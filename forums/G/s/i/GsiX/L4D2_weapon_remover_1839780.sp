#pragma semicolon 1
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
new Handle:removeThrowable;
new Handle:removeAmmoPile;
new Handle:removeT3;
new Handle:removeT2;
new Handle:removeT1;
new Handle:removeMelee;
new Handle:removeGascan;
new Handle:removePistol;
new Handle:roundEnd;
new Handle:roundRoundHp;
new Handle:roundincap;
new Handle:safeRoomMedKit;
new Handle:outDoorMedKit;
new Handle:finaleMedKit;

new bool:Remove = false;
new bool:Remove2 = false;

new bool:Ref_1 = false;
new bool:Ref_2 = false;
new bool:Ref_3 = false;

new Float:worldRef1[3];
new Float:worldRef2[3];
new Float:worldRef3[3];

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
	removeAmmoPile		= CreateConVar("l4d2_wr_ammo_pile",			"0", "Remove ammo pile. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeThrowable		= CreateConVar("l4d2_wr_throwable",			"1", "Remove throwable item eg. molotov. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeT3			= CreateConVar("l4d2_wr_t3",				"1", "Remove all T3 weapon. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeT2			= CreateConVar("l4d2_wr_t2",				"1", "Remove all T2 weapon. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeT1			= CreateConVar("l4d2_wr_t1",				"1", "Remove all T1 weapon. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeMelee			= CreateConVar("l4d2_wr_melee",				"1", "Remove All Melee weapon. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeGascan		= CreateConVar("l4d2_wr_cane",				"1", "Remove gascan etc. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removePistol		= CreateConVar("l4d2_wr_pistol",			"0", "Remove pistol and magnum. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	roundEnd			= CreateConVar("l4d2_wr_round",				"1", "0:Off, 1:On, If on, survivor that survive the round will be reset for the next level", FCVAR_NOTIFY | FCVAR_PLUGIN);
	roundRoundHp		= CreateConVar("l4d2_wr_round_hp",			"30", "0:Off, 1 and above, How much HP we give him and we only give him HP if his HP below this ('l4d2_wr_round must' be on).", FCVAR_NOTIFY | FCVAR_PLUGIN);
	roundincap			= CreateConVar("l4d2_wr_round_incap",		"1", "0:Off, 1:On, If on, player incap count will be reset ('l4d2_wr_round' must be on).", FCVAR_NOTIFY | FCVAR_PLUGIN);
	safeRoomMedKit		= CreateConVar("l4d2_wr_saferoom_medkit",	"1", "0:Off, 1:On, If on, safe room med kit will be remove (1st map starting point count as safe room >_<).", FCVAR_NOTIFY | FCVAR_PLUGIN);
	outDoorMedKit		= CreateConVar("l4d2_wr_outdoor_medkit",	"1", "0:Off, 1:On, If on, out door med kit will be remove.", FCVAR_NOTIFY | FCVAR_PLUGIN);
	finaleMedKit		= CreateConVar("l4d2_wr_finale_medkit",		"1", "0:Off, 1:On, If on, finale med kit will be remove ( saferoom med kit dosen't count).", FCVAR_NOTIFY | FCVAR_PLUGIN);
	
	AutoExecConfig( true, "l4d2_weapon_remover" );

	HookEvent( "player_spawn",			EVENT_PlayerSpawn );
	HookEvent( "round_start",			EVENT_RoundStart );
	HookEvent( "round_end",				EVENT_RoundEnd );
	HookEvent( "map_transition",		EVENT_MapTransition, EventHookMode_Pre);
	
	RegAdminCmd( "check_myposition",	CommandCheck, ADMFLAG_ROOT );
}

public OnMapStart()
{
	Remove = false;
	Remove2 = false;
}

public Action:CommandCheck( client, args )
{
	if ( IsValidClient( client ))
	{
		decl String:nnnnnnn[64];
		decl String:zzzzzz[64];
		decl Float:ppppp[3];
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", ppppp );
		GetCurrentMap( zzzzzz, sizeof( zzzzzz ));
		PrintToServer( "----- %s -----", zzzzzz );
		PrintToServer( "new Float:medPos[3] = { %0.4f, %0.4f, %0.4f };", ppppp[0], ppppp[1], ppppp[2] );
		new aim = GetClientAimTarget( client, false );
		if ( aim != -1 )
		{
			GetEntityClassname( aim, nnnnnnn, sizeof( nnnnnnn ));
			GetEntPropVector( aim, Prop_Send, "m_vecOrigin", ppppp );
			PrintToServer( "----- Entity name = %s -----", nnnnnnn );
			PrintToServer( "----- Entity Pos[3] = { %0.4f, %0.4f, %0.4f }; -----", ppppp[0], ppppp[1], ppppp[2] );
		}
	}
	return Plugin_Handled;
}

public EVENT_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( WRenabled ) == 1 && !Remove2 )
	{
		new client = GetClientOfUserId( GetEventInt( event, "userid" ));
		if ( client > 0 && IsClientConnected( client ) && IsClientInGame( client ) && !IsFakeClient( client ))
		{
			Remove2 = true;
			CreateTimer( 0.1, RemoveWeaponDelay, _, TIMER_FLAG_NO_MAPCHANGE );
		}
	}
}

public EVENT_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( WRenabled ) == 1 && !Remove )
	{
		Remove = true;
		CreateTimer( 0.2, RemoveWeaponDelay, _, TIMER_FLAG_NO_MAPCHANGE );
	}
}

public EVENT_RoundEnd( Handle:event, const String:name[], bool:dontBroadcast )
{
	Remove = false;
	Remove2 = false;
}

public EVENT_MapTransition( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( GetConVarInt( roundEnd ) < 1 ) return;
	
	new i;
	new inc;
	new hea;
	new Float:buf;
	new Health	= GetConVarInt( roundRoundHp );
	new Incap	= GetConVarInt( roundincap );
	
	for ( i = 1; i <= MaxClients; i++ )
	{
		if ( IsValidClient( i ))
		{
			if ( Health > 0 && GetEntProp( i, Prop_Data, "m_iHealth" ) < Health )
			{
				if ( Incap == 0 )
					inc = GetEntProp( i, Prop_Send, "m_currentReviveCount" );
				HealthCheat( i );
				SetEntProp( i, Prop_Data, "m_iHealth", Health );
				SetEntProp( i, Prop_Send, "m_bIsOnThirdStrike", 0 );
				if ( Health > 30 )
					SetEntPropFloat( i, Prop_Send, "m_healthBuffer", 0.0 );
				if ( Incap == 0 )
					SetEntProp( i, Prop_Send, "m_currentReviveCount", ( inc - 1 ));
			}
			
			if ( Incap > 0 )
			{
				if ( Health == 0 )
				{
					hea = GetEntProp( i, Prop_Data, "m_iHealth" );
					buf = GetEntPropFloat( i, Prop_Send, "m_healthBuffer" );
					HealthCheat( i );
					SetEntProp( i, Prop_Send, "m_bIsOnThirdStrike", 0 );
					SetEntProp( i, Prop_Data, "m_iHealth", hea );
					SetEntPropFloat( i, Prop_Send, "m_healthBuffer", buf );
				}
				SetEntProp( i, Prop_Send, "m_currentReviveCount", 0 );
			}
		}
	}
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
	RemoveMedKit();
}

RemoveMedKit()
{
	new ent = -1;
	decl Float:medPoss[3];
	
	// safe room med kit
	FindReference( worldRef1, worldRef2 );
	if ( GetConVarInt( safeRoomMedKit ) > 0 )
	{
		while (( ent = FindEntityByClassname( ent, "weapon_first_aid_kit" )) != -1 )
		{
			GetEntPropVector( ent, Prop_Send, "m_vecOrigin", medPoss );
			if ( Ref_1 && GetVectorDistance( worldRef1, medPoss ) < 200.0 )
			{
				if ( IsValidEntity( ent ))
				{
					DestroyThisItem( ent );
				}
			}
			if ( Ref_2 && GetVectorDistance( worldRef2, medPoss ) < 200.0 )
			{
				if ( IsValidEntity( ent ))
				{
					DestroyThisItem( ent );
				}
			}
		}
		
		ent = -1;
		while (( ent = FindEntityByClassname( ent, "weapon_first_aid_kit_spawn" )) != -1 )
		{
			GetEntPropVector( ent, Prop_Send, "m_vecOrigin", medPoss );
			if ( Ref_1 && GetVectorDistance( worldRef1, medPoss ) < 200.0 )
			{
				if ( IsValidEntity( ent ))
				{
					DestroyThisItem( ent );
				}
			}
			if ( Ref_2 && GetVectorDistance( worldRef2, medPoss ) < 200.0 )
			{
				if ( IsValidEntity( ent ))
				{
					DestroyThisItem( ent );
				}
			}
		}
	}
	
	// out door med kit
	if ( GetConVarInt( outDoorMedKit ) > 0 )
	{
		new setting;
		if ( Ref_1 && Ref_2 )		setting = 1;
		else if ( Ref_1 && !Ref_2 )	setting = 2;
		else if ( !Ref_1 && Ref_2 )	setting = 3;
			
		ent = -1;
		while (( ent = FindEntityByClassname( ent, "weapon_first_aid_kit" )) != -1 )
		{
			GetEntPropVector( ent, Prop_Send, "m_vecOrigin", medPoss );
			
			switch ( setting )
			{
				case 1:
				{
					if ( GetVectorDistance( worldRef1, medPoss ) > 200.0 && GetVectorDistance( worldRef2, medPoss ) > 200.0 ) DestroyThisItem( ent );
				}
				case 2:
				{
					if ( GetVectorDistance( worldRef1, medPoss ) > 200.0 ) DestroyThisItem( ent );
				}
				case 3:
				{
					if ( GetVectorDistance( worldRef2, medPoss ) > 200.0 ) DestroyThisItem( ent );
				}
			}
		}
		
		ent = -1;
		while (( ent = FindEntityByClassname( ent, "weapon_first_aid_kit" )) != -1 )
		{
			GetEntPropVector( ent, Prop_Send, "m_vecOrigin", medPoss );
			
			switch ( setting )
			{
				case 1:
				{
					if ( GetVectorDistance( worldRef1, medPoss ) > 200.0 && GetVectorDistance( worldRef2, medPoss ) > 200.0 ) DestroyThisItem( ent );
				}
				case 2:
				{
					if ( GetVectorDistance( worldRef1, medPoss ) > 200.0 ) DestroyThisItem( ent );
				}
				case 3:
				{
					if ( GetVectorDistance( worldRef2, medPoss ) > 200.0 ) DestroyThisItem( ent );
				}
			}
		}
	}
	
	// finale med kit
	FindFinaleReference( worldRef2, worldRef3 );
	if ( GetConVarInt( finaleMedKit ) > 0 )
	{
		ent = -1;
		while (( ent = FindEntityByClassname( ent, "weapon_first_aid_kit" )) != -1 )
		{
			GetEntPropVector( ent, Prop_Send, "m_vecOrigin", medPoss );
			if ( Ref_2 && GetVectorDistance( worldRef2, medPoss ) < 200.0 )
			{
				if ( IsValidEntity( ent ))
				{
					DestroyThisItem( ent );
				}
			}
			if ( Ref_3 && GetVectorDistance( worldRef3, medPoss ) < 200.0 )
			{
				if ( IsValidEntity( ent ))
				{
					DestroyThisItem( ent );
				}
			}
		}
		ent = -1;
		while (( ent = FindEntityByClassname( ent, "weapon_first_aid_kit_spawn" )) != -1 )
		{
			GetEntPropVector( ent, Prop_Send, "m_vecOrigin", medPoss );
			if ( Ref_2 && GetVectorDistance( worldRef2, medPoss ) < 200.0 )
			{
				if ( IsValidEntity( ent ))
				{
					DestroyThisItem( ent );
				}
			}
			if ( Ref_3 && GetVectorDistance( worldRef3, medPoss ) < 200.0 )
			{
				if ( IsValidEntity( ent ))
				{
					DestroyThisItem( ent );
				}
			}
		}
	}
}

FindReference( Float:refPos1[3], Float:refPos2[3] )
{
	Ref_1 = false;
	Ref_2 = false;
	
	refPos1[0] = refPos2[0] = 0.0;
	refPos1[1] = refPos2[1] = 0.0;
	refPos1[2] = refPos2[2] = 0.0;
	
	decl String:mapName2[128];
	GetCurrentMap( mapName2, sizeof( mapName2 ));

	if ( StrEqual( mapName2, "c1m1_hotel", false ))
	{
		new Float:medPos1[3] = { 430.2816, 5741.2456, 2882.9821 };
		new Float:medPos2[3] = { 2051.4218, 4312.6655, 1214.2247 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c1m2_streets", false ))
	{
		new Float:medPos1[3] = { 2423.1342, 4968.8061, 478.2246 };
		new Float:medPos2[3] = { -7685.4575, -4718.5151, 419.2512 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c1m3_mall", false ))
	{
		new Float:medPos1[3] = { 6522.2001, -1459.3996, 59.0015 };
		new Float:medPos2[3] = { -2211.9687, -4660.6655, 571.2263 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c1m4_atrium", false ))
	{
		new Float:medPos1[3] = { -2203.1791, -4667.7788, 571.2263 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		Ref_1 = true;
	}

	else if ( StrEqual( mapName2, "c2m1_highway", false ))
	{
		new Float:medPos1[3] = { 10696.4531, 7862.8676, -541.4426 };
		new Float:medPos2[3] = { -821.5376, -2489.2290, -1048.7677 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c2m2_fairgrounds", false ))
	{
		new Float:medPos1[3] = { 1713.1789, 2795.4055, 39.2322 };
		new Float:medPos2[3] = { -4824.8559, -5400.7700, -28.7677 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c2m3_coaster", false ))
	{
		new Float:medPos1[3] = { 4070.1054, 2150.7971, -28.7677 };
		new Float:medPos2[3] = { -5449.6059, 1933.9711, 4.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c2m4_barns", false ))
	{
		new Float:medPos1[3] = { 2915.9538, 3857.6252, -187.9687 };
		new Float:medPos2[3] = { -672.7420, 2232.3637, -220.9987 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c2m5_concert", false ))
	{
		new Float:medPos1[3] = { -663.2974, 2233.2106, -220.9987 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		Ref_1 = true;
	}
	
	else if ( StrEqual( mapName2, "c3m1_plankcountry", false ))
	{
		new Float:medPos1[3] = { -12495.5498, 10526.3691, 244.8933 };
		new Float:medPos2[3] = { -2695.2988, 563.7081, 56.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c3m2_swamp", false ))
	{
		new Float:medPos1[3] = { -8199.3046, 7624.5161, 12.0312 };
		new Float:medPos2[3] = { 7598.6992, -1032.0473, 136.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c3m3_shantytown", false ))
	{
		new Float:medPos1[3] = { -5719.1552, 2039.9526, 136.0312 };
		new Float:medPos2[3] = { 5093.1298, -3716.1313, 350.7612 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c3m4_plantation", false ))
	{
		new Float:medPos1[3] = { -5149.6201, -1604.1312, -96.8117 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		Ref_1 = true;
	}

	else if ( StrEqual( mapName2, "c4m1_milltown_a", false ))
	{
		new Float:medPos1[3] = { -6118.3432, 7488.1450, 104.0312 };
		new Float:medPos2[3] = { 4120.2343, -1493.1767, 232.2812 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c4m2_sugarmill_a", false ))
	{
		new Float:medPos1[3] = { 3875.3374, -1638.6550, 232.5312 };
		new Float:medPos2[3] = { -1798.1179, -13757.4462, 130.2812 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c4m3_sugarmill_b", false ))
	{
		new Float:medPos1[3] = { -1796.2554, -13762.8955, 130.0312 };
		new Float:medPos2[3] = { 3864.0307, -1644.9687, 232.2812 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c4m4_milltown_b", false ))
	{
		new Float:medPos1[3] = { 4118.3129, -1516.0693, 232.2812 };
		new Float:medPos2[3] = { -3374.4980, 7798.7426, 120.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c4m5_milltown_escape", false ))
	{
		new Float:medPos1[3] = { -3387.6918, 7805.1162, 120.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		Ref_1 = true;
	}

	else if ( StrEqual( mapName2, "c5m1_waterfront", false ))
	{
		new Float:medPos1[3] = { 735.9216, 714.9528, -481.9687 };
		new Float:medPos2[3] = { -4353.5029, -1167.1304, -343.9687 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c5m2_park", false ))
	{
		new Float:medPos1[3] = { -4374.1728, -1157.0118, -343.9687 };
		new Float:medPos2[3] = { -9831.8398, -8134.9975, -255.9687 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c5m3_cemetery", false ))
	{
		new Float:medPos1[3] = { 6291.2685, 8262.6914, 0.0312 };
		new Float:medPos2[3] = { 7498.1782, -9648.0468, 104.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c5m4_quarter", false ))
	{
		new Float:medPos1[3] = { -3036.9602, 4807.9526, 68.0312 };
		new Float:medPos2[3] = { 1570.6762, -3654.2966, 64.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c5m5_bridge", false ))
	{
		new Float:medPos1[3] = { -11906.1142, 5712.7485, 128.0312 };	// safe room finale1
		new Float:medPos2[3] = { -11929.2734, 5945.9624, 512.0312 };	// safe room finale2
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	
	else if ( StrEqual( mapName2, "c6m1_riverbank", false ))
	{
		new Float:medPos1[3] = { 931.1972, 3811.5063, 94.0298 };
		new Float:medPos2[3] = { -4144.5776, 1444.1317, 728.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c6m2_bedlam", false ))
	{
		new Float:medPos1[3] = { 3064.6887, -1163.1391, -295.9687 };
		new Float:medPos2[3] = { 11371.9687, 4917.0825, -631.9687 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c6m3_port", false ))
	{
		new Float:medPos1[3] = { -2296.0312, -578.6568, -255.9687 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		Ref_1 = true;
	}

	else if ( StrEqual( mapName2, "c7m1_docks", false ))
	{
		new Float:medPos1[3] = { 13549.7265, 2158.4687, -89.5687 };
		new Float:medPos2[3] = { 1910.4873, 2370.7141, 176.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c7m2_barge", false ))
	{
		new Float:medPos1[3] = { 10728.7480, 2369.2304, 176.0312 };
		new Float:medPos2[3] = { -11261.7529, 3107.6208, 176.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c7m3_port", false ))
	{
		new Float:medPos1[3] = { 994.0950, 3236.4074, 168.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		Ref_1 = true;
	}
	
	else if ( StrEqual( mapName2, "c8m1_apartment", false ))
	{
		new Float:medPos1[3] = { 1902.5856, 891.0704, 475.0312 };
		new Float:medPos2[3] = { 2908.7153, 2928.8518, -239.9687 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c8m2_subway", false ))
	{
		new Float:medPos1[3] = { 2921.1047, 2999.6994, 16.0312 };
		new Float:medPos2[3] = { 10974.9335, 4672.7607, 16.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c8m3_sewers", false ))
	{
		new Float:medPos1[3] = { 10957.3652, 4672.7607, 16.0312 };
		new Float:medPos2[3] = { 12312.5605, 12276.7021, 16.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c8m4_interior", false ))
	{
		new Float:medPos1[3] = { 12319.3574, 12271.5664, 16.0312 };
		new Float:medPos2[3] = { 11329.5976, 14973.2138, 5536.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c8m5_rooftop", false ))
	{
		new Float:medPos1[3] = { 5312.9536, 8470.5966, 5536.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		Ref_1 = true;
	}

	else if ( StrEqual( mapName2, "c9m1_alleys", false ))
	{
		new Float:medPos1[3] = { -9859.0146, -8713.4042, -5.8110 };
		new Float:medPos2[3] = { 194.4359, -1355.2963, -175.9687 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c9m2_lots", false ))
	{
		new Float:medPos1[3] = { 193.9082, -1345.4185, -175.9687 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		Ref_1 = true;
	}

	else if ( StrEqual( mapName2, "c10m1_caves", false ))
	{
		new Float:medPos1[3] = { -11759.5029, -14640.6484, -201.0613 };
		new Float:medPos2[3] = { -10757.0371, -4919.9360, 318.2246 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c10m2_drainage", false ))
	{
		new Float:medPos1[3] = { -11054.3486, -8955.1142, -562.0253 };
		new Float:medPos2[3] = { -8348.9648, -5557.7651, -30.9687 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c10m3_ranchhouse", false ))
	{
		new Float:medPos1[3] = { -8337.6806, -5555.3442, -24.9687 };
		new Float:medPos2[3] = { -2608.1403, 117.5983, 336.4168 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c10m4_mainstreet", false ))
	{
		new Float:medPos1[3] = { -3126.3596, 109.4828, 328.0312 };
		new Float:medPos2[3] = { 1310.5878, -5435.1933, -55.9687 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c10m5_houseboat", false ))
	{
		new Float:medPos1[3] = { 2045.1307, 4582.4047, -63.9687 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		Ref_1 = true;
	}

	else if ( StrEqual( mapName2, "c11m1_greenhouse", false ))
	{
		new Float:medPos1[3] = { 6748.1967, -531.1122, 804.3424 };
		new Float:medPos2[3] = { 5298.4394, 2711.5922, 88.2619 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c11m2_offices", false ))
	{
		new Float:medPos1[3] = { 5284.5268, 2728.3281, 88.2619 };
		new Float:medPos2[3] = { 7901.8164, 6097.6113, 16.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c11m3_garage", false ))
	{
		new Float:medPos1[3] = { -5445.8823, -3150.7316, 16.0312 };
		new Float:medPos2[3] = { -380.4152, 3605.3823, 296.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c11m4_terminal", false ))
	{
		new Float:medPos1[3] = { -372.0156, 3595.7075, 296.0312 };
		new Float:medPos2[3] = { 3280.5654, 4549.5786, 152.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c11m5_runway", false ))
	{
		new Float:medPos1[3] = { -6716.3769, 12044.6699, 152.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		Ref_1 = true;
	}

	else if ( StrEqual( mapName2, "c12m1_hilltop", false ))
	{
		new Float:medPos1[3] = { -7923.2729, -14961.8583, 307.0303 };
		new Float:medPos2[3] = { -6512.0751, -6693.5283, 348.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c12m2_traintunnel", false ))
	{
		new Float:medPos1[3] = { -6499.8691, -6844.4912, 348.0312 };
		new Float:medPos2[3] = { -909.5875, -10388.4560, -63.9687 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c12m3_bridge", false ))
	{
		new Float:medPos1[3] = { -921.5653, -10385.1279, -63.9687 };
		new Float:medPos2[3] = { 7766.2348, -11411.3515, 440.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c12m4_barn", false ))
	{
		new Float:medPos1[3] = { 7752.1997, -11396.8144, 440.0312 };
		new Float:medPos2[3] = { 10462.0361, -477.4966, -28.9687 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c12m5_cornfield", false ))
	{
		new Float:medPos1[3] = { 10436.6494, -331.5462, -28.9687 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		Ref_1 = true;
	}

	else if ( StrEqual( mapName2, "c13m1_alpinecreek", false ))
	{
		new Float:medPos1[3] = { -3100.1291, -654.0091, 76.9501 };
		new Float:medPos2[3] = { 1252.3303, -1207.4747, 352.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c13m2_southpinestream", false ))
	{
		new Float:medPos1[3] = { 8741.9023, 7115.3916, 496.0312 };
		new Float:medPos2[3] = { 386.1105, 8774.2216, -404.9687 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c13m3_memorialbridge", false ))
	{
		new Float:medPos1[3] = { -4248.5820, -5187.1669, 96.0312 };
		new Float:medPos2[3] = { 6094.9887, -6215.8686, 386.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_1 = true;
		Ref_2 = true;
	}
	else if ( StrEqual( mapName2, "c13m4_cutthroatcreek", false ))
	{
		new Float:medPos1[3] = { -3397.7700, -9205.6513, 360.0312 };
		refPos1[0] = medPos1[0];
		refPos1[1] = medPos1[1];
		refPos1[2] = medPos1[2];
		Ref_1 = true;
	}
}

FindFinaleReference( Float:refPos2[3], Float:refPos3[3] )
{
	Ref_2 = false;
	Ref_3 = false;
	
	refPos2[0] = refPos3[0] = 0.0;
	refPos2[1] = refPos3[1] = 0.0;
	refPos2[2] = refPos3[2] = 0.0;
	
	decl String:mapName2[128];
	GetCurrentMap( mapName2, sizeof( mapName2 ));

	if ( StrEqual( mapName2, "c1m4_atrium", false ))
	{
		new Float:medPos2[3] = { -4468.6630, -3968.6342, 0.0312 };
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_2 = true;
	}

	else if ( StrEqual( mapName2, "c2m5_concert", false ))
	{
		new Float:medPos2[3] = { -2320.3269, 1988.2136, 128.0312 };
		new Float:medPos3[3] = { -914.6693, 2201.0427, -255.9687 };
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		refPos3[0] = medPos3[0];
		refPos3[1] = medPos3[1];
		refPos3[2] = medPos3[2];
		Ref_2 = true;
		Ref_3 = true;
	}

	else if ( StrEqual( mapName2, "c3m4_plantation", false ))
	{
		new Float:medPos2[3] = { 1054.1826, 795.9151, 164.0312 };// finale1
		new Float:medPos3[3] = { 2263.2204, 808.8970, 164.0312 };// finale2
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		refPos3[0] = medPos3[0];
		refPos3[1] = medPos3[1];
		refPos3[2] = medPos3[2];
		Ref_2 = true;
		Ref_3 = true;
	}

	else if ( StrEqual( mapName2, "c4m5_milltown_escape", false ))
	{
		new Float:medPos2[3] = { -6142.7172, 7498.4404, 104.0312 };
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_2 = true;
	}

	else if ( StrEqual( mapName2, "c6m3_port", false ))
	{
		new Float:medPos2[3] = { -314.0025, -809.6803, 0.5845 };
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_2 = true;
	}

	else if ( StrEqual( mapName2, "c7m3_port", false ))
	{
		new Float:medPos2[3] = { -314.0025, -825.9970, 0.4799 };
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_2 = true;
	}
	
	else if ( StrEqual( mapName2, "c8m5_rooftop", false ))
	{
		new Float:medPos2[3] = { 5697.8618, 8465.9365, 6080.0312 };
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_2 = true;
	}

	else if ( StrEqual( mapName2, "c9m2_lots", false ))
	{
		new Float:medPos2[3] = { 7138.2065, 6468.3911, 45.4688 };
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_2 = true;
	}

	else if ( StrEqual( mapName2, "c10m5_houseboat", false ))
	{
		new Float:medPos2[3] = { 3803.6408, -4647.0488, -151.9687 };
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_2 = true;
	}

	else if ( StrEqual( mapName2, "c11m5_runway", false ))
	{
		new Float:medPos2[3] = { -5127.5024, 9246.2548, -191.9687 };
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_2 = true;
	}

	else if ( StrEqual( mapName2, "c12m5_cornfield", false ))
	{
		new Float:medPos2[3] = { 6926.6030, 1320.3940, 238.0312 };
		refPos2[0] = medPos2[0];
		refPos2[1] = medPos2[1];
		refPos2[2] = medPos2[2];
		Ref_2 = true;
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

stock bool:IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( GetClientTeam( client ) != 2 ) return false;
	if ( !IsPlayerAlive( client )) return false;
	return true;
}

stock HealthCheat( client )
{
	if ( client > 0 )
	{
		new userflags = GetUserFlagBits( client );
		new cmdflags = GetCommandFlags( "give" );
		SetUserFlagBits( client, ADMFLAG_ROOT );
		SetCommandFlags( "give", cmdflags & ~FCVAR_CHEAT );
		FakeClientCommand( client,"give health" );
		SetCommandFlags( "give", cmdflags );
		SetUserFlagBits( client, userflags );
	}
}


