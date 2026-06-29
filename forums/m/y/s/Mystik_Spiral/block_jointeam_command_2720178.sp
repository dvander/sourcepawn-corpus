/*======================================================================================
	Plugin Info:

	Block "jointeam" command by Mystik Spiral

	Useful to prevent L4D2 Co-Op players from doing things like...

		jointeam 1
		jointeam 2 zoey;respawn

	...which adds another bot.  This plugin should work with any
	Source game, but is probably most useful for L4D2 Co-Op mode.
========================================================================================

	Change Log:

1.0 (04-Oct-2020)
	- Initial release.

1.1 (19-Oct-2020)
	- Changed to use new SourcePawn syntax.

1.2 (02-Nov-2020)
	- Exempt admins with new cvar: block_jointeam_command_admflags.

======================================================================================*/

#define PLUGIN_VERSION	"1.2"
#define CVAR_FLAGS FCVAR_NOTIFY

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

	ConVar g_hCvarAdmFlags;

public Plugin myinfo =
{
	name = "[L4D2] Block jointeam Command",
	author = "Mystik Spiral",
	description = "Blocks use of the jointeam command in client console",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=327694"
}

public void OnPluginStart()
{
	AddCommandListener(ChangeTeam, "jointeam");
	g_hCvarAdmFlags = CreateConVar(	"block_jointeam_command_admflags", "z", "Players with one of these admin flags can use the jointeam command, all others blocked.", CVAR_FLAGS );
	AutoExecConfig(true, "block_jointeam_command");
}

public Action ChangeTeam(int client, const char[] command, int args)
{
	// Check Admin Flags
	bool bAllowJTC;
	int iAdmFlags;
	static char sTemp[32];
	g_hCvarAdmFlags.GetString(sTemp, sizeof(sTemp));

	if( sTemp[0] == 0 )
		bAllowJTC = true;
	else
	{
		char sVal[2];
		for( int i = 0; i < strlen(sTemp); i++ )
		{
			sVal[0] = sTemp[i];
			iAdmFlags = ReadFlagString(sVal);

			if( CheckCommandAccess(client, "", iAdmFlags, true) == true )
			{
				bAllowJTC = true;
				break;
			}
		}
	}

	if( bAllowJTC == false )
	{
		PrintToServer("%L attempted jointeam command but was blocked.", client);
		return Plugin_Stop;
	}
	else
		return Plugin_Continue;
}