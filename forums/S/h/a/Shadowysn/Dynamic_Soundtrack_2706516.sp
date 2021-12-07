// DeathChaos25 is the original creator of this plugin.
// Shadowysn is the one that bug-tested, edited, and polished this plugin to better functionality.

/* Includes */
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

/* L4D1 Survivor Models */
#define MODEL_BILL "models/survivors/survivor_namvet.mdl"
#define MODEL_ZOEY 	"models/survivors/survivor_teenangst.mdl"
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"

#define PLUGIN_NAME "[L4D2] Dynamic Soundtrack Sets"
#define PLUGIN_AUTHOR "DeathChaos25, Shadowysn"
#define PLUGIN_DESC "Adjusts soundtrack for both survivor sets"
#define PLUGIN_VERSION "1.5.4"
#define PLUGIN_URL ""
#define PLUGIN_NAME_SHORT "Dynamic Soundtrack Sets"
#define PLUGIN_NAME_TECH "dynamic_soundtrack"

#define GAMEDATA "dynamic_soundtrack"

Handle hConf = null;

static Handle hMusicPlay = null;
#define NAME_MusicPlay "Music::Play"
#define SIG_MusicPlay_LINUX "@_ZN5Music4PlayEPKcifbb"
#define SIG_MusicPlay_WINDOWS "\\x55\\x8B\\x2A\\x81\\xEC\\xDC\\x2A\\x2A\\x2A\\xA1\\x2A\\x2A\\x2A\\x2A\\x33\\x2A\\x89\\x2A\\x2A\\xA1"

static Handle hMusicStopPlaying = null;
#define NAME_MusicStopPlaying "Music::StopPlaying"
#define SIG_MusicStopPlaying_LINUX "@_ZN5Music11StopPlayingEPKcfb"
#define SIG_MusicStopPlaying_WINDOWS "\\x55\\x8B\\x2A\\x83\\x2A\\x2A\\xA1\\x2A\\x2A\\x2A\\x2A\\x83\\x2A\\x2A\\x2A\\x56\\x8B\\x2A\\x89\\x2A\\x2A\\x0F\\x84\\x25"

/* Plugin Information */
public Plugin myinfo =  {
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESC, 
	version = PLUGIN_VERSION, 
	url = PLUGIN_URL
}

/* Globals */
#define DEBUG 0 
#define DEBUG_TAG "L4D1 Sound Restore"
#define DEBUG_PRINT_FORMAT "[%s] %s"

#define MAX_ENTITIES 4096

//static bool g_CanPlayDeathHit = true;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

ConVar version_cvar;

/* Plugin Functions */
public void OnPluginStart()
{
	char cvar_str[500];
	Format(cvar_str, sizeof(cvar_str), "%s plugin version.", PLUGIN_NAME_SHORT);
	version_cvar = CreateConVar("sm_l4d2_dynamic_soundtrack_ver", PLUGIN_VERSION, cvar_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	GetGamedata();
	
	HookEvent("player_incapacitated", player_incapacitated, EventHookMode_Post);
	HookEvent("revive_success", revive_success, EventHookMode_Post);
	HookEvent("player_spawn", player_spawn, EventHookMode_Post);
	HookEvent("player_death", player_death, EventHookMode_Post);
	HookEvent("mission_lost", mission_lost, EventHookMode_Post);
	HookEvent("map_transition", map_transition, EventHookMode_Post);
	HookEvent("finale_escape_start", finale_escape_start, EventHookMode_Post);
	HookEvent("finale_win", finale_win, EventHookMode_Post);
	
	RegAdminCmd("sm_ds_onall", Command_PlayOnAll, ADMFLAG_CHEATS, "Play music on all players.");
	RegAdminCmd("sm_ds_sndonall", Command_PlaySndOnAll, ADMFLAG_CHEATS, "Play sound on all players.");
	RegAdminCmd("sm_ds_stop_onall", Command_StopOnAll, ADMFLAG_CHEATS, "Stop music on all players.");
}

public void OnPluginEnd()
{
	UnhookEvent("player_incapacitated", player_incapacitated, EventHookMode_Post);
	UnhookEvent("revive_success", revive_success, EventHookMode_Post);
	UnhookEvent("player_spawn", player_spawn, EventHookMode_Post);
	UnhookEvent("player_death", player_death, EventHookMode_Post);
	UnhookEvent("mission_lost", mission_lost, EventHookMode_Post);
	UnhookEvent("map_transition", map_transition, EventHookMode_Post);
	UnhookEvent("finale_escape_start", finale_escape_start, EventHookMode_Post);
	UnhookEvent("finale_win", finale_win, EventHookMode_Post);
}

public void OnMapStart()
{
	//g_CanPlayDeathHit = true;
	
	// Map check coming soon tm music/tags/LeftForDeathHit_l4d1.wav
	PrefetchSound("music/tags/LeftForDeathHit_l4d1.wav");
	PrecacheSound("music/tags/LeftForDeathHit_l4d1.wav", true);
	
	PrefetchSound("music/tags/LeftForDeathHit_l4d1.wav");
	PrecacheSound("music/tags/LeftForDeathHit_l4d1.wav", true);
}

Action Command_PlayOnAll(int client, any args)
{
	if (args < 1 || args > 5)
	{
		ReplyToCommand(client, "[SM] Usage: sm_ds_onall <music>");
		return Plugin_Handled;
	}
	
	/*if (GetClientCount(false) >= (MaxClients - number_int))
	{
		ReplyToCommand(client, "[SM] Attempt to kick dead infected bots...");
		kick = KickDeadInfectedBots(client);
    }
	
	if (kick <= 0)
	{ CreateInfectedWithParams(client, zomb, mode_int, number_int); }
	else
	{
		DataPack data = CreateDataPack();
		data.WriteCell(client);
		data.WriteString(zomb);
		data.WriteCell(mode_int);
		data.WriteCell(number_int);
		CreateTimer(0.01, Timer_CreateInfected, data);
	}*/
	
	char arg[128], arg_one_int[10], arg_one_float[10], arg_one_bool[1], arg_two_bool[1];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg_one_int, sizeof(arg_one_int));
	GetCmdArg(3, arg_one_float, sizeof(arg_one_float));
	GetCmdArg(4, arg_one_bool, sizeof(arg_one_bool));
	GetCmdArg(5, arg_two_bool, sizeof(arg_two_bool));
	//SDK_PlayMusic(int client, const char[] music_str, int one_int = 1, float one_float = 0.0, bool one_bool = false, bool two_bool = false)
	//char format_str[256];
	//Format(format_str, sizeof(format_str), "music_dynamic_play %s", arg);
	
	int one_int = StringToInt(arg_one_int);
	float one_float = StringToFloat(arg_one_float);
	bool one_bool = view_as<bool>(StringToInt(arg_one_bool));
	bool two_bool = view_as<bool>(StringToInt(arg_two_bool));
	
	for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
	{
		if (IsValidClient(loopclient) && !IsFakeClient(loopclient))
		{
			SDK_PlayMusic(loopclient, arg, one_int, one_float, one_bool, two_bool);
		}
	}
	
	return Plugin_Handled;
}

Action Command_StopOnAll(int client, any args)
{
	if (args < 1 || args > 5)
	{
		ReplyToCommand(client, "[SM] Usage: sm_ds_stop_onall <music>");
		return Plugin_Handled;
	}
	
	char arg[128], arg_one_float[10], arg_one_bool[1];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg_one_float, sizeof(arg_one_float));
	GetCmdArg(3, arg_one_bool, sizeof(arg_one_bool));
	
	float one_float = StringToFloat(arg_one_float);
	bool one_bool = view_as<bool>(StringToInt(arg_one_bool));
	
	for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
	{
		if (IsValidClient(loopclient) && !IsFakeClient(loopclient))
		{
			SDK_StopMusic(loopclient, arg, one_float, one_bool);
		}
	}
	
	return Plugin_Handled;
}

Action Command_PlaySndOnAll(int client, any args)
{
	if (args < 1 || args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_ds_sndonall <snd_path>");
		return Plugin_Handled;
	}
	
	char arg[128];
	GetCmdArg(1, arg, sizeof(arg));
	
	//char format_str[256];
	//Format(format_str, sizeof(format_str), "music_dynamic_play %s", arg);
	
	PrecacheSound(arg);
	
	for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
	{
		if (IsValidClient(loopclient) && !IsFakeClient(loopclient))
		{
			EmitSoundToClient(loopclient, arg, loopclient);
		}
	}
	
	return Plugin_Handled;
}

void player_incapacitated(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsSurvivor(client) || !IsPlayerAlive(client)) return;
	
	SDKHook(client, SDKHook_OnTakeDamagePost, CheckIncapHealth);
	switch (IsL4D1Survivor(client))
	{
		case true:
		{
			if (!IsFakeClient(client))
			{
				SDK_StopMusic(client, "Event.Down");
				SDK_PlayMusic(client, "Event.Down_L4D1", client);
			}
			for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
			{
				if (loopclient != client && IsSurvivor(loopclient) && IsPlayerAlive(loopclient) && !IsFakeClient(loopclient))
				{
					SDK_StopMusic(loopclient, "Event.DownHit");
					SDK_PlayMusic(loopclient, "Event.DownHit_L4D1", client);
				}
			}
			return;
		}
		default:
		{
			if (!IsFakeClient(client))
			{
				SDK_StopMusic(client, "Event.Down_L4D1");
				SDK_PlayMusic(client, "Event.Down", client);
			}
			for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
			{
				if (loopclient != client && IsSurvivor(loopclient) && IsPlayerAlive(loopclient) && !IsFakeClient(loopclient))
				{
					SDK_StopMusic(loopclient, "Event.DownHit_L4D1");
					SDK_PlayMusic(loopclient, "Event.DownHit", client);
				}
			}
			return;
		}
	}
}

void CheckIncapHealth(int client, int attacker, int inflictor, float damage, int damagetype)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && IsSurvivor(client) && IsIncapped(client))
	{
		int health = GetClientHealth(client);
		if (health < 30)
		{
			SDKUnhook(client, SDKHook_OnTakeDamagePost, CheckIncapHealth);
			RequestFrame(CheckIncapHealth_FrameCallback, client);
		}
	}
	else
	{ SDKUnhook(client, SDKHook_OnTakeDamagePost, CheckIncapHealth); }
}

void CheckIncapHealth_FrameCallback(int client)
{
	if (!IsSurvivor(client)) return;
	switch (IsL4D1Survivor(client))
	{
		case true:
		{
			if (!IsFakeClient(client))
			{
				SDK_StopMusic(client, "Event.BleedingOut");
				SDK_PlayMusic(client, "Event.BleedingOut_L4D1", client);
			}
			for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
			{
				if (loopclient != client && IsSurvivor(loopclient) && IsPlayerAlive(loopclient) && !IsFakeClient(loopclient))
				{
					SDK_StopMusic(loopclient, "Event.BleedingOutHit");
					SDK_PlayMusic(loopclient, "Event.BleedingOutHit_L4D1", client);
				}
			}
			return;
		}
		default:
		{
			if (!IsFakeClient(client))
			{
				SDK_StopMusic(client, "Event.BleedingOut_L4D1");
				SDK_PlayMusic(client, "Event.BleedingOut", client);
			}
			for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
			{
				if (loopclient != client && IsSurvivor(loopclient) && IsPlayerAlive(loopclient) && !IsFakeClient(loopclient))
				{
					SDK_StopMusic(loopclient, "Event.BleedingOutHit_L4D1");
					SDK_PlayMusic(loopclient, "Event.BleedingOutHit", client);
				}
			}
			return;
		}
	}
}

void revive_success(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "subject"));
	if (!IsValidClient(client) || !IsSurvivor(client) || IsFakeClient(client)) return;
	
	SDK_StopMusic(client, "Event.Down_L4D1", 1.0);
	SDK_StopMusic(client, "Event.BleedingOut_L4D1", 1.0);
	SDK_StopMusic(client, "Event.Down", 1.0);
	SDK_StopMusic(client, "Event.BleedingOut", 1.0);
}

void player_spawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsSurvivor(client) && !IsFakeClient(client))
	{
		StopMusic(client, 1.0);
	}
}

void player_death(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client) || !IsSurvivor(client) || IsPlayerAlive(client)) return;
	
	StopMusic(client, 0.0);
	switch (IsL4D1Survivor(client))
	{
		case true:
		{
			if (!IsFakeClient(client))
			{
				SDK_PlayMusic(client, "Event.SurvivorDeath_L4D1", client);
			}
			for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
			{
				if (loopclient != client && IsSurvivor(loopclient) && IsPlayerAlive(loopclient) && !IsFakeClient(loopclient))
				{
					SDK_StopMusic(loopclient, "Event.SurvivorDeathHit");
					SDK_PlayMusic(loopclient, "Event.SurvivorDeathHit_L4D1", client);
				}
			}
			return;
		}
		default:
		{
			if (!IsFakeClient(client))
			{
				SDK_PlayMusic(client, "Event.SurvivorDeath", client);
			}
			for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
			{
				if (loopclient != client && IsSurvivor(loopclient) && IsPlayerAlive(loopclient) && !IsFakeClient(loopclient))
				{
					SDK_StopMusic(loopclient, "Event.SurvivorDeathHit_L4D1");
					SDK_PlayMusic(loopclient, "Event.SurvivorDeathHit", client);
				}
			}
			return;
		}
	}
	
	/*if (g_CanPlayDeathHit)
	{
		g_CanPlayDeathHit = false;
		CreateTimer(10.0, g_CanPlayDeathHit_Timer, _, TIMER_FLAG_NO_MAPCHANGE);
	}*/
}

void mission_lost(Handle event, const char[] name, bool dontBroadcast)
{
	RequestFrame(MISSIONLOSTMUSIC_FrameCallback);
}
void MISSIONLOSTMUSIC_FrameCallback()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client) || !IsSurvivor(client) || IsFakeClient(client)) continue;
		
		switch (IsL4D1Survivor(client))
		{
			case true:
			{
				SDK_StopMusic(client, "Event.ScenarioLose");
				SDK_PlayMusic(client, "Event.ScenarioLose_L4D1", client);
				return;
			}
			default:
			{
				SDK_StopMusic(client, "Event.ScenarioLose_L4D1");
				SDK_PlayMusic(client, "Event.ScenarioLose", client);
				return;
			}
		}
	}
}

void map_transition(Handle event, const char[] name, bool dontBroadcast)
{
	RequestFrame(MAPTRANSITIONMUSIC_FrameCallback);
}
void MAPTRANSITIONMUSIC_FrameCallback()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client) || !IsSurvivor(client) || IsFakeClient(client)) continue;
		
		switch (IsL4D1Survivor(client))
		{
			case true:
			{
				SDK_StopMusic(client, "Event.SafeRoom");
				SDK_PlayMusic(client, "Event.SafeRoom_L4D1", client);
				return;
			}
			default:
			{
				SDK_StopMusic(client, "Event.SafeRoom_L4D1");
				SDK_PlayMusic(client, "Event.SafeRoom", client);
				return;
			}
		}
	}
}

void finale_escape_start(Handle event, const char[] name, bool dontBroadcast)
{
	RequestFrame(FINALEALMOSTMUSIC_FrameCallback);
}
void FINALEALMOSTMUSIC_FrameCallback()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client) || !IsSurvivor(client) || IsFakeClient(client)) return;
		
		switch (IsL4D1Survivor(client))
		{
			case true:
			{
				SDK_StopMusic(client, "Event.FinalBattle");
				SDK_PlayMusic(client, "Event.FinalBattle_L4D1", client);
				return;
			}
			default:
			{
				SDK_StopMusic(client, "Event.FinalBattle_L4D1");
				SDK_PlayMusic(client, "Event.FinalBattle", client);
				return;
			}
		}
	}
}

void finale_win(Handle event, const char[] name, bool dontBroadcast)
{
	RequestFrame(FINALEWINMUSIC_FrameCallback);
}
void FINALEWINMUSIC_FrameCallback()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client) || !IsSurvivor(client) || IsFakeClient(client)) continue;

		switch (IsL4D1Survivor(client))
		{
			case true:
			{
				SDK_StopMusic(client, "Event.ScenarioWin");
				SDK_PlayMusic(client, "Event.ScenarioWin_L4D1", client);
				return;
			}
			default:
			{
				SDK_StopMusic(client, "Event.ScenarioWin_L4D1");
				SDK_PlayMusic(client, "Event.ScenarioWin", client);
				return;
			}
		}
	}
}

void StopMusic(int client, float one_float = 0.0)
{
	SDK_StopMusic(client, "Event.Down_L4D1", one_float);
	SDK_StopMusic(client, "Event.Down", one_float);
	SDK_StopMusic(client, "Event.SurvivorDeath_L4D1", one_float);
	SDK_StopMusic(client, "Event.SurvivorDeath", one_float);
	SDK_StopMusic(client, "Event.ScenarioLose_L4D1", one_float);
	SDK_StopMusic(client, "Event.ScenarioLose", one_float);
	SDK_StopMusic(client, "Event.BleedingOut_L4D1", one_float);
	SDK_StopMusic(client, "Event.BleedingOut", one_float);
}

#if DEBUG
void Debug_PrintText(const char[] format, any unused)
{
	char buffer[256];
	VFormat(buffer, sizeof(buffer), format, 2);
	
	LogMessage(buffer);
	
	int AdminId adminId;
	for (int client = 1; client <= MaxClients; client++) {
		if (!IsClientInGame(client) || IsFakeClient(client)) {
			continue;
		}
		
		adminId = GetUserAdmin(client);
		if (adminId == INVALID_ADMIN_ID || !GetAdminFlag(adminId, Admin_Root)) {
			continue;
		}
		
		PrintToChat(client, DEBUG_PRINT_FORMAT, DEBUG_TAG, buffer);
	}
}
#endif

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

bool IsSurvivor(int client)
{
	if (!IsValidClient(client)) return false;
	if (GetClientTeam(client) != 2 && GetClientTeam(client) != 4) return false;
	return true;
}

bool IsL4D1Survivor(int client)
{
	if (IsSurvivor(client))
	{
		char model[42];
		//GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		GetClientModel(client, model, sizeof(model));
		if (StrEqual(model, MODEL_FRANCIS, false) || StrEqual(model, MODEL_LOUIS, false) 
			|| StrEqual(model, MODEL_BILL, false) || StrEqual(model, MODEL_ZOEY, false))
		{
			return true;
		}
		/*int netchar = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if (netchar >= 4 && netchar <= 7)
		{
			return true;
		}*/
	}
	return false;
}

bool IsIncapped(int client)
{ return GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0; }

/*void FakeCHEAT(int client, const char[] sCommand, const char[] sArgument)
{
	int iFlags = GetCommandFlags(sCommand);
	SetCommandFlags(sCommand, iFlags & ~FCVAR_CHEAT);
	ClientCommand(client, "%s %s", sCommand, sArgument);
	SetCommandFlags(sCommand, iFlags & FCVAR_CHEAT);
}*/

void SDK_PlayMusic(int client, const char[] music_str, int source_ent = 0, float one_float = 0.0, bool one_bool = false, bool two_bool = false)
{
	Address music_address = GetEntityAddress(client)+(view_as<Address>(GetEntSendPropOffs(client, "m_music")));
	SDKCall(hMusicPlay, music_address, music_str, source_ent, one_float, one_bool, two_bool);
}

void SDK_StopMusic(int client, const char[] music_str, float one_float = 0.0, bool one_bool = false)
{	
	Address music_address = GetEntityAddress(client)+(view_as<Address>(GetEntSendPropOffs(client, "m_music")));
	SDKCall(hMusicStopPlaying, music_address, music_str, one_float, one_bool);
}

/*void PlayAmbientMusic(int client, const char[] music_str) // !!USELESS, it plays globally for all players!
{
	int music_ent = CreateEntityByName("ambient_music");
	DispatchKeyValue(music_ent, "message", music_str);
	DispatchSpawn(music_ent);
	ActivateEntity(music_ent);
	AcceptEntityInput(music_ent, "PlaySound");
}*/

/*void Logic_RunScript(const char[] sCode, any ...) 
{
	int iScriptLogic = FindEntityByTargetname(-1, PLUGIN_SCRIPTLOGIC);
	if (!iScriptLogic || !IsValidEntity(iScriptLogic))
	{
		iScriptLogic = CreateEntityByName("logic_script");
		DispatchKeyValue(iScriptLogic, "targetname", PLUGIN_SCRIPTLOGIC);
		DispatchSpawn(iScriptLogic);
	}
	
	char sBuffer[512]; 
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
	
	SetVariantString(sBuffer); 
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}*/

void GetGamedata()
{
	char filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, sizeof(filePath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(filePath) )
	{
		hConf = LoadGameConfigFile(GAMEDATA); // For some reason this doesn't return null even for invalid files, so check they exist first.
	}
	else
	{
		PrintToServer("[SM] %s unable to get %s.txt gamedata file. Generating...", PLUGIN_NAME, GAMEDATA);
		
		Handle fileHandle = OpenFile(filePath, "w");
		if (fileHandle == null)
		{ SetFailState("[SM] Couldn't generate gamedata file!"); }
		
		WriteFileLine(fileHandle, "\"Games\"");
		WriteFileLine(fileHandle, "{");
		WriteFileLine(fileHandle, "	\"left4dead2\"");
		WriteFileLine(fileHandle, "	{");
		WriteFileLine(fileHandle, "		\"Signatures\"");
		WriteFileLine(fileHandle, "		{");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_MusicPlay);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_MusicPlay_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_MusicPlay_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_MusicPlay_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_MusicStopPlaying);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_MusicStopPlaying_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_MusicStopPlaying_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_MusicStopPlaying_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "		}");
		WriteFileLine(fileHandle, "	}");
		WriteFileLine(fileHandle, "}");
		
		CloseHandle(fileHandle);
		hConf = LoadGameConfigFile(GAMEDATA);
		if (hConf == null)
		{ SetFailState("[SM] Failed to load auto-generated gamedata file!"); }
		
		PrintToServer("[SM] %s successfully generated %s.txt gamedata file!", PLUGIN_NAME, GAMEDATA);
	}
	PrepSDKCall();
}

void PrepSDKCall()
{
	if (hConf == null)
	{ SetFailState("Unable to find %s.txt gamedata.", GAMEDATA); return; }
	
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, NAME_MusicPlay))
	{ SetFailState("Unable to find %s signature in gamedata file.", NAME_MusicPlay); return; }
	//PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
	
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	hMusicPlay = EndPrepSDKCall();
	if (hMusicPlay == null)
	{ SetFailState("Cannot initialize %s SDKCall, signature is broken.", NAME_MusicPlay); return; }
	
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, NAME_MusicStopPlaying))
	{ SetFailState("Unable to find %s signature in gamedata file.", NAME_MusicStopPlaying); return; }
	//PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
	
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	hMusicStopPlaying = EndPrepSDKCall();
	if (hMusicStopPlaying == null)
	{ SetFailState("Cannot initialize %s SDKCall, signature is broken.", NAME_MusicStopPlaying); return; }
}