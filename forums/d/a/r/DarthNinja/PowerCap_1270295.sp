#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.4"

#define FlagPickedUp 1
#define FlagCaptured 2
#define FlagDefended 3
#define FlagDropped  4

new Handle:v_RegenCapper = INVALID_HANDLE;
new Handle:v_PowerUpCapper = INVALID_HANDLE;
new Handle:v_PowerUpTime = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "[TF2] PowerCap: PowerPlay for the flag capper",
    author = "DarthNinja",
    description = "Regenerate's player's health/ammo and gives them powerplay when they cap a flag",
    version = PLUGIN_VERSION,
    url = "DarthNinja.com"
};

 
public OnPluginStart()
{
	v_RegenCapper = CreateConVar("sm_powercap_regen", "1", "<1/0> Regenerate player's health/ammo when they cap", 0, true, 0.0, true, 1.0);
	v_PowerUpCapper = CreateConVar("sm_powercap_powerup", "1", "<1/0> Give player powerplay mode when they capture", 0, true, 0.0, true, 1.0);
	v_PowerUpTime = CreateConVar("sm_powercap_time", "7", "Powerplay time in seconds");
	CreateConVar("sm_powercap_version", PLUGIN_VERSION, "PowerCap version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("teamplay_flag_event", FlagEvent);
	LoadTranslations("common.phrases");
}

public Action:Timer_PowerDown(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsClientConnected(client) && IsPlayerAlive(client) && IsClientInGame(client))
	{
		TF2_SetPlayerPowerPlay(client, false)
	}
	return Plugin_Stop;
}

public Action:Timer_PowerUp(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsClientConnected(client) && IsPlayerAlive(client) && IsClientInGame(client))
	{
		TF2_SetPlayerPowerPlay(client, true)
		//Get time and start timer
		new Float:f_Time = GetConVarFloat(v_PowerUpTime);
		CreateTimer(f_Time, Timer_PowerDown, userid)
	}
	return Plugin_Continue;
}


public FlagEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "eventtype") == FlagCaptured)
	{
		new client = GetEventInt(event, "player");
		new userid = GetClientUserId(client);
		
		if(GetConVarBool(v_RegenCapper))
		{
			TF2_RegeneratePlayer(client);
		}
		
		if (GetConVarBool(v_PowerUpCapper))
		{
			//Powerup graphics fix
			CreateTimer(1.0, Timer_PowerUp, userid);
		}
	}
	return;
}