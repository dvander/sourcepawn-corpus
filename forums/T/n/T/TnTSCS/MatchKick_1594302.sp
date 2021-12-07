/**

Match Kick
	DESCRIPTION:
		Will ban players if they leave while the game is live
		
	VERSION HISTORY:
		1.0.0	-	Initial code
		1.0.1	-	Fixed BanIdentiy BANFLAG error
		1.0.2	-	Changed datapack from using clientId to userId
		1.0.3	-	Added bypass for players with "allow_matchkick_bypass" or ADMFLAG_CUSTOM4.  They will not get banned
**/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sourcebans>

#define PLUGIN_VERSION "1.0.3"

new Handle:h_Trie;

new bool:BanOnDisconnect = true;
new bool:MK_Is_Enabled = false;
new bool:SB_Available = false;

new Float:BanDelay;

new BanLength;

public Plugin:myinfo = 
{
	name = "MatchKick",
	author = "TnTSCS & Impact",
	description = "Bans a player if they disconnect on a live match",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_matchkick_version", PLUGIN_VERSION, "Version of Match Kick", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	new Handle:hRandom; // KyleS hates handles	

	HookConVarChange((hRandom = CreateConVar("sm_matchkick_banondisconnect", "1", 
	"1 = Ban player if they disconnect during a live match || 2 = Ban player after sm_matchkick_bandelay seconds of disconnecting during a live match", _, true, 0.0, true, 1.0)), BanOnDisconnectChanged);
	BanOnDisconnect = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_matchkick_bandelay", "60", 
	"Number of seconds to wait for player to reconnect before banning them for leaving during a live match", _, true, 1.0, true, 180.0)), BanDelayChanged);
	BanDelay = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_matchkick_banlength", "1440", 
	"How many minutes to ban a player if they leave during a live match (1440 minutes = 24 hours = 1 day || 10080 minutes = 7 days)", _, true, 1.0, true, 10080.0)), BanLengthChanged);
	BanLength = GetConVarInt(hRandom);
	
	CloseHandle(hRandom); // KyleS hates handles
	
	RegAdminCmd("sm_matchkick", cmdMatchKick, ADMFLAG_BAN, "Will toggle the match live auto ban feature");

	HookEvent("player_disconnect", PlayerDisconnect_Event);
	
	// Execute the config file
	AutoExecConfig(true, "plugin.sm_matchkick");
	
	h_Trie = CreateTrie();
}

public BanOnDisconnectChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	BanOnDisconnect = GetConVarBool(cvar);
	
public BanDelayChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	BanDelay = GetConVarFloat(cvar);
	
public BanLengthChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	BanLength = GetConVarInt(cvar);

public OnAllPluginsLoaded()
{
	if (LibraryExists("sourcebans"))
		SB_Available = true;
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "sourcebans"))
		SB_Available = true;
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "sourcebans"))
		SB_Available = false;
}

public OnMapStart()
{
	// Clear all entries of the Trie
	ClearTrie(h_Trie);
}

public OnClientAuthorized(client, const String:auth[])
{
	// Do not process if client is a BOT
	if(!IsFakeClient(client))
	{
		new valuecheck;
		
		// Retrieve the value of the Trie, if it exists and store that value in the cash variable
		if(GetTrieValue(h_Trie, auth, valuecheck))
			RemoveFromTrie(h_Trie, auth);
	}
}

public Action:Timer_BanEnforce(Handle:timer, Handle:mypack)
{
	new valuecheck;
	
	decl String:authString[20];
	new UserID;
	ResetPack(mypack);
	UserID = ReadPackCell(mypack);
	ReadPackString(mypack, authString, 20);
	
	if(GetTrieValue(h_Trie, authString, valuecheck))
	{
		BanIdentity(authString, BanLength, BANFLAG_AUTHID, "Left during live match and didn't return", "SM");
		
		LogMessage("%s (UserID %i) was banned for leaving while match was live and they did not return in time.", authString, UserID);
		RemoveFromTrie(h_Trie, authString);
	}
}

public PlayerDisconnect_Event(Handle:event, String:name[], bool:dontBroadcast)
{
	new UserID = GetEventInt(event, "userid");
	new client = GetClientOfUserId(UserID);
	
	if(IsClientInGame(client) && !IsFakeClient(client) && MK_Is_Enabled)
	{
		if(CheckCommandAccess(client, "allow_matchkick_bypass", ADMFLAG_CUSTOM4))
			return;
			
		// Get and store the client's SteamID
		decl String:authString[20];
		GetClientAuthString(client, authString, 20);
		
		// Get and store the client's disconnect reason
		decl String:reason[64];
		GetEventString(event, "reason", reason, sizeof(reason));
		
		if(StrContains(reason, "Disconnect by user.") != -1)
		{
			if(BanOnDisconnect)
			{
				if(SB_Available)
					SBBanPlayer(0, client, BanLength, "Leaving while live");
				else if(!SB_Available)
					BanClient(client, BanLength, BANFLAG_AUTO, "Leaving while live", "You have been banned for leaving while the match was live", "SM");
				
				LogMessage("%N (UserID %i) has been banned for leaving while math is live.  DISCONNECT REASON was: %s", client, UserID, reason);
				
				return;
			}
			// Adds the clients AuthID to the trie for further processing by the timer to follow
			SetTrieValue(h_Trie, authString, 1, true);
			
			new Handle:mypack;
						
			CreateDataTimer(BanDelay, Timer_BanEnforce, mypack);
			
			WritePackCell(mypack, UserID);
			WritePackString(mypack, authString);
		}
	}	
}

public Action:cmdMatchKick(client, args)
{
	if(!MK_Is_Enabled)
	{
		MK_Is_Enabled = true;
		PrintToChatAll("\x04Match Kick is active, do not disconnect while game is -[\x03live\x04]- or you may get banned!");
		LogMessage("[MATCH KICK] Activated");
	}
	else if(MK_Is_Enabled)
	{
		MK_Is_Enabled = false;
		PrintToChatAll("\x04Match Kick is -[\x03deactivated\x04]-");
		LogMessage("[MATCH KICK] DeActivated");
	}
}