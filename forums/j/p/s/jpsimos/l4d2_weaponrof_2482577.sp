#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "L4D2 Weapon Rate Of Fire Modifier",
	author = "Jacob Psimos",
	description = "Modifies the Survivors Weapon ROF",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1369117#post1369117"
};

/* numWeapons must always equal the number of weapons in the WeaponNames array */
const numWeapons = 10;

new String:WeaponNames[numWeapons][64] = {
	"weapon_rifle",
	"weapon_rifle_ak47",
	"weapon_smg",
	"weapon_smg_silenced",
	"weapon_rifle_m60",
	"weapon_hunting_rifle",
	"weapon_pumpshotgun",
	"weapon_shotgun_chrome",
	"weapon_sniper_military",
	"weapon_shotgun_spas"
};

new Float:WeaponSpeeds[numWeapons] = {
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,
	1.0
};

new Handle:WeaponSpeedEnabled = INVALID_HANDLE;


public OnPluginStart(){
	RegAdminCmd("l4d2_weaponspeed", Command_WeaponSpeed, ADMFLAG_BAN, "l4d2_weaponspeed <weapon_name> <modifier>");
	WeaponSpeedEnabled = CreateConVar("l4d2_weaponspeed_enable", "1", "<0|1> - Enable rate of fire mods", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	LoadTranslations("common.phrases");
}

public Action:Command_WeaponSpeed(client, args){
	/*
		Expected arguments: l4d_weaponspeed <weapon_name> <rof: 1.0-2.0>
	*/
	new err = 0;
	if(args == 2){
		
		new String:argument[128];
		new String:argumentSplit[2][64];
		
		GetCmdArgString(argument, 128);
		new count = ExplodeString(argument, " ", argumentSplit, 2, 64, false);
		
		if(count == 2){
			
			new weapIndex = _GetWeaponIndex(argumentSplit[0]);
			new Float:parsedFloat = StringToFloat(argumentSplit[1]);
			
			if(weapIndex >= 0){
				if(parsedFloat > 2.0 || parsedFloat < 1.0){
					parsedFloat = 1.0;
					ReplyToCommand(client, "[SM] Fire rate truncated to default (outside bounds)");
				}
				WeaponSpeeds[weapIndex] = parsedFloat;
				ReplyToCommand(client, "[SM] Weapon fire rate modified");
			}else{
				ReplyToCommand(client, "[SM] Bogus or unsupported weapon name");
			}
			
		}else{
			err = 1;
		}
	}else{
		err = 1;
	}
	
	if(err == 1){
		ReplyToCommand(client, "[SM] Invalid number of arguments");
		ReplyToCommand(client, "[SM] Expecting <weapon_name> <rof: 1.0-2.0>");
	}
	
	return Plugin_Handled;
}

/* Get the array index of a weapon in the WeaponNames array */
public _GetWeaponIndex(String:name[64]){
	for(new i = 0; i < numWeapons; i++){
		if(StrEqual(WeaponNames[i], name)){
			return i;
		}
	}
	return -1;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	//OnPlayerRunCmd seems to work best for this so we can get the right frame to set our values on the players weapon
	if (IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		if (GetConVarInt(WeaponSpeedEnabled) != 0)
		{
			if (buttons & IN_ATTACK || buttons & IN_ATTACK2)
			{
				new String:name[64];
				GetClientWeapon(client, name, 64);
				new weapIndex = _GetWeaponIndex(name);
				if(weapIndex >= 0){
					AdjustWeaponSpeed(client, WeaponSpeeds[weapIndex], 0);
				}
			}
		}
	}

	return Plugin_Continue;	
}

/* Original code from Machine's weapon speed plugin */
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