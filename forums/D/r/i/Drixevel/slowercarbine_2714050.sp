#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2items>

ConVar convar_FireRate;

public Plugin myinfo = 
{
	name = "[TF2] Slower Carbine", 
	author = "Drixevel", 
	description = "Makes the Cleaner's Carbine fire slower.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	convar_FireRate = CreateConVar("sm_carbine_firerate", "1.25");
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int itemdef, Handle& item)
{
	//The Cleaner's Carbine
	if (itemdef == 751)
	{
		item = TF2Items_CreateItem(PRESERVE_ATTRIBUTES | OVERRIDE_ATTRIBUTES);
		TF2Items_SetNumAttributes(item, 5);
		TF2Items_SetAttribute(item, 0, 5, convar_FireRate.FloatValue);
		TF2Items_SetAttribute(item, 1, 3, 0.80);
		TF2Items_SetAttribute(item, 2, 15, 0.0);
		TF2Items_SetAttribute(item, 3, 780, 1.0);
		TF2Items_SetAttribute(item, 4, 779, 8.0);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}