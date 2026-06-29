/*
Admin Join Notify 0.1 (Beta)
Play sound + text when admin (flags : Generic or Root) join server

If you want to remake this plugin, please add my name into credits , thanks :P and HF

Made for suggestion : http://forums.alliedmods.net/showthread.php?t=75055
*/


#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION 	"0.1"
#define SOUND		"ambient/alarms/klaxon1.wav"

/*
TO DO :

new Handle:AdminJoinEnabled = INVALID_HANDLE;
new Handle:AdminJoinSoundEnabled = INVALID_HANDLE;
new Handle:AdminJoinTextEnabled = INVALID_HANDLE;
new Handle:cvarSoundFile = INVALID_HANDLE;
*/

public Plugin:myinfo = 
{
	name = "Admin Join Notify",
	author = "HiJacker",
	description = "Play a sound on admin connect",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
CreateConVar( "sm_adminjoinnotify_version", PLUGIN_VERSION, "Admin Join Notify", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY );
}

public OnClientPostAdminCheck( client )
{
	if( IsFakeClient( client ) )
	return;

	new flags = GetUserFlagBits(client);
	if (flags & ADMFLAG_ROOT || flags & ADMFLAG_GENERIC)
	    {
      EmitSoundToAll(SOUND);
      PrintToChatAll("\x04[SM] \x03Admin has joined game");
      }
}
