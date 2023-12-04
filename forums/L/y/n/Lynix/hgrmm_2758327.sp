#include <sourcemod>
#include <sdktools>
#include <hgr>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Hook Grab Rope Min/Max Distance",
	author = "Sheepdude",
	description = "Sets minimum and maximum distance where hook, grab, and rope are allowed",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

new Handle:h_cvarHookMin;
new Handle:h_cvarHookMax;
new Handle:h_cvarGrabMin;
new Handle:h_cvarGrabMax;
new Handle:h_cvarRopeMin;
new Handle:h_cvarRopeMax;
new Handle:h_cvarHookPush;
new Handle:h_cvarPushHook;

new Float:g_cvarMin[3];
new Float:g_cvarMax[3];
new bool:g_cvarHookPush;
new bool:g_cvarPushHook;

public OnPluginStart()
{
	// Public convar
	CreateConVar("sm_hgrmm_version", PLUGIN_VERSION, "[HGR] Plugin version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY);
	
	// Convars
	h_cvarHookMin  = CreateConVar("sm_hgrmm_hook_min", "0.0", "Minimum allowed hook distance", FCVAR_NOTIFY, true, 0.0);
	h_cvarHookMax  = CreateConVar("sm_hgrmm_hook_max", "0.0", "Maximum allowed hook distance", FCVAR_NOTIFY, true, 0.0);
	h_cvarGrabMin  = CreateConVar("sm_hgrmm_grab_min", "0.0", "Minimum allowed grab distance", FCVAR_NOTIFY, true, 0.0);
	h_cvarGrabMax  = CreateConVar("sm_hgrmm_grab_max", "0.0", "Maximum allowed grab distance", FCVAR_NOTIFY, true, 0.0);
	h_cvarRopeMin  = CreateConVar("sm_hgrmm_rope_min", "0.0", "Minimum allowed rope distance", FCVAR_NOTIFY, true, 0.0);
	h_cvarRopeMax  = CreateConVar("sm_hgrmm_rope_max", "0.0", "Maximum allowed rope distance", FCVAR_NOTIFY, true, 0.0);
	h_cvarHookPush = CreateConVar("sm_hgrmm_hookpush", "0", "Does +hook use +push distance", 0, true, 0.0, true, 1.0);
	h_cvarPushHook = CreateConVar("sm_hgrmm_pushhook", "1", "Does +push use +hook distance", 0, true, 0.0, true, 1.0);
	
	// Convar changes
	HookConVarChange(h_cvarHookMin, ConvarChanged);
	HookConVarChange(h_cvarHookMax, ConvarChanged);
	HookConVarChange(h_cvarGrabMin, ConvarChanged);
	HookConVarChange(h_cvarGrabMax, ConvarChanged);
	HookConVarChange(h_cvarRopeMin, ConvarChanged);
	HookConVarChange(h_cvarRopeMax, ConvarChanged);
	HookConVarChange(h_cvarHookPush, ConvarChanged);
	HookConVarChange(h_cvarPushHook, ConvarChanged);
	
	// Auto-generate configuration file
	AutoExecConfig(true, "hgrmm");
	
	// Assign variables
	UpdateAllConvars();
}

/********
 *Events*
*********/

public Action:HGR_OnClientHook(client)
{
	new Float:distance;
	if(!HGR_IsPushing(client))
	{
		if(g_cvarHookPush)
			distance = HGR_GetPushDistance(client);
		else
			distance = HGR_GetHookDistance(client);
	}
	else
	{
		if(g_cvarPushHook)
			distance = HGR_GetHookDistance(client);
		else
			distance = HGR_GetPushDistance(client);
	}
	if(g_cvarMin[0] < g_cvarMax[0] && (distance < g_cvarMin[0] || distance > g_cvarMax[0]))
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action:HGR_OnClientGrab(client)
{
	new Float:distance = HGR_GetGrabDistance(client);
	if(g_cvarMin[1] < g_cvarMax[1] && (distance < g_cvarMin[1] || distance > g_cvarMax[1]))
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action:HGR_OnClientRope(client)
{
	new Float:distance = HGR_GetRopeDistance(client);
	if(g_cvarMin[2] < g_cvarMax[2] && (distance < g_cvarMin[2] || distance > g_cvarMax[2]))
		return Plugin_Handled;
	return Plugin_Continue;
}

/*********
 *Convars*
**********/

public ConvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == h_cvarHookMin)
		g_cvarMin[0]   = GetConVarFloat(h_cvarHookMin);
	else if(cvar == h_cvarHookMax)
		g_cvarMax[0]   = GetConVarFloat(h_cvarHookMax);
	else if(cvar == h_cvarGrabMin)
		g_cvarMin[1]   = GetConVarFloat(h_cvarGrabMin);
	else if(cvar == h_cvarGrabMax)
		g_cvarMax[1]   = GetConVarFloat(h_cvarGrabMax);
	else if(cvar == h_cvarRopeMin)
		g_cvarMin[2]   = GetConVarFloat(h_cvarRopeMin);
	else if(cvar == h_cvarRopeMax)
		g_cvarMax[2]   = GetConVarFloat(h_cvarRopeMax);
	else if(cvar == h_cvarHookPush)
		g_cvarHookPush = GetConVarBool(h_cvarHookPush);
	else if(cvar == h_cvarPushHook)
		g_cvarPushHook = GetConVarBool(h_cvarPushHook);
}

UpdateAllConvars()
{
	g_cvarMin[0]   = GetConVarFloat(h_cvarHookMin);
	g_cvarMax[0]   = GetConVarFloat(h_cvarHookMax);
	g_cvarMin[1]   = GetConVarFloat(h_cvarGrabMin);
	g_cvarMax[1]   = GetConVarFloat(h_cvarGrabMax);
	g_cvarMin[2]   = GetConVarFloat(h_cvarRopeMin);
	g_cvarMax[2]   = GetConVarFloat(h_cvarRopeMax);
	g_cvarHookPush = GetConVarBool(h_cvarHookPush);
	g_cvarPushHook = GetConVarBool(h_cvarPushHook);
}