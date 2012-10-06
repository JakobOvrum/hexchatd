module xchat.capi;

import core.stdc.time;
import std.traits;

enum XCHAT_IFACE_MAJOR = 1;
enum XCHAT_IFACE_MINOR = 9;
enum XCHAT_IFACE_MICRO = 11;

enum XCHAT_IFACE_VERSION = ((XCHAT_IFACE_MAJOR * 10000) +
							(XCHAT_IFACE_MINOR * 100) +
							(XCHAT_IFACE_MICRO));

enum XCHAT_PRI_HIGHEST = 127;
enum XCHAT_PRI_HIGH = 64;
enum XCHAT_PRI_NORM = 0;
enum XCHAT_PRI_LOW = -64;
enum XCHAT_PRI_LOWEST = -128;

enum XCHAT_FD_READ = 1;
enum XCHAT_FD_WRITE = 2;
enum XCHAT_FD_EXCEPTION = 4;
enum XCHAT_FD_NOTSOCKET = 8;

enum XCHAT_EAT_NONE = 0; // pass it on through!
enum XCHAT_EAT_XCHAT = 1; // don't let xchat see this event
enum XCHAT_EAT_PLUGIN = 2; // don't let other plugins see this event
enum XCHAT_EAT_ALL = XCHAT_EAT_XCHAT | XCHAT_EAT_PLUGIN; // don't let anything see this event 

extern(C):
struct xchat_list {}
struct xchat_hook {}
struct xchat_context {}

alias extern(C) int function (const(char)** word, const(char)** word_eol, void *user_data) xchat_cmd_cb;
alias extern(C) int function (const(char)** word, void *user_data) xchat_print_cb;
alias extern(C) int function (void *user_data) xchat_timer_cb;
alias extern(C) int function (int fd, int flags, void *user_data) xchat_fd_cb;

struct xchat_plugin
{
	// these are only used on win32
	extern(C):
	xchat_hook *function (xchat_plugin *ph, const char *name, int pri, xchat_cmd_cb callback, const char *help_text, void *userdata) xchat_hook_command;
	xchat_hook *function (xchat_plugin *ph, const char *name, int pri, xchat_cmd_cb callback, void *userdata) xchat_hook_server;
	xchat_hook *function (xchat_plugin *ph, const char *name, int pri, xchat_print_cb callback, void *userdata) xchat_hook_print;
	xchat_hook *function (xchat_plugin *ph, int timeout, xchat_timer_cb callback, void *userdata) xchat_hook_timer;
	xchat_hook *function (xchat_plugin *ph, int fd, int flags, xchat_fd_cb callback, void *userdata) xchat_hook_fd;
	void *function (xchat_plugin *ph, xchat_hook *hook) xchat_unhook;
	void function (xchat_plugin *ph, const char *text) xchat_print;
	void function (xchat_plugin *ph, const char *format, ...) xchat_printf;
	void function (xchat_plugin *ph, const char *command) xchat_command;
	void function (xchat_plugin *ph, const char *format, ...) xchat_commandf;
	int function (xchat_plugin *ph, const char *s1, const char *s2) xchat_nickcmp;
	int function (xchat_plugin *ph, xchat_context *ctx) xchat_set_context;
	xchat_context *function (xchat_plugin *ph, const char *servname, const char *channel) xchat_find_context;
	xchat_context *function (xchat_plugin *ph) xchat_get_context;
	const char *function (xchat_plugin *ph, const char *id) xchat_get_info;
	int function (xchat_plugin *ph, const char *name, const char **string, int *integer) xchat_get_prefs;
	xchat_list * function (xchat_plugin *ph, const char *name) xchat_list_get;
	void function (xchat_plugin *ph, xchat_list *xlist) xchat_list_free;
	const char ** function (xchat_plugin *ph, const char *name) xchat_list_fields;
	int function (xchat_plugin *ph, xchat_list *xlist) xchat_list_next;
	const char * function (xchat_plugin *ph, xchat_list *xlist, const char *name) xchat_list_str;
	int function (xchat_plugin *ph, xchat_list *xlist, const char *name) xchat_list_int;
	void * function (xchat_plugin *ph, const char *filename, const char *name, const char *desc, const char *_version, char *reserved) xchat_plugingui_add;
	void function (xchat_plugin *ph, void *handle) xchat_plugingui_remove;
	int function (xchat_plugin *ph, const char *event_name, ...) xchat_emit_print;
	int function (xchat_plugin *ph, void *src, char *buf, int *len) xchat_read_fd;
	time_t function (xchat_plugin *ph, xchat_list *xlist, const char *name) xchat_list_time;
	char *function (xchat_plugin *ph, const char *msgid) xchat_gettext;
	void function (xchat_plugin *ph, const char **targets, int ntargets, int modes_per_line, char sign, char mode) xchat_send_modes;
	char *function (xchat_plugin *ph, const char *str, int len, int flags) xchat_strip;
	void function (xchat_plugin *ph, void *ptr) xchat_free;
}

version(Windows)
{
	private mixin template WrapMember(string funcname)
	{
		mixin("alias typeof(xchat_plugin.init." ~ funcname ~ ") fun;");
		mixin(`
			ReturnType!fun ` ~ funcname ~ `(ParameterTypeTuple!fun args)
			{
				return args[0].` ~ funcname ~ `(args);
			}
		`);
	}

	mixin WrapMember!"xchat_hook_command";
	mixin WrapMember!"xchat_hook_server";
	mixin WrapMember!"xchat_hook_print";
	mixin WrapMember!"xchat_hook_timer";
	mixin WrapMember!"xchat_hook_fd";
	mixin WrapMember!"xchat_unhook";
	mixin WrapMember!"xchat_print";
	mixin WrapMember!"xchat_command";
	mixin WrapMember!"xchat_nickcmp";
	mixin WrapMember!"xchat_set_context";
	mixin WrapMember!"xchat_find_context";
	mixin WrapMember!"xchat_get_context";
	mixin WrapMember!"xchat_get_info";
	mixin WrapMember!"xchat_get_prefs";
	mixin WrapMember!"xchat_list_get";
	mixin WrapMember!"xchat_list_free";
	mixin WrapMember!"xchat_list_fields";
	mixin WrapMember!"xchat_list_next";
	mixin WrapMember!"xchat_list_str";
	mixin WrapMember!"xchat_list_int";
	mixin WrapMember!"xchat_plugingui_add";
	mixin WrapMember!"xchat_plugingui_remove";
	mixin WrapMember!"xchat_read_fd";
	mixin WrapMember!"xchat_list_time";
	mixin WrapMember!"xchat_gettext";
	mixin WrapMember!"xchat_send_modes";
	mixin WrapMember!"xchat_strip";
	mixin WrapMember!"xchat_free";

	// WrapMember can't handle varargs
	void xchat_printf(Args...)(xchat_plugin *ph, const char *format, Args args)
	{
		ph.xchat_printf(ph, format, args);
	}

	void xchat_commandf(Args...)(xchat_plugin *ph, const char *format, Args args)
	{
		ph.xchat_commandf(ph, format, args);
	}

	int xchat_emit_print(Args...)(xchat_plugin *ph, const char *event_name, Args args)
	{
		ph.xchat_emit_print(ph, event_name, args);
	}
}
else
{
	xchat_hook *
		xchat_hook_command (xchat_plugin *ph,
							const char *name,
							int pri,
							xchat_cmd_cb callback,
							const char *help_text,
							void *userdata);

	xchat_hook *
		xchat_hook_server (xchat_plugin *ph,
							const char *name,
							int pri,
							xchat_cmd_cb callback,
							void *userdata);

	xchat_hook *
		xchat_hook_print (xchat_plugin *ph,
							const char *name,
							int pri,
							xchat_print_cb callback,
							void *userdata);

	xchat_hook *
		xchat_hook_timer (xchat_plugin *ph,
							int timeout,
							xchat_timer_cb callback,
							void *userdata);

	xchat_hook *
		xchat_hook_fd (xchat_plugin *ph,
						int fd,
						int flags,
						xchat_fd_cb callback,
						void *userdata);

	void *
		xchat_unhook (xchat_plugin *ph,
						xchat_hook *hook);

	void
		xchat_print (xchat_plugin *ph,
						const char *text);

	void
		xchat_printf (xchat_plugin *ph,
						const char *format, ...);

	void
		xchat_command (xchat_plugin *ph,
						const char *command);

	void
		xchat_commandf (xchat_plugin *ph,
						const char *format, ...);

	int
		xchat_nickcmp (xchat_plugin *ph,
						const char *s1,
						const char *s2);

	int
		xchat_set_context (xchat_plugin *ph,
							xchat_context *ctx);

	xchat_context *
		xchat_find_context (xchat_plugin *ph,
							const char *servname,
							const char *channel);

	xchat_context *
		xchat_get_context (xchat_plugin *ph);

	const(char*)
		xchat_get_info (xchat_plugin *ph,
						const char *id);

	int
		xchat_get_prefs (xchat_plugin *ph,
							const char *name,
							const char **string,
							int *integer);

	xchat_list *
		xchat_list_get (xchat_plugin *ph,
						const char *name);

	void
		xchat_list_free (xchat_plugin *ph,
							xchat_list *xlist);

	const(char**)
		xchat_list_fields (xchat_plugin *ph,
							const char *name);

	int
		xchat_list_next (xchat_plugin *ph,
							xchat_list *xlist);

	const(char*)
		xchat_list_str (xchat_plugin *ph,
						xchat_list *xlist,
						const char *name);

	int
		xchat_list_int (xchat_plugin *ph,
						xchat_list *xlist,
						const char *name);

	time_t
		xchat_list_time (xchat_plugin *ph,
							xchat_list *xlist,
							const char *name);

	void *
		xchat_plugingui_add (xchat_plugin *ph,
								const char *filename,
								const char *name,
								const char *desc,
								const char *_version,
								char *reserved);

	void
		xchat_plugingui_remove (xchat_plugin *ph,
								void *handle);

	int 
		xchat_emit_print (xchat_plugin *ph,
							const char *event_name, ...);

	char *
		xchat_gettext (xchat_plugin *ph,
						const char *msgid);

	void
		xchat_send_modes (xchat_plugin *ph,
							const char **targets,
							int ntargets,
							int modes_per_line,
							char sign,
							char mode);

	char *
		xchat_strip (xchat_plugin *ph,
						const char *str,
						int len,
						int flags);

	void
		xchat_free (xchat_plugin *ph,
					void *ptr);
}
