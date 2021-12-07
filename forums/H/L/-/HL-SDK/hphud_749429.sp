#include <sourcemod>
#include <sdktools>

new Handle:g_hInterval;
new Handle:g_hTimer;
new Handle:HudMessage;

#define PLUGIN_VERSION "0.3.5"

public Plugin:myinfo = {
    name = "HP HUD",
    author = "Allan Button",
    description = "Provides a HUD for how much health you have",
    version = PLUGIN_VERSION,
    url = "http://www.idlecode.com/"
};

public OnPluginStart()
{
    CreateConVar("sm_hphud", PLUGIN_VERSION, "hphud version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
    g_hInterval = CreateConVar("sm_hphud_interval", "5", "How often health timer is updated (in tenths of a second).");
    HookConVarChange(g_hInterval, ConVarChange_Interval);
    HudMessage = CreateHudSynchronizer();
}

public OnMapStart() 
{
    g_hTimer = CreateTimer(GetConVarInt(g_hInterval) * 0.1, Timer_ShowInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_ShowInfo(Handle:timer) {


    for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) 
	{
        if (IsClientInGame(i) && !IsFakeClient(i)) 
		{
            SetHudTextParams(0.04, 0.37, 1.0, 255, 50, 50, 255);
            ShowSyncHudText(i, HudMessage, "Health: %d", GetClientHealth(i));
        }
    }


    return Plugin_Continue
}
public ConVarChange_Interval(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
    if (g_hTimer != INVALID_HANDLE) 
	{
        KillTimer(g_hTimer);
    }
    
    g_hTimer          = CreateTimer(GetConVarInt(g_hInterval) * 0.1, Timer_ShowInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}