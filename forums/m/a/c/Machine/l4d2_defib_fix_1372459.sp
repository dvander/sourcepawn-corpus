#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

new Float:DeathOrigin[MAXPLAYERS + 1][3];

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}
public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	new entitycount = GetMaxEntities();
	for (new e=1; e<=entitycount; e++)
	{
		if (IsValidEntity(e))
		{
			decl String:classname[32];
			GetEdictClassname(e, classname, sizeof(classname));
			if (StrEqual(classname, "survivor_death_model"))
			{
				decl Float:Origin[3];
				GetEntPropVector(e, Prop_Send, "m_vecOrigin", Origin);
				if (DeathOrigin[client][0] == Origin[0] && DeathOrigin[client][1] == Origin[1] && DeathOrigin[client][2] == Origin[2])
				{
					AcceptEntityInput(e, "Kill");
				}
			}
		}
	}
}
public Action:Event_PlayerDeath(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client > 0)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			GetClientAbsOrigin(client, DeathOrigin[client]);
		}
	}
}
