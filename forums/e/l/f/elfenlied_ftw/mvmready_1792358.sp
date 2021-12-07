// written using "UEStudio '12 Development Environment" editor
// credits: "Afro Priest" - making me write the plugin to begin with
//        - "Dr. McKay" & "ReFlexPoison" - For info on FakeClientCommand() vs ClientCommand()
//        - "Dr. McKay" - For ReplyToTargetError() alternative for error/failure report, and command filtering info
// date: sept. 5 2012, updated 9/6/2012
// tested with: sourcemod v1.4.5-dev, metamod version 1.8.7
// game(s): TF2
// notes: This is my first plugin, so please forgive any stupid methods and mistakes.
//      - elf_* is short for elfenlied :-)
// TODOs: n/a
#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VER "1.3"


public Plugin:myinfo =
{
	name = "[TF2] MvM Player Ready",
	author = "elfenlied ftw! (otaku mode)",
	description = "Allows admins to toggle a players ready state (F4) in MvM.",
	version = PLUGIN_VER,
	url = "n/a"
}


public OnPluginStart()
{
	// - init -
	LoadTranslations( "common.phrases" );
	
	
	
	
	// - cvars -
	CreateConVar( "mvmready_version", PLUGIN_VER, "Plugin Version", FCVAR_PLUGIN | FCVAR_NOTIFY );
	
	// - cmds -
	RegAdminCmd(	"sm_mvmready",  	elf_SetReady,			ADMFLAG_GENERIC,	"Sets a clients ready state."	);
	RegAdminCmd(	"sm_ready",  			elf_SetReady,			ADMFLAG_GENERIC,	"Sets a clients ready state."	); // request from "Vastrix"
}


// command :: sm_mvmready
// descr   :: Sets a clients ready state by <faking> a client command.
public Action:elf_SetReady( client, args )
{
	// grab the command for printing (2 commands access this func).. this is to avoid any confusion to users
	decl String:cmd[20];
	GetCmdArg( 0, cmd, sizeof( cmd ) );
	
	
	// - argcheck
	if( args < 2 )
	{
		PrintToChat( client, "\x04[SM]\x01 Usage: %s <#userid|name> <1=ready, 0=not>", cmd );
		return Plugin_Handled;
	}
	
	
	
	// - grab args
	decl String:targ[40];
	GetCmdArg( 1, targ, sizeof( targ ) ); // 1 - userid|name
	
	decl String:val [5];
	GetCmdArg( 2, val,  sizeof( val  ) ); // 2 - b:state
	new bool:cstate = bool:StringToInt( val );
	
	
	
	// - grab the target(s)
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:ml;
	target_count = ProcessTargetString(
		targ,
		client,
		target_list,
		MAXPLAYERS,
		0,
		target_name,
		sizeof( target_name ),
		ml
	);
	
	
	// - validate
	if( target_count <= 0 )
		ReplyToTargetError( client, target_count );

	// - execute the command on the client(s)
	else for( new i = 0; i < target_count; ++i )
		FakeClientCommand( target_list[i], "tournament_player_readystate %d", cstate );
	
	
	// - report the command
	// note - this will show failed attempts as well
	ShowActivity2( client, "[SM] ", "set ready status '%d' on %s", cstate, target_name );
	
	
	return Plugin_Handled;
}




// EOF