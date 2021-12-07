#include <sourcemod>
#include <sdktools>

public OnClientPutInServer(int client)
{
	CreateTimer(0.5, Timer_Aim, client, TIMER_REPEAT);
}

public Action Timer_Aim(Handle timer, any client)
{
	if (!IsClientInGame(client))
	{
		return Plugin_Stop;
	}

	if (IsPlayerAlive(client))
	{
		new entity_aim = GetClientAimTarget(client,false); 
		if(entity_aim != -1 && entity_aim != -2)
		{
			new String:strName[64];
			GetEntPropString(entity_aim, Prop_Data, "m_iClassname", strName, sizeof(strName));
			PrintCenterText(client, "%s", strName);
		}
	}
	return Plugin_Continue;
}
