/*
L4D1 Proper Reserve Ammo
Copyright (C)2015  Buster "Mr. Zero" Nielsen

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

As a special exception, AlliedModders LLC gives you permission to link the
code of this program (as well as its derivative works) to "Half-Life 2," the
"Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
by the Valve Corporation.  You must obey the GNU General Public License in
all respects for all other code used.  Additionally, AlliedModders LLC grants
this exception to all derivative works.  AlliedModders LLC defines further
exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
or <http://www.sourcemod.net/license.php>. 
*/

/* Includes */
#include <sourcemod>
#include <sdktools>
//#include <l4d_stocks>
#include <sdkhooks>
#tryinclude <left4dhooks> // Download here: https://forums.alliedmods.net/showthread.php?t=321696

/* Plugin Information */
public Plugin:myinfo =
{
	name		= "L4D1 Proper Reserve Ammo",
	author		= "Buster \"Mr. Zero\" Nielsen",
	description	= "Fixes reserve ammo count, when picking up ammo, to give full reserve ammo plus weapon magazine size",
	version		= "1.0.0",
	url		= "mrzerodk@gmail.com"
}

/* Globals */
#define DEBUG 0
#define DEBUG_TAG "ProperReserveAmmo"
#define DEBUG_PRINT_FORMAT "[%s] %s"

#define ERROR_INVALID_AMMO_OFFSET "Invalid m_iAmmo offset. Client %L, weapon \"%s\"<%d>"

#define MAXENTITIES 2048
#define MAXEDICTS 4096

new bool:g_IsBeforeMapStart = true
new bool:g_IsInMapTransition = false

#define KILL_SPAWNED_WEAPON_TIME 0.1
new Handle:g_WeaponClipTrie
new Handle:g_WeaponAmmoTrie

new bool:g_IsInGame[MAXPLAYERS + 1]
#define AIM_TARGET_INTERVAL 0.3
#define AMMOSPAWN_CLASSNAME "weapon_ammo_spawn"
new Float:g_AimTargetTimestamp[MAXPLAYERS + 1]

#define USE_RANGE 88 // Guess-itmate. 90 is too high, 85 is too little. 88 seems just about right.

#define CVAR_AMMO_ASSULTRIFLE_MAX_NAME "ammo_assaultrifle_max"
#define CVAR_AMMO_SHOTGUN_MAX_NAME "ammo_buckshot_max"
#define CVAR_AMMO_HUNTINGRIFLE_MAX_NAME "ammo_huntingrifle_max"
#define CVAR_AMMO_SMG_MAX_NAME "ammo_smg_max"

#define CLASSNAME_WEAPON_PUMPSHOTGUN "weapon_pumpshotgun"
#define CLASSNAME_WEAPON_SMG "weapon_smg"
#define CLASSNAME_WEAPON_RIFLE "weapon_rifle"
#define CLASSNAME_WEAPON_HUNTING_RIFLE "weapon_hunting_rifle"
#define CLASSNAME_WEAPON_AUTOSHOTGUN "weapon_autoshotgun"

new g_CachedAmmo_Shotgun
new g_CachedAmmo_SMG
new g_CachedAmmo_Rifle
new g_CachedAmmo_HuntingRifle

/* Plugin Functions */
public OnPluginStart()
{
	g_WeaponClipTrie = CreateTrie()
	g_WeaponAmmoTrie = CreateTrie()
	
	new Handle:convar
	convar = FindConVar(CVAR_AMMO_ASSULTRIFLE_MAX_NAME)
	HookConVarChange(convar, Ammo_Rifle_ConVarChanged)
	g_CachedAmmo_Rifle = GetConVarInt(convar)
	
	convar = FindConVar(CVAR_AMMO_SHOTGUN_MAX_NAME)
	HookConVarChange(convar, Ammo_Shotgun_ConVarChanged)
	g_CachedAmmo_Shotgun = GetConVarInt(convar)
	
	convar = FindConVar(CVAR_AMMO_HUNTINGRIFLE_MAX_NAME)
	HookConVarChange(convar, Ammo_HuntingRifle_ConVarChanged)
	g_CachedAmmo_HuntingRifle = GetConVarInt(convar)
	
	convar = FindConVar(CVAR_AMMO_SMG_MAX_NAME)
	HookConVarChange(convar, Ammo_SMG_ConVarChanged)
	g_CachedAmmo_SMG = GetConVarInt(convar)
	
	HookEvent("ammo_pickup", AmmoPickup_Event)
	HookEvent("map_transition", MapTransition_Event)
}

public OnAllPluginsLoaded()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		g_IsInGame[client] = IsClientInGame(client) && IsClientAuthorized(client)
	}
}

public Ammo_Rifle_ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_CachedAmmo_Rifle = GetConVarInt(convar)
}

public Ammo_Shotgun_ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_CachedAmmo_Shotgun = GetConVarInt(convar)
}

public Ammo_HuntingRifle_ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_CachedAmmo_HuntingRifle = GetConVarInt(convar)
}

public Ammo_SMG_ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_CachedAmmo_SMG = GetConVarInt(convar)
}

public OnMapStart()
{
	g_IsInMapTransition = false
	g_IsBeforeMapStart = false
}

public OnMapEnd()
{
	g_IsBeforeMapStart = true
}

public OnClientPostAdminCheck(client)
{
	g_IsInGame[client] = true
}

public OnClientDisconnect(client)
{
	g_IsInGame[client] = false
}

public MapTransition_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_IsInMapTransition = true
}

public AmmoPickup_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || L4DTeam:GetClientTeam(client) != L4DTeam_Survivor)
	{
		return
	}
	
#if DEBUG
	Debug_PrintText("Ammo Pickup, client %N<%d>", client, client)
#endif
	
	FixClientReserveAmmo(client)
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if (!g_IsInGame[client] || !(buttons & IN_USE))
	{
		return Plugin_Continue
	}
	
#if AIM_TARGET_INTERVAL
	new Float:time = GetEngineTime()
	if (time - g_AimTargetTimestamp[client] < AIM_TARGET_INTERVAL)
	{
		return Plugin_Continue
	}
	
	g_AimTargetTimestamp[client] = time
#endif
	
	new ammospawn = GetClientAimTarget(client, false)
	if (ammospawn <= 0 || ammospawn > MAXENTITIES || !IsValidEntity(ammospawn))
	{
		return Plugin_Continue
	}
	
	decl String:classname[32]
	GetEntityClassname(ammospawn, classname, sizeof(classname))
	
	if (!StrEqual(classname, AMMOSPAWN_CLASSNAME))
	{
		return Plugin_Continue
	}
	
	new Float:origin[3]
	new Float:clientOrigin[3]
	GetEntityAbsOrigin(ammospawn, origin)
	GetClientAbsOrigin(client, clientOrigin)
	
	if (GetVectorDistance(clientOrigin, origin) > USE_RANGE)
	{
		return Plugin_Continue
	}
	
#if DEBUG
	Debug_PrintText("Client %N<%d> using weapon_ammo_spawn", client, client)
#endif
	
	FixClientReserveAmmo(client)
	
	return Plugin_Continue
}

stock FixClientReserveAmmo(client)
{
	new weapon = GetPlayerWeaponSlot(client, _:L4DWeaponSlot_Primary)
	if (weapon <= 0 || !IsValidEntity(weapon))
	{
		return
	}
	
	new String:weaponName[128]
	GetEntityClassname(weapon, weaponName, sizeof(weaponName))
	
	new offset = FindDataMapInfo(client, "m_iAmmo") + (GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType") * 4)
	if (offset <= 0)
	{
		LogError(ERROR_INVALID_AMMO_OFFSET, client, weaponName, weapon)
		return
	}
	
	new oldAmmo = GetEntData(client, offset)
	new ammo = GetWeaponMaxAmmo(weaponName)
	new clip = GetEntProp(weapon, Prop_Data, "m_iClip1")
	new clipSize = GetWeaponMaxClipSize(weaponName)
	
	if (ammo < 0 || clipSize < 0)
	{
		return
	}
	
	new fixedAmmo = ammo + (clipSize - clip)
	
	if (fixedAmmo == oldAmmo)
	{
		return
	}
	
#if DEBUG
	Debug_PrintText("Fixed Client %N<%d> Ammo: %d", client, client, fixedAmmo)
#endif
	SetEntData(client, offset, fixedAmmo, _, true)
	
	new Handle:event = CreateEvent("ammo_pickup")
	SetEventInt(event, "userid", GetClientUserId(client))
	FireEvent(event)
}

stock GetWeaponMaxAmmo(const String:weaponName[])
{
	new ammo = -1
	GetWeaponAmmoInfo(weaponName, ammo, _)
	return ammo
}

stock GetWeaponMaxClipSize(const String:weaponName[])
{
	new clip = -1
	GetWeaponAmmoInfo(weaponName, _, clip)
	return clip
}

stock bool:GetWeaponAmmoInfo(const String:weaponName[], &ammo = -1, &clip = -1)
{
#if DEBUG
	Debug_PrintText("GetWeaponAmmoInfo(weaponName \"%s\")", weaponName)
#endif
	new cachedClip = -1
	new cachedAmmo = -1
	if (GetTrieValue(g_WeaponAmmoTrie, weaponName, cachedAmmo) && GetTrieValue(g_WeaponClipTrie, weaponName, cachedClip))
	{
#if DEBUG
		Debug_PrintText(" - Ammo %d (cached)", cachedAmmo)
		Debug_PrintText(" - Clip %d (cached)", cachedClip)
#endif
		ammo = cachedAmmo
		clip = cachedClip
		return true
	}
	
	if (g_IsBeforeMapStart || g_IsInMapTransition)
	{
#if DEBUG
		Debug_PrintText("Before map start or in transition! Ending.")
#endif
		return false
	}
	
	new weapon = CreateEntityByName(weaponName)
	if (weapon <= 0 || !IsValidEntity(weapon))
	{
#if DEBUG
		Debug_PrintText("Failed to create weapon! Ending.")
#endif
		return false
	}
	
	DispatchSpawn(weapon)
	cachedClip = GetEntProp(weapon, Prop_Data, "m_iClip1")
	
	if (StrEqual(weaponName, CLASSNAME_WEAPON_PUMPSHOTGUN) || StrEqual(weaponName, CLASSNAME_WEAPON_AUTOSHOTGUN))
	{
		cachedAmmo = g_CachedAmmo_Shotgun
	}
	else if (StrEqual(weaponName, CLASSNAME_WEAPON_SMG))
	{
		cachedAmmo = g_CachedAmmo_SMG
	}
	else if (StrEqual(weaponName, CLASSNAME_WEAPON_RIFLE))
	{
		cachedAmmo = g_CachedAmmo_Rifle
	}
	else if (StrEqual(weaponName, CLASSNAME_WEAPON_HUNTING_RIFLE))
	{
		cachedAmmo = g_CachedAmmo_HuntingRifle
	}
	
	SetTrieValue(g_WeaponAmmoTrie, weaponName, cachedAmmo)
	SetTrieValue(g_WeaponClipTrie, weaponName, cachedClip)
	
	ammo = cachedAmmo
	clip = cachedClip
	
#if DEBUG
	Debug_PrintText(" - Ammo %d", cachedAmmo)
	Debug_PrintText(" - Clip %d", cachedClip)
#endif
	return true
}

stock bool:GetEntityAbsOrigin(entity, Float:origin[3])
{
	if (entity <= 0 || !IsValidEntity(entity))
	{
		return false
	}
	
	decl Float:mins[3], Float:maxs[3]
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin)
	GetEntPropVector(entity, Prop_Send, "m_vecMins", mins)
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs)
	
	for (new i = 0; i < 3; i++)
	{
		origin[i] += (mins[i] + maxs[i]) * 0.5
	}
	return true
}

#if DEBUG
stock Debug_PrintText(const String:format[], any:...)
{
	decl String:buffer[256]
	VFormat(buffer, sizeof(buffer), format, 2)
	
	LogMessage(buffer)
	
	new AdminId:adminId
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client))
		{
			continue
		}
		
		adminId = GetUserAdmin(client)
		if (adminId == INVALID_ADMIN_ID || !GetAdminFlag(adminId, Admin_Root))
		{
			continue
		}
		
		PrintToChat(client, DEBUG_PRINT_FORMAT, DEBUG_TAG, buffer)
	}
}
#endif