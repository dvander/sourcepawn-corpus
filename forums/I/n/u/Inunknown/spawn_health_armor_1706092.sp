#include <sourcemod>
#include <sdktools>


new Handle:g_CvarCTHP = INVALID_HANDLE;
new Handle:g_CvarTRHP = INVALID_HANDLE;
new Handle:g_CvarCTAR = INVALID_HANDLE;
new Handle:g_CvarTRAR = INVALID_HANDLE;
//new String:g_ARP[ ] = { "m_ArmorValue" };

public Plugin:myinfo = {
	name = "Set spawn health armor",
	author = "Inunknown",
	description = "When you spawn,You will get x hp and x armor",
	version = "Final",
	url = "http://forums.alliedmods.com/"
}

public OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn);
	g_CvarCTHP = CreateConVar("sm_CT_spawn_health", "100", "CT's Health when spawn", FCVAR_PLUGIN);
	g_CvarTRHP = CreateConVar("sm_T_spawn_health", "100", "TR's Health when spawn", FCVAR_PLUGIN);
	g_CvarCTAR = CreateConVar("sm_CT_spawn_armor", "0", "CT's Armor when spawn(0~127)", FCVAR_PLUGIN, true, 0.0, true, 127.0);
	g_CvarTRAR = CreateConVar("sm_T_spawn_armor", "0", "TR's Armor when spawn(0~127)", FCVAR_PLUGIN, true, 0.0, true, 127.0);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsPlayerAlive(client))
	{
		new team = GetClientTeam(client);
		if (team == 3)
		{
			SetEntityHealth(client, GetConVarInt(g_CvarCTHP));
			SetEntProp(client, Prop_Send, "m_ArmorValue", GetConVarInt(g_CvarCTAR), 1);
		}
		if (team == 2)
		{
			SetEntityHealth(client, GetConVarInt(g_CvarTRHP));
			SetEntProp(client, Prop_Send, "m_ArmorValue", GetConVarInt(g_CvarTRAR), 1);
		}
	}
}