#pragma semicolon 1

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

#define PLUGIN_VERSION	"0.1"

public Plugin:myinfo =
{
	name = "Scout knives",
	author = "Blake",
	description = "Removes all weapons and gives a scout and knife",
	version = PLUGIN_VERSION,
	url = ""
}

new bool:g_Enabled = false;
new Handle:g_hEnabled = INVALID_HANDLE;
	
public OnPluginStart()
{
	CreateConVar("sv_scoutknives_version", PLUGIN_VERSION, "Plugin scoutknives version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sv_scoutknives_enabled", "0", "Enable/Disable Scoutknives", FCVAR_PLUGIN, true, 0.0, false, 1.0);
	HookConVarChange(g_hEnabled, OnConVarChanged);
	
	HookEvent("player_spawn", OnSpawn);
	for (new client = 1; client <= MaxClients; client++) 
	{ 
        if (Client_IsIngameAuthorized(client))
		{
			SDKHook(client, SDKHook_PostThink, OnPostThink);
			SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
		}
    }
}

public OnPluginEnd()
{
	for (new client = 1; client <= MaxClients; client++) 
	{ 
        if (Client_IsIngameAuthorized(client))
		{
			SDKUnhook(client, SDKHook_PostThink, OnPostThink);
			SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponEquip);
		}
    }
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar==g_hEnabled)
	{
		g_Enabled = bool:StringToInt(newValue);
		serverSetup(g_Enabled);
	}
}

public OnMapStart()
{
	for (new client = 1; client <= MaxClients; client++) 
	{ 
        if (Client_IsIngameAuthorized(client))
		{
			SDKHook(client, SDKHook_PostThink, OnPostThink);
			SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
		}
    }
}

public OnClientPutInServer(client)
{
	if (Client_IsIngameAuthorized(client))
	{
		SDKHook(client, SDKHook_PostThink, OnPostThink);
		SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	}
}

public OnClientDisconnect(client)
{
	if (Client_IsIngameAuthorized(client))
	{
		SDKUnhook(client, SDKHook_PostThink, OnPostThink);
		SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	}
}

public OnPostThink(client)
{
	if(IsPlayerAlive(client) && g_Enabled)
	{
		SetEntProp(client, Prop_Send, "m_bInBuyZone", 0);
	}
}

public Action:OnWeaponEquip(client, weapon)
{
	if(g_Enabled)
	{
		new String:weaponName[256];
		Entity_GetClassName(weapon, weaponName, sizeof(weaponName));
		if(!StrEqual(weaponName, "weapon_knife", false) && !StrEqual(weaponName, "weapon_scout", false))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:OnSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_Enabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!Client_HasWeapon(client, "weapon_scout"))
		{
			Client_GiveWeaponAndAmmo(client, "weapon_scout", true, 90, 0, 10, 0);
		}
	}
}

serverSetup(bool:enabled)
{
	new Handle:gravity = FindConVar("sv_gravity");
	new Handle:airaccelerate = FindConVar("sv_airaccelerate");
	new Handle:bunnyhop = FindConVar("sv_enablebunnyhopping");
	SetConVarInt(gravity, enabled ? 200 : 800, true);
	SetConVarInt(airaccelerate, enabled ? 100 : 10, true);
	SetConVarInt(bunnyhop, enabled ? 1 : 0, true);
}