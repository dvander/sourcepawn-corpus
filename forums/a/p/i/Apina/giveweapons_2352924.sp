#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define MAX_WEAPONS		38

public Plugin:myinfo = {
	name = "Give Weapon",
	author = "Kiske",
	description = "Give a weapon to a player from a command",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

new const String:g_weapons[MAX_WEAPONS][] = {
	"weapon_ak47", "weapon_aug", "weapon_bizon", "weapon_deagle", "weapon_decoy", "weapon_elite", "weapon_famas", "weapon_fiveseven", "weapon_flashbang",
	"weapon_g3sg1", "weapon_galilar", "weapon_glock", "weapon_hegrenade", "weapon_hkp2000", "weapon_incgrenade", "weapon_knife", "weapon_m249", "weapon_m4a1",
	"weapon_mac10", "weapon_mag7", "weapon_molotov", "weapon_mp7", "weapon_mp9", "weapon_negev", "weapon_nova", "weapon_p250", "weapon_p90", "weapon_sawedoff",
	"weapon_scar20", "weapon_sg556", "weapon_smokegrenade", "weapon_ssg08", "weapon_taser", "weapon_tec9", "weapon_ump45", "weapon_xm1014", "weapon_awp", "weapon_m4a1_silencer"
};

public OnPluginStart()
{
	RegAdminCmd("sm_weapon", smWeapon, ADMFLAG_BAN, "- <target> <weaponname>");
	RegAdminCmd("sm_weaponlist", smWeaponList, ADMFLAG_BAN, "- list of the weapon names");
}

public Action:smWeapon(id, args)
{
	if(args < 2)
	{
		ReplyToCommand(id, "[SM] Usage: sm_weapon <name | #userid> <weaponname>");
		return Plugin_Handled;
	}
	
	decl String:sArg[256];
	decl String:sTempArg[32];
	decl String:sWeaponName[32];
	decl String:sWeaponNameTemp[32];
	decl iL;
	decl iNL;
	
	GetCmdArgString(sArg, sizeof(sArg));
	iL = BreakString(sArg, sTempArg, sizeof(sTempArg));
	
	if((iNL = BreakString(sArg[iL], sWeaponName, sizeof(sWeaponName))) != -1)
		iL += iNL;
	
	new i;
	new iValid = 0;
	
	if(StrContains(sWeaponName, "weapon_") == -1)
	{
		FormatEx(sWeaponNameTemp, 31, "weapon_");
		StrCat(sWeaponNameTemp, 31, sWeaponName);
		
		strcopy(sWeaponName, 31, sWeaponNameTemp);
	}
	
	for(i = 0; i < MAX_WEAPONS; ++i)
	{
		if(StrEqual(sWeaponName, g_weapons[i]))
		{
			iValid = 1;
			break;
		}
	}
	
	if(!iValid)
	{
		ReplyToCommand(id, "[SM] The weaponname (%s) isn't valid", sWeaponName);
		return Plugin_Handled;
	}
	
	decl String:sTargetName[MAX_TARGET_LENGTH];
	decl sTargetList[1];
	decl bool:bTN_IsML;
	
	new iTarget = -1;
	
	if(ProcessTargetString(sTempArg, id, sTargetList, 1, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_MULTI, sTargetName, sizeof(sTargetName), bTN_IsML) > 0)
		iTarget = sTargetList[0];
	
	if(iTarget != -1 && !IsFakeClient(iTarget))
		GivePlayerItem(iTarget, sWeaponName);
	
	return Plugin_Handled;
}

public Action:smWeaponList(id, args)
{
	new i;
	for(i = 0; i < MAX_WEAPONS; ++i)
		ReplyToCommand(id, "%s", g_weapons[i]);
	
	ReplyToCommand(id, "");
	ReplyToCommand(id, "* No need to put weapon_ in the <weaponname>");
	
	return Plugin_Handled;
}