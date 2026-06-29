#pragma semicolon 1
#include <sourcemod>
#include <downloader>

//#define debug_banlistchecker
//#if defined debug_banlistchecker
//#endif

/*

this plugin makes use of a ban/not-banned cache in order to cut down on bandwidth usage and prevent flooding, don't expect changes to take effect quicky,
map changes and reconnects shouldn't result in another web request.

almost the same as the following, by devicenull : http://forums.alliedmods.net/showthread.php?t=39949

sm_banlist_add "http://somewebsite.com/checkid.php?steamid=%s"
sm_banlist_add "http://asdf.com/checkid.php?steamid=%s"
sm_banlist_add "http://aaaaaa.com/checkid.php?steamid=%s"
sm_banlist_finalize

web page format:
3,B,STEAMID,3,

Credits
http://forums.alliedmods.net/showthread.php?t=39949
http://forums.alliedmods.net/showthread.php?p=631313
http://forums.alliedmods.net/showthread.php?t=54611

*/
public Plugin:myinfo =
{
	name = "Banlist Checker",
	author = "Seather",
	description = "Check multiple websites for bans when user connects",
	version = "0.0.1",
	url = "http://www.sourcemod.net"
};

#define MAXURLLEN 2048
#define MAXLISTS 20
#define MAXPLAYERS_BLOCK (MAXPLAYERS + 1)
#define XSLOTS (MAXPLAYERS_BLOCK * MAXLISTS)
#define MAXDATA 50
new String:ListArray[MAXLISTS][MAXURLLEN]; //URLs to check for bans
new Handle:DownloaderArray[XSLOTS] = {INVALID_HANDLE, ...};
new String:DataArray[XSLOTS][MAXDATA]; //Strings fetched from URLs
new bool:SentArray[MAXPLAYERS_BLOCK]; //Set once URLs are sent for a user
new g_ListCount = 0;
new bool:g_finalized = false;//when true prevent any more lists from being added

#define CACHESIZE (MAXPLAYERS_BLOCK + 10) //don't need to download when its in cache, helps with map changes
new String:CacheID[CACHESIZE][MAXDATA];
new bool:CacheBan[CACHESIZE] = false;
new CacheMarker = 0;

public OnPluginStart()
{
	RegServerCmd("sm_banlist_add",Command_add);
	RegServerCmd("sm_banlist_finalize",Command_finalize);
	
	//todo: every 30 second timer
}
public Action:Command_add(args) {
	if(g_finalized == true)
		return;
	if(g_ListCount == MAXLISTS)
		return;
		
	decl String:arg[MAXURLLEN];
	GetCmdArg(1, arg, sizeof(arg));
	Format(ListArray[g_ListCount], MAXURLLEN, "%s", arg);
	
	g_ListCount++;
}
public Action:Command_finalize(args) {
	g_finalized = true;
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen) {
	SentArray[client] = false;
	return true;
}
public OnClientAuthorized(client, const String:auth[]) {
#if defined debug_banlistchecker
	PrintToServer("auth");
#endif
	TryCheck(client);
}
public OnClientDisconnect(client) {
	decl String:auth[50];
	GetClientAuthString(client, auth, sizeof(auth));
	//PrintToServer("disconnect %s",auth);

	CacheAdd(auth,false);

}
CacheAdd(const String:auth[], bool:banned) {
	if(CheckCache(auth) == 1)
		return;
	Format(CacheID[CacheMarker], MAXDATA, "%s", auth);
	CacheBan[CacheMarker] = banned;
	CacheMarker++;
	if(CacheMarker == CACHESIZE)
		CacheMarker = 0;
}
CheckCache(const String:auth[]) {
	new returnvalue = -1;
	new i;
	//Look for entries set to ban
	for(i = 0;i < CACHESIZE; i++) {
		if(StrEqual(CacheID[i],auth,false)) {
			returnvalue = 0;
			if(CacheBan[i] == true) {
				returnvalue = 1;
				break;
			}
		}
	}
	
	//return
	//-1 not found
	//0 found, not banned
	//1 found, banned
	return returnvalue;
}
//needs to contain numbers, LAN won't pass
bool:isValidSteamid(const String:auth[]) {
	decl String:steamid_test[50];
	Format(steamid_test, sizeof(steamid_test), "%s", auth);
	ReplaceString(steamid_test, sizeof(steamid_test), "STEAM_", "");
	ReplaceString(steamid_test, sizeof(steamid_test), ":", "");
	new i;
	for(i = 0;i < strlen(steamid_test);i++) {
		if(!IsCharNumeric(steamid_test[i]))
			return false;
	}
	return true;
}
TryCheck(client) {
	if(!IsClientConnected(client))
		return;
	if(SentArray[client] == true)
		return;
	if(g_finalized == false)
		return;
	if(!IsClientAuthorized(client))
		return;
	decl String:auth[50];
	GetClientAuthString(client, auth, sizeof(auth));
	
	//if we've made it here we don't need to do another check
	SentArray[client] = true;
	
	if(IsFakeClient(client))
		return;
	
	//Check cache
	new tempcheck = CheckCache(auth);
	if(tempcheck == 0)
		return;
	if(tempcheck == 1) {
		tempBan(auth);
		return;
	}
	
	//download
	new i,k;
	for(i = 0;i < g_ListCount;i++) {
		k = (MAXPLAYERS_BLOCK * i) + client;
		
		if(DownloaderArray[k] != INVALID_HANDLE) {
			CloseHandle(DownloaderArray[k]);
			DownloaderArray[k] = INVALID_HANDLE;
		}
		DownloaderArray[k] = CreateDownloader();
		
		//URL
		decl String:tempurl[MAXURLLEN];
		Format(tempurl, sizeof(tempurl), "%s", ListArray[i]);
		ReplaceString(tempurl, sizeof(tempurl), "%s", auth);
		SetURL(DownloaderArray[k], tempurl);
#if defined debug_banlistchecker
		PrintToServer("url %s",tempurl);
#endif

		SetCallback(DownloaderArray[k], update_Complete);
		SetProgressCallback(DownloaderArray[k], update_Progress);

		SetArg(DownloaderArray[k], k);
		
		SetOutputString(DownloaderArray[k], DataArray[k], MAXDATA);

		Download(DownloaderArray[k]);
	}
	
}

public update_Progress(const recvSize, const totalSize, Handle:arg)
{
}

public update_Complete(const sucess, const status, Handle:arg)
{
	//PrintToServer("Banlist DownloadComplete: %i %i",sucess, status);
	//PrintToServer("arg %i",arg);

	new k = arg;
	
	//take care of the handle
	if(DownloaderArray[k] != INVALID_HANDLE) {
		CloseHandle(DownloaderArray[k]);
		DownloaderArray[k] = INVALID_HANDLE;
	}
	
	//abort if download failed
	if(sucess != 1)
		return;
	
	new String:tokens[7][50];
	ExplodeString(DataArray[k],",",tokens,7,50);
	
#if defined debug_banlistchecker
	PrintToServer("data %s",DataArray[k]);
	PrintToServer("tokens[2] %s",tokens[2]);
#endif
	
	//Check format around Steamid 
	// 3,B,STEAM,3,
	if(!StrEqual(tokens[0],"3",false) || !StrEqual(tokens[1],"B",false) || !StrEqual(tokens[3],"3",false))
		return;
		
#if defined debug_banlistchecker
	PrintToServer("checkpoint 1");
#endif
	
	//Check Steamid Format
	if(!isValidSteamid(tokens[2]))
		return;

#if defined debug_banlistchecker
	PrintToServer("checkpoint 2");
#endif
		
	//Kick + Ban
	if(CheckCache(tokens[2]) != 1)
		CacheAdd(tokens[2],true);
	tempBan(tokens[2]);
}

tempBan(const String:auth[]) {
	ServerCommand("banid 5 %s", auth);
	//the kick parameter for the banid command does not work in a certain time window
	
	ServerCommand("kickid %s", auth);
	
#if defined debug_banlistchecker
	PrintToServer("ban %s", auth);
#endif
}

