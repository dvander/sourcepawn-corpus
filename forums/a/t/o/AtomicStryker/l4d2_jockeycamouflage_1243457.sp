#pragma semicolon			1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.0.0"


static const String:ENTPROP_ZOMBIE_CLASS[] 			= "m_zombieClass";
static const L4D2_TEAM_INFECTED						= 3;
static const ZOMBIECLASS_JOCKEY						= 5;

static Handle:cvar_Setting							= INVALID_HANDLE;


public Plugin:myinfo =
{
	name = "[L4D2] Jockey Stealth",
	author = "AtomicStryker",
	description = " Makes Jockey camouflaged ",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("l4d2_jockey_camouflage_version", PLUGIN_VERSION, " L4D2 Jockey Camouflage Plugin Version ", 	FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	
	cvar_Setting = CreateConVar("l4d2_jockey_camouflage_setting", "25", " How visible shall Jockey be - 0 is invisible, 255 is max ", FCVAR_PLUGIN|FCVAR_REPLICATED);

	HookEvent("player_spawn", _event_PlayerSpawn);
}

public Action:_event_PlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client
	|| !IsClientInGame(client)
	|| GetClientTeam(client) != L4D2_TEAM_INFECTED
	|| GetEntProp(client, Prop_Send, ENTPROP_ZOMBIE_CLASS) != ZOMBIECLASS_JOCKEY) return;
	
	MakeInvisible(client);
}

static MakeInvisible(client)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 190, 190, 255, GetConVarInt(cvar_Setting));
}