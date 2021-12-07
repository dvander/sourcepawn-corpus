#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"


new String:Chat1[MAXPLAYERS+1][1024];
new String:Chat2[MAXPLAYERS+1][1024];
new String:Chat3[MAXPLAYERS+1][1024];
new String:Chat4[MAXPLAYERS+1][1024];

new bool:IsBlocked[MAXPLAYERS+1] = false;
new LineCount[MAXPLAYERS+1] = 1;

new Handle:DelayTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:sm_advertflood_time;
new Handle:sm_advertflood_minlen;

public Plugin:myinfo = 
{
	name = "Advert Antiflood",
	author = "EHG",
	description = "Advert Antiflood",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("sm_advertflood_version", PLUGIN_VERSION, "Advert Antiflood Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	sm_advertflood_time = CreateConVar("sm_advertflood_time", "5.00", "Amount of time allowed between advert chat messages");
	sm_advertflood_minlen = CreateConVar("sm_advertflood_minlen", "5", "Minimum length of text to be detected");
	
	
	AddCommandListener(Command_SayChat, "say");
	AddCommandListener(Command_SayChat, "say_team");
}

public OnClientPostAdminCheck(client)
{
	IsBlocked[client] = false;
	LineCount[client] = 1;
	strcopy(Chat1[client], sizeof(Chat1[]), "NULL_INVALID_CHAT1");
	strcopy(Chat2[client], sizeof(Chat2[]), "NULL_INVALID_CHAT2");
	strcopy(Chat3[client], sizeof(Chat3[]), "NULL_INVALID_CHAT3");
	strcopy(Chat4[client], sizeof(Chat4[]), "NULL_INVALID_CHAT4");
	DelayTimer[client] = INVALID_HANDLE;
}


public OnClientDisconnect(client)
{
	if (DelayTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(DelayTimer[client]);
		DelayTimer[client] = INVALID_HANDLE;
	}
}

public Action:Command_SayChat(client, const String:command[], args)
{
	decl String:CurrentChat[1024];
	if (GetCmdArgString(CurrentChat, sizeof(CurrentChat)) < 1 || client == 0)
	{
		return Plugin_Continue;
	}
	
	if (strlen(CurrentChat) >= GetConVarInt(sm_advertflood_minlen))
	{
		new line = LineCount[client];
		switch(line)
		{
			case 1:
			{
				strcopy(Chat1[client], sizeof(Chat1[]), CurrentChat);
				LineCount[client] = 2;
				if (IsBlocked[client])
				{
					if (strcmp(CurrentChat, Chat2[client], false) == 0 
					|| strcmp(CurrentChat, Chat3[client], false) == 0 
					|| strcmp(CurrentChat, Chat4[client], false) == 0)
					{
						PrintToChat(client, "[SM] You are flooding the chat");
						return Plugin_Handled;
					}
				}
				else
				{
					StartTimer(client);
				}
			}
			case 2:
			{
				strcopy(Chat2[client], sizeof(Chat2[]), CurrentChat);
				LineCount[client] = 3;
				if (IsBlocked[client])
				{
					if (strcmp(CurrentChat, Chat1[client], false) == 0 
					|| strcmp(CurrentChat, Chat3[client], false) == 0 
					|| strcmp(CurrentChat, Chat4[client], false) == 0)
					{
						PrintToChat(client, "[SM] You are flooding the chat");
						return Plugin_Handled;
					}
				}
				else
				{
					StartTimer(client);
				}
			}
			case 3:
			{
				strcopy(Chat3[client], sizeof(Chat3[]), CurrentChat);
				LineCount[client] = 4;
				if (IsBlocked[client])
				{
					if (strcmp(CurrentChat, Chat1[client], false) == 0 
					|| strcmp(CurrentChat, Chat2[client], false) == 0 
					|| strcmp(CurrentChat, Chat4[client], false) == 0)
					{
						PrintToChat(client, "[SM] You are flooding the chat");
						return Plugin_Handled;
					}
				}
				else
				{
					StartTimer(client);
				}
			}
			case 4:
			{
				strcopy(Chat4[client], sizeof(Chat4[]), CurrentChat);
				LineCount[client] = 1;
				if (IsBlocked[client])
				{
					if (strcmp(CurrentChat, Chat1[client], false) == 0 
					|| strcmp(CurrentChat, Chat2[client], false) == 0 
					|| strcmp(CurrentChat, Chat3[client], false) == 0)
					{
						PrintToChat(client, "[SM] You are flooding the chat");
						return Plugin_Handled;
					}
				}
				else
				{
					StartTimer(client);
				}
			}
		}
	}
	
	return Plugin_Continue;
}


public StartTimer(client)
{
	IsBlocked[client] = true;
	if (DelayTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(DelayTimer[client]);
	}
	new Handle:pack;
	DelayTimer[client] = CreateDataTimer(GetConVarFloat(sm_advertflood_time), Timer_Reset, pack);
	WritePackCell(pack, client);
	WritePackCell(pack, GetClientUserId(client));
}

public Action:Timer_Reset(Handle:timer, Handle:pack)
{
	new client;
	new userid;
	ResetPack(pack);
	client = ReadPackCell(pack);
	userid = ReadPackCell(pack);
	if (userid != GetClientUserId(client))
		return Plugin_Handled;
	
	DelayTimer[client] = INVALID_HANDLE;
	strcopy(Chat1[client], sizeof(Chat1[]), "NULL_INVALID_CHAT1");
	strcopy(Chat2[client], sizeof(Chat2[]), "NULL_INVALID_CHAT2");
	strcopy(Chat3[client], sizeof(Chat3[]), "NULL_INVALID_CHAT3");
	strcopy(Chat4[client], sizeof(Chat4[]), "NULL_INVALID_CHAT4");
	IsBlocked[client] = false;
	return Plugin_Handled;
}


