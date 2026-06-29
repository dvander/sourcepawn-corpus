#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.00"

#define BOTH_TEAMS 1
#define RED_TEAM 2
#define BLU_TEAM 3

#define VC_MEDIC "0 0"
#define VC_THANKS "0 1"
#define VC_GOGOGO "0 2"
#define VC_MOVEUP "0 3"
#define VC_GOLEFT "0 4"
#define VC_GORIGHT "0 5"
#define VC_YES "0 6"
#define VC_NO "0 7"
#define VC_PASSTOME "0 8"

#define VC_INCOMING "1 0"
#define VC_SPY "1 1"
#define VC_SENTRYAHEAD "1 2"
#define VC_TELEPORTERHERE "1 3"
#define VC_DISPENSERHERE "1 4"
#define VC_SENTRYHERE "1 5"
#define VC_ACTIVATEUBER "1 6"
#define VC_UBERREADY "1 7"
#define VC_PASSTOME2 "1 8"

#define VC_HELP "2 0"
#define VC_BATTLECRY "2 1"
#define VC_CHEERS "2 2"
#define VC_JEERS "2 3"
#define VC_POSITIVE "2 4"
#define VC_NEGATIVE "2 5"
#define VC_NICESHOT "2 6"
#define VC_GOODJOB "2 7"

#define IDLE_CHATTER_DELAY 4.0
#define KILL_CHATTER_DELAY 2.0
#define POINT_CAPTURE_CHATTER_DELAY 2.0
#define FLAG_EVENT_CHATTER_DELAY 2.0
#define BUILDING_UPGRADE_CHATTER_DELAY 2.0
#define TEAM_CHATTER_DELAY 4.0

bool g_bRoundEnd;
bool g_bMVM;
bool g_bCVEnabled;
bool g_bCVMVMSupported;
bool g_bCVIdleChatter;
int g_iCVTeam;
Handle g_hVoiceTriggerTimer[MAXPLAYERS+1];
Handle g_hIdleVoiceTriggerTimer[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Give Bots Voice Commands",
	author = "luki1412",
	description = "Gives TF2 bots voice commands",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=43109"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		FormatEx(error, err_max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVar hCVVersion = CreateConVar("sm_gbvc_version", PLUGIN_VERSION, "Give Bots Voice Commands version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	ConVar hCVEnabled = CreateConVar("sm_gbvc_enabled", "1", "Enables/disables this plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	ConVar hCVTeam = CreateConVar("sm_gbvc_team", "1", "Team to give voice commands to: 1-both, 2-red, 3-blu", FCVAR_NONE, true, 1.0, true, 3.0);
	ConVar hCVMVMSupported = CreateConVar("sm_gbvc_mvm", "0", "Enables/disables giving bots voice commands when MVM mode is enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	ConVar hCVIdleChatter = CreateConVar("sm_gbvc_idlechatter", "1", "Enables/disables using some voice commands for idle chatter", FCVAR_NONE, true, 0.0, true, 1.0);

	OnEnabledChanged(hCVEnabled, "", "");
	HookConVarChange(hCVEnabled, OnEnabledChanged);
	OnMVMSupportedChanged(hCVMVMSupported, "", "");
	HookConVarChange(hCVMVMSupported, OnMVMSupportedChanged);
	OnIdleChatterChanged(hCVIdleChatter, "", "");
	HookConVarChange(hCVIdleChatter, OnIdleChatterChanged);
	OnTeamChanged(hCVTeam, "", "");
	HookConVarChange(hCVTeam, OnTeamChanged);
	SetConVarString(hCVVersion, PLUGIN_VERSION);
	AutoExecConfig(true, "Give_Bots_Voice_Commands");

	delete hCVVersion;
	delete hCVEnabled;
	delete hCVTeam;
	delete hCVMVMSupported;
	delete hCVIdleChatter;
}

public void OnEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(convar))
	{
		g_bCVEnabled = true;
		HookEvent("player_chargedeployed", player_chargedeployed);
		HookEvent("teamplay_point_startcapture", teamplay_point_startcapture);
		HookEvent("teamplay_flag_event", teamplay_flag_event);
		HookEvent("teamplay_capture_blocked", teamplay_capture_blocked);
		HookEvent("player_upgradedobject", player_upgradedobject);
		HookEvent("player_death", player_death);
		HookEvent("teamplay_round_win", teamplay_round_win);
		HookEvent("player_spawn", player_spawn);
		HookEvent("player_hurt", player_hurt);
		HookEvent("teamplay_round_start", teamplay_round_start, EventHookMode_PostNoCopy);
	}
	else
	{
		g_bCVEnabled = false;
		UnhookEvent("player_chargedeployed", player_chargedeployed);
		UnhookEvent("teamplay_point_startcapture", teamplay_point_startcapture);
		UnhookEvent("teamplay_flag_event", teamplay_flag_event);
		UnhookEvent("teamplay_capture_blocked", teamplay_capture_blocked);
		UnhookEvent("player_upgradedobject", player_upgradedobject);
		UnhookEvent("player_death", player_death);
		UnhookEvent("teamplay_round_win", teamplay_round_win);
		UnhookEvent("player_spawn", player_spawn);
		UnhookEvent("player_hurt", player_hurt);
		UnhookEvent("teamplay_round_start", teamplay_round_start, EventHookMode_PostNoCopy);

		for (int i = 0; i < (MAXPLAYERS+1); i++)
		{
			delete g_hVoiceTriggerTimer[i];
			delete g_hIdleVoiceTriggerTimer[i];
		}
	}
}

public void OnMVMSupportedChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bCVMVMSupported = GetConVarBool(convar);
}

public void OnIdleChatterChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bCVIdleChatter = GetConVarBool(convar);
}

public void OnTeamChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iCVTeam = GetConVarInt(convar);
}

public void OnMapStart()
{
	g_bMVM = GameRules_GetProp("m_bPlayingMannVsMachine") ? true : false;

	for (int i = 0; i < (MAXPLAYERS+1); i++)
	{
		delete g_hVoiceTriggerTimer[i];
		delete g_hIdleVoiceTriggerTimer[i];
	}
}

public void OnClientDisconnect(int client)
{
	delete g_hVoiceTriggerTimer[client];
	delete g_hIdleVoiceTriggerTimer[client];
}

public void player_hurt(Handle event, const char[] ename, bool dontBroadcast)
{
	if (!g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported) || (GetURandomFloat() < 0.6))
	{
		return;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int health = GetEventInt(event, "health");

	if (!IsPlayerHere(client) || !IsPlayerAllowed(client))
	{
		return;
	}

	if (health < 66)
	{
		switch (GetRandomUInt(0, 1))
		{
			case 0:
			{
				ScheduleVoiceCommand(client, VC_MEDIC);
			}
			case 1:
			{
				ScheduleVoiceCommand(client, VC_HELP);
			}
		}
	}
	else if (health >= 66)
	{
		int weaponId = GetEventInt(event, "weaponid");
		int dmgamount = GetEventInt(event, "damageamount");
		char selectedOption[5] = VC_BATTLECRY;

		if ((weaponId == TF_WEAPON_SENTRY_BULLET) || (weaponId == TF_WEAPON_SENTRY_ROCKET) || (weaponId == TF_WEAPON_WRENCH))
		{
			selectedOption = VC_SENTRYAHEAD;
		}
		else if(dmgamount > 65)
		{
			selectedOption = VC_NICESHOT;
		}

		switch (GetRandomUInt(0, 2))
		{
			case 0:
			{
				ScheduleVoiceCommand(client, VC_JEERS);
			}
			case 1:
			{
				ScheduleVoiceCommand(client, VC_NEGATIVE);
			}
			case 2:
			{
				ScheduleVoiceCommand(client, selectedOption);
			}
		}
	}

	return;
}

public void player_death(Handle event, const char[] ename, bool dontBroadcast)
{
	if (!g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported) || (GetURandomFloat() < 0.6))
	{
		return;
	}

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!IsPlayerHere(attacker) || !IsPlayerAllowed(attacker))
	{
		return;
	}

	switch (GetRandomUInt(0, 4))
	{
		case 0:
		{
			ScheduleVoiceCommand(attacker, VC_CHEERS, _, KILL_CHATTER_DELAY);
		}
		case 1:
		{
			ScheduleVoiceCommand(attacker, VC_POSITIVE, _, KILL_CHATTER_DELAY);
		}
		case 2:
		{
			ScheduleVoiceCommand(attacker, VC_NICESHOT, _, KILL_CHATTER_DELAY);
		}
		case 3:
		{
			ScheduleVoiceCommand(attacker, VC_GOODJOB, _, KILL_CHATTER_DELAY);
		}
		case 4:
		{
			ScheduleVoiceCommand(attacker, VC_THANKS, _, KILL_CHATTER_DELAY);
		}
	}

	return;
}

public void player_upgradedobject(Handle event, const char[] name, bool dontBroadcast)
{
	if (!g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported) || (GetURandomFloat() < 0.7))
	{
		return;
	}

	int building = GetEventInt(event,"index");
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	int buildingType = GetEntProp(building, Prop_Send, "m_iObjectType");

	if (!IsPlayerHere(client) || !IsPlayerAllowed(client))
	{
		return;
	}

	switch (buildingType)
	{
		case view_as<int>(TFObject_Sentry):
		{
			ScheduleVoiceCommand(client, VC_SENTRYHERE, _, BUILDING_UPGRADE_CHATTER_DELAY);
		}
		case view_as<int>(TFObject_Teleporter):
		{
			ScheduleVoiceCommand(client, VC_TELEPORTERHERE, _, BUILDING_UPGRADE_CHATTER_DELAY);
		}
		case view_as<int>(TFObject_Dispenser):
		{
			ScheduleVoiceCommand(client, VC_DISPENSERHERE, _, BUILDING_UPGRADE_CHATTER_DELAY);
		}
	}
}

public void teamplay_flag_event(Handle event, const char[] name, bool dontBroadcast)
{
	if (!g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported) || (GetURandomFloat() < 0.7))
	{
		return;
	}

	int player = GetEventInt(event,"player");
	int eventType = GetEventInt(event,"eventtype");

	if (!IsPlayerHere(player) || !IsPlayerAllowed(player))
	{
		return;
	}

	switch (eventType)
	{
		case view_as<int>(TF_FLAGEVENT_PICKEDUP):
		{
			ScheduleVoiceCommand(player, VC_HELP, _, FLAG_EVENT_CHATTER_DELAY);
		}
		case view_as<int>(TF_FLAGEVENT_DEFENDED):
		{
			ScheduleVoiceCommand(player, VC_GOGOGO, _, FLAG_EVENT_CHATTER_DELAY);
		}
		case view_as<int>(TF_FLAGEVENT_DROPPED):
		{
			ScheduleVoiceCommand(player, VC_NEGATIVE, _, FLAG_EVENT_CHATTER_DELAY);
		}
	}
}

public void player_chargedeployed(Handle event, const char[] ename, bool dontBroadcast)
{
	if (!g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported))
	{
		return;
	}

	int userid = GetEventInt(event, "userid");
	int medic = GetClientOfUserId(userid);
	int targetid = GetEventInt(event, "targetid");
	int target = GetClientOfUserId(targetid);

	if ((GetURandomFloat() < 0.7) && IsPlayerHere(medic) && IsPlayerAllowed(medic))
	{
		ScheduleVoiceCommand(medic, VC_UBERREADY);
	}

	if ((GetURandomFloat() < 0.7) && IsPlayerHere(target) && IsPlayerAllowed(target))
	{
		ScheduleVoiceCommand(target, VC_ACTIVATEUBER);
	}
}

public void teamplay_capture_blocked(Handle event, const char[] ename, bool dontBroadcast)
{
	if (!g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported) || (GetURandomFloat() < 0.7))
	{
		return;
	}

	int blocker = GetEventInt(event, "blocker");

	if (IsPlayerHere(blocker) && IsPlayerAllowed(blocker))
	{
		switch (GetRandomUInt(0, 2))
		{
			case 0:
			{
				ScheduleVoiceCommand(blocker, VC_NO, _, POINT_CAPTURE_CHATTER_DELAY);
			}
			case 1:
			{
				ScheduleVoiceCommand(blocker, VC_HELP, _, POINT_CAPTURE_CHATTER_DELAY);
			}
			case 2:
			{
				ScheduleVoiceCommand(blocker, VC_INCOMING, _, POINT_CAPTURE_CHATTER_DELAY);
			}
		}
	}
}

public void teamplay_point_startcapture(Handle event, const char[] ename, bool dontBroadcast)
{
	if (!g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported))
	{
		return;
	}

	char cappers[MAXPLAYERS+1];
	GetEventString(event, "cappers", cappers, sizeof(cappers));

	for (int client = 0; client < sizeof(cappers); client++)
	{
		if ((GetURandomFloat() < 0.6) && IsPlayerHere(cappers[client]) && IsPlayerAllowed(cappers[client]))
		{
			ScheduleVoiceCommand(cappers[client], VC_HELP, _, POINT_CAPTURE_CHATTER_DELAY);
		}
	}
}

public void ScheduleTeamResponse(int team, bool positive)
{
	if (!g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported) || (team < RED_TEAM))
	{
		return;
	}

	for (int client = 1; client < MaxClients; client++)
	{
		if ((GetURandomFloat() < 0.6) || !IsPlayerHere(client) || !IsPlayerAllowed(client) || (GetClientTeam(client) != team))
		{
			continue;
		}

		if (positive)
		{
			switch (GetRandomUInt(0, 3))
			{
				case 0:
				{
					ScheduleVoiceCommand(client, VC_CHEERS, _, TEAM_CHATTER_DELAY);
				}
				case 1:
				{
					ScheduleVoiceCommand(client, VC_POSITIVE, _, TEAM_CHATTER_DELAY);
				}
				case 2:
				{
					ScheduleVoiceCommand(client, VC_BATTLECRY, _, TEAM_CHATTER_DELAY);
				}
				case 3:
				{
					ScheduleVoiceCommand(client, VC_GOODJOB, _, TEAM_CHATTER_DELAY);
				}
			}
		}
		else
		{
			switch (GetRandomUInt(0, 3))
			{
				case 0:
				{
					ScheduleVoiceCommand(client, VC_JEERS, _, TEAM_CHATTER_DELAY);
				}
				case 1:
				{
					ScheduleVoiceCommand(client, VC_NEGATIVE, _, TEAM_CHATTER_DELAY);
				}
				case 2:
				{
					ScheduleVoiceCommand(client, VC_INCOMING, _, TEAM_CHATTER_DELAY);
				}
				case 3:
				{
					ScheduleVoiceCommand(client, VC_HELP, _, TEAM_CHATTER_DELAY);
				}
			}
		}
	}

	return;
}

public void player_spawn(Handle event, const char[] ename, bool dontBroadcast)
{
	if (!g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported) || !g_bCVIdleChatter)
	{
		return;
	}

	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	delete g_hIdleVoiceTriggerTimer[client];

	if (!IsPlayerHere(client) || !IsPlayerAllowed(client))
	{
		return;
	}

	CreateTimer(GetRandomFloat(0.1, 2.0), Timer_TriggerSpawnVoiceCommand, userid, TIMER_FLAG_NO_MAPCHANGE);
	g_hIdleVoiceTriggerTimer[client] = CreateTimer(8.0+(GetRandomFloat(0.1, 3.0)), Timer_TriggerIdleVoiceCommand, userid, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public Action Timer_TriggerSpawnVoiceCommand(Handle timer, any data)
{
	int client = GetClientOfUserId(data);

	if (!g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported) || !IsPlayerHere(client) || !IsPlayerAllowed(client) || g_bRoundEnd || !g_bCVIdleChatter || (GetURandomFloat() > 0.4))
	{
		return Plugin_Stop;
	}

	switch (GetRandomUInt(0, 14))
	{
		case 0:
		{
			ScheduleVoiceCommand(client, VC_GOGOGO, _, IDLE_CHATTER_DELAY);
		}
		case 1:
		{
			ScheduleVoiceCommand(client, VC_MOVEUP, _, IDLE_CHATTER_DELAY);
		}
		case 2:
		{
			ScheduleVoiceCommand(client, VC_GOLEFT, _, IDLE_CHATTER_DELAY);
		}
		case 3:
		{
			ScheduleVoiceCommand(client, VC_GORIGHT, _, IDLE_CHATTER_DELAY);
		}
		case 4:
		{
			ScheduleVoiceCommand(client, VC_INCOMING, _, IDLE_CHATTER_DELAY);
		}
		case 5:
		{
			ScheduleVoiceCommand(client, VC_TELEPORTERHERE, _, IDLE_CHATTER_DELAY);
		}
		case 6:
		{
			ScheduleVoiceCommand(client, VC_DISPENSERHERE, _, IDLE_CHATTER_DELAY);
		}
		case 7:
		{
			ScheduleVoiceCommand(client, VC_SENTRYHERE, _, IDLE_CHATTER_DELAY);
		}
		case 8:
		{
			ScheduleVoiceCommand(client, VC_BATTLECRY, _, IDLE_CHATTER_DELAY);
		}
		case 9:
		{
			ScheduleVoiceCommand(client, VC_CHEERS, _, IDLE_CHATTER_DELAY);
		}
		case 10:
		{
			ScheduleVoiceCommand(client, VC_JEERS, _, IDLE_CHATTER_DELAY);
		}
		case 11:
		{
			ScheduleVoiceCommand(client, VC_POSITIVE, _, IDLE_CHATTER_DELAY);
		}
		case 12:
		{
			ScheduleVoiceCommand(client, VC_NEGATIVE, _, IDLE_CHATTER_DELAY);
		}
		case 13:
		{
			ScheduleVoiceCommand(client, VC_MEDIC, _, IDLE_CHATTER_DELAY);
		}
		case 14:
		{
			ScheduleVoiceCommand(client, VC_ACTIVATEUBER, _, IDLE_CHATTER_DELAY);
		}
	}

	return Plugin_Continue;
}

public Action Timer_TriggerIdleVoiceCommand(Handle timer, any data)
{
	int client = GetClientOfUserId(data);

	if ((g_hIdleVoiceTriggerTimer[client] == null) || !g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported) || !IsPlayerHere(client) || !g_bCVIdleChatter)
	{
		g_hIdleVoiceTriggerTimer[client] = null;
		return Plugin_Stop;
	}
	else if (!IsPlayerAllowed(client) || g_bRoundEnd || (GetURandomFloat() < 0.6))
	{
		return Plugin_Continue;
	}

	switch (GetRandomUInt(0, 23))
	{
		case 0:
		{
			ScheduleVoiceCommand(client, VC_GOGOGO, _, IDLE_CHATTER_DELAY);
		}
		case 1:
		{
			ScheduleVoiceCommand(client, VC_MOVEUP, _, IDLE_CHATTER_DELAY);
		}
		case 2:
		{
			ScheduleVoiceCommand(client, VC_GOLEFT, _, IDLE_CHATTER_DELAY);
		}
		case 3:
		{
			ScheduleVoiceCommand(client, VC_GORIGHT, _, IDLE_CHATTER_DELAY);
		}
		case 4:
		{
			ScheduleVoiceCommand(client, VC_YES, _, IDLE_CHATTER_DELAY);
		}
		case 5:
		{
			ScheduleVoiceCommand(client, VC_NO, _, IDLE_CHATTER_DELAY);
		}
		case 6:
		{
			ScheduleVoiceCommand(client, VC_PASSTOME, _, IDLE_CHATTER_DELAY);
		}
		case 7:
		{
			ScheduleVoiceCommand(client, VC_INCOMING, _, IDLE_CHATTER_DELAY);
		}
		case 8:
		{
			ScheduleVoiceCommand(client, VC_SPY, _, IDLE_CHATTER_DELAY);
		}
		case 9:
		{
			ScheduleVoiceCommand(client, VC_TELEPORTERHERE, _, IDLE_CHATTER_DELAY);
		}
		case 10:
		{
			ScheduleVoiceCommand(client, VC_DISPENSERHERE, _, IDLE_CHATTER_DELAY);
		}
		case 11:
		{
			ScheduleVoiceCommand(client, VC_SENTRYHERE, _, IDLE_CHATTER_DELAY);
		}
		case 12:
		{
			ScheduleVoiceCommand(client, VC_PASSTOME2, _, IDLE_CHATTER_DELAY);
		}
		case 13:
		{
			ScheduleVoiceCommand(client, VC_BATTLECRY, _, IDLE_CHATTER_DELAY);
		}
		case 14:
		{
			ScheduleVoiceCommand(client, VC_CHEERS, _, IDLE_CHATTER_DELAY);
		}
		case 15:
		{
			ScheduleVoiceCommand(client, VC_JEERS, _, IDLE_CHATTER_DELAY);
		}
		case 16:
		{
			ScheduleVoiceCommand(client, VC_POSITIVE, _, IDLE_CHATTER_DELAY);
		}
		case 17:
		{
			ScheduleVoiceCommand(client, VC_NEGATIVE, _, IDLE_CHATTER_DELAY);
		}
		case 18:
		{
			ScheduleVoiceCommand(client, VC_MEDIC, _, IDLE_CHATTER_DELAY);
		}
		case 19:
		{
			ScheduleVoiceCommand(client, VC_GOODJOB, _, IDLE_CHATTER_DELAY);
		}
		case 20:
		{
			ScheduleVoiceCommand(client, VC_THANKS, _, IDLE_CHATTER_DELAY);
		}
		case 21:
		{
			ScheduleVoiceCommand(client, VC_ACTIVATEUBER, _, IDLE_CHATTER_DELAY);
		}
		case 22:
		{
			ScheduleVoiceCommand(client, VC_SENTRYAHEAD, _, IDLE_CHATTER_DELAY);
		}
		case 23:
		{
			ScheduleVoiceCommand(client, VC_NICESHOT, _, IDLE_CHATTER_DELAY);
		}
	}

	return Plugin_Continue;
}

public void teamplay_round_start(Handle event, const char[] name, bool dontBroadcast)
{
	g_bRoundEnd = false;
}

public void teamplay_round_win(Handle event, const char[] name, bool dontBroadcast)
{
	g_bRoundEnd = true;
	int winningteam = GetEventInt(event,"team");
	ScheduleTeamResponse(winningteam, true);
	int losingteam = winningteam == RED_TEAM ? BLU_TEAM : RED_TEAM;
	ScheduleTeamResponse(losingteam, false);
}

void ScheduleVoiceCommand(int client, const char[] option, float baseDelay = 0.0, float randomizedDelay = 0.0)
{
	if (null != g_hVoiceTriggerTimer[client])
	{
		return;
	}

	float cvdelay = baseDelay;

	if (randomizedDelay > 0.1)
	{
		cvdelay += GetRandomUFloat(0.1, randomizedDelay);
	}

	int userid = GetClientUserId(client);
	DataPack pack;
	g_hVoiceTriggerTimer[client] = CreateDataTimer(cvdelay, Timer_VoiceCommand, pack, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(pack, userid);
	WritePackString(pack, option);
	ResetPack(pack, false);
}

public Action Timer_VoiceCommand(Handle timer, any data)
{
	int client = GetClientOfUserId(ReadPackCell(data));
	g_hVoiceTriggerTimer[client] = null;

	if (!g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported) || !IsPlayerHere(client) || !IsPlayerAllowed(client))
	{
		return Plugin_Stop;
	}

	char option[5];
	ReadPackString(data, option, 5);
	FakeClientCommand(client, "voicemenu %s", option);
	return Plugin_Continue;
}

bool IsPlayerHere(int client)
{
	return (client && IsClientInGame(client) && IsFakeClient(client) && !IsClientReplay(client) && !IsClientSourceTV(client) && IsPlayerAlive(client));
}

bool IsPlayerAllowed(int client)
{
	return ((g_iCVTeam == BOTH_TEAMS) || (GetClientTeam(client) == g_iCVTeam) ? true : false);
}

int GetRandomUInt(int min, int max)
{
	return (RoundToFloor(GetURandomFloat() * (max - min + 1)) + min);
}

float GetRandomUFloat(float min, float max)
{
	return ((GetURandomFloat() * (max - min + 0.01)) + min);
}