#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <adminmenu>


#undef REQUIRE_EXTENSIONS
#include <93x_checkip>
#define REQUIRE_EXTENSIONS

#pragma newdecls required
ConVar g_cvEnabled;
int i_cvEnabled;

int g_OnClientPutInServer[MAXPLAYERS+1] = {false, ... };

public Plugin myinfo = 
{
	name = "SM XnEt 93x IP Print",
	author = "bbs.93x.net Add More Translation By:2389736818",
	description = "<- Description ->",
	version = "1.6",
	url = "<- URL ->"
}

public void OnPluginStart()
{
    LoadTranslations("93x_checkip.phrases"); 
	g_cvEnabled = CreateConVar("sm_93x_ip_print_enabled", "2", "1= show city 2 = show full 0 = disable");
	i_cvEnabled = GetConVarInt(g_cvEnabled);
	HookConVarChange(g_cvEnabled, HookConVar_Changed);
	
	RegConsoleCmd("sm_ipcheck", checkplayerip);
	
	AutoExecConfig(true);
	
	HookEventEx("player_team",	Event_PlayerTeam);
}

public void HookConVar_Changed(ConVar convar, char[] oldValue, char[] newValue)
{
	if(convar == g_cvEnabled)
		
	i_cvEnabled = view_as<int>(StringToInt(newValue));
}


public void OnClientPutInServer(int client)
{
	g_OnClientPutInServer[client] = true;
}


public Action Event_PlayerTeam(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!client || !IsClientInGame(client) || IsFakeClient(client) || !g_OnClientPutInServer[client] || i_cvEnabled == 0)
	{
		return Plugin_Continue;
	}
	
	CreateTimer(1.0, TimerPost, client);
	
	return Plugin_Continue;
}





public Action TimerPost(Handle timer ,any client)
{
	if(!client || !IsClientInGame(client) || IsFakeClient(client) || !g_OnClientPutInServer[client] || i_cvEnabled == 0) return;
	
	char g_ip[32];
	char g_city[128];
	char g_network[64];
	
	GetClientIP(client, g_ip, sizeof(g_ip));
	checkip_93x(g_ip, g_city, sizeof(g_city), g_network, sizeof(g_network), 1);
	
	g_OnClientPutInServer[client] = false;
	
	
	if(i_cvEnabled !=0 && i_cvEnabled ==1)
	{
		PrintToChatAll("%t", "Welcome message", client, g_city, g_network);
	}
	else if(i_cvEnabled !=0 && i_cvEnabled ==2)
	{
		PrintToChatAll("%t", "Welcome message Two", client, g_ip, g_city, g_network);
	}
	
	
	
}


public Action checkplayerip(int client, int args)
{
	if(client == 0)
	{
		PrintToChat(client, " \x04[SM] %t", "Not use command RCON");
		return Plugin_Handled;
	}
	
	if(!IsPlayerAdmin(client))
	{	
		PrintToChat(client, " \x04[SM] %t", "Only OP can use set");
		return Plugin_Handled;
	}
	
	if(args < 1) 
	{
		DisplayIPCheckMenu(client);
		return Plugin_Handled;
	}
	
	char arg2[10];
	
	GetCmdArg(2, arg2, sizeof(arg2));
	
	
	
	char strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget)); 
	
	
	char strTargetName[MAX_TARGET_LENGTH]; 
	int TargetList[MAXPLAYERS], TargetCount; 
	bool TargetTranslate; 
	
	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
	strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{
		ReplyToTargetError(client, TargetCount); 
		return Plugin_Handled; 
	} 
	
	
	for (int i = 0; i < TargetCount; i++) 
	{ 
		int iClient = TargetList[i]; 
		if (IsClientInGame(iClient)) 
		{
			char ipaddress[32];
			char city[128];
			char network[64];
			GetClientIP(iClient,ipaddress,sizeof(ipaddress));
			checkip_93x(ipaddress, city, sizeof(city), network, sizeof(network), 1);
			PrintToChat(client, "%t", "Player IP network address", iClient,ipaddress,city,network);
			PrintToChat(client, "%t", "Message only visible to me");
		}
	}
	
	return Plugin_Handled;
}




stock void DisplayIPCheckMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_IPCheckMenu);
	SetMenuTitle(menu, "%t", "Query player IP information");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_NO_BOTS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


public int MenuHandler_IPCheckMenu(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			char info[32];
			int target;
			
			GetMenuItem(menu, param2, info, sizeof(info));
			int userid = StringToInt(info);
			
			if ((target = GetClientOfUserId(userid)) == 0)
			{
				PrintToChat(param1, " \x04[SM] %t", "Player not available");
			}
			else
			{
				char ipaddress[32];
				char city[128];
				char network[64];
				GetClientIP(target,ipaddress,sizeof(ipaddress));
				checkip_93x(ipaddress, city, sizeof(city), network, sizeof(network), 1);
				PrintToChat(param1, "%t", "Player IP network address", target,ipaddress,city,network);
				PrintToChat(param1, "%t", "Message only visible to me Two");
			}
		}
	}
}


stock bool IsPlayerAdmin(int client)
{
	if (CheckCommandAccess(client, "sm_ban", ADMFLAG_BAN, false))
	{
		return true;
	}
	return false;
	
}