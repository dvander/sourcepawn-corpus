#include <sourcemod>
#include <tf2items>

#define PYROVISION_ATTRIBUTE 275

#define VERSION "1.0"

new Handle:cvar_Enabled = INVALID_HANDLE;

new Handle:g_PyrovisionAttributes = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "No Fall Damage",
	author = "Powerlord + Dr. McKay",
	description = "Attempt to prevent fall damage",
	version = VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	cvar_Enabled = CreateConVar("nofalldamage_enabled", "1", "Enable no fall damage for all players?", FCVAR_NONE, true, 0.0, true, 1.0);
	
	g_PyrovisionAttributes = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES | PRESERVE_ATTRIBUTES);
	TF2Items_SetAttribute(g_PyrovisionAttributes, 0, PYROVISION_ATTRIBUTE, 1.0);
	TF2Items_SetNumAttributes(g_PyrovisionAttributes, 1);
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], itemDefinitionIndex, &Handle:hItem)
{
	if (GetConVarBool(cvar_Enabled))
	{
		hItem = CloneHandle(g_PyrovisionAttributes);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

