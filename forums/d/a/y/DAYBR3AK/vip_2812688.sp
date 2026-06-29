#include <sourcemod>
#include <regex>
#include <string>
#include <colors>

#define PLUGIN_AUTHOR "DAYBR3AK1999"
#define PLUGIN_VERSION "3.0"

ConVar gCvarDonateUrl;
ConVar gCvarAdminPanelUrl;
ConVar gCvarShowMenuOnConnect;
ConVar gCvarEnableTrial;

public Plugin:myinfo = 
{
	name = "Automated VIP System",
	author = PLUGIN_AUTHOR,
	description = "Automated Sourcebans VIP Trial Plugin where commands are used to become VIP.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=344460"
};

bool usedViptest[MAXPLAYERS + 1];
int spamblock[MAXPLAYERS + 1];
int spamblock_viptest[MAXPLAYERS + 1];

native SQL_ReadCallback(Handle:query, const FunctionName[], any:DataTuple = 0);

public void OnRebuildAdminCache(AdminCachePart part)
{
    switch(part)
    {
        case AdminCache_Admins:
        {
            if(SQL_CheckConfig("sourcebans"))
            {
				Database DB = SQL_Connect("sourcebans", false, "", 0);
				Connect_callback(null, DB, "", 0);
            }
        }
    }
}

void RefreshAdminCache()
{
    ServerCommand("sm_reloadadmins");
}

public void OnClientAuthorized(int client)
{
    if (!IsValidClient(client)) return;

    char steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

    if (!SQL_CheckConfig("sourcebans"))
        return;

    Database db = SQL_Connect("sourcebans", false, "", 0);
    if (db == null)
    {
        LogError("[VIP] Failed to connect to database in OnClientAuthorized()");
        return;
    }

    char query[300];
    Format(query, sizeof(query), "SELECT viptest_used FROM sb_vip_system WHERE steamid = '%s'", steamid);
    SQL_TQuery(db, OnClientAuthorized_QueryCallback, query, client, DBPrio_Low);

    delete db;
}

public void OnClientAuthorized_QueryCallback(Handle owner, Handle hndl, const char[] error, any client)
{
    if(hndl == null)
    {
        SetFailState("ERROR - %s", error);
    }

    if (SQL_FetchRow(hndl))
    {
        int viptest_used_db = SQL_FetchInt(hndl, 0);
        usedViptest[client] = viptest_used_db == 1;
    }
    else
    {
        usedViptest[client] = false;
    }
    
    delete hndl;
}

public void OnClientDisconnect(int client)
{
    spamblock[client] = 0;
    spamblock_viptest[client] = 0;
    usedViptest[client] = false;
}

bool IsValidClient(int client)
{
    return (1 <= client <= MaxClients)
        && IsClientInGame(client)
        && !IsFakeClient(client)
        && IsClientAuthorized(client);
}

void ResetUsedViptestArray()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        usedViptest[i] = false;
		spamblock[i] = 0;
        spamblock_viptest[i] = 0;
    }
}

public void OnPluginStart()
{
	LoadTranslations("vip.phrases");
    if (!SQL_CheckConfig("sourcebans")) {
        SetFailState("[SM] Invalid sourcebans database configuration.");
        return;
    }
	
	gCvarAdminPanelUrl = CreateConVar("sm_vip_adminpanel_url", "", "URL of the VIP admin web panel");
	gCvarDonateUrl = CreateConVar("sm_vip_donate_url", "", "Donation URL to open when selecting Donate");
	gCvarShowMenuOnConnect = CreateConVar("sm_vip_show_menu_on_connect", "0", "Show !vipmenu to players on first connect", FCVAR_NONE, true, 0.0, true, 1.0);
	gCvarEnableTrial = CreateConVar("sm_vip_enable_trial", "1", "Enable/Disable VIP Trial Command (!viptest)", FCVAR_NONE, true, 0.0, true, 1.0);
	AutoExecConfig(true, "vip");
    
	RegConsoleCmd("sm_vipmenu", vipmenu);
    RegConsoleCmd("sm_vip_code", vip_code);
    RegConsoleCmd("sm_viptest", viptest);
    RegConsoleCmd("sm_myvipcode", myvipcode);
    RegConsoleCmd("sm_vipstatus", vipstatus);
	RegConsoleCmd("sm_vipadmin", vipadmin_menu);
    
    ResetUsedViptestArray();

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i))
        {
            ClientConnect_Post(i);
            OnClientPostAdminCheck(i);
        }
    }
    OnRebuildAdminCache(AdminCache_Admins);
    PreloadVIPStatus();
    CreateTimer(60.0, Timer_CheckForExpiredVipCodes, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CheckForExpiredVipCodes(Handle timer) {
    CheckForExpiredVipCodes();
    return Plugin_Continue;
}

public void OnMapStart() {
    CheckForExpiredVipCodes();
}

public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast) {
    CheckForExpiredVipCodes();
}

public void CheckForExpiredVipCodes() {
    Database DB = SQL_Connect("sourcebans", false, "", 0);
    if (DB == null) {
        LogError("Failed to connect to the database.");
        return;
    }

    char query[300];
    Format(query, sizeof(query), "UPDATE sb_vip_system SET vip_group = NULL WHERE expire < NOW() AND vip_group = 'vip'");
    
    LogMessage("Running expired VIP codes check with query: %s", query);

    if (!SQL_FastQuery(DB, query)) {
        char error[256];
        SQL_GetError(DB, error, sizeof(error));
        LogError("SQL Error: %s", error);
    } else {
        LogMessage("Expired VIP codes have been updated.");
        RefreshAdminCache();
    }

    delete DB;
}

void PreloadVIPStatus()
{
    Database DB = SQL_Connect("sourcebans", false, "", 0);
    if (DB == null) return;

    char query[] = "SELECT steamid, viptest_used FROM sb_vip_system";
    SQL_TQuery(DB, PreloadVIPStatus_Callback, query, DBPrio_High);
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i))
        {
            CheckVipTestStatus(i);
        }
    }
}

void CheckVipTestStatus(int client)
{
    if (!IsValidClient(client)) return;

    char steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

    char buffer[300];
    Format(buffer, sizeof(buffer), "SELECT viptest_used FROM sb_vip_system WHERE steamid = '%s'", steamid);
    Database DB = SQL_Connect("sourcebans", false, "", 0);
    if (DB == null) return;

    SQL_TQuery(DB, OnClientAuthorized_QueryCallback, buffer, client, DBPrio_Low);
}

public void PreloadVIPStatus_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null)
    {

        return;
    }

    while (SQL_FetchRow(hndl))
    {
        char steamid[32];
        SQL_FetchString(hndl, 0, steamid, sizeof(steamid));
    }

    delete hndl;
}

public void ClientConnect_Post(int client)
{
    if (!IsValidClient(client)) {
        return;
    }
	
	if (gCvarShowMenuOnConnect.BoolValue && !usedViptest[client] && gCvarEnableTrial.BoolValue)
	{
		vipmenu(client, 0);
	}
}

public void OnClientPostAdminCheck(int client)
{
    if (!IsValidClient(client)) {
        return;
    }
}

bool HasUnusedVipCode(int client)
{
    char steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

    if (!SQL_CheckConfig("sourcebans")) return false;

    Database DB = SQL_Connect("sourcebans", false, "", 0);
    if (DB == null) return false;

    char query[256];
    Format(query, sizeof(query), "SELECT used FROM sb_vip_system WHERE steamid = '%s' AND viptest_used = 1", steamid);

    DBResultSet result = SQL_Query(DB, query);
    bool show = false;

    if (result != null && SQL_FetchRow(result))
    {
        int used = SQL_FetchInt(result, 0);
        show = (used == 0);
        delete result;
    }

    delete DB;
    return show;
}

public Action vipmenu(int client, int args)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    if (!SQL_CheckConfig("sourcebans")) return Plugin_Handled;

    char steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

    Database DB = SQL_Connect("sourcebans", false, "", 0);
    if (DB == null) return Plugin_Handled;

    char query[256];
    Format(query, sizeof(query), "SELECT 1 FROM sb_vip_system s LEFT JOIN sb_vip_groups g ON s.vip_group = g.vip_group WHERE s.steamid = '%s' AND g.info IS NOT NULL AND g.info != '' LIMIT 1", steamid);

    Handle pack = CreateDataPack();
    WritePackCell(pack, client);
    SQL_TQuery(DB, BuildVIPMenu_Callback, query, pack);

    delete DB;
    return Plugin_Handled;
}

public void BuildVIPMenu_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
    ResetPack(data);
    int client = ReadPackCell(data);
    CloseHandle(data);

    if (!IsClientInGame(client)) return;

    Menu menu = new Menu(VIPMenuHandler);
    char title[64];
    if (!Format(title, sizeof(title), "%T", "VIP_MENU_TITLE", client))
        strcopy(title, sizeof(title), "VIP Menu");
    menu.SetTitle(title);

    char text[64];
    if (gCvarEnableTrial.BoolValue)
    {
        if (!Format(text, sizeof(text), "%T", "VIP_MENU_CLAIM", client))
            strcopy(text, sizeof(text), "Claim VIP Trial");
        menu.AddItem("claim", text, usedViptest[client] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    }

    if (!Format(text, sizeof(text), "%T", "VIP_MENU_STATUS", client))
        strcopy(text, sizeof(text), "VIP Status");
    menu.AddItem("status", text);

	if (HasUnusedVipCode(client))
	{
		if (!Format(text, sizeof(text), "%T", "VIP_MENU_CODE", client))
			strcopy(text, sizeof(text), "Show My VIP Code");
		menu.AddItem("mycode", text);
	}

    char donateUrl[256];
    gCvarDonateUrl.GetString(donateUrl, sizeof(donateUrl));
    if (strlen(donateUrl) > 0)
    {
        if (!Format(text, sizeof(text), "%T", "VIP_MENU_DONATE", client))
            strcopy(text, sizeof(text), "Support Us / Donate");
        menu.AddItem("donate", text);
    }

    if (!Format(text, sizeof(text), "%T", "VIP_MENU_HELP", client))
        strcopy(text, sizeof(text), "What is VIP?");
    menu.AddItem("help", text);

    if (hndl != null && SQL_FetchRow(hndl))
    {
        if (!Format(text, sizeof(text), "%T", "VIP_MENU_BENEFITS", client))
			strcopy(text, sizeof(text), "VIP Advantages");
		menu.AddItem("benefits", text);
    }
	
    if (CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
    {
        if (!Format(text, sizeof(text), "%T", "VIP_ADMIN_TITLE", client))
            strcopy(text, sizeof(text), "VIP Admin Menu");
        menu.AddItem("adminmenu", text);
    }

    delete hndl;
    menu.Display(client, 15);
}

public void vipmenu_callback(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	CloseHandle(data);

	if (!IsClientInGame(client)) return;

	Menu menu = new Menu(VIPMenuHandler);

	char title[64];
	if (!Format(title, sizeof(title), "%T", "VIP_MENU_TITLE", client))
		strcopy(title, sizeof(title), "VIP Menu");
	menu.SetTitle(title);

	char text[64];

	if (gCvarEnableTrial.BoolValue)
	{
		if (!Format(text, sizeof(text), "%T", "VIP_MENU_CLAIM", client))
			strcopy(text, sizeof(text), "Claim VIP Trial");
		menu.AddItem("claim", text, usedViptest[client] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}

	if (!Format(text, sizeof(text), "%T", "VIP_MENU_STATUS", client))
		strcopy(text, sizeof(text), "VIP Status");
	menu.AddItem("status", text);

	if (HasUnusedVipCode(client))
	{
		if (!Format(text, sizeof(text), "%T", "VIP_MENU_CODE", client))
			strcopy(text, sizeof(text), "Show My VIP Code");
		menu.AddItem("mycode", text);
	}

	char donateUrl[256];
	gCvarDonateUrl.GetString(donateUrl, sizeof(donateUrl));
	if (strlen(donateUrl) > 0)
	{
		if (!Format(text, sizeof(text), "%T", "VIP_MENU_DONATE", client))
			strcopy(text, sizeof(text), "Support Us / Donate");
		menu.AddItem("donate", text);
	}

	if (!Format(text, sizeof(text), "%T", "VIP_MENU_HELP", client))
		strcopy(text, sizeof(text), "What is VIP?");
	menu.AddItem("help", text);
	
	if (hndl != null && SQL_FetchRow(hndl))
	{
		if (!Format(text, sizeof(text), "%T", "VIP_MENU_BENEFITS", client))
			strcopy(text, sizeof(text), "VIP Advantages");
		menu.AddItem("benefits", text);
	}

	if (CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		if (!Format(text, sizeof(text), "%T", "VIP_ADMIN_TITLE", client))
			strcopy(text, sizeof(text), "VIP Admin Menu");
		menu.AddItem("adminmenu", text);
	}

	delete hndl;
	menu.Display(client, 15);
}

public void AddVIPBenefitsButton_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	Handle hData = data;
	ResetPack(hData);
	int client = ReadPackCell(hData);
	Menu menu = ReadPackCell(hData);

	if (hndl == null || !IsClientInGame(client))
	{
		CloseHandle(hData);
		return;
	}

	if (SQL_FetchRow(hndl))
	{
		menu.AddItem("benefits", "Voir mes avantages VIP");
	}

	delete hndl;
	CloseHandle(hData);
}

public int VIPMenuHandler(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param, info, sizeof(info));

        if (StrEqual(info, "claim"))
        {
            viptest(client, 0);
        }
        else if (StrEqual(info, "status"))
        {
            vipstatus_menu(client);
        }
        else if (StrEqual(info, "benefits"))
        {
            vipbenefits_menu(client);
        }
        else if (StrEqual(info, "mycode"))
        {
            myvipcode(client, 0);
        }
		else if (StrEqual(info, "donate"))
		{
			char donateUrl[256];
			gCvarDonateUrl.GetString(donateUrl, sizeof(donateUrl));

			char motdTitle[64];
			Format(motdTitle, sizeof(motdTitle), "%T", "VIP_MOTD_DONATE_TITLE", client);
			ShowMOTDPanel(client, motdTitle, donateUrl, MOTDPANEL_TYPE_URL);
		}
        else if (StrEqual(info, "help"))
        {
            CPrintToChat(client, "%t", "VIP_MENU_HELP_INFO");
        }
        else if (StrEqual(info, "adminpanel"))
        {
            char panelUrl[256];
            gCvarAdminPanelUrl.GetString(panelUrl, sizeof(panelUrl));
            if (strlen(panelUrl) > 0 && !StrEqual(panelUrl, "0"))
            {
                char motdTitle[64];
				Format(motdTitle, sizeof(motdTitle), "%T", "VIP_MOTD_ADMIN_TITLE", client);
				ShowMOTDPanel(client, motdTitle, panelUrl, MOTDPANEL_TYPE_URL);
            }
            else
            {
                CPrintToChat(client, "%t", "VIP_ADMIN_NO_URL");
            }
        }
        else if (StrEqual(info, "adminmenu"))
        {
            vipadmin_menu(client, 0);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}

public void vipstatus_menu(int client)
{
    if (!IsValidClient(client)) return;

    char steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

    if (!SQL_CheckConfig("sourcebans")) return;

    Database DB = SQL_Connect("sourcebans", false, "", 0);
    if (DB == null) return;

    char query[256];
    Format(query, sizeof(query), "SELECT code, expire, used, viptest_used FROM sb_vip_system WHERE steamid = '%s'", steamid);

    Handle hData = CreateDataPack();
    WritePackCell(hData, client);

    SQL_TQuery(DB, vipstatus_menu_callback, query, hData);
}

public void vipstatus_menu_callback(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null)
    {
        CloseHandle(data);
        LogError("[VIPStatusMenu] SQL error: %s", error);
        return;
    }

    Handle hData = data;
    ResetPack(hData);
    int client = ReadPackCell(hData);

    Menu menu = new Menu(VIPStatusHandler);

    char title[64];
    Format(title, sizeof(title), "%T", "VIP_MENU_STATUS", client);
    menu.SetTitle(title);

    if (!SQL_FetchRow(hndl))
    {
        char line[128];
        Format(line, sizeof(line), "%T", "VIP_STATUS_NOT_CLAIMED", client);
        menu.AddItem("none", line);
    }
    else
    {
        char code[32];
        char expire[32];
        int used = SQL_FetchInt(hndl, 2);
        int viptest_used = SQL_FetchInt(hndl, 3);

        SQL_FetchString(hndl, 0, code, sizeof(code));
        SQL_FetchString(hndl, 1, expire, sizeof(expire));

        if (viptest_used == 0)
        {
            char line[128];
            Format(line, sizeof(line), "%T", "VIP_STATUS_NOT_CLAIMED", client);
            menu.AddItem("not_claimed", line);
        }
        else
        {
            char buffer[128];

            Format(buffer, sizeof(buffer), "%T", "VIP_STATUS_CLAIMED", client, "YES");
            menu.AddItem("claimed", buffer, ITEMDRAW_DISABLED);

            if (used == 1 && strlen(expire) > 0)
            {
                Format(buffer, sizeof(buffer), "%T", "VIP_STATUS_EXPIRE", client, expire);
                menu.AddItem("expire", buffer, ITEMDRAW_DISABLED);
            }
            else
            {
                Format(buffer, sizeof(buffer), "%T", "VIP_STATUS_NOT_ACTIVATED", client);
                menu.AddItem("not_activated", buffer, ITEMDRAW_DISABLED);
            }

			Format(buffer, sizeof(buffer), "%T", "VIP_STATUS_CODE", client, code);
			menu.AddItem("code", buffer, ITEMDRAW_DISABLED);

			// NEW: Show activation button if not used
			if (used == 0)
			{
				Format(buffer, sizeof(buffer), "%T", "VIP_ACTIVATE_NOW", client);
				menu.AddItem("activate", buffer);
			}
        }
    }

    char backText[64];
	Format(backText, sizeof(backText), "%T", "VIP_MENU_BACK", client);
	menu.AddItem("back", backText);
    menu.Display(client, 15);
    delete hndl;
    CloseHandle(hData);
}

public int VIPStatusHandler(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param, info, sizeof(info));

        if (StrEqual(info, "back"))
        {
            vipmenu(client, 0);
        }
        else if (StrEqual(info, "activate"))
        {
            Menu confirm = new Menu(ConfirmActivationHandler);
            char title[64];
            Format(title, sizeof(title), "%T", "VIP_ACTIVATE_CONFIRM_TITLE", client);
            confirm.SetTitle(title);

            char yes[32], no[32];
            Format(yes, sizeof(yes), "%T", "YES", client);
            Format(no, sizeof(no), "%T", "NO", client);

            confirm.AddItem("yes", yes);
            confirm.AddItem("no", no);
            confirm.Display(client, 10);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

public int ConfirmActivationHandler(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param, info, sizeof(info));

        if (StrEqual(info, "yes"))
        {
            char steamid[32];
            GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

            Database db = SQL_Connect("sourcebans", false, "", 0);
            if (db != null)
            {
                char query[256];
                Format(query, sizeof(query), "SELECT code FROM sb_vip_system WHERE steamid = '%s'", steamid);
                DBResultSet rs = SQL_Query(db, query);
                if (rs != null && SQL_FetchRow(rs))
                {
                    char code[32];
                    SQL_FetchString(rs, 0, code, sizeof(code));
                    activate_vip_code(client, code);
                    delete rs;
                }
                delete db;
            }
        }
        else
        {
            vipstatus_menu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

public void vipbenefits_menu(int client)
{
	if (!IsValidClient(client)) return;

	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

	if (!SQL_CheckConfig("sourcebans")) return;

	Database DB = SQL_Connect("sourcebans", false, "", 0);
	if (DB == null) return;

	char query[256];
	Format(query, sizeof(query),
		"SELECT g.info FROM sb_vip_system s LEFT JOIN sb_vip_groups g ON s.vip_group = g.vip_group WHERE s.steamid = '%s' AND g.info IS NOT NULL AND g.info != ''", steamid);

	Handle hData = CreateDataPack();
	WritePackCell(hData, client);
	SQL_TQuery(DB, vipbenefits_callback, query, hData);

	delete DB;
}

public void vipbenefits_callback(Handle owner, Handle hndl, const char[] error, any data)
{
	Handle hData = data;
	ResetPack(hData);
	int client = ReadPackCell(hData);

	if (hndl == null)
	{
		LogError("[VIP Benefits] SQL error: %s", error);
		CloseHandle(hData);
		return;
	}

	if (!SQL_FetchRow(hndl))
	{
		CloseHandle(hData);
		delete hndl;
		return;
	}

	char info[1024];
	SQL_FetchString(hndl, 0, info, sizeof(info));

	Menu menu = new Menu(VIPBenefitsHandler);
	char title[64];
	Format(title, sizeof(title), "%T", "VIP_BENEFITS_TITLE", client);
	menu.SetTitle(title);

	char lines[20][256];
	int count = ExplodeString(info, "\n", lines, sizeof(lines), sizeof(lines[]));

	for (int i = 0; i < count; i++)
	{
		TrimString(lines[i]);
		if (lines[i][0] != '\0') {
			menu.AddItem("", lines[i], ITEMDRAW_DISABLED);
		}
	}

	menu.AddItem("back", "< Retour");
	menu.Display(client, 20);

	delete hndl;
	CloseHandle(hData);
}

public int VIPBenefitsHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));
		if (StrEqual(info, "back"))
		{
			vipmenu(client, 0);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public Action vipadmin_menu(int client, int args)
{
	if (!IsValidClient(client)) return Plugin_Handled;
	if (!CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC)) {
		CPrintToChat(client, "%t", "VIP_ADMIN_NO_ACCESS");
		return Plugin_Handled;
	}

	Menu menu = new Menu(VIPAdminHandler);

	char title[64];
	Format(title, sizeof(title), "%T", "VIP_ADMIN_TITLE", client);
	menu.SetTitle(title);

	char item[64];

	Format(item, sizeof(item), "%T", "VIP_ADMIN_VIEW_VIPS", client);
	menu.AddItem("viewvips", item);

	Format(item, sizeof(item), "%T", "VIP_ADMIN_CHECK_EXPIRE", client);
	menu.AddItem("checkexpire", item);

	Format(item, sizeof(item), "%T", "VIP_MENU_ADMIN", client);
	menu.AddItem("webpanel", item);
	
	if (CheckCommandAccess(client, "sm_cvar", ADMFLAG_ROOT))
	{
		Format(item, sizeof(item), "%T", "VIP_ADMIN_TOGGLE_TRIAL", client);
		menu.AddItem("toggletrial", item);
	}

	menu.Display(client, 15);
	return Plugin_Handled;
}

public int VIPAdminHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));

		if (StrEqual(info, "viewvips")) {
			ShowActiveVIPs(client);
		}
		else if (StrEqual(info, "checkexpire")) {
			CheckForExpiredVipCodes();
			CPrintToChat(client, "%t", "VIP_ADMIN_EXECUTED");
		}
		else if (StrEqual(info, "webpanel"))
		{
			char panelUrl[256];
			gCvarAdminPanelUrl.GetString(panelUrl, sizeof(panelUrl));

			if (strlen(panelUrl) > 0 && !StrEqual(panelUrl, "0"))
			{
				ShowMOTDPanel(client, "VIP Admin Panel", panelUrl, MOTDPANEL_TYPE_URL);
			}
			else
			{
				CPrintToChat(client, "%t", "VIP_ADMIN_NO_URL");
			}
		}
		else if (StrEqual(info, "toggletrial")) {
			if (!CheckCommandAccess(client, "sm_cvar", ADMFLAG_ROOT)) {
				CPrintToChat(client, "%t", "VIP_ADMIN_NO_PERMISSION");
			} else {
				bool current = gCvarEnableTrial.BoolValue;
				gCvarEnableTrial.SetBool(!current);
				CPrintToChat(client, "%t", "VIP_ADMIN_TRIAL_TOGGLED", current ? "disabled" : "enabled");
			}
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void ShowActiveVIPs(int client)
{
	if (!SQL_CheckConfig("sourcebans")) return;

	Database DB = SQL_Connect("sourcebans", false, "", 0);
	if (DB == null) return;

	char query[256];
	Format(query, sizeof(query), "SELECT name, steamid, expire FROM sb_vip_system WHERE used = 1 AND expire >= NOW()");

	Handle hData = CreateDataPack();
	WritePackCell(hData, client);
	WritePackCell(hData, 1);

	SQL_TQuery(DB, ShowActiveVIPs_Callback, query, hData);
}

public void ShowActiveVIPs_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	Handle hData = data;
	ResetPack(hData);
	int client = ReadPackCell(hData);
	int fromAdmin = ReadPackCell(hData);

	if (hndl == null) {
		CPrintToChat(client, "%t", "VIP_LIST_SQL_ERROR", error);
		CloseHandle(hData);
		return;
	}

	Menu menu = new Menu(VIPListHandler);
	char title[64];
	Format(title, sizeof(title), "%T", "VIP_LIST_TITLE", client);
	menu.SetTitle(title);

	bool hasEntries = false;
	while (SQL_FetchRow(hndl))
	{
		char name[64], steamid[32], expire[32];
		SQL_FetchString(hndl, 0, name, sizeof(name));
		SQL_FetchString(hndl, 1, steamid, sizeof(steamid));
		SQL_FetchString(hndl, 2, expire, sizeof(expire));

		char entry[128];
		Format(entry, sizeof(entry), "%s (%s)", name, expire);
		menu.AddItem(steamid, entry);
		hasEntries = true;
	}

	if (!hasEntries)
	{
		char line[64];
		Format(line, sizeof(line), "%T", "VIP_LIST_EMPTY", client);
		menu.AddItem("", line);
	}

	char back[64];
	Format(back, sizeof(back), "%T", "VIP_MENU_BACK", client);
	menu.AddItem(fromAdmin ? "adminmenu" : "vipmenu", back);

	menu.Display(client, 20);
	delete hndl;
	CloseHandle(hData);
}

public int VIPListHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, info, sizeof(info));

		if (StrEqual(info, "adminmenu")) {
			vipadmin_menu(client, 0);
		}
		else if (StrEqual(info, "vipmenu")) {
			vipmenu(client, 0);
		}
		else if (StrContains(info, "STEAM_") == 0) {
			ShowVIPDetails(client, info);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void ShowVIPDetails(int client, const char[] steamid)
{
	if (!IsValidClient(client)) return;
	if (!SQL_CheckConfig("sourcebans")) return;

	Database DB = SQL_Connect("sourcebans", false, "", 0);
	if (DB == null) return;

	char query[300];
	Format(query, sizeof(query), "SELECT code, expire, used, vip_group FROM sb_vip_system WHERE steamid = '%s'", steamid);

	Handle hData = CreateDataPack();
	WritePackCell(hData, client);
	WritePackString(hData, steamid);

	SQL_TQuery(DB, ShowVIPDetails_Callback, query, hData);
}

public void ShowVIPDetails_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null) {
		CloseHandle(data);
		LogError("[VIP] SQL error in ShowVIPDetails_Callback: %s", error);
		return;
	}

	ResetPack(data);
	int client = ReadPackCell(data);
	char steamid[32];
	ReadPackString(data, steamid, sizeof(steamid));

	Menu menu = new Menu(VIPDetailsMenuHandler);
	char title[64];
	Format(title, sizeof(title), "%T", "VIP_DETAILS_TITLE", client, steamid);
	menu.SetTitle(title);

	if (SQL_FetchRow(hndl))
	{
		char code[32], expire[32], group[64];
		int used = SQL_FetchInt(hndl, 2);

		SQL_FetchString(hndl, 0, code, sizeof(code));
		SQL_FetchString(hndl, 1, expire, sizeof(expire));
		SQL_FetchString(hndl, 3, group, sizeof(group));

		char buffer[128];
		Format(buffer, sizeof(buffer), "%T", "VIP_DETAILS_CODE", client, code);
		menu.AddItem("", buffer, ITEMDRAW_DISABLED);

		Format(buffer, sizeof(buffer), "%T", "VIP_DETAILS_EXPIRE", client, strlen(expire) > 0 ? expire : "-");
		menu.AddItem("", buffer, ITEMDRAW_DISABLED);

		Format(buffer, sizeof(buffer), "%T", "VIP_DETAILS_USED", client, used ? "YES" : "NO");
		menu.AddItem("", buffer, ITEMDRAW_DISABLED);

		Format(buffer, sizeof(buffer), "%T", "VIP_DETAILS_GROUP", client, strlen(group) > 0 ? group : "NONE");
		menu.AddItem("", buffer, ITEMDRAW_DISABLED);

		char editInfo[64];
		Format(editInfo, sizeof(editInfo), "editvip|%s", steamid);

		char editText[64];
		Format(editText, sizeof(editText), "%T", "VIP_EDIT_VIP", client);

		menu.AddItem(editInfo, editText);
	}

	menu.AddItem("back", "< Back");

	menu.Display(client, 20);
	delete hndl;
	CloseHandle(data);
}

public int VIPDetailsMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, info, sizeof(info));

		if (StrEqual(info, "back"))
		{
			ShowActiveVIPs(client);
		}
		else if (StrContains(info, "editvip|") == 0)
		{
			char steamid[32];
			strcopy(steamid, sizeof(steamid), info[8]);

			char baseUrl[256];
			gCvarAdminPanelUrl.GetString(baseUrl, sizeof(baseUrl));

			if (strlen(baseUrl) > 0)
			{
				char finalUrl[512];
				Format(finalUrl, sizeof(finalUrl), "%s/edit.php?id=%s", baseUrl, steamid);
				char motdTitle[64];
				Format(motdTitle, sizeof(motdTitle), "%T", "VIP_MOTD_EDIT_TITLE", client);
				ShowMOTDPanel(client, motdTitle, finalUrl, MOTDPANEL_TYPE_URL);
			}
			else
			{
				CPrintToChat(client, "[VIP] Admin panel URL not set.");
			}
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public Action vip_code(int client, int arg) {
    if (!IsValidClient(client)) return Plugin_Handled;

    if (arg < 1) {
        CPrintToChat(client, "%t", "VIP_USAGE");
        return Plugin_Handled;
    }

    int time = GetTime();

    if (time < spamblock[client]) {
        CPrintToChat(client, "%t", "VIP_SPAM");
        return Plugin_Handled;
    }

    spamblock[client] = time + 3;

    char vipCode[20];
    GetCmdArg(1, vipCode, sizeof(vipCode));

    if (SimpleRegexMatch(vipCode, "[^a-zA-Z0-9]") > 0) {
        CPrintToChat(client, "%t", "VIP_CODE_ALPHANUM");
        return Plugin_Handled;
    }

    if (SQL_CheckConfig("sourcebans")) {
        Database DB = SQL_Connect("sourcebans", false, "", 0);
        if (DB == null) return Plugin_Handled;

        char buffer[300];
        Format(buffer, sizeof(buffer), "SELECT used, steamid FROM sb_vip_system WHERE code = '%s'", vipCode);

        Handle hDataPack = CreateDataPack();
        WritePackCell(hDataPack, client);
        WritePackString(hDataPack, vipCode);
        SQL_TQuery(DB, vip_code_check_callback, buffer, hDataPack);
    }

    return Plugin_Handled;
}

public void vip_code_check_callback(Handle owner, Handle hndl, const char[] error, any dataPack) {
    if (hndl == null) {
        SetFailState("ERROR - %s", error);
        CloseHandle(dataPack);
        return;
    }

    Handle hDataPack = dataPack;
    ResetPack(hDataPack);
    int client = ReadPackCell(hDataPack);
    char code[20];
    ReadPackString(hDataPack, code, sizeof(code));

    char clientSteamID[32];
    GetClientAuthId(client, AuthId_Steam2, clientSteamID, sizeof(clientSteamID));

    if (SQL_FetchRow(hndl)) {
        int used = SQL_FetchInt(hndl, 0);
        char steamID[32];
        SQL_FetchString(hndl, 1, steamID, sizeof(steamID));

        if (used != 0) {
           CPrintToChat(client, "%t", "VIP_ALREADY_CLAIMED");
        } else if (strlen(steamID) > 0 && strcmp(steamID, clientSteamID) != 0) {
           CPrintToChat(client, "%t", "VIP_NOT_YOURS");
        } else {
            activate_vip_code(client, code);
        }
    } else {
        CPrintToChat(client, "%t", "VIP_INCORRECT");
    }

    delete hndl;
    CloseHandle(hDataPack);
}

void activate_vip_code(int client, const char[] code) {
    if (!IsValidClient(client)) return;

    Database DB = SQL_Connect("sourcebans", false, "", 0);
    if (DB == null) {
        LogError("Failed to connect to the database while activating VIP code.");
        return;
    }

    char buffer[300], steamID[64];
    GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));

    Format(buffer, sizeof(buffer), "UPDATE sb_vip_system SET steamid = '%s', expire = DATE_ADD(NOW(), INTERVAL 1 WEEK), used = 1, vip_group = 'vip' WHERE code = '%s'", steamID, code);
    
    if (!SQL_FastQuery(DB, buffer)) {
        char error[256];
        SQL_GetError(DB, error, sizeof(error));
        LogError("[VIP Plugin] SQL Error: %s", error);
        CPrintToChat(client, "%t", "VIP_PROCESS_ERROR");
    } else {
        CPrintToChat(client, "%t", "VIP_ACTIVATED");
        RefreshAdminCache();
    }

    delete DB;
}

public Action viptest(int client, int arg)
{
	
    if (!IsValidClient(client)) return Plugin_Handled;

	if (!gCvarEnableTrial.BoolValue)
	{
		CPrintToChat(client, "%t", "VIP_TRIAL_DISABLED");
		return Plugin_Handled;
	}

    if (usedViptest[client])
    {
        CPrintToChat(client, "%t", "VIP_TRIAL_RECEIVED");
        return Plugin_Handled;
    }
	
	int time = GetTime();
   if (time < spamblock_viptest[client])
   {
       CPrintToChat(client, "%t", "VIP_SPAM");
       return Plugin_Handled;
   }
   spamblock_viptest[client] = time + 10;

    if (SQL_CheckConfig("sourcebans"))
    {
        Database DB = SQL_Connect("sourcebans", false, "", 0);

        if (DB == null) return Plugin_Handled;

        char steamid[32];
        GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

        char name[MAX_NAME_LENGTH];
        GetClientName(client, name, sizeof(name));

        char buffer[300];

        Format(buffer, sizeof(buffer), "SELECT code, used, expire, viptest_used FROM sb_vip_system WHERE steamid = '%s'", steamid);

        DBResultSet result = SQL_Query(DB, buffer);

        bool alreadyClaimed = false;
        char existingCode[32];
        bool used = false;
        int expire;
        int usedViptestDB;

        if (result != null)
        {
            if (SQL_FetchRow(result))
            {
                alreadyClaimed = true;
                SQL_FetchString(result, 0, existingCode, sizeof(existingCode));
                used = SQL_FetchInt(result, 1) == 1;
                expire = SQL_FetchInt(result, 2);
                usedViptestDB = SQL_FetchInt(result, 3);
            }
            delete result;
        }

        if (usedViptestDB)
        {
            CPrintToChat(client, "%t", "VIP_VIPTEST_USED");
            delete DB;
            return Plugin_Handled;
        }

        if (alreadyClaimed)
        {
            if (used)
            {
                if (expire >= GetTime())
                {
                    CPrintToChat(client, "%t", "VIP_TRIAL_ACTIVE");
                }
                else
                {
                    CPrintToChat(client, "%t", "VIP_TRIAL_EXPIRED");
                }
            }
            else
            {
                CPrintToChat(client, "%t", "VIP_VIPTEST_ALREADY_CLAIMED", existingCode, existingCode);
            }
        }
        else
        {
            char randomCode[32];
            GenerateRandomCode(randomCode, 10);

            Format(buffer, sizeof(buffer), "INSERT INTO sb_vip_system (code, steamid, name, viptest_used) SELECT '%s', '%s', '%s', 1 WHERE NOT EXISTS (SELECT 1 FROM sb_vip_system WHERE steamid = '%s')", randomCode, steamid, name, steamid);

            if (!SQL_FastQuery(DB, buffer))
            {
                SQL_GetError(DB, buffer, sizeof(buffer));
                LogError("%s", buffer);
            }
            else
            {
                CPrintToChat(client, "%t", "VIP_NEW_CODE", randomCode);
                usedViptest[client] = true;
            }
        }

        delete DB;
    }

    return Plugin_Handled;
}

void GenerateRandomCode(char[] buffer, int length)
{
    static const char charset[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    for (int i = 0; i < length; i++)
    {
        buffer[i] = charset[GetRandomInt(0, sizeof(charset) - 2)];
    }
    buffer[length] = '\0';
}

public Action myvipcode(int client, int arg)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    char steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

    if (SQL_CheckConfig("sourcebans"))
    {
        Database DB = SQL_Connect("sourcebans", false, "", 0);

        if (DB == null) return Plugin_Handled;

        char buffer[300];
        Format(buffer, sizeof(buffer), "SELECT code, viptest_used FROM sb_vip_system WHERE steamid = '%s'", steamid);

        DBResultSet result = SQL_Query(DB, buffer);

        if (result != null)
        {
            if (SQL_FetchRow(result))
            {
                int viptest_used_db = SQL_FetchInt(result, 1);

                if (viptest_used_db == 1)
                {
                    char code[32];
                    SQL_FetchString(result, 0, code, sizeof(code));
                    CPrintToChat(client, "%t", "VIP_YOUR_CODE", code);
                }
                else
                {
                    CPrintToChat(client, "%t", "VIP_VIPTEST_NOT_USED");
                }
            }
            else
            {
                CPrintToChat(client, "%t", "VIP_VIPTEST_NOT_USED");
            }
            delete result;
        }
        else
        {
            char error[256];
            SQL_GetError(DB, error, sizeof(error));
        }

        delete DB;
    }
    else
    {
        PrintToServer("[DEBUG] sourcebans config check failed");
    }

    return Plugin_Handled;
}

public Action vipstatus(int client, int arg)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    char steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

    if (SQL_CheckConfig("sourcebans"))
    {
        Database DB = SQL_Connect("sourcebans", false, "", 0);

        if (DB == null) return Plugin_Handled;

        char buffer[300];
        Format(buffer, sizeof(buffer), "SELECT expire, viptest_used FROM sb_vip_system WHERE steamid = '%s'", steamid);

        DBResultSet result = SQL_Query(DB, buffer);

        if (result != null)
        {
            if (SQL_FetchRow(result))
            {
                int viptest_used_db = SQL_FetchInt(result, 1);

                if (viptest_used_db == 0)
                {
                    CPrintToChat(client, "%t", "VIP_VIPTEST_NOT_CLAIMED");
                }
                else
                {
                    char expireDate[32];
                    SQL_FetchString(result, 0, expireDate, sizeof(expireDate));
                    if (strlen(expireDate) > 0)
                    {
                        CPrintToChat(client, "%t", "VIP_TRIAL_EXPIRES", expireDate);
                    }
                    else
                    {
                        CPrintToChat(client, "%t", "VIP_TRIAL_NOT_ACTIVATED");
                    }
                }
            }
            else
            {
                CPrintToChat(client, "%t", "VIP_VIPTEST_NOT_CLAIMED");
            }
            delete result;
        }
        delete DB;
    }

    return Plugin_Handled;
}

public void Connect_callback(Handle owner, Handle hndl, const char[] error, any data)
{
    if(hndl == null) return;

    char buffer[300];

    Format(buffer, sizeof(buffer), "SELECT steamid, vip_group FROM sb_vip_system WHERE expire >= CURDATE() AND steamid REGEXP '^STEAM_[[:digit:]]\\:[[:digit:]]\\:[[:digit:]]+$'"); //"STEAM_1:1:111111"
    SQL_TQuery(hndl, Query_callback, buffer, data, DBPrio_Low);

    delete hndl;
}

public void Query_callback(Handle owner, Handle hndl, const char[] error, any data)
{

    if(hndl == null)
    {
        SetFailState("ERROR - %s", error);
    }

    GroupId group;
    AdminId admin;

    char buffer[300];

    while (SQL_FetchRow(hndl))
    {
        SQL_FetchString(hndl, 1, buffer, sizeof(buffer));

        group = FindAdmGroup(buffer);
        if(group == INVALID_GROUP_ID) continue;

        SQL_FetchString(hndl, 0, buffer, sizeof(buffer));

        admin = FindAdminByIdentity("steam", buffer);

        if(admin == INVALID_ADMIN_ID)
        {
            admin = CreateAdmin("vip");
            if(!BindAdminIdentity(admin, "steam", buffer))
            {
                RemoveAdmin(admin);
                continue;
            }
        }

        bool IsInGroup;

        for(int x = 0; x < GetAdminGroupCount(admin); x++)
        {
            if(GetAdminGroup(admin, x, "", 0) == group)
            {
                IsInGroup = true;
                break;
            }
        }

        if(IsInGroup) continue;

        AdminInheritGroup(admin, group);
    }
} 