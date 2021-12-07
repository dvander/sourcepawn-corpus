/*	TF2 Jailbreak by Jack of Designs!
	Goal of this plugin: Offer a TF2 Jailbreak experience and make TF2 Jailbreak a thing. I'm expecting to see hundreds of servers by at least 3-4 months after I release this! Make it happen people!
	
	The licensing for this plugin is similar to Sourcemod but there's two things I'd like to ask in a sincere way:
		- If you make any changes to this plugin, tell me. I'd like to update this for everyone to use. If you have updates you think should happen, fork this plugin on Github and push it to me to look at.
		- If you can help it, attempt to use the Natives I offer to create sub modules as plugins. I can make new natives if you need them so just give me a buzz.
	Other than that, if you need to edit the plugin, go right ahead, I don't mind.
	
	
	Do you like my work? Donate to me on my site below or use the link on the side:	http://www.jackofdesigns.com/blog/
		- Every penny counts since I like to eat food so anything is appreciated! If you donate $10000, I will personally come to your house and share a nice glass of Orange Juice with you!
		
	The list of credits for the plugin will be on the Github Wiki, I want them in one central place so check them out there. There's a lot of people since I generally looked at code made up by them and saw new methods that actually made my life easier.
	
	Also, I'd like to thank The Outpost Community for giving me a ground to step in in terms of a server to test things on and start the plugin on, I wouldn't have been able to do it without them.
*/

#pragma semicolon 1	//Based on C languages, we like to use semicolons in our code.

//Includes, not entirely convinced that #tryinclude is needed since our plugin doesn't use them as requirements but it's fine.
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <smlib>
#undef REQUIRE_EXTENSIONS
#tryinclude <clientprefs>
#tryinclude <tf2items>
#tryinclude <steamtools>
#undef REQUIRE_PLUGIN
#tryinclude <sourcebans>
#tryinclude <adminmenu>
#tryinclude <updater>
#tryinclude <tf2attributes>
#tryinclude <sourcecomms>
#tryinclude <basecomm>
#tryinclude <basebans>
#tryinclude <betherobot>
#tryinclude <voiceannounce_ex>
#tryinclude <filesmanagementinterface>

//Defines so we don't have to edit code manually for simple stuff.
#define PLUGIN_NAME     "[TF2] Jailbreak"
#define PLUGIN_AUTHOR   "Keith Warren(Jack of Designs)"
#define PLUGIN_VERSION  "4.8.6"
#define PLUGIN_DESCRIPTION	"Jailbreak for Team Fortress 2."
#define PLUGIN_CONTACT  "http://www.jackofdesigns.com/"

#define CLAN_TAG_COLOR	"{community}[TF2Jail]"
#define CLAN_TAG		"[TF2Jail]"

//Cvar handles
new Handle:JB_Cvar_Version = INVALID_HANDLE;
new Handle:JB_Cvar_Enabled = INVALID_HANDLE;
new Handle:JB_Cvar_Advertise = INVALID_HANDLE;
new Handle:JB_Cvar_Cvars = INVALID_HANDLE;
new Handle:JB_Cvar_Balance = INVALID_HANDLE;
new Handle:JB_Cvar_BalanceRatio = INVALID_HANDLE;
new Handle:JB_Cvar_RedMelee = INVALID_HANDLE;
new Handle:JB_Cvar_Warden = INVALID_HANDLE;
new Handle:JB_Cvar_WardenModel = INVALID_HANDLE;
new Handle:JB_Cvar_WardenColor = INVALID_HANDLE;
new Handle:JB_Cvar_Doorcontrol = INVALID_HANDLE;
new Handle:JB_Cvar_DoorOpenTime = INVALID_HANDLE;
new Handle:JB_Cvar_RedMute = INVALID_HANDLE;
new Handle:JB_Cvar_RedMuteTime = INVALID_HANDLE;
new Handle:JB_Cvar_MicCheck = INVALID_HANDLE;
new Handle:JB_Cvar_Rebels = INVALID_HANDLE;
new Handle:JB_Cvar_RebelColor = INVALID_HANDLE;
new Handle:JB_Cvar_RebelsTime = INVALID_HANDLE;
new Handle:JB_Cvar_Crits = INVALID_HANDLE;
new Handle:JB_Cvar_VoteNeeded = INVALID_HANDLE;
new Handle:JB_Cvar_VoteMinPlayers = INVALID_HANDLE;
new Handle:JB_Cvar_VotePostAction = INVALID_HANDLE;
new Handle:JB_Cvar_Freekillers = INVALID_HANDLE;
new Handle:JB_Cvar_Freekillers_Time = INVALID_HANDLE;
new Handle:JB_Cvar_Freekillers_Kills = INVALID_HANDLE;
new Handle:JB_Cvar_Freekillers_Wave = INVALID_HANDLE;
new Handle:JB_Cvar_Freekillers_Action = INVALID_HANDLE;
new Handle:JB_Cvar_Freekillers_BanMSG = INVALID_HANDLE;
new Handle:JB_Cvar_Freekillers_BanMSGDC = INVALID_HANDLE;
new Handle:JB_Cvar_Freekillers_Bantime = INVALID_HANDLE;
new Handle:JB_Cvar_Freekillers_BantimeDC = INVALID_HANDLE;
new Handle:JB_Cvar_LRS_Enabled = INVALID_HANDLE;
new Handle:JB_Cvar_FreedayColor = INVALID_HANDLE;
new Handle:JB_Cvar_VotePassedLimit = INVALID_HANDLE;
new Handle:JB_Cvar_BlueMute = INVALID_HANDLE;

//Array to save our clients for the anti-freekill system.
new Handle:g_hArray_Pending = INVALID_HANDLE;

//Handles the forwards for our natives involving Warden.
new Handle:g_fward_onBecome = INVALID_HANDLE;
new Handle:g_fward_onRemove = INVALID_HANDLE;

//Handles for the advertising timer and the cvar changes.
new Handle:g_adverttimer = INVALID_HANDLE;
new Handle:Cvar_FF = INVALID_HANDLE;
new Handle:Cvar_COL = INVALID_HANDLE;

//Cvar settings saved here so we can have default values.
new bool:j_Enabled = true;
new bool:j_Advertise = true;
new bool:j_Cvars = true;
new bool:j_Balance = true;
new Float:j_BalanceRatio = 0.5;
new bool:j_RedMelee = true;
new bool:j_Warden = false;
new bool:j_WardenModel = true;
new gWardenColor[3];
new bool:j_DoorControl = true;
new Float:j_DoorOpenTimer = 60.0;
new j_RedMute = 2;
new Float:j_RedMuteTime = 15.0;
new bool:j_MicCheck = true;
new bool:j_Rebels = true;
new gRebelColor[3];
new Float:j_RebelsTime = 30.0;
new j_Criticals = 1;
new Float:j_WVotesNeeded = 0.60;
new j_WVotesMinPlayers = 0;
new j_WVotesPostAction = 0;
new bool:j_Freekillers = true;
new Float:j_FreekillersTime = 6.0;
new j_FreekillersKills = 6;
new Float:j_FreekillersWave = 60.0;
new j_FreekillersAction = 2;
new j_FreekillersBantime = 60;
new j_FreekillersBantimeDC = 120;
new bool:j_LRSEnabled = true;
new gFreedayColor[3];
new j_WVotesPassedLimit = 3;
new j_BlueMute = 2;

//Bools setup for different extensions and plugins, the goal is to make this plugin as customizable and functional as possible.
new bool:e_sdkhooks;
new bool:e_tf2items;
new bool:e_clientprefs;
new bool:e_tf2attributes;
new bool:e_sourcecomms;
new bool:e_basecomm;
new bool:e_basebans;
new bool:e_betherobot;
new bool:e_voiceannounce_ex;
new bool:e_filemanager;
new bool:e_sourcebans;
new bool:steamtools = false;

//Global bools for the plugin to use to allow/deny/keep track of players where needed.
new bool:g_IsMapCompatible = false;
new bool:g_CellDoorTimerActive = false;
new bool:g_1stRoundFreeday = false;
new bool:g_bIsLRInUse = false;
new bool:g_bIsWardenLocked = false;
new bool:g_bIsSpeedDemonRound = false;
new bool:g_bIsLowGravRound = false;
new bool:g_RobotRoundClients[MAXPLAYERS+1];
new bool:g_IsMuted[MAXPLAYERS+1];
new bool:g_IsRebel[MAXPLAYERS + 1];
new bool:g_IsFreeday[MAXPLAYERS + 1];
new bool:g_IsFreedayActive[MAXPLAYERS + 1];
new bool:g_IsFreekiller[MAXPLAYERS + 1];
new bool:g_HasTalked[MAXPLAYERS+1];
new bool:g_LockedFromWarden[MAXPLAYERS+1];

//Anti-Freekilling System saves for players.
new g_FirstKill[MAXPLAYERS + 1];
new g_Killcount[MAXPLAYERS + 1];

//Used by the veto system for Warden.
new g_Voters = 0;
new g_Votes = 0;
new g_VotesNeeded = 0;
new g_VotesPassed = 0;
new bool:g_Voted[MAXPLAYERS+1] = {false, ...};

new String:DoorList[][] = {"func_door", "func_movelinear", "func_door_rotating"};	//String for the list of entities our plugin uses for the door opener and map compatibility checks.

new Warden = -1;	//Save a client as Warden, start with -1 which means there are no Wardens active.

//Enum to save last requests, this is a lot easier than using bool handles.
enum LastRequests
{
	LR_Disabled = 0,
	LR_FreedayForAll,
	LR_PersonalFreeday,
	LR_GuardsMeleeOnly,
	LR_HHHKillRound,
	LR_LowGravity,
	LR_SpeedDemon,
	LR_HungerGames,
	LR_RoboticTakeOver,
	LR_HideAndSeek
};
new LastRequests:enumLastRequests;

public Plugin:myinfo =	//You can edit these values in the defines above.
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};

public OnPluginStart()
{
	LogMessage("%s Jailbreak is now loading...", CLAN_TAG_COLOR);
	LoadTranslations("common.phrases");
	LoadTranslations("TF2Jail.phrases");

	JB_Cvar_Version = CreateConVar("tf2jail_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	JB_Cvar_Enabled = CreateConVar("sm_jail_enabled", "1", "Status of the plugin: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_Cvar_Advertise = CreateConVar("sm_jail_advertisement", "1", "Display plugin creator advertisement: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_Cvar_Cvars = CreateConVar("sm_jail_variables", "1", "Set default cvars: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_Cvar_Balance = CreateConVar("sm_jail_autobalance", "1", "Should the plugin autobalance teams: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_Cvar_BalanceRatio = CreateConVar("sm_jail_balance_ratio", "0.5", "Ratio for autobalance: (Example: 0.5 = 2:4)", FCVAR_PLUGIN, true, 0.1, true, 1.0);
	JB_Cvar_RedMelee = CreateConVar("sm_jail_redmeleeonly", "1", "Strip Red Team of weapons: (1 = strip weapons, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_Cvar_Warden = CreateConVar("sm_jail_warden", "1", "Allow Wardens: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_Cvar_WardenModel = CreateConVar("sm_jail_wardenmodel", "1", "Does Warden have a model: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_Cvar_WardenColor = CreateConVar("sm_jail_wardencolor", "125 150 250", "Color of warden if wardenmodel is off: (0 = off)", FCVAR_PLUGIN);
	JB_Cvar_Doorcontrol = CreateConVar("sm_jail_doorcontrols", "1", "Allow Wardens and Admins door control: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_Cvar_DoorOpenTime = CreateConVar("sm_jail_cell_opener", "60", "Time after Arena round start to open doors: (1.0 - 60.0) (0.0 = off)", FCVAR_PLUGIN, true, 0.0, true, 60.0);
	JB_Cvar_RedMute = CreateConVar("sm_jail_redmute", "2", "Mute Red team: (2 = mute prisoners alive and all dead, 1 = mute prisoners on round start based on redmute_time, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	JB_Cvar_RedMuteTime = CreateConVar("sm_jail_redmute_time", "15", "Mute time for redmute: (1.0 - 60.0)", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	JB_Cvar_MicCheck = CreateConVar("sm_jail_micchecks", "1", "Check blue clients for microphone: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_Cvar_Rebels = CreateConVar("sm_jail_rebels", "1", "Enable the Rebel system: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_Cvar_RebelColor = CreateConVar("sm_jail_rebels_color", "0 0 255", "Rebel color flags: (0 = off)", FCVAR_PLUGIN);
	JB_Cvar_RebelsTime = CreateConVar("sm_jail_rebel_time", "30.0", "Rebel timer: (1.0 - 60.0, 0 = always)", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	JB_Cvar_Crits = CreateConVar("sm_jail_crits", "1", "Which team gets crits: (0 = off, 1 = blue, 2 = red, 3 = both)", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	JB_Cvar_VoteNeeded = CreateConVar("sm_jail_voteoffwarden_votesneeded", "0.60", "Percentage of players required for fire warden vote: (default 0.60 - 60%) (0.05 - 1.0)", 0, true, 0.05, true, 1.00);
	JB_Cvar_VoteMinPlayers = CreateConVar("sm_jail_voteoffwarden_minplayers", "0", "Minimum amount of players required for fire warden vote: (0 - MaxPlayers)", 0, true, 0.0, true, float(MAXPLAYERS));
	JB_Cvar_VotePostAction = CreateConVar("sm_jail_voteoffwarden_post", "0", "Fire warden instantly on vote success or next round: (0 = instant, 1 = Next round)", _, true, 0.0, true, 1.0);
	JB_Cvar_Freekillers = CreateConVar("sm_jail_freekillers", "1", "Enable the Freekill system: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_Cvar_Freekillers_Time = CreateConVar("sm_jail_freekillers_time", "6.0", "Time in seconds minimum for freekill flag on mark: (1.0 - 60.0)", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	JB_Cvar_Freekillers_Kills = CreateConVar("sm_jail_freekillers_kills", "6", "Number of kills required to flag for freekilling: (1.0 - MaxPlayers)", FCVAR_PLUGIN, true, 1.0, true, float(MAXPLAYERS));
	JB_Cvar_Freekillers_Wave = CreateConVar("sm_jail_freekillers_wave", "60.0", "Time in seconds until client is banned for being marked: (1.0 - 60.0)", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	JB_Cvar_Freekillers_Action = CreateConVar("sm_jail_freekillers_action", "2", "Action towards marked freekiller: (2 = Ban client based on cvars, 1 = Slay the client, 0 = remove mark on timer)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	JB_Cvar_Freekillers_BanMSG = CreateConVar("sm_jail_freekillers_banreason", "You have been banned for freekilling.", "Message to give the client if they're marked as a freekiller and banned.", FCVAR_PLUGIN);
	JB_Cvar_Freekillers_BanMSGDC = CreateConVar("sm_jail_freekillers_bandcreason", "You have been banned for freekilling and disconnecting.", "Message to give the client if they're marked as a freekiller/disconnected and banned.", FCVAR_PLUGIN);
	JB_Cvar_Freekillers_Bantime = CreateConVar("sm_jail_freekillers_bantime", "60", "Time banned after timer ends: (0 = permanent)", FCVAR_PLUGIN, true, 0.0);
	JB_Cvar_Freekillers_BantimeDC = CreateConVar("sm_jail_freekillers_bantimedc", "120", "Time banned if disconnected after timer ends: (0 = permanent)", FCVAR_PLUGIN, true, 0.0);
	JB_Cvar_LRS_Enabled = CreateConVar("sm_jail_lr_enabled", "1", "Status of the LR System: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	JB_Cvar_FreedayColor = CreateConVar("sm_jail_freeday_color", "0 255 0", "Freeday color flags: (0 = off)", FCVAR_PLUGIN);
	JB_Cvar_VotePassedLimit = CreateConVar("sm_jail_voteoffwarden_limit", "3", "Limit to wardens fired by players via votes: (1 - 10, 0 = unlimited)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	JB_Cvar_BlueMute = CreateConVar("sm_jail_bluemute", "2", "Mute Blue team: (2 = always except warden, 1 = while Warden is active, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 2.0);

	//Colors saved by default, we define them here instead of as a global because we already have one handle setup.
	gWardenColor[0] = 125;
	gWardenColor[1] = 150;
	gWardenColor[2] = 250;
	gRebelColor[0] = 0;
	gRebelColor[1] = 0;
	gRebelColor[2] = 255;
	gFreedayColor[0] = 0;
	gFreedayColor[1] = 255;
	gFreedayColor[2] = 0;

	HookConVarChange(JB_Cvar_Enabled, HandleCvars);
	HookConVarChange(JB_Cvar_Advertise, HandleCvars);
	HookConVarChange(JB_Cvar_Cvars, HandleCvars);
	HookConVarChange(JB_Cvar_Balance, HandleCvars);
	HookConVarChange(JB_Cvar_BalanceRatio, HandleCvars);
	HookConVarChange(JB_Cvar_RedMelee, HandleCvars);
	HookConVarChange(JB_Cvar_Warden, HandleCvars);
	HookConVarChange(JB_Cvar_WardenModel, HandleCvars);
	HookConVarChange(JB_Cvar_WardenColor, HandleCvars);
	HookConVarChange(JB_Cvar_Doorcontrol, HandleCvars);
	HookConVarChange(JB_Cvar_DoorOpenTime, HandleCvars);
	HookConVarChange(JB_Cvar_RedMute, HandleCvars);
	HookConVarChange(JB_Cvar_RedMuteTime, HandleCvars);
	HookConVarChange(JB_Cvar_MicCheck, HandleCvars);
	HookConVarChange(JB_Cvar_Rebels, HandleCvars);
	HookConVarChange(JB_Cvar_RebelColor, HandleCvars);
	HookConVarChange(JB_Cvar_RebelsTime, HandleCvars);
	HookConVarChange(JB_Cvar_Crits, HandleCvars);
	HookConVarChange(JB_Cvar_VoteNeeded, HandleCvars);
	HookConVarChange(JB_Cvar_VoteMinPlayers, HandleCvars);
	HookConVarChange(JB_Cvar_VotePostAction, HandleCvars);
	HookConVarChange(JB_Cvar_Freekillers, HandleCvars);
	HookConVarChange(JB_Cvar_Freekillers_Time, HandleCvars);
	HookConVarChange(JB_Cvar_Freekillers_Kills, HandleCvars);
	HookConVarChange(JB_Cvar_Freekillers_Wave, HandleCvars);
	HookConVarChange(JB_Cvar_Freekillers_Action, HandleCvars);
	HookConVarChange(JB_Cvar_Freekillers_Bantime, HandleCvars);
	HookConVarChange(JB_Cvar_Freekillers_BantimeDC, HandleCvars);
	HookConVarChange(JB_Cvar_LRS_Enabled, HandleCvars);
	HookConVarChange(JB_Cvar_FreedayColor, HandleCvars);
	HookConVarChange(JB_Cvar_VotePassedLimit, HandleCvars);
	HookConVarChange(JB_Cvar_BlueMute, HandleCvars);
	
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_hurt", PlayerHurt);
	HookEvent("player_death", PlayerDeath);
	HookEvent("teamplay_round_start", RoundStart);
	HookEvent("arena_round_start", ArenaRoundStart);
	HookEvent("teamplay_round_win", RoundEnd);
	AddCommandListener(InterceptBuild, "build");
	
	AutoExecConfig(true, "TF2Jail");

	RegConsoleCmd("sm_jailbreak", JailbreakMenu);
	RegConsoleCmd("sm_fire", Command_FireWarden);
	RegConsoleCmd("sm_firewarden", Command_FireWarden);
	RegConsoleCmd("sm_w", BecomeWarden);
	RegConsoleCmd("sm_warden", BecomeWarden);
	RegConsoleCmd("sm_uw", ExitWarden);
	RegConsoleCmd("sm_unwarden", ExitWarden);
	RegConsoleCmd("sm_wmenu", WardenMenuC);
	RegConsoleCmd("sm_wardenmenu", WardenMenuC);
	RegConsoleCmd("sm_open", OnOpenCommand);
	RegConsoleCmd("sm_close", OnCloseCommand);
	RegConsoleCmd("sm_wff", WardenFriendlyFire);
	RegConsoleCmd("sm_wardenff", WardenFriendlyFire);
	RegConsoleCmd("sm_wardenfriendlyfire", WardenFriendlyFire);
	RegConsoleCmd("sm_wcc", WardenCollision);
	RegConsoleCmd("sm_wcollision", WardenCollision);
	RegConsoleCmd("sm_givelr", GiveLR);
	RegConsoleCmd("sm_givelastrequest", GiveLR);
	RegConsoleCmd("sm_givelrm", GiveLRMenu);
	RegConsoleCmd("sm_givelrmenu", GiveLRMenu);
	RegConsoleCmd("sm_removelr", RemoveLR);
	RegConsoleCmd("sm_removelastrequest", RemoveLR);
	
	RegAdminCmd("sm_rw", AdminRemoveWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_removewarden", AdminRemoveWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_pardon", AdminPardonFreekiller, ADMFLAG_GENERIC);
	RegAdminCmd("sm_denylr", AdminDenyLR, ADMFLAG_GENERIC);
	RegAdminCmd("sm_denylastrequest", AdminDenyLR, ADMFLAG_GENERIC);
	RegAdminCmd("sm_opencells", AdminOpenCells, ADMFLAG_GENERIC);
	RegAdminCmd("sm_closecells", AdminCloseCells, ADMFLAG_GENERIC);
	RegAdminCmd("sm_lockcells", AdminLockCells, ADMFLAG_GENERIC);
	RegAdminCmd("sm_unlockcells", AdminUnlockCells, ADMFLAG_GENERIC);
	RegAdminCmd("sm_forcewarden", AdminForceWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_forcelr", AdminForceLR, ADMFLAG_GENERIC);
	RegAdminCmd("sm_jailreset", AdminResetPlugin, ADMFLAG_GENERIC);
	RegAdminCmd("sm_compatible", MapCompatibilityCheck, ADMFLAG_GENERIC);
	RegAdminCmd("sm_givefreeday", AdminGiveFreeday, ADMFLAG_GENERIC);
	
	//Warden can change these if an admin allows it so we make them easier to manage.
	Cvar_FF = FindConVar("mp_friendlyfire");
	Cvar_COL = FindConVar("tf_avoidteammates_pushaway");
	
	//Targeting filters, we want admins the ability to target commands at certain groups involving the plugin. (IE 'sm_slap @freedays 3' will slap all freedays on the server, same concept as regular commands)
	AddMultiTargetFilter("@warden", WardenGroup, "the warden", false);
	AddMultiTargetFilter("@rebels", RebelsGroup, "all rebellers", false);
	AddMultiTargetFilter("@freedays", FreedaysGroup, "all freedays", false);
	AddMultiTargetFilter("@!warden", NotWardenGroup, "all but the warden", false);
	AddMultiTargetFilter("@!rebels", NotRebelsGroup, "all but rebellers", false);
	AddMultiTargetFilter("@!freedays", NotFreedaysGroup, "all but freedays", false);
	
	steamtools = LibraryExists("SteamTools");
	
	//Easier to manage forwards for natives.
	g_fward_onBecome = CreateGlobalForward("warden_OnWardenCreated", ET_Ignore, Param_Cell);
	g_fward_onRemove = CreateGlobalForward("warden_OnWardenRemoved", ET_Ignore, Param_Cell);

	AddServerTag2("Jailbreak");
	
	MapCheck();	//We want to check the map to see if it's compatible so lets do that now just in case we reload the plugin.
	
	g_hArray_Pending = CreateArray();	//Create an array and make it easier to use.
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));

	if (!StrEqual(Game, "tf"))	//You can probably change this to work with TFBeta but since I'm not bothering with it, I'm not adding it.
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}

	MarkNativeAsOptional("GetUserMessageType");
	MarkNativeAsOptional("Steam_SetGameDescription");
	
	//Ze natives, feel free to change these if you don't like the names.
	CreateNative("TF2Jail_WardenActive", Native_ExistWarden);
	CreateNative("TF2Jail_IsWarden", Native_IsWarden);
	CreateNative("TF2Jail_WardenSet", Native_SetWarden);
	CreateNative("TF2Jail_WardenUnset", Native_RemoveWarden);
	CreateNative("TF2Jail_IsFreeday", Native_IsFreeday);
	CreateNative("TF2Jail_GiveFreeday", Native_GiveFreeday);
	CreateNative("TF2Jail_IsRebel", Native_IsRebel);
	CreateNative("TF2Jail_MarkRebel", Native_MarkRebel);
	CreateNative("TF2Jail_IsFreekiller", Native_IsFreekiller);
	CreateNative("TF2Jail_MarkFreekiller", Native_MarkFreekill);
	RegPluginLibrary("TF2Jail");

	return APLRes_Success;
}

public OnAllPluginsLoaded()
{	
	//As stated at the start of the plugin, I want this plugin to be as customizable and functional as possible so we're going to be making everything an option but not allow anything to break.
	if (LibraryExists("betherobot"))				e_betherobot = true;
	if (LibraryExists("sdkhooks"))					e_sdkhooks = true;
	if (LibraryExists("tf2items"))					e_tf2items = true;
	if (LibraryExists("clientprefs"))				e_clientprefs = true;
	if (LibraryExists("voiceannounce_ex"))			e_voiceannounce_ex = true;
	if (LibraryExists("filesmanagementinterface"))	e_filemanager = true;
	if (LibraryExists("tf2attributes"))				e_tf2attributes = true;
	if (LibraryExists("sourcebans"))				e_sourcebans = true;
	if (LibraryExists("sourcecomms"))				e_sourcecomms = true;
	if (LibraryExists("basecomm"))					e_basecomm = true;
	if (LibraryExists("basebans"))					e_basebans = true;
}

public OnPluginEnd()
{
	ConvarsOff();	//Disable the cvars since the plugin is ending, assuming you don't want them to stay that way.
	RemoveServerTag2("Jailbreak");
	LogMessage("%s Jailbreak has been unloaded successfully.", CLAN_TAG);
}

stock ConvarsOn()	//General cvars that will interfere with the plugin if enabled. The air dashing for scout is not required so feel free to disable it if you so desire.
{
	SetConVarInt(FindConVar("mp_stalemate_enable"),0);
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
	SetConVarInt(FindConVar("mp_autoteambalance"), 0);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
	SetConVarInt(FindConVar("mp_scrambleteams_auto"), 0);
	SetConVarInt(FindConVar("tf_scout_air_dash_count"), 0);
}

stock ConvarsOff()	//Disable cvars.
{
	SetConVarInt(FindConVar("mp_stalemate_enable"),1);
	SetConVarInt(FindConVar("tf_arena_use_queue"), 1);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 1);
	SetConVarInt(FindConVar("mp_autoteambalance"), 1);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 1);
	SetConVarInt(FindConVar("mp_scrambleteams_auto"), 1);
	SetConVarInt(FindConVar("tf_scout_air_dash_count"), 1);
}

public OnLibraryAdded(const String:name[])
{
	//The goal is to be as stream-lined as possible, lets set the bools to true on libraries added.
	if (StrEqual(name, "sourcebans"))				e_sourcebans = true;
	if (StrEqual(name, "sourcecomms"))				e_sourcecomms = true;
	if (StrEqual(name, "basecomm"))					e_basecomm = true;
	if (StrEqual(name, "basebans"))					e_basebans = true;
	if (StrEqual(name, "filesmanagementinterface"))	e_filemanager = true;
	if (StrEqual(name, "voiceannounce_ex"))			e_voiceannounce_ex = true;
	if (StrEqual(name, "betherobot"))				e_betherobot = true;
	if (StrEqual(name, "tf2attributes"))			e_tf2attributes = true;
	if (StrEqual(name, "clientprefs"))				e_clientprefs = true;
	if (StrEqual(name, "tf2items"))					e_tf2items = true;
	if (StrEqual(name, "sdkhooks"))					e_sdkhooks = true;
	
	if (strcmp(name, "SteamTools", false) == 0)	steamtools = true;
}

public OnLibraryRemoved(const String:name[])
{
	//The goal is to be as stream-lined as possible so lets remove these once they're unloaded.
	if (StrEqual(name, "sourcebans"))				e_sourcebans = false;
	if (StrEqual(name, "basecomm"))					e_basecomm = false;
	if (StrEqual(name, "basebans"))					e_basebans = false;
	if (StrEqual(name, "sdkhooks"))					e_sdkhooks = false;
	if (StrEqual(name, "tf2items"))					e_tf2items = false;
	if (StrEqual(name, "clientprefs"))				e_clientprefs = false;
	if (StrEqual(name, "tf2attributes"))			e_tf2attributes = false;
	if (StrEqual(name, "sourcecomms"))				e_sourcecomms = false;
	if (StrEqual(name, "betherobot"))				e_betherobot = false;
	if (StrEqual(name, "voiceannounce_ex"))			e_voiceannounce_ex = false;
	if (StrEqual(name, "filesmanagementinterface"))	e_filemanager = false;
	
	if (strcmp(name, "SteamTools", false) == 0)	steamtools = false;
}

public OnConfigsExecuted()
{
	j_Enabled = GetConVarBool(JB_Cvar_Enabled);
	j_Advertise = GetConVarBool(JB_Cvar_Advertise);
	j_Cvars = GetConVarBool(JB_Cvar_Cvars);
	j_Balance = GetConVarBool(JB_Cvar_Balance);
	j_BalanceRatio = GetConVarFloat(JB_Cvar_BalanceRatio);
	j_RedMelee = GetConVarBool(JB_Cvar_RedMelee);
	j_Warden = GetConVarBool(JB_Cvar_Warden);
	j_WardenModel = GetConVarBool(JB_Cvar_WardenModel);
	j_DoorControl = GetConVarBool(JB_Cvar_Doorcontrol);
	j_DoorOpenTimer = GetConVarFloat(JB_Cvar_DoorOpenTime);
	j_RedMute = GetConVarInt(JB_Cvar_RedMute);
	j_RedMuteTime = GetConVarFloat(JB_Cvar_RedMuteTime);
	j_MicCheck = GetConVarBool(JB_Cvar_MicCheck);
	j_Rebels = GetConVarBool(JB_Cvar_Rebels);
	j_RebelsTime = GetConVarFloat(JB_Cvar_RebelsTime);
	j_Criticals = GetConVarInt(JB_Cvar_Crits);
	j_WVotesNeeded = GetConVarFloat(JB_Cvar_VoteNeeded);
	j_WVotesMinPlayers = GetConVarInt(JB_Cvar_VoteMinPlayers);
	j_WVotesPostAction = GetConVarInt(JB_Cvar_VotePostAction);
	j_Freekillers = GetConVarBool(JB_Cvar_Freekillers);
	j_FreekillersTime = GetConVarFloat(JB_Cvar_Freekillers_Time);
	j_FreekillersKills = GetConVarInt(JB_Cvar_Freekillers_Kills);
	j_FreekillersWave = GetConVarFloat(JB_Cvar_Freekillers_Wave);
	j_FreekillersAction = GetConVarInt(JB_Cvar_Freekillers_Action);
	j_FreekillersBantime = GetConVarInt(JB_Cvar_Freekillers_Bantime);
	j_FreekillersBantimeDC = GetConVarInt(JB_Cvar_Freekillers_BantimeDC);
	j_LRSEnabled = GetConVarBool(JB_Cvar_LRS_Enabled);
	j_WVotesPassedLimit = GetConVarInt(JB_Cvar_VotePassedLimit);
	j_BlueMute = GetConVarInt(JB_Cvar_BlueMute);
	
	if (e_clientprefs && e_filemanager && e_sdkhooks && e_tf2attributes && e_tf2items)
	{
		//Do NOTHING, we use these later. Less shit from the compiler.
	}

	//Plugin needs updates? This will tell you exactly why.
	new String:strVersion[16];
	GetConVarString(JB_Cvar_Version, strVersion, 16);
	if (StrEqual(strVersion, PLUGIN_VERSION) == false)
	{
		LogError("Your plugin seems to be outdated, please refresh your config in order to receive new command variables list.");
	}
	SetConVarString(JB_Cvar_Version, PLUGIN_VERSION);

	if (j_Enabled)
	{		
		if (j_Cvars)
		{
			ConvarsOn();
		}
		if (j_WardenModel)	//If Warden model is enabled, no need to add these to download tables if it's not since the plugin won't be using it.
		{
			if (PrecacheModel("models/jailbreak/warden/warden_v2.mdl", true))	//Precache the model on the server.
			{
				AddFileToDownloadsTable("models/jailbreak/warden/warden_v2.mdl");
				AddFileToDownloadsTable("models/jailbreak/warden/warden_v2.dx80.vtx");
				AddFileToDownloadsTable("models/jailbreak/warden/warden_v2.dx90.vtx");
				AddFileToDownloadsTable("models/jailbreak/warden/warden_v2.phy");
				AddFileToDownloadsTable("models/jailbreak/warden/warden_v2.sw.vtx");
				AddFileToDownloadsTable("models/jailbreak/warden/warden_v2.vvd");
				AddFileToDownloadsTable("materials/models/jailbreak/warden/NineteenEleven.vtf");
				AddFileToDownloadsTable("materials/models/jailbreak/warden/NineteenEleven.vmt");
				AddFileToDownloadsTable("materials/models/jailbreak/warden/warden_body.vtf");
				AddFileToDownloadsTable("materials/models/jailbreak/warden/warden_body.vmt");
				AddFileToDownloadsTable("materials/models/jailbreak/warden/warden_hat.vtf");
				AddFileToDownloadsTable("materials/models/jailbreak/warden/warden_hat.vmt");
				AddFileToDownloadsTable("materials/models/jailbreak/warden/warden_head.vtf");
				AddFileToDownloadsTable("materials/models/jailbreak/warden/warden_head.vmt");
			}
			else	//Something went wrong, lets throw an error and turn Warden model off so we don't see errors.
			{
				LogError("Warden model has failed to load correctly, please verify the files.");
				j_WardenModel = false;
			}
		}
	}
	if (steamtools)	//Lets set the description for the server to TF2Jail since we like to be badass like that.
	{
		decl String:gameDesc[64];
		Format(gameDesc, sizeof(gameDesc), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
		Steam_SetGameDescription(gameDesc);
	}
	ResetVotes();	//Lets reset all the votes so Wardens can't get voted off even easier than now.
}

public HandleCvars (Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(oldValue, newValue, true))
	{
		return;	//Obviously, if it's the same, no need to change it.
	}
	
	new iNewValue = StringToInt(newValue);
	
	if (cvar == JB_Cvar_Enabled)	//Generally hooks and unhooks events, command listeners, and disables everything it should.
	{
		if (iNewValue == 1)
		{
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "plugin enabled");
			HookEvent("player_spawn", PlayerSpawn);
			HookEvent("player_hurt", PlayerHurt);
			HookEvent("player_death", PlayerDeath);
			HookEvent("teamplay_round_start", RoundStart);
			HookEvent("arena_round_start", ArenaRoundStart);
			HookEvent("teamplay_round_win", RoundEnd);
			AddCommandListener(InterceptBuild, "build");
			j_Enabled = true;
			if (steamtools)
			{
				decl String:gameDesc[64];
				Format(gameDesc, sizeof(gameDesc), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
				Steam_SetGameDescription(gameDesc);
			}
			for (new i = 1; i <= MaxClients; i++)
			{
				if (i == Warden && j_WardenModel)
				{
					SetModel(i, "models/jailbreak/warden/warden_v2.mdl");
				}
			}
		}
		else if (iNewValue == 0)
		{
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "plugin disabled");
			UnhookEvent("player_spawn", PlayerSpawn);
			UnhookEvent("player_hurt", PlayerHurt);
			UnhookEvent("player_death", PlayerDeath);
			UnhookEvent("teamplay_round_start", RoundStart);
			UnhookEvent("arena_round_start", ArenaRoundStart);
			UnhookEvent("teamplay_round_win", RoundEnd);
			RemoveCommandListener(InterceptBuild, "build");
			j_Enabled = false;
			if (steamtools)
			{
				Steam_SetGameDescription("Team Fortress");
			}
			for (new i = 1; i <= MaxClients; i++)
			{
				if (i == Warden && j_WardenModel)
				{
					RemoveModel(i);
				}
				if (g_IsRebel[i] && j_Rebels)
				{
					SetEntityRenderColor(i, 255, 255, 255, 255);
					g_IsRebel[i] = false;
				}
			}
		}
	}
	else if (cvar == JB_Cvar_Advertise)
	{
		if (iNewValue == 1)
		{
			j_Advertise = true;
		}
		else if (iNewValue == 0)
		{
			j_Advertise = false;
		}
	}
	else if (cvar == JB_Cvar_Cvars)
	{
		if (iNewValue == 1)
		{
			j_Cvars = true;
			ConvarsOn();
		}
		else if (iNewValue == 0)
		{
			j_Cvars = false;
			ConvarsOff();
		}
	}
	else if (cvar == JB_Cvar_Balance)
	{
		if (iNewValue == 1)
		{
			j_Balance = true;
		}
		else if (iNewValue == 0)
		{
			j_Balance = false;
		}
	}
	else if (cvar == JB_Cvar_BalanceRatio)
	{
		j_BalanceRatio = StringToFloat(newValue);
	}
	else if (cvar == JB_Cvar_RedMelee)
	{
		if (iNewValue == 1)
		{
			j_RedMelee = true;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Red && IsPlayerAlive(i))
				{
					RedSpawnStrip(i);
				}
			}
		}
		else if (iNewValue == 0)
		{
			j_RedMelee = false;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Red && IsPlayerAlive(i))
				{
					TF2_RegeneratePlayer(i);
				}
			}
		}
	}
	else if (cvar == JB_Cvar_Warden)
	{
		if (iNewValue == 1)
		{
			j_Warden = true;
		}
		else if (iNewValue == 0)
		{
			j_Warden = false;
		}
	}
	else if (cvar == JB_Cvar_WardenModel)
	{
		if (iNewValue == 1)
		{
			j_WardenModel = true;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (i == Warden)
				{
					SetEntityRenderColor(i, 255, 255, 255, 255);
					SetModel(i, "models/jailbreak/warden/warden_v2.mdl");
				}
			}
		}
		else if (iNewValue == 0)
		{
			j_WardenModel = false;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (i == Warden)
				{
					SetEntityRenderColor(i, gWardenColor[0], gWardenColor[1], gWardenColor[2], 255);
					RemoveModel(i);
				}
			}
		}
	}
	else if (cvar == JB_Cvar_WardenColor)
	{
		gWardenColor = SplitColorString(newValue);
	}
	else if (cvar == JB_Cvar_Doorcontrol)
	{
		if (iNewValue == 1)
		{
			j_DoorControl = false;
		}
		else if (iNewValue == 0)
		{
			j_DoorControl = true;
		}
	}
	else if (cvar == JB_Cvar_DoorOpenTime)
	{
		j_DoorOpenTimer = StringToFloat(newValue);
	}
	else if (cvar == JB_Cvar_RedMute)
	{
		j_RedMute = iNewValue;
	}
	else if (cvar == JB_Cvar_RedMuteTime)
	{
		j_RedMuteTime = StringToFloat(newValue);
	}
	else if (cvar == JB_Cvar_MicCheck)
	{
		if (iNewValue == 1)
		{
			j_MicCheck = true;
		}
		else if (iNewValue == 0)
		{
			j_MicCheck = false;
		}
	}	
	else if (cvar == JB_Cvar_Rebels)
	{
		if (iNewValue == 1)
		{
			j_Rebels = true;
		}
		else if (iNewValue == 0)
		{
			j_Rebels = false;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (g_IsRebel[i])
				{
					SetEntityRenderColor(i, 255, 255, 255, 255);
					g_IsRebel[i] = false;
				}
			}
		}
	}
	else if (cvar == JB_Cvar_RebelColor)
	{
		gRebelColor = SplitColorString(newValue);
	}
	else if (cvar == JB_Cvar_RebelsTime)
	{
		j_RebelsTime = StringToFloat(newValue);
	}
	else if (cvar == JB_Cvar_Crits)
	{
		j_Criticals = iNewValue;
	}
	else if (cvar == JB_Cvar_VoteNeeded)
	{
		j_WVotesNeeded = StringToFloat(newValue);
	}
	else if (cvar == JB_Cvar_VoteMinPlayers)
	{
		j_WVotesMinPlayers = iNewValue;
	}
	else if (cvar == JB_Cvar_VotePostAction)
	{
		j_WVotesPostAction = iNewValue;
	}
	else if (cvar == JB_Cvar_Freekillers)
	{
		if (iNewValue == 1)
		{
			j_Freekillers = true;
		}
		else if (iNewValue == 0)
		{
			j_Freekillers = false;
		}
	}
	else if (cvar == JB_Cvar_Freekillers_Time)
	{
		j_FreekillersTime = StringToFloat(newValue);
	}
	else if (cvar == JB_Cvar_Freekillers_Kills)
	{
		j_FreekillersKills = iNewValue;
	}
	else if (cvar == JB_Cvar_Freekillers_Wave)
	{
		j_FreekillersWave = StringToFloat(newValue);
	}
	else if (cvar == JB_Cvar_Freekillers_Action)
	{
		j_FreekillersAction = iNewValue;
	}
	else if (cvar == JB_Cvar_Freekillers_Bantime)
	{
		j_FreekillersBantime = iNewValue;
	}
	else if (cvar == JB_Cvar_Freekillers_BantimeDC)
	{
		j_FreekillersBantimeDC = iNewValue;
	}
	else if (cvar == JB_Cvar_LRS_Enabled)
	{
		if (iNewValue == 1)
		{
			j_LRSEnabled = true;
		}
		else if (iNewValue == 0)
		{
			j_LRSEnabled = false;
		}
	}
	else if (cvar == JB_Cvar_FreedayColor)
	{
		gFreedayColor = SplitColorString(newValue);
	}
	else if (cvar == JB_Cvar_VotePassedLimit)
	{
		j_WVotesPassedLimit = iNewValue;
	}
	else if (cvar == JB_Cvar_BlueMute)
	{
		j_BlueMute = iNewValue;
	}
}

SplitColorString(const String:colors[])	//Read the credits above for the name of the person and his plugin I got this from, I just used it to make my plugin more customizable.
{
	decl _iColors[3], String:_sBuffer[3][4];
	ExplodeString(colors, " ", _sBuffer, 3, 4);
	for (new i = 0; i <= 2; i++)
	_iColors[i] = StringToInt(_sBuffer[i]);
	
	return _iColors;
}

public OnMapStart()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			OnClientConnected(i);	//We should probably do a double check for clients when the map starts, may skip a few.
		}
	}
	if (j_Enabled && j_Advertise)	g_adverttimer = CreateTimer(120.0, TimerAdvertisement, _, TIMER_REPEAT);	//MY ADVERTISEMENT TIMER! IT'S GLORIOUS! Obviously won't turn on if the plugin is off.
	
	g_1stRoundFreeday = true;	//Lets make sure the 1st round is freeday so new clients connecting have a chance to play.

	//Set all the votes to 0 just in case.
	g_Voters = 0;
	g_Votes = 0;
	g_VotesNeeded = 0;
	
	MapCheck();	//New map, lets check if it's compatible. If it's not, disable door controls and if it is, leave them on.
}

public OnMapEnd()
{
	for (new i = 1; i <= MaxClients; i++)	//Shall we make sure all client bools are false for a fresh start?
	{
		if (IsValidClient(i))
		{
			g_HasTalked[i] = false;
			g_IsMuted[i] = false;
			g_IsFreeday[i] = false;
			g_LockedFromWarden[i] = false;
		}
	}

	if (j_Cvars)	ConvarsOff();	//Cvars are on? Lets turn them off just in case you changed config settings then changed the map.
	if (steamtools)	Steam_SetGameDescription("Team Fortress");	//Same concept with the cvars portion, just in case you changed the map with the plugin off.

	g_IsMapCompatible = false;	//Just because the current map is compatible doesn't mean the next one is.
	
	CloseHandle(g_adverttimer);	//NOOO, my poor ad. ;_;
	g_adverttimer = INVALID_HANDLE;
	
	ResetVotes();	//Reset votes so current votes don't hinder 1st warden on next map.
}

public Action:TimerAdvertisement (Handle:timer, any:client)
{
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "plugin advertisement");	//My advertisement brings all the boys to the yard.
}

public OnClientConnected(client)
{
	if (IsFakeClient(client))	return;	//Fake client? Don't worry, we gotchya covered!
	
	g_Voted[client] = false;

	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * j_WVotesNeeded);
	
	return;
}

public OnClientPutInServer(client)
{
	//Not entirely certain that these are needed but reconnecting clients may cause problems.
	g_IsMuted[client] = false;
	g_RobotRoundClients[client] = false;
	g_IsRebel[client] = false;
	g_IsFreeday[client] = false;
	g_IsFreedayActive[client] = false;
	g_IsFreekiller[client] = false;
	g_HasTalked[client] = false;
	g_LockedFromWarden[client] = false;
}

public OnClientPostAdminCheck(client)
{
	if (j_Enabled)	CreateTimer(4.0, Timer_Welcome, client, TIMER_FLAG_NO_MAPCHANGE);	//Lets welcome our guests and be sure they know about the menus and rules.
}

public Action:Timer_Welcome(Handle:timer, any:client)
{
	if (IsValidClient(client))	CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "welcome message");	//	"message"
}

public OnClientDisconnect(client)
{
	if (IsFakeClient(client))	return;	//Those pesky fake clients...
	
	if (g_Voted[client])	g_Votes--;
	g_Voters--;

	g_VotesNeeded = RoundToFloor(float(g_Voters) * j_WVotesNeeded);
	
	if (g_Votes && g_Voters && g_Votes >= g_VotesNeeded )	//Lets deduct from the current value and if the new value is the needed amount, fire the Warden.
	{
		if (j_WVotesPostAction == 1)
		{
			return;
		}
		FireWardenCall();
	}

	if (client == Warden)	//Client was Warden? Better find a new one.
	{
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "warden disconnected");
		PrintCenterTextAll("%t", "warden disconnected center");
		Warden = -1;
	}

	g_HasTalked[client] = false;
	g_IsMuted[client] = false;
	g_RobotRoundClients[client] = false;
	g_IsRebel[client] = false;
	g_IsFreeday[client] = false;
	g_Killcount[client] = 0;
	g_FirstKill[client] = 0;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	new notarget = GetEntityFlags(client)|FL_NOTARGET;

	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		g_IsRebel[client] = false;
		switch(enumLastRequests)
		{
		case LR_GuardsMeleeOnly, LR_HungerGames, LR_HideAndSeek:	//Some LR's require players to not have weapons but melee during them, this would push that.
			{
				TF2_RemoveWeaponSlot(client, 0);
				TF2_RemoveWeaponSlot(client, 1);
				TF2_RemoveWeaponSlot(client, 3);
				TF2_RemoveWeaponSlot(client, 4);
				TF2_RemoveWeaponSlot(client, 5);
				TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
			}
		}
		if (team == _:TFTeam_Red)
		{
			SetEntityFlags(client, notarget);	//Sentries shouldn't be able to fire at you unless wrangled.

			new ent = -1;
			while ((ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != -1)
			{
				AcceptEntityInput(ent, "kill");	//Lets kill the demo shield if red since it can cause problems.
			}
			if (TF2_GetPlayerClass(client) == TFClass_Spy && TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				TF2_RemoveCondition(client, TFCond_Cloaked);	//Cloaked spies shouldn't be able to cloak.
			}
			if (j_RedMute != 0) MutePlayer(client);	//Lets mute the players if the cvar is set to the given value.
			if (g_IsFreeday[client]) GiveFreeday(client);	//If the client's freeday, give him is freeday.
			if (j_RedMelee) RedSpawnStrip(client);	//Lets strip reds of their melee, this also removes certain weapons.
		}
		else if (team == _:TFTeam_Blue)
		{
			if (e_voiceannounce_ex && !g_HasTalked[client] && j_MicCheck && !Client_HasAdminFlags(client, ADMFLAG_RESERVATION))	//Microphone check, checks if the plugin is detected, if the client hasn't talked, if the cvars are set to on and if the client isn't a VIP/Donor.
			{
				ChangeClientTeam(client, _:TFTeam_Red);
				TF2_RespawnPlayer(client);
				CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "microphone unverified");
			}
			if (j_BlueMute == 2) MutePlayer(client);	//Mute blue team if this cvar is set to 2.
		}
	}
	return Plugin_Continue;
}

RedSpawnStrip(client)	//This strips weapons properly so clients have no ammo in the clip or on them properly without glitches. (Least it should)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	new index = -1;
	switch(class)
	{
	case TFClass_DemoMan:
		{
			SetClip(client, 0, 0, client);
			SetClip(client, 1, 0, client);
			SetAmmo(client, 0, 0, client);
			SetAmmo(client, 1, 0, client);
		}
	case TFClass_Engineer:
		{
			SetClip(client, 0, 0, client);
			SetClip(client, 1, 0, client);
			SetAmmo(client, 0, 0, client);
			SetAmmo(client, 1, 0, client);
		}
	case TFClass_Heavy:
		{
			SetClip(client, 1, 0, client);
			SetAmmo(client, 0, 0, client);
			SetAmmo(client, 1, 0, client);
		}
	case TFClass_Medic:
		{
			SetClip(client, 0, 0, client);
			SetClip(client, 1, 0, client);
			SetAmmo(client, 0, 0, client);
			SetAmmo(client, 1, 0, client);
		}
	case TFClass_Pyro:
		{
			SetClip(client, 1, 0, client);
			SetAmmo(client, 0, 0, client);
			SetAmmo(client, 1, 0, client);
		}
	case TFClass_Scout:
		{
			SetClip(client, 0, 0, client);
			SetClip(client, 1, 0, client);
			SetAmmo(client, 0, 0, client);
			SetAmmo(client, 1, 0, client);
		}
	case TFClass_Sniper:
		{
			SetClip(client, 1, 0, client);
			SetAmmo(client, 0, 0, client);
			SetAmmo(client, 1, 0, client);
		}
	case TFClass_Soldier:
		{
			SetClip(client, 0, 0, client);
			SetClip(client, 1, 0, client);
			SetAmmo(client, 0, 0, client);
			SetAmmo(client, 1, 0, client);
		}
	case TFClass_Spy:
		{
			SetClip(client, 0, 0, client);
			SetClip(client, 1, 0, client);
			SetAmmo(client, 0, 0, client);
			SetAmmo(client, 1, 0, client);
		}
	}
	new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if (primary > MaxClients && IsValidEdict(primary))
	{
		index = GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex");
		switch (index)
		{
		case 56, 1005: SetClip(client, 0, 0, client);
		}
	}
	TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
	TF2_RemoveWeaponSlot(client, 3);
	TF2_RemoveWeaponSlot(client, 4);
	TF2_RemoveWeaponSlot(client, 5);
	CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "stripped weapons and ammo");
}

stock TF2_SwitchtoSlot(client, slot)	//Code to switch the slot of a player, mainly used for melee.
{
	if (slot >= 0 && slot <= 5 && IsValidClient(client) && IsPlayerAlive(client))
	{
		decl String:classname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

public Action:PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!j_Enabled || !IsValidClient(client) || !IsValidClient(client_attacker))
	{
		return Plugin_Continue;
	}

	if (client_attacker != client)
	{
		if (g_IsFreedayActive[client_attacker])
		{
			RemoveFreeday(client_attacker);	//If the client is an active freeday, remove their freeday for attacking a guard.
		}
		if (j_Rebels && GetClientTeam(client_attacker) == _:TFTeam_Red && GetClientTeam(client) == _:TFTeam_Blue && !g_IsRebel[client_attacker])
		{
			MarkRebel(client_attacker);	//Lets mark them as a rebel if they attack someone.
		}
	}
	return Plugin_Continue;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new time = GetTime();
	
	if (!j_Enabled || !IsValidClient(client) || !IsValidClient(client_killer))
	{
		return Plugin_Continue;
	}

	if (j_Freekillers && client_killer != client && GetClientTeam(client_killer) == _:TFTeam_Blue)	//Anti-Freekill system
	{
		if ((g_FirstKill[client_killer] + j_FreekillersTime) >= time)
		{
			if (++g_Killcount[client_killer] == j_FreekillersKills)
			{
				MarkFreekiller(client_killer);	//If they killed a certain number of clients in a certain number of seconds, lets mark them.
			}
		}
		else
		{
			g_Killcount[client_killer] = 1;
			g_FirstKill[client_killer] = time;
		}
	}
	
	if (client == Warden)	//Client died as Warden, we need a new one.
	{
		WardenUnset(Warden);
		PrintCenterTextAll("%t", "warden killed", Warden);
	}

	switch(j_RedMute)
	{
	case 1, 2:	MutePlayer(client);	//In the case of the cvar, it would probably be in our best interest to do what the cvar is intended to do and mute them on death.
	}

	new lastprisoner = Team_GetClientCount(_:TFTeam_Red, CLIENTFILTER_ALIVE);	//Requested by Theodore of the HopsJB community, he wanted it so if warden is disabled, last request is given to last remaining red player regardless.
	if (lastprisoner == 1 && !j_Warden)
	{
		if (IsPlayerAlive(client) && GetClientTeam(client) == _:TFTeam_Red)
		{
			LastRequestStart(client);
		}
	}
	return Plugin_Continue;
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	Warden = -1;	//New Warden, lets set it.
	g_bIsLRInUse = false;	//LR is is not currently in use, lets allow Warden again.

	ServerCommand("sm_countdown_enabled 2");	//Messy, I know. Until I convert the countdown plugin into a sub module, this will be here so we know it's on regardless.

	if (j_Enabled && g_1stRoundFreeday)	//1st round freeday? Lets open the jails!
	{
		OpenCells();
		PrintCenterTextAll("1st round freeday");
		g_1stRoundFreeday = false;	//Probably not wise to have it on multiple rounds.
	}
	if (g_IsMapCompatible)	//Is the map compatible and passed it's checks? Lets do stuff.
	{
		new open_cells = Entity_FindByName("open_cells", "func_button");	//Lets grab the entity if it exsits for the door button.
		if (Entity_IsValid(open_cells))
		{
			if (j_DoorControl)
			{
				Entity_Lock(open_cells);	//Lets lock it if the door controls are on, no need to keep it on.
			}
			else
			{
				Entity_UnLock(open_cells);	//We should probably unlock it if the cvar is off so players can open the door.
			}
		}
	}
	else	//Map didn't pass it's checks, lets throw an error.
	{
		LogError("Map is incompatible, disabling check for door controls command variable.");	//Ze error, ugly is it not?
	}
}

public Action:ArenaRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!j_Enabled) return Plugin_Continue;

	g_bIsWardenLocked = false;	//Warden is no longer locked so lets make sure it's not locked.

	new Float:Ratio;
	if (j_Balance)	//Autobalance, needs more work to it but it works for now.
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			Ratio = Float:GetTeamClientCount(_:TFTeam_Blue)/Float:GetTeamClientCount(_:TFTeam_Red);
			if (Ratio <= j_BalanceRatio || GetTeamClientCount(_:TFTeam_Red) == 1)
			{
				break;
			}
			if (IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Blue)
			{
				ChangeClientTeam(i, _:TFTeam_Red);
				TF2_RespawnPlayer(i);
				CPrintToChat(i, "%s %t", CLAN_TAG_COLOR, "moved for balance");
			}
		}
	}
	
	if (g_IsMapCompatible && j_DoorOpenTimer != 0.0)	//Is the map compatible? and is the cvar set to on? Lets automatically open the doors after a number of seconds if Warden doesn't, give the prisoners fresh air.
	{
		new autoopen = RoundFloat(j_DoorOpenTimer);
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "cell doors open start", autoopen);
		CreateTimer(j_DoorOpenTimer, Open_Doors, _);
		g_CellDoorTimerActive = true;
	}

	switch(j_RedMute)	//Based on the cvar, lets do whatever is needed with mutes.
	{
	case 0:
		{
			CPrintToChatAll("%s Muting is currently disabled. Everyone may talk.", CLAN_TAG_COLOR);
		}
	case 1:
		{
			new time = RoundFloat(j_RedMuteTime);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "red team muted temporarily", time);
			CreateTimer(j_RedMuteTime, UnmuteReds, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	case 2:
		{
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "red team muted");
		}
	}
	
	switch(enumLastRequests)	//Last request system - Basically executes certain things and tells people in chat that shit's hitting the fan. It also sets the LR to 0 or offfor each one.
	{
	case LR_FreedayForAll:
		{
			OpenCells();
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr free for all executed");
			enumLastRequests = LR_Disabled;
		}
	case LR_PersonalFreeday:
		{
			//CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr freeday executed", client);	//This needs work which I am doing.
			enumLastRequests = LR_Disabled;
		}
	case LR_GuardsMeleeOnly:
		{
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr guards melee only executed");
			enumLastRequests = LR_Disabled;
		}
	case LR_HHHKillRound:
		{
			ServerCommand("sm_behhh @all");
			OpenCells();
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr hhh kill round executed");
			CreateTimer(10.0, EnableFFTimer, _, TIMER_FLAG_NO_MAPCHANGE);
			enumLastRequests = LR_Disabled;
		}
	case LR_LowGravity:
		{
			g_bIsLowGravRound = true;
			ServerCommand("sv_gravity 300");
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr low gravity round executed");
			enumLastRequests = LR_Disabled;
		}
	case LR_SpeedDemon:
		{
			g_bIsSpeedDemonRound = true;
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr speed demon round executed");
			enumLastRequests = LR_Disabled;
		}
	case LR_HungerGames:
		{
			OpenCells();
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr hunger games executed");
			CreateTimer(10.0, EnableFFTimer, _, TIMER_FLAG_NO_MAPCHANGE);
			enumLastRequests = LR_Disabled;
		}
	case LR_RoboticTakeOver:
		{
			if (e_betherobot)	//JUST in case the Robotic LR is executed regardless if the bools set to false or something glitches, lets not execute just in case if it isn't.
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i))
					{
						g_RobotRoundClients[i] = true;
						BeTheRobot_SetRobot(i, true);
					}
				}
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr robotic takeover executed");
				enumLastRequests = LR_Disabled;
			}
			else
			{
				LogError("Robotic Takeover cannot be executed due to lack of the Plug-in being installed, please check that the plug-in is installed and running properly.");
			}
		}
	case LR_HideAndSeek:
		{
			OpenCells();
			ServerCommand("sm_freeze @blue 45");
			CreateTimer(30.0, LockBlueteam, _, TIMER_FLAG_NO_MAPCHANGE);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr hide and seek executed");
			enumLastRequests = LR_Disabled;
		}
	}
	return Plugin_Continue;
}

//If you're new to plugin development, we do so many checks in timers because clients can disconnect, die or anything during them so lets not have errors spawn.
public Action:UnmuteReds(Handle:timer, any:client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
		{
			UnmutePlayer(i);
		}
	}
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "red team unmuted");
	return Plugin_Continue;
}

public Action:Open_Doors(Handle:timer, any:client)
{
	if (g_CellDoorTimerActive)
	{
		OpenCells();
		new time = RoundFloat(j_DoorOpenTimer);
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "cell doors open end", time);
		g_CellDoorTimerActive = false;
	}
}

public Action:LockBlueteam(Handle:timer, any:client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
		{
			TF2_StunPlayer(i, 120.0, 0.0, TF_STUNFLAGS_LOSERSTATE, 0);
		}
	}
}

public Action:RoundEnd(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	if (!j_Enabled) return Plugin_Continue;

	if (GetConVarBool(Cvar_FF))	SetConVarBool(Cvar_FF, false);	//Lets set the cvars back to default just in case.
	if (GetConVarBool(Cvar_COL))	SetConVarBool(Cvar_COL, false);	// ^^^

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			UnmutePlayer(i);
			if (g_RobotRoundClients[i])	//There's no check for the bool in this since the only way players have this activated on them is IF the plugin is active.
			{
				BeTheRobot_SetRobot(i, false);
				g_RobotRoundClients[i] = false;
			}
		}
		if (i == Warden) WardenUnset(i);	//Warden still alive? How shocking, lets demote him for next round.
		if (g_IsFreedayActive[i])	//Any active freedays need to be stripped so lets do that.
		{
			ServerCommand("sm_evilbeam #%d", GetClientUserId(i));
			g_IsFreedayActive[i] = false;
		}
	}
	
	//Lets set cvars and reset everything from LR's.
	if (g_bIsLowGravRound)
	{
		ServerCommand("sv_gravity 800");
		g_bIsLowGravRound = false;
	}
	if (g_bIsSpeedDemonRound)
	{
		ResetPlayerSpeed();
		g_bIsSpeedDemonRound = false;
	}
	return Plugin_Continue;
}

public OnGameFrame()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsPlayerAlive(i)) continue;
		if (g_bIsSpeedDemonRound)	SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 400.0);	//I wanted to use a timer for this but it seemed trivial to do that so I just did this to make things simple.
		
		if (j_Enabled)
		{
			switch(j_Criticals)	//The criticals function was causing problems so I broke down and just used this. It's easier.
			{
			case 1:
				{
					if (GetClientTeam(i) == _:TFTeam_Blue)
					{
						TF2_AddCondition(i, TFCond_Kritzkrieged, 0.1);
					}
				}
			case 2:
				{
					if (GetClientTeam(i) == _:TFTeam_Red)
					{
						TF2_AddCondition(i, TFCond_Kritzkrieged, 0.1);
					}
				}
			case 3:
				{
					TF2_AddCondition(i, TFCond_Kritzkrieged, 0.1);
				}
			}
		}
	}
}

public OnEntityCreated(entity, const String:classname[])	//I got reports of players inside their cells suiciding and giving the dropped weapons as ammo, this fixes that. It messes with metal dropped from dead sentries but not that bad in Jailbreak.
{
	if (j_Enabled && IsValidEntity(entity))
	{
		if (StrContains(classname, "tf_ammo_pack", false) != -1)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
}

public bool:OnClientSpeakingEx(client)
{
	if (e_voiceannounce_ex && j_MicCheck && !g_HasTalked[client])	//They talk? Lets verify them so they can join blue.
	{
		g_HasTalked[client] = true;
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "microphone verified");
	}
}

public Action:JailbreakMenu(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}

	if (!client)
	{
		ReplyToCommand(client, "%t","Command is in-game only");
		return Plugin_Handled;
	}

	else
	{
		JB_ShowMenu(client);
	}
	return Plugin_Handled;
}

JB_ShowMenu(client)
{
	new Handle:menu = CreateMenu(JB_MenuHandler);
	SetMenuExitBackButton(menu, false);

	SetMenuTitle(menu, "Jailbreak %s", PLUGIN_VERSION);

	AddMenuItem(menu, "rules",    "Rules & Gameplay");
	AddMenuItem(menu, "commands", "Commands");

	DisplayMenu(menu, client, 30);
}

public JB_MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	case MenuAction_Select:
		{
			new Handle:cpanel = CreatePanel();
			if (param2 == 0)
			{
				SetPanelTitle(cpanel, "Rules:");
				DrawPanelText(cpanel, " ");

				DrawPanelText(cpanel, "This menu is currently being built.");
			}
			else if (param2 == 1)
			{
				SetPanelTitle(cpanel, "Commands:");
				DrawPanelText(cpanel, " ");
			}
			for (new j = 0; j < 7; ++j)
			DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
			DrawPanelText(cpanel, " ");
			DrawPanelItem(cpanel, "Back", ITEMDRAW_CONTROL);

			SendPanelToClient(cpanel, param1, Help_MenuHandler, 45);
			CloseHandle(cpanel);
		}
	}
}

public Help_MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	case MenuAction_Select:
		{
			JB_ShowMenu(param1);
		}
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			JB_ShowMenu(param1);
		}
	}
}

public Action:Command_FireWarden(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}

	if (!client) return Plugin_Handled;

	AttemptFireWarden(client);

	return Plugin_Handled;
}

AttemptFireWarden(client)
{
	if (GetClientCount(true) < j_WVotesMinPlayers)
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "fire warden minimum players not met");
		return;			
	}

	if (g_Voted[client])
	{
		CReplyToCommand(client, "%s %t", CLAN_TAG_COLOR, "fire warden already voted", g_Votes, g_VotesNeeded);
		return;
	}

	new String:name[64];
	GetClientName(client, name, sizeof(name));
	g_Votes++;
	g_Voted[client] = true;

	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "fire warden requested", name, g_Votes, g_VotesNeeded);

	if (g_Votes >= g_VotesNeeded)
	{
		FireWardenCall();
	}	
}

FireWardenCall()
{
	if (Warden != -1)
	{
		for (new i=1; i<=MAXPLAYERS; i++)
		{
			if (i == Warden)
			{
				WardenUnset(i);
				g_LockedFromWarden[i] = true;
			}
		}
		ResetVotes();
		g_VotesPassed++;
	}
}

ResetVotes()
{
	g_Votes = 0;
	
	for (new i=1; i<=MAXPLAYERS; i++)
	{
		g_Voted[i] = false;
	}
}

public Action:MapCompatibilityCheck(client, args)	//I set this up so maps can be setup to be compatible or not without the plugin losing it's mind and players being locked in their cells constantly.
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	new open_cells = Entity_FindByName("open_cells", "func_button");
	new cell_door = Entity_FindByName("cell_door", "func_door");
	
	if (Entity_IsValid(open_cells))
	{
		CPrintToChat(client, "%s Cell Opener = Detected", CLAN_TAG);
	}
	else
	{
		CPrintToChat(client, "%s Cell Opener = Undetected", CLAN_TAG);
	}
	
	if (Entity_IsValid(cell_door))
	{
		CPrintToChat(client, "%s Cell Doors = Detected", CLAN_TAG);
	}
	else
	{
		CPrintToChat(client, "%s Cell Doors = Undetected", CLAN_TAG);
	}
	return Plugin_Handled;
}

public Action:AdminResetPlugin(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	g_CellDoorTimerActive = false;
	g_1stRoundFreeday = false;
	g_bIsLRInUse = false;
	g_bIsWardenLocked = false;
	g_bIsSpeedDemonRound = false;
	
	g_bIsLowGravRound = false;
	for (new i = 1; i <= MaxClients; i++)
	{
		g_RobotRoundClients[i] = false;
		g_IsMuted[i] = false;
		g_IsRebel[i] = false;
		g_IsFreeday[i] = false;
		g_IsFreedayActive[i] = false;
		g_HasTalked[i] = false;
		
	}
	
	Warden = -1;
	enumLastRequests = LR_Disabled;

	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "admin reset plugin");
	return Plugin_Handled;
}

public Action:AdminOpenCells(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (g_IsMapCompatible)
	{
		OpenCells();
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "incompatible map");
	}

	return Plugin_Handled;
}

public Action:AdminCloseCells(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (g_IsMapCompatible)
	{
		CloseCells();
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "incompatible map");
	}
	return Plugin_Handled;
}

public Action:AdminLockCells(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (g_IsMapCompatible)
	{
		LockCells();
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "incompatible map");
	}
	
	return Plugin_Handled;
}

public Action:AdminUnlockCells(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (g_IsMapCompatible)
	{
		UnlockCells();
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "incompatible map");
	}

	return Plugin_Handled;
}

public Action:AdminForceWarden(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (Warden == -1)
	{
		new randomplayer = Client_GetRandom(CLIENTFILTER_TEAMTWO|CLIENTFILTER_ALIVE);
		if (randomplayer)
		{
			WardenSet(randomplayer);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "forced warden", client, randomplayer);
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "current warden", Warden);
	}
	
	return Plugin_Handled;
}

public Action:AdminForceLR(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	LastRequestStart(client);
	
	return Plugin_Handled;
}

public Action:AdminDenyLR(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	g_bIsLRInUse = false;
	g_bIsWardenLocked = false;
	
	enumLastRequests = LR_Disabled;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_RobotRoundClients[i])
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "admin removed robot");
			g_RobotRoundClients[i] = false;
		}
		if (g_IsFreeday[i] || g_IsFreedayActive[i])
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "admin removed freeday");
			g_IsFreeday[i] = false;
			g_IsFreedayActive[i] = false;
		}
	}
	
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "admin deny lr");

	return Plugin_Handled;
}

public Action:AdminPardonFreekiller(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (j_Freekillers)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (g_IsFreekiller[i])
			{
				SetEntityRenderColor(i, 255, 255, 255, 255);
				TF2_RegeneratePlayer(i);
				ServerCommand("sm_beacon #%d", GetClientUserId(i));
				g_IsFreekiller[i] = false;
			}
		}
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "admin pardoned freekillers");
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "freekillers system disabled");
	}
	
	return Plugin_Handled;
}

public Action:AdminGiveFreeday(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}

	new Handle:menu = CreateMenu(MenuHandlerFFAdmin, MENU_ACTIONS_ALL);
	SetMenuTitle(menu,"Choose a Player");
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
	DisplayMenu(menu, client, 20);
	
	return Plugin_Handled;
}

public MenuHandlerFFAdmin(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			decl String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));

			new target = GetClientOfUserId(StringToInt(info));
			if ((target) == 0)
			{
				PrintToChat(param1, "Client is not valid.");
			}
			else if (!CanUserTarget(param1, target))
			{
				PrintToChat(param1, "Cannot target client.");
			}
			else
			{                     
				GiveFreeday(target);
			}
		}
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}  

public Action:BecomeWarden(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}

	if (!j_Warden)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "Warden disabled");
		return Plugin_Handled;
	}
	
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if (!g_1stRoundFreeday || !g_bIsWardenLocked)
	{
		if (Warden == -1)
		{
			if (!g_LockedFromWarden[client])
			{
				if (GetClientTeam(client) == _:TFTeam_Blue)
				{
					if (IsValidClient(client) && IsPlayerAlive(client))
					{
						CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "new warden", client);
						CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "warden message");
						WardenSet(client);
					}
					else
					{
						CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "dead warden");
					}
				}
				else
				{
					CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "guards only");
				}
			}
			else
			{
				CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "voted off of warden");
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "current warden", Warden);
		}
	}
	else
	{
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "warden locked");
	}
	
	return Plugin_Handled;
}

public Action:WardenMenuC(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (client == Warden)
	{
		WardenMenu(client);
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
	}

	return Plugin_Handled;
}

WardenMenu(client)
{
	new Handle:menu = CreateMenu(WardenMenuHandler);
	SetMenuTitle(menu, "Available Warden Commands:");
	AddMenuItem(menu, "1", "Open Cells");
	AddMenuItem(menu, "2", "Close Cells");
	AddMenuItem(menu, "3", "Toggle Friendlyfire");
	AddMenuItem(menu, "4", "Toggle Collision");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
}

public WardenMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			switch (param2)
			{
			case 0:
				{
					FakeClientCommandEx(client, "say /open");
				}
			case 1:
				{
					FakeClientCommandEx(client, "say /close");
				}
			case 2:
				{
					FakeClientCommandEx(client, "say /wff");
				}
			case 3:
				{
					FakeClientCommandEx(client, "say /wcc");
				}
			}
		}
	case MenuAction_Cancel:
		{
			CloseHandle(menu);
		}
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Action:WardenFriendlyFire(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}

	if (client == Warden)
	{
		if (!GetConVarBool(Cvar_FF))
		{
			SetConVarBool(Cvar_FF, true);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "friendlyfire enabled");
			LogMessage("%s %N has enabled friendly fire as Warden.", CLAN_TAG_COLOR, Warden);
		}
		else
		{
			SetConVarBool(Cvar_FF, false);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "friendlyfire disabled");
			LogMessage("%s %N has disabled friendly fire as Warden.", CLAN_TAG_COLOR, Warden);
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
	}

	return Plugin_Handled;
}

public Action:WardenCollision(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (client == Warden)
	{
		if (!GetConVarBool(Cvar_COL))
		{
			SetConVarBool(Cvar_COL, true);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "collision enabled");
			LogMessage("%s %N has enabled collision as Warden.", CLAN_TAG_COLOR, Warden);
		}
		else
		{
			SetConVarBool(Cvar_COL, false);
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "collision disabled");
			LogMessage("%s %N has disabled collision fire as Warden.", CLAN_TAG_COLOR, Warden);
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
	}

	return Plugin_Handled;
}

public Action:ExitWarden(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (client == Warden)
	{
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "warden retired", client);
		PrintCenterTextAll("%t", "warden retired center");
		WardenUnset(client);
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
	}

	return Plugin_Handled;
}

public Action:AdminRemoveWarden(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (Warden != -1)
	{
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "warden fired", client, Warden);
		PrintCenterTextAll("%t", "warden fired center");
		WardenUnset(Warden);
	}
	else
	{
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "no warden current");
	}

	return Plugin_Handled;
}

public Action:OnOpenCommand(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (g_IsMapCompatible)
	{
		if (j_DoorControl)
		{
			if (client == Warden)
			{
				OpenCells();
			}
			else
			{
				CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "door controls disabled");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "incompatible map");
	}

	return Plugin_Handled;
}

public Action:OnCloseCommand(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}

	if (g_IsMapCompatible)
	{
		if (j_DoorControl)
		{
			if (client == Warden)
			{
				CloseCells();
			}
			else
			{
				CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "door controls disabled");
		}
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "incompatible map");
	}

	return Plugin_Handled;
}

public Action:GiveLR(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}

	if (!j_LRSEnabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "lr system disabled");
		return Plugin_Handled;
	}
	
	if (args != 1)
	{
		ReplyToCommand(client, "%s Usage: sm_givelr <player|#userid>", CLAN_TAG_COLOR);
		return Plugin_Handled;
	}

	if (client == Warden)
	{
		if (g_bIsLRInUse)
		{
			new String:arg1[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			
			new target = FindTarget(client, arg1, false, false);
			if (target == -1)
			{
				return Plugin_Handled;
			}
			if (IsValidClient(target) && GetClientTeam(target) == _:TFTeam_Red)
			{
				LastRequestStart(target);
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "last request given", Warden, target);
			}
			else
			{
				CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "last request invalid client");
			}
		}
	}
	else
	{			
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
	}
	
	return Plugin_Handled;
}

public Action:GiveLRMenu(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (j_LRSEnabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "lr system disabled");
		return Plugin_Handled;
	}
	
	if (client == Warden)
	{
		new Handle:menu = CreateMenu(GiveLRMenuHandler, MENU_ACTIONS_ALL);
		SetMenuTitle(menu,"Choose a Player:");
		AddTargetsToMenu2(menu, 0, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
		DisplayMenu(menu, client, 20);
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
	}

	return Plugin_Handled;
}

public GiveLRMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:info[32];
			decl String:Name[32];    
			GetMenuItem(menu, itemNum, info, sizeof(info));     
			new iInfo = StringToInt(info);
			new iUserid = GetClientOfUserId(iInfo);
			GetClientName(iUserid, Name, sizeof(Name));    
			if (GetClientTeam(iUserid) != _:TFTeam_Red)
			{
				PrintToChat(client,"You cannot give LR to a guard or spectator!");
			}
			else
			{
				LastRequestStart(iUserid);
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "last request given", Warden, iUserid);
			}
		}
	}
}  

public Action:RemoveLR(client, args)
{
	if (!j_Enabled)
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "plugin disabled");
		return Plugin_Handled;
	}
	
	if (client == Warden)
	{
		g_bIsLRInUse = false;
		g_bIsWardenLocked = false;
		enumLastRequests = LR_Disabled;
		g_IsFreeday[client] = false;
		g_IsFreedayActive[client] = false;
		CPrintToChat(Warden, "%s %t", CLAN_TAG_COLOR, "warden removed lr");
	}
	else
	{
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "not warden");
	}

	return Plugin_Handled;
}

WardenSet(client)
{
	Warden = client;
	SetClientListeningFlags(client, VOICE_NORMAL);
	if (j_WardenModel)
	{
		SetModel(client, "models/jailbreak/warden/warden_v2.mdl");
	}
	else
	{
		SetEntityRenderColor(client, gWardenColor[0], gWardenColor[1], gWardenColor[2], 255);
	}
	WardenMenu(client);
	Forward_OnWardenCreation(client);
	
	if (j_BlueMute == 1)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Blue && i != Warden)
			{
				MutePlayer(i);
			}
		}
	}
}

WardenUnset(client)
{
	if (Warden != -1)
	{
		Warden = -1;
		if (j_WardenModel)
		{
			RemoveModel(client);
		}
		else
		{
			SetEntityRenderColor(client, 255, 255, 255, 255);
		}
	}
	Forward_OnWardenRemoved(client);
	
	if (j_BlueMute == 1)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Blue && i != Warden)
			{
				UnmutePlayer(i);
			}
		}
	}
}

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client) && client == Warden)
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		SetWearableAlpha(client, 255);
	}
}
public Action:RemoveModel(client)
{
	if (IsValidClient(client))
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		SetWearableAlpha(client, 0);
	}
}

stock SetWearableAlpha(client, alpha, bool:override = false)
{
	if (!override) return 0;
	new count;
	for (new z = MaxClients + 1; z <= 2048; z++)
	{
		if (!IsValidEntity(z)) continue;
		decl String:cls[35];
		GetEntityClassname(z, cls, sizeof(cls));
		if (!StrEqual(cls, "tf_wearable") && !StrEqual(cls, "tf_powerup_bottle")) continue;
		if (client != GetEntPropEnt(z, Prop_Send, "m_hOwnerEntity")) continue;
		SetEntityRenderMode(z, RENDER_TRANSCOLOR);
		SetEntityRenderColor(z, 255, 255, 255, alpha);
		count++;
	}
	return count;
}

OpenCells()
{
	for (new i = 0; i < sizeof(DoorList); i++)
	{
		new String:buffer[60], ent = -1;
		while((ent = FindEntityByClassname(ent, DoorList[i])) != -1)
		{
			GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
			if (StrEqual(buffer, "cell_door", false) || StrEqual(buffer, "cd", false))
			{
				AcceptEntityInput(ent, "Open");
			}
		}
	}
	if (g_CellDoorTimerActive)
	{
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "doors manual open");
		g_CellDoorTimerActive = false;
	}
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "doors opened");
}

CloseCells()
{
	for (new i = 0; i < sizeof(DoorList); i++)
	{
		new String:buffer[60], ent = -1;
		while((ent = FindEntityByClassname(ent, DoorList[i])) != -1)
		{
			GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
			if (StrEqual(buffer, "cell_door", false) || StrEqual(buffer, "cd", false))
			{
				AcceptEntityInput(ent, "Close");
			}
		}
	}
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "doors closed");
}

LockCells()
{
	for (new i = 0; i < sizeof(DoorList); i++)
	{
		new String:buffer[60], ent = -1;
		while((ent = FindEntityByClassname(ent, DoorList[i])) != -1)
		{
			GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
			if (StrEqual(buffer, "cell_door", false) || StrEqual(buffer, "cd", false))
			{
				AcceptEntityInput(ent, "Lock");
			}
		}
	}
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "doors locked");
}

UnlockCells()
{
	for (new i = 0; i < sizeof(DoorList); i++)
	{
		new String:buffer[60], ent = -1;
		while((ent = FindEntityByClassname(ent, DoorList[i])) != -1)
		{
			GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
			if (StrEqual(buffer, "cell_door", false) || StrEqual(buffer, "cd", false))
			{
				AcceptEntityInput(ent, "Unlock");
			}
		}
	}
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "doors unlocked");
}

public Action:InterceptBuild(client, const String:command[], args)
{
	if (!j_Enabled) return Plugin_Continue;

	if (IsValidClient(client) && GetClientTeam(client) == _:TFTeam_Red)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

LastRequestStart(client)
{
	new Handle:LRMenu = CreateMenu(MenuHandlerLR, MENU_ACTIONS_ALL);
	SetMenuTitle(LRMenu, "Last Request Menu");

	AddMenuItem(LRMenu, "0", "Freeday for yourself");
	AddMenuItem(LRMenu, "1", "Freeday for you and others");
	AddMenuItem(LRMenu, "2", "Freeday for all");
	AddMenuItem(LRMenu, "3", "Commit Suicide");
	AddMenuItem(LRMenu, "4", "Guards Melee Only Round");
	AddMenuItem(LRMenu, "5", "HHH Kill Round");
	AddMenuItem(LRMenu, "6", "Low Gravity Round");
	AddMenuItem(LRMenu, "7", "Speed Demon Round");
	AddMenuItem(LRMenu, "8", "Hunger Games");
	if (e_betherobot)	AddMenuItem(LRMenu, "9", "Robotic Takeover");
	AddMenuItem(LRMenu, "10", "Hide & Seek");
	AddMenuItem(LRMenu, "11", "Custom Request");
	
	SetMenuExitButton(LRMenu, true);
	DisplayMenu(LRMenu, client, 30 );
}

public MenuHandlerLR(Handle:LRMenu, MenuAction:action, client, item)
{
	switch(action)
	{
	case MenuAction_Display:
		{
			g_bIsLRInUse = true;
			CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "warden granted lr");
		}
	case MenuAction_Select:
		{
			switch (item)
			{
			case 0:
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr freeday queued", client);
					enumLastRequests = LR_PersonalFreeday;
					g_IsFreeday[client] = true;
				}
			case 1:
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr freeday picking clients", client);
					FreedayforClientsMenu(client);
				}
			case 2:
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr free for all queued", client);
					enumLastRequests = LR_FreedayForAll;
				}
			case 3:
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr suicide", client);
					ForcePlayerSuicide(client);
				}
			case 4:
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr guards melee only queued", client);
					enumLastRequests = LR_GuardsMeleeOnly;
				}
			case 5:
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr hhh kill round queued", client);
					enumLastRequests = LR_HHHKillRound;
				}
			case 6:
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr low gravity round queued", client);
					enumLastRequests = LR_LowGravity;
				}
			case 7:
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr speed demon round queued", client);
					enumLastRequests = LR_SpeedDemon;
				}
			case 8:
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr hunger games queued", client);
					enumLastRequests = LR_HungerGames;
				}
			case 9:
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr robotic takeover queued", client);
					enumLastRequests = LR_RoboticTakeOver;
				}
			case 10:
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr hide and seek queued", client);
					enumLastRequests = LR_HideAndSeek;
				}
			case 11:
				{
					CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr custom message", client);
				}
			}
			g_bIsWardenLocked = true;
		}
	case MenuAction_Cancel:
		{
			g_bIsLRInUse = false;
			CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "last request closed");
		}
	case MenuAction_End:
		{
			CloseHandle(LRMenu);
		}
	}
}

FreedayforClientsMenu(client)
{
	new Handle:menu = CreateMenu(FreedayForClientsMenu_H, MENU_ACTIONS_ALL);

	SetMenuTitle(menu, "Choose a Player");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public FreedayForClientsMenu_H(Handle:menu, MenuAction:action, param1, param2)
{
	new counter = 0;

	switch(action)
	{
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	case MenuAction_Select:
		{
			decl String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			new target = GetClientOfUserId(StringToInt(info));

			if ((target) == 0)
			{
				PrintToChat(param1, "[JODC] %T", "Player no longer available", LANG_SERVER);
			}
			else if (!CanUserTarget(param1, target))
			{
				PrintToChat(param1, "[JODC] %T", "Unable to target", LANG_SERVER);
			}
			else
			{
				g_IsFreeday[target] = true;
				CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr freeday picked clients", param1, target);
				counter++;
				if (IsValidClient(param1) && !IsClientInKickQueue(param1))
				{
					FreedayforClientsMenu(param1);
				}
			}
		}
	}

	if (counter == 3)
	{
		CloseHandle(menu);
		PrintToChat(param1, "You have reached the maximum number of allowed clients for Freeday.");
	}
}

GiveFreeday(client)
{
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	SetEntityRenderColor(client, gFreedayColor[0], gFreedayColor[1], gFreedayColor[2], 255);
	CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "lr freeday message");
	new flags = GetEntityFlags(client)|FL_NOTARGET;
	SetEntityFlags(client, flags);
	ServerCommand("sm_evilbeam #%d", GetClientUserId(client));
	g_IsFreeday[client] = false;
	g_IsFreedayActive[client] = true;
}

RemoveFreeday(client)
{
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "lr freeday lost", client);
	PrintCenterTextAll("%t", "lr freeday lost center", client);
	new flags = GetEntityFlags(client)&~FL_NOTARGET;
	SetEntityFlags(client, flags);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	ServerCommand("sm_evilbeam #%d", GetClientUserId(client));
	g_IsFreedayActive[client] = false;
}

stock ResetPlayerSpeed()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsPlayerAlive(i)) continue;
		new TFClassType:class = TF2_GetPlayerClass(i);
		switch(class)
		{
		case TFClass_DemoMan: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 280.0);
		case TFClass_Engineer: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 300.0);
		case TFClass_Heavy: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 230.0);
		case TFClass_Medic: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 320.0);
		case TFClass_Pyro: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 300.0);
		case TFClass_Scout: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 400.0);
		case TFClass_Sniper: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 300.0);
		case TFClass_Soldier: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 240.0);
		case TFClass_Spy: SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 300.0);
		}
	}
}

public Action:EnableFFTimer(Handle:timer)
{
	SetConVarBool(Cvar_FF, true);
}

MarkRebel(client)
{
	g_IsRebel[client] = true;
	SetEntityRenderColor(client, gRebelColor[0], gRebelColor[1], gRebelColor[2], 255);
	CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "prisoner has rebelled", client);
	if (j_RebelsTime >= 1.0)
	{
		new time = RoundFloat(j_RebelsTime);
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "rebel timer start", time);
		CreateTimer(j_RebelsTime, RemoveRebel, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:RemoveRebel(Handle:timer, any:client)
{
	if (IsValidClient(client) && GetClientTeam(client) != 1 && IsPlayerAlive(client))
	{
		g_IsRebel[client] = false;
		SetEntityRenderColor(client, 255, 255, 255, 255);
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "rebel timer end");
	}
}

MarkFreekiller(client)
{
	g_IsFreekiller[client] = true;
	TF2_RemoveAllWeapons(client);
	ServerCommand("sm_beacon #%d", GetClientUserId(client));
	EmitSoundToAll("ui/system_message_alert.wav", _, _, _, _, 1.0, _, _, _, _, _, _);
	if (j_FreekillersWave >= 1.0)
	{
		new time = RoundFloat(j_FreekillersWave);
		CPrintToChatAll("%s %t", CLAN_TAG_COLOR, "freekiller timer start", client, time);

		decl String:sAuth[24];
		new Handle:hPack;
		new Handle:hTimer = CreateDataTimer(j_FreekillersWave, BanClientTimerFreekiller, hPack);
		WritePackCell(hPack, client);
		WritePackCell(hPack, GetClientUserId(client));
		WritePackString(hPack, sAuth);
		PushArrayCell(hPack, hTimer);
	}
}

public Action:BanClientTimerFreekiller(Handle:timer, Handle:hPack)
{
	new iPosition;
	if ((iPosition = FindValueInArray(g_hArray_Pending, timer) != -1))
	RemoveFromArray(g_hArray_Pending, iPosition);

	ResetPack(hPack);
	new client = ReadPackCell(hPack);
	new userid = ReadPackCell(hPack);
	new String:sAuth[24];
	ReadPackString(hPack, sAuth, sizeof(sAuth));

	switch (j_FreekillersAction)
	{
	case 0:
		{
			if (IsValidClient(client))
			{
				g_IsFreekiller[client] = false;
				TF2_RegeneratePlayer(client);
				ServerCommand("sm_beacon #%d", GetClientUserId(client));
			}
		}
	case 1:
		{
			if (IsValidClient(client))
			{
				ForcePlayerSuicide(client);
				g_IsFreekiller[client] = false;
			}
		}
	case 2:
		{
			if (GetClientOfUserId(userid))
			{
				decl String:BanMsg[100];
				GetConVarString(JB_Cvar_Freekillers_BanMSG, BanMsg, sizeof(BanMsg));
				if (e_sourcebans) SBBanPlayer(0, client, 60, "Client has been marked for Freekilling.");
				else if (e_basebans) BanClient(client, j_FreekillersBantime, BANFLAG_AUTHID, "Client has been marked for Freekilling.", BanMsg, "freekillban", client);
			}
			else
			{
				decl String:BanMsgDC[100];
				GetConVarString(JB_Cvar_Freekillers_BanMSGDC, BanMsgDC, sizeof(BanMsgDC));
				BanIdentity(sAuth, j_FreekillersBantimeDC, BANFLAG_AUTHID, BanMsgDC);
			}
		}
	}
}

MapCheck()
{
	new open_cells = Entity_FindByName("open_cells", "func_button");
	new cell_door = Entity_FindByName("cell_door", "func_door");
	if (Entity_IsValid(open_cells) && Entity_IsValid(cell_door))
	{
		g_IsMapCompatible = true;
		LogMessage("%s The current map has passed all compatibility checks, plugin may proceed.", CLAN_TAG);
	}
	else
	{
		g_IsMapCompatible = false;
		LogError("The current map is incompatible with this plugin. Please verify the map or change it.");
		LogError("Feel free to type !compatible in chat to check the map manually.");
	}
}

stock MutePlayer(client)
{
	if (!AlreadyMuted(client) && !Client_HasAdminFlags(client, ADMFLAG_RESERVATION|ADMFLAG_RESERVATION) && !g_IsMuted[client])
	{
		Client_Mute(client);
		g_IsMuted[client] = true;
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "muted player");
	}
}

stock UnmutePlayer(client)
{
	if (!AlreadyMuted(client) && !Client_HasAdminFlags(client, ADMFLAG_RESERVATION|ADMFLAG_RESERVATION) && g_IsMuted[client])
	{
		Client_UnMute(client);
		g_IsMuted[client] = false;
		CPrintToChat(client, "%s %t", CLAN_TAG_COLOR, "unmuted player");
	}
}

stock bool:AlreadyMuted(client)
{
	if (e_sourcecomms)
	{
		if (SourceComms_GetClientMuteType(client) == bNot) return false;
		else return true;
	}
	else if (e_basecomm)
	{
		if (!BaseComm_IsClientMuted(client)) return false;
		else return true;
	}
	return false;
}

stock AddServerTag2(const String:tag[])
{
	new Handle:hTags = INVALID_HANDLE;
	hTags = FindConVar("sv_tags");
	if (hTags != INVALID_HANDLE)
	{
		decl String:tags[256];
		GetConVarString(hTags, tags, sizeof(tags));
		if (StrContains(tags, tag, true) > 0) return;
		if (strlen(tags) == 0)
		{
			Format(tags, sizeof(tags), tag);
		}
		else
		{
			Format(tags, sizeof(tags), "%s,%s", tags, tag);
		}
		SetConVarString(hTags, tags, true);
	}
}

stock RemoveServerTag2(const String:tag[])
{
	new Handle:hTags = INVALID_HANDLE;
	hTags = FindConVar("sv_tags");
	if (hTags != INVALID_HANDLE)
	{
		decl String:tags[50];
		GetConVarString(hTags, tags, sizeof(tags));
		if (StrEqual(tags, tag, true))
		{
			Format(tags, sizeof(tags), "");
			SetConVarString(hTags, tags, true);
			return;
		}
		new pos = StrContains(tags, tag, true);
		new len = strlen(tags);
		if (len > 0 && pos > -1)
		{
			new bool:found;
			new String:taglist[50][50];
			ExplodeString(tags, ",", taglist, sizeof(taglist[]), sizeof(taglist));
			for (new i; i < sizeof(taglist[]); i++)
			{
				if (StrEqual(taglist[i], tag, true))
				{
					Format(taglist[i], sizeof(taglist), "");
					found = true;
					break;
				}
			}
			if (!found) return;
			ImplodeStrings(taglist, sizeof(taglist[]), ",", tags, sizeof(tags));
			if (pos == 0)
			{
				tags[0] = 0x20;
			}
			else if (pos == len-1)
			{
				Format(tags[strlen(tags)-1], sizeof(tags), "");
			}
			else
			{
				ReplaceString(tags, sizeof(tags), ",,", ",");
			}
			SetConVarString(hTags, tags, true);
		}
	}
}

stock IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetEntProp(client, Prop_Send, "m_bIsCoaching") || IsFakeClient(client) || !IsValidEntity(client))
	{
		return false;
	}
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}

stock SetClip(client, wepslot, newAmmo, admin)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	if (IsValidEntity(weapon))
	{
		new iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
		SetEntData(weapon, iAmmoTable, newAmmo, 4, true);
	}
}

stock SetAmmo(client, wepslot, newAmmo, admin)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, newAmmo, 4, true);
	}
}

stock ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
	}
	timer = INVALID_HANDLE;
}

public bool:WardenGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && Warden != -1 && i == Warden)
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:NotWardenGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && Warden != -1 && i != Warden)
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:RebelsGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && g_IsRebel[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:NotRebelsGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && !g_IsRebel[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:FreedaysGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && g_IsFreeday[i] || IsValidClient(i) && g_IsFreedayActive[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool:NotFreedaysGroup(const String:strPattern[], Handle:hClients)
{
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsValidClient(i) && !g_IsFreeday[i] || IsValidClient(i) && !g_IsFreedayActive[i])
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}


public Native_ExistWarden(Handle:plugin, numParams)
{
	if (Warden != -1) return true;
	return false;
}

public Native_IsWarden(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
	ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (client == Warden) return true;
	return false;
}

public Native_SetWarden(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
	ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (Warden == -1) WardenSet(client);
}

public Native_RemoveWarden(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
	ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (client == Warden) WardenUnset(client);
}

public Native_IsFreeday(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
	ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (g_IsFreeday[client] || g_IsFreedayActive[client]) return true;
	return false;
}

public Native_GiveFreeday(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
	ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (!g_IsFreeday[client] || !g_IsFreedayActive[client]) GiveFreeday(client);
}

public Native_IsRebel(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
	ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (g_IsRebel[client]) return true;
	return false;
}

public Native_MarkRebel(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
	ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (!g_IsRebel[client]) MarkRebel(client);
}

public Native_IsFreekiller(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
	ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (g_IsFreekiller[client]) return true;
	return false;
}

public Native_MarkFreekill(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
	ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if (!g_IsFreekiller[client]) MarkFreekiller(client);
}

public Forward_OnWardenCreation(client)
{
	Call_StartForward(g_fward_onBecome);
	Call_PushCell(client);
	Call_Finish();
}

public Forward_OnWardenRemoved(client)
{
	Call_StartForward(g_fward_onRemove);
	Call_PushCell(client);
	Call_Finish();
}