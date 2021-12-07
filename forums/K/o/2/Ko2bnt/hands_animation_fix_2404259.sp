#pragma semicolon 1
#include <sdkhooks>

#define PLUGIN_NAME "HL2DM hands animation fix"
#define PLUGIN_AUTHOR "toizy"
#define PLUGIN_DESCRIPTION "Fixes a common bug, called the hands of Jesus or something like that."
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL "toizy@mail.ru"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanSwitchTo, Hook_WeaponCanSwitchTo);
}

public Action:Hook_WeaponCanSwitchTo(client, weapon) 
{
	SetEntityFlags(client, GetEntityFlags(client) | FL_ONGROUND);
}

public OnPluginStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			SDKHook(i, SDKHook_WeaponCanSwitchTo, Hook_WeaponCanSwitchTo);
		}
	}
}