#include <sourcemod>
#define PLUGIN_VERSION "1.1.1"

new Handle:v_Enable = INVALID_HANDLE;
new Handle:v_Quota = INVALID_HANDLE;
new Handle:v_Days = INVALID_HANDLE;
new Handle:v_PathToPHP = INVALID_HANDLE;
new Handle:v_PathToReplays = INVALID_HANDLE;
new Handle:v_Log = INVALID_HANDLE;
new Handle:v_AutoPrune = INVALID_HANDLE;

new g_LoopBreak = 0;
new bool:g_TimerRunning = false;

public Plugin:myinfo =
{
	name = "[TF2] HTTP Replay Cleaner",
	author = "DarthNinja",
	description = "Delete old replay files when you exceed a set limit",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{
	//Cvars
	CreateConVar("sm_replaycleanup_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	v_Enable = CreateConVar("sm_replaycleanup_enable", "1", "Enable/Disable the plugin", 0, true, 0.0, true, 1.0);
	v_Quota = CreateConVar("sm_replaycleanup_cachesize", "1024", "The plugin will only begin pruning files after the folder exceeds this size.  Sizes are in MB.");
	v_Days = CreateConVar("sm_replaycleanup_days", "4", "When the folder exceeds the cache size cvar, files older then this many days will be deleted.");
	v_PathToPHP = CreateConVar("sm_replaycleanup_link", "www.yoursite.com/tf2/replays/file.php", "The http link to open the php file. \n DO NOT use http:// !");
	v_PathToReplays = CreateConVar("sm_replaycleanup_localpath", "tf/2/", "Path to the replay files from where the php script is located.");
	v_Log = CreateConVar("sm_replaycleanup_save_logfile", "0", "Set to 1 to save a log on the webserver with a list of the deleted files", 0, true, 0.0, true, 1.0);
	v_AutoPrune = CreateConVar("sm_replaycleanup_autoprune", "0", "Set this to a non-zero value to auto run a cleaning every X hours in addition to at round ends", 0, true, 0.0);

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
	new iRandomClient = GetRandomInt(2, MaxClients); //Start at 2 to avoid selecting the replay bot
	Cleanup2(iRandomClient);
	return Plugin_Continue;
}

public Cleanup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(v_Enable))
	{
		new iRandomClient = GetRandomInt(2, MaxClients); //Start at 2 to avoid selecting the replay bot
		Cleanup2(iRandomClient);
	}
}

Cleanup2(iRandomClient)
{
	if (IsClientInGame(iRandomClient) && !IsFakeClient(iRandomClient))
	{
		new Handle:kvMOTD = CreateKeyValues("data");

		KvSetString(kvMOTD, "title", "Replay Cleanup");
		KvSetNum(kvMOTD, "type", MOTDPANEL_TYPE_URL);
		
		decl String:phpGET[256];
		decl String:sLink[100];
		decl String:sPath[25];
		GetConVarString(v_PathToPHP, sLink, sizeof(sLink))
		GetConVarString(v_PathToReplays, sPath, sizeof(sPath))
		
		FormatEx(phpGET, sizeof(phpGET), "%s?max_size=%i&age_days=%i&path=%s&log=%i", sLink, GetConVarInt(v_Quota), GetConVarInt(v_Days), sPath, GetConVarInt(v_Log));
		
		KvSetString(kvMOTD, "msg", phpGET);
		ShowVGUIPanel(iRandomClient, "info", kvMOTD, false); //false loads the page but doesnt show it
		//PrintToChatAll("Sending link %s to %N", phpGET, iRandomClient);	//debug
		CloseHandle(kvMOTD);
		g_LoopBreak = 0;
	}
	else if (g_LoopBreak < 5)
	{
		//Try again
		g_LoopBreak ++;
		iRandomClient = GetRandomInt(2, MaxClients);
		Cleanup2(iRandomClient);
	}
}