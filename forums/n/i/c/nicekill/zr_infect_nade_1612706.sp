#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>

#include <helpers>
#include <functions>

//#include "zr/weapons/restrict"

#define PLUGIN_VERSION "1.0"

#define NADE_PRICE 1000
#define NADE_DISTANCE 600
#define NADE_COLOR	{75,255,75,255}
#define SND_BUYNADE "items/itempickup.wav"
#define SND_CANTBUY "buttons/weapon_cant_buy.wav"
/**
 * Maximum length of a weapon name string
 */
#define WEAPONS_MAX_LENGTH 32

new Handle:h_zr_plugin;
//new Function:h_RestrictOnClientDisconnect;
new Function:h_RestrictCanUse;
new h_return_result;

new maxents;
new g_beamsprite, g_halosprite;
new i_clients_amount[MAXPLAYERS+1];
new gAccount = -1;

// P L U G I N    I N F O
public Plugin:myinfo = {
	name = "[ZR] Infect Nade",
	author = "nicekill.com",
	description = "Grenade for zombies used for infecting humans",
	version = PLUGIN_VERSION,
	url = "http://www.nicekill.com/"
};

// Fires when the plugin start
public OnPluginStart(){
	// Creates console variable version
	//CreateConVar("zr_infect_nade_version", PLUGIN_VERSION, "The version of the plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	// Hooks event changes
	//HookEvent("player_death", OnPlayerDeath);
	HookEvent("hegrenade_detonate", NadeDetonate);
	
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
	g_beamsprite = PrecacheModel("materials/sprites/lgtning.vmt");
	g_halosprite = PrecacheModel("materials/sprites/halo01.vmt");

	PrecacheSound(SND_BUYNADE, true);
	PrecacheSound(SND_CANTBUY, true);

     // get a reference to the ZR plugin
     h_zr_plugin = FindPluginByFile("zombiereloaded.smx");
     //h_RestrictOnClientDisconnect = GetFunctionByName(h_zr_plugin, "RestrictOnClientDisconnect");
     h_RestrictCanUse = GetFunctionByName(h_zr_plugin, "RestrictCanUse");
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
     SDKUnhook(client, SDKHook_WeaponCanUse, h_RestrictCanUse);
     //g_iCanUseHookID[client] = -1;
     //Call_StartFunction(h_zr_plugin, h_RestrictOnClientDisconnect);
     //Call_PushCell(client);
     //Call_Finish(h_return_result);
     // replace with zr_nade_RestrictCanUse
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
    // If the player is a zombie
    if (ZR_IsClientZombie(client)){
        new String:weaponentity[WEAPONS_MAX_LENGTH];
        GetEdictClassname(weapon, weaponentity, sizeof(weaponentity));

        // if weapon is a grenade
        if(StrEqual(weaponentity, "weapon_hegrenade")){
            SDKUnhook(client, SDKHook_WeaponCanUse, h_RestrictCanUse);
       	 return Plugin_Continue;
        }
        //return Plugin_Handled;
    }

    // let ZR handle this
    // return RestrictCanUse(client, weapon);
    Call_StartFunction(h_zr_plugin, h_RestrictCanUse);
    Call_PushCell(client);
    Call_PushCell(weapon);
    Call_Finish(h_return_result);
    return h_return_result;
}
// he grenade detonated
public Action:NadeDetonate(Handle:event, const String:name[], bool:dontBroadcast) {
	decl String:EdictName[64];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

     // If the owner is human
	//if (ZR_IsClientHuman(client)){return;}
	
	maxents = GetMaxEntities();
	
	for (new edict = MaxClients; edict <= maxents; edict++){
		if (IsValidEdict(edict))		{
			GetEdictClassname(edict, EdictName, sizeof(EdictName));
			if (!strcmp(EdictName, "hegrenade_projectile", false)){
				if (GetEntPropEnt(edict, Prop_Send, "m_hThrower") == client){
					AcceptEntityInput(edict, "Kill");
                     }
			}
		}
	}
	
	new Float:DetonateOrigin[3];
	DetonateOrigin[0] = GetEventFloat(event, "x"); 
	DetonateOrigin[1] = GetEventFloat(event, "y"); 
	DetonateOrigin[2] = GetEventFloat(event, "z") + 30.0;
	
     // check each player
	for (new i = 1; i <= MaxClients; i++){
		if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i)){
			new Float:targetOrigin[3];
			GetClientAbsOrigin(i, targetOrigin);

			// human player within distance of the infect blast
			if (GetVectorDistance(DetonateOrigin, targetOrigin) <= NADE_DISTANCE){
				ZR_InfectClient(i, client, false, false, false);
			}
		}
	}
	
	TE_SetupBeamRingPoint(DetonateOrigin, 10.0, NADE_DISTANCE, g_beamsprite, g_halosprite, 1, 10, 1.0, 5.0, 1.0, NADE_COLOR, 0, 0);
	TE_SendToAll();
}


