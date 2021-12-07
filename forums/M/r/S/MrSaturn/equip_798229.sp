#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
new Handle:gameConf;
new Handle:giveNamedItem;
new Handle:weaponEquip;
new Handle:gweapons = INVALID_HANDLE;
public OnPluginStart() {
	gameConf = LoadGameConfigFile("givenameditem.games");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Virtual, "GiveNamedItem");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
	giveNamedItem = EndPrepSDKCall();
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	weaponEquip = EndPrepSDKCall();
	HookEvent("player_spawn", Event_player_spawn);
	gweapons = CreateConVar("sm_equip_weapons", "", "weapons", FCVAR_PLUGIN);
}
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client)) {
		CreateTimer(0.01, Equip, client);
		DisableResupply();
	}
}
public Action:Equip(Handle:timer, any:client) {
	if(IsClientInGame(client) && IsPlayerAlive(client)) {
		TF2_RemoveAllWeapons(client);
		decl String:wpns[1024], String:split[16][64];
		GetConVarString(gweapons, wpns, sizeof(wpns));
		if(!StrEqual(wpns, "")) {
			new count = ExplodeString(wpns, ",", split, 16, 64);
			for(new i=0;i<count;i++) {
				TrimString(split[i]);
				new entity = SDKCall(giveNamedItem, client, split[i], 0, 0);
				SDKCall(weaponEquip, client, entity);
			}
		}
	}
}
DisableResupply() {
	new iRegenerate = -1;
	while ((iRegenerate = FindEntityByClassname(iRegenerate, "func_regenerate")) != -1)
		AcceptEntityInput(iRegenerate, "Disable");
}