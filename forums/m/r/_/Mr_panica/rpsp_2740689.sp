#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <morecolors>
#include <clientprefs>
#include <sdkhooks>

#pragma newdecls required

Cookie g_WinsCookie = null;
Cookie g_LossesCookie = null;

int g_iWins[MAXPLAYERS + 1] =  { 0, ... };
int g_iLosses[MAXPLAYERS + 1] =  { 0, ... };

public void OnPluginStart()
{
	LoadTranslations("rpsp.phrases");
	
	g_WinsCookie = new Cookie("knb_wins", "", CookieAccess_Private);
	g_LossesCookie = new Cookie("knb_losses", "", CookieAccess_Private);
	
	HookEvent("rps_taunt_event", Event_RpsTaunt);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || !AreClientCookiesCached(client))
			continue;
		
		OnClientCookiesCached(client);
	}
}

public void OnClientCookiesCached(int client)
{
	char szBuffer[16];
	g_WinsCookie.Get(client, szBuffer, sizeof(szBuffer));
	g_iWins[client] = szBuffer[0] ? StringToInt(szBuffer) : 0;
	
	g_LossesCookie.Get(client, szBuffer, sizeof(szBuffer));
	g_iLosses[client] = szBuffer[0] ? StringToInt(szBuffer) : 0;
}

public void Event_RpsTaunt(Event event, const char[] name, bool dontBroadcast)
{
	int winner = event.GetInt("winner");
	int loser = event.GetInt("loser");
	if(!IsClientInGame(winner) || !IsClientInGame(loser))
		return;
	
	int winner_rps = event.GetInt("winner_rps");
	int loser_rps = event.GetInt("loser_rps");
	
	char szWinnerRsp[32], szLoserRsp[32];
	GetRspPhrase(winner_rps, szWinnerRsp, sizeof(szWinnerRsp));
	GetRspPhrase(loser_rps, szLoserRsp, sizeof(szLoserRsp));
	
	++g_iWins[winner];
	++g_iLosses[loser];
	
	CPrintToChatAll("%t", "Player Win",
	(TF2_GetClientTeam(winner) == TFTeam_Red) ? "Red Team Color" : "Blue Team Color", winner,
	(TF2_GetClientTeam(loser) == TFTeam_Red) ? "Red Team Color" : "Blue Team Color", loser,
	szWinnerRsp, szLoserRsp, g_iWins[winner], 
	float(g_iWins[winner]) / float(g_iWins[winner] + g_iLosses[winner]) * 100.0);

	DataPack hPack;
	CreateDataTimer(3.5, Timer_ReadDataPack, hPack, TIMER_FLAG_NO_MAPCHANGE); //Idea. Make RPS for Friendly Fire :D
	hPack.WriteCell(loser);
	hPack.WriteCell(winner);


	char szBuffer[16];
	IntToString(g_iWins[winner], szBuffer, sizeof(szBuffer));
	g_WinsCookie.Set(winner, szBuffer);
	
	IntToString(g_iLosses[loser], szBuffer, sizeof(szBuffer));
	g_LossesCookie.Set(loser, szBuffer);
}

int GetRspPhrase(int rsp, char[] szBuffer, int len)
{
	switch(rsp)
	{
		case 0:	return strcopy(szBuffer, len, "Rock");
		case 1:	return strcopy(szBuffer, len, "Paper");
		case 2:	return strcopy(szBuffer, len, "Scissors");
	}
	
	return 0;
}

public Action Timer_ReadDataPack(Handle hTimer, Handle hDataPack)
{
	DataPack hPack = view_as<DataPack>(hDataPack);
	hPack.Reset();
	int loser = ReadPackCell(hPack);
	int winner = ReadPackCell(hPack);

	if(TF2_GetClientTeam(winner) == TF2_GetClientTeam(loser) && IsClientInGame(loser) && IsClientInGame(winner))
	SDKHooks_TakeDamage(loser, winner, winner, 850.0);

}
