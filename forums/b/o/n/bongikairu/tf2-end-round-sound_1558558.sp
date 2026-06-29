#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "TF2 End Round Sound",
	author = "BongiKairu",
	description = "Plugin plays custom sound when round ends.",
	version = PLUGIN_VERSION
};

public OnPluginStart()
{
	HookEventEx("teamplay_win_panel", Event_TeamPlayWinSound);
	
	CreateConVar("sm_tf2_end_round_sound_version", PLUGIN_VERSION, "Plugin Version",
		FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED |
		FCVAR_NOTIFY | FCVAR_DONTRECORD);
}

public OnMapStart()
{
    AddFileToDownloadsTable("sound/custom/TF2-win.mp3");
	PrecacheSound("custom/TF2-win.mp3");
	
	AddFileToDownloadsTable("sound/custom/TF2-lose.mp3");
    PrecacheSound("custom/TF2-lose.mp3");
}

public Event_TeamPlayWinSound(Handle:event, const String:name[],
							 bool:dontBroadcast)
{
	new WinTeam = GetEventInt(event, "winning_team");
	if (WinTeam == 2 || WinTeam == 3)
	{
		CreateTimer(0.1, Timer_PushSound, WinTeam);
	}
}

public Action:Timer_PushSound(Handle:timer, any:WinTeam)
{
	if (IsVoteInProgress()) return;

	new client;
	
	for (new i = 0; i < MaxClients; i++)
	{
		client = i + 1;
		if(IsClientInGame(client)) {
			if(GetClientTeam(client) == WinTeam) {
				ClientCommand( client, "play custom/TF2-win.mp3"); 
			} else {
				ClientCommand( client, "play custom/TF2-lose.mp3" ); 
			}
		}
	}
}