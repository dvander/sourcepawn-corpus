#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

#define YELLOW				0x01
#define NAMECOLOR			0x02
#define TEAMCOLOR			0x03
#define GREEN				0x04

new g_iLastCTKilling = -1;
new Handle:g_hBombThiefPunishMenu = INVALID_HANDLE;
new g_iCurrentDefuser = -1;

public Plugin:myinfo = 
{
	name = "Bomb Thief",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "CT who killed the last T has the privlege to defuse the bomb.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	CreateConVar("sm_bombthief_version", PLUGIN_VERSION, _, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("bomb_begindefuse", Event_BombBeginDefuse);
	HookEvent("bomb_abortdefuse", Event_BombAbortDefuse);
	HookEvent("bomb_defused", Event_BombDefused);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_team", Event_PlayerTeam);
}

public OnClientDisconnect(client)
{
	if(client == g_iLastCTKilling)
		g_iLastCTKilling = -1;
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new oldteam = GetEventInt(event, "oldteam");
	
	// Last killing CT changed his team?
	if(client == g_iLastCTKilling && oldteam == CS_TEAM_CT)
	{
		g_iLastCTKilling = -1;
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iLastCTKilling = -1;
	g_iCurrentDefuser = -1;
	if(g_hBombThiefPunishMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hBombThiefPunishMenu);
		g_hBombThiefPunishMenu = INVALID_HANDLE;
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	// CT died?
	if(g_iLastCTKilling == client)
		g_iLastCTKilling = -1;
	
	// replace the old last attacker
	if(attacker > 0 
	   && IsClientInGame(attacker) 
	   && IsPlayerAlive(attacker) 
	   && GetClientTeam(attacker) == CS_TEAM_CT 
	   && GetClientTeam(client) == CS_TEAM_T)
	{
		g_iLastCTKilling = attacker;
	}
}

public Action:Event_BombBeginDefuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:haskit = GetEventBool(event, "haskit");
	
	// No T alive?
	for(new i=1;i<MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
			return Plugin_Continue;
		
	}
	
	g_iCurrentDefuser = client;
	
	if(client == g_iLastCTKilling || g_iLastCTKilling == -1)
		return Plugin_Continue;
	
	g_hBombThiefPunishMenu = CreateMenu(Menu_BombThiefPunish);
	SetMenuTitle(g_hBombThiefPunishMenu, "A thief is trying to steal your bomb:");
	AddMenuItem(g_hBombThiefPunishMenu, "allow", "Let him defuse.");
	AddMenuItem(g_hBombThiefPunishMenu, "slay", "Punish the bomb thief.");
	
	SetMenuExitButton(g_hBombThiefPunishMenu, true);
	
	if(haskit)
		SetEntProp(g_iLastCTKilling, Prop_Send, "m_iProgressBarDuration", 5);
	else
		SetEntProp(g_iLastCTKilling, Prop_Send, "m_iProgressBarDuration", 10);
	
	SetEntPropFloat(g_iLastCTKilling, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	
	DisplayMenu(g_hBombThiefPunishMenu, g_iLastCTKilling, MENU_TIME_FOREVER);
	
	return Plugin_Continue;
}

public Menu_BombThiefPunish(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		g_hBombThiefPunishMenu = INVALID_HANDLE;
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:opt[256];
		GetMenuItem(menu, param2, opt, sizeof(opt));
		
		if(StrEqual(opt[0], "allow"))
		{
			PrintToChat(g_iCurrentDefuser, "%c[Bomb Thief]%c %N %callowed you to defuse this bomb. The player who killed the last T has priority.", GREEN, YELLOW, g_iLastCTKilling, TEAMCOLOR);
			PrintToChat(g_iLastCTKilling, "%c[Bomb Thief]%c You allowed%c %N %cto defuse the bomb.", GREEN, TEAMCOLOR, YELLOW, g_iCurrentDefuser, TEAMCOLOR);
		}
		else if(StrEqual(opt[0], "slay"))
		{
			ForcePlayerSuicide(g_iCurrentDefuser);
			PrintToChat(g_iCurrentDefuser, "%c[Bomb Thief]%c %N %chas priority to this bomb, since he killed the last T.", GREEN, YELLOW, g_iLastCTKilling, TEAMCOLOR);
			PrintToChat(g_iLastCTKilling, "%c[Bomb Thief]%c You did not allow%c %N %cto defuse the bomb.", GREEN, TEAMCOLOR, YELLOW, g_iCurrentDefuser, TEAMCOLOR);
		}
		SetEntProp(g_iLastCTKilling, Prop_Send, "m_iProgressBarDuration", 0);
	}
}

public Action:Event_BombAbortDefuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_iCurrentDefuser = -1;
	
	if(client == g_iLastCTKilling || g_iLastCTKilling == -1)
		return Plugin_Continue;
	
	SetEntProp(g_iLastCTKilling, Prop_Send, "m_iProgressBarDuration", 0);
	
	if(g_hBombThiefPunishMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hBombThiefPunishMenu);
		g_hBombThiefPunishMenu = INVALID_HANDLE;
	}
	
	PrintToChat(g_iLastCTKilling, "%c[Bomb Thief]%c %N %cstopped to defuse the bomb.", GREEN, YELLOW, g_iCurrentDefuser, TEAMCOLOR);
	
	return Plugin_Continue;
}

public Action:Event_BombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client == g_iLastCTKilling || g_iLastCTKilling == -1)
		return Plugin_Continue;
	
	SetEntProp(g_iLastCTKilling, Prop_Send, "m_iProgressBarDuration", 0);
	
	return Plugin_Continue;
}