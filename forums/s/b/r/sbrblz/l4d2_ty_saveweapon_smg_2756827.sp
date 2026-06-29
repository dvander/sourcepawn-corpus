/**
 * =============================================================================
 * L4D2 coop save weapon
 * Copyright 2011 - 2020 steamcommunity.com/profiles/76561198025355822/
 * Fixed 2015 steamcommunity.com/id/Electr0n
 * Fixed 2016 steamcommunity.com/id/mixjayrus
 * Fixed 2016 user Merudo
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
//#include <sdkhooks>
#pragma newdecls required

char sg_buffer1[40];
char sg_buffer2[32];
char sg_buffer3[24];

char sg_slot0[MAXPLAYERS+1][40];
int ig_prop0[MAXPLAYERS+1]; /* m_iClip1 slot 0 */
int ig_prop1[MAXPLAYERS+1]; /* m_iClip1 slot 1 */
int ig_prop2[MAXPLAYERS+1]; /* m_upgradeBitVec slot 0 */
int ig_prop3[MAXPLAYERS+1]; /* m_nUpgradedPrimaryAmmoLoaded slot 0 */
int ig_prop4[MAXPLAYERS+1]; /* m_nSkin slot 0 */
int ig_prop5[MAXPLAYERS+1]; /* m_nSkin slot 1 */
int ig_prop6[MAXPLAYERS+1]; /* m_iAmmo slot 0 */

char sg_slot1[MAXPLAYERS+1][40];
char sg_slot2[MAXPLAYERS+1][40];
char sg_slot3[MAXPLAYERS+1][40];
char sg_slot4[MAXPLAYERS+1][40];

char sg_defib[MAXPLAYERS+1][40];

int ig_coop;
int ig_time;
int ig_protection;
ConVar hg_health;

public Plugin myinfo =
{
	name = "[L4D2] Save Weapon",
	author = "MAKS, Shadowysn",
	description = "L4D2 coop save weapon",
	version = "4.12 Shadowysn",
	url = "forums.alliedmods.net/showthread.php?p=2304407"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("item_pickup", Event_ItemPickup);
	HookEvent("defibrillator_used", Event_DefibUsed);
	HookEvent("map_transition", Event_MapTransition, EventHookMode_PostNoCopy);

	hg_health = CreateConVar("l4d2_hx_health", "1", "", FCVAR_NONE, true, 0.0, true, 1.0);
}

void HxPrecache()
{
	/* survivors */
	if (!IsModelPrecached("models/survivors/survivor_teenangst.mdl"))
	{
		PrecacheModel("models/survivors/survivor_teenangst.mdl", false);
	}
	if (!IsModelPrecached("models/survivors/survivor_manager.mdl"))
	{
		PrecacheModel("models/survivors/survivor_manager.mdl", false);
	}
	if (!IsModelPrecached("models/survivors/survivor_namvet.mdl"))
	{
		PrecacheModel("models/survivors/survivor_namvet.mdl", false);
	}
	if (!IsModelPrecached("models/survivors/survivor_biker.mdl"))
	{
		PrecacheModel("models/survivors/survivor_biker.mdl", false);
	}
	if (!IsModelPrecached("models/survivors/survivor_mechanic.mdl"))
	{
		PrecacheModel("models/survivors/survivor_mechanic.mdl", false);
	}
	if (!IsModelPrecached("models/survivors/survivor_producer.mdl"))
	{
		PrecacheModel("models/survivors/survivor_producer.mdl", false);
	}
	if (!IsModelPrecached("models/survivors/survivor_gambler.mdl"))
	{
		PrecacheModel("models/survivors/survivor_gambler.mdl", false);
	}
	if (!IsModelPrecached("models/survivors/survivor_coach.mdl"))
	{
		PrecacheModel("models/survivors/survivor_coach.mdl", false);
	}
	/* witch */
	if (!IsModelPrecached("models/infected/witch_bride.mdl"))
	{
		PrecacheModel("models/infected/witch_bride.mdl", false);
	}
	if (!IsModelPrecached("models/infected/witch.mdl"))
	{
		PrecacheModel("models/infected/witch.mdl", false);
	}
	/* melee w*/
	if (!IsModelPrecached("models/weapons/melee/w_electric_guitar.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_electric_guitar.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_cricket_bat.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_cricket_bat.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_frying_pan.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_frying_pan.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_riotshield.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_riotshield.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_pitchfork.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_pitchfork.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_golfclub.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_golfclub.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_crowbar.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_crowbar.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_machete.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_machete.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_katana.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_katana.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_shovel.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_shovel.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_tonfa.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_tonfa.mdl", false);
	}
	/* melee v*/
	if (!IsModelPrecached("models/weapons/melee/v_electric_guitar.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_electric_guitar.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/v_cricket_bat.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_cricket_bat.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/v_frying_pan.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_frying_pan.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/v_golfclub.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_golfclub.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/v_fireaxe.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_fireaxe.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/v_crowbar.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_crowbar.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/v_machete.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_machete.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/v_katana.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_katana.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/v_shovel.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_shovel.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/v_tonfa.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_tonfa.mdl", false);
	}
	/* w models */
	if (!IsModelPrecached("models/w_models/weapons/w_knife_t.mdl"))
	{
		PrecacheModel("models/w_models/weapons/w_knife_t.mdl", false);
	}
	if (!IsModelPrecached("models/w_models/weapons/50cal.mdl"))
	{
		PrecacheModel("models/w_models/weapons/50cal.mdl", false);
	}
	/* v models */
	if (!IsModelPrecached("models/v_models/v_knife_t.mdl"))
	{
		PrecacheModel("models/v_models/v_knife_t.mdl", false);
	}
}

int HxGameMode()
{
	GetConVarString(FindConVar("mp_gamemode"), sg_buffer3, sizeof(sg_buffer3)-1);
	if (!strcmp(sg_buffer3, "coop", true))
	{
		return 1;
	}
	if (!strcmp(sg_buffer3, "realism", true))
	{
		return 2;
	}

	return 0;
}

void HxCleaning(int client)
{
	ig_prop0[client] = 50;
	ig_prop1[client] = 30;
	ig_prop2[client] = 0;
	ig_prop3[client] = 0;
	ig_prop4[client] = 0;
	ig_prop5[client] = 0;
	ig_prop6[client] = 0;

	sg_slot0[client][0] = '\0';
	sg_slot1[client][0] = '\0';
	sg_slot2[client][0] = '\0';
	sg_slot3[client][0] = '\0';
	sg_slot4[client][0] = '\0';
	sg_defib[client][0] = '\0';
}

void HxKickC(int client)
{
	if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		int iSlot0 = GetPlayerWeaponSlot(client, 0);
		int iSlot2 = GetPlayerWeaponSlot(client, 2);
		int iSlot3 = GetPlayerWeaponSlot(client, 3);
		int iSlot4 = GetPlayerWeaponSlot(client, 4);
	
		if (RealValidEntity(iSlot0))
		{
			RemovePlayerItem(client, iSlot0);
			AcceptEntityInput(iSlot0, "Kill");
		}
		if (RealValidEntity(iSlot2))
		{
			RemovePlayerItem(client, iSlot2);
			AcceptEntityInput(iSlot2, "Kill");
		}
		if (RealValidEntity(iSlot3))
		{
			RemovePlayerItem(client, iSlot3);
			AcceptEntityInput(iSlot3, "Kill");
		}
		if (RealValidEntity(iSlot4))
		{
			RemovePlayerItem(client, iSlot4);
			AcceptEntityInput(iSlot4, "Kill");
		}
	}
	
	KickClient(client, "Mt");
}

void HxGetSlot1(int client, int iSlot1)
{
	char wep_name[64];
	if (HasEntProp(iSlot1, Prop_Data, "m_strMapSetScriptName"))
	{
		GetEntPropString(iSlot1, Prop_Data, "m_strMapSetScriptName", wep_name, sizeof(wep_name));
	}
	else
	{
		if (HasEntProp(iSlot1, Prop_Send, "m_isDualWielding") && 
		GetEntProp(iSlot1, Prop_Send, "m_isDualWielding") > 0)
		{
			strcopy(wep_name, sizeof(wep_name), "dual_pistol");
			ig_prop1[client] = GetEntProp(iSlot1, Prop_Send, "m_iClip1");
		}
		else
		{
			GetEntityClassname(iSlot1, wep_name, sizeof(wep_name));
		}
		if (StrContains(wep_name, "chainsaw", false) >= 0)
		{
			ig_prop1[client] = GetEntProp(iSlot1, Prop_Send, "m_iClip1");
		}
	}
	
	bool isValid = (wep_name[0] != '\0');
	
	if (isValid)
	{
		strcopy(sg_slot1[client], 40, wep_name);
	}
	
	return;
}

void HxSaveC(int client)
{
	if (GetClientTeam(client) != 2 || !IsPlayerAlive(client)) return;
	
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);

	if (GetConVarBool(hg_health))
	{
		SetEntProp(client, Prop_Send, "m_iHealth", 100);
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
		SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
	}

	int iSlot0 = GetPlayerWeaponSlot(client, 0);
	int iSlot1 = GetPlayerWeaponSlot(client, 1);
	int iSlot2 = GetPlayerWeaponSlot(client, 2);
	int iSlot3 = GetPlayerWeaponSlot(client, 3);
	int iSlot4 = GetPlayerWeaponSlot(client, 4);

	if (iSlot0 > 0)
	{
		GetEntityClassname(iSlot0, sg_slot0[client], 39);
		ig_prop0[client] = GetEntProp(iSlot0, Prop_Send, "m_iClip1", 4);
		ig_prop6[client] = GetClientAmmo(client, iSlot0);
		ig_prop2[client] = GetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", 4);
		ig_prop3[client] = GetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4);
		ig_prop4[client] = GetEntProp(iSlot0, Prop_Send, "m_nSkin", 4);
		RemovePlayerItem(client, iSlot0);
		AcceptEntityInput(iSlot0, "Kill");
	}
	if (iSlot1 > 0)
	{
		HxGetSlot1(client, iSlot1);
		ig_prop5[client] = GetEntProp(iSlot1, Prop_Send, "m_nSkin", 4);
	}
	if (iSlot2 > 0)
	{
		GetEntityClassname(iSlot2, sg_slot2[client], 39);
		RemovePlayerItem(client, iSlot2);
		AcceptEntityInput(iSlot2, "Kill");
	}
	if (iSlot3 > 0)
	{
		GetEntityClassname(iSlot3, sg_slot3[client], 39);
		RemovePlayerItem(client, iSlot3);
		AcceptEntityInput(iSlot3, "Kill");
	}
	if (iSlot4 > 0)
	{
		GetEntityClassname(iSlot4, sg_slot4[client], 39);
		RemovePlayerItem(client, iSlot4);
		AcceptEntityInput(iSlot4, "Kill");
	}
}

/*void HxFakeCHEAT(int client, const char[] sCmd, const char[] sArg)
{
	int iFlags = GetCommandFlags(sCmd);
	SetCommandFlags(sCmd, iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", sCmd, sArg);
	SetCommandFlags(sCmd, iFlags);
}*/

int GetClientAmmo(int client, int weapon)
{
	if (!HasEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType") || !HasEntProp(client, Prop_Send, "m_iAmmo")) return 0;
	
	int ammo_Type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammo_Type <= 0) return 0;
	int m_iAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammo_Type);
	
	return m_iAmmo > 0 ? m_iAmmo : 0;
}

void SetClientAmmo(int client, int weapon, int count)
{
	if (!HasEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType") || !HasEntProp(client, Prop_Send, "m_iAmmo")) return;
	
	int ammo_Type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammo_Type <= 0) return;
	
	SetEntProp(client, Prop_Send, "m_iAmmo", count, _, ammo_Type);
}

void HxGiveC(int client)
{
	if (!IsPlayerAlive(client)) return;
	
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

	if (sg_slot0[client][0] != '\0')
	{
		GiveWep(client, sg_slot0[client]);
		iSlot0 = GetPlayerWeaponSlot(client, 0);
		SetEntProp(iSlot0, Prop_Send, "m_iClip1", ig_prop0[client], 4);
		SetClientAmmo(client, iSlot0, ig_prop6[client]);
		SetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", ig_prop2[client], 4);
		SetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ig_prop3[client], 4);
		SetEntProp(iSlot0, Prop_Send, "m_nSkin", ig_prop4[client], 4);
	}
/	else
	{
		if (ig_time > GetTime())
		{
			GiveWep(client, "smg");
			SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1", 50, 4);
		}
	}

	if (sg_slot1[client][0] != '\0')
	{
		if (!strcmp(sg_slot1[client], "dual_pistol", false))
		{
			GiveWep(client, "pistol");
			GiveWep(client, "pistol");
		}
		else
		{
			GiveWep(client, sg_slot1[client]);
			if (StrContains(sg_slot1[client], "chainsaw", false) >= 0)
			{
				iSlot1 = GetPlayerWeaponSlot(client, 1);
				SetEntProp(iSlot1, Prop_Send, "m_iClip1", ig_prop1[client], 4);
			}

			if (ig_prop5[client] > 0)
			{
				iSlot1 = GetPlayerWeaponSlot(client, 1);
				SetEntProp(iSlot1, Prop_Send, "m_nSkin", ig_prop5[client], 4);
			}
		}
	}
	else
	{
		GiveWep(client, "pistol");
	}

	if (sg_slot2[client][0] != '\0')
	{
		GiveWep(client, sg_slot2[client]);
	}
	if (sg_slot3[client][0] != '\0')
	{
		GiveWep(client, sg_slot3[client]);
	}
	if (sg_slot4[client][0] != '\0')
	{
		//PrintToChatAll("sg_slot4: %s", sg_slot4[client]);
		GiveWep(client, sg_slot4[client]);
	}
}

Action HxTimerConnected(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		if (GetClientTeam(client) == 2)
		{
			if (IsPlayerAlive(client))
			{
				HxGiveC(client);
				return;
			}
		}
		CreateTimer(2.0, HxTimerConnected, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnMapStart()
{
	HxPrecache();
	ig_coop = HxGameMode();
	if (ig_coop)
	{
		SetConVarInt(FindConVar("survivor_respawn_with_guns"), 0, false, false);
	}

	ig_protection = 0;
	GetCurrentMap(sg_buffer2, sizeof(sg_buffer2)-1);
	if (StrContains(sg_buffer2, "m1_", true) > 1)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			HxCleaning(i);
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client) || !ig_coop) return;
	
	CreateTimer(5.5, HxTimerConnected, client, TIMER_FLAG_NO_MAPCHANGE);
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

Action HxTimerRS(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || GetClientTeam(i) != 2) continue;
		HxGiveC(i);
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!ig_coop) return;
	
	ig_time = GetTime() + 45;
	CreateTimer(1.2, HxTimerRS, _, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{
	int iUserid = GetClientOfUserId(GetEventInt(event, "userid"));
	if (iUserid > 0)
	{
		if (!IsFakeClient(iUserid))
		{
			GetEventString(event, "item", sg_buffer1, sizeof(sg_buffer1)-1);
			if (!strcmp(sg_buffer1, "pistol_magnum", true))
			{
				sg_defib[iUserid] = "pistol_magnum";
			}
			if (!strcmp(sg_buffer1, "chainsaw", true))
			{
				sg_defib[iUserid] = "chainsaw";
			}
			if (!strcmp(sg_buffer1, "melee", true))
			{
				int iSlot1 = GetPlayerWeaponSlot(iUserid, 1);
				if (iSlot1 > 0)
				{
					GetEntPropString(iSlot1, Prop_Data, "m_strMapSetScriptName", sg_defib[iUserid], 39);
				}
			}
		}
	}
}

Action HxTimerDefib(Handle timer, int client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && 
	sg_defib[client][0] != '\0')
	{
		int iSlot1 = GetPlayerWeaponSlot(client, 1);
		if (iSlot1 > 0)
		{
			RemovePlayerItem(client, iSlot1);
			AcceptEntityInput(iSlot1, "Kill");
		}
		GiveWep(client, sg_defib[client]);
	}
}

void Event_DefibUsed(Event event, const char[] name, bool dontBroadcast)
{
	int iSubject = GetClientOfUserId(GetEventInt(event, "subject"));
	if (!IsValidClient(iSubject) || !ig_coop) return;
	
	CreateTimer(1.0, HxTimerDefib, iSubject, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	ig_protection = 1;

	if (!ig_coop) return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		HxCleaning(i);
		if (!IsValidClient(i)) continue;
		
		if (IsFakeClient(i))
		{
			HxKickC(i);
		}
		else
		{
			HxSaveC(i);
		}
	}
}

/*void GiveWep(int client, const char[] wep)
{
	Logic_RunScript("GetPlayerFromUserID(%d).GiveItem(\"%s\")", GetClientUserId(client), wep);
}*/

int GiveWep(int client, const char[] wep, bool quick = true)
{
	char wep_str[128];
	strcopy(wep_str, sizeof(wep_str), wep);
	if (StrContains(wep_str, "weapon_", false) < 0)
	{
		Format(wep_str, sizeof(wep_str), "weapon_%s", wep_str);
	}
	if (StrContains(wep_str, "_spawn", false) < 0)
	{
		Format(wep_str, sizeof(wep_str), "%s_spawn", wep_str);
	}
	
	int new_wep = CreateEntityByName(wep_str);
	if (!RealValidEntity(new_wep))
	{
		// If invalid, the string may be for a melee weapon.
		new_wep = CreateEntityByName("weapon_melee_spawn");
		
		SetEntPropString(new_wep, Prop_Data, "m_iszMeleeWeapon", wep);
	}
	DispatchKeyValue(new_wep, "spawnflags", "2");
	DispatchKeyValue(new_wep, "count", "1");
	
	SetVariantString("OnUser1 !self:Kill::0.02:1");
	AcceptEntityInput(new_wep, "AddOutput");
	AcceptEntityInput(new_wep, "FireUser1");
	
	float pos[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
	TeleportEntity(new_wep, pos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchSpawn(new_wep);
	ActivateEntity(new_wep);
	
	if (!quick)
	{
		DataPack data = CreateDataPack();
		data.WriteCell(client);
		data.WriteCell(new_wep);
		RequestFrame(NewWep_RequestFrame, data);
	}
	else
	{ AcceptEntityInput(new_wep, "Use", client, new_wep); }
	
	return new_wep;
}
void NewWep_RequestFrame(DataPack data)
{
	data.Reset();
	int client = data.ReadCell();
	int new_wep = data.ReadCell();
	if (data != null)
	{ CloseHandle(data); }
	
	if (!IsValidClient(client) || !RealValidEntity(new_wep)) return;
	
	AcceptEntityInput(new_wep, "Use", client, new_wep);
	AcceptEntityInput(new_wep, "Kill");
}

bool RealValidEntity(int entity)
{
	if (entity <= 0 || !IsValidEntity(entity)) return false;
	return true;
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}
