#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>
#include <cstrike>

//#include "zr/weapons/restrict"

#define PLUGIN_VERSION "1.0"

#define NADE_PRICE 1000
#define SND_BUYNADE "items/itempickup.wav"
#define SND_CANTBUY "buttons/weapon_cant_buy.wav"

new i_clients_amount[MAXPLAYERS+1];
new gAccount = -1;

// P L U G I N    I N F O
public Plugin:myinfo = {
	name = "[ZR] Infect Nade",
	author = "nicekill (nicekill.com)",
	description = "Grenade for zombies used for infecting humans",
	version = PLUGIN_VERSION,
	url = "http://www.nicekill.com/"
};

// Fires when the plugin start
public OnPluginStart(){
	// Creates console variable version
	CreateConVar("zr_infect_nade_version", PLUGIN_VERSION, "The version of the plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	// Hooks event changes
	//HookEvent("player_death", OnPlayerDeath);
	//HookEvent("hegrenade_detonate", NadeDetonate);
	
	// Registers new console commands
	RegConsoleCmd("sm_nade", Command_BuyNade, "Buy an infect nade.");

	if ((gAccount = FindSendPropOffs("CCSPlayer", "m_iAccount")) == -1){
		SetFailState("Could not find offset \"m_iAccount\"");
	}

	// Loads the translation
	LoadTranslations("zr_infect_nade");
}
// Fires when the map starts
public OnMapStart(){
	PrecacheSound(SND_BUYNADE, true);
	PrecacheSound(SND_CANTBUY, true);
}
// Fires when the client disconnects
public OnClientDisconnect(client){
	i_clients_amount[client] = 0;
}

// events
public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn){
	
}

/*
	------------------------------------------------
*/
public Action:Command_BuyNade(client, argc){
	if (!client || !IsClientInGame(client)){return Plugin_Continue;}
	if (!IsPlayerAlive(client)){		PrintHintText(client, "%t", "Can't buy while dead"); return Plugin_Handled;}
	if (GetClientTeam(client) <= 1){	PrintHintText(client, "%t", "Can't buy while spec"); return Plugin_Handled;}
	/*if (ZR_IsClientHuman(client)){		PrintHintText(client, "%t", "Can't buy while human"); return Plugin_Handled;}*/
	
	// purchase
	new money = GetEntData(client, gAccount);
	if (money < NADE_PRICE){
		PrintHintText(client, "%t", "Can't buy low money");
		EmitSoundToClient(client, SND_CANTBUY);
		return Plugin_Handled;
	}

     // override ZR's hooks
     SDKUnhook(client, SDKHook_WeaponCanUse, RestrictCanUse);
     SDKUnhook(client, SDKHook_WeaponCanUse, zr_nade_RestrictCanUse);
     SDKHook(client, SDKHook_WeaponCanUse, zr_nade_RestrictCanUse);

     // trade money for the nade
	money -= NADE_PRICE;
	SetEntData(client, gAccount, money);
	i_clients_amount[client]++;
	GivePlayerItem(client, "weapon_hegrenade");
	PrintHintText(client, "%t", "Bought infect nade");
	EmitSoundToClient(client, SND_BUYNADE);

	return Plugin_Handled;
}
// modified Hook callback of RestrictCanUse from zr/weapons/restrict.inc
public Action:zr_nade_RestrictCanUse(client, weapon){
    // restore ZR's hooks
    SDKUnhook(client, SDKHook_WeaponCanUse, zr_nade_RestrictCanUse);
    SDKHook(client, SDKHook_WeaponCanUse, RestrictCanUse);
    
    // If the player is a zombie
    if (ZR_IsClientZombie(client)){
        return ACTION_CONTINUE;
    }

    // let ZR handle this
    return RestrictCanUse(client, weapon);
}
/*public Action:NadeDetonate(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!enabled || !freezegren)
		return;
	
	decl String:EdictName[64];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	maxents = GetMaxEntities();
	
	for (new edict = MaxClients; edict <= maxents; edict++){
		if (IsValidEdict(edict))		{
			GetEdictClassname(edict, EdictName, sizeof(EdictName));
			if (!strcmp(EdictName, "smokegrenade_projectile", false)){
				if (GetEntPropEnt(edict, Prop_Send, "m_hThrower") == client)
					AcceptEntityInput(edict, "Kill");
			}
		}
	}
	
	new Float:DetonateOrigin[3];
	DetonateOrigin[0] = GetEventFloat(event, "x"); 
	DetonateOrigin[1] = GetEventFloat(event, "y"); 
	DetonateOrigin[2] = GetEventFloat(event, "z") + 30.0;
	
	for (new i = 1; i <= MaxClients; i++){
		if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientZombie(i)){
			new Float:targetOrigin[3];
			GetClientAbsOrigin(i, targetOrigin);
			
			if (GetVectorDistance(DetonateOrigin, targetOrigin) <= freezedistance){
				new Handle:trace = TR_TraceRayFilterEx(DetonateOrigin, targetOrigin, MASK_SHOT, RayType_EndPoint, FilterTarget, i);
			
				if (TR_DidHit(trace)){
					if (TR_GetEntityIndex(trace) == i)
						Freeze(i, freezeduration);
				}else{
					GetClientEyePosition(i, targetOrigin);
					targetOrigin[2] -= 1.0;
			
					if (GetVectorDistance(DetonateOrigin, targetOrigin) <= freezedistance){
						new Handle:trace2 = TR_TraceRayFilterEx(DetonateOrigin, targetOrigin, MASK_SHOT, RayType_EndPoint, FilterTarget, i);
				
						if (TR_DidHit(trace2)){
							if (TR_GetEntityIndex(trace2) == i)
								Freeze(i, freezeduration);
						}
						CloseHandle(trace2);
					}
				}
				CloseHandle(trace);
			}
		}
	}
	
	TE_SetupBeamRingPoint(DetonateOrigin, 10.0, freezedistance, g_beamsprite, g_halosprite, 1, 10, 1.0, 5.0, 1.0, FreezeColor, 0, 0);
	TE_SendToAll();
	LightCreate(SMOKE, DetonateOrigin);
}*/


