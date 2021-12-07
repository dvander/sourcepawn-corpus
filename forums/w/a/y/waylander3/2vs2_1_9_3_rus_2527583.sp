#include <sourcemod>
#include <sdktools>
#pragma newdecls required
#define Plugin_Version "1.9.3 (Final Version)"
#define MSGTAG " \x02[Retakes]\x05"
//////////////////////////////////////////////////////////
//ConVars
ConVar i_nMaxReady = null;
//Booleans
bool IsOnEditMode[MAXPLAYERS+1] = false;
bool IsSpawnTaken[256] = false;
bool IsClientReady[MAXPLAYERS+1] = false;
bool IsMatchLive = false;
bool IsMatchSetup = false;
//Ints
int i_hReadyNum = 0;
//int SpawnNum = 0;
//Strings
char h_iMapName[32];
char h_iPrimaryWeapon[MAXPLAYERS+1][32];
char h_iSecondaryWeapon[MAXPLAYERS+1][32];
char h_iExtraItem[MAXPLAYERS+1][32];
char h_iSideString[4];
//Floats
//////////////////////////////////////////////////////////
public Plugin myinfo = {
	name = "[CS:GO] BlackRocks Retakes",
	author = "noBrain",
	description = "Allow server-side 2vs2 competitve matches",
	version = Plugin_Version,
};

public void OnPluginStart()
{
	//AdminCommands
	RegAdminCmd("sm_emode", Command_EditMode, ADMFLAG_ROOT);
	RegAdminCmd("sm_addspawn", Command_AddSpawn, ADMFLAG_ROOT);
	RegAdminCmd("sm_addbomb", Command_AddBombSpawn, ADMFLAG_ROOT);
	RegAdminCmd("sm_forcestop", Command_ForceStop, ADMFLAG_ROOT);
	//ConosleCommands
	RegConsoleCmd("sm_awp", Command_Awp);
	RegConsoleCmd("sm_ak", Command_Ak);
	RegConsoleCmd("sm_m1", Command_M1);
	RegConsoleCmd("sm_m4", Command_M4);
	RegConsoleCmd("sm_ready", Command_Ready)
	RegConsoleCmd("sm_r", Command_Ready)
	//Hooks
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_start", RoundStart);
	HookEvent("player_disconnect", PlayerDisconnect);
	HookEvent("cs_pre_restart", Event_ReRestart);
	//ConVars
	i_nMaxReady = CreateConVar("sm_max_ready_num", "4", "Max ready users needed to startup the match");
	//Extra
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
		Format(h_iPrimaryWeapon[client], sizeof(h_iPrimaryWeapon[]), "weapon_ak47");
		Format(h_iSecondaryWeapon[client], sizeof(h_iSecondaryWeapon[]), "weapon_glock");
	}
	if(team == 3)
	{
		Format(h_iPrimaryWeapon[client], sizeof(h_iPrimaryWeapon[]), "weapon_m4a1");
		Format(h_iSecondaryWeapon[client], sizeof(h_iSecondaryWeapon[]), "weapon_hkp2000");
	}
	if(IsMatchLive)
	{
		if(!IsClientReady[client])
		{
			ChangeClientTeam(client, 1);
			PrintToChat(client, "%s You are not able to join due you are not part of a team.", MSGTAG);
		}
	}
}

public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
	{
		PrintToChat(client, "%s Can't start match while there is a warmup time.", MSGTAG);
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
	ServerCommand("tv_msg \"%s Матч %s запущен. LIVE! LIVE! LIVE!\"", MSGTAG, h_iSideString);
	if(HasBomb(client))
	{
		if(ApplyBombSpawn(client, h_iSideString, h_iMapName))
		{
			PrintToChat(client, "%s Вы в зоне закладки бомбы.", MSGTAG);
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
			PrintToChat(client, "%s Retake \x0E%s: \x02%d Ts \x05vs \x0B%d CTs.", MSGTAG, h_iSideString, GetTeamPlayers(2), GetTeamPlayers(3));
			PrintToChat(client, "%s Вы возродились.", MSGTAG);
		}
		else
		{
			ChangeClientTeam(client, 1);
			PrintToChat(client, "%s Не найдено доступных спавнов.", MSGTAG);
		}
	}
}

public Action RoundStart(Handle event, const char[] name, bool dontBroadcast) 
{
	//PrintToChatAll("%s Данный мод предоставлен для SLL ладдера 2vs2 retakes.", MSGTAG);
	//PrintToChatAll("%s Версия мода: \x02%s", MSGTAG, Plugin_Version);
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
	{
		IsMatchLive = false;
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
}

public Action PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientReady[client] && !IsMatchLive)
	{
		i_hReadyNum = i_hReadyNum - 1;
		PrintToChat(client, "%s Готовых к матчу игроков: %d", MSGTAG, i_hReadyNum);
	}
}

public Action Event_ReRestart(Handle event, const char[] name, bool dontBroadcast) 
{
	for(int spawns = 0; spawns <= 256; spawns++)
	{
		IsSpawnTaken[spawns] = false;
	}
}

public Action Command_Ready(int client, int args)
{
	if(IsClientReady[client])
	{
		PrintToChat(client, "%s Вы уже подтвердили готовность.", MSGTAG);
		return Plugin_Handled;
	}
	if(IsMatchLive)
	{
		PrintToChat(client, "%s Вы опоздали!", MSGTAG);
		return Plugin_Handled;
	}
	i_hReadyNum++;
	IsClientReady[client] = true;
	PrintToChat(client, "%s Вы подтвердили свою готовность.", MSGTAG);
	if(i_hReadyNum == GetConVarInt(i_nMaxReady))
	{
		PrintToChatAll("%s Все игроки готовы, матч переходит в LIVE.", MSGTAG);
		IsMatchLive = true;
		SetupMatch();
		return Plugin_Handled;
	}
	else
	{
		PrintToChatAll("%s Игрок %N готов, матч начнётся, когда все 4 игрока подтвердят готовность !ready.", MSGTAG, client);
		return Plugin_Handled;
	}
}

public Action Command_M1(int client, int args)
{
	if(GetClientTeam(client) != 3)
	{
		PrintToChat(client, "%s Данная команда недоступна для вашей команды.", MSGTAG);
		return Plugin_Handled;
	}
	Format(h_iPrimaryWeapon[client], sizeof(h_iPrimaryWeapon[]), "weapon_m4a1_silencer");
	PrintToChat(client, "%s Вы выбрали M4A1 Silencer как основное оружие.", MSGTAG);
	return Plugin_Handled;
}
public Action Command_M4(int client, int args)
{
	if(GetClientTeam(client) != 3)
	{
		PrintToChat(client, "%s Данная команда недоступна для вашей команды.", MSGTAG);
		return Plugin_Handled;
	}
	Format(h_iPrimaryWeapon[client], sizeof(h_iPrimaryWeapon[]), "weapon_m4a1");
	PrintToChat(client, "%s Вы выбрали M4A4 как основное оружие.", MSGTAG);
	return Plugin_Handled;
}
public Action Command_Ak(int client, int args)
{
	if(GetClientTeam(client) != 2)
	{
		PrintToChat(client, "%s Данная команда недоступна для вашей команды.", MSGTAG);
		return Plugin_Handled;
	}
	Format(h_iPrimaryWeapon[client], sizeof(h_iPrimaryWeapon[]), "weapon_ak47");
	PrintToChat(client, "%s Вы выбрали AK47 как основное оружие.", MSGTAG);
	return Plugin_Handled;
}
public Action Command_Awp(int client, int args)
{
	Format(h_iPrimaryWeapon[client], sizeof(h_iPrimaryWeapon[]), "weapon_awp");
	PrintToChat(client, "%s Вы выбрали AWP как основное оружие.", MSGTAG);
	return Plugin_Handled;
}
public Action Command_EditMode(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "%s Использование: sm_emode 1/0", MSGTAG);
		return Plugin_Handled;
	}
	char StrArgument[32];
	GetCmdArg(1, StrArgument, sizeof(StrArgument));
	if(StrEqual(StrArgument, "1", false))
	{
		if(!IsOnEditMode[client])
		{
			IsOnEditMode[client] = true;
			ReplyToCommand(client, "%s Вы запустили режим редактирования", MSGTAG);
		}
		else
		{
			ReplyToCommand(client, "%s Вы уже в режиме редактирования.", MSGTAG);
		}
	}
	else if(StrEqual(StrArgument, "0", false))
	{
		if(IsOnEditMode[client])
		{
			IsOnEditMode[client] = false;
			ReplyToCommand(client, "%s Вы вышли из режима редактирования.", MSGTAG);
		}
		else
		{
			ReplyToCommand(client, "%s Вы уже вышли из режима редактирования.", MSGTAG);
		}
	}
	return Plugin_Handled;
}

public Action Command_AddBombSpawn(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "%s Использование: sm_addbomb side, (i.e sm_addbomb A)", MSGTAG);
		return Plugin_Handled;
	}
	if(!IsOnEditMode[client])
	{
		ReplyToCommand(client, "%s Вы не в режиме редактирования. Для начала - запустите его.", MSGTAG);
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
			ReplyToCommand(client, "%s Бомб сайд A Позиция (%f , %f , %f) была сохрнанена.", MSGTAG, Origin[0], Origin[1], Origin[2]);
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
			ReplyToCommand(client, "%s Бомб сайд B Позиция (%f , %f , %f) была сохрнанена.", MSGTAG, Origin[0], Origin[1], Origin[2]);
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
		ReplyToCommand(client, "%s Использование: sm_addspawn side team num (i.e sm_addspawn B CT 1)", MSGTAG);
		return Plugin_Handled;
	}
	if(!IsOnEditMode[client])
	{
		ReplyToCommand(client, "%s Вы не в режиме редактирования. Для начала - запустите его.", MSGTAG);
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
						ReplyToCommand(client, "%s Позиция (%f , %f , %f) была сохранена.", MSGTAG, Origin[0], Origin[1], Origin[2]);
						KvRewind(kv);
						KeyValuesToFile(kv, StrPath);
						CloseHandle(kv);
						return Plugin_Handled;
					}
					else
					{
						ReplyToCommand(client, "%s An error ocurred. (error code: 1)", MSGTAG);
						return Plugin_Handled;
					}
				}
				else
				{
					ReplyToCommand(client, "%s An error ocurred. (error code: 2)", MSGTAG);
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
						ReplyToCommand(client, "%s Позиция (%f , %f , %f) была сохранена.", MSGTAG, Origin[0], Origin[1], Origin[2]);
						KvRewind(kv);
						KeyValuesToFile(kv, StrPath);
						CloseHandle(kv);
						return Plugin_Handled;
					}
					else
					{
						ReplyToCommand(client, "%s An error ocurred. (error code: 3)", MSGTAG);
						return Plugin_Handled;
					}
				}
				else
				{
					ReplyToCommand(client, "%s An error ocurred. (error code: 4)", MSGTAG);
					return Plugin_Handled;
				}
			}
		}
		else
		{
			ReplyToCommand(client, "%s An error ocurred. (error code: 5)", MSGTAG);
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
						ReplyToCommand(client, "%s Позиция (%f , %f , %f) была сохранена.", MSGTAG, Origin[0], Origin[1], Origin[2]);
						KvRewind(kv);
						KeyValuesToFile(kv, StrPath);
						CloseHandle(kv);
						return Plugin_Handled;
					}
					else
					{
						ReplyToCommand(client, "%s An error ocurred. (error code: 6)", MSGTAG);
						return Plugin_Handled;
					}
				}
				else
				{
					ReplyToCommand(client, "%s An error ocurred. (error code: 7)", MSGTAG);
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
						ReplyToCommand(client, "%s Позиция (%f , %f , %f) была сохранена.", MSGTAG, Origin[0], Origin[1], Origin[2]);
						KvRewind(kv);
						KeyValuesToFile(kv, StrPath);
						CloseHandle(kv);
						return Plugin_Handled;
					}
					else
					{
						ReplyToCommand(client, "%s An error ocurred. (error code: 8)", MSGTAG);
						return Plugin_Handled;
					}
				}
				else
				{
					ReplyToCommand(client, "%s An error ocurred. (error code: 9)", MSGTAG);
					return Plugin_Handled;
				}
			}
		}
		else
		{
			ReplyToCommand(client, "%s An error ocurred. (error code: 10)", MSGTAG);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action Command_ForceStop(int client, int args)
{
	if(!IsMatchLive)
	{
		ReplyToCommand(client, "%s Вы не можете остановить матч, так как он не запущен.", MSGTAG);
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
	ServerCommand("mp_warmup_start");
	PrintToChatAll("%s Матч был принудительно остановлен.", MSGTAG);
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
					PrintToServer("&s Спавны не найдены.", MSGTAG);
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
					PrintToServer("&s Спавны не найдены.", MSGTAG);
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
		PrintToServer("&s Спавны не найдены.", MSGTAG);
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
	GetRandomGen(client);
	StripAllWeapons(client);
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
	for (int i; i < 4; i++) {
	
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
    return (1 <= client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client)); 
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

stock void SetupMatch()
{
	if(!IsMatchSetup)
	{
		ServerCommand("mp_warmup_end");
		IsMatchSetup = true;
	}
	CreateTimer(0.5, Timer_RestartMatch);
}

public Action Timer_RestartMatch(Handle timer)
{
	for(int i = 1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && !IsClientReady[i])
		{
			ChangeClientTeam(i, 1);
			PrintToChat(i, "%s Вы были перемещены в наблюдатели, так как вы не участник матча.");
		}
	}
	ServerCommand("mp_restartgame 1");
	char CfgPath[64] = "2vs2/2vs2.cfg";
	ServerCommand("exec %s", CfgPath);
	PrintToChatAll("%s Матч запущен. LIVE! LIVE! LIVE!", MSGTAG)
}