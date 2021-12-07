#pragma semicolon 1

#include <sourcemod>

#define VERSION "1.0"

public Plugin:myinfo =
{
	name = "Admin List",
	author = "Samantha",
	description = "Lists all admins in a menu.",
	version = VERSION,
	url = "www.foxyden.net"
};

public OnPluginStart()
{
	RegConsoleCmd( "sm_admins", Command_Admins, "Lists all admins" );
	
	CreateConVar( "sm_adminslist_version", VERSION, "Version of admin menu.", FCVAR_NOTIFY );
}

public Action:Command_Admins( Client, Args )
{
	if( Client )
	{
		decl Handle:Menu, String:Buffer[MAX_NAME_LENGTH];
		Menu = CreateMenu( HandleAdminList );
		
		SetMenuTitle( Menu, "Admin List" );
		
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				if( CheckCommandAccess( i, "", ADMFLAG_GENERIC  ) )
				{
					Format( Buffer, sizeof(Buffer), "%N", i );
					AddMenuItem( Menu, "", Buffer );
				}
			}
		}
		
		if( GetMenuItemCount( Menu ) > 0 )
		{
			DisplayMenu( Menu, Client, 30 );
		}
		else
		{	
			AddMenuItem( Menu, "", "No admins are currently online." );
			DisplayMenu( Menu, Client, 30 );
		}
	}
	
	return Plugin_Handled;
}

public HandleAdminList(Handle:hMenu, MenuAction:HandleAction, Client, Parameter)
{
	if(HandleAction == MenuAction_End)
	{
		CloseHandle( hMenu );
	}
}
