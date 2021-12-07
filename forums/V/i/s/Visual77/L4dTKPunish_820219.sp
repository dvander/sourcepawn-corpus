#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.0"

new Handle:cvarAnnounce = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "L4D Mirror Friendly Fire",
	author = "Joshua Coffey",
	description = "Kills Tkers",
	version = "1.0.0",
	url = "http://www.sourcemod.net/"
};


public OnPluginStart()
{
HookEvent("player_hurt", Event_PlayerHurt)
cvarAnnounce = CreateConVar("sm_ffmirror_announce","1");
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
   if (GetClientTeam(victim) == GetClientTeam(attacker))
   if (dmgminus >= 3){
   if (dmgdeal  >= 1 && dmgdeal <=100)
	SetEntityHealth(attacker, dmgdeal); 
    }
}


public OnClientPutInServer(client)
{
	if (client)
	{
		if (GetConVarBool(cvarAnnounce))
			CreateTimer(45.0, TimerAnnounce, client);
	}
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
       
	if (IsClientInGame(client))
	{
		PrintToChat(client, "\x04[SM]\x03 This server mirrors the Friendly Fire damage you do to others. Be careful");
	}
}