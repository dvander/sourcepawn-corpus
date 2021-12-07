/********************************************************************************************
* Plugin	: PhrasesPickUpItem
* Version	: 1.2
* Game	    : Left4Dead, Left4Dead2  
* Author	: Sheleu
* Testers	: Myself and Aquarius

Version 1.2 (18.07.10)
* 		- Fix bug: plugin don't work when begin new campany.
Version 1.1 (28.06.10)
* 		- Add vomitjar.
Version 1.0 (27.06.10)
* 		- Initial release.
*********************************************************************************************/ 

#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION "1.2"

new bool: isOnMapStart = false;

public Plugin:myinfo = 
{
	name = "PhrasesPickUpItem",
	author = "Sheleu",  
	description = "Plugin with funny phrases at a raising molotov, pipe, vomitjar, propane or oxygen",
	version = PLUGIN_VERSION
};

public OnPluginStart()
{	
	isOnMapStart = false;		
	LoadTranslations("l4d_item_pickup");
	HookEvent("item_pickup", EventItemPickup);
	HookEvent("map_transition", EventMapTransition);
	HookEvent("mission_lost", EventMapTransition);		
	HookEvent("finale_win", RestartPlugin);	
	HookEvent("round_freeze_end", RestartPlugin);	
}

public Action: EventItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:item[64];
	new rnd = GetRandomInt(1,3);
	new client = GetClientOfUserId(GetEventInt(event, "userid"));		
	if (client > 0 && !isOnMapStart)
	{
		GetEventString(event, "item", item, sizeof(item));		
		if(StrEqual(item, "molotov", false))
		{
			switch (rnd)
			{
				case 1: CPrintToChat(client, "%t", "MOLOTOV1");
				case 2: CPrintToChat(client, "%t", "MOLOTOV2");
				case 3: CPrintToChat(client, "%t", "MOLOTOV3");
			}
		}
		else if(StrEqual(item, "pipe_bomb", false))
		{
			switch (rnd)
				{
				case 1: CPrintToChat(client, "%t", "PIPE_BOMB1");
				case 2: CPrintToChat(client, "%t", "PIPE_BOMB2");
				case 3: CPrintToChat(client, "%t", "PIPE_BOMB3");
			}
		}
		else if(StrEqual(item, "vomitjar", false))
		{
			switch (rnd)
			{
				case 1: CPrintToChat(client, "%t", "VOMITJAR1");
				case 2: CPrintToChat(client, "%t", "VOMITJAR2");
				case 3: CPrintToChat(client, "%t", "VOMITJAR3");
			}
		}
		else if(StrEqual(item, "gascan", false))
		{
			switch (rnd)
			{
				case 1: CPrintToChat(client, "%t", "GASCAN1");
				case 2: CPrintToChat(client, "%t", "GASCAN2");
				case 3: CPrintToChat(client, "%t", "GASCAN3");
			}
		}
		else if(StrEqual(item, "propanetank", false))
		{
			switch (rnd)
			{
				case 1: CPrintToChat(client, "%t", "PROPANETANK1");
				case 2: CPrintToChat(client, "%t", "PROPANETANK2");
				case 3: CPrintToChat(client, "%t", "PROPANETANK3");
			}
		}
		else if(StrEqual(item, "oxygentank", false))
		{
			switch (rnd)
			{
				case 1: CPrintToChat(client, "%t", "OXYGENTANK1");
				case 2: CPrintToChat(client, "%t", "OXYGENTANK2");
				case 3: CPrintToChat(client, "%t", "OXYGENTANK3");
			}
		}
	}
	return Plugin_Continue;
}

public Action: EventMapTransition(Handle:event, const String:name[], bool:dontBroadcast)
{	
	isOnMapStart = true;
}

public Action: RestartPlugin(Handle:event, const String:name[], bool:dontBroadcast)
{	
	isOnMapStart = false;
}