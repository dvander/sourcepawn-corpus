#include <sourcemod>

public OnPluginStart()

{

	LoadTranslations("common.phrases");
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}


public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1)
}

public OnGameFrame()

{

	for (new i = 1; i <= MaxClients; i++)
		
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
			
		{
			if(GetClientButtons(i) & IN_ATTACK)
			{
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1)
			}
			if(GetClientButtons(i) & IN_ATTACK2)
			{
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1)
			}
		}


	}
}
