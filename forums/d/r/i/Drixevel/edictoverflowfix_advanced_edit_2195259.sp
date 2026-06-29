/*
* CREDITS:
* 
* berni - SMLIB & Stocks.
* Tylerst & Oshizu - Inspiration.
* Everyone else thats helped me in the scripting forums.
* 
* CHANGELOG:
* 0.1 - 
* 		First Release. (Could be unstable, ineffecient etc)
* 0.2 - 
* 		Register values on PluginStart also to prevent false console spam.
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.2 edited"

public Plugin:myinfo = 
{
	name = "Edict Overflow Fix Advanced",
	author = "xCoderx, Edits by Keith Warren (Jack of Designs)",
	version = PLUGIN_VERSION,
	url = "www.bravegaming.net"
}

new Handle:g_hStatus = INVALID_HANDLE;
new Handle:g_hEntLimit = INVALID_HANDLE;
new Handle:g_hEntLimitAction = INVALID_HANDLE;
new Handle:g_hEntCritical = INVALID_HANDLE;
new Handle:g_hEntCriticalAction = INVALID_HANDLE;

new Status;
new EntMax;
new EntAction;
new EntCritical;
new EntCriticalAction;

public OnPluginStart()
{
	CreateConVar("eof_version", PLUGIN_VERSION, "Edict Overflow Fix", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	g_hStatus = CreateConVar("eof_status", "1", "0 - Disable, 1 - Enable, 2 - Enable with Server Prints", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_hEntLimit = CreateConVar("eof_entlimit", "1024", "Max Edicts of an Entity at any time.");
	g_hEntLimitAction = CreateConVar("eof_entlimit_action", "1", "0 - Disable, 1 - Prevent further of that type, 2 - Clear all of that type., 3 - hard kills");
	g_hEntCritical = CreateConVar("eof_entcrtical", "2044", "Critical Edict Limit");
	g_hEntCriticalAction = CreateConVar("eof_entcrtical_action", "1", "0 - Disable, 1 - Prevent further of that type, 2 - Clear all of that type. 3 - Restart Map");
	
	HookConVarChange(g_hStatus, CvarChange_Status);
	HookConVarChange(g_hEntLimit, CvarChange_EntLimit);
	HookConVarChange(g_hEntLimitAction, CvarChange_EntAction);
	HookConVarChange(g_hEntCritical, CvarChange_EntCritical);
	HookConVarChange(g_hEntCriticalAction, CvarChange_EntCritical);
	
	Status = GetConVarInt(g_hStatus);
	EntMax = GetConVarInt(g_hEntLimit);
	EntAction = GetConVarInt(g_hEntLimitAction);
	EntCritical = GetConVarInt(g_hEntCritical);
	EntCriticalAction = GetConVarInt(g_hEntCriticalAction);
}

public OnConfigsExecuted()
{
	Status = GetConVarInt(g_hStatus);
	EntMax = GetConVarInt(g_hEntLimit);
	EntAction = GetConVarInt(g_hEntLimitAction);
	EntCritical = GetConVarInt(g_hEntCritical);
	EntCriticalAction = GetConVarInt(g_hEntCriticalAction);
}

/* ----- CONVAR HOOKS ----- */

public CvarChange_Status(Handle:Cvar, const String:strOldValue[], const String:strNewValue[])
	Status = StringToInt(strNewValue);

public CvarChange_EntLimit(Handle:Cvar, const String:strOldValue[], const String:strNewValue[])
	EntMax = StringToInt(strNewValue);

public CvarChange_EntAction(Handle:Cvar, const String:strOldValue[], const String:strNewValue[])
	EntAction = StringToInt(strNewValue);

public CvarChange_EntCritical(Handle:Cvar, const String:strOldValue[], const String:strNewValue[])
	EntCritical = StringToInt(strNewValue);

public CvarChange_EntCriticalAction(Handle:Cvar, const String:strOldValue[], const String:strNewValue[])
	EntCriticalAction = StringToInt(strNewValue);

/* ----- LOGIC ----- */

public OnEntityCreated(entity)
{
	if (Status <= 0) return;
	
	decl String:className[64];
	
	GetEntityClassname(entity, className, sizeof(className));
	
	if(EntAction > 0)
	{
		if (EntAction == 3)
		{
			SDKHook(entity, SDKHook_Spawn, Ent_Spawn);
			return;
		}
		
		if(Entity_GetCountByClassName(className) > EntMax && EntMax > 64 && ! Entity_IsPlayer(className))
		{
			PrintToServer2("[EOF] Entity %s is more has more than %d edicts!", className, EntMax);
		
			switch(EntAction)
			{
				case 1:
				{
					PrintToServer2("[EOF] Terminating %s", className);
					Entity_Terminator(className);
				}
			
				case 2: 
				{
					PrintToServer2("[EOF] Assassinating %s", className);
					Entity_KillAllByClassName(className);
				}
			}
		}
	}
	
	else
	{
		if(Entity_GetCountByClassName(className) > 1024)
		{
			PrintToServer2("[EOF] Entity %s is using more than 50% of available edicts.", className);
			PrintToServer2("[EOF] This is not good, Please consider setting eof_entlimit_action > 0");
		}
	}
	
	if(entity >= EntCritical)
	{
		PrintToServer("[EOF] Entity Level Critcal, Taking Action!");
		
		switch(EntCriticalAction)
		{
			case 0: 
			{
				PrintToServer2("[EOF] Praying To Gaben.");
				
				if(entity >= 2047)
				{
					PrintToChatAll("Houston, We've Got a Problem.");
				}
			}
			
			case 1: 
			{
				PrintToServer2("[EOF] Terminating %s", className);
				Entity_Terminator(className);
			}
			
			case 2: 
			{
				PrintToServer2("[EOF] Assassinating %s", className);
				Entity_KillAllByClassName(className);
			}
			
			case 3: 
			{
				new String:Map[64]
				GetCurrentMap(Map, sizeof(Map))
				PrintToServer2("[EOF] Restarting Map.");
				ForceChangeLevel(Map, "[EOF] Restarting Map.")
			}
		}
	}
}

public Action:Ent_Spawn(entity)
{
	while(entity >= 2044) return Plugin_Stop;
	return Plugin_Continue;
}

/* ----- STOCKS ----- */

stock Entity_Terminator(const String:className[])
{
	new entity = -1;
	entity = FindEntityByClassname(entity, className)
	
	if(IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
		
		if(IsValidEntity(entity)) // Not killed first time eh?
			RemoveEdict(entity) // Now your dead :)
	}
}

stock bool:Entity_IsPlayer(const String:className[])
{
	new entity = -1;
	entity = FindEntityByClassname(entity, className)
	
	if (entity < 1 || entity > MaxClients) {
		return false;
	}
	
	return true;
}

stock Entity_GetCountByClassName(const String:className[])
{
	new count=0;
	
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, className)) != INVALID_ENT_REFERENCE) {
		count++;
	}
	
	return count;
}

stock Entity_KillAllByClassName(const String:className[])
{
	new x = 0;
	
	new entity = INVALID_ENT_REFERENCE;
	while ((entity = FindEntityByClassname(entity, className)) != INVALID_ENT_REFERENCE && IsValidEntity(entity)) {
		AcceptEntityInput(entity, "kill");
		
		if(IsValidEntity(entity)) // Not killed first time eh?
			RemoveEdict(entity) // Now your dead :)
		
		x++;
	}
	
	return x;
}

PrintToServer2(const String:format[], any:...)
{
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), format, 2);
	PrintToServer(buffer);
}