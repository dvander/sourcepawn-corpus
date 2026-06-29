/**
Plugin Requested by Mistery (profile-http://forums.alliedmods.net/member.php?u=160070) 
REQ URL - http://forums.alliedmods.net/showthread.php?t=171454

Public release plugin name changed from matchban to MatchBan

Match Ban (previously Match Kick)
	DESCRIPTION:
		Will ban players if they leave while the game/match is live
			* This plugin works with Sourcebans as it uses the sm_addban command
		
	VERSION HISTORY:
		1.0.0	-	Initial code
		1.0.1	-	Fixed BanIdentiy BANFLAG error
		1.0.2	-	Changed datapack from using clientId to userId
		1.0.3	-	Added bypass for players with "allow_matchban_bypass" or ADMFLAG_CUSTOM4.  They will not get banned
		1.0.4	-	Fixed delayed ban to work with Sourcebans
		1.0.5	-	Removed the include for sourcebans and using the sm_addban server command instead
		1.0.6	-	Cleaned up the method of banning to reduce redundant code
		1.0.7	-	Added an argument for the sm_matchban command so it's easier to use in config files 
				-	sm_matchban 1 = On
				-	sm_matchban 0 = Off
		1.0.8	-	Fixed "Native "IsClientInGame" reported: Client index 0 is invalid" error
		1.0.9	-	Re-Added include for sourcebans for if BanOnDisconnect then use the SBBanPlayer
		1.1.0	-	Initial Public Release
				-	Also added Updater functionality for automatic updates
				-	Renamed from matchban to MatchBan
		
		1.1.1	-	Moved sourcebans from required to optional
		
		1.1.2	-	Fixed incorrect Bool to Int
		
		1.1.3	-	Added debug feature
			-	Added ability to modify the disconnect reason to look for - defaulted to the CS:S reason
		
	TO DO LIST:
		*	Add translation capability
		*	[DONE v1.1.0] - Add Updater for automatic updates to this plugin
**/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <sourcebans>
#include <updater>

#define UPDATE_URL "http://dl.dropbox.com/u/3266762/MatchBan.txt"

#define PLUGIN_VERSION "1.1.3"
#define PLUGIN_PREFIX "\x04[\x03Match Ban\x04]\x01"

#define MAX_MESSAGE_LENGTH 250

new Handle:h_Trie;

new bool:IsSBAvailable = false;
new BanOnDisconnect = true;
new bool:MB_Is_Enabled = false;

new Float:BanDelay;

new BanLength;

new String:dmsg[MAX_MESSAGE_LENGTH];
new bool:UseDebug;

new String:DisconnectString[50];

public Plugin:myinfo = 
{
	name = "Match Ban",
	author = "TnTSCS aka ClarkKent",
	description = "Bans a player if they disconnect on a live match",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_matchban_version", PLUGIN_VERSION, "Version of Match Ban", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("sm_matchban_version_build", SOURCEMOD_VERSION, "The version of SourceMod that 'Match Ban' was compiled with.", FCVAR_PLUGIN);
	
	new Handle:hRandom; // KyleS hates handles	

	HookConVarChange((hRandom = CreateConVar("sm_matchban_banondisconnect", "1", 
	"1 = Ban player if they disconnect during a live match || 2 = Ban player after sm_matchban_bandelay seconds of disconnecting during a live match", FCVAR_PLUGIN, true, 1.0, true, 2.0)), BanOnDisconnectChanged);
	BanOnDisconnect = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_matchban_bandelay", "60", 
	"Number of seconds to wait for player to reconnect before banning them for leaving during a live match", FCVAR_PLUGIN, true, 1.0, true, 180.0)), BanDelayChanged);
	BanDelay = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_matchban_banlength", "1440", 
	"How many minutes to ban a player if they leave during a live match (1440 minutes = 24 hours = 1 day || 10080 minutes = 7 days)", FCVAR_PLUGIN, true, 1.0, true, 10080.0)), BanLengthChanged);
	BanLength = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_matchban_reason", "Disconnect by user.", 
	"Disconnect reason to check for\nCS:S uses \"Disconnect by user.\"\nCS:GO uses \"Disconnect\"", FCVAR_PLUGIN)), DisconnectReasonChanged);
	GetConVarString(hRandom, DisconnectString, sizeof(DisconnectString));
	
	HookConVarChange((hRandom = CreateConVar("sm_matchban_debug", "0", 
	"Use debug feature?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), UseDebugChanged);
	UseDebug = GetConVarBool(hRandom);
	
	CloseHandle(hRandom); // KyleS hates handles
	
	RegAdminCmd("sm_matchban", cmdmatchban, ADMFLAG_BAN, "Will toggle the match live auto ban feature");

	HookEvent("player_disconnect", PlayerDisconnect_Event);
	
	// Execute the config file
	AutoExecConfig(true, "sm_matchban.plugin");
	
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	h_Trie = CreateTrie();
}

public OnAllPluginsLoaded()
{
	if (LibraryExists("sourcebans"))
	{
		IsSBAvailable = true;
		if (UseDebug)
		{
			LogMessage("Sourcebans is available!");
		}
	}
	else
	{
		if (UseDebug)
		{
			LogMessage("Sourcebans is NOT available!");
		}
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "sourcebans"))
	{
		IsSBAvailable = true;
	}
	
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "sourcebans"))
	{
		IsSBAvailable = false;
		if (UseDebug)
		{
			LogMessage("Sourcebans was disabled/removed!");
		}
	}
}

public OnMapStart()
{
	// Clear all entries of the Trie
	ClearTrie(h_Trie);
}

public OnClientAuthorized(client, const String:auth[])
{
	// Do not process if client is a BOT
	if (!IsFakeClient(client))
	{
		if (UseDebug)
		{
			Format(dmsg, sizeof(dmsg), "%L is authorized with SteamID %s", client, auth);
			DebugMessage(dmsg);
		}
		
		new UserID_Check; // Junk variable for testing if GetTrieValue returns true or false.
		
		// Retrieve the value of the Trie, if it exists and remove from Trie
		if (GetTrieValue(h_Trie, auth, UserID_Check))
		{
			if (UseDebug)
			{
				Format(dmsg, sizeof(dmsg), "%L had a match with SteamID %s - removing SteamID from Trie", client, auth);
				DebugMessage(dmsg);
			}
			
			RemoveFromTrie(h_Trie, auth);
		}
		else
		{
			if (UseDebug)
			{
				Format(dmsg, sizeof(dmsg), "%L did not have a match with SteamID %s", client, auth);
				DebugMessage(dmsg);
			}
		}
	}
}

public PlayerDisconnect_Event(Handle:event, String:name[], bool:dontBroadcast)
{
	new UserID = GetEventInt(event, "userid");
	new client = GetClientOfUserId(UserID);
	
	if (client == 0)
	{
		return;
	}
	
	if (UseDebug)
	{
		Format(dmsg, sizeof(dmsg), "%L triggered disconnect event", client);
		DebugMessage(dmsg);
	}
	
	if (IsClientInGame(client) && !IsFakeClient(client) && MB_Is_Enabled)
	{
		if (CheckCommandAccess(client, "allow_matchban_bypass", ADMFLAG_CUSTOM4))
		{
			if (UseDebug)
			{
				Format(dmsg, sizeof(dmsg), "%L has immunity to matchban.", client);
				DebugMessage(dmsg);
			}
			
			return;
		}
			
		// Get and store the client's SteamID
		new String:authString[20];
		GetClientAuthString(client, authString, 20);
		
		// Get and store the player's name in a string for later use
		new String:playername[MAX_NAME_LENGTH];
		GetClientName(client, playername, sizeof(playername));
		
		// Get and store the client's disconnect reason
		new String:reason[192];
		GetEventString(event, "reason", reason, sizeof(reason));
		
		if (UseDebug)
		{
			Format(dmsg, sizeof(dmsg), "%L has disconnect reason of: %s", client, reason);
			DebugMessage(dmsg);
		}
		
		if (StrContains(reason, DisconnectString) != -1)
		{
			if (BanOnDisconnect == 1)
			{
				if (UseDebug)
				{
					Format(dmsg, sizeof(dmsg), "BanOnDisconnect=1, banning %L", client);
					DebugMessage(dmsg);
				}
				
				MB_BanPlayer(UserID, client, authString, reason, playername, IsClientConnected(client));
				
				return;
			}
			
			if (UseDebug)
			{
				Format(dmsg, sizeof(dmsg), "BanOnDisconnect != 1, adding %L info to Trie and starting timer", client);
				DebugMessage(dmsg);
			}
			
			// Create timer to wait and see if player rejoins the server - if not, execute a ban
			// Adds the clients AuthID to the trie for further processing by the timer to follow
			SetTrieValue(h_Trie, authString, UserID, true);
			
			new Handle:MB_Pack;
			new String:sClient[MAXPLAYERS];
			IntToString(client, sClient, sizeof(sClient));
			
			CreateDataTimer(BanDelay, Timer_BanEnforce, MB_Pack);
			
			WritePackCell(MB_Pack, UserID);
			WritePackString(MB_Pack, sClient);
			WritePackString(MB_Pack, authString);
			WritePackString(MB_Pack, reason);
			WritePackString(MB_Pack, playername);
			
			if (UseDebug)
			{
				Format(dmsg, sizeof(dmsg), "Wrote UserID[%i], ClientID[%i], SteamID[%s], Reason[%s], and Name[%s] to MB_Pack", UserID, client, authString, reason, playername);
				DebugMessage(dmsg);
			}
		}
	}
}

public Action:Timer_BanEnforce(Handle:timer, Handle:MB_Pack)
{
	new UserID_Check;
	new String:sClient[MAXPLAYERS];
	new String:authString[20];
	new String:reason[192];
	new String:playername[MAX_NAME_LENGTH];
	
	ResetPack(MB_Pack);
	
	new UserID = ReadPackCell(MB_Pack);
	ReadPackString(MB_Pack, sClient, sizeof(sClient));
	ReadPackString(MB_Pack, authString, sizeof(authString));
	ReadPackString(MB_Pack, reason, sizeof(reason));
	ReadPackString(MB_Pack, playername, sizeof(playername));
	
	if (UseDebug)
	{
		Format(dmsg, sizeof(dmsg), "Timer for SteamID[%s], Name[%s] triggered, checking if ban is required.", authString, playername);
		DebugMessage(dmsg);
	}
	
	// Let's search the Trie for the SteamID.  If it's still in the Trie, that means the player didn't return in time, so let's ban him.
	if (GetTrieValue(h_Trie, authString, UserID_Check))
	{
		new client = StringToInt(sClient);
		MB_BanPlayer(UserID, client, authString, reason, playername, false);
		
		RemoveFromTrie(h_Trie, authString);
	}
}

/**
 * Bans and logs the ban of a disconnecting client
 * 
 * @param	UserID	UserID of client
 * @param	client		Client index
 * @param	auth		SteamID String
 * @param	reason	Disconnect reason string
 * @param	name		Client's name
 * @param	PlayerConnected	Bool for if player is connected or not
 * 
 * @noreturn
 */
public MB_BanPlayer(any:UserID, any:client, const String:auth[], const String:reason[], const String:name[], bool:PlayerConnected)
{
	if (PlayerConnected)
	{
		if (IsSBAvailable)
		{
			SBBanPlayer(0, client, BanLength, "Left during live match");
			
			if (UseDebug)
			{
				Format(dmsg, sizeof(dmsg), "Banned %L using SourceBans", client);
				DebugMessage(dmsg);
			}
		}
		else
		{
			BanClient(client, BanLength, BANFLAG_AUTO, "Left during live match");
			
			if (UseDebug)
			{
				Format(dmsg, sizeof(dmsg), "Banned %L using SourceMod", client);
				DebugMessage(dmsg);
			}
		}
	}
	else
	{
		ServerCommand("sm_addban %i \"%s\" \"Left during live match\"", BanLength, auth);
		
		if (UseDebug)
		{
			Format(dmsg, sizeof(dmsg), "Player no longer connected, adding ban by SteamID[%s]", auth);
			DebugMessage(dmsg);
		}
	}
	
	LogMessage("%s [UserID #%i] [ClientID #%i] [%s] was banned for leaving during a live match.  DISCONNECT REASON was: %s", name, UserID, client, auth, reason);
}

public Action:cmdmatchban(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "%s Usage: sm_matchban <1/0>", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	new String:arg[2];
	GetCmdArg(1, arg, sizeof(arg));
	
	new OnOff = StringToInt(arg);

	switch (OnOff)
	{
		case 0:
		{
			if (!MB_Is_Enabled)
			{
				return Plugin_Handled;
			}
			
			MB_Is_Enabled = false;
			PrintToChatAll("%s \x04-[\x03deactivated\x04]-", PLUGIN_PREFIX);
			LogMessage("[Match Ban] DeActivated");		
		}
		
		case 1:
		{
			if (MB_Is_Enabled)
			{
				return Plugin_Handled;
			}
			
			MB_Is_Enabled = true;
			PrintToChatAll("%s \x04-[\x03active\x04]-", PLUGIN_PREFIX);
			PrintToChatAll("\x04Do not disconnect while game is -[\x03live\x04]- or you may get banned!");
			LogMessage("[Match Ban] Activated");
		}
		
		default:
		{
			ReplyToCommand(client, "%s Usage: sm_matchban <1/0>", PLUGIN_PREFIX);
		}
	}
	
	return Plugin_Continue;
}

DebugMessage(const String:msg[], any:...)
{
	LogMessage("%s", msg);
}

public BanOnDisconnectChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	BanOnDisconnect = GetConVarInt(cvar);
}
	
public BanDelayChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	BanDelay = GetConVarFloat(cvar);
}
	
public BanLengthChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	BanLength = GetConVarInt(cvar);
}

public DisconnectReasonChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(cvar, DisconnectString, sizeof(DisconnectString));
}

public UseDebugChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseDebug = GetConVarBool(cvar);
}