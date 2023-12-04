#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <gifts>

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
}

public OnPluginEnd()
{
	Gifts_RemovePlugin();
}

public Gifts_ClientPickUp(client)
{
	switch (GetRandomInt(1, 2))
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
	}
}