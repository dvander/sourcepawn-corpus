#pragma semicolon 1
#include <sourcemod>

public OnPluginStart()
{
	HookEvent("survival_round_start", _SurvivalStart, EventHookMode_PostNoCopy);
	HookEvent("round_end ", _RoundEnd, EventHookMode_PostNoCopy);
}

public Action:_SurvivalStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarBool(FindConVar("sv_cheats"), true);
	SetConVarBool(FindConVar("buildenable"), true);
}

public Action:_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarBool(FindConVar("sv_cheats"), false);
	SetConVarBool(FindConVar("buildenable"), false);
}