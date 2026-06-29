#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new Handle:hPrnt 	= INVALID_HANDLE;
new Handle:hLog		= INVALID_HANDLE;

public Plugin:myinfo= {
	name 			= "Network String Table Viewer",
	author 			= "-=( TFN | Nick )=-",
	description 	= "Development tool that allows plugin authors details about the Network String Table (NST)",
	version 		= PLUGIN_VERSION,
	url 			= "http://clantfn.counter-strike.com"
}

public OnPluginStart()
{
		RegAdminCmd("sm_diag_nst",
					String_Test,
					ADMFLAG_CONFIG,
					"View NST's. These are printed out to console. Add in a table name to view specific details on the table.");
		
		hPrnt	= CreateConVar("sm_diag_nst_prt",
								"1",
								"enables or disables printing live table data to the console. Helpful for large tables like 'userinfo'",
								FCVAR_REPLICATED|FCVAR_NOTIFY);
		hLog	= CreateConVar("sm_diag_nst_log", 
								"1", 
								"enables or disables logging of output to logs/nst/", 
								FCVAR_REPLICATED|FCVAR_NOTIFY);
		CreateConVar("sm_diag_nst_version",
						PLUGIN_VERSION,
						"Version of the plugin",
						FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:String_Test(client,args)
{
	new iPrnt	= GetConVarInt(hPrnt);
	new iLog	= GetConVarInt(hLog);
	
	if (args == 0) {
		new iTables = GetNumStringTables();
	
		new String:buffer[255];
	
		new bool:bLock;
		LockStringTables(bLock);
		new String:szbLock[10];
		if (bLock == true) {
			szbLock = "true";
		}
		else {
			szbLock = "false";
		}
	
		new iTotal;
		new iMax;
		
		PrintToConsole(client, "[SM] NSTViewer (ver %s)", PLUGIN_VERSION);
		PrintToConsole(client, "[SM] Showing Network Tables");
		PrintToConsole(client, "	* Total Amount of Tables: %i", iTables);
		PrintToConsole(client, "	* Network String Table Lock Status: %s", szbLock);
		PrintToConsole(client, " ");
		PrintToConsole(client, "Table			|	Total Strings	|	Max Strings");
		PrintToConsole(client, " ");
		
		/*
		* Add in section to get the size of the table
		*/
	
		for (new i = 0; iTables > i; i++) {
			GetStringTableName(i, buffer, sizeof(buffer));
			iTotal = GetStringTableNumStrings(i);
			iMax = GetStringTableMaxStrings(i);
			PrintToConsole(client, "%s			%i		%i", buffer, iTotal, iMax);
		}
		
		return Plugin_Handled;
	}
	else {
		new String:buffer[255];
		GetCmdArgString(buffer, sizeof(buffer));
		
		new iTables = FindStringTable(buffer);
		
		new String:name[MAX_NAME_LENGTH];
		GetStringTableName(iTables, name, sizeof(name));
		new iTotal = GetStringTableNumStrings(iTables);
		
		new String:szPath_SM[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, szPath_SM, sizeof(szPath_SM), "/logs/nst/%s.txt", name);
		
		new String:line[255];
		new String:user[255];
		new iSize;
		
		new Handle:File = OpenFile(szPath_SM, "a");
		
		new iTime = GetTime();
		new String:szTime[196];
		FormatTime(szTime, sizeof(szTime), "\0", iTime);
		
		PrintToConsole(client, "[SM] NSTViewer (ver %s)", PLUGIN_VERSION);
		PrintToConsole(client, "	* Table '%s' contains %i Strings", name, iTotal);
		PrintToConsole(client, " ");
		
		
		//This area needs to be converted to a switch()
		if(iLog == 1 && iPrnt == 1) {
			WriteFileLine(File, "%s - Logging Started for '%s' by %L", szTime, name, client);
			WriteFileLine(File, "	* Log Built On NSTViewer %s", PLUGIN_VERSION);
			WriteFileLine(File, "	* Table '%s' contains %i Strings", name, iTotal);
			WriteFileLine(File, " ");
				
			for(new i = 0; i < iTotal; i++) {
				ReadStringTable(iTables, i, line, sizeof(line));
				GetStringTableData(iTables, i, user, sizeof(user));
				iSize = GetStringTableDataLength(iTables, i);
				
				PrintToConsole(client, "	* String %i : %s - %s (%i)", i, line, user, iSize);
				
				WriteFileLine(File, "- String %i : %s - %s (%i)", i, line, user, iSize);
			}
			
			WriteFileLine(File, "--------------- End of session ---------------");
			
			PrintToConsole(client, "[SM] This data has now been logged");

		}
		else if(iLog == 0 && iPrnt == 1) {
			for(new i = 0; i < iTotal; i++) {
				ReadStringTable(iTables, i, line, sizeof(line));
				GetStringTableData(iTables, i, user, sizeof(user));
				iSize = GetStringTableDataLength(iTables, i);
				
				PrintToConsole(client, "- String %i : \"%s\" [%s] (%i)", i, line, user, iSize);
			}
		}
		else if(iLog == 1 && iPrnt == 0) {
			WriteFileLine(File, "%s - Logging Started for %s by %L", szTime, name, client);
			WriteFileLine(File, "	* Log Built On NSTViewer %s", PLUGIN_VERSION);
			WriteFileLine(File, "	* Table '%s' contains %i Strings", name, iTotal);
			WriteFileLine(File, " ");
				
			for(new i = 0; i < iTotal; i++) {
				ReadStringTable(iTables, i, line, sizeof(line));
				GetStringTableData(iTables, i, user, sizeof(user));
				iSize = GetStringTableDataLength(iTables, i);
				
				WriteFileLine(File, "- String %i : %s - %s (%i)", i, line, user, iSize);
			}
			
			WriteFileLine(File, "--------------- End of session ---------------");
		}
		CloseHandle(File);
		
		return Plugin_Handled;
	}
}