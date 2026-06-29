#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.0"
new Handle:gameConf;
new Handle:giveNamedItem;
new Handle:weaponEquip;
new offsActiveWeapon = -1;
new offsClip1 = -1;
new g_ExplosionSprite;
new bool:killed[MAXPLAYERS+1];
public Plugin:myinfo = 
{
	name = "Paintball",
	author = "MikeJS",
	description = "1 shot kill, flares only.",
	version = PLUGIN_VERSION,
	url = "http://mikejs.byethost18.com/"
}
public OnPluginStart() {
	gameConf = LoadGameConfigFile("paintball.games");
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
	offsActiveWeapon = FindSendPropInfo("CTFPlayer", "m_hActiveWeapon");
	offsClip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	CreateConVar("sm_paintball", PLUGIN_VERSION, "Paintball version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_death", Event_player_death, EventHookMode_Pre);
	HookEvent("player_hurt", Event_player_hurt);
	HookEvent("player_spawn", Event_player_spawn);
}
public OnMapStart() {
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
}
public OnConfigsExecuted() {
	SetConVarBool(FindConVar("tf_weapon_criticals"), true);
}
public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(killed[client]) {
		killed[client] = false;
		return Plugin_Handled;
	}
	decl Float:vecPos[3];
	GetClientAbsOrigin(client, vecPos);
	vecPos[2] += 2;
	TE_SetupExplosion(vecPos, g_ExplosionSprite, 1.0, 0, 0, 192, 500);
	TE_SendToAll();
	return Plugin_Continue;
}
public Action:Event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	killed[client] = true;
	if(GetClientOfUserId(GetEventInt(event, "attacker"))>0) {
		FakeClientCommand(client, "explode");
	}
}
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client)) {
		if(_:TF2_GetPlayerClass(client)!=7) {
			TF2_SetPlayerClass(client, TFClassType:7);
		}
		CreateTimer(0.01, Equip, client);
	}
}
public Action:Equip(Handle:timer, any:client) {
	if(IsClientInGame(client) && IsPlayerAlive(client)) {
		decl String:wpn[32];
		GetClientWeapon(client, wpn, sizeof(wpn));
		if(!StrEqual(wpn, "tf_weapon_flaregun")) {
			new weaponIndex;
			while((weaponIndex = GetPlayerWeaponSlot(client, 1))!=-1) {
				RemovePlayerItem(client, weaponIndex);
				RemoveEdict(weaponIndex);
			}
			new entity = SDKCall(giveNamedItem, client, "tf_weapon_flaregun", 0, 0);
			SDKCall(weaponEquip, client, entity);
			TF2_RemoveWeaponSlot(client, 0);
			TF2_RemoveWeaponSlot(client, 2);
			SetEntData(GetEntDataEnt2(client, offsActiveWeapon), offsClip1, 99);
		}
		CreateTimer(5.0, Equip, client);
	}
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result) {
	SetEntData(GetEntDataEnt2(client, offsActiveWeapon), offsClip1, 100);
	result = true;
	return Plugin_Changed;
}