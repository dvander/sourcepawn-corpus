#include <sourcemod>
#include <sdktools>
 
public Plugin:myinfo =
{
	name = "Left 4 Dead Teamkill disable",
	author = "Joshua Coffey",
	description = "Kills TKers",
	version = "2.0.0.0",
	url = "http://www.sourcemod.net/"
};

new Handle:g_hEnabled = INVALID_HANDLE;

public OnPluginStart()
{
g_hEnabled = CreateConVar("sm_mirror_enabled", "1", "Sets whether the Teamkill Punisher plugin is turned on.", FCVAR_NOTIFY|FCVAR_PLUGIN)
   HookEvent("player_hurt", Event_PlayerHurt)
}
 
public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
   new victim_id = GetEventInt(event, "userid")
   new attacker_id = GetEventInt(event, "attacker")
   new victim = GetClientOfUserId(victim_id)
   new attacker = GetClientOfUserId(attacker_id)
   new dmgminus = GetClientHealth(attacker)
   new dmg = GetEventInt(event, "dmg_health");
   new dmgdeal = dmgminus - dmg
   new bool:bEnabled = GetConVarInt(g_hEnabled);
if (bEnabled == 1){
if (GetClientTeam(victim) == GetClientTeam(attacker)){
   if (dmgminus >= 3){
   if (dmgdeal  >= 1 && dmgdeal <=100){
	SetEntityHealth(attacker, dmgdeal);

}}}

}