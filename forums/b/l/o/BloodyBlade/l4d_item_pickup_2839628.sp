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
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION "1.2"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

ConVar hPluginEnable;
bool isOnMapStart = false, bHooked = false;

public Plugin myinfo = 
{
	name = "PhrasesPickUpItem",
	author = "Sheleu(Edit. by BloodyBlade)",  
	description = "Plugin with funny phrases at a raising molotov, pipe, vomitjar, propane or oxygen",
	version = PLUGIN_VERSION
};

public void OnPluginStart()
{	
	CreateConVar("l4d_item_pickup_version", PLUGIN_VERSION, "PhrasesPickUpItem plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hPluginEnable = CreateConVar("l4d_item_pickup_enable", "1", "Enables this plugin.", CVAR_FLAGS, true, 0.0, true, 1.0);
	AutoExecConfig(true, "l4d_item_pickup");
	hPluginEnable.AddChangeHook(OnConVarEnableChanged);
	LoadTranslations("l4d_item_pickup");
}

public void OnMapStart()
{
	isOnMapStart = true;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarEnableChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = hPluginEnable.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		HookEvent("item_pickup", EventItemPickup);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("item_pickup", EventItemPickup);
	}
}

Action EventItemPickup(Event event, const char[] name, bool dontBroadcast)
{
	char item[64];
	int rnd = GetRandomInt(1,3);
	int client = GetClientOfUserId(event.GetInt("userid"));		
	if (client > 0 && !isOnMapStart)
	{
		event.GetString("item", item, sizeof(item));		
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

public void OnMapEnd()
{	
	isOnMapStart = false;
}
