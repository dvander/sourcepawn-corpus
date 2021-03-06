/* Plugin Template generated by Pawn Studio */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new String:skyname[32];
new String:lightlevel[2];

public Plugin:myinfo = 
{
	name = "map_lightstyle",
	author = "WuTong",
	description = "Config the map light style.",
	version = "1.0",
	url = "www.modchina.com"
}

public OnPluginStart()
{
	LoadKV();
	ServerCommand("sv_skyname %s",skyname);
}

public LoadKV()
{
	new Handle:kv = CreateKeyValues("LigheStyle");
	if (!FileToKeyValues(kv,"cfg/sourcemod/lightstyle.txt"))
	{
		return;
	}
	if (KvJumpToKey(kv, "Settings"))
	{
		KvGetString(kv,"lightlevel",lightlevel, sizeof(lightlevel));
		KvGetString(kv,"skyname",skyname, sizeof(skyname));
		KvGoBack(kv);
	}
	
	CloseHandle(kv);	
}

public OnMapStart()
{
	
	SetLightStyle(0,lightlevel);

}
