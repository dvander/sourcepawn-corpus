#define PLUGIN_VERSION                  "1.0.0"
#define PLUGIN_NAME                     "Death Unloader Specific"
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
    ServerCommand("sm plugins unload NameOfPlugin");

    PrintToServer("NameOfPlugin was disabled!");

    return Plugin_Handled;
}