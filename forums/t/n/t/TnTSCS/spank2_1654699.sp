/*
Spank2
Hell Phoenix
http://www.charliemaurice.com/plugins

Description:
	Plays a sound "Okay, Bendover", and tells everyone that the admin 
	is spanking the player ... 8 spanks causing no damage.

Thanks To:
	Denkkar Seffyd for the amxx original =D
	
Notes:
	Add bendover.wav to sound/misc/
	Requires at least revision 1175 of SourceMod
	
Versions:
	1.0
		* First Public Release!
	1.1
		* Fixed it spanking yourself...whoops =D
	1.2
		* Targeting is fixed for good hopefully
		
	1.3
		* Fixed targeting for if a client leaves
		* Added translation file needed for FindTarget
		* Removed unneeded clientname and playername strings and replaced with %N in PrintToChatAll
		* Adjusted to only play sound to those players currently on Terrorist or CT team (spectators will not hear the sound)
		* Removed the creation of 8 timers and implemented a repeating timer that stops once 8 slaps is achieved and implemented a Handle for the timer
	
	1.4
		* Fixed error with target
		* Fixed error with Precache, now sound will work correctly.
		* Changed from client command to playing sound to using Emit sound (plays sound to player and nearby players will also hear the sound)
		- Removed the precache of the fallpain wav files (not needed, I think...)

Admin Commands:

	From Console:
	sm_spank2 <user>

	From Chat:
	/sm_spank2 <user>
	/spank2 <user>
	!sm_spank2 <user>
	!spank2 <user>

*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"
#define SOUND_FILE "misc/bendover.wav"

new Handle:h_Spanking[MAXPLAYERS+1] = INVALID_HANDLE;

// Plugin definitions
public Plugin:myinfo = 
{
	name = "sm_spank2",
	author = "Hell Phoenix, added to by TnTSCS",
	description = "Spank players with no damage",
	version = PLUGIN_VERSION,
	url = "http://www.charliemaurice.com/plugins/"
}

public OnPluginStart()
{
	CreateConVar("sm_spank2_version", PLUGIN_VERSION, "SM Spank2 Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	RegAdminCmd("sm_spank2", admin_spanking, ADMFLAG_SLAY, "sm_spank2 <user>");
	
	// Needed for FindTarget
	LoadTranslations("common.phrases");
	
	HookEvent("player_death", Event_PlayerDeath);
}

public OnMapStart()
{
	PrecacheSound(SOUND_FILE, true);
	
	AddFileToDownloadsTable("sound/misc/bendover.wav");
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// If a player is getting slapped and gets killed, kill the slapping and timer.
	if(h_Spanking[client] != INVALID_HANDLE)
	{
		KillTimer(h_Spanking[client]);
		h_Spanking[client] = INVALID_HANDLE;
	}
}

public Action:admin_spanking(client, args)
{ 
	if(args < 1)
	{
		ReplyToCommand(client, "\x04[\x03Spank2\x04] Usage: sm_spank2 <Player/Partial Name>");
		return Plugin_Handled;
	}
	
	decl String:arg[MAX_NAME_LENGTH];
	arg[0] = '\0';
	decl player;
	
	GetCmdArg(1, arg, sizeof(arg));	
	
	// If unable to target the player (or unsupported group such as @t or @ct or @humans or @all), stop processing
	if((player = FindTarget(client, arg)) <= 0)
	{
		return Plugin_Handled;
	}
	
	// Let the client know the player is currently being spanked
	if(h_Spanking[player] != INVALID_HANDLE)
	{
		ReplyToCommand(client, "\x04[\x03Spank2\x04] %N is already being spanked, try again in a few seconds", player);
		return Plugin_Handled;
	}
	
	// Store the vector of the players eye position to play the sound from
	new Float:vec[3];
	GetClientEyePosition(player, vec);
	
	// Emit the sound to player (nearby players will hear the bendover sound too)
	EmitAmbientSound(SOUND_FILE, vec, player, SNDLEVEL_RAIDSIREN);
	
	// Advertise that the player is being slapped 
	PrintToChatAll("\x03%N \x04is being bent over by \x03%N \x04for a well deserved spanking.", player, client);
	
	h_Spanking[player] = CreateTimer(1.5, spanking, player); // Allow 1.5 seconds for the bendover sound to play
	
	return Plugin_Handled;
} 

public Action:spanking(Handle:timer, any:player)
{
	// Kill timer if player disconnects or dies
	if(!IsClientInGame(player) || !IsPlayerAlive(player))
	{
		h_Spanking[player] = INVALID_HANDLE;
		return Plugin_Handled;
	}
	
	// Create the repeating timer to slap the player over and over (8 times)
	h_Spanking[player] = CreateTimer(0.2, slap_player, player, TIMER_REPEAT);
	
	return Plugin_Continue;
}

public Action:slap_player(Handle:timer, any:player)
{
	// Kill the timer if the player disconnects or dies
	if (!IsClientInGame(player) || !IsPlayerAlive(player))
		return Plugin_Stop;
		
	static NumSlapped = 0;
	
	// Once the number of slaps reaches 8, stop slapping the player (also if the player disconnects or dies)
	if(h_Spanking[player] != INVALID_HANDLE && NumSlapped++ >=8 || !IsClientInGame(player) || !IsPlayerAlive(player))
	{
		NumSlapped = 0;
		h_Spanking[player] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	// Slap the player with 0 damage and play the associated sound (fallpain wav files)
	SlapPlayer(player, 0, true);
	
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		if(h_Spanking[client] != INVALID_HANDLE)
		{
			KillTimer(h_Spanking[client]);
			h_Spanking[client] = INVALID_HANDLE;
		}
	}
}