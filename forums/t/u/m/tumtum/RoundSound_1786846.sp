/* *
 * RoundSound BY TUMMIETUM (TUMTUM)
 * -------------------------
 * Changelog Original Roundsound++ by ANTiCHRiST
 * -------------------------
 * by TanaToS aka ANTiCHRiST
 */
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <console>
#include <string>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1.0"
#define MAX_FILE_LEN 256

new Handle:g_hEnabled = INVALID_HANDLE;
new bool:g_bEnabled = true;

public Plugin:myinfo = {
	name = "RoundSound CS:GO",
	author = "ANTiCHRiST Edited by TumTum",
	description = "Plays a Sound at RoundEnd.",
	version = PLUGIN_VERSION,
	url = "http://www.team-secretforce.com"
};

public OnPluginStart() {
	CreateConVar("sm_roundsound_version", PLUGIN_VERSION, "RoundSound version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("sm_roundsound_enable", "1", "RoundSound Enable/Disable CVar.", FCVAR_PLUGIN|FCVAR_NOTIFY);

	HookEvent("round_end", EventRoundEnd);
	HookConVarChange(g_hEnabled, CVarEnabled);
}

public OnMapStart()
{
	decl String:tewin_snd1[MAX_FILE_LEN];
	decl String:tewin_snd2[MAX_FILE_LEN];
	decl String:tewin_snd3[MAX_FILE_LEN];
	decl String:ctwin_snd1[MAX_FILE_LEN];
	decl String:ctwin_snd2[MAX_FILE_LEN];
	decl String:ctwin_snd3[MAX_FILE_LEN];

	Format(tewin_snd1, sizeof(tewin_snd1), "sound/music/misc/twinnar1.mp3");
	Format(tewin_snd2, sizeof(tewin_snd2), "sound/music/misc/twinnar2.mp3");
	Format(tewin_snd3, sizeof(tewin_snd3), "sound/music/misc/twinnar3.mp3");
	Format(ctwin_snd1, sizeof(ctwin_snd1), "sound/music/misc/ctwinnar1.mp3");
	Format(ctwin_snd2, sizeof(ctwin_snd2), "sound/music/misc/ctwinnar2.mp3");
	Format(ctwin_snd3, sizeof(ctwin_snd3), "sound/music/misc/ctwinnar3.mp3");

	if(FileExists(tewin_snd1) && FileExists(tewin_snd2) && FileExists(tewin_snd3) && FileExists(ctwin_snd1) && FileExists(ctwin_snd2) && FileExists(ctwin_snd3)) {
		AddFileToDownloadsTable(tewin_snd1);
		AddFileToDownloadsTable(tewin_snd2);
		AddFileToDownloadsTable(tewin_snd3);
		AddFileToDownloadsTable(ctwin_snd1);
		AddFileToDownloadsTable(ctwin_snd2);
		AddFileToDownloadsTable(ctwin_snd3);

		PrecacheSound("music/misc/ctwinnar1.mp3", true);
		PrecacheSound("music/misc/ctwinnar2.mp3", true);
		PrecacheSound("music/misc/ctwinnar3.mp3", true);
		PrecacheSound("music/misc/twinnar1.mp3", true);
		PrecacheSound("music/misc/twinnar2.mp3", true);
		PrecacheSound("music/misc/twinnar3.mp3", true);
	}
	else {
		LogError("Not all sound files exists.");
		LogError("Unload the Plugin.");
		ServerCommand("sm plugins unload \"RoundSound.smx\"");
	}
}

public OnConfigsExecuted() {
	if(GetConVarBool(g_hEnabled)) {
		g_bEnabled = true;
	}
	else if(!GetConVarBool(g_hEnabled)) {
		g_bEnabled = false;
	}
	else {
		g_bEnabled = true;
		LogError("False value plugin continued");
	}
}

public CVarEnabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(GetConVarBool(g_hEnabled)) {
		g_bEnabled = true;
	}
	else if(!GetConVarBool(g_hEnabled)) {
		g_bEnabled = false;
	}
	else {
		g_bEnabled = true;
		LogError("False value plugin continued");
	}
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	new rnd_sound = GetRandomInt(1, 3);
	new ev_winner = GetEventInt(event, "winner");
	if(g_bEnabled) {
		if(ev_winner == 2) {
			if(rnd_sound == 1) {
				EmitSoundToAll("music/misc/twinnar1.mp3");
			}
			else if(rnd_sound == 2) {
				EmitSoundToAll("music/misc/twinnar2.mp3");
			}
			else if(rnd_sound == 3) {
				EmitSoundToAll("music/misc/twinnar3.mp3");
			}
			else {
				LogError("Ramdom Sound CVar Error.");
			}
		}
		else if(ev_winner == 3) {
			if(rnd_sound == 1) {
				EmitSoundToAll("music/misc/ctwinnar1.mp3");
			}
			else if(rnd_sound == 2) {
				EmitSoundToAll("music/misc/ctwinnar2.mp3");
			}
			else if(rnd_sound == 3) {
				EmitSoundToAll("music/misc/ctwinnar3.mp3");
			}
			else {
				LogError("Ramdom Sound CVar Error.");
			}
		}
		else {
			LogError("No team has win the round.");
		}
	}
}