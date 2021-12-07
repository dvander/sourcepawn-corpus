#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <cstrike>

#define LIFE_MODE_PLAYER		0
#define LIFE_MODE_TEAM			1

#define MAXTEAMS 				2

int g_Lives[MAXPLAYERS + 1];
int g_TeamLives[MAXTEAMS + 1];
int g_OriginalTeam[MAXPLAYERS + 1];

bool g_LiveRound = false;

EngineVersion g_Engine;

ConVar g_cvLifeCount;
ConVar g_cvLifeMode;

bool g_Teamplay;
int g_LifeMode;

public void OnPluginStart()
{
	/*
	 * Yay convars for expanded functionality!
	 */
	g_cvLifeCount = CreateConVar("sm_lives_amount", "5", "How many lives should players be given?", FCVAR_NOTIFY);
	g_cvLifeMode = CreateConVar("sm_lives_mode", "0", "Style of lives to be using? (0 = Players have X lives individually, 1 = Team shared lives)", FCVAR_NOTIFY);
	g_cvLifeMode.AddChangeHook(OnLifeModeChanged);
	AutoExecConfig();

	g_Teamplay = GetConVarBool(FindConVar("mp_teamplay"));
	g_Engine = GetEngineVersion();

	RegAdminCmd("sm_setlives", command_SetLives, ADMFLAG_CUSTOM5, "Set the lives of a player or team");
	RegAdminCmd("sm_takelives", command_TakeLives, ADMFLAG_CUSTOM5, "Take lives from a player or team");
	RegAdminCmd("sm_givelives", command_GiveLives, ADMFLAG_CUSTOM5, "Give lives to a player or team");

	AddCommandListener(listener_Jointeam, "jointeam");

	char _gameFolder[64];
	GetGameFolderName(_gameFolder, sizeof(_gameFolder));
	if(!HookEventEx("player_death", OnPlayerDeath)) SetFailState("Game %s does not support event: player_death, unloading...", _gameFolder);
	if(!HookEventEx("round_start", OnRoundStart)) SetFailState("Game %s does not support event: round_start, unloading...", _gameFolder);
	if(!HookEventEx("player_team", OnJoinTeam, EventHookMode_Pre)) SetFailState("Game %s does not support event: player_team, unloading...", _gameFolder);
}

public void OnClientPutInServer(int client)
{
	//nitialize Values - Round Start will give players lives.
	g_Lives[client] = 0;
	g_OriginalTeam[client] = 1;
}

public Action listener_Jointeam(int client, const char[] command, int argc)
{
	char _team[32];
	GetCmdArg(1, _team, sizeof(_team));

	if(StringToInt(_team) == 1) return Plugin_Continue;

	if(IsClientObserver(client) && g_OriginalTeam[client] < 2)
	{
		DispatchSpawn(client);
		return Plugin_Continue;
	}

	return Plugin_Handled;
}

public Action command_SetLives(int client, int args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Invalid Syntax: sm_setlives <player/team> <value>");
		return Plugin_Handled;
	}

	char sTarget[32];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	
	switch(g_LifeMode)
	{	
		//Player Lives:
		case 0:
		{
			int target = FindTarget(client, sTarget, true, false);
			if(target == -1)
			{
				ReplyToCommand(client, "[SM] Invalid Target: %s", sTarget);
				return Plugin_Handled;
			}

			char sLives[32];
			GetCmdArg(2, sLives, sizeof(sLives));
			int _Lives = StringToInt(sLives);
			
			g_Lives[target] = _Lives;
			ReplyToCommand(client, "[SM] Set the lives %N to %i", target, _Lives);
			return Plugin_Handled;
		}

		//Team Lives:
		default:
		{	
			int _Team = -1;
			if(StringToInt(sTarget) == 2 || StringToInt(sTarget) == 3) _Team = StringToInt(sTarget);
			else _Team = StringToTeamIndex(sTarget);

			if(StringToTeamIndex(sTarget) == -1)
			{
				ReplyToCommand(client, "[SM] Invalid Target - Must be Team ID or Team Name");
				return Plugin_Handled;
			}	

			char sLives[32];
			GetCmdArg(2, sLives, sizeof(sLives));
			int _Lives = StringToInt(sLives);
			
			g_TeamLives[_Team] = _Lives;
			ReplyToCommand(client, "[SM] Set the lives of team %s to %i", sTarget, _Lives);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action command_TakeLives(int client, int args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Invalid Syntax: sm_takelives <player/team> <value>");
		return Plugin_Handled;
	}

	char sTarget[32];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	
	switch(g_LifeMode)
	{	
		//Player Lives:
		case 0:
		{
			int target = FindTarget(client, sTarget, true, false);
			if(target == -1)
			{
				ReplyToCommand(client, "[SM] Invalid Target: %s", sTarget);
				return Plugin_Handled;
			}

			char sLives[32];
			GetCmdArg(2, sLives, sizeof(sLives));
			int _Lives = StringToInt(sLives);
			
			g_Lives[target] -= _Lives;
			ReplyToCommand(client, "[SM] Took %i lives from %N", _Lives, target);
			return Plugin_Handled;
		}

		//Team Lives:
		default:
		{	
			int _Team = -1;
			if(!StrEqual(sTarget, "2", false) || !StrEqual(sTarget, "3", false)) _Team = StringToTeamIndex(sTarget);

			if(StringToTeamIndex(sTarget) == -1)
			{
				ReplyToCommand(client, "[SM] Invalid Target - Must be Team ID or Team Name");
				return Plugin_Handled;
			}	

			char sLives[32];
			GetCmdArg(2, sLives, sizeof(sLives));
			int _Lives = StringToInt(sLives);
			
			g_TeamLives[_Team] -= _Lives;
			ReplyToCommand(client, "[SM] Took %i lives from team %s", _Lives, sTarget);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action command_GiveLives(int client, int args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Invalid Syntax: sm_givelives <player/team> <value>");
		return Plugin_Handled;
	}

	char sTarget[32];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	
	switch(g_LifeMode)
	{	
		//Player Lives:
		case 0:
		{
			int target = FindTarget(client, sTarget, true, false);
			if(target == -1)
			{
				ReplyToCommand(client, "[SM] Invalid Target: %s", sTarget);
				return Plugin_Handled;
			}

			char sLives[32];
			GetCmdArg(2, sLives, sizeof(sLives));
			int _Lives = StringToInt(sLives);
			
			g_Lives[target] += _Lives;
			ReplyToCommand(client, "[SM] Gave %i lives to %N", _Lives, target);
			return Plugin_Handled;
		}

		//Team Lives:
		default:
		{	
			int _Team = -1;
			if(!StrEqual(sTarget, "2", false) || !StrEqual(sTarget, "3", false)) _Team = StringToTeamIndex(sTarget);

			if(StringToTeamIndex(sTarget) == -1)
			{
				ReplyToCommand(client, "[SM] Invalid Target - Must be Team ID or Team Name");
				return Plugin_Handled;
			}	

			char sLives[32];
			GetCmdArg(2, sLives, sizeof(sLives));
			int _Lives = StringToInt(sLives);
			
			g_TeamLives[_Team] += _Lives;
			ReplyToCommand(client, "[SM] Gave %i lives to team %s", _Lives, sTarget);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

/*
 * StringToTeamIndex
 * @param str: Argument String
 * @return: Team Index or -1
 * @error: -1
 */
stock int StringToTeamIndex(char[] str)
{
	//TF2 Teams:
	if(StrEqual(str, "Blu", false) || StrEqual(str, "Blue", false)) return 3;
	else if(StrEqual(str, "Red", false)) return 2;

	//CStrike Teams:
	else if(StrEqual(str, "Terrorists", false) || StrEqual(str, "Terrorist", false) || StrEqual(str, "T", false)) return 2;
	else if(StrEqual(str, "Counter", false) || StrEqual(str, "CounterTerrorist", false) || StrEqual(str, "CT", false) || StrEqual(str, "CTs", false)) return 3;

	//HL2MP Teams:
	else if(StrEqual(str, "Rebel", false) || StrEqual(str, "Rebels", false)) return 3;
	else if(StrEqual(str, "Combine", false) || StrEqual(str, "Combines", false)) return 2;
	else return -1;
}

public void OnLifeModeChanged(ConVar convar, const char[] oldVal, const char[] newVal)
{
	g_LifeMode = StringToInt(newVal);
}

public void OnConfigsExecuted()
{
	g_LifeMode = g_cvLifeMode.IntValue;

	//If teamplay is disabled, set lifemode to individual player:
	if(!g_Teamplay && g_LifeMode == LIFE_MODE_TEAM) g_cvLifeMode.IntValue = 0;
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(!g_LiveRound) return;

	switch(g_LifeMode)
	{
		//g_LifeMode or g_cvLifeMode < 1 - Individual Player Lives
		case 0:
		{
			if(g_Lives[client] <= 0)
			{
				if(g_Engine != Engine_CSGO || g_Engine != Engine_CSS) ChangeClientTeam(client, 1); //Set to spectator.
				PrintToChat(client, "[SM] You have run out of lives.");
				return;
			}

			g_Lives[client] --;
			PrintToChat(client, "[SM] You have %i lives remaining.", g_Lives[client]);
			if(g_Engine == Engine_CSGO || g_Engine == Engine_CSS) CS_RespawnPlayer(client);
			return;
		}

		//g_LifeMode or g_cvLifeMode > 0 - Team Lives
		default:
		{
			int _TeamNum = GetClientTeam(client);
			if(g_TeamLives[_TeamNum - 2] <= 0)
			{
				PrintToChat(client, "[SM] Your team has no more lives to spare.");
				if(g_Engine != Engine_CSGO || g_Engine != Engine_CSS) ChangeClientTeam(client, 1); //Set to spectator.
				return;
			}

			g_TeamLives[_TeamNum - 2] --;

			for(int i = 1; i <= MaxClients; i++)
			{
				if(GetClientTeam(i) == _TeamNum)
				{
					PrintToChatAll("[SM] Your team has %i lives remaining.", g_TeamLives[_TeamNum - 2]);
					if(g_Engine == Engine_CSGO || g_Engine == Engine_CSS) CS_RespawnPlayer(client);
					return;
				}
			}
		}
	}

	//Check team sizes, if empty, restart round.
	int _TeamSize[2];

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(GetClientTeam(i) == 2) _TeamSize[0]++;
			else if(GetClientTeam(i) == 3) _TeamSize[1]++;
		}
	}

	//Team 2 has no more players:
	if(_TeamSize[0] < 1)
	{
		SetTeamScore(3, GetTeamScore(3) + 1);
		switch(g_Engine)
		{
			case Engine_CSGO, Engine_CSS:
			{
				PrintToChatAll("[SM] Terrorists have run out of lives. Counter-Terrorist Victory!");
			}

			case Engine_TF2:
			{
				PrintToChatAll("[SM] Red has ran out of lives. Blue Victory!");
			}

			case Engine_HL2DM:
			{
				PrintToChatAll("[SM] Combine has ran out of lives. Rebel Victory!");
			}
		}
		ServerCommand("mp_restartgame 10");
	}
	else if(_TeamSize[1] < 1) //Team 3 has no more players:
	{

		SetTeamScore(2, GetTeamScore(2) + 1);
		switch(g_Engine)
		{
			case Engine_CSGO, Engine_CSS:
			{
				PrintToChatAll("[SM] Counter-Terrorists have run out of lives. Terrorist Victory!");
			}

			case Engine_TF2:
			{
				PrintToChatAll("[SM] Blue has ran out of lives. Red Victory!");
			}

			case Engine_HL2DM:
			{
				PrintToChatAll("[SM] Rebels have ran out of lives. Combine Victory!");
			}
		}
		ServerCommand("mp_restartgame 10");
	}
	else return; //Both teams have players:
}

public int GetValidPlayerCount()
{
	int _players = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && g_OriginalTeam[i] != 1 && !IsClientSourceTV(i))
		{
			_players++;
		}
	}

	return _players;
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(GetValidPlayerCount() < 2)
	{
		g_LiveRound = false;
		PrintToChatAll("[SM] Lives are not in effect due to low player count.");
	}
	else g_LiveRound = true;

	switch(g_LifeMode)
	{
		//g_LifeMode or g_cvLifeMode < 1 - Individual Player Lives
		case 0:
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					if(g_OriginalTeam[i] > 1)
					{
						g_Lives[i] = g_cvLifeCount.IntValue;
					}
				}
			}
		}

		default:
		{
			for(int i = 0; i < MAXTEAMS; i++)
			{
				g_TeamLives[i] = g_cvLifeCount.IntValue;
			}
		}
	}

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientSourceTV(i))
		{
			//SetEntProp(i, Prop_Send, "m_lifeState", 2);
			if(g_OriginalTeam[i] > 1)
			{
				ChangeClientTeam(i, g_OriginalTeam[i]);
				DispatchSpawn(i);
			}
			//SetEntProp(i, Prop_Send, "m_lifeState", 0);
		}
	}
}

public Action OnJoinTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int _NewTeam = event.GetInt("team");

	if (!dontBroadcast && !event.GetBool("silent"))
	{
		SetEventBroadcast(event, true);
    }

	if(g_Lives[client] <= 0) 
	{
		ChangeClientTeam(client, 1);
		ClientCommand(client, "spectate");
		//return Plugin_Changed;
	}

	if(_NewTeam > 1) //Joining team other than spectator
	{
		g_OriginalTeam[client] = _NewTeam;
		switch(g_LifeMode)
		{
			case 0:
			{
				if(g_Lives[client] < 1)
				{
					ChangeClientTeam(client, 1);
				}
				else
				{
					ChangeClientTeam(client, _NewTeam);
					DispatchSpawn(client);
				}
			}

			default:
			{
				if(g_TeamLives[_NewTeam - 2] < 1)
				{
					ChangeClientTeam(client, 1);
				}
				else
				{
					ChangeClientTeam(client, _NewTeam);
					DispatchSpawn(client);
				}
			}
		}
		
		if(!g_LiveRound) CreateTimer(1.0, InitLiveRound);
		return Plugin_Changed;
	}
	else if(_NewTeam == 1 && g_OriginalTeam[client] != 1) //New team is spectator, but cached team is not spectator
	{
	}
	return Plugin_Changed;
}


//Some sort of anti cheese I guess
public Action InitLiveRound(Handle timer)
{
	if(!g_LiveRound)
	{
		int _players = GetValidPlayerCount();
		if(_players > 1) ServerCommand("mp_restartgame 10");
	}
	return Plugin_Handled;
}

public Plugin myinfo =
{
	name = "Live or Lose",
	author = "Sidezz",
	description = "An abstract gamemode variant that involves lives in generalized gameplay",
	version = "1.0",
	url = "http://steamcommunity.com/id/Sidezz/"
}