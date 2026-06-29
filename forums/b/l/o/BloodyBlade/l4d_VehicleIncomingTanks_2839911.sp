#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

public Plugin myinfo = 
{
    name        = "[L4D] Vehicle Incoming Tanks",
    author      = "BloodyBlade",
    description = "Spawn more tanks on vehicle incoming",
    version     = PLUGIN_VERSION,
    url         = "https://bloodsiworld.ru"
};

ConVar hPluginEnable, hNeedTankCount;
bool bL4D2 = false, bHooked = false, bIsIncoming = false;
int zClassTank = 5, iNeedTankCount = 0, iTankCount = 0;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine == Engine_Left4Dead)
    {
        bL4D2 = false;
        zClassTank = 5;
    }
    else if(engine == Engine_Left4Dead2)
    {
        bL4D2 = true;
        zClassTank = 8;
    }
    else
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" game series");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{	
    CreateConVar("l4d_vehicle_incoming_tanks_version", PLUGIN_VERSION, "[L4D] Vehicle Incoming Tanks plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
    hPluginEnable = CreateConVar("l4d_vehicle_incoming_tanks_enable", "1", "Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
    hNeedTankCount = CreateConVar("l4d_vehicle_incoming_tanks_tankcount", "4"," How many tanks shall spawn", CVAR_FLAGS, true, 2.0, true, 8.0);

    AutoExecConfig(true, "l4d_vehicle_incoming_tanks");

    hPluginEnable.AddChangeHook(OnConVarPluginOnChange);
    hNeedTankCount.AddChangeHook(ConVarChanged_Cvars);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void ConVarChanged_Cvars(ConVar cvar, const char[] oldVal, const char[] newVal)
{
    iNeedTankCount = hNeedTankCount.IntValue;
}

void IsAllowed()
{
    bool bPluginOn = hPluginEnable.BoolValue;
    if(!bHooked && bPluginOn)
    {
        bHooked = true;
        ConVarChanged_Cvars(null, "", "");
        HookEvent("finale_vehicle_incoming", Events);
        HookEvent("finale_vehicle_leaving", Events);
        HookEvent("player_spawn", Events);
        HookEvent("player_death", Events);
        HookEvent("round_end", Events);
        HookEvent("map_transition", Events);
        HookEvent("finale_win", Events);
    }
    else if(bHooked && !bPluginOn)
    {
        bHooked = false;
        UnhookEvent("finale_vehicle_incoming", Events);
        UnhookEvent("finale_vehicle_leaving", Events);
        UnhookEvent("player_spawn", Events);
        UnhookEvent("player_death", Events);
        UnhookEvent("round_end", Events);
        UnhookEvent("map_transition", Events);
        UnhookEvent("finale_win", Events);
    }
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
    if (strcmp(name, "finale_vehicle_incoming") == 0)
    {
        bIsIncoming = true;
    }
    else if(strcmp(name, "player_spawn") == 0)
    {
        if(bIsIncoming)
        {
            int iTank = GetClientOfUserId(event.GetInt("userid"));
            if(IsTank(iTank))
            {
                iTankCount++;
                if(iTankCount < iNeedTankCount)
                {
                    if(bL4D2)
                    {
                        int flags = GetCommandFlags("z_spawn_old");
                        SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
                        ServerCommand("z_spawn_old tank auto");
                        SetCommandFlags("z_spawn_old", flags);
                    }
                    else
                    {
                        int flags = GetCommandFlags("z_spawn");
                        SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
                        ServerCommand("z_spawn tank auto");
                        SetCommandFlags("z_spawn", flags);
                    }
                }
            }
        }
    }
    else if(strcmp(name, "player_death") == 0)
    {
        if(bIsIncoming)
        {
            int iTank = GetClientOfUserId(event.GetInt("userid"));
            if(IsTank(iTank))
            {
                if(iTankCount > 0)
                {
                    iTankCount--;
                }
            }
        }
    }
    else if(strcmp(name, "finale_vehicle_leaving") == 0 || strcmp(name, "round_end") == 0 || strcmp(name, "map_transition") == 0 || strcmp(name, "finale_win") == 0)
    {
        bIsIncoming = false;
        iTankCount = 0;
    }
    return Plugin_Continue;
}

stock bool IsTank(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == zClassTank;
}
