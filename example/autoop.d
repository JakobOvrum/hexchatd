module example.autoop;

import xchat.plugin;

bool enabled = true;

EatMode join(in char[][] words)
{
	if (enabled)
		commandf("OP %s", words[0]);

	return EatMode.none;
}

EatMode autooptoggle(in char[][] word, in char[][] word_eol)
{
	if(!enabled)
	{
		enabled = true;
		writefln("AutoOping now enabled!");
	}
	else
	{
		enabled = false;
		writefln("AutoOping now disabled!");
	}

	return EatMode.all;
}

void initPlugin(ref PluginInfo info)
{
	info.name = "AutoOp";
	info.description = "Auto Ops anyone that joins";
	info.version_ = "0.1";

	hookCommand("AutoOpToggle", &autooptoggle, "Usage: AUTOOPTOGGLE, Turns OFF/ON Auto Oping");
	hookPrint("Join", &join);

	writefln("AutoOpPlugin loaded successfully!");
}

mixin(XchatPlugin!initPlugin);
