#include <sourcemod>
#include <tf2>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

ConVar g_hCVCharAdminFlag;
ConVar g_hCVEnabled;
ConVar g_hCVMode;
ConVar g_hCVWinnersEffect;
ConVar g_hCVLosersEffect;
ConVar g_hCVWinnersEffectDuration;
ConVar g_hCVLosersEffectDuration;

bool   g_bIsPlayerImmune[MAXPLAYERS + 1];
bool   g_bRoundEnd					   = false;
bool   g_bLateLoad					   = false;

int	   g_iLastWinningTeam			   = -1;
int	   g_iCurrentWinnersEffect		   = -1;
int	   g_iCurrentLosersEffect		   = -1;
float  g_fCurrentWinnersEffectDuration = 0.0;
float  g_fCurrentLosersEffectDuration  = 0.0;
int	   g_iCurrentMode				   = -1;

char   g_sCharAdminFlag[1];

float  g_fMax = 340282346638528859811704183484516925440.0;

public Plugin myinfo =
{
	name		= "Bonus Round Player Effects",
	author		= "luki1412",
	description = "Gives players effects during bonus rounds",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/member.php?u=43109"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}

	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVar hCVversioncvar	   = CreateConVar("sm_brpe_version", PLUGIN_VERSION, "Bonus Round Immunity Extended version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hCVEnabled			   = CreateConVar("sm_brpe_enabled", "1", "Enable/Disable Admin immunity during bonus round");
	g_hCVCharAdminFlag		   = CreateConVar("sm_brpe_adminflag", "o", "Admin flag to use for immunity (only one). Must be in char format. Default: o");
	g_hCVMode				   = CreateConVar("sm_brpe_mode", "0", "0 - effects are applied to everybody. 1 - only to players with the admin flag. 2 - to all winners plus losers with the admin flag. 3 - to all losers plus winners with the admin flag. Default: 0", FCVAR_NONE, true, 0.0, true, 3.0);
	g_hCVWinnersEffect		   = CreateConVar("sm_brpe_winners_effect", "52", "Condition from TFCond enum - applied to the players on the winning team. 0 - do nothing. Default: 52", FCVAR_NONE, true, 0.0, true, 999.0);
	g_hCVLosersEffect		   = CreateConVar("sm_brpe_losers_effect", "24", "Condition from TFCond enum - applied to the players on the losing team. 0 - do nothing. Default: 24", FCVAR_NONE, true, 0.0, true, 999.0);
	g_hCVWinnersEffectDuration = CreateConVar("sm_brpe_winners_effect_duration", "0", "Duration of the effect, applied to the players on the winning team. 0 - max duration. Default: 0", FCVAR_NONE, true, 0.0, true, g_fMax);
	g_hCVLosersEffectDuration  = CreateConVar("sm_brpe_losers_effect_duration", "0", "Duration of the effect, applied to the players on the losing team. 0 - max duration. Default: 0", FCVAR_NONE, true, 0.0, true, g_fMax);
	HookConVarChange(g_hCVEnabled, EnabledChanged);
	SetConVarString(hCVversioncvar, PLUGIN_VERSION);
	AutoExecConfig(true, "Bonus_Round_Player_Effects");

	if (g_bLateLoad)
	{
		OnConfigsExecuted();
	}

	EnabledChanged(g_hCVEnabled, "", "");
}

public void OnPluginEnd()
{
	ResetAllPlayers();
}

public void OnConfigsExecuted()
{
	UpdateRoundVariables();
}

public void OnClientDisconnect(int client)
{
	g_bIsPlayerImmune[client] = false;
}

void UpdateRoundVariables()
{
	GetConVarString(g_hCVCharAdminFlag, g_sCharAdminFlag, sizeof(g_sCharAdminFlag));
	g_iCurrentWinnersEffect			= GetConVarInt(g_hCVWinnersEffect);
	g_iCurrentLosersEffect			= GetConVarInt(g_hCVLosersEffect);
	g_iCurrentMode					= GetConVarInt(g_hCVMode);
	g_fCurrentWinnersEffectDuration = GetConVarFloat(g_hCVWinnersEffectDuration);
	g_fCurrentLosersEffectDuration	= GetConVarFloat(g_hCVLosersEffectDuration);
}

public void HookRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_bRoundEnd		   = false;
	g_iLastWinningTeam = -1;
	ResetAllPlayers();
	UpdateRoundVariables();
}

public void HookRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	g_bRoundEnd		   = true;
	g_iLastWinningTeam = GetEventInt(event, "team");

	if (!GetConVarBool(g_hCVEnabled))
	{
		return;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			EnforceModeOnClient(i, GetClientTeam(i));
		}
	}
}

public void HookPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(g_hCVEnabled))
	{
		return;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_bRoundEnd)
	{
		EnforceModeOnClient(client, GetEventInt(event, "team"));
	}
}

void EnforceModeOnClient(int client, int team)
{
	bool winner = (team == g_iLastWinningTeam) ? true : false;

	switch (g_iCurrentMode)
	{
		case 0:
		{
			SetImmune(client, winner);
		}
		case 1:
		{
			if (IsValidAdmin(client, g_sCharAdminFlag))
			{
				SetImmune(client, winner);
			}
		}
		case 2:
		{
			if (winner)
			{
				SetImmune(client, winner);
			}
			else if (IsValidAdmin(client, g_sCharAdminFlag))
			{
				SetImmune(client, winner);
			}
		}
		case 3:
		{
			if (!winner)
			{
				SetImmune(client, winner);
			}
			else if (IsValidAdmin(client, g_sCharAdminFlag))
			{
				SetImmune(client, winner);
			}
		}
	}
}

void SetNormal(int client)
{
	g_bIsPlayerImmune[client] = false;
	TF2_RemoveCondition(client, view_as<TFCond>(g_iCurrentWinnersEffect));
	TF2_RemoveCondition(client, view_as<TFCond>(g_iCurrentLosersEffect));
}

void SetImmune(int client, bool winner)
{
	g_bIsPlayerImmune[client] = true;
	int	  effect			  = 0;
	float duration			  = 0.0;

	if (winner)
	{
		effect	 = g_iCurrentWinnersEffect;
		duration = g_fCurrentWinnersEffectDuration;
	}
	else {
		effect	 = g_iCurrentLosersEffect;
		duration = g_fCurrentLosersEffectDuration;
	}

	if (duration == 0.0)
	{
		duration = g_fMax;
	}

	if (effect != 0)
	{
		TF2_AddCondition(client, view_as<TFCond>(effect), duration, 0);
	}
}

void ResetAllPlayers()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_bIsPlayerImmune[i] && IsClientInGame(i))
		{
			SetNormal(i);
		}

		g_bIsPlayerImmune[i] = false;
	}
}

public void EnabledChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(g_hCVEnabled) == false)
	{
		UnhookEvent("player_spawn", HookPlayerSpawn);
		UnhookEvent("teamplay_round_start", HookRoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("teamplay_round_win", HookRoundEnd);
		ResetAllPlayers();
	}
	else
	{
		HookEvent("player_spawn", HookPlayerSpawn);
		HookEvent("teamplay_round_start", HookRoundStart, EventHookMode_PostNoCopy);
		HookEvent("teamplay_round_win", HookRoundEnd);
	}
}

bool IsValidAdmin(int client, const char[] flags)
{
	if (IsFakeClient(client))
	{
		return false;
	}

	int ibFlags = ReadFlagString(flags);
	if ((GetUserFlagBits(client) & ibFlags) == ibFlags)
	{
		return true;
	}

	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}

	return false;
}