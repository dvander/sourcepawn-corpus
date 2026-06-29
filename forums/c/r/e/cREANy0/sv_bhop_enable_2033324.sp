#include <sourcemod>
#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Enable sv_bhop",
	author = "cREANy0 (code by Sheepdude)",
	description = "Sets sv_bhop to 1 on map start",
	version = "1.0",
	url = "-"
};

new Handle:SV_BHOP = INVALID_HANDLE;

public OnPluginStart()
{
	SV_BHOP = FindConVar("sv_bhop");
	HookEvent("round_freeze_end", OnNewRound, EventHookMode_Pre);
}

public OnNewRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(SV_BHOP != INVALID_HANDLE)
		SetConVarInt(SV_BHOP, 1);
}