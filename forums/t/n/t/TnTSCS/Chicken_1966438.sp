/* Chicken.sp

Description: Chicken Plugin Duh!!

Versions: 0.5

Changelog:

0.1 - Initial Release
0.2 - removed console errors that repeat and cause server lag and require server reboot.
0.3 - Repaired if player has knife out when turnd into chicken, player don't get 200hp
    - Added let chicken keep and plant bomb
0.4 - Repard if player leaves game while a chicken errors loop in console and server needs reboot. 
    - Added let Chicken keep and use a he-grennade 

- sm_chicken <player/@ALL/@CT/@T> <1|0>

0.5 - reworked the plugin with updated code with help from Peace-Maker and DarthNinja  ( example from his cash.sp )
    - renamed plugin from sm_chicken to Chicken
    - special thanks to pred, dalto, techknow, peace-maker, and darthninja for their contributions, whether or 
	  not they know it

0.6 - fixed the bug where player's guns were turned to knives dropped after they became chickens which caused 
      knives to litter the map.
    - Added back #pragma semicolon 1
	- Changed the messages sent to players to be more aesthetic
	
0.7		+	started using sdkhooks to block the pickup of weapons while a chicken
		*	Rewrote a lot of the code to clean it up

0.7.1		+	Used some stocks and functions from SMLib - thanks goes to benri for those
0.7.2		+	Added config file
0.7.3		*	Misc code fixes regarding PrecacheModel
0.7.4		+	Added "Updater" capability
0.7.5		+	Added translation file.  Went through and commented a lot of the code.
0.7.6		*	Fixed sm_chicken_version - it now has FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY
0.7.6.1	*	Plugin now has 4 digit version number.  
		+	Added CVar for Updater.  
		+	Added FCVAR_DONTRECORD flag to plugin version CVar
		+	Added speed of chicken CVar
0.7.6.2	*	Fixed bug where some clients would not be issued a pistol on the round after being a chicken
			+	Added Event_RoundEnd and code for when mp_restartround is used
		+	Added a stock for UndoChicken to streamline the .sp file
		+	Added CS_OnBuyCommand so player's cannot buy weapons while a chicken (saving them their money)
			+	Included a timer so as to not flood the player's chat
		*	Change bool IsPlayerChicken to PlayerIsChicken (I like the statement rather than the question)

0.7.6.3	+	Added chicken vote (!votechicken) so, if enough players vote for it, the next round will be a chicken round

0.7.6.4	*	Enhanced the code to add the model/material/sound files to the download tables.
		+	Added a couple new entries to the translation files.

0.7.6.5	+	Added FOV resets when DoChicken executed to address bug if player is turned into a chicken while zoomed in with a scope.
		*	Changed to using ClientSerial instead of ClientID in timer's involving clients

0.8.0.0	*	Added ability to retain weapons when turned back from a chicken (cvar controlled)
		*	Plugin now grabs player's current model prior to changing to chicken and will set player back to that skin if turned back to a human
			*	This makes this plugin work with CS:GO (and probably any other source game)

	To Do List:
		*	Add chicken death sound capability to CS:GO
*/

// Comment out to not require semicolons at the end of each line of code.
#pragma semicolon 1

// Plugin includes
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <colors>
#undef REQUIRE_PLUGIN
#include <updater>

// Plugin defines
#define PLUGIN_VERSION "0.8.0.0"
#define PLUGIN_PREFIX "{green}[{lightgreen}SM Chicken{green}]"
#define UPDATE_URL "http://dl.dropbox.com/u/3266762/Chicken.txt"

#define 	MAX_FILE_LEN 			256
#define 	MAX_WEAPONS 			48
#define		MAX_WEAPON_STRING		80

#define 	HEGrenadeOffset 		11	// (11 * 4)
#define 	FlashbangOffset 		12	// (12 * 4)
#define 	SmokegrenadeOffset		13	// (13 * 4)
#define		IncenderyGrenadesOffset	14	// (14 * 4) Also Molotovs
#define		DecoyGrenadeOffset		15	// (15 * 4)

public Plugin:myinfo = 
{
	name = "Chicken",
	author = "TnTSCS, TechKnow, Peace-Maker",
	description = "Turns Players Into Chickens with Knives",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=156898"
};

// Plugin variables
new String:g_soundName[MAX_FILE_LEN];
new String:g_ctchicken[MAX_FILE_LEN];
new String:g_tchicken[MAX_FILE_LEN];
new String:PlayerOldSkin[MAXPLAYERS+1][MAX_FILE_LEN];

new Float:PlayerGravity;

new bool:IsCSGO;
new bool:UseModelColors;
new SaveWeapons; // 3 modes for save weapons
new bool:PlayerHasWeapons[MAXPLAYERS+1];
new bool:PlayerHasDefuser[MAXPLAYERS+1];

new bool:chicken = false;
new bool:AllowNades = true;
new bool:UseUpdater = false;
new bool:PlayerIsChicken[MAXPLAYERS+1] = {false, ...};

new onoff;
new health;
new Float:speed;
new Float:restarttime;

new Handle:RG_Timer = INVALID_HANDLE; // Restart Game timer

new bool:AdviseOfNoBuy[MAXPLAYERS+1] = {true, ...};

new Votes = 0; // Total number of !votechicken votes
new Voters = 0; // Total players connected, not including fake clients
new Float:VotesNeeded = 0.0; // Necessary votes before vote chicken starts
new Float:VotesRequired = 0.0; // Necessary votes to pass the chicken vote
new bool:Voting = false;  // True if a vote is already in progress
new bool:Voted[MAXPLAYERS+1] = {false, ...}; // True/False for if the player has voted or not
new bool:ChickenRound = false; // OnRoundStart should all players be switched to a chicken?
new bool:CanVoteChicken = true; // True if players are allowed to start a new !votechicken
new Handle:ChickenVoteDelayTimer = INVALID_HANDLE; // Vote delay timer
new Handle:CheckChickenVote = INVALID_HANDLE; // When to check/count the votes
new Float:fChickenVoteTimer = 0.0; // Float to hold the amont of time to delay another chicken vote

new String:PrimarySlot[MAXPLAYERS+1][MAX_WEAPON_STRING];
new String:SecondarySlot[MAXPLAYERS+1][MAX_WEAPON_STRING];

new HEGrenades[MAXPLAYERS+1];
new FlashBangs[MAXPLAYERS+1];
new SmokeGrenades[MAXPLAYERS+1];
new INCGrenades[MAXPLAYERS+1];
new DecoyGrenades[MAXPLAYERS+1];

new T_Color[4];
new CT_Color[4];

/**
 * Called when the plugin is fully initialized and all known external references 
 * are resolved. This is only called once in the lifetime of the plugin, and is 
 * paired with OnPluginEnd (  ).
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
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	// Handle and CVar stuff
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	new Handle:hRandom; // KyleS hates handles
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_version", PLUGIN_VERSION, 
	"Version of 'Chicken'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD)), OnVersionChanged);

	HookConVarChange((hRandom = CreateConVar("sm_chicken_sound", "smchicken/chicken.wav", 
	"Path to the sound to play when player dies as a chicken (home folder is cstrike/sound)")), ChickenSoundChanged);
	GetConVarString(hRandom, g_soundName, sizeof(g_soundName));

	HookConVarChange((hRandom = CreateConVar("sm_ctchicken_model", "models/player/chicken/ct/chicken-ct.mdl", 
	"The path for the CT Chicken Model (.mdl file).")), CtChickenModelChanged);
	GetConVarString(hRandom, g_ctchicken, sizeof(g_ctchicken));

	HookConVarChange((hRandom = CreateConVar("sm_tchicken_model", "models/player/chicken/t/chicken-t.mdl", 
	"The path for the T Chicken Model (.mdl file).")), tChickenModelChanged);
	GetConVarString(hRandom, g_tchicken, sizeof(g_tchicken));
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_health", "200", 
	"Amount of health to give players when they're turned into a chicken.", _, true, 100.0, true, 500.0)), ChickenHealthChanged);
	health = GetConVarInt (hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_allownades", "1", 
	"Allow chickens to use/buy/pickup hegrenades (1/0)?", _, true, 0.0, true, 1.0)), AllowNadesChanged);
	AllowNades = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_gravity", "0.65", 
	"Amount of gravity to apply to players when they're a chicken.", _, true, 0.1, true, 3.0)), PlayerGravityChanged);
	PlayerGravity = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_speed", "1.3", 
	"Amount of speed to apply to players when they're a chicken.", _, true, 0.1, true, 5.0)), PlayerSpeedChanged);
	speed = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_useupdater", "0", 
	"Utilize 'Updater' plugin to auto-update Chicken when updates are published?\n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnUseUpdaterChanged);
	UseUpdater = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = FindConVar("mp_restartgame")), RestartGameTriggered);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_startvote", ".15", 
	"Percentage of players needed to type !votechicken before vote is initialized", _, true, 0.0, true, 1.0)), OnStartVoteChanged);
	VotesNeeded = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_passvote", ".65", 
	"Percentage of players needed to vote yes for the chicken round to pass", _, true, 0.0, true, 1.0)), OnPassVoteChanged);
	VotesRequired = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_votedelay", "300", 
	"Number of seconds to wait before allowing another chicken vote", _, true, 0.0, true, 900.0)), OnVoteDelayChanged);
	fChickenVoteTimer = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_saveweapons", "2", 
	"Save the weapons the player has prior to being turned into a chicken and give back to player?\n0 = No\n1 = Yes\n2 = Yes, only if player doesn't die as chicken", _, true, 0.0, true, 2.0)), OnSaveWeaponsChanged);
	SaveWeapons = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_usemodelcolors", "0",
	"For CSGO only, use specific model colors for chicken model?\n0 = No\n1 = Yes", _, true, 0.0, true, 1.0)), OnUseColorsChanged);
	UseModelColors = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_t_red", "220",
	"Amount of red to use for T model")), OnTRedChanged);
	T_Color[0] = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_t_green", "0",
	"Amount of green to use for T model")), OnTGreenChanged);
	T_Color[1] = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_t_blue", "0",
	"Amount of blue to use for T model")), OnTBlueChanged);
	T_Color[2] = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_t_alpha", "185",
	"Amount of alpha to use for T model")), OnTAlphaChanged);
	T_Color[3] = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_ct_red", "0",
	"Amount of red to use for CT model")), OnCTRedChanged);
	CT_Color[0] = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_ct_green", "0",
	"Amount of green to use for CT model")), OnCTGreenChanged);
	CT_Color[1] = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_ct_blue", "220",
	"Amount of blue to use for CT model")), OnCTBlueChanged);
	CT_Color[2] = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_chicken_ct_alpha", "185",
	"Amount of alpha to use for CT model")), OnCTAlphaChanged);
	CT_Color[3] = GetConVarInt(hRandom);
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	decl String:gdir[PLATFORM_MAX_PATH];
	gdir[0] = '\0';
	
	GetGameFolderName(gdir,sizeof(gdir));
	
	LogMessage("Game Directory is: %s", gdir);
	
	if (StrEqual(gdir, "csgo", false))
	{
		IsCSGO = true;
	}
	else
	{
		IsCSGO = false;
	}
	
	RegAdminCmd("sm_chicken", Command_SetChicken, ADMFLAG_SLAY);
	RegConsoleCmd("sm_votechicken", Command_VoteChicken, "Type !votechicken to try to pass a vote to make the next round a chicken round");
	
	// Load translation files (common.phrases is needed for FindTarget)
	LoadTranslations("common.phrases");
	LoadTranslations("sm_chicken.phrases");
	
	HookEvent("player_spawn",		Event_PlayerSpawn);
	HookEvent("player_death",		Event_PlayerDeath);
	HookEvent("round_end",			Event_RoundEnd);
	HookEvent("round_freeze_end",	Event_RoundFreezeEnd);
	
	// Execute the config file
	AutoExecConfig(true, "plugin.sm_chicken");
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
	if (UseUpdater && StrEqual(name, "updater"))
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
	RunPreCache();
	
	// If CVar to use Updater is true, check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if (UseUpdater && LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
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
	CanVoteChicken = true;
	Voting = false;
}

/**
 * Called right before a map ends.
 */
public OnMapEnd()
{
	ClearTimer(ChickenVoteDelayTimer);
	ClearTimer(CheckChickenVote);
}

/**
 * Callback for Admin Command sm_chicken
 *
 * @param client 		Client index
 * @param args		arguments of the admin command 
 * @noreturn
 */
public Action:Command_SetChicken(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		
		return Plugin_Handled;
	}
	
	if (args != 2)
	{
		CPrintToChat(client, "%s Usage: sm_chicken <target> <1/0>", PLUGIN_PREFIX);
		
		return Plugin_Handled;
	}
	
	decl String:target[MAX_NAME_LENGTH];
	target[0] = '\0';
	decl String:target_name[MAX_NAME_LENGTH];
	target_name[0] = '\0';
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;	

	GetCmdArg(1, target, sizeof(target));

	if ((target_count = ProcessTargetString( 
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		
		return Plugin_Handled;
	}

	decl String:arg2[2];
	arg2[0] = '\0';

	GetCmdArg(2, arg2, sizeof(arg2));
	onoff = StringToInt(arg2);
	
	if (onoff >= 2)
	{
		CPrintToChat(client, "%s Usage: sm_chicken <target> <1/0>", PLUGIN_PREFIX);
		PrintToChat(client, "1=ON, 2=OFF");
		
		return Plugin_Handled;
	}
	
	chicken = (onoff==1?true:false);

	for (new i = 0; i < target_count; i++)
	{
		if (target_list[i] == -1)
		{
			return Plugin_Handled;
		}
		
		ExecChicken(target_list[i]);
	}
	
	return Plugin_Handled;
}

/**
 * Callback for command votechicken
 *
 * @param client 		Client index
 * @param args		arguments of the admin command 
 * @noreturn
 */
public Action:Command_VoteChicken(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		
		return Plugin_Handled;
	}
	
	if (VotesNeeded <= 0)
	{
		CPrintToChat(client, "%s Voting is disabled!", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	if (args > 0)
	{
		CPrintToChat(client, "%s Usage: !votechicken", PLUGIN_PREFIX);
		
		return Plugin_Handled;
	}
	
	if (ChickenRound)
	{
		CPrintToChat(client, "%s %t", PLUGIN_PREFIX, "VoteAlreadyPassed");
		
		return Plugin_Handled;
	}
	
	if (Voted[client])
	{
		CPrintToChat(client, "%s %t", PLUGIN_PREFIX, "AlreadyVoted");
		
		return Plugin_Handled;
	}
	
	if (Voting)
	{
		CPrintToChat(client, "%s A vote is already in progress...", PLUGIN_PREFIX);
		
		return Plugin_Handled;
	}
	
	if (!CanVoteChicken)
	{
		CPrintToChat(client, "%s %t", PLUGIN_PREFIX, "CantVote");
		
		return Plugin_Handled;
	}
	
	Voted[client] = true;
	
	CPrintToChatAll("%t", "PlayerStartedVote", client);
	
	Votes++;
	
	CalculateVotes(1);
	
	return Plugin_Handled;
}

/**
 * Returns the client counts of the first two teams (eg.: Terrorists - Counter).
 * Use this function for optimization if you have to get the counts of both teams,
 * otherwise use Team_GetClientCount().
 *
 * @param team1					Pass an integer variable by reference
 * @param team2					Pass an integer variable by reference
 * @noreturn
 */
GetClientCounts(&team1=0, &team2=0)
{
	for (new client=1; client <= MaxClients; client++)
	{
		if (GetClientTeam(client) <= CS_TEAM_SPECTATOR || IsFakeClient(client))
		{
			continue;
		}
		
		if (GetClientTeam(client) == CS_TEAM_T)
		{
			team1++;
		}
		else if (GetClientTeam(client) == CS_TEAM_CT)
		{
			team2++;
		}
	}
}

public CalculateVotes(any:type)
{
	new TCount, CTCount;
	GetClientCounts(TCount, CTCount);
	
	Voters = TCount + CTCount;	
	
	switch (type)
	{
		case 1:
		{
			if ((float(Votes) / float(Voters)) >= VotesNeeded)
			{
				Votes = 0;
				Voters = 0;
				Voting = true;
				CanVoteChicken = false;
				
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
					{
						Voted[i] = false;
						Menu_ChickenVote(i);
					}
				}
				
				ClearTimer(CheckChickenVote);
				CheckChickenVote = CreateTimer(25.0, Timer_CheckChickenVote);
			}
			else
			{
				// Inform players of vote progress
				new Float:needed;
				needed = Voters * VotesNeeded;
				
				CPrintToChatAll("%t", "Votes Needed", Votes, RoundToCeil(needed - Votes));
			}
		}
		
		case 2:
		{
			if ((float(Votes) / float(Voters)) >= VotesRequired)
			{
				ChickenRound = true;
				
				CPrintToChatAll("%s %t", PLUGIN_PREFIX, "VotePassed");
			}
			else
			{
				ChickenRound = false;
				
				CPrintToChatAll("%s %t", PLUGIN_PREFIX, "VoteNotPassed");
			}
			
			Votes = 0;
			Voters = 0;
			Voting = false;
			CanVoteChicken = false;
			
			ClearTimer(ChickenVoteDelayTimer);
			ChickenVoteDelayTimer = CreateTimer(fChickenVoteTimer, Timer_ChickenVoteDelay);
			
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
				{
					Voted[i] = false;
				}
			}
		}
	}
}

public Action:Timer_ChickenVoteDelay(Handle:timer)
{
	CanVoteChicken = true;
	ChickenVoteDelayTimer = INVALID_HANDLE;
}

public Action:Timer_CheckChickenVote(Handle:timer)
{
	CheckChickenVote = INVALID_HANDLE;
	CalculateVotes(2);
	Voting = false;
}

/**
 * Function to figure out if players should be turned into a chicken or not and to hook the SDKHook_WeaponCanUse or not
 *
 * @param client		Client index
 * @noreturn
 */
public ExecChicken(client)
{
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) < CS_TEAM_T)
	{
		return;
	}
	
	if (chicken == true && !PlayerIsChicken[client])
	{
		DoChicken(client);
		
		return;
	}

	if (chicken == false && PlayerIsChicken[client])
	{
		UndoChicken(client, false, true);
	}
}

/**
 * Function to change player into a chicken model and strip away restricted weapons while a chicken
 *
 *@param client 	Client index
 * @noreturn
 */
public DoChicken(client)
{
	PlayerOldSkin[client][0] = '\0';
	
	GetClientModel(client, PlayerOldSkin[client], sizeof(PlayerOldSkin[]));
	GetClientWeapons(client);

	// Hook the player with WeaponCanUse
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	
	// Mark the player as a chicken
	PlayerIsChicken[client] = true;
	
	// Get the player's team index
	new TeamNum = GetClientTeam(client);
	
	switch (TeamNum)
	{
		case CS_TEAM_T:
		{
			// Set player's model to the Terrorist Chicken model
			SetEntityModel(client, g_tchicken);
			
			if (IsCSGO && UseModelColors)
			{
				SetEntityRenderColor(client, T_Color[0], T_Color[1], T_Color[2], T_Color[3]);
			}
		}
		case CS_TEAM_CT:
		{
			// Set player's model to the CT Chicken model
			SetEntityModel(client, g_ctchicken);
			
			if (IsCSGO && UseModelColors)
			{
				SetEntityRenderColor(client, CT_Color[0], CT_Color[1], CT_Color[2], CT_Color[3]);
			}
		}
	}
	
	SMLIB_RemoveAllWeapons(client);
	
	// Set clients FOV in case they're zoomed in with a scope when turned into a chicken
	SetEntProp( client, Prop_Send, "m_iFOV", 90 );
	SetEntProp( client, Prop_Send, "m_iFOVStart", 90 );
	
	// Set the player's health, gravity, and speed to the defined values in their CVars
	SetEntityHealth(client, health);
	SetEntityGravity(client, PlayerGravity);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed);
	
	CPrintToChat(client,"%s %t", PLUGIN_PREFIX, "Chicken");
	CPrintToChat(client,"%t", "Chicken Health", health);
}

/**
 * Function to change player from being a chicken back to a player and select
 * a random player model if needed.  Also, if death, play the chicken death sound.
 * 
 * @param	client		Client index of player
 * @bool	death		If true, it will play the chicken death sound to the player
 * @bool	spawn	If true, if will set a random player model for the player's team
 * @noreturn
 */
public UndoChicken(any:client, bool:death, bool:spawn)
{
	if (IsClientInGame(client))
	{
		// Mark the player as no longer a chicken
		PlayerIsChicken[client] = false;
		
		// Unhook the player from WeaponCanUse
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		
		// Reset the player's gravity to default (this won't automatically be reset)
		SetEntityGravity(client, 1.0);
		
		if (death)
		{
			if (strcmp(g_soundName, "")) // if g_soundName > null
			{
				// Get the position where the chicken death sound will emit from
				new Float:vec[3];
				GetClientEyePosition(client, vec);
				
				// Emit the chicken death sound
				EmitAmbientSound(g_soundName, vec, client, SNDLEVEL_RAIDSIREN);
				
				if (SaveWeapons == 2)
				{
					ClearClientWeapons(client);
				}
			}
		}
		
		if (spawn)
		{
			// Set the player to have a player model they had prior to turning into a chicken
			SetEntityModel(client, PlayerOldSkin[client]);
			
			// Reset the player's health and speed to default
			SetEntityHealth(client, 100);
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
			
			if (SaveWeapons >= 1)
			{
				GiveClientWeapons(client);
			}
			
			// Notify client they are no longer a chicken
			CPrintToChat(client,"%s %t", PLUGIN_PREFIX, "Not Chicken"); 
		}
	}
}

/**
 * SDKHooks Function SDKHook_WeaponCanUse
 *
 * @param client		Client index
 * @param weapon	weapon index
 * @noreturn
 * @note 			return Plugin_Continue to allow the weapon to be used or Plugin_Handled to not allow it
 */
public Action:OnWeaponCanUse(client, weapon)
{
	// This is here as a safety catch in the event the player is still hooked to WeaponCanUse even if they're not a chicken
	if (!PlayerIsChicken[client])
	{
		// If the player is NOT a chicken, but still hooked to WeaponCanUse, unhook the player and allow them to use the weapon
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		return Plugin_Continue;
	}
	
	decl String:sWeapon[32];
	sWeapon[0] = '\0';
	
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	
	// Allow kinfe and C4
	if (StrEqual(sWeapon, "weapon_knife", false) || StrEqual(sWeapon, "weapon_c4", false))
	{
		return Plugin_Continue;
	}
	
	// Allow hegrenades if permitted
	if (AllowNades && StrEqual(sWeapon, "weapon_hegrenade", false))
	{
		return Plugin_Continue;
	}

	return Plugin_Handled;
}

ClearClientWeapons(client)
{
	PlayerHasDefuser[client] = false;
	PrimarySlot[client][0] = '\0';
	SecondarySlot[client][0] = '\0';
	HEGrenades[client] = 0;
	FlashBangs[client] = 0;
	SmokeGrenades[client] = 0;
	DecoyGrenades[client] = 0;
	INCGrenades[client] = 0;
}

GetClientWeapons(client)
{
	if (GetEntProp(client, Prop_Send, "m_bHasDefuser"))
	{
		PlayerHasDefuser[client] = true;
		SetEntProp(client, Prop_Send, "m_bHasDefuser", 0);
	}
	
	new prim, sec;
	
	PrimarySlot[client][0] = '\0';
	SecondarySlot[client][0] = '\0';
	
	PlayerHasWeapons[client] = true;
	
	prim = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	
	if (prim > MaxClients)
	{
		GetEntityClassname(prim, PrimarySlot[client], sizeof(PrimarySlot[]));
	}
	else
	{
		Format(PrimarySlot[client], sizeof(PrimarySlot), "NONE");
	}
	
	sec = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	
	if (sec > MaxClients)
	{
		GetEntityClassname(sec, SecondarySlot[client], sizeof(SecondarySlot[]));
	}
	else
	{
		Format(SecondarySlot[client], sizeof(SecondarySlot), "NONE");
	}
	
	if (!AllowNades)
	{
		HEGrenades[client] = GetClientHEGrenades(client);
	}
	
	FlashBangs[client] = GetClientFlashbangs(client);
	SmokeGrenades[client] = GetClientSmokeGrenades(client);
	
	if (IsCSGO)
	{
		DecoyGrenades[client] = GetClientDecoyGrenades(client);
		INCGrenades[client] = GetClientIncendaryGrenades(client);
	}
}

GetClientHEGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, HEGrenadeOffset);
}

GetClientSmokeGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, SmokegrenadeOffset);
}

GetClientFlashbangs(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, FlashbangOffset);
}

GetClientDecoyGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, DecoyGrenadeOffset);
}

GetClientIncendaryGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, IncenderyGrenadesOffset);
}

GiveClientWeapons(client)
{
	PlayerHasWeapons[client] = false;
	
	if (PlayerHasDefuser[client])
	{
		PlayerHasDefuser[client] = false;
		SetEntProp(client, Prop_Send, "m_bHasDefuser", 1);
	}
	
	if (!AllowNades && HEGrenades[client] > 0)
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
	
	if (IsCSGO && DecoyGrenades[client] > 0)
	{
		for (new dg = 0; dg < DecoyGrenades[client]; dg++)
		{
			GivePlayerItem(client, "weapon_decoy");
		}
		
		DecoyGrenades[client] = 0;
	}
	
	if (IsCSGO && INCGrenades[client] > 0)
	{
		for (new ig = 0; ig < INCGrenades[client]; ig++)
		{
			if (GetClientTeam(client) == CS_TEAM_CT)
			{
				GivePlayerItem(client, "weapon_incgrenade");
			}
			else
			{
				GivePlayerItem(client, "weapon_molotov");
			}
		}
		
		INCGrenades[client] = 0;
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

/**
 * Called when a player attempts to purchase an item.
 * Return Plugin_Continue to allow the purchase or return a
 * higher action to deny.
 *
 * @param client		Client index
 * @param weapon	User input for weapon name
 */
public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	// Allow all weapon purchases if the player is not currently a chicken
	if (!PlayerIsChicken[client])
	{
		return Plugin_Continue;
	}
	
	// Player is a chicken, so let's make sure to allow them to buy a nade, if permited
	if (StrEqual(weapon, "hegrenade", false) && AllowNades)
	{
		return Plugin_Continue;
	}
	
	// Since player is a chicken and the weapon being purchasd is not a hegrenade (or nades are not permitted), advise player and deny purchase
	if (AdviseOfNoBuy[client])
	{
		AdviseOfNoBuy[client] = false;
		
		if (AllowNades)
		{
			CPrintToChat(client, "%t", "CantBuy");
		}
		else
		{
			CPrintToChat(client, "%t", "CantBuyNades");
		}
		
		CreateTimer(1.0, Timer_AdviseNoBuy, GetClientSerial(client));
	}
	
	return Plugin_Handled;
}

/**
 * Function for timer to advise the player they aren't allowed to purchase weapons while they are a chicken
 * 
 * @param	timer		Handle for timer
 * @param	client		Client index
 * @noreturn
 */
public Action:Timer_AdviseNoBuy(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
	{
		return;
	}
	
	AdviseOfNoBuy[client] = true;
}

/**
 *	"player_death"				// a game event, name may be 32 characters long	
 *	{
 *		// this extents the original player_death by a new fields
 *		"userid"		"short"   	// user ID who died				
 *		"attacker"		"short"	 // user ID who killed
 *		"weapon"		"string" 	// weapon name killer used 
 *		"headshot"		"bool"		// singals a headshot
 *		"dominated"		"short"	// did killer dominate victim with this kill
 *		"revenge"		"short"	// did killer get revenge on victim with this kill
 *	}
 */
public Event_PlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// If player is marked as being a chicken, execute UndoChicken function
	if (PlayerIsChicken[client])
	{
		UndoChicken(client, true, false);
	}
}

/**
 *	"player_spawn"			// player spawned in game
 *	{
 *		"userid"	"short"	// user ID on server
 *	}
 */
public Event_PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	// Retrieve the client index of the player spawning
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// This is here as an extra catch in case the player is spawned and still marked as a chicken
	if (PlayerIsChicken[client])
	{
		UndoChicken(client, false, true);
	}
	
	if (ChickenRound)
	{
		Voted[client] = false;
		DoChicken(client);
	}
	
	if (PlayerHasWeapons[client])
	{
		GiveClientWeapons(client);
	}
}

public Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (ChickenRound)
	{
		// Reset some of the votechicken variables
		ChickenRound = false;
		Votes = 0;
	}
}

/**
 * 	"round_end"
 *	{
 *		"winner"	"byte"		// winner team/user i
 *		"reason"	"byte"		// reson why team won
 *		"message"	"string"	// end round message 
 *	}
 */
public Event_RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	// Go through the alive players and execute UndoChicken if any player is still a chicken
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && PlayerIsChicken[i])
		{
			UndoChicken(i, false, true);
		}
	}
}

/**
 * Function for timer when mp_restartgame is used
 * 
 * @param	timer		Timer handle
 * @noreturn
 */
public Action:Timer_RestartGame(Handle:timer)
{
	RG_Timer = INVALID_HANDLE;
	
	// Go through the alive players and execute UndoChicken if any player is still a chicken
	// This executes 0.5 seconds before the round is restarted when mp_restartround is executed
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && PlayerIsChicken[i])
		{
			UndoChicken(i, false, true);
		}
	}
}

public OnClientConnected(client)
{
	PlayerIsChicken[client] = false;
	
	AdviseOfNoBuy[client] = true;
	
	Voted[client] = false;
}

/**
 * Called when a client is disconnecting from the server.
 *
 * @param client		Client index.
 * @noreturn
 * 
 * @noteYou still need to check IsClientInGame (client) if you want to do the client specific stuff  (exvel)
 */
public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		//ClearTimer(ClientTimer[client]);
		AdviseOfNoBuy[client] = true;
		
		if (Voted[client])
		{
			Voted[client] = false;
			Votes--;
		}
		
		if (PlayerIsChicken[client])
		{
			// Mark the client as not a chicken
			PlayerIsChicken[client] = false;
			
			// Unhook the client from WeaponCanUse
			SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		}
		
		PlayerOldSkin[client][0] = '\0';
		PlayerHasDefuser[client] = false;
		PlayerHasWeapons[client] = false;
	}
}

/**
 * Function for loading the player models and sounds for this plugin
 * It will precache the sounds and model files as well as add them to the downloads table
 * 
 * @noreturn
 */
public RunPreCache()
{
	// Add the files listed in the cfg file to the downloads table
	decl String:buffer[MAX_FILE_LEN];
	buffer[0] = '\0';
	
	if (strcmp(g_soundName, "")) // if g_soundName > null
	{
		Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
		AddFileToDownloadsTable(buffer);
	}
	
	if (strcmp(g_ctchicken, "")) // if g_ctchicken > null
	{
		Format(buffer, sizeof(buffer), "%s", g_ctchicken);
		AddFileToDownloadsTable(buffer);
	}
	
	if (strcmp(g_tchicken, "")) // if g_tchicken > null
	{
		Format(buffer, sizeof(buffer), "%s", g_tchicken);
		AddFileToDownloadsTable(buffer);
	}
	
	// Open the INI file and add everythin in it to download table
	decl String:file[MAX_FILE_LEN];
	file[0] = '\0';
	
	BuildPath(Path_SM, file, sizeof(file), "configs/chicken.ini");
	
	new Handle:fileh = OpenFile(file, "r"); // List of modes - http://www.cplusplus.com/reference/clibrary/cstdio/fopen/
	
	if (fileh == INVALID_HANDLE)
	{
		SetFailState("Chicken.ini file missing!!!");
	}
	
	// Go through each line of the file to add the needed files to the downloads table
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{
		TrimString(buffer);
   		
		if (FileExists(buffer))
		{
			AddFileToDownloadsTable(buffer);
		}
		
		if (IsEndOfFile(fileh))
		{
			break;
		}
	}
	
	if (!PrecacheSound(g_soundName, true))
	{
		LogError("Unsuccessful precaching of the sound %s", g_soundName);
	}
	
	if (!PrecacheModel(g_ctchicken, true))
	{
		LogError("Unsuccessful precaching of the model %s", g_ctchicken);
	}
	
	if (!PrecacheModel(g_tchicken, true))
	{
		LogError("Unsuccessful precaching of the model %s", g_tchicken);
	}
}

public OnVersionChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(newValue, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public ChickenSoundChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(cvar, g_soundName, sizeof(g_soundName));
}

public CtChickenModelChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(cvar, g_ctchicken, sizeof(g_ctchicken));
}

public tChickenModelChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(cvar, g_tchicken, sizeof(g_tchicken));
}
	
public ChickenHealthChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	health = GetConVarInt(cvar);
}
	
public AllowNadesChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AllowNades = GetConVarBool(cvar);
}
	
public PlayerGravityChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	PlayerGravity = GetConVarFloat(cvar);
}

public PlayerSpeedChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	speed = GetConVarFloat(cvar);
}

public OnUseUpdaterChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseUpdater = GetConVarBool(cvar);
}

public OnStartVoteChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	VotesNeeded = GetConVarFloat(cvar);
}

public OnPassVoteChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	VotesRequired = GetConVarFloat(cvar);
}

public OnVoteDelayChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	fChickenVoteTimer = GetConVarFloat(cvar);
}

public RestartGameTriggered(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	restarttime = GetConVarFloat(cvar) - 0.5;
	
	if(chicken && restarttime > 0)
	{
		ClearTimer(RG_Timer);
		RG_Timer = CreateTimer(restarttime, Timer_RestartGame);
	}
}

public OnSaveWeaponsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SaveWeapons = GetConVarInt(cvar);
}

public OnUseColorsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseModelColors = GetConVarBool(cvar);
}

public OnTRedChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	T_Color[0] = GetConVarInt(cvar);
}

public OnTGreenChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	T_Color[1] = GetConVarInt(cvar);
}

public OnTBlueChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	T_Color[2] = GetConVarInt(cvar);
}

public OnTAlphaChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	T_Color[3] = GetConVarInt(cvar);
}

public OnCTRedChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	CT_Color[0] = GetConVarInt(cvar);
}

public OnCTGreenChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	CT_Color[1] = GetConVarInt(cvar);
}

public OnCTBlueChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	CT_Color[2] = GetConVarInt(cvar);
}

public OnCTAlphaChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	CT_Color[3] = GetConVarInt(cvar);
}

/*************************************************************************************************
** The following are from SMLIB  - credit for the remove weapon goes to berni **
**************************************************************************************************/

/**
 * Removes all weapons of a client except knife, c4, and hegrenades
 *
 * @param client 		Client Index.
 * @noreturn		Number of removed weapons.
 */
SMLIB_RemoveAllWeapons(client)
{
	new offset = SMLIB_GetWeaponsOffset(client) -4;
	
	for (new i=0; i < MAX_WEAPONS; i++)
	{
		offset += 4;
		
		new weapon = GetEntDataEnt2(client, offset);
		
		if (!IsValidEntity(weapon))
		{
			continue;
		}
		
		decl String:sWeapon[32];
		sWeapon[0] = '\0';
		
		GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
		
		if (StrEqual(sWeapon, "weapon_knife", false) || StrEqual(sWeapon, "weapon_c4", false))
		{
			if (StrEqual(sWeapon, "weapon_knife", false))
			{
				SMLIB_SetActiveWeapon(client, weapon);
			}
			continue;
		}
		
		if (AllowNades && StrEqual(sWeapon, "weapon_hegrenade", false))
		{
			continue;
		}
			
		AcceptEntityInput(weapon, "kill");
	}
}


/**
 * Changes the active/current weapon of a player by Index.
 * Note: No changing animation will be played !
 *
 * @param client		Client Index.
 * @param weapon		Index of a valid weapon.
 * @noreturn
 */
stock SMLIB_SetActiveWeapon(client, weapon)
{
	SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", weapon);
	ChangeEdictState(client, FindDataMapOffs(client, "m_hActiveWeapon"));
}


/**
 * Gets the offset for a client's weapon list  (m_hMyWeapons).
 * The offset will saved globally for optimization.
 *
 * @param client		Client Index.
 * @return		Weapon list offset or -1 on failure.
 */
stock SMLIB_GetWeaponsOffset(client)
{
	static offset = -1;

	if (offset == -1)
	{
		offset = FindDataMapOffs(client, "m_hMyWeapons");
	}
	
	return offset;
}

// ----------------------------
// MENU STUFF
//-----------------------------
public MenuHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		Voted[param1] = true;
		
		CPrintToChat(param1, "%t", "You Voted", info);
		
		if (param2 == 0)
		{
			Votes++;
		}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
 
public Menu_ChickenVote(client)
{
	new Handle:menu = CreateMenu(MenuHandler1);
	SetMenuTitle(menu, "%t", "Have Chicken Round");
	AddMenuItem(menu, "yes", "Yes");
	AddMenuItem(menu, "no", "No");
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 20);
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