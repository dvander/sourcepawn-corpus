//                          ==========================================================================
//	                    |     Plugin By Tair Azoulay                                             |
//                          |                                                                        |
//                          |     Profile : http://steamcommunity.com/profiles/76561198013150925/    |                                         |
//                          |                                                                        |
//	                    |     Name : Grenades On Spawn                                           |
//                          |                                                                        |
//	                    |     Version : 1.0                                                      |
//                          |                                                                        |
//	                    |     Description : Flash + Smoke + HeGrenade on spawn (+ Molotov in csgo)|                       |     
//                          ==========================================================================

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0"
new Handle:gs_Cvar_Enable = INVALID_HANDLE
new Handle:gs_Cvar_hegrenade = INVALID_HANDLE
new Handle:gs_Cvar_flashbang = INVALID_HANDLE
new Handle:gs_Cvar_smoke = INVALID_HANDLE
new Handle:gs_Cvar_molotov = INVALID_HANDLE

public Plugin:myinfo = 
{
	name = "Grenades On Spawn",
	author = "Tair",
	description = "Gives Grenades On Spawn (Flash , Smoke , HeGrenade ,Molotov)",
	version = "1.1",
	url = "Www.sourcemod.net"
}

public OnPluginStart() 
{
	HookEvent("player_spawn", Event_PlayerSpawn);
        CreateConVar("sm_gs_version", PLUGIN_VERSION, "Version of the Plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
        gs_Cvar_Enable = CreateConVar("sm_gs_enabled", "1", "Enables or Disables the Plugin", FCVAR_PLUGIN);
        gs_Cvar_molotov = CreateConVar("sm_gs_molotov", "1", "Enables or Disables Molotov");
        gs_Cvar_hegrenade = CreateConVar("sm_gs_hegrenade", "1", "Enables or Disables HeGrenade");
        gs_Cvar_flashbang = CreateConVar("sm_gs_flashbang", "1", "Enables or Disables Flashbang");
        gs_Cvar_smoke = CreateConVar("sm_gs_smoke", "1", "Enables or Disables Smoke Grenade");
}


public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetConVarInt(gs_Cvar_Enable))
	{
	PrintToChat(client, " \x04[SM] \x03You Received Grenades !");

	if (GetConVarInt(gs_Cvar_molotov))
	{
	GivePlayerItem(client, "weapon_molotov");
        }

	if (GetConVarInt(gs_Cvar_hegrenade))
	{
	GivePlayerItem(client, "weapon_hegrenade");
        }

	if (GetConVarInt(gs_Cvar_flashbang))
	{
	GivePlayerItem(client, "weapon_flashbang");
        }

	if (GetConVarInt(gs_Cvar_smoke))
	{
	GivePlayerItem(client, "weapon_smokegrenade");
        }
	}
}
