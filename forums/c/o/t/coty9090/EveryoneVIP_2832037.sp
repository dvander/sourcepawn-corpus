#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <admin>

#define ADMIN_GROUP_NAME "Default"

public Plugin myinfo =
{
	name        = "Everyone Is VIP",
	author      = "DontRushB",
	description = "Gives everyone default VIP access",
	version     = "1.0",
	url         = "https://redd.it/vp37bx",
};

AdminId aid;

public void OnConfigsExecuted()
{
    Init();
    PrintToServer( "[EveryoneIsVIP] Ready" );
}

public void OnClientPostAdminCheck( int client )
{
    if( IsFakeClient( client ) )
        return;

    if( GetUserAdmin( client ) == INVALID_ADMIN_ID )
    {
        PrintToServer( "[EveryoneIsVIP] Giving %L default access", client );
        SetUserAdmin( client, aid, false );
    }
}

public void OnRebuildAdminCache( AdminCachePart part )
{
    if( part == AdminCache_Admins )
    {
        Init();

        for( int i = 1; i <= MaxClients; i++ )
        {
            if( !IsClientInGame( i ) || IsFakeClient( i ) )
                continue;

            if( GetUserAdmin( i ) == INVALID_ADMIN_ID )
                SetUserAdmin( i, aid, false );
        }
    }
}

void Init()
{
    aid = CreateAdmin( "" );
    if( aid == INVALID_ADMIN_ID )
        SetFailState( "Could not create temporary admin entry" );

    GroupId gid = FindAdmGroup( ADMIN_GROUP_NAME );
    if( gid == INVALID_GROUP_ID )
        SetFailState( "Could not find existing admin group \"%s\"", ADMIN_GROUP_NAME );

    AdminInheritGroup( aid, gid );
}