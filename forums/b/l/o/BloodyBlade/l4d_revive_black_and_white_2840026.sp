#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

public Plugin myinfo = 
{
    name        = "[L4D] Revive Black and White",
    author      = "BloodyBlade",
    description = "Revive player after capped by SI with Black and White state",
    version     = PLUGIN_VERSION,
    url         = "https://bloodsiworld.ru"
};

ConVar hPluginOn, hIncapCountMax, hNoDeathCheck;
bool bHooked = false;
Handle g_hSDK_CTerrorPlayer_OnRevived = null;

public void OnPluginStart()
{
    CreateConVar("l4d_revive_black_and_white_version", PLUGIN_VERSION, "[L4D] Revive Black and White plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
    hPluginOn = CreateConVar("l4d_revive_black_and_white_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    AutoExecConfig(true, "l4d_revive_black_and_white");
    hPluginOn.AddChangeHook(OnConVarEnableChange);

    hIncapCountMax = FindConVar("survivor_max_incapacitated_count");
    hNoDeathCheck = FindConVar("director_no_death_check");

    GameData hGameData = new GameData("l4d_revive_black_and_white");
    if(hGameData == null)
    {
        SetFailState("Could not find gamedata file at addons/sourcemod/gamedata/l4d_respawn_black_and_white.txt , you FAILED AT INSTALLING");
    }

    StartPrepSDKCall(SDKCall_Player);
    if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnRevived") == false )
    {
        LogError("Failed to find signature: \"CTerrorPlayer::OnRevived\"");
    }
    else
    {
        g_hSDK_CTerrorPlayer_OnRevived = EndPrepSDKCall();
        if(g_hSDK_CTerrorPlayer_OnRevived == null)
        {
            LogError("Failed to create SDKCall: \"CTerrorPlayer::OnRevived\"");
        }
    }
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarEnableChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = hPluginOn.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		HookEvent("player_death",				Event_PlayerDeath);
		HookEvent("player_incapacitated_start",	Event_Capped);
		HookEvent("round_end",					Event_RoundEnd);
		HookEvent("mission_lost",				Event_RoundEnd);
		HookEvent("map_transition",				Event_RoundEnd);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("player_death", 				Event_PlayerDeath);
		UnhookEvent("player_incapacitated_start",	Event_Capped);
		UnhookEvent("round_end",					Event_RoundEnd);
		UnhookEvent("mission_lost",					Event_RoundEnd);
		UnhookEvent("map_transition",				Event_RoundEnd);
	}
}

Action Event_Capped(Event event, const char[] name, bool bDontBroadcast)
{
	int iLastClient = GetClientOfUserId(event.GetInt("victim"));
	int iAttacker = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidSurvivor(iLastClient) && IsPlayerAlive(iLastClient) && IsValidInfected(iAttacker))
	{
		if(GetCountAliveSurv() == 1)
		{
			hNoDeathCheck.SetInt(0, false, false);
			ForcePlayerSuicide(iAttacker);
			SDKCall(g_hSDK_CTerrorPlayer_OnRevived, iLastClient);
			SetEntProp(iLastClient, Prop_Send, "m_currentReviveCount", hIncapCountMax);
			SetEntProp(iLastClient, Prop_Send, "m_bIsOnThirdStrike", 1);
			SetEntProp(iLastClient, Prop_Send, "m_isGoingToDie", 1);
			EmitSoundToClient(iLastClient, "player/heartbeatloop.wav");
		}
	}
	return Plugin_Continue;
}

Action Event_PlayerDeath(Event event, const char[] name, bool bDontBroadcast)
{
	int iDeathClient = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidSurvivor(iDeathClient))
	{
		if(GetCountAliveSurv() == 0)
		{
			hNoDeathCheck.SetInt(0, false, false);
		}
	}
	return Plugin_Continue;
}

Action Event_RoundEnd(Event event, const char[] name, bool bDontBroadcast)
{
	hNoDeathCheck.SetInt(0, false, false);
	return Plugin_Continue;
}

stock int GetCountAliveSurv()
{
	int iCount = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			iCount++;
		}
	}
	return iCount;
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}

stock bool IsValidSurvivor(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 2;
}

stock bool IsValidInfected(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 3;
}
