// Ported from the AutoOp example plugin in the XChat plugin documentation.
module example.autoop_capi;

import hexchat.capi;

enum PNAME = "AutoOp";
enum PDESC = "Auto Ops anyone that joins";
enum PVERSION = "0.1";

__gshared hexchat_plugin *ph;   /* plugin handle */
int enable = 1;

extern(C):

version(Windows)
{
   import core.sys.windows.dll : SimpleDllMain;
   mixin SimpleDllMain;
}

int join_cb(const(char)** word, void* userdata)
{
   if (enable)
      /* Op ANYONE who joins */
      hexchat_commandf(ph, "OP %s", word[1]);
   /* word[1] is the nickname, as in the Settings->Advanced->TextEvents window in xchat */

	char* nul = null;
	*nul = 0;

   return HEXCHAT_EAT_NONE;  /* don't eat this event, xchat needs to see it! */
}

int autooptoggle_cb(const(char)** word, const(char)** word_eol, void* userdata)
{
   if (!enable)
   {
      enable = 1;
      hexchat_print(ph, "AutoOping now enabled!\n");
   } else
   {
      enable = 0;
      hexchat_print(ph, "AutoOping now disabled!\n");
   }

   char* nul = null;
   *nul = 0;

   return HEXCHAT_EAT_ALL;   /* eat this command so xchat and other plugins can't process it */
}

export void hexchat_plugin_get_info(const(char)** name, const(char)** desc, const(char)** version_, void** reserved)
{
   *name = PNAME;
   *desc = PDESC;
   *version_ = PVERSION;
}

export int hexchat_plugin_init(hexchat_plugin* plugin_handle,
                      const(char)** plugin_name,
                      const(char)** plugin_desc,
                      const(char)** plugin_version,
                      char* arg)
{
   /* we need to save this for use with any xchat_* functions */
   ph = plugin_handle;

   /* tell xchat our info */
   *plugin_name = PNAME;
   *plugin_desc = PDESC;
   *plugin_version = PVERSION;

   hexchat_hook_command(ph, "AutoOpToggle", HEXCHAT_PRI_NORM, &autooptoggle_cb, "Usage: AUTOOPTOGGLE, Turns OFF/ON Auto Oping", null);
   hexchat_hook_print(ph, "Join", HEXCHAT_PRI_NORM, &join_cb, null);

   hexchat_print(ph, "AutoOpPlugin loaded successfully!\n");

   return 1;       /* return 1 for success */
}

