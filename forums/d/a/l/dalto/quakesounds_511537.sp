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
*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "0.96"
#define MAX_CLIENTS 64
#define NUM_SOUNDS 24
#define MAX_FILE_LEN 64
#define DISABLE_CHOICE 3
#define NO_KILLS -1.0

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
new soundPreference[MAX_CLIENTS + 1];
new consecutiveKills[MAX_CLIENTS + 1];
new Float:lastKillTime[MAX_CLIENTS + 1];
new lastKillCount[MAX_CLIENTS + 1];
new String:soundsList[2][NUM_SOUNDS][MAX_FILE_LEN];
new String:soundNames[NUM_SOUNDS][15];
new totalKills;
new gameType = OTHER;
new headShotCount[MAX_CLIENTS + 1];
new Handle:kvQUS;
new String:fileQUS[MAX_FILE_LEN];
new	Handle:cvarEnabled = INVALID_HANDLE;
new	Handle:cvarWho = INVALID_HANDLE;
new	Handle:cvarMinKills = INVALID_HANDLE;
new	Handle:cvarTK = INVALID_HANDLE;
new	Handle:cvarGrenade = INVALID_HANDLE;
new	Handle:cvarKnife = INVALID_HANDLE;
new	Handle:cvarKills = INVALID_HANDLE;
new	Handle:cvarSK = INVALID_HANDLE;
new	Handle:cvarMK = INVALID_HANDLE;
new	Handle:cvarRP = INVALID_HANDLE;
new	Handle:cvarFB = INVALID_HANDLE;
new	Handle:cvarHS = INVALID_HANDLE;
new Handle:cvarFemale = INVALID_HANDLE;
new Handle:cvarAnnounce = INVALID_HANDLE;

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
		
	// Create the remainder of the CVARs
	CreateConVar("sm_quakesounds_version", PLUGIN_VERSION, "Quake Sounds Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarWho = CreateConVar("sm_quakesounds_who", "1", "Defines who hears Quake sounds");
	cvarMinKills = CreateConVar("sm_quakesounds_min_kills", "4", "The number of kills required to trigger the first kill sound");
	cvarTK = CreateConVar("sm_quakesounds_tk", "1", "Enables the team killer sounds");
	cvarGrenade = CreateConVar("sm_quakesounds_grenade", "1", "Enables the grenade sounds");
	cvarKnife = CreateConVar("sm_quakesounds_knife", "1", "Enables the knife sounds");
	cvarKills = CreateConVar("sm_quakesounds_kills", "1", "Enables the kills sounds");
	cvarSK = CreateConVar("sm_quakesounds_sk", "1", "Enables the self kill sounds");
	cvarMK = CreateConVar("sm_quakesounds_mk", "1", "Enables the multikill sounds");
	cvarRP = CreateConVar("sm_quakesounds_rp", "1", "Enables the round play sounds");
	cvarFB = CreateConVar("sm_quakesounds_fb", "1", "Enables the first blood sounds");
	cvarHS = CreateConVar("sm_quakesounds_hs", "1", "Enables the head shot sounds");
	cvarFemale = CreateConVar("sm_quakesounds_female", "1", "Enables the female sounds");
	cvarAnnounce = CreateConVar("sm_quakesounds_announce", "1", "Announcement preferences");

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
	InitializeSoundNames();
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
				soundPreference[client] = KvGetNum(kvQUS, "sound preference", 1);
			}
			else {
				KvJumpToKey(kvQUS, steamId, true);
				KvSetNum(kvQUS, "sound preference", 1);
				soundPreference[client] = 1;
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
	
	if(attackerId == victimId && GetConVarBool(cvarSK))
		soundId = SELFKILL;
		
	if(headshot && GetConVarBool(cvarHS) && attackerClient > 0 && attackerClient <= MAX_CLIENTS)
		switch(++headShotCount[attackerClient]) {
			case 3:
				soundId = HEADSHOT3;
			case 5:
				soundId = HEADSHOT5;
			default:
				soundId = HEADSHOT;
		}
		
	if(totalKills == 1 && GetConVarBool(cvarFB))
		soundId = FIRSTBLOOD;
		
	if(GetConVarBool(cvarKills)) {
		switch(consecutiveKills[attackerClient] - GetConVarInt(cvarMinKills))
		{
			case 0:
				soundId = KILLS_1;
			case 2:
				soundId = KILLS_2;
			case 4:
				soundId = KILLS_3;
			case 6:
				soundId = KILLS_4;
			case 8:
				soundId = KILLS_5;
			case 10:
				soundId = KILLS_6;
			case 12:
				soundId = KILLS_7;
			case 14:
				soundId = KILLS_8;
			case 16:
				soundId = KILLS_9;
			case 18:
				soundId = KILLS_10;
			case 20:
				soundId = KILLS_11;
		}
	}
	if(IsGrenade(weapon) && GetConVarBool(cvarGrenade))
		soundId = GRENADE;
		
	if(IsKnife(weapon) && GetConVarBool(cvarKnife))
		soundId = KNIFE;
		
	if(attackerClient && GetConVarBool(cvarMK))
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
			
	if(attackerClient && victimClient && GetClientTeam(attackerClient) == GetClientTeam(victimClient) && attackerId != victimId && GetConVarBool(cvarTK))
		soundId = TEAMKILL;
	
	// Play the appropriate sound if there was a reason to do so 
	if(soundId != NO_KILLS)
		PlayQuakeSound(soundId, attackerClient, victimClient, GetConVarInt(cvarWho));
}

//  This selects or disables the quake sounds
public PanelHandlerQuake(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		// The Disable Choice moves around based on if female sounds are enabled
		new disableChoice = DISABLE_CHOICE;
		if(!GetConVarBool(cvarFemale))
			disableChoice = DISABLE_CHOICE - 1;
		
		// Update both the soundPreference array and User Settings KV
		if(param2 == disableChoice)
			soundPreference[param1] = 0;
		else
			soundPreference[param1] = param2;
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
	SetPanelTitle(panel, "Quake Sounds Menu");
	if(soundPreference[client] == 1)
		DrawPanelItem(panel, "Standard Sounds(Enabled)");
	else
		DrawPanelItem(panel, "Standard Sounds");
	if(GetConVarBool(cvarFemale))
		if(soundPreference[client] == 2)
			DrawPanelItem(panel, "Female Sounds(Enabled)");
		else
			DrawPanelItem(panel, "Female Sounds");
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

	BuildPath(Path_SM, fileQSL, MAX_FILE_LEN, "configs/QuakeSoundsList.cfg");
	FileToKeyValues(kvQSL, fileQSL);
	
	if (!KvGotoFirstSubKey(kvQSL))	{
		SetFailState("configs/QuakeSoundsList.cfg not found or not correctly structured");
		return;
	}

	for(new i = 0; i < NUM_SOUNDS; i++) {
		KvRewind(kvQSL);
		KvJumpToKey(kvQSL, soundNames[i]);
		KvGetString(kvQSL, "standard", soundsList[0][i], MAX_FILE_LEN);
		KvGetString(kvQSL, "female", soundsList[1][i], MAX_FILE_LEN);
	}
	
	CloseHandle(kvQSL);
}

// The Precaches all the sounds and adds them to the downloads table so that
// clients can automatically download them
// As of version 0.7 we only do this if the sounds are enabled
public PrepareQuakeSounds()
{
	if(GetConVarBool(cvarHS))
		PrepareSound(HEADSHOT);
	
	if(GetConVarBool(cvarHS))
		PrepareSound(HEADSHOT3);
	
	if(GetConVarBool(cvarHS))
		PrepareSound(HEADSHOT5);
	
	if(GetConVarBool(cvarGrenade))
		PrepareSound(GRENADE);
	
	if(GetConVarBool(cvarRP))
		PrepareSound(ROUND_PLAY);
	
	if(GetConVarBool(cvarSK))
		PrepareSound(SELFKILL);
	
	if(GetConVarBool(cvarKnife))
		PrepareSound(KNIFE);
	
	if(GetConVarBool(cvarKills))
		for(new sound=KILLS_1; sound <= KILLS_11; sound++)
			PrepareSound(sound);
			
	if(GetConVarBool(cvarFB))
		PrepareSound(FIRSTBLOOD);
	
	if(GetConVarBool(cvarMK)) {
		PrepareSound(DOUBLECOMBO);
		PrepareSound(TRIPLECOMBO);
		PrepareSound(QUADCOMBO);
		PrepareSound(MONSTERCOMBO);
	}
	
	if(GetConVarBool(cvarTK))
		PrepareSound(TEAMKILL);
}

// This plays the quake sounds based on playPreference
// 1 = All, 2 = Attacker and Victim, 3 = Attacker Only, 4 = Victim Only
public PlayQuakeSound(soundKey, attackerClient, victimClient, playPreference)
{
	new playersConnected = GetMaxClients();
	
	if(playPreference == 1)
		for (new i = 1; i < playersConnected; i++)
			if(IsClientInGame(i) && !IsFakeClient(i) && soundPreference[i] && !StrEqual(soundsList[soundPreference[i]-1][soundKey], "")) {
				EmitSoundToClient(i, soundsList[soundPreference[i]-1][soundKey]);
			}
			
	if((playPreference == 2 || playPreference == 3) && attackerClient && !StrEqual(soundsList[soundPreference[attackerClient]-1][soundKey], ""))
		EmitSoundToClient(attackerClient, soundsList[soundPreference[attackerClient]-1][soundKey]);
	
	if((playPreference == 2 || playPreference == 4) && victimClient && !StrEqual(soundsList[soundPreference[victimClient]-1][soundKey], ""))
		EmitSoundToClient(victimClient, soundsList[soundPreference[victimClient]-1][soundKey]);
}

// Play the starting sound
public EventRoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(cvarRP))
		PlayQuakeSound(ROUND_PLAY, 0, 0, 1);
}

// Initializations to be done at the beginning of the round
public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	totalKills = 0;
	for(new i; i <= MAX_CLIENTS; i++) {
		headShotCount[i] = 0;
		lastKillCount[i] = -1;
	}
	ResetLastKillTime();
		
	// Save quake user settings to a file
	KvRewind(kvQUS);
	KeyValuesToFile(kvQUS, fileQUS);
}

public ResetConsecutiveKills()
{
	for(new i=1; i <= MAX_CLIENTS; i++)
		consecutiveKills[i] = 0;
}

public ResetLastKillTime()
{
	for(new i=1; i <= MAX_CLIENTS; i++)
		lastKillTime[i] = NO_KILLS;
}

public PrepareSound(sound)
{
	new String:downloadFile[MAX_FILE_LEN];

	if(!StrEqual(soundsList[0][sound], "")) {
		PrecacheSound(soundsList[0][sound], true);
		Format(downloadFile, MAX_FILE_LEN, "sound/%s", soundsList[0][sound]);
		AddFileToDownloadsTable(downloadFile);
		if(GetConVarBool(cvarFemale) && !StrEqual(soundsList[1][sound], "")) {
			PrecacheSound(soundsList[1][sound], true);
			Format(downloadFile, MAX_FILE_LEN, "sound/%s", soundsList[1][sound]);
			AddFileToDownloadsTable(downloadFile);
		}
	}
}

// Initializes the soundNames array.  This information is used to convert indexes
// to the names used in the sound list config file.
public InitializeSoundNames()
{
	soundNames[HEADSHOT] = "headshot";
	soundNames[HEADSHOT3] = "headshot 3";
	soundNames[HEADSHOT5] = "headshot 5";
	soundNames[GRENADE] = "grenade";
	soundNames[SELFKILL] = "selfkill";
	soundNames[ROUND_PLAY] = "round play";
	soundNames[KNIFE] = "knife";
	soundNames[KILLS_1] = "killsound 1";
	soundNames[KILLS_2] = "killsound 2";
	soundNames[KILLS_3] = "killsound 3";
	soundNames[KILLS_4] = "killsound 4";
	soundNames[KILLS_5] = "killsound 5";
	soundNames[KILLS_6] = "killsound 6";
	soundNames[KILLS_7] = "killsound 7";
	soundNames[KILLS_8] = "killsound 8";
	soundNames[KILLS_9] = "killsound 9";
	soundNames[KILLS_10] = "killsound 10";
	soundNames[KILLS_11] = "killsound 11";
	soundNames[FIRSTBLOOD] = "first blood";
	soundNames[DOUBLECOMBO] = "double combo";
	soundNames[TRIPLECOMBO] = "triple combo";
	soundNames[QUADCOMBO] = "quad combo";
	soundNames[MONSTERCOMBO] = "monster combo";
	soundNames[TEAMKILL] = "teamkill";
}

public IsGrenade(String:weapon[])
{
	// Counter Strike:Source grenades
	if(StrEqual(weapon, "hegrenade") || StrEqual(weapon, "smokegrenade") || StrEqual(weapon, "flashbang"))
		return 1;
		
	// Day of Defeat grenades
	if(StrEqual(weapon, "riflegren_ger") || StrEqual(weapon, "riflegren_us") || StrEqual(weapon, "frag_ger") || StrEqual(weapon, "frag_us") || StrEqual(weapon, "smoke_ger") || StrEqual(weapon, "smoke_us"))
		return 1;
		
	return 0;
}

public IsKnife(String:weapon[])
{
	// Counter Strike Knife
	if(StrEqual(weapon, "knife"))
		return 1;
		
	// Day of Defeat knives
	if(StrEqual(weapon, "spade") || StrEqual(weapon, "amerknife") || StrEqual(weapon, "punch"))
		return 1;
		
	return 0;
}