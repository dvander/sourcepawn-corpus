#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

new g_ActiveWeaponOffset;
static bool:buttondelay[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "[L4D2] Prevent M60 Drop", 
	author = "DeathChaos25", 
	description = "Prevents M60 from dropping, edited by MasterMind420 for multiple equipment",
	version = "1.0", 
	url = "https://forums.alliedmods.net/showthread.php?t=266485"
}


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:s_GameFolder[32];
	GetGameFolderName(s_GameFolder, sizeof(s_GameFolder));
	if (!StrEqual(s_GameFolder, "left4dead2", false))
	{
		strcopy(error, err_max, "This plugin is for Left 4 Dead 2 Only!");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	HookEvent("upgrade_incendiary_ammo", Event_AmmoUpgrade);
	HookEvent("upgrade_explosive_ammo", Event_AmmoUpgrade);
	HookEvent("receive_upgrade", Event_AmmoUpgrade);
	CreateTimer(0.1, M60AmmoCheck, _, TIMER_REPEAT);
}

public Action:M60AmmoCheck(Handle:Timer)
{
	if (!IsServerProcessing())
	{
		return;
	}
	decl String:weaponclass[128];
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsSurvivor(client) && IsPlayerAlive(client))
		{
			new ReserveAmmo = GetConVarInt(FindConVar("ammo_m60_max"));
			new weapon = GetPlayerWeaponSlot(client, 0);
			if (IsValidEdict(weapon))
			{
				
				new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
				new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
				new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
				
				GetEdictClassname(weapon, weaponclass, sizeof(weaponclass));
				
				if (StrEqual(weaponclass, "weapon_rifle_m60"))
				{
					if (clip == 0 && ammo > ReserveAmmo + 150)
					{
						SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + 150, _, PrimType);
						PrintHintText(client, "No infinite M60 ammo for you :3");
					}
					else if (clip > 0 && ammo > ReserveAmmo)
					{
						SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + (150 - clip), _, PrimType);
						PrintHintText(client, "No infinite M60 ammo for you :3");
					}
					else if (clip == 0 && ammo ==0)
					{
						SetEntProp(weapon, Prop_Send, "m_iClip1", 1);
					}
				}
			}
		}
	}
}

public Action:Event_AmmoUpgrade(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsSurvivor(client))
	{
		return;
	}
	new weapon = GetPlayerWeaponSlot(client, 0);
	decl String:s_Weapon[32];
	if (IsValidEntity(weapon))
	{
		GetEdictClassname(weapon, s_Weapon, sizeof(s_Weapon));
	}
	
	if (StrEqual(s_Weapon, "weapon_rifle_m60"))
	{
		new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
		if (clip == 0)
		{
			SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 150, 1);
			SetEntProp(weapon, Prop_Send, "m_iClip1", 150);
		}
	}
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:f_Velocity[3], Float:f_Angles[3])
{
	if (!IsSurvivor(client))
	{
		return;
	}
	
	if (buttons & IN_ATTACK)
	{
		decl String:s_Weapon[32];
		new weapon = GetEntDataEnt2(client, g_ActiveWeaponOffset);
		
		if (IsValidEntity(weapon))
		{
			GetEdictClassname(weapon, s_Weapon, sizeof(s_Weapon));
		}
		if (StrEqual(s_Weapon, "weapon_rifle_m60"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new M60 = CreateEntityByName("weapon_rifle_m60");
				DispatchSpawn(M60);
				EquipPlayerWeapon(client, M60);
				SetEntProp(M60, Prop_Send, "m_iClip1", 0);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				SetEntProp(M60, Prop_Send, "m_upgradeBitVec", laser);
			}
		}
	}
	/*
	else if (buttons & IN_USE && !buttondelay[client])
	{
		new M60 = GetClientAimTarget(client, false);
		decl String:s_Weapon[32];
		
		if (IsValidEntity(M60))
		{
			GetEdictClassname(M60, s_Weapon, sizeof(s_Weapon));
		}
		CreateTimer(2.0, ResetDelay, client);
		if (StrEqual(s_Weapon, "weapon_rifle_m60"))
		{
			EquipPlayerWeapon(client, M60);
		}
		else if (StrEqual(s_Weapon, "weapon_ammo_spawn"))
		{
			new ReserveAmmo = GetConVarInt(FindConVar("ammo_m60_max"));
			new weapon = GetPlayerWeaponSlot(client, 0);
			
			if (IsValidEdict(weapon))
			{
				new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
				GetEdictClassname(weapon, s_Weapon, sizeof(s_Weapon));
				if (StrEqual(s_Weapon, "weapon_rifle_m60"))
				{
					SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo, _, PrimType);
				}
			}
		}
	}
	*/
}
/*
public Action:ResetDelay(Handle:timer, any:client)
{
	buttondelay[client] = false;
}
*/
stock bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
} 