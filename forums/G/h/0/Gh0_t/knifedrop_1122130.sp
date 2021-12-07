/*
*****************************************
*   Knife-Drop for Sourcemod			*
*			           By Gh0$t         *
*		http://www.HuGaminG.de/         *
*****************************************
*/

//~~~~~~~ ( Include's
#include <sourcemod>
#include <sdktools>

//~~~~~~~ ( Define's
#define PLUGIN_VERSION "1.1"
#pragma semicolon 1

//~~~~~~~ ( New's
//~~ ( Handle's
new Handle:KnifeDropEnabled;
new Handle:weaponDrop = INVALID_HANDLE;
new Handle:gameConf = INVALID_HANDLE;

//~~~~~~~ ( Plugin Info's
public Plugin:myinfo =
{
	name = "Knife Drop",
	author = "Gh0$t",
	description = "Drop the Knife with G",
	version = PLUGIN_VERSION,
	url = "http://www.HuGaminG.de/"
};

//~~~~~~~ ( Plugin Start
public OnPluginStart()
{
	RegisterHacks();

	LoadTranslations ("knifedrop.phrases");

	CreateConVar("sm_knifedrop_version", PLUGIN_VERSION, "Join Message Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	KnifeDropEnabled = CreateConVar("sm_knifedrop_enabled", "1", "enable(1) and disable(0) the Knife-Drop");

	RegConsoleCmd("drop", Command_Drop);
}

RegisterHacks()
{
	gameConf = LoadGameConfigFile("knifedrop.games");
	if(gameConf == INVALID_HANDLE)
	{
		SetFailState("gamedata/weapon_restrict.games.txt not loadable");
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Signature, "CSWeaponDrop");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	weaponDrop = EndPrepSDKCall();
}

//~~~~~~~ ( Commands
public Action:Command_Drop(client, args)
{
	if (IsClientInGame(client))
	{
		if(GetConVarInt(KnifeDropEnabled))
		{
			new String:playerWeapon[32];
			GetClientWeapon(client, playerWeapon, sizeof(playerWeapon));

			if(StrEqual("weapon_knife", playerWeapon))
			{
				new weapon = GetPlayerWeaponSlot(client, 2);
				SDKCall(weaponDrop, client, weapon, true, true);
				KnifeDropMsg(client);
			}
		}
	}
	return Plugin_Continue;
}

//~~~~~~~ ( TheMessages
KnifeDropMsg(client)
{
	if(GetConVarInt(KnifeDropEnabled) == 1)
	{
		PrintToChat(client,"%t", "knifedrop",client);
	}
}
