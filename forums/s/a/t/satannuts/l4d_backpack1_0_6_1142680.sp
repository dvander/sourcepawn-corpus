#pragma semicolon 1
#include <sourcemod>
#include <string>
#include <sdktools>
#include <timers>
#define PLUGIN_VERSION "1.0.6"


/******
* TODO
*******
* - Expand Backpack to include Slot 0 & Slot 1(Primary & Secondary)
* - Add Weight/Amount limits
* - Add Encumberance slowdown
* - Add Unrecoverable items on death
* - Add cvars for controlling plugin
* - Add support for Co-op
* + Add Quick Select Commands
* - Improve Item Resupply Logic
* - Improve Pills Usage Logic
* - Improve Grenade Usage Logic
* - Add Drop command
* - Add Admin View Command
* - Add Admin Give Command
* - Make L4D1 Compatible
******************
* Version History
******************
* 1.0
*  - Initial Release
* 1.1
*  - Added Quick Select Commands
*/

//Initialise Variables

/* Player Identifier - Used to carry packs between maps in Co-op */

new Handle:hGame_Mode = INVALID_HANDLE;
new String:pack_store[MAXPLAYERS+1][36];
//GetClientAuthString
new iGame_Mode;

/* Backpack Contents - Stores player amounts of each item in their backpack */
new pack_mols[MAXPLAYERS+1];							//Molotovs
new pack_pipes[MAXPLAYERS+1];							//Pipebombs
new pack_biles[MAXPLAYERS+1];							//Bile Bombs
new pack_kits[MAXPLAYERS+1];							//First Aid Kits
new pack_defibs[MAXPLAYERS+1];							//Defibrillator
new pack_firepacks[MAXPLAYERS+1];						//Incendiary Ammo Packs
new pack_explodepacks[MAXPLAYERS+1];					//Explosive Ammo Packs
new pack_pills[MAXPLAYERS+1];							//Pain Pills
new pack_adrens[MAXPLAYERS+1];							//Adrenaline

/* Solt Selections - Stores current item choice for each slot */
new pack_slot2[MAXPLAYERS+1];							//Grenade Selection
new pack_slot3[MAXPLAYERS+1];							//Kit Selection
new pack_slot4[MAXPLAYERS+1];							//Pills Selection

/* Misc. Fixes - Used to fix various event problems/issues */
new bool:item_pickup[MAXPLAYERS+1];						//Set in Event_ItemPickup to skip Event_PlayerUse
new item_drop[MAXPLAYERS+1];							//Set in Event_WeaponDrop to prevent items getting "reused"
new bool:pills_used[MAXPLAYERS+1];						//Set in Event_PillsUsed to skip Event_WeaponDrop
new pills_owner[MAXPLAYERS+1];							//Set in Event_WeaponDrop to handle passing pills/adren
new Handle:nadetimer[MAXPLAYERS+1] = INVALID_HANDLE;	//Timer to resupply players after they use grenades

public Plugin:myinfo = {
	name = "Backpack",
	author = "Oshroth",
	description = "Allows you to carry extra items in your backpack.",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public OnPluginStart() {
	decl String:game[12];
	new Handle:pack_version = INVALID_HANDLE;
	decl String:sGame_Mode[32];
	
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead2") == -1) SetFailState("Backpack will only work with Left 4 Dead 2!");
	
	/* Game Mode Hook */
	hGame_Mode = FindConVar("mp_gamemode");
	HookConVarChange(hGame_Mode, ConVarChange_GameMode);
	
	GetConVarString(hGame_Mode, sGame_Mode, sizeof(sGame_Mode));
	
	if(StrContains(sGame_Mode, "coop") != -1) {
		iGame_Mode = 1;
	}
	if(StrContains(sGame_Mode, "realism") != -1) {
		iGame_Mode = 2;
	}
	if(StrContains(sGame_Mode, "versus") != -1) {
		iGame_Mode = 3;
	}
	if(StrContains(sGame_Mode, "scavenge") != -1) {
		iGame_Mode = 4;
	}
	if(StrContains(sGame_Mode, "teamversus") != -1) {
		iGame_Mode = 5;
	}
	if(StrContains(sGame_Mode, "teamscavenge") != -1) {
		iGame_Mode = 6;
	}
	if(StrContains(sGame_Mode, "survival") != -1) {
		iGame_Mode = 7;
	}
	
	
	RegConsoleCmd("pack", PackMenu);
	RegAdminCmd("pack_view", AdminViewMenu, ADMFLAG_GENERIC, "Allows admins to view player backpacks");
	
	/* Event Hooks */
	HookEvent("round_start", Event_RoundStart); 		//Used to reset all backpacks at start of round
	HookEvent("item_pickup", Event_ItemPickup);			//Used to handle item pickups
	HookEvent("player_use", Event_PlayerUse); 			//Used to pick up extra items
	HookEvent("weapon_drop", Event_WeaponDrop);			//Used to catch item drops
	HookEvent("player_death", Event_PlayerDeath); 		//Used to drop player's items on death
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_win", Event_FinaleWin);
	HookEvent("mission_lost", Event_MissionLost);
	
	/* Item Use Events */
	HookEvent("heal_success", Event_KitUsed); 			//Used to catch when someone uses a kit
	HookEvent("defibrillator_used", Event_KitUsed); 	//Used to catch when someone uses a defib
	HookEvent("upgrade_pack_used",Event_KitUsed); 		//Used to catch when someone deploys a ammo pack
	HookEvent("pills_used", Event_PillsUsed); 			//Used to catch when someone uses pills
	HookEvent("adrenaline_used", Event_PillsUsed); 		//Used to catch when someone uses adrenaline
	
	/* Backpack Changeover */
	HookEvent("bot_player_replace", Event_BotToPlayer); //Used to give a leaving Bot's pack to a joining player
	HookEvent("player_bot_replace", Event_PlayerToBot); //Used to give a leaving player's pack to a joining Bot
	
	pack_version = CreateConVar("l4d_backpack_version", PLUGIN_VERSION, "Backpack plugin version.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	AutoExecConfig();
	
	SetConVarString(pack_version, PLUGIN_VERSION, true);
	
}
// +New player joins server
// +Existing player rejoins server
// +Player leaves server
// Team wins map
// Team loses map
// Team beats finale

public OnClientPutInServer(client) {
	CreateTimer(60.0, Timer_WelcomeMessage, client);
}
/*public OnClientAuthorized(client, const String:auth[]) {
new i;
decl String:temp[10][64];

if(iGame_Mode == 1) {
for(i = 1; i <= MAXPLAYERS + 1; i++) {
if(StrContains(pack_id[i], auth) != -1) {
ExplodeString(pack_store[i], " ", temp, 10, 64);
pack_mols[client] = StringToInt(temp[1]);
pack_pipes[client] = StringToInt(temp[2]);
pack_biles[client] = StringToInt(temp[3]);
pack_kits[client] = StringToInt(temp[4]);
pack_defibs[client] = StringToInt(temp[5]);
pack_firepacks[client] = StringToInt(temp[6]);
pack_explodepacks[client] = StringToInt(temp[7]);
pack_pills[client] = StringToInt(temp[8]);
pack_adrens[client] = StringToInt(temp[9]);
return;
}
}
}
}*/

public Action:Timer_WelcomeMessage(Handle:timer, any:client) {
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client)) {
		PrintToChat(client, "\x01[SM] Survivors can carry extra items in their backpack.");
		PrintToChat(client, "\x01[SM] To access your backpack, type \x04!pack\x01 in chat.");
		PrintToChat(client, "\x01[SM] You can quick-select items by typing \x04!pack <item no.>\x01 in chat.");
	}
}

public ConVarChange_GameMode(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	decl String:sGame_Mode[32];
	
	GetConVarString(hGame_Mode, sGame_Mode, sizeof(sGame_Mode));
	
	if(StrContains(sGame_Mode, "coop") != -1) {
		iGame_Mode = 1;
	}
	if(StrContains(sGame_Mode, "realism") != -1) {
		iGame_Mode = 2;
	}
	if(StrContains(sGame_Mode, "versus") != -1) {
		iGame_Mode = 3;
	}
	if(StrContains(sGame_Mode, "scavenge") != -1) {
		iGame_Mode = 4;
	}
	if(StrContains(sGame_Mode, "teamversus") != -1) {
		iGame_Mode = 5;
	}
	if(StrContains(sGame_Mode, "teamscavenge") != -1) {
		iGame_Mode = 6;
	}
	if(StrContains(sGame_Mode, "survival") != -1) {
		iGame_Mode = 7;
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	new i;
	
	if(iGame_Mode == 1 || iGame_Mode == 2) {
		//Coop - Don't delete pack
		return Plugin_Continue;
	}
	for(i = 0; i <= MAXPLAYERS; i++) {
		pack_mols[i] = 0;
		pack_pipes[i] = 0;
		pack_biles[i] = 0;
		pack_kits[i] = 0;
		pack_defibs[i] = 0;
		pack_firepacks[i] = 0;
		pack_explodepacks[i] = 0;
		pack_pills[i] = 0;
		pack_adrens[i] = 0;
		pack_slot2[i] = 0;
		pack_slot3[i] = 0;
		pack_slot4[i] = 0;
		item_drop[i] = 0;
		pills_owner[i] = 0;
		pills_used[i] = false;
		item_pickup[i] = false;
		nadetimer[i] = INVALID_HANDLE;
	}
	return Plugin_Continue;
}

public Action:Event_ItemPickup(Handle:event, const String:name[], bool:dontBroadcast) {
	new userId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userId);
	decl String:item[64];
	GetEventString(event, "item", item, sizeof(item));
	item_drop[client] = 0;
	#if defined DEBUG
	PrintToChatAll("[DEBUG] %d called ItemPickup. Item = %s", client, item);
	#endif
	if(StrContains(item, "molotov", false) != -1) {
		if(nadetimer[client] != INVALID_HANDLE) {
			KillTimer(nadetimer[client]);
			nadetimer[client] = INVALID_HANDLE;
			GrenadeRemove(client);
		}
		pack_slot2[client] = 1;
		#if defined DEBUG
		PrintToChatAll("[DEBUG] %d changed slot2 to %d", client, pack_slot2[client]);
		#endif
	}
	if(StrContains(item, "pipe_bomb", false) != -1) {
		if(nadetimer[client] != INVALID_HANDLE) {
			KillTimer(nadetimer[client]);
			nadetimer[client] = INVALID_HANDLE;
			GrenadeRemove(client);
		}
		pack_slot2[client] = 2;
		#if defined DEBUG
		PrintToChatAll("[DEBUG] %d changed slot2 to %d", client, pack_slot2[client]);
		#endif
	}
	if(StrContains(item, "vomitjar", false) != -1) {
		if(nadetimer[client] != INVALID_HANDLE) {
			KillTimer(nadetimer[client]);
			nadetimer[client] = INVALID_HANDLE;
			GrenadeRemove(client);
		}
		pack_slot2[client] = 3;
		#if defined DEBUG
		PrintToChatAll("[DEBUG] %d changed slot2 to %d", client, pack_slot2[client]);
		#endif
	}
	if(StrContains(item, "first_aid_kit", false) != -1) {
		pack_slot3[client] = 1;
		#if defined DEBUG
		PrintToChatAll("[DEBUG] %d changed slot3 to %d", client, pack_slot3[client]);
		#endif
	}
	if(StrContains(item, "defibrillator", false) != -1) {
		pack_slot3[client] = 2;
		#if defined DEBUG
		PrintToChatAll("[DEBUG] %d changed slot3 to %d", client, pack_slot3[client]);
		#endif
	}
	if(StrContains(item, "upgradepack_incendiary", false) != -1) {
		pack_slot3[client] = 3;
		#if defined DEBUG
		PrintToChatAll("[DEBUG] %d changed slot3 to %d", client, pack_slot3[client]);
		#endif
	}
	if(StrContains(item, "upgradepack_explosive", false) != -1) {
		pack_slot3[client] = 4;
		#if defined DEBUG
		PrintToChatAll("[DEBUG] %d changed slot3 to %d", client, pack_slot3[client]);
		#endif
	}
	if(StrContains(item, "pain_pills", false) != -1) {
		pack_slot4[client] = 1;
		if(pills_owner[client] != 0) {
			CreateTimer(1.0, GivePills, pills_owner[client]);
			pills_owner[client] = 0;
		}
		#if defined DEBUG
		PrintToChatAll("[DEBUG] %d changed slot4 to %d", client, pack_slot4[client]);
		#endif
	}
	if(StrContains(item, "adrenaline", false) != -1) {
		pack_slot4[client] = 2;
		if(pills_owner[client] != 0) {
			CreateTimer(1.0, GivePills, pills_owner[client]);
			pills_owner[client] = 0;
		}
		#if defined DEBUG
		PrintToChatAll("[DEBUG] %d changed slot4 to %d", client, pack_slot4[client]);
		#endif
	}
	item_pickup[client] = true;
	return Plugin_Continue;
}

public Action:Event_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast) {
	new userId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userId);
	decl String:item[64];
	new targetid;
	if(item_pickup[client]) {
		item_pickup[client] = false;
		return Plugin_Continue;
	}
	targetid = GetEventInt(event, "targetid");
	GetEdictClassname(targetid, item, sizeof(item));
	if(StrContains(item, "molotov", false) != -1) {
		AcceptEntityInput(targetid, "Kill");
		pack_mols[client] += 1;
	}
	if(StrContains(item, "pipe_bomb", false) != -1) {
		AcceptEntityInput(targetid, "Kill");
		pack_pipes[client] += 1;
	}
	if(StrContains(item, "vomitjar", false) != -1) {
		AcceptEntityInput(targetid, "Kill");
		pack_biles[client] += 1;
	}
	if(StrContains(item, "first_aid_kit", false) != -1) {
		pack_slot3[client] = 1; //Catches pregiven kits
		AcceptEntityInput(targetid, "Kill");
		pack_kits[client] += 1;
	}
	if(StrContains(item, "defibrillator", false) != -1) {
		AcceptEntityInput(targetid, "Kill");
		pack_defibs[client] += 1;
	}
	if(StrContains(item, "upgradepack_incendiary", false) != -1) {
		AcceptEntityInput(targetid, "Kill");
		pack_firepacks[client] += 1;
	}
	if(StrContains(item, "upgradepack_explosive", false) != -1) {
		AcceptEntityInput(targetid, "Kill");
		pack_explodepacks[client] += 1;
	}
	if(StrContains(item, "pain_pills", false) != -1) {
		AcceptEntityInput(targetid, "Kill");
		pack_pills[client] += 1;
	}
	if(StrContains(item, "adrenaline", false) != -1) {
		AcceptEntityInput(targetid, "Kill");
		pack_adrens[client] += 1;
	}
	
	return Plugin_Continue;
}

public Action:Event_WeaponDrop(Handle:event, const String:name[], bool:dontBroadcast) {
	new userId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userId);
	new weapon = GetEventInt(event, "propid");
	decl String:item[64];
	GetEventString(event, "item", item, sizeof(item));
	
	if(client <= 0) {
		return Plugin_Continue;
	}
	#if defined DEBUG
	PrintToChatAll("[DEBUG] %d dropped %d - %s", client, weapon, item);
	#endif
	if(StrContains(item, "molotov", false) != -1) {
		if(nadetimer[client] != INVALID_HANDLE) {
			TriggerTimer(nadetimer[client]);
		}
		nadetimer[client] = CreateTimer(0.5, GiveGrenade, client);
	}
	if(StrContains(item, "pipe_bomb", false) != -1) {
		if(nadetimer[client] != INVALID_HANDLE) {
			TriggerTimer(nadetimer[client]);
		}
		nadetimer[client] = CreateTimer(0.5, GiveGrenade, client);
	}
	if(StrContains(item, "vomitjar", false) != -1) {
		if(nadetimer[client] != INVALID_HANDLE) {
			TriggerTimer(nadetimer[client]);
		}
		nadetimer[client] = CreateTimer(0.5, GiveGrenade, client);
	}
	if(StrContains(item, "first_aid_kit", false) != -1) {
		AcceptEntityInput(weapon, "Kill");
		pack_kits[client] += 1;
		item_drop[client] = 4;
	}
	if(StrContains(item, "defibrillator", false) != -1) {
		AcceptEntityInput(weapon, "Kill");
		pack_defibs[client] += 1;
		item_drop[client] = 5;
	}
	if(StrContains(item, "upgradepack_incendiary", false) != -1) {
		AcceptEntityInput(weapon, "Kill");
		pack_firepacks[client] += 1;
		item_drop[client] = 6;
	}
	if(StrContains(item, "upgradepack_explosive", false) != -1) {
		AcceptEntityInput(weapon, "Kill");
		pack_explodepacks[client] += 1;
		item_drop[client] = 7;
	}
	if(pills_used[client]) {
		pills_used[client] = false;
		return Plugin_Continue;
	}	
	if(StrContains(item, "pain_pills", false) != -1) {
		new target = GetClientAimTarget(client);
		if(target < 0) {
			AcceptEntityInput(weapon, "Kill");
			pack_pills[client] += 1;
			item_drop[client] = 8;
			return Plugin_Continue;
		}
		pills_owner[target] = client;
	}
	if(StrContains(item, "adrenaline", false) != -1) {
		new target = GetClientAimTarget(client);
		if(target < 0) {
			AcceptEntityInput(weapon, "Kill");
			pack_adrens[client] += 1;
			item_drop[client] = 9;
			return Plugin_Continue;
		}
		pills_owner[target] = client;
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new userId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userId);
	new Float:victim[3];
	victim[0] = GetEventFloat(event, "victim_x");
	victim[1] = GetEventFloat(event, "victim_y");
	victim[2] = GetEventFloat(event, "victim_z");
	if(client <= 0) {
		return Plugin_Continue;
	}
	#if defined DEBUG
	PrintToChatAll("[DEBUG] %d called PlayerDeath.", client);
	#endif
	SpawnItem(victim, "weapon_molotov", pack_mols[client]);
	pack_mols[client] = 0;
	SpawnItem(victim, "weapon_pipe_bomb", pack_pipes[client]);
	pack_pipes[client] = 0;
	SpawnItem(victim, "weapon_vomitjar", pack_biles[client]);
	pack_biles[client] = 0;
	SpawnItem(victim, "weapon_first_aid_kit", pack_kits[client]);
	pack_kits[client] = 0;
	SpawnItem(victim, "weapon_defibrillator", pack_defibs[client]);
	pack_defibs[client] = 0;
	SpawnItem(victim, "weapon_upgradepack_incendiary", pack_firepacks[client]);
	pack_firepacks[client] = 0;
	SpawnItem(victim, "weapon_upgradepack_explosive", pack_explodepacks[client]);
	pack_explodepacks[client] = 0;
	SpawnItem(victim, "weapon_pain_pills", pack_pills[client]);
	pack_pills[client] = 0;
	SpawnItem(victim, "weapon_adrenaline", pack_adrens[client]);
	pack_adrens[client] = 0;
	pack_slot2[client] = 0;
	pack_slot3[client] = 0;
	pack_slot4[client] = 0;
	item_drop[client] = 0;
	pills_owner[client] = 0;
	pills_used[client] = false;
	item_pickup[client] = false;
	
	return Plugin_Continue;
}

public SpawnItem(const Float:origin[3], const String:item[], const amount) {
	new i;
	new entity;
	for(i = 1; i <= amount; i++) {
		entity = CreateEntityByName(item);
		if(entity == -1) {
			#if defined DEBUG
			PrintToChatAll("[DEBUG] During event PlayerDeath, Entity %s failed to be created.", item);
			#endif
			break;
		}
		if(!DispatchSpawn(entity)) {
			#if defined DEBUG
			PrintToChatAll("[DEBUG] During event PlayerDeath, Entity %s failed to spawn.", item);
			#endif
			continue;
		}
		TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
		#if defined DEBUG
		PrintToChatAll("[DEBUG] During event PlayerDeath, Entity %s was successfully spawned at (%.2f, %.2f, %.2f).", item, origin[0], origin[1], origin[2]);
		#endif
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	new i;
	decl String:line[36];
	
	if(iGame_Mode == 1 || iGame_Mode == 2) {
		for(i = 1; i <= MAXPLAYERS; i++) {
			Format(line, sizeof(line), "%d %d %d %d %d %d %d %d %d", pack_mols[i], pack_pills[i],pack_mols[i], pack_pipes[i], pack_biles[i], pack_kits[i], pack_defibs[i], pack_firepacks[i], pack_explodepacks[i], pack_pills[i], pack_adrens[i]);
			strcopy(pack_store[i], 36, line);
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_FinaleWin(Handle:event, const String:name[], bool:dontBroadcast) {
	new i;
	decl String:line[36];
	
	for(i = 0; i <= MAXPLAYERS; i++) {
		pack_mols[i] = 0;
		pack_pipes[i] = 0;
		pack_biles[i] = 0;
		pack_kits[i] = 0;
		pack_defibs[i] = 0;
		pack_firepacks[i] = 0;
		pack_explodepacks[i] = 0;
		pack_pills[i] = 0;
		pack_adrens[i] = 0;
		pack_slot2[i] = 0;
		pack_slot3[i] = 0;
		pack_slot4[i] = 0;
		item_drop[i] = 0;
		pills_owner[i] = 0;
		pills_used[i] = false;
		item_pickup[i] = false;
		nadetimer[i] = INVALID_HANDLE;
		if(iGame_Mode == 1 || iGame_Mode == 2) {
			Format(line, sizeof(line), "%d %d %d %d %d %d %d %d %d", pack_mols[i], pack_pills[i],pack_mols[i], pack_pipes[i], pack_biles[i], pack_kits[i], pack_defibs[i], pack_firepacks[i], pack_explodepacks[i], pack_pills[i], pack_adrens[i]);
			strcopy(pack_store[i], 36, line);
		}
	}
	return Plugin_Continue;
}

public Action:Event_MissionLost(Handle:event, const String:name[], bool:dontBroadcast) {
	new i;
	new client;
	decl String:temp[9][36];
	
	if(iGame_Mode == 1 || iGame_Mode == 2) {
		for(i = 1; i <= MAXPLAYERS + 1; i++) {
			client = i;
			ExplodeString(pack_store[i], " ", temp, 9, sizeof(temp));
			pack_mols[client] = StringToInt(temp[0]);
			pack_pipes[client] = StringToInt(temp[1]);
			pack_biles[client] = StringToInt(temp[2]);
			pack_kits[client] = StringToInt(temp[3]);
			pack_defibs[client] = StringToInt(temp[4]);
			pack_firepacks[client] = StringToInt(temp[5]);
			pack_explodepacks[client] = StringToInt(temp[6]);
			pack_pills[client] = StringToInt(temp[7]);
			pack_adrens[client] = StringToInt(temp[8]);
		}
	}
}

public GrenadeRemove(any:client) {
	new Float:position[3]; //Current entity position
	decl String:grenade[128]; //Dropped grenade name
	new Float:eyepos[3]; //Client eye position
	new entity = -1; //Stores closest grenade entity/edict
	new Float:distance = 10000.0; //Stores vector distance of closest grenade
	new Float:dist; //Stores vector distance of current grenade
	new slot2 = pack_slot2[client];
	
	GetClientAbsOrigin(client, eyepos);
	switch (slot2) {
		case 1: {
			strcopy(grenade, sizeof(grenade), "weapon_molotov");
		}
		case 2: {
			strcopy(grenade, sizeof(grenade), "weapon_pipe_bomb");
		}
		case 3: {
			strcopy(grenade, sizeof(grenade), "weapon_vomitjar");
		}
		default: {
			#if defined DEBUG
			PrintToChatAll("[DEBUG] Exited RemoveGrenade because %d's slot2 = %d", client, slot2);
			#endif
			/*
			* Hmmm If this comes up it means something has probably
			* gone wrong or someone did something they shouldn't have. 
			* Nothing left to do here except log and return.
			*/
			return;
		}
	}
	for(new i = 0; i <= GetEntityCount(); i++) {
		if(IsValidEntity(i)) {
			decl String:EdictName[128];
			GetEdictClassname(i, EdictName, sizeof(EdictName));
			if(StrContains(EdictName, grenade) != -1) {
				#if defined DEBUG
				PrintToChatAll("[DEBUG] Found %d - %s while looking for last grenade.", i, EdictName);
				#endif
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", position);
				#if defined DEBUG
				PrintToChatAll("[DEBUG] Grenade position (%.2f, %.2f, %.2f) Eye position (%.2f, %.2f, %.2f)", position[0], position[1], position[2], eyepos[0], eyepos[1], eyepos[2]);
				#endif
				dist = FloatAbs(GetVectorDistance(eyepos, position));
				#if defined DEBUG
				PrintToChatAll("[DEBUG] Distance = %f. Shortest Distance = %f", dist, distance);
				#endif
				if((dist < distance) && (dist != 50.0)) { //The grenade found exactly 50 units away is the one you are holding
					distance = dist;
					entity = i;
				}
			}
		}
	}
	if(distance == 10000.0 || entity <= 0) {
		//Last grenade couldn't be found for some reason
		#if defined DEBUG
		PrintToChatAll("[DEBUG] Couldn't find grenade %s for %d", grenade, client);
		#endif
		return;
	}
	#if defined DEBUG
	PrintToChatAll("[DEBUG] Removing Grenade %s at %f distance from %d", grenade, distance, client);
	#endif
	AcceptEntityInput(entity, "Kill");
	switch (slot2) {
		case 1: {
			pack_mols[client] += 1;
		}
		case 2: {
			pack_pipes[client] += 1;
		}
		case 3: {
			pack_biles[client] += 1;
		}
	}
	return;
}

public Action:GiveGrenade(Handle:timer, any:client) {
	if(client <= 0) {
		return;
	}
	#if defined DEBUG
	PrintToChatAll("[DEBUG] %d called GiveGrenade.", client);
	#endif
	nadetimer[client] = INVALID_HANDLE;
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	new entity;
	entity = GetPlayerWeaponSlot(client, 2);
	if(entity <= -1) {
		switch (pack_slot2[client]) {
			case 1: {
				if(pack_mols[client] > 0) {
					FakeClientCommand(client, "give molotov");
					pack_mols[client] -= 1;
				} else {
					pack_slot2[client] = 0;
				}
			}
			case 2: {
				if(pack_pipes[client] > 0) {
					FakeClientCommand(client, "give pipe_bomb");
					pack_pipes[client] -= 1;
				} else {
					pack_slot2[client] = 0;
				}
			}
			case 3: {
				if(pack_biles[client] > 0) {
					FakeClientCommand(client, "give vomitjar");
					pack_biles[client] -= 1;
				} else {
					pack_slot2[client] = 0;
				}
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

public Action:Event_KitUsed(Handle:event, const String:name[], bool:dontBroadcast) {
	new userId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userId);
	new flags = GetCommandFlags("give");
	#if defined DEBUG
	PrintToChatAll("[DEBUG] %d called KitUsed.", client);
	#endif
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	new entity;
	entity = GetPlayerWeaponSlot(client, 3);
	if(entity <= -1) {
		switch (pack_slot3[client]) {
			case 1: {
				if(item_drop[client] == 4) {
					pack_kits[client] -= 1;
				}
				if(pack_kits[client] > 0) {
					FakeClientCommand(client, "give first_aid_kit");
					pack_kits[client] -= 1;
				} else {
					pack_slot3[client] = 0;
				}
			}
			case 2: {
				if(item_drop[client] == 5) {
					pack_defibs[client] -= 1;
				}
				if(pack_defibs[client] > 0) {
					FakeClientCommand(client, "give defibrillator");
					pack_defibs[client] -= 1;
				} else {
					pack_slot3[client] = 0;
				}
			}
			case 3: {
				if(item_drop[client] == 6) {
					pack_firepacks[client] -= 1;
				}
				if(pack_firepacks[client] > 0) {
					FakeClientCommand(client, "give upgradepack_incendiary");
					pack_firepacks[client] -= 1;
				} else {
					pack_slot3[client] = 0;
				}
			}
			case 4: {
				if(item_drop[client] == 7) {
					pack_explodepacks[client] -= 1;
				}
				if(pack_explodepacks[client] > 0) {
					FakeClientCommand(client, "give upgradepack_explosive");
					pack_explodepacks[client] -= 1;
				} else {
					pack_slot3[client] = 0;
				}
			}
		}
		item_drop[client] = 0;
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	return Plugin_Continue;
}

public Action:Event_PillsUsed(Handle:event, const String:name[], bool:dontBroadcast) {
	new userId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userId);
	CreateTimer(1.0, GivePills, client);
	pills_used[client] = true;
	#if defined DEBUG
	PrintToChatAll("[DEBUG] %d called PillsUsed.", client);
	#endif
	return Plugin_Continue;
}

public Action:GivePills(Handle:timer, any:client) {
	#if defined DEBUG
	PrintToChatAll("[DEBUG] %d called GivePills.", client);
	#endif
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	new entity;
	entity = GetPlayerWeaponSlot(client, 4);
	if(entity <= -1) {
		switch (pack_slot4[client]) {
			case 1: {
				if(item_drop[client] == 8) {
					pack_pills[client] -= 1;
				}
				if(pack_pills[client] > 0) {
					FakeClientCommand(client, "give pain_pills");
					pack_pills[client] -= 1;
				} else {
					pack_slot4[client] = 0;
				}
			}
			case 2: {
				if(item_drop[client] == 9) {
					pack_adrens[client] -= 1;
				}
				if(pack_adrens[client] > 0) {
					FakeClientCommand(client, "give adrenaline");
					pack_adrens[client] -= 1;
				} else {
					pack_slot4[client] = 0;
				}
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

public Action:Event_BotToPlayer(Handle:event, const String:name[], bool:dontBroadcast) {
	new bot = GetEventInt(event, "bot");
	new client = GetClientOfUserId(bot);
	new player = GetEventInt(event, "player");
	new client2 = GetClientOfUserId(player);
	new i;
	decl String:line[36];
	
	#if defined DEBUG
	PrintToChatAll("[DEBUG] Bot %d handed control to %d.", client, client2);
	#endif
	
	/* Changeover */
	pack_mols[client2] += pack_mols[client];
	pack_pipes[client2] += pack_pipes[client];
	pack_biles[client2] += pack_biles[client];
	pack_kits[client2] += pack_kits[client];
	pack_defibs[client2] += pack_defibs[client];
	pack_firepacks[client2] += pack_firepacks[client];
	pack_explodepacks[client2] += pack_explodepacks[client];
	pack_pills[client2] += pack_pills[client];
	pack_adrens[client2] += pack_adrens[client];
	pack_slot2[client2] = pack_slot2[client];
	pack_slot3[client2] = pack_slot3[client];
	pack_slot4[client2] = pack_slot4[client];
	item_drop[client2] = 0;
	pills_owner[client2] = 0;
	pills_used[client2] = false;
	item_pickup[client2] = false;
	
	/* Remove Old */
	pack_mols[client] = 0;
	pack_pipes[client] = 0;
	pack_biles[client] = 0;
	pack_kits[client] = 0;
	pack_defibs[client] = 0;
	pack_firepacks[client] = 0;
	pack_explodepacks[client] = 0;
	pack_pills[client] = 0;
	pack_adrens[client] = 0;
	pack_slot2[client] = 0;
	pack_slot3[client] = 0;
	pack_slot4[client] = 0;
	item_drop[client] = 0;
	pills_owner[client] = 0;
	pills_used[client] = false;
	item_pickup[client] = false;
	
	if(iGame_Mode == 1 || iGame_Mode == 2) {
		strcopy(pack_store[client2], 36, pack_store[client]);
		i = client;
		Format(line, sizeof(line), "%d %d %d %d %d %d %d %d %d", pack_mols[i], pack_pills[i],pack_mols[i], pack_pipes[i], pack_biles[i], pack_kits[i], pack_defibs[i], pack_firepacks[i], pack_explodepacks[i], pack_pills[i], pack_adrens[i]);
		strcopy(pack_store[i], 36, line);
	}
	
	return Plugin_Continue;
}


public Action:Event_PlayerToBot(Handle:event, const String:name[], bool:dontBroadcast) {
	new bot = GetEventInt(event, "bot");
	new client2 = GetClientOfUserId(bot);
	new player = GetEventInt(event, "player");
	new client = GetClientOfUserId(player);
	new i;
	decl String:line[36];
	
	#if defined DEBUG
	PrintToChatAll("[DEBUG] %d handed control to Bot %d.", client, client2);
	#endif
	
	/* Changeover */
	pack_mols[client2] += pack_mols[client];
	pack_pipes[client2] += pack_pipes[client];
	pack_biles[client2] += pack_biles[client];
	pack_kits[client2] += pack_kits[client];
	pack_defibs[client2] += pack_defibs[client];
	pack_firepacks[client2] += pack_firepacks[client];
	pack_explodepacks[client2] += pack_explodepacks[client];
	pack_pills[client2] += pack_pills[client];
	pack_adrens[client2] += pack_adrens[client];
	pack_slot2[client2] = pack_slot2[client];
	pack_slot3[client2] = 1;
	pack_slot4[client2] = pack_slot4[client];
	item_drop[client2] = 0;
	pills_owner[client2] = pills_owner[client];
	pills_used[client2] = false;
	item_pickup[client2] = false;
	
	/* Remove Old */
	pack_mols[client] = 0;
	pack_pipes[client] = 0;
	pack_biles[client] = 0;
	pack_kits[client] = 0;
	pack_defibs[client] = 0;
	pack_firepacks[client] = 0;
	pack_explodepacks[client] = 0;
	pack_pills[client] = 0;
	pack_adrens[client] = 0;
	pack_slot2[client] = 0;
	pack_slot3[client] = 0;
	pack_slot4[client] = 0;
	item_drop[client] = 0;
	pills_owner[client] = 0;
	pills_used[client] = false;
	item_pickup[client] = false;
	
	if(iGame_Mode == 1 || iGame_Mode == 2) {
		strcopy(pack_store[client2], 36, pack_store[client]);
		i = client;
		Format(line, sizeof(line), "%d %d %d %d %d %d %d %d %d", pack_mols[i], pack_pills[i],pack_mols[i], pack_pipes[i], pack_biles[i], pack_kits[i], pack_defibs[i], pack_firepacks[i], pack_explodepacks[i], pack_pills[i], pack_adrens[i]);
		strcopy(pack_store[i], 36, line);
	}
	
	return Plugin_Continue;
}


/* HUD Functions */
public Action:PackMenu(client, arg) {
	decl String:sSlot[128];
	new iSlot;
	new entity;
	decl String:EdictName[128];
	new flags = GetCommandFlags("give");
	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	
	if(IsClientInGame(client) && !IsFakeClient(client)) {
		if(GetClientTeam(client) == 2) {
			if(IsPlayerAlive(client)) {
				GetCmdArg(1, sSlot, sizeof(sSlot));
				iSlot = StringToInt(sSlot);
				switch(iSlot) {
					case 1, 2, 3: {
						entity = GetPlayerWeaponSlot(client, 2);
						if(entity > -1) {
							GetEdictClassname(entity, EdictName, sizeof(EdictName));
							if(StrContains(EdictName, "molotov", false) != -1) {
								RemovePlayerItem(client, entity);
								pack_mols[client] += 1;
							}
							if(StrContains(EdictName, "pipe_bomb", false) != -1) {
								RemovePlayerItem(client, entity);
								pack_pipes[client] += 1;
							}
							if(StrContains(EdictName, "vomitjar", false) != -1) {
								RemovePlayerItem(client, entity);
								pack_biles[client] += 1;
							}
						}
						pack_slot2[client] = iSlot;
						switch (iSlot) {
							case 1: {
								if(pack_mols[client] > 0) {
									FakeClientCommand(client, "give molotov");
									pack_mols[client] -= 1;
								} else {
									pack_slot2[client] = 0;
								}
							}
							case 2: {
								if(pack_pipes[client] > 0) {
									FakeClientCommand(client, "give pipe_bomb");
									pack_pipes[client] -= 1;
								} else {
									pack_slot2[client] = 0;
								}
							}
							case 3: {
								if(pack_biles[client] > 0) {
									FakeClientCommand(client, "give vomitjar");
									pack_biles[client] -= 1;
								} else {
									pack_slot2[client] = 0;
								}
							}
						}
					}
					case 4, 5, 6, 7: {
						entity = GetPlayerWeaponSlot(client, 3);
						if(entity > -1) {
							GetEdictClassname(entity, EdictName, sizeof(EdictName));
							if(StrContains(EdictName, "first_aid_kit", false) != -1) {
								RemovePlayerItem(client, entity);
								pack_kits[client] += 1;
							}
							if(StrContains(EdictName, "defibrillator", false) != -1) {
								RemovePlayerItem(client, entity);
								pack_defibs[client] += 1;
							}
							if(StrContains(EdictName, "upgradepack_incendiary", false) != -1) {
								RemovePlayerItem(client, entity);
								pack_firepacks[client] += 1;
							}
							if(StrContains(EdictName, "upgradepack_explosive", false) != -1) {
								RemovePlayerItem(client, entity);
								pack_explodepacks[client] += 1;
							}
						}
						pack_slot2[client] = iSlot - 3;
						switch (iSlot - 3) {
							case 1: {
								if(pack_kits[client] > 0) {
									FakeClientCommand(client, "give first_aid_kit");
									pack_kits[client] -= 1;
								} else {
									pack_slot3[client] = 0;
								}
							}
							case 2: {
								if(pack_defibs[client] > 0) {
									FakeClientCommand(client, "give defibrillator");
									pack_defibs[client] -= 1;
								} else {
									pack_slot3[client] = 0;
								}
							}
							case 3: {
								if(pack_firepacks[client] > 0) {
									FakeClientCommand(client, "give upgradepack_incendiary");
									pack_firepacks[client] -= 1;
								} else {
									pack_slot3[client] = 0;
								}
							}
							case 4: {
								if(pack_explodepacks[client] > 0) {
									FakeClientCommand(client, "give upgradepack_explosive");
									pack_explodepacks[client] -= 1;
								} else {
									pack_slot3[client] = 0;
								}
							}
						}
					}
					case 8, 9: {
						entity = GetPlayerWeaponSlot(client, 4);
						if(entity > -1) {
							GetEdictClassname(entity, EdictName, sizeof(EdictName));
							if(StrContains(EdictName, "pain_pills", false) != -1) {
								RemovePlayerItem(client, entity);
								pack_pills[client] += 1;
							}
							if(StrContains(EdictName, "adrenaline", false) != -1) {
								RemovePlayerItem(client, entity);
								pack_adrens[client] += 1;
							}
						}
						pack_slot4[client] = iSlot - 7;
						switch (iSlot - 7) {
							case 1: {
								if(pack_pills[client] > 0) {
									FakeClientCommand(client, "give pain_pills");
									pack_pills[client] -= 1;
								} else {
									pack_slot4[client] = 0;
								}
							}
							case 2: {
								if(pack_adrens[client] > 0) {
									FakeClientCommand(client, "give adrenaline");
									pack_adrens[client] -= 1;
								} else {
									pack_slot4[client] = 0;
								}
							}
						}
					}
					default: {
						showpackHUD(client);
					}
				}
			} else {
				PrintToChat(client, "You cannot access your Backpack while dead.");
			}
		} else {
			PrintToChat(client, "You cannot access your Backpack when infected.");
		}
	}
	
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	
	return Plugin_Handled;
}


public showpackHUD(client) {
	decl String:line[100];
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Backpack:");
	DrawPanelText(panel, "---------------------");
	Format(line, sizeof(line), "Molotovs: %d", pack_mols[client]);
	if(pack_slot2[client] == 1) StrCat(line, sizeof(line), " (Selected)");
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Pipe Bombs: %d", pack_pipes[client]);
	if(pack_slot2[client] == 2) StrCat(line, sizeof(line), " (Selected)");
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Bile Bombs: %d", pack_biles[client]);
	if(pack_slot2[client] == 3) StrCat(line, sizeof(line), " (Selected)");
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Medkits: %d", pack_kits[client]);
	if(pack_slot3[client] == 1) StrCat(line, sizeof(line), " (Selected)");
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Defibs: %d", pack_defibs[client]);
	if(pack_slot3[client] == 2) StrCat(line, sizeof(line), " (Selected)");
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Incediary Packs: %d", pack_firepacks[client]);
	if(pack_slot3[client] == 3) StrCat(line, sizeof(line), " (Selected)");
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Explosive Packs: %d", pack_explodepacks[client]);
	if(pack_slot3[client] == 4) StrCat(line, sizeof(line), " (Selected)");
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Pills: %d", pack_pills[client]);
	if(pack_slot4[client] == 1) StrCat(line, sizeof(line), " (Selected)");
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Adrenaline: %d", pack_adrens[client]);
	if(pack_slot4[client] == 2) StrCat(line, sizeof(line), " (Selected)");
	DrawPanelItem(panel, line);
	DrawPanelItem(panel, "Exit");
	SendPanelToClient(panel, client, Panel_Backpack, 60);
	CloseHandle(panel);
	return;
}


public Panel_Backpack(Handle:menu, MenuAction:action, param1, param2) {
	new entity;
	decl String:EdictName[128];
	new flags = GetCommandFlags("give");
	
	if (!(action == MenuAction_Select)) {
		return;
	}
	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	switch (param2) {
		case 1, 2, 3: {
			entity = GetPlayerWeaponSlot(param1, 2);
			if(entity > -1) {
				GetEdictClassname(entity, EdictName, sizeof(EdictName));
				if(StrContains(EdictName, "molotov", false) != -1) {
					RemovePlayerItem(param1, entity);
					pack_mols[param1] += 1;
				}
				if(StrContains(EdictName, "pipe_bomb", false) != -1) {
					RemovePlayerItem(param1, entity);
					pack_pipes[param1] += 1;
				}
				if(StrContains(EdictName, "vomitjar", false) != -1) {
					RemovePlayerItem(param1, entity);
					pack_biles[param1] += 1;
				}
			}
			pack_slot2[param1] = param2;
			switch (param2) {
				case 1: {
					if(pack_mols[param1] > 0) {
						FakeClientCommand(param1, "give molotov");
						pack_mols[param1] -= 1;
					} else {
						pack_slot2[param1] = 0;
					}
				}
				case 2: {
					if(pack_pipes[param1] > 0) {
						FakeClientCommand(param1, "give pipe_bomb");
						pack_pipes[param1] -= 1;
					} else {
						pack_slot2[param1] = 0;
					}
				}
				case 3: {
					if(pack_biles[param1] > 0) {
						FakeClientCommand(param1, "give vomitjar");
						pack_biles[param1] -= 1;
					} else {
						pack_slot2[param1] = 0;
					}
				}
			}
		}
		case 4, 5, 6, 7: {
			entity = GetPlayerWeaponSlot(param1, 3);
			if(entity > -1) {
				GetEdictClassname(entity, EdictName, sizeof(EdictName));
				if(StrContains(EdictName, "first_aid_kit", false) != -1) {
					RemovePlayerItem(param1, entity);
					pack_kits[param1] += 1;
				}
				if(StrContains(EdictName, "defibrillator", false) != -1) {
					RemovePlayerItem(param1, entity);
					pack_defibs[param1] += 1;
				}
				if(StrContains(EdictName, "upgradepack_incendiary", false) != -1) {
					RemovePlayerItem(param1, entity);
					pack_firepacks[param1] += 1;
				}
				if(StrContains(EdictName, "upgradepack_explosive", false) != -1) {
					RemovePlayerItem(param1, entity);
					pack_explodepacks[param1] += 1;
				}
			}
			pack_slot2[param1] = param2 - 3;
			switch (param2 - 3) {
				case 1: {
					if(pack_kits[param1] > 0) {
						FakeClientCommand(param1, "give first_aid_kit");
						pack_kits[param1] -= 1;
					} else {
						pack_slot3[param1] = 0;
					}
				}
				case 2: {
					if(pack_defibs[param1] > 0) {
						FakeClientCommand(param1, "give defibrillator");
						pack_defibs[param1] -= 1;
					} else {
						pack_slot3[param1] = 0;
					}
				}
				case 3: {
					if(pack_firepacks[param1] > 0) {
						FakeClientCommand(param1, "give upgradepack_incendiary");
						pack_firepacks[param1] -= 1;
					} else {
						pack_slot3[param1] = 0;
					}
				}
				case 4: {
					if(pack_explodepacks[param1] > 0) {
						FakeClientCommand(param1, "give upgradepack_explosive");
						pack_explodepacks[param1] -= 1;
					} else {
						pack_slot3[param1] = 0;
					}
				}
			}
		}
		case 8, 9: {
			entity = GetPlayerWeaponSlot(param1, 4);
			if(entity > -1) {
				GetEdictClassname(entity, EdictName, sizeof(EdictName));
				if(StrContains(EdictName, "pain_pills", false) != -1) {
					RemovePlayerItem(param1, entity);
					pack_pills[param1] += 1;
				}
				if(StrContains(EdictName, "adrenaline", false) != -1) {
					RemovePlayerItem(param1, entity);
					pack_adrens[param1] += 1;
				}
			}
			pack_slot4[param1] = param2 - 7;
			switch (param2 - 7) {
				case 1: {
					if(pack_pills[param1] > 0) {
						FakeClientCommand(param1, "give pain_pills");
						pack_pills[param1] -= 1;
					} else {
						pack_slot4[param1] = 0;
					}
				}
				case 2: {
					if(pack_adrens[param1] > 0) {
						FakeClientCommand(param1, "give adrenaline");
						pack_adrens[param1] -= 1;
					} else {
						pack_slot4[param1] = 0;
					}
				}
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	return;
}


public Action:AdminViewMenu(client, args) {
	decl String:line[100];
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Admin Pack View:");
	DrawPanelText(panel, "---------------------");
	
	Format(line, sizeof(line), "Players: %3d %3d %3d %3d %3d %3d %3d %3d", 1, 2, 3, 4, 5, 6, 7, 8);
	DrawPanelText(panel, line);
	Format(line, sizeof(line), "Molotovs: %3d %3d %3d %3d %3d %3d %3d %3d", pack_mols[1], pack_mols[2], pack_mols[3], pack_mols[4], pack_mols[5], pack_mols[6], pack_mols[7], pack_mols[8]);
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Pipe Bombs: %3d %3d %3d %3d %3d %3d %3d %3d", pack_pipes[1], pack_pipes[2], pack_pipes[3], pack_pipes[4], pack_pipes[5], pack_pipes[6], pack_pipes[7], pack_pipes[8]);
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Bile Bombs: %3d %3d %3d %3d %3d %3d %3d %3d", pack_biles[1], pack_biles[2], pack_biles[3], pack_biles[4], pack_biles[5], pack_biles[6], pack_biles[7], pack_biles[8]);
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Medkits: %3d %3d %3d %3d %3d %3d %3d %3d", pack_kits[1], pack_kits[2], pack_kits[3], pack_kits[4], pack_kits[5], pack_kits[6], pack_kits[7], pack_kits[8]);
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Defibs: %3d %3d %3d %3d %3d %3d %3d %3d", pack_defibs[1], pack_defibs[2], pack_defibs[3], pack_defibs[4], pack_defibs[5], pack_defibs[6], pack_defibs[7], pack_defibs[8]);
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Incediary Packs: %3d %3d %3d %3d %3d %3d %3d %3d", pack_firepacks[1], pack_firepacks[2], pack_firepacks[3], pack_firepacks[4], pack_firepacks[5], pack_firepacks[6], pack_firepacks[7], pack_firepacks[8]);
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Explosive Packs: %3d %3d %3d %3d %3d %3d %3d %3d", pack_explodepacks[1], pack_explodepacks[2], pack_explodepacks[3], pack_explodepacks[4], pack_explodepacks[5], pack_explodepacks[6], pack_explodepacks[7], pack_explodepacks[8]);
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Pills: %3d %3d %3d %3d %3d %3d %3d %3d", pack_pills[1], pack_pills[2], pack_pills[3], pack_pills[4], pack_pills[5], pack_pills[6], pack_pills[7], pack_pills[8]);
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Adrenaline: %3d %3d %3d %3d %3d %3d %3d %3d", pack_adrens[1], pack_adrens[2], pack_adrens[3], pack_adrens[4], pack_adrens[5], pack_adrens[6], pack_adrens[7], pack_adrens[8]);
	DrawPanelItem(panel, line);
	DrawPanelItem(panel, "Exit");
	SendPanelToClient(panel, client, Panel_Nothing, 60);
	CloseHandle(panel);
	
	return Plugin_Handled;
}


public Panel_Nothing(Handle:menu, MenuAction:action, param1, param2) {
	return;
}