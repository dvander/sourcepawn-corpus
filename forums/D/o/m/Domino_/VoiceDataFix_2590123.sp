#include <sourcemod>
#include <voiceannounce_ex>
#include <sourcebanspp>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "VoiceData Crash Fix", 
	author = "backwards, IT-KiLLER, SM9();, BH4x0r, Ember, domino_", 
	description = "Exploit Fix", 
	version = "0.3"
};

char g_szLog[PLATFORM_MAX_PATH];
ConVar g_cBanClient = null;
ConVar g_cBanCount = null;
bool g_bSourceBans = false;

int g_Count[MAXPLAYERS+1] = { 0, ... };
Handle g_hTimer = INVALID_HANDLE;

public void OnPluginStart() 
{
	BuildPath(Path_SM, g_szLog, sizeof(g_szLog), "logs/VoiceDataCrashFix.log");
	
	g_cBanClient = CreateConVar("sm_voicedatafix_ban", "1", "Should the client be banned for crash attempt?", FCVAR_PROTECTED);
	g_cBanCount = CreateConVar("sm_voicedatafix_count", "96", "How many packets per second max?", FCVAR_PROTECTED);
	
	AutoExecConfig(true, "VoiceDataFix");
}

public void OnMapStart()
{
    if(g_hTimer == INVALID_HANDLE)
        g_hTimer = CreateTimer(1.0, RepeatingTimer, _, TIMER_REPEAT);
}

public void OnMapEnd()
{
    if(g_hTimer != INVALID_HANDLE)
    {
        KillTimer(g_hTimer);
        g_hTimer = INVALID_HANDLE;
    }
}

public Action RepeatingTimer(Handle timer)
{
	for(int i = 1;i <= MAXPLAYERS; i++)
		g_Count[i] = 0;

	return Plugin_Continue;
}

public void OnLibraryAdded(const char[] szName) 
{
	if (StrEqual(szName, "sourcebans"))
		g_bSourceBans = true;
}

public void OnLibraryRemoved(const char[] szName) 
{
	if (StrEqual(szName, "sourcebans"))
		g_bSourceBans = false;
}

public void OnClientSpeakingEx(int iClient)
{
	g_Count[iClient]++;

	if(g_Count[iClient] > g_cBanCount.IntValue) //on 64 tick sever clients send 32 voice packets per second, this threshold should be safe
	{
		if(!IsClientInKickQueue(iClient))
		{
			if(g_cBanClient.BoolValue)
			{
				if(g_bSourceBans)
				{
					SBPP_BanPlayer(0, iClient, 0, "Attempted server crash exploit");
				}
				else
				{
					BanClient(iClient, 0, BANFLAG_AUTO, "Attempted server crash exploit", "Attempted server crash exploit");
				}
				LogToFileEx(g_szLog, "Banned %L for sending VoiceData messages (>96pps) (Confirmed crash attempt)", iClient);
			}
			else
			{
				KickClient(iClient, "Attempted server crash exploit");
				LogToFileEx(g_szLog, "Kicked %L for sending VoiceData messages (>96pps) (Confirmed crash attempt)", iClient);
			}
		}
	}
}

stock bool IsValidClient(int iClient, bool noBots = true)
{ 
	if (iClient <= 0 || iClient > MaxClients || !IsClientConnected(iClient) || !IsClientAuthorized(iClient) || (noBots && IsFakeClient(iClient)))
		return false;
	
	return IsClientInGame(iClient);
}