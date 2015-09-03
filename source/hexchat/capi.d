module hexchat.capi;

import core.stdc.time;
import std.traits;

enum HEXCHAT_PRI_HIGHEST = 127;
enum HEXCHAT_PRI_HIGH = 64;
enum HEXCHAT_PRI_NORM = 0;
enum HEXCHAT_PRI_LOW = -64;
enum HEXCHAT_PRI_LOWEST = -128;

enum HEXCHAT_FD_READ = 1;
enum HEXCHAT_FD_WRITE = 2;
enum HEXCHAT_FD_EXCEPTION = 4;
enum HEXCHAT_FD_NOTSOCKET = 8;

enum HEXCHAT_EAT_NONE = 0; // pass it on through!
enum HEXCHAT_EAT_HEXCHAT = 1; // don't let xchat see this event
enum HEXCHAT_EAT_PLUGIN = 2; // don't let other plugins see this event
enum HEXCHAT_EAT_ALL = HEXCHAT_EAT_HEXCHAT | HEXCHAT_EAT_PLUGIN; // don't let anything see this event

extern(C):
struct hexchat_list {}
struct hexchat_hook {}
struct hexchat_context {}

alias extern(C) int function (const(char)** word, const(char)** word_eol, void *user_data) hexchat_cmd_cb;
alias extern(C) int function (const(char)** word, void *user_data) hexchat_print_cb;
alias extern(C) int function (void *user_data) hexchat_timer_cb;
alias extern(C) int function (int fd, int flags, void *user_data) hexchat_fd_cb;

struct hexchat_plugin
{
	// these are only used on win32
	extern(C):
	hexchat_hook *function (hexchat_plugin *ph, const char *name, int pri, hexchat_cmd_cb callback, const char *help_text, void *userdata) hexchat_hook_command;
	hexchat_hook *function (hexchat_plugin *ph, const char *name, int pri, hexchat_cmd_cb callback, void *userdata) hexchat_hook_server;
	hexchat_hook *function (hexchat_plugin *ph, const char *name, int pri, hexchat_print_cb callback, void *userdata) hexchat_hook_print;
	hexchat_hook *function (hexchat_plugin *ph, int timeout, hexchat_timer_cb callback, void *userdata) hexchat_hook_timer;
	hexchat_hook *function (hexchat_plugin *ph, int fd, int flags, hexchat_fd_cb callback, void *userdata) hexchat_hook_fd;
	void *function (hexchat_plugin *ph, hexchat_hook *hook) hexchat_unhook;
	void function (hexchat_plugin *ph, const char *text) hexchat_print;
	void function (hexchat_plugin *ph, const char *format, ...) hexchat_printf;
	void function (hexchat_plugin *ph, const char *command) hexchat_command;
	void function (hexchat_plugin *ph, const char *format, ...) hexchat_commandf;
	int function (hexchat_plugin *ph, const char *s1, const char *s2) hexchat_nickcmp;
	int function (hexchat_plugin *ph, hexchat_context *ctx) hexchat_set_context;
	hexchat_context *function (hexchat_plugin *ph, const char *servname, const char *channel) hexchat_find_context;
	hexchat_context *function (hexchat_plugin *ph) hexchat_get_context;
	const char *function (hexchat_plugin *ph, const char *id) hexchat_get_info;
	int function (hexchat_plugin *ph, const char *name, const char **string, int *integer) hexchat_get_prefs;
	hexchat_list * function (hexchat_plugin *ph, const char *name) hexchat_list_get;
	void function (hexchat_plugin *ph, hexchat_list *xlist) hexchat_list_free;
	const char ** function (hexchat_plugin *ph, const char *name) hexchat_list_fields;
	int function (hexchat_plugin *ph, hexchat_list *xlist) hexchat_list_next;
	const char * function (hexchat_plugin *ph, hexchat_list *xlist, const char *name) hexchat_list_str;
	int function (hexchat_plugin *ph, hexchat_list *xlist, const char *name) hexchat_list_int;
	void * function (hexchat_plugin *ph, const char *filename, const char *name, const char *desc, const char *_version, char *reserved) hexchat_plugingui_add;
	void function (hexchat_plugin *ph, void *handle) hexchat_plugingui_remove;
	int function (hexchat_plugin *ph, const char *event_name, ...) hexchat_emit_print;
	int function (hexchat_plugin *ph, void *src, char *buf, int *len) hexchat_read_fd;
	time_t function (hexchat_plugin *ph, hexchat_list *xlist, const char *name) hexchat_list_time;
	char *function (hexchat_plugin *ph, const char *msgid) hexchat_gettext;
	void function (hexchat_plugin *ph, const char **targets, int ntargets, int modes_per_line, char sign, char mode) hexchat_send_modes;
	char *function (hexchat_plugin *ph, const char *str, int len, int flags) hexchat_strip;
	void function (hexchat_plugin *ph, void *ptr) hexchat_free;
}

version(Windows)
{
	private mixin template WrapMember(string funcname)
	{
		mixin("alias typeof(hexchat_plugin.init." ~ funcname ~ ") fun;");
		mixin(`
			ReturnType!fun ` ~ funcname ~ `(ParameterTypeTuple!fun args)
			{
				return args[0].` ~ funcname ~ `(args);
			}
		`);
	}

	mixin WrapMember!"hexchat_hook_command";
	mixin WrapMember!"hexchat_hook_server";
	mixin WrapMember!"hexchat_hook_print";
	mixin WrapMember!"hexchat_hook_timer";
	mixin WrapMember!"hexchat_hook_fd";
	mixin WrapMember!"hexchat_unhook";
	mixin WrapMember!"hexchat_print";
	mixin WrapMember!"hexchat_command";
	mixin WrapMember!"hexchat_nickcmp";
	mixin WrapMember!"hexchat_set_context";
	mixin WrapMember!"hexchat_find_context";
	mixin WrapMember!"hexchat_get_context";
	mixin WrapMember!"hexchat_get_info";
	mixin WrapMember!"hexchat_get_prefs";
	mixin WrapMember!"hexchat_list_get";
	mixin WrapMember!"hexchat_list_free";
	mixin WrapMember!"hexchat_list_fields";
	mixin WrapMember!"hexchat_list_next";
	mixin WrapMember!"hexchat_list_str";
	mixin WrapMember!"hexchat_list_int";
	mixin WrapMember!"hexchat_plugingui_add";
	mixin WrapMember!"hexchat_plugingui_remove";
	mixin WrapMember!"hexchat_read_fd";
	mixin WrapMember!"hexchat_list_time";
	mixin WrapMember!"hexchat_gettext";
	mixin WrapMember!"hexchat_send_modes";
	mixin WrapMember!"hexchat_strip";
	mixin WrapMember!"hexchat_free";

	// WrapMember can't handle varargs
	void hexchat_printf(Args...)(hexchat_plugin *ph, const char *format, Args args)
	{
		ph.hexchat_printf(ph, format, args);
	}

	void hexchat_commandf(Args...)(hexchat_plugin *ph, const char *format, Args args)
	{
		ph.hexchat_commandf(ph, format, args);
	}

	int hexchat_emit_print(Args...)(hexchat_plugin *ph, const char *event_name, Args args)
	{
		ph.hexchat_emit_print(ph, event_name, args);
	}
}
else
{
	hexchat_hook *
		hexchat_hook_command (hexchat_plugin *ph,
							const char *name,
							int pri,
							hexchat_cmd_cb callback,
							const char *help_text,
							void *userdata);

	hexchat_hook *
		hexchat_hook_server (hexchat_plugin *ph,
							const char *name,
							int pri,
							hexchat_cmd_cb callback,
							void *userdata);

	hexchat_hook *
		hexchat_hook_print (hexchat_plugin *ph,
							const char *name,
							int pri,
							hexchat_print_cb callback,
							void *userdata);

	hexchat_hook *
		hexchat_hook_timer (hexchat_plugin *ph,
							int timeout,
							hexchat_timer_cb callback,
							void *userdata);

	hexchat_hook *
		hexchat_hook_fd (hexchat_plugin *ph,
						int fd,
						int flags,
						hexchat_fd_cb callback,
						void *userdata);

	void *
		hexchat_unhook (hexchat_plugin *ph,
						hexchat_hook *hook);

	void
		hexchat_print (hexchat_plugin *ph,
						const char *text);

	void
		hexchat_printf (hexchat_plugin *ph,
						const char *format, ...);

	void
		hexchat_command (hexchat_plugin *ph,
						const char *command);

	void
		hexchat_commandf (hexchat_plugin *ph,
						const char *format, ...);

	int
		hexchat_nickcmp (hexchat_plugin *ph,
						const char *s1,
						const char *s2);

	int
		hexchat_set_context (hexchat_plugin *ph,
							hexchat_context *ctx);

	hexchat_context *
		hexchat_find_context (hexchat_plugin *ph,
							const char *servname,
							const char *channel);

	hexchat_context *
		hexchat_get_context (hexchat_plugin *ph);

	const(char*)
		hexchat_get_info (hexchat_plugin *ph,
						const char *id);

	int
		hexchat_get_prefs (hexchat_plugin *ph,
							const char *name,
							const char **string,
							int *integer);

	hexchat_list *
		hexchat_list_get (hexchat_plugin *ph,
						const char *name);

	void
		hexchat_list_free (hexchat_plugin *ph,
							hexchat_list *xlist);

	const(char**)
		hexchat_list_fields (hexchat_plugin *ph,
							const char *name);

	int
		hexchat_list_next (hexchat_plugin *ph,
							hexchat_list *xlist);

	const(char*)
		hexchat_list_str (hexchat_plugin *ph,
						hexchat_list *xlist,
						const char *name);

	int
		hexchat_list_int (hexchat_plugin *ph,
						hexchat_list *xlist,
						const char *name);

	time_t
		hexchat_list_time (hexchat_plugin *ph,
							hexchat_list *xlist,
							const char *name);

	void *
		hexchat_plugingui_add (hexchat_plugin *ph,
								const char *filename,
								const char *name,
								const char *desc,
								const char *_version,
								char *reserved);

	void
		hexchat_plugingui_remove (hexchat_plugin *ph,
								void *handle);

	int
		hexchat_emit_print (hexchat_plugin *ph,
							const char *event_name, ...);

	char *
		hexchat_gettext (hexchat_plugin *ph,
						const char *msgid);

	void
		hexchat_send_modes (hexchat_plugin *ph,
							const char **targets,
							int ntargets,
							int modes_per_line,
							char sign,
							char mode);

	char *
		hexchat_strip (hexchat_plugin *ph,
						const char *str,
						int len,
						int flags);

	void
		hexchat_free (hexchat_plugin *ph,
					void *ptr);
}
