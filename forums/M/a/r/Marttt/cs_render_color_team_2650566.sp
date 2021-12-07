#include <sourcemod>
#include <cstrike>

#define PLUGIN_NAME                  "[CS] Render Color Team"
#define PLUGIN_AUTHOR                "Pilo"
#define PLUGIN_DESCRIPTION           "Sets the same color for the Counter-Strike teams."
#define PLUGIN_VERSION               "1.0.1"
#define PLUGIN_URL                   "https://forums.alliedmods.net/showthread.php?t=316034"

public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dB)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    switch (GetClientTeam(client))
    {
        case CS_TEAM_CT: SetEntityRenderColor(client, 0, 0, 255, 255); //Blue (RGBA)
        case CS_TEAM_T: SetEntityRenderColor(client, 255, 0, 0, 255); //Red (RGBA
    }
}