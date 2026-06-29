#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Map Speed Limiter",
	author = "Tair",
	description = "The plugin limits the max velocity in the server.",
	version = "1.0",
	url = "https://forums.alliedmods.net/"
}

public void OnMapStart()
{
	CreateTimer(2.0, Timer_SetSpeed);	
}

public Action Timer_SetSpeed(Handle timer)
{
	char mapname[32];
	GetCurrentMap(mapname, sizeof(mapname));
	
	KeyValues kv = new KeyValues("Maps");
	kv.ImportFromFile("addons/sourcemod/configs/mapspeedlimit.cfg");
 
	if (!kv.JumpToKey(mapname))
	{
		SetConVarInt(FindConVar("sv_maxvelocity"), 100000);
		delete kv;
		return;
	}
 	char kvSpeed[6];
	kv.GetString("maxspeed", kvSpeed, sizeof(kvSpeed));
	SetConVarInt(FindConVar("sv_maxvelocity"), StringToInt(kvSpeed));
	delete kv;
}
