// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
// *********************************************************************************
#pragma semicolon 1                 // Force strict semicolon mode.
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
// *********************************************************************************
// OPTIONALS - If these exist, we use them. If not, we do nothing.
// *********************************************************************************
native L4D_LobbyUnreserve();
native L4D_LobbyIsReserved();
// *********************************************************************************
// CONSTANTS
// *********************************************************************************
#define CONSISTENCY_CHECK	5.0
#define DEBUG		0
#define PLUGIN_VERSION		"1.7.3"
#define CVAR_FLAGS FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD
#define TEAM_SPECTATOR	1
#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3
#define TEAM_NEUTRAL	4

#define ZOMBIE_SMOKER	1
#define ZOMBIE_BOOMER	2
#define ZOMBIE_HUNTER	3

// *********************************************************************************
// VARS
// *********************************************************************************
new Handle:MedkitTimer    			    = INVALID_HANDLE;
new Handle:TeamPanelTimer[MAXPLAYERS + 1]	= INVALID_HANDLE;
new Handle:SurvivorLimit 			    = INVALID_HANDLE;
new Handle:InfectedLimit 		    	= INVALID_HANDLE;
new Handle:L4DInfectedLimit 			= INVALID_HANDLE;
new Handle:KillRes				        = INVALID_HANDLE;
new Handle:AutoDifficulty			    = INVALID_HANDLE;
new Handle:SurvivalistDifficulty		= INVALID_HANDLE;
new Handle:SubDirector				    = INVALID_HANDLE;
new Handle:AllowSuperBoomer				= INVALID_HANDLE;
new Handle:XtraHP                       = INVALID_HANDLE;
new Handle:hpMulti			        	= INVALID_HANDLE;
new bool:RoundStarted;
new bool:SurvivorKickEnabled;
new bool:IsSpawningBots;
new bool:MidSpawn[MAXPLAYERS+1] = {true, ...};

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
	name        = "Super Versus Reloaded",
	author      = "DDRKhat, Marcus101RR, $atanic $pirit & Merudo",
	description = "Allow versus to become up to 18 vs 18",
	version     = PLUGIN_VERSION,
	url         = "https://forums.alliedmods.net/showpost.php?p=2392175&postcount=1044"
};
// *********************************************************************************
// METHODS
// *********************************************************************************
// ------------------------------------------------------------------------
// OnPluginStart()
// ------------------------------------------------------------------------
public OnPluginStart()
{
	CreateConVar("sm_superversus_version", PLUGIN_VERSION, "L4D Super Versus", CVAR_FLAGS);
	L4DInfectedLimit = FindConVar("z_max_player_zombies");
	SurvivorLimit = CreateConVar("l4d_survivor_limit", "4", "Maximum amount of survivors", CVAR_FLAGS,true, 4.00, true, 24.00);
	InfectedLimit = CreateConVar("l4d_infected_limit", "4", "Max amount of infected (will not affect bots)", CVAR_FLAGS, true, 4.00, true, 24.00);
	KillRes = CreateConVar("l4d_killreservation", "1", "Should we clear Lobby reservaton? (For use with Left4DownTown extension ONLY)", CVAR_FLAGS, true, 0.0, true, 1.0);
	AutoDifficulty = CreateConVar("director_auto_difficulty", "1", "Change Difficulty", CVAR_FLAGS, true, 0.0, true, 1.0);
	SurvivalistDifficulty = CreateConVar("director_survivalist_difficulty", "0", "Allow Survivalist Difficulty", CVAR_FLAGS, true, 0.0, true, 1.0);
	AllowSuperBoomer = CreateConVar("director_allow_super_boomer", "0", "Allow Super Boomers", CVAR_FLAGS, true, 0.0, true, 1.0);
	XtraHP = CreateConVar("l4d_XtraHP","0","Give extra survivors HP packs? (1 for extra medpacks)", CVAR_FLAGS,true,0.0,true,1.0);
	hpMulti = CreateConVar("l4d_tank_hpmulti","0.25","Tanks HP Multiplier (multi*(survivors-4)). Only active if director_auto_difficulty is 1", CVAR_FLAGS,true,0.01,true,1.00);
	
	SetConVarBounds(L4DInfectedLimit, ConVarBound_Upper, true, 18.0);
	HookConVarChange(L4DInfectedLimit, FIL);
	HookConVarChange(InfectedLimit, FIL);

	RegConsoleCmd("sm_join", Join_Game, "Jointeam 3 - Without dev console");
	RegConsoleCmd("sm_infected", Join_Infected, "Jointeam 3 - Without dev console");
	RegConsoleCmd("sm_teams", TeamMenu, "Jointeam 3 - Without dev console");
	RegConsoleCmd("sm_changeteam", TeamMenu, "Jointeam 3 - Without dev console");
	RegConsoleCmd("sm_spectate", Join_Spectator, "Jointeam 2 - Without dev console");
	RegConsoleCmd("sm_afk", Join_Spectator, "Jointeam 2 - Without dev console");
	RegConsoleCmd("sm_survivor", Join_Survivor, "Jointeam 2 - Without dev console");
	RegConsoleCmd("sm_createplayer", Create_Player, "Create Survivor - Without dev console");

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_connect_full", Event_PlayerConnectFull, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
	HookEvent("player_now_it", Event_PlayerNowIt);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_Post);
	HookEvent("player_left_checkpoint", Event_PlayerLeftStartArea, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	
	AutoExecConfig(true, "l4d_superversus");
}
// ------------------------------------------------------------------------
// OnAskPluginLoad() && OnLibraryRemoved && l4dt
// ------------------------------------------------------------------------
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
// ------------------------------------------------------------------------
// OnConvarChange()
// ------------------------------------------------------------------------
#define FORCE_INT_CHANGE(%1,%2,%3) public %1 (Handle:c, const String:o[], const String:n[]) { SetConVarInt(%2,%3); } 
FORCE_INT_CHANGE(FIL,L4DInfectedLimit,GetConVarInt(InfectedLimit))

// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
public OnMapEnd()
{
	OnGameEnd();
}

public OnGameEnd()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));

	if(SubDirector != INVALID_HANDLE || (SubDirector != INVALID_HANDLE && StrEqual(GameName, "coop", false)))
	{
		CloseHandle(SubDirector);
		SubDirector = INVALID_HANDLE;
	}

	if(MedkitTimer != INVALID_HANDLE)
	{
		CloseHandle(MedkitTimer);
		MedkitTimer = INVALID_HANDLE;
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

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsSpawningBots == false && GetTotalInGamePlayers() >= GetTotalPlayers() && TeamPlayers(TEAM_SURVIVOR) < GetConVarInt(SurvivorLimit) && IsClientInGame(client))
	{
		#if DEBUG
		PrintToChatAll("DEBUG: Spawning Triggered");
		#endif
		if(TeamPlayers(TEAM_SURVIVOR) < GetConVarInt(SurvivorLimit))
		{
			#if DEBUG
			PrintToChatAll("DEBUG: Spawning Bots");
			#endif
			IsSpawningBots = true;
			new NumSurvivors = TeamPlayers(2);
			new MaxSurvivors = GetConVarInt(SurvivorLimit);
			#if DEBUG
			LogMessage("SpawnTick> Survivors: [%i/%i]",NumSurvivors,MaxSurvivors);
			#endif

			for(;NumSurvivors < MaxSurvivors; NumSurvivors++)
			{
				SpawnFakeClient();
			}	
				
			if(TeamPlayers(2) >= MaxSurvivors)
			{
				IsSpawningBots = false;
			}
		}
	}
	
	if(GetClientTeam(client) == TEAM_INFECTED)
	{
		new iClass = GetEntProp(client, Prop_Send, "m_zombieClass");
		if(iClass == 2 && GetRandomInt(1, 100) < 51 && GetConVarInt(AllowSuperBoomer) == 1)
		{
			new iMaxHealth = GetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 4);
			SetEntProp(client, Prop_Send, "m_iMaxHealth", iMaxHealth * 10);
			SetEntProp(client, Prop_Send, "m_iHealth", iMaxHealth * 10);
		}
	}

	if(GetConVarInt(AutoDifficulty) == 1)
		AutoDifficultyCheck(client);
}

public Action:Join_Game(client, args)
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));	

	if(IsClientInGame(client))
	{
		if(GetClientTeam(client) != TEAM_SURVIVOR)
		{
			if(CheckAvailableBot(2) == 0 && !IsClientIdle(client) && !StrEqual(GameName, "versus"))
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
			else if(IsPlayerAlive(client) == false && CheckAvailableBot(2) != 0)
			{
				ChangeClientTeam(client, TEAM_SPECTATOR);
				FakeClientCommand(client,"jointeam 2");
			}
			else if(IsPlayerAlive(client) == false && CheckAvailableBot(2) == 0 && bool:MidSpawn[client] == true)
			{
				FakeClientCommand(client,"jointeam 2");
				Respawn(client);
				Teleport(client);
				PrintToChat(client, "\x01Survivor \x04bot \x01created."); 
			}
		}
	}
	return Plugin_Handled;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userId"));
	MidSpawn[victim] = false;
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
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));	

	if(StrEqual(GameName, "coop") && !CheckCommandAccess( client, "", ADMFLAG_CHEATS, true )  )
	{
		PrintToChat(client, "\x01[\x04ERROR\x01] The \x05Infected Team\x01 is not available in coop.");
		return Plugin_Handled;
	}

	if(StrEqual(GameName, "versus") || StrEqual(GameName, "teamversus") || StrEqual(GameName, "scavenge") || StrEqual(GameName, "teamscavenge") || StrContains(GameName, "mutation", false) != -1)
	{
		if(GetConVarInt(InfectedLimit) > GetClientTeamHumans(TEAM_INFECTED))
		{
			ChangeClientTeam(client,TEAM_INFECTED);
			return Plugin_Handled;
		}
		else
		{
			PrintToChat(client, "\x01[\x04ERROR\x01] The \x05Infected Team\x01 is Full.");
		}
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
				Teleport(Bot);
				if(GetConVarInt(XtraHP))
				{
					CheatCommand(Bot, "give", "first_aid_kit", "");
				}
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

public Action:timer_SpawnExtraMedKit(Handle:hTimer, any:junk)
{
	new client = GetAnyValidSurvivor();
	new amount = TeamPlayers(2) - 4;
	if(amount > 0 && client > 0)
	{
		for(new i = 1; i <= amount; i++)
		{
			CheatCommand(client, "give", "first_aid_kit", "");
		}
	}
	MedkitTimer = INVALID_HANDLE;
}

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
	Format(title_spectator, sizeof(title_spectator), "Spectator (%d)", TeamPlayers(1));
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
	Format(title_survivor, sizeof(title_survivor), "Survivors (%d/%d) - %d Bot(s)", GetClientTeamHumans(TEAM_SURVIVOR), GetConVarInt(FindConVar("l4d_survivor_limit")), CheckAvailableBot(2));
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
	Format(title_infected, sizeof(title_infected), "Infected (%d/%d) - %d Bot(s)", GetClientTeamHumans(TEAM_INFECTED), GetConVarInt(FindConVar("l4d_survivor_limit")), CheckAvailableBot(3));
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

public Event_PlayerConnectFull(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(RoundStarted != true || IsFakeClient(client))
	{
		return;
	}

	if(GetTotalPlayers() < GetSurvivorTeam() && SurvivorKickEnabled == true)
	{
		if(GetConVarInt(SurvivorLimit) < GetSurvivorTeam())
		{
			new Bot = GetAnyValidBot();
			if(Bot > 0 && IsClientInGame(Bot) && IsFakeClient(Bot) && !HasIdlePlayer(Bot))
				KickClient(Bot, "Kicking Fake Client.");
		}
	}

	// Auto-Difficulty Changer
	if(GetConVarInt(AutoDifficulty) == 1)
		AutoDifficultyCheck(client);
}

public AutoDifficultyCheck(client)
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));

	if(IsClientInGame(client) && TeamPlayers(2) >= 4 && GetClientTeam(client) != 3 || IsClientInGame(client) && IsFakeClient(client) && TeamPlayers(2) >= 4 && GetClientTeam(client) != 3 )
	{
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 20+RoundToNearest(float(20)*((float(TeamPlayers(TEAM_SURVIVOR))/4.0)-1.0)/1.6));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 30+RoundToNearest(float(30)*((float(TeamPlayers(TEAM_SURVIVOR))/4.0)-1.0)/1.6));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 10+RoundToNearest(float(10)*((float(TeamPlayers(TEAM_SURVIVOR))/4.0)-1.0)/1.6));
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 20+RoundToNearest(float(10)*((float(TeamPlayers(TEAM_SURVIVOR))/4.0)-1.0)/1.6));
		SetConVarInt(FindConVar("z_mega_mob_size"), 50+RoundToNearest(float(50)*((float(TeamPlayers(TEAM_SURVIVOR))/4.0)-1.0)/1.6));
		//SetConVarInt(FindConVar("z_health"), 50+RoundToNearest(float(50)*((float(TeamPlayers(TEAM_SURVIVOR))/4.0)-1.0)/1.6));
		//SetConVarInt(FindConVar("z_gas_health"), RoundToCeil(float(250)*float(TeamPlayers(TEAM_SURVIVOR))/4.0));
		//SetConVarInt(FindConVar("z_hunter_health"), RoundToNearest(float(250)*float(TeamPlayers(TEAM_SURVIVOR))/4.0));
		//SetConVarInt(FindConVar("z_exploding_health"), RoundToNearest(float(50)*float(TeamPlayers(TEAM_SURVIVOR))/4.0));
		SetConVarInt(FindConVar("z_common_limit"), 30+RoundToNearest(float(30)*((float(TeamPlayers(TEAM_SURVIVOR))/4.0)-1.0)/6.0));

		SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), RoundToFloor(900.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));
		SetConVarInt(FindConVar("z_mega_mob_spawn_min_interval"), RoundToFloor(420.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_easy"), RoundToFloor(240.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), RoundToFloor(180.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), RoundToFloor(180.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), RoundToFloor(180.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_easy"), RoundToFloor(120.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), RoundToFloor(90.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), RoundToFloor(90.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), RoundToFloor(90.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));

		SetConVarInt(FindConVar("director_special_respawn_interval"), RoundToFloor(45.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));
		SetConVarInt(FindConVar("director_special_battlefield_respawn_interval"), RoundToFloor(10.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));
		SetConVarInt(FindConVar("director_special_finale_offer_length"), RoundToFloor(10.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));
		SetConVarInt(FindConVar("director_special_initial_spawn_delay_max"), RoundToFloor(60.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));
		SetConVarInt(FindConVar("director_special_initial_spawn_delay_max_extra"), RoundToFloor(180.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));
		SetConVarInt(FindConVar("director_special_initial_spawn_delay_min"), RoundToFloor(30.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));
		SetConVarInt(FindConVar("director_special_original_offer_length"), RoundToFloor(30.0 * (4.0/float(TeamPlayers(TEAM_SURVIVOR)))));


		if(!StrEqual(GameName, "versus", false))
		{
			if (!StrEqual(game_name, "left4dead2", false))
			{
				new iInfectedAmount = TeamPlayers(2);

				new iSmoker = GetRandomInt(1, iInfectedAmount-2);
				SetConVarInt(FindConVar("z_gas_limit"), iSmoker);
				iInfectedAmount -= iSmoker;

				new iBoomer = GetRandomInt(1, iInfectedAmount-1);
				SetConVarInt(FindConVar("z_exploding_limit"), iBoomer);
				iInfectedAmount -= iBoomer;

				new iHunter = GetRandomInt(iInfectedAmount, iInfectedAmount);
				SetConVarInt(FindConVar("z_hunter_limit"), iHunter);
			}
		}

		new Float:extrasurvivors = (float(GetConVarInt(SurvivorLimit))-4.0);
		if(RoundFloat(extrasurvivors) > 0)
		{
			new TankHP = RoundFloat((4000*(1.0+(GetConVarFloat(hpMulti)*extrasurvivors))));
			SetConVarInt(FindConVar("z_tank_health"), TankHP);
		}
	}
}

public Event_PlayerNowIt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetConVarInt(SurvivalistDifficulty))
	{
		CheatCommand(client, "z_spawn", "mob" ,"");
	}
}

// ------------------------------------------------------------------------
// TeamPlayers() arg = teamnum
// ------------------------------------------------------------------------
public TeamPlayers(any:team)
{
	new inte=0;
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team)
			inte++;
	}
	return inte;
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

public GetClientTeamHumans(team)
{
	new count = 0;
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team && !IsFakeClient(i))
		{
			count++;
		}
	}
	return count;
}

public GetTotalPlayers()
{
	new iCount = 0;
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientConnected(i) && !IsFakeClient(i))
		{
			iCount++;
		}
	}
	return iCount;
}

public GetTotalInGamePlayers()
{
	new iCount = 0;
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			iCount++;
		}
	}
	return iCount;
}

// ------------------------------------------------------------------------
// OnClientDisconnect()
// ------------------------------------------------------------------------
public OnClientDisconnect(client)
{
	if(IsFakeClient(client) || RoundStarted != true)
		return;

	if(GetTotalPlayers() < GetSurvivorTeam() && SurvivorKickEnabled == true)
	{
		if(GetConVarInt(SurvivorLimit) < GetSurvivorTeam())
		{
			new Bot = GetAnyValidBot();
			if(Bot > 0 && IsClientInGame(Bot) && IsFakeClient(Bot) && !HasIdlePlayer(Bot))
				KickClient(Bot, "Kicking Fake Client.");
		}
	}
	if(TeamPanelTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(TeamPanelTimer[client]);
		TeamPanelTimer[client] = INVALID_HANDLE;
	}

	if(!IsFakeClient(client) && GetConVarInt(AutoDifficulty) == 1)
	{
		AutoDifficultyCheck(client);
	}
}
// ------------------------------------------------------------------------
// SpawnFakeClient()
// ------------------------------------------------------------------------
SpawnFakeClient()
{
	// Spawn bot survivor.
	new Bot = CreateFakeClient("SurvivorBot");
	if(Bot == 0)
		return;

	ChangeClientTeam(Bot, 2);
	if(DispatchKeyValue(Bot, "classname", "SurvivorBot") == false)
	{
		return;
	}
	DispatchSpawn(Bot);
	if(DispatchSpawn(Bot) == false)
	{
		return;
	}

	if(GetConVarInt(XtraHP))
	{
		new med = GivePlayerItem(Bot,"weapon_first_aid_kit");
		if(med)
			EquipPlayerWeapon(Bot,med);			
	}
		
	if(IsClientInGame(Bot) && IsFakeClient(Bot) && !HasIdlePlayer(Bot))
		KickClient(Bot, "Kicking Fake Client.");
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

// ------------------------------------------------------------------------
// Event_RoundStart()
// ------------------------------------------------------------------------

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));

	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));

	if(MedkitTimer != INVALID_HANDLE)
	{
		CloseHandle(MedkitTimer);
		MedkitTimer = INVALID_HANDLE;
	}

	if(MedkitTimer == INVALID_HANDLE && GetConVarInt(XtraHP))
	{
		MedkitTimer = CreateTimer(6.0, timer_SpawnExtraMedKit);
	}
	RoundStarted = true;
	
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	MidSpawn[i] = true;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundStarted = false;
	SurvivorKickEnabled = false;
	OnGameEnd();
}

public Event_PlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));

	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
 
	if(SubDirector == INVALID_HANDLE && StrEqual(GameName, "versus", false) && !StrEqual(ModName, "left4dead2", false) && AnySurvivorLeftSafeArea())
	{
		SubDirector = CreateTimer(float(GetConVarInt(FindConVar("z_ghost_delay_max"))), BotInfectedCounter, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	if(SurvivorKickEnabled != true)
	{
		SurvivorKickEnabled = true;
	}
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
		if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) || IsClientInGame(i) && GetClientTeam(i) == 3 && !IsPlayerAlive(i))
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
	new Float:m_iAverageIntensity = 5.0 + (float(m_iIntensity) / (float(TeamPlayers(2)) * 100.0) * float(GetConVarInt(FindConVar("z_ghost_delay_max"))));

	SubDirector = INVALID_HANDLE;
	SubDirector = CreateTimer(15.0 + m_iAverageIntensity, BotInfectedCounter, _, TIMER_FLAG_NO_MAPCHANGE);
}

bool:AnySurvivorLeftSafeArea()
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
		if(GetEntProp(ent, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
		{
			return true;
		}
	}
	return false;
}

stock CheckAvailableBot(team)
{
	new inte = 0;
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(IsFakeClient(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
			{
				if(!HasIdlePlayer(i))
					inte++;
			}
		}
	}
	return inte;
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

stock bool:IsValidPlayer(client)
{
	if(client <= 0)
		return false;
	
	if(!IsClientInGame(client))
		return false;
	
	return true;
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
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsFakeClient(i) && !HasIdlePlayer(i))
			return i;
	} 
	return -1;
}

stock GetAnyValidClient()
{
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i))
			return i;
	} 
	return -1;
}

stock GetAnyValidSurvivor()
{
	new iMaxClients = MaxClients; 
	for(new i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR)
		{
			return i;
		}
	}
	return -1;
}

stock Respawn(client)
{
	static Handle:hRoundRespawn = INVALID_HANDLE;
	if (hRoundRespawn == INVALID_HANDLE)
	{
		new Handle:hGameConf = LoadGameConfigFile("l4drespawn");
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

stock Teleport(client)
{
	new i = GetAnyValidSurvivor();
	if(i > 0)
	{
		new Float:teleportOrigin[3];
		GetClientAbsOrigin(i, teleportOrigin);
		TeleportEntity(client, teleportOrigin, NULL_VECTOR, NULL_VECTOR);
	}
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