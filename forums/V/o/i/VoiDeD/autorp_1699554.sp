
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <sendproxy>


#define PLUGIN_VERSION	"0.1"

public Plugin:myinfo =
{
	name = "Force AutoRP",
	author = "VoiDeD",
	description = "By the Will of Ruinous Hespera, John Madden",
	version = PLUGIN_VERSION,
	url = "http://saxtonhell.com"
};


new Handle:g_EnabledCvar = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar( "autorp_version", PLUGIN_VERSION, "Forced AutoRP Version", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD );
	
	g_EnabledCvar = CreateConVar( "tf_autorp_forced", "1", "Force AutoRP" );
	HookConVarChange( g_EnabledCvar, OnEnableChanged );
}

public OnEnableChanged( Handle:cvar, const String:oldValue[], const String:newValue[] )
{
	// force the gamerules sendtable to precalculate again
	// this calls our proxy
	GameRules_SetProp( "m_bPlayingMedieval", false, 1, 0, true );
}

public OnMapStart()
{
	new entGamerules = FindEntityByClassname( -1, "tf_gamerules" );
	
	if ( entGamerules == -1 )
	{
		SetFailState( "Unable to find tf_gamerules!" );
	}
	
	SendProxy_Hook( entGamerules, "m_bPlayingMedieval", Prop_Int, MedievalProxy );
}

public Action:MedievalProxy( entity, const String:propName[], &iValue, element )
{
	iValue = GetConVarBool( g_EnabledCvar );
	return Plugin_Changed;
}