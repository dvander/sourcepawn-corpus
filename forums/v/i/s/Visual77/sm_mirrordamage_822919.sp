#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.0"

new Handle:cvarAnnounce = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "L4D Mirror Damage",
	author = "Joshua Coffey (edited by Visual77)",
	description = "Disables Friendly Fire. Attacker takes damage if he tries to TK",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
HookEvent("player_hurt", Event_player_hurt, EventHookMode_Pre)
cvarAnnounce = CreateConVar("sm_ffmirror_announce","1");
AutoExecConfig(true, "sm_mirror_damage");
}

	public Action:Event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	
{
	new victimId = GetEventInt(event, "userid")
	new attackerId = GetEventInt(event, "attacker")
	if ((victimId != 0) && (attackerId != 0))
    {
	new victim = GetClientOfUserId(victimId)
	new attacker = GetClientOfUserId(attackerId)
        new dmgminus = GetClientHealth(attacker)
        new dmg = GetEventInt(event, "dmg_health");
        new dmgdeal = dmgminus - dmg 
        if (GetClientTeam(victim) == GetClientTeam(attacker))
        if (dmgdeal  >= 2 && dmgdeal <=100)
	     SetEntityHealth(attacker, dmgdeal); 
	if (IsClientInGame(victim)){
	if (IsClientInGame(attacker)){
	if (GetClientTeam(victim) == GetClientTeam(attacker))
	{
	SetEntityHealth(victim,(GetEventInt(event,"dmg_health")+ GetEventInt(event,"health")))
	}
	}
        } 
     }
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
		PrintToChat(client, "\x04[SM]\x03 Friendly Fire is mirrored on this server. Be careful");
	}
}