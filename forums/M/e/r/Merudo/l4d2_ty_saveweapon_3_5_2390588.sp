/**
 *
 * =============================================================================
 * L4D2 coop save weapon
 * Copyright 2014 steamcommunity.com/profiles/76561198025355822/
 * Fixed 2015 steamcommunity.com/id/Electr0n
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
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
*/

#pragma semicolon 1
#include <sourcemod>
#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif
#include <sdktools>

#define TYPRECACHE 1
#define TYLOG 0

#if TYLOG
char sg_log[160];
#endif
char sg_modelName[64];
char sg_className[40];

char sg_slot0[MAXPLAYERS+1][40];
char sg_slot1[MAXPLAYERS+1][40];
char sg_slot2[MAXPLAYERS+1][40];
char sg_slot3[MAXPLAYERS+1][40];
char sg_slot4[MAXPLAYERS+1][40];

int ig_iClip1[MAXPLAYERS+1];
int ig_uBitVec[MAXPLAYERS+1];
int ig_nUPAL[MAXPLAYERS+1];

int ig_iClip1_slot1[MAXPLAYERS+1];  //  Added for chainsaw support

int ig_protection;
int ig_noob;
int ig_roundS;

ConVar hg_noob;

public Plugin myinfo =
{
	name = "l4d2_ty_saveweapon",
	author = "MAKS",
	description = "L4D2 coop save weapon",
	version = "3.5",
	url = "forums.alliedmods.net/showthread.php?p=2304407"
};

public void OnPluginStart()
{
	HookEvent("round_start",    Event_RoundStart,    EventHookMode_PostNoCopy);
	HookEvent("round_end",      Event_RoundEnd,      EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_MapTransition, EventHookMode_PostNoCopy);
	HookEvent("finale_win",     Event_FinaleWin,     EventHookMode_PostNoCopy);
	HookEvent("player_spawn",   Event_PlayerSpawn);

	hg_noob = CreateConVar("l4d2_ty_noob", "1", "", FCVAR_NONE, true, 0.0, true, 1.0);
#if TYLOG
	RegAdminCmd("sm_saveW", CMD_SaveW, ADMFLAG_CHEATS, "");
	RegAdminCmd("sm_allSaveW", CMD_AllSaveW, ADMFLAG_CHEATS, "");
	BuildPath(Path_SM, sg_log, sizeof(sg_log)-1, "logs/l4d2_ty_saveweapon.log");
#endif
}

#if TYLOG
public Action CMD_SaveW(int client, int args)
{
	if (client)
	{
		LogToFile(sg_log, "RegAdminCmd sm_saveW %N", client);

		TySaveWeapon(client);
		TyGweaponC(client);
	}
	return Plugin_Continue;
}

public Action CMD_AllSaveW(int client, int args)
{
	if (client)
	{
		LogToFile(sg_log, "RegAdminCmd sm_allSaveW %N", client);

		int i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i))
			{
				if (GetClientTeam(i) == 2)
				{
					if (IsPlayerAlive(client))
					{
						TySaveWeapon(i);
						TyGweaponC(i);
					}
				}
			}
			i += 1;
		}
	}
	return Plugin_Continue;
}
#endif

public void TyFakeCHEAT(int client, char[] sCommand, char[] sArgument)
{
	int iFlags = GetCommandFlags(sCommand);
	SetCommandFlags(sCommand, iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", sCommand, sArgument);
	SetCommandFlags(sCommand, iFlags);
}

public void TyCleanW(int client)
{
#if TYLOG
	if (IsClientInGame(client))
	{
		LogToFile(sg_log, "TyCleanW %N", client);
	}
#endif
	sg_slot0[client][0] = '\0';
	ig_iClip1[client] = 50;
	ig_uBitVec[client] = 0;
	ig_nUPAL[client] = 0;
	sg_slot1[client][0] = '\0';
	sg_slot2[client][0] = '\0';
	sg_slot3[client][0] = '\0';
	sg_slot4[client][0] = '\0';
	
	ig_iClip1_slot1[client] = 0;  //  Added for chainsaw support
}

public void OnClientDisconnect(int client)
{
	if (!IsFakeClient(client))
	{
		if (!ig_protection)
		{
		#if TYLOG
			LogToFile(sg_log, "OnClientDisconnect %N", client);
		#endif
			TyCleanW(client);
		}
	}
}

public Action TyTimerPspawn(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (IsFakeClient(client))
		{
			TyCleanW(client);
		}

		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			if (GetPlayerWeaponSlot(client, 0) > -1)
			{
				RemovePlayerItem(client, GetPlayerWeaponSlot(client, 0));
			}
			if (GetPlayerWeaponSlot(client, 1) > -1)
			{
				RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
			}
			if (GetPlayerWeaponSlot(client, 2) > -1)
			{
				RemovePlayerItem(client, GetPlayerWeaponSlot(client, 2));
			}
			if (GetPlayerWeaponSlot(client, 3) > -1)
			{
				RemovePlayerItem(client, GetPlayerWeaponSlot(client, 3));
			}
			if (GetPlayerWeaponSlot(client, 4) > -1)
			{
				RemovePlayerItem(client, GetPlayerWeaponSlot(client, 4));
			}
			TyFakeCHEAT(client, "give", "weapon_pistol");
		}
	}
	return Plugin_Stop;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client)
	{
		CreateTimer(0.3, TyTimerPspawn, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Event_FinaleWin(Event event, const char[] name, bool dontBroadcast)
{
#if TYLOG
	LogToFile(sg_log, "HookEvent finale_win");
#endif
	ig_protection = 0;
	int i = 1;

	while (i <= MaxClients)
	{
		TyCleanW(i);
		if (IsClientInGame(i))
		{
			if (IsFakeClient(i))
			{
				KickClient(i, "Fw");
			}
		}
		i += 1;
	}
}

public int TySaveWeapon(int client)
{
	if (GetClientTeam(client) != 2)
	{
		TyCleanW(client);
		return 1;
	}

	if (!IsPlayerAlive(client))
	{
		TyCleanW(client);
		sg_slot0[client] = "weapon_smg";
		return 1;
	}

	TyFakeCHEAT(client, "give", "health");
	SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
	SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
	SetEntProp(client, Prop_Send, "m_iHealth", 71);

	int iSlot0 = GetPlayerWeaponSlot(client, 0);
	int iSlot1 = GetPlayerWeaponSlot(client, 1);
	int iSlot2 = GetPlayerWeaponSlot(client, 2);
	int iSlot3 = GetPlayerWeaponSlot(client, 3);
	int iSlot4 = GetPlayerWeaponSlot(client, 4);

	if (iSlot0 > 0)
	{
		GetEdictClassname(iSlot0, sg_slot0[client], 39);
		ig_iClip1[client] = GetEntProp(iSlot0, Prop_Send, "m_iClip1", 4);
		ig_uBitVec[client] = GetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", 4);
		ig_nUPAL[client] = GetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4);
		RemovePlayerItem(client, iSlot0);
	}
	else
	{
		sg_slot0[client] = "weapon_smg";
		ig_iClip1[client] = 50;
		ig_uBitVec[client] = 0;
	}

	if (iSlot1 > 0)
	{
		sg_slot1[client][0] = '\0';
		sg_className[0] = '\0';
		sg_modelName[0] = '\0';
		GetEdictClassname(iSlot1, sg_className, sizeof(sg_className)-1);

		if (!strcmp(sg_className, "weapon_melee", true))
		{
			GetEntPropString(iSlot1, Prop_Data, "m_ModelName", sg_modelName, sizeof(sg_modelName)-1);

			if (!strcmp(sg_modelName, "models/weapons/melee/v_cricket_bat.mdl", true))
			{
				sg_slot1[client] = "cricket_bat";
			}
			if (!strcmp(sg_modelName, "models/weapons/melee/v_crowbar.mdl", true))
			{
				sg_slot1[client] = "crowbar";
			}
			if (!strcmp(sg_modelName, "models/weapons/melee/v_fireaxe.mdl", true))
			{
				sg_slot1[client] = "fireaxe";
			}
			if (!strcmp(sg_modelName, "models/weapons/melee/v_katana.mdl", true))
			{
				sg_slot1[client] = "katana";
			}
			if (!strcmp(sg_modelName, "models/weapons/melee/v_bat.mdl", true))
			{
				sg_slot1[client] = "baseball_bat";
			}
			if (!strcmp(sg_modelName, "models/weapons/melee/v_golfclub.mdl", true))
			{
				sg_slot1[client] = "golfclub";
			}
			if (!strcmp(sg_modelName, "models/weapons/melee/v_machete.mdl", true))
			{
				sg_slot1[client] = "machete";
			}
			if (!strcmp(sg_modelName, "models/weapons/melee/v_tonfa.mdl", true))
			{
				sg_slot1[client] = "tonfa";
			}
			if (!strcmp(sg_modelName, "models/weapons/melee/v_electric_guitar.mdl", true))
			{
				sg_slot1[client] = "electric_guitar";
			}
			if (!strcmp(sg_modelName, "models/weapons/melee/v_frying_pan.mdl", true))
			{
				sg_slot1[client] = "frying_pan";
			}
			if (!strcmp(sg_modelName, "models/v_models/v_knife_t.mdl", true))
			{
				sg_slot1[client] = "knife";
			}

			if (sg_slot1[client][0] == '\0')
			{
			#if TYLOG
				LogToFile(sg_log, "m_ModelName(%s)", sg_modelName);
			#endif
				LogError("m_ModelName(%s)", sg_modelName);
				LogError("___________");
			}
		}
		else
		{
			ig_iClip1_slot1[client] = GetEntProp(iSlot1, Prop_Send, "m_iClip1", 4);     // Save the clip of slot1 weapon. Added for chainsaw support
		
			if (!strcmp(sg_className, "weapon_pistol", true))
			{
				GetEntPropString(iSlot1, Prop_Data, "m_ModelName", sg_modelName, sizeof(sg_modelName)-1);

				if (!strcmp(sg_modelName, "models/v_models/v_dual_pistolA.mdl", true))
				{
					sg_slot1[client] = "dual_pistol";
				}
			}
			else
			{
				GetEdictClassname(iSlot1, sg_slot1[client], 39);
			}
		}

		RemovePlayerItem(client, iSlot1);
	}

	if (iSlot2 > 0)
	{
		GetEdictClassname(iSlot2, sg_slot2[client], 39);
		RemovePlayerItem(client, iSlot2);
	}
	else
	{
		sg_slot2[client][0] = '\0';
	}

	if (iSlot3 > 0)
	{
		GetEdictClassname(iSlot3, sg_slot3[client], 39);
		RemovePlayerItem(client, iSlot3);
	}
	else
	{
		sg_slot3[client][0] = '\0';
	}

	if (iSlot4 > 0)
	{
		GetEdictClassname(iSlot4, sg_slot4[client], 39);
		RemovePlayerItem(client, iSlot4);
	}
	else
	{
		sg_slot4[client][0] = '\0';
	}
#if TYLOG
	LogToFile(sg_log, "[%N]", client);
	LogToFile(sg_log, "sg_slot0 	 %s", sg_slot0[client]);

	LogToFile(sg_log, "m_iClip1                     %d", ig_iClip1[client]);
	LogToFile(sg_log, "m_upgradeBitVec              %d", ig_uBitVec[client]);
	LogToFile(sg_log, "m_nUpgradedPrimaryAmmoLoaded %d", ig_nUPAL[client]);

	LogToFile(sg_log, "sg_slot1 	 %s", sg_slot1[client]);
	LogToFile(sg_log, "sg_slot2 	 %s", sg_slot2[client]);
	LogToFile(sg_log, "sg_slot3 	 %s", sg_slot3[client]);
	LogToFile(sg_log, "sg_slot4 	 %s", sg_slot4[client]);
	LogToFile(sg_log, "___________");
#endif
	return 0;
}

public Action Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
#if TYLOG
	LogToFile(sg_log, "HookEvent map_transition");
#endif
	ig_protection = 1;
	int i = 1;

	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (IsFakeClient(i))
			{
				if (IsPlayerAlive(i) && GetClientTeam(i) == 2)
				{
					if (GetPlayerWeaponSlot(i, 0) > -1)
					{
						RemovePlayerItem(i, GetPlayerWeaponSlot(i, 0));
					}
					if (GetPlayerWeaponSlot(i, 1) > -1)
					{
						RemovePlayerItem(i, GetPlayerWeaponSlot(i, 1));
					}
					if (GetPlayerWeaponSlot(i, 2) > -1)
					{
						RemovePlayerItem(i, GetPlayerWeaponSlot(i, 2));
					}
					if (GetPlayerWeaponSlot(i, 3) > -1)
					{
						RemovePlayerItem(i, GetPlayerWeaponSlot(i, 3));
					}
					if (GetPlayerWeaponSlot(i, 4) > -1)
					{
						RemovePlayerItem(i, GetPlayerWeaponSlot(i, 4));
					}
				}
				TyCleanW(i);
				KickClient(i, "Mt");
			}
			else
			{
				TySaveWeapon(i);
			}
		}
		i += 1;
	}
#if TYLOG
	LogToFile(sg_log, "HookEvent map_transition end");
#endif
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
#if TYLOG
	LogToFile(sg_log, "HookEvent round_end");
#endif
	ig_protection = 1;
	return Plugin_Continue;
}

public int TyGweaponC(int client)
{
	if (IsPlayerAlive(client))
	{
	#if TYLOG
		LogToFile(sg_log, "TyGweaponC %N", client);
	#endif
		int iSlot0 = GetPlayerWeaponSlot(client, 0);
		int iSlot1 = GetPlayerWeaponSlot(client, 1);
		int iSlot2 = GetPlayerWeaponSlot(client, 2);
		int iSlot3 = GetPlayerWeaponSlot(client, 3);
		int iSlot4 = GetPlayerWeaponSlot(client, 4);

		if (iSlot0 > 0)
		{
			RemovePlayerItem(client, iSlot0);
		}
		if (iSlot1 > 0)
		{
			RemovePlayerItem(client, iSlot1);
		}
		if (iSlot2 > 0)
		{
			RemovePlayerItem(client, iSlot2);
		}
		if (iSlot3 > 0)
		{
			RemovePlayerItem(client, iSlot3);
		}
		if (iSlot4 > 0)
		{
			RemovePlayerItem(client, iSlot4);
		}

		if (IsFakeClient(client))
		{
			TyFakeCHEAT(client, "give", "weapon_pistol");
			return 1;
		}

		if (sg_slot0[client][0] != '\0')
		{
			TyFakeCHEAT(client, "give", sg_slot0[client]);
			iSlot0 = GetPlayerWeaponSlot(client, 0);
			SetEntProp(iSlot0, Prop_Send, "m_iClip1", ig_iClip1[client], 4);
			SetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", ig_uBitVec[client], 4);
			SetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ig_nUPAL[client], 4);
		}
		else
		{
			if ((ig_noob > 0) && ig_roundS)
			{
				TyFakeCHEAT(client, "give", "weapon_smg_silenced");
				SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1", 50, 4);
			}
		}

		if (sg_slot1[client][0] != '\0')
		{
			if (!strcmp(sg_slot1[client], "dual_pistol", true))
			{
				TyFakeCHEAT(client, "give", "weapon_pistol");
				TyFakeCHEAT(client, "give", "weapon_pistol");
			}
			else
			{
				TyFakeCHEAT(client, "give", sg_slot1[client]);
				
				//------------ Added for chainsaw support  --------
				iSlot1 = GetPlayerWeaponSlot(client, 1);
				GetEdictClassname(iSlot1, sg_className, sizeof(sg_className));
				if (StrEqual(sg_className, "weapon_chainsaw"))
				{
					SetEntProp(iSlot1, Prop_Send, "m_iClip1", ig_iClip1_slot1[client], 4);					
				}
				//--------------------------------------------------
			}
		}
		else
		{
			TyFakeCHEAT(client, "give", "weapon_pistol");
		}

		if (sg_slot2[client][0] != '\0')
		{
			TyFakeCHEAT(client, "give", sg_slot2[client]);
		}

		if (sg_slot3[client][0] != '\0')
		{
			TyFakeCHEAT(client, "give", sg_slot3[client]);
		}

		if (sg_slot4[client][0] != '\0')
		{
			TyFakeCHEAT(client, "give", sg_slot4[client]);
		}
	}
	return 0;
}

public Action TyTimerConnected(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (GetClientTeam(client) == 2)
		{
			TyGweaponC(client);
			return Plugin_Stop;
		}

		CreateTimer(1.0, TyTimerConnected, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Stop;
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
	#if TYLOG
		LogToFile(sg_log, "OnClientPostAdminCheck %N", client);
	#endif
		CreateTimer(4.0, TyTimerConnected, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void TyWhileClientW()
{
#if TYLOG
	LogToFile(sg_log, "TyWhileClientW");
#endif
	ig_roundS = 1;
	ig_noob = GetConVarInt(hg_noob);
	int i = 1;

	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				TyGweaponC(i);
			}
		}
		i += 1;
	}

	ig_protection = 0;
}

public Action TyTimerGWeapon(Handle timer, any client)
{
	TyWhileClientW();
	return Plugin_Stop;
}

public void TyPrecache()
{
#if TYLOG
	LogToFile(sg_log, "Precache models");
#endif
#if TYPRECACHE
	if (!IsModelPrecached("models/survivors/survivor_producer.mdl"))
	{
		PrecacheModel("models/survivors/survivor_producer.mdl", false);
	}

	if (!IsModelPrecached("models/survivors/survivor_coach.mdl"))
	{
		PrecacheModel("models/survivors/survivor_coach.mdl", false);
	}

	if (!IsModelPrecached("models/survivors/survivor_gambler.mdl"))
	{
		PrecacheModel("models/survivors/survivor_gambler.mdl", false);
	}

	if (!IsModelPrecached("models/survivors/survivor_manager.mdl"))
	{
		PrecacheModel("models/survivors/survivor_manager.mdl", false);
	}

	if (!IsModelPrecached("models/survivors/survivor_mechanic.mdl"))
	{
		PrecacheModel("models/survivors/survivor_mechanic.mdl", false);
	}

	if (!IsModelPrecached("models/survivors/survivor_teenangst.mdl"))
	{
		PrecacheModel("models/survivors/survivor_teenangst.mdl", false);
	}

	if (!IsModelPrecached("models/survivors/survivor_biker.mdl"))
	{
		PrecacheModel("models/survivors/survivor_biker.mdl", false);
	}

	if (!IsModelPrecached("models/infected/witch.mdl"))
	{
		PrecacheModel("models/infected/witch.mdl", false);
	}

	if (!IsModelPrecached("models/infected/witch_bride.mdl"))
	{
		PrecacheModel("models/infected/witch_bride.mdl", false);
	}

	if (!IsModelPrecached("models/weapons/melee/w_cricket_bat.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_cricket_bat.mdl", false);
	}

	if (!IsModelPrecached("models/weapons/melee/w_crowbar.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_crowbar.mdl", false);
	}

	if (!IsModelPrecached("models/weapons/melee/w_electric_guitar.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_electric_guitar.mdl", false);
	}

	if (!IsModelPrecached("models/weapons/melee/w_katana.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_katana.mdl", false);
	}

	if (!IsModelPrecached("models/weapons/melee/w_machete.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_machete.mdl", false);
	}

	if (!IsModelPrecached("models/weapons/melee/w_tonfa.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_tonfa.mdl", false);
	}

	if (!IsModelPrecached("models/weapons/melee/w_frying_pan.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_frying_pan.mdl", false);
	}

	if (!IsModelPrecached("models/w_models/weapons/w_knife_t.mdl"))
	{
		PrecacheModel("models/w_models/weapons/w_knife_t.mdl", false);
	}

	if (!IsModelPrecached("models/weapons/melee/w_golfclub.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_golfclub.mdl", false);
	}

	if (!IsModelPrecached("models/w_models/weapons/w_smg_mp5.mdl"))
	{
		PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl", false);
	}

	if (!IsModelPrecached("models/w_models/weapons/w_sniper_scout.mdl"))
	{
		PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl", false);
	}

	if (!IsModelPrecached("models/w_models/weapons/w_sniper_awp.mdl"))
	{
		PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl", false);
	}

	if (!IsModelPrecached("models/v_models/v_snip_awp.mdl"))
	{
		PrecacheModel("models/v_models/v_snip_awp.mdl", false);
	}

	if (!IsModelPrecached("models/v_models/v_snip_scout.mdl"))
	{
		PrecacheModel("models/v_models/v_snip_scout.mdl", false);
	}

	if (!IsModelPrecached("models/w_models/weapons/w_rifle_sg552.mdl"))
	{
		PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl", false);
	}

	if (!IsModelPrecached("models/v_models/v_rif_sg552.mdl"))
	{
		PrecacheModel("models/v_models/v_rif_sg552.mdl", false);
	}

	if (!IsModelPrecached("models/v_models/v_smg_mp5.mdl"))
	{
		PrecacheModel("models/v_models/v_smg_mp5.mdl", false);
	}

	if (!IsModelPrecached("models/w_models/weapons/50cal.mdl"))
	{
		PrecacheModel("models/w_models/weapons/50cal.mdl", false);
	}

	if (!IsModelPrecached("models/weapons/melee/v_fireaxe.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_fireaxe.mdl", false);
	}

	if (!IsModelPrecached("models/weapons/melee/v_frying_pan.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_frying_pan.mdl", false);
	}

	if (!IsModelPrecached("models/weapons/melee/v_machete.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_machete.mdl", false);
	}

	if (!IsModelPrecached("models/weapons/melee/v_golfclub.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_golfclub.mdl", false);
	}
#endif
	CreateTimer(1.1, TyTimerGWeapon, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TyTimerRS(Handle timer, any client)
{
	TyPrecache();
	return Plugin_Stop;
}

public Action TyTimerRoundS(Handle timer, any client)
{
	ig_roundS = 0;
	return Plugin_Stop;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
#if TYLOG
	LogToFile(sg_log, "HookEvent round_start");
#endif
	CreateTimer(0.1, TyTimerRS, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(40.0, TyTimerRoundS, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

