#pragma semicolon 1
#include <sourcemod>

#define GAY_VERSION					"0.0"
#define GAY_DESCRIPTION				"Modify gay HP on spawn"
#define GAY_TEAM_T					2
#define GAY_TEAM_CT					3
#define INVALID_GAY					-1

#define GAY_MIN_LEVEL				Admin_Custom6				// minimum admin level to grant HP add.
#define GAY_EXHP_T					50							// custom hp to add to Terror team
#define GAY_EXHP_CT					51							// custom hp to add to Counter Terror team

new bool:g_bIs_Gay[MAXPLAYERS+1]	= false;

public Plugin:myinfo =
{
    name		= "[CSGO]Gay_HP",
    author		= "GsiX is not gay",
    description	= GAY_DESCRIPTION,
    version		= GAY_VERSION,
    url			= "n/a"
};

public OnPluginStart()
{
	CreateConVar( "gay_hp_version", GAY_VERSION, GAY_DESCRIPTION, FCVAR_PLUGIN|FCVAR_DONTRECORD );
	HookEvent( "player_spawn", Event_Every_Time_Gay_Spawn );
	
	for( new i=1; i<=MaxClients; i++ )
	{
		if( IsClientConnected( i ) && IsClientInGame( i ) && !IsFakeClient( i ))
		{
			OnClientPostAdminCheck( i );
		}
	}
}

public OnClientPostAdminCheck( iClient )
{
	if( iClient > 0 )
	{
		g_bIs_Gay[iClient] = Check_Gay_Accsess( iClient );
	}
}

public Event_Every_Time_Gay_Spawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( iClient > 0 && IsClientInGame( iClient ) && g_bIs_Gay[iClient] )
	{
		new Extra_Gay = INVALID_GAY;
		switch( GetClientTeam( iClient ))
		{
			case GAY_TEAM_T: { Extra_Gay = GAY_EXHP_T; }
			case GAY_TEAM_CT: { Extra_Gay = GAY_EXHP_CT; }
		}
		
		if( Extra_Gay != INVALID_GAY )
		{
			Set_Gay_HP( iClient, ( Get_Gay_HP( iClient ) + Extra_Gay ));
		}
	}
}

Set_Gay_HP( The_Gay, HP )
{
	SetEntProp( The_Gay, Prop_Send, "m_iHealth", HP );
	SetEntProp( The_Gay, Prop_Send, "m_iMaxHealth", HP );
}

Get_Gay_HP( The_Gay )
{
	return GetEntProp( The_Gay, Prop_Send, "m_iHealth" );
}

bool:Check_Gay_Accsess( The_Gay )
{
	if ( GetAdminFlag( GetUserAdmin( The_Gay ), GAY_MIN_LEVEL )) return true;
	return false;
}

