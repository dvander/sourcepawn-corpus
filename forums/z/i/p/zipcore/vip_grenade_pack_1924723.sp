/*
 * ============================================================================
 *
 *  Grenade Pack
 *
 *  File:          grenadepack.sp
 *  Type:          Base
 *  Description:   Allows players to carry more than 1 HE grenade.
 *
 *  Copyright (C) 2009-2010  Greyscale
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

// Comment out to not require semicolons at the end of each line of code.
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <vip>

#define PLUGIN_VERSION "1.5"

#define MODE_CLASSIC 0
#define MODE_DEATHMATCH 1

#define VIP_GOLD Vip_Custom4
#define VIP_PLATIN Vip_Custom3

/**
 * Record plugin info.
 */
public Plugin:myinfo =
{
	name = "VIP: Grenade Pack",
	author = "Greyscale",
	description = "Allows players to carry more than 1 HE grenade.",
	version = PLUGIN_VERSION,
	url = ""
};


/**
 * Cvar handles.
 */
new Handle:g_cvarNadeLimitGold;
new Handle:g_cvarNadeLimitPlatin;
new Handle:g_cvarAnnounce;
new Handle:g_cvarMode;

#define HEGRENADE_COST 300

/**
 * Array to track how many times a client has spawned so the plugin isn't announced every spawn.
 */
new g_iSpawnCount[MAXPLAYERS+1];

/**
 * Offsets.
 */
new g_offsAccount;
new g_offsInBuyZone;

/**
 * Plugin has started.
 */
public OnPluginStart()
{
	LoadTranslations("grenadepack.phrases");
	
	// ======================================================================
	
	HookEvent("player_spawn", PlayerSpawn);
	
	// ======================================================================
	
	g_offsAccount = FindSendPropInfo("CCSPlayer", "m_iAccount");
	if (g_offsAccount == -1)
		SetFailState("Couldn't find offset \"m_iAccount\"!");
	
	g_offsInBuyZone = FindSendPropInfo("CCSPlayer", "m_bInBuyZone");
	if (g_offsInBuyZone == -1)
		SetFailState("Couldn't find offset \"m_bInBuyZone\"!");
	
	// ======================================================================
	
	AddCommandListener(Listener_Buy, "buy");
	
	// ======================================================================
	
	g_cvarNadeLimitGold = CreateConVar("gp_limit_gold", "2", "Max amount of grenades a gold player can carry ['0' = Unlimited]");
	g_cvarNadeLimitPlatin= CreateConVar("gp_limit_platin", "3", "Max amount of grenades a platin player can carry ['0' = Unlimited]");
	g_cvarAnnounce = CreateConVar("gp_announce", "3", "Every x rounds the player is reminded of the plugin ['0' = Disable]");
	g_cvarMode = CreateConVar("gp_mode", "1", "Enable Deathmatch mode ['0' = Disable]");
	
	CreateConVar("gs_grenadepack_version", PLUGIN_VERSION, "[Grenade Pack] Current version of this plugin", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_UNLOGGED | FCVAR_DONTRECORD | FCVAR_REPLICATED | FCVAR_NOTIFY);
	
	// Autocreate and execute cfg if it doesn't exist.
	AutoExecConfig(true, "grenadepack");
	
	// Hook this cvar to announce to the server if it changes.
	HookConVarChange(g_cvarNadeLimitGold, CvarHook);
	HookConVarChange(g_cvarNadeLimitPlatin, CvarHook);
	HookConVarChange(g_cvarMode, CvarHook);
}

/**
 * Cvar change callback for gp_limit.
 * Announce to the server that the cvar has changed.
 * 
 * @param convar	The handle of the cvar being changed.
 * @param oldValue  The value before it was changed.
 * @param newValue  The value after it was changed.
 * 
 */
public CvarHook(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_cvarNadeLimitGold)
	{
		if (StrEqual(newValue, "0"))
			PrintToChatAll("[Grenade Pack] %t", "Limit changed unlimited");
		
		else
			PrintToChatAll("[Grenade Pack] %t", "Limit changed", StringToInt(newValue));
	}
	if (convar == g_cvarNadeLimitPlatin)
	{
		if (StrEqual(newValue, "0"))
			PrintToChatAll("[Grenade Pack] %t", "Limit changed unlimited");
		
		else
			PrintToChatAll("[Grenade Pack] %t", "Limit changed", StringToInt(newValue));
	}
}

/**
 * Client has connected to the server. (not in game yet)
 * 
 * @param client	The client connecting.
 * @param rejectmsg The message to send client if rejecting them.
 * @param maxlen	The max length of the reject message.
 */
public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	// Reset the client's spawn count.
	g_iSpawnCount[client] = -1;
	
	return true;
}

/**
 * Client has joined the server.
 * 
 * @param client	The client index.
 */
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_Touch, Hook_Touch);
}

/**
 * Client is disconnecting from the server.
 * 
 * @param client	The client index.
 */
public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_Touch, Hook_Touch);
}

/**
 * Client has spawned.
 * 
 * @param event		 The event handle.
 * @param name		  The name of the event.
 * @param dontBroadcast Don't tell clients the event has fired.
 */
public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new index = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new limitgold = GetConVarInt(g_cvarNadeLimitGold);
	new limitplatin = GetConVarInt(g_cvarNadeLimitPlatin);
	
	new bool:gold = GetVipFlag(index, VIP_GOLD);
	new bool:platin = GetVipFlag(index, VIP_PLATIN);
	
	new announce = GetConVarInt(g_cvarAnnounce);
	if (announce > 0)
	{
		if (g_iSpawnCount[index] == 0 || g_iSpawnCount[index] == announce)
		{
			g_iSpawnCount[index] = 0;
			
			if(platin)
			{
				if (limitplatin > 1)
					PrintToChat(index, "[%t] %t", "Grenade Pack", "Announcement", limitplatin);
				
				else
					PrintToChat(index, "[%t] %t", "Grenade Pack", "Announcement unlimited");
			}
			
			else if(gold)
			{
				if (limitgold > 1)
					PrintToChat(index, "[%t] %t", "Grenade Pack", "Announcement", limitgold);
				
				else
					PrintToChat(index, "[%t] %t", "Grenade Pack", "Announcement unlimited");
			}
		}
	}
	
	new mode = GetConVarInt(g_cvarMode);
	if(mode == MODE_DEATHMATCH)
	{
		if(platin)
		{
			for(new i=GetClientGrenades(index);i<limitplatin;++i)
				GiveClientGrenade(index);
		}
		else if(gold)
		{
			for(new i=GetClientGrenades(index);i<limitgold;++i)
				GiveClientGrenade(index);
		}
	}
	
	// Increment spawn count.
	g_iSpawnCount[index]++;
}

/**
 * Callback for command listeners. This is invoked whenever any command
 * reaches the server, from the server console itself or a player.

 * Returning Plugin_Handled or Plugin_Stop will prevent the original,
 * baseline code from running.
 * 
 * @param client		Client, or 0 for server. Client will be connected but
 *					  not necessarily in game.
 * @param command	   Command name, lower case. To get name as typed, use
 *					  GetCmdArg() and specify argument 0.
 * @param argc		  Argument count.
 * @return				Action to take (see extended notes above).
 */
public Action:Listener_Buy(client, const String:command[], argc)
{
	if (!IsClientInGame(client))
		return Plugin_Continue;
	
	new limitgold = GetConVarInt(g_cvarNadeLimitGold);
	new limitplatin = GetConVarInt(g_cvarNadeLimitPlatin);
	
	new bool:gold = GetVipFlag(client, VIP_GOLD);
	new bool:platin = GetVipFlag(client, VIP_PLATIN);
	
	new limit;
	
	if(platin)
	{
		limit = limitplatin;
	}
	else if(gold)
	{
		limit = limitgold;
	}
	
	// If the client is not VIP
	if (!gold && !platin)
		return Plugin_Continue;
	
	decl String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	// If client isn't buying a grenade, then ignore.
	if (!StrEqual(arg1, "hegrenade", false))
		return Plugin_Continue;
	
	// If client isn't in a buyzone, then ignore.
	if (!GetEntData(client, g_offsInBuyZone, 1))
		return Plugin_Continue;
	
	// If client doesn't have enough money, then ignore.
	new money = GetEntData(client, g_offsAccount);
	if (money < HEGRENADE_COST)
		return Plugin_Continue;
	
	// If the client has no grenades then allow the game to buy the grenade for the client.
	if (GetClientGrenades(client) == 0)
		return Plugin_Continue;
	
	// Check if the client is under the grenade limit, or if there is no limit.
	new count = GetClientGrenades(client);
	
	if (count < limit || limit <= 0)
	{
		SetEntData(client, g_offsAccount, money - HEGRENADE_COST);
		
		new entity = GivePlayerItem(client, "weapon_hegrenade");
		PickupGrenade(client, entity);
	
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/**
 * Touch callback.
 * Called when client touches an entity.  If the entity is a grenade check if they should pick it up.
 * 
 * @param client	The client index.
 * @param entity	The entity index being touched by the client.
 */
public Hook_Touch(client, entity)
{
	if (!IsValidEntity(entity))
		return;
	
	decl String:classname[32];
	GetEdictClassname(entity, classname, sizeof(classname));
	
	if (StrEqual(classname, "weapon_hegrenade", false))
	{
		new limitgold = GetConVarInt(g_cvarNadeLimitGold);
		new limitplatin = GetConVarInt(g_cvarNadeLimitGold);
		
		new bool:gold = GetVipFlag(client, VIP_GOLD);
		new bool:platin = GetVipFlag(client, VIP_PLATIN);
		
		if (!gold && !platin)
			return;
		
		new limit;
		
		if(platin)
		{
			limit = limitplatin;
		}
		else if(gold)
		{
			limit = limitgold;
		}
		
		new count = GetClientGrenades(client);
		if (count < limit || limit <= 0)
			PickupGrenade(client, entity);
	}
}

PickupGrenade(client, entity)
{
	new Handle:event = CreateEvent("item_pickup");
	if (event != INVALID_HANDLE)
	{
		SetEventInt(event, "userid", GetClientUserId(client));
		SetEventString(event, "item", "hegrenade");
		FireEvent(event);
	}
	
	new Float:loc[3] = {0.0,0.0,0.0};
	TeleportEntity(entity, loc, NULL_VECTOR, NULL_VECTOR);
	
	CreateTimer(0.1, RemoveGrenade, entity);
	
	GiveClientGrenade(client);
	
	EmitSoundToClient(client, "items/itempickup.wav");
}

public Action:RemoveGrenade(Handle:timer, any:grenade)
{
	if (IsValidEdict(grenade))
		RemoveEdict(grenade);
}

GetClientGrenades(client)
{
	new offsNades = FindDataMapOffs(client, "m_iAmmo") + (11 * 4);
	
	return GetEntData(client, offsNades);
}

GiveClientGrenade(client)
{
	new offsNades = FindDataMapOffs(client, "m_iAmmo") + (11 * 4);
	
	new count = GetEntData(client, offsNades);
	SetEntData(client, offsNades, ++count);
}