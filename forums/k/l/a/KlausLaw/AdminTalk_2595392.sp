#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Klaus"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#define PREFIX " \x04[AdminTalk]\x01"

bool g_InTalk[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Admin Talk", 
	author = PLUGIN_AUTHOR, 
	description = "Let admins join a private talk", 
	version = PLUGIN_VERSION, 
	url = "KlausLaw"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_admintalk", SM_AdminTalk, ADMFLAG_BAN);
	RegAdminCmd("sm_fadmintalk", SM_fAdminTalk, ADMFLAG_BAN);
	RegAdminCmd("sm_sadmintalk", SM_SAdminTalk, ADMFLAG_BAN);
	
	HookEvent("player_death", EventRenew, EventHookMode_Post);
	HookEvent("player_spawn", EventRenew, EventHookMode_Post);
	
	LoadTranslations("common.phrases.txt");
}

public OnClientPostAdminCheck(int client)
{
	ChangeTalk(client);
}

public OnClientDisconnect(int client)
{
	g_InTalk[client] = false;
}


public EventRenew(Handle event, char[] sName, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	ChangeTalk(client);
}


public Action SM_AdminTalk(int client, int args)
{
	JoinAdminTalk(client);
	return Plugin_Handled;
}

public Action SM_fAdminTalk(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "%s Usage: sm_fadmintalk <name>.", PREFIX);
		return Plugin_Handled;
	}
	char sTargetArg[MAX_NAME_LENGTH];
	GetCmdArg(1, sTargetArg, sizeof(sTargetArg));
	int target = FindTarget(client, sTargetArg, true, false);
	if (target == -1)
	{
		return Plugin_Handled;
	}
	
	JoinAdminTalk(target);
	return Plugin_Handled;
}

void JoinAdminTalk(int client)
{
	g_InTalk[client] = !g_InTalk[client];
	ChangeTalk(client);
	
	char sMessage[128];
	Format(sMessage, sizeof(sMessage), "%s \x07%N\x01 has %s\x01 the \x04Admin Talk", PREFIX, client, g_InTalk[client] ? "\x04joined" : "\x02left");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || (GetUserAdmin(i) == INVALID_ADMIN_ID && !g_InTalk[i]))continue;
		PrintToChat(i, sMessage);
	}
}

public Action SM_SAdminTalk(int client, int args)
{
	char sPlayers[120];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !g_InTalk[i])continue;
		Format(sPlayers, sizeof(sPlayers), "\x07%N\x01 %s %s", i, strlen(sPlayers) <= 1 ? "" : ",", sPlayers);
	}
	if (strlen(sPlayers) <= 1)
	{
		PrintToChat(client, "%s There are \x070\x01 players in the \x04Admin Talk", PREFIX);
		return Plugin_Handled;
	}
	PrintToChat(client, "%s Players in Admin Talk: %s", PREFIX, sPlayers);
	return Plugin_Handled;
	
}

void ChangeTalk(int client)
{
	ListenOverride LOverride;
	ListenOverride LOverride2;
	if (g_InTalk[client])
	{
		LOverride = Listen_Yes;
		LOverride2 = Listen_No;
	}
	else
	{
		LOverride = Listen_No;
		LOverride2 = Listen_Default;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))continue;
		if (g_InTalk[i])
		{
			SetListenOverride(i, client, LOverride);
			SetListenOverride(client, i, LOverride);
		}
		else
		{
			SetListenOverride(i, client, LOverride2);
			SetListenOverride(client, i, LOverride2);
			
		}
	}
}


