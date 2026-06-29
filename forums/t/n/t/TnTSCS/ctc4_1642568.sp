//* This plugins is a remake of an Eventscripts plugin //*
//* called CTrun (http://addons.eventscripts.com/addons/view/CTRun) //*
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "CT-C4",
	author = "rodipm",
	description = "Allows CTs to pickup the c4 and plant it.",
	version = "1.1a",
	url = "sourcemod.net"
}

new Handle:g_canplant = INVALID_HANDLE;
new bool:wait;
new bool:holding[MAXPLAYERS+1];

new the_bomb = INVALID_ENT_REFERENCE;

public OnPluginStart()
{
	g_canplant = CreateConVar("ctc4_canplant", "0", "Defines if CTs can plant the bomb. Default = 0");
	
	HookEvent("bomb_dropped", Dropped);
	HookEvent("bomb_pickup", Pickup);
	HookEvent("bomb_planted", Planted);
	HookEvent("bomb_beginplant", Planting);
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_Touch, Touch);
}

public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		SDKUnhook(client, SDKHook_Touch, Touch);
		
		holding[client] = false;
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	// Get the entity index of the bomb
	if(StrEqual(classname, "weapon_c4"))
	{
		the_bomb = entity;
	}
	
	// If the bomb is planted, set the bomb entity index to -1
	if(StrEqual(classname, "planted_c4"))
	{
		the_bomb = INVALID_ENT_REFERENCE;
	}
}

public Action:Touch(client, entity)
{
	if(!wait && client > 0 && client <= MaxClients && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT && 
		!holding[client] && the_bomb != INVALID_ENT_REFERENCE && entity == the_bomb)
	{
		RemoveEdict(entity);
		
		SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_T);
		GivePlayerItem(client, "weapon_c4");
		SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_CT);
		
		holding[client] = true;
	}
}

public Dropped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		wait = true;
		CreateTimer(0.5, WaitCheck);
		holding[client] = false;
	}
}

public Pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
		holding[client] = true;
	}
}

public Planted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
		holding[client] = false;
	}
}


public Planting(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetClientTeam(client) == CS_TEAM_CT && !GetConVarBool(g_canplant))
	{
		PrintToChatAll("\x04[CT-C4 \x01By.:RpM\x04]\x03 You can't plant the bomb!");
		new c4ent = GetPlayerWeaponSlot(client, CS_SLOT_C4);
		
		RemovePlayerItem(client, c4ent);
		
		SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_T);
		GivePlayerItem(client, "weapon_c4");
		SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_CT);
		
		holding[client] = true;
	}
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_canplant))
	{
		PrintToChatAll("\x04[CT-C4 \x01By.:RpM\x04]\x03 CTs can now pickup the bomb");
	}
	else
	{
		PrintToChatAll("\x04[CT-C4 \x01By.:RpM\x04]\x03 CTs can now pickup the bomb and plant it!");
	}
}

public RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && holding[i])
		{
			holding[i] = false;
		}
	}
}

public Action:WaitCheck(Handle:timer)
{
	wait = false;
}