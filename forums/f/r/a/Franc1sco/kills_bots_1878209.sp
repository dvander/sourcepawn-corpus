#include <sourcemod>
#include <sdktools>

#pragma semicolon 1


public OnPluginStart()
{
	HookEvent("player_death", playerDeath);
}

public Action:playerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!clientevalido(attacker))
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsFakeClient(attacker))
	{
		new olddeaths = GetEntProp(client, Prop_Data, "m_iDeaths");
		SetEntProp(client, Prop_Data, "m_iDeaths", olddeaths-1);
	}
	else if (IsFakeClient(client)) SetEntProp(attacker, Prop_Data, "m_iFrags", GetClientFrags(attacker)-1);
}

public clientevalido( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}