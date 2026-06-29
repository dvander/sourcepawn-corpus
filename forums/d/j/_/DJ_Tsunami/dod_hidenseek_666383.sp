#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define PL_VERSION "0.2.1"

int g_iBeamSprite;
int g_iGrey[4]       = {128, 128, 128, 255};
int g_iHaloSprite;
int g_iHideTeam      = 2;
int g_iModelsCount;
int g_iRed[4]        = {255,  75,  75, 255};
int g_iSeeker;
int g_iSeekTeam      = 3;
int g_iWins;
bool g_bRunning  = false;
bool g_bUse[MAXPLAYERS + 1] = false;
float g_fRadius;
Handle g_hBeacon;
ConVar g_hEnabled;
ConVar g_hMin;
Menu g_hModels;
ConVar g_hRandom;
ConVar g_hShow;
ConVar g_hSwitch;
ConVar g_hThird;
ConVar g_hWinLimit;
char g_sKill[6][] = {"dod_capture_area", "dod_bomb_dispenser", "dod_bomb_target",
					 "dod_round_timer",  "func_team_wall",     "trigger_hurt"};
char g_sModels[256][PLATFORM_MAX_PATH];
char g_sSection[8];
char g_sSoundLive[PLATFORM_MAX_PATH];
char g_sSoundWin[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name        = "DoD:S Hide & Seek",
	author      = "Tsunami",
	description = "DoD:S Hide & Seek for SourceMod",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
}

public void OnPluginStart()
{
	CreateConVar("sm_hidenseek_version", PL_VERSION, "DoD:S Hide & Seek for SourceMod", FCVAR_NOTIFY);
	g_hEnabled     = CreateConVar("sm_hidenseek_enabled",  "1", "Enable/disable DoD:S Hide & Seek.");
	g_hMin         = CreateConVar("sm_hidenseek_min",      "3", "Minimum players required for DoD:S Hide & Seek.");
	g_hRandom      = CreateConVar("sm_hidenseek_random",   "0", "Enable/disable random models for DoD:S Hide & Seek.");
	g_hSwitch      = CreateConVar("sm_hidenseek_switch",   "1", "Enable/disable in-round model switching for DoD:S Hide & Seek.");
	g_hThird       = CreateConVar("sm_hidenseek_3rd",      "1", "Enable/disable switching players to third person on spawn for DoD:S Hide & Seek.");
	g_hWinLimit    = CreateConVar("sm_hidenseek_winlimit", "6", "Maximum rounds before a map change for DoD:S Hide & Seek.");
	g_iBeamSprite  = PrecacheModel("materials/sprites/laser.vmt");
	g_iHaloSprite  = PrecacheModel("materials/sprites/halo01.vmt");

	g_hEnabled.AddChangeHook(ConVarChange_Enabled);
	HookEvent("dod_round_start", Event_RoundStart);
	HookEvent("player_death",    Event_PlayerDeath);
	HookEvent("player_hurt",     Event_PlayerHurt);
	HookEvent("player_spawn",    Event_PlayerSpawn);
	HookEvent("player_team",     Event_PlayerTeam);
	LoadTranslations("hidenseek.phrases");
	RegConsoleCmd("say",      Command_Say,      "Hook say triggers for DoD:S Hide & Seek.");
	RegConsoleCmd("-3rd",     Command_ThirdOff, "Disable third person in DoD:S Hide & Seek.");
	RegConsoleCmd("+3rd",     Command_ThirdOn,  "Enable third person in DoD:S Hide & Seek.");
	RegConsoleCmd("timeleft", Command_Timeleft, "Hook timeleft trigger for DoD:S Hide & Seek.");
}

public void OnMapStart()
{
	g_hShow        = FindConVar("sm_trigger_show");
	g_fRadius      = FindConVar("sm_beacon_radius").FloatValue;
	g_iWins        = 0;
	g_bRunning     = false;

	LoadConfig();
	PrecacheModel("models/player/american_support.mdl");
}

public void OnGameFrame()
{
	for (int i = 1; i <= MaxClients; i++) {
		if ((g_bUse[i] = IsClientInGame(i) && IsPlayerAlive(i) && GetClientButtons(i) & IN_USE && !g_bUse[i])) {
			Use(i);
		}
	}
}

public void OnClientDisconnectPost(int client)
{
	if (g_bRunning) {
		if (GetTeamClientCount(g_iSeekTeam) == 0) {
			ChooseSeeker();
			ChangeClientTeam(g_iSeeker, g_iSeekTeam);
			PrintHintText(g_iSeeker, "You are now the Seeker");
		} else {
			CheckWin();
		}
	}
}

public void ConVarChange_Enabled(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bRunning     = false;

	ServerCommand("mp_clan_restartround 1");
}

public int MenuHandler_SetModel(Menu menu,    MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select) {
		char sModel[PLATFORM_MAX_PATH];
		GetMenuItem(menu, param2, sModel, sizeof(sModel));
		SetModel(param1, sModel);

		if (g_hThird.BoolValue) {
			SetThird(param1, true);
		}
	}
}

public int MenuHandler_SwitchModel(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select) {
		char sModel[PLATFORM_MAX_PATH];
		menu.GetItem(param2, sModel, sizeof(sModel));

		if (!StrEqual(sModel, "0")) {
			SetModel(param1, sModel);
		}
	}
}

public Action Command_Say(int client, int args)
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

public Action Command_ThirdOff(int client, int args)
{
	if (g_bRunning && GetClientTeam(client) == g_iHideTeam) {
		SetThird(client, false);
	}

	return Plugin_Handled;
}

public Action Command_ThirdOn(int client,  int args)
{
	if (g_bRunning && GetClientTeam(client) == g_iHideTeam) {
		SetThird(client, true);
	}

	return Plugin_Handled;
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
		int iClient = GetClientOfUserId(event.GetInt("userid"));

		if (GetClientTeam(iClient) == g_iHideTeam) {
			int iAttacker  = GetClientOfUserId(event.GetInt("attacker"));
			if (iAttacker != 0 && GetClientTeam(iAttacker) == g_iSeekTeam && GetTeamClientCount(g_iHideTeam) > 1) {
				GivePlayerItem(iAttacker, "weapon_p38");
			}

			// sm_msay 5 Nickname has joined the Seekers
			ChangeClientTeam(iClient, g_iSeekTeam);
			CheckWin();
		}
	}
}

public Action Event_PlayerHurt(Event event,  const char[] name, bool dontBroadcast)
{
	if (g_bRunning) {
		int iClient = GetClientOfUserId(event.GetInt("userid"));

		if (GetClientHealth(iClient) <= 0) {
			SetEntityModel(iClient, "models/player/american_support.mdl");
		}
	}
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int iClient  = GetClientOfUserId(event.GetInt("userid"));
	if (g_hEnabled.BoolValue && !g_bRunning && g_hMin.IntValue <= GetTeamClientCount(g_iHideTeam) + GetTeamClientCount(g_iSeekTeam)) {
		RestartRound();

		g_bRunning = true;
	} else if (g_bRunning && GetClientTeam(iClient) > 1) {
		CreateTimer(0.1, Timer_Strip, iClient);
	}
}

public Action Event_PlayerTeam(Event event,  const char[] name, bool dontBroadcast)
{
	if (g_bRunning && event.GetInt("oldteam") == g_iHideTeam) {
		SetEntityModel(GetClientOfUserId(event.GetInt("userid")), "models/player/american_support.mdl");
	}
}

public Action Event_RoundStart(Event event,  const char[] name, bool dontBroadcast)
{
	if (g_bRunning) {
		EmitSoundToAll(g_sSoundLive);

		for (int i = 0; i < sizeof(g_sKill); i++) {
			int iKill     = -1;
			while ((iKill = FindEntityByClassname(iKill, g_sKill[i])) != -1) {
				AcceptEntityInput(iKill, "Kill");
			}
		}
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

public Action Timer_Strip(Handle timer, int client)
{
	for (int i = 0, s; i < 5; i++) {
		if ((s = GetPlayerWeaponSlot(client, i)) != -1) {
			RemovePlayerItem(client, s);
			RemoveEdict(s);
		}
	}

	switch (GetClientTeam(client)) {
		case 2: {
			int iWeapon = GivePlayerItem(client, "weapon_amerknife");
			SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(iWeapon, 255, 255, 255, 0);
			SetModel(client, g_sModels[GetRandomInt(1, g_iModelsCount)]);

			if (!g_hRandom.BoolValue) {
				g_hModels.Display(client, MENU_TIME_FOREVER);
			}
			if (g_hThird.BoolValue)   {
				SetThird(client, true);
			}
		}
		case 3:
			GivePlayerItem(client, "weapon_spade");
	}
}

public SMCResult EndSection(SMCParser smc) {}

public SMCResult KeyValue(SMCParser smc,   const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if (StrEqual(g_sSection, "Models")) {
		PrecacheModel(value, true);
		AddFileToDownloadsTable(value);
		g_hModels.AddItem(value, key);
		strcopy(g_sModels[++g_iModelsCount], sizeof(g_sModels[]), value);
	} else if (StrEqual(g_sSection, "Sounds")) {
		if (!StrEqual(value, ""))     {
			char sPath[PLATFORM_MAX_PATH];
			Format(sPath, sizeof(sPath), "sound/%s", value);
			PrecacheSound(value, true);
			AddFileToDownloadsTable(sPath);
		}

		if (StrEqual(key,    "Live")) {
			strcopy(g_sSoundLive, sizeof(g_sSoundLive), value);
		} else if (StrEqual(key, "Win")) {
			strcopy(g_sSoundWin,  sizeof(g_sSoundWin),  value);
		}
	}
}

public SMCResult NewSection(SMCParser smc, const char[] name, bool opt_quotes)
{
	strcopy(g_sSection, sizeof(g_sSection), name);
}

void CheckWin()
{
	int iCount  = GetTeamClientCount(g_iHideTeam);
	if (iCount == 1) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && GetClientTeam(i) == g_iHideTeam) {
				// sm_msay 10 The Seekers have beaconed the \n Last Man Standing!
				g_hBeacon = CreateTimer(2.0, Timer_Beacon, i, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				break;
			}
		}
	} else if (iCount == 0) {
		EmitSoundToAll(g_sSoundWin);
		delete g_hBeacon;

		if (++g_iWins == g_hWinLimit.IntValue) {
			char sNextMap[32];
			GetNextMap(sNextMap, sizeof(sNextMap));
			PrintToChatAll("%c%t", 1, "Win", 4, sNextMap, 1);
			CreateTimer(4.5, Timer_EndGame);
		} else {
			RestartRound();
		}
	}
}

void ChooseSeeker()
{
	int iSeeker = GetRandomInt(1, MaxClients);
	while (!IsClientInGame(iSeeker) || IsClientObserver(iSeeker) || iSeeker == g_iSeeker) {
		iSeeker   = GetRandomInt(1, MaxClients);
	}
	g_iSeeker   = iSeeker;
}

void LoadConfig()
{
	SMCParser hParser = new SMCParser();
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/hidenseek.txt");

	if (FileExists(sPath)) {
		delete g_hModels;

		g_iModelsCount = 0;
		g_hModels      = new Menu(MenuHandler_SetModel);
		g_hModels.SetTitle("%t", "Camouflage");
		g_hModels.ExitBackButton = true;
		hParser.OnEnterSection = NewSection;
		hParser.OnKeyValue     = KeyValue;
		hParser.OnLeaveSection = EndSection;

		int iLine;
		SMCError iError = hParser.ParseFile(sPath, iLine);
		if (iError != SMCError_Okay) {
			char sError[256];
			hParser.GetErrorString(iError, sError, sizeof(sError));
			LogError("Could not parse file (line %d, file \"%s\"):", iLine, sPath);
			LogError("Parser encountered error: %s", sError);
		}
	} else {
		SetFailState("File Not Found: %s", sPath);
	}
}

void RestartRound()
{
	ServerCommand("mp_clan_restartround 9");
	ChooseSeeker();

	g_bRunning  = false;
	if (GetClientTeam(g_iSeeker) == g_iHideTeam) {
		ChangeClientTeam(g_iSeeker, g_iSeekTeam);
	}
	for (int i  = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == g_iSeekTeam && i != g_iSeeker) {
			ChangeClientTeam(i, g_iHideTeam);
		}
	}
	g_bRunning  = true;
}

void SetModel(int iClient, const char[] sModel)
{
	SetEntityModel(iClient, sModel);
	SetEntityRenderColor(iClient, 255, 255, 255, 255);
}

void SetThird(int iClient, bool bState)
{
	if (bState) {
		SetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget", 0);
		SetEntProp(iClient,    Prop_Send, "m_iObserverMode",   1);
		SetEntProp(iClient,    Prop_Send, "m_bDrawViewmodel",  0);
		SetEntProp(iClient,    Prop_Send, "m_iFOV",            120);
	} else {
		SetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(iClient,    Prop_Send, "m_iObserverMode",   0);
		SetEntProp(iClient,    Prop_Send, "m_bDrawViewmodel",  1);
		SetEntProp(iClient,    Prop_Send, "m_iFOV",            90);
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

void Use(int iClient)
{
	if (g_bRunning && g_hSwitch.BoolValue && GetClientTeam(iClient) == g_iHideTeam) {
		char sClientModel[PLATFORM_MAX_PATH], sDisplay[32], sInfo[PLATFORM_MAX_PATH], sModel[PLATFORM_MAX_PATH];
		int iModel = GetClientAimTarget(iClient, false);
		if (iModel > MaxClients + 1) {
			GetEntPropString(iClient, Prop_Data, "m_ModelName", sClientModel, PLATFORM_MAX_PATH);
			GetEntPropString(iModel,  Prop_Data, "m_ModelName", sModel,       PLATFORM_MAX_PATH);

			if (StrEqual(sClientModel, sModel)) {
				// sm_msay 5 You are already a sClientModel
			} else {
				for (int i = 1; i <= g_iModelsCount; i++) {
					g_hModels.GetItem(i, sInfo, sizeof(sInfo), _, sDisplay, sizeof(sDisplay));
					if (StrEqual(sInfo, sModel)) {
						char sNo[16], sYes[16];
						Menu hSwitch = new Menu(MenuHandler_SwitchModel);

						Format(sNo,  sizeof(sNo),  "%t", "No");
						Format(sYes, sizeof(sYes), "%t", "Yes");

						hSwitch.ExitButton = false;
						hSwitch.SetTitle("%t", "Switch", sDisplay);
						hSwitch.AddItem(sModel, sYes);
						hSwitch.AddItem("0",    sNo);
						hSwitch.Display(iClient, MENU_TIME_FOREVER);
						break;
					}
				}
			}
		}
	}
}
