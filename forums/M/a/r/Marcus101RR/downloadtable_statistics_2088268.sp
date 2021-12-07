#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "1.1"


/*****************************************************************


			P L U G I N   I N F O


*****************************************************************/

public Plugin:myinfo = {
	name = "Download Table Statistics /w Progress",
	author = "Berni, Marcus101RR",
	description = "Shows statistics and missing files of the hl2 download table when joining.",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=75555"
}

/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/

new Handle:dts_version;
new Handle:iDownloadTimer[MAXPLAYERS + 1] = INVALID_HANDLE;

new bool:iForceReconnect[MAXPLAYERS + 1] = true;
new bool:iDownloadFinish[MAXPLAYERS + 1] = false;

/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/

public OnPluginStart() {
	// ConVars
	dts_version = CreateConVar("dts_version", VERSION, "Download Table Statistics plugin version", FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	// Set it to the correct version, in case the plugin gets updated...
	SetConVarString(dts_version, VERSION);


	RegConsoleCmd("disconnect", DisableDisconnect, "List Upgrades.");
	RegConsoleCmd("sm_printconsole", PrintConsole, "List Upgrades.");
	RegAdminCmd("sm_downloadtablestatistics", DownloadTableStatistics, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_dts", DownloadTableStatistics, ADMFLAG_CUSTOM4);

	HookEvent("player_connect_full", event_PlayerConnectFull);
}



/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/

public OnClientConnected(client)
{
	if(client > 0 && IsClientConnected(client) && !IsFakeClient(client) && iDownloadTimer[client] == INVALID_HANDLE)
	{
		CreateTimer(0.25, timer_ShowDownloadStatus, client);
		//CreateTimer(0.1, timer_ToggleConsole, client);
		CreateTimer(2.0, timer_StartConsole, client);
		iForceReconnect[client] = true;
		iDownloadFinish[client] = false;
	}
}

public event_PlayerConnectFull(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if(client > 0)
	{
		iForceReconnect[client] = false;
		iDownloadFinish[client] = true;
		ClientCommand(client, "toggleconsole");
		if(iDownloadTimer[client] != INVALID_HANDLE)
		{
			CloseHandle(iDownloadTimer[client]);
			iDownloadTimer[client] = INVALID_HANDLE;
		}
	}
}

public Action:timer_ShowDownloadStatus(Handle:hTimer, any:client)
{
	ClientCommand(client, "clear;wait;");
	PrepareConsole(client);
}

public Action:timer_ToggleConsole(Handle:hTimer, any:client)
{
	if(iDownloadFinish[client] == true)
		return;

	ClientCommand(client, "toggleconsole;toggleconsole;");
	CreateTimer(0.1, timer_ToggleConsole, client);
}

public Action:DisableDisconnect(client, args)
{
	if(iForceReconnect[client] == true)
		ClientCommand(client, "wait 200;connect 70.125.52.200:27015");
}

public PrepareConsole(client)
{
	if(iDownloadFinish[client] == true)
		return;

	decl String:path[PLATFORM_MAX_PATH];
	decl String:path_bz2[PLATFORM_MAX_PATH];
	decl String:part[32];
	new Float:filesize;

	new Float:size_sounds;
	new Float:size_maps;
	new Float:size_models;
	new Float:size_materials;
	new Float:size_others;
	
	new count_notfound;
	new count_sounds;
	new count_maps;
	new count_models;
	new count_materials;
	new count_others;
	new count_bzip2;

	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE) {
		table = FindStringTable("downloadables");
	}
	
	//ReplyToCommand(client, "[SM] Displaying statistics for the download table:");
	
	new size = GetStringTableNumStrings(table);
	for (new i=0; i<size; ++i) {
		new bool:isBzip2File = true;

		ReadStringTable(table, i, path, sizeof(path));
		
		Format(path_bz2, sizeof(path_bz2), "%s.bz2", path);
		
		filesize = float(FileSize(path_bz2));
		
		if (filesize == -1) {
			filesize = float(FileSize(path));
			isBzip2File = false;
		}
		
		if (filesize == -1) {
			//ClientCommand(client, "Echo [SM] Warning: File %s not found !", path);
			count_notfound++;
		}
		else {
			
			if (isBzip2File) {
				count_bzip2++;
			}

			filesize = filesize/1024/1024;
			
			new n = 0;
			while (path[n] != '/' && path[n] != '\\' && path[n] != '\0') {
				part[n] = path[n];
				n++;
			}
			part[n] = '\0';
			
			new bool:other = true;
			
			if (path[0] != '\0') {
				if (StrEqual(part, "sound", true)) {
					size_sounds += filesize;
					count_sounds++;
					other = false;
				}
				else if (StrEqual(part, "maps", true)) {
					size_maps += filesize;
					count_maps++;
					other = false;
				}
				else if (StrEqual(part, "models", true)) {
					size_models += filesize;
					count_models++;
					other = false;
				}
				else if (StrEqual(part, "materials", true)) {
					size_materials += filesize;
					count_materials++;
					other = false;
				}
			}
			
			if (other) {
				size_others = filesize;
				count_others++;
			}
		}
	}
	
	new Float:totalsize = size_sounds+size_maps+size_models+size_materials+size_others;

	ClientCommand(client, "Echo #============================================================#");
	ClientCommand(client, "Echo \"|  DOWNLOADING MISSING FILES                                 |\""); 
	ClientCommand(client, "Echo |============================================================|");
	ClientCommand(client, "Echo |############################################################|");
	ClientCommand(client, "Echo \"| WARNING: DO NOT CLOSE LEFT 4 DEAD OR DISCONNECT FROM SERVER|\"");
	ClientCommand(client, "Echo \"| UPDATE IN PROGRESS                                         |\"");
	ClientCommand(client, "Echo |############################################################|");
	ClientCommand(client, "Echo \"|                                                            |\"");
	ClientCommand(client, "Echo \"|                                                            |\"");
	ClientCommand(client, "Echo \"|                                                            |\"");
	ClientCommand(client, "Echo \"| Sounds (%d):            %.3f mb                            |\"", count_sounds, size_sounds);
	ClientCommand(client, "Echo \"| Maps (%d):              %.3f mb                           |\"", count_maps, size_maps);
	ClientCommand(client, "Echo \"| Models (%d):            %.3f mb                          |\"", count_models, size_models);
	ClientCommand(client, "Echo \"| Materials (%d):         %.3f mb                          |\"", count_models, size_materials);
	ClientCommand(client, "Echo \"| Others (%d):            %.3f mb                           |\"", count_others, size_others);
	ClientCommand(client, "Echo \"| -----------------------------------------------------------|\"");
	ClientCommand(client, "Echo \"| Total files: %d (%d not found): %.3f mb                |\"", size,  count_notfound, totalsize);
	ClientCommand(client, "Echo \"| Compressed Files (bzip2): %d                                |\"\"", count_bzip2);
	ClientCommand(client, "Echo \"| Min. Download Time: 56k: %.2fmin   2mbit: %.2fmin        |", calcDownloadTime(totalsize, 0.0546875), calcDownloadTime(totalsize, 2.0));
	ClientCommand(client, "Echo \"|                     4mbit: %.2fmin 16mbit: %.2fmin         |\"", calcDownloadTime(totalsize, 4.0), calcDownloadTime(totalsize, 16.0));
	ClientCommand(client, "Echo ______________________________________________________________\"");
	
	new bool:save = LockStringTables(false);
	
	LockStringTables(save);
	CreateTimer(1.0, timer_ShowDownloadStatus, client);
}

public Action:PrintConsole(client, args)
{
	decl String:path[PLATFORM_MAX_PATH];
	decl String:path_bz2[PLATFORM_MAX_PATH];
	decl String:part[32];
	new Float:filesize;

	new Float:size_sounds;
	new Float:size_maps;
	new Float:size_models;
	new Float:size_materials;
	new Float:size_others;
	
	new count_notfound;
	new count_sounds;
	new count_maps;
	new count_models;
	new count_materials;
	new count_others;
	new count_bzip2;

	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE) {
		table = FindStringTable("downloadables");
	}
	
	//ReplyToCommand(client, "[SM] Displaying statistics for the download table:");
	
	new size = GetStringTableNumStrings(table);
	for (new i=0; i<size; ++i) {
		new bool:isBzip2File = true;

		ReadStringTable(table, i, path, sizeof(path));
		
		Format(path_bz2, sizeof(path_bz2), "%s.bz2", path);
		
		filesize = float(FileSize(path_bz2));
		
		if (filesize == -1) {
			filesize = float(FileSize(path));
			isBzip2File = false;
		}
		
		if (filesize == -1) {
			//PrintToConsole(client, "[SM] Warning: File %s not found !", path);
			count_notfound++;
		}
		else {
			
			if (isBzip2File) {
				count_bzip2++;
			}

			filesize = filesize/1024/1024;
			
			new n = 0;
			while (path[n] != '/' && path[n] != '\\' && path[n] != '\0') {
				part[n] = path[n];
				n++;
			}
			part[n] = '\0';
			
			new bool:other = true;
			
			if (path[0] != '\0') {
				if (StrEqual(part, "sound", true)) {
					size_sounds += filesize;
					count_sounds++;
					other = false;
				}
				else if (StrEqual(part, "maps", true)) {
					size_maps += filesize;
					count_maps++;
					other = false;
				}
				else if (StrEqual(part, "models", true)) {
					size_models += filesize;
					count_models++;
					other = false;
				}
				else if (StrEqual(part, "materials", true)) {
					size_materials += filesize;
					count_materials++;
					other = false;
				}
			}
			
			if (other) {
				size_others = filesize;
				count_others++;
			}
		}
	}
	
	new Float:totalsize = size_sounds+size_maps+size_models+size_materials+size_others;

	ReplyToCommand(client, "#============================================================#");
	ReplyToCommand(client, "|  DOWNLOADING MISSING FILES                                 |"); 
	ReplyToCommand(client, "|============================================================|");
	ReplyToCommand(client, "|############################################################|");
	ReplyToCommand(client, "| WARNING: DO NOT CLOSE LEFT 4 DEAD OR DISCONNECT FROM SERVER|");
	ReplyToCommand(client, "| UPDATE IN PROGRESS                                         |");
	ReplyToCommand(client, "|############################################################|");
	ReplyToCommand(client, "|                                                            |");
	ReplyToCommand(client, "|                                                            |");
	ReplyToCommand(client, "|                                                            |");
	ReplyToCommand(client, "| Sounds (%d):            %.3f mb                            |", count_sounds, size_sounds);
	ReplyToCommand(client, "| Maps (%d):              %.3f mb                           |", count_maps, size_maps);
	ReplyToCommand(client, "| Models (%d):            %.3f mb                          |", count_models, size_models);
	ReplyToCommand(client, "| Materials (%d):         %.3f mb                          |", count_models, size_materials);
	ReplyToCommand(client, "| Others (%d):            %.3f mb                           |", count_others, size_others);
	ReplyToCommand(client, "| -----------------------------------------------------------|");
	ReplyToCommand(client, "| Total files: %d (%d not found): %.3f mb", size,  count_notfound, totalsize);
	ReplyToCommand(client, "| Compressed Files (bzip2): %d", count_bzip2);
	ReplyToCommand(client, "| Min. Download Time: 56k: %.2fmin   2mbit: %.2fmin", calcDownloadTime(totalsize, 0.0546875), calcDownloadTime(totalsize, 2.0));
	ReplyToCommand(client, "|                     4mbit: %.2fmin 16mbit: %.2fmin", calcDownloadTime(totalsize, 4.0), calcDownloadTime(totalsize, 16.0));
	
	new bool:save = LockStringTables(false);
	
	LockStringTables(save);
	CreateTimer(1.0, timer_ShowDownloadStatus, client);
}

public Action:timer_StartConsole(Handle:hTimer, any:client)
{
	ClientCommand(client, "toggleconsole");
	ClientCommand(client, "toggleconsole");
}

public Action:DownloadTableStatistics(client, args) {
	decl String:path[PLATFORM_MAX_PATH];
	decl String:path_bz2[PLATFORM_MAX_PATH];
	decl String:part[32];
	new Float:filesize;

	new Float:size_sounds;
	new Float:size_maps;
	new Float:size_models;
	new Float:size_materials;
	new Float:size_others;
	
	new count_notfound;
	new count_sounds;
	new count_maps;
	new count_models;
	new count_materials;
	new count_others;
	new count_bzip2;

	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE) {
		table = FindStringTable("downloadables");
	}
	
	PrintToConsole(client, "[SM] Displaying statistics for the download table:");
	
	new size = GetStringTableNumStrings(table);
	for (new i=0; i<size; ++i) {
		new bool:isBzip2File = true;

		ReadStringTable(table, i, path, sizeof(path));
		
		Format(path_bz2, sizeof(path_bz2), "%s.bz2", path);
		
		filesize = float(FileSize(path_bz2));
		
		if (filesize == -1) {
			filesize = float(FileSize(path));
			isBzip2File = false;
		}
		
		if (filesize == -1) {
			ReplyToCommand(client, "[SM] Warning: File %s not found !", path);
			count_notfound++;
		}
		else {
			
			if (isBzip2File) {
				count_bzip2++;
			}

			filesize = filesize/1024/1024;
			
			new n = 0;
			while (path[n] != '/' && path[n] != '\\' && path[n] != '\0') {
				part[n] = path[n];
				n++;
			}
			part[n] = '\0';
			
			new bool:other = true;
			
			if (path[0] != '\0') {
				if (StrEqual(part, "sound", true)) {
					size_sounds += filesize;
					count_sounds++;
					other = false;
				}
				else if (StrEqual(part, "maps", true)) {
					size_maps += filesize;
					count_maps++;
					other = false;
				}
				else if (StrEqual(part, "models", true)) {
					size_models += filesize;
					count_models++;
					other = false;
				}
				else if (StrEqual(part, "materials", true)) {
					size_materials += filesize;
					count_materials++;
					other = false;
				}
			}
			
			if (other) {
				size_others = filesize;
				count_others++;
			}
		}
	}
	
	new Float:totalsize = size_sounds+size_maps+size_models+size_materials+size_others;
	
	PrintToConsole(client, "[SM] Sounds (%d):                    %.3f mb", count_sounds, size_sounds);
	PrintToConsole(client, "[SM] Maps (%d):                      %.3f mb", count_maps, size_maps);
	PrintToConsole(client, "[SM] Models (%d):                    %.3f mb", count_models, size_models);
	PrintToConsole(client, "[SM] Materials (%d):                 %.3f mb", count_models, size_materials);
	PrintToConsole(client, "[SM] Others (%d):                    %.3f mb", count_others, size_others);
	PrintToConsole(client, "[SM] ------");
	PrintToConsole(client, "[SM] Total files: %d (%d not found): %.3f mb", size,  count_notfound, totalsize);
	PrintToConsole(client, "[SM] Compressed Files (bzip2): %d", count_bzip2);
	PrintToConsole(client, "[SM] min. estimated download time: 56k: %.2fmin   2mbit: %.2fmin   4mbit: %.2fmin   16mbit: %.2fmin", calcDownloadTime(totalsize, 0.0546875), calcDownloadTime(totalsize, 2.0), calcDownloadTime(totalsize, 4.0), calcDownloadTime(totalsize, 16.0));
	
	new bool:save = LockStringTables(false);

	
	
	LockStringTables(save);

}



/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/

stock Float:calcDownloadTime(Float:filesize, Float:speed) {
	new Float:filesize_mbits = filesize*8;
	new Float:secs = filesize_mbits/speed;
	new Float:mins = secs/60;
	
	return mins;
}

stock strfind(String:str[], char) {
	new n=0;
	
	while (str[n] != '\0') {
		if (str[n] == char) {
			return n;
		}
	}
	
	return -1;
}
