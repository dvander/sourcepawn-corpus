#pragma semicolon 1
#pragma newdecls required

#include <sdktools_entinput>
#include <sdktools_functions>

static const char WEAPONS[][] =
{
	"item_maglite",
	"tool_welder",
	"fa_glock17"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_Spawn);
}

public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, GiveItemsToPlayer, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action GiveItemsToPlayer(Handle timer, int client)
{
	if((client = GetClientOfUserId(client)) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		for(int i, item; i < sizeof(WEAPONS); i++)
		{
			if((item = GivePlayerItem(client, WEAPONS[i])) == -1)
				LogError("Can't give item '%s' to '%N'", WEAPONS[i], client);
			else if(!AcceptEntityInput(item, "use", client, client))
				LogError("Can't AcceptEntityInput 'use' for item '%s'", WEAPONS[i]);
		}
	}
	return Plugin_Stop;
}