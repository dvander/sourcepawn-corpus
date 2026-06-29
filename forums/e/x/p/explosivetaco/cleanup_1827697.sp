#define PLUGIN_FULLNAME                 "CleanUp" // Used when printing the plugin name anywhere
#define PLUGIN_AUTHOR                   "explosivetaco"       // Author of the plugin
#define PLUGIN_DESCRIPTION              "Cleans Up All Props From A Server" // Description of the plugin
#define PLUGIN_VERSION                  "1.1"                               // Version of the plugin
#define PLUGIN_URL                      "www.sourcemod.net"                // URL associated with the project
#define PLUGIN_CVAR_PREFIX              "cleanupv1" // Prefix for plugin cvars

#include <sourcemod>

public Plugin:myinfo = 
{
    name           = PLUGIN_FULLNAME,
    author         = PLUGIN_AUTHOR,
    description    = PLUGIN_DESCRIPTION,
    version        = PLUGIN_VERSION,
    url            = PLUGIN_URL
}

public OnPluginStart()
{
	RegAdminCmd("sm_cleanupprop", Command_CleanUp, ADMFLAG_SLAY, "Cleans Up All Props");
	RegConsoleCmd("say", Command_Hook, "Hook");
}

public:action Command_CleanUp(Client, args)
{
	FakeClientCommand(Client, "ent_remove_all prop_physics");
	FakeClientCommand(Client, "ent_remove_all prop_dynamic");
	PrintToChat(Client, "\x04[CleanUp]\x01 All Of The Props Has Been Cleaned Up.");
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	return Plugin_Handled
}

public:action Command_Hook(Client, args)
{
new String:hook[32];
GetCmdArg(1, hook, sizeof(hook));


	if(StrEqual(prop,"!cleanup"))
	{
		FakeClientCommand(client,"sm_cleanupprop");
		return Plugin_Handled
	}
}