#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "2.0.5"

new Handle:g_hEnabled;
new Handle:g_hWeaponRandom;
new Handle:g_hWeaponRandomAmount;
new Handle:g_hWeaponBaseballBat;
new Handle:g_hWeaponCricketBat;
new Handle:g_hWeaponCrowbar;
new Handle:g_hWeaponElecGuitar;
new Handle:g_hWeaponFireAxe;
new Handle:g_hWeaponFryingPan;
new Handle:g_hWeaponGolfClub;
new Handle:g_hWeaponKnife;
new Handle:g_hWeaponKatana;
new Handle:g_hWeaponMachete;
new Handle:g_hWeaponRiotShield;
new Handle:g_hWeaponTonfa;

new bool:g_bSpawnedMelee;
new bool:g_bKnifeAloud = false;
new bool:g_bShieldAloud = false;

new g_iMeleeClassCount = 0;
new g_iMeleeRandomSpawn[20];
new g_iRound = 2;

new String:g_sMeleeClass[16][32];

public Plugin:myinfo =
{
	name = "Melee In The Saferoom",
	author = "N3wton",
	description = "Spawns a selection of melee weapons in the saferoom, at the start of each round.",
	version = VERSION
};

public OnPluginStart()
{
	decl String:GameName[12];
	GetGameFolderName(GameName, sizeof(GameName));
	if( !StrEqual(GameName, "left4dead2") )
		SetFailState( "Melee In The Saferoom is only supported on left 4 dead 2." );
		
	CreateConVar( "l4d2_MITSR_Version",		VERSION, "The version of Melee In The Saferoom", FCVAR_PLUGIN ); 
	g_hEnabled				= CreateConVar( "l4d2_MITSR_Enabled",		"1", "Should the plugin be enabled", FCVAR_PLUGIN ); 
	g_hWeaponRandom			= CreateConVar( "l4d2_MITSR_Random",		"1", "Spawn Random Weapons (1) or custom list (0)", FCVAR_PLUGIN ); 
	g_hWeaponRandomAmount	= CreateConVar( "l4d2_MITSR_Amount",		"4", "Number of weapons to spawn if l4d2_MITSR_Random is 1", FCVAR_PLUGIN ); 
	g_hWeaponBaseballBat 	= CreateConVar( "l4d2_MITSR_BaseballBat",	"1", "Number of baseball bats to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponCricketBat 	= CreateConVar( "l4d2_MITSR_CricketBat", 	"1", "Number of cricket bats to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponCrowbar 		= CreateConVar( "l4d2_MITSR_Crowbar", 	"1", "Number of crowbars to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponElecGuitar		= CreateConVar( "l4d2_MITSR_ElecGuitar",	"1", "Number of electric guitars to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponFireAxe			= CreateConVar( "l4d2_MITSR_FireAxe",		"1", "Number of fireaxes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponFryingPan		= CreateConVar( "l4d2_MITSR_FryingPan",	"1", "Number of frying pans to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponGolfClub		= CreateConVar( "l4d2_MITSR_GolfClub",	"1", "Number of golf clubs to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponKnife			= CreateConVar( "l4d2_MITSR_Knife",		"1", "Number of knifes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponKatana			= CreateConVar( "l4d2_MITSR_Katana",		"1", "Number of katanas to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponMachete			= CreateConVar( "l4d2_MITSR_Machete",		"1", "Number of machetes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponRiotShield		= CreateConVar( "l4d2_MITSR_RiotShield",	"1", "Number of riot shields to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponTonfa			= CreateConVar( "l4d2_MITSR_Tonfa",		"1", "Number of tonfas to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	AutoExecConfig( true, "[L4D2]MeleeInTheSaferoom" );
	
	HookEvent( "round_start", Event_RoundStart );
	
	RegAdminCmd( "sm_melee", Command_SMMelee, ADMFLAG_KICK, "Lists all melee weapons spawnable in current campaign" );
}

public Action:Command_SMMelee(client, args)
{
	for( new i = 0; i < g_iMeleeClassCount; i++ )
	{
		PrintToChat( client, "%d : %s", i, g_sMeleeClass[i] );
	}
}

public OnMapStart()
{
	if( FileExists( "scripts/melee/huntingknife.txt" ) )
	{
		AddFileToDownloadsTable( "scripts/melee/huntingknife.txt" );
		g_bKnifeAloud = true;
	}
	if( FileExists( "scripts/melee/riot_shield.txt" ) )
	{
		AddFileToDownloadsTable( "scripts/melee/riot_shield.txt" );
		g_bShieldAloud = true;
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( !GetConVarBool( g_hEnabled ) ) return Plugin_Continue;
	
	g_bSpawnedMelee = false;
	
	if( g_iRound == 2 && IsVersus() ) g_iRound = 1; else g_iRound = 2;
	
	GetMeleeClasses();
	
	CreateTimer( 1.0, Timer_SpawnMelee );
	
	return Plugin_Continue;
}

public Action:Timer_SpawnMelee( Handle:timer )
{
	new client = GetInGameClient();

	if( client != 0 && !g_bSpawnedMelee )
	{
		decl Float:SpawnPosition[3], Float:SpawnAngle[3];
		GetClientAbsOrigin( client, SpawnPosition );
		SpawnPosition[2] += 20; SpawnAngle[0] = 90.0;
		
		if( GetConVarBool( g_hWeaponRandom ) )
		{
			new i = 0;
			while( i < GetConVarInt( g_hWeaponRandomAmount ) )
			{
				new RandomMelee = GetRandomInt( 0, g_iMeleeClassCount-1 );
				if( IsVersus() && g_iRound == 2 ) RandomMelee = g_iMeleeRandomSpawn[i]; 
				SpawnMelee( g_sMeleeClass[RandomMelee], SpawnPosition, SpawnAngle );
				if( IsVersus() && g_iRound == 1 ) g_iMeleeRandomSpawn[i] = RandomMelee;
				i++;
			}
			g_bSpawnedMelee = true;
		}
		else
		{
			SpawnCustomList( SpawnPosition, SpawnAngle );
			g_bSpawnedMelee = true;
		}
	}
	else
	{
		if( !g_bSpawnedMelee ) CreateTimer( 1.0, Timer_SpawnMelee );
	}
}

stock SpawnCustomList( Float:Position[3], Float:Angle[3] )
{
	decl String:ScriptName[32];
	
	//Spawn Basseball Bats
	if( GetConVarInt( g_hWeaponBaseballBat ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponBaseballBat ); i++ )
		{
			GetScriptName( "baseball_bat", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Cricket Bats
	if( GetConVarInt( g_hWeaponCricketBat ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponCricketBat ); i++ )
		{
			GetScriptName( "cricket_bat", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Crowbars
	if( GetConVarInt( g_hWeaponCrowbar ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponCrowbar ); i++ )
		{
			GetScriptName( "crowbar", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Electric Guitars
	if( GetConVarInt( g_hWeaponElecGuitar ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponElecGuitar ); i++ )
		{
			GetScriptName( "electric_guitar", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Fireaxes
	if( GetConVarInt( g_hWeaponFireAxe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponFireAxe ); i++ )
		{
			GetScriptName( "fireaxe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Frying Pans
	if( GetConVarInt( g_hWeaponFryingPan ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponFryingPan ); i++ )
		{
			GetScriptName( "frying_pan", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Golfclubs
	if( GetConVarInt( g_hWeaponGolfClub ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponGolfClub ); i++ )
		{
			GetScriptName( "golfclub", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Knifes
	if( GetConVarInt( g_hWeaponKnife ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponKnife ); i++ )
		{
			GetScriptName( "huntingknife", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Katanas
	if( GetConVarInt( g_hWeaponKatana ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponKatana ); i++ )
		{
			GetScriptName( "katana", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Machetes
	if( GetConVarInt( g_hWeaponMachete ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponMachete ); i++ )
		{
			GetScriptName( "machete", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn RiotShields
	if( GetConVarInt( g_hWeaponRiotShield ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponRiotShield ); i++ )
		{
			GetScriptName( "riot_shield", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Tonfas
	if( GetConVarInt( g_hWeaponTonfa ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponTonfa ); i++ )
		{
			GetScriptName( "tonfa", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
}

stock SpawnMelee( const String:Class[32], Float:Position[3], Float:Angle[3] )
{
	decl Float:SpawnPosition[3], Float:SpawnAngle[3];
	SpawnPosition = Position;
	SpawnAngle = Angle;
	
	SpawnPosition[0] += ( -10 + GetRandomInt( 0, 20 ) );
	SpawnPosition[1] += ( -10 + GetRandomInt( 0, 20 ) );
	SpawnPosition[2] += GetRandomInt( 0, 10 );
	SpawnAngle[1] = GetRandomFloat( 0.0, 360.0 );

	new MeleeSpawn = CreateEntityByName( "weapon_melee" );
	DispatchKeyValue( MeleeSpawn, "melee_script_name", Class );
	DispatchSpawn( MeleeSpawn );
	TeleportEntity(MeleeSpawn, SpawnPosition, SpawnAngle, NULL_VECTOR );
}

stock GetMeleeClasses()
{
	new MeleeStringTable = FindStringTable( "MeleeWeapons" );
	g_iMeleeClassCount = GetStringTableNumStrings( MeleeStringTable );
	
	for( new i = 0; i < g_iMeleeClassCount; i++ )
	{
		ReadStringTable( MeleeStringTable, i, g_sMeleeClass[i], 32 );
	}	
}

stock GetScriptName( const String:Class[32], String:ScriptName[32] )
{
	if( StrContains(ScriptName, "knife", false) != -1 && !g_bKnifeAloud ) 
	{
		Format( ScriptName, 32, "%s", g_sMeleeClass[0] );
		return;
	}
	if( StrContains(ScriptName, "shield", false) != -1 && !g_bShieldAloud ) 
	{
		Format( ScriptName, 32, "%s", g_sMeleeClass[0] );
		return;
	}

	for( new i = 0; i < g_iMeleeClassCount; i++ )
	{
		if( StrContains( g_sMeleeClass[i], Class, false ) == 0 )
		{
			Format( ScriptName, 32, "%s", g_sMeleeClass[i] );
			return;
		}
	}
	Format( ScriptName, 32, "%s", g_sMeleeClass[0] );	
}

stock GetInGameClient()
{
	for( new x = 1; x <= GetClientCount( true ); x++ )
	{
		if( IsClientInGame( x ) && GetClientTeam( x ) == 2 )
		{
			return x;
		}
	}
	return 0;
}

stock bool:IsVersus()
{
	new String:GameMode[32];
	GetConVarString( FindConVar( "mp_gamemode" ), GameMode, 32 );
	if( StrContains( GameMode, "versus", false ) != -1 ) return true;
	return false;
}