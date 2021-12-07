#pragma semicolon 1                 // Force strict semicolon mode.

#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

native L4D_LobbyUnreserve();
native L4D_LobbyIsReserved();
// *********************************************************************************
// CONSTANTS
// *********************************************************************************
#define CONSISTENCY_CHECK	5.0
#define DEBUG		0
#define PLUGIN_VERSION		"1.8.1"
#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY
#define TEAM_SPECTATOR	1
#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3
#define TEAM_NEUTRAL	4

#define ZOMBIE_SMOKER	1
#define ZOMBIE_BOOMER	2
#define ZOMBIE_HUNTER	3

new Handle:MedkitTimer    				= INVALID_HANDLE;
new Handle:TeamPanelTimer[MAXPLAYERS + 1]	= INVALID_HANDLE;
new Handle:SurvivorLimit 				= INVALID_HANDLE;
new Handle:InfectedLimit 				= INVALID_HANDLE;
new Handle:L4DInfectedLimit 			= INVALID_HANDLE;
new Handle:KillRes						= INVALID_HANDLE;
new Handle:AutoDifficulty				= INVALID_HANDLE;
new Handle:SubDirector					= INVALID_HANDLE;
new Handle:extraFirstAid				= INVALID_HANDLE;
new Handle:BotsUpdateTimer    			= INVALID_HANDLE;
new Handle:hpMulti    					= INVALID_HANDLE;

new Handle:g_VarInfected[6] = { INVALID_HANDLE, ...};

new bool:MedkitsGiven = false;
new bool:RoundStarted = false;
new String:gameMode[32];
new String:gameName[32];

public Plugin:myinfo =
{
	name        = "Super Versus Reloaded",
	author      = "DDRKhat, Marcus101RR, and Merudo",
	description = "Allows up to 32 players on Left 4 Dead.",
	version     = PLUGIN_VERSION,
	url         = "https://forums.alliedmods.net/showthread.php?p=2393931#post2393931"
}

// *********************************************************************************
// METHODS FOR GAME START & END
// *********************************************************************************
public OnPluginStart()
{
	GetConVarString(FindConVar("mp_gamemode"), gameMode, sizeof(gameMode));
	GetGameFolderName(gameName, sizeof(gameName));
	
	CreateConVar("sm_superversus_version", PLUGIN_VERSION, "L4D Super Versus", CVAR_FLAGS);
	L4DInfectedLimit = FindConVar("z_max_player_zombies");
	SurvivorLimit = CreateConVar("l4d_survivor_limit", "4", "Maximum amount of survivors", CVAR_FLAGS,true, 1.00, true, 24.00);
	InfectedLimit = CreateConVar("l4d_infected_limit", "4", "Max amount of infected (will not affect bots)", CVAR_FLAGS, true, 4.00, true, 24.00);
	AutoDifficulty = CreateConVar("director_auto_difficulty", "0", "Change Difficulty", CVAR_FLAGS, true, 0.0, true, 1.0);
	extraFirstAid = CreateConVar("l4d_extra_first_aid", "1" , "Allow extra first aid kits for extra players. 0: No extra kits. 1: one extra kit per player above four", CVAR_FLAGS, true, 0.0, true, 1.0);
	hpMulti = CreateConVar("l4d_tank_hpmulti","0.25","Tanks HP Multiplier (multi*(survivors-4)). Only active if director_auto_difficulty is 1", CVAR_FLAGS,true,0.01,true,1.00);
	
	SetConVarBounds(L4DInfectedLimit, ConVarBound_Upper, true, 18.0);
	HookConVarChange(L4DInfectedLimit, FIL);
	HookConVarChange(InfectedLimit, FIL);

	RegConsoleCmd("sm_join", Join_Game, "Join Survivor Team (If dead, takeover bot)");	
	RegConsoleCmd("sm_survivor", Join_Survivor, "Join Survivor Team (If Bot Available)");	
	RegConsoleCmd("sm_infected", Join_Infected, "Join Infected Team");
	RegConsoleCmd("sm_spectate", Join_Spectator, "Join Spectator Team");
	RegConsoleCmd("sm_afk", Join_Spectator, "Join Spectator Team");	
	RegConsoleCmd("sm_teams", TeamMenu, "Opens Team Panel with Selection");
	RegConsoleCmd("sm_changeteam", TeamMenu, "Opens Team Panel with Selection");
	RegConsoleCmd("sm_createplayer", Create_Player, "Create Survivor Bot");
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
	
	g_VarInfected[0]  = FindConVar("z_versus_smoker_limit");
	g_VarInfected[1]  = FindConVar("z_versus_boomer_limit");
	g_VarInfected[2]  = FindConVar("z_versus_hunter_limit");
	g_VarInfected[3]  = FindConVar("z_versus_spitter_limit");
	g_VarInfected[4]  = FindConVar("z_versus_charger_limit");
	g_VarInfected[5]  = FindConVar("z_versus_jockey_limit");
					
	AutoExecConfig(true, "l4d_superversus");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("L4D_LobbyUnreserve");
	MarkNativeAsOptional("L4D_LobbyIsReserved");
	return APLRes_Success;
}

public bool:l4dt()
{
	if(GetConVarFloat(FindConVar("left4downtown_version"))>0.00) return true;
	else return false;
}
public OnLibraryRemoved(const String:name[]) {if(StrEqual(name,"Left 4 Downtown Extension")) SetConVarInt(KillRes,0);}

#define FORCE_INT_CHANGE(%1,%2,%3) public %1 (Handle:c, const String:o[], const String:n[]) { SetConVarInt(%2,%3); } 
FORCE_INT_CHANGE(FIL,L4DInfectedLimit,GetConVarInt(InfectedLimit))

// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
public OnMapEnd()
{
	OnGameEnd();
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundStarted = false;
	OnGameEnd();
}

// ------------------------------------------------------------------------
//  Clean up the timers at the game end
// ------------------------------------------------------------------------
public OnGameEnd()
{
	if(SubDirector != INVALID_HANDLE )
	{
		CloseHandle(SubDirector);
		SubDirector = INVALID_HANDLE;
	}

	if(MedkitTimer != INVALID_HANDLE)
	{
		CloseHandle(MedkitTimer);
		MedkitTimer = INVALID_HANDLE;
	}
	
	if(BotsUpdateTimer != INVALID_HANDLE)
	{
		CloseHandle(BotsUpdateTimer);
		BotsUpdateTimer = INVALID_HANDLE;
	}	
	
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(TeamPanelTimer[i] != INVALID_HANDLE)
		{
			CloseHandle(TeamPanelTimer[i]);
			TeamPanelTimer[i] = INVALID_HANDLE;
		}
	}
}

// ------------------------------------------------------------------------
// Event_RoundStart()
// ------------------------------------------------------------------------

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	MedkitsGiven = false;
	RoundStarted = true;
}

// ------------------------------------------------------------------------
//  MedKit timer. Used to spawn extra medkits in safehouse
// ------------------------------------------------------------------------
public Action:timer_SpawnExtraMedKit(Handle:hTimer)
{
	new client = GetAnyValidSurvivor();
	new amount = GetTeamPlayers(2, true) - 4;
	
	if(amount > 0 && client > 0)
	{
		for(new i = 1; i <= amount; i++)
		{
			CheatCommand(client, "give", "first_aid_kit", "");
		}
	}
	MedkitTimer = INVALID_HANDLE;
}

// ------------------------------------------------------------------------
// FinaleEnd() Thanks to Damizean for smarter method of detecting safe survivors.
// ------------------------------------------------------------------------
public Event_FinaleVehicleLeaving(Handle:event, const String:name[], bool:dontBroadcast)
{
	new edict_index = FindEntityByClassname(-1, "info_survivor_position");
	if (edict_index != -1)
	{
		new Float:pos[3];
		GetEntPropVector(edict_index, Prop_Send, "m_vecOrigin", pos);
		new iMaxClients = MaxClients; 
		for(new i = 1; i <= iMaxClients; i++)
		{
			if (!IsClientConnected(i)) continue;
			if (!IsClientInGame(i)) continue;
			if (GetClientTeam(i) != 2) continue;
			if (!IsPlayerAlive(i)) continue;
			if (GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) == 1) continue;
			TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

// *********************************************************************************
// METHODS RELATED TO PLAYER/BOT SPAWN AND KICK
// *********************************************************************************

// ------------------------------------------------------------------------
//  Each time a survivor spawns, setup timer to kick / spawn bots a bit later
// ------------------------------------------------------------------------
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetClientTeam(client) != TEAM_SURVIVOR) return ;
	
	// Reset the timer, if one exists
	if(BotsUpdateTimer != INVALID_HANDLE)
	{
		CloseHandle(BotsUpdateTimer);
		BotsUpdateTimer = INVALID_HANDLE;
	}
	BotsUpdateTimer = CreateTimer(2.0, timer_BotsUpdate);
}


// ------------------------------------------------------------------------
// If player disconnect, set timer to spawn/kick bots as needed
// Might not be required, but can help fix unwanted bots
// ------------------------------------------------------------------------
public OnClientDisconnect(client)
{
	if(IsFakeClient(client) || RoundStarted != true)        // if bot or during transition
		return;

	if(TeamPanelTimer[client] != INVALID_HANDLE)            // Clean up Panel timer
	{
		CloseHandle(TeamPanelTimer[client]);
		TeamPanelTimer[client] = INVALID_HANDLE;
	}

	// Reset the timer, if one exists
	if(BotsUpdateTimer != INVALID_HANDLE)
	{
		CloseHandle(BotsUpdateTimer);
		BotsUpdateTimer = INVALID_HANDLE;
	}
	BotsUpdateTimer = CreateTimer(1.0, timer_BotsUpdate); // re-update the bots
}

// ------------------------------------------------------------------------
// Bots are kicked/spawned after every survivor spawned and every player joined
// ------------------------------------------------------------------------
public Action:timer_BotsUpdate(Handle:hTimer)
{
	BotsUpdateTimer = INVALID_HANDLE;

	if (AreAllInGame() == true)
	{
		SpawnCheck();
		if(MedkitTimer == INVALID_HANDLE && !MedkitsGiven && GetConVarInt(extraFirstAid))
		{
			MedkitsGiven = true;
			MedkitTimer = CreateTimer(2.0, timer_SpawnExtraMedKit);
		}
	}
	else
	{
		BotsUpdateTimer = CreateTimer(1.0, timer_BotsUpdate);  // if not everyone joined, delay update
	}
}

// ------------------------------------------------------------------------
// Check the # of survivors, and kick/spawn bots as needed
// ------------------------------------------------------------------------
public SpawnCheck()
{
	if(RoundStarted != true)  return;      // if during transition, don't do anything
	
	int iSurvivor    = GetTeamPlayers(TEAM_SURVIVOR, true);
	int iSurvivorMax = GetConVarInt(SurvivorLimit);
	
	if (iSurvivor != iSurvivorMax){
		PrintToConsoleAll("superversus - updating bots");		
	}

	for(; iSurvivorMax < iSurvivor; iSurvivorMax++)
	{
		KickUnusedBot();
	}
	
	for(; iSurvivor < iSurvivorMax; iSurvivor++)
	{
		SpawnFakeClient();  // This triggers Event_PlayerSpawn and create new timer, be careful about infinite loops
	}
}

// ------------------------------------------------------------------------
// Kick an unused bot
// ------------------------------------------------------------------------
KickUnusedBot()
{
	new Bot = GetAnyValidBot();
	if(Bot > 0 && IsClientInGame(Bot) && IsFakeClient(Bot) && !HasIdlePlayer(Bot))
		KickClient(Bot, "Kicking Useless Client.");
}

// ------------------------------------------------------------------------
// Spawn a survivor bot
// ------------------------------------------------------------------------
SpawnFakeClient()
{
	// Spawn bot survivor.
	new Bot = CreateFakeClient("SurvivorBot");
	if(Bot == 0)
		return;

	ChangeClientTeam(Bot, TEAM_SURVIVOR);
	if(DispatchKeyValue(Bot, "classname", "SurvivorBot") == false)
	{
		return;
	}
	DispatchSpawn(Bot);
	if(DispatchSpawn(Bot) == false)
	{
		return;
	}

	// Kick the "SurvivorBot" so it becomes a regular bot
	if(IsClientInGame(Bot) && IsFakeClient(Bot) && !HasIdlePlayer(Bot))
		KickClient(Bot, "Kicking Fake Client.");
}

// *********************************************************************************
// COMMANDS FOR JOINING TEAMS
// *********************************************************************************

public Action:Join_Game(client, args)
{
	if(IsClientInGame(client))
	{
		if(GetClientTeam(client) != TEAM_SURVIVOR)
		{
			if(CheckAvailableBot(2) == 0 && !IsClientIdle(client) && !AreInfectedAllowed())
			{
				ChangeClientTeam(client, TEAM_SURVIVOR);
			}
			else
			{
				if(!IsClientIdle(client))
					FakeClientCommand(client,"jointeam 2");
			}
		}
		if(GetClientTeam(client) == TEAM_SURVIVOR)
		{	
			if(IsPlayerAlive(client) == true)
			{
				PrintToChat(client, "\x01You are on the \x04Survivor Team\x01.");
			}
			else if(IsPlayerAlive(client) == false && CheckAvailableBot(2) != 0)  // Takeover a bot
			{
				ChangeClientTeam(client, TEAM_SPECTATOR);
				FakeClientCommand(client,"jointeam 2");
			}
			else if(IsPlayerAlive(client) == false && CheckAvailableBot(2) == 0)
			{
				PrintToChat(client, "\x01You are \x04Dead\x01. No \x05Bot(s) \x01Available.");
			}
		}
	}
	return Plugin_Handled;
}

public Action:Join_Spectator(client, args)
{
	ChangeClientTeam(client,TEAM_SPECTATOR);
	return Plugin_Handled;
}

public Action:Join_Survivor(client, args)
{
	FakeClientCommand(client,"jointeam 2");
	return Plugin_Handled;
}

public Action:Join_Infected(client, args)
{
	if( !AreInfectedAllowed() && !CheckCommandAccess( client, "", ADMFLAG_CHEATS, true ) )   
	{
		PrintToChat(client, "\x01[\x04ERROR\x01] The \x05Infected Team\x01 is not available in %s.", gameMode);
	}
	else if(GetConVarInt(InfectedLimit) <= GetTeamPlayers(TEAM_INFECTED, false))
	{
		PrintToChat(client, "\x01[\x04ERROR\x01] The \x05Infected Team\x01 is Full.");
	}	
	else
	{
		ChangeClientTeam(client,TEAM_INFECTED);
	}
	return Plugin_Handled;
}

public Action:Create_Player(client, args)
{
	decl String:arg[MAX_NAME_LENGTH];
	if (args > 0)
	{
		GetCmdArg(1, arg, sizeof(arg));	
		PrintToChatAll("Player %s has joined the game", arg);	
		CreateFakeClient(arg);
	}
	else
	{
		new i = GetAnyValidSurvivor();
		new Bot = CreateFakeClient("SurvivorBot");
		if(Bot == 0)
			return Plugin_Handled;

		ChangeClientTeam(Bot, 2);
		if (DispatchKeyValue(Bot, "classname", "survivorbot") == true)
		{
			// spawn the client
			if (DispatchSpawn(Bot) == true)
			{
				if(!IsPlayerAlive(Bot))
				{
					Respawn(Bot);
				}	
				if(i > 0)
				{
					new Float:teleportOrigin[3];
					GetClientAbsOrigin(i, teleportOrigin);
					TeleportEntity(Bot, teleportOrigin, NULL_VECTOR, NULL_VECTOR);
				}
				if((GetConVarInt(extraFirstAid)))				
					CheatCommand(Bot, "give", "first_aid_kit", "");
					
				new id = GetRandomInt(1, 3);
				if(id == 1)
					CheatCommand(Bot, "give", "pistol", "");
				if(id == 2)
					CheatCommand(Bot, "give", "smg", "");
				if(id == 3)
					CheatCommand(Bot, "give", "rifle", "");

				if(IsClientInGame(Bot) && IsFakeClient(Bot) && !HasIdlePlayer(Bot))
					KickClient(Bot, "Kicking Fake Client.");
			}
		}
	}
	return Plugin_Handled;
}

// *********************************************************************************
// RETURN PROPERTIES OF INFECTED/SURVIVOR TEAMS, BOTS, & PLAYERS
// *********************************************************************************

new const String:survivor_only_modes[22][] =
{
	"coop", "realism", "survival",
	"m60s", "hardcore",
	"mutation1",	"mutation2",	"mutation3",	"mutation4",
	"mutation5",	"mutation6",	"mutation7",	"mutation8",
	"mutation9",	"mutation10",	"mutation16",	"mutation17", "mutation20",
	"community1",	"community2",	"community4",	"community5"
};

// ------------------------------------------------------------------------
// Returns true if players in team infected are allowed
// ------------------------------------------------------------------------
public bool AreInfectedAllowed()
{	
	decl i;
	for (i = 0; i < sizeof(survivor_only_modes); i++)
	{
		if (StrEqual(gameMode, survivor_only_modes[i], false))
		{
			return false;
		}
	}
	return true;
}

public GetTeamPlayers(int team, bool includeBots)
{
	int players = 0;
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team)
		{
			if(IsFakeClient(i) && !includeBots)
				continue;
			players++;
		}
	}
	return players;
}

public GetSurvivorTeam()
{
	new count = 0;
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR)
		{
			count++;
		}
	}
	return count;
}

public bool:AreAllInGame()
{
	int iMaxClients = MaxClients; 
	
	for(int i = 1; i <= iMaxClients; i++)
	{
		if(IsClientConnected(i) && !IsFakeClient(i))
		{
			if (!IsClientInGame(i)) return false;
		}
	}
	return true;
}

stock PrintToConsoleAll(const String:format[], any:...) 
{ 
    decl String:text[192]; 
    for (new x = 1; x <= MaxClients; x++) 
    { 
        if (IsClientInGame(x)) 
        { 
            SetGlobalTransTarget(x); 
            VFormat(text, sizeof(text), format, 2); 
            PrintToConsole(x, text); 
        } 
    } 
}

stock CheckAvailableBot(team)
{
	int num = 0;
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(IsFakeClient(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
			{
				if(!HasIdlePlayer(i))
					num++;
			}
		}
	}
	return num;
}

stock bool:HasIdlePlayer(bot)
{
	if(IsClientInGame(bot) && GetClientTeam(bot) == TEAM_SURVIVOR && IsPlayerAlive(bot))
	{
		decl String:sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if(IsFakeClient(bot) && strcmp(sNetClass, "SurvivorBot") == 0)
		{
			new client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
			if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR)
			{
					return true;
			}
		}
	}
	return false;
}

stock bool:IsClientIdle(client)
{
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR)
		{
        		new spectator_userid = GetEntData(i, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID"));
        		new spectator_client = GetClientOfUserId(spectator_userid);
        
			if(spectator_client == client)
				return true;
		}
	}
	return false;
}

stock GetAnyValidBot()
{
	new i = MaxClients; 
	for(; i >= 1; i--)  // kick bots in reverse order they have been spawned
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsFakeClient(i) && !HasIdlePlayer(i) && !IsClientInKickQueue(i))
			return i;
	} 
	return -1;
}

stock GetAnyValidClient()
{
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientInKickQueue(i) )
			return i;
	} 
	return -1;
}

stock GetAnyValidSurvivor()
{
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR && !IsClientInKickQueue(i))
		{
			return i;
		}
	}
	return -1;
}

// *********************************************************************************
// TEAM MENU
// *********************************************************************************

public Action:TeamMenu(client, args)
{
	if(TeamPanelTimer[client] == INVALID_HANDLE)
	{
		DisplayTeamMenu(client);
	}
	return Plugin_Handled;
}

public DisplayTeamMenu(client)
{
	new Handle:TeamPanel = CreatePanel();

	SetPanelTitle(TeamPanel, "SuperVersus Team Panel");

	decl String:title_spectator[32];
	Format(title_spectator, sizeof(title_spectator), "Spectator (%d)", GetTeamPlayers(1, false));
	DrawPanelItem(TeamPanel, title_spectator);
		
	// Draw Spectator Group
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 1)
		{
			new String:text_client[32];

			decl String:ClientUserName[MAX_TARGET_LENGTH];
			GetClientName(i, ClientUserName, sizeof(ClientUserName));
			ReplaceString(ClientUserName, sizeof(ClientUserName), "[", "");

			Format(text_client, sizeof(text_client), "%s", ClientUserName);
			DrawPanelText(TeamPanel, text_client);
		}
	}

	decl String:title_survivor[32];
	Format(title_survivor, sizeof(title_survivor), "Survivors (%d/%d) - %d Bot(s)", GetTeamPlayers(TEAM_SURVIVOR, false), GetConVarInt(SurvivorLimit), CheckAvailableBot(2));
	DrawPanelItem(TeamPanel, title_survivor);
	
	// Draw Survivor Group
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			new String:text_client[32];

			decl String:ClientUserName[MAX_TARGET_LENGTH];
			GetClientName(i, ClientUserName, sizeof(ClientUserName));
			ReplaceString(ClientUserName, sizeof(ClientUserName), "[", "");

			decl String:m_iHealth[MAX_TARGET_LENGTH];
			if(IsPlayerAlive(i))
			{
				if(GetEntProp(i, Prop_Send, "m_isIncapacitated"))
				{
					Format(m_iHealth, sizeof(m_iHealth), "DOWN - %d HP - ", GetEntData(i, FindDataMapOffs(i, "m_iHealth"), 4));
				}
				else if(GetEntProp(i, Prop_Send, "m_currentReviveCount") == GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
				{
					Format(m_iHealth, sizeof(m_iHealth), "BLWH - ");
				}
				else
				{
					Format(m_iHealth, sizeof(m_iHealth), "%d HP - ", GetClientRealHealth(i));
				}
	
			}
			else
			{
				Format(m_iHealth, sizeof(m_iHealth), "DEAD - ");
			}

			Format(text_client, sizeof(text_client), "%s%s", m_iHealth, ClientUserName);
			DrawPanelText(TeamPanel, text_client);
		}
	}

	decl String:title_infected[32];
	Format(title_infected, sizeof(title_infected), "Infected (%d/%d) - %d Bot(s)", GetTeamPlayers(TEAM_INFECTED, false), GetConVarInt(InfectedLimit), CheckAvailableBot(3));
	DrawPanelItem(TeamPanel, title_infected);
		
	// Draw Infected Group
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			new String:text_client[32];

			decl String:ClientUserName[MAX_TARGET_LENGTH];
			GetClientName(i, ClientUserName, sizeof(ClientUserName));
			ReplaceString(ClientUserName, sizeof(ClientUserName), "[", "");

			decl String:m_iHealth[MAX_TARGET_LENGTH];
			if(IsPlayerAlive(i))
			{
				if(GetEntProp(i, Prop_Send, "m_isIncapacitated"))
				{
					Format(m_iHealth, sizeof(m_iHealth), "DOWN - %d HP - ", GetEntData(i, FindDataMapOffs(i, "m_iHealth"), 4));
				}
				if(GetEntProp(i, Prop_Send, "m_isGhost"))
				{
					Format(m_iHealth, sizeof(m_iHealth), "GHOST - ");
				}
				else
				{
					Format(m_iHealth, sizeof(m_iHealth), "%d HP - ", GetEntData(i, FindDataMapOffs(i, "m_iHealth"), 4));
				}
			}
			else
			{
				Format(m_iHealth, sizeof(m_iHealth), "DEAD - ");
			}

			Format(text_client, sizeof(text_client), "%s%s", m_iHealth, ClientUserName);
			DrawPanelText(TeamPanel, text_client);
		}
	}

	DrawPanelItem(TeamPanel, "Close");
		
	SendPanelToClient(TeamPanel, client, TeamMenuHandler, 30);
	CloseHandle(TeamPanel);
	TeamPanelTimer[client] = CreateTimer(1.0, timer_TeamMenuHandler, client);
}

public TeamMenuHandler(Handle:UpgradePanel, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select)
	{
		if(param2 == 1)
		{
			FakeClientCommand(client, "sm_spectate");
		}
		else if(param2 == 2)
		{
			decl String:ModName[50];
			GetGameFolderName(ModName, sizeof(ModName));
			if(StrEqual(ModName, "left4dead2", false))
			{
				FakeClientCommand(client, "jointeam 2");
			}
			else
			{
				FakeClientCommand(client, "sm_join");
			}

		}
		else if(param2 == 3)
		{
			FakeClientCommand(client, "sm_infected");
		}
		else if(param2 == 4)
		{
			CloseHandle(TeamPanelTimer[client]);
			TeamPanelTimer[client] = INVALID_HANDLE;
		}
	}
	else if(action == MenuAction_Cancel)
	{
		// Nothing
	}
}

public Action:timer_TeamMenuHandler(Handle:hTimer, any:client)
{
	DisplayTeamMenu(client);
}

stock GetClientRealHealth(client)
{
	if(!client || !IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsClientObserver(client))
	{
		return -1;
	}
	if(GetClientTeam(client) != 2)
	{
		return GetClientHealth(client);
	}
  
	new Float:buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	new Float:TempHealth;
	new PermHealth = GetClientHealth(client);
	if(buffer <= 0.0)
	{
		TempHealth = 0.0;
	}
	else
	{
		new Float:difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		new Float:decay = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
		new Float:constant = 1.0/decay;	TempHealth = buffer - (difference / constant);
	}
	
	if(TempHealth < 0.0)
	{
		TempHealth = 0.0;
	}
	return RoundToFloor(PermHealth + TempHealth);
}

// *********************************************************************************
// DIRECTOR DIFFICULTY METHODS
// *********************************************************************************

public OnClientPostAdminCheck(client)
{
	// Auto-Difficulty (Tanks, Specials, Etc)
	if(GetConVarInt(AutoDifficulty) == 1 && !IsFakeClient(client))
		AutoDifficultyCheck(client);
}

public AutoDifficultyCheck(client)
{
	if(IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) != 3 && GetTeamPlayers(2, true) >= 4)
	{
		int iMultiplier = GetTeamPlayers(TEAM_SURVIVOR, false);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 20+RoundToNearest(float(20)*((float(iMultiplier)/4.0)-1.0)/1.6));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 30+RoundToNearest(float(30)*((float(iMultiplier)/4.0)-1.0)/1.6));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 10+RoundToNearest(float(10)*((float(iMultiplier)/4.0)-1.0)/1.6));
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 20+RoundToNearest(float(10)*((float(iMultiplier)/4.0)-1.0)/1.6));
		SetConVarInt(FindConVar("z_mega_mob_size"), 50+RoundToNearest(float(50)*((float(iMultiplier)/4.0)-1.0)/1.6));
		//SetConVarInt(FindConVar("z_health"), 50+RoundToNearest(float(50)*((float(iMultiplier)/4.0)-1.0)/1.6));
		//SetConVarInt(FindConVar("z_gas_health"), RoundToCeil(float(250)*float(iMultiplier)/4.0));
		//SetConVarInt(FindConVar("z_hunter_health"), RoundToNearest(float(250)*float(iMultiplier)/4.0));
		//SetConVarInt(FindConVar("z_exploding_health"), RoundToNearest(float(50)*float(iMultiplier)/4.0));
		SetConVarInt(FindConVar("z_common_limit"), 30+RoundToNearest(float(30)*((float(iMultiplier)/4.0)-1.0)/6.0));

		SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), RoundToFloor(900.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mega_mob_spawn_min_interval"), RoundToFloor(420.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_easy"), RoundToFloor(240.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), RoundToFloor(180.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), RoundToFloor(180.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), RoundToFloor(180.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_easy"), RoundToFloor(120.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), RoundToFloor(90.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), RoundToFloor(90.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), RoundToFloor(90.0 * (4.0/float(iMultiplier))));

		SetConVarInt(FindConVar("director_special_respawn_interval"), RoundToFloor(45.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("director_special_battlefield_respawn_interval"), RoundToFloor(10.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("director_special_finale_offer_length"), RoundToFloor(10.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("director_special_initial_spawn_delay_max"), RoundToFloor(60.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("director_special_initial_spawn_delay_max_extra"), RoundToFloor(180.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("director_special_initial_spawn_delay_min"), RoundToFloor(30.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("director_special_original_offer_length"), RoundToFloor(30.0 * (4.0/float(iMultiplier))));


		if(!StrEqual(gameMode, "versus", false))
		{
			if (!StrEqual(gameName, "left4dead2", false))
			{
				new iInfectedAmount = GetTeamPlayers(2, true);

				new iSmoker = GetRandomInt(0, iInfectedAmount-2);
				SetConVarInt(FindConVar("z_gas_limit"), iSmoker);
				iInfectedAmount -= iSmoker;

				new iBoomer = GetRandomInt(0, iInfectedAmount-1);
				SetConVarInt(FindConVar("z_exploding_limit"), iBoomer);
				iInfectedAmount -= iBoomer;

				new iHunter = GetRandomInt(iInfectedAmount, iInfectedAmount);
				SetConVarInt(FindConVar("z_hunter_limit"), iHunter);
			}
			else
			{
				new iInfectedAmount;
				if(GetConVarInt(SurvivorLimit) < GetTeamPlayers(2, true))
					iInfectedAmount = GetTeamPlayers(2, true);
				else
					iInfectedAmount = GetConVarInt(SurvivorLimit);
				
				new iLastType = 0;
				new iCurrentType = 0;
				new iLowValue = 0;
				new iAmount = 0;
				new String:iType[6][16] =
				{
					"z_smoker_limit",
					"z_boomer_limit",
					"z_hunter_limit",
					"z_spitter_limit",
					"z_charger_limit",
					"z_jockey_limit"
				};
				new iMax[6] =
				{
					3,
					1,
					0,
					0,
					0,
					0
				};
				new String:iName[6][16] = {"Smoker", "Boomer", "Hunter", "Spitter", "Charger", "Jockey"};
				if(GetConVarInt(g_VarInfected[0]) > 0)
					iLastType = 1;
				if(GetConVarInt(g_VarInfected[1]) > 0)
					iLastType = 2;
				if(GetConVarInt(g_VarInfected[2]) > 0)
					iLastType = 3;
				if(GetConVarInt(g_VarInfected[3]) > 0)
					iLastType = 4;
				if(GetConVarInt(g_VarInfected[4]) > 0)
					iLastType = 5;
				if(GetConVarInt(g_VarInfected[5]) > 0)
					iLastType = 6;
				
				PrintToConsoleAll("---------------------------------------------------");
				PrintToConsoleAll("ID\tTOTAL:\t%d\t%d", iInfectedAmount, iLastType);
				PrintToConsoleAll("---------------------------------------------------");

				for(new i = 0; i < 6; i++)
				{
					iCurrentType++;
					if(iLastType == iCurrentType)
						iLowValue = iInfectedAmount;
					if(GetConVarInt(g_VarInfected[i]) > 0)
					{
						iAmount = GetRandomInt(iLowValue, iInfectedAmount-iMax[i]);
						SetConVarInt(FindConVar(iType[i]), iAmount);
						iInfectedAmount -= iAmount;
						PrintToConsoleAll("%s\t\t%d\t%d\t%d", iName[i], iAmount, iInfectedAmount, iLowValue);
					}
				}
			}
		}

		new Float:extrasurvivors = (float(GetTeamPlayers(2, true))-4.0);
		if(RoundFloat(extrasurvivors) > 0)
		{
			new TankHP = RoundFloat((4000*(1.0+(GetConVarFloat(hpMulti)*extrasurvivors))));
			SetConVarInt(FindConVar("z_tank_health"), TankHP);
			PrintToConsoleAll("Tank HP: %d", TankHP);
		}
	}
}


// *********************************************************************************
// INFECTED COUNTER
// *********************************************************************************


SetGhostStatus(client, bool:ghost)
{
	if (ghost)
	SetEntProp(client, Prop_Send, "m_isGhost", 1);

	else
	SetEntProp(client, Prop_Send, "m_isGhost", 0);
}

SetLifeState(client, bool:ready)
{
	if(ready)
	SetEntProp(client, Prop_Send,  "m_lifeState", 1);

	else
	SetEntProp(client, Prop_Send, "m_lifeState", 0);
}

bool:IsPlayerGhost (client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost"))
		return true;
	return false;
}

public Action:BotInfectedCounter(Handle:timer, any:value)
{
	new smoker = GetConVarInt(FindConVar("z_versus_smoker_limit"));
	new boomer = GetConVarInt(FindConVar("z_versus_boomer_limit"));
	new hunter = GetConVarInt(FindConVar("z_hunter_limit"));

	new iInfected = GetConVarInt(InfectedLimit);

	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			iInfected--;

			if(GetEntProp(i, Prop_Send, "m_zombieClass") == ZOMBIE_HUNTER) hunter--;
			else if(GetEntProp(i, Prop_Send, "m_zombieClass") == ZOMBIE_SMOKER) smoker--;
			else if(GetEntProp(i, Prop_Send, "m_zombieClass") == ZOMBIE_BOOMER) boomer--;
		}
	}

	new bool:resetGhost[MAXPLAYERS+1];
	new bool:resetLife[MAXPLAYERS+1];
	
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			if(IsPlayerGhost(i))
			{
				resetGhost[i] = true;
				SetGhostStatus(i, false);
			}
			else if(!IsPlayerAlive(i))
			{
				resetLife[i] = true;
				SetLifeState(i, false);
			}
		}
	}

	new client = GetAnyValidClient();

	for(new limit = 0;limit < iInfected; limit++)
	{
		new Bot = CreateFakeClient("InfectedBot");
		if(Bot != 0)
		{
			ChangeClientTeam(Bot, 3);
			DispatchKeyValue(Bot, "classname", "InfectedBot");
			new type = GetRandomInt(1, 3);

			if(type == 1 && smoker-- > 0){ CheatCommand(client, "z_spawn", "smoker", "auto"); }
			else if(type == 2 && boomer-- > 0){ CheatCommand(client, "z_spawn", "boomer", "auto"); }
			else if(type == 3 && hunter-- > 0){ CheatCommand(client, "z_spawn", "hunter", "auto"); }

			KickClient(Bot, "Kicked Fake Bot");
		}
	}

	// We restore the player's status
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(resetGhost[i] == true)
			SetGhostStatus(i, true);
		if(resetLife[i] == true)
			SetLifeState(i, true);
	}

	new m_iIntensity = 0;
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			m_iIntensity += GetEntProp(i, Prop_Send, "m_clientIntensity");
		}
	}
	new Float:m_iAverageIntensity = 5.0 + (float(m_iIntensity) / (float(GetTeamPlayers(2, true)) * 100.0) * float(GetConVarInt(FindConVar("z_ghost_delay_max"))));

	SubDirector = INVALID_HANDLE;
	SubDirector = CreateTimer(15.0 + m_iAverageIntensity, BotInfectedCounter, _, TIMER_FLAG_NO_MAPCHANGE);
}


// *********************************************************************************
// RESPAWN AND CHEAT METHODS
// *********************************************************************************

stock Respawn(client)
{
	static Handle:hRoundRespawn = INVALID_HANDLE;
	if (hRoundRespawn == INVALID_HANDLE)
	{
		new Handle:hGameConf = LoadGameConfigFile("l4d_superversus");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
		if(hRoundRespawn == INVALID_HANDLE)
		{
			PrintToChatAll("L4D_SM_Respawn: RoundRespawn Signature broken");
		}
  	}
	SDKCall(hRoundRespawn, client);
}

stock CheatCommand(client, String:command[], String:argument1[], String:argument2[])
{
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, argument1, argument2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}