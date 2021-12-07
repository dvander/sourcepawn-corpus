#include <sourcemod>
#include <cstrike> 
#include <sdktools>

#pragma semicolon 1

#define MAX_WEAPONS		39

new String:sWeaponName[32];

public Plugin:myinfo = {
	name = "Give Weapon",
	author = "Kiske",
	description = "Give a weapon to a player from a command",
	version = "1.0.1",
	url = "http://www.sourcemod.net/"
};

new const String:g_weapons[MAX_WEAPONS][] = {
	"weapon_ak47", "weapon_aug", "weapon_awp", "weapon_bizon", "weapon_cz75a", "weapon_deagle", "weapon_decoy", "weapon_elite", "weapon_famas", "weapon_fiveseven", "weapon_flashbang",
	"weapon_g3sg1", "weapon_galilar", "weapon_glock", "weapon_hegrenade", "weapon_hkp2000", "weapon_incgrenade", "weapon_m249", "weapon_m4a1",
	"weapon_m4a1_silencer", "weapon_mac10", "weapon_mag7", "weapon_molotov", "weapon_mp7", "weapon_mp9", "weapon_negev", "weapon_nova", "weapon_p250", "weapon_p90",
	"weapon_sawedoff", "weapon_scar20", "weapon_sg556", "weapon_smokegrenade", "weapon_ssg08", "weapon_taser", "weapon_tec9", "weapon_ump45", "weapon_usp_silencer",
	"weapon_xm1014"
};

public OnPluginStart()
{
	RegAdminCmd("sm_weapon", smWeapon, ADMFLAG_BAN, "- <target> <weaponname>");
	RegAdminCmd("sm_weapon_all", smWeapon_all, ADMFLAG_BAN, "<weaponname>");
	RegAdminCmd("sm_weapon_t", smWeapon_t, ADMFLAG_BAN, "<weaponname>");
	RegAdminCmd("sm_weapon_ct", smWeapon_ct, ADMFLAG_BAN, "<weaponname>");
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
	if(IsFakeClient(iTarget))
	{
		ReplyToCommand(id, "[SM] Bot isn't support");
	}	
	weapon_choose(iTarget);
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

public Action:smWeapon_all(id, args)
{
	if(args < 1)
	{
		ReplyToCommand(id, "[SM] Usage: sm_weapon_all <weaponname>");
		return Plugin_Handled;
	}
	
	decl String:sArg[256];
	decl String:sWeaponNameTemp[32];

	GetCmdArgString(sArg, sizeof(sArg));
	ReplaceString(sArg, sizeof(sArg), "sm_weapon_all", "");
	ReplaceString(sArg, sizeof(sArg), " ", "");
	strcopy(sWeaponName, sizeof(sWeaponName), sArg);
	
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
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
		{
			return Plugin_Handled;
		}
		if (!IsPlayerAlive(client))
		{
			return Plugin_Handled;
		}
		new iTarget = client;
		weapon_choose(iTarget);		
	}
	return Plugin_Handled;
}

public Action:smWeapon_t(id, args)
{
	if(args < 1)
	{
		ReplyToCommand(id, "[SM] Usage: sm_weapon_t <weaponname>");
		return Plugin_Handled;
	}
	
	decl String:sArg[256];
	decl String:sWeaponNameTemp[32];

	GetCmdArgString(sArg, sizeof(sArg));
	ReplaceString(sArg, sizeof(sArg), "sm_weapon_t", "");
	ReplaceString(sArg, sizeof(sArg), " ", "");
	strcopy(sWeaponName, sizeof(sWeaponName), sArg);
	
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
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
		{
			return Plugin_Handled;
		}
		if (!IsPlayerAlive(client))
		{
			return Plugin_Handled;
		}
		new iTeam = GetClientTeam(client);
		new iTarget = client;
		if(iTeam == CS_TEAM_T)
		{
			weapon_choose(iTarget);
		}
	}
	return Plugin_Handled;
}

public Action:smWeapon_ct(id, args)
{
	if(args < 1)
	{
		ReplyToCommand(id, "[SM] Usage: sm_weapon_ct <weaponname>");
		return Plugin_Handled;
	}
	
	decl String:sArg[256];
	decl String:sWeaponNameTemp[32];

	GetCmdArgString(sArg, sizeof(sArg));
	ReplaceString(sArg, sizeof(sArg), "sm_weapon_ct", "");
	ReplaceString(sArg, sizeof(sArg), " ", "");
	strcopy(sWeaponName, sizeof(sWeaponName), sArg);	
	
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
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
		{
			return Plugin_Handled;
		}
		if (!IsPlayerAlive(client))
		{
			return Plugin_Handled;
		}
		new iTeam = GetClientTeam(client);
		new iTarget = client;
		if(iTeam == CS_TEAM_CT)
		{
			weapon_choose(iTarget);
		}
	}
	return Plugin_Handled;
}

weapon_choose(iTarget)
{
	if(iTarget != -1 && !IsFakeClient(iTarget))
	{		
		if (StrEqual(sWeaponName, "weapon_hegrenade", false) || StrEqual(sWeaponName, "weapon_molotov", false) || StrEqual(sWeaponName, "weapon_smokegrenade", false) || StrEqual(sWeaponName, "weapon_flashbang", false) || StrEqual(sWeaponName, "weapon_decoy", false))
		{
			GivePlayerItem(iTarget, sWeaponName);
		}		
		else
		{
			new iItem = GivePlayerItem(iTarget, sWeaponName);
			EquipPlayerWeapon(iTarget, iItem);			
		}
	}
}