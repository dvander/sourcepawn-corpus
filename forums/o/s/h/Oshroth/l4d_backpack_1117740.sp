#pragma semicolon 1
#include <sourcemod>
#include <string>
#include <sdktools>
#include <timers>
#define PLUGIN_VERSION "1.1.1"


/******
* TODO
*******
* - Expand Backpack to include Slot 0 & Slot 1(Primary & Secondary)
* - Add Weight/Amount limits
* - Add Encumberance slowdown
* - Add Unrecoverable items on death
* - Add cvars for controlling plugin
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
new pack_store[MAXPLAYERS+1][4];
new iGame_Mode;

/* Backpack Contents - Stores player amounts of each item in their backpack */
new pack_mols[MAXPLAYERS+1];							//Molotovs
new pack_pipes[MAXPLAYERS+1];							//Pipebombs
new pack_kits[MAXPLAYERS+1];							//First Aid Kits
new pack_pills[MAXPLAYERS+1];							//Pain Pills

/* Solt Selections - Stores current item choice for each slot */
new pack_slot2[MAXPLAYERS+1];							//Grenade Selection

/* Misc. Fixes - Used to fix various event problems/issues */
new bool:item_pickup[MAXPLAYERS+1];						//Set in Event_ItemPickup to skip Event_PlayerUse
new bool:roundFailed = false;

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
	if (StrContains(game, "left4dead") == -1) SetFailState("Backpack will only work with Left 4 Dead!");
	
	/* Game Mode Hook */
	hGame_Mode = FindConVar("mp_gamemode");
	HookConVarChange(hGame_Mode, ConVarChange_GameMode);
	
	GetConVarString(hGame_Mode, sGame_Mode, sizeof(sGame_Mode));
	
	if(StrContains(sGame_Mode, "coop") != -1) {
		iGame_Mode = 1;
	}
	if(StrContains(sGame_Mode, "versus") != -1) {
		iGame_Mode = 2;
	}
	if(StrContains(sGame_Mode, "teamversus") != -1) {
		iGame_Mode = 3;
	}
	if(StrContains(sGame_Mode, "survival") != -1) {
		iGame_Mode = 4;
	}
	
	
	RegConsoleCmd("pack", PackMenu);
	RegAdminCmd("pack_view", AdminViewMenu, ADMFLAG_GENERIC, "Allows admins to view player backpacks");
	
	/* Event Hooks */
	HookEvent("round_start", Event_RoundStart); 		//Used to reset all backpacks at start of round
	HookEvent("item_pickup", Event_ItemPickup);			//Used to handle item pickups
	HookEvent("player_use", Event_PlayerUse); 			//Used to pick up extra items
	HookEvent("player_death", Event_PlayerDeath); 		//Used to drop player's items on death
	HookEvent("round_freeze_end", Event_RoundEnd);
	HookEvent("mission_lost", Event_MissionLost);
	HookEvent("finale_win", Event_FinaleWin);
	
	/* Item Use Events */
	HookEvent("heal_success", Event_KitUsed); 			//Used to catch when someone uses a kit
	HookEvent("pills_used", Event_PillsUsed); 			//Used to catch when someone uses pills
	
	/* Backpack Changeover */
	HookEvent("bot_player_replace", Event_BotToPlayer); //Used to give a leaving Bot's pack to a joining player
	HookEvent("player_bot_replace", Event_PlayerToBot); //Used to give a leaving player's pack to a joining Bot
	
	pack_version = CreateConVar("l4d_backpack_version", PLUGIN_VERSION, "Backpack plugin version.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CreateConVar("l4d_backpack_start_mols", "0", "Starting Molotovs", _, true, 0.0);
	CreateConVar("l4d_backpack_start_pipes", "0", "Starting Pipe Bombs", _, true, 0.0);
	CreateConVar("l4d_backpack_start_kits", "0", "Starting Medkits", _, true, 0.0);
	CreateConVar("l4d_backpack_start_pills", "0", "Starting Pills", _, true, 0.0);
	CreateConVar("l4d_backpack_help_mode", "1", "Controls how joining help message is displayed.");
	
	AutoExecConfig(true, "l4d_backpack");
	
	SetConVarString(pack_version, PLUGIN_VERSION);
	
	ResetBackpack(0, 1);
}

public OnClientPutInServer(client) {
	if(GetConVarInt(FindConVar("l4d_backpack_help_mode")) != 0) {
		CreateTimer(60.0, Timer_WelcomeMessage, client);
	}
}

public Action:Timer_WelcomeMessage(Handle:timer, any:client) {
	new String:help[] = "\x01[SM] Survivors can carry extra items in their backpack.\n\x01[SM] To access your backpack, type \x04!pack\x01 in chat.";
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client)) {
		switch (GetConVarInt(FindConVar("l4d_backpack_help_mode"))) {
			case 1: {
				PrintToChat(client, help);
			}
			case 2: {
				PrintHintText(client, help);
			}
			case 3: {
				PrintCenterText(client, help);
			}
			default: {
				PrintToChat(client, help);
			}
		}
	}
}

public ConVarChange_GameMode(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	decl String:sGame_Mode[32];
	
	GetConVarString(hGame_Mode, sGame_Mode, sizeof(sGame_Mode));
	
	if(StrContains(sGame_Mode, "coop") != -1) {
		iGame_Mode = 1;
	}
	if(StrContains(sGame_Mode, "versus") != -1) {
		iGame_Mode = 2;
	}
	if(StrContains(sGame_Mode, "teamversus") != -1) {
		iGame_Mode = 3;
	}
	if(StrContains(sGame_Mode, "survival") != -1) {
		iGame_Mode = 4;
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	new i;
	
	if(iGame_Mode == 1) {
		if(roundFailed == true) {
			for(i = 1; i <= MAXPLAYERS; i++) {
				pack_mols[i] = pack_store[i][0];
				pack_pipes[i] = pack_store[i][1];
				pack_kits[i] = pack_store[i][2];
				pack_pills[i] = pack_store[i][3];
			}
		}
		roundFailed = false;
		
		return Plugin_Continue;
	}
	ResetBackpack(0, 1);
	
	return Plugin_Continue;
}

public Action:Event_ItemPickup(Handle:event, const String:name[], bool:dontBroadcast) {
	new userId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userId);
	decl String:item[64];
	GetEventString(event, "item", item, sizeof(item));
	#if defined DEBUG
	PrintToChatAll("[DEBUG] %d called ItemPickup. Item = %s", client, item);
	#endif
	if(StrContains(item, "molotov", false) != -1) {
		pack_slot2[client] = 1;
		#if defined DEBUG
		PrintToChatAll("[DEBUG] %d changed slot2 to %d", client, pack_slot2[client]);
		#endif
	}
	if(StrContains(item, "pipe_bomb", false) != -1) {
		pack_slot2[client] = 2;
		#if defined DEBUG
		PrintToChatAll("[DEBUG] %d changed slot2 to %d", client, pack_slot2[client]);
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
	if(StrContains(item, "first_aid_kit", false) != -1) {
		AcceptEntityInput(targetid, "Kill");
		pack_kits[client] += 1;
	}
	if(StrContains(item, "pain_pills", false) != -1) {
		AcceptEntityInput(targetid, "Kill");
		pack_pills[client] += 1;
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
	if(GetClientTeam(client) == 2) {
		SpawnItem(victim, "weapon_molotov", pack_mols[client]);
		SpawnItem(victim, "weapon_pipe_bomb", pack_pipes[client]);
		SpawnItem(victim, "weapon_first_aid_kit", pack_kits[client]);
		SpawnItem(victim, "weapon_pain_pills", pack_pills[client]);
	}
	ResetBackpack(client, 0);
	
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
	
	if((iGame_Mode == 1) && roundFailed == false) {
		for(i = 1; i <= MAXPLAYERS; i++) {
			pack_store[i][0] = pack_mols[i];
			pack_store[i][1] = pack_pipes[i];
			pack_store[i][2] = pack_kits[i];
			pack_store[i][3] = pack_pills[i];
		}
	}
	return Plugin_Continue;
}

public Action:Event_FinaleWin(Handle:event, const String:name[], bool:dontBroadcast) {
	new i;
	
	if(iGame_Mode == 1) {
		ResetBackpack(0, 1);
		for(i = 1; i <= MAXPLAYERS; i++) {
			pack_store[i][0] = pack_mols[i];
			pack_store[i][1] = pack_pipes[i];
			pack_store[i][2] = pack_kits[i];
			pack_store[i][3] = pack_pills[i];
		}
	}
	
	roundFailed = false;
	
	return Plugin_Continue;
}

public Action:Event_MissionLost(Handle:event, const String:name[], bool:dontBroadcast) {
	if(iGame_Mode == 1) {
		roundFailed = true;
	}
	return Plugin_Continue;
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
		if(pack_kits[client] > 0) {
			FakeClientCommand(client, "give first_aid_kit");
			pack_kits[client] -= 1;
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	return Plugin_Continue;
}

public Action:Event_PillsUsed(Handle:event, const String:name[], bool:dontBroadcast) {
	new userId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userId);
	CreateTimer(1.0, GivePills, client);
	#if defined DEBUG
	PrintToChatAll("[DEBUG] %d called PillsUsed.", client);
	#endif
	return Plugin_Continue;
}

public Action:GivePills(Handle:timer, any:client) {
	if(client <= 0 || !IsClientInGame(client)) {
		return;
	}
	#if defined DEBUG
	PrintToChatAll("[DEBUG] %d called GivePills.", client);
	#endif
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	new entity;
	entity = GetPlayerWeaponSlot(client, 4);
	if(entity <= -1) {
		if(pack_pills[client] > 0) {
			FakeClientCommand(client, "give pain_pills");
			pack_pills[client] -= 1;
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

public Action:Event_BotToPlayer(Handle:event, const String:name[], bool:dontBroadcast) {
	new bot = GetEventInt(event, "bot");
	new client = GetClientOfUserId(bot);
	new player = GetEventInt(event, "player");
	new client2 = GetClientOfUserId(player);
	
	#if defined DEBUG
	PrintToChatAll("[DEBUG] Bot %d handed control to %d.", client, client2);
	#endif
	
	/* Changeover */
	pack_mols[client2] += pack_mols[client];
	pack_pipes[client2] += pack_pipes[client];
	pack_kits[client2] += pack_kits[client];
	pack_pills[client2] += pack_pills[client];
	pack_slot2[client2] = pack_slot2[client];
	item_pickup[client2] = false;
	
	/* Remove Old */
	ResetBackpack(client, 0);
	
	if(iGame_Mode == 1) {
		pack_store[client2][0] += pack_store[client][0];
		pack_store[client2][1] += pack_store[client][1];
		pack_store[client2][2] += pack_store[client][2];
		pack_store[client2][3] += pack_store[client][3];
		
		pack_store[client][0] = 0;
		pack_store[client][1] = 0;
		pack_store[client][2] = 0;
		pack_store[client][3] = 0;
		
	}
	
	return Plugin_Continue;
}


public Action:Event_PlayerToBot(Handle:event, const String:name[], bool:dontBroadcast) {
	new bot = GetEventInt(event, "bot");
	new client2 = GetClientOfUserId(bot);
	new player = GetEventInt(event, "player");
	new client = GetClientOfUserId(player);
	
	#if defined DEBUG
	PrintToChatAll("[DEBUG] %d handed control to Bot %d.", client, client2);
	#endif
	
	/* Changeover */
	pack_mols[client2] += pack_mols[client];
	pack_pipes[client2] += pack_pipes[client];
	pack_kits[client2] += pack_kits[client];
	pack_pills[client2] += pack_pills[client];
	pack_slot2[client2] = pack_slot2[client];
	item_pickup[client2] = false;
	
	/* Remove Old */
	ResetBackpack(client, 0);
	
	if(iGame_Mode == 1) {
		pack_store[client2][0] += pack_store[client][0];
		pack_store[client2][1] += pack_store[client][1];
		pack_store[client2][2] += pack_store[client][2];
		pack_store[client2][3] += pack_store[client][3];
		
		pack_store[client][0] = 0;
		pack_store[client][1] = 0;
		pack_store[client][2] = 0;
		pack_store[client][3] = 0;
	}
	
	return Plugin_Continue;
}

ResetBackpack(client = 0, reset = 1) {
	/*
	* Client Values
	* Client number for player you want to reset
	* 0 means reset all
	* 
	* Reset Values
	* 0 means empty the pack back to 0
	* 1 means set the pack to starting amounts
	*/
	new mols;
	new pipes;
	new kits;
	new pills;
	new i;
	
	if(reset == 1) {
		mols = GetConVarInt(FindConVar("l4d_backpack_start_mols"));
		pipes = GetConVarInt(FindConVar("l4d_backpack_start_pipes"));
		kits = GetConVarInt(FindConVar("l4d_backpack_start_kits"));
		pills = GetConVarInt(FindConVar("l4d_backpack_start_pills"));
	}
	
	if(client != 0) {
		pack_mols[client] = mols;
		pack_pipes[client] = pipes;
		pack_kits[client] = kits;
		pack_pills[client] = pills;
		pack_slot2[client] = 0;
		item_pickup[client] = false;
		
		return;
	}
	
	for(i = 0; i <= MAXPLAYERS; i++) {
		pack_mols[i] = mols;
		pack_pipes[i] = pipes;
		pack_kits[i] = kits;
		pack_pills[i] = pills;
		pack_slot2[i] = 0;
		item_pickup[i] = false;
	}
	
	return;
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
					case 1, 2: {
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
	Format(line, sizeof(line), "Medkits: %d", pack_kits[client]);
	DrawPanelText(panel, line);
	Format(line, sizeof(line), "Pills: %d", pack_pills[client]);
	DrawPanelText(panel, line);
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
		case 1, 2: {
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
	Format(line, sizeof(line), "Medkits: %3d %3d %3d %3d %3d %3d %3d %3d", pack_kits[1], pack_kits[2], pack_kits[3], pack_kits[4], pack_kits[5], pack_kits[6], pack_kits[7], pack_kits[8]);
	DrawPanelItem(panel, line);
	Format(line, sizeof(line), "Pills: %3d %3d %3d %3d %3d %3d %3d %3d", pack_pills[1], pack_pills[2], pack_pills[3], pack_pills[4], pack_pills[5], pack_pills[6], pack_pills[7], pack_pills[8]);
	DrawPanelItem(panel, line);
	DrawPanelItem(panel, "Exit");
	SendPanelToClient(panel, client, Panel_Nothing, 60);
	CloseHandle(panel);
	
	return Plugin_Handled;
}


public Panel_Nothing(Handle:menu, MenuAction:action, param1, param2) {
	return;
}
