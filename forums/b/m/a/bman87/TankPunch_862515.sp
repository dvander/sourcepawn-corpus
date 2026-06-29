#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

new Handle:g_hIncapHealth  = INVALID_HANDLE;
new Handle:cvarSurvHealth = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Tank Punch Incap",
	author = "DrThunder & Thraka & Bman",
	description = "Players who are incapacitated by a tank punch fly across the map, like a normal punch, instead of just instantly falling to the ground.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=96075"
}

public OnPluginStart()
{
	CreateConVar("tankpunch_ver", PLUGIN_VERSION, "Version of the tank punch plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvarSurvHealth = CreateConVar("tankpunch_incap_health", "-1", "Survivor incap health", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	HookEvent("player_incapacitated", PlayerIncap);
	g_hIncapHealth = FindConVar("survivor_incap_health");
	
	
}
	
IncapTimer(client)
{	
	CreateTimer(0.4, IncapTimer_Function, client, TIMER_REPEAT);
}

public Action:IncapTimer_Function(Handle:timer, any:client)
{
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
	if(GetConVarInt(cvarSurvHealth) == -1)
	{
		SetEntityHealth(client, GetConVarInt(g_hIncapHealth));
		return Plugin_Stop;	
	}
	else
	{
		SetEntityHealth(client, GetConVarInt(cvarSurvHealth));
		return Plugin_Stop;	
	}
}

public Action:PlayerIncap(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new PlayerID = GetClientOfUserId(GetEventInt(event, "userid"));	
	new String:Weapon[256];	 
	GetEventString(event, "weapon", Weapon, 256);
	if (StrEqual(Weapon, "tank_claw"))
	{
		SetEntProp(PlayerID, Prop_Send, "m_isIncapacitated", 0);
		SetEntityHealth(PlayerID, 1);
		IncapTimer(PlayerID);
	}

}
