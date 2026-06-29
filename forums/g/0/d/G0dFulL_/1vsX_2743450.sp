#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin:myinfo = 
{
    name = "1vsX Clutch Situation",
    author = "G0dFulL & SSher1FF",
    description = "Plugin Originally made by G0dFulL but rewrote by SSher1FF, helps with muteing dead people in a clutch situation",
	version     = "1.1",
    url = "https://death.ro/"
}

#pragma semicolon 1
#pragma newdecls required
ConVar sv_full_alltalk;

int playersalivet = 0;
int playersalivect = 0;
bool alreadyannouced = false;
public void OnPluginStart()
{
	HookEvent("player_death", Event_OnPlayerDeath);
    HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);
    HookEvent("round_start", RoundStart,EventHookMode_Post);
    HookEvent("round_end", RoundEnd, EventHookMode_Pre);
    sv_full_alltalk = FindConVar("sv_full_alltalk");
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool bDb)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(GetClientTeam(client)==2)
        playersalivet--;
    else if(GetClientTeam(client)==3)
        playersalivect--;
    if((playersalivet==1 || playersalivect==1) && !alreadyannouced)
    {
        alreadyannouced = true;
        SetConVarInt(sv_full_alltalk, 0);
        PrintHintTextToAll("--<font color='#FF0000'>[1VX] ClutchTime</font> Everyone is getting <font color='#FF0000'>MUTED</font> until the next Round--");
    }
}
public Action RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    alreadyannouced = false;
    playersalivet = 0;
    playersalivect = 0;
    for(int i = 1; i <= MaxClients;i++)
    {
        if(IsClientInGame(i)&&!IsFakeClient(i)&&IsPlayerAlive(i)&&GetClientTeam(i)==2)
            playersalivet++;
        if(IsClientInGame(i)&&!IsFakeClient(i)&&IsPlayerAlive(i)&&GetClientTeam(i)==3)
            playersalivect++;
    }
}
public Action RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
    SetConVarInt(sv_full_alltalk, 1);
}
public Action Event_ServerCvar(Handle event, const char []name, bool dontBroadcast) {
    return Plugin_Handled;
} 