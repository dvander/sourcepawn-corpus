/*
This plugin just simply to count player killing record save to files.
If anyone can help to make a sql version that's very good :)

Contact hotmail: fuyuumiai@outlook.com
Or Steam: http://steamcommunity.com/id/kirisamealice/

国内的插件制作麻烦别拿着我这插件去卖,谢谢. 如果你想更改代码请先与我联系.

v1.1:
-Fix the playername change bug,this plugin won't record playername anymore.
-Remove Unused code.
-Don't need color.inc anymore.
*/

#include <sdktools>
#include <sourcemod>
#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

#define	TEAM_SPECTATOR	1
#define	TEAM_SURVIVOR	2
#define	TEAM_INFECTED	3

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY

#define ATTACKER new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
#define CLIENT new client = GetClientOfUserId(GetEventInt(event, "userid"));

#define IsValidClient(%1)		(1 <= %1 <= MaxClients && IsClientInGame(%1))

new playerBoomerKilled[MAXPLAYERS+1];
new playerHunterKilled[MAXPLAYERS+1];
new playerSmokerKilled[MAXPLAYERS+1];
new playerJockeyKilled[MAXPLAYERS+1];
new playerChargerKilled[MAXPLAYERS+1];
new playerSpitterKilled[MAXPLAYERS+1];
new playerWitchKilled[MAXPLAYERS+1];
new playerTankDamage[MAXPLAYERS+1];
new playerCommonKilled[MAXPLAYERS+1];
new playerGunfiredTime[MAXPLAYERS+1];
//new playerMeleeShovedTime[MAXPLAYERS+1];
new playerHitedenemy[MAXPLAYERS+1];

new String:SavePath[256];

new Handle:PlayerStatsSave = INVALID_HANDLE;
new Handle:CleanSaveFileDays	=	INVALID_HANDLE;
new bool:IsAdmin[MAXPLAYERS+1]	=	{false, ...};

public Plugin:myinfo =
{
	name = "[L4D2] Player Stats",
	author = "Kirisame",
	description = "Count player zombies killing,save to file.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

enum
{
    CLASS_SMOKER = 1,
    CLASS_BOOMER = 2,
    CLASS_HUNTER = 3,
    CLASS_SPITTER = 4,
    CLASS_JOCKEY = 5,
    CLASS_CHARGER = 6,
    CLASS_TANK = 7,
    CLASS_WITCH = 8
};

public OnPluginStart()
{	
	CreateConVar("l4d2_stats_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	CleanSaveFileDays = CreateConVar("l4d2_stats_clearout", "7",	"Remove player log when them don't join this server for a long time. 0 = never clear.", CVAR_FLAGS, true, 0.0);

	RegConsoleCmd("sm_stats",	Menu_ShowStats);
	
	HookEvent("infected_death", Infected_Killed);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_death", Event_Death);
	HookEvent("weapon_fire", OnWeaponFire);
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("player_changename", Event_PlayerChangename,	EventHookMode_Pre);
	
	AutoExecConfig(true, "l4d2_stats");
	
	ShowStats();
}

public ShowStats()
{
	CreateTimer(360.0, Stats, _, TIMER_REPEAT);
}

public Action:Stats(Handle:timer)
{
	PrintToChatAll("\x01You can type\x05 !stats \x04to see your server stats\x01");
}

public Action:Infected_Killed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));	
	
	if(attacker > 0)
	{
		if(GetClientTeam(attacker)==2)
		{
			playerCommonKilled[attacker] += 1;
			playerHitedenemy[attacker] += 1;
		}
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	//new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	//new victim = GetEventInt(event, "userid");

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(IsValidClient(victim))
	{
		if(GetClientTeam(victim) == TEAM_INFECTED)
		{
			new iClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
			if(IsValidClient(attacker))
			{
				if(GetClientTeam(attacker) == TEAM_SURVIVOR)	//Player kill special infected
				{
					if(!IsFakeClient(attacker))
					{
						switch (iClass)
						{
							case 1:
							{
								playerSmokerKilled[attacker] += 1;
							}
							case 2:
							{
								playerBoomerKilled[attacker] += 1;
							}
							case 3:
							{
								playerHunterKilled[attacker] += 1;
							}
							case 4:
							{
								playerSpitterKilled[attacker] += 1;
							}
							case 5:
							{
								playerJockeyKilled[attacker] += 1;
							}
							case 6:
							{
								playerChargerKilled[attacker] += 1;
							}
						}
					}
				}
			}
		}
	}
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetEntProp(target, Prop_Send, "m_zombieClass") == 8)
	{
		new dmg_health = GetEventInt(event, "dmg_health");	 // get the amount of damage done
		if(attacker > 0 && target > 0)
		{
			if(GetClientTeam(attacker)==2)
			{
				playerTankDamage[attacker] += dmg_health;
			}
		}
	}
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if(attacker > 0 && victim > 0)
	{
		if(GetClientTeam(attacker)==2 && GetClientTeam(victim)!=3)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					if (!IsFakeClient(i) && GetClientTeam(i)==2)
					{
						ClientSaveToFileSave(i);
					}
				}
			}
		}
	}
}

public OnMapStart()
{
	PlayerStatsSave = CreateKeyValues("Player Stats Save");
	BuildPath(Path_SM, SavePath, 255, "data/PlayerStatsSave.txt");
	FileToKeyValues(PlayerStatsSave, SavePath);
}

public OnMapEnd()
{	
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				ClientSaveToFileSave(i);
			}
		}
	}
	CloseHandle(PlayerStatsSave);
}

public OnClientConnected(Client)
{
	Initialization(Client);
	decl String:user_name[MAX_NAME_LENGTH]="";
	GetClientAuthString(Client, user_name, sizeof(user_name));
	KvJumpToKey(PlayerStatsSave, user_name, false);
	KvGoBack(PlayerStatsSave);
	
	ClientSaveToFileLoad(Client);
}

public OnClientDisconnect(client)
{
	ClientSaveToFileSave(client);
	Initialization(client);
}

ClientSaveToFileLoad(Client)
{
	decl String:user_name[MAX_NAME_LENGTH]="";
	GetClientAuthString(Client, user_name, sizeof(user_name));
	
	ReplaceString(user_name, sizeof(user_name), "\"", "{DQM}");//DQM Double quotation mark
	ReplaceString(user_name, sizeof(user_name), "\'", "{SQM}");//SQM Single quotation mark
	ReplaceString(user_name, sizeof(user_name), "/*", "{SST}");//SST Slash Star
	ReplaceString(user_name, sizeof(user_name), "*/", "{STS}");//STS Star Slash
	ReplaceString(user_name, sizeof(user_name), "//", "{DSL}");//DSL Double Slash
	KvJumpToKey(PlayerStatsSave, user_name, true);

	playerBoomerKilled[Client] = KvGetNum(PlayerStatsSave, "Boomer", 0);
	playerSmokerKilled[Client] = KvGetNum(PlayerStatsSave, "Smoker", 0);
	playerHunterKilled[Client] = KvGetNum(PlayerStatsSave, "Hunter", 0);
	playerJockeyKilled[Client] = KvGetNum(PlayerStatsSave, "Jockey", 0);
	playerSpitterKilled[Client] = KvGetNum(PlayerStatsSave, "Spitter",0);
	playerChargerKilled[Client] = KvGetNum(PlayerStatsSave, "Charger", 0);
	playerWitchKilled[Client] = KvGetNum(PlayerStatsSave, "Witch", 0);
	playerTankDamage[Client]= KvGetNum(PlayerStatsSave, "TankDamage", 0);
	playerCommonKilled[Client] = KvGetNum(PlayerStatsSave, "Common", 0);
	playerGunfiredTime[Client] = KvGetNum(PlayerStatsSave, "GunFired", 0);
	//playerMeleeShovedTime[Client] = KvGetNum(PlayerStatsSave, "MeleeShoved", 0);
	playerHitedenemy[Client] = KvGetNum(PlayerStatsSave, "SucessHit", 0);

	KvGoBack(PlayerStatsSave);
}

ClientSaveToFileSave(Client)
{
	decl String:user_name[MAX_NAME_LENGTH]="";
	GetClientName(Client, user_name, sizeof(user_name));

	ReplaceString(user_name, sizeof(user_name), "\"", "{DQM}");//DQM Double quotation mark
	ReplaceString(user_name, sizeof(user_name), "\'", "{SQM}");//SQM Single quotation mark
	ReplaceString(user_name, sizeof(user_name), "/*", "{SST}");//SST Slash Star
	ReplaceString(user_name, sizeof(user_name), "*/", "{STS}");//STS Star Slash
	ReplaceString(user_name, sizeof(user_name), "//", "{DSL}");//DSL Double Slash
	KvJumpToKey(PlayerStatsSave, user_name, true);

	KvSetNum(PlayerStatsSave, "Boomer", playerBoomerKilled[Client]);
	KvSetNum(PlayerStatsSave, "Smoker", playerSmokerKilled[Client]);
	KvSetNum(PlayerStatsSave, "Hunter", playerHunterKilled[Client]);
	KvSetNum(PlayerStatsSave, "Jockey", playerJockeyKilled[Client]);
	KvSetNum(PlayerStatsSave, "Spitter", playerSpitterKilled[Client]);
	KvSetNum(PlayerStatsSave, "Charger", playerChargerKilled[Client]);
	KvSetNum(PlayerStatsSave, "Witch", playerWitchKilled[Client]);
	KvSetNum(PlayerStatsSave, "TankDamage", playerTankDamage[Client]);
	KvSetNum(PlayerStatsSave, "Common", playerCommonKilled[Client]);
	KvSetNum(PlayerStatsSave, "GunFired", playerGunfiredTime[Client]);
	//KvSetNum(PlayerStatsSave, "MeleeShoved", playerMeleeShovedTime[Client]);
	KvSetNum(PlayerStatsSave, "SucessHit", playerHitedenemy[Client]);
	
	decl String:DisconnectDate[128] = "";
	if(IsAdmin[Client])
		FormatTime(DisconnectDate, sizeof(DisconnectDate), "%j:1-%Y/%m/%d %H:%M:%S");
	else
		FormatTime(DisconnectDate, sizeof(DisconnectDate), "%j:0-%Y/%m/%d %H:%M:%S");

	KvSetString(PlayerStatsSave,"DATE", DisconnectDate);
	
	KvRewind(PlayerStatsSave);
	KeyValuesToFile(PlayerStatsSave, SavePath);
}

static Initialization(i)
{
	playerBoomerKilled[i]=0;
	playerSmokerKilled[i]=0;
	playerHunterKilled[i]=0;
	playerJockeyKilled[i]=0;
	playerSpitterKilled[i]=0;
	playerChargerKilled[i]=0;
	playerWitchKilled[i]=0;
	playerTankDamage[i]=0;
	playerCommonKilled[i]=0;
	playerGunfiredTime[i] =0;
	//playerMeleeShovedTime[i]=0;
	playerHitedenemy[i]=0;
}

public Action:OnWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:weapon[25];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if(!StrEqual(weapon, "melee"))
	{
		playerGunfiredTime[GetClientOfUserId(GetEventInt(event, "userid"))]++;
	}
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
	playerHitedenemy[GetClientOfUserId(GetEventInt(event, "attacker"))]++;

public Action:CleanSaveFile(Handle:timer)
{
	decl String:section[256];
	decl String:curDayStr[8] = "";
	decl String:curYearStr[8] = "";

	FormatTime(curDayStr,sizeof(curDayStr),"%j");
	FormatTime(curYearStr,sizeof(curYearStr),"%Y");

	new curDay	= StringToInt(curDayStr);
	new curYear	= StringToInt(curYearStr);
	new delDays	= GetConVarInt(CleanSaveFileDays);


	KvGotoFirstSubKey(PlayerStatsSave);

	new statsEntries = 1;
	new statsChecked = 0;

	while (KvGotoNextKey(PlayerStatsSave))
	{
		statsEntries++;
	}
	PrintToServer("Today is %d %d ,Save file total :%d,Clear out...", curYear, curDay, statsEntries);
	KvRewind(PlayerStatsSave);
	KvGotoFirstSubKey(PlayerStatsSave);
	while (statsChecked < statsEntries)
	{
		statsChecked++;

		KvGetSectionName(PlayerStatsSave, section, 256);

		decl String:lastConnStr[128] = "";
		KvGetString(PlayerStatsSave,"DATE",lastConnStr,sizeof(lastConnStr),"Failed");

		if (!StrEqual(lastConnStr, "Failed", false)) //"%j:0-%Y" 000:0-0000
		{
			new String:lastDayStr[8], String:IsAdminStr[8], String:lastYearStr[8];

			lastDayStr[0] = lastConnStr[0];
			lastDayStr[1] = lastConnStr[1];
			lastDayStr[2] = lastConnStr[2];
			new lastDay	= StringToInt(lastDayStr);

			IsAdminStr[0] = lastConnStr[4];
			new isAdmin = StringToInt(IsAdminStr);

			lastYearStr[0] = lastConnStr[6];
			lastYearStr[1] = lastConnStr[7];
			lastYearStr[2] = lastConnStr[8];
			lastYearStr[3] = lastConnStr[9];
			new lastYear = StringToInt(lastYearStr);

			new daysSinceVisit = (curDay+((curYear-lastYear)*365)) - lastDay;

			if (daysSinceVisit > delDays-1 && delDays != 0)
			{
				if (isAdmin==1)
				{
					KvGotoNextKey(PlayerStatsSave);
				}
				else
				{
					KvDeleteThis(PlayerStatsSave);
				}
			}
			else KvGotoNextKey(PlayerStatsSave);
		}
		else KvDeleteThis(PlayerStatsSave);
	}

	KvRewind(PlayerStatsSave);
	KeyValuesToFile(PlayerStatsSave, SavePath);
	return Plugin_Handled;
}
/* Witch Killed */
public Action:Event_WitchKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(killer) == 2 && !IsFakeClient(killer))
	{
		playerWitchKilled[killer] += 1;
	}
}

public Action:Event_PlayerChangename(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:oldname[256];
	decl String:newname[256];
	GetEventString(event, "oldname", oldname, sizeof(oldname));
	GetEventString(event, "newname", newname, sizeof(newname));
	Initialization(target);
	decl String:user_name[MAX_NAME_LENGTH]="";
	GetClientName(target, user_name, sizeof(user_name));
	KvJumpToKey(PlayerStatsSave, user_name, false);
	KvGoBack(PlayerStatsSave);
	return Plugin_Continue;
}

public Action:Menu_ShowStats(Client,args)
{
	MenuFunc_Stats(Client);
	return Plugin_Handled;
}

public Action:MenuFunc_Stats(Client)
{
	PrintToChat(Client, "\x03════════════════Persional Server Info════════ ");
	PrintToChat(Client, "\x01Boomer Killed:\x04%d\x01/Smoker Killed:\x04%d\x01/Hunter Killed:\x04%d\x01/Jockey Killed:\x04%d\x01/Charger Killed:\x04%d\x01", playerBoomerKilled[Client], playerSmokerKilled[Client], playerHunterKilled[Client], playerJockeyKilled[Client], playerChargerKilled[Client]);
	PrintToChat(Client, "\x01Witch Killed:\x04%d\x01/Tank total damage:\x04%d\x01/Common Infected Killed:\x04%d\x01", playerWitchKilled[Client], playerTankDamage[Client], playerCommonKilled[Client]);
	PrintToChat(Client, "\x01Weapon Fired:\x04%d\x01/Total Hits:\x04%d\x01/ Accuracy:\x04%.1f%%\x01", playerGunfiredTime[Client], playerHitedenemy[Client], playerGunfiredTime[Client] ? float(playerHitedenemy[Client]) / float(playerGunfiredTime[Client]) * 100.0 : 0.0);
	PrintToChat(Client, "\x03══════════════════════════════════ ");
	return Plugin_Handled;
}