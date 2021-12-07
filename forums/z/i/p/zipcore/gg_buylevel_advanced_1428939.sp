#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <gungame>

#define PLUGIN_VERSION "1.1"

// chat colors
#define YELLOW "\x01"
#define GREEN "\x04"

// CVAR-Handles
new Handle:cvar_Buylevel_Version = INVALID_HANDLE;
new Handle:cvar_Buylevel_Enable = INVALID_HANDLE;
new Handle:cvar_Buylevel_Cost = INVALID_HANDLE;
new Handle:cvar_Buylevel_Blockskip = INVALID_HANDLE;
new Handle:cvar_Buylevel_Announce = INVALID_HANDLE;
new Handle:cvar_Buylevel_Killreward = INVALID_HANDLE;
new Handle:cvar_Buylevel_Deathreward = INVALID_HANDLE;
new Handle:cvar_Buylevel_Levelupreward = INVALID_HANDLE;
new Handle:cvar_GunGame_Enable = INVALID_HANDLE;
new Handle:cvar_Startmoney = INVALID_HANDLE;

// CVARS
new cvstartmoney;
new cvgungameenable;
new cvbuylevelannounce;
new cvbuylevelenable;
new cvbuylevelcost;
new cvbuylevelkillreward;
new cvbuyleveldeathreward;
new cvbuylevellevelupreward;
new String:cvbuylevelblockskip[256];

new g_iAccount = -1;
new maxlevel = 24;
new CurRoundMoney[MAXPLAYERS + 1];
new bool:WarmupInProgress = false;
new bool:GameIsOver = false;
new bool:FirstSpawn[MAXPLAYERS + 1];
new bool:IHateFloods[MAXPLAYERS + 1];
new bool:BuyLevelLvlUp[MAXPLAYERS + 1];
new bool:RoundEnd = false;
new String:plugin_name[128];
new Leader;

public Plugin:myinfo =
{
	name = "SM GunGame Buylevel",
	author = "Miraculix",
	description = "Players can skip current level by buying the next level.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=93977"
};

public OnPluginStart()
{
	// ConVars
	cvar_Buylevel_Version = CreateConVar("sm_ggbuylevel_version", PLUGIN_VERSION, "SM GunGame Buylevel Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_Buylevel_Enable = CreateConVar("sm_ggbuylevel_enable","1","Enables/Disables SM GunGame Buylevel.",FCVAR_PLUGIN);
	cvar_Buylevel_Cost = CreateConVar("sm_ggbuylevel_cost","16000","The amount required to buy a level.",FCVAR_PLUGIN);
	cvar_Buylevel_Blockskip = CreateConVar("sm_ggbuylevel_block_skip","hegrenade,knife","Block these weapons from being skipped with buylevel.\nThe last level will always be blocked from skipping.",FCVAR_PLUGIN);
	cvar_Buylevel_Announce = CreateConVar("sm_ggbuylevel_announce","1","Announce how to use buylevel.",FCVAR_PLUGIN);
	cvar_Buylevel_Killreward = CreateConVar("sm_ggbuylevel_kill_reward","750","The amount earned per kill.",FCVAR_PLUGIN);
	cvar_Buylevel_Deathreward = CreateConVar("sm_ggbuylevel_death_reward","2500","The amount earned per kill.",FCVAR_PLUGIN);
	cvar_Buylevel_Levelupreward = CreateConVar("sm_ggbuylevel_levelup_reward","800","The amount earned per levelup.",FCVAR_PLUGIN);

	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");

	// create config file
	AutoExecConfig(true, "gungame_buylevel");

	// Update the Plugin Version cvar
	SetConVarString(cvar_Buylevel_Version, PLUGIN_VERSION);

	RegConsoleCmd("sm_buylevel", Command_Buylevel);

	HookEvent("round_start", EventRoundStart);
	HookEvent("round_end",EventRoundEnd);
}

public OnMapStart()
{
	GameIsOver = false;
	Leader = 0;
}

public OnConfigsExecuted()
{
	Format(plugin_name, sizeof(plugin_name), "%c[!buylevel]%c", GREEN, YELLOW);
	maxlevel = GG_GetMaxLevel();
	cvbuylevelenable = GetConVarInt(cvar_Buylevel_Enable);
	GetConVarString(cvar_Buylevel_Blockskip, cvbuylevelblockskip, sizeof(cvbuylevelblockskip));
	cvbuylevelcost = GetConVarInt(cvar_Buylevel_Cost);
	cvbuylevelannounce = GetConVarInt(cvar_Buylevel_Announce);
	cvbuylevelkillreward = GetConVarInt(cvar_Buylevel_Killreward);
	cvbuyleveldeathreward = GetConVarInt(cvar_Buylevel_Deathreward);
	cvbuylevellevelupreward = GetConVarInt(cvar_Buylevel_Levelupreward);

	cvar_Startmoney = FindConVar("mp_startmoney");
	cvstartmoney = GetConVarInt(cvar_Startmoney);

	cvar_GunGame_Enable = FindConVar("gungame_enabled");
	if (cvar_GunGame_Enable != INVALID_HANDLE)
		cvgungameenable = GetConVarInt(cvar_GunGame_Enable);
	else
		cvgungameenable = 1;
}

public OnClientAuthorized(client)
{
	FirstSpawn[client] = true;
	if(cvbuylevelannounce > 0)
		IHateFloods[client] = true;
	else
		IHateFloods[client] = false;

	BuyLevelLvlUp[client] = false;
	CurRoundMoney[client] = cvstartmoney;
}

// buylevel kill reward
public Action:GG_OnClientDeath(Killer, Victim, Weapons:WeaponId, bool:TeamKilled)
{
	if (TeamKilled)
		return Plugin_Continue;

	if (WarmupInProgress)
		return Plugin_Continue;

	new KillerMoney = GetEntData(Killer, g_iAccount, 4);
	new NewKillerMoney = KillerMoney + cvbuylevelkillreward - 300;
	if (NewKillerMoney > 16000)
			NewKillerMoney = 16000;
	SetEntData(Killer, g_iAccount, NewKillerMoney, 4, true);

	new VictimMoney = GetEntData(Victim, g_iAccount, 4);
	new NewVictimMoney = VictimMoney + cvbuyleveldeathreward;
	if (NewVictimMoney > 16000)
			NewVictimMoney = 16000;
	SetEntData(Victim, g_iAccount, NewVictimMoney, 4, true);
	
	return Plugin_Continue;
}

// buylevel levelup reward
public Action:GG_OnClientLevelChange(client, level, difference, bool:steal, bool:last, bool:knife)
{
	if (!difference || (difference < 0))
		return Plugin_Continue;

	if (BuyLevelLvlUp[client])
	{
		BuyLevelLvlUp[client] = false;
		return Plugin_Continue;
	}
	if (difference > 0)
	{
		new ClientMoney = GetEntData(client, g_iAccount, 4);
		new NewClientMoney = ClientMoney + cvbuylevellevelupreward;
		if (NewClientMoney > 16000)
			NewClientMoney = 16000;
		SetEntData(client, g_iAccount, NewClientMoney, 4, true);
	}

	return Plugin_Continue;
}

// checks client
IsValidClient(client)
{
	if(client == 0)
		return false;

	else if(!IsClientConnected(client))
		return false;

	else if(IsFakeClient(client))
		return false;

	else if(!IsClientInGame(client))
		return false;

	return true;
}

// checks player not spectator
IsPlayerInTeam(client)
{
	new Team = GetClientTeam(client);

	if((Team < 2) || (Team > 3))
		return false;

	return true;
}

bool:IsBuylevelEnable()
{
	if(!cvbuylevelenable)
		return false;
	if(!cvgungameenable)
		return false;

	return true;
}

ClientBuylevel(client)
{
	new ClientMoney = GetEntData(client, g_iAccount, 4);
	new LevelCost = cvbuylevelcost;
	if(ClientMoney < LevelCost)
	{
		PrintToChat(client, "%s You need at least %c$%d%c to buy a level!", plugin_name, GREEN, cvbuylevelcost, YELLOW);
	}
	else
	{
		new NewClientMoney = ClientMoney - LevelCost;
		SetEntData(client, g_iAccount, NewClientMoney, 4, true);
		BuyLevelLvlUp[client] = true;
		if (RoundEnd)
			CurRoundMoney[client] -= LevelCost;
		GG_AddALevel(client);
	}
}

public Action:Command_Buylevel(client, args)
{
	if (!IsBuylevelEnable())
		return Plugin_Handled;

	if (WarmupInProgress)
	{
		PrintToChat(client, "%s You may not buy a level until the game starts!", plugin_name);
		return Plugin_Handled;
	}
	if (!IsPlayerInTeam(client))
	{
		PrintToChat(client, "%s You can't skip level when not in a team.", plugin_name);
		return Plugin_Handled;
	}
	if (GameIsOver)
	{
		PrintToChat(client, "%s You can't skip level after game ends.", plugin_name);
		return Plugin_Handled;
	}
	if (IsPlayerAlive(client))
	{
		PrintToChat(client, "%s You can't skip level while alive.", plugin_name);
		return Plugin_Handled;
	}
	if (client == Leader)
	{
		PrintToChat(client, "%s You can't skip level while leading.", plugin_name);
		return Plugin_Handled;
	}
	else
	{
		new ClientLevel = GG_GetClientLevel(client);
		new String:curWeaponName[128];
		new bool:IsNadeKnife = false;

		GG_GetLevelWeaponName(ClientLevel, curWeaponName, sizeof(curWeaponName));
		IsNadeKnife = StrContains(cvbuylevelblockskip, curWeaponName, false) < 0 ? false : true;

		if (IsNadeKnife || (maxlevel == ClientLevel))
		{
			PrintToChat(client, "%s You cannot skip %s level!", plugin_name, curWeaponName);
			return Plugin_Handled;
		}
		else
		{
			ClientBuylevel(client);
			return Plugin_Handled;
		}
	}
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsBuylevelEnable())
		return;

	RoundEnd = false;

	WarmupInProgress = GG_IsWarmupInProgress();

	if (WarmupInProgress) return;

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i)) continue;

		SetEntData(i, g_iAccount, CurRoundMoney[i], 4, true);

		if(FirstSpawn[i])
		{
			FirstSpawn[i] = false;
			continue;
		}

		if(IHateFloods[i])
		{
			PrintToChat(i, "%s Type %c!buylevel%c in chat to purchase a level for %c$%d%c", plugin_name, GREEN, YELLOW, GREEN, cvbuylevelcost, YELLOW);
			IHateFloods[i] = false;
		}
	}
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsBuylevelEnable())
		return;

	RoundEnd = true;

	if (WarmupInProgress) return;

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i)) continue;
		CurRoundMoney[i] = GetEntData(i, g_iAccount, 4);
	}
}

public GG_OnLeaderChange(client, level, totalLevels)
{
	Leader = client;
}

public GG_OnWinner(client, const String:weapon[], victim)
{
    GameIsOver = true;
}
public OnMapEnd()
{
    GameIsOver = false;
}
