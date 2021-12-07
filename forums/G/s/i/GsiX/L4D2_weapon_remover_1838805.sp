#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3"

public Plugin:myinfo = 
{
	name		= " L4D2 Weapon Remover",
	author		= " GsiX ",
	description	= " Remove Item Spawn On Map ",
	version		= PLUGIN_VERSION,
	url			= ""
}

new Handle:WRenabled;
new Handle:removeAmmoUpgrades;
new Handle:removeChainsaws;
new Handle:removeLauncher;
new Handle:removeM60;
new Handle:removeLaser;
new Handle:removeHealthKit;
new Handle:removeMedKit;
new Handle:removeThrowable;
new Handle:removeAmmoPile;
new Handle:removeT3;
new Handle:removeT2;
new Handle:removeT1;
new Handle:removeMelee;
new Handle:removeGascan;
new Handle:removePistol;

new bool:Remove = false;

public OnPluginStart()
{
	CreateConVar("l4d2_wr_version", PLUGIN_VERSION, "Plugin Version.", FCVAR_PLUGIN);
	WRenabled			= CreateConVar("l4d2_wr_enabled",			"1", "Enable Plugin.", FCVAR_PLUGIN);
	removeAmmoUpgrades	= CreateConVar("l4d2_wr_ammo_upgrades",		"1", "remove upgrade explosive, incendiary ammo. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeChainsaws		= CreateConVar("l4d2_wr_chainsaw",			"1", "Remove Chainsaws. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeLauncher		= CreateConVar("l4d2_wr_launcher",			"1", "Remove grenade launchers. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeM60			= CreateConVar("l4d2_wr_m60",				"1", "Remove M60 rifles. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeLaser			= CreateConVar("l4d2_wr_laser",				"0", "Remove Laser Sights. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeHealthKit		= CreateConVar("l4d2_wr_health_kit",		"1", "Remove pills, adrn, defb. (0=Disable, 1= Enable)", FCVAR_PLUGIN);
	removeMedKit		= CreateConVar("l4d2_wr_med_kit",			"0", "Remove Med kit. (0=Disable, 1= Enable)", FCVAR_PLUGIN);
	removeAmmoPile		= CreateConVar("l4d2_wr_ammo_pile",			"0", "Remove ammo pile. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeThrowable		= CreateConVar("l4d2_wr_throwable",			"1", "Remove throwable item eg. molotov. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeT3			= CreateConVar("l4d2_wr_t3",				"1", "Remove all T3 weapon. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeT2			= CreateConVar("l4d2_wr_t2",				"1", "Remove all T2 weapon. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeT1			= CreateConVar("l4d2_wr_t1",				"1", "Remove all T1 weapon. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeMelee			= CreateConVar("l4d2_wr_melee",				"1", "Remove All Melee weapon. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeGascan		= CreateConVar("l4d2_wr_cane",				"1", "Remove gascan etc. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removePistol		= CreateConVar("l4d2_wr_pistol",			"0", "Remove pistol and magnum. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	AutoExecConfig( true, "l4d2_weapon_remover" );

	HookEvent( "player_spawn",			EVENT_Remove );
	HookEvent( "round_start",			EVENT_Reset );
	HookEvent( "round_end",				EVENT_Reset );
}

public OnMapStart()
{
	Remove = false;
}

public EVENT_Remove( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( WRenabled ) == 1 && !Remove )
	{
		Remove = true;
		CreateTimer( 1.0, RemoveWeaponDelay, _, TIMER_FLAG_NO_MAPCHANGE );
	}
}

public EVENT_Reset( Handle:event, const String:name[], bool:dontBroadcast )
{
	Remove = false;
}

public Action:RemoveWeaponDelay( Handle:timer )
{
	new EntCount = GetEntityCount();
	decl String:EdictName[128];
	decl String:ModelName[258];
	
	for ( new i = MaxClients; i <= EntCount; i++ )
	{
		if ( !IsValidEntity( i )) continue;
		GetEntityClassname( i, EdictName, sizeof( EdictName ));
		
		//remove heal kits
		if ( GetConVarInt( removeHealthKit ) == 1 )
		{
			if(( StrEqual( EdictName, "weapon_pain_pills", false ))			||
			( StrEqual( EdictName, "weapon_pain_pills_spawn", false ))		||
			( StrEqual( EdictName, "weapon_adrenaline", false ))			||
			( StrEqual( EdictName, "weapon_adrenaline_spawn", false ))		||
			( StrEqual( EdictName, "weapon_defibrillator", false ))			||
			( StrEqual( EdictName, "weapon_defibrillator_spawn", false )))
			{
				DestroyThisItem( i );
			}
		}
		
		//remove Med kits
		if ( GetConVarInt( removeMedKit ) == 1 )
		{
			if (( StrEqual( EdictName, "weapon_first_aid_kit", false )) ||
			( StrEqual( EdictName, "weapon_first_aid_kit_spawn", false )))
			{
				DestroyThisItem( i );
			}
		}
		
		//remove explosive and incendiary ammo
		if ( GetConVarInt( removeAmmoUpgrades ) == 1 )
		{
			if (( StrEqual( EdictName, "weapon_upgradepack_explosive", false )) 	||
			( StrEqual( EdictName, "weapon_upgradepack_explosive_spawn", false )) 	||
			( StrEqual( EdictName, "weapon_upgradepack_incendiary", false ))		||
			( StrEqual( EdictName, "weapon_upgradepack_incendiary_spawn", false )))
			{
				DestroyThisItem( i );
			}
		}
		
		//remove ammo pile
		if( GetConVarInt( removeAmmoPile ) == 1 )
		{
			if( StrEqual( EdictName, "weapon_ammo_spawn", false ))
			{
				DestroyThisItem( i );
			}
		}
		
		//remove chainsaws
		if ( GetConVarInt( removeChainsaws ) == 1 )
		{
			if (( StrEqual( EdictName, "weapon_chainsaw", false ))	||
			( StrEqual( EdictName, "weapon_chainsaw_spawn", false )))
			{
				DestroyThisItem( i );
			}
		}
		
		//remove grenade launchers
		if ( GetConVarInt( removeLauncher ) == 1 )
		{
			if (( StrEqual( EdictName, "weapon_grenade_launcher", false ))	||
			( StrEqual( EdictName, "weapon_grenade_launcher_spawn", false )))
			{
				DestroyThisItem( i );
			}
		}
		
		//remove m60 weapon
		if ( GetConVarInt( removeM60 ) == 1 )
		{
			if (( StrEqual( EdictName, "weapon_rifle_m60", false))	||
			( StrEqual( EdictName, "weapon_rifle_m60_spawn", false)))
			{
				DestroyThisItem( i );
			}
		}
		
		//remove throwable
		if ( GetConVarInt( removeThrowable ) == 1 )
		{
			if (( StrEqual( EdictName, "weapon_pipe_bomb", false))			||
			( StrEqual( EdictName, "weapon_pipe_bomb_spawn", false))		||
			( StrEqual( EdictName, "weapon_molotov", false))				||
			( StrEqual( EdictName, "weapon_molotov_spawn", false))			||
			( StrEqual( EdictName, "weapon_vomitjar", false))				||
			( StrEqual( EdictName, "weapon_vomitjar_spawn", false)))
			{
				DestroyThisItem( i );
			}
		}
		
		//remove T3 ewapon
		if ( GetConVarInt( removeT3 ) == 1 )
		{
			if (( StrEqual( EdictName, "weapon_sniper_awp", false ))		||
			( StrEqual( EdictName, "weapon_sniper_awp_spawn", false ))		||
			( StrEqual( EdictName, "weapon_sniper_scout", false ))			||
			( StrEqual( EdictName, "weapon_sniper_scout_spawn", false ))	||
			( StrEqual( EdictName, "weapon_shotgun_spas", false ))			||
			( StrEqual( EdictName, "weapon_shotgun_spas_spawn", false ))	||
			( StrEqual( EdictName, "weapon_spawn", false )))
			{
				DestroyThisItem( i );
			}
		}
		
		//remove T2 weapon
		if ( GetConVarInt( removeT2 ) == 1 )
		{
			if (( StrEqual( EdictName, "weapon_rifle", false ))				||
			( StrEqual( EdictName, "weapon_rifle_spawn", false ))			||
			( StrEqual( EdictName, "weapon_rifle_ak47", false ))			||
			( StrEqual( EdictName, "weapon_rifle_ak47_spawn", false ))		||
			( StrEqual( EdictName, "weapon_rifle_desert", false ))			||
			( StrEqual( EdictName, "weapon_rifle_desert_spawn", false ))	||
			( StrEqual( EdictName, "weapon_autoshotgun", false ))			||
			( StrEqual( EdictName, "weapon_autoshotgun_spawn", false ))		||
			( StrEqual( EdictName, "weapon_sniper_military", false ))		||
			( StrEqual( EdictName, "weapon_spawn", false ))					||
			( StrEqual( EdictName, "weapon_sniper_military_spawn", false )))
			{
				DestroyThisItem( i );
			}
		}		
		
		//remove T1 weapon
		if ( GetConVarInt( removeT1 ) == 1 )
		{
			if (( StrEqual( EdictName, "weapon_hunting_rifle", false ))		||
			( StrEqual( EdictName, "weapon_hunting_rifle_spawn", false ))	||
			( StrEqual( EdictName, "weapon_shotgun_chrome", false ))		||
			( StrEqual( EdictName, "weapon_shotgun_chrome_spawn", false ))	||
			( StrEqual( EdictName, "weapon_pumpshotgun", false ))			||
			( StrEqual( EdictName, "weapon_pumpshotgun_spawn", false ))		||
			( StrEqual( EdictName, "weapon_smg", false ))					||
			( StrEqual( EdictName, "weapon_smg_spawn", false ))				||
			( StrEqual( EdictName, "weapon_smg_silenced", false ))			||
			( StrEqual( EdictName, "weapon_smg_silenced_spawn", false ))	||
			( StrEqual( EdictName, "weapon_smg_mp5", false ))				||
			( StrEqual( EdictName, "weapon_smg_mp5_spawn", false )))
			{
				DestroyThisItem( i );
			}
		}
		
		//remove Melee weapon
		if ( GetConVarInt( removeMelee ) == 1 )
		{
			if (( StrEqual(EdictName, "weapon_fireaxe", false))				||
			( StrEqual(EdictName, "weapon_fireaxe_spawn", false))			||
			( StrEqual( EdictName, "weapon_frying_pan", false))				||
			( StrEqual( EdictName, "weapon_frying_pan_spawn", false))		||
			( StrEqual( EdictName, "weapon_machete", false))				||
			( StrEqual( EdictName, "weapon_machete_spawn", false))			||
			( StrEqual( EdictName, "weapon_baseball_bat", false))			||
			( StrEqual( EdictName, "weapon_baseball_bat_spawn", false))		||
			( StrEqual( EdictName, "weapon_crowbar", false))				||
			( StrEqual( EdictName, "weapon_crowbar_spawn", false))			||
			( StrEqual( EdictName, "weapon_cricket_bat", false))			||
			( StrEqual( EdictName, "weapon_cricket_bat_spawn", false))		||
			( StrEqual( EdictName, "weapon_katana", false))					||
			( StrEqual( EdictName, "weapon_katana_spawn", false))			||
			( StrEqual( EdictName, "weapon_electric_guitar", false))		||
			( StrEqual( EdictName, "weapon_electric_guitar_spawn", false))	||
			( StrEqual( EdictName, "weapon_hunting_knife", false))			||
			( StrEqual( EdictName, "weapon_hunting_knife_spawn", false))	||
			( StrEqual( EdictName, "weapon_golfclub", false))				||
			( StrEqual( EdictName, "weapon_golfclub_spawn", false))			||
			( StrEqual( EdictName, "weapon_riotshield", false))				||
			( StrEqual( EdictName, "weapon_riotshield_spawn", false))		||
			( StrEqual( EdictName, "weapon_tonfa", false))					||
			( StrEqual( EdictName, "weapon_tonfa_spawn", false))			||
			( StrEqual( EdictName, "weapon_melee", false))					||
			( StrEqual( EdictName, "weapon_melee_spawn", false)))
			{
				DestroyThisItem( i );
			}
		} 
		
		//remove laser sights
		if ( GetConVarInt( removeLaser ) == 1 )
		{
			if ( StrEqual( EdictName, "upgrade_laser_sight", false )		||
			StrEqual( EdictName, "weapon_upgrade_laser_sight", false )		||
			StrEqual( EdictName, "upgrade_laser_sight_spawn", false )		||
			StrEqual( EdictName, "weapon_upgrade_laser_sight_spawn", false ))
			{
				DestroyThisItem( i );
			}
		}
		
		// remove gascan etc..
		if ( GetConVarInt( removeGascan ) == 1 )
		{
			if ( StrEqual( EdictName, "prop_physics", false ))
			{
				GetEntPropString( i, Prop_Data, "m_ModelName", ModelName, sizeof( ModelName ));
				if (( StrEqual( ModelName, "models/props_junk/propanecanister001a.mdl", false ))	||
				( StrEqual( ModelName, "models/props_junk/explosive_box001.mdl", false ))			||
				( StrEqual( ModelName, "models/props_equipment/oxygentank01.mdl", false ))			||
				( StrEqual( ModelName, "models/props_junk/gascan001a.mdl", false )))
				{
					DestroyThisItem( i );
				}
			}
		}
		
		// remove pistol and magnum
		if ( GetConVarInt( removePistol ) == 1 )
		{
			if ( StrEqual( EdictName, "weapon_pistol", false ) 			||
			StrEqual( EdictName, "weapon_pistol_spawn", false )			||
			StrEqual( EdictName, "weapon_pistol_magnum", false )		||
			StrEqual( EdictName, "weapon_pistol_magnum_spawn", false ))
			{
				DestroyThisItem( i );
			}
		}
	}
}

stock DestroyThisItem( entity )
{
	if ( IsValidEntity( entity ))
	{
		if ( GetEntPropEnt( entity, Prop_Data, "m_hOwnerEntity" ) == -1 )
		{
			AcceptEntityInput( entity, "Kill" );
		}
	}
}

