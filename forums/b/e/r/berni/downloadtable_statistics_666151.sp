/*

Description:

This is a plugin for showing statistics and missing files of the servers download table that is sent to the players when they connect.

You can use this to determine, how much data is getting sent to each player, on their first connect. and how long they have to wait until they have all the files.

    * missing files
    * file count in specific directory
    * total file size of a specific directory
    * total files count
    * total bzip2 files count
    * total file size
    * the estimated download time for 56, 2mbit, 4mbit and 8mbit connection speed (in minutes)

Note: This plugin can't open bzip2 files that are on a webserver (using sv_downloadurls). bzip2 compression is not taken into account. But this plugin can still give you a roughly overview on how long it will take to download all the stuff and how many files there are.

Commands:

sm_downloadtablestatistics
sm_dts - Alias of above


Example:

[code]
[SM] Displaying statistics for the download table:
[SM] Warning: File sound/misc/sprayer.wav not found !
[SM] Sounds (118):                    30.854 mb
[SM] Maps (2):                      10.491 mb
[SM] Models (0):                    0.000 mb
[SM] Materials (0):                 0.000 mb
[SM] Others (0):                    0.000 mb
[SM] ------
[SM] Total files: 121 (1 not found): 41.345 mb
[SM] Compressed Files (bzip2): 1
[SM] min. estimated download time: 56k: 100.80min   2mbit: 2.75min   4mbit: 1.37min   16mbit: 0.34min
[/code]

Changelog


Date: 13.08.2008
Version: 1.1

    * Added bzip2 support - bzip2 files are now used for calculation instead of uncomprossed file, if exists
    * Added compressed files count line
    * Added an alias command sm_dts because the other one seems pretty long



Date: 08.08.2008
Version: 1.0

    * Initial release
	
	
*/











// enforce semicolons after each code statement
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "1.1"



/*****************************************************************


			P L U G I N   I N F O


*****************************************************************/

public Plugin:myinfo = {
	name = "Download Table Statistics",
	author = "Berni",
	description = "Shows statistics and missing files of the hl2 download table",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=75555"
}



/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/

new Handle:dts_version;



/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/

public OnPluginStart() {
	// ConVars
	dts_version = CreateConVar("dts_version", VERSION, "Download Table Statistics plugin version", FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	// Set it to the correct version, in case the plugin gets updated...
	SetConVarString(dts_version, VERSION);

	RegAdminCmd("sm_downloadtablestatistics", DownloadTableStatistics, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_dts", DownloadTableStatistics, ADMFLAG_CUSTOM4);
}



/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/

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
	
	ReplyToCommand(client, "[SM] Displaying statistics for the download table:");
	
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
	
	ReplyToCommand(client, "[SM] Sounds (%d):                    %.3f mb", count_sounds, size_sounds);
	ReplyToCommand(client, "[SM] Maps (%d):                      %.3f mb", count_maps, size_maps);
	ReplyToCommand(client, "[SM] Models (%d):                    %.3f mb", count_models, size_models);
	ReplyToCommand(client, "[SM] Materials (%d):                 %.3f mb", count_models, size_materials);
	ReplyToCommand(client, "[SM] Others (%d):                    %.3f mb", count_others, size_others);
	ReplyToCommand(client, "[SM] ------");
	ReplyToCommand(client, "[SM] Total files: %d (%d not found): %.3f mb", size,  count_notfound, totalsize);
	ReplyToCommand(client, "[SM] Compressed Files (bzip2): %d", count_bzip2);
	ReplyToCommand(client, "[SM] min. estimated download time: 56k: %.2fmin   2mbit: %.2fmin   4mbit: %.2fmin   16mbit: %.2fmin", calcDownloadTime(totalsize, 0.0546875), calcDownloadTime(totalsize, 2.0), calcDownloadTime(totalsize, 4.0), calcDownloadTime(totalsize, 16.0));
	
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
