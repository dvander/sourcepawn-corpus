#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

// Global Definitions
#define PLUGIN_VERSION "1.0.6a"

new randomClass;

new bool:isActive = false;

new Handle:cvarEnable;
new Handle:cvarClass;
new Handle:cvarRandom;

new Handle:hGameConf;
new Handle:hForceStalemate;
new Handle:hGiveNamedItem;
new Handle:hRemoveAllWeapons;
new Handle:hWeaponEquip;

// Functions
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
	CreateConVar("sm_sdmr_version", PLUGIN_VERSION, "Sudden Death Melee Redux Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("sm_suddendeathmelee_enable", "1", "Enable/Disable the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarClass = CreateConVar("sm_suddendeathmelee_class", "scout", "Class for people to spawn as", FCVAR_PLUGIN);
	cvarRandom = CreateConVar("sm_suddendeathmelee_random", "1", "Which random mode to choose a class for someone to spawn as (1 = Per player spawn, 2 = Per stalemate)", FCVAR_PLUGIN, true, 1.0, true, 2.0);

	AutoExecConfig(true, "plugin.suddendeathmelee");

	RegAdminCmd("sm_forcestalemate", Command_ForceStalemate, ADMFLAG_CHEATS, "sm_forcestalemate");
	RegConsoleCmd("equip", Command_Equip);

	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("teamplay_round_stalemate", event_SuddenDeathStart);
	HookEvent("teamplay_round_start", event_SuddenDeathEnd);
	HookEvent("teamplay_round_win", event_SuddenDeathEnd);

	hGameConf = LoadGameConfigFile("sdmr.games");

	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "ForceStalemate");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	hForceStalemate = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "GiveNamedItem");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
	hGiveNamedItem = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "RemoveAllWeapons");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	hRemoveAllWeapons = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	hWeaponEquip = EndPrepSDKCall();
}

public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarInt(cvarEnable) || !isActive)
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	decl String:classString[32];
	GetConVarString(cvarClass, classString, sizeof(classString));

	new TFClassType:class = TF2_GetClass(classString);
	if (class == TFClass_Unknown)
	{
		if (strcmp(classString, "random") == 0)
		{
			switch(GetConVarInt(cvarRandom))
			{
				case 1:
					class = TFClassType:GetRandomInt(1, 9);
				case 2:
				{
					if (randomClass == 10)
						class = TFClassType:GetRandomInt(1, 9);
					else
						class = TFClassType:randomClass;
				}
			}
		}
	}

	if (class != TFClass_Unknown)
		TF2_SetPlayerClass(client, class, false, false);

	CreateTimer(0.1, timer_Melee, client);
}

public Action:event_SuddenDeathStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	isActive = true;
	randomClass = GetRandomInt(1, 10);

	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsClientOnTeam(i))
			TF2_RespawnPlayer(i);
	}
}

public Action:event_SuddenDeathEnd(Handle:event, const String:name[], bool:dontBroadcast)
	isActive = false;

public Action:timer_Melee(Handle:timer, any:client)
{
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		SDKCall(hRemoveAllWeapons, client, true);
		EquipClassMelee(client, TF2_GetPlayerClass(client));

		ClientCommand(client, "slot3");
	}
}

public Action:Command_ForceStalemate(client, args)
{
	SDKCall(hForceStalemate, 1, false, false);
	return Plugin_Handled;
}

public Action:Command_Equip(client, args)
{
	if (!GetConVarInt(cvarEnable) || !isActive)
		return;

	CreateTimer(0.1, timer_Melee, client);
}

stock bool:IsClientOnTeam(client)
{
	new team = GetClientTeam(client);
	switch (team)
	{
		case 2:
			return true;
		case 3:
			return true;
		default:
			return false;
	}

	return false;
}

stock EquipClassMelee(client, TFClassType:class)
{
	new entity;
	switch (class)
	{
		case 1:
		{
			entity = SDKCall(hGiveNamedItem, client, "tf_weapon_bat", 0, 0);
			if (entity)
				SDKCall(hWeaponEquip, client, entity);
		}
		case 2:
		{
			entity = SDKCall(hGiveNamedItem, client, "tf_weapon_club", 0, 0);
			if (entity)
				SDKCall(hWeaponEquip, client, entity);
		}
		case 3:
		{
			entity = SDKCall(hGiveNamedItem, client, "tf_weapon_shovel", 0, 0);
			if (entity)
				SDKCall(hWeaponEquip, client, entity);
		}
		case 4:
		{
			entity = SDKCall(hGiveNamedItem, client, "tf_weapon_bottle", 0, 0);
			if (entity)
				SDKCall(hWeaponEquip, client, entity);
		}
		case 5:
		{
			entity = SDKCall(hGiveNamedItem, client, "tf_weapon_bonesaw", 0, 0);
			if (entity)
				SDKCall(hWeaponEquip, client, entity);
		}
		case 6:
		{
			entity = SDKCall(hGiveNamedItem, client, "tf_weapon_fists", 0, 0);
			if (entity)
				SDKCall(hWeaponEquip, client, entity);
		}
		case 7:
		{
			entity = SDKCall(hGiveNamedItem, client, "tf_weapon_fireaxe", 0, 0);
			if (entity)
				SDKCall(hWeaponEquip, client, entity);
		}
		case 8:
		{
			entity = SDKCall(hGiveNamedItem, client, "tf_weapon_knife", 0, 0);
			if (entity)
				SDKCall(hWeaponEquip, client, entity);
		}
		case 9:
		{
			entity = SDKCall(hGiveNamedItem, client, "tf_weapon_wrench", 0, 0);
			if (entity)
				SDKCall(hWeaponEquip, client, entity);
		}
	}
}