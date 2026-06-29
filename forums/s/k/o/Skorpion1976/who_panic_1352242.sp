#include <sourcemod>

public OnPluginStart() 
{
	HookEvent("create_panic_event", Event_Panic);
}

public Action:Event_Panic(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new id = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientConnected(id))
	{
		new szName[MAX_NAME_LENGTH];
		GetClientName(id, szName, MAX_NAME_LENGTH - 1);
		PrintToChatAll( "\x03[Panic Event]\x01 %s started the panic event!", szName);
	}
	else        
		PrintToChatAll( "\x03[Panic Event]\x01 Panic event has been started!"); 
}

