#include <sourcemod>
#define PLUGIN_VERSION "1.0"

new bool:var_LeftSafeRoom = false;

public Plugin:myinfo = 
{
	name = "Disable Saferoom Friendly Fire",
	author = "Squidinator",
	description = "Disable SafeRoom Friendly Fire",
	version = PLUGIN_VERSION,
	url = "bilago.com"
};

public OnPluginStart()
{
    // Require Left 4 Dead 2
    decl String:game_name[64];
    GetGameFolderName( game_name, sizeof( game_name ) );
    if ( !StrEqual( game_name, "left4dead2", false ) )
    {
        SetFailState( "Plugin supports Left 4 Dead 2 only." );
    }

	CreateConVar( "l4d2_toggleff_version", PLUGIN_VERSION, "L4D2 Toggle Friendly Fire Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY );
	
	AutoExecConfig( true, "l4d2_toggle_friendly_fire" );
	//RegAdminCmd( "sm_regcommon", ToggleFriendlyFire, ADMFLAG_BAN, "Toggles Friendly Fire On/Off.", _, FCVAR_PLUGIN );
	
	HookEvent( "player_left_start_area", Event_player_left_start_area );
	HookEvent( "door_open", Event_DoorOpen );
	HookEvent("round_end", Event_round_end);
}

public OnMapStart()
{
	modifyCvars();
	var_LeftSafeRoom = false;
	
}

public Event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{

	if ( var_LeftSafeRoom )
	{
		var_LeftSafeRoom = false;
		modifyCvars();
	}
}

public Event_player_left_start_area(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( !var_LeftSafeRoom )
	{	
		var_LeftSafeRoom = true;		
		unmodifyCvars();
	}
}

public Event_player_left_checkpoint(Handle:event, const String:name[], bool:dontBroadcast)
{

	if ( !var_LeftSafeRoom )
	{		
		var_LeftSafeRoom = true;		
		unmodifyCvars();
	}
}


public Event_DoorOpen(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( !var_LeftSafeRoom )
	{		
		var_LeftSafeRoom = true;
		unmodifyCvars();
	}
}

modifyCvars()
{
	UnsetCheatVar( FindConVar( "survivor_friendly_fire_factor_normal" ) );
	UnsetCheatVar( FindConVar( "survivor_friendly_fire_factor_hard" ) );
	UnsetCheatVar( FindConVar( "survivor_friendly_fire_factor_expert" ) );

	SetConVarFloat( FindConVar( "survivor_friendly_fire_factor_normal" ), 0.0 );
	SetConVarFloat( FindConVar( "survivor_friendly_fire_factor_hard" ), 0.0 );
	SetConVarFloat( FindConVar( "survivor_friendly_fire_factor_expert" ), 0.0 );
}

unmodifyCvars()
{
	ResetConVar( FindConVar( "survivor_friendly_fire_factor_normal" ) );
	ResetConVar( FindConVar( "survivor_friendly_fire_factor_hard" ) );
	ResetConVar( FindConVar( "survivor_friendly_fire_factor_expert" ) );
	
	SetConVarFloat( FindConVar( "survivor_friendly_fire_factor_normal" ), 0.1 );
	SetConVarFloat( FindConVar( "survivor_friendly_fire_factor_hard" ), 0.3 );
	SetConVarFloat( FindConVar( "survivor_friendly_fire_factor_expert" ), 0.5 );	
}

stock UnsetCheatVar(Handle:hndl)
{
	new flags = GetConVarFlags(hndl);
	flags &= ~FCVAR_CHEAT;
	SetConVarFlags(hndl, flags);
}
 
stock SetCheatVar(Handle:hndl)
{
	new flags = GetConVarFlags(hndl);
	flags |= FCVAR_CHEAT;
	SetConVarFlags(hndl, flags);
}