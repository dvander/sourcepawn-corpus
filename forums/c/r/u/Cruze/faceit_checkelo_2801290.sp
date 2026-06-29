#include <sourcemod>
#include <SteamWorks>

#pragma newdecls required
#pragma semicolon 1

#define MAX_USERNAME_LENGTH 64

public Plugin myinfo = 
{
	name = "[Faceit] Check ELO and LVL",
	author = "Cruze",
	description = "Type !elo <username> to check player elo and lvl.",
	version = "1.0.0",
	url = "https://github.com/Cruze03"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_elo", Command_CheckElo, "Check username's elo and lvl");
}

public Action Command_CheckElo(int client, int args)
{
	if(!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	char sUsername[MAX_USERNAME_LENGTH];
	GetCmdArgString(sUsername, sizeof(sUsername));
	TrimString(sUsername);
	StripQuotes(sUsername);
	
	DataPack pack = new DataPack();
	pack.WriteCell(GetClientSerial(client));
	pack.WriteCell(GetCmdReplySource());
	pack.WriteString(sUsername);
	
	static char sRequest[256];
	FormatEx(sRequest, sizeof(sRequest), "https://api.satont.dev/faceit?nick=%s", sUsername);
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, sRequest);
	if(!hRequest || !SteamWorks_SetHTTPRequestContextValue(hRequest, pack) || !SteamWorks_SetHTTPCallbacks(hRequest, OnTransferCompleted) || !SteamWorks_SendHTTPRequest(hRequest))
	{
		delete hRequest;
	}
	return Plugin_Handled;
}

public int OnTransferCompleted(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, DataPack pack)
{
	if (bFailure || !bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{
		LogError("SteamAPI HTTP Response failed: %i", eStatusCode);
		delete hRequest;
		delete pack;
		return;
	}
	
	pack.Reset();
	
	char sUsername[MAX_USERNAME_LENGTH];

	int serial = pack.ReadCell();
	ReplySource source = view_as<ReplySource>(pack.ReadCell());
	pack.ReadString(sUsername, sizeof(sUsername));
	delete pack;
	
	int client;
	if((client = GetClientFromSerial(serial)) == 0)
	{
		delete hRequest;
		return;
	}
	if(!IsClientInGame(client))
	{
		delete hRequest;
		return;
	}

	int iBodyLength;
	SteamWorks_GetHTTPResponseBodySize(hRequest, iBodyLength);

	char[] sData = new char[iBodyLength+1];
	SteamWorks_GetHTTPResponseBodyData(hRequest, sData, iBodyLength);
	
	delete hRequest;
	
	char sSearch[128];
	Format(sSearch, sizeof(sSearch), "User with nickname %s not found on faceit. Remember, you have to type nickname in the same case as in faceit.", sUsername);
	
	if(!strcmp(sData, sSearch, false))
	{
		if(source == SM_REPLY_TO_CONSOLE)
		{
			PrintToConsole(client, "[SM] Username not found in Faceit.");
		}
		else if(source == SM_REPLY_TO_CHAT)
		{
			PrintToChat(client, "[SM] Username not found in Faceit.");
		}
		return;
	}
	
	int elo = GetValueFromJson(sData, "elo");
	int lvl = GetValueFromJson(sData, "lvl");
	
	if(source == SM_REPLY_TO_CONSOLE)
	{
		PrintToConsole(client, "[SM] Player %s - Elo: %i | Lvl: %i", sUsername, elo, lvl);
	}
	else if(source == SM_REPLY_TO_CHAT)
	{
		PrintToChat(client, "[SM] Player %s - Elo: %i | Lvl: %i", sUsername, elo, lvl);
	}
}

int GetValueFromJson(char[] responseBody, char[] sSearch)
{
	char str[20][64];
	int count = ExplodeString(responseBody, ",", str, 20, 64);
	count = count > 19 ? 19 : count;
	for (int i = 0; i <= count; i++)
	{
		if (StrContains(str[i], sSearch) != -1)
		{
			char str2[2][32];
			ExplodeString(str[i], ":", str2, 2, 32);
			return StringToInt((str2[1]));
		}
	}
	return -1;
}