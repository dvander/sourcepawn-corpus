#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR		"tuty"
#define PLUGIN_VERSION		"1.0"
#define TICK_SOUND_FILE		"buttons/button14.wav"
#pragma semicolon 1

new Handle:gPluginEnabled = INVALID_HANDLE;
new Handle:gBlockVoice = INVALID_HANDLE;
new Handle:gBlockHandSignal = INVALID_HANDLE;
new Handle:gBlockAll = INVALID_HANDLE;
new Handle:gBlockTime = INVALID_HANDLE;

new Float:bLastUsed[ 33 ];
new i;

new String:szVoiceCommands[][] = 
{
/* ==== Voice commands		   In game messages ==== */

	"voice_gogogo",		// Go Go Go! (Germans)
	"voice_attack", 	// Go Go Go! (us marines)
	"voice_hold",		// Hold This Position!
	"voice_left",		// Squad, flank left!
	"voice_right",		// Squad, flank right!
	"voice_sticktogether",	// Squad, stick together!
	"voice_cover",		// Squad, covering fire!
	"voice_usesmoke",	// Smoke em!
	"voice_usegrens",	// Use your grenades!
	"voice_ceasefire",	// Cease fire!
	"voice_yessir",		// Yes sir!
	"voice_negative",	// Negative!
	"voice_backup",		// I need backup!
	"voice_fireinhole", 	// Fire in the hole!
	"voice_grenade",	// Grenade, take cover!
	"voice_sniper",		// Sniper!
	"voice_niceshot",	// Nice shot!
	"voice_thanks",		// Thanks!
	"voice_areaclear",	// Area clear!
	"voice_dropweapons",	// Drop your weapons!
	"voice_displace",	// Displace!
	"voice_mgahead",	// Machine gun ahead!
	"voice_enemybehind",	// Enemy behind us!
	"voice_moveupmg",	// Move up the machinegun!
	"voice_needammo",	// I need ammo!
	"voice_usebazooka",	// Use the panzerschreck!(us marines)  |  Use the Bazooka!(germans)
	"voice_fireleft",	// Taking fire, left flank!
	"voice_fireright",	// Taking fire, right flank!
	"voice_fallback",	// Fall Back!
	"voice_enemyahead",	// Enemy ahead!
	"voice_medic",		// Medic!
	"voice_coverflanks",	// Cover the flanks!
	"voice_takeammo",	// Take this ammo!
	"voice_bazookaspotted",	// Panzerschreck!(us marines)  |  Bazooka!(germans)
	"voice_wegothim",	// Enemy position knocked out! Move Up!
	"voice_wtf",		// Whiskey! Tango! Foxtrot!
	"voice_movewithtank",	// Move with the tank!
	"voice_tank"		// Tiger Ahead!
};
new String:szHandSignals[][] = 
{
	"signal_areaclear", "signal_moveout", "signal_backup", "signal_coveringfire", "signal_enemyspotted", "signal_fallback",
	"signal_enemyleft", "signal_enemyright", "signal_grenade", "signal_holdposition", "signal_flankleft", "signal_no",
	"signal_flankright", "signal_sniper", "signal_sticktogether", "signal_yes"
};
public Plugin:myinfo = 
{
	name = "DoD:S AntiSpam",
	author = PLUGIN_AUTHOR,
	description = "Block voice and hand signals, when are abused.",
	version = PLUGIN_VERSION,
	url = "www.ligs.us"
};
public OnPluginStart()
{
	for( i = 0; i < sizeof szVoiceCommands; i++ )
	{
		RegConsoleCmd( szVoiceCommands[ i ], Command_BlockVoice );
	}
	
	for( i = 0; i < sizeof szHandSignals; i++ )
	{
		RegConsoleCmd( szHandSignals[ i ], Command_BlockSignal );
	}
	
	CreateConVar( "dods_antispam_version", PLUGIN_VERSION, "DoD:S AntiSpam", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
	gPluginEnabled = CreateConVar( "dods_antispam_enabled", "1" );
	gBlockVoice = CreateConVar( "dods_antispam_voiceblock", "1" );
	gBlockHandSignal = CreateConVar( "dods_antispam_hsignalblock", "1" );
	gBlockTime = CreateConVar( "dods_antispam_blocktime", "5" );
	gBlockAll = CreateConVar( "dods_antispam_blockall", "0" );
}
public Action:Command_BlockVoice( id, args )
{
	if( GetConVarInt( gPluginEnabled ) == 1 )
	{
		if( GetConVarInt( gBlockAll ) == 1 )
		{
			PrintToChat( id, "[DoD:S AntiSpam] Sorry dude, the 'Voice' commands are blocked!" );
			EmitSoundToClient( id, TICK_SOUND_FILE );
			
			return Plugin_Handled;
		}
		
		if( GetConVarInt( gBlockVoice ) == 1 )
		{
			new iTime = GetConVarInt( gBlockTime );
			new Float:fGameTime = GetGameTime();

			if( fGameTime - bLastUsed[ id ] < iTime )
			{
				PrintToChat( id, "[DoD:S AntiSpam] Sorry, you must wait %d seconds until you can use 'Voice' commands again!", iTime );
				EmitSoundToClient( id, TICK_SOUND_FILE );
				
				return Plugin_Handled;
			}
			
			bLastUsed[ id ] = fGameTime;
		}
	}
	
	return Plugin_Continue;
}
public Action:Command_BlockSignal( id, args )
{
	if( GetConVarInt( gPluginEnabled ) == 1 )
	{
		if( GetConVarInt( gBlockAll ) == 1 )
		{
			PrintToChat( id, "[DoD:S AntiSpam] Sorry dude, the 'Hand Signal' commands are blocked!" );
			EmitSoundToClient( id, TICK_SOUND_FILE );
			
			return Plugin_Handled;
		}
		
		if( GetConVarInt( gBlockHandSignal ) == 1 )
		{
			new iTime = GetConVarInt( gBlockTime );
			new Float:fGameTime = GetGameTime();

			if( fGameTime - bLastUsed[ id ] < iTime )
			{
				PrintToChat( id, "[DoD:S AntiSpam] Sorry, you must wait %d seconds until you can use 'Hand Signals' again!", iTime );
				EmitSoundToClient( id, TICK_SOUND_FILE );
					
				return Plugin_Handled;
			}
			
			bLastUsed[ id ] = fGameTime;
		}
	}
	
	return Plugin_Continue;
}
