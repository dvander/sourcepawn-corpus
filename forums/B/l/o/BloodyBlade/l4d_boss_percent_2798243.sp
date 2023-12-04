#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>
#include <colors>

public Plugin myinfo =
{
	name = "L4D1 Boss Flow Announce",
	author = "Harry",
	version = "1.0",
	description = "Announce boss flow percents!",
	url = "http://steamcommunity.com/profiles/76561198026784913"
};

int iWitchPercent = 0;
int iTankPercent = 0;

ConVar hCvarPrintToEveryone, hCvarTankPercent, hCvarWitchPercent;
bool InSecondHalfOfRound;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{ 
	CreateNative("SaveBossPercents",Native_SaveBossPercents);
	RegPluginLibrary("l4d_boss_percent");
	return APLRes_Success;
}

public void OnPluginStart()
{
	hCvarPrintToEveryone = CreateConVar("l4d_global_percent", "0", "Display boss percentages to entire team when using commands", FCVAR_NOTIFY);
	hCvarTankPercent = CreateConVar("l4d_tank_percent", "1", "Display Tank flow percentage in chat", FCVAR_NOTIFY);
	hCvarWitchPercent = CreateConVar("l4d_witch_percent", "1", "Display Witch flow percentage in chat", FCVAR_NOTIFY);

	RegConsoleCmd("sm_boss", BossCmd);
	RegConsoleCmd("sm_tank", BossCmd);
	RegConsoleCmd("sm_witch", BossCmd);
	RegConsoleCmd("sm_t", BossCmd);

	HookEvent("round_end", PD_ev_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", LeftStartAreaEvent, EventHookMode_PostNoCopy);
	
	//Autoconfig for plugin
	AutoExecConfig(true, "l4d_boss_percent");
}

public void LeftStartAreaEvent(Event event, char[] name, bool dontBroadcast)
{
	for (int client = 1; client <= MaxClients; client++)
		if (IsClientInGame(client)&& !IsFakeClient(client))
			PrintBossPercents(client);
}
public void OnMapStart()
{
	//LogMessage("this is OnMapStart and InSecondHalfOfRound is false");
	//每一關地圖載入後都會進入OnMapStart()
	InSecondHalfOfRound = false;
}

public int Native_SaveBossPercents(Handle plugin, int numParams)
{
	CreateTimer(1.0, SaveBossFlows);
	return 0;
}

public void PD_ev_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	//LogMessage("this is PD_ev_RoundEnd , InSecondHalfOfRound is true");
	if(!InSecondHalfOfRound)//第一回合結束
		InSecondHalfOfRound = true;
}

public Action SaveBossFlows(Handle timer)
{
	if (!InSecondHalfOfRound)
	{
		iWitchPercent = 0;
		iTankPercent = 0;
	
		if (L4D2Direct_GetVSWitchToSpawnThisRound(0))
		{
			iWitchPercent = RoundToNearest(GetWitchFlow(0) * 100.0);
		}
		if (L4D2Direct_GetVSTankToSpawnThisRound(0))
		{
			iTankPercent = RoundToNearest(GetTankFlow(0) * 100.0);
		}
	}
	else
	{
		if (iWitchPercent != 0)
		{
			iWitchPercent = RoundToNearest(GetWitchFlow(1) * 100.0);
		}
		if (iTankPercent != 0)
		{
			iTankPercent = RoundToNearest(GetTankFlow(1) * 100.0);
		}
	}

	return Plugin_Continue;
}

stock void PrintBossPercents(int client)
{
	if(hCvarTankPercent.BoolValue)
	{
		if (iTankPercent)
			CPrintToChat(client, "{default}[{olive}TS{default}] {red}Tank{default}:{green} %d%%", iTankPercent);
		else
			CPrintToChat(client, "{default}[{olive}TS{default}] {red}Tank{default}:{green} None");
	}

	if(hCvarWitchPercent.BoolValue)
	{
		if (iWitchPercent > 0)
			CPrintToChat(client, "{default}[{olive}TS{default}] {red}Witch{default}:{green} %d%%", iWitchPercent);
		else
			CPrintToChat(client, "{default}[{olive}TS{default}] {red}Witch{default}:{green} None");
			
	}
}

public Action BossCmd(int client, int args)
{
	int iTeam = GetClientTeam(client);

	if (hCvarPrintToEveryone.BoolValue)//打這指令的只有自己看到
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i)&& !IsFakeClient(i) && GetClientTeam(i) == iTeam)
				PrintBossPercents(i);
		}
	}
	else
	{
		PrintBossPercents(client);
	}

	return Plugin_Handled;
}

stock float GetTankFlow(int round)
{
	float tankflow = L4D2Direct_GetVSTankFlowPercent(round); 
	return tankflow;
}

stock float GetWitchFlow(int round)
{
	float witchflow = L4D2Direct_GetVSWitchFlowPercent(round);
	return witchflow;
}
