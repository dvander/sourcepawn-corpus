#include <sourcemod>

#define SHOW_OWN_KILLS 1

new String:g_sCMD[][] = {"coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", "fallback", "sticktog", "getinpos", "stormfront", "report", "roger", "enemyspot", "needbackup", "sectorclear", "inposition", "reportingin", "getout", "negative","enemydown"};

public OnPluginStart()
{
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);

	for(new i; i < sizeof(g_sCMD); i++)
	{
		AddCommandListener(Command_BlockRadio, g_sCMD[i]);
	}
}

public OnConfigsExecuted()
{
	ServerCommand("sv_ignoregrenaderadio 1");
}

public Action:Command_BlockRadio(client, const String:command[], args) 
{
	return Plugin_Handled;
}

public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	return (Plugin_Handled);
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	return (Plugin_Handled);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));

	#if SHOW_OWN_KILLS == 1
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(victim == i || attacker == i || assister == i)
				{
					return Plugin_Continue;
				}
				else
				{
					return (Plugin_Handled);
				}
			}
		}
	#endif
	return (Plugin_Handled);
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	return (Plugin_Handled);
}