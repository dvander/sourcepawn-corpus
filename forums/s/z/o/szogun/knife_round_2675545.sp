//#define UNLOAD_KENTO_RANKME

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <entity>

#pragma semicolon				1
#pragma newdecls				required

#define MAX_PLAYERS				64

#define TEAM_CT					2
#define TEAM_TT					3

public Plugin myinfo =
{
	name = "Knife Round",
	author = "Maciej Wrzesinski",
	description = "Plugin sets up an additional knife round after warmup ends",
	version = "1.3",
	url = "https://github.com/maciej-wrzesinski/"
};

bool g_bKnifeRoundEnded = false;

int g_iRoundNumber = 0;
int g_iWonTeam = 0;

int iClientsNumWinners = 0;
int iClientsWinnersID[MAX_PLAYERS + 1];
int iClientsWinnersDecision[MAX_PLAYERS + 1];

ConVar cvInfo;
ConVar cvTime;
ConVar cvVote;
ConVar cvAllowAllTalk;
ConVar cvBuyTimeNormal;
ConVar cvBuyTimeImmunity;
ConVar cvTalkDead;
ConVar cvTalkLiving;

int		g_iCvarInfo;
float	g_fCvarRoundTime;
float	g_fCvarVoteTime;
int		g_iCvarAllowAllTalk;
float	g_fCvarBuyTimeNormal;
float	g_fCvarBuyTimeImmunity;
int		g_iCvarTalkDead;
int		g_iCvarTalkLiving;

Handle g_hHUD;

public void OnPluginStart()
{
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	HookEvent("player_spawn", PlayerSpawn);
	
	cvInfo = CreateConVar("knifer_info", "2", "How should messages be displayed? (0 - none, 1 - chat, 2 - HUD)", _, true, 0.0, true, 2.0);
	cvTime = CreateConVar("knifer_roundtime", "60.0", "How much time should knife round take? (0.5 to 60.0 minutes)", _, true, 0.5, true, 60.0);
	cvVote = CreateConVar("knifer_votetime", "10.0", "How much time should vote take? (5 to 20 seconds)", _, true, 5.0, true, 20.0);
	cvAllowAllTalk = CreateConVar("knifer_alltalk", "1", "Should there be alltalk enabled while knife round? (1 - enabled, 0 - disabled)", _, true, 0.0, true, 1.0);
	
	cvBuyTimeNormal = FindConVar("mp_buytime");
	cvBuyTimeImmunity = FindConVar("mp_buy_during_immunity");
	cvTalkDead = FindConVar("sv_talk_enemy_dead");
	cvTalkLiving = FindConVar("sv_talk_enemy_living");
	
	g_bKnifeRoundEnded = false;
	g_iRoundNumber = 0;
	
	g_hHUD = CreateHudSynchronizer();
	
	AutoExecConfig(true, "knife_round");
	LoadTranslations("knife_round.phrases");
}

public void OnConfigsExecuted()
{
	g_iCvarInfo = GetConVarInt(cvInfo);
	g_fCvarRoundTime = GetConVarFloat(cvTime);
	g_fCvarVoteTime = GetConVarFloat(cvVote);
	g_iCvarAllowAllTalk = GetConVarInt(cvAllowAllTalk);
	
	g_fCvarBuyTimeNormal = GetConVarFloat(cvBuyTimeNormal);
	g_fCvarBuyTimeImmunity = GetConVarFloat(cvBuyTimeImmunity);
	g_iCvarTalkDead = GetConVarInt(cvTalkDead);
	g_iCvarTalkLiving = GetConVarInt(cvTalkLiving);
}

public void OnMapStart()
{
	g_bKnifeRoundEnded = false;
	g_iRoundNumber = 0;
}

public void OnMapEnd()
{
	g_bKnifeRoundEnded = false;
	g_iRoundNumber = 0;
}

public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if (g_iRoundNumber == 2 && g_bKnifeRoundEnded == false)
		StripOnePlayerWeapons(GetClientOfUserId(GetEventInt(event, "userid")));
}

public Action RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if (GetClientCountInTeams() < 1 || GameRules_GetProp("m_bWarmupPeriod"))
	{
		g_iRoundNumber = 0;
		g_bKnifeRoundEnded = false;
		return;
	}
	
	if (g_bKnifeRoundEnded)
		return;
	
	
	g_iRoundNumber++;
	
	if (g_iRoundNumber == 1)
		PrepareForKnifeRound();
	
	else if(g_iRoundNumber == 2 && g_bKnifeRoundEnded == false) //round after warmup = knife round
	{
		
		
#if defined UNLOAD_KENTO_RANKME
		ServerCommand("sm plugins unload kento_rankme");
#endif
		
		
		CreateTimer(0.5, TimerStripWeapons);
		
		char cTempTextHUD[256];
		Format(cTempTextHUD, sizeof(cTempTextHUD), "%t", "Knife_Start");
		SendTextToAll(cTempTextHUD);
	}
}

public Action RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if (GetClientCountInTeams() < 1 || GameRules_GetProp("m_bWarmupPeriod"))
	{
		g_iRoundNumber = 0;
		g_bKnifeRoundEnded = false;
		return;
	}
	
	if (g_bKnifeRoundEnded)
		return;
	
	if (g_iRoundNumber == 2) //end of knife round
	{
		
		
#if defined UNLOAD_KENTO_RANKME
		ServerCommand("sm plugins load kento_rankme");
#endif
		
		
		g_bKnifeRoundEnded = true;
		AfterKnifeRound();
		
		g_iWonTeam = GetEventInt(event, "winner");
		if (g_iWonTeam != TEAM_CT && g_iWonTeam != TEAM_TT)
		{
			char cTempTextHUD[256];
			Format(cTempTextHUD, sizeof(cTempTextHUD), "%t", "Win_None");
			SendTextToAll(cTempTextHUD);
			
			RestartLastTime();
		}
		else
			MakeVote();
	}
}

stock void MakeVote()
{
	char cTempTextHUD[256];
	Format(cTempTextHUD, sizeof(cTempTextHUD), "%t", "Voting_Start");
	SendTextToAll(cTempTextHUD);
	
	iClientsNumWinners = 0;
	for (int i = 1;i <= MAX_PLAYERS;i++) //counting winning guys to show them a menu
	
		if (IsClientValid(i) && !IsClientSourceTV(i))
		
			if (GetClientTeam(i) == g_iWonTeam)
			{
				iClientsWinnersID[iClientsNumWinners] = i;
				++iClientsNumWinners;
			}
	
	
	Handle hMenu = CreateMenu(ShowVotingMenuHandle);
	char cTempBuffer[128];
	Format(cTempBuffer, sizeof(cTempBuffer), "%t", "Menu_Title");
	SetMenuTitle(hMenu, cTempBuffer);
	
	AddMenuItem(hMenu, "CT", "CT");
	AddMenuItem(hMenu, "TT", "TT");
	
	SetMenuExitButton(hMenu, false);
	SetMenuExitBackButton(hMenu, false);
	
	for(int i = 0; i < iClientsNumWinners; i++)
		DisplayMenu(hMenu, iClientsWinnersID[i], RoundFloat(g_fCvarVoteTime));
	CreateTimer(g_fCvarVoteTime, EndTheVote);
}

public int ShowVotingMenuHandle(Handle hMenu, MenuAction action, int client, int choose)
{
	if (action == MenuAction_End)
	{
		if (IsValidHandle(hMenu))
			CloseHandle(hMenu);
	}
	else if (action == MenuAction_Select)
	{
		choose += 2;
		if (choose == TEAM_CT)
			iClientsWinnersDecision[client] = TEAM_CT;
			
		else if (choose == TEAM_TT)
			iClientsWinnersDecision[client] = TEAM_TT;
	}
} 

public Action EndTheVote(Handle hTimer)
{
	int iCTNum = 0;
	int iTTNum = 0;
	for (int i = 1; i <= MAX_PLAYERS; i++) //counting winning guys to show them a menu
	
		if (IsClientValid(i) && !IsClientSourceTV(i))
		
			switch(iClientsWinnersDecision[i])
			{
				case TEAM_CT: { ++iCTNum; }
				case TEAM_TT: { ++iTTNum; }
			}
	
	int iWantedTeam = 0;
	bool bDoSwap = false;
	
	if (iCTNum >= iTTNum)
		iWantedTeam = TEAM_CT;
	else
		iWantedTeam = TEAM_TT;
	
	g_iWonTeam = g_iWonTeam == TEAM_CT ? TEAM_TT : TEAM_CT;
	
	
	if (g_iWonTeam != iWantedTeam)
		bDoSwap = true;
	
	
	if (bDoSwap)
	{
		char cTempTextHUD[256];
		Format(cTempTextHUD, sizeof(cTempTextHUD), "%t", "Winning_Swap");
		SendTextToAll(cTempTextHUD);
		
		RestartSwapLastTime();
	}
	else
	{
		char cTempTextHUD[256];
		Format(cTempTextHUD, sizeof(cTempTextHUD), "%t", "Winning_Stay");
		SendTextToAll(cTempTextHUD);
		
		RestartLastTime();
	}
}

stock void PrepareForKnifeRound()
{
	if (g_iCvarAllowAllTalk)
	{
		ServerCommand("sv_talk_enemy_dead 1");
		ServerCommand("sv_talk_enemy_living 1");
	}
	ServerCommand("mp_roundtime %f", g_fCvarRoundTime);
	ServerCommand("mp_roundtime_defuse %f", g_fCvarRoundTime);
	ServerCommand("mp_buytime 0");
	ServerCommand("mp_buy_during_immunity 0");
	ServerCommand("mp_startmoney 0");
	ServerCommand("mp_restartgame 1");
}

stock void AfterKnifeRound()
{
	if (g_iCvarAllowAllTalk)
	{
		ServerCommand("sv_talk_enemy_dead %i", g_iCvarTalkDead);
		ServerCommand("sv_talk_enemy_living %i", g_iCvarTalkLiving);
	}
	ServerCommand("mp_roundtime 1.92");
	ServerCommand("mp_roundtime_defuse 1.92");
	ServerCommand("mp_pause_match");
}

stock void RestartLastTime()
{
	ServerCommand("mp_buytime %f", g_fCvarBuyTimeNormal);
	ServerCommand("mp_buy_during_immunity %f", g_fCvarBuyTimeImmunity);
	ServerCommand("mp_startmoney 800");
	ServerCommand("mp_unpause_match");
	ServerCommand("mp_restartgame 1");
}

stock void RestartSwapLastTime()
{
	ServerCommand("mp_buytime %f", g_fCvarBuyTimeNormal);
	ServerCommand("mp_buy_during_immunity %f", g_fCvarBuyTimeImmunity);
	ServerCommand("mp_startmoney 800");
	ServerCommand("mp_unpause_match");
	ServerCommand("mp_swapteams");
}

public Action TimerStripWeapons(Handle timer)
{
	StripAllPlayersWeapons();
}

stock void StripAllPlayersWeapons()
{
	for (int i = 1; i <= MAX_PLAYERS; i++)
		StripOnePlayerWeapons(i);
}

stock void StripOnePlayerWeapons(int client)
{
	if (IsClientValid(client) && IsPlayerAlive(client))
	{
		int iTempWeapon = -1;
		for (int i = 0; i < 5; i++)
			if ((iTempWeapon = GetPlayerWeaponSlot(client, i)) != -1)
				if (IsValidEntity(iTempWeapon))
				{
					--i;
					SafeRemoveWeapon(client, iTempWeapon);
				}
		
		GivePlayerItem(client, "weapon_knife");
		ClientCommand(client, "slot3");
	}
}

/*
	https://forums.alliedmods.net/archive/index.php/t-288614.html
	thanks for SafeRemoveWeapon stock
*/

stock bool SafeRemoveWeapon(int client, int weapon)
{
	if (!IsValidEntity(weapon) || !IsValidEdict(weapon))
		return false;
	
	if (!HasEntProp(weapon, Prop_Send, "m_hOwnerEntity"))
		return false;
	
	int iOwnerEntity = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	
	if (iOwnerEntity != client)
		SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);
	
	CS_DropWeapon(client, weapon, false);
	
	if (HasEntProp(weapon, Prop_Send, "m_hWeaponWorldModel"))
	{
		int iWorldModel = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
		
		if (IsValidEdict(iWorldModel) && IsValidEntity(iWorldModel) && !AcceptEntityInput(iWorldModel, "Kill"))
			return false;
	}
	
	if (!AcceptEntityInput(weapon, "Kill"))
		return false;
	
	return true;
}

stock bool IsClientValid(int client)
{
	return (client > 0 && client <= MAX_PLAYERS && IsClientInGame(client));
}

stock int GetClientCountInTeams()
{
	int iTempSum = 0;
	for (int i = 1; i <= MAX_PLAYERS; i++)
		if (IsClientValid(i) && IsClientAuthorized(i) && !IsClientSourceTV(i) && (GetClientTeam(i) == TEAM_CT || GetClientTeam(i) == TEAM_TT))
			++iTempSum;
	
	return iTempSum;
}

stock void SendTextToAll(char[] text)
{
	if (g_iCvarInfo == 1)
		PrintToChatAll(text);
	else if (g_iCvarInfo == 2)
	{
		Handle hData = CreateDataPack();
		WritePackString(hData, text);
		
		CreateTimer(2.0, FixHUDmsg, hData);
	}
}

public Action FixHUDmsg(Handle hTimer, Handle hData)
{
	ResetPack(hData);
	
	char cTempText[256];
	ReadPackString(hData, cTempText, sizeof(cTempText));
	
	for (int i = 1; i <= MAX_PLAYERS; i++)
		if (IsClientValid(i))
		{
			SetHudTextParams(-1.0, -1.0, 4.0, 255, 255, 255, 200, 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(i, g_hHUD, cTempText);
		}
}
