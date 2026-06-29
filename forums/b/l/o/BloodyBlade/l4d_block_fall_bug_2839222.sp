#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

#define DMG_CLUB (1 << 7)
#define TEAM_SURVIVOR 2

public Plugin myinfo = 
{
	name = "Block Fall Bug",
	author = "DJ_WEST",
	description = "Block the survivor bug with falling on the infected zombies",
	version = PLUGIN_VERSION,
	url = "http://amx-x.ru"
}


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Block Fall Bug supports \"Left 4 Dead\" game series only.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

bool bHooked = false;
int iCvarWarnings = 0, g_Warnings[MAXPLAYERS + 1] = {0, ...};
float fCvarTime = 0.0;
Handle g_ResetTimer[MAXPLAYERS + 1] = {null, ...};
ConVar h_CvarPluginOn, h_CvarWarnings, h_CvarTime;

public void OnPluginStart()
{
	CreateConVar("block_fallbug_version", PLUGIN_VERSION, "Block Fall Bug version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	h_CvarPluginOn = CreateConVar("l4d_fall_bug_enable", "1", "Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	h_CvarWarnings = CreateConVar("l4d_fall_bug_warnings", "3", "Quantity of the player warnings for bug detection", CVAR_FLAGS, true, 0.0, true, 10.0);
	h_CvarTime = CreateConVar("l4d_fall_bug_time", "2.0", "Time for checks warnings of the player", CVAR_FLAGS, true, 0.0, true, 10.0);

	AutoExecConfig(true, "l4d_fall_bug");

	h_CvarPluginOn.AddChangeHook(OnConVarEnableChanged);
	h_CvarWarnings.AddChangeHook(OnConVarsChanged);
	h_CvarTime.AddChangeHook(OnConVarsChanged);

	LoadTranslations("block_fall_bug.phrases");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarEnableChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void OnConVarsChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	iCvarWarnings = h_CvarWarnings.IntValue;
	fCvarTime = h_CvarTime.FloatValue;
}

void IsAllowed()
{
	bool bPluginOn = h_CvarPluginOn.BoolValue;
	if(!bHooked && bPluginOn)
	{
		HookEvent("infected_hurt", EventInfectedHurt);
	}
	else if(bHooked && !bPluginOn)
	{
		UnhookEvent("infected_hurt", EventInfectedHurt);
	}
}

public void OnClientPutInServer(int i_Client)
{
	if (bHooked && i_Client > 0 && !IsFakeClient(i_Client))
	{
		if (g_ResetTimer[i_Client] != null)
		{
			delete g_ResetTimer[i_Client];
		}

		g_Warnings[i_Client] = 0;
	}
}

Action EventInfectedHurt(Event h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	if (h_Event.GetInt("type") & DMG_CLUB)
	{
		int i_Client = 0, i_Ent = 0;
		i_Client = GetClientOfUserId(h_Event.GetInt("attacker"));
		if (i_Client > 0 && IsClientInGame(i_Client) && GetClientTeam(i_Client) == TEAM_SURVIVOR)
		{
			i_Ent = h_Event.GetInt("entityid");
			if (GetEntPropEnt(i_Client, Prop_Data, "m_hGroundEntity") == i_Ent)
			{
				g_Warnings[i_Client]++;

				if (g_ResetTimer[i_Client] == null)
				{
					g_ResetTimer[i_Client] = CreateTimer(fCvarTime, ResetWarnings, i_Client);
				}

				if (g_Warnings[i_Client] > iCvarWarnings)
				{
					char s_PlayerName[MAX_NAME_LENGTH];
					GetClientName(i_Client, s_PlayerName, sizeof(s_PlayerName));
					PrintToChatAll("\x03[%t]\x01 %t.", "Information", "Detected", s_PlayerName);
					ForcePlayerSuicide(i_Client);
					
					g_Warnings[i_Client] = 0;
					
					if (g_ResetTimer[i_Client] != null)
					{
						delete g_ResetTimer[i_Client];
					}	
				}
			}
		}
	}
	return Plugin_Handled;
}

Action ResetWarnings(Handle h_Timer, int i_Client)
{
	g_Warnings[i_Client] = 0;
	g_ResetTimer[i_Client] = null;
	return Plugin_Stop;
}
