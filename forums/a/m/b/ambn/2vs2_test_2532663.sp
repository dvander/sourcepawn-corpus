#include <sourcemod>
#include <sdktools>
#pragma newdecls required
#define Plugin_Version "2.3.9 (Final Version)"
#define MSGTAG " \x02[Retakes]\x05"
//////////////////////////////////////////////////////////
//ConVars
ConVar i_nMaxReady = null;
ConVar i_nReadySys = null;
//ConVar i_nRecStatics = null;
//Booleans
bool IsOnEditMode[MAXPLAYERS+1] = false;
bool IsSpawnTaken[256] = false;
bool IsClientReady[MAXPLAYERS+1] = false;
bool IsMatchLive = false;
bool IsMatchSetup = false;
bool IsUserHaveWep[MAXPLAYERS] = false;
bool IsUserHavePistol[MAXPLAYERS] = false;
//bool IsRecEnable = false;
//Ints
int i_hReadyNum = 0;
//int SpawnNum = 0;
//Strings
char h_iMapName[32];
char h_iPrimaryWeapon[MAXPLAYERS+1][32];
char h_iSecondaryWeapon[MAXPLAYERS+1][32];
char h_iExtraItem[MAXPLAYERS+1][32];
char h_iSideString[4];
char h_iSectionName[MAXPLAYERS+1][64];
char h_iWepClassName[MAXPLAYERS+1][32];
char h_iPistolClassName[MAXPLAYERS+1][32];
//Floats
//Handle
Handle g_iTimer;
//////////////////////////////////////////////////////////
public Plugin myinfo = {
	name = "[CS:GO] BlackRocks Retakes",
	author = "noBrain",
	description = "Allow server-side 2vs2 competitve matches and was made for CsGoBlackRocks Gaming Community",
	version = Plugin_Version,
};

public void OnPluginStart()
{
	//AdminCommands
	RegAdminCmd("sm_emode", Command_EditMode, ADMFLAG_ROOT);
	RegAdminCmd("sm_addspawn", Command_AddSpawn, ADMFLAG_ROOT);
	RegAdminCmd("sm_addbomb", Command_AddBombSpawn, ADMFLAG_ROOT);
	RegAdminCmd("sm_forcestop", Command_ForceStop, ADMFLAG_ROOT);
	RegAdminCmd("sm_fs", Command_ForceStop, ADMFLAG_ROOT);
	//ConosleCommands
	//RegConsoleCmd("sm_awp", Command_Awp);
	//RegConsoleCmd("sm_ak", Command_Ak);
	//RegConsoleCmd("sm_a1", Command_A1);
	//RegConsoleCmd("sm_a4", Command_A4);
	RegConsoleCmd("sm_ready", Command_Ready);
	RegConsoleCmd("sm_r", Command_Ready);
	RegConsoleCmd("sm_guns", Command_Guns);
	RegConsoleCmd("sm_unready", Command_UnReady);
	RegConsoleCmd("sm_ur", Command_UnReady);
	//Hooks
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_start", RoundStart, EventHookMode_Post);
	HookEvent("player_disconnect", PlayerDisconnect);
	HookEvent("cs_pre_restart", Event_ReRestart);
	//ConVars
	i_nMaxReady = CreateConVar("sm_max_ready_num", "4", "Max ready users needed to startup the match");
	i_nReadySys = CreateConVar("sm_use_ready_sys", "1", "Whether use ready system or not");
	//i_nRecStatics = CreateConVar("sm_r_data", "0", "Record player's data per player.");
	//Extra
	LoadTranslations("2vs2.phrases.txt"); 
	//LoadTranslations("ru/2vs2.phrases.txt"); 
	if (!DirExists("cfg/2vs2"))
	{
		CreateDirectory("cfg/2vs2", 511);
	}
}

public void OnMapStart()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			IsClientReady[client] = false;
		}
	}
	ConVar g_iConVar = null;
	ConVar g_iBuyMoney = null;
	ConVar g_iStartMoney = null;
	g_iConVar = FindConVar("mp_warmuptime");
	g_iBuyMoney = FindConVar("mp_maxmoney");
	g_iStartMoney = FindConVar("mp_startmoney");
	SetConVarInt(g_iConVar, 99999);
	SetConVarInt(g_iBuyMoney, 60000);
	SetConVarInt(g_iStartMoney, 60000);
	ServerCommand("mp_warmup_start");
	GetCurrentMap(h_iMapName, sizeof(h_iMapName));
	CMapFile(h_iMapName);
	PrintToServer("%s Map %s settings has been generated.", MSGTAG, h_iMapName);
	IsMatchLive = false;
}

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int team = GetEventInt(event, "team");
	if(team == 2)
	{
		if(IsUserHaveWep[client])
		{
			Format(h_iPrimaryWeapon[client], sizeof(h_iPrimaryWeapon[]), h_iWepClassName[client]);
		}
		else
		{
			Format(h_iPrimaryWeapon[client], sizeof(h_iPrimaryWeapon[]), "weapon_ak47");
		}
		if(IsUserHavePistol[client])
		{
			Format(h_iSecondaryWeapon[client], sizeof(h_iSecondaryWeapon[]), h_iPistolClassName[client]);
		}
		else
		{
			Format(h_iSecondaryWeapon[client], sizeof(h_iSecondaryWeapon[]), "weapon_glock");
		}
	}
	if(team == 3)
	{
		if(IsUserHaveWep[client])
		{
			Format(h_iPrimaryWeapon[client], sizeof(h_iPrimaryWeapon[]), h_iWepClassName[client]);
		}
		else
		{
			Format(h_iPrimaryWeapon[client], sizeof(h_iPrimaryWeapon[]), "weapon_m4a1");
		}
		if(IsUserHavePistol[client])
		{
			Format(h_iSecondaryWeapon[client], sizeof(h_iSecondaryWeapon[]), h_iPistolClassName[client]);
		}
		else
		{
			Format(h_iSecondaryWeapon[client], sizeof(h_iSecondaryWeapon[]), "weapon_hkp2000");
		}
	}
}

public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsClientConnected(client))
	{
		return;
	}
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
	{
		PrintToChat(client, "%T", "Warmup", client, MSGTAG);
		return;
	}
	ApplyWeapons(client);
	CreateTimer(0.1, Timer_SetupSpawn, client);
}

public Action Timer_SetupSpawn(Handle timer, any client)
{
	int SpawnNum = 0;
	char StrSpawnNum[4];
	//ApplyWeapons(client);
	int TeamNum = GetClientTeam(client);
	//GetRandomSide(StrSide);
	//Format(h_iSideString, sizeof(h_iSideString), StrSide);
	ServerCommand("tv_msg \"%s Retakes %s is now on.\"", MSGTAG, h_iSideString);
	if(HasBomb(client))
	{
		if(ApplyBombSpawn(client, h_iSideString, h_iMapName))
		{
			PrintHintText(client, " Retakes: <font color='#00ff55'>%s</font> \n<font color='#ff0000'>%d Ts</font> VS <font color='#00a1ff'>%d CTs</font>.", h_iSideString, GetTeamPlayers(2), GetTeamPlayers(3));
			PrintToChat(client, "%s Retake \x0E%s: \x02%d Ts \x05vs \x0B%d CTs.", MSGTAG, h_iSideString, GetTeamPlayers(2), GetTeamPlayers(3));
			PrintToChat(client, "%T", "Bomb", client, MSGTAG);
		}
		return;
	}
	int MaxTSpawn = GetMaxTeamSpawns(h_iSideString, "T", h_iMapName);
	int MaxCTSpawn = GetMaxTeamSpawns(h_iSideString, "CT", h_iMapName);
	if(TeamNum == 2)
	{
		SpawnNum = GetRandomInt(1, MaxTSpawn);
	}
	else if(TeamNum == 3)
	{
		SpawnNum = GetRandomInt(1, MaxCTSpawn);
	}
	IntToString(SpawnNum, StrSpawnNum, sizeof(StrSpawnNum));
	if(IsClientInGame(client) && IsPlayerAlive(client) && !IsClientSourceTV(client))
	{
		if(IsSpawnTaken[SpawnNum])
		{
			CreateTimer(0.1, Timer_SetupSpawn, client);
		}
		else if(ApplySpawn(client, StrSpawnNum, h_iSideString, h_iMapName))
		{
			IsSpawnTaken[SpawnNum] = true;
			PrintHintText(client, " Retakes: <font color='#00ff55'>%s</font> \n<font color='#ff0000'>%d Ts</font> VS <font color='#00a1ff'>%d CTs</font>.", h_iSideString, GetTeamPlayers(2), GetTeamPlayers(3));
			PrintToChat(client, "%s Retake \x0E%s: \x02%d Ts \x05vs \x0B%d CTs.", MSGTAG, h_iSideString, GetTeamPlayers(2), GetTeamPlayers(3));
			PrintToChat(client, "%T", "Spawn", client, MSGTAG);
		}
		else
		{
			ChangeClientTeam(client, 1);
			PrintToChat(client, "%T", "EnoughSpawns", client, MSGTAG);
		}
	}
}

public Action RoundStart(Handle event, const char[] name, bool dontBroadcast) 
{
	//PrintToChatAll("%s This plugin has been re-created for CsGoBlackRocks 2vs2 matches by \x02noBrain.", MSGTAG);
	//PrintToChatAll("%s Current plugin version: \x02%s", MSGTAG, Plugin_Version);
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
	{
		if(g_iTimer == null)
		{
			g_iTimer = CreateTimer(0.5, Timer_ReadyMessage, _, TIMER_REPEAT);
		}
		IsMatchLive = false;
		IsMatchSetup = false;
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				IsClientReady[client] = false;
			}
		}
		i_hReadyNum = 0;
		return;
	}
	else
	{
		if(g_iTimer != null)
		{
			KillTimer(g_iTimer);
			g_iTimer = null;
		}
	}
	if(GetAlivePlayers() == 0)
	{
		PrintToChatAll("%s Match Failed!", MSGTAG);
		IsMatchLive = false;
		IsMatchSetup = false;
		i_hReadyNum = 0;
		for(int user = 1; user <= MaxClients; user++)
		{
			if(IsClientInGame(user))
			{
				IsClientReady[user] = false;
			}
		}
		ConVar g_iBuyMoney = null;
		ConVar g_iStartMoney = null;
		g_iBuyMoney = FindConVar("mp_maxmoney");
		g_iStartMoney = FindConVar("mp_startmoney");
		SetConVarInt(g_iBuyMoney, 60000);
		SetConVarInt(g_iStartMoney, 60000);
		ServerCommand("mp_warmup_start");
		PrintToChatAll("%s Match force stopped.", MSGTAG);
		return;
	}
	if(!IsMatchSetup)
	{
		SetupMatch();
		//IsMatchSetup = true;
	}
	char StrSide[4];
	GetRandomSide(StrSide);
	Format(h_iSideString, sizeof(h_iSideString), StrSide);
	RemoveC4();
	int client = GetRandomPlayer(2);
	GivePlayerItem(client, "weapon_c4");
	if(IsMatchLive)
	{
		for(int i = 1 ; i <= MaxClients;  i++)
		{
			if(IsValidClient(i) && !IsClientReady[i] && GetConVarBool(i_nReadySys))
			{
				ChangeClientTeam(i, 1);
				PrintToChat(client, "%T", "Team", client, MSGTAG);
			}
		}
	}
}

public Action Timer_ReadyMessage(Handle iTimer)
{
	if(!GetConVarBool(i_nReadySys))
	{
		KillTimer(g_iTimer);
		g_iTimer = null;
		return Plugin_Stop;
	}
	int ReadyNumb = GetConVarInt(i_nMaxReady);
	for(int i = 1;i <= MaxClients; i++)
	{
		if(IsValidClient(i) && !IsClientReady[i])
		{
			PrintHintText(i, "Type <font color='#42d7f4'>!ready / !r</font> to become ready. \n Currently <font color='#bbf441'>%d/%d</font> players are ready", i_hReadyNum, ReadyNumb);
		}
		else if(IsValidClient(i) && IsClientReady[i])
		{
			PrintHintText(i, "You are marked as <font color='#42d7f4'>Ready</font>!\n Type <font color='#f4d442'>!unready / !ur</font> to become Unready! \n Currently <font color='#bbf441'>%d/%d</font> player(s) are ready", i_hReadyNum, ReadyNumb);
		}
	}
	return Plugin_Continue;
}

public Action PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientReady[client] && IsMatchLive && GetConVarBool(i_nReadySys))
	{
		ServerCommand("mp_pause_match");
		PrintToChatAll("%T", "DCReady", client, MSGTAG, i_hReadyNum);
		
	}
	if(IsClientReady[client] && !IsMatchLive && GetConVarBool(i_nReadySys))
	{
		IsClientReady[client] = false;
		i_hReadyNum = i_hReadyNum - 1;
		PrintToChat(client, "%T", "DCReady", client, MSGTAG, i_hReadyNum);
	}
	IsUserHavePistol[client] = false;
	IsUserHaveWep[client] = false;
	h_iPistolClassName[client] = "";
	h_iWepClassName[client] = "";
	return Plugin_Continue;
}

public Action Event_ReRestart(Handle event, const char[] name, bool dontBroadcast) 
{
	for(int spawns = 0; spawns < 256; spawns++)
	{
		IsSpawnTaken[spawns] = false;
	}
}

public Action Command_Ready(int client, int args)
{
	if(!GetConVarBool(i_nReadySys))
	{
		PrintToChat(client, "%T", "ReadyIsDis", client, MSGTAG);
		return Plugin_Handled;
	}
	if(IsClientReady[client])
	{
		PrintToChat(client, "%T", "MarkReady", client, MSGTAG);
		return Plugin_Handled;
	}
	if(GetClientTeam(client) == 1)
	{
		return Plugin_Handled;
	}
	if(IsMatchLive)
	{
		PrintToChat(client, "%T", "TooLateToReady", client, MSGTAG);
		return Plugin_Handled;
	}
	i_hReadyNum++;
	IsClientReady[client] = true;
	PrintToChat(client, "%T", "DMarkReady", client, MSGTAG);
	if(i_hReadyNum == GetConVarInt(i_nMaxReady))
	{
		int ReadyNumb = GetConVarInt(i_nMaxReady);
		PrintToChatAll("%T", "AlReady", client, MSGTAG, ReadyNumb);
		IsMatchLive = true;
		SetupMatch();
		return Plugin_Handled;
	}
	else
	{
		int ReadyNumb = GetConVarInt(i_nMaxReady);
		char StrUserName[MAX_NAME_LENGTH];
		GetClientName(client, StrUserName, sizeof(StrUserName));
		PrintToChatAll("%T", "NoStart", client, MSGTAG, StrUserName, ReadyNumb);
		return Plugin_Handled;
	}
}

public Action Command_UnReady(int client, int args)
{
	if(!GetConVarBool(i_nReadySys))
	{
		PrintToChat(client, "%T", "ReadyIsDis", client, MSGTAG);
		return Plugin_Handled;
	}
	if(!IsClientReady[client])
	{
		PrintToChat(client, "%T", "NotReady", client, MSGTAG);
		return Plugin_Handled;
	}
	if(GetClientTeam(client) == 1)
	{
		return Plugin_Handled;
	}
	if(IsMatchLive)
	{
		PrintToChat(client, "%T", "TooLateToUnReady", client, MSGTAG);
		return Plugin_Handled;
	}
	int ReadyNumb = GetConVarInt(i_nMaxReady);
	i_hReadyNum = i_hReadyNum - 1;
	char StrUserName[MAX_NAME_LENGTH];
	GetClientName(client, StrUserName, sizeof(StrUserName));
	IsClientReady[client] = false;
	PrintToChat(client, "%T", "DMarkUnReady", client, MSGTAG);
	PrintToChatAll("%T", "UnNoStart", client, MSGTAG, StrUserName, ReadyNumb);
	return Plugin_Handled;
}

/*
public Action Command_A1(int client, int args)
{
	if(GetClientTeam(client) != 3)
	{
		PrintToChat(client, "%T", "NotAvailable", client, MSGTAG);
		return Plugin_Handled;
	}
	Format(h_iPrimaryWeapon[client], sizeof(h_iPrimaryWeapon[]), "weapon_m4a1_silencer");
	PrintToChat(client, "%T", "M4A1", client, MSGTAG);
	IsUserHavingAwp[client] = false;
	return Plugin_Handled;
}
public Action Command_A4(int client, int args)
{
	if(GetClientTeam(client) != 3)
	{
		PrintToChat(client, "%T", "NotAvailable", client, MSGTAG);
		return Plugin_Handled;
	}
	Format(h_iPrimaryWeapon[client], sizeof(h_iPrimaryWeapon[]), "weapon_m4a1");
	PrintToChat(client, "%T", "M4A4", client, MSGTAG);
	IsUserHavingAwp[client] = false;
	return Plugin_Handled;
}
public Action Command_Ak(int client, int args)
{
	if(GetClientTeam(client) != 2)
	{
		PrintToChat(client, "%T", "NotAvailable", client, MSGTAG);
		return Plugin_Handled;
	}
	Format(h_iPrimaryWeapon[client], sizeof(h_iPrimaryWeapon[]), "weapon_ak47");
	PrintToChat(client, "%T", "AK47", client, MSGTAG);
	IsUserHavingAwp[client] = false;
	return Plugin_Handled;
}
public Action Command_Awp(int client, int args)
{
	Format(h_iPrimaryWeapon[client], sizeof(h_iPrimaryWeapon[]), "weapon_awp");
	PrintToChat(client, "%T", "AWP", client, MSGTAG);
	IsUserHavingAwp[client] = true;
	return Plugin_Handled;
}
*/
public Action Command_Guns(int client, int args)
{
	PrintToChat(client, "%T", "GunsOpen", client, MSGTAG);
	DisplayGunsMenu(client);
	return Plugin_Handled;
}
public Action Command_EditMode(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "%T", "ReplyEditMode", client, MSGTAG);
		return Plugin_Handled;
	}
	char StrArgument[32];
	GetCmdArg(1, StrArgument, sizeof(StrArgument));
	if(StrEqual(StrArgument, "1", false))
	{
		if(!IsOnEditMode[client])
		{
			IsOnEditMode[client] = true;
			ReplyToCommand(client, "%T", "EnteredEditMode", client, MSGTAG);
		}
		else
		{
			ReplyToCommand(client, "%T", "AlreadyEnteredEditMode", client, MSGTAG);
		}
	}
	else if(StrEqual(StrArgument, "0", false))
	{
		if(IsOnEditMode[client])
		{
			IsOnEditMode[client] = false;
			ReplyToCommand(client, "%T", "QuitEditMode", client, MSGTAG);
		}
		else
		{
			ReplyToCommand(client, "%T", "AlreadyQuitEditMode", client, MSGTAG);
		}
	}
	return Plugin_Handled;
}

public Action Command_AddBombSpawn(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "%T", "ErrorBombSpawnArg", client, MSGTAG);
		return Plugin_Handled;
	}
	if(!IsOnEditMode[client])
	{
		ReplyToCommand(client, "%T", "NotOnEditMode", client, MSGTAG);
		return Plugin_Handled;
	}
	char StrSide[4], StrPath[64];
	Format(StrPath, sizeof(StrPath), "cfg/2vs2/%s.cfg", h_iMapName);
	GetCmdArg(1, StrSide, sizeof(StrSide));
	Handle kv = CreateKeyValues("spawns");
	FileToKeyValues(kv, StrPath);
	if(StrEqual(StrSide, "A", false))
	{
		if(KvJumpToKey(kv, "A", true))
		{
			float Origin[3];
			GetClientAbsOrigin(client, Origin);
			KvSetFloat(kv, "Pitch", Origin[0]);
			KvSetFloat(kv, "Yaw", Origin[1]);
			KvSetFloat(kv, "Roll", Origin[2]);
			ReplyToCommand(client, "%T", "BombSideALoc", client, MSGTAG, Origin[0], Origin[1], Origin[2]);
			KvRewind(kv);
			KeyValuesToFile(kv, StrPath);
			CloseHandle(kv);
			return Plugin_Handled;
		}
	}
	else if(StrEqual(StrSide, "B", false))
	{
		if(KvJumpToKey(kv, "B", true))
		{
			float Origin[3];
			GetClientAbsOrigin(client, Origin);
			KvSetFloat(kv, "Pitch", Origin[0]);
			KvSetFloat(kv, "Yaw", Origin[1]);
			KvSetFloat(kv, "Roll", Origin[2]);
			ReplyToCommand(client, "%T", "BombSideBLoc", client, MSGTAG, Origin[0], Origin[1], Origin[2]);
			KvRewind(kv);
			KeyValuesToFile(kv, StrPath);
			CloseHandle(kv);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action Command_AddSpawn(int client, int args)
{
	if(args < 3)
	{
		ReplyToCommand(client, "%T", "AddSpawnArg", client, MSGTAG);
		return Plugin_Handled;
	}
	if(!IsOnEditMode[client])
	{
		ReplyToCommand(client, "%T", "NotOnEditMode", client, MSGTAG);
		return Plugin_Handled;
	}
	char StrSide[4], StrTeam[4], StrSpawnNumb[4], StrPath[64];
	Format(StrPath, sizeof(StrPath), "cfg/2vs2/%s.cfg", h_iMapName);
	GetCmdArg(1, StrSide, sizeof(StrSide));
	GetCmdArg(2, StrTeam, sizeof(StrTeam));
	GetCmdArg(3, StrSpawnNumb, sizeof(StrSpawnNumb));
	Handle kv = CreateKeyValues("spawns");
	FileToKeyValues(kv, StrPath);
	if(StrEqual(StrSide, "A", false))
	{
		if(KvJumpToKey(kv, "A", true))
		{
			if(StrEqual(StrTeam, "CT", false))
			{
				if(KvJumpToKey(kv, "CT", true))
				{
					if(KvJumpToKey(kv, StrSpawnNumb, true))
					{
						float Origin[3];
						GetClientAbsOrigin(client, Origin);
						KvSetFloat(kv, "Pitch", Origin[0]);
						KvSetFloat(kv, "Yaw", Origin[1]);
						KvSetFloat(kv, "Roll", Origin[2]);
						ReplyToCommand(client, "%T", "SaveLoc", client, MSGTAG, Origin[0], Origin[1], Origin[2]);
						KvRewind(kv);
						KeyValuesToFile(kv, StrPath);
						CloseHandle(kv);
						return Plugin_Handled;
					}
					else
					{
						ReplyToCommand(client, "%T", "ErrorAddSpawn", client, MSGTAG, 1);
						return Plugin_Handled;
					}
				}
				else
				{
					ReplyToCommand(client, "%T", "ErrorAddSpawn", client, MSGTAG, 2);
					return Plugin_Handled;
				}
			}
			else if(StrEqual(StrTeam, "T", false))
			{
				if(KvJumpToKey(kv, "T", true))
				{
					if(KvJumpToKey(kv, StrSpawnNumb, true))
					{
						float Origin[3];
						GetClientAbsOrigin(client, Origin);
						KvSetFloat(kv, "Pitch", Origin[0]);
						KvSetFloat(kv, "Yaw", Origin[1]);
						KvSetFloat(kv, "Roll", Origin[2]);
						ReplyToCommand(client, "%T", "SaveLoc", client, MSGTAG, Origin[0], Origin[1], Origin[2]);
						KvRewind(kv);
						KeyValuesToFile(kv, StrPath);
						CloseHandle(kv);
						return Plugin_Handled;
					}
					else
					{
						ReplyToCommand(client, "%T", "ErrorAddSpawn", client, MSGTAG, 3);
						return Plugin_Handled;
					}
				}
				else
				{
					ReplyToCommand(client, "%T", "ErrorAddSpawn", client, MSGTAG, 4);
					return Plugin_Handled;
				}
			}
		}
		else
		{
			ReplyToCommand(client, "%T", "ErrorAddSpawn", client, MSGTAG, 5);
			return Plugin_Handled;
		}
	}
	else if(StrEqual(StrSide, "B", false))
	{
		if(KvJumpToKey(kv, "B", true))
		{
			if(StrEqual(StrTeam, "CT", false))
			{
				if(KvJumpToKey(kv, "CT", true))
				{
					if(KvJumpToKey(kv, StrSpawnNumb, true))
					{
						float Origin[3];
						GetClientAbsOrigin(client, Origin);
						KvSetFloat(kv, "Pitch", Origin[0]);
						KvSetFloat(kv, "Yaw", Origin[1]);
						KvSetFloat(kv, "Roll", Origin[2]);
						ReplyToCommand(client, "%T", "SaveLoc", client, MSGTAG, Origin[0], Origin[1], Origin[2]);
						KvRewind(kv);
						KeyValuesToFile(kv, StrPath);
						CloseHandle(kv);
						return Plugin_Handled;
					}
					else
					{
						ReplyToCommand(client, "%T", "ErrorAddSpawn", client, MSGTAG, 6);
						return Plugin_Handled;
					}
				}
				else
				{
					ReplyToCommand(client, "%T", "ErrorAddSpawn", client, MSGTAG, 7);
					return Plugin_Handled;
				}
			}
			else if(StrEqual(StrTeam, "T", false))
			{
				if(KvJumpToKey(kv, "T", true))
				{
					if(KvJumpToKey(kv, StrSpawnNumb, true))
					{
						float Origin[3];
						GetClientAbsOrigin(client, Origin);
						KvSetFloat(kv, "Pitch", Origin[0]);
						KvSetFloat(kv, "Yaw", Origin[1]);
						KvSetFloat(kv, "Roll", Origin[2]);
						ReplyToCommand(client, "%T", "SaveLoc", client, MSGTAG, Origin[0], Origin[1], Origin[2]);
						KvRewind(kv);
						KeyValuesToFile(kv, StrPath);
						CloseHandle(kv);
						return Plugin_Handled;
					}
					else
					{
						ReplyToCommand(client, "%T", "ErrorAddSpawn", client, MSGTAG, 8);
						return Plugin_Handled;
					}
				}
				else
				{
					ReplyToCommand(client, "%T", "ErrorAddSpawn", client, MSGTAG, 9);
					return Plugin_Handled;
				}
			}
		}
		else
		{
			ReplyToCommand(client, "%T", "ErrorAddSpawn", client, MSGTAG, 10);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action Command_ForceStop(int client, int args)
{
	if(!IsMatchLive)
	{
		ReplyToCommand(client, "%T", "ForceStop", client, MSGTAG);
		return Plugin_Handled;
	}
	IsMatchLive = false;
	IsMatchSetup = false;
	i_hReadyNum = 0;
	for(int user = 1; user <= MaxClients; user++)
	{
		if(IsClientInGame(user))
		{
			IsClientReady[user] = false;
		}
	}
	ConVar g_iBuyMoney = null;
	ConVar g_iStartMoney = null;
	g_iBuyMoney = FindConVar("mp_maxmoney");
	g_iStartMoney = FindConVar("mp_startmoney");
	SetConVarInt(g_iBuyMoney, 60000);
	SetConVarInt(g_iStartMoney, 60000);
	ServerCommand("mp_warmup_start");
	PrintToChatAll("%s Match force stopped.", MSGTAG);
	return Plugin_Handled;
}

bool CMapFile(char[] StrMapName)
{
	char StrPath[128];
	Format(StrPath, sizeof(StrPath), "cfg/2vs2/%s.cfg", StrMapName);
	if(FileExists(StrPath))
	{
		return false;
	}
	Handle kv = CreateKeyValues("spawns");
	KeyValuesToFile(kv, StrPath);
	CloseHandle(kv);
	return true;
}
bool ApplySpawn(int client, char[] StrSpawnNumb, char[] StrSide, char[] StrMapName)
{
	char StrPath[128];
	Format(StrPath, sizeof(StrPath), "cfg/2vs2/%s.cfg", StrMapName);
	if(!FileExists(StrPath))
	{
		return false;
	}
	Handle kv = CreateKeyValues("spawns");
	FileToKeyValues(kv, StrPath);
	if(KvJumpToKey(kv, StrSide, false))
	{
		int i_hTeam = GetClientTeam(client);
		if(i_hTeam == 2)
		{
			if(KvJumpToKey(kv, "T", false))
			{
				if(KvJumpToKey(kv, StrSpawnNumb, false))
				{
					float Origin[3];
					Origin[0] = KvGetFloat(kv, "Pitch");
					Origin[1] = KvGetFloat(kv, "Yaw");
					Origin[2] = KvGetFloat(kv, "Roll");
					TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
					return true;
				}
				else
				{
					PrintToServer("&s Spawn was not found.", MSGTAG);
					return false;
				}
			}
		}
		else if(i_hTeam == 3)
		{
			if(KvJumpToKey(kv, "CT", false))
			{
				if(KvJumpToKey(kv, StrSpawnNumb, false))
				{
					float Origin[3];
					Origin[0] = KvGetFloat(kv, "Pitch");
					Origin[1] = KvGetFloat(kv, "Yaw");
					Origin[2] = KvGetFloat(kv, "Roll");
					TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
					return true;
				}
				else
				{
					PrintToServer("&s Spawn was not found.", MSGTAG);
					return false;
				}
			}
		}
	}
	return false;
}

bool ApplyBombSpawn(int client, char[] StrSide, char[] StrMapName)
{
	char StrPath[128];
	Format(StrPath, sizeof(StrPath), "cfg/2vs2/%s.cfg", StrMapName);
	if(!FileExists(StrPath))
	{
		return false;
	}
	Handle kv = CreateKeyValues("spawns");
	FileToKeyValues(kv, StrPath);
	if(KvJumpToKey(kv, StrSide, false))
	{
		float Origin[3];
		Origin[0] = KvGetFloat(kv, "Pitch");
		Origin[1] = KvGetFloat(kv, "Yaw");
		Origin[2] = KvGetFloat(kv, "Roll");
		TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
		CloseHandle(kv);
		return true;
	}
	else
	{
		PrintToServer("&s Spawn was not found.", MSGTAG);
		CloseHandle(kv)
		return false;
	}
}
 
void GetRandomSide(char StrSide[4])
{
	int Side = GetRandomInt(0, 1);
	if(Side == 0)
	{
		Format(StrSide, sizeof(StrSide), "A");
	}
	else if(Side == 1)
	{
		Format(StrSide, sizeof(StrSide), "B");
	}
}

int GetMaxTeamSpawns(char[] StrSide, char[] StrTeam, char[] StrMapName)
{
	char StrPath[128];
	int g_iMaxSpawns;
	Format(StrPath, sizeof(StrPath), "cfg/2vs2/%s.cfg", StrMapName);
	Handle kv = CreateKeyValues("spawns");
	FileToKeyValues(kv, StrPath);
	if(KvJumpToKey(kv, StrSide, false))
	{
		if(KvJumpToKey(kv, StrTeam, false))
		{
			KvGotoFirstSubKey(kv, false)
			do
			{
				g_iMaxSpawns++;
			}
			while(KvGotoNextKey(kv, false));
		}
	}
	CloseHandle(kv);
	return g_iMaxSpawns;
}

void ApplyWeapons(int client)
{
	StripAllWeapons(client);
	GetRandomGen(client);
	GivePlayerItem(client, h_iPrimaryWeapon[client]);
	GivePlayerItem(client, h_iSecondaryWeapon[client]);
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, h_iExtraItem[client]);
}

void StripAllWeapons(int client) 
{

	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {

		return;

	}

	int weapon;
	for (int i; i <= 4; i++) {
	
		if ((weapon = GetPlayerWeaponSlot(client, i)) != -1) {
		
			if (IsValidEntity(weapon)) {
			
				RemovePlayerItem(client, weapon);
				AcceptEntityInput(weapon, "Kill");
				
			}
			
		}
		
	}
	
}

void GetRandomGen(int client)
{
	int GenNum = GetRandomInt(1, 4);
	if(GenNum == 1)
	{
		Format(h_iExtraItem[client], sizeof(h_iExtraItem[]), "weapon_molotov");
	}
	else if(GenNum == 2)
	{
		Format(h_iExtraItem[client], sizeof(h_iExtraItem[]), "weapon_hegrenade");
	}
	else if(GenNum == 3)
	{
		Format(h_iExtraItem[client], sizeof(h_iExtraItem[]), "weapon_smokegrenade");
	}
	else if(GenNum == 4)
	{
		Format(h_iExtraItem[client], sizeof(h_iExtraItem[]), "weapon_flashbang");
	}
}


public int GetRandomPlayer(int team)
{
    int RandomClient;

    ArrayList ValidClients = new ArrayList();
    
    for(int i = 1; i < MaxClients; i++)
    {
        if(IsValidClient(i) && GetClientTeam(i) == team)
        {
            ValidClients.Push(i);
        }
    }
    
    RandomClient = ValidClients.Get(GetRandomInt(0, ValidClients.Length - 1));
    
    delete ValidClients;
  
    return RandomClient;
}

stock bool IsValidClient(int client) 
{ 
    return (1 <= client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && !IsFakeClient(client) && !IsPlayerAlive(client)); 
} 

bool HasBomb(int client)
{
	char WeaponName[32];
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		for(int slot = 0; slot <= 4; slot++)
		{
			int ent = GetPlayerWeaponSlot(client, slot);
			if(ent != -1)
			{
				if (IsValidEntity(ent))
				{
					GetEdictClassname(ent, WeaponName, sizeof(WeaponName));
					if(StrEqual(WeaponName, "weapon_c4"))
					{
						return true;
					}
				}
			}
		}
	}
	return false;
}

stock void RemoveC4()
{
	char WeaponName[32];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			for(int slot = 0; slot <= 4; slot++)
			{
				int ent = GetPlayerWeaponSlot(i, slot);
				if(ent != -1)
				{
					if (IsValidEntity(ent))
					{
						GetEdictClassname(ent, WeaponName, sizeof(WeaponName));
						if(StrEqual(WeaponName, "weapon_c4"))
						{
							RemovePlayerItem(i, ent);
							AcceptEntityInput(ent, "Kill");
							
						}
					}
				}
			}
		}
	}
}
stock int GetTeamPlayers(int team)
{
	int i_gUserNum = 0;
	for(int user = 1; user <= MaxClients ; user++)
	{
		if(IsClientConnected(user) && IsPlayerAlive(user) && GetClientTeam(user) == team)
		{
			i_gUserNum++;
		}
	}
	return i_gUserNum;
}

stock int GetAlivePlayers()
{
	int i_gUserNum = 0;
	for(int user = 1; user <= MaxClients ; user++)
	{
		if(IsClientConnected(user) && IsPlayerAlive(user))
		{
			i_gUserNum++;
		}
	}
	return i_gUserNum;
}

stock void SetupMatch()
{
	if(!IsMatchSetup)
	{
		ServerCommand("mp_warmup_end");
		IsMatchSetup = true;
		CreateTimer(0.5, Timer_RestartMatch);
	}
}

public Action Timer_RestartMatch(Handle timer)
{
	for(int i = 1;i<=MaxClients;i++)
	{
		if(IsValidClient(i) && !IsClientReady[i] && GetConVarBool(i_nReadySys))
		{
			ChangeClientTeam(i, 1);
			PrintToChat(i, "%T", "MovedToSpect", i, MSGTAG);
		}
	}
	ConVar g_iBuyMoney;
	ConVar g_iStartMoney;
	g_iBuyMoney = FindConVar("mp_maxmoney");
	g_iStartMoney = FindConVar("mp_startmoney");
	SetConVarInt(g_iBuyMoney, 0);
	SetConVarInt(g_iStartMoney, 0);
	ServerCommand("mp_restartgame 1");
	char CfgPath[64] = "2vs2/2vs2.cfg";
	ServerCommand("exec %s", CfgPath);
	PrintToChatAll("%s Match is live now.", MSGTAG);
	IsMatchLive = true;
}

void DisplayGunsMenu(int client)
{
	h_iSectionName[client] = "";
	char StrszPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, StrszPath, sizeof(StrszPath), "configs/guns.ini");
	Handle menu = CreateMenu(Guns);
	Handle kv = CreateKeyValues("guns");
	SetMenuTitle(menu, "Guns Menu:");
	FileToKeyValues(kv, StrszPath);
	KvGotoFirstSubKey(kv, true);
	do
	{
		char StrSection[32], Name[32];
		KvGetSectionName(kv, StrSection, sizeof(StrSection));
		KvGetString(kv, "Name", Name, sizeof(Name));
		AddMenuItem(menu, StrSection, Name);
	}
	while(KvGotoNextKey(kv, true));
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	SetMenuExitButton(menu, true);
}
public int Guns(Handle menu, MenuAction action, int client, int itemx)
{
	char StrszPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, StrszPath, sizeof(StrszPath), "configs/guns.ini");
	Handle kv = CreateKeyValues("guns");
	FileToKeyValues(kv, StrszPath);
	switch (action) 
	{
		case MenuAction_Select: 
		{
			char item[64], Team[8];
			GetMenuItem(menu, itemx, item, sizeof(item));
			KvGotoFirstSubKey(kv, true);
			do
			{
				KvGetSectionName(kv, h_iSectionName[client], sizeof(h_iSectionName[]));
				if(StrEqual(item, h_iSectionName[client]))
				{
					KvRewind(kv);
					if(KvJumpToKey(kv, h_iSectionName[client], false))
					{
						Handle g_menu = CreateMenu(SubGuns);
						char UID[32], Name[32], Title[64];
						KvGetString(kv, "Title", Title, sizeof(Title));
						SetMenuTitle(g_menu, Title);
						KvGotoFirstSubKey(kv, true);
						do
						{
							KvGetString(kv, "Team", Team, sizeof(Team))
							if(KvGetNum(kv, "Team") == GetClientTeam(client) || StrEqual(Team, ""))
							{
								KvGetString(kv, "Name", Name, sizeof(Name));
								KvGetString(kv, "u_id", UID, sizeof(UID));
								AddMenuItem(g_menu, UID, Name);
							}
						}
						while(KvGotoNextKey(kv, true));
						DisplayMenu(g_menu, client, MENU_TIME_FOREVER);
						SetMenuExitButton(g_menu, true);
					}
				}
				else
				{
					KvGotoNextKey(kv, true);
				}
			}
			while(!StrEqual(item, h_iSectionName[client]));
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
			CloseHandle(kv);
		}
	}
}
public int SubGuns(Handle g_menu, MenuAction action, int client, int itemx)
{
	char StrszPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, StrszPath, sizeof(StrszPath), "configs/guns.ini");
	Handle kv = CreateKeyValues("guns");
	FileToKeyValues(kv, StrszPath);
	switch (action) 
	{
		case MenuAction_Select: 
		{
			char item[64], UID[32], ClassName[32], Team[8];
			GetMenuItem(g_menu, itemx, item, sizeof(item));
			if(KvJumpToKey(kv, h_iSectionName[client], false))
			{
				char Type[4];
				KvGetString(kv, "Type", Type, sizeof(Type));
				KvGotoFirstSubKey(kv, true);
				do
				{
					KvGetString(kv, "u_id", UID, sizeof(UID));
					if(StrEqual(item, UID))
					{
						KvGetString(kv, "Team", Team, sizeof(Team));
						if(KvGetNum(kv, "Team") != GetClientTeam(client) && !StrEqual(Team, ""))
						{
							CloseHandle(kv);
							CloseHandle(g_menu);
							PrintToChat(client, "%T", "ErrorToTeam", client, MSGTAG);
							return;
						}
						KvGetString(kv, "ClassName", ClassName, sizeof(ClassName));
						if(StrEqual(Type, "1"))
						{
							if(KvGetNum(kv, "Stay") == 1)
							{
								IsUserHaveWep[client] = true;
								Format(h_iWepClassName[client], sizeof(h_iWepClassName[]), ClassName);
							}
							else
							{
								IsUserHaveWep[client] = false;
								Format(h_iWepClassName[client], sizeof(h_iWepClassName[]), "");
							}
							Format(h_iPrimaryWeapon[client], sizeof(h_iPrimaryWeapon[]), ClassName);
							PrintToChat(client, "%T", "GunGivenPrimary", client, MSGTAG, ClassName);
						}
						else if(StrEqual(Type, "2"))
						{
							if(KvGetNum(kv, "Stay") == 1)
							{
								IsUserHavePistol[client] = true;
								Format(h_iPistolClassName[client], sizeof(h_iPistolClassName[]), ClassName);
							}
							else
							{
								IsUserHavePistol[client] = false;
								Format(h_iPistolClassName[client], sizeof(h_iPistolClassName[]), "");
							}
							Format(h_iSecondaryWeapon[client], sizeof(h_iSecondaryWeapon[]), ClassName);
							PrintToChat(client, "%T", "GunGivenPistol", client, MSGTAG, ClassName);
						}
					}
					else
					{
						KvGotoNextKey(kv, true);
					}
				}
				while(!StrEqual(item, UID));
			}
		}
		case MenuAction_End: 
		{
			CloseHandle(g_menu);
			CloseHandle(kv);
		}
	}
}