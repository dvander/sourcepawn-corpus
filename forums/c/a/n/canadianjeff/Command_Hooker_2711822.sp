// Safe Commands List:
// vmodenable
// vban
// joingame
// spec_next
// spec_prev
// spec_mode
// say
// team_say
// choose_opendoor
// choose_closedoor
// achievement_earned
// menuselect
// vote
// warp_to_start_area


// Illegal Commands:
// setupslot ### 108/65



#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

char g_sCommandListenerLog[PLATFORM_MAX_PATH];

#define PLUGIN_NAME "Server Exploit Detector And Blocker!"
#define PLUGIN_VERSION "1.10"
#define TEAM_SPECTATOR 1

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "linux_canadajeff, Dustin",
	description = "Listens For ALL Client or Server Commands For Exploits (Logging Possible)",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2711822"
};

enum struct PlayerInfo {
	float lastTime; /* Last time player used command */
	int tokenCount; /* Number of flood tokens player has */
}

PlayerInfo playerinfo[MAXPLAYERS+1];
//new Handle:regeex = INVALID_HANDLE;
new Handle:g_hHostname = INVALID_HANDLE;
new bool:g_bIsInvisible[MAXPLAYERS + 2] = {false, ...};
ConVar g_cBlockIdle = null;
ConVar g_cBlockGlobalChat = null;
ConVar g_cBlockTeamChat = null;
ConVar g_cHidePlayers = null;
ConVar g_cHideBots = null;
ConVar g_cLogger = null;
ConVar g_cConsole = null;
new Handle:g_StatusOS;
new Handle:g_StatusIP;
//ConVar command_flood_time;
//new String:sCodes[][] = {"\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08"};

public void OnPluginStart()
{
	/**
	 * @note For the love of god, please stop using FCVAR_PLUGIN.
	 * Console.inc even explains this above the entry for the FCVAR_PLUGIN define.
	 * "No logic using this flag ever existed in a released game. It only ever appeared in the first hl2sdk."
	 */
	CreateConVar("l4d_command_hooker_version", PLUGIN_VERSION, "Standard plugin version ConVar. Please don't change me!", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cLogger = CreateConVar("l4d_command_hooker_logger", "0", "Enable Logging Commands To Disk?", _, true, 0.0, true, 1.0);
	g_cConsole = CreateConVar("l4d_command_hooker_console", "0", "Enable Showing Commands To Everyones Console?", _, true, 0.0, true, 1.0);
	g_cBlockIdle = CreateConVar("command_hooker_block_idle", "0", "Block \"go_away_from_keyboard\"?", _, true, 0.0, true, 1.0);
	g_cBlockGlobalChat = CreateConVar("command_hooker_block_chat", "0", "Block Global Chat?", _, true, 0.0, true, 1.0);
	g_cBlockTeamChat = CreateConVar("command_hooker_block_teamchat", "0", "Block Team Chat?", _, true, 0.0, true, 1.0);
	g_cHidePlayers = CreateConVar("command_hooker_hide_players", "1", "Hides Players From Status Output", _, true, 0.0, true, 1.0);
	g_cHideBots = CreateConVar("command_hooker_hide_bots", "1", "Hides Bots From Status Output", _, true, 0.0, true, 1.0);
	g_StatusOS = CreateConVar("status_os", "Duck Tape And Lots of Hope", "Set The OS Version In Status Output");
	g_StatusIP = CreateConVar("status_ip", "127.0.0.1:27015", "Set The IP+Port In Status Output");
	//command_flood_time = CreateConVar("command_flood_time", "0.75", "Amount of time allowed between commands");
	g_hHostname = FindConVar("hostname");
	BuildPath(Path_SM, g_sCommandListenerLog, sizeof(g_sCommandListenerLog), "logs/CommandListener.log");
	AddCommandListener(Command_Callback, "");
	//AddCommandListener(OnSayCommand, "say");
	//AddCommandListener(OnSayCommand, "say2");
	//AddCommandListener(OnSayCommand, "say_team");
	
	//regeex = CompileRegex("/^[a-zA-Z0-9]+$/");
}

public void OnMapStart()
{
	/**
	 * @note Precache your models, sounds, etc. here!
	 * Not in OnConfigsExecuted! Doing so leads to issues.
	 */
}

public void OnClientPutInServer(int client)
{
	playerinfo[client].lastTime = 0.0;
	playerinfo[client].tokenCount = 0;
}

public Action:Command_Callback(int client, const char[] command, int args)
{
	char sCmdArgs[192];
	char ClientIP[32];
	GetCmdArgString(sCmdArgs, sizeof(sCmdArgs)) < 1;

// THE CODE HERE IS MAYBE GONNA USE A WHITELIST ALLOWED COMMANDS AND BLOCK EVERYTHING ELSE?????
//	if(IsClientInGame(client) || !IsFakeClient(client))
//	{
//		if(strcmp(command, whitelist[i]) == 0)
//		{
//			PrintToServer("Possible legal Command: %s %s", command, sCmdArgs);
//		}
//		else
//		{
//			PrintToServer("Possible Illegal Command: %s %s", command, sCmdArgs);
//			return Plugin_Handled;
//		}
//	}

// THE CODE BELOW IS TRYING TO DETECT x86 Assembly Code
//	if (IsCharAlpha(client) || client == ' '){PrintToServer("Clients Name (%N) Is Alpha", client);}else{PrintToServer("Clients Name (%N) Is NOT Alpha", client);}
//	if (IsCharAlpha(command)){PrintToServer("Command Is Alpha");}
//	if (IsCharAlpha(sCmdArgs) || sCmdArgs == ' '){PrintToServer("Args (%s) Is Alpha", sCmdArgs);}else{PrintToServer("Args (%s) Is NOT Alpha", sCmdArgs);}

//	PrintToServer("Command_Callback Running!");
//	decl String:sCmdArgs[192];
//	new startidx = 0;

	if (!IsPlayerIndexed(client))
	{
		//PrintToServer("[SM] Player <%N> Not Indexed!", client);
		return Plugin_Continue;
	}

	if (!IsClientInGame(client) || IsFakeClient(client))
	{
		//PrintToServer("[SM] Player <%N> Is Fake!", client);
		return Plugin_Continue;
	}

	char sSteamAuth[56];
	if (!GetClientAuthId(client, AuthId_Steam2, sSteamAuth, sizeof(sSteamAuth)))
	{
		// steam servers down
		PrintToChatAll("[SM] %N Not Authorized", client);
		KickClient(client, "Your Client Did Not Auth With Steam, Please Try Again!");
		return Plugin_Continue;
	}

//	PrintToServer("Command_Callback Still Running!");

//	if (sCmdArgs[strlen(sCmdArgs)-1] == '"')
//	{
//		PrintToServer("Command_Callback If StrLen");
//		sCmdArgs[strlen(sCmdArgs)-1] = '\0';
//		PrintToServer("POSSIBLE UNICODE DETECTED!!!!!!!!!");
//		KickClient(client, "Kicking For An Attempt To Crash The Server");
//		startidx = 1;
//	}

//	if (strcmp(command, "say2", false) == 0)
//	{
//		startidx += 4;
//	}

//	PrintToServer("Command_Callback GOING GOING GOING!!!!");

	//int target = FindTarget(client, sCmdArgs);
	GetClientIP(client, ClientIP, sizeof(ClientIP));

	// No point in logging or printing these common commands used with no args
//	if(argc < 1)
//	{
//		if (StrEqual(command, "choose_opendoor") || StrEqual(command, "choose_closedoor"))
//		{
//			return Plugin_Continue;
//		}
//	}

	if(g_cLogger.BoolValue)
	{
		LogToFile(g_sCommandListenerLog, "%N (ID: %s | IP: ) %s %s", client, sSteamAuth, command, sCmdArgs);
	}
	PrintToServer("[SM] %N (ID: %s | IP: %s) %s %s", client, sSteamAuth, ClientIP, command, sCmdArgs);

	if(g_cConsole.BoolValue)
	{
		PrintToConsoleAll("[SM] %N (ID: %s) %s %s", client, sSteamAuth, command, sCmdArgs);
	}

	if(g_cBlockIdle.BoolValue)
	{
		if (StrEqual(command, "wait") || StrEqual(command, "go_away_from_keyboard"))
		{
			PrintToChat(client, "Console: Sorry, you do not have access to this command.");
			return Plugin_Handled;
		}
	}

	if(g_cBlockGlobalChat.BoolValue)
	{
		if (StrEqual(command, "say"))
		{
			//PrintToChat(client, "Console: Sorry, you do not have access to this command.");
			return Plugin_Handled;
		}
	}

	if(g_cBlockTeamChat.BoolValue)
	{
		if (StrEqual(command, "team_say"))
		{
			//PrintToChat(client, "Console: Sorry, you do not have access to this command.");
			return Plugin_Handled;
		}
	}

	if (StrEqual(command, "pause") || StrEqual(command, "setpause") || StrEqual(command, "unpause"))
	{
		//Would Be Nice To Show Something To All Chat When A Player Is Spamming These To FPS DROP/DDOS
		//PrintToChat(client, "Console: Sorry, you do not have access to this command.");
		//new flags = GetCommandFlags("pause");
		//SetCommandFlags("pause", flags|FCVAR_CHEAT);
		//new flags2 = GetCommandFlags("setpause");
		//SetCommandFlags("setpause", flags2|FCVAR_CHEAT);
		//new flags3 = GetCommandFlags("unpause");
		//SetCommandFlags("unpause", flags3|FCVAR_CHEAT);
		return Plugin_Handled;
	}

	if (StrEqual(command, "survival_record"))
	{
		PrintToChat(client, "[SM] %N (ID: %s) %s %s", client, sSteamAuth, command, sCmdArgs);
		return Plugin_Handled;
	}

	if (StrEqual(command, "jointeam"))
	{
		if (StrEqual(sCmdArgs, "Survivor"))
		{
			PrintToChatAll("[SM] %N has moved to Survivors Team!", client);
			return Plugin_Continue;
		}

		if (StrEqual(sCmdArgs, "Infected"))
		{
			PrintToChatAll("[SM] %N has moved to Zombies Team!", client);
			return Plugin_Continue;
		}

// This Portion Of The Code Is Patched In Last Stand Update!
//		if ( args > 1 )
//		{
//			if (StrContains(sCmdArgs, "Bill") || StrContains(sCmdArgs, "Zoey") || StrContains(sCmdArgs, "Louis") || StrContains(sCmdArgs, "Francis") || StrContains(sCmdArgs, "Coach") || StrContains(sCmdArgs, "Rochelle") || StrContains(sCmdArgs, "Nick") || StrContains(sCmdArgs, "Ellis"))
//			{
//				PrintToChatAll("[SM] %N (%s) Attempted Ghost Bug! (%s %s)", client, sSteamAuth, command, sCmdArgs);
//				return Plugin_Handled;
//			}
//		}
	}

	if (StrEqual(command, "status"))
	{
		new String:buffer[64];
		new String:StatusOS[64];
		new String:StatusIP[32];
		GetConVarString(g_StatusOS,StatusOS,sizeof(StatusOS));
		GetConVarString(g_StatusIP,StatusIP,sizeof(StatusIP));
		GetConVarString(g_hHostname,buffer,sizeof(buffer));
		PrintToConsole(client,"hostname: %s",buffer);
		PrintToConsole(client,"version : 2.2.0.6 8011 secure  (unknown)");
		PrintToConsole(client,"udp/ip  : %s [ public same ] ", StatusIP);
		PrintToConsole(client,"os      : %s", StatusOS);
		GetCurrentMap(buffer,sizeof(buffer));
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		PrintToConsole(client,"map     : %s", buffer);
		PrintToConsole(client,"players : %d (%d max)", GetClientCount() - GetInvisCount(), MaxClients);
		PrintToConsole(client,"# userid name uniqueid connected ping loss state rate adr");
		new String:name[18];
		new String:time[9];
		new iRate;
		for(new i; i <= MaxClients; i++)
		{
			if(ValidPlayer(i))
			{
				if(!g_bIsInvisible[i])
				{
					Format(name,sizeof(name),"\"%N\"",i);
					iRate = GetClientDataRate(client);
					if(!IsFakeClient(i))
					{
						FormatShortTime(RoundToFloor(GetClientTime(i)),time,sizeof(time));
						if (g_cHidePlayers.BoolValue == false){
							PrintToConsole(client,"# %d %s %s %s %d %d active %d 127.0.0.1:27005", GetClientUserId(i), 
								name, sSteamAuth, time, RoundToFloor(GetClientAvgLatency(i,NetFlow_Both) * 1000.0), 
								RoundToFloor(GetClientAvgLoss(i,NetFlow_Both) * 100.0), 
								iRate);
						}
						else
						{
							PrintToConsole(client, " ¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶");
							PrintToConsole(client, " ¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶_____¶¶______¶¶¶____¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶______¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶______¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶______¶¶______¶¶______¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶_____¶¶______¶¶______¶¶______¶¶¶¶¶");
							PrintToConsole(client, " ¶¶¶__¶¶¶¶¶¶¶¶¶¶______¶¶______¶¶______¶¶______¶¶¶¶¶\n \
													¶______¶¶¶¶¶¶¶¶¶_____¶¶______¶¶______¶¶______¶¶¶¶¶\n \
													¶¶______¶¶¶¶¶¶¶______¶¶______¶¶______¶¶______¶¶¶¶¶\n \
													¶¶¶______¶¶¶¶¶¶¶_____¶¶______¶¶______¶¶______¶¶¶¶¶\n \
													¶¶¶¶______¶¶¶¶¶______¶¶______¶¶______¶¶______¶¶¶¶¶\n \
													¶¶¶¶¶_______¶¶¶______¶¶______¶¶______¶¶______¶¶¶¶¶\n \
													¶¶¶¶¶¶_______¶¶¶_____¶¶______¶¶______¶¶¶___¶¶¶¶¶¶¶");
							PrintToConsole(client, " ¶¶¶¶¶¶¶¶______¶¶¶¶_¶¶¶¶______¶¶¶¶__¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶______¶¶¶¶¶¶¶¶¶¶___¶¶¶¶¶¶¶¶¶¶¶_____¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶________¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶__________¶¶¶¶¶¶¶¶¶¶__________¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶_________________________¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶__________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n ");
							PrintToConsole(client, "#end");
							return Plugin_Handled;
						}
					}
					else 
					{
						if (g_cHideBots.BoolValue == false){
							PrintToConsole(client,"#%d %s Bot active", GetClientUserId(i), name);
						}
						else
						{
							PrintToConsole(client, " ¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶");
							PrintToConsole(client, " ¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶_____¶¶______¶¶¶____¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶______¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶______¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶______¶¶______¶¶______¶¶______¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶_____¶¶______¶¶______¶¶______¶¶¶¶¶");
							PrintToConsole(client, " ¶¶¶__¶¶¶¶¶¶¶¶¶¶______¶¶______¶¶______¶¶______¶¶¶¶¶\n \
													¶______¶¶¶¶¶¶¶¶¶_____¶¶______¶¶______¶¶______¶¶¶¶¶\n \
													¶¶______¶¶¶¶¶¶¶______¶¶______¶¶______¶¶______¶¶¶¶¶\n \
													¶¶¶______¶¶¶¶¶¶¶_____¶¶______¶¶______¶¶______¶¶¶¶¶\n \
													¶¶¶¶______¶¶¶¶¶______¶¶______¶¶______¶¶______¶¶¶¶¶\n \
													¶¶¶¶¶_______¶¶¶______¶¶______¶¶______¶¶______¶¶¶¶¶\n \
													¶¶¶¶¶¶_______¶¶¶_____¶¶______¶¶______¶¶¶___¶¶¶¶¶¶¶");
							PrintToConsole(client, " ¶¶¶¶¶¶¶¶______¶¶¶¶_¶¶¶¶______¶¶¶¶__¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶______¶¶¶¶¶¶¶¶¶¶___¶¶¶¶¶¶¶¶¶¶¶_____¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶________¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶__________¶¶¶¶¶¶¶¶¶¶__________¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶_________________________¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶__________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
													¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n ");
							PrintToConsole(client, "#end");
							return Plugin_Handled;
						}
					}
				}
			}
		}
		PrintToConsole(client, "#end");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool:ValidPlayer(client)
{
	if(client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

FormatShortTime(time, String:outTime[], size)
{
	new temp;
	temp = time % 60;
	Format(outTime, size,"%02d",temp);
	temp = (time % 3600) / 60;
	Format(outTime, size,"%02d:%s", temp, outTime);
	temp = (time % 86400) / 3600;
	if(temp > 0)
	{
		Format(outTime, size, "%d%:s", temp, outTime);

	}
}

GetInvisCount()
{
	new count = 0;
	for(new i; i <= MaxClients; i++)
	{
		if(ValidPlayer(i) && g_bIsInvisible[i])
		{
			count++;
		}
	}
	return count;
}

bool IsPlayerIndexed(int client)
{
	return 0 < client <= MaxClients;
}