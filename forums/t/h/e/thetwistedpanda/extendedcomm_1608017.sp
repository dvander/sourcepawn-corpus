/*
	Revision 3.0.1:
		Fixed erroneous logic with immunity checks that prevented equal level immunities from affecting each other. Failure was new > old, now is new < old
		Modified the original SQL/SQLite queries to ensure everything is created properly for new clients.
		Changed the version back to sm_extendedcomm_version, to provide compatibility with the AM forums.
		Removed code which attempted to issue final save queries upon unloading the plugin; it only errored out.
		Fixed an error in sm_mute/sm_gag/sm_silence that prevented the ExtendedComm versions from functioning.
		The table extendedcomm_version will now save the current extendedcomm_database cvar value.
			ALTER TABLE extendedcomm_version ADD COLUMN current_database varchar(32) NOT NULL default ''
			In the event that the saved database differs from the new database, the plugin will re-update the tables to ensure that they're proper.

	Revision 3.0.0:
		The "sm_" portion of the plugin has been dropped because I felt like it, and to make it slightly more similiar to basecomm.
		The sm_extendedcomm_update command has been rendered obsolete and thus removed.
			The plugin will now create an additional table, "extendedcomm_version" by default, and use it to store current version information.
			Version checks are run every time the plugin is run to ensure that the database is using the correct version, however, due to the above table, such checks will not impact the server.
		With the new natives that BaseComm provides in SourceMod v1.4, ExtendedComm will no longer reproduce BaseComm functionality.
			The plugin will no longer automatically disable BaseComm if it is within the /plugins/ directory.
			BaseComm is now required for ExtendedComm to function.
			Any features that ExtendedComm replicated, such as AllTalk/DeadTalk, have been returned to BaseComm control.
			The commands provided by BaseComm are hooked, rather than replaced, to ensure plugin compatibility.
		The natives that are released by ExtendedComm have been modified slightly to better suit the changes.
			ExtendedComm_GetClientMute/ExtendedComm_GetClientGag, which returned true/false for being muted/gagged, is now ExtendedComm_GetMuteType/ExtendedComm_GetGagType, which returns 1/2/3 for temporary/extended/permanent punishments.
			All natives will return -2 if the database isn't configured or it isn't connected; a value of -1 will be returned if the native doesn't have the proper data to return (i.e. attempting to get the expiration date on a temporary punishment)
		Plugin creates a new category of commands in the sm_admin menu and places all ExtendedComm commands (minus sm_commprune) within this category. Unfortanately, it's not possible to remove BaseComm commands from the menu without a minor edit/recompile.
		Optional support has been added to perform queries immediately after they've been issued, rather than waiting until the client disconnects / map changes.
		Optional support has been added to protect punishments added by console/administrators from lower level admins / plugins.
			When a player is punished, the punishing admin's immunity level will be saved with the client's information. When another punishment is issued while an existing punishment is currently active, the new punishment will only be saved if the new admin has a higher immunity level than the original admin.
			The same concept is applied to removing punishments; in order to remove an existing punishment, the new admin must have higher immunity than the original.
			Punishments that have been issued by console can only be removed by console, unless you're in the habit of assigning an immunity level of 2147483648.
		Optional support has been added for attaching reasons to extended / permanent punishments. Temporary punishments cannot have a reason attached. Custom reasons can be provided by using the console commands.
		The sm_commprune command has been added for ROOT administrators to manually prune the punishment database. (Punishments that expire are only removed on client connect, or if configured to auto prune every x maps).
		The sm_status command provided by 2.2.4 has been replaced with sm_commlist to provide compatibility with HLStatsX:CE/GameMe.
		To help provide support for mass targeting / scripts, the sm_unmute/sm_ungag/sm_unsilence commands will no longer remove extended punishments unless an additional parameter >= 1 is provided. That is to say, sm_unmute @all will remove all temporary mutes, but sm_unmute @all 1 will remove all temporary/extended/permanent mutes.
		The plugin will now play nicely with multiple mute/gag combinations (i.e. you can be temporarily/extended/permanently muted all at once).
		Late loading detection has been greatly improved and the server will no longer glitch/crash upon doing such.
		Translation support has been greatly improved and simplified.
		Plugin functionality should be maintained in the event of a database disconnection / misconfiguration as it reverts to only allowing temporary punishments.
		The extendedcomm_auto_prune cvar has been modified to support running every x maps, rather than every map.
		Fixed a minor issue where the dbi.inc was marked as not being required, yet it was definitely required.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <extendedcomm>
#include <dbi>
#include <basecomm>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "3.0.1"

//Determines update functionality
#define VERSION_CURRENT_UPDATE 1
#define VERSION_3_0_0_STEPS 1

//SQLite/MySQL Tables
#define COMM_TABLE "extendedcomm"
#define COMM_TABLE_VERSION "extendedcomm_version"
#define COMM_TABLE_PREVIOUS "extendedcomm" //ExtendedComm versions < 3.0.0

//Punishment Indexes
#define COMM_MUTE 1
#define COMM_GAG 2
#define COMM_SILENCE 3
#define COMM_MUTED 4
#define COMM_GAGGED 5
#define COMM_SILENCED 6

//Punishment Bitwise
#define COMM_MUTE_TIME 1
#define COMM_MUTE_PERM 2
#define COMM_GAG_TIME 1
#define COMM_GAG_PERM 2
#define COMM_MUTE_TEMP 1
#define COMM_GAG_TEMP 2

#define MAX_COMM_TIMES 32
new g_iNumTimes, g_iTimeSeconds[MAX_COMM_TIMES], g_iTimeFlags[MAX_COMM_TIMES];
new String:g_sTimeDisplays[MAX_COMM_TIMES][32];

#define MAX_COMM_REASONS 32
new g_iNumReasons, g_iReasonFlags[MAX_COMM_TIMES];
new String:g_sReasonDisplays[MAX_COMM_REASONS][32], String:g_sReasonReasons[MAX_COMM_REASONS][192];

new String:g_sSQL_VersionCreate[] = { "CREATE TABLE IF NOT EXISTS %s (primary_key int(4) PRIMARY KEY default 0, current_version varchar(8) NOT NULL default '', current_update int(4) NOT NULL default 0, current_database varchar(32) NOT NULL default '')" };
new String:g_sSQL_VersionUpdate[] = { "REPLACE INTO %s (current_version, current_update, current_database) VALUES ('%s', %d, '%s')" };
new String:g_sSQL_VersionSelect[] = { "SELECT current_update, current_database FROM %s" };
new String:g_sSQL_VersionExisting[] = { "SELECT steam_id FROM %s" };
 
new String:g_sSQL_CreateTable[1024] = { "CREATE TABLE IF NOT EXISTS %s (steam_id varchar(32) PRIMARY KEY default '', mute_type int(4) NOT NULL default 0, mute_length int(12) NOT NULL default 0, mute_admin varchar(64) NOT NULL default '', mute_time int(12) NOT NULL default 0, mute_reason varchar(256) NOT NULL default '', mute_level int(12) NOT NULL default 0, gag_type int(4) NOT NULL default 0, gag_length int(12) NOT NULL default 0, gag_admin varchar(64) NOT NULL default '', gag_time int(12) NOT NULL default 0, gag_reason varchar(256) NOT NULL default '', gag_level int(12) NOT NULL default 0)" };

new String:g_sSQL_PruneSelect[] = { "SELECT steam_id, mute_type, mute_length, mute_time, gag_type, gag_length, gag_time FROM %s" };
new String:g_sSQL_PruneUpdate[] = { "UPDATE %s SET mute_type = %d, mute_length = %d, mute_time = %d, gag_type = %d, gag_length = %d, gag_time = %d WHERE steam_id = '%s'" };
new String:g_sSQL_PruneDelete[] = { "DELETE FROM %s WHERE steam_id = '%s'" };

new String:g_sSQL_SaveClient[] = { "REPLACE INTO %s (steam_id, mute_type, mute_length, mute_time, mute_admin, mute_reason, mute_level, gag_type, gag_length, gag_time, gag_admin, gag_reason, gag_level) VALUES ('%s', %d, %d, %d, '%s', '%s', %d, %d, %d, %d, '%s', '%s', %d)" };
new String:g_sSQL_LoadClient[] = { "SELECT mute_type, mute_length, mute_time, mute_admin, mute_reason, mute_level, gag_type, gag_length, gag_time, gag_admin, gag_reason, gag_level FROM %s WHERE steam_id = '%s'" };
new String:g_sSQL_DeleteClient[] = { "DELETE FROM %s WHERE steam_id = '%s'" };

new String:g_sSQL_UpdateTables_3_0_0[][] = { "ALTER TABLE %s ADD COLUMN mute_reason varchar(128) default ''", "ALTER TABLE %s ADD COLUMN mute_level int(12) default 0", "ALTER TABLE %s ADD COLUMN gag_reason varchar(128) default ''", "ALTER TABLE %s ADD COLUMN gag_level int(12) default 0" };
new String:g_sSQL_SelectPlayerPre_3_0_0[] = { "SELECT steam_id, mute_type, mute_length, gag_type, gag_length FROM %s" };
new String:g_sSQL_UpdatePlayerPre_3_0_0[] = { "UPDATE %s SET mute_type = %d, mute_length = %d, gag_type = %d, gag_length = %d WHERE steam_id = '%s'" };
new String:g_sSQL_PrunePlayerPre_3_0_0[] = { "DELETE FROM %s WHERE steam_id = '%s'" };

new Handle:g_hDatabase = INVALID_HANDLE;
new Handle:g_hTopMenu = INVALID_HANDLE;
new Handle:g_hTrie_Temporary = INVALID_HANDLE;
new Handle:g_hConnection = INVALID_HANDLE;
new Handle:g_hTemporary = INVALID_HANDLE;
new Handle:g_hDelayQueries = INVALID_HANDLE;
new Handle:g_hObeyImmunity = INVALID_HANDLE;
new Handle:g_hLogActions = INVALID_HANDLE;
new Handle:g_hLogNotices = INVALID_HANDLE;
new Handle:g_hTimeFormat = INVALID_HANDLE;
new Handle:g_hAutoPrune = INVALID_HANDLE;

enum PeskyPanels
{
	curTarget,
	curIndex,
	viewingMute,
	viewingGag,
	viewingList
}

new AdminId:g_AdminId[MAXPLAYERS + 1];
new g_Immunity[MAXPLAYERS + 1];
new bool:g_bCommSave[MAXPLAYERS + 1];
new bool:g_bTempMuted[MAXPLAYERS + 1];
new String:g_sTempMuted[MAXPLAYERS + 1][32];
new bool:g_bTempGagged[MAXPLAYERS + 1];
new String:g_sTempGagged[MAXPLAYERS + 1][32];
new String:g_sName[MAXPLAYERS + 1][32];
new String:g_sSteam[MAXPLAYERS + 1][32];
new g_iMuteState[MAXPLAYERS + 1];
new g_iMuteLength[MAXPLAYERS + 1];
new g_iMuteTime[MAXPLAYERS + 1];
new g_iMuteLevel[MAXPLAYERS + 1];
new String:g_sMuteAdmin[MAXPLAYERS + 1][32];
new String:g_sMuteReason[MAXPLAYERS + 1][64];
new g_iGagState[MAXPLAYERS + 1];
new g_iGagLength[MAXPLAYERS + 1];
new g_iGagTime[MAXPLAYERS + 1];
new g_iGagLevel[MAXPLAYERS + 1];
new String:g_sGagAdmin[MAXPLAYERS + 1][32];
new String:g_sGagReason[MAXPLAYERS + 1][64];
new Handle:g_hTimer_GagExpire[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new Handle:g_hTimer_MuteExpire[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new g_iPeskyPanels[MAXPLAYERS + 1][PeskyPanels];

new g_iUpdateSteps, g_iAutoPrune, g_iPruneReady;
new bool:g_bLateLoad, bool:g_bLateQuery, bool:g_bTemporary, bool:g_bLogActions, bool:g_bLogNotices, bool:g_bNullTime, bool:g_bDelayQueries, bool:g_bObeyImmunity;
new String:g_sLogActions[256], String:g_sLogNotices[256], String:g_sTimeFormat[192], String:g_sConnection[32], String:g_sPrefixConsole[32], String:g_sPrefixChat[32];

public Plugin:myinfo = 
{
	name = "ExtendedComm",
	author = "Twisted|Panda",
	description = "Extends the commands provided by basecomm.smx, providing extended and permanent punishments, as well as methods to view current punishments.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("ExtendedComm_GetMuteType", Native_GetMuteType);
	CreateNative("ExtendedComm_GetMuteLength", Native_GetMuteLength);
	CreateNative("ExtendedComm_GetMuteStart", Native_GetMuteStart);
	CreateNative("ExtendedComm_GetMuteExpire", Native_GetMuteExpire);
	CreateNative("ExtendedComm_GetGagType", Native_GetGagType);
	CreateNative("ExtendedComm_GetGagLength", Native_GetGagLength);
	CreateNative("ExtendedComm_GetGagStart", Native_GetGagStart);
	CreateNative("ExtendedComm_GetGagExpire", Native_GetGagExpire);
	RegPluginLibrary("extendedcomm");
	
	g_bLateLoad = g_bLateQuery = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("extendedcomm.phrases");

	new Handle:_hTemp = INVALID_HANDLE;
	if(LibraryExists("adminmenu") && ((_hTemp = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(_hTemp);

	CreateConVar("sm_extendedcomm_version", PLUGIN_VERSION, "ExtendedComm: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hConnection = CreateConVar("extendedcomm_database", "", "The database configuration for ExtendedComm. Use \"\" to connect to a local sqlite database.", FCVAR_NONE);
	HookConVarChange(g_hConnection, OnSettingsChange);
	g_hTemporary = CreateConVar("extendedcomm_save_temporary", "0", "If enabled, temporary punishments issued by ExtendedComm will remain until the map changes (as opposed to disappearing on reconnecting). (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hTemporary, OnSettingsChange);
	g_hDelayQueries = CreateConVar("extendedcomm_delay_queries", "1", "If enabled, save queries will be delayed until the client disconnects, otherwise the save queries are executed upon issuing the punishment. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hDelayQueries, OnSettingsChange);
	g_hObeyImmunity = CreateConVar("extendedcomm_obey_immunity", "1", "If enabled, an admin's immunity is used when assigning a punishment and admins with lower immunity are inable to modify the existing punishment. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hObeyImmunity, OnSettingsChange);

	g_hLogActions = CreateConVar("extendedcomm_action_log", "", "The path for logging punishments related to ExtendedComm. Example: \"/logs/extendedcomm_actions.txt\"", FCVAR_NONE);
	HookConVarChange(g_hLogActions, OnSettingsChange);
	g_hLogNotices = CreateConVar("extendedcomm_notice_log", "", "The path for logging errors related to ExtendedComm. Example: Example: \"/logs/extendedcomm_notices.txt\"", FCVAR_NONE);
	HookConVarChange(g_hLogNotices, OnSettingsChange);
	g_hTimeFormat = CreateConVar("extendedcomm_time_format", "", "Determines the formatting for time and date display. Using \"\" will default to sm_datetime_format (/cfg/sourcemod.cfg)", FCVAR_NONE);
	HookConVarChange(g_hTimeFormat, OnSettingsChange);
	g_hAutoPrune = CreateConVar("extendedcomm_auto_prune", "0", "If enabled, ExtendedComm automatically checks the database for expired punishments every x maps, where x is the cvar, rather than waiting for the client to connect.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hAutoPrune, OnSettingsChange);
	AutoExecConfig(true, "extendedcomm");

	AddCommandListener(Command_IssueMute, "sm_mute");
	AddCommandListener(Command_RemoveMute, "sm_unmute");
	AddCommandListener(Command_IssueGag, "sm_gag");
	AddCommandListener(Command_RemoveGag, "sm_ungag");
	AddCommandListener(Command_IssueSilence, "sm_silence");
	AddCommandListener(Command_RemoveSilence, "sm_unsilence");
	RegAdminCmd("sm_commlist", Command_List, ADMFLAG_CHAT, "Extended Comm: Provides functionality for viewing current comm punishments.");
	RegAdminCmd("sm_commprune", Command_Prune, ADMFLAG_ROOT, "Extended Comm: Provides functionality for automatically pruning the table for expired punishments.");

	HookEvent("player_changename", Event_OnPlayerName, EventHookMode_Pre);

	g_hTrie_Temporary = CreateTrie();
	Void_SetDefaults();
	Void_LoadTimes();
	Void_LoadReasons();
	
	//Lazy Patch
	//- Punishments issued by console can only be removed by console.
	g_iMuteLevel[0] = g_iGagLevel[0] = 2147483648;
}

public OnLibraryRemoved(const String:name[])
{
	if(StrEqual(name, "adminmenu"))
		g_hTopMenu = INVALID_HANDLE;
}

public OnAdminMenuReady(Handle:topmenu)
{
	if(topmenu == g_hTopMenu)
		return;

	g_hTopMenu = topmenu;
	new TopMenuObject:MenuObject = AddToTopMenu(g_hTopMenu, "excomm_cmds", TopMenuObject_Category, Handle_Commands, INVALID_TOPMENUOBJECT);
	if(MenuObject == INVALID_TOPMENUOBJECT)
		return;

	AddToTopMenu(g_hTopMenu, "excomm_list", TopMenuObject_Item, Handle_MenuList, MenuObject, "sm_commlist", ADMFLAG_CHAT);
	AddToTopMenu(g_hTopMenu, "excomm_gag", TopMenuObject_Item, Handle_MenuGag, MenuObject, "sm_gag", ADMFLAG_CHAT);
	AddToTopMenu(g_hTopMenu, "excomm_ungag", TopMenuObject_Item, Handle_MenuGagged, MenuObject, "sm_ungag", ADMFLAG_CHAT);
	AddToTopMenu(g_hTopMenu, "excomm_mute", TopMenuObject_Item, Handle_MenuMute, MenuObject, "sm_mute", ADMFLAG_CHAT);
	AddToTopMenu(g_hTopMenu, "excomm_unmute", TopMenuObject_Item, Handle_MenuMuted, MenuObject, "sm_unmute", ADMFLAG_CHAT);
	AddToTopMenu(g_hTopMenu, "excomm_silence", TopMenuObject_Item, Handle_MenuSilence, MenuObject, "sm_silence", ADMFLAG_CHAT);
	AddToTopMenu(g_hTopMenu, "excomm_unsilence", TopMenuObject_Item, Handle_MenuSilenced, MenuObject, "sm_unsilence", ADMFLAG_CHAT);
}

public OnPluginEnd()
{
	ClearTrie(g_hTrie_Temporary);
}

public OnConfigsExecuted()
{
	Format(g_sPrefixChat, sizeof(g_sPrefixChat), "%T", "Prefix_Chat", LANG_SERVER);
	Format(g_sPrefixConsole, sizeof(g_sPrefixConsole), "%T", "Prefix_Console", LANG_SERVER);

	if(g_bLateLoad)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				g_AdminId[i] = GetUserAdmin(i);
				GetClientAuthString(i, g_sSteam[i], 32);
				GetClientName(i, g_sName[i], 32);
				g_Immunity[i] = (g_AdminId[i] == INVALID_ADMIN_ID) ? 0 : GetAdminImmunityLevel(g_AdminId[i]);
			}
		}
				
		g_bLateLoad = false;
	}
}

public OnMapStart()
{
	if(g_hTrie_Temporary == INVALID_HANDLE)
		g_hTrie_Temporary = CreateTrie();
	else if(g_bTemporary)
		ClearTrie(g_hTrie_Temporary);

	if(g_hDatabase == INVALID_HANDLE)
	{
		g_iUpdateSteps = 0;
		SQL_TConnect(SQL_ConnectCall, StrEqual(g_sConnection, "") ? "storage-local" : g_sConnection);
	}
	else if(g_iAutoPrune)
	{
		if(!g_iPruneReady)
		{
			g_iPruneReady = g_iAutoPrune - 1;
			decl String:_sQuery[512];
			Format(_sQuery, sizeof(_sQuery), g_sSQL_PruneSelect, COMM_TABLE);
			SQL_TQuery(g_hDatabase, SQL_AutoPrune, _sQuery, -1);
		}
		else
			g_iPruneReady--;
	}
}

public OnClientAuthorized(client)
{
	if(client > 0 && !IsFakeClient(client))
	{
		GetClientName(client, g_sName[client], 32);
		if(g_bTemporary)
		{
			new _iState;
			if(GetTrieValue(g_hTrie_Temporary, g_sSteam[client], _iState))
			{
				if(_iState & COMM_GAG_TEMP)
					BaseComm_SetClientGag(client, true);
				if(_iState & COMM_MUTE_TEMP)
					BaseComm_SetClientMute(client, true);
			}
		}

		if(g_hDatabase != INVALID_HANDLE)
		{
			decl String:_sQuery[512];
			Format(_sQuery, sizeof(_sQuery), g_sSQL_LoadClient, COMM_TABLE, g_sSteam[client]);
			SQL_TQuery(g_hDatabase, SQL_LoadPlayerCall, _sQuery, client);
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if(client > 0 && !IsFakeClient(client))
	{
		g_AdminId[client] = GetUserAdmin(client);
		GetClientAuthString(client, g_sSteam[client], 32);
		g_Immunity[client] = (g_AdminId[client] == INVALID_ADMIN_ID) ? 0 : GetAdminImmunityLevel(g_AdminId[client]);
	}
}

public OnClientDisconnect(client)
{
	if(client > 0 && !IsFakeClient(client))
	{
		if(g_hTimer_MuteExpire[client] != INVALID_HANDLE && CloseHandle(g_hTimer_MuteExpire[client]))
			g_hTimer_MuteExpire[client] = INVALID_HANDLE;

		if(g_hTimer_GagExpire[client] != INVALID_HANDLE && CloseHandle(g_hTimer_GagExpire[client]))
			g_hTimer_GagExpire[client] = INVALID_HANDLE;
			
		if(g_bTemporary)
		{
			new _iState;
			if(g_bTempMuted[client])
				_iState += COMM_MUTE_TEMP;
			if(g_bTempGagged[client])
				_iState += COMM_GAG_TEMP;
			if(_iState)
				SetTrieValue(g_hTrie_Temporary, g_sSteam[client], _iState);
		}

		if(g_bDelayQueries && g_bCommSave[client])
		{
			Void_SaveClient(client);
			g_bCommSave[client] = false;
		}
	}
}

public Action:Event_OnPlayerName(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && IsClientInGame(client))
		GetEventString(event, "newname", g_sName[client], 32);
}

Void_SaveClient(client)
{
	if(g_hDatabase != INVALID_HANDLE)
	{
		decl String:_sQuery[512];
		if(!g_iMuteState[client] && !g_iGagState[client])
		{
			Format(_sQuery, sizeof(_sQuery), g_sSQL_DeleteClient, COMM_TABLE, g_sSteam[client]);
			SQL_TQuery(g_hDatabase, SQL_DeletePlayerCall, _sQuery, GetClientUserId(client));
		}
		else
		{
			Format(_sQuery, sizeof(_sQuery), g_sSQL_SaveClient, COMM_TABLE, g_sSteam[client], g_iMuteState[client], g_iMuteLength[client], g_iMuteTime[client], g_sMuteAdmin[client], g_sMuteReason[client], g_iMuteLevel[client], g_iGagState[client], g_iGagLength[client], g_iGagTime[client], g_sGagAdmin[client],	g_sGagReason[client], g_iGagLevel[client]);
			SQL_TQuery(g_hDatabase, SQL_SavePlayerCall, _sQuery, GetClientUserId(client));
		}
	}
}

PerformMuteCommand(client, target, length, String:reason[], String:admin[])
{	
	if(length == -1)
	{
		g_bTempMuted[target] = true;
		strcopy(g_sTempMuted[target], sizeof(g_sTempMuted[]), admin);

		ShowActivity2(client, g_sPrefixChat, "%t", "Log_Mute_Issue_Temp", target);
		LogCommAction(client, target, "%T", "Log_Mute_Issue_Temp", LANG_SERVER, target);
	}
	else
	{
		if(g_bObeyImmunity && g_iMuteState[target] && g_Immunity[client] < g_iMuteLevel[target])
		{
			if(client)
				PrintToChat(client, "%s%t", g_sPrefixChat, "Command_Mute_Issue_Immunity", target);
			else
				ReplyToCommand(client, "%s%t", g_sPrefixConsole, "Command_Mute_Issue_Immunity", target);
			
			return;
		}
	
		if(!length)
		{
			if(!(g_iMuteState[target] & COMM_MUTE_PERM))
				g_iMuteState[target] += COMM_MUTE_PERM;

			ShowActivity2(client, g_sPrefixChat, "%t", "Log_Mute_Issue_Perm", target);
			LogCommAction(client, target, "%T", "Log_Mute_Issue_Perm", LANG_SERVER, target);
		}
		else
		{
			if(!(g_iMuteState[target] & COMM_MUTE_TIME))
				g_iMuteState[target] += COMM_MUTE_TIME;

			if(g_hTimer_MuteExpire[target] != INVALID_HANDLE)
				CloseHandle(g_hTimer_MuteExpire[target]);
			g_hTimer_MuteExpire[target] = CreateTimer(float(length), Timer_MuteExpire, target, TIMER_FLAG_NO_MAPCHANGE);

			ShowActivity2(client, g_sPrefixChat, "%t", "Log_Mute_Issue_Time", target, length / 60);
			LogCommAction(client, target, "%T", "Log_Mute_Issue_Time", LANG_SERVER, target, length / 60);
		}
		
		g_iMuteLength[target] = length;
		g_iMuteTime[target] = GetTime();
		strcopy(g_sMuteAdmin[target], sizeof(g_sMuteAdmin[]), admin);
		strcopy(g_sMuteReason[target], sizeof(g_sMuteReason[]), reason);
		if(g_bObeyImmunity)
			g_iMuteLevel[target] = g_Immunity[client];
	
		if(g_bDelayQueries)
			g_bCommSave[target] = true;
		else
			Void_SaveClient(target);
	}

	if(!BaseComm_IsClientMuted(target))
		BaseComm_SetClientMute(target, true);
}

PerformMutedCommand(client, target, bool:remove)
{
	if(g_bTempMuted[target])
	{
		g_bTempMuted[target] = false;
		g_sTempMuted[target][0] = '\0';
		if(!g_bTempGagged[target])
			RemoveFromTrie(g_hTrie_Temporary, g_sSteam[target]);
		else
			SetTrieValue(g_hTrie_Temporary, g_sSteam[target], COMM_GAG_TEMP);

		ShowActivity2(client, g_sPrefixChat, "%t", "Log_Mute_Remove_Temp", target);
		LogCommAction(client, target, "%T", "Log_Mute_Remove_Temp", LANG_SERVER, target);
	}

	if(remove)
	{
		if(g_bObeyImmunity && g_iMuteState[target] && g_Immunity[client] < g_iMuteLevel[target])
		{
			if(client)
				PrintToChat(client, "%s%t", g_sPrefixChat, "Command_Mute_Remove_Immunity", target);
			else
				ReplyToCommand(client, "%s%t", g_sPrefixConsole, "Command_Mute_Remove_Immunity", target);
			
			return;
		}

		if(g_iMuteState[target] & COMM_MUTE_PERM)
		{
			ShowActivity2(client, g_sPrefixChat, "%t", "Log_Mute_Remove_Perm", target);
			LogCommAction(client, target, "%T", "Log_Mute_Remove_Perm", LANG_SERVER, target);
		}
		else if(g_iMuteState[target] & COMM_MUTE_TIME)
		{
			ShowActivity2(client, g_sPrefixChat, "%t", "Log_Mute_Remove_Time", target, g_iMuteLength[target] / 60);
			LogCommAction(client, target, "%T", "Log_Mute_Remove_Time", LANG_SERVER, target, g_iMuteLength[target] / 60);
		}

		g_iMuteState[target] &= ~COMM_MUTE_PERM;
		if(g_iMuteState[target] & COMM_MUTE_TIME)
		{
			g_iMuteState[target] &= ~COMM_MUTE_TIME;
			if(g_hTimer_MuteExpire[target] != INVALID_HANDLE && CloseHandle(g_hTimer_MuteExpire[target]))
				g_hTimer_MuteExpire[target] = INVALID_HANDLE;
		}
		
		g_iMuteLength[target] = 0;
		g_iMuteTime[target] = 0;
		g_sMuteAdmin[target][0] = '\0';
		g_sMuteReason[target][0] = '\0';
		g_iMuteLevel[target] = 0;

		if(g_bDelayQueries)
			g_bCommSave[target] = true;
		else
			Void_SaveClient(target);
	}

	if(!g_iMuteState[target] && BaseComm_IsClientMuted(target))
		BaseComm_SetClientMute(target, false);
}

PerformGagCommand(client, target, length, String:reason[], String:admin[])
{
	if(length == -1)
	{
		g_bTempGagged[target] = true;
		strcopy(g_sTempGagged[target], sizeof(g_sTempGagged[]), admin);

		ShowActivity2(client, g_sPrefixChat, "%t", "Log_Gag_Issue_Temp", target);
		LogCommAction(client, target, "%T", "Log_Gag_Issue_Temp", LANG_SERVER, target);
	}
	else
	{
		if(g_bObeyImmunity && g_iGagState[target] && g_Immunity[client] < g_iGagLevel[target])
		{
			if(client)
				PrintToChat(client, "%s%t", g_sPrefixChat, "Command_Gag_Issue_Immunity", target);
			else
				ReplyToCommand(client, "%s%t", g_sPrefixConsole, "Command_Gag_Issue_Immunity", target);
			
			return;
		}

		if(!length)
		{
			if(!(g_iGagState[target] & COMM_GAG_PERM))
				g_iGagState[target] += COMM_GAG_PERM;

			ShowActivity2(client, g_sPrefixChat, "%t", "Log_Gag_Issue_Perm", target);
			LogCommAction(client, target, "%T", "Log_Gag_Issue_Perm", LANG_SERVER, target);
		}
		else
		{
			if(!(g_iGagState[target] & COMM_GAG_TIME))
				g_iGagState[target] += COMM_GAG_TIME;

			if(g_hTimer_GagExpire[target] != INVALID_HANDLE)
				CloseHandle(g_hTimer_GagExpire[target]);
			g_hTimer_GagExpire[target] = CreateTimer(float(length), Timer_GagExpire, target, TIMER_FLAG_NO_MAPCHANGE);
				
			ShowActivity2(client, g_sPrefixChat, "%t", "Log_Gag_Issue_Time", target, length / 60);
			LogCommAction(client, target, "%T", "Log_Gag_Issue_Time", LANG_SERVER, target, length / 60);
		}
		
		g_iGagLength[target] = length;
		g_iGagTime[target] = GetTime();
		strcopy(g_sGagAdmin[target], sizeof(g_sGagAdmin[]), admin);
		strcopy(g_sGagReason[target], sizeof(g_sGagReason[]), reason);
		if(g_bObeyImmunity)
			g_iGagLevel[target] = g_Immunity[client];

		if(g_bDelayQueries)
			g_bCommSave[target] = true;
		else
			Void_SaveClient(target);
	}

	if(!BaseComm_IsClientGagged(target))
		BaseComm_SetClientGag(target, true);
}

PerformGaggedCommand(client, target, bool:remove)
{	
	if(g_bTempGagged[target])
	{
		g_bTempGagged[target] = false;
		g_sTempGagged[target][0] = '\0';
		if(!g_bTempMuted[target])
			RemoveFromTrie(g_hTrie_Temporary, g_sSteam[target]);
		else
			SetTrieValue(g_hTrie_Temporary, g_sSteam[target], COMM_MUTE_TEMP);

		ShowActivity2(client, g_sPrefixChat, "%t", "Log_Gag_Remove_Temp", target);
		LogCommAction(client, target, "%T", "Log_Gag_Remove_Temp", LANG_SERVER, target);
	}
	
	if(remove)
	{
		if(g_bObeyImmunity && g_iGagState[target] && g_Immunity[client] < g_iGagLevel[target])
		{
			if(client)
				PrintToChat(client, "%s%t", g_sPrefixChat, "Command_Gag_Remove_Immunity", target);
			else
				ReplyToCommand(client, "%s%t", g_sPrefixConsole, "Command_Gag_Remove_Immunity", target);
			
			return;
		}

		if(g_iGagState[target] & COMM_GAG_PERM)
		{
			ShowActivity2(client, g_sPrefixChat, "%t", "Log_Gag_Remove_Perm", target);
			LogCommAction(client, target, "%T", "Log_Gag_Remove_Perm", LANG_SERVER, target);
		}
		else if(g_iGagState[target] & COMM_GAG_TIME)
		{
			ShowActivity2(client, g_sPrefixChat, "%t", "Log_Gag_Remove_Time", target, g_iGagLength[target] / 60);
			LogCommAction(client, target, "%T", "Log_Gag_Remove_Time", LANG_SERVER, target, g_iGagLength[target] / 60);
		}

		g_iGagState[target] &= ~COMM_GAG_PERM;
		if(g_iGagState[target] & COMM_GAG_TIME)
		{
			g_iGagState[target] &= ~COMM_GAG_TIME;
			if(g_hTimer_GagExpire[target] != INVALID_HANDLE && CloseHandle(g_hTimer_GagExpire[target]))
				g_hTimer_GagExpire[target] = INVALID_HANDLE;
		}
		
		g_iGagLength[target] = 0;
		g_iGagTime[target] = 0;
		g_sGagAdmin[target][0] = '\0';
		g_sGagReason[target][0] = '\0';
		g_iGagLevel[target] = 0;

		if(g_bDelayQueries)
			g_bCommSave[target] = true;
		else
			Void_SaveClient(target);
	}

	if(!g_iGagState[target] && BaseComm_IsClientGagged(target))
		BaseComm_SetClientGag(target, false);
}

PerformSilenceCommand(client, target, length, String:reason[], String:admin[])
{
	new _iReturn;
	if(length == -1)
	{
		g_bTempMuted[target] = true;
		g_bTempGagged[target] = true;
		strcopy(g_sTempMuted[target], sizeof(g_sTempMuted[]), admin);
		strcopy(g_sTempGagged[target], sizeof(g_sTempGagged[]), admin);

		ShowActivity2(client, g_sPrefixChat, "%t", "Log_Silence_Issue_Temp", target);
		LogCommAction(client, target, "%T", "Log_Silence_Issue_Temp", LANG_SERVER, target);
	}
	else
	{
		if(g_bObeyImmunity)
		{
			if(g_iGagState[target] && g_Immunity[client] < g_iGagLevel[target] && g_iMuteState[target] && g_Immunity[client] < g_iMuteLevel[target])
			{
				_iReturn += (COMM_GAG_TEMP + COMM_MUTE_TEMP);
				if(client)
					PrintToChat(client, "%s%t", g_sPrefixChat, "Command_Silence_Issue_Immunity", target);
				else
					ReplyToCommand(client, "%s%t", g_sPrefixConsole, "Command_Silence_Issue_Immunity", target);
			}
			else
			{
				if(g_iGagState[target] && g_Immunity[client] < g_iGagLevel[target])
				{
					_iReturn += COMM_GAG_TEMP;
					if(client)
						PrintToChat(client, "%s%t", g_sPrefixChat, "Command_Silence_Issue_Immunity_Gag", target);
					else
						ReplyToCommand(client, "%s%t", g_sPrefixConsole, "Command_Silence_Issue_Immunity_Gag", target);
				}

				if(g_iMuteState[target] && g_Immunity[client] < g_iMuteLevel[target])
				{
					_iReturn += COMM_MUTE_TEMP;
					if(client)
						PrintToChat(client, "%s%t", g_sPrefixChat, "Command_Silence_Issue_Immunity_Mute", target);
					else
						ReplyToCommand(client, "%s%t", g_sPrefixConsole, "Command_Silence_Issue_Immunity_Mute", target);
				}
			}
			
			if((_iReturn & COMM_GAG_TEMP) && (_iReturn & COMM_MUTE_TEMP))
				return;
		}

		if(!length)
		{
			if(!g_bObeyImmunity || !(_iReturn & COMM_MUTE_TEMP))
				if(!(g_iMuteState[target] & COMM_MUTE_PERM))
					g_iMuteState[target] += COMM_MUTE_PERM;

			if(!g_bObeyImmunity || !(_iReturn & COMM_GAG_TEMP))
				if(!(g_iGagState[target] & COMM_GAG_PERM))
					g_iGagState[target] += COMM_GAG_PERM;

			ShowActivity2(client, g_sPrefixChat, "%t", "Log_Silence_Issue_Perm", target);
			LogCommAction(client, target, "%T", "Log_Silence_Issue_Perm", LANG_SERVER, target);
		}
		else
		{
			if(!g_bObeyImmunity || !(_iReturn & COMM_MUTE_TEMP))
			{
				if(!(g_iMuteState[target] & COMM_MUTE_TIME))
					g_iMuteState[target] += COMM_MUTE_TIME;
				if(g_hTimer_MuteExpire[target] != INVALID_HANDLE)
					CloseHandle(g_hTimer_MuteExpire[target]);
				g_hTimer_MuteExpire[target] = CreateTimer(float(length), Timer_MuteExpire, target, TIMER_FLAG_NO_MAPCHANGE);
			}

			if(!g_bObeyImmunity || !(_iReturn & COMM_GAG_TEMP))
			{
				if(!(g_iGagState[target] & COMM_GAG_TIME))
					g_iGagState[target] += COMM_GAG_TIME;
				if(g_hTimer_GagExpire[target] != INVALID_HANDLE)
					CloseHandle(g_hTimer_GagExpire[target]);
				g_hTimer_GagExpire[target] = CreateTimer(float(length), Timer_GagExpire, target, TIMER_FLAG_NO_MAPCHANGE);
			}

			ShowActivity2(client, g_sPrefixChat, "%t", "Log_Silence_Issue_Time", target, length / 60);
			LogCommAction(client, target, "%T", "Log_Silence_Issue_Time", LANG_SERVER, target, length / 60);
		}

		if(!g_bObeyImmunity || !(_iReturn & COMM_GAG_TEMP))
		{
			g_iGagLength[target] = length;
			g_iGagTime[target] = GetTime();
			strcopy(g_sGagAdmin[target], sizeof(g_sGagAdmin[]), admin);
			strcopy(g_sGagReason[target], sizeof(g_sGagReason[]), reason);
			if(g_bObeyImmunity)
				g_iGagLevel[target] = g_Immunity[client];
		}

		if(!g_bObeyImmunity || !(_iReturn & COMM_MUTE_TEMP))
		{
			g_iMuteLength[target] = length;
			g_iMuteTime[target] = GetTime();
			strcopy(g_sMuteAdmin[target], sizeof(g_sMuteAdmin[]), admin);
			strcopy(g_sMuteReason[target], sizeof(g_sMuteReason[]), reason);
			if(g_bObeyImmunity)
				g_iMuteLevel[target] = g_Immunity[client];
		}

		if(g_bDelayQueries)
			g_bCommSave[target] = true;
		else
			Void_SaveClient(target);
	}

	if((!_iReturn || !(_iReturn & COMM_MUTE_TEMP)) && !BaseComm_IsClientMuted(target))
		BaseComm_SetClientMute(target, true);

	if((!_iReturn || !(_iReturn & COMM_GAG_TEMP)) && !BaseComm_IsClientGagged(target))
		BaseComm_SetClientGag(target, true);	
}

PerformSilencedCommand(client, target, bool:remove)
{
	if(g_bTempMuted[target] || g_bTempGagged[target])
	{
		g_bTempMuted[target] = false;
		g_bTempGagged[target] = false;
		g_sTempMuted[target][0] = '\0';
		g_sTempGagged[target][0] = '\0';
		
		RemoveFromTrie(g_hTrie_Temporary, g_sSteam[target]);
		ShowActivity2(client, g_sPrefixChat, "%t", "Log_Silence_Remove_Temp", target);
		LogCommAction(client, target, "%T", "Log_Silence_Remove_Temp", LANG_SERVER, target);
	}
	
	if(remove)
	{
		if(g_bObeyImmunity)
		{
			new _iReturn;
			if(g_iGagState[target] && g_Immunity[client] < g_iGagLevel[target] && g_iMuteState[target] && g_Immunity[client] < g_iMuteLevel[target])
			{
				_iReturn += (COMM_GAG_TEMP + COMM_MUTE_TEMP);
				if(client)
					PrintToChat(client, "%s%t", g_sPrefixChat, "Command_Silence_Remove_Immunity", target);
				else
					ReplyToCommand(client, "%s%t", g_sPrefixConsole, "Command_Silence_Remove_Immunity", target);
			}
			else
			{
				if(g_iGagState[target] && g_Immunity[client] < g_iGagLevel[target])
				{
					_iReturn += COMM_GAG_TEMP;
					if(client)
						PrintToChat(client, "%s%t", g_sPrefixChat, "Command_Silence_Remove_Immunity_Gag", target);
					else
						ReplyToCommand(client, "%s%t", g_sPrefixConsole, "Command_Silence_Remove_Immunity_Gag", target);
				}

				if(g_iMuteState[target] && g_Immunity[client] < g_iMuteLevel[target])
				{
					_iReturn += COMM_MUTE_TEMP;
					if(client)
						PrintToChat(client, "%s%t", g_sPrefixChat, "Command_Silence_Remove_Immunity_Mute", target);
					else
						ReplyToCommand(client, "%s%t", g_sPrefixConsole, "Command_Silence_Remove_Immunity_Mute", target);
				}
			}
			
			if((_iReturn & COMM_GAG_TEMP) && (_iReturn & COMM_MUTE_TEMP))
				return;
		}

		if(g_iGagState[target] & COMM_GAG_PERM && g_iMuteState[target] & COMM_MUTE_PERM)
		{
			ShowActivity2(client, g_sPrefixChat, "%t", "Log_Silence_Remove_Perm", target);
			LogCommAction(client, target, "%T", "Log_Silence_Remove_Perm", LANG_SERVER, target);
		}
		else if(g_iMuteState[target] & COMM_MUTE_TIME && g_iGagState[target] & COMM_GAG_TIME)
		{
			ShowActivity2(client, g_sPrefixChat, "%t", "Log_Silence_Remove_Time", target);
			LogCommAction(client, target, "%T", "Log_Silence_Remove_Time", LANG_SERVER, target);
		}
		else
		{
			ShowActivity2(client, g_sPrefixChat, "%t", "Log_Silence_Remove_Misc", target);
			LogCommAction(client, target, "%T", "Log_Silence_Remove_Misc", LANG_SERVER, target);
		}

		g_iMuteState[target] &= ~COMM_MUTE_PERM;
		if(g_iMuteState[target] & COMM_MUTE_TIME)
		{
			g_iMuteState[target] &= ~COMM_MUTE_TIME;
			if(g_hTimer_MuteExpire[target] != INVALID_HANDLE && CloseHandle(g_hTimer_MuteExpire[target]))
				g_hTimer_MuteExpire[target] = INVALID_HANDLE;
		}
		
		g_iGagState[target] &= ~COMM_GAG_PERM;
		if(g_iGagState[target] & COMM_GAG_TIME)
		{
			g_iGagState[target] &= ~COMM_GAG_TIME;
			if(g_hTimer_GagExpire[target] != INVALID_HANDLE && CloseHandle(g_hTimer_GagExpire[target]))
				g_hTimer_GagExpire[target] = INVALID_HANDLE;
		}
		
		g_iGagLength[target] = g_iMuteLength[target] = 0;
		g_iGagTime[target] = g_iMuteTime[target] = 0;
		g_sMuteAdmin[target][0] = g_sGagAdmin[target][0] = '\0';
		g_sMuteReason[target][0] = g_sGagReason[target][0] = '\0';
		g_iMuteLevel[target] = g_iGagLevel[target] = 0;

		if(g_bDelayQueries)
			g_bCommSave[target] = true;
		else
			Void_SaveClient(target);
	}

	if(!g_iGagState[target] && BaseComm_IsClientGagged(target))
		BaseComm_SetClientGag(target, false);
	if(!g_iMuteState[target] && BaseComm_IsClientMuted(target))
		BaseComm_SetClientMute(target, false);
}

public Action:Command_IssueMute(client, const String:command[], args)
{
	decl String:_sTemp[192], String:_sReason[192];
	if(args < 1)
	{
		Format(_sTemp, sizeof(_sTemp), "%s%T", g_sPrefixConsole, "Command_Issue_Mute_Usage", client);

		ReplyToCommand(client, _sTemp);
		return Plugin_Stop;
	}

	new bool:_bAccess, _iLength = -1;
	GetCmdArg(1, _sTemp, sizeof(_sTemp));
	if(g_iNumTimes && args > 1 && g_hDatabase != INVALID_HANDLE)
	{
		decl String:_sTime[64];
		GetCmdArg(2, _sTime, sizeof(_sTime));

		_iLength = StringToInt(_sTime);
		if(_iLength < 0)
			_iLength = -1;
		else
		{
			new _iLast, _iFlag = client ? GetUserFlagBits(client) : 0;
			for(new i = g_iNumTimes; i >= 0; i--)
			{
				if(((!_iLength || _iLength == -1) && _iLength == g_iTimeSeconds[i]) || (g_iTimeSeconds[i] > 0 && _iLength <= g_iTimeSeconds[i]))
				{
					if(!g_iTimeFlags[i] || _iFlag & g_iTimeFlags[i])
					{
						_bAccess = true;
						break;
					}
				}
				else
					_iLast = i;
			}

			if(!_bAccess)
			{
				decl String:_sBuffer[192];
				if(!_iLength)
					Format(_sBuffer, sizeof(_sBuffer), "%s%T", g_sPrefixConsole, "Command_Issue_Mute_Permission_Perm", client);
				else
					Format(_sBuffer, sizeof(_sBuffer), "%s%T", g_sPrefixConsole, "Command_Issue_Mute_Permission_Time", client, g_iTimeSeconds[_iLast]);

				ReplyToCommand(client, _sBuffer);
				return Plugin_Stop;
			}
		}
	
		if(args >= 3)
			GetCmdArg(3, _sReason, sizeof(_sReason));
		else
			_sReason[0] = '\0';
	}
	else
		_sReason[0] = '\0';
	
	decl String:_sName[MAX_TARGET_LENGTH], _iTargets[MAXPLAYERS], _iCount, bool:_bTemp;
	if((_iCount = ProcessTargetString(_sTemp, client, _iTargets, sizeof(_iTargets), COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED, _sName, sizeof(_sName), _bTemp)) <= COMMAND_TARGET_NONE)
		return Plugin_Continue;

	GetIssuerName(client, _sTemp, sizeof(_sTemp));
	for (new i = 0; i < _iCount; i++)
		if(IsClientInGame(_iTargets[i]) && CanUserTarget(client, _iTargets[i]))
			PerformMuteCommand(client, _iTargets[i], _iLength * 60, _sReason, _sTemp);

	return Plugin_Stop;	
}

public Action:Command_IssueGag(client, const String:command[], args)
{
	decl String:_sTemp[192], String:_sReason[192];
	if(args < 1)
	{
		Format(_sTemp, sizeof(_sTemp), "%s%T", g_sPrefixConsole, "Command_Issue_Gag_Usage", client);

		ReplyToCommand(client, _sTemp);
		return Plugin_Stop;
	}

	new bool:_bAccess, _iLength = -1;
	GetCmdArg(1, _sTemp, sizeof(_sTemp));
	if(g_iNumTimes && args > 1 && g_hDatabase != INVALID_HANDLE)
	{
		decl String:_sTime[64];
		GetCmdArg(2, _sTime, sizeof(_sTime));

		_iLength = StringToInt(_sTime);
		if(_iLength < 0)
			_iLength = -1;
		else
		{
			new _iLast, _iFlag = client ? GetUserFlagBits(client) : 0;
			for(new i = g_iNumTimes; i >= 0; i--)
			{
				if(((!_iLength || _iLength == -1) && _iLength == g_iTimeSeconds[i]) || (g_iTimeSeconds[i] > 0 && _iLength <= g_iTimeSeconds[i]))
				{
					if(!g_iTimeFlags[i] || _iFlag & g_iTimeFlags[i])
					{
						_bAccess = true;
						break;
					}
				}
				else
					_iLast = i;
			}

			if(!_bAccess)
			{
				decl String:_sBuffer[192];
				if(!_iLength)
					Format(_sBuffer, sizeof(_sBuffer), "%s%T", g_sPrefixConsole, "Command_Issue_Gag_Permission_Perm", client);
				else
					Format(_sBuffer, sizeof(_sBuffer), "%s%T", g_sPrefixConsole, "Command_Issue_Gag_Permission_Time", client, g_iTimeSeconds[_iLast]);

				ReplyToCommand(client, _sBuffer);
				return Plugin_Stop;
			}
		}

		if(args >= 3)
			GetCmdArg(3, _sReason, sizeof(_sReason));
		else
			_sReason[0] = '\0';
	}
	else
		_sReason[0] = '\0';

	decl String:_sName[MAX_TARGET_LENGTH], _iTargets[MAXPLAYERS], _iCount, bool:_bTemp;
	if((_iCount = ProcessTargetString(_sTemp, client, _iTargets, sizeof(_iTargets), COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED, _sName, sizeof(_sName), _bTemp)) <= COMMAND_TARGET_NONE)
		return Plugin_Continue;

	GetIssuerName(client, _sTemp, sizeof(_sTemp));
	for (new i = 0; i < _iCount; i++)
		if(IsClientInGame(_iTargets[i]) && CanUserTarget(client, _iTargets[i]))
			PerformGagCommand(client, _iTargets[i], _iLength * 60, _sReason, _sTemp);

	return Plugin_Stop;	
}


public Action:Command_IssueSilence(client, const String:command[], args)
{
	decl String:_sTemp[192], String:_sReason[192];
	if(args < 1)
	{
		Format(_sTemp, sizeof(_sTemp), "%s%T", g_sPrefixConsole, "Command_Issue_Silence_Usage", client);

		ReplyToCommand(client, _sTemp);
		return Plugin_Stop;
	}

	new bool:_bAccess, _iLength = -1;
	GetCmdArg(1, _sTemp, sizeof(_sTemp));
	if(g_iNumTimes && args > 1 && g_hDatabase != INVALID_HANDLE)
	{
		decl String:_sTime[64];
		GetCmdArg(2, _sTime, sizeof(_sTime));

		_iLength = StringToInt(_sTime);
		if(_iLength < 0)
			_iLength = -1;
		else
		{
			new _iLast, _iFlag = client ? GetUserFlagBits(client) : 0;
			for(new i = g_iNumTimes; i >= 0; i--)
			{
				if(((!_iLength || _iLength == -1) && _iLength == g_iTimeSeconds[i]) || (g_iTimeSeconds[i] > 0 && _iLength <= g_iTimeSeconds[i]))
				{
					if(!g_iTimeFlags[i] || _iFlag & g_iTimeFlags[i])
					{
						_bAccess = true;
						break;
					}
				}
				else
					_iLast = i;
			}

			if(!_bAccess)
			{
				decl String:_sBuffer[192];
				if(!_iLength)
					Format(_sBuffer, sizeof(_sBuffer), "%s%T", g_sPrefixConsole, "Command_Issue_Silence_Permission_Perm", client);
				else
					Format(_sBuffer, sizeof(_sBuffer), "%s%T", g_sPrefixConsole, "Command_Issue_Silence_Permission_Time", client, g_iTimeSeconds[_iLast]);

				ReplyToCommand(client, _sBuffer);
				return Plugin_Stop;
			}
		}

		if(args >= 3)
			GetCmdArg(3, _sReason, sizeof(_sReason));
		else
			_sReason[0] = '\0';
	}
	else
		_sReason[0] = '\0';
	
	decl String:_sName[MAX_TARGET_LENGTH], _iTargets[MAXPLAYERS], _iCount, bool:_bTemp;
	if((_iCount = ProcessTargetString(_sTemp, client, _iTargets, sizeof(_iTargets), COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED, _sName, sizeof(_sName), _bTemp)) <= COMMAND_TARGET_NONE)
		return Plugin_Continue;

	GetIssuerName(client, _sTemp, sizeof(_sTemp));
	for (new i = 0; i < _iCount; i++)
		if(IsClientInGame(_iTargets[i]) && CanUserTarget(client, _iTargets[i]))
			PerformSilenceCommand(client, _iTargets[i], _iLength * 60, _sReason, _sTemp);

	return Plugin_Stop;	
}

public Action:Command_RemoveMute(client, const String:command[], args)
{
	decl String:_sTemp[192], String:_sRemove[64];
	if(args < 1)
	{
		Format(_sTemp, sizeof(_sTemp), "%T", "Command_Remove_Mute_Usage", client);

		ReplyToCommand(client, _sTemp);
		return Plugin_Stop;
	}

	new bool:_bRemove;
	GetCmdArg(1, _sTemp, sizeof(_sTemp));
	if(args >= 2 && g_hDatabase != INVALID_HANDLE)
	{
		GetCmdArg(2, _sRemove, sizeof(_sRemove));
		_bRemove = StringToInt(_sRemove) ? true : false;
	}
	decl String:_sName[MAX_TARGET_LENGTH], _iTargets[MAXPLAYERS], _iCount, bool:_bTemp;
	if((_iCount = ProcessTargetString(_sTemp, client, _iTargets, MAXPLAYERS, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED, _sName, sizeof(_sName), _bTemp)) <= COMMAND_TARGET_NONE)
		return Plugin_Continue;

	for (new i = 0; i < _iCount; i++)
		if(IsClientInGame(_iTargets[i]))
			PerformMutedCommand(client, _iTargets[i], _bRemove);

	return Plugin_Stop;	
}

public Action:Command_RemoveGag(client, const String:command[], args)
{
	decl String:_sTemp[192], String:_sRemove[64];
	if(args < 1)
	{
		Format(_sTemp, sizeof(_sTemp), "%T", "Command_Remove_Gag_Usage", client);

		ReplyToCommand(client, _sTemp);
		return Plugin_Stop;
	}

	new bool:_bRemove;
	GetCmdArg(1, _sTemp, sizeof(_sTemp));
	if(args >= 2 && g_hDatabase != INVALID_HANDLE)
	{
		GetCmdArg(2, _sRemove, sizeof(_sRemove));
		_bRemove = StringToInt(_sRemove) ? true : false;
	}
	decl String:_sName[MAX_TARGET_LENGTH], _iTargets[MAXPLAYERS], _iCount, bool:_bTemp;
	if((_iCount = ProcessTargetString(_sTemp, client, _iTargets, MAXPLAYERS, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED, _sName, sizeof(_sName), _bTemp)) <= COMMAND_TARGET_NONE)
		return Plugin_Continue;

	for (new i = 0; i < _iCount; i++)
		if(IsClientInGame(_iTargets[i]))
			PerformGaggedCommand(client, _iTargets[i], _bRemove);

	return Plugin_Stop;	
}

public Action:Command_RemoveSilence(client, const String:command[], args)
{
	decl String:_sTemp[192], String:_sRemove[64];
	if(args < 1)
	{
		Format(_sTemp, sizeof(_sTemp), "%T", "Command_Remove_Silence_Usage", client);

		ReplyToCommand(client, _sTemp);
		return Plugin_Stop;
	}

	new bool:_bRemove;
	GetCmdArg(1, _sTemp, sizeof(_sTemp));
	if(args >= 2 && g_hDatabase != INVALID_HANDLE)
	{
		GetCmdArg(2, _sRemove, sizeof(_sRemove));
		_bRemove = StringToInt(_sRemove) ? true : false;
	}
	decl String:_sName[MAX_TARGET_LENGTH], _iTargets[MAXPLAYERS], _iCount, bool:_bTemp;
	if((_iCount = ProcessTargetString(_sTemp, client, _iTargets, MAXPLAYERS, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED, _sName, sizeof(_sName), _bTemp)) <= COMMAND_TARGET_NONE)
		return Plugin_Continue;

	for (new i = 0; i < _iCount; i++)
		if(IsClientInGame(_iTargets[i]))
			PerformSilencedCommand(client, _iTargets[i], _bRemove);

	return Plugin_Stop;	
}

public Action:Command_List(client, args) 
{
	if(g_hDatabase == INVALID_HANDLE)
	{
		if(client)
			PrintToChat(client, "%s%t", g_sPrefixConsole, "Command_Database_Invalid");
		else
			ReplyToCommand(client, "%s%t", g_sPrefixConsole, "Command_Database_Invalid");
	}
	else
	{
		if(!client)
			ReplyToCommand(client, "%s%t", g_sPrefixConsole, "Command_List_Game_Only");
		else
		{
			g_iPeskyPanels[client][viewingList] = true;
			AdminMenu_List(client, 0);
		}
	}

	return Plugin_Handled;
}

public Action:Command_Prune(client, args) 
{
	if(g_hDatabase == INVALID_HANDLE)
	{
		if(client)
			PrintToChat(client, "%s%t", g_sPrefixConsole, "Command_Database_Invalid");
		else
			ReplyToCommand(client, "%s%t", g_sPrefixConsole, "Command_Database_Invalid");
	}
	else
	{
		decl String:_sQuery[512];
		Format(_sQuery, sizeof(_sQuery), g_sSQL_PruneSelect, COMM_TABLE);
		SQL_TQuery(g_hDatabase, SQL_AutoPrune, _sQuery, client);
	}

	return Plugin_Handled;
}

public SQL_ConnectCall(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogCommError("Source: SQL_ConnectCall");
		LogCommError("- ExtendedComm was unable to connect to the provided database!");
		if(hndl != INVALID_HANDLE)
		{
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);
			LogCommError("- Error: %s", _sError);
		}
		else if(strlen(error) > 0)
			LogCommError("- Error: %s", error);
	}
	else
	{
		decl String:_sQuery[1024];
		SQL_LockDatabase(hndl);
		Format(_sQuery, sizeof(_sQuery), g_sSQL_VersionCreate, COMM_TABLE_VERSION);
		if(!SQL_FastQuery(hndl, _sQuery))
		{
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);

			LogCommError("Source: SQL_ConnectCall");
			LogCommError("- The query string g_sSQL_VersionCreate could not be executed!");
			LogCommError("- Error: %s", _sError);
			CloseHandle(hndl);
			return;
		}

		Format(_sQuery, sizeof(_sQuery), g_sSQL_CreateTable, COMM_TABLE);
		if(!SQL_FastQuery(hndl, _sQuery))
		{
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);

			LogCommError("Source: SQL_ConnectCall");
			LogCommError("- The query string g_sSQL_CreateTable could not be executed!");
			LogCommError("- Error: %s", _sError);
			CloseHandle(hndl);
			return;
		}
		SQL_UnlockDatabase(hndl);
		g_hDatabase = hndl;	

		Format(_sQuery, sizeof(_sQuery), g_sSQL_VersionSelect, COMM_TABLE_VERSION);
		SQL_TQuery(g_hDatabase, SQL_VersionCheck, _sQuery, _);
	}
}

public SQL_PerformUpdateQuery(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogCommError("Source: SQL_PerformUpdateQuery");
		LogCommError("- A query relating to updating the databases could not be executed!");
		if(hndl != INVALID_HANDLE)
		{
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);
			LogCommError("- Error: %s", _sError);
		}
		else if(strlen(error) > 0)
			LogCommError("- Error: %s", error);
	}
}

public SQL_PerformUpdate_3_0_0(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogCommError("Source: SQL_PerformUpdate_3_0_0");
		LogCommError("- A query relating to updating the database to version 3.0.0 could not be executed!");
		if(hndl != INVALID_HANDLE)
		{
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);
			LogCommError("- Error: %s", _sError);
		}
		else if(strlen(error) > 0)
			LogCommError("- Error: %s", error);
	}
	else if(SQL_GetRowCount(hndl))
	{
		decl String:_sBuffer[32], String:_sQuery[512];
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, _sBuffer, 32);

			new _iMuteType = SQL_FetchInt(hndl, 1);
			new _iMuteLength = SQL_FetchInt(hndl, 2);
			if(_iMuteType > 1)
			{
				if(!_iMuteLength)
					_iMuteType = COMM_MUTE_PERM;
				else
					_iMuteType = COMM_MUTE_TIME;
			}
			else
				_iMuteType = _iMuteLength = 0;

			new _iGagType = SQL_FetchInt(hndl, 3);
			new _iGagLength = SQL_FetchInt(hndl, 4);
			if(_iGagType > 1)
			{
				if(!_iGagLength)
					_iGagType = COMM_GAG_PERM;
				else
					_iGagType = COMM_GAG_TIME;
			}
			else
				_iGagType = _iGagLength = 0;

			if(!_iMuteType && !_iGagType)
			{
				Format(_sQuery, sizeof(_sQuery), g_sSQL_PrunePlayerPre_3_0_0, COMM_TABLE, _sBuffer);
				SQL_TQuery(g_hDatabase, SQL_PerformUpdateQuery, _sQuery, _);
			}
			else
			{
				Format(_sQuery, sizeof(_sQuery), g_sSQL_UpdatePlayerPre_3_0_0, COMM_TABLE, _iMuteType, _iMuteLength, _iGagType, _iGagLength, _sBuffer);
				SQL_TQuery(g_hDatabase, SQL_PerformUpdateQuery, _sQuery, _);			
			}
		}

		g_iUpdateSteps++;
		Format(_sQuery, sizeof(_sQuery), g_sSQL_VersionSelect, COMM_TABLE_VERSION);
		SQL_TQuery(g_hDatabase, SQL_VersionCheck, _sQuery, _);
	}
}

public SQL_VersionUpdate(Handle:owner, Handle:hndl, const String:error[], any:manual)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogCommError("Source SQL_VersionUpdate");
		LogCommError("- The query string g_sSQL_VersionUpdate could not be executed!");
		if(hndl != INVALID_HANDLE)
		{
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);
			LogCommError("- Error: %s", _sError);
		}
		else if(strlen(error) > 0)
			LogCommError("- Error: %s", error);
	}
	else
	{
		decl String:_sQuery[512];
		Format(_sQuery, sizeof(_sQuery), g_sSQL_VersionSelect, COMM_TABLE_VERSION);
		SQL_TQuery(g_hDatabase, SQL_VersionCheck, _sQuery, _);
	}
}

public SQL_VersionCheck(Handle:owner, Handle:hndl, const String:error[], any:manual)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogCommError("Source: SQL_VersionCheck");
		LogCommError("- The query string g_sSQL_VersionSelect could not be executed!");
		if(hndl != INVALID_HANDLE)
		{
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);
			LogCommError("- Error: %s", _sError);
		}
		else if(strlen(error) > 0)
			LogCommError("- Error: %s", error);
	}
	else
	{
		decl String:_sQuery[512];
		if(!SQL_GetRowCount(hndl))
		{
			Format(_sQuery, sizeof(_sQuery), g_sSQL_VersionExisting, COMM_TABLE);
			SQL_TQuery(g_hDatabase, SQL_VersionExisting, _sQuery, _);
		}
		else
		{
			if(SQL_FetchRow(hndl))
			{
				new _iCurrent = SQL_FetchInt(hndl, 0);
				if(_iCurrent < VERSION_CURRENT_UPDATE)
				{
					switch(_iCurrent)
					{
						case 0:
						{
							//Version 2.2.4 to 3.0.0
							if(g_iUpdateSteps > VERSION_3_0_0_STEPS)
							{
								Format(_sQuery, sizeof(_sQuery), g_sSQL_VersionUpdate, COMM_TABLE_VERSION, "3.0.1", VERSION_CURRENT_UPDATE, g_sConnection);
								SQL_TQuery(g_hDatabase, SQL_VersionUpdate, _sQuery, _);
							}
							else
							{
								switch(g_iUpdateSteps)
								{
									case 0:
									{
										for(new i = 0; i <= 3; i++)
										{
											Format(_sQuery, sizeof(_sQuery), g_sSQL_UpdateTables_3_0_0[i], COMM_TABLE);
											SQL_TQuery(g_hDatabase, SQL_PerformUpdateQuery, _sQuery, _);
										}
										
										g_iUpdateSteps++;
										Format(_sQuery, sizeof(_sQuery), g_sSQL_VersionSelect, COMM_TABLE_VERSION);
										SQL_TQuery(g_hDatabase, SQL_VersionCheck, _sQuery, _);
									}
									case 1:
									{
										Format(_sQuery, sizeof(_sQuery), g_sSQL_SelectPlayerPre_3_0_0, COMM_TABLE_PREVIOUS);
										SQL_TQuery(g_hDatabase, SQL_PerformUpdate_3_0_0, _sQuery, _);
									}
								}
							}
						}
					}
				}
				else
				{
					decl String:_sBuffer[32];
					SQL_FetchString(hndl, 1, _sBuffer, 32);
					if(!StrEqual(_sBuffer, g_sConnection, false))
					{
						g_iUpdateSteps = 0;
						Format(_sQuery, sizeof(_sQuery), g_sSQL_VersionUpdate, COMM_TABLE_VERSION, "0.0.0", 0, g_sConnection);
						SQL_TQuery(g_hDatabase, SQL_VersionUpdate, _sQuery, _);
					}
					else
					{
						if(g_bLateQuery)
						{
							for(new i = 1; i <= MaxClients; i++)
							{
								if(IsClientInGame(i))
								{
									Format(_sQuery, sizeof(_sQuery), g_sSQL_LoadClient, COMM_TABLE, g_sSteam[i]);
									SQL_TQuery(g_hDatabase, SQL_LoadPlayerCall, _sQuery, i);
								}
							}

							g_bLateQuery = false;
						}
					}
				}
			}
		}
	}

	return;
}

public SQL_VersionExisting(Handle:owner, Handle:hndl, const String:error[], any:manual)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogCommError("Source: SQL_VersionExisting");
		LogCommError("- The query string g_sSQL_VersionExisting could not be executed!");
		if(hndl != INVALID_HANDLE)
		{
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);
			LogCommError("- Error: %s", _sError);
		}
		else if(strlen(error) > 0)
			LogCommError("- Error: %s", error);
	}
	else
	{
		if(!SQL_GetRowCount(hndl))
		{
			decl String:_sQuery[512];
			Format(_sQuery, sizeof(_sQuery), g_sSQL_VersionUpdate, COMM_TABLE_VERSION, PLUGIN_VERSION, VERSION_CURRENT_UPDATE, g_sConnection);
			SQL_TQuery(g_hDatabase, SQL_VersionUpdate, _sQuery, _);
		}
		else
		{
			decl String:_sQuery[512];
			Format(_sQuery, sizeof(_sQuery), g_sSQL_VersionUpdate, COMM_TABLE_VERSION, "0.0.0", 0, g_sConnection);
			SQL_TQuery(g_hDatabase, SQL_VersionUpdate, _sQuery, _);
		}
	}
}

public SQL_LoadPlayerCall(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogCommError("Source: SQL_LoadPlayerCall");
		LogCommError("- The query string g_sSQL_LoadClient could not be executed!");
		if(hndl != INVALID_HANDLE)
		{
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);
			LogCommError("- Error: %s", _sError);
		}
		else
			LogCommError("- Error: %s", error);
	}
	else
	{
		new client = GetClientOfUserId(userid);
		if(client > 0 && IsClientInGame(client))
		{
			if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
			{
				new _iRemaining, _iEnding, _iTime = GetTime();
				GetMapTimeLeft(_iRemaining);
				_iEnding = _iRemaining + _iTime;

				g_iMuteState[client] = SQL_FetchInt(hndl, 0);
				g_iMuteLength[client] = SQL_FetchInt(hndl, 1);
				g_iMuteTime[client] = SQL_FetchInt(hndl, 2);
				SQL_FetchString(hndl, 3, g_sMuteAdmin[client], 32);
				SQL_FetchString(hndl, 4, g_sMuteReason[client], 64);
				if(g_iMuteState[client] & COMM_MUTE_TIME)
				{
					if((g_iMuteLength[client] + g_iMuteTime[client]) <= _iTime)
					{
						g_bCommSave[client] = true;
						g_iMuteState[client] &= ~COMM_MUTE_TIME;
						g_iMuteLength[client] = g_iMuteTime[client] = 0;
					}
					else
					{
						BaseComm_SetClientMute(client, true);
						if(_iEnding > (g_iMuteLength[client] + g_iMuteTime[client]))
							g_hTimer_MuteExpire[client] = CreateTimer(float(_iRemaining), Timer_MuteExpire, client, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				else if(g_iMuteState[client] & COMM_MUTE_PERM)
					BaseComm_SetClientMute(client, true);

				g_iGagState[client] = SQL_FetchInt(hndl, 5);
				g_iGagLength[client] = SQL_FetchInt(hndl, 6);
				g_iGagTime[client] = SQL_FetchInt(hndl, 7);
				SQL_FetchString(hndl, 8, g_sGagAdmin[client], 32);
				SQL_FetchString(hndl, 9, g_sGagReason[client], 64);
				if(g_iGagState[client] & COMM_GAG_TIME)
				{
					if((g_iGagLength[client] + g_iGagTime[client]) <= _iTime)
					{
						g_bCommSave[client] = true;
						g_iGagState[client] &= ~COMM_GAG_TIME;
						g_iGagLength[client] = g_iGagTime[client] = 0;
					}
					else
					{
						BaseComm_SetClientGag(client, true);
						if(_iEnding > (g_iGagLength[client] + g_iGagTime[client]))
							g_hTimer_GagExpire[client] = CreateTimer(float(_iRemaining), Timer_GagExpire, client, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				else if(g_iGagState[client] & COMM_GAG_PERM)
					BaseComm_SetClientGag(client, true);
			}
		}
	}
}

public SQL_DeletePlayerCall(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogCommError("Source: SQL_DeletePlayerCall");
		LogCommError("- The query string g_sSQL_DeleteClient could not be executed!");
		if(hndl != INVALID_HANDLE)
		{
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);
			LogCommError("- Error: %s", _sError);
		}
		else
			LogCommError("- Error: %s", error);
	}
}

public SQL_SavePlayerCall(Handle:owner, Handle:hndl, const String:error[], any:userid)
{	
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogCommError("Source: SQL_SavePlayerCall");
		LogCommError("- The query string g_sSQL_SaveClient could not be executed!");
		if(hndl != INVALID_HANDLE)
		{
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);
			LogCommError("- Error: %s", _sError);
		}
		else
			LogCommError("- Error: %s", error);
	}
}

public SQL_PruneUpdate(Handle:owner, Handle:hndl, const String:error[], any:var)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogCommError("Source: SQL_PruneUpdate");
		LogCommError("- The query string g_sSQL_PruneUpdate could not be executed!");
		if(hndl != INVALID_HANDLE)
		{
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);
			LogCommError("- Error: %s", _sError);
		}
		else if(strlen(error) > 0)
			LogCommError("- Error: %s", error);
	}
}

public SQL_PruneDelete(Handle:owner, Handle:hndl, const String:error[], any:var)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogCommError("Source: SQL_PruneDelete");
		LogCommError("- The query string g_sSQL_PruneDelete could not be executed!");
		if(hndl != INVALID_HANDLE)
		{
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);
			LogCommError("- Error: %s", _sError);
		}
		else if(strlen(error) > 0)
			LogCommError("- Error: %s", error);
	}
}

public SQL_AutoPrune(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogCommError("Source: SQL_AutoPrune");
		LogCommError("- The automatic pruning query could not be executed!");
		if(hndl != INVALID_HANDLE)
		{
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);
			LogCommError("- Error: %s", _sError);
		}
		else if(strlen(error) > 0)
			LogCommError("- Error: %s", error);
	}
	else
	{
		new _iCurrent = GetTime(), _iRemove, _iUpdate; 
		decl String:_sBuffer[32], String:_sQuery[512];
		decl _iMuteState, _iMuteTime, _iMuteLength, _iGagState, _iGagTime, _iGagLength;
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, _sBuffer, 32);

			_iMuteState = SQL_FetchInt(hndl, 1);
			if(_iMuteState & COMM_MUTE_TIME)
			{
				_iMuteLength = SQL_FetchInt(hndl, 2);
				_iMuteTime = SQL_FetchInt(hndl, 3);
				if((_iMuteLength + _iMuteTime) > _iCurrent)
				{
					_iMuteState &= ~COMM_MUTE_TIME;
					_iMuteLength = _iMuteTime = 0;
				}
			}

			_iGagLength = SQL_FetchInt(hndl, 4);
			if(_iGagState & COMM_GAG_TIME)
			{
				_iGagLength = SQL_FetchInt(hndl, 5);
				_iGagTime = SQL_FetchInt(hndl, 6);
				if((_iGagLength + _iGagTime) >_iCurrent)
				{
					_iGagState &= ~COMM_GAG_TIME;
					_iGagLength = _iGagTime = 0;
				}
			}
			
			if(!_iMuteState && !_iGagState)
			{
				_iRemove++;
				Format(_sQuery, 256, g_sSQL_PruneDelete, COMM_TABLE, _sBuffer);
				SQL_TQuery(g_hDatabase, SQL_PruneDelete, _sQuery, _);
			}
			else
			{
				_iUpdate++;
				Format(_sQuery, 256, g_sSQL_PruneUpdate, COMM_TABLE, _iMuteState, _iMuteLength, _iMuteTime, _iGagState, _iGagLength, _iGagTime, _sBuffer);
				SQL_TQuery(g_hDatabase, SQL_PruneUpdate, _sQuery, _);
			}
		}
		
		if(client >= 0)
		{
			if(client)
				PrintToChat(client, "%s%t", g_sPrefixConsole, "Commande_Prune_Complete", _iRemove, _iUpdate);
			else
				ReplyToCommand(client, "%s%t", g_sPrefixConsole, "Commande_Prune_Complete", _iRemove, _iUpdate);
		}
	}
}

public Action:Timer_MuteExpire(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		g_iMuteState[client] &= ~COMM_MUTE_TIME;
		if(!(g_iMuteState[client] & COMM_MUTE_PERM))
		{
			g_iMuteLength[client] = g_iMuteTime[client] = 0;
			if(!g_bTempMuted[client])
				BaseComm_SetClientMute(client, false);
		}
		
		if(g_bDelayQueries)
			g_bCommSave[client] = true;
		else
			Void_SaveClient(client);
	}

	g_hTimer_MuteExpire[client] = INVALID_HANDLE;
}

public Action:Timer_GagExpire(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		g_bCommSave[client] = true;
		g_iGagState[client] &= ~COMM_GAG_TIME;
		if(!(g_iGagState[client] & COMM_GAG_PERM))
		{
			g_iGagLength[client] = g_iGagTime[client] = 0;
			if(!g_bTempGagged[client])
				BaseComm_SetClientGag(client, false);
		}
		
		if(g_bDelayQueries)
			g_bCommSave[client] = true;
		else
			Void_SaveClient(client);
	}

	g_hTimer_GagExpire[client] = INVALID_HANDLE;
}

Void_LoadTimes()
{
	g_iNumTimes = 0;
	decl String:_sPath[PLATFORM_MAX_PATH], String:_sBuffer[MAX_COMM_TIMES][32];
	new _iBuffer[2][MAX_COMM_TIMES], _iHighest, _iIndex;

	new Handle:_hKV = CreateKeyValues("ExtendedComm_Times");
	BuildPath(Path_SM, _sPath, PLATFORM_MAX_PATH, "configs/extendedcomm/extendedcomm_times.ini");
	if(FileToKeyValues(_hKV, _sPath))
	{
		decl String:_sTemp[32];
		KvGotoFirstSubKey(_hKV);
		do
		{
			KvGetSectionName(_hKV, _sBuffer[g_iNumTimes], 32);
			_iBuffer[0][g_iNumTimes] = KvGetNum(_hKV, "seconds", 0);
			KvGetString(_hKV, "flags", _sTemp, sizeof(_sTemp));
			_iBuffer[1][g_iNumTimes] = StrEqual(_sTemp, "") ? 0 : ReadFlagString(_sTemp);
			
			//Lazy Patch: Permanent should be last!
			if(!_iBuffer[0][g_iNumTimes])
				_iBuffer[0][g_iNumTimes] = 2147483647;
			
			g_iNumTimes++;
		}
		while (KvGotoNextKey(_hKV));
	}
	CloseHandle(_hKV);
	if(g_iNumTimes)
		g_iNumTimes--;
	
	new _iSorted = 0;
	for(new i = 0; i <= g_iNumTimes; i++)
	{
		_iIndex = 0;
		_iHighest = -2147483647;
		for(new j = 0; j <= g_iNumTimes; j++)
		{
			if(_iBuffer[0][j] > _iHighest)
			{
				_iIndex = j;
				_iHighest = _iBuffer[0][j];
			}
		}
		
		strcopy(g_sTimeDisplays[_iSorted], 32, _sBuffer[_iIndex]);
		g_iTimeSeconds[_iSorted] = _iBuffer[0][_iIndex];
		g_iTimeFlags[_iSorted] = _iBuffer[1][_iIndex];
		_iBuffer[0][_iIndex] = 2147483648;
		_iSorted++;
	}
	
	//Lazy Patch: Permanent should be last!
	for(new i = g_iNumTimes; i >= 0; i--)
	{
		if(g_iTimeSeconds[i] == 2147483647)
		{
			g_iTimeSeconds[i] = 0;
			break;
		}
	}
}

Void_LoadReasons()
{
	g_iNumReasons = 0;
	decl String:_sPath[PLATFORM_MAX_PATH];
	new Handle:_hKV = CreateKeyValues("ExtendedComm_Reasons");
	BuildPath(Path_SM, _sPath, PLATFORM_MAX_PATH, "configs/extendedcomm/extendedcomm_reasons.ini");
	if(FileToKeyValues(_hKV, _sPath))
	{
		decl String:_sTemp[32];
		KvGotoFirstSubKey(_hKV);
		do
		{
			KvGetSectionName(_hKV, g_sReasonDisplays[g_iNumReasons], 32);
			KvGetString(_hKV, "flags", _sTemp, sizeof(_sTemp));
			KvGetString(_hKV, "reason", g_sReasonReasons[g_iNumReasons], sizeof(g_sReasonReasons[]));
			g_iReasonFlags[g_iNumReasons] = StrEqual(_sTemp, "") ? 0 : ReadFlagString(_sTemp);
			g_iNumReasons++;
		}
		while (KvGotoNextKey(_hKV));
	}
	CloseHandle(_hKV);
	if(g_iNumReasons)
		g_iNumReasons--;
}

Void_SetDefaults()
{
	g_bTemporary = GetConVarInt(g_hTemporary) ? true : false;
	g_bDelayQueries = GetConVarInt(g_hDelayQueries) ? true : false;
	g_bObeyImmunity = GetConVarInt(g_hObeyImmunity) ? true : false;
	g_iAutoPrune = GetConVarInt(g_hAutoPrune);
	GetConVarString(g_hConnection, g_sConnection, sizeof(g_sConnection));
	GetConVarString(g_hTimeFormat, g_sTimeFormat, sizeof(g_sTimeFormat));
	g_bNullTime = StrEqual(g_sTimeFormat, "", false) ? true : false;

	decl String:_sBuffer[PLATFORM_MAX_PATH];
	GetConVarString(g_hLogActions, _sBuffer, sizeof(_sBuffer));
	g_bLogActions = StrEqual(_sBuffer, "") ? false : true;
	if(g_bLogActions)
		BuildPath(Path_SM, g_sLogActions, sizeof(g_sLogActions), _sBuffer);
	
	GetConVarString(g_hLogNotices, _sBuffer, sizeof(_sBuffer));
	g_bLogNotices = StrEqual(_sBuffer, "") ? false : true;
	if(g_bLogNotices)
		BuildPath(Path_SM, g_sLogNotices, sizeof(g_sLogNotices), _sBuffer);
}

public OnSettingsChange(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	if(convar == g_hConnection)
	{
		Format(g_sConnection, sizeof(g_sConnection), "%s", newvalue);
		if(g_hDatabase != INVALID_HANDLE)
			CloseHandle(g_hDatabase);

		SQL_TConnect(SQL_ConnectCall, StrEqual(newvalue, "") ? "storage-local" : newvalue);
	}
	else if(convar == g_hTemporary)
	{
		g_bTemporary = StringToInt(newvalue) ? true : false;
	}
	else if(convar == g_hDelayQueries)
	{
		g_bDelayQueries = StringToInt(newvalue) ? true : false;
	}
	else if(convar == g_hObeyImmunity)
	{
		g_bObeyImmunity = StringToInt(newvalue) ? true : false;
	}
	else if(convar == g_hLogActions)
	{
		g_bLogActions = StrEqual(newvalue, "") ? false : true;
		if(g_bLogActions)
			BuildPath(Path_SM, g_sLogActions, sizeof(g_sLogActions), newvalue);
	}
	else if(convar == g_hLogNotices)
	{
		g_bLogNotices = StrEqual(newvalue, "") ? false : true;
		if(g_bLogNotices)
			BuildPath(Path_SM, g_sLogNotices, sizeof(g_sLogNotices), newvalue);
	}
	else if(convar == g_hTimeFormat)
	{
		g_bNullTime = StrEqual(newvalue, "", false) ? true : false;
		Format(g_sTimeFormat, sizeof(g_sTimeFormat), "%s", newvalue);
	}
	else if(convar == g_hAutoPrune)
	{
		g_iAutoPrune = StringToInt(newvalue);
	}
}

LogCommAction(client, target, const String:format[], any:...)
{
	decl String:_sBuffer[192];
	VFormat(_sBuffer, sizeof(_sBuffer), format, 4);

	LogAction(client, target, "%s", _sBuffer);
	if(g_bLogActions)
		LogToFileEx(g_sLogActions, "%s", _sBuffer);
}

LogCommError(const String:format[], any:...)
{
	decl String:_sBuffer[192];
	VFormat(_sBuffer, sizeof(_sBuffer), format, 2);

	LogError("%s", _sBuffer);
	if(g_bLogNotices)
		LogToFileEx(g_sLogNotices, "%s", _sBuffer);
}

public Native_GetMuteType(Handle:plugin, numParams)
{
	if(g_hDatabase != INVALID_HANDLE)
	{
		new client = GetNativeCell(1);
		if(client > 0 && IsClientInGame(client))
		{
			if(g_iMuteState[client] & COMM_MUTE_PERM)
				return 3;
			else if(g_iMuteState[client] & COMM_MUTE_TIME)
				return 2;
			else if(g_bTempMuted[client])
				return 1;
		}
	}
	else
		return -2;

	return -1;
}

public Native_GetMuteLength(Handle:plugin, numParams)
{
	if(g_hDatabase != INVALID_HANDLE)
	{
		new client = GetNativeCell(1);
		if(client > 0 && IsClientInGame(client))
			if(g_iMuteState[client] & COMM_MUTE_TIME)
				return g_iMuteLength[client];
	}
	else
		return -2;

	return -1;
}

public Native_GetMuteStart(Handle:plugin, numParams)
{
	if(g_hDatabase != INVALID_HANDLE)
	{
		new client = GetNativeCell(1);
		if(client > 0 && IsClientInGame(client))
			if(g_iMuteState[client])
				return g_iMuteTime[client];
	}
	else
		return -2;

	return -1;
}

public Native_GetMuteExpire(Handle:plugin, numParams)
{
	if(g_hDatabase != INVALID_HANDLE)
	{
		new client = GetNativeCell(1);
		if(client > 0 && IsClientInGame(client))
			if(g_iMuteState[client] & COMM_MUTE_TIME)
				return (g_iMuteTime[client] + g_iMuteLength[client]);
	}
	else
		return -2;

	return -1;
}

public Native_GetGagType(Handle:plugin, numParams)
{
	if(g_hDatabase != INVALID_HANDLE)
	{
		new client = GetNativeCell(1);
		if(client > 0 && IsClientInGame(client))
		{
			if(g_iGagState[client] & COMM_GAG_PERM)
				return 3;
			else if(g_iGagState[client] & COMM_GAG_TIME)
				return 2;
			else if(g_bTempGagged[client])
				return 1;
		}
	}
	else
		return -2;

	return -1;
}

public Native_GetGagLength(Handle:plugin, numParams)
{
	if(g_hDatabase != INVALID_HANDLE)
	{
		new client = GetNativeCell(1);
		if(client > 0 && IsClientInGame(client))
			if(g_iGagState[client] & COMM_GAG_TIME)
				return g_iGagLength[client];
	}
	else
		return -2;

	return -1;
}

public Native_GetGagStart(Handle:plugin, numParams)
{
	if(g_hDatabase != INVALID_HANDLE)
	{
		new client = GetNativeCell(1);
		if(client > 0 && IsClientInGame(client))
			if(g_iGagState[client])
				return g_iGagTime[client];
	}
	else
		return -2;

	return -1;
}

public Native_GetGagExpire(Handle:plugin, numParams)
{
	if(g_hDatabase != INVALID_HANDLE)
	{
		new client = GetNativeCell(1);
		if(client > 0 && IsClientInGame(client))
			if(g_iGagState[client] & COMM_GAG_TIME)
				return (g_iGagTime[client] + g_iGagLength[client]);
	}
	else
		return -2;

	return -1;
}

Bool_ValidMenuTarget(client, target, bool:checkImmunity = true)
{
	if(target <= 0)
	{
		decl String:_sBuffer[192];
		Format(_sBuffer, sizeof(_sBuffer), "%T", "AdminMenu_Not_Available", client);
		if(client)
			PrintToChat(client, "%s%s", g_sPrefixChat, _sBuffer);
		else
			ReplyToCommand(client, "%s%s", g_sPrefixConsole, _sBuffer);
			
		return false;
	}
	else if(checkImmunity && !CanUserTarget(client, target))
	{
		decl String:_sBuffer[192];
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Command_Target_Not_Targetable", client);
		if(client)
			PrintToChat(client, "%s%s", g_sPrefixChat, _sBuffer);
		else
			ReplyToCommand(client, "%s%s", g_sPrefixConsole, _sBuffer);
			
		return false;
	}
	
	return true;
}

AdminMenu_GetPunishPhrase(client, target, String:name[], length)
{
	decl String:_sBuffer[192];
	if((g_bTempMuted[target] || g_iMuteState[target]) && (g_bTempGagged[target] || g_iGagState[target]))
		Format(_sBuffer, sizeof(_sBuffer), "%T", "AdminMenu_Display_Silenced", client, name);
	else if(g_bTempMuted[target] || g_iMuteState[target])
		Format(_sBuffer, sizeof(_sBuffer), "%T", "AdminMenu_Display_Muted", client, name);
	else if(g_bTempGagged[target] || g_iGagState[target])
		Format(_sBuffer, sizeof(_sBuffer), "%T", "AdminMenu_Display_Gagged", client, name);
	else
		Format(_sBuffer, sizeof(_sBuffer), "%T", "AdminMenu_Display_None", client, name);

	strcopy(name, length, _sBuffer);
}

GetIssuerName(client, String:name[], length)
{
	decl String:_sBuffer[192];
	if(!client)
		Format(_sBuffer, sizeof(_sBuffer), "Console");
	else
	{
		if(g_AdminId[client] == INVALID_ADMIN_ID)
			strcopy(_sBuffer, sizeof(_sBuffer), g_sSteam[client]);
		else
		{
			decl String:_sTemp[32];
			if(GetAdminUsername(g_AdminId[client], _sTemp, sizeof(_sTemp)))
				strcopy(_sBuffer, sizeof(_sBuffer), _sTemp);
			else
				strcopy(_sBuffer, sizeof(_sBuffer), g_sSteam[client]);
		}
	}
	strcopy(name, length, _sBuffer);
}

public Handle_Commands(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, param1, String:buffer[], maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "AdminMenu_Main", param1);
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "%T", "AdminMenu_Select_Main", param1);
	}
}

public Handle_MenuList(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, param1, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "AdminMenu_List", param1);
	else if(action == TopMenuAction_SelectOption)
	{
		g_iPeskyPanels[param1][viewingList] = false;
		AdminMenu_List(param1, 0);
	}
}

public Handle_MenuGag(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, param1, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "AdminMenu_Gag", param1);
	else if(action == TopMenuAction_SelectOption)
		AdminMenu_Target(param1, COMM_GAG);
}

public Handle_MenuMute(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, param1, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "AdminMenu_Mute", param1);
	else if(action == TopMenuAction_SelectOption)
		AdminMenu_Target(param1, COMM_MUTE);
}

public Handle_MenuSilence(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, param1, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "AdminMenu_Silence", param1);
	else if(action == TopMenuAction_SelectOption)
		AdminMenu_Target(param1, COMM_SILENCE);
}

public Handle_MenuGagged(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, param1, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "AdminMenu_Gagged", param1);
	else if(action == TopMenuAction_SelectOption)
		AdminMenu_Target(param1, COMM_GAGGED);
}

public Handle_MenuMuted(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, param1, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "AdminMenu_Muted", param1);
	else if(action == TopMenuAction_SelectOption)
		AdminMenu_Target(param1, COMM_MUTED);
}

public Handle_MenuSilenced(Handle:menu, TopMenuAction:action, TopMenuObject:object_id, param1, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "AdminMenu_Silenced", param1);
	else if(action == TopMenuAction_SelectOption)
		AdminMenu_Target(param1, COMM_SILENCED);
}

AdminMenu_Target(client, type)
{
	decl String:_sTitle[192], String:_sOption[32];
	switch(type)
	{
		case COMM_GAG:
			Format(_sTitle, sizeof(_sTitle), "%T", "AdminMenu_Select_Gag", client);
		case COMM_MUTE:
			Format(_sTitle, sizeof(_sTitle), "%T", "AdminMenu_Select_Mute", client);
		case COMM_SILENCE:
			Format(_sTitle, sizeof(_sTitle), "%T", "AdminMenu_Select_Silence", client);
		case COMM_GAGGED:
			Format(_sTitle, sizeof(_sTitle), "%T", "AdminMenu_Select_Gagged", client);
		case COMM_MUTED:
			Format(_sTitle, sizeof(_sTitle), "%T", "AdminMenu_Select_Muted", client);
		case COMM_SILENCED:
			Format(_sTitle, sizeof(_sTitle), "%T", "AdminMenu_Select_Silenced", client);
	}
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuTarget);
	SetMenuTitle(_hMenu, _sTitle);
	SetMenuExitBackButton(_hMenu, true);

	if(type <= 3)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				strcopy(_sTitle, sizeof(_sTitle), g_sName[i]);
				AdminMenu_GetPunishPhrase(client, i, _sTitle, sizeof(_sTitle));
				Format(_sOption, sizeof(_sOption), "%d %d", GetClientUserId(i), type);
				AddMenuItem(_hMenu, _sOption, _sTitle, (CanUserTarget(client, i) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED));
			}
		}
	}
	else
	{
		new _iClients;
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				switch(type)
				{
					case COMM_MUTED:
					{
						if(g_bTempMuted[i] || g_iMuteState[i])
						{
							_iClients++;
							strcopy(_sTitle, sizeof(_sTitle), g_sName[i]);
							Format(_sOption, sizeof(_sOption), "%d %d", GetClientUserId(i), type);
							AddMenuItem(_hMenu, _sOption, _sTitle, (CanUserTarget(client, i) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED));
						}
					}
					case COMM_GAGGED:
					{
						if(g_bTempGagged[i] || g_iGagState[i])
						{
							_iClients++;
							strcopy(_sTitle, sizeof(_sTitle), g_sName[i]);
							Format(_sOption, sizeof(_sOption), "%d %d", GetClientUserId(i), type);
							AddMenuItem(_hMenu, _sOption, _sTitle, (CanUserTarget(client, i) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED));
						}
					}
					case COMM_SILENCED:
					{
						if((g_bTempMuted[i] || g_iMuteState[i]) && (g_bTempGagged[i] || g_iGagState[i]))
						{
							_iClients++;
							strcopy(_sTitle, sizeof(_sTitle), g_sName[i]);
							Format(_sOption, sizeof(_sOption), "%d %d", GetClientUserId(i), type);
							AddMenuItem(_hMenu, _sOption, _sTitle, (CanUserTarget(client, i) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED));
						}
					}
				}
			}
		}
	
		if(!_iClients)
		{
			switch(type)
			{
				case COMM_MUTED:
					Format(_sTitle, sizeof(_sTitle), "%T", "AdminMenu_Option_Mute_Empty", client);
				case COMM_GAGGED:
					Format(_sTitle, sizeof(_sTitle), "%T", "AdminMenu_Option_Gag_Empty", client);
				case COMM_SILENCED:
					Format(_sTitle, sizeof(_sTitle), "%T", "AdminMenu_Option_Silence_Empty", client);
			}
			AddMenuItem(_hMenu, "0", _sTitle, ITEMDRAW_DISABLED);
		}
	}

	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuTarget(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel: 
		{
			if(param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
				DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
		case MenuAction_Select:
		{
			decl String:_sOption[32], String:_sTemp[2][8];
			GetMenuItem(menu, param2, _sOption, sizeof(_sOption));
			ExplodeString(_sOption, " ", _sTemp, 2, 8);
			new target = GetClientOfUserId(StringToInt(_sTemp[0]));

			if(Bool_ValidMenuTarget(param1, target))
			{
				new type = StringToInt(_sTemp[1]);
				if(type <= 3)
				{
					if(g_iNumTimes && g_hDatabase != INVALID_HANDLE)
						AdminMenu_Duration(param1, target, type);
					else
					{
						GetIssuerName(param1, _sOption, sizeof(_sOption));
						switch(type)
						{
							case COMM_MUTE:
								PerformMuteCommand(param1, target, -1, "", _sOption);
							case COMM_GAG:
								PerformGagCommand(param1, target, -1, "", _sOption);
							case COMM_SILENCE:
								PerformSilenceCommand(param1, target, -1, "", _sOption);
						}
					}
				}
				else
				{
					switch(type)
					{
						case COMM_MUTED:
							PerformMutedCommand(param1, target, true);
						case COMM_GAGGED:
							PerformGaggedCommand(param1, target, true);
						case COMM_SILENCED:
							PerformSilencedCommand(param1, target, true);
					}
				}
			}
		}
	}
}

AdminMenu_Duration(client, target, type)
{
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuDuration);
	decl String:_sBuffer[192], String:_sTemp[64];
	Format(_sBuffer, sizeof(_sBuffer), "%T", "AdminMenu_Title_Durations", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitBackButton(_hMenu, true);

	new _iFlags = GetUserFlagBits(client);
	for(new i = g_iNumTimes; i >= 0; i--)
	{
		if(!g_iTimeFlags[i] || _iFlags & g_iTimeFlags[i])
		{
			Format(_sTemp, sizeof(_sTemp), "%d %d %d", GetClientUserId(target), type, i);
			AddMenuItem(_hMenu, _sTemp, g_sTimeDisplays[i]);
		}
	}

	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuDuration(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel: 
		{
			if(param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
				DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
		case MenuAction_Select:
		{
			decl String:_sOption[32], String:_sTemp[3][8];
			GetMenuItem(menu, param2, _sOption, sizeof(_sOption));
			ExplodeString(_sOption, " ", _sTemp, 3, 8);
			new target = GetClientOfUserId(StringToInt(_sTemp[0]));

			if(Bool_ValidMenuTarget(param1, target))
			{
				new type = StringToInt(_sTemp[1]);
				new length = StringToInt(_sTemp[2]);
				
				if(g_iNumReasons && g_iTimeSeconds[length] >= 0)
					AdminMenu_Reason(param1, target, type, length);
				else
				{
					GetIssuerName(param1, _sOption, sizeof(_sOption));
					switch(type)
					{
						case COMM_MUTE:
							PerformMuteCommand(param1, target, g_iTimeSeconds[length], "", _sOption);
						case COMM_GAG:
							PerformGagCommand(param1, target, g_iTimeSeconds[length], "", _sOption);
						case COMM_SILENCE:
							PerformSilenceCommand(param1, target, g_iTimeSeconds[length], "", _sOption);
					}
				}
			}
		}
	}
}

AdminMenu_Reason(client, target, type, length = -1)
{
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuReason);
	decl String:_sBuffer[192], String:_sTemp[64];
	Format(_sBuffer, sizeof(_sBuffer), "%T", "AdminMenu_Title_Reasons", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitBackButton(_hMenu, true);

	new _iFlags = GetUserFlagBits(client);
	for(new i = g_iNumReasons; i >= 0; i--)
	{
		if(!g_iReasonFlags[i] || _iFlags & g_iReasonFlags[i])
		{
			Format(_sTemp, sizeof(_sTemp), "%d %d %d %d", GetClientUserId(target), type, i, length);
			AddMenuItem(_hMenu, _sTemp, g_sReasonDisplays[i]);
		}
	}

	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuReason(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel: 
		{
			if(param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
				DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
		case MenuAction_Select:
		{
			decl String:_sOption[64], String:_sTemp[4][8];
			GetMenuItem(menu, param2, _sOption, sizeof(_sOption));
			ExplodeString(_sOption, " ", _sTemp, 4, 8);
			new target = GetClientOfUserId(StringToInt(_sTemp[0]));

			if(Bool_ValidMenuTarget(param1, target))
			{
				new type = StringToInt(_sTemp[1]);
				new reason = StringToInt(_sTemp[2]);
				new length = StringToInt(_sTemp[3]) >= 0 ? g_iTimeSeconds[StringToInt(_sTemp[3])] : -1;

				GetIssuerName(param1, _sOption, sizeof(_sOption));
				switch(type)
				{
					case COMM_MUTE:
						PerformMuteCommand(param1, target, length, g_sReasonReasons[reason], _sOption);
					case COMM_GAG:
						PerformGagCommand(param1, target, length, g_sReasonReasons[reason], _sOption);
					case COMM_SILENCE:
						PerformSilenceCommand(param1, target, length, g_sReasonReasons[reason], _sOption);
				}
			}
		}
	}
}

AdminMenu_List(client, index)
{
	decl String:_sTitle[192], String:_sOption[32];
	Format(_sTitle, sizeof(_sTitle), "%T", "AdminMenu_Select_List", client);
	new _iClients, Handle:_hMenu = CreateMenu(MenuHandler_MenuList);
	SetMenuTitle(_hMenu, _sTitle);
	if(!g_iPeskyPanels[client][viewingList])
		SetMenuExitBackButton(_hMenu, true);

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && (g_bTempMuted[i] || g_bTempGagged[i] || g_iMuteState[i] || g_iGagState[i]))
		{
			_iClients++;
			strcopy(_sTitle, sizeof(_sTitle), g_sName[i]);
			AdminMenu_GetPunishPhrase(client, i, _sTitle, sizeof(_sTitle));
			Format(_sOption, sizeof(_sOption), "%d", GetClientUserId(i));
			AddMenuItem(_hMenu, _sOption, _sTitle);
		}
	}
	
	if(!_iClients)
	{
		Format(_sTitle, sizeof(_sTitle), "%T", "ListMenu_Option_Empty", client);
		AddMenuItem(_hMenu, "0", _sTitle, ITEMDRAW_DISABLED);
	}
	
	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuList(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel: 
		{
			if(!g_iPeskyPanels[param1][viewingList])
				if(param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
					DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
		case MenuAction_Select:
		{
			decl String:_sOption[32];
			GetMenuItem(menu, param2, _sOption, sizeof(_sOption));
			new target = GetClientOfUserId(StringToInt(_sOption));

			if(Bool_ValidMenuTarget(param1, target, false))
				AdminMenu_ListTarget(param1, target, GetMenuSelectionPosition());
			else
				AdminMenu_List(param1, GetMenuSelectionPosition());
		}
	}
}

AdminMenu_ListTarget(client, target, index, viewMute = 0, viewGag = 0)
{
	new userid = GetClientUserId(target), Handle:_hMenu = CreateMenu(MenuHandler_MenuListTarget);
	decl String:_sBuffer[192], String:_sOption[32];
	SetMenuTitle(_hMenu, g_sName[target]);
	SetMenuPagination(_hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, false);
	
	if(g_bTempMuted[target] || g_iMuteState[target])
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "ListMenu_Option_Mute", client);
		Format(_sOption, sizeof(_sOption), "0 %d %d %b %b", userid, index, viewMute, viewGag); 
		AddMenuItem(_hMenu, _sOption, _sBuffer);

		if(viewMute)
		{
			if(g_iMuteState[target])
			{
				Format(_sBuffer, sizeof(_sBuffer), "%T", "ListMenu_Option_Admin", client, g_sMuteAdmin[target]);
				AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);
			}
			else
			{
				Format(_sBuffer, sizeof(_sBuffer), "%T", "ListMenu_Option_Admin", client, g_sTempMuted[target]);
				AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);
			}

			decl String:_sMuteTemp[192], String:_sMuteTime[192];
			Format(_sMuteTemp, sizeof(_sMuteTemp), "%T", "ListMenu_Option_Duration", client);
			if(g_iMuteState[target] & COMM_MUTE_PERM)
				Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sMuteTemp, "ListMenu_Option_Duration_Perm", client);
			else if(g_iMuteState[target] & COMM_MUTE_TIME)
				Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sMuteTemp, "ListMenu_Option_Duration_Time", client, g_iMuteLength[target]);
			else
				Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sMuteTemp, "ListMenu_Option_Duration_Temp", client);
			AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);

			if(g_iMuteState[target])
			{
				FormatTime(_sMuteTime, sizeof(_sMuteTime), g_bNullTime ? NULL_STRING : g_sTimeFormat, g_iMuteTime[target]);
				Format(_sBuffer, sizeof(_sBuffer), "%T", "ListMenu_Option_Issue", client, _sMuteTime);
				AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);
			}

			Format(_sMuteTemp, sizeof(_sMuteTemp), "%T", "ListMenu_Option_Expire", client);
			if(g_iMuteState[target] & COMM_MUTE_PERM)
				Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sMuteTemp, "ListMenu_Option_Expire_Perm", client);
			else if(g_iMuteState[target] & COMM_MUTE_TIME)
			{
				FormatTime(_sMuteTime, sizeof(_sMuteTime), g_bNullTime ? NULL_STRING : g_sTimeFormat, (g_iMuteTime[target] + g_iMuteLength[target]));
				Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sMuteTemp, "ListMenu_Option_Expire_Time", client, _sMuteTime);
			}
			else
				Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sMuteTemp, g_bTemporary ? "ListMenu_Option_Expire_Temp" : "ListMenu_Option_Expire_Temp_Reconnect", client);
			AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);
			
			if(g_iMuteState[target])
			{
				if(strlen(g_sMuteReason[target]) > 0)
				{
					Format(_sBuffer, sizeof(_sBuffer), "%T", "ListMenu_Option_Reason", client);
					Format(_sOption, sizeof(_sOption), "1 %d %d %b %b", userid, index, viewMute, viewGag); 
					AddMenuItem(_hMenu, _sOption, _sBuffer);
				}
				else
				{
					Format(_sBuffer, sizeof(_sBuffer), "%T", "ListMenu_Option_Reason_None", client);
					AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);
				}
			}
		}
	}

	if(g_bTempGagged[target] || g_iGagState[target])
	{
		Format(_sBuffer, sizeof(_sBuffer), "%T", "ListMenu_Option_Gag", client);
		Format(_sOption, sizeof(_sOption), "2 %d %d %b %b", userid, index, viewMute, viewGag); 
		AddMenuItem(_hMenu, _sOption, _sBuffer);

		if(viewGag)
		{
			if(g_iGagState[target])
			{
				Format(_sBuffer, sizeof(_sBuffer), "%T", "ListMenu_Option_Admin", client, g_sGagAdmin[target]);
				AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);
			}
			else
			{
				Format(_sBuffer, sizeof(_sBuffer), "%T", "ListMenu_Option_Admin", client, g_sTempGagged[target]);
				AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);
			}

			decl String:_sGagTemp[192], String:_sGagTime[192];
			Format(_sGagTemp, sizeof(_sGagTemp), "%T", "ListMenu_Option_Duration", client);
			if(g_iGagState[target] & COMM_GAG_PERM)
				Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sGagTemp, "ListMenu_Option_Duration_Perm", client);
			else if(g_iGagState[target] & COMM_GAG_TIME)
				Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sGagTemp, "ListMenu_Option_Duration_Time", client, g_iGagLength[target]);
			else
				Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sGagTemp, "ListMenu_Option_Duration_Temp", client);
			AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);

			if(g_iGagState[target])
			{
				FormatTime(_sGagTime, sizeof(_sGagTime), g_bNullTime ? NULL_STRING : g_sTimeFormat, g_iGagTime[target]);
				Format(_sBuffer, sizeof(_sBuffer), "%T", "ListMenu_Option_Issue", client, _sGagTime);
				AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);
			}

			Format(_sGagTemp, sizeof(_sGagTemp), "%T", "ListMenu_Option_Expire", client);
			if(g_iGagState[target] & COMM_GAG_PERM)
				Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sGagTemp, "ListMenu_Option_Expire_Perm", client);
			else if(g_iGagState[target] & COMM_GAG_TIME)
			{
				FormatTime(_sGagTime, sizeof(_sGagTime), g_bNullTime ? NULL_STRING : g_sTimeFormat, (g_iGagTime[target] + g_iGagLength[target]));
				Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sGagTemp, "ListMenu_Option_Expire_Time", client, _sGagTime);
			}
			else
				Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sGagTemp, g_bTemporary ? "ListMenu_Option_Expire_Temp" : "ListMenu_Option_Expire_Temp_Reconnect", client);
			AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);
			
			if(g_iGagState[target])
			{
				if(strlen(g_sGagReason[target]) > 0)
				{
					Format(_sBuffer, sizeof(_sBuffer), "%T", "ListMenu_Option_Reason", client);
					Format(_sOption, sizeof(_sOption), "3 %d %d %b %b", userid, index, viewMute, viewGag); 
					AddMenuItem(_hMenu, _sOption, _sBuffer);
				}
				else
				{
					Format(_sBuffer, sizeof(_sBuffer), "%T", "ListMenu_Option_Reason_None", client);
					AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);
				}
			}
		}
	}

	g_iPeskyPanels[client][curIndex] = index;
	g_iPeskyPanels[client][curTarget] = target;
	g_iPeskyPanels[client][viewingGag] = viewGag;
	g_iPeskyPanels[client][viewingMute] = viewMute;
	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuListTarget(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel: 
		{
			if(param2 == MenuCancel_ExitBack)
				AdminMenu_List(param1, g_iPeskyPanels[param1][curIndex]);
		}
		case MenuAction_Select:
		{
			decl String:_sOption[64], String:_sTemp[5][8];
			GetMenuItem(menu, param2, _sOption, sizeof(_sOption));
			ExplodeString(_sOption, " ", _sTemp, 5, 8);

			new target = GetClientOfUserId(StringToInt(_sTemp[1]));
			if(Bool_ValidMenuTarget(param1, target, false))
			{
				switch(StringToInt(_sTemp[0]))
				{
					case 0:
						AdminMenu_ListTarget(param1, target, StringToInt(_sTemp[2]), !(StringToInt(_sTemp[3])), 0);
					case 1, 3:
						AdminMenu_ListTargetReason(param1, target, g_iPeskyPanels[param1][viewingMute], g_iPeskyPanels[param1][viewingGag]);
					case 2:
						AdminMenu_ListTarget(param1, target, StringToInt(_sTemp[2]), 0, !(StringToInt(_sTemp[4])));
				}
			}
			else
				AdminMenu_List(param1, StringToInt(_sTemp[2]));
			
		}
	}
}

AdminMenu_ListTargetReason(client, target, showMute, showGag)
{
	decl String:_sTemp[192], String:_sBuffer[192];
	new Handle:_hPanel = CreatePanel();
	SetPanelTitle(_hPanel, g_sName[target]);
	DrawPanelItem(_hPanel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);

	if(showMute)
	{
		Format(_sTemp, sizeof(_sTemp), "%T", "ReasonPanel_Punishment_Mute", client);
		if(g_iMuteState[target] & COMM_MUTE_PERM)
			Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sTemp, "ReasonPanel_Perm", client);
		else if(g_iMuteState[target] & COMM_MUTE_TIME)
			Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sTemp, "ReasonPanel_Time", client, g_iMuteLength[target]);
		else
			Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sTemp, "ReasonPanel_Temp", client);
		DrawPanelText(_hPanel, _sBuffer);

		Format(_sBuffer, sizeof(_sBuffer), "%T", "ReasonPanel_Reason", client, g_sMuteReason[target]);
		DrawPanelText(_hPanel, _sBuffer);
	}
	else if(showGag)
	{
		Format(_sTemp, sizeof(_sTemp), "%T", "ReasonPanel_Punishment_Gag", client);
		if(g_iGagState[target] & COMM_GAG_PERM)
			Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sTemp, "ReasonPanel_Perm", client);
		else if(g_iGagState[target] & COMM_GAG_TIME)
			Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sTemp, "ReasonPanel_Time", client, g_iGagLength[target]);
		else
			Format(_sBuffer, sizeof(_sBuffer), "%s%T", _sTemp, "ReasonPanel_Temp", client);
		DrawPanelText(_hPanel, _sBuffer);

		Format(_sBuffer, sizeof(_sBuffer), "%T", "ReasonPanel_Reason", client, g_sGagReason[target]);
		DrawPanelText(_hPanel, _sBuffer);
	}

	DrawPanelItem(_hPanel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	SetPanelCurrentKey(_hPanel, 10);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "ReasonPanel_Back", client);
	DrawPanelItem(_hPanel, _sBuffer);
	SendPanelToClient(_hPanel, client, PanelHandler_ListTargetReason, MENU_TIME_FOREVER);
	CloseHandle(_hPanel);
}

public PanelHandler_ListTargetReason(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			AdminMenu_ListTarget(param1, g_iPeskyPanels[param1][curTarget], g_iPeskyPanels[param1][curIndex], g_iPeskyPanels[param1][viewingMute], g_iPeskyPanels[param1][viewingGag]);
		}
	}
}