#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "L4D2 Weapon Attack Speed Modifier",
	author = "Machine",
	description = "Modifies the Survivors Weapon Attack Speed",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1369117#post1369117"
};

new WeaponSpeed[MAXPLAYERS + 1];
new Handle:WeaponSpeedEnabled = INVALID_HANDLE;
new Handle:WeaponSpeedAmount = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("l4d2_weaponspeed", Command_WeaponSpeed, ADMFLAG_BAN, "l4d2_weaponspeed <#userid|name> <0|1> - Changes clients default weapon speed");

	CreateConVar("l4d2_weaponspeed_version", PLUGIN_VERSION, "L4D2 Weapon Attack Speed Modifier Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	WeaponSpeedEnabled = CreateConVar("l4d2_weaponspeed_everyone", "0", "<0|1> - Apply the Weapon Attack Speed Modifier on Everyone?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	WeaponSpeedAmount = CreateConVar("l4d2_weaponspeed_amount", "1.6", "<1.0-2.0> - Weapon Attack Speed Modified Value", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 2.0);

	LoadTranslations("common.phrases");
}
public OnClientPostAdminCheck(client)
{
	WeaponSpeed[client] = 0;
}
public Action:Command_WeaponSpeed(client, args)
{	
	if (args < 1)
	{
		if (client > 0)
		{
			if (WeaponSpeed[client] == 0)
			{
				WeaponSpeed[client] = 1;
				PrintToChat(client,"\x01[SM] Your \x03Weapon Speed\x01 has been modified");
			}
			else
			{
				WeaponSpeed[client] = 0;
				PrintToChat(client,"\x01[SM] Your \x05Weapon Speed\x01 has returned to normal");
			}
		}
		else
		{
			ReplyToCommand(client, "[SM] Must be in game to modify Weapon Speed on yourself");	
		}
	}		
	else if (args == 1)
	{
		ReplyToCommand(client, "[SM] Usage: l4d2_weaponspeed <#userid|name> <0|1>");
	}
	else if (args == 2)
	{
		new String:target[32], String:arg2[32];
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, arg2, sizeof(arg2));
		new args2 = StringToInt(arg2);
			
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
		if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		for (new i=0; i<target_count; i++)
		{
			new String:clientname[64];
			GetClientName(target_list[i], clientname, sizeof(clientname));
			if (args2 == 0)
			{
				ReplyToCommand(client,"[SM] Custom Weapon Speed Disabled on %s",clientname);	
				WeaponSpeed[target_list[i]] = 0;
				PrintToChat(target_list[i],"\x01[SM] Your \x05Weapon Speed\x01 has returned to normal");
			}
			else if (args2 == 1)
			{
				ReplyToCommand(client,"[SM] Custom Weapon Speed Enabled on %s",clientname);	
				WeaponSpeed[target_list[i]] = 1;
				PrintToChat(target_list[i],"\x01[SM] Your \x03Weapon Speed\x01 has been modified");
			}			
			else
			{
				ReplyToCommand(client, "[SM] Usage: l4d2_weaponspeed <#userid|name> <0|1>");
			}		
		}
	}
	else if (args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: l4d2_weaponspeed <#userid|name> <0|1>");
	}

	return Plugin_Handled;
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	//OnPlayerRunCmd seems to work best for this so we can get the right frame to set our values on the players weapon
	if (IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		if (GetConVarInt(WeaponSpeedEnabled) == 1 || WeaponSpeed[client] == 1)
		{
			if (buttons & IN_ATTACK || buttons & IN_ATTACK2)
			{
				new String:name[64];
				GetClientWeapon(client, name, sizeof(name));
				if (StrEqual(name, "weapon_smg") || StrEqual(name, "weapon_smg_silenced") || StrEqual(name, "weapon_smg_mp5")
				|| StrEqual(name, "weapon_rifle") || StrEqual(name, "weapon_rifle_sg552") || StrEqual(name, "weapon_rifle_ak47")
				|| StrEqual(name, "weapon_autoshotgun") || StrEqual(name, "weapon_shotgun_spas") || StrEqual(name, "weapon_rifle_m60")
				|| StrEqual(name, "weapon_sniper_awp") || StrEqual(name, "weapon_sniper_military") || StrEqual(name, "weapon_sniper_scout")
				|| StrEqual(name, "weapon_hunting_rifle") || StrEqual(name, "weapon_pumpshotgun") || StrEqual(name, "weapon_shotgun_chrome"))
				{
					AdjustWeaponSpeed(client, GetConVarFloat(WeaponSpeedAmount), 0);
				}
				else if (StrEqual(name, "weapon_melee"))
				{
					AdjustWeaponSpeed(client, GetConVarFloat(WeaponSpeedAmount), 1);
				}
			}
		}
	}

	return Plugin_Continue;	
}
stock AdjustWeaponSpeed(client, Float:Amount, slot)
{
	if (GetPlayerWeaponSlot(client, slot) > 0)
	{
		new Float:m_flNextPrimaryAttack = GetEntPropFloat(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_flNextPrimaryAttack");
		new Float:m_flNextSecondaryAttack = GetEntPropFloat(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_flNextSecondaryAttack");
		new Float:m_flCycle = GetEntPropFloat(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_flCycle");
		new m_bInReload = GetEntProp(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_bInReload");
		//Getting the animation cycle at zero seems to be key here, however the scar and pistols weren't seem to be getting affected
		if (m_flCycle == 0.000000 && m_bInReload < 1)
		{
			SetEntPropFloat(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_flPlaybackRate", Amount);
			SetEntPropFloat(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_flNextPrimaryAttack", m_flNextPrimaryAttack - ((Amount - 1.0) / 2));
			SetEntPropFloat(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_flNextSecondaryAttack", m_flNextSecondaryAttack - ((Amount - 1.0) / 2));
		}
	}
}