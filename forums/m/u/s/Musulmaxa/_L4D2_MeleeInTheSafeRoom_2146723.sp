#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "2.0.7modded"

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
new Handle:g_hWeaponChainsaw;
new Handle:g_hWeaponGnome;
new Handle:g_hWeaponWrench;
new Handle:g_hWeaponMace;
new Handle:g_hWeaponMace2;
new Handle:g_hWeaponLongsword;
new Handle:g_hWeaponFubar;
new Handle:g_hWeaponDaxe;
new Handle:g_hWeaponBnc;
new Handle:g_hWeaponGman;
new Handle:g_hWeaponNailbat;
new Handle:g_hWeaponTonfaRiot;
new Handle:g_hWeaponGloves;
new Handle:g_hWeaponGuitar;
new Handle:g_hWeaponKatana2;
new Handle:g_hWeaponPot;
new Handle:g_hWeaponWoodenbat;

new bool:g_bSpawnedMelee;

new g_iMeleeClassCount = 0;
new g_iMeleeRandomSpawn[20];
new g_iRound = 2;

new String:g_sMeleeClass[16][32];

public Plugin:myinfo =
{
	name = "Melee In The Saferoom Modded",
	author = "N3wton modded by StixsmasterHD",
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
	g_hWeaponRandom			= CreateConVar( "l4d2_MITSR_Random",		"0", "Spawn Random Weapons (1) or custom list (0)", FCVAR_PLUGIN ); 
	g_hWeaponRandomAmount	= CreateConVar( "l4d2_MITSR_Amount",		"8", "Number of weapons to spawn if l4d2_MITSR_Random is 1", FCVAR_PLUGIN ); 
	g_hWeaponBaseballBat 	= CreateConVar( "l4d2_MITSR_BaseballBat",	"1", "Number of baseball bats to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponCricketBat 	= CreateConVar( "l4d2_MITSR_CricketBat", 	"1", "Number of cricket bats to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponCrowbar 		= CreateConVar( "l4d2_MITSR_Crowbar", 	"1", "Number of crowbars to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponElecGuitar		= CreateConVar( "l4d2_MITSR_ElecGuitar",	"1", "Number of electric guitars to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponFireAxe			= CreateConVar( "l4d2_MITSR_FireAxe",		"2", "Number of fireaxes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponFryingPan		= CreateConVar( "l4d2_MITSR_FryingPan",	"1", "Number of frying pans to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponGolfClub		= CreateConVar( "l4d2_MITSR_GolfClub",	"1", "Number of golf clubs to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponKnife			= CreateConVar( "l4d2_MITSR_Knife",		"3", "Number of knifes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponKatana			= CreateConVar( "l4d2_MITSR_Katana",		"3", "Number of katanas to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponMachete			= CreateConVar( "l4d2_MITSR_Machete",		"3", "Number of machetes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponRiotShield		= CreateConVar( "l4d2_MITSR_RiotShield",	"1", "Number of riot shields to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponTonfa			= CreateConVar( "l4d2_MITSR_Tonfa",		"1", "Number of tonfas to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponChainsaw			= CreateConVar( "l4d2_MITSR_Chainsaw",		"1", "Number of chainsaws to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponGnome			= CreateConVar( "l4d2_MITSR_Gnome",		"1", "Number of gnomes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponWrench			= CreateConVar( "l4d2_MITSR_Wrench",		"1", "Number of wrenchs to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponMace			= CreateConVar( "l4d2_MITSR_Mace",		"1", "Number of maces to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponMace2			= CreateConVar( "l4d2_MITSR_Mace2",		"1", "Number of mace2s to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponLongsword			= CreateConVar( "l4d2_MITSR_Longsword",		"1", "Number of longswords to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponFubar			= CreateConVar( "l4d2_MITSR_Fubar",		"1", "Number of fubars to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponDaxe			= CreateConVar( "l4d2_MITSR_Daxe",		"1", "Number of daxes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponBnc			= CreateConVar( "l4d2_MITSR_Bnc",		"1", "Number of bncs to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponGman			= CreateConVar( "l4d2_MITSR_Gman",		"1", "Number of gmans to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponNailbat			= CreateConVar( "l4d2_MITSR_Nailbat",		"1", "Number of nailbats to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponTonfaRiot			= CreateConVar( "l4d2_MITSR_TonfaRiot",		"1", "Number of tonfariots to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponGloves			= CreateConVar( "l4d2_MITSR_Gloves",		"1", "Number of gloves to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponGuitar			= CreateConVar( "l4d2_MITSR_Guitar",		"1", "Number of guitars to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponKatana2			= CreateConVar( "l4d2_MITSR_Katana2",		"1", "Number of katana2s to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponWoodenbat			= CreateConVar( "l4d2_MITSR_Woodenbat",		"1", "Number of woodenbats to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
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
	PrecacheModel( "models/weapons/melee/v_bat.mdl", true );
	PrecacheModel( "models/weapons/melee/v_cricket_bat.mdl", true );
	PrecacheModel( "models/weapons/melee/v_crowbar.mdl", true );
	PrecacheModel( "models/weapons/melee/v_electric_guitar.mdl", true );
	PrecacheModel( "models/weapons/melee/v_fireaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_frying_pan.mdl", true );
	PrecacheModel( "models/weapons/melee/v_golfclub.mdl", true );
	PrecacheModel( "models/weapons/melee/v_katana.mdl", true );
	PrecacheModel( "models/weapons/melee/v_machete.mdl", true );
	PrecacheModel( "models/weapons/melee/v_tonfa.mdl", true );
	PrecacheModel( "models/weapons/melee/v_chainsaw.mdl", true );
	PrecacheModel( "models/weapons/melee/v_gnome.mdl", true );
	PrecacheModel( "models/weapons/melee/v_wrench.mdl", true );
	PrecacheModel( "models/weapons/melee/v_mace.mdl", true );
	PrecacheModel( "models/weapons/melee/v_mace2.mdl", true );
	PrecacheModel( "models/weapons/melee/v_longsword.mdl", true );
	PrecacheModel( "models/weapons/melee/v_fubar.mdl", true );
	PrecacheModel( "models/weapons/melee/v_daxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_bnc.mdl", true );
	PrecacheModel( "models/weapons/melee/v_gman.mdl", true );
	PrecacheModel( "models/weapons/melee/v_nailbat.mdl", true );
	PrecacheModel( "models/weapons/melee/v_tonfa_riot.mdl", true );
	PrecacheModel( "models/weapons/melee/v_gloves_box.mdl", true );
	PrecacheModel( "models/weapons/melee/v_electric_guitrb.mdl", true );
	PrecacheModel( "models/weapons/melee/v_katano.mdl", true );
	PrecacheModel( "models/weapons/melee/v_sauced_pot.mdl", true );
	PrecacheModel( "models/weapons/melee/v_btc.mdl", true );
	PrecacheModel( "models/weapons/melee/w_bat.mdl", true );
	PrecacheModel( "models/weapons/melee/w_cricket_bat.mdl", true );
	PrecacheModel( "models/weapons/melee/w_crowbar.mdl", true );
	PrecacheModel( "models/weapons/melee/w_electric_guitar.mdl", true );
	PrecacheModel( "models/weapons/melee/w_fireaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_frying_pan.mdl", true );
	PrecacheModel( "models/weapons/melee/w_golfclub.mdl", true );
	PrecacheModel( "models/weapons/melee/w_katana.mdl", true );
	PrecacheModel( "models/weapons/melee/w_machete.mdl", true );
	PrecacheModel( "models/weapons/melee/w_tonfa.mdl", true );
	PrecacheModel( "models/weapons/melee/w_chainsaw.mdl", true );
	PrecacheModel( "models/weapons/melee/w_wrench.mdl", true );
	PrecacheModel( "models/weapons/melee/w_mace.mdl", true );
	PrecacheModel( "models/weapons/melee/w_mace2.mdl", true );
	PrecacheModel( "models/weapons/melee/w_longsword.mdl", true );
	PrecacheModel( "models/weapons/melee/w_fubar.mdl", true );
	PrecacheModel( "models/weapons/melee/w_daxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_bnc.mdl", true );
	PrecacheModel( "models/weapons/melee/w_gman.mdl", true );
	PrecacheModel( "models/weapons/melee/w_nailbat.mdl", true );
	PrecacheModel( "models/weapons/melee/w_tonfa_riot.mdl", true );
	PrecacheModel( "models/weapons/melee/w_gloves_box.mdl", true );
	PrecacheModel( "models/weapons/melee/w_electric_guitrb.mdl", true );
	PrecacheModel( "models/weapons/melee/w_katano.mdl", true );
	PrecacheModel( "models/weapons/melee/w_sauced_pot.mdl", true );
	PrecacheModel( "models/weapons/melee/w_btc.mdl", true );
	
	PrecacheGeneric( "scripts/melee/baseball_bat.txt", true );
	PrecacheGeneric( "scripts/melee/cricket_bat.txt", true );
	PrecacheGeneric( "scripts/melee/crowbar.txt", true );
	PrecacheGeneric( "scripts/melee/electric_guitar.txt", true );
	PrecacheGeneric( "scripts/melee/fireaxe.txt", true );
	PrecacheGeneric( "scripts/melee/frying_pan.txt", true );
	PrecacheGeneric( "scripts/melee/golfclub.txt", true );
	PrecacheGeneric( "scripts/melee/katana.txt", true );
	PrecacheGeneric( "scripts/melee/machete.txt", true );
	PrecacheGeneric( "scripts/melee/tonfa.txt", true );
	PrecacheGeneric( "scripts/melee/wrench.txt", true );
	PrecacheGeneric( "scripts/melee/mace.txt", true );
	PrecacheGeneric( "scripts/melee/mace2.txt", true );
	PrecacheGeneric( "scripts/melee/longsword.txt", true );
	PrecacheGeneric( "scripts/melee/fubar.txt", true );
	PrecacheGeneric( "scripts/melee/daxe.txt", true );
	PrecacheGeneric( "scripts/melee/bnc.txt", true );
	PrecacheGeneric( "scripts/melee/gman.txt", true );
	PrecacheGeneric( "scripts/melee/nailbat.txt", true );
	PrecacheGeneric( "scripts/melee/tonfa_riot.txt", true );
	PrecacheGeneric( "scripts/melee/gloves.txt", true );
	PrecacheGeneric( "scripts/melee/guitar.txt", true );
	PrecacheGeneric( "scripts/melee/katana2.txt", true );
	PrecacheGeneric( "scripts/melee/pot.txt", true );
	PrecacheGeneric( "scripts/melee/woodbat.txt", true );
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
			GetScriptName( "knife", ScriptName );
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
			GetScriptName( "riotshield", ScriptName );
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

	//Spawn Chainsaws
	if( GetConVarInt( g_hWeaponChainsaw ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponChainsaw ); i++ )
		{
			GetScriptName( "chainsaw", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn Gnomes
	if( GetConVarInt( g_hWeaponGnome ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponGnome ); i++ )
		{
			GetScriptName( "gnome", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn Wrenchs
	if( GetConVarInt( g_hWeaponWrench ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponWrench ); i++ )
		{
			GetScriptName( "wrench", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn Maces
	if( GetConVarInt( g_hWeaponMace ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponMace ); i++ )
		{
			GetScriptName( "mace", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn Mace2s
	if( GetConVarInt( g_hWeaponMace2 ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponMace2 ); i++ )
		{
			GetScriptName( "mace2", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn Longswords
	if( GetConVarInt( g_hWeaponLongsword ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponLongsword ); i++ )
		{
			GetScriptName( "longsword", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn Fubars
	if( GetConVarInt( g_hWeaponFubar ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponFubar ); i++ )
		{
			GetScriptName( "fubar", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn Daxes
	if( GetConVarInt( g_hWeaponDaxe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponDaxe ); i++ )
		{
			GetScriptName( "daxe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn Bncs
	if( GetConVarInt( g_hWeaponBnc ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponBnc ); i++ )
		{
			GetScriptName( "bnc", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn Gmans
	if( GetConVarInt( g_hWeaponGman ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponGman ); i++ )
		{
			GetScriptName( "gman", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn Nailbats
	if( GetConVarInt( g_hWeaponNailbat ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponNailbat ); i++ )
		{
			GetScriptName( "nailbat", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn TonfaRiots
	if( GetConVarInt( g_hWeaponTonfaRiot ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponTonfaRiot ); i++ )
		{
			GetScriptName( "tonfa_riot", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn Gloves
	if( GetConVarInt( g_hWeaponGloves ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponGloves ); i++ )
		{
			GetScriptName( "gloves", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn Guitars
	if( GetConVarInt( g_hWeaponGuitar ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponGuitar ); i++ )
		{
			GetScriptName( "guitar", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn Katana2s
	if( GetConVarInt( g_hWeaponKatana2 ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponKatana2 ); i++ )
		{
			GetScriptName( "katana2", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn Pots
	if( GetConVarInt( g_hWeaponPot ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponPot ); i++ )
		{
			GetScriptName( "pot", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn Woodenbats
	if( GetConVarInt( g_hWeaponWoodenbat ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponWoodenbat ); i++ )
		{
			GetScriptName( "woodenbat", ScriptName );
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