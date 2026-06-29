#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <colors>

#define CLASS_SCOUT 1 
#define CLASS_SOLDIER 2
#define CLASS_PYRO 3
#define CLASS_DEMOMAN 4
#define CLASS_HEAVY 5
#define CLASS_ENGINEER 6
#define CLASS_MEDIC 7
#define CLASS_SNIPER 8
#define CLASS_SPY 9

//--START Texture stuff
#define	DUEL_RED_VMT	"materials/custom/duel_melee_red.vmt"
#define	DUEL_RED_VTF	"materials/custom/duel_melee_red.vtf"

#define	DUEL_BLU_VMT	"materials/custom/duel_melee_blu.vmt"
#define	DUEL_BLU_VTF	"materials/custom/duel_melee_blu.vtf"

#define TEAM_RED 2
#define TEAM_BLU 3
//--END Texture stuff

#define MAX_ACCEPTABLE_DISTANCE 1048576.0

#define PLUGIN_VERSION "1.2.2"

public Plugin:myinfo = {
	name = "Melee Duel",
	author = "NuclearWatermelon",
	description = "Plays meleedare sounds and makes melee duels.",
	version = PLUGIN_VERSION,
	url = "http://www.critsandvich.com/"
}

/*

Many thanks to EnigmatiK for the original melee dare code,
and to o0whiplash0o for the enhanced sound file selection.

*/

new Float:arr_lastDuel[MAXPLAYERS + 1];
new arr_playerClass[MAXPLAYERS + 1];
new arr_duelPartner[MAXPLAYERS + 1];
//--START Texture stuff
new arr_entList[MAXPLAYERS + 1];
new g_velocityOffset;
//--END Texture stuff

public OnPluginStart() {
	SetConVarString(CreateConVar("sm_meleeduel_version", PLUGIN_VERSION, "Version of the TF2 Melee Duel plugin.", FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_REPLICATED), PLUGIN_VERSION);
	HookEvent("player_spawn", player_spawn);
}

public player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	switch (TF2_GetPlayerClass(client)) {
		case (TFClass_Scout): arr_playerClass[client] = CLASS_SCOUT;
		case (TFClass_Soldier): arr_playerClass[client] = CLASS_SOLDIER;
		case (TFClass_Pyro): arr_playerClass[client] = CLASS_PYRO;
		case (TFClass_DemoMan): arr_playerClass[client] = CLASS_DEMOMAN;
		case (TFClass_Heavy): arr_playerClass[client] = CLASS_HEAVY;
		case (TFClass_Engineer): arr_playerClass[client] = CLASS_ENGINEER;
		case (TFClass_Medic): arr_playerClass[client] = CLASS_MEDIC;
		case (TFClass_Sniper): arr_playerClass[client] = CLASS_SNIPER;
		case (TFClass_Spy): arr_playerClass[client] = CLASS_SPY;
		default: arr_playerClass[client] = 0;
	}
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	arr_duelPartner[client] = 0;
	//--START Texture stuff
	g_velocityOffset = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	//--END Texture stuff
}

//TODO: Hook sentries to save them from damage from dueling persons.
//TODO: Maybe disable the ability for dueling persons to capture points/intel/push cart?  As it stands the distance modifier ought to be enough.
//TODO: NO(Stop medics from healing melee duelers) Disable dueling an ubered opponent.

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if ((attacker == 0) || (victim == 0)) return Plugin_Continue;	
	if (IsClientInGame(victim) && IsClientInGame(attacker)) {
		//Victim is in a duel, but not with his attacker
		if ((arr_duelPartner[victim] > 0) && !(arr_duelPartner[victim] == attacker)) {
			damage = 0.0;
			return Plugin_Changed;
		}
		//Attacker is in a duel, but not with his victim
		if ((arr_duelPartner[attacker] > 0) && !(arr_duelPartner[attacker] == victim)) {
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

//--START Texture stuff
public OnMapStart() {
	AddFileToDownloadsTable(DUEL_RED_VMT);
	PrecacheGeneric(DUEL_RED_VMT, true);

	AddFileToDownloadsTable(DUEL_RED_VTF);
	PrecacheGeneric(DUEL_RED_VTF, true);
	
	AddFileToDownloadsTable(DUEL_BLU_VMT);
	PrecacheGeneric(DUEL_BLU_VMT, true);
	
	AddFileToDownloadsTable(DUEL_BLU_VTF);
	PrecacheGeneric(DUEL_BLU_VTF, true);
}
//--END Texture stuff

public OnGameFrame() {
	decl String:weapon[20], String:melee[20];
	for (new i = 1; i <= MaxClients; i++) {
		//--START Texture stuff
		new ref = arr_entList[i];
		if (ref != 0 && IsClientInGame(i))
		{
			new ent = EntRefToEntIndex(ref);
			if (ent > 0)// && IsClientInGame(i))
			{
				new Float:vOrigin[3];
				GetClientEyePosition(i, vOrigin);
				vOrigin[2] += 30.0;

				new Float:vVelocity[3];
				GetEntDataVector(i, g_velocityOffset, vVelocity);

				TeleportEntity(ent, vOrigin, NULL_VECTOR, vVelocity);
			}
		}
		//--END Texture stuff
		
		//In a duel that is still valid?
		if ((arr_duelPartner[i] > 0) && checkMeleeDuel(i, arr_duelPartner[i])) continue;
		if (!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
		
		//decl String:namei[35];
		//GetClientName(i, namei, 35);
		//PrintToServer("%s has duel partner %d",namei,arr_duelPartner[i]);
		
		if (!arr_playerClass[i] || GetGameTime() < arr_lastDuel[i] + 5.0) continue;
		new slot = GetPlayerWeaponSlot(i, 2);
		if (slot == -1) continue;
		GetEdictClassname(slot, melee, sizeof(melee));
		GetClientWeapon(i, weapon, sizeof(weapon));
		if (StrEqual(weapon, melee)) {
			//PrintToServer("%s has melee out",namei);
			//PrintToConsole(i,"Melee weapon out");
			new team = GetClientTeam(i);
			// vector stuff
			decl Float:pos_i[3], Float:pos_j[3];
			decl Float:vec_i[3], Float:vec_j[3];
			GetClientEyePosition(i, pos_i);
			GetClientEyeAngles(i, vec_i);
			GetAngleVectors(vec_i, vec_i, NULL_VECTOR, NULL_VECTOR);
			// * Check for enemies in FOV * //
			for (new j = 1; j <= MaxClients; j++) {
				// in game? alive? on different team?
				if (IsClientInGame(j) && IsPlayerAlive(j) && GetClientTeam(j) != team) {
					if ((arr_duelPartner[j] > 0) && checkMeleeDuel(j, arr_duelPartner[j])) continue;
					//Got melee?
					slot = GetPlayerWeaponSlot(j, 2);
					if (slot == -1) continue;
					GetEdictClassname(slot, melee, sizeof(melee));
					GetClientWeapon(j, weapon, sizeof(weapon));
					if (!StrEqual(weapon, melee)) continue;
					//if (!(GetEntProp(j, Prop_Send, "m_nPlayerCond") & 16) && TF2_
					if ((TF2_GetPlayerClass(j) == TFClass_Spy) || (TF2_GetPlayerClass(i) == TFClass_Spy)){//If they are both spies...
					continue; // POOT SPY CHECKS HERE
					}
					// get enemy vector
					GetClientEyePosition(j, pos_j);
					MakeVectorFromPoints(pos_i, pos_j, vec_j);
					// is he close to me?
					if (GetVectorLength(vec_j, true) > MAX_ACCEPTABLE_DISTANCE) continue;
					// am I looking at him?
					NormalizeVector(vec_j, vec_j);
					if (GetVectorDotProduct(vec_i, vec_j) < 0.7) continue;
					// is he looking at me?
					GetClientEyeAngles(j, vec_j);
					GetAngleVectors(vec_j, vec_j, NULL_VECTOR, NULL_VECTOR);
					if (GetVectorDotProduct(vec_i, vec_j) > -0.7) continue;
					// do it
					playMeleeDare(i);
					playMeleeDare(j);
					startMeleeDuel(i,j);
					break;
				}
			}
		}
	}
}

startMeleeDuel(i,j) {
	decl String:namei[35];
	decl String:namej[35];
	GetClientName(i, namei, 35);
	GetClientName(j, namej, 35);
	//Let people know what's happening
	CPrintToChat(i, "Melee duel with {green}%s {default}begun!", namej);
	CPrintToChat(j, "Melee duel with {green}%s {default}begun!", namei);
	PrintCenterText(i, "Melee duel started!");
	PrintCenterText(j, "Melee duel started!");
	CPrintToChatAll("{green}%s {default}is in a melee duel with {green}%s{default}!", namei, namej);
	
	//TODO:  Add texture to appear above dueling persons' heads
	createSprite(i);
	createSprite(j);
	
	//Set partner
	arr_duelPartner[i] = j;
	arr_duelPartner[j] = i;
}

checkMeleeDuel(i,j) {
	//If we aren't in a duel, stop
	if (j == 0) return false;
	
	//j left the game, i wins
	if (!IsClientInGame(j)) return endMeleeDuel(i,j,1,1);
	
	//i is dead, j wins
	if (!IsPlayerAlive(i)) return endMeleeDuel(i,j,2,2);
	
	//Some kind of teamswitch happened, duel ended
	if (GetClientTeam(i) == GetClientTeam(j)) return endMeleeDuel(i,j,0,3);
	
	decl String:weapon[20], String:melee[20];
	//Check to see if i still has melee out
	new slot = GetPlayerWeaponSlot(i, 2);
	if (slot == -1) return false;
	GetEdictClassname(slot, melee, sizeof(melee));
	GetClientWeapon(i, weapon, sizeof(weapon));
	//i has a non-melee weapon out.  Duel ended.
	if (!StrEqual(weapon, melee)) return endMeleeDuel(i,j,0,4);
	
	//Check to see if they are still close
	decl Float:pos_i[3], Float:pos_j[3], Float:vec_d[3];
	GetClientEyePosition(i, pos_i);
	GetClientEyePosition(j, pos_j);
	MakeVectorFromPoints(pos_i, pos_j, vec_d);
	//i and j are too far, someone is a baby
	if (GetVectorLength(vec_d, true) > MAX_ACCEPTABLE_DISTANCE) return endMeleeDuel(i,j,0,5);
	
	return true;
}

endMeleeDuel(i,j,winner,endcond) {
/*
winner values
0 - none
1 - i
2 - j

endcond values
1 - Player left game
2 - Player dead (win condition)
3 - Team switch
4 - Player changed away from melee weapon
5 - Someone ran away
*/

	decl String:namei[35];
	decl String:namej[35];
	GetClientName(i, namei, 35);
	GetClientName(j, namej, 35);

	decl String:gAnnounce[128];
	decl String:iAnnounce[128];
	decl String:iAnnounceC[128];
	decl String:jAnnounce[128];
	decl String:jAnnounceC[128];

	switch (winner) {
		case(0): {
			FormatEx(gAnnounce, sizeof(gAnnounce), "No winner in the melee duel between {green}%s {default}and {green}%s{default}.", namei, namej);
			iAnnounceC = "No winner!";
			jAnnounceC = "No winner!";
		}
		case(1): {
			FormatEx(gAnnounce, sizeof(gAnnounce), "{green}%s {default}won the melee duel against {green}%s{default}!", namei, namej);
			iAnnounceC = "You win!";
			jAnnounceC = "You failed!";
		}
		case(2): {
			FormatEx(gAnnounce, sizeof(gAnnounce), "{green}%s {default}won the melee duel against {green}%s{default}!", namej, namei);
			iAnnounceC = "You failed!";
			jAnnounceC = "You win!";
		}
		default: gAnnounce = "General error #1";
	}
	
	//TODO: More variation for the silly stuff?  Something with a GetRandomInt perhaps?
	switch (endcond) {
		case(1): {
			if (IsClientInGame(i)) {
				FormatEx(iAnnounce, sizeof(iAnnounce), "{green}%s {default}left the game.  Duel canceled.", namej);
			}
			else {
				FormatEx(iAnnounce, sizeof(iAnnounce), "{green}%s {default}left the game.  Duel canceled.", namei);
			}
		}
		case(2): {
			if (IsPlayerAlive(i)) {
				iAnnounce = "You are victorious!";
				jAnnounce = "You failed.  Don't do it again.";
			}
			else {
				jAnnounce = "You are victorious!";
				iAnnounce = "You failed.  Don't do it again.";
			}
		}
		case(3): {
			iAnnounce = "Teamswitch occured.  Duel canceled.";
			jAnnounce = "Teamswitch occured.  Duel canceled.";
		}
		case(4): {
			iAnnounce = "You changed away from your melee weapon!  Coward!";
			FormatEx(jAnnounce, sizeof(jAnnounce), "{green}%s {default}changed away from his melee weapon!  He was a whimp anyway.", namei);
		}
		case(5): {
			FormatEx(iAnnounce, sizeof(iAnnounce), "You and {green}%s {default}are too far away.  Duel canceled.", namej);
			FormatEx(jAnnounce, sizeof(jAnnounce), "You and {green}%s {default}are too far away.  Duel canceled.", namei);
		}
		default: {
			iAnnounce = "General error #2";
			jAnnounce = "General error #2";
		}
	}
	
	//Check to see if they're still around, dump them some information.
	if (IsClientInGame(i)) {
		CPrintToChat(i,iAnnounce);
		PrintCenterText(i,iAnnounceC);
	}
	if (IsClientInGame(j)) {
		CPrintToChat(j,jAnnounce);
		PrintCenterText(j,jAnnounceC);
	}
	
	CPrintToChatAll(gAnnounce);
	
	//Reset duel partners, duel is over
	arr_duelPartner[i] = 0;
	arr_duelPartner[j] = 0;
	
	killSprite(i);
	killSprite(j);
	
	//Set time at end of duel
	arr_lastDuel[i] = GetGameTime();
	arr_lastDuel[j] = GetGameTime();
	
	//Always return false on an endMeleeDuel condition to force the loop in OnGameFrame to continue
	return false;
}

playMeleeDare(client) {
	decl String:path[50];
	switch (arr_playerClass[client]) {
		case (CLASS_SCOUT):    FormatEx(path, sizeof(path), "vo/scout_meleedare%02d.wav", GetRandomInt(1, 6));
		case (CLASS_SOLDIER):  FormatEx(path, sizeof(path), "vo/soldier_PickAxeTaunt%02d.wav", GetRandomInt(1, 5));
		case (CLASS_PYRO):     FormatEx(path, sizeof(path), "vo/pyro_autodejectedtie01.wav");
		case (CLASS_DEMOMAN): 
			switch (GetRandomInt(0, 1)) {
				case 0: FormatEx(path, sizeof(path), "vo/demoman_eyelandertaunt%02d.wav", GetRandomInt(1, 2));
				case 1: FormatEx(path, sizeof(path), "vo/demoman_autocappedintelligence02.wav");
			}
		case (CLASS_HEAVY):    FormatEx(path, sizeof(path), "vo/heavy_meleedare%02d.wav", GetRandomInt(1, 13));
		case (CLASS_ENGINEER): FormatEx(path, sizeof(path), "vo/engineer_meleedare%02d.wav", GetRandomInt(1, 3));
		case (CLASS_MEDIC):
			switch (GetRandomInt(0, 2)) {
				case 0: FormatEx(path, sizeof(path), "vo/medic_autocappedcontrolpoint03.wav");
				case 1: FormatEx(path, sizeof(path), "vo/medic_autodejectedtie02.wav");
				case 2: FormatEx(path, sizeof(path), "vo/medic_specialcompleted02.wav");
			}
		case (CLASS_SNIPER):   FormatEx(path, sizeof(path), "vo/sniper_meleedare%02d.wav", GetRandomInt(1, 9));
		//Spy is currently disabled, this should never really come up
		case (CLASS_SPY):      FormatEx(path, sizeof(path), "vo/spy_meleedare%02d.wav", GetRandomInt(1, 2));
	}
	if (!strlen(path)) return; // hmm. (client must be invalid!)
	PrecacheSound(path);
	EmitSoundToAll(path, client, SNDCHAN_VOICE);
}

stock createSprite(client) {
	new ent = CreateEntityByName("env_sprite_oriented");
	if (ent) {
		decl String:sprite[40];
		decl String:spriteName[16];
		new team = GetClientTeam(client);
		
		if (team == TEAM_RED) {
			sprite = DUEL_RED_VMT;
			spriteName = "duel_red_spr";
		}
		else {
			sprite = DUEL_BLU_VMT;
			spriteName = "duel_blu_spr";
		}
		
		DispatchKeyValue(ent, "model", sprite);
		DispatchKeyValue(ent, "classname", "env_sprite_oriented");
		DispatchKeyValue(ent, "spawnflags", "1");
		DispatchKeyValue(ent, "scale", "0.1");
		DispatchKeyValue(ent, "rendermode", "1");
		DispatchKeyValue(ent, "rendercolor", "255 255 255");
		DispatchKeyValue(ent, "targetname", spriteName);
		DispatchSpawn(ent);

		new Float:vOrigin[3];
		GetClientEyePosition(client, vOrigin);

		vOrigin[2] += 30.0;

		TeleportEntity(ent, vOrigin, NULL_VECTOR, NULL_VECTOR);
		arr_entList[client] = EntIndexToEntRef(ent);

		SetEntityMoveType(ent, MOVETYPE_NOCLIP);
	}
}

stock killSprite(client) {
	new ref = arr_entList[client];
	if (ref != 0)
	{
		new ent = EntRefToEntIndex(ref);
		if (ent > 0 && IsValidEntity(ent))
		{
			AcceptEntityInput(ent, "kill");
		}
		arr_entList[client] = 0;
	}
}
