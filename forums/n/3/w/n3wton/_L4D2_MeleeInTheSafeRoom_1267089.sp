#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Handle:g_hEnabled;
new Handle:g_hWeapon;
new Handle:g_hAmount;
new Handle:g_hVesusEqual;

new bool:g_bWeaponsSpawned = false;

new String:g_sMeleeName[36][48];
new g_iMeleeCount = 0;
new String:g_iVersusWeps[36][48];
new g_iAddedAmount = 0;
new g_iRoundCount = 1;
new bool:g_bIsVersusSame = false;

#define VERSION "1.2.7"

public Plugin:myinfo =
{
	name = "Melee in the saferoom",
	author = "N3wton",
	description = "Spawns X amount of melee weapons in the saferoom at round start.",
	version = VERSION
};

public OnPluginStart()
{
	CreateConVar( "l4d2_MITSR_Version", VERSION, "The Plugin Version", FCVAR_PLUGIN );
	g_hEnabled = CreateConVar( "l4d2_MITSR_Enabled", "1", "Should the plugin be enabled", FCVAR_PLUGIN );
	g_hVesusEqual = CreateConVar( "l4d2_MITSR_Versus_Equal", "1", "Should the same melee weapons be spawned for both teams in versus mode", FCVAR_PLUGIN );
	g_hWeapon = CreateConVar( "l4d2_MITSR_Weapon", "random", "Weapon the should be spawned ( random, baseball_bat, fireaxe, frying_pan, machete, crowbar, cricket_bat, katana, electric_guitar, tonfa, golfclub, hunting_knife, riotshield )", FCVAR_PLUGIN );
	g_hAmount = CreateConVar( "l4d2_MITSR_Amount", "4", "Number of melle weapons to spawn", FCVAR_PLUGIN, true, 0.0, true, 20.0 );
	AutoExecConfig( true, "[L4D2]MeleeSafeRoom" );
	
	if( GetConVarInt( g_hAmount ) > 20 ) SetConVarInt( g_hAmount, 20 );
	if( GetConVarInt( g_hAmount ) < 0 ) SetConVarInt( g_hAmount, 0 );

	HookEvent( "round_start", Event_RoundStart );
}

public OnMapStart()
{
    if( FileExists( "addons\\melee_weapons_unlock.vpk" ) )
	{
		SetConVarInt( FindConVar( "sv_allowdownload" ), 1 );
		
		AddFileToDownloadsTable("missions\\campaign1.txt");
		AddFileToDownloadsTable("missions\\campaign2.txt");
		AddFileToDownloadsTable("missions\\campaign3.txt");
		AddFileToDownloadsTable("missions\\campaign4.txt");
		AddFileToDownloadsTable("missions\\campaign5.txt");
		AddFileToDownloadsTable("missions\\campaign6.txt");
		AddFileToDownloadsTable("missions\\credits.txt");
		
		AddFileToDownloadsTable("scripts\\melee\\baseball_bat.txt");
		AddFileToDownloadsTable("scripts\\melee\\baseballbat.txt");
		AddFileToDownloadsTable("scripts\\melee\\cricket_bat.txt");
		AddFileToDownloadsTable("scripts\\melee\\crowbar.txt");
		AddFileToDownloadsTable("scripts\\melee\\electric_guitar.txt");
		AddFileToDownloadsTable("scripts\\melee\\fireaxe.txt");
		AddFileToDownloadsTable("scripts\\melee\\frying_pan.txt");
		AddFileToDownloadsTable("scripts\\melee\\golf_club.txt");
		AddFileToDownloadsTable("scripts\\melee\\golfclub.txt");
		AddFileToDownloadsTable("scripts\\melee\\hunting_knife.txt");
		AddFileToDownloadsTable("scripts\\melee\\katana.txt");
		AddFileToDownloadsTable("scripts\\melee\\knife.txt");
		AddFileToDownloadsTable("scripts\\melee\\machete.txt");
		AddFileToDownloadsTable("scripts\\melee\\riotshield.txt");
		AddFileToDownloadsTable("scripts\\melee\\tonfa.txt");
		AddFileToDownloadsTable("scripts\\melee\\melee_manifest.txt");
	}
}

public Action:Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarBool( g_hEnabled ) )
	{
		g_bWeaponsSpawned = false;
		g_iAddedAmount = 0;
		
		new String:GameMode[32];
		GetConVarString(FindConVar("mp_gamemode"), GameMode, 32);
		if( (StrContains(GameMode, "versus", false ) != -1) && (GetConVarBool(g_hVesusEqual)) )
		{
			g_bIsVersusSame = true;
		}
		
		CreateTimer( 1.0, Timer_SpawnBats );
	
		new i_MeleeTable = FindStringTable( "MeleeWeapons" );
		g_iMeleeCount = GetStringTableNumStrings( i_MeleeTable );
		for( new q = 0; q < g_iMeleeCount; q++ )
		{
			ReadStringTable( i_MeleeTable, q, g_sMeleeName[q], 32 );
		}	
	}
}

public Action:Timer_SpawnBats( Handle:timer )
{
	new client = 0;
	for( new x = 1; x <= 8; x++ )
	{
		if( IsClientInGame( x ) )
		{
			if( GetClientTeam( x ) == 2 )
			{
				client = x;
				break;
			}
		}
	}
	if( client != 0 && IsClientInGame( client ) && !g_bWeaponsSpawned )
	{
		decl Float:Position[3];
		decl Float:Angle[3];
		GetClientAbsOrigin( client, Position );
		Position[2] += 20;
		Angle[0] = 90.0;
		new i = 0;
		while( i < GetConVarInt( g_hAmount ) )
		{
			Position[0] += (-10+GetRandomInt(0, 20));
			Position[1] += (-10+GetRandomInt(0, 20));
			Angle[1] = GetRandomFloat(0.0, 360.0);
			decl String:WeaponClass[48];
			GetWeaponClass( WeaponClass );
			new Ent = CreateEntityByName( "weapon_melee" );
			DispatchKeyValue( Ent, "melee_script_name", WeaponClass );
			DispatchSpawn( Ent );
			TeleportEntity( Ent, Position, Angle, NULL_VECTOR );
			new String:ModelName[128];
			GetEntPropString( Ent, Prop_Data, "m_ModelName", ModelName, 128 ); 
			if( StrContains( ModelName, "hunter", false ) != -1)
			{
				RemoveEdict( Ent );
				GetConVarString( g_hWeapon, WeaponClass, 48 );
				if( StrContains( WeaponClass, "random", false ) == -1 )
				{
					SetConVarString( g_hWeapon, "random" );
				}
			} else {
				i++;
			}
			if( i == GetConVarInt( g_hAmount ) )
			{
				g_bWeaponsSpawned = true;
				if( g_bIsVersusSame )
				{
					if( g_iRoundCount == 1 ) 
					{
						g_iRoundCount = 2; 
						g_iAddedAmount = 0;
					}
					else 
					{
						g_iRoundCount = 1;
						g_iAddedAmount = 0;
					}
				}
			}
		}
	} else {
		CreateTimer( 0.1, Timer_SpawnBats );
	}
}

GetWeaponClass( String:Class[] )
{
	GetConVarString( g_hWeapon, Class, 48 );
	if( StrContains( Class, "random", false ) != -1 )
	{
		if( g_bIsVersusSame )
		{
			if( g_iRoundCount == 1 ) 
			{
				Format( Class, 48, "%s", g_sMeleeName[GetRandomInt( 0, g_iMeleeCount-1 )] );
				Format( g_iVersusWeps[g_iAddedAmount], 48, "%s", Class );
				g_iAddedAmount++;
			}
			else
			{
				Format( Class, 48, "%s", g_iVersusWeps[g_iAddedAmount] );
				g_iAddedAmount++;
			}
		}
		else
		{
			Format( Class, 48, "%s", g_sMeleeName[GetRandomInt( 0, g_iMeleeCount-1 )] );
		}
	}
}
