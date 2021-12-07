#include <sourcemod>
#include <adminmenu>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "2.0"
#define TAG "[SM] "
Handle g_hTopMenu = null;
ConVar gcv_iArraySize = null;
ArrayList ga_Names;
ArrayList ga_SteamIds;
public Plugin myinfo =
{
	name = "Ban Disconnected Player",
	author = "Headline, mad_hamster",
	description = "Allows you to ban players who have disconnected from the server",
	version = PLUGIN_VERSION,
};
public void OnPluginStart()
{
	CreateConVar("hl_bandisconnected_version", PLUGIN_VERSION, "Headline's ban disconnected plugin", FCVAR_DONTRECORD);
	gcv_iArraySize = CreateConVar("hl_bandisconnected_max", "100", "List size of ban disconnected players menu");
	RegAdminCmd("sm_bandisconnected", Command_BanDisconnected, ADMFLAG_BAN, "Ban a player after they have disconnected!");
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
	char sSteamID[32];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));
	if (FindStringInArray(ga_SteamIds, sSteamID) != -1)
	{
		ga_Names.Erase(ga_SteamIds.FindString(sSteamID));
		ga_SteamIds.Erase(ga_SteamIds.FindString(sSteamID));
	}
}
public Action Event_PlayerDisconnect(Event hEvent, char[] name, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (IsValidClient(client))
	{
		char sName[MAX_NAME_LENGTH];
		GetClientName(client, sName, sizeof(sName));
		char sDisconnectedSteamID[32];
		GetClientAuthId(client, AuthId_Steam2, sDisconnectedSteamID, sizeof(sDisconnectedSteamID));
		if (FindStringInArray(ga_SteamIds, sDisconnectedSteamID) == -1)
		{
			PushToArrays(sName, sDisconnectedSteamID);
		}
	}
}
void PushToArrays(const char[] clientName, const char[] clientSteam)
{
	if (ga_Names.Length == 0)
	{
		ga_Names.PushString(clientName);
		ga_SteamIds.PushString(clientSteam);
	}
	else
	{
		ga_Names.ShiftUp(0);
		ga_SteamIds.ShiftUp(0);
		ga_Names.SetString(0, clientName);
		ga_SteamIds.SetString(0, clientSteam);
	}
	if (ga_Names.Length >= gcv_iArraySize.IntValue && gcv_iArraySize.IntValue > 0)
	{
		ga_Names.Resize(gcv_iArraySize.IntValue);
		ga_SteamIds.Resize(gcv_iArraySize.IntValue);
	}
}
public Action Command_BanDisconnected(int client, int args)
{
	if (args != 3)
	{
		ReplyToCommand(client, " %sUsage: sm_bandisconnected <\"steamid\"> <minutes|0> [\"reason\"]", TAG);
		return Plugin_Handled;
	}
	else
	{
		char steamid[20], minutes[10], reason[256];
		GetCmdArg(1, steamid, sizeof(steamid));
		GetCmdArg(2, minutes, sizeof(minutes));
		GetCmdArg(3, reason,  sizeof(reason));
		CheckAndPerformBan(client, steamid, StringToInt(minutes), reason);
	}
	return Plugin_Handled;
}
public Action Command_ListDisconnected(int client, int args)
{
	if (ga_Names.Length >= 10)
	{
		PrintToConsole(client, "************ LAST 10 DISCONNECTED PLAYERS *****************");
		for (int i = 0; i <= 10; i++)
		{
			char sName[MAX_TARGET_LENGTH], sSteamID[32];
			ga_Names.GetString(i, sName, sizeof(sName));
			ga_SteamIds.GetString(i, sSteamID, sizeof(sSteamID));
			PrintToConsole(client, "NAME : %s  STEAMID : %s", sName, sSteamID);
		}
		PrintToConsole(client, "************ LAST 10 DISCONNECTED PLAYERS *****************");
	}
	else
	{
		if (ga_Names.Length == 0)
		{
			PrintToConsole(client, "[SM] There are no disconnected players yet!");
		}
		else
		{
			PrintToConsole(client, "************ LAST %i DISCONNECTED PLAYERS *****************", GetArraySize(ga_Names) - 1);
			for (int i = 0; i < ga_Names.Length; i++)
			{
				char sName[MAX_TARGET_LENGTH], sSteamID[32];
				ga_Names.GetString(i, sName, sizeof(sName));
				ga_SteamIds.GetString(i, sSteamID, sizeof(sSteamID));
				PrintToConsole(client, "** %s | %s **", sName, sSteamID);
			}
			PrintToConsole(client, "************ LAST %i DISCONNECTED PLAYERS *****************", GetArraySize(ga_Names) - 1);
		}
	}
	return Plugin_Handled;
}
void CheckAndPerformBan(int client, char[] steamid, int minutes, char[] reason)
{
	AdminId admClient = GetUserAdmin(client);
	AdminId admTarget;
	if ((admTarget = FindAdminByIdentity(AUTHMETHOD_STEAM, steamid)) == INVALID_ADMIN_ID || CanAdminTarget(admClient, admTarget))
	{
		bool hasRoot = GetAdminFlag(admClient, Admin_Root);
		SetAdminFlag(admClient, Admin_Root, true);
		FakeClientCommand(client, "sm_addban \"%s\" %d %s", steamid, minutes, reason);
		SetAdminFlag(admClient, Admin_Root, hasRoot);
	}
	else
	{
		ReplyToCommand(client, " %sYou can't ban an admin with higher immunity than yourself", TAG);
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
		Format(buffer, maxlength, "Ban disconnected player");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayTargetsMenu(param);
	}
}
public void DisplayTargetsMenu(int client)
{
	if (ga_SteamIds.Length == 0)
	{
		ReplyToCommand(client, "[SM] There are no disconnected players yet!");
		return;
	}
	Menu MainMenu = new Menu(TargetsMenu_CallBack, MenuAction_Select | MenuAction_End);
	MainMenu.SetTitle("Select a target!");
	char sDisplayBuffer[128], sSteamID[32], sName[MAX_NAME_LENGTH];
	for (int i = 0; i < ga_SteamIds.Length; i++)
	{
		ga_Names.GetString(i, sName, sizeof(sName));
		ga_SteamIds.GetString(i, sSteamID, sizeof(sSteamID));
		Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%s (%s)", sName, sSteamID);
		MainMenu.AddItem(sSteamID, sDisplayBuffer);
	}
	SetMenuExitBackButton(MainMenu, true);
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
	BanTimeMenu.SetTitle("Select A Time:");
	char sInfoBuffer[128];
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,131490", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "3 Months");
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,0", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "Permanent");
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,60", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "1 Hour");
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,720", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "12 Hours");
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,1440", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "1 Day");
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,1440", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "1 Week");
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,30240", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "3 Weeks");
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,43830", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "1 Month");
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,131490", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "3 Months");
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,262980", sInfo);
	BanTimeMenu.AddItem(sInfoBuffer, "6 Months");
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
	BanReasonMenu.SetTitle("Select A Reason:");
	char sInfoBuffer[128];
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,Team killing", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "Team killing");
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,Breaking Server Rules", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "Breaking Server Rules");
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,Abusive", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "Abusive");
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,General cheating/exploits", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "General cheating/exploits");
	Format(sInfoBuffer, sizeof(sInfoBuffer), "%s,Mic spamming", sInfo);
	BanReasonMenu.AddItem(sInfoBuffer, "Spamming");
	SetMenuExitBackButton(BanReasonMenu, true);
	DisplayMenu(BanReasonMenu, client, MENU_TIME_FOREVER);
}
public int BanReason_CallBack(Handle BanReasonMenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[128], sTempArray[3][64];
			GetMenuItem(BanReasonMenu, param2, sInfo, sizeof(sInfo));
			ExplodeString(sInfo, ",", sTempArray, 3, 64);
			CheckAndPerformBan(param1, sTempArray[0], StringToInt(sTempArray[1]), sTempArray[2]);
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
	ga_Names = new ArrayList(MAX_TARGET_LENGTH);
	ga_SteamIds = new ArrayList(32);
}
bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}