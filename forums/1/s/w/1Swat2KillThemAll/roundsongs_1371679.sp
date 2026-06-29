/**
 * @file	roundsongs.sp
 * @author	1Swat2KillThemAll
 *
 * @brief	Round Songs - Source Engine SourceMod plugin
 *			-As inspired by PStar
 * @version	1.000.000
 *
 * Round Songs
 * Copyright (C)/© 2010 B.D.A.K. Koch
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define MAX_FILE_LENGTH 256
new Handle:g_h_arr_strFileList = INVALID_HANDLE,
	Handle:g_h_arr_strNameList = INVALID_HANDLE,
	Handle:g_h_arrDurationList = INVALID_HANDLE,
	Handle:g_hSoundTimer = INVALID_HANDLE,
	g_iMaxSound = 0,
	String:g_strCurrentSound[MAX_FILE_LENGTH],
	bool:g_bIsListening[MAXPLAYERS+2] = { true, ... },
	g_SndLevel[MAXPLAYERS+2] = { SNDLEVEL_NORMAL, ... },
	Float:g_SndVolume[MAXPLAYERS+2] = { SNDVOL_NORMAL, ... },
	Handle:g_h_CvEnabled = INVALID_HANDLE;

#define PLUGIN_NAME "Round Songs"
#define PLUGIN_AUTHOR "1Swat2KillThemAll"
#define PLUGIN_DESCRIPTION "Spam music to all your clients! :D"
#define PLUGIN_VERSION "1.000.000"
#define PLUGIN_URL "http://ccc-clan.com/"
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};
public OnPluginStart()
{
	CreateConVar("sm_roundsongs_version", PLUGIN_VERSION, "Version ConVar", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_CHEAT);
	g_h_CvEnabled = CreateConVar("sm_roundsongs_enabled", "1", "Sets whether or not to enable this plugin.", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	HookConVarChange(g_h_CvEnabled, OnConVarChanged);
	LoadSoundList();
	RegAdminCmd("sm_nextsong", Sm_NextSong, ADMFLAG_SLAY);
	RegConsoleCmd("sm_music", Sm_Music);
	RegConsoleCmd("sm_soundlevel", Sm_SoundLevel);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}
public OnMapStart()
{
	g_hSoundTimer = INVALID_HANDLE;
	LoadSoundList();
}
public OnClientPutInServer(client)
{
	g_bIsListening[client] = true;
	g_SndLevel[client] = SNDLEVEL_NORMAL;
	g_SndVolume[client] = SNDVOL_NORMAL;
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StringToInt(newVal))
	{
		HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		StartSound(false);
	}
	else
	{
		UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		EndSound();
	}
}
public Action:Sm_NextSong(client, args)
{
	StartSound();
}
public Action:Sm_Music(client, args)
{
	g_bIsListening[client] = !g_bIsListening[client];

	if (!g_bIsListening[client])
	{
		StopSound(client, SNDCHAN_AUTO, g_strCurrentSound);
	}

	PrintToChat(client, "[SM] You %sabled the music!", (g_bIsListening[client]?"en":"dis"));
}
public Action:Sm_SoundLevel(client, args)
{
	if (args != 1)
	{
		PrintToChat(client, "[SM] Current level: %i, use sm_soundlevel <soundlevel (int)> to change it.", g_SndLevel[client]);
	}
	else
	{
		decl String:buff[8];
		GetCmdArg(1, buff, sizeof(buff));
		g_SndLevel[client] = StringToInt(buff);
	}
}

StartSound(bool:EndFirst = true)
{
	decl String:buff[MAX_FILE_LENGTH], index;

	if (g_hSoundTimer != INVALID_HANDLE)
	{
		KillTimer(g_hSoundTimer);
		g_hSoundTimer = INVALID_HANDLE;
	}

	if (EndFirst)
	{
		EndSound();
	}

	GetArrayString(g_h_arr_strFileList, (index = GetRandomInt(0, g_iMaxSound - 1)), buff, sizeof(buff));
	strcopy(g_strCurrentSound, sizeof(g_strCurrentSound), buff);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && g_bIsListening[i])
		{
			EmitSoundToClient(i, buff, SOUND_FROM_PLAYER, SNDCHAN_AUTO, g_SndLevel[i], SND_NOFLAGS, g_SndVolume[i]);
		}
	}

	GetArrayString(g_h_arr_strNameList, index, buff, sizeof(buff));
	PrintToChatAll("[SM] The server's now playing %s", buff);

	g_hSoundTimer = CreateTimer(Float:GetArrayCell(g_h_arrDurationList, index) + 2.0, Timer_SoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);
}
public Action:Timer_SoundEnd(Handle:timer, any:data)
{
	EndSound();
	StartSound();
}

EndSound()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		StopSound(i, SNDCHAN_AUTO, g_strCurrentSound);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_h_CvEnabled))
	{
		StartSound(false);
	}
}

IsValidClient(client)
{
	return client && IsClientInGame(client) && IsClientConnected(client);
}

LoadSoundList()
{
	decl String:buff[MAX_FILE_LENGTH],
		String:File[MAX_FILE_LENGTH],
		String:Name[MAX_FILE_LENGTH],
		Float:Duration;

	if (g_h_arr_strFileList != INVALID_HANDLE)
	{
		CloseHandle(g_h_arr_strFileList);
	}
	if (g_h_arr_strNameList != INVALID_HANDLE)
	{
		CloseHandle(g_h_arr_strNameList);
	}
	if (g_h_arrDurationList != INVALID_HANDLE)
	{
		CloseHandle(g_h_arrDurationList);
	}
	g_h_arr_strFileList = CreateArray(MAX_FILE_LENGTH);
	g_h_arr_strNameList = CreateArray(MAX_FILE_LENGTH);
	g_h_arrDurationList = CreateArray();

	new Handle:kv = CreateKeyValues("RoundSongs");

	if (!FileToKeyValues(kv, "cfg/sourcemod/roundsongs.kv") || !KvGotoFirstSubKey(kv))
	{
		CloseHandle(kv);
		SetFailState("Couldn\'t open keyvalue file!");
	}

	g_iMaxSound = 0;
	do
	{
		KvGetSectionName(kv, Name, sizeof(Name));
		if (StrEqual(Name, ""))
		{
			continue;
		}

		KvGetString(kv, "file", File, sizeof(File));
		Format(buff, sizeof(buff), "sound/%s", File);
		if (!FileExists(buff) || !PrecacheSound(File))
		{
			continue;
		}

		if ((Duration = KvGetFloat(kv, "duration", -1.0)) <= 0.0)
		{
			continue;
		}

		PushArrayString(g_h_arr_strFileList, File);
		PushArrayString(g_h_arr_strNameList, Name);
		PushArrayCell(g_h_arrDurationList, Duration);

		AddFileToDownloadsTable(buff);
		g_iMaxSound++;
	} while (KvGotoNextKey(kv));

	CloseHandle(kv);

	if (!(GetArraySize(g_h_arr_strFileList) && GetArraySize(g_h_arr_strNameList) && GetArraySize(g_h_arrDurationList)) || g_iMaxSound < 1)
	{
		SetFailState("The plugin encountered an error processing the keyvalue file!");
	}	
}
/*
CVARS:
sm_roundsongs_version | version cvar
sm_roundsongs_enabled | take an educated guess ;)
COMMANDS:
	Admin:
	* sm_nextsong | oh gee, I wonder what this would do...
	Public:
	* sm_music | Turn music on or off (autotoggle)
	* sm_soundlevel | Check your current soundlevel, or alter it.
CFG FILE (../cstrike/cfg/sourcemod/roundsongs.kv):
//--
"RoundSongs"
{
	"Song's name here"
	{
		"file"				"sound's filepath relative to ../cstrike/sound/"
		"duration"			"songlength in seconds (float)"
	}
	"Whole Lotta Rosie - AC/DC"
	{
		"file"				"misc/wholelottarosie.wav"
		"duration"			"324.5"
	}
	"Thunderstruck - AC/DC"
	{
		"file"				"misc/thunderstruck.wav"
		"duration"			"292.5"
	}
	"WanDeage"
	{
		"file"				"misc/wandeage.wav"
		"duration"			"2.0"
	}
}
//--
ORIGINAL REQUEST:
[PStar]
Hello to everyone.

I would like to request a plugin that every time a new round start it's chooses a random music from a list (or could be a specified diretorie in the sound flodder). IF the music is short and will end before the round end the plugin should start a new one.
And if it's possible we should be able to set the loudnes of the music whit a cvar.

Thx in forward. 
[6th Dec 2010 , 12:30 PM]
*/
