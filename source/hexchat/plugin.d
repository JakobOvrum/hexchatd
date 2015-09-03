module hexchat.plugin;

import hexchat.capi;

import std.array;
import std.conv;
import std.string;
import core.stdc.string : strlen;
import core.stdc.stdio;

// Note: to!string will currently make a copy unconditionally, hence this.
private inout(char)[] fromStringz(inout(char)* cstr)
{
	return cstr[0 .. strlen(cstr)];
}

private __gshared hexchat_plugin *ph; // Plugin handle

struct PluginInfo
{
	string name;
	string description;
	string version_;
}

private __gshared PluginInfo pluginInfo;

// Internal, has to be public because of the below mixin strings.
int _hexchatInitPlugin(void* plugin_handle,
							 immutable(char)** plugin_name,
							 immutable(char)** plugin_desc,
							 immutable(char)** plugin_version,
							 void function(ref PluginInfo) initFunc)
{
	ph = cast(hexchat_plugin*)plugin_handle;

	if(plugin_name && *plugin_name)
		pluginInfo.name = fromStringz(*plugin_name);

	if(plugin_desc && *plugin_desc)
		pluginInfo.description = fromStringz(*plugin_desc);

	if(plugin_version && *plugin_version)
		pluginInfo.version_ = fromStringz(*plugin_version);

	try
	{
		initFunc(pluginInfo);
	}
	catch(Throwable e)
	{
		auto message = e.toString();
		hexchat_printf(ph, `Error initializing plugin "%.*s": %.*s`.ptr, pluginInfo.name.length, pluginInfo.name.ptr, message.length, message.ptr);
		return 0;
	}

	if(pluginInfo.name)
		*plugin_name = toStringz(pluginInfo.name);

	if(pluginInfo.description)
		*plugin_desc = toStringz(pluginInfo.description);

	if(pluginInfo.version_)
		*plugin_version = toStringz(pluginInfo.version_);

	return 1; // Return 1 for success
}

// Internal, has to be public because of the below mixin strings.
int _hexchatShutdownPlugin(void function() shutdownFunc)
{
	try
	{
		shutdownFunc();
	}
	catch(Throwable e)
	{
		auto message = e.toString();
		fprintf(stderr,`Error initializing plugin "%.*s": %.*s`, pluginInfo.name.length, pluginInfo.name.ptr, message.length, message.ptr);
		return 0;
	}
	return 1; // Return 1 for success
}

//TODO: verify initFunc signature
template Plugin(alias initFunc)
{
	enum Plugin =
		// The first exported C symbol always gets a preceeding
		// underscore on Windows with DMD/OPTLINK, but hexchat
		// expects "hexchat_plugin_init" exactly.
		"version(Windows) export extern(C) void _systemconvdummy() {}\n" ~
		"export extern(C) int hexchat_plugin_init(void* ph," ~
		"	immutable(char)** name, immutable(char)** desc, immutable(char)** version_, char* arg)" ~
		"{" ~
		"	return _hexchatInitPlugin(ph, name, desc, version_, &" ~ __traits(identifier, initFunc) ~ ");" ~
		"}";
}

//TODO: verify deinitFunc signature
template Plugin(alias initFunc, alias deinitFunc)
{
	enum Plugin = Plugin!initFunc ~
		"export extern(C) int hexchat_plugin_deinit(void* ph) {" ~
		"	return _hexchatShutdownPlugin(&" ~ __traits(identifier, deinitFunc) ~ ");" ~
		"}";
}

void writefln(FmtArgs...)(const(char)[] fmt, FmtArgs fmtArgs)
{
	static if(fmtArgs.length != 0)
	{
		fmt = format(fmt, fmtArgs);
	}

	hexchat_printf(ph, "%.*s".ptr, fmt.length, fmt.ptr);
}

void commandf(FmtArgs...)(const(char)[] fmt, FmtArgs fmtArgs)
{
	static if(fmtArgs.length != 0)
	{
		fmt = format(fmt, fmtArgs);
	}

	hexchat_commandf(ph, "%.*s", fmt.length, fmt.ptr);
}

string getInfo(in char[] id)
{
	return to!string((hexchat_get_info(ph, toStringz(id))));
}

void readInfo(in char[] id, void delegate(in char[] info) dg)
{
	dg(fromStringz(hexchat_get_info(ph, toStringz(id))));
}

struct User
{
	const(char)[] nick, userName, hostName;
}

User parseUser(const(char)[] user)
{
	auto nick = user.munch("^!");
	auto userName = user.munch("^@");

	userName.popFront(); // Skip exclamation mark
	user.popFront(); // Skip at-mark

	return User(nick, userName, user);
}

/// Event consumption behavior.
enum EatMode
{
	none = HEXCHAT_EAT_NONE, /// Pass it on through.
	hexchat = HEXCHAT_EAT_HEXCHAT, /// Don't let xchat see this event.
	plugin = HEXCHAT_EAT_PLUGIN, /// Don't let other plugins see this event.
	all = HEXCHAT_EAT_HEXCHAT | HEXCHAT_EAT_PLUGIN /// Don't let anything see this event.
}

///
enum CommandPriority
{
	highest = HEXCHAT_PRI_HIGHEST, ///
	high = HEXCHAT_PRI_HIGH, ///
	normal = HEXCHAT_PRI_NORM, ///
	low = HEXCHAT_PRI_LOW, ///
	lowest = HEXCHAT_PRI_LOWEST ///
}

private enum PDIWORDS = 32;
private alias const(char)[][PDIWORDS] WordBuffer;

// TODO: Really inefficent for words_eol
private const(char)[][] getWords(const(char)** cwords, ref const(char)[][PDIWORDS] words)
{
	foreach(i; 1 .. PDIWORDS)
	{
		auto cword = cwords[i];
		if(cword[0])
			words[i - 1] = fromStringz(cword);
		else
			return words[0 .. i - 1];
	}
	return words[];
}

private EatMode handleCallback(alias cb, string type, Args...)(Args args)
{
	try
	{
		return cb(args);
	}
	catch(Throwable e)
	{
		writefln("Error in " ~ type ~ " callback: %s", e.toString());
	}
	return EatMode.none;
}

/**
* Hook a server message.
*
* Params:
*   type = _type of message to hook
*   callback = _callback function or delegate
*   priority = priority of this hook. Should be CommandPriority.normal
*/
void hookServer(in char[] type,
				 EatMode function(in char[][] words, in char[][] words_eol) callback,
				 CommandPriority priority = CommandPriority.normal)
{
	alias typeof(callback) Callback; // Workaround for older compiler versions

	extern(C) static int hexchat_serv_cb(const(char)** cwords, const(char)** cwords_eol, void* ud)
	{
		WordBuffer words_buffer, words_eol_buffer;
		auto words = getWords(cwords, words_buffer);
		auto words_eol = getWords(cwords_eol, words_eol_buffer);

		auto cb = cast(Callback)ud;

		return handleCallback!(cb, "server")(words, words_eol);
	}

	hexchat_hook_server(ph, toStringz(type), priority, &hexchat_serv_cb, callback);
}

/// Ditto
void hookServer(in char[] type,
				EatMode delegate(in char[][] words, in char[][] words_eol) callback,
				CommandPriority priority = CommandPriority.normal)
{
	static struct CallbackData
	{
		typeof(callback) cb;
	}

	extern(C) static int hexchat_serv_cb(const(char)** cwords, const(char)** cwords_eol, void* ud)
	{
		WordBuffer words_buffer, words_eol_buffer;
		auto words = getWords(cwords, words_buffer);
		auto words_eol = getWords(cwords_eol, words_eol_buffer);

		auto cb = (cast(CallbackData*)ud).cb;

		return handleCallback!(cb, "server")(words, words_eol);
	}

	auto data = new CallbackData;
	data.cb = callback;

	hexchat_hook_server(ph, toStringz(type), priority, &hexchat_serv_cb, data);
}

/**
 * Hook a chat command.
 *
 * Params:
 *   cmd = name of command
 *   callback = _callback function or delegate
 *   helpText = instructions for this command, displayed when the $(D /help <cmd>) command is invoked
 *   priority = priority of this hook. Should be CommandPriority.normal
 */
void hookCommand(in char[] cmd,
				 EatMode function(in char[][] words, in char[][] words_eol) callback,
				 in char[] helpText = null,
				 CommandPriority priority = CommandPriority.normal)
{

	alias typeof(callback) Callback; // Workaround for older compiler versions

	extern(C) static int hexchat_cmd_cb(const(char)** cwords, const(char)** cwords_eol, void* ud)
	{
		WordBuffer words_buffer, words_eol_buffer;
		auto words = getWords(cwords, words_buffer);
		auto words_eol = getWords(cwords_eol, words_eol_buffer);

		auto cb = cast(Callback)ud;

		return handleCallback!(cb, "command")(words, words_eol);
	}

	hexchat_hook_command(ph, toStringz(cmd), priority, &hexchat_cmd_cb, helpText? toStringz(helpText) : null, callback);
}

/// Ditto
void hookCommand(in char[] cmd,
				 EatMode delegate(in char[][] words, in char[][] words_eol) callback,
				 in char[] helpText = null,
				 CommandPriority priority = CommandPriority.normal)
{
	static struct CallbackData
	{
		typeof(callback) cb;
	}

	extern(C) static int hexchat_cmd_cb(const(char)** cwords, const(char)** cwords_eol, void* ud)
	{
		WordBuffer words_buffer, words_eol_buffer;
		auto words = getWords(cwords, words_buffer);
		auto words_eol = getWords(cwords_eol, words_eol_buffer);

		auto cb = (cast(CallbackData*)ud).cb;

		return handleCallback!(cb, "command")(words, words_eol);
	}

	auto data = new CallbackData;
	data.cb = callback;

	hexchat_hook_command(ph, toStringz(cmd), priority, &hexchat_cmd_cb, helpText? toStringz(helpText) : null, data);
}

/**
 * Hook a print event.
 *
 * The list of text events can be found in $(D Settings -> Advanced -> Text Events...);
 * the list at the bottom of the window describes the contents of the $(D words) callback
 * parameter for a particular event.
 * Params:
 *   name = _name of event
 *   callback = _callback function or delegate
 *   priority = priority of this hook. Should be CommandPriority.normal
 */
void hookPrint(in char[] name,
			   EatMode function(in char[][] words) callback,
			   CommandPriority priority = CommandPriority.normal)
{
	alias typeof(callback) Callback; // Workaround for older compiler versions

	extern(C) static int hexchat_print_cb(const(char)** cwords, void* ud)
	{
		WordBuffer words_buffer;
		auto words = getWords(cwords, words_buffer);

		auto cb = cast(Callback)ud;

		return handleCallback!(cb, "print")(words);
	}

	hexchat_hook_print(ph, toStringz(name), priority, &hexchat_print_cb, callback);
}

/// Ditto
void hookPrint(in char[] name,
			   EatMode delegate(in char[][] words) callback,
			   CommandPriority priority = CommandPriority.normal)
{
	static struct CallbackData
	{
		typeof(callback) cb;
	}

	extern(C) static int hexchat_print_cb(const(char)** cwords, void* ud)
	{
		WordBuffer words_buffer;
		auto words = getWords(cwords, words_buffer);

		auto cb = (cast(CallbackData*)ud).cb;

		return handleCallback!(cb, "print")(words);
	}

	auto data = new CallbackData;
	data.cb = callback;

	hexchat_hook_print(ph, toStringz(name), priority, &hexchat_print_cb, data);
}

