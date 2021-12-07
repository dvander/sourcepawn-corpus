#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

new g_ActiveWeaponOffset;

public Plugin:myinfo =
{
	name = "[L4D2]OneBulletLeft",
	author = "MasterMind420, credit to DeathChaos25",
	description = "Prevents primary weapons from firing there last round, a fix for Multiple Equipments",
	version = "1.0",
	//url = ""
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
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:f_Velocity[3], Float:f_Angles[3], &weapon)
{
	if (!IsSurvivor(client))
	{
		return;
	}

	if (buttons & IN_ATTACK)
	{
		decl String:s_Weapon[32];
		weapon = GetEntDataEnt2(client, g_ActiveWeaponOffset);
		
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
				new Gun = CreateEntityByName("weapon_rifle_m60");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
		else if (StrEqual(s_Weapon, "weapon_grenade_launcher"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			//new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (ammo <= 1 && clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new Gun = CreateEntityByName("weapon_grenade_launcher");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				//SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
		else if (StrEqual(s_Weapon, "weapon_rifle"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			//new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (ammo <= 1 && clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new Gun = CreateEntityByName("weapon_rifle");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				//SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
		else if (StrEqual(s_Weapon, "weapon_pumpshotgun"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (ammo <= 1 && clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new Gun = CreateEntityByName("weapon_pumpshotgun");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
		else if (StrEqual(s_Weapon, "weapon_autoshotgun"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (ammo <= 1 && clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new Gun = CreateEntityByName("weapon_autoshotgun");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
		else if (StrEqual(s_Weapon, "weapon_smg"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (ammo <= 1 && clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new Gun = CreateEntityByName("weapon_smg");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
		else if (StrEqual(s_Weapon, "weapon_hunting_rifle"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (ammo <= 1 && clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new Gun = CreateEntityByName("weapon_hunting_rifle");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
		else if (StrEqual(s_Weapon, "weapon_sniper_scout"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (ammo <= 1 && clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new Gun = CreateEntityByName("weapon_sniper_scout");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
		else if (StrEqual(s_Weapon, "weapon_sniper_military"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (ammo <= 1 && clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new Gun = CreateEntityByName("weapon_sniper_military");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
		else if (StrEqual(s_Weapon, "weapon_sniper_awp"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (ammo <= 1 && clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new Gun = CreateEntityByName("weapon_sniper_awp");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
		else if (StrEqual(s_Weapon, "weapon_smg_silenced"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (ammo <= 1 && clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new Gun = CreateEntityByName("weapon_smg_silenced");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
		else if (StrEqual(s_Weapon, "weapon_smg_mp5"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (ammo <= 1 && clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new Gun = CreateEntityByName("weapon_smg_mp5");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
		else if (StrEqual(s_Weapon, "weapon_shotgun_spas"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (ammo <= 1 && clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new Gun = CreateEntityByName("weapon_shotgun_spas");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
		else if (StrEqual(s_Weapon, "weapon_shotgun_chrome"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (ammo <= 1 && clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new Gun = CreateEntityByName("weapon_shotgun_chrome");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
		else if (StrEqual(s_Weapon, "weapon_rifle_sg552"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (ammo <= 1 && clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new Gun = CreateEntityByName("weapon_rifle_sg552");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
		else if (StrEqual(s_Weapon, "weapon_rifle_desert"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (ammo <= 1 && clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new Gun = CreateEntityByName("weapon_rifle_desert");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
		else if (StrEqual(s_Weapon, "weapon_rifle_ak47"))
		{
			new clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
			new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
			new laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
			
			if (ammo <= 1 && clip <= 1)
			{
				AcceptEntityInput(weapon, "kill");
				new Gun = CreateEntityByName("weapon_rifle_ak47");
				DispatchSpawn(Gun);
				EquipPlayerWeapon(client, Gun);
				SetEntProp(Gun, Prop_Send, "m_iClip1", 1);
				SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, PrimType);
				SetEntProp(Gun, Prop_Send, "m_upgradeBitVec", laser);
				//AcceptEntityInput(Gun, "Use", client);
			}
		}
	}
}

stock bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
} 