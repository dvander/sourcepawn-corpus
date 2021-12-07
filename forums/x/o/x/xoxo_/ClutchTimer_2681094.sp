#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <store>

#define PREFIX " \x0B[SM]\x01 " 
#define PREFIX_NO_COLOR "[SM] " 

#pragma newdecls required
#pragma semicolon 1

bool gB_Clutch;
int gI_ClutchingPlayerTeam;
int gI_EnemyPlayersTotal;
int gI_Prize;

/* CVars */

ConVar gCV_PluginEnabled = null;
ConVar gCV_MinCredits = null;
ConVar gCV_MaxCredits = null;

/* Cached CVars */

bool gB_PluginEnabled = true;
int gI_MinCredits = 100;
int gI_MaxCredits = 500;

Handle hTimer_ClutchInfo = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "Clutch Timer",
	author = "xoxo^^",
	description = "",
	version = "1.0",
	url = ""
};

public void OnMapStart()
{
	hTimer_ClutchInfo = INVALID_HANDLE;
}
public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);

	gCV_PluginEnabled = CreateConVar("clutch_enabled", "1", "Enable or Disable all features of the plugin.", 0, true, 0.0, true, 1.0);
	gCV_MinCredits = CreateConVar("clutch_min", "150", "Minimum amount of credits given for a clutch.", FCVAR_NOTIFY, true, 0.0);
	gCV_MaxCredits = CreateConVar("clutch_max", "1500", "Maximum amount of credits given for a clutch.", FCVAR_NOTIFY, true, 0.0);

	gCV_PluginEnabled.AddChangeHook(OnConVarChanged);
	gCV_MinCredits.AddChangeHook(OnConVarChanged);
	gCV_MaxCredits.AddChangeHook(OnConVarChanged);

	AutoExecConfig();
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	gB_PluginEnabled = gCV_PluginEnabled.BoolValue;
	gI_MinCredits = gCV_MinCredits.IntValue;
	gI_MaxCredits = gCV_MaxCredits.IntValue;
}

public void OnPlayerDeath(Event event, char[] name, bool dontBroadcast)
{
	if(!gB_PluginEnabled)
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	PlayerDeath_CheckClutch(victim, attacker);
}

public void PlayerDeath_CheckClutch(int victim, int attacker)
{
	// Victim & attacker can be equal to 0 while gB_Clutch is false, so this won't throw an error.
	if(gB_Clutch && ((gI_ClutchingPlayerTeam == CS_TEAM_T && GetClientTeam(victim) == CS_TEAM_T) || (gI_ClutchingPlayerTeam == CS_TEAM_CT && GetClientTeam(victim) == CS_TEAM_CT)))
	{
		PrintCenterTextAll("<font color='#FF0000'>%N </font><font color='#ffffff'>Ruined </font><font color='#FF0000'>%N's </font><font color='#ffffff'>Clutch! </font> ", attacker, victim);
		gB_Clutch = false;
	}

	int iAliveT, iAliveCT;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(IsPlayerAlive(i))
			{
				switch(GetClientTeam(i))
				{
					case CS_TEAM_T: iAliveT++;
					case CS_TEAM_CT: iAliveCT++;
				}
			}
		}
	}

	if(!gB_Clutch)
	{
		if(iAliveCT == 1 && iAliveT > 1)
		{
			gI_ClutchingPlayerTeam = CS_TEAM_CT;
			gI_EnemyPlayersTotal = iAliveT;
			gB_Clutch = true;
		}
		else if(iAliveT == 1 && iAliveCT > 1)
		{
			gI_ClutchingPlayerTeam = CS_TEAM_T;
			gI_EnemyPlayersTotal = iAliveCT;
			gB_Clutch = true;
		}

		if(gB_Clutch)
		{
			PrintToChatAll("%s It's time to \x05clutch! \x01(\x051 \x01vs \x07%d\x01) ", PREFIX, gI_EnemyPlayersTotal);
			
			hTimer_ClutchInfo = CreateTimer(1.0, Timer_ClutchInfo, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
	}
	else
	{
		// If someone was killed
		if(gI_ClutchingPlayerTeam == CS_TEAM_T && GetClientTeam(victim) == CS_TEAM_CT)
		{
			PrintToChatAll("%s Clutch \x05Progress \x01: Killed [\x04%d\x01/\x07%d\x01] ", PREFIX, gI_EnemyPlayersTotal - iAliveCT, gI_EnemyPlayersTotal);
		}
		else if(gI_ClutchingPlayerTeam == CS_TEAM_CT && GetClientTeam(victim) == CS_TEAM_T)
		{
			PrintToChatAll("%s Clutch \x05Progress \x01: Killed [\x04%d\x01/\x07%d\x01] ", PREFIX, gI_EnemyPlayersTotal - iAliveT, gI_EnemyPlayersTotal);
		}
		
		TriggerTimer(hTimer_ClutchInfo, true);
	}
}

public Action Timer_ClutchInfo(Handle hTimer)
{
	int client = GetClutchingPlayer();
	
	if(client == 0)
	{
		hTimer_ClutchInfo = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	int iAliveEnemies;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(IsPlayerAlive(i))
			{
				if(GetClientTeam(i) > CS_TEAM_SPECTATOR && GetClientTeam(i) != gI_ClutchingPlayerTeam)
					iAliveEnemies++;
			}
		}
	}
	
	char Name[64];
	
	GetClientName(client, Name, sizeof(Name));
	
	ReplaceString(Name, sizeof(Name), "<", ""); // Hopefully this will be fixed in the future when using %N
	ReplaceString(Name, sizeof(Name), ">", "");
		
	if(gI_ClutchingPlayerTeam == CS_TEAM_T)
		PrintCenterTextAll("<font color='#40E0D0'>Clutch Situation:</font>\n<font color='#FF0000'>%s</font> VS <font color='#0000FF'>%i %s</font>\nKilled: <font color='#00FF00'>%i</font>/<font color='#FF0000'>%i</font>", Name, gI_EnemyPlayersTotal, gI_ClutchingPlayerTeam == CS_TEAM_T ? "CT" : "T", gI_EnemyPlayersTotal - iAliveEnemies, gI_EnemyPlayersTotal);
		
	else
		PrintCenterTextAll("<font color='#40E0D0'>Clutch Situation:</font>\n<font color='#0000FF'>%s</font> VS <font color='#FF0000'>%i %s</font>\nKilled: <font color='#00FF00'>%i</font>/<font color='#FF0000'>%i</font>", Name, gI_EnemyPlayersTotal, gI_ClutchingPlayerTeam == CS_TEAM_T ? "CT" : "T", gI_EnemyPlayersTotal - iAliveEnemies, gI_EnemyPlayersTotal);
	
	return Plugin_Continue;
	
	
}

public void OnRoundEnd(Event event, char[] name, bool dontBroadcast)
{
	if(hTimer_ClutchInfo != INVALID_HANDLE)
	{
		CloseHandle(hTimer_ClutchInfo);
		hTimer_ClutchInfo = INVALID_HANDLE;
	}
	if(!gB_Clutch || !gB_PluginEnabled)
	{
		return;
	}

	int winningTeam = event.GetInt("winner");

	if(winningTeam == gI_ClutchingPlayerTeam)
	{
		int LivingPlayers = 0, LastLivingPlayer = 0;
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i))
				continue;
				
			else if(!IsPlayerAlive(i))
				continue;
				
			LivingPlayers++;
			LastLivingPlayer = i;
		}
		
		if(LivingPlayers != 1)
		{
			int client = GetClutchingPlayer();
		
			if(client != 0)
				PrintToChatAll(" \x07%N \x01has failed \x01to \x05Clutch! ", client);
				
			return;
		}
		gI_Prize = GetRandomInt(gI_MinCredits, gI_MaxCredits);
		PrintToChatAll(" \x0C%N \x01Successfully \x05Clutched! \x01Enjoy Your \x07Prize \x01(\x04%d \x01credits)! ", LastLivingPlayer, gI_Prize);
		Store_SetClientCredits(LastLivingPlayer, Store_GetClientCredits(LastLivingPlayer) + gI_Prize);
	}
	else
	{
		int client = GetClutchingPlayer();
		
		if(client != 0)
			PrintToChatAll(" \x07%N \x01has failed \x01to \x05Clutch! ", client);
			
	}
	gB_Clutch = false;
}

public void OnRoundStart(Event event, char[] name, bool dontBroadcast)
{
	if(hTimer_ClutchInfo != INVALID_HANDLE)
	{
		CloseHandle(hTimer_ClutchInfo);
		hTimer_ClutchInfo = INVALID_HANDLE;
	}
	
	gB_Clutch = false;
	
	PlayerDeath_CheckClutch(0, 0);
}

// returns 0 if no clutching player is found / no clutch has to be made.
stock int GetClutchingPlayer()
{
	int LivingPlayers, LastLivingPlayer;
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(!IsPlayerAlive(i))
			continue;
		
		else if(GetClientTeam(i) != gI_ClutchingPlayerTeam)
			continue;
			
		LivingPlayers++;
		LastLivingPlayer = i;
	}
	
	if(LivingPlayers != 1)
		return 0;
		
	return LastLivingPlayer;
}