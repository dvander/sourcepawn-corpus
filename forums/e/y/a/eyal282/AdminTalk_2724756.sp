#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Klaus, edit by Eyal282"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#define PREFIX " \x04[AdminTalk]\x01"
#define MENU_PREFIX "[AdminTalk]"

bool g_InTalk[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Admin Talk", 
	author = PLUGIN_AUTHOR, 
	description = "Let admins join a private talk", 
	version = PLUGIN_VERSION, 
	url = "KlausLaw"
};

Handle fwOnClientAdminTalkPost;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("AT_IsClientInAdminTalk", Native_IsClientInAdminTalk);
}

public any Native_IsClientInAdminTalk(Handle plugin, numParams)
{
	int client = GetNativeCell(1);
	
	return g_InTalk[client];
}
public void OnPluginStart()
{
	RegAdminCmd("sm_at", SM_AdminTalk, ADMFLAG_BAN);
	RegAdminCmd("sm_sat", SM_SAdminTalk, ADMFLAG_BAN);
	RegAdminCmd("sm_atmenu", SM_MenuAdminTalk, ADMFLAG_BAN);
	RegAdminCmd("sm_admintalk", SM_AdminTalk, ADMFLAG_BAN);
	RegAdminCmd("sm_fadmintalk", SM_fAdminTalk, ADMFLAG_BAN);
	RegAdminCmd("sm_sadmintalk", SM_SAdminTalk, ADMFLAG_BAN);
	
	HookEvent("player_death", EventRenew, EventHookMode_Post);
	HookEvent("player_spawn", EventRenew, EventHookMode_Post);
	
	LoadTranslations("common.phrases.txt");
	
	// public void AT_OnClientAdminTalkPost(int client, bool bPrevInTalk, bool bInTalk);
	fwOnClientAdminTalkPost = CreateGlobalForward("AT_OnClientAdminTalkPost", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
}

public OnClientPostAdminCheck(int client)
{
	ChangeTalk(client);
}

public OnClientConnected(int client)
{
	g_InTalk[client] = false;
	
	FireAdminTalkForward(client, false);
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
	if(args == 0)
	{
		JoinAdminTalk(client);
		
		return Plugin_Handled;
	}
	char sTargetArg[MAX_NAME_LENGTH];
	GetCmdArgString(sTargetArg, sizeof(sTargetArg));
	int target = FindTarget(client, sTargetArg, true, false);
	
	if (target == -1)
	{
		ReplyToCommand(client, "%s Usage: sm_admintalk <#userid|name>.", PREFIX);
		return Plugin_Handled;
	}
	
	
	JoinAdminTalk(target);
	return Plugin_Handled;
}


public Action SM_MenuAdminTalk(int client, int args)
{
	Menu menu = new Menu(MenuHandler_AdminTalk);
	
	menu.SetTitle("%s Choose a player to move into / out of admin talk:\nPlayers inside the admin talk are marked with ⬤", MENU_PREFIX);
	
	char TempFormat[11], Name[64];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(IsFakeClient(i))
			continue;
			
		IntToString(GetClientUserId(i), TempFormat, sizeof(TempFormat));
		
		GetClientName(i, Name, sizeof(Name));
		
		if(g_InTalk[i])
			Format(Name, sizeof(Name), "⬤ %s", Name);
		
		menu.AddItem(TempFormat, Name);
			
	}
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}


public int MenuHandler_AdminTalk(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
		CloseHandle(menu);
		
	else if(action == MenuAction_Select)
	{
		char sUserId[11];
		
		menu.GetItem(item, sUserId, sizeof(sUserId));
		
		new target = GetClientOfUserId(StringToInt(sUserId));
		
		if(target == 0)
		{
			PrintToChat(client, "%s Target is no longer connected.", PREFIX);
			
			return;
		}
		
		JoinAdminTalk(target);
		
		SM_MenuAdminTalk(client, 0);
	}
}
public Action SM_fAdminTalk(int client, int args)
{
	ReplyToCommand(client, "[SM] Deprecated command, use !at <target> instead.");
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
	
	FireAdminTalkForward(client, !g_InTalk[client]);
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

void FireAdminTalkForward(int client, bool bPrevInTalk)
{
	Call_StartForward(fwOnClientAdminTalkPost);
	
	Call_PushCell(client);
	Call_PushCell(bPrevInTalk);
	Call_PushCell(g_InTalk[client]);
	
	Call_Finish();
}
