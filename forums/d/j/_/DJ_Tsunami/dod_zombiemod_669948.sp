#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define PL_VERSION "0.1.1"

int g_iBeamSprite;
int g_iGrey[4]         = {128, 128, 128, 255};
int g_iHaloSprite;
int g_iHitgroupHead    = 1;
int g_iHumanTeam       = 2;
int g_iMaxHealth       = 150;
int g_iMeleeWeaponSlot = 2;
int g_iOffset;
int g_iRed[4]          = {255,  75,  75, 255};
int g_iWeapon[MAXPLAYERS + 1] = {-1, ...};
int g_iWins            = 0;
int g_iZombie;
int g_iZombieTeam      = 3;
bool g_bRunning    = false;
bool g_bTheOne     = false;
float g_fRadius;
Handle g_hBeacon;
ConVar g_hEnabled;
ConVar g_hLight;
ConVar g_hMin;
ConVar g_hPipes;
ConVar g_hPistols;
ConVar g_hPowerUps;
ConVar g_hShow;
ConVar g_hTheOne;
ConVar g_hWinLimit;
char g_sKill[6][] = {"dod_capture_area", "dod_bomb_dispenser", "dod_bomb_target",
					 "dod_round_timer",  "func_team_wall",     "trigger_hurt"};
char g_sModel[PLATFORM_MAX_PATH];
char g_sModelTheOne[PLATFORM_MAX_PATH];
char g_sModelZombie[PLATFORM_MAX_PATH];
char g_sSoundAmbient[PLATFORM_MAX_PATH];
char g_sSoundCritical[PLATFORM_MAX_PATH];
char g_sSoundDeath[PLATFORM_MAX_PATH];
char g_sSoundEnd[PLATFORM_MAX_PATH];
char g_sSoundFinishHim[PLATFORM_MAX_PATH];
char g_sSoundJoin[PLATFORM_MAX_PATH];
char g_sSoundSpawn[PLATFORM_MAX_PATH];
char g_sSoundStart[PLATFORM_MAX_PATH];
char g_sSoundWin[PLATFORM_MAX_PATH];
char g_sSoundTheOneDeath[PLATFORM_MAX_PATH];
char g_sSoundTheOneSpawn[PLATFORM_MAX_PATH];
char g_sSoundTheOneStart[PLATFORM_MAX_PATH];
char g_sSoundTheOneWin[PLATFORM_MAX_PATH];
char g_sSoundZombieDeath[PLATFORM_MAX_PATH];
char g_sSoundZombieSpawn[PLATFORM_MAX_PATH];
char g_sSoundZombieStart[PLATFORM_MAX_PATH];
char g_sSoundZombieWin[PLATFORM_MAX_PATH];
char g_sSoundsAmbient[8][] = {"ambient/atmosphere/tone_quiet.wav", "ambient/atmosphere/tone_alley.wav",
								"ambient/atmosphere/sewer_air1.wav", "ambient/atmosphere/hole_amb3.wav",
								"ambient/atmosphere/drone4lp.wav",   "ambient/atmosphere/ambience_base.wav",
								"ambient/atmosphere/ambience5.wav",  "ambient/atmosphere/ambience6.wav"};

public Plugin myinfo =
{
	name        = "DoD:S Zombie Mod",
	author      = "Tsunami",
	description = "DoD:S Zombie Mod for SourceMod",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
}

public void OnPluginStart()
{
	CreateConVar("sm_zombiemod_version", PL_VERSION, "DoD:S Zombie Mod for SourceMod", FCVAR_NOTIFY);
	g_hEnabled      = CreateConVar("sm_zombiemod_enabled",  "1", "Enable/disable DoD:S Zombie Mod.");
	g_hLight        = CreateConVar("sm_zombiemod_light",    "b", "Light style for DoD:S Zombie Mod.");
	g_hMin          = CreateConVar("sm_zombiemod_min",      "3", "Minimum players required for DoD:S Zombie Mod.");
	g_hPipes        = CreateConVar("sm_zombiemod_pipes",    "1", "Enable/disable pipe bombs in The One mode for DoD:S Zombie Mod.");
	g_hPistols      = CreateConVar("sm_zombiemod_pistols",  "1", "Enable/disable pistols for DoD:S Zombie Mod.");
	g_hPowerUps     = CreateConVar("sm_zombiemod_powerups", "1", "Enable/disable power ups for DoD:S Zombie Mod.");
	g_hTheOne       = CreateConVar("sm_zombiemod_theone",   "1", "Enable/disable The One mode for DoD:S Zombie Mod.");
	g_hWinLimit     = CreateConVar("sm_zombiemod_winlimit", "5", "Maximum rounds before a map change for DoD:S Zombie Mod.");
	g_iOffset       = FindSendPropInfo("CBasePlayer",       "m_iAmmo");
	g_iBeamSprite   = PrecacheModel("materials/sprites/laser.vmt");
	g_iHaloSprite   = PrecacheModel("materials/sprites/halo01.vmt");

	HookEvent("dod_round_start", Event_RoundStart);
	HookEvent("player_death",    Event_PlayerDeath);
	HookEvent("player_hurt",     Event_PlayerHurt);
	HookEvent("player_spawn",    Event_PlayerSpawn);
	LoadTranslations("zombiemod.phrases");
	RegConsoleCmd("drop",     Command_Drop,     "Block weapons from being dropped in DoD:S Zombie Mod.");
	RegConsoleCmd("say",      Command_Say,      "Hook say triggers for DoD:S Zombie Mod.");
	RegConsoleCmd("timeleft", Command_Timeleft, "Hook timeleft trigger for DoD:S Zombie Mod.");
}

public void OnMapStart()
{
	g_hShow         = FindConVar("sm_trigger_show");
	g_fRadius       = FindConVar("sm_beacon_radius").FloatValue;
	g_iWins         = 0;
	g_bRunning      = false;

	strcopy(g_sSoundAmbient, PLATFORM_MAX_PATH, g_sSoundsAmbient[GetRandomInt(0, 7)]);
	LoadConfig();
}

public void OnClientPostAdminCheck(int client)
{
	if (g_hEnabled.BoolValue && !StrEqual(g_sSoundJoin, "")) {
		EmitSoundToClient(client, g_sSoundJoin);
	}
	g_iWeapon[client] = -1;
}

public void OnClientDisconnectPost(int client)
{
	if (g_bRunning) {
		if (GetTeamClientCount(g_iZombieTeam) == 0) {
			ChooseZombie();
			ChangeClientTeam(g_iZombie, g_iZombieTeam);
			PrintHintText(g_iZombie, "You are now the Zombie");
		} else {
			CheckWin();
		}
	}
}

public Action Command_Drop(int client,     int args)
{
	return g_bRunning ? Plugin_Handled : Plugin_Continue;
}

public Action Command_Say(int client,      int args)
{
	if (g_bRunning) {
		int iStart = 0;
		char sText[192];
		GetCmdArgString(sText, sizeof(sText));

		if (sText[strlen(sText) - 1] == '"') {
			sText[strlen(sText) - 1] = '\0';
			iStart                   = 1;
		}

		if (StrEqual(sText[iStart], "timeleft")) {
			ShowTimeleft(client);

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action Command_Timeleft(int client, int args)
{
	if (g_bRunning) {
		ShowTimeleft(client);

		return Plugin_Handled;
	} else {
		return Plugin_Continue;
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bRunning) {
		char sWeapon[16];
		int iClient   = GetClientOfUserId(event.GetInt("userid")),
			iAttacker = GetClientOfUserId(event.GetInt("attacker"));
		event.GetString("weapon", sWeapon, sizeof(sWeapon));

		switch (GetClientTeam(iClient)) {
			case 2: {
				ChangeClientTeam(iClient,  g_iZombieTeam);

				if (IsValidEntity(g_iWeapon[iClient])) {
					RemoveWeapon(iClient, g_iWeapon[iClient]);
				}
				if (!CheckWin() && g_hPowerUps.BoolValue && GetClientTeam(iAttacker) == g_iZombieTeam &&
					StrContains("spade frag_ger frag_us riflegren_us", sWeapon) != -1) {
					if (g_bTheOne) {
						GivePowerUp(iAttacker, "health");
					} else {
						float fSpeed = GetEntPropFloat(iAttacker, Prop_Data, "m_flLaggedMovementValue");
						if (fSpeed < 0.85) {
							SetEntPropFloat(iAttacker, Prop_Data, "m_flLaggedMovementValue", fSpeed + 0.04);
							PrintToChat(iAttacker, "%t", "Speed");
						} else {
							PrintToChat(iAttacker, "%t", "MaxSpeed");
						}
					}
				}
			}
			case 3: {
				if (!StrEqual(g_sSoundDeath, "")) {
					EmitSoundToClient(iClient, g_sSoundDeath);
				}
				if (g_hPowerUps.BoolValue && GetClientTeam(iAttacker) == g_iHumanTeam) {
					int iAward = GetRandomInt(1, 2);
					if (g_bTheOne) {
						switch (iAward) {
							case 1: {
								GivePlayerItem(iAttacker, "weapon_frag_ger");
								GivePlayerItem(iAttacker, "weapon_frag_us");
								PrintToChat(iAttacker, "%t", "Nades");
							}
							case 2:
								GivePowerUp(iAttacker, "health");
						}
					} else if (StrContains("amerknife colt", sWeapon) != -1) {
						switch (iAward) {
							case 1: {
								if (GivePowerUp(iAttacker, "ammo")) {
									PrintToChat(iAttacker, "%t", "Ammo");
								} else {
									PrintToChat(iAttacker, "%t", "MaxAmmo");
								}
							}
							case 2:
								GivePowerUp(iAttacker, "health");
						}
					} else if (GivePowerUp(iAttacker, "ammo")) {
						PrintToChat(iAttacker, "%t", "AmmoFatal");
					}
				}
			}
		}
	}
}

public Action Event_PlayerHurt(Event event,  const char[] name, bool dontBroadcast)
{
	if (g_bRunning) {
		char sWeapon[16];
		int iClient   = GetClientOfUserId(event.GetInt("userid")),
			iAttacker = GetClientOfUserId(event.GetInt("attacker")),
			iHitgroup = event.GetInt("hitgroup"),
			iTeam     = GetClientTeam(iClient);
		event.GetString("weapon", sWeapon, sizeof(sWeapon));

		if (iTeam == g_iZombieTeam) {
			int iWeapon = GetPlayerWeaponSlot(iClient, g_iMeleeWeaponSlot);
			if (g_bTheOne) {
				SetEntityRenderColor(iClient, 255, 255, 255, 255);
				SetEntityRenderColor(iWeapon, 255, 0, 0, 255);
				CreateTimer(3.0, Timer_Invisible, iClient);
			} else if (iHitgroup == g_iHitgroupHead && StrContains("amerknife colt", sWeapon) != -1 && GetClientHealth(iClient) > 2) {
				SetEntityHealth(iClient, 2);
				SetEntityRenderColor(iWeapon, 0, 255, 0, 255);
				if (!StrEqual(g_sSoundCritical,  "")) {
					EmitSoundToClient(iClient,   g_sSoundCritical);
				}
				if (!StrEqual(g_sSoundFinishHim, "")) {
					EmitSoundToClient(iAttacker, g_sSoundFinishHim);
				}
				PrintCenterText(iAttacker,     "%t", "FinishHim");
			}
		}
	}
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int iClient  = GetClientOfUserId(event.GetInt("userid"));
	if (g_hEnabled.BoolValue && !g_bRunning && g_hMin.IntValue <= GetTeamClientCount(g_iHumanTeam) + GetTeamClientCount(g_iZombieTeam)) {
		RestartRound();

		g_bRunning = true;
	} else if (g_bRunning) {
		/*decl Float:fPosition[3];
		GetClientAbsOrigin(iClient, fPosition);
		EmitAmbientSound(g_sSoundAmbient, fPosition, iClient);*/

		if (GetClientTeam(iClient) == g_iZombieTeam) {
			SetEntityModel(iClient,    g_sModel);
			CreateTimer(0.1, Timer_Strip, iClient);

			if (g_bTheOne) {
				SetEntityRenderMode(iClient,  RENDER_TRANSCOLOR);
				SetEntityRenderColor(iClient, 0, 0, 0, 0);
				SetEntPropFloat(iClient, Prop_Data, "m_flLaggedMovementValue", 2.0);
			} else {
				SetEntityHealth(iClient, 10000);
				SetEntPropFloat(iClient, Prop_Data, "m_flLaggedMovementValue", 0.65);
			}
			if (!StrEqual(g_sSoundSpawn, "")) {
				EmitSoundToClient(iClient, g_sSoundSpawn);
			}
		} else {
			g_iWeapon[iClient] = GetPlayerWeaponSlot(iClient, 0);
			GivePlayerItem(iClient, "weapon_amerknife");
			GivePlayerItem(iClient, "weapon_colt");
			SetEntData(iClient, g_iOffset + 4, 28, _, true);
		}
	}
}

public Action Event_RoundStart(Event event,  const char[] name, bool dontBroadcast)
{
	if (g_bRunning) {
		EmitSoundToAll(g_sSoundStart);

		for (int i = 0; i < sizeof(g_sKill); i++) {
			int iKill     = -1;
			while ((iKill = FindEntityByClassname(iKill, g_sKill[i])) != -1) {
				AcceptEntityInput(iKill, "Kill");
			}
		}

		char sLight[2];
		g_hLight.GetString(sLight, sizeof(sLight));
		SetLightStyle(0, sLight);
	} else {
		SetLightStyle(0, "m");
	}
}

public Action Timer_Beacon(Handle timer, int client)
{
	if (!IsClientInGame(client) || IsClientObserver(client) || !IsPlayerAlive(client)) {
		g_hBeacon      = null;
		return Plugin_Stop;
	}
	float fPosition[3];
	GetClientAbsOrigin(client, fPosition);
	fPosition[2]    += 10;

	TE_SetupBeamRingPoint(fPosition, 10.0, g_fRadius, g_iBeamSprite, g_iHaloSprite, 0, 15, 0.5, 5.0,  0.0, g_iGrey, 10, 0);
	TE_SendToAll();

	TE_SetupBeamRingPoint(fPosition, 10.0, g_fRadius, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.6, 10.0, 0.5, g_iRed,  10, 0);
	TE_SendToAll();

	GetClientEyePosition(client, fPosition);
	EmitAmbientSound("buttons/blip1.wav", fPosition, client, SNDLEVEL_RAIDSIREN);

	return Plugin_Handled;
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

public Action Timer_Invisible(Handle timer, int client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client)) {
		SetEntityRenderColor(client, 0, 0, 0, 0);
		SetEntityRenderColor(GetPlayerWeaponSlot(client, g_iMeleeWeaponSlot), 0, 0, 0, 0);
	}
}

public Action Timer_RestartRound(Handle timer)
{
	ServerCommand("mp_clan_restartround 1");
	ChooseZombie();

	g_bRunning  = false;
	g_bTheOne   = g_hTheOne.BoolValue && GetRandomInt(1, 2) == 2 ? true : false;
	if (GetClientTeam(g_iZombie) == g_iHumanTeam) {
		ChangeClientTeam(g_iZombie, g_iZombieTeam);
	}
	for (int i  = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == g_iZombieTeam && i != g_iZombie) {
			ChangeClientTeam(i, g_iHumanTeam);
		}
	}
	g_bRunning  = true;

	if (g_bTheOne) {
		g_sModel      = g_sModelTheOne;
		g_sSoundDeath = g_sSoundTheOneDeath;
		g_sSoundSpawn = g_sSoundTheOneSpawn;
		g_sSoundStart = g_sSoundTheOneStart;
		g_sSoundWin   = g_sSoundTheOneWin;
	} else {
		g_sModel      = g_sModelZombie;
		g_sSoundDeath = g_sSoundZombieDeath;
		g_sSoundSpawn = g_sSoundZombieSpawn;
		g_sSoundStart = g_sSoundZombieStart;
		g_sSoundWin   = g_sSoundZombieWin;
	}
}

public Action Timer_Strip(Handle timer, int client)
{
	for (int i = 0, s; i < 5; i++) {
		if ((s = GetPlayerWeaponSlot(client, i)) != -1) {
			RemoveWeapon(client, s);
		}
	}

	int iWeapon = GivePlayerItem(client, "weapon_spade");
	SetEntityRenderMode(iWeapon,    RENDER_TRANSCOLOR);

	if (g_bTheOne) {
		SetEntityRenderColor(iWeapon,   0, 0, 0, 0);
		if (g_hPipes.BoolValue) {
			GivePlayerItem(client, "weapon_frag_ger");
			GivePlayerItem(client, "weapon_frag_ger");
		}
	} else {
		SetEntityRenderColor(iWeapon, 255, 0, 0, 255);
	}
}

bool GivePowerUp(int iClient, const char[] sPowerUp)
{
	if (StrEqual(sPowerUp, "ammo")) {
		int iAmmo = GetEntData(iClient, g_iOffset + 4);
		if (iAmmo < 50) {
			SetEntData(iClient, g_iOffset + 4, iAmmo + 7, _, true);
			return true;
		}
	} else if (StrEqual(sPowerUp, "health")) {
		int iHealth = GetClientHealth(iClient);
		if (iHealth < g_iMaxHealth) {
			SetEntityHealth(iClient, iHealth + 10);
			PrintToChat(iClient, "%t", "Health");
		} else {
			PrintToChat(iClient, "%t", "MaxHealth");
		}
	}

	return false;
}

bool CheckWin()
{
	int iCount  = GetTeamClientCount(g_iHumanTeam);
	if (iCount == 1) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && GetClientTeam(i) == g_iHumanTeam) {
				g_hBeacon = CreateTimer(2.0, Timer_Beacon, i, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				break;
			}
		}
	} else if (iCount == 0) {
		delete g_hBeacon;

		if (++g_iWins == g_hWinLimit.IntValue) {
			if (!StrEqual(g_sSoundWin, "")) {
				EmitSoundToAll(g_sSoundWin);
			}
			PrintToChatAll("%t", "Win");
			CreateTimer(4.5, Timer_EndGame);
		} else {
			if (!StrEqual(g_sSoundEnd, "")) {
				EmitSoundToAll(g_sSoundEnd);
			}
			RestartRound();
		}
		return true;
	}

	return false;
}

void ChooseZombie()
{
	int iZombie = GetRandomInt(1, MaxClients);
	while (!IsClientInGame(iZombie) || IsClientObserver(iZombie) || iZombie == g_iZombie) {
		iZombie   = GetRandomInt(1, MaxClients);
	}
	g_iZombie   = iZombie;
}

void LoadConfig()
{
	KeyValues hConfig = new KeyValues("ZombieMod");
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/zombiemod.txt");

	if (FileExists(sPath)) {
		hConfig.ImportFromFile(sPath);
		hConfig.JumpToKey("Models");
		hConfig.GetString("TheOne",      g_sModelTheOne,      PLATFORM_MAX_PATH);
		hConfig.GetString("Zombie",      g_sModelZombie,      PLATFORM_MAX_PATH);

		if (!StrEqual(g_sModelTheOne, "")) {
			LoadModel(g_sModelTheOne);
		}
		if (!StrEqual(g_sModelZombie, "")) {
			LoadModel(g_sModelZombie);
		}

		hConfig.Rewind();
		hConfig.JumpToKey("Sounds");
		hConfig.GetString("Critical",    g_sSoundCritical,    PLATFORM_MAX_PATH);
		hConfig.GetString("End",         g_sSoundEnd,         PLATFORM_MAX_PATH);
		hConfig.GetString("FinishHim",   g_sSoundFinishHim,   PLATFORM_MAX_PATH);
		hConfig.GetString("Join",        g_sSoundJoin,        PLATFORM_MAX_PATH);
		hConfig.GetString("TheOneDeath", g_sSoundTheOneDeath, PLATFORM_MAX_PATH);
		hConfig.GetString("TheOneSpawn", g_sSoundTheOneSpawn, PLATFORM_MAX_PATH);
		hConfig.GetString("TheOneStart", g_sSoundTheOneStart, PLATFORM_MAX_PATH);
		hConfig.GetString("TheOneWin",   g_sSoundTheOneWin,   PLATFORM_MAX_PATH);
		hConfig.GetString("ZombieDeath", g_sSoundZombieDeath, PLATFORM_MAX_PATH);
		hConfig.GetString("ZombieSpawn", g_sSoundZombieSpawn, PLATFORM_MAX_PATH);
		hConfig.GetString("ZombieStart", g_sSoundZombieStart, PLATFORM_MAX_PATH);
		hConfig.GetString("ZombieWin",   g_sSoundZombieWin,   PLATFORM_MAX_PATH);

		if (!StrEqual(g_sSoundCritical,    "")) {
			LoadSound(g_sSoundCritical);
		}
		if (!StrEqual(g_sSoundEnd,         "")) {
			LoadSound(g_sSoundEnd);
		}
		if (!StrEqual(g_sSoundFinishHim,   "")) {
			LoadSound(g_sSoundFinishHim);
		}
		if (!StrEqual(g_sSoundJoin,        "")) {
			LoadSound(g_sSoundJoin);
		}
		if (!StrEqual(g_sSoundTheOneDeath, "")) {
			LoadSound(g_sSoundTheOneDeath);
		}
		if (!StrEqual(g_sSoundTheOneSpawn, "")) {
			LoadSound(g_sSoundTheOneSpawn);
		}
		if (!StrEqual(g_sSoundTheOneStart, "")) {
			LoadSound(g_sSoundTheOneStart);
		}
		if (!StrEqual(g_sSoundTheOneWin,   "")) {
			LoadSound(g_sSoundTheOneWin);
		}
		if (!StrEqual(g_sSoundZombieDeath, "")) {
			LoadSound(g_sSoundZombieDeath);
		}
		if (!StrEqual(g_sSoundZombieSpawn, "")) {
			LoadSound(g_sSoundZombieSpawn);
		}
		if (!StrEqual(g_sSoundZombieStart, "")) {
			LoadSound(g_sSoundZombieStart);
		}
		if (!StrEqual(g_sSoundZombieWin,   "")) {
			LoadSound(g_sSoundZombieWin);
		}
	} else {
		SetFailState("File Not Found: %s", sPath);
	}
}

void LoadModel(const char[] sFile)
{
	PrecacheModel(sFile, true);
	AddFileToDownloadsTable(sFile);
}

void LoadSound(const char[] sFile)
{
	char sPath[PLATFORM_MAX_PATH];
	Format(sPath, sizeof(sPath), "sound/%s", sFile);
	PrecacheSound(sFile, true);
	AddFileToDownloadsTable(sPath);
}

void RemoveWeapon(int iClient, int iWeapon)
{
	RemovePlayerItem(iClient, iWeapon);
	RemoveEdict(iWeapon);
}

void RestartRound()
{
	if (g_bRunning && g_hMin.IntValue <= GetTeamClientCount(g_iHumanTeam) + GetTeamClientCount(g_iZombieTeam)) {
		CreateTimer(15.0, Timer_RestartRound);
	} else {
		g_bRunning      = false;
	}
}

void ShowTimeleft(int iClient)
{
	char sTimeleft[64];
	Format(sTimeleft, sizeof(sTimeleft), "%c%t", 1, "Timeleft", 4, g_iWins, 1, 4, g_hWinLimit.IntValue, 1);

	if (iClient == 0) {
		PrintToServer(sTimeleft);
	} else if (g_hShow.BoolValue) {
		PrintToChat(iClient, sTimeleft);
	} else {
		PrintToChatAll(sTimeleft);
	}
}
