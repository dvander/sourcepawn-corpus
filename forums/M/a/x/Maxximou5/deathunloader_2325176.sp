#define PLUGIN_VERSION                  "1.0.0"
#define PLUGIN_NAME                     "Death Unloader"
#define PLUGIN_DESCRIPTION              "Unloads this plugin on Event_OnPlayerDeath."

#include <sdkhooks>

public Plugin myinfo =
{
    name            = PLUGIN_NAME,
    author          = "Maxximou5",
    description     = PLUGIN_DESCRIPTION,
    version         = PLUGIN_VERSION,
    url             = "http://maxximou5.com/"
};

public void OnPluginStart()
{
    //Event hooks
    HookEvent("player_death", Event_OnPlayerDeath);
}

public Action Event_OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    new Handle:plugin = GetMyHandle(), String:nameOfPlugin[256];
    GetPluginFilename(plugin, nameOfPlugin, sizeof(nameOfPlugin));
    ServerCommand("sm plugins unload %s", nameOfPlugin);

    PrintToServer("%s was disabled!", nameOfPlugin);

    return Plugin_Handled;
}