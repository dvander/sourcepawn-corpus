
#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2"
#define MESS "\x04Weapon Cleanup \x01%t"



public Plugin:myinfo = 
{
	name = "SM Cleanup",
	author = "Franc1sco steam: franug",
	description = "Keeps the map clean of weapons lost",
	url = "http://steamcommunity.com/id/franug"
};



new Handle:Cvar_Repeticion;
new g_WeaponParent;
new Handle:Cvar_Interval;
new Handle:Cvar_msg_auto;
new Handle:Cvar_msg_cmd;
new Handle:Cvar_Timer;

public OnPluginStart()
{


	CreateConVar("sm_cleanup_version", PLUGIN_VERSION, "cleanup", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	Cvar_Repeticion = CreateConVar("sm_barrearmas_repeticion", "1", "If set to 0 then it will disable the auto barrearmas and will only be for admin command. Default: 1");

        Cvar_msg_auto = CreateConVar("sm_barrearmas_msg_auto", "1", "If set to 1 is the activated every time a message is passed on the broom by the repeater. Default: 0");

        Cvar_msg_cmd = CreateConVar("sm_barrearmas_msg_cmd", "1", "If set to 1 is then activated every time a message is passed on the broom admin command. Default: 1");

	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");

        RegAdminCmd("sm_cleanup", Command_Manual, ADMFLAG_SLAY);  // here you can set permissions have to have sm admin to run the command. Example: ADMFLAG_RCON or ADMFLAG_SLAY, etc.
        RegAdminCmd("sm_cleanup", Command_Manual, ADMFLAG_SLAY);  // aqui se puede ajustar que permisos tiene que tener el admin del sm para poder ejecutar el comando. Ejemplo: ADMFLAG_RCON o ADMFLAG_SLAY , etc 

	Cvar_Interval = CreateConVar("sm_barrearmas_interval", "10.0", "Determines every X seconds to remove the weapons falls. Default: 30.0 seconds");

        Cvar_Timer = CreateTimer(GetConVarFloat(Cvar_Interval), Repetidor, _, TIMER_REPEAT);

        HookConVarChange(Cvar_Interval, Cvar_Interval_Change);
        AutoExecConfig(true,"plugin.weaponcleanup");  
}

public Cvar_Interval_Change(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	KillTimer(Cvar_Timer);

	Cvar_Timer = CreateTimer(GetConVarFloat(Cvar_Interval), Repetidor, _, TIMER_REPEAT);
}

public Action:Command_Manual(client, args)
{

	new maxent = GetMaxEntities(), String:weapon[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ( ( StrContains(weapon, "weapon_molotov") != -1 
			|| StrContains(weapon, "weapon_anm14") != -1 
			|| StrContains(weapon, "weapon_c4_ied") != -1 
		  || StrContains(weapon, "weapon_c4_clicker") != -1 
		  || StrContains(weapon, "weapon_m18") != -1  
		  || StrContains(weapon, "weapon_tear_gas") != -1 
		  || StrContains(weapon, "weapon_impact_m67") != -1 
		  || StrContains(weapon, "weapon_f1") != -1  
		  || StrContains(weapon, "weapon_m67") != -1 
		  || StrContains(weapon, "weapon_law") != -1 
		  || StrContains(weapon, "weapon_rpg7") != -1  
		  || StrContains(weapon, "weapon_at4") != -1 
		  || StrContains(weapon, "weapon_grenadepistol") != -1 
		  || StrContains(weapon, "weapon_smoke_gun") != -1  
		  || StrContains(weapon, "weapon_flash_gun") != -1 
		  || StrContains(weapon, "weapon_p2a1") != -1 
		  || StrContains(weapon, "weapon_brassknuckles") != -1  
		  || StrContains(weapon, "weapon_Ninjato") != -1 
		  || StrContains(weapon, "weapon_NieR") != -1 
		  || StrContains(weapon, "weapon_parang") != -1  
		  || StrContains(weapon, "weapon_machete") != -1 
		  || StrContains(weapon, "weapon_gorkhas") != -1 
		  || StrContains(weapon, "weapon_knife") != -1  
		  || StrContains(weapon, "weapon_kabar") != -1  		  
		  || StrContains(weapon, "weapon_tanto") != -1 
		  || StrContains(weapon, "weapon_bayonet") != -1 
		  || StrContains(weapon, "weapon_gurkha") != -1 		  
		  || StrContains(weapon, "weapon_kimberdesertwarrior") != -1  
		  || StrContains(weapon, "weapon_fnp") != -1 
		  || StrContains(weapon, "weapon_fiveseven") != -1 
		  || StrContains(weapon, "weapon_cz75") != -1  
		  || StrContains(weapon, "weapon_glock18") != -1 
		  || StrContains(weapon, "weapon_waltherp99") != -1 
		  || StrContains(weapon, "weapon_hkusp") != -1  
		  || StrContains(weapon, "weapon_gsh") != -1 
		  || StrContains(weapon, "weapon_m93r") != -1 
		  || StrContains(weapon, "weapon_glock19") != -1  
		  || StrContains(weapon, "weapon_deagle") != -1 
		  || StrContains(weapon, "weapon_m45") != -1 
		  || StrContains(weapon, "weapon_m1911") != -1  
		  || StrContains(weapon, "weapon_mp443") != -1 
		  || StrContains(weapon, "weapon_sigp220") != -1 
		  || StrContains(weapon, "weapon_rpk") != -1  
		  || StrContains(weapon, "weapon_toz") != -1 
		  || StrContains(weapon, "weapon_saiga12auto") != -1 
		  || StrContains(weapon, "weapon_mk18_m0") != -1  
		  || StrContains(weapon, "weapon_nova") != -1 
		  || StrContains(weapon, "weapon_ak12u") != -1   
		  || StrContains(weapon, "weapon_sig553") != -1 
		  || StrContains(weapon, "weapon_mp5a4") != -1 
		  || StrContains(weapon, "weapon_ump45") != -1  
		  || StrContains(weapon, "weapon_saiga762") != -1 
		  || StrContains(weapon, "weapon_aek971") != -1 
		  || StrContains(weapon, "weapon_g3a4") != -1  
		  || StrContains(weapon, "weapon_m110") != -1 
		  || StrContains(weapon, "weapon_ar15") != -1 
		  || StrContains(weapon, "weapon_mg36") != -1   
		  || StrContains(weapon, "weapon_m4a1sopmod") != -1 
		  || StrContains(weapon, "weapon_sr25") != -1   
		  || StrContains(weapon, "weapon_remingtonmsr") != -1 
		  || StrContains(weapon, "weapon_svd") != -1 
		  || StrContains(weapon, "weapon_l118a1") != -1  
		  || StrContains(weapon, "weapon_cm901") != -1 
		  || StrContains(weapon, "weapon_sa80") != -1  
		  || StrContains(weapon, "weapon_m249") != -1 
		  || StrContains(weapon, "weapon_acr") != -1 
		  || StrContains(weapon, "weapon_g3a3") != -1  
		  || StrContains(weapon, "weapon_galil_sar") != -1 
		  || StrContains(weapon, "weapon_g36c") != -1 
		  || StrContains(weapon, "weapon_scar") != -1  
		  || StrContains(weapon, "weapon_mosin") != -1 
		  || StrContains(weapon, "weapon_m40a1") != -1 
		  || StrContains(weapon, "weapon_m1a1") != -1  
		  || StrContains(weapon, "weapon_fal") != -1 
		  || StrContains(weapon, "weapon_m14") != -1 
		  || StrContains(weapon, "weapon_akm") != -1  
		  || StrContains(weapon, "weapon_m84") != -1 
		  || StrContains(weapon, "weapon_galil") != -1 
		  || StrContains(weapon, "weapon_ak74") != -1  
		  || StrContains(weapon, "weapon_sks") != -1 
		  || StrContains(weapon, "weapon_l1a1") != -1 
		  || StrContains(weapon, "weapon_m4a1") != -1  
		  || StrContains(weapon, "weapon_m16a4") != -1 
		  || StrContains(weapon, "weapon_mini14") != -1 
		  || StrContains(weapon, "weapon_m1014") != -1 		  
		  || StrContains(weapon, "weapon_scar_H") != -1  
		  || StrContains(weapon, "weapon_mg36") != -1 																							      
			|| StrContains(weapon, "weapon_akm") != -1 
			|| StrContains(weapon, "weapon_rpg7") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 )
					RemoveEdict(i);
		}
	}	
        if (!GetConVarBool(Cvar_msg_cmd))
	{
		return Plugin_Continue;
	}
}

public Action:Repetidor(Handle:timer)
{
        if (!GetConVarBool(Cvar_Repeticion))
	{
		return Plugin_Continue;
	}

	new maxent = GetMaxEntities(), String:weapon[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ( ( StrContains(weapon, "weapon_molotov") != -1 
			|| StrContains(weapon, "weapon_anm14") != -1 
			|| StrContains(weapon, "weapon_c4_ied") != -1 
		  || StrContains(weapon, "weapon_m18") != -1  
		  || StrContains(weapon, "weapon_tear_gas") != -1 
		  || StrContains(weapon, "weapon_f1") != -1  
		  || StrContains(weapon, "weapon_law") != -1 
		  || StrContains(weapon, "weapon_rpg7") != -1  
		  || StrContains(weapon, "weapon_at4") != -1 
		  || StrContains(weapon, "weapon_smoke_gun") != -1  
		  || StrContains(weapon, "weapon_flash_gun") != -1 
		  || StrContains(weapon, "weapon_p2a1") != -1 
		  || StrContains(weapon, "weapon_brassknuckles") != -1  
		  || StrContains(weapon, "weapon_Ninjato") != -1 
		  || StrContains(weapon, "weapon_NieR") != -1 
		  || StrContains(weapon, "weapon_parang") != -1  
		  || StrContains(weapon, "weapon_machete") != -1 
		  || StrContains(weapon, "weapon_gorkhas") != -1 
		  || StrContains(weapon, "weapon_knife") != -1  
		  || StrContains(weapon, "weapon_kabar") != -1  		  
		  || StrContains(weapon, "weapon_tanto") != -1 
		  || StrContains(weapon, "weapon_bayonet") != -1 
		  || StrContains(weapon, "weapon_gurkha") != -1 		  
		  || StrContains(weapon, "weapon_kimberdesertwarrior") != -1  
		  || StrContains(weapon, "weapon_fnp") != -1 
		  || StrContains(weapon, "weapon_fiveseven") != -1 
		  || StrContains(weapon, "weapon_cz75") != -1  
		  || StrContains(weapon, "weapon_glock18") != -1 
		  || StrContains(weapon, "weapon_waltherp99") != -1 
		  || StrContains(weapon, "weapon_hkusp") != -1  
		  || StrContains(weapon, "weapon_gsh") != -1 
		  || StrContains(weapon, "weapon_m93r") != -1 
		  || StrContains(weapon, "weapon_glock19") != -1  
		  || StrContains(weapon, "weapon_deagle") != -1 
		  || StrContains(weapon, "weapon_m45") != -1 
		  || StrContains(weapon, "weapon_m1911") != -1  
		  || StrContains(weapon, "weapon_mp443") != -1 
		  || StrContains(weapon, "weapon_sigp220") != -1 
		  || StrContains(weapon, "weapon_rpk") != -1  
		  || StrContains(weapon, "weapon_toz") != -1 
		  || StrContains(weapon, "weapon_saiga12auto") != -1 
		  || StrContains(weapon, "weapon_mk18_m0") != -1  
		  || StrContains(weapon, "weapon_nova") != -1 
		  || StrContains(weapon, "weapon_ak12u") != -1   
		  || StrContains(weapon, "weapon_sig553") != -1 
		  || StrContains(weapon, "weapon_mp5a4") != -1 
		  || StrContains(weapon, "weapon_ump45") != -1  
		  || StrContains(weapon, "weapon_saiga762") != -1 
		  || StrContains(weapon, "weapon_aek971") != -1 
		  || StrContains(weapon, "weapon_g3a4") != -1  
		  || StrContains(weapon, "weapon_m110") != -1 
		  || StrContains(weapon, "weapon_ar15") != -1 
		  || StrContains(weapon, "weapon_mg36") != -1   
		  || StrContains(weapon, "weapon_m4a1sopmod") != -1 
		  || StrContains(weapon, "weapon_sr25") != -1   
		  || StrContains(weapon, "weapon_remingtonmsr") != -1 
		  || StrContains(weapon, "weapon_svd") != -1 
		  || StrContains(weapon, "weapon_l118a1") != -1  
		  || StrContains(weapon, "weapon_cm901") != -1 
		  || StrContains(weapon, "weapon_sa80") != -1  
		  || StrContains(weapon, "weapon_m249") != -1 
		  || StrContains(weapon, "weapon_acr") != -1 
		  || StrContains(weapon, "weapon_g3a3") != -1  
		  || StrContains(weapon, "weapon_galil_sar") != -1 
		  || StrContains(weapon, "weapon_g36c") != -1 
		  || StrContains(weapon, "weapon_scar?_L") != -1  
		  || StrContains(weapon, "weapon_mosin") != -1 
		  || StrContains(weapon, "weapon_m40a1") != -1 
		  || StrContains(weapon, "weapon_m1a1") != -1  
		  || StrContains(weapon, "weapon_fal") != -1 
		  || StrContains(weapon, "weapon_m14") != -1 
		  || StrContains(weapon, "weapon_akm") != -1  
		  || StrContains(weapon, "weapon_m84") != -1 
		  || StrContains(weapon, "weapon_galil") != -1 
		  || StrContains(weapon, "weapon_ak74") != -1  
		  || StrContains(weapon, "weapon_sks") != -1 
		  || StrContains(weapon, "weapon_l1a1") != -1 
		  || StrContains(weapon, "weapon_m4a1") != -1  
		  || StrContains(weapon, "weapon_m16a4") != -1 
		  || StrContains(weapon, "weapon_mini14") != -1 
		  || StrContains(weapon, "weapon_m1014") != -1 		   
		  || StrContains(weapon, "weapon_mg36") != -1 																							      
			|| StrContains(weapon, "weapon_akm") != -1 
			|| StrContains(weapon, "weapon_rpg7") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 )
					RemoveEdict(i);
		}
	}
        if (!GetConVarBool(Cvar_msg_auto))
	{
		return Plugin_Continue;
	}
}

