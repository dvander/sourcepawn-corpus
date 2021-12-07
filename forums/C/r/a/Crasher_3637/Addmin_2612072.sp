#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required
#define ADDMIN_VERSION "1.1"

public Plugin myinfo = 
{
	name = "In Game Admin Manager",
	author = "Facksy",
	description = "In-Game Admin Manager",
	version = ADDMIN_VERSION,
	url = "http://steamcommunity.com/id/iamfacksy/"
};

bool g_bClientCanSayID[MAXPLAYERS + 1], g_bClientCanSayName[MAXPLAYERS + 1], g_bTargetHasFlags[MAXPLAYERS + 1];
char g_sKvPath[255], g_sTargetFlagsRegistred[MAXPLAYERS + 1][64], g_sTargetGivenSteamID[MAXPLAYERS + 1][64], g_sTargetName[MAXPLAYERS + 1][64];
ConVar g_cvSQL;
int g_iCGB[MAXPLAYERS + 1], g_iTargetSymbol[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegAdminCmd("sm_addmin", Cmd_Addmin, ADMFLAG_ROOT, "Open Admin Manager");
	RegAdminCmd("sm_addmins", Cmd_Addmin, ADMFLAG_ROOT, "Open Admin Manager");
	RegAdminCmd("sm_addadmin", Cmd_Addmin, ADMFLAG_ROOT, "Open Admin Manager");
	RegAdminCmd("sm_addadmins", Cmd_Addmin, ADMFLAG_ROOT, "Open Admin Manager");
	RegAdminCmd("sm_adminmanager", Cmd_Addmin, ADMFLAG_ROOT, "Open Admin Manager");
	g_cvSQL = CreateConVar("sm_sql_on", "1", "If MySQL or SQLlite is launched");
	CreateConVar("sm_addmin_version", ADDMIN_VERSION, "Addmin version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	AutoExecConfig(true, "sm_addmin");
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			InitialiseCl(i);
		}
	}
}

void InitialiseCl(int client)
{
	if (IsValidClient(client))
	{
		Format(g_sTargetFlagsRegistred[client], sizeof(g_sTargetFlagsRegistred[]), "");
		Format(g_sTargetGivenSteamID[client], sizeof(g_sTargetGivenSteamID[]), "");
		Format(g_sTargetName[client], sizeof(g_sTargetName[]), "");
		g_bTargetHasFlags[client] = false;
		g_bClientCanSayID[client] = false;
		g_bClientCanSayName[client] = false;
		g_iTargetSymbol[client] = 0;
	}
}

public Action Cmd_Addmin(int client, int args)
{
	InitialiseCl(client);
	Menu menu = new Menu(Menu_Handler);
	menu.SetTitle("-=- In-Game Admin Manager -=-");
	menu.AddItem("-", "-----", ITEMDRAW_DISABLED);
	menu.AddItem("1", "View in-game players");
	menu.AddItem("2", "Add/Modify Player with SteamID");
	menu.AddItem("3", "View file admin.cfg");
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Handler(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			char sInfo[64];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			switch (sInfo[0])
			{
				case '1': InGamePlayersMenu(client);
				case '2': SteamIDTool(client);
				case '3': AdminFileMenu(client);
			}
		}
	}
}

void InGamePlayersMenu(int client)
{
	Menu menu = new Menu(Menu_Handler2);
	menu.SetTitle("List of all Online Players");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			char sName[64], sUID[64];
			GetClientName(i, sName, sizeof(sName));
			IntToString(GetClientUserId(i), sUID, sizeof(sUID));
			menu.AddItem(sUID, sName);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Handler2(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Cmd_Addmin(client, 0);
			}
		}
		case MenuAction_Select:
		{
			char sInfo[64];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			int iTarget = GetClientUserId(StringToInt(sInfo));
			if (IsValidClient(iTarget))
			{
				GetClientAuthId(iTarget, AuthId_Steam2, g_sTargetGivenSteamID[client], sizeof(g_sTargetGivenSteamID[]));
				GetClientName(iTarget, g_sTargetName[client], sizeof(g_sTargetName[]));
				g_iCGB[client] = 1;
				SearchInCfg(client);
			}
		}
	}
}

void SearchInCfg(int client)
{
	BuildPath(Path_SM, g_sKvPath, sizeof(g_sKvPath), "configs/admins.cfg");
	KeyValues KvAdmins = new KeyValues("Admins");
	KvAdmins.ImportFromFile(g_sKvPath);
	char sFileSteamID[64], sMenuItem[64];
	bool bFound;
	Menu menu = new Menu(Menu_Handler3);
	menu.SetTitle("Info about this player");
	if (KvAdmins.GotoFirstSubKey())
	{
		KvAdmins.GetString("identity", sFileSteamID, sizeof(sFileSteamID));
		if (StrEqual(g_sTargetGivenSteamID[client], sFileSteamID))
		{
			KvAdmins.GetString("flags", g_sTargetFlagsRegistred[client], sizeof(g_sTargetFlagsRegistred[]));
			KvAdmins.GetSectionSymbol(g_iTargetSymbol[client]);
			bFound = true;
		}
		while (KvAdmins.GotoNextKey() && !bFound)
		{
			KvAdmins.GetString("identity", sFileSteamID, sizeof(sFileSteamID));
			if (StrEqual(g_sTargetGivenSteamID[client], sFileSteamID))
			{
				KvAdmins.GetString("flags", g_sTargetFlagsRegistred[client], sizeof(g_sTargetFlagsRegistred[]));
				KvAdmins.GetSectionSymbol(g_iTargetSymbol[client]);
				bFound = true;
			}
		}
	}
	if (bFound)
	{
		bFound = false;
		if (g_iCGB[client] != 3)
		{
			PrintToChat(client, "\x04[Addmin]\x03This player is in admin list");
		}
		g_bTargetHasFlags[client] = true;
		Format(sMenuItem, sizeof(sMenuItem), "His flags are: %s", g_sTargetFlagsRegistred[client]);
		menu.AddItem("-", sMenuItem, ITEMDRAW_DISABLED);
		Format(sMenuItem, sizeof(sMenuItem), "His SteamID: %s", g_sTargetGivenSteamID[client]);
		menu.AddItem("-", sMenuItem, ITEMDRAW_DISABLED);
		menu.AddItem("-", "------", ITEMDRAW_DISABLED);
		menu.AddItem("1", "Modify his flags");
	}
	else
	{
		PrintToChat(client, "\x04[Addmin]\x03This player is not in admin list");
		Format(sMenuItem, sizeof(sMenuItem), "His flags are: Ø");
		menu.AddItem("-", sMenuItem, ITEMDRAW_DISABLED);
		Format(sMenuItem, sizeof(sMenuItem), "His SteamID: %s", g_sTargetGivenSteamID[client]);
		menu.AddItem("-", sMenuItem, ITEMDRAW_DISABLED);
		menu.AddItem("-", "------", ITEMDRAW_DISABLED);
		menu.AddItem("1", "Modify his flags");
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	delete KvAdmins;
}

public int Menu_Handler3(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				switch (g_iCGB[client])
				{
					case 1: InGamePlayersMenu(client);
					case 2: delete menu;
					case 3: AdminFileMenu(client);
				}
			}
		}
		case MenuAction_Select:
		{
			char sInfo[64];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			if (StrEqual(sInfo, "1"))
			{
				ChooseFlagMenu(client);
			}
		}
	}
}

void ChooseFlagMenu(int client)
{
	Menu menu = new Menu(Menu_Handler4);
	char sMenuTitle[64];
	!StrEqual(g_sTargetName[client], "") ? Format(sMenuTitle, sizeof(sMenuTitle), "Flags of %s", g_sTargetName[client]) : Format(sMenuTitle, sizeof(sMenuTitle), "Flags of your target");
	menu.SetTitle(sMenuTitle);
	char sFlag[64];
	Format(sFlag, sizeof(sFlag), "[%s]Flag a: Reserved slots", (CheckFlags(client, "a") ? "x" : ""));
	menu.AddItem("a", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag b: Generic admin, required for admins", (CheckFlags(client, "b") ? "x" : ""));
	menu.AddItem("b", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag c: Kick other players", (CheckFlags(client, "c") ? "x" : ""));
	menu.AddItem("c", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag d: Banning other players", (CheckFlags(client, "d") ? "x" : ""));
	menu.AddItem("d", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag e: Removing bans", (CheckFlags(client, "e") ? "x" : ""));
	menu.AddItem("e", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag f: Slaying other players", (CheckFlags(client, "f") ? "x" : ""));
	menu.AddItem("f", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag g: Changing the map", (CheckFlags(client, "g") ? "x" : ""));
	menu.AddItem("g", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag h: Changing cvars", (CheckFlags(client, "h") ? "x" : ""));
	menu.AddItem("h", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag i: Changing configs", (CheckFlags(client, "i") ? "x" : ""));
	menu.AddItem("i", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag j: Special chat privileges", (CheckFlags(client, "j") ? "x" : ""));
	menu.AddItem("j", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag k: Voting", (CheckFlags(client, "k") ? "x" : ""));
	menu.AddItem("k", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag l: Password the server", (CheckFlags(client, "l") ? "x" : ""));
	menu.AddItem("l", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag m: Remote console", (CheckFlags(client, "m") ? "x" : ""));
	menu.AddItem("m", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag n: Change sv_cheats and related commands", (CheckFlags(client, "n") ? "x" : ""));
	menu.AddItem("n", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag o: custom1", (CheckFlags(client, "o") ? "x" : ""));
	menu.AddItem("o", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag p: custom2", (CheckFlags(client, "p") ? "x" : ""));
	menu.AddItem("p", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag q: custom3", (CheckFlags(client, "q") ? "x" : ""));
	menu.AddItem("q", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag r: custom4", (CheckFlags(client, "r") ? "x" : ""));
	menu.AddItem("r", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag s: custom5", (CheckFlags(client, "s") ? "x" : ""));
	menu.AddItem("s", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag t: custom6", (CheckFlags(client, "t") ? "x" : ""));
	menu.AddItem("t", sFlag);
	Format(sFlag, sizeof(sFlag), "[%s]Flag z: root", (CheckFlags(client, "z") ? "x" : ""));
	menu.AddItem("z", sFlag);
	menu.AddItem("1", "Save these flags");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

bool CheckFlags(int client, char[] flag)
{
	return StrContains(g_sTargetFlagsRegistred[client], flag, false) != -1;
}

public int Menu_Handler4(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			char sInfo[64];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			if (!StrEqual(sInfo, "1"))
			{
				StrContains(g_sTargetFlagsRegistred[client], sInfo, false) != -1 ? ReplaceString(g_sTargetFlagsRegistred[client], sizeof(g_sTargetFlagsRegistred[]), sInfo, "", false) : Format(g_sTargetFlagsRegistred[client], sizeof(g_sTargetFlagsRegistred[]), "%s%s", g_sTargetFlagsRegistred[client], sInfo);
				ChooseFlagMenu(client);
			}
			else
			{
				g_bTargetHasFlags[client] ? StartReWrite(client) : (!StrEqual(g_sTargetName[client], "", false) ? StartWrite(client) : PreStartWrite(client));
			}
		}
	}
}

void SteamIDTool(int client)
{
	PrintToChat(client, "\x04[Addmin]\x03Now type the SteamID of the player in the chat (STEAM_0:1234....)");
	g_bClientCanSayID[client] = true;
}

public Action Command_Say(int client, const char[] command, int argc)
{
	char sArgs[64];
	GetCmdArgString(sArgs, sizeof(sArgs));
	if (g_bClientCanSayID[client])
	{
		if (StrContains(sArgs, "STEAM_", false) != -1)
		{
			g_bClientCanSayID[client] = false;
			ReplaceString(sArgs, sizeof(sArgs), " ", "", false);
			ReplaceString(sArgs, sizeof(sArgs), "\"", "", false);
			Format(g_sTargetGivenSteamID[client], sizeof(g_sTargetGivenSteamID[]), "%s", sArgs);
			g_iCGB[client] = 2;
			SearchInCfg(client);
			return Plugin_Handled;
		}
		else
		{
			if (StrContains(sArgs, "cancel", false) != -1)
			{
				ReplaceString(sArgs, sizeof(sArgs), "\"", "", false);
				PrintToChat(client, "\x04[Addmin]\x03Canceled");
				InitialiseCl(client);
				return Plugin_Handled;
			}
			else
			{
				PrintToChat(client, "\x04[Addmin]\x03Fail, try again (type cancel or !cancel to stop)");
				return Plugin_Handled;
			}
		}	
	}
	if (g_bClientCanSayName[client])
	{
		if (StrContains(sArgs, "cancel", false) != -1)
		{
			PrintToChat(client, "\x04[Addmin]\x03Canceled");
			InitialiseCl(client);
			return Plugin_Handled;
		}
		else
		{
			g_bClientCanSayName[client] = false;
			ReplaceString(sArgs, sizeof(sArgs), "\"", "", false);
			Format(g_sTargetName[client], sizeof(g_sTargetName[]), "%s", sArgs);
			StartWrite(client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

void PreStartWrite(int client)
{
	PrintToChat(client, "\x04[Addmin]\x03Now type the name of the player in the chat!");
	g_bClientCanSayName[client] = true;
}	

void StartWrite(int client)
{
	BuildPath(Path_SM, g_sKvPath, sizeof(g_sKvPath), "configs/admins.cfg");
	KeyValues KvAdmins = CreateKeyValues("Admins");
	KvAdmins.ImportFromFile(g_sKvPath);
	if (KvAdmins.JumpToKey(g_sTargetName[client], true))
	{
		KvAdmins.SetString("auth", "steam");
		KvAdmins.SetString("identity", g_sTargetGivenSteamID[client]);
		KvAdmins.SetString("flags", g_sTargetFlagsRegistred[client]);
		KvAdmins.Rewind();
		KvAdmins.ExportToFile(g_sKvPath);
		PrintToChat(client, "\x04[Addmin]\x03 Admin succesfully created with flags: \"%s\"!", g_sTargetFlagsRegistred[client]);
	}
	InitialiseCl(client);
	if (g_cvSQL.IntValue == 1)
	{
		DumpAdminCache(AdminCache_Admins, true);
	}
	delete KvAdmins;
}

void StartReWrite(int client)
{
	BuildPath(Path_SM, g_sKvPath, sizeof(g_sKvPath), "configs/admins.cfg");
	KeyValues KvAdmins = CreateKeyValues("Admins");
	KvAdmins.ImportFromFile(g_sKvPath);
	if (KvAdmins.JumpToKeySymbol(g_iTargetSymbol[client]))
	{
		KvAdmins.SetString("flags", g_sTargetFlagsRegistred[client]);
		PrintToChat(client, "\x04[Addmin]\x03Player flags succesfully changed to \"%s\"!", g_sTargetFlagsRegistred[client]);
		KvAdmins.Rewind();
		KvAdmins.ExportToFile(g_sKvPath);
	}
	InitialiseCl(client);
	if (g_cvSQL.IntValue == 1)
	{
		DumpAdminCache(AdminCache_Admins, true);
	}
	delete KvAdmins;
}

void AdminFileMenu(int client)
{
	BuildPath(Path_SM, g_sKvPath, sizeof(g_sKvPath), "configs/admins.cfg");
	KeyValues KvAdmins = new KeyValues("Admins");
	KvAdmins.ImportFromFile(g_sKvPath);
	char sFileName[64], sFileSteamID[64], sFileFlags[64];
	Menu menu = new Menu(Menu_Handler6);
	menu.SetTitle("List of all admins of the server");
	if (KvAdmins.GotoFirstSubKey())
	{
		KvAdmins.GetSectionName(sFileName, sizeof(sFileName));
		KvAdmins.GetString("identity", sFileSteamID, sizeof(sFileSteamID));
		KvAdmins.GetString("flags", sFileFlags, sizeof(sFileFlags));
		menu.AddItem(sFileSteamID, sFileName);
		while (KvAdmins.GotoNextKey())
		{
			KvAdmins.GetSectionName(sFileName, sizeof(sFileName));
			KvAdmins.GetString("identity", sFileSteamID, sizeof(sFileSteamID));
			KvAdmins.GetString("flags", sFileFlags, sizeof(sFileFlags));
			menu.AddItem(sFileSteamID, sFileName);
		}
	}
	delete KvAdmins;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Handler6(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Cmd_Addmin(client, 0);
			}
		}
		case MenuAction_Select:
		{
			char sInfo[64];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			Format(g_sTargetGivenSteamID[client], sizeof(g_sTargetGivenSteamID[]), sInfo);
			g_iCGB[client] = 3;
			SearchInCfg(client);
		}
	}
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}