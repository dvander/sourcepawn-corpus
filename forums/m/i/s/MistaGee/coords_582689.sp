#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "coords",
	author = "MistaGee",
	description = "Shows your coords",
	version = "1.0.0",
	url = "http://www.sourcemod.net"
};

public OnPluginStart(){
	RegAdminCmd( "coords",		Command_Coords,		0 );
	RegAdminCmd( "teleport",	Command_Teleport,	ADMFLAG_CHEATS );
	}

public Action:Command_Coords( client, args ){
	new Float:pos[3];
	GetClientEyePosition( client, pos );
	ReplyToCommand( client, "[SM] You're eye position is %f %f %f.", pos[0], pos[1], pos[2] );
	return Plugin_Handled;
	}

public Action:Command_Teleport( client, args ){
	if( args != 3 ){
		ReplyToCommand( client, "[SM] Usage: sm_teleport <x> <y> <z> -- Teleport you." );
		return Plugin_Handled;
		}
	new String:arg[10],
	    Float:pos[3];
	
	for( new i = 0; i < 3; i++ ){
		GetCmdArg( i+1, arg, sizeof(arg) );
		pos[i] = StringToFloat( arg );
		}
	
	TeleportEntity( client, pos, NULL_VECTOR, NULL_VECTOR );
	ReplyToCommand( client, "[SM] Teleported you to %f %f %f.", pos[0], pos[1], pos[2] );
	return Plugin_Handled;
	}
