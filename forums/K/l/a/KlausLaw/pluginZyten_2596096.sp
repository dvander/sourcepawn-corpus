#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Klaus"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>


public Plugin myinfo = 
{
	name = "Plugin for Zyten", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

float g_savedOrg[MAXPLAYERS + 1][3];
float g_savedAng[MAXPLAYERS + 1][3];

public void OnPluginStart()
{
	RegConsoleCmd("sm_sloc", SM_SaveLoc);
	RegConsoleCmd("sm_tpme", SM_TeleportMe);
	RegConsoleCmd("sm_noclipme", SM_Noclipme);
}

public Action SM_SaveLoc(int client, int args)
{
	GetClientAbsOrigin(client, g_savedOrg[client]);
	GetClientAbsAngles(client, g_savedAng[client]);
	
	ReplyToCommand(client, "Your location has been saved.");
	return Plugin_Handled;
}

public Action SM_TeleportMe(int client, int args)
{
	if (IsPlayerAlive(client))
	{
		ReplyToCommand(client, "You can't teleport while your are alive.");
		return Plugin_Handled;
	}
	
	TeleportEntity(client, g_savedOrg[client], g_savedAng[client], NULL_VECTOR);
	ReplyToCommand(client, "You have been teleported to your saved location.");
	return Plugin_Handled;
}

public Action SM_Noclipme(int client, int args)
{
	if (IsPlayerAlive(client))
	{
		ReplyToCommand(client, "You can't use noclip while you are alive.");
		return Plugin_Handled;
	}
	if (GetEntityMoveType(client) == MOVETYPE_WALK)
	{
		SetEntityMoveType(client, MOVETYPE_NOCLIP);
		ReplyToCommand(client, "Noclip is now on.");
	}
	else
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		ReplyToCommand(client, "Noclip is now off.");
	}
	return Plugin_Handled;
}

