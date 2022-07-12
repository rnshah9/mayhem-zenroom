/*
 * This file is part of zenroom
 * 
 * Copyright (C) 2017-2021 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License v3.0
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * Along with this program you should have received a copy of the
 * GNU Affero General Public License v3.0
 * If not, see http://www.gnu.org/licenses/agpl.txt
 * 
 * Last modified by Denis Roio
 * on Thursday, 2nd September 2021
 */

#ifndef LIBRARY


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <ctype.h>
#include <time.h>

#if ! defined ARCH_WIN
#include <sys/types.h>
#include <sys/wait.h>
#endif

#include <errno.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <lua_functions.h>
#include <repl.h>

#include <zenroom.h>
#include <zen_memory.h>
#include <zen_error.h>

#include <sys/types.h>
#include <unistd.h>

#if defined(ARCH_LINUX)
#include <sys/prctl.h>
#include <linux/seccomp.h>
#include <linux/filter.h>
#include <sys/syscall.h>
static const struct sock_filter  strict_filter[] = {
	BPF_STMT(BPF_LD | BPF_W | BPF_ABS, (offsetof (struct seccomp_data, nr))),

	BPF_JUMP(BPF_JMP | BPF_JEQ, SYS_getrandom,    6, 0),
	BPF_JUMP(BPF_JMP | BPF_JEQ, SYS_rt_sigreturn, 5, 0),
	BPF_JUMP(BPF_JMP | BPF_JEQ, SYS_read,         4, 0),
	BPF_JUMP(BPF_JMP | BPF_JEQ, SYS_write,        3, 0),
	BPF_JUMP(BPF_JMP | BPF_JEQ, SYS_exit,         2, 0),
	BPF_JUMP(BPF_JMP | BPF_JEQ, SYS_exit_group,   1, 0),

	BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_KILL),
	BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ALLOW)
};

static const struct sock_fprog  strict = {
	.len = (unsigned short)( sizeof strict_filter / sizeof strict_filter[0] ),
	.filter = (struct sock_filter *)strict_filter
};

#endif

extern int zen_setenv(lua_State *L, char *key, char *val);

// This function exits the process on failure.
void load_file(char *dst, FILE *fd) {
	char *firstline = NULL;
	long file_size = 0L;
	size_t offset = 0;
	size_t bytes = 0;
	if(!fd) {
		zerror(0, "Error opening %s", strerror(errno));
		exit(1); }
	if(fd!=stdin) {
		if(fseek(fd, 0L, SEEK_END)<0) {
			zerror(0, "fseek(end) error in %s: %s", __func__,
			      strerror(errno));
			exit(1); }
		file_size = ftell(fd);
		if(fseek(fd, 0L, SEEK_SET)<0) {
			zerror(0, "fseek(start) error in %s: %s", __func__,
			      strerror(errno));
			exit(1); }
		func(0, "size of file: %u", file_size);
	}

	firstline = malloc(MAX_STRING);
	// skip shebang on firstline
	if(!fgets(firstline, MAX_STRING, fd)) {
		if(errno==0) { // file is empty
			zerror(0, "Error reading, file is empty");
			if(firstline) free(firstline);
			exit(1); }
		zerror(0, "Error reading first line: %s", strerror(errno));
		exit(1); }
	if(firstline[0]=='#' && firstline[1]=='!')
		func(0, "Skipping shebang");
	else {
		offset+=strlen(firstline);
		strncpy(dst, firstline, MAX_STRING);
	}

	size_t chunk;
	while(1) {
		chunk = MAX_STRING;
		if( offset+MAX_STRING>MAX_FILE )
			chunk = MAX_FILE-offset-1;
		if(!chunk) {
			warning(0, "File too big, truncated at maximum supported size");
			break; }
		bytes = fread(&dst[offset],1,chunk,fd);

		if(!bytes) {
			if(feof(fd)) {
				if((fd!=stdin) && (long)offset!=file_size) {
					warning(0, "Incomplete file read (%u of %u bytes)",
					      offset, file_size);
				} else {
					func(0, "EOF after %u bytes",offset);
				}
 				dst[offset] = '\0';
				break;
			}
			if(ferror(fd)) {
				zerror(0, "Error in %s: %s", __func__, strerror(errno));
				fclose(fd);
				if(firstline) free(firstline);
				exit(1); }
		}
		offset += bytes;
	}
	if(fd!=stdin) fclose(fd);
	act(0, "loaded file (%u bytes)", offset);
	if(firstline) free(firstline);
}

static char *conffile = NULL;
static char *keysfile = NULL;
static char *scriptfile = NULL;
static char *datafile = NULL;
static char *rngseed = NULL;
static char *sideload = NULL;
static char *sidescript = NULL;
static char *script = NULL;
static char *keys = NULL;
static char *data = NULL;
static char *introspect = NULL;

// for benchmark, breaks c99 spec
struct timespec before = {0}, after = {0};

int cli_alloc_buffers() {
	conffile = malloc(MAX_STRING);
	scriptfile = malloc(MAX_STRING);
	sideload = malloc(MAX_STRING);
	keysfile = malloc(MAX_STRING);
	datafile = malloc(MAX_STRING);
	rngseed = malloc(MAX_STRING);
	script = malloc(MAX_FILE);
	sidescript = malloc(MAX_FILE);
	keys = malloc(MAX_FILE);
	data = malloc(MAX_FILE);
	introspect = malloc(MAX_STRING);
	return(1);
}

int cli_free_buffers() {
	free(conffile);
	free(scriptfile);
	free(sidescript);
	free(keysfile);
	free(datafile);
	free(rngseed);
	free(script);
	free(keys);
	free(data);
	free(introspect);
	return(1);
}

int main(int argc, char **argv) {
	int opt, index;
	int   interactive         = 0;
	int   zencode             = 0;
	int use_seccomp = 0;
	cli_alloc_buffers();

	zenroom_t *Z;

	const char *short_options = "hD:ic:k:a:l:S:pz";
	const char *help          =
		"Usage: zenroom [-h] [-s] [ -D scenario ] [ -i ] [ -c config ] [ -k keys ] [ -a data ] [ -S seed ] [ -p ] [ -z ] [ -l lib ] [ script.lua ]\n";
	int pid, status, retval;
	conffile   [0] = '\0';
	scriptfile [0] = '\0';
	sideload   [0] = '\0';
	keysfile   [0] = '\0';
	datafile   [0] = '\0';
	rngseed    [0] = '\0';
	data       [0] = '\0';
	keys       [0] = '\0';
	introspect [0] = '\0';
	// conf[0] = '\0';
	script[0] = '\0';
	int verbosity = 1;
	while((opt = getopt(argc, argv, short_options)) != -1) {
		switch(opt) {
		case 'D':
			snprintf(introspect,MAX_STRING-1,"%s",optarg);
			break;
		case 'h':
			fprintf(stdout,"%s",help);
			cli_free_buffers();
			return EXIT_SUCCESS;
			break;
		case 's':
		        use_seccomp = 1;
			break;
		case 'i':
			interactive = 1;
			break;
		case 'l':
			snprintf(sideload,MAX_STRING-1,"%s",optarg);
			break;
		case 'k':
			snprintf(keysfile,MAX_STRING-1,"%s",optarg);
			break;
		case 'a':
			snprintf(datafile,MAX_STRING-1,"%s",optarg);
			break;
		case 'c':
			snprintf(conffile,MAX_STRING-1,"%s",optarg);
			break;
		case 'S':
			snprintf(rngseed,MAX_STRING-1,"%s",optarg);
			break;
		case 'z':
			zencode = 1;
			interactive = 0;
			break;
		case '?': zerror(0, help); cli_free_buffers(); return EXIT_FAILURE;
		default:  zerror(0, help); cli_free_buffers(); return EXIT_FAILURE;
		}
	}

	if(verbosity) {
		notice(NULL, "Zenroom v%s - secure crypto language VM",VERSION);
		act(NULL, "Zenroom is Copyright (C) 2017-2021 by the Dyne.org foundation");
		act(NULL, "For the original source code and documentation go to https://zenroom.org");
		act(NULL, "Zenroom is free software: you can redistribute it and/or modify");
		act(NULL, "it under the terms of the GNU Affero General Public License as");
		act(NULL, "published by the Free Software Foundation, either version 3 of the");
		act(NULL, "License, or (at your option) any later version.");
		act(NULL, "Zenroom is distributed in the hope that it will be useful,");
		act(NULL, "but WITHOUT ANY WARRANTY; without even the implied warranty of");
		act(NULL, "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the");
		act(NULL, "GNU Affero General Public License for more details.");
		act(NULL, "You should have received a copy of the GNU Affero General Public License");
		act(NULL, "along with this program.  If not, see http://www.gnu.org/licenses/");
	}

	for (index = optind; index < argc; index++) {
		snprintf(scriptfile,MAX_STRING-1,"%s",argv[index]);
	}

	if(keysfile[0]!='\0') {
		if(verbosity) act(NULL, "reading KEYS from file: %s", keysfile);
		load_file(keys, fopen(keysfile, "r"));
	}

	if(datafile[0]!='\0' && verbosity) {
		if(verbosity) act(NULL, "reading DATA from file: %s", datafile);
		load_file(data, fopen(datafile, "r"));
	}

	if(interactive) {
		////////////////////////////////////
		// start an interactive repl console
		Z = zen_init(
			conffile[0]?conffile:NULL,
			keys[0]?keys:NULL,
			data[0]?data:NULL);
		lua_State *L = (lua_State*)Z->lua;

		// print function
		zen_add_function(L, repl_flush, "flush");
		zen_add_function(L, repl_read, "read");
		zen_add_function(L, repl_write, "write");
		int res;
		if(verbosity) notice(NULL, "Interactive console, press ctrl-d to quit.");
		res = repl_loop(Z);
		if(res)
			// quits on ctrl-D
			zen_teardown(Z);
		cli_free_buffers();
		return(res);
	}

	// configuration from -c or default
	if(conffile[0]!='\0') {
		if(verbosity) act(NULL, "configuration: %s",conffile);
	// load_file(conf, fopen(conffile, "r"));
	} else
		if(verbosity) act(NULL, "using default configuration");

	// time from here
    clock_gettime(CLOCK_MONOTONIC, &before);

	// set_debug(verbosity);
	Z = zen_init(
			(conffile[0])?conffile:NULL,
			(keys[0])?keys:NULL,
			(data[0])?data:NULL);
	if(!Z) {
		zerror(NULL, "Initialisation failed.");
		cli_free_buffers();
		return EXIT_FAILURE; }

	// print scenario documentation
	if(introspect[0]!='\0') {
		static char zscript[MAX_ZENCODE];
		notice(NULL, "Documentation for scenario: %s",introspect);
		(*Z->snprintf)(zscript,MAX_ZENCODE-1,
		               "function Given(text, fn) ZEN.given_steps[text] = true end\n"
		               "function When(text, fn) ZEN.when_steps[text] = true end\n"
		               "function Then(text, fn) ZEN.then_steps[text] = true end\n"
					   "function IfWhen(text, fn) ZEN.if_steps[text] = true end\n"
		               "function ZEN.add_schema(arr)\n"
		               "  for k,v in pairs(arr) do ZEN.schemas[k] = true end end\n"
		               "ZEN.given_steps = {}\n"
		               "ZEN.when_steps = {}\n"
		               "ZEN.then_steps = {}\n"
   		               "ZEN.if_steps = {}\n"
		               "ZEN.schemas = {}\n"
		               "require_once('zencode_%s')\n"
		               "print(JSON.encode(\n"
		               "{ Scenario = \"%s\",\n"
		               "  Given = ZEN.given_steps,\n"
		               "  When = ZEN.when_steps,\n"
		               "  Then = ZEN.then_steps,\n"
					   "  If = ZEN.if_steps,\n"
		               "  Schemas = ZEN.schemas }))", introspect, introspect);
		int ret = luaL_dostring(Z->lua, zscript);
		if(ret) {
			zerror(Z->lua, "Zencode execution error");
			zerror(Z->lua, "Script:\n%s", zscript);
			zerror(Z->lua, "%s", lua_tostring(Z->lua, -1));
			fflush(stderr);
		}
		zen_teardown(Z);
		cli_free_buffers();
		return EXIT_SUCCESS;
	}

	if(sideload[0]!='\0') {
		notice(Z->lua,"Side loading library: %s",sideload);
		load_file(sidescript, fopen(sideload,"rb"));
		zen_exec_script(Z, sidescript);
		// TODO: detect error
	}

	if(scriptfile[0]!='\0') {
		////////////////////////////////////
		// load a file as script and execute
		if(verbosity) notice(NULL, "reading Zencode from file: %s", scriptfile);
		load_file(script, fopen(scriptfile, "rb"));
	} else {
		////////////////////////
		// get another argument from stdin
		if(verbosity) act(NULL, "reading Zencode from stdin");
		load_file(script, stdin);
		// func(NULL, "%s\n--",script);
	}

	// configure to parse Lua or Zencode
	if(zencode) {
		if(verbosity) notice(NULL, "Direct Zencode execution");
		// func(NULL, script);
	}

#if (defined(ARCH_WIN) || defined(DISABLE_FORK)) || defined(ARCH_CORTEX) || defined(ARCH_BSD)
	if(zencode)
		zen_exec_zencode(Z, script);
	else
		zen_exec_script(Z, script);

#else /* POSIX */
	if (!use_seccomp) {
		if(zencode) {
			zen_exec_zencode(Z, script);
		} else {
			zen_exec_script(Z, script);
		}
	} else {
		act(NULL, "protected mode (seccomp isolation) activated");
		if (fork() == 0) {
#   ifdef ARCH_LINUX /* LINUX engages SECCOMP. */
			if (prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0)) {

				zerror(Z->lua, "Seccomp fail to set no_new_privs: %s", strerror(errno));
				zen_teardown(Z);

				cli_free_buffers();
				return EXIT_FAILURE;
			}
			if (prctl(PR_SET_SECCOMP, SECCOMP_MODE_FILTER, &strict)) {

				zerror(Z->lua, "Seccomp fail to install filter: %s", strerror(errno));
				zen_teardown(Z);

				cli_free_buffers();
				return EXIT_FAILURE;
			}
#   endif /* ARCH_LINUX */
			if(verbosity) act(NULL, "starting execution.");
			int exitcode;
			if(zencode) {
				exitcode = zen_exec_zencode(Z, script);
			} else {
				exitcode = zen_exec_script(Z, script);
			}
			zen_teardown(Z);
			cli_free_buffers();
			return exitcode;
		}
		do {
			pid = wait(&status);
		} while(pid == -1);

		if (WIFEXITED(status)) {
			retval = WEXITSTATUS(status);
			if (retval == 0)
				if(verbosity) notice(NULL, "Execution completed.");
		} else if (WIFSIGNALED(status)) {
			notice(NULL, "Execution interrupted by signal %d.", WTERMSIG(status));
		}
	}
#endif /* POSIX */
	int exitcode = Z->exitcode;
	zen_teardown(Z);

	{
		// measure and report time of execution
		clock_gettime(CLOCK_MONOTONIC, &after);
		long musecs = (after.tv_sec - before.tv_sec) * 1000000L;
		act(NULL,"Time used: %lu", ( ((after.tv_nsec - before.tv_nsec) / 1000L) + musecs) );
	}

	cli_free_buffers();
	return exitcode;
}

#endif // LIBRARY
