#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0"

new Handle:iuber_version = INVALID_HANDLE;
new Handle:iuber_uberlevel = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "InstantUber",
	author = "Lord Max & Antithasys",
	description = "InstantUber is a plugin that gives the medic class 100% UberCharge on respawn.",
	version = PLUGIN_VERSION,
	url = "http://www.lordmax.net"
}
public OnPluginStart()
{
	iuber_version = CreateConVar("iuber_version", PLUGIN_VERSION, "Instant Uber", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	iuber_uberlevel = CreateConVar("iuber_uberlevel", "1.0", "Uber level to give medics on spawn", _, true, 0.0, true, 1.0);
	if (!HookEventEx("player_spawn", HookPlayerSpawn, EventHookMode_Post)
		|| !HookEventEx("player_changeclass", HookPlayerClass, EventHookMode_Post))
		SetFailState("Could not hook an event.");
	AutoExecConfig(true, "plugin.instantuber");
}
public Action:HookPlayerClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new any:class = GetEventInt(event, "class");
	if (class != TFClass_Medic)
		return _:Plugin_Continue;
	CreateTimer(0.25, Timer_PlayerUberDelay, client);
	return _:Plugin_Continue;
}
public Action:HookPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (class != TFClass_Medic)
		return _:Plugin_Continue;
	CreateTimer(0.25, Timer_PlayerUberDelay, client);
	return _:Plugin_Continue;
}
public Action:Timer_PlayerUberDelay(Handle:timer, any:client)
{
	if (IsClientInGame(client)) {
		new TFClassType:class = TF2_GetPlayerClass(client);
			if (class == TFClass_Medic) {
				new uberlevel = GetConVarFloat(iuber_uberlevel);
		new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel);
}
}
}