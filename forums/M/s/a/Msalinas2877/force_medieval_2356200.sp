#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

public Plugin:myinfo = 
{
    name = "Force Medieval Mode",
    author = "Msalinas2877",
    version = "1.1"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_force_medieval", Command_Force_Medieval, ADMFLAG_KICK);
}

public OnMapStart()
{
	PrecacheSound("*/ambient_mp3/medieval_dooropen.mp3");
	PrecacheSound("*/ambient_mp3/medieval_doorclose.mp3");
}

public Action Command_Force_Medieval(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_force_medieval <Duration>");
		return Plugin_Handled;
	}
	
	GameRules_SetProp("m_bPlayingMedieval", 1);
	
	PrintHintTextToAll("Admin Forced Medieval Mode");
	EmitSoundToAll("*/ambient_mp3/medieval_dooropen.mp3");
	
	new i = 1; i < GetMaxClients();
	TF2_RemoveWeaponSlot(i, TFWeaponSlot_Primary);
	TF2_RemoveWeaponSlot(i, TFWeaponSlot_Secondary);
	
	new melee = GetPlayerWeaponSlot(i, TFWeaponSlot_Melee);
	SetEntPropEnt(i, Prop_Send, "m_hActiveWeapon", melee);  
	
	decl String:Time[64];
	
	GetCmdArg(1, Time, sizeof(Time));

	CreateTimer(StringToFloat(Time), End);
	
	return Plugin_Continue;
}

public Action:End(Handle:timer)
{
	PrintHintTextToAll("Medieval Mode Has Ended");
	EmitSoundToAll("*/ambient_mp3/medieval_doorclose.mp3");

	GameRules_SetProp("m_bPlayingMedieval", 0);
	
	return Plugin_Handled;
}