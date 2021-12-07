#include <sourcemod>
#include <sdkhooks>
#define PLUGIN_VERSION "1.0"

new Handle:hDmg = INVALID_HANDLE;
new Handle:hEnable = INVALID_HANDLE;
new Handle:hSpeed = INVALID_HANDLE;
new Handle:hTime = INVALID_HANDLE;
new Float:forwardtime[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[L4D/2] Crawl Balancer",
	author = "McFlurry",
	description = "Increases damage while crawling",
	version = PLUGIN_VERSION,
	url = "http://mcflurrysource.tk" //probably still not done or started
}

public OnPluginStart()
{
	new String:game_name[128];
	GetGameFolderName(game_name, sizeof(game_name));
	if(!StrEqual(game_name, "left4dead2", false) && !StrEqual(game_name, "left4dead", false))
	{
		SetFailState("This plugin only supports Left 4 Dead series");
	}
	CreateConVar("l4d2_crawlbalancer_version", PLUGIN_VERSION, "Version of crawlbalancer on this server", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED);
	hEnable = CreateConVar("l4d2_crawlbalancer_enable", "1", "Enable Crawlbalancer on this server", FCVAR_NOTIFY|FCVAR_PLUGIN);
	hDmg = CreateConVar("l4d2_crawlbalancer_damage", "1.3", "Multiplier for damage taken by crawling", FCVAR_NOTIFY|FCVAR_PLUGIN);
	HookConVarChange(hEnable, OnEnabled);
	hSpeed = CreateConVar("l4d2_crawlbalancer_speed", "15", "Speed of crawling for survivors", FCVAR_NOTIFY|FCVAR_PLUGIN);
	HookConVarChange(hSpeed, OnSpeedChanged);
	hTime = CreateConVar("l4d2_crawlbalancer_time", "1.0", "After how much crawling time will the bonus damage be added", FCVAR_NOTIFY|FCVAR_PLUGIN);
	HookEvent("revive_success", Event_Revive);
	AutoExecConfig(true, "l4d2_crawlbalancer");
}

public OnMapStart()
{
	for(new i=1;i<=MaxClients;i++)
	{
		forwardtime[i] = 0.0;
	}	
}

public OnConfigsExecuted()
{
	if(GetConVarBool(hEnable))
	{
		SetConVarInt(FindConVar("survivor_allow_crawling"), 1);
	}
}	

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(GetConVarBool(hEnable) && buttons & IN_FORWARD && IsPlayerAlive(client) && GetClientTeam(client) == 2 && GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
	{
		forwardtime[client] += 0.0333333333; //this is a tick in l4d and l4d2.
	}
}	

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	forwardtime[client] = 0.0
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(GetConVarBool(hEnable) && IsClientInGame(victim) && IsPlayerAlive(victim) && GetEntProp(victim, Prop_Send, "m_isIncapacitated") && damagetype & DMG_POISON && forwardtime[victim] >= GetConVarInt(hTime))
	{
		forwardtime[victim] -= GetConVarInt(hTime);
		damage *= GetConVarFloat(hDmg);
		damage = float(RoundToCeil(damage));
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!StringToInt(newValue))  SetConVarInt(FindConVar("survivor_allow_crawling"), 0);
	else SetConVarInt(FindConVar("survivor_allow_crawling"), 1);
}

public OnSpeedChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarInt(FindConVar("survivor_crawl_speed"), StringToInt(newValue));
}	

public Action:Event_Revive(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	forwardtime[client] = 0.0;
}	