#include <sourcemod>
#include <attributes>
#include <sdkhooks>
#include <colors>

#pragma semicolon 1
#define PLUGIN_VERSION "0.1.0"

new Handle:g_hCvarHealthPlus;
new g_iHealthPlus;

new Handle:g_hCvarBaseHealth;
new g_iBaseHealth;


new g_Lifeforce[MAXPLAYERS+1];
new g_iLifeforceID;

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = "tAttributes Mod, Lifeforce",
	author = "Thrawn",
	description = "A plugin for tAttributes Mod, Lifeforce, increases maximum health.",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}


//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
	// G A M E  C H E C K //
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	if((StrEqual(game, "tf")))
	{
		SetFailState("This plugin is not for %s", game);
	}

	g_hCvarHealthPlus = CreateConVar("sm_att_lifeforce_healthplus", "2", "Health grows by this value every attribute point", FCVAR_PLUGIN, true, 0.0);
	g_hCvarBaseHealth = CreateConVar("sm_att_lifeforce_basehealth", "200", "Base Health for survivors", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hCvarHealthPlus, Cvar_Changed);
	HookConVarChange(g_hCvarBaseHealth, Cvar_Changed);

	HookEvent("player_spawn", Event_Player_Spawn);
}

public OnConfigsExecuted()
{
	g_iHealthPlus = GetConVarInt(g_hCvarHealthPlus);
	g_iBaseHealth = GetConVarInt(g_hCvarBaseHealth);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public OnAllPluginsLoaded() {
	if(LibraryExists("attributes")) {
		g_iLifeforceID = att_RegisterAttribute("Lifeforce", "Increases health", att_OnLifeforceChange);
	}
}

//////////////////////////
//E V E N T   H O O K S //
//////////////////////////
public Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(att_IsEnabled())
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		applyClassHealth(client);
	}
}

public OnPluginEnd()
{
	//att_UnregisterAttribute(g_iLifeforceID);
	LogMessage("Did NOT unload LifeForce Attribute (%i)", g_iLifeforceID);
}

public att_OnLifeforceChange(iClient, iValue, iAmount) {
	g_Lifeforce[iClient] = iValue;
	if(IsClientInGame(iClient)) {
		applyClassHealth(iClient);
		if(iAmount != -1)
		{
			CPrintToChat(iClient, "You start with {green}%i{default} additional healthpoints.", g_Lifeforce[iClient] * g_iHealthPlus);
		}
	}
}

stock applyClassHealth(client) {
	new iHealth = g_iBaseHealth + g_Lifeforce[client] * g_iHealthPlus;
	
	if(IsClientInGame(client) && GetClientTeam(client) == 3){
		iHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth") + g_Lifeforce[client] * g_iHealthPlus;
	}
	
	new iCurrentDiff = GetEntProp(client, Prop_Data, "m_iMaxHealth") - GetClientHealth(client);

	SetEntProp(client, Prop_Data, "m_iMaxHealth", iHealth);

	SetEntityHealth(client, iHealth-iCurrentDiff);
}