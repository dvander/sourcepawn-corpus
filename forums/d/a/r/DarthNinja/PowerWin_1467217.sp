#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.4"

new Handle:v_Enable = INVALID_HANDLE;
new Handle:v_PowerUpTime = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "[TF2] PowerWin",
    author = "DarthNinja",
    description = "Gives the winning team PowerPlay",
    version = PLUGIN_VERSION,
    url = "DarthNinja.com"
};

 
public OnPluginStart()
{
	v_Enable = CreateConVar("sm_powerwin_enable", "1", "<1/0> Enable/Disable PowerPlay for the winning team", 0, true, 0.0, true, 1.0);
	v_PowerUpTime = CreateConVar("sm_powerwin_time", "5", "Powerplay time in seconds");
	CreateConVar("sm_powerwin_version", PLUGIN_VERSION, "PowerWin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("teamplay_round_win", RoundWin);
}


public Action:Timer_PowerDown(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client !=0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		TF2_SetPlayerPowerPlay(client, false)
	}
	return Plugin_Stop;
}


public Action:Timer_PowerUp(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client !=0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		TF2_SetPlayerPowerPlay(client, true);
		new Float:Time = GetConVarFloat(v_PowerUpTime);
		CreateTimer(Time, Timer_PowerDown, userid);
	}
	return Plugin_Continue;
}


public RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(v_Enable))
	{
		new WinningTeam = GetEventInt(event, "team");
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i) && WinningTeam == GetClientTeam(i))
			{
				new userid = GetClientUserId(i);
				CreateTimer(1.0, Timer_PowerUp, userid);
			}
		}
		return;
	}
}