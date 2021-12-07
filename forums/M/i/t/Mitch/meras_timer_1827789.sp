#include <sourcemod>
#define PL_VERSION "1.1"

new baseTime = 0;
new Handle:basevar = INVALID_HANDLE;
new varTime = 0;
new Handle:varvar = INVALID_HANDLE;
new minTime = 0;
new maxTime = 0;

new bool:isSpawned = false;

public Plugin:myinfo = 
{
	name = "[TF2]Merasmus Timer",
	author = "Mitch",
	description = "",
	version = PL_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("sm_meras_timer_version", PL_VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("merasmus_summoned", OnSpawn, EventHookMode_Post);
	HookEvent("merasmus_killed", OnDeath, EventHookMode_Post);
	HookEvent("merasmus_escaped", OnDeath, EventHookMode_Post);
	basevar = FindConVar("tf_merasmus_spawn_interval");
	varvar = FindConVar("tf_merasmus_spawn_interval_variation");
	CreateTimer(1.0, Timer, INVALID_HANDLE, TIMER_REPEAT);
	
}
SetTimers()
{
	baseTime = GetConVarInt(basevar);
	varTime = GetConVarInt(varvar);
	minTime = baseTime-varTime;
	maxTime = baseTime+varTime;
}
public Action:OnSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	isSpawned = true;
	return Plugin_Continue;
}
public Action:OnDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	isSpawned = false;
	SetTimers();
	return Plugin_Continue;
}
public Action:Timer(Handle:timer)
{
	if(GetClientCount(true) >= 10)
	{
		if(!isSpawned) //Not Spawned
		{
			if(minTime >= 1)
					minTime--;
			if(maxTime >= 1)
					maxTime--;
			for(new i=1; i<=MaxClients; i++)
			{
				if(IsClientInGame(i) && IsClientConnected(i) && !IsClientReplay(i) && !IsClientSourceTV(i))
				{
					HudMessageTime(i, maxTime, minTime);
				}
			}
		}
		else //He Is Spawned
		{
			for(new i=1; i<=MaxClients; i++)
			{
				if(IsClientInGame(i) && IsClientConnected(i) && !IsClientReplay(i) && !IsClientSourceTV(i))
				{
					HudMessageIsSpawned(i);
				}
			}
		}
	}
	else
	{
		SetTimers();
		/*for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && IsClientConnected(i) && !IsClientReplay(i) && !IsClientSourceTV(i))
			{
				//HudMessageIsNotEnoughPlayers(i);
			}
		}*/
	}
}
/*
public OnClientPostAdminCheck(client)
{
	playercount++;
}
public OnClientDisconnect(client)
{
	playercount--;
}
*/
HudMessageTime(client, hightime, lowtime)
{
	SetHudTextParams(0.0, 0.0, 1.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, -1, "Next Spawn: High %is Low %is", hightime, lowtime);
}
HudMessageIsSpawned(client)
{
	SetHudTextParams(0.0, 0.0, 1.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, -1, "Next Spawn: Merasmus is spawned");
}
/*
HudMessageIsNotEnoughPlayers(client)
{
	SetHudTextParams(0.0, 0.0, 1.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, -1, "Next Spawn: Not enough players");
}
*/
