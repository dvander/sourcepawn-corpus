#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.0"

new Handle:g_hCvarType;

public Plugin:myinfo =
{
	name		= "Infinite Ammo",
	author		= "FrozDark",
	description	= "",
	version		= PLUGIN_VERSION,
	url			= "www.hlmod.ru"
}

public OnPluginStart()
{
	g_hCvarType = CreateConVar("sm_infinite_ammo_type", "3", "How to work? 0 disable. 1 only restock ammo on reload. 2 only refill clip on kill. 3 both", 0, true, 0.0, true, 3.0);
	
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("weapon_reload", OnWeaponReload);
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	switch (GetConVarInt(g_hCvarType))
	{
		case 2, 3 :
		{
			new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
			if (!attacker || !IsClientInGame(attacker))
			{
				return;
			}
			
			new weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			if (weapon != -1 && IsValidEdict(weapon))
			{
				new clip = 0;
				if (GetMaxClip1(weapon, clip))
				{
					SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
				}
			}
		}
	}
}

public OnWeaponReload(Handle:event, const String:name[], bool:dontBroadcast)
{
	switch (GetConVarInt(g_hCvarType))
	{
		case 1, 3 :
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			if (!client || !IsClientInGame(client))
			{
				return;
			}
			
			new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (weapon != -1 && IsValidEdict(weapon))
			{
				GivePlayerAmmo(client, 9999, GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType"), true);
			}
		}
	}
}

// Credits to Bacardi for representing below
public OnEntityCreated(entity, const String:clsname[]) 
{ 
    if (StrContains(clsname, "weapon_", false) != -1) SDKHookEx(entity, SDKHook_SpawnPost, SpawnPost); 
} 

public SpawnPost(entity) 
{ 
    GetMaxClip1(entity, _, true); // store m_iClip1 value 
} 

bool:GetMaxClip1(entity, &clip = -1, bool:store = false) 
{ 
    clip = -1; 

    static Handle:trie_ammo = INVALID_HANDLE; 

    if(trie_ammo == INVALID_HANDLE) trie_ammo = CreateTrie(); 

    if(entity <= MaxClients || !IsValidEntity(entity) || !HasEntProp(entity, Prop_Send, "m_iClip1")) return false; 

    decl String:clsname[30]; 
    if(!GetEntityClassname(entity, clsname, sizeof(clsname))) return false; 

    if(store) 
    { 
        SetTrieValue(trie_ammo, clsname, GetEntProp(entity, Prop_Send, "m_iClip1")); 
        return true; 
    } 

    if(!GetTrieValue(trie_ammo, clsname, clip)) return false; 

    return true; 
}  