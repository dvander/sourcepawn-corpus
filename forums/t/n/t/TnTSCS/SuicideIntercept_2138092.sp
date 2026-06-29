/*
This plugin will intercept player suicide attempts by capturing the following commands
	* kill
	* jointeam (removed 9/5/11) (added back 9/6/11)
	* joinclass
	* spectate (removed 9/5/11) (added back 9/6/11)
	* explode

Plugin can be en/disabled via cvar sm_suicideintercept_enabled 1/0
Configurable number of delay seconds to carry out players requested suicide or set sm_suicideintercept_delaydeathtime to 0 to block suicide command

Plugin idea/request from 'wazzgod' - http://forums.alliedmods.net/showthread.php?t=162870

A list of plugins by me at http://www.sourcemod.net/plugins.php?cat=0&mod=0&title=&author=TnTSCS&description=&search=1

	Change Log
			
		* Version 1.0
			* Initial public release
			
		* Version 1.1
			* Added ability to simply block the suicide command by setting sm_suicideintercept_delaydeathtime to 0 in config file
			
		* Version 1.2
			* Applied KyleS' suggestions regarding the FindConVar
			* Added min 0 and max 1 to sm_suicideintercept_enabled
			* Added ability to modify the settings while in game (enable or disable it, change the death time)
			* Updated description to include ability to block the suicide command
			
		* Version 1.2a
			* Cleaned up code a bit and fixed the enabled bool
			
		* Version 1.3
			* Added translation file and cleaned up code (handles and hookconvarchange) according to KyleS' suggestions.
			* Removed auto config file - cvars can just be set in sourcemod.cfg if needed, or changed via console with rcon.
			
		* Version 1.3a
			* Added colors include
			
		* Version 1.4
			* Removed hooks for "spectate" and "jointeam" <-- to be added back in future version
			
		* Version 1.4a
			* Added back hooks for "spectate" and "jointeam"
			
		* Version 1.4b
			* Fixed janky translation file - now it has proper variables :)
			
		* Version 1.5
			* Redesigned the code to be cleaner and more effecient
			* Fixed the bad Int of -1 in convars
			* Added new cvars to allow configuration of blocking the "kill", "explode", "spectate", "jointeam", and "joinclass" commands
				-	Reworked some of the code so it keeps itself clean
				
		* Version 1.5.1
			* Added Updater capability
			
		* Version 1.5.2
			* Removed requirement for cstrike
			
		* Version 1.5.3
			* Added flag FCVAR_DONTRECORD to plugin version CVar
			* Added CVar for Updater - defaulted to off
			* Commented some more of the code

		* Version 1.5.4
			* Added timer to ignore suicide commands by player for n seconds after player spawn (by request) - disabled by default
			* Added bool for checks if plugin is enabled or not for the console commands
			* Modified the variable in the translation file so it doesn't print so many 0's in the delay notification
		
		* Version 1.5.5
			* Fixed error: Native "IsPlayerAlive" reported: Client # is not in game
		
		* Version 1.5.6
			* Added CVar to disable immunity
			
	To Do List
		* Nothing - request something		
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>
#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL "http://dl.dropbox.com/u/3266762/SuicideIntercept.txt"

#define PLUGIN_VERSION "1.5.6"

#define PANEL_TEAM "team"

new Handle:ClientTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:ClientTimer2[MAXPLAYERS+1] = INVALID_HANDLE;

new Float:DelaySpecTime;
new Float:DelayDeathTime;
new Float:DelayJointeamTime;
new Float:AllowSuicide;

new bool:BlockSuicides = false;
new bool:BlockSpectate = false;
new bool:BlockJointeam = false;
new bool:UseUpdater = false;
new bool:PluginEnabled = true;
new bool:AllowImmunity = true;

new bool:MoveToSpec[MAXPLAYERS+1] = false;
new bool:JoinTeam[MAXPLAYERS+1] = false;
new bool:JoinClass[MAXPLAYERS+1] = false;

public Plugin:myinfo = 
{
	name = "Suicide Intercept",
	author = "TnTSCS aka ClarkKent",
	description = "Intercepts suicide commands and blocks the command or delays it by X seconds",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1520337"
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
	// Create this plugins CVars
	new Handle:hRandom;// KyleS hates handles
	
	HookConVarChange((hRandom = CreateConVar("sm_suicideintercept_version", PLUGIN_VERSION, 
	"Version of 'Suicide Intercept'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_suicideintercept_enabled", "1", 
	"Is Suicide Intercept Enabled?\n1 for Enabled\n0 for Disabled", _, true, 0.0, true, 1.0)), OnEnabledChanged);
	PluginEnabled = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_suicideintercept_blocksuicides", "0", 
	"Should the commands 'kill' and 'explode' just be blocked instead of delayed?", _, true, 0.0, true, 1.0)), OnBlockSuicidesChanged);
	BlockSuicides = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_suicideintercept_delaydeathtime", "7", 
	"How many seconds to wait before forcing the suicide on the player.\nUse '0' if you want to allow players to use 'kill' and 'explode'\nRequires sm_suicideintercept_blocksuicides to be 0", _, true, 0.0)), OnDeathTimeChanged);
	DelayDeathTime = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_suicideintercept_blockspectate", "0", 
	"Should the command 'spectate' be blocked instead of delayed?", _, true, 0.0, true, 1.0)), OnBlockSpectateChanged);
	BlockSpectate = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_suicideintercept_delayspectime", "7", 
	"How many seconds to wait before sending the player to spectate.\nUse '0' if you want to allow players to use 'spectate'\nRequires sm_suicideintercept_blockspectate to be 0", _, true, 0.0)), OnSpecTimeChanged);
	DelaySpecTime = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_suicideintercept_blocksjointeam", "0", 
	"Should the commands 'jointeam' and 'joinclass' be blocked instead of delayed?", _, true, 0.0, true, 1.0)), OnBlockJointeamChanged);
	BlockJointeam = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_suicideintercept_delayjointeamtime", "7", 
	"How many seconds to wait before switching the players team.\nUse '0' if you want to allow players to use 'joinclass' and 'jointeam'\nRequires sm_suicideintercept_blockjointeam to be 0", _, true, 0.0)), OnJointeamTimeChanged);
	DelayJointeamTime = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_suicideintercept_useupdater", "0", 
	"Utilize 'Updater' plugin to auto-update Suicide Intercept when updates are published?\n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnUseUpdaterChanged);
	UseUpdater = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_suicideintercept_time", "0", 
	"Number of seconds after player spawn to allow them to use a suicide command without interception.\nSet to 0 to disable grace period.", _, true, 0.0, true, 180.0)), OnTimeChanged);
	AllowSuicide = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_suicideintercept_immunity", "1", 
	"Allow immunity using command override bypass_suicideintercept?", _, true, 0.0, true, 1.0)), OnImmunityChanged);
	AllowImmunity = GetConVarBool(hRandom);
	
	CloseHandle(hRandom); // KyleS hates handles.
	
	// Load translation file
	LoadTranslations("SuicideIntercept.phrases");
	
	// Execute the config file
	AutoExecConfig(true, "SuicideIntercept.plugin");
	
	// Register the cancel command 
	RegConsoleCmd("sm_cancel", Command_Cancel, "This command will cancel your pending suicide commands");
	
	// Hook game events
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	// Add command listeners
	AddCommandListener(Command_InterceptSuicide, "kill");
	AddCommandListener(Command_InterceptSuicide, "explode");
	AddCommandListener(Command_InterceptSuicide, "spectate");
	AddCommandListener(Command_InterceptSuicide, "jointeam");
	AddCommandListener(Command_InterceptSuicide, "joinclass");
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
	// If CVar to use Updater is true, add Chicken to Updater's list of plugins
	if(UseUpdater && StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

/**
 * Called when the map has loaded, servercfgfile  ( server.cfg ) has been 
 * executed, and all plugin configs are done executing.  This is the best
 * place to initialize plugin functions which are based on cvar data.  
 *
 * @note This will always be called once and only once per map.  It will be 
 * called after OnMapStart (  ).
 *
 * @noreturn
 */
public OnConfigsExecuted()
{	
	// If CVar to use Updater is true, check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if(UseUpdater && LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

/**
 * Callback for player command sm_cancel
 * 
 * @param client		client index
 * @param args		arguments of the command
 * 
 * @noreturn 
 */
public Action:Command_Cancel(client, args)
{
	if(!PluginEnabled || client == 0)
	{
		return Plugin_Handled;
	}
	
	if(!MoveToSpec[client] && !JoinTeam[client] && !JoinClass[client] && ClientTimer[client] == INVALID_HANDLE)
	{
		ReplyToCommand(client, "%t", "No Requests");
		return Plugin_Handled;
	}
		
	ClearRequests(client);
	ClearTimer(ClientTimer[client]);
	ClearTimer(ClientTimer2[client]);
	CPrintToChat(client, "%t", "Requests Cancelled");
	return Plugin_Continue;
}

/**
 * Callback for when player uses any of the following commands:
 * 	kill	spectate	explode	joinclass	jointeam
 * 
 * @param client		client index
 * @param	command	command string used
 * @param	args		arguments of the command
 * 
 * @noreturn
 */
public Action:Command_InterceptSuicide(client, const String:command[], args)
{
	// If invalid client, plugin not enabled, or suicide is permitted for player
	if(!PluginEnabled || client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || 
		IsFakeClient(client) || GetClientTeam(client) < 2 || ClientTimer2[client] != INVALID_HANDLE)
	{
		return Plugin_Continue;
	}
	
	if(AllowImmunity && CheckCommandAccess(client, "bypass_suicideintercept", ADMFLAG_ROOT))
	{
		return Plugin_Continue;
	}
	
	new SuicideType = 0;
	
	if(StrEqual(command, "kill", false) || StrEqual(command, "explode", false))
		SuicideType = 1;
	else if(StrEqual(command, "spectate", false))
		SuicideType = 2;
	else if(StrEqual(command, "jointeam", false))
		SuicideType = 3;
	else if(StrEqual(command, "joinclass", false))
		SuicideType = 4;
		
	switch (SuicideType)
	{
		// Player used "kill" or "explode"
		case 1:
		{
			if(DelayDeathTime == 0.0 && !BlockSuicides)
			{
				return Plugin_Continue;
			}
			
			// Notify player their suicide attempt was intercepted
			PrintCenterText(client, "%t", "Intercepted");
			
			if(BlockSuicides)
			{
				// Notify player their suicide attempt was denied
				CPrintToChat(client, "%t", "Denied");
				return Plugin_Handled;
			}
			
			// Notify player their suicide attempt will be delayed
			CPrintToChat(client, "%t", "Seconds", DelayDeathTime);
			CPrintToChat(client, "%t", "Request", command);
			
			// Create a timer to carry out the players suicide request
			ClearTimer(ClientTimer[client]);
			ClientTimer[client] = CreateTimer(DelayDeathTime, Force_Suicide, client);
			
			return Plugin_Handled;
		}
		
		// Player used "spectate"
		case 2:
		{
			if(DelaySpecTime == 0.0 && !BlockSpectate)
			{
				return Plugin_Continue;
			}
			
			// Notify player their spectate attempt was intercepted
			PrintCenterText(client, "%t", "SpecIntercepted");
			
			if(BlockSpectate)
			{
				// Notify player their spectate attempt will be denied				
				CPrintToChat(client, "%t", "SpecDenied");
				CPrintToChat(client, "%t", "Request", command);
				ClearRequests(client);
				MoveToSpec[client] = true;
				return Plugin_Handled;
			}
			
			// Notify player their spectate attempt will be delayed
			CPrintToChat(client, "%t", "SpecSeconds", DelaySpecTime);
			CPrintToChat(client, "%t", "Request", command);
			
			// Create a timer to carry out the players spectate request
			ClearTimer(ClientTimer[client]);
			ClientTimer[client] = CreateTimer(DelaySpecTime, Force_Spectate, client);
			
			return Plugin_Handled;
		}
		
		// Player used "jointeam"
		case 3:
		{
			if(DelayJointeamTime == 0.0 && !BlockJointeam)
			{
				return Plugin_Continue;
			}
			
			// Notify player their Jointeam attempt was intercepted
			PrintCenterText(client, "%t", "JoinIntercepted");
			
			if(BlockJointeam)
			{
				// Notify player their suicide attempt was denied
				CPrintToChat(client, "%t", "JoinDenied");
				CPrintToChat(client, "%t", "Request", command);
				ClearRequests(client);
				JoinTeam[client] = true;
				return Plugin_Handled;
			}
			
			// Notify player their spectate attempt will be delayed
			CPrintToChat(client, "%t", "JoinSeconds", DelayJointeamTime);
			CPrintToChat(client, "%t", "Request", command);
			
			// Create a timer to carry out the players spectate request
			ClearTimer(ClientTimer[client]);
			ClientTimer[client] = CreateTimer(DelayJointeamTime, Force_Jointeam, client);
			
			return Plugin_Handled;
		}
		
		// Player used "joinclass"
		case 4:
		{
			if(DelayJointeamTime == 0.0 && !BlockJointeam)
			{
				return Plugin_Continue;
			}
			
			// Notify player their joinclass attempt was intercepted
			PrintCenterText(client, "%t", "JoinCIntercepted");
			
			if(BlockJointeam)
			{
				// Notify player their joinclass attempt was denied
				CPrintToChat(client, "%t", "JoinCDenied");
				CPrintToChat(client, "%t", "Request", command);
				ClearRequests(client);
				JoinClass[client] = true;
				return Plugin_Handled;
			}
			
			// Notify player their joinclass attempt will be delayed
			CPrintToChat(client, "%t", "JoinCSeconds", DelayJointeamTime);
			CPrintToChat(client, "%t", "Request", command);
			
			// Create a timer to carry out the players spectate request
			ClearTimer(ClientTimer[client]);
			ClientTimer[client] = CreateTimer(DelayJointeamTime, Force_Joinclass, client);
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

/**
 * Timer function
 * 
 * @param	timer		Handle of timer
 * @param	client		client index
 * 
 * @noreturn
 */
public Action:Force_Suicide(Handle:timer, any:client)
{
	if(ClientTimer[client] != INVALID_HANDLE)
	{		
		// Make sure client is still in game and didn't rage quit or get killed
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			// Notify player their suicide request has been carried out
			PrintCenterText(client,"%t", "Granted");
			CPrintToChat(client, "%t", "RequestGranted");
			
			// Kill player via suicide
			ForcePlayerSuicide(client);
		}
		ClientTimer[client] = INVALID_HANDLE;
	}
}

/**
 * Timer function
 * 
 * @param	timer		Handle of timer
 * @param	client		client index
 * 
 * @noreturn
 */
public Action:Force_Spectate(Handle:timer, any:client)
{
	if(ClientTimer[client] != INVALID_HANDLE)
	{
		// Make sure client is still in game and didn't rage quit
		if(IsClientInGame(client) && GetClientTeam(client) > 1)
		{
			ChangeClientTeam(client, 1);
		}
		ClientTimer[client] = INVALID_HANDLE;
	}
}

/**
 * Timer function
 * 
 * @param	timer		Handle of timer
 * @param	client		client index
 * 
 * @noreturn
 */
public Action:Force_Jointeam(Handle:timer, any:client)
{
	if(ClientTimer[client] != INVALID_HANDLE)
	{
		// Make sure client is still in game and didn't rage quit
		if(IsClientInGame(client))
		{
			ForcePlayerSuicide(client);
			ChangeClientTeam(client, 1);
			ShowVGUIPanel(client, PANEL_TEAM);
		}
		ClientTimer[client] = INVALID_HANDLE;
	}
}

/**
 * Timer function
 * 
 * @param	timer		Handle of timer
 * @param	client		client index
 * 
 * @noreturn
 */
public Action:Force_Joinclass(Handle:timer, any:client)
{
	if(ClientTimer[client] != INVALID_HANDLE)
	{
		// Make sure client is still in game and didn't rage quit
		if(IsClientInGame(client))
		{
			new team = GetClientTeam(client);
			ForcePlayerSuicide(client);
			ChangeClientTeam(client, 1);
			ChangeClientTeam(client, team);
		}
		ClientTimer[client] = INVALID_HANDLE;
	}
}

/**
 * Timer function
 * 
 * @param	timer		Handle of timer
 * @param	client		client index
 * 
 * @noreturn
 */
public Action:Timer_ResetAllowSpawn(Handle:timer, any:client)
{
	ClearTimer(ClientTimer2[client]);
}

/**
 * 	"player_spawn"				// player spawned in game
 *	{
 *		"userid"	"short"		// user ID on server
 *	}
 */
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if(IsFakeClient(client))
	{
		return;
	}

	if(AllowSuicide > 0)
	{
		ClearTimer(ClientTimer2[client]);
		ClientTimer2[client] = CreateTimer(AllowSuicide, Timer_ResetAllowSpawn, client);
	}
}

/**
*	"player_death"				// a game event, name may be 32 characters long	
*	{
*		// this extents the original player_death by a new fields
*		"userid"		"short"   	// user ID who died				
*		"attacker"		"short"	// user ID who killed
*		"weapon"		"string" 	// weapon name killer used 
*		"headshot"		"bool"		// singals a headshot
*		"dominated"		"short"	// did killer dominate victim with this kill
*		"revenge"		"short"	// did killer get revenge on victim with this kill
*	}
*/
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	ClearTimer(ClientTimer[client]);
	ClearTimer(ClientTimer2[client]);
	
	if(MoveToSpec[client] || JoinTeam[client] || JoinClass[client])
	{
		CheckRequests(client);
	}
}

/**
*	"round_end"
*	{
*		"winner"	"byte"		// winner team/user i
*		"reason"	"byte"		// reson why team won
*		"message"	"string"	// end round message 
*	}
*/
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(MoveToSpec[i] || JoinTeam[i] || JoinClass[i])
		{
			CheckRequests(i);
		}
	}
}

/**
 * Called when a client is disconnecting from the server.
 *
 * @param client		Client index.
 * @noreturn
 * 
 * Note - You still need to check IsClientInGame(client) if you want to do the client specific stuff (exvel)
 */
public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		ClearTimer(ClientTimer[client]);
		ClearTimer(ClientTimer2[client]);
		ClearRequests(client);
	}
}

/**
 * Function to determine the request the client made
 * 
 * @param	client		client index
 * @noreturn
 */
public CheckRequests(client)
{	
	new ReqType = 0;
	
	if(MoveToSpec[client])
	{
		ReqType = 1;
	}
	
	if(JoinTeam[client])
	{
		ReqType = 2;
	}
	
	if(JoinClass[client])
	{
		ReqType = 3;
	}
	
	if(ReqType > 0)
	{
		HandleRequests(client, ReqType);
	}
}
/**
 * Function to carry out the request the client made
 * 
 * @param	client			client index
 * @param	RequestType	ReqType from CheckRequests
 * @noreturn
 */
public HandleRequests(client, RequestType)
{
	if(IsClientInGame(client))
	{
		switch (RequestType)
		{
			case 1: // Move to spectate
			{			
				if(GetClientTeam(client) > 1)
				{
					ChangeClientTeam(client, 1);
					CPrintToChat(client, "%t", "SpecRequestGranted");
				}
			}
			
			case 2: // Jointeam
			{
				ChangeClientTeam(client, 1);
				ShowVGUIPanel(client, PANEL_TEAM);
				CPrintToChat(client, "%t", "JoinRequestGranted");
			}
			
			case 3: // Joinclass
			{
				new team = GetClientTeam(client);
				ChangeClientTeam(client, 1);
				ChangeClientTeam(client, team);
				CPrintToChat(client, "%t", "JoinCRequestGranted");
			}
		}
		
		ClearRequests(client);
	}
}

/**
 * Function to clear the requests
 * 
 * @param	client		client index
 * @noreturn
 */
public ClearRequests(client)
{
	MoveToSpec[client] = false;
	JoinTeam[client] = false;
	JoinClass[client] = false;
}

/**
 * Function to clear/kill the timer and set to INVALID_HANDLE if it's still active
 * 
 * @param	timer		Handle of the timer
 * @noreturn
 */
public ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}     
}

public OnVersionChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(newValue, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnEnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	switch (StringToInt(newVal))
	{
		case 0:
		{
			// Remove command listeners
			RemoveCommandListener(Command_InterceptSuicide, "kill");
			RemoveCommandListener(Command_InterceptSuicide, "explode");
			RemoveCommandListener(Command_InterceptSuicide, "spectate");
			RemoveCommandListener(Command_InterceptSuicide, "jointeam");
			RemoveCommandListener(Command_InterceptSuicide, "joinclass");
			
			// UnHook game events
			UnhookEvent("player_death", Event_PlayerDeath);
			UnhookEvent("round_end", Event_RoundEnd);
			UnhookEvent("player_spawn", Event_PlayerSpawn);
			
			PluginEnabled = false;
		}
		
		case 1:
		{
			// Add command listeners
			AddCommandListener(Command_InterceptSuicide, "kill");
			AddCommandListener(Command_InterceptSuicide, "explode");
			AddCommandListener(Command_InterceptSuicide, "spectate");
			AddCommandListener(Command_InterceptSuicide, "jointeam");
			AddCommandListener(Command_InterceptSuicide, "joinclass");
			
			// Hook game events
			HookEvent("player_death", Event_PlayerDeath);
			HookEvent("round_end", Event_RoundEnd);
			HookEvent("player_spawn", Event_PlayerSpawn);
			
			PluginEnabled = true;
		}
	}
}

public OnDeathTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DelayDeathTime = GetConVarFloat(cvar);
}

public OnSpecTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DelaySpecTime = GetConVarFloat(cvar);
}

public OnJointeamTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DelayJointeamTime = GetConVarFloat(cvar);
}

public OnBlockSuicidesChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	BlockSuicides = GetConVarBool(cvar);
}

public OnBlockSpectateChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	BlockSpectate = GetConVarBool(cvar);
}

public OnBlockJointeamChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	BlockJointeam = GetConVarBool(cvar);
}

public OnUseUpdaterChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseUpdater = GetConVarBool(cvar);
}

public OnTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AllowSuicide = GetConVarFloat(cvar);
}

public OnImmunityChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AllowImmunity = GetConVarBool(cvar);
}