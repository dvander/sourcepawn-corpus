#include <sourcemod>
#include <sdktools>

new g_ActiveWeaponOffset;

public Plugin:myinfo = 
{
	name = "[L4D2] Prevent M60 Drop", 
	author = "DeathChaos25, MasterMind420", 
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
	//CreateTimer(0.1, M60ReloadCheck, _, TIMER_REPEAT);
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
			if (IsFakeClient(client) || !IsFakeClient(client))
			{
				new ReserveAmmo = GetConVarInt(FindConVar("ammo_m60_max"));
				new WeaponSlot = GetPlayerWeaponSlot(client, 0);
				if (IsValidEdict(WeaponSlot))
				{			
					new Clip = GetEntProp(WeaponSlot, Prop_Data, "m_iClip1");
					new PrimType = GetEntProp(WeaponSlot, Prop_Send, "m_iPrimaryAmmoType");
					new Ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
				
					GetEdictClassname(WeaponSlot, weaponclass, sizeof(weaponclass));
				
					if (StrEqual(weaponclass, "weapon_rifle_m60"))
					{
						if (Clip == 0 && Ammo > ReserveAmmo + 150)
						{
							SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + 150, _, PrimType);
							PrintHintText(client, "No infinite M60 ammo for you :3");
						}
						else if (Clip > 0 && Ammo > ReserveAmmo)
						{
							SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmo + (150 - Clip), _, PrimType);
							PrintHintText(client, "No infinite M60 ammo for you :3");
						}
						else if (Clip == 0 && Ammo ==0)
						{
							SetEntProp(WeaponSlot, Prop_Send, "m_iClip1", 1);
						}
					}
				}
			}
		}
	}
}

//if(GetEntProp(client, Prop_Send, "m_isHoldingFireButton") > 0)
//m_releasedAltFireButton (offset 5416) (type integer) (bits 1)
//m_releasedFireButton (offset 5417) (type integer) (bits 1)
//m_isHoldingAltFireButton (offset 5419) (type integer) (bits 1)
//m_isHoldingFireButton (offset 5418) (type integer) (bits 1)
	
/*
public Action:M60ReloadCheck(Handle:Timer)
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
			if (IsFakeClient(client) || !IsFakeClient(client))
			{
				new WeaponSlot = GetPlayerWeaponSlot(client, 0);
				new weapon = GetEntDataEnt2(client, g_ActiveWeaponOffset);
				if (IsValidEdict(WeaponSlot))
				{			
					GetEdictClassname(WeaponSlot, weaponclass, sizeof(weaponclass));
					if (StrEqual(weaponclass, "weapon_rifle_m60"))
					{
						if(GetEntProp(weapon, Prop_Data, "m_bInReload"))
						{
							SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1000.0);
						}
						else
						{
							SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
						}
					}
				}
			}
		}
	}
}
*/

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

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3])
{
	if (!IsSurvivor(client))
	{
		return;
	}
	if (IsSurvivor(client) && IsPlayerAlive(client))
	{
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
				new Clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
				new PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
				new Ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimType);
				new Laser = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
				if (Clip <= 1)
				{
					AcceptEntityInput(weapon, "kill");
					new M60 = CreateEntityByName("weapon_rifle_m60");
					DispatchSpawn(M60);
					EquipPlayerWeapon(client, M60);
					SetEntProp(M60, Prop_Send, "m_iClip1", 0);
					SetEntProp(client, Prop_Send, "m_iAmmo", Ammo, _, PrimType);
					SetEntProp(M60, Prop_Send, "m_upgradeBitVec", Laser);
				}
			}
		}
	}
}

/*
public OnGameFrame()
{
	for(new client=1; client<=MaxClients; client++)
	{
		if(!IsClientInGame(client)) { return; }
		if(GetClientTeam(client) != 2) { return; }
		if(IsPlayerAlive(client))
		{
			decl String:s_Weapon[32];
			new weapon = GetEntDataEnt2(client, g_ActiveWeaponOffset);
		
			if (IsValidEntity(weapon))
			{
				GetEdictClassname(weapon, s_Weapon, sizeof(s_Weapon));
			}
			if (StrEqual(s_Weapon, "weapon_rifle_m60"))
			{
				new InReload = GetEntProp(weapon, Prop_Data, "m_bInReload");
				if(InReload == 1)
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1000.0);
					PrintToChat(client, "IN_RELOAD");
				}
				else
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1000.0);
					//SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
					PrintToChat(client, "NOT_IN_RELOAD");
				}
			}
		}
	}
}

							if (buttons & IN_ATTACK)
							{
								buttons &= ~IN_ATTACK;
							}
							return Plugin_Changed;

	if (buttons & IN_RELOAD)
	{
		new weapon = GetEntDataEnt2(client, g_ActiveWeaponOffset);
		new InReload = GetEntProp(weapon, Prop_Data, "m_bInReload");
		if(InReload == 1)
		{
			if (buttons & IN_ATTACK) buttons &= ~IN_ATTACK;
			//SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1000.0);
			PrintToChat(client, "WORKING");
		}
		else
		{
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
			PrintToChat(client, "NOT_WORKING");
		}
	}
*/

stock bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
} 