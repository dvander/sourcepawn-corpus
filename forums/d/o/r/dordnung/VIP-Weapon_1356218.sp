#include <sourcemod>
#include <sdktools>
#include <stamm>

#pragma semicolon 1

#define GREEN 0x04
#define LIGHTGREEN 0x03

new Handle:level_needc;
new Handle:maximumc;
new Handle:can_p228c;
new Handle:can_deaglec;
new Handle:can_m4a1c;
new Handle:can_tmpc;
new Handle:can_augc;
new Handle:can_mac10c;
new Handle:can_m3c;
new Handle:can_ak47c;
new Handle:can_m249c;
new Handle:can_fivesevenc;
new Handle:can_xm1014c;
new Handle:can_glockc;
new Handle:can_p90c;
new Handle:can_uspc;
new Handle:can_ump45c;
new Handle:can_awpc;
new Handle:can_scoutc;
new Handle:can_elitec;
new Handle:can_famasc;
new Handle:can_galilc;
new Handle:can_mp5navyc;
new Handle:can_g3sg1c;
new Handle:can_sg550c;
new Handle:can_sg552c;

new level_need;
new maximum;
new can_p228;
new can_deagle;
new can_m4a1;
new can_tmp;
new can_aug;
new can_mac10;
new can_m3;
new can_ak47;
new can_m249;
new can_fiveseven;
new can_xm1014;
new can_glock;
new can_p90;
new can_usp;
new can_ump45;
new can_awp;
new can_scout;
new can_elite;
new can_famas;
new can_galil;
new can_mp5navy;
new can_g3sg1;
new can_sg550;
new can_sg552;

new Usages[MAXPLAYERS + 1];

public OnPluginStart()
{
	CreateConVar("VIP-Weapon_ver", "1.2", "VIP-Weapon Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	level_needc = CreateConVar("stamm_vip-weapon_level_need", "0", "VIP Level to use VIP-Weapon, 0 = Just VIP, 1 = Bronze, 2 = Silver, 3 = Gold, 4 = Platinum");
	maximumc = CreateConVar("stamm_vip-weapon_maximum", "2", "Max. usage per Round");
	
	can_p228c = CreateConVar("stamm_vip-weapon_p228", "1", "1 = Enable P-228, 0 = Disable");
	can_deaglec = CreateConVar("stamm_vip-weapon_deagle", "1", "1 = Enable Deagle, 0 = Disable");
	can_m4a1c = CreateConVar("stamm_vip-weapon_m4a1", "1", "1 = Enable M4, 0 = Disable");
	can_tmpc = CreateConVar("stamm_vip-weapon_tmp", "1", "1 = Enable TMP, 0 = Disable");
	can_augc = CreateConVar("stamm_vip-weapon_aug", "1", "1 = Enable AUG, 0 = Disable");
	can_mac10c = CreateConVar("stamm_vip-weapon_mac10", "1", "1 = Enable Mac, 0 = Disable");
	can_m3c = CreateConVar("stamm_vip-weapon_m3", "1", "1 = Enable M3, 0 = Disable");
	can_ak47c = CreateConVar("stamm_vip-weapon_ak47", "1", "1 = Enable AK-47, 0 = Disable");
	can_m249c = CreateConVar("stamm_vip-weapon_m249", "1", "1 = Enable M-249, 0 = Disable");
	can_fivesevenc = CreateConVar("stamm_vip-weapon_fiveseven", "1", "1 = Enable Fiveseven, 0 = Disable");
	can_xm1014c = CreateConVar("stamm_vip-weapon_xm1014", "1", "1 = Enable XM-1014, 0 = Disable");
	can_glockc = CreateConVar("stamm_vip-weapon_glock", "1", "1 = Enable Glock, 0 = Disable");
	can_p90c = CreateConVar("stamm_vip-weapon_p90", "1", "1 = Enable P-90, 0 = Disable");
	can_uspc = CreateConVar("stamm_vip-weapon_usp", "1", "1 = Enable USP, 0 = Disable");
	can_ump45c = CreateConVar("stamm_vip-weapon_ump45", "1", "1 = Enable UMP, 0 = Disable");
	can_awpc = CreateConVar("stamm_vip-weapon_awp", "1", "1 = Enable AWP, 0 = Disable");
	can_scoutc = CreateConVar("stamm_vip-weapon_scout", "1", "1 = Enable Scout, 0 = Disable");
	can_elitec = CreateConVar("stamm_vip-weapon_elite", "1", "1 = Enable Elite, 0 = Disable");
	can_famasc = CreateConVar("stamm_vip-weapon_famas", "1", "1 = Enable Famas, 0 = Disable");
	can_galilc = CreateConVar("stamm_vip-weapon_galil", "1", "1 = Enable Galil, 0 = Disable");
	can_mp5navyc = CreateConVar("stamm_vip-weapon_mp5navy", "1", "1 = Enable MP-5, 0 = Disable");
	can_g3sg1c = CreateConVar("stamm_vip-weapon_g3sg1", "1", "1 = Enable G3-SG1, 0 = Disable");
	can_sg550c = CreateConVar("stamm_vip-weapon_sg550", "1", "1 = Enable SG-550, 0 = Disable");
	can_sg552c = CreateConVar("stamm_vip-weapon_sg552", "1", "1 = Enable SG-552, 0 = Disable");
	
	AutoExecConfig(true, "VIP-Weapon", "stamm");
	
	RegConsoleCmd("sm_sgive", GiveCallback, "Give VIP's Weapons");
	
	HookEvent("round_start", RoundStart);
}

public RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new x=0; x <= MaxClients; x++) Usages[x] = 0;
}

public OnClientConnected(client)
{
	Usages[client] = 0;
}

public Action:GiveCallback(client, args)
{
	if (GetCmdArgs() == 1)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			if (IsClientVip(client, level_need))
			{
				if (Usages[client] < maximum)
				{
					decl String:WeaponName[64];
					
					GetCmdArg(1, WeaponName, sizeof(WeaponName));
					
					ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "");
					
					if (StrEqual(WeaponName, "p228") && can_p228 == 1)
					{
						GivePlayerItem(client, "weapon_p228");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "deagle") && can_deagle == 1)
					{
						GivePlayerItem(client, "weapon_deagle");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "m4a1") && can_m4a1 == 1)
					{
						GivePlayerItem(client, "weapon_m4a1");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "tmp") && can_tmp == 1)
					{
						GivePlayerItem(client, "weapon_tmp");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "aug") && can_aug == 1)
					{
						GivePlayerItem(client, "weapon_aug");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "mac10") && can_mac10 == 1)
					{
						GivePlayerItem(client, "weapon_mac10");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "m3") && can_m3 == 1)
					{
						GivePlayerItem(client, "weapon_m3");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "ak47") && can_ak47 == 1)
					{
						GivePlayerItem(client, "weapon_ak47");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "m249") && can_m249 == 1)
					{
						GivePlayerItem(client, "weapon_m249");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "fiveseven") && can_fiveseven == 1)
					{
						GivePlayerItem(client, "weapon_fiveseven");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "xm1014") && can_xm1014 == 1)
					{
						GivePlayerItem(client, "weapon_xm1014");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "glock") && can_glock == 1)
					{
						GivePlayerItem(client, "weapon_glock");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "p90") && can_p90 == 1)
					{
						GivePlayerItem(client, "weapon_p90");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "usp") && can_usp == 1)
					{
						GivePlayerItem(client, "weapon_usp");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "ump45") && can_ump45 == 1)
					{
						GivePlayerItem(client, "weapon_ump45");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "awp") && can_awp == 1)
					{
						GivePlayerItem(client, "weapon_awp");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "scout") && can_scout == 1)
					{
						GivePlayerItem(client, "weapon_scout");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "elite") && can_elite == 1)
					{
						GivePlayerItem(client, "weapon_elite");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "famas") && can_famas == 1)
					{
						GivePlayerItem(client, "weapon_famas");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "galil") && can_galil == 1)
					{
						GivePlayerItem(client, "weapon_galil");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "mp5navy") && can_mp5navy == 1)
					{
						GivePlayerItem(client, "weapon_mp5navy");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "g3sg1") && can_g3sg1 == 1)
					{
						GivePlayerItem(client, "weapon_g3sg1");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "sg550") && can_sg550 == 1)
					{
						GivePlayerItem(client, "weapon_sg550");
						Usages[client]++;
					}
					else if (StrEqual(WeaponName, "sg552") && can_sg552 == 1)
					{
						GivePlayerItem(client, "weapon_sg552");
						Usages[client]++;
					}
					else PrintToChat(client, "%c[%cVIP-Weapon%c] %cInvalid %cWeapon!!", LIGHTGREEN, GREEN, LIGHTGREEN, GREEN, LIGHTGREEN);
				}
				else PrintToChat(client, "%c[%cVIP-Weapon%c] %cMaxium %creached!!", LIGHTGREEN, GREEN, LIGHTGREEN, GREEN, LIGHTGREEN);
			}
			
			else 
			{
				if (level_need == 0) PrintToChat(client, "%c[%cVIP-Weapon%c] %cYou are no %cVIP!!", LIGHTGREEN, GREEN, LIGHTGREEN, GREEN, LIGHTGREEN);
				if (level_need == 1) PrintToChat(client, "%c[%cVIP-Weapon%c] %cYou are no %cBronze VIP!!", LIGHTGREEN, GREEN, LIGHTGREEN, GREEN, LIGHTGREEN);
				if (level_need == 2) PrintToChat(client, "%c[%cVIP-Weapon%c] %cYou are no %cSilver VIP!!", LIGHTGREEN, GREEN, LIGHTGREEN, GREEN, LIGHTGREEN);
				if (level_need == 3) PrintToChat(client, "%c[%cVIP-Weapon%c] %cYou are no %cGold VIP!!", LIGHTGREEN, GREEN, LIGHTGREEN, GREEN, LIGHTGREEN);
				if (level_need == 4) PrintToChat(client, "%c[%cVIP-Weapon%c] %cYou are no %cPlatinum VIP!!", LIGHTGREEN, GREEN, LIGHTGREEN, GREEN, LIGHTGREEN);
			}
		}
	}

	return Plugin_Handled;
}

public OnConfigsExecuted()
{
	level_need = GetConVarInt(level_needc);
	maximum = GetConVarInt(maximumc);
	
	can_p228 = GetConVarInt(can_p228c);
	can_deagle = GetConVarInt(can_deaglec);
	can_m4a1 = GetConVarInt(can_m4a1c);
	can_tmp = GetConVarInt(can_tmpc);
	can_aug = GetConVarInt(can_augc);
	can_mac10 = GetConVarInt(can_mac10c);
	can_m3 = GetConVarInt(can_m3c);
	can_ak47 = GetConVarInt(can_ak47c);
	can_m249 = GetConVarInt(can_m249c);
	can_fiveseven = GetConVarInt(can_fivesevenc);
	can_xm1014 = GetConVarInt(can_xm1014c);
	can_glock = GetConVarInt(can_glockc);
	can_p90 = GetConVarInt(can_p90c);
	can_usp = GetConVarInt(can_uspc);
	can_ump45 = GetConVarInt(can_ump45c);
	can_awp = GetConVarInt(can_awpc);
	can_scout = GetConVarInt(can_scoutc);
	can_elite = GetConVarInt(can_elitec);
	can_famas = GetConVarInt(can_famasc);
	can_galil = GetConVarInt(can_galilc);
	can_mp5navy = GetConVarInt(can_mp5navyc);
	can_g3sg1 = GetConVarInt(can_g3sg1c);
	can_sg550 = GetConVarInt(can_sg550c);
	can_sg552 = GetConVarInt(can_sg552c);
}