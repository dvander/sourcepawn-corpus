/********************************************************************************************
* Plugin	: L4D2 Character Select Menu
* Version	: 1.7
* Game		: Left 4 Dead 2
* Author	: MI 5
* Testers	: Myself
* Website	: N/A
* 
* Purpose	: Allows players to change their in game character or model!
* 
* Version 1.7
* 		- Fixed a crash with the infected menu
* 		- Precached boomer and witch so that it doesn't crash when you select them
* 		- Fixed bug where survivors couldn't access the menu when they had 1 point of health left
* 		- Changed the description of the Infected Menu cvar
* 		- Added cvar: l4d_csm_models_only
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
#define PLUGIN_VERSION "1.7"
#define PLUGIN_NAME "L4D2 Character Select Menu"
#define DEBUG 0
#pragma semicolon 1
#define TEAM_SPECTATOR		1
#define TEAM_SURVIVORS 		2
#define TEAM_INFECTED 		3
#define MODEL_BILL "models/survivors/survivor_namvet.mdl"
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl"
#define MODEL_NICK "models/survivors/survivor_gambler.mdl"
#define MODEL_COACH "models/survivors/survivor_coach.mdl"
#define MODEL_ROCHELLE "models/survivors/survivor_producer.mdl"
#define MODEL_ELLIS "models/survivors/survivor_mechanic.mdl"
new String:currentmap[64];

// includes
#include <sourcemod>
#include <sdktools>

// Cvar Handles
new Handle:g_hActivate;
new Handle:g_hFun;
new Handle:g_hInfectedMenu;
new Handle:g_hSurvivorMenu;
new Handle:g_hChangeLimit;
new Handle:g_hModelsOnly;

// variables
static g_iSelectedClient; // used to save the client number that was selected by an admin to change their character

// Bools
new bool:g_bL4DVersion;
new bool:g_bRoundStarted;

// Arrays
new bool:g_b_aOneToSpawn[MAXPLAYERS+1]; // Used to tell the plugin that this client will be the one to spawn and not place any spawn restrictions on that client
new g_i_aChangeLimitPlayer[MAXPLAYERS+1];


public Plugin:myinfo = 
{
	name = "Character Select00",
	author = "MI 5",
	description = "Change character",
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
	g_hInfectedMenu = CreateConVar("l4d_csm_infected_menu", "1", "If 1, Infected Menu will be shown to admins only, will only show models to players if fun mode is on", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	// Survivor Menu cvar
	g_hSurvivorMenu = CreateConVar("l4d_csm_survivor_menu", "1", "If 1, Survivor Menu will be shown to players and admins", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	// Models only cvar
	g_hModelsOnly = CreateConVar("l4d_csm_models_only", "0", "If 1, only models can be selected, admins can bypass this", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	// Change Limit cvar
	g_hChangeLimit = CreateConVar("l4d_csm_change_limit", "9999", "Sets the amount of times a client can change their character", FCVAR_PLUGIN|FCVAR_SPONLY);
	HookConVarChange(g_hChangeLimit, ConVarChangeLimit);
	
	// Hook Events
	HookEvent("item_pickup", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_end", Event_RoundEnd);
	
	// config file
	AutoExecConfig(true, "l4d2csm00");
	
	// sourcemod command
	RegConsoleCmd("sm_csm", PlayerMenuActivator);
	RegAdminCmd("sm_csc", InitiateMenuAdmin, ADMFLAG_GENERIC, "Brings up a menu to select a client's character");
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
		GetCurrentMap(currentmap, 64);
		PrecacheModel(MODEL_BILL, true);
		PrecacheModel(MODEL_FRANCIS, true);
		PrecacheModel(MODEL_LOUIS, true);
		PrecacheModel(MODEL_ZOEY, true);
		PrecacheModel(MODEL_NICK, true);
		PrecacheModel(MODEL_COACH, true);
		PrecacheModel(MODEL_ROCHELLE, true);
		PrecacheModel(MODEL_ELLIS, true);
		SetConVarInt(FindConVar("precache_l4d1_survivors"), 1, true, true);
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
		PrecacheModel("models/survivors/survivor_namvet.mdl", true);
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

public Action:PlayerMenu(Handle:timer, any:client)
{
	
	new Handle:menu = CreateMenu(CharMenu);
	SetMenuTitle(menu, "Choose a character:");
	
	// if the player is alive
	if (PlayerIsAlive(client))
	{
		if (GetClientTeam(client) == TEAM_SURVIVORS && GetConVarBool(g_hSurvivorMenu) && g_i_aChangeLimitPlayer[client] >= 1)
		{
			if (!GetConVarBool(g_hModelsOnly) || GetUserFlagBits(client) != 0)
			{
				AddMenuItem(menu, "0", "Zoey");
				AddMenuItem(menu, "1", "Francis");
				AddMenuItem(menu, "2", "Louis");
				AddMenuItem(menu, "3", "Bill");
				if (!g_bL4DVersion)
					AddMenuItem(menu, "8", "Gargantua");
				else
				{
					AddMenuItem(menu, "4", "Nick");
					AddMenuItem(menu, "5", "Rochelle");
					AddMenuItem(menu, "6", "Coach");
					AddMenuItem(menu, "7", "Ellis");
				}
			}
			
		}
		
		if (GetConVarBool(g_hFun) && GetConVarBool(g_hSurvivorMenu) && g_i_aChangeLimitPlayer[client] >= 1 || GetUserFlagBits(client) != 0 && GetConVarBool(g_hSurvivorMenu) && g_i_aChangeLimitPlayer[client] >= 1)
		{
			AddMenuItem(menu, "8", "Zoey(Model)");
			AddMenuItem(menu, "9", "Francis(Model)");
			AddMenuItem(menu, "10", "Louis(Model)");
			AddMenuItem(menu, "11", "Bill(Model)");
			if (!g_bL4DVersion)
				AddMenuItem(menu, "16", "Gargantua(Model)");
			else
			{
				AddMenuItem(menu, "12", "Nick(Model)");
				AddMenuItem(menu, "13", "Rochelle(Model)");
				AddMenuItem(menu, "14", "Coach(Model)");
				AddMenuItem(menu, "15", "Ellis(Model)");
			}
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
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 2, 1, true);
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
			if (!g_bL4DVersion)
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 0, 1, true);
			else
			SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 4, 1, true);

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
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) // player is connected and is not fake and it's in game ...
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
	if (temp) CreateTimer(0.1, kickbot, temp);
	
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
	if (GetEntProp(client, Prop_Send, "m_isGhost"))
		return true;
	return false;
}

bool:PlayerIsAlive (client)
{
	if (!GetEntProp(client,Prop_Send, "m_lifeState"))
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
		SetEntProp(client, Prop_Send, "m_isGhost", 1);
	else
	SetEntProp(client, Prop_Send, "m_isGhost", 0);
}

SetLifeState (client, bool:ready)
{
	if (ready)
		SetEntProp(client, Prop_Send, "m_lifeState", 1);
	else
	SetEntProp(client, Prop_Send, "m_lifeState", 0);
}

public Action:kickbot(Handle:timer, any:value)
{
	KickThis(value);
}

KickThis (client)
{
	
	if (IsClientConnected(client) && (!IsClientInKickQueue(client)))
	{
		if (IsFakeClient(client)) KickClient(client,"Kick");
	}
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

public Action:InitiateMenuAdmin(client, args) 
{
	decl String:name[MAX_NAME_LENGTH], String:number[10];
	
	new Handle:menu = CreateMenu(ShowMenu2);
	SetMenuTitle(menu, "Select a client:");
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) != TEAM_SURVIVORS) continue;
		if (i == client) continue;
		
		Format(name, sizeof(name), "%N", i);
		Format(number, sizeof(number), "%i", i);
		AddMenuItem(menu, number, name);
	}
	
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public ShowMenu2(Handle:menu, MenuAction:action, param1, param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			decl String:number[4];
			GetMenuItem(menu, param2, number, sizeof(number));
			
			g_iSelectedClient = StringToInt(number);
			
			new args;
			ShowMenuAdmin(param1, args);
		}
		case MenuAction_Cancel:
		{
			
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}

public Action:ShowMenuAdmin(client, args) 
{
	decl String:sMenuEntry[8];
	
	new Handle:menu = CreateMenu(CharMenuAdmin);
	SetMenuTitle(menu, "Choose a character:");
	{
		{
		AddMenuItem(menu, "0", "Zoey");
		AddMenuItem(menu, "1", "Francis");
		AddMenuItem(menu, "2", "Louis");
		AddMenuItem(menu, "3", "Bill");
		AddMenuItem(menu, "4", "Nick");
		AddMenuItem(menu, "5", "Rochelle");
		AddMenuItem(menu, "6", "Coach");
		AddMenuItem(menu, "7", "Ellis");
		}		
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public CharMenuAdmin(Handle:menu, MenuAction:action, param1, param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			decl String:item[8];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			switch(StringToInt(item)) 
			{
				case 0:	{	SetUpSurvivor(g_iSelectedClient, 0);	}
				case 1:	{	SetUpSurvivor(g_iSelectedClient, 1);	}
				case 2:	{	SetUpSurvivor(g_iSelectedClient, 2);	}
				case 3:	{	SetUpSurvivor(g_iSelectedClient, 3);	}
				case 4:	{	SetUpSurvivor(g_iSelectedClient, 4);	}
				case 5:	{	SetUpSurvivor(g_iSelectedClient, 5);	}
				case 6:	{	SetUpSurvivor(g_iSelectedClient, 6);	}
				case 7:	{	SetUpSurvivor(g_iSelectedClient, 7);	}

			}
		}
		case MenuAction_Cancel:
		{
			
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}

////////