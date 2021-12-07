#include <sourcemod>
#include <cURL>
#pragma semicolon 1
#define PLUGIN_VERSION "2.0.0"

new Handle:v_Enable = INVALID_HANDLE;
new Handle:v_Quota = INVALID_HANDLE;
new Handle:v_Days = INVALID_HANDLE;
new Handle:v_PathToPHP = INVALID_HANDLE;
new Handle:v_PathToReplays = INVALID_HANDLE;
new Handle:v_Log = INVALID_HANDLE;
new Handle:v_AutoPrune = INVALID_HANDLE;
new Handle:v_SecretKey = INVALID_HANDLE;

new bool:g_TimerRunning = false;

public Plugin:myinfo =
{
	name = "[TF2] HTTP Replay Cleaner Redux",
	author = "DarthNinja / Rowedahelicon",
	description = "Delete old replay files when you exceed a set limit",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com / Rowedahelicon.com"
};

public OnPluginStart()
{
	//Cvars
	CreateConVar("sm_replaycleanup_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	v_Enable = CreateConVar("sm_replaycleanup_enable", "1", "Enable/Disable the plugin", 0, true, 0.0, true, 1.0);
	v_Quota = CreateConVar("sm_replaycleanup_cachesize", "1024", "The plugin will only begin pruning files after the folder exceeds this size.  Sizes are in MB.");
	v_Days = CreateConVar("sm_replaycleanup_days", "4", "When the folder exceeds the cache size cvar, files older then this many days will be deleted.");
	v_PathToPHP = CreateConVar("sm_replaycleanup_link", "http://www.yoursite.com/tf2/replays/file.php", "The http link to open the php file.");
	v_PathToReplays = CreateConVar("sm_replaycleanup_localpath", "tf/2/", "Path to the replay files from where the php script is located.");
	v_Log = CreateConVar("sm_replaycleanup_save_logfile", "0", "Set to 1 to save a log on the webserver with a list of the deleted files", 0, true, 0.0, true, 1.0);
	v_AutoPrune = CreateConVar("sm_replaycleanup_autoprune", "0", "Set this to a non-zero value to auto run a cleaning every X hours in addition to at round ends", 0, true, 0.0);
	v_SecretKey = CreateConVar("sm_replaycleanup_secretkey", "", "Your secret key to keep people from posting to your page.");

	LoadTranslations("common.phrases");
	AutoExecConfig(true, "HTTPReplayCleanup");
	HookEvent("teamplay_round_win", Cleanup,  EventHookMode_Post);
}

public OnConfigsExecuted()
{
	new Float:fTime = GetConVarFloat(v_AutoPrune);
	if (fTime > 0.0 && !g_TimerRunning)
	{
		g_TimerRunning = true;
		CreateTimer((fTime * 60.0 * 60.0 ), Timer_CleanUp, INVALID_HANDLE, TIMER_REPEAT);
	}
}

public Action:Timer_CleanUp(Handle:timer, any:userid)
{
	Cleanup2();
	return Plugin_Continue;
}

public Cleanup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(v_Enable))
	{
		Cleanup2();
	}
}

Cleanup2()
{

		decl String:sLink[100];
		decl String:sPath[25];
		decl String:sKey[25];
		GetConVarString(v_PathToPHP, sLink, sizeof(sLink));
		GetConVarString(v_PathToReplays, sPath, sizeof(sPath));
		GetConVarString(v_SecretKey, sKey, sizeof(sKey));
		
		new String:query[PLATFORM_MAX_PATH];
		Format(query, sizeof(query), "max_size=%i&age_days=%i&path=%s&log=%i&key=%s", GetConVarInt(v_Quota), GetConVarInt(v_Days), sPath, GetConVarInt(v_Log), sKey);
		
		new Handle:curl = curl_easy_init();
    
		curl_easy_setopt_string(curl, CURLOPT_URL, sLink);
		curl_easy_setopt_int(curl, CURLOPT_SSL_VERIFYPEER, 0);
		curl_easy_setopt_int(curl, CURLOPT_SSL_VERIFYHOST, 2);
		curl_easy_setopt_string(curl, CURLOPT_POSTFIELDS, query);
		curl_easy_perform_thread(curl, OnComplete);

}

public OnComplete(Handle:hndl, CURLcode: code)
{
    CloseHandle(hndl);
}