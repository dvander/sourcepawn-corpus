/* *
 * ANTiCHRiST RoundSound++ 
 * -------------------------
 * Changelog
 *   changelog.txt
 * Readme
 *   readme.txt
 * Credits
 *   Old CS 1.6 Plugin
 *   by "PaintLancer"
 * Thxs
 *   To NAT for his help!
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
	name = "RoundSound++",
	author = "ANTiCHRiST",
	description = "Plays a Sound at RoundEnd.",
	version = PLUGIN_VERSION,
	url = "http://passionfighters.de"
};

public OnPluginStart() {
	CreateConVar("sm_roundsound_version", PLUGIN_VERSION, "RoundSound++ version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("sm_roundsound_enable", "1", "RoundSound++ Enable/Disable CVar.", FCVAR_PLUGIN|FCVAR_NOTIFY);

	HookEvent("round_end", EventRoundEnd);
	HookConVarChange(g_hEnabled, CVarEnabled);
}

public OnMapStart()
{
	decl String:tewin_snd1[MAX_FILE_LEN];
	decl String:tewin_snd2[MAX_FILE_LEN];
	decl String:tewin_snd3[MAX_FILE_LEN];
        decl String:tewin_snd4[MAX_FILE_LEN];
        decl String:tewin_snd5[MAX_FILE_LEN];
        decl String:tewin_snd6[MAX_FILE_LEN];
        decl String:tewin_snd7[MAX_FILE_LEN];
        decl String:tewin_snd8[MAX_FILE_LEN];
        decl String:tewin_snd9[MAX_FILE_LEN];
        decl String:tewin_snd10[MAX_FILE_LEN];
        decl String:tewin_snd11[MAX_FILE_LEN];
        decl String:tewin_snd12[MAX_FILE_LEN];
	decl String:ctwin_snd1[MAX_FILE_LEN];
	decl String:ctwin_snd2[MAX_FILE_LEN];
	decl String:ctwin_snd3[MAX_FILE_LEN];
        decl String:ctwin_snd4[MAX_FILE_LEN];
        decl String:ctwin_snd5[MAX_FILE_LEN];
        decl String:ctwin_snd6[MAX_FILE_LEN];
        decl String:ctwin_snd7[MAX_FILE_LEN];
        decl String:ctwin_snd8[MAX_FILE_LEN];
        decl String:ctwin_snd9[MAX_FILE_LEN];
        decl String:ctwin_snd10[MAX_FILE_LEN];
        decl String:ctwin_snd11[MAX_FILE_LEN];
        decl String:ctwin_snd12[MAX_FILE_LEN];

	Format(tewin_snd1, sizeof(tewin_snd1), "sound/misc/twinnar.mp3");
	Format(tewin_snd2, sizeof(tewin_snd2), "sound/misc/twinnar2.mp3");
	Format(tewin_snd3, sizeof(tewin_snd3), "sound/misc/twinnar3.mp3");
        Format(tewin_snd1, sizeof(tewin_snd4), "sound/misc/twinnar4.mp3");
        Format(tewin_snd1, sizeof(tewin_snd5), "sound/misc/twinnar5.mp3");
        Format(tewin_snd1, sizeof(tewin_snd6), "sound/misc/twinnar6.mp3");
        Format(tewin_snd1, sizeof(tewin_snd7), "sound/misc/twinnar7.mp3");
        Format(tewin_snd1, sizeof(tewin_snd8), "sound/misc/twinnar8.mp3");
        Format(tewin_snd1, sizeof(tewin_snd9), "sound/misc/twinnar9.mp3");
        Format(tewin_snd1, sizeof(tewin_snd10), "sound/misc/twinnar10.mp3");
        Format(tewin_snd1, sizeof(tewin_snd11), "sound/misc/twinnar11.mp3");
        Format(tewin_snd1, sizeof(tewin_snd12), "sound/misc/twinnar12.mp3");
	Format(ctwin_snd1, sizeof(ctwin_snd1), "sound/misc/ctwinnar.mp3");
	Format(ctwin_snd2, sizeof(ctwin_snd2), "sound/misc/ctwinnar2.mp3");
	Format(ctwin_snd3, sizeof(ctwin_snd3), "sound/misc/ctwinnar3.mp3");
        Format(ctwin_snd3, sizeof(ctwin_snd4), "sound/misc/ctwinnar4.mp3");
        Format(ctwin_snd3, sizeof(ctwin_snd5), "sound/misc/ctwinnar5.mp3");
        Format(ctwin_snd3, sizeof(ctwin_snd6), "sound/misc/ctwinnar6.mp3");
        Format(ctwin_snd3, sizeof(ctwin_snd7), "sound/misc/ctwinnar7.mp3");
        Format(ctwin_snd3, sizeof(ctwin_snd8), "sound/misc/ctwinnar8.mp3");
        Format(ctwin_snd3, sizeof(ctwin_snd9), "sound/misc/ctwinnar9.mp3");
        Format(ctwin_snd3, sizeof(ctwin_snd10), "sound/misc/ctwinnar10.mp3");
        Format(ctwin_snd3, sizeof(ctwin_snd11), "sound/misc/ctwinnar11.mp3");
        Format(ctwin_snd3, sizeof(ctwin_snd12), "sound/misc/ctwinnar12.mp3");

	if(FileExists(tewin_snd1) && FileExists(tewin_snd2) && FileExists(tewin_snd3) && FileExists(tewin_snd4) && FileExists(tewin_snd5) && FileExists(tewin_snd5) && FileExists(tewin_snd6) && FileExists(tewin_snd7) && FileExists(tewin_snd8) && FileExists(tewin_snd9) && FileExists(tewin_snd10) && FileExists(tewin_snd11) && FileExists(tewin_snd12) && FileExists(ctwin_snd1) && FileExists(ctwin_snd2) && FileExists(ctwin_snd3) && FileExists(ctwin_snd4) && FileExists(ctwin_snd5) && FileExists(ctwin_snd6) && FileExists(ctwin_snd7) && FileExists(ctwin_snd8) && FileExists(ctwin_snd9) && FileExists(ctwin_snd10) && FileExists(ctwin_snd11) && FileExists(ctwin_snd12)) {
		AddFileToDownloadsTable(tewin_snd1);
		AddFileToDownloadsTable(tewin_snd2);
		AddFileToDownloadsTable(tewin_snd3);
                AddFileToDownloadsTable(tewin_snd4);
                AddFileToDownloadsTable(tewin_snd5);
                AddFileToDownloadsTable(tewin_snd6);
                AddFileToDownloadsTable(tewin_snd7);
                AddFileToDownloadsTable(tewin_snd8);
                AddFileToDownloadsTable(tewin_snd9);
                AddFileToDownloadsTable(tewin_snd10);
                AddFileToDownloadsTable(tewin_snd11);
                AddFileToDownloadsTable(tewin_snd12);
		AddFileToDownloadsTable(ctwin_snd1);
		AddFileToDownloadsTable(ctwin_snd2);
		AddFileToDownloadsTable(ctwin_snd3);
                AddFileToDownloadsTable(ctwin_snd4);
                AddFileToDownloadsTable(ctwin_snd5);
                AddFileToDownloadsTable(ctwin_snd6);
                AddFileToDownloadsTable(ctwin_snd7);
                AddFileToDownloadsTable(ctwin_snd8);
                AddFileToDownloadsTable(ctwin_snd9);
                AddFileToDownloadsTable(ctwin_snd10);
                AddFileToDownloadsTable(ctwin_snd11);
                AddFileToDownloadsTable(ctwin_snd12);

		PrecacheSound("sound/misc/ñtwinnar.mp3", true);
		PrecacheSound("sound/misc/ñtwinnar2.mp3", true);
		PrecacheSound("sound/misc/ñtwinnar3.mp3", true);
                PrecacheSound("sound/misc/ñtwinnar4.mp3", true);
                PrecacheSound("sound/misc/ñtwinnar5.mp3", true);
                PrecacheSound("sound/misc/ñtwinnar6.mp3", true);
                PrecacheSound("sound/misc/ñtwinnar7.mp3", true);
                PrecacheSound("sound/misc/ñtwinnar8.mp3", true);
                PrecacheSound("sound/misc/ñtwinnar9.mp3", true);
                PrecacheSound("sound/misc/ctwinnar10.mp3", true);
                PrecacheSound("sound/misc/ctwinnar11.mp3", true);
                PrecacheSound("sound/misc/ctwinnar12.mp3", true);
		PrecacheSound("sound/misc/twinnar.mp3", true);
		PrecacheSound("sound/misc/twinnar2.mp3", true);
		PrecacheSound("sound/misc/twinnar3.mp3", true);
                PrecacheSound("sound/misc/twinnar4.mp3", true);
                PrecacheSound("sound/misc/twinnar5.mp3", true);
                PrecacheSound("sound/misc/twinnar6.mp3", true);
                PrecacheSound("sound/misc/twinnar7.mp3", true);
                PrecacheSound("sound/misc/twinnar8.mp3", true);
                PrecacheSound("sound/misc/twinnar9.mp3", true);
                PrecacheSound("sound/misc/twinnar10.mp3", true);
                PrecacheSound("sound/misc/twinnar11.mp3.mp3", true);
                PrecacheSound("sound/misc/twinnar11.mp3", true);
	}
	else {
		LogError("Not all sound files exists.");
		LogError("Unload the Plugin.");
		ServerCommand("sm plugins unload \"RoundSound++.smx\"");
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
				EmitSoundToAll("sound/misc/twinnar.mp3");
			}
			else if(rnd_sound == 2) {
				EmitSoundToAll("sound/misc/twinnar2.mp3");
			}
			else if(rnd_sound == 3) {
				EmitSoundToAll("sound/misc/twinnar3.mp3");
                        }
			else if(rnd_sound == 4) {
				EmitSoundToAll("sound/misc/twinnar4.mp3");
                        }
			else if(rnd_sound == 5) {
				EmitSoundToAll("sound/misc/twinnar5.mp3");
                        }
			else if(rnd_sound == 6) {
				EmitSoundToAll("sound/misc/twinnar6.mp3");
                        }
			else if(rnd_sound == 7) {
				EmitSoundToAll("sound/misc/twinnar7.mp3");
                        }
			else if(rnd_sound == 8) {
				EmitSoundToAll("sound/misc/twinnar8.mp3");
                        }
			else if(rnd_sound == 9) {
				EmitSoundToAll("sound/misc/twinnar9.mp3");
                        }
			else if(rnd_sound == 10) {
				EmitSoundToAll("sound/misc/twinnar10.mp3");
                        }
			else if(rnd_sound == 11) {
				EmitSoundToAll("sound/misc/twinnar11.mp3");
                        }
			else if(rnd_sound == 12) {
				EmitSoundToAll("sound/misc/twinnar12.mp3");
			}
			else {
				LogError("Ramdom Sound CVar Error.");
			}
		}
		else if(ev_winner == 3) {
			if(rnd_sound == 1) {
				EmitSoundToAll("sound/misc/ñtwinnar.mp3");
			}
			else if(rnd_sound == 2) {
				EmitSoundToAll("sound/misc/ñtwinnar2.mp3");
			}
			else if(rnd_sound == 3) {
				EmitSoundToAll("sound/misc/ñtwinnar3.mp3");
                        }
			else if(rnd_sound == 4) {
				EmitSoundToAll("sound/misc/ñtwinnar4.mp3");
                        }
			else if(rnd_sound == 5) {
				EmitSoundToAll("sound/misc/ñtwinnar5.mp3");
                        }
			else if(rnd_sound == 6) {
				EmitSoundToAll("sound/misc/ñtwinnar6.mp3");
                        }
			else if(rnd_sound == 7) {
				EmitSoundToAll("sound/misc/ñtwinnar7.mp3");
                        }
			else if(rnd_sound == 8) {
				EmitSoundToAll("sound/misc/ñtwinnar8.mp3");
                        }
			else if(rnd_sound == 9) {
				EmitSoundToAll("sound/misc/ñtwinnar9.mp3");
                        }
			else if(rnd_sound == 10) {
				EmitSoundToAll("sound/misc/ñtwinnar10.mp3");
                        }
			else if(rnd_sound == 11) {
				EmitSoundToAll("sound/misc/ñtwinnar11.mp3");
                        }
			else if(rnd_sound == 12) {
				EmitSoundToAll("sound/misc/ñtwinnar12.mp3");
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