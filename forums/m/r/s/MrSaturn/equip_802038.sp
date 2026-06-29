#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
// This plugin was made using sections from Allied Modders forums at http://forums.alliedmods.net/showthread.php?t=88417 and with the template from MikeJS at 												// http://forums.alliedmods.net/showthread.php?t=89055, which is where you may also find the most recent update of this plugin.
new Handle:gameConf;
new Handle:giveNamedItem;
new Handle:weaponEquip;
new Handle:gweapons = INVALID_HANDLE;
new offsNextPrimaryAttack = -1; 
new offsNextSecondaryAttack = -1; 
new offsActiveWeapon = -1; 
new weaponRateQueue[MAXPLAYERS+1]; 
new weaponRateQueueLen; 
new Handle:g_hROF = INVALID_HANDLE; 
new Float:rofmult; 
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
	offsNextPrimaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack"); 
    	offsNextSecondaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack"); 
   	offsActiveWeapon = FindSendPropInfo("CTFPlayer", "m_hActiveWeapon"); 
   	g_hROF = CreateConVar("sm_rof", "1.0", "ROF multiplier.", FCVAR_PLUGIN|FCVAR_NOTIFY); 
	HookConVarChange(g_hROF, Cvar_rof); 
}
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client)) {
		CreateTimer(0.01, Equip, client);
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
public OnConfigsExecuted() { 
    rofmult = 1.0/GetConVarFloat(g_hROF); 
} 
public OnGameFrame() { 
    if(weaponRateQueueLen) { 
        decl ent, Float:time; 
        new Float:enginetime = GetGameTime(); 
        for(new i=0;i<weaponRateQueueLen;i++) { 
            ent = weaponRateQueue[i]; 
            if(IsValidEntity(ent)) { 
                time = (GetEntDataFloat(ent, offsNextPrimaryAttack)-enginetime)*rofmult; 
                SetEntDataFloat(ent, offsNextPrimaryAttack, time+enginetime, true); 
                time = (GetEntDataFloat(ent, offsNextSecondaryAttack)-enginetime)*rofmult; 
                SetEntDataFloat(ent, offsNextSecondaryAttack, time+enginetime, true); 
            } 
        } 
        weaponRateQueueLen = 0; 
    } 
} 
public Cvar_rof(Handle:convar, const String:oldValue[], const String:newValue[]) { 
    rofmult = 1.0/GetConVarFloat(g_hROF); 
} 
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result) { 
    new ent = GetEntDataEnt2(client, offsActiveWeapon); 
    if(ent!=-1) { 
        weaponRateQueue[weaponRateQueueLen++] = ent; 
    } 
    return Plugin_Continue; 
} 