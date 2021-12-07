#define PLUGIN_VERSION "1.2.1"
/*
v 1.2.1 - small bug fix.
v 1.2.0 - attemp to fix black screen.
		- kill item ownership on item removal.
		- Fixed client 0. Added client check on every function.
v 1.1.9 - fixed ShowBar() error.
		- attemp to fix black screen.
v 1.1.8 - fixed GetClientTeam error on client disconnected.
v 1.1.7 - fixed timer continue fireing when player incap and selfstandup_incap = 0, player ledge grab and selfstandup_ledge = 0.
		- fixed timer continue firing when player incap and being grab by SI but function turned turned off for the specific SI type.
		- added cvar list of item required to self stand up. More configureable. Requested by MasterMind420.
v 1.1.6 - add enable noclip on player self stand up to prevent animation fail (this idea is sick, way too cheat).
		- fixed timer dosen't terminat on finale (mission over).
		- fixed timer dosent terminated on client disconnect.
		- fixed minor issue with revive count on self get up ledge.
		- fixed problem timer self stand up wont fire when player being revive by team mate (timer already stop) but the Mr.Reviver dead before player completly revived.
		- add option revive team mate while incap. Requested by RavenDan29.
v 1.1.5 - fixing player dead
		- fixed zero score.
		- fixed survivor crawl problem.
v 1.1.4 - fixed progress bar loading.
		- added condition of timer termination.
		- i got complain regarding player glow conflict with other plugin so remove it.
		- fixing invalid entity on player weapon slot.
		- add option incap crawling.
		- add option thrid person on incap crawling.
		- hopefuly fixed player score.
v 1.1.3 - fixed player glow dosen't off when player die. Glow will effect player if player change team in versus.
		- rename some idiot var.
		- kill timer on player dead. My bad.
		- added cvar "selfstandup_clearance". Only allow incap player to get up if player at some radius range from zombie and SI. Requested by "MasterMind420".
		- adde cvar enable or disable check for player ledge grab who try to get up but being too close to zombie.
		- fixed countdown timer dosen't start from zero if zombie to close and player keep holding duck button (timer jump).
		- fixed duck button don't block forward button.
		- Some code update.
		- added cvar selfstandup_healthcheck for the point_system or buy_menu or player cheats... lolz..
		- added sound upon success break free from SI or success self get up (proper game behavior).
v 1.1.2 - change some slot count value.
        - relocate notify message.
		- fixed colour not changing when selfstandup_costly > 0.
		- fixed who attack player on player dead (player self kill) to prevent zero score in versus.
		- add timer check to prevent message print twice or triple.
		- adding fix timer delay for smoker (2.0 seconds) and jockey (1.0 seconds). This 2 guys too nob.
		- fixed player not turn to black & white problem when get up by team mate.
		- fixed when self get up kick in, team mate no longer allowed to lend a hand.
		- added glow type. 0:off, 1:on green only, 2: on glow only, 3:on both.
		- fixed proper name for defibrillator in chat msg.
		- added cvar plugin on/off.
		- added var check item only will be remove if player succses break free from SI or get up sucsess.
		- fixed if break free from infected cost player noting if infected killed before timer end (if selfstandup_costly > 0).
		- fixed possibility player cheat or use point system. Example, if "selfstandup_costly > 0", player buy item after being smoke (timer check already
		  run but broken half way due to no item as an exchange but player wisht to break free using point). Fixed timer dont continue, animation glitch,
		  get up wont fire again, cause player ended up 6 feet below. (Cost me 18 hrs to fix this).
		- force fire event on hunter break free (pounce_stopped) for proper game behavior.
		- removing unnecessary event.
		- little code clean up.
v 1.1.1 - fixing error IsValidSlot. My bad.
v 1.1.0 - Added option required medkit, pills, adren, (if option 2 explo and incdn count as medkit).
        - add hint text on player required medkit etc. but player do not have it.
v 1.0.6 - reset player colour and sound heart beat on player take damage (in respond to the problem - player using other plugin to restore life).
        - Fixing invalid enttity report.
		- changed notify message.
v 1.0.5 - fixed max duration of self get up timer duration.
v 1.0.4 - u need to delete the old l4d2_selfgetup.cfg in your cfg/sourcemod dir. Plugin will create new one.
        - still have minor issue with the self get up timer duration. I decide to release because the previous release mesh up.
        - changed max duration on self get up to 4.5 to prevent glitch on restoring health (animation problem).
        - little code clean up.
        - modify some cvar.
        - fixed self get up on ledge grab. Tnanks to MasterMind420 for the tips. Note: u dont need "sm_cvar z_grab_ledges_solo 1" as i already set them.
        - fixed health on ledge grab. If u green life before ledge grab, u get green life after self get up from ledge grab.
        - hopefuly fixed bug on the black and white count. Player die before black n white state (wrong counter).
v 1.0.3 - when player try to break free from infected, the attacker die before the timer end. Fixed problem with the ladder climbing.
v 1.0.2 - comment out debug Event. my bad.
v 1.0.1 - adding url. i forget this 1.
v 1.0.0 - Official release.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name		= "[L4D, L4D2] Self Get Up",
	author		= " GsiX ",
	description	= "Self help from incap, ledge grabs, and break free from infected attacks",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?t=195623"	
}

#define SOUND_KILL1			"/weapons/knife/knife_hitwall1.wav"
#define SOUND_KILL2			"/weapons/knife/knife_deploy.wav"
#define SOUND_HEART_BEAT	"player/heartbeatloop.wav"
#define SOUND_GETUP			"ui/bigreward.wav"

#define INCAP_NONE		0
#define INCAP			1
#define INCAP_LEDGE		2

#define STATE_NONE		0
#define STATE_SELFGETUP	1
#define STATE_GETUP		2

#define NONE			0
#define SMOKER			1
#define HUNTER			3
#define JOCKEY			5
#define CHARGER			6
#define TANK			8

/*--  Developer  -- */
new bool:debugMSG		= false;
new bool:debugEvent		= false;
new bool:debugMSGTimer	= false;
new bool:debugTeamTimer	= false;
/*      ----        */

new Handle:selfstandup_enable			= INVALID_HANDLE;
new Handle:selfstandup_hint_delay		= INVALID_HANDLE;
new Handle:selfstandup_delay			= INVALID_HANDLE;
new Handle:selfstandup_duration			= INVALID_HANDLE;
new Handle:selfstandup_health_incap		= INVALID_HANDLE;
new Handle:selfstandup_grab				= INVALID_HANDLE;
new Handle:selfstandup_pounce			= INVALID_HANDLE;
new Handle:selfstandup_ride				= INVALID_HANDLE;
new Handle:selfstandup_pummel			= INVALID_HANDLE;
new Handle:selfstandup_ledge			= INVALID_HANDLE;
new Handle:selfstandup_incap			= INVALID_HANDLE;
new Handle:selfstandup_kill				= INVALID_HANDLE;
new Handle:selfstandup_versus			= INVALID_HANDLE;
new Handle:selfstandup_bot				= INVALID_HANDLE;
new Handle:selfstandup_blackwhite		= INVALID_HANDLE;
new Handle:selfstandup_count_msg		= INVALID_HANDLE;
new Handle:selfstandup_color			= INVALID_HANDLE;
new Handle:selfstandup_costly			= INVALID_HANDLE;
new Handle:selfstandup_costly_item		= INVALID_HANDLE;
new Handle:selfstandup_clearance		= INVALID_HANDLE;
new Handle:selfstandup_clearance_ledge	= INVALID_HANDLE;
new Handle:selfstandup_healthcheck		= INVALID_HANDLE;
new Handle:selfstandup_crawl			= INVALID_HANDLE;
new Handle:selfstandup_crawl_speed		= INVALID_HANDLE;
new Handle:selfstandup_crawl_third		= INVALID_HANDLE;
new Handle:selfstandup_team				= INVALID_HANDLE;

new Handle:g_Timers[MAXPLAYERS+1]			= { INVALID_HANDLE, ... };
new Handle:g_TimerTeam[MAXPLAYERS+1]		= { INVALID_HANDLE, ... };
new Handle:g_TimerScanMsg[MAXPLAYERS+1]		= { INVALID_HANDLE, ... };
new Float:g_HelpStartTime[MAXPLAYERS+1]		= { 0.0, ... };
new Float:g_UpIncapOrLedge					= 0.0;

new g_EnemyScan[MAXPLAYERS+1]			= { 0, ... };
new bool:L4D2Version					= false;

new g_HelpState[MAXPLAYERS+1]			= { 0, ... };
new g_ReviveHealth[MAXPLAYERS+1][2];
new g_Attacker[MAXPLAYERS+1]			= { 0, ... };
new g_ZombieClass[MAXPLAYERS+1]			= { 0, ... };
new g_PlayerWeaponSlot[MAXPLAYERS+1]	= { 0, ... };
new g_IdiotHelper[MAXPLAYERS+1]			= { 0, ... };
new g_CheckSlapper[MAXPLAYERS+1]		= { 0, ... };
new g_NotifyCheck[MAXPLAYERS+1]			= { 0, ... };
new g_IncapCheck[MAXPLAYERS + 1]		= { 0, ... };
new g_HelpTeamStatus[MAXPLAYERS+1]		= { 0, ... };
new bool:g_TeamButtInter[MAXPLAYERS+1]	= { false, ... };
new GameMode;

new bool:g_Pills			= false;
new bool:g_Adrenaline		= false;
new bool:g_Med_Kit			= false;
new bool:g_Defibrillator	= false;
new bool:g_Incendiary		= false;
new bool:g_Explosive		= false;

// code from panxiohai
new String:Gauge1[2] = "-";
new String:Gauge3[2] = "#";

public OnPluginStart()
{
	CreateConVar("selfstandup_version", PLUGIN_VERSION, " ", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	selfstandup_enable			= CreateConVar("selfstandup_enable",			"1",	"0: off,  1: on,  Plugin On/Off", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_hint_delay		= CreateConVar("selfstandup_hint_delay",		"1.0",	"0: turn off,  1 and above: Self stand up hint delay", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_delay			= CreateConVar("selfstandup_delay",				"1.0",	"Self stand up delay the timer to kick in", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_duration		= CreateConVar("selfstandup_duration",			"5.0",	"Min:0, Max: 5.0, Self stand up Duration", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_health_incap	= CreateConVar("selfstandup_health_incap",		"40.0",	"How much health after reviving from incapacitation.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_ledge			= CreateConVar("selfstandup_ledge",				"1",	"Self stand up for ledge grabs, 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);		
	selfstandup_incap			= CreateConVar("selfstandup_incap",				"1",	"Self stand up for incapacitation, 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_grab			= CreateConVar("selfstandup_grab",				"1",	"Self stand up for smoker grab, 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_pounce			= CreateConVar("selfstandup_pounce",			"1",	"Self stand up for hunter pounce, 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_ride			= CreateConVar("selfstandup_ride",				"1",	"Self stand up for jockey ride, 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_pummel			= CreateConVar("selfstandup_pummel",			"1",	"Self stand up for charger pummel , 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_kill			= CreateConVar("selfstandup_kill",				"0",	"0: Do not kill special infected when breaking free; 1: Kill special infected when breaking free", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);	
	selfstandup_versus			= CreateConVar("selfstandup_versus",			"0",	"0: Disable in versus, 1: Enable in versus", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_bot				= CreateConVar("selfstandup_bot",				"1",	"0: Disable for bot, 1: Enable for bot", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_blackwhite		= CreateConVar("selfstandup_max",				"2",	"value only 1 and above = max incap count to black n white (off function = 9999 or what ever)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_count_msg		= CreateConVar("selfstandup_count_msg",			"1",	"0:Off,   1:on  notify count on chat", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_color			= CreateConVar("selfstandup_color",				"1",	"0:off, 1:On, Green colour on last life", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_costly			= CreateConVar("selfstandup_costly",			"1",	"0:Off,   1:On, Function to turn on required item to break free from infected or self stand up", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_costly_item		= CreateConVar("selfstandup_costly_item",		"med_kit, pills, adrenaline, defibrillator, incendiary, explosive",	"List of item allowed sparated by comma, 'selfstandup_costly' must on (med_kit, pills, adrenaline, defibrillator, incendiary, explosive)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_clearance		= CreateConVar("selfstandup_clearance",			"200.0", "0: Off,   200.0: on, max radius scan range (only allow incap player to get up if player at this range from zombie and SI)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_clearance_ledge	= CreateConVar("selfstandup_clearance_ledge",	"0",	"0: Off (allowed player get up, ignore near by zombie), 1:on (block get up ledge if there is near by zombie, not recomended unless u wan something harder))", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_healthcheck		= CreateConVar("selfstandup_healthcheck",		"1",	"0: Off, 1:on,  turn this on if u use pont_system or buys_menu or any cheats)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_crawl			= CreateConVar("selfstandup_crawl",				"1",	"0: Off, 1:on,  Allow player crawling on incap)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_crawl_speed		= CreateConVar("selfstandup_crawl_speed",		"50",	"How fast player crawl when incap)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_crawl_third		= CreateConVar("selfstandup_crawl_third",		"1",	"0:First person view on crawling, 1:Third person view on crawling)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_team			= CreateConVar("selfstandup_team",				"1",	"0:Off, 1:On, Enable/disable revive team mate while player incap)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	AutoExecConfig( true, "l4d2_selfstandup" );
	GameCheck();
	
	HookEvent( "lunge_pounce",					EVENT_LungePounce );
	HookEvent( "pounce_stopped",				EVENT_PounceStopped );
	HookEvent( "tongue_grab",					EVENT_TongueGrab );
	HookEvent( "tongue_release",				EVENT_TongueRelease );
	if ( L4D2Version )
	{
		HookEvent( "jockey_ride",				EVENT_JockeyRide );
		HookEvent( "jockey_ride_end",			EVENT_JockeyRideEnd );
		HookEvent( "charger_pummel_start",		EVENT_ChargerPummelStart );
		HookEvent( "charger_pummel_end",		EVENT_ChargerPummelEnd );
	}	
	HookEvent( "player_incapacitated",			EVENT_PlayerIncapacitated );
	HookEvent( "player_ledge_grab",				EVENT_PlayerLedgeGrab );
	HookEvent( "player_hurt",					EVENT_PlayerHurt );
	HookEvent( "player_death",					EVENT_PlayerDeath );
	HookEvent( "survivor_rescued",				EVENT_SurvivorRescued );
	HookEvent( "revive_begin",					EVENT_ReviveBegin );
	HookEvent( "revive_end",					EVENT_ReviveEnd );
	HookEvent( "revive_success",				EVENT_ReviveSuccess );
	HookEvent( "player_spawn",					EVENT_PlayerSpawn );
	HookEvent( "round_start",					EVENT_RoundStart );
	HookEvent( "round_end",						EVENT_RoundEnd );
	HookEvent( "heal_success",					EVENT_HealSuccess );
	HookConVarChange( selfstandup_enable,		bw_CVARChanged );
	HookConVarChange( selfstandup_versus,		bw_CVARChanged );
	HookConVarChange( selfstandup_blackwhite,	bw_CVARChanged );
	HookConVarChange( selfstandup_duration, 	bw_CVARChanged );
	HookConVarChange( selfstandup_health_incap,	bw_CVARChanged );
	
	UdateCvarChange();
}

GameCheck()
{
	// code from pan xiohai
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
	{
		GameMode = 3;
	}
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
	{
		GameMode = 2;
	}
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
	{
		GameMode = 1;
	}
	else
	{
		GameMode = 0;
 	}
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		L4D2Version=true;
	}	
	else
	{ 
		L4D2Version=false;
	}
}

UdateCvarChange()
{
	GameCheck();
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0) || ( GetConVarInt( selfstandup_enable ) == 0 ))
	{
		SetConVarInt( FindConVar( "survivor_max_incapacitated_count" ), 2 );
		SetConVarInt( FindConVar( "survivor_revive_duration" ), 5 );
		SetConVarInt( FindConVar( "z_grab_ledges_solo" ), 0 );
		SetConVarInt( FindConVar( "survivor_revive_health" ), 30 );
	}
	else
	{
		SetConVarInt( FindConVar( "survivor_max_incapacitated_count" ), GetConVarInt( selfstandup_blackwhite ));
		SetConVarInt( FindConVar( "survivor_revive_health" ), GetConVarInt( selfstandup_health_incap ));
		if ( GetConVarInt( selfstandup_duration ) > 0 )
		{
			SetConVarInt( FindConVar( "survivor_revive_duration" ), GetConVarInt( selfstandup_duration ));
		}
		if ( GetConVarInt( selfstandup_ledge ) > 0 )
		{
			SetConVarInt( FindConVar( "z_grab_ledges_solo" ), 1 );
		}
	}
}

public OnMapStart()
{
 	GameCheck();
	if(L4D2Version)
	{
		PrecacheSound( SOUND_KILL2, true );
	}
	else
	{
		PrecacheSound( SOUND_KILL1, true );
	}
	PrecacheSound( SOUND_HEART_BEAT, true );
	PrecacheSound( SOUND_GETUP, true );
	
	UdateCvarChange();
}

public OnConfigsExecuted()
{
	UdateCvarChange();
}

public OnClientPutInServer( client )
{
	if ( client > 0 && client <= MaxClients )
	{
		g_IdiotHelper[client]		= 0; 
		g_HelpTeamStatus[client]	= 0;
		g_TeamButtInter[client]		= true;
		g_Attacker[client]			= 0;
		g_HelpStartTime[client]		= 0.0;
		g_Timers[client]			= INVALID_HANDLE;
		g_TimerTeam[client]			= INVALID_HANDLE;
	}
}

public OnClientDisconnect( client )
{
	if ( client > 0 && client <= MaxClients )
	{
		g_HelpTeamStatus[client]	= 0;
		g_TeamButtInter[client]		= true;
		g_Attacker[client]			= 0;
		g_HelpStartTime[client]		= 0.0;
		g_HelpState[client]			= STATE_NONE;
		
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( g_IdiotHelper[i] == client )
			{
				g_IdiotHelper[i] = 0;
				break;
			}
		}
	}
	if ( debugEvent ) PrintToServer( "------ Event client disconnect ------" );
}

public bw_CVARChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UdateCvarChange();
}

public EVENT_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if ( IsValidSurvivor( i ))
		{
			g_ReviveHealth[i][0]	= 0;			
			g_ReviveHealth[i][1]	= 0;			
			g_Attacker[i]			= 0;
			g_HelpState[i]			= STATE_NONE;
			g_IdiotHelper[i]		= 0;
			g_ZombieClass[i]		= NONE;
			g_NotifyCheck[i]		= 0;
			g_IncapCheck[i]			= 0;
			g_HelpTeamStatus[i]		= 0;
			g_HelpStartTime[i]		= 0.0;
			g_TeamButtInter[i]		= false;
			g_EnemyScan[i]			= 0;
			g_PlayerWeaponSlot[i]	= -1;
			g_Timers[i]				= INVALID_HANDLE;
			g_TimerTeam[i]			= INVALID_HANDLE;
			g_TimerScanMsg[i]		= INVALID_HANDLE;
		}
	}
	
	if ( GetConVarInt( selfstandup_crawl ) > 0 )
	{
		SetConVarInt( FindConVar( "survivor_allow_crawling" ), 1 );
		SetConVarInt( FindConVar( "survivor_crawl_speed" ), GetConVarInt( selfstandup_crawl_speed ));
	}
	
	if ( debugEvent )	PrintToServer("------ EVENT_RoundStart ------");
}

public EVENT_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarInt( FindConVar( "survivor_allow_crawling" ), 0 );
	SetConVarInt( FindConVar( "survivor_crawl_speed" ), 15 );
	
	if ( debugEvent ) PrintToServer( "------ EVENT_RoundEnd ------" );
}

public EVENT_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0 ) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( victim ))
	{
		SetEntProp( victim, Prop_Data, "m_MoveType", 2 );
		SetEntProp( victim, Prop_Data, "m_takedamage", 2, 1 );
		GetClientHP( victim );
		
		g_Attacker[victim]			= 0;
		g_HelpState[victim]			= STATE_NONE;
		g_IdiotHelper[victim]		= 0;
		g_ZombieClass[victim]		= NONE;
		g_NotifyCheck[victim]		= 0;
		g_IncapCheck[victim]		= 0;
		g_HelpTeamStatus[victim]	= 0;
		g_HelpStartTime[victim]		= 0.0;
		g_TeamButtInter[victim]		= true;
		g_EnemyScan[victim]			= 0;
		g_PlayerWeaponSlot[victim]	= -1;
		g_Timers[victim]			= INVALID_HANDLE;
		g_TimerTeam[victim]			= INVALID_HANDLE;
		g_TimerScanMsg[victim]		= INVALID_HANDLE;
		CreateTimer( 0.1, ResetReviveCount, victim );
		if ( debugEvent ) PrintToServer( "------ EVENT_PlayerSpawn ------" );
	}
}

public EVENT_TongueGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( debugEvent ) PrintToServer( "------ EVENT_TongueGrab ------" );
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0 ) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "victim" ));
	new attacker = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( victim ))
	{
		g_Attacker[victim]			= attacker;
		g_HelpState[victim]			= STATE_NONE;
		g_ZombieClass[victim]		= SMOKER;
		g_CheckSlapper[attacker]	= 0;
		if ( !IsValidSlot( victim ) && GetConVarInt( selfstandup_costly ) > 0 )
		{
			if ( GetConVarFloat( selfstandup_hint_delay ) > 0.0 )
			{
				CreateTimer( GetConVarFloat( selfstandup_hint_delay ), Timer_RequiredItemBreakDelay, victim );
			}
			return;
		}
		if ( GetConVarInt( selfstandup_grab ) > 0 )
		{
			CreateTimer(( GetConVarFloat( selfstandup_delay ) + 2.0 ), Timer_SelfGetUPDelay, victim );
		}
	}
}

public EVENT_TongueRelease (Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( debugEvent ) PrintToServer("------ EVENT_TongueRelease ------");
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0 ) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "victim" ));

	if ( IsValidSurvivor( victim ))
	{
		if ( IsNo_Incap( victim ) || IsNo_IncapLedge( victim ))
		{
			g_Attacker[victim]		= NONE;
			g_NotifyCheck[victim]	= 1;
			g_HelpState[victim]		= STATE_GETUP;
		}
		else
		{
			g_HelpState[victim]		= STATE_NONE;
		}
		g_ZombieClass[victim]		= NONE;
	}
}

public EVENT_LungePounce ( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( debugEvent ) PrintToServer( "------ EVENT_LungePounce ------" );
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0 ) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "victim" ));
	new attacker = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( victim ))
	{
		g_Attacker[victim]			= attacker;
		g_HelpState[victim]			= STATE_NONE;
		g_ZombieClass[victim]		= HUNTER;
		g_CheckSlapper[attacker]	= 0;
		if ( !IsValidSlot( victim ) && GetConVarInt( selfstandup_costly ) > 0 )
		{
			if ( GetConVarFloat( selfstandup_hint_delay ) > 0.0 )
			{
				CreateTimer( GetConVarFloat( selfstandup_hint_delay ), Timer_RequiredItemBreakDelay, victim );
			}
			return;
		}
		if ( GetConVarInt( selfstandup_pounce ) > 0 )
		{
			CreateTimer( GetConVarFloat( selfstandup_delay ), Timer_SelfGetUPDelay, victim );
		}
	}
}

public EVENT_PounceStopped (Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( debugEvent ) PrintToServer("------ EVENT_PounceStopped ------");
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0 ) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "victim" ));

	if ( IsValidSurvivor( victim ))
	{
		if ( IsNo_Incap( victim ) || IsNo_IncapLedge( victim ))
		{
			g_Attacker[victim]		= NONE;
			g_NotifyCheck[victim]	= 1;
			g_HelpState[victim]		= STATE_GETUP;
		}
		else
		{
			g_HelpState[victim]		= STATE_NONE;
		}
		g_ZombieClass[victim]		= NONE;
	}
}

public EVENT_JockeyRide (Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( debugEvent ) PrintToServer("------ EVENT_JockeyRide ------");
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0 ) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "victim" ));
	new attacker = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( victim ))
	{
		g_Attacker[victim]			= attacker;
		g_HelpState[victim]			= STATE_NONE;
		g_ZombieClass[victim]		= JOCKEY;
		g_CheckSlapper[attacker]	= 0;
		if ( !IsValidSlot( victim ) && GetConVarInt( selfstandup_costly ) > 0 )
		{
			if ( GetConVarFloat( selfstandup_hint_delay ) > 0.0 )
			{
				CreateTimer( GetConVarFloat( selfstandup_hint_delay ), Timer_RequiredItemBreakDelay, victim );
			}
			return;
		}
		if ( GetConVarInt( selfstandup_ride ) > 0 )
		{
			CreateTimer(( GetConVarFloat( selfstandup_delay ) + 1.0 ), Timer_SelfGetUPDelay, victim );
		}
	}
}

public EVENT_JockeyRideEnd ( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( debugEvent ) PrintToServer( "------ EVENT_JockeyRideEnd ------" );
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0 ) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "victim" ));

	if ( IsValidSurvivor( victim ))
	{
		if ( IsNo_Incap( victim ) || IsNo_IncapLedge( victim ))
		{
			g_Attacker[victim]		= NONE;
			g_NotifyCheck[victim]	= 1;
			g_HelpState[victim]		= STATE_GETUP;
		}
		else
		{
			g_HelpState[victim]		= STATE_NONE;
		}
		g_ZombieClass[victim]		= NONE;
	}
}

public EVENT_ChargerPummelStart ( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( debugEvent ) PrintToServer( "------ EVENT_ChargerPummelStart ------" );
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0 ) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "victim" ));
	new attacker = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( victim ))
	{
		g_Attacker[victim]			= attacker;
		g_HelpState[victim]			= STATE_NONE;
		g_ZombieClass[victim]		= CHARGER;
		g_CheckSlapper[attacker]	= 0;
		if ( !IsValidSlot( victim ) && GetConVarInt( selfstandup_costly ) > 0 )
		{
			if ( GetConVarFloat( selfstandup_hint_delay ) > 0.0 )
			{
				CreateTimer( GetConVarFloat( selfstandup_hint_delay ), Timer_RequiredItemBreakDelay, victim);
			}
			return;
		}
		if ( GetConVarInt( selfstandup_pummel ) > 0 )
		{
			CreateTimer( GetConVarFloat( selfstandup_delay ), Timer_SelfGetUPDelay, victim );
		}
	}
}

public EVENT_ChargerPummelEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( debugEvent ) PrintToServer("------ EVENT_ChargerPummelEnd ------");
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0 ) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "victim" ));

	if ( IsValidSurvivor( victim ))
	{
		if ( IsNo_Incap( victim ) || IsNo_IncapLedge( victim ))
		{
			g_Attacker[victim]		= NONE;
			g_NotifyCheck[victim]	= 1;
			g_HelpState[victim]		= STATE_GETUP;
		}
		else
		{
			g_HelpState[victim]		= STATE_NONE;
		}
		g_ZombieClass[victim]		= NONE;
	}
}

public EVENT_PlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0 ) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( victim ))
	{
		g_HelpState[victim] = STATE_NONE;
	
		if ( GetConVarInt( selfstandup_crawl_third ) > 0 )
		{
			GotoThirdPerson( victim );
		}
		
		if ( !IsValidSlot( victim ) && GetConVarInt( selfstandup_costly ) > 0 )
		{
			if ( GetConVarFloat( selfstandup_hint_delay ) > 0.0 )
			{
				CreateTimer( GetConVarFloat( selfstandup_hint_delay ), Timer_RequiredItemBreakDelay, victim );
			}
			return;
		}
		if ( GetConVarInt( selfstandup_incap) > 0 && g_ZombieClass[victim] == NONE )
		{
			g_IncapCheck[victim] = 1;
			CreateTimer( GetConVarFloat( selfstandup_delay ), Timer_SelfGetUPDelay, victim );
		}
		
		GetClientHP( victim );
		if ( debugEvent ) PrintToServer("------ EVENT_PlayerIncapacitated ------");
	}
}

public EVENT_PlayerLedgeGrab ( Handle:event, const String:name[], bool:dontBroadcast )
{
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0 ) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( victim ))
	{
		g_HelpState[victim] = STATE_NONE;
		if ( g_Timers[victim] != INVALID_HANDLE )
		{
			KillTimer( g_Timers[victim] );
			g_Timers[victim] = INVALID_HANDLE;
		}
		
		if ( g_TimerTeam[victim] != INVALID_HANDLE )
		{
			KillTimer( g_TimerTeam[victim] );
			g_TimerTeam[victim] = INVALID_HANDLE;
		}

		if ( !IsValidSlot( victim ) && GetConVarInt( selfstandup_costly ) > 0 )
		{
			if ( GetConVarFloat( selfstandup_hint_delay ) > 0.0 )
			{
				CreateTimer( GetConVarFloat( selfstandup_hint_delay ), Timer_RequiredItemBreakDelay, victim );
			}
			return;
		}
		if ( GetConVarInt( selfstandup_ledge ) > 0 )
		{
			CreateTimer( GetConVarFloat( selfstandup_delay ), Timer_SelfGetUPDelay, victim );
		}
		if ( debugEvent ) PrintToServer("------ EVENT_PlayerLedgeGrab ------");
	}
}

public Action:Timer_SelfGetUPDelay( Handle:timer, any:victim )
{
	if (IsValidSurvivor( victim ))
	{
		if ( IsFakeClient( victim ) && GetConVarInt( selfstandup_bot ) == 0 ) return;
		g_UpIncapOrLedge = GetConVarFloat( selfstandup_duration );
		if ( GetConVarFloat( selfstandup_hint_delay ) > 0.0 )
		{
			if ( GetConVarInt( selfstandup_incap ) > 0 || GetConVarInt( selfstandup_ledge ) > 0 )
			{
				CreateTimer( GetConVarFloat( selfstandup_hint_delay ), Timer_HintDelay, victim );
			}
			if ( GetConVarInt( selfstandup_team ) > 0 && g_ZombieClass[victim] == NONE )
			{
				CreateTimer(( GetConVarFloat( selfstandup_hint_delay ) + 2.0 ), Timer_HintDelayTeam, victim );
			}
		}
		
		// dont set the timer less than 0.2 or timer "Timer_GetUp" will fail.
		if ( g_Timers[victim] == INVALID_HANDLE )
		{
			g_Timers[victim] = CreateTimer( 0.2, Timer_SelfGetUP, victim, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
		}
	}
}

public Action:Timer_HintDelay( Handle:timer, any:victim )
{
	if ( IsClientInGame( victim ) && IsPlayerAlive( victim ))
	{
		if ( debugEvent ) PrintToChat( victim, "[SELFGETUP] Hint Self revive");
		PrintHintText( victim, "++ hold DUCK to help yourself ++" );
	}
	return Plugin_Stop;
}

public Action:Timer_HintDelayTeam( Handle:timer, any:victim )
{
	if ( IsClientInGame( victim ) && IsPlayerAlive( victim ))
	{
		if ( debugEvent ) PrintToChat( victim, "[SELFGETUP] Hint help team mate");
		PrintHintText( victim, "++ hold RELOAD to help team mate ++" );
	}
	return Plugin_Stop;
}

public Action:Timer_RequiredItemBreakDelay( Handle:timer, any:victim )
{
	if ( IsValidSurvivor( victim ))
	{
		if ( debugEvent ) PrintToChat( victim, "[SELFGETUP] Hint Hint dont have item" );
		PrintHintText(victim, "-- You Dont Have Required Item --");
	}
	return Plugin_Stop;
}

public Action:Timer_SelfGetUP( Handle:timer, any:victim )
{
	if ( IsValidSurvivor( victim ) && g_HelpTeamStatus[victim] == 0 && g_HelpState[victim] != STATE_GETUP && (( !IsNo_Incap( victim ) || !IsNo_IncapLedge( victim )) || IsInfectedOwner( victim )))
	{
		if ( !IsNo_Incap( victim ) && g_UpIncapOrLedge > 5.0 ) g_UpIncapOrLedge = 5.0;
		if ( !IsNo_IncapLedge( victim ) && g_UpIncapOrLedge > 4.0 ) g_UpIncapOrLedge = 4.0;
		
		new Float:time = GetEngineTime();
		if ( GetClientButtons( victim ) & IN_DUCK || IsFakeClient( victim ))
		{
			if ( g_HelpState[victim] == STATE_NONE )
			{
				g_HelpStartTime[victim] = time;
				if (( !IsNo_Incap( victim ) || !IsNo_IncapLedge( victim )) && g_ZombieClass[victim] == NONE )
				{
					SetEntProp( victim, Prop_Data, "m_MoveType", 0 );
					SetEntPropEnt( victim, Prop_Send, "m_reviveOwner", victim );
				}
				ShowBar( victim, time - g_HelpStartTime[victim], g_UpIncapOrLedge );
				Load_Unload_ProgressBar( victim, g_UpIncapOrLedge );
				g_HelpState[victim] = STATE_SELFGETUP;
				if ( debugMSG ) PrintToServer( "[SELFSTANDUP]: HelpState = STATE_NONE" );
			}

			if ( g_HelpState[victim] == STATE_SELFGETUP )
			{
				if ( GetConVarFloat( selfstandup_clearance ) > 0.0 )
				{
					if ( ScanEnemy( victim ) == 0 || g_ZombieClass[victim] != NONE || ( GetConVarInt( selfstandup_clearance_ledge ) == 0 && !IsNo_IncapLedge( victim )))
					{
						RunEngine( victim, time, g_UpIncapOrLedge );
					}
					else
					{
						StopEngine( victim );
					}
				}
				else
				{
					RunEngine( victim, time, g_UpIncapOrLedge );
				}
				if ( debugMSG ) PrintToServer( "[SELFSTANDUP]: HelpState = STATE_SELFGETUP" );
			}
			return Plugin_Continue;
		}
		// duck button released so we reset the engine & wait for the button again
		else 
		{
			if ( debugMSG ) PrintToServer("[SELFSTANDUP]: Button DUCK released");
			if ( g_HelpTeamStatus[victim] == 0 )
			{
				SetEntProp( victim, Prop_Data, "m_MoveType", 2 );
			}
			
			g_TimerScanMsg[victim]	= INVALID_HANDLE;
			ShowBar( victim, -1.0, g_UpIncapOrLedge );
			
			if ( g_IdiotHelper[victim] < 1 )
			{
				Load_Unload_ProgressBar( victim, 0.0 );
			}
			if ( g_HelpState[victim] == STATE_SELFGETUP )
			{
				if (( !IsNo_Incap( victim ) || !IsNo_IncapLedge( victim )) && !IsInfectedOwner( victim ) && g_IdiotHelper[victim] == 0 )
				{
					SetEntPropEnt( victim, Prop_Send, "m_reviveOwner", -1 );
				}
				g_HelpState[victim] = STATE_NONE;
			}
			return Plugin_Continue;
		}
	}
	
	// player dead, gone, get up or whatever so we terminate the timer.
	g_IncapCheck[victim] = 0;
	if ( IsValidSurvivor( victim ))
	{
		ShowBar( victim, -1.0, g_UpIncapOrLedge );
		if ( g_HelpTeamStatus[victim] == 0 )
		{
			SetEntProp( victim, Prop_Data, "m_MoveType", 2 );
		}
		if ( g_IdiotHelper[victim] == 0 )
		{
			Load_Unload_ProgressBar( victim, 0.0 );
		}
	}

	g_Timers[victim] = INVALID_HANDLE;
	
	if ( debugMSG || debugEvent ) PrintToServer("[SELFSTANDUP]: Timer_SelfGetUP terminated");
	return Plugin_Stop;
}

public Action:EVENT_ReviveBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( debugEvent ) PrintToServer( "------ EVENT_ReviveBegin ------" );
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0 ) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "subject" ));
	new helper = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( victim ))
	{
		if ( !IsNo_Incap( victim ) || !IsNo_IncapLedge( victim ))
		{
			g_HelpState[victim]		= STATE_GETUP;
			g_IdiotHelper[victim]	= helper;
		}
	}
}

public Action:EVENT_ReviveEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( debugEvent ) PrintToServer( "------ EVENT_ReviveEnd ------" );
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0 ) || ( GetConVarInt( selfstandup_enable ) == 0 )) return ;
	new victim = GetClientOfUserId( GetEventInt( event, "subject" ));
	if ( IsValidSurvivor( victim ))
	{
		g_IdiotHelper[victim]	= 0;
		g_HelpState[victim]		= STATE_NONE;
		
		if ( !IsNo_Incap( victim ) || !IsNo_IncapLedge( victim ))
		{
			if ( g_Timers[victim] == INVALID_HANDLE )
			{
				if (( !IsNo_Incap( victim ) && GetConVarInt( selfstandup_incap ) == 0) || ( !IsNo_IncapLedge(victim) && GetConVarInt( selfstandup_ledge ) == 0))
				{
					return;
				}
				
				if ( !IsValidSlot( victim ) && GetConVarInt( selfstandup_costly ) > 0 )
				{
					if ( GetConVarFloat( selfstandup_hint_delay) > 0.0 )
					{
						CreateTimer( GetConVarFloat( selfstandup_hint_delay ), Timer_RequiredItemBreakDelay, victim );
					}
					return;
				}
				CreateTimer( GetConVarFloat( selfstandup_delay ), Timer_SelfGetUPDelay, victim );
			}
		}
	}
}

public EVENT_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( victim > 0 && victim <= MaxClients )
	{
		if ( IsClientConnected( victim ) && GetClientTeam( victim ) == 2 )
		{
			SetEntProp( victim, Prop_Data, "m_MoveType", 2 );
			SetEntProp( victim, Prop_Data, "m_takedamage", 2, 1 );
			
			StopBeat(victim);
			
			g_Attacker[victim]			= 0;
			g_NotifyCheck[victim]		= 0;
			g_IncapCheck[victim]		= 0;
			g_HelpTeamStatus[victim]	= 0;
			g_TeamButtInter[victim]		= true;
			g_ZombieClass[victim]		= NONE;
			g_HelpState[victim]			= STATE_NONE;
			g_TimerScanMsg[victim]		= INVALID_HANDLE;
			g_IdiotHelper[victim]		= 0;
			
			if ( debugEvent ) PrintToServer("------ EVENT_PlayerDeath ------");
		}
		
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( g_IdiotHelper[i] == victim )
			{
				g_IdiotHelper[i] = 0;
			}
			if ( g_HelpTeamStatus[i] == victim )
			{
				g_HelpTeamStatus[i] = 0;
			}
		}
	}
}

public EVENT_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0 ) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( victim ))
	{
		GetClientHP( victim );
		if (( GetEntProp( victim, Prop_Send, "m_currentReviveCount" ) < GetConVarInt( selfstandup_blackwhite )) && ( GetConVarInt( selfstandup_healthcheck ) == 1 ) && IsNo_Incap( victim ))
		{
			// in respond other plugin may mod player health, we preform this.
			StopBeat( victim );
			SetEntProp( victim, Prop_Send, "m_bIsOnThirdStrike", 0 );
			if ( GetConVarInt( selfstandup_color) > 0 )
			{
				SetEntityRenderMode( victim, RENDER_TRANSCOLOR );
				SetEntityRenderColor( victim, 255, 255, 255, 255 );
			}
		}
		
		// incase our engine break down in the middle of some things, we restart them.
		if (( !IsNo_Incap( victim ) && GetConVarInt( selfstandup_incap ) == 0) || ( !IsNo_IncapLedge(victim) && GetConVarInt( selfstandup_ledge ) == 0))
		{
			return;
		}
		
		if ( !IsNo_Incap( victim ) && g_ZombieClass[victim] != NONE )
		{
			if ( GetConVarInt( selfstandup_grab )	== 0 && g_ZombieClass[victim] == SMOKER ) return;
			if ( GetConVarInt( selfstandup_pounce )	== 0 && g_ZombieClass[victim] == HUNTER ) return;
			if ( GetConVarInt( selfstandup_ride )	== 0 && g_ZombieClass[victim] == JOCKEY ) return;
			if ( GetConVarInt( selfstandup_pummel )	== 0 && g_ZombieClass[victim] == CHARGER ) return;
		}
		
		if (( !IsNo_Incap( victim ) || !IsNo_IncapLedge( victim )) && ( g_IdiotHelper[victim] == 0 ) && ( g_Timers[victim] == INVALID_HANDLE ) && ( g_IncapCheck[victim] == 0 ) && g_HelpTeamStatus[victim] == 0 )
		{
			if ( !IsValidSlot( victim ) && GetConVarInt( selfstandup_costly ) > 0 )
			{
				if ( GetConVarFloat( selfstandup_hint_delay) > 0.0 )
				{
					CreateTimer( GetConVarFloat( selfstandup_hint_delay ), Timer_RequiredItemBreakDelay, victim );
				}
				return;
			}
			
			g_IncapCheck[victim] = 1;
			g_HelpState[victim] = STATE_NONE;
			CreateTimer( GetConVarFloat( selfstandup_delay ), Timer_SelfGetUPDelay, victim );
			if(!IsNo_IncapLedge(victim) && (debugMSG || debugEvent)) PrintToServer("[SELFSTANDUP]: Timer incap ledge restarted");
			else if(!IsNo_Incap(victim) && (debugMSG || debugEvent)) PrintToServer("[SELFSTANDUP]: Timer incap restarted");
		}
		if(debugEvent) PrintToServer("------ EVENT_PlayerHurt ------");
	}
}

public EVENT_SurvivorRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( debugEvent ) PrintToServer( "------ EVENT_SurvivorRescued ------" );
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0 ) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "subject" ));
	if ( IsValidSurvivor( victim ))
	{
		SetEntProp( victim, Prop_Data, "m_MoveType", 2 );
		SetEntProp( victim, Prop_Data, "m_takedamage", 2, 1 );
		
		g_Attacker[victim]			= 0;
		g_IncapCheck[victim]		= 0;
		g_HelpTeamStatus[victim]	= 0;
		g_HelpState[victim]			= STATE_NONE;
		
		GetClientHP( victim );
		
		g_EnemyScan[victim]			= 0;
		g_TeamButtInter[victim]		= true;
		g_IdiotHelper[victim]		= 0;
		g_PlayerWeaponSlot[victim]	= 0;
		g_ZombieClass[victim]		= NONE;
		g_Timers[victim]			= INVALID_HANDLE;
		g_TimerScanMsg[victim]		= INVALID_HANDLE;
		CreateTimer( 0.1, ResetReviveCount, victim );
	}
}

public EVENT_ReviveSuccess( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( debugEvent ) PrintToServer( "------ EVENT_ReviveSuccess ------" );
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0 ) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "subject" ));
	
	if ( IsValidSurvivor( victim ))
	{
		SetEntProp( victim, Prop_Data, "m_takedamage", 2, 1 );
		SetEntProp( victim, Prop_Data, "m_MoveType", 2 );
		
		g_HelpState[victim]			= STATE_GETUP;
		g_NotifyCheck[victim]		= 1;
		g_IncapCheck[victim]		= 0;
		g_ZombieClass[victim]		= NONE;
		if( g_IdiotHelper[victim] > 0 )
		{
			g_IdiotHelper[victim]	= 0;
			CreateTimer(0.1, Timer_ReviveFriendlyNotify, victim);
		}
		if ( GetConVarInt( selfstandup_crawl_third ) > 0 )
		{
			GotoFirstPerson( victim );
		}
	}
	PrintToChatAll( "Revive succsess" );
}

public EVENT_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( debugEvent ) PrintToServer( "------ EVENT_HealSuccess ------" );
	if (( GameMode == 2 && GetConVarInt( selfstandup_versus ) == 0) || ( GetConVarInt( selfstandup_enable ) == 0 )) return;
	new victim = GetClientOfUserId( GetEventInt( event, "subject" ));
	if ( IsValidSurvivor( victim ))
	{
		GetClientHP( victim );
		CreateTimer( 0.2, ResetReviveCount, victim );
		if ( GetConVarFloat( selfstandup_count_msg ) > 0.0 )
		{
			new revivecount = GetEntProp( victim, Prop_Send, "m_currentReviveCount" );
			if ( !IsFakeClient( victim ))
			{
				PrintToChat( victim, "\x04[\x05GET UP\x04]\x05:  \x04%d \x05of \x04%d", revivecount, GetConVarInt( selfstandup_blackwhite ));
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ( client > 0 && ( buttons & IN_RELOAD ) && GetConVarInt( selfstandup_team ) > 0 )
	{
		if ( !IsNo_Incap( client ) && IsNo_IncapLedge( client ) && g_ZombieClass[client] == NONE && g_IdiotHelper[client] == 0 && g_HelpTeamStatus[client] == 0 && g_TeamButtInter[client] )
		{
			new target = GetClientAimTarget( client, true );
			if ( IsValidSurvivor( target ) && g_IdiotHelper[target] == 0 && ( !IsNo_Incap( target ) || !IsNo_IncapLedge( client )))
			{
				new Float:targetPos[3];
				new Float:helperPos[3];
				GetEntPropVector( target, Prop_Send, "m_vecOrigin", targetPos );
				GetEntPropVector( client, Prop_Send, "m_vecOrigin", helperPos );
			
				if ( GetVectorDistance( targetPos, helperPos ) <= 60.0 )
				{
					g_TeamButtInter[client]		= false;
		
					GetClientHP( target );
					
					g_HelpTeamStatus[client]	= target;
					g_HelpTeamStatus[target]	= client;
					g_IdiotHelper[target]		= client;
					
					g_HelpState[target] 		= STATE_NONE;
					g_HelpState[client] 		= STATE_NONE;
					
					SetEntProp( client, Prop_Data, "m_MoveType", 0 );
					SetEntProp( target, Prop_Data, "m_MoveType", 0 );
					
					SetEntProp( client, Prop_Data, "m_takedamage", 0, 1 );
					SetEntProp( target, Prop_Data, "m_takedamage", 0, 1 );
					
					SetEntPropEnt( client, Prop_Send, "m_reviveOwner", -1 );
					g_TimerTeam[client] = CreateTimer( 0.1, Timer_HelpingTeamMate, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
				}
				if ( debugTeamTimer ) PrintToServer( "[SELFSTANDUP]: Revive team mate begun!!" );
			}
		}
	}
	return Plugin_Continue;
}

SelfStandUp( victim )
{	
	if ( IsValidZombie( g_Attacker[victim] ))
	{
		if ( GetConVarInt(selfstandup_kill) > 0 )
		{
			KillAttacker( victim );
		}
		else
		{
			KnockAttacker( victim );
		}
	}
	CreateTimer( 0.1, Timer_GetUp, victim );
}

KillAttacker( victim )
{
	new attacker = g_Attacker[victim];
	if ( IsValidZombie( attacker ))
	{
		ForcePlayerSuicide( attacker );
		if ( L4D2Version )
		{
			EmitSoundToAll( SOUND_KILL2, victim );
		}
		else
		{
			EmitSoundToAll( SOUND_KILL1, victim );
		}
	}
}

KnockAttacker( victim )
{
	new attacker = g_Attacker[victim];
	if ( IsValidZombie( attacker ))
	{
		if (g_ZombieClass[victim] == SMOKER)
		{
			SetEntityMoveType( attacker, MOVETYPE_NOCLIP );			// this trick trigger the event tongue_release
			CreateTimer( 0.1, Timer_RestoreCollution, attacker );
			CreatePointPush( victim, attacker, 800.0 );
		}
		if ( g_ZombieClass[victim] == JOCKEY )
		{
			CallOnJockeyRideEnd( attacker );						// this trick trigger the event jockey_ride_end
			CreatePointPush( victim, attacker, 800.0 );
		}
		if ( g_ZombieClass[victim] == HUNTER )
		{
			SetEntityMoveType( attacker, MOVETYPE_NOCLIP );
			CreateTimer( 0.1, Timer_RestoreCollution, attacker );
			
			Execute_EventPounceStopped( attacker, victim );			// this trick trigger the event pounce_stopped
			CreatePointPush( victim, attacker, 800.0 );
		}
		if ( g_ZombieClass[victim] == CHARGER )
		{
			CallOnPummelEnded( victim );							// this trick trigger the event Pummel_end
			CreatePointPush( victim, attacker, 800.0 );
		}
	}
}

public Action:Timer_GetUp( Handle:timer, any:victim )
{
	if ( IsValidSurvivor( victim ))
	{
		if (( !IsNo_IncapLedge( victim )) || ( !IsNo_Incap( victim )))
		{	
			StopBeat( victim );
			new n_MaxBandW = GetConVarInt( selfstandup_blackwhite );
			new n_RevCount = GetEntProp( victim, Prop_Send, "m_currentReviveCount" );
			if ( !IsNo_Incap( victim ) && IsNo_IncapLedge( victim ))
			{
				n_RevCount += 1;
			}
			HealthCheat( victim );
			SetEntProp( victim, Prop_Send, "m_isHangingFromLedge", 0 );
			SetEntProp( victim, Prop_Send, "m_isIncapacitated", 0 );
			SetEntProp( victim, Prop_Send, "m_reviveOwner", 0 );
			SetEntProp( victim, Prop_Data, "m_iHealth", g_ReviveHealth[victim][0] );
			if ( g_ReviveHealth[victim][1] > 0.0 )
			{
				SetEntPropFloat( victim, Prop_Send, "m_healthBuffer", float( g_ReviveHealth[victim][1] ));
			}
			if ( n_MaxBandW > 0 ) 
			{	
				SetEntProp( victim, Prop_Send, "m_currentReviveCount", n_RevCount );
				if ( n_RevCount == n_MaxBandW )
				{
					CreateTimer( 0.1, Timer_ThirdStrike, victim );
				}
			}
		}
		
		if ( GetConVarInt( selfstandup_crawl_third ) > 0 )
		{
			GotoFirstPerson( victim );
		}
		CreateTimer( 0.1, reviveNotify, victim );
		EmitSoundToClient( victim, SOUND_GETUP );
	}
	if (debugMSG) PrintToServer( "[SELFSTANDUP]: Timer get UP" );
}

public Action:reviveNotify( Handle:timer, any:victim )
{
	if( IsValidSurvivor( victim ))
	{
		decl String:slotName[64];
		new Float:n_Msg	= GetConVarFloat( selfstandup_count_msg );
		new n_Costly	= GetConVarInt( selfstandup_costly );
		new n_MaxBandW	= GetConVarInt( selfstandup_blackwhite );
		new n_RevCount	= GetEntProp( victim, Prop_Send, "m_currentReviveCount" );
		
		if ( n_Costly == 0 )
		{
			if ( n_Msg > 0.0 )
			{
				if (( !IsFakeClient( victim )) && ( n_RevCount < n_MaxBandW ))
				{
					PrintToChat( victim, "\x04[\x05GET UP\x04]\x05:  \x04%d \x05of \x04%d", n_RevCount, n_MaxBandW );
				}
			}
		}
		if ( n_Costly > 0 && IsValidSlot( victim ))
		{
			if ( g_PlayerWeaponSlot[victim] != -1 )
			{
				new n_DestroyThis = g_PlayerWeaponSlot[victim];
				if ( n_Msg > 0.0 )
				{
					GetEntityClassname( n_DestroyThis, slotName, sizeof( slotName ));
					if ( StrEqual( slotName, "weapon_upgradepack_explosive", false ))
						Format(slotName, sizeof( slotName ), "Explosive Ammo");
				
					else if ( StrEqual( slotName, "weapon_upgradepack_incendiary", false ))
						Format( slotName, sizeof( slotName ), "Incendiary Ammo" );
				
					else if ( StrEqual( slotName, "weapon_first_aid_kit", false ))
						Format( slotName, sizeof( slotName ), "First Aid Kit" );
				
					else if ( StrEqual( slotName, "weapon_defibrillator", false ))
						Format( slotName, sizeof( slotName ), "Defibrillator" );
				
					else if ( StrEqual( slotName, "weapon_pain_pills", false ))
						Format( slotName, sizeof( slotName ), "Pain Pills" );
				
					else Format( slotName, sizeof( slotName ), "Adrenaline" );
				
					if ( n_RevCount < n_MaxBandW )
					{
						if ( !IsFakeClient( victim ))
						{
							PrintToChat( victim, "\x04[\x05GET UP\x04]\x05:  \x04%d \x05of \x04%d\x05,  cost of  \x04%s", n_RevCount, n_MaxBandW, slotName );
						}
					}
				}

				if ( g_NotifyCheck[victim] == 1 )
				{
					DestroyThisItem( n_DestroyThis );
					g_NotifyCheck[victim]		= 0;
					g_PlayerWeaponSlot[victim]	= -1;
				}
			}
		}
	}
	if ( debugEvent ) PrintToServer("------ Event_CostlyGetUP ------");
}

public Action:Timer_ReviveFriendlyNotify( Handle:timer, any:victim )
{
	if ( IsValidSurvivor( victim ))
	{
		new n_MaxBandW = GetConVarInt( selfstandup_blackwhite );
		new n_RevCount = GetEntProp( victim, Prop_Send, "m_currentReviveCount" );
		if ( n_RevCount == n_MaxBandW )
		{
			CreateTimer( 0.1, Timer_ThirdStrike, victim );
		}
		else
		{
			if ( !IsFakeClient( victim ))
			{
				PrintToChat( victim, "\x04[\x05GET UP\x04]\x05:  \x04%d \x05of \x04%d", n_RevCount, n_MaxBandW );
			}
		}
	}
}

public Action:ScanIntMSG( Handle:timer, any:victim )
{
	if( IsValidSurvivor( victim ))
	{
		g_TimerScanMsg[victim] = INVALID_HANDLE;
	}
	return Plugin_Stop;
}

public Action:Timer_RestoreCollution( Handle:timer, any:attacker )
{
	if( IsValidZombie( attacker ))
	{
		SetEntityMoveType( attacker, MOVETYPE_WALK );
	}
}

public Action:Timer_ThirdStrike( Handle:timer, any:victim )
{
	if ( IsValidSurvivor( victim ))
	{
		EmitSoundToClient( victim, SOUND_HEART_BEAT );
		SetEntProp( victim, Prop_Send, "m_bIsOnThirdStrike", 1 );
		if ( GetConVarInt( selfstandup_color ) > 0 )
		{
			SetEntityRenderMode( victim, RENDER_TRANSCOLOR );
			SetEntityRenderColor( victim, 128, 255, 128, 255 );
		}
		if( GetConVarFloat( selfstandup_count_msg ) > 0.0 )
		{
			PrintToChatAll( "\x04[\x05GET UP\x04]\x05:  \x04%N \x05on last life!!", victim );
		}
	}
}

public Action:ResetReviveCount( Handle:timer, any:victim )
{
	if( IsValidSurvivor( victim ))
	{
		StopBeat( victim );
		SetEntProp( victim, Prop_Send, "m_currentReviveCount", 0 );
		SetEntPropFloat( victim, Prop_Send, "m_healthBuffer", 0.0 );
		SetEntProp( victim, Prop_Send, "m_bIsOnThirdStrike", 0 );
		
		if( GetConVarInt( selfstandup_color) > 0 )
		{
			SetEntityRenderMode( victim, RENDER_TRANSCOLOR);
			SetEntityRenderColor( victim, 255, 255, 255, 255 );
		}
	}
}

public Action:Timer_HelpingTeamMate( Handle:timer, any:client )
{
	new target = g_HelpTeamStatus[client];
		
	if ( IsValidSurvivor( client ) && IsValidSurvivor( target ) && ( GetClientButtons( client ) & IN_RELOAD ) &&
	g_ZombieClass[client] == NONE && g_ZombieClass[target] == NONE && g_IdiotHelper[client] == 0 && g_IdiotHelper[target] == client &&
	( !IsNo_Incap( client ) || IsNo_IncapLedge( client )) && ( !IsNo_Incap( target ) || !IsNo_IncapLedge( target )))
	{
		g_UpIncapOrLedge = GetConVarFloat( selfstandup_duration );
		if ( !IsNo_Incap( target ) && g_UpIncapOrLedge > 5.0 ) g_UpIncapOrLedge = 5.0;
		if ( !IsNo_IncapLedge( target ) && g_UpIncapOrLedge > 4.0 ) g_UpIncapOrLedge = 4.0;
		
		new Float:timeS = GetEngineTime();
		if ( g_HelpState[target] == STATE_NONE )
		{
			g_HelpStartTime[client] = timeS;
			
			SetEntPropEnt( target, Prop_Send, "m_reviveOwner", client );
			SetEntPropEnt( client, Prop_Send, "m_reviveTarget", target );
			Load_Unload_ProgressBar( client, g_UpIncapOrLedge );
			g_HelpState[target] = STATE_SELFGETUP;
			if ( debugTeamTimer ) PrintToServer("[SELFSTANDUP]: g_HelpState[target] == STATE_NONE");
		}
		if ( g_HelpState[target] == STATE_SELFGETUP )
		{
			if (( timeS - g_HelpStartTime[client] ) <= g_UpIncapOrLedge )
			{
				ShowBar( client, timeS - g_HelpStartTime[client], g_UpIncapOrLedge );
				if( debugTeamTimer ) PrintToServer("[SELFSTANDUP]: RunTeam: %f  MaxTeam: %f", timeS - g_HelpStartTime[client], g_UpIncapOrLedge);
				return Plugin_Continue;
			}
			
			Target_StandUp( target, client );
			ShowBar( client, -1.0, g_UpIncapOrLedge );
			Load_Unload_ProgressBar( client, 0.0 );
			if ( debugTeamTimer ) PrintToServer("[SELFSTANDUP]: g_HelpState[target] == STATE_SELFGETUP");
		}
	}
	
	if ( g_TimerTeam[client] != INVALID_HANDLE )
	{
		KillTimer( g_TimerTeam[client] );
		g_TimerTeam[client] = INVALID_HANDLE;
	}
		
	g_HelpTeamStatus[client]	= 0;
	g_HelpTeamStatus[target]	= 0;
	g_TeamButtInter[client]		= true;
	
	g_HelpState[target]			= STATE_NONE;
		
	if ( IsValidSurvivor( client ))
	{
		ShowBar( client, -1.0, g_UpIncapOrLedge );
		Load_Unload_ProgressBar( client, 0.0 );
		
		SetEntProp( client, Prop_Data, "m_MoveType", 2 );
		SetEntProp( client, Prop_Data, "m_takedamage", 2, 1 );
		if ( !IsNo_Incap( client ))
		{
			SetEntPropEnt( client, Prop_Send, "m_reviveTarget", -1 );
			if ( g_IdiotHelper[client] == 0 )
			{
				SetEntPropEnt( client, Prop_Send, "m_reviveOwner", -1 );
			}
		}
	}
	if ( IsValidSurvivor( target ))
	{
		SetEntProp( target, Prop_Data, "m_MoveType", 2 );
		SetEntProp( target, Prop_Data, "m_takedamage", 2, 1 );
		if ( !IsNo_Incap( target ) || !IsNo_IncapLedge( target ))
		{
			if ( g_IdiotHelper[target] == client )
			{
				SetEntPropEnt( target, Prop_Send, "m_reviveOwner", -1 );
				g_IdiotHelper[target] = 0;
			}
		}
	}
	if ( debugTeamTimer ) PrintToServer( "[SELFSTANDUP]: Invalid revive team mate!!" );
	
	return Plugin_Stop;
}

// code from panxiohai
ShowBar( victim, Float:pos, Float:max )	 
{
	if ( IsValidSurvivor( victim ))
	{
		if ( pos < 0.0 )
		{
			PrintCenterText( victim, "" );
			return;
		}
		
		new String:ChargeBar[100];
		new Float:GaugeNum = pos/max*100;
		Format( ChargeBar, sizeof( ChargeBar ), "" );
		
		if ( GaugeNum > 100.0 )	GaugeNum = 100.0;
		if ( GaugeNum < 0.0 ) GaugeNum = 0.0;
		for ( new m = 0; m < 100; m++ )
		{
			ChargeBar[m] = Gauge1[0];
		}
		new p = RoundFloat( GaugeNum );
		if ( p >= 0 && p < 100 ) ChargeBar[p] = Gauge3[0]; 
		PrintCenterText( victim, "                                << SELF GET UP IN PROGRESS >> %3.0f %\n<<< %s >>>", GaugeNum, ChargeBar );
	}
}
// code from panxiohai
CallOnPummelEnded( victim )
{
	if ( IsValidSurvivor( victim ))
	{
		static Handle:hOnPummelEnded = INVALID_HANDLE;
		new Handle:hConf = INVALID_HANDLE;
		if ( hOnPummelEnded == INVALID_HANDLE )
		{
			hConf = LoadGameConfigFile( "l4d2_selfstandup" );
			StartPrepSDKCall( SDKCall_Player );
			PrepSDKCall_SetFromConf( hConf, SDKConf_Signature, "CTerrorPlayer::OnPummelEnded" );
			PrepSDKCall_AddParameter( SDKType_Bool,SDKPass_Plain );
			PrepSDKCall_AddParameter( SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL );
			hOnPummelEnded = EndPrepSDKCall();
			CloseHandle( hConf );
			if ( hOnPummelEnded == INVALID_HANDLE )
			{
				SetFailState( "Can't get CTerrorPlayer::OnPummelEnded SDKCall!" );
				return;
			}            
		}
		SDKCall( hOnPummelEnded, victim, true, -1 );
	}
}

GetClientHP( victim )
{
	if ( IsValidSurvivor( victim ))
	{
		if ( IsNo_Incap( victim ))
		{
			g_ReviveHealth[victim][0]	= GetClientHealth( victim );
			g_ReviveHealth[victim][1]	= 0;
			if( debugMSG ) PrintToServer( "[SELFSTANDUP]: Health not incap" );
		}
		else
		{
			if( IsNo_IncapLedge( victim ))
			{
				g_ReviveHealth[victim][0]	= 1;
				g_ReviveHealth[victim][1]	= GetConVarInt( selfstandup_health_incap );
				if( debugMSG ) PrintToServer( "[SELFSTANDUP]: Health incap" );
			}
		}
	}
}

StopBeat( victim )
{
	if ( IsValidSurvivor( victim ))
	{
		StopSound( victim, SNDCHAN_AUTO, SOUND_HEART_BEAT );
	}
}

GetListOfMetrial()
{
	new String:List[128];
	GetConVarString( selfstandup_costly_item, List, sizeof(List));
	
	if ( StrContains( List, "pills", false ) != -1 )
		g_Pills = true;
	else
		g_Pills = false;
	
	if ( StrContains( List, "adrenaline", false ) != -1 )
		g_Adrenaline = true;
	else
		g_Adrenaline = false;
	
	if ( StrContains( List, "med_kit", false ) != -1 )
		g_Med_Kit = true;
	else
		g_Med_Kit = false;
	
	if ( StrContains( List, "defibrillator", false ) != -1 )
		g_Defibrillator = true;
	else
		g_Defibrillator = false;
	
	if ( StrContains( List, "incendiary", false ) != -1 )
		g_Incendiary = true;
	else
		g_Incendiary = false;
	
	if ( StrContains( List, "explosive", false ) != -1 )
		g_Explosive = true;
	else
		g_Explosive = false;
}

bool:IsValidSlot( victim )
{
	if ( IsValidSurvivor( victim ))
	{
		GetListOfMetrial();
	
		new String:PlayerSlot[128];
		new PlayerSlot_3 = GetPlayerWeaponSlot( victim, 3 );
		new PlayerSlot_4 = GetPlayerWeaponSlot( victim, 4 );
	
		if ( PlayerSlot_4 != -1 && IsValidEdict( PlayerSlot_4 ) && ( g_Pills || g_Adrenaline ))
		{
			GetEntityClassname( PlayerSlot_4, PlayerSlot, sizeof( PlayerSlot ));
		
			if ( StrEqual( PlayerSlot, "weapon_pain_pills", false ) && g_Pills )
			{
				g_PlayerWeaponSlot[victim] = PlayerSlot_4;
				return true;
			}
			if ( StrEqual( PlayerSlot, "weapon_adrenaline", false ) && g_Adrenaline )
			{
				g_PlayerWeaponSlot[victim] = PlayerSlot_4;
				return true;
			}
		}
		if ( PlayerSlot_3 != -1 && IsValidEdict( PlayerSlot_3 ) && ( g_Med_Kit || g_Defibrillator || g_Incendiary || g_Explosive ))
		{
			GetEntityClassname( PlayerSlot_3, PlayerSlot, sizeof( PlayerSlot ));
		
			if ( StrEqual( PlayerSlot, "weapon_first_aid_kit", false ) && g_Med_Kit )
			{
				g_PlayerWeaponSlot[victim] = PlayerSlot_3;
				return true;
			}
			if ( StrEqual( PlayerSlot, "weapon_defibrillator", false ) && g_Defibrillator )
			{
				g_PlayerWeaponSlot[victim] = PlayerSlot_3;
				return true;
			}
			if ( StrEqual( PlayerSlot, "weapon_upgradepack_incendiary", false ) && g_Incendiary )
			{
				g_PlayerWeaponSlot[victim] = PlayerSlot_3;
				return true;
			}
			if ( StrEqual( PlayerSlot, "weapon_upgradepack_explosive", false ) && g_Explosive )
			{
				g_PlayerWeaponSlot[victim] = PlayerSlot_3;
				return true;
			}
		}
	}
	g_PlayerWeaponSlot[victim] = -1;
	return false;
}

ScanEnemy( victim )
{
	g_EnemyScan[victim] = 0;
	if( IsValidSurvivor( victim ))
	{
		decl String:InfName[64];
		decl Float:targetPos[3], Float:playerPos[3];
		GetEntPropVector( victim, Prop_Send, "m_vecOrigin", playerPos );
		
		new EntCount = GetEntityCount();
		for ( new i = 1; i <= EntCount; i++ )
		{
			if ( IsValidEntity( i ))
			{
				if ( IsValidZombie( i ))
				{
					GetEntPropVector( i, Prop_Send, "m_vecOrigin", targetPos );
					if ( GetVectorDistance( targetPos, playerPos ) <= GetConVarFloat( selfstandup_clearance ))
					{
						g_EnemyScan[victim] = i;
						break;
					}
				}
				else
				{
					GetEntityClassname( i, InfName, sizeof( InfName ));
					if ( StrEqual( InfName, "infected", false ))
					{
						GetEntPropVector( i, Prop_Send, "m_vecOrigin", targetPos );
						if ( GetVectorDistance( targetPos, playerPos ) <= GetConVarFloat( selfstandup_clearance ))
						{
							g_EnemyScan[victim] = i;
							break;
						}
					}
				}
			}
		}
	}
	return g_EnemyScan[victim];
}

RunEngine( victim, Float:time, Float:duration )
{
	if ( IsValidSurvivor( victim ))
	{
		if (( time - g_HelpStartTime[victim] ) <= duration )
		{
			ShowBar( victim, time - g_HelpStartTime[victim], duration );
			if( debugMSGTimer ) PrintToServer("[SELFSTANDUP]: RunTime: %f  MaxTime: %f", time - g_HelpStartTime[victim], duration );
		}
		if (( time - g_HelpStartTime[victim] ) > duration )
		{
			SelfStandUp( victim );
			g_HelpState[victim] = STATE_GETUP;
			ShowBar( victim, -1.0, duration );
			Load_Unload_ProgressBar( victim, 0.0 );
			
			if( debugMSG ) PrintToServer("[SELFSTANDUP]: HelpState = STATE_SELFGETUP RunEngine");
		}
	}
}

StopEngine( victim )
{
	if ( IsValidSurvivor( victim ))
	{
		g_HelpState[victim] = STATE_NONE;
		Load_Unload_ProgressBar( victim, 0.0 );
		SetEntPropEnt( victim, Prop_Send, "m_reviveOwner", -1 );
		if( g_TimerScanMsg[victim] == INVALID_HANDLE && GetConVarFloat( selfstandup_count_msg ) > 0.0 )
		{
			decl String:ArrayString[32];
			if ( g_EnemyScan[victim] > 0 && g_EnemyScan[victim] <= MaxClients )
			{
				PrintToChat( victim, "\x04[\x05GET UP\x04]\x05:  \x05You're too close to \x04%N", g_EnemyScan[victim] );
			}
			else if ( g_EnemyScan[victim] > MaxClients )
			{
				GetEntityClassname( g_EnemyScan[victim], ArrayString, sizeof( ArrayString ));
				PrintToChat( victim, "\x04[\x05GET UP\x04]\x05:  \x05You're too close to \x04%s", ArrayString );
			}
			g_EnemyScan[victim] = 0;
			g_TimerScanMsg[victim] = CreateTimer( 10.0, ScanIntMSG, victim );
		}
		if( debugMSG ) PrintToServer("[SELFSTANDUP]: HelpState = STATE_SELFGETUP StopEngine");
	}
}

Target_StandUp( victim, helper )
{
	PrintToServer("TargetStandup");
	if ( IsValidSurvivor( victim ))
	{
		g_IdiotHelper[victim]	= 0;
		
		new n_MaxBandW = GetConVarInt( selfstandup_blackwhite );
		new n_RevCount = GetEntProp( victim, Prop_Send, "m_currentReviveCount" );
		if ( !IsNo_Incap( victim ) && IsNo_IncapLedge( victim ))
		{
			n_RevCount += 1;
		}
		HealthCheat( victim );
		SetEntProp( victim, Prop_Send, "m_isHangingFromLedge", 0 );
		SetEntProp( victim, Prop_Send, "m_isIncapacitated", 0 );
		SetEntProp( victim, Prop_Send, "m_reviveOwner", 0 );
		SetEntProp( victim, Prop_Data, "m_iHealth", g_ReviveHealth[victim][0] );
		if ( g_ReviveHealth[victim][1] > 0.0 )
		{
			SetEntPropFloat( victim, Prop_Send, "m_healthBuffer", float( g_ReviveHealth[victim][1] ));
		}

		if ( n_MaxBandW > 0 ) 
		{	
			SetEntProp( victim, Prop_Send, "m_currentReviveCount", n_RevCount );
			if ( n_RevCount < n_MaxBandW )
			{
				if ( !IsFakeClient( victim ))
				{
					PrintToChat( victim, "\x04[\x05GET UP\x04]\x05:  \x04%d \x05of \x04%d", n_RevCount, n_MaxBandW );
				}
			}
			if ( n_RevCount == n_MaxBandW )
			{
				CreateTimer( 0.1, Timer_ThirdStrike, victim );
			}
		}
		
		if ( GetConVarInt( selfstandup_crawl_third ) > 0 )
		{
			GotoFirstPerson( victim );
		}
		EmitSoundToClient( victim, SOUND_GETUP );
		if ( IsValidSurvivor( helper ))
		{
			EmitSoundToClient( helper, SOUND_GETUP );
		}
	}
}

// code from panxiohai
stock CallOnJockeyRideEnd( attacker )
{
	if ( IsValidZombie( attacker ))
	{
		new flag =  GetCommandFlags( "dismount" );
		SetCommandFlags( "dismount", flag & ~FCVAR_CHEAT );
		FakeClientCommand( attacker, "dismount" );
		SetCommandFlags( "dismount", flag );
	}
}

stock HealthCheat( client )
{
	if ( IsValidSurvivor( client ))
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

stock bool:IsNo_Incap( victim )
{
	if ( IsValidSurvivor( victim ))
	{
		// if survivor incaped return false, true otherwise.
		if ( GetEntProp( victim, Prop_Send, "m_isIncapacitated" ) == 1 ) return false;
	}
	return true;
}

stock bool:IsNo_IncapLedge( victim )
{
	if ( IsValidSurvivor( victim ))
	{
		// if survivor ledge grab return false, true otherwise.
		if ( GetEntProp( victim, Prop_Send, "m_isHangingFromLedge" ) == 1 ) return false;
	}
	return true;
}

stock bool:IsValidSurvivor( victim )
{
	if ( victim < 1 || victim > MaxClients ) return false;
	if ( !IsClientConnected( victim )) return false;
	if ( !IsClientInGame( victim )) return false;
	if ( !IsPlayerAlive( victim )) return false;
	if ( GetClientTeam( victim ) != 2 ) return false;
	return true;
}

stock bool:IsValidZombie( attacker )
{
	if ( attacker < 1 || attacker > MaxClients ) return false;
	if ( !IsClientConnected( attacker )) return false;
	if ( !IsClientInGame( attacker )) return false;
	if ( !IsPlayerAlive( attacker )) return false;
	if ( GetClientTeam( attacker ) != 3 ) return false;
	if ( GetEntProp( attacker, Prop_Send, "m_zombieClass" ) == TANK ) return false;
	return true;
}

stock bool:IsInfectedOwner( client )
{
	if ( IsValidSurvivor( client ))
	{
		if ( GetEntProp( client, Prop_Send, "m_tongueOwner" ) > 0 )	return true;
		if ( GetEntPropEnt( client, Prop_Send, "m_pounceAttacker" ) > 0 ) return true;
		if ( GetEntPropEnt( client, Prop_Send, "m_jockeyAttacker" ) > 0 ) return true;
		if ( GetEntPropEnt( client, Prop_Send, "m_pummelAttacker" ) > 0 ) return true;
	}
	return false;
}

stock Execute_EventPounceStopped( client, victim )
{
	if ( client > 0 && victim > 0 )
	{
		new Handle:event = CreateEvent("pounce_stopped");
		if ( event != INVALID_HANDLE )
		{
			SetEventInt( event, "userid", GetClientUserId( client ));		// Who stopped it
			SetEventInt( event, "victim", GetClientUserId( victim ));		// And who was being pounced
			FireEvent( event );
		}
	}
}

stock GotoThirdPerson( victim )
{
	if ( IsValidSurvivor( victim ))
	{
		SetEntPropFloat( victim, Prop_Send, "m_TimeForceExternalView", 99999.3 );
	}
}

stock GotoFirstPerson( victim )
{
	if ( IsValidSurvivor( victim ))
	{
		SetEntPropFloat( victim, Prop_Send, "m_TimeForceExternalView", 0.0 );
	}
}

stock CreatePointPush( client, target, Float:Force )
{
	if ( IsValidSurvivor( client ) && IsValidZombie( target ))
	{
		decl Float:ppDM[3];
		decl Float:qqDM[3];
		decl Float:qqAA[3];
		decl Float:qqDA[3];
		decl Float:qqVv[3];
		
		GetEntPropVector( target, Prop_Send, "m_vecOrigin", ppDM );
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", qqDM );
		
		MakeVectorFromPoints( qqDM, ppDM, qqAA );
		GetVectorAngles( qqAA, qqDA );
		qqDA[0] = -30.0;
		GetAngleVectors( qqDA, qqVv, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector( qqVv, qqVv );
		ScaleVector( qqVv, Force );
		TeleportEntity( target, NULL_VECTOR, NULL_VECTOR, qqVv );
	}
}

public Action:DeletIndex( Handle:timer, any:index )
{
    if ( IsValidEntity( index ))
	{
		AcceptEntityInput( index, "Kill" );
	}
}

stock DestroyThisItem( entity )
{
	if ( IsValidEntity( entity ))
	{
		decl Float:desPos[3];
		GetEntPropVector( entity, Prop_Send, "m_vecOrigin", desPos );
		SetEntPropEnt( entity, Prop_Data, "m_hOwnerEntity", -1)	;
		desPos[2] += 5000.0;
		TeleportEntity( entity, desPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput( entity, "kill" );
	}
}

stock Load_Unload_ProgressBar( victim, Float:time )
{
	if ( IsValidSurvivor( victim ))
	{
		SetEntPropFloat( victim, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntPropFloat( victim, Prop_Send, "m_flProgressBarDuration", time );
	}
}


