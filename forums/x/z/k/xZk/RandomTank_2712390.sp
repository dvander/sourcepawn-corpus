#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "1.0.1"

#define g_sTankNorm	"models/infected/hulk.mdl"
#define g_sTankSac	"models/infected/hulk_dlc3.mdl"

ConVar g_cvarEnabled;
ConVar g_cvarChance;

public Plugin myinfo = 
{
	name = "RandomTank",
	author = "Ludastar (Armonic)",
	description = "Just Adds the 50% Chance between each tank model",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/ArmonicJourney"
}

public void OnPluginStart()
{	
	g_cvarEnabled = CreateConVar("RandomTank", "1", "Enable / Disable", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarChance = CreateConVar("RandomTank_Chance", "50", "Percent Chance 0/100 %", FCVAR_NONE, true, 0.0,true, 100.0);
	HookEvent("tank_spawn", eTankSpawn);
}

public void OnMapStart()
{
	if(!g_cvarEnabled.BoolValue)
		return;
	
	PrecacheModel(g_sTankNorm, true);
	PrecacheModel(g_sTankSac, true);
}


public void eTankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_cvarEnabled.BoolValue)
		return;
	
	int iTank =  event.GetInt("tankid");
	if(iTank > 0 && iTank <= MaxClients && IsClientInGame(iTank) && GetClientTeam(iTank) == 3 && IsPlayerAlive(iTank))
	{
		if(GetRandomInt(1, 100) <= g_cvarChance.IntValue){
			SetEntityModel(iTank, g_sTankSac);
		}else{
			SetEntityModel(iTank, g_sTankNorm);
		}
	}
}

