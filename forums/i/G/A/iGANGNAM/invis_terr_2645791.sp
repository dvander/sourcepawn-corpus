#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#define CS_TEAM_T 2

#define IsValidAlive(%1) ( 1 <= %1 <= MaxClients && IsClientInGame(%1) && IsPlayerAlive(%1) )

ConVar cvarAlpha;
int m_flNextSecondaryAttack = -1;
int m_flNextPrimaryAttack = -1;

public Plugin myinfo =
{
    name = "Invisible zombie",
    author = "Prefix",
    description = "Invisible zombie for CS:GO",
    version = "0.1",
    url = "https://forums.alliedmods.net/showthread.php?t=315247"
};

public void OnPluginStart()
{
    cvarAlpha = FindConVar("sv_disable_immunity_alpha");
    if(cvarAlpha != null) SetConVarInt(cvarAlpha, 1);
    HookEvent("round_start", eventRound);
    m_flNextSecondaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack");
    m_flNextPrimaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack");
}

public void OnClientPostAdminCheck(int client)
{
    SDKHook(client, SDKHook_SetTransmit, onSetTransmit);
}

public int GetPlayerCount()
{
    int players;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
            players++;
    }
    return players;
} 

public void eventRound(Event event, const char[] name, bool dontBroadcast)
{
	if (GetPlayerCount() == 0)
		return;

	ServerCommand("bot_kick")
	ServerCommand("bot_add_t")
	RequestFrame(OnNextFrame);
}

public void OnNextFrame(any data) {
    for (int client = 1; client <= MaxClients; client++) 
    {
        if (IsClientConnected(client))
            continue;
        if (!IsFakeClient(client))
            continue;
        if (IsClientSourceTV(client)) {
            int team = GetClientTeam(client);
            if (team == CS_TEAM_CT || team == CS_TEAM_T)
                CS_SwitchTeam(client, CS_TEAM_SPECTATOR)
            continue;
        }
        if (GetClientTeam(client) != CS_TEAM_T)
        	CS_SwitchTeam(client, CS_TEAM_T);
        CS_RespawnPlayer(client);
        RequestFrame(OnAnotherNextFrame, client);
        
    }
}

public void OnAnotherNextFrame(any bot) {
    if (IsClientConnected(bot))
        return;
    if (!IsFakeClient(bot))
        return;
    if (GetClientTeam(bot) != CS_TEAM_T) {
    	CS_SwitchTeam(bot, CS_TEAM_T);
    }
    SDKHook(bot, SDKHook_PreThink, OnPreThink);
    SetEntityMoveType(bot, MOVETYPE_NONE);
    SetEntProp(bot, Prop_Data, "m_takedamage", 1, 1);
}

public Action OnPreThink(int client)
{
    int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    
    if (!IsClientInGame(client))
        return Plugin_Continue;
    if (!IsFakeClient(client))
        return Plugin_Continue;
    if (IsClientSourceTV(client))
        return Plugin_Continue;

    if (!IsValidEdict(iWeapon))
    {
        return Plugin_Continue;
    }

    char classname[MAX_NAME_LENGTH];
    GetEdictClassname(iWeapon, classname, sizeof(classname));
    if (StrContains(classname, "weapon") != -1)
    {
        SetEntDataFloat(iWeapon, m_flNextPrimaryAttack, GetGameTime() + 1.0); // block primary attack
        SetEntDataFloat(iWeapon, m_flNextSecondaryAttack, GetGameTime() + 1.0); // block secondary attack
    }

    return Plugin_Continue;
}  

public Action onSetTransmit(int entity, int client) 
{
    if ( !IsFakeClient(entity) || !IsPlayerAlive(entity) ) return Plugin_Continue;
    if ( !IsValidAlive(client) ) return Plugin_Continue;

    if (entity == client) return Plugin_Continue;

    if ( GetClientTeam(entity) == CS_TEAM_T )
        return Plugin_Handled; 

    return Plugin_Continue;
}