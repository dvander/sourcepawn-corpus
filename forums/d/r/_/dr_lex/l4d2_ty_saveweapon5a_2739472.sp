/**
 * =============================================================================
 * Copyright 2011 - 2020 steamcommunity.com/profiles/76561198025355822/
 * Release 5a 2021 http://steamcommunity.com/id/dr_lex/
 * Fixed 2015 steamcommunity.com/id/Electr0n
 * Fixed 2016 steamcommunity.com/id/mixjayrus
 * Fixed 2016 user Merudo
 *

 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <www.sourcemod.net/license.php>.
 *
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

int ig_h1[MAXPLAYERS+1];
int ig_h1a[MAXPLAYERS+1];
int ig_h2a[MAXPLAYERS+1];
int ig_h3a[MAXPLAYERS+1];
int ig_h4a[MAXPLAYERS+1];
float ig_h5a[MAXPLAYERS+1];

char sg_slot0[MAXPLAYERS+1][40];
int ig_prop0[MAXPLAYERS+1];
int ig_prop1[MAXPLAYERS+1];
int ig_prop2[MAXPLAYERS+1];
int ig_prop3[MAXPLAYERS+1];
int ig_prop4[MAXPLAYERS+1];
char sg_slot0a[MAXPLAYERS+1][40];
int ig_prop0a[MAXPLAYERS+1];
int ig_prop1a[MAXPLAYERS+1];
int ig_prop2a[MAXPLAYERS+1];
int ig_prop3a[MAXPLAYERS+1];
int ig_prop4a[MAXPLAYERS+1];
char sg_slot1[MAXPLAYERS+1][40];
int ig_prop5[MAXPLAYERS+1];
int ig_prop6[MAXPLAYERS+1];
char sg_slot1a[MAXPLAYERS+1][40];
int ig_prop5a[MAXPLAYERS+1];
int ig_prop6a[MAXPLAYERS+1];
char sg_slot2[MAXPLAYERS+1][40];
char sg_slot2a[MAXPLAYERS+1][40];
char sg_slot3[MAXPLAYERS+1][40];
char sg_slot3a[MAXPLAYERS+1][40];
char sg_slot4[MAXPLAYERS+1][40];
char sg_slot4a[MAXPLAYERS+1][40];

char sg_buf2[64];
char sg_buf12[32];

int ig_player[MAXPLAYERS+1];
int ig_afk[MAXPLAYERS+1];

int ig_protection;
int ig_offset;

public Plugin myinfo =
{
	name = "[L4D2] Save Weapon",
	author = "dr lex",
	description = "L4D2 coop save weapon",
	version = "5.0a",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("map_transition", Event_MapTransition);
	HookEvent("finale_win", Event_FinaleWin, EventHookMode_PostNoCopy);

	ig_offset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
}

stock void HxCleaning(int &client)
{
	ig_afk[client] = 0;
	ig_player[client] = 0;
}

stock void HxCleaningMap(char [] sMap)
{
	if (StrContains(sMap, "m1_", true) > 1)
	{
		int i = 1;
		while (i <= MaxClients)
		{
			HxCleaning(i);
			HxCleaningAfk(i);
			i += 1;
		}
	}
	else
	{
		if (HxDlcStartMaps(sMap))
		{
			int i = 1;
			while (i <= MaxClients)
			{
				HxCleaning(i);
				HxCleaningAfk(i);
				i += 1;
			}
		}
	}
}

stock void HxRemoveWeapon(int &client)
{
	int iSlot0 = GetPlayerWeaponSlot(client, 0);
	int iSlot1 = GetPlayerWeaponSlot(client, 1);
	int iSlot2 = GetPlayerWeaponSlot(client, 2);
	int iSlot3 = GetPlayerWeaponSlot(client, 3);
	int iSlot4 = GetPlayerWeaponSlot(client, 4);

	if (iSlot0 > 0)
	{
		RemovePlayerItem(client, iSlot0);
		AcceptEntityInput(iSlot0, "Kill");
	}

	if (iSlot1 > 0)
	{
		RemovePlayerItem(client, iSlot1);
		AcceptEntityInput(iSlot1, "Kill");
	}

	if (iSlot2 > 0)
	{
		RemovePlayerItem(client, iSlot2);
		AcceptEntityInput(iSlot2, "Kill");
	}

	if (iSlot3 > 0)
	{
		RemovePlayerItem(client, iSlot3);
		AcceptEntityInput(iSlot3, "Kill");
	}

	if (iSlot4 > 0)
	{
		RemovePlayerItem(client, iSlot4);
		AcceptEntityInput(iSlot4, "Kill");
	}
}

stock void HxFakeCHEAT(int &client, const char[] sCmd, const char[] sArg)
{
	int iFlags = GetCommandFlags(sCmd);
	SetCommandFlags(sCmd, iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", sCmd, sArg);
	SetCommandFlags(sCmd, iFlags);
}

stock int HxDlcStartMaps(char[] Map)
{
	if (StrEqual(Map, "l4dblackoutbasement1"))
	{ /* Blackout Basement */
		return 1;
	}
	else if (StrEqual(Map, "l4d2_city17_01"))
	{ /* City 17 v3.2 */
		return 1;
	}
	else if (StrEqual(Map, "damitdc1"))
	{ /* Damit 2 - The Director's Cut */
		return 1;
	}
	else if (StrEqual(Map, "l4d2_deadcity01_riverside"))
	{ /* DeadCity II */
		return 1;
	}
	else if (StrEqual(Map, "deathrow01_streets"))
	{ /* Death Row */
		return 1;
	}
	else if (StrEqual(Map, "l4d2_fallindeath01"))
	{ /* Fall in Death */
		return 1;
	}
	else if (StrEqual(Map, "msd1_town"))
	{ /* Farewell Chenming */
		return 1;
	}
	else if (StrEqual(Map, "l4d2_ff01_woods"))
	{ /* Fatal Freight */
		return 1;
	}
	else if (StrEqual(Map, "l4d_ihm01_forest"))
	{ /* I Hate Mountains Team */
		return 1;
	}
	else if (StrEqual(Map, "l4d_yama_1"))
	{ /* Yama */
		return 1;
	}
	else if (StrEqual(Map, "l4d2_diescraper1_apartment_36") || StrEqual(Map, "l4d2_diescraper1_apartment_361"))
	{ /* Diescraper Redux 3.62 */
		return 1;
	}
	else if (StrEqual(Map, "l4d2_planb1_v051"))
	{ /* Plan B [Beta 0.51] */
		return 1;
	}
	else if (StrEqual(Map, "l4d2_ravenholmwar_1"))
	{ /* We Don't Go To Ravenholm 2 */
		return 1;
	}
	else if (StrEqual(Map, "redemptionII-deadstop"))
	{ /* RedemptionII */
		return 1;
	}
	else if (StrEqual(Map, "eu01_residential_b16"))
	{ /* Tour of Terror */
		return 1;
	}
	else if (StrEqual(Map, "uf1_boulevard"))
	{ /* Urban Flight */
		return 1;
	}
	else if (StrEqual(Map, "l4d_viennacalling_city"))
	{ /* Vienna Calling 1 */
		return 1;
	}
	else if (StrEqual(Map, "srocchurch"))
	{ /* Warcelona */
		return 1;
	}
	else if (StrEqual(Map, "dw_woods"))
	{ /* Dark Wood (Extended) */
		return 1;
	}
	else if (StrEqual(Map, "bhm1_outskirts"))
	{ /* Left Behind */
		return 1;
	}
	else if (StrEqual(Map, "cbm1_lake"))
	{ /* Blood Proof */
		return 1;
	}
	else if (StrEqual(Map, "c14m1_orchard"))
	{ /* Dam It [Remastered] */
		return 1;
	}
	else if (StrEqual(Map, "dm1_suburbs"))
	{ /* Devil Mountain */
		return 1;
	}
	else if (StrEqual(Map, "p84m1_apartment"))
	{ /* Precinct 84 (2018) */
		return 1;
	}
	else if (StrEqual(Map, "l4d_stadium1_apartment"))
	{ /* Suicide Blitz L4D1 Port */
		return 1;
	}
	else if (StrEqual(Map, "omf_01"))
	{ /* Our Mutual Fiend */
		return 1;
	}
	else if (StrEqual(Map, "l4d2_draxmap1"))
	{ /* Death Strip */
		return 1;
	}
	else if (StrEqual(Map, "deadbeat01_forest"))
	{ /* Deadbeat Escape */
		return 1;
	}
	else if (StrEqual(Map, "ch01_jupiter"))
	{ /* Chernobyl: Chapter One */
		return 1;
	}
	else if (StrEqual(Map, "l4d2_bts01_forest"))
	{ /* Back To School */
		return 1;
	}
	else if (StrEqual(Map, "l4d_tbm_1"))
	{ /* The Bloody Moors */
		return 1;
	}
	else if (StrEqual(Map, "l4d2_stadium1_apartment"))
	{ /* Suicide Blitz 2 */
		return 1;
	}
	else if (StrEqual(Map, "mall_of_ukraine"))
	{ /* Dnieper v2.0 - Fixed */
		return 1;
	}
	else if (StrEqual(Map, "l4d_dbde_citylights"))
	{ /* Dead Before Dawn (Extended) */
		return 1;
	}
	else
	{ /* No */
		return 0;
	}
}

stock void HxSetAmmo(int &client, char[] weapon, int count)
{
	int iOffset;
	if (StrEqual(weapon, "weapon_rifle") 
	|| StrEqual(weapon, "weapon_rifle_sg552") 
	|| StrEqual(weapon, "weapon_rifle_desert") 
	|| StrEqual(weapon, "weapon_rifle_ak47"))
	{
		iOffset = 12;
	}
	else if (StrEqual(weapon, "weapon_rifle_m60"))
	{
		iOffset = 24;
	}
	else if (StrEqual(weapon, "weapon_smg") 
	|| StrEqual(weapon, "weapon_smg_silenced") 
	|| StrEqual(weapon, "weapon_smg_mp5"))
	{
		iOffset = 20;
	}
	else if (StrEqual(weapon, "weapon_pumpshotgun") 
	|| StrEqual(weapon, "weapon_shotgun_chrome"))
	{
		iOffset = 28;
	}
	else if (StrEqual(weapon, "weapon_autoshotgun") 
	|| StrEqual(weapon, "weapon_shotgun_spas"))
	{
		iOffset = 32;
	}
	else if (StrEqual(weapon, "weapon_hunting_rifle"))
	{
		iOffset = 36;
	}
	else if (StrEqual(weapon, "weapon_sniper_scout") 
	|| StrEqual(weapon, "weapon_sniper_military") 
	|| StrEqual(weapon, "weapon_sniper_awp"))
	{
		iOffset = 40;
	}
	else if (StrEqual(weapon, "weapon_grenade_launcher"))
	{
		iOffset = 68;
	}

	if (iOffset > 0)
	{
		SetEntData(client, ig_offset + iOffset, count);
	}
}

stock void HxGiveWeapon(int &client, int afk)
{
	if (afk)
	{
		SetEntProp(client, Prop_Send, "m_iHealth", ig_h1a[client]);
		SetEntProp(client, Prop_Send, "m_isGoingToDie", ig_h2a[client]);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", ig_h3a[client]);
		SetEntProp(client, Prop_Send, "m_currentReviveCount", ig_h4a[client]);
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", ig_h5a[client]);
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime",	GetGameTime());
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_iHealth", ig_h1[client]);
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
		SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime",	GetGameTime());
	}

	HxRemoveWeapon(client);
	if (afk)
	{
		if (sg_slot0a[client][0])
		{
			HxFakeCHEAT(client, "give", sg_slot0a[client]);

			int iSlot0 = GetPlayerWeaponSlot(client, 0);
			if (iSlot0 > 0)
			{
				SetEntProp(iSlot0, Prop_Send, "m_iClip1", ig_prop0a[client], 4);
				SetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", ig_prop1a[client], 4);
				SetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ig_prop2a[client], 4);
				HxSetAmmo(client, sg_slot0a[client], ig_prop3a[client]);
				SetEntProp(iSlot0, Prop_Send, "m_nSkin", ig_prop4a[client], 4);
			}
		}
		else
		{
			HxFakeCHEAT(client, "give", "smg");
		}
		
		if (sg_slot1a[client][0])
		{
			if (!strcmp(sg_slot1a[client], "dual_pistol", true))
			{
				HxFakeCHEAT(client, "give", "pistol");
				HxFakeCHEAT(client, "give", "pistol");
			}
			else
			{
				HxFakeCHEAT(client, "give", sg_slot1a[client]);

				int iSlot1 = GetPlayerWeaponSlot(client, 1);
				if (!strcmp(sg_slot1a[client], "chainsaw", true))
				{
					if (iSlot1 > 0)
					{
						SetEntProp(iSlot1, Prop_Send, "m_iClip1", ig_prop5a[client], 4);
					}
				}
				if (!strcmp(sg_slot1a[client], "cricket_bat", true))
				{
					if (iSlot1 > 0)
					{
						SetEntProp(iSlot1, Prop_Send, "m_nSkin", ig_prop6a[client], 4);
					}
				}
				if (!strcmp(sg_slot1a[client], "crowbar", true))
				{
					if (iSlot1 > 0)
					{
						SetEntProp(iSlot1, Prop_Send, "m_nSkin", ig_prop6a[client], 4);
					}
				}
				if (!strcmp(sg_slot1a[client], "pistol_magnum", true))
				{
					if (iSlot1 > 0)
					{
						SetEntProp(iSlot1, Prop_Send, "m_nSkin", ig_prop6a[client], 4);
					}
				}
			}
		}
		else
		{
			HxFakeCHEAT(client, "give", "pistol");
		}
		
		if (sg_slot2a[client][0])
		{
			HxFakeCHEAT(client, "give", sg_slot2a[client]);
		}
		if (sg_slot3a[client][0])
		{
			HxFakeCHEAT(client, "give", sg_slot3a[client]);
		}
		if (sg_slot4a[client][0])
		{
			HxFakeCHEAT(client, "give", sg_slot4a[client]);
		}
		
		HxCleaningAfk(client);
	}
	else
	{
		if (sg_slot0[client][0])
		{
			HxFakeCHEAT(client, "give", sg_slot0[client]);

			int iSlot0 = GetPlayerWeaponSlot(client, 0);
			if (iSlot0 > 0)
			{
				SetEntProp(iSlot0, Prop_Send, "m_iClip1", ig_prop0[client], 4);
				SetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", ig_prop1[client], 4);
				SetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ig_prop2[client], 4);
				HxSetAmmo(client, sg_slot0[client], ig_prop3[client]);
				SetEntProp(iSlot0, Prop_Send, "m_nSkin", ig_prop4[client], 4);
			}
		}
		else
		{
			HxFakeCHEAT(client, "give", "smg");
		}
		
		if (sg_slot1[client][0])
		{
			if (!strcmp(sg_slot1[client], "dual_pistol", true))
			{
				HxFakeCHEAT(client, "give", "pistol");
				HxFakeCHEAT(client, "give", "pistol");
			}
			else
			{
				HxFakeCHEAT(client, "give", sg_slot1[client]);

				int iSlot1 = GetPlayerWeaponSlot(client, 1);
				if (!strcmp(sg_slot1[client], "chainsaw", true))
				{
					if (iSlot1 > 0)
					{
						SetEntProp(iSlot1, Prop_Send, "m_iClip1", ig_prop5[client], 4);
					}
				}
				if (!strcmp(sg_slot1[client], "cricket_bat", true))
				{
					if (iSlot1 > 0)
					{
						SetEntProp(iSlot1, Prop_Send, "m_nSkin", ig_prop6[client], 4);
					}
				}
				if (!strcmp(sg_slot1[client], "crowbar", true))
				{
					if (iSlot1 > 0)
					{
						SetEntProp(iSlot1, Prop_Send, "m_nSkin", ig_prop6[client], 4);
					}
				}
				if (!strcmp(sg_slot1[client], "pistol_magnum", true))
				{
					if (iSlot1 > 0)
					{
						SetEntProp(iSlot1, Prop_Send, "m_nSkin", ig_prop6[client], 4);
					}
				}
			}
		}
		else
		{
			HxFakeCHEAT(client, "give", "pistol");
		}
		
		if (sg_slot2[client][0])
		{
			HxFakeCHEAT(client, "give", sg_slot2[client]);
		}
		if (sg_slot3[client][0])
		{
			HxFakeCHEAT(client, "give", sg_slot3[client]);
		}
		if (sg_slot4[client][0])
		{
			HxFakeCHEAT(client, "give", sg_slot4[client]);
		}
	}
}

public void HxGiveMain(int &i)
{
	if (IsPlayerAlive(i))
	{
		if (ig_player[i])
		{
			HxGiveWeapon(i, 0);
		}
		else
		{
			HxFakeCHEAT(i, "give", "smg");
		}
	}
}

public Action HxTimerRS(Handle timer)
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				HxGiveMain(i);
			}
		}
		i += 1;
	}

	return Plugin_Stop;
}

stock void HxKickClient(int &client)
{
	if (GetClientTeam(client) == 2)
	{
		if (IsPlayerAlive(client))
		{
			HxRemoveWeapon(client);
		}
	}
	KickClient(client, "Mt");
}

public Action HxTimerTeam2(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (GetClientTeam(client) == 2)
		{
			if (ig_afk[client])
			{
				HxGiveWeapon(client, 1);
				ig_afk[client] = 0;
				ig_player[client] = 1;
			}
			else
			{
				HxGiveMain(client);
			}
		}
		if (!IsPlayerAlive(client))
		{
			CreateTimer(2.0, HxTimerTeam2, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Stop;
}

stock void HxGetHealth(int afk, int client)
{
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
	if (afk)
	{
		ig_h1a[client] = GetEntProp(client, Prop_Send, "m_iHealth", 4);
		ig_h2a[client] = GetEntProp(client, Prop_Send, "m_isGoingToDie", 4);
		ig_h3a[client] = GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 4);
		ig_h4a[client] = GetEntProp(client, Prop_Send, "m_currentReviveCount", 4);
		ig_h5a[client] = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_iHealth", 100, 1);
		ig_h1[client] = GetEntProp(client, Prop_Send, "m_iHealth", 4);
	}
}

stock int HxGetAmmo(int &client, char[] weapon)
{
	int iOffset;
	if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
	{
		iOffset = 12;
	}
	else if (StrEqual(weapon, "weapon_rifle_m60"))
	{
		iOffset = 24;
	}
	else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
	{
		iOffset = 20;
	}
	else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
	{
		iOffset = 28;
	}
	else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
	{
		iOffset = 32;
	}
	else if (StrEqual(weapon, "weapon_hunting_rifle"))
	{
		iOffset = 36;
	}
	else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
	{
		iOffset = 40;
	}
	else if (StrEqual(weapon, "weapon_grenade_launcher"))
	{
		iOffset = 68;
	}

	return iOffset > 0 ? GetEntData(client, ig_offset + iOffset) : 0;
}

stock void HxGetSlot0(int afk, int &client)
{
	int iSlot0 = GetPlayerWeaponSlot(client, 0);
	if (iSlot0 > 0)
	{
		if (afk)
		{
			GetEdictClassname(iSlot0, sg_slot0a[client], 39);
			ig_prop0a[client] = GetEntProp(iSlot0, Prop_Send, "m_iClip1", 4);
			ig_prop1a[client] = GetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", 4);
			ig_prop2a[client] = GetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4);
			ig_prop3a[client] = HxGetAmmo(client, sg_slot0a[client]);
			ig_prop4a[client] = GetEntProp(iSlot0, Prop_Send, "m_nSkin", 4);
		}
		else
		{
			GetEdictClassname(iSlot0, sg_slot0[client], 39);
			ig_prop0[client] = GetEntProp(iSlot0, Prop_Send, "m_iClip1", 4);
			ig_prop1[client] = GetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", 4);
			ig_prop2[client] = GetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4);
			ig_prop3[client] = HxGetAmmo(client, sg_slot0[client]);
			ig_prop4[client] = GetEntProp(iSlot0, Prop_Send, "m_nSkin", 4);
		}
		RemovePlayerItem(client, iSlot0);
		AcceptEntityInput(iSlot0, "Kill");
	}
}

stock int HxGetSlot1(int afk, int &client)
{
	int iSlot1 = GetPlayerWeaponSlot(client, 1);
	if (iSlot1 > 0)
	{
		sg_buf2[0] = '\0';
		GetEntPropString(iSlot1, Prop_Data, "m_ModelName", sg_buf2, sizeof(sg_buf2)-1);

		if (StrContains(sg_buf2, "v_pistola.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "pistol";
			}
			else
			{
				sg_slot1[client] = "pistol";
			}
			return 1;
		}

		if (StrContains(sg_buf2, "v_dual_pistola.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "dual_pistol";
			}
			else
			{
				sg_slot1[client] = "dual_pistol";
			}
			return 1;
		}

		if (StrContains(sg_buf2, "v_desert_eagle.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "pistol_magnum";
				ig_prop6a[client] = GetEntProp(iSlot1, Prop_Send, "m_nSkin", 4);
			}
			else
			{
				sg_slot1[client] = "pistol_magnum";
				ig_prop6[client] = GetEntProp(iSlot1, Prop_Send, "m_nSkin", 4);
			}
			return 1;
		}

		if (StrContains(sg_buf2, "v_bat.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "baseball_bat";
			}
			else
			{
				sg_slot1[client] = "baseball_bat";
			}
			return 1;
		}

		if (StrContains(sg_buf2, "v_cricket_bat.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "cricket_bat";
				ig_prop6a[client] = GetEntProp(iSlot1, Prop_Send, "m_nSkin", 4);
			}
			else
			{
				sg_slot1[client] = "cricket_bat";
				ig_prop6[client] = GetEntProp(iSlot1, Prop_Send, "m_nSkin", 4);
			}
			return 1;
		}

		if (StrContains(sg_buf2, "v_crowbar.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "crowbar";
				ig_prop6a[client] = GetEntProp(iSlot1, Prop_Send, "m_nSkin", 4);
			}
			else
			{
				sg_slot1[client] = "crowbar";
				ig_prop6[client] = GetEntProp(iSlot1, Prop_Send, "m_nSkin", 4);
			}
			return 1;
		}

		if (StrContains(sg_buf2, "v_fireaxe.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "fireaxe";
			}
			else
			{
				sg_slot1[client] = "fireaxe";
			}
			return 1;
		}

		if (StrContains(sg_buf2, "v_katana.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "katana";
			}
			else
			{
				sg_slot1[client] = "katana";
			}
			return 1;
		}

		if (StrContains(sg_buf2, "v_golfclub.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "golfclub";
			}
			else
			{
				sg_slot1[client] = "golfclub";
			}
			return 1;
		}

		if (StrContains(sg_buf2, "v_machete.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "machete";
			}
			else
			{
				sg_slot1[client] = "machete";
			}
			return 1;
		}

		if (StrContains(sg_buf2, "v_tonfa.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "tonfa";
			}
			else
			{
				sg_slot1[client] = "tonfa";
			}
			return 1;
		}

		if (StrContains(sg_buf2, "v_electric_guitar.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "electric_guitar";
			}
			else
			{
				sg_slot1[client] = "electric_guitar";
			}
			return 1;
		}

		if (StrContains(sg_buf2, "v_frying_pan.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "frying_pan";
			}
			else
			{
				sg_slot1[client] = "frying_pan";
			}
			return 1;
		}

		if (StrContains(sg_buf2, "v_chainsaw.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "chainsaw";
				ig_prop5a[client] = GetEntProp(iSlot1, Prop_Send, "m_iClip1", 4);
			}
			else
			{
				sg_slot1[client] = "chainsaw";
				ig_prop5[client] = GetEntProp(iSlot1, Prop_Send, "m_iClip1", 4);
			}
			return 1;
		}

		if (StrContains(sg_buf2, "v_knife_t.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "knife";
			}
			else
			{
				sg_slot1[client] = "knife";
			}
			return 1;
		}
		
		if (StrContains(sg_buf2, "v_pitchfork.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "pitchfork";
			}
			else
			{
				sg_slot1[client] = "pitchfork";
			}
			return 1;
		}
		
		if (StrContains(sg_buf2, "v_shovel.mdl", true) != -1)
		{
			if (afk)
			{
				sg_slot1a[client] = "shovel";
			}
			else
			{
				sg_slot1[client] = "shovel";
			}
			return 1;
		}
	}
	return 0;
}

stock void HxGetSlot2(int afk, int &client)
{
	int iSlot2 = GetPlayerWeaponSlot(client, 2);
	if (iSlot2 > 0)
	{
		if (afk)
		{
			GetEdictClassname(iSlot2, sg_slot2a[client], 39);
		}
		else
		{
			GetEdictClassname(iSlot2, sg_slot2[client], 39);
		}
		RemovePlayerItem(client, iSlot2);
		AcceptEntityInput(iSlot2, "Kill");
	}
}

stock void HxGetSlot3(int afk, int &client)
{
	int iSlot3 = GetPlayerWeaponSlot(client, 3);
	if (iSlot3 > 0)
	{
		if (afk)
		{
			GetEdictClassname(iSlot3, sg_slot3a[client], 39);
		}
		else
		{
			GetEdictClassname(iSlot3, sg_slot3[client], 39);
		}
		RemovePlayerItem(client, iSlot3);
		AcceptEntityInput(iSlot3, "Kill");
	}
}

stock void HxGetSlot4(int afk, int &client)
{
	int iSlot4 = GetPlayerWeaponSlot(client, 4);
	if (iSlot4 > 0)
	{
		if (afk)
		{
			GetEdictClassname(iSlot4, sg_slot4a[client], 39);
		}
		else
		{
			GetEdictClassname(iSlot4, sg_slot4[client], 39);
		}
		RemovePlayerItem(client, iSlot4);
		AcceptEntityInput(iSlot4, "Kill");
	}
}

stock int HxBotXYZ(int &client)
{
	int i = 1;
	int iC = -1;
	float fXYZ1[3];
	float fXYZ2[3];
	GetClientAbsOrigin(client, fXYZ1);

	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (IsFakeClient(i))
			{
				GetClientAbsOrigin(i, fXYZ2);
				if (fXYZ1[0] == fXYZ2[0])
				{
					if (fXYZ1[1] == fXYZ2[1])
					{
						iC = i;
						break;
					}
				}
			}
		}
		i += 1;
	}

	if (iC > 0)
	{
		return iC;
	}

	return client;
}

stock void HxSaveWeaponAfk(int client)
{
	int iBot = HxBotXYZ(client);
	if (GetClientTeam(iBot) == 2)
	{
		if (IsPlayerAlive(iBot))
		{
			HxGetHealth(1, iBot);
			HxGetSlot0(1, iBot);
			HxGetSlot1(1, iBot);
			HxGetSlot2(1, iBot);
			HxGetSlot3(1, iBot);
			HxGetSlot4(1, iBot);
			
			HxAFK(client, iBot);

			HxCleaningAfk(iBot);
		}
	}
}

stock void HxAFK(int client, int bot)
{
	ig_h1a[client] = ig_h1a[bot];
	ig_h2a[client] = ig_h2a[bot];
	ig_h3a[client] = ig_h3a[bot];
	ig_h4a[client] = ig_h4a[bot];
	ig_h5a[client] = ig_h5a[bot];
	
	Format(sg_slot0a[client], 40-1, "%s", sg_slot0a[bot]);
	ig_prop0a[client] = ig_prop0a[bot];
	ig_prop1a[client] = ig_prop1a[bot];
	ig_prop2a[client] = ig_prop2a[bot];
	ig_prop3a[client] = ig_prop3a[bot];
	ig_prop4a[client] = ig_prop4a[bot];
	
	Format(sg_slot1a[client], 40-1, "%s", sg_slot1a[bot]);
	ig_prop5a[client] = ig_prop5a[bot];
	ig_prop6a[client] = ig_prop6a[bot];
	
	Format(sg_slot2a[client], 40-1, "%s", sg_slot2a[bot]);
	Format(sg_slot3a[client], 40-1, "%s", sg_slot3a[bot]);
	Format(sg_slot4a[client], 40-1, "%s", sg_slot4a[bot]);
}

/* ========================================== */

public void OnMapStart()
{
	ig_protection = 0;
	SetConVarInt(FindConVar("survivor_respawn_with_guns"), 0, false, false);

	sg_buf12[0] = '\0';
	GetCurrentMap(sg_buf12, sizeof(sg_buf12)-1);

	HxCleaningMap(sg_buf12);
}

public void OnClientDisconnect(int client)
{
	if (!IsFakeClient(client))
	{
		if (!ig_protection)
		{
			HxCleaning(client);
		}
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.2, HxTimerRS, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			ig_afk[i] = 0;
		}
		i += 1;
	}
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client)
	{
		if (!IsFakeClient(client))
		{
			int iTeam = event.GetInt("team");
			if (iTeam == 1)
			{
				if (event.GetInt("oldteam") == 2)
				{	/*	Игрок уходит в афк	*/
					ig_afk[client] = 1;
					HxSaveWeaponAfk(client);
				}
			}
			if (iTeam == 2)
			{	/*	Игрок играет	*/
				CreateTimer(1.0, HxTimerTeam2, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	ig_protection = 1;

	int i = 1;
	while (i <= MaxClients)
	{
		HxCleaning(i);
		HxCleaningSave(i);
		
		if (IsClientInGame(i))
		{
			if (IsFakeClient(i))
			{
				HxKickClient(i);
			}
			else
			{
				if (GetClientTeam(i) == 1)
				{
					ig_player[i] = 1;
					HxMapTransitionAFK(i);
				}
				if (GetClientTeam(i) == 2)
				{
					if (IsPlayerAlive(i))
					{
						ig_player[i] = 1;
						HxMapTransition(i);
					}
				}
			}
		}
		i += 1;
	}
}

stock void HxMapTransition(int client)
{
	HxGetHealth(0, client);
	HxGetSlot0(0, client);
	HxGetSlot1(0, client);
	HxGetSlot2(0, client);
	HxGetSlot3(0, client);
	HxGetSlot4(0, client);
}

stock void HxMapTransitionAFK(int client)
{
	ig_h1[client] = 100;
	Format(sg_slot0[client], 40-1, "%s", sg_slot0a[client]);
	ig_prop0[client] = ig_prop0a[client];
	ig_prop1[client] = ig_prop1a[client];
	ig_prop2[client] = ig_prop2a[client];
	ig_prop3[client] = ig_prop3a[client];
	ig_prop4[client] = ig_prop4a[client];
	
	Format(sg_slot1[client], 40-1, "%s", sg_slot1a[client]);
	ig_prop5[client] = ig_prop5a[client];
	ig_prop6[client] = ig_prop6a[client];
	
	Format(sg_slot2[client], 40-1, "%s", sg_slot2a[client]);
	Format(sg_slot3[client], 40-1, "%s", sg_slot3a[client]);
	Format(sg_slot4[client], 40-1, "%s", sg_slot4a[client]);
}

public void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast)
{
	ig_protection = 1;
	
	int i = 1;
	while (i <= MaxClients)
	{
		HxCleaning(i);
		HxCleaningSave(i);
		i += 1;
	}
}

stock void HxCleaningSave(int &client)
{
	ig_h1[client] = 0;
	
	sg_slot0[client][0] = '\0';
	ig_prop0[client] = 0;
	ig_prop1[client] = 0;
	ig_prop2[client] = 0;
	ig_prop3[client] = 0;
	ig_prop4[client] = 0;
	
	sg_slot1[client][0] = '\0';
	ig_prop5[client] = 0;
	ig_prop6[client] = 0;
	
	sg_slot2[client][0] = '\0';
	sg_slot3[client][0] = '\0';
	sg_slot4[client][0] = '\0';
}

stock void HxCleaningAfk(int &client)
{
	ig_h1a[client] = 0;
	ig_h2a[client] = 0;
	ig_h3a[client] = 0;
	ig_h4a[client] = 0;
	ig_h5a[client] = 0.0;
	
	sg_slot0a[client][0] = '\0';
	ig_prop0a[client] = 0;
	ig_prop1a[client] = 0;
	ig_prop2a[client] = 0;
	ig_prop3a[client] = 0;
	ig_prop4a[client] = 0;
	
	sg_slot1a[client][0] = '\0';
	ig_prop5a[client] = 0;
	ig_prop6a[client] = 0;
	
	sg_slot2a[client][0] = '\0';
	sg_slot3a[client][0] = '\0';
	sg_slot4a[client][0] = '\0';
}