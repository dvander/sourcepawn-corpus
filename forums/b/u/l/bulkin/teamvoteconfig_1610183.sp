#include <sourcemod>
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#undef REQUIRE_PLUGIN

#define GETVERSION "0.2.4"
#define MAXCLIENTS MaxClients

new bool:votedTeamOne = false;
new String:votedConfig[64];
new votedTeam = 0;
new bool:isL4D = false;

new Handle:sm_tvc_prefix     = INVALID_HANDLE;
new Handle:sm_tvc_exec_delay = INVALID_HANDLE;
new Handle:sm_tvc_comploader_disable = INVALID_HANDLE;

// SDK calls
new Handle:gConf = INVALID_HANDLE;
new Handle:fSHS = INVALID_HANDLE;
new Handle:fTOB = INVALID_HANDLE;

//Plugin Info
public Plugin:myinfo = 
{
	name   = "Team Vote Config Loader",
	author = "Comrade Bulkin",
	description = "Executes config by Team Vote. Also player can change team by !switchme, !infected, !survivor or !surv (for L4D1/2)",
	version = GETVERSION,
	url     = "http://forum.teamserver.ru"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("teamvoteconfig.phrases");	
	
	CreateConVar("sm_tvc_version", GETVERSION, "Version of Sourcemod Config Loader plugin", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	sm_tvc_prefix     = CreateConVar("sm_tvc_prefix", "", "Prefix of config which will be added to its name.", FCVAR_NOTIFY);
	sm_tvc_exec_delay = CreateConVar("sm_tvc_exec_delay", "3.0", "Delay to start voted config.", FCVAR_NOTIFY);
	sm_tvc_comploader_disable = CreateConVar("sm_tvc_comploader_disable", "1", "Disable Comp Loader plugin and enable !load command through TVC.", FCVAR_NOTIFY);
	
	AutoExecConfig(true, "tvc")
	
	// SDK Calls: Copied from L4DUnscrambler plugin, made by Fyren (http://forums.alliedmods.net/showthread.php?p=730278)
	gConf = LoadGameConfigFile("tvc");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	fSHS = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	fTOB = EndPrepSDKCall();

	RegConsoleCmd("sm_cplay", ConfigSuggest);
	RegConsoleCmd("sm_cfg", ConfigSuggest);
	RegConsoleCmd("sm_confirm", ConfigConfirm);
	RegConsoleCmd("sm_switchme", switchPlayer);
	RegAdminCmd("sm_forceplay", ForcePlay, ADMFLAG_CONFIG);
	
}

public OnAllPluginsLoaded()
{
	new compLoaderDisable = GetConVarInt(sm_tvc_comploader_disable);
	
	// Check if user wants to disable Comp Loader			
	new Handle:iter = GetPluginIterator(); // Get plugins list
	new String:pl[64];
	new bool:compLoaderExists = false;
	new bool:l4dreadyExists = false;

	// GameName
	new String:GameType[50];
	GetGameFolderName(GameType, sizeof(GameType));
	
	// Try to find the comp_loader
	while (MorePlugins(iter))
	{
		GetPluginFilename(ReadPlugin(iter), pl, sizeof(pl));

		// Search for comp_loader
		if (StrContains(pl, "comp_loader", false) == 0)
		{
			if (compLoaderDisable > 0)
			{				
				ServerCommand("sm plugins unload %s", pl); // Unload Comp Loader				
			}
			else
			{
				compLoaderExists = true; // The Key, that Comp Loader is stil exists
			}
		}
		else
		if (StrContains(pl, "l4dready", false) == 0)
		{
			l4dreadyExists = true; // The key, that L4DReady plugin exists
		}		
	}
	
	CloseHandle(iter); 
	
	if (compLoaderExists == false)
	{
		RegConsoleCmd("sm_load", ConfigSuggest); // Add !load command

		if (StrEqual(GameType, "left4dead", false) || StrEqual(GameType, "left4dead2", false) )
		{
			PrintToServer("[TVC] %s: %s", "The Game is", GameType, LANG_SERVER);
			PrintToServer("[TVC] Now it's possible to use !infected or !inf, !survivor, !sur or !surv");
			RegConsoleCmd("sm_infected", toInfected); // Add !infected command
			RegConsoleCmd("sm_inf", toInfected); // Add !infected command
			RegConsoleCmd("sm_survivor", toSurvivors); // Add !survivor command
			RegConsoleCmd("sm_sur", toSurvivors); // Add !surv command
		}
	}
	// End Of searching comp_loader

	if (l4dreadyExists == false)
	{
		RegConsoleCmd("sm_spectate", spectate); // Add !spectate command
	}

	// Set special variables for different games

	if (StrEqual(GameType, "left4dead", false) || StrEqual(GameType, "left4dead2", false) )
	{		
		isL4D = true;
		RegConsoleCmd("sm_surv", toSurvivors); // Add !surv command
	} 

}

/* !cplay or !cfg of !load 
 * Command that a player can use to vote for a config
 * Команда, позволяющая предложить игровой конфиг
 */
public Action:ConfigSuggest(suggester, args)
{	
	new voterTeam;
	new String:newVotedConfig[64];

	//Open the vote menu for the client if they arent using the server console
	if (suggester < 1)
	{
		PrintToServer("\x03[TVC] \x05%T", "Command is in-game only", LANG_SERVER);
	}
	else 
	{
		/* English
		 * *************** 
		 * - If votedTeamOne is empty, then no vote started.
		 *   votedTeam = suggester team
		 *   votedTeamOne = true
		 * -If it is not empty, then we got an answer to suggested config
		 *  Compare suggested team - if it isnot the same with teamOne,
		 *  then we compare the new offered config. If it is the same - 
		 *  we start it. If not:
		 *  votedTeam = ClientTeam 
		 *  votedTeamOne = true
		 *  If the team is the same, then print the message, that his team 
		 *  is voted already.
		 * 
		 * *************************************************************
		 * Russian
		 * ***************
		 * - Если votedTeamOne пустая, значит голосования еще не было.
		 *   votedTeam = команда игрока
		 *   votedTeamOne = true
		 *      
		 * - Если не пустая - значит это ответ на предложение.
		 *   Сравниваем команду игрока - если не совпадает с teamOne,
		 *   то сравниваем ответный конфиг. Если совпадает, запускаем его. 
		 *   Если нет - votedTeam = ClientTeam. votedTeamOne = true
		 *   Если команда совпадает, выводим сообщение, что его команда
		 *   уже проголосовала.
		 * 
		 */		
		voterTeam = GetClientTeam(suggester);
		
		// Let's check that player is in team
		if (voterTeam > 1)
		{
			// Get the name of config
			GetCmdArg(1, newVotedConfig, sizeof(newVotedConfig));			
			
			// If no config entered
			if ( strlen(newVotedConfig) == 0)
			{
				PrintToChat(suggester, "\x03[TVC] \x05%t", "NoConfig");
			}
			else
			/* If there was no vote before
			 * Если еще не было голосования
			 */ 
			if ( votedTeamOne == false )
			{				
				votedTeamOne = true;
				votedTeam    = voterTeam;
				votedConfig  = newVotedConfig;
				PrintToChatAll("\x03[TVC] \x05%t", "SuggestedConfig", votedConfig);
				PrintToChatAll("\x03[TVC] \x05%t", "WaitingConfirm");				
			}
			else
			/* If a config is already suggested by the other team
			 * Если конфиг уже предложен другой командой
			 */
			if ( votedTeamOne == true && votedTeam != voterTeam )
			{
				
				if ( strcmp(newVotedConfig, votedConfig, false) != 0 )
				{					
					votedTeamOne = true;
					votedTeam    = voterTeam;
					votedConfig  = newVotedConfig;
					
					PrintToChatAll("\x03[TVC] \x05%t", "OtherConfigSuggested", votedConfig);
					PrintToChatAll("\x03[TVC] \x05%t", "WaitingConfirm");
				}
				else
				{
					new Float:fdelay = GetConVarFloat(sm_tvc_exec_delay);
					
					// Reset vars
					votedTeamOne = false;
					votedTeam    = 0;
					
					PrintToChatAll("\x03[TVC] \x05%t", "StartTimer", votedConfig, RoundFloat(fdelay));
					
					// Start the config
					CreateTimer(fdelay, StartConfig);
				}				
			}
			else
			/* If a config is already suggested by suggester team
			 * Если конфиг уже предложен своей командой
			 */
			if (votedTeam == voterTeam)
			{
				PrintToChat(suggester, "\x03[TVC] \x05%t", "PlayerTeamConfigSuggested", votedConfig);
			}
		}
		else
		{
			PrintToChat(suggester, "\x03[TVC] \x05%t", "NotInTeam");
		}
	}		
}

/* !confirm
 * Command that a player can use to confirm a config
 * Подверждение конфига противоположной командой
 */
public Action:ConfigConfirm(suggester, args)
{
	new voterTeam;
	
	//Open the vote menu for the client if they arent using the server console
	if(suggester < 1)
	{
		PrintToServer("\x03[TVC] \x05%T", "Command is in-game only", LANG_SERVER);
	}
	else
	{
		/* English
		 * ***********
		 * !confirm
		 * - Compare the team. If it is not the same as teamOne,
		 *   then we start the config. Else print the message, that
		 *   his team is voted before.
		 * 
		 * Russian
		 * ***********
		 * !confirm
		 * - Сравниваем команду игрока - если не совпадает с teamOne,
		 *   то запускаем конфиг. Иначе вывести сообщение, что его команда
		 *   уже проголосовала. 
		 */
		
		voterTeam   = GetClientTeam(suggester);
		
		// Let's check that player is in team		
		if ( voterTeam > 1)
		{
			/* If there was no vote before
			 * Если еще не было голосования
			 */
			if ( votedTeamOne == false )
			{
				PrintToChat(suggester, "\x03[TVC] \x05%t", "ConfirmNoConfig");
			}
			else
			/* If a config is already suggested by the other team
			 * Если конфиг уже предложен другой командой
			 */
			if ( votedTeamOne == true && votedTeam != voterTeam )
			{				
				new Float:fdelay = GetConVarFloat(sm_tvc_exec_delay);
				
				// Reset vars
				votedTeamOne = false;
				votedTeam = 0;																					
				
				PrintToChatAll("\x03[TVC] \x05%t", "StartTimer", votedConfig, RoundFloat(fdelay));
				
				// Start the config
				CreateTimer(fdelay, StartConfig);										
			}
			else
			// If a config already suggested by player's team
			if (votedTeam == voterTeam)
			{
				PrintToChat(suggester, "\x03[TVC] \x05%t", "AlreadySuggested", votedConfig);
			}
		}
		else
		{
			PrintToChat(suggester, "\x03[TVC] \x05%t", "NotInTeam");
		}
	}
}


/* !forceplay
 * Admin force command
 * Принудительный запуск конфига админом
 */
public Action:ForcePlay(admin, args)
{
	new String:forcedConfig[64];
	
	//Open the vote menu for the client if they arent using the server console
	if(admin < 1)
	{
		PrintToServer("\x03[TVC] \x05%T", "Command is in-game only", LANG_SERVER);
	}
	else 
	{
		// Get the name of config
		GetCmdArg(1, forcedConfig, sizeof(forcedConfig));			
		
		// If no config entered
		if ( strlen(forcedConfig) == 0)
		{
			PrintToChat(admin, "\x03[TVC] \x05%t", "NoConfig");
		}
		else
		{
			new Float:fdelay = GetConVarFloat(sm_tvc_exec_delay);
			
			// Reset vars
			votedTeamOne = false;
			votedTeam    = 0;
			votedConfig  = forcedConfig;
			
			PrintToChatAll("\x03[TVC] \x05%t", "StartTimer", votedConfig, RoundFloat(fdelay));
			
			// Start the config
			CreateTimer(fdelay, StartConfig);
		}		
	}
	
}

// Start the config
public Action:StartConfig(Handle:timer)
{
	new String:prefix[64];
	GetConVarString(sm_tvc_prefix, prefix, sizeof(prefix));
	
	PrintToChatAll("\x03[TVC] \x05%t", "Starting", votedConfig);
	
	if ( strlen(prefix) > 0)
	{
		ServerCommand("exec %s_%s.cfg", prefix, votedConfig);
	}
	else
	{
		ServerCommand("exec %s.cfg", votedConfig);
	}
	
	// Reset votedConfig
	votedConfig = "";	
}

// Get MAX players of each team in L4D1/2
stock GetL4dMaxPlayers(team)
{
	if(team == 2)
	{
		return GetConVarInt(FindConVar("survivor_limit"));
	}
	else if(team == 3)
	{
		return GetConVarInt(FindConVar("z_max_player_zombies"));
	}
	
	return -1;
}

// Count Live players in team in L4D1/2
stock GetMaxPlayersInTeam(team)
{
	new players = 0;
	
	new i;

	for(i = 1; i <= MAXCLIENTS; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
		{
			players++;
		}
	}
	
	return players;
}

// Get free slots in team in L4D1/2
stock getL4dFreePlayers(team)
{
	new maxSlots = GetL4dMaxPlayers(team);
	new UsedSlots = GetMaxPlayersInTeam(team);
	new freeSlots = maxSlots - UsedSlots;

	//PrintToServer("\x03[TVC] Slots:\n     > \x05Slots %d.\n     > \x05Live Players %d.\n     > \x05Free Slots %d.", maxSlots, UsedSlots, freeSlots);

	return freeSlots;
}

/*  The function, which allows a player
	to switch himself to any team or to spectator
	by a simple command !infected, !surv and so on
*/
public Action:switchPlayer(player, args)
{
	if(player < 1)
	{
		PrintToServer("\x03[TVC] \x05%T", "Command is in-game only", LANG_SERVER);
	}
	else
	if (isL4D == true)
	{		
		new playerTeam = GetClientTeam(player);
		new freeSlots = getL4dFreePlayers(playerTeam);

		if (playerTeam == 2)
		{
			if(freeSlots <= 0)
			{
				PrintToChat(player, "\x03[TVC] \x05%t", "InfectedTeamFull");
			}
			else
			{
				PerformSwitch (player, 3, false);	
			}		
		}
		else
		if (playerTeam == 3)
		{
			if(freeSlots <= 0)
			{
				PrintToChat(player, "\x03[TVC] \x05%t", "SurvivorsTeamFull");
			}
			else
			{
				PerformSwitch (player, 2, false);
			}
		}
		else
		{
			PrintToChat(player, "\x03[TVC] \x05%t", "MustBeInTeamToSwitch");
		}
	}
	else
	{
		if (GetClientTeam(player) == 2)
		{
			PerformSwitch (player, 3, false);		
		}
		else
		if (GetClientTeam(player) == 3)
		{
			PerformSwitch (player, 2, false);
		}
		else
		{
			PrintToChat(player, "\x03[TVC] \x05%t", "MustBeInTeamToSwitch");
		}
	}
}

// Switch player to Spectator
// Common function for all games
public Action:spectate(player, args)
{
	if(player < 1)
	{
		PrintToServer("\x03[TVC] \x05%T", "Command is in-game only", LANG_SERVER);
	}
	else
	{
		PerformSwitch (player, 1, false);			
	}

	return Plugin_Handled;
}

// Switch player to Survivors
public Action:toSurvivors(player, args)
{
	new freeSurvivorSlots = getL4dFreePlayers(2);
	
	if(player < 1)
	{
		PrintToServer("\x03[TVC] \x05%T", "Command is in-game only", LANG_SERVER);
		return Plugin_Handled;
	}

	if(freeSurvivorSlots <= 0)
	{
		PrintToChat(player, "\x03[TVC] \x05%t", "SurvivorsTeamFull");
	}
	else
	{
		PerformSwitch (player, 2, false);
	}

	return Plugin_Handled;
}

// Switch player to Infected
public Action:toInfected(player, args)
{
	new freeInfectedSlots = getL4dFreePlayers(3);

	if(player < 1)
	{     
		PrintToServer("\x03[TVC] \x05%T", "Command is in-game only", LANG_SERVER);
		return Plugin_Handled;
	}

	if(freeInfectedSlots <= 0)
	{
		PrintToChat(player, "\x03[TVC] \x05%t", "InfectedTeamFull");
	}
	else
	{
		PerformSwitch (player, 3, false);	
	}

	return Plugin_Handled;
}

// The part of this code is taken from L4DSwitchPlayers
PerformSwitch (player, team, bool:silent)
{
	new String:PlayerName[200];
	GetClientName(player, PlayerName, sizeof(PlayerName));

	// GameName
	new String:GameType[50];
	GetGameFolderName(GameType, sizeof(GameType));

	if ((!IsClientConnected(player)) || (!IsClientInGame(player)))
	{
		PrintToServer("[TVC] The player is not avilable anymore.");
		return;
	}
	
	// If teams are the same ...
	if (GetClientTeam(player) == team)
	{
		PrintToChat(player, "\x03[TVC] \x05%t", "AlreadyInTeam");
		return;
	}
	
	if (StrEqual(GameType, "left4dead", false) || StrEqual(GameType, "left4dead2", false))
	{
		// If player was on infected .... 
		if (GetClientTeam(player) == 3)
		{
			// ... and he wasn't a tank ...
			new String:iClass[100];
			GetClientModel(player, iClass, sizeof(iClass));
			if (StrContains(iClass, "hulk", false) == -1)
				ForcePlayerSuicide(player);	// we kill him
		}
		
		// If player is survivors .... we need to do a little trick ....
		if (team == 2)
		{
			// first we switch to spectators ..
			ChangeClientTeam(player, 1); 
			
			// Search for an empty bot
			new bot = 1;
			while !(IsClientConnected(bot) && IsFakeClient(bot) && (GetClientTeam(bot) == 2)) do bot++;
				
			// force player to spec humans
			SDKCall(fSHS, bot, player); 
			
			// force player to take over bot
			SDKCall(fTOB, player, true); 
		}
		else // We change it's team ...
		{
			ChangeClientTeam(player, team);
		}

		// Print switch info
		if (!silent)
		{
			if (team == 1)
				PrintToChatAll("\x03[TVC] \x01%t", "SwitchedToSpec", PlayerName);
			else if (team == 2)
				PrintToChatAll("\x03[TVC] \x05%t", "SwitchedToSurvivors", PlayerName);
			else if (team == 3)
				PrintToChatAll("\x03[TVC] \x05%t", "SwitchedToInfected", PlayerName);
		}
	}
	else
	if (StrEqual(GameType, "tf", false))
	{
		ChangeClientTeam(player, team);

		if (!silent)
		{
			if (team == 1)
				PrintToChatAll("\x03[TVC] \x01%t", "SwitchedToSpec", PlayerName);
			else if (team == 2)
				PrintToChatAll("\x03[TVC] \x04%t", "SwitchedTo", PlayerName, "RED");
			else if (team == 3)
				PrintToChatAll("\x03[TVC] \x05%t", "SwitchedTo", PlayerName, "BLU");
		}
	}
	else
	if (StrEqual(GameType, "cstrike", false) || StrEqual(GameType, "css", false))
	{
		ChangeClientTeam(player, team);

		if (!silent)
		{
			if (team == 1)
				PrintToChatAll("\x06[TVC] \x05%t", "SwitchedToSpec", PlayerName);
			else if (team == 2)
				PrintToChatAll("\x06[TVC] \x04%t", "SwitchedTo", PlayerName, "Terrorists");
			else if (team == 3)
				PrintToChatAll("\x06[TVC] \x03%t", "SwitchedTo", PlayerName, "Counter-Terrorists");
		}
	}
	else
	{
		ChangeClientTeam(player, team);

		if (!silent)
		{
			if (team == 1)
				PrintToChatAll("\x03[TVC] \x05%t", "SwitchedToSpec", PlayerName);
			else if (team == 2)
				PrintToChatAll("\x03[TVC] \x05%t", "SwitchedTo", PlayerName, "Team #1");
			else if (team == 3)
				PrintToChatAll("\x03[TVC] \x05%t", "SwitchedTo", PlayerName, "Team #2");
		}
	}

	
}