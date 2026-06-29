#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo =
{
	name = "Buy-Menu Disabler",
	author = "Marcus",
	description = "An easy plugin to disable buyzones.",
	version = "1.0.0",
	url = "http://snbx.info"
};

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	RemoveBuyZone( );
}

public OnMapStart( )
{
	RemoveBuyZone( );
	PrintToChatAll("[SM] This server has disabled buy-zones.");
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	RemoveBuyZone( );
}

RemoveBuyZone( )
{
	new MaxEntities = GetMaxEntities( );
	decl String:class[64];

	for(new i = MaxClients; i <= MaxEntities; i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if(StrEqual("func_buyzone", class))
			{
				RemoveEdict(i);
			}
		}
	}
}