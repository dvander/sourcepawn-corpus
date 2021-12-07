#include <sourcemod>
#include <sdktools>
#include <tf2>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.2"

ConVar g_cvFF; // Friendly fire cvar
ConVar g_cvEnable;

public Plugin myinfo = 
{
	name = "[TF2] Crits on stalemate for all", 
	author = "Meten & Sreap", 
	description = "Takes away the stun and enables crits for everyone on a stalemate.", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/matthiasmeten/random-plugins"
}

public void OnPluginStart()
{
	HookEvent("teamplay_round_win", OnTFRoundWin, EventHookMode_Post);
	HookEvent("teamplay_round_start", OnTFRoundStart, EventHookMode_PostNoCopy);
	
	g_cvFF = FindConVar("mp_friendlyfire");
	g_cvEnable = CreateConVar("sm_stalemateff_enable", "1", "Enable Friendly Fire on round end. 1 = enabled.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	CreateConVar("sm_stalematecrits_version", PLUGIN_VERSION, "Plugin Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	
}

public void OnTFRoundWin(Event event, const char[] name, bool dontBroadcast)
{
	if (GetEventInt(event, "winreason") == 5)
	{
		GameRules_SetProp("m_iRoundState", RoundState_RoundRunning); //Thanks Timely
		
		if (g_cvEnable.BoolValue)
		{
			g_cvFF.SetBool(true);
			PrintToChatAll("\x07FFA500Friendly Fire\x01 has been enabled!");
			PrintCenterTextAll("Friendly Fire has been enabled!");
		}
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				int team = GetClientTeam(i);
				if (!IsPlayerAlive(i) && (team == 2 || team == 3))
				{
					TF2_RespawnPlayer(i);
				}
				//				TF2_RemoveCondition(i, TFCond_Ubercharged);
				TF2_AddCondition(i, TFCond_CritOnFirstBlood, TFCondDuration_Infinite, 0);
			}
		}
	}
}


public void OnTFRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// Prevents a bizzare glitch from occuring when a team wins normally and fixes no announcer voice.
	GameRules_SetProp("m_iRoundState", RoundState_Preround);
} 