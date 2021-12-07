/* B-Rush
* 
* 1002 need to check if anyone is in queue before allowing this event.
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
* 		0.0.2.3	*	Fixed the freezing of players
* 
* 		0.0.2.4	+	Added fast round restart option with configurable time
* 
* 		0.0.2.5	*	Code adjustment from RedSword's comments in forums.
* 				-	Removed set_random_model to make this plugin CS:GO capable
* 
* 		0.0.2.6	-	Removed waiting list feature
* 				*	Fixed timer to use ClientSerial instead of client value
* 
* 		0.0.2.7	+	Added ability to reset player's cash to mp_startmoney when Ts win
* 
* 		0.0.2.8	*	Fixed issues with bot management
* 
* 		0.0.3.0	*	Fixed bot management
* 				+	Manually added SMLib functions for less bloat
* 
* 		0.0.3.1	+	Added CS_UpdateClientModel for team switches (new in SM 1.5.1)
* 					*	Now requires SM 1.5.1+
* 				+	Added a couple more functions from Updater (thanks GoD-Tony)
* 				+	Now using AutoExecConfig include file
* 
* 		0.0.3.2	*	Fixed menu not appearing to CTKiller
* 
* 		0.0.3.3	*	Added checks for if game is CSGO to not use BR_PrintToChat
* 				*	Changed the way bombsites are handled due to crash if bomb is dropped from player while dropping in wrong bombsite.
* 
* 		0.0.3.4	*	Further edits to GetBombSiteIndex function
* 				+	Added include for SDKHooks, not sure why it went missing.
* 				+	Added different method to drop bomb for CS:GO
* 
* 		0.0.3.5	*	Made changes for BR_PrintToChat... for CS:GO
* 
* 		0.0.3.6	+	Added bot bombsite controls
* 
* 		0.0.3.7	*	Enhanced bot control to bombsite and added bombsite area instead of bombsite center for where bots rush to.
* 				*	Enhanced bot_quota stuff
* 
* 		0.0.3.8	*	Removed all CS:GO code, this will be for CS:S only - CS:GO will have it's own plugin
* 		
* 		0.1.0.0	*	Reworked most of the code, simplified some functions.
* 
* 		0.1.0.1	*	Now requires SM 1.6.0-hg4115 or later due to use of RequestFrame Function to handle bot teamjoins.
* 
* 		0.1.1.0	*	Added weapon reset for when Terrorists win
* 				*	Fixed some client validation code for visual enhancement only
* 
* 
* 	TO DO List
* 		Add Queue Manager
* 			-	Queue for players waiting to jump in when someone leaves
* 			-	Incorporate with bot management
* 
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
* 		Try to optimize this plugin by using less for (new... cycling through all of the players)
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
#include <sdkhooks>
#include <cstrike>
#include <morecolors>
#include <autoexecconfig>
#include <adminmenu>
#undef REQUIRE_PLUGIN
#include <updater>

// ===================================================================================================================================
// Defines
// ===================================================================================================================================
#define 	PLUGIN_VERSION 		"0.1.1.0"
#define 	UPDATE_URL 			"http://dl.dropbox.com/u/3266762/brush.txt"
#define 	SOUND_FILE 			"buttons/weapon_cant_buy.wav" // cstrike\sound\buttons

//#define PANEL_TEAM "team"

#define _DEBUG 					0	// Set to 1 for debug spew to log file
#define _DEBUG_CHAT				0	// Set to 1 for debug spew to in-game chat

#define MAX_WEAPON_STRING		80
#define MAX_WEAPONS				48	// Max number of weapons available

#define CLIENTFILTER_ALL				0		// No filtering
#define CLIENTFILTER_BOTS			( 1	<< 1  )	// Fake clients
#define CLIENTFILTER_NOBOTS			( 1	<< 2  )	// No fake clients
#define CLIENTFILTER_AUTHORIZED		( 1 << 3  ) // SteamID validated
#define CLIENTFILTER_NOTAUTHORIZED  ( 1 << 4  ) // SteamID not validated (yet)
#define CLIENTFILTER_ADMINS			( 1	<< 5  )	// Generic Admins (or higher)
#define CLIENTFILTER_NOADMINS		( 1	<< 6  )	// No generic admins
// All flags below require ingame checking (optimization)
#define CLIENTFILTER_INGAME			( 1	<< 7  )	// Ingame
#define CLIENTFILTER_INGAMEAUTH		( 1 << 8  ) // Ingame & Authorized
#define CLIENTFILTER_NOTINGAME		( 1 << 9  )	// Not ingame (currently connecting)
#define CLIENTFILTER_ALIVE			( 1	<< 10 )	// Alive
#define CLIENTFILTER_DEAD			( 1	<< 11 )	// Dead
#define CLIENTFILTER_SPECTATORS		( 1 << 12 )	// Spectators
#define CLIENTFILTER_NOSPECTATORS	( 1 << 13 )	// No Spectators
#define CLIENTFILTER_OBSERVERS		( 1 << 14 )	// Observers
#define CLIENTFILTER_NOOBSERVERS	( 1 << 15 )	// No Observers
#define CLIENTFILTER_TEAMONE		( 1 << 16 )	// First Team (Terrorists, ...)
#define CLIENTFILTER_TEAMTWO		( 1 << 17 )	// Second Team (Counter-Terrorists, ...)

// Team Defines
#define	TEAM_INVALID	-1
#define TEAM_UNASSIGNED	0
#define TEAM_SPECTATOR	1
#define TEAM_ONE		2
#define TEAM_TWO		3
#define TEAM_THREE		4
#define TEAM_FOUR		5

#define SIZE_OF_INT		2147483647		// without 0

// ===================================================================================================================================
// Client Variables
// ===================================================================================================================================
new CTKiller = 0; // Holds the UserID of the T who killed 2+ CTs

new PlayerKilledCT[MAXPLAYERS+1] = 0; // Holds the number of CTs the T killed
new ChangeTeamImmune[MAXPLAYERS+1] = false; // Marks the player as Change Team Immune
new SwitchingPlayer[MAXPLAYERS+1] = false; // Flags the player as being switched by the plugin
new bool:PlayerSwitchable[MAXPLAYERS+1] = false; // Flags the player as switchable

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
new bool:UseConfigs; // Bool to let the plugin know if it should execute live/notlive config files
new Float:CTFreezeTime; // Time for extra time the CTs should remain frozen after mp_freezetime has expired
new Float:TFreezeTime;// Time for extra time the Terrorists should remain frozen after mp_freezetime has expired

new Handle:LiveTimer = INVALID_HANDLE; // Timer handle for checking when the conditions match to go live
//new Handle:brush_botquota; // Handle for cvar bot_quota so we can change the amount later

new bool:CTAwps = false; // Bool to allow CTs to purchase AWPs/Autos
new CTAwpNumber; // Number of AWPs/Autos to allow the CTs to buy
new bool:TAwps = false; // Bool to allow the Ts to purchase AWPs/Autos
new TAwpNumber; // Number o fAWPs/Autos to allow the Ts to buy

new FreezeTime; // Amount of time in mp_freezetime
new MenuTime; // Calculated time to show the menu to the player who killed 2+ CTs before the menu goes away and a random teammate is chosen
new CTScore = 0; // Holder for CT Score
new killers = 0; // Holder for the number of Ts that killed CTs
new g_BombsiteB = -1; // Holder for Bomb site B entity index
new g_BombsiteA = -1; // Holder for Bomb site A entity index
new numSwitched = 0; // Holds the number of Ts that are switched to CT - used for randomswitch and menu building
//new bot_quota; // Holds the game's bot_quota
new the_bomb = INVALID_ENT_REFERENCE; // Holds the entity index of the bomb
new roundend_mode; // Holds the round end mode setting

new tawpno = 0; // Holds the number of AWPs/AUTOs the Terrorists have
new ctawpno = 0; // Holds the number of AWPs/AUTOs the CTs have

new bool:IsPlayerFrozen[MAXPLAYERS+1] = {false, ...};

new String:s_bombsite[] = "B";
new String:BR_msg[MAX_MESSAGE_LENGTH];
new bool:UseBombsiteDisable;

new bool:fast_round = false;
new fr_time = 1;
new Handle:fr_restart = INVALID_HANDLE;

new Float:vecBombsiteCenterA[3];
new Float:vecBombsiteCenterB[3];

new bool:ResetPlayerCash;
new bool:ResetPlayerWeapons;
new String:TPistol[MAX_WEAPON_STRING];
new String:CTPistol[MAX_WEAPON_STRING];
new DefaultStartCash;
new g_iAccount = -1;
new bool:lateLoad;
new bool:NeedsCashReset;

new String:g_sOrgBotQuotaMode[15];
new g_iOrgBotQuota;

#if _DEBUG
new String:dmsg[MAX_MESSAGE_LENGTH];
#endif


public Plugin:myinfo = {
	name = "CSS BRush",
	author = "TnTSCS aka ClarkKent",
	description = "B Rush bomb site only - 5T vs 3CT",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

/**
 * Called before OnPluginStart, in case the plugin wants to check for load failure.
 * This is called even if the plugin type is "private."  Any natives from modules are 
 * not available at this point.  Thus, this forward should only be used for explicit 
 * pre-emptive things, such as adding dynamic natives, setting certain types of load 
 * filters (such as not loading the plugin for certain games).
 * 
 * @note It is not safe to call externally resolved natives until OnPluginStart().
 * @note Any sort of RTE in this function will cause the plugin to fail loading.
 * @note If you do not return anything, it is treated like returning success. 
 * @note If a plugin has an AskPluginLoad2(), AskPluginLoad() will not be called.
 *
 *
 * @param myself	Handle to the plugin.
 * @param late		Whether or not the plugin was loaded "late" (after map load).
 * @param error		Error message buffer in case load failed.
 * @param err_max	Maximum number of characters for error message buffer.
 * @return		APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise
 */
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	lateLoad = late;
	return APLRes_Success;
}

public OnPluginStart() {
	new bool:appended;
	AutoExecConfig_SetFile("plugin.brush");
	
	new Handle:hRandom; // KyleS HATES handles
	
	HookConVarChange((hRandom = CreateConVar("sm_brush_version", PLUGIN_VERSION, 
	"Version of 'CSS BRush'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_useupdater", "0", 
	"Utilize 'Updater' plugin to auto-update CSS BRush when updates are published?\n1=yes\n0=no", FCVAR_NONE, true, 0.0, true, 1.0)), OnUseUpdaterChanged);
	UseUpdater = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_useweaprestrict", "1", 
	"Use this plugin's weapon restrict features?\n1=yes\n0=no - if you are going to use a different weapon restrict plugin", FCVAR_NONE, true, 0.0, true, 1.0)), OnUseWeaponRestrictChanged);
	UseWeaponRestrict = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_hegrenades", "0", 
	"Allow players to buy/use HEGrenades?\n1=yes\n0=no", FCVAR_NONE, true, 0.0, true, 1.0)), OnHEGrenadesChanged);
	AllowHEGrenades = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_flashbangs", "0", 
	"Allow players to buy/use FlashBangs?\n1=yes\n0=no", FCVAR_NONE, true, 0.0, true, 1.0)), OnFlashBangsChanged);
	AllowFlashBangs = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_smokes", "0", 
	"Allow players to buy/use Smoke Grenades?\n1=yes\n0=no", FCVAR_NONE, true, 0.0, true, 1.0)), OnSmokesChanged);
	AllowSmokes = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_ctawps", "1", 
	"Allow CTs to buy/use AWPs/Autos?\n1=yes\n0=no", FCVAR_NONE, true, 0.0, true, 1.0)), OnCTAwpsChanged);
	CTAwps = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_ctawpnumber", "1", 
	"If CTs are allowed to buy/use AWPs/Autos, how many should they be limited to?", FCVAR_NONE, true, 1.0, true, 3.0)), OnCTAwpNumberChanged);
	CTAwpNumber = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_tawps", "0", 
	"Allow Ts to buy/use AWPs/Autos?\n1=yes\n0=no", FCVAR_NONE, true, 0.0, true, 1.0)), OnTAwpsChanged);
	TAwps = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_tawpnumber", "1", 
	"If Ts are allowed to buy/use AWPs/Autos, how many should they be limited to?", FCVAR_NONE, true, 1.0, true, 5.0)), OnTAwpNumberChanged);
	TAwpNumber = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = FindConVar("mp_freezetime")), OnFreezeTimeChanged);
	FreezeTime = GetConVarInt(hRandom);
	MenuTime = (3 + FreezeTime) / 2;
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_enabled", "1", 
	"Is this plugin enabled?", FCVAR_NONE, true, 0.0, true, 1.0)), OnEnabledChanged);
	Enabled = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_managebots", "0", 
	"Allow BRush to manage bots, if present, as human players join or leave a team?", FCVAR_NONE, true, 0.0, true, 1.0)), OnManageBotsChanged);
	ManageBots = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_usecfgs", "0", 
	"Should BRush execute the brush.live.cfg and brush.notlive.cfg configs (located in cstrike/cfg)?", FCVAR_NONE, true, 0.0, true, 1.0)), OnUseConfigsChanged);
	UseConfigs = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_ctfreeze", "0.0", 
	"How long should the CTs remain frozen after mp_freezetime has expired?", FCVAR_NONE, true, 0.0, true, 25.0)), OnCTFreezeTimeChanged);
	CTFreezeTime = GetConVarFloat(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_tfreeze", "0.0", 
	"How long should the Terrorists remain frozen after mp_freezetime has expired?", FCVAR_NONE, true, 0.0, true, 25.0)), OnTFreezeTimeChanged);
	TFreezeTime = GetConVarFloat(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_endmode", "1", 
	"What should happen to players when the round ends and the Terrorists are the winners?\n0 = Nothing\n1 = Teleport alive players back to their spawn\n2 = Give alive players god mode", FCVAR_NONE, true, 0.0, true, 2.0)), OnRoundEndModeChanged);
	roundend_mode = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_bombsite", "B", 
	"What bomb site should be used?", FCVAR_NONE)), OnBombsiteChanged);
	GetConVarString(hRandom, s_bombsite, sizeof(s_bombsite));
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_fastround", "0", 
	"Use fast round?\n0 = No\n1 = Yes, restart round fast to speed up game play when Terrorists win", FCVAR_NONE, true, 0.0, true, 1.0)), OnFastRoundChanged);
	fast_round = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_frtime", "1", 
	"If using fast round, specify the number of seconds to restart the round", FCVAR_NONE, true, 1.0, true, 5.0)), OnFastRoundTimeChanged);
	fr_time = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_resetcash", "1",
	"Reset player's cash when Ts win?\n0 = No\n1 = Yes", FCVAR_NONE, true, 0.0, true, 1.0)), OnResetCashChanged);
	ResetPlayerCash = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_resetweapons", "1",
	"Reset player's weapons when Ts win?\n0 = No\n1 = Yes", FCVAR_NONE, true, 0.0, true, 1.0)), OnResetWeaponsChanged);
	ResetPlayerWeapons = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_ct_pistol", "weapon_usp",
	"Default weapon for CTs (if using sm_brush_resetweapons)", FCVAR_NONE)), OnResetCTPistolChanged);
	GetConVarString(hRandom, CTPistol, sizeof(CTPistol));
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_t_pistol", "weapon_glock",
	"Default weapon for Terrorists (if using sm_brush_resetweapons)", FCVAR_NONE)), OnResetTPistolChanged);
	GetConVarString(hRandom, TPistol, sizeof(TPistol));
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_brush_bombsitedisable", "0",
	"Use this plugins bombsite disable feature?\n0 = No\n1 = Yes", FCVAR_NONE, true, 0.0, true, 1.0)), OnUseBombsiteDisableChanged);
	UseBombsiteDisable = GetConVarBool(hRandom);
	SetAppend(appended);
	
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	if (g_iAccount == -1)
	{
		SetFailState("Could not find m_iAccount");
	}
	
	fr_restart = FindConVar("mp_restartgame");
	if (fr_restart == INVALID_HANDLE)
	{
		SetFailState("Unable to hook mp_restartgame");
	}
	
	//HookConVarChange((brush_botquota = FindConVar("bot_quota")), OnBotQuotaChanged);
	//bot_quota = GetConVarInt(brush_botquota);
	
	LoadTranslations("brush.phrases");
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("bomb_exploded", Event_BombExploded, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("bomb_pickup", Event_BombPickup);
	
	HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);
	
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Command_JoinClass, "joinclass");
	
	// Execute the config file
	AutoExecConfig(true, "plugin.brush");
	
	CloseHandle(hRandom);
	
	// Cleaning is an expensive operation and should be done at the end
	if (appended)
	{
		AutoExecConfig_CleanFile();
	}
	
	if (lateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				ResetClientVariables(i);
			}
		}
	}
}

/**
 * Called after a library is added that the current plugin references 
 * optionally. A library is either a plugin name or extension name, as 
 * exposed via its include file.
 *
 * @param name			Library name.
 */
public OnLibraryAdded(const String:name[]) {
	// Check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if (UseUpdater && StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

/**
 * Called when your plugin is about to begin downloading an available update.
 *
 * @return		Plugin_Handled to prevent downloading, Plugin_Continue to allow it.
 */
public Action:Updater_OnPluginDownloading() {
	BR_PrintToChatAll("{green}::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::");
	BR_PrintToChatAll("{green}::: {red}BRush is downloading an update and will reload shortly {green}:::");
	BR_PrintToChatAll("{green}::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::");
	
	return Plugin_Continue;
}

/**
 * Called when your plugin's update has been completed. It is safe
 * to reload your plugin at this time.
 *
 * @noreturn
 */
public Updater_OnPluginUpdated() {
	ReloadPlugin(INVALID_HANDLE);
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
public OnConfigsExecuted() {
	// Check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if (UseUpdater && LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	// For the restriction sound that plays to the player
	if (!PrecacheSound(SOUND_FILE, true))
	{
		LogError("Unable to precache sound file %s", SOUND_FILE);
	}
	
	new Handle:g_hBotQuotaMode = FindConVar("bot_quota_mode");
	GetConVarString(g_hBotQuotaMode, g_sOrgBotQuotaMode, sizeof(g_sOrgBotQuotaMode));
	
	new Handle:g_hBotQuota = FindConVar("bot_quota");
	g_iOrgBotQuota = GetConVarInt(g_hBotQuota);
	
	if (ManageBots)
	{
		SetConVarString(g_hBotQuotaMode, "fill");
		
		SetConVarInt(g_hBotQuota, 8);
	}
	
	CloseHandle(g_hBotQuotaMode);
	CloseHandle(g_hBotQuota);
	
	new Handle:g_hStartMoney = FindConVar("mp_startmoney");	
	if (g_hStartMoney == INVALID_HANDLE)
	{
		SetFailState("Unable to hook mp_startmoney");
	}
	DefaultStartCash = GetConVarInt(g_hStartMoney);
	
	CloseHandle(g_hStartMoney);
}

public OnMapStart()
{
	
}

public OnMapEnd()
{
	if (IsValidEntity(g_BombsiteA))
	{
		AcceptEntityInput(g_BombsiteA, "Enable");
	}
	
	if (IsValidEntity(g_BombsiteB))
	{
		AcceptEntityInput(g_BombsiteB, "Enable");
	}
	
	g_BombsiteA = -1;
	g_BombsiteB = -1;
}

/**
 * Called once a client successfully connects.  This callback is paired with OnClientDisconnect.
 *
 * @param client		Client index.
 * @noreturn
 */
public OnClientConnected(client) { // No bot_quota stuff here, not until a player joins a team
	if (!Enabled)
	{
		return;
	}
	
	if ((StrEqual(s_bombsite, "A", false) && g_BombsiteA == -1) || (StrEqual(s_bombsite, "B", false) && g_BombsiteB == -1))
	{
		GetBomsitesIndexes();
	}
	
	ResetClientVariables(client);
	
	/* We'll handle this a different way in the player_team event
	if (IsFakeClient(client))
	{ // Bot is joining, let's make sure he goes on the correct team
		CreateTimer(0.3, Timer_HandleTeamSwitch, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	*/
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
public OnClientPostAdminCheck(client) {
	if (Enabled && IsClientInGame(client) && !IsFakeClient(client))
	{
		PrintToConsole(client, "\n\n******************************");
		PrintToConsole(client, "[CSS BRush] v%s by TnTSCS", PLUGIN_VERSION);
		PrintToConsole(client, "******************************\n");
	}
}

/**
 * Called when a client is disconnecting from the server.
 *
 * @param client		Client index.
 * @noreturn
 * @note	Must use IsClientInGame(client) if you want to do client specific things
 */
public OnClientDisconnect(client) {
	if (IsClientInGame(client))
	{
		ResetClientVariables(client);
	}
}

/**
 * @brief When an entity is created
 *
 * @param		entity		Entity index
 * @param		classname	Class name
 * @noreturn
 */
public OnEntityCreated(entity, const String:classname[]) {
	if (StrEqual(classname, "weapon_c4", false))
	{ // Get the entity index of the bomb so we can later on have the owner of the bomb drop it, if necessary
		the_bomb = entity;
		
		#if _DEBUG
		Format(dmsg, sizeof(dmsg), "[OnEntityCreated] the_bomb index is %i", the_bomb);
		DebugMessage(dmsg);
		#endif
	}
	
	if (StrEqual(classname, "planted_c4", false))
	{ // If the bomb is planted, set the bomb entity index to -1 so we can bypass the bomb dropping function
		the_bomb = INVALID_ENT_REFERENCE;
		
		#if _DEBUG
		Format(dmsg, sizeof(dmsg), "[OnEntityCreated] Bomb was planted, the_bomb index is set to -1");
		DebugMessage(dmsg);
		#endif
	}
}

public Action:Command_JoinTeam(client, const String:command[], argc) {
	/* *********************************************************************
	* Bots don't flow through this routine, We'll handle tham a different way in the player_team event
	* Player's don't flow through this when acted against using CS_SwitchTeam or ChangeClientTeam 
	* **********************************************************************/
	if (client == 0 || !IsClientInGame(client))
	{
		#if _DEBUG
		Format(dmsg, sizeof(dmsg), "[Command_JoinTeam] Client [%i] is either invalid or not in game.", client);
		DebugMessage(dmsg);
		#endif
		
		return Plugin_Continue;
	}
	
	new String:arg1[2];
	GetCmdArg(1, arg1, sizeof(arg1));
	new team = StringToInt(arg1);
	
	#if _DEBUG
	Format(dmsg, sizeof(dmsg), "[Command_JoinTeam] %L is attempting to join team [%i]", client, team);
	DebugMessage(dmsg);
	#endif
	
	if (team == CS_TEAM_NONE) // Player used auto team, let's try to find them a team they can join
	{
		#if _DEBUG
		Format(dmsg, sizeof(dmsg), "[Command_JoinTeam] %L used autojoin", client);
		DebugMessage(dmsg);
		#endif
		
		if (GetTeamClientCount(CS_TEAM_CT) < 3 || (ManageBots && IsBotOnTeam(CS_TEAM_CT)))
		{ // Team has less than 3 players or there is a bot on the team
			#if _DEBUG
			Format(dmsg, sizeof(dmsg), "[Command_JoinTeam] %L tried to join CT, it has 3 players already, and a bot is on the team, allow the join", client);
			DebugMessage(dmsg);
			#endif
			
			if (ManageBots && IsBotOnTeam(CS_TEAM_CT))
			{
				KickClient(GetBotOnPlayerTeam(CS_TEAM_CT), "Making room for human player");
			}
			
			SwitchPlayerTeam(client, CS_TEAM_CT);
			return Plugin_Handled;
		}
		
		if (GetTeamClientCount(CS_TEAM_T) < 5 || (ManageBots && IsBotOnTeam(CS_TEAM_T)))
		{ // Team has less than 3 players or there is a bot on the team
			#if _DEBUG
			Format(dmsg, sizeof(dmsg), "[Command_JoinTeam] %L tried to join Terrorist, it has 3 players already, and a bot is on the team, allow the join", client);
			DebugMessage(dmsg);
			#endif
			
			if (ManageBots && IsBotOnTeam(CS_TEAM_T))
			{
				KickClient(GetBotOnPlayerTeam(CS_TEAM_T), "Making room for human player");
			}
			
			SwitchPlayerTeam(client, CS_TEAM_T);
			return Plugin_Handled;
		}
		
		#if _DEBUG
		Format(dmsg, sizeof(dmsg), "[Command_JoinTeam] %L used autojoin, but all teams are full and no bots are in-game", client);
		DebugMessage(dmsg);
		#endif
		
		SwitchPlayerTeam(client, CS_TEAM_SPECTATOR);
		return Plugin_Handled;
	}
	
	if (team > CS_TEAM_SPECTATOR) // Player is trying to join CT or Terrorist at this point
	{
		#if _DEBUG
		Format(dmsg, sizeof(dmsg), "[Command_JoinTeam] %L used command to join team [%i]", client, team);
		DebugMessage(dmsg);
		#endif
		
		new maxCount;
		(team == CS_TEAM_CT) ? (maxCount = 3) : (maxCount = 5);
		
		if (GetTeamClientCount(team) < maxCount || (ManageBots && IsBotOnTeam(team)))
		{ // Team has less than max players or there is a bot on the team
			#if _DEBUG
			Format(dmsg, sizeof(dmsg), "[Command_JoinTeam] %L tried to join team [%i], it has %i players already, and a bot is on the team, allow the join", client, team, maxCount);
			DebugMessage(dmsg);
			#endif
			
			// Do we need to kick, or would CVar BOT_AUTO_VACATE handle the kicking of the bot?
			//KickClient(GetBotOnPlayerTeam(team), "Making room for human player");
			
			SwitchPlayerTeam(client, team);
			return Plugin_Handled;
		}
		else
		{
			/* There does not appear to be any room on the teams for this player */
			#if _DEBUG
			Format(dmsg, sizeof(dmsg), "[Command_JoinTeam] %L tried to join team [%i], but it is full and no bot is on that team", client, team);
			DebugMessage(dmsg);
			#endif
			
			SwitchPlayerTeam(client, CS_TEAM_SPECTATOR);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Handled;
}

bool:IsBotOnTeam(team)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == team)
		{
			return true;
		}
	}
	
	return false;
}

public Action:Command_JoinClass(client, const String:command[], argc) {
	/* At this point, player has already picked the team, now picking the class */ 
	
	// Bots don't flow through this routine.
	// Player's only go through this if they use the command joinclass or plugin uses ChangeClientTeam
	#if _DEBUG
	new String:arg1[2];
	GetCmdArg(1, arg1, sizeof(arg1));
	Format(dmsg, sizeof(dmsg), "[Command_JoinClass] %L is on team [%s] and is attempting to join class [%s]", client, (GetClientTeam(client) == CS_TEAM_CT ? "CT" : "Terrorist"), arg1);
	DebugMessage(dmsg);
	#endif
	
	// Needs testing to see if a player (or players) have picked their team and are stalling in the class selection,
	// will plugin allow more than normally allowed number of players to join a team
}

/**
 * Check if a bot is on a given team and return the first found bot's ClientID
 * 
 * @param	team	Team index to check
 * @return	ClientID of first bot found or 0 if no bots found
 */
GetBotOnPlayerTeam(team)
{
	new idx = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && team == GetClientTeam(i))
		{
			idx = i;
			break;
		}
	}
	
	return idx;
}

SwitchPlayerTeam(client, team) {
	#if _DEBUG
	Format(dmsg, sizeof(dmsg), "[SwitchPlayerTeam] %N is being switched to team %i, SP value is [%i], Immune value is [%i]", client, team, SwitchingPlayer[client], ChangeTeamImmune[client]);
	DebugMessage(dmsg);
	#endif
	
	if (team > CS_TEAM_SPECTATOR)
	{
		CS_SwitchTeam(client, team);
		CS_UpdateClientModel(client);
		CS_RespawnPlayer(client);
	}
	else
	{
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	}
}

public Action:Event_ServerCvar(Handle:event, const String:name[], bool:dontBroadcast) {
	//#if _DEBUG
	//	return Plugin_Continue;
	//#endif
	
	new String:sConVarName[64];
	
	GetEventString(event, "cvarname", sConVarName, sizeof(sConVarName));
	
	if (StrContains(sConVarName, "bot_quota", false) >= 0)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!Enabled)
	{
		return Plugin_Continue;
	}
	
	dontBroadcast = true;
	
	#if _DEBUG
	Format(dmsg, sizeof(dmsg), "[Event_PlayerTeam] %L triggered player_team event", GetClientOfUserId(GetEventInt(event, "userid")));
	DebugMessage(dmsg);
	#endif
	
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (!SwitchingPlayer[client])
	{
		RequestFrame(RequestFrameCallback:HandlePlayerTeam, userid);
	}
	
	return Plugin_Changed;
}

/**
 * The function that is called on the next frame of the event "player_team" to aid in handling the event for bots
 * 
 * @param	userid	Player's UserID
 * @noreturn	
 */
public HandlePlayerTeam(userid) {
	// The player is on the team at this point
	
	new client = GetClientOfUserId(userid);
	if (client == 0)
	{
		// Bots disconnecting will trigger this for some reason
		return;
	}
	
	new team = GetClientTeam(client);
	new String:teamName[30];
	switch(team)
	{
		case CS_TEAM_CT: { Format(teamName, sizeof(teamName), "CT"); }
		case CS_TEAM_T: { Format(teamName, sizeof(teamName), "Terrorist"); }
		case CS_TEAM_NONE: { Format(teamName, sizeof(teamName), "NONE"); }
		case CS_TEAM_SPECTATOR: { Format(teamName, sizeof(teamName), "Spectator"); }
	}
	
	if (SwitchingPlayer[client])
	{ // Allow the event to flow
		#if _DEBUG
		Format(dmsg, sizeof(dmsg), "[HandlePlayerTeam] %L allowed to join team [%s] because plugin is switching them", client, teamName);
		DebugMessage(dmsg);
		#endif
		
		SwitchingPlayer[client] = false;
		
		return;
	}
	
	#if _DEBUG
	Format(dmsg, sizeof(dmsg), "[HandlePlayerTeam] %L joined team [%s], SP value [%i]", client, teamName, SwitchingPlayer[client]);
	DebugMessage(dmsg);
	#endif
	
	if (team <= CS_TEAM_SPECTATOR)
	{ // Allow player to move to spectator
		#if _DEBUG
		Format(dmsg, sizeof(dmsg), "[HandlePlayerTeam] %L allowed to join team [%s] because they are not joining T or CT", client, teamName);
		DebugMessage(dmsg);
		#endif
		
		return;
	}
	
	// If, as a result of this event, the team the player joined has more then the max allowed, move the player to spectate
	new maxCount;
	(team == CS_TEAM_CT) ? (maxCount = 3) : (maxCount = 5);
	
	if (IsFakeClient(client) && !IsClientSourceTV(client) && !IsClientReplay(client))
	{ // Bot is triggering this event
		if (GetTeamClientCount(team) > maxCount) // && no one is in the queue
		{
			#if _DEBUG
			Format(dmsg, sizeof(dmsg), "[HandlePlayerTeam] %L being switched because they joined a full team, SP value [%i]", client, SwitchingPlayer[client]);
			DebugMessage(dmsg);
			#endif
			
			(team == CS_TEAM_CT) ? (SwitchPlayerTeam(client, CS_TEAM_T)) : (SwitchPlayerTeam(client, CS_TEAM_CT));
			return;
		}
	}
	else
	{ // Human is triggering this event
		if (GetTeamClientCount(team) > maxCount && !IsBotOnTeam(team)) // && no one is in the queue
		{
			SwitchPlayerTeam(client, CS_TEAM_SPECTATOR);
			return;
		}
	}
	
	// NEED QUEUE CHECKING HERE
}

/**
 * Called when a player spawns.
 *
 * @param event			Handle to event. This could be INVALID_HANDLE if every plugin hooking 
 *						this event has set the hook mode EventHookMode_PostNoCopy.
 * @param name			String containing the name of the event.
 * @param dontBroadcast	True if event was not broadcast to clients, false otherwise.
 * @noreturn
 * 
 * @eventparam	userid	UserID of player spawning
 */
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!Enabled || !(1 <= client <= MaxClients) || !IsClientInGame(client) || GetClientTeam(client) <= CS_TEAM_NONE)
	{
		return;
	}
	
	ResetClientVariables(client);
	
	if (NeedsCashReset)
	{
		if (ResetPlayerCash)
		{
			CreateTimer(0.1, Timer_ResetPlayerCash, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		if (ResetPlayerWeapons)
		{
			CreateTimer(0.1, Timer_ResetPlayerWeapons, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
			return;
		}
	}
	
	new team = GetClientTeam(client);
	
	new String:WeaponName[MAX_WEAPON_STRING];
	
	new wEnt = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	
	if (wEnt == INVALID_ENT_REFERENCE && wEnt <= MaxClients)
	{
		return;
	}
	
	GetEntityClassname(wEnt, WeaponName, sizeof(WeaponName));
		
	if (StrContains(WeaponName, "awp", false) != -1 || StrContains(WeaponName, "g3sg1", false) != -1 || StrContains(WeaponName, "sg550", false) != -1)
	{
		team == CS_TEAM_CT ? ctawpno++ : tawpno++;
		
		// Need to figure out if player's team has too many snipers, if so, drop this one from player.
		if ((team == CS_TEAM_CT && ctawpno > CTAwpNumber) || (team == CS_TEAM_T && tawpno > TAwpNumber))
		{
			Format(BR_msg, sizeof(BR_msg), "%t %t", "Prefix", "NoSniperSpawn");
			BR_PrintToChat(client, BR_msg);
			EmitSoundToClient(client, SOUND_FILE);
			CS_DropWeapon(client, wEnt, true);
			// Set location for teleport
			//new Float:orgin[3] = {-10000.0, -10000.0, -10000.0};
			// Get rid of weapon
			//TeleportEntity(weapon, orgin, NULL_VECTOR, NULL_VECTOR);
			
			AcceptEntityInput(wEnt, "kill");
		}
	}
}

/**
 * Called when mp_freezetime expires.
 *
 * @param event			Handle to event. This could be INVALID_HANDLE if every plugin hooking 
 *						this event has set the hook mode EventHookMode_PostNoCopy.
 * @param name			String containing the name of the event.
 * @param dontBroadcast	True if event was not broadcast to clients, false otherwise.
 * @noreturn
 */
public Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	NeedsCashReset = false;
	
	if ((StrEqual(s_bombsite, "A", false) && g_BombsiteA == -1) || (StrEqual(s_bombsite, "B", false) && g_BombsiteB == -1))
	{ // Why don't we have the bombsite indexes yet?
		GetBomsitesIndexes();
	}
	
	new tCount = 0, ctCount = 0;
	Team_GetClientCounts(tCount, ctCount, CLIENTFILTER_NOSPECTATORS);
	
	// ===================================================================================================================================
	// Make sure conditions are appropriate for BRush round - 5 players on Terrorist's team and 3 players on CT's team
	// ===================================================================================================================================
	if (tCount == 5 && ctCount == 3)
	{
		GameIsLive = true;
		
		// Let the players know this round is LIVE
		Format(BR_msg, sizeof(BR_msg), "%t %t", "Prefix", "LiveRound");
		BR_PrintToChatAll(BR_msg);
		
		PrintCenterTextAll("%t", "LiveRound");
		
		ApplyPlayerFreeze();
	}
	else
	{
		if (GameIsLive && UseConfigs)
		{
			ServerCommand("exec brush.notlive.cfg"); // Since the game had been live, but is now not live, execute the notlive config
		}
		
		GameIsLive = false;
		
		// Let the players know this round is not live
		Format(BR_msg, sizeof(BR_msg), "%t %t", "Prefix", "NotLiveRound");
		BR_PrintToChatAll(BR_msg);
		
		// Start a repeating timer (if one isn't already running) to constantly check for BRUSH live round conditions
		if (LiveTimer == INVALID_HANDLE)
		{
			// The 3.0 seconds is for the PrintKeyHintText display time
			LiveTimer = CreateTimer(3.0, Timer_CheckLive, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	CTKiller = 0; // Set this holder to zero so we'll know later on if there is a CTKiller	
	numSwitched = 0; // Set this to 0 so we can accuratly keep track of how many Terrorists are switched	
	killers = 0; // Set this to 0 so we can accuratly count how many Terrorist kill CTs
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			ChangeTeamImmune[i] = false;
		}
	}
}

/**
 * Called when the bomb is planted.
 *
 * @param event			Handle to event. This could be INVALID_HANDLE if every plugin hooking 
 *						this event has set the hook mode EventHookMode_PostNoCopy.
 * @param name			String containing the name of the event.
 * @param dontBroadcast	True if event was not broadcast to clients, false otherwise.
 * @noreturn
 * 
 * @eventparam	userid	player who picked up the bomb
 */
public Event_BombPickup(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client || IsFakeClient(client))
	{
		return;
	}
	
	if (StrEqual(s_bombsite, "A", false))
	{
		Format(BR_msg, sizeof(BR_msg), "%t", "PlantA");
		BR_PrintToChat(client, BR_msg);
		
		return;
	}
	
	if (StrEqual(s_bombsite, "B", false))
	{
		Format(BR_msg, sizeof(BR_msg), "%t", "PlantB");
		BR_PrintToChat(client, BR_msg);
		
		return;
	}
	
	LogError("ERROR WITH BOMB SITE CVAR - it's not set to A or B!!");
}

/**
 * Called when a player starts planting the bomb.
 *
 * @param event			Handle to event. This could be INVALID_HANDLE if every plugin hooking 
 *						this event has set the hook mode EventHookMode_PostNoCopy.
 * @param name			String containing the name of the event.
 * @param dontBroadcast	True if event was not broadcast to clients, false otherwise.
 * @noreturn
 * 
 * @eventparam	userid	Player who is planting the bomb
 * @eventparma	site		Bombsite index
 */
public Event_BeginBombPlant(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!GameIsLive)
	{
		return;
	}
	
	new bombsite = GetEventInt(event, "site");
	
	if ((StrEqual(s_bombsite, "B", false) && bombsite == g_BombsiteB) || (StrEqual(s_bombsite, "A", false) && bombsite == g_BombsiteA))
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (StrEqual(s_bombsite, "B", false) && bombsite != g_BombsiteB)
	{
		Format(BR_msg, sizeof(BR_msg), "%t %t", "Prefix", "PlantB");
		BR_PrintToChat(client, BR_msg);
		
		AcceptEntityInput(g_BombsiteA, "Disable");
	}
	
	if (StrEqual(s_bombsite, "A", false) && bombsite != g_BombsiteA)
	{
		Format(BR_msg, sizeof(BR_msg), "%t %t", "Prefix", "PlantA");
		BR_PrintToChat(client, BR_msg);
		
		AcceptEntityInput(g_BombsiteB, "Disable");
	}
	
	EmitSoundToClient(client, SOUND_FILE);
	
	new c4ent = GetPlayerWeaponSlot(client, CS_SLOT_C4);
	
	if (c4ent != INVALID_ENT_REFERENCE)
	{
		CS_DropWeapon(client, c4ent, false);
	}
}

/**
 * Called when a player dies.
 *
 * @param event			Handle to event. This could be INVALID_HANDLE if every plugin hooking 
 *						this event has set the hook mode EventHookMode_PostNoCopy.
 * @param name			String containing the name of the event.
 * @param dontBroadcast	True if event was not broadcast to clients, false otherwise.
 * @noreturn
 * 
 * @eventparam	userid	UserID who died
 * @eventparam	attacker	UserID who killed
 * @eventparam	weapon	String containing name of weapon killer used
 * @eventparam	headshot	Bool: Was this a headshot kill?
 * @eventparam	dominated	Bool: Did killer dominate victim with this kill?
 * @eventparam	revenge	Bool: Did killer get revenge on victim with this kill?
 */
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!GameIsLive)
	{
		return;
	}
	
	// ===================================================================================================================================
	// Figure out who killed who.  If a T killed a CT, mark that T as switchable just in case Ts win the round.
	// ===================================================================================================================================
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!Entity_IsPlayer(attacker))
	{ // attacker is not a valid player
		return;
	}
	
	new ateam = GetClientTeam(attacker); // Get attacker's team	
	new victim = GetClientOfUserId(GetEventInt(event, "userid")); // Get the victim's client index
	new vteam = GetClientTeam(victim); // Get the victim's team
	
	// Ensure attacking team is Terrorist and it's not a team kill or self kill.
	if (ateam != CS_TEAM_T || ateam == vteam || attacker == victim)
	{ // Attacker is either a CT, this was a team kill, or a suicide
		return;
	}
	
	PlayerKilledCT[attacker]++; // Mark attacker (T player) as having killed a CT
	
	PlayerSwitchable[victim] = true; // Mark victim (CT player) as switchable in case the Ts win the round.
	ChangeTeamImmune[victim] = false;
	
	Format(BR_msg, sizeof(BR_msg), "%t", "CTKilled", attacker); // Let the CT know they might get switched.
	BR_PrintToChat(victim, BR_msg);
	
	// This terrorist's first kill, perform first kill tasks
	if (PlayerKilledCT[attacker] == 1) 
	{
		// Notify the player they killed a CT and they will be switched if Ts win
		Format(BR_msg, sizeof(BR_msg), "%t", "KilledCT", victim);
		BR_PrintToChat(attacker, BR_msg);
		
		killers++; // Number of Terrorists who killed the CTs holder
		
		// Mark attacker (T player) as switchable in case Ts win the round.
		PlayerSwitchable[attacker] = true;
		
		// Mark this terrorist as ChangeTeam immune for handling later
		ChangeTeamImmune[attacker] = true;
	}
	else if (PlayerKilledCT[attacker] > 1) // This terrorist's 2nd/3rd kill
	{
		CTKiller = GetClientSerial(attacker); // Mark client serial as the player who killed more than one CT
		
		#if _DEBUG
		Format(dmsg, sizeof(dmsg), "[Event_PlayerDeath] %N a CTkiller [%i] = attacker's serial", attacker, CTKiller);
		DebugMessage(dmsg);
		#endif
	}
}

/**
 * Called when the bomb explodes.
 *
 * @param event			Handle to event. This could be INVALID_HANDLE if every plugin hooking 
 *						this event has set the hook mode EventHookMode_PostNoCopy.
 * @param name			String containing the name of the event.
 * @param dontBroadcast	True if event was not broadcast to clients, false otherwise.
 * @noreturn
 * 
 * @eventparam	userid	UserID of player who planted the bomb
 * @eventparam	site		Bombsite index
 */
public Event_BombExploded(Handle:event, const String:name[], bool:dontBroadcast) {
	// Let's make sure the bomber gets credit for this event and gets switched over to CT if the Terrorists win
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client == 0)
	{
		return;
	}
	
	PlayerKilledCT[client]++;
		
	if (PlayerKilledCT[client] == 1) 
	{
		killers++;
		
		PlayerSwitchable[client] = true;
		
		ChangeTeamImmune[client] = true;
		
		if (killers == 1) // This was the only killer of CTs this round
		{
			CTKiller = GetClientSerial(client);
			
			#if _DEBUG
			Format(dmsg, sizeof(dmsg), "[Event_BombExploded] %N a CTkiller [%i] = attacker's serial", client, CTKiller);
			DebugMessage(dmsg);
			#endif
		}
	}
	else if (PlayerKilledCT[client] > 1) // This player is a CT killer
	{
		CTKiller = GetClientSerial(client);
		
		#if _DEBUG
		Format(dmsg, sizeof(dmsg), "[Event_BombExploded] %N a CTkiller [%i] = attacker's serial", client, CTKiller);
		DebugMessage(dmsg);
		#endif
	}
}

/**
 * Called when the round ends.
 *
 * @param event			Handle to event. This could be INVALID_HANDLE if every plugin hooking 
 *						this event has set the hook mode EventHookMode_PostNoCopy.
 * @param name			String containing the name of the event.
 * @param dontBroadcast	True if event was not broadcast to clients, false otherwise.
 * @noreturn
 * 
 * @eventparam	winner	Byte: Winner team/user index
 * @eventparam	reason	Byte: Reason why team won
 * @eventparam	message	String: End round message.
 */
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	CreateTimer(0.6, Timer_SetScore); // See function for details
	
	if (!GameIsLive)
	{
		return;
	}
	
	#if _DEBUG
	DebugMessage("Event_RoundEnd triggered");
	#endif
	
	// ===================================================================================================================================
	// Figure out what team won and handle appropriately with announcements and team swapping if needed
	// ===================================================================================================================================
	new winner = GetEventInt(event, "winner");
	
	numSwitched = 0;
	
	if (winner == CS_TEAM_T) // Terrorists won, let's reset some stuff
	{
		NeedsCashReset = true;
		
		CreateTimer(0.2, Timer_ProcessTeam); // See function for details
		
		if (fast_round)
		{
			SetConVarInt(fr_restart, fr_time, false, false);
		}
	}
	else // CTs won, let's go to next round.
	{
		CTScore++; // Increase the CT's score by 1
		
		Format(BR_msg, sizeof(BR_msg), "%t", "CTWon");
		BR_PrintToChatAll(BR_msg);
		
		if (CTScore >= 2)
		{
			CreateTimer(0.3, Timer_Announcement); // See function for details
		}
	}
	
	tawpno = 0;
	ctawpno = 0;
}

/**
 * Function for timer that Announces repeat CT wins and T taunts
 * 
 * @param	timer		Handle of timer
 * @noreturn
 */
public Action:Timer_Announcement(Handle:timer) {
	// ===================================================================================================================================
	// Just fun taunting messages to the Terrorists if they keep loosing to the 3 CTs
	// ===================================================================================================================================
	Format(BR_msg, sizeof(BR_msg), "%t", "CTWonAgain", CTScore);
	BR_PrintToChatAll(BR_msg);
	
	switch (CTScore)
	{
		case 3: {
			Format(BR_msg, sizeof(BR_msg), "%t", "TTaunt3");
			BR_PrintToChatAll(BR_msg);
		}
		
		case 4:	{
			Format(BR_msg, sizeof(BR_msg), "%t", "TTaunt4");
			BR_PrintToChatAll(BR_msg);
		}
		
		case 5:	{
			Format(BR_msg, sizeof(BR_msg), "%t", "TTaunt5");
			BR_PrintToChatAll(BR_msg);
		}
		
		case 6:	{
			Format(BR_msg, sizeof(BR_msg), "%t", "TTaunt6");
			BR_PrintToChatAll(BR_msg);
		}
		
		case 7:	{
			Format(BR_msg, sizeof(BR_msg), "%t", "TTaunt7");
			BR_PrintToChatAll(BR_msg);
		}
		
		case 8, 9, 10, 11, 12, 13, 14, 15: {
			// Switch up teams, and if CTs keep winning, keep switching up the teams
			Format(BR_msg, sizeof(BR_msg), "%t", "Scrambling");
			BR_PrintToChatAll(BR_msg);
			
			ScrambleTeams();
		}
	}
}

/**
 * Function for timer when BRush's conditions make it go not live.  Will run until conditions to go live are met or the plugin is disabled
 * 
 * @param	timer		Handle for timer
 * @noreturn
 */
public Action:Timer_CheckLive(Handle:timer) {
	// ===================================================================================================================================
	// Repeating timer to check for team conditions.  Once there are 5 players on Terrorist's team and 3 players on CT's team, the round will go live
	// ===================================================================================================================================
	if (GetTeamClientCount(CS_TEAM_T) == 5 && GetTeamClientCount(CS_TEAM_CT) == 3)
	{
		LiveTimer = INVALID_HANDLE; // Always need to set back to INVALID_HANDLE when the timer has served its purpose
		
		GameIsLive = true; // So Event_RoundFreezeEnd knows it's live
		
		if (UseConfigs)
		{
			ServerCommand("exec brush.live.cfg"); // Since the game is now live, execute the live config file.
		}
		
		new times = 0;
		while (times < 3) // Repeat the announcement 3 times
		{
			Format(BR_msg, sizeof(BR_msg), "%t", "RoundGoingLive");
			BR_PrintToChatAll(BR_msg);
			
			times++;
		}
		
		SetConVarInt(fr_restart, 5, false, false); // Restart the game since now the conditions meet a live match
		
		CTScore = 0; // Reset the score for CTs
		
		return Plugin_Stop; // Stop this repeating timer.
	}
	
	// Conditions haven't been met to live the round for BRUSH, let any spectators know they are needed
	for (new i = 1; i <= MaxClients; i++)
	{	
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			Client_PrintKeyHintText(i, "%t\n\n%t", "Prefix2", "SpecAdvert");
		}
	}
	
	return Plugin_Continue;
}

#if 0
/**
 * Switch the player to the CT team and increment numSwitched
 * 
 * @param	client		client index
 * @noreturn
 */
ProcessT(client) {
	numSwitched++;
	
	SwitchPlayerTeam(client, CS_TEAM_CT);
}
#endif

/**
 * Function to Scramble teams - moves all players to Terrorist's team, then calls SwitchRandom to move 3 to CT
 * 
 * @noreturn
 */
ScrambleTeams() {
	// Move everyone to Terrorist's team
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			SwitchPlayerTeam(i, CS_TEAM_T);
			if (IsPlayerAlive(i))
			{
				BR_RespawnPlayer(i);
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
SwitchRandom() {
	while (numSwitched < 3)
	{
		// Since less than 3 Ts were switched to the CT team, randomly select 1 or 2 more to be switched
		new i = Client_GetRandom(CLIENTFILTER_TEAMONE);
		
		// If player is a valid client index and is not one of the just switched CTs, switch to CT team.
		if (i == -1)
		{
			LogError("ERROR with SwitchRandom, probably harmless");
			break;
		}
		
		if (!ChangeTeamImmune[i])
		{
			//ChangeTeamImmune[i] = true;
			numSwitched++;
			SwitchingPlayer[i] = true;
			SwitchPlayerTeam(i, CS_TEAM_CT);
		}
	}
}

public Action:Timer_MoreTs(Handle:timer, any:serial) {
	new client = GetClientFromSerial(serial);
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	new TeamCount = GetTeamClientCount(CS_TEAM_CT);
	
	if (TeamCount < 3)
	{
		new Handle:menu = CreateMenu(MenuHandler_Teams);
		SetMenuTitle(menu, "%t", "Menu2");
		SetMenuExitButton(menu, true);
		
		AddTerroristsToMenu(menu);
		
		DisplayMenu(menu, client, MenuTime);
	}
	
	return Plugin_Continue;
}

/**
 * Function for timer to process the CT team switching
 * 
 * @param	timer		Handle of timer
 * @param	client		client index
 * @noreturn
 */
public Action:Timer_ProcessCT(Handle:timer, any:serial) {
	new client = GetClientFromSerial(serial);
	
	if (client == 0 || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
	{
		return Plugin_Continue;
	}
	
	ChangeTeamImmune[client] = true;
	SwitchPlayerTeam(client, CS_TEAM_T);
	
	return Plugin_Continue;
}

/**
 * Function for timer Processes the teams when Terrorists win
 * 
 * @param	timer		Handle of timer
 * @noreturn
 */
public Action:Timer_ProcessTeam(Handle:timer) {
	/* ===================================================================================================================================
	ALL CTs get switched to the Terrorist's team.
	
	The Terrorists who killed 1 or more CTs get switched to CT team.
	
	If less than 3 Terrorists killed a CT, the Terrorist who killed 2+ CTs will get a menu to select the player(s) to be switched
	=================================================================================================================================== */
	// Let's drop the bomb prior to player team movement so a CT doesn't end up with the bomb
	if (the_bomb > MaxClients && IsValidEntity(the_bomb))
	{
		new bomb_owner = Weapon_GetOwner(the_bomb);
		
		if (bomb_owner != INVALID_ENT_REFERENCE)
		{
			#if _DEBUG
			Format(dmsg, sizeof(dmsg), "[Timer_ProcessTeam] The bomb owner is %L", bomb_owner);
			DebugMessage(dmsg);
			#endif
			
			CS_DropWeapon(bomb_owner, the_bomb, false);
		}
		else
		{
			#if _DEBUG
			Format(dmsg, sizeof(dmsg), "[Timer_ProcessTeam] There is no bomb owner");
			DebugMessage(dmsg);
			#endif
		}
	}
	else
	{
		#if _DEBUG
		Format(dmsg, sizeof(dmsg), "[Timer_ProcessTeam] Bomb index is %i and might not be a valid entity", the_bomb);
		DebugMessage(dmsg);
		#endif
	}
	
	// Go through each client and process accordingly
	new team;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (IsPlayerAlive(i))
			{
				if (roundend_mode == 2)
				{ // Set god mod on player after round end
					SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
					SetEntityRenderMode(i, RENDER_TRANSALPHA);
					SetEntityRenderColor(i, 255, 255, 255, 100);
				}
				else if (roundend_mode == 1)
				{ // Respawn player after round end
					CreateTimer(0.3, Timer_RespawnPlayer, GetClientSerial(i), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			
			team = GetClientTeam(i);
			
			if (team == CS_TEAM_CT)// && !ChangeTeamImmune[i]) // Switch this CT to the Terrorist's team
			{
				#if _DEBUG
				Format(dmsg, sizeof(dmsg), "[Timer_ProcessTeam] Switching %L to Terrorist", i);
				DebugMessage(dmsg);
				#endif
				
				ChangeTeamImmune[i] = true; // Mark them so they can't be picked to be on the CT team again by the CT Killer
				SwitchingPlayer[i] = true;
				SwitchPlayerTeam(i, CS_TEAM_T);
				//CreateTimer(0.2, Timer_ProcessCT, GetClientSerial(i));
			}
			else if (team == CS_TEAM_T && PlayerSwitchable[i]) // Switch this Terrorist to the CT's team since they got a kill during the round
			{
				#if _DEBUG
				Format(dmsg, sizeof(dmsg), "[Timer_ProcessTeam] Switching %L to CT", i);
				DebugMessage(dmsg);
				#endif
				
				numSwitched++;
				SwitchingPlayer[i] = true;
				SwitchPlayerTeam(i, CS_TEAM_CT);
				//ProcessT(i);
			}
		}
	}
	
	#if _DEBUG
	Format(dmsg, sizeof(dmsg), "[Timer_ProcessTeam] numSwitched value is %i", numSwitched);
	DebugMessage(dmsg);
	#endif
	
	// If less than three Terrorists were switched to CT, we need to process further
	if (numSwitched != 3)
	{
		if (numSwitched == 0) // CTs killed themselves or were slayed... something where Terrorists didn't kill them
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
	//TScore = 0;
	
	// ===================================================================================================================================
	// Let's get the number of players on the Terrorist's team who killed a player (or players) on the CT team, then announce this everyone
	// ===================================================================================================================================
	CreateTimer(0.3, Timer_WhoWon);//, killers);
}

public Action:Timer_ResetPlayerCash(Handle:timer, any:serial) {
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	SetEntData(client, g_iAccount, DefaultStartCash, 4, true);
	
	return Plugin_Continue;
}

public Action:Timer_ResetPlayerWeapons(Handle:timer, any:serial) {
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	Client_RemoveAllWeapons(client, "weapon_knife");
	
	GivePlayerItem(client, (GetClientTeam(client) == CS_TEAM_CT ? CTPistol : TPistol));
	
	return Plugin_Continue;
}

public Action:Timer_RespawnPlayer(Handle:timer, any:serial) {
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	BR_RespawnPlayer(client);
	
	return Plugin_Continue;
}

/**
 * Function for timer that sets the scores
 * 
 * @param	timer		Handle of timer
 * @noreturn
 */
public Action:Timer_SetScore(Handle:timer) {
	if (GameIsLive)
	{
		// Set the team scores
		SetTeamScore(CS_TEAM_CT, CTScore);
		SetTeamScore(CS_TEAM_T, 0);
	}
	else
	{
		// Set the team scores to something fun - pi :)
		SetTeamScore(CS_TEAM_CT, 700);
		SetTeamScore(CS_TEAM_T, 1337);
	}
	
	return Plugin_Continue;
}

public Action:Timer_UnFreezePlayer(Handle:timer, any:serial) {
	new client = GetClientFromSerial(serial);
	
	if (client == 0 || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	FreezePlayer(client, false);
	
	return Plugin_Continue;
}

/**
 * Function for timer that announces the winner of the round
 * 
 * @param	timer		Handle of timer
 * @noreturn
 */
public Action:Timer_WhoWon(Handle:timer) {
	Format(BR_msg, sizeof(BR_msg), "%t", "TWon", killers);
	BR_PrintToChatAll(BR_msg);
	
	return Plugin_Continue;
}

/**
 * Called when a player attempts to purchase an item.
 * Return Plugin_Continue to allow the purchase or return a
 * higher action to deny.
 *
 * @param client		Client index
 * @param weapon	User input for weapon name
 */
public Action:CS_OnBuyCommand(client, const String:weapon[]) {
	if (!UseWeaponRestrict || !GameIsLive || !Enabled)
	{
		return Plugin_Continue;
	}
	
	// ===================================================================================================================================
	// Check if weapon being purchased is a flashbang, smoke grenade, or hegrenade, and restrict the purchase if those are prohibited
	// ===================================================================================================================================
	if ((StrContains(weapon, "flashbang", false) != -1 && !AllowFlashBangs) || 
		(StrContains(weapon, "smokegrenade", false) != -1 && !AllowSmokes) || 
		(StrContains(weapon, "hegrenade", false) != -1 && !AllowHEGrenades))
	{
		Format(BR_msg, sizeof(BR_msg), "%t %t", "Prefix", "NoNade");
		BR_PrintToChat(client, BR_msg);
		//BR_PrintToChat(client, "%t %t", "Prefix", "NoNade");
		EmitSoundToClient(client, SOUND_FILE);
		return Plugin_Handled;
	}
	
	// ===================================================================================================================================
	// Check if the weapon being purchased is an AWP or Auto and restrict the purchase if it is prohibited
	// ===================================================================================================================================
	if (StrContains(weapon, "awp", false) != -1 || StrContains(weapon, "g3sg1", false) != -1 || StrContains(weapon, "sg550", false) != -1)
	{
		new team = GetClientTeam(client);
		
		switch(team)
		{
			case CS_TEAM_T: { tawpno++; }
			
			case CS_TEAM_CT: { ctawpno++; }
		}
		
		// ===================================================================================================================================
		// Weapon being purchased is an AWP/Auto, let's see if the team the player's on is allowed to buy AWPS/Autos
		// If not, do not allow the purchase.
		// ===================================================================================================================================
		if ((team == CS_TEAM_T && TAwps) || (team == CS_TEAM_CT && CTAwps))
		{
			// ===================================================================================================================================
			// If the player's team already has its AWP limit, then this player cannot purchase it
			// Otherwise, allow the purchase as long as the players has the money for it
			// ===================================================================================================================================
			if ((team == CS_TEAM_CT && ctawpno > CTAwpNumber) || (team == CS_TEAM_T && tawpno > TAwpNumber))
			{
				Format(BR_msg, sizeof(BR_msg), "%t %t", "Prefix", "NoSniper");
				BR_PrintToChat(client, BR_msg);
				EmitSoundToClient(client, SOUND_FILE);
				return Plugin_Handled;
			}
		}
		else
		{
			Format(BR_msg, sizeof(BR_msg), "%t %t", "Prefix", "NoSniper");
			BR_PrintToChat(client, BR_msg);
			EmitSoundToClient(client, SOUND_FILE);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

/**
 * Reset all client variables (ChangeTeamImmune, PlayerSwitchable, PlayerKilledCT, SwitchingPlayer, and unfreezes the player
 * 
 * @param	client	Client to reset variables for
 * @noreturn
 */
ResetClientVariables(client) {
	PlayerSwitchable[client] = false;
	PlayerKilledCT[client] = 0;
	SwitchingPlayer[client] = false;
	FreezePlayer(client, false);
}

/* ===================================================================================================================================
    SMLib Functions (thanks berni)
	* https://forums.alliedmods.net/showthread.php?t=148387
    =================================================================================================================================== */
/**
 * Returns the client counts of the first two teams (eg.: Terrorists - Counter).
 * Use this function for optimization if you have to get the counts of both teams,
 * otherwise use Team_GetClientCount().
 *
 * @param team1					Pass an integer variable by reference
 * @param team2					Pass an integer variable by reference
 * @param flags					Client Filter Flags (Use the CLIENTFILTER_ constants).
 * @noreturn
 */
Team_GetClientCounts(&team1=0, &team2=0, flags=0) {
	flags |= CLIENTFILTER_INGAME;
	
	for (new client=1; client <= MaxClients; client++)
	{
		
		if (!Client_MatchesFilter(client, flags))
		{
			continue;
		}
		
		if (GetClientTeam(client) == TEAM_ONE)
		{
			team1++;
		}
		else if (GetClientTeam(client) == TEAM_TWO)
		{
			team2++;
		}
	}
}

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
bool:Client_PrintKeyHintText(client, const String:format[], any:...) {
	new Handle:userMessage = StartMessageOne("KeyHintText", client);
	
	if (userMessage == INVALID_HANDLE)
	{
		return false;
	}
	
	new String:buffer[254];

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
 * Gets the owner (usually a client) of the weapon
 * 
 * @param weapon		Weapon Entity.
 * @return				Owner of the weapon or INVALID_ENT_REFERENCE if the weapon has no owner.
 */
Weapon_GetOwner(weapon) {
	return GetEntPropEnt(weapon, Prop_Data, "m_hOwner");
}

/**
 * Gets a random client matching the specified flags filter.
 *
 * @param flags			Client Filter Flags (Use the CLIENTFILTER_ constants).
 * @return				Client Index or -1 if no client was found
 */
Client_GetRandom(flags=CLIENTFILTER_ALL) {
	decl clients[MaxClients];
	new num = Client_Get(clients, flags);
	
	if (num == 0)
	{
		return -1;
	}
	else if (num == 1)
	{
		return clients[0];
	}
	
	new random = Math_GetRandomInt(0, num-1);
	
	return clients[random];
}

/**
 * Gets all clients matching the specified flags filter.
 *
 * @param client		Client Array, size should be MaxClients or MAXPLAYERS
 * @param flags			Client Filter Flags (Use the CLIENTFILTER_ constants).
 * @return				The number of clients stored in the array
 */
Client_Get(clients[], flags=CLIENTFILTER_ALL) {
	new x=0;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!Client_MatchesFilter(client, flags))
		{
			continue;
		}
		
		clients[x++] = client;
	}

	return x;
}


/**
 * Returns a random, uniform Integer number in the specified (inclusive) range.
 * This is safe to use multiple times in a function.
 * The seed is set automatically for each plugin.
 * Rewritten by MatthiasVance, thanks.
 * 
 * @param min			Min value used as lower border
 * @param max			Max value used as upper border
 * @return				Random Integer number between min and max
 */
Math_GetRandomInt(min, max) {
	new random = GetURandomInt();
	
	if (random == 0)
	{
		random++;
	}

	return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}


/**
 * Checks if a client matches the specified flag filter.
 * Use one of the CLIENTFILTER_ constants.
 * Note that this already checks if the client is ingame or connected
 * so you don't have to do that yourself.
 * This function is optimized to make as less native calls as possible :)
 *
 * @param Client		Client Index.
 * @param flags			Client Filter Flags (Use the CLIENTFILTER_ constants).
 * @return				True if the client if the client matches, false otherwise.
 */
bool:Client_MatchesFilter(client, flags) {
	new bool:isIngame = false;
	
	if (flags >= CLIENTFILTER_INGAME)
	{
		isIngame = IsClientInGame(client);
		
		if (isIngame)
		{
			if (flags & CLIENTFILTER_NOTINGAME)
			{
				return false;
			}
		}
		else
		{
			return false;
		}
	}
	else if (!IsClientConnected(client))
	{
		return false;
	}
	
	if (!flags)
	{
		return true;
	}
	
	if (flags & CLIENTFILTER_INGAMEAUTH)
	{
		flags |= CLIENTFILTER_INGAME | CLIENTFILTER_AUTHORIZED;
	}
	
	if (flags & CLIENTFILTER_BOTS && !IsFakeClient(client))
	{
		return false;
	}
	
	if (flags & CLIENTFILTER_NOBOTS && IsFakeClient(client))
	{
		return false;
	}
	
	if (flags & CLIENTFILTER_ADMINS && !Client_IsAdmin(client))
	{
		return false;
	}
	
	if (flags & CLIENTFILTER_NOADMINS && Client_IsAdmin(client))
	{
		return false;
	}
	
	if (flags & CLIENTFILTER_AUTHORIZED && !IsClientAuthorized(client))
	{
		return false;
	}
	
	if (flags & CLIENTFILTER_NOTAUTHORIZED && IsClientAuthorized(client))
	{
		return false;
	}

	if (isIngame)
	{
		if (flags & CLIENTFILTER_ALIVE && !IsPlayerAlive(client))
		{
			return false;
		}
		
		if (flags & CLIENTFILTER_DEAD && IsPlayerAlive(client))
		{
			return false;
		}
		
		if (flags & CLIENTFILTER_SPECTATORS && GetClientTeam(client) != TEAM_SPECTATOR)
		{
			return false;
		}
		
		if (flags & CLIENTFILTER_NOSPECTATORS && GetClientTeam(client) == TEAM_SPECTATOR)
		{
			return false;
		}
		
		if (flags & CLIENTFILTER_OBSERVERS && !IsClientObserver(client))
		{
			return false;
		}
		
		if (flags & CLIENTFILTER_NOOBSERVERS && IsClientObserver(client))
		{
			return false;
		}
		
		if (flags & CLIENTFILTER_TEAMONE && GetClientTeam(client) != TEAM_ONE)
		{
			return false;
		}
		
		if (flags & CLIENTFILTER_TEAMTWO && GetClientTeam(client) != TEAM_TWO)
		{
			return false;
		}
	}
	
	return true;
}

/**
 * Checks whether the client is a generic admin.
 *
 * @param				Client Index.
 * @return				True if the client is a generic admin, false otheriwse.
 */
bool:Client_IsAdmin(client) {
	new AdminId:adminId = GetUserAdmin(client);
	
	if (adminId == INVALID_ADMIN_ID)
	{
		return false;
	}
	
	return GetAdminFlag(adminId, Admin_Generic);
}

/**
 * Gets the offset for a client's weapon list (m_hMyWeapons).
 * The offset will saved globally for optimization.
 *
 * @param client		Client Index.
 * @return				Weapon list offset or -1 on failure.
 */
Client_GetWeaponsOffset(client)
{
	static offset = -1;

	if (offset == -1) {
		offset = FindDataMapOffs(client, "m_hMyWeapons");
	}
	
	return offset;
}

/**
 * Checks whether the entity is a valid weapon or not.
 * 
 * @param weapon		Weapon Entity.
 * @return				True if the entity is a valid weapon, false otherwise.
 */
bool:Weapon_IsValid(weapon)
{
	if (!IsValidEdict(weapon)) {
		return false;
	}
	
	return Entity_ClassNameMatches(weapon, "weapon_", true);
}

/**
 * Removes all weapons of a client.
 * You can specify a weapon it shouldn't remove and if to
 * clear the player's ammo for a weapon when it gets removed.
 *
 * @param client 		Client Index.
 * @param exclude		If not empty, this weapon won't be removed from the client.
 * @return				Number of removed weapons.
 */
Client_RemoveAllWeapons(client, const String:exclude[]="")
{
	new offset = Client_GetWeaponsOffset(client) - 4;
	
	new numWeaponsRemoved = 0;
	for (new i = 0; i < MAX_WEAPONS; i++)
	{
		offset += 4;
		
		new weapon = GetEntDataEnt2(client, offset);
		
		if (!Weapon_IsValid(weapon))
		{
			continue;
		}
		
		if (exclude[0] != '\0' && Entity_ClassNameMatches(weapon, exclude))
		{
			Client_SetActiveWeapon(client, weapon);
			continue;
		}
		
		if (RemovePlayerItem(client, weapon))
		{
			Entity_Kill(weapon);
		}
		
		numWeaponsRemoved++;
	}
	
	return numWeaponsRemoved;
}

/**
 * Kills an entity on the next frame (delayed).
 * It is safe to use with entity loops.
 * If the entity is is player ForcePlayerSuicide() is called.
 *
 * @param kenny			Entity index.
 * @param killChildren	When true, kennys children are killed too.
 * @return 				True on success, false otherwise.
 */
bool:Entity_Kill(kenny, killChildren=false)
{
	if (Entity_IsPlayer(kenny))
	{
		// Oh My God! They Killed Kenny!!
		ForcePlayerSuicide(kenny);
		return true;
	}
	
	if (killChildren)
	{
		return AcceptEntityInput(kenny, "KillHierarchy");
	}
	else
	{
		return AcceptEntityInput(kenny, "Kill");
	}
}

/**
 * Checks if an entity is a player or not.
 * No checks are done if the entity is actually valid,
 * the player is connected or ingame.
 *
 * @param entity			Entity index.
 * @return 				True if the entity is a player, false otherwise.
 */
bool:Entity_IsPlayer(entity)
{
	if (1 <= entity <= MaxClients)
	{
		return true;
	}
	
	return false;
}

/**
 * Changes the active/current weapon of a player by Index.
 * Note: No changing animation will be played !
 *
 * @param client		Client Index.
 * @param weapon		Index of a valid weapon.
 * @noreturn
 */
Client_SetActiveWeapon(client, weapon)
{
	SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", weapon);
	ChangeEdictState(client, FindDataMapOffs(client, "m_hActiveWeapon"));
}

/**
 * Checks if an entity (partially) matches a specific entity class.
 *
 * @param entity		Entity Index.
 * @param className		Classname String.
 * @partialMatch		If to do a partial classname check.
 * @return				True if the classname matches, false otherwise.
 */
bool:Entity_ClassNameMatches(entity, const String:className[], partialMatch=false)
{
	new String:entity_className[64];
	Entity_GetClassName(entity, entity_className, sizeof(entity_className));

	if (partialMatch)
	{
		return (StrContains(entity_className, className) != -1);
	}

	return StrEqual(entity_className, className);
}

/**
 * Gets the Classname of an entity.
 * This is like GetEdictClassname(), except it works for ALL
 * entities, not just edicts.
 *
 * @param entity			Entity index.
 * @param buffer			Return/Output buffer.
 * @param size				Max size of buffer.
 * @return					Number of non-null bytes written.
 */
Entity_GetClassName(entity, String:buffer[], size)
{
	return GetEntPropString(entity, Prop_Data, "m_iClassname", buffer, size);	
}

// ===================================================================================================================================
// Thanks to exvel - http://forums.alliedmods.net/showthread.php?p=1287116
// Provided the GetBombsitesIndexes() and stock bool:IsVecBetween
// ===================================================================================================================================
GetBomsitesIndexes() {
	new index = -1;
	
	index = FindEntityByClassname(index, "cs_player_manager");
	
	#if _DEBUG
	Format(dmsg, sizeof(dmsg), "[GetBombSiteIndexes] cs_player_manager index = %i (shouldn't be -1)", index);
	DebugMessage(dmsg);
	#endif
	
	if (index != -1)
	{
		GetEntPropVector(index, Prop_Send, "m_bombsiteCenterA", vecBombsiteCenterA);
		GetEntPropVector(index, Prop_Send, "m_bombsiteCenterB", vecBombsiteCenterB);
		
		#if _DEBUG
		Format(dmsg, sizeof(dmsg), "[GetBombSiteIndexes] m_bombsiteCenterA vec = %f %f %f m_bombsiteCenterB vec = %f %f %f", vecBombsiteCenterA[0], vecBombsiteCenterA[1], vecBombsiteCenterA[2], vecBombsiteCenterB[0], vecBombsiteCenterB[1], vecBombsiteCenterB[2]);
		DebugMessage(dmsg);
		#endif
	}
	
	index = -1;
	
	#if _DEBUG
	Format(dmsg, sizeof(dmsg), "[GetBombSiteIndexes] func_bomb_target index = %i (shouldn't be -1)", FindEntityByClassname(index, "func_bomb_target"));
	DebugMessage(dmsg);
	#endif
	
	while ((index = FindEntityByClassname(index, "func_bomb_target")) != -1)
	{
		new Float:vecBombsiteMin[3];
		new Float:vecBombsiteMax[3];
		
		GetEntPropVector(index, Prop_Send, "m_vecMins", vecBombsiteMin);
		GetEntPropVector(index, Prop_Send, "m_vecMaxs", vecBombsiteMax);
		
		#if _DEBUG
		Format(dmsg, sizeof(dmsg), "[GetBombSiteIndexes] vecBombsiteMin vec = %f %f %f vecBombsiteMax vec = %f %f %f", vecBombsiteMin[0], vecBombsiteMin[1], vecBombsiteMin[2], vecBombsiteMax[0], vecBombsiteMax[1], vecBombsiteMax[2]);
		DebugMessage(dmsg);
		#endif
		
		if (IsVecBetween(vecBombsiteCenterA, vecBombsiteMin, vecBombsiteMax))
		{
			g_BombsiteA = index;
		}
		
		if (IsVecBetween(vecBombsiteCenterB, vecBombsiteMin, vecBombsiteMax))
		{
			g_BombsiteB = index;
		}
	}
	
	#if _DEBUG
	Format(dmsg, sizeof(dmsg), "[GetBombSiteIndexes] Indexes are: a=%i, b=%i", g_BombsiteA, g_BombsiteB);
	DebugMessage(dmsg);
	#endif
	
	if (UseBombsiteDisable)
	{
		if (StrEqual(s_bombsite, "A", false))
		{
			if (IsValidEntity(g_BombsiteB))
			{
				AcceptEntityInput(g_BombsiteB, "Disable");
			}
			else
			{
				#if _DEBUG
				Format(dmsg, sizeof(dmsg), "[GetBombSiteIndexes] g_BombsiteB [%i] is not valid", g_BombsiteB);
				DebugMessage(dmsg);
				#endif
			}
		}
		else if (StrEqual(s_bombsite, "B", false))
		{
			if (IsValidEntity(g_BombsiteA))
			{
				AcceptEntityInput(g_BombsiteA, "Disable");
			}
			else
			{
				#if _DEBUG
				Format(dmsg, sizeof(dmsg), "[GetBombSiteIndexes] g_BombsiteA [%i] is not valid", g_BombsiteA);
				DebugMessage(dmsg);
				#endif
			}
		}
	}
}

bool:IsVecBetween(const Float:vecVector[3], const Float:vecMin[3], const Float:vecMax[3]) {
	return ( (vecMin[0] <= vecVector[0] <= vecMax[0]) && 
			 (vecMin[1] <= vecVector[1] <= vecMax[1]) && 
			 (vecMin[2] <= vecVector[2] <= vecMax[2]) );
}

// ===================================================================================================================================
// Menu Functions
// ===================================================================================================================================
public DisplayMenuToCTKiller() {
	new client = GetClientFromSerial(CTKiller);
	
	if (1 <= client <= MaxClients && !IsFakeClient(client))
	{
		#if _DEBUG
		Format(dmsg, sizeof(dmsg), "[DisplayMenuToCTKiller] %L is the CT killer and is being shown the menu", client);
		DebugMessage(dmsg);
		#endif
		
		new Handle:menu = CreateMenu(MenuHandler_Teams);
		SetMenuTitle(menu, "%t", "Menu1");
		SetMenuExitButton(menu, true);
		
		AddTerroristsToMenu(menu);
		
		// Display the team selection menu to the player who killed more than 1 CT
		DisplayMenu(menu, client, MenuTime);
	}
	else
	{
		SwitchRandom();
	}
}

public MenuHandler_Teams(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info)); // param2 is the UserID of the selected player
		
		//new UserID = StringToInt(info);
		new client = GetClientOfUserId(StringToInt(info));
		
		if (client > 0)
		{
			if (GetTeamClientCount(CS_TEAM_CT) < 3)
			{
				numSwitched++;
				SwitchPlayerTeam(client, CS_TEAM_CT);
				
				if (IsPlayerAlive(client))
				{
					BR_RespawnPlayer(client);
				}
			}
			else
			{
				Format(BR_msg, sizeof(BR_msg), "%t", "TooLate");
				BR_PrintToChat(client, BR_msg);
			}
		}
		
		CreateTimer(0.2, Timer_MoreTs, GetClientSerial(param1));
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

/**
 * This will populate the menu with names of the terrorists available to be switched
 * @noreturn
 */
public AddTerroristsToMenu(Handle:menu) {
	new String:user_id[12]; 
	new String:name[MAX_NAME_LENGTH];
	new String:display[MAX_NAME_LENGTH+15];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && !ChangeTeamImmune[i])
		{
			IntToString(GetClientUserId(i), user_id, sizeof(user_id));
			
			GetClientName(i, name, sizeof(name));
			
			Format(display, sizeof(display), "%s (%s)", name, user_id);
			
			AddMenuItem(menu, user_id, display);
		}
	}
}

/** 
 * This will freeze players if the game is configured to do that
 * @noreturn
 */
ApplyPlayerFreeze() {
	new player_team, Float:ftime;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
		{
			player_team = GetClientTeam(i);
			
			(player_team == CS_TEAM_T) ? (ftime = TFreezeTime) : (ftime = CTFreezeTime);
			
			if (ftime != 0.0)
			{
				FreezePlayer(i, true);
				CreateTimer(ftime, Timer_UnFreezePlayer, GetClientSerial(i));
				
				Format(BR_msg, sizeof(BR_msg), "%t", "Frozen", TFreezeTime);
				BR_PrintToChat(i, BR_msg);
			}
		}
	}
}

/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags. (from morecolors.inc)
 * 
 * @param client		Client index.
 * @param message		Message (formatting rules).
 * @noreturn
 * 
 * On error/Errors:		If the client is not connected an error will be thrown.
 */
BR_PrintToChat(client, String:buffer[], any:...) {
	if (!IsValidPlayer(client) || IsFakeClient(client))
	{
		return;
	}
	
	//if (IsCSGO && StripColorsForCSGO)
	//{
	//	CRemoveTags(buffer, MAX_MESSAGE_LENGTH);
	//}
	
	#if _DEBUG // Log the actual message, with code and all
	Format(dmsg, sizeof(dmsg), "%s", buffer);
	DebugMessage(dmsg);
	#endif
	
	CPrintToChat(client, buffer);
}

/**
 * Prints a message to all clients in the chat area.
 * Supports color tags. (from morecolors.inc)
 * 
 * @param client		Client index.
 * @param message		Message (formatting rules).
 * @noreturn
 */
BR_PrintToChatAll(String:buffer[], any:...) {
	//if (IsCSGO)
	//{
	//	CRemoveTags(buffer, MAX_MESSAGE_LENGTH);
	//}
	
	#if _DEBUG // Log the actual message, with code and all
	Format(dmsg, sizeof(dmsg), "%s", buffer);
	DebugMessage(dmsg);
	#endif
	
	CPrintToChatAll(buffer);
}

/**
 * Check if a clientID is a valid player or not
 * 
 * @param	client	ClientID to check
 * @return	True if ClientID is a valid player, false otherwise
 */
bool:IsValidPlayer(client) {
	if (!Entity_IsPlayer(client) || !IsClientConnected(client))
	{
		return false;
	}
	
	return IsClientInGame(client);
}

/**
 * Function to handle un/freezing of a player
 * 
 * @param	client	ClientID of player to un/freeze
 * @param	freeze	True to freeze, false to unfreeze
 * @noreturn
 */
FreezePlayer(client, bool:freeze) {
	if (IsValidEntity(client))
	{
		if (freeze)
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
			SetEntityRenderColor(client, 0, 128, 255, 192);
			IsPlayerFrozen[client] = true;
			
			return;
		}
		
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		IsPlayerFrozen[client] = false;
	}
}

/**
 * Respawns a player after marking them SwitchingPlayer
 * @param	client	PlayerID to use
 * @noreturn
 */
BR_RespawnPlayer(client) {
	SwitchingPlayer[client] = true;
	CS_RespawnPlayer(client);
	SwitchingPlayer[client] = false;
}

/**
 * Function to clear/kill the timer and set to INVALID_HANDLE if it's still active
 * 
 * @param	timer		Handle of the timer
 * @noreturn
 */
ClearTimer(&Handle:timer) {
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}     
}

SetAppend(&appended) {
	if (AutoExecConfig_GetAppendResult() == AUTOEXEC_APPEND_SUCCESS)
	{
		appended = true;
	}
}

#if _DEBUG 
DebugMessage(const String:msg[], any:...) {
	LogMessage("%s (at frame [%i])", msg, GetGameTickCount());
	#if _DEBUG_CHAT
	PrintToChatAll("[BRush DEBUG] %s (at frame [%i])", msg, GetGameTickCount());
	#endif
}
#endif

// ===================================================================================================================================
// CVar Change Functions
// ===================================================================================================================================
public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	// Make sure the version number is what is set in the compiled plugin, not a config file or changed CVar
	if (!StrEqual(newVal, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnUseUpdaterChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	UseUpdater = GetConVarBool(cvar);
}

public OnUseWeaponRestrictChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	UseWeaponRestrict = GetConVarBool(cvar);
}

public OnHEGrenadesChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	AllowHEGrenades = GetConVarBool(cvar);
}

public OnFlashBangsChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	AllowFlashBangs = GetConVarBool(cvar);
}

public OnSmokesChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	AllowSmokes = GetConVarBool(cvar);
}

public OnCTAwpsChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	CTAwps = GetConVarBool(cvar);
}

public OnCTAwpNumberChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	CTAwpNumber = GetConVarInt(cvar);
}

public OnTAwpsChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	TAwps = GetConVarBool(cvar);
}

public OnTAwpNumberChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	TAwpNumber = GetConVarInt(cvar);
}

public OnFreezeTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	FreezeTime = GetConVarInt(cvar);
	MenuTime = (3 + FreezeTime) / 2;
}

public OnEnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (StrEqual(newVal, "1"))
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
		AddCommandListener(Command_JoinClass, "joinclass");
		
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
		RemoveCommandListener(Command_JoinClass, "joinclass");
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				ChangeTeamImmune[i] = false;
				PlayerSwitchable[i] = false;
				PlayerKilledCT[i] = 0;
				SwitchingPlayer[i] = false;
			}
		}
		
		Enabled = false;
		
		ClearTimer(LiveTimer);
	}
}

public OnManageBotsChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	ManageBots = GetConVarBool(cvar);
	
	new Handle:g_hBotQuotaMode = FindConVar("bot_quota_mode");
	new Handle:g_hBotQuota = FindConVar("bot_quota");
	
	if (ManageBots)
	{
		SetConVarString(g_hBotQuotaMode, "fill");
		SetConVarInt(g_hBotQuota, 8);
	}
	else
	{
		SetConVarString(g_hBotQuotaMode, g_sOrgBotQuotaMode);
		SetConVarInt(g_hBotQuota, g_iOrgBotQuota);
	}
	
	CloseHandle(g_hBotQuotaMode);
	CloseHandle(g_hBotQuota);
}

//public OnBotQuotaChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
//	bot_quota = GetConVarInt(cvar);
//}

/*
public OnBotQuotaModeChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (ManageBots)
	{
		SetConVarString(cvar, "normal");
	}
}
*/

public OnUseConfigsChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	UseConfigs = GetConVarBool(cvar);
}

public OnCTFreezeTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	CTFreezeTime = GetConVarFloat(cvar);
}

public OnTFreezeTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	TFreezeTime = GetConVarFloat(cvar);
}

public OnRoundEndModeChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	roundend_mode = GetConVarInt(cvar);
}

public OnBombsiteChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	s_bombsite[0] = '\0';
	GetConVarString(cvar, s_bombsite, sizeof(s_bombsite));
	
	new site = 0;
	if (strcmp(s_bombsite, "A", false) == 0)
	{
		site = 1;
	}
	else if (strcmp(s_bombsite, "B", false) == 0)
	{
		site = 2;
	}
	
	if (site != 0 && IsValidEntity(g_BombsiteA) && IsValidEntity(g_BombsiteB))
	{
		AcceptEntityInput((site == 1 ? g_BombsiteA : g_BombsiteB), "Enable");
		AcceptEntityInput((site == 1 ? g_BombsiteB : g_BombsiteA), "Disable");
		
		LogMessage("sm_brush_bombsite changed from [%s] to [%s], bomb site A [%i] is \"%s\" and bomb site B [%i] is \"%s\"", oldVal, newVal, g_BombsiteA, (site == 1 ? "Enabled" : "Disabled"), g_BombsiteB, (site == 1 ? "Disabled" : "Enabled"));
	}
	else
	{
		LogError("sm_brush_bombsite changed from [%s] to [%s], g_BombsiteA is [%i], and g_BombsiteB is [%i]", oldVal, newVal, g_BombsiteA, g_BombsiteB);
	}
}

public OnFastRoundChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	fast_round = GetConVarBool(cvar);
}

public OnFastRoundTimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	fr_time = GetConVarInt(cvar);
}

public OnResetCashChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	ResetPlayerCash = GetConVarBool(cvar);
}

public OnResetWeaponsChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	ResetPlayerWeapons = GetConVarBool(cvar);
}

public OnUseBombsiteDisableChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	UseBombsiteDisable = GetConVarBool(cvar);
}

public OnResetCTPistolChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	GetConVarString(cvar, CTPistol, sizeof(CTPistol));
}

public OnResetTPistolChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	GetConVarString(cvar, TPistol, sizeof(TPistol));
}