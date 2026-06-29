#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "0.1"
#include <swarmtools> 

public Plugin:myinfo = 
{
    name = "DeltaTimo's Healme",
    author = "DeltaTimo",
    description = "Allows Admins with CHEAT Flag to healme.",
    version = PLUGIN_VERSION,
    url = ""
}

public OnPluginStart()
{
    //tank buster weapons menu cvar
	RegAdminCmd("healme", HealmeDo, ADMFLAG_CHEATS);
	RegAdminCmd("cureinfection", cureinfectiondo, ADMFLAG_CHEATS);
	RegAdminCmd("suicide", suicidedo, ADMFLAG_CHEATS);
    //plugin version
	CreateConVar("deltas_healme_version", PLUGIN_VERSION, "Tank_Buster_Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:HealmeDo(client,args)
{
    healme(client);
    
    return Plugin_Handled;
}
public Action:cureinfectiondo(client,args)
{
    cureinfection(client);
    
    return Plugin_Handled;
}
public Action:suicidedo(client,args)
{
	suicide(client);
	
	return Plugin_Handled;
}
public Action:healme(client) {
	Swarm_SetMarineHealth(Swarm_GetMarine(client), Swarm_GetMarineMaxHealth(Swarm_GetMarine(client)));
	PrintToConsole( client, "You have been healed." );
	return Plugin_Handled;
}

public Action:cureinfection(client) {
	if ( Swarm_IsMarineInfested(Swarm_GetMarine(client)) == true ) {
		Swarm_CureMarineInfestation(Swarm_GetMarine(client));
	}
	PrintToConsole( client, "You're infection has been cured." );
	return Plugin_Handled;
}
public Action:suicide(client) {
	Swarm_ForceMarineSuicide(Swarm_GetMarine(client));
	PrintToConsole( client, "You're marine has commited suicide." );
	return Plugin_Handled;
}