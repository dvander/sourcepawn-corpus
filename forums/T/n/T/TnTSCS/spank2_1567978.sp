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

Admin Commands:
	sm_spank2 <user>

*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3"

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
	CreateConVar("sm_spank2_version", PLUGIN_VERSION, "SM Spank2 Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_spank2", admin_spanking, ADMFLAG_SLAY, "sm_spank2 <user>");
	
	// Needed for FindTarget
	LoadTranslations("common.phrases");
	
	HookEvent("player_death", Event_PlayerDeath);
}

public OnMapStart()
{
	PrecacheSound("sound/misc/bendover.wav", true);
	PrecacheSound("player/pl_fallpain1.wav", true);
	PrecacheSound("player/pl_fallpain3.wav", true);
	AddFileToDownloadsTable("sound/misc/bendover.wav");
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
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
	
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));	
	
	new player = FindTarget(client, arg);
	
	if(h_Spanking[player] != INVALID_HANDLE)
	{
		ReplyToCommand(client, "\x04[\x03Spank2\x04] %N is already being spanked, try again in a few seconds", player);
		return Plugin_Handled;
	}
	
	new playersconnected = GetMaxClients();
	
	for(new i = 1; i < playersconnected; i++)
	{
		// Play sound to only those player currently on Terrorst or CT team
		if(IsClientInGame(i) && GetClientTeam(i) >= 2)
			ClientCommand(i,"play misc/bendover.wav");
	}
	
	PrintToChatAll("\x03%N \x04is being bent over by \x03%N \x04for a well deserved spanking.", player, client);
	h_Spanking[player] = CreateTimer(1.5, spanking, player);
	return Plugin_Handled;
} 

public Action:spanking(Handle:timer, any:player)
{
	if(!IsClientInGame(player) || !IsPlayerAlive(player))
	{
		h_Spanking[player] = INVALID_HANDLE;
		return Plugin_Handled;
	}
	
	h_Spanking[player] = CreateTimer(0.2, slap_player, player, TIMER_REPEAT);
	return Plugin_Continue;
}

public Action:slap_player(Handle:timer, any:player)
{ 
	if (!IsClientInGame(player) || !IsPlayerAlive(player))
		return Plugin_Stop;
		
	static NumSlapped = 0;
	if(h_Spanking[player] != INVALID_HANDLE && NumSlapped++ >=8 || !IsClientInGame(player) || !IsPlayerAlive(player))
	{
		NumSlapped = 0;
		h_Spanking[player] = INVALID_HANDLE;
		return Plugin_Stop;
	}	
	SlapPlayer(player, 0, true); 
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	if(h_Spanking[client] != INVALID_HANDLE)
	{
		KillTimer(h_Spanking[client]);
		h_Spanking[client] = INVALID_HANDLE;
	}
}