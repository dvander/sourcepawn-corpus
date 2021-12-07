#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <gifts>
#include <smlib>

#define PLUGIN_VERSION	"1.0"

public Plugin:myinfo =
{
	name = "[Gifts] Test",
	author = "FrozDark (HLModders LLC)",
	description = "Gifts :D",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru/"
};

public OnPluginStart()
{
	Gifts_RegisterPlugin("Gifts_ClientPickUp");

	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	SetEntityGravity(client, 1.0);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
}

public OnPluginEnd()
{
	Gifts_RemovePlugin();
}

public Gifts_ClientPickUp(client)
{
	switch (GetRandomInt(1, 6))
	{
		case 1 :
		{
			SetEntityHealth(client, 100);
			CPrintToChat(client, "{green}[Gifts] {red}You have got health!");
		}
		case 2 :
		{
			SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
			CPrintToChat(client, "{green}[Gifts] {aqua}You have got armor!");
		}
		case 3 :
		{
			new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"); 
			new value = Weapon_GetPrimaryAmmoCount(weapon);
			value +=100;
			Weapon_SetPrimaryAmmoCount(weapon, value);

			CPrintToChat(client, "{green}[Gifts] {aqua}You received more ammo!");


		}
		case 4 :
		{
			decl Float:value2;

			value2 = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
			value2 += 0.2;
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", value2);

			CPrintToChat(client, "{green}[Gifts] {aqua}you received more velocity");


		}
		case 5 :
		{
			decl Float:value3;
			value3 = GetEntityGravity(client);
			value3 -= 0.1;
			SetEntityGravity(client, value3);

			CPrintToChat(client, "{green}[Gifts] {aqua}You have gravity down!");
		}
		case 6 :
		{

			CPrintToChat(client, "{green}[Gifts] {aqua}You have nothing!");
		}
	}
}

