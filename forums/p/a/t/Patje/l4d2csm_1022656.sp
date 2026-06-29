/********************************************************************************************
* Plugin	: [L4D2] Character Select Menu
* Version	: 1.4
* Game		: Left 4 Dead 2
* Author	: Patje
* Testers	: Myself
* Website	: N/A
* 
* 
* Purpose	: Allows players to change their in game character or model!
* 
* Version 1.4	
*		- added Equal, that allow all players to change ther model
*
* Version 1.3
* 		- Added a timer to the Gamemode ConVarHook to ensure compatitbilty with other gamemode changing plugins
* 		- Survivors can now become Infected and vice versa (Character or model) (L4D2 only)
* 		- Added Boomette (L4D2 only)
* 		- Added Uncommon infected (model only) (L4D2 only)
* 	    	- Fixed bug where the survivor menu would appear even if its turned off
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
#define PLUGIN_VERSION "1.3"
#define PLUGIN_NAME "[L4D2] Character Select Menu"
#define DEBUG 0
#pragma semicolon 1
#define TEAM_SPECTATOR		1
#define TEAM_SURVIVORS 		2
#define TEAM_INFECTED 		3
#define ZOMBIECLASS_TANK	8

// includes
#include <sourcemod>
#include <sdktools>

// Cvar Handles
new Handle:g_hActivate;
new Handle:h_Fun;
new Handle:h_Equal;
new Handle:h_GameMode;
new Handle:g_hInfectedMenu;
new Handle:g_hSurvivorMenu;
new Handle:g_hChangeLimit;

// Variables
new g_GameMode; // Used to determine the gamemode

// Arrays
new bool:OneToSpawn[MAXPLAYERS+1]; // Used to tell the plugin that this client will be the one to spawn and not place any spawn restrictions on that client
new g_ChangeLimitPlayer[MAXPLAYERS+1];

// Bools
new bool:DoNotUseConVarHook;

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "MI 5",
	description = "Allows players to change their in game character or model",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	
	// Register the version cvar
	CreateConVar("l4d2_csm_version", PLUGIN_VERSION, "Version of L4D2 Character Select Menu", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// convars
	
	// Fun Cvar
	h_Fun = CreateConVar("l4d2_csm_fun_mode", "0", "If 1, players will be able to change their models on the csm", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	// Equal Cvar
	h_Equal = CreateConVar("l4d2_csm_equal_mode", "1", "If 1, players will be able to change their character on the csm", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	// Activate Cvar
	g_hActivate = CreateConVar("l4d2_csm_enable", "1", "If 1, character select menu is activated", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	// Infected Menu cvar
	g_hInfectedMenu = CreateConVar("l4d2_csm_infected_menu", "1", "If 1, Infected Menu will be shown to players", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	// Survivor Menu cvar
	g_hSurvivorMenu = CreateConVar("l4d2_csm_survivor_menu", "1", "If 1, Survivor Menu will be shown to players", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	// Change Limit cvar
	g_hChangeLimit = CreateConVar("l4d2_csm_change_limit", "9999", "Sets the amount of times a client can change their character", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);
	HookConVarChange(g_hChangeLimit, ConVarChangeLimit);
	
	// Grab Gamemode value
	h_GameMode = FindConVar("mp_gamemode");
	HookConVarChange(h_GameMode, ConVarGameMode);
	
	// Hook Events
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	// config file
	AutoExecConfig(true, "l4d2csm");
	
	// sourcemod command
	RegConsoleCmd("sm_csm", PlayerMenuActivator);
}

public ConVarGameMode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// If the plugin is changing the gamemode manually, don't execute this convar hook
	
	if (DoNotUseConVarHook)
		return;
	
	CreateTimer(2.0, GameModeCheck);
}

public ConVarChangeLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		g_ChangeLimitPlayer[i] = GetConVarInt(g_hChangeLimit);
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
	CreateTimer(0.1, GameModeCheck);
	
	for (new i = 1; i <= MaxClients; i++) 
	{
		g_ChangeLimitPlayer[i] = GetConVarInt(g_hChangeLimit);
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// We get the client id
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// If client is valid
	if (client == 0) return Plugin_Continue;
	if (!IsClientConnected(client)) return Plugin_Continue;
	if (!IsClientInGame(client)) return Plugin_Continue;
	
	g_ChangeLimitPlayer[client] = GetConVarInt(g_hChangeLimit);
	
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	// If is a bot, skip this function
	if (IsFakeClient(client))
		return;
	
	g_ChangeLimitPlayer[client] = GetConVarInt(g_hChangeLimit);
}

public Action:GameModeCheck(Handle:timer)
{
	#if DEBUG
	LogMessage("Checking Gamemode");
	#endif
	//MI 5, We determine what the gamemode is
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
		g_GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		g_GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		g_GameMode = 1;
	else
	{
		g_GameMode = 0;
	}
}

public CharMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:item[256], String:display[256];
		
		GetMenuItem(menu, param2, item, sizeof(item), _, display, sizeof(display));
		
		if (StrEqual(item, "nick"))
		{
			if ((GetClientTeam(param1)) == TEAM_INFECTED)
			{
				SetGhostStatus(param1, true);
				
				new bot = CreateFakeClient("Fake Survivor");
				ChangeClientTeam(bot,2);
				DispatchKeyValue(bot,"classname","SurvivorBot");
				DispatchSpawn(bot);
				CreateTimer(0.1,kickbot,bot);
				
				// Check to see if they have the root admin flag, give it to them if they don't have it
				new admindata = GetUserFlagBits(param1);
				
				if (FindConVar("sm_admin_cheats_version") != INVALID_HANDLE)
				{
					SetUserFlagBits(param1, ADMFLAG_ROOT);
				}
				
				// enable the z_spawn command without sv_cheats
				new flags = GetCommandFlags("sb_takecontrol");
				SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
				
				FakeClientCommand(param1, "sb_takecontrol");
				
				// restore z_spawn and user flags
				SetCommandFlags("sb_takecontrol", flags);
				if (FindConVar("sm_admin_cheats_version") != INVALID_HANDLE)
				{
					SetUserFlagBits(param1, admindata);
				}
				SetGhostStatus(param1, false);
				
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"),TEAM_INFECTED);
			}
			
			// get prop
			new offset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
			new char = GetEntData(param1, offset, 1);
			
			// set char
			char = 0;
			SetEntData(param1, offset, char, 1, true);
			
			// update client model info
			decl String:model[] = "models/survivors/survivor_gambler.mdl";
			SetEntityModel(param1, model);
			
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Nick \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		else if (StrEqual(item, "nick_fun"))
		{
			decl String:model[] = "models/survivors/survivor_gambler.mdl";
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now \x03Nick \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "rochelle"))
		{
			if ((GetClientTeam(param1)) == TEAM_INFECTED)
			{
				SetGhostStatus(param1, true);
				
				new bot = CreateFakeClient("Fake Survivor");
				ChangeClientTeam(bot,2);
				DispatchKeyValue(bot,"classname","SurvivorBot");
				DispatchSpawn(bot);
				CreateTimer(0.1,kickbot,bot);
				
				// Check to see if they have the root admin flag, give it to them if they don't have it
				new admindata = GetUserFlagBits(param1);
				
				if (FindConVar("sm_admin_cheats_version") != INVALID_HANDLE)
				{
					SetUserFlagBits(param1, ADMFLAG_ROOT);
				}
				
				// enable the z_spawn command without sv_cheats
				new flags = GetCommandFlags("sb_takecontrol");
				SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
				
				FakeClientCommand(param1, "sb_takecontrol");
				
				// restore z_spawn and user flags
				SetCommandFlags("sb_takecontrol", flags);
				if (FindConVar("sm_admin_cheats_version") != INVALID_HANDLE)
				{
					SetUserFlagBits(param1, admindata);
				}
				SetGhostStatus(param1, false);
				
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"),TEAM_INFECTED);
			}
			
			// get prop
			new offset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
			new char = GetEntData(param1, offset, 1);
			
			// set char
			char = 1;
			SetEntData(param1, offset, char, 1, true);
			
			// update client model info
			decl String:model[] = "models/survivors/survivor_producer.mdl";
			SetEntityModel(param1, model);
			
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Rochelle \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		else if (StrEqual(item, "rochelle_fun"))
		{
			decl String:model[] = "models/survivors/survivor_producer.mdl";
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now \x03Rochelle \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "coach"))
		{
			if ((GetClientTeam(param1)) == TEAM_INFECTED)
			{
				SetGhostStatus(param1, true);
				
				new bot = CreateFakeClient("Fake Survivor");
				ChangeClientTeam(bot,2);
				DispatchKeyValue(bot,"classname","SurvivorBot");
				DispatchSpawn(bot);
				CreateTimer(0.1,kickbot,bot);
				
				// Check to see if they have the root admin flag, give it to them if they don't have it
				new admindata = GetUserFlagBits(param1);
				
				if (FindConVar("sm_admin_cheats_version") != INVALID_HANDLE)
				{
					SetUserFlagBits(param1, ADMFLAG_ROOT);
				}
				
				// enable the z_spawn command without sv_cheats
				new flags = GetCommandFlags("sb_takecontrol");
				SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
				
				FakeClientCommand(param1, "sb_takecontrol");
				
				// restore z_spawn and user flags
				SetCommandFlags("sb_takecontrol", flags);
				if (FindConVar("sm_admin_cheats_version") != INVALID_HANDLE)
				{
					SetUserFlagBits(param1, admindata);
				}
				SetGhostStatus(param1, false);
				
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"),TEAM_INFECTED);
			}
			
			// get prop
			new offset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
			new char = GetEntData(param1, offset, 1);
			
			// set char
			char = 2;
			SetEntData(param1, offset, char, 1, true);
			
			// update client model info
			decl String:model[] = "models/survivors/survivor_coach.mdl";
			SetEntityModel(param1, model);
			
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Coach \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		else if (StrEqual(item, "coach_fun"))
		{
			decl String:model[] = "models/survivors/survivor_coach.mdl";
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now \x03Coach \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		
		else if (StrEqual(item, "ellis"))
		{
			
			if ((GetClientTeam(param1)) == TEAM_INFECTED)
			{
				SetGhostStatus(param1, true);
				
				new bot = CreateFakeClient("Fake Survivor");
				ChangeClientTeam(bot,2);
				DispatchKeyValue(bot,"classname","SurvivorBot");
				DispatchSpawn(bot);
				CreateTimer(0.1,kickbot,bot);
				
				// Check to see if they have the root admin flag, give it to them if they don't have it
				new admindata = GetUserFlagBits(param1);
				
				if (FindConVar("sm_admin_cheats_version") != INVALID_HANDLE)
				{
					SetUserFlagBits(param1, ADMFLAG_ROOT);
				}
				
				// enable the z_spawn command without sv_cheats
				new flags = GetCommandFlags("sb_takecontrol");
				SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
				
				FakeClientCommand(param1, "sb_takecontrol");
				
				// restore z_spawn and user flags
				SetCommandFlags("sb_takecontrol", flags);
				if (FindConVar("sm_admin_cheats_version") != INVALID_HANDLE)
				{
					SetUserFlagBits(param1, admindata);
				}
				SetGhostStatus(param1, false);
				
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"),TEAM_INFECTED);
			}
			
			// get prop
			new offset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
			new char = GetEntData(param1, offset, 1);
			
			// set char
			char = 3;
			SetEntData(param1, offset, char, 1, true);
			
			// update client model info
			decl String:model[] = "models/survivors/survivor_mechanic.mdl";
			SetEntityModel(param1, model);
			
			PrintToChat(param1, "\x05[ \x01You're now playing as \x03Ellis \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		else if (StrEqual(item, "ellis_fun"))
		{
			decl String:model[] = "models/survivors/survivor_mechanic.mdl";
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now \x03Ellis \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "smoker"))
		{
			new bool:playersurvivor = false;
			
			if ((GetClientTeam(param1)) == TEAM_SURVIVORS)
			{
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_INFECTED);
				playersurvivor = true;
			}
			
			// Set the player as a ghost so that it can take the spawned infected
			SetGhostStatus(param1, true);
			
			// Set the player as the one to spawn so no spawn restrictions apply to that client
			OneToSpawn[param1] = true;
			
			// Tell the spawn infected function that it will spawn a smoker
			new InfectedTicket = 2;
			
			// Start the Spawn infected function
			Spawn_Infected(InfectedTicket);
			
			// The client is no longer the one to spawn as the client has already spawned
			OneToSpawn[param1] = false;
			
			// Set the client back to life
			SetGhostStatus(param1, false);
			
			if (playersurvivor)
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_SURVIVORS);
			
			// And Done!
			PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Smoker \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		else if (StrEqual(item, "smoker_fun"))
		{
			decl String:model[] = "models/infected/smoker.mdl";
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Smoker \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		
		else if (StrEqual(item, "boomer"))
		{
			new bool:playersurvivor = false;
			
			if ((GetClientTeam(param1)) == TEAM_SURVIVORS)
			{
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_INFECTED);
				playersurvivor = true;
			}
			
			// Set the player as a ghost so that it can take the spawned infected
			SetGhostStatus(param1, true);
			
			// Set the player as the one to spawn so no spawn restrictions apply to that client
			OneToSpawn[param1] = true;
			
			// Tell the spawn infected function that it will spawn a boomer
			new InfectedTicket = 3;
			
			// Start the Spawn infected function
			Spawn_Infected(InfectedTicket);
			
			// The client is no longer the one to spawn as the client has already spawned
			OneToSpawn[param1] = false;
			
			// Set the client back to life
			SetGhostStatus(param1, false);
			
			if (playersurvivor)
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_SURVIVORS);
			
			// And Done!
			PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Boomer \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		else if (StrEqual(item, "boomer_fun"))
		{
			decl String:model[] = "models/infected/boomer.mdl";
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Boomer \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "boomette"))
		{
			new bool:playersurvivor = false;
			
			if ((GetClientTeam(param1)) == TEAM_SURVIVORS)
			{
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_INFECTED);
				playersurvivor = true;
			}
			
			// Set the player as a ghost so that it can take the spawned infected
			SetGhostStatus(param1, true);
			
			// Set the player as the one to spawn so no spawn restrictions apply to that client
			OneToSpawn[param1] = true;
			
			// Tell the spawn infected function that it will spawn a boomer
			new InfectedTicket = 3;
			
			// Start the Spawn infected function
			Spawn_Infected(InfectedTicket);
			
			// The client is no longer the one to spawn as the client has already spawned
			OneToSpawn[param1] = false;
			
			// Set the client back to life
			SetGhostStatus(param1, false);
			
			if (playersurvivor)
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_SURVIVORS);
			
			// Change the model for the boomette
			decl String:model[] = "models/infected/boomette.mdl";
			SetEntityModel(param1, model);
			
			// And Done!
			PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Boomette \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		else if (StrEqual(item, "boomette_fun"))
		{
			decl String:model[] = "models/infected/boomette.mdl";
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Boomette \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		
		else if (StrEqual(item, "hunter"))
		{
			new bool:playersurvivor = false;
			
			if ((GetClientTeam(param1)) == TEAM_SURVIVORS)
			{
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_INFECTED);
				playersurvivor = true;
			}
			
			// Set the player as a ghost so that it can take the spawned infected
			SetGhostStatus(param1, true);
			
			// Set the player as the one to spawn so no spawn restrictions apply to that client
			OneToSpawn[param1] = true;
			
			// Tell the spawn infected function that it will spawn a hunter
			new InfectedTicket = 1;
			
			// Start the Spawn infected function
			Spawn_Infected(InfectedTicket);
			
			// The client is no longer the one to spawn as the client has already spawned
			OneToSpawn[param1] = false;
			
			// Set the client back to life
			SetGhostStatus(param1, false);
			
			if (playersurvivor)
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_SURVIVORS);
			
			// And Done!
			PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Hunter \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		else if (StrEqual(item, "hunter_fun"))
		{
			decl String:model[] = "models/infected/hunter.mdl";
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Hunter \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		
		else if (StrEqual(item, "tank"))
		{
			new bool:playersurvivor = false;
			
			if ((GetClientTeam(param1)) == TEAM_SURVIVORS)
			{
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_INFECTED);
				playersurvivor = true;
			}
			
			// Set the player as a ghost so that it can take the spawned infected
			SetGhostStatus(param1, true);
			
			// Set the player as the one to spawn so no spawn restrictions apply to that client
			OneToSpawn[param1] = true;
			
			// Tell the spawn infected function that it will spawn a tank
			new InfectedTicket = 4;
			
			// Start the Spawn infected function
			Spawn_Infected(InfectedTicket);
			
			// The client is no longer the one to spawn as the client has already spawned
			OneToSpawn[param1] = false;
			
			// Set the client back to life
			SetGhostStatus(param1, false);
			
			if (playersurvivor)
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_SURVIVORS);
			
			// And Done!
			PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Tank! \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		else if (StrEqual(item, "tank_fun"))
		{
			decl String:model[] = "models/infected/hulk.mdl";
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Tank! \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "charger"))
		{
			new bool:playersurvivor = false;
			
			if ((GetClientTeam(param1)) == TEAM_SURVIVORS)
			{
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_INFECTED);
				playersurvivor = true;
			}
			
			// Set the player as a ghost so that it can take the spawned infected
			SetGhostStatus(param1, true);
			
			// Set the player as the one to spawn so no spawn restrictions apply to that client
			OneToSpawn[param1] = true;
			
			// Tell the spawn infected function that it will spawn a tank
			new InfectedTicket = 5;
			
			// Start the Spawn infected function
			Spawn_Infected(InfectedTicket);
			
			// The client is no longer the one to spawn as the client has already spawned
			OneToSpawn[param1] = false;
			
			// Set the client back to life
			SetGhostStatus(param1, false);
			
			if (playersurvivor)
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_SURVIVORS);
			
			// And Done!
			PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Charger \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		else if (StrEqual(item, "charger_fun"))
		{
			decl String:model[] = "models/infected/charger.mdl";
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Charger \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "jockey"))
		{
			new bool:playersurvivor = false;
			
			if ((GetClientTeam(param1)) == TEAM_SURVIVORS)
			{
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_INFECTED);
				playersurvivor = true;
			}
			
			// Set the player as a ghost so that it can take the spawned infected
			SetGhostStatus(param1, true);
			
			// Set the player as the one to spawn so no spawn restrictions apply to that client
			OneToSpawn[param1] = true;
			
			// Tell the spawn infected function that it will spawn a tank
			new InfectedTicket = 6;
			
			// Start the Spawn infected function
			Spawn_Infected(InfectedTicket);
			
			// The client is no longer the one to spawn as the client has already spawned
			OneToSpawn[param1] = false;
			
			// Set the client back to life
			SetGhostStatus(param1, false);
			
			if (playersurvivor)
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_SURVIVORS);
			
			// And Done!
			PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Jockey \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		else if (StrEqual(item, "jockey_fun"))
		{
			decl String:model[] = "models/infected/jockey.mdl";
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Jockey \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "spitter"))
		{
			new bool:playersurvivor = false;
			
			if ((GetClientTeam(param1)) == TEAM_SURVIVORS)
			{
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_INFECTED);
				playersurvivor = true;
			}
			
			// Set the player as a ghost so that it can take the spawned infected
			SetGhostStatus(param1, true);
			
			// Set the player as the one to spawn so no spawn restrictions apply to that client
			OneToSpawn[param1] = true;
			
			// Tell the spawn infected function that it will spawn a tank
			new InfectedTicket = 7;
			
			// Start the Spawn infected function
			Spawn_Infected(InfectedTicket);
			
			// The client is no longer the one to spawn as the client has already spawned
			OneToSpawn[param1] = false;
			
			// Set the client back to life
			SetGhostStatus(param1, false);
			
			if (playersurvivor)
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_SURVIVORS);
			
			// And Done!
			PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Spitter \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		else if (StrEqual(item, "spitter_fun"))
		{
			decl String:model[] = "models/infected/spitter.mdl";
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Spitter \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "witch"))
		{
			new bool:playersurvivor = false;
			
			if ((GetClientTeam(param1)) == TEAM_SURVIVORS)
			{
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_INFECTED);
				playersurvivor = true;
			}
			
			// Set the player as a ghost so that it can take the spawned infected
			SetGhostStatus(param1, true);
			
			// Set the player as the one to spawn so no spawn restrictions apply to that client
			OneToSpawn[param1] = true;
			
			// Tell the spawn infected function that it will spawn a hunter
			new InfectedTicket = 1;
			
			// Start the Spawn infected function
			Spawn_Infected(InfectedTicket);
			
			// The client is no longer the one to spawn as the client has already spawned
			OneToSpawn[param1] = false;
			
			// Set the client back to life
			SetGhostStatus(param1, false);
			
			if (playersurvivor)
				SetEntData(param1, FindSendPropInfo("CTerrorPlayer", "m_iTeamNum"), TEAM_SURVIVORS);
			
			// update client model info
			
			// Change the hunter model into the witch's model (if I changed the actual zombie class, it would cause crashes)
			decl String:model[] = "models/infected/witch.mdl";
			SetEntityModel(param1, model);
			
			// And Done!
			PrintToChat(param1, "\x05[ \x01You're now playing as a \x03Witch! \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		else if (StrEqual(item, "witch_fun"))
		{
			decl String:model[] = "models/infected/witch.mdl";
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Witch! \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "ceda"))
		{
			decl String:model[] = "models/infected/common_male_ceda.mdl";
			PrecacheModel(model);
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Ceda Hazmat Operative! \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "clown"))
		{
			decl String:model[] = "models/infected/common_male_clown.mdl";
			PrecacheModel(model);
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Clown Infected! \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "mud"))
		{
			decl String:model[] = "models/infected/common_male_mud.mdl";
			PrecacheModel(model);
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Mud Man Infected! \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "roadcrew"))
		{
			decl String:model[] = "models/infected/common_male_roadcrew.mdl";
			PrecacheModel(model);
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Construction worker! \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "riot"))
		{
			decl String:model[] = "models/infected/common_male_riot.mdl";
			PrecacheModel(model);
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Riot Infected! \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "fallen"))
		{
			decl String:model[] = "models/infected/common_male_fallen_survivor.mdl";
			PrecacheModel(model);
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Fallen Survivor! \x05]");
			g_ChangeLimitPlayer[param1]--;
		}
		
		else if (StrEqual(item, "jimmy"))
		{
			decl String:model[] = "models/infected/common_male_jimmy.mdl.mdl";
			PrecacheModel(model);
			SetEntityModel(param1, model);
			PrintToChat(param1, "\x05[ \x01Your model is now a \x03Jimmy Gibbs Jr.! \x05]");
			g_ChangeLimitPlayer[param1]--;
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
		PrintHintText(client, "[SM] L4D2 Character Select Menu: Type !csm in chat to select your character!");
	}
}

public Action:PlayerMenu(Handle:timer, any:client)
{
	
	new Handle:menu = CreateMenu(CharMenu);
	SetMenuTitle(menu, "Choose a character:");
	
	if (GetClientHealth(client) > 1)
	{
		if (GetClientTeam(client) == TEAM_SURVIVORS && GetConVarBool(g_hSurvivorMenu) && g_ChangeLimitPlayer[client] >= 1 || GetClientTeam(client) == TEAM_INFECTED && GetUserFlagBits(client) != 0 && GetConVarBool(g_hSurvivorMenu) && g_ChangeLimitPlayer[client] >= 1)
		{
			AddMenuItem(menu, "nick", "Nick");
			AddMenuItem(menu, "rochelle", "Rochelle");
			AddMenuItem(menu, "coach", "Coach");
			AddMenuItem(menu, "ellis", "Ellis");
		}
		
		if (GetConVarBool(h_Fun) && GetConVarBool(g_hSurvivorMenu) && g_ChangeLimitPlayer[client] >= 1 || GetUserFlagBits(client) != 0 && GetConVarBool(g_hSurvivorMenu) && g_ChangeLimitPlayer[client] >= 1)
		{
			AddMenuItem(menu, "nick_fun", "Nick(Model)");
			AddMenuItem(menu, "rochelle_fun", "Rochelle(Model)");
			AddMenuItem(menu, "coach_fun", "Coach(Model)");
			AddMenuItem(menu, "ellis_fun", "Ellis(Model)");
		}

		if (GetConVarBool(h_Equal) && GetConVarBool(g_hSurvivorMenu) && g_ChangeLimitPlayer[client] >= 1 || GetUserFlagBits(client) != 0 && GetConVarBool(g_hSurvivorMenu) && g_ChangeLimitPlayer[client] >= 1)
		{
			AddMenuItem(menu, "nick", "Nick");
			AddMenuItem(menu, "rochelle", "Rochelle");
			AddMenuItem(menu, "coach", "Coach");
			AddMenuItem(menu, "ellis", "Ellis");
		}
		
		if (GetUserFlagBits(client) != 0 && GetConVarBool(g_hInfectedMenu) && g_ChangeLimitPlayer[client] >= 1)
		{
			AddMenuItem(menu, "smoker", "Smoker");
			AddMenuItem(menu, "boomer", "Boomer");
			AddMenuItem(menu, "boomette", "Boomette");
			AddMenuItem(menu, "hunter", "Hunter");
			AddMenuItem(menu, "tank", "Tank");
			AddMenuItem(menu, "charger", "Charger");
			AddMenuItem(menu, "jockey", "Jockey");
			AddMenuItem(menu, "spitter", "Spitter");
			AddMenuItem(menu, "witch", "Witch");
		}
		
		if (GetConVarBool(h_Fun) && GetConVarBool(g_hInfectedMenu) && g_ChangeLimitPlayer[client] >= 1 || GetUserFlagBits(client) != 0 && GetConVarBool(g_hInfectedMenu) && g_ChangeLimitPlayer[client] >= 1)
		{
			AddMenuItem(menu, "smoker_fun", "Smoker(Model)");
			AddMenuItem(menu, "boomer_fun", "Boomer(Model)");
			AddMenuItem(menu, "boomette_fun", "Boomette(Model)");
			AddMenuItem(menu, "hunter_fun", "Hunter(Model)");
			AddMenuItem(menu, "tank_fun", "Tank(Model)");
			AddMenuItem(menu, "charger_fun", "Charger(Model)");
			AddMenuItem(menu, "jockey_fun", "Jockey(Model)");
			AddMenuItem(menu, "spitter_fun", "Spitter(Model)");
			AddMenuItem(menu, "witch_fun", "Witch(Model)");
			AddMenuItem(menu, "ceda", "CEDA Hazmat(Model)");
			AddMenuItem(menu, "clown", "Clown(Model)");
			AddMenuItem(menu, "mud", "Mud Man(Model)");
			AddMenuItem(menu, "roadcrew", "Construction Worker(Model)");
			AddMenuItem(menu, "riot", "Riot Officer(Model)");
			AddMenuItem(menu, "fallen", "Fallen Survivor(Model)");
			AddMenuItem(menu, "jimmy", "Jimmy Gibbs Jr.(Model)");
		}

		if (GetConVarBool(h_Equal) && GetConVarBool(g_hInfectedMenu) && g_ChangeLimitPlayer[client] >= 1 || GetUserFlagBits(client) != 0 && GetConVarBool(g_hInfectedMenu) && g_ChangeLimitPlayer[client] >= 1)
		{
			AddMenuItem(menu, "smoker", "Smoker");
			AddMenuItem(menu, "boomer", "Boomer");
			AddMenuItem(menu, "boomette", "Boomette");
			AddMenuItem(menu, "hunter", "Hunter");
			AddMenuItem(menu, "tank", "Tank");
			AddMenuItem(menu, "charger", "Charger");
			AddMenuItem(menu, "jockey", "Jockey");
			AddMenuItem(menu, "spitter", "Spitter");
			AddMenuItem(menu, "witch", "Witch");
			AddMenuItem(menu, "ceda", "CEDA Hazmat(Model)");
			AddMenuItem(menu, "clown", "Clown(Model)");
			AddMenuItem(menu, "mud", "Mud Man(Model)");
			AddMenuItem(menu, "roadcrew", "Construction Worker(Model)");
			AddMenuItem(menu, "riot", "Riot Officer(Model)");
			AddMenuItem(menu, "fallen", "Fallen Survivor(Model)");
			AddMenuItem(menu, "jimmy", "Jimmy Gibbs Jr.(Model)");
		}
		if (g_ChangeLimitPlayer[client] < 1)
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

Spawn_Infected(InfectedTicket)
{
	// Before spawning the bot, we determine if an real infected player is dead, since the new infected bot will be controlled by this player
	new bool:resetGhost[MAXPLAYERS+1];
	new bool:resetDead[MAXPLAYERS+1];
	new bool:resetLife[MAXPLAYERS+1];
	
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientConnected(i) && (!IsFakeClient(i)) && IsClientInGame(i)) // player is connected and is not fake and it's in game ...
		{
			// If player is on infected's team and is dead ..
			if (GetClientTeam(i)==TEAM_INFECTED)
			{
				if (OneToSpawn[i] == false)
				{
					// If player is a ghost ....
					if (IsPlayerGhost(i))
					{
						resetGhost[i] = true;
						SetGhostStatus(i, false);
						resetDead[i] = true;
						SetAliveStatus(i, true);
						#if DEBUG
						LogMessage("Player is a ghost, taking preventive measures for spawning an infected bot");
						#endif
					}
					else if (!IsPlayerAlive(i)) // if player is just dead ...
					{
						resetLife[i] = true;
						SetLifeState(i, false);
					}
					else if (!IsPlayerAlive(i))
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
	if (anyclient == 0)
	{
		#if DEBUG
		LogMessage("[Character Select] Creating temp client to fake command");
		#endif
		// we create a fake client
		anyclient = CreateFakeClient("Bot");
		if (anyclient == 0)
		{
			LogError("[L4D2] Character Select: CreateFakeClient returned 0 -- Infected bot was not spawned");
			return;
		}
		temp = true;
	}
	
	new admindata = GetUserFlagBits(anyclient);
	if (FindConVar("sm_admin_cheats_version") != INVALID_HANDLE)
	{
		SetUserFlagBits(anyclient, ADMFLAG_ROOT);
	}
	
	new flags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
	
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	new CurrentGameMode;
	if (g_GameMode != 2)
	{
		// This is to tell the plugin not to execute the gamemode ConVarHook
		DoNotUseConVarHook = true;
		
		if (StrEqual(GameName, "coop", false))
		{
			CurrentGameMode = 1;
		}
		else if (StrEqual(GameName, "realism", false))
		{
			CurrentGameMode = 2;
		}
		else if (StrEqual(GameName, "survival", false))
		{
			CurrentGameMode = 3;
		}
		
		// Set the Gamemode to versus so that the spawned infected will spawn with a flashlight
		SetConVarString(FindConVar("mp_gamemode"), "versus");
	}
	
	// We spawn the bot ...
	switch (InfectedTicket)
	{
		case 1: // Hunter
		{
			#if DEBUG
			LogMessage("Spawning Hunter");
			#endif
			FakeClientCommand(anyclient, "z_spawn hunter auto");
		}
		case 2: // Smoker
		{	
			#if DEBUG
			LogMessage("Spawning Smoker");
			#endif
			FakeClientCommand(anyclient, "z_spawn smoker auto");
		}
		case 3: // Boomer
		{
			#if DEBUG
			LogMessage("Spawning Boomer");
			#endif
			FakeClientCommand(anyclient, "z_spawn boomer auto");
		}
		case 4: // Tank
		{
			#if DEBUG
			LogMessage("Spawning Tank");
			#endif
			FakeClientCommand(anyclient, "z_spawn tank auto");
		}
		case 5: // Charger
		{
			#if DEBUG
			LogMessage("Spawning Charger");
			#endif
			FakeClientCommand(anyclient, "z_spawn charger auto");
		}
		case 6: // Jockey
		{
			#if DEBUG
			LogMessage("Spawning Jockey");
			#endif
			FakeClientCommand(anyclient, "z_spawn jockey auto");
		}
		case 7: // Spitter
		{
			#if DEBUG
			LogMessage("Spawning Spitter");
			#endif
			FakeClientCommand(anyclient, "z_spawn spitter auto");
		}
	}
	
	if (g_GameMode != 2)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if(!IsClientInGame(i) || GetClientTeam(i) != 3) continue;
			if(!IsPlayerTank(i)) continue;
			
			#if DEBUG
			PrintToChatAll("Client %i found Tank", i);		
			PrintToChatAll("OLD: GetClientHealth: %i", GetClientHealth(i));
			PrintToChatAll("OLD: m_iHealth: %i",GetEntProp(i, Prop_Send, "m_iHealth"));
			#endif
			
			decl String:difficulty[100], tankhealth;
			GetConVarString(FindConVar("z_difficulty"), difficulty, sizeof(difficulty));
			// Check the difficulty mode and adjust the tank health from there
			if (StrEqual(difficulty, "Easy", false))
			{
				tankhealth = RoundFloat(float(GetConVarInt(FindConVar("z_tank_health")))*0.75);
				SetEntityHealth(i, tankhealth);
				SetEntProp(i, Prop_Send, "m_iMaxHealth", tankhealth);
			}
			else if (StrEqual(difficulty, "Normal", false))
			{
				tankhealth = RoundFloat(float(GetConVarInt(FindConVar("z_tank_health")))*1.0);
				SetEntityHealth(i, tankhealth);
				SetEntProp(i, Prop_Send, "m_iMaxHealth", tankhealth);
			}
			else if (StrEqual(difficulty, "Hard", false))
			{
				tankhealth = RoundFloat(float(GetConVarInt(FindConVar("z_tank_health")))*2.0);
				SetEntityHealth(i, tankhealth);
				SetEntProp(i, Prop_Send, "m_iMaxHealth", tankhealth);
			}
			else if (StrEqual(difficulty, "Impossible", false))
			{
				tankhealth = RoundFloat(float(GetConVarInt(FindConVar("z_tank_health")))*2.0);
				SetEntityHealth(i, tankhealth);
				SetEntProp(i, Prop_Send, "m_iMaxHealth", tankhealth);
			}
			
			#if DEBUG
			PrintToChatAll("NEW: GetClientHealth: %i", GetClientHealth(i));
			PrintToChatAll("NEW: m_iHealth: %i",GetEntProp(i, Prop_Send, "m_iHealth"));
			#endif
		}
	}
	// Restore the Gamemode
	switch (CurrentGameMode)
	{
		case 1: // coop
		SetConVarString(FindConVar("mp_gamemode"), "coop");
		case 2: // realism
		SetConVarString(FindConVar("mp_gamemode"), "realism");
		case 3: // survival
		SetConVarString(FindConVar("mp_gamemode"), "survival");
	}
	
	DoNotUseConVarHook = false;
	
	// restore z_spawn and user flags
	
	if (FindConVar("sm_admin_cheats_version") != INVALID_HANDLE)
	{
		SetUserFlagBits(anyclient, admindata);
	}
	SetCommandFlags("z_spawn", flags);
	
	// We restore the player's status
	for (new i=1;i<=MaxClients;i++)
	{
		if (resetGhost[i] == true)
			SetGhostStatus(i, true);
		if (resetDead[i] == true)
			SetAliveStatus(i, false);
		if (resetLife[i] == true)
			SetLifeState(i, true);
		//ChangeClientTeam(i, 3)
	}
	
	// If client was temp, we setup a timer to kick the fake player
	if (temp) CreateTimer(0.1,kickbot,anyclient);
}

bool:IsPlayerGhost (client)
{
	if (GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_isGhost"), 1))
		return true;
	return false;
}

bool:IsPlayerTank (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK)
		return true;
	return false;
}

SetAliveStatus (client, bool:alive)
{
	if (alive)
		SetEntData(client, FindSendPropInfo("CTransitioningPlayer", "m_isAlive"), 1, 1, true);
	else
	SetEntData(client, FindSendPropInfo("CTransitioningPlayer", "m_isAlive"), 0, 1, false);
}

SetGhostStatus (client, bool:ghost)
{
	if (ghost)
	{	
		SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_isGhost"), 1, 1, true);
		SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
	}
	else
	{
		SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_isGhost"), 0, 1, false);
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
}

SetLifeState (client, bool:ready)
{
	if (ready)
		SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_lifeState"), 1, 1, true);
	else
	SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_lifeState"), 0, 1, false);
}

public GetAnyClient ()
{
	#if DEBUG
	LogMessage("[Character Select] Looking for any real client to fake command");
	#endif
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && (!IsFakeClient(i)))
		{
			return i;
		}
	}
	return 0;
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

////////////////
