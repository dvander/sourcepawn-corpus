/*
quakesounds.sp

Description:
	Plays Quake Sounds

Versions:
	0.4
		* Initial Release
	
	0.5
		* Added support for loading sounds from a configuration file

	0.6
		* Made user preferences persistent
		* Removed some unused code
		
	0.7
		* Cleaned up announcement text
		* Added error handling for missing sould list config file
		* Added teamkiller sounds
		* Added a more flexible kill count system
		* Added numerous control CVAR's
		* Added additional comments and #defines for readability
	
	0.8
		* Added cvar to suppress announcements
		* Made the current choice show in menu
		
	0.9
		* added progressive combo sounds
		* added progressive headshot sounds
		* restructured code
		* switched from play to EmitSound
		
	0.95
		* added DOD:S support
		* fixed announce cvar
		* added better error handling of sounds
		
	0.96
		* Added DOD:S smoke grenades
		* Added some better error handling for DOD:S
		* Fixed the sm_quakesounds_announce cvar....again
	
	1.0
		* Added time to the settings data to allow pruning at a later date
		* Added support for translations
		* Added text display of quake events
		* Added a cvar for default sound preference for new users
		* added a cvar for default text display preference
		* Moved sound setting cvar's into an array
		* Added individual sound and text information per sound
		
	1.1
		* Added the ability to print the names of those involved in the text
	
	1.2
		* Fixed numerous bugs surrounding the selecting and saving of text preferences
		* Switched MAX_CLIENTS to MAXPLAYERS
	
	1.3
		* Moved individual sound preferences to config file
		
	1.3.1
		* Fixed text for ROUND_PLAY
		* Fixed a bug in the play and text commands when the users sound preferences were not being accounted for
		* Fixed array out of bounds messages in PlayQuakeSounds()
		
	1.4
		* Added the ability to add and remove sound sets
		* Removed cvarMinKills and cvarFemale
		* Added the ability for the kill sounds to have custom kill counts
		
	1.4.1
		* Changed the behavior of disabled sounds
		
	1.4.2
		* Added some additional checks for HL2DM

	1.4.3
		* Added HL2DM weapons
*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.4.3"
#define NUM_SOUNDS 24
#define MAX_FILE_LEN 64
#define DISABLE_CHOICE 3
#define NO_KILLS -1.0
#define MAX_NUM_SETS 5

#define HEADSHOT 0
#define GRENADE 1
#define SELFKILL 2
#define ROUND_PLAY 3
#define KNIFE 4
#define KILLS_1 5
#define KILLS_2 6
#define KILLS_3 7
#define KILLS_4 8
#define KILLS_5 9
#define KILLS_6 10
#define KILLS_7 11
#define KILLS_8 12
#define KILLS_9 13
#define KILLS_10 14
#define KILLS_11 15
#define FIRSTBLOOD 16
#define TEAMKILL 17
#define DOUBLECOMBO 18
#define TRIPLECOMBO 19
#define QUADCOMBO 20
#define MONSTERCOMBO 21
#define HEADSHOT3 22
#define HEADSHOT5 23

#define OTHER 0
#define DODS 1
#define CSS 2
#define HL2DM 3

// Plugin definitions
public Plugin:myinfo = 
{
	name = "QuakeSounds",
	author = "AMP",
	description = "Quake Sounds Plugin",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

// Global Variables
new soundPreference[MAXPLAYERS + 1];
new textPreference[MAXPLAYERS + 1];
new consecutiveKills[MAXPLAYERS + 1];
new Float:lastKillTime[MAXPLAYERS + 1];
new lastKillCount[MAXPLAYERS + 1];
new String:soundsList[MAX_NUM_SETS][NUM_SOUNDS][MAX_FILE_LEN];
new String:setNames[MAX_NUM_SETS][30];
new killNumSetting[50];
new settingsArray[NUM_SOUNDS];
new totalKills;
new gameType = OTHER;
new headShotCount[MAXPLAYERS + 1];
new Handle:kvQUS;
new String:fileQUS[MAX_FILE_LEN];
new	Handle:cvarEnabled = INVALID_HANDLE;
new Handle:cvarAnnounce = INVALID_HANDLE;
new Handle:cvarTextDefault = INVALID_HANDLE;
new Handle:cvarSoundDefault = INVALID_HANDLE;
new numSets;
static const String:soundNames[NUM_SOUNDS][] = {"headshot", "grenade", "selfkill", "round play", "knife",
"killsound 1", "killsound 2", "killsound 3", "killsound 4", "killsound 5", "killsound 6", "killsound 7",
"killsound 8", "killsound 9", "killsound 10", "killsound 11", "first blood", "teamkill", "double combo",
"triple combo", "quad combo", "monster combo", "headshot 3", "headshot 5"};

public OnPluginStart()
{
	// Before we do anything else lets make sure that the plugin is not disabled
	cvarEnabled = CreateConVar("sm_quakesounds_enable", "1", "Enables the Quake sounds plugin");
	if(!GetConVarBool(cvarEnabled))
		SetFailState("Plugin Disabled");
		
	// Counter Strike Source
	decl String:gameName[80];
	GetGameFolderName(gameName, 80);
	if(StrEqual(gameName, "cstrike"))
		gameType = CSS;
	else if(StrEqual(gameName, "dod"))
		gameType = DODS;
	else if(StrEqual(gameName, "hl2mp"))
		gameType = HL2DM;
		
	LoadTranslations("plugin.quakesounds");
	
	// Create the remainder of the CVARs
	CreateConVar("sm_quakesounds_version", PLUGIN_VERSION, "Quake Sounds Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarAnnounce = CreateConVar("sm_quakesounds_announce", "1", "Announcement preferences");
	cvarTextDefault = CreateConVar("sm_quakesounds_text", "1", "Default text setting for new users");
	cvarSoundDefault = CreateConVar("sm_quakesounds_sound", "1", "Default sound for new users, 1=Standard, 2=Female, 0=Disabled");

	// Hook events and register commands as needed
	HookEvent("player_death", EventPlayerDeath);
	if(gameType == CSS)
		HookEvent("round_freeze_end", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
	else if(gameType == DODS)
		HookEvent("dod_warmup_ends", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
	if(gameType == DODS)
		HookEvent("dod_round_start", EventRoundStart, EventHookMode_PostNoCopy);
	else
		HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
	RegConsoleCmd("quake", PanelQuake);
	
	// Load the sounds and initialize kvQUS
	LoadSounds();
	kvQUS=CreateKeyValues("QuakeUserSettings");
  	BuildPath(Path_SM, fileQUS, MAX_FILE_LEN, "data/quakeusersettings.txt");
	if(!FileToKeyValues(kvQUS, fileQUS))
    	KeyValuesToFile(kvQUS, fileQUS);
}

public OnPluginEnd()
{
	CloseHandle(kvQUS);
}

public OnMapStart()
{
	PrepareQuakeSounds();
	ResetConsecutiveKills();
	if(gameType == HL2DM)
		NewRoundInitialization();

}


public Action:TimerAnnounce(Handle:timer, any:client)
{
	if(IsClientInGame(client))
		PrintToChat(client, "Say !quake or /quake to set your quake sounds preferences");
}

// When a new client is authorized we reset sound preferences
// and let them know how to turn the sounds on and off
public OnClientAuthorized(client, const String:auth[])
{
	new String:steamId[20];
	if(client) {
		if(!IsFakeClient(client)) {
			// Get the users saved setting or create them if they don't exist
			GetClientAuthString(client, steamId, 20);
			KvRewind(kvQUS);
			if(KvJumpToKey(kvQUS, steamId)) {
				soundPreference[client] = KvGetNum(kvQUS, "sound preference", GetConVarInt(cvarSoundDefault));
				textPreference[client] = KvGetNum(kvQUS, "text preference", GetConVarInt(cvarTextDefault));
			}
			else {
				KvJumpToKey(kvQUS, steamId, true);
				KvSetNum(kvQUS, "sound preference", GetConVarInt(cvarSoundDefault));
				KvSetNum(kvQUS, "text preference", GetConVarInt(cvarTextDefault));
				KvSetNum(kvQUS, "timestamp", GetTime());
				soundPreference[client] = GetConVarInt(cvarSoundDefault);
				textPreference[client] = GetConVarInt(cvarTextDefault);
			}
			KvRewind(kvQUS);

			// Make the announcement in 30 seconds unless announcements are turned off
			if(GetConVarBool(cvarAnnounce))
				CreateTimer(30.0, TimerAnnounce, client);
		}
		
		// Initialize variables
		consecutiveKills[client] = 0;
		lastKillTime[client] = -1.0;
	}
}

// The death event this is where we decide what sound to play
// It is important to note that we will play no more than one sound per death event
// so we will order them as to choose the most appropriate one
public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:weapon[64];
	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");
	new attackerClient = GetClientOfUserId(attackerId);
	new victimClient = GetClientOfUserId(victimId);
	new bool:headshot;
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	new soundId = -1;

	if(gameType == CSS)
		headshot = GetEventBool(event, "headshot");
	else
		headshot = false;
		
	totalKills++;
	
	if(attackerClient)
		consecutiveKills[attackerClient]++;
	
	if(victimClient)
		consecutiveKills[victimClient] = 0;
	
	if(attackerId == victimId && settingsArray[SELFKILL])
		soundId = SELFKILL;
		
	if(headshot && attackerClient > 0 && attackerClient <= MAXPLAYERS)
		switch(++headShotCount[attackerClient]) {
			case 3:
				if(settingsArray[HEADSHOT3])
					soundId = HEADSHOT3;
			case 5:
				if(settingsArray[HEADSHOT5])
					soundId = HEADSHOT5;
			default:
				if(settingsArray[HEADSHOT])
					soundId = HEADSHOT;
		}
		
	if(totalKills == 1 && settingsArray[FIRSTBLOOD])
		soundId = FIRSTBLOOD;
		
	if(killNumSetting[consecutiveKills[attackerClient]])
			soundId = killNumSetting[consecutiveKills[attackerClient]];

	if(IsGrenade(weapon) && settingsArray[GRENADE])
		soundId = GRENADE;
		
	if(IsKnife(weapon) && settingsArray[KNIFE])
		soundId = KNIFE;
		
	if(attackerClient && (settingsArray[DOUBLECOMBO] || settingsArray[TRIPLECOMBO] || settingsArray[QUADCOMBO] || settingsArray[MONSTERCOMBO]))
	{
		if(lastKillTime[attackerClient] != -1.0) {
			if((GetEngineTime() - lastKillTime[attackerClient]) < 1.5) {
				switch(++lastKillCount[attackerClient])
				{
					case 2:
						soundId = DOUBLECOMBO;
					case 3:
						soundId = TRIPLECOMBO;
					case 4:
						soundId = QUADCOMBO;
					case 5:
						soundId = MONSTERCOMBO;
				}
			}
		} else
			lastKillCount[attackerClient] = 1;
		lastKillTime[attackerClient] = GetEngineTime();
	}
			
	if(attackerClient && victimClient && GetClientTeam(attackerClient) == GetClientTeam(victimClient) && attackerId != victimId && settingsArray[TEAMKILL])
		soundId = TEAMKILL;
	
	// Play the appropriate sound if there was a reason to do so 
	if(soundId != NO_KILLS) {
		PlayQuakeSound(soundId, attackerClient, victimClient);
		PrintQuakeText(soundId, attackerClient, victimClient);
	}
}

//  This selects or disables the quake sounds
public PanelHandlerQuake(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		// The Disable Choice moves around based on if female sounds are enabled
		new disableChoice = numSets + 2;
		
		// Update both the soundPreference array and User Settings KV
		if(param2 == disableChoice)
			soundPreference[param1] = 0;
		else if(param2 == 1)
			textPreference[param1] = Flip(textPreference[param1]);
		else
			soundPreference[param1] = param2 - 1;
		new String:steamId[20];
		GetClientAuthString(param1, steamId, 20);
		KvRewind(kvQUS);
		KvJumpToKey(kvQUS, steamId);
		KvSetNum(kvQUS, "sound preference", soundPreference[param1]);
	}
	else if (action == MenuAction_Cancel)
		PrintToServer("Client %d's Quake Sounds menu was cancelled.  Reason: %d", param1, param2);
}
 
//  This creates the Quake panel
public Action:PanelQuake(client, args)
{
	new Handle:panel = CreatePanel();
	new String:buffer[50];
	
	SetPanelTitle(panel, "Quake Sounds Menu");
	if(textPreference[client] == 0)
		DrawPanelItem(panel, "Enable Text Display");
	else
		DrawPanelItem(panel, "Disable Text Display");
	for(new set = 0; set < numSets; set++) {
		if(soundPreference[client] == set + 1)
			Format(buffer, 50, "%T(Enabled)", setNames[set], client);
		else
			Format(buffer, 50, "%T", setNames[set], client);
		DrawPanelItem(panel, buffer);
	}
	if(soundPreference[client] == 0)
		DrawPanelItem(panel, "No Quake Sounds(Enabled)");
	else
		DrawPanelItem(panel, "No Quake Sounds");
 
	SendPanelToClient(panel, client, PanelHandlerQuake, 20);
 
	CloseHandle(panel);
 
	return Plugin_Handled;
}

// Loads the soundsList array with the quake sounds
public LoadSounds()
{
	new Handle:kvQSL = CreateKeyValues("QuakeSoundsList");
	new String:fileQSL[MAX_FILE_LEN];
	new String:buffer[30];

	BuildPath(Path_SM, fileQSL, MAX_FILE_LEN, "configs/QuakeSoundsList.cfg");
	FileToKeyValues(kvQSL, fileQSL);
	
	if (!KvJumpToKey(kvQSL, "sound sets")) {
		SetFailState("configs/QuakeSoundsList.cfg not found or not correctly structured");
		return;
	}

	// Read the sound set information in
	numSets = 0;
	for(new i = 0; i < MAX_NUM_SETS; i++) {
		Format(buffer, 30, "sound set %i", i + 1);
		KvGetString(kvQSL, buffer, setNames[numSets], 30);
		if(!StrEqual(setNames[numSets], ""))
			numSets++;
	}
	
	for(new soundKey = 0; soundKey < NUM_SOUNDS; soundKey++) {
		KvRewind(kvQSL);
		KvJumpToKey(kvQSL, soundNames[soundKey]);
		for(new set = 0; set < numSets; set++) {
			KvGetString(kvQSL, setNames[set], soundsList[set][soundKey], MAX_FILE_LEN);
			if(StrEqual(soundsList[set][soundKey], ""))
				PrintToServer("Failed to load %s:%s", soundsList[set], soundNames[soundKey]);
		}
		if(soundKey >= KILLS_1 && soundKey <= KILLS_11)
			killNumSetting[KvGetNum(kvQSL, "kills")] = soundKey;
		settingsArray[soundKey] = KvGetNum(kvQSL, "config", 9);
	}
	
	CloseHandle(kvQSL);
}

// The Precaches all the sounds and adds them to the downloads table so that
// clients can automatically download them
// As of version 0.7 we only do this if the sounds are enabled
public PrepareQuakeSounds()
{
	for(new sound=0; sound < NUM_SOUNDS; sound++)
		if((settingsArray[sound] & 1) || (settingsArray[sound] & 2) || (settingsArray[sound] & 4))
			PrepareSound(sound);
}

// This plays the quake sounds based on soundPreference
public PlayQuakeSound(soundKey, attackerClient, victimClient)
{
	new playersConnected = GetMaxClients();
	
	if(settingsArray[soundKey] & 1) {
		for (new i = 1; i < playersConnected; i++)
			if(IsClientInGame(i) && !IsFakeClient(i) && soundPreference[i] && !StrEqual(soundsList[soundPreference[i]-1][soundKey], ""))
				EmitSoundToClient(i, soundsList[soundPreference[i]-1][soundKey]);
		return;
	}
			
	if(soundPreference[attackerClient] && (settingsArray[soundKey] & 2) && attackerClient && !StrEqual(soundsList[soundPreference[attackerClient]-1][soundKey], ""))
		EmitSoundToClient(attackerClient, soundsList[soundPreference[attackerClient]-1][soundKey]);
	
	if(soundPreference[victimClient] && (settingsArray[soundKey] & 4) && victimClient && !StrEqual(soundsList[soundPreference[victimClient]-1][soundKey], ""))
		EmitSoundToClient(victimClient, soundsList[soundPreference[victimClient]-1][soundKey]);
}

// This prints the quake text
public PrintQuakeText(soundKey, attackerClient, victimClient)
{
	new playersConnected = GetMaxClients();
	decl String:attackerName[30];
	decl String:victimName[30];
	
	// Get the names of the victim and the attacker
	if(attackerClient && IsClientInGame(attackerClient))
		GetClientName(attackerClient, attackerName, 30);
	else
		attackerName = "Nobody";
	if(victimClient && IsClientInGame(victimClient))
		GetClientName(victimClient, victimName, 30);
	else
		victimName = "Nobody";
	if(settingsArray[soundKey] & 8) {
		for(new i = 1; i < playersConnected; i++)
			if(IsClientInGame(i) && !IsFakeClient(i) && textPreference[i])
				PrintCenterText(i, "%t", soundNames[soundKey], attackerName, victimName);
		return;
	}
			
	if(textPreference[attackerClient] && (settingsArray[soundKey] & 16) && attackerClient)
		PrintCenterText(attackerClient, "%t", soundNames[soundKey], attackerName, victimName);
	
	if(textPreference[victimClient] && (settingsArray[soundKey] & 32) && victimClient)
		PrintCenterText(victimClient, "%t", soundNames[soundKey], attackerName, victimName);
}

// Play the starting sound
public EventRoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	PlayQuakeSound(ROUND_PLAY, 0, 0);
	PrintQuakeText(ROUND_PLAY, 0, 0);
}

// Initializations to be done at the beginning of the round
public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(gameType != HL2DM)
		NewRoundInitialization();
}

public ResetConsecutiveKills()
{
	for(new i=1; i <= MAXPLAYERS; i++)
		consecutiveKills[i] = 0;
}

public ResetLastKillTime()
{
	for(new i=1; i <= MAXPLAYERS; i++)
		lastKillTime[i] = NO_KILLS;
}

public PrepareSound(sound)
{
	new String:downloadFile[MAX_FILE_LEN];

	for(new set = 0; set < numSets; set++) {
		if(!StrEqual(soundsList[set][sound], "")) {
			PrecacheSound(soundsList[set][sound], true);
			Format(downloadFile, MAX_FILE_LEN, "sound/%s", soundsList[set][sound]);
			AddFileToDownloadsTable(downloadFile);
		}
	}
}

public IsGrenade(String:weapon[])
{
	// Counter Strike:Source grenades
	if(StrEqual(weapon, "hegrenade") || StrEqual(weapon, "smokegrenade") || StrEqual(weapon, "flashbang"))
		return 1;
		
	// Day of Defeat:Source grenades
	if(StrEqual(weapon, "riflegren_ger") || StrEqual(weapon, "riflegren_us") || StrEqual(weapon, "frag_ger") || StrEqual(weapon, "frag_us") || StrEqual(weapon, "smoke_ger") || StrEqual(weapon, "smoke_us"))
		return 1;
		
	// HL2:Deathmatch grenades
	if(StrEqual(weapon, "grenade_frag"))
		return 1;
		
	return 0;
}

public IsKnife(String:weapon[])
{
	// Counter Strike Knife
	if(StrEqual(weapon, "knife"))
		return 1;
		
	// Day of Defeat:Source knives
	if(StrEqual(weapon, "spade") || StrEqual(weapon, "amerknife") || StrEqual(weapon, "punch"))
		return 1;
		
	// HL2:Deathmatch knives
	if(StrEqual(weapon, "stunstick") || StrEqual(weapon, "crowbar"))
		return 1;
		
	return 0;
}

// When a user disconnects we need to update their timestamp in kvC4
public OnClientDisconnect(client)
{
	new String:steamId[20];
	if(client && !IsFakeClient(client)) {
		GetClientAuthString(client, steamId, 20);
		KvRewind(kvQUS);
		if(KvJumpToKey(kvQUS, steamId))
			KvSetNum(kvQUS, "timestamp", GetTime());
	}
}

// Switches a non-zero number to a 0 and a 0 to a 1
public Flip(flipNum)
{
	if(flipNum == 0)
		return 1;
	else
		return 0;
}

// This is called from EventRoundStart or OnMapStart depending on the mod
public NewRoundInitialization()
{
	totalKills = 0;
	for(new i; i <= MAXPLAYERS; i++) {
		headShotCount[i] = 0;
		lastKillCount[i] = -1;
	}
	ResetLastKillTime();
		
	// Save quake user settings to a file
	KvRewind(kvQUS);
	KeyValuesToFile(kvQUS, fileQUS);
}