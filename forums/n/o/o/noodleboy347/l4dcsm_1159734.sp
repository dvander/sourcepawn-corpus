/********************************************************************************************
* Plugin	: [L4D/L4D2] Character Select Menu
* Version	: 1.6
* Game		: Left 4 Dead/Left 4 Dead 2
* Author	: MI 5
* Testers	: Myself
* Website	: N/A
* 
* Purpose	: Allows players to change their in game character or model!
* 
* Version 1.6
* 		- L4D1 Survivors can now be played on any campaign
* 
* Version 1.5
* 		- Original Survivors are now playable in L4D2 (except for Bill for obvious reasons)
* 
* Version 1.4
* 		- Optimized the plugin
* 		- Merged L4D version of plugin with L4D2 version
* 		- Survivors can now become fully Infected (admins only to prevent abuse)
* 		- Fixed server crashes with uncommon infected
*
* Version 1.3
* 		- Added a timer to the Gamemode ConVarHook to ensure compatitbilty with other gamemode changing plugins
* 		- Survivors can now become Infected and vice versa (Character or model) (L4D2 only)
* 		- Added Boomette (L4D2 only)
* 		- Added Uncommon infected (model only) (L4D2 only)
* 	    - Fixed bug where the survivor menu would appear even if its turned off
* 
* Version 1.2
* 		- Redone tank health fix
* 		- Few optimizations here and there
* 
* Version 1.1
* 		- Added cvars: l4d_csm_infected_menu, l4d_csm_survivor_menu and l4d_csm_change_limit
* 		- Fixed bug where clients can access restricted parts of the menu
* 
* Version 1.0
* 		- Initial release.
* 
* 
**********************************************************************************************/

// define
#define PLUGIN_VERSION "1.6"
#define PLUGIN_NAME "[L4D/L4D2] Character Select Menu"
#define DEBUG 0
#pragma semicolon 1
#define TEAM_SPECTATOR		1
#define TEAM_SURVIVORS 		2
#define TEAM_INFECTED 		3

// includes
#include <sourcemod>
#include <sdktools>

// Cvar Handles
new Handle:g_hActivate;
new Handle:g_hFun;
new Handle:g_hInfectedMenu;
new Handle:g_hSurvivorMenu;
new Handle:g_hChangeLimit;

// Bools
new bool:g_bL4DVersion;
new bool:g_bRoundStarted;

// Arrays
new bool:g_b_aOneToSpawn[MAXPLAYERS+1]; // Used to tell the plugin that this client will be the one to spawn and not place any spawn restrictions on that client
new g_i_aChangeLimitPlayer[MAXPLAYERS+1];


public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "MI 5",
	description = "Allows players to change their in game character or model",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// Checks to see if the game is a L4D game. If it is, check if its the sequel. L4DVersion is L4D if false, L4D2 if true.
	decl String:GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrContains("left4dead", "left4dead", false) == -1)
		return APLRes_Failure;
	else if (StrEqual(GameName, "left4dead2", false))
		g_bL4DVersion = true;
	
	return APLRes_Success;
}

public OnPluginStart()
{	
	// Register the version cvar
	CreateConVar("l4d_csm_version", PLUGIN_VERSION, "Version of L4D Character Select Menu", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// convars
	
	// Fun Cvar
	g_hFun = CreateConVar("l4d_csm_fun_mode", "0", "If 1, players will be able to change their models on the csm", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	// Activate Cvar
	g_hActivate = CreateConVar("l4d_csm_enable", "1", "If 1, character select menu is activated", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	// Infected Menu cvar
	g_hInfectedMenu = CreateConVar("l4d_csm_infected_menu", "1", "If 1, Infected Menu will be shown to players", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	// Survivor Menu cvar
	g_hSurvivorMenu = CreateConVar("l4d_csm_survivor_menu", "1", "If 1, Survivor Menu will be shown to players", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	// Change Limit cvar
	g_hChangeLimit = CreateConVar("l4d_csm_change_limit", "9999", "Sets the amount of times a client can change their character", FCVAR_PLUGIN|FCVAR_SPONLY);
	HookConVarChange(g_hChangeLimit, ConVarChangeLimit);
	
	// Hook Events
	HookEvent("item_pickup", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_end", Event_RoundEnd);
	
	// config file
	AutoExecConfig(true, "l4dcsm");
	
	// sourcemod command
	RegConsoleCmd("sm_csm", PlayerMenuActivator);
}

public ConVarChangeLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	#if DEBUG
	LogMessage("L4D CSM:Round Started");
	#endif
	for (new i = 1; i <= MaxClients; i++) 
	{
		g_i_aChangeLimitPlayer[i] = GetConVarInt(g_hChangeLimit);
	}
}

public OnClientPutInServer(client)
{
	if (client)
	{
		if (GetConVarBool(g_hActivate))
			CreateTimer(30.0, AnnounceCharSelect, client);
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If round has started ...
	if (g_bRoundStarted)
		return;
	
	g_bRoundStarted = true;
	
	for (new i = 1; i <= MaxClients; i++) 
	{
		g_i_aChangeLimitPlayer[i] = GetConVarInt(g_hChangeLimit);
	}
}

public OnMapStart()
{
	//Precache models here so that the server doesn't crash
	if (g_bL4DVersion)
	{
		PrecacheModel("models/infected/common_male_ceda.mdl", true);
		PrecacheModel("models/infected/common_male_clown.mdl", true);
		PrecacheModel("models/infected/common_male_mud.mdl", true);
		PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
		PrecacheModel("models/infected/common_male_riot.mdl", true);
		PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);
		PrecacheModel("models/infected/common_male_jimmy.mdl.mdl", true);
		PrecacheModel("models/infected/boomette.mdl", true);
		PrecacheModel("models/infected/witch.mdl", true);
		PrecacheModel("models/survivors/survivor_teenangst.mdl", true);
		PrecacheModel("models/survivors/survivor_biker.mdl", true);
		PrecacheModel("models/survivors/survivor_manager.mdl", true);
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bRoundStarted = false;
}

public OnMapEnd()
{
	g_bRoundStarted = false;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// We get the client id
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// If client is valid
	if (client == 0) return Plugin_Continue;
	if (!IsClientConnected(client)) return Plugin_Continue;
	if (!IsClientInGame(client)) return Plugin_Continue;
	
	g_i_aChangeLimitPlayer[client] = GetConVarInt(g_hChangeLimit);
	
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	// If is a bot, skip this function
	if (IsFakeClient(client))
		return;
	
	g_i_aChangeLimitPlayer[client] = GetConVarInt(g_hChangeLimit);
}

public Action:PlayerMenuActivator(client, args)
{
	if ((client) && (GetConVarBool(g_hActivate)))
	{
		CreateTimer(0.1, PlayerMenu, client);
	}
}

public Action:AnnounceCharSelect(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		PrintHintText(client, "[SM] L4D Character Select Menu: Type !csm in chat to select your character!");
	}
}

public Action:PlayerMenu(Handle:timer, any:client)
{
	
	new Handle:menu = CreateMenu(CharMenu);
	SetMenuTitle(menu, "Choose a character:");
	
	// if the player is alive
	if (PlayerIsAlive(client))
	{
		if (GetClientTeam(client) == TEAM_SURVIVORS && GetConVarBool(g_hSurvivorMenu) && g_i_aChangeLimitPlayer[client] >= 1)
		{
			
			AddMenuItem(menu, "0", "Zoey");
			AddMenuItem(menu, "1", "Francis");
			AddMenuItem(menu, "2", "Louis");
			if (!g_bL4DVersion)
				AddMenuItem(menu, "3", "Bill");
			else
			{
			AddMenuItem(menu, "4", "Nick");
			AddMenuItem(menu, "5", "Rochelle");
			AddMenuItem(menu, "6", "Coach");
			AddMenuItem(menu, "7", "Ellis");
			}
			
		}
		
		if (GetConVarBool(g_hFun) && GetConVarBool(g_hSurvivorMenu) && g_i_aChangeLimitPlayer[client] >= 1 || GetUserFlagBits(client) != 0 && GetConVarBool(g_hSurvivorMenu) && g_i_aChangeLimitPlayer[client] >= 1)
		{
			AddMenuItem(menu, "8", "Zoey(Model)");
			AddMenuItem(menu, "9", "Francis(Model)");
			AddMenuItem(menu, "10", "Louis(Model)");
			if (!g_bL4DVersion)
			AddMenuItem(menu, "11", "Bill(Model)");
			else
			{
				AddMenuItem(menu, "12", "Nick(Model)");
				AddMenuItem(menu, "13", "Rochelle(Model)");
				AddMenuItem(menu, "14", "Coach(Model)");
				AddMenuItem(menu, "15", "Ellis(Model)");
			}
		}
		
		if (GetUserFlagBits(client) != 0 && GetConVarBool(g_hInfectedMenu) && g_i_aChangeLimitPlayer[client] >= 1)
		{
			AddMenuItem(menu, "16", "Smoker");
			AddMenuItem(menu, "17", "Boomer");
			AddMenuItem(menu, "18", "Hunter");
			AddMenuItem(menu, "19", "Tank");
			if (g_bL4DVersion)
			{
				AddMenuItem(menu, "20", "Boomette");
				AddMenuItem(menu, "21", "Charger");
				AddMenuItem(menu, "22", "Jockey");
				AddMenuItem(menu, "23", "Spitter");
			}
		}
		
		if (GetConVarBool(g_hFun) && GetConVarBool(g_hInfectedMenu) && g_i_aChangeLimitPlayer[client] >= 1 || GetUserFlagBits(client) != 0 && GetConVarBool(g_hInfectedMenu) && g_i_aChangeLimitPlayer[client] >= 1)
		{
			if (!g_bL4DVersion && GetClientTeam(client) == TEAM_INFECTED || g_bL4DVersion)
			{
				AddMenuItem(menu, "24", "Smoker(Model)");
				AddMenuItem(menu, "25", "Boomer(Model)");
				AddMenuItem(menu, "26", "Hunter(Model)");
			}
			AddMenuItem(menu, "27", "Tank(Model)");
			if (g_bL4DVersion)
			{
				AddMenuItem(menu, "28", "Boomette(Model)");
				AddMenuItem(menu, "29", "Charger(Model)");
				AddMenuItem(menu, "30", "Jockey(Model)");
				AddMenuItem(menu, "31", "Spitter(Model)");
				AddMenuItem(menu, "32", "CEDA Hazmat(Model)");
				AddMenuItem(menu, "33", "Clown(Model)");
				AddMenuItem(menu, "34", "Mud Man(Model)");
				AddMenuItem(menu, "35", "Construction Worker(Model)");
				AddMenuItem(menu, "36", "Riot Officer(Model)");
				AddMenuItem(menu, "37", "Fallen Survivor(Model)");
				AddMenuItem(menu, "38", "Jimmy Gibbs Jr.(Model)");
			}
			AddMenuItem(menu, "39", "Witch(Model)");
		}
		if (g_i_aChangeLimitPlayer[client] < 1)
		{
			PrintHintText(client, "Sorry, you cannot change your character until you respawn.");
			return;
		}
		if (GetMenuItemCount(menu) == 0)
		{
			PrintHintText(client, "Sorry, there are no selections you can make at this time.");
			return;
		}
	}
	else
	{
		PrintHintText(client, "Sorry, you must be alive to use the Character Select Menu!");
		return;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 9999);
}

public CharMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:item[256], String:display[256];
		
		GetMenuItem(menu, param2, item, sizeof(item), _, display, sizeof(display));
		
		new Menu_Number = StringToInt(item);
		
		switch(Menu_Number)
		{
			case 0: // Zoey
			SetUpSurvivor(param1, 0);
			case 1: // Francis
			SetUpSurvivor(param1, 1);
			case 2: // Louis
			SetUpSurvivor(param1, 2);
			case 3: // Bill
			SetUpSurvivor(param1, 3);
			case 4: // Nick
			SetUpSurvivor(param1, 4);
			case 5: // Rochelle
			SetUpSurvivor(param1, 5);
			case 6: // Coach
			SetUpSurvivor(param1, 6);
			case 7: // Ellis
			SetUpSurvivor(param1, 7);
			case 8: // Zoey (Model)
			SetUpSurvivorModel(param1, 0);
			case 9: // Francis (Model)
			SetUpSurvivorModel(param1, 1);
			case 10: // Louis (Model)
			SetUpSurvivorModel(param1, 2);
			case 11: // Bill (Model)
			SetUpSurvivorModel(param1, 3);
			case 12: // Nick (Model)
			SetUpSurvivorModel(param1, 4);
			case 13: // Rochelle (Model)
			SetUpSurvivorModel(param1, 5);
			case 14: // Coach (Model)
			SetUpSurvivorModel(param1, 6);
			case 15: // Ellis (Model)
			SetUpSurvivorModel(param1, 7);
			case 16: // Smoker
			SetUpInfected(param1, 2);
			case 17: // Boomer
			SetUpInfected(param1, 3);
			case 18: // Hunter
			SetUpInfected(param1, 1);
			case 19: // Tank
			SetUpInfected(param1, 4);
			case 20: // Boomette
			SetUpInfected(param1, 8);
			case 21: // Charger
			SetUpInfected(param1, 5);
			case 22: // Jockey
			SetUpInfected(param1, 6);
			case 23: // Spitter
			SetUpInfected(param1, 7);
			case 24: // Smoker (Model)
			SetUpInfectedModel(param1, 2);
			case 25: // Boomer (Model)
			SetUpInfectedModel(param1, 3);
			case 26: // Hunter (Model)
			SetUpInfectedModel(param1, 1);
			case 27: // Tank (Model)
			SetUpInfectedModel(param1, 4);
			case 28: // Boomette (Model)
			SetUpInfectedModel(param1, 8);
			case 29: // Charger (Model)
			SetUpInfectedModel(param1, 5);
			case 30: // Jockey (Model)
			SetUpInfectedModel(param1, 6);
			case 31: // Spitter (Model)
			SetUpInfectedModel(param1, 7);
			case 32: // CEDA (Model)
			SetUpInfectedModel(param1, 9);
			case 33: // Clown (Model)
			SetUpInfectedModel(param1, 10);
			case 34: // Mudman (Model)
			SetUpInfectedModel(param1, 11);
			case 35: // Roadcrew (Model)
			SetUpInfectedModel(param1, 12);
			case 36: // Riot (Model)
			SetUpInfectedModel(param1, 13);
			case 37: // Fallen Survivor (Model)
			SetUpInfectedModel(param1, 14);
			case 38: // Jimmy Gibbs Jr.
			SetUpInfectedModel(param1, 15);
			case 39: // Witch
			SetUpInfectedModel(param1, 16);
		}
	} 
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

SetUpSurvivor(param1, Survivor)
{
	if (GetClientTeam(param1) == TEAM_INFECTED)
		return;
	
	// Set the character and model
	switch(Survivor)
	{
		case 0: // Zoey
		{
			if (!g_bL4DVersion)
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 1, 1, true);
			else
			SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 5, 1, true);
			
			SetEntityModel(param1, "models/survivors/survivor_teenangst.mdl");
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Zoey \x05]");
		}
		case 1: // Francis
		{
			if (!g_bL4DVersion)
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 3, 1, true);
			else
			SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 6, 1, true);
			
			SetEntityModel(param1, "models/survivors/survivor_biker.mdl");
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Francis \x05]");
		}
		case 2: // Louis
		{
			if (!g_bL4DVersion)
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 3, 1, true);
			else
			SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 7, 1, true);
			
			SetEntityModel(param1, "models/survivors/survivor_manager.mdl");
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Louis \x05]");
		}
		case 3: // Bill
		{
			SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 0, 1, true);
			SetEntityModel(param1, "models/survivors/survivor_namvet.mdl");
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Bill \x05]");
		}
		case 4: // Nick
		{
			SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 0, 1, true);
			SetEntityModel(param1, "models/survivors/survivor_gambler.mdl");
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Nick \x05]");
		}
		case 5: // Rochelle
		{
			SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 1, 1, true);
			SetEntityModel(param1, "models/survivors/survivor_producer.mdl");
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Rochelle \x05]");
		}
		case 6: // Coach
		{
			SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 2, 1, true);
			SetEntityModel(param1, "models/survivors/survivor_coach.mdl");
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Coach \x05]");
		}
		case 7: // Ellis
		{
			SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 3, 1, true);
			SetEntityModel(param1, "models/survivors/survivor_mechanic.mdl");
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Ellis \x05]");
		}
	}
	
	g_i_aChangeLimitPlayer[param1]--;
}

SetUpSurvivorModel(param1, Survivor)
{
	switch(Survivor)
	{
		case 0: // Zoey
		{
			SetEntityModel(param1, "models/survivors/survivor_teenangst.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now \x03Zoey \x05]");
		}
		case 1: // Francis
		{
			SetEntityModel(param1, "models/survivors/survivor_biker.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now \x03Francis \x05]");
		}
		case 2: // Louis
		{
			SetEntityModel(param1, "models/survivors/survivor_manager.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now \x03Louis \x05]");
		}
		case 3: // Bill
		{
			SetEntityModel(param1, "models/survivors/survivor_namvet.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now \x03Bill \x05]");
		}
		case 4: // Nick
		{
			SetEntityModel(param1, "models/survivors/survivor_gambler.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now \x03Nick \x05]");
		}
		case 5: // Rochelle
		{
			SetEntityModel(param1, "models/survivors/survivor_producer.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now \x03Rochelle \x05]");
		}
		case 6: // Coach
		{
			SetEntityModel(param1, "models/survivors/survivor_coach.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now \x03Coach \x05]");
		}
		case 7: // Ellis
		{
			SetEntityModel(param1, "models/survivors/survivor_mechanic.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now \x03Ellis \x05]");
		}
	}
	
	g_i_aChangeLimitPlayer[param1]--;
}

SetUpInfected(param1, Infected)
{
	if ((GetClientTeam(param1)) == TEAM_SURVIVORS)
		ChangeClientTeam(param1, TEAM_INFECTED);
	
	// Set the player as a ghost so that it can take the spawned infected
	SetGhostStatus(param1, true);
	
	// Set the player as the one to spawn so no spawn restrictions apply to that client
	g_b_aOneToSpawn[param1] = true;
	
	// If it's a boomette, spawn a boomer, else just pass the infected number to the Spawn_Infected function
	if (Infected == 8)
		Spawn_Infected(3);
	else
	Spawn_Infected(Infected);
	
	// The client is no longer the one to spawn as the client has already spawned
	g_b_aOneToSpawn[param1] = false;
	
	// Set the client back to life
	SetGhostStatus(param1, false);
	
	// Change the model for the boomer or boomette
	if (Infected == 3)
		SetEntityModel(param1, "models/infected/boomer.mdl");
	else if (Infected == 8)
		SetEntityModel(param1, "models/infected/boomette.mdl");
	
	// Print to the player they changed into
	switch(Infected)
	{
		case 1: // Hunter
		PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Hunter \x05]");
		case 2: // Smoker
		PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Smoker \x05]");
		case 3: // Boomer
		PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Boomer \x05]");
		case 4: // Tank
		PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Tank! \x05]");
		case 5: // Charger
		PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Charger \x05]");
		case 6: // Jockey
		PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Jockey \x05]");
		case 7: // Spitter
		PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Spitter \x05]");
		case 8: // Boomette
		PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Boomette \x05]");
	}
	
	g_i_aChangeLimitPlayer[param1]--;
}

SetUpInfectedModel(param1, Infected)
{
	switch(Infected)
	{
		case 1: // Hunter
		{
			// Prevents players from changing teams and accessing the models while the menu is running
			if (!g_bL4DVersion && GetClientTeam(param1) != TEAM_INFECTED)
				return;
			SetEntityModel(param1, "models/infected/hunter.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Hunter \x05]");
		}
		case 2: // Smoker
		{
			// Prevents players from changing teams and accessing the models while the menu is running
			if (!g_bL4DVersion && GetClientTeam(param1) != TEAM_INFECTED)
				return;
			SetEntityModel(param1, "models/infected/smoker.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Smoker \x05]");
		}
		case 3: // Boomer
		{
			// Prevents players from changing teams and accessing the models while the menu is running
			if (!g_bL4DVersion && GetClientTeam(param1) != TEAM_INFECTED)
				return;
			SetEntityModel(param1, "models/infected/boomer.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Boomer \x05]");
		}
		case 4: // Tank
		{
			SetEntityModel(param1, "models/infected/hulk.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Tank! \x05]");
		}
		case 5: // Charger
		{
			SetEntityModel(param1, "models/infected/charger.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Charger \x05]");
		}
		case 6: // Jockey
		{
			SetEntityModel(param1, "models/infected/jockey.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Jockey \x05]");
		}
		case 7: // Spitter
		{
			SetEntityModel(param1, "models/infected/spitter.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Spitter \x05]");
		}
		case 8: // Boomette
		{
			SetEntityModel(param1, "models/infected/boomette.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Boomette \x05]");
		}
		case 9: // CEDA
		{
			SetEntityModel(param1, "models/infected/common_male_ceda.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Ceda Hazmat Operative! \x05]");
		}
		case 10: // Clown
		{
			SetEntityModel(param1, "models/infected/common_male_clown.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Clown Infected! \x05]");
		}
		case 11: // Mud
		{
			SetEntityModel(param1, "models/infected/common_male_mud.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Mud Man Infected! \x05]");
		}
		case 12: // Roadcrew
		{
			SetEntityModel(param1, "models/infected/common_male_roadcrew.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Construction worker! \x05]");
		}
		case 13: // Riot
		{
			SetEntityModel(param1, "models/infected/common_male_riot.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Riot Infected! \x05]");
		}
		case 14: // Fallen Survivor
		{
			SetEntityModel(param1, "models/infected/common_male_fallen_survivor.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Fallen Survivor! \x05]");
		}
		case 15: // Jimmy Gibbs Jr.
		{
			SetEntityModel(param1, "models/infected/common_male_jimmy.mdl.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Jimmy Gibbs Jr.! \x05]");
		}
		case 16: // Witch
		{
			SetEntityModel(param1, "models/infected/witch.mdl");
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Witch! \x05]");
		}
	}
	
	g_i_aChangeLimitPlayer[param1]--;
}

Spawn_Infected(InfectedTicket)
{
	// Before spawning the bot, we determine if an real infected player is dead, since the new infected bot will be controlled by this player
	new bool:resetGhost[MAXPLAYERS+1];
	new bool:resetLife[MAXPLAYERS+1];
	
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientConnected(i) && (!IsFakeClient(i)) && IsClientInGame(i)) // player is connected and is not fake and it's in game ...
		{
			// If player is on infected's team and is dead ..
			if (GetClientTeam(i)==TEAM_INFECTED)
			{
				if (g_b_aOneToSpawn[i] == false)
				{
					// If player is a ghost ....
					if (IsPlayerGhost(i))
					{
						resetGhost[i] = true;
						SetGhostStatus(i, false);
						#if DEBUG
						LogMessage("Player is a ghost, taking preventive measures for spawning an infected bot");
						#endif
					}
					else if (!PlayerIsAlive(i))
					{
						resetLife[i] = true;
						SetLifeState(i, false);
						#if DEBUG
						LogMessage("Found a dead player, spawn time has not reached zero, delaying player to Spawn an infected bot");
						#endif
					}
				}
			}
		}
	}
	
	// We get any client ....
	new anyclient = GetAnyClient();
	new bool:temp = false;
	if (!anyclient)
	{
		#if DEBUG
		LogMessage("[CSM] Creating temp client to fake command");
		#endif
		// we create a fake client
		anyclient = CreateFakeClient("Bot");
		if (!anyclient)
		{
			LogError("[L4D] Character Select Menu: CreateFakeClient returned 0 -- Infected bot was not spawned");
			return;
		}
		temp = true;
	}
	
	// We spawn the bot ...
	switch (InfectedTicket)
	{
		case 1: // Hunter
		{
			#if DEBUG
			LogMessage("Spawning Hunter");
			#endif
			CheatCommand(anyclient, "z_spawn", "hunter auto");
		}
		case 2: // Smoker
		{	
			#if DEBUG
			LogMessage("Spawning Smoker");
			#endif
			CheatCommand(anyclient, "z_spawn", "smoker auto");
		}
		case 3: // Boomer
		{
			#if DEBUG
			LogMessage("Spawning Boomer");
			#endif
			CheatCommand(anyclient, "z_spawn", "boomer auto");
		}
		case 4: // Tank
		{
			#if DEBUG
			LogMessage("Spawning Tank");
			#endif
			CheatCommand(anyclient, "z_spawn", "tank auto");
		}
		case 5: // Charger
		{
			#if DEBUG
			LogMessage("Spawning Charger");
			#endif
			CheatCommand(anyclient, "z_spawn", "charger auto");
		}
		case 6: // Jockey
		{
			#if DEBUG
			LogMessage("Spawning Jockey");
			#endif
			CheatCommand(anyclient, "z_spawn", "jockey auto");
		}
		case 7: // Spitter
		{
			#if DEBUG
			LogMessage("Spawning Spitter");
			#endif
			CheatCommand(anyclient, "z_spawn", "spitter auto");
		}
	}
	
	// If client was temp, we setup a timer to kick the fake player
	if (temp) KickClient(temp, "No longer needed");
	
	// We restore the player's status
	for (new i=1;i<=MaxClients;i++)
	{
		if (resetGhost[i] == true)
			SetGhostStatus(i, true);
		if (resetLife[i] == true)
			SetLifeState(i, true);
	}
	
}

bool:IsPlayerGhost (client)
{
	if (GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_isGhost"), 1))
		return true;
	return false;
}

bool:PlayerIsAlive (client)
{
	if (GetClientHealth(client) > 1)
		return true;
	return false;
}

stock GetAnyClient()
{
	#if DEBUG
	LogMessage("[Infected bots] Looking for any real client to fake command");
	#endif
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && (!IsFakeClient(i)))
		{
			return i;
		}
	}
	return 0;
}

SetGhostStatus (client, bool:ghost)
{
	if (ghost)
	{	
		SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_isGhost"), 1, 1, true);
	}
	else
	{
		SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_isGhost"), 0, 1, false);
	}
}

SetLifeState (client, bool:ready)
{
	if (ready)
		SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_lifeState"), 1, 1, true);
	else
	SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_lifeState"), 0, 1, false);
}

stock CheatCommand(client, String:command[], String:arguments[] = "")
{
	if (!client || !IsClientInGame(client))
	{
		for (new target = 1; target <= MaxClients; target++)
		{
			client = target;
			break;
		}
		
		return; // case no valid Client found
	}
	
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

//////////