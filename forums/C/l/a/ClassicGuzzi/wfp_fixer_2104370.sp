#include <sourcemod>

public Plugin:myinfo =
{
	name = "WFP Fixer",
	author = "Classic",
	description = "No more 'Wating for Players' stuck in zero.",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

//This should cancel the wfp time at given momment
//mp_waitingforplayers_cancel 1

new Handle:g_hWaitingForPlayerCancel;
new g_WaitingForPlayerCancel;

public OnPluginStart()
{
g_hWaitingForPlayerCancel = FindConVar("mp_waitingforplayers_cancel");
g_WaitingForPlayerCancel = GetConVarInt(g_hWaitingForPlayerCancel);
}

public OnMapStart()
{
	SetConVarInt(g_hWaitingForPlayerCancel, 0, true);
	CreateTimer(40.0, CancelWFP);
	CreateTimer(50.0, ActivateWFP);
}

public Action:CancelWFP(Handle:timer)
{
	PrintToChatAll("[SM]Starting...");
	SetConVarInt(g_hWaitingForPlayerCancel, 1, true);
}
public Action:ActivateWFP(Handle:timer)
{
	SetConVarInt(g_hWaitingForPlayerCancel, 0, true);
}


public OnMapEnd()
{
	SetConVarInt(g_hWaitingForPlayerCancel, g_WaitingForPlayerCancel, true);
}