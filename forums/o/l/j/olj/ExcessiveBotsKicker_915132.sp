#define PLUGIN_VERSION "1.0"
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

new Handle:h_MaxBotsAllowed;
new Handle:h_KickTime;
new Float:KickTime;
new MaxBotsAllowed;


public Plugin:myinfo = 

{
	name = "Excessive butts/bots kicker",
	author = "Olj",
	description = "Kick excessive bots",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}



public OnPluginStart()
{
	h_MaxBotsAllowed = CreateConVar("l4d_maxbots", "4", "Maximum bots allowed", CVAR_FLAGS);
	h_KickTime = CreateConVar("l4d_maxbots_kicktime", "200.0", "Time before checking for excessive bots starts.", CVAR_FLAGS);
	MaxBotsAllowed = GetConVarInt(h_MaxBotsAllowed);
	KickTime = GetConVarFloat(h_KickTime);
	HookConVarChange(h_MaxBotsAllowed, MaxBotsAllowedChanged);
	HookEvent("round_start", KickBots, EventHookMode_Post);
	AutoExecConfig(true, "l4d_excessivebotskicking");
}

public MaxBotsAllowedChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		MaxBotsAllowed = GetConVarInt(h_MaxBotsAllowed);
	}			
	
public KickBots(Handle:event, const String:name[], bool:dontBroadcast)
	{
		CreateTimer(KickTime, KickBotsTimer ,0,TIMER_FLAG_NO_MAPCHANGE);
	}
	
public Action:KickBotsTimer(Handle:timer)
	{
		new BotCount = 0;
		for (new i = 1; i <=MaxClients; i++)
			{
				if ((IsClientInGame(i))&&(IsClientConnected(i))&&(GetClientTeam(i)==2)&&(IsFakeClient(i)))
					{
						BotCount++;
						if (BotCount>MaxBotsAllowed) 
							{
								KickClient(i);
								BotCount--;
							}
					}	
			}
	}