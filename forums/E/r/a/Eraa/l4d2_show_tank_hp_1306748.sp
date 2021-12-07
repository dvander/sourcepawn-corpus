#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

new Float:MaxHealth[MAXPLAYERS+1];

new Handle:TankAnnounce = INVALID_HANDLE;
new Handle:TankGauge	= INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[L4D2] Show Tank HP",
	author = "ztar",
	description = "Show Tank's health bar. Multitank is also supported.",
	version = PLUGIN_VERSION,
	url = "http://ztar.blog7.fc2.com/"
}

public OnPluginStart()
{
	TankAnnounce = CreateConVar("sm_tankhp_announce","1", "Notify tank health(0:OFF 1:ON)", CVAR_FLAGS);
	TankGauge	 = CreateConVar("sm_tankhp_gaugetype","0", "Tank gauge type(0:Center text 1:Hint text)", CVAR_FLAGS);
	
	HookEvent("tank_spawn", Event_Tank_Spawn);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client <= 0 || client > GetMaxClients())
		return Plugin_Continue;
	if(target <= 0 || target > GetMaxClients())
		return Plugin_Continue; 
	
	/* Notify Tank health */
	if(GetEntProp(target, Prop_Send, "m_zombieClass") == 8 && GetConVarInt(TankAnnounce))
	{
		new i, j;
		new dtype = GetEventInt(event, "type");
		new Float:Health = float(GetEventInt(event,"health"));
		decl String:HealthBar[80+1];
		new Float:GaugeNum = ((Health / MaxHealth[target]) * 100.0)*0.8;
		
		for(i=0; i<80; i++)
			HealthBar[i] = '|';
		for(j=RoundToCeil(GaugeNum); j<80; j++)
			HealthBar[j] = ' ';
		HealthBar[80] = '\0';
		if(dtype != 64 && dtype != 128 && dtype != 268435464)
		{
			/* Gauge type(0:Center 1:Hint) */
			if(GetConVarInt(TankGauge) == 0)
				PrintCenterText(client, "TANK %4.0f/%4.0f  %s", Health, MaxHealth[target], HealthBar);
			else
				PrintHintText(client, "TANK %4.0f/%4.0f  %s", Health, MaxHealth[target], HealthBar);
		}
	}
	return Plugin_Continue;
}

public Action:Event_Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsClientInGame(client) || !IsValidEntity(client))
		return Plugin_Continue;
	
	/* Get MAX health of Tank */
	if(GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
	{
		CreateTimer(1.0, GetTankHealth, client);
	}
	return Plugin_Continue;
}

public Action:GetTankHealth(Handle:timer, any:client)
{
	if(IsValidEntity(client) && IsClientInGame(client))
		MaxHealth[client] = float(GetClientHealth(client));
}
