// Ported from the AutoOp example plugin in the XChat plugin documentation.
module example.autoop_capi;

import xchat.capi;

enum PNAME = "AutoOp";
enum PDESC = "Auto Ops anyone that joins";
enum PVERSION = "0.1";

__gshared xchat_plugin *ph;   /* plugin handle */
int enable = 1;

extern(C):

// The first exported C symbol always gets a preceeding
// underscore on Windows with DMD/OPTLINK, but xchat
// expects "xchat_plugin_init" exactly.
version(Windows) export void _systemconvdummy() {}

int join_cb(const(char)** word, void* userdata)
{
   if (enable)
      /* Op ANYONE who joins */
      xchat_commandf(ph, "OP %s", word[1]);
   /* word[1] is the nickname, as in the Settings->Advanced->TextEvents window in xchat */

	char* nul = null;
	*nul = 0;

   return XCHAT_EAT_NONE;  /* don't eat this event, xchat needs to see it! */
}

int autooptoggle_cb(const(char)** word, const(char)** word_eol, void* userdata)
{
   if (!enable)
   {
      enable = 1;
      xchat_print(ph, "AutoOping now enabled!\n");
   } else
   {
      enable = 0;
      xchat_print(ph, "AutoOping now disabled!\n");
   }

   char* nul = null;
   *nul = 0;

   return XCHAT_EAT_ALL;   /* eat this command so xchat and other plugins can't process it */
}

export void xchat_plugin_get_info(const(char)** name, const(char)** desc, const(char)** version_, void** reserved)
{
   *name = PNAME;
   *desc = PDESC;
   *version_ = PVERSION;
}

export int xchat_plugin_init(xchat_plugin* plugin_handle,
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

   xchat_hook_command(ph, "AutoOpToggle", XCHAT_PRI_NORM, &autooptoggle_cb, "Usage: AUTOOPTOGGLE, Turns OFF/ON Auto Oping", null);
   xchat_hook_print(ph, "Join", XCHAT_PRI_NORM, &join_cb, null);

   xchat_print(ph, "AutoOpPlugin loaded successfully!\n");

   return 1;       /* return 1 for success */
}
