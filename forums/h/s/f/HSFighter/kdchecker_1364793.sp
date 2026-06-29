//////////////////////////////////////////////////////////////////
// Kill Death Ratio Checker By HSFighter / www.hsfighter.net
//////////////////////////////////////////////////////////////////

#include <sourcemod>
#pragma semicolon 1
#define PLUGIN_VERSION "1.7.1"

#undef REQUIRE_PLUGIN
#include <updater>


/* Updater */
#define UPDATE_URL	"http://update.hsfighter.net/sourcemod/kdchecker/kdchecker.txt"


//////////////////////////////////////////////////////////////////
// Declaring variables and handles
//////////////////////////////////////////////////////////////////

new Handle:KDCheckerEnabled;
new Handle:KDCheckerShowRoundEnd;
new Handle:KDCheckerShowOnKill;
new Handle:KDCheckerWatchEnabled;	
new Handle:KDCheckerEnabledCheckRate;	
new Handle:KDCheckerRate;
new Handle:KDCheckerKills;
new Handle:KDCheckerActionMode;
new Handle:KDCheckerBanTime;
new Handle:KDCheckerDebug;


new g_bSBAvailable = false;


//////////////////////////////////////////////////////////////////
// Plugin Info
//////////////////////////////////////////////////////////////////

public Plugin:myinfo =
{
	name = "KDR Checker",
	author = "HSFighter",
	description = "Kill Death Ratio Checker",
	version = PLUGIN_VERSION,
	url = "http://www.hsfighter.net"
};


//////////////////////////////////////////////////////////////////
// Start plugin
//////////////////////////////////////////////////////////////////

public OnPluginStart()
{
	// Create convars
	CreateConVar("sm_kdrc_version", PLUGIN_VERSION, "KD Kicker Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	KDCheckerEnabled          = CreateConVar("sm_kdrc_enable",          "1",    "Enable/Disable KD Checker", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	KDCheckerShowRoundEnd     = CreateConVar("sm_kdrc_show_roundend",   "1",    "Show KD Rate to player on roundend", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	KDCheckerShowOnKill       = CreateConVar("sm_kdrc_show_kill",   	"0",    "Show KD Rate to attacker on kill", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	KDCheckerWatchEnabled     = CreateConVar("sm_kdrc_watch_enable",    "0",    "Enable/Disable KD Rate watching", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	KDCheckerRate             = CreateConVar("sm_kdrc_watch_rate",      "4.0",  "KD Rate for a player before action", FCVAR_PLUGIN, true, 1.0);
	KDCheckerKills            = CreateConVar("sm_kdrc_watch_kills",     "15",   "Count of kills before a player is checked", FCVAR_PLUGIN, true, 1.0);
	KDCheckerEnabledCheckRate = CreateConVar("sm_kdrc_watch_checkrate", "30.0",	"Rate in seconds at players KD Rate are checked", FCVAR_PLUGIN, true, 1.0);
	KDCheckerActionMode       = CreateConVar("sm_kdrc_watch_action",    "0",    "Action for affected player (0 = kick, 1 = ban)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	KDCheckerBanTime          = CreateConVar("sm_kdrc_watch_bantime",   "60",   "Amount of time in Minutes to ban if using 'sm_kdrc_watch_action = 1' (0 = perm)", _, true, 0.0);
	KDCheckerDebug     		  = CreateConVar("sm_kdrc_debug",   		"0",    "Debug playercheck to serverlog", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	// Register Console Commands
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	RegConsoleCmd("sm_kdr", ShowKDRateToClientCmd);
	
	// Hook Events
	HookEvent("round_end", EventRoundEnd);
	HookEvent("player_death", hookPlayerDie, EventHookMode_Post);
	
	// Updater
	if(LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	
	// Create Timer for delay
	CreateTimer(GetConVarFloat(KDCheckerEnabledCheckRate), Checktime, _, TIMER_REPEAT);
	
	// Autoexec / Create Configfile
	AutoExecConfig(true, "plugin.kdcheck");
}

//////////////////////////////////////////////////////////////////
// Check if sourcebans present 
//////////////////////////////////////////////////////////////////

public OnAllPluginsLoaded()
{
	if (LibraryExists("sourcebans"))
	{
		g_bSBAvailable = true;
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "sourcebans"))
	{
		g_bSBAvailable = true;
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
		g_bSBAvailable = false;
	}
}


//////////////////////////////////////////////////////////////////
// Action: Say Command
//////////////////////////////////////////////////////////////////

public Action:Command_Say(client, args)
{
	
    // Check if plugin is disbaled
	if(GetConVarInt(KDCheckerEnabled) != 1)
	{  
		return Plugin_Continue;	
	}
		
	// Check if player ok
	if (!client)
	{
		return Plugin_Continue;
	}

	// Declaring variables
	decl String:text[192], String:command[64];
	new startidx = 0;

	// Check saycommand is valid
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}

	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	// Check saycommand type
	GetCmdArg(0, command, sizeof(command));
	if (strcmp(command, "say2", false) == 0)
	{
		startidx += 4;
	}

	// Is saycommand "kdr" show KD-Rate to player
	if (strcmp(text[startidx], "kdr", false) == 0)
	{
		ShowKDRateToClient(client, 0);
		
	}
	
	if (strcmp(text[startidx], "kdrselfaction", false) == 0)
	{
		KDRateAction(client);
		
	}
	
	return Plugin_Continue;
}


//////////////////////////////////////////////////////////////////
// Action: Send KD Rate Text to Client Cmd
//////////////////////////////////////////////////////////////////

public Action:ShowKDRateToClientCmd(client, args){

	ShowKDRateToClient(client, 0);

}


//////////////////////////////////////////////////////////////////
// Action: Send KD Rate Text to Client
//////////////////////////////////////////////////////////////////

public Action:ShowKDRateToClient(client, offset){
	
	decl String:player_name[65];
	GetClientName(client, player_name, sizeof(player_name));
	
	// Get Deaths, Kills and KD Rate
	new Deaths = GetClientDeaths(client);
	new Frags = GetClientFrags(client) + offset;
	new Float:KDRate = float(Frags)/float(Deaths);
	
	if ((Deaths == 0) && (Frags != 0)) KDRate = float(Frags);
	if (Frags < 0) KDRate = float(0);
	
	// Print KDR to Client
	PrintToChat(client, "\x01[KDR Check] \x03%s\x04, your KDRate is \x03%.2f \x04(\x03%i \x04Kills / \x03%i \x04Deaths)", player_name, KDRate, Frags, Deaths);
	// LogAction(client, -1, "[KDR Check] Test %i Minutes", GetConVarInt(KDCheckerBanTime));
	return Plugin_Handled;	
}


//////////////////////////////////////////////////////////////////
// Action: Event Roundstart
//////////////////////////////////////////////////////////////////


public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check if "Plugin" is disbaled or "show kdr on roundend" is disbaled
	if((GetConVarInt(KDCheckerEnabled) != 1) || (GetConVarInt(KDCheckerShowRoundEnd) != 1)) return Plugin_Continue;
	
	// Get all clients on the server
	for (new i = 1; i <= MaxClients; i++)
	{
		//Check if player ok
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ShowKDRateToClient(i, 0);			
		}
	}	
	return Plugin_Continue;

}

//////////////////////////////////////////////////////////////////
// Action: Event Player Die
//////////////////////////////////////////////////////////////////


public Action:hookPlayerDie(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check if "Plugin" is disbaled or "show kdr on kill" is disbaled
	if((GetConVarInt(KDCheckerEnabled) != 1) || (GetConVarInt(KDCheckerShowOnKill) != 1)) return Plugin_Continue;
	
	new attacker = GetEventInt(event, "attacker");
	new id =  GetClientOfUserId(attacker);
	
	// Check if player ok
	if (IsClientConnected(id) && IsClientInGame(id))
	{
		ShowKDRateToClient(id, 1);
	}
	return Plugin_Continue;
}


//////////////////////////////////////////////////////////////////
// Action: Timerloop
//////////////////////////////////////////////////////////////////

public Action:Checktime(Handle:timer){
	
	// Check if Plugin is disbaled or Watching is disbaled
	if((GetConVarInt(KDCheckerEnabled) != 1)) return Plugin_Continue;
	

	// Get all clients on the server
	for (new i = 1; i <= MaxClients; i++)
	{
		// Check if player ok
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			// Get playername
			new String:f_sPlayer_Name[65];
			GetClientName(i, f_sPlayer_Name, sizeof(f_sPlayer_Name));
			
			// Get Player ID and IP
			new String:f_sAuthID[64], String:f_sIP[64];
			
			GetClientAuthString(i, f_sAuthID, sizeof(f_sAuthID));
			GetClientIP(i, f_sIP, sizeof(f_sIP));
			
			// Check if player ist bot
			if (!IsClientBot(i))
			{
				if(GetConVarInt(KDCheckerWatchEnabled) == 1) GetClientKillDeathRatio(i);
				if(GetConVarInt(KDCheckerDebug) != 0) LogAction(i, -1,"[KDR Check] Check %s (ID: %s | IP: %s) is PLAYER", f_sPlayer_Name, f_sAuthID, f_sIP);	
			}else{
				if(GetConVarInt(KDCheckerDebug) != 0) LogAction(i, -1,"[KDR Check] Ignore %s (ID: %s | IP: %s) is BOT", f_sPlayer_Name, f_sAuthID, f_sIP);
			}
		}
	}
	
	
	return Plugin_Continue;
} 


//////////////////////////////////////////////////////////////////
// Action: Get KillDeathRatio
//////////////////////////////////////////////////////////////////

public Action:GetClientKillDeathRatio(client)
{		
	// Get Deaths, Kills and KD Rate
	new Deaths = GetClientDeaths(client);
	new Frags = GetClientFrags(client);
	new Float:KDRate = float(Frags)/float(Deaths);
	
	if ((Deaths == 0) && (Frags != 0)) KDRate = float(Frags);
	if (Frags < 0) KDRate = float(0);
	
	if(!Deaths){ 
		// If Deaths null return	
		return Plugin_Continue;	
	}else{
		// If frags less than kill threshold return
		if ((Frags) < GetConVarInt(KDCheckerKills)) return Plugin_Continue;
		// Calc KD-Rate and exec action if necessary
		if (KDRate >= GetConVarFloat(KDCheckerRate))
		{
			// Exec Action
			KDRateAction(client);
	    }		
    }
	return Plugin_Continue;
}


//////////////////////////////////////////////////////////////////
// Action: Exec KillDeathRatio watch event for a client
//////////////////////////////////////////////////////////////////

public Action:KDRateAction(client)
{

	// Get Player ID
	new String:f_sAuthID[64];
	GetClientAuthString(client, f_sAuthID, sizeof(f_sAuthID));
	
	// Get Player IP
	new String:f_sIP[64];
	GetClientIP(client, f_sIP, sizeof(f_sIP));
	
	// Get client name
	new String:f_sPlayer_Name[65];
	GetClientName(client, f_sPlayer_Name, sizeof(f_sPlayer_Name));
	
	// Select Action Mode
	switch (GetConVarInt(KDCheckerActionMode))
	{				
		// If Kick
		case 0: 
		{
			// Kick client
			KickClient(client, "You were kicked due high KD Rate!");
			// Show message to all other clients
			PrintToChatAll("[KDRCheck] Name: %s was KICKED for a high KD Rate", f_sPlayer_Name);
			// Log Action
			LogAction(client, -1, "[KDR Check] %s (ID: %s | IP: %s) was KICKED for a high KD Rate", f_sPlayer_Name, f_sAuthID, f_sIP);
		}
		// If Ban
		case 1: 	
		{
			// Check if Sourcebans aviable
			if (g_bSBAvailable)
			{
				// Ban client
				ServerCommand("sm_ban #%d %i \"To high KD Rate!\"",GetClientUserId(client), GetConVarInt(KDCheckerBanTime));
				
			}else{
				// Ban client
				BanClient(client, 
					GetConVarInt(KDCheckerBanTime), 
					BANFLAG_AUTO, 
					"High KD Rate", 
					"You were banned due high KD Rate!", 
					"KDRCheck",
					client);		
			}
			
			if (GetConVarInt(KDCheckerBanTime) == 0)
			{
				// Show message permanent ban to all other clients
				PrintToChatAll("[KDRCheck] Name: %s was BANNED for a high KD Rate", f_sPlayer_Name);
				// Log Action
				LogAction(client, -1, "[KDR Check] %s (ID: %s | IP: %s) was BANNED permanently for a high KD Rate", f_sPlayer_Name, f_sAuthID, f_sIP);
			}else{
				// Show message temp ban to all other clients
				PrintToChatAll("[KDRCheck] Name: %s was BANNED %i Minutes for a high KD Rate", f_sPlayer_Name, GetConVarInt(KDCheckerBanTime));
				// Log Action
				LogAction(client, -1, "[KDR Check] %s (ID: %s | IP: %s) was BANNED %i Minutes for a high KD Rate", f_sPlayer_Name, f_sAuthID, f_sIP, GetConVarInt(KDCheckerBanTime));				
			}
		}
    }
	return Plugin_Continue;	
}


//////////////////////////////////////////////////////////////////
// Function: Is client a bot
//////////////////////////////////////////////////////////////////


public bool:IsClientBot(client)
{
	decl String:SteamID[64];
	// Get Steam ID
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	
	//Check if BOT
	if (!IsFakeClient(client) && !StrEqual(SteamID, "BOT") && !StrEqual(SteamID, "STEAM_ID_PENDING")) return false;

	return true;
}

//////////////////////////////////////////////////////////////////
// End Plugin
//////////////////////////////////////////////////////////////////

public OnPluginEnd(){
	

}

//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////