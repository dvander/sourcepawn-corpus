#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION	 "1.3"

new blockCommand;
new g_Collision;
new Handle:cvar_adverts = INVALID_HANDLE;
new bool:g_IsGhost[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Redie 4 SourceMod",
	author = "MeoW",
	description = "Return as a ghost after you died.",
	version = PLUGIN_VERSION,
	url = "http://www.trident-gaming.net/"
};

public OnPluginStart()
{
	HookEvent("round_end", Event_Round_End, EventHookMode_Pre);
	HookEvent("round_start", Event_Round_Start, EventHookMode_Pre);	
	HookEvent("player_spawn", Event_Player_Spawn);
	HookEvent("player_death", Event_Player_Death);
	RegConsoleCmd("sm_redie", Command_Redie);
	CreateTimer(120.0, advert, _,TIMER_REPEAT);
	CreateConVar("sm_redie_version", PLUGIN_VERSION, "Redie Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvar_adverts = CreateConVar("sm_redie_adverts", "1", "If enabled, redie will produce an advert every 2 minutes.");
	g_Collision = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public OnClientPostAdminCheck(client)
{
	g_IsGhost[client] = false;
}

public Action:Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast) 
{
	blockCommand = false;
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast) 
{
	blockCommand = true;
}


public Action:Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_IsGhost[client])
	{
		SetEntProp(client, Prop_Send, "m_nHitboxSet", 2);
		g_IsGhost[client] = false;
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_nHitboxSet", 0);
	}
}

public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	PrintToChat(client, "\x01[\x03Redie\x01] \x04Type !redie into chat to respawn as a ghost.");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(GetEntProp(client, Prop_Send, "m_lifeState") == 1)
	{
		buttons &= ~IN_USE;
	}
	return Plugin_Continue;
}

public Action:Command_Redie(client, args)
{
	if(blockCommand)
	{
		if (!IsPlayerAlive(client))
		{
			if(GetClientTeam(client) > 1)
			{
				g_IsGhost[client] = true;
				CS_RespawnPlayer(client);
				new weaponIndex;
				for (new i = 0; i <= 3; i++)
				{
					if ((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1)
					{  
						RemovePlayerItem(client, weaponIndex);
						RemoveEdict(weaponIndex);
					}
				}
				SetEntProp(client, Prop_Send, "m_lifeState", 1);
				SetEntData(client, g_Collision, 2, 4, true);
				PrintToChat(client, "\x01[\x03Redie\x01] \x04You are now a ghost.");
			}
			else
			{
				PrintToChat(client, "\x01[\x03Redie\x01] \x04You must be on a team.");
			}
		}
		else
		{
			PrintToChat(client, "\x01[\x03Redie\x01] \x04You must be dead to use redie.");
		}
	}
	else
	{
		PrintToChat(client, "\x01[\x03Redie\x01] \x04Please wait for the new round to begin.");
	}
	return Plugin_Handled;
}

public Action:OnWeaponCanUse(client, weapon)
{
	if(GetEntProp(client, Prop_Send, "m_lifeState") == 1)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action:advert(Handle:timer)
{
	if(GetConVarInt(cvar_adverts))
	{
		PrintToChatAll ("\x01[\x03Redie\x01] \x04This server is running !redie.");
	}
	return Plugin_Continue;
}