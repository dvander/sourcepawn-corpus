/* Plugin Template generated by Pawn Studio */

#include <sourcemod>

new Handle:hEasyHeadDamage = INVALID_HANDLE;
new Handle:hExpertHeadDamage = INVALID_HANDLE;
new Handle:hHardHeadDamage = INVALID_HANDLE;
new Handle:hNormalHeadDamage = INVALID_HANDLE;

new Handle:cEnableHeadshotsOnly = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "L4D HeadShots Only",
	author = "Crimson",
	description = "http://www.sourcemod.net",
	version = "1.0.0",
	url = "http://www.brutalservers.net"
}

public OnPluginStart()
{
	hEasyHeadDamage = FindConVar("z_non_head_damage_factor_easy");
	hExpertHeadDamage = FindConVar("z_non_head_damage_factor_expert");
	hHardHeadDamage = FindConVar("z_non_head_damage_factor_hard");
	hNormalHeadDamage = FindConVar("z_non_head_damage_factor_normal");

	cEnableHeadshotsOnly = CreateConVar("sm_headshots_only", "0", "Enable/Disable Headshots on Infected Only", _, true, 0.0, true, 1.0);
}

public OnConfigsExecuted()
{
	HookConVarChange(cEnableHeadshotsOnly, ConVarChange_HeadshotsOnly);
}

public ConVarChange_HeadshotsOnly(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StrEqual(newValue, "1"))
	{
		SetConVarInt(hEasyHeadDamage, 0);
		SetConVarInt(hExpertHeadDamage, 0);
		SetConVarInt(hHardHeadDamage, 0);
		SetConVarInt(hNormalHeadDamage, 0);
	}
	else if(StrEqual(newValue, "0"))
	{
		SetConVarInt(hEasyHeadDamage, 1);
		SetConVarInt(hExpertHeadDamage, 1);
		SetConVarInt(hHardHeadDamage, 1);
		SetConVarInt(hNormalHeadDamage, 1);
	}
}