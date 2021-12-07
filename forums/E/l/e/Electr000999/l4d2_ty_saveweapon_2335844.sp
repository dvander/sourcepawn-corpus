/**
 *
 * =============================================================================
 * L4D2 coop save weapon
 * Copyright 2015 steamcommunity.com/profiles/76561198025355822 && steamcommunity.com/id/Electr0n
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

#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

#define TYLOG 0
enum WEAP
{
	iClip = 0,
	iAmmo,
	iUpgrade,
	iUpAmmo,
};

char 	g_sWeapDB[MAXPLAYERS+1][5][56], sg_modelName[128], sg_className[56];
int 	g_iWeaponInfo[MAXPLAYERS+1][4], g_iAmmoOffset, g_iSurvMaxIncapCount, g_iAmmo_smg_max, g_iNoob, 
		g_iClearAfterCampaign, g_iRoundStart, g_iMapStart, g_Loaded, g_Loaded_REnd, g_iCountRoundEnds, g_iRemoveWeaponAfterSave;
ConVar 	g_hNoob, g_hClearAfterCampaign, g_hRemoveWeaponAfterSave, g_hSurvMaxIncapCount, g_hAmmo_smg_max;
Handle	g_fwdOnWeaponsGivedByTySaver, g_fwdOnWeaponsPreSaveByTySaver;

public Plugin myinfo =
{
	name = "[L4D2] Save Weapon",
	author = "MAKS, Electr0",
	description = "L4D2 coop save weapon",
	version = "3.5",
	url = "forum.allianc-e.ru"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_fwdOnWeaponsGivedByTySaver = CreateGlobalForward("OnWeaponsGivedByTySaver", ET_Ignore, Param_Cell);	
	g_fwdOnWeaponsPreSaveByTySaver = CreateGlobalForward("OnWeaponsPreSaveByTySaver", ET_Ignore, Param_Cell);	
	
	return APLRes_Success;
}

public void OnPluginStart()
{	
	HookEvent("round_start",				Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("round_end",					Event_RoundEnd,		EventHookMode_PostNoCopy);
	
	HookEvent("map_transition", 			Event_MapTransition);
	HookEvent("finale_win", 				Event_FinaleWin);
	HookEvent("player_disconnect", 			Event_Player_Disconnect, EventHookMode_Post);

	g_hNoob 								= CreateConVar("l4d2_ty_noob",						"1");
	g_hClearAfterCampaign 					= CreateConVar("l4d2_ty_clear_after_campaign", 		"0");
	g_hRemoveWeaponAfterSave 	 			= CreateConVar("l4d2_ty_remove_weapon_after_save", 	"1");
	
	#if TYLOG
	RegAdminCmd("sm_save_weap", 			CMD_SaveWeap, 		ADMFLAG_CHEATS, "");
	RegAdminCmd("sm_save_weap_all", 		CMD_SaveWeapAll, 	ADMFLAG_CHEATS, "");
	#endif

	g_iAmmoOffset 							= FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	g_hSurvMaxIncapCount 					= FindConVar("survivor_max_incapacitated_count");
	g_hAmmo_smg_max		 					= FindConVar("ammo_smg_max");
	
	AutoExecConfig(true, "l4d2_ty_saveweapon");
	
	HookConVarChange(g_hSurvMaxIncapCount, 		OnCVarChange);
	HookConVarChange(g_hRemoveWeaponAfterSave, 	OnCVarChange);
	HookConVarChange(g_hAmmo_smg_max, 			OnCVarChange);
	HookConVarChange(g_hNoob, 					OnCVarChange);
	HookConVarChange(g_hClearAfterCampaign, 	OnCVarChange);
	
	GetCVars();
}

public void OnConfigsExecuted()
{
	GetCVars();
}

public void OnCVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCVars();
}

void GetCVars()
{
	g_iSurvMaxIncapCount 	= g_hSurvMaxIncapCount.IntValue;
	g_iAmmo_smg_max 		= g_hAmmo_smg_max.IntValue;
	g_iNoob 				= g_hNoob.IntValue;
	g_iClearAfterCampaign	= g_hClearAfterCampaign.IntValue;
	g_iRemoveWeaponAfterSave= g_hRemoveWeaponAfterSave.IntValue;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_Loaded_REnd == 1 && g_iRoundStart == 0 && g_Loaded == 0)
	{		
		g_Loaded = 1;
		
		if (g_iCountRoundEnds > 0)
		{
			CreateTimer(2.5, TyTimerGiveWeaponAll);
		}
	}

	g_iRoundStart = 1;
	g_Loaded_REnd = 0;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if( g_Loaded_REnd == 0 )
	{
		g_iCountRoundEnds++;
	}

	// чистим переменные
	g_Loaded = 0;
	g_iRoundStart = 0;
	g_iMapStart = 0;
	g_Loaded_REnd = 1;
}

public Action Event_Player_Disconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && !IsFakeClient(client))
	{
		TyCleanW(client);
	}
}

public Action Event_FinaleWin(Event event, const char[] name, bool dontBroadcast)
{	
	if(g_iClearAfterCampaign == 1)
	{
		int i = 1;
		while(i <= MaxClients)
		{
			TyCleanW(i);
			i += 1;
		}
	}
	else
	{
		#if TYLOG
			LogMessage("Оружие в руках игроков");
		#endif
			TySaveAllWeapon();
		#if TYLOG
			LogMessage("Переход на следующую кампанию");
		#endif
	}
}

public Action Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
#if TYLOG
	LogMessage("Оружие в руках игроков");
#endif

	TySaveAllWeapon();
	
#if TYLOG
	LogMessage("Переход на следующую карту");
#endif
}

public void OnMapStart()
{
	if( g_iMapStart == 0 && g_iRoundStart == 1 && g_Loaded == 0)
	{					
		g_Loaded = 1;
	}

	g_iMapStart = 1;
	
	g_iCountRoundEnds = 0;
}

public void OnMapEnd()
{
	g_Loaded 		= 0;
	g_iMapStart 	= 0;
	g_iRoundStart 	= 1;
}

public Action TyTimerGiveWeaponAll(Handle timer)
{
	TyGiveWeaponAll();
	return Plugin_Stop;
}

public void TyGiveWeaponAll()
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != 3)
		{
			CreateTimer(2.0, TyTimerConnected, GetClientUserId(i));
		}
		i += 1;
	}
}

#if TYLOG
public Action CMD_SaveWeap(int client, int args)
{
	if (client)
	{
		TySaveWeapon(client);
		
		TyGweaponC(client);
		HandleOnWeaponsGivedByTySaver(client);
	}
	return Plugin_Continue;
}

public Action CMD_SaveWeapAll(int client, int args)
{
	if (client)
	{
		TySaveAllWeapon();
		TyGiveWeaponAll();
	}
	return Plugin_Continue;
}
#endif

void TyFakeCHEAT(int client, char[] sCommand, char[] sArgument)
{
	int iFlags = GetCommandFlags(sCommand);
	SetCommandFlags(sCommand, iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", sCommand, sArgument);
	SetCommandFlags(sCommand, iFlags);
}

void TyCleanW(int client)
{
	#if TYLOG
	if (IsClientInGame(client))
	{
		LogMessage("TyCleanW [%N][index %i]", client, client);
	}	
	#endif
	
	g_iWeaponInfo[client][iClip] = 50;
	g_iWeaponInfo[client][iAmmo] = g_iAmmo_smg_max;
	g_iWeaponInfo[client][iUpgrade] = 0;
	g_iWeaponInfo[client][iUpAmmo] = 0;
	
	g_sWeapDB[client][0][0] = '\0';
	g_sWeapDB[client][1][0] = '\0';
	g_sWeapDB[client][2][0] = '\0';
	g_sWeapDB[client][3][0] = '\0';
	g_sWeapDB[client][4][0] = '\0';
}

void TySaveWeapon(int client, int bot = 0)
{
	HandleOnWeaponsPreSaveByTySaver(client);
	
	int iTarget;
	
	// если нужно сохранить оружие бота на игрока то прописываем цель как бота, а сохранять всеравно будет на игрока хозяина бота.
	iTarget = (bot == 0 ? client : bot);
	
	#if TYLOG
	LogMessage("TySaveWeapon TARGET [%N][index %i], OWNER[%N][index %i] - alive %i, team %i, incap %i", iTarget, iTarget, client, client, IsPlayerAlive(iTarget), GetClientTeam(iTarget), GetEntProp(iTarget, Prop_Send, "m_isIncapacitated"));
	#endif
	
	if (GetClientTeam(iTarget) == 3)
	{
		TyCleanW(client);
		return;
	}

	if (!IsPlayerAlive(iTarget))
	{
		TyCleanW(client);
		g_sWeapDB[client][0] = "weapon_smg_silenced";
		return;
	}
	
	if (GetEntProp(iTarget, Prop_Send, "m_isIncapacitated") == 1)
	{		
		int iRevive = GetEntProp(iTarget, Prop_Send, "m_currentReviveCount");
		int isGoingToDie = GetEntProp(iTarget, Prop_Send, "m_isGoingToDie");
		
		TyFakeCHEAT(iTarget, "give", "health");
			
		if (iRevive == g_iSurvMaxIncapCount)	
		{
			iRevive = g_iSurvMaxIncapCount -1;
		}
				
		SetEntProp(iTarget, Prop_Send, "m_currentReviveCount", iRevive);		
		SetEntProp(iTarget, Prop_Send, "m_isGoingToDie", isGoingToDie);
		SetEntityHealth(iTarget, 1);	
		SetEntPropFloat(iTarget, Prop_Send, "m_healthBuffer", 30.0);
		SetEntPropFloat(iTarget, Prop_Send, "m_healthBufferTime", GetGameTime());
	}

	int iSlot0 = GetPlayerWeaponSlot(iTarget, 0);
	int iSlot1 = GetPlayerWeaponSlot(iTarget, 1);
	int iSlot2 = GetPlayerWeaponSlot(iTarget, 2);
	int iSlot3 = GetPlayerWeaponSlot(iTarget, 3);
	int iSlot4 = GetPlayerWeaponSlot(iTarget, 4);

	if (iSlot0 > 0)
	{
		GetEdictClassname(iSlot0, g_sWeapDB[client][0], 39);
		
		g_iWeaponInfo[client][iClip] = GetEntProp(iSlot0, Prop_Send, "m_iClip1", 4);
		g_iWeaponInfo[client][iAmmo] = GetClientAmmo(iTarget, g_sWeapDB[client][0]);
		g_iWeaponInfo[client][iUpgrade] = GetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", 4);
		g_iWeaponInfo[client][iUpAmmo]  = GetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4);
		
		if(g_iRemoveWeaponAfterSave && RemovePlayerItem(iTarget, iSlot0))
		{
			AcceptEntityInput(iSlot0, "Kill");
		}
	}
	else
	{
		g_sWeapDB[client][0] = "weapon_smg_silenced";
		
		g_iWeaponInfo[client][iClip] = 50;
		g_iWeaponInfo[client][iAmmo] = g_iAmmo_smg_max;
		g_iWeaponInfo[client][iUpgrade] = 0;
	}

	if (iSlot1 > 0)
	{
		g_sWeapDB[client][1][0] = '\0';
		sg_className[0] = '\0';
		sg_modelName[0] = '\0';
		GetEdictClassname(iSlot1, sg_className, sizeof(sg_className)-1);

		if (!strcmp(sg_className, "weapon_melee", true))
		{
			GetEntPropString(iSlot1, Prop_Data, "m_strMapSetScriptName", g_sWeapDB[client][1], 40);
			
			if (g_sWeapDB[client][1][0] == '\0')
			{
				GetEntPropString(iSlot1, Prop_Data, "m_ModelName", sg_modelName, sizeof(sg_modelName)-1);
				FormatEx(g_sWeapDB[client][1], 55, MeleeStrCodeByModel(sg_modelName));

				//char tmp[40];
				//GetEntPropString(iSlot1, Prop_Data, "m_strMapSetScriptName", tmp, 40);
				//LogError("not found by m_strMapSetScriptName (%s), but by m_ModelName(%s) this is %s", tmp, sg_modelName, g_sWeapDB[client][1]);
				//LogError("___________");
			}
		}
		else
		{
			if (!strcmp(sg_className, "weapon_pistol", true))
			{
				GetEntPropString(iSlot1, Prop_Data, "m_ModelName", sg_modelName, sizeof(sg_modelName)-1);

				if (!strcmp(sg_modelName, "models/v_models/v_dual_pistolA.mdl", true))
				{
					g_sWeapDB[client][1] = "dual_pistol";
				}
				else 
				{
					g_sWeapDB[client][1] = "weapon_pistol";
				}				
			}
			else
			{
				GetEdictClassname(iSlot1, g_sWeapDB[client][1], 39);
			}
		}

		if(g_iRemoveWeaponAfterSave && RemovePlayerItem(iTarget, iSlot1))
		{
			AcceptEntityInput(iSlot1, "Kill");
		}
	}

	if (iSlot2 > 0)
	{
		GetEdictClassname(iSlot2, g_sWeapDB[client][2], 39);
		
		if(g_iRemoveWeaponAfterSave && RemovePlayerItem(iTarget, iSlot2))
		{
			AcceptEntityInput(iSlot2, "Kill");
		}
	}
	else
	{
		g_sWeapDB[client][2][0] = '\0';
	}

	if (iSlot3 > 0)
	{
		GetEdictClassname(iSlot3, g_sWeapDB[client][3], 39);
				
		if(g_iRemoveWeaponAfterSave && RemovePlayerItem(iTarget, iSlot3))
		{
			AcceptEntityInput(iSlot3, "Kill");
		}
	}
	else
	{
		g_sWeapDB[client][3][0] = '\0';
	}

	if (iSlot4 > 0)
	{
		GetEdictClassname(iSlot4, g_sWeapDB[client][4], 39);
		
		if(g_iRemoveWeaponAfterSave && RemovePlayerItem(iTarget, iSlot4))
		{
			AcceptEntityInput(iSlot4, "Kill");
		}
	}
	else
	{
		g_sWeapDB[client][4][0] = '\0';
	}
#if TYLOG
	LogMessage("TySaveWeapon TARGET[%N][index %i], OWNER[%N][index %i]", iTarget, iTarget, client, client);
	LogMessage("sg_slot0	%s", g_sWeapDB[client][0]);
	LogMessage("sg_slot1	%s", g_sWeapDB[client][1]);
	LogMessage("sg_slot2	%s", g_sWeapDB[client][2]);
	LogMessage("sg_slot3	%s", g_sWeapDB[client][3]);
	LogMessage("sg_slot4	%s", g_sWeapDB[client][4]);
	
	LogMessage("g_iWeaponInfo[iClip]	%i", g_iWeaponInfo[client][iClip]);
	LogMessage("g_iWeaponInfo[iAmmo]	%i", g_iWeaponInfo[client][iAmmo]);
	LogMessage("g_iWeaponInfo[iUpgrade]	%i", g_iWeaponInfo[client][iUpgrade]);
	LogMessage("g_iWeaponInfo[iUpAmmo]	%i", g_iWeaponInfo[client][iUpAmmo]);	
	
	LogMessage("___________");
#endif
}

char MeleeStrCodeByModel(const char[] Model)
{
	char buffer[64];
	if (StrEqual(Model, "models/weapons/melee/v_cricket_bat.mdl")) 			buffer = "cricket_bat";
	else if (StrEqual(Model, "models/weapons/melee/v_crowbar.mdl"))			buffer = "crowbar";
	else if (StrEqual(Model, "models/weapons/melee/v_bat.mdl"))				buffer = "baseball_bat";
	else if (StrEqual(Model, "models/weapons/melee/v_electric_guitar.mdl"))	buffer = "electric_guitar";
	else if (StrEqual(Model, "models/weapons/melee/v_fireaxe.mdl"))			buffer = "fireaxe";
	else if (StrEqual(Model, "models/weapons/melee/v_katana.mdl"))			buffer = "katana";
	else if (StrEqual(Model, "models/v_models/v_knife_t.mdl"))				buffer = "knife";
	else if (StrEqual(Model, "models/weapons/melee/v_tonfa.mdl"))			buffer = "tonfa";
	else if (StrEqual(Model, "models/weapons/melee/v_golfclub.mdl"))		buffer = "golfclub";
	else if (StrEqual(Model, "models/weapons/melee/v_machete.mdl"))			buffer = "machete";
	else if (StrEqual(Model, "models/weapons/melee/v_frying_pan.mdl"))		buffer = "frying_pan";
	else if (StrEqual(Model, "models/weapons/melee/v_riotshield.mdl"))		buffer = "alliance_shield";
	else if (StrEqual(Model, "models/weapons/melee/v_fubar.mdl"))			buffer = "fubar";
	else if (StrEqual(Model, "models/weapons/melee/v_paintrain.mdl"))		buffer = "nail_board";
	else if (StrEqual(Model, "models/weapons/melee/v_sledgehammer.mdl"))	buffer = "sledgehammer";
	else
	{
		LogError("not found melee by Model(%s)", Model);
		buffer = "";
	}

	return buffer;
}

void TySaveAllWeapon()
{
	int i = 1;
	int team;
	while(i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && (team = GetClientTeam(i)) != 3)
		{
			if (team == 1)
			{
				int bot = GetBotIdlePlayer(i);
				if(bot > 0)
				{
					TySaveWeapon(i, bot);
				}
			}
			else
			{
				TySaveWeapon(i);
			}
		}
		i += 1;
	}
}

int GetBotIdlePlayer(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && GetPlayerIdleBot(i) == client)
		{
			return i;
		}
	}

	return 0;
}

int GetPlayerIdleBot(int bot)
{
	char sClass[64];
	GetEntityNetClass(bot, sClass, sizeof(sClass));

	PropFieldType proptype;

	if (FindSendPropInfo(sClass, "m_humanSpectatorUserID", proptype) > 0){

		int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));
		if (client && IsClientInGame(client) && GetClientTeam(client) == 1 && !IsFakeClient(client))
			return client;
	}
	return 0;
}

void TyGweaponC(int client)
{
	#if TYLOG
	LogMessage("TyGweaponC [%N][index %i] - alive %i", client, client, IsPlayerAlive(client));
	#endif
	
	if (IsPlayerAlive(client))
	{
		#if TYLOG
		LogMessage("TyGweaponC [%N][index %i]", client, client);
		LogMessage("sg_slot0	%s", g_sWeapDB[client][0]);
		LogMessage("sg_slot1	%s", g_sWeapDB[client][1]);
		LogMessage("sg_slot2	%s", g_sWeapDB[client][2]);
		LogMessage("sg_slot3	%s", g_sWeapDB[client][3]);
		LogMessage("sg_slot4	%s", g_sWeapDB[client][4]);
		
		LogMessage("g_iWeaponInfo[iClip]	%i", g_iWeaponInfo[client][iClip]);
		LogMessage("g_iWeaponInfo[iAmmo]	%i", g_iWeaponInfo[client][iAmmo]);
		LogMessage("g_iWeaponInfo[iUpgrade]	%i", g_iWeaponInfo[client][iUpgrade]);
		LogMessage("g_iWeaponInfo[iUpAmmo]	%i", g_iWeaponInfo[client][iUpAmmo]);	
		
		LogMessage("___________");
		#endif
		
		int iSlot;
		for (int index; index < 5; index++)
		{
			iSlot = GetPlayerWeaponSlot(client, index);
			if (iSlot > 0 && RemovePlayerItem(client, iSlot))
			{
				AcceptEntityInput(iSlot, "Kill");
			}
		}

		if (IsFakeClient(client))
		{
			TyFakeCHEAT(client, "give", "weapon_pistol");
			return;
		}

		if (g_sWeapDB[client][0][0] != '\0')
		{
			TyFakeCHEAT(client, "give", g_sWeapDB[client][0]);
			iSlot = GetPlayerWeaponSlot(client, 0);
			if (iSlot > 0)
			{	
				SetEntProp(iSlot, Prop_Send, "m_iClip1", g_iWeaponInfo[client][iClip], 4);
				SetClientAmmo(client, g_sWeapDB[client][0], g_iWeaponInfo[client][iAmmo]);
				SetEntProp(iSlot, Prop_Send, "m_upgradeBitVec", g_iWeaponInfo[client][iUpgrade], 4);
				SetEntProp(iSlot, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", g_iWeaponInfo[client][iUpAmmo], 4);
			}
			else
			{
				LogError("ERROR::SLOT 0, WEAPON AFTER GIVE HAVE INDEX -1::TyGweaponC [%N][index %i]", client, client);
				LogError("sg_slot0	%s", g_sWeapDB[client][0]);
				
				LogError("g_iWeaponInfo[iClip]	%i", g_iWeaponInfo[client][iClip]);
				LogError("g_iWeaponInfo[iAmmo]	%i", g_iWeaponInfo[client][iAmmo]);
				LogError("g_iWeaponInfo[iUpgrade]	%i", g_iWeaponInfo[client][iUpgrade]);
				LogError("g_iWeaponInfo[iUpAmmo]	%i", g_iWeaponInfo[client][iUpAmmo]);	
				
				LogError("END ERROR REPORT.");
			}
		}
		else
		{
			if(g_iNoob > 0)
			{
				TyFakeCHEAT(client, "give", "weapon_smg_silenced");
			}
		}

		if (g_sWeapDB[client][1][0] != '\0')
		{
			if (!strcmp(g_sWeapDB[client][1], "dual_pistol", true))
			{
				TyFakeCHEAT(client, "give", "weapon_pistol");
				TyFakeCHEAT(client, "give", "weapon_pistol");
			}
			else
			{
				TyFakeCHEAT(client, "give", g_sWeapDB[client][1]);
			}
		}
		else
		{
			TyFakeCHEAT(client, "give", "weapon_pistol");
		}

		if (g_sWeapDB[client][2][0] != '\0')
		{
			TyFakeCHEAT(client, "give", g_sWeapDB[client][2]);
		}
		if (g_sWeapDB[client][3][0] != '\0')
		{
			TyFakeCHEAT(client, "give", g_sWeapDB[client][3]);
		}
		if (g_sWeapDB[client][4][0] != '\0')
		{
			TyFakeCHEAT(client, "give", g_sWeapDB[client][4]);
		}
	}
}

public Action TyTimerConnected(Handle timer, any client)
{
	client = GetClientOfUserId(client);
	if (client && IsClientInGame(client))
	{
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			TyGweaponC(client);
			HandleOnWeaponsGivedByTySaver(client);
			return Plugin_Stop;
		}
		CreateTimer(1.0, TyTimerConnected, GetClientUserId(client));
	}
	else
	{
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		CreateTimer(4.0, TyTimerConnected, GetClientUserId(client));
	}
}

int GetClientAmmo(int client, char[] weapon)
{
	int weapon_offset;
	
	if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47") || StrEqual(weapon, "weapon_rifle_m60"))
	{
		weapon_offset = 12;
	}
	else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
	{
		weapon_offset = 20;
	}
	else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
	{
		weapon_offset = 28;
	}
	else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
	{
		weapon_offset = 32;
	}
	else if (StrEqual(weapon, "weapon_hunting_rifle"))
	{
		weapon_offset = 36;
	}
	else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
	{
		weapon_offset = 40;
	}
	else if (StrEqual(weapon, "weapon_grenade_launcher"))
	{
		weapon_offset = 68;
	}

	return weapon_offset > 0 ? GetEntData(client, g_iAmmoOffset+weapon_offset) : 0;
}

void SetClientAmmo(int client, char[] weapon, int count)
{
	int weapon_offset;
	if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47") || StrEqual(weapon, "weapon_rifle_m60"))
	{
		weapon_offset = 12;
	}
	else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
	{
		weapon_offset = 20;
	}
	else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
	{
		weapon_offset = 28;
	}
	else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
	{
		weapon_offset = 32;
	}
	else if (StrEqual(weapon, "weapon_hunting_rifle"))
	{
		weapon_offset = 36;
	}
	else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
	{
		weapon_offset = 40;
	}
	else if (StrEqual(weapon, "weapon_grenade_launcher"))
	{
		weapon_offset = 68;
	}

	if (weapon_offset > 0)
	{
		SetEntData(client, g_iAmmoOffset+weapon_offset, count);
	}
}

void HandleOnWeaponsPreSaveByTySaver(int client)
{	
	Call_StartForward(g_fwdOnWeaponsPreSaveByTySaver);
	Call_PushCell(client);
	Call_Finish();
}

void HandleOnWeaponsGivedByTySaver(int client)
{	
	Call_StartForward(g_fwdOnWeaponsGivedByTySaver);
	Call_PushCell(client);
	Call_Finish();
}