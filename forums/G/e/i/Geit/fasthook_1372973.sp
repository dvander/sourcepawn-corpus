#pragma semicolon 1

#include <sourcemod>
#include <wepannounce>
#include <steamtools>

#define PL_VERSION "1.0"

#define TEAM_BLUE 3
#define TEAM_RED 2
#define TEAM_SPEC 1
#define TEAM_UNASSIGNED 0

new g_SteamConnectedTime=0;
new Handle:g_SteamConnectedTimer;
new bool:g_AllowItemEvent=false;

public Plugin:myinfo = 
{
	name = "Fast Item Hook",
	author = "Geit",
	description = "Provides item notifications as they happen, rather when the player accepts them. Uses the TF2BackpackHook extension by Asherkin",
	version = PL_VERSION,
	url = "http://gamingmasters.co.uk"
};

public OnPluginStart()
{
	CreateConVar("sm_fast_itemhook_version", PL_VERSION, "Fast Item Hooker", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("item_found", Event_item_found_pre, EventHookMode_Pre);
}

public OnMapStart()
{
	if (g_SteamConnectedTimer == INVALID_HANDLE)
	{
		g_SteamConnectedTimer=CreateTimer(1.0, Timer_IncrecementSteamUptime, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	g_SteamConnectedTime=0;
}

public Action:Event_item_found_pre(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_AllowItemEvent)
	{
		SetEventInt(event, "method", 20);
		return Plugin_Changed;
	}
	
	g_AllowItemEvent=false;
	return Plugin_Continue;
}

public OnItemAddedToInventory(client, itemDefinitionIndex, itemLevel, itemQuality, inventoryPos, const String:customName[], const String:customDesc[], const String:itemName[], bool:properName, const String:typeName[], const String:name[], globalIndex_low, globalIndex_high)
{
	if (g_SteamConnectedTime > 30 && IsClientConnected(client) && client > 0)
	{
		if (GetClientTeam(client) != TEAM_UNASSIGNED)
		{
			g_AllowItemEvent=true;
			new Handle:event_item_found = CreateEvent("item_found");
			if (event_item_found != INVALID_HANDLE)
			{
				new itemMethod=inventoryPos & 0xFFFF;
				SetEventInt(event_item_found, "player", client);
				SetEventInt(event_item_found, "quality", itemQuality);
				SetEventString(event_item_found, "item", itemName);
				SetEventInt(event_item_found, "method", itemMethod-1);
				SetEventBool(event_item_found, "propername", properName);
				FireEvent(event_item_found);
				//PrintToChatAll("Forced item found event should have been fired! player: %i quality: %i item: %s method: %i ", client, itemQuality, itemName, itemMethod-1);
			}
			
		}
	}
}

public Action:Timer_IncrecementSteamUptime(Handle:timer, any:timerdata)
{
	if (Steam_IsConnected())
		g_SteamConnectedTime++;	
	else
		g_SteamConnectedTime=0;
}