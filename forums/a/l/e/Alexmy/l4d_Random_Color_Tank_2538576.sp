#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

public Plugin myinfo = 
{
	name = "[L4D] Random Color Tank",
	author = "AlexMy",
	description = "",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2498019#post2498019"
};

public void OnPluginStart()
{
	HookEvent("tank_spawn", Event_tank_spawn, EventHookMode_Post);
}

public Action Event_tank_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	{
		if(client <= 0 || client > GetMaxClients() || !IsValidEntity(client) || !IsClientInGame(client))return;
		{
			SetEntityRenderColor(client, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 255); 
		}
	}
}