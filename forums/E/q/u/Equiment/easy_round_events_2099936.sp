// Includes
#include <sourcemod>
#include <sdktools>
#include <morecolors>
#pragma semicolon 1

// Variables
new Handle:g_CvarCTstart = INVALID_HANDLE;
new Handle:g_CvarCTwin = INVALID_HANDLE;
new Handle:g_CvarTstart = INVALID_HANDLE;
new Handle:g_CvarTwin = INVALID_HANDLE;
new String:g_soundCTw[80];
new String:g_soundCTs[80];
new String:g_soundTw[80];
new String:g_soundTs[80];
new winner;

// Info
public Plugin:myinfo = 
{
	name = "Easy Round Events",
	author = "Equiment",
	description = "Custom messages & sounds",
	version = "1.0",
	url = "http://steamcommunity.com/id/equiment"
}

// Start
public OnPluginStart() 
{
	LoadTranslations("easy_round_events.phrases");
	g_CvarCTstart = CreateConVar("sm_ct_start_sound", "", "Sound to play to CT force on spawn.");
	g_CvarTstart = CreateConVar("sm_t_start_sound", "", "Sound to play to T force on spawn.");
	g_CvarCTwin = CreateConVar("sm_ct_end_sound", "", "Sound to play on round end if CT force win.");
	g_CvarTwin = CreateConVar("sm_t_end_sound", "", "Sound to play on round end if T force win.");

	AutoExecConfig(true, "easy_round_events");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	PrecacheSound("radio/ctwin.wav", false);
	PrecacheSound("radio/terwin.wav", false);
}

// Executing
public OnConfigsExecuted() 
{
	GetConVarString(g_CvarCTstart, g_soundCTs, 80);
	decl String:CTs[80];
	PrecacheSound(g_soundCTs, true);
	Format(CTs, sizeof(CTs), "sound/%s", g_soundCTs);
	AddFileToDownloadsTable(CTs);
//
	GetConVarString(g_CvarTstart, g_soundTs, 80);
	decl String:Ts[80];
	PrecacheSound(g_soundTs, true);
	Format(Ts, sizeof(Ts), "sound/%s", g_soundTs);
	AddFileToDownloadsTable(Ts);
//
	GetConVarString(g_CvarCTwin, g_soundCTw, 80);
	decl String:CTw[80];
	PrecacheSound(g_soundCTw, true);
	Format(CTw, sizeof(CTw), "sound/%s", g_soundCTw);
	AddFileToDownloadsTable(CTw);
//
	GetConVarString(g_CvarTwin, g_soundTw, 80);
	decl String:Tw[80];
	PrecacheSound(g_soundTw, true);
	Format(Tw, sizeof(Tw), "sound/%s", g_soundTw);
	AddFileToDownloadsTable(Tw);
}

// Round Start
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	for(new client = 1; client <= MaxClients; client++) 
	{
		if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
		{
			if (GetClientTeam(client) == 3)
			{
				CPrintToChat(client, "%t", "CT_Start");
				EmitSoundToClient(client,g_soundCTs);
			}
			if (GetClientTeam(client) == 2)
			{
				CPrintToChat(client, "%t", "T_Start");
				EmitSoundToClient(client,g_soundTs);
			}
		}
	}
} 

// Round End
public Event_RoundEnd(Handle:event, const String:name[], bool:silent) 
{ 
	if (!silent) 
	{ 
		SetEventBroadcast(event, true); 
	}
	
	winner = GetEventInt(event, "winner");
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			StopSound(i, SNDCHAN_STATIC, "radio/ctwin.wav");
			StopSound(i, SNDCHAN_STATIC, "radio/terwin.wav");
		}
		if (winner == 2)
		{
			PrintCenterText(i, "%t", "T_Win");
			EmitSoundToClient(i, g_soundTw, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		}
		if (winner == 3)
		{
			PrintCenterText(i, "%t", "CT_Win");
			EmitSoundToClient(i, g_soundCTw, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		}
	}
} 