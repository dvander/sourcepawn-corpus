#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required
#pragma semicolon 1

#define VERSION	"1.1"

#define TEAM_SURVIVOR	2

public Plugin myinfo = 
{
	name = "L4D1 Ammo refill fix",
	author = "Axel Juan Nieves",
	description = "Fixes refilling on grabbing ammunation.",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2728258"
}

public void OnPluginStart()
{
	CreateConVar("l4d1_ammo_refill_fix_version", VERSION, "L4D1 Ammo refill fix version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public void OnEntityCreated(int ent, const char[] classname)
{
	if ( StrEqual("weapon_ammo_spawn", classname, false) )
		SDKHook(ent, SDKHook_Use, OnEntityUse);
}

public Action OnEntityUse(int ent, int client)
{
	if ( !IsValidClientInGame(client) )
		return Plugin_Continue;

	if ( !IsPlayerAlive(client) )
		return Plugin_Continue;

	if ( GetClientTeam(client)!=TEAM_SURVIVOR )
		return Plugin_Continue;

	if ( !IsValidEntity(ent) )
		return Plugin_Continue;
	
	fixAmmo(client);
			
	return Plugin_Continue;
}

stock void fixAmmo(int client)
{
	
	if ( !IsValidClientInGame(client) )
		return;
	
	int weapon = GetPlayerWeaponSlot(client, 0);
	if ( !IsValidEntity(weapon) )
		return;
	
	int oldAmmo = GetEntProp(weapon, Prop_Send, "m_iClip1", 1);
	char strWeaponName[64];
	GetEdictClassname(weapon, strWeaponName, sizeof(strWeaponName));

	int newWeapon = CreateEntityByName(strWeaponName);
	if ( !IsValidEntity(newWeapon) )
		return;
	DispatchSpawn(newWeapon);
	
	int maxClipSize = GetEntProp(newWeapon, Prop_Send, "m_iClip1", 1);
	int ammoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
	int reserveAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType"));
	
	int maxReserve;
	switch ( ammoType )
	{
		case 6: maxReserve = GetConVarInt(FindConVar("ammo_buckshot_max"));
		case 5: maxReserve = GetConVarInt(FindConVar("ammo_smg_max"));
		case 3: maxReserve = GetConVarInt(FindConVar("ammo_assaultrifle_max"));
		case 2: maxReserve = GetConVarInt(FindConVar("ammo_huntingrifle_max"));
	}
	
	int wantedAmmo = maxReserve+maxClipSize-oldAmmo;
	if ( wantedAmmo+oldAmmo > reserveAmmo+oldAmmo )
	{
		//PrintToChatAll("refill");
		//set reserve ammo...
		SetEntProp(client, Prop_Send, "m_iAmmo", wantedAmmo, 4, ammoType);
		Handle event = CreateEvent("ammo_pickup");
		SetEventInt(event, "userid", GetClientUserId(client));
		FireEvent(event);
		float fPos[3];
		GetClientAbsOrigin(client, fPos);
		EmitAmbientSound("items/itempickup.wav", fPos, client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
		
		/*
		//compatibility with limited ammo piles(?) never tested
		int entity = GetClientAimTarget(client, false);
		if ( IsValidEntity(entity) )
		{
			char classname[64];
			GetEdictClassname(entity, classname, sizeof(classname));
			if ( StrEqual(classname, "weapon_ammo_spawn") )
			{
				event = CreateEvent("player_use");
				SetEventInt(event, "userid", GetClientUserId(client));
				SetEventInt(event, "targetid", entity);
				FireEvent(event);
			}
		}*/
	}
	
	AcceptEntityInput(newWeapon, "Kill");
	
	//PrintToChatAll("Weapon: %s. OldAmmo:%i Reserve:%i newClip: %i AmmoType: %i", strWeaponName, oldAmmo, reserveAmmo, maxClipSize, ammoType);
}

stock int IsValidClientInGame(int client)
{
	if (IsValidClientIndex(client))
	{
		if (IsClientInGame(client))
			return 1;
	}
	return 0;
}

stock int IsValidClientIndex(int index)
{
	if (index>0 && index<=MaxClients)
	{
		return 1;
	}
	return 0;
}