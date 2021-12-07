/*
advancedc4timer.sp

Description:
	Advanced c4 countdown timer.  Based on the original sm c4 timer by sslice.  Much of the
	work here is his.

Versions:
	0.5
		* Initial Release
		
	0.6
		* Restructued most of the code
		* Added user configuration of sounds
		* Added optional announcement
		* Changed timer to go 30, 20, 10, 9.....1
		
	1.0
		* Minor code and naming standards changes
		* Added support for late loading
		
	1.1
		* Added an exit option to the settings menu
		* Changed command to sm_c4timer
		* Made the SoundNames array const
		* Added new hud text
		
	1.1.1
		* Fixed voice countdown bug
		
	1.2
		* Added translations
		* Added name to bomb exploded message
		* Added bomb defused hud message
		
	1.2.1
		* Updated translation files and script to match
		* Changed menu behavior
*/
		
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2.1a"
#define NUM_SOUNDS 12
#define TIMER 30

#define TWENTY 0
#define ONE 1
#define TWO 2
#define THREE 3
#define FOUR 4
#define FIVE 5
#define SIX 6
#define SEVEN 7
#define EIGHT 8
#define NINE 9
#define TEN 10
#define THIRTY 11

#define NUM_PREFS 4
#define SOUND 0
#define CHAT 1
#define CENTER 2
#define HUD 3

public Plugin:myinfo = 
{
	name = "Advanced c4 Countdown Timer",
	author = "AMP",
	description = "Plugin that gives a countdown for the C4 explosion in Counter-Strike Source.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};


// Global Variables
new String:soundsList[1][NUM_SOUNDS][PLATFORM_MAX_PATH];
new c4Preferences[MAXPLAYERS + 1][NUM_PREFS];
new Handle:kvC4;
new String:filenameC4[PLATFORM_MAX_PATH];
new Handle:cvarEnable;
new Handle:cvarMPc4Timer;
new Handle:cvarAnnounce;
new explosionTime;
new lastCountdown;
new bool:lateLoaded;
new String:planter[40];
static const String:soundNames[NUM_SOUNDS][] = {"20", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "30"};

// We need to capture if the plugin was late loaded so we can make sure initializations
// are handled properly
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	lateLoaded = late;
	return true;
}

public OnPluginStart()
{
	CreateConVar("sm_c4_timer_version", PLUGIN_VERSION, "Advanced c4 Timer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("sm_c4_timer_enable", "1", "Enables the c4 timer");
	cvarAnnounce = CreateConVar("sm_c4_timer_announce", "1", "Announcement preferences");

	cvarMPc4Timer = FindConVar("mp_c4timer");
	
	LoadTranslations("plugin.advancedc4timer");

	HookEvent("bomb_planted", EventBombPlanted, EventHookMode_Post);
	HookEvent("bomb_beep", EventBombBeep, EventHookMode_PostNoCopy);
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
	HookEvent("bomb_exploded", EventBombExploded, EventHookMode_PostNoCopy);
	HookEvent("bomb_defused", EventBombDefused, EventHookMode_Post);
	RegConsoleCmd("sm_c4timer", PanelSettings);

	LoadSounds();
	
	kvC4=CreateKeyValues("c4UserSettings");
  	BuildPath(Path_SM, filenameC4, PLATFORM_MAX_PATH, "data/c4usersettings.txt");
	if(!FileToKeyValues(kvC4, filenameC4))
    	KeyValuesToFile(kvC4, filenameC4);
    	
	// if the plugin was loaded late we have a bunch of initialization that needs to be done
	if(lateLoaded) {
		// First we need to do whatever we would have done at OnMapStart()
		for(new i=0; i < NUM_SOUNDS; i++)
			PrepareSound(i);

		// Next we need to whatever we would have done as each client authorized
		for(new i = 1; i < GetMaxClients(); i++) {
			if(IsClientInGame(i))
				PrepareClient(i);
		}
	}
}

public OnMapStart()
{
	for(new i=0; i < NUM_SOUNDS; i++)
		PrepareSound(i);
}

// When a new client is authorized we create sound preferences
// for them if they do not have any already
public OnClientAuthorized(client, const String:auth[])
{
	PrepareClient(client);
}

// Based on the original by sslice
public EventBombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(cvarEnable))
		return;
	
	explosionTime = GetTime() + GetConVarInt(cvarMPc4Timer);
	
	GetClientName(GetClientOfUserId(GetEventInt(event, "userid")), planter, sizeof(planter));
}

public EventBombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(cvarEnable))
		return;
	
	decl String:defuser[40];
	GetClientName(GetClientOfUserId(GetEventInt(event, "userid")), defuser, sizeof(defuser));
	for(new i = 1; i <= GetMaxClients(); i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && c4Preferences[i][HUD])
			PrintHintText(i, "%T", "bomb defused", i, defuser);
	}
}

// Based on the original by sslice
public EventBombBeep(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(cvarEnable))
		return;
	
	new now = GetTime();
	new diff = explosionTime - now;
	if (diff <= TIMER && lastCountdown != now && diff >= 0) {
		lastCountdown = GetTime();
		BombMessage(diff);
	}
}

// Loads the soundsList array with the c4 sounds
public LoadSounds()
{
	new Handle:kvQSL = CreateKeyValues("c4SoundsList");
	new String:fileQSL[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, fileQSL, PLATFORM_MAX_PATH, "configs/c4soundslist.cfg");
	FileToKeyValues(kvQSL, fileQSL);
	
	if (!KvGotoFirstSubKey(kvQSL))	{
		SetFailState("configs/c4soundslist.cfg not found or not correctly structured");
		return;
	}

	for(new i = 0; i < NUM_SOUNDS; i++)
		KvGetString(kvQSL, soundNames[i], soundsList[0][i], PLATFORM_MAX_PATH);
	
	CloseHandle(kvQSL);
}

public PrepareSound(sound)
{
	new String:downloadFile[PLATFORM_MAX_PATH];

	if(!StrEqual(soundsList[0][sound], "")) {
		PrecacheSound(soundsList[0][sound], true);
		Format(downloadFile, PLATFORM_MAX_PATH, "sound/%s", soundsList[0][sound]);
		AddFileToDownloadsTable(downloadFile);
	} else
		PrintToServer("Failed to prepare %i", sound);
}

// Sends the bomb message
public BombMessage(count)
{
	new soundKey;
	
	switch(count) {
		case 1, 2, 3, 4, 5, 6, 7, 8, 9, 10:
			soundKey = count;
		case 20:
			soundKey = TWENTY;
		case 30:
			soundKey = THIRTY;
		default:
			return;
	}
	
	for (new i = 1; i <= GetMaxClients(); i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && !StrEqual(soundsList[0][soundKey], "")) {
			if(c4Preferences[i][SOUND])
				EmitSoundToClient(i, soundsList[0][soundKey]);
			if(c4Preferences[i][CHAT])
				PrintToChat(i, "Bomb: %d", count);
			if(c4Preferences[i][CENTER])
				PrintCenterText(i, "%d", count);
			if(c4Preferences[i][HUD])
				PrintHintText(i, "%d", count);
		}
	}
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if(IsClientInGame(client))
		PrintToChat(client, "%t", "announce");
}

//  This selects or disables the c4 settings
public PanelHandlerSettings(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		// Update both the soundPreference array and User Settings KV
		switch(param2)
		{
			case 1:
				c4Preferences[param1][SOUND] = Flip(c4Preferences[param1][SOUND]);
			case 2:
				c4Preferences[param1][CHAT] = Flip(c4Preferences[param1][CHAT]);
			case 3:
				c4Preferences[param1][CENTER] = Flip(c4Preferences[param1][CENTER]);
			case 4:
				c4Preferences[param1][HUD] = Flip(c4Preferences[param1][HUD]);
			case 5:
				return;
		}
		new String:steamId[20];
		GetClientAuthString(param1, steamId, 20);
		KvRewind(kvC4);
		KvJumpToKey(kvC4, steamId);
		KvSetNum(kvC4, "sound", c4Preferences[param1][SOUND]);
		KvSetNum(kvC4, "chat", c4Preferences[param1][CHAT]);
		KvSetNum(kvC4, "center", c4Preferences[param1][CENTER]);
		KvSetNum(kvC4, "hud", c4Preferences[param1][HUD]);
		KvSetNum(kvC4, "timestamp", GetTime());
		PanelSettings(param1, 0);
	}
}
 
//  This creates the settings panel
public Action:PanelSettings(client, args)
{
	decl String:buffer[100];
	new Handle:panel = CreatePanel();
	Format(buffer, sizeof(buffer), "%T", "c4 menu", client);
	SetPanelTitle(panel, buffer);
	if(c4Preferences[client][SOUND] == 1)
		Format(buffer, sizeof(buffer), "%T", "disable sound", client);
	else
		Format(buffer, sizeof(buffer), "%T", "enable sound", client);
	DrawPanelItem(panel, buffer);

	if(c4Preferences[client][CHAT] == 1)
		Format(buffer, sizeof(buffer), "%T", "disable chat", client);
	else
		Format(buffer, sizeof(buffer), "%T", "enable chat", client);
	DrawPanelItem(panel, buffer);
	
	if(c4Preferences[client][CENTER] == 1)
		Format(buffer, sizeof(buffer), "%T", "disable center", client);
	else
		Format(buffer, sizeof(buffer), "%T", "enable center", client);
	DrawPanelItem(panel, buffer);
	
	if(c4Preferences[client][HUD] == 1)
		Format(buffer, sizeof(buffer), "%T", "disable hud", client);
	else
		Format(buffer, sizeof(buffer), "%T", "enable hud", client);
	DrawPanelItem(panel, buffer);

	Format(buffer, sizeof(buffer), "%T", "exit", client);
	DrawPanelItem(panel, buffer);
	
	SendPanelToClient(panel, client, PanelHandlerSettings, 20);
 
	CloseHandle(panel);
 
	return Plugin_Handled;
}

// Switches a non-zero number to a 0 and a 0 to a 1
public Flip(flipNum)
{
	if(flipNum == 0)
		return 1;
	else
		return 0;
}

// Initializations to be done at the beginning of the round
public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Save user settings to a file
	KvRewind(kvC4);
	KeyValuesToFile(kvC4, filenameC4);
}

// When a user disconnects we need to update their timestamp in kvC4
public OnClientDisconnect(client)
{
	new String:steamId[20];
	if(client && !IsFakeClient(client)) {
		GetClientAuthString(client, steamId, 20);
		KvRewind(kvC4);
		if(KvJumpToKey(kvC4, steamId))
			KvSetNum(kvC4, "timestamp", GetTime());
	}
}

public PrepareClient(client)
{
	new String:steamId[20];
	if(client) {
		if(!IsFakeClient(client)) {
			// Get the users saved setting or create them if they don't exist
			GetClientAuthString(client, steamId, 20);
			KvRewind(kvC4);
			if(KvJumpToKey(kvC4, steamId)) {
				c4Preferences[client][SOUND] = KvGetNum(kvC4, "sound", 1);
				c4Preferences[client][CHAT] = KvGetNum(kvC4, "chat", 0);
				c4Preferences[client][CENTER] = KvGetNum(kvC4, "center", 1);
				c4Preferences[client][HUD] = KvGetNum(kvC4, "hud", 0);
			}
			else {
				KvRewind(kvC4);
				KvJumpToKey(kvC4, steamId, true);
				KvSetNum(kvC4, "sound", 1);
				KvSetNum(kvC4, "chat", 0);
				KvSetNum(kvC4, "center", 1);
				KvSetNum(kvC4, "hud", 0);
				c4Preferences[client][SOUND] = 1;
				c4Preferences[client][CHAT] = 0;
				c4Preferences[client][CENTER] = 1;
				c4Preferences[client][HUD] = 0;
			}
			KvRewind(kvC4);

			// Make the announcement in 30 seconds unless announcements are turned off
			if(GetConVarBool(cvarAnnounce))
				CreateTimer(30.0, TimerAnnounce, client);
		}
	}
}

public EventBombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= GetMaxClients(); i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && c4Preferences[i][HUD])
			PrintHintText(i, "%T", "bomb exploded", i, planter);
	}
}
