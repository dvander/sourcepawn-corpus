#include <sourcemod>
#include <sdkhooks>
#include <sdktools> 
#include <tf2attributes>


public OnPluginStart()
{

	HookEvent("post_inventory_application", Event_InvApp, EventHookMode_Post);
	
}


public Action Timer_ReloadAttrib(Handle timer, int client)
{
	new weapon[6];
	weapon[0] = GetPlayerWeaponSlot(client, 0);
	weapon[1] = GetPlayerWeaponSlot(client, 1);
	weapon[2] = GetPlayerWeaponSlot(client, 2);
	weapon[3] = GetPlayerWeaponSlot(client, 3);
	weapon[4] = GetPlayerWeaponSlot(client, 4);
	weapon[5] = GetPlayerWeaponSlot(client, 5);
	if (IsValidEntity(weapon[5])) {
		TF2Attrib_SetByName(weapon[5], "reload time increased hidden", 1.0); 
	}
	return Plugin_Continue;
}

public void Event_InvApp(Event event, const char[] name, bool dontBroadcast)
{

	int client = GetClientOfUserId(event.GetInt("userid"));
	CreateTimer(0.2, Timer_ReloadAttrib, client); 
	
}