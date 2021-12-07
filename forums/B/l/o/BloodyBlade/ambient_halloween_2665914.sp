#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

ConVar gc_bFog;
ConVar gc_bFogRandom;
ConVar gc_iFogDensity;
ConVar gc_bHowl;
ConVar gc_fHowlTimer;

int g_iFog = -1;

public Plugin myinfo =
{
	name = "Ambient Halloween",
	author = "Hypr (edited by Dragokas)",
	description = "Makes your server spooky",
	version = PLUGIN_VERSION,
	url = "https://condolent.xyz"
};

/*
	- Removed dependency on includes
	- Added switch off on some maps
*/

public void OnPluginStart()
{
	gc_bFog = CreateConVar("sm_halloween_fog", "1", "Enable fog?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bFogRandom = CreateConVar("sm_halloween_fog_random", "1", "Make the fog random each round?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_iFogDensity = CreateConVar("sm_halloween_fog_density", "0.35", "Max density of the fog", FCVAR_NOTIFY);
	gc_bHowl = CreateConVar("sm_halloween_howl", "1", "Enable howling?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_fHowlTimer = CreateConVar("sm_halloween_howl_timer", "300", "Time in seconds between each howling sound.", FCVAR_NOTIFY, true, 1.0);
	
	AutoExecConfig(true, "halloween.ambient");
	
	HookEvent("round_start", OnRoundStart);
}

public void OnMapStart()
{
	if(gc_bHowl.IntValue == 1 && MapAllowed())
	{
		PrecacheSound("npc/witch/voice/die/female_death_1.wav", true);
		CreateTimer(gc_fHowlTimer.FloatValue, HowlTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(gc_bFog.IntValue == 1 && MapAllowed())
	{
		int iEnt = FindEntityByClassname(-1, "env_fog_controller");	
		if(iEnt != -1)
		{
			g_iFog = iEnt;
		}
		else
		{
			g_iFog = CreateEntityByName("env_fog_controller");
			DispatchSpawn(g_iFog);
		}
		
		ExecFog();
		if(gc_bFogRandom.IntValue != 1)
		{
			AcceptEntityInput(g_iFog, "TurnOn");
		}
		else
		{
			int rand = GetRandomInt(0, 1);	
			if(rand == 1)
				AcceptEntityInput(g_iFog, "TurnOn");
			else
				AcceptEntityInput(g_iFog, "TurnOff");
		}
	}
}

public Action HowlTimer(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++) EmitSoundToAll("npc/witch/voice/die/female_death_1.wav");
	
	return Plugin_Continue;
}

public void ExecFog()
{
	if(g_iFog != -1)
	{
		DispatchKeyValue(g_iFog, "fogblend", "0");
		DispatchKeyValue(g_iFog, "fogcolor", "255 255 255");
		DispatchKeyValue(g_iFog, "fogcolor2", "255 255 255");
		DispatchKeyValueFloat(g_iFog, "fogstart", 250.0);
		DispatchKeyValueFloat(g_iFog, "fogend", 350.0);
		DispatchKeyValueFloat(g_iFog, "fogmaxdensity", gc_iFogDensity.FloatValue);
	}
}

bool MapAllowed()
{
	char map[50];
	GetCurrentMap(map, sizeof(map));
	if (StrEqual(map, "c1m3_mall", false)
	|| StrEqual(map, "c1m4_atrium", false) 
	|| StrEqual(map, "c2m1_highway", false) 
	|| StrEqual(map, "c3m1_plankcountry", false) 
	|| StrEqual(map, "c3m2_swamp", false) 
	|| StrEqual(map, "c3m3_shantytown", false) 
	|| StrEqual(map, "c3m4_plantation", false) 
	|| StrEqual(map, "c4m3_sugarmill_b", false) 
	|| StrEqual(map, "c4m4_milltown_b", false) 
	|| StrEqual(map, "c4m5_milltown_escape", false) 
	|| StrEqual(map, "c5m1_waterfront", false) 
	|| StrEqual(map, "c5m5_bridge", false) 
	|| StrEqual(map, "c6m1_riverbank", false) 
	|| StrEqual(map, "c6m2_bedlam", false) 
	|| StrEqual(map, "c7m1_docks", false) 
	|| StrEqual(map, "c7m2_barge", false) 
	|| StrEqual(map, "c8m3_sewers", false) 
	|| StrEqual(map, "c10m5_houseboat", false) 
	|| StrEqual(map, "c13m1_alpinecreek", false) 
	|| StrEqual(map, "c13m2_southpinestream", false) 
	|| StrEqual(map, "c13m3_memorialbridge", false) 
	|| StrEqual(map, "c13m4_cutthroatcreek", false))
	{
		return false;
	}
	return true;
}