#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.2"

public Plugin:myinfo = {
	name = "tf_weapon_criticals 0 simulator",
	author = "FlaminSarge",
	description = "Simulates tf_weapon_criticals 0 while still keeping the CalcIsAttackCritical forward",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net",
};

new Handle:hCvarEnabled;
new bool:bEnabled;

public OnPluginStart()
{
	CreateConVar("sm_tf_wep_crit_ver", PLUGIN_VERSION, "tf_weapon_criticals 0 simulator version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_PLUGIN);
	hCvarEnabled = CreateConVar("sm_tf_weapon_criticals", "0", "tf_weapon_criticals, but fixed. Keep tf_weapon_criticals 1 when using this plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	bEnabled = GetConVarBool(hCvarEnabled);
	HookConVarChange(hCvarEnabled, cvarChange_Enabled);
	HookConVarChange(FindConVar("sv_tags"), cvarChange_Tags);
}
stock TagsCheck(const String:tag[], bool:remove = false)	//DarthNinja
{
	new Handle:hTags = FindConVar("sv_tags");
	decl String:tags[255];
	GetConVarString(hTags, tags, sizeof(tags));

	if (StrContains(tags, tag, false) == -1 && !remove)
	{
		decl String:newTags[255];
		Format(newTags, sizeof(newTags), "%s,%s", tags, tag);
		ReplaceString(newTags, sizeof(newTags), ",,", ",", false);
		SetConVarString(hTags, newTags);
		GetConVarString(hTags, tags, sizeof(tags));
	}
	else if (StrContains(tags, tag, false) > -1 && remove)
	{
		ReplaceString(tags, sizeof(tags), tag, "", false);
		ReplaceString(tags, sizeof(tags), ",,", ",", false);
		SetConVarString(hTags, tags);
	}
//	CloseHandle(hTags);
}
public OnConfigsExecuted()
{
	bEnabled = GetConVarBool(hCvarEnabled);
	if (!bEnabled) TagsCheck("nocrits");
	else if (GetConVarBool(FindConVar("tf_weapon_criticals"))) TagsCheck("nocrits", true);
}
public cvarChange_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	OnConfigsExecuted();
}
public cvarChange_Tags(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!bEnabled) TagsCheck("nocrits");
	else if (GetConVarBool(FindConVar("tf_weapon_criticals"))) TagsCheck("nocrits", true);
}
stock TF2_IsPlayerCritBuffed(client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged)
			|| TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy)
			|| TF2_IsPlayerInCondition(client, TFCond:34)
			|| TF2_IsPlayerInCondition(client, TFCond:35)
			|| TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood)
			|| TF2_IsPlayerInCondition(client, TFCond_CritOnWin)
			|| TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture)
			|| TF2_IsPlayerInCondition(client, TFCond_CritOnKill)
			|| TF2_IsPlayerInCondition(client, TFCond:44)
			);
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (GetConVarBool(hCvarEnabled)) return Plugin_Continue;
	if (client <= 0 || client > MaxClients) return Plugin_Continue;
	if (TF2_IsPlayerCritBuffed(client)) return Plugin_Continue;
	if (TF2_GetPlayerClass(client) == TFClass_DemoMan && GetEntPropFloat(client, Prop_Send, "m_flChargeMeter") <= 5 && weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Melee)) return Plugin_Continue;
	if (StrContains(weaponname, "robot_arm", false) != -1) return Plugin_Continue;
	if (StrContains(weaponname, "knife", false) != -1) return Plugin_Continue;
	if (StrContains(weaponname, "sniperrifle", false) != -1) return Plugin_Continue;
	if (StrContains(weaponname, "compound_bow", false) != -1) return Plugin_Continue;
	result = false;
	return Plugin_Changed;
}