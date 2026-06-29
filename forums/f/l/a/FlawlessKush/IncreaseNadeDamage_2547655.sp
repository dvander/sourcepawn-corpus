//change log
/* 

-Version 1.0.4
Update Syntax to a new.
Add VIP Cvars
IsValidClient is in my include file, if you need. make your own .inc file and add this bool
stock bool IsValidClient(int client, bool noBots=true) {
	if (client < 1 || client > MaxClients)
		return false;
	if (!IsClientInGame(client))
		return false;
	if (!IsClientConnected(client))
		return false;
	if (noBots)
		if (IsFakeClient(client))
			return false;
	if (IsClientSourceTV(client))
		return false;
	return true;
}
-Version 1.0.3
Fix crash & error logs 
credits to mcpan313
*/

#include <sourcemod>
#include <sdkhooks>
#include <addicted>
#pragma newdecls required
#pragma semicolon 1
#define PLUGIN_VERSION "1.0.4"


Handle g_Cvar_HePower = INVALID_HANDLE;
Handle g_Cvar_HeRadius = INVALID_HANDLE;
Handle g_Cvar_HePowerVIP = INVALID_HANDLE;
Handle g_Cvar_HeRadiusVIP = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "Increase Nade Damage",
	author = "AUSTINBOTS! - SavSin",
	description = "Increase HeGrenade DMG & Radius",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

public void OnPluginStart()
{
	CreateConVar("ind_version", PLUGIN_VERSION, "Version of increased nade damage", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_Cvar_HePower = CreateConVar("sm_hePower", "1.3", "Power of HE nades. <Default: 1.3>");
	g_Cvar_HeRadius = CreateConVar("sm_heRadius", "2.5", "Radius of the nade.  <Default: 2.5>");
	g_Cvar_HePowerVIP = CreateConVar("sm_hePowerVIP", "1.6", "Power of HE nades for players with flag b. <Default: 1.3>");
	g_Cvar_HeRadiusVIP = CreateConVar("sm_heRadiusVIP", "3.0", "Radius of the nade for Players with flag b.  <Default: 2.5>");
	
}

public void OnEntityCreated(int iEnt, const char []szClassname)
{
	if(StrEqual(szClassname, "hegrenade_projectile"))
	{
		SDKHook(iEnt, SDKHook_SpawnPost, OnGrenadeSpawn);
	}
}

public void OnGrenadeSpawn(int iGrenade)
{
	CreateTimer(0.01, ChangeGrenadeDamage, EntIndexToEntRef(iGrenade), TIMER_FLAG_NO_MAPCHANGE);
}

public Action ChangeGrenadeDamage(Handle hTimer, any ref)
{
	int iEnt = EntRefToEntIndex(ref);
	int client;
	if(GetUserFlagBits(client) & ADMFLAG_RESERVATION || IsValidClient(client) || IsValidEdict(iEnt) || IsPlayerAlive(client))
	{
		float flGrenadePowerVIP = GetEntPropFloat(iEnt, Prop_Send, "m_flDamage");
		float flGrenadeRadiusVIP = GetEntPropFloat(iEnt, Prop_Send, "m_DmgRadius");

		SetEntPropFloat(iEnt, Prop_Send, "m_flDamage", (flGrenadePowerVIP*GetConVarFloat(g_Cvar_HePowerVIP)));
		SetEntPropFloat(iEnt, Prop_Send, "m_DmgRadius", (flGrenadeRadiusVIP*GetConVarFloat(g_Cvar_HeRadiusVIP)));
		return Plugin_Handled;
	}
	
	
	// Lets just add a check for root players aswell?
	if(GetUserFlagBits(client) & ADMFLAG_ROOT || IsValidClient(client) || IsValidEdict(iEnt) || IsPlayerAlive(client))
	{
		float flGrenadePowerVIP = GetEntPropFloat(iEnt, Prop_Send, "m_flDamage");
		float flGrenadeRadiusVIP = GetEntPropFloat(iEnt, Prop_Send, "m_DmgRadius");

		SetEntPropFloat(iEnt, Prop_Send, "m_flDamage", (flGrenadePowerVIP*GetConVarFloat(g_Cvar_HePowerVIP)));
		SetEntPropFloat(iEnt, Prop_Send, "m_DmgRadius", (flGrenadeRadiusVIP*GetConVarFloat(g_Cvar_HeRadiusVIP)));
		return Plugin_Handled;
	}
	
	else
	if (IsValidEdict(iEnt) || IsValidClient(client) || IsValidEdict(iEnt) || IsPlayerAlive(client))
	{
		float flGrenadePower = GetEntPropFloat(iEnt, Prop_Send, "m_flDamage");
		float flGrenadeRadius = GetEntPropFloat(iEnt, Prop_Send, "m_DmgRadius");

		SetEntPropFloat(iEnt, Prop_Send, "m_flDamage", (flGrenadePower*GetConVarFloat(g_Cvar_HePower)));
		SetEntPropFloat(iEnt, Prop_Send, "m_DmgRadius", (flGrenadeRadius*GetConVarFloat(g_Cvar_HeRadius)));
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

