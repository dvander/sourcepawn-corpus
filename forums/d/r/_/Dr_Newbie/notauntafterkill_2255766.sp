#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.0.0"

new Handle:g_cvarNoTauntAfterKillEnable = INVALID_HANDLE;
new g_isEnabled;
new Handle:BlockTauntTimers[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "No Taunt After Kill",
	author = "Dr_Newbie",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	g_cvarNoTauntAfterKillEnable = CreateConVar("sm_notaunt_enable", "1", "No taunt after killing someone (1 = ON ; 0 = OFF)", FCVAR_PLUGIN);
	g_isEnabled = GetConVarInt(g_cvarNoTauntAfterKillEnable);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookConVarChange(g_cvarNoTauntAfterKillEnable, CVarChange);
	AddCommandListener(TauntDoCmd, "taunt");
	AddCommandListener(TauntDoCmd, "+taunt");
}

public CVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == g_cvarNoTauntAfterKillEnable)
		g_isEnabled = GetConVarInt(g_cvarNoTauntAfterKillEnable);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (BlockTauntTimers[attacker] != INVALID_HANDLE)
		KillTimer(BlockTauntTimers[attacker]);
	BlockTauntTimers[attacker] = CreateTimer(5.0, BlockTauntTimer, GetClientSerial(attacker));
}

public Action:TauntDoCmd(iClient, const String:strCommand[], iArgs)
{
	if(g_isEnabled <= 0 || !IsValidClient(iClient))
		return Plugin_Continue;

	if(BlockTauntTimers[iClient] != INVALID_HANDLE)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action:BlockTauntTimer(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	if (client != 0)
		BlockTauntTimers[client] = INVALID_HANDLE;
}

stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}