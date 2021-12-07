#include <sourcemod>
#include <sdktools>

new Handle: g_cvar_steelwitch = INVALID_HANDLE;
new Handle: g_cvar_sw_health = INVALID_HANDLE;


public Plugin:myinfo = 
{
	name = "Steel Witch",
	author = "Karma",
	description = "Witch will not be damaged unless she is shot in the head. Starting HP of witch becomes 2000.",
	version = "1.0.0",
	url = "N/A"
}

public OnPluginStart()
{
	decl String:gamename[16]
	GetGameFolderName(gamename, sizeof(gamename))
	
	if (!StrEqual(gamename, "left4dead2", false)) SetFailState("This plugin support Left 4 Dead 2 only.")//plugin for l4d2 only.
	
	g_cvar_steelwitch = CreateConVar("sm_steelwitch", "1", "Enable(1) or disable(0) Steel Witch plugin. Version: 1.0.0", FCVAR_PLUGIN);
	g_cvar_sw_health = CreateConVar("sm_steelwitch_hp", "2000", "Set witch's starting health.", FCVAR_PLUGIN, true, 1.0, true, 10000.0);
	
	HookEvent("infected_hurt", Event_WitchHurt);
	HookEvent("witch_spawn", Event_WitchHealth);
}

public Action:Event_WitchHurt(Handle:event, const String:name[], bool:dontBroadcast){
	if (GetConVarInt(g_cvar_steelwitch) == 0) return Plugin_Continue;
	
	new entId = GetEventInt(event, "entityid"); //Get id of zombie hurt
	decl String:entClass[96]; 
	GetEntityNetClass(entId, entClass, sizeof(entClass)); 
	if (!StrEqual(entClass, "Witch")) return Plugin_Continue; //Check whether it is a witch.
	
	if (GetEventInt(event, "hitgroup") != 1) //If damaged area is not head, 
	{ 
		SetEntProp(entId, Prop_Data, "m_iHealth",GetEntProp(entId, Prop_Data, "m_iHealth")+GetEventInt(event, "amount")); //do no damage to witch.
	}
	return Plugin_Continue;
}
	
public Event_WitchHealth(Handle:event, const String:name[], bool:dontBroadcast){
	new entId = GetEventInt(event, "witchid");
	new witchStartHealth = GetConVarInt(g_cvar_sw_health);//Get starting health of witch.
	
	SetEntProp(entId, Prop_Data, "m_iMaxHealth", witchStartHealth);//Set max and 
	SetEntProp(entId, Prop_Data, "m_iHealth", witchStartHealth); //current health of witch to defined health.
}