/*
	Revision 1.0.2
	----------------
	Added cvar sm_notices_order, which allows choice between ascending/descending ordering for the Notice menu. 
	Fixed a minor display bug with sm_getnotice, / sm_listnotices where Duration showed a value in seconds rather than minutes.
	Fixed an issue with Notices not expiring automatically on map change where applicable.
*/

#pragma semicolon 1
#include <sourcemod>
#include <colors>

#define PLUGIN_VERSION "1.0.2"
#define MAXIMUM_NOTICES 256

#define ORDER_ASC "ASC"
#define ORDER_DESC "DESC"

#define INCREMENT_SQLITE "AUTOINCREMENT"
#define INCREMENT_MYSQL "AUTO_INCREMENT"

new g_iNoticeIssue[MAXIMUM_NOTICES];
new g_iNoticeDuration[MAXIMUM_NOTICES];
new String:g_sNoticeAdmin[MAXIMUM_NOTICES][32];
new String:g_sNoticeTitle[MAXIMUM_NOTICES][192];
new String:g_sNoticeMessage[MAXIMUM_NOTICES][192];

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hIndex = INVALID_HANDLE;
new Handle:g_hChatCommands = INVALID_HANDLE;
new Handle:g_hTimeFormat = INVALID_HANDLE;
new Handle:g_hConnection = INVALID_HANDLE;
new Handle:g_hAdvert = INVALID_HANDLE;
new Handle:g_hOrder = INVALID_HANDLE;
new Handle:g_hDatabase = INVALID_HANDLE;

new Float:g_fAdvert;
new g_iIndex, g_iNumNotices, g_iNumCommands, g_iOrder;
new bool:g_bEnabled, bool:g_bNullTime, bool:g_bQuery;
new String:g_sPrefixChat[64], String:g_sPrefixConsole[64], String:g_sConnection[32], String:g_sChatCommands[16][32], String:g_sTimeFormat[32];

new String:g_sSQL_TableCreate[] = { "CREATE TABLE IF NOT EXISTS sm_notices (entry INTEGER PRIMARY KEY %s NOT NULL, server int(4) NOT NULL default 0, issued int(12) NOT NULL default 0, duration int(12) NOT NULL default 0, title varchar(192) NOT NULL default '', message varchar(192) NOT NULL default '', admin varchar(32) NOT NULL default '')" };
new String:g_sSQL_TableLoad[] = { "SELECT entry, issued, duration, title, message, admin FROM sm_notices WHERE server = 0 OR server = %d ORDER BY issued %s" };
new String:g_sSQL_PruneDelete[] = { "DELETE FROM sm_notices WHERE entry = %d" };
new String:g_sSQL_CommandList[] = { "SELECT entry, server, issued, duration, title, message, admin FROM sm_notices WHERE server = %d ORDER BY entry" };
new String:g_sSQL_CommandListAll[] = { "SELECT entry, server, issued, duration, title, message, admin FROM sm_notices ORDER BY server" };
new String:g_sSQL_CommandDel[] = { "DELETE FROM sm_notices WHERE entry = %d" };
new String:g_sSQL_CommandAdd[] = { "INSERT INTO sm_notices (server, issued, duration, title, message, admin) VALUES (%d, %d, %d, '%s', '%s', '%s')" };
new String:g_sSQL_CommandGet[] = { "SELECT server, issued, duration, title, message, admin FROM sm_notices WHERE entry = %d" };

public Plugin:myinfo = 
{
	name = "[SM] Notices",
	author = "Twisted|Panda",
	description = "Provides a simple interface for relaying news/announcements to a server.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
};

public OnPluginStart()
{	
	LoadTranslations("common.phrases");
	LoadTranslations("sm_notices.phrases");

	CreateConVar("sm_notices_version", PLUGIN_VERSION, "[SM] Notices: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_notices_enabled", "1", "Enables/disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hIndex = CreateConVar("sm_notices_index", "1", "The server index, allowing for server-specific notices.", FCVAR_NONE, true, 1.0);
	HookConVarChange(g_hIndex, OnSettingsChange);
	g_hChatCommands = CreateConVar("sm_notices_commands", "!news, /news, !notice, /notice, !notices, /notices", "The chat triggers available to clients to access notices.", FCVAR_NONE);
	HookConVarChange(g_hChatCommands, OnSettingsChange);
	g_hConnection = CreateConVar("sm_notices_database", "sm_notices", "The database to use for the plugin.", FCVAR_NONE);
	HookConVarChange(g_hConnection, OnSettingsChange);
	g_hTimeFormat = CreateConVar("sm_notices_format_time", "%x", "Determines the formatting for time and date display. Using \"\" will default to sm_datetime_format (/cfg/sourcemod.cfg)", FCVAR_NONE);
	HookConVarChange(g_hTimeFormat, OnSettingsChange);
	g_hAdvert = CreateConVar("sm_notices_advert", "5.0", "The number of seconds after a player joins an initial team for an advert to be sent about the plugin. (0.0 = Disabled)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hAdvert, OnSettingsChange);
	g_hOrder = CreateConVar("sm_notices_order", "1", "Determines the sorting method to apply to Notices via their issued date. (0 = Ascending, 1 = Descending)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hOrder, OnSettingsChange);
	AutoExecConfig(true, "sm_notices");

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	HookEvent("player_team", Event_OnPlayerTeam);
	
	RegAdminCmd("sm_loadnotices", Command_LoadNotice, ADMFLAG_ROOT, "Notices: sm_loadnotices | Loads notices to the current server.");
	RegAdminCmd("sm_listnotices", Command_ListNotice, ADMFLAG_ROOT, "Notices: sm_listnotices <optional:server> | Displays all notices to console.");
	RegAdminCmd("sm_delnotice", Command_DelNotice, ADMFLAG_ROOT, "Notices: sm_delnotice <entry> | Deletes an existing notice from the database.");
	RegAdminCmd("sm_getnotice", Command_GetNotice, ADMFLAG_ROOT, "Notices: sm_getnotice <entry> | Retrieves an existing notice from the database.");
	RegAdminCmd("sm_addnotice", Command_AddNotice, ADMFLAG_ROOT, "Notices: sm_addnotice <server> <duration:minutes> <title> <message> | Creates a new notice in the database.");
	
	decl String:_sTemp[192];
	g_bEnabled = GetConVarBool(g_hEnabled);
	g_iIndex = GetConVarInt(g_hIndex);
	GetConVarString(g_hConnection, g_sConnection, sizeof(g_sConnection));
	GetConVarString(g_hChatCommands, _sTemp, sizeof(_sTemp));
	g_iNumCommands = ExplodeString(_sTemp, ", ", g_sChatCommands, 16, 32);
	GetConVarString(g_hTimeFormat, g_sTimeFormat, sizeof(g_sTimeFormat));
	g_bNullTime = StrEqual(g_sTimeFormat, "", false) ? true : false;
	g_fAdvert = GetConVarFloat(g_hAdvert);
	g_iOrder = GetConVarInt(g_hOrder);
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		Format(g_sPrefixChat, sizeof(g_sPrefixChat), "%T", "Prefix_Chat", LANG_SERVER);
		Format(g_sPrefixConsole, sizeof(g_sPrefixConsole), "%T", "Prefix_Console", LANG_SERVER);
		
		if(g_hDatabase == INVALID_HANDLE)
			SQL_TConnect(SQL_ConnectCall, g_sConnection);
		else if(!g_bQuery)
		{
			g_bQuery = true;

			decl String:_sQuery[192];
			Format(_sQuery, sizeof(_sQuery), g_sSQL_TableLoad, g_iIndex, g_iOrder ? ORDER_DESC : ORDER_ASC);
			SQL_TQuery(g_hDatabase, SQL_TableLoad, _sQuery, _);
		}
	}
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client <= 0 || !IsClientInGame(client))
			return Plugin_Continue;

		if(g_fAdvert && !GetEventInt(event, "oldteam"))
			CreateTimer(g_fAdvert, Timer_Announce, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action:Timer_Announce(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client > 0 && IsClientInGame(client))
	{
		decl String:_sName[32];
		GetClientName(client, _sName, sizeof(_sName));
		CPrintToChat(client, "%s%t", g_sPrefixChat, "Plugin_Advert", _sName);
	}
	
	return Plugin_Handled;
}

public Action:Command_Say(client, const String:command[], argc)
{
	if(g_bEnabled)
	{
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		decl String:_sText[192];
		GetCmdArgString(_sText, sizeof(_sText));
		StripQuotes(_sText);

		for(new i = 0; i < g_iNumCommands; i++)
		{
			if(StrEqual(_sText, g_sChatCommands[i], false))
			{
				Menu_Notices(client);
				return Plugin_Stop;
			}
		}
	}

	return Plugin_Continue;
}

Menu_Notices(client, entry = 0)
{
	decl String:_sBuffer[128];
	new _iTemp, Handle:_hMenu = CreateMenu(MenuHandler_MenuNotices);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title_Main", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);

	new _iTime = GetTime();
	for(new i = 0; i < g_iNumNotices; i++)
	{
		if(!g_iNoticeDuration[i] || (g_iNoticeIssue[i] + g_iNoticeDuration[i]) > _iTime)
		{
			_iTemp++;

			IntToString(i, _sBuffer, sizeof(_sBuffer));
			AddMenuItem(_hMenu, _sBuffer, g_sNoticeTitle[i]);
		}
	}
	
	if(!_iTemp)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title_Empty", client);
		AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);
	}
	
	DisplayMenuAtItem(_hMenu, client, entry, MENU_TIME_FOREVER);
}

public MenuHandler_MenuNotices(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Select:
		{
			decl String:_sTemp[8], String:_sBuffer[192];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			new _iNotice = StringToInt(_sTemp);

			FormatTime(_sBuffer, sizeof(_sBuffer), g_bNullTime ? NULL_STRING : g_sTimeFormat, g_iNoticeIssue[_iNotice]);
			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Menu_Notice_Issued", g_sNoticeAdmin[_iNotice], _sBuffer);
			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Menu_Notice_Title", g_sNoticeTitle[_iNotice]);
			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Menu_Notice_Display", g_sNoticeMessage[_iNotice]);
			Menu_Notices(param1, GetMenuSelectionPosition());
		}
	}
}

public Action:Command_LoadNotice(client, args) 
{
	if(!g_bQuery)
	{
		g_bQuery = true;

		decl String:_sQuery[192];
		Format(_sQuery, sizeof(_sQuery), g_sSQL_TableLoad, g_iIndex, g_iOrder ? ORDER_DESC : ORDER_ASC);
		SQL_TQuery(g_hDatabase, SQL_TableLoad, _sQuery, _);
	}
	
	return Plugin_Handled;
}

public Action:Command_ListNotice(client, args) 
{
	new _iIndex;
	if(args)
	{
		decl String:_sBuffer[4];
		GetCmdArg(1, _sBuffer, sizeof(_sBuffer));
		_iIndex = StringToInt(_sBuffer);
	}

	decl String:_sQuery[192];
	if(_iIndex)
		Format(_sQuery, sizeof(_sQuery), g_sSQL_CommandList, _iIndex);
	else
		Format(_sQuery, sizeof(_sQuery), g_sSQL_CommandListAll);
	SQL_TQuery(g_hDatabase, SQL_CommandList, _sQuery, client > 0 ? GetClientUserId(client) : client);
	
	return Plugin_Handled;
}

public SQL_CommandList(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("Error: The query \"g_sSQL_CommandList\" could not be executed!");
		decl String:_sError[512];
		if(hndl != INVALID_HANDLE && SQL_GetError(hndl, _sError, 512))
			LogError("- SQL_CommandList: %s", _sError);
		else
			LogError("- SQL_CommandList: %s", error);
	}
	else
	{
		new client, _iReturned;
		if(userid)
		{
			client = GetClientOfUserId(userid);
			client = (client && IsClientInGame(client)) ? client : 0;
			if(!client)
				return;
		}

		new _iTime = GetTime();
		decl String:_sBuffer[192], String:_sTitle[192], String:_sMessage[192], String:_sAdmin[32];
		while (SQL_FetchRow(hndl))
		{
			new _iIssue = SQL_FetchInt(hndl, 2);
			new _iDuration = SQL_FetchInt(hndl, 3);
			if(!_iDuration || (_iIssue + _iDuration) > _iTime)
			{
				_iReturned++;
				new _iIndex = SQL_FetchInt(hndl, 0);
				new _iServer = SQL_FetchInt(hndl, 1);
				SQL_FetchString(hndl, 4, _sTitle, sizeof(_sTitle));
				SQL_FetchString(hndl, 5, _sMessage, sizeof(_sMessage));
				SQL_FetchString(hndl, 6, _sAdmin, sizeof(_sAdmin));

				FormatTime(_sBuffer, sizeof(_sBuffer), g_bNullTime ? NULL_STRING : g_sTimeFormat, _iIssue);
				if(client)
				{
					PrintToConsole(client, "%s%t", g_sPrefixConsole, "Command_List_Part_One", _iIndex, _iServer, _sBuffer, _sAdmin, (_iDuration / 60));		
					PrintToConsole(client, "%s%t", g_sPrefixConsole, "Command_List_Part_Two", _sTitle);	
					PrintToConsole(client, "%s%t", g_sPrefixConsole, "Command_List_Part_Three", _sMessage);	
				}
				else
				{
					PrintToServer("%s%t", g_sPrefixConsole, "Command_List_Part_One", _iIndex, _iServer, _sBuffer, _sAdmin, (_iDuration / 60));	
					PrintToServer("%s%t", g_sPrefixConsole, "Command_List_Part_Two", _sTitle);	
					PrintToServer("%s%t", g_sPrefixConsole, "Command_List_Part_Three", _sMessage);	
				}
			}
		}

		if(!_iReturned)
		{
			if(client)
				CPrintToChat(client, "%s%t", g_sPrefixChat, "Command_List_Failure");
			else
				PrintToServer("%s%t", g_sPrefixConsole, "Command_List_Failure");
		}
		else
		{
			if(client)
				CPrintToChat(client, "%s%t", g_sPrefixChat, "Command_List_Success");
			else
				PrintToServer("%s%t", g_sPrefixConsole, "Command_List_Success");
		}
	}
}

public Action:Command_DelNotice(client, args) 
{
	if(args < 1)
	{
		ReplyToCommand(client, "%t", "Command_Del_Arguments");
		return Plugin_Handled;
	}
	
	decl String:_sBuffer[4];
	GetCmdArg(1, _sBuffer, sizeof(_sBuffer));
	new _iIndex = StringToInt(_sBuffer);

	decl String:_sQuery[192];
	Format(_sQuery, sizeof(_sQuery), g_sSQL_CommandDel, _iIndex);
	SQL_TQuery(g_hDatabase, SQL_CommandDel, _sQuery, client > 0 ? GetClientUserId(client) : client);
	
	return Plugin_Handled;
}

public SQL_CommandDel(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("Error: The query \"g_sSQL_CommandDel\" could not be executed!");
		decl String:_sError[512];
		if(hndl != INVALID_HANDLE && SQL_GetError(hndl, _sError, 512))
			LogError("- SQL_CommandDel: %s", _sError);
		else
			LogError("- SQL_CommandDel: %s", error);
	}
	else
	{
		new client;
		if(userid)
		{
			client = GetClientOfUserId(userid);
			client = (client && IsClientInGame(client)) ? client : 0;
			if(!client)
				return;
		}
		
		if(SQL_GetAffectedRows(owner))
		{
			if(client)
				CPrintToChat(client, "%s%t", g_sPrefixChat, "Command_Del_Success");
			else
				PrintToServer("%s%t", g_sPrefixConsole, "Command_Del_Success");
		}	
		else
		{
			if(client)
				CPrintToChat(client, "%s%t", g_sPrefixChat, "Command_Del_Failure");
			else
				PrintToServer("%s%t", g_sPrefixConsole, "Command_Del_Failure");
		}
	}
}

public Action:Command_AddNotice(client, args) 
{
	if(args != 4)
	{
		ReplyToCommand(client, "%t", "Command_Add_Arguments");
		return Plugin_Handled;
	}

	decl String:_sBuffer[192], String:_sTitle[384], String:_sMessage[384];
	GetCmdArg(1, _sBuffer, sizeof(_sBuffer));
	new _iServer = StringToInt(_sBuffer);
	GetCmdArg(2, _sBuffer, sizeof(_sBuffer));
	new _iDuration = StringToInt(_sBuffer) * 60;
	GetCmdArg(3, _sBuffer, sizeof(_sBuffer));
	SQL_EscapeString(g_hDatabase, _sBuffer, _sTitle, sizeof(_sTitle));
	GetCmdArg(4, _sBuffer, sizeof(_sBuffer));
	SQL_EscapeString(g_hDatabase, _sBuffer, _sMessage, sizeof(_sMessage));

	decl String:_sAdmin[32];
	if(!client)
		Format(_sAdmin, sizeof(_sAdmin), "%T", "Phrase_Notice_Console", LANG_SERVER);
	else
	{
		new AdminId:_AdminId = GetUserAdmin(client);
		if(_AdminId == INVALID_ADMIN_ID)
			Format(_sAdmin, sizeof(_sAdmin), "%T", "Phrase_Notice_Admin", LANG_SERVER);
		else
		{	
			GetAdminUsername(_AdminId, _sAdmin, sizeof(_sAdmin));
			if(StrEqual(_sAdmin, ""))
				Format(_sAdmin, sizeof(_sAdmin), "%T", "Phrase_Notice_Admin", LANG_SERVER);
		}
	}

	decl String:_sQuery[512];
	Format(_sQuery, sizeof(_sQuery), g_sSQL_CommandAdd, _iServer, GetTime(), _iDuration, _sTitle, _sMessage, _sAdmin);
	SQL_TQuery(g_hDatabase, SQL_CommandAdd, _sQuery, client > 0 ? GetClientUserId(client) : client);
	
	return Plugin_Handled;
}

public SQL_CommandAdd(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("Error: The query \"g_sSQL_CommandAdd\" could not be executed!");
		decl String:_sError[512];
		if(hndl != INVALID_HANDLE && SQL_GetError(hndl, _sError, 512))
			LogError("- SQL_CommandAdd: %s", _sError);
		else
			LogError("- SQL_CommandAdd: %s", error);
	}
	else
	{
		new client;
		if(userid)
		{
			client = GetClientOfUserId(userid);
			client = (client && IsClientInGame(client)) ? client : 0;
			if(!client)
				return;
		}

		if(client)
			CPrintToChat(client, "%s%t", g_sPrefixChat, "Command_Add_Success", SQL_GetInsertId(owner));
		else
			PrintToServer("%s%t", g_sPrefixConsole, "Command_Add_Success", SQL_GetInsertId(owner));
	}
}

public Action:Command_GetNotice(client, args) 
{
	if(args < 1)
	{
		ReplyToCommand(client, "%t", "Command_Get_Arguments");
		return Plugin_Handled;
	}

	decl String:_sBuffer[4];
	GetCmdArg(1, _sBuffer, sizeof(_sBuffer));
	new _iIndex = StringToInt(_sBuffer);

	decl String:_sQuery[192];
	Format(_sQuery, sizeof(_sQuery), g_sSQL_CommandGet, _iIndex);
	SQL_TQuery(g_hDatabase, SQL_CommandGet, _sQuery, client > 0 ? GetClientUserId(client) : client);
	
	return Plugin_Handled;
}

public SQL_CommandGet(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("Error: The query \"g_sSQL_CommandGet\" could not be executed!");
		decl String:_sError[512];
		if(hndl != INVALID_HANDLE && SQL_GetError(hndl, _sError, 512))
			LogError("- SQL_CommandGet: %s", _sError);
		else
			LogError("- SQL_CommandGet: %s", error);
	}
	else
	{
		new client;
		if(userid)
		{
			client = GetClientOfUserId(userid);
			client = (client && IsClientInGame(client)) ? client : 0;
			if(!client)
				return;
		}

		decl String:_sBuffer[192], String:_sTitle[192], String:_sMessage[192], String:_sAdmin[32];
		if(SQL_FetchRow(hndl))
		{
			new _iServer = SQL_FetchInt(hndl, 0);
			new _iIssue = SQL_FetchInt(hndl, 1);
			new _iDuration = SQL_FetchInt(hndl, 2);
			SQL_FetchString(hndl, 3, _sTitle, sizeof(_sTitle));
			SQL_FetchString(hndl, 4, _sMessage, sizeof(_sMessage));
			SQL_FetchString(hndl, 5, _sAdmin, sizeof(_sAdmin));

			FormatTime(_sBuffer, sizeof(_sBuffer), g_bNullTime ? NULL_STRING : g_sTimeFormat, _iIssue);
			if(client)
			{
				CPrintToChat(client, "%s%t", g_sPrefixChat, "Command_Get_Success");
				CPrintToChat(client, "%s%t", g_sPrefixChat, "Command_Get_Part_One", _iServer, _sBuffer, _sAdmin, (_iDuration / 60));
				CPrintToChat(client, "%s%t", g_sPrefixChat, "Command_Get_Part_Two", _sTitle);	
				CPrintToChat(client, "%s%t", g_sPrefixChat, "Command_Get_Part_Three", _sMessage);
			}
			else
			{
				PrintToServer("%s%t", g_sPrefixConsole, "Command_Get_Success");
				PrintToServer("%s%t", g_sPrefixConsole, "Command_Get_Part_One", _iServer, _sBuffer, _sAdmin, (_iDuration / 60));	
				PrintToServer("%s%t", g_sPrefixConsole, "Command_Get_Part_Two", _sTitle);
				PrintToServer("%s%t", g_sPrefixConsole, "Command_Get_Part_Three", _sMessage);
			}	
		}
		else
		{
			if(client)
				CPrintToChat(client, "%s%t", g_sPrefixChat, "Command_Get_Failure");
			else
				PrintToServer("%s%t", g_sPrefixConsole, "Command_Get_Failure");
		}
	}
}

public SQL_ConnectCall(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("Error: Notices was unable to establish a database connection!");
		decl String:_sError[512];
		if(hndl != INVALID_HANDLE && SQL_GetError(hndl, _sError, 512))
			LogError("- SQL_ConnectCall: %s", _sError);
		else
			LogError("- SQL_ConnectCall: %s", error);
	}
	else
	{
		decl String:_sQuery[512];
		SQL_GetDriverIdent(owner, _sQuery, sizeof(_sQuery));

		SQL_LockDatabase(hndl);
		Format(_sQuery, sizeof(_sQuery), g_sSQL_TableCreate, StrEqual(_sQuery, "sqlite") ? INCREMENT_SQLITE : INCREMENT_MYSQL);
		if(!SQL_FastQuery(hndl, _sQuery))
		{
			LogError("Error: The query \"g_sSQL_TableCreate\" could not be executed!");
			decl String:_sError[512];
			if(hndl != INVALID_HANDLE && SQL_GetError(hndl, _sError, 512))
				LogError("- SQL_ConnectCall: %s", _sError);
				
			CloseHandle(hndl);
			return;
		}
		SQL_UnlockDatabase(hndl);
		g_hDatabase = hndl;

		if(!g_bQuery)
		{
			g_bQuery = true;

			Format(_sQuery, sizeof(_sQuery), g_sSQL_TableLoad, g_iIndex, g_iOrder ? ORDER_DESC : ORDER_ASC);
			SQL_TQuery(g_hDatabase, SQL_TableLoad, _sQuery, _);
		}
	}
}

public SQL_TableLoad(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("Error: The query \"g_sSQL_TableLoad\" could not be executed!");
		decl String:_sError[512];
		if(hndl != INVALID_HANDLE && SQL_GetError(hndl, _sError, 512))
			LogError("- SQL_TableLoad: %s", _sError);
		else
			LogError("- SQL_TableLoad: %s", error);
	}
	else
	{
		g_iNumNotices = 0;
		new _iTime = GetTime(), _iNumExpired, _iExpired[MAXIMUM_NOTICES];
		while (SQL_FetchRow(hndl))
		{
			new _iIssue = SQL_FetchInt(hndl, 1);
			new _iDuration = SQL_FetchInt(hndl, 2);
			if(!_iDuration || (_iIssue + _iDuration) > _iTime)
			{
				g_iNoticeIssue[g_iNumNotices] = _iIssue;
				g_iNoticeDuration[g_iNumNotices] = _iDuration;
				SQL_FetchString(hndl, 3, g_sNoticeTitle[g_iNumNotices], sizeof(g_sNoticeTitle[]));
				SQL_FetchString(hndl, 4, g_sNoticeMessage[g_iNumNotices], sizeof(g_sNoticeMessage[]));
				SQL_FetchString(hndl, 5, g_sNoticeAdmin[g_iNumNotices], sizeof(g_sNoticeAdmin[]));
				g_iNumNotices++;
			}
			else
			{
				new _iEntry = SQL_FetchInt(hndl, 0);
				_iExpired[_iNumExpired] = _iEntry;
				_iNumExpired++;
			}
		}
		
		if(_iNumExpired)
		{
			decl String:_sQuery[256];
			for(new i = 0; i < _iNumExpired; i++)
			{
				Format(_sQuery, sizeof(_sQuery), g_sSQL_PruneDelete, _iExpired[i]);
				SQL_TQuery(g_hDatabase, SQL_PruneDelete, _sQuery, _);
			}
		}
	}
	
	g_bQuery = false;
}

public SQL_PruneDelete(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("Error: The query \"g_sSQL_PruneDelete\" could not be executed!");
		decl String:_sError[512];
		if(hndl != INVALID_HANDLE && SQL_GetError(hndl, _sError, 512))
			LogError("- SQL_PruneDelete: %s", _sError);
		else
			LogError("- SQL_PruneDelete: %s", error);
	}
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hIndex)
		g_iIndex = StringToInt(newvalue);
	else if(cvar == g_hOrder)
		g_iOrder = StringToInt(newvalue);
	else if(cvar == g_hConnection)
	{
		strcopy(g_sConnection, sizeof(g_sConnection), newvalue);
		if(g_hDatabase != INVALID_HANDLE)
			CloseHandle(g_hDatabase);
			
		SQL_TConnect(SQL_ConnectCall, g_sConnection);
	}
	else if(cvar == g_hChatCommands)
		g_iNumCommands = ExplodeString(newvalue, ", ", g_sChatCommands, 16, 32);
	else if(cvar == g_hTimeFormat)
	{
		g_bNullTime = StrEqual(newvalue, "", false) ? true : false;
		Format(g_sTimeFormat, sizeof(g_sTimeFormat), "%s", newvalue);
	}
	else if(cvar == g_hAdvert)
		g_fAdvert = StringToFloat(newvalue);
}