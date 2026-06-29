#include <sourcemod>
#include <sdktools>
#include <adminmenu>

#define PLUGIN_NAME "ND Commander Actions"
#define PLUGIN_VERSION "1.3"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Xander (Player 1)",
	description = "A rewrite of 1Swat's 'Commander Management' using keyvalues instead of SQL to save bans.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=192858"
}

#define BANTYPE_NOTBANNED -2
#define BANTYPE_UNKNOWN -1
#define BANTYPE_PERMANENT 0

new Handle:hAdminMenu = INVALID_HANDLE,
	g_CommanderBans[MAXPLAYERS+1] = {-1,...},
	g_BanQueue[MAXPLAYERS+1],
	String:g_sKeyValuesPath[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	CreateConVar("sm_nd_commander_actions_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	RegAdminCmd("sm_setcommander", Cmd_SetCommander, ADMFLAG_SLAY, "<Name|#UserID> - Promote a player to commander.");
	RegAdminCmd("sm_demotecommander", Cmd_Demote, ADMFLAG_SLAY, "<ct | emp> - Remove a team's commander.");
	RegAdminCmd("sm_bancommander", Cmd_BanCommander, ADMFLAG_BAN, "<minutes> <Name|#UserID|SteamID> - Ban connected players from commanding.");
	RegAdminCmd("sm_unbancommander", Cmd_UnBan, ADMFLAG_BAN, "<Name|#UserID|SteamID> - Remove a SteamID from the ban list. (Unban by name only works on connected players.)");
	RegAdminCmd("sm_listcommanderbans", Cmd_ListBans, ADMFLAG_GENERIC, "Prints all commander bans in a list format.");
	
	AddCommandListener(CommandListener:CMD_Apply, "applyforcommander");
	
	LoadTranslations("common.phrases"); //required for FindTarget
	
	
	BuildPath(Path_SM, g_sKeyValuesPath, PLATFORM_MAX_PATH, "commanderbans.txt");
	
	if (!FileExists(g_sKeyValuesPath))
	{
		new Handle:fileHandle = OpenFile(g_sKeyValuesPath,"w");
		CloseHandle(fileHandle);
	}
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);
}
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		hAdminMenu = INVALID_HANDLE;
}
public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
		return;
	
	hAdminMenu = topmenu;
	
	new TopMenuObject:CMCategory = AddToTopMenu(topmenu, "Commander Actions", TopMenuObject_Category, CategoryHandler, INVALID_TOPMENUOBJECT);
	AddToTopMenu(topmenu, "Set Commander", TopMenuObject_Item, CMHandleSETCommander, CMCategory, "sm_setcommander", ADMFLAG_SLAY);
	AddToTopMenu(topmenu, "Demote Commander", TopMenuObject_Item, CMHandleDEMOTECommander, CMCategory, "sm_demotecommander", ADMFLAG_SLAY);
	AddToTopMenu(topmenu, "Ban Commander", TopMenuObject_Item, CMHandleBANCommander, CMCategory, "sm_bancommander", ADMFLAG_BAN);
	AddToTopMenu(topmenu, "Unban Commander", TopMenuObject_Item, CMHandleUNBANCommander, CMCategory, "sm_unbancommander", ADMFLAG_BAN);
}

public Action:Cmd_SetCommander(client, args)
{
	if (!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setcommander <Name|#Userid>");
		return Plugin_Handled;
	}
	
	decl String:arg1[64]
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new target = FindTarget(client, arg1, true, true);
	
	if (target == -1)
	{}
	
	else
		PerformPromote(client, target);
	
	return Plugin_Handled;
}

public Action:Cmd_Demote(client, args)
{
	if (!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_demotecommander <ct | emp>");
		return Plugin_Handled;
	}
	
	new target = -1;
	decl String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (StrEqual(arg1, "ct", false))
		target = GameRules_GetPropEnt("m_hCommanders", 0);
	
	else if (StrEqual(arg1, "emp", false))
		target = GameRules_GetPropEnt("m_hCommanders", 1);
	
	else
	{
		ReplyToCommand(client, "[SM] Unknown argument: %s. Usage: sm_demotecommander <ct | emp>", arg1);
		return Plugin_Handled;
	}
	
	
	if (target == -1)
		ReplyToCommand(client, "[SM] No commander on team %s", arg1);
	
	else
		PerformDemote(client, target);
	
	return Plugin_Handled;
}

public Action:Cmd_BanCommander(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_bancommander <minutes> <Name|#Userid|SteamID>");
		return Plugin_Handled;
	}
	
	decl String:text[128], String:arg1[64], String:arg2[64];
	new target;
	
	GetCmdArgString(text, sizeof(text));
	new len = BreakString(text, arg1, sizeof(arg1));
	BreakString(text[len], arg2, sizeof(arg2));
	
	if (StrContains(arg2, "STEAM_1:") != -1)
	{
		StripQuotes(arg2);
		TrimString(arg2);
		target = -1;
	}
	else
	{
		target = FindTarget(client, arg2, true, true);
		if (target == -1)
			return Plugin_Handled;
		
		GetClientAuthString(target, arg2, sizeof(arg2));
	}
	
	new BanTime = StringToInt(arg1);
	
	if (BanTime < 0 || BanTime > 5256000)
		BanTime = 0;
	
	PerformCommanderBan(client, target, arg2, BanTime);
	return Plugin_Handled;
}

public Action:Cmd_UnBan(client, args)
{
	if (!args)
	{
		ReplyToCommand(client, "Usage: sm_unbancommander <Name|#Userid|SteamID>");
		return Plugin_Handled;
	}
	
	decl String:arg1[64];
	new target;
	GetCmdArgString(arg1, sizeof(arg1));
	
	if (StrContains(arg1, "STEAM_1:0:") != -1)
	{
		StripQuotes(arg1);
		TrimString(arg1);
		target = -1;
	}
	else
	{
		target = FindTarget(client, arg1, true, true);
		if (target == -1)
			return Plugin_Handled;
		
		GetClientAuthString(target, arg1, sizeof(arg1));
	}
	
	PerformUnban(client, target, arg1, GetCmdReplySource());
	return Plugin_Handled;
}

public Action:CMD_Apply(client, const String:command[], args)
{
	if (!client)
		return Plugin_Handled;
	
	//check if client is banned
	if (g_CommanderBans[client] == BANTYPE_UNKNOWN)
	{
		decl String:authid[32];
		GetClientAuthString(client, authid, sizeof(authid));
		
		new Handle:kv = CreateKeyValues("bans");
		FileToKeyValues(kv, g_sKeyValuesPath);
		
		if (KvJumpToKey(kv, authid, false))
		{
			new unbantime = KvGetNum(kv, "unbantime", -1);
			
			if (unbantime == -1)
				g_CommanderBans[client] = BANTYPE_PERMANENT;
			
			else
				g_CommanderBans[client] = unbantime;
		}
		else
			g_CommanderBans[client] = BANTYPE_NOTBANNED;

		CloseHandle(kv);
	}
	
	if (g_CommanderBans[client] == BANTYPE_NOTBANNED)
		return Plugin_Continue;
	
	//player is banned.. tell them so. 0 = perm ban, any > 0 == Unban Time (Unix stamp).
	if (g_CommanderBans[client] == BANTYPE_PERMANENT)
		PrintToChat(client, "[SM] You are permanently banned from commanding.");
	
	else if (g_CommanderBans[client] > BANTYPE_PERMANENT)
	{
		decl String:FormatedTime[100];
		FormatTime(FormatedTime, sizeof(FormatedTime), "%d %b %Y - %X %Z", g_CommanderBans[client]);
		PrintToChat(client, "[SM] You are banned from commanding until %s.", FormatedTime);
	}
	
	return Plugin_Handled;
}

PerformPromote(client, target)
{
	ServerCommand("_promote_to_commander %d", target);
	LogAction(client, target, "\"%L\" promoted \"%L\" to commander.", client, target);
	ShowActivity2(client, "[SM] ", "Promoted %N to commander.", target);
}

PerformDemote(client, target) {
	if (target == -1)
		return;
	
	LogAction(client, target, "\"%L\" demoted \"%L\" from commander.", client, target);
	FakeClientCommand(target, "startmutiny");
	FakeClientCommand(target, "rtsview");
	ShowActivity2(client, "[SM] ", "Demoted %N from commander.",target);
}

PerformCommanderBan(client, target, const String:authid[], BanTime)
{	
	new Handle:kv = CreateKeyValues("bans"), UnbanTime;
	FileToKeyValues(kv, g_sKeyValuesPath);
	
	KvJumpToKey(kv, authid, true);
	
	if (target != -1)
	{
		decl String:name[64];
		GetClientName(target, name, sizeof(name));
		KvSetString(kv, "name", name);
	}
		
	if (BanTime != 0)
	{
		UnbanTime = BanTime * 60 + GetTime();
		KvSetNum(kv, "unbantime", UnbanTime);
	}
	else
		KvSetNum(kv, "unbantime", -1);
	
	KvRewind(kv);
	KeyValuesToFile(kv, g_sKeyValuesPath);
	CloseHandle(kv);
	
	if (target != -1)
	{
		if (GetClientTeam(target) > 1 && target == GameRules_GetPropEnt("m_hCommanders", GetClientTeam(target) - 2))
			FakeClientCommand(target, "startmutiny");

		FakeClientCommand(target, "unapplyforcommander");
		
		if (BanTime != 0)
		{
			g_CommanderBans[target] = UnbanTime;
			ShowActivity2(client, "[SM] ", "Banned %N from commanding for %d minutes.", target, BanTime);
			LogAction(client, target, "\"%L\" banned \"%L\" from commanding. (Time: %d minutes)", client, target, BanTime);
		}
		else
		{
			g_CommanderBans[target] = BANTYPE_PERMANENT;
			ShowActivity2(client, "[SM] ", "Permanently banned %N from commanding.", target);
			LogAction(client, target, "\"%L\" permanently banned \"%L\" from commanding.", client, target);
		}
	}
	else
	{
		LogAction(client, -1, "\"%L\" banned identity <%s> from commanding.", client, authid);
		ShowActivity2(client, "[SM] ", "Added commander ban on identity <%s>", authid);
	}
}

PerformUnban(client, target, const String:authid[], ReplySource:source)
{
	new Handle:kv = CreateKeyValues("bans");
	FileToKeyValues(kv, g_sKeyValuesPath);
	
	if (KvJumpToKey(kv, authid, false))
	{
		decl String:targetName[64];
		KvGetString(kv, "name", targetName, sizeof(targetName), "");
		KvDeleteThis(kv);
		KvRewind(kv);
		KeyValuesToFile(kv, g_sKeyValuesPath);
		ShowActivity2(client, "[SM] ", "Removed commander ban on %s <%s>", targetName, authid);
		LogAction(client, -1, "\"%L\" removed a commander ban on identity <%s> <%s>", client, targetName, authid);
		if (target != -1)
			g_CommanderBans[target] = BANTYPE_NOTBANNED;
	}
	else
	{
		source = SetCmdReplySource(ReplySource:source);
		ReplyToCommand(client, "No ban on SteamId: <%s>. (Unban by name only works on connected players.)", authid);
		SetCmdReplySource(ReplySource:source);
	}
	CloseHandle(kv);
}

public OnMapEnd()
{
	RemoveExpiredBans();
}
RemoveExpiredBans()
{
	new CurrentTime = GetTime(), UnbanTime, Handle:kv = CreateKeyValues("bans");
	FileToKeyValues(kv, g_sKeyValuesPath);
	
	if (KvGotoFirstSubKey(kv, true))
	{
		for (;;)
		{
			UnbanTime = KvGetNum(kv, "unbantime", -1);
			
			//perm banned; ignore and move to the next key, or break the loop if no more keys
			if (UnbanTime == -1 && !KvGotoNextKey(kv, true))
				break;
			
			//ban expired; delete the key and break the loop if no more keys
			else if (CurrentTime >= UnbanTime && KvDeleteThis(kv) < 1)
				break;
			
			//ban has not expired
			else if (!KvGotoNextKey(kv, true))
				break;
		
		}
	}
	
	KvRewind(kv);
	KeyValuesToFile(kv, g_sKeyValuesPath);
	CloseHandle(kv);
}

public OnClientDisconnect(client)
{
	g_CommanderBans[client] = -1;
}

public Action:Cmd_ListBans(client, args)
{
	new ReplySource:Source;
	if (client)
		Source = SetCmdReplySource(SM_REPLY_TO_CONSOLE);
	
	decl String:name[64], String:authid[64], String:FormatedTime[100];
	new Handle:kv = CreateKeyValues("bans"), UnbanTime;
	FileToKeyValues(kv, g_sKeyValuesPath);
	
	if (KvGotoFirstSubKey(kv, true))
	{
		ReplyToCommand(client, "** List of commander bans: **");
		ReplyToCommand(client, "SteamID -- Name -- Banned Until");
		ReplyToCommand(client, "");
		
		do
		{
			KvGetSectionName(kv, authid, sizeof(authid));
			KvGetString(kv, "name", name, sizeof(name), "UNKNOWN");
			UnbanTime = KvGetNum(kv, "unbantime", -1);
			
			if (UnbanTime == -1)
				Format(FormatedTime, sizeof(FormatedTime), "Permanent");
			else
				FormatTime(FormatedTime, sizeof(FormatedTime), "%d %b %Y - %X %Z", UnbanTime);
			
			ReplyToCommand(client, "# %s    %s    %s", authid, name, FormatedTime);
		
		} while (KvGotoNextKey(kv, true))
		
		ReplyToCommand(client, "");
		ReplyToCommand(client, "** End Ban List **");
		
		if (client && Source == SM_REPLY_TO_CHAT)
			PrintToChat(client, "[SM] See console for output.");
	}
	
	else
	{
		SetCmdReplySource(Source)
		ReplyToCommand(client, "No Bans!");
	}
	
	CloseHandle(kv);
	return Plugin_Handled;
}
	
//=========MENU HANDLERS====================================================

public CategoryHandler(Handle:topmenu, 
				TopMenuAction:action,
				TopMenuObject:object_id,
				param,
				String:buffer[],
				maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "Commander Actions:");
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Commander Actions");
	}
}

// Set Commander Menu Handlers
public CMHandleSETCommander(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Set");
	
	else if (action == TopMenuAction_SelectOption)
	{
		new Handle:menu = CreateMenu(Handle_SetCommander_SelectTeam);
		SetMenuTitle(menu, "Select a Team:");
		AddMenuItem(menu, "2", "Consortium");
		AddMenuItem(menu, "3", "Empire");
		DisplayMenu(menu, param, MENU_TIME_FOREVER);
	}
}
public Handle_SetCommander_SelectTeam(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:item[8]
		GetMenuItem(menu, param2, item, sizeof(item));
		Display_SetCommander_TeamList(param1, StringToInt(item));
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}
Display_SetCommander_TeamList(client, SelectedTeam)
{
	decl String:UserID[8], String:Name[64]
	new Handle:menu = CreateMenu(Handle_SetCommander_ClientSelection);
	SetMenuTitle(menu, "Select A Player:");
	
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			if (!IsFakeClient(i) && GetClientTeam(i) == SelectedTeam && CanUserTarget(client, i))
			{
				IntToString(GetClientUserId(i), UserID, sizeof(UserID));
				GetClientName(i, Name, sizeof(Name));
				AddMenuItem(menu, UserID, Name);
			}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public Handle_SetCommander_ClientSelection(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:item[8];
		GetMenuItem(menu, param2, item, sizeof(item));
		new target = StringToInt(item);
		target = GetClientOfUserId(target);
	
		if (target)
			PerformPromote(param1, target)
		
		else
			PrintToChat(param1, "[SM] That player is no longer available.");
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

// Demote Commander Menu Handlers
public CMHandleDEMOTECommander(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Demote");
	
	else if (action == TopMenuAction_SelectOption)
	{
		new Handle:menu = CreateMenu(Handle_DemoteCommander_SelectTeam);
		SetMenuTitle(menu, "Demote Which Commander?");
		
		if (GameRules_GetPropEnt("m_hCommanders", 0) == -1)
			AddMenuItem(menu, "", "Consortium", ITEMDRAW_DISABLED);
		
		else
			AddMenuItem(menu, "0", "Consortium");
				
		if (GameRules_GetPropEnt("m_hCommanders", 1) == -1)
			AddMenuItem(menu, "1", "Empire", ITEMDRAW_DISABLED);
		
		else
			AddMenuItem(menu, "1", "Empire");
		
		DisplayMenu(menu, param, MENU_TIME_FOREVER);
	}
}
public Handle_DemoteCommander_SelectTeam(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select)
	{
		decl String:item[8];
		GetMenuItem(menu, param2, item, sizeof(item));
		new target = GameRules_GetPropEnt("m_hCommanders", StringToInt(item));
		
		if (target == -1)
			return;
		
		if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] You cannon target this client.");
			return;
		}
		
		PerformDemote(param1, GameRules_GetPropEnt("m_hCommanders", StringToInt(item)));
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

//Ban Commander Menu Handlers
public CMHandleBANCommander(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Ban");
	
	else if (action == TopMenuAction_SelectOption)
	{
		new Handle:menu = CreateMenu(Handle_BanCommander_SelectPlayer), i;
		decl Commanders[2], String:UserID[8], String:Name[64];
		
		Commanders[0] = GameRules_GetPropEnt("m_hCommanders", 0);
		Commanders[1] = GameRules_GetPropEnt("m_hCommanders", 1);
		
		SetMenuTitle(menu, "Select A Player To Ban:");
		
		//put both commanders at the top of the list
		for (i = 0; i <= 1; i++)
			if (Commanders[i] != -1 && CanUserTarget(param, Commanders[i]))
			{
				IntToString(GetClientUserId(Commanders[i]), UserID, 8);
				GetClientName(Commanders[i], Name, 64);
				AddMenuItem(menu, UserID, Name);
			}
		
		//add the rest of the clients
		for (i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i) && CanUserTarget(param, i) && i != Commanders[0] && i != Commanders[1])
			{
				IntToString(GetClientUserId(i), UserID, 8);
				GetClientName(i, Name, 64);
				AddMenuItem(menu, UserID, Name);
			}
		
		DisplayMenu(menu, param, MENU_TIME_FOREVER);
	}
}
public Handle_BanCommander_SelectPlayer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:item[8];
		GetMenuItem(menu, param2, item, sizeof(item));
		g_BanQueue[param1] = StringToInt(item);
		DisplayMenu_BanCommander_SelectBanTime(param1);
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}
DisplayMenu_BanCommander_SelectBanTime(client)
{
	new Handle:menu = CreateMenu(Handle_BanCommander_SelectBanTime);
	SetMenuTitle(menu, "Ban For How Long?");
	AddMenuItem(menu, "-1", "This Map");
	AddMenuItem(menu, "60", "1 Hour");
	AddMenuItem(menu, "300", "5 Hours");
	AddMenuItem(menu, "1440", "1 Day");
	AddMenuItem(menu, "10080", "1 Week");
	AddMenuItem(menu, "43200", "1 Month");
	AddMenuItem(menu, "0", "Permanently");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public Handle_BanCommander_SelectBanTime(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
		decl String:item[8];
		GetMenuItem(menu, param2, item, sizeof(item));
		new BanTime = StringToInt(item),
			target = GetClientOfUserId(g_BanQueue[param1]);
		
		if (target)
		{
			if (BanTime == -1)
			{
				g_CommanderBans[target] = 0;
				if (GetClientTeam(target) > 1 && target == GameRules_GetPropEnt("m_hCommanders", GetClientTeam(target) - 2))
					FakeClientCommand(target, "startmutiny");
				
				FakeClientCommand(target, "unapplyforcommander");
				ShowActivity2(param1, "[SM] ", "Banned %N from commanding for the length of this map.", target);
			}
			else
			{
				decl String:authid[32];
				GetClientAuthString(target, authid, sizeof(authid));
				PerformCommanderBan(param1, target, authid, BanTime);
			}
		}
		else
			PrintToChat(param1, "[SM] That player is no longer available.");
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

//Unban Commander Menu Handlers
public CMHandleUNBANCommander(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Unban");
	
	else if (action == TopMenuAction_SelectOption)
	{
		decl String:name[64], String:authid[64];
		new Handle:menu = CreateMenu(Handle_UnBanCommander_SelectPlayer), Handle:kv = CreateKeyValues("bans");
		SetMenuTitle(menu, "Remove A Commander Ban:");
		
		FileToKeyValues(kv, g_sKeyValuesPath);
		
		if (KvGotoFirstSubKey(kv, true))
			do
			{
				KvGetSectionName(kv, authid, sizeof(authid));
				KvGetString(kv, "name", name, sizeof(name), "");				
				
				if (StrEqual(name, ""))
					AddMenuItem(menu, authid, authid);
				
				else
					AddMenuItem(menu, authid, name);
				
			} while (KvGotoNextKey(kv, true));
		
		else
			AddMenuItem(menu, "", "No Bans!", ITEMDRAW_DISABLED);
		
		DisplayMenu(menu, param, MENU_TIME_FOREVER);
		CloseHandle(kv);
	}
}
public Handle_UnBanCommander_SelectPlayer(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select)
	{
		decl String:item[64];
		GetMenuItem(menu, param2, item, sizeof(item));
		PerformUnban(param1, -1, item, SM_REPLY_TO_CHAT);
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}