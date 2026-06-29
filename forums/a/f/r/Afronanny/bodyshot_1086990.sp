#include <sourcemod>

new Handle:hCvarMultiplier;

new Float:fMultiplier = 0.5;

public Plugin:myinfo = 
{
	name = "Bodyshot Damage Multiplier",
	author = "Afronanny",
	description = "Reduce/Multiply damage done by Sniper Rifle bodyshots",
	version = "0.1",
	url = "http://teamfail.net/"
}

public OnPluginStart()
{
	hCvarMultiplier = CreateConVar("sm_bodyshot_multiplier", ".5", "The lower the setting, the less damage will be done. 0 to disable damage.", FCVAR_PLUGIN);
	HookConVarChange(hCvarMultiplier, ConVarChanged_Multiplier);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new iWeaponId;
	new bool:bIsCrit;
	new iDamageDone;
	
	iWeaponId = GetEventInt(event, "weaponid");
	bIsCrit = GetEventBool(event, "crit");
	iDamageDone = GetEventInt(event, "damageamount");
	
	if (iWeaponId == 17 && !bIsCrit)
	{
		SetEventFloat(event, "damageamount", iDamageDone * fMultiplier);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public ConVarChanged_Multiplier(Handle:convar, const String:oldValue[], const String:newValue[])
{
	fMultiplier = StringToFloat(newValue);
	
	//Ensure the damage multiplier is not below zero
	if (fMultiplier < 0)
		fMultiplier = -fMultiplier;
}