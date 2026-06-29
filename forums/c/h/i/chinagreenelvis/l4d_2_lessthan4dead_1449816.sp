#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.3"

public Plugin:myinfo = 
{
	name = "[L4D, L4D2] Less Than 4 Dead",
	author = "chinagreenelvis",
	description = "Dynamically change the number of survivors",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1330706"
}

new bool:Enabled = false;
new survivorlimit = 0;
new survivors = 0;

new NewClient[MAXPLAYERS+1];

new Handle:lt4d_minsurvivors = INVALID_HANDLE;
new Handle:lt4d_maxsurvivors = INVALID_HANDLE;
new Handle:lt4d_specials = INVALID_HANDLE;
new Handle:lt4d_specials_boomersenable = INVALID_HANDLE;
new Handle:lt4d_specials_chargersenable = INVALID_HANDLE;
new Handle:lt4d_specials_huntersenable = INVALID_HANDLE;
new Handle:lt4d_specials_jockeysenable = INVALID_HANDLE;
new Handle:lt4d_specials_smokersenable = INVALID_HANDLE;
new Handle:lt4d_specials_spittersenable = INVALID_HANDLE;
new Handle:lt4d_commons = INVALID_HANDLE;
new Handle:lt4d_commons_1player = INVALID_HANDLE;
new Handle:lt4d_megamob_1player = INVALID_HANDLE;
new Handle:lt4d_mobmin_1player = INVALID_HANDLE;
new Handle:lt4d_mobmax_1player = INVALID_HANDLE;
new Handle:lt4d_commons_2players = INVALID_HANDLE;
new Handle:lt4d_megamob_2players = INVALID_HANDLE;
new Handle:lt4d_mobmin_2players = INVALID_HANDLE;
new Handle:lt4d_mobmax_2players = INVALID_HANDLE;
new Handle:lt4d_commons_3players = INVALID_HANDLE;
new Handle:lt4d_megamob_3players = INVALID_HANDLE;
new Handle:lt4d_mobmin_3players = INVALID_HANDLE;
new Handle:lt4d_mobmax_3players = INVALID_HANDLE;
new Handle:lt4d_commons_4players = INVALID_HANDLE;
new Handle:lt4d_megamob_4players = INVALID_HANDLE;
new Handle:lt4d_mobmin_4players = INVALID_HANDLE;
new Handle:lt4d_mobmax_4players = INVALID_HANDLE;

static Handle:hRoundRespawn = INVALID_HANDLE;
static Handle:hGameConf = INVALID_HANDLE;

public OnPluginStart() 
{
	lt4d_minsurvivors = CreateConVar("lt4d_minsurvivors", "1", "Minimum number of survivors to allow (additional slots are filled by bots)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_maxsurvivors = CreateConVar("lt4d_maxsurvivors", "4", "Maximum number of survivors to allow", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_specials = CreateConVar("lt4d_specials", "1", "Allow special infected regulation? 1: Enable, 0: Disable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_specials_boomersenable = CreateConVar("lt4d_specials_boomersenable", "1", "Number of players at which to turn on boomers", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_specials_chargersenable = CreateConVar("lt4d_specials_chargersenable", "4", "Number of players at which to turn on chargers", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_specials_huntersenable = CreateConVar("lt4d_specials_huntersenable", "2", "Number of players at which to turn on hunters", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_specials_jockeysenable = CreateConVar("lt4d_specials_jockeysenable", "3", "Number of players at which to turn on jockeys", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_specials_smokersenable = CreateConVar("lt4d_specials_smokersenable", "2", "Number of players at which to turn on smokers", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_specials_spittersenable = CreateConVar("lt4d_specials_spittersenable", "4", "Number of players at which to turn on spitters", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_commons = CreateConVar("lt4d_commons", "1", "Allow common infected regulation? 1: Enable, 0: Disable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_commons_1player = CreateConVar("lt4d_commons_1player", "15", "Number of common infected for one player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_megamob_1player = CreateConVar("lt4d_megamob_1player", "20", "Mega-mob size for one player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_mobmin_1player = CreateConVar("lt4d_mobmin_1player", "4", "Minimum mob spawn size for one player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_mobmax_1player = CreateConVar("lt4d_mobmax_1player", "10", "Maximum mob spawn size for one player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_commons_2players = CreateConVar("lt4d_commons_2players", "20", "Number of common infected for two players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_megamob_2players = CreateConVar("lt4d_megamob_2players", "30", "Mega-mob size for two players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_mobmin_2players = CreateConVar("lt4d_mobmin_2players", "6", "Minimum mob spawn size for two players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_mobmax_2players = CreateConVar("lt4d_mobmax_2players", "20", "Maximum mob spawn size for two players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_commons_3players = CreateConVar("lt4d_commons_3players", "25", "Number of common infected for three players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_megamob_3players = CreateConVar("lt4d_megamob_3players", "40", "Mega-mob size for three players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_mobmin_3players = CreateConVar("lt4d_mobmin_3players", "8", "Minimum mob spawn size for three players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_mobmax_3players = CreateConVar("lt4d_mobmax_3players", "25", "Maximum mob spawn size for three players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_commons_4players = CreateConVar("lt4d_commons_4players", "30", "Number of common infected for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_megamob_4players = CreateConVar("lt4d_megamob_4players", "50", "Mega-mob size for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_mobmin_4players = CreateConVar("lt4d_mobmin_4players", "10", "Minimum mob spawn size for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_mobmax_4players = CreateConVar("lt4d_mobmax_4players", "30", "Maximum mob spawn size for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d_2_lessthan4dead");
	
	LoadTranslations("common.phrases");
	hGameConf = LoadGameConfigFile("l4drespawn");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
	hRoundRespawn = EndPrepSDKCall();
	if (hRoundRespawn == INVALID_HANDLE) SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
	
	SetConVarInt(FindConVar("director_no_survivor_bots"), 1, true, false);
	
	new flags = GetConVarFlags(FindConVar("survivor_limit")); 
	if (flags & FCVAR_NOTIFY)
	{ 
		SetConVarFlags(FindConVar("survivor_limit"), flags ^ FCVAR_NOTIFY); 
	}
	SetConVarInt(FindConVar("survivor_limit"), GetConVarInt(lt4d_maxsurvivors), true, false);
	survivorlimit = GetConVarInt(FindConVar("survivor_limit"));
	
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("survivor_rescued", Event_SurvivorRescued);
	HookEvent("player_team", Event_PlayerTeam);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsFakeClient(i)) 
		{
			KickClient(i);
		}
	}
	
	Enabled = false;
}

public OnMapEnd()
{
	if (Enabled == true)
	{
		Enabled = false;
	}
}

public OnClientConnected(client)
{
	PlayerCheck();
	if (!IsFakeClient(client))
	{
		NewClient[client] = 1;
	}
}

public OnClientDisconnect(client)
{
	PlayerCheck();	
}

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (Enabled == false)
		{
			Enabled = true;
			PlayerCheck();
			CreateTimer(5.0, Timer_DifficultySet);
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (Enabled == false)
		{
			Enabled = true;
			PlayerCheck();
			CreateTimer(5.0, Timer_DifficultySet);
		}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client)
	{	
		if (GetClientTeam(client) == 2)
		{
			CreateTimer(1.0, Timer_DifficultyCheck);
		}
	}
}

public Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, Timer_DifficultyCheck);
}

public Event_SurvivorRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, Timer_DifficultyCheck);
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (NewClient[client] == 1 && GetEventInt(event, "team") == 2)
	{
		CreateTimer(1.0, Timer_Respawn, client);
	}
	if (NewClient[client] == 1 && GetEventInt(event, "team") == 3)
	{
		NewClient[client] = 0;
	}
}

PlayerCheck()
{
	if (Enabled == true)
	{
		CreateTimer(2.0, Timer_PlayerCheck);
	}
}

public Action:Timer_PlayerCheck(Handle:timer)
{
	//PrintToChatAll("Performing PlayerCheck");
	new maxsurvivors = GetConVarInt(lt4d_maxsurvivors);
	new minsurvivors = GetConVarInt(lt4d_minsurvivors);
	if (minsurvivors > maxsurvivors)
	{
		minsurvivors = maxsurvivors;
	}
	//SetConVarInt(FindConVar("sv_visiblemaxplayers"), maxsurvivors, true, false);
	new players = 0;
	new bots = 0;
	new survivorplayers = 0;
	new idlesurvivors = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			players++;
		}
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") == 0) 
		{
			bots++;
		}
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
		{
			survivorplayers++;
		}
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") > 0)
		{
			idlesurvivors++;
		}
	}
	new actualsurvivorplayers = survivorplayers + idlesurvivors;
	new waitingplayers = players - actualsurvivorplayers;
	new shouldbots = minsurvivors - actualsurvivorplayers;
	//PrintToChatAll("Actual players %i", players);
	//PrintToChatAll("Actual survivor players %i", actualsurvivorplayers);
	//PrintToChatAll("Survivor bots %i", bots);
	//PrintToChatAll("Idle survivors %i", idlesurvivors);
	if (shouldbots <= 0)
	{
		shouldbots = waitingplayers;
	}
	survivorlimit = actualsurvivorplayers + shouldbots;
	//PrintToChatAll("Survivor limit %i", survivorlimit);
	if (survivorlimit > 0)
	{
		SetConVarInt(FindConVar("survivor_limit"), survivorlimit, true, false);
		if (shouldbots > bots)
		{
			new addbots = shouldbots - bots;
			for (new i = 1; i <= addbots; i++)
			{
				ServerCommand("sb_add");
			}
		}
		if (shouldbots < bots)
		{
			new subtractbots = bots - shouldbots;
			for (new i = 1; i <= subtractbots; i++)
			{
				CreateTimer(2.0, Timer_KickBot);
			}
		}
	}
}

public Action:Timer_DifficultySet(Handle:timer)
{
	//PrintToServer("Setting difficulty");
	survivors = GetConVarInt(FindConVar("survivor_limit"));
	SetDifficulty();
}

public Action:Timer_DifficultyCheck(Handle:timer)
{
	DifficultyCheck();
}

DifficultyCheck()
{
	//PrintToServer("Performing difficulty check");
	new alivesurvivors = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if(i)
		{
			if (IsClientConnected(i) && GetClientTeam(i) == 2) 
			{
				if (IsPlayerAlive(i))
				{
					alivesurvivors++;
				}
			}
		}
	}
	//PrintToServer("Alive survivors %i", alivesurvivors);
	survivors = alivesurvivors;
	SetDifficulty();
}

SetDifficulty()
{
	if (GetConVarInt(lt4d_specials) > 0)
	{
		new boomersenable = GetConVarInt(lt4d_specials_boomersenable);
		new chargersenable = GetConVarInt(lt4d_specials_chargersenable);
		new huntersenable = GetConVarInt(lt4d_specials_huntersenable);
		new jockeysenable = GetConVarInt(lt4d_specials_jockeysenable);
		new smokersenable = GetConVarInt(lt4d_specials_smokersenable);
		new spittersenable = GetConVarInt(lt4d_specials_spittersenable);
		if (survivors >= boomersenable)
		{
			SetConVarInt(FindConVar("z_boomer_limit"), 1);
		}
		if (survivors < boomersenable)
		{
			SetConVarInt(FindConVar("z_boomer_limit"), 0);
		}
		if (survivors >= chargersenable)
		{
			SetConVarInt(FindConVar("z_charger_limit"), 1);
		}
		if (survivors < chargersenable)
		{
			SetConVarInt(FindConVar("z_charger_limit"), 0);
		}
		if (survivors >= huntersenable)
		{
			SetConVarInt(FindConVar("z_hunter_limit"), 1);
		}
		if (survivors < huntersenable)
		{
			SetConVarInt(FindConVar("z_hunter_limit"), 0);
		}
		if (survivors >= jockeysenable)
		{
			SetConVarInt(FindConVar("z_jockey_limit"), 1);
		}
		if (survivors < jockeysenable)
		{
			SetConVarInt(FindConVar("z_jockey_limit"), 0);
		}
		if (survivors >= smokersenable)
		{
			SetConVarInt(FindConVar("z_smoker_limit"), 1);
		}
		if (survivors < smokersenable)
		{
			SetConVarInt(FindConVar("z_smoker_limit"), 0);
		}
		if (survivors >= spittersenable)
		{
			SetConVarInt(FindConVar("z_spitter_limit"), 1);
		}
		if (survivors < spittersenable)
		{
			SetConVarInt(FindConVar("z_spitter_limit"), 0);
		}
	}
	if (GetConVarInt(lt4d_commons) > 0)
	{
		if (survivors <= 1)
		{
			PrintToServer("Setting commons for one player.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_1player));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_megamob_1player));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_mobmin_1player));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_mobmax_1player));
		}
		if (survivors == 2)
		{
			PrintToServer("Setting commons for two players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_2players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_megamob_2players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_mobmin_2players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_mobmax_2players));
		}
		if (survivors == 3)
		{
			PrintToServer("Setting commons for three players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_3players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_megamob_3players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_mobmin_3players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_mobmax_3players));
		}
		if (survivors >= 4)
		{
			PrintToServer("Setting commons for four players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_4players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_megamob_4players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_mobmin_4players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_mobmax_4players));
		}
	}
}

public Action:Timer_KickBot(Handle:timer)
{	
	//PrintToChatAll("A bot should be about to be kicked.")
	new bool:ABotHasBeenKicked = false;
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (ABotHasBeenKicked == false)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2) 
			{ 
				//PrintToChatAll("A bot is very likely about to be kicked.")
				if (IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") == 0) 
				{
					//PrintToChatAll("A bot is definitely about to be kicked.")
					if (IsPlayerAlive(i))
					{
						ForcePlayerSuicide(i);
					}
					KickClient(i);
					ABotHasBeenKicked = true;
				}
			}
		}
	}
}

public Action:Timer_Respawn(Handle:timer, any:client)
{
	if (!IsPlayerAlive(client))
	{
		RespawnPlayer(client);
		CreateTimer(3.0, Timer_DifficultySet);
	}
	else
	{
		NewClient[client] = 0;
		CreateTimer(3.0, Timer_DifficultySet);
	}
}

static RespawnPlayer(client)
{
	SDKCall(hRoundRespawn, client);
	CheatCommand(client, "give", "first_aid_kit");
	CheatCommand(client, "give", "smg");
	TeleportPlayer(client);
}

static TeleportPlayer(client)
{
	new iClients[MAXPLAYERS+1];
	new iNumClients = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && IsPlayerAlive(i) && NewClient[i] == 0)
		{
			iClients[iNumClients++] = i;
			decl String:clientname[64];
			GetClientName(i, clientname, 64);
			//PrintToServer("%s is a valid player to teleport to.", clientname);
		}
	}
	new iRandomClient = iClients[GetRandomInt(0, iNumClients-1)];
	decl String:nameofclient[64];
	GetClientName(iRandomClient, nameofclient, 64);
	//PrintToServer("Teleporting new player to %s", nameofclient);
	new Float:coordinates[3];
	GetClientAbsOrigin(iRandomClient, coordinates);
	TeleportEntity(client, coordinates, NULL_VECTOR, NULL_VECTOR);
}

stock CheatCommand(client, String:command[], String:arguments[]="")
{
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}
