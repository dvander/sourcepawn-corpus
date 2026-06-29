#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>
#include "zr/tools_functions"

#define PLUGIN_VERSION "1.0"

#define NADE_PRICE 1000
#define NADE_DISTANCE 600
#define NADE_COLOR	{255,255,255,255}
#define SND_BUYNADE "items/itempickup.wav"
#define SND_CANTBUY "buttons/weapon_cant_buy.wav"

new maxents;
new g_beamsprite, g_halosprite;
new nade_count[MAXPLAYERS+1];
new gAccount = -1;

// P L U G I N    I N F O
public Plugin:myinfo = {
	name = "[ZR] Antidote Nade",
	author = "nicekill.com",
	description = "Grenade that changes zombies into humans",
	version = PLUGIN_VERSION,
	url = "http://www.nicekill.com/"
};

// Fires when the plugin start
public OnPluginStart(){
	// Creates console variable version
	//CreateConVar("zr_anti_nade_version", PLUGIN_VERSION, "The version of the plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	// Hooks event changes
	HookEvent("hegrenade_detonate", NadeDetonate);
	
	// Registers new console commands
	RegConsoleCmd("sm_anti_nade", Command_BuyNade, "Buy an antidote nade.");

	if ((gAccount = FindSendPropOffs("CCSPlayer", "m_iAccount")) == -1){
		SetFailState("Could not find offset \"m_iAccount\"");
	}

	// Loads the translation
	LoadTranslations("zr_anti_nade");
}
// Fires when the map starts
public OnMapStart(){
	g_beamsprite = PrecacheModel("materials/sprites/lgtning.vmt");
	g_halosprite = PrecacheModel("materials/sprites/halo01.vmt");

	PrecacheSound(SND_BUYNADE, true);
	PrecacheSound(SND_CANTBUY, true);
}
// Fires when the client disconnects
public OnClientDisconnect(client){
	nade_count[client] = 0;
}
// client wants to buy an anti nade
public Action:Command_BuyNade(client, argc){
	if (!client || !IsClientInGame(client)){return Plugin_Continue;}
	if (!IsPlayerAlive(client)){		PrintHintText(client, "%t", "Can't buy while dead"); return Plugin_Handled;}
	if (GetClientTeam(client) <= 1){	PrintHintText(client, "%t", "Can't buy while spec"); return Plugin_Handled;}
	if (ZR_IsClientZombie(client)){		PrintHintText(client, "%t", "Can't buy while zombie"); return Plugin_Handled;}
	
	// purchase
	new money = GetEntData(client, gAccount);
	if (money < NADE_PRICE){
		PrintHintText(client, "%t", "Can't buy low money");
		EmitSoundToClient(client, SND_CANTBUY);
		return Plugin_Handled;
	}

     // trade money for the nade
	money -= NADE_PRICE;
	SetEntData(client, gAccount, money);

	nade_count[client]++;
	GivePlayerItem(client, "weapon_hegrenade");

	PrintHintText(client, "%t", "Bought nade");
	EmitSoundToClient(client, SND_BUYNADE);

	return Plugin_Handled;
}

// he grenade detonated
public Action:NadeDetonate(Handle:event, const String:name[], bool:dontBroadcast) {
	decl String:EdictName[64];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// does the client have an anti-nade?
	if(nade_count[client] > 0){
		nade_count[client]--;
	}else{
		return;
	}
	
	// kill the grenade
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
	
	// location where the grenade detonated
	new Float:DetonateOrigin[3];
	DetonateOrigin[0] = GetEventFloat(event, "x"); 
	DetonateOrigin[1] = GetEventFloat(event, "y"); 
	DetonateOrigin[2] = GetEventFloat(event, "z") + 30.0;
	
     // check each player
	for (new victim = 1; victim <= MaxClients; victim++){
		if (IsClientInGame(victim) && IsPlayerAlive(victim) && ZR_IsClientZombie(victim)){
			new Float:targetOrigin[3];
			GetClientAbsOrigin(victim, targetOrigin);

			// if zombie within distance of the infect blast
			if (GetVectorDistance(DetonateOrigin, targetOrigin) <= NADE_DISTANCE){
				// turn zombie into a human
				ZR_HumanClient(victim, false, false);

		     	   	// Create and send custom player_death event.
       			new Handle:death_event = CreateEvent("player_death");
        			if (event != INVALID_HANDLE){
            			SetEventInt(death_event, "userid", GetClientUserId(victim));
            			SetEventInt(death_event, "attacker", GetClientUserId(client));
            			SetEventString(death_event, "weapon", "Antidote Nade");
            			FireEvent(death_event, false);
        			}
        
        			// Give human a score point.
        			new score = ToolsClientScore(client, true, false);
        			ToolsClientScore(client, true, true, ++score);
        
        			// Give zombie a death point.
        			new deaths = ToolsClientScore(victim, false, false);
        			ToolsClientScore(victim, false, true, ++deaths);
			}
		}
	}
	
	// special effects
	TE_SetupBeamRingPoint(DetonateOrigin, 10.0, NADE_DISTANCE, g_beamsprite, g_halosprite, 1, 10, 1.0, 5.0, 1.0, NADE_COLOR, 0, 0);
	TE_SendToAll();

	new iEntity = CreateEntityByName("light_dynamic");
	DispatchKeyValue(iEntity, "inner_cone", "0");
	DispatchKeyValue(iEntity, "cone", "80");
	DispatchKeyValue(iEntity, "brightness", "1");
	DispatchKeyValueFloat(iEntity, "spotlight_radius", 150.0);
	DispatchKeyValue(iEntity, "pitch", "90");
	DispatchKeyValue(iEntity, "style", "1");

	DispatchKeyValue(iEntity, "_light", "255 255 255 255");
	DispatchKeyValueFloat(iEntity, "distance", NADE_DISTANCE);
	//EmitSoundToAll(SOUND_FREEZE_EXPLODE, iEntity, SNDCHAN_WEAPON);
	CreateTimer(1.0, Delete, iEntity, TIMER_FLAG_NO_MAPCHANGE);

	DispatchSpawn(iEntity);
	TeleportEntity(iEntity, DetonateOrigin, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEntity, "TurnOn");
}
public Action:Delete(Handle:timer, any:entity){
	if(IsValidEdict(entity)){
		AcceptEntityInput(entity, "kill");
	}
}


