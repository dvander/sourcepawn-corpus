#define TFGG_MAIN
#define PLUGIN_VERSION "1.4"

#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <tfgungame>

#pragma semicolon 1
#pragma newdecls required

#include "tfgungame_ggweapon.sp"

//#define DEBUG

public Plugin myinfo =
{
	name = "TFGunGame: Redux",
	author = "Frosty Scales",
	description = "GunGame - Run through a series of weapons, first person to get a kill with the final weapon wins.",
	version = PLUGIN_VERSION,
	url = "https://github.com/koopa516"
};

#define MAX_WEAPONS 64

stock const char LASTRANK_SOUND[] = ""; // TODO
stock const char WIN_SOUND[] = ""; // TODO
stock const char HUMILIATION_SOUND[] = ""; // TODO
stock const char strCleanTheseEntities[][256] = 
{
	"info_populator",
	"info_passtime_ball_spawn",
	"tf_logic_arena",
	"tf_logic_hybrid_ctf_cp",
	"tf_logic_koth",
	"tf_logic_mann_vs_machine",
	"tf_logic_medieval",
	"tf_logic_multiple_escort",
	"tf_logic_player_destruction",
	"tf_logic_robot_destruction",
	"team_control_point",
	"team_control_point_master",
	"team_control_point_round",
	"team_train_watcher",
	"item_teamflag",
	"trigger_capture_area",
	"trigger_passtime_ball",
	"trigger_rd_vault_trigger"
};

stock const int g_iClassMaxHP[TFClassType] =
{
	0,
	125,
	125,
	200,
	175,
	150,
	300,
	175,
	125,
	125
};

const float HINT_REFRESH_INTERVAL = 5.0;

int g_iRank[MAXPLAYERS+1];
int g_iRankBuffer[MAXPLAYERS+1];
int g_iAssists[MAXPLAYERS+1];
bool g_bCooldownWeps[MAXPLAYERS+1];
bool g_bResetOnSpawn[MAXPLAYERS+1];
bool g_bLate;
bool g_bRoundActive;

Handle g_hGetMaxAmmo;
Handle g_hGetMaxClip1;

Handle hFwdOnWin;
Handle hFwdRankUp;
Handle hFwdRankDown;

ConVar g_hCvarSpawnProtect;
ConVar g_hCvarAllowSuicide;
ConVar g_hCvarLastRankSound;
ConVar g_hCvarWinSound;
ConVar g_hCvarHumiliationSound;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;
	
	CreateNative("GGWeapon.GGWeapon", Native_GGWeapon);
	CreateNative("GGWeapon.Init", Native_GGWeaponInit);
	CreateNative("GGWeapon.InitSeries", Native_GGWeaponInitSeries);
	CreateNative("GGWeapon.Total", Native_GGWeaponTotal);
	CreateNative("GGWeapon.SeriesTotal", Native_GGWeaponSeriesTotal);
	CreateNative("GGWeapon.GetFromIndex", Native_GGWeaponGetFromIndex);
	CreateNative("GGWeapon.PushToSeries", Native_GGWeaponPushToSeries);
	CreateNative("GGWeapon.GetFromSeries", Native_GGWeaponGetFromSeries);
	CreateNative("GGWeapon.GetFromAll", Native_GGWeaponGetFromAll);
	CreateNative("GGWeapon.GetName", Native_GGWeaponGetName);
	CreateNative("GGWeapon.GetClassname", Native_GGWeaponGetClassname);
	CreateNative("GGWeapon.GetAttributeOverride", Native_GGWeaponGetAttributeOverride);
	CreateNative("GGWeapon.Index.get", Native_GGWeaponIndex);
	CreateNative("GGWeapon.Class.get", Native_GGWeaponClass);
	CreateNative("GGWeapon.Slot.get", Native_GGWeaponSlot);
	CreateNative("GGWeapon.Disabled.get", Native_GGWeaponDisabled);
	CreateNative("GGWeapon.FlagsOverride.get", Native_GGWeaponFlagsOverride);
	CreateNative("GGWeapon.ClipOverride.get", Native_GGWeaponClipOverride);
	
	CreateNative("GetGunGameRank", Native_GetRank);
	CreateNative("ForceGunGameWin", Native_ForceWin);
	CreateNative("ForceGunGameRank", Native_ForceRank);
	CreateNative("ForceGunGameRankUp", Native_ForceRankUp);
	CreateNative("ForceGunGameRankDown", Native_ForceRankDown);
	
	hFwdOnWin = CreateGlobalForward("OnGunGameWin", ET_Ignore, Param_Cell);
	hFwdRankUp = CreateGlobalForward("OnGunGameRankUp", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	hFwdRankDown = CreateGlobalForward("OnGunGameRankDown", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("tfggr_version", PLUGIN_VERSION, "Plugin Version", FCVAR_ARCHIVE);
	g_hCvarSpawnProtect = 		CreateConVar("tfgg_spawnprotect_length", "-1.0", "Length of the spawn protection for players, set to 0.0 to disable and -1.0 for infinite length", true);
	g_hCvarAllowSuicide = 		CreateConVar("tfgg_allow_suicide", "0", "Set to 1 to not humiliate players when they suicide", _, true, 0.0, true, 1.0);
	g_hCvarLastRankSound = 		CreateConVar("tfgg_last_rank_sound", LASTRANK_SOUND, "Sound played when someone has hit the last rank");
	g_hCvarWinSound = 			CreateConVar("tfgg_win_sound", WIN_SOUND, "Sound played when someone wins the game");
	g_hCvarHumiliationSound = 	CreateConVar("tfgg_humiliation_sound", HUMILIATION_SOUND, "Sound played on humiliation");
	
	g_hCvarLastRankSound.AddChangeHook(OnChangeSound);
	g_hCvarWinSound.AddChangeHook(OnChangeSound);
	g_hCvarHumiliationSound.AddChangeHook(OnChangeSound);
	
	GGWeapon.Init();
	HookEvent("teamplay_round_start", 			OnTFRoundStart);
	HookEvent("teamplay_round_start", 			OnTFRoundStartPre,		EventHookMode_Pre);
	HookEvent("player_spawn", 					OnReloadPlayerWeapons, 	EventHookMode_Pre);
	HookEvent("post_inventory_application", 	OnReloadPlayerWeapons);
	HookEvent("player_death", 					OnPlayerDeath);
	HookEvent("player_death", 					OnPlayerDeathPre, 		EventHookMode_Pre);
	
	if (g_bLate)
	{
		ServerCommand("mp_restartgame 1");
		PrintToChatAll("\x07FFA500[GunGame]\x07FFFFFF Late-load detected! Restarting round...");
	}
	
	ServerCommand("mp_respawnwavetime 0");
	ServerCommand("tf_use_fixed_weaponspreads 1");
	ServerCommand("tf_damage_disablespread 1");
	ServerCommand("tf_weapon_criticals 0");
	ServerCommand("mp_autoteambalance 1");
	
	RegConsoleCmd("gg_help", Command_Help, "Sends a player a help panel");
	
	PrepSDK();
	
	LoadTranslations("tfgungame.phrases");
	
	//PrecacheSound(LASTRANK_SOUND, true);
	//PrecacheSound(WIN_SOUND, true);
	//PrecacheSound(HUMILIATION_SOUND, true);
}

public void OnMapStart()
{
	LoadTranslations("tfgungame.phrases");
	
	CleanLogicEntities();
}

void CleanLogicEntities()
{
	for (int i = 0; i <= 2048; i++)
	{
		if (!IsValidEntity(i)) continue;
		
		char strClassname[255];
		GetEntityClassname(i, strClassname, sizeof(strClassname));
		
		for (int j = 0; j < sizeof(strCleanTheseEntities); j++)
		{
			if (StrEqual(strClassname, strCleanTheseEntities[j]))
			{
				AcceptEntityInput(i, "Kill");
			}
		}
	}
}

public void OnChangeSound(ConVar hConVar, const char[] strOldValue, const char[] strNewValue)
{
	if (FileExists(strNewValue)) PrecacheSound(strNewValue);
	else
	{
		char strName[255];
		hConVar.GetName(strName, sizeof(strName));
		LogError("Invalid file location \"%s\" set in cvar \"%s\", resetting to previous value \"%s\"", strNewValue, strName, strOldValue);
		
		hConVar.SetString(strOldValue);
	}
}

void PrepSDK()
{
	Handle hGameData = LoadGameConfigFile("tf2gungame");
	
	if (hGameData == null)
		SetFailState("[GunGame] Unable to load GameData! (gamedata/tf2gungame.txt)");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::GetMaxAmmo");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	g_hGetMaxAmmo = EndPrepSDKCall();
	if (g_hGetMaxAmmo == null)
		SetFailState("[GunGame] Couldn't load SDK Call CTFPlayer::GetMaxAmmo");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFWeaponBase::GetMaxClip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	g_hGetMaxClip1 = EndPrepSDKCall();
	if (g_hGetMaxClip1 == null)
		SetFailState("[GunGame] Couldn't load SDK Call CTFWeaponBase::GetMaxClip1");

	delete hGameData;
}

int GetMaxAmmo(int iClient, int iAmmoType, TFClassType iClass)
{ 
	if (iAmmoType == -1 || !iClass)
		return -1;
	
	if (g_hGetMaxAmmo == null)
	{
		LogError("[GunGame] SDK Call for GetMaxAmmo is invalid!");
		return -1;
	}
	
	return SDKCall(g_hGetMaxAmmo, iClient, iAmmoType, iClass);
}

stock int GetWeaponMaxAmmo(int iClient, int iWeapon)
{
	return GetMaxAmmo(iClient, GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType", 1), TF2_GetPlayerClass(iClient));
}

stock int GetSlotMaxAmmo(int iClient, int iSlot, TFClassType iClass = TFClass_Unknown)
{
	int iWep = GetPlayerWeaponSlot(iClient, iSlot);
	if (iWep == -1)
		return -1;
	
	if (iClass == TFClass_Unknown)
		iClass = TF2_GetPlayerClass(iClient);
	
	return GetMaxAmmo(iClient, GetEntProp(iWep, Prop_Send, "m_iPrimaryAmmoType", 1), iClass);
}

stock int GetMaxClip(int iWeapon)
{ 
	if (g_hGetMaxClip1 == INVALID_HANDLE)
	{
		LogError("[GunGame] SDK Call for GetMaxClip1 is invalid!");
		return -1;
	}
	
	return SDKCall(g_hGetMaxClip1, iWeapon);
}

public void OnClientPostAdminCheck(int client)
{
#if defined DEBUG
	if (IsFakeClient(client))
	{
		// Give joining bots a random rank for testing
		g_iRank[client] = GetRandomInt(0, GGWeapon.Total() - 1);
	}
#endif
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsValidClient(client)) return Plugin_Continue;
	
	if (buttons & IN_ATTACK || buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT || TF2_IsPlayerInCondition(client, TFCond_Taunting))
		if (GetEntProp(client, Prop_Send, "m_nPlayerCond") == 32)
			TF2_RemoveCondition(client, TFCond_Ubercharged);
	
	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (IsValidEntity(entity) && StrEqual(classname, "tf_wearable_demoshield"))
		AcceptEntityInput(entity, "Kill");
}

public Action OnTFRoundStartPre(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Continue;
}

public Action OnTFRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	GenerateRoundWeps();
	
	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		g_iRank[i] = 0;
	}
	
	g_bRoundActive = true;
	
	Handle hTimer = CreateTimer(HINT_REFRESH_INTERVAL, RefreshCheapHintText, _, TIMER_REPEAT);
	RefreshCheapHintText(hTimer);
	
	PrintToChatAll("\x07FFA500[GunGame]\x07FFFFFF PROTIP: You can type \x07FF5555!gg_help\x07FFFFFF for some information about the gamemode!");
	
	
	CreateTimer(5.0, CleanEnts);
	return Plugin_Continue;
}

public Action CleanEnts(Handle hTimer)
{
	CleanLogicEntities();
}

public Action RefreshCheapHintText(Handle hTimer)
{
	RefreshScores();
}

void RefreshScores()
{
	char strText[1024];
	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		
		TFTeam eTeam = TF2_GetClientTeam(i);
		if (eTeam == TFTeam_Unassigned || eTeam == TFTeam_Spectator) continue;

		char strWeps[3][48];
		char strNextWeps[216], strAssist[128];
		GGWeapon hWeapon;
		
		int iTotal = GGWeapon.SeriesTotal();
		
		if (g_iRank[i] >= iTotal)
			break;
		
		if (g_iRank[i] < iTotal - 3)
		{
			for (int j = 0; j < 3; j++)
			{
				hWeapon = GGWeapon.GetFromSeries(g_iRank[i] + (j + 1));
				hWeapon.GetName(strWeps[j], sizeof(strWeps[]));
			}
			
			Format(strNextWeps, sizeof(strNextWeps), "\n\nNext Weapons:\n%s\n%s\n%s", strWeps[0], strWeps[1], strWeps[2]);
		}
		else if (g_iRank[i] == iTotal - 3)
		{
			hWeapon = GGWeapon.GetFromSeries(g_iRank[i] + 1);
			hWeapon.GetName(strWeps[0], sizeof(strWeps[]));
			hWeapon = GGWeapon.GetFromSeries(g_iRank[i] + 2);
			hWeapon.GetName(strWeps[1], sizeof(strWeps[]));
			Format(strNextWeps, sizeof(strNextWeps), "\n\nNext Weapons:\n%s\n%s", strWeps[0], strWeps[1]);
		}
		else if (g_iRank[i] == iTotal - 2)
		{
			hWeapon = GGWeapon.GetFromSeries(g_iRank[i] + 1);
			hWeapon.GetName(strWeps[0], sizeof(strWeps[]));
			Format(strNextWeps, sizeof(strNextWeps), "\n\nNext Weapon:\n%s", strWeps[0]);
		}
		else
			Format(strNextWeps, sizeof(strNextWeps), "");
		
		char strWep[128];
		hWeapon = GGWeapon.GetFromSeries(g_iRank[i]);
		hWeapon.GetName(strWep, sizeof(strWep));
		Format(strAssist, sizeof(strAssist), "%s", (g_iAssists[i] == 1) ? "\n\nYou're one assist away from ranking up!" : "");
		Format(strText, sizeof(strText), "Current Weapon:\n%s%s%s", strWep, strNextWeps, strAssist);
		
		//for (int j = 1; j < MaxClients; j++)
		//	if (j != i && TF2_GetClientTeam(j) == TFTeam_Spectator && GetEntPropEnt(j, Prop_Send, "m_hObserverTarget") == i)
		//		PrintKeyHintText(j, strText);
		
		PrintKeyHintText(i, strText);
	}
}

void PrintKeyHintText(int client, char[] buffer)
{
	BfWrite hBuffer = view_as<BfWrite>(StartMessageOne("KeyHintText", client)); 
	hBuffer.WriteByte(1); 
	hBuffer.WriteString(buffer); 
	EndMessage();
	return;
}

public Action OnReloadPlayerWeapons(Event event, const char[] name, bool dontBroadcast)
{
	// Get Client and check validity
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(iClient)) return Plugin_Handled;
	
	if (!IsFakeClient(iClient))
	{
		if (g_hCvarSpawnProtect.FloatValue == -1.0)
			TF2_AddCondition(iClient, TFCond_Ubercharged);
		else if (g_hCvarSpawnProtect.FloatValue > 0.0)
			TF2_AddCondition(iClient, TFCond_Ubercharged, g_hCvarSpawnProtect.FloatValue);
	}

	if (!g_bCooldownWeps[iClient])
		RequestFrame(ReloadWeaponsFrame, iClient);
	
	if (g_bResetOnSpawn[iClient])
	{
		g_bResetOnSpawn[iClient] = false;
		RequestFrame(ReloadWeaponsFrame, iClient);
	}

	return Plugin_Continue;
}

public void ReloadWeaponsFrame(any data)
{
	SetPlayerWeapon(data, g_iRank[data], true);
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	int iAssister = GetClientOfUserId(event.GetInt("assister"));
	int iCustomKill = event.GetInt("customkill");
	
	if (!IsValidClient(iAttacker)) return Plugin_Handled;
	
	if (iCustomKill == TF_CUSTOM_TRIGGER_HURT || !g_bRoundActive || 
		(iCustomKill == TF_CUSTOM_SUICIDE || iAttacker == iVictim) && g_hCvarAllowSuicide.IntValue)
			return Plugin_Continue;

	char strWeapon[128];
	event.GetString("weapon_logclassname", strWeapon, sizeof(strWeapon));

#if defined DEBUG
	PrintToChatAll(strWeapon);
#endif
	
	if (!(iCustomKill == TF_CUSTOM_SUICIDE || iAttacker == iVictim))
	{
		g_iRankBuffer[iAttacker]++;
		RequestFrame(RankUpBuffered, iAttacker);
		
		Call_StartForward(hFwdRankUp);
		Call_PushCell(iAttacker);
		Call_PushCell(iVictim);
		Call_PushCell(g_iRank[iAttacker]);
		Call_PushCell(GGWeapon.GetFromSeries(g_iRank[iAttacker]));
		Call_PushCell(GGWeapon.GetFromSeries(g_iRank[iAttacker] + 1));
		Call_Finish();
	}
	
	if (iAssister && IsValidClient(iAssister) && iAssister != iAttacker && iAssister != iVictim && !(iCustomKill == TF_CUSTOM_SUICIDE || iAttacker == iVictim))
	{
		if (g_iAssists[iAssister] == 1)
		{
			g_iAssists[iAssister] = 0;
			g_iRankBuffer[iAssister]++;
			RequestFrame(RankUpBuffered, iAssister);
			
			Call_StartForward(hFwdRankUp);
			Call_PushCell(iAssister);
			Call_PushCell(iVictim);
			Call_PushCell(g_iRank[iAssister]);
			Call_PushCell(GGWeapon.GetFromSeries(g_iRank[iAssister]));
			Call_PushCell(GGWeapon.GetFromSeries(g_iRank[iAssister] + 1));
			Call_Finish();
		}
		else
			g_iAssists[iAssister]++;
	}
	
	if (StrEqual(strWeapon, "sledgehammer") || (iCustomKill == TF_CUSTOM_SUICIDE || iAttacker == iVictim) && !g_hCvarAllowSuicide.IntValue)
	{
		if (g_iRank[iVictim] > 0)
			PrintToChat(iVictim, "\x07FFA500[GunGame] HUMILIATION! %t", "Humiliation");
		else
			PrintToChat(iVictim, "\x07FFA500[GunGame] HUMILIATION!");
		
		char strSound[255];
		g_hCvarHumiliationSound.GetString(strSound, sizeof(strSound));
		EmitSoundToAll(strSound, .level = SNDLEVEL_ROCKET);
		
		RequestFrame(RankDownBuffered, iVictim);
		
		Call_StartForward(hFwdRankDown);
		Call_PushCell(iAttacker);
		Call_PushCell(iVictim);
		Call_PushCell(g_iRank[iVictim]);
		Call_PushCell(GGWeapon.GetFromSeries(g_iRank[iVictim]));
		Call_PushCell(GGWeapon.GetFromSeries(g_iRank[iVictim] + 1));
		Call_Finish();
	}

	return Plugin_Continue;
}

public void OnPlayerDeathPre(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	RequestFrame(Respawn, GetClientSerial(iVictim));
}
	

public void Respawn(any serial)
{
	//Instant Respawn
	int iClient = GetClientFromSerial(serial);
	if (iClient != 0)
	{
		int team = GetClientTeam(iClient);
		if (!IsPlayerAlive(iClient) && team != 1)
		{
			TF2_RespawnPlayer(iClient);
		}
	}
}

public void RankUpBuffered(int iAttacker)
{
	int iTotal = GGWeapon.SeriesTotal();
	int iAmt = g_iRankBuffer[iAttacker];
	g_iRankBuffer[iAttacker] = 0;

	if (RankUp(iAttacker, iAmt) <= iTotal - 1)
	{
		
		SetPlayerWeapon(iAttacker, g_iRank[iAttacker]);
		if (!IsPlayerAlive(iAttacker))
			g_bResetOnSpawn[iAttacker] = true;
		
		if (g_iRank[iAttacker] == iTotal - 1)
		{
			PrintToChatAll("\x07FFA500[GunGame] %N %t", iAttacker, "GoldenWrench");
			
			char strSound[255];
			g_hCvarLastRankSound.GetString(strSound, sizeof(strSound));
			EmitSoundToAll(strSound, .level = SNDLEVEL_ROCKET);
		}
	}
	else
		WinPlayer(iAttacker);
}

public void RankDownBuffered(int iVictim)
{
	if (g_iRank[iVictim] > 0) RankUp(iVictim, -1);

	SetPlayerWeapon(iVictim, g_iRank[iVictim]);
	if (!IsPlayerAlive(iVictim))
	{
		g_bResetOnSpawn[iVictim] = true;
	}
}

int RankUp(int iClient, int iAmount = 1)
{
	g_iRank[iClient] += iAmount;
	return g_iRank[iClient];
}

void WinPlayer(int iClient)
{
	PrintToChatAll("\x07FFA500[GunGame] %N %t", iClient, "WonMatch");
	
	char strSound[255];
	g_hCvarWinSound.GetString(strSound, sizeof(strSound));
	EmitSoundToAll(strSound, .level = SNDLEVEL_ROCKET);
	
	int iEnt = FindEntityByClassname(iEnt, "game_round_win");
	
	if (iEnt < 1)
	{
		iEnt = CreateEntityByName("game_round_win");
		if (IsValidEntity(iEnt))
			DispatchSpawn(iEnt);
		else
			ThrowError("[GunGame] Could not spawn round win entity!");
	}
	
	SetVariantInt(view_as<int>(TF2_GetClientTeam(iClient)));
	AcceptEntityInput(iEnt, "SetTeam");
	AcceptEntityInput(iEnt, "RoundWin");
	g_bRoundActive = false;
	
	Call_StartForward(hFwdOnWin);
	Call_PushCell(iClient);
	Call_Finish();
}

stock bool IsValidClient(int iClient)
{
	return !(iClient <= 0
			|| iClient > MaxClients
			|| !IsClientInGame(iClient)
			|| !IsClientConnected(iClient)
			|| GetEntProp(iClient, Prop_Send, "m_bIsCoaching")
			|| IsClientSourceTV(iClient)
			|| IsClientReplay(iClient));
}

void SetPlayerWeapon(int iClient, int iRank, bool refresh = false)
{
	if (!IsValidClient(iClient)) return;

	if (iRank >= GGWeapon.SeriesTotal()) return;
	
	GGWeapon hWeapon = GGWeapon.GetFromSeries(iRank);

	TFClassType eClass = hWeapon.Class;
	TF2_SetPlayerClass(iClient, eClass, _, true);

	g_bCooldownWeps[iClient] = true;

	SetEntityHealth(iClient, g_iClassMaxHP[view_as<int>(eClass)]);
	
	TF2_RemoveAllWeapons(iClient);
	
	char strClassname[128], strAttributes[128];
	hWeapon.GetClassname(strClassname, sizeof(strClassname));
	hWeapon.GetAttributeOverride(strAttributes, sizeof(strAttributes));
	
	int iWeapon = CreateWeapon(iClient, strClassname, hWeapon.Index, 1, 1, strAttributes, hWeapon.FlagsOverride);
	FlagWeaponDontDrop(iWeapon);
	
	if (hWeapon.ClipOverride)
		SetEntData(iWeapon, FindSendPropInfo("CTFWeaponBase", "m_iClip1"), hWeapon.ClipOverride, _, true);
	else if (hWeapon.Index == 741) // Rainblower fix, thanks to Benoist3012
		SetEntProp(iWeapon, Prop_Send, "m_nModelIndexOverrides", GetEntProp(iWeapon, Prop_Send, "m_nModelIndexOverrides", _, 3), _, 0);
	
	SetMaxAmmo(iClient, iWeapon);
	EquipPlayerWeapon(iClient, iWeapon);
	if (!IsFakeClient(iClient))
		EquipPlayerWeapon(iClient, CreateWeapon(iClient, "tf_weapon_fireaxe", 153, 50, 6, ""));

	if (refresh) RefreshScores();

	CreateTimer(0.1, RemoveWepCooldown, iClient);
}

void GenerateRoundWeps()
{
	GGWeapon.InitSeries();

	KeyValues hKvConfig = new KeyValues("WeaponSeries");
	char strPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, strPath, PLATFORM_MAX_PATH, "configs/gungame-series.cfg");
	hKvConfig.ImportFromFile(strPath);
	
	if (hKvConfig == null)
		SetFailState("[GunGame] Config file not found or invalid!");
	
	char strSectionName[128];
	hKvConfig.GetSectionName(strSectionName, sizeof(strSectionName));
	if (!StrEqual("WeaponSeries", strSectionName))
		SetFailState("[GunGame] Config file is invalid!");
	
	if (!hKvConfig.GotoFirstSubKey())
		SetFailState("[GunGame] Config file has no weapons!");

	int j;
	do
	{
		GGWeapon hWeapon;
		int iIndex = hKvConfig.GetNum("index_override", 0);
		if (iIndex)
		{
			hWeapon = GGWeapon.GetFromIndex(iIndex);
		}
		else
		{
			ArrayList hTemp = new ArrayList();
			for (int i = 0; i < GGWeapon.Total(); i++)
			{
				hWeapon = GGWeapon.GetFromAll(i);
				if (hWeapon.Class == view_as<TFClassType>(hKvConfig.GetNum("class")) && hWeapon.Slot == hKvConfig.GetNum("slot") && !hWeapon.Disabled)
					hTemp.Push(hWeapon);
			}
			
			if (hTemp.Length == 0)
				hWeapon = view_as<GGWeapon>(INVALID_HANDLE);
			else
				hWeapon = view_as<GGWeapon>(hTemp.Get(GetRandomInt(0, hTemp.Length - 1)));
		}
		
		if (hWeapon != null)
		{
			j++;
			char strWeapon[128];
			hWeapon.GetName(strWeapon, 128);
			PrintToServer("[GunGame] Added Weapon %d: %d (%s)", j, hWeapon.Index, strWeapon);
			GGWeapon.PushToSeries(hWeapon);
		}
	}
	while (hKvConfig.GotoNextKey());
}

public Action RemoveWepCooldown(Handle hTimer, int iClient)
{
	g_bCooldownWeps[iClient] = false;
}

stock int CreateWeapon(int client, char[] sName, int index, int level = 1, int qual = 1, char[] att, int flags = OVERRIDE_ALL | PRESERVE_ATTRIBUTES)
{
	Handle hWeapon = TF2Items_CreateItem(flags);
	if (hWeapon == INVALID_HANDLE)
		return -1;
	
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	TF2Items_SetClassname(hWeapon, sName);

	char atts[32][32];
	int count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 1)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);

		for (int j, i; i < count; i += 2, j++)
			TF2Items_SetAttribute(hWeapon, j, StringToInt(atts[i]), StringToFloat(atts[i+1]));
	}
	else if (flags & ~PRESERVE_ATTRIBUTES)
		TF2Items_SetNumAttributes(hWeapon, 0);

	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	delete hWeapon;
	return entity;
}

void FlagWeaponDontDrop(int iWeapon)
{
	// Big thanks to Benoist3012 for this func
	int iItemOffset = GetEntSendPropOffs(iWeapon, "m_Item", true);
	if (iItemOffset <= 0) return;

	Address pWeapon = GetEntityAddress(iWeapon);
	if (pWeapon == Address_Null) return;

	StoreToAddress(view_as<Address>((view_as<int>(pWeapon)) + iItemOffset + 36), 0x23E173A2, NumberType_Int32);
	SetEntProp(iWeapon, Prop_Send, "m_bValidatedAttachedEntity", 1);
}

void SetMaxAmmo(int iClient, int iWeapon, int iForceAmmo = -1)
{
	int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
	int iMaxAmmo = GetWeaponMaxAmmo(iClient, iWeapon);
	
	if (iAmmoType != -1 && iMaxAmmo != -1)
		SetEntProp(iClient, Prop_Data, "m_iAmmo", (iForceAmmo == -1) ? iMaxAmmo : iForceAmmo, _, iAmmoType);
}

public any Native_GetRank(Handle plugin, int numParams)
{
	return g_iRank[GetNativeCell(1)];
}

public any Native_ForceRank(Handle plugin, int numParams)
{
	int iRank = GetNativeCell(2);
	int iClient = GetNativeCell(1);
	
	if (iRank >= 0 && iRank < GGWeapon.SeriesTotal())
		return false;
	
	g_iRank[iClient] = iRank;
	return true;
}

public any Native_ForceWin(Handle plugin, int numParams)
{
	WinPlayer(GetNativeCell(1));
	return;
}

public any Native_ForceRankUp(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	
	if (g_iRank[iClient]+1 >= GGWeapon.SeriesTotal())
		return false;
	
	RankUp(iClient);
	SetPlayerWeapon(iClient, g_iRank[iClient]);
	return true;
}

public any Native_ForceRankDown(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	
	if (!g_iRank[iClient])
		return false;
	
	RankUp(iClient, -1);
	SetPlayerWeapon(iClient, g_iRank[iClient]);
	return true;
}

public Action Command_Help(int iClient, int iArgs)
{
	// {orange}[GunGame]{white} In GunGame the objective is to kill other players,
	// which changes your weapon to another one. The goal is to get through every 
	// weapon until you win! However, if you get hit by a melee weapon or kill yourself,
	// you get set back one rank.
	ReplyToCommand(iClient, "\x07FFA500[GunGame]\x07FFFFFF %t", "HelpString");
}
