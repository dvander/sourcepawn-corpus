#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.0.2"

public Plugin:myinfo =
{
	name = "Objective Remover",
	author = "SavSin",
	description = "Removes bomb and hostages from the map.",
	version = PLUGIN_VERSION,
	url = "http://www.norcalbots.com/"
};

public OnPluginStart()
{
	//Create Public Var for Server Tracking
	CreateConVar("objrem_version", PLUGIN_VERSION, "Version of Objective Remover", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//Hook Events
	HookEvent("round_start", OnRoundStart);
	HookEvent("item_pickup", OnItemPickUp);
}

public OnMapStart()
{
	//Create a variable to hold the index of the entities
	new iEnt = -1;
	while((iEnt = FindEntityByClassname(iEnt, "func_bomb_target")) != -1) //Find bombsites
	{
		AcceptEntityInput(iEnt,"kill"); //Destroy the entity
	}
	
	while((iEnt = FindEntityByClassname(iEnt, "func_hostage_rescue")) != -1) //Find rescue points
	{
		AcceptEntityInput(iEnt,"kill"); //Destroy the entity
	}
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iEnt = -1;
	while((iEnt = FindEntityByClassname(iEnt, "hostage_entity")) != -1) //Find the hostages themselves and destroy them
	{
		AcceptEntityInput(iEnt, "kill");
	}
}

public Action:OnItemPickUp(Handle:hEvent, const String:szName[], bool:dontBroadcast)
{
	new String:temp[32];
	GetEventString(hEvent, "item", temp, sizeof(temp));
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(StrEqual(temp, "weapon_c4", false)) //Find the bomb carrier
	{
		new iWeaponIndex = GetPlayerWeaponSlot(iClient, 4);
		RemovePlayerItem(iClient, iWeaponIndex); //Remove the bomb
	}
	return Plugin_Continue;
}