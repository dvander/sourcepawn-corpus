#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#tryinclude <lasermines>
#tryinclude <zr_lasermines>
#tryinclude <zriot_lasermines>

#define PLUGIN_VERSION	"1.1"

new Handle:h_timer[MAXPLAYERS+1][2049],
	Handle:h_delay;

public Plugin:myinfo =
{
	name = "Lasermines Battery",
	author = "FrozDark",
	description = "Adds battery charge to the lasermines",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru/"
};
public OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_death", OnPlayerDeath);
	h_delay = CreateConVar("lasermine_battery_charge", "60", "The lasermines' battery charge in seconds", 0, true, 0.0);
}

public OnMapEnd()
{
	for (new i = 0; i <= MaxClients; i++)
	{
		ResetTimers(i);
	}
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ResetTimers(client);
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 0; i <= MaxClients; i++)
	{
		ResetTimers(i);
	}
}

ResetTimers(client)
{
	for (new i = 0; i < sizeof(h_timer[]); i++)
	{
		if (h_timer[client][i] != INVALID_HANDLE)
		{
			KillTimer(h_timer[client][i]);
			h_timer[client][i] = INVALID_HANDLE;
		}
	}
}

public OnLaserminePlanted(client, lasermine, Float:act_delay, exp_damage, exp_radius, health, color[3])
{
	CreateBattery(client, GetBeamByLasermine(lasermine), act_delay);
}

public ZR_OnLaserminePlanted(client, lasermine, Float:act_delay, exp_damage, exp_radius, health, color[3])
{
	CreateBattery(client, ZR_GetBeamByLasermine(lasermine), act_delay);
}

public ZRiot_OnLaserminePlanted(client, lasermine, Float:act_delay, exp_damage, exp_radius, health, color[3])
{
	CreateBattery(client, ZRiot_GetBeamByLasermine(lasermine), act_delay);
}

public Action:OnPreHitByLasermine(victim, &attacker, &beam, &lasermine, &damage)
{
	return OnPreHit(attacker, beam);
}

public Action:ZR_OnPreHitByLasermine(victim, &attacker, &beam, &lasermine, &damage)
{
	return OnPreHit(attacker, beam);
}

public Action:ZRiot_OnPreHitByLasermine(victim, &attacker, &beam, &lasermine, &damage)
{
	return OnPreHit(attacker, beam);
}

Action:OnPreHit(owner, beam)
{
	if (h_timer[owner][beam] == INVALID_HANDLE)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

CreateBattery(client, beam, Float:act_delay)
{
	if (beam == -1)
		return;
	
	new Handle:dp;
	h_timer[client][beam] = CreateDataTimer(GetConVarFloat(h_delay) + act_delay, TurnOffLasermine, dp, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(dp, client);
	WritePackCell(dp, beam);
}

public Action:TurnOffLasermine(Handle:timer, any:dp)
{
	ResetPack(dp);
	new client = ReadPackCell(dp);
	new beam = ReadPackCell(dp);
	
	h_timer[client][beam] = INVALID_HANDLE;
	AcceptEntityInput(beam, "TurnOff");
	SetEntityRenderColor(beam, 0, 0, 0, 0);
}