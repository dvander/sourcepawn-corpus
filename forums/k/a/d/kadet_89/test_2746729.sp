#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

Handle g_SQL = null;

public void OnPluginStart() 
{
	SQL_TConnect(GotDatabase, "plugin");
}

public void GotDatabase(Handle owner, Handle hndl, const char[] error, any data)
{
	if(error[0])
	{
		Log("GotDatabase | Query Failed: %s", error);
		return;
	}
	
	if(hndl	== INVALID_HANDLE)
	{
		Log("GotDatabase | Could not connect to database \"plugin\": %s", error);
		g_SQL = null;
		return;
	}

	g_SQL = hndl;
	
	char buff[512];

	Log("SQL_SetCharset(g_SQL, \"utf8mb4\")");
	SQL_SetCharset(g_SQL, "utf8mb4");
	Log("SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;");
	SQL_TQuery(hndl, ErrorCheckCallback, "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;"); 

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table1 (param1 VARCHAR(32), param2 VARCHAR(256), param3 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "ALTER TABLE table1 CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);
	Log(buff);
	
	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table2 (param1 VARCHAR(256), param2 VARCHAR(256), param3 VARCHAR(32))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);
	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table3 (param1 VARCHAR(32), param2 VARCHAR(32))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS `table4` (param1 VARCHAR(64), param2 VARCHAR(64), param3 INT(2), param4 VARCHAR(2048), param4 INT(2), UNIQUE (param1))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	// ////////////////////// VIP OPTIONS ///////////////////////////////////////////////////////////////////////////
	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table5 (param1 VARCHAR(32), param2 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table6 (param1 VARCHAR(32), param2 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table7 (param1 VARCHAR(32), param2 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table8 (param1 VARCHAR(32), param2 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table9 (param1 VARCHAR(32), param2 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table10 (param1 VARCHAR(32), param2 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table11 (param1 VARCHAR(32), param2 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);
	
	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table12 (param1 VARCHAR(32), param2 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table13 (param1 VARCHAR(32), param2 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table14 (param1 VARCHAR(32), param2 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table15 (param1 VARCHAR(32), param2 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table16 (param1 VARCHAR(32), param2 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table17 (param1 VARCHAR(32), param2 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table18 (param1 VARCHAR(32), param2 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table19 (param1 VARCHAR(32), param2 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS table20 (param1 VARCHAR(32), param2 INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	// //////////////////////  ///////////////////////////////////////////////////////////////////////////

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS `table21` (`param1` VARCHAR(32), `param2` VARCHAR(32), `param3` VARCHAR(32), `param4` VARCHAR(32), `param5` VARCHAR(32), `param6` VARCHAR(32), `param7` INT(2), `param8` INT(2))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "ALTER TABLE table21 CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);
	Log(buff);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS `table22` (`param1` VARCHAR(32), `param2` VARCHAR(32), `clientpassword` VARCHAR(64))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);//Exception reported: Script execution timed out
	SQL_TQuery(hndl, ErrorCheckCallback, "ALTER TABLE `table22` ADD PRIMARY KEY (`param2`), ADD UNIQUE KEY `uc` (`param1`)", _);

	FormatEx(buff, sizeof(buff), "ALTER TABLE table22 CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);
	Log(buff);

	FormatEx(buff, sizeof(buff), "CREATE TABLE IF NOT EXISTS `table23` (param0 VARCHAR(32), param1 VARCHAR(32), param2 INT(2), param3 INT(2), UNIQUE (param0))");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);

	FormatEx(buff, sizeof(buff), "ALTER TABLE table23 CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;");
	SQL_TQuery(hndl, ErrorCheckCallback, buff, _);
	Log(buff);
	
	Log("Connected to database: \"plugin\"");
}

void Log (const char[] format, any ...)
{
	char filelog[] = "addons/sourcemod/logs/plugin.log";
	
	new length = strlen(format) + 255;
	new String:formattedString[length];
	VFormat(formattedString, length, format, 2);  	
	
	LogToFile(filelog, formattedString);
}