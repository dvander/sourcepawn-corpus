#pragma semicolon 1

#include <sourcemod>
#include <left4dhooks>
#include <multicolors>

public Plugin:myinfo =
{
	name = "L4D1 Boss Flow Announce",
	author = "Harry",
	version = "1.0",
	description = "Announce boss flow percents!",
	url = "http://steamcommunity.com/profiles/76561198026784913"
};

new iWitchPercent = 0;
new iTankPercent = 0;

new Handle:hCvarPrintToEveryone;
new Handle:hCvarTankPercent;
new Handle:hCvarWitchPercent;
new bool:InSecondHalfOfRound;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{ 
	CreateNative("SaveBossPercents",Native_SaveBossPercents);
	RegPluginLibrary("l4d_boss_percent");
	return APLRes_Success;
}

public OnPluginStart()
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
public LeftStartAreaEvent(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new client = 1; client <= MaxClients; client++)
		if (IsClientInGame(client)&& !IsFakeClient(client))
			PrintBossPercents(client);
}
public OnMapStart()
{
	//LogMessage("this is OnMapStart and InSecondHalfOfRound is false");
	//每一關地圖載入後都會進入OnMapStart()
	InSecondHalfOfRound = false;
}

public Native_SaveBossPercents(Handle:plugin, numParams)
{
	CreateTimer(1.0, SaveBossFlows);
}

public Action:PD_ev_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	//LogMessage("this is PD_ev_RoundEnd , InSecondHalfOfRound is true");
	if(!InSecondHalfOfRound)//第一回合結束
		InSecondHalfOfRound = true;
}

public Action:SaveBossFlows(Handle:timer)
{
	if (!InSecondHalfOfRound)
	{
		iWitchPercent = 0;
		iTankPercent = 0;
	
		if (L4D2Direct_GetVSWitchToSpawnThisRound(0))
		{
			iWitchPercent = RoundToNearest(GetWitchFlow(0)*100.0);
		}
		if (L4D2Direct_GetVSTankToSpawnThisRound(0))
		{
			iTankPercent = RoundToNearest(GetTankFlow(0)*100.0);
		}
	}
	else
	{
		if (iWitchPercent != 0)
		{
			iWitchPercent = RoundToNearest(GetWitchFlow(1)*100.0);
		}
		if (iTankPercent != 0)
		{
			iTankPercent = RoundToNearest(GetTankFlow(1)*100.0);
		}
	}
}

stock PrintBossPercents(client)
{
	if(GetConVarBool(hCvarTankPercent))
	{
		if (iTankPercent)
			CPrintToChat(client, "{default}[{olive}TS{default}] {red}Tank{default}:{green} %d%%", iTankPercent);
		else
			CPrintToChat(client, "{default}[{olive}TS{default}] {red}Tank{default}:{green} None");
	}

	if(GetConVarBool(hCvarWitchPercent))
	{
		if (iWitchPercent > 0)
			CPrintToChat(client, "{default}[{olive}TS{default}] {red}Witch{default}:{green} %d%%", iWitchPercent);
		else
			CPrintToChat(client, "{default}[{olive}TS{default}] {red}Witch{default}:{green} None");
			
	}
}

public Action:BossCmd(client, args)
{
	new iTeam = GetClientTeam(client);

	if (GetConVarBool(hCvarPrintToEveryone))//打這指令的只有自己看到
	{
		for (new i = 1; i <= MaxClients; i++)
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

stock Float:GetTankFlow(round)
{
	new Float:tankflow = L4D2Direct_GetVSTankFlowPercent(round); 
	return tankflow;
}

stock Float:GetWitchFlow(round)
{
	new Float:witchflow = L4D2Direct_GetVSWitchFlowPercent(round);
	return witchflow;
}