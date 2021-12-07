#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <myjailshop>

public Plugin myinfo = 
{
	name = "GOLD MEMBER",
	author = "kRatoss aka Teazze",
	description = "DNS BENEFITS",
	version = "1.6",
	url = "kratoss.eu"
};

bool b_IsGoldMember[MAXPLAYERS + 1];

Handle g_hServerName;
Handle g_cvFirstRound;
Handle g_cvBonus;
Handle g_cvSetClanTag;
Handle g_cvCreditsInterval;
Handle g_cvCreditsPerInt

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_Spawn);

	
	g_hServerName = CreateConVar("goldmember_servername", "alliedmods.net", "Your server/community names that players must have in their nickname");
					
	g_cvFirstRound = CreateConVar("goldmember_workfirstround", "0.0", "0 = Give no money first round. 1 = Give money in the first round.", \
					_, true, 0.0, true, 1.0);
					
	g_cvBonus = CreateConVar("goldmember_bonus", "15.0", "How many percent are added to the current player?. Example: 15 = 15% = 15/100");
	
	g_cvSetClanTag = CreateConVar("goldmember_tag", "1.0", "Set Gold Member® Tag?", _, true, 0.0, true, 1.0);
	
	g_cvCreditsInterval = CreateConVar("goldmember_interval", "60.0", "Interval(seconds)", _, true, 0.0, true, 1.0);
		
	g_cvCreditsPerInt = CreateConVar("goldmember_credits", "1.0", "Credits per interval", _, true, 0.0, true, 1.0);	
	
	CreateTimer(GetConVarFloat(g_cvCreditsInterval), Credits, _, TIMER_REPEAT);

}
	
public Action Credits(Handle pTimer)
{
	int iId;
	for (iId = 0; iId < MaxClients; iId++)
	{
		if(b_IsGoldMember[iId] && iId > 0)
		{
			int current_credits = MyJailShop_GetCredits(iId);
			float bonus_credits = GetConVarFloat(g_cvCreditsPerInt);
			int new_credits = RoundToCeil(bonus_credits);
			
			MyJailShop_SetCredits(iId, current_credits + new_credits);
			
			PrintToChat(iId, "* \x03 You've got +%i Credits", new_credits);
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	char sName[MAX_NAME_LENGTH], g_sDNS[MAX_NAME_LENGTH];
	
	GetConVarString(g_hServerName, g_sDNS, sizeof(g_sDNS));
	GetClientName(iClient, sName, MAX_NAME_LENGTH);
	
	if(StrContains(sName, g_sDNS, false) > -1)
		b_IsGoldMember[iClient] = true;
}

public Action Event_Spawn(Handle event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if(iClient > 0 && b_IsGoldMember[iClient] && IsPlayerAlive(iClient))
		CreateTimer(1.0, Equipt, iClient, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Equipt(Handle pTimer, any iClient)
{
	// Money
	//
	
	bool work = true;
	int Round = (GetTeamScore(CS_TEAM_CT) + GetTeamScore(CS_TEAM_T));
	float WorkFirstRound = GetConVarFloat(g_cvFirstRound);
	int iAccount = GetEntProp(iClient, Prop_Send, "m_iAccount");
	float ConVarBonus = GetConVarFloat(g_cvBonus);
	float fBonus = (ConVarBonus / 100);
	
	if(WorkFirstRound > 0.0)
	{
		if(Round == 0 || Round == 15)
			work = true;
		else
			work = true
	}
	else
		work = true;

	float AccBonus = (fBonus * iAccount);
	int RealBonus = RoundToCeil(AccBonus);
	int NewAcc = (RealBonus + iAccount);
	
	if(work)
	{
		SetEntProp(iClient, Prop_Send, "m_iAccount", NewAcc);
		PrintToChat(iClient, "* \x04 Thanks for advertising. \x06 You've got a money bonus.");
	}
		
	// Clan Tag
	//
	
	bool work2 = false;
	float cvVal = GetConVarFloat(g_cvSetClanTag);
	if(cvVal > 0.0)
		work2 = true;
		
	if(work2)
		CS_SetClientClanTag(iClient, "Gold Member®");

	return Plugin_Continue;
}