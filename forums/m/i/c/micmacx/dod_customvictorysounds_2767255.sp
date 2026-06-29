#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"1.2"

public Plugin:myinfo = 
{
	name = "DoD Custom Victory Sounds", 
	author = "FeuerSturm", 
	description = "Change the Round Win sounds!", 
	version = PLUGIN_VERSION, 
	url = "http://www.dodsplugins.net"
}

#define ALLIES_DEFAULT	"ambient/us_win.mp3"
#define AXIS_DEFAULT	"ambient/german_win.mp3"

new String:SoundCfg[] =  { "cfg/dod_customvictorysounds/dod_customvictorysounds.cfg" }
new String:CurrentMap[64]
new String:AlliesWinSnd[256], String:AxisWinSnd[256], String:AlliesWinFile[256], String:AxisWinFile[256]

new Handle:VictorySounds = INVALID_HANDLE

new bool:DownloadFilter[MAXPLAYERS + 1]

public OnPluginStart()
{
	CreateConVar("dod_customvictorysounds_version", PLUGIN_VERSION, "DoD Custom Victory Sounds Version (DO NOT CHANGE!)", FCVAR_DONTRECORD | FCVAR_NOTIFY)
	SetConVarString(FindConVar("dod_customvictorysounds_version"), PLUGIN_VERSION)
	VictorySounds = CreateConVar("dod_victorysounds_status", "1", "<1/0> = enable/disable changing the victory sounds", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	HookEvent("dod_broadcast_audio", OnBroadcastAudio, EventHookMode_Pre)
}

public OnMapStart()
{
	new Handle:victorysoundvalue = CreateKeyValues("DoDCustomVictorySounds")
	if (!FileExists(SoundCfg, true))
	{
		SetFailState("File dod/cfg/dod_customvictorysounds/dod_customvictorysounds.cfg is missing!")
		return 
	}
	GetCurrentMap(CurrentMap, sizeof(CurrentMap))
	FileToKeyValues(victorysoundvalue, SoundCfg)
	if (!KvJumpToKey(victorysoundvalue, CurrentMap))
	{
		KvJumpToKey(victorysoundvalue, "Generic_Settings")
	}
	KvGetString(victorysoundvalue, "AlliedVictory", AlliesWinSnd, sizeof(AlliesWinSnd), "ambient/us_win.mp3")
	KvGetString(victorysoundvalue, "AxisVictory", AxisWinSnd, sizeof(AxisWinSnd), "ambient/german_win.mp3")
	CloseHandle(victorysoundvalue)
	Format(AlliesWinFile, sizeof(AlliesWinFile), "sound/%s", AlliesWinSnd)
	Format(AxisWinFile, sizeof(AxisWinFile), "sound/%s", AxisWinSnd)
	PrecacheSound(AlliesWinSnd)
	PrecacheSound(AxisWinSnd)
	PrecacheSound(ALLIES_DEFAULT)
	PrecacheSound(AXIS_DEFAULT)
	AddFileToDownloadsTable(AlliesWinFile)
	AddFileToDownloadsTable(AxisWinFile)
}

public OnClientPutInServer(client)
{
	QueryClientConVar(client, "cl_downloadfilter", ConVarQueryFinished:dlfilter)
}

public Action:OnBroadcastAudio(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(VictorySounds) == 0)
	{
		return Plugin_Continue
	}
	new String:sound[128]
	GetEventString(event, "sound", sound, sizeof(sound))
	if (strcmp(sound, "Game.USWin", true) == 0)
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && !IsFakeClient(client))
			{
				if (DownloadFilter[client])
				{
					EmitSoundToClient(client, ALLIES_DEFAULT)
				}
				else if (!DownloadFilter[client])
				{
					EmitSoundToClient(client, AlliesWinSnd)
				}
			}
		}
		return Plugin_Handled
	}
	if (strcmp(sound, "Game.GermanWin", true) == 0)
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && !IsFakeClient(client))
			{
				if (DownloadFilter[client])
				{
					EmitSoundToClient(client, AXIS_DEFAULT)
				}
				else if (!DownloadFilter[client])
				{
					EmitSoundToClient(client, AxisWinSnd)
				}
			}
		}
		return Plugin_Handled
	}
	return Plugin_Continue
}

public dlfilter(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName1[], const String:cvarValue1[])
{
	if (strcmp(cvarValue1, "all", true) == 0)
	{
		DownloadFilter[client] = false
	}
	else
	{
		DownloadFilter[client] = true
	}
} 