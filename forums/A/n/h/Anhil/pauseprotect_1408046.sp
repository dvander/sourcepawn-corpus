#pragma semicolon 1

#include <sourcemod>

new PlayerCount = 0;
new Float:GameTime = 0.0;

public Plugin:myinfo = 
{
	name = "Pause protect",
	author = "Anhil",
	description = "Protects server from those guys who pauses and leaves server (thanks to RapHero for realization idea).",
	version = "1.01",
	url = "http://forums.alliedmods.net/"
};

public OnPluginStart()
{
	decl String:gameFolder[PLATFORM_MAX_PATH];
	GetGameFolderName(gameFolder,sizeof(gameFolder));
	if(!StrEqual(gameFolder,"hl2mp",false))
		SetFailState("This plugin is for HL2:DM only.");
	/* Checking for game */
	for (new player = 1; player <= GetMaxClients(); player++)
		if (IsClientInGame(player) && !IsFakeClient(player))
			PlayerCount++; // If plugin was loaded in middle of map
}

public OnClientPutInServer(client)
{
	if(!IsFakeClient(client))
		PlayerCount++;
}
public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
		PlayerCount--;
	if(PlayerCount == 0)
	{
		GameTime = GetGameTime();
		CreateTimer(0.1, Timer);
	}
}

public Action:Timer(Handle:timer)
{
	if(GameTime == GetGameTime())
	{
		new String:map[64];
		new Handle:nextmap = FindConVar("sm_nextmap");
		if(nextmap != INVALID_HANDLE)
		{
			GetConVarString(nextmap, map, sizeof(map));
			if(StrEqual(map, "") || !IsMapValid(map))
				ServerCommand("changelevel %s", map);
		}
		else
			GetCurrentMap(map, sizeof(map));
		ServerCommand("changelevel %s", map);
	}
	return Plugin_Stop;
}