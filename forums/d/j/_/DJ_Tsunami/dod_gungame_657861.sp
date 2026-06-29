#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define PL_VERSION "0.4.1"

public Plugin myinfo =
{
	name        = "DoD:S GunGame",
	author      = "Tsunami",
	description = "DoD:S GunGame for SourceMod",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
}

int g_iAmmo[MAXPLAYERS + 1];
int g_iAmount[MAXPLAYERS + 1];
int g_iClip;
int g_iLevel[MAXPLAYERS + 1]    = {1, ...};
int g_iLevels;
int g_iOffset;
int g_iOldLevel[MAXPLAYERS + 1] = {1, ...};
int g_iWeapon[MAXPLAYERS + 1]   = {-1, ...};
bool g_bEnabled                 = true;
float g_fPosition[MAXPLAYERS + 1][3];
ConVar g_hEnabled;
ConVar g_hFlags;
ConVar g_hHandicap;
ConVar g_hSpades;
ConVar g_hSpadePro;
ConVar g_hTurbo;
char g_sPrefix[24]              = "\x01[\x04GunGame\x01] ";
char g_sSoundJoin[PLATFORM_MAX_PATH];
char g_sSoundLevelUp[PLATFORM_MAX_PATH];
char g_sSoundLevelDown[PLATFORM_MAX_PATH];
char g_sSoundLevelSteal[PLATFORM_MAX_PATH];
char g_sSoundWin[PLATFORM_MAX_PATH];
char g_sWeapon[MAXPLAYERS + 1][16];

public void OnPluginStart()
{
	CreateConVar("sm_gungame_version", PL_VERSION, "DoD:S GunGame for SourceMod", FCVAR_NOTIFY);
	g_hEnabled  = CreateConVar("sm_gungame_enabled",  "1", "Enable/disable DoD:S GunGame.");
	g_hFlags    = CreateConVar("sm_gungame_flags",    "0", "Enable/disable flags in DoD:S GunGame.");
	g_hHandicap = CreateConVar("sm_gungame_handicap", "1", "Enable/disable Handicap mode in DoD:S GunGame.");
	g_hSpades   = CreateConVar("sm_gungame_spades",   "1", "Enable/disable spades in DoD:S GunGame.");
	g_hSpadePro = CreateConVar("sm_gungame_spadepro", "1", "Enable/disable Spade Pro mode in DoD:S GunGame.");
	g_hTurbo    = CreateConVar("sm_gungame_turbo",    "1", "Enable/disable Turbo mode in DoD:S GunGame.");
	g_iClip     = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	g_iOffset   = FindSendPropInfo("CBasePlayer",       "m_iAmmo");

	g_hEnabled.AddChangeHook(ConVarChange_Enabled);
	g_hFlags.AddChangeHook(ConVarChange_Flags);
	HookEvent("dod_round_start", Event_RoundStart);
	HookEvent("player_death",    Event_PlayerDeath);
	HookEvent("player_spawn",    Event_PlayerSpawn);
	RegConsoleCmd("drop",        Command_Drop, "Block weapons from being dropped in DoD:S GunGame.");
	LoadTranslations("gungame.phrases");
}

public void OnMapStart()
{
	LoadConfig();
}

public void OnGameFrame()
{
	if (g_bEnabled) {
		for (int i    = 1, iAmmo, iAmount; i <= MaxClients; i++) {
			if (IsClientInGame(i) && IsPlayerAlive(i)) {
				iAmmo     = g_iAmmo[GetLevel(i)], iAmount = g_iAmount[i];
				if (iAmmo > g_iOffset && GetEntData(i, iAmmo) <= iAmount) {
					SetEntData(i, iAmmo, iAmount * 2, _, true);
				}
			}
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (g_bEnabled && !StrEqual(g_sSoundJoin, "")) {
		EmitSoundToClient(client, g_sSoundJoin);
	}
	int iClients  = GetTeamClientCount(2) + GetTeamClientCount(3), iLevel = 0;
	if (g_hHandicap.BoolValue && iClients > 0) {
		for (int i  = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && GetClientTeam(i) > 1) {
				iLevel += GetLevel(i);
			}
		}
		g_iLevel[client] = iLevel / iClients;
	} else {
		g_iLevel[client] = 1;
	}
	g_iWeapon[client]  = -1;
}

public void ConVarChange_Enabled(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bEnabled  = StrEqual(newValue, "1");

	ServerCommand("mp_clan_restartround 1");

	int iLevel[MAXPLAYERS + 1] = {1, ...};
	g_iLevel                   = iLevel;
}

public void ConVarChange_Flags(ConVar convar,   const char[] oldValue, const char[] newValue)
{
	SetFlags();
}

public int MenuHandler_Give(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End) {
		delete menu;
	} else if (action == MenuAction_Select) {
		GiveWeapon(param1);
	}
}

public Action Command_Drop(int client, int args)
{
	return g_bEnabled ? Plugin_Handled : Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bEnabled) {
		float fPosition[3];
		char sWeapon[16];
		int iAttackerID = event.GetInt("attacker"),
			iClientID   = event.GetInt("userid"),
			iAttacker   = GetClientOfUserId(iAttackerID),
			iClient     = GetClientOfUserId(iClientID);
		GetClientAbsOrigin(iClient, fPosition);
		event.GetString("weapon", sWeapon, sizeof(sWeapon));

		if (IsValidEntity(g_iWeapon[iClient])) {
			RemoveWeapon(iClient, g_iWeapon[iClient]);
		}
		if (iAttacker == 0 || iAttacker == iClient)   {
			if (g_iLevel[iClient] > 1) {
				g_iLevel[iClient]--;
				PrintToChatAll("%s%t", g_sPrefix, "Suicide", 4, iClient, 1);
				LogEvent("gg_leveldown",    iClientID);

				if (!StrEqual(g_sSoundLevelDown,    "")) {
					EmitSoundToClient(iClient, g_sSoundLevelDown);
				}
			}
		} else if (GetClientTeam(iAttacker) != GetClientTeam(iClient) &&
					(StrEqual(sWeapon, g_sWeapon[GetLevel(iAttacker)]) || StrEqual(sWeapon, "spade"))) {
			if (fPosition[0] == g_fPosition[iClient][0] &&
					fPosition[1] == g_fPosition[iClient][1]) {
				PrintHintText(iAttacker, "%t", "AFK", iClient);
			} else if (g_iLevel[iAttacker]++ < g_iLevels) {
				if (g_hSpades.BoolValue   && g_hSpadePro.BoolValue &&
					StrEqual(sWeapon, "spade") && g_iLevel[iClient] > 1) {
					g_iLevel[iClient]--;
					PrintToChatAll("%s%t", g_sPrefix, "Steal", 4, iAttacker, 1, 4, iClient, 1);
					LogEvent("gg_levelsteal", iAttackerID);
					LogEvent("gg_leveldown",  iClientID);

					if (!StrEqual(g_sSoundLevelSteal, "")) {
						EmitSoundToClient(iAttacker, g_sSoundLevelSteal);
					}
					if (!StrEqual(g_sSoundLevelDown,  "")) {
						EmitSoundToClient(iClient,   g_sSoundLevelDown);
					}
				} else {
					LogEvent("gg_levelup",    iAttackerID);

					if (!StrEqual(g_sSoundLevelUp,    "")) {
						EmitSoundToClient(iAttacker, g_sSoundLevelUp);
					}
				}

				int iLeader  = GetLeader(), iLevel = g_iLevel[iAttacker];
				if (IsPlayerAlive(iAttacker)) {
					PrintToChat(iAttacker,   "%s%t", g_sPrefix, "Weapon",     4, g_sWeapon[iLevel]);
				}
				if (iLeader == iAttacker) {
					PrintToChatAll("%s%t", g_sPrefix, "Leader", 4, iAttacker, 1, 4, iLevel, 1);
				} else {
					int iLead  = g_iLevel[iLeader] - iLevel;
					if (iLead  > 0) {
						PrintToChat(iAttacker, "%s%t", g_sPrefix, "Difference", 4, iLead, 1, iLead == 1 ? "" : "s");
					}
				}

				if (g_hTurbo.BoolValue) {
					CreateTimer(0.1, Timer_Give, iAttacker);
				} else {
					Menu hGive = new Menu(MenuHandler_Give);

					SetMenuTitle(hGive, "You have leveled up!");
					SetMenuExitButton(hGive, true);
					AddMenuItem(hGive, "", "Press 1 to get your next weapon.");
					DisplayMenu(hGive, iAttacker, MENU_TIME_FOREVER);
				}
			} else {
				char sNextMap[32];
				GetNextMap(sNextMap, sizeof(sNextMap));
				PrintToChatAll("%s%t",   g_sPrefix, "Win",   4, iAttacker, 1, 4, sNextMap);
				LogEvent("gg_win", iAttackerID);
				CreateTimer(4.5, Timer_EndGame);

				if (!StrEqual(g_sSoundWin,          "")) {
					EmitSoundToAll(g_sSoundWin);
				}
			}
		}
	}
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bEnabled) {
		int iClient = GetClientOfUserId(event.GetInt("userid"));
		if (GetClientTeam(iClient) > 1) {
			GetClientAbsOrigin(iClient, g_fPosition[iClient]);
			CreateTimer(0.1, Timer_Strip, iClient);
		}
	}
}

public Action Event_RoundStart(Event event,  const char[] name, bool dontBroadcast)
{
	SetFlags();
}

public Action Timer_EndGame(Handle timer)
{
	int iGameEnd  = FindEntityByClassname(-1, "game_end");
	if (iGameEnd == -1 && (iGameEnd = CreateEntityByName("game_end")) == -1) {
		LogError("Unable to create entity \"game_end\"!");
	} else {
		AcceptEntityInput(iGameEnd, "EndGame");
	}
}

public Action Timer_Give(Handle timer,  int client)
{
	if (IsPlayerAlive(client)) {
		GiveWeapon(client);
	}
}

public Action Timer_Strip(Handle timer, int client) {
	for (int i = 0, s; i < 5; i++) {
		if ((s = GetPlayerWeaponSlot(client, i)) != -1) {
			RemoveWeapon(client, s);
		}
	}

	int iLevel        = g_iLevel[client];
	g_iWeapon[client] = -1;
	PrintToChat(client, "%s%t", g_sPrefix, "Level", 4, iLevel, 1, 4, g_sWeapon[iLevel]);
	GiveWeapon(client);
	if (g_hSpades.BoolValue && !StrEqual(g_sWeapon[iLevel], "amerknife")
		&& !StrEqual(g_sWeapon[iLevel], "spade")) {
		GivePlayerItem(client, "weapon_spade");
	}
}

int GetLeader()
{
	int iLeader = 0;
	for (int i  = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && g_iLevel[i] > g_iLevel[iLeader]) {
			iLeader = i;
		}
	}

	return iLeader;
}

int GetLevel(int iClient) {
	if (g_hTurbo.BoolValue) {
		return g_iLevel[iClient];
	} else {
		return g_iOldLevel[iClient];
	}
}

int GiveWeapon(int iClient)
{
	int iWeapon;
	char sWeapon[24];
	int iLevel = g_iOldLevel[iClient] = g_iLevel[iClient];
	Format(sWeapon, sizeof(sWeapon), "weapon_%s", g_sWeapon[iLevel]);

	if (IsValidEntity(g_iWeapon[iClient])) {
		RemoveWeapon(iClient, g_iWeapon[iClient]);
	}
	if (g_hSpades.BoolValue && (iWeapon = GetPlayerWeaponSlot(iClient, 2)) != -1 &&
		(StrEqual(g_sWeapon[iLevel], "amerknife") || StrEqual(g_sWeapon[iLevel], "spade"))) {
		RemoveWeapon(iClient, iWeapon);
	}
	g_iWeapon[iClient]      = GivePlayerItem(iClient, sWeapon);
	if ((g_iAmount[iClient] = GetEntData(g_iWeapon[iClient], g_iClip)) < 1) {
		g_iAmount[iClient]    = 1;
	}
	if (g_iAmmo[iLevel]     > 0) {
		SetEntData(iClient, g_iAmmo[iLevel], g_iAmount[iClient] * 2, _, true);
	}
}

void LoadConfig()
{
	char sLevel[4], sPath[PLATFORM_MAX_PATH], sWeapon[16],
		sWeapons[22][16] = {"colt",      "p38",       "c96",
							"garand",    "k98",       "k98_scoped",
							"m1carbine", "spring",    "thompson",
							"mp40",      "mp44",      "bar",
							"30cal",     "mg42",      "bazooka",
							"pschreck",  "frag_us",   "frag_ger",
							"smoke_us",  "smoke_ger", "riflegren_us",
							"riflegren_ger"};
	int  iLevel                  = 1,
		 iOffsets[22]            = { 4,  8, 12,
									16, 20, 20,
									24, 28, 32,
									32, 32, 36,
									40, 44, 48,
									48, 52, 56,
									68, 72, 84,
									88};
	KeyValues hConfig            = new KeyValues("GunGame");
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/gungame.txt");

	if (FileExists(sPath)) {
		for (int i = 0; i < sizeof(g_sWeapon); i++) {
			g_iAmmo[i]   = g_iOffset;
			g_sWeapon[i] = "";
		}

		hConfig.ImportFromFile(sPath);
		hConfig.JumpToKey("Levels");
		hConfig.GetString("1", sWeapon, sizeof(sWeapon));

		while (!StrEqual(sWeapon, "")) {
			g_sWeapon[iLevel] = sWeapon;

			IntToString(++iLevel, sLevel, sizeof(sLevel));
			hConfig.GetString(sLevel, sWeapon, sizeof(sWeapon));
		}

		hConfig.Rewind();
		hConfig.JumpToKey("Sounds");
		hConfig.GetString("Join",       g_sSoundJoin,       PLATFORM_MAX_PATH);
		hConfig.GetString("LevelUp",    g_sSoundLevelUp,    PLATFORM_MAX_PATH);
		hConfig.GetString("LevelDown",  g_sSoundLevelDown,  PLATFORM_MAX_PATH);
		hConfig.GetString("LevelSteal", g_sSoundLevelSteal, PLATFORM_MAX_PATH);
		hConfig.GetString("Win",        g_sSoundWin,        PLATFORM_MAX_PATH);

		if (!StrEqual(g_sSoundJoin,       "")) {
			LoadSound(g_sSoundJoin);
		}
		if (!StrEqual(g_sSoundLevelUp,    "")) {
			LoadSound(g_sSoundLevelUp);
		}
		if (!StrEqual(g_sSoundLevelDown,  "")) {
			LoadSound(g_sSoundLevelDown);
		}
		if (!StrEqual(g_sSoundLevelSteal, "")) {
			LoadSound(g_sSoundLevelSteal);
		}
		if (!StrEqual(g_sSoundWin,        "")) {
			LoadSound(g_sSoundWin);
		}

		g_iLevels  = --iLevel;
		for (int i = 1, j; i <= g_iLevels; i++) {
			for (j = 0; j < sizeof(sWeapons); j++) {
				if (StrEqual(g_sWeapon[i], sWeapons[j])) {
					g_iAmmo[i] += iOffsets[j];
					break;
				}
			}
		}
	} else {
		SetFailState("File Not Found: %s", sPath);
	}
}

void LoadSound(const char[] sFile)
{
	char sPath[PLATFORM_MAX_PATH];
	Format(sPath, sizeof(sPath), "sound/%s", sFile);
	PrecacheSound(sFile, true);
	AddFileToDownloadsTable(sPath);
}

void LogEvent(const char[] sName, int iUserID)
{
	char sAuth[32];
	int iClient = GetClientOfUserId(iUserID);
	GetClientAuthId(iClient, AuthId_Steam2, sAuth, sizeof(sAuth));
	LogToGame("\"%N<%d><%s><GunGame>\" triggered \"%s\"", iClient, iUserID, sAuth, sName);
}

void RemoveWeapon(int iClient, int iWeapon)
{
	RemovePlayerItem(iClient, iWeapon);
	RemoveEdict(iWeapon);
}

void SetFlags()
{
	char sState[8];
	int iCaptureArea     = -1;
	sState               = g_bEnabled && !g_hFlags.BoolValue ? "Disable" : "Enable";
	while ((iCaptureArea = FindEntityByClassname(iCaptureArea, "dod_capture_area")) != -1) {
		AcceptEntityInput(iCaptureArea, sState);
	}
}
