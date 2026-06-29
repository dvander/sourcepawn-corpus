#pragma semicolon 1
#pragma newdecls required

#include <revival>

int
	m_iAccount,
	iReward;

public Plugin myinfo =
{
	name		= "[Revival] Reward",
	version		= "1.0.0",
	description	= "Gives the player money for each player he revives.",
	author		= "Grey83",
	url			= "https://steamcommunity.com/groups/grey83ds"
}

public void OnPluginStart()
{
	if((m_iAccount = FindSendPropInfo("CCSPlayer", "m_iAccount")) == -1)
		SetFailState("Unable to find offset CCSPlayer::m_iAccount.");

	ConVar cvar = CreateConVar("sm_revival_reward", "300", "How much money to give for revival", FCVAR_NOTIFY, true, _, true, 16000.0);
	iReward = cvar.IntValue;
	cvar.AddChangeHook(CVarChanged);
}

public void CVarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iReward = cvar.IntValue;
}

public void Revival_OnPlayerRevived(int reviver, int target, int frags)
{
	if(!iReward) return;

	int money = GetEntData(reviver, m_iAccount) + iReward;
	if(money > 16000) money = 16000;
	SetEntData(reviver, m_iAccount, money);
}