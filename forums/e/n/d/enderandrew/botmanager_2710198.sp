#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION			"1.3.0"

public Plugin myinfo =
{
	name		= "[TF2] Bot Manager",
	author		= "Dr. McKay",
	description	= "Allows for customization of TFBots",
	version		= PLUGIN_VERSION,
	url			= "http://www.doctormckay.com"
}

Handle cvarBotQuota;
Handle cvarBotJoinAfterPlayer;
Handle cvarGameLogic;
Handle cvarSupportedMap;
Handle cvarOnTeamsOnly;

ConVar tf_bot_quota;

Handle joiningBots;

Handle fwdBotAdd;
Handle fwdBotKick;

#define UPDATE_FILE		"botmanager.txt"
#define CONVAR_PREFIX	"bot_manager"

#include "mckayupdater.sp"

// BEGIN: Enums and stocks ported from tf2.inc and tf2_stocks.inc (for TF2Classic compatibility)
enum TFClassType
{
	TFClass_Unknown = 0,
	TFClass_Scout,
	TFClass_Sniper,
	TFClass_Soldier,
	TFClass_DemoMan,
	TFClass_Medic,
	TFClass_Heavy,
	TFClass_Pyro,
	TFClass_Spy,
	TFClass_Engineer
};

enum TFTeam
{
	TFTeam_Unassigned = 0,
	TFTeam_Spectator = 1,
	TFTeam_Red = 2,
	TFTeam_Blue = 3
};

stock TFClassType TF2_GetPlayerClass(int client)
{
	return view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_iClass"));
}
// END

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char game[64];
	GetGameFolderName(game, sizeof(game));
	if(!StrEqual(game, "tf") && !StrEqual(game, "tf2classic")) {
		strcopy(error, err_max, "Bot Manager only works on Team Fortress 2");
		return APLRes_Failure;
	}
	
	RegPluginLibrary("botmanager");
	return APLRes_Success;
}

public void OnPluginStart()
{
	cvarBotQuota = CreateConVar("sm_bot_quota", "0", "Number of players to keep in the server");
	cvarBotJoinAfterPlayer = CreateConVar("sm_bot_join_after_player", "1", "If nonzero, bots wait until a player joins before entering the game.");
	cvarGameLogic = CreateConVar("sm_bot_game_logic", "1", "0 = use plugin logic when assigning bots, 1 = use game logic");
	cvarSupportedMap = CreateConVar("sm_bot_supported_map", "1", "If nonzero, bots will only be added on maps that have nav files");
	cvarOnTeamsOnly = CreateConVar("sm_bot_on_team_only", "1", "If nonzero, players will only be considered \"in-game\" if they're on a team for purposes of determining the bot count");
	
	tf_bot_quota = FindConVar("tf_bot_quota");
	
	HookEvent("player_connect_client", Event_PlayerConnect, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	
	joiningBots = CreateArray();
	
	fwdBotAdd = CreateGlobalForward("Bot_OnBotAdd", ET_Single, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_String);
	fwdBotKick = CreateGlobalForward("Bot_OnBotKick", ET_Single, Param_CellByRef);
	
	Handle buffer = FindConVar("tf_bot_quota_mode");
	SetConVarString(buffer, "normal");
	HookConVarChange(buffer, OnConVarChange);
	buffer = FindConVar("tf_bot_join_after_player");
	SetConVarInt(buffer, 0);
	HookConVarChange(buffer, OnConVarChange);
}

public void OnConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	char name[64];
	GetConVarName(convar, name, sizeof(name));
	if(StrEqual(name, "tf_bot_quota_mode")) {
		LogMessage("tf_bot_quota_mode cannot be changed while Bot Manager is running. tf_bot_quota_mode set to \"normal\".");
		SetConVarString(convar, "normal");
	} else if(StrEqual(name, "tf_bot_join_after_player")) {
		LogMessage("tf_bot_join_after_player cannot be changed while Bot Manager is running. tf_bot_join_after_player set to \"0\". Use sm_bot_join_after_player for similar functionality.");
		SetConVarInt(convar, 0);
	}
}

public void OnConfigsExecuted()
{
	char buffer[64];
	GetCurrentMap(buffer, sizeof(buffer));
	Format(buffer, sizeof(buffer), "maps/%s.nav", buffer);
	if(FileExists(buffer, true) || !GetConVarBool(cvarSupportedMap)) {
		CreateTimer(0.1, Timer_CheckBotNum, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	} else {
		LogMessage("Bots are not supported on this map. Bot Manager disabled.");
	}
}

public void OnMapEnd()
{
	SetConVarInt(tf_bot_quota, 0); // Prevents an issue that happens at mapchange
}

public Action Timer_CheckBotNum(Handle timer)
{
	int clients = GetValidClientCount();
	int actual = GetValidClientCount(false);
	int bots = GetBotCount();
	int realClients = clients - bots;
	if(realClients == 0 && GetConVarBool(cvarBotJoinAfterPlayer)) {
		if(bots > 0) {
			RemoveBot();
		}
		return;
	}
	if(GetConVarInt(cvarBotQuota) >= MaxClients) {
		LogMessage("sm_bot_quota cannot be greater than or equal to maxplayers. Setting sm_bot_quota to \"%d\".", MaxClients - 1);
		SetConVarInt(cvarBotQuota, MaxClients - 1);
	}
	if(clients < GetConVarInt(cvarBotQuota) && actual < (MaxClients - 1)) {
		AddBot();
	} else if(clients > GetConVarInt(cvarBotQuota) && bots > 0) {
		RemoveBot();
	}
}

int GetValidClientCount(bool excludeTeamsOnly = true)
{																	  
	int count = 0;
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || IsClientSourceTV(i) || IsClientReplay(i)) {
			continue;
		}
		if(excludeTeamsOnly && GetConVarBool(cvarOnTeamsOnly) && GetClientTeam(i) <= 1) {
			continue;
		}
		count++;
	}
	return count;
}

int GetBotCount()
{																					  
	int count = 0;
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsClientSourceTV(i) && !IsClientReplay(i) && IsFakeClient(i)) {
			count++;
		}
	}
	return count;
}

int AddBot()
{									
	TFTeam team = TFTeam_Unassigned;
	
	if(!GetConVarBool(cvarGameLogic)) {
		if(GetTeamClientCount(2) < GetTeamClientCount(3)) {
			team = TFTeam_Red;
		} else {
			team = TFTeam_Blue;
		}
	}
	
	TFClassType class = TFClass_Unknown;
	
	if(!GetConVarBool(cvarGameLogic)) {
		int scout, soldier, pyro, demoman, heavy, engineer, medic, sniper, spy;
		GetClassCounts(team, scout, soldier, pyro, demoman, heavy, engineer, medic, sniper, spy);
		if(medic == 0) {
			class = TFClass_Medic;
		} else {
			int least = scout;
			class = TFClass_Scout;
			if(soldier < least) {
				least = soldier;
				class = TFClass_Soldier;
			}
			if(pyro < least) {
				least = pyro;
				class = TFClass_Pyro;
			}
			if(demoman < least) {
				least = demoman;
				class = TFClass_DemoMan;
			}
			if(heavy < least) {
				least = heavy;
				class = TFClass_Heavy;
			}
			if(engineer < least) {
				least = engineer;
				class = TFClass_Engineer;
			}
			if(sniper < least) {
				least = sniper;
				class = TFClass_Sniper;
			}
			if(spy < least) {
				least = spy;
				class = TFClass_Spy;
			}
		}
	}
	
	int difficulty = -1;
	char name[MAX_NAME_LENGTH];
	
	Call_StartForward(fwdBotAdd);
	Call_PushCellRef(class);
	Call_PushCellRef(team);
	Call_PushCellRef(difficulty);
	Call_PushStringEx(name, sizeof(name), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish();
	
	char strDifficulty[16];
	char strTeam[16];
	char strClass[16];
	
	switch(difficulty) {
		case 0: Format(strDifficulty, sizeof(strDifficulty), "easy");
		case 1: Format(strDifficulty, sizeof(strDifficulty), "normal");
		case 2: Format(strDifficulty, sizeof(strDifficulty), "hard");
		case 3: Format(strDifficulty, sizeof(strDifficulty), "expert");
		default: Format(strDifficulty, sizeof(strDifficulty), "");
	}
	
	switch(team) {
		case TFTeam_Red: Format(strTeam, sizeof(strTeam), "red");
		case TFTeam_Blue: Format(strTeam, sizeof(strTeam), "blue");
		default: Format(strTeam, sizeof(strTeam), "");
	}
	
	switch(class) {
		case TFClass_Scout: Format(strClass, sizeof(strClass), "Scout");
		case TFClass_Soldier: Format(strClass, sizeof(strClass), "Soldier");
		case TFClass_Pyro: Format(strClass, sizeof(strClass), "Pyro");
		case TFClass_DemoMan: Format(strClass, sizeof(strClass), "Demoman");
		case TFClass_Heavy: Format(strClass, sizeof(strClass), "HeavyWeapons");
		case TFClass_Engineer: Format(strClass, sizeof(strClass), "Engineer");
		case TFClass_Medic: Format(strClass, sizeof(strClass), "Medic");
		case TFClass_Sniper: Format(strClass, sizeof(strClass), "Sniper");
		case TFClass_Spy: Format(strClass, sizeof(strClass), "Spy");
		default: Format(strClass, sizeof(strClass), "");
	}
	
	ReplaceString(name, sizeof(name), "\"", "");
	if(strlen(name) > 0) {
		Format(name, sizeof(name), "\"%s\"", name);
	}
	
	ServerCommand("tf_bot_add %s %s %s %s", strDifficulty, strTeam, strClass, name); // count class team difficulty name (any order)
}

void GetClassCounts(TFTeam team, int &scout, int &soldier, int &pyro, int &demoman, int &heavy, int &engineer, int &medic, int &sniper, int &spy)
{
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || view_as<TFTeam>(GetClientTeam(i)) != team) {
			continue;
		}
		switch(TF2_GetPlayerClass(i)) {
			case TFClass_Scout: scout++;
			case TFClass_Soldier: soldier++;
			case TFClass_Pyro: pyro++;
			case TFClass_DemoMan: demoman++;
			case TFClass_Heavy: heavy++;
			case TFClass_Engineer: engineer++;
			case TFClass_Medic: medic++;
			case TFClass_Sniper: sniper++;
			case TFClass_Spy: spy++;
		}
	}
}

void RemoveBot()
{
	int teamToKick;
	if(GetTeamClientCount(2) > GetTeamClientCount(3)) {
		teamToKick = 2;
	} else if(GetTeamClientCount(2) < GetTeamClientCount(3)) {
		teamToKick = 3;
	} else {
		teamToKick = GetRandomInt(2, 3);
	}
	
	Handle bots = CreateArray();
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientConnected(i) && !IsClientSourceTV(i) && !IsClientReplay(i) && IsFakeClient(i) && GetClientTeam(i) == teamToKick) {
			PushArrayCell(bots, i);
		}
	}
	
	if(GetArraySize(bots) == 0) {
		CloseHandle(bots);
		return;
	}
	
	int bot = GetArrayCell(bots, GetRandomInt(0, GetArraySize(bots) - 1));
	CloseHandle(bots);
	
	Call_StartForward(fwdBotKick);
	Call_PushCellRef(bot);
	Call_Finish();
	
	ServerCommand("tf_bot_kick \"%N\"", bot);
}

public void Event_PlayerConnect(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetEventBool(event, "bot")) {
		PushArrayCell(joiningBots, GetEventInt(event, "userid"));
		SetEventBroadcast(event, true);
	}
}

public void Event_PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client == 0) {
		return;
	}
	if(IsFakeClient(client)) {
		SetEventBroadcast(event, true);
		PrintToChatAll("\x01BOT \x07%06X%N \x01has left the game", GetTeamColor(GetClientTeam(client)), client);
	}
}

public void Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client == 0) {
		return;
	}
	if(IsFakeClient(client)) {
		SetEventBroadcast(event, true);
		int pos;
		if((pos = FindValueInArray(joiningBots, GetClientUserId(client))) != -1) {
			RemoveFromArray(joiningBots, pos);
			PrintToServer("BOT %N has joined the game", client);
			PrintToChatAll("\x01BOT \x07%06X%N \x01has joined the game", GetTeamColor(GetEventInt(event, "team")), client);
		}
	}
}

int GetTeamColor(int team)
{
	int value;
	switch(team) {
		case 1: {
			value = 0xCCCCCC;
		}
		case 2: {
			value = 0xFF4040;
		}
		case 3: {
			value = 0x99CCFF;
		}
		default: {
			value = 0x3EFF3E;
		}
	}
	return value;
}