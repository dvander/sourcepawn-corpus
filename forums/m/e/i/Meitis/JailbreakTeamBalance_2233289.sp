/* CSS Jailbreak Team Balance
   by: databomb
   Original Compile Date: 12.26.2010
   
   Description/Features:
   
   This plugin is designed to automate the team switching that inundate many admins in the CSS Jailbreak community.  A configurable ratio will specify how many Ts for each CT.  The ratio is matched everytime the round ends.  While the ratio is usually higher or lower than what is requested, the plugin will find the closest match possible at the end of every round.  One advantage of this plugin is the separate algorithms for T and CT switching.  When a player is switched off CT team a LIFO routine (last person to join is moved off first) is specified while (optionally) only those with a mic are radonmly switched to CT absent any guard requests which are pending.
   
   Prisoners may type '!guard' in chat or use the sm_guard command to join a queue of those requesting a transfer to CT.  The queue is processed in normal FIFO fashion (the first to join the queue is the first to get a transfer.)  Admins may say '!clearguards' or use the sm_clearguards command to manually clear the guard queue completely.  Admins may also target a single unwanted individual with '!removeguard <player|#userid>' or just sm_removeguard which will bring up the menu.  While anyone is waiting in the queue for a CT position, team switching to CT is blocked and instead handled by the queue.
   
   When you join the server and haven't yet selected a team, you're required by default to pick either Terrorist team or Spectate.  By default auto-join is disabled and CT is only available after you played on the Terorrist team.  Often times the teams will become stacked at the beginning of a map resulting in the often mandated 'first-round free-day.'  This behavior is compensated for by allowing the first person access to the CT team without any of the previous restrictions but enforcing it thereafter.  Also, teams are locked during round transitions to make it impossible for players to switch back to CT without suiciding after they spawn in the following round.  The exception to this is at the beginning of the game when you hear "Round Draw" it will still allow you to join teams.
   
   Optional Plugins:
   
   If you have asherkin's VoiceHook installed then this plugin will determine which Ts used their mics each round and exclude those that did not use their mic from being switched to CT.  This has built in integration with a few other plugins such as Azelphur's and my own team bans plugin in addition to my voicecomm plugin for dead all talk.
   
   Usage/Cvar List:
   sm_jbtb_ratio, [0.1-10.0]: Sets the ratio of Ts to CTs (e.g. 3.0 will match 12Ts & 4CTs with 16 players.)
   sm_jbtb, [0,1]: Turns the plugin functionality on or off.
   sm_jbtb_soundfile, [path]: The path to the soundfile to play when denying a team-change request. Set to "" to disable.
   sm_jbtb_showqueue, [0,1]: Sets whether the position in the queue is revealed to players when they use the guard command.
   sm_jbtb_showclasses, [0,1]: Sets whether to show the classes screen after the team selection screen. Useful for servers that use custom models or model menus.
   sm_jbtb_blockct, [0,1]: This requires everyone to play as T before joining CT. This may frusturate potential free-killers and/or your regulars.
   
   Installation:
   .smx file goes in addons/sourcemod/plugins/
   .phrases.txt file goes in addons/sourcemod/translations/
   
   Future Considerations:
	 - Overhaul the team size matching algorithm and T->CT selection for efficiency
	 - Additional integrations with VoiceHook such as informational notifications
	 - Optimize code further
	 
   Special Thanks:
   psychonic who helped me with many general SM issues
   dalto who wrote the deny sound code which I've used in this plugin
   asherkin who has developed the VoiceHook MetaMod:Source plugin
   
*/

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <adminmenu>
#include <cstrike>

#define VERSION	"3.0.8"
#define REASON_ROUND_DRAW 9
#define REASON_GAME_COMMENCING 15
#define REASON_INVALID 20
#define CHAT_BANNER "\x03[SM] \x01%t"
#define DEBUG 0

enum EJoinTeamReason
{
	k_OneTeamChange=0,
	k_TeamsFull=1,
	k_TTeamFull=2,
	k_CTTeamFull=3
}

// here we'll listen for asherkin's voicehook mm:s plugin
forward OnClientSpeaking(client);
new bool:g_bTalkedThisRound[MAXPLAYERS+1];

new Handle:gH_LimitTeams = INVALID_HANDLE;
new Handle:gH_AzelphurTeamBanStatus = INVALID_HANDLE;
new Handle:gH_AzlBanCookie = INVALID_HANDLE;
new Handle:gH_BanCookie = INVALID_HANDLE;
new Handle:gH_CTBansStatus = INVALID_HANDLE;
new gShadow_CTBan;
new Handle:gH_Cvar_Enabled = INVALID_HANDLE;
new bool:gShadow_Cvar_Enabled;
new Handle:gH_Cvar_RatioGoal = INVALID_HANDLE;
new Float:gShadow_Cvar_RatioGoal;
new Handle:gH_Cvar_SoundName = INVALID_HANDLE;
new String:gShadow_Cvar_SoundName[PLATFORM_MAX_PATH];
new Handle:gH_Cvar_ShowQueuePosition = INVALID_HANDLE;
new bool:gShadow_Cvar_ShowQueuePosition;
new Handle:gH_Cvar_ShowClassPanel = INVALID_HANDLE;
new bool:gShadow_Cvar_ShowClassPanel;
new Handle:gH_TopMenu = INVALID_HANDLE;
new Handle:gH_CTStack = INVALID_HANDLE;
new Handle:gH_TempStack = INVALID_HANDLE;
new Handle:gA_GuardRequest = INVALID_HANDLE;
new Handle:gA_Terrorists = INVALID_HANDLE;

new gLastRoundEndReason = REASON_INVALID;
new g_iActivePlayers = 0;
new g_iNumCTsDuringRound;
new bool:gTeamsLocked;
new bool:gOneJoined;
new bool:gOneRoundPlayed;
new bool:g_bSuicided[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Jailbreak Team Balance",
	author = "databomb",
	description = "Matches teams to a requested ratio every round",
	version = VERSION,
	url = "vintagejailbreak.org"
}

public OnPluginStart()
{
	// Load translations files needed
	LoadTranslations("jailbreak-tb.phrases");
	LoadTranslations("common.phrases");
	
	// Register console variables
	CreateConVar("sm_jbtb_version",VERSION,"Jailbreak Team Balance Version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	gH_Cvar_Enabled = CreateConVar("sm_jbtb","1","Enables the jailbreak team balance system", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gShadow_Cvar_Enabled = true;
	gH_Cvar_RatioGoal = CreateConVar("sm_jbtb_ratio","2.75","Sets the requested ratio of how many Ts per each CT", FCVAR_PLUGIN, true, 0.1, true, 10.0);
	gShadow_Cvar_RatioGoal = 2.75;
	gH_Cvar_SoundName = CreateConVar("sm_jbtb_soundfile", "buttons/button11.wav", "The name of the sound to play when an action is denied",FCVAR_PLUGIN);
	strcopy(gShadow_Cvar_SoundName, PLATFORM_MAX_PATH, "buttons/button11.wav");
	gH_Cvar_ShowQueuePosition = CreateConVar("sm_jbtb_showqueue", "1", "Specifies whether clients see their queue position when using the guard command.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gShadow_Cvar_ShowQueuePosition = true;
	gH_Cvar_ShowClassPanel = CreateConVar("sm_jbtb_showclasses", "1", "Sets whether the class selection screen will be shown to players. 1-shows class menu, 0-stops menu from appearing.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gShadow_Cvar_ShowClassPanel = true;
	
	// create handles to the two global stacks & arrays we'll use
	gH_CTStack = CreateStack(1);
	gH_TempStack = CreateStack(1);
	gA_Terrorists = CreateArray(1);
	gA_GuardRequest = CreateArray(1);
	
	// Auto generates a config file, JailbreakTeamBalance.cfg, with default values
	// Old file 'jailbreak-teambalance.cfg' may be safely deleted
	AutoExecConfig(true, "JBTeamBalance");
	
	// Register the plugin's own commands
	RegConsoleCmd("sm_guard", Command_Guard);
	RegConsoleCmd("sm_unguard", Command_Unguard);
	RegAdminCmd("sm_clearguards", Command_ClearGuards, ADMFLAG_CUSTOM4, "sm_clearguards - Resets the guard queue");
	RegAdminCmd("sm_removeguard", Command_RemoveGuard, ADMFLAG_CUSTOM4, "sm_removeguard <player|#userid> - Removes target player from the guard queue");
	
	// Look for changes to act on
	HookUserMessage(GetUserMessageId("VGUIMenu"),Hook_VGUIMenu,true);
	
	HookConVarChange(gH_Cvar_Enabled, ConVarChanged_Global);
	HookConVarChange(gH_Cvar_RatioGoal, ConVarChanged_Global);
	HookConVarChange(gH_Cvar_SoundName, ConVarChanged_Global);
	HookConVarChange(gH_Cvar_ShowQueuePosition, ConVarChanged_Global);
	HookConVarChange(gH_Cvar_ShowClassPanel, ConVarChanged_Global);
	
	HookEvent("round_end",Event_RoundEnded,EventHookMode_Post);
	HookEvent("round_start",Event_RoundStarted,EventHookMode_Post);
	HookEvent("player_team",Event_PlayerTeamSwitch,EventHookMode_Pre);
	HookEvent("player_disconnect",Event_PlayerDisconnect,EventHookMode_Post);
	HookEvent("jointeam_failed", Event_JoinTeamFailed, EventHookMode_Pre);

	// Hook join & team change commands
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Command_Suicide, "kill");
	
	// Hook joinclass for debugging purposes
	#if DEBUG == 1
	AddCommandListener(Command_JoinClass, "joinclass");
	#endif
	
	// Zero out array
	for (new idx = 1; idx <= MaxClients; idx++)
	{
		g_bTalkedThisRound[idx] = false;
	}
	
	// Add menu integration for removeguard command
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
} // end OnPluginStart

public OnConfigsExecuted()
{
	// Update the shadow variables from the exec'd configs
	gShadow_Cvar_Enabled = GetConVarBool(gH_Cvar_Enabled);
	GetConVarString(gH_Cvar_SoundName, gShadow_Cvar_SoundName, sizeof(gShadow_Cvar_SoundName));
	gShadow_Cvar_RatioGoal = GetConVarFloat(gH_Cvar_RatioGoal);
	gShadow_Cvar_ShowQueuePosition = GetConVarBool(gH_Cvar_ShowQueuePosition);
	gShadow_Cvar_ShowClassPanel = GetConVarBool(gH_Cvar_ShowClassPanel);
	
	// Check for the prescence of other plugins 
	gH_CTBansStatus = FindConVar("sm_ctban_enable");
	gH_AzelphurTeamBanStatus = FindConVar("sm_teambans_version");
	
	if (gH_CTBansStatus != INVALID_HANDLE)
	{
		HookConVarChange(gH_CTBansStatus, ConVarChanged_Global);
		gShadow_CTBan = GetConVarInt(gH_CTBansStatus);
		if (gShadow_CTBan)
		{
			gH_BanCookie = RegClientCookie("Banned_From_CT", "Tells if you are restricted from joining the CT team", CookieAccess_Protected);
		}
	}

	if (gH_AzelphurTeamBanStatus != INVALID_HANDLE)
	{
		gH_AzlBanCookie = RegClientCookie("TeamBan_BanMask", "The team banmask.", CookieAccess_Private);
	}
	
	// Make sure we enforce the limitteams value if owner is running vanilla config	
	gH_LimitTeams = FindConVar("mp_limitteams");
	if (GetConVarInt(gH_LimitTeams) > 0)
	{
		SetConVarInt(gH_LimitTeams, 0);
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		gH_TopMenu = INVALID_HANDLE;
	}
}

public Action:Command_ClearGuards(client, args)
{
	if (args)
	{
		ReplyToCommand(client, CHAT_BANNER, "ClearGuards Usage");
		return Plugin_Handled;
	}

	ClearArray(gA_GuardRequest);
	ReplyToCommand(client, CHAT_BANNER, "Clear Guards");
	
	return Plugin_Handled;
}

public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == gH_TopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	gH_TopMenu = topmenu;
	
	/* Build the "Player Commands" category */
	new TopMenuObject:player_commands = FindTopMenuCategory(gH_TopMenu, ADMINMENU_PLAYERCOMMANDS);
	
	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(gH_TopMenu, 
			"sm_removeguard",
			TopMenuObject_Item,
			AdminMenu_RemoveGuard,
			player_commands,
			"sm_removeguard",
			ADMFLAG_CUSTOM4);
	}
}

public AdminMenu_RemoveGuard(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Remove from Queue");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayRemoveGuardMenu(param, GetArraySize(gA_GuardRequest));
	}
}

DisplayRemoveGuardMenu(Client, QueueSize)
{
	if (QueueSize == 0)
	{
		PrintToChat(Client, CHAT_BANNER, "Queue Empty");
	}
	else
	{
		new Handle:menu = CreateMenu(MenuHandler_RemoveGuard);
		
		SetMenuTitle(menu, "Remove Player from Guard Queue:");
		SetMenuExitBackButton(menu, true);
		
		new IndexPlayer = 0;
		for (new QueueIndex = 0; QueueIndex < QueueSize; QueueIndex++)
		{
			IndexPlayer = GetArrayCell(gA_GuardRequest, QueueIndex);
			decl String:sName[MAX_NAME_LENGTH];
			GetClientName(IndexPlayer, sName, sizeof(sName));
			decl String:sPlayerIndex[5];
			IntToString(IndexPlayer, sPlayerIndex, sizeof(sPlayerIndex));
			AddMenuItem(menu, sPlayerIndex, sName);	
		}
		
		DisplayMenu(menu, Client, 15);
	}
}

public MenuHandler_RemoveGuard(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if ((param2 == MenuCancel_ExitBack) && (gH_TopMenu != INVALID_HANDLE))
		{
			DisplayTopMenu(gH_TopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:sInfo[5];
		new target;
		GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
		target = StringToInt(sInfo);

		if (target == 0)
		{
			PrintToChat(param1, CHAT_BANNER, "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, CHAT_BANNER, "Unable to target");
		}
		else
		{
			// try to find target in guard queue
			new RemoveeIndex = FindValueInArray(gA_GuardRequest, target);
			
			if (RemoveeIndex == -1)
			{
				PrintToChat(param1, CHAT_BANNER, "Queue Not Found");
			}
			else
			{
				RemoveFromArray(gA_GuardRequest, RemoveeIndex);
				PrintToChat(param1, CHAT_BANNER, "Queue Removed Guard", target);	
			}
		}
	}
}

public Action:Command_RemoveGuard(client, args)
{
	new iQueueSize = GetArraySize(gA_GuardRequest);
	if (iQueueSize == 0)
	{
		ReplyToCommand(client, CHAT_BANNER, "Queue Empty");
		return Plugin_Handled;
	}
	
	if (!args)
	{
		if (client)
		{
			DisplayRemoveGuardMenu(client, iQueueSize);
		}
		else
		{
			ReplyToCommand(client, CHAT_BANNER, "Not Available from Server");
		}
		return Plugin_Handled;
	}
	
	decl String:sArgument[65];
	GetCmdArg(1, sArgument, sizeof(sArgument));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	target_count = ProcessTargetString(
			sArgument,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml);

	if (target_count != 1)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	// try to find target in guard queue
	new RemoveeIndex = FindValueInArray(gA_GuardRequest, target_list[0]);
	
	if (RemoveeIndex == -1)
	{
		ReplyToCommand(client, CHAT_BANNER, "Queue Not Found");
		return Plugin_Handled;
	}
	
	RemoveFromArray(gA_GuardRequest, RemoveeIndex);
	ReplyToCommand(client, CHAT_BANNER, "Queue Removed Guard", target_list[0]);
	
	return Plugin_Handled;
}

public ConVarChanged_Global(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	// Ignore changes which result in the same value being set
	if (StrEqual(oldValue, newValue, true))
	{
		return;
	}
	
	// Perform separate integer checking for booleans
	new iNewValue = StringToInt(newValue);
	new iOldValue = StringToInt(oldValue);
	new bool:b_iNoChange = false;
	if (iNewValue == iOldValue)
	{
		b_iNoChange = true;
	}

	if (!b_iNoChange && (cvar == gH_Cvar_Enabled))
	{
		if (iNewValue != 1)
		{
			UnhookEvent("round_end",Event_RoundEnded,EventHookMode_Post);
			UnhookEvent("round_start",Event_RoundStarted,EventHookMode_Post);
			UnhookEvent("player_team",Event_PlayerTeamSwitch,EventHookMode_Post);
			UnhookEvent("player_disconnect",Event_PlayerDisconnect,EventHookMode_Post);
		}
		else
		{
			HookEvent("round_end",Event_RoundEnded,EventHookMode_Post);
			HookEvent("round_start",Event_RoundStarted,EventHookMode_Post);
			HookEvent("player_team",Event_PlayerTeamSwitch,EventHookMode_Pre);
			HookEvent("player_disconnect",Event_PlayerDisconnect,EventHookMode_Post);
		}
	
		gShadow_Cvar_Enabled = bool:iNewValue;
	}
	else if (cvar == gH_Cvar_RatioGoal)
	{
		gShadow_Cvar_RatioGoal = StringToFloat(newValue);
	}
	else if (cvar == gH_Cvar_SoundName)
	{
		strcopy(gShadow_Cvar_SoundName, PLATFORM_MAX_PATH, newValue);
	}
	else if (!b_iNoChange && (cvar == gH_Cvar_ShowQueuePosition))
	{
		gShadow_Cvar_ShowQueuePosition = bool:iNewValue;
	}
	else if (!b_iNoChange && (cvar == gH_Cvar_ShowClassPanel))
	{
		if (!iNewValue)
		{
			HookUserMessage(GetUserMessageId("VGUIMenu"),Hook_VGUIMenu,true);
		}
		else
		{
			UnhookUserMessage(GetUserMessageId("VGUIMenu"),Hook_VGUIMenu,true);			
		}
		gShadow_Cvar_ShowClassPanel = bool:iNewValue;
	}
	else if (cvar == gH_CTBansStatus)
	{
		gShadow_CTBan = bool:iNewValue;
	}
}

public Action:Command_Guard(client, args)
{
	// check to make sure the client isn't already a CT
	if (GetClientTeam(client) != CS_TEAM_CT)
	{
		if (IsCTBanned(client))
		{
			if (strcmp(gShadow_Cvar_SoundName, ""))
			{
				decl String:buffer[PLATFORM_MAX_PATH + 5];
				Format(buffer, sizeof(buffer), "play %s", gShadow_Cvar_SoundName);
				ClientCommand(client, buffer);
			}
			PrintToChat(client, CHAT_BANNER, "CT Bans Denied");
			return Plugin_Handled;
		}
		
		// check if requester is already in the queue
		new QueuePosition = FindValueInArray(gA_GuardRequest, client);
		if (QueuePosition == -1)
		{
			// count people on CT
			new numCTs = GetTeamClientCount(CS_TEAM_CT);
			
			if (numCTs != 0)
			{
				new GRindex = PushArrayCell(gA_GuardRequest, client) + 1;
				if (gShadow_Cvar_ShowQueuePosition)
				{
					PrintToChat(client, CHAT_BANNER, "Queue Added Position", GRindex);
				}
				else
				{
					PrintToChat(client, CHAT_BANNER, "Queue No Position Added");
				}
			}
			else
			{
				// this often occurs at the beginning of a map
				CS_SwitchTeam(client, CS_TEAM_CT);
				ForcePlayerSuicide(client);
				PrintToChat(client, CHAT_BANNER, "Request Processed");
			}
		}
		else
		{
			if (gShadow_Cvar_ShowQueuePosition)
			{
				PrintToChat(client, CHAT_BANNER, "Queue Position", QueuePosition+1);
			}
			else
			{
				PrintToChat(client, CHAT_BANNER, "Queue InQueue");
			}
		}
	}
	else
	{
		PrintToChat(client, CHAT_BANNER, "Queue CT");
	}
	
	return Plugin_Handled;
} //end Command_Guard

public Action:Command_Unguard(client, args)
{
	new RemoveeIndex = FindValueInArray(gA_GuardRequest, client);
			
	if (RemoveeIndex == -1)
	{
		ReplyToCommand(client, CHAT_BANNER, "Queue Not Found");
		return Plugin_Handled;
	}
	
	RemoveFromArray(gA_GuardRequest, RemoveeIndex);
	ReplyToCommand(client, CHAT_BANNER, "Queue Removed Guard", client);
	
	return Plugin_Handled;
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientID = GetClientOfUserId(GetEventInt(event, "userid"));

	// remove from guard request list if they were in it
	new FindValueIndex = FindValueInArray(gA_GuardRequest, clientID);
	if (FindValueIndex != -1)
	{
		RemoveFromArray(gA_GuardRequest, FindValueIndex);
	}
	
	return Plugin_Handled;
}

public Action:Event_RoundEnded(Handle:event, const String:name[], bool:dontBroadcast)
{
	gLastRoundEndReason = GetEventInt(event, "reason");

	// lock team changes
	gTeamsLocked = true;
	
	gOneRoundPlayed = true;

	// clear T array
	ClearArray(gA_Terrorists);

	// consider making global variables and moving this to jointeam cmd
	// count people in T and CT teams
	new numTs = 0;
	new numCTs = 0;

	// check if VoiceHook is installed (crude method but effective in JB servers)
	// it's preferable to check a cvar or file but this is the cheapest method
	new bool:bVoiceHook = false;
	for (new Pidx = 1; Pidx <= MaxClients; Pidx++)
	{
		if (g_bTalkedThisRound[Pidx])
		{
			bVoiceHook = true;
		}
	}
   
	for (new idx = 1; idx <= MaxClients; idx++)
	{
		// check if person is in game and not in spec
		if (IsClientInGame(idx))
		{
			new indexTeam = GetClientTeam(idx);
			if (indexTeam == CS_TEAM_T)
			{
				if (!IsCTBanned(idx))
				{
					if (bVoiceHook)
					{
						if (g_bTalkedThisRound[idx])
						{
							PushArrayCell(gA_Terrorists, idx);
						}
						//  debug the voicehook mm:s plugin/extension
						#if DEBUG == 1
						else
						{
							LogMessage("VH: excluded T %N for not using their mic this round", idx);
						}
						#endif
					}
					else
					{
						PushArrayCell(gA_Terrorists, idx);
					}
				}
				numTs++;
			}
			else if (indexTeam == CS_TEAM_CT)
			{
				numCTs++;
			}
		} // end if client in game

		// reset global voicehook bools
		g_bTalkedThisRound[idx] = false;
	} // end for idx

	// check for empty CT team
	if (numCTs == 0)
	{
		gOneRoundPlayed = false;
		gOneJoined = false;
	}
   
	g_iActivePlayers = numTs + numCTs;
	// make sure server isn't empty
	if (numCTs < 2 && numTs == 0)
	{
		return Plugin_Continue;
	}

	// let's take a look how many CT's we need
	new TargetNumCTs = RoundToFloor(g_iActivePlayers / (gShadow_Cvar_RatioGoal + 1));
	if (TargetNumCTs == 0) TargetNumCTs = 1;
   
	new numToMove = 0;
	new Switch_ID = 0;

	// find if changes need to be made
	if (numCTs < TargetNumCTs)
	{
		// move Ts to CT
		numToMove = TargetNumCTs - numCTs;
		
		for (new t = 0; t < numToMove; t++)
		{
			//Check the request queue (!guard) for people trying to become CT
			if (GetArraySize(gA_GuardRequest) != 0)
			{
				// act like a queue
				Switch_ID = GetArrayCell(gA_GuardRequest,0);
				RemoveFromArray(gA_GuardRequest, 0);
				  
				if (IsClientInGame(Switch_ID))
				{
					if (!IsFakeClient(Switch_ID))
					{
						PrintToChat(Switch_ID, CHAT_BANNER, "Request Processed");
					}
					CS_SwitchTeam(Switch_ID,CS_TEAM_CT);
					  
					// remove them from terrorists array (consider they might have been spectator)
					new FindValueIndex = FindValueInArray(gA_Terrorists, Switch_ID);
					if (FindValueIndex != -1)
					{
						RemoveFromArray(gA_Terrorists, FindValueIndex);
					}
				}
			}
			else if (GetArraySize(gA_Terrorists) != 0)
			{
				// grab random T
				new RandomIndex = GetRandomInt(0, GetArraySize(gA_Terrorists) - 1);
				
				Switch_ID = GetArrayCell(gA_Terrorists, RandomIndex);
				RemoveFromArray(gA_Terrorists, RandomIndex);
				
				// let them know they were changed
				if (!IsFakeClient(Switch_ID))
				{
					PrintToChat(Switch_ID, CHAT_BANNER, "Random to CT");
				}
				CS_SwitchTeam(Switch_ID,CS_TEAM_CT);
				numTs--;
			}
		}
	}
	//else if (numTs < TargetNumTs)
	else if (numCTs > TargetNumCTs)
	{
		// move CTs to T
		numToMove = numCTs - TargetNumCTs;

		for (new t = 0; t < numToMove; t++)
		{
			// check if the stack is empty before we pop a value
			if (!IsStackEmpty(gH_CTStack))
			{
				PopStackCell(gH_CTStack,Switch_ID);
				// push it back on the stack so the change team can pop it
				PushStackCell(gH_CTStack,Switch_ID);

				if (!IsFakeClient(Switch_ID))
				{
					PrintToChat(Switch_ID, CHAT_BANNER, "Stacked to T");
				}
				CS_SwitchTeam(Switch_ID,CS_TEAM_T);
			}
		}
	}
	return Plugin_Continue;
} // end Event_RoundEnded

public OnMapStart()
{
   gLastRoundEndReason = REASON_INVALID;
   
   gOneJoined = false;
   gOneRoundPlayed = false;
   
   g_iNumCTsDuringRound = 0;
   //account for late load
   for (new i = 1; i <= MaxClients; i++)
   {
	   if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
	   {
		   gOneJoined = true;
		   g_iNumCTsDuringRound++;
	   }
   }
   
   // clear the stacks
   for (;;)
   {
	  if (IsStackEmpty(gH_CTStack))
	  {
		 break;
	  }
	  PopStack(gH_CTStack);
   }
   for (;;)
   {
	  if (IsStackEmpty(gH_TempStack))
	  {
		 break;
	  }
	  PopStack(gH_TempStack);
   }
   
   ClearArray(gA_GuardRequest);
   
   // pre-cache deny sound
   if(strcmp(gShadow_Cvar_SoundName, ""))
   {
		decl String:sBuffer[PLATFORM_MAX_PATH];
		PrecacheSound(gShadow_Cvar_SoundName, true);
		Format(sBuffer, sizeof(sBuffer), "sound/%s", gShadow_Cvar_SoundName);
		AddFileToDownloadsTable(sBuffer);
   }
}

public Action:Event_PlayerTeamSwitch(Handle:event, const String:name[], bool:dontBroadcast)
{
   new NewTeam = GetEventInt(event, "team");
   new OldTeam = GetEventInt(event, "oldteam");
   new bool:Disconnect = GetEventBool(event, "disconnect");
   new UserID = GetEventInt(event, "userid");
   new clientID = GetClientOfUserId(UserID);
   
   new joined = gOneJoined ? 1 : 0;
   LogMessage("%N: oldteam: %d, newteam: %d, gOneJoined: %d", clientID, OldTeam, NewTeam, joined);
   if (OldTeam == CS_TEAM_NONE && NewTeam == CS_TEAM_CT && GetTeamClientCount(CS_TEAM_CT) != 0)
   {
		LogMessage("swapping %N to T", clientID);
		CreateTimer(0.0, Timer_SwapFirstJoin, UserID);
		return Plugin_Handled;
   }
   
   // remove userid from old team
   if (OldTeam == CS_TEAM_CT)
   {
	  g_iNumCTsDuringRound--;
	  
	  // check if there's no more CTs
	  if (g_iNumCTsDuringRound <= 0)
	  {
		gOneJoined = false;
		gOneRoundPlayed = false;
	  }
	  
	  // find the CT in the stack and remove her/him
	  new TempStackSize = 0;
	  new TempClient = 0;
	  for(;;)
	  {
	      PopStackCell(gH_CTStack, TempClient);
	
	      if (TempClient == clientID)
	      {
	         // rebuild CT stack
	         for (new tsi = 0; tsi < TempStackSize; tsi++)
	         {
	            PopStackCell(gH_TempStack,TempClient);
	            PushStackCell(gH_CTStack,TempClient);
	         }
	         break;
	      }
	      
	      if (IsStackEmpty(gH_CTStack))
	      {
	         break;
	      }  
	          
		  // insert it into the temp stack
	      PushStackCell(gH_TempStack,TempClient);     	 
	      TempStackSize++;
	  } // 'end' infinite loop
   }
   
   if (Disconnect == true)
   {
	  // remove from guard request list if they were in it
	  new FindValueIndex = FindValueInArray(gA_GuardRequest, clientID);
	  if (FindValueIndex != -1)
	  {
		RemoveFromArray(gA_GuardRequest, FindValueIndex);
	  }
   }
   else
   {
	   // find new team
	   if (NewTeam == CS_TEAM_CT)
	   {
	      PushStackCell(gH_CTStack,clientID);
	   }
   }
   return Plugin_Continue;
} // end Event_PlayerTeamSwitch

public Action:Event_RoundStarted(Handle:event, const String:name[], bool:dontBroadcast)
{	
	// count and track people on CT before teams are unlocked
	new numCTs = 0;
	for (new idx = 1; idx <= MaxClients; idx++)
	{
		if (IsClientInGame(idx))
		{
			if (GetClientTeam(idx) == CS_TEAM_CT)
			{
				PushStackCell(gH_TempStack, idx);
				numCTs++;
			}
		}
		g_bSuicided[idx] = false;
	} // end for idx
	
	// fire a timer to handle any respawns that don't occur
	// or those who want to swap back to T after a random switch
	CreateTimer(7.5, Timer_RespawnSwapped, numCTs, TIMER_FLAG_NO_MAPCHANGE);
	
	// keep track of number of CTs during a round, starting now
	g_iNumCTsDuringRound = numCTs;
	
	if (numCTs == 0)
	{
		gOneJoined = false;
		gOneRoundPlayed = false;
	}
	
	// unlock team changes
	gTeamsLocked = false;
		
	return Plugin_Handled;
} // end Event_RoundStarted

public Action:Timer_RespawnSwapped(Handle:timer, any:numberCTs)
{
	// only respawn those CTs who were there before teams were locked
	new TempClient = 0;
	for (new CTidx = 0; CTidx < numberCTs; CTidx++)
	{
	   PopStackCell(gH_TempStack,TempClient);
	   if (IsClientInGame(TempClient))
	   {
	    if (!IsPlayerAlive(TempClient) && (GetClientTeam(TempClient) == CS_TEAM_CT))
	    {
	    	CS_RespawnPlayer(TempClient);
	    }
	   }
	} // end for CTidx
	// respawn any T who is dead
	for (new idx = 1; idx <= MaxClients; idx++)
	{
	 if (IsClientInGame(idx))
	 {
	 	if ((GetClientTeam(idx) == CS_TEAM_T) && !IsPlayerAlive(idx) && !g_bSuicided[idx])
	 	{
	 		CS_RespawnPlayer(idx);
	 	}
	 }      
	} // end for idx
}

// this function is present for debugging purposes
#if DEBUG == 1
public Action:Command_JoinClass(client, const String:command[], args)
{
	decl String:classString[5];
	GetCmdArg(1, classString, sizeof(classString));
	new Target_Class = StringToInt(classString);
	if ((Target_Class != 3) && (Target_Class != 5))
	{
		LogMessage("%N did joinclass: %d", client, Target_Class);
	}
	return Plugin_Continue;
}
#endif

public Action:Timer_DetermineRoundDraw(Handle:timer)
{
	// if the we're NOT inbetween round_start and round_end
	if (!gTeamsLocked)
	{
		// count alive players and total players on each team
		new CTs = GetTeamClientCount(CS_TEAM_CT);
		new Ts = GetTeamClientCount(CS_TEAM_T);
		new AliveCTs = 0;
		new AliveTs = 0;
		
		for (new idx = 1; idx <= MaxClients; idx++)
		{
			if (IsClientInGame(idx) && IsPlayerAlive(idx))
			{
				switch (GetClientTeam(idx))
				{
					case CS_TEAM_CT:
					{
						AliveCTs++;
					}
					case CS_TEAM_T:
					{
						AliveTs++;
					}
				}
			}
		}
		
		if ((CTs > 0 && AliveCTs == 0) || (Ts >0 && AliveTs == 0))
		{
			CS_TerminateRound(0.0, CSRoundEnd_Draw, true);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_JoinTeam(client, const String:command[], args)
{
	// Check to see if the client is valid and JBTB is enabled
	if(!client || !IsClientInGame(client) || IsFakeClient(client) || !gShadow_Cvar_Enabled)
	{
		return Plugin_Continue;
	}
	
	// Create timer to determine if we should fire a round draw manually
	CreateTimer(0.1, Timer_DetermineRoundDraw, _, TIMER_FLAG_NO_MAPCHANGE);
	
	// Get the target team
	decl String:teamString[3];
	GetCmdArg(1, teamString, sizeof(teamString));
	new Target_Team = StringToInt(teamString);
	// Get the players current team
	new Current_Team = GetClientTeam(client);
	
	LogMessage("%N: Current team: %d, Target team: %d", client, Current_Team, Target_Team);
	//target team 0 = disconnect
	if (Target_Team == 0)
	{
		CS_SwitchTeam(client, CS_TEAM_T);
		return Plugin_Handled;
	}
	// Check to see if the team request is valid
	if (Current_Team == Target_Team)
	{
		return Plugin_Handled;
	}
	
	// check if teams are currently locked and it's not the beginning of the game
	if (gTeamsLocked && (gLastRoundEndReason != REASON_INVALID) && (gLastRoundEndReason != REASON_GAME_COMMENCING) && (gLastRoundEndReason != REASON_ROUND_DRAW))
	{	
		if(strcmp(gShadow_Cvar_SoundName, ""))
		{
			decl String:buffer[PLATFORM_MAX_PATH + 5];
			Format(buffer, sizeof(buffer), "play %s", gShadow_Cvar_SoundName);
			ClientCommand(client, buffer);
		}
		PrintCenterText(client, "%t", "Center Teams Locked");			
		CS_SwitchTeam(client, CS_TEAM_T);
		return Plugin_Handled;
	} // end if teams locked
	if (Current_Team == CS_TEAM_CT && Target_Team == CS_TEAM_T)
	{
		ForcePlayerSuicide(client);
		return Plugin_Continue;
	}
	// allow one person to join CT when map first starts or CT team is empty
	if (Target_Team == CS_TEAM_CT && !gOneJoined && !gOneRoundPlayed)
	{
		gOneJoined = true;
		return Plugin_Continue;
	}
	
	// disable auto-join 
	if (!((Target_Team == CS_TEAM_T) || (Target_Team == CS_TEAM_CT) || (Target_Team == CS_TEAM_SPECTATOR)))
	{	
		if(strcmp(gShadow_Cvar_SoundName, ""))
		{
			decl String:buffer[PLATFORM_MAX_PATH + 5];
			Format(buffer, sizeof(buffer), "play %s", gShadow_Cvar_SoundName);
			ClientCommand(client, buffer);
		}
		CS_SwitchTeam(client, CS_TEAM_T);
		ForcePlayerSuicide(client);
		return Plugin_Handled;	
	}
	
	// disable joining CT with people waiting in queue
	if (Target_Team == CS_TEAM_CT)
	{
		if(strcmp(gShadow_Cvar_SoundName, ""))
		{
			decl String:buffer[PLATFORM_MAX_PATH + 5];
			Format(buffer, sizeof(buffer), "play %s", gShadow_Cvar_SoundName);
			ClientCommand(client, buffer);
		}
		CS_SwitchTeam(client, CS_TEAM_T);
		PrintCenterText(client, "%t", "Center Guard");
		return Plugin_Handled;
	}
	
	// we've passed all the checks, now get ready to call joinclass if we're not showing the classes screen
	if (!gShadow_Cvar_ShowClassPanel)
	{
		new Handle:JoinClassPack = CreateDataPack();
		WritePackCell(JoinClassPack, client);
		WritePackCell(JoinClassPack, Target_Team);
		CreateTimer(0.0, Timer_ForceJoinClass, JoinClassPack);
	}
	
	// If we get to here then all is for the good
	return Plugin_Continue;
} // end Command_JoinTeam

public Action:Timer_ForceJoinClass(Handle:timer, Handle:JoinClassPack)
{
	ResetPack(JoinClassPack);
	new client = ReadPackCell(JoinClassPack);
	new Team = ReadPackCell(JoinClassPack);

	// these models here were chosen so they support attachables
	// in case the server doesn't run an SM model menu and has classes disabled
	if (Team == CS_TEAM_T)
	{
		// arctic model
		FakeClientCommand(client, "joinclass 3");
	}
	else if (Team == CS_TEAM_CT)
	{
		// urban model
		FakeClientCommand(client, "joinclass 5");
	}
	
	CloseHandle(JoinClassPack);
}

public Action:Hook_VGUIMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new String:sPanelName[10];
	
	if (GetUserMessageType() == UM_Protobuf)
	{
		PbReadString(bf, "name", sPanelName, sizeof(sPanelName));
	}
	else
	{
		BfReadString(bf, sPanelName, sizeof(sPanelName));
	}

	// find any class panels
	if(StrContains(sPanelName, "class") != -1)
	{
		new bShow = BfReadByte(bf);
		if(bShow)
		{
			// hide class screen
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public OnClientSpeaking(client)
{
	g_bTalkedThisRound[client] = true;
}

public Action:Event_JoinTeamFailed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;

	ChangeClientTeam(client, CS_TEAM_T);
	return Plugin_Handled;
}

IsCTBanned(client)
{
	if (gH_CTBansStatus != INVALID_HANDLE)
	{
		// check if client cookie is loaded (if not, Team Bans will take care of it)
		if (AreClientCookiesCached(client) && gShadow_CTBan)
		{
			decl String:cookie[5];
			GetClientCookie(client, gH_BanCookie, cookie, sizeof(cookie));
			
			if (StrEqual(cookie, "1")) 
			{
				return true;
			}
		} // end Are Cookies Cached?
	} // end Team Bans check
	else if (gH_AzelphurTeamBanStatus != INVALID_HANDLE)
	{
		decl String:sCookie[5];
		GetClientCookie(client, gH_AzlBanCookie, sCookie, sizeof(sCookie));
		new iBanMask = StringToInt(sCookie);
		if (1<<CS_TEAM_CT & iBanMask) 
		{
			return true;
		} // end If CT Banned
	}
	return false;
}

public Action:Timer_SwapFirstJoin(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client)
	{
		CS_SwitchTeam(client, CS_TEAM_T);
		ForcePlayerSuicide(client);
		LogMessage("%N swapped to T", client);
	}
	return Plugin_Stop;
}

public Action:Command_Suicide(client, const String:command[], args)
{
	// we don't want people to be able to change cells just by suiciding
	g_bSuicided[client] = true;
}