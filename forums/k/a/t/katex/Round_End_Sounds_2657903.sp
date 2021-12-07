#pragma semicolon 1

#define DEBUG

#include <sdktools>
#include <colors>

// ----->> SONG LIST <<----- //
//Song #01
#define SONG1 "sound/dnc_song1.mp3"
#define p_SONG1 "dnc_song1.mp3"
#define n_SONG1 "Name Song #01"
//Song #02
#define SONG2 "sound/dnc_song2.mp3"
#define p_SONG2 "dnc_song2.mp3"
#define n_SONG2 "Name Song #02"
//Song #03
#define SONG3 "sound/dnc_song3.mp3"
#define p_SONG3 "dnc_song3.mp3"
#define n_SONG3 "Name Song #03"
//Song #04
#define SONG4 "sound/dnc_song4.mp3"
#define p_SONG4 "dnc_song4.mp3"
#define n_SONG4 "Name Song #04"
//Song #05
#define SONG5 "sound/dnc_song5.mp3"
#define p_SONG5 "dnc_song5.mp3"
#define n_SONG5 "Name Song #05"
//Song #06
#define SONG6 "sound/dnc_song6.mp3"
#define p_SONG6 "dnc_song6.mp3"
#define n_SONG6 "Name Song #06"
//Song #07
#define SONG7 "sound/dnc_song7.mp3"
#define p_SONG7 "dnc_song7.mp3"
#define n_SONG7 "Name Song #07"
//Song #08
#define SONG8 "sound/dnc_song8.mp3"
#define p_SONG8 "dnc_song8.mp3"
#define n_SONG8 "Name Song #08"
//Song #09
#define SONG9 "sound/dnc_song9.mp3"
#define p_SONG9 "dnc_song9.mp3"
#define n_SONG9 "Name Song #09"
//Song #10
#define SONG10 "sound/dnc_song10.mp3"
#define p_SONG10 "dnc_song10.mp3"
#define n_SONG10 "Name Song #010"
//Song #11
#define SONG11 "sound/dnc_song11.mp3"
#define p_SONG11 "dnc_song11.mp3"
#define n_SONG11 "Name Song #11"
//Song #12
#define SONG12 "sound/dnc_song12.mp3"
#define p_SONG12 "dnc_song12.mp3"
#define n_SONG12 "Name Song #12"
//Song #13
#define SONG13 "sound/dnc_song13.mp3"
#define p_SONG13 "dnc_song13.mp3"
#define n_SONG13 "Name Song #13"
//Song #14
#define SONG14 "sound/dnc_song14.mp3"
#define p_SONG14 "dnc_song14.mp3"
#define n_SONG14 "Name Song #14"
//Song #15
#define SONG15 "sound/dnc_song15.mp3"
#define p_SONG15 "dnc_song15.mp3"
#define n_SONG15 "Name Song #015"
// ----->> SONG LIST <<----- //

public Plugin myinfo = 
{
	name = "Round End Musics",
	author = "KaTeX",
	description = "Puts Music at the end of Rounds..",
	version = "0.3",
	url = "https://steamcommunity.com/id/ikatex"
};

public void OnPluginStart()
{
	PrintToServer("Round End Musics loaded.");
}

public void OnMapStart()
{
	HookEvent("round_end", Play_Song, EventHookMode_Pre);
	AddFileToDownloadsTable(SONG1); //Song #01
	PrecacheSound(p_SONG1);
	AddFileToDownloadsTable(SONG2); //Song #02
	PrecacheSound(p_SONG2);
	AddFileToDownloadsTable(SONG3); //Song #03
	PrecacheSound(p_SONG3);
	AddFileToDownloadsTable(SONG4); //Song #04
	PrecacheSound(p_SONG4);
	AddFileToDownloadsTable(SONG5); //Song #05
	PrecacheSound(p_SONG5);
	AddFileToDownloadsTable(SONG6); //Song #06
	PrecacheSound(p_SONG6);
	AddFileToDownloadsTable(SONG7); //Song #07
	PrecacheSound(p_SONG7);
	AddFileToDownloadsTable(SONG8); //Song #08
	PrecacheSound(p_SONG8);
	AddFileToDownloadsTable(SONG9); //Song #09
	PrecacheSound(p_SONG9);
	AddFileToDownloadsTable(SONG10); //Song #10
	PrecacheSound(p_SONG10);
	AddFileToDownloadsTable(SONG11); //Song #11
	PrecacheSound(p_SONG11);
	AddFileToDownloadsTable(SONG12); //Song #12
	PrecacheSound(p_SONG12);
	AddFileToDownloadsTable(SONG13); //Song #13
	PrecacheSound(p_SONG13);
	AddFileToDownloadsTable(SONG14); //Song #14
	PrecacheSound(p_SONG14);
	AddFileToDownloadsTable(SONG15); //Song #15
	PrecacheSound(p_SONG15);
}

public void Play_Song(Event event, const char[] name, bool dontBroadcast)
{
	int randomnum = GetRandomInt(0, 15);
	
	if (randomnum == 1){ 
		EmitSoundToAll(p_SONG1);
		CPrintToChatAll("{green}[REM] {default}Now is playing: {green}%s", n_SONG1);
	}
	if (randomnum == 2){ 
		EmitSoundToAll(p_SONG2);
		CPrintToChatAll("{green}[REM] {default}Now is playing: {green}%s", n_SONG2);
	}
	if (randomnum == 3){ 
		EmitSoundToAll(p_SONG3);
		CPrintToChatAll("{green}[REM] {default}Now is playing: {green}%s", n_SONG3);
	}
	if (randomnum == 4){ 
		EmitSoundToAll(p_SONG4);
		CPrintToChatAll("{green}[REM] {default}Now is playing: {green}%s", n_SONG4);
	}
	if (randomnum == 5){ 
		EmitSoundToAll(p_SONG5);
		CPrintToChatAll("{green}[REM] {default}Now is playing: {green}%s", n_SONG5);
	}
	if (randomnum == 6){ 
		EmitSoundToAll(p_SONG6);
		CPrintToChatAll("{green}[REM] {default}Now is playing: {green}%s", n_SONG6);
	}
	if (randomnum == 7){ 
		EmitSoundToAll(p_SONG7);
		CPrintToChatAll("{green}[REM] {default}Now is playing: {green}%s", n_SONG7);
	}
	if (randomnum == 8){ 
		EmitSoundToAll(p_SONG8);
		CPrintToChatAll("{green}[REM] {default}Now is playing: {green}%s", n_SONG8);
	}
	if (randomnum == 9){ 
		EmitSoundToAll(p_SONG9);
		CPrintToChatAll("{green}[REM] {default}Now is playing: {green}%s", n_SONG9);
	}
	if (randomnum == 10){ 
		EmitSoundToAll(p_SONG10);
		CPrintToChatAll("{green}[REM] {default}Now is playing: {green}%s", n_SONG10);
	}
	if (randomnum == 11){ 
		EmitSoundToAll(p_SONG11);
		CPrintToChatAll("{green}[REM] {default}Now is playing: {green}%s", n_SONG11);
	}
	if (randomnum == 12){ 
		EmitSoundToAll(p_SONG12);
		CPrintToChatAll("{green}[REM] {default}Now is playing: {green}%s", n_SONG12);
	}
	if (randomnum == 13){ 
		EmitSoundToAll(p_SONG13);
		CPrintToChatAll("{green}[REM] {default}Now is playing: {green}%s", n_SONG13);
	}
	if (randomnum == 14){ 
		EmitSoundToAll(p_SONG14);
		CPrintToChatAll("{green}[REM] {default}Now is playing: {green}%s", n_SONG14);
	}
	if (randomnum == 15){ 
		EmitSoundToAll(p_SONG15);
		CPrintToChatAll("{green}[REM] {default}Now is playing: {green}%s", n_SONG15);
	}
	
	return Plugin_Continue;
}