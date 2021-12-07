#pragma semicolon 1
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <tf2_stocks>

// ConVars
ConVar g_cvConVars[7];
bool g_cvEnabled, g_cvBots, g_cvHintText, g_cvCenterText, g_cvEndRound, g_cvAdmins;
char g_cvAdminFlags[10];
float g_cvRespawnTime;

// Arrays
ArrayList g_alAdminFlags;

// Booleans
bool g_bRoundActive = true;

// Handles
Handle g_hTimer[MAXPLAYERS+1];

public Plugin myinfo = {
	name 		= "[TF2] Respawn Timer",
	author 		= "Sgt. Gremulock",
	description = "Control the respawn time with custom values.",
	version 	= PLUGIN_VERSION,
	url 		= "grem-co.com"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_TF2) // Stop the plugin from running if the game server is not for TF2.
	{
		SetFailState("This plugin only supports Team Fortress 2.");
	}

	CreateConVar("sm_respawntimer_version", PLUGIN_VERSION, "Plugin's version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvConVars[0] = CreateConVar("sm_respawntimer_enable", "1", "Enable/disable the plugin.\n(1 = Enable, 0 = Disable)", _, true, 0.0, true, 1.0);
	g_cvConVars[1] = CreateConVar("sm_respawntimer_bots", "1", "Enable/disable the respawn timer for bots.\n(1 = Enable, 0 = Disable)", _, true, 0.0, true, 1.0);
	g_cvConVars[2] = CreateConVar("sm_respawntimer_time", "3.0", "Time it should take (in seconds) to respawn a player.", _, true, 0.01);
	g_cvConVars[3] = CreateConVar("sm_respawntimer_hint_text", "0", "Enable/disable displaying the time (with hint text) until the player will respawn.\n(1 = Enable, 0 = Disable)", _, true, 0.0, true, 1.0);
	g_cvConVars[4] = CreateConVar("sm_respawntimer_center_text", "0", "Enable/disable displaying the time (with center text) until the player will respawn.\n(1 = Enable, 0 = Disable)", _, true, 0.0, true, 1.0);
	g_cvConVars[5] = CreateConVar("sm_respawntimer_admin_flags", "", "Restrict the respawn timer to only affect players with certain admin flag(s).\nIf using multiple flags (you can use up to 5), seperate each with a comma (,) and make sure to end with a comma.\nLeave this blank to disable.");
	g_cvConVars[6] = CreateConVar("sm_respawntimer_end_round", "0", "Enable/disable respawning after a round ends.\n(1 = Enable, 0 = Disable)", _, true, 0.0, true, 1.0);

	for (int i = 0; i < sizeof(g_cvConVars); i++)
	{
		g_cvConVars[i].AddChangeHook(ConVar_Update); // Hook ConVar changes.
	}

	AutoExecConfig(true, "respawntimer");

	HookEvent("player_death", Event_PlayerDeath); // Hook the player death event.
	HookEvent("teamplay_round_win", Event_RoundWin); // Hook the round end event.
	HookEvent("teamplay_round_start", Event_RoundStart); // Hook the round start event.

	LoadTranslations("respawntimer.phrases");
}

public void OnConfigsExecuted()
{
	g_cvEnabled 	= g_cvConVars[0].BoolValue;
	g_cvBots 		= g_cvConVars[1].BoolValue;
	g_cvRespawnTime = g_cvConVars[2].FloatValue;
	g_cvHintText 	= g_cvConVars[3].BoolValue;
	g_cvCenterText 	= g_cvConVars[4].BoolValue;
	g_cvConVars[5].GetString(g_cvAdminFlags, sizeof(g_cvAdminFlags));
	g_cvEndRound 	= g_cvConVars[6].BoolValue;

	if (g_cvEnabled && !StrEqual(g_cvAdminFlags, "", false))
	{
		g_cvAdmins 		= true;
		g_alAdminFlags 	= new ArrayList(1);
		AdminFlag g_admAdminFlag;
		char g_sAdminFlags[10];
		strcopy(g_sAdminFlags, sizeof(g_sAdminFlags), g_cvAdminFlags);

		for (int i = 0; i < strlen(g_sAdminFlags); i++)
		{
			if (StrContains(g_sAdminFlags, ",", false) != -1)
			{
				char g_sSplitString[3];

				if (SplitString(g_sAdminFlags, ",", g_sSplitString, sizeof(g_sSplitString)) != -1)
				{
					if (!FindFlagByChar(g_sSplitString[0], g_admAdminFlag))
					{
						LogError("ERROR: Invalid admin flag '%s'. Skipping...", g_sSplitString);
					}
					else
					{
						g_alAdminFlags.PushString(g_sSplitString);
						LogMessage("Added admin flag requirement '%s'.", g_sSplitString);
					}

					Format(g_sSplitString, sizeof(g_sSplitString), "%s,", g_sSplitString);
					ReplaceString(g_sAdminFlags, sizeof(g_sAdminFlags), g_sSplitString, "", false);
				}
			}
			else
			{
				if (!FindFlagByChar(g_cvAdminFlags[0], g_admAdminFlag))
				{
					SetFailState("ERROR: Invalid admin flag '%s'.", g_cvAdminFlags);
				}

				g_alAdminFlags.PushString(g_cvAdminFlags);

				LogMessage("Set required admin flag to '%s'.", g_cvAdminFlags);
			}
		}
	}
	else
	{
		if (g_alAdminFlags != null)
		{
			g_alAdminFlags.Clear();
			g_alAdminFlags = null;
		}

		g_cvAdmins 		= false;
	}
}

public void ConVar_Update(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	OnConfigsExecuted();

	if (!g_cvEnabled)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i, g_cvBots))
			{
				continue;
			}

			OnClientDisconnect(i);
		}
	}
}

/* Client functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

public void OnClientDisconnect(int client)
{
	if (g_hTimer[client] != null)
	{
		KillTimer(g_hTimer[client]);
		g_hTimer[client] = null;
	}
}

/* Events ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvEnabled || (!g_cvEndRound && !g_bRoundActive))
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (IsValidClient(client, g_cvBots) && !(event.GetInt("death_flags") & 32)) // Make sure the client is valid, they didn't fake their death with a dead ringer, etc.
	{
		if (g_cvAdmins) // If admin flags are enabled and the client has one of the flags, create the respawn timer.
		{
			if (DoesClientHaveRequiredFlag(client))
			{
				CreateRespawnTimer(client);
			}

			return; // Idk if this is necessary or not, but just in case ;).
		}
		else // If admin flags are disabled, create the respawn timer for the client regardless.
		{
			CreateRespawnTimer(client);
		}
	}
}

public void Event_RoundWin(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvEnabled || g_cvEndRound)
	{
		return;
	}

	g_bRoundActive = false;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvEnabled || g_cvEndRound)
	{
		return;
	}

	g_bRoundActive = true;
}

/* Timers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

public Action Timer_Respawn(Handle timer, any client)
{
	if (!IsPlayerAlive(client) && TF2_GetClientTeam(client) != TFTeam_Spectator && TF2_GetClientTeam(client) != TFTeam_Unassigned)
	{
		TF2_RespawnPlayer(client);

		if (g_cvHintText)
		{
			PrintHintText(client, "");
		}

		if (g_cvCenterText)
		{
			PrintCenterText(client, "");
		}
	}

	g_hTimer[client] = null;
}

/* Stocks ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

// Check if a client is valid or not.
bool IsValidClient(int client, bool bots)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (!bots && IsFakeClient(client)))
	{
		return false;
	}

	return IsClientInGame(client);
}

// Check if a client has a required admin flag.
bool DoesClientHaveRequiredFlag(int client)
{
	AdminId g_admAdminId = GetUserAdmin(client);

	if (g_admAdminId != INVALID_ADMIN_ID)
	{
		char g_sAdminFlag[1];
		AdminFlag g_admAdminFlag;

		for (int i = 0; i < g_alAdminFlags.Length; i++)
		{
			g_alAdminFlags.GetString(i, g_sAdminFlag, sizeof(g_sAdminFlag));
			FindFlagByChar(g_sAdminFlag[0], g_admAdminFlag);

			if (g_admAdminId.HasFlag(g_admAdminFlag, Access_Effective) || g_admAdminId.HasFlag(Admin_Root, Access_Effective))
			{
				return true;
			}
			else
			{
				continue;
			}
		}
	}

	return false;
}

// Create the respawn timer.
void CreateRespawnTimer(int client)
{
	g_hTimer[client] = CreateTimer(g_cvRespawnTime, Timer_Respawn, client, TIMER_FLAG_NO_MAPCHANGE);

	if (g_cvHintText)
	{
		PrintHintText(client, "%t", "Respawn Text", g_cvRespawnTime);
	}

	if (g_cvCenterText)
	{
		PrintCenterText(client, "%t", "Respawn Text", g_cvRespawnTime);
	}
}