#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_AUTHOR "AlexMy"
#define PLUGIN_VERSION "1.0"

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[L4D & L4D2] Random Color Tank",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart() 
{
	HookEvent("tank_spawn", Event_tank_spawn);
}

public Action Event_tank_spawn(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, RandomColorTank, GetClientOfUserId(GetEventInt(event, "userid")), TIMER_FLAG_NO_MAPCHANGE);
}

public Action RandomColorTank(Handle timer, any client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		switch(GetRandomInt(1, 16))
		{
			case 1: SetEntityRenderColor(client, 75, 95, 105, 255);
			case 2: SetEntityRenderColor(client, 70, 80, 100, 255);
			case 3: SetEntityRenderColor(client, 130, 130, 255, 255);
			case 4: SetEntityRenderColor(client, 100, 25, 25, 255);
			case 5: SetEntityRenderColor(client, 12, 115, 128, 255);
			case 6: SetEntityRenderColor(client, 100, 255, 200, 255);
			case 7: SetEntityRenderColor(client, 128, 0, 0, 255);
			case 8: SetEntityRenderColor(client, 0, 100, 170, 200);
			case 9: SetEntityRenderColor(client, 255, 200, 0, 255);
			case 10: SetEntityRenderColor(client, 100, 100, 100, 0);
			case 11: SetEntityRenderColor(client, 100, 165, 255, 255);
			case 12: SetEntityRenderColor(client, 255, 200, 255, 255);
			case 13: SetEntityRenderColor(client, 135, 205, 255, 255);
			case 14: SetEntityRenderColor(client, 0, 105, 255, 255);
			case 15: SetEntityRenderColor(client, 200, 255, 0, 255);
			case 16: SetEntityRenderColor(client, 33, 34, 35, 255);
		}
	}
	return Plugin_Stop;
}
