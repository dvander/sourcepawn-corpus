#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <zr_tools>
#include <zombiereloaded>

#define PLUGIN_VERSION	"1.0"

public Plugin:myinfo =
{
	name = "[ZR] Print Class Info",
	author = "FrozDark (HLModders LLC)",
	description = "[ZR] Class info printer",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru/"
};

public OnPluginStart()
{
	CreateConVar("zr_class_info_version", PLUGIN_VERSION, "The version of class info", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	PrintInfo(client);
}

public ZR_OnClientHumanPost(client, bool:respawn, bool:protect)
{
	PrintInfo(client);
}

PrintInfo(client)
{
	decl String:buffer[256];
	ZR_GetClassDisplayName(client, buffer, sizeof(buffer), ZR_CLASS_CACHE_PLAYER);
	PrintToChat(client, "\x01Your Class: \x04%s", buffer);
	ZRT_GetClientAttributeString(client, "description", buffer, sizeof(buffer));
	PrintToChat(client, "\x01Description: \x03%s", buffer);
}