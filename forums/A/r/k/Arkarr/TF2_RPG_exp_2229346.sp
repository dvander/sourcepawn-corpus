#include <sourcemod>
#include <clientprefs>
#include <morecolors>
#include <kvizzle>

#define KILLER_DOMINATION (1 << 0)
#define ASSISTER_DOMINATION (1 << 1)
#define KILLER_REVENGE (1 << 2)
#define ASSISTER_REVENGE (1 << 3)
#define FIRST_BLOOD (1 << 4)
#define FEIGN_DEATH (1 << 5)
#define HUD_DISPLAY_DEFAULT  0
#define HUD_DISPLAY_NONE	 1
#define HUD_DISPLAY_EXPBARRE 2

Handle COOKIEplayerLevel = INVALID_HANDLE;
Handle COOKIEplayerExp = INVALID_HANDLE;
Handle COOKIEdisplayHUDMode = INVALID_HANDLE;
Handle playerTimer[MAXPLAYERS+1] = INVALID_HANDLE;
Handle playersLevels = INVALID_HANDLE;
Handle weaponsKillExp = INVALID_HANDLE;
Handle deathTypeExp = INVALID_HANDLE;
Handle databaseConnection = INVALID_HANDLE;

char LAST_LEVEL_RECORDED[10];

int expPlayer[MAXPLAYERS+1];
int levelPlayer[MAXPLAYERS+1];
int expNeededPlayer[MAXPLAYERS+1];
int displayHUDMode[MAXPLAYERS+1];

bool HelpMessageDisplayed[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "TF2 RPG exp",
	author = "Arkarr",
	description	= "Manage EXP for each player",
	version	= "1.0",
	url	= "http://www.sourcemod.net"
};

public OnPluginStart()
{
	COOKIEplayerLevel = RegClientCookie("TF2_RPG_player_level", "Store the level players", CookieAccess_Private);
	COOKIEplayerExp = RegClientCookie("TF2_RPG_player_exp", "Store the exp players", CookieAccess_Private);
	COOKIEdisplayHUDMode = RegClientCookie("TF2_RPG_display_mode", "Store the HUD display mode", CookieAccess_Private);
	
	RegConsoleCmd("sm_resetlevel", CMD_RESETLEVELS, "Reset levels at 0");
	RegConsoleCmd("sm_levelhud", CMD_CHANGEHUDMODE, "Change the HUD display mode");
	RegAdminCmd("sm_setexp", CMD_SETEXP, ADMFLAG_CHEATS, "Set a ammount of exp on a player");
	RegAdminCmd("sm_addexp", CMD_ADDEXP, ADMFLAG_CHEATS, "Add a ammount of exp on a player");
	RegAdminCmd("sm_subexp", CMD_SUBEXP, ADMFLAG_CHEATS, "Substract a ammount of exp on a player");
	
	HookEvent("player_changeclass", Event_Changeclass);
	HookEvent("player_death", Event_PlayerDeath);
	
	playersLevels = GetInformationFromCFG("level_progression");
	weaponsKillExp = GetInformationFromCFG("weapons");
	deathTypeExp = GetInformationFromCFG("how_player_is_killed");
	
	for(new i = MaxClients; i > 0; --i)
	{
		SearchNextLevel(i, playersLevels);
		
		if(IsValidClient(i))
		{
			DisplayClientHUD(i);
			playerTimer[i] = CreateTimer(0.30, RefreshStat, GetClientSerial(i), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		
		if(!AreClientCookiesCached(i))
		{
			continue;
		}
		
		OnClientCookiesCached(i);
	}
	
	SQL_TConnect(RequestDBConnection, "TF2RPG_LEVEL_wi");
	
	CreateTimer(60.0, TMR_SavePlayerData, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public OnClientDisconnect(int client)
{
	char tmp[10];
	IntToString(expPlayer[client], tmp, sizeof(tmp));
	SetClientCookie(client, COOKIEplayerExp, tmp);
	IntToString(levelPlayer[client], tmp, sizeof(tmp));
	SetClientCookie(client, COOKIEplayerLevel, tmp);
	IntToString(displayHUDMode[client], tmp, sizeof(tmp));
	SetClientCookie(client, COOKIEdisplayHUDMode, tmp);
	HelpMessageDisplayed[client] = false;
	playerTimer[client] = INVALID_HANDLE;
}

public OnClientCookiesCached(int client)
{
	char cookieValue[10];
	GetClientCookie(client, COOKIEplayerLevel, cookieValue, sizeof(cookieValue));
	levelPlayer[client] = StringToInt(cookieValue);
	GetClientCookie(client, COOKIEplayerExp, cookieValue, sizeof(cookieValue));
	expPlayer[client] = StringToInt(cookieValue);
	GetClientCookie(client, COOKIEdisplayHUDMode, cookieValue, sizeof(cookieValue));
	displayHUDMode[client] = StringToInt(cookieValue);
	
	SearchNextLevel(client, playersLevels);
}

public RequestDBConnection(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		SetFailState("Database failure: %s", error);
		return;
	}
	
	databaseConnection = hndl;
	
	char buffer[300];
	
	if(!SQL_FastQuery(databaseConnection, "CREATE TABLE IF NOT EXISTS `TF2RPG_WI_level` (  `steamid` varchar(20) NOT NULL, `name` text NOT NULL,`level` int NOT NULL,`exp` int NOT NULL,`exp_nextlevel` int NOT NULL,PRIMARY KEY (`steamid`))"))
	{
		SQL_GetError(databaseConnection, buffer, sizeof(buffer));
		SetFailState("%s", buffer);
	}
}

public QueryResult(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		SetFailState("Database failure: %s", error);
		return;
	}
	
	CloseHandle(owner);
	CloseHandle(hndl);
}

public Action TMR_SavePlayerData(Handle tmr)
{
	for(new i = MaxClients; i > 0; --i)
	{
		if(IsValidClient(i))
		{
			char query[255];
			char steamID[255];
			char playerName[255];
			
			GetClientAuthId(i, AuthId_Steam2, steamID, sizeof(steamID));
			GetClientName(i, playerName, sizeof(playerName));
			Format(query, sizeof(query), "INSERT INTO `TF2RPG_WI_level` (`steamid`, `name`, `level`, `exp`, `exp_nextlevel`) VALUES ('%s', '%s', '%i', '%i', '%i')", steamID, playerName, levelPlayer[i], expPlayer[i], expNeededPlayer[i]);
			SQL_TQuery(databaseConnection, QueryResult, query);
		}
	}
	return Plugin_Continue;
}

public Action CMD_RESETLEVELS(int client, int args)
{
	levelPlayer[client] = 0;
	CPrintToChat(client, "{green}[TF2 LEVEL]{default} Levels sucessfully reseted.");
	SearchNextLevel(client, playersLevels);
	
	return Plugin_Handled;
}

public Action CMD_CHANGEHUDMODE(int client, int args)
{
	if(args != 1)
	{
		CPrintToChat(client, "{green}[TF2 LEVEL]{default} Usage : sm_levelhud <value>");
		return Plugin_Handled;
	}
	
	char arg1[5];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if(StringToInt(arg1) == HUD_DISPLAY_DEFAULT || HUD_DISPLAY_EXPBARRE == StringToInt(arg1) || HUD_DISPLAY_NONE == StringToInt(arg1))
	{
		displayHUDMode[client] = StringToInt(arg1);
	}
	else
	{
		CPrintToChat(client, "{green}[TF2 LEVEL]{default} Not a valid display mode.");
		CPrintToChat(client, "{green}[TF2 LEVEL]{default} List of valid display mode :");
		CPrintToChat(client, "{green}[TF2 LEVEL]{default} 0 = default");
		CPrintToChat(client, "{green}[TF2 LEVEL]{default} 1 = no display");
		CPrintToChat(client, "{green}[TF2 LEVEL]{default} 2 = [||||  ] LVL");
	}
	
	return Plugin_Handled;
}

public Action CMD_SETEXP(int client, int args)
{
	if(args < 2 || args > 3)
	{
		CPrintToChat(client, "{green}[TF2 LEVEL]{default} Usage : sm_setexp <target> <exp> <OPTIONAL:level>");
		return Plugin_Handled;
	}
	
	char target[20];
	char value[20];
	GetCmdArg(1, target, sizeof(target));
	int exp;
	int level = -1;
	
	if(GetCmdArg(2, value, sizeof(value)))
		exp = StringToInt(value);
	
	if(GetCmdArg(3, value, sizeof(value)))
		level = StringToInt(value);
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED, 
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		if(!AddExpManually(client, target_list[i], exp, level, true))
			return Plugin_Handled;
	}
	
	CPrintToChat(client, "{green}[TF2 LEVEL]{default} EXP sucessfully set on %i player(s) (set at %i EXP)", target_count, exp);
	
	return Plugin_Handled;
}

public Action CMD_ADDEXP(int client, int args)
{
	if(args < 2)
	{
		CPrintToChat(client, "{green}[TF2 LEVEL]{default} Usage : sm_setexp <target> <exp>");
		return Plugin_Handled;
	}
	
	char target[20], value[20];
	GetCmdArg(1, target, sizeof(target));
	int exp;
	int level = -1;
	
	if(GetCmdArg(2, value, sizeof(value)))
		exp = StringToInt(value);
	
	if(GetCmdArg(3, value, sizeof(value)))
		level = StringToInt(value);
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED, 
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		if(!AddExpManually(client, target_list[i], exp, level))
			return Plugin_Handled;
	}
	
	CPrintToChat(client, "{green}[TF2 LEVEL]{default} EXP sucessfully added on %i player(s) (+ %i EXP)", target_count, exp);
	
	return Plugin_Handled;
}

public Action CMD_SUBEXP(client, args)
{
	if(args < 2)
	{
		CPrintToChat(client, "{green}[TF2 LEVEL]{default} Usage : sm_setexp <target> <exp>");
		return Plugin_Handled;
	}
	
	char target[20], value[20];
	GetCmdArg(1, target, sizeof(target));
	int exp;
	int level = -1;
	
	if(GetCmdArg(2, value, sizeof(value)))
		exp = StringToInt(value);
	
	if(GetCmdArg(3, value, sizeof(value)))
		level = StringToInt(value);
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED, 
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		if(!AddExpManually(client, target_list[i], -exp, level))
			return Plugin_Handled;
	}
	
	CPrintToChat(client, "{green}[TF2 LEVEL]{default} EXP sucessfully substracted on %i player(s) (- %i EXP)", target_count, exp);
	
	return Plugin_Handled;
}

public Action RefreshStat(Handle:timer, any:serial)
{
	int client = GetClientFromSerial(serial);
	
	if(client == 0)
		return Plugin_Continue;
	
	DisplayClientHUD(client);
	
	return Plugin_Handled;
}

public Action Event_Changeclass(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!HelpMessageDisplayed[client])
	{
		if(playerTimer[client] != INVALID_HANDLE)
		{
			KillTimer(playerTimer[client]);
			playerTimer[client] = INVALID_HANDLE;
		}
		
		CPrintToChat(client, "{green}[TF2 LEVEL]{default} Level initialized, do {fullred}frag{default} to get {green}EXP{default} !");
		HelpMessageDisplayed[client] = true;
		DisplayClientHUD(client);
		playerTimer[client] = CreateTimer(0.30, RefreshStat, GetClientSerial(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int victimId = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker == 0)
		return Plugin_Continue;
	int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	int weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	int deathflag = GetEventInt(event, "death_flags");
	
	AddExpToPlayerWeapon(attacker, weaponindex, weaponsKillExp);
	if(GetClientTeam(victimId) == GetClientTeam(attacker))
	{
		int expToAdd = 0;
		GetTrieValue(deathTypeExp, "friendlyfire", expToAdd);
		expPlayer[attacker] += expToAdd;
		if(expPlayer[attacker] < 0) expPlayer[attacker] = 0;
	}
	else
	{
		AddExpToPlayerDeathType(attacker, deathflag, deathTypeExp);
	}
	
	return Plugin_Continue;
}

stock bool AddExpManually(int laucher, int client, int exp, int level, bool setmod=false)
{
	char lvl[10];
	int exp_tmp;
	if(level != -1)
	{
		if(level > GetTrieSize(playersLevels))
		{
			CPrintToChat(laucher, "{green}[TF2 LEVEL]{default} {fullred}Invalid parameters{default} ! Level %i doesn't exist !", level);
			return false;
		}
		
		IntToString(level, lvl, sizeof(lvl));
		GetTrieValue(playersLevels, lvl, exp_tmp);
		if(exp_tmp > exp)
		{
			expPlayer[client] = exp;
			expNeededPlayer[client] = exp_tmp;
			levelPlayer[client] = level;
		}
		else
		{
			CPrintToChat(laucher, "{green}[TF2 LEVEL]{default} {fullred}Invalid parameters{default} ! Level %i only require %i exp and %i is too high !", level, exp_tmp, exp);
			return false;
		}
	}
	else
	{
		if(setmod)
		{
			for(new y = 0; y < GetTrieSize(playersLevels); y++)
			{
				IntToString(y, lvl, sizeof(lvl));
				GetTrieValue(playersLevels, lvl, exp_tmp);
				if(exp_tmp > exp)
				{
					expPlayer[client] = exp;
					expNeededPlayer[client] = exp_tmp;
					levelPlayer[client] = y;
					break;
				}
			}
		}
		else
		{
			expPlayer[client] += exp;
			if(expPlayer[client] < 0)
			{
				levelPlayer[client]--;
				IntToString(levelPlayer[client], lvl, sizeof(lvl));
				GetTrieValue(playersLevels, lvl, exp_tmp);
				expPlayer[client] = exp_tmp + expPlayer[client];
				if(levelPlayer[client] < 0)
					levelPlayer[client] = 0;
			}
			else if(expPlayer[client] >= expNeededPlayer[client] && expPlayer[client] != StringToInt(LAST_LEVEL_RECORDED))
			{
				expPlayer[client] -= exp;
				levelPlayer[client]++;
				IntToString(levelPlayer[client], lvl, sizeof(lvl));
				GetTrieValue(playersLevels, lvl, exp_tmp);
				expPlayer[client] = exp - (expNeededPlayer[client] - expPlayer[client]);
			}

			IntToString(levelPlayer[client], lvl, sizeof(lvl));
			GetTrieValue(playersLevels, lvl, exp_tmp);
			expNeededPlayer[client] = exp_tmp;
		}
	}
	return true;
}

stock SearchNextLevel(client, Handle table)
{
	char tmp[10];
	IntToString(levelPlayer[client], tmp, sizeof(tmp));
	if(!GetTrieValue(table, tmp, expNeededPlayer[client]))
	{
		GetTrieValue(table, LAST_LEVEL_RECORDED, expNeededPlayer[client]);
	}
}

stock AddExpToPlayerWeapon(client, weaponindex, Handle table)
{
	char tmp[10];
	int expToAdd = 0;
	IntToString(weaponindex, tmp, sizeof(tmp));
	GetTrieValue(table, tmp, expToAdd);
	if(expToAdd == 0) expToAdd = 1;
	expPlayer[client] += expToAdd;
	CheckPlayerNewLevel(client);
}

stock AddExpToPlayerDeathType(int client, int deathflag, Handle table)
{
	int expToAdd = 0;
	if (deathflag & KILLER_DOMINATION) GetTrieValue(table, "dominations", expToAdd);
	else if (deathflag & KILLER_REVENGE) GetTrieValue(table, "revenge kills", expToAdd);
	else if (deathflag & ASSISTER_DOMINATION) GetTrieValue(table, "assist domination", expToAdd);
	else if (deathflag & ASSISTER_REVENGE) GetTrieValue(table, "assister revenge", expToAdd);
	else if (deathflag & FIRST_BLOOD) GetTrieValue(table, "first blood", expToAdd);
	else if (deathflag & FEIGN_DEATH) GetTrieValue(table, "fake death(spy)", expToAdd);	
	expPlayer[client] += expToAdd;
	CheckPlayerNewLevel(client);
}

stock CheckPlayerNewLevel(int client)
{
	if(expPlayer[client] >= expNeededPlayer[client])
	{
		levelPlayer[client]++;
		expPlayer[client] -= expNeededPlayer[client];
		SearchNextLevel(client, playersLevels);
	}
	else if(expPlayer[client] < 0)
	{
		//SearchNextLevel(client, playersLevels, true);
	}
}

stock DisplayClientHUD(int client)
{
	if(displayHUDMode[client] == HUD_DISPLAY_NONE)
	{
		if(playerTimer[client] != INVALID_HANDLE)
		{
			KillTimer(playerTimer[client]);
			playerTimer[client] = INVALID_HANDLE;
		}
	}
	else if(displayHUDMode[client] == HUD_DISPLAY_DEFAULT)
	{
		SetHudTextParams(-1.0, 0.85, 0.5, 0, 255, 0, 200, 0, 0.00001, 0.00001, 0.00001);
		ShowHudText(client, -1, "[ Level : %i | Exp : %i/%i ]", levelPlayer[client] , expPlayer[client] , expNeededPlayer[client]);
	}
	else if(displayHUDMode[client] == HUD_DISPLAY_EXPBARRE)
	{
		char hud[100];
		char hud_end[30];
		SetHudTextParams(-1.0, 0.85, 0.5, 0, 255, 0, 200, 0, 0.00001, 0.00001, 0.00001);
		float p = 100 * (float(expPlayer[client]) / float(expNeededPlayer[client]));
		Format(hud, sizeof(hud), "[");
		for(new i = 0; i < 100; i+=2)
		{
			if(i <= p)
				StrCat(hud, sizeof(hud), "|");
			else
				StrCat(hud, sizeof(hud), " ");
		}
		Format(hud_end, sizeof(hud_end), "] Level %i", levelPlayer[client]);
		StrCat(hud, sizeof(hud), hud_end);
		ShowHudText(client, -1, hud);
	}
	
	if(playerTimer[client] == INVALID_HANDLE && displayHUDMode[client] != HUD_DISPLAY_NONE)
		playerTimer[client] = CreateTimer(0.30, RefreshStat, GetClientSerial(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

stock Handle GetInformationFromCFG(const char[] key)
{
	char level[100];
	char expNeeded[100];
	Handle arrayList;
	
	arrayList = CreateTrie();
	
	Handle kv = KvizCreateFromFile("TF2_RPG_XP", "addons/sourcemod/configs/tf2_rpg_exp.cfg");
	for(new i = 1; KvizExists(kv, "%s:nth-child(%i)",key, i); i++)
	{
		KvizGetStringExact(kv, level, sizeof(level), "%s:nth-child(%i):key",key, i);
		KvizGetStringExact(kv, expNeeded, sizeof(expNeeded), "%s:nth-child(%i):value",key, i);
		SetTrieValue(arrayList, level, StringToInt(expNeeded));
		Format(LAST_LEVEL_RECORDED, sizeof(LAST_LEVEL_RECORDED), level);
	}
	KvizClose(kv);  
	
	return arrayList;
}

stock bool IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}