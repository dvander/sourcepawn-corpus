#pragma		semicolon		1
//──────────────────────────────────────────────────────────────────────────────
/*
    AutoReady.sp

    Copyright 2013 Andrew V. Dromaretsky  <dromaretsky@gmail.com>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this library; if not, write to the Free Software Foundation,
    Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/
//──────────────────────────────────────────────────────────────────────────────
// Tab = 4
//──────────────────────────────────────────────────────────────────────────────
#include	<sourcemod>
#include	<sdktools>
#include	<tf2>
//──────────────────────────────────────────────────────────────────────────────
#define		PLUGIN_VER		"0.3"
#define		PLUGIN_NAME		"[TF2] Auto-ready"
#define		PLUGIN_AUTHOR	"Andrew Dromaretsky aka avi9526"
#define		PLUGIN_DESC		"If there is enough players that ready - lets go play, no more wait"
#define		PLUGIN_URL		"https://bitbucket.org/avi9526/autoready/src/"
//──────────────────────────────────────────────────────────────────────────────
// String constants
#define		STR_AUTO_CHAT	"\x01[\x07A6FF00Auto-ready\x01]"
#define		STR_AUTO_LOG	"[Auto-ready]"
//──────────────────────────────────────────────────────────────────────────────
// Global variables
//──────────────────────────────────────────────────────────────────────────────
// Global Handle Console Variable MinPlayers
new 		Handle:g_hcvMinPlayers	= INVALID_HANDLE;
// Global Handle Console Variable MinPercent
new 		Handle:g_hcvMinPercent	= INVALID_HANDLE;
// Global Integer MinPlayers
new 		g_iMinPlayers			= 3;
// Global Float MinPercent
new	Float:	g_fMinPercent			= 0.6;
// Lock - used to prevent infinite recursive call
new	bool:	Lock					= false;
//──────────────────────────────────────────────────────────────────────────────
// Service variables
//──────────────────────────────────────────────────────────────────────────────
public Plugin:myinfo =
{
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESC,
	version		= PLUGIN_VER,
	url			= PLUGIN_URL
}
//──────────────────────────────────────────────────────────────────────────────
// Hook functions
//──────────────────────────────────────────────────────────────────────────────
// Initialize required console variables, commands, etc.
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	CreateConVar("mvm_autoready_version", PLUGIN_VER, "Plugin Version", FCVAR_PLUGIN | FCVAR_NOTIFY);
	
	// Add console variable 'mvm_autoready_threshold' which is hooked to 'g_iMinPlayers'
	g_hcvMinPlayers = CreateConVar("mvm_autoready_threshold", "2", "Amount of players that must be ready to allow forced wave start", _, true, 1.0, false, 10.0);
	g_iMinPlayers = GetConVarInt(g_hcvMinPlayers);
	HookConVarChange(g_hcvMinPlayers, OnConVarChanged);
	
	// Add console variable 'mvm_autoready_percent' which is hooked to 'g_fMinPercent'
	g_hcvMinPercent = CreateConVar("mvm_autoready_percent", "0.6", "Relative amount of players that must be ready to allow forced wave start", _, true, 0.0, true, 1.0);
	g_fMinPercent = GetConVarFloat(g_hcvMinPercent);
	HookConVarChange(g_hcvMinPercent, OnConVarChanged);
	
	// Add hook to command from client to detect if he change his 'Ready' state
	// Command 'tournament_player_readystate' is autodisabled by TF2 when wave started
	// But this hook is still possible
	AddCommandListener(AutoReady, "tournament_player_readystate");
}
//──────────────────────────────────────────────────────────────────────────────
// If console variable changed - need change corresponding internal variables
public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_hcvMinPlayers)
	{
		g_iMinPlayers = StringToInt(newValue);
		LogAction(-1, -1, "%s MinPlayers now is %d", STR_AUTO_LOG, g_iMinPlayers);
	}
	if(convar == g_hcvMinPercent)
	{
		g_fMinPercent = StringToFloat(newValue);
		LogAction(-1, -1, "%s MinPercent now is %f", STR_AUTO_LOG, g_fMinPercent);
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Action functions
//──────────────────────────────────────────────────────────────────────────────
// This function decide if need to force all players (humans) to be ready
// It's called when 'tournament_player_readystate' console command executed
// and uses same command to make players ready - be sure to prevent infinite loop
// Use 'return Plugin_Continue' in this function, not 'return Plugin_Handled'
// because need forward player ready state, not block it
public Action:AutoReady(Client, const String:Command[], Argc)
{
	// Prevent recursive call
	// This function use console command which is hooked on
	if (Lock)
	{
		LogAction(-1, -1, "%s Locked", STR_AUTO_LOG);
		return Plugin_Continue;
	}
	// Logging reqired for testing
	LogAction(-1, -1, "%s Triggered 'Ready' state by '%L'", STR_AUTO_LOG, Client);
	// Con. command 'tournament_player_readystate' require one argument or will do nothing
	if(Argc != 1)
	{
		ReplyToCommand(Client, "[SM] Function '%s' require one argument", Command);
		return Plugin_Continue;
	}
	// Let's avoid processing command from unknown/bots/etc clients
	if (!IsValidClient(Client))
	{
		LogAction(-1, -1, "%s Wrong client '%L' triggered this function, do nothing", STR_AUTO_LOG, Client);
		return Plugin_Continue;
	}
	// Locking
	// Do 'Lock = false' before exit
	Lock = true;
	// Check if we play Mann vs. Machine game mode
	if (IsMvM())
	{
		// TF2 automatically disable 'tournament_player_readystate' command when wave has started
		// But let's do one more check to be sure
		// TODO: Need also to avoid after victory calls
		if (!IsWaveStarted())
		{
			// Count all humans
			new CountAll = GetRedHumanCount(false);
			// Count all humans that ready
			new CountRdy = GetRedHumanCount(true);
			
			// This required because function called before player's 'Ready' state changed ...
			new RdyNew = 0;
			new String:sRdy [4];
			GetCmdArg(1, sRdy,  sizeof(sRdy));
			RdyNew = StringToInt(sRdy);
			
			new RdyOld = IsReady(Client);
			
			// Argument from console command can be any integer number
			// we need to make it -1 for 'not ready' and 1 for 'ready'
			if (RdyNew > 0) RdyNew = 1;
			if (RdyNew < 1) RdyNew = -1;
						
			if (RdyNew != RdyOld)	// does player change his 'ready' state ?
			{
				CountRdy = CountRdy + RdyNew;	// then lets count him
			}
			// ... done
			
			// We will also check relative amount of players that is ready
			new Float:PercentRdy = 0.0;
			// Prevent division by zero
			if (CountAll > 0)
			{
				PercentRdy = FloatDiv(float(CountRdy), float(CountAll));
			}
			
			LogAction(-1, -1, "%s - We have %d players", STR_AUTO_LOG, CountAll);
			LogAction(-1, -1, "%s - %d players is ready (minimum required is %d)", STR_AUTO_LOG, CountRdy, g_iMinPlayers);
			LogAction(-1, -1, "%s - its a %.2f%% (minimum required is %.2f%%)", STR_AUTO_LOG, PercentRdy*100.0, g_fMinPercent*100.0);
			
			// If we have enough players ready (absolute and relative)
			if ((CountRdy >= g_iMinPlayers) && (PercentRdy >= g_fMinPercent))
			{
				// No need to spam and do useless code
				if (CountRdy < CountAll)
				{
					PrintToChatAll("%s Enough players is ready - let's go", STR_AUTO_CHAT);
					LogAction(-1, -1, "%s Forcing wave start", STR_AUTO_LOG, CountRdy, CountAll);
					SetAllReady();	// make all players to be ready, let's go play
					LogAction(-1, -1, "%s All players was set to be ready", STR_AUTO_LOG, CountRdy, CountAll);
				}
			}
		}
		else
		{
			LogAction(-1, -1, "%s Wave started - 'Ready' is now useless", STR_AUTO_LOG);
		}
	}
	else
	{
		LogAction(-1, -1, "%s Not MvM game mode", STR_AUTO_LOG);
	}
	Lock = false;
	return Plugin_Continue;
}
//──────────────────────────────────────────────────────────────────────────────
// Stock functions
//──────────────────────────────────────────────────────────────────────────────
// Returns amount of humans in red team at all or only which is ready
stock GetRedHumanCount(bool:OnlyReady = false)
{
	// Number of clients
	new Count = 0;
	// Go through all clients on server
	for (new Client = 1; Client <= MaxClients; Client++)
	{
		// Determine who is real player (human)
		if (IsValidClient(Client))
		{
			// Accept only red team players (blu team can't be ready)
			if (GetClientTeam(Client) == _:TFTeam_Red)
			{
				// Need count only who is ready or not
				if (OnlyReady)
				{
					Count = Count + IsReady(Client);
				}
				else
				{
					Count = Count + 1;
				}
			}
		}
	}
	return Count;
}
//──────────────────────────────────────────────────────────────────────────────
// Make all humans in red team ready
stock SetAllReady()
{
	// Go through all clients on server
	for (new Client = 1; Client <= MaxClients; Client++)
	{
		// Determine who is real player (human)
		if (IsValidClient(Client))
		{
			// Accept only red team players (blu team can't be ready)
			if (GetClientTeam(Client) == _:TFTeam_Red)
			{
				DoReady(Client);
			}
		}
	}
	return;
}
//──────────────────────────────────────────────────────────────────────────────
// Ckeck if client is normal player (human) that already in game, not bot or etc
stock IsValidClient(Client)
{
	if ((Client <= 0) || (Client > MaxClients) || (!IsClientInGame(Client)))
	{
		return false;
	}
	if (IsClientSourceTV(Client) || IsClientReplay(Client))
	{
		return false;
	}
	// Skip bots
	new String:Auth[32];	// TODO: better use 'new', but check speed
	GetClientAuthString(Client, Auth, sizeof(Auth));
	if (StrEqual(Auth, "BOT", false) || StrEqual(Auth, "STEAM_ID_PENDING", false) || StrEqual(Auth, "STEAM_ID_LAN", false))
	{
		return false;
	}
	return true;
}
//──────────────────────────────────────────────────────────────────────────────
// Return 1 is player is ready, 0 - if not
// This func. don't do any check for client to be valid
// You need to do it yourself
stock IsReady(client)
{
	new Ready = GameRules_GetProp("m_bPlayerReady", 1, client);
	return Ready;
}
//──────────────────────────────────────────────────────────────────────────────
// Make client to be ready
// Return nothing
// This func. don't do any check for client to be valid
// You need to do it yourself
stock DoReady(client)
{
	// Execute client console command on server side
	FakeClientCommand(client, "tournament_player_readystate %d", 1);
	return;
}
//──────────────────────────────────────────────────────────────────────────────
// Check if current game mode is 'Mann vs. Machine'
stock bool:IsMvM()
{
	new bool:ismvm = bool:GameRules_GetProp("m_bPlayingMannVsMachine");
	return ismvm;
}
//──────────────────────────────────────────────────────────────────────────────
// Check if wave/round started
stock bool:IsWaveStarted()
{
	new RoundState:nRoundState = GameRules_GetRoundState();
	return (!GameRules_GetProp("m_bInWaitingForPlayers", 1) && (nRoundState == RoundState_RoundRunning));
}
//──────────────────────────────────────────────────────────────────────────────
