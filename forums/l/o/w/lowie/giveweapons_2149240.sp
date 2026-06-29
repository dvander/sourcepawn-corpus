#include <sourcemod>
#include <cstrike> 
#include <sdktools>

#pragma semicolon 1

#define MAX_WEAPONS		39
new String:sWeaponName[32];

new const String:g_weapons[MAX_WEAPONS][] = {
	"weapon_ak47", "weapon_aug", "weapon_awp", "weapon_bizon", "weapon_cz75a", "weapon_deagle", "weapon_decoy", "weapon_elite", "weapon_famas", "weapon_fiveseven", "weapon_flashbang",
	"weapon_g3sg1", "weapon_galilar", "weapon_glock", "weapon_hegrenade", "weapon_hkp2000", "weapon_incgrenade", "weapon_m249", "weapon_m4a1",
	"weapon_m4a1_silencer", "weapon_mac10", "weapon_mag7", "weapon_molotov", "weapon_mp7", "weapon_mp9", "weapon_negev", "weapon_nova", "weapon_p250", "weapon_p90",
	"weapon_sawedoff", "weapon_scar20", "weapon_sg556", "weapon_smokegrenade", "weapon_ssg08", "weapon_taser", "weapon_tec9", "weapon_ump45", "weapon_usp_silencer",
	"weapon_xm1014"
};

public Plugin:myinfo =
{
	name = "Give Weapon",
	author = "Kiske",
	description = "Give a weapon to a player from a command",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};


// Weapon Entity Members and Data
new g_iAmmo = -1;
new g_hActiveWeapon = -1;
new g_iPrimaryAmmoType = -1;
new g_iClip1 = -1;

public OnPluginStart()
{
	g_iAmmo = FindSendPropOffs("CCSPlayer", "m_iAmmo");
	g_hActiveWeapon = FindSendPropOffs("CCSPlayer", "m_hActiveWeapon");
	g_iPrimaryAmmoType = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");
	g_iClip1 = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
	if (g_hActiveWeapon == -1 || g_iPrimaryAmmoType == -1 || g_iAmmo == -1 || g_iClip1 == -1)
	SetFailState("Failed to retrieve entity member offsets");
	
	RegAdminCmd("sm_weapon", smWeapon, ADMFLAG_BAN, "- <target> <weaponname>");
	RegAdminCmd("sm_weapon_all", smWeapon_all, ADMFLAG_BAN, "<weaponname>");
	RegAdminCmd("sm_weapon_t", smWeapon_t, ADMFLAG_BAN, "<weaponname>");
	RegAdminCmd("sm_weapon_ct", smWeapon_ct, ADMFLAG_BAN, "<weaponname>");
	RegAdminCmd("sm_weaponlist", smWeaponList, ADMFLAG_BAN, "- list of the weapon names");
	RegAdminCmd("sm_weapon_ammo", smWeapon_ammo, ADMFLAG_BAN, "fill ammo");

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
	
	if(iTarget == -1)
	{
		return Plugin_Handled;
	}
	if(!IsClientConnected(iTarget))
	{
		return Plugin_Handled;
	}
	weapon_choose(iTarget);
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
	
	for(new client = 1; client <= MaxClients+1; client++)
	{
		if(!IsClientConnected(client))
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
	
	for(new client = 1; client <= MaxClients+1; client++)
	{
		if(!IsClientConnected(client))
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
	
	for(new client = 1; client <= MaxClients+1; client++)
	{
		if(!IsClientConnected(client))
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

public Action:smWeapon_ammo(id, args)
{
	new client_index = id;
	if(!IsClientConnected(client_index))
	{
		return Plugin_Handled;
	}	
	if(IsPlayerAlive(client_index))
	{
		ReserveAmmo(client_index);
	}
	return Plugin_Handled;
}

stock weapon_choose(iTarget)
{
	if(iTarget != -1)
	{		
		if(StrEqual(sWeaponName, "weapon_incgrenade", false) || StrEqual(sWeaponName, "weapon_hegrenade", false) || StrEqual(sWeaponName, "weapon_molotov", false) || StrEqual(sWeaponName, "weapon_smokegrenade", false) || StrEqual(sWeaponName, "weapon_flashbang", false) || StrEqual(sWeaponName, "weapon_decoy", false))
		{
			GivePlayerItem(iTarget, sWeaponName);
		}		
		else if((GetPlayerWeaponSlot(iTarget, 0) == -1) && (GetPlayerWeaponSlot(iTarget, 1) == -1))
		{
			new client_index = iTarget;
			GivePlayerItem(iTarget, sWeaponName);
			CreateTimer(0.5, Timer_WAIT, client_index);
		}
		else 
		{
			new iWeapon1 = GetPlayerWeaponSlot(iTarget, 0);
			new iWeapon2 = GetPlayerWeaponSlot(iTarget, 1);
			decl String:buffer1[32] = "weapon";
			decl String:buffer2[32] = "weapon";
			if(iWeapon1 != -1)
			GetEntityClassname(iWeapon1, buffer1, 32);
			if(iWeapon2 != -1)
			GetEntityClassname(iWeapon2, buffer2, 32);
			if(StrEqual(sWeaponName, buffer1, false) || StrEqual(sWeaponName, buffer2, false))
			{
				new client_index = iTarget;
				GivePlayerItem(iTarget, sWeaponName);
				CreateTimer(0.5, Timer_WAIT, client_index);
			}
			else
			{
				new client_index = iTarget;
				new iItem = GivePlayerItem(iTarget, sWeaponName);
				EquipPlayerWeapon(iTarget, iItem);
				CreateTimer(0.5, Timer_WAIT, client_index);
			}
		}
	}
}

stock ReserveAmmo(client_index)
{	
	if (client_index && GetClientTeam(client_index) >= 2)
	{
		new entity_index1 = GetPlayerWeaponSlot(client_index, 0);
		new entity_index2 = GetPlayerWeaponSlot(client_index, 1);
		if (IsValidEdict(entity_index1))
		{			
			new ammo_type1 = GetEntData(entity_index1, g_iPrimaryAmmoType);			
			GivePlayerAmmo(client_index, 200, ammo_type1, true);		
		}
		if (IsValidEdict(entity_index2))
		{						
			new ammo_type2 = GetEntData(entity_index2, g_iPrimaryAmmoType);			
			GivePlayerAmmo(client_index, 200, ammo_type2, true);
		}
	}
}

public Action:Timer_WAIT(Handle:timer, any:client_index)
{
	ReserveAmmo(client_index);
}