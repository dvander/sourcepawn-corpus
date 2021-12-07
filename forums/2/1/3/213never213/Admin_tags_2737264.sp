#define PLUGIN_AUTHOR "never"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <cstrike>
#include <colors_csgo>

#pragma semicolon 1

#define Tag "{green}[SM]{default}"

bool lock = false;

public Plugin myinfo = 
{
	name = "Hide tags", 
	author = PLUGIN_AUTHOR, 
	description = "tags for Admins", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/213never213/"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_hide", cmd_hide, ADMFLAG_GENERIC);
	
	HookEvent("player_spawn", Player_Spawn);
}

public Action cmd_hide(int client, int args)
{
	lock = lock == true ? false : true;
	
	if (lock)
	{
		CPrintToChat(client, "%s you are hidden!", Tag);
		HandleTag2(client);
	}
	else
	{
		CPrintToChat(client, "%s You're not hidden anymore!", Tag);
		HandleTag(client);
	}
	
}

public Action Player_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsFakeClient(client) | IsClientSourceTV(client))
	{
		return;
	}
	
	if (lock)
	{
		HandleTag2(client);
	}
	else
	{
		HandleTag(client);
	}
}

HandleTag(client)
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		CS_SetClientClanTag(client, "[Owner]");
	}
	else if (GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
	{
		CS_SetClientClanTag(client, "[Head-Admin]");
	}
	else if (GetUserFlagBits(client) & ADMFLAG_GENERIC)
	{
		CS_SetClientClanTag(client, "[Admin]");
	}
}

HandleTag2(client)
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		CS_SetClientClanTag(client, "[VIP]");
	}
	else if (GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
	{
		CS_SetClientClanTag(client, "[VIP]");
	}
	else if (GetUserFlagBits(client) & ADMFLAG_GENERIC)
	{
		CS_SetClientClanTag(client, "[VIP]");
	}
}
