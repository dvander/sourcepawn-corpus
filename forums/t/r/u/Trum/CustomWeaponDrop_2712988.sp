#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required

int g_iLastDroppedItem[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "CustomWeaponDrop",
	author = "Trum (Impact's drop mechanic idea)",
	description = "Preventing people from spam-dropping guns on the ground",
	version = "1.0",
	url = "",
}

public void OnPluginStart()
{
    AddCommandListener(OnDrop, "drop");

    HookEvent("player_spawn", OnSpawn);
}

public Action OnSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if(client)
        g_iLastDroppedItem[client] = 0;
}

public Action OnDrop(int client, const char[] command, int argc)
{
    g_iLastDroppedItem[client] = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

public Action CS_OnCSWeaponDrop(int client, int weapon)
{
	if(GameRules_GetProp("m_bWarmupPeriod"))
    {
		if(IsValidEdict(weapon))
			AcceptEntityInput(weapon, "Kill");

		if(weapon == g_iLastDroppedItem[client])
			RemoveEntity(weapon);
	}
}

public Action CS_OnGetWeaponPrice(int client, const char[] weapon, int &price)
{
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
	{
		price = 0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}