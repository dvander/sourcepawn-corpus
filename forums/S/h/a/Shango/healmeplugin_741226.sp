/*
Tf2 Health Mod
ShangFuu
http://www.stompfest.com

This Plugin is very similar to, and based off of the DoD:S Medic Plugin, when a player types /healme, they are given a certain amount of health, based on cvars.


Versions:
	0.8 - Test version, Printed Amount of uses left, health given etc to all for testing, was not released.
	0.9 - First version submitted to Allied Modders, had one minor mistake and "PrintToChatAll" instead of "PrintToChat(client"
	* so people were advised to use /healme instead of !healme.
	1.0 - Current version, uses PrintToChat(client,) so that no chat spam :D
 
Cvarlist (default value):
	sm_health_max 450 <Maximum Health left to be able to use /healme>
	sm_health_give 35 <Amount of health to give when /healme is used>
	sm_hmenabled 1 <If the plugin is enabled or not>
	sm_hmamount 1 <How many times a player can use the /healme command in one life>
	
Admin Commands:
	None
	

*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "0.9"

new health[33]

;new Handle:cvarhealthmaximum	= INVALID_HANDLE
;new Handle:cvarhealthtogive		= INVALID_HANDLE
;new Handle:cvar_hmenabled			= INVALID_HANDLE
;new Handle:cvar_hmamount		= INVALID_HANDLE;
new g_Used[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "healme",
	author = "Shango",
	description = "Gives Health to players with the Subscriber flag when they type /healme. Can change cvars to modify amount of health given.",
	version = PLUGIN_VERSION,
	url = "www.stompfest.com"
};

public OnPluginStart(){
	CreateConVar("tfs_health_version", PLUGIN_VERSION, "tfs health Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarhealthmaximum = CreateConVar("sm_health_max","450","Maximum Health left to be able to use /healme",FCVAR_PLUGIN);
	cvarhealthtogive = CreateConVar("sm_health_give","35","Amount of health to give to player when /healme is used",FCVAR_PLUGIN);
	cvar_hmenabled 			= CreateConVar("sm_hmenabled", "1", " enables/disables the health mod", FCVAR_PLUGIN);
	cvar_hmamount 	 	= CreateConVar("sm_hmamount", "1", " amount of times per life to be able to use /healme (1 default)", FCVAR_PLUGIN);
	
	LoadTranslations("common.phrases");
	
	HookEvent("player_spawn", PlayerSpawnEvent);
	RegConsoleCmd("sm_healme",Command_Heal,"Gives a set amount of health to a player");
}



public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvar_hmenabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (client > 0)
		{
			if (IsClientInGame(client))
			{		
				GetClientOfUserId(GetEventInt(event, "userid"));
				g_Used[client] = 0;
				SetEntityHealth(client, GetConVarInt(cvarhealthtogive));
			}
		}
	}
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", PlayerSpawnEvent);
}

public Action:Command_Heal(client,args)
{
	if (GetConVarInt(cvar_hmenabled))
	{	
		if (CheckCommandAccess(client, "sm_hmheal", ADMFLAG_RESERVATION, true))
		{
			if (g_Used[client] < GetConVarInt(cvar_hmamount))
			{
				if (client > 0)
				{
					if (IsClientInGame(client) && IsPlayerAlive(client))
					{
							health[client] = GetClientHealth(client);
							PrintToChat(client, "[SM] Okay one heal comin' up!");
							if (health[client] < GetConVarInt(cvarhealthmaximum))
							{							
								new tempH = health[client] + GetConVarInt(cvarhealthtogive);
								g_Used[client]++;
								PrintToChat(client, "Here you go!");
								SetEntityHealth(client,tempH);
							}
						}
					}
				}
			}
		}
	}

