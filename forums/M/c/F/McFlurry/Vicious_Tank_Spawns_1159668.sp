#include <sourcemod>
#pragma semicolon 1

#define VICIOUS_TANK_SPAWNS
#define PLUGIN_VERSION "1.31"

new g_iTankClient;
new bool:g_bTankIsInPlay;
new Handle:g_hAnnounce;
new Announce;
new Handle:g_hBoomer = INVALID_HANDLE;
static bool:BoomerTimeout = false;
new Handle:g_hSpitter = INVALID_HANDLE;
static laggedMovementOffset = 0;

public Plugin:myinfo = 
{
    name = "[L4D2] Vicious Tank Spawns",
    author = "Mortiegama",
    description = "This plugin will create a panic event when the tank spawns, spawn a witch when the tank dies, spawn a mob when a boomer vomits/explodes, and slow survivors when they run through spitter goo.",
    version = PLUGIN_VERSION,
    url = ""
}

public OnPluginStart()
{
        HookEvent("tank_spawn", Tank_Spawned);
	HookEvent("player_death", Tank_Dead);
	HookEvent("player_now_it", Event_PlayerNowIt);
	HookEvent("entered_spit", Event_SpitSlow);
	g_hAnnounce = CreateConVar("l4d_vts_announce", "1", "Announce panic event and witch spawn?");
	g_hBoomer = CreateConVar("l4d_vts_boomer", "1", "Does a Boomer summon a mob when puking?");
	g_hSpitter = CreateConVar("l4d_vts_spitter", "1", "Does running through spit slow the survivor?");
	laggedMovementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
}

public OnMapStart()
{
	/* Precache Models */
	PrecacheModel("models/infected/witch.mdl", true);	

}	

public Action:Tank_Spawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_hAnnounce = FindConVar("l4d_vts_announce");
	Announce = GetConVarInt(g_hAnnounce);
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iTankClient = client;	
	if(g_bTankIsInPlay){return;}	
	g_bTankIsInPlay = true;
	new flags3 = GetCommandFlags("z_spawn");
	new flags4 = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("z_spawn", flags3 & ~FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flags4 & ~FCVAR_CHEAT);
	FakeClientCommand(client, "director_force_panic_event");
	SetCommandFlags("z_spawn", flags3|FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flags4|FCVAR_CHEAT);
	PrintToServer("[Vicious Tank] Panic Event starting.");
	if (Announce != 0) PrintToChatAll("[SM] The tank has caused a panic event!");

}

  
public Action:Tank_Dead(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_hAnnounce = FindConVar("l4d_vts_announce");
	Announce = GetConVarInt(g_hAnnounce);
	if(!g_bTankIsInPlay){return;}
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client != g_iTankClient){return;}
	new flags3 = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", flags3 & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", "z_spawn", "witch auto");  
	PrintToServer("[Vicious Tank] Witch spawned.");
	SetCommandFlags("z_spawn", flags3|FCVAR_CHEAT);
	Reset();
	if (Announce != 0) PrintToChatAll("[SM] A Witch has appeared to mourn the tank!");
}

public Event_PlayerNowIt (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_hBoomer) && !BoomerTimeout)
{
	BoomerTimeout = true;
	CreateTimer(10.0, BoomWaitTime);
	new client = GetClientOfUserId(GetEventInt(event,"attacker"));
	new flags3 = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", flags3 & ~FCVAR_CHEAT);
	FakeClientCommand(client,"z_spawn mob auto");
	SetCommandFlags("z_spawn", flags3|FCVAR_CHEAT);
}
}

public Event_SpitSlow (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (GetConVarBool(g_hSpitter) && IsClientInGame(client) == true)
{
	PrintHintText(client, "Standing in the spit is slowing you down!");
	CreateTimer(4.0, SpitSlow, client);
	SetEntDataFloat(client, laggedMovementOffset, 0.5, true); //this halves the survivors speed
}
}


public Action:BoomWaitTime(Handle:timer)
{
	BoomerTimeout = false;
}

public Action:SpitSlow(Handle:timer, any:client)
{
	SetEntDataFloat(client, laggedMovementOffset, 1.0, true); //sets the survivors speed back to normal
	PrintHintText(client, "The spit is wearing off!");
}

Reset()
{
	g_bTankIsInPlay = false;
}