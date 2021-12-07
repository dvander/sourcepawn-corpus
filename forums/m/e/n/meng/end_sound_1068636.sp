/*
	end_sound.sp

	Description:
	Plays music/sound at the end of the map.

	Versions:
	1.2
	* Initial Release
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2m"
#define MAX_FILE_LEN 255

public Plugin:myinfo = 
{
	name = "Map End Music/Sound",
	author = "TechKnow, meng",
	description = "Plays Music/sound at the end of the map.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new Handle:g_hCvarMaxrounds;
new Handle:g_hCvarTimeLimit;
new g_iRoundCount;
new bool:g_bPlaySound;
new String:g_sCurrSound[MAX_FILE_LEN];

public OnPluginStart()
{
	CreateConVar("sm_MapEnd_Sound_version", PLUGIN_VERSION, "MapEnd_Sound_Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hCvarMaxrounds = FindConVar("mp_maxrounds");
	g_hCvarTimeLimit = FindConVar("mp_timelimit");
	HookEvent("round_end", EventRoundEnd);
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
}

public OnMapStart()
{
	g_iRoundCount = 0;
	g_bPlaySound = false;
	if (DirExists("sound/mapend"))
	{
		new Handle:dir = OpenDirectory("sound/mapend");
		new Handle:soundsArray = CreateArray(MAX_FILE_LEN);
		new FileType:type;
		decl String:file[MAX_FILE_LEN];
		while (ReadDirEntry(dir, file, sizeof(file), type))
			if (type == FileType_File)
				PushArrayString(soundsArray, file);
		CloseHandle(dir);
		new arraySize = GetArraySize(soundsArray);
		if (arraySize)
		{
			GetArrayString(soundsArray, GetRandomInt(0, arraySize-1), file, sizeof(file));
			Format(g_sCurrSound, sizeof(g_sCurrSound), "sound/mapend/%s", file);
			AddFileToDownloadsTable(g_sCurrSound);
			Format(g_sCurrSound, sizeof(g_sCurrSound), "mapend/%s", file);
			PrecacheSound(g_sCurrSound, true);
		}
		else
			LogError("No sound files found in sound/mapend.");
		CloseHandle(soundsArray);
	}
	else
		LogError("Directory sound/mapend does not exist.");
}

public EventRoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	new timeleft; GetMapTimeLeft(timeleft);
	if (GetConVarInt(g_hCvarTimeLimit) && (timeleft <= 0))
	{
		PlayTheMapEndSound();
		return;
	}

	new winner = GetEventInt(event, "winner");
	if ((winner == 0) || (winner == 1))
		return;

	g_iRoundCount++;
	new MaxRounds = GetConVarInt(g_hCvarMaxrounds);
	if (MaxRounds && (g_iRoundCount >= MaxRounds))
		g_bPlaySound = true;
}

public EventRoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (g_bPlaySound)
		PlayTheMapEndSound();
}

PlayTheMapEndSound()
{
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
			EmitSoundToClient(i, g_sCurrSound);
}