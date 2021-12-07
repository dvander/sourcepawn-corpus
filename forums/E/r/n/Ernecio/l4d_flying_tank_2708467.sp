/** ====================================================================================================================
			
											Changelog by Ernecio
			
	[05/22/2020] Version 2.6
	- Code optimizations and updated Game Modes function (Taken from 'Silvers' plugins).
	- Added new function to detect maps and that the plugin only works on certain maps.
	  Code taken from the 'Marttt' plugins, credits to him for his code and method.
	- Added a new method to control the Tank when is flying.
	
	[01/16/2020] Version 2.5
	- Added support to control the Tank when it starts to fly if this plugin is executed in versus mode.
	- Fixed when Tank dies and can continue to fly for a short time.
	- Added user recovers to timers.
	
	[12/03/2019] Version 2.4
	- Handle functions changed to ConVar.
	- New settings have been added for the status when the Tank is flying.
	- Added new config that allows the use of Tank ability only in finals.
	- Removed the old Glow method and replaced by dynamic Glow.
	- Change the effects when Tank is flayion:
	  Light was added to the Jetpack flames when Tank is flying.
	  Sound added to Tank's jetpack.
	
	[11/24/2019] Version 2.3
	- Added lights on the tank head that simulate a crown, hinting that he is the king :D
	
	[11/19/2019] Version 2.2
	- Improvement in the execution of events that use string values and improvement in obtaining probabilities.
	
	[11/14/2019] Version 2.1
	- Active/Inactive state method in game modes changed to extend support.
	  Code taken from 'SilverShot' Plugins, credits to him for his code and method.
	  
	- Added new Cvar to enable or disable the plugin.
	- Added Hooks in the settings to make changes within the game without having to restart the plugin.
	- Added a new entity removal method when Tank has died or has stopped flying.
	- Code optimization.
	- Attachment models were rewritten for code optimization.
	  Previous method removed and added a new method in which the functions that was separated
	  of attach models to Tank.
	
	[11/14/2019] Version 2.0
	- Zombieclass function changed to boolean function (For Tank).
	- Corrections in syntax and cleared functions that can cause errors.
	- Some sections of the code and variables are renamed for your better understanding.
	  (Personal taste, doesn't affect performance)
	
	[10/02/2019] Version 1.9
	- Model precache method changed.
	- Fixed blocking issues for Left 4 Dead 1 in 5-chapter campaigns and also during the course of the map when 
	  the Tank is about to fly.
	- Problems fixed in Left 4 Dead 2 when the tank for no reason remains static in the air when he is flying.
	
	[10/02/2019] Version 1.8
	- The method of switching between games was modified, a game detector was added.
	- Added "true" values ​​in the variables of the autoexec file to avoid that by mistake a value that is 
	  excessive is added and causes problems in the operation of the plugin.
	- Color rendering function removed because it causes conflicts with plugins that use this function.
	
	[10/02/2019] Version 1.7
	- Updated to the new Sourcemod 1.10 syntax( Tests performed only on SourceMod 1.10 ).
	
	[10/01/2019] Version 1.6
	- All the error warnings contained in the plugin were removed in original Plugin.
	- Unnecessary functions removed (because these functions are never used).
	
	[10/17/2011] Version 1.5
	- All changes made prior to version 1.5 were made by its original author Pan Xiao Hai.
	
	Original plugin: https://forums.alliedmods.net/showthread.php?p=1544648
	
   ===================================================================================================================== */

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "2.6"

#define CHAT_TAG "\x04➛\x01Flying Tank\x04➛\x01"
#define HINT_TAG "➛Flying Tank➛"

#define FilterSelf 					0
#define FilterSelfAndPlayer 		1
#define FilterSelfAndSurvivor 		2
#define FilterSelfAndInfected 		3
#define FilterSelfAndPlayerAndCI 	4

#define STATE_NONE 	0
#define STATE_START 1
#define STATE_FLY 	2
#define NULL 		0

static ConVar hCvar_MPGameMode;
static ConVar hCvar_FlyingInfected_Enabled;
static ConVar hCvar_FlyingInfected_FinaleOnly;

static ConVar hCvar_FlyingInfected_GameModesOn;
static ConVar hCvar_FlyingInfected_GameModesOff;
static ConVar hCvar_FlyingInfected_GameModesToggle;
static ConVar hCvar_FlyingInfected_MapsOn;
static ConVar hCvar_FlyingInfected_MapsOff;

static ConVar hCvar_FlyingInfected_Chance_Throw;
static ConVar hCvar_FlyingInfected_Chance_Tankclaw;
static ConVar hCvar_FlyingInfected_Chance_Tankjump;

static ConVar hCvar_FlyingInfected_Speed; 
static ConVar hCvar_FlyingInfected_Maxtime;

static ConVar hCvar_FlyingInfected_Crown;
static ConVar hCvar_FlyingInfected_JetPack_Light;
static ConVar hCvar_FlyingInfected_Mssage;
static ConVar hCvar_FlyingInfected_Ads;

/**********************************/
static int iCvar_GameModesToggle;
static int iCvar_CurrentMode;

static char sCvar_MPGameMode[16];
static char sCvar_GameModesOn[256];
static char sCvar_GameModesOff[256];

static char sCurrentMap[256];
static char sCvar_MapsOn[256];
static char sCvar_MapsOff[256];
/**********************************/

static float fCvar_FlyingInfected_Chance_Throw;
static float fCvar_FlyingInfected_Chance_Tankclaw;
static float fCvar_FlyingInfected_Chance_Tankjump;
static float fCvar_FlyingInfected_Speed;
static float fCvar_FlyingInfected_Maxtime;

static bool bCvar_FlyingInfected_Enabled;
static bool bCvar_FlyingInfected_Crown;
static bool bCvar_FlyingInfected_JetPack_Light;
static bool bCvar_FlyingInfected_Mssage;
static bool bCvar_FlyingInfected_Ads;
static bool bCvar_FlyingInfected_FinaleOnly;

static bool bMapStarted;
static bool bFinalEvent;
static bool bLeft4DeadTwo;

static int vOffsetVelocity;

int iArrayStatus[MAXPLAYERS+1];
int iArraySounds[MAXPLAYERS+1];
int iArrayTarget[MAXPLAYERS+1];

float ClientVelocity[MAXPLAYERS+1][3];
float LastTime[MAXPLAYERS+1]; 
float FireTime[MAXPLAYERS+1]; 
float StartTime[MAXPLAYERS+1];
float ScanTime[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name 		= "[L4D1 AND L4D2] Flying Tank",
	author 		= "Panxiaohai And Ernecio (Satanael)",
	description = "Provides the ability to fly to Tanks and special effects.",
	version 	= PLUGIN_VERSION,
	url 		= "https://steamcommunity.com/profiles/76561198404709570/"
}

/**
 * @note Called on pre plugin start.
 *
 * @param hMyself        Handle to the plugin.
 * @param bLate          Whether or not the plugin was loaded "late" (after map load).
 * @param sError         Error message buffer in case load failed.
 * @param Error_Max      Maximum number of characters for error message buffer.
 * @return               APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise.
 */
public APLRes AskPluginLoad2( Handle hMyself, bool bLate, char[] sError, int Error_Max )
{
	EngineVersion Engine = GetEngineVersion();
	if( Engine != Engine_Left4Dead && Engine != Engine_Left4Dead2 )
	{
		strcopy( sError, Error_Max, "This Plugin \"Flaying Tank\" only runs in the \"Left 4 Dead 1/2\" Games!." );
		return APLRes_SilentFailure;
	}
	
	bLeft4DeadTwo = ( Engine == Engine_Left4Dead2 );
	return APLRes_Success;
}

/**
 * Called on plugin start.
 *
 * @noreturn
 */
public void OnPluginStart()
{
	hCvar_MPGameMode 						= FindConVar("mp_gamemode");
	hCvar_FlyingInfected_Enabled 			= CreateConVar("l4d_flyinginfected_enable", 			"1", 		"Enables/Disables the plugin. 0 = Plugin OFF, 1 = Plugin ON.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_FlyingInfected_FinaleOnly 		= CreateConVar("l4d_flyinginfected_finale_only", 		"0", 		"Enables/Disables the ability to fly for Tanks only in final events.\n0 = Finals OFF.\n1 = Finals ON", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	hCvar_FlyingInfected_GameModesOn 		= CreateConVar("l4d_flyinginfected_gamemodes_on",  		"",   		"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", FCVAR_NOTIFY );
	hCvar_FlyingInfected_GameModesOff 		= CreateConVar("l4d_flyinginfected_gamemodes_off", 		"",   		"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", FCVAR_NOTIFY );
	hCvar_FlyingInfected_GameModesToggle 	= CreateConVar("l4d_flyinginfected_gamemodes_toggle", 	"0", 		"Turn on the plugin in these game modes.\n0 = All, 1 = Coop, 2 = Survival, 4 = Versus, 8 = Scavenge.\nAdd numbers together.", FCVAR_NOTIFY, true, 0.0, true, 15.0 );
	hCvar_FlyingInfected_MapsOn 			= CreateConVar("l4d_flyinginfected_maps_on", 			"", 		"Allow the plugin being loaded on these maps, separate by commas (no spaces). Empty = all.\nExample: \"l4d_hospital01_apartment,c1m1_hotel\"", FCVAR_NOTIFY);
	hCvar_FlyingInfected_MapsOff 			= CreateConVar("l4d_flyinginfected_maps_off", 			"", 		"Prevent the plugin being loaded on these maps, separate by commas (no spaces). Empty = none.\nExample: \"l4d_hospital01_apartment,c1m1_hotel\"", FCVAR_NOTIFY);
	
	hCvar_FlyingInfected_Chance_Throw 		= CreateConVar("l4d_flyinginfected_chance_throw", 		"50.0", 	"Probability of flying when the Tank throws a rock.", FCVAR_NOTIFY, true, 0.0, true, 100.0);
 	hCvar_FlyingInfected_Chance_Tankclaw 	= CreateConVar("l4d_flyinginfected_chance_tankclaw", 	"45.0", 	"Probability of flying when the Tank hits.", FCVAR_NOTIFY, true, 0.0, true, 100.0);
 	hCvar_FlyingInfected_Chance_Tankjump 	= CreateConVar("l4d_flyinginfected_chance_tankjump", 	"75.0", 	"Probability of flying when the Tank jumps.", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	
	hCvar_FlyingInfected_Speed 				= CreateConVar("l4d_flyinginfected_speed", 				"300.0", 	"Set the speed of the Tank when him is flying.", FCVAR_NOTIFY, true, 100.0, true, 450.0);
 	hCvar_FlyingInfected_Maxtime 			= CreateConVar("l4d_flyinginfected_maxtime", 			"100.0", 	"Set the max flight time.", FCVAR_NOTIFY, true, 10.0, true, 1000.0);
	
	hCvar_FlyingInfected_Crown 				= CreateConVar("l4d_flyinginfected_crown", 				"1", 		"Enables/Disables the crown when Tank is fliying.\n0 = Crown of light OFF.\n1 = Crown of light ON.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_FlyingInfected_JetPack_Light 		= CreateConVar("l4d_flyinginfected_light_system", 		"1", 		"Enables/Disables the light effect of the jetpack when the Tank is flying.\n0 = JetPack Light OFF.\n1 = JetPack Light ON.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_FlyingInfected_Mssage 			= CreateConVar("l4d_flyinginfected_message", 			"1", 		"Enables/Disables the warning message to the player when is chased by the Tank when him is flying.\n0 = Messaje OFF\n1 = Messaje ON.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_FlyingInfected_Ads 				= CreateConVar("l4d_flyinginfected_ads", 				"1", 		"Enables/Disables the ads about Tank status.\n0 = Ads OFF\n1 = Ads ON.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	CreateConVar(											"l4d_flyinginfected_version",		PLUGIN_VERSION, "Flying Tank Plugin Version.", FCVAR_NOTIFY|FCVAR_DONTRECORD );
	
	hCvar_MPGameMode.AddChangeHook( Event_ConVarChanged );
	hCvar_FlyingInfected_Enabled.AddChangeHook( Event_ConVarChanged );
	hCvar_FlyingInfected_FinaleOnly.AddChangeHook( Event_ConVarChanged );
	hCvar_FlyingInfected_GameModesOn.AddChangeHook( Event_ConVarChanged );
	hCvar_FlyingInfected_GameModesOff.AddChangeHook( Event_ConVarChanged );
	hCvar_FlyingInfected_GameModesToggle.AddChangeHook( Event_ConVarChanged );
	hCvar_FlyingInfected_MapsOn.AddChangeHook( Event_ConVarChanged );
	hCvar_FlyingInfected_MapsOff.AddChangeHook( Event_ConVarChanged );
	hCvar_FlyingInfected_Chance_Throw.AddChangeHook( Event_ConVarChanged );
	hCvar_FlyingInfected_Chance_Tankclaw.AddChangeHook( Event_ConVarChanged );
	hCvar_FlyingInfected_Chance_Tankjump.AddChangeHook( Event_ConVarChanged );
	hCvar_FlyingInfected_Speed.AddChangeHook( Event_ConVarChanged );
	hCvar_FlyingInfected_Maxtime.AddChangeHook( Event_ConVarChanged );
	hCvar_FlyingInfected_Crown.AddChangeHook( Event_ConVarChanged );
	hCvar_FlyingInfected_JetPack_Light.AddChangeHook( Event_ConVarChanged );
	hCvar_FlyingInfected_Mssage.AddChangeHook( Event_ConVarChanged );
	hCvar_FlyingInfected_Ads.AddChangeHook( Event_ConVarChanged );
	
	HookEvent("finale_start", 	Event_FinaleStarted, EventHookMode_Pre);
	HookEvent("round_start", 	Event_RoundStarted, EventHookMode_Post);
	HookEvent("round_end", 		Event_RoundStarted, EventHookMode_Pre );
	HookEvent("finale_win", 	Event_RoundStarted, EventHookMode_Pre );
	HookEvent("mission_lost", 	Event_RoundStarted, EventHookMode_Pre );
	HookEvent("map_transition", Event_RoundStarted, EventHookMode_Pre );	
	HookEvent("weapon_fire", 	Event_WeaponFire, 	EventHookMode_Post);
	HookEvent("ability_use", 	Event_AbilityUse, 	EventHookMode_Post);
	HookEvent("player_jump", 	Event_PlayerJump, 	EventHookMode_Post);
	HookEvent("player_hurt", 	Event_PlayerHurt);
	HookEvent("player_death", 	Event_PlayerDeath, 	EventHookMode_Pre );
	HookEvent("tank_spawn", 	Event_TankSpawn, 	EventHookMode_Post);
//	HookEvent("player_spawn", 	Event_PlayerSpawn, 	EventHookMode_Post);
//	HookEvent("player_team",	Event_PlayerTeam);
	HookEvent("player_bot_replace",Event_BotReplace,EventHookMode_Post);
	HookEvent("bot_player_replace", Event_PlayerReplace );	
	
	vOffsetVelocity = FindSendPropInfo( "CBasePlayer", "m_vecVelocity[0]" );
	
	AutoExecConfig( true, "l4d_flying_tank" );
}

/**
 * Called on configs executed.
 *
 * @noreturn
 */
public void OnConfigsExecuted()
{
	GetCvars();
}

void Event_ConVarChanged( Handle hCvar, const char[] sOldVal, const char[] sNewVal )
{
	GetCvars();
}

void GetCvars()
{
	GetCurrentMap( sCurrentMap, sizeof( sCurrentMap ) );
	
	hCvar_MPGameMode.GetString( sCvar_MPGameMode, sizeof( sCvar_MPGameMode ) );
	TrimString( sCvar_MPGameMode );
	
	bCvar_FlyingInfected_Enabled = hCvar_FlyingInfected_Enabled.BoolValue;
	bCvar_FlyingInfected_FinaleOnly = hCvar_FlyingInfected_FinaleOnly.BoolValue;
	iCvar_GameModesToggle = hCvar_FlyingInfected_GameModesToggle.IntValue;
	fCvar_FlyingInfected_Chance_Throw = hCvar_FlyingInfected_Chance_Throw.FloatValue;
	fCvar_FlyingInfected_Chance_Tankclaw = hCvar_FlyingInfected_Chance_Tankclaw.FloatValue;
	fCvar_FlyingInfected_Chance_Tankjump = hCvar_FlyingInfected_Chance_Tankjump.FloatValue;
	fCvar_FlyingInfected_Speed = hCvar_FlyingInfected_Speed.FloatValue;
	fCvar_FlyingInfected_Maxtime = hCvar_FlyingInfected_Maxtime.FloatValue;
	bCvar_FlyingInfected_Crown = hCvar_FlyingInfected_Crown.BoolValue;
	bCvar_FlyingInfected_JetPack_Light = hCvar_FlyingInfected_JetPack_Light.BoolValue;
	bCvar_FlyingInfected_Mssage = hCvar_FlyingInfected_Mssage.BoolValue;
	bCvar_FlyingInfected_Ads = hCvar_FlyingInfected_Ads.BoolValue;
	
	hCvar_FlyingInfected_GameModesOn.GetString( sCvar_GameModesOn, sizeof( sCvar_GameModesOn ) );
//	TrimString( sCvar_GameModesOn ); 													// Removes whitespace characters from the beginning and end of a string.
	ReplaceString( sCvar_GameModesOn, sizeof( sCvar_GameModesOn ), " ", "", false ); 	// Remove spaces in any section of the string.
	hCvar_FlyingInfected_GameModesOff.GetString( sCvar_GameModesOff, sizeof( sCvar_GameModesOff ) );
//	TrimString( sCvar_GameModesOff );
	ReplaceString( sCvar_GameModesOff, sizeof( sCvar_GameModesOff ), " ", "", false );
	
	hCvar_FlyingInfected_MapsOn.GetString( sCvar_MapsOn, sizeof( sCvar_MapsOn ) );
	ReplaceString( sCvar_MapsOn, sizeof( sCvar_MapsOn ), " ", "", false );
	
	hCvar_FlyingInfected_MapsOff.GetString( sCvar_MapsOff, sizeof( sCvar_MapsOff ) );
	ReplaceString( sCvar_MapsOff, sizeof( sCvar_MapsOff ), " ", "", false );
}

/**
 * The map is starting.
 *
 * @noreturn
 **/
public void OnMapStart()
{
	PrecacheModel("models/props_equipment/oxygentank01.mdl", true);
	PrecacheSound("ambient/Spacial_Loops/CarFire_Loop.wav", true );
	
	bMapStarted = true;
}

/**
 * The map is ending.
 *
 * @noreturn
 **/
public void OnMapEnd()
{
	bMapStarted = false;
}

/**
 * Event callback (round_start, round_end, finale_win, mission_lost, map_transition)
 * @note Multiple event calls, all in order to reset client status.
 * 
 * @param hEvent 			The event handle.
 * @param sName	    		The name of the event.
 * @param bDontBroadcast 	If true, event is broadcasted to all clients, false if not.
 **/
public void Event_RoundStarted( Event hEvent, const char[] sName, bool bDontBroadcast )
{	
	for( int i = 1; i <= MaxClients; i ++ )
	{
		if( !IsValidClient( i ) )
			continue;
			
		StopFly( i );
		iArrayStatus[i] = STATE_NONE;
		FireTime[i] = 0.0;
		SDKUnhook(i, SDKHook_PreThink, PreThink); 
		SDKUnhook(i, SDKHook_StartTouch, FlyTouch);
	}
	
	bFinalEvent = false;
}

/**
 * Event callback (finale_start)
 * @note Event call when end activated.
 * 
 * @param hEvent 			The event handle.
 * @param sName	    		The name of the event.
 * @param bDontBroadcast 	If true, event is broadcasted to all clients, false if not.
 **/
public void Event_FinaleStarted( Event hEvent, const char[] sName, bool bDontBroadcast )
{	
	bFinalEvent = true;
}

/**
 * Event callback (weapon_fire)
 * @note Event call when a player/bot has opened firee.
 * 
 * @param hEvent 			The event handle.
 * @param sName	    		The name of the event.
 * @param bDontBroadcast 	If true, event is broadcasted to all clients, false if not.
 **/
public void Event_WeaponFire( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	if( !IsAllowedPlugin() ) return;
	
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );
	if( IsTank( client ) && IsPlayerAlive( client ) ) 
	{
		if( FireTime[client] + 1.0 < GetEngineTime())
			FireTime[client] = GetEngineTime();
		else
			return; // Prevents over-creation of timers.
		
		if( iArrayStatus[client] == STATE_NONE )
		{ 
			if( GetRandomFloat( 0.0, 100.0 ) <= fCvar_FlyingInfected_Chance_Tankclaw )
			{
				iArrayStatus[client] = STATE_START;
				CreateTimer( 3.0, StartTimer, GetClientUserId( client ), TIMER_FLAG_NO_MAPCHANGE );
			}
		}
	}
}

/**
 * Event callback (player_hurt)
 * @note Event call when a player/bot has received or dealt damage.
 * 
 * @param hEvent 			The event handle.
 * @param sName	    		The name of the event.
 * @param bDontBroadcast 	If true, event is broadcasted to all clients, false if not.
 **/
public void Event_PlayerHurt( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	if( !IsAllowedPlugin() ) return;
	
	int attacker = GetClientOfUserId( hEvent.GetInt( "attacker" ) );
	if( attacker > 0 && iArrayStatus[attacker] == STATE_FLY )
	{
		char sBuffer[32];	
		hEvent.GetString( "weapon", sBuffer, sizeof( sBuffer ) );
		
	 	if( StrEqual( sBuffer, "tank_claw" ) )
			StopFly( attacker );
	}
}

/**
 * Event callback (player_jump)
 * @note Event call when a player/bot has jumped.
 * 
 * @param hEvent 			The event handle.
 * @param sName    			The name of the event.
 * @param bDontBroadcast 	If true, event is broadcasted to all clients, false if not.
 **/
public void Event_PlayerJump( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	if( !IsAllowedPlugin() ) return;
	
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );
	if( IsTank( client ) && iArrayStatus[client] == STATE_NONE )
	{
		if( GetRandomFloat( 0.0, 100.0 ) <= fCvar_FlyingInfected_Chance_Tankjump )
		{
			iArrayStatus[client] = STATE_START;
			StartTimer( INVALID_HANDLE, GetClientUserId( client ) );
		}
	}
}

/**
 * Event callback (player_death)
 * @note Event call when a player/bot is dead.
 * 
 * @param hEvent 			The event handle.
 * @param sName	    		The name of the event.
 * @param bDontBroadcast 	If true, event is broadcasted to all clients, false if not.
 **/
public void Event_PlayerDeath( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	if( !IsAllowedPlugin() ) return;
	
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );
	if( IsTank( client ) && iArrayStatus[client] == STATE_FLY ) 
		StopFly( client );
	
	if( IsTank( client ) && bCvar_FlyingInfected_Ads )
		PrintToChatAll( "%s \x03%N \x01Is \x04Dead!", CHAT_TAG, client );
}

/**
 * Event callback (ability_use)
 * @note Event call when a tank has thrown a rock.
 *
 * @param hEvent 			The event handle.
 * @param sName	    		The name of the event.
 * @param bDontBroadcast 	If true, event is broadcasted to all clients, false if not.
 **/
public void Event_AbilityUse( Event hEvent, const char[] sName, bool bDontBroadcast )
{	
	if( !IsAllowedPlugin() ) return;
	
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );
	if( iArrayStatus[client] == STATE_NONE ) 
	{
		char sBuffer[32];	
		hEvent.GetString( "ability", sBuffer, sizeof( sBuffer ) );
		if( StrEqual( sBuffer, "ability_throw", true ) )
		{
			if( GetRandomFloat( 0.0, 100.0 ) <= fCvar_FlyingInfected_Chance_Throw )
			{
				iArrayStatus[client] = STATE_START;
				CreateTimer( 3.0, StartTimer, GetClientUserId( client ), TIMER_FLAG_NO_MAPCHANGE );
			}
		}
	}
}

/**
 * Event callback (tank_spawn)
 * @note Event call when a tank is about to spawn.
 * 
 * @param hEvent 			The event handle.
 * @param sName	    		The name of the event.
 * @param bDontBroadcast 	If true, event is broadcasted to all clients, false if not.
 **/
public void Event_TankSpawn( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	if( !IsAllowedPlugin() ) return;
	
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );
	if( client > 0 && IsClientInGame( client ) )
		CreateTimer( 0.2, Timer_DelayAds, GetClientUserId( client ), TIMER_FLAG_NO_MAPCHANGE );
}

/**
 * Event callback (player_bot_replace)
 * @note Event call when a bot takes the place of a player.
 * 
 * @param hEvent 			The event handle.
 * @param sName	    		The name of the event.
 * @param bDontBroadcast 	If true, event is broadcasted to all clients, false if not.
 **/
public void Event_BotReplace( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	if( !bCvar_FlyingInfected_Enabled ) return;
	
 	int client = GetClientOfUserId( hEvent.GetInt( "player" ) );
	int bot = GetClientOfUserId( hEvent.GetInt( "bot" ) );   
	
	if( client ) StopFly( client );
	if( bot ) StopFly( bot );
}

/**
 * Event callback (bot_player_replace)
 * @note Event call when a player takes the place of a robot.
 * 
 * @param hEvent 			The event handle.
 * @param sName	    		The name of the event.
 * @param bDontBroadcast 	If true, event is broadcasted to all clients, false if not.
 **/
public void Event_PlayerReplace( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	if( !bCvar_FlyingInfected_Enabled ) return;
	
 	int client = GetClientOfUserId( hEvent.GetInt( "player" ) );
	int bot = GetClientOfUserId( hEvent.GetInt( "bot" ) );   
	
	if( bot ) StopFly( bot );
	if( client ) StopFly( client );
}

/**
 * @note Handler for the timer to attach models and entities to player or ads.
 * 
 * @param hTimer 		Handle for the timer
 * @param client		Client Index
 */
public Action Timer_DelayAds( Handle hTimer, any UserID )
{
	int client = GetClientOfUserId( UserID );
	
	if( IsTank( client ) )
		if( IsPlayerAlive( client ) )
			if( bCvar_FlyingInfected_Ads )
				PrintToChatAll( "%s \x03%N \x01 Has Spawned!", CHAT_TAG, client );
}

/**
 * @note Handler for timer start for Tank start flying and trace the trajectory.
 * 
 * @param hTimer 		Handle for the timer
 * @param UserID		Client Index
 */
public Action StartTimer( Handle hTimer, any UserID )
{
	int client = GetClientOfUserId( UserID );
	if( IsTank( client ) && iArrayStatus[client] != STATE_FLY && IsPlayerAlive( client ) && !IsPlayerIncapped( client ) ) 
		StartFly( client );
	
	if( iArrayStatus[client] != STATE_FLY ) 
		iArrayStatus[client] = STATE_NONE;
}

void StartFly( int client )
{   
	if( iArrayStatus[client] == STATE_FLY )
		StopFly( client );
	
	iArrayStatus[client] = STATE_NONE;

	float vOrigin[3], vPos[3], vAngles[3], vEyeAngles[3];
	vAngles[0] = - 89.0;
	GetClientEyePosition( client, vOrigin );
	Handle hTrace = TR_TraceRayFilterEx( vOrigin, vAngles, MASK_ALL, RayType_Infinite, DontHitSelf, client );
	
	bool bNarrow = false;
	if( TR_DidHit( hTrace ) )
	{
		TR_GetEndPosition( vPos, hTrace ); 
		if( GetVectorDistance( vPos, vOrigin ) <= 100.0 )
		{
			bNarrow = true;
			
			if( !IsFakeClient( client ) )
				PrintCenterText( client, "Too narrow to start flight!" );
			
			if( bCvar_FlyingInfected_Ads )
				PrintCenterTextAll( "%N has been frustrated while trying to fly!", client );
		}
	}
	
	delete hTrace;
	if( bNarrow ) return;
	
	iArrayStatus[client] = STATE_FLY;
	
//	GetEntPropVector( client, Prop_Send, "m_vecOrigin", vOrigin );
	GetEntPropVector( client, Prop_Data, "m_vecAbsOrigin", vOrigin );
	GetClientEyeAngles( client, vEyeAngles ); 								// Crosshair angles.
	vOrigin[2] += 5.0; 														// Initial elevation from the ground.
	vEyeAngles[2] = 30.0; 													// Initial elevation angle.
	GetAngleVectors( vEyeAngles, vEyeAngles, NULL_VECTOR, NULL_VECTOR );
	NormalizeVector( vEyeAngles, vEyeAngles );
	ScaleVector( vEyeAngles, 55.0 );
	TeleportEntity( client, vOrigin, NULL_VECTOR, vEyeAngles );
	vCopyVector( vEyeAngles, ClientVelocity[client] );
	
	LastTime[client] = GetEngineTime() - 0.01;
	StartTime[client] = GetEngineTime();
	ScanTime[client] = GetEngineTime() - 0.0;
	
	iArrayTarget[client] = NULL;
	
	SDKUnhook( client, SDKHook_PreThink, PreThink );
	SDKHook( client, SDKHook_PreThink, PreThink );
	SDKUnhook( client, SDKHook_StartTouch, FlyTouch );
	SDKHook( client, SDKHook_StartTouch, FlyTouch );
	
	SetParentModel( client );
	SetParentFlame( client );
	SetParentLight( client );
	SetParentCrown( client );
	StartGlowing( client );
	
	CreateTimer( 0.5, Timer_Others, GetClientUserId( client ), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
} 

public Action FlyTouch( int client, int other )
{
	StopFly( client ); 
}

public Action PreThink( int client )
{
	if( IsValidClient( client ) && IsPlayerAlive( client ) && !IsPlayerIncapped( client ) )
	{ 
		float fTime = GetEngineTime();
		float fIntervual = fTime - LastTime[client]; 
		int CurrentButton = GetClientButtons( client );
		
		LastTime[client] = fTime;
		TraceFly( client, CurrentButton, fTime, fIntervual );
	}
	else 
	{
		SDKUnhook( client, SDKHook_PreThink, PreThink );
	}
}

public Action Timer_Others( Handle hTimer, any UserID )
{
	int client = GetClientOfUserId( UserID );
	if( !IsTank( client ) || !IsPlayerAlive( client ) || IsPlayerIncapped( client ) || iArrayStatus[client] != STATE_FLY )
		return Plugin_Stop;
	
	if( bCvar_FlyingInfected_Ads )
		PrintCenterTextAll( "%s %N Is Flying!", HINT_TAG, client );
	
	static float vPos[3];
	GetClientAbsOrigin( client, vPos );
	
	PlaySound( client, vPos );
	
	return Plugin_Continue;
}

void TraceFly( int client, int CurrentButton, float fTime, float fDuration )
{
	if( fTime - StartTime[client] > fCvar_FlyingInfected_Maxtime )
	{
		StopFly( client );
		return;
	}
	
	if( !IsFakeClient( client ) && IsClientInGame( client ) && IsClientConnected( client ) )
	{		
		if( CurrentButton & IN_USE )
		{
			float vFallGravity; 													// Default gravity.
			
			if( CurrentButton & IN_SPEED )
				vFallGravity = 0.75; 												// Seventy-five percent gravity.
			else if( CurrentButton & IN_DUCK )
				vFallGravity = 0.5; 												// Fifty percent gravity.
			else
				vFallGravity = 1.0;
			
			SetEntityGravity( client, vFallGravity );
//			PrintHintText( client, "%s %N You are descending!", HINT_TAG, client );
			return;
		}
		
		SetEntityMoveType( client, MOVETYPE_FLYGRAVITY ); 
		
		float vEyeAngles[3], vAbsOrigin[3], vTemp[3], vSpeedIndex[3], vPushingForce[3]; 
		float vLifForce = 50.0, vGravity = 0.001, vNormalGravity = 0.01;
		float vSpeedLimit = fCvar_FlyingInfected_Speed;
		float vVariableSpeed;
		
		GetEntDataVector( client, vOffsetVelocity, vSpeedIndex );
		GetClientEyeAngles( client, vEyeAngles );
		GetClientAbsOrigin( client, vAbsOrigin );
//		vEyeAngles[0] = 0.0; 														// Crosshair angle offers greater jetpack control, zero array corresponds Up, Down.
		
		bool bJumping = false;
		
		if( CurrentButton & IN_JUMP ) 
		{
			bJumping = true;
			vEyeAngles[0] = -50.0; 													// Elevation Angle.
			GetAngleVectors( vEyeAngles, vEyeAngles, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector( vEyeAngles, vEyeAngles );
			ScaleVector( vEyeAngles, vSpeedLimit );
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vEyeAngles );
//			PrintHintText( client, "%s %N You are rising!", HINT_TAG, client );
			return;
		}
		
		if((CurrentButton & IN_SPEED) && !bJumping )
		{
			vVariableSpeed = vSpeedLimit * 75.0 / 100.0; 							// Seventy-five percent of max speed.
			
			if( CurrentButton & IN_FORWARD )
				vVariableSpeed = vSpeedLimit; 										// Max allowed speed
			
			GetAngleVectors( vEyeAngles, vEyeAngles, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector( vEyeAngles, vEyeAngles );
//			ScaleVector( vEyeAngles, vSpeedLimit );
			ScaleVector( vEyeAngles, vVariableSpeed );
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vEyeAngles );
//			PrintHintText( client, "%s %N Your current speed is[%f]", HINT_TAG, client, vVariableSpeed ); // Test.
//			PrintHintText( client, "%s %N You move at max speed!", HINT_TAG, client );
			return;
		}
		else if( !(CurrentButton & IN_SPEED) && (CurrentButton & IN_DUCK) && !bJumping )
		{
			vVariableSpeed = vSpeedLimit * 33.33 / 100.0; 							// Thirty-three percent of max speed.
			
			if( CurrentButton & IN_FORWARD )
				vVariableSpeed = vSpeedLimit * 50.0 / 100.0; 						// Fifty percent of max speed.
			
			GetAngleVectors( vEyeAngles, vEyeAngles, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector( vEyeAngles, vEyeAngles );
			ScaleVector( vEyeAngles, vVariableSpeed );
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vEyeAngles );
//			PrintHintText( client, "%s %N Your current speed is[%f]", HINT_TAG, client, vVariableSpeed ); // Test.
//			PrintHintText( client, "%s %N You move at the min speed!", HINT_TAG, client );
			return;
		}
		
		if( CurrentButton & IN_FORWARD )
		{ 
			GetAngleVectors( vEyeAngles, vTemp, NULL_VECTOR, NULL_VECTOR );
			NormalizeVector( vTemp, vTemp );
			AddVectors( vPushingForce, vTemp, vPushingForce );
//			PrintHintText( client, "%s %N You move forward!", HINT_TAG, client );
		}
		else if( CurrentButton & IN_BACK )
		{
			GetAngleVectors( vEyeAngles, vTemp, NULL_VECTOR, NULL_VECTOR );
			NormalizeVector( vTemp, vTemp ); 
			SubtractVectors( vPushingForce, vTemp, vPushingForce ); 
//			PrintHintText( client, "%s %N You move backwards!", HINT_TAG, client );
		}
		
		if( CurrentButton & IN_MOVELEFT )
		{ 
			GetAngleVectors( vEyeAngles, NULL_VECTOR, vTemp, NULL_VECTOR );
			NormalizeVector( vTemp, vTemp); 
			SubtractVectors( vPushingForce, vTemp, vPushingForce );
//			PrintHintText( client, "%s %N You move to the left!", HINT_TAG, client );
		}
		else if( CurrentButton & IN_MOVERIGHT )
		{
			GetAngleVectors( vEyeAngles, NULL_VECTOR, vTemp, NULL_VECTOR );
			NormalizeVector( vTemp, vTemp ); 
			AddVectors( vPushingForce, vTemp, vPushingForce );
//			PrintHintText( client, "%s %N You move to the right!", HINT_TAG, client );
		}
		
		NormalizeVector( vPushingForce, vPushingForce );
		ScaleVector( vPushingForce, vLifForce * fDuration );
		
		if( FloatAbs( vSpeedIndex[2] ) > 40.0 )
			vGravity = vSpeedIndex[2] * fDuration;
		else
			vGravity = vNormalGravity;
		
		float vCurrentSpeed = GetVectorLength( vSpeedIndex );
		
		if( vGravity > 0.5 ) vGravity = 0.5;
		if( vGravity < - 0.5 ) vGravity = - 0.5; 
		
		if( vCurrentSpeed > vSpeedLimit )
		{
			NormalizeVector( vSpeedIndex, vSpeedIndex );
			ScaleVector( vSpeedIndex, vSpeedLimit );
			TeleportEntity( client, NULL_VECTOR, NULL_VECTOR, vSpeedIndex );
			vGravity = vNormalGravity;
		}
		
		SetEntityGravity( client, vGravity );
		return; // From here the control is automatic.
	}
	
	float vOrigin[3];
	float vVelocity[3];
	
	GetClientAbsOrigin( client, vOrigin );
	GetEntDataVector( client, vOffsetVelocity, vVelocity );
	vOrigin[2] += 30.0;
	
	vCopyVector(ClientVelocity[client], vVelocity );	
	if( GetVectorLength( vVelocity ) < 10.0 ) return;
	NormalizeVector( vVelocity, vVelocity );
	
 	int iTarget = iArrayTarget[client];
	if( ScanTime[client] + 1.0 <= fTime )
	{
		ScanTime[client] = fTime;
		if( IsFakeClient( client ) )
		{
			iTarget = GetEnemy( vOrigin, vVelocity );
		}
		else 
		{
			float vLookDir[3];
			GetClientEyeAngles( client, vLookDir );
			GetAngleVectors( vLookDir, vLookDir, NULL_VECTOR, NULL_VECTOR ); 
			NormalizeVector( vLookDir, vLookDir );
			iTarget = GetEnemy( vOrigin, vLookDir );
		}
	}
	
	if( iTarget > 0 && IsClientInGame( iTarget ) && IsPlayerAlive( iTarget ) )
	{
		iArrayTarget[client] = iTarget;
	}
	else
	{
		iTarget = NULL;
		iArrayTarget[client] = iTarget;
	}
	
	float velocityenemy[3], vtrace[3];
	
	bool bVisible = false;
	float ENEMY_DISTANCE = 1000.0;
	if( iTarget )
	{
		float Objective[3];
		GetClientEyePosition( iTarget, Objective );
		ENEMY_DISTANCE = GetVectorDistance( vOrigin, Objective );
		bVisible = IfTwoPosVisible( vOrigin, Objective, client );
		GetEntDataVector( iTarget, vOffsetVelocity, velocityenemy );
		ScaleVector( velocityenemy, fDuration );
		AddVectors( Objective, velocityenemy, Objective );
		MakeVectorFromPoints(vOrigin, Objective, vtrace );
		
		if( iTarget && !IsFakeClient( iTarget ) && IsClientInGame( client ) && bCvar_FlyingInfected_Mssage )
			PrintHintText( iTarget, "Warning! You are in %N's sights, Distance[%d]", client, RoundFloat( ENEMY_DISTANCE ) );
	}
	
	static float vleft[3], vright[3], vup[3], vdown[3], vfront[3], vv1[3], vv2[3], vv3[3], vv4[3], vv5[3], vv6[3], vv7[3], vv8[3];
	
	float factor1 = 0.2; 
	float factor2 = 0.5;
	float base1 = 1500.0;
	float base2 = 10.0;
	float vAngles[3];
	float t;
	
	GetVectorAngles( vVelocity, vAngles );
	
	float front = GetDistanceVectorsPhysicsObjects( vOrigin, vAngles, 0.0,   0.0, vfront, client, FilterSelfAndSurvivor);
	float down 	= GetDistanceVectorsPhysicsObjects( vOrigin, vAngles, 90.0,  0.0, vdown, client, FilterSelfAndSurvivor );
	float up 	= GetDistanceVectorsPhysicsObjects( vOrigin, vAngles, -90.0, 0.0, vup, client );
	float left 	= GetDistanceVectorsPhysicsObjects( vOrigin, vAngles, 0.0,  90.0, vleft, client, FilterSelfAndSurvivor );
	float right = GetDistanceVectorsPhysicsObjects( vOrigin, vAngles, 0.0, -90.0, vright, client, FilterSelfAndSurvivor);
	
	float f1 = GetDistanceVectorsPhysicsObjects( vOrigin, vAngles, 30.0,  0.0,   vv1, client, FilterSelfAndSurvivor );
	float f2 = GetDistanceVectorsPhysicsObjects( vOrigin, vAngles, 30.0,  45.0,  vv2, client, FilterSelfAndSurvivor );
	float f3 = GetDistanceVectorsPhysicsObjects( vOrigin, vAngles, 0.0,   45.0,  vv3, client, FilterSelfAndSurvivor );
	float f4 = GetDistanceVectorsPhysicsObjects( vOrigin, vAngles, -30.0, 45.0,  vv4, client, FilterSelfAndSurvivor );
	float f5 = GetDistanceVectorsPhysicsObjects( vOrigin, vAngles, -30.0, 0.0,   vv5, client, FilterSelfAndSurvivor );
	float f6 = GetDistanceVectorsPhysicsObjects( vOrigin, vAngles, -30.0, -45.0, vv6, client, FilterSelfAndSurvivor );	
	float f7 = GetDistanceVectorsPhysicsObjects( vOrigin, vAngles, 0.0,   -45.0, vv7, client, FilterSelfAndSurvivor );
	float f8 = GetDistanceVectorsPhysicsObjects( vOrigin, vAngles, 30.0,  -45.0, vv8, client, FilterSelfAndSurvivor );
	
	NormalizeVector( vfront, vfront );
	NormalizeVector( vup, vup );
	NormalizeVector( vdown, vdown );
	NormalizeVector( vleft, vleft );
	NormalizeVector( vright, vright );
	NormalizeVector( vtrace, vtrace );
	NormalizeVector( vv1, vv1 );
	NormalizeVector( vv2, vv2 );
	NormalizeVector( vv3, vv3 );
	NormalizeVector( vv4, vv4 );
	NormalizeVector( vv5, vv5 );
	NormalizeVector( vv6, vv6 );
	NormalizeVector( vv7, vv7 );
	NormalizeVector( vv8, vv8 );
	
	if( bVisible ) base1 = 80.0;
	if( front > base1 ) front 	= base1;
	if( up 	  > base1 ) up 		= base1;
	if( down  > base1 ) down 	= base1;
	if( left  > base1 ) left 	= base1;
	if( right > base1 ) right 	= base1;
	if( f1 > base1 ) f1 = base1;
	if( f2 > base1 ) f2 = base1;
	if( f3 > base1 ) f3 = base1;	
	if( f4 > base1 ) f4 = base1;
	if( f5 > base1 ) f5 = base1;
	if( f6 > base1 ) f6 = base1;
	if( f7 > base1 ) f7 = base1;
	if( f8 > base1 ) f8 = base1;
	
	if( front < base2 ) front 	= base2;
	if( up    < base2 ) up 		= base2;
	if( down  < base2 ) down 	= base2;
	if( left  < base2 ) left 	= base2;
	if( right < base2 ) right 	= base2;
	if( f1 < base2 ) f1 = base2;
	if( f2 < base2 ) f2 = base2;	
	if( f3 < base2 ) f3 = base2;
	if( f4 < base2 ) f4 = base2;
	if( f5 < base2 ) f5 = base2;
	if( f6 < base2 ) f6 = base2;
	if( f7 < base2 ) f7 = base2;
	if( f8 < base2 ) f8 = base2;
	
	t = - 1.0 * factor1 * ( base1 - front ) / base1;
	ScaleVector( vfront, t );
	t = - 1.0 * factor1 * ( base1 - up ) / base1;
	ScaleVector( vup, t );
	t = - 1.0 * factor1 * ( base1 - down ) / base1;
	ScaleVector( vdown, t );
	t = - 1.0 * factor1 * ( base1 - left ) / base1;
	ScaleVector( vleft, t );
	t = - 1.0 * factor1 * ( base1 - right ) / base1;
	ScaleVector( vright, t );
	t = - 1.0 * factor1 * ( base1 - f1 ) / f1;
	ScaleVector( vv1, t );
	t = - 1.0 * factor1 * ( base1 - f2 ) / f2;
	ScaleVector( vv2, t );
	t = - 1.0 * factor1 * ( base1 - f3 ) / f3;
	ScaleVector( vv3, t );
	t = - 1.0 * factor1 * ( base1 - f4 ) / f4;
	ScaleVector( vv4, t );
	t = - 1.0 * factor1 * ( base1 - f5 ) / f5;
	ScaleVector( vv5, t );
	t = - 1.0 * factor1 * ( base1 - f6 ) / f6;
	ScaleVector( vv6, t );
	t = - 1.0 * factor1 * ( base1 - f7 ) / f7;
	ScaleVector( vv7, t );
	t = - 1.0 * factor1 * ( base1 - f8 ) / f8;
	ScaleVector( vv8, t );
	
	if( ENEMY_DISTANCE >= 500.0 ) ENEMY_DISTANCE = 500.0;
	t = 1.0 * factor2 * ( 1000.0 - ENEMY_DISTANCE ) / 500.0;
	ScaleVector( vtrace, t );

	AddVectors( vfront, vup, vfront );
	AddVectors( vfront, vdown, vfront );
	AddVectors( vfront, vleft, vfront );
	AddVectors( vfront, vright, vfront );
	AddVectors( vfront, vv1, vfront );
	AddVectors( vfront, vv2, vfront );
	AddVectors( vfront, vv3, vfront );
	AddVectors( vfront, vv4, vfront );
	AddVectors( vfront, vv5, vfront );
	AddVectors( vfront, vv6, vfront );
	AddVectors( vfront, vv7, vfront );
	AddVectors( vfront, vv8, vfront );
	AddVectors( vfront, vtrace, vfront );	
	NormalizeVector( vfront, vfront );
	
	ScaleVector( vfront, 3.141592 * fDuration * 2.0 );
	
	float vNewVelocity[3];
	AddVectors( vVelocity, vfront, vNewVelocity );
	
	float Speed = fCvar_FlyingInfected_Speed;
	if( Speed < 60.0 ) 
		Speed = 60.0;
	
	NormalizeVector( vNewVelocity, vNewVelocity );
	ScaleVector( vNewVelocity, Speed);   
	
	SetEntityMoveType( client, MOVETYPE_FLY );
//	SetEntityGravity( client, 0.01 );
	vCopyVector( vNewVelocity, ClientVelocity[client] );
	
	TeleportEntity( client, NULL_VECTOR, NULL_VECTOR , vNewVelocity );
}

/**
 * @note Validates if the client is valid.
 *
 * @param vPos				The vector for origin of client.
 * @param vlAngles			The vector for angle of client.
 **/
int GetEnemy( float vPos[3], float vAngles[3] )
{
	float vMinAngle = 4.0;
	float vPosition[3];
	int   iIndex = NULL;
	
	for( int i = 1; i <= MaxClients; i ++ )
	{
		if( IsClientInGame( i ) && GetClientTeam( i ) == 2 && IsPlayerAlive( i ) )
		{
			GetClientEyePosition( i, vPosition );
			MakeVectorFromPoints( vPos, vPosition, vPosition );
			if( GetAngle( vAngles, vPosition ) <= vMinAngle )
			{
				vMinAngle = GetAngle( vAngles, vPosition );
				iIndex = i;
			}
		}
	}
	
	return iIndex;
}

bool IfTwoPosVisible( float vAngles[3], float vOrigins[3], int iSelf )
{
	bool bR = true;
	Handle hTrace = TR_TraceRayFilterEx( vOrigins, vAngles, MASK_SOLID, RayType_EndPoint, DontHitSelfAndSurvivor, iSelf );
	if( TR_DidHit( hTrace ) ) 
		bR = false;
	
	delete hTrace;
	return bR;
}

float GetDistanceVectorsPhysicsObjects( float vOrigin[3], float vAngle[3], float vOffset1, float vOffset2, float vForce[3], int iEntity, int iFlag = FilterSelf )
{
	static float vAngles[3];
	vCopyVector( vAngle, vAngles );
	vAngles[0] += vOffset1;
	vAngles[1] += vOffset2;
	GetAngleVectors( vAngles, vForce, NULL_VECTOR,NULL_VECTOR ) ;
	float vDistance = GetRayDistance( vOrigin, vAngles, iEntity, iFlag ); 
	return vDistance; 
}

float GetAngle( float vX1[3], float vX2[3] )
{
	return ArcCosine( GetVectorDotProduct( vX1, vX2 ) / ( GetVectorLength( vX1 ) * GetVectorLength( vX2 ) ) );
}

public bool DontHitSelf( int entity, int mask, any data )
{
	if( entity == data )
		return false;
	
	return true;
}

public bool DontHitSelfAndPlayer( int entity, int mask, any data )
{
	if( entity == data )
		return false;
	else if( entity > 0 && entity <= MaxClients ) 
		if ( IsClientInGame( entity ) )
			return false;
		
	return true;
}

public bool DontHitSelfAndSurvivor( int entity, int mask, any data )
{
	if( entity == data )
		return false; 
	else if( entity > 0 && entity <= MaxClients ) 
		if ( IsClientInGame( entity ) && GetClientTeam( entity ) == 2 )
			return false;
		
	return true;
}

public bool DontHitSelfAndInfected( int entity, int mask, any data )
{
	if( entity == data ) 
		return false;
	else if( entity > 0 && entity <= MaxClients ) 
		if ( IsClientInGame(entity) && GetClientTeam(entity) == 3 )
			return false;
		
	return true;
}

public bool DontHitSelfAndPlayerAndCI( int entity, int mask, any data )
{
	if( entity == data ) 
		return false;
	else if( entity > 0 && entity <= MaxClients )
	{
		if( IsClientInGame( entity ) )
			return false;
	}
	else
	{
		if( IsValidEntity( entity ) && IsValidEdict( entity ) )
		{
			char sEdictName[128];
			GetEdictClassname( entity, sEdictName, sizeof( sEdictName ) );
			if( StrContains( sEdictName, "infected") >= 0 )
				return false;
		}
	}
	return true;
}

float GetRayDistance( float vOrigin[3], float vAngles[3], int iSelf, int iFlag )
{
	float vHitPos[3];
	GetRayHitPos( vOrigin, vAngles, vHitPos, iSelf, iFlag );
	return GetVectorDistance( vOrigin, vHitPos );
}

int GetRayHitPos( float vOrigin[3], float vAngles[3], float vHitPos[3], int iSelf, int iFlag )
{
	Handle hTrace;
	int iHit = NULL;
	
	if( iFlag == FilterSelf ) 						hTrace = TR_TraceRayFilterEx( vOrigin, vAngles, MASK_SOLID, RayType_Infinite, DontHitSelf, iSelf );
	else if( iFlag == FilterSelfAndPlayer ) 		hTrace = TR_TraceRayFilterEx( vOrigin, vAngles, MASK_SOLID, RayType_Infinite, DontHitSelfAndPlayer, iSelf );
	else if( iFlag == FilterSelfAndSurvivor ) 		hTrace = TR_TraceRayFilterEx( vOrigin, vAngles, MASK_SOLID, RayType_Infinite, DontHitSelfAndSurvivor, iSelf );
	else if( iFlag == FilterSelfAndInfected ) 		hTrace = TR_TraceRayFilterEx( vOrigin, vAngles, MASK_SOLID, RayType_Infinite, DontHitSelfAndInfected, iSelf );
	else if( iFlag == FilterSelfAndPlayerAndCI ) 	hTrace = TR_TraceRayFilterEx( vOrigin, vAngles, MASK_SOLID, RayType_Infinite, DontHitSelfAndPlayerAndCI, iSelf );
	if( TR_DidHit( hTrace ) )
	{	
		TR_GetEndPosition( vHitPos, hTrace);
		iHit = TR_GetEntityIndex( hTrace );
	}
	
	delete hTrace;
	return iHit;
}

stock void SetParentModel( int client )
{
	float vOrigin[3], vAngles[3];
	int RenderRGB[4], iEntity[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", vOrigin);
	GetEntPropVector(client, Prop_Send, "m_angRotation", vAngles);
	GetEntityRenderColor(client, RenderRGB[0], RenderRGB[1], RenderRGB[2], RenderRGB[3]);
	
	for( int iCount = 1; iCount <= 2; iCount ++ )
	{
		iEntity[iCount] = CreateEntityByName( "prop_dynamic_override" );
		if( IsValidEntity( iEntity[iCount] ) )
		{
			char sName[64];
			Format(sName, sizeof(sName), "Tank%d", client);
			DispatchKeyValue(client, "targetname", sName);
			GetEntPropString(client, Prop_Data, "m_iName", sName, sizeof(sName));
			
			DispatchKeyValue(iEntity[iCount], "model", "models/props_equipment/oxygentank01.mdl");
			SetEntityRenderColor(iEntity[iCount], RenderRGB[0], RenderRGB[1], RenderRGB[2], RenderRGB[3]);
			DispatchKeyValue(iEntity[iCount], "targetname", "PropaneTankEntity");
			DispatchKeyValue(iEntity[iCount], "parentname", sName);
			DispatchKeyValueVector(iEntity[iCount], "origin", vOrigin);
			DispatchKeyValueVector(iEntity[iCount], "angles", vAngles);
			DispatchSpawn(iEntity[iCount]);
			SetVariantString(sName);
			AcceptEntityInput(iEntity[iCount], "SetParent", iEntity[iCount], iEntity[iCount]);
			switch(iCount)
			{
				case 1:{ SetVariantString("rfoot"); vOrigin = view_as<float>({0.0, 30.0,  8.0}); }
				case 2:{ SetVariantString("lfoot"); vOrigin = view_as<float>({0.0, 30.0, -8.0}); }
			}
			AcceptEntityInput(iEntity[iCount], "SetParentAttachment");
			AcceptEntityInput(iEntity[iCount], "Enable");
			AcceptEntityInput(iEntity[iCount], "DisableCollision");
			SetEntPropEnt(iEntity[iCount], Prop_Send, "m_hOwnerEntity", client);
			
			vAngles = view_as<float>({0.0, 0.0, 90.0});
			
			TeleportEntity(iEntity[iCount], vOrigin, vAngles, NULL_VECTOR);
			
			StartGlowing( iEntity[iCount] );
			
			SDKUnhook(iEntity[iCount], SDKHook_SetTransmit, SetTransmit);
			SDKHook(iEntity[iCount], SDKHook_SetTransmit, SetTransmit);
		}
	}
}

stock void SetParentFlame( int client )
{
	float vOrigin[3], vAngles[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", vOrigin);
//	GetEntPropVector(client, Prop_Send, "m_angRotation", vAngles);
	int iEntity[3];
	
	for( int iCount = 1; iCount <= 2; iCount ++ )
	{
		iEntity[iCount] = CreateEntityByName("env_steam");
		if( IsValidEntity( iEntity[iCount] ) )
		{
			char sName[64];
			Format(sName, sizeof(sName), "Tank%d", client);
			DispatchKeyValue(client, "targetname", sName);
			GetEntPropString(client, Prop_Data, "m_iName", sName, sizeof(sName));
			
			DispatchKeyValue(iEntity[iCount], "targetname", "SteamEntity");
			DispatchKeyValue(iEntity[iCount], "parentname", sName);
			DispatchKeyValueVector(iEntity[iCount], "origin", vOrigin);
//			DispatchKeyValueVector(iEntity[iCount], "angles", vAngles);
			DispatchKeyValue(iEntity[iCount], "SpawnFlags", "1");
			DispatchKeyValue(iEntity[iCount], "Type", "0");
			DispatchKeyValue(iEntity[iCount], "InitialState", "1");
			DispatchKeyValue(iEntity[iCount], "Spreadspeed", "1");
			DispatchKeyValue(iEntity[iCount], "Speed", "250");
			DispatchKeyValue(iEntity[iCount], "Startsize", "6");
			DispatchKeyValue(iEntity[iCount], "EndSize", "8");
			DispatchKeyValue(iEntity[iCount], "Rate", "555");
			DispatchKeyValue(iEntity[iCount], "RenderColor", "255 100 10 41");
			DispatchKeyValue(iEntity[iCount], "JetLength", "40"); 
			DispatchKeyValue(iEntity[iCount], "RenderAmt", "180");
			DispatchSpawn(iEntity[iCount]);
			SetVariantString(sName);
			AcceptEntityInput(iEntity[iCount], "SetParent", iEntity[iCount], iEntity[iCount] );
			switch( iCount )
			{
				case 1:{ SetVariantString("rfoot"); vOrigin = view_as<float>({0.0, 0.0,  8.0}); }
				case 2:{ SetVariantString("lfoot"); vOrigin = view_as<float>({0.0, 0.0, -8.0}); }
			}
			AcceptEntityInput(iEntity[iCount], "SetParentAttachment");
			AcceptEntityInput(iEntity[iCount], "TurnOn");
			AcceptEntityInput(iEntity[iCount], "DisableCollision");
			SetEntPropEnt(iEntity[iCount], Prop_Send, "m_hOwnerEntity", client);
			
			vAngles = view_as<float>({0.0, -180.0, 0.0});
			
			GetVectorAngles(vAngles, vAngles);
			
			TeleportEntity(iEntity[iCount], vOrigin, vAngles, NULL_VECTOR);
			
			SDKUnhook(iEntity[iCount], SDKHook_SetTransmit, SetTransmit);
			SDKHook(iEntity[iCount], SDKHook_SetTransmit, SetTransmit);
		}
	}
}

void PlaySound( int client, const float vPos[3] )
{
	StopSound( iArraySounds[client], SNDCHAN_WEAPON, "ambient/Spacial_Loops/CarFire_Loop.wav" );
	EmitSoundToAll( "ambient/Spacial_Loops/CarFire_Loop.wav", iArraySounds[client], SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vPos, NULL_VECTOR, true, 0.0 );
}

stock void SetParentCrown( int client )
{
	if( !bCvar_FlyingInfected_Crown ) 
		return;
	
	static float vOrigin[3];
	static float vAngles[3];
	
	static char sColor[16];
	sColor = GetRandomClors();
	
	static int iColor;
	iColor = GetColor( sColor );
	
	int iEntity[7];
	for( int iCount = 1; iCount <= 6; iCount ++ )
	{
		iEntity[iCount] = CreateEntityByName("beam_spotlight");
		if( IsValidEntity( iEntity[iCount] ) )
		{
			DispatchKeyValue(iEntity[iCount], "spawnflags", "3");
			DispatchKeyValue(iEntity[iCount], "HaloScale", "100"); 			// Tamaño de la aureola
			DispatchKeyValue(iEntity[iCount], "SpotlightWidth", "10");  	// Ancho de la luz
			DispatchKeyValue(iEntity[iCount], "SpotlightLength", "50"); 	// Longitud de la luz
			DispatchKeyValue(iEntity[iCount], "renderamt", "125");
			DispatchKeyValueFloat(iEntity[iCount], "HDRColorScale", 0.7);
			SetEntProp(iEntity[iCount], Prop_Send, "m_clrRender", iColor);
			
			DispatchSpawn(iEntity[iCount]);
			
			SetVariantString("!activator");
			AcceptEntityInput(iEntity[iCount], "SetParent", client);
	
			switch( iCount )
			{				
				case 1: vAngles = view_as<float>({ -45.0, 60.0,  0.0 });
				case 2: vAngles = view_as<float>({ -45.0, 120.0, 0.0 });
				case 3: vAngles = view_as<float>({ -45.0, 180.0, 0.0 });
				case 4: vAngles = view_as<float>({ -45.0, 240.0, 0.0 });
				case 5: vAngles = view_as<float>({ -45.0, 300.0, 0.0 });
				case 6: vAngles = view_as<float>({ -45.0, 360.0, 0.0 });
			}
			
			vOrigin[2] = 95.0; 											// Altura
			
			AcceptEntityInput(iEntity[iCount], "Enable"); 				// No esencial
			AcceptEntityInput(iEntity[iCount], "DisableCollision"); 	// No esencial
			SetEntProp(iEntity[iCount], Prop_Send, "m_hOwnerEntity", client);
			
			AcceptEntityInput(iEntity[iCount], "TurnOn");
			
			TeleportEntity(iEntity[iCount], vOrigin, vAngles, NULL_VECTOR);
		}
	}
}

stock void SetParentLight( int client )
{
	if( !bCvar_FlyingInfected_JetPack_Light ) 
		return;
	
	int iEntity = CreateEntityByName("light_dynamic");	
	if( IsValidEntity( iEntity ) )
	{
		DispatchKeyValue(iEntity, "inner_cone", "0");
		DispatchKeyValue(iEntity, "cone", "80");
		DispatchKeyValue(iEntity, "brightness", "6");
		DispatchKeyValueFloat(iEntity, "spotlight_radius", 240.0);
		DispatchKeyValueFloat(iEntity, "distance", 250.0);
		DispatchKeyValue(iEntity, "_light", "255 100 10 41"); // Orange
		DispatchKeyValue(iEntity, "pitch", "-90");
		DispatchKeyValue(iEntity, "style", "5");
		DispatchSpawn(iEntity);
		
		static float vPosition[3], vAngleA[3], vAngleB[3], vForward[3], vOrigin[3];
		
		GetClientEyePosition( client, vPosition );
		GetClientEyeAngles( client, vAngleA );
		GetClientEyeAngles( client, vAngleB );

		vAngleB[0] = 0.0;
		vAngleB[2] = 0.0;
		GetAngleVectors( vAngleB, vForward, NULL_VECTOR, NULL_VECTOR );
		ScaleVector( vForward, -50.0 );
		vForward[2] = 0.0;
		AddVectors( vPosition, vForward, vOrigin );

		vAngleA[0] += 90.0;
		vOrigin[2] -= 120.0;
		TeleportEntity(iEntity, vOrigin, vAngleA, NULL_VECTOR);

		char sName[32];
		Format(sName, sizeof(sName), "Tank%d", client);
		DispatchKeyValue(client, "targetname", sName);
		
		DispatchKeyValue(iEntity, "parentname", sName);
		SetVariantString("!activator");
		AcceptEntityInput(iEntity, "SetParent", client );
		AcceptEntityInput(iEntity, "TurnOn");
		SetEntProp(iEntity, Prop_Send, "m_hOwnerEntity", client);
	}
}

stock void StartGlowing( int entity )
{
	if( !entity || !bLeft4DeadTwo ) 
		return;
	
	int RenderRGB[4];
	GetEntityRenderColor( entity, RenderRGB[0], RenderRGB[1], RenderRGB[2], RenderRGB[3] );
	
	SetEntProp( entity, Prop_Send, "m_iGlowType", 2 ); // 2 = Brillo visible solo si el objeto es visible, 3 = Brillo visible a traves de objetos.
	SetEntProp( entity, Prop_Send, "m_bFlashing", 1 );
	SetEntProp( entity, Prop_Send, "m_nGlowRange", 10000 );
	SetEntProp( entity, Prop_Send, "m_nGlowRangeMin", 100);
	SetEntProp( entity, Prop_Send, "m_glowColorOverride", RenderRGB[0] + ( RenderRGB[1] * 256 ) + ( RenderRGB[2] * 65536 ) );
//	AcceptEntityInput( entity, "StartGlowing" );
}

stock void StopGlowing( int entity )
{
	if( !entity || !bLeft4DeadTwo )
		return;
	
	SetEntProp( entity, Prop_Send, "m_iGlowType", 0 );
	SetEntProp( entity, Prop_Send, "m_bFlashing", 0 );
	SetEntProp( entity, Prop_Send, "m_nGlowRange",0 );
	SetEntProp( entity, Prop_Send, "m_glowColorOverride", 0 );
}

stock char[] GetRandomClors()
{
	static char sColor[16];
	switch( GetRandomInt( 1, 12 ) ) // Best color selection.
	{
		case 1: Format( sColor, sizeof( sColor ), "255 0 0 255" ); 		// Red
		case 2: Format( sColor, sizeof( sColor ), "0 255 0 255" ); 		// Green
		case 3: Format( sColor, sizeof( sColor ), "0 0 255 255" ); 		// Blue
		case 4: Format( sColor, sizeof( sColor ), "100 0 150 255" ); 	// Purple
		case 5: Format( sColor, sizeof( sColor ), "255 155 0 255" ); 	// Orange
		case 6: Format( sColor, sizeof( sColor ), "255 255 0 255" ); 	// Yellow
		case 7: Format( sColor, sizeof( sColor ), "-1 -1 -1 255" ); 	// White
		case 8: Format( sColor, sizeof( sColor ), "255 0 150 255" ); 	// Pink
		case 9: Format( sColor, sizeof( sColor ), "0 255 255 255" ); 	// Cyan
		case 10:Format( sColor, sizeof( sColor ), "128 255 0 255" ); 	// Lime
		case 11:Format( sColor, sizeof( sColor ), "0 128 128 255" ); 	// Teal
		case 12:Format( sColor, sizeof( sColor ), "50 50 50 255" ); 	// Grey
	}
	
	return sColor; // Format( sColor, sizeof( sColor ), "%i %i %i 255", GetRandomInt( 0, 255 ), GetRandomInt( 0, 255 ), GetRandomInt( 0, 255 ) );
}

stock int GetColor( char[] sTemp ) // Converts an array to an integer value.
{
	char sColors[4][4];
	ExplodeString(sTemp, " ", sColors, sizeof sColors, sizeof sColors[]);

	int iColor;
	iColor = StringToInt(sColors[0]);
	iColor += 256 * StringToInt(sColors[1]);
	iColor += 65536 * StringToInt(sColors[2]);
	return iColor;
}

public Action SetTransmit( int entity, int client )
{
	if( !IsValidClient( client ) )
		return Plugin_Stop;
	
	int iOwner = GetEntPropEnt( entity, Prop_Send, "m_hOwnerEntity" );
	if( iOwner == client && !IsTankThirdPerson( client ) && !IsFakeClient( client ) )
		return Plugin_Handled;

	return Plugin_Continue;
}

stock bool IsTankThirdPerson( int client )// Stock from Mutan Tanks by Crasher_3637
{
	if( IsPlayerIncapped( client ) )
		return true;
	
	if((bLeft4DeadTwo && GetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView" ) > GetGameTime() ) || 
	GetEntPropFloat( client, Prop_Send, "m_staggerTimer", 1 ) > -1.0 || 
	GetEntPropEnt( client, Prop_Send, "m_hViewEntity" ) > 0 )
		return true;

	if( IsTank( client ) )
	{
		switch( GetEntProp( client, Prop_Send, "m_nSequence" ) )
		{
			case 28, 29, 30, 31, 47, 48, 49, 50, 51, 73, 74, 75, 76, 77: return true;
		}
	}

	return false;
}

/**
 * @note Validates if the current client is valid to run the plugin.
 *
 * @param client		The client index.
 * @return              False if the client is not the Tank, true otherwise.
 */
stock bool IsTank( int client )
{
	if( client > 0 && client <= MaxClients && IsClientInGame( client ) && GetClientTeam( client ) == 3 )
		if( GetEntProp( client, Prop_Send, "m_zombieClass" ) == ( bLeft4DeadTwo ? 8 : 5 ) )
			return true;
	
	return false;
}

stock bool IsValidClient( int client )
{
	return client > 0 && client <= MaxClients && IsClientInGame( client ) && !IsClientInKickQueue( client );
}

bool IsAllowedPlugin()
{
	if( !bCvar_FlyingInfected_Enabled || !IsAllowedGameMode() || !IsAllowedMap() || !IsFinale() ) 
		return false;
	
	return true;
}

bool IsFinale()
{
	if( !bCvar_FlyingInfected_FinaleOnly || ( bCvar_FlyingInfected_FinaleOnly && bFinalEvent ) )
		return true;
	
	return false;
}

stock bool IsPlayerIncapped( int client )
{
	if( GetEntProp( client, Prop_Send, "m_isIncapacitated", 1 ) ) 
		return true;
		
	return false;
}

/**
 * @note Check if the current game mode is allowed and based on this it returns a boolean value.
 *
 * @return           True if game mode is valid, false otherwise.
 */
bool IsAllowedGameMode()
{
	if( hCvar_MPGameMode == null )
		return false;
	
	if( iCvar_GameModesToggle != 0 )
	{
		if( bMapStarted == false )
			return false;

		iCvar_CurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) 	// Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); 		// Because multiple plugins creating at once, avoid too many duplicate ents in the same frame.
		}

		if( iCvar_CurrentMode == 0 )
			return false;

		if( !(iCvar_GameModesToggle & iCvar_CurrentMode) )
			return false;
	}
	
	char sGameMode[256], sGameModes[256];
	Format(sGameMode, sizeof(sGameMode), ",%s,", sCvar_MPGameMode);
	
	strcopy(sGameModes, sizeof(sCvar_GameModesOn), sCvar_GameModesOn);
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}
	
	strcopy(sGameModes, sizeof(sCvar_GameModesOff), sCvar_GameModesOff);
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

/**
 * @note Sets the running game mode int value.
 *
 * @param sOutput        Output.
 * @param iCaller        Caller.
 * @param iActivator     Activator.
 * @param fDelay         Delay.
 * @noreturn
 */
public void OnGamemode(const char[] sOutput, int iCaller, int iActivator, float fDelay)
{
	if( strcmp(sOutput, "OnCoop") == 0 )
		iCvar_CurrentMode = 1;
	else if( strcmp(sOutput, "OnSurvival") == 0 )
		iCvar_CurrentMode = 2;
	else if( strcmp(sOutput, "OnVersus") == 0 )
		iCvar_CurrentMode = 4;
	else if( strcmp(sOutput, "OnScavenge") == 0 )
		iCvar_CurrentMode = 8;
}

/**
 * @note Validates if the current game mode is valid to run the plugin.
 *
 * @return           True if game mode is valid, false otherwise.
 */
bool IsAllowedMap()
{
	char sMap[256], sMaps[256];
	Format(sMap, sizeof(sMap), ",%s,", sCurrentMap);
	
	strcopy( sMaps, sizeof( sMaps ), sCvar_MapsOn );
	if( !StrEqual( sMaps, "", false ) )
	{
		Format( sMaps, sizeof( sMaps ), ",%s,", sMaps );
		if( StrContains( sMaps, sMap, false ) == -1 )
			return false;
	}
	
	strcopy( sMaps, sizeof( sMaps ), sCvar_MapsOff );
	if( !StrEqual( sMaps, "", false ) )
	{
		Format( sMaps, sizeof( sMaps ), ",%s,", sMaps );
		if( StrContains(sMaps, sMap, false) != -1 )
			return false;
	}
	
	return true;
}

stock void vCopyVector( const float vSource[3], float vTarget[3] )
{
	vTarget[0] = vSource[0];
	vTarget[1] = vSource[1];
	vTarget[2] = vSource[2];
}

stock void StopFly( int client )
{
	if( iArrayStatus[client] != STATE_FLY )
		return;
	
	iArrayStatus[client] = STATE_NONE;
	
	StopSound( iArraySounds[client], SNDCHAN_WEAPON, "ambient/Spacial_Loops/CarFire_Loop.wav" );
	
	SDKUnhook(client, SDKHook_PreThink, PreThink); 
	SDKUnhook(client, SDKHook_StartTouch, FlyTouch);
	
	SetEntityMoveType( client, MOVETYPE_WALK );
	SetEntityGravity( client, 1.0 );
	
	StopGlowing( client );
	
	int entity = -1;
	
	while( ( entity = FindEntityByClassname( entity, "prop_dynamic" ) ) != INVALID_ENT_REFERENCE )
	{
		char sModel[128];
		GetEntPropString( entity, Prop_Data, "m_ModelName", sModel, sizeof( sModel ) );
		if ( StrEqual( sModel, "models/props_equipment/oxygentank01.mdl" ) )
		{
			int iOwner = GetEntPropEnt( entity, Prop_Send, "m_hOwnerEntity" );
			if( iOwner == client )
			{
				AcceptEntityInput( entity, "ClearParent" );
				AcceptEntityInput( entity, "Kill" );
			}
		}
	}
	
	while( ( entity = FindEntityByClassname( entity, "beam_spotlight" ) ) != INVALID_ENT_REFERENCE )
	{
		int iOwner = GetEntProp( entity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == client )							
		{
			AcceptEntityInput( entity, "Kill" );
		}
	}
	
	while( ( entity = FindEntityByClassname( entity, "env_steam" ) ) != INVALID_ENT_REFERENCE )
	{
		int iOwner = GetEntPropEnt( entity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == client )
		{
			AcceptEntityInput( entity, "Kill" );
		}
	}
	
	while( ( entity = FindEntityByClassname( entity, "light_dynamic" ) ) != INVALID_ENT_REFERENCE )
	{
		int iOwner = GetEntProp( entity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == client )							
		{
			AcceptEntityInput( entity, "Kill" );
		}
	}
}

/* ===========================
			The End?
   =========================== */
