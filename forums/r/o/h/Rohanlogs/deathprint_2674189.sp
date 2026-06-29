#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

int g_iFreezeTime;
int g_iRoundStart;


public void OnPluginStart()
{
	Handle hCvFreezeTime = FindConVar("mp_freezetime");
	g_iFreezeTime = GetConVarInt(hCvFreezeTime);
	
	HookEvent("round_start", Event_RoundStart);  
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
}


public Action Event_RoundStart( Handle hEvent, const char[] sName, bool dontBroadcast ) 
{
	g_iRoundStart = GetTime();
}


public Action Event_OnPlayerDeath( Handle hEvent, const char[] sName, bool dontBroadcast )
{
	int iClient = GetClientOfUserId( GetEventInt(hEvent, "userid") );
	
	if( !fwIsValidClient(iClient) ) return Plugin_Continue;
	
	int iSecondsTotal = ( GetTotalRoundTime() - GetCurrentRoundTime() );
	
	int iMinutes = (iSecondsTotal / 60);
	int iSeconds = iSecondsTotal - (iMinutes * 60);
	
	if(iMinutes > 0 && iSeconds > 0) PrintToChatAll("[SM] Player %N died with %i minute(s) and %i second(s) round left.", iClient, iMinutes, iSeconds);
	return Plugin_Continue;
}


public int GetTotalRoundTime() 
{
	return GameRules_GetProp("m_iRoundTime");
}


public int GetCurrentRoundTime() 
{
	return( GetTime() - g_iRoundStart ) - g_iFreezeTime;
}


bool fwIsValidClient(int iClient) 
{ 
	if(iClient <= 0) return false; 
	if(iClient > MaxClients) return false; 
	if( !IsClientConnected(iClient) ) return false; 
	
	return IsClientInGame(iClient); 
}

