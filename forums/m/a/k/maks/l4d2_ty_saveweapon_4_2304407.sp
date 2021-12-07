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
#pragma newdecls required

char sg_buffer0[64];
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
	author = "MAKS",
	description = "L4D2 coop save weapon",
	version = "4.12",
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

void HxCleaning(int &client)
{
	ig_prop0[client] = 50;
	ig_prop1[client] = 30;
	ig_prop2[client] = 0;
	ig_prop3[client] = 0;
	ig_prop4[client] = 0;
	ig_prop5[client] = 0;

	sg_slot0[client][0] = '\0';
	sg_slot1[client][0] = '\0';
	sg_slot2[client][0] = '\0';
	sg_slot3[client][0] = '\0';
	sg_slot4[client][0] = '\0';
	sg_defib[client][0] = '\0';
}

void HxKickC(int &client)
{
	int iSlot0;
	int iSlot2;
	int iSlot3;
	int iSlot4;

	if (GetClientTeam(client) == 2)
	{
		if (IsPlayerAlive(client))
		{
			iSlot0 = GetPlayerWeaponSlot(client, 0);
			iSlot2 = GetPlayerWeaponSlot(client, 2);
			iSlot3 = GetPlayerWeaponSlot(client, 3);
			iSlot4 = GetPlayerWeaponSlot(client, 4);

			if (iSlot0 > 0)
			{
				RemovePlayerItem(client, iSlot0);
				AcceptEntityInput(iSlot0, "Kill");
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
	}

	KickClient(client, "Mt");
}

int HxGetSlot1(int &client, int iSlot1)
{
	sg_buffer0[0] = '\0';
	GetEntPropString(iSlot1, Prop_Data, "m_ModelName", sg_buffer0, sizeof(sg_buffer0)-1);

	if (StrContains(sg_buffer0, "v_pistolA.mdl", true) != -1)
	{
		sg_slot1[client] = "pistol";
		return 1;
	}
	if (StrContains(sg_buffer0, "v_dual_pistolA.mdl", true) != -1)
	{
		sg_slot1[client] = "dual_pistol";
		return 1;
	}
	if (StrContains(sg_buffer0, "v_desert_eagle.mdl", true) != -1)
	{
		sg_slot1[client] = "pistol_magnum";
		return 1;
	}
	if (StrContains(sg_buffer0, "v_bat.mdl", true) != -1)
	{
		sg_slot1[client] = "baseball_bat";
		return 1;
	}
	if (StrContains(sg_buffer0, "v_cricket_bat.mdl", true) != -1)
	{
		sg_slot1[client] = "cricket_bat";
		return 1;
	}
	if (StrContains(sg_buffer0, "v_crowbar.mdl", true) != -1)
	{
		sg_slot1[client] = "crowbar";
		return 1;
	}
	if (StrContains(sg_buffer0, "v_fireaxe.mdl", true) != -1)
	{
		sg_slot1[client] = "fireaxe";
		return 1;
	}
	if (StrContains(sg_buffer0, "v_katana.mdl", true) != -1)
	{
		sg_slot1[client] = "katana";
		return 1;
	}
	if (StrContains(sg_buffer0, "v_golfclub.mdl", true) != -1)
	{
		sg_slot1[client] = "golfclub";
		return 1;
	}
	if (StrContains(sg_buffer0, "v_machete.mdl", true) != -1)
	{
		sg_slot1[client] = "machete";
		return 1;
	}
	if (StrContains(sg_buffer0, "v_tonfa.mdl", true) != -1)
	{
		sg_slot1[client] = "tonfa";
		return 1;
	}
	if (StrContains(sg_buffer0, "v_electric_guitar.mdl", true) != -1)
	{
		sg_slot1[client] = "electric_guitar";
		return 1;
	}
	if (StrContains(sg_buffer0, "v_frying_pan.mdl", true) != -1)
	{
		sg_slot1[client] = "frying_pan";
		return 1;
	}
	if (StrContains(sg_buffer0, "v_chainsaw.mdl", true) != -1)
	{
		ig_prop1[client] = GetEntProp(iSlot1, Prop_Send, "m_iClip1", 4);
		sg_slot1[client] = "chainsaw";
		return 1;
	}
	if (StrContains(sg_buffer0, "v_knife_t.mdl", true) != -1)
	{
		sg_slot1[client] = "knife";
		return 1;
	}
	if (StrContains(sg_buffer0, "v_pitchfork.mdl", true) != -1)
	{
		sg_slot1[client] = "pitchfork";
		return 1;
	}
	if (StrContains(sg_buffer0, "v_shovel.mdl", true) != -1)
	{
		sg_slot1[client] = "shovel";
		return 1;
	}

	GetEdictClassname(iSlot1, sg_slot1[client], 39);
	LogError("m_ModelName(%s) %s", sg_buffer0, sg_slot1[client]);
	return 0;
}

void HxSaveC(int &client)
{
	int iSlot0;
	int iSlot1;
	int iSlot2;
	int iSlot3;
	int iSlot4;

	if (GetClientTeam(client) == 2)
	{
		if (IsPlayerAlive(client))
		{
			SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);

			if (GetConVarBool(hg_health))
			{
				SetEntProp(client, Prop_Send, "m_iHealth", 100);
				SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
				SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
				SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
			}

			iSlot0 = GetPlayerWeaponSlot(client, 0);
			iSlot1 = GetPlayerWeaponSlot(client, 1);
			iSlot2 = GetPlayerWeaponSlot(client, 2);
			iSlot3 = GetPlayerWeaponSlot(client, 3);
			iSlot4 = GetPlayerWeaponSlot(client, 4);

			if (iSlot0 > 0)
			{
				GetEdictClassname(iSlot0, sg_slot0[client], 39);
				ig_prop0[client] = GetEntProp(iSlot0, Prop_Send, "m_iClip1", 4);
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
				GetEdictClassname(iSlot2, sg_slot2[client], 39);
				RemovePlayerItem(client, iSlot2);
				AcceptEntityInput(iSlot2, "Kill");
			}
			if (iSlot3 > 0)
			{
				GetEdictClassname(iSlot3, sg_slot3[client], 39);
				RemovePlayerItem(client, iSlot3);
				AcceptEntityInput(iSlot3, "Kill");
			}
			if (iSlot4 > 0)
			{
				GetEdictClassname(iSlot4, sg_slot4[client], 39);
				RemovePlayerItem(client, iSlot4);
				AcceptEntityInput(iSlot4, "Kill");
			}
		}
	}
}

void HxFakeCHEAT(int &client, const char[] sCmd, const char[] sArg)
{
	int iFlags = GetCommandFlags(sCmd);
	SetCommandFlags(sCmd, iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", sCmd, sArg);
	SetCommandFlags(sCmd, iFlags);
}

void HxGiveC(int &client)
{
	int iSlot0;
	int iSlot1;
	int iSlot2;
	int iSlot3;
	int iSlot4;

	if (IsPlayerAlive(client))
	{
		iSlot0 = GetPlayerWeaponSlot(client, 0);
		iSlot1 = GetPlayerWeaponSlot(client, 1);
		iSlot2 = GetPlayerWeaponSlot(client, 2);
		iSlot3 = GetPlayerWeaponSlot(client, 3);
		iSlot4 = GetPlayerWeaponSlot(client, 4);

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
			HxFakeCHEAT(client, "give", sg_slot0[client]);
			iSlot0 = GetPlayerWeaponSlot(client, 0);
			SetEntProp(iSlot0, Prop_Send, "m_iClip1", ig_prop0[client], 4);
			SetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", ig_prop2[client], 4);
			SetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ig_prop3[client], 4);
			SetEntProp(iSlot0, Prop_Send, "m_nSkin", ig_prop4[client], 4);
		}
		else
		{
			if (ig_time > GetTime())
			{
				HxFakeCHEAT(client, "give", "smg_silenced");
				SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1", 50, 4);
			}
		}

		if (sg_slot1[client][0] != '\0')
		{
			if (!strcmp(sg_slot1[client], "dual_pistol", true))
			{
				HxFakeCHEAT(client, "give", "pistol");
				HxFakeCHEAT(client, "give", "pistol");
			}
			else
			{
				HxFakeCHEAT(client, "give", sg_slot1[client]);
				if (!strcmp(sg_slot1[client], "chainsaw", true))
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
			HxFakeCHEAT(client, "give", "pistol");
		}

		if (sg_slot2[client][0] != '\0')
		{
			HxFakeCHEAT(client, "give", sg_slot2[client]);
		}
		if (sg_slot3[client][0] != '\0')
		{
			HxFakeCHEAT(client, "give", sg_slot3[client]);
		}
		if (sg_slot4[client][0] != '\0')
		{
			HxFakeCHEAT(client, "give", sg_slot4[client]);
		}
	}
}

public Action HxTimerConnected(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (GetClientTeam(client) == 2)
		{
			if (IsPlayerAlive(client))
			{
				HxGiveC(client);
				return Plugin_Stop;
			}
		}
		CreateTimer(2.0, HxTimerConnected, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Stop;
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
		int i = 1;
		while (i <= MaxClients)
		{
			HxCleaning(i);
			i += 1;
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		if (ig_coop)
		{
			CreateTimer(5.5, HxTimerConnected, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
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

public Action HxTimerRS(Handle timer)
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				HxGiveC(i);
			}
		}
		i += 1;
	}

	return Plugin_Stop;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (ig_coop)
	{
		ig_time = GetTime() + 45;
		CreateTimer(1.2, HxTimerRS, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void Event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
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

public Action HxTimerDefib(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (GetClientTeam(client) == 2)
		{
			if (IsPlayerAlive(client))
			{
				if (sg_defib[client][0] != '\0')
				{
					int iSlot1 = GetPlayerWeaponSlot(client, 1);
					if (iSlot1 > 0)
					{
						RemovePlayerItem(client, iSlot1);
						AcceptEntityInput(iSlot1, "Kill");
					}
					HxFakeCHEAT(client, "give", sg_defib[client]);
				}
			}
		}
	}

	return Plugin_Stop;
}

public void Event_DefibUsed(Event event, const char[] name, bool dontBroadcast)
{
	int iSubject = GetClientOfUserId(GetEventInt(event, "subject"));
	if (iSubject > 0)
	{
		if (ig_coop)
		{
			CreateTimer(1.0, HxTimerDefib, iSubject, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	int i = 1;
	ig_protection = 1;

	if (ig_coop)
	{
		while (i <= MaxClients)
		{
			HxCleaning(i);
			if (IsClientInGame(i))
			{
				if (IsFakeClient(i))
				{
					HxKickC(i);
				}
				else
				{
					HxSaveC(i);
				}
			}
			i += 1;
		}
	}
}
