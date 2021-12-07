#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.1.4"

new g_RandomClass;

new bool:g_bIsActive;
new bool:g_bMaxClass;
new bool:g_bClassRestrictions;

new Handle:g_hCvarClass;
new Handle:g_hCvarEnable;
new Handle:g_hCvarRandom;
new Handle:g_hCvarDisable;

new Handle:g_hGameConf;
new Handle:g_hForceStalemate;
new Handle:g_hRegenerate;

public Plugin:myinfo =
{
	name = "Sudden Death Melee Redux",
	author = "bl4nk",
	description = "Melee only mode during sudden death",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_sdmr_version", PLUGIN_VERSION, "Sudden Death Melee Redux Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCvarClass = CreateConVar("sm_suddendeathmelee_class", "scout", "Class for people to spawn as", FCVAR_PLUGIN);
	g_hCvarEnable = CreateConVar("sm_suddendeathmelee_enable", "1", "Enable/Disable the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarRandom = CreateConVar("sm_suddendeathmelee_random", "1", "Which random mode to choose a class for someone to spawn as (1 = Per player spawn, 2 = Per stalemate)", FCVAR_PLUGIN, true, 1.0, true, 2.0);
	g_hCvarDisable = CreateConVar("sm_suddendeathmelee_disableplugins", "1", "Disable known plugins that can cause issues", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	AutoExecConfig(true, "plugin.suddendeathmelee");

	RegAdminCmd("sm_forcestalemate", Command_ForceStalemate, ADMFLAG_CHEATS, "sm_forcestalemate");

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("teamplay_round_stalemate", Event_SuddenDeathStart);
	HookEvent("teamplay_round_start", Event_SuddenDeathEnd);
	HookEvent("teamplay_round_win", Event_SuddenDeathEnd);

	g_hGameConf = LoadGameConfigFile("sdmr.games");

	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Virtual, "ForceStalemate");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_hForceStalemate = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "Regenerate");
	g_hRegenerate = EndPrepSDKCall();
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_hCvarEnable) && g_bIsActive)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		decl String:classString[32];
		GetConVarString(g_hCvarClass, classString, sizeof(classString));

		new TFClassType:class = TF2_GetClass(classString);
		if (class == TFClass_Unknown)
		{
			if (strcmp(classString, "random") == 0)
			{
				switch(GetConVarInt(g_hCvarRandom))
				{
					case 1:
					{
						class = TFClassType:GetRandomInt(1, 9);
					}
					case 2:
					{
						if (g_RandomClass == 10)
						{
							class = TFClassType:GetRandomInt(1, 9);
						}
						else
						{
							class = TFClassType:g_RandomClass;
						}
					}
				}
			}
			else
			{
				class = TF2_GetPlayerClass(client);
			}
		}

		TF2_SetPlayerClass(client, class, false, false);
		SDKCall(g_hRegenerate, client);
		SetClassSpeed(client, class);

		CreateTimer(0.1, Timer_MeleeStrip, GetEventInt(event, "userid"));
	}
}

public Action:Timer_MeleeStrip(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client && IsPlayerAlive(client))
	{
		for (new i = 0; i <= 5; i++)
		{
			if (i == 2)
			{
				continue;
			}

			TF2_RemoveWeaponSlot(client, i);
		}

		new weapon = GetPlayerWeaponSlot(client, 2);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}

public Event_SuddenDeathStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bIsActive = true;

	if (GetConVarBool(g_hCvarDisable))
	{
		new Handle:hMaxClass = FindConVar("sm_maxclass_allow");
		if (hMaxClass != INVALID_HANDLE)
		{
			g_bMaxClass = GetConVarBool(hMaxClass);
			SetConVarBool(hMaxClass, false);
		}

		new Handle:hClassRestrictions = FindConVar("sm_classrestrict_enabled");
		if (hClassRestrictions != INVALID_HANDLE)
		{
			g_bClassRestrictions = GetConVarBool(hClassRestrictions);
			SetConVarBool(hClassRestrictions, false);
		}
	}

	g_RandomClass = GetRandomInt(1, 10);

	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsClientInGame(i) && IsClientOnTeam(i))
		{
			TF2_RespawnPlayer(i);
		}
	}
}

public Event_SuddenDeathEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bIsActive && GetConVarBool(g_hCvarDisable))
	{
		new Handle:hMaxClass = FindConVar("sm_maxclass_allow");
		if (hMaxClass != INVALID_HANDLE)
		{
			SetConVarBool(hMaxClass, g_bMaxClass);
		}

		new Handle:hClassRestrictions = FindConVar("sm_classrestrict_enabled");
		if (hClassRestrictions != INVALID_HANDLE)
		{
			SetConVarBool(hClassRestrictions, g_bClassRestrictions);
		}
	}

	g_bIsActive = false;
}

public Action:Command_ForceStalemate(client, args)
{
	SDKCall(g_hForceStalemate, 1, false, false);

	return Plugin_Handled;
}

bool:IsClientOnTeam(client)
{
	switch (GetClientTeam(client))
	{
		case 2:
		{
			return true;
		}
		case 3:
		{
			return true;
		}
	}

	return false;
}

SetClassSpeed(client, TFClassType:class)
{
	switch (class)
	{
		case TFClass_Scout:
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 400.0);
		case TFClass_Sniper:
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
		case TFClass_Soldier:
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 240.0);
		case TFClass_DemoMan:
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 280.0);
		case TFClass_Medic:
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 320.0);
		case TFClass_Heavy:
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 230.0);
		case TFClass_Pyro:
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
		case TFClass_Spy:
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
		case TFClass_Engineer:
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
	}
}