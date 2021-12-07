#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "2.2"
new Handle:g_FFA;
new Handle:g_HealthAdd;
new Handle:g_HealthLimit;
new Handle:g_HealthAddEnable;
new Handle:g_SpeedDefault;
new Handle:g_SpeedEnable;
new Handle:g_SpeedMulti;
new Handle:g_MSG;


public Plugin:myinfo =
{
        name = "Health and Speed Adder",
        author = "AbNeR_CSS and Arkarr",
        description = "Health and Speed Bonus by kill a enemy",
        version = PLUGIN_VERSION,
        url = "www.tecnohardclan.com"
};

public OnPluginStart()
{  
	//Cvars
	AutoExecConfig();
	CreateConVar("health_speed_adder_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	g_FFA = CreateConVar("health_speed_adder_ffa", "0", "When enable the plugin works with ffa mode", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_HealthAddEnable = CreateConVar("health_add_enable", "1", "Active the health bonus when kill", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_HealthAdd = CreateConVar("health_add", "10", "Amount of life added by kill", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_HealthLimit = CreateConVar("health_limit", "0", "Max health added by kill, 0 to disable", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_SpeedEnable = CreateConVar("speed_add_enable", "1", "Active speed bonus when kill", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_SpeedMulti = CreateConVar("speed_add", "100", "Amount of speed added by kill", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_SpeedDefault = CreateConVar("speed_default", "260", "Default speed of a player default value is 260", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_MSG = CreateConVar("health_speed_msg", "1", "Enable the menssages when kill a player", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	HookEvent("player_death", PlayerDeath); 
	HookEvent("player_spawn", PlayerSpawn); 
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	SetEntPropFloat(userid, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(g_SpeedDefault)/260); 
	PrintToChatAll("%f", GetConVarFloat(g_SpeedDefault)/260);
}


public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	new killer = GetClientOfUserId(GetEventInt(event, "attacker")); 
	new victim = GetClientOfUserId(GetEventInt(event, "userid")); 
	
	new vida = GetClientHealth(killer);
	new nvida = vida + GetConVarInt(g_HealthAdd);
	
	//The default speed is 260 so to get the speed vector like 2.0 or 3.0  you need to divide the speed by 260 
	new Float:speed = GetEntPropFloat(killer, Prop_Send, "m_flMaxspeed")+GetConVarFloat(g_SpeedMulti);
	new Float:speed_vec = speed/260;
	
	if((killer == 0) || (!IsPlayerAlive(killer)))
	{
		return Plugin_Handled;
	}
	
	if(GetClientTeam(killer) == GetClientTeam(victim) && GetConVarInt(g_FFA) == 0)
	{
		return Plugin_Handled;
	}
	
	if(GetConVarInt(g_HealthAddEnable) != 0 && GetUserFlagBits(killer) & ADMFLAG_RESERVATION)
	{
		if(GetConVarInt(g_HealthLimit) != 0)
		{
			if(nvida <= GetConVarInt(g_HealthLimit))
			{
				SetEntityHealth(killer, nvida);
			}
			if(nvida > GetConVarInt(g_HealthLimit) && vida < GetConVarInt(g_HealthLimit))
			{
				SetEntityHealth(killer, GetConVarInt(g_HealthLimit));
			}
		}
		else
		{
			SetEntityHealth(killer, nvida);
		}
	}
	
	if(GetConVarInt(g_SpeedEnable) != 0)
	{
		SetEntPropFloat(killer, Prop_Send, "m_flMaxspeed", speed);
		SetEntPropFloat(killer, Prop_Data, "m_flLaggedMovementValue", speed_vec); 
	}
	
	if(GetConVarInt(g_MSG) != 0)
	{
		if(GetConVarInt(g_HealthAddEnable) != 0 && GetConVarInt(g_SpeedEnable) != 0)
		{
			PrintToChat(killer, "\x01\x0B\x04[Health and Speed Adder] \x01 You have now \x03%0.2f \x01of speed and \x03%d \x01of life.", speed_vec, GetClientHealth(killer));
			return Plugin_Handled;
		}
		
		if(GetConVarInt(g_HealthAddEnable) != 0 && GetConVarInt(g_SpeedEnable) == 0)
		{
			PrintToChat(killer, "\x01\x0B\x04[Health Adder] \x01 You have now \x03%d \x01of life.", GetClientHealth(killer));
			return Plugin_Handled;
		}
		
		if(GetConVarInt(g_HealthAddEnable) == 0 && GetConVarInt(g_SpeedEnable) != 0)
		{
			PrintToChat(killer, "\x01\x0B\x04[Speed Adder] \x01 You have now \x03%0.2f \x01of speed.", speed_vec);
			return Plugin_Handled;
		}
		
	}
	return Plugin_Handled;
}

