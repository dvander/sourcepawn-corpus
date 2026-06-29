#include <sourcemod>
#include <sdktools>
static String:DownloadPath[64]
public Plugin:myinfo = {
	name = "Auto Table Downloader",
	author = "Master(D)",
	description = "Auto Table Downloader",
	version = "1.1.1",
	url = ""
}
public Action:Command_CheakDownloadTables(Client,Args) {  
	PrintToConsole(Client,"Cheaking Download Table...")
	new Handle:fileh = OpenFile(DownloadPath, "r")
	new String:buffer[256]
	while (ReadFileLine(fileh, buffer, sizeof(buffer))) {
		new len = strlen(buffer)
		if (buffer[len-1] == '\n') {
			buffer[--len] = '\0'
		}
		if (FileExists(buffer)) {
 			PrintToConsole(Client,"Download: %s",buffer)
		} else {
			PrintToConsole(Client,"Ignore: %s",buffer)
		}
		if (IsEndOfFile(fileh)) {
			break
		}
	}
	return Plugin_Handled   
}
public OnMapStart(){
	BuildPath(Path_SM, DownloadPath, 64, "configs/download.txt")
	if(FileExists(DownloadPath) == false) SetFailState("[SM] ERROR: Missing file '%s'", DownloadPath)
	new Handle:fileh = OpenFile(DownloadPath, "r")
	new String:buffer[256]
	while (ReadFileLine(fileh, buffer, sizeof(buffer))) {
		new len = strlen(buffer)
		if (buffer[len-1] == '\n') {
			buffer[--len] = '\0'
		}
		if (FileExists(buffer)){
			AddFileToDownloadsTable(buffer)
		}
		if (IsEndOfFile(fileh)) {
			break;
		}
	}
}
public OnPluginStart() {
    	RegAdminCmd("sm_dlcheck", Command_CheakDownloadTables, ADMFLAG_SLAY, "<Name> <Id> - Checks download.txt")
    	CreateConVar("dlversion", "1.1.1", "auto table downloader version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY)

}