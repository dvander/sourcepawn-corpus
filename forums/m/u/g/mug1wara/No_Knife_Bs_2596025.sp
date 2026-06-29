#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

bool g_bTyped[MAXPLAYERS + 1];

int iCount;

public Plugin myinfo =
{
	name = "[NKB] No Knife Bs",
	author = "Mug1wara",
	description = "Basically prevents people from bullshitting you, saying they want to knife but instead pulls up his / her gun in last sec.",
	version = "0.0.2",
	url = "http://img.pr0gramm.com/2017/06/29/4d539b3b585eac96.jpg",
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_nkb", Cmd_Nkb);
}

public Action Event_End(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	g_bTyped[iClient] = false;
	
	iCount = 0;
}

public Action Cmd_Nkb(int iClient, int iArgs)
{
	if (!IsPlayerAlive(iClient))
		return Plugin_Handled;
	
	if (GetTeamClientCount(CS_TEAM_CT) == 1 && GetTeamClientCount(CS_TEAM_T) == 1)
	{
		g_bTyped[iClient] = true;
	
		int iPrimary = GetPlayerWeaponSlot(iClient, CS_SLOT_PRIMARY);
		int iSecondary = GetPlayerWeaponSlot(iClient, CS_SLOT_SECONDARY);
		int iWeapons = iPrimary + iSecondary;
	
		if (g_bTyped[iClient])
			return Plugin_Handled;
	
		iCount++;
	
		if (iCount == 2)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				RemovePlayerItem(i, iWeapons);
				AcceptEntityInput(iWeapons, "Kill");
			}
		}
	}
	
	return Plugin_Handled;
}