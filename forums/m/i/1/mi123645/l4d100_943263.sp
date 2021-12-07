/********************************************************************************************
* Plugin	: Left 4 100
* Version	: 1.7
* Game		: Left 4 Dead 1/2
* Author	: MI 5
* Testers	: Myself
* Website	: N/A
* 
* Purpose	: Provides an alternative fun gamemode!
* 
* Version 1.7
* 		- Compatible with the latest mutations
* 		- Removed "Incorrect gamemode" message
* 		- Survivors no longer die instantly by commons when incapped
* 
* Version 1.6
* 		- Fixed typo with game detection
* 		- Fixed bug in L4D2 with zombies not spawning correctly
* 		- Now compatible with mutations: Last Man on Earth, Chainsaw Massacre and Room for One
* 		- Plugin will not say "Incorrect Gamemode" if the plugin is not activated
* 
* Version 1.5
* 		- Compatible with new mutations
* 
* Version 1.4
* 		- L4D 1 and 2 versions of the plugin are now one
* 		- Tank health reduced drastically for coop, increased for versus
* 		- Lots of code rewritten along with optimizations
* 		- Fixed bug where the activation cvar would randomly have no effect
* 
* Version 1.3
* 		- Cvars that are changed by the plugin are reset when unloaded
* 		- Added a timer to the Gamemode ConVarHook to ensure compatitbilty with other gamemode changing plugins
* 
* Version 1.2
* 	    - Few optimizations here and there
* 		- Removed default difficulty "easy" (still recommend easy difficulty for this gamemode)
* 
* Version 1.1
* 		- Church Door problem fixed
* 		- Activation cvar being set 0 in the cfg now has effect
* 		- Redone Safe room detection method
* 
* Version 1.0
* 		- Initial release.
* 
* 
**********************************************************************************************/

#include <sourcemod>
#define DEBUG 0
#define PLUGIN_VERSION "1.7"
#pragma semicolon 1

// Variables

new g_GameMode;

// Handles

new Handle:g_h_Activate;
new Handle:g_h_GameMode;
new Handle:g_h_Message;

// Bools

new bool:g_b_LeavedSafeRoom; // States if the survivors have left the safe room
new bool:g_b_MessageDisplayed;
new bool:g_b_L4DVersion;
new bool:g_b_RoundStarted;

public Plugin:myinfo = 
{
	name = "[L4D/L4D2] Left 4 100",
	author = "MI 5",
	description = "Provides a new gamemode where the survivors have to race to the end while facing hordes and hordes of zombies!",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// Checks to see if the game is a L4D game. If it is, check if its the sequel. L4DVersion is L4D if false, L4D2 if true.
	decl String:GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrContains(GameName, "left4dead", false) == -1)
		return APLRes_Failure;
	else if (StrEqual(GameName, "left4dead2", false))
		g_b_L4DVersion = true;
	
	return APLRes_Success;
}

public OnPluginStart()
{
	// Hook some events
	
	HookEvent("item_pickup", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("finale_start", Event_FinaleStart);
	HookEvent("create_panic_event", Event_SurvivalStart);
	if (!g_b_L4DVersion)
		HookEvent("explain_church_door", Event_ChurchDoor);
	
	// Cvar to turn the plugin on or off
	
	// Activate cvar
	g_h_Activate = CreateConVar("l4d_100_enable", "1", "If 1, Left 4 100 is enabled", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	HookConVarChange(g_h_Activate, ConVarActivate);
	
	// Gamemode hook
	g_h_GameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_h_GameMode, ConVarGameMode);
	
	// Message cvar
	g_h_Message = CreateConVar("l4d_100_messages", "1", "If 1, Left 4 100 will display messages to players", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	// config file
	AutoExecConfig(true, "l4d100");
	
	// We register the version cvar
	CreateConVar("l4d_100_version", PLUGIN_VERSION, "Version of Left 4 100", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnPluginEnd()
{
	ResetConVar(FindConVar("z_common_limit"), true, true);
	ResetConVar(FindConVar("z_mega_mob_size"), true, true);
	ResetConVar(FindConVar("z_mob_spawn_max_size"), true, true);
	ResetConVar(FindConVar("z_mob_spawn_min_size"), true, true);
	ResetConVar(FindConVar("z_mob_spawn_finale_size"), true, true);
	ResetConVar(FindConVar("z_mega_mob_spawn_max_interval"), true, true);
	ResetConVar(FindConVar("z_mega_mob_spawn_min_interval"), true, true);
	ResetConVar(FindConVar("z_spawn_mobs_behind_chance"), true, true);
	ResetConVar(FindConVar("z_mob_population_density"), true, true);
	//ResetConVar(FindConVar("z_attack_incapacitated_damage"), true, true);
	ResetConVar(FindConVar("z_respawn_interval"), true, true);
	ResetConVar(FindConVar("director_no_bosses"), true, true);
	ResetConVar(FindConVar("director_no_specials"), true, true);
	ResetConVar(FindConVar("director_panic_forever"), true, true);
	ResetConVar(FindConVar("z_tank_health"), true, true);
	
	if (g_b_L4DVersion)
	{
		ResetConVar(FindConVar("tank_burn_duration"), true, true);
		ResetConVar(FindConVar("director_panic_wave_pause_max"), true, true);
		ResetConVar(FindConVar("director_panic_wave_pause_min"), true, true);
	}
	else
	{
		ResetConVar(FindConVar("tank_burn_duration_normal"), true, true);
		ResetConVar(FindConVar("z_tank_burning_lifetime"), true, true);
	}
	
	ResetConVar(FindConVar("tank_burn_duration_hard"), true, true);
	ResetConVar(FindConVar("tank_burn_duration_expert"), true, true);
}

public ConVarActivate(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(g_h_Activate))
	{
		GameModeCheck();
		if (g_GameMode == 1 || g_GameMode == 2)
		{  
			ChangeCvars();
			
			// We search for any player client to execute the force panic event command. If there isn't any, we create a fake client instead and execute it on him.
			
			new anyclient = GetAnyClient();
			new bool:temp = false;
			if (anyclient == -1)
			{
				#if DEBUG
				LogMessage("[L4D 100] Creating temp client to fake command");
				#endif
				// we create a fake client
				anyclient = CreateFakeClient("TempBot");
				if (anyclient == 0)
				{
					LogError("[L4D] 100: CreateFakeClient returned 0 -- TempBot was not spawned");
					return;
				}
				temp = true;
			}
			
			// Execute the command
			
			CheatCommand(anyclient, "director_force_panic_event");
			
			// If client was temp, we setup a timer to kick the fake player
			if (temp) CreateTimer(0.1,kickbot,anyclient);
			
			if (!g_b_MessageDisplayed && GetConVarBool(g_h_Message))
			{
				PrintHintTextToAll("L4D 100: GET TO THE END OF THE MAP BEFORE THE HORDE OVERCOMES YOU!");
				g_b_MessageDisplayed = true;
			}
		}
		if (g_GameMode == 3)
		{
			if (!g_b_MessageDisplayed && GetConVarBool(g_h_Message))
			{
				PrintHintTextToAll("L4D 100: THE HORDE IS COMING! HOLDOUT FOR AS LONG AS YOU CAN!");
				g_b_MessageDisplayed = true;
				ChangeCvars();
			}
		}
	}
	
	if (!GetConVarBool(g_h_Activate))
	{
		ResetConVar(FindConVar("z_common_limit"), true, true);
		ResetConVar(FindConVar("z_mega_mob_size"), true, true);
		ResetConVar(FindConVar("z_mob_spawn_max_size"), true, true);
		ResetConVar(FindConVar("z_mob_spawn_min_size"), true, true);
		ResetConVar(FindConVar("z_mob_spawn_finale_size"), true, true);
		ResetConVar(FindConVar("z_mega_mob_spawn_max_interval"), true, true);
		ResetConVar(FindConVar("z_mega_mob_spawn_min_interval"), true, true);
		ResetConVar(FindConVar("z_spawn_mobs_behind_chance"), true, true);
		ResetConVar(FindConVar("z_mob_population_density"), true, true);
		//ResetConVar(FindConVar("z_attack_incapacitated_damage"), true, true);
		ResetConVar(FindConVar("z_respawn_interval"), true, true);
		ResetConVar(FindConVar("director_no_bosses"), true, true);
		ResetConVar(FindConVar("director_no_specials"), true, true);
		ResetConVar(FindConVar("director_panic_forever"), true, true);
		ResetConVar(FindConVar("z_tank_health"), true, true);
		
		if (g_b_L4DVersion)
		{
			ResetConVar(FindConVar("tank_burn_duration"), true, true);
			ResetConVar(FindConVar("director_panic_wave_pause_max"), true, true);
			ResetConVar(FindConVar("director_panic_wave_pause_min"), true, true);
		}
		else
		{
			ResetConVar(FindConVar("tank_burn_duration_normal"), true, true);
			ResetConVar(FindConVar("z_tank_burning_lifetime"), true, true);
		}
		
		ResetConVar(FindConVar("tank_burn_duration_hard"), true, true);
		ResetConVar(FindConVar("tank_burn_duration_expert"), true, true);
	}
}

public ConVarGameMode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GameModeCheck();
	if (GetConVarBool(g_h_Activate))
	{
		ChangeCvars();
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// if the glove don't fit, gotta aquit
	if (g_b_RoundStarted)
		return;
	
	g_b_RoundStarted = true;
	g_b_LeavedSafeRoom = false;
	g_b_MessageDisplayed = false;
	
	//Check the GameMode
	GameModeCheck();
	
	if (GetConVarBool(g_h_Activate))
	{
		ChangeCvars();
		
		if (g_GameMode == 1 || g_GameMode == 2)
		{
			CreateTimer(1.0, PlayerLeftStart);
		}
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_b_LeavedSafeRoom = false;
	g_b_RoundStarted = false;
}

// Checks the current GameMode

GameModeCheck()
{
	#if DEBUG
	LogMessage("Checking Gamemode");
	#endif
	// We determine what the gamemode is
	decl String:GameName[16];
	GetConVarString(g_h_GameMode, GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false) || StrEqual(GameName, "mutation15", false))
		g_GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false) || StrEqual(GameName, "mutation12", false) || StrEqual(GameName, "mutation13", false) || StrEqual(GameName, "mutation11", false))
		g_GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false) || StrEqual(GameName, "mutation3", false) || StrEqual(GameName, "mutation9", false) || StrEqual(GameName, "mutation1", false) || StrEqual(GameName, "mutation7", false) || StrEqual(GameName, "mutation10", false) || StrEqual(GameName, "mutation2", false) || StrEqual(GameName, "mutation4", false) || StrEqual(GameName, "mutation5", false) || StrEqual(GameName, "mutation14", false))
		g_GameMode = 1;
	else
	g_GameMode = 1;
}

ChangeCvars()
{
	SetConVarInt(FindConVar("z_common_limit"), 100);
	SetConVarInt(FindConVar("z_mega_mob_size"), 100);
	SetConVarInt(FindConVar("z_mob_spawn_max_size"), 100);
	SetConVarInt(FindConVar("z_mob_spawn_min_size"), 100);
	SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 100);
	SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), 200);
	SetConVarInt(FindConVar("z_mega_mob_spawn_min_interval"), 100);
	SetConVarInt(FindConVar("z_mob_population_density"), 4);
	//SetConVarInt(FindConVar("z_attack_incapacitated_damage"), 500);
	SetConVarInt(FindConVar("z_respawn_interval"), 1);
	if (g_GameMode != 3)
	{
		SetConVarInt(FindConVar("z_spawn_mobs_behind_chance"), 10);
		SetConVarInt(FindConVar("director_panic_forever"), 1);
	}
	else
	{
		SetConVarInt(FindConVar("z_spawn_mobs_behind_chance"), 50);
		SetConVarInt(FindConVar("director_panic_forever"), 0);
	}
	SetConVarInt(FindConVar("director_no_bosses"), 1);
	SetConVarInt(FindConVar("director_no_specials"), 1);
	ResetConVar(FindConVar("z_tank_health"), true, true);
	if (g_b_L4DVersion)
	{
		ResetConVar(FindConVar("tank_burn_duration"), true, true);
		SetConVarInt(FindConVar("director_panic_wave_pause_max"), 1);
		SetConVarInt(FindConVar("director_panic_wave_pause_min"), 1);
	}
	else
	{
		ResetConVar(FindConVar("tank_burn_duration_normal"), true, true);
		ResetConVar(FindConVar("z_tank_burning_lifetime"), true, true);
	}
	ResetConVar(FindConVar("tank_burn_duration_hard"), true, true);
	ResetConVar(FindConVar("tank_burn_duration_expert"), true, true);
}

ChangeCvarsFinale()
{
	SetConVarInt(FindConVar("director_panic_forever"), 0);
	
	if (g_b_L4DVersion && g_GameMode != 2)
		SetConVarInt(FindConVar("tank_burn_duration"), 100);
	else if (g_b_L4DVersion && g_GameMode == 2)
		SetConVarInt(FindConVar("tank_burn_duration"), 200);
	else
	{
		SetConVarInt(FindConVar("tank_burn_duration_normal"), 100);
		SetConVarInt(FindConVar("z_tank_burning_lifetime"), 200);
	}
	
	SetConVarInt(FindConVar("tank_burn_duration_hard"), 200);
	SetConVarInt(FindConVar("tank_burn_duration_expert"), 300);
	if (g_GameMode != 2)
		SetConVarInt(FindConVar("z_tank_health"), 30000);
	else
	SetConVarInt(FindConVar("z_tank_health"), 40000);
	
}

public Action:PlayerLeftStart(Handle:Timer)
{
	if (LeftStartArea())
	{
		if (g_GameMode != 3 && GetConVarBool(g_h_Activate) && !g_b_LeavedSafeRoom)
		{  
			// We search for any player client to execute the force panic event command. If there isn't any, we create a fake client instead and execute it on him.
			
			new anyclient = GetAnyClient();
			new bool:temp = false;
			if (anyclient == -1)
			{
				#if DEBUG
				LogMessage("[L4D 100] Creating temp client to fake command");
				#endif
				// we create a fake client
				anyclient = CreateFakeClient("TempBot");
				if (anyclient == 0)
				{
					LogError("[L4D] 100: CreateFakeClient returned 0 -- TempBot was not spawned");
					return Plugin_Continue;
				}
				temp = true;
			}
			
			// Execute the command
			
			CheatCommand(anyclient, "director_force_panic_event");
			
			// If client was temp, we setup a timer to kick the fake player
			if (temp) CreateTimer(0.1,kickbot,anyclient);
			
			if (!g_b_MessageDisplayed && GetConVarBool(g_h_Message))
			{
				PrintHintTextToAll("L4D 100: GET TO THE END OF THE MAP BEFORE THE HORDE OVERCOMES YOU!");
				g_b_MessageDisplayed = true;
			}
			g_b_LeavedSafeRoom = true;
		}
	}
	else
	{
		CreateTimer(1.0, PlayerLeftStart);
	}
	
	return Plugin_Continue;
}

public Action:Event_SurvivalStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_GameMode == 3 && GetConVarBool(g_h_Activate))
	{  
		if (!g_b_MessageDisplayed && GetConVarBool(g_h_Message))
		{
			PrintHintTextToAll("L4D 100: THE HORDE IS COMING! HOLDOUT FOR AS LONG AS YOU CAN!");
			g_b_MessageDisplayed = true;
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_FinaleStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_h_Activate))
	{
		ChangeCvarsFinale();
		PrintHintTextToAll("L4D 100: THE TANK IS STRONGER THAN EVER! BE CAREFUL!");
	}
}

public Action:Event_ChurchDoor(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("Church Door detected")
	#endif
	SetConVarInt(FindConVar("director_panic_forever"), 0);
}

public OnClientDisconnect(client)
{
	// If is a bot, skip this function
	if (IsFakeClient(client))
		return;
	
	if (!RealPlayersInGame(client))
		GameEnded();
}

GameEnded()
{
	#if DEBUG
	LogMessage("Game ended");
	#endif
	g_b_LeavedSafeRoom = false;
	g_b_RoundStarted = false;
}

stock GetAnyClient() 
{ 
	for (new target = 1; target <= MaxClients; target++) 
	{ 
		if (IsClientInGame(target)) return target; 
	} 
	return -1; 
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

bool:RealPlayersInGame (client)
{
	
	for (new i=1;i<=MaxClients;i++)
	{
		if (i != client)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
				return true;
		}
	}
	
	return false;
}

stock CheatCommand(client, String:command[], String:arguments[] = "")
{
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

bool:LeftStartArea()
{
	new ent = -1, maxents = GetMaxEntities();
	for (new i = MaxClients+1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			decl String:netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}
	
	if (ent > -1)
	{
		new offset = FindSendPropInfo("CTerrorPlayerResource", "m_hasAnySurvivorLeftSafeArea");
		if (offset > 0)
		{
			if (GetEntData(ent, offset))
			{
				if (GetEntData(ent, offset) == 1) return true;
			}
		}
	}
	return false;
}

//////