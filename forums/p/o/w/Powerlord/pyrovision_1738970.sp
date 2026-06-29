#include <sourcemod>
#include <tf2items>

#define PYROVISION_ATTRIBUTE 406

#define VERSION "1.0"
#define DEBUG

new Handle:cvar_Enabled = INVALID_HANDLE;

new Handle:g_PyrovisionAttributes = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Pyrovision",
	author = "Powerlord",
	description = "Attempt to give players Pyrovision",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=188646"
}

public OnPluginStart()
{
	CreateConVar("pyrovision_version", VERSION, "PyroVision Version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	cvar_Enabled = CreateConVar("pyrovision_enabled", "1", "Enable Pyrovision for all players?", FCVAR_NONE, true, 0.0, true, 1.0);
	
	g_PyrovisionAttributes = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES | PRESERVE_ATTRIBUTES);
	TF2Items_SetAttribute(g_PyrovisionAttributes, 0, PYROVISION_ATTRIBUTE, 1.0);
	TF2Items_SetNumAttributes(g_PyrovisionAttributes, 1);
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], itemDefinitionIndex, &Handle:hItem)
{
	if (GetConVarBool(cvar_Enabled))
	{
		hItem = CloneHandle(g_PyrovisionAttributes);
		#if defined DEBUG
		LogMessage("Adding Pyrovision to %N's %s", client, classname);
		#endif
		return Plugin_Changed;
	}
	#if defined DEBUG
	else
	{
		LogMessage("Plugin is currently disabled by cvar.");
	}
	#endif
	
	return Plugin_Continue;
}

