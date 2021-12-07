#pragma semicolon 1
#include <sourcemod>
new String:cvars[][] = {"sm_nextmap", "bot_quota"};

public Plugin:myinfo = 
{
	name = "CVar Supression",
	author = "Kyle Sanderson",
	description = "Got Milk?",
	url = "http://www.SourceMod.net"
}

public OnPluginStart()
{
	for(new i = 0; i <sizeof(cvars); i++)
	{
		new Handle:CVarHandle = FindConVar(cvars[i]);
		if (CVarHandle != INVALID_HANDLE)
		{
			new flags;
			flags = GetConVarFlags(CVarHandle);
			flags &= ~FCVAR_NOTIFY;
			SetConVarFlags(CVarHandle, flags);
			CloseHandle(CVarHandle);
			return;
		}
		ThrowError("Couldn't find %s. What sort of game is this?", cvars[i]);
		return;
	}
}