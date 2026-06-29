/*
* [TF2] Custom Uber Time
* 
* Author: Ugleh
* Date: April 24, 2011
* 
*/
#define PLUGIN_VERSION 			"0.1.2"

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include tf2
#include tf2_stocks

new Handle:c_Enabled = INVALID_HANDLE;
new Handle:c_Seconds = INVALID_HANDLE;
new Handle: TimeStorage[MAXPLAYERS+1];
new Handle:g_Timerhandle[MAXPLAYERS+1] = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Custom Uber Time",
	author = "Ugleh",
	description = "Use a cvar to create a Custom Uber Time",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	CreateConVar("sm_cut_version", PLUGIN_VERSION , "Current CUT Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	c_Enabled   = CreateConVar("sm_cut_enable",    	"1",        "<0/1> Enable CUT.");
	c_Seconds    = CreateConVar("sm_cut_seconds",    	"120",    	"<60/120/180/etc> Amount of Seconds for Deployed Ubers to last");
	HookEvent("player_chargedeployed", PlantedUber);	
}


public Action:PlantedUber(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(c_Enabled) == 1){
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		TimeStorage[client] = GetTime() + GetConVarInt(c_Seconds);
		g_Timerhandle[client] = CreateTimer(0.1, Timer_Uber, client, TIMER_REPEAT);
	}
	}

public Action:Timer_Uber(Handle:timer, any:client)
{
	if(!IsClientInGame(client)){
		g_Timerhandle[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if (TF2_GetPlayerClass(client) != TF2_GetClass("medic")){
		g_Timerhandle[client] = INVALID_HANDLE;
		return Plugin_Stop;	
	}	
	new CurrentTime = GetTime();
	if(CurrentTime > TimeStorage[client]){
	
		g_Timerhandle[client] = INVALID_HANDLE;
		PrintCenterText(client, "Ubercharge 0 Seconds");
		TF_SetUberLevel(client, 0.0);
		return Plugin_Stop;
	}else{
		PrintCenterText(client, "Ubercharge: %i Seconds",TimeStorage[client] - CurrentTime);
		TF_SetUberLevel(client, 100.0);
		return Plugin_Continue;
	}
}


stock TF_SetUberLevel(client, Float:uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
	SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
}