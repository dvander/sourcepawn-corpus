#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "Magical disappeareance cuttaroo",
	author = "Original by d0ck3r for CS:S, cleaned by Jim McKenzie for CS:GO",
	description = "Makes the knives being held by zombies disappear so they don't look like gangsta muggers.",
	version = "1.0.0",
	url = ""
};

new bool:lateLoad = false;

public OnMapStart()
{
	if (lateLoad == true)
	{
		return;
	}
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
		{
			continue;
		}
		OnClientPutInServer(client);
	}
	lateLoad = true;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public OnPostThinkPost(client)
{	
	// If the player isn't alive we don't cate
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	// We don't care if he isn't a zombie either
	if (GetClientTeam(client) != 2)
	{
		return;
	}

	// We get the knife
	new entity = GetPlayerWeaponSlot(client, 2); 
	
	// If the knife exist then we go on
	if (IsValidEdict(entity))
	{
		SetEntityRenderMode(entity, RENDER_NONE);
	}
}
