#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = 
{
	name = "TF2B In-game Backpack Viewer",
	author = "n00berific",
	description = "Opens up TF2B in the MOTD Panel.",
	version = "1.0",
	url = "http://www.tf2b.com/"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegConsoleCmd("sm_tf2b", Command_TF2B);
}

public Action:Command_TF2B(iClient, iArgs)
{
	new String:szSteamID[32];
	new String:szCommunityID[32];
	new String:szURL[128];
	
	if(iArgs < 1)
	{
		GetClientAuthString(iClient, szSteamID, sizeof(szSteamID));
		GetCommunityID(szSteamID, szCommunityID);
		Format(szURL, sizeof(szURL), "http://www.tf2b.com/?id=%s", szCommunityID);
		ShowMOTDPanel(iClient, "TF2B", szURL, MOTDPANEL_TYPE_URL);
		
		return Plugin_Handled;
	}
	
	new String:szSearch[32];
	new String:szPlayerName[32];
	GetCmdArg(1, szSearch, sizeof(szSearch));
	
	new String:szTarget_Name[MAX_TARGET_LENGTH];
	new iTarget_List[MAXPLAYERS], bool:bTn_is_ml;
	
	if((ProcessTargetString(szSearch, iClient, iTarget_List, MAXPLAYERS, COMMAND_FILTER_CONNECTED, szTarget_Name, sizeof(szTarget_Name), bTn_is_ml)) <= 0)
	{
		Format(szURL, sizeof(szURL), "http://www.tf2b.com/?id=%s", szSearch);
		ShowMOTDPanel(iClient, "TF2B", szURL, MOTDPANEL_TYPE_URL);
		
		return Plugin_Handled;
	}
	
	if(IsClientConnected(iTarget_List[0]) && IsClientInGame(iTarget_List[0]))
	{
		GetClientName(iTarget_List[0], szPlayerName, sizeof(szPlayerName));
		
		if(StrContains(szPlayerName, szSearch, false))
		{
			GetClientAuthString(iTarget_List[0], szSteamID, sizeof(szSteamID));
			GetCommunityID(szSteamID, szCommunityID);
			Format(szURL, sizeof(szURL), "http://www.tf2b.com/?id=%s", szCommunityID);
			ShowMOTDPanel(iClient, "TF2B", szURL, MOTDPANEL_TYPE_URL);
		}
	}
	
	return Plugin_Handled;
}

GetCommunityID(String:szSteamID[], String:szCommunityID[])
{
	new String:szBuffers[3][16];
	ExplodeString(szSteamID, ":", szBuffers, 3, 16);
	
	new result = StringToInt(szBuffers[2]) * 2 + 60265728 + StringToInt(szBuffers[1]);
	Format(szCommunityID, 32, "765611979%i", result);
}