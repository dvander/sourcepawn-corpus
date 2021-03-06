/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <events>
#include <clients> 

public Plugin:myinfo = 
{
	name        = "Prevent Sandman from affecting ubers",
	author      = "Fox Mulder",
	description = "Damn you Valve, why must I waste my time writing a plugin to prevent sandman from affecting ubers!",
	version     = "1.0",
	url         = "<- URL ->"
}

public OnPluginStart()
{
	HookEvent("player_stunned",Event_PlayerStunned);
}


public Action:Event_PlayerStunned(Handle:event,  const String:name[], bool:dontBroadcast)
{
    new victimId = GetEventInt(event, "victim");
    new victim = GetClientOfUserId(victimId);

	new m_nPlayerCond = FindSendPropInfo("CTFPlayer","m_nPlayerCond");
    new cond = GetEntData(victim, m_nPlayerCond);


	new m_nStunTime = FindSendPropInfo("CTFPlayer","m_iStunFlags");
	
	if(cond == 32 || cond == 327712){
		SetEntData(victim, m_nStunTime, 0, 4, true)
		PrintToChatAll("STUN has beed disabled from affecting ubers!");
	}
}
