#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf2itemsinfo>
#include <tf2attributes>

public Plugin:myinfo =
{
	name = "[TF2] Civilian",
	author = "Bitl",
	description = "Sets your class to civilian",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_civilian", Command_Civilian);
	HookEvent("player_death", event_PlayerDeath, EventHookMode_Pre);
}

public Action:Command_Civilian(client, args)
{
	if(IsPlayerAlive(client))
	{
		TF2_SetPlayerClass(client, TFClass_Scout);
		TF2Attrib_SetByName(client, "max health additive penalty", -75.0);
		TF2Attrib_SetByName(client, "no double jump", 1.0);
		SetEntityHealth(client, 50);
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
		for( new iSlot = 0; iSlot < _:TF2ItemSlot; iSlot++ )
			TF2_RemoveWeaponSlot( client, iSlot );
	}
	
	return Plugin_Handled;
}

public event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");
	TF2Attrib_RemoveByName(client, "max health additive penalty");
	TF2Attrib_RemoveByName(client, "no double jump");
}

