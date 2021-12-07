#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

enum GunSlots
{
	Primary,
	Secondary,
	ExtraPrimary,
	ExtraSecondary
};

new bool:BlockDrop[MAXPLAYERS+1];
new SlotStatus[MAXPLAYERS+1][GunSlots];
new IsEnabled;

new Handle:GunSlotTrie;
new Handle:hIsEnabled;

public Plugin:myinfo =
{
	name = "Extra Guns",
	author = "Blodia",
	description = "Allows players to carry extra guns",
	version = "1.1",
	url = ""
}

public OnPluginStart()
{
	CreateConVar("extraguns_version", PLUGIN_VERSION, "Extra Guns version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	hIsEnabled = CreateConVar("extraguns_enable", "3", "0 disables plugin, 1 allows extra primary only, 2 allows extra secondary only, 3 allows extra primary and secondary", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 3.0);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	HookConVarChange(hIsEnabled, ConVarChange);
	IsEnabled = GetConVarInt(hIsEnabled);
	
	for (new client = 1; client <= MaxClients; client++) 
	{ 
        if (IsClientInGame(client)) 
        {
			SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
			SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
			SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
			
			new PrimaryGun = GetPlayerWeaponSlot(client, 1);
			new SecondaryGun = GetPlayerWeaponSlot(client, 2);
			
			if (PrimaryGun != -1)
			{
				SlotStatus[client][Primary] = PrimaryGun;
			}
			if (SecondaryGun != -1)
			{
				SlotStatus[client][Secondary] = SecondaryGun;
			}
        } 
    }
	
	GunSlotTrie = CreateTrie();
	
	SetTrieValue(GunSlotTrie, "weapon_galil", 1);
	SetTrieValue(GunSlotTrie, "weapon_ak47", 1);
	SetTrieValue(GunSlotTrie, "weapon_scout", 1);
	SetTrieValue(GunSlotTrie, "weapon_sg552", 1);
	SetTrieValue(GunSlotTrie, "weapon_awp", 1);
	SetTrieValue(GunSlotTrie, "weapon_g3sg1", 1);
	SetTrieValue(GunSlotTrie, "weapon_famas", 1);
	SetTrieValue(GunSlotTrie, "weapon_m4a1", 1);
	SetTrieValue(GunSlotTrie, "weapon_aug", 1);
	SetTrieValue(GunSlotTrie, "weapon_sg550", 1);
	SetTrieValue(GunSlotTrie, "weapon_glock", 2);
	SetTrieValue(GunSlotTrie, "weapon_usp", 2);
	SetTrieValue(GunSlotTrie, "weapon_p228", 2);
	SetTrieValue(GunSlotTrie, "weapon_deagle", 2);
	SetTrieValue(GunSlotTrie, "weapon_elite", 2);
	SetTrieValue(GunSlotTrie, "weapon_fiveseven", 2);
	SetTrieValue(GunSlotTrie, "weapon_m3", 1);
	SetTrieValue(GunSlotTrie, "weapon_xm1014", 1);
	SetTrieValue(GunSlotTrie, "weapon_mac10", 1);
	SetTrieValue(GunSlotTrie, "weapon_tmp", 1);
	SetTrieValue(GunSlotTrie, "weapon_mp5navy", 1);
	SetTrieValue(GunSlotTrie, "weapon_ump45", 1);
	SetTrieValue(GunSlotTrie, "weapon_p90", 1);
	SetTrieValue(GunSlotTrie, "weapon_m249", 1);
}

public OnPluginEnd()
{
	CloseHandle(GunSlotTrie);
}

public ConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == hIsEnabled)
	{
		IsEnabled = GetConVarInt(hIsEnabled);
	}	
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new UserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(UserId);
	
	if (GetEntProp(client, Prop_Send, "m_iTeamNum") > 1)
	{
		switch (IsEnabled)
		{
			case 1:
			{
				PrintToChat(client, "\x04[Extra Guns]\x05 You can pick up an extra primary gun.");
				PrintToChat(client, "\x04[Extra Guns]\x05 Use the keyboard and the mouse wheel to switch between primary guns.");
			}
			case 2:
			{
				PrintToChat(client, "\x04[Extra Guns]\x05 You can pick up an extra secondary gun.");
				PrintToChat(client, "\x04[Extra Guns]\x05 Use the keyboard and the mouse wheel to switch between secondary guns.");
			}
			case 3:
			{
				PrintToChat(client, "\x04[Extra Guns]\x05 You can pick up an extra primary and secondary gun.");
				PrintToChat(client, "\x04[Extra Guns]\x05 Use the keyboard and the mouse wheel to switch between primary/secondary guns.");
			}
		}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new UserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(UserId);
	
	SlotStatus[client][Primary] = 0;
	SlotStatus[client][Secondary] = 0;
	SlotStatus[client][ExtraPrimary] = 0;
	SlotStatus[client][ExtraSecondary] = 0;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
}

// keep track of the players current weapons as they equip them.
public Action:OnWeaponEquip(client, weapon)
{
	if ((!IsEnabled) || (!IsPlayerAlive(client)))
	{
		return Plugin_Continue;
	}
	
	new String:WeaponName[30];
	GetEdictClassname(weapon, WeaponName, sizeof(WeaponName));
	
	new WeaponSlot;
	if (GetTrieValue(GunSlotTrie, WeaponName, WeaponSlot))
	{
		if (SlotStatus[client][Primary] && (!IsValidEntity(SlotStatus[client][Primary])))
		{
			SlotStatus[client][Primary] = 0;
		}
		
		if (SlotStatus[client][Secondary] && (!IsValidEntity(SlotStatus[client][Secondary])))
		{
			SlotStatus[client][Secondary] = 0;
		}
		
		if (WeaponSlot == 1)
		{
			if (!SlotStatus[client][Primary])
			{
				SlotStatus[client][Primary] = weapon;
			}
			else if (!SlotStatus[client][ExtraPrimary])
			{
				SlotStatus[client][ExtraPrimary] = weapon;
			}
		}
		else
		{
			if (!SlotStatus[client][Secondary])
			{
				SlotStatus[client][Secondary] = weapon;
			}
			else if (!SlotStatus[client][ExtraSecondary])
			{
				SlotStatus[client][ExtraSecondary] = weapon;
			}
		}
	}
	
	return Plugin_Continue;
}

// checks whether a player can pick up a weapon they are touching.
// EquipPlayerWeapon forces the player to equip the weapon causing them to drop their old weapon for that slot.
// only EquipPlayerWeapon if they have an empty slot.
public Action:OnWeaponCanUse(client, weapon)
{
	if ((!IsEnabled) || (!IsPlayerAlive(client)))
	{
		return Plugin_Continue;
	}
	
	new String:WeaponName[30];
	GetEdictClassname(weapon, WeaponName, sizeof(WeaponName));
	
	new WeaponSlot;
	if (GetTrieValue(GunSlotTrie, WeaponName, WeaponSlot))
	{
		if (SlotStatus[client][ExtraPrimary] && (!IsValidEntity(SlotStatus[client][ExtraPrimary])))
		{
			SlotStatus[client][ExtraPrimary] = 0;
		}
		
		if (SlotStatus[client][ExtraSecondary] && (!IsValidEntity(SlotStatus[client][ExtraSecondary])))
		{
			SlotStatus[client][ExtraSecondary] = 0;
		}
		
		if (WeaponSlot == 1)
		{
			if (IsEnabled & 1)
			{
				if ((!SlotStatus[client][Primary]) || (!SlotStatus[client][ExtraPrimary]))
				{
					BlockDrop[client] = true;
					EquipPlayerWeapon(client, weapon);
				}
			}
		}
		else
		{
			if (IsEnabled > 1)
			{
				if ((!SlotStatus[client][Secondary]) || (!SlotStatus[client][ExtraSecondary]))
				{
					BlockDrop[client] = true;
					EquipPlayerWeapon(client, weapon);
				}
			}
		}
	}
	
	return Plugin_Continue;
}

// keep track of the players current weapons as they drop them.
public Action:OnWeaponDrop(client, weapon)
{
	if ((!IsEnabled) || (!IsPlayerAlive(client)))
	{
		return Plugin_Continue;
	}
	
	// block players dropping their old weapons after being forced to pick up new ones with EquipPlayerWeapon.
	if (BlockDrop[client])
	{
		BlockDrop[client] = false;
		
		return Plugin_Handled;
	}
	
	if (SlotStatus[client][Primary] == weapon)
	{
		SlotStatus[client][Primary] = 0;
	}
	else if (SlotStatus[client][Secondary] == weapon)
	{
		SlotStatus[client][Secondary] = 0;
	}
	else if (SlotStatus[client][ExtraPrimary] == weapon)
	{
		SlotStatus[client][ExtraPrimary] = 0;
	}
	else if (SlotStatus[client][ExtraSecondary] == weapon)
	{
		SlotStatus[client][ExtraSecondary] = 0;
	}
	
	return Plugin_Continue;
}