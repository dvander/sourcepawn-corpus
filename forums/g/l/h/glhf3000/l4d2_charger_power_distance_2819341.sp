#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define VERSION "1.0"

public Plugin myinfo =
{
	name = "[L4D2] Charger power: run distance affects push power",
	author = "glhf3000",
	description = "",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=126831&page=9"
};

ConVar	cvPower, 
		cvChargeWarmup, cvChargeDuration, cvMinSpeed, cvMaxSpeed;

float	fPowerDefault,
		fChargeWarmup, fChargeDuration, fMinSpeed, fMaxSpeed;

float	fChargeStartTime[MAXPLAYERS+1];

public void OnPluginStart()
{
	////////////
	cvPower = 			FindConVar("l4d2_charger_power");

	if(cvPower == null)	SetFailState("ConVar l4d2_charger_power not found");
	
	cvChargeWarmup = 	FindConVar("z_charge_warmup");
	cvChargeDuration = 	FindConVar("z_charge_duration");
	
	cvMinSpeed = 		FindConVar("z_charge_start_speed");
	cvMaxSpeed = 		FindConVar("z_charge_max_speed");
	
	////////////
	cvPower.AddChangeHook(ConVarChanged);
	
	cvChargeWarmup.AddChangeHook(ConVarChanged);
	cvChargeDuration.AddChangeHook(ConVarChanged);
	
	cvMinSpeed.AddChangeHook(ConVarChanged);
	cvMaxSpeed.AddChangeHook(ConVarChanged);
	
	setVars(true);
	
	////////////
	HookEvent("ability_use", EventChargeStart);
	HookEvent("charger_charge_end", EventChargeEndPre, EventHookMode_Pre);
}

void ConVarChanged(ConVar cv, const char[] oldValue, const char[] newValue)
{
	// char name[32];
	// cv.GetName(name, 32);
	
	// PrintToChatAll("%s   %s -> %s", name, oldValue, newValue);
	setVars();
}

void setVars(bool init = false)
{
	if(init) 
		fPowerDefault	= cvPower.FloatValue;
	
	fChargeWarmup		= cvChargeWarmup.FloatValue;
	fChargeDuration		= cvChargeDuration.FloatValue;
	
	fMinSpeed 			= cvMinSpeed.FloatValue;
	fMaxSpeed 			= cvMaxSpeed.FloatValue;
}

//////////////////////////////
//////////////////////////////
//////////////////////////////

public Action EventChargeStart(Event event, const char[] name, bool dontBroadcast)
{
	char ability[16];
	event.GetString("ability", ability, sizeof(ability), "wut?");

	if(!StrEqual(ability, "ability_charge")) 
		return Plugin_Continue;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	fChargeStartTime[client] = GetEngineTime();

	return Plugin_Continue;
}

public Action EventChargeEndPre(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(fChargeStartTime[client] == 0) return Plugin_Continue;

	float runtime = GetEngineTime() - fChargeStartTime[client];
	float slowdownThresold = fChargeDuration - fChargeWarmup;
	
	float multiplier;
	float minPower = fMinSpeed / fMaxSpeed * fPowerDefault;
	float diffToMaxPower = fPowerDefault - minPower;

	if(runtime < cvChargeWarmup.FloatValue)
	{
		// 250 -> 500
		multiplier = runtime / fChargeWarmup;

		setPower( minPower + (diffToMaxPower * multiplier) );
	}
	else if(runtime > slowdownThresold)
	{
		// 500 -> 0
		multiplier = (fChargeDuration - runtime) / fChargeWarmup;
		
		setPower( cvPower.FloatValue * multiplier );
	} 
	else 
	{
		// PrintToChatAll("runtime: %02f", runtime);
		// PrintToChatAll("power: %02f", cvPower.FloatValue);
		return Plugin_Continue;
	}

	// PrintToChatAll("runtime: %02f", runtime);
	// PrintToChatAll("power min/max: %02f/%02f", minPower, fPowerDefault);
	// PrintToChatAll("power: %02f", cvPower.FloatValue);
	
	RequestFrame(resetValue);

	fChargeStartTime[client] = 0.0;

	return Plugin_Continue;
}

void resetValue()
{
	setPower(fPowerDefault);
}

void setPower(float value)
{
	if(cvPower.Flags & FCVAR_NOTIFY)
	{	
		cvPower.Flags &= ~FCVAR_NOTIFY;
		RequestFrame(resetFlags);
	}
	
	cvPower.FloatValue = value;
}

void resetFlags()
{
	cvPower.Flags |= FCVAR_NOTIFY;
}

