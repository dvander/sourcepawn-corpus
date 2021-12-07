#pragma semicolon 1
#include <sourcemod>
#include <l4d2_stocks>

#define PLUGIN_VERSION "1.2"

public Plugin:myinfo = 
{
	name = "[L4D2] Laser Fix",
	author = "McFlurry",
	description = "Fixes them pesky laser sights for dual primaries",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
	HookEvent("player_use", Event_Use);
	AddCommandListener(Upgrade, "upgrade_add");
}

public Action:Event_Use(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new target = GetEventInt(event, "targetid");
	new String:class[100];
	GetEdictClassname(target, class, sizeof(class));
	if(StrEqual(class, "upgrade_laser_sight", false))
	{
		new slot2 = GetPlayerWeaponSlot(client, 1);	
		if(slot2 > MaxClients)
		{
			decl String:class2[64];
			GetEdictClassname(slot2, class2, sizeof(class2));
			if(StrContains(class2, "pistol", false) == -1) return;
			new bits = L4D2_GetWeaponUpgradeBits(slot2);
			if((bits & L4D2_UPGRADEFLAG_LASER) == 0)
			{
				L4D2_SetWeaponUpgradeBits(slot2, bits|L4D2_UPGRADEFLAG_LASER);
			}
		}
	}
}	

public Action:Upgrade(client, const String:command[], argc)
{
	if(argc > 1) return;
	new String:arg[50];
	GetCmdArg(1, arg, sizeof(arg));
	if(StrEqual(arg, "LASER_SIGHT", false))
	{
		new slot2 = GetPlayerWeaponSlot(client, 1);	
		if(slot2 > MaxClients)
		{
			decl String:class2[64];
			GetEdictClassname(slot2, class2, sizeof(class2));
			if(StrContains(class2, "pistol", false) == -1) return;
			new bits = L4D2_GetWeaponUpgradeBits(slot2);
			if((bits & L4D2_UPGRADEFLAG_LASER) == 0)
			{
				L4D2_SetWeaponUpgradeBits(slot2, bits|L4D2_UPGRADEFLAG_LASER);
			}	
		}
	}
}	