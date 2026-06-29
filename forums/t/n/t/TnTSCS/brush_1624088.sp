/* B-Rush
* LINE 1238!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
* 	DESCRIPTION
* 		A great plugin where there are 5 Terrorists vs 3 CTs.  The Ts must only plant at the "B" bomb site.
* 		Server admins can configure if players are allowed to buy/use FlashBangs, Smoke Grenades, HE Grenades,
* 		or AWPS.  The number of AWPS allowed is configurable as well.
* 
* 		If the CTs kill all of the Ts, the game continues to the next round, no modifications.
* 
* 		If the Ts kill all of the CTs (or they somehow successfully bomb the B site), then the CTs become Ts
* 		and those Ts that killed a CT will be switched to the CT team.  If only 1 or 2 Ts killed a CT, then one
* 		randomly selected T will become the 2nd and/or 3rd CT.
* 
* 		This is a fast paced game that is quickly gaining interest.  There are other private BRUSH mods, but
* 		this is the first public SourceMod plugin that I'm aware of.
* 
* 	VERSIONS and ChangeLog
* 
* 		0.0.1.0	*	Initial Beta Release
* 
* 		0.0.1.1	*	Fixed mistake in CVar description for sm_brush_smokes
* 				+	Added menu option for T who killed 2+ CTs to pick their teammates.  If they don't pick
* 					them in time, the plugin randomly selects the player(s)
* 				+	Added translations file (need other languages)
* 				+	I added team scrambling for when CTs win 8+ rounds in a row
* 
* 		0.0.1.2	*	Fixed bug where player wouldn't respawn if they didn't use auto team select and tried to join a 
* 					team that was already full.
* 					-	This was caused by using CS_SwitchTeam - now using ChangeClientTeam
* 				*	Increased the delay at the end of round when swapping players to new team.
* 
* 		0.0.1.3	*	Fixed bug where a T with a bomb who was switched to CT retained the C4.
* 
* 			* NOTE	I may not finish the nade limiter - since Valve has that built in, you can just use the 
* 					ammo_<nadetype>_max and set it yourself
* 
* 		0.0.1.4	*	Now using a different, somewhat faster method for end of round team changes.
* 
* 		0.0.1.5	+	Added CVar for enabling/disabling the plugin - by request
* 				+	Added automatic bot handling - by request
* 				+	Added functionality for if the Terrorists successfully bomb the B site, the bomber will
* 					be moved to the CT team and if no CTs were killed by Ts, then the player menu will
* 					be shown to the bomber to pick their team.
* 				*	Enhanced the score keeping
* 				+	Added the Slovak translation file to Updater
* 		0.0.1.6	*	Fixed bug introduced in 0.0.1.5 where CT would spawn in Ts spawn area
* 				+	Added live/not-live config file ability with a CVar that controls whether or not to use them
* 				+	Added individual team freeze timers that can be controlled via CVars
* 		0.0.1.7	*	Fixed bad SK translation file
* 
* 		0.0.1.8	*	Hopefully fixed the error - Property ''m_hOwner'' not found
* 
* 		0.0.1.9	*	Fixed bug where round would start with dead players sometimes.
* 				+	Added CVar for round end handling - use god mode, teleport players back to spawn, or do nothing.
* 				+	Added code to remove "PlayerX has joined the X team" message.
* 				*	Fixed bug where player could buy and awp and drop it to get around the sniper limit
* 				+	Added random model assignment for CS_SwitchTeam
* 
* 		0.0.2.0	*	Fixed Invalid_Entity error if C4 gets stripped by another plugin.
* 
* 		0.0.2.1	-	Removed 2 unneeded translation files.
* 				-	Removed 2 unneeded defines
* 
* 		0.0.2.2	*	Fixed bug where player could join a team even if 8 players were already occupying all of the slots
* 				+	Added ability to change the bomb site to rush and plant (by request) - new CVar sm_brush_bombsite A or B
* 					-	Added message to player who gets bomb to let them know what site to plant at.
* 
* 		0.0.2.3	*	Fixed code according to RedSwords comments
* 
* 
* 	TO DO List
* 		Add translation file
* 			-	This is a biggie since a lot of swedish players like this game play
* 			+	DONE v0.0.1.1
* 
* 		Add a waiting list for those in spectate with a place holder system
* 			-	If someone leaves the game, take the next spectater in the list and put them in the game.
* 				*	If they end up not moving when they die or the round ends, put them back in spectate 
* 					and bring the next spectator in line to the game
* 			-	Or if someone leaves the game, put a menu up to those in spectate asking if they want to join
* 
* 		Fix the team scrambler for if the CTs are just dominating the Ts
* 			-	Maybe scramble the teams after the CTs win 8 times in a row?  Maybe 10 times in a row
* 			-	Move all three CTs or just the lowest scoring, or two lowest scoring?
* 			+	DONE v0.0.1.1
* 				-	It just scrambles the team right now... moves everyone to the T team and then randomly
* 					picks 3 to go CT
* 
* 		Add different game types for when only 1 or 2 Ts kill the CTs
* 			-	One way would be to display a menu to the player who killed 2 or 3 CTs and allow that player 
* 				to select the T he wants to be on the CT team with him
* 			-	Another way would be to allow the highest scoring CT (or CTs) to remain on the CT team
* 			*	May not implement this
* 
* 		Add functionality to allow server admins to determine how many of each grenade players are allowed to buy/carry
* 			-	I have this in my GrenadePack2 plugin, just need to put it in this one
* 			*	May not implement this
* 
* 		Try to optimize this plugin by using less for(new... cycling through all of the players
* 
* 	KNOWN ISSUES
* 		None that I could find during my testing
* 
* 	REQUESTS
* 		Suggest something
* 
* 
*/
#pragma semicolon 1

// ===================================================================================================================================
// Includes
// ===================================================================================================================================
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colors>
#include <smlib\clients>
#undef REQUIRE_PLUGIN
#include <updater>

// ===================================================================================================================================
// Defines
// ===================================================================================================================================
#define 	PLUGIN_VERSION 		"0.0.2.3"
#define 	UPDATE_URL 			"http://dl.dropbox.com/u/3266762/brush.txt"
#define 	SOUND_FILE 			"buttons/weapon_cant_buy.wav" // cstrike\sound\buttons

// ===================================================================================================================================
// Client Variables
// ===================================================================================================================================
new CTKiller = 0; // Holds the UserID of the T who killed 2+ CTs

new PlayerKilledCT[MAXPLAYERS+1] = 0; // Holds the number of CTs the T killed
new CTImmune[MAXPLAYERS+1] = false; // Marks the player as Change Team Immune
new SwitchingPlayer[MAXPLAYERS+1] = false; // Flags the player as being switched by the plugin
new bool:PlayerSwitchable[MAXPLAYERS+1] = false; // Flags the player as switchable

new Handle:ClientTimer[MAXPLAYERS+1] = INVALID_HANDLE; // Client timer for various things
new Handle:p_FreezeTime[MAXPLAYERS+1] = INVALID_HANDLE; // Handle for client timer used for extra freeze time

// ===================================================================================================================================
// CVar Variables
// ===================================================================================================================================
new bool:UseUpdater = false; // Should this plugin be updated by Updater
new bool:UseWeaponRestrict = true; // Should this plugin enforce weapon restrictions
new bool:AllowHEGrenades = false; // Bool for allowing HEGrenades or not
new bool:AllowFlashBangs = false; // Bool for allowing FlashBangs or not
new bool:AllowSmokes = false; // Bool for allowing Smoke Grenades or not
new bool:GameIsLive = false; // Bool for the plugin to know if the game is live (5Ts and 3CTs)
new bool:Enabled = true; // Bool for the plugin to know if the plugin is enabled or not
new bool:ManageBots = true; // Bool to let the plugin know if it should manage bots by reducing the bot_quota if a human joins
new bool:FillBots = false; // Bool to let the plugin know if it should maintain 8 players and add bots if needed
new bool:UseConfigs; // Bool to let the plugin know if it should execute live/notlive config files
new Float:CTFreezeTime; // Time for extra time the CTs should remain frozen after mp_freezetime has expired
new Float:TFreezeTime;// Time for extra time the Terrorists should remain frozen after mp_freezetime has expired

new Handle:LiveTimer = INVALID_HANDLE; // Timer handle for checking when the conditions match to go live
new Handle:brush_botquota; // Handle for cvar bot_quota so we can change the amount later

new bool:CTAwps = false; // Bool to allow CTs to purchase AWPs/Autos
new CTAwpNumber; // Number of AWPs/Autos to allow the CTs to buy
new bool:TAwps = false; // Bool to allow the Ts to purchase AWPs/Autos
new TAwpNumber; // Number o fAWPs/Autos to allow the Ts to buy

new FreezeTime; // Amount of time in mp_freezetime
new MenuTime; // Calculated time to show the menu to the player who killed 2+ CTs before the menu goes away and a random teammate is chosen
new CTScore = 0; // Holder for CT Score
new TScore = 0; // Holder for T Score
new killers = 0; // Holder for the number of Ts that killed CTs
new g_BombsiteB = -1; // Holder for Bomb site B entity index
new g_BombsiteA = -1; // Holder for Bomb site A entity index
new numSwitched = 0; // Holds the number of Ts that are switched to CT - used for randomswitch and menu building
new bot_quota; // Holds the game's bot_quota
new the_bomb = INVALID_ENT_REFERENCE; // Holds the entity index of the bomb
new roundend_mode; // Holds the round end mode setting

new tawpno = 0; // Holds the number of AWPs/AUTOs the Terrorists have
new ctawpno = 0; // Holds the number of AWPs/AUTOs the CTs have

new bool:IsPlayerFrozen[MAXPLAYERS+1] = {false, ...};

new String:s_bombsite[] = "B";

// T and CT models to use for random model assignment
static const String:ctmodels[4][] = 
	{
		"models/player/ct_urban.mdl",
		"models/player/ct_gsg9.mdl",
		"models/player/ct_sas.mdl",
		"models/player/ct_gign.mdl"
	};
	
static const String:tmodels[4][] = 
	{
		"models/player/t_phoenix.mdl",
		"models/player/t_leet.mdl",
		"models/player/t_arctic.mdl",
		"models/player/t_guerilla.mdl"
	};

public Plugin:myinfo = 
{
	name = "CSS BRush",
	author = "TnTSCS aka ClarkKent",
	description = "B Rush bomb site only - 5T vs 3CT",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	// Create this plugins CVars
	new Handle:hRandom; // KyleS HATES handles
	
	HookConVarChange((hRandom = CreateConVar("sm_brush_version", PLUGIN_VERSION, 
	"Version of 'CSS BRush'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_brush_useupdater", "0", 
	"Utilize 'Updater' plugin to auto-update CSS BRush when updates are published?\n1=yes\n0=no", FCVAR_NONE, true, 0.0, true, 1.0)), OnUseUpdaterChanged);
	UseUpdater = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_brush_useweaprestrict", "1", 
	"Use this plugin's weapon restrict features?\n1=yes\n0=no - if you are going to use a different weapon restrict plugin", FCVAR_NONE, true, 0.0, true, 1.0)), OnUseWeaponRestrictChanged);
	UseWeaponRestrict = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_brush_hegrenades", "1", 
	"Allow players to buy/use HEGrenades?\n1=yes\n0=no", FCVAR_NONE, true, 0.0, true, 1.0)), OnHEGrenadesChanged);
	AllowHEGrenades = GetConVarBool(hRandom);

	HookConVarChange((hRandom = CreateConVar("sm_brush_flashbangs", "0", 
	"Allow players to buy/use FlashBangs?\n1=yes\n0=no", FCVAR_NONE, true, 0.0, true, 1.0)), OnFlashBangsChanged);
	AllowFlashBangs = GetConVarBool(hRandom);

	HookConVarChange((hRandom = CreateConVar("sm_brush_smokes", "0", 
	"Allow players to buy/use Smoke Grenades?\n1=yes\n0=no", FCVAR_NONE, true, 0.0, true, 1.0)), OnSmokesChanged);
	AllowSmokes = GetConVarBool(hRandom);

	HookConVarChange((hRandom = CreateConVar("sm_brush_ctawps", "1", 
	"Allow CTs to buy/use AWPs/Autos?\n1=yes\n0=no", FCVAR_NONE, true, 0.0, true, 1.0)), OnCTAwpsChanged);
	CTAwps = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_brush_ctawpnumber", "1", 
	"If CTs are allowed to buy/use AWPs/Autos, how many should they be limited to?", FCVAR_NONE, true, 1.0, true, 3.0)), OnCTAwpNumberChanged);
	CTAwpNumber = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_brush_tawps", "0", 
	"Allow Ts to buy/use AWPs/Autos?\n1=yes\n0=no", FCVAR_NONE, true, 0.0, true, 1.0)), OnTAwpsChanged);
	TAwps = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_brush_tawpnumber", "1", 
	"If Ts are allowed to buy/use AWPs/Autos, how many should they be limited to?", FCVAR_NONE, true, 1.0, true, 5.0)), OnTAwpNumberChanged);
	TAwpNumber = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = FindConVar("mp_freezetime")), OnFreezeTimeChanged);
	FreezeTime = GetConVarInt(hRandom);
	MenuTime = (3 + FreezeTime) / 2;
	
	HookConVarChange((hRandom = CreateConVar("sm_brush_enabled", "1", 
	"Is this plugin enabled?", FCVAR_NONE, true, 0.0, true, 1.0)), OnEnabledChanged);
	Enabled = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_brush_managebots", "1", 
	"Allow BRush to remove bots, if present, when human players join?", FCVAR_NONE, true, 0.0, true, 1.0)), OnManageBotsChanged);
	ManageBots = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_brush_fillbots", "0", 
	"Allow BRush to maintain 8 players at all times by adding/removing bots?", FCVAR_NONE, true, 0.0, true, 1.0)), OnFillBotsChanged);
	FillBots = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_brush_usecfgs", "0", 
	"Should BRush execute the brush.live.cfg and brush.notlive.cfg configs (located in cstrike/cfg)?", FCVAR_NONE, true, 0.0, true, 1.0)), OnUseConfigsChanged);
	UseConfigs = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_brush_ctfreeze", "2.0", 
	"How long should the CTs remain frozen after mp_freezetime has expired?", FCVAR_NONE, true, 0.0, true, 25.0)), OnCTFreezeTimeChanged);
	CTFreezeTime = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_brush_tfreeze", "4.0", 
	"How long should the Terrorists remain frozen after mp_freezetime has expired?", FCVAR_NONE, true, 0.0, true, 25.0)), OnTFreezeTimeChanged);
	TFreezeTime = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_brush_endmode", "1", 
	"What should happen to players when the round ends and the Terrorists are the winners?\n0 = Nothing\n1 = Teleport alive players back to their spawn\n2 = Give alive players god mode", FCVAR_NONE, true, 0.0, true, 2.0)), OnRoundEndModeChanged);
	roundend_mode = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_brush_bombsite", "B", 
	"What bomb site should be used?", FCVAR_NONE)), OnBombsiteChanged);
	GetConVarString(hRandom, s_bombsite, sizeof(s_bombsite));
	
	HookConVarChange((brush_botquota = FindConVar("bot_quota")), OnBotQuotaChanged);
	bot_quota = GetConVarInt(brush_botquota);
	
	//LoadTranslations("common.phrases");
	//LoadTranslations("playercommands.phrases");
	
	LoadTranslations("brush.phrases");
	
	HookEvent("bomb_beginplant", Event_BeginBombPlant);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("bomb_exploded", Event_BombExploded, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("bomb_pickup", Event_BombPickup);
	
	AddCommandListener(Command_JoinTeam, "jointeam");
	
	// Execute the config file
	AutoExecConfig(true, "plugin.brush");
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
	if(UseUpdater && StrEqual(name, "updater"))
	{
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
	// Check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if(UseUpdater && LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	// For the restriction sound that plays to the player
	PrecacheSound(SOUND_FILE, true);
}

/**
 * Called once a client successfully connects.  This callback is paired with OnClientDisconnect.
 *
 * @param client		Client index.
 * @noreturn
 */
public OnClientConnected(client)
{
	if(!Enabled)
	{
		return;
	}
	
	if(GetClientCount(true) < 3)
	{
		// Find out the entity's of the bomb sites
		GetBomsitesIndexes();
	}
	
	// Reset all of the player variables
	CTImmune[client] = false;
	PlayerSwitchable[client] = false;
	PlayerKilledCT[client] = 0;
	SwitchingPlayer[client] = false;
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
	if(!Enabled || IsFakeClient(client))
	{
		return;
	}
	
	if(ManageBots)
	{
		new humans = Client_GetCount(true, false);
		if(humans + bot_quota >= 8)
		{
			// Reduce the bot_quota by 1 to make room for the human player to join
			bot_quota--;
			
			SetConVarInt(brush_botquota, bot_quota);
		}
	}
	
	if(IsClientInGame(client))
	{
		PrintToConsole(client, "\n\n******************************");
		PrintToConsole(client, "[CSS BRush] v%s by TnTSCS", PLUGIN_VERSION);
		PrintToConsole(client, "******************************\n");
	}
}

// ===================================================================================================================================
// The following two JoinTeam's will ensure that players cannot join a team if that team already has the maximum number of players allowed (5T, 3CT)
// If teams are 4T and 3CT and a player tries to join the CT team, they will automatically be placed on the Terrorist's team.  See Timer_ChangeToSpec
// for details on that
// ===================================================================================================================================
public Action:Command_JoinTeam(client, const String:command[], argc)
{
	if(!client || !IsClientInGame(client) || SwitchingPlayer[client])
	{
		return Plugin_Continue;
	}
	
	// Figure out what team they player is trying to join
	decl String:TeamNum[2];
	TeamNum[0] = '\0';
	
	GetCmdArg(1, TeamNum, sizeof(TeamNum));
	
	new team = StringToInt(TeamNum);
	
	new tCount, ctCount;
	
	Team_GetClientCounts(tCount, ctCount);
	
	// If the team the player is trying to join is full, let them know it's full, and process further, see Timer_ChangeToSpec for details.
	if((team == CS_TEAM_T && tCount >= 5) || (team == CS_TEAM_CT && ctCount >= 3))
	{
		SwitchPlayerTeam(client, CS_TEAM_SPECTATOR);
		
		CPrintToChat(client, "%t", "CantJoin");
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public SwitchPlayerTeam(client, team)
{
	SwitchingPlayer[client] = true;
	
	if(team > CS_TEAM_SPECTATOR)
	{
		CS_SwitchTeam(client, team);
		set_random_model(client, team);
	}
	else
	{
		ChangeClientTeam(client, team);
	}
	
	SwitchingPlayer[client] = false;
}

/**
 * 	"player_team"				// player change his team
 *	{
 *		"userid"		"short"	// user ID on server
 *		"team"		"byte"		// team id
 *		"oldteam" 		"byte"		// old team id
 *		"disconnect" 	"bool"		// team change because player disconnects
 *		"autoteam" 		"bool"		// true if the player was auto assigned to the team
 *		"silent" 		"bool"		// if true wont print the team join messages
 *		"name"		"string"	// player's name
 *	
 */
public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetEventBroadcast(event, true);
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client == 0 || !IsClientInGame(client) || SwitchingPlayer[client])
	{
		return Plugin_Continue;
	}
	
	// Figure out what team they player is trying to join
	new team = GetEventInt(event, "team");
	
	new tCount;
	new ctCount;
	
	Team_GetClientCounts(tCount, ctCount);
	
	// If the team the player is trying to join is full, let them know it's full, and process further, see Timer_ChangeToSpec for details.
	if((team == CS_TEAM_T && tCount >= 5) || (team == CS_TEAM_CT && ctCount >= 3))
	{
		CPrintToChat(client, "%t", "CantJoin");
		
		ClientTimer[client] = CreateTimer(0.1, Timer_HandleTeamSwitch, client);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/**
 * Timer to handle player team joinings
 * 
 * @param	timer		Handle for timer
 * @param	client		client index
 * @noreturn
 */
public Action:Timer_HandleTeamSwitch(Handle:timer, any:client)
{
	ClientTimer[client] = INVALID_HANDLE;
	
	if(GetTeamClientCount(CS_TEAM_CT) < 3)
	{
		SwitchPlayerTeam(client, CS_TEAM_CT);
		CPrintToChat(client, "%t", "OnCT");			
		return Plugin_Handled;
	}
	
	if(GetTeamClientCount(CS_TEAM_T) < 5)
	{
		SwitchPlayerTeam(client, CS_TEAM_T);
		CPrintToChat(client, "%t", "OnT");
		return Plugin_Handled;
	}
	
	SwitchPlayerTeam(client, CS_TEAM_SPECTATOR);
	CPrintToChat(client, "%t", "OnSpectate");
	
	return Plugin_Continue;
}

/**
 * 	"player_spawn"				// player spawned in game
 *	{
 *		"userid"	"short"		// user ID on server
 *	}
 */
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Reset player variables
	if(Enabled)
	{
		CTImmune[client] = false;
		PlayerSwitchable[client] = false;
		PlayerKilledCT[client] = 0;
		SwitchingPlayer[client] = false;
		
		if(IsPlayerFrozen[client])
		{
			ClearTimer(p_FreezeTime[client]);
			
			UnFreezePlayer(client);
		}
		
		new team = GetClientTeam(client);
		
		decl String:WeaponName[MAX_WEAPON_STRING];
		WeaponName[0] = '\0';
		
		new wEnt = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		
		if(wEnt != INVALID_ENT_REFERENCE && wEnt > MaxClients)
		{
			GetEntityClassname(wEnt, WeaponName, sizeof(WeaponName));
			
			if(StrContains(WeaponName, "awp", false) != -1 || StrContains(WeaponName, "g3sg1", false) != -1 || StrContains(WeaponName, "sg550", false) != -1)
			{
				switch(team)
				{
					case CS_TEAM_CT:
					{
						ctawpno++;
					}
					
					case CS_TEAM_T:
					{
						tawpno++;
					}
				}
			}
		}
	}
}

/**
 * When the mp_freezetime expires
 */
public Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// ===================================================================================================================================
	// Make sure conditions are appropriate for BRUSH round - 5 players on Terrorist's team and 3 players on CT's team
	// ===================================================================================================================================
	if(GetTeamClientCount(CS_TEAM_T) == 5 && GetTeamClientCount(CS_TEAM_CT) == 3)
	{
		GameIsLive = true;
		
		// Let the players know this round is LIVE
		CPrintToChatAll("%t %t", "Prefix", "LiveRound");
		PrintCenterTextAll("%t", "LiveRound");
		
		// Apply extra feeze time and advise player if their team is being frozen for an extra amount of time beyond the mp_freezetime
		new player_team;
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				player_team = GetClientTeam(i);
				
				switch(player_team)
				{
					case CS_TEAM_T:
					{
						if(TFreezeTime != 0.0)
						{
							FreezePlayer(i);
							p_FreezeTime[i] = CreateTimer(TFreezeTime, Timer_UnFreezePlayer, i);
							
							CPrintToChat(i, "%t", "Frozen", TFreezeTime);
						}
					}
					
					case CS_TEAM_CT:
					{
						if(CTFreezeTime != 0.0)
						{
							FreezePlayer(i);				
							p_FreezeTime[i] = CreateTimer(CTFreezeTime, Timer_UnFreezePlayer, i);
							
							CPrintToChat(i, "%t", "Frozen", CTFreezeTime);
						}
					}
				}
			}
		}
	}
	else
	{
		if(GameIsLive && UseConfigs)
		{
			ServerCommand("exec brush.notlive.cfg"); // Since the game had been live, but is now not live, execute the notlive config
		}
		
		GameIsLive = false;
		
		// Let the players know this round is not live
		CPrintToChatAll("%t %t", "Prefix", "NotLiveRound");
		
		// Start a repeating timer (if one isn't already running) to constantly check for BRUSH live round conditions
		if(LiveTimer == INVALID_HANDLE)
		{
			LiveTimer = CreateTimer(3.0, CheckLive, _, TIMER_REPEAT);
		}
	}
	
	CTKiller = 0; // Set this holder to zero so we'll know later on if there is a CTKiller
	
	numSwitched = 0; // Set this to 0 so we can accuratly keep track of how many Terrorists are switched
	
	killers = 0; // Set this to 0 so we can accuratly count how many Terrorist kill CTs
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
	// Get the entity index of the bomb so we can later on have the owner of the bomb drop it, if necessary
	if(StrEqual(classname, "weapon_c4"))
	{
		the_bomb = entity;
	}
	
	// If the bomb is planted, set the bomb entity index to -1 so we can bypass the bomb dropping function
	if(StrEqual(classname, "planted_c4"))
	{
		the_bomb = INVALID_ENT_REFERENCE;
	}
}

/**
 * Function for timer when BRush's conditions make it go not live.  Will run until conditions to go live are met or the plugin is disabled
 * 
 * @param	timer		Handle for timer
 * @noreturn
 */
public Action:CheckLive(Handle:timer)
{
	// ===================================================================================================================================
	// Repeating timer to check for team conditions.  Once there are 5 players on Terrorist's team and 3 players on CT's team, the round will go live
	// ===================================================================================================================================
	if(GetTeamClientCount(CS_TEAM_T) == 5 && GetTeamClientCount(CS_TEAM_CT) == 3)
	{
		LiveTimer = INVALID_HANDLE; // Always need to set back to INVALID_HANDLE when the timer has served its purpose
		
		GameIsLive = true; // So Event_RoundFreezeEnd knows it's live
		
		if(UseConfigs)
		{
			ServerCommand("exec brush.live.cfg"); // Since the game is now live, execute the live config file.
		}
		
		new times = 0;
		while(times < 3) // Repeat the announcement 3 times
		{
			CPrintToChatAll("%t", "RoundGoingLive");
			times++;
		}
		
		ServerCommand("mp_restartgame 3"); // Restart the game since now the conditions meet a live match
		
		CTScore = 0; // Reset the score for CTs
		TScore = 0; // Reset the score for Terrorists
		
		return Plugin_Stop; // Stop this repeating timer.
	}
	
	// Conditions haven't been met to live the round for BRUSH, let any spectators know they are needed
	for(new i = 1; i <= MaxClients; i++)
	{		
		if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_SPECTATOR)
		{
			Client_PrintKeyHintText(i, "%t\n\n%t", "Prefix2", "SpecAdvert");
		}
	}
	
	return Plugin_Continue;
}

/**
 * 	"bomb_abortplant"
 *	{
 *		"userid"	"short"		// player who is planting the bomb
 *	}
 * 
 */
public Event_BombPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!client || IsFakeClient(client))
	{
		return;
	}
	
	if(StrEqual(s_bombsite, "A", false))
	{
		CPrintToChat(client, "%t", "PlantA");
		return;
	}
	
	if(StrEqual(s_bombsite, "B", false))
	{
		CPrintToChat(client, "%t", "PlantB");
		return;
	}
	
	LogMessage("ERROR WITH BOMB SITE CVAR - it's not set to A or B!!");
}

/**
 * 	"bomb_abortplant"
 *	{
 *		"userid"	"short"		// player who is planting the bomb
 *		"site"		"short"		// bombsite index
 *	}
 * 
 */
public Event_BeginBombPlant(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GameIsLive)
	{
		return;
	}
	
	// ===================================================================================================================================
	// Make sure player's only plant at B bomb site (I'm working on blocking the paths to the other site(s)
	// ===================================================================================================================================	
	new bombsite = GetEventInt(event, "site");
	
	if((StrEqual(s_bombsite, "B", false) && bombsite == g_BombsiteB) || (StrEqual(s_bombsite, "A", false) && bombsite == g_BombsiteA))
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(StrEqual(s_bombsite, "B", false) && bombsite != g_BombsiteB)
	{
		CPrintToChat(client, "%t %t", "Prefix", "PlantB");
		//AcceptEntityInput(g_BombsiteA, "Disable");
	}
	
	if(StrEqual(s_bombsite, "A", false) && bombsite != g_BombsiteA)
	{
		CPrintToChat(client, "%t %t", "Prefix", "PlantA");
		//AcceptEntityInput(g_BombsiteB, "Disable");
	}
	
	EmitSoundToClient(client, SOUND_FILE);
	
	new c4ent = GetPlayerWeaponSlot(client, CS_SLOT_C4);
	
	if(c4ent != INVALID_ENT_REFERENCE)
	{
		CS_DropWeapon(client, c4ent, true);
	}
}

/**
 * 	"player_death"				// a game event, name may be 32 characters long
 *	{
 *		// this extents the original player_death by a new fields
 *		"userid"	"short"   		// user ID who died				
 *		"attacker"	"short"	 	// user ID who killed
 *		"weapon"	"string" 		// weapon name killer used 
 *		"headshot"	"bool"			// singals a headshot
 *		"dominated"	"short"		// did killer dominate victim with this kill
 *		"revenge"	"short"		// did killer get revenge on victim with this kill
 *	}
 * 
 */
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GameIsLive)
	{
		return;
	}
	
	// ===================================================================================================================================
	// Figure out who killed who.  If a T killed a CT, mark that T as switchable just in case Ts win the round.
	// ===================================================================================================================================
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(attacker > 0 && attacker <= MaxClients) // Make sure attacker is a player
	{
		new ateam = GetClientTeam(attacker); // Get attacker's team
		
		new victim = GetClientOfUserId(GetEventInt(event, "userid")); // Get the victim's client index
		new vteam = GetClientTeam(victim); // Get the victim's team
		
		// If attacker is a Terrorist and it's not a self or team kill
		if(ateam == CS_TEAM_T && ateam != vteam && attacker != victim)
		{
			PlayerKilledCT[attacker]++; // Mark player as having killed a CT
			
			PlayerSwitchable[victim] = true; // Mark this player as switchable in case the Ts win the round.
			
			CPrintToChat(victim, "%t", "CTKilled", attacker); // Let the CT know they might get switched.
			
			// This terrorist's first kill, perform first kill tasks
			if(PlayerKilledCT[attacker] == 1) 
			{
				// Notify the player they killed a CT and they will be switched if Ts win
				CPrintToChat(attacker, "%t", "KilledCT", victim);
				
				killers++; // Number of Terrorists who killed the CTs holder
				
				// Mark this player as switchable in case Ts win the round.
				PlayerSwitchable[attacker] = true;
				
				// Mark this terrorist as ChangeTeam immune for handling later
				CTImmune[attacker] = true;
			}
			else if(PlayerKilledCT[attacker] >= 2) // This terrorist's 2nd/3rd kill
			{
				CTKiller = GetClientUserId(attacker); // Mark userId as the player who killed more than one CT
			}
		}
	}
}

/**
 * 	"bomb_exploded"
 *	{
 *		"userid"	"short"		// player who planted the bomb
 *		"site"		"short"		// bombsite index
 *	}
 */
public Event_BombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Let's make sure the bomber gets credit for this event and gets switched over to CT if the Terrorists win
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if(client != 0)
	{
		PlayerKilledCT[client]++;
		
		if(PlayerKilledCT[client] == 1) 
		{
			killers++;
			
			PlayerSwitchable[client] = true;
			
			CTImmune[client] = true;
			
			if(killers == 1)
			{
				CTKiller = userid;
			}
		}
		else if(PlayerKilledCT[client] >= 2) // This player is a CT killer
		{
			CTKiller = userid;
		}
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
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.6, Timer_SetScore); // See function for details
	
	if(!GameIsLive)
	{
		return;
	}
	
	// ===================================================================================================================================
	// Figure out what team won and handle appropriately with announcements and team swapping if needed
	// ===================================================================================================================================
	new winner = GetEventInt(event, "winner");
	
	if(winner == CS_TEAM_T)
	{
		TScore++; // Increase the Terrorist's score by 1
		
		CreateTimer(0.5, ProcessTeam); // See function for details
	}
	else
	{
		CTScore++; // Increase the CT's score by 1
		
		CPrintToChatAll("%t", "CTWon");
		
		if(CTScore >= 2)
		{
			CreateTimer(0.3, Announcement); // See function for details
		}
	}
	
	tawpno = 0;
	ctawpno = 0;
}

/**
 * Function for timer that sets the scores
 * 
 * @param	timer		Handle of timer
 * @noreturn
 */
public Action:Timer_SetScore(Handle:timer)
{
	if(GameIsLive)
	{
		// Set the team scores
		SetTeamScore(CS_TEAM_CT, CTScore);
		SetTeamScore(CS_TEAM_T, TScore);
	}
	else
	{
		// Set the team scores to something fun - TOO LEET :)
		SetTeamScore(CS_TEAM_CT, 700);
		SetTeamScore(CS_TEAM_T, 1337);
	}
}

/**
 * Function for timer that Announces repeat CT wins and T taunts
 * 
 * @param	timer		Handle of timer
 * @noreturn
 */
public Action:Announcement(Handle:timer)
{
	// ===================================================================================================================================
	// Just fun taunting messages to the Terrorists if they keep loosing to the 3 CTs
	// ===================================================================================================================================
	CPrintToChatAll("%t", "CTWonAgain", CTScore);
	
	switch(CTScore)
	{
		case 3:	{CPrintToChatAll("%t", "TTaunt3");}
		
		case 4:	{CPrintToChatAll("%t", "TTaunt4");}
		
		case 5:	{CPrintToChatAll("%t", "TTaunt5");}
		
		case 6:	{CPrintToChatAll("%t", "TTaunt6");}
		
		case 7:	{CPrintToChatAll("%t", "TTaunt7");}
		
		case 8, 9, 10, 11, 12, 13, 14, 15:
		{
			// Switch up teams, and if CTs keep winning, keep switching up the teams
			CPrintToChatAll("%t", "Scrambling");
			ScrambleTeams();
		}
	}
}

/**
 * Function for timer Processes the teams when Terrorists win
 * 
 * @param	timer		Handle of timer
 * @noreturn
 */
public Action:ProcessTeam(Handle:timer)
{	
	// ===================================================================================================================================
	// ALL CTs get switched to the Terrorist's team.
	//
	// The Terrorists who killed 1 or more CTs get switched to CT team.
	//
	// If less than 3 Terrorists killed a CT, 1 or 2 randomly selected Terrorists will be switched to CT team (I may add a different method for
	// switching Terrorists to the CT team and have a CVar to define which method to use).  
	// One way would be to present a menu to the Terrorist who killed 2 or more CTs and have that player select the player to swap (this could run
	// into time issues).  Another method would be to select the CT(s) with the highest score(s) to remain on the CT team.
	// ===================================================================================================================================
	// Move the Terrorists who killed a CT to the CT team, if less than three Ts killed a CT, randomly select 1 or 2 
	// Terrorists to switch to the CT team or display the team picking menu to the CT killer.
	// Also, move the CTs to the Terrorist team since they just lost.
	// ===================================================================================================================================
	
	// Let's drop the bomb prior to player team movement so a CT doesn't end up with the bomb
	if(the_bomb > MaxClients && IsValidEntity(the_bomb))
	{
		new bomb_owner = Weapon_GetOwner(the_bomb);
		
		if(bomb_owner != INVALID_ENT_REFERENCE)
		{
			CS_DropWeapon(bomb_owner, the_bomb, false);
		}
	}
	
	// Go through each client and process accordingly
	new team;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if (IsPlayerAlive(i) && roundend_mode == 2)
			{
				SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
				SetEntityRenderColor(i, 255, 255, 254, 165);
			}
			
			team = GetClientTeam(i);
			
			if(team == CS_TEAM_CT && !CTImmune[i]) // Switch this CT to the Terrorist's team
			{
				ClientTimer[i] = CreateTimer(0.2, Timer_ProcessCT, i);
			}
			else if(team == CS_TEAM_T && CTImmune[i]) // Figure out if we need to switch this Terrorist to the CT's team
			{
				ProcessT(i);
			}
		}
	}
	
	// If less than three Terrorists were switched to CT, we need to process further
	if(numSwitched != 3)
	{
		if(numSwitched == 0) // CTs killed themselves or were slayed... something where Terrorists didn't kill them
		{
			SwitchRandom();
		}
		else // Maybe there's a CT killer
		{
			DisplayMenuToCTKiller();
		}
	}
		
	// Since the Terrorists just dominated the CTs, reset the scores - it's only fun to see how many rounds (points) the CTs can get against the Terrorists
	CTScore = 0;
	TScore = 0;
	
	// ===================================================================================================================================
	// Let's get the number of players on the Terrorist's team who killed a player (or players) on the CT team, then announce this everyone
	// ===================================================================================================================================
	CreateTimer(0.3, Timer_WhoWon);//, killers);
}

/**
 * Function for timer that announces the winner of the round
 * 
 * @param	timer		Handle of timer
 * @noreturn
 */
public Action:Timer_WhoWon(Handle:timer)
{
	CPrintToChatAll("%t", "TWon", killers);
}

/**
 * Function for timer to process the CT team switching
 * 
 * @param	timer		Handle of timer
 * @param	client		client index
 * @noreturn
 */
public Action:Timer_ProcessCT(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		ClientTimer[client] = INVALID_HANDLE;
		
		CTImmune[client] = true;
		SwitchPlayerTeam(client, CS_TEAM_T);
	}
}

/**
 * Function that handles the Terrorist's team swapping
 * 
 * @param	client		client index
 * @noreturn
 */
public ProcessT(client)
{
	numSwitched++;
	
	SwitchPlayerTeam(client, CS_TEAM_CT);
	
	if(IsPlayerAlive(client) && roundend_mode == 1)
	{
		SwitchingPlayer[client] = true;
		CS_RespawnPlayer(client);
		SwitchingPlayer[client] = false;
	}
}

/**
 * Function to Scramble teams - moves all players to Terrorist's team, then calls SwitchRandom to move 3 to CT
 * 
 * @noreturn
 */
public ScrambleTeams()
{
	// Move everyone to Terrorist's team
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			new team = GetClientTeam(i);
			if(team == CS_TEAM_CT)
			{
				SwitchPlayerTeam(i, CS_TEAM_T);
			}
		}
	}
	
	// Pull 3 random Ts and put them on CT team
	SwitchRandom();
}

/**
 * Function to Switch a random Terrorist to the CT team
 * @noreturn
 * @note		Uses the global variable numSwitched to know when enough players have been switched
 */
public SwitchRandom()
{
	while(numSwitched < 3)
	{
		// Since less than 3 Ts were switched to the CT team, randomly select 1 or 2 more to be switched
		new i = Client_GetRandom(CLIENTFILTER_TEAMONE);
		
		// If player is a valid client index and is not one of the just switched CTs, switch to CT team.
		if(i != -1)
		{
			CTImmune[i] = true;
			ProcessT(i);
		}
		else
		{
			LogMessage("ERROR with SwitchRandom");
			break;
		}
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
	if(!UseWeaponRestrict || !GameIsLive || !Enabled)
	{
		return Plugin_Continue;
	}
	
	// ===================================================================================================================================
	// Check if weapon being purchased is a flashbang, smoke grenade, or hegrenade, and restrict the purchase if those are prohibited
	// ===================================================================================================================================
	if((StrContains(weapon, "flashbang", false) != -1 && !AllowFlashBangs) || 
		(StrContains(weapon, "smokegrenade", false) != -1 && !AllowSmokes) || 
		(StrContains(weapon, "hegrenade", false) != -1 && !AllowHEGrenades))
	{
		CPrintToChat(client, "%t %t", "Prefix", "NoNade");
		EmitSoundToClient(client, SOUND_FILE);
		return Plugin_Handled;
	}
	
	// ===================================================================================================================================
	// Check if the weapon being purchased is an AWP or Auto and restrict the purchase if it is prohibited
	// ===================================================================================================================================
	if(StrContains(weapon, "awp", false) != -1|| StrContains(weapon, "g3sg1", false) != -1 || StrContains(weapon, "sg550", false) != -1)
	{
		new team = GetClientTeam(client);
		
		switch(team)
		{
			case CS_TEAM_T:
			{
				tawpno++;
			}
			
			case CS_TEAM_CT:
			{
				ctawpno++;
			}
		}
		
		// ===================================================================================================================================
		// Weapon being purchased is an AWP/Auto, let's see if the team the player's on is allowed to buy AWPS/Autos
		// If not, do not allow the purchase.
		// ===================================================================================================================================
		if((team == CS_TEAM_T && TAwps) || (team == CS_TEAM_CT && CTAwps))
		{
			// ===================================================================================================================================
			// If the player's team already has its AWP limit, then this player cannot purchase it
			// Otherwise, allow the purchase as long as the players has the money for it
			// ===================================================================================================================================
			if((team == CS_TEAM_CT && ctawpno > CTAwpNumber) || (team == CS_TEAM_T && tawpno > TAwpNumber))
			{
				CPrintToChat(client, "%t %t", "Prefix", "NoSniper");
				EmitSoundToClient(client, SOUND_FILE);
				return Plugin_Handled;
			}
		}
		else
		{
			CPrintToChat(client, "%t %t", "Prefix", "NoSniper");
			EmitSoundToClient(client, SOUND_FILE);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
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
	if(IsClientInGame(client))
	{
		CTImmune[client] = false;
		PlayerSwitchable[client] = false;
		PlayerKilledCT[client] = 0;
		SwitchingPlayer[client] = false;
		
		ClearTimer(ClientTimer[client]);
		ClearTimer(p_FreezeTime[client]);
		
		if(FillBots && !IsFakeClient(client))
		{
			new humans = Client_GetCount(true, false);
			if(humans + bot_quota <= 8)
			{
				bot_quota++;
				SetConVarInt(brush_botquota, bot_quota);
			}
		}
	}
}

// ===================================================================================================================================
// Thanks to exvel - http://forums.alliedmods.net/showthread.php?p=1287116
// Provided the GetBombsitesIndexes() and tock bool:IsVecBetween
// ===================================================================================================================================
stock GetBomsitesIndexes()
{
	new index = -1;
	
	new Float:vecBombsiteCenterA[3];
	new Float:vecBombsiteCenterB[3];
	
	index = FindEntityByClassname(index, "cs_player_manager");
	if (index != -1)
	{
		GetEntPropVector(index, Prop_Send, "m_bombsiteCenterA", vecBombsiteCenterA);
		GetEntPropVector(index, Prop_Send, "m_bombsiteCenterB", vecBombsiteCenterB);
	}
	
	index = -1;
	while ((index = FindEntityByClassname(index, "func_bomb_target")) != -1)
	{
		new Float:vecBombsiteMin[3];
		new Float:vecBombsiteMax[3];
		
		GetEntPropVector(index, Prop_Send, "m_vecMins", vecBombsiteMin);
		GetEntPropVector(index, Prop_Send, "m_vecMaxs", vecBombsiteMax);
		
		if (IsVecBetween(vecBombsiteCenterA, vecBombsiteMin, vecBombsiteMax))
		{
			g_BombsiteA = index;
		}
		if (IsVecBetween(vecBombsiteCenterB, vecBombsiteMin, vecBombsiteMax))
		{
			g_BombsiteB = index;
		}
	}
}

stock bool:IsVecBetween(const Float:vecVector[3], const Float:vecMin[3], const Float:vecMax[3])
{
	return ( (vecMin[0] <= vecVector[0] <= vecMax[0]) && 
			 (vecMin[1] <= vecVector[1] <= vecMax[1]) && 
			 (vecMin[2] <= vecVector[2] <= vecMax[2]) );
}

// ===================================================================================================================================
// Menu Functions
// ===================================================================================================================================
public DisplayMenuToCTKiller()
{
	new CTclient = GetClientOfUserId(CTKiller);
	
	if(CTclient > 0 && CTclient <= MaxClients && IsClientConnected(CTclient) && !IsFakeClient(CTclient))
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
		
		new Handle:menu = CreateMenu(MenuHandler_Teams);
		SetMenuTitle(menu, "%t", "Menu1");
		SetMenuExitButton(menu, true);
		
		AddTerroristsToMenu(menu);
		
		// Display the team selection menu to the player who killed more than 1 CT
		DisplayMenu(menu, CTclient, MenuTime);
	}
	else
	{
		SwitchRandom();
	}
}

public MenuHandler_Teams(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		info[0] = '\0';
		
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new UserID = StringToInt(info);
		new client = GetClientOfUserId(UserID);
		
		if(GetTeamClientCount(CS_TEAM_CT) < 3)
		{
			//SwitchingPlayer[client] = true;
			
			//CS_SwitchTeam(client, CS_TEAM_CT);
			//set_random_model(client, CS_TEAM_CT);
			SwitchPlayerTeam(client, CS_TEAM_CT);
			
			if(IsPlayerAlive(client))
			{
				SwitchingPlayer[client] = true;
				CS_RespawnPlayer(client);
				SwitchingPlayer[client] = false;
			}
			
			numSwitched++;
		}
		else
		{
			CPrintToChat(client, "%t", "TooLate");
		}
		
		ClientTimer[param1] = CreateTimer(0.2, Timer_MoreTs, param1);
	}
	else if (action == MenuAction_Cancel)
	{
		SwitchRandom();
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Timer_MoreTs(Handle:timer, any:client)
{
	ClientTimer[client] = INVALID_HANDLE;
	
	new TeamCount = GetTeamClientCount(CS_TEAM_CT);
	
	if(TeamCount < 3)
	{
		decl String:sMenuText[64];
		sMenuText[0] = '\0';
		
		new Handle:menu = CreateMenu(MenuHandler_Teams);
		SetMenuTitle(menu, "%t", "Menu2");
		SetMenuExitButton(menu, true);
		
		AddTerroristsToMenu(menu);
		
		DisplayMenu(menu, client, MenuTime);
	}
}

public AddTerroristsToMenu(Handle:menu)
{
	decl String:user_id[12];
	user_id[0] = '\0';
	
	decl String:name[MAX_NAME_LENGTH];
	name[0] = '\0';
	
	decl String:display[MAX_NAME_LENGTH+15];
	display[0] = '\0';
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && !CTImmune[i])
		{
			// Retrieve and store the UserID of player index i as a string
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
			
			GetClientName(i, name, sizeof(name));
			
			Format(display, sizeof(display), "%s (%s)", name, user_id);
			
			AddMenuItem(menu, user_id, display);
		}
	}
}

// ===================================================================================================================================
// Player freeze/unfreeze functions - Thanks to author of Freeze Tag for m_flLaggedMovementValue
// http://forums.alliedmods.net/showthread.php?p=929064
// ===================================================================================================================================

public FreezePlayer(client)
{
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
	SetEntityRenderColor(client, 255, 0, 170, 174);
	IsPlayerFrozen[client] = true;
}

public UnFreezePlayer(client)
{
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	IsPlayerFrozen[client] = false;
}

public Action:Timer_UnFreezePlayer(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		p_FreezeTime[client] = INVALID_HANDLE;
		
		UnFreezePlayer(client);
	}
}

/**
 * Function to clear/kill the timer and set to INVALID_HANDLE if it's still active
 * 
 * @param	timer		Handle of the timer
 * @noreturn
 */
stock ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}     
}

/**
 * Function for randomly selecting the appropriate team player model for the player
 * 
 * @param	client		Client index
 * @param	team		Team index
 * @noreturn
 */
stock set_random_model(client, team)
{
	// Get a random number between 0 and 3
	new random = GetRandomInt(0, 3);
	
	switch(team)
	{
		case CS_TEAM_T:
		{
			SetEntityModel(client, tmodels[random]);
		}
		case CS_TEAM_CT:
		{
			SetEntityModel(client, ctmodels[random]);
		}
	}
}

// ===================================================================================================================================
// CVar Change Functions
// ===================================================================================================================================
public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	// Make sure the version number is what is set in the compiled plugin, not a config file or changed CVar
	if (!StrEqual(newVal, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnUseUpdaterChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseUpdater = GetConVarBool(cvar);
}

public OnUseWeaponRestrictChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseWeaponRestrict = GetConVarBool(cvar);
}

public OnHEGrenadesChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AllowHEGrenades = GetConVarBool(cvar);
}

public OnFlashBangsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AllowFlashBangs = GetConVarBool(cvar);
}

public OnSmokesChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AllowSmokes = GetConVarBool(cvar);
}

public OnCTAwpsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	CTAwps = GetConVarBool(cvar);
}

public OnCTAwpNumberChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	CTAwpNumber = GetConVarInt(cvar);
}

public OnTAwpsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	TAwps = GetConVarBool(cvar);
}

public OnTAwpNumberChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	TAwpNumber = GetConVarInt(cvar);
}

public OnFreezeTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	FreezeTime = GetConVarInt(cvar);
	MenuTime = (3 + FreezeTime) / 2;
}

public OnEnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(StrEqual(newVal, "1"))
	{
		HookEvent("bomb_beginplant", Event_BeginBombPlant);
		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
		HookEvent("round_freeze_end", Event_RoundFreezeEnd);
		HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
		HookEvent("bomb_exploded", Event_BombExploded, EventHookMode_Pre);
		HookEvent("player_spawn", Event_PlayerSpawn);
		HookEvent("bomb_pickup", Event_BombPickup);
		
		AddCommandListener(Command_JoinTeam, "jointeam");
		
		Enabled = true;
	}
	else
	{
		UnhookEvent("bomb_beginplant", Event_BeginBombPlant);
		UnhookEvent("player_death", Event_PlayerDeath);
		UnhookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
		UnhookEvent("round_freeze_end", Event_RoundFreezeEnd);
		UnhookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
		UnhookEvent("bomb_exploded", Event_BombExploded, EventHookMode_Pre);
		UnhookEvent("player_spawn", Event_PlayerSpawn);
		UnhookEvent("bomb_pickup", Event_BombPickup);
		
		RemoveCommandListener(Command_JoinTeam, "jointeam");
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				CTImmune[i] = false;
				PlayerSwitchable[i] = false;
				PlayerKilledCT[i] = 0;
				SwitchingPlayer[i] = false;
			}
		}
		
		Enabled = false;
		
		ClearTimer(LiveTimer);
	}
}

public OnManageBotsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ManageBots = GetConVarBool(cvar);
}

public OnFillBotsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	FillBots = GetConVarBool(cvar);
	
	if(FillBots)
	{
		new humans = Client_GetCount(true, false);
		//ServerCommand("bot_quota %i", 8 - humans);
		SetConVarInt(brush_botquota, 8 - humans);
	}
}

public OnBotQuotaChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	bot_quota = GetConVarInt(cvar);
}

public OnUseConfigsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseConfigs = GetConVarBool(cvar);
}

public OnCTFreezeTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	CTFreezeTime = GetConVarFloat(cvar);
}

public OnTFreezeTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	TFreezeTime = GetConVarFloat(cvar);
}

public OnRoundEndModeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	roundend_mode = GetConVarInt(cvar);
}

public OnBombsiteChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	s_bombsite[0] = '\0';
	GetConVarString(cvar, s_bombsite, sizeof(s_bombsite));
}