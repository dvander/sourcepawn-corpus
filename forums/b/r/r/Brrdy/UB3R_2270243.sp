#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define MAX_WEAPONS		36

public Plugin:myinfo = {
	name = "UB3R Guns",
	author = "Brrdy",
	description = "UB3R Guns allows you to switch bullet type",
	version = "1.0.0",
	url = "http://www.sourcemod.net/"
};
new const String:ub3r_weapons[MAX_WEAPONS][] = {
	"weapon_ak47", "weapon_aug", "weapon_bizon", "weapon_deagle", "weapon_decoy", "weapon_elite", "weapon_famas", "weapon_fiveseven", "weapon_flashbang",
	"weapon_g3sg1", "weapon_galilar", "weapon_glock", "weapon_hegrenade", "weapon_hkp2000", "weapon_incgrenade", "weapon_knife", "weapon_m249", "weapon_m4a1",
	"weapon_mac10", "weapon_mag7", "weapon_molotov", "weapon_mp7", "weapon_mp9", "weapon_negev", "weapon_nova", "weapon_p250", "weapon_p90", "weapon_sawedoff",
	"weapon_scar20", "weapon_sg556", "weapon_smokegrenade", "weapon_ssg08", "weapon_taser", "weapon_tec9", "weapon_ump45", "weapon_xm1014"
};


public OnPluginStart()
{
	RegAdminCmd("ub_awp", smUB3RAWP, ADMFLAG_GENERIC, "- <target> <weaponname>");
	RegAdminCmd("ub_scout", smUB3RSCOUT, ADMFLAG_GENERIC, "- <target> <weaponname>");
	RegAdminCmd("ub_p90", smUB3RP90, ADMFLAG_GENERIC, "- <target> <weaponname>");
	RegAdminCmd("ub_p250", smUB3RP250, ADMFLAG_GENERIC, "- <target> <weaponname>");
	RegAdminCmd("ub_fiveseven", smUB3RFIVESEVEN, ADMFLAG_GENERIC, "- <target> <weaponname>");
	RegAdminCmd("ub_zeus", smUB3RZEUS, ADMFLAG_GENERIC, "- <target> <weaponname>");
	RegAdminCmd("ub_m249", smUB3RM249, ADMFLAG_GENERIC, "- <target> <weaponname>");
	RegAdminCmd("ub_negev", smUB3RNEGEV, ADMFLAG_GENERIC, "- <target> <weaponname>");
	RegAdminCmd("ub_cmds", Command_UBCMDS, ADMFLAG_GENERIC);
	RegConsoleCmd("ub_version", Command_UB3RVers);
}
public Action:Command_UBCMDS(client, args)
{
PrintToConsole(client, "ub3r cmds:");
PrintToConsole(client, "ub_awp <player> <weaponname>");
PrintToConsole(client, "ub_scout <player> <weaponname>");
PrintToConsole(client, "ub_p90 <player> <weaponname>");
PrintToConsole(client, "ub_p250 <player> <weaponname>");
PrintToConsole(client, "ub_fiveseven <player> <weaponname>");
PrintToConsole(client, "ub_zeus <player> <weaponname>");
PrintToConsole(client, "ub_m249 <player> <weaponname>");
PrintToConsole(client, "ub_negev <player> <weaponname>");
return Plugin_Handled;
}
public Action:Command_UB3RVers(client, args)
{
PrintToConsole(client, "UB3R Guns V 1.0.0:");
return Plugin_Handled;
}
public Action:smUB3RNEGEV(id, args)
{
	if(args < 2)
	{
		ReplyToCommand(id, "Type ub_cmds");
		return Plugin_Handled;
	}
	
	decl String:Ub3rArg[256];
	decl String:Ub3rTempArg[32];
	decl String:Ub3rWeaponName[32];
	decl String:Ub3rWeaponNameTemp[32];
	decl Ub3rL;
	decl Ub3rNL;
	
	GetCmdArgString(Ub3rArg, sizeof(Ub3rArg));
	Ub3rL = BreakString(Ub3rArg, Ub3rTempArg, sizeof(Ub3rTempArg));
	
	if((Ub3rNL = BreakString(Ub3rArg[Ub3rL], Ub3rWeaponName, sizeof(Ub3rWeaponName))) != -1)
		Ub3rL += Ub3rNL;
	
	new i;
	new ub3rvalid = 0;
	
	if(StrContains(Ub3rWeaponName, "weapon_") == -1)
	{
		FormatEx(Ub3rWeaponNameTemp, 31, "weapon_");
		StrCat(Ub3rWeaponNameTemp, 31, Ub3rWeaponName);
		
		strcopy(Ub3rWeaponName, 31, Ub3rWeaponNameTemp);
	}
	
	for(i = 0; i < MAX_WEAPONS; ++i)
	{
		if(StrEqual(Ub3rWeaponName, ub3r_weapons[i]))
		{
			ub3rvalid = 1;
			break;
		}
	}
	
	if(!ub3rvalid)
	{
		ReplyToCommand(id, "The weaponname (%s) isn't valid", Ub3rWeaponName);
		return Plugin_Handled;
	}
	
	decl String:ub3rTargetName[MAX_TARGET_LENGTH];
	decl ub3rTargetList[1];
	decl bool:bTN_IsML;
	
	new iMUb3r = -1;
	
	if(ProcessTargetString(Ub3rTempArg, id, ub3rTargetList, 1, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_MULTI, ub3rTargetName, sizeof(ub3rTargetName), bTN_IsML) > 0)
	iMUb3r = ub3rTargetList[0];
	new topkek;
	topkek = CreateEntityByName(Ub3rWeaponName);
	SetEntProp(topkek, Prop_Send, "m_iItemDefinitionIndex", 28);
	DispatchSpawn(topkek);
	if(iMUb3r != -1 && !IsFakeClient(iMUb3r))
	EquipPlayerWeapon(iMUb3r, topkek);
	
	return Plugin_Handled;
}

public Action:smUB3RM249(id, args)
{
	if(args < 2)
	{
		ReplyToCommand(id, "Type ub_cmds");
		return Plugin_Handled;
	}
	
	decl String:Ub3rArg[256];
	decl String:Ub3rTempArg[32];
	decl String:Ub3rWeaponName[32];
	decl String:Ub3rWeaponNameTemp[32];
	decl Ub3rL;
	decl Ub3rNL;
	
	GetCmdArgString(Ub3rArg, sizeof(Ub3rArg));
	Ub3rL = BreakString(Ub3rArg, Ub3rTempArg, sizeof(Ub3rTempArg));
	
	if((Ub3rNL = BreakString(Ub3rArg[Ub3rL], Ub3rWeaponName, sizeof(Ub3rWeaponName))) != -1)
		Ub3rL += Ub3rNL;
	
	new i;
	new ub3rvalid = 0;
	
	if(StrContains(Ub3rWeaponName, "weapon_") == -1)
	{
		FormatEx(Ub3rWeaponNameTemp, 31, "weapon_");
		StrCat(Ub3rWeaponNameTemp, 31, Ub3rWeaponName);
		
		strcopy(Ub3rWeaponName, 31, Ub3rWeaponNameTemp);
	}
	
	for(i = 0; i < MAX_WEAPONS; ++i)
	{
		if(StrEqual(Ub3rWeaponName, ub3r_weapons[i]))
		{
			ub3rvalid = 1;
			break;
		}
	}
	
	if(!ub3rvalid)
	{
		ReplyToCommand(id, "The weaponname (%s) isn't valid", Ub3rWeaponName);
		return Plugin_Handled;
	}
	
	decl String:ub3rTargetName[MAX_TARGET_LENGTH];
	decl ub3rTargetList[1];
	decl bool:bTN_IsML;
	
	new iMUb3r = -1;
	
	if(ProcessTargetString(Ub3rTempArg, id, ub3rTargetList, 1, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_MULTI, ub3rTargetName, sizeof(ub3rTargetName), bTN_IsML) > 0)
	iMUb3r = ub3rTargetList[0];
	new topkek;
	topkek = CreateEntityByName(Ub3rWeaponName);
	SetEntProp(topkek, Prop_Send, "m_iItemDefinitionIndex", 14);	
	DispatchSpawn(topkek);
	if(iMUb3r != -1 && !IsFakeClient(iMUb3r))
	EquipPlayerWeapon(iMUb3r, topkek);
	
	return Plugin_Handled;
}

public Action:smUB3RZEUS(id, args)
{
	if(args < 2)
	{
		ReplyToCommand(id, "Type ub_cmds");
		return Plugin_Handled;
	}
	
	decl String:Ub3rArg[256];
	decl String:Ub3rTempArg[32];
	decl String:Ub3rWeaponName[32];
	decl String:Ub3rWeaponNameTemp[32];
	decl Ub3rL;
	decl Ub3rNL;
	
	GetCmdArgString(Ub3rArg, sizeof(Ub3rArg));
	Ub3rL = BreakString(Ub3rArg, Ub3rTempArg, sizeof(Ub3rTempArg));
	
	if((Ub3rNL = BreakString(Ub3rArg[Ub3rL], Ub3rWeaponName, sizeof(Ub3rWeaponName))) != -1)
		Ub3rL += Ub3rNL;
	
	new i;
	new ub3rvalid = 0;
	
	if(StrContains(Ub3rWeaponName, "weapon_") == -1)
	{
		FormatEx(Ub3rWeaponNameTemp, 31, "weapon_");
		StrCat(Ub3rWeaponNameTemp, 31, Ub3rWeaponName);
		
		strcopy(Ub3rWeaponName, 31, Ub3rWeaponNameTemp);
	}
	
	for(i = 0; i < MAX_WEAPONS; ++i)
	{
		if(StrEqual(Ub3rWeaponName, ub3r_weapons[i]))
		{
			ub3rvalid = 1;
			break;
		}
	}
	
	if(!ub3rvalid)
	{
		ReplyToCommand(id, "The weaponname (%s) isn't valid", Ub3rWeaponName);
		return Plugin_Handled;
	}
	
	decl String:ub3rTargetName[MAX_TARGET_LENGTH];
	decl ub3rTargetList[1];
	decl bool:bTN_IsML;
	
	new iMUb3r = -1;
	
	if(ProcessTargetString(Ub3rTempArg, id, ub3rTargetList, 1, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_MULTI, ub3rTargetName, sizeof(ub3rTargetName), bTN_IsML) > 0)
	iMUb3r = ub3rTargetList[0];
	new topkek;
	topkek = CreateEntityByName(Ub3rWeaponName);
	SetEntProp(topkek, Prop_Send, "m_iItemDefinitionIndex", 31);	
	DispatchSpawn(topkek);
	if(iMUb3r != -1 && !IsFakeClient(iMUb3r))
	EquipPlayerWeapon(iMUb3r, topkek);
	
	return Plugin_Handled;
}

public Action:smUB3RFIVESEVEN(id, args)
{
	if(args < 2)
	{
		ReplyToCommand(id, "Type ub_cmds>");
		return Plugin_Handled;
	}
	
	decl String:Ub3rArg[256];
	decl String:Ub3rTempArg[32];
	decl String:Ub3rWeaponName[32];
	decl String:Ub3rWeaponNameTemp[32];
	decl Ub3rL;
	decl Ub3rNL;
	
	GetCmdArgString(Ub3rArg, sizeof(Ub3rArg));
	Ub3rL = BreakString(Ub3rArg, Ub3rTempArg, sizeof(Ub3rTempArg));
	
	if((Ub3rNL = BreakString(Ub3rArg[Ub3rL], Ub3rWeaponName, sizeof(Ub3rWeaponName))) != -1)
		Ub3rL += Ub3rNL;
	
	new i;
	new ub3rvalid = 0;
	
	if(StrContains(Ub3rWeaponName, "weapon_") == -1)
	{
		FormatEx(Ub3rWeaponNameTemp, 31, "weapon_");
		StrCat(Ub3rWeaponNameTemp, 31, Ub3rWeaponName);
		
		strcopy(Ub3rWeaponName, 31, Ub3rWeaponNameTemp);
	}
	
	for(i = 0; i < MAX_WEAPONS; ++i)
	{
		if(StrEqual(Ub3rWeaponName, ub3r_weapons[i]))
		{
			ub3rvalid = 1;
			break;
		}
	}
	
	if(!ub3rvalid)
	{
		ReplyToCommand(id, "The weaponname (%s) isn't valid", Ub3rWeaponName);
		return Plugin_Handled;
	}
	
	decl String:ub3rTargetName[MAX_TARGET_LENGTH];
	decl ub3rTargetList[1];
	decl bool:bTN_IsML;
	
	new iMUb3r = -1;
	
	if(ProcessTargetString(Ub3rTempArg, id, ub3rTargetList, 1, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_MULTI, ub3rTargetName, sizeof(ub3rTargetName), bTN_IsML) > 0)
	iMUb3r = ub3rTargetList[0];
	new topkek;
	topkek = CreateEntityByName(Ub3rWeaponName);
	SetEntProp(topkek, Prop_Send, "m_iItemDefinitionIndex", 3);
	DispatchSpawn(topkek);
	if(iMUb3r != -1 && !IsFakeClient(iMUb3r))
	EquipPlayerWeapon(iMUb3r, topkek);
	
	return Plugin_Handled;
}

public Action:smUB3RP250(id, args)
{
	if(args < 2)
	{
		ReplyToCommand(id, "Type ub_cmds");
		return Plugin_Handled;
	}
	
	decl String:Ub3rArg[256];
	decl String:Ub3rTempArg[32];
	decl String:Ub3rWeaponName[32];
	decl String:Ub3rWeaponNameTemp[32];
	decl Ub3rL;
	decl Ub3rNL;
	
	GetCmdArgString(Ub3rArg, sizeof(Ub3rArg));
	Ub3rL = BreakString(Ub3rArg, Ub3rTempArg, sizeof(Ub3rTempArg));
	
	if((Ub3rNL = BreakString(Ub3rArg[Ub3rL], Ub3rWeaponName, sizeof(Ub3rWeaponName))) != -1)
		Ub3rL += Ub3rNL;
	
	new i;
	new ub3rvalid = 0;
	
	if(StrContains(Ub3rWeaponName, "weapon_") == -1)
	{
		FormatEx(Ub3rWeaponNameTemp, 31, "weapon_");
		StrCat(Ub3rWeaponNameTemp, 31, Ub3rWeaponName);
		
		strcopy(Ub3rWeaponName, 31, Ub3rWeaponNameTemp);
	}
	
	for(i = 0; i < MAX_WEAPONS; ++i)
	{
		if(StrEqual(Ub3rWeaponName, ub3r_weapons[i]))
		{
			ub3rvalid = 1;
			break;
		}
	}
	
	if(!ub3rvalid)
	{
		ReplyToCommand(id, "The weaponname (%s) isn't valid", Ub3rWeaponName);
		return Plugin_Handled;
	}
	
	decl String:ub3rTargetName[MAX_TARGET_LENGTH];
	decl ub3rTargetList[1];
	decl bool:bTN_IsML;
	
	new iMUb3r = -1;
	
	if(ProcessTargetString(Ub3rTempArg, id, ub3rTargetList, 1, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_MULTI, ub3rTargetName, sizeof(ub3rTargetName), bTN_IsML) > 0)
	iMUb3r = ub3rTargetList[0];
	new topkek;
	topkek = CreateEntityByName(Ub3rWeaponName);
	SetEntProp(topkek, Prop_Send, "m_iItemDefinitionIndex", 36);	
	DispatchSpawn(topkek);
	if(iMUb3r != -1 && !IsFakeClient(iMUb3r))
	EquipPlayerWeapon(iMUb3r, topkek);
	
	return Plugin_Handled;
}

public Action:smUB3RSCOUT(id, args)
{
	if(args < 2)
	{
		ReplyToCommand(id, "Type ub_cmds");
		return Plugin_Handled;
	}
	
	decl String:Ub3rArg[256];
	decl String:Ub3rTempArg[32];
	decl String:Ub3rWeaponName[32];
	decl String:Ub3rWeaponNameTemp[32];
	decl Ub3rL;
	decl Ub3rNL;
	
	GetCmdArgString(Ub3rArg, sizeof(Ub3rArg));
	Ub3rL = BreakString(Ub3rArg, Ub3rTempArg, sizeof(Ub3rTempArg));
	
	if((Ub3rNL = BreakString(Ub3rArg[Ub3rL], Ub3rWeaponName, sizeof(Ub3rWeaponName))) != -1)
		Ub3rL += Ub3rNL;
	
	new i;
	new ub3rvalid = 0;
	
	if(StrContains(Ub3rWeaponName, "weapon_") == -1)
	{
		FormatEx(Ub3rWeaponNameTemp, 31, "weapon_");
		StrCat(Ub3rWeaponNameTemp, 31, Ub3rWeaponName);
		
		strcopy(Ub3rWeaponName, 31, Ub3rWeaponNameTemp);
	}
	
	for(i = 0; i < MAX_WEAPONS; ++i)
	{
		if(StrEqual(Ub3rWeaponName, ub3r_weapons[i]))
		{
			ub3rvalid = 1;
			break;
		}
	}
	
	if(!ub3rvalid)
	{
		ReplyToCommand(id, "The weaponname (%s) isn't valid", Ub3rWeaponName);
		return Plugin_Handled;
	}
	
	decl String:ub3rTargetName[MAX_TARGET_LENGTH];
	decl ub3rTargetList[1];
	decl bool:bTN_IsML;
	
	new iMUb3r = -1;
	
	if(ProcessTargetString(Ub3rTempArg, id, ub3rTargetList, 1, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_MULTI, ub3rTargetName, sizeof(ub3rTargetName), bTN_IsML) > 0)
	iMUb3r = ub3rTargetList[0];
	new topkek;
	topkek = CreateEntityByName(Ub3rWeaponName);
	SetEntProp(topkek, Prop_Send, "m_iItemDefinitionIndex", 40);	
	DispatchSpawn(topkek);
	if(iMUb3r != -1 && !IsFakeClient(iMUb3r))
	EquipPlayerWeapon(iMUb3r, topkek);
	
	return Plugin_Handled;
}

public Action:smUB3RP90(id, args)
{
	if(args < 2)
	{
		ReplyToCommand(id, "Type ub_cmds");
		return Plugin_Handled;
	}
	
	decl String:Ub3rArg[256];
	decl String:Ub3rTempArg[32];
	decl String:Ub3rWeaponName[32];
	decl String:Ub3rWeaponNameTemp[32];
	decl Ub3rL;
	decl Ub3rNL;
	
	GetCmdArgString(Ub3rArg, sizeof(Ub3rArg));
	Ub3rL = BreakString(Ub3rArg, Ub3rTempArg, sizeof(Ub3rTempArg));
	
	if((Ub3rNL = BreakString(Ub3rArg[Ub3rL], Ub3rWeaponName, sizeof(Ub3rWeaponName))) != -1)
		Ub3rL += Ub3rNL;
	
	new i;
	new ub3rvalid = 0;
	
	if(StrContains(Ub3rWeaponName, "weapon_") == -1)
	{
		FormatEx(Ub3rWeaponNameTemp, 31, "weapon_");
		StrCat(Ub3rWeaponNameTemp, 31, Ub3rWeaponName);
		
		strcopy(Ub3rWeaponName, 31, Ub3rWeaponNameTemp);
	}
	
	for(i = 0; i < MAX_WEAPONS; ++i)
	{
		if(StrEqual(Ub3rWeaponName, ub3r_weapons[i]))
		{
			ub3rvalid = 1;
			break;
		}
	}
	
	if(!ub3rvalid)
	{
		ReplyToCommand(id, "The weaponname (%s) isn't valid", Ub3rWeaponName);
		return Plugin_Handled;
	}
	
	decl String:ub3rTargetName[MAX_TARGET_LENGTH];
	decl ub3rTargetList[1];
	decl bool:bTN_IsML;
	
	new iMUb3r = -1;
	
	if(ProcessTargetString(Ub3rTempArg, id, ub3rTargetList, 1, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_MULTI, ub3rTargetName, sizeof(ub3rTargetName), bTN_IsML) > 0)
	iMUb3r = ub3rTargetList[0];
	new topkek;
	topkek = CreateEntityByName(Ub3rWeaponName);
	SetEntProp(topkek, Prop_Send, "m_iItemDefinitionIndex", 19);	
	DispatchSpawn(topkek);
	if(iMUb3r != -1 && !IsFakeClient(iMUb3r))
	EquipPlayerWeapon(iMUb3r, topkek);
	
	return Plugin_Handled;
}

public Action:smUB3RAWP(id, args)
{
	if(args < 2)
	{
		ReplyToCommand(id, "Type ub_cmds");
		return Plugin_Handled;
	}
	
	decl String:Ub3rArg[256];
	decl String:Ub3rTempArg[32];
	decl String:Ub3rWeaponName[32];
	decl String:Ub3rWeaponNameTemp[32];
	decl Ub3rL;
	decl Ub3rNL;
	
	GetCmdArgString(Ub3rArg, sizeof(Ub3rArg));
	Ub3rL = BreakString(Ub3rArg, Ub3rTempArg, sizeof(Ub3rTempArg));
	
	if((Ub3rNL = BreakString(Ub3rArg[Ub3rL], Ub3rWeaponName, sizeof(Ub3rWeaponName))) != -1)
		Ub3rL += Ub3rNL;
	
	new i;
	new ub3rvalid = 0;
	
	if(StrContains(Ub3rWeaponName, "weapon_") == -1)
	{
		FormatEx(Ub3rWeaponNameTemp, 31, "weapon_");
		StrCat(Ub3rWeaponNameTemp, 31, Ub3rWeaponName);
		
		strcopy(Ub3rWeaponName, 31, Ub3rWeaponNameTemp);
	}
	
	for(i = 0; i < MAX_WEAPONS; ++i)
	{
		if(StrEqual(Ub3rWeaponName, ub3r_weapons[i]))
		{
			ub3rvalid = 1;
			break;
		}
	}
	
	if(!ub3rvalid)
	{
		ReplyToCommand(id, "The weaponname (%s) isn't valid", Ub3rWeaponName);
		return Plugin_Handled;
	}
	
	decl String:ub3rTargetName[MAX_TARGET_LENGTH];
	decl ub3rTargetList[1];
	decl bool:bTN_IsML;
	
	new iMUb3r = -1;
	
	if(ProcessTargetString(Ub3rTempArg, id, ub3rTargetList, 1, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_MULTI, ub3rTargetName, sizeof(ub3rTargetName), bTN_IsML) > 0)
		iMUb3r = ub3rTargetList[0];
	new topkek;
	topkek = CreateEntityByName(Ub3rWeaponName);
	SetEntProp(topkek, Prop_Send, "m_iItemDefinitionIndex", 9);		
	DispatchSpawn(topkek);
	if(iMUb3r != -1 && !IsFakeClient(iMUb3r))
	EquipPlayerWeapon(iMUb3r, topkek);
	return Plugin_Handled;
}