#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
public Plugin:myinfo =
{
	name = "[TF2] MvM Visible Max Players",
	author = "FlaminSarge",
	description = "Spams console about 6-player MvM, but sets sv_visiblemaxplayers to other values",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

new Handle:cvarCount;
new Handle:sv_visiblemaxplayers;
new count = -1;
public OnPluginStart()
{
	CreateConVar("mvm_vismaxp_version", PLUGIN_VERSION, "[TF2] MvM Visible Max Players", FCVAR_PLUGIN, true, -1.0, true, 10.0);
	cvarCount = CreateConVar("mvm_visiblemaxplayers", "-1", "Set above 0 to set sv_visiblemaxplayers for MvM", FCVAR_PLUGIN, true, -1.0, true, 10.0);
	count = GetConVarInt(cvarCount);
	HookConVarChange(cvarCount, cvarChange_cvarCount);
	sv_visiblemaxplayers = FindConVar("sv_visiblemaxplayers");
	HookConVarChange(sv_visiblemaxplayers, cvarChange_sv_visiblemaxplayers);
}
public OnMapStart()
{
	IsMvM(true);
}
public cvarChange_cvarCount(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (IsMvM())
	{
		count = GetConVarInt(convar);
		if (sv_visiblemaxplayers != INVALID_HANDLE) SetConVarInt(sv_visiblemaxplayers, count > 0 ? count : -1);
	}
}
public cvarChange_sv_visiblemaxplayers(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (IsMvM())
	{
		if (count > 0 && GetConVarInt(convar) != count) SetConVarInt(convar, count);
	}
}
stock bool:IsMvM(bool:forceRecalc = false)
{
	static bool:found = false;
	static bool:ismvm = false;
	if (forceRecalc)
	{
		found = false;
		ismvm = false;
	}
	if (!found)
	{
		new i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}
