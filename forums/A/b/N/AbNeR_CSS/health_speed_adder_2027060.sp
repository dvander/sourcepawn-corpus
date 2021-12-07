#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "3.1"

new Handle:g_FFA;
new Handle:g_HealthAdd;
new Handle:g_HealthLimit;
new Handle:g_HealthAddEnable;
new Handle:g_SpeedDefault;
new Handle:g_SpeedEnable;
new Handle:g_SpeedMulti;
new Handle:g_MSG;
new Handle:g_HeadShotAdd;
new Handle:g_KnifeAdd;
new Handle:g_SpeedHeadshot;
new Handle:g_SpeedKnife;


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
	AutoExecConfig(true, "health_speed_adder");
	CreateConVar("health_speed_adder_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	g_FFA = CreateConVar("health_speed_adder_ffa", "0", "When enable the plugin works with ffa mode", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_HealthAddEnable = CreateConVar("health_add_enable", "1", "Active the health bonus when kill", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_HealthAdd = CreateConVar("health_add", "10", "Amount of life added by kill", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_HealthLimit = CreateConVar("health_limit", "0", "Max health added by kill, 0 to disable", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_SpeedEnable = CreateConVar("speed_add_enable", "1", "Active speed bonus when kill", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_SpeedMulti = CreateConVar("speed_add", "100", "Amount of speed added by kill", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_SpeedDefault = CreateConVar("speed_default", "260", "Default speed of a player default value is 260", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_SpeedHeadshot = CreateConVar("speed_headshot_add", "50", "Default speed of a player default value is 260", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_SpeedKnife = CreateConVar("speed_knife_add", "100", "Default speed of a player default value is 260", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_MSG = CreateConVar("health_speed_msg", "1", "Enable the menssages when kill a player", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_HeadShotAdd = CreateConVar("health_headshot_add", "20", "Extra health by headshot", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_KnifeAdd = CreateConVar("health_knife_add", "50", "Extra health by knifekill", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	
	HookEvent("player_death", PlayerDeath); 
	HookEvent("player_spawn", PlayerSpawn); 
	
	LoadTranslations("common.phrases");
	LoadTranslations("health_speed_adder.phrases");
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	SetEntPropFloat(userid, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(g_SpeedDefault)/260); 
	//PrintToChatAll("%f", GetConVarFloat(g_SpeedDefault)/260);
}


public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	new killer = GetClientOfUserId(GetEventInt(event, "attacker")); 
	new victim = GetClientOfUserId(GetEventInt(event, "userid")); 
	decl String:sWeapon[32];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
	
	//The default speed is 260 so to get the speed vector like 2.0 or 3.0  you need to divide the speed by 260 
	
	if(!IsValidClient(killer))
	{
		return Plugin_Continue;
	}
	
	if((killer == 0) || !IsPlayerAlive(killer))
	{
		return Plugin_Handled;
	}
	
	if(GetClientTeam(killer) == GetClientTeam(victim) && GetConVarInt(g_FFA) == 0)
	{
		return Plugin_Handled;
	}
	
	if(GetConVarInt(g_HealthAddEnable) != 0)
	{
		new vida = GetClientHealth(killer);
		new nvida = vida + GetConVarInt(g_HealthAdd);	
		if (GetEventBool(event, "headshot"))
		{
			nvida = nvida + GetConVarInt(g_HeadShotAdd);
			if(GetConVarInt(g_MSG) != 0 && GetConVarInt(g_HeadShotAdd) != 0)
			{
				//PrintToChat(killer, "+%dHP by HeadShot Kill", nvida - vida);
				PrintToChat(killer, "\x01%t", "HeadShotHealth", nvida - vida);
			}
		}
		
		if (!GetEventBool(event, "headshot") && !StrEqual(sWeapon, "knife"))
		{
			//PrintToChat(killer, "+%dHP by Kill Enemy", nvida - vida);
			PrintToChat(killer, "\x01%t", "KillHealth", nvida - vida);
		}
		
		if(StrEqual(sWeapon, "knife") && GetConVarInt(g_KnifeAdd) != 0)
		{
			nvida = nvida + GetConVarInt(g_KnifeAdd);
			if(GetConVarInt(g_MSG) != 0 && GetConVarInt(g_KnifeAdd) != 0)
			{
				//PrintToChat(killer, "+%dHP by Knife Kill", nvida - vida);
				PrintToChat(killer, "\x01%t", "KnifeHealth", nvida - vida);
			}
		}
		
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
		new Float:speed = GetEntPropFloat(killer, Prop_Send, "m_flMaxspeed")+GetConVarInt(g_SpeedMulti);
		if (GetEventBool(event, "headshot"))
		{
			speed = speed + GetConVarInt(g_SpeedHeadshot);
			if(GetConVarInt(g_MSG) != 0 && GetConVarInt(g_SpeedHeadshot) != 0)
			{
				//PrintToChat(killer, "+%0.2f speed by HeadShot Kill", (speed - GetConVarInt(g_SpeedDefault))/260);
				PrintToChat(killer, "\x01%t", "HeadShotSpeed", (speed - GetConVarInt(g_SpeedDefault))/260);
			}
		}
		if (!GetEventBool(event, "headshot") && !StrEqual(sWeapon, "knife"))
		{
			PrintToChat(killer, "\x01%t", "KillSpeed", (speed - GetConVarInt(g_SpeedDefault))/260);
		}
		
		if(StrEqual(sWeapon, "knife") && GetConVarInt(g_SpeedKnife) != 0)
		{
			speed = speed + GetConVarInt(g_SpeedKnife);
			if(GetConVarInt(g_MSG) != 0 && GetConVarInt(g_SpeedKnife) != 0)
			{
				PrintToChat(killer, "\x01%t", "KnifeSpeed", (speed - GetConVarInt(g_SpeedDefault))/260);
			}
		}
		SetEntPropFloat(killer, Prop_Send, "m_flMaxspeed", speed);
		SetEntPropFloat(killer, Prop_Data, "m_flLaggedMovementValue", speed/260); 
	}
	

	return Plugin_Handled;
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
