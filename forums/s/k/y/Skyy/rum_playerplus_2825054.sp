#define			TEAM_SPECTATOR							1
#define			TEAM_SURVIVOR							2
#define			TEAM_INFECTED							3
#define			MAX_ENTITIES							2048
#define			PLUGIN_VERSION							"1.0"
#define			PLUGIN_CONTACT							"https://github.com/biaspark"
#define			PLUGIN_NAME								"[ReadyUp! Module] Player+ module"
#define			PLUGIN_DESCRIPTION						"bot manager module for ReadyUp!"

#define NICK_MODEL				"models/survivors/survivor_gambler.mdl"
#define ROCHELLE_MODEL			"models/survivors/survivor_producer.mdl"
#define COACH_MODEL				"models/survivors/survivor_coach.mdl"
#define ELLIS_MODEL				"models/survivors/survivor_mechanic.mdl"
#define ZOEY_MODEL				"models/survivors/survivor_teenangst.mdl"
#define FRANCIS_MODEL			"models/survivors/survivor_biker.mdl"
#define LOUIS_MODEL				"models/survivors/survivor_manager.mdl"
#define BILL_MODEL				"models/survivors/survivor_namvet.mdl"

#include		<sourcemod>
#include		<sdktools>

#undef			REQUIRE_PLUGIN
#include		"readyup.inc"

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_CONTACT,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT };

Handle g_sGameConf = INVALID_HANDLE;
Handle hSetHumanSpec = INVALID_HANDLE;
Handle hTakeOverBot = INVALID_HANDLE;
Handle hRoundRespawn = INVALID_HANDLE;

char white[4];
char green[4];
char blue[4];
char orange[4];

int iMinSurvivors;

public OnPluginStart() {
	CreateConVar("rum_playerplus", PLUGIN_VERSION, "version header", FCVAR_NOTIFY);
	SetConVarString(FindConVar("rum_playerplus"), PLUGIN_VERSION);
	LoadTranslations("rum_playerplus.phrases");
	g_sGameConf = LoadGameConfigFile("rum_playerplus");
	if (g_sGameConf != INVALID_HANDLE) {
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_sGameConf, SDKConf_Signature, "SetHumanSpec");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSetHumanSpec = EndPrepSDKCall();
	
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_sGameConf, SDKConf_Signature, "TakeOverBot");
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hTakeOverBot = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_sGameConf, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
	}
	else SetFailState("File not found: .../gamedata/rum_playerplus.txt");
	// beats using smlib for a small project
	Format(white, sizeof(white), "\x01");
	Format(orange, sizeof(orange), "\x04");
	Format(green, sizeof(green), "\x05");
	Format(blue, sizeof(blue), "\x03");
	AddCommandListener(Cmd_JoinTeam, "jointeam");
}

public Action Cmd_JoinTeam(int client, char[] command, int argc) {
	char a_temp[32];
	GetCmdArg(1, a_temp, sizeof(a_temp));
	if ((StrEqual(a_temp, "Survivor") || StringToInt(a_temp) == TEAM_SURVIVOR) && GetClientTeam(client) != TEAM_SURVIVOR) {
		ChangeTeamSurvivor(client);
	}
	else if (ReadyUp_GetGameMode() == 2 && ((StrEqual(a_temp, "Infected") || StringToInt(a_temp) == TEAM_INFECTED) && GetClientTeam(client) != TEAM_INFECTED)) {
		ChangeClientTeam(client, TEAM_INFECTED);
	}
	else if (StrEqual(a_temp, "Spectator") || StringToInt(a_temp) == TEAM_SPECTATOR) {
		ChangeClientTeam(client, TEAM_SPECTATOR);
	}
	if (StringToInt(a_temp) != TEAM_SURVIVOR) {
		CreateTimer(0.1, Timer_KickSurvivorBots, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Handled;
}

public ReadyUp_FwdChangeTeam(int client, int team) {
	char Name[64];
	GetClientName(client, Name, sizeof(Name));
	if (team == TEAM_SPECTATOR) {
		PrintToChatAll("%t", "Change Team Spectator", green, Name, white, green);
		ChangeClientTeam(client, TEAM_SPECTATOR);
	}
	else if (team == TEAM_SURVIVOR) {
		PrintToChatAll("%t", "Change Team Survivor", green, Name, white, blue);
		ChangeTeamSurvivor(client);
	}
	else if (team == TEAM_INFECTED) {
		PrintToChatAll("%t", "Change Team Infected", green, Name, white, orange);
		ChangeClientTeam(client, TEAM_INFECTED);
	}
	CreateTimer(0.2, Timer_CheckSurvivorCount, _, TIMER_FLAG_NO_MAPCHANGE);
}

public ReadyUp_TrueDisconnect(client) {
	if (!IsFakeClient(client)) {
		CreateTimer(0.1, Timer_KickSurvivorBots, _, TIMER_FLAG_NO_MAPCHANGE);
		if (TotalSurvivorCount(true, client) < 1 && iMinSurvivors < 1) {
			// lets other plugins know that there are no more humans and all bots have been removed.
			ReadyUp_NtvIsEmptyOnDisconnect();
		}
	}
}

public Action Timer_CheckSurvivorCount(Handle timer) {
	int TotalSurvivors = TotalSurvivorCount();
	int TotalHumanSurvivors = TotalSurvivorCount(true);
	if (TotalHumanSurvivors < 1 && iMinSurvivors < 1 || TotalSurvivors > iMinSurvivors) {
		KickSurvivorBots();
	}
	else if (iMinSurvivors > TotalSurvivors) {
		CreateSurvivorBots();
	}
	// if (TotalSurvivorCount(true) < 1 || TotalSurvivors > iMinSurvivors) CreateTimer(0.1, Timer_KickSurvivorBots, _, TIMER_FLAG_NO_MAPCHANGE);
	// else if (iMinSurvivors > TotalSurvivors) CreateTimer(0.1, Timer_CreateSurvivorBots, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Stop;
}

public Action Timer_CreateSurvivorBots(Handle timer) {
	CreateSurvivorBots();
	return Plugin_Stop;
}

public Action Timer_KickSurvivorBots(Handle timer) {
	KickSurvivorBots();
	return Plugin_Stop;
}
public ReadyUp_CheckpointDoorStartOpened() {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR || IsPlayerAlive(i)) continue;
		SDKCall(hRoundRespawn, i);
	}
	KickSurvivorBots();
}

public bool IsClientsConnecting() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && !IsClientInGame(i) && !IsFakeClient(i)) return true;
	}
	return false;
}

public ReadyUp_SetSurvivorMinimum(int iMin) {
	int oldmin = iMinSurvivors;
	iMinSurvivors = iMin;
	//if (oldmin < iMin || oldmin == iMin) CreateSurvivorBots();
	if (oldmin < iMin) {
		CreateSurvivorBots();
	}
	else {
		KickSurvivorBots();
	}
}

stock CreateSurvivorBots() {
	if (TotalSurvivorCount(true) < 1) return;	// no bots are created if there are no players.
	int thenumber = iMinSurvivors - TotalSurvivorCount();
	if (IsClientsConnecting()) {
		thenumber = 1;	// if there are still clients connecting, we only create one bot.
	}
	while (thenumber > 0) {
		thenumber--;
		CreateSurvivorBot();
	}
}

public ReadyUp_ReadyUpStart() {
	KickSurvivorBots();
}

stock int FindClientWithAuthString(char[] key, bool MustBeExact = false) {
	char AuthId[64];
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i)) continue;
		GetClientAuthId(i, AuthId_Steam2, AuthId, sizeof(AuthId));
		if (MustBeExact && StrEqual(key, AuthId, false) || !MustBeExact && StrContains(key, AuthId, false) != -1) return i;
	}
	return -1;
}

stock bool IsLegitimateClient(client) {
	if (client < 1 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client)) return false;
	return true;
}

stock bool IsSurvivorCompanion(client) {
	char CompanionSteamId[64];
	GetEntPropString(client, Prop_Data, "m_iName", CompanionSteamId, sizeof(CompanionSteamId));
	if (FindClientWithAuthString(CompanionSteamId) != -1) return true;
	return false;
}

public KickSurvivorBots() {
	int TotalSurvs = TotalSurvivorCount();
	if (TotalSurvs <= iMinSurvivors) return;	// never let it drop below 4 as long as there is at least 1 human player.
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientBot(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i)) && TotalSurvs > iMinSurvivors) {
			L4D_RemoveAllWeapons(i);
			KickClient(i);
			TotalSurvs--;
		}
	}
}

public TotalHumanSurvivorCount() {
	int Count = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) Count++;
	}
	return Count;
}

public TotalHumanCount() {
	int Count = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) Count++;
	}
	return Count;
}

stock bool IsSurvivorBot(int client) {
	if (IsLegitimateClient(client) && IsFakeClient(client)) {
		char TheModel[64];
		GetClientModel(client, TheModel, sizeof(TheModel));	// helms deep creates bots that aren't necessarily on the survivor team.
		if (StrEqual(TheModel, NICK_MODEL) ||
			StrEqual(TheModel, ROCHELLE_MODEL) ||
			StrEqual(TheModel, COACH_MODEL) ||
			StrEqual(TheModel, ELLIS_MODEL) ||
			StrEqual(TheModel, ZOEY_MODEL) ||
			StrEqual(TheModel, FRANCIS_MODEL) ||
			StrEqual(TheModel, LOUIS_MODEL) ||
			StrEqual(TheModel, BILL_MODEL)) {
			return true;
		}
	}
	return false;
}

stock int TotalSurvivorCount(bool bIsHumans = false, int client = 0) {
	int Count = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i)) && (client == 0 || client != i)) {
			if (!bIsHumans || !IsFakeClient(i)) Count++;
		}
	}
	return Count;
}

stock CreateSurvivorBot(int client = -1, char[] CompanionName = "Survivor Bot") {
	int survivorBot	= CreateFakeClient(CompanionName);
	if (survivorBot != 0) {
		ChangeClientTeam(survivorBot, TEAM_SURVIVOR);
		if (DispatchKeyValue(survivorBot, "classname", "survivorbot") && DispatchSpawn(survivorBot)) {
			float Pos[3];
			if (IsPlayerAlive(survivorBot)) {
				for (int i = 1; i <= MaxClients; i++) {
					if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && i != survivorBot) {
						GetClientAbsOrigin(i, Pos);
						TeleportEntity(survivorBot, Pos, NULL_VECTOR, NULL_VECTOR);
						break;
					}
				}
			}
			if (IsClientActual(survivorBot) && GetClientTeam(survivorBot) == TEAM_SURVIVOR && client == -1) KickClient(survivorBot);
			if (client != -1) {
				if (survivorBot != -1) {
					char SteamId[64];
					GetClientAuthId(client, AuthId_Steam2, SteamId, sizeof(SteamId));
					SetEntPropString(survivorBot, Prop_Data, "m_iName", SteamId);
				}
			}
		}
	}
}

public ChangeTeamSurvivor(int client) {
	int survivor = FindSurvivorBot();
	if (survivor == 0) {
		int survivorBot	= CreateFakeClient("Survivor Bot");
		if (survivorBot == 0) return;
		ChangeClientTeam(survivorBot, TEAM_SURVIVOR);
		if (DispatchKeyValue(survivorBot, "classname", "survivorbot") && DispatchSpawn(survivorBot)) {
			float Pos[3];
			if (IsPlayerAlive(survivorBot)) {
				for (int i = 1; i <= MaxClients; i++) {
					if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR || i == survivorBot) continue;
					GetClientAbsOrigin(i, Pos);
					TeleportEntity(survivorBot, Pos, NULL_VECTOR, NULL_VECTOR);
					break;
				}
			}
			if (IsClientActual(survivorBot) && GetClientTeam(survivorBot) == TEAM_SURVIVOR) KickClient(survivorBot);
			if (client > 0 && IsClientInGame(client)) {
				CreateTimer(1.0, Timer_ChangeTeamSurvivor, client, TIMER_FLAG_NO_MAPCHANGE);
			}
			else {
				KickSurvivorBots();
			}
		}
	}
	else if (IsClientInGame(survivor)) {
		SDKCall(hSetHumanSpec, survivor, client);
		SDKCall(hTakeOverBot, client, true);
		CreateTimer(0.2, Timer_CheckSurvivorCount, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnMapStart() {
	CreateTimer(5.0, Timer_CheckSurvivorCount, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ChangeTeamSurvivor(Handle timer, any client) {
	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client)) {
		ChangeTeamSurvivor(client);
	}
	return Plugin_Stop;
}

public FindSurvivorBot() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && IsClientActual(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsFakeClient(i)) {
			return i;
		}
	}
	return 0;
}

stock void L4D_RemoveAllWeapons(int client) {
	for (int i = 0; i <= 4; i++) {
		L4D_RemoveWeaponSlot(client, i);
	}
}

stock L4D_RemoveWeaponSlot(int client, int slot) {
    int wi = GetPlayerWeaponSlot(client, slot);
    if (wi != -1) {
        RemovePlayerItem(client, wi);
        RemoveEdict(wi);
    }
}

stock bool IsClientActual(int client) {
	if (client < 1 || client > MaxClients || !IsClientConnected(client)) return false;
	return true;
}

stock bool IsClientBot(int client) {
	if (!IsClientActual(client)) return false;
	if (IsFakeClient(client)) return true;
	return false;
}