#include <sourcemod>
#define PLUGIN_VERSION "1.0"

new Handle:cvar_ToggleEnabled;
new Handle:cvar_ToggleFFSafeRoom;
new bool:var_ToggleFFEnabled = true;
new bool:var_ToggleFFSafeRoom = false;
new bool:var_LeftSafeRoom = false;

public Plugin:myinfo = 
{
	name = "Toggle Friendly Fire",
	author = "Squidinator",
	description = "Disable Friendly Fire",
	version = PLUGIN_VERSION,
	url = "zombiehunterkillzone.com"
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
	cvar_ToggleEnabled = CreateConVar( "l4d2_toggleff_enabled", "1", "Is the plugin enabled?", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	cvar_ToggleFFSafeRoom = CreateConVar( "l4d2_toggleff_safe_room_only", "1", "Only disable friendly fire in the safe room?", FCVAR_PLUGIN, true, 0.0, true, 1.0 );

	HookConVarChange( cvar_ToggleEnabled, ToggleFFCVarChanged );

	AutoExecConfig( true, "l4d2_toggle_friendly_fire" );
	RegAdminCmd( "sm_regcommon", ToggleFriendlyFire, ADMFLAG_BAN, "Toggles Friendly Fire On/Off.", _, FCVAR_PLUGIN );

	HookEvent( "player_left_start_area", Event_player_left_start_area, EventHookMode_PostNoCopy );
	HookEvent( "door_open", Event_DoorOpen, EventHookMode_PostNoCopy );
}

public OnMapStart()
{
	if ( var_ToggleFFEnabled )
	{
		modifyCvars();
	}
	else
	{
		unmodifyCvars();
	}
}

public ToggleFFCVarChanged( Handle:convar, const String:oldValue[], const String:newValue[] )
{
	var_ToggleFFEnabled = GetConVarBool( cvar_ToggleEnabled );
	var_ToggleFFSafeRoom  = GetConVarBool( cvar_ToggleFFSafeRoom );
	
	if ( var_ToggleFFEnabled )
	{
		modifyCvars();
	}
	else
	{
		unmodifyCvars();
	}
}

public Action:ToggleFriendlyFire( client,args )
{
	if ( var_ToggleFFEnabled )
	{
		SetConVarInt( cvar_ToggleEnabled, 0 );
		ReplyToCommand( client,"[SM] Friendly Fire is now Enabled." );
	}
	else
	{
		SetConVarInt( cvar_ToggleEnabled, 1 );
		ReplyToCommand( client,"[SM] Friendly Fire is now Disabled." );
	}
	return Plugin_Handled;
}

public Event_player_left_start_area(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( !var_LeftSafeRoom )
	{
		var_LeftSafeRoom = true;
		if ( var_ToggleFFSafeRoom )
		{
			SetConVarInt( cvar_ToggleEnabled, 0 );
		}
	}
}

public Event_DoorOpen(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( !var_LeftSafeRoom )
	{
		if ( GetEventBool( event, "checkpoint" ) )
		{
			var_LeftSafeRoom = true;
			if ( var_ToggleFFSafeRoom )
			{
				SetConVarInt( cvar_ToggleEnabled, 0 );
			}
		}
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

	SetCheatVar( FindConVar( "survivor_friendly_fire_factor_normal" ) );
	SetCheatVar( FindConVar( "survivor_friendly_fire_factor_hard" ) );
	SetCheatVar( FindConVar( "survivor_friendly_fire_factor_expert" ) );
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