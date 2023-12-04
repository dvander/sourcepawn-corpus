#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
#define PLUGIN_VERSION		"1.8.10"
#define CVAR_FLAGS			FCVAR_NOTIFY
#define TEAM_SPECTATOR	1
#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3

ConVar g_ConVarMaxIncap;
ConVar g_ConVarPillsDecayRate;

int g_iMaxIncap;
float g_fPillsDecayRate;
bool g_bLeft4Dead2;
int iLastTime[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name        = "Team Panel",
	author      = "DDRKhat, Marcus101RR, and Merudo, fork by Dragokas",
	description = "Team Panel on Left 4 Dead.",
	version     = PLUGIN_VERSION,
	url         = ""
}

// *********************************************************************************
// METHODS FOR GAME START & END
// *********************************************************************************

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2) {
		g_bLeft4Dead2 = true;		
	}
	else if (test != Engine_Left4Dead) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("TeamPanel.phrases");
	
	CreateConVar("sm_teampanel_drago_version", PLUGIN_VERSION, "Plugin version", CVAR_FLAGS | FCVAR_DONTRECORD);

	RegConsoleCmd("sm_teams", TeamMenu, "Opens Team Panel with Selection");
	RegConsoleCmd("sm_team", TeamMenu, "Opens Team Panel with Selection");
	RegConsoleCmd("sm_online", TeamMenu, "Opens Team Panel with Selection");
	
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("heal_success", Event_HealSuccess);

	g_ConVarMaxIncap = FindConVar("survivor_max_incapacitated_count");
	g_ConVarPillsDecayRate = FindConVar("pain_pills_decay_rate");

	g_ConVarMaxIncap.AddChangeHook(ConVarChanged);
	g_ConVarPillsDecayRate.AddChangeHook(ConVarChanged);
	
	GetCvars();
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iMaxIncap = g_ConVarMaxIncap.IntValue;
	g_fPillsDecayRate = g_ConVarPillsDecayRate.FloatValue;
}

//Show Playerlist Panel after Scoreboard
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if (buttons & IN_SCORE)
	{
		if (iLastTime[client] != 0) // time limit
		{
			if (iLastTime[client] + 5 > GetTime())
			{
				return Plugin_Continue;
			}
		}
		iLastTime[client] = GetTime();
		
		if (!IsValidPlayer(client)) return Plugin_Continue;	
		
		DisplayTeamMenu(client);
	}  
	return Plugin_Continue;
}  

// *********************************************************************************
// TEAM MENU
// *********************************************************************************

public void Event_ReviveSuccess(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	
	if (client && IsClientInGame(client))
	{
		static int r,g,b,a,iRevives;
		
		iRevives = GetEntProp(client, Prop_Send, "m_currentReviveCount");
		
		if (iRevives == 2)
		{
			GetEntityRenderColor(client, r,g,b,a);
			SetEntityRenderColor(client, 0,0,0,a);
		}
		else if (iRevives == g_iMaxIncap)
		{
			GetEntityRenderColor(client, r,g,b,a);
			SetEntityRenderColor(client, 255,0,0,a);
		}
	}
}

public void Event_HealSuccess(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	
	if (client && IsClientInGame(client))
	{
		static int r,g,b,a;
		GetEntityRenderColor(client, r,g,b,a);
		SetEntityRenderColor(client, 255,255,255,a);
	}
}

public Action TeamMenu(int client, int args)
{
	DisplayTeamMenu(client);
	return Plugin_Handled;
}

void DisplayTeamMenu(int client)
{
	static char text_client[64];
	static char title_survivor[64];
	static char title_infected[64];
	static char title_spectator[64];
	static char m_sHealth[64];
	static int iHealth, iRevives, iHealthOffset;
	static float fTemp;
	
	Panel TeamPanel = new Panel();
	
	FormatEx(title_survivor, sizeof(title_survivor), "%T (%d) - %d %T", "Survivors", client, GetTeamPlayers(TEAM_SURVIVOR, false), CheckAvailableBot(TEAM_SURVIVOR), "Bot(s)", client);
	TeamPanel.DrawItem(title_survivor);
	
	if (iHealthOffset == 0)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) != TEAM_SPECTATOR)
			{
				iHealthOffset = FindDataMapInfo(i, "m_iHealth");
				break;
			}
		}
	}

	// Draw Survivor Group
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR)
		{
			if(IsPlayerAlive(i))
			{
				if(GetEntProp(i, Prop_Send, "m_isIncapacitated"))
				{
					FormatEx(m_sHealth, sizeof(m_sHealth), " [%T] - %d HP - ", "INCAP", client, GetEntData(i, iHealthOffset, 4));
				}
				else {
					iRevives = GetEntProp(i, Prop_Send, "m_currentReviveCount");
					
					if (iRevives == g_iMaxIncap)
					{
						FormatEx(m_sHealth, sizeof(m_sHealth), " [%T] - %d HP - ", "B/R", client, GetClientRealHealth(i));
					}
					else if (iRevives == 2) {
						FormatEx(m_sHealth, sizeof(m_sHealth), " [%T] - %d HP - ", "B/W", client, GetClientRealHealth(i));
					}
					else {
						iHealth = GetClientRealHealth(i, fTemp);
						FormatEx(m_sHealth, sizeof(m_sHealth), "%d%s HP - ", iHealth, fTemp > 0.0 ? "-" : "");
					}
				}
			}
			else
			{
				FormatEx(m_sHealth, sizeof(m_sHealth), " [%T] - ", "DEAD", client);
			}
			
			FormatEx(text_client, sizeof(text_client), "%s%N", m_sHealth, i);
			TeamPanel.DrawText(text_client);
		}
	}
	
	FormatEx(title_spectator, sizeof(title_spectator), "%T (%d)", "Spectators", client, GetTeamPlayers(TEAM_SPECTATOR, false));
	TeamPanel.DrawItem(title_spectator);
	
	// Draw Spectator Group
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SPECTATOR)
		{
			FormatEx(text_client, sizeof(text_client), " %N", i);
			TeamPanel.DrawText(text_client);
		}
	}

	if(VersusModes())
	{
		FormatEx(title_infected, sizeof(title_infected), "%T (%d) - %d %T", "Infected", client, GetTeamPlayers(TEAM_INFECTED, false), CheckAvailableBot(TEAM_INFECTED), "Bot(s)", client);
		TeamPanel.DrawItem(title_infected);
			
		// Draw Infected Group
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED)
			{
				if(IsPlayerAlive(i))
				{
					if(GetEntProp(i, Prop_Send, "m_isIncapacitated"))
					{
						FormatEx(m_sHealth, sizeof(m_sHealth), " [%T] - %d HP - ", "DOWN", client, GetEntData(i, iHealthOffset, 4));
					}
					if(GetEntProp(i, Prop_Send, "m_isGhost"))
					{
						FormatEx(m_sHealth, sizeof(m_sHealth), " [%T] - ", "GHOST", client);
					}
					else
					{
						FormatEx(m_sHealth, sizeof(m_sHealth), "%d HP - ", GetEntData(i, iHealthOffset, 4));
					}
				}
				else
					FormatEx(m_sHealth, sizeof(m_sHealth), " [%T] - ", "DEAD", client);
				
				FormatEx(text_client, sizeof(text_client), "%s%N", m_sHealth, i);
				TeamPanel.DrawText(text_client);
			}
		}
	}
	
	TeamPanel.Send(client, TeamMenuHandler, 10);
	delete TeamPanel;
}

public int TeamMenuHandler(Menu UpgradePanel, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		if(param2 == 1)
		{
/*			if(g_bLeft4Dead2)
			{
				FakeClientCommand(client, "sm_survivor");
			}
			else
			{
				//FakeClientCommand(client, "sm_join");
			}
			FakeClientCommand(client, "sm_s0");*/
		}
		else if(param2 == 2)
		{
			//FakeClientCommand(client, "sm_spec");
		}
		else if(param2 == 3)
		{
			//FakeClientCommand(client, "sm_infected");
		}
	}
	else if(action == MenuAction_Cancel)
	{
		// Nothing
	}
	return 0;
}

int GetClientRealHealth(int client, float &temp = 0.0)
{
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || IsClientObserver(client))
	{
		return -1;
	}

	if(GetClientTeam(client) != TEAM_SURVIVOR)
	{
		return GetClientHealth(client);
	}
	
	float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float TempHealth;
	int PermHealth = GetClientHealth(client);
	if(buffer <= 0.0)
	{
		TempHealth = 0.0;
	}
	else
	{
		float difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		float constant = 1.0 / g_fPillsDecayRate;
		TempHealth = buffer - (difference / constant);
	}
	
	if(TempHealth < 0.0)
	{
		TempHealth = 0.0;
	}
	
	temp = TempHealth;
	return PermHealth + RoundToFloor(TempHealth);
}

//Is Valid Player
int IsValidPlayer(int client)
{
	if (client == 0)
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	return true;
}

bool VersusModes()
{
	char GameMode[16];
	ConVar gamecvar_mp_gamemode = FindConVar("mp_gamemode");
	gamecvar_mp_gamemode.GetString(GameMode, sizeof(GameMode));
	if (StrEqual(GameMode, "versus", false) == true 
	||  StrEqual(GameMode, "mutation11", false) == true 
	||  StrEqual(GameMode, "mutation12", false) == true 
	||  StrEqual(GameMode, "mutation18", false) == true 
	||  StrEqual(GameMode, "mutation19", false) == true 
	||  StrEqual(GameMode, "community3", false) == true 
	||  StrEqual(GameMode, "community6", false) == true
	)
	{
		return true;
	}
	return false;
}

// ------------------------------------------------------------------------
// Returns true if all connected players are in the game
// ------------------------------------------------------------------------
stock bool HasIdlePlayer(int bot)
{
	if(IsClientInGame(bot) && GetClientTeam(bot) == TEAM_SURVIVOR && IsPlayerAlive(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if(IsFakeClient(bot) && strcmp(sNetClass, "SurvivorBot") == 0)
		{
			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
			if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR)
			{
				return true;
			}
		}
	}
	return false;
}

// ------------------------------------------------------------------------
// Returns true if survivor player is idle.
// ------------------------------------------------------------------------
stock bool IsClientIdle(int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR)
		{
			int spectator_userid = GetEntData(i, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID"));
			int spectator_client = GetClientOfUserId(spectator_userid);

			if(spectator_client == client)
				return true;
		}
	}
	return false;
}

// ------------------------------------------------------------------------
// Get the number of players on the team
// includeBots == true : counts bots
// ------------------------------------------------------------------------
int GetTeamPlayers(int team, bool includeBots)
{
	int players = 0;
	for(int i = 1; i <= MaxClients; i++)
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

// ------------------------------------------------------------------------
// Is the bot valid? (either survivor or infected)
// ------------------------------------------------------------------------
bool IsBotValid(int client)
{
	//if(IsClientInGame(client) && IsFakeClient(client) && !HasIdlePlayer(client) && !IsClientInKickQueue(client))
	//	return true;
	if(IsClientInGame(client) && IsFakeClient(client))
		return true;
	return false;
}

// ------------------------------------------------------------------------
// Check if how many alive bots are available in a team
// ------------------------------------------------------------------------
int CheckAvailableBot(int team)
{
	int num = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsBotValid(i) && IsPlayerAlive(i) && GetClientTeam(i) == team)
			num++;
	}
	return num;
}
