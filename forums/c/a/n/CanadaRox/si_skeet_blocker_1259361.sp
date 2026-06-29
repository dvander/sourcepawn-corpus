#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION	"1.1"

#define TEAM_SPECTATOR	1
#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3

new bool:bInJockeyRide[MAXPLAYERS + 1];

new Handle:hEnabled;
new bEnabled;

public Plugin:myinfo = 
{
	name = "SI Skeet Blocker",
	author = "CanadaRox",
	description = "Prevents special infected from killing eachother in the air, and prevents jockey's from being scratched off while riding a survivor.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1259361"
}

public OnPluginStart()
{
	HookEvent("jockey_ride", JockeyRide_Event);
	HookEvent("jockey_ride_end", JockeyRideEnd_Event);
	HookEvent("player_disconnect", ArrayReset_Event);
	HookEvent("player_death", ArrayReset_Event);
	
	hEnabled = CreateConVar("l4d2_skeetblocker_enable", "1", "Enabled the SI Skeet Blocker");
	HookConVarChange(hEnabled, Enabled_ConVarChanged);
	bEnabled = GetConVarBool(hEnabled);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Enabled_ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	bEnabled = GetConVarBool(hEnabled);
}

public ArrayReset_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public JockeyRide_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	bInJockeyRide[client] = true;
}

public JockeyRideEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	bInJockeyRide[client] = false;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{	
	if (isGrounded(victim) || GetClientTeam(attacker) != TEAM_INFECTED || !(bEnabled && bInJockeyRide[victim])) return Plugin_Continue;
	
	return Plugin_Handled;
}

stock bool:isGrounded(client) return (GetEntProp(client,Prop_Data,"m_fFlags") & FL_ONGROUND) > 0;
stock bool:isClient(client) return IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client);