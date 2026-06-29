#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.0"

bool g_iVampireActivated [MAXPLAYERS+1];
float g_fVampireTimer;

int g_iVampireKillCount [MAXPLAYERS+1];
int g_iVampireLevelOne;
int g_iVampireLevelTwo;
int g_iVampireLevelMax;

ConVar g_Cvar_VampirePluginEnables;
ConVar g_Cvar_VampireLevelOneKills;
ConVar g_Cvar_VampireLevelTwoKills;
ConVar g_Cvar_VampireLevelMaxKills;
ConVar g_Cvar_VampireLevelOneTimer;
ConVar g_Cvar_VampireLevelTwoTimer;
ConVar g_Cvar_VampireLevelMaxTimer;
ConVar g_Cvar_VampireLevelOneHeals;
ConVar g_Cvar_VampireLevelTwoHeals;
ConVar g_Cvar_VampireLevelMaxHeals;

public Plugin myinfo =
{
	name = "L4D Vampire",
	version = PLUGIN_VERSION,
	description = "Lifesteal Ability After Killing Multiple SI",
	author = "alasfourom",
	url = "https://forums.alliedmods.net"
}

public void OnPluginStart()
{
	CreateConVar ("l4d2_survivors_vampire_version", PLUGIN_VERSION, "L4D2 Survivors Vampire", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_Cvar_VampirePluginEnables = CreateConVar("l4d2_vampire_plugin_enables", "1", "Enable l4d2 vampire plugin [1 = Enable, 0 = Disable]", FCVAR_NOTIFY);
	g_Cvar_VampireLevelOneKills = CreateConVar("l4d2_vampire_levelone_kills", "5", "How many special infected you need to kill to reach level one", FCVAR_NOTIFY);
	g_Cvar_VampireLevelTwoKills = CreateConVar("l4d2_vampire_leveltwo_kills", "10", "How many special infected you need to kill to reach level two", FCVAR_NOTIFY);
	g_Cvar_VampireLevelMaxKills = CreateConVar("l4d2_vampire_levelmax_kills", "15", "How many special infected you need to kill to reach level max", FCVAR_NOTIFY);
	g_Cvar_VampireLevelOneTimer = CreateConVar("l4d2_vampire_levelone_timer", "60", "How long vampire level one can last when activated (in seconds)", FCVAR_NOTIFY);
	g_Cvar_VampireLevelTwoTimer = CreateConVar("l4d2_vampire_leveltwo_timer", "120", "How long vampire level two can last when activated (in seconds)", FCVAR_NOTIFY);
	g_Cvar_VampireLevelMaxTimer = CreateConVar("l4d2_vampire_levelmax_timer", "180", "How long vampire level max can last when activated (in seconds)", FCVAR_NOTIFY);
	g_Cvar_VampireLevelOneHeals = CreateConVar("l4d2_vampire_levelone_lifesteal", "3", "How much health you get after killing a special infected when level one is activated", FCVAR_NOTIFY);
	g_Cvar_VampireLevelTwoHeals = CreateConVar("l4d2_vampire_leveltwo_lifesteal", "6", "How much health you get after killing a special infected when level two is activated", FCVAR_NOTIFY);
	g_Cvar_VampireLevelMaxHeals = CreateConVar("l4d2_vampire_levelmax_lifesteal", "10", "How much health you get after killing a special infected when level max is activated", FCVAR_NOTIFY);
	AutoExecConfig(true, "L4D2_Survivors_Vampire");
	
	RegConsoleCmd("sm_vampire", Command_Vampire, "Activate Vampire State");
	HookEvent("player_death", Event_OnPlayerDeath);
}

public void OnMapStart()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		g_iVampireKillCount[i] = 0;
		g_iVampireActivated[i] = false;
	}
	
	g_iVampireLevelOne = g_Cvar_VampireLevelOneKills.IntValue;
	g_iVampireLevelTwo = g_Cvar_VampireLevelTwoKills.IntValue;
	g_iVampireLevelMax = g_Cvar_VampireLevelMaxKills.IntValue;
}

public Action Command_Vampire(int client, int args)
{
	if(!g_Cvar_VampirePluginEnables.BoolValue)
		return Plugin_Handled;
	
	int iLevelOne = g_iVampireLevelOne - g_iVampireKillCount[client];
	
	if(g_iVampireKillCount[client] < g_iVampireLevelTwo && g_iVampireKillCount[client] >= g_iVampireLevelOne)
	{
		g_fVampireTimer = g_Cvar_VampireLevelOneTimer.FloatValue;
		int time = RoundToNearest(g_fVampireTimer);
		PrintHintText(client, "Vampire Timeout: %d", time);
		CreateTimer (1.0, Timer_CountDown, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		
		g_iVampireActivated[client] = true;
		PrintToChat(client, "\x04[Vampire] \x01You have activated vampire: \x05Level 1");
		return Plugin_Handled;
	}
	else if (g_iVampireKillCount[client] < g_iVampireLevelMax && g_iVampireKillCount[client] >= g_iVampireLevelTwo) //level 2
	{
		g_fVampireTimer = g_Cvar_VampireLevelTwoTimer.FloatValue;
		int time = RoundToNearest(g_fVampireTimer);
		PrintHintText(client, "Vampire Timeout: %d", time);
		CreateTimer (1.0, Timer_CountDown, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		
		g_iVampireActivated[client] = true;
		PrintToChat(client, "\x04[Vampire] \x01You have activated vampire: \x05Level 2");
		return Plugin_Handled;
	}
	else if (g_iVampireKillCount[client] >= g_iVampireLevelMax) //level 3
	{
		g_fVampireTimer = g_Cvar_VampireLevelMaxTimer.FloatValue;
		int time = RoundToNearest(g_fVampireTimer);
		PrintHintText(client, "Vampire Timeout: %d", time);
		CreateTimer (1.0, Timer_CountDown, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		
		g_iVampireActivated[client] = true;
		PrintToChat(client, "\x04[Vampire] \x01You have activated vampire: \x05Level Max");
		return Plugin_Handled;
	}
	else PrintToChat(client, "\x04[Vampire] \x01You need at least \x05%d \x01kills to activate: \x03Vampire Level 1", iLevelOne);
	return Plugin_Handled;
}

public Action Timer_CountDown(Handle timer, int client)
{
	int timeleft = RoundToNearest(g_fVampireTimer--);
	
	if (timeleft >= 1)
	{
		PrintHintText(client, "Vampire Timeout: %d", timeleft);
		return Plugin_Continue;
	}
	
	else if (timeleft <= 0)
	{
		PrintHintText(client, "Vampire Deactivated");
		g_iVampireKillCount[client] = 0;
		g_iVampireActivated[client] = false;
	}
	return Plugin_Stop;
}

void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_Cvar_VampirePluginEnables.BoolValue) return;
	
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !IsClientInGame(victim) || GetClientTeam(victim) != 3) return;
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!attacker || !IsClientInGame(attacker) || IsFakeClient(attacker) || GetClientTeam(attacker) != 2 || !IsPlayerAlive(attacker)) return;
	
	int iLevelOne = g_iVampireLevelOne - g_iVampireKillCount[attacker] -1;
	int iLevelTwo = g_iVampireLevelTwo - g_iVampireKillCount[attacker] -1;
	int iLevelMax = g_iVampireLevelMax - g_iVampireKillCount[attacker] -1;
	
	int iMaxHealth = GetEntProp(attacker, Prop_Send, "m_iMaxHealth");
	int CurrentHp = GetClientHealth(attacker);
	
	if(g_iVampireActivated[attacker])
	{
		if(g_iVampireKillCount[attacker] < g_iVampireLevelTwo && g_iVampireKillCount[attacker] >= g_iVampireLevelOne) //level 1
		{
			int LifeSteal = g_Cvar_VampireLevelOneHeals.IntValue;
			
			if ((CurrentHp + LifeSteal) > iMaxHealth) SetEntProp(attacker, Prop_Send, "m_iHealth", iMaxHealth, 1);
			else SetEntProp(attacker, Prop_Send, "m_iHealth", LifeSteal + CurrentHp, 1);
		}
		else if (g_iVampireKillCount[attacker] < g_iVampireLevelMax && g_iVampireKillCount[attacker] >= g_iVampireLevelTwo) //level 2
		{
			int LifeSteal = g_Cvar_VampireLevelTwoHeals.IntValue;
			
			if ((CurrentHp + LifeSteal) > iMaxHealth) SetEntProp(attacker, Prop_Send, "m_iHealth", iMaxHealth, 1);
			else SetEntProp(attacker, Prop_Send, "m_iHealth", LifeSteal + CurrentHp, 1);
		}
		else if (g_iVampireKillCount[attacker] >= g_iVampireLevelMax) //level 3
		{
			int LifeSteal = g_Cvar_VampireLevelMaxHeals.IntValue;
			
			if ((CurrentHp + LifeSteal) > iMaxHealth) SetEntProp(attacker, Prop_Send, "m_iHealth", iMaxHealth, 1);
			else SetEntProp(attacker, Prop_Send, "m_iHealth", LifeSteal + CurrentHp, 1);
		}
	}
	else
	{
		g_iVampireKillCount[attacker]++;
		
		if(g_iVampireKillCount[attacker] < g_iVampireLevelOne)
			PrintToChat(attacker, "\x04[Vampire] \x01You got \x05+1 \x01kills, you need \x04%d \x01to reach: \x03Vampire Level 1", iLevelOne);
			
		else if(g_iVampireKillCount[attacker] == g_iVampireLevelOne)
			PrintToChat(attacker, "\x04[Vampire] \x01Your vampire level 1: \x03Ready!");
			
		else if(g_iVampireKillCount[attacker] < g_iVampireLevelTwo)
			PrintToChat(attacker, "\x04[Vampire] \x01You got \x05+1 \x01kills, you need \x04%d \x01to reach: \x03Vampire Level 2", iLevelTwo);
			
		else if(g_iVampireKillCount[attacker] == g_iVampireLevelTwo)
			PrintToChat(attacker, "\x04[Vampire] \x01Your vampire level 2: \x03Ready!");
			
		else if(g_iVampireKillCount[attacker] < g_iVampireLevelMax)
			PrintToChat(attacker, "\x04[Vampire] \x01You got \x05+1 \x01kills, you need \x04%d \x01to reach: \x03Vampire Level Max", iLevelMax);
			
		else if(g_iVampireKillCount[attacker] == g_iVampireLevelMax)
			PrintToChat(attacker, "\x04[Vampire] \x01Your vampire level max: \x03Ready!");
	}
	return;
}