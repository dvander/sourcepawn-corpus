/*

list all cvar/commands
sm_cclist

cheat cvars
sm_cclist ",14.1" "]cvar"

cheat commands
sm_cclist "]command" ",14.1"

all commands/cvar that start with "mp_"
sm_cclist "[mp_"


(1<<14)
has cheat flag: ",14.1", does not have cheat flag: ",14.0"

see sourcemod/scripting/include/console.inc for more
*/
//define FCVAR_PROTECTED			(1<<5)	/**< It's a server cvar, but we don't send the data since it's a password, etc. Sends 1 if it's not bland/zero, 0 otherwise as value. */
//define	FCVAR_NOTIFY			(1<<8)	/**< Notifies players when changed. */
//define	FCVAR_USERINFO			(1<<9)	/**< Changes the client's info string. */
//define FCVAR_REPLICATED		(1<<13)	/**< Server setting enforced on clients. */
//define FCVAR_CHEAT				(1<<14)	/**< Only useable in singleplayer / debug / multiplayer & sv_cheats */
//define FCVAR_DEMO				(1<<16)	/**< Record this cvar when starting a demo file. */
//define FCVAR_DONTRECORD		(1<<17)	/**< Don't record these command in demo files. */
//define FCVAR_PLUGIN			(1<<18)	/**< Defined by a 3rd party plugin. */
//define FCVAR_NOT_CONNECTED		(1<<22)	/**< Cvar cannot be changed by a client that is connected to a server. */

#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo =
{
	name = "All Command and ConVar Lister",
	author = "Upholder of the [BFG]",
	description = "A plugin to list all cvars and commands",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	RegAdminCmd("sm_cclist", Command_Mycclist, ADMFLAG_CONVARS, "sm_cclist [search] [AND contains] [AND contains] [...]");
}

public Action:Command_Mycclist(client, args)
{
	decl Handle:iter;
	decl String:buffer[512];
	new flags, bool:isCommand;
	new count = 0;

	iter = FindFirstConCommand(buffer, sizeof(buffer), isCommand, flags);
	do
	{
		Format(buffer, sizeof(buffer), "[%s]", buffer);
		if (isCommand)
			Format(buffer, sizeof(buffer), "%scommand,", buffer);
		else
			Format(buffer, sizeof(buffer), "%scvar,", buffer);

		
		//see console.inc, search for FCVAR_UNREGISTERED
		// ,14.1, means that it has the cheat flag, ,14.0, the opposite
		new i,f;
		for(i = 0; i <= 27; i++) {
			if( flags & (1<<i) )
				f = 1;
			else
				f = 0;
			Format(buffer, sizeof(buffer), "%s%d.%d,", buffer, i, f);
		}
		
		//only display if buffer contains at least one of each arg
		new bool:display = true;
		decl String:arg[65];
		for(i = 1; i <= args; i++) {
			GetCmdArg(i, arg, sizeof(arg));
			
			if(StrContains(buffer,arg,false) == -1) {
				display = false;
				break;
			}
		}
		if(display) {
			ReplyToCommand(client, "%s", buffer);
			count += 1;
		}
	}
	while (FindNextConCommand(iter, buffer, sizeof(buffer), isCommand, flags));
	
	ReplyToCommand(client, "Total: %d", count);

	CloseHandle(iter);
	
	return Plugin_Handled;
}

