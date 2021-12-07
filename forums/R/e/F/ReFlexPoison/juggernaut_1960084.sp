#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <morecolors>
#include <juggernaut>

// ====[ DEFINES ]=============================================================
#define PLUGIN_NAME					"Juggernaut (1 vs All)"
#define PLUGIN_VERSION				"1.6"

// ====[ HANDLES | CVARS ]=====================================================
new Handle:g_hCvarEnabled,			bool:g_bCvarEnabled;
new Handle:g_hCvarChance,			Float:g_fCvarChance;
new Handle:g_hCvarHealth,			g_iCvarHealth;
new Handle:g_hCvarShowHealth,		bool:g_bCvarShowHealth;
new Handle:g_hCvarVoteRatio,		Float:g_fCvarVoteRatio;
new Handle:g_hCvarVoteMinimum,		g_iCvarVoteMinimum;
new Handle:g_hCvarUnbalanceLimit;
new Handle:g_hTimerJuggernautHud;
new Handle:g_hHudSynchronizer;

// ====[ VARIABLES ]===========================================================
new g_iJuggernaut;
new g_iNextJuggernaut;
new g_iDamage						[MAXPLAYERS + 1];
new bool:g_bNextRoundJuggernaut;
new bool:g_JuggernautRoundStarted;
new bool:g_bVotedForJuggernaut		[MAXPLAYERS + 1];

// ====[ PLUGIN ]==============================================================
public APLRes:AskPluginLoad2(Handle:hPlugin, bool:bLateLoad, String:strError[], iErrorSize)
{
	CreateNative("GetJuggernautUserId", Native_JuggernautUserId);
	RegPluginLibrary("juggernaut");
	return APLRes_Success;
}

// ====[ NATIVES ]=============================================================
public Native_JuggernautUserId(Handle:hPlugin, iParams)
{
	if(IsValidClient(g_iJuggernaut))
		return GetClientUserId(g_iJuggernaut);
	return -1;
}

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "ReFlexPoison",
	description = "New JUGGERNAUT!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

// ====[ EVENTS ]==============================================================
public OnPluginStart()
{
	CreateConVar("sm_juggernaut_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_hCvarEnabled = CreateConVar("sm_juggernaut_enabled", "1", "Enable Juggernaut", _, true, 0.0, true, 1.0);
	g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);

	g_hCvarChance = CreateConVar("sm_juggernaut_chance", "0.1", "Percent chance of random Juggernaut round", _, true, 0.0, true, 1.0);
	g_fCvarChance = GetConVarFloat(g_hCvarChance);
	HookConVarChange(g_hCvarChance, OnConVarChange);

	g_hCvarVoteRatio = CreateConVar("sm_juggernaut_voteratio", "0.6", "Ratio of players who need to vote for Juggernaut round\n0 = Disabled", _, true, 0.0, true, 1.0);
	g_fCvarVoteRatio = GetConVarFloat(g_hCvarVoteRatio);
	HookConVarChange(g_hCvarVoteRatio, OnConVarChange);

	g_hCvarVoteMinimum = CreateConVar("sm_juggernaut_voteminimum", "4", "Minimum amount of players required to vote for Juggernaut round\n0 = None", _, true, 0.0);
	g_iCvarVoteMinimum = GetConVarInt(g_hCvarVoteMinimum);
	HookConVarChange(g_hCvarVoteMinimum, OnConVarChange);

	g_hCvarHealth = CreateConVar("sm_juggernaut_health", "550", "Amount of HP the Juggernaut gets per player", _, true, 1.0);
	g_iCvarHealth = GetConVarInt(g_hCvarHealth);
	HookConVarChange(g_hCvarHealth, OnConVarChange);

	g_hCvarShowHealth = CreateConVar("sm_juggernaut_showhealth", "1", "Show health of Juggernaut in HUD?\n0 = No\n1 = Yes", _, true, 0.0, true, 0.0);
	g_bCvarShowHealth = GetConVarBool(g_hCvarShowHealth);
	HookConVarChange(g_hCvarShowHealth, OnConVarChange);

	g_hCvarUnbalanceLimit = FindConVar("mp_teams_unbalance_limit");

	AutoExecConfig(true, "plugin.juggernaut");

	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("arena_round_start", OnArenaStart);
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("player_hurt", OnPlayerHurt);

	RegAdminCmd("sm_juggernaut", JuggernautCmd, ADMFLAG_GENERIC);
	RegAdminCmd("sm_votejuggernaut", VoteJuggernautCmd, 0);
	AddCommandListener(JointeamCmd, "jointeam");

	LoadTranslations("common.phrases");
	LoadTranslations("juggernaut.phrases");

	g_hHudSynchronizer = CreateHudSynchronizer();
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == g_hCvarEnabled)
		g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
	else if(hConvar == g_hCvarHealth)
		g_iCvarHealth = GetConVarInt(g_hCvarHealth);
	else if(hConvar == g_hCvarShowHealth)
		g_bCvarShowHealth = GetConVarBool(g_hCvarShowHealth);
	else if(hConvar == g_hCvarChance)
		g_fCvarChance = GetConVarFloat(g_hCvarChance);
	else if(hConvar == g_hCvarVoteRatio)
		g_fCvarVoteRatio = GetConVarFloat(g_hCvarVoteRatio);
	else if(hConvar == g_hCvarVoteMinimum)
		g_iCvarVoteMinimum = GetConVarInt(g_hCvarVoteMinimum);
}

public OnMapStart()
{
	g_JuggernautRoundStarted = false;
	g_bNextRoundJuggernaut = false;
	g_iJuggernaut = 0;
	g_iNextJuggernaut = 0;
	ClearTimer(g_hTimerJuggernautHud);
}

public OnClientConnected(iClient)
{
	g_iDamage[iClient] = 0;
	g_bVotedForJuggernaut[iClient] = false;
}

public OnClientDisconnect_Post(iClient)
{
	if(iClient == g_iJuggernaut)
	{
		g_iJuggernaut = 0;
		g_JuggernautRoundStarted = false;
		ServerCommand("mp_scrambleteams");
	}

	g_bVotedForJuggernaut[iClient] = false;

	if(g_bCvarEnabled && g_fCvarVoteRatio > 0 && !g_bNextRoundJuggernaut)
	{
		new iVoteCount = GetJuggernautVoteCount();
		new iRatio = RoundToNearest((GetValidTeamClientCount(2) + GetValidTeamClientCount(3)) * g_fCvarVoteRatio);

		if(iVoteCount >= iRatio && iVoteCount >= g_iCvarVoteMinimum)
		{
			g_bNextRoundJuggernaut = true;
			CPrintToChatAll("\x05[SM]\x01 %T", "NextRound", LANG_SERVER);

			for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
				g_bVotedForJuggernaut[iClient] = false;
		}
	}
}

public Action:OnRoundStart(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	ClearTimer(g_hTimerJuggernautHud);
	g_JuggernautRoundStarted = false;

	if(!g_bCvarEnabled)
		return;

	if(g_bNextRoundJuggernaut)
	{
		g_bNextRoundJuggernaut = false;

		new iNextJuggernaut;
		if(IsValidClient(g_iNextJuggernaut) && GetClientTeam(g_iNextJuggernaut) > 1)
		{
			iNextJuggernaut = g_iNextJuggernaut;
			g_iNextJuggernaut = 0;
		}
		else
			iNextJuggernaut = GetRandomPlayer();

		if(IsValidClient(iNextJuggernaut))
		{
			for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
			{
				if(GetClientTeam(i) > 1)
				{
					if(i != iNextJuggernaut)
						SetClientTeam(i, 2);
					else
						SetClientTeam(i, 3);
				}
			}

			g_JuggernautRoundStarted = true;
			g_iJuggernaut = iNextJuggernaut;
			CPrintToChatAll("\x05[SM]\x01 %T", "RoundStart", LANG_SERVER, g_iJuggernaut);
			SetConVarInt(g_hCvarUnbalanceLimit, 0);
		}
	}
	else
		SetConVarInt(g_hCvarUnbalanceLimit, 1);

	if(!g_bNextRoundJuggernaut && g_fCvarChance >= GetRandomFloat(0.0, 1.0))
	{
		g_bNextRoundJuggernaut = true;
		CPrintToChatAll("\x05[SM]\x01 %T", "NextRound", LANG_SERVER);
	}
}

public Action:OnArenaStart(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	ClearTimer(g_hTimerJuggernautHud);
	g_hTimerJuggernautHud = CreateTimer(1.0, Timer_JuggernautHud, _, TIMER_REPEAT);

	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(GetClientTeam(i) > 1 && i == g_iJuggernaut)
			SetEntityHealth(i, g_iCvarHealth * GetValidTeamClientCount(2));
	}
}

public Action:OnPlayerHurt(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!IsValidClient(iVictim) || !IsValidClient(iAttacker))
		return;

	if(iVictim == g_iJuggernaut && iAttacker != g_iJuggernaut)
		g_iDamage[iAttacker] += GetEventInt(hEvent, "damageamount");
}

public Action:OnRoundEnd(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	ClearTimer(g_hTimerJuggernautHud);
	g_JuggernautRoundStarted = false;

	if(!IsValidClient(g_iJuggernaut))
		return;

	CPrintToChatAll("\x05[SM]\x01 %T", "RoundOver", LANG_SERVER);
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(i != g_iJuggernaut)
		{
			CPrintToChat(i, "\x05[SM]\x01 %T", "DamageDealt", LANG_SERVER, g_iDamage[i]);

			new iPoints = RoundToNearest(g_iDamage[i] / 600.0);
			CPrintToChat(i, "\x05[SM]\x01 %T", "PointsEarned", LANG_SERVER, iPoints);

			new Handle:hCustomEvent = CreateEvent("player_escort_score", true);
			SetEventInt(hCustomEvent, "player", i);
			SetEventInt(hCustomEvent, "points", iPoints);
			FireEvent(hCustomEvent);

			g_iDamage[i] = 0;
		}
	}

	g_iJuggernaut = 0;
	ServerCommand("mp_scrambleteams");
}

// ====[ COMMANDS ]============================================================
public Action:JuggernautCmd(iClient, iArgs)
{
	if(!g_bCvarEnabled)
		return Plugin_Continue;

	if(iArgs == 1)
	{
		g_iNextJuggernaut = 0;

		decl String:strCommand[MAX_NAME_LENGTH];
		GetCmdArgString(strCommand, sizeof(strCommand));

		g_iNextJuggernaut = FindTarget(iClient, strCommand);
		if(IsValidClient(g_iNextJuggernaut) && GetClientTeam(g_iNextJuggernaut) > 1)
		{
			CPrintToChatAll("\x05[SM]\x01 %T", "NextJuggernaut", LANG_SERVER, g_iNextJuggernaut);
			g_bNextRoundJuggernaut = true;
		}
		else
			g_iNextJuggernaut = 0;

		return Plugin_Handled;
	}

	if(!g_bNextRoundJuggernaut)
	{
		g_bNextRoundJuggernaut = true;
		CPrintToChatAll("\x05[SM]\x01 %T", "NextRound", LANG_SERVER);
	}
	else
	{
		g_bNextRoundJuggernaut = false;
		CPrintToChatAll("\x05[SM]\x01 %T", "RoundCancelled", LANG_SERVER);
	}

	return Plugin_Handled;
}

public Action:VoteJuggernautCmd(iClient, iArgs)
{
	if(!g_bCvarEnabled || g_fCvarVoteRatio <= 0)
		return Plugin_Continue;

	if(g_bNextRoundJuggernaut)
	{
		CReplyToCommand(iClient, "\x05[SM]\x01 %T", "NextRound", LANG_SERVER);
		return Plugin_Handled;
	}

	if(!g_bVotedForJuggernaut[iClient])
	{
		g_bVotedForJuggernaut[iClient] = true;

		new iVoteCount = GetJuggernautVoteCount();
		new iRatio = RoundToNearest((GetValidTeamClientCount(2) + GetValidTeamClientCount(3)) * g_fCvarVoteRatio);

		if(iRatio < g_iCvarVoteMinimum)
			iRatio = g_iCvarVoteMinimum;

		CPrintToChatAll("\x05[SM]\x01 %T", "VotedFor", LANG_SERVER, iClient, iVoteCount, iRatio);

		if(iVoteCount >= iRatio)
		{
			g_bNextRoundJuggernaut = true;
			CPrintToChatAll("\x05[SM]\x01 %T", "NextRound", LANG_SERVER);

			for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
				g_bVotedForJuggernaut[i] = false;
		}
	}
	else
		CReplyToCommand(iClient, "\x05[SM]\x01 %T", "AlreadyVoted", LANG_SERVER);

	return Plugin_Handled;
}

public Action:JointeamCmd(iClient, const String:strCmd[], iArgc)
{
	if(!g_JuggernautRoundStarted)
		return Plugin_Continue;

	decl String:strCommand[16];
	GetCmdArgString(strCommand, sizeof(strCommand));

	if(StrEqual(strCommand, "blue", false) || StrEqual(strCommand, "auto", false) || StrEqual(strCommand, "random", false))
		return Plugin_Handled;

	if(StrEqual(strCommand, "red", false) && iClient == g_iJuggernaut)
		return Plugin_Handled;

	return Plugin_Continue;
}

// ====[ TIMERS ]==============================================================
public Action:Timer_JuggernautHud(Handle:hTimer)
{
	if(!g_bCvarShowHealth || !IsValidClient(g_iJuggernaut) || g_hHudSynchronizer == INVALID_HANDLE)
		return;

	SetHudTextParams(0.02, 0.02, 1.0, 255, 255, 255, 255);
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
		ShowSyncHudText(i, g_hHudSynchronizer, "%T", "JugHP", LANG_SERVER, GetClientHealth(g_iJuggernaut));
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	return true;
}

stock GetJuggernautVoteCount()
{
	new iCount;
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(g_bVotedForJuggernaut[i])
			iCount++;
	}
	return iCount;
}

stock GetValidTeamClientCount(iTeam)
{
	new iCount;
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(GetClientTeam(i) == iTeam)
			iCount++;
	}
	return iCount;
}

stock GetRandomPlayer()
{
	new iPlayers[MAXPLAYERS + 1];
	new iCount;
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(GetClientTeam(i) > 1)
			iPlayers[iCount++] = i;
	}
	return (iCount == 0) ? - 1 : iPlayers[GetRandomInt(0, iCount - 1)];
}

stock ClearTimer(&Handle:hTimer)
{
	if(hTimer != INVALID_HANDLE)
	{
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
	}
}

stock SetClientTeam(iClient, iTeam)
{
	SetEntProp(iClient, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(iClient, iTeam);
	TF2_RespawnPlayer(iClient);
}