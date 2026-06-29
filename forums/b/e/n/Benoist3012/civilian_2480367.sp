#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>

public Plugin myinfo =
{
	name = "[TF2] Civilian",
	author = "Bitl",
	description = "Sets your class to civilian",
	version = "1.0b",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_civilian", Command_Civilian);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public Action Command_Civilian(int iClient, int iArgs)
{
	if (IsPlayerAlive(iClient))
	{
		TF2_SetPlayerClass(iClient, TFClass_Scout);
		TF2Attrib_SetByName(iClient, "max health additive penalty", -75.0);
		TF2Attrib_SetByName(iClient, "no double jump", 1.0);
		SetEntityHealth(iClient, 50);
		SetVariantInt(1);
		AcceptEntityInput(iClient, "SetForcedTauntCam");
		for( int iSlot = 0; iSlot <= 5; iSlot++ )
			TF2_RemoveWeaponSlot( iClient, iSlot );
	}
	return Plugin_Handled;
}

public Action Event_PlayerDeath(Event event, const String:name[], bool:dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	SetVariantInt(0);
	AcceptEntityInput(iClient, "SetForcedTauntCam");
	TF2Attrib_RemoveByName(iClient, "max health additive penalty");
	TF2Attrib_RemoveByName(iClient, "no double jump");
}

