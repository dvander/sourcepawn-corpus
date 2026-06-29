#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.9.3"
#define SURVIVOR 2
#define INFECTED 3
#define CVAR_FLAGS FCVAR_NOTIFY

int sb_all_bot_type = 0;
ConVar g_hCvarAllow, g_hGameMode;
bool g_bCvarAllow = false, HumanMoved = false, LeftSafe = false, Started[MAXPLAYERS + 1] = {false, ...};

// Plugin info
public Plugin myinfo = 
{
	name = "[L4D/L4D2] VS Bug Fix",
	author = "Pescoxa",
	description = "Fix for Versus Server shutting down and Bots starting without players",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=126940"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if(test == Engine_Left4Dead)
	{
		sb_all_bot_type = 1;
	}
	else if(test == Engine_Left4Dead2)
	{
		sb_all_bot_type = 2;
	}
	else
	{
		strcopy(error, err_max, "VS Bug Fix supports L4D and L4D2 only.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_vsbugfix_version", PLUGIN_VERSION, "[L4D/L4D2] VS Bug Fix", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_hCvarAllow = CreateConVar("sm_vsbugfix_allow", "1", "0 = Plugin off, 1 = Plugin on.", CVAR_FLAGS);

	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hGameMode = FindConVar("mp_gamemode");
	g_hGameMode.AddChangeHook(ConVarChanged_GameMode);

	AutoExecConfig(true, "sm_vsbugfix");

	LeftSafe = false;
	SetStarted(false);

	LoadTranslations("l4d_sm_vsbugfix.phrases");

	RegAdminCmd("sm_unfreezebots", Command_UnfreezeBots, ADMFLAG_CUSTOM1);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_GameMode(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(g_bCvarAllow) Init(true);
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	if(!g_bCvarAllow && bCvarAllow)
	{
		g_bCvarAllow = true;
		Init(true);
		HookEvent("round_start", Event_Round_Start, EventHookMode_Post);
		HookEvent("round_end",Event_Round_End, EventHookMode_Post);
		HookEvent("player_team", Event_Join_Team, EventHookMode_Post);
		HookEvent("player_left_checkpoint", Event_Left_CheckPoint, EventHookMode_Post);
	}
	else if(g_bCvarAllow && !bCvarAllow)
	{
		Init(false);
		g_bCvarAllow = false;
		UnhookEvent("round_start", Event_Round_Start, EventHookMode_Post);
		UnhookEvent("round_end",Event_Round_End, EventHookMode_Post);
		UnhookEvent("player_team", Event_Join_Team, EventHookMode_Post);
		UnhookEvent("player_left_checkpoint", Event_Left_CheckPoint, EventHookMode_Post);
	}
}

void Init(bool SwitchOn)
{
	if(SwitchOn)
	{
		if (IsValidMode())
		{
			if (sb_all_bot_type == 2) FindConVar("sb_all_bot_game").SetInt(1);
			else FindConVar("sb_all_bot_team").SetInt(1);

			if (!LeftSafe)
			{
				FindConVar("sb_stop").SetInt(1);
				FindConVar("director_ready_duration").SetInt(0);
				FindConVar("director_no_mobs").SetInt(1);
			}
			else
			{
				ResetConVar(FindConVar("sb_stop"));
				ResetConVar(FindConVar("director_ready_duration"));
				ResetConVar(FindConVar("director_no_mobs"));
			}
		}
		else
		{
			if (sb_all_bot_type == 2) ResetConVar(FindConVar("sb_all_bot_game"));
			else ResetConVar(FindConVar("sb_all_bot_team"));
			ResetConVar(FindConVar("sb_stop"));
			ResetConVar(FindConVar("director_ready_duration"));
			ResetConVar(FindConVar("director_no_mobs"));
		}
	}
	else
	{
		if (sb_all_bot_type == 2) ResetConVar(FindConVar("sb_all_bot_game"));
		else ResetConVar(FindConVar("sb_all_bot_team"));
		ResetConVar(FindConVar("sb_stop"));
		ResetConVar(FindConVar("director_ready_duration"));
		ResetConVar(FindConVar("director_no_mobs"));
	}
}

void SetStarted(bool Value)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		Started[i] = Value;
	}
}

bool IsValidMode()
{
	char gmode[32];
	FindConVar("mp_gamemode").GetString(gmode, sizeof(gmode));
	if (StrEqual(gmode, "versus", false) || StrEqual(gmode, "teamversus", false) || StrEqual(gmode, "scavenge", false) || StrEqual(gmode, "teamscavenge", false) || StrEqual(gmode, "mutation12", false))
	{
		return true;
	}
	else
	{
		return false;
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// BEGIN: COMMANDS
///////////////////////////////////////////////////////////////////////////////////////////////////
Action Command_UnfreezeBots(int client, int args)
{
	RunUnfreeze();
	ReplyToCommand(client, "\x04[VBF] \x01%T", "BOTsAreUnfrozen.", client);
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////
// END: COMMANDS
///////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////
// BEGIN: GOD FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////
void God(int client, bool value)
{
	if (client > 0 && IsClientInGame(client))
	{
		if (value && IsPlayerAlive(client))
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);		
			PrintToChat(client, "\x04[VBF] \x01%T", "GodOn", client);
		}
		else
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			PrintToChat(client, "\x04[VBF] \x01%T", "GodOff", client);
		}
	}
}

Action TimerGod(Handle timer, any client)
{
	if(client > 0)
	{
		if (!LeftSafe) God(client, true);
		else God(client, false);
	}
	return Plugin_Stop;
}

Action TimerUnGod(Handle timer, any client)
{
	if(client > 0) God(client, false);
	return Plugin_Stop;
}
///////////////////////////////////////////////////////////////////////////////////////////////////
// END: GOD FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////
// BEGIN: FREEZE AND UNFREEZE FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////
void FreezeAllSurvivorBOT()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidEntity(i) && IsClientConnected(i) && !IsClientInKickQueue(i) && IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == SURVIVOR)
		{
			SetEntityMoveType(i, MOVETYPE_NONE);
		}
	}

	if (!LeftSafe) FindConVar("sb_stop").SetInt(1);
}

void UnFreezeAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
	
		if (IsValidEntity(i) && IsClientConnected(i) && !IsClientInKickQueue(i) && IsClientInGame(i) && GetClientTeam(i) != 1)
		{
			UnFreeze(i);
			God(i, false);
		}
	}
	ResetConVar(FindConVar("sb_stop"));
}

void FreezeUnFreezeClient(int client, int clientTeam)
{
	if(client > 0 && IsValidEntity(client) && IsClientConnected(client))
	{
		if(IsFakeClient(client))
		{
			if(clientTeam == SURVIVOR)
			{
				if(!LeftSafe)
				{
					CreateTimer(0.5, TimerFreeze, client);
				}
			}
			return;
		}
		else
		{
			CreateTimer(0.5, TimerUnFreeze, client);
			return;
		}
	}
}

void UnFreeze(int client)
{
	if((client > 0) && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client))
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
}

Action TimerFreeze(Handle timer, any client)
{
	FreezeAllSurvivorBOT();
	return Plugin_Stop;
}

Action TimerUnFreeze(Handle timer, any client)
{
	UnFreeze(client);
	return Plugin_Stop;
}
///////////////////////////////////////////////////////////////////////////////////////////////////
// END: FREEZE AND UNFREEZE FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////
// BEGIN: EVENTS THAT CONTROLS THE PLUGIN
///////////////////////////////////////////////////////////////////////////////////////////////////

void Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	LeftSafe = false;
	SetStarted(false);
	HumanMoved = false;
	Init(true);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (buttons & IN_MOVELEFT || buttons & IN_BACK || buttons & IN_FORWARD || buttons & IN_MOVERIGHT || buttons & IN_USE)
	{
		if (client > 0 && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client) && (GetClientTeam(client) == SURVIVOR))
		{
			if (!IsFakeClient(client)) HumanMoved = true;
			if (HumanMoved)
			{
				Started[client] = true;
			}
		}
	}
	return Plugin_Continue;
}

void Event_Left_CheckPoint(Event event, const char[] event_name, bool dontBroadcast)
{
	int entity = event.GetInt("entityid");
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && Started[client] && entity == 0 && !LeftSafe)
	{
		CreateTimer(0.5, OnLeftSafeArea, client);
	}
}

Action OnLeftSafeArea(Handle timer, any client)
{
	if (client > 0 && IsClientInGame(client))
	{
		if (GetClientTeam(client) != SURVIVOR)
		{
			Started[client] = false;
			return Plugin_Stop;
		}
		RunUnfreeze();
	}
	return Plugin_Stop;	
}

void RunUnfreeze()
{
	LeftSafe = true;
	SetStarted(true);
	UnFreezeAll();
	ResetConVar(FindConVar("sb_stop"));
	ResetConVar(FindConVar("director_ready_duration"));
	ResetConVar(FindConVar("director_no_mobs"));
}

void Event_Join_Team(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int clientTeam = event.GetInt("team");
	FreezeUnFreezeClient(client, clientTeam);

	if (!LeftSafe)
	{
		if (clientTeam == SURVIVOR) CreateTimer(0.5, TimerGod, client);
		else if (clientTeam == INFECTED) CreateTimer(0.5, TimerUnGod, client);
		SetStarted(false);
	}
}

void Event_Round_End(Event event, const char[] event_name, bool dontBroadcast)
{
	LeftSafe = false;
	SetStarted(false);
	HumanMoved = false;
}
///////////////////////////////////////////////////////////////////////////////////////////////////
// END: EVENTS THAT CONTROLS THE PLUGIN
///////////////////////////////////////////////////////////////////////////////////////////////////