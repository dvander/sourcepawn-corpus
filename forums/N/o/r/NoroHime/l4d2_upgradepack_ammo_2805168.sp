#define PLUGIN_VERSION		"1.0"
#define PLUGIN_PREFIX		"l4d2_"
#define PLUGIN_NAME			"upgradepack_ammo"
#define PLUGIN_NAME_FULL	"[L4D2] UpgradePack Gives Ammo"
#define PLUGIN_DESCRIPTION	"gives ammo when receive upgrade ammo"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?t=342914"

/**
 *	Changes
 *	v1.0 (29-May-2023)
 *		- just released
 * 
 */


#pragma newdecls required
#pragma semicolon 1

#include <sdkhooks>
#include <sdktools>

#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))

public Plugin myinfo = {
	name			= PLUGIN_NAME_FULL,
	author			= PLUGIN_AUTHOR,
	description		= PLUGIN_DESCRIPTION,
	version			= PLUGIN_VERSION,
	url				= PLUGIN_LINK
};

Handle sdkUseAmmo;

public void OnPluginStart() {

	CreateConVar(PLUGIN_NAME ... "_version", PLUGIN_VERSION, "Plugin Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	Handle hGameData = LoadGameConfigFile(PLUGIN_PREFIX ... PLUGIN_NAME);

	if( hGameData == null )
		SetFailState("fail to load gamedata file %s.txt", PLUGIN_PREFIX ... PLUGIN_NAME);

	// prepare SDKCall CWeaponAmmoSpawn::Use
	StartPrepSDKCall(SDKCall_Entity);
	if( !PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CWeaponAmmoSpawn::Use") )
		SetFailState("Could not load the \"CWeaponAmmoSpawn::Use\" gamedata signature.");

	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkUseAmmo = EndPrepSDKCall();
	if( sdkUseAmmo == null )
		SetFailState("Could not prep the \"CWeaponAmmoSpawn::Use\" function.");

	HookEvent("receive_upgrade", OnReceiveUpgrade);
}

void OnReceiveUpgrade(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("userid"));

	static char name_upgrade[32];

	event.GetString("upgrade", name_upgrade, sizeof(name_upgrade));

	if (strcmp(name_upgrade, "LASER_SIGHT") == 0)
		return;

	if (IsClient(client) && GetClientTeam(client) == 2)
		SDKCall( sdkUseAmmo, client, client, client, 1, 0.0 );
}