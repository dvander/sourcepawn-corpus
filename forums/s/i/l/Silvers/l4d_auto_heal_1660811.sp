#define PLUGIN_VERSION 		"1.0"
#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY
#pragma semicolon 			1

public Plugin:myinfo =
{
	name = "[L4D & L4D2] Auto Heal",
	author = "SilverShot",
	description = "Auto heals players on round end.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=179503"
}


static Handle:g_hCvarMax, g_iCvarMax;

public OnPluginStart()
{
	g_hCvarMax = CreateConVar("l4d_auto_heal_max", "50", "Heal someone to this much health on round end.", CVAR_FLAGS);
	CreateConVar("l4d_auto_heal_version", PLUGIN_VERSION, "Auto Healing plugin version.", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	HookEvent( "round_end", Event_RoundEnd);
}

public CvarChange_Cvar(Handle:convar, const String:oldValue[], const String:newValue[])
	g_iCvarMax = GetConVarInt(g_hCvarMax);

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for( new i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
			HealClient(i);
}

HealClient(client)
{
	new iHealth = GetClientHealth(client);
	if( iHealth > g_iCvarMax )
		return;

	SetEntityHealth(client, g_iCvarMax);
}