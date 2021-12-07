#pragma semicolon 1

#include <sourcemod>

new PlayerCount = 0;
new Float:GameTime = 0.0;
new Handle:IsPausableHandle = INVALID_HANDLE;
new bool:IsPausable = false;

public Plugin:myinfo = 
{
	name = "Pause protect",
	author = "Anhil",
	description = "Protects server from those guys who pauses and leaves server (thanks to RapHero for realization idea).",
	version = "1.0",
	url = "http://forums.alliedmods.net/"
};

public OnPluginStart()
{
	decl String:gameFolder[PLATFORM_MAX_PATH];
	GetGameFolderName(gameFolder,sizeof(gameFolder));
	if(!StrEqual(gameFolder,"hl2mp",false))
		SetFailState("This plugin is for HL2:DM only.");
	/* Checking for game */
	IsPausableHandle = FindConVar("sv_pausable");
	IsPausable = GetConVarBool(IsPausableHandle);
	if(IsPausable)
	{
		for (new player = 1; player <= GetMaxClients(); player++)
			if (IsClientInGame(player) && !IsFakeClient(player))
				PlayerCount++; // If plugin was loaded in middle of map
		PrintToServer("[PauseProtect-debug] Plugin loaded, PlayerCount = %d, sv_pausable is 1", PlayerCount);
		LogToGame("[PauseProtect-debug] Plugin loaded, PlayerCount = %d, sv_pausable is 1", PlayerCount);
	}
	else
	{
		PrintToServer("[PauseProtect-debug] Plugin loaded, sv_pausable is 0", PlayerCount);
		LogToGame("[PauseProtect-debug] Plugin loaded, sv_pausable is 0", PlayerCount);
	}
	HookConVarChange(IsPausableHandle, OnSvPausableChange);
}

public OnClientPutInServer(client)
{
	if(IsPausable)
	{
		if(!IsFakeClient(client))
			PlayerCount++;
		PrintToServer("[PauseProtect-debug] Client connected, Name = %N, IsFakeClient() = %d, PlayerCount = %d", client, IsFakeClient(client), PlayerCount);
		LogToGame("[PauseProtect-debug] Client connected, Name = %N, IsFakeClient() = %d, PlayerCount = %d", client, IsFakeClient(client), PlayerCount);
	}
}
public OnClientDisconnect(client)
{
	if(IsPausable)
	{
		if(!IsFakeClient(client))
			PlayerCount--;
		PrintToServer("[PauseProtect-debug] Client disconnected, Name = %N, IsFakeClient() = %d, PlayerCount = %d", client, IsFakeClient(client), PlayerCount);
		LogToGame("[PauseProtect-debug] Client disconnected, Name = %N, IsFakeClient() = %d, PlayerCount = %d", client, IsFakeClient(client), PlayerCount);
		if(PlayerCount == 0)
		{
			GameTime = GetGameTime();
			CreateTimer(0.1, Timer);
			PrintToServer("[PauseProtect-debug] PlayerCount == 0, GetGameTime() == %f, launching timer", GameTime);
			LogToGame("[PauseProtect-debug] PlayerCount == 0, GetGameTime() == %f, launching timer", GameTime);
		}
	}
}

public Action:Timer(Handle:timer)
{
	if(GameTime == GetGameTime())
	{
		new String:map[64];
		new Handle:nextmap = FindConVar("sm_nextmap");
		if(nextmap != INVALID_HANDLE)
			GetConVarString(nextmap, map, sizeof(map));
		else
			GetCurrentMap(map, sizeof(map));
		PrintToServer("[PauseProtect-debug] Timer expired. GetGameTime is same as that which was on disconnect, changing map to %s", map);
		LogToGame("[PauseProtect-debug] Timer expired. GetGameTime is same as that which was on disconnect, changing map to %s", map);
		ServerCommand("changelevel %s", map);
	}
	else
	{
		PrintToServer("[PauseProtect-debug] Timer expired. GetGameTime is different to that which was on disconnect, value is %f", GetGameTime());
		LogToGame("[PauseProtect-debug] Timer expired. GetGameTime is different to that which was on disconnect, value is %f", GetGameTime());
	}
	return Plugin_Stop;
}

public OnSvPausableChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	IsPausable = GetConVarBool(IsPausableHandle);
	if(IsPausable)
	{
		for (new player = 1; player <= GetMaxClients(); player++)
			if (IsClientInGame(player) && !IsFakeClient(player))
				PlayerCount++;
		PrintToServer("[PauseProtect-debug] sv_pausable changed to 1, PlayerCount = %d", PlayerCount);
		LogToGame("[PauseProtect-debug] sv_pausable changed to 1, PlayerCount = %d", PlayerCount);
	}
	else
	{
		PlayerCount = 0;
		PrintToServer("[PauseProtect-debug] sv_pausable changed to 0, PlayerCount reseted");
		LogToGame("[PauseProtect-debug] sv_pausable changed to 0, PlayerCount reseted");
	}
} 