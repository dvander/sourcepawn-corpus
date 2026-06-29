#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.2"
#define CVAR_FLAGS FCVAR_NOTIFY
#define L4D_VOTE_TEAM_ALL	-1
#define L4D2_VOTE_TEAM_ALL	255

public Plugin myinfo =
{
	name = "[L4D & L4D2] Vote Poll Fix",
	author = "raziEiL [disawar1]",
	description = "Changes number of players eligible to vote",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

ConVar hPluginOn;
static bool bHooked = false, g_bVotePoolFixTriggered = false, g_bL4D2Version = false;
static int g_iVoteEntity = INVALID_ENT_REFERENCE, g_iVoteTeamAll = 0;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead: g_bL4D2Version = false;
		case Engine_Left4Dead2: g_bL4D2Version = true;
		default:
		{
			strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
			return APLRes_SilentFailure;
		}
	}

	if (late) VPF_PrepareToFindVoteEnt();

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_votepoll_fix_version", PLUGIN_VERSION, "Vote Poll Fix plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	hPluginOn = CreateConVar("l4d_votepoll_fix_plugin_on", "1", "Plugin On/Off.", CVAR_FLAGS);
	hPluginOn.AddChangeHook(OnConVarChanged_Allow);
	AutoExecConfig(true, "l4d_votepoll_fix");
	AddCommandListener(VPF_cmdh_Vote, "vote");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarChanged_Allow(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = hPluginOn.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		if (!g_bL4D2Version)
		{
			g_iVoteTeamAll = L4D_VOTE_TEAM_ALL;
			HookEvent("vote_started", VPF_ev_VoteStarted, EventHookMode_Pre);
		}
		else
		{
			g_iVoteTeamAll = L4D2_VOTE_TEAM_ALL;
			HookUserMessage(GetUserMessageId("VoteStart"), VPF_mh_OnVoteStart);
		}
		HookEvent("round_start", VPF_ev_RoundStart, EventHookMode_PostNoCopy);
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("round_start", VPF_ev_RoundStart, EventHookMode_PostNoCopy);
	}
}

Action VPF_cmdh_Vote(int client, const char[] command, int argc)
{
	if (g_bVotePoolFixTriggered && GetClientTeam(client) == 1) return Plugin_Handled;
	return Plugin_Continue;
}

Action VPF_ev_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	VPF_PrepareToFindVoteEnt();
	return Plugin_Continue;
}

Action VPF_ev_VoteStarted(Event event, const char[] name, bool dontBroadcast)
{
	VPF_PrepareToFix(event.GetInt("team"), event.GetInt("initiator"));
	return Plugin_Continue;
}

Action VPF_mh_OnVoteStart(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	int team = BfReadByte(bf);
	int client = BfReadByte(bf);
	VPF_PrepareToFix(team, client);
}

void VPF_PrepareToFix(int team, int client)
{
	int iPolls;
	if (IsValidInitiator(client) && IsValidVoteEnt() && IsAnyOneSpectator() && ((team == g_iVoteTeamAll && (iPolls = GetTotalPlayers())) || (iPolls = GetTeammateCount(team))))
	{
		g_bVotePoolFixTriggered = true;
		SetEntProp(g_iVoteEntity, Prop_Send, "m_potentialVotes", iPolls);
	}
	else g_bVotePoolFixTriggered = false;
}

void VPF_PrepareToFindVoteEnt()
{
	if (!IsValidVoteEnt()) CreateTimer(0.5, VPF_t_FindVoteContollerEnt, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action VPF_t_FindVoteContollerEnt(Handle timer)
{
	g_iVoteEntity = EntIndexToEntRef(FindEntityByClassname(-1, "vote_controller"));
	return Plugin_Stop;
}

int GetTotalPlayers()
{
	int players = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) != 1 && !IsFakeClient(i))
		{
			players++;
		}
	}
	return players;
}

int GetTeammateCount(int team)
{
	if (team == 2 || team == 3)
	{
		int teammates = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == team && !IsFakeClient(i))
			{
				teammates++;
			}
		}
		return teammates;
	}
	return 0;
}

bool IsValidInitiator(int index)
{
	return index > 0 && index <= MaxClients && IsClientInGame(index) && GetClientTeam(index) != 1;
}

bool IsValidVoteEnt()
{
	return EntRefToEntIndex(g_iVoteEntity) != INVALID_ENT_REFERENCE;
}

bool IsAnyOneSpectator()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 1 && !IsFakeClient(i))
		{
			return true;
		}
	}
	return false;
}
