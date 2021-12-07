#pragma semicolon 1

#include <sourcemod>

#define PL_VERSION "1.0"

new Handle:g_hDatabase = INVALID_HANDLE;

new Records = 0;
new Players = 0;
new Double = 0;
new Deleted = 0;
new Msg = 0;

public Plugin:myinfo =
{
    name        = "[Timer] Double Records Delete",
    author      = "Zipcore",
    description = "A simple command to delete double records of your timer 1.x database to make it timer 2.x compatible",
    version     = "1.0",
    url         = "zipcore#googlemail.com"
};

public OnPluginStart()
{
	RegAdminCmd("sm_timer_delete_double", Command_Scan, ADMFLAG_ROOT);
	
	SQL_TConnect(SQL_Connect_Database, "timer");
}

public Action:Command_Scan(client, args)
{
	if(g_hDatabase == INVALID_HANDLE)
	{
		ReplyToCommand(client, "Database error");
		return Plugin_Handled;
	}
	
	PrintToChatAll("[Timer] DRD: Searching double records...");
	LogMessage("[Timer] DRD: Searching double records...");
		
	decl String:query[512];
	Format(query, sizeof(query), "SELECT `id` , LOWER(`map`) , `auth` , `physicsdifficulty` , `bonus` FROM `round` ORDER BY `auth` , `map` , `bonus` , `physicsdifficulty` , `time`");
	SQL_TQuery(g_hDatabase, CallBack_CheckRecords, query, _, DBPrio_Normal);
	
	return Plugin_Handled;
}

public SQL_Connect_Database(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	g_hDatabase = hndl;
}

public CallBack_CheckRecords(Handle:owner, Handle:hndl, const String:error[], any:pack)
{
	if (hndl == INVALID_HANDLE)
	{
		return;
	}
	
	new id;
	new String:sMap[128], String:sAuth[128], style, bonus;
	new String:sMap_last[128], String:sAuth_last[128], style_last, bonus_last;
	
	Double = 0;
	Records = 0;
	Players = 0;
	Deleted = 0;
	Msg = 0;
	
	while (SQL_FetchRow(hndl))
	{
		Records++;
		
		id = SQL_FetchInt(hndl, 0);
		SQL_FetchString(hndl, 1, sMap, sizeof(sMap));
		SQL_FetchString(hndl, 2, sAuth, sizeof(sAuth));
		style = SQL_FetchInt(hndl, 3);
		bonus = SQL_FetchInt(hndl, 4);
		
		if(StrEqual(sAuth, sAuth_last) && StrEqual(sMap, sMap_last) && bonus == bonus_last && style == style_last)
		{
			Double++;
			decl String:query[512];
			Format(query, sizeof(query), "DELETE FROM `round` WHERE `id` = %d", id);
			SQL_TQuery(g_hDatabase, DeleteCallback, query, _, DBPrio_Normal);
		} else Players++;
		
		Format(sAuth_last, sizeof(sAuth_last), sAuth);
		Format(sMap_last, sizeof(sMap_last), sMap);
		bonus_last = bonus;
		style_last = style;
	}
	
	if(Double > 0)
	{
		PrintToChatAll("[Timer] DRD: %d/%d double records detected (%d players)", Double, Records, Players);
		LogMessage("[Timer] DRD: %d/%d double records detected (%d players)", Double, Records, Players);
		
		PrintToChatAll("[Timer] DRD: Please wait! It can take some time to delete all records!");
		LogMessage("[Timer] DRD: Please wait! It can take some time to delete all records!");
	}
	else
	{
		PrintToChatAll("[Timer] DRD: No double records found.");
		LogMessage("[Timer] DRD: No double records found.");
	}
}

public DeleteCallback(Handle:owner, Handle:hndl, const String:error[], any:param1) 
{
	Deleted++;
	Msg++;
	
	if(Deleted >= Double)
	{
		PrintToChatAll("[Timer] DRD: Deleted all %d double records.", Deleted);
		LogMessage("[Timer] DRD: Deleted all %d double records.", Deleted);
		return;
	}
	
	if(Msg >= 1000)
	{
		Msg = 0;
		PrintToChatAll("[Timer] DRD: Deleted %d / %d double records.", Deleted, Double);
		LogMessage("[Timer] DRD: Deleted %d / %d double records.", Deleted, Double);
	}
}