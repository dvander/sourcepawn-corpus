/*
 * =============================================================================
 * GB.CritVote, a vote to enable/disable random crits
 *
 * Done in 2011 by GB.FlyveHest
 *
 * Inspired heavily by TF2 CritVote by r5053 (http://forums.alliedmods.net/showthread.php?t=83961)
 *  and TF2 Permanent CritVote by Sillium (http://forums.alliedmods.net/showthread.php?t=130179)
 *
 * Using colors.inc by exvel (http://forums.alliedmods.net/showthread.php?t=96831)
 * =============================================================================
 */

// Semicolons are nice at EOLs :)
#pragma semicolon 1

// Defines
#define GB_CV_VERSION "1.3.5"

// Includes
#include <sourcemod>
#include <colors>

// We don't absolutely need clientprefs, we'll handle it if it isn't there
#undef REQUIRE_EXTENSIONS
#undef AUTOLOAD_EXTENSIONS
#tryinclude <clientprefs>
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS  

public Plugin:myinfo = 
{
	name 				= "GB.CritVote",
	author 			= "FlyveHest",
	description = "Enables voting to turn on or off random crits at the beginning of every round, users can set a permanent voting preference as well.",
	version 		= GB_CV_VERSION,
	url 				= "http://gaming.gladblad.dk/"
};

// Global variables
new bool:hasFirstClientConnected = false;		// Are there players on the server yet?
new bool:voteInProgress = false;						// Is the vote to determine critstatus ongoing?
new bool:clientPrefsAvailable = false;			// We assume that client prefs isn't available
new votesEnabled = 0;												// Votes for on
new votesDisabled = 0; 											// Votes for off

// Create various handles
new Handle:co_CritPreference = INVALID_HANDLE;				// Used to save an eventual persistent vote choice in a client cookie
new Handle:cv_InitialVoteDelay = INVALID_HANDLE;			// The delay, in seconds, from first client connects until the vote starts
new Handle:cv_VoteLength = INVALID_HANDLE;						// Length, in seconds, of the vote
new Handle:cv_VoteChoiceOrder = INVALID_HANDLE;				// The order of the votechoices (0 lists crits on first, 1 list crits off first)
new Handle:cv_AllowPermanentVotes = INVALID_HANDLE;		// Allows or disallows the users being able to permanently set a vote (Need clientprefs enabled on server)
new Handle:cv_PlayerJoinInfoDelay = INVALID_HANDLE;		// Time to wait, in seconds, before we inform a new player of the current crit status
new Handle:cv_VoteOnNoVote = INVALID_HANDLE;					// What should be voted, if a player doesn't vote (2 equals no preference)
new Handle:cv_ValueOnTie = INVALID_HANDLE;						// What tf_weapon_criticals will be set to in case of a tie
new Handle:cv_ResetVoteWhenEmpty = INVALID_HANDLE;		// Should the voting be reset if the server becomes empty?
new Handle:cv_SetCritsWhenEmpty = INVALID_HANDLE;			// Change the value of tf_weapon_criticals if the server becomes empty? (0/1 for value, 2 leaves as is)
new Handle:cv_ValueOnMapChange = INVALID_HANDLE;			// What tf_weapon_criticals will be set to on mapchange (2 leaves as is)
new Handle:cv_tf_weapon_criticals = INVALID_HANDLE;		// The built-in convar to en/disable random crits

// Called when plugin is loaded, initialize it
public OnPluginStart()
{
	// Check if this is TF2
	new String:gameFolder[64];
	GetGameFolderName(gameFolder, sizeof(gameFolder));
	
	if (strcmp(gameFolder, "tf", false) != 0)
	{
		// This is not TF2, print an error, and exit
		SetFailState("[GB.CritVote] This is a TF2 only plugin");
	}
	
	// Load translations
	LoadTranslations("gbcritvote.phrases");
	
	// Create our ConVars
	CreateConVar("gb_critvote_version", GB_CV_VERSION, "Enables voting on random crits.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cv_InitialVoteDelay = CreateConVar("gb_critvote_initial_vote_delay", "30", "The delay, in seconds, from first client connects until the vote starts");
	cv_VoteLength = CreateConVar("gb_critvote_vote_length", "20", "Length, in seconds, of the vote");
	cv_VoteChoiceOrder = CreateConVar("gb_critvote_vote_choice_order", "0", "The order of the votechoices (0 lists crits on first, 1 list crits off first)");
	cv_AllowPermanentVotes = CreateConVar("gb_critvote_allow_permanent_votes", "1", "Allows or disallows the users being able to permanently set a vote (Need clientprefs enabled on server))");
	cv_PlayerJoinInfoDelay = CreateConVar("gb_critvote_player_join_info_delay", "20", "Time to wait, in seconds, before we inform a new player of the current crit status");
	cv_VoteOnNoVote = CreateConVar("gb_critvote_vote_on_no_vote", "2", "What should be voted, if a player doesn't vote (2 equals no preference)");
	cv_ValueOnTie = CreateConVar("gb_critvote_value_on_tie", "1", "What tf_weapon_criticals will be set to in case of a tie");
	cv_ResetVoteWhenEmpty = CreateConVar("gb_critvote_reset_vote_when_empty", "1", "Should the voting be reset if the server becomes empty?");
	cv_SetCritsWhenEmpty = CreateConVar("gb_critvote_set_crits_when_empty", "2", "Change the value of tf_weapon_criticals if the server becomes empty? (0/1 for value, 2 leaves as is)");
	cv_ValueOnMapChange = CreateConVar("gb_critvote_value_on_mapchange", "2", "What tf_weapon_criticals will be set to on mapchange (2 leaves it as is)");

	// Create/Load a config file
	AutoExecConfig(true, "gb_critvote");

	// Retrieve the native ConVar
	cv_tf_weapon_criticals = FindConVar("tf_weapon_criticals");

	// Create sm_crit, as this is always available
	RegConsoleCmd("sm_crit", CritStatus);		// Show current critstatus	
}

// So we are able to check if permanent votes should be allowed
public OnConfigsExecuted()
{
	// Test for availability of client preferences
	if (GetExtensionFileStatus("clientprefs.ext") == 1)
	{
		// They are, does the admin want to allow permanent votes?
		if(GetConVarBool(cv_AllowPermanentVotes))
		{
			// Client prefs are available
			clientPrefsAvailable = true;
	
			// Register our cookie
			co_CritPreference = RegClientCookie("gb_critvote_preference", "The players crit vote preference", CookieAccess_Public);	

			// Create our console command to delete permanent votes
			RegConsoleCmd("sm_deletecrit", DeleteCritVote); // Deletes the clients critvote preference
		}
		else
		{
			// Client prefs are available, but admin has disabled permanent votes (We use the same bool for this)
			clientPrefsAvailable = false;
		}
	}
}

// When a map loads
public OnMapStart()
{
	// No players are connected at this time
	hasFirstClientConnected = false;
	
	// Check if we should reset tf_criticals to anything, only do anything if its set to a valid value
	switch (GetConVarInt(cv_ValueOnMapChange))
	{
		case 0:
		{
			// Disable crits
			SetConVarInt(cv_tf_weapon_criticals, 0);	
		}
		case 1:
		{
			// Enable crits
			SetConVarInt(cv_tf_weapon_criticals, 1);
		}
		case 2:
		{
			// Do nothing
		}
		default:
		{
			// Print an error to console
			PrintToServer("[GB.CritVote] cv_ValueOnMapChange set to an invalid value");
		}
	}
}

// Called when a client is fully authorized and in game
public OnClientPostAdminCheck(client)
{
	// Lets see if this is the first client on the map, and, not a bot (Replay/SrcTV)
	if (!hasFirstClientConnected && !IsFakeClient(client))
	{
		// First client on the map		
		hasFirstClientConnected = true;
		
		// Set voting in progress, this is cheating a little, as the actual vote does not start until cv_InitialVoteDelay has passed,
		//   but its so we don't send info about crit status before its been decided.
		voteInProgress = true;

		// Initiate vote-timer countdown (Default, 20 seconds)
		CreateTimer(GetConVarFloat(cv_InitialVoteDelay), StartCritVote);
	}
	else if (!voteInProgress)
	{
		// Vote is not in progress, setup a timer to inform the new player of the crit status on the server
		CreateTimer(GetConVarFloat(cv_PlayerJoinInfoDelay), InformPlayerCritStatus, GetClientSerial(client));
	}
}

// Called when a client disconnects, we check if its the last one on
public OnClientDisconnect_Post(client)
{
	if (GetClientCount() == 0)
	{
		// No more players online
	
		// Check if vote should be reset
		if (GetConVarInt(cv_ResetVoteWhenEmpty) == 1)
		{
			// Reset the vote
			hasFirstClientConnected = false;
		}

		// Check if the value of tf_weapon_criticals should be changed (2 leaves as is, invalid value does nothing)
		switch (GetConVarInt(cv_SetCritsWhenEmpty))
		{
			case 0:
			{
				// Disable crits
				SetConVarInt(cv_tf_weapon_criticals, 0);	
			}
			case 1:
			{
				// Enable crits
				SetConVarInt(cv_tf_weapon_criticals, 1);
			}
			case 2:
			{
				// Do nothing
			}
			default:
			{
				// Print an error to console
				PrintToServer("cv_SetCritsWhenEmpty set to an invalid value");
			}
		}
	}
}

// Informs a player of the current crit state
public Action:InformPlayerCritStatus(Handle:timer, any:clientSerial)
{
	// Lets get the client ID from the serial
	new client = GetClientFromSerial(clientSerial);
	
	// Check that the the player is still connected
	if (client > 0 && IsClientInGame(client) && IsClientConnected(client))
	{
		// Send the current crit status to the client, if we can get the convar
		if(GetConVarBool(cv_tf_weapon_criticals))
		{
			// Crits are enabled
			CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "InformPlayerRandomCritsEnabled");
		}
		else
		{
			// Crits are disabled
			CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "InformPlayerRandomCritsDisabled");
		}
	}
}

// Start the crit vote, messaging all the players currently on the server
public Action:StartCritVote(Handle:timer)
{
	// Initialize vote results
	votesEnabled = 0;
	votesDisabled = 0;
	
 	// Loop all connected clients, and decide if they should see the votepanel or not
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
		{	
			// Initialize vote preference
			new votePreference = 0;
			
			// Only check cookies, if clientprefs are available
			if (clientPrefsAvailable)
			{	
				// Check if cookies are loaded
				if (AreClientCookiesCached(client))
				{
					// Check if the player has a cookie set
					decl String:rawVotePreference[2];
					GetClientCookie(client, co_CritPreference, rawVotePreference, sizeof(rawVotePreference));
					votePreference = StringToInt(rawVotePreference);
				}
			}
			
			// Check vote preference
			switch (votePreference)
			{
				case 4:
				{
					// On vote
					votesEnabled++;
					
					// Inform client of his/her vote preference
					CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "AutoVotedOn");
					CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "HowToRemoveVotePref");
				}
				case 5:
				{
					// Off vote
					votesDisabled++;
		
					// Inform client of his/her vote preference
					CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "AutoVotedOff");
					CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "HowToRemoveVotePref");
				}
				case 6:
				{
					// Inform client of his/her vote preference
					CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "AutoVotedNoPref");
					CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "HowToRemoveVotePref");
				}
				default:
				{
					// Declare our translation string
					decl String:translated[255];
					
					// Create our panel, we create it here so we can translate it to the given client
					new Handle:panel = CreatePanel();
					
					Format(translated, sizeof(translated), "%T", "MenuHeader", client);
					SetPanelTitle(panel, translated);
					
					Format(translated, sizeof(translated), "%T", (GetConVarInt(cv_VoteChoiceOrder) == 0 ? "MenuVoteEnabled" : "MenuVoteDisabled"), client);
					DrawPanelItem(panel, translated);
					
					Format(translated, sizeof(translated), "%T", (GetConVarInt(cv_VoteChoiceOrder) == 0 ? "MenuVoteDisabled" : "MenuVoteEnabled"), client);
					DrawPanelItem(panel, translated);

					Format(translated, sizeof(translated), "%T", "MenuVoteNoPreference", client);
					DrawPanelItem(panel, translated);

					// Only show permanent vote-choices if clientprefs are available
					if (clientPrefsAvailable)
					{
						// Divider, below it are the always votes
						DrawPanelText(panel, "---");
	
						Format(translated, sizeof(translated), "%T", (GetConVarInt(cv_VoteChoiceOrder) == 0 ? "MenuAlwaysVoteEnabled" : "MenuAlwaysVoteDisabled"), client);
						DrawPanelItem(panel, translated);
	
						Format(translated, sizeof(translated), "%T", (GetConVarInt(cv_VoteChoiceOrder) == 0 ? "MenuAlwaysVoteDisabled" : "MenuAlwaysVoteEnabled"), client);
						DrawPanelItem(panel, translated);
	
						Format(translated, sizeof(translated), "%T", "MenuAlwaysVoteNoPreference", client);
						DrawPanelItem(panel, translated);
					}
 					
					// Send the vote panel to the client
					SendPanelToClient(panel, client, CritVotePanelHandler, GetConVarInt(cv_VoteLength));

					// Close our panel, its been sent to the client
					CloseHandle(panel);
				}
			}
		}
	}
	
	// Start timer to tally vote, 2 second longer than vote length
	CreateTimer(GetConVarFloat(cv_VoteLength) + 2.0, TallyCritVote);
}

// Handles entry from our vote panel
public CritVotePanelHandler(Handle:menu, MenuAction:action, voteClient, voteValue)
{
	if (action == MenuAction_Select)
	{
		// Check if VoteChoiceOrder is reversed, then we simply reverse the values here
		if (GetConVarInt(cv_VoteChoiceOrder) == 1)
		{
			// Vote order is reversed, change 1 to 2, 4 to 5 and vice versa
			if (voteValue == 1)
			{
				// On is off, when order is reversed
				voteValue = 2;
			}
			else if (voteValue == 2)
			{
				// Off is on, when order is reversed
				voteValue = 1;
			}
			else if (voteValue == 4)
			{
				// An always on is an always off, when order is reversed
				voteValue = 5;
			}
			else if (voteValue == 5)
			{
				// An always off is an always on, when order is reversed
				voteValue = 4;
			}
		}

		// Convert integer to string, if we need to save it later
		decl String:stringVoteValue[2];
		IntToString(voteValue, stringVoteValue, sizeof(stringVoteValue));
		
		// Check vote type, we only handle on/off and always on/off/no pref votes
		switch (voteValue)
		{
	    case 1:
	    {
	    	// On
	    	votesEnabled++;
	    	
	    	// Inform client of his/her vote
	    	CPrintToChat(voteClient, "[{olive}GB.CritVote{default}] %t", "VotedOn");
	    }
	    case 2:
	    {
	    	// Off
	    	votesDisabled++;

	    	// Inform client of his/her vote
	    	CPrintToChat(voteClient, "[{olive}GB.CritVote{default}] %t", "VotedOff");
	    }
	    case 3:
	    {
	    	// Inform client of his/her vote
				CPrintToChat(voteClient, "[{olive}GB.CritVote{default}] %t", "VotedNoPref");
	    }
	    case 4:
	    {
				// Always on
				votesEnabled++;
				
				// Save cookie
				SetClientCookie(voteClient, co_CritPreference, stringVoteValue);
				
				// Inform client of his/her vote
				CPrintToChat(voteClient, "[{olive}GB.CritVote{default}] %t", "SetVotePrefOn");
				CPrintToChat(voteClient, "[{olive}GB.CritVote{default}] %t", "HowToRemoveVotePref");
	    }
	    case 5:
	    {
				// Always off
				votesDisabled++;
				
				// Save cookie
				SetClientCookie(voteClient, co_CritPreference, stringVoteValue);
				
				// Inform client of his/her vote
				CPrintToChat(voteClient, "[{olive}GB.CritVote{default}] %t", "SetVotePrefOff");
				CPrintToChat(voteClient, "[{olive}GB.CritVote{default}] %t", "HowToRemoveVotePref");
	    }
	    case 6:
	    {
				// Always no preference, save cookie
				SetClientCookie(voteClient, co_CritPreference, stringVoteValue);
				
				// Inform client of his/her vote
				CPrintToChat(voteClient, "[{olive}GB.CritVote{default}] %t", "SetVotePrefNoPref");
				CPrintToChat(voteClient, "[{olive}GB.CritVote{default}] %t", "HowToRemoveVotePref");
	    }
		}
	}
	else if (action == MenuAction_Cancel)
	{
		// Client did not select anything, lets see what we should do, if anything
		switch (GetConVarInt(cv_VoteOnNoVote))
		{
			case 0:
			{
				// Vote counts as a vote for off
				votesDisabled++;
			}
			case 1:
			{
				// Vote counts as a vote for on
				votesEnabled++;
			}
		}
		
		// Inform client that he/she did not vote
		if (IsClientInGame(voteClient) && IsClientConnected(voteClient))
		{
			CPrintToChat(voteClient, "[{olive}GB.CritVote{default}] %t", "DidNotVote");
		}
	}
}

// Lets tally the votes, and decide what the setting should be
public Action:TallyCritVote(Handle:timer)
{
	// Print to server log
	PrintToServer("[GB.CritVote] CritVote over, %d voted for, %d voted against.", votesEnabled, votesDisabled);	
	
	// Determine what tf_weapon_criticals should be set to
	if (votesEnabled > votesDisabled)
	{
		// Crits are on, set ConVar		
		SetConVarInt(cv_tf_weapon_criticals, 1);
	}
	else if (votesDisabled > votesEnabled)
	{
		// Crits are off, set ConVar
		SetConVarInt(cv_tf_weapon_criticals, 0);
	}
	else
	{
		// Its a tie, use ValueOnTie convar
		SetConVarInt(cv_tf_weapon_criticals, GetConVarInt(cv_ValueOnTie));
	}

	// Inform the server of the voteresult
	if(GetConVarBool(cv_tf_weapon_criticals))
	{
		CPrintToChatAll("[{olive}GB.CritVote{default}] %t", "InformPlayerRandomCritsEnabled");
	}
	else
	{
		CPrintToChatAll("[{olive}GB.CritVote{default}] %t", "InformPlayerRandomCritsDisabled");
	}
	
	// End the vote
	voteInProgress = false;	
}

// Inform client (or server) about the current random crit status
public Action:CritStatus(client, args)
{
	// Check if the command is called from client or server
	if (client)
	{
		// Check that voting has finished
		if (voteInProgress)
		{
			// Voting is in progress, inform the client
			CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "VoteUndecided");
		}
		else
		{
			// Check crit state and inform player
			if(GetConVarBool(cv_tf_weapon_criticals))
			{
				// Crits are enabled
				CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "InformPlayerRandomCritsEnabled");
			}
			else
			{
				// Crits are disabled
				CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "InformPlayerRandomCritsDisabled");
			}

			// Only check permanent votes, if clientprefs are available
			if (clientPrefsAvailable)
			{
				// Check for vote preference, and also inform client of this
				new votePreference = 0;
					
				// Check if cookies are loaded
				if (AreClientCookiesCached(client))
				{
					// Check if the player has a cookie set
					decl String:rawVotePreference[2];
					GetClientCookie(client, co_CritPreference, rawVotePreference, sizeof(rawVotePreference));
					votePreference = StringToInt(rawVotePreference);
				}
				
				// Inform client, if he has a cookie set
				switch (votePreference)
				{
			    case 4:
			    {
						// Inform client of his/her preference and how to delete it
						CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "VotePrefOn");
						CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "HowToRemoveVotePref");
			    }
			    case 5:
			    {
						// Inform client of his/her preference and how to delete it
						CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "VotePrefOff");
						CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "HowToRemoveVotePref");
			    }
			    case 6:
			    {
						// Inform client of his/her preference and how to delete it
						CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "VotePrefNoPref");
						CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "HowToRemoveVotePref");
			    }
				}
			}
		}		
	}
	else
	{
		// Show the current status of the CritVote on the server console
		if (voteInProgress)
		{
			// Vote is in progress
			PrintToServer("The critvote hasn't been decided yet");
		}
		else
		{
			// Vote has been decided
			if(GetConVarBool(cv_tf_weapon_criticals))
			{
				// Crits are enabled
				PrintToServer("Random crits are enabled");
			}
			else
			{
				// Crits are disabled
				PrintToServer("Random crits are disabled");
			}			
		}	
	}
	
	// And we're done		
	return Plugin_Handled;	
}

// Deletes a critvote preference, if its been set
public Action:DeleteCritVote(client, args)
{
	// Check if the command has been issued by a client
	if (client)
	{
		// Initialize vote preference
		new votePreference = 0;
			
		// Check if cookies are loaded
		if (AreClientCookiesCached(client))
		{
			// Check if the player has a cookie set
			decl String:rawVotePreference[2];
			GetClientCookie(client, co_CritPreference, rawVotePreference, sizeof(rawVotePreference));
			votePreference = StringToInt(rawVotePreference);
		}
			
		// Check if he/she has set a preference
		if (votePreference == 0)
		{
			// No preference has been set, inform the client
			CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "VotePrefNotSet");
		}
		else
		{
			// A preference has been set, remove it
			SetClientCookie(client, co_CritPreference, "");
			
			// Inform the client
			CPrintToChat(client, "[{olive}GB.CritVote{default}] %t", "VotePrefDeleted");
		}		
	}
	
	// And we're done		
	return Plugin_Handled;		
}