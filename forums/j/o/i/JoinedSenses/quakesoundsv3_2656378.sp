#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_DESCRIPTION	"Plays sounds based on events that happen in game."
#define PLUGIN_VERSION		"4.0.0"

// Sound Sets
#define MAX_NUM_SETS 5
// Max Kill Streak/Combo Config Setting
#define MAX_NUM_KILLS 50

public Plugin myinfo={
	  name = "Quake Sounds v3"
	, author = "Spartan_C001 (Updated by JoinedSenses)"
	, description = PLUGIN_DESCRIPTION
	, version = PLUGIN_VERSION
	, url = "http //steamcommunity.com/id/spartan_c001/"
}

int g_iNumSets = 0;
char g_sSetsName[MAX_NUM_SETS][PLATFORM_MAX_PATH];

// Sound Files
char g_sHeadshotSound[MAX_NUM_SETS][MAX_NUM_KILLS][PLATFORM_MAX_PATH];
char g_sGrenadeSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char g_sSelfkillSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char g_sRoundplaySound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char g_sKnifeSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char g_sKillSound[MAX_NUM_SETS][MAX_NUM_KILLS][PLATFORM_MAX_PATH];
char g_sFirstbloodSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char g_sTeamkillSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];
char g_sComboSound[MAX_NUM_SETS][MAX_NUM_KILLS][PLATFORM_MAX_PATH];
char g_sJoinSound[MAX_NUM_SETS][PLATFORM_MAX_PATH];

// Sound Configs
int g_iHeadshotConfig[MAX_NUM_SETS][MAX_NUM_KILLS];
int g_iGrenadeConfig[MAX_NUM_SETS];
int g_iSelfkillConfig[MAX_NUM_SETS];
int g_iRoundplayConfig[MAX_NUM_SETS];
int g_iKnifeConfig[MAX_NUM_SETS];
int g_iKillConfig[MAX_NUM_SETS][MAX_NUM_KILLS];
int g_iFirstbloodConfig[MAX_NUM_SETS];
int g_iTeamkillConfig[MAX_NUM_SETS];
int g_iComboConfig[MAX_NUM_SETS][MAX_NUM_KILLS];
int g_iJoinConfig[MAX_NUM_SETS];

// Kill Streaks
int g_iTotalKills = 0;
int g_iConsecutiveKills[MAXPLAYERS+1];
float g_fLastKillTime[MAXPLAYERS+1];
int g_iComboScore[MAXPLAYERS+1];
int g_iConsecutiveHeadshots[MAXPLAYERS+1];

// Preferences
Handle g_hCookieText;
int g_iTextPreference[MAXPLAYERS+1];

Handle g_hCookieSound;
int g_iSoundPreference[MAXPLAYERS+1];

// Engine Version for game specific checks / features
EngineVersion g_GameEngine;

// Fix any shiz if plugin was loaded late for some reason
bool g_bLateLoad = false;

ConVar g_cvarAnnounce;
ConVar g_cvarText;
ConVar g_cvarSound;
ConVar g_cvarVolume;
ConVar g_cvarMode;
ConVar g_cvarTime;

// Checks if plugin was late or normal
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_bLateLoad = late;
	g_GameEngine = GetEngineVersion();
	return APLRes_Success;
}

// Stuff to do when plugin is loaded
public void OnPluginStart() {
	CreateConVar("sm_quakesoundsv3_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY|FCVAR_DONTRECORD).SetString(PLUGIN_VERSION);
	g_cvarAnnounce = CreateConVar("sm_quakesoundsv3_announce", "1", "Sets whether to announcement to clients as they join, 0=Disabled, 1=Enabled.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarText = CreateConVar("sm_quakesoundsv3_text", "1", "Default text display setting for new users, 0=Disabled, 1=Enabled.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarSound = CreateConVar("sm_quakesoundsv3_sound", "1", "Default sound set for new users, 0=Disabled, 1=Standard, 2=Female.", FCVAR_NONE, true, 0.0);
	g_cvarVolume = CreateConVar("sm_quakesoundsv3_volume", "1.0", "Sound Volume  should be a number between 0.0 and 1.0.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarMode = CreateConVar("sm_quakesoundsv3_teamkill_mode", "0", "Teamkiller Mode; 0=Normal, 1=Team-Kills count as normal kills.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarTime = CreateConVar("sm_quakesoundsv3_combo_time", "2.0", "Max time in seconds between kills to count as combo; 0.0=Minimum, 2.0=Default", FCVAR_NONE, true, 0.0);

	g_cvarSound.AddChangeHook(cvarChanged_Sound);

	RegConsoleCmd("sm_quake", CMD_ShowQuakePrefsMenu);

	AutoExecConfig(true, "plugin.quakesounds");
	LoadTranslations("plugin.quakesounds");

	HookGameEvents();
	g_hCookieText = RegClientCookie("Quake Text Pref", "Text setting", CookieAccess_Private);
	g_hCookieSound = RegClientCookie("Quake Sound Pref", "Sound setting", CookieAccess_Private);
	SetCookieMenuItem(QuakePrefSelected, 0, "Quake Sound Prefs");

	if (g_bLateLoad) {
		LateLoadedInitialization();
	}
}

public void cvarChanged_Sound(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (!(-1 < StringToInt(newValue) < 3)) {
		convar.SetString(oldValue);
	}
}

// Extra stuff to do if plugin was loaded late
public void LateLoadedInitialization() {
	NewRoundInitialization();
	for (int i = 1; i <= GetMaxHumanPlayers(); i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			g_iSoundPreference[i] = g_cvarSound.IntValue - 1;
			g_iTextPreference[i] = g_cvarText.IntValue;

			if (AreClientCookiesCached(i)) {
				LoadClientCookiesFor(i);
			}
		}
		else {
			g_iSoundPreference[i] = -1;
			g_iTextPreference[i] = 0;
		}
	}
}

// If Quake Prefs Menu was selected from the clientprefs menyu (!settings);
public void QuakePrefSelected(int client, CookieMenuAction action, any info, char[] buffer, int maxlen) {
	if (action == CookieMenuAction_SelectOption) {
		ShowQuakeMenu(client);
	}
}

// Hooks correct game events
public void HookGameEvents() {
	HookEvent("player_death", EventPlayerDeath);

	switch(g_GameEngine) {
		case Engine_CSS, Engine_CSGO: {
			HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
			HookEvent("round_freeze_end", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
		}
		case Engine_DODS: {
			HookEvent("dod_round_start", EventRoundStart, EventHookMode_PostNoCopy);
			HookEvent("dod_round_active", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
		}
		case Engine_TF2: {
			HookEvent("teamplay_round_start", EventRoundStart, EventHookMode_PostNoCopy);
			HookEvent("teamplay_round_active", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
			HookEvent("arena_round_start", EventRoundFreezeEnd, EventHookMode_PostNoCopy);
		}
		case Engine_HL2DM: {
			HookEvent("teamplay_round_start", EventRoundStart, EventHookMode_PostNoCopy);
		}
		default: {
			HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
		}
	}
}

// Loads QuakeSetsList config to check for sound sets
public void LoadSoundSets() {
	char bufferString[PLATFORM_MAX_PATH];
	KeyValues SoundSetsKV = new KeyValues("SetsList");
	BuildPath(Path_SM, bufferString, PLATFORM_MAX_PATH, "configs/QuakeSetsList.cfg");

	if (!SoundSetsKV.ImportFromFile(bufferString)) {
		delete SoundSetsKV;
		SetFailState("configs/QuakeSetsList.cfg not found");
	}

	if (!SoundSetsKV.JumpToKey("sound sets")) {
		delete SoundSetsKV;
		SetFailState("configs/QuakeSetsList.cfg not correctly structured");
	}

	g_iNumSets = 0;
	for (int i = 0; i < MAX_NUM_SETS; i++) {
		Format(bufferString, PLATFORM_MAX_PATH, "sound set %i", (i+1));
		SoundSetsKV.GetString(bufferString, g_sSetsName[i], PLATFORM_MAX_PATH);

		if (g_sSetsName[i][0] != '\0') {
			BuildPath(Path_SM, bufferString, PLATFORM_MAX_PATH, "configs/quake/%s.cfg", g_sSetsName[i]);
			PrintToServer("[SM] Quake Sounds v3  Loading sound set config '%s'.", bufferString);
			LoadSet(bufferString, i);
			g_iNumSets++;
		}
	}

	delete SoundSetsKV;
}

// Loads sound file paths and configs for each sound set
public void LoadSet(char[] setFile, int setNum) {
	char bufferString[PLATFORM_MAX_PATH];
	KeyValues SetFileKV = new KeyValues("SoundSet");

	if (!SetFileKV.ImportFromFile(setFile)) {
		PrintToServer("[SM] Quake Sounds v3  Cannot parse '%s', file not found or incorrectly structured!", setFile);
		delete SetFileKV;
		return;
	}

// =============
	if (SetFileKV.JumpToKey("headshot")) {
		if (SetFileKV.GotoFirstSubKey()) {
			do {
				SetFileKV.GetSectionName(bufferString, PLATFORM_MAX_PATH);
				int killNum = StringToInt(bufferString);

				if (killNum >= 0) {
					SetFileKV.GetString("sound", g_sHeadshotSound[setNum][killNum], PLATFORM_MAX_PATH);
					g_iHeadshotConfig[setNum][killNum] = SetFileKV.GetNum("config", 9);
					Format(bufferString, PLATFORM_MAX_PATH, "sound/%s", g_sHeadshotSound[setNum][killNum]);

					if (FileExists(bufferString, true)) {
						PrecacheSoundCustom(g_sHeadshotSound[setNum][killNum], PLATFORM_MAX_PATH);
						AddFileToDownloadsTable(bufferString);
					}
					else {
						g_iHeadshotConfig[setNum][killNum] = 0;
						PrintToServer("[SM] Quake Sounds v3  File specified in 'headshot %i' does not exist in '%s', ignoring.", killNum, setFile);
					}
				}
			} while (SetFileKV.GotoNextKey());

			SetFileKV.GoBack();
		}
		else {
			PrintToServer("[SM] Quake Sounds v3  'headshot' section not configured correctly in %s.", setFile);
		}
	}
	else {
		PrintToServer("[SM] Quake Sounds v3  'headshot' section missing in %s.", setFile);
	}

	SetFileKV.Rewind();

// =============
	if (SetFileKV.JumpToKey("grenade")) {
		if (SetFileKV.GotoFirstSubKey()) {
			PrintToServer("[SM] Quake Sounds v3  'grenade' section not configured correctly in %s.", setFile);
			SetFileKV.GoBack();
		}
		else {
			SetFileKV.GetString("sound", g_sGrenadeSound[setNum], PLATFORM_MAX_PATH);
			g_iGrenadeConfig[setNum] = SetFileKV.GetNum("config", 9);
			Format(bufferString, PLATFORM_MAX_PATH, "sound/%s", g_sGrenadeSound[setNum]);

			if (FileExists(bufferString, true)) {
				PrecacheSoundCustom(g_sGrenadeSound[setNum], PLATFORM_MAX_PATH);
				AddFileToDownloadsTable(bufferString);
			}
			else {
				g_iGrenadeConfig[setNum] = 0;
				PrintToServer("[SM] Quake Sounds v3  File specified in 'grenade' does not exist in '%s', ignoring.", setFile);
			}
		}
	}
	else {
		PrintToServer("[SM] Quake Sounds v3  'grenade' section missing in %s.", setFile);
	}

	SetFileKV.Rewind();

// =============
	if (SetFileKV.JumpToKey("selfkill")) {
		if (SetFileKV.GotoFirstSubKey()) {
			PrintToServer("[SM] Quake Sounds v3  'selfkill' section not configured correctly in %s.", setFile);
			SetFileKV.GoBack();
		}
		else {
			SetFileKV.GetString("sound", g_sSelfkillSound[setNum], PLATFORM_MAX_PATH);
			g_iSelfkillConfig[setNum] = SetFileKV.GetNum("config", 9);
			Format(bufferString, PLATFORM_MAX_PATH, "sound/%s", g_sSelfkillSound[setNum]);

			if (FileExists(bufferString, true)) {
				PrecacheSoundCustom(g_sSelfkillSound[setNum], PLATFORM_MAX_PATH);
				AddFileToDownloadsTable(bufferString);
			}
			else {
				g_iSelfkillConfig[setNum] = 0;
				PrintToServer("[SM] Quake Sounds v3  File specified in 'selfkill' does not exist in '%s', ignoring.", setFile);
			}
		}
	}
	else {
		PrintToServer("[SM] Quake Sounds v3  'selfkill' section missing in %s.", setFile);
	}

	SetFileKV.Rewind();

// =============
	if (SetFileKV.JumpToKey("round play")) {
		if (SetFileKV.GotoFirstSubKey()) {
			PrintToServer("[SM] Quake Sounds v3  'round play' section not configured correctly in %s.", setFile);
			SetFileKV.GoBack();
		}
		else {
			SetFileKV.GetString("sound", g_sRoundplaySound[setNum], PLATFORM_MAX_PATH);
			g_iRoundplayConfig[setNum] = SetFileKV.GetNum("config", 9);
			Format(bufferString, PLATFORM_MAX_PATH, "sound/%s", g_sRoundplaySound[setNum]);

			if (FileExists(bufferString, true)) {
				PrecacheSoundCustom(g_sRoundplaySound[setNum], PLATFORM_MAX_PATH);
				AddFileToDownloadsTable(bufferString);
			}
			else {
				g_iRoundplayConfig[setNum] = 0;
				PrintToServer("[SM] Quake Sounds v3  File specified in 'round play' does not exist in '%s', ignoring.", setFile);
			}
		}
	}
	else {
		PrintToServer("[SM] Quake Sounds v3  'round play' section missing in %s.", setFile);
	}

	SetFileKV.Rewind();

// =============
	if (SetFileKV.JumpToKey("knife")) {
		if (SetFileKV.GotoFirstSubKey()) {
			PrintToServer("[SM] Quake Sounds v3  'knife' section not configured correctly in %s.", setFile);
			SetFileKV.GoBack();
		}
		else {
			SetFileKV.GetString("sound", g_sKnifeSound[setNum], PLATFORM_MAX_PATH);
			g_iKnifeConfig[setNum] = SetFileKV.GetNum("config", 9);
			Format(bufferString, PLATFORM_MAX_PATH, "sound/%s", g_sKnifeSound[setNum]);

			if (FileExists(bufferString, true)) {
				PrecacheSoundCustom(g_sKnifeSound[setNum], PLATFORM_MAX_PATH);
				AddFileToDownloadsTable(bufferString);
			}
			else {
				g_iKnifeConfig[setNum] = 0;
				PrintToServer("[SM] Quake Sounds v3  File specified in 'knife' does not exist in '%s', ignoring.", setFile);
			}
		}
	}
	else {
		PrintToServer("[SM] Quake Sounds v3  'knife' section missing in %s.", setFile);
	}

	SetFileKV.Rewind();

// =============
	if (SetFileKV.JumpToKey("killsound")) {
		if (SetFileKV.GotoFirstSubKey()) {
			do {
				SetFileKV.GetSectionName(bufferString, PLATFORM_MAX_PATH);
				int killNum = StringToInt(bufferString);

				if (killNum >= 0) {
					SetFileKV.GetString("sound", g_sKillSound[setNum][killNum], PLATFORM_MAX_PATH);
					g_iKillConfig[setNum][killNum] = SetFileKV.GetNum("config", 9);
					Format(bufferString, PLATFORM_MAX_PATH, "sound/%s", g_sKillSound[setNum][killNum]);

					if (FileExists(bufferString, true)) {
						PrecacheSoundCustom(g_sKillSound[setNum][killNum], PLATFORM_MAX_PATH);
						AddFileToDownloadsTable(bufferString);
					}
					else {
						g_iKillConfig[setNum][killNum] = 0;
						PrintToServer("[SM] Quake Sounds v3  File specified in 'killsound %i' does not exist in '%s', ignoring.", killNum, setFile);
					}
				}
			} while (SetFileKV.GotoNextKey());

			SetFileKV.GoBack();
		}
		else {
			PrintToServer("[SM] Quake Sounds v3  'killsound' section not configured correctly in %s.", setFile);
		}
	}
	else {
		PrintToServer("[SM] Quake Sounds v3  'killsound' section missing in %s.", setFile);
	}

	SetFileKV.Rewind();

// =============
	if (SetFileKV.JumpToKey("first blood")) {
		if (SetFileKV.GotoFirstSubKey()) {
			PrintToServer("[SM] Quake Sounds v3  'first blood' section not configured correctly in %s.", setFile);
			SetFileKV.GoBack();
		}
		else {
			SetFileKV.GetString("sound", g_sFirstbloodSound[setNum], PLATFORM_MAX_PATH);
			g_iFirstbloodConfig[setNum] = SetFileKV.GetNum("config", 9);
			Format(bufferString, PLATFORM_MAX_PATH, "sound/%s", g_sFirstbloodSound[setNum]);

			if (FileExists(bufferString, true)) {
				PrecacheSoundCustom(g_sFirstbloodSound[setNum], PLATFORM_MAX_PATH);
				AddFileToDownloadsTable(bufferString);
			}
			else {
				g_iFirstbloodConfig[setNum] = 0;
				PrintToServer("[SM] Quake Sounds v3  File specified in 'first blood' does not exist in '%s', ignoring.", setFile);
			}
		}
	}
	else {
		PrintToServer("[SM] Quake Sounds v3  'first blood' section missing in %s.", setFile);
	}

	SetFileKV.Rewind();

// =============
	if (SetFileKV.JumpToKey("teamkill")) {
		if (SetFileKV.GotoFirstSubKey()) {
			PrintToServer("[SM] Quake Sounds v3  'teamkill' section not configured correctly in %s.", setFile);
			SetFileKV.GoBack();
		}
		else {
			SetFileKV.GetString("sound", g_sTeamkillSound[setNum], PLATFORM_MAX_PATH);
			g_iTeamkillConfig[setNum] = SetFileKV.GetNum("config", 9);
			Format(bufferString, PLATFORM_MAX_PATH, "sound/%s", g_sTeamkillSound[setNum]);

			if (FileExists(bufferString, true)) {
				PrecacheSoundCustom(g_sTeamkillSound[setNum], PLATFORM_MAX_PATH);
				AddFileToDownloadsTable(bufferString);
			}
			else {
				g_iTeamkillConfig[setNum] = 0;
				PrintToServer("[SM] Quake Sounds v3  File specified in 'teamkill' does not exist in '%s', ignoring.", setFile);
			}
		}
	}
	else {
		PrintToServer("[SM] Quake Sounds v3  'teamkill' section missing in %s.", setFile);
	}

	SetFileKV.Rewind();

// =============
	if (SetFileKV.JumpToKey("combo")) {
		if (SetFileKV.GotoFirstSubKey()) {
			do {
				SetFileKV.GetSectionName(bufferString, PLATFORM_MAX_PATH);
				int killNum = StringToInt(bufferString);

				if (killNum >= 0) {
					SetFileKV.GetString("sound", g_sComboSound[setNum][killNum], PLATFORM_MAX_PATH);
					g_iComboConfig[setNum][killNum] = SetFileKV.GetNum("config", 9);
					Format(bufferString, PLATFORM_MAX_PATH, "sound/%s", g_sComboSound[setNum][killNum]);

					if (FileExists(bufferString, true)) {
						PrecacheSoundCustom(g_sComboSound[setNum][killNum], PLATFORM_MAX_PATH);
						AddFileToDownloadsTable(bufferString);
					}
					else {
						g_iComboConfig[setNum][killNum] = 0;
						PrintToServer("[SM] Quake Sounds v3  File specified in 'combo %i' does not exist in '%s', ignoring.", killNum, setFile);
					}
				}
			} while (SetFileKV.GotoNextKey());

			SetFileKV.GoBack();
		}
		else {
			PrintToServer("[SM] Quake Sounds v3  'combo' section not configured correctly in %s.", setFile);
		}
	}
	else {
		PrintToServer("[SM] Quake Sounds v3  'combo' section missing in %s.", setFile);
	}

	SetFileKV.Rewind();

// =============
	if (SetFileKV.JumpToKey("join server")) {
		if (SetFileKV.GotoFirstSubKey()) {
			PrintToServer("[SM] Quake Sounds v3  'join server' section not configured correctly in %s.", setFile);
			SetFileKV.GoBack();
		}
		else {
			SetFileKV.GetString("sound", g_sJoinSound[setNum], PLATFORM_MAX_PATH);
			g_iJoinConfig[setNum] = SetFileKV.GetNum("config", 9);
			Format(bufferString, PLATFORM_MAX_PATH, "sound/%s", g_sJoinSound[setNum]);

			if (FileExists(bufferString, true)) {
				PrecacheSoundCustom(g_sJoinSound[setNum], PLATFORM_MAX_PATH);
				AddFileToDownloadsTable(bufferString);
			}
			else {
				g_iJoinConfig[setNum] = 0;
				PrintToServer("[SM] Quake Sounds v3  File specified in 'join server' does not exist in '%s', ignoring.", setFile);
			}
		}
	}
	else {
		PrintToServer("[SM] Quake Sounds v3  'join server' section missing in %s.", setFile);
	}

	delete SetFileKV;
}

// Things to do when map starts
public void OnMapStart() {
	LoadSoundSets();

	if (g_GameEngine == Engine_HL2DM) {
		NewRoundInitialization();
	}
}

// Things to do when the round starts
public void EventRoundStart(Event event, const char[] name, bool dontBroadcast) {
	if (g_GameEngine != Engine_HL2DM) {
		NewRoundInitialization();
	}
}

// Resets combo/headshot streaks (not kill streaks though) on new round
public void NewRoundInitialization() {
	g_iTotalKills = 0;

	for (int i = 1; i <= GetMaxHumanPlayers(); i++) {
		g_iConsecutiveHeadshots[i] = 0;
		g_fLastKillTime[i] = -1.0;
	}
}

// Plays round play sound depending on each players config and the text display
public void EventRoundFreezeEnd(Event event, const char[] name, bool dontBroadcast) {
	for (int i = 1; i <= GetMaxHumanPlayers(); i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && g_iSoundPreference[i] >= 0) {
			if (g_sRoundplaySound[g_iSoundPreference[i]][0] != '\0' && (g_iRoundplayConfig[g_iSoundPreference[i]] & 1) || g_iRoundplayConfig[g_iSoundPreference[i]] & (2|4)) {
				EmitSoundToClient(i, g_sRoundplaySound[g_iSoundPreference[i]], .volume = g_cvarVolume.FloatValue);
			}
			if (g_iTextPreference[i] && (g_iRoundplayConfig[g_iSoundPreference[i]] & 8) || g_iRoundplayConfig[g_iSoundPreference[i]] & (16|32)) {
				PrintCenterText(i, "%t", "round play");
			}
		}
	}
}

// Reset clients preferences and reload them when they join. Changed to PostAdminCheck for CS GO compatibility.
public void OnClientPostAdminCheck(int client) {
	g_iConsecutiveKills[client] = 0;
	g_fLastKillTime[client] = -1.0;
	g_iConsecutiveHeadshots[client] = 0;
	if (!IsFakeClient(client)) {
		g_iSoundPreference[client] = g_cvarSound.IntValue - 1;
		g_iTextPreference[client] = g_cvarText.IntValue;

		if (AreClientCookiesCached(client)) {
			LoadClientCookiesFor(client);
		}

		if (g_cvarAnnounce.BoolValue) {
			CreateTimer(30.0, TimerAnnounce, client);
		}

		if (g_iSoundPreference[client] >= 0) {
			if (g_sJoinSound[g_iSoundPreference[client]][0] != '\0' && (g_iJoinConfig[g_iSoundPreference[client]] & 1) || g_iJoinConfig[g_iSoundPreference[client]] & (2|4)) {
				EmitSoundToClient(client, g_sJoinSound[g_iSoundPreference[client]], .volume = g_cvarVolume.FloatValue);
			}
		}
	}
	else {
		g_iSoundPreference[client] = -1;
		g_iTextPreference[client] = 0;
	}
}

// Announce the settings option after time set when timer created (Default 30 secs);
public Action TimerAnnounce(Handle timer, any client) {
	if (IsClientInGame(client)) {
		PrintToChat(client, "%t", "announce message");
	}
}

// When clients cookies have been loaded, check them for prefs
public void OnClientCookiesCached(int client) {
	if (IsClientInGame(client) && !IsFakeClient(client)) {
		LoadClientCookiesFor(client);
	}
}

// Retrieving clients cookie settings
public void LoadClientCookiesFor(int client) {
	char buffer[5];
	GetClientCookie(client, g_hCookieText, buffer, 5);
	if (buffer[0] != '\0') {
		g_iTextPreference[client] = StringToInt(buffer);
	}

	GetClientCookie(client, g_hCookieSound, buffer, 5);
	if (buffer[0] != '\0') {
		int value = StringToInt(buffer);
		if (value > 2) {
			FormatEx(buffer, sizeof(buffer), "%i", g_iSoundPreference[client]);
			SetClientCookie(client, g_hCookieSound, buffer);
		}
		g_iSoundPreference[client] = StringToInt(buffer);
	}
}

// Important bit - does all kill/combo/custom kill sounds and things!
public void EventPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int attackerClient = GetClientOfUserId(event.GetInt("attacker"));
	char attackerName[MAX_NAME_LENGTH];
	GetClientName(attackerClient, attackerName, MAX_NAME_LENGTH);
	int victimClient = GetClientOfUserId(event.GetInt("userid"));
	char victimName[MAX_NAME_LENGTH];
	GetClientName(victimClient, victimName, MAX_NAME_LENGTH);
	char bufferString[256];
	if (victimClient < 1 || victimClient > GetMaxHumanPlayers()) {
		return;
	}
	else {
		if (attackerClient == victimClient || attackerClient == 0) {
			g_iConsecutiveKills[attackerClient] = 0;
			for (int i = 1; i <= GetMaxHumanPlayers(); i++) {
				if (IsClientInGame(i) && !IsFakeClient(i) && g_iSoundPreference[i] > -1) {
					if (g_sSelfkillSound[g_iSoundPreference[i]][0] != '\0') {
						int config = g_iSelfkillConfig[g_iSoundPreference[i]];

						if (config & 1) {
							EmitSoundToClient(i, g_sSelfkillSound[g_iSoundPreference[i]], .volume = g_cvarVolume.FloatValue);
						}
						else if ((config & 2) && attackerClient == i) {
							EmitSoundToClient(i, g_sSelfkillSound[g_iSoundPreference[i]], .volume = g_cvarVolume.FloatValue);
						}
						else if ((config & 4) && victimClient == i) {
							EmitSoundToClient(i, g_sSelfkillSound[g_iSoundPreference[i]], .volume = g_cvarVolume.FloatValue);
						}
					}

					if (g_iTextPreference[i]) {
						int config = g_iSelfkillConfig[g_iSoundPreference[i]];

						if ((config & 8)) {
							PrintCenterText(i, "%t", "selfkill", victimName);
						}
						else if ((config & 16) && attackerClient == i) {
							PrintCenterText(i, "%t", "selfkill", victimName);
						}
						else if ((config & 32) && victimClient == i) {
							PrintCenterText(i, "%t", "selfkill", victimName);
						}
					}
				}
			}
		}
		else if (GetClientTeam(attackerClient) == GetClientTeam(victimClient) && !g_cvarMode.BoolValue) {
			g_iConsecutiveKills[attackerClient] = 0;
			for (int i = 1; i <= GetMaxHumanPlayers(); i++) {
				if (IsClientInGame(i) && !IsFakeClient(i) && g_iSoundPreference[i] > -1) {
					if (g_sTeamkillSound[g_iSoundPreference[i]][0] != '\0') {
						int config = g_iTeamkillConfig[g_iSoundPreference[i]];

						if (config & 1) {
							EmitSoundToClient(i, g_sTeamkillSound[g_iSoundPreference[i]], .volume = g_cvarVolume.FloatValue);
						}
						else if ((config & 2) && attackerClient == i) {
							EmitSoundToClient(i, g_sTeamkillSound[g_iSoundPreference[i]], .volume = g_cvarVolume.FloatValue);
						}
						else if ((config & 4) && victimClient == i) {
							EmitSoundToClient(i, g_sTeamkillSound[g_iSoundPreference[i]], .volume = g_cvarVolume.FloatValue);
						}
					}
					if (g_iTextPreference[i]) {
						int config = g_iTeamkillConfig[g_iSoundPreference[i]];

						if (config & 8) {
							PrintCenterText(i, "%t", "teamkill", attackerName, victimName);
						}
						else if ((config & 16) && attackerClient == i) {
							PrintCenterText(i, "%t", "teamkill", attackerName, victimName);
						}
						else if ((config & 32) && victimClient == i) {
							PrintCenterText(i, "%t", "teamkill", attackerName, victimName);
						}
					}
				}
			}
		}
		else {
			g_iTotalKills++;
			g_iConsecutiveKills[attackerClient]++;
			bool firstblood;
			bool headshot;
			bool knife;
			bool grenade;
			bool combo;
			int customkill;
			char[] weapon = new char[GetMaxHumanPlayers()];
			event.GetString("weapon", weapon, GetMaxHumanPlayers());

			if (g_GameEngine == Engine_CSS || g_GameEngine == Engine_CSGO) {
				headshot = event.GetBool("headshot");
			}
			else if (g_GameEngine == Engine_TF2) {
				customkill = event.GetInt("customkill");
				if (customkill == 1) {
					headshot = true;
				}
			}
			else {
				headshot = false;
			}

			if (headshot) {
				g_iConsecutiveHeadshots[attackerClient]++;
			}

			float tempLastKillTime = g_fLastKillTime[attackerClient];
			g_fLastKillTime[attackerClient] = GetEngineTime();
			if (tempLastKillTime == -1.0 || (g_fLastKillTime[attackerClient] - tempLastKillTime) > g_cvarTime.FloatValue) {
				g_iComboScore[attackerClient] = 1;
				combo = false;
			}
			else {
				g_iComboScore[attackerClient]++;
				combo = true;
			}
			if (g_iTotalKills == 1) {
				firstblood = true;
			}
			if (g_GameEngine == Engine_TF2) {
				if (customkill == 2) {
					knife = true;
				}
			}
			else if (g_GameEngine == Engine_CSS) {
				if (StrEqual(weapon, "hegrenade") || StrEqual(weapon, "smokegrenade") || StrEqual(weapon, "flashbang")) {
					grenade = true;
				}
				else if (StrEqual(weapon, "knife")) {
					knife = true;
				}
			}
			else if (g_GameEngine == Engine_CSGO) {
				if (StrEqual(weapon, "inferno") || StrEqual(weapon, "hegrenade") || StrEqual(weapon, "flashbang") || StrEqual(weapon, "decoy") || StrEqual(weapon, "smokegrenade")) {
					grenade = true;
				}
				else if (StrEqual(weapon, "knife_default_ct") || StrEqual(weapon, "knife_default_t") || StrEqual(weapon, "knifegg") || StrEqual(weapon, "knife_flip") || StrEqual(weapon, "knife_gut") || StrEqual(weapon, "knife_karambit") || StrEqual(weapon, "bayonet") || StrEqual(weapon, "knife_m9_bayonet")) {
					knife = true;
				}
			}
			else if (g_GameEngine == Engine_DODS) {
				if (StrEqual(weapon, "riflegren_ger") || StrEqual(weapon, "riflegren_us") || StrEqual(weapon, "frag_ger") || StrEqual(weapon, "frag_us") || StrEqual(weapon, "smoke_ger") || StrEqual(weapon, "smoke_us")) {
					grenade = true;
				}
				else if ((StrEqual(weapon, "spade") || StrEqual(weapon, "amerknife") || StrEqual(weapon, "punch"))) {
					knife = true;
				}
			}
			else if (g_GameEngine == Engine_HL2DM) {
				if (StrEqual(weapon, "grenade_frag")) {
					grenade = true;
				}
				else if ((StrEqual(weapon, "stunstick") || StrEqual(weapon, "crowbar"))) {
					knife = true;
				}
			}
			for (int i = 1; i <= GetMaxHumanPlayers(); i++) {
				if (IsClientInGame(i) && !IsFakeClient(i) && g_iSoundPreference[i] >= 0) {
					if (firstblood && g_iFirstbloodConfig[g_iSoundPreference[i]] > 0) {
						if (g_sFirstbloodSound[g_iSoundPreference[i]][0] != '\0') {
							int config = g_iFirstbloodConfig[g_iSoundPreference[i]];

							if (config & 1) {
								EmitSoundToClient(i, g_sFirstbloodSound[g_iSoundPreference[i]], .volume = g_cvarVolume.FloatValue);
							}
							else if ((config & 2) && attackerClient == i) {
								EmitSoundToClient(i, g_sFirstbloodSound[g_iSoundPreference[i]], .volume = g_cvarVolume.FloatValue);
							}
							else if ((config & 4) && victimClient == i) {
								EmitSoundToClient(i, g_sFirstbloodSound[g_iSoundPreference[i]], .volume = g_cvarVolume.FloatValue);
							}
						}
						if (g_iTextPreference[i]) {
							int config = g_iFirstbloodConfig[g_iSoundPreference[i]];

							if (config & 8) {
								PrintCenterText(i, "%t", "first blood", attackerName);
							}
							else if ((config & 16) && attackerClient == i) {
								PrintCenterText(i, "%t", "first blood", attackerName);
							}
							else if ((config & 32) && victimClient == i) {
								PrintCenterText(i, "%t", "first blood", attackerName);
							}
						}
					}
					else if (headshot && g_iHeadshotConfig[g_iSoundPreference[i]][0] > 0) {
						if (g_sHeadshotSound[g_iSoundPreference[i]][0][0] != '\0') {
							int config = g_iHeadshotConfig[g_iSoundPreference[i]][0];

							if (config & 1) {
								EmitSoundToClient(i, g_sHeadshotSound[g_iSoundPreference[i]][0], .volume = g_cvarVolume.FloatValue);
							}
							else if ((config & 2) && attackerClient == i) {
								EmitSoundToClient(i, g_sHeadshotSound[g_iSoundPreference[i]][0], .volume = g_cvarVolume.FloatValue);
							}
							else if ((config & 4) && victimClient == i) {
								EmitSoundToClient(i, g_sHeadshotSound[g_iSoundPreference[i]][0], .volume = g_cvarVolume.FloatValue);
							}
						}
						if (g_iTextPreference[i]) {
							int config = g_iHeadshotConfig[g_iSoundPreference[i]][0];
							if (config & 8) {
								PrintCenterText(i, "%t", "headshot", attackerName);
							}
							else if ((config & 16) && attackerClient == i) {
								PrintCenterText(i, "%t", "headshot", attackerName);
							}
							else if ((config & 32) && victimClient == i) {
								PrintCenterText(i, "%t", "headshot", attackerName);
							}
						}
					}
					else if (headshot && g_iConsecutiveHeadshots[attackerClient] < MAX_NUM_KILLS && g_iHeadshotConfig[g_iSoundPreference[i]][g_iConsecutiveHeadshots[attackerClient]] > 0) {
						if (g_sHeadshotSound[g_iSoundPreference[i]][g_iConsecutiveHeadshots[attackerClient]][0] != '\0') {
							int config = g_iHeadshotConfig[g_iSoundPreference[i]][g_iConsecutiveHeadshots[attackerClient]];

							if (config & 1) {
								EmitSoundToClient(i, g_sHeadshotSound[g_iSoundPreference[i]][g_iConsecutiveHeadshots[attackerClient]], .volume = g_cvarVolume.FloatValue);
							}
							else if ((config & 2) && attackerClient == i) {
								EmitSoundToClient(i, g_sHeadshotSound[g_iSoundPreference[i]][g_iConsecutiveHeadshots[attackerClient]], .volume = g_cvarVolume.FloatValue);
							}
							else if ((config & 4) && victimClient == i) {
								EmitSoundToClient(i, g_sHeadshotSound[g_iSoundPreference[i]][g_iConsecutiveHeadshots[attackerClient]], .volume = g_cvarVolume.FloatValue);
							}
						}

						if (g_iTextPreference[i] && g_iConsecutiveHeadshots[attackerClient] < MAX_NUM_KILLS) {
							int config = g_iHeadshotConfig[g_iSoundPreference[i]][g_iConsecutiveHeadshots[attackerClient]];

							if (config & 8) {
								Format(bufferString, 256, "headshot %i", g_iConsecutiveHeadshots[attackerClient]);
								PrintCenterText(i, "%t", bufferString, attackerName);
							}
							else if ((config & 16) && attackerClient == i) {
								Format(bufferString, 256, "headshot %i", g_iConsecutiveHeadshots[attackerClient]);
								PrintCenterText(i, "%t", bufferString, attackerName);
							}
							else if ((config & 32) && victimClient == i) {
								Format(bufferString, 256, "headshot %i", g_iConsecutiveHeadshots[attackerClient]);
								PrintCenterText(i, "%t", bufferString, attackerName);
							}
						}
					}
					else if (knife && g_iKnifeConfig[g_iSoundPreference[i]] > 0) {
						if (g_sKnifeSound[g_iSoundPreference[i]][0] != '\0') {
							int config = g_iKnifeConfig[g_iSoundPreference[i]];

							if (config & 1) {
								EmitSoundToClient(i, g_sKnifeSound[g_iSoundPreference[i]], .volume = g_cvarVolume.FloatValue);
							}
							else if ((config & 2) && attackerClient == i) {
								EmitSoundToClient(i, g_sKnifeSound[g_iSoundPreference[i]], .volume = g_cvarVolume.FloatValue);
							}
							else if ((config & 4) && victimClient == i) {
								EmitSoundToClient(i, g_sKnifeSound[g_iSoundPreference[i]], .volume = g_cvarVolume.FloatValue);
							}
						}

						if (g_iTextPreference[i]) {
							int config = g_iKnifeConfig[g_iSoundPreference[i]];

							if (config & 8) {
								PrintCenterText(i, "%t", "knife", attackerName, victimName);
							}
							else if ((config & 16) && attackerClient == i) {
								PrintCenterText(i, "%t", "knife", attackerName, victimName);
							}
							else if ((config & 32) && victimClient == i) {
								PrintCenterText(i, "%t", "knife", attackerName, victimName);
							}
						}
					}
					else if (grenade && g_iGrenadeConfig[g_iSoundPreference[i]] > 0) {
						if (g_sGrenadeSound[g_iSoundPreference[i]][0] != '\0') {
							int config = g_iGrenadeConfig[g_iSoundPreference[i]];

							if (config & 1) {
								EmitSoundToClient(i, g_sGrenadeSound[g_iSoundPreference[i]], .volume = g_cvarVolume.FloatValue);
							}
							else if ((config & 2) && attackerClient == i) {
								EmitSoundToClient(i, g_sGrenadeSound[g_iSoundPreference[i]], .volume = g_cvarVolume.FloatValue);
							}
							else if ((config & 4) && victimClient == i) {
								EmitSoundToClient(i, g_sGrenadeSound[g_iSoundPreference[i]], .volume = g_cvarVolume.FloatValue);
							}
						}
						if (g_iTextPreference[i]) {
							int config = g_iGrenadeConfig[g_iSoundPreference[i]];

							if (config & 8) {
								PrintCenterText(i, "%t", "grenade", attackerName, victimName);
							}
							else if ((config & 16) && attackerClient == i) {
								PrintCenterText(i, "%t", "grenade", attackerName, victimName);
							}
							else if ((config & 32) && victimClient == i) {
								PrintCenterText(i, "%t", "grenade", attackerName, victimName);
							}
						}
					}
					else if (combo && g_iComboScore[attackerClient] < MAX_NUM_KILLS && g_iComboConfig[g_iSoundPreference[i]][g_iComboScore[attackerClient]] > 0) {
						if (g_sComboSound[g_iSoundPreference[i]][g_iComboScore[attackerClient]][0] != '\0') {
							int config = g_iComboConfig[g_iSoundPreference[i]][g_iComboScore[attackerClient]];

							if (config & 1) {
								EmitSoundToClient(i, g_sComboSound[g_iSoundPreference[i]][g_iComboScore[attackerClient]], .volume = g_cvarVolume.FloatValue);
							}
							else if ((config & 2) && attackerClient == i) {
								EmitSoundToClient(i, g_sComboSound[g_iSoundPreference[i]][g_iComboScore[attackerClient]], .volume = g_cvarVolume.FloatValue);
							}
							else if ((config & 4) && victimClient == i) {
								EmitSoundToClient(i, g_sComboSound[g_iSoundPreference[i]][g_iComboScore[attackerClient]], .volume = g_cvarVolume.FloatValue);
							}
						}
						if (g_iTextPreference[i] && g_iComboScore[attackerClient] < MAX_NUM_KILLS) {
							int config = g_iComboConfig[g_iSoundPreference[i]][g_iComboScore[attackerClient]];

							if (config & 8) {
								Format(bufferString, 256, "combo %i", g_iComboScore[attackerClient]);
								PrintCenterText(i, "%t", bufferString, attackerName);
							}
							else if ((config & 16) && attackerClient == i) {
								Format(bufferString, 256, "combo %i", g_iComboScore[attackerClient]);
								PrintCenterText(i, "%t", bufferString, attackerName);
							}
							else if ((config & 32) && victimClient == i) {
								Format(bufferString, 256, "combo %i", g_iComboScore[attackerClient]);
								PrintCenterText(i, "%t", bufferString, attackerName);
							}
						}
					}
					else {
						if (g_iConsecutiveKills[attackerClient] < MAX_NUM_KILLS && g_sKillSound[g_iSoundPreference[i]][g_iConsecutiveKills[attackerClient]][0] != '\0') {
							int config = g_iKillConfig[g_iSoundPreference[i]][g_iConsecutiveKills[attackerClient]];

							if (config & 1) {
								EmitSoundToClient(i, g_sKillSound[g_iSoundPreference[i]][g_iConsecutiveKills[attackerClient]], .volume = g_cvarVolume.FloatValue);
							}
							else if ((config & 2) && attackerClient == i) {
								EmitSoundToClient(i, g_sKillSound[g_iSoundPreference[i]][g_iConsecutiveKills[attackerClient]], .volume = g_cvarVolume.FloatValue);
							}
							else if ((config & 4) && victimClient == i) {
								EmitSoundToClient(i, g_sKillSound[g_iSoundPreference[i]][g_iConsecutiveKills[attackerClient]], .volume = g_cvarVolume.FloatValue);
							}
						}
						if (g_iTextPreference[i] && g_iConsecutiveKills[attackerClient] < MAX_NUM_KILLS) {
							int config = g_iKillConfig[g_iSoundPreference[i]][g_iConsecutiveKills[attackerClient]];

							if (config & 8) {
								Format(bufferString, 256, "killsound %i", g_iConsecutiveKills[attackerClient]);
								PrintCenterText(i, "%t", bufferString, attackerName);
							}
							else if ((config & 16) && attackerClient == i) {
								Format(bufferString, 256, "killsound %i", g_iConsecutiveKills[attackerClient]);
								PrintCenterText(i, "%t", bufferString, attackerName);
							}
							else if ((config & 32) && victimClient == i) {
								Format(bufferString, 256, "killsound %i", g_iConsecutiveKills[attackerClient]);
								PrintCenterText(i, "%t", bufferString, attackerName);
							}
						}
					}
				}
			}
		}
	}

	g_iConsecutiveKills[victimClient] = 0;
	g_iConsecutiveHeadshots[victimClient] = 0;
}

// When someone uses command to open prefs menu, open the menu
public Action CMD_ShowQuakePrefsMenu(int client, int args) {
	ShowQuakeMenu(client);
	return Plugin_Handled;
}

// Make the menu or nothing will show
public void ShowQuakeMenu(int client) {
	char buffer[100];
	Format(buffer, 100, "%T", "quake menu", client);

	Menu menu = new Menu(MenuHandlerQuake);
	menu.SetTitle(buffer);

	Format(buffer, 100, "%T", g_iTextPreference[client] ? "disable text" : "enable text", client);
	menu.AddItem("text pref", buffer);

	Format(buffer, 100, (g_iSoundPreference[client] == -1) ? "%T (Enabled)" : "%T", "no quake sounds", client);
	menu.AddItem("no sounds", buffer);

	for (int set = 0; set < g_iNumSets; set++) {
		Format(buffer, 50, (g_iSoundPreference[client] == set) ? "%T (Enabled)" : "%T", g_sSetsName[set], client);
		menu.AddItem("sound set", buffer);
	}

	menu.ExitButton = true;
	menu.Display(client, 20);
}

// Check what's been selected in the menu
int MenuHandlerQuake(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		if (param2 == 0) {
			g_iTextPreference[param1] = !g_iTextPreference[param1];
		}
		else {
			g_iSoundPreference[param1] = param2 - 2;
		}

		char buffer[5];
		IntToString(g_iTextPreference[param1], buffer, 5);
		SetClientCookie(param1, g_hCookieText, buffer);

		IntToString(g_iSoundPreference[param1], buffer, 5);
		SetClientCookie(param1, g_hCookieSound, buffer);
		CMD_ShowQuakePrefsMenu(param1, 0);
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
}

// Adds specified sound to cache (and for CSGO);
stock void PrecacheSoundCustom(char[] soundFile, int maxLength) {
	if (g_GameEngine == Engine_CSGO) {
		Format(soundFile, maxLength, "*%s", soundFile);
		AddToStringTable(FindStringTable("soundprecache"), soundFile);
	}
	else {
		PrecacheSound(soundFile, true);
	}
}