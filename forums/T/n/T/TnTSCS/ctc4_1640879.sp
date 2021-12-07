//* This plugins is a remake of an Eventscripts plugin //*
//* called CTrun (http://addons.eventscripts.com/addons/view/CTRun) //*

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "CT-C4",
	author = "rodipm",
	description = "Allows CTs to pickup the c4 and plant it.",
	version = "1.1",
	url = "sourcemod.net"
}

new Handle:g_canplant = INVALID_HANDLE;
new bool:wait;
new bool:holding[MAXPLAYERS+1];

public OnPluginStart()
{
	g_canplant = CreateConVar("ctc4_canplant", "0", "Defines if CTs can plant the bomb. Default = 0");
	
	HookEvent("bomb_dropped", Dropped);
	HookEvent("bomb_pickup", Pickup);
	HookEvent("bomb_planted", Planted);
	HookEvent("bomb_beginplant", Planting);
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	
	//for(new i = 1; i <= MaxClients; i++)
	//{
	//	if(IsClientInGame(i) && IsClientConnected(i))
	//		OnClientPutInServer(i);
	//}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_Touch, Touch);
}

public Touch(ent1, ent2)
{
	if(!wait && !holding[ent1])
	{
		if(ent1 > 0 && ent1 <= MaxClients && IsPlayerAlive(ent1) && GetClientTeam(ent1) == CS_TEAM_CT)
		{
			decl String:name[50];
			GetEdictClassname(ent2, name, 50);
			
			if(StrContains(name, "weapon_c4") != -1)
			{
				SetEntProp(ent1, Prop_Send, "m_iTeamNum", 2);
				RemoveEdict(ent2);
				GivePlayerItem(ent1, "weapon_c4");
				SetEntProp(ent1, Prop_Send, "m_iTeamNum", 3);
				holding[ent1] = true;
			}
		}
	}
}

public Dropped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT)
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
		holding[client] = true;
}

public Planted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(client) == CS_TEAM_CT)
		holding[client] = false;
}


public Planting(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(client) == CS_TEAM_CT && !GetConVarBool(g_canplant))
	{
		PrintToChatAll("\x04[CT-C4 \x01By.:RpM\x04]\x03 You can't plant the bomb!");
		new weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		
		RemovePlayerItem(client, weapon);
		
		SetEntProp(client, Prop_Send, "m_iTeamNum", 2);
		GivePlayerItem(client, "weapon_c4");
		SetEntProp(client, Prop_Send, "m_iTeamNum", 3);
		holding[client] = true;
	}
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_canplant))
		PrintToChatAll("\x04[CT-C4 \x01By.:RpM\x04]\x03 CTs can now pickup the bomb");
	else
		PrintToChatAll("\x04[CT-C4 \x01By.:RpM\x04]\x03 CTs can now pickup the bomb and plant it!");
}

public RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
			holding[i] = false;
	}
}

public Action:WaitCheck(Handle:timer)
{
	wait = false;
}