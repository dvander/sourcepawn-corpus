#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdktools>

#define VERSION "1.0"



public Plugin:myinfo = 
{
	name = "[TF2]Unicorn Lines",
	author = "Classic",
	description = "Play unicorn's lines",
	version = VERSION,
	url = ""
}


public OnPluginStart()
{
	CreateConVar("ul_version", VERSION, "Unicorn Lines version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("post_inventory_application", OnItemsGiven);
}

public OnItemsGiven(Handle:event, const String:name[], bool:dontBroadcast)
{		
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(CheckClient(client))
	{
		
		SetVariantString("randomnum:100");
		AcceptEntityInput(client, "AddContext");
		
		SetVariantString("IsUnicornHead:1");
		AcceptEntityInput(client, "AddContext");
	
	}
	
}
bool:CheckClient(client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) )
	{
		return false;
	}
	return true;
}
