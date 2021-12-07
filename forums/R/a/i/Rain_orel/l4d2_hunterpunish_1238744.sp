#include <sourcemod>
#include <sdktools>
 
public Plugin:myinfo =
{
	name = "Hunter Punch Punish",
	author = "Rain_orel",
	description = "Punishes n00b hunters",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

new Handle:hKillHunterEnabled
new Handle:hHealth
new Handle:hIgniteTime
 
public OnPluginStart()
{
	hKillHunterEnabled = CreateConVar("hpp_hunterpunish", "1", "Hunter punish type: 0 - don't punish, 1- kill, 2 - ignite",FCVAR_NOTIFY)
	hHealth = CreateConVar("hpp_givehealth", "5", "How much health must be given to survivor.",FCVAR_NOTIFY)
	hIgniteTime = CreateConVar("hpp_ignitetime", "30", "Number of seconds to set hunter on fire if fire punish is enabled.",FCVAR_NOTIFY)
	HookEvent("hunter_punched", Event_HunterPunched)
}

public Event_HunterPunched(Handle:event, const String:name[], bool:dontBroadcast)
{
   new survivor_id = GetEventInt(event, "userid")
   new hunter_id = GetEventInt(event, "hunteruserid")
   new bool:lunging = GetEventBool(event, "islunging")
   
   if(lunging == true)
   {
		new givehealth = GetConVarInt(hHealth)
		new hunterkill = GetConVarInt(hKillHunterEnabled)
		new survivor = GetClientOfUserId(survivor_id)
		new hunter = GetClientOfUserId(hunter_id)
		if(hunterkill==1){
		ForcePlayerSuicide(hunter)
		}
		else if(hunterkill==2){
		new Float:time = GetConVarFloat(hIgniteTime)
		IgniteEntity(hunter,time)
		}
		new health = GetClientHealth(survivor)
		SetEntityHealth(survivor, health+givehealth)
	}
}