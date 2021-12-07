#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

bool g_bStop;
Handle g_hStop;

ConVar cMin, cMax, cLimit;

static const char szNames[][] = 
{
	"smoker auto",
	"smoker auto",
	"boomer auto",
    "hunter auto",
    "spitter auto",
    "jockey auto",
    "charger auto"
};

public Plugin myinfo =
{
    name        = "Coffee",
    author      = "BHaType",
    description = "0x90",
    version     = "0x90",
    url         = "0x90"
}

public void OnPluginStart()
{
	cMin = CreateConVar("sm_wave_spawn_min",  "3", "Min time", FCVAR_NONE);
	cMax = CreateConVar("sm_wave_spawn_max",  "10", "Max time", FCVAR_NONE);
	cLimit = CreateConVar("sm_wave_limit_specials",  "5", "Limit of specials", FCVAR_NONE);
	
	HookEvent("panic_event_finished", eEvent, EventHookMode_PostNoCopy);
	
	HookEvent("round_end", eEvent, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", eEvent, EventHookMode_PostNoCopy);
	
	Handle hGamedata = LoadGameConfigFile("CMegaWave");
	if( hGamedata == null ) SetFailState("Failed to load gamedata.");
	
	Handle hDetour = DHookCreateFromConf(hGamedata, "CStartMegaWave");
	if( !DHookEnableDetour(hDetour, false, detour) ) SetFailState("Failed to detour \"CStartMegaWave\".");
	
	AutoExecConfig(true, "mega_wave_infected");
}

public void OnMapEnd()
{
	if(g_hStop != null)
		delete g_hStop;
		
	g_bStop = true;
}

public void OnPluginEnd()
{
	if(g_hStop != null)
		delete g_hStop;
		
	g_bStop = true;
}

public MRESReturn detour(Handle hReturn, Handle hParams)
{
	g_bStop = false;
		
	if(g_hStop == null)
		g_hStop = CreateTimer(GetRandomFloat(cMin.FloatValue, cMax.FloatValue), tSpawn, _, TIMER_REPEAT);
	
	return MRES_Ignored;
}

public void eEvent(Event event, const char[] name, bool dontBroadcast)
{
	if(strcmp(name, "panic_event_finished") == 0)
	{
		if(g_hStop != null)
			delete g_hStop;
			
		g_bStop = true;
		
		return;
	}
	else if(strcmp(name, "round_end") == 0 || strcmp(name, "mission_lost") == 0)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3)
				KickClient(i, "go away");
		}
		
		if(g_hStop != null)
			delete g_hStop;
		
		g_bStop = true;
		
		return;
	}
}

public Action tSpawn (Handle timer)
{
	if(g_bStop)
	{
		delete g_hStop;
		return Plugin_Stop;
	}
	
	int index;
	
	for(index = 1; index <= MaxClients; index++)
	{
		if(IsClientInGame(index))
			break;
	}
	
	int count;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 3)
			count++;
	}
	
	if(count >= cLimit.IntValue)
		return Plugin_Continue;
	
	if(index)
	{
		index = CreateFakeClient("fakeclient");
		Execute(index, "z_spawn_old", szNames[GetRandomInt(0, sizeof szNames - 1)]);
		CreateTimer(0.1, tKick, GetClientUserId(index));
	}
	
	return Plugin_Continue;
}

public Action tKick (Handle timer, int index)
{
	index = GetClientOfUserId(index);
	if(index && IsClientInGame(index))
		KickClient(index, "fakeclient");
}

void Execute(int client, const char[] cmd, const char[] args)
{
	int flags = GetCommandFlags(cmd);
	SetCommandFlags(cmd, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", cmd, args);
	SetCommandFlags(cmd, flags);
}