#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.2"

int g_iRespawn_Duration[MAXPLAYERS+1];
bool g_bRespawn_Started[MAXPLAYERS+1];
ConVar g_Cvar_PluginEnable;
ConVar g_Cvar_EditVipFlags;
ConVar g_Cvar_RegularTimer;
ConVar g_Cvar_SpecialTimer;
ConVar g_Cvar_RespawnNoWin;
ConVar g_Cvar_RespawnTexts;

public Plugin myinfo =
{
	name = "CS Respawner",
	author = "alasfourom",
	description = "Respawn Players After Death With Timer",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=340201"
};

public void OnPluginStart()
{
	CreateConVar ("cs_respawner_version", PLUGIN_VERSION, "CS Respawner", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_Cvar_PluginEnable = CreateConVar("cs_respawner_plugin_enable", "1", "Enable The Respawner Plugin (0 = Disable, 1 = Enable).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_EditVipFlags = CreateConVar("cs_respawner_vip_flag", "o", "Set The Required Flag For VIP Players (Empty Will Make All Players VIP).", FCVAR_NOTIFY);
	g_Cvar_RegularTimer = CreateConVar("cs_respawner_regular_timer", "15", "Set The Respawn Timer For Regular Players (In Seconds).", FCVAR_NOTIFY);
	g_Cvar_SpecialTimer = CreateConVar("cs_respawner_special_timer", "5", "Set The Respawn Timer For VIP/Admin Players (In Seconds).", FCVAR_NOTIFY);
	g_Cvar_RespawnNoWin = CreateConVar("cs_respawner_ignore_winning", "1", "Ignore Winning Rounds, Making It Infinite (Restart Map Is Required To Take Effect).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_RespawnTexts = CreateConVar("cs_respawner_announcement_type", "2", "Enable Respawn Countdown Announcement (0 = Disable, 1 = Chat, 2 = Hint, 3 = Central).", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	AutoExecConfig(true, "CS_Respawner");
	
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_SLAY, "sm_respawn <#userid|name>");
	
	HookEvent("player_connect_full", Event_PlayerConnect);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnMapStart()
{
	for(int i = 1; i <= MaxClients; i++)
		g_bRespawn_Started[i] = false;
		
	if (g_Cvar_RespawnNoWin.BoolValue) SetConVarInt(FindConVar("mp_ignore_round_win_conditions"), 1);
	else SetConVarInt(FindConVar("mp_ignore_round_win_conditions"), 0);
}

Action Command_Respawn(int client, int args)
{
	if (!client || !IsClientInGame(client) || !g_Cvar_PluginEnable.BoolValue) return Plugin_Handled;
	
	if (args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_respawn <#userid|name>");
		return Plugin_Handled;
	}
	
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int  target_list[MAXPLAYERS + 1], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY,
	target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
		CS_RespawnPlayer(target_list[i]);
	
	return Plugin_Handled;
}

void Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || IsPlayerAlive(client) || !g_Cvar_PluginEnable.BoolValue) return;
	
	g_bRespawn_Started[client] = true;
	g_iRespawn_Duration[client] = 5;
	CreateTimer(1.0, Timer_Respawn, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || IsPlayerAlive(client) || !g_Cvar_PluginEnable.BoolValue) return;
	
	if(GetClientTeam(client) == 1)
	{
		g_bRespawn_Started[client] = false;
		return;
	}
	else if(!g_bRespawn_Started[client])
	{
		g_bRespawn_Started[client] = true;
		if(IsSpecialPlayer(client)) g_iRespawn_Duration[client] = g_Cvar_SpecialTimer.IntValue;
		else g_iRespawn_Duration[client] = g_Cvar_RegularTimer.IntValue;
		CreateTimer(1.0, Timer_Respawn, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || !g_Cvar_PluginEnable.BoolValue) return;
	
	g_bRespawn_Started[client] = true;
	if(IsSpecialPlayer(client)) g_iRespawn_Duration[client] = g_Cvar_SpecialTimer.IntValue;
	else g_iRespawn_Duration[client] = g_Cvar_RegularTimer.IntValue;
	
	CreateTimer(1.0, Timer_Respawn, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Respawn(Handle timer, int client)
{
	if (!IsClientInGame(client) || IsPlayerAlive(client) || !g_bRespawn_Started[client])
		return Plugin_Stop;
	
	int timeleft = g_iRespawn_Duration[client]--;
	if (timeleft >= 0)
	{
		if(g_Cvar_RespawnTexts.IntValue == 1) PrintToChat(client,"\x04[DM] \x01Respawn Timeleft: \x05%d", timeleft);
		else if(g_Cvar_RespawnTexts.IntValue == 2) PrintHintText(client,"Respawn Timeleft: %d", timeleft);
		else if(g_Cvar_RespawnTexts.IntValue == 3) PrintCenterText(client,"Respawn Timeleft: %d", timeleft);
		return Plugin_Continue;
	}
	else
	{
		g_bRespawn_Started[client] = false;
		
		if(g_Cvar_RespawnTexts.IntValue == 1) PrintToChat(client,"\x04[DM] \x01You have been respawned.");
		else if(g_Cvar_RespawnTexts.IntValue == 2) PrintHintText(client,"Respawned");
		else if(g_Cvar_RespawnTexts.IntValue == 3) PrintCenterText(client,"Respawned");
		CS_RespawnPlayer(client);
	}
	return Plugin_Stop;
}

bool IsSpecialPlayer(int client)
{
	char flag[10];
	g_Cvar_EditVipFlags.GetString(flag, sizeof(flag));
	
	if (GetUserFlagBits(client) & ReadFlagString(flag) || GetAdminFlag(GetUserAdmin(client), Admin_Root))
		return true;
		
	return false;
}