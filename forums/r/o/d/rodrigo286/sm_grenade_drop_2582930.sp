/*
Description:

Allows players to drop all grenades of your inventory

This plugin has been rewritten from the original made by member: Rodipm
Original thread: http://forums.alliedmods.net/showthread.php?t=172315

The cause of rewriting the plugin? Support bugs and add cvars.

I removed knife drop function.

Bugs fixed:

Infinite grenades: http://forums.alliedmods.net/showpost.php?p=1599372&postcount=11

CVARs:

sm_grenadedrop_enabled = 1/0 - Plugin is enabled/disabled.
sm_drop_he = 0/1 - Allow drop HE Grenades?
sm_drop_smoke = 0/1 Allow drop SMOKE Grenades?
sm_drop_flash = 0/1 Allow drop FLASH Grenades?
sm_grenadedrop_version - Current plugin version

Changelog:

* Version 1.0.0 *
Initial Release

* Version 1.0.1 *
Oficial CSGO Support

New cvar's
sm_drop_incendery = 0/1 Allow drop INCENDERY Grenades?
sm_drop_molotov = 0/1 Allow drop MOLOTOVS?
sm_drop_decoy = 0/1 Allow drop DECOY Grenades?

* Version 1.0.2 *
Little code clean

* Version 1.0.3 *
Total rewrite with new syntax
Update CSGO grenades offsets
Added support for drop knifes
Added support for unit drop
Added support for tagrenades

Cvar's changed to
sm_grenadedrop_enable = 1/0 - Plugin is enabled/disabled.
sm_grenadedrop_he = 0/1 - Allow drop HE Grenades?
sm_grenadedrop_flash = 0/1 - Allow drop FLASH Grenades?
sm_grenadedrop_smoke = 0/1 - Allow drop SMOKE Grenades?
sm_grenadedrop_molotov = 0/1 Allow drop MOLOTOVS?
sm_grenadedrop_inc = 0/1 Allow drop INCENDERY Grenades?
sm_grenadedrop_decoy 0/1 Allow drop DECOY Grenades?
sm_grenadedrop_ta 0/1 Allow drop TA Grenades?
sm_grenadedrop_knife = 0/1 - Allow drop HE Grenades?

*/

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#pragma semicolon 1
#pragma newdecls required;

bool bConVar[9];
Handle hConVar[9] = INVALID_HANDLE;

/* ★ CSS Grenades Indexes ★ */
#define CSS_HE_OFFSET 11
#define CSS_FLASH_OFFSET 12
#define CSS_SMOKE_OFFSET 13

/* ★ CS:GO Grenades Indexes ★ */
#define CSGO_HE_OFFSET 14
#define CSGO_FLASH_OFFSET 15
#define CSGO_SMOKE_OFFSET 16
#define INC_MOLOTOV_OFFSET 17
#define	DECOY_OFFSET 18
#define	TA_OFFSET 22

/* ★ CVARS INDEXS ★ */
#define ENABLE 0
#define HE 1
#define FLASH 2
#define SMOKE 3
#define MOLOTOV 4
#define INC 5
#define	DECOY 6
#define	TA 7
#define	KNIFE 8

/* ★ Current plugin version ★ */
#define PLUGIN_VERSION "Build 1.0.3"

/* ★ Plugin information ★ */
public Plugin myinfo = {
	name = "SM: Grenade Drop",
	author = "Rodrigo286",
	description = "Allows players to drop all grenades and knife",
    version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=224570"
};

public void OnPluginStart(){
	CreateConVar("sm_grenadedrop_version", PLUGIN_VERSION, "\"SM: Grenade Drop\" version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_NOTIFY);

	hConVar[ENABLE] = CreateConVar("sm_grenadedrop_enable", "1", "\"1\" = \"[SM] # Grenade Drop\" plugin is enabled, \"0\" = \"[SM] # Grenade Drop\" plugin is disabled");
	hConVar[HE] = CreateConVar("sm_grenadedrop_he", "1", "\"1\" = \"[SM] # Grenade Drop\" allow drop HE Grenades, \"0\" = \"[SM] # Grenade Drop\" disallow drop HE Grenades");
	hConVar[FLASH] = CreateConVar("sm_grenadedrop_flash", "1", "\"1\" = \"[SM] # Grenade Drop\" allow drop FLASH Grenades, \"0\" = \"[SM] # Grenade Drop\" disallow drop FLASH Grenades");
	hConVar[SMOKE] = CreateConVar("sm_grenadedrop_smoke", "1", "\"1\" = \"[SM] # Grenade Drop\" allow drop SMOKE Grenades, \"0\" = \"[SM] # Grenade Drop\" disallow drop SMOKE Grenades");
	hConVar[MOLOTOV] = CreateConVar("sm_grenadedrop_molotov", "1", "\"1\" = \"[SM] # Grenade Drop\" allow drop MOLOTOV Grenades, \"0\" = \"[SM] # Grenade Drop\" disallow drop MOLOTOV Grenades");
	hConVar[INC] = CreateConVar("sm_grenadedrop_inc", "1", "\"1\" = \"[SM] # Grenade Drop\" allow drop INC Grenades, \"0\" = \"[SM] # Grenade Drop\" disallow drop INC Grenades");
	hConVar[DECOY] = CreateConVar("sm_grenadedrop_decoy", "1", "\"1\" = \"[SM] # Grenade Drop\" allow drop DECOY Grenades, \"0\" = \"[SM] # Grenade Drop\" disallow drop DECOY Grenades");
	hConVar[TA] = CreateConVar("sm_grenadedrop_ta", "1", "\"1\" = \"[SM] # Grenade Drop\" allow drop TA Grenades, \"0\" = \"[SM] # Grenade Drop\" disallow drop TA Grenades");
	hConVar[KNIFE] = CreateConVar("sm_grenadedrop_knife", "1", "\"1\" = \"[SM] # Grenade Drop\" allow drop KNIFE, \"0\" = \"[SM] # Grenade Drop\" disallow drop KNIFE");

	HookConVarChange(hConVar[ENABLE], ConVarChange);
	HookConVarChange(hConVar[HE], ConVarChange);
	HookConVarChange(hConVar[FLASH], ConVarChange);
	HookConVarChange(hConVar[SMOKE], ConVarChange);
	HookConVarChange(hConVar[MOLOTOV], ConVarChange);
	HookConVarChange(hConVar[INC], ConVarChange);
	HookConVarChange(hConVar[DECOY], ConVarChange);
	HookConVarChange(hConVar[TA], ConVarChange);
	HookConVarChange(hConVar[KNIFE], ConVarChange);

	bConVar[ENABLE] = GetConVarBool(hConVar[ENABLE]);
	bConVar[HE] = GetConVarBool(hConVar[HE]);
	bConVar[FLASH] = GetConVarBool(hConVar[FLASH]);
	bConVar[SMOKE] = GetConVarBool(hConVar[SMOKE]);
	bConVar[MOLOTOV] = GetConVarBool(hConVar[MOLOTOV]);
	bConVar[INC] = GetConVarBool(hConVar[INC]);
	bConVar[DECOY] = GetConVarBool(hConVar[DECOY]);
	bConVar[TA] = GetConVarBool(hConVar[TA]);
	bConVar[KNIFE] = GetConVarBool(hConVar[KNIFE]);

	AutoExecConfig(true, "sm_grenade_drop");

	char game[16]; GetGameFolderName(game, sizeof(game));
	if(!StrEqual(game, "cstrike", false) && !StrEqual(game, "csgo", false)){
		SetFailState("\n [SM] # Grenade Drop is only for CSS or CSGO.\n Game detected: %s", game);
		return;
	}

	AddCommandListener(OnHookDrop, "drop");
}

public void ConVarChange(Handle convar, const char[] oldValue, const char[] newValue){
	bConVar[ENABLE] = GetConVarBool(hConVar[ENABLE]);
	bConVar[HE] = GetConVarBool(hConVar[HE]);
	bConVar[FLASH] = GetConVarBool(hConVar[FLASH]);
	bConVar[SMOKE] = GetConVarBool(hConVar[SMOKE]);
	bConVar[MOLOTOV] = GetConVarBool(hConVar[MOLOTOV]);
	bConVar[INC] = GetConVarBool(hConVar[INC]);
	bConVar[DECOY] = GetConVarBool(hConVar[DECOY]);
	bConVar[TA] = GetConVarBool(hConVar[TA]);
	bConVar[KNIFE] = GetConVarBool(hConVar[KNIFE]);
}

public Action OnHookDrop(int client, const char[] command, int argc){
	if(!bConVar[ENABLE])
		return Plugin_Handled;

	if(!IsValidClient(client, false, false))
		return Plugin_Handled;

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(!IsValidEntity(weapon))
		return Plugin_Handled;

	char game[16]; GetGameFolderName(game, sizeof(game));
	if(StrEqual(game, "cstrike", false)){
		if(bConVar[HE] && DropWeapon(client, "weapon_hegrenade", weapon, CSS_HE_OFFSET)){return Plugin_Handled;}
		if(bConVar[FLASH] && DropWeapon(client, "weapon_flashbang", weapon, CSS_FLASH_OFFSET)){return Plugin_Handled;}
		if(bConVar[SMOKE] && DropWeapon(client, "weapon_smokegrenade", weapon, CSS_SMOKE_OFFSET)){return Plugin_Handled;}
		if(bConVar[KNIFE] && DropWeapon(client, "weapon_knife", weapon, 0)){return Plugin_Handled;}
	}
	else if(StrEqual(game, "csgo", false)){
		if(bConVar[HE] && DropWeapon(client, "weapon_hegrenade", weapon, CSGO_HE_OFFSET)){return Plugin_Handled;}
		if(bConVar[FLASH] && DropWeapon(client, "weapon_flashbang", weapon, CSGO_FLASH_OFFSET)){return Plugin_Handled;}
		if(bConVar[SMOKE] && DropWeapon(client, "weapon_smokegrenade", weapon, CSGO_SMOKE_OFFSET)){return Plugin_Handled;}
		if(bConVar[INC] && DropWeapon(client, "weapon_incgrenade", weapon, INC_MOLOTOV_OFFSET)){return Plugin_Handled;}
		if(bConVar[MOLOTOV] && DropWeapon(client, "weapon_molotov", weapon, INC_MOLOTOV_OFFSET)){return Plugin_Handled;}
		if(bConVar[DECOY] && DropWeapon(client, "weapon_decoy", weapon, DECOY_OFFSET)){return Plugin_Handled;}
		if(bConVar[TA] && DropWeapon(client, "weapon_tagrenade", weapon, TA_OFFSET)){return Plugin_Handled;}
		if(bConVar[KNIFE] && DropWeapon(client, "weapon_knife", weapon, 0)){return Plugin_Handled;}
		if(bConVar[KNIFE] && DropWeapon(client, "weapon_bayonet", weapon, 0)){return Plugin_Handled;}
	}

	return Plugin_Continue;
}

stock bool DropWeapon(int client, char[] entity, int weapon, int offset){
	if(IsValidClient(client, false, false) && IsValidEntity(weapon)){
		char classname[64]; 
		GetEntityClassname(weapon, classname, sizeof(classname));  

		if(StrEqual(classname, entity, false)){
			if(offset < 1){
				CS_DropWeapon(client, weapon, true, true);
			}else{
				int quantity = GetEntProp(client, Prop_Send, "m_iAmmo", _, offset);		
				if(quantity > 1){
					quantity --;
					SetEntProp(client, Prop_Send, "m_iAmmo", quantity, _, offset);
					
					float vec[3], origin[3], angles[3];
					GetClientEyePosition(client, vec);
					GetClientAbsOrigin(client, angles); 

					// get random numbers for the x and y to start position
					int side = GetRandomInt(0, 1);
					int randomy = GetRandomInt(-55, 60);

					// get random side of x vector
					int randomx; 
					if(side == 0){randomx = GetRandomInt(-55, -60);}
					else if(side == 1){randomx = GetRandomInt(55, 60);}

					// calc random origin spawn angle
					origin[0] = vec[0] + randomx;
					origin[1] = vec[1] + randomy;
					origin[2] = angles[2] + 25;

					int drop = CreateEntityByName(entity);
					if(IsValidEntity(drop)){		
						DispatchKeyValue(drop, "ammo", "0");
						DispatchSpawn(drop); 
						TeleportEntity(drop, origin, angles, NULL_VECTOR);
					}
				}else if(quantity == 1){CS_DropWeapon(client, weapon, true, true);}
			}

			return true;
		}
	}

	return false;
}

stock bool IsValidClient(int client, bool AllowBots = false, bool AllowDead = true){
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !AllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!AllowDead && !IsPlayerAlive(client)))
    {
        return false;
    }
    return true;
}