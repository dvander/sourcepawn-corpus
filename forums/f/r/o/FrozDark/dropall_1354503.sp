
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"
#pragma semicolon 1

new Handle:DropAllEnabled;
new Handle:weaponDrop = INVALID_HANDLE;
new Handle:gameConf = INVALID_HANDLE;
new weapon;

public Plugin:myinfo =
{
	name = "Drop All",
	author = "FrozDark",
	description = "You will be able to drop all undropable weapons like knife and grenades.",
	version = PLUGIN_VERSION,
	url = "http://all-stars.sytes.net/"
};

public OnPluginStart()
{
	RegisterHacks();

	CreateConVar("sm_dropall_version", PLUGIN_VERSION, "Drop all Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	DropAllEnabled = CreateConVar("sm_dropall_enabled", "1", "enable(1) and disable(0) the Drop-All");

	RegConsoleCmd("drop", Command_Drop);
}

RegisterHacks()
{
	gameConf = LoadGameConfigFile("dropall.games");
	if(gameConf == INVALID_HANDLE)
	{
		SetFailState("gamedata/dropall.games.txt not loadable");
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Signature, "CSWeaponDrop");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	weaponDrop = EndPrepSDKCall();
}

public Action:Command_Drop(client, args)
{
	if (IsClientInGame(client))
	{
		if(GetConVarBool(DropAllEnabled))
		{
			weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (IsValidEdict(weapon))
			{
				SDKCall(weaponDrop, client, weapon, true, true);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}