#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	RegConsoleCmd("sm_cancel", Command_Cancel);
}

public Action:Command_Cancel(client, args)
{
	new iMarker = MaxClients+1;
	while((iMarker = FindEntityByClassname(iMarker, "entity_revive_marker")) > MaxClients)
	{
		if(GetEntPropEnt(iMarker, Prop_Send, "m_hOwner") == client)
		{
			AcceptEntityInput(iMarker, "Kill");
		}
	}

	return Plugin_Handled;
}