/*
* CREDITS:
* berni - SMLIB & Stocks.
* Tylerst & Oshizu - Inspiration.
* floube - Helping optimize code.
* Everyone else thats helped me in the scripting forums.
* 
* CHANGELOG:
* 0.1 - 
* 		First Release. (Could be unstable, ineffecient etc)
* 0.2 - 
* 		Register values on PluginStart also to prevent false console spam.
* 
* NOTE: 0.1 - 0.4
* 		Unstable and broken, Don't use.
* 0.5 - 
* 		Added Ent spawn blocking.
* 0.6 - 
* 		Reworked Logic once again, This time I have tested it quite throughly before release.
* 0.7 - 
* 		Lots of code optimization with thanks to floube.
* 		Improved code logic even more.
* 0.8 - 
* 		Optimized plugin even more & Fixed loop timeout issue.
* 0.9 - 
* 		More optimizations & more agressive code.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.9.1"

public Plugin:myinfo = 
{
	name = "Edict Overflow Fix",
	author = "xCoderx",
	version = PLUGIN_VERSION,
	url = "www.bravegaming.net"
};

new Handle:g_hEntLimit = INVALID_HANDLE;
new String:g_sClassName[64];
new g_iEntityLimit;

public OnPluginStart()
{
	CreateConVar("eof_version", PLUGIN_VERSION, "EOF", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	g_hEntLimit 		= CreateConVar("eof_entlimit", "768", "Max Edicts of an Entity at any time.");
	g_iEntityLimit		= GetConVarInt(g_hEntLimit);
	
	HookConVarChange(g_hEntLimit, CvarChange_EntLimit);
}

public CvarChange_EntLimit(Handle:Cvar, const String:strOldValue[], const String:strNewValue[])
{
	g_iEntityLimit = StringToInt(strNewValue);
}

public OnEntityCreated(entity) 
{
	if(Entity_GetCount(entity) > g_iEntityLimit || entity >= 2038)
	{
		SDKHook(entity, SDKHook_Spawn, EntHook);
	}
}

public Action:EntHook(entity)
{
	HandleEdict(entity);
}

stock HandleEdict(entity)
{
	new ent = -1;
	GetEntityClassname(entity, g_sClassName, sizeof(g_sClassName));
	
	while ((FindEntityByClassname(ent, g_sClassName)) != INVALID_ENT_REFERENCE)
	{
		if(! IsValidEntity(ent) || ! IsValidEdict(ent))
			continue;
		
		if(Entity_GetCount(entity) > g_iEntityLimit || entity >= 2038)
		{
			if(ent != entity) 
			{
				RemoveEdict(ent);
			}
		}
		else break;
	}
}

stock Entity_GetCount(entity)
{
	new ent = -1;
	new count = 0;
	
	GetEntityClassname(entity, g_sClassName, sizeof(g_sClassName));
	
	while ((FindEntityByClassname(ent, g_sClassName)) != INVALID_ENT_REFERENCE)
		count++;
	
	return count;
}