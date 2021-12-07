/** 
* Name:
*	R E S E R V E D - T E A M S - By Team MX | MoggieX
*
* Description:
*	Stops a player going to spec unless they are root or have reserved acess
*
* Usage:
*	sm_resteams_version - 	Doh!
*	sm_resteams_enable 	- 	Default: 1 (enabled) 				- Enables the restriction of team joining, spectators by default
*	sm_resteams_team	- 	Default: 1 (spectators)				- Team to Restrict - Spectators = 1 (default), Terrorists = 2, Counter Terrorist = 3
*	sm_resteams_type		- 	Default: 1 (player count)			- Spectators swapping by: 1 = Player Count(default), 2 = Team Score
*	sm_resteams_sound 	- 	Def: buttons/weapon_cant_buy.wav	- Sound to play when player is denied access to a team
*	
* Thanks to:
* 	All tha n00blets @ http://www.UKManDown.co.uk for putting up with my testing!
*	pRED* for his help at 03:50 in the morning and the suggestion of using the timer
*	Tsunami, always extremely helpful to a wee pawn n00b
*	
* Based upon:
*	Hours of 'faffing' around and the requirement arising from our core admins to spec cheaters and give sponsors access to spectator
*  
* Version History
* 	1.0 - First Release
* 	1.5 - Added mod support outside of CS:Source by nicking pRED*'s code from super commands :)
* 	
*/
//////////////////////////////////////////////////////////////////
// Defines, Includes, Handles & Plugin Info
//////////////////////////////////////////////////////////////////
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <cstrike>

#define RS_VERSION "1.5"
#define MAX_FILE_LEN 80

#define NUMMODS 5
#define CSTRIKE 0
#define DOD 1
#define HL2MP 2
#define INS 3
#define TF 4

new String:modname[30];
new bool:cstrike;
new mod;

static String:teamname[NUMMODS][3][] =  
{
	{"All","Terrorist","Counter-Terrorist" },
	{"All","Allies","Axis" },
	{"All","Combine","Rebels" },
	{"All","US Marines","Insurgents"}, //This might be the other way around
	{"All", "Red", "Blue"}
};

new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];

new Handle:cvarRestictedTeam;
new Handle:CountOrScore;
new Handle:cvarEnable;

new bool:g_isHooked;
new bool:NeedsARespawn[MAXPLAYERS+1]; 

// Define author information
public Plugin:myinfo = 
{
	name = "Reserved Spectators",
	author = "MoggieX",
	description = "Reserved Spectators plus extras!",
	version = RS_VERSION,
	url = "http://www.UKManDown.co.uk"
};

//////////////////////////////////////////////////////////////////
// Plugin Start
//////////////////////////////////////////////////////////////////
public OnPluginStart()
{
	CreateConVar("sm_resteams_version", RS_VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	cvarEnable 		= 	CreateConVar("sm_resteams_enable","1","Enables the restriction of team joining, spectators by default",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CvarSoundName 	=	CreateConVar("sm_resteams_sound", "buttons/weapon_cant_buy.wav", "The sound to play when a player is denied access to a team");
	cvarRestictedTeam	=	CreateConVar("sm_resteams_team","1","Team to Restrict - Spectators = 1 (default), Terrorists = 2, Counter Terrorist = 3", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CountOrScore 		=	CreateConVar("sm_resteams_type","1","Spectators swapping by: 1 = Player Count(default), 2 = Team Score", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	CreateTimer(3.0, OnPluginStart_Delayed);

	GetGameFolderName(modname, sizeof(modname));

	//Get mod name stuff
	if (StrEqual(modname,"cstrike",false)) mod = CSTRIKE;
	else if (StrEqual(modname,"dod",false)) mod = DOD;
	else if (StrEqual(modname,"hl2mp",false)) mod = HL2MP;
	else if (StrEqual(modname,"Insurgency",false)) mod = INS;
	else if (StrEqual(modname,"tf",false)) mod = TF;

	cstrike = LibraryExists("cstrike");

}

//////////////////////////////////////////////////////////////////
// Caching of the Sound File(s)
//////////////////////////////////////////////////////////////////
public OnConfigsExecuted()
{
	GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
	decl String:buffer[MAX_FILE_LEN];
	PrecacheSound(g_soundName, true);
	Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
	AddFileToDownloadsTable(buffer);
}

//////////////////////////////////////////////////////////////////
// Hook Event
//////////////////////////////////////////////////////////////////
public Action:OnPluginStart_Delayed(Handle:timer){
	if(GetConVarInt(cvarEnable) > 0)
	{
		g_isHooked = true;
		HookEvent("player_team",ev_PlayerTeamSwitch);
		HookEvent("round_start",ev_RoundStart);
		HookConVarChange(cvarEnable,ResSpecCvarChange);
		
		LogMessage("[Reserved Spectators] - Loaded");
	}
}

//////////////////////////////////////////////////////////////////
// Check for changes
//////////////////////////////////////////////////////////////////
public ResSpecCvarChange(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(GetConVarInt(cvarEnable) <= 0){
		if(g_isHooked){
		g_isHooked = false;
		UnhookEvent("player_team",ev_PlayerTeamSwitch);
		UnhookEvent("round_start",ev_RoundStart);
		}
	}else if(!g_isHooked){
		g_isHooked = true;
		HookEvent("player_team",ev_PlayerTeamSwitch);
		HookEvent("round_start",ev_RoundStart);
	}
}

//////////////////////////////////////////////////////////////////
// The Do Stuff Bit - Chosen "player_team" as it appears they are assigned team 0 when they first join, so any selection makes this trigger
//////////////////////////////////////////////////////////////////
public ev_PlayerTeamSwitch(Handle:event, const String:name[], bool:dontBroadcast)
{
													// Check if enabled, if not bail out
	if (GetConVarInt(cvarEnable) == 0)
	{
		return true;
	}

	//Declare and get MINIMAL Information
	new newteam = GetEventInt(event, "team");			// New team
	new oldteam = GetEventInt(event, "oldteam");			// Old Team
	new TeamtoCheck = GetConVarInt(cvarRestictedTeam);	// Get the restricted team index
		
	// Error Checking
	//PrintToChatAll("\x04[RESPEC]\x03 1. A player swapped teams! - New Team: %i Old Team: %i, Restricted Team: %i",newteam,oldteam,TeamtoCheck);

	if (newteam == TeamtoCheck) 						// check if they have gone to spec (set by cvarRestictedTeam)
	{

													
		new client = GetClientOfUserId(GetEventInt(event,"UserId"));
		new flags = GetUserFlagBits(client);				// Get flags to check against

		// Error Checking only
		//decl String:clientname[100];					// Name to use
		//GetClientName(client,clientname,100);			// Get thier client name	

		// Error Checking
		//PrintToChatAll("\x04[RESPEC]\x03 2. Chose Spectators <%s> New Team: %i Old Team: %i, Restricted Team: %i",clientname,newteam,oldteam,TeamtoCheck);

													
		if (!IsClientInGame(client) || IsFakeClient(client))		// Make sure they are connected and not a bot
		{
			return true;
		}

		if (flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION) 
		{
			PrintToChat(client, "\x04[Reserved Teams]\x03 You have been \x04granted\x03 access to switch teams");
			return true;								// Just let them go to the new team naturally
		}
		else											// They do not have a reserved slot or are a ROOT admin
		{

			if (oldteam  != 0 && TeamtoCheck == 1)		// Check to see if they had an old team and whether its spectators that is restricted - Do not want this bit working if its CT or T
			{
				// Error Checking
				//PrintToChatAll("\x04[Reserved Teams]\x03 4. Forced back to OLD team <%s> New Team: %i Old Team: %i",clientname,newteam,oldteam);
				
				PrintToChat(client, "\x04[Reserved Teams]\x03 You have been \x04declined\x03 access to the Spectators");
				PrintToChat(client, "\x04[Reserved Spectators]\x03 Only sponsors may access the \x04Spectator Team");

				if (mod == CSTRIKE && cstrike && (oldteam == 2 || oldteam == 3))
				{
													// now if there no delay it fails, so thanksd to pRED we now have a timer here
					new Handle:pack;				
					CreateDataTimer(0.5, Timer_SwapTeam, pack);
					WritePackCell(pack, client);
					WritePackCell(pack, oldteam);
				}
				else									// Not CSS, so use ChangeClientTeam
				{
					ChangeClientTeam(client, oldteam);
				}
			
			}
			else
			{

				new TeamToGoTo = 2;					// set to Terrorist by default													

				if (GetConVarInt(CountOrScore) == 1)		// Is it Team Count or not???
				{
					new CTTeamCount = GetTeamClientCount(3)	;	
					new TTeamCount = GetTeamClientCount(2);
					
					if (CTTeamCount >= TTeamCount)		// Did it this way because CT are camping *kers
					{
						PrintToChat(client, "\x04[Reserved Teams]\x03 You have been moved to the \x04%s\x03 Team", teamname[mod][TeamToGoTo-1]);
						PrintToChat(client, "\x04[Reserved Teams]\x03 Only \x04Sponsors\x03 may access the \x04Spectator\x03 Option");
						EmitSoundToClient(client, g_soundName);

						// Error Checking
						//PrintToChatAll("\x04[Reserved Teams]\x03 5. Forced back to TERRORIST team <%s> New Team: %i Old Team: %i, TeamToGoTo: %i",clientname, newteam, oldteam, TeamToGoTo);
					}
					else
					{
						TeamToGoTo = 3;
						PrintToChat(client, "\x04[Reserved Teams]\x03 You have been moved to the \x04%s\x03 Team", teamname[mod][TeamToGoTo-1]);
						PrintToChat(client, "\x04[Reserved Teams]\x03 Only \x04Sponsors\x03 may access the \x04Spectator\x03 Option");
						EmitSoundToClient(client, g_soundName);

						// Error Checking
						//PrintToChatAll("\x04[Reserved Teams]\x03 5. Forced back to TERRORIST team <%s> New Team: %i Old Team: %i, TeamToGoTo: %i",clientname, newteam, oldteam, TeamToGoTo);
					}

				}
				else									// must be swapping based upon team scores
				{
					new CTTeamScore = GetTeamScore(3)	;	
					new TTeamScore = GetTeamScore(2);

					if (CTTeamScore >= TTeamScore)		// Did it this way because CT are camping *kers
					{
						PrintToChat(client, "\x04[Reserved Teams]\x03 You have been moved to the \x04%s\x03 Team", teamname[mod][TeamToGoTo-1]);
						PrintToChat(client, "\x04[Reserved Teams]\x03 Only \x04Sponsors\x03 may access the \x04Spectator\x03 Option");
						EmitSoundToClient(client, g_soundName);

						// Error Checking
						//PrintToChatAll("\x04[Reserved Teams]\x03 5. Forced back to TERRORIST team <%s> New Team: %i Old Team: %i, TeamToGoTo: %i",clientname, newteam, oldteam, TeamToGoTo);
					}
					else
					{
						TeamToGoTo = 3;
						PrintToChat(client, "\x04[Reserved Teams]\x03 You have been moved to the \x04%s\x03 Team", teamname[mod][TeamToGoTo-1]);
						PrintToChat(client, "\x04[Reserved Teams]\x03 Only \x04Sponsors\x03 may access the \x04Spectator\x03 Option");
						EmitSoundToClient(client, g_soundName);

						// Error Checking
						//PrintToChatAll("\x04[Reserved Teams]\x03 5. Forced back to TERRORIST team <%s> New Team: %i Old Team: %i, TeamToGoTo: %i",clientname, newteam, oldteam, TeamToGoTo);
					}		
				}

				if (mod == CSTRIKE && cstrike && (TeamToGoTo == 2 || TeamToGoTo == 3))
				{
													// now if there no delay it fails, so thanks to pRED we now have a timer here
					new Handle:pack;				
					CreateDataTimer(0.5, Timer_SwapTeam, pack);
					WritePackCell(pack, client);
					WritePackCell(pack, TeamToGoTo);
				}
				else									// Not CSS, so use ChangeClientTeam
				{
					ChangeClientTeam(client, TeamToGoTo);
				}

				return true;
			}
		}
	}
	
	return true;
}

//////////////////////////////////////////////////////////////////
// Timer_SwapTeam - Time to swap teams, has to be outside of the above function as it needs a delay (without it fails to switch the user)
//////////////////////////////////////////////////////////////////
public Action:Timer_SwapTeam(Handle:timer, Handle:pack)
{	
								// Declare some bits
	new client;
	new newteam;
								//Set to the beginning and unpack it
	ResetPack(pack);
	client = ReadPackCell(pack);
	newteam =ReadPackCell(pack);

	ForcePlayerSuicide(client);
	CS_SwitchTeam(client, newteam);

	NeedsARespawn[client] = true;	// Because they stay dead, even if the next round starts, need to check them when the next round starts
	
}

//////////////////////////////////////////////////////////////////
// ev_RoundStart - Because they stay dead, we need to respawn them on the round start
//////////////////////////////////////////////////////////////////
public ev_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{

	new maxplayers;
	maxplayers = GetMaxClients();
	
	for (new i=1; i<=maxplayers; i++)
	{
		if (!IsClientConnected(i))
		{
			continue;
		}

		if (NeedsARespawn[i] == true)
		{
			CS_RespawnPlayer(i);
			NeedsARespawn[i] = false;
		}
	}
}

//////////////////////////////////////////////////////////////////
// OnClientDisconnect - Set "NeedsARespawn"  to false to save function ev_RoundStart trying to respawn a player that has left
//////////////////////////////////////////////////////////////////
public OnClientDisconnect(client)
{
	if (NeedsARespawn[client] == true)
	{
		NeedsARespawn[client] = false;
	}
}