// Includes
#include <sourcemod>
#include <store>
#include <kento_touchdown>

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

ConVar gc_iCreditsTouchdown;
ConVar gc_iCreditsKillBallHolder;

// Info
public Plugin myinfo = 
{
	name = "[Touchdown] Store Credits Giver",
	author = "shanapu",
	description = "Give Credits for Zephs store on TouchDown",
	version = "1.0",
	url = "https://github.com/shanapu/"
};

public void OnPluginStart()
{
	gc_iCreditsTouchdown = CreateConVar("sm_touchdown_credits_goal", "50", "How many credits for touchdown? 0 - disabled", _, true, 0.0);
	gc_iCreditsKillBallHolder = CreateConVar("sm_touchdown_credits_kill", "10", "How many credits for killing ballholder? 0 - disabled", _, true, 0.0);

	AutoExecConfig(true, "kento_touchdown_credits");
}

public Action Touchdown_OnPlayerTouchDown(int client)
{
	if(gc_iCreditsTouchdown.IntValue < 1)
	{
		return;
	}

	if(!IsValidClient(client))
	{
		return;
	}

	Store_SetClientCredits(client, Store_GetClientCredits(client) + gc_iCreditsTouchdown.IntValue);

	PrintToChat(client, "\x04[Store]\x01 You have earned %d cash for touchdown!", gc_iCreditsTouchdown.IntValue);
}

public Action Touchdown_OnPlayerKillBall(int ballholder, int attacker)
{
	if(gc_iCreditsKillBallHolder.IntValue < 1)
	{
		return;
	}

	if(!IsValidClient(attacker))
	{
		return;
	}

	Store_SetClientCredits(attacker, Store_GetClientCredits(attacker) + gc_iCreditsKillBallHolder.IntValue);

	PrintToChat(attacker, "\x04[Store]\x01 You have earned %d cash for killing the ballholder %N!", gc_iCreditsKillBallHolder.IntValue, ballholder);
}

bool IsValidClient(int client)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}

	return false;
}