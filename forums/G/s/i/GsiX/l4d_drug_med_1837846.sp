#define PLUGIN_VERSION "1.0"

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new Handle:drugmed_enable;
new Handle:drugmed_number;

new bool:g_DrugSpawn	= false;
new cvarEnable			= 0;
new cvarDrug			= 0;

public Plugin:myinfo = 
{
	name		= "Increase Med spawn",
	author		= "GsiX",
	description	= "Add more drug on the map..",
	version		= PLUGIN_VERSION,
	url			= ""	
}

public OnPluginStart()
{
	CreateConVar( "l4d_drugmed_version", PLUGIN_VERSION, " ", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	drugmed_enable		= CreateConVar( "l4d_drugmed_enable",		"1",	"0:Off,  1:On,  Toggle plugin On/Off.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	drugmed_number		= CreateConVar( "l4d_drugmed_number",		"3",	"How many drug we spawn per one spot.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	AutoExecConfig( true, "l4d2_drug_med" );
	HookEvent( "player_spawn",			EVENT_PlayerSpawn );
	HookEvent( "round_end",				EVENT_RoundEnd );
	HookConVarChange( drugmed_enable,	CVARChanged );
	HookConVarChange( drugmed_number,	CVARChanged );
}

public OnMapStart()
{
	UpdateCvar();
	g_DrugSpawn = false;
}

public OnConfigsExecuted()
{
	UpdateCvar();
}

public CVARChanged( Handle:convar, const String:oldValue[], const String:newValue[] )
{
	UpdateCvar();
}

UpdateCvar()
{
	cvarEnable	= GetConVarInt( drugmed_enable );
	cvarDrug	= GetConVarInt( drugmed_number );
}

public EVENT_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( !g_DrugSpawn && cvarEnable == 1 )
	{
		g_DrugSpawn = true;
		DuplicateItem( cvarDrug, "weapon_first_aid_kit" );
	}
}

public EVENT_RoundEnd( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( cvarEnable == 1 )
	{
		g_DrugSpawn = false;
	}
}

DuplicateItem( Qty, const String:item[] )
{
	new i;
	new m;
	decl String:newName[64];
	decl String:edictName[64];
	Format( newName, sizeof( newName), "%s_spawn", item );
		
	new ent = GetEntityCount();
	
	for ( i = MaxClients; i <= ent; i ++ )
	{
		if ( !IsValidEntity( i )) continue;
		
		GetEntityClassname( i, edictName, sizeof( edictName ));
		if ( StrContains( edictName, newName, false ) != -1)
		{
			for ( m = 1; m <= Qty; m++ )
			{
				CreateEntity( i, item );
			}
		}
	}
}

CreateEntity( index, const String:ItemName[] )
{
	decl Float:mmPos[3];
	decl Float:mmAng[3];
	GetEntPropVector( index, Prop_Send, "m_vecOrigin", mmPos );
	GetEntPropVector( index, Prop_Data, "m_angRotation", mmAng );
	mmPos[0] += GetRandomFloat( -15.0, 15.0 );
	mmPos[1] += GetRandomFloat( -15.0, 15.0 );
	mmPos[2] += GetRandomFloat( 5.0, 15.0 );
	mmAng[1] += GetRandomFloat( -15.0, 15.0 );
	
	new ent = CreateEntityByName( ItemName );
	if ( ent != -1 )
	{
		DispatchSpawn( ent );
		TeleportEntity( ent, mmPos, mmAng, NULL_VECTOR);
	}
}


