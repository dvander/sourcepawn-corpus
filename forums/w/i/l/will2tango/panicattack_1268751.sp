#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "2.11"

/* ChangeLog
1.00	Release
2.00	Re Written
2.10	Translations < for niask1 :)
2.11	Timer Kill on NewRound
*/

#define SURVIVOR	2
#define ZOMBIE		3
#define READY		4

#define PANIC		0
#define DROP		1

public Plugin:myinfo =
{
	name = "ZPS Panic Attack",
	author = "Will2Tango",
	description = "Blocks Survivors from Panicing or Dropping at Round Start.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

//Cvars
new Handle:hEnabled = INVALID_HANDLE;
new Handle:hTime = INVALID_HANDLE;
new Handle:hTest = INVALID_HANDLE;

new bool:gEnabled = true;
new Float:gTime = 10.0;
new bool:gTest = false;

//Timer Handle
new Handle:hPanicTimer = INVALID_HANDLE;

//Global Player Vars
new bool:panicNotify[2][MAXPLAYERS+1] = {{false, ...}, {false, ...}};

//Global Vars
new bool:gBlock = false;
new bool:gNewRound = true;

public OnPluginStart()
{
	//Cvars
	CreateConVar("zps_panicattack_version", PLUGIN_VERSION, "Panic Attack Plugin Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hEnabled = CreateConVar("sm_panic_attack", "1", "Panic Attack Enabled. (0/1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hTime = CreateConVar("sm_panic_time", "10.0", "Time from Round Start to Block Panic and Drop. (Seconds 1-180)", FCVAR_PLUGIN, true, 1.0, true, 180.0);
	
	hTest = FindConVar("sv_testmode");
	HookConVarChange(hTest, ConVarChange);
	HookConVarChange(hEnabled, ConVarChange);
	HookConVarChange(hTime, ConVarChange);
	
	//Hooks
	HookEvent("player_spawn", PlayerSpawned);
	HookEvent("game_round_restart", NewRound);
		
	AddCommandListener(Event_Panic, "panic");
	AddCommandListener(Event_Drop, "dropweapon");
	AddCommandListener(Event_Drop, "dropammo");
	
	//Translations
	LoadTranslations("panicattack.phrases");
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	gEnabled = GetConVarBool(hEnabled);
	gTime = GetConVarFloat(hTime);
	gTest = GetConVarBool(hTest);
}

public OnConfigsExecuted()
{
	if (!gEnabled || gTest)
	{
		return;
	}
	
	gNewRound = true;
	gBlock = true;
}

public Action:NewRound(Handle:Event, const String:Name[], bool:Broadcast)
{
	if (!gEnabled || gTest)
	{
		return;
	}
	
	if (hPanicTimer != INVALID_HANDLE)
	{
		KillTimer(hPanicTimer);
		hPanicTimer = INVALID_HANDLE;
	}

	gNewRound = true;
	gBlock = true;
}

public Action:PlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!gEnabled || gTest || !gNewRound)
	{
		return Plugin_Continue;
	}
	
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new team = GetClientTeam(client);
	
	if (team == READY)
	{
		panicNotify[PANIC][client] = true;
		panicNotify[DROP][client] = true;
	}
	else if (team == ZOMBIE)
	{
		if (gTime > 0 && hPanicTimer == INVALID_HANDLE)
		{
			hPanicTimer = CreateTimer(gTime, RemoveBlock);
		}
		else
		{
			gBlock = false;
		}
		
		gNewRound = false;
	}
	
	return Plugin_Continue;
}

public Action:RemoveBlock(Handle:timer)
{
	gBlock = false;
	hPanicTimer = INVALID_HANDLE;

	return Plugin_Stop;
}

public Action:Event_Panic(client, const String:command[], argc)
{
	if (!gBlock || gNewRound || !gEnabled || gTest)
	{
		return Plugin_Continue;
	}
	
	new team = GetClientTeam(client);
	
	if (team == SURVIVOR)
	{
		if (panicNotify[PANIC][client])
		{
			PrintToChat(client, "[Panic] %t", "Panic");
			panicNotify[PANIC][client] = false;
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:Event_Drop(client, const String:command[], argc)
{
	if (!gBlock || gNewRound || !gEnabled || gTest)
	{
		return Plugin_Continue;
	}
	
	new team = GetClientTeam(client);
	
	if (team == SURVIVOR)
	{
		if (panicNotify[DROP][client])
		{
			PrintToChat(client, "[Panic] %t", "Drop");
			panicNotify[DROP][client] = false;
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}