/*
*	Description:
*		Plugin that will dynamically set the HP of bots and quota based on players joined and 
*		difference between bots and humans scores.
*		
*		This plugin was based off of the not publicly released metamod plugin Adaptive Bots by Old and Slow (https://forums.alliedmods.net/member.php?u=15225)
*		I did not have access to the sourcecode and this was designed off of my experience playing on a server that had this plugin.
*		
*		It's a fun plugin and I wanted others to enjoy this type of gameplay.
*
*	Versions:
*		.0
*			* Initial beta release after alpha testing
*			
*		.1
*			* Enhanced iBotsQuota
*			* Added a join advertisement
*			* Fixed PlayerReachedOneHundred multi-kill bug and now it correcly changes the bot_difficulty
*			* Cosmetic changes to in-game messages
*			* Began using SMLIB
*			
*		.2
*			* fixed client 0 invalid error in OnJoinTeam code
*			* enhanced round end detection (now if time runs out, or max rounds is met, or whatever, the code to alter the bot_difficulty will execute)
*			* Changed PlayerReachedOneHundred() to MapHasEnded()
*			* started using a config file for plugin settings
*			
*		.3
*			* Modified some end of round event code to enhance the display of the winner
*			* Modified the advertise strings to better enhance its viewing
*			* Changed from using keyhinttext to just hinttext
*			
*		.4
*			* Fixed bot_quota loop when max bot quota was reached it got stuck in a loop
*			
*		.5
*			* added server command to set mp_fraglimit to what iBots_maxfrags is set to
*			
*		.5a
*			* added +HP to killers
*			
*		.5b
*			* fixed HP not going down
*			
*		.6
*			* cleaned up code a little and cvar junk
*			* added HookConVarChange
*			
*		.6a
*			* Enhanced round end capability to detect time limit reached
*			* added cs_win_panel_match hookevent
*			
*		.6b
*			* Changed the way !snipers was responded to - removed the hook for say and say_team and added RegConsoleCmd
*			
*		.7
*			* Fixed CLIENT = 0 bug with iBots command
*			
*		.7.1
*			* Minor code changes and cleanup prior to public release
*			
*		1.0.0
*			* Initial public release
*			* Removed include for smlib and just put the functions in the plugin directly so it will compile on the web compiler 
*				- Thanks goes to berni for the SMLib functions - great job on that
*				
*		1.0.1
*			* Some code clean up and optimization - trying to get this plugin approved :)
*			* Fixed up the team joining code to be a bit more streamlined
*			
*		1.0.2
*			* Added translation file
*
*		1.0.3	* Enhanced the team join handling
*			* Added last bot beacon
*		
*		1.0.4
*			* Added admin command to change the iBots HP on the fly
*			* Fixed the bot beacon issue where it would get multiple beacons if it was the last bot and it killed a human
*			* Change the MinBotQuota to retain the minimum number of bots until the ratio caused it to increase.
*
*		1.0.5
*			* Added HP bonus based on difficulty level of the bot
*		
*		1.0.6
*			* Added/Modified CVars so admins can disable parts of the mod.
*		
*		1.0.7
*			* Fixed bug with spectators
*		
*		1.0.8
*			* Added carry-over HP for humans
*		
*		1.0.9
*			* Added Super Nades
*			* Added check to see how many reserved slots there are to help negate the bot join/part bug
*		
*		1.1.0
*			* Fixed bug with Nade Multiplier not resetting and error when sm_ibots was typed in console
*
*		Version 1.1.1.0
* 			*	Added CVar to enable/disable the mp_maxfrags option
* 				-	Now, plugin will announce the highest winner on Event_RoundEnd if the iBots_usemaxfrags is 0
* 			*	Went from 3 digit version to 4 digit version
* 			+	Added Updater functionality
* 			*	Plugin now requires SourceMod 1.4.4 or higher due to the 07/02/2012 CS:S Update
* 
* 		Version 1.1.1.1
* 			+	Added CVar to turn on/off ignited nades (they don't ignite any players, yet)
* 
* 		Version 1.1.1.2
* 			*	Fixed JoinPartMode 3 issue where bot_quota sometimes wouldn't be adjusted.
* 			+	Added Friendly Fire Mode - see new CVar iBots_ffmode
* 
* 		Version 1.1.1.3
* 			-	Removed CS_SetTeamScore until it's in an official release of SourceMod
* 
* 		Version 1.1.1.4
* 			*	Changed jointeam to ensure humans cannot join bot team and bots cannot join human team.
* 			+	Added dynamic bot_difficulty
* 
* 		Version 1.1.1.5
* 			*	Changed from <colors> to <morecolors> so we can have any color chat.
* 
* 		Version 1.2.0.0
* 			+	Added support for CS:GO
* 				*	Taking control of a bot is disabled
* 			+	Added automatic CVar handling for bot_prefix and team management (mp_humanteam, bot_prefix <skill> <difficulty>)
* 			*	Optimized code a bit
* 
* 		Version 1.2.0.1
* 			*	Fixed bug with rounds restarting when bot's difficulty changed.
* 
* 		Version 1.2.1.0
* 			*	Changed the way CVar messages for bot_quota and bot_difficulty are supressed.
* 
* 		Version 1.2.1.1
* 			+	Added reverting changed server variables back to original when plugin is unloaded.
*			*	Changed OnTakeDamage for FF to use Plugin_Handled instead of Changed
*			* 
*
* 		Version 1.2.2.1
* 			+	Added ability to take control of a bot when you die in CS:GO
* 
* 		Version 1.2.2.2
* 			+	Added Humans and Bots StreakDiff so server admins can define when their difficulty starts to increase or decrease
* 
* 		Version 1.3.0.0
* 			+	Added ability to take over bots on CS:S
* 				*	Configurable with CVars and VIP enabled
* 
* 		Version 1.3.0.1
* 			+	Added configurable number of times players (VIP and non-VIP) can take over a bot.
* 
* 		Version 1.3.0.2
* 			+	Added two CVars - one for beacon and one for BotMaxHP.
* 			*	Fixed issue when ModifyHP being set to 0 causing the game to not count wins and losses (streaks).
* 			*	Fixed TEAM_BOT CVar so when it's switched it will swap all players to the correct side.
* 
* 		Version 1.3.0.3
* 			+	Added the autoexecconfig include - thanks goes to Impact123 (https://forums.alliedmods.net/showthread.php?t=204254)
* 
* 		Version 1.3.0.4
* 			*	Hotfix for AutoExecConfig_CleanFile - Now using SetAppend to check if the config was appended before attempting to clean the file since
* 				it's so expensive of an operation.
* 
* 		Version 1.3.0.5
* 			*	Recompile with updated AutoExecConfig include file which added support for multiline comments
* 			+	Added translation phrases for bot take over messages
* 				+	Added a CVar to control the bot takeover message
* 			*	Fixed error for CS:GO in cmd_iBots due to KeyHintText
* 
* 		Version 1.3.0.6
* 			*	Fixed plugin to not use KeyHintText for CS:GO
* 
* 		Version 1.3.0.7
* 			*	Fixed bool check from false to true for if game is CS:GO to not use PrintKeyHintText
* 
* 		Version 1.3.0.8
* 			*	Fixed StartingBotDiff not working (thanks to coty9090 for reporting it)
*
*	Credits
*		*	Lots of people... I've been working on this plugin on and off and have been reading a lot of posts and looking at different
*			plugins to achieve what it is this plugin is all about.  Thank you to all of the people who support sourcemod and the plugins
*			
*			Thanks to berni for the SMLib function set :)
*
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colors>
#include <sdkhooks>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_VERSION "1.3.0.8"
#define PLUGIN_ANNOUNCE "{green}[{lightgreen}iBots{green}] v1.3.0.8 by TnTSCS"
#define PLUGIN_ANNOUNCE2 "[iBots] v1.3.0.8 by TnTSCS"

#define UPDATE_URL "http://dl.dropbox.com/u/3266762/ibots.txt"

#define SOUND_BLIP		"buttons/blip1.wav"
#define SOUND_BEEP		"buttons/button17.wav"
#define BLOCKED_WEAPONS	"buttons/weapon_cant_buy.wav"

#define MAX_WEAPON_STRING	80

#define	MAX_WEAPON_SLOTS	6

#define HEGrenadeOffset 	11	// (11 * 4)
#define FlashbangOffset 	12	// (12 * 4)
#define SmokegrenadeOffset	13	// (13 * 4)

#define _DEBUG 0 // Set to 1 for debug spew

new bool:b_MapIsOver = false;

new Float:f_iBotsQuota = 0.0;

new Handle:h_ClientAdvertise[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:ClientTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:BeaconTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

new MinQuota, MinHP, iBotsHPIncrease, iBotsHPDecrease, MaxFrags, MaxBots, HumanWinningStreak, HumansStreakMoney,
	BotWinningStreak, BotsStreakMoney, StreakMoney, WinningDifference, BotDifficulty, FinalDiff_Bots, FinalDiff_Humans,
	AdvertiseInterval, TEAM_BOT, TEAM_HUMAN;

new iBotsHealth = 100;
new score_bot = 0;
new score_human = 0;
new BotsWinStreak = 0;
new HumansWinStreak = 0;
new Advertisetime = 0;
new FragCount[MAXPLAYERS+1] = {0, ...};
new bool:MapIsDone = false;
new bool:UseUpdater = false;

new Handle:botteam = INVALID_HANDLE;
new Handle:humanteam = INVALID_HANDLE;

new Handle:ibot_quota = INVALID_HANDLE;
new Handle:ibot_fraglimit = INVALID_HANDLE;
new Handle:ibot_difficulty = INVALID_HANDLE;
new Handle:ibot_restartgame = INVALID_HANDLE;
new Handle:reservedslots = INVALID_HANDLE;

new Handle:botsprefix = INVALID_HANDLE;
new String:OrgPrefix[MAX_NAME_LENGTH];
new String:NewPrefix[MAX_NAME_LENGTH];
new String:Orgbotteam[5];
new String:Orghumanteam[5];

new g_BeamSprite = -1;
new g_HaloSprite = -1;

new EasyBonus, FairBonus, NormalBonus, ToughBonus, HardBonus, VeryHardBonus, ExpertBonus, EliteBonus;
new Float:KnifeBonusMultiplier = 1.0;

new bool:ModifyHP = true;
new bool:HPBonus = true;
new JoinPartMode = 1;
new ireservedslots;
new ClientHP[MAXPLAYERS+1];

new bool:UseSuperNades = false;
new Float:NadeMultiplyer = 1.0;
new Float:NadeMultiplyerIncrease = 0.20;
new Float:NadeMultiplyerDecrease = 0.15;
new bool:ManageBots = true;
new bool:UseMaxFrags = false;
new bool:UseIgnitedNades = false;
new bool:IsVIP[MAXPLAYERS+1] = {false, ...};
new FFMode = 0;

new Handle:BotQuotaTimer = INVALID_HANDLE;

new BotDifficultyChangeable = 0;
new AdjustBotDiff = 1;
new StartingBotDiff;
new Orgbotquota, Orgfraglimit, bool:IsCSGO;
new bool:AllowBotControl = true;
new bool:AllHumansDead = true;
new HumansStreakDiff, BotsStreakDiff;

new String:PrimarySlot[MAXPLAYERS+1][MAX_WEAPON_STRING];
new String:SecondarySlot[MAXPLAYERS+1][MAX_WEAPON_STRING];
new HEGrenades[MAXPLAYERS+1];
new FlashBangs[MAXPLAYERS+1];
new SmokeGrenades[MAXPLAYERS+1];
new Handle:NoEndRoundHandle = INVALID_HANDLE;
new bool:HideDeath[MAXPLAYERS+1];
new bool:IsControllingBot[MAXPLAYERS+1];
new Float:RestartRoundTime;
new String:PlayerOldSkin[MAXPLAYERS+1][PLATFORM_MAX_PATH];
new bool:AllowedToControlBot[MAXPLAYERS+1];
new BotControlTimes[MAXPLAYERS+1];

new BotControlTimesVIP, BotControlTimesREG, BotMaxHP, BotControlMsg, bool:UseBeacon, bool:IsClientAdmin[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "iBots",
	author = "TnTSCS aka ClarkKent",
	description = "Interactive CSS/GO gameplay for Bots vs Humans with reactive bot_quota and bot health",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

/**
 * Called when the plugin is fully initialized and all known external references 
 * are resolved. This is only called once in the lifetime of the plugin, and is 
 * paired with OnPluginEnd().
 *
 * If any run-time error is thrown during this callback, the plugin will be marked 
 * as failed.
 *
 * It is not necessary to close any handles or remove hooks in this function.  
 * SourceMod guarantees that plugin shutdown automatically and correctly releases 
 * all resources.
 *
 * @noreturn
 */
public OnPluginStart()
{
	// Create CVars
	CreateMyCVars();
	
	// Hook Needed Events
	HookEvent("cs_win_panel_match", 	OnCSWinPanelMatch);
	HookEvent("round_end", 				OnRoundEnd);
	HookEvent("round_start", 			OnRoundStart);
	HookEvent("player_team", 			OnTeamJoin, 		EventHookMode_Pre);	
	HookEvent("game_start", 			OnGameStart);
	HookEvent("player_death", 			OnPlayerDeath,		EventHookMode_Pre);
	HookEvent("bomb_defused", 			OnBombDefused);
	HookEvent("player_spawn",			OnPlayerSpawn);
	HookEvent("player_connect", 		OnPlayerConnect, 	EventHookMode_Pre);
	HookEvent("player_activate", 		OnPlayerActivate);
	HookEvent("player_disconnect",		OnPlayerDisconnect,	EventHookMode_Pre);
	
	// Thanks to KyleS for showing me this method of supressing some CVar message to clients
	HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);
	
	RegConsoleCmd("sm_ibots", Cmd_ibots);
	RegAdminCmd("sm_ibots_switch", Cmd_SwitchTeams, ADMFLAG_SLAY, "Allows you to switch the teams");
	
	RegAdminCmd("sm_ibotshp", Cmd_iBotsHP, ADMFLAG_GENERIC, "Set the HP of the iBots");
	
	LoadTranslations("ibots.phrases");
	
	NoEndRoundHandle = FindConVar("mp_ignore_round_win_conditions");
	
	if (NoEndRoundHandle == INVALID_HANDLE)
	{
		SetFailState("Unable to find CVar mp_ignore_round_win_conditions");
	}
	
	// Execute the config file, let it autoname it
	//AutoExecConfig(true); // Removed with the addition of the AutoExecConfig include file as of 1.3.0.3
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
			OnClientPostAdminCheck(i);
		}
	}
}

/**
 * Called when the plugin is about to be unloaded.
 *
 * @noreturn
 */
public OnPluginEnd()
{
	#if _DEBUG
		DebugMessage("Setting server variables back to original...");
	#endif
	
	SetConVarString(botsprefix, OrgPrefix);
	SetConVarString(botteam, Orgbotteam);
	SetConVarString(humanteam, Orghumanteam);
	
	SetConVarInt(ibot_quota, Orgbotquota);
	SetConVarInt(ibot_fraglimit, Orgfraglimit);
}

/**
 * Called after a library is added that the current plugin references 
 * optionally. A library is either a plugin name or extension name, as 
 * exposed via its include file.
 *
 * @param name			Library name.
 */
public OnLibraryAdded(const String:name[])
{
	// Check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if (UseUpdater && StrEqual(name, "updater"))
	{
		#if _DEBUG
			DebugMessage("OnLibraryAdded adding iBots to Updater");
		#endif
		
		Updater_AddPlugin(UPDATE_URL);
	}
}

/**
 * Called when the map has loaded, servercfgfile (server.cfg) has been 
 * executed, and all plugin configs are done executing.  This is the best
 * place to initialize plugin functions which are based on cvar data.  
 *
 * @note This will always be called once and only once per map.  It will be 
 * called after OnMapStart().
 *
 * @noreturn
 */
public OnConfigsExecuted()
{
	if (TEAM_BOT == CS_TEAM_T)
	{
		SetConVarString(botteam, "T");
		SetConVarString(humanteam, "CT");
		PrintToServer("%t", "Bots on T");
	}
	else
	{
		SetConVarString(botteam, "CT");
		SetConVarString(humanteam, "T");
		PrintToServer("%t", "Bots on CT");
	}
	
	HookConVarChange((reservedslots = FindConVar("sm_reserved_slots")), ReservedSlotsChanged);
		
	if (reservedslots == INVALID_HANDLE)
	{
		SetFailState("Unable to hook sm_reserved_slots");
	}
	
	ireservedslots = GetConVarInt(reservedslots);
	
	if (UseMaxFrags)
	{
		SetConVarInt(ibot_fraglimit, MaxFrags);
	}
	
	// Check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if (UseUpdater && LibraryExists("updater"))
	{
		#if _DEBUG
			DebugMessage("OnConfigsExecuted adding iBots to Updater");
		#endif
		
		Updater_AddPlugin(UPDATE_URL);
	}
	
	iBotsQuota();
	
	if (!IsCSGO)
	{
		SetConVarString(botsprefix, NewPrefix);
	}
}

/**
 * Called when the map is loaded.
 *
 * @note This used to be OnServerLoad(), which is now deprecated.
 * Plugins still using the old forward will work.
 */
public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/bomb_planted_ring.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo.vtf");
	
	BotDifficultyChangeable = 0;
	
	PrecacheSound(SOUND_BEEP, true);
 	PrecacheSound(SOUND_BLIP, true);
 	PrecacheSound(BLOCKED_WEAPONS, true);
}

/**
 * Called right before a map ends.
 */
public OnMapEnd()
{
	#if _DEBUG
		DebugMessage("Running OnMapEnd");
	#endif
	
	switch (AdjustBotDiff)
	{
		case 1:
		{
			#if _DEBUG
				new String:dmsg[MAX_MESSAGE_LENGTH];
				Format(dmsg, sizeof(dmsg), "Setting bot_difficulty back to default [%i]", StartingBotDiff);
				DebugMessage(dmsg);
			#endif
			
			SetConVarInt(ibot_difficulty, StartingBotDiff);
		}
		
		case 2:
		{
			#if _DEBUG
				DebugMessage("Going to run SetBotDifficulty...");
			#endif
			
			SetBotDifficulty();
		}
	}
}

/**
 *	"game_start"					// a new game starts
 *	{
 *		"roundslimit"	"long"		// max round
 *		"timelimit"		"long"		// time limit
 *		"fraglimit"		"long"		// frag limit
 *		"objective"		"string"	// round objective
 *	}
 */
public OnGameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if _DEBUG
		DebugMessage("About to run ResetEverything from OnGameStart...");
	#endif
	
	// Set all variables back to starting values that should be set back
	ResetEverything();
}

/**
 * Called when a client is entering the game.
 *
 * Whether a client has a steamid is undefined until OnClientAuthorized
 * is called, which may occur either before or after OnClientPutInServer.
 * Similarly, use OnClientPostAdminCheck() if you need to verify whether 
 * connecting players are admins.
 *
 * GetClientCount() will include clients as they are passed through this 
 * function, as clients are already in game at this point.
 *
 * @param client		Client index.
 * @noreturn
 */
public OnClientPutInServer(client)
{
	if (UseSuperNades)
	{
		#if _DEBUG
			new String:dmsg[MAX_MESSAGE_LENGTH];
			Format(dmsg, sizeof(dmsg), "SDKHooking OnTakeDamage on %L", client);
			DebugMessage(dmsg);
		#endif
		
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	
	if (AdvertiseInterval > 0 && !IsFakeClient(client))
	{
		ClearTimer(h_ClientAdvertise[client]);
		
		h_ClientAdvertise[client] = CreateTimer(20.0, Join_Advertise, client);
	}
	
	ClientHP[client] = 0;
}

/**
 * Called once a client is authorized and fully in-game, and 
 * after all post-connection authorizations have been performed.  
 *
 * This callback is gauranteed to occur on all clients, and always 
 * after each OnClientPutInServer() call.
 *
 * @param client		Client index.
 * @noreturn
 */
public OnClientPostAdminCheck(client)
{
	#if _DEBUG
		new String:dmsg[MAX_MESSAGE_LENGTH];
		Format(dmsg, sizeof(dmsg), "Running OnClientPostAdminCheck for %L", client);
		DebugMessage(dmsg);
	#endif
	
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (CheckCommandAccess(client, "ibots_vip", ADMFLAG_RESERVATION))
		{
			#if _DEBUG
				Format(dmsg, sizeof(dmsg), "%L is VIP", client);
				DebugMessage(dmsg);
			#endif
			
			IsVIP[client] = true;
		}
		else
		{
			#if _DEBUG
				Format(dmsg, sizeof(dmsg), "%L is NOT a VIP", client);
				DebugMessage(dmsg);
			#endif
			
			IsVIP[client] = false;
		}
		
		if (CheckCommandAccess(client, "allow_control_bots", ADMFLAG_CUSTOM1))
		{
			AllowedToControlBot[client] = true;
			
			if (IsVIP[client])
			{
				BotControlTimes[client] = BotControlTimesVIP;
			}
			else
			{
				BotControlTimes[client] = BotControlTimesREG;
			}
		}
		else
		{
			AllowedToControlBot[client] = false;
		}
		
		if (CheckCommandAccess(client, "ibots_admin", ADMFLAG_GENERIC))
		{
			IsClientAdmin[client] = true;
		}
	}
}

/**
 * Called when a client is disconnecting from the server.
 *
 * @param client		Client index.
 * @noreturn
 * @note	Must use IsClientInGame(client) if you want to do client specific things
 */
public OnClientDisconnect(client)
{
	// ===================================================================================================================================
	// Clean up client specific variables and open timers (if they exist)
	// ===================================================================================================================================
	if (IsClientInGame(client))
	{
		ClearTimer(h_ClientAdvertise[client]);
		ClearTimer(ClientTimer[client]);
		FragCount[client] = 0;
		ClientHP[client] = 0;
		IsVIP[client] = false;
		IsClientAdmin[client] = false;
		
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		
		#if _DEBUG
			new String:dmsg[MAX_MESSAGE_LENGTH];
			Format(dmsg, sizeof(dmsg), "%L disconnected, all client variables reset", client);
			DebugMessage(dmsg);
		#endif
	}
	
	if (JoinPartMode == 3)
	{
		#if _DEBUG
			DebugMessage("OnClientDisconnect, JoinPartMode is 3, about to adjust bot_quota...");
		#endif
		
		CreateTimer(0.5, Timer_UpdateQuotaDisconnect);
	}
}

public Action:Join_Advertise(Handle:timer, any:client)
{
	h_ClientAdvertise[client] = INVALID_HANDLE;
	
	#if _DEBUG
		DebugMessage("Running Join_Advertise timer code...");
	#endif
	
	if (IsClientInGame(client) && GetClientTeam(client) > CS_TEAM_NONE)
	{
		CPrintToChat(client, "%s %t", PLUGIN_ANNOUNCE, "Advertise");
		
		PrintCenterText(client, PLUGIN_ANNOUNCE2);
	}
}

/**
 *	"player_connect"			// a new client connected
 *	{
 *		"name"		"string"	// player name		
 *		"index"		"byte"		// player slot (entity index-1)
 *		"userid"	"short"		// user ID on server (unique on server)
 *		"networkid" "string" // player network (i.e steam) id
 *		"address"	"string"	// ip:port
 *		"bot"		"short"		// is a bot
 *	}
 */
public Action:OnPlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetEventBroadcast(event, true);
	
	return Plugin_Continue;
}

/**
 *	"player_activate"
 *	{
 *		"userid"	"short"		// user ID on server
 *	}
 */ 
public OnPlayerActivate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsFakeClient(client))
	{
		PrintToChatAll("Player %N has joined the game", client);
	}
}

/**
 *	"player_disconnect"			// a client was disconnected
 *	{
 *		"userid"	"short"		// user ID on server
 *		"reason"	"string"	// "self", "kick", "ban", "cheat", "error"
 *		"name"		"string"	// player name
 *		"networkid"	"string"	// player network (i.e steam) id
 *		"bot"		"short"		// is a bot
 *	}
 */
public Action:OnPlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client > 0 && client <= MaxClients && IsFakeClient(client))
	{
		#if _DEBUG
			DebugMessage("Bot disconnected, silencing the event");
		#endif
		
		SetEventBroadcast(event, true);
	}
	
	return Plugin_Continue;
}

/**
 *	"player_spawn"				// player spawned in game
 *	{
 *		"userid"	"short"		// user ID on server
 *	}
 */
public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Retrieve client's current Frag Count	
	FragCount[client] = GetClientFrags(client);
	
	if (IsFakeClient(client))
	{
		#if _DEBUG
			DebugMessage("OnPlayerSpawn, bot spawned, adjusting HP...");
		#endif
		HideDeath[client] = false;
		SetEntProp(client, Prop_Send, "m_iHealth", iBotsHealth, 1);
	}
	else
	{
		if (ClientHP[client] > 100)
		{
			#if _DEBUG
				DebugMessage("OnPlayerSpawn, human spawned who had +100 HP, setting HP to higher amount...");
			#endif
			
			SetEntProp(client, Prop_Send, "m_iHealth", ClientHP[client], 1);
			ClientHP[client] = 0;
		}
	}
}

/**
 *	"round_start"
 *	{
 *		"timelimit"	"long"		// round time limit in seconds
 *		"fraglimit"	"long"		// frag limit in seconds
 *		"objective"	"string"	// round objective
 *	}
 */
public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if _DEBUG
		DebugMessage("Event Round Start");
	#endif
	
	StopAllBeacon();
	
	if (JoinPartMode == 1)
	{
		#if _DEBUG
			DebugMessage("JoinPartMode is 1, running iBots Quota...");
		#endif
		
		iBotsQuota();
	}
	
	// Exec Money
	iBotsMoney();
	
	// Let players know what the bots HP is set to
	CPrintToChatAll("%t", "Round Start", iBotsHealth);
	
	// If Advertise every X rounds enabled, advertise to clients connected.  See t_Advertise
	Advertisetime++;
	
	if (AdvertiseInterval > 0)
	{
		if (Advertisetime > AdvertiseInterval)
		{
			#if _DEBUG
				DebugMessage("Starting Advertisement timer...");
			#endif
			
			CreateTimer(2.0, t_Advertise);
			Advertisetime = 0;
		}
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			PlayerOldSkin[i][0] = '\0';
			GetClientModel(i, PlayerOldSkin[i], sizeof(PlayerOldSkin[]));
		}
	}
}

public Action:t_Advertise(Handle:timer)
{
	#if _DEBUG
		DebugMessage("Running t_Advertise");
	#endif
	
	// Advertises to every client every X rounds if enabled
	Client_PrintKeyHintTextToAll(PLUGIN_ANNOUNCE2);	
	PrintHintTextToAll("%s %t", PLUGIN_ANNOUNCE2, "Advertise2", iBotsHealth, BotDifficulty);
}

/**
 *	"player_death"				// a game event, name may be 32 charaters long
 *	{
 *		"userid"	"short"   	// user ID who died				
 *		"attacker"	"short"	 	// user ID who killed
 *	}
 */	
public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	#if _DEBUG
		new String:dmsg[MAX_MESSAGE_LENGTH];
		Format(dmsg, sizeof(dmsg), "OnPlayerDeath - victim is [%i] - killer is [%i]", victim, killer);
		DebugMessage(dmsg);
	#endif
	
	ClearTimer(BeaconTimer[victim]);
	
	if (IsFakeClient(victim))
	{
		CheckForBeacon();
	}
	else
	{
		IsControllingBot[victim] = false;
	}
	
	if (killer < 1 || killer > MaxClients || killer == victim)
	{
		if (HideDeath[victim])
		{
			CreateTimer(0.2, tDestroyRagdoll, GetClientSerial(victim));
			return Plugin_Handled;
		}
		else
		{
			return Plugin_Continue;
		}
	}
	
	new victimTeam = GetClientTeam(victim);
	new killerTeam = GetClientTeam(killer);
	
	if (killerTeam == victimTeam)
	{
		FragCount[killer]--;
		return Plugin_Continue;
	}
	
	new hp_bonus = 0;
	if (IsFakeClient(victim))
	{
		hp_bonus = BotLevel(victim);
	}
	
	FragCount[killer]++;
	
	if (!IsFakeClient(killer) && HPBonus && hp_bonus > 0)
	{
		decl String:wname[80];
		wname[0] = '\0';
		
		GetEventString(event, "weapon", wname, sizeof(wname));
		
		new health = GetEntProp(killer, Prop_Send, "m_iHealth");
		
		if (StrEqual(wname, "knife", false) && KnifeBonusMultiplier > 0)
		{
			#if _DEBUG
				DebugMessage("Weapon used was a knife...");
			#endif
			
			new score = GetClientFrags(killer);
			score += 1;
			SetEntProp(killer, Prop_Data, "m_iFrags", score++);
			FragCount[killer]++;
			Client_PrintKeyHintText(killer, "%t", "Knife Frag Bonus");
			
			hp_bonus = RoundToNearest(hp_bonus * KnifeBonusMultiplier);
		}
		
		SetEntProp(killer, Prop_Send, "m_iHealth", health + hp_bonus, 1);
		CPrintToChat(killer, "%t", "HP Bonus", hp_bonus);
	}
	
	// If this kill equals the mp_fraglimit set MapIsDone and create timer to announce winner of map
	if (UseMaxFrags && FragCount[killer] == MaxFrags)
	{
		if (!MapIsDone)
		{
			// Set this so the "who won" message won't repeat on multi kill over MaxFrags kills
			// (example: hegrenade kills 4 people where only 1 was needed to reach maxfrags)
			MapIsDone = true;
			b_MapIsOver = false;
			CreateTimer(1.0, t_MapHasEnded, killer);
			return Plugin_Continue;
		}
	}
	
	if (AllowBotControl && !IsFakeClient(victim))
	{
		AllHumansDead = true;
		new team;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				team = GetClientTeam(i);
				if (team == TEAM_HUMAN)
				{
					AllHumansDead = false;
					break;
				}
			}
		}
		
		if (!AllHumansDead && AllowedToControlBot[victim])
		{
			if (IsCSGO && BotControlTimes[victim] != 0)
			{
				CS_SwitchTeam(victim, TEAM_BOT);
			}
			
			// Implement a timer instead
			CreateTimer(1.0, Timer_AdvertiseBotControl, GetClientSerial(victim), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_AdvertiseBotControl(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (!client)
	{
		return Plugin_Stop;
	}
	
	if (IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	
	// Find out who the player is spectating.
	new target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	
	if (target != -1 && IsFakeClient(target)) // Player is spectating a bot
	{
		if (BotControlTimes[client] != 0)
		{
			PrintHintText(client, "Press your USE (E) key\nto take control of %N", target);
		}
	}
	
	return Plugin_Continue;
}

public Action:tDestroyRagdoll(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	HideDeath[client] = false;
	
	if (ragdoll < 0)
	{
		return Plugin_Continue;
	}
	
	AcceptEntityInput(ragdoll, "kill");
	
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	// Check if the player is using (USE KEY) while dead (CSS code)
	if (buttons & IN_USE && !IsCSGO && !IsPlayerAlive(client) && AllowedToControlBot[client] && AllowBotControl)
	{
		// Find out who the player is spectating.
		new target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		
		if (target != -1 && IsFakeClient(target))
		{
			if (GetAliveBots() == 1)
			{
				SetConVarInt(NoEndRoundHandle, 1);
			}
			
			// Switch player to BOT team, save list of weapons bot currently has, get bot's location, slay/kill/kick bot, spawn player where bot was, give player weapons bot had.
			CS_SwitchTeam(client, TEAM_BOT);
			CS_RespawnPlayer(client);
			GetClientWeapons(client, target);
			
			new Float:vecPos[3], Float:vecAng[3];
			GetClientAbsOrigin(client, vecPos);
			GetClientAbsAngles(client, vecAng);
			
			HideDeath[target] = true;
			
			//SDKHooks_TakeDamage(target, 0, 0, 1000.0);
			ForcePlayerSuicide(target);
			
			//CS_RespawnPlayer(client);
			TeleportEntity(client, vecPos, vecAng, NULL_VECTOR);
			GiveClientWeapons(client);
			
			if (BotControlMsg > 0)
			{
				AdviseBotControl(client);
			}
			
			IsControllingBot[client] = true;
			SetConVarInt(NoEndRoundHandle, 0);
			BotControlTimes[client]--;
			
			CheckForBeacon();
			
			switch (BotControlTimes[client])
			{
				case 0:
				{
					CPrintToChat(client, "%t", "Last Bot Takeover");
					AllowedToControlBot[client] = false;
				}
				
				default:
				{
					CPrintToChat(client, "%t", "Bot Takeover", BotControlTimes[client]);
				}
			}
		}
	}
	
	// We must return Plugin_Continue to let the changes be processed.
	// Otherwise, we can return Plugin_Handled to block the commands
	return Plugin_Continue;
}

AdviseBotControl(client)
{
	if (BotControlMsg == 2)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && i != client)
			{
				CPrintToChat(i, "%t", "Player Took Over Bot", client, BotControlTimes[client]);
			}
		}
	}
	else
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsClientAdmin[i])
			{
				CPrintToChat(i, "%t", "Player Took Over Bot", client, BotControlTimes[client]);
			}
		}
	}
}

GetAliveBots()
{
	new alive = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && IsPlayerAlive(i))
		{
			alive++;
		}
	}
	
	return alive;
}

/**
* Sets the client's weapons to that of the bot's they are taking over
* 
* @param		client		Player's client index who is taking over the bot
* @param		bot		Bot's index who is being taken over
* @noreturn
*/
GetClientWeapons(client, bot)
{
	new prim, sec;
	
	PrimarySlot[client][0] = '\0';
	SecondarySlot[client][0] = '\0';
	
	prim = GetPlayerWeaponSlot(bot, CS_SLOT_PRIMARY);
	
	if (prim > MaxClients)
	{
		GetEntityClassname(prim, PrimarySlot[client], sizeof(PrimarySlot[]));
		RemovePlayerItem(bot, prim);
		AcceptEntityInput(prim, "Kill");
	}
	else
	{
		Format(PrimarySlot[client], sizeof(PrimarySlot), "NONE");
	}
	
	sec = GetPlayerWeaponSlot(bot, CS_SLOT_SECONDARY);
	
	if (sec > MaxClients)
	{
		GetEntityClassname(sec, SecondarySlot[client], sizeof(SecondarySlot[]));
		RemovePlayerItem(bot, sec);
		AcceptEntityInput(sec, "Kill");
	}
	else
	{
		Format(SecondarySlot[client], sizeof(SecondarySlot), "NONE");
	}
	
	HEGrenades[client] = GetClientHEGrenades(bot);
	FlashBangs[client] = GetClientFlashbangs(bot);
	SmokeGrenades[client] = GetClientSmokeGrenades(bot);
}

GiveClientWeapons(client)
{
	//GivePlayerItem(client, "weapon_knife");
	
	if (HEGrenades[client] > 0)
	{
		for (new g = 0; g < HEGrenades[client]; g++)
		{
			GivePlayerItem(client, "weapon_hegrenade");
		}
		
		HEGrenades[client] = 0;
	}
	
	if (FlashBangs[client] > 0)
	{
		for (new fb = 0; fb < FlashBangs[client]; fb++)
		{
			GivePlayerItem(client, "weapon_flashbang");
		}
		
		FlashBangs[client] = 0;
	}
	
	if (SmokeGrenades[client] > 0)
	{
		for (new sg = 0; sg < SmokeGrenades[client]; sg++)
		{
			GivePlayerItem(client, "weapon_smokegrenade");
		}
		
		SmokeGrenades[client] = 0;
	}
	
	if (!StrEqual(SecondarySlot[client], "NONE", false))
	{
		GivePlayerItem(client, SecondarySlot[client]);
		
		SecondarySlot[client][0] = '\0';
	}
	
	if (!StrEqual(PrimarySlot[client], "NONE", false))
	{
		GivePlayerItem(client, PrimarySlot[client]);
		
		PrimarySlot[client][0] = '\0';
	}
}

GetClientHEGrenades(client)
{
	new count = GetEntProp(client, Prop_Data, "m_iAmmo", _, HEGrenadeOffset);
	SetEntProp(client, Prop_Data, "m_iAmmo", 0, _, HEGrenadeOffset);
	
	return count;
}

GetClientSmokeGrenades(client)
{
	new count = GetEntProp(client, Prop_Data, "m_iAmmo", _, SmokegrenadeOffset);
	SetEntProp(client, Prop_Data, "m_iAmmo", 0, _, SmokegrenadeOffset);
	
	return count;
}

GetClientFlashbangs(client)
{
	new count = GetEntProp(client, Prop_Data, "m_iAmmo", _, FlashbangOffset);
	SetEntProp(client, Prop_Data, "m_iAmmo", 0, _, FlashbangOffset);
	
	return count;
}

public Action:Event_ServerCvar(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if _DEBUG
		return Plugin_Continue;
	#endif
	
	decl String:sConVarName[64];
	sConVarName[0] = '\0';
	
	GetEventString(event, "cvarname", sConVarName, sizeof(sConVarName));
	
	if (StrContains(sConVarName, "bot_difficulty", false) >= 0 ||
		StrContains(sConVarName, "bot_quota", false) >= 0)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

BotLevel(client)
{
	if (!IsClientInGame(client) || !IsFakeClient(client))
	{
		return 0;
	}
	
	decl String:name[MAX_NAME_LENGTH];
	name[0] = '\0';
	
	GetClientName(client, name, sizeof(name));
	
	if (StrContains(name, "elite", false) != -1)
	{
		return EliteBonus;
	}
	else if (StrContains(name, "expert", false) != -1)
	{
		return ExpertBonus;
	}
	else if (StrContains(name, "veryhard", false) != -1)
	{
		return VeryHardBonus;
	}
	else if (StrContains(name, "hard", false) != -1)
	{
		return HardBonus;
	}
	else if (StrContains(name, "tough", false) != -1)
	{
		return ToughBonus;
	}
	else if (StrContains(name, "normal", false) != -1)
	{
		return NormalBonus;
	}
	else if (StrContains(name, "fair", false) != -1)
	{
		return FairBonus;
	}
	else if (StrContains(name, "easy", false) != -1)
	{
		return EasyBonus;
	}
	
	return -1;
}

StopAllBeacon()
{
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			ClearTimer(BeaconTimer[i]);
		}
	}
}

CheckForBeacon()
{
	if (!UseBeacon)
	{
		return;
	}
	
	new humans = 0;
	new bots = 0;
	
	new client = -1;

	for (new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (GetClientTeam(i) == TEAM_BOT)
			{
				bots++;
				client = i;
			}
			else
			{
				humans++;
			}
		}
	}

	if (client != -1 && humans > 0 && bots == 1)
	{
		BeaconTimer[client] = CreateTimer(1.0, Timer_Beacon, client, TIMER_REPEAT);
	}
}

public Action:Timer_Beacon(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		
		vec[2] += 10;
		
		TE_SetupBeamRingPoint(vec, 10.0, 300.0, g_BeamSprite, g_HaloSprite, 0, 15, 1.0, 5.0, 0.0, {0, 0, 255, 255}, 10, 0);
		TE_SendToAll();
		
		EmitAmbientSound(SOUND_BEEP, vec, client, SNDLEVEL_RAIDSIREN);
		
		CreateTimer(0.5, Timer_Blip, client);
	}
	else
	{
		BeaconTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:Timer_Blip(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		
		vec[2] += 10;
		
		EmitAmbientSound(SOUND_BLIP, vec, client, SNDLEVEL_RAIDSIREN);
	}
	else
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

/**
 *	"bomb_defused"
 *	{
 *		"userid"	"short"		// player who defused the bomb
 *		"site"		"short"		// bombsite index
 *	}
 */
public OnBombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Retrieve ID of player who defused
	new defuser = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Add 3 to the players frag count
	FragCount[defuser] += 3;
	
	// If the players score reached or exceeded the mp_fraglimit set MapIsDont and create timer to announce winner of map
	if (UseMaxFrags && FragCount[defuser] >= MaxFrags)
	{
		MapIsDone = true;
		b_MapIsOver = false;
		CreateTimer(1.0, t_MapHasEnded, defuser);
	}
}

public Action:t_MapHasEnded(Handle:timer, any:client)
{
	if (client > 0)
	{
		// Announce player who won by achieving maxfrags first
		if (!b_MapIsOver)
		{
			CPrintToChatAll("%t", "Player Won", client, MaxFrags);
		}
		else
		{
			// This will fire if the map ended because time ran out and no one achieved the mp_fraglimit
			CPrintToChatAll("%t", "No Win", MaxFrags);
		}
	}
	else
	{
		// Find player(s) with highest score
		new temptopscore = 0;
		new score = 0;
		new temptopplayer = 0;
		new tied[MAXPLAYERS+1] = 0;
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
			{
				score = FragCount[i];
				
				if (score > 0 && score >= temptopscore)
				{
					if (score == temptopscore)
					{
						tied[i] = temptopplayer; // I'm tied with this player
						tied[temptopplayer] = i; // This player tied with me
					}
					else
					{
						temptopplayer = i; // I'm the new top player
						temptopscore = score; // My score is the new top score
						tied[i] = 0; // I'm not tied with anyone, yet
					}
				}
				else
				{
					tied[i] = 0;
				}
			}
		}
		
		new top_winner = temptopplayer;
		new tied_winner = tied[top_winner]; // Player I'm tied with, if any
		new topscore = FragCount[top_winner];
		
		if (tied_winner > 0)
		{
			CPrintToChatAll("%t", "Tie", top_winner, tied_winner, topscore);
		}
		else
		{
			CPrintToChatAll("%t", "No Tie", top_winner, topscore);
		}
	}
	
	//if (ResetBotDiff)
	//{
	//	SetConVarInt(ibot_difficulty, StartingBotDiff);
	//}
	
	ClearTimer(BotQuotaTimer);
}

/**
 *	"round_end"
 *	{
 *		"winner"	"byte"		// winner team/user i
 *		"reason"	"byte"		// reson why team won
 *		"message"	"string"	// end round message 
 *	}
 */
public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	StopAllBeacon();
	
	// As long as no one has reached the mp_fraglimit
	if (!MapIsDone)
	{
		new winner = GetEventInt(event, "winner");
		
		iBotsHP(winner);
		
		#if 0
		if (ModifyHP)
		{
			iBotsHP(winner);
		}
		#endif
	}
	
	if (JoinPartMode == 2)
	{
		iBotsQuota();
	}
	
	CreateTimer(0.1, Timer_SetScore);
	
	new HP;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (IsPlayerAlive(i))
			{
				HP = GetClientHealth(i);
				
				if (HP > 100)
				{
					ClientHP[i] = HP;
				}
				
				if (IsControllingBot[i])
				{
					CreateTimer((RestartRoundTime - 0.2), Timer_ResetPlayer, GetClientSerial(i));
				}
			}
		}
	}
}

public Action:Timer_ResetPlayer(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (!client)
		return Plugin_Continue;
	
	SetEntityModel(client, PlayerOldSkin[client]);
	
	CS_RemoveAllWeapons(client);
	
	if (AllowBotControl && IsControllingBot[client] && GetClientTeam(client) == TEAM_BOT)
	{
		CS_SwitchTeam(client, TEAM_HUMAN);
	}
	
	IsControllingBot[client] = false;
	
	return Plugin_Continue;
}

CS_RemoveAllWeapons(client)
{
	new weapon_index = -1;
	
	for (new slot = 0; slot < MAX_WEAPON_SLOTS; slot++)
	{
		while ((weapon_index = GetPlayerWeaponSlot(client, slot)) != -1)
		{
			if (IsValidEntity(weapon_index))
			{
				RemovePlayerItem(client, weapon_index);
				AcceptEntityInput(weapon_index, "kill");
			}
		}
	}
}

public Action:Timer_SetScore(Handle:timer)
{
	SetTeamScore(TEAM_BOT, score_bot);
	//CS_SetTeamScore(TEAM_BOT, score_bot); // Removed until it's in an official SM release
	
	SetTeamScore(TEAM_HUMAN, score_human);
	//CS_SetTeamScore(TEAM_HUMAN, score_human); // Removed until it's in an official SM release
}

/**
 *	"cs_win_panel_match"			
 *	{		
 *		"t_score"						"short"
 *		"ct_score"						"short"		
 *		"t_kd"							"float"
 *		"ct_kd"							"float"		
 *		"t_objectives_done"				"short"
 *		"ct_objectives_done"			"short"		
 *		"t_money_earned"				"long"
 *		"ct_money_earned"				"long"
 *	}
 */
public OnCSWinPanelMatch(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if (!MapIsDone)
	{
		b_MapIsOver = true;
		CreateTimer(2.0, t_MapHasEnded, 0);
	}
} 

iBotsHP(winner)
{
	#if _DEBUG
		DebugMessage("iBotsHP running...");
	#endif
	
	if (winner == TEAM_BOT)
	{
		#if _DEBUG
			DebugMessage("TEAM_BOT won...");
		#endif
		
		score_bot++;
		BotsWinStreak++;
		HumansWinStreak = 0;
		
		CPrintToChatAll("%t", "Bot Streak", BotsWinStreak);
		
		if (BotsWinStreak >= BotWinningStreak)
		{
			if (UseSuperNades && NadeMultiplyer > 1.0)
			{
				NadeMultiplyer -= NadeMultiplyerDecrease;
				
				if (NadeMultiplyer < 1.0)
				{
					NadeMultiplyer = 1.0;
				}
			}
			
			if (ModifyHP)
			{
				iBotsHealth -= iBotsHPDecrease;
				
				if (iBotsHealth < MinHP)
				{
					iBotsHealth = MinHP;
				}
			}
		}
	}
	else if (winner == TEAM_HUMAN)
	{
		#if _DEBUG
			DebugMessage("TEAM_HUMAN won...");
		#endif
		
		score_human++;
		HumansWinStreak++;
		BotsWinStreak = 0;
		
		CPrintToChatAll("%t", "Human Streak", HumansWinStreak);
		
		if (HumansWinStreak >= HumanWinningStreak)
		{
			if (ModifyHP)
			{
				iBotsHealth += iBotsHPIncrease;
				
				if (BotMaxHP > 0 && iBotsHealth > BotMaxHP)
				{
					iBotsHealth = BotMaxHP;
				}
			}
			
			if (UseSuperNades)
			{
				#if _DEBUG
					DebugMessage("Increasing nade multiplyer");
				#endif
				
				NadeMultiplyer += NadeMultiplyerIncrease;
			}
		}
	}
	
	BotDifficultyChangeable++;
	
	if (BotDifficultyChangeable >= 4 && BotDiffNeedsAdjustment())
	{
		AdjustBotDifficultyMidGame();
		BotDifficultyChangeable = 0;
	}
}

bool:BotDiffNeedsAdjustment()
{
	#if _DEBUG
		DebugMessage("Runing BotDiffNeedsAdjustment...");
	#endif
	
	if (HumansWinStreak >= HumansStreakDiff)
	{
		if (BotDifficulty < 3)
		{
			BotDifficulty++;
			
			SetConVarInt(ibot_difficulty, BotDifficulty);
			
			return true;
		}
	}

	if (BotsWinStreak >= BotsStreakDiff)
	{
		if (BotDifficulty > 0)
		{
			BotDifficulty--;
			
			SetConVarInt(ibot_difficulty, BotDifficulty);
			
			return true;
		}
	}
	
	return false;
}

AdjustBotDifficultyMidGame()
{
	#if _DEBUG
		DebugMessage("Running AdjustBotDifficultyMidGame...");
	#endif
	
	new KickLast = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && !IsClientSourceTV(i))
		{
			if (KickLast == 0)
			{
				KickLast = i;
				CreateTimer(3.0, Timer_KickLast, i);
				
				continue;
			}
			KickClient(i);
		}
	}
}

public Action:Timer_KickLast(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsFakeClient(client))
	{
		#if _DEBUG
			DebugMessage("Kicking the last bot after changing the bot_difficulty");
		#endif
		KickClient(client, "Adjusting Bot Difficulty");
	}
	
	CPrintToChatAll("{default}[{red}iBots{default}] {green}Bot difficulty changed to [{red}%i{green}]", BotDifficulty);
}

iBotsMoney()
{
	if (BotsWinStreak > BotsStreakMoney)
	{
		if (GetTeamClientCount(TEAM_HUMAN) < 1)
		{
			return;
		}
			
		CPrintToChatAll("%t", "Paid Humans", StreakMoney);
		
		new team, val;
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				team = GetClientTeam(i);
				if (team > CS_TEAM_SPECTATOR)
				{
					val = GetEntProp(i, Prop_Send, "m_iAccount");
					val += StreakMoney;
					SetEntProp(i, Prop_Send, "m_iAccount", val);
				}
			}
		}
	}
	
	if (HumansWinStreak > HumansStreakMoney)
	{
		CPrintToChatAll("%t", "Paid Bots", StreakMoney);
		
		new team, val;
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsFakeClient(i))
			{
				team = GetClientTeam(i);
				if (team > CS_TEAM_SPECTATOR)
				{
					val = GetEntProp(i, Prop_Send, "m_iAccount");
					val += StreakMoney;
					SetEntProp(i, Prop_Send, "m_iAccount", val);
				}
			}
		}
	}
}

iBotsQuota()
{
	if (!ManageBots)
	{
		return;
	}
	
	new humans = GetTeamClientCount(TEAM_HUMAN);
	new spectators = GetTeamClientCount(CS_TEAM_SPECTATOR);
	
	new quota;
	
	if (humans >= 1)
	{
		// Set base quota based on humans multiplied by iBotsQuota cvar, rounded
		quota = RoundFloat(humans * f_iBotsQuota);
		
		if (quota < MinQuota)
		{
			quota = MinQuota;
		}
	}
	else
	{
		quota = MinQuota;
		ResetEverything();
	}
	
	new difference = score_human - score_bot;
	
	if (difference > WinningDifference)
	{
		quota = quota + difference - WinningDifference;
	}
		
	if (quota > MaxBots)
	{
		quota = MaxBots;
	}
	
	if (quota + humans + spectators >= MaxClients)
	{
		humans += spectators;
		
		quota = (MaxClients - humans) - ireservedslots;
	}
	
	SetConVarInt(ibot_quota, quota);
}

/**
 *	"player_team"				// player change his team
 *	{
 *		"userid"	"short"		// user ID on server
 *		"team"		"byte"		// team id
 *		"oldteam" "byte"		// old team id
 *		"disconnect" "bool"	// team change because player disconnects
 *		"autoteam" "bool"		// true if the player was auto assigned to the team
 *		"silent" "bool"			// if true wont print the team join messages
 *		"name"	"string"		// player's name
 *	}
 */
public Action:OnTeamJoin(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Set the event notification off for team joins
	SetEventBroadcast(event, true);
	
	return Plugin_Continue;
}

public Action:Timer_UpdateQuota(Handle:timer)
{
	BotQuotaTimer = INVALID_HANDLE;
	
	iBotsQuota();
}

public Action:Timer_UpdateQuotaDisconnect(Handle:timer)
{
	iBotsQuota();
}

ResetEverything()
{
	#if _DEBUG
		DebugMessage("Running ResetEverything...");
	#endif
	
	score_bot = 0;
	score_human = 0;
	iBotsHealth = 100;
	BotsWinStreak = 0;
	HumansWinStreak = 0;
	Advertisetime = 0;
	MapIsDone = false;
	NadeMultiplyer = 1.0;
	
	if (UseMaxFrags)
	{
		#if _DEBUG
			new String:dmsg[MAX_MESSAGE_LENGTH];
			Format(dmsg, sizeof(dmsg), "UseMaxFrags is being used, setting mp_fraglimit to %i", MaxFrags);
			DebugMessage(dmsg);
		#endif
		
		SetConVarInt(ibot_fraglimit, MaxFrags);
	}
	
	CPrintToChatAll("{green}[{lightgreen}iBots{green}]{default} %t", "Resetting");
	
	SetConVarInt(ibot_quota, MinQuota);
	
	ChangeBotDifficulty(StartingBotDiff);
}

public Action:Cmd_ibots(client, args)
{
	#if _DEBUG
		new String:dmsg[MAX_MESSAGE_LENGTH];
		Format(dmsg, sizeof(dmsg), "%L requesting iBots information", client);
		DebugMessage(dmsg);
	#endif
	
	if (client == 0)
	{
		ReplyToCommand(client, "%s - %t", PLUGIN_ANNOUNCE2, "Cmd1");
		ReplyToCommand(client, "%t", "Cmd2a", iBotsHealth, BotDifficulty, NadeMultiplyer);
		return Plugin_Handled;
	}
	
	new humans = GetTeamClientCount(TEAM_HUMAN);
	new quota = RoundFloat(humans * f_iBotsQuota);
	
	CPrintToChat(client, "%s - %t", PLUGIN_ANNOUNCE, "Cmd1");
	CPrintToChat(client, "%t", "Cmd2", iBotsHealth, BotDifficulty, NadeMultiplyer);
	
	if (quota < MinQuota)
	{
		CPrintToChat(client, "%t", "MinQuota", f_iBotsQuota, MinQuota);
	}
	else
	{
		CPrintToChat(client, "%t", "Quota", f_iBotsQuota, quota);
	}
	
	Client_PrintKeyHintText(client, "%s%t", PLUGIN_ANNOUNCE2, "Cmd3", f_iBotsQuota, quota, iBotsHealth, BotDifficulty, NadeMultiplyer);
	
	return Plugin_Continue;
}

SetBotDifficulty()
{
	#if _DEBUG
		DebugMessage("Running SetBotDifficulty");
	#endif
	
	new difference = score_human - score_bot;
	new bdiff = BotDifficulty;
	
	// If tied or Humans beat bots
	if (difference >= 0)
	{
		if (difference >= FinalDiff_Humans)
		{
			if (bdiff < 3)
			{
				bdiff++;
			}
			else
			{
				bdiff = 3;
				CPrintToChatAll("%t", "Bot Hardest", bdiff);
				return;
			}
			
			//SetConVarInt(ibot_difficulty, bdiff);
			ChangeBotDifficulty(bdiff);
			
			CPrintToChatAll("%t", "Bots Too Easy", bdiff);
			return;
		}
		else
		{
			CPrintToChatAll("%t", "Bots Good");
			return;
		}
	}
	else // If bots beat humans
	{
		difference = score_bot - score_human;
		if (difference >= FinalDiff_Bots)
		{
			if (bdiff > 0)
			{
				bdiff--;
			}
			else
			{
				bdiff = 0;
				CPrintToChatAll("%t", "Bots Easiest", bdiff);
				return;
			}
			
			//SetConVarInt(ibot_difficulty, bdiff);
			ChangeBotDifficulty(bdiff);
			
			CPrintToChatAll("%t", "Bots Too Hard", bdiff);
			return;
		}
		else
		{
			CPrintToChatAll("%t", "Bots Good");
			return;
		}
	}
}

/**
 * @brief When an entity is created
 *
 * @param		entity		Entity index
 * @param		classname	Class name
 * @noreturn
 */
public OnEntityCreated(entity, const String:classname[])
{
	if (UseIgnitedNades && StrContains(classname, "_projectile") != -1)
	{
		#if _DEBUG
			new String:dmsg[MAX_MESSAGE_LENGTH];
			Format(dmsg, sizeof(dmsg), "About to ignite hegrenade [%i]", entity);
			DebugMessage(dmsg);
		#endif
		
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
	}
}

/**
 * @brief When an entity is spawned
 *
 * @param		entity		Entity index
 * @noreturn
 */
public OnEntitySpawned(entity)
{
	new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	
	if (owner > 0 && owner <= MaxClients && IsVIP[owner])
	{
		#if _DEBUG
			new String:dmsg[MAX_MESSAGE_LENGTH];
			Format(dmsg, sizeof(dmsg), "Igniting hegrenade thrown by VIP %L", owner);
			DebugMessage(dmsg);
		#endif
		
		IgniteEntity(entity, 5.0);
	}
	else
	{
		#if _DEBUG
			new String:dmsg[MAX_MESSAGE_LENGTH];
			Format(dmsg, sizeof(dmsg), "Did not ignite hegrenade [%i].  Either player is not valid or not VIP, player [%i]", entity, owner);
			DebugMessage(dmsg);
		#endif
	}
}

/**
 * @brief When a player takes damage
 *
 * @param		victim		Victim entity index
 * @param		attacker	Attacker entity index (not always another player)
 * @param		inflictor	Entity index of source of damage
 * @param		damage		Damage amount (in float), return plugin_changed if altered
 * @param		damagetype	Enum for damagetype
 * @param		weapon		Weapon entity
 * @param		damageForce	Vector[3] damage force
 * @param		damagePosition	Vector[3] position where damage occurred
 * @param		classname	Class name
 * @noreturn
 */
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (attacker < 1 || attacker > MaxClients || IsFakeClient(attacker))
	{
		return Plugin_Continue;
	}
	
	if (FFMode > 0)
	{
		#if _DEBUG
			new String:dmsg[MAX_MESSAGE_LENGTH];
			Format(dmsg, sizeof(dmsg), "OnTakeDamage FFMode is %i", FFMode);
			DebugMessage(dmsg);
		#endif
		
		new ateam = GetClientTeam(attacker);
		new vteam = GetClientTeam(victim);
		
		if (ateam == vteam && ((FFMode & 4 && IsVIP[victim]) || 
			(FFMode & 2 && IsFakeClient(victim)) || 
			(FFMode & 1 && !IsFakeClient(victim))))
		{
			#if _DEBUG
				DebugMessage("OnTakeDamage, setting damage to 0.0 and damageForces to 0.0");
			#endif
			
			//damage = 0.0;
			//damagetype = DMG_PREVENT_PHYSICS_FORCE;
			
			//damageForce[0] = 0.0;
			//damageForce[1] = 0.0;
			//damageForce[2] = 0.0;
			return Plugin_Handled;
			//return Plugin_Changed;
		}
	}
	
	if (UseSuperNades)
	{
		decl String:sWeapon[MAX_WEAPON_STRING];
		sWeapon[0] = '\0';
		
		if (IsValidEntity(inflictor))
		{
			GetEntityClassname(inflictor, sWeapon, sizeof(sWeapon));
		}
		else
		{
			return Plugin_Continue;
		}
		
		if (StrEqual(sWeapon, "hegrenade_projectile", false))
		{
			#if _DEBUG
				new String:dmsg[MAX_MESSAGE_LENGTH];
				Format(dmsg, sizeof(dmsg), "UseSuperNades, adjusting damage by %f", NadeMultiplyer);
				DebugMessage(dmsg);
			#endif
			
			damage *= NadeMultiplyer;
			
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

CreateMyCVars()
{
	new bool:appended;
	
	// Set the file for the include
	AutoExecConfig_SetFile("plugin.iBots");
	
	HookConVarChange((CreateConVar("iBots_version", PLUGIN_VERSION, 
	"The version of iBots", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD)), OnVersionChanged);
	
	new Handle:hRandom; // KyleS HATES Handles
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_quota_min", "3", 
	"Minimum number of iBots to have in-game at any given time.", _, true, 0.0, true, 64.0)), MinQuotaChange);
	MinQuota = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_hp", "70", 
	"Lowest Health for iBots (they will always start with 100 on map start)", _, true, 1.0, true, 100.0)), MinHPChange);
	MinHP = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_hp_increase", "30", 
	"Amount of HP to add to bot's health as humans maintain a winning streak at or above iBots_streak_humans", _, true, 5.0, true, 100.0)), iBotsHPIncreaseChange);
	iBotsHPIncrease = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_hp_decrease", "15", 
	"Amount of HP to take from bot's health as bots maintain a winning streak at or above iBots_streak_bots", _, true, 5.0, true, 100.0)), iBotsHPDecreaseChange);
	iBotsHPDecrease = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_maxfrags", "100", 
	"Number of frags to declare a player a winner - this will set mp_fraglimit to the value specified here", _, true, 10.0, true, 100.0)), MaxFragsChange);
	MaxFrags = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_usemaxfrags", "1", 
	"Use the iBots_maxfrags?\n0 = NO\n1 = YES", _, true, 0.0, true, 1.0)), UseMaxFragsChange);
	UseMaxFrags = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_ManageBots", "1", 
	"Should iBots manage the bots?", _, true, 0.0, true, 1.0)), ManageBotsChange);
	ManageBots = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_quota", "2.2", 
	"Number of bots for each human player (will be rounded to nearest whole number after calculation)", _, true, 1.0, true, 10.0)), iBotsQuotaChange);
	f_iBotsQuota = GetConVarFloat(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_maxbots", "24", 
	"Maximum number of bots allowed - should be higher than iBots_quota_min", _, true, 0.0, true, 64.0)), MaxBotsChange);
	MaxBots = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_streak_humans", "2", 
	"How many rounds humans have to win in a row to start increasing the bot's HP", _, true, 1.0, true, 20.0)), HumanWinningStreakChange);
	HumanWinningStreak = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_streak_humans_cash", "4", 
	"Number of wins in a row humans must get before bots are paid (iBots_streak_money)", _, true, 1.0, true, 10.0)), HumansStreakMoneyChange);
	HumansStreakMoney = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_streak_humans_diff", "7", 
	"Number of wins in a row humans must get before bots have their difficulty increased", _, true, 1.0, true, 20.0)), HumansStreakDiffChange);
	HumansStreakDiff = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_streak_bots", "2", 
	"How many rounds bots have to win in a row to start having their HP reduced", _, true, 1.0, true, 20.0)), BotWinningStreakChange);
	BotWinningStreak = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_streak_bots_cash", "3", 
	"Number of wins in a row bots must get before humans are paid (iBots_streak_money)", _, true, 1.0, true, 10.0)), BotsStreakMoneyChange);
	BotsStreakMoney = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_streak_bots_diff", "4", 
	"Number of wins in a row bots must get before their difficulty is reduced", _, true, 1.0, true, 10.0)), BotsStreakDiffChange);
	BotsStreakDiff = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_streak_money", "2500", 
	"Amount of money to pay the loosing team after iBots_streak_<team>_cash is reached", _, true, 100.0, true, 16000.0)), StreakMoneyChange);
	StreakMoney = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_score_difference", "4", 
	"Number of wins the humans have over the bots before additional bots (beyond the quota formula) start joining", _, true, 1.0, true, 8.0)), WinningDifferenceChange);
	WinningDifference = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_final_diff_bots", "2", 
	"If bots win the map by this many rounds, the bot_difficulty will be lowered by 1", _, true, 1.0, true, 15.0)), FinalDiff_BotsChange);
	FinalDiff_Bots = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_final_diff_humans", "7", 
	"If humnas win the map by this many rounds, the bot_difficulty will be raised by 1", _, true, 1.0, true, 15.0)), FinalDiff_HumansChange);
	FinalDiff_Humans = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_advertise", "5", 
	"The number of rounds in between advertisement of iBots (0 to disable)", _, true, 0.0, true, 15.0)), AdvertiseIntervalChange);
	AdvertiseInterval = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_TEAM_BOT", "2", 
	"Team number for bots (2 is T, 3 is CT)", _, true, 2.0, true, 3.0)), TeamBotChange);
	TEAM_BOT = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_Bonus_Easy", "5", 
	"The amount of HP to award a player for killing an Easy level bot", _, true, 0.0, true, 50.0)), EasyBonusChange);
	EasyBonus = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_Bonus_Fair", "5", 
	"The amount of HP to award a player for killing a Fair level bot", _, true, 0.0, true, 50.0)), FairBonusChange);
	FairBonus = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_Bonus_Normal", "5", 
	"The amount of HP to award a player for killing a Normal level bot", _, true, 0.0, true, 50.0)), NormalBonusChange);
	NormalBonus = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_Bonus_Tough", "10", 
	"The amount of HP to award a player for killing a Tough level bot", _, true, 0.0, true, 50.0)), ToughBonusChange);
	ToughBonus = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_Bonus_Hard", "10", 
	"The amount of HP to award a player for killing a Hard level bot", _, true, 0.0, true, 50.0)), HardBonusChange);
	HardBonus = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_Bonus_VeryHard", "15", 
	"The amount of HP to award a player for killing a Very Hard level bot", _, true, 0.0, true, 50.0)), VeryHardBonusChange);
	VeryHardBonus = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_Bonus_Expert", "15", 
	"The amount of HP to award a player for killing an Expert level bot", _, true, 0.0, true, 50.0)), ExpertBonusChange);
	ExpertBonus = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_Bonus_Elite", "20", 
	"The amount of HP to award a player for killing an Elite level bot", _, true, 0.0, true, 50.0)), EliteBonusChange);
	EliteBonus = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_KnifeMultiplier", "2.0", 
	"The multiplier value of HP to award a player for killing a bot with a knife.", _, true, 0.0, true, 50.0)), KnifeMultiplierBonusChange);
	KnifeBonusMultiplier = GetConVarFloat(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_ModifyHP", "1", 
	"Use bot HP feature to increase/decrease bot's HP based on winning streaks?\n1 = YES\n0 = No", _, true, 0.0, true, 1.0)), ModifyHPChange);
	ModifyHP = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_HPBonus", "1", 
	"Use the HP bonus for when players kill bots?\n1 = Yes\n0 = No", _, true, 0.0, true, 1.0)), HPBonusChange);
	HPBonus = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_JoinPartMode", "1", 
	"Which method to use for adjusting bot count when humans join or leave?\n1 = Adjust on Round Start\n2 = Adjust on Round End\n3 = Adjust on Join", _, true, 1.0, true, 3.0)), JoinPartModeChange);
	JoinPartMode = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_SuperNades", "0", 
	"Use super grenades?\n1 = YES\n0 = No", _, true, 0.0, true, 1.0)), UseSuperNadesChange);
	UseSuperNades = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_NadeMultiplyerIncrease", "0.25", 
	"Amount to increase the power of Super Nades as Bots' HP increases", _, true, 0.1, true, 10.0)), SuperNadeIncreaseChange);
	NadeMultiplyerIncrease = GetConVarFloat(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_NadeMultiplyerDecrease", "0.15", 
	"Amount to decrease the power of Super Nades as Bots' HP decreases", _, true, 0.1, true, 10.0)), SuperNadeDecreaseChange);
	NadeMultiplyerDecrease = GetConVarFloat(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_IgnitedNades", "0", 
	"Use ignited nades for VIP players?\nCurrent flag is \"a\", use admin_overrides to change it by over-ridding command \"ibots_vip\" to whatever flag you want\n1 = YES\n0 = No", _, true, 0.0, true, 1.0)), UseIgnitedNadesChange);
	UseIgnitedNades = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_useupdater", "0", 
	"Utilize 'Updater' plugin to auto-update iBots when updates are published?\n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnUseUpdaterChanged);
	UseUpdater = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_ffmode", "0", 
	"Combine the following modes for your choice of FF:\n0 = iBots doesn't manage FF, 1 = No FF for Humans, 2 = No FF for Bots, 4 = No FF for ViPs\nEx. 3 would mean no FF for anyone, 6 would mean no FF for bots and VIPs", _, true, 0.0, true, 7.0)), OnFFModeChanged);
	FFMode = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_start_botdiff", "1", 
	"Starting bot difficulty level", _, true, 0.0, true, 3.0)), OnStartBotDiffChanged);
	StartingBotDiff = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_adjust_botdiff", "1", 
	"Which mode to use to adjust bot_difficulty when the map ends?\n0 = Don't adjust\n1 = Reset to iBots_start_botdiff\n2 = Adjust based on score", _, true, 0.0, true, 2.0)), OnAdjustBotDiffChanged);
	AdjustBotDiff = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_allow_botcontrol", "1", 
	"Allow dead humans to take control of bots to fight against humans?\n1=yes\n0=no", _, true, 0.0, true, 1.0)), OnAllowBotControlChanged);
	AllowBotControl = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_botcontrol_vip", "20", 
	"How many times to allow VIP players to take control of a bot during a map", _, true, 0.0, true, 1000.0)), OnBotControlVIPChanged);
	BotControlTimesVIP = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_botcontrol_reg", "1", 
	"How many times to allow non-VIP players to take control of a bot during a map", _, true, 0.0, true, 1000.0)), OnBotControlREGChanged);
	BotControlTimesREG = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_usebeacon", "1", 
	"Use the beacon on the last surviving bot?\n1=yes\n0=no", _, true, 0.0, true, 1.0)), OnUseBeaconChanged);
	UseBeacon = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_bot_maxhp", "0", 
	"Maximum HP bots are allowed to reach\nUse 0 to have no limit", _, true, 0.0, true, 999.0)), OnBotMaxHPChanged);
	BotMaxHP = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("iBots_botcontrol_msg", "0", 
	"Who to inform when a player takes control of a bot (choose one)?\n0 = No message\n1 = Admins Only\n2 = Everyone", _, true, 0.0, true, 2.0)), OnBotControlMsgChanged);
	BotControlMsg = GetConVarInt(hRandom);
	SetAppend(appended);
	
	hRandom = FindConVar("mp_round_restart_delay");
	if (hRandom == INVALID_HANDLE)
	{
		SetFailState("Unable to hook mp_round_restart_delay");
	}	
	RestartRoundTime = GetConVarFloat(hRandom);
	
	CloseHandle(hRandom);
	
	botsprefix = FindConVar("bot_prefix");
 	
 	if (botsprefix == INVALID_HANDLE)
 	{
 		SetFailState("Unable to hook bot_prefix");
 	}
	
	GetConVarString(botsprefix, OrgPrefix, sizeof(OrgPrefix));
	
	Format(NewPrefix, sizeof(NewPrefix), "%s <difficulty>", OrgPrefix);
	
	#if _DEBUG
		new String:dmsg[MAX_MESSAGE_LENGTH];
		Format(dmsg, sizeof(dmsg), "Changing bot_prefix from %s to %s", OrgPrefix, NewPrefix);
		DebugMessage(dmsg);
	#endif
	
	SetConVarString(botsprefix, NewPrefix);
	
	ibot_quota = FindConVar("bot_quota");
	
	if (ibot_quota == INVALID_HANDLE)
	{
		SetFailState("Unable to hook bot_quota");
	}
	
	Orgbotquota = GetConVarInt(ibot_quota);
	
	ibot_fraglimit = FindConVar("mp_fraglimit");
	
	if (ibot_fraglimit == INVALID_HANDLE)
	{
		SetFailState("Unable to hook mp_fraglimit");
	}
	
	Orgfraglimit = GetConVarInt(ibot_fraglimit);
	
	HookConVarChange((ibot_difficulty = FindConVar("bot_difficulty")), BotDifficultyChange);
	
	if (ibot_difficulty == INVALID_HANDLE)
	{
		SetFailState("Unable to hook bot_difficulty");
	}
	BotDifficulty = GetConVarInt(ibot_difficulty);
	
	ibot_restartgame = FindConVar("mp_restartgame");
	
	if (ibot_restartgame == INVALID_HANDLE)
	{
		SetFailState("Unable to hook mp_restartgame");
	}
	
	botteam = FindConVar("bot_join_team");
	
	if (botteam == INVALID_HANDLE)
	{
		SetFailState("Unable to hook bot_join_team CVar");
	}
	
	GetConVarString(botteam, Orgbotteam, sizeof(Orgbotteam));
	
	SetConVarString(botteam, "T");
	
	humanteam = FindConVar("mp_humanteam");
 	
 	if (humanteam == INVALID_HANDLE)
	{
		SetFailState("Unable to hook mp_humanteam CVar");
	}
	
	GetConVarString(humanteam, Orghumanteam, sizeof(Orghumanteam));
	
	SetConVarString(humanteam, "CT");
	
	TEAM_HUMAN = CS_TEAM_CT;
	
	new String:gdir[PLATFORM_MAX_PATH];
	GetGameFolderName(gdir,sizeof(gdir));
	if (StrEqual(gdir,"csgo",false))
	{
		IsCSGO = true;
	}
	else
	{
		IsCSGO = false;
	}
	
	AutoExecConfig(true, "plugin.iBots");
	
	// Cleaning is an expensive operation and should be done at the end
	if (appended)
	{
		AutoExecConfig_CleanFile();
	}
}

SetAppend(&appended)
{
	if (AutoExecConfig_GetAppendResult() == AUTOEXEC_APPEND_SUCCESS)
	{
		appended = true;
	}
}

public OnVersionChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(newValue, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public MinQuotaChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	MinQuota = GetConVarInt(cvar);
}
	
public BotDifficultyChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	BotDifficulty = GetConVarInt(cvar);
	SetConVarInt(ibot_difficulty, BotDifficulty);
}
	
public MinHPChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	MinHP = GetConVarInt(cvar);
}
	
public iBotsHPIncreaseChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	iBotsHPIncrease = GetConVarInt(cvar);
}
	
public iBotsHPDecreaseChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	iBotsHPDecrease = GetConVarInt(cvar);
}
	
public MaxFragsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	MaxFrags = GetConVarInt(cvar);
	
	if (UseMaxFrags)
	{
		SetConVarInt(ibot_fraglimit, MaxFrags);
	}
}

public UseMaxFragsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseMaxFrags = GetConVarBool(cvar);
	
	switch (UseMaxFrags)
	{
		case true:
		{
			SetConVarInt(ibot_fraglimit, MaxFrags);
		}
		
		case false:
		{
			SetConVarInt(ibot_fraglimit, 0);
		}
	}
}

public iBotsQuotaChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	f_iBotsQuota = GetConVarFloat(cvar);
}

public ManageBotsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ManageBots = GetConVarBool(cvar);
}
	
public MaxBotsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	MaxBots = GetConVarInt(cvar);
}
	
public HumanWinningStreakChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	HumanWinningStreak = GetConVarInt(cvar);
}
	
public HumansStreakMoneyChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	HumansStreakMoney = GetConVarInt(cvar);
}
	
public BotWinningStreakChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	BotWinningStreak = GetConVarInt(cvar);
}
	
public BotsStreakMoneyChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	BotsStreakMoney = GetConVarInt(cvar);
}
	
public StreakMoneyChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	StreakMoney = GetConVarInt(cvar);
}
	
public WinningDifferenceChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	WinningDifference = GetConVarInt(cvar);
}
	
public FinalDiff_BotsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	FinalDiff_Bots = GetConVarInt(cvar);
}
	
public FinalDiff_HumansChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	FinalDiff_Humans = GetConVarInt(cvar);
}
	
public AdvertiseIntervalChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AdvertiseInterval = GetConVarInt(cvar);
}

//public TeamHumanChange(Handle:cvar, const String:oldVal[], const String:newVal[])
//{
//	TEAM_HUMAN = GetConVarInt(cvar);
//}

public EasyBonusChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	EasyBonus = GetConVarInt(cvar);
}

public FairBonusChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	FairBonus = GetConVarInt(cvar);
}

public NormalBonusChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	NormalBonus = GetConVarInt(cvar);
}

public ToughBonusChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ToughBonus = GetConVarInt(cvar);
}

public HardBonusChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	HardBonus = GetConVarInt(cvar);
}

public VeryHardBonusChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	VeryHardBonus = GetConVarInt(cvar);
}

public ExpertBonusChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ExpertBonus = GetConVarInt(cvar);
}

public EliteBonusChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	EliteBonus = GetConVarInt(cvar);
}

public KnifeMultiplierBonusChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	KnifeBonusMultiplier = GetConVarFloat(cvar);
}

public ModifyHPChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ModifyHP = GetConVarBool(cvar);
}

public JoinPartModeChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	JoinPartMode = GetConVarInt(cvar);
}

public HPBonusChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	HPBonus = GetConVarBool(cvar);
	
	if (HPBonus)
	{
		SetConVarString(botsprefix, NewPrefix);
	}
	else
	{
		SetConVarString(botsprefix, OrgPrefix);
	}
}

public ReservedSlotsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ireservedslots = GetConVarInt(cvar);
}

public UseSuperNadesChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseSuperNades = GetConVarBool(cvar);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			switch (UseSuperNades)
			{
				case true:
				{
					SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				}
				
				case false:
				{
					SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				}
			}
		}
	}
}

public SuperNadeIncreaseChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	NadeMultiplyerIncrease = GetConVarFloat(cvar);
}

public SuperNadeDecreaseChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	NadeMultiplyerDecrease = GetConVarFloat(cvar);
}

public UseIgnitedNadesChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseIgnitedNades = GetConVarBool(cvar);
}

public TeamBotChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	TEAM_BOT = GetConVarInt(cvar);
	
	if (TEAM_BOT == CS_TEAM_T)
	{
		SetConVarString(botteam, "T");
		SetConVarString(humanteam, "CT");
		TEAM_HUMAN = CS_TEAM_CT;
	}
	else
	{
		SetConVarString(botteam, "CT");
		SetConVarString(humanteam, "T");
		TEAM_HUMAN = CS_TEAM_T;
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if (IsFakeClient(i))
		{
			CS_SwitchTeam(i, TEAM_BOT);
		}
		else
		{
			CS_SwitchTeam(i, TEAM_HUMAN);
		}
	}
}

public OnUseUpdaterChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseUpdater = GetConVarBool(cvar);
}

public OnFFModeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	FFMode = GetConVarInt(cvar);
}

public OnAdjustBotDiffChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AdjustBotDiff = GetConVarInt(cvar);
}

public OnStartBotDiffChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	StartingBotDiff = GetConVarInt(cvar);
}

public OnAllowBotControlChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AllowBotControl = GetConVarBool(cvar);
}

public HumansStreakDiffChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	HumansStreakDiff = GetConVarInt(cvar);
}

public BotsStreakDiffChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	BotsStreakDiff = GetConVarBool(cvar);
}

public OnBotControlVIPChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	BotControlTimesVIP = GetConVarInt(cvar);
}

public OnBotControlREGChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	BotControlTimesREG = GetConVarInt(cvar);
}

public OnUseBeaconChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseBeacon = GetConVarBool(cvar);
}

public OnBotMaxHPChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	BotMaxHP = GetConVarInt(cvar);
}

public OnBotControlMsgChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	BotControlMsg = GetConVarInt(cvar);
}

public Action:Cmd_SwitchTeams(client, args)
{	
	if (client == 0)
	{
		ReplyToCommand(client, "In-game command only");
		return Plugin_Handled;
	}
	
	if (TEAM_BOT == CS_TEAM_T)
	{
		TEAM_BOT = CS_TEAM_CT;
		SetConVarString(botteam, "CT");
		TEAM_HUMAN = CS_TEAM_T;
		SetConVarString(humanteam, "T");
	}
	else
	{
		TEAM_BOT = CS_TEAM_T;
		SetConVarString(botteam, "T");
		TEAM_HUMAN = CS_TEAM_CT;
		SetConVarString(humanteam, "CT");
	}
	
	new Handle:ibot_bot_team = INVALID_HANDLE;	
	ibot_bot_team = FindConVar("iBots_TEAM_BOT");
	if (ibot_bot_team == INVALID_HANDLE)
	{
		SetFailState("[iBots] Unable to hook cvar iBots_TEAM_BOT");
	}
	SetConVarInt(ibot_bot_team, TEAM_BOT);
	CloseHandle(ibot_bot_team);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
		{
			if (IsFakeClient(i))
			{
				CS_SwitchTeam(i, TEAM_BOT);
			}
			else
			{
				CS_SwitchTeam(i, TEAM_HUMAN);
			}
		}
	}
	
	SetConVarInt(ibot_restartgame, 1);
	
	CreateTimer(2.5, Timer_SetScore);
	
	CPrintToChat(client, "%t", "Switched");
	
	return Plugin_Continue;
}

public Action:Cmd_iBotsHP(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[iBots] Usage: sm_ibotshp <amount>");
		return Plugin_Handled;
	}
	
	new String:arg[10];
	arg[0] = '\0';
	
	GetCmdArg(1, arg, sizeof(arg));
	new bothp = StringToInt(arg);
	
	if (bothp < MinHP || bothp > BotMaxHP)
	{
		ReplyToCommand(client, "[iBots] Acceptable value is %i-999", MinHP);
		return Plugin_Handled;
	}
	
	iBotsHealth = bothp;
	CPrintToChatAllEx(client, "[{green}iBots{default}] iBots HP set to {green}%i {default}by {teamcolor}%N", bothp, client);
	
	return Plugin_Continue;
}

ChangeBotDifficulty(diff)
{
	if (diff == BotDifficulty || diff < 0 || diff > 3)
	{
		return;
	}
	
	SetConVarInt(ibot_difficulty, diff);
	
	new FirstBot = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && !IsClientSourceTV(i))
		{
			if (FirstBot == 0)
			{
				FirstBot = i;
				ClearTimer(ClientTimer[i]);
				
				CreateTimer(3.0, Timer_KickLast, i);
				continue;
			}
			
			KickClient(i, "Changing bot difficulty");
		}
	}
}

/**
 * Function to clear/kill the timer and set to INVALID_HANDLE if it's still active
 * 
 * @param	timer		Handle of the timer
 * @noreturn
 */
ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}     
}

#if _DEBUG
DebugMessage(const String:msg[], any:...)
{
	LogMessage("[iBots DEBUG] %s", msg);
	PrintToChatAll("[iBots DEBUG] %s", msg);
}
#endif

// **************************************************
// SMLib Functions (thanks to berni)
// **************************************************
/**
 * Prints white text to the right-center side of the screen
 * for one client. Does not work in all games.
 * Line Breaks can be done with "\n".
 * 
 * @param client		Client Index.
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @return				True on success, false if this usermessage doesn't exist.
 */
bool:Client_PrintKeyHintText(client, const String:format[], any:...)
{
	if (IsCSGO)
	{
		return false;
	}
	
	new Handle:userMessage = StartMessageOne("KeyHintText", client);
	
	if (userMessage == INVALID_HANDLE)
	{
		return false;
	}

	decl String:buffer[254];
	buffer[0] = '\0';

	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);

	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available
		&& GetUserMessageType() == UM_Protobuf)
	{
		PbSetString(userMessage, "hints", format);
	}
	else
	{
		BfWriteByte(userMessage, 1); 
		BfWriteString(userMessage, buffer); 
	}

	EndMessage();
	
	return true;
}

/**
 * Prints white text to the right-center side of the screen
 * for all clients. Does not work in all games.
 * Line Breaks can be done with "\n".
 * 
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @noreturn
 */
Client_PrintKeyHintTextToAll(const String:format[], any:...)
{
	decl String:buffer[254];
	buffer[0] = '\0';
	
	for (new client=1; client <= MaxClients; client++) 
	{
		
		if (!IsClientInGame(client)) 
		{
			continue;
		}
		
		SetGlobalTransTarget(client);
		VFormat(buffer, sizeof(buffer), format, 2);
		Client_PrintKeyHintText(client, buffer);
	}
}