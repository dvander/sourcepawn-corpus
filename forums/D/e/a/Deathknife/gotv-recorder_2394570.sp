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
#define CompressLevel 9		//Compression level to use for BZ2
//Note: It will only delete files if it successfuly compressed/uploaded

#pragma semicolon 1

#define PLUGIN_AUTHOR "Deathknife"
#define PLUGIN_VERSION "2.00"

#include <sourcemod>
#include <sdktools>
#if defined UploadFTP
#include <tEasyFTP>
#include <curl>
#endif
#if defined compress
#include <bzip2>
#endif

public Plugin myinfo = 
{
	name = "GOTV BAN RECORDER",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

Handle db;
public void OnPluginStart()
{
	#if defined Sourcebans
	SQL_TConnect(DB_Connect, "sourcebans");
	#endif
	
	//Create directory if doesnt exist
	CreateDirectory("demos/", 511);
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
	FormatEx(path, sizeof(path), "demos/%s %s", timestring, szauthid);
	
	//Execute tv_record and immediately after tv_stoprecord
	ServerCommand("tv_record \"%s\"; tv_stoprecord", path);
	//Create pack
	Handle pack = CreateDataPack();
	Format(path, sizeof(path), "%s.dem", path);
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
	
	#if defined compress
	char compresspath[PLATFORM_MAX_PATH];
	FormatEx(compresspath, sizeof(compresspath), "%s.bz2", path);
	BZ2_CompressFile(path, compresspath, CompressLevel, Compressed_Demo, pack);
	#elseif defined UploadFTP
	EasyFTP_UploadFile("demos", path, "/", EasyFTP_CallBack, pack);
	#else
	CloseHandle(pack);
	#endif
}

#if defined compress
public Compressed_Demo(BZ_Error iError, char[] sIn, char[] sOut, any pack) {
	if(iError == BZ_OK) {
		#if defined RemoveUncompressed
		//sIn seems to give full path, so we read it from the pack
		ResetPack(pack);
		char path[PLATFORM_MAX_PATH];
		ReadPackString(pack, path, sizeof(path));
		if(!DeleteFile(path)) {
			LogError("Couldn't delete file %s", path);
		}
		#endif
		
		#if defined UploadFTP
		EasyFTP_UploadFile("demos", sOut, "/", EasyFTP_CallBack, pack);
		#else
		CloseHandle(pack);
		#endif
	} else {
		CloseHandle(pack);
		LogBZ2Error(iError);
	}
}
#endif

#if defined UploadFTP
public EasyFTP_CallBack(const String:sTarget[], const String:sLocalFile[], const String:sRemoteFile[], iErrorCode, any:pack)
{
    if(iErrorCode == 0)        // These are the cURL error codes
    {
        PrintToServer("Success. File %s uploaded to %s.", sLocalFile, sTarget);    
        #if defined Sourcebans
        char authid[32];
        char query[1024];
        char path[2];
        //Read from pack, no need to 
        ResetPack(pack);
        ReadPackString(pack, path, sizeof(path));
        ReadPackString(pack, authid, sizeof(authid));
        FormatEx(query, sizeof(query), "SELECT bid FROM %s_bans WHERE authid='%s' ORDER BY created DESC LIMIT 1;", sbprefix, authid);
        SQL_TQuery(db, DB_Select, query, pack);
        #else
        CloseHandle(pack);
        #endif
        
        #if defined RemoveAfterUpload
        DeleteFile(sLocalFile);
        #endif
    } else {
        PrintToServer("Failed uploading %s to %s.", sLocalFile, sTarget);    
        LogError("Failed uploading %s to %s.", sLocalFile, sTarget);    
        CloseHandle(pack);
    }
}  
#endif

public void DB_Connect(Handle owner, Handle hndl, char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Database failure: %s", error);
	} else {
		//Connected
		db = hndl;
	}
}

public void DB_Dummy(Handle owner, Handle hndl, char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Database failure: %s", error);
	} else {
		//
	}
}

public void DB_Select(Handle owner, Handle hndl, char[] error, any pack)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Database failure: %s", error);
	} else {
		if(SQL_FetchRow(hndl)) {
			int bid = SQL_FetchInt(hndl, 0);
			char path[PLATFORM_MAX_PATH];
			ResetPack(pack);
			ReadPackString(pack, path, sizeof(path));
			static char query[2048];
			
			char demtype;
			//no idea if it makes a difference
			#if defined compress
			demtype = 'B';
			Format(path, sizeof(path), "%s.bz2", path);
			#else
			demtype = 'b';
			#endif
			
			
			FormatEx(query, sizeof(query), "INSERT INTO %s_demos SET demid=%i, demtype='%c', filename='%s', origname='%s'", sbprefix, bid, demtype, path, path);
			SQL_TQuery(db, DB_Dummy, query);
		}
	}
	CloseHandle(pack);
}