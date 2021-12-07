#pragma semicolon 1
#include <tf2_stocks>
#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "[TF2] Infinite buildings",
	author = "Pelipoika",
	description = "Cream gravy!",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	AddCommandListener(Listener_Build, "build");

	HookEvent("player_builtobject", Event_BuiltObject);
}

public Event_BuiltObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	new iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "obj_*")) != -1) 
	{
		if(GetEntProp(iEnt, Prop_Send, "m_bDisposableBuilding") == 1 && GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder") == client)
		{
			SetEntProp(iEnt, Prop_Send, "m_bDisposableBuilding", 0);
		}
	}
}

public Action:Listener_Build(client, String:cmd[], args)
{
	if (args < 1) return Plugin_Continue;
	if (TF2_GetPlayerClass(client) != TFClass_Engineer) return Plugin_Continue;

	decl String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));

	new iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "obj_*")) != -1) 
	{
		if (GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder") == client && GetEntProp(iEnt, Prop_Send, "m_bDisposableBuilding") != 1)
		{
			SetEntProp(iEnt, Prop_Send, "m_bDisposableBuilding", 1);
		}
	}
	
	return Plugin_Continue;
}