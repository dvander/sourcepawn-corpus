#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required
int HSCounter[MAXPLAYERS + 1] = 0;
int KillsCounter[MAXPLAYERS + 1] = 0;
public Plugin myinfo = 
{
	name = "HeadShot percentage on clan tag",
	author = "SheriF",
	description = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);
	AddCommandListener(ResetScore, "sm_rs");
}
public void OnMapStart()
{
	CreateTimer(0.1, HUD, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}
public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients;i++ )
	{
		if(IsClientInGame(i)&&!IsFakeClient(i))
		{
			HSCounter[i] = 0;
			KillsCounter[i] = 0;
		}
	}
}
public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int userid = GetClientOfUserId(event.GetInt("userid"));
	if(attacker!=userid)
	{
		KillsCounter[attacker]++;
		bool headshot = event.GetBool("headshot");
		if(headshot)
		HSCounter[attacker]++;
	}
}
public void OnClientPutInServer(int client)
{
	HSCounter[client] = 0;
	KillsCounter[client] = 0;
}
public Action ResetScore(int client,const char[]command,int Args)
{
	HSCounter[client] = 0;
	KillsCounter[client] = 0;
}
public float GetHsPercentage(int client, int hs, int kills)
{
	if(kills==0 || hs==0)
	return 0.0;
	else
	return 100.0*(float(hs) / float(kills));
}

public Action HUD(Handle timer)
{
	for (int i = 1; i <= MaxClients;i++ )
	{
		if(IsClientInGame(i)&&!IsFakeClient(i))
		{
			float HSper = GetHsPercentage(i, HSCounter[i], KillsCounter[i]);
			SetHudTextParams(0.0, 0.0, 2.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
			ShowHudText(i, -1,"Your HeadShot Percentage is: %0.2f%",HSper);
		}
	}
}