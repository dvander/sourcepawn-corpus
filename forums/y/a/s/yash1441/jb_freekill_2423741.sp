#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Simon"
#define PLUGIN_VERSION "1.1"

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

new bool:Freekilled[MAXPLAYERS + 1] =  { false, ... };

EngineVersion g_Game;

public Plugin:myinfo = 
{
	name = "Jailbreak Freekill Report",
	author = PLUGIN_AUTHOR,
	description = "Freekill report for jailbreak",
	version = PLUGIN_VERSION,
	url = "yash1441@yahoo.com"
};

public OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	CreateConVar("jb_freekill_version", PLUGIN_VERSION, "Jailbreak Freekill Report Version", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	
	RegConsoleCmd("sm_fk", Freekill);
	RegConsoleCmd("sm_freekill", Freekill);
	
	HookEvent("round_start", RoundStart);
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	LoopClients(i)
	{
		Freekilled[i] = false;
	}
	return Plugin_Continue;
}

public Action:Freekill(client, args)
{
	if (GetClientTeam(client) != CS_TEAM_T || IsPlayerAlive(client) || !Freekilled[client])
		return Plugin_Handled;
	
	new Handle:menu = CreateMenu(FreekillHandler);
	SetMenuTitle(menu, "Report Guard:");
	
	decl String:temp2[8], String:temp[128];
	new count = 0;
	for (new i = 1; i < MaxClients; i++)
	{
		if(IsPlayerAlive(i) && GetClientTeam(i) == 3) 
		{
			Format(temp, 128, "%N", i);
			Format(temp2, 8, "%i", i);
			AddMenuItem(menu, temp2, temp);
			
			count++;
		}
	}
	if(count == 0)
	{
		AddMenuItem(menu, "none", "N.A.", ITEMDRAW_DISABLED);
	}
	DisplayMenu(menu, client, 15);
	return Plugin_Handled;
}

public FreekillHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select)
	{
		if (GetClientTeam(client) != CS_TEAM_T || IsPlayerAlive(client))
			return;
			
		decl String:info[11];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		new other = StringToInt(info);
		AskOther(client, other);
	}
}

public AskOther(client, guard)
{
	Freekilled[client] = true;
	new Handle:menu = CreateMenu(FreekillerHandler);
	SetMenuTitle(menu, "Freekilled?");
	new String:clientid[64];
	FormatEx(clientid, sizeof(clientid), "%i", client);
	AddMenuItem(menu, clientid, "Yes");
	AddMenuItem(menu, "no", "No");
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, guard, MENU_TIME_FOREVER);
}

public FreekillerHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select)
	{
		if (GetClientTeam(client) != CS_TEAM_CT || !IsPlayerAlive(client))
			return;
			
		decl String:info[11];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		if (strcmp(info,"no") != 0) 
		{
			new id = StringToInt(info);
			CS_RespawnPlayer(id);
			PrintToChatAll("<--- %N has been respawned -->", id);
		}
	}
}