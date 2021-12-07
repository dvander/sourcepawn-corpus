#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <left4downtown>

new iDistance;
new witchIndex;

new bool:bPointsFrozen;

new tCount;
new wCount;

new cTank;

public Plugin:myinfo = 
{
	name = "[L4D2] Versus Scoring Fix",
	author = "Visor; originally by Jahze, vintik, cravenge",
	version = "2.2",
	description = "Fixes Scores In Versus While Boss Infected Spawn.",
	url = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
	decl String:gName[12];
	GetGameFolderName(gName, sizeof(gName));
	if(StrEqual(gName, "left4dead2"))
	{
		cTank = 8;
	}
	else
	{
		cTank = 5;
	}
	
	HookEvent("round_start", EventHook:OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", EventHook:OnTankSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("witch_spawn", OnWitchSpawn);
	HookEvent("witch_killed", EventHook:OnWitchKilled, EventHookMode_PostNoCopy);
}

public OnRoundStart()
{
	witchIndex = -1;
	
	tCount = 0;
	wCount = 0;
	
	if (InSecondHalfOfRound())
	{
		UnFreezePoints();
	}
}

public OnTankSpawn()
{
	tCount++;
	if(bPointsFrozen)
	{
		return;
	}
	
	bPointsFrozen = true;
	FreezePoints();
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsTank(client))
	{
		tCount--;
		CreateTimer(0.1, CheckForTanksDelay, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:CheckForTanksDelay(Handle:timer) 
{
	if(!bPointsFrozen || tCount > 0 || wCount > 0)
	{
		return Plugin_Stop;
	}
	
	bPointsFrozen = false;
	UnFreezePoints();
	
	return Plugin_Stop;
}

public Action:OnWitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	wCount++;
	if(bPointsFrozen)
	{
		return;
	}
	
	witchIndex = GetEventInt(event, "witchid");
	bPointsFrozen = true;
	FreezePoints();
}

public OnWitchKilled()
{
	wCount--;
	if(!bPointsFrozen || wCount > 0 || tCount > 0)
	{
		return;
	}
	
	bPointsFrozen = false;
	UnFreezePoints();
	witchIndex = -1;
}

FreezePoints() 
{
	iDistance = L4D_GetVersusMaxCompletionScore();
	L4D_SetVersusMaxCompletionScore(0);
}

UnFreezePoints() 
{
	L4D_SetVersusMaxCompletionScore(iDistance);
}

bool:IsTank(client)
{
	if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_zombieClass") != cTank)
	{
		return false;
	}
	
	return true;
}

InSecondHalfOfRound()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound");
}

