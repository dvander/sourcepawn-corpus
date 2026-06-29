#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"
#define MAX_STRING_LEN 255

public Plugin:myinfo =
{
	name = "Buildings Built Test",
	author = "Antithasys",
	description = "Test buildings built code",
	version = PLUGIN_VERSION,
	url = "http://www.mytf2.com"
}

public OnPluginStart()
{
	RegConsoleCmd("doihavebuildings", Command_BuildingCheck, "Returns if you have buildings or not");
}

public Action:Command_BuildingCheck(client, args)
{
	if (client == 0) {
		ReplyToCommand(client, "Command must be run at the player level");
		return Plugin_Handled;
	}
	if (HasBuildingsBuilt(client))
		ReplyToCommand(client, "You have buildings built");
	else
		ReplyToCommand(client, "You do not have buildings built");
	return Plugin_Handled;
}

stock bool:HasBuildingsBuilt(client)
{
	new maxclients = GetMaxClients();
	new maxentities = GetMaxEntities();
	new bool:result = false;
	for (new i = maxclients + 1; i <= maxentities; i++)
    {
        if (!IsValidEntity(i))
            continue;
        decl String:netclass[32];
        GetEntityNetClass(i, netclass, sizeof(netclass));
        if (strcmp(netclass, "CObjectSentrygun") == 0 
		|| strcmp(netclass, "CObjectTeleporter") == 0 
		|| strcmp(netclass, "CObjectDispenser") == 0) {
			new buildingclient = GetEntPropEnt(i, Prop_Data, "m_hBuilder");
			if (buildingclient == client) {
				result = true;
				break;
            }
		}
    }
	return result;
}