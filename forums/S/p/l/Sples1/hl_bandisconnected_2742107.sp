#include <sourcemod>
#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.0.1"
#define TAG "「BanDisconnected」 "

Handle g_hTopMenu = null;

ConVar gcv_iArraySize = null;

ArrayList ga_Data;
enum struct UserData {
	char			Names[MAX_TARGET_LENGTH];
	char			SteamIDs[32];
	char			IPs[32];
}

public Plugin myinfo =
{
	name = "[ANY] Ban Disconnected Player",
	author = "Headline, Original Plugin : mad_hamster",
	description = "Allows you to ban players who have disconnected from the server",
	version = PLUGIN_VERSION,
	url = "http://michaelwflaherty.com/"
};

public void OnPluginStart()
{
	CreateConVar("hl_bandisconnected_version", PLUGIN_VERSION, "Headline's ban disconnected plugin", FCVAR_DONTRECORD);
	
	gcv_iArraySize = CreateConVar("hl_bandisconnected_max", "100", "List size of ban disconnected players menu");
	
	RegAdminCmd("sm_bandisconnected", Command_BanDisconnected, ADMFLAG_BAN, "Ban a player after they have disconnected!");
	RegAdminCmd("sm_bandc", Command_BanDisconnected, ADMFLAG_BAN, "Ban a player after they have disconnected!");
	RegAdminCmd("sm_listdisconnected", Command_ListDisconnected, ADMFLAG_BAN, "List all disconnected players!");

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	
	Handle topmenu;
	if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	LoadADTArray();
}

public void OnClientPostAdminCheck(int client)
{
	if (IsValidClient(client))
	{
		char sSteamID[32];
		GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));

		UserData iData;
		int size = ga_Data.Length;
		for (int i = 0; i < size; i++)
		{
			ga_Data.GetArray(i, iData);
			if (StrEqual(iData.SteamIDs, sSteamID))
			{
				ga_Data.Erase(i);
				break;
			}
		}
	}
}

public Action Event_PlayerDisconnect(Event hEvent, char[] name, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (IsValidClient(client))
	{
		char sName[MAX_NAME_LENGTH];
		GetClientName(client, sName, sizeof(sName));
		
		char sDisconnectedSteamID[32], ip[18];
		GetClientAuthId(client, AuthId_Steam2, sDisconnectedSteamID, sizeof(sDisconnectedSteamID));
		GetClientIP(client, ip, sizeof(ip));
		
		bool found = false;
		UserData iData;
		int size = ga_Data.Length;
		for (int i = 0; i < size; i++)
		{
			ga_Data.GetArray(i, iData);
			if (StrEqual(iData.SteamIDs, sDisconnectedSteamID))
			{
				found = true;
				break;
			}
		}
		
		if (!found)
			PushToArrays(sName, sDisconnectedSteamID, ip);
	}
}

void PushToArrays(const char[] clientName, const char[] clientSteam, const char[] ip)
{
	UserData iData;

	FormatEx(iData.Names, sizeof(iData.Names), clientName);
	FormatEx(iData.SteamIDs, sizeof(iData.SteamIDs), clientSteam);
	FormatEx(iData.IPs, sizeof(iData.IPs), ip);
	
	ga_Data.PushArray(iData);
	
	/* Trucate Arrays */
	if (ga_Data.Length >= gcv_iArraySize.IntValue && gcv_iArraySize.IntValue > 0)
	{
		ga_Data.Resize(gcv_iArraySize.IntValue);
	}
}

public Action Command_BanDisconnected(int client, int args)
{
	if (args == 0)
	{
		DisplayTargetsMenu(client, false);
		return Plugin_Handled;
	}
	if (args != 5)
	{
		ReplyToCommand(client, " %sUsage: sm_bandisconnected <\"steamid\"> <minutes|0> [\"reason\"] <ip> <name>", TAG);
		return Plugin_Handled;
	}

	char steamid[20], minutes[10], reason[256], ip[16], name[128];
	GetCmdArg(1, steamid, sizeof(steamid));
	GetCmdArg(2, minutes, sizeof(minutes));
	GetCmdArg(3, reason,  sizeof(reason));
	GetCmdArg(4, ip,  sizeof(ip));
	GetCmdArg(5, name,  sizeof(name));
	CheckAndPerformBan(client, steamid, StringToInt(minutes), reason, ip, name);
	return Plugin_Handled;
}

public Action Command_ListDisconnected(int client, int args)
{
	UserData iData;
	if (ga_Data.Length >= 10)
	{
		PrintToConsole(client, "************ LAST %i DISCONNECTED PLAYER *****************");
		for (int i = 0; i <= 10; i++)
		{
			ga_Data.GetArray(i, iData);
			PrintToConsole(client, "NAME : %s  STEAMID : %s IP : %s", iData.Names, iData.SteamIDs,  iData.IPs);
		}
		PrintToConsole(client, "************ LAST %i DISCONNECTED PLAYER *****************");
	}
	else
	{
		if (ga_Data.Length == 0)
		{
			PrintToConsole(client, "「BanDC」 Noone left the server");
		}
		else
		{
			int size = ga_Data.Length;
			PrintToConsole(client, "************ LAST %i DISCONNECTED PLAYER *****************", size - 1);
			for (int i = 0; i < size; i++)
			{
				ga_Data.GetArray(i, iData);
				PrintToConsole(client, "NAME : %s  STEAMID : %s IP : %s", iData.Names, iData.SteamIDs,  iData.IPs);
			}
			PrintToConsole(client, "************ LAST %i DISCONNECTED PLAYER *****************", size - 1);
		}
	}
	return Plugin_Handled;
}

void CheckAndPerformBan(int client, char[] steamid, int minutes, char[] reason,  char[] ip,  char[] name)
{
	AdminId admClient = GetUserAdmin(client);
	AdminId admTarget;
	if ((admTarget = FindAdminByIdentity(AUTHMETHOD_STEAM, steamid)) == INVALID_ADMIN_ID || CanAdminTarget(admClient, admTarget))
	{
		bool hasRoot = GetAdminFlag(admClient, Admin_Root);
		SetAdminFlag(admClient, Admin_Root, true);
		char temp[1024];
		Format(temp, sizeof(temp), "%s + [Offline Ban]", reason);
		FakeClientCommand(client, "sm_addban \"%d\" \"%s\" \"%s\" \"%s\" \"%s\"", minutes, steamid, temp, ip, name);
		SetAdminFlag(admClient, Admin_Root, hasRoot);
	}
	else
	{
		ReplyToCommand(client, " %sYou can not ban immune players!", TAG);
	}
}

public void OnAdminMenuReady(Handle hTopMenu)
{
	if(hTopMenu == g_hTopMenu)
	{
		return;
	}
	
	g_hTopMenu = hTopMenu;

	TopMenuObject MenuObject = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	if(MenuObject == INVALID_TOPMENUOBJECT)
	{
		return;
	} 
	AddToTopMenu(hTopMenu, "sm_bandisconnected", TopMenuObject_Item, AdminMenu_Ban, MenuObject, "sm_bandisconnected", ADMFLAG_BAN, "Ban Disconnected Player");
}

public void AdminMenu_Ban(Handle hTopMenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Ban Disconnected Player");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayTargetsMenu(param, true);
	}
}

public void DisplayTargetsMenu(int client, bool exitback) 
{
	if (ga_Data.Length == 0)
	{
		ReplyToCommand(client, "「BanDC」 Noone left the server yet!");
		return;
	}
	
	Menu MainMenu = new Menu(TargetsMenu_CallBack, MenuAction_Select | MenuAction_End); 
	MainMenu.SetTitle("Target:"); 

	UserData iData;
	int size = ga_Data.Length;
	char sDisplayBuffer[128], temp[3];
	for (int i = 0; i < size; i++)
	{
		ga_Data.GetArray(i, iData);
		
		Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%s (%s)", iData.Names, iData.SteamIDs);
		IntToString(i, temp, sizeof(temp));
		MainMenu.AddItem(temp, sDisplayBuffer); 
	}
	SetMenuExitBackButton(MainMenu, exitback);
	DisplayMenu(MainMenu, client, MENU_TIME_FOREVER); 
}

public int TargetsMenu_CallBack(Menu MainMenu, MenuAction action, int param1, int param2) 
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[128];
			GetMenuItem(MainMenu, param2, sInfo, sizeof(sInfo));
			
			DisplayBanTimeMenu(param1, sInfo);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(MainMenu);
		}
	}
}

public void DisplayBanTimeMenu(int client, char[] sInfo)
{
	Menu BanTimeMenu = new Menu(BanTime_CallBack, MenuAction_Select | MenuAction_End); 
	BanTimeMenu.SetTitle("Length:"); 
	char sInfoBuffer[128];
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,0", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "Permanent");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,10", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "10 Minute");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,30", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "30 Minute");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,60", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "1 Hour");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,240", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "4 Hour");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,1440", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "1 Day");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,10080", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "1 Week");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,20160", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "2 Week");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,30240", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "3 Week");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,43200", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "1 Month");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,129600", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "3 Month");
	
	SetMenuExitBackButton(BanTimeMenu, true);
	DisplayMenu(BanTimeMenu, client, MENU_TIME_FOREVER); 
}

public int BanTime_CallBack(Handle BanTimeMenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[128];
			GetMenuItem(BanTimeMenu, param2, sInfo, sizeof(sInfo));
			
			DisplayBanReasonMenu(param1, sInfo);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(BanTimeMenu);
		}
	}
}

void DisplayBanReasonMenu(int client, char[] sInfo)
{
	Menu BanReasonMenu = new Menu(BanReason_CallBack, MenuAction_Select | MenuAction_End); 
	BanReasonMenu.SetTitle("Reason:"); 
	char sInfoBuffer[128];
		
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,Hacking", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "Hacking");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,General Exploit", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "General Exploit");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,Cheating (Collective)", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "Cheating (Collective)");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,Wallhack", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "Wallhack");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,Aimbot", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "Aimbot");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,Speedhacking", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "Speedhacking");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,Spamming Mic/Chat", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "Spamming Mic/Chat");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,Admin disrespect", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "Admin disrespect");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,Inappropriate Name", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "Inappropriate Name");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,Ignoring Admins", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "Ignoring Admins");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,Inappropriate Language", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "Inappropriate Language");
	
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,Other", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "Other");
	
	SetMenuExitBackButton(BanReasonMenu, true);
	DisplayMenu(BanReasonMenu, client, MENU_TIME_FOREVER);
}

public int BanReason_CallBack(Handle BanReasonMenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[128], sTempArray[3][64]; // Steamid,time,reason is the format of sInfo
			
			GetMenuItem(BanReasonMenu, param2, sInfo, sizeof(sInfo));
			ExplodeString(sInfo, ",", sTempArray, 3, 64);
			
			int temp = StringToInt(sTempArray[0]);
			
			UserData iData;
			ga_Data.GetArray(temp, iData);
			
			CheckAndPerformBan(param1, iData.SteamIDs, StringToInt(sTempArray[1]), sTempArray[2], iData.IPs, iData.Names);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(BanReasonMenu);
		}
	}
}

void LoadADTArray()
{
	ga_Data = CreateArray(sizeof(UserData));
}

bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}