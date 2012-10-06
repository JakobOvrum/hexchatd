module xchat.plugin;

import xchat.capi;

import std.string;
import core.stdc.string : strlen;

// Note: to!string will currently make a copy unconditionally, hence this.
private inout(char)[] fromStringz(inout(char)* cstr)
{
	return cstr[0 .. strlen(cstr)];
}

__gshared xchat_plugin *ph; // Plugin handle

struct PluginInfo
{
	string name;
	string description;
	string version_;
}

// Internal, has to be public because of the below mixin strings.
int _xchatInitPlugin(void* plugin_handle,
							 immutable(char)** plugin_name,
							 immutable(char)** plugin_desc,
							 immutable(char)** plugin_version,
							 void function(ref PluginInfo) initFunc)
{
	ph = cast(xchat_plugin*)plugin_handle;

	PluginInfo info;

	if(plugin_name && *plugin_name)
		info.name = fromStringz(*plugin_name);

	if(plugin_desc && *plugin_desc)
		info.description = fromStringz(*plugin_desc);

	if(plugin_version && *plugin_version)
		info.version_ = fromStringz(*plugin_version);

	try
	{
		initFunc(info);
	}
	catch(Throwable e)
	{
		auto message = e.toString();
		xchat_printf(ph, `Error initializing plugin "%.*s": %.*s`, info.name.length, info.name.ptr, message.length, message.ptr);
		return 0;
	}

	if(info.name)
		*plugin_name = toStringz(info.name);

	if(info.description)
		*plugin_desc = toStringz(info.description);

	if(info.version_)
		*plugin_version = toStringz(info.version_);

	debug xchat_printf(ph, "Debug: loaded plugin %s %s (%s)\n", *plugin_name, *plugin_version, *plugin_desc);

	return 1; // Return 1 for success
}

//TODO: verify initFunc signature
template XchatPlugin(alias initFunc)
{
	enum XchatPlugin = 
		// The first exported C symbol always gets a preceeding
		// underscore on Windows with DMD/OPTLINK, but xchat
		// expects "xchat_plugin_init" exactly.
		"version(Windows) export extern(C) void _systemconvdummy() {}\n" ~
		"export extern(C) int xchat_plugin_init(void* ph," ~
		"	immutable(char)** name, immutable(char)** desc, immutable(char)** version_, char* arg)" ~
		"{" ~
		"	return _xchatInitPlugin(ph, name, desc, version_, &" ~ __traits(identifier, initFunc) ~ ");" ~
		"}";
}

//TODO: verify deinitFunc signature
template XchatPlugin(alias initFunc, alias deinitFunc)
{
	enum XchatPlugin = XchatPlugin!initFunc ~
		"export extern(C) int xchat_plugin_deinit(void* ph) {" ~
		"	return " ~ __traits(identifier, deinitFunc) ~ "();" ~
		"}";
}

void writefln(FmtArgs...)(const(char)[] fmt, FmtArgs fmtArgs)
{
	static if(fmtArgs.length != 0)
	{
		fmt = xformat(fmt, fmtArgs);
	}

	xchat_printf(ph, "%.*s", fmt.length, fmt.ptr);
}

void commandf(FmtArgs...)(const(char)[] fmt, FmtArgs fmtArgs)
{
	static if(fmtArgs.length != 0)
	{
		fmt = xformat(fmt, fmtArgs);
	}

	xchat_commandf(ph, "%.*s", fmt.length, fmt.ptr);
}

enum EatMode
{
	none = XCHAT_EAT_NONE, // pass it on through!
	xchat = XCHAT_EAT_XCHAT, // don't let xchat see this event
	plugin = XCHAT_EAT_PLUGIN, // don't let other plugins see this event
	all = XCHAT_EAT_XCHAT | XCHAT_EAT_PLUGIN // don't let anything see this event 
}

enum CommandPriority
{
	highest = XCHAT_PRI_HIGHEST,
	high = XCHAT_PRI_HIGH,
	normal = XCHAT_PRI_NORM,
	low = XCHAT_PRI_LOW,
	lowest = XCHAT_PRI_LOWEST
}

private enum PDIWORDS = 32;

// TODO: Really inefficent for words_eol
private void getWords(const(char)** cwords, ref const(char)[][PDIWORDS] words)
{
	foreach(i; 1 .. PDIWORDS)
	{
		if(auto cword = cwords[i])
			words[i - 1] = fromStringz(cword);
		else
			break;
	}
}

void hookCommand(in char[] cmd,
				 EatMode function(in char[][] words, in char[][] words_eol) callback,
				 in char[] helpText = null,
				 CommandPriority priority = CommandPriority.normal)
{
	extern(C) static int xchat_cmd_cb(const(char)** cwords, const(char)** cwords_eol, void* ud)
	{
		const(char)[][PDIWORDS] words, words_eol;
		getWords(cwords, words);
		getWords(cwords_eol, words_eol);

		auto cb = cast(typeof(callback))ud;

		return cb(words, words_eol);
	}

	xchat_hook_command(ph, toStringz(cmd), priority, &xchat_cmd_cb, helpText? toStringz(helpText) : null, callback);
}


void hookCommand(in char[] cmd,
				 EatMode delegate(in char[][] words, in char[][] words_eol) callback,
				 in char[] helpText = null,
				 CommandPriority priority = CommandPriority.normal)
{
	static struct CallbackData
	{
		typeof(callback) cb;
	}

	extern(C) static int xchat_cmd_cb(const(char)** cwords, const(char)** cwords_eol, void* ud)
	{
		const(char)[][PDIWORDS] words, words_eol;
		getWords(cwords, words);
		getWords(cwords_eol, words_eol);

		auto data = cast(CallbackData*)ud;

		return data.cb(words, words_eol);
	}

	auto data = new CallbackData;
	data.cb = callback;

	xchat_hook_command(ph, toStringz(cmd), priority, &xchat_cmd_cb, helpText? toStringz(helpText) : null, data);
}

void hookPrint(in char[] cmd,
			   EatMode function(in char[][] words) callback,
			   CommandPriority priority = CommandPriority.normal)
{
	extern(C) static int xchat_print_cb(const(char)** cwords, void* ud)
	{
		const(char)[][PDIWORDS] words;
		getWords(cwords, words);

		auto cb = cast(typeof(callback))ud;

		return cb(words);
	}

	xchat_hook_print(ph, toStringz(cmd), priority, &xchat_print_cb, callback);
}

void hookPrint(in char[] cmd,
			   EatMode delegate(in char[][] words) callback,
			   CommandPriority priority = CommandPriority.normal)
{
	static struct CallbackData
	{
		typeof(callback) cb;
	}

	extern(C) static int xchat_print_cb(const(char)** cwords, void* ud)
	{
		const(char)[][PDIWORDS] words;
		getWords(cwords, words);

		auto data = cast(CallbackData*)ud;

		return data.cb(words);
	}

	auto data = new CallbackData;
	data.cb = callback;

	xchat_hook_print(ph, toStringz(cmd), priority, &xchat_print_cb, data);
}
