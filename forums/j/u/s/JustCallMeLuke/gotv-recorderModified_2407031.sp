/************************************************************************
 *		This plugin saves GOTV recording when ban is issued				*
 *		It's up to you to have GOTV setup correctly						*
 *																		*
 *		It's recommended you have delay set. E.g 3minutes				*
 *																		*
 *		This is built for sourcebans, others might work					*
 *																		*
 *		This is in experimental stage. Just something I put together in	*
 *		couple of minutes												*
 *																		*
 *		Saves demos in csgo/demos/TIME-AUTH								*
 *																		*
 *		Yeah code is awful. Not 100% chance to work						*
 *		I might be working on this to improve it...						*
 ***********************************************************************/
 //Some 'extensions' that you can enable disable
#define UploadFTP			//Requires tEasyFTP + curl - Uploads to FTP (config 'demos')
#define Sourcebans			//Adds the demo to the ban (UploadFTP needs to be enabled!)
#define sbprefix "sb"		//Sourcebans prefix
#define compress			//Compress
#define RemoveUncompressed	//Remove uncompressed file after compressing
#define RemoveAfterUpload	//Remove the demo(compressed if enabled) after uploading to FTP
#define CompressLevel 0		//Compression level to use for BZ2
//Note: It will only delete files if it successfuly compressed/uploaded

#pragma semicolon 1

#define PLUGIN_AUTHOR "Deathknife | Code Modified By JustCallMeLuke"
#define PLUGIN_VERSION "2.00"

#include <sourcemod>
#include <sdktools>
#if defined UploadFTP
#endif
#if defined compress
#endif

public Plugin myinfo = 
{
	name = "GOTV BAN RECORDER",
	author = PLUGIN_AUTHOR,
	description = "Made by Deathknife, Modified By JustCallMeLuke",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	//Create directory if doesnt exist
	CreateDirectory("/addons/sourcemod/demos/", 511);
}

public Action OnBanClient(int client, int time, int flags, const char[] reason, const char[] kick_message, const char[] command, any source) {
	//Get authid. One to store in pack, other for path
	char authid[32];
	char szauthid[32];
	GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
	strcopy(szauthid, sizeof(szauthid), authid);
	
	//A file cannot cointain :
	ReplaceString(szauthid, sizeof(szauthid), ":", " ");
	
	//Foramt path
	static char timestring[42];
	static char path[PLATFORM_MAX_PATH];
	FormatTime(timestring, sizeof(timestring), "%Y-%m-%d %H-%M-%S");
	FormatEx(path, sizeof(path), "/addons/sourcemod/demos/RENAMETHISTOMAKEITWORK%s %s", timestring, szauthid);
	
	//Execute tv_record and immediately after tv_stoprecord
	ServerCommand("tv_record \"%s\"; tv_stoprecord", path);
	//Create pack
	Handle pack = CreateDataPack();
	Format(path, sizeof(path), "RENAMETHISTOMAKEITWORK%s.dem", path);
	WritePackString(pack, path);
	WritePackString(pack, authid);
	
	//Create timer before proceeding -> allows demo to save.
	//It doesn't take 3 seconds, probably 0.1sec would be enough
	CreateTimer(3.0, ProceedFile, pack);
}

public Action ProceedFile(Handle timer, any pack) {
	ResetPack(pack);
	char path[PLATFORM_MAX_PATH];
	ReadPackString(pack, path, sizeof(path));
}


