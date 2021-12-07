
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "0.0.1"


public Plugin:myinfo = {
    name = "L4D2 Weapon Pickup Message",
    author = "timtam95",
    description = "Custom message on weapon pickup",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/"
};

public void OnClientPutInServer(client) 
{ 
    SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip) 
}

public void OnPluginStart()
{

    CreateConVar("cv_weapon_melee_msg", ""); 
    CreateConVar("cv_weapon_rifle_msg", ""); 
    CreateConVar("cv_weapon_autoshotgun_msg", ""); 
    CreateConVar("cv_weapon_hunting_rifle_msg", ""); 
    CreateConVar("cv_weapon_smg_msg", ""); 
    CreateConVar("cv_weapon_pumpshotgun_msg", ""); 
    CreateConVar("cv_weapon_pistol_msg", ""); 
    CreateConVar("cv_weapon_molotov_msg", ""); 
    CreateConVar("cv_weapon_pipe_bomb_msg", ""); 
    CreateConVar("cv_weapon_first_aid_kit_msg", ""); 
    CreateConVar("cv_weapon_pain_pills_msg", ""); 
    CreateConVar("cv_weapon_shotgun_chrome_msg", ""); 
    CreateConVar("cv_weapon_rifle_desert_msg", ""); 
    CreateConVar("cv_weapon_grenade_launcher_msg", ""); 
    CreateConVar("cv_weapon_rifle_m60_msg", ""); 
    CreateConVar("cv_weapon_rifle_ak47_msg", "");
    CreateConVar("cv_weapon_rifle_sg552_msg", ""); 
    CreateConVar("cv_weapon_shotgun_spas_msg", ""); 
    CreateConVar("cv_weapon_smg_silenced_msg", ""); 
    CreateConVar("cv_weapon_smg_mp5_msg", ""); 
    CreateConVar("cv_weapon_sniper_awp_msg", ""); 
    CreateConVar("cv_weapon_sniper_military_msg", ""); 
    CreateConVar("cv_weapon_sniper_scout_msg", ""); 
    CreateConVar("cv_weapon_chainsaw_msg", ""); 
    CreateConVar("cv_weapon_pistol_magnum_msg", ""); 
    CreateConVar("cv_weapon_vomitjar_msg", ""); 
    CreateConVar("cv_weapon_defibrillator_msg", ""); 
    CreateConVar("cv_weapon_upgradepack_explosive_msg", ""); 
    CreateConVar("cv_weapon_upgradepack_incendiary_msg", ""); 
    CreateConVar("cv_weapon_adrenaline_msg", ""); 

    AutoExecConfig(true, "l4d2weaponmsg");

} 

public OnClientDisconnect(client) 
{ 
    if ( IsClientInGame(client) ) 
    { 
        SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponEquip) 
    } 
} 

public Action:OnWeaponEquip(client, weapon) 
{ 
    decl String:sWeapon[64]; 
    decl String:weaponCvar[64]; 
    decl String:msg[256]; 

    GetEdictClassname(weapon, sWeapon, sizeof(sWeapon)); 
    Format(weaponCvar, sizeof(weaponCvar), "cv_%s_msg", sWeapon);


    new Handle:g_hwCvar;
    g_hwCvar = FindConVar(weaponCvar);

    GetConVarString(g_hwCvar, msg, sizeof(msg));
    if (msg[0] != EOS) PrintHintText(client, "%s", msg);
    
    return Plugin_Continue; 
}  