#include <sourcemod>

new Handle:h_MaxFrags
new MaxFrags;
new Handle:g_map_array = INVALID_HANDLE;
new g_map_serial = -1;
new String:map_name[64];

public Plugin:myinfo =
{
    name = "Winner Choose Map",
    author = "Golden_Eagle",
    description = "Let the winner by fraglimit choose the next map",
    version = "1.0",
    url = "www.amazing-gaming.fr"
}

public OnPluginStart()
{
    h_MaxFrags = FindConVar("mp_fraglimit");
    MaxFrags = GetConVarInt(h_MaxFrags);

    HookConVarChange(h_MaxFrags, OnCVarChange);

    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
}

public OnCVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    MaxFrags = GetConVarInt(cvar);
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new killer = GetClientOfUserId(GetEventInt(event, "attacker"));

    if(IsClientInGame(killer) && GetClientFrags(killer) >= MaxFrags)
        {
            PrintToChatAll("\x03%N\x04 has won the game. He has reached a frag score of \x03%i\x04 first and will now be able to choose the next map.", killer, MaxFrags);
            new Handle:menuMap = CreateMenu(MenuHandler);
            SetMenuTitle(menuMap, "Choose the next map:");
            LoadMapList(Handle:menuMap);
            SetMenuExitButton(menuMap, false);
            DisplayMenu(menuMap, killer, 20);
        }
}

public MenuHandler(Handle:menu, MenuAction:action, param1, param2)
    {
        if ( action == MenuAction_Select ) 
            {
                SetNextMap(map_name);
            }
    }

LoadMapList(Handle:menuMap)
{
	new Handle:map_array;
	
	if ((map_array = ReadMapList(g_map_array,
			g_map_serial,
			"sm_map menu",
			MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_NO_DEFAULT|MAPLIST_FLAG_MAPSFOLDER))
		!= INVALID_HANDLE)
	{
		g_map_array = map_array;
	}
	
	if (g_map_array == INVALID_HANDLE)
	{
		return 0;
	}
	
	RemoveAllMenuItems(menuMap);
	
	new map_count = GetArraySize(g_map_array);
	
	for (new i = 0; i < map_count; i++)
	{
		GetArrayString(g_map_array, i, map_name, sizeof(map_name));
		AddMenuItem(menuMap, map_name, map_name);
	}
	
	return map_count;
}