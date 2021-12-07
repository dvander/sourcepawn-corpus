/*
==============================
ZOMBIE PANIC! SOURCE - QUAKE SOUNDS
Coded by Shepard62700FR (~*L-M*~ -/TFH\- Shepard)
Heavily based on the Quake sounds revamped plugin by Grrrrrrrrrrrrrrrrrrr
==============================
*/

#pragma semicolon 1

#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <clientprefs>

// Variables

#define ZPSMAXPLAYERS 24

new bool:FirstBlood = true;
new bool:RoundInProgress = false;
new Combo_Kills[ZPSMAXPLAYERS + 1];
new Cookie_Player[ZPSMAXPLAYERS + 1] = { 1, ... };
new Damage_HitBox[ZPSMAXPLAYERS + 1];
new Float:Combo_LastKillTime[ZPSMAXPLAYERS + 1];
new Handle:Cookie;
new iMaxClients;

// Quake sounds definitions

#define QUAKESOUND_HUMILIATION 0
#define QUAKESOUND_TEAMKILL 1
#define QUAKESOUND_HEADSHOT 2
#define QUAKESOUND_FIRSTBLOOD 3
#define QUAKESOUND_DOUBLEKILL 4
#define QUAKESOUND_MULTIKILL 5
#define QUAKESOUND_ULTRAKILL 6
#define QUAKESOUND_MONSTERKILL 7
#define QUAKESOUND_GRENADE 8
#define QUAKESOUND_PLAY 9
#define QUAKESOUND_SUICIDE 10

#define QUAKESOUND_STANDARD_HUMILIATION "quake_zps/humiliation.wav"
#define QUAKESOUND_STANDARD_TEAMKILLER "quake_zps/teamkiller.wav"
#define QUAKESOUND_STANDARD_HEADSHOT "quake_zps/headshot.wav"
#define QUAKESOUND_STANDARD_FIRSTBLOOD "quake_zps/firstblood.wav"
#define QUAKESOUND_STANDARD_DOUBLEKILL "quake_zps/doublekill.wav"
#define QUAKESOUND_STANDARD_MULTIKILL "quake_zps/multikill.wav"
#define QUAKESOUND_STANDARD_ULTRAKILL "quake_zps/ultrakill.wav"
#define QUAKESOUND_STANDARD_MONSTERKILL "quake_zps/monsterkill.wav"
#define QUAKESOUND_STANDARD_GRENADE "quake_zps/perfect.wav"
#define QUAKESOUND_STANDARD_PLAY "quake_zps/prepare.wav"

#define QUAKESOUND_LOL_EN_HUMILIATION "quake_zps/lol_en_humiliation.wav"
#define QUAKESOUND_LOL_EN_FIRSTBLOOD "quake_zps/lol_en_firstblood.wav"
#define QUAKESOUND_LOL_EN_DOUBLEKILL "quake_zps/lol_en_doublekill.wav"
#define QUAKESOUND_LOL_EN_MULTIKILL "quake_zps/lol_en_multikill.wav"
#define QUAKESOUND_LOL_EN_ULTRAKILL "quake_zps/lol_en_ultrakill.wav"
#define QUAKESOUND_LOL_EN_MONSTERKILL "quake_zps/lol_en_monsterkill.wav"
#define QUAKESOUND_LOL_EN_GRENADE "quake_zps/lol_en_perfect.wav"

#define QUAKESOUND_STANDARD_HUMILIATION_FULL "sound/quake_zps/humiliation.wav"
#define QUAKESOUND_STANDARD_TEAMKILLER_FULL "sound/quake_zps/teamkiller.wav"
#define QUAKESOUND_STANDARD_HEADSHOT_FULL "sound/quake_zps/headshot.wav"
#define QUAKESOUND_STANDARD_FIRSTBLOOD_FULL "sound/quake_zps/firstblood.wav"
#define QUAKESOUND_STANDARD_DOUBLEKILL_FULL "sound/quake_zps/doublekill.wav"
#define QUAKESOUND_STANDARD_MULTIKILL_FULL "sound/quake_zps/multikill.wav"
#define QUAKESOUND_STANDARD_ULTRAKILL_FULL "sound/quake_zps/ultrakill.wav"
#define QUAKESOUND_STANDARD_MONSTERKILL_FULL "sound/quake_zps/monsterkill.wav"
#define QUAKESOUND_STANDARD_GRENADE_FULL "sound/quake_zps/perfect.wav"
#define QUAKESOUND_STANDARD_PLAY_FULL "sound/quake_zps/prepare.wav"

#define QUAKESOUND_LOL_EN_HUMILIATION_FULL "sound/quake_zps/lol_en_humiliation.wav"
#define QUAKESOUND_LOL_EN_FIRSTBLOOD_FULL "sound/quake_zps/lol_en_firstblood.wav"
#define QUAKESOUND_LOL_EN_DOUBLEKILL_FULL "sound/quake_zps/lol_en_doublekill.wav"
#define QUAKESOUND_LOL_EN_MULTIKILL_FULL "sound/quake_zps/lol_en_multikill.wav"
#define QUAKESOUND_LOL_EN_ULTRAKILL_FULL "sound/quake_zps/lol_en_ultrakill.wav"
#define QUAKESOUND_LOL_EN_MONSTERKILL_FULL "sound/quake_zps/lol_en_monsterkill.wav"
#define QUAKESOUND_LOL_EN_GRENADE_FULL "sound/quake_zps/lol_en_perfect.wav"

//====================
//Plugin:myinfo - Plugin's information
//====================

public Plugin:myinfo =
{
	name = "[ZPS] Quake Sounds",
	author = "Shepard62700FR",
	description = "Play sounds at random events such as headshots, kill streak...",
	version = "1.0.0.0",
	url = "http://www.sourcemod.net/"
}

//====================
//OnAllPluginsLoaded - Used for loading SDKHooks to detect headshots
//====================

public OnAllPluginsLoaded()
{
	iMaxClients = GetMaxClients();

	// SDKHooks has failed to load
	if( GetExtensionFileStatus( "sdkhooks.ext" ) != 1 )
		SetFailState( "[ZPS Quake Sounds] Error while loading SDK Hooks!" );

	// Hooks the events we need to detect headshots
	for( new i = 1 ; i <= iMaxClients ; i++ )
	{
		if( IsClientInGame( i ) )
			SDKHook( i, SDKHook_TraceAttackPost, OnTraceAttack );
	}
}

//====================
//OnPluginStart - Prepare the plugin to do it's job =)
//====================

public OnPluginStart()
{
	// Are we running ZPS?
	decl String:GameName[32];
	GetGameFolderName( GameName, sizeof( GameName ) );
	if ( !StrEqual( GameName, "zps" ) )
		SetFailState( "[ZPS Quake Sounds] This plugin is for Zombie Panic! Source only!" );
	else
	{
		// Hooking events
		HookEvent( "ambient_play", Event_RoundRestart, EventHookMode_PostNoCopy );
		HookEvent( "player_death", Event_PlayerDeath );

		// Console command
		RegConsoleCmd( "sm_quake", Command_ShowMenu );

		// Cookie
		Cookie = RegClientCookie( "Quake Sounds", "Quake Sounds", CookieAccess_Private );

		// Load the translations
		LoadTranslations( "zps_quakesounds.phrases" );

		// Show in the settings menu that we can configure the plugin
		decl String:Title[ 64 ];
		Format( Title, sizeof( Title ), "%t", "Menu_Title" );
		if( LibraryExists( "clientprefs" ) )
			SetCookieMenuItem( Cookie_Menu_Select, VOTEINFO_CLIENT_INDEX, Title );
	}
}

//====================
//OnMapStart - Server has loaded the map
//====================

public OnMapStart()
{
	// Get max players count
	iMaxClients = GetMaxClients();

	// Precache the sounds
	AddFileToDownloadsTable( QUAKESOUND_STANDARD_HUMILIATION_FULL );
	AddFileToDownloadsTable( QUAKESOUND_STANDARD_TEAMKILLER_FULL );
	AddFileToDownloadsTable( QUAKESOUND_STANDARD_HEADSHOT_FULL );
	AddFileToDownloadsTable( QUAKESOUND_STANDARD_FIRSTBLOOD_FULL );
	AddFileToDownloadsTable( QUAKESOUND_STANDARD_DOUBLEKILL_FULL );
	AddFileToDownloadsTable( QUAKESOUND_STANDARD_MULTIKILL_FULL );
	AddFileToDownloadsTable( QUAKESOUND_STANDARD_ULTRAKILL_FULL );
	AddFileToDownloadsTable( QUAKESOUND_STANDARD_MONSTERKILL_FULL );
	AddFileToDownloadsTable( QUAKESOUND_STANDARD_GRENADE_FULL );
	AddFileToDownloadsTable( QUAKESOUND_STANDARD_PLAY_FULL );
	AddFileToDownloadsTable( QUAKESOUND_LOL_EN_HUMILIATION_FULL );
	AddFileToDownloadsTable( QUAKESOUND_LOL_EN_FIRSTBLOOD_FULL );
	AddFileToDownloadsTable( QUAKESOUND_LOL_EN_DOUBLEKILL_FULL );
	AddFileToDownloadsTable( QUAKESOUND_LOL_EN_MULTIKILL_FULL );
	AddFileToDownloadsTable( QUAKESOUND_LOL_EN_ULTRAKILL_FULL );
	AddFileToDownloadsTable( QUAKESOUND_LOL_EN_MONSTERKILL_FULL );
	AddFileToDownloadsTable( QUAKESOUND_LOL_EN_GRENADE_FULL );
	PrecacheSound( QUAKESOUND_STANDARD_HUMILIATION, true );
	PrecacheSound( QUAKESOUND_STANDARD_TEAMKILLER, true );
	PrecacheSound( QUAKESOUND_STANDARD_HEADSHOT, true );
	PrecacheSound( QUAKESOUND_STANDARD_FIRSTBLOOD, true );
	PrecacheSound( QUAKESOUND_STANDARD_DOUBLEKILL, true );
	PrecacheSound( QUAKESOUND_STANDARD_MULTIKILL, true );
	PrecacheSound( QUAKESOUND_STANDARD_ULTRAKILL, true );
	PrecacheSound( QUAKESOUND_STANDARD_MONSTERKILL, true );
	PrecacheSound( QUAKESOUND_STANDARD_GRENADE, true );
	PrecacheSound( QUAKESOUND_STANDARD_PLAY, true );
	PrecacheSound( QUAKESOUND_LOL_EN_HUMILIATION, true );
	PrecacheSound( QUAKESOUND_LOL_EN_FIRSTBLOOD, true );
	PrecacheSound( QUAKESOUND_LOL_EN_DOUBLEKILL, true );
	PrecacheSound( QUAKESOUND_LOL_EN_MULTIKILL, true );
	PrecacheSound( QUAKESOUND_LOL_EN_ULTRAKILL, true );
	PrecacheSound( QUAKESOUND_LOL_EN_MONSTERKILL, true );
	PrecacheSound( QUAKESOUND_LOL_EN_GRENADE, true );
}

//====================
//OnClientPutInServer - Player has joined the server
//====================

public OnClientPutInServer( Client )
{
	if( IsClientConnected( Client ) )
	{
		// Get max players count
		iMaxClients = GetMaxClients();
		// Reset these for new client
		Combo_LastKillTime[Client] = -1.0;
		Damage_HitBox[Client] = -1;
		SDKHook( Client, SDKHook_TraceAttackPost, OnTraceAttack );
		// Load cookies
		if( AreClientCookiesCached( Client ) )
			Cookie_LoadSettings( Client );
	}
}

//====================
//OnClientCookiesCached - When a player's saved cookies have been loaded
//====================

public OnClientCookiesCached( Client )
{
	// If cookies didn't managed to be loaded during player's connection, then wait until OnClientCookiesCached()
	if( IsClientConnected( Client ) )
		Cookie_LoadSettings( Client );
}

//====================
//OnTraceAttack - Trace the line of attack and tell which hitbox we are aiming
//====================

public OnTraceAttack( Player_Victim, Player_Attacker, Inflictor, Float:Damage, Damage_Type, Ammo_Type, HitBox, HitGroup )
{
	if( HitGroup > 0 && Player_Attacker > 0 && Player_Attacker <= iMaxClients && Player_Victim > 0 && Player_Victim <= iMaxClients )
		Damage_HitBox[Player_Victim] = HitGroup;
}

//====================
//Event_RoundRestart - Round is restarting
//====================

public Event_RoundRestart( Handle:event, const String:name[], bool:dontBroadcast )
{
	// Get max players count
	iMaxClients = GetMaxClients();
	// Reset first blood
	FirstBlood = true;
	for( new i = 1 ; i <= iMaxClients ; i++ ) 
	{
		Combo_LastKillTime[i] = -1.0;
		Damage_HitBox[i] = -1;
	}
	if( RoundInProgress )
		RoundInProgress = false;
	else
	{
		PlayQuakeSound( QUAKESOUND_PLAY, 0, 0 );
		RoundInProgress = true;
	}
}

//====================
//Event_PlayerDeath - Player is dead
//====================

public Event_PlayerDeath( Handle:event, const String:name[], bool:dontBroadcast )
{
	iMaxClients = GetMaxClients();

	new Player_Attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	new Player_Victim = GetClientOfUserId( GetEventInt( event, "userid" ) );

	// Victim is really a player?
	if( Player_Victim < 1 || Player_Victim > iMaxClients )
		return;

	// Attacker is really a player?
	if( Player_Attacker > 0 && Player_Attacker <= iMaxClients )
	{
		// Suicide?
		if( Player_Victim == Player_Attacker )
			PlayQuakeSound( QUAKESOUND_SUICIDE, 0, Player_Victim );
		// Teamkill?
		else if( GetClientTeam( Player_Victim ) == GetClientTeam( Player_Attacker ) )
			PlayQuakeSound( QUAKESOUND_TEAMKILL, Player_Attacker, Player_Victim );
		else
		{
			// Get weapon's info
			decl String:Weapon_Name[64];
			GetEventString( event, "weapon", Weapon_Name, sizeof( Weapon_Name ) );
			
			// Headshot?
			if( Damage_HitBox[ Player_Victim ] == 1 )
				PlayQuakeSound( QUAKESOUND_HEADSHOT, Player_Attacker, Player_Victim );

			// First blood?
			if( FirstBlood )
			{
				PlayQuakeSound( QUAKESOUND_FIRSTBLOOD, Player_Attacker, Player_Victim );
				FirstBlood = false;
			}

			// Kill streak?
			new Float:Combo_TemporaryLastKillTime = Combo_LastKillTime[Player_Attacker];
			Combo_LastKillTime[Player_Attacker] = GetEngineTime();

			if( Combo_TemporaryLastKillTime == -1.0 || ( Combo_LastKillTime[Player_Attacker] - Combo_TemporaryLastKillTime ) > 5.0 )
				Combo_Kills[Player_Attacker] = 1;
			else
			{
				Combo_Kills[ Player_Attacker ]++;

				if( Combo_Kills[ Player_Attacker ] == 2 )
					PlayQuakeSound( QUAKESOUND_DOUBLEKILL, Player_Attacker, Player_Victim );
				else if( Combo_Kills[ Player_Attacker ] == 3 )
					PlayQuakeSound( QUAKESOUND_MULTIKILL, Player_Attacker, Player_Victim );
				else if( Combo_Kills[ Player_Attacker ] == 4 )
					PlayQuakeSound( QUAKESOUND_ULTRAKILL, Player_Attacker, Player_Victim );
				else
					PlayQuakeSound( QUAKESOUND_MONSTERKILL, Player_Attacker, Player_Victim );
			}

			// Explosive kill?
			if( StrEqual( Weapon_Name, "frag" ) || StrEqual( Weapon_Name, "ied" ) )
				PlayQuakeSound( QUAKESOUND_GRENADE, Player_Attacker, Player_Victim );
			// Melee kill?
			else if( StrEqual( Weapon_Name, "axe" ) || StrEqual( Weapon_Name, "bat_aluminium" )  || StrEqual( Weapon_Name, "bat_wood" ) || StrEqual( Weapon_Name, "broom" ) || StrEqual( Weapon_Name, "chair" ) || StrEqual( Weapon_Name, "crowbar" ) || StrEqual( Weapon_Name, "fryingpan" ) || StrEqual( Weapon_Name, "golf" ) || StrEqual( Weapon_Name, "keyboard" ) || StrEqual( Weapon_Name, "machete" ) || StrEqual( Weapon_Name, "plank" ) || StrEqual( Weapon_Name, "pot" ) || StrEqual( Weapon_Name, "racket" ) || StrEqual( Weapon_Name, "shovel" ) || StrEqual( Weapon_Name, "sledgehammer" ) || StrEqual( Weapon_Name, "spanner" ) || StrEqual( Weapon_Name, "tireiron" ) || StrEqual( Weapon_Name, "torque" ) )
				PlayQuakeSound( QUAKESOUND_HUMILIATION, Player_Attacker, Player_Victim );
		}
	}
}

//====================
//PlayQuakeSound - Play the Quake sounds
//====================

public PlayQuakeSound( SoundID, Player_Attacker, Player_Victim )
{
	// Get max players count
	iMaxClients = GetMaxClients();
	// Get attacker and victim names
	decl String:Player_Attacker_Name[MAX_NAME_LENGTH];
	decl String:Player_Victim_Name[MAX_NAME_LENGTH];

	// Is the attacker a player ?
	if( Player_Attacker && IsClientInGame( Player_Attacker ) )
		GetClientName( Player_Attacker, Player_Attacker_Name, MAX_NAME_LENGTH );
	else
		Player_Attacker_Name = "";

	// Is the victim a player ?
	if( Player_Victim && IsClientInGame( Player_Victim ) )
		GetClientName( Player_Victim, Player_Victim_Name, MAX_NAME_LENGTH );
	else
		Player_Victim_Name = "";

	for( new i = 1 ; i <= iMaxClients ; i++ )
	{
		Cookie_LoadSettings( i );
		if( IsClientInGame( i ) && !IsFakeClient( i ) && Cookie_Player[i] != 0 )
		{
			if( SoundID == QUAKESOUND_HUMILIATION )
			{
				if( Cookie_Player[i] == 2 )
					EmitSoundToClient( i, QUAKESOUND_LOL_EN_HUMILIATION );
				else
					EmitSoundToClient( i, QUAKESOUND_STANDARD_HUMILIATION );

				PrintCenterTextAll( "%s {HUMILIATION} %s", Player_Attacker_Name, Player_Victim_Name );
			}
			else if( SoundID == QUAKESOUND_TEAMKILL )
			{
				EmitSoundToClient( i, QUAKESOUND_STANDARD_TEAMKILLER );
				PrintCenterTextAll( "%s {TEAM KILL} %s", Player_Attacker_Name, Player_Victim_Name );
			}
			else if( SoundID == QUAKESOUND_HEADSHOT )
			{
				EmitSoundToClient( i, QUAKESOUND_STANDARD_HEADSHOT );
				PrintCenterTextAll( "%s {HEADSHOT} %s", Player_Attacker_Name, Player_Victim_Name );
			}
			else if( SoundID == QUAKESOUND_FIRSTBLOOD )
			{
				if( Cookie_Player[i] == 2 )
					EmitSoundToClient( i, QUAKESOUND_LOL_EN_FIRSTBLOOD );
				else
					EmitSoundToClient( i, QUAKESOUND_STANDARD_FIRSTBLOOD );

				PrintCenterTextAll( "%s {FIRST BLOOD} %s", Player_Attacker_Name, Player_Victim_Name );
			}
			else if( SoundID == QUAKESOUND_DOUBLEKILL )
			{
				if( Cookie_Player[i] == 2 )
					EmitSoundToClient( i, QUAKESOUND_LOL_EN_DOUBLEKILL );
				else
					EmitSoundToClient( i, QUAKESOUND_STANDARD_DOUBLEKILL );

				PrintCenterTextAll( "%s {DOUBLE KILL} %s", Player_Attacker_Name, Player_Victim_Name );
			}
			else if( SoundID == QUAKESOUND_MULTIKILL )
			{
				if( Cookie_Player[i] == 2 )
					EmitSoundToClient( i, QUAKESOUND_LOL_EN_MULTIKILL );
				else
					EmitSoundToClient( i, QUAKESOUND_STANDARD_MULTIKILL );

				PrintCenterTextAll( "%s {MULTI KILL} %s", Player_Attacker_Name, Player_Victim_Name );
			}
			else if( SoundID == QUAKESOUND_ULTRAKILL )
			{
				if( Cookie_Player[i] == 2 )
					EmitSoundToClient( i, QUAKESOUND_LOL_EN_ULTRAKILL );
				else
					EmitSoundToClient( i, QUAKESOUND_STANDARD_ULTRAKILL );

				PrintCenterTextAll( "%s {ULTRA KILL} %s", Player_Attacker_Name, Player_Victim_Name );
			}
			else if( SoundID == QUAKESOUND_MONSTERKILL )
			{
				if( Cookie_Player[i] == 2 )
					EmitSoundToClient( i, QUAKESOUND_LOL_EN_MONSTERKILL );
				else
					EmitSoundToClient( i, QUAKESOUND_STANDARD_MONSTERKILL );

				PrintCenterTextAll( "%s {MONSTER KILL} %s", Player_Attacker_Name, Player_Victim_Name );
			}
			else if( SoundID == QUAKESOUND_GRENADE )
			{
				EmitSoundToClient( i, QUAKESOUND_STANDARD_GRENADE );
				PrintCenterTextAll( "%s {EXPLOSIVE KILL} %s", Player_Attacker_Name, Player_Victim_Name );
			}
			else if( SoundID == QUAKESOUND_PLAY )
			{
				EmitSoundToClient( i, QUAKESOUND_STANDARD_PLAY );
				PrintCenterTextAll( "ROUND BEGINS !!!" );
			}
			else if( SoundID == QUAKESOUND_SUICIDE )
			{
				if( Cookie_Player[i] == 2 )
					EmitSoundToClient( i, QUAKESOUND_LOL_EN_HUMILIATION );
				else
					EmitSoundToClient( i, QUAKESOUND_STANDARD_HUMILIATION );

				PrintCenterTextAll( "%s {SUICIDE}", Player_Victim_Name );
			}
			else
				return;
		}
	}
}

//====================
//Command_ShowMenu - Player typed the command to show the menu
//====================

public Action:Command_ShowMenu( Client, Args )
{
	// Show the menu
	Show_Cookie_Menu( Client );

	// Avoid "Unknown command" in player's console
	return Plugin_Handled;
}

//====================
//Cookie_Menu_Select - Player has used the "settings" command to configure the plugin
//====================

public Cookie_Menu_Select( Client, CookieMenuAction:action, any:Info, String:Buffer[], MaxLen )
{
	// Don't disappear when player select an option
	if( action == CookieMenuAction_SelectOption )
		Show_Cookie_Menu( Client );
}

//====================
//Cookie_Menu_Callback - Callback for the cookie menu, store the configuration
//====================

public Cookie_Menu_Callback( Handle:Cookie_Menu_Handler, MenuAction:action, Client, Param )
{
	if( action == MenuAction_Select )
	{
		// Detect which configuration 
		if( Param == 0 )
			Cookie_Player[Client] = 0;
		else if( Param == 1 )
			Cookie_Player[Client] = 1;
		else if( Param == 2 )
			Cookie_Player[Client] = 2;

		// Temporary buffer
		decl String:Buffer[ 2 ];
		IntToString( Cookie_Player[Client], Buffer, sizeof( Buffer ) );

		// Setting the cookie
		SetClientCookie( Client, Cookie, Buffer );

		// Show the menu
		Command_ShowMenu( Client, MENU_TIME_FOREVER );
	}
	else if( action == MenuAction_Cancel )
		ShowCookieMenu( Client );
	else if( action == MenuAction_End )
		CloseHandle( Cookie_Menu_Handler );
}

//====================
//Cookie_LoadSettings - Load player's current configuration
//====================

Cookie_LoadSettings( Client )
{
	// Temporary buffer
	decl String:Buffer[2];

	// Get value and store in the buffer
	GetClientCookie( Client, Cookie, Buffer, sizeof( Buffer ) );

	// Update
	if( !StrEqual( Buffer, NULL_STRING ) )
		Cookie_Player[Client] = StringToInt( Buffer );
}

//====================
//Show_Cookie_Menu - Show the menu to configure the plugin
//====================

Show_Cookie_Menu( Client )
{
	// Create the menu and a temporary buffer
	new Handle:Cookie_Menu_Handler = CreateMenu( Cookie_Menu_Callback );
	decl String:Buffer[128];

	// Set title
	SetMenuTitle( Cookie_Menu_Handler, "Quake Sounds" );

	// Disabled
	if( Cookie_Player[Client] == 0 )
		Format( Buffer, sizeof( Buffer ), "%t", "Menu_Select_Disabled_Chosen", Client );
	else
		Format( Buffer, sizeof( Buffer ), "%t", "Menu_Select_Disabled", Client );

	AddMenuItem( Cookie_Menu_Handler, NULL_STRING, Buffer );

	// Disabled (Standard)
	if( Cookie_Player[Client] == 1 )
		Format( Buffer, sizeof( Buffer ), "%t", "Menu_Select_Standard_Chosen", Client );
	else
		Format( Buffer, sizeof( Buffer ), "%t", "Menu_Select_Standard", Client );

	AddMenuItem( Cookie_Menu_Handler, NULL_STRING, Buffer );

	// League of Legends (English)
	if( Cookie_Player[Client] == 2 )
		Format( Buffer, sizeof( Buffer ), "%t", "Menu_Select_LoL_EN_Chosen", Client );
	else
		Format( Buffer, sizeof( Buffer ), "%t", "Menu_Select_LoL_EN", Client );

	AddMenuItem( Cookie_Menu_Handler, NULL_STRING, Buffer );

	// Specify Back and Exit buttons
	SetMenuExitBackButton( Cookie_Menu_Handler, true );
	SetMenuExitButton( Cookie_Menu_Handler, false );

	// Show the menu
	DisplayMenu( Cookie_Menu_Handler, Client, MENU_TIME_FOREVER );
}
