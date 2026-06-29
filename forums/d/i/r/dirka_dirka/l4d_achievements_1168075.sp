#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
//#include <sdkhooks> - use this for jump shot if hunter head shot event doesnt ever fire
#include <colors>

#define		PLUGIN_VERSION		"1.3"
/* *************************************
	*	Plugin: Selected Achievements
	*
	*	Version History:
	*	1.0		Initial Release based upon http://forums.alliedmods.net/showthread.php?t=125326
	*			Wasn't a separate plugin at this stage
	*	1.1		Improved chat display (each person gets their own)
	*			Added Colors.inc (see above for reason)
	*			Made into seperate plugin (was part of a custom announcement plugin that isn't posted)
	*	1.2		Changed from a single achievement announcement to multiple achievements.
	*			Added Boomer: Barf Bagged
	*			Added Tank: Man Vs Tank, Kite Like a Man & Tank Burger
	*			Fixed some minor coding issues.
	*	1.2a	Moved _Module_Enabled to OnPluginStart() - from OnConfigsExecuted()..
	*			- Think this is what caused the multiple event triggers that was the result of the above rewrite
	*	1.2b	Fixed(?) tank_index going out of bounds (over time) when tanks don't die and the round ends.
	*			- by adding a Rebuild_TankIndex at round start - should flush out any lost tanks.
	*			Also, rewrote Rebuild_TankIndex() - same issue as above & to account for glitches
	*			- incase the game reports the same tank spawn multiple times (which is what was happening before 1.2a)
	*	1.2.1	** Not released **
	*			Added Tank: Tankbusters
	*			Added Charger: Scattering Ram & Meat Tenderizer
	*			Changed [Level] to [Charger]
	*			Added Jockey: Qualified Ride, A Ride Denied & Back in the Saddle
	*			Added Generic: Stache Whacker, Gong Show
	*	1.3		Fairly significant re-write of much of the core code to accomodate the new features
	*			Started work on Untouchables, Safety First & any other campaign based achievement
	*			Added Translations
	*			Added convar to allow/disable L4D1 achievements to be displayed in L4D2.
	*			Added convar for a generic message option
	*			Added Charger: Long Distance Carrier & started work on Wedding Crasher (when done, it will be every charger achievement).
	*			Added Tank: All 4 Dead
	*			Added Boomer: Clean Kill, Blind Luck
	*			Added Hunter: Hunter Punter, Dead Stop, Jump Shot
	*			Added another check for tank_index not resetting (when you kick the tank).
	*			Removed MAX_TANKS, changed it to MAXPLAYERS+1 (tanks are players after all)
	*			Added info on EVERY achievement..
	*			Added 3 commands for achievements, 1 is admin:
	*			- sm_achievement <achievement> = lists info about an achievement
	*			- sm_my_achievement <achievement> = lists personal info about an achievement (progress, completed, etc)
	*			- sm_set_achievement [list|never|once|game|map|life|always] <Achievement> = with list, it is similar to sm_achievement, all other options set the report frequency on the server
	*			Got rid of some global handle variables
	*			Added hooks to the convars
	*			Added config file
	*
	*	To Do:
	*		Blind Luck is not finished yet.
	*		Hunter Punter doesnt work - need to adjust how it is detected
	*		Finish Safety First, Untouchables, Wedding Crasher.
	*		Considering changing [Charger], [Tank] and [Boomer] (and any future tags) to [Award]
	*		Maybe: allow boomers to get barf bagged by explosion.
	*
	*** */
#define		TAG_DEBUG			"[Debug]"
#define		TAG_CMD				"[Award]"
#define		TAG_AWARD			"{lightgreen}[Award]{default}"
#define		TAG_BOOMER			"{lightgreen}[Boomer]{default}"
#define		TAG_HUNTER			"{lightgreen}[Hunter]{default}"
#define 	TAG_CHARGER		"{lightgreen}[Charger]{default}"
#define		TAG_JOCKEY			"{lightgreen}[Jockey]{default}"
#define		TAG_TANK			"{lightgreen}[Tank]{default}"

#define		MSG_SIZE			256

#define		NEG_T_INFECTED		-3
#define		NEG_T_SURVIVORS	-2
#define		NEG_T_SPECTATORS	-1
#define		TEAM_UNSPECIFIED	0
#define		TEAM_SPECTATORS	1
#define		TEAM_SURVIVORS		2
#define		TEAM_INFECTED		3

// not 100% certain on all the numbers below..
#define		ZOMBIECLASS_UNKNOWN	-1
#define		ZOMBIECLASS_SMOKER		1
#define		ZOMBIECLASS_BOOMER		2
#define		ZOMBIECLASS_HUNTER		3
static		ZOMBIECLASS_WITCH;		// This value varies depending on which L4D game it is.. 4 or 7
static		ZOMBIECLASS_TANK;		// This value varies depending on which L4D game it is.. 5 or 8
#define		ZOMBIECLASS_SPITTER	4
#define		ZOMBIECLASS_JOCKEY		5
#define		ZOMBIECLASS_CHARGER	6
//#define	ZOMBIECLASS_OTHER		9		// this is a survivor or a ci

static	bool:	g_bEnabled;
static	bool:	g_bLogToChat;
static	bool:	g_bLogToFile;
static	bool:	g_bUseL4D1inL4D2;
static	bool:	g_bUseGenericMessage;

static	String:	g_sZDifficulty[12]		=	"Impossible";

static	Handle:	g_hTimer__Ability[MAXPLAYERS+1]			=			{ INVALID_HANDLE, ... };
static	Handle:	g_hTimer__CleanKill[MAXPLAYERS+1][MAXPLAYERS+1];

enum		g_eClientData	{
	bool:	b_isPukedOn,			// Did this client get puked on?
	bool:	b_isBiledOn,			// or did this client get covered in bile
			Puker_Id,				// & Who puked/biled on this client
	bool:	b_isFrustrated,		// Is this client a frustrated tank?
			Frustrated_index,		// & the tank_index value of this tank (to replace once new tank spawns)
	bool:	b_isPounced,			// Is this client being pounced
			Pouncer_Id,			// & who is doing the pouncing
			Rider_Id,				// Who is the jockey that is riding this mule?
			PrevMule_Id,			// As a jockey, victim of previous ride
			CurMule_Id,			// & victim of current ride
	bool:	b_isImpacted,			// Has a charger impacted this client?
			Impactor_Id,			// & Who is the Charger that collided with the client?
	bool:	b_isCarried,			// &/or Is this client being carried by a charger?
			Carrier_Id,			// & Who is the Charger that is carrying this client?
	Float:	f_CarryStartX,			// Origin of starting point of a 'Carry'
	Float:	f_CarryStartY,			// MD array in an MD array - pawn says no way!
	Float:	f_CarryStartZ,			// see above
	bool:	b_isPummeled,			// &/or Is this client being pummelled by a charger?
			Pummeler_Id,			// & Who is the Charger that is pummeling this client?
	bool:	b_isShoved,			// Has this player been shoved?
			Shoved_Id,				// & the client who did the shoving.
	bool:	b_isDead,				// Is this client dead?
			Killer_Id				// & Who Killed this client.
}
static			g_eClientInfo[MAXPLAYERS+1][g_eClientData];

// Boomer
static	Handle:	g_hBoomerVomitDelay			=	INVALID_HANDLE;
static	Float:	g_fBoomerVomitDelay;
static	Handle:	g_hZVomitDuration			=	INVALID_HANDLE;
static	Float:	g_fZVomitDuration;
static	Handle:	g_hSurvivorItDuration		=	INVALID_HANDLE;
static	Float:	g_fSurvivorItDuration;								// this is probably an int, but i use it for a timer duration
static	Handle:	g_hZExplodingShoveInterval	=	INVALID_HANDLE;
static	Float:	g_fZExplodingShoveInterval;
// Tank
#define		ALL_TANKS		-1
enum		g_eTankIndex_Info	{
	bool:	TankHasHurt,		// Has this tank hurt anyone? For Tankbusters
			//DamageCache[MAXPLAYERS+1],	// How much damage has the tank done to each client
			userid				// The userid of each tank in the index (not client #)
}
static			g_eTankIndex[MAXPLAYERS+1][g_eTankIndex_Info];
// Jockey
static	Handle:	g_hTimer__JockeyRide[MAXPLAYERS+1]	=	{ INVALID_HANDLE, ... };
// Charger
static	Handle:	g_hZChargeDuration	=	INVALID_HANDLE;
static	Float:	g_fZChargeDuration;
static	Handle:	g_hTimer__Pummel[MAXPLAYERS+1]		=	{ INVALID_HANDLE, ... };
// Hunter
static	Handle:	g_hTimer__PunchedOut[MAXPLAYERS+1]	=	{ INVALID_HANDLE, ... };

#define		MELEE_NAME_SIZE	24		// must be at least the size of largest s_WeaponName.. +1
#define		MELEE_DESC_SIZE	36		// must be at least the size of largest s_WeaponDesc.. +1
static		MELEE_ALL;
enum		g_eMeleeWeapons	{
	unknown,			// if a weapon cannot be detected, default to this
	baseball_bat,
	cricket_bat,
	crowbar,
	electric_guitar,
	fireaxe,
	frying_pan,
	katana,
	machete,
	tonfa,
	golfclub,			// these 3(4) dont count as 'all'
	knife,
	hunting_knife,		// work-around most (if not all) plugins have used to enable the knife
	riotshield
}
enum		g_eMeleeData		{
	String:	s_WeaponName[MELEE_NAME_SIZE],	// the ingame name. eg: baseball_bat
	String:	s_WeaponDesc[MELEE_DESC_SIZE],	// what to print. eg: a baseball bat (in color)
			flag								// not used here.. yet
}
static			g_eMeleeInfo[g_eMeleeWeapons][g_eMeleeData];

#define		UCI_NAME_SIZE		16
static		UCI_ALL;				// This is all the uci required for crass menagerie
enum		g_eUCITypes		{
	Ceda,
	Clown,
	Mudman,
	Roadcrew,
	Riot,
	JimmyGibbs,
	Fallen
}
enum		g_eUCIData		{
	String:	s_Name[UCI_NAME_SIZE],
			flag
}
static			g_eUncommonInfo[g_eUCITypes][g_eUCIData];
#define		CAMP_NAME_SIZE		16
static		CAMP_WAYTTP_L4D1;			// The list of campaigns for "What Are You Trying To Prove"
static		CAMP_ALL_L4D1;				// All L4D1 Campaigns
static		CAMP_SSTP_L4D2;			// The list of campaigns for "Still Something To Prove"
static		CAMP_ALL_L4D2;				// All L4D2 Campaigns
static		CAMP_ALL;					// All campaigns for L4D1 & L4D2
enum		g_eCampaigns	{
	Blood_Harvest,
	Dead_Air,
	Death_Toll,
	No_Mercy,
	Crash_Course,
	Dead_Center,
	Dark_Carnival,
	Swamp_Fever,
	Hard_Rain,
	The_Parish,
	The_Passing
}
enum		g_eCampaignData		{
	String:	s_Name[CAMP_NAME_SIZE],
			flag
}
static			g_eCampaignInfo[g_eCampaigns][g_eCampaignData];
static	bool:	g_bFinaleStarted;
static	bool:	g_bIsL4D2;

// The below are used for g_eAchievementData[L4D1or2]
#define		GAME_L4D1		1
#define		GAME_L4D2		2
#define		GAME_L4D12		3
/*
	The below are used for g_eAchievementData[ReportFrequency]
	For achievements that are not g_eAchievementData[b_IsRepeatable],
	values above REPORT_ONCE are essentially REPORT_ONCE_PER_GAME
	REPORT_DISABLED is internal to the source and means I haven't added any code to track it
	-Changing that could result in errors.. or confusion
	REPORT_NEVER is how an admin can disable tracking with the command
*/
#define		REPORT_DISABLED		-1		// There is no achievement tracking for this
#define		REPORT_NEVER			0		// This achievement will never be reported
#define		REPORT_ONCE			1		// This achievement will only be reported ONCE - EVER (per player) on the server - until reset
#define		REPORT_ONCE_PER_GAME	2		// This achievement will only be reported ONCE PER CONNECTION/CAMPAIGN
#define		REPORT_ONCE_PER_MAP	3		// This achievement will only be reported once every map
#define		REPORT_ONCE_PER_LIFE	4		// This achievement will only be reported once per life (eg: back in the saddle wont trigger again until next respawn)
#define		REPORT_ALWAYS			5		// This achivement will ALWAYS be reported when it is earned

#define		FOR_EACH_ACHIEVEMENT(%1)					\
	for (new %1 = 0; %1 < sizeof(g_eAchievementInfo); %1++)

enum		g_eAchievements		{
	UNDEFINED_ALL						= -1,
	A_Ride_Denied						= 0,
	A_Spittle_Help_From_My_Friends,
	Acid_Reflex,
	Akimbo_Assassin,
	All_4_Dead,
	Armory_Of_One,
	Back_2_Help,
	Back_In_The_Saddle,
	Barf_Bagged,
	Beat_The_Rush,
	Big_Drag,
	Blind_Luck,
	Brain_Salad,
	Bridge_Burner,
	Bridge_Over_Trebled_Slaughter,
	Bronze_Mettle,
	Burn_The_Witch,
	Burning_Sensation,
	Cache_And_Carry,
	Cache_Grab,
	Chain_Of_Command,
	Chain_Smoker,
	Cl0wned,
	Clean_Kill,
	Club_Dead,
	Confederacy_Of_Crunches,
	Cr0wnd,
	Crash_proof,
	Crass_Menagerie,
	Dead_Baron,
	Dead_Giveaway,
	Dead_In_The_Water,
	Dead_Stop,
	Dead_Wreckening,
	Dismemberment_Plan,
	Distinguished_Survivor,
	Do_Not_Disturb,
	Double_Jump,
	Drag_And_Drop,
	Field_Medic,
	Fore,
	Fried_Piper,
	Fuel_Crisis,
	Gas_Guzzler,
	Gas_Shortage,
	Guardin_Gnome,
	Gong_Show,
	Grave_Robber,
	Great_Expectorations,
	Grim_Reaper,
	Ground_Cover,
	Head_Honcho,
	Heartwarmer,
	Helping_Hand,
	Hero_Closet,
	Heroic_Survivor,
	Hunter_Punter,
	Hunting_Party,
	Jump_Shot,
	Jumpin_Jack_Smash,
	Kill_Them_Swiftly_To_This_Song,		// was too long.. should be 'Killing'
	Kite_Like_A_Man,
	Lamb_2_Slaughter,
	Last_Stand,
	Legendary_Survivor,
	Level_A_Charge,
	Long_Distance_Carrier,
	Man_Vs_Tank,
	Meat_Tenderizer,
	Mercy_Killer,
	Midnight_Rider,
	Mutant_Overlord,
	My_Bodyguard,
	No_one_Left_Behind,
	No_Smoking_Section,
	Nothing_Special,
	One_Hundred_One_Cremations,
	Outbreak,
	Pharm_assist,
	Port_Of_Scavenge,
	Price_Chopper,
	Pyrotechnician,
	Qualified_Ride,
	Quick_Power,
	Ragin_Cajun,
	Red_Mist,
	Robbed_Zombie,
	Rode_Hard_Put_Away_Wet,
	Safety_First,
	Scattering_Ram,
	Scavenger_Hunt,
	Septic_Tank,
	Shock_Jock,
	Silver_Bullets,
	Slippery_Pull,
	Smash_Hit,
	Sob_Story,
	Spinal_Tap,
	Stache_Whacker,
	Stand_Tall,
	Still_Something_To_Prove,
	Stomach_Upset,
	Strength_In_Numbers,
	Tank_Burger,
	Tank_Stumble,
	Tankbusters,
	The_Littlest_Genocide,
	The_Quick_And_The_Dead,
	The_Real_Deal,
	Til_It_Goes_Click,
	Toll_Collector,
	Tongue_Twister,
	Torch_Bearer,
	Towering_Inferno,
	Truck_Stop,
	Twenty_Car_Pile_up,
	Unbreakable,
	Untouchables,
	Violence_In_Silence,
	Violence_Is_Golden,
	Weatherman,
	Wedding_Crasher,
	What_Are_You_Trying_To_Prove,
	Wing_And_A_Prayer,
	Wipefest,
	Witch_Hunter,
	Zombicidal_Maniac,
	Zombie_Genocidest
}
#define		SIZE_NAME		64
#define		NO_TOTAL		-1
enum		g_eAchievementData	{
	String:	s_Name[SIZE_NAME],		// The name as Valve worded it (looked up in translation file)
			L4D1or2,				// Is it L4D1 or 2 or both
	bool:	b_IsRepeatable,		// Can this achievement be earned multiple times per map/campaign
			ReportFrequency,		// How often can this achievement be 'earned'
			Total,					// How much 'Count' to complete this achievement?
	String:	s_Desc[SIZE_NAME]		// The description as written by Valve - this is the string used in translation file
}
static			g_eAchievementInfo[g_eAchievements][g_eAchievementData];
enum		g_eClientAchievementData	{
			Target_Id,			// attacker or victim, depending on achievement
	bool:	b_IsCompleted,		// already got this achievement?
	bool:	b_IsPrevented,		// already blew this achievement? (per-map or per-campaign)
			Count				// progress towards achievement
}
static			g_eAchievementStatus[MAXPLAYERS+1][g_eAchievements][g_eClientAchievementData];

public Plugin:myinfo = {
	name			=	"[L4D] Selected Achievements",
	author			=	"Dirka_Dirka",
	description	=	"Displays a message when someone qualifies for an achievement.",
	version			=	PLUGIN_VERSION,
	url				=	"http://forums.alliedmods.net/showthread.php?t=125808"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	// Require Left 4 Dead
	decl String:game_name[12];
	GetGameFolderName(game_name, sizeof(game_name));
	if (StrEqual(game_name, "left4dead2", false)) {
		g_bIsL4D2 = true;
		ZOMBIECLASS_WITCH = 7;
		ZOMBIECLASS_TANK = 8;
	} else if (StrEqual(game_name, "left4dead", false)) {
		g_bIsL4D2 = false;
		ZOMBIECLASS_WITCH = 4;
		ZOMBIECLASS_TANK = 5;
	} else {
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart() {
	CreateConVar(
		"l4d_achievements_ver", PLUGIN_VERSION,
		"Version of the Selected Achievements plugin.",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD );
	
	new Handle:Enabled = CreateConVar(
		"l4d_achievements_enable", "1",
		"Toggles the plugin, which turns off or off the Achievement related messages.",
		FCVAR_PLUGIN|FCVAR_NOTIFY,
		true, 0.0, true, 1.0 );
	g_bEnabled = GetConVarBool(Enabled);
	HookConVarChange(Enabled, ConVarChange__Enable);
	
	// These 2 are for debugging purposes.. as such, they are "hidden".
	new Handle:DebugLogToChat = CreateConVar(
		"l4d_achievements_debug", "0",
		"Prints chat messages for 'live' log info.",
		FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD,
		true, 0.0, true, 1.0 );
	g_bLogToChat = GetConVarBool(DebugLogToChat);
	HookConVarChange(DebugLogToChat, ConVarChange__LogToChat);
	new Handle:DebugLogToFile = CreateConVar(
		"l4d_achievements_debuglog", "0",
		"Logs all debugging info.",
		FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD,
		true, 0.0, true, 1.0 );
	g_bLogToFile = GetConVarBool(DebugLogToFile);
	HookConVarChange(DebugLogToFile, ConVarChange__LogToFile);
	
	if (g_bIsL4D2) {
		new Handle:UseL4D1inL4D2 = CreateConVar(
			"l4d_achievements_l4d1inl4d2", "1",
			"Toggles the allowance of L4D1 achievements to be tracked/displayed in L4D2. Does nothing if the game is not L4D2.",
			FCVAR_PLUGIN|FCVAR_NOTIFY,
			true, 0.0, true, 1.0 );
		g_bUseL4D1inL4D2 = GetConVarBool(UseL4D1inL4D2);
		HookConVarChange(UseL4D1inL4D2, ConVarChange__UseL4D1inL4D2);
	}
	
	new Handle:UseGenericMessage = CreateConVar(
		"l4d_achievements_usegeneric", "0",
		"Toggles the use of generic messages (every achievement message is the same), or custom ones.",
		FCVAR_PLUGIN|FCVAR_NOTIFY,
		true, 0.0, true, 1.0 );
	g_bUseGenericMessage = GetConVarBool(UseGenericMessage);
	HookConVarChange(UseGenericMessage, ConVarChange__UseGenericMessage);
	
	// game convars..
	g_hBoomerVomitDelay = FindConVar("boomer_vomit_delay");
	g_hZVomitDuration = FindConVar("z_vomit_duration");
	g_hSurvivorItDuration = FindConVar("survivor_it_duration");
	g_hZExplodingShoveInterval = FindConVar("z_exploding_shove_interval");
	if (g_bIsL4D2) {
		g_hZChargeDuration = FindConVar("z_charge_duration");
	}
	
	new Handle:ZDifficulty = FindConVar("z_difficulty");
	GetConVarString(ZDifficulty, g_sZDifficulty, sizeof(g_sZDifficulty));
	HookConVarChange(ZDifficulty, ConVarChange__ZDifficulty);
	
	RegConsoleCmd("sm_achievement",	_Command__Get_Achievement,					"Get information about achievements");
	RegConsoleCmd("sm_my_achievement",	_Command__My_Achievement,						"Get information about progress on achievements");
	RegAdminCmd("sm_set_achievement",	_Command__Set_Achievement,	ADMFLAG_ROOT,	"Set tracking information for achievements");
	
	AutoExecConfig(true, "plugin.l4d.achievements");
	LoadTranslations("achievement.phrases.txt");
	// Initialize things..
	_Init();
	if (g_bEnabled)
		_ModuleEnabled();
	
	// this is to remove a warning until im ready to use it..
	if (ZOMBIECLASS_WITCH == 7) {
		// blargh
	}
}

public Action:_Command__My_Achievement(client, args) {
	if (args == 0) {
		ReplyToCommand(client, "%s Usage: sm_my_achievement <Achievement>.", TAG_CMD);
		return;
	}
	
	decl String:arg[SIZE_NAME];
	GetCmdArgString(arg, sizeof(arg));
	
	new achievement = FindAchievement(arg);
	if (achievement == -1) {
		ReplyToCommand(client, "%s '%s' is not a valid achievement.", TAG_CMD, arg);
		return;
	}
	if (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_DISABLED) {
		ReplyToCommand(client, "%s Achievement '%s' is not tracked.", TAG_CMD, g_eAchievementInfo[achievement][s_Name]);
		return;
	}
	
	ReplyToCommand(client, "%s This command is under construction", TAG_CMD);
	return;
	/*
	ReplyToCommand(client, "%s Settings for Achievement '%s':\n[ Desc: %s", TAG_CMD,
		g_eAchievementInfo[achievement][s_Name],
		g_eAchievementInfo[achievement][s_Desc] );
	ReplyToCommand(client, "[ Game: %s, Repeatable?: %s\n[ Report Freq: %s",
		((g_eAchievementInfo[achievement][L4D1or2] == GAME_L4D1) ? "L4D1"
		: (g_eAchievementInfo[achievement][L4D1or2] == GAME_L4D2) ? "L4D2"
		: "L4D1+2"),
		(g_eAchievementInfo[achievement][b_IsRepeatable] ? "Yes" : "No"),
		((g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ALWAYS) ? "Every Time"
		: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE_PER_LIFE) ? "Once per spawn"
		: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE_PER_MAP) ? "Once per map"
		: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE_PER_GAME) ? "Once per campaign / game session"
		: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE) ? "Once - just like how Valve does it"
		: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_NEVER) ? "Never - achievement has been disabled by admin"
		: "Never - achievement can not be tracked" ));
	if (g_eAchievementInfo[achievement][Total] != NO_TOTAL) {
		ReplyToCommand(client, "[ Amount required to earn: %d", g_eAchievementInfo[achievement][Total]);
	}
	*/
	
/*
static bool:DisplayAchievement(client, g_eAchievements:Achievement = UNDEFINED_ALL) {
	if ((Achievement < UNDEFINED_ALL) || (Achievement >= sizeof(g_eAchievements))) {
		DebugPrintToAll("Error: Trying to display an invalid Achievement: %i (on client %i)", Achievement, client);
		return false;
	}
	if ((client < 1) || (client > MaxClients)) {
		DebugPrintToAll("Error: Trying to display an achievement to an invalid client %i", client);
		return false;
	}
	if (Achievement == UNDEFINED_ALL) {
		for (new i=0; i<sizeof(g_eAchievements); i++) {
			switch (g_eAchievementInfo[i][L4D1or2]) {
				case GAME_L4D1: {
					if (g_bIsL4D2)
						continue;
				}
				case GAME_L4D2: {
					if (!g_bIsL4D2)
						continue;
				}
				case GAME_L4D12: {
					if (g_bIsL4D2 && !g_bUseL4D1inL4D2)
						continue;
				}
			}
			
			if (g_eAchievementStatus[client][i][b_IsCompleted]) {
			} else if (g_eAchievementStatus[client][i][b_IsPrevented]) {
			} else if ((g_eAchievementInfo[i][Total] != NO_TOTAL)
					&& (g_eAchievementStatus[client][i][Count] > 0)) {
			}
		}
	} else {
		if (g_eAchievementStatus[client][Achievement][b_IsCompleted]) {
		} else if (g_eAchievementStatus[client][Achievement][b_IsPrevented]) {
		} else if ((g_eAchievementInfo[Achievement][Total] != NO_TOTAL)
				&& (g_eAchievementStatus[client][Achievement][Count] > 0)) {
		}
	}
}
*/
}

public Action:_Command__Get_Achievement(client, args) {
	if (args == 0) {
		ReplyToCommand(client, "%s Usage: sm_achievement [Achievement].", TAG_CMD);
		return;
	}
	
	decl String:arg[SIZE_NAME];
	GetCmdArgString(arg, sizeof(arg));
	
	new achievement = FindAchievement(arg);
	if (achievement == -1) {
		ReplyToCommand(client, "%s '%s' is not a valid achievement.", TAG_CMD, arg);
		return;
	}
	if (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_DISABLED) {
		ReplyToCommand(client, "%s Achievement '%s' is not tracked.", TAG_CMD, g_eAchievementInfo[achievement][s_Name]);
		return;
	}
	switch (GetCmdReplySource()) {
		case SM_REPLY_TO_CHAT: {		// use color for chat messages
			PrintToChat(client, "%s Settings for Achievement '{green}%s{default}':\n{lightgreen}[{default} Desc: {olive}%s{default}.", TAG_AWARD,
				g_eAchievementInfo[achievement][s_Name],
				g_eAchievementInfo[achievement][s_Desc] );
			PrintToChat(client, "{lightgreen}[{default} Game: {olive}%s{default}, Repeatable?: {olive}%s{default}.",
				((g_eAchievementInfo[achievement][L4D1or2] == GAME_L4D1) ? "L4D1"
				: (g_eAchievementInfo[achievement][L4D1or2] == GAME_L4D2) ? "L4D2"
				: "L4D1+2"),
				(g_eAchievementInfo[achievement][b_IsRepeatable] ? "Yes" : "No"));
			PrintToChat(client, "{lightgreen}[{default} Report Freq: {olive}%s{default}.",
				((g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ALWAYS) ? "Every time it is qualified"
				: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE_PER_LIFE) ? "Once per spawn"
				: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE_PER_MAP) ? "Once per map"
				: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE_PER_GAME) ? "Once per campaign / game session"
				: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE) ? "Once - just like how Valve does it"
				: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_NEVER) ? "Never - achievement has been disabled by admin"
				: "Never - achievement can not be tracked" ));
			if (g_eAchievementInfo[achievement][Total] != NO_TOTAL) {
				PrintToChat(client, "{lightgreen}[{default} Amount required to earn: {olive}%d{default}.", g_eAchievementInfo[achievement][Total]);
			}
		}
		default: {						// no color in console (logs)
			ReplyToCommand(client, "%s Settings for Achievement '%s':\n[ Desc: %s", TAG_CMD,
				g_eAchievementInfo[achievement][s_Name],
				g_eAchievementInfo[achievement][s_Desc] );
			ReplyToCommand(client, "[ Game: %s, Repeatable?: %s",
				((g_eAchievementInfo[achievement][L4D1or2] == GAME_L4D1) ? "L4D1"
				: (g_eAchievementInfo[achievement][L4D1or2] == GAME_L4D2) ? "L4D2"
				: "L4D1+2"),
				(g_eAchievementInfo[achievement][b_IsRepeatable] ? "Yes" : "No"));
			ReplyToCommand(client, "[ Report Freq: %s",
				((g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ALWAYS) ? "Every time it is qualified"
				: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE_PER_LIFE) ? "Once per spawn"
				: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE_PER_MAP) ? "Once per map"
				: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE_PER_GAME) ? "Once per campaign / game session"
				: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE) ? "Once - just like how Valve does it"
				: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_NEVER) ? "Never - achievement has been disabled by admin"
				: "Never - achievement can not be tracked" ));
			if (g_eAchievementInfo[achievement][Total] != NO_TOTAL) {
				ReplyToCommand(client, "[ Amount required to earn: %d", g_eAchievementInfo[achievement][Total]);
			}
		}
	}
}

public Action:_Command__Set_Achievement(client, args) {
	if (args == 0) {
		ReplyToCommand(client, "%s Usage: sm_set_achievement [list|never|once|game|map|life|always] <Achievement>\n[ list shows info for an achievement & the rest changes the report frequency.", TAG_CMD);
	} else if (args == 1) {
		ReplyToCommand(client, "%s Missing argument. Need to specify an option and then an achievement.", TAG_CMD);
	} else {
		const argsize = 12 + SIZE_NAME;			// 12 is longer then any of the command arguments.. eg: 'always' = 6
		decl String:arg1[12], String:arg2[SIZE_NAME], String:arg[argsize];
		
		GetCmdArgString(arg, sizeof(arg));							// get the whole argument string
		new achieve_pos = BreakString(arg, arg1, sizeof(arg1));		// get the first arg (GetCmdArg(1,..)) and find where the rest begins (for arg2)
		Format(arg2, sizeof(arg2), "%s", arg[achieve_pos]);			// get the second arg, which is the whole arg starting where the first arg ends
		
		new achievement = FindAchievement(arg2);
		if (achievement == -1) {
			ReplyToCommand(client, "%s '%s' is not a valid achievement.", TAG_CMD, arg2);
			return;
		}
		if (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_DISABLED) {
			ReplyToCommand(client, "%s Achievement '%s' cannot be modified. It is disabled.", TAG_CMD, g_eAchievementInfo[achievement][s_Name]);
			return;
		}
		
		if (StrEqual("list", arg1, false)) {
			switch (GetCmdReplySource()) {
				case SM_REPLY_TO_CHAT: {
					PrintToChat(client, "%s Settings for Achievement '{green}%s{default}':\n{lightgreen}[{default} Desc: {olive}%s{default}.", TAG_AWARD,
						g_eAchievementInfo[achievement][s_Name],
						g_eAchievementInfo[achievement][s_Desc] );
					PrintToChat(client, "{lightgreen}[{default} Game: {olive}%s{default}, Repeatable?: {olive}%s{default}.",
						((g_eAchievementInfo[achievement][L4D1or2] == GAME_L4D1) ? "L4D1"
						: (g_eAchievementInfo[achievement][L4D1or2] == GAME_L4D2) ? "L4D2"
						: "L4D1+2"),
						(g_eAchievementInfo[achievement][b_IsRepeatable] ? "Yes" : "No"));
					PrintToChat(client, "{lightgreen}[{default} Report Freq: {olive}%s{default}.",
						((g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ALWAYS) ? "Every time it is qualified"
						: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE_PER_LIFE) ? "Once per spawn"
						: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE_PER_MAP) ? "Once per map"
						: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE_PER_GAME) ? "Once per campaign / game session"
						: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE) ? "Once - just like how Valve does it"
						: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_NEVER) ? "Never - achievement has been disabled by admin"
						: "Never - achievement can not be tracked" ));
					if (g_eAchievementInfo[achievement][Total] != NO_TOTAL) {
						PrintToChat(client, "{lightgreen}[{default} Amount required to earn: {olive}%d{default}.", g_eAchievementInfo[achievement][Total]);
					}
				}
				default: {
					ReplyToCommand(client, "%s Settings for Achievement '%s':\n[ Desc: %s", TAG_CMD,
						g_eAchievementInfo[achievement][s_Name],
						g_eAchievementInfo[achievement][s_Desc] );
					ReplyToCommand(client, "[ Game: %s, Repeatable?: %s",
						((g_eAchievementInfo[achievement][L4D1or2] == GAME_L4D1) ? "L4D1"
						: (g_eAchievementInfo[achievement][L4D1or2] == GAME_L4D2) ? "L4D2"
						: "L4D1+2"),
						(g_eAchievementInfo[achievement][b_IsRepeatable] ? "Yes" : "No"));
					ReplyToCommand(client, "[ Report Freq: %s",
						((g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ALWAYS) ? "Every time it is qualified"
						: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE_PER_LIFE) ? "Once per spawn"
						: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE_PER_MAP) ? "Once per map"
						: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE_PER_GAME) ? "Once per campaign / game session"
						: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_ONCE) ? "Once - just like how Valve does it"
						: (g_eAchievementInfo[achievement][ReportFrequency] == REPORT_NEVER) ? "Never - achievement has been disabled by admin"
						: "Never - achievement can not be tracked" ));
					if (g_eAchievementInfo[achievement][Total] != NO_TOTAL) {
						ReplyToCommand(client, "[ Amount required to earn: %d", g_eAchievementInfo[achievement][Total]);
					}
				}
			}
		} else if (StrEqual("never", arg1, false)) {
			g_eAchievementInfo[achievement][ReportFrequency] = REPORT_NEVER;
			ReplyToCommand(client, "%s Achievement '%s' will never be reported.", TAG_CMD, g_eAchievementInfo[achievement][s_Name]);
		} else if (StrEqual("once", arg1, false)) {
			g_eAchievementInfo[achievement][ReportFrequency] = REPORT_ONCE;
			ReplyToCommand(client, "%s Achievement '%s' will be reported once per client (just like Valve does it).", TAG_CMD, g_eAchievementInfo[achievement][s_Name]);
		} else if (StrEqual("game", arg1, false)) {
			g_eAchievementInfo[achievement][ReportFrequency] = REPORT_ONCE_PER_GAME;
			ReplyToCommand(client, "%s Achievement '%s' will be reported once per game session for each client.", TAG_CMD, g_eAchievementInfo[achievement][s_Name]);
		} else if (StrEqual("map", arg1, false)) {
			g_eAchievementInfo[achievement][ReportFrequency] = REPORT_ONCE_PER_MAP;
			ReplyToCommand(client, "%s Achievement '%s' will be reported once per map for each client.", TAG_CMD, g_eAchievementInfo[achievement][s_Name]);
		} else if (StrEqual("life", arg1, false)) {
			g_eAchievementInfo[achievement][ReportFrequency] = REPORT_ONCE_PER_LIFE;
			ReplyToCommand(client, "%s Achievement '%s' will be reported once per life for each client.", TAG_CMD, g_eAchievementInfo[achievement][s_Name]);
		} else if (StrEqual("always", arg1, false)) {
			g_eAchievementInfo[achievement][ReportFrequency] = REPORT_ALWAYS;
			ReplyToCommand(client, "%s Achievement '%s' will be reported every time a client earns it.", TAG_CMD, g_eAchievementInfo[achievement][s_Name]);
		} else {
			ReplyToCommand(client, "%s Invalid option. Usage: sm_set_achievement [list|total|never|once|game|map|life|always] <Achievement>", TAG_CMD);
		}
	}
	return;
}

public OnConfigsExecuted() {
	// these game convars are very rarely changed.. and when they do - it is usually in a config file
	// so i don't think hooking them is required, just check if they change
	g_fBoomerVomitDelay = GetConVarFloat(g_hBoomerVomitDelay);
	g_fZVomitDuration = GetConVarFloat(g_hZVomitDuration);
	g_fSurvivorItDuration = GetConVarFloat(g_hSurvivorItDuration);
	g_fZExplodingShoveInterval = GetConVarFloat(g_hZExplodingShoveInterval);
	if (g_bIsL4D2) {
		g_fZChargeDuration = GetConVarFloat(g_hZChargeDuration);
	}
	
	// this is to remove a warning until im ready to use it..
	if (g_fSurvivorItDuration) {
		// blargh
	}
	DebugPrintToAll("[OnConfigsExecuted] Processed.");
}

public OnMapStart() {
	if (!g_bEnabled) return;
	
	g_bFinaleStarted = false;
	for (new i=1; i<=MaxClients; i++) 	{
		ResetTimer(g_hTimer__Ability[i]);
		ResetTimer(g_hTimer__JockeyRide[i]);
		ResetTimer(g_hTimer__Pummel[i]);
		for (new j=1; j<=MaxClients; j++) {
			ResetTimer(g_hTimer__CleanKill[i][j]);
		}
		_Reset_ClientInfo(i);
	}
	DebugPrintToAll("[OnMapStart] Completed.");
}

/*
	if jumpshot doesnt work.. try using traceattack
public OnClientPutInServer(client) {
	if (!g_bEnabled) return;
	
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
}

public Action:TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup) {
	if (hitgroup == 1) {
		damage *= 0.50;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
*/

public OnClientDisconnect(client) {
	if (!g_bEnabled) return;
	
	/*
	this cant work here.. if a player disconnects, then a bot would take over right?.. put it there
	if (IsPlayerClient(client)) {
		if (GetZombieClass2(client) == ZOMBIECLASS_TANK) {
			new id = FindTankIndex(GetClientUserId(client));
			if (id != -1) {
				DebugPrintToAll("[OnClientDisconnect] client (%i) '%N' has a known tank_index id (%i), removing from the tank_index.", client, client, id);
				Rebuild_TankIndex(id, false);
			}
			DebugPrintToAll("[OnClientDisconnect] Resetting Achievement 'All 4 Dead'.");
			Reset_All4Dead(client);
		}
	}
	*/
	ResetTimer(g_hTimer__Ability[client]);
	ResetTimer(g_hTimer__JockeyRide[client]);
	ResetTimer(g_hTimer__Pummel[client]);
	for (new i=1; i<=MaxClients; i++) {
		ResetTimer(g_hTimer__CleanKill[client][i]);
	}
	//_Reset_ClientInfo(client);
	DebugPrintToAll("[OnClientDisconnect] Completed.");
}

public ConVarChange__Enable(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(convar);
	DebugPrintToAll("[ConVarChange] l4d_achievements_enable (g_bEnabled) = %s.", g_bEnabled ? "true" : "false" );
	if (g_bEnabled)
		_ModuleEnabled();
	else
		_ModuleDisabled();
}

public ConVarChange__LogToChat(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if (g_bLogToChat)		// logging is on, so print a msg before turning it off..
		DebugPrintToAll("[ConVarChange] l4d_achievements_debug (g_bLogToChat) = %s", g_bLogToChat ? "false" : "true" );
	g_bLogToChat = GetConVarBool(convar);
	if (g_bLogToChat)		// logging was off, but now it isn't
		DebugPrintToAll("[ConVarChange] l4d_achievements_debug (g_bLogToChat) = %s", g_bLogToChat ? "true" : "false");
}

public ConVarChange__LogToFile(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if (g_bLogToFile)
		DebugPrintToAll("[ConVarChange] l4d_achievements_debuglog (g_bLogToFile) = %s", g_bLogToFile ? "false" : "true" );
	g_bLogToFile = GetConVarBool(convar);
	if (g_bLogToFile)
		DebugPrintToAll("[ConVarChange] l4d_achievements_debuglog (g_bLogToFile) = %s", g_bLogToFile ? "true" : "false" );
}

public ConVarChange__UseL4D1inL4D2(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bUseL4D1inL4D2 = GetConVarBool(convar);
	DebugPrintToAll("[ConVarChange] l4d_achievements_l4d1inl4d2 (g_bUseL4D1inL4D2) = %s.", g_bUseL4D1inL4D2 ? "true" : "false" );
}

public ConVarChange__UseGenericMessage(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bUseGenericMessage = GetConVarBool(convar);
	DebugPrintToAll("[ConVarChange] l4d_achievements_usegeneric (g_bUseGenericMessage) = %s.", g_bUseGenericMessage ? "true" : "false" );
}

public ConVarChange__ZDifficulty(Handle:convar, const String:oldValue[], const String:newValue[]) {
	GetConVarString(convar, g_sZDifficulty, sizeof(g_sZDifficulty));
	DebugPrintToAll("[ConVarChange] z_difficulty.. oldValue = '%s', newValue = '%s'.", oldValue, newValue);
}

public Action:_Event__Award_Earned(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[award_earned] Begin..");
	if (!g_bEnabled) return;
	// user who earned the award
	new user = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsPlayerClient(user))
		return;
	// client likes ent id ??????
	new entity = GetEventInt(event, "entityid");
	// entity id of other 'party' in the award
	new subject = GetEventInt(event, "subjectentid");
	// id of the actual award
	new award = GetEventInt(event, "award");
	DebugPrintToAll("[award_earned] user (%i) '%N', entityid %i, subjectentid %i, award %i", user, user, entity, subject, award);
}

public Action:_Event__Vote_Passed(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[vote_passed] Begin..");
	if (!g_bEnabled) return;
	
	decl String:details[64], String:param1[64];
	new team;
	new bool:reliable;
	
	GetEventString(event, "details", details, sizeof(details));
	GetEventString(event, "param1", param1, sizeof(param1));
	GetEventInt(event, "team");
	GetEventBool(event, "reliable");
	DebugPrintToAll("[vote_passed] details '%s', param1 '%s', team = %i, reliable %b", details, param1, team, reliable);
	
	//if (StrEqual(details, "#L4D_vote_passed_restart_game"))
	//	ResetAllAchievements();
	
}

public Action:_Event__Map_Transition(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[map_transition] Begin..");
	if (!g_bEnabled) return;
	
}

public Action:_Event__Player_Transitioned(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[player_transitioned] Begin..");
	if (!g_bEnabled) return;
	
}

public Action:_Event__Player_First_Spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[player_first_spawn] Begin..");
	if (!g_bEnabled) return;
	
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsPlayerClient(player))
		return;
	
	_Reset_ClientInfo(player);
}

public Action:_Event__Round_Start_Post_Nav(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[round_start_post_nav] Begin..");
	if (IsPrevented(Wedding_Crasher) && !IsRepeatable(Wedding_Crasher)) {
		DebugPrintToAll("[round_start_post_nav] Achievement 'Wedding Crasher' is prevented from being earned by any one.");
		return;
	}
	
	decl String:map[24];
	GetCurrentMap(map, sizeof(map));
	DebugPrintToAll("[round_start_post_nav] Current map = '%s'.", map);
	if (!StrEqual(map, "c6m1_riverbank", true))
		return;
	
	decl String:classname[128], String:model[128];
	new maxentities = GetMaxEntities();
	//new offs = FindSendPropInfo("CDynamicProp", "m_ModelName");
	for (new i=1; i<=maxentities; i++) {
		if (!IsValidEntity(i) || !IsValidEdict(i))
			continue;
		
		GetEdictClassname(i, classname, sizeof(classname));
		if (!StrEqual(classname, "prop_physics", false))
			continue;
		
		DebugPrintToAll("[round_start_post_nav] entity %i (of %i), classname '%s' is a prop_physics.", i, maxentities, classname);
		GetEntPropString(i , Prop_Data, "m_ModelName", model, sizeof(model));
		//GetEntDataString(i, offs, model, sizeof(model));
		DebugPrintToAll("[round_start_post_nav] model = '%s'", model);
		if (!StrEqual(model, "models/props_urban/plastic_chair001_debris.mdl", true))
			continue;
		
		DebugPrintToAll("[round_start_post_nav] entity is a plastic_chair001_debris.");
		//HookSingleEntityOutput(i, "output_string??", Output_ChairCollision)
	}
}
/*
public Output_ChairCollision(const String:output[], caller, activator, Float:delay) {
	if (achievement_earned)
		UnhookSingleEntityOutput(entity, "output_string??", Output_ChairCollision);
}
*/
public Action:_Event__Round_Start(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[round_start] Begin..");
	if (!g_bEnabled) return;
	
	DebugPrintToAll("[round_start] Rebuilding tank_index..");
	Rebuild_TankIndex(ALL_TANKS);
}

public Action:_Event__Scavenge_Round_Start(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[scavenge_round_start] Begin..");
	if (!g_bEnabled) return;
	
	DebugPrintToAll("[scavenge_round_start] Rebuilding tank_index..");
	Rebuild_TankIndex(ALL_TANKS);
}

public Action:_Event__Survival_Round_Start(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[survival_round_start] Begin..");
	if (!g_bEnabled) return;
	
	DebugPrintToAll("[survival_round_start] Rebuilding tank_index..");
	Rebuild_TankIndex(ALL_TANKS);
}

public Action:_Event__Versus_Round_Start(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[versus_round_start] Begin..");
	if (!g_bEnabled) return;
	
	DebugPrintToAll("[versus_round_start] Rebuilding tank_index..");
	Rebuild_TankIndex(ALL_TANKS);
}

public Action:_Event__Round_End(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[round_end] Begin..");
	if (!g_bEnabled) return;
}

public Action:_Event__Finale_Start(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[finale_start] Begin..");
	if (!g_bEnabled) return;
	g_bFinaleStarted = true;
}

public Action:_Event__Finale_Win(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[finale_win] Begin..");
	if (!g_bEnabled) return;
	g_bFinaleStarted = false;
}

public Action:_Event__Mission_Lost(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[mission_lost] Begin..");
	if (!g_bEnabled) return;
	g_bFinaleStarted = false;
}

public Action:_Event__Difficulty_Changed(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[difficulty_changed] Begin..");
	if (!g_bEnabled) return;
	
	new old_dif, new_dif;
	old_dif = GetEventInt(event, "oldDifficulty");
	new_dif = GetEventInt(event, "newDifficulty");
	DebugPrintToAll("[difficulty_changed] oldDifficulty = %i, newDifficulty = %i", old_dif, new_dif);
}

public Action:_Event__Friendly_Fire(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[friendly_fire] Begin..");
	if (!g_bEnabled) return;
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!IsPlayerClient(attacker) || !IsPlayerClient(victim))
		return;
	// only care about survivor ff events.. does this even fire otherwise?
	new team_a = GetClientTeam(attacker);
	new team_v = GetClientTeam(victim);
	DebugPrintToAll("[friendly_fire] attackers team = %i, victims team = %i.", team_a, team_v);
	if ((team_a != TEAM_SURVIVORS) || (team_v != TEAM_SURVIVORS))
		return;
	
	DebugPrintToAll("[friendly_fire] attacker = '%N', victim = '%N'.", attacker, victim);
	// guilty SHOULD be attacker or victim.. but just in case
	new guilty = GetClientOfUserId(GetEventInt(event, "guilty"));
	if (!IsPlayerClient(guilty)) {
		DebugPrintToAll("[friendly_fire] attacker & victim are both valid, yet the guilty party (%i) is not a player client!?!", guilty);
		return;
	}
	
	if (GetClientTeam(guilty) != TEAM_SURVIVORS) {
		DebugPrintToAll("[friendly_fire] attacker & victim are both valid, yet the guilty party (%i) isn't a survivor?", guilty);
	} else {
		DebugPrintToAll("[friendly_fire] guilty party = '%N'.", guilty);
		if (!IsPrevented(Safety_First, guilty)) {
			DebugPrintToAll("[friendly_fire] Achievement 'Safety First' blown by '%N'.", guilty);
			for (new i=1; i<=MaxClients; i++) {
				if (IsClientInGame(i)) {
					if (GetClientTeam(i) == TEAM_SURVIVORS)
						PreventAchievement(i, Safety_First);
				}
			}
		}
	}
}

public Action:_Event__Player_Team(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[player_team] Begin..");
	if (!g_bEnabled) return;
}

public Action:_Event__Player_Bot_Replace(Handle:event, const String:name[], bool:dontBroadcast) {
// Bot replaces a player
	DebugPrintToAll("[player_bot_replace] Begin..");
	if (!g_bEnabled) return;
	
	new player_id = GetEventInt(event, "player");
	new player = GetClientOfUserId(player_id);
	new bot_id = GetEventInt(event, "bot");
	new bot = GetClientOfUserId(bot_id);
	DebugPrintToAll("[player_bot_replace] (Id - Client) Player = %d - %d, Bot = %d - %d", player_id, player, bot_id, bot);
}

public Action:_Event__Bot_Player_Replace(Handle:event, const String:name[], bool:dontBroadcast) {
// Player replaces a bot
	DebugPrintToAll("[bot_player_replace] Begin..");
	if (!g_bEnabled) return;
	
	new bot_id = GetEventInt(event, "bot");
	new bot = GetClientOfUserId(bot_id);
	new player_id = GetEventInt(event, "player");
	new player = GetClientOfUserId(player_id);
	DebugPrintToAll("[bot_player_replace] (Id - Client) Bot = %d - %d, Player = %d - %d", bot_id, bot, player_id, player);
}

public Action:_Event__Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[player_hurt] Begin..");
	if (!g_bEnabled) return;
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsPlayerClient(victim))
		return;
	
	if (GetClientTeam(victim) == TEAM_SURVIVORS) {
		DebugPrintToAll("[player_hurt] victim = '%N'.", victim);
		if (g_bFinaleStarted) {
			DebugPrintToAll("[player_hurt] Achievement 'Untouchables' failed!");
			for (new i=1; i<=MaxClients; i++) {
				if (IsClientInGame(i)) {
					if (GetClientTeam(i) == TEAM_SURVIVORS)
						PreventAchievement(i, Untouchables);
				}
			}
		}
	}
	
	new attackerid = GetEventInt(event, "attacker");
	new attacker = GetClientOfUserId(attackerid);
	if (!IsPlayerClient(attacker))
		return;
	
	if (GetClientTeam(attacker) == TEAM_INFECTED) {
		if (GetZombieClass2(attacker) == ZOMBIECLASS_TANK) {
			DebugPrintToAll("[player_hurt] attacker = '%N', is a TANK.. Achievement 'Tankbusters' failed.", attacker);
			new tank_id = FindTankIndex(attackerid);
			if (tank_id != -1)
				g_eTankIndex[tank_id][TankHasHurt] = true;
		}
	}
}

public Action:_Event__Player_Incapacitated(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[player_incapacitated] Begin..");
	if (!g_bEnabled) return;
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsPlayerClient(victim))
		return;
	
	DebugPrintToAll("[player_incapacitated] victim = '%N'.", victim);
	g_eClientInfo[victim][b_isDead] = true;
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!IsPlayerClient(attacker))
		return;
	
	DebugPrintToAll("[player_incapacitated] attacker = '%N'.", attacker);
	g_eClientInfo[victim][Killer_Id] = attacker;
	if (GetZombieClass2(attacker) == ZOMBIECLASS_TANK) {
		if (IsPrevented(All_4_Dead, attacker) || !IsRepeatable(All_4_Dead, attacker)) {
			DebugPrintToAll("[player_incapacitated] Achievement 'All_4_Dead' is prevented from being earned by tank '%N'.", attacker);
		} else {
			DebugPrintToAll("[player_incapacitated] Tank incapped victim, check for 'All 4 Dead'.");
			CheckAll4Dead(attacker);
		}
	}
}

public Action:_Event__Player_Death(Handle:event, const String:name[], bool:dontBroadcast) {
/*
	string:weapon		bool:attackerisbot		type (damage  eg: (1<<2) )
	bool:headshot		bool:victimisbot
*/
	DebugPrintToAll("[player_death] Begin..");
	if (!g_bEnabled) return;
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsPlayerClient(victim))
		return;
	
	new zClass = GetZombieClass2(victim);
	DebugPrintToAll("[player_death] victim = '%N', zombie class = %i.", victim, zClass);
	
	g_eClientInfo[victim][b_isDead] = true;
	// Can't get 'Back In The Saddle' if you die..
	g_eClientInfo[victim][PrevMule_Id] = -1;
	g_eClientInfo[victim][CurMule_Id] = -1;
	if (zClass == ZOMBIECLASS_TANK) {		// Can't kill em all if your already dead..
		DebugPrintToAll("[player_death] Victim was a TANK, Achievement 'All 4 Dead' failed.");
		Reset_All4Dead(victim);
	} else if (zClass == ZOMBIECLASS_BOOMER) {		// Clean Kill - if the victim was a boomer, get it over with
		for (new i=1; i<=MaxClients; i++) {
			if (g_hTimer__CleanKill[i][victim] != INVALID_HANDLE) {
				TriggerTimer(g_hTimer__CleanKill[i][victim]);
				break;		// there SHOULD only be 1 timer per victim (i already fixed that) - so no need to keep looping once its found
			}
		}
	}
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!IsPlayerClient(attacker))
		return;
	
	DebugPrintToAll("[player_death] attacker = '%N'.", attacker);
	g_eClientInfo[victim][Killer_Id] = attacker;
	// All 4 Dead
	if (GetZombieClass2(attacker) == ZOMBIECLASS_TANK) {
		if (IsPrevented(All_4_Dead, attacker) || !IsRepeatable(All_4_Dead, attacker)) {
			DebugPrintToAll("[player_death] Achievement 'All_4_Dead' is prevented from being earned by tank '%N'.", attacker);
		} else {
			DebugPrintToAll("[player_death] attacker is a TANK, check for achievement 'All 4 Dead'.");
			CheckAll4Dead(attacker);
		}
	}
	
}

public Action:_Event__Revive_Success(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[revive_success] Begin..");
	if (!g_bEnabled) return;
	
	new saved = GetClientOfUserId(GetEventInt(event, "subject"));
	if (!IsPlayerClient(saved))
		return;
	
	g_eClientInfo[saved][Killer_Id] = -1;
	//new bool:ledge_save = GetEventBool(event, "ledge_hang");
	//if (ledge_save)
	//	return;
}

public Action:_Event__Defibrillator_Used(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[defibrillator_used] Begin..");
	if (!g_bEnabled) return;
	
	new saved = GetClientOfUserId(GetEventInt(event, "subject"));
	if (!IsPlayerClient(saved))
		return;
	
	g_eClientInfo[saved][Killer_Id] = -1;
}

public Action:_Event__Respawning(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[respawning] Begin..");
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsPlayerClient(player))
		return;
	
	DebugPrintToAll("[respawning] player = '%N'.", player);
	_Reset_ClientInfo(player);
}

public Action:_Event__Player_Shoved(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[player_shoved] Begin..");
	if (!g_bEnabled) return;
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new shoved = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsPlayerClient(attacker) || !IsPlayerClient(shoved))
		return;
	
	DebugPrintToAll("[player_shoved] shove-er (%i) '%N', shove-ee (%i) '%N'.", attacker, attacker, shoved, shoved);
	new class = GetZombieClass2(shoved);
	DebugPrintToAll("[player_shoved] shove-ee's zombieclass = %i.", class);
	switch (class) {
		// Clean Kill
		case ZOMBIECLASS_BOOMER: {
			DebugPrintToAll("[player_shoved] shove-ee is a Boomer. Check for 'Clean_Kill'.");
			if (IsPrevented(Clean_Kill, attacker) || !IsRepeatable(Clean_Kill, attacker)) {
				DebugPrintToAll("[player_shoved] Achievement 'Clean_Kill' is prevented from being earned by shove-er '%N'.", attacker);
				return;
			}
			new bool:isValid = true;
			// check if anyone has already been puked on by this boomer
			for (new i=1; i<=MaxClients; i++) {
				if (IsValidClient(i)) {
					if (g_eClientInfo[i][b_isPukedOn] || g_eClientInfo[i][b_isBiledOn]) {
						if (g_eClientInfo[i][Puker_Id] == shoved) {
							DebugPrintToAll("[player_shoved] Achievement 'Clean_Kill' is not valid due to someone already being puked on.");
							isValid = false;
							break;
						}
					}
				}
			}
			// this is to prevent 1 boomer giving out 4 clean kills (if all 4 survivors were to shove him)
			// this is also the sole reason g_hTimer__CleanKill is multi-dimensional
			for (new i=1; i<=MaxClients; i++) {
				if ((i != attacker) && (i != shoved)) {
					if (g_hTimer__CleanKill[i][shoved] != INVALID_HANDLE) {
						DebugPrintToAll("[player_shoved] '%N' has a 'Clean_Kill' timer active.. too bad for '%N'.", i, attacker);
						isValid = false;
					}
				}
			}
			if (isValid) {
				g_eClientInfo[shoved][b_isShoved] = true;
				g_eClientInfo[shoved][Shoved_Id] = attacker;
				DebugPrintToAll("[player_shoved] Begin timer to check for 'Clean_Kill'.");
				if (g_hTimer__CleanKill[attacker][shoved] != INVALID_HANDLE) {
					DebugPrintToAll("[player_shoved] '%N' already has a 'Clean_Kill' timer active.. reset.", attacker);
					KillTimer(g_hTimer__CleanKill[attacker][shoved], true);
				}
				// Using a data timer to resolve issues with figuring out who shoved whom
				// removed the TIMER_FLAG_NO_MAPCHANGE to ensure the pack handle gets closed.. will have to adjust code in timer.
				new Handle:pack;
				decl String:sShoved[MAX_NAME_LENGTH];
				Format(sShoved, sizeof(sShoved), "%N", shoved);		// if the client isnt in game when the timer expires - get his name (bots wont be in game after they are dead)
				
				g_hTimer__CleanKill[attacker][shoved] = CreateDataTimer(g_fZExplodingShoveInterval, _Timer__CleanKill, pack);
				WritePackCell(pack, attacker);
				WritePackCell(pack, shoved);
				WritePackString(pack, sShoved);
			}
		}
		// Hunter Punter
		case ZOMBIECLASS_HUNTER: {
			DebugPrintToAll("[player_shoved] shove-ee is a Hunter. Check for 'Hunter_Punter'.");
			new pounced = GetPounceVictim(shoved);
			if (IsPlayerClient(pounced)) {
				DebugPrintToAll("[player_shoved] Hunter is pouncing someone: (%d) '%N'.", pounced, pounced);
				if (!IsPrevented(Hunter_Punter, attacker) && IsRepeatable(Hunter_Punter, attacker)) {
					DebugPrintToAll("[player_shoved] Achievement 'Hunter_Punter' is qualified!");
					if (g_bUseGenericMessage) {
						PrintAwardMsgToAll(Hunter_Punter, attacker);
					} else {
						decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE];
						decl String:c_survivor[MSG_SIZE], String:c_hunter[MSG_SIZE], String:c_pounced[MSG_SIZE];
						Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Hunter_Punter][s_Name]);
						Format(c_survivor, MSG_SIZE, "{green}%N{default}", attacker);
						Format(c_hunter, MSG_SIZE, "{green}%N{default}", shoved);
						Format(c_pounced, MSG_SIZE, "{green}%N{default}", pounced);
						if (!IsFakeClient(attacker)) {
							Format(msg1, MSG_SIZE, "%T", "Message_Hunter_Punter_1", attacker, c_hunter, c_pounced);
							CPrintToChat(attacker, "%s %s", TAG_HUNTER, msg1);
						}
						CSkipNextClient(attacker);
						if (!IsFakeClient(shoved)) {
							Format(msg1, MSG_SIZE, "%T", "Message_Hunter_Punter_2", shoved, c_survivor, c_pounced);
							CPrintToChat(shoved, "%s %s", TAG_HUNTER, msg1);
						}
						CSkipNextClient(shoved);
						if (!IsFakeClient(pounced)) {
							Format(msg1, MSG_SIZE, "%T", "Message_Hunter_Punter_3", pounced, c_survivor, c_hunter);
							CPrintToChat(pounced, "%s %s", TAG_HUNTER, msg1);
						}
						CSkipNextClient(pounced);
						Format(msg1, MSG_SIZE, "%T", "Message_Hunter_Punter_4", LANG_SERVER, c_survivor, c_hunter);
						CPrintToChatAll("%s %s", TAG_HUNTER, msg1);
					}
				}
			}
		}
		default: {
			DebugPrintToAll("[player_shoved] No achievement associated with shove-ee's zombieclass.");
			return;
		}
	}
}

stock bool:IsPounced(client) {
	if (GetEntProp(client, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	return false;
}

stock bool:IsPouncing(client) {
	if (GetEntProp(client, Prop_Send, "m_pounceVictim") > 0)
		return true;
	return false;
}

stock GetPounceAttacker(client) {
	return GetEntProp(client, Prop_Send, "m_pounceAttacker");
}

stock GetPounceVictim(client) {
	return GetEntProp(client, Prop_Send, "m_pounceVictim");
}

stock bool:IsPummeled(client) {
	if (GetEntProp(client, Prop_Send, "m_pummelAttacker") > 0)
		return true;
	return false;
}

stock bool:IsPummeling(client) {
	if (GetEntProp(client, Prop_Send, "m_pummelVictim") > 0)
		return true;
	return false;
}

stock GetPummelAttacker(client) {
	return GetEntProp(client, Prop_Send, "m_pummelAttacker");
}

stock GetPummelVictim(client) {
	return GetEntProp(client, Prop_Send, "m_pummelVictim");
}
/*
  -Member: m_carryAttacker (offset 10860) (type integer) (bits 21)
  -Member: m_carryVictim (offset 10856) (type integer) (bits 21)

stock bool:IsTongued(client) {
	if (GetEntProp(client, Prop_Send, "m_tongueOwner") > 0)
		return true;
	return false;
}

stock bool:IsTonging(client) {
	if (GetEntProp(client, Prop_Send, "m_tongueVictim") > 0)
		return true;
	return false;
}

stock GetTongueVictim(client) {
	return GetEntProp(client, Prop_Send, "m_tongueVictim");
}

stock GetTongueAttacker(client) {
	return GetEntProp(client, Prop_Send, "m_tongueOwner");
}

these could be used for achievements..
  -Member: m_tongueVictim (offset 13236) (type integer) (bits 21)
  -Member: m_tongueOwner (offset 13240) (type integer) (bits 21)
   Sub-Class Table (3 Deep): DT_IntervalTimer
   -Member: m_timestamp (offset 4) (type float) (bits 0)
  -Member: m_initialTonguePullDir (offset 13252) (type vector) (bits 0)
  -Member: m_isHangingFromTongue (offset 13264) (type integer) (bits 1)
  -Member: m_reachedTongueOwner (offset 13265) (type integer) (bits 1)
  -Member: m_isProneTongueDrag (offset 13272) (type integer) (bits 1)
*/

public Action:_Timer__CleanKill(Handle:timer, Handle:data) {
	DebugPrintToAll("[_Timer__CleanKill] Times up..");
	ResetPack(data);
	new attacker = ReadPackCell(data);
	new shoved = ReadPackCell(data);
	decl String:sShoved[MAX_NAME_LENGTH];
	ReadPackString(data, sShoved, sizeof(sShoved));
	g_hTimer__CleanKill[attacker][shoved] = INVALID_HANDLE;
	
	if (IsClientInGame(attacker)) {		// if the player left, he doesn't earn the achievement
		if (g_eClientInfo[shoved][b_isDead]) {
			DebugPrintToAll("[_Timer__CleanKill] Boomer died, now see if he puked on anyone..");
			new bool:isClean = true;
			for (new i=1; i<=MaxClients; i++) {		// see if the boomer puked/exploded on anyone
				if (IsClientInGame(i)) {
					if (GetClientTeam(i) == TEAM_SURVIVORS) {
						if ((g_eClientInfo[i][b_isPukedOn] || g_eClientInfo[i][b_isBiledOn])
						&& (g_eClientInfo[i][Puker_Id] == shoved)) {
							DebugPrintToAll("[_Timer__CleanKill] Found a client that was puked on.. Achievement Failed!");
							isClean = false;
							break;
						}
					}
				}
			}
			if (isClean) {
				DebugPrintToAll("[_Timer__CleanKill] Boomer %d '%s' was killed w.o puking!", shoved, sShoved);
				if (!IsPrevented(Clean_Kill, attacker) && IsRepeatable(Clean_Kill, attacker)) {
					DebugPrintToAll("[_Timer__CleanKill] Achievement 'Clean_Kill' is qualified!");
					if (g_bUseGenericMessage) {
						PrintAwardMsgToAll(Clean_Kill, attacker);
					} else {
						decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE];
						decl String:c_survivor[MSG_SIZE], String:c_boomer[MSG_SIZE];
						Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Clean_Kill][s_Name]);
						Format(c_survivor, MSG_SIZE, "{green}%N{default}", attacker);
						Format(c_boomer, MSG_SIZE, "{green}%s{default}", sShoved);
						if (!IsFakeClient(attacker)) {
							Format(msg1, MSG_SIZE, "%T", "Message_Clean_Kill_1", attacker, colorized, c_boomer);
							CPrintToChat(attacker, "%s %s", TAG_BOOMER, msg1);
						}
						CSkipNextClient(attacker);
						if (!IsFakeClient(shoved)) {
							Format(msg1, MSG_SIZE, "%T", "Message_Clean_Kill_2", shoved, colorized, c_survivor);
							CPrintToChat(shoved, "%s %s", TAG_BOOMER, msg1);
						}
						CSkipNextClient(shoved);
						Format(msg1, MSG_SIZE, "%T", "Message_Clean_Kill_3", LANG_SERVER, colorized, c_survivor, c_boomer);
						CPrintToChatAll("%s %s", TAG_BOOMER, msg1);
					}
				}
			}
		} else {
			DebugPrintToAll("[_Timer__CleanKill] Achievement failed! Boomer isn't dead.");
		}
	}
}

/*
public Action:_Event__Entity_Shoved(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[entity_shoved] Begin..");
	if (!g_bEnabled) return;
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!IsPlayerClient(attacker))
		return;
	
	new entity = GetEventInt(event, "entityid");
	DebugPrintToAll("[entity_shoved] entity = %i, attacker (%i) = '%N'.", entity, attacker, attacker);
}
*/
public Action:_Event__Ability_Use(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[ability_use] Begin..");
	new user = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsPlayerClient(user))
		return;
	
	decl String:sAbility[24];
	GetEventString(event, "ability", sAbility, sizeof(sAbility));
	new use = GetEventInt(event, "context");
	DebugPrintToAll("[ability_use] user %i, ability '%s', use %i", user, sAbility, use);
	
	if (g_hTimer__Ability[user] != INVALID_HANDLE) {
		DebugPrintToAll("[ability_use] user has an ability timer active already!?!.. kill it.");
		KillTimer(g_hTimer__Ability[user]);
		g_hTimer__Ability[user] = INVALID_HANDLE;
	}
	
	new Float:duration = 0.0;
	if (StrEqual(sAbility, "ability_vomit", true)) {
		DebugPrintToAll("[ability_use] 'ability_vomit' detected.");
		if (IsPrevented(Barf_Bagged, user) || !IsRepeatable(Barf_Bagged, user)) {
			DebugPrintToAll("[ability_use] Achievement 'Barf Bagged' is prevented from being earned by user '%N'. Aborting..", user);
		} else {
			DebugPrintToAll("[ability_use] Begin timer to detect 'Barf Bagged'.");
			duration = FloatAdd(g_fBoomerVomitDelay, g_fZVomitDuration);
			g_hTimer__Ability[user] = CreateTimer(duration, _Timer__Puking, user);
		}
	} else if (StrEqual(sAbility, "ability_charge", true)) {
		DebugPrintToAll("[ability_use] 'ability_charge' detected.");
		if (IsPrevented(Scattering_Ram, user) || !IsRepeatable(Scattering_Ram, user)) {
			DebugPrintToAll("[ability_use] Achievement 'Scattering Ram' is prevented from being earned by user '%N'. Aborting..", user);
		} else {
			DebugPrintToAll("[ability_use] Begin timer to detect 'Scattering Ram'.");
			g_hTimer__Ability[user] = CreateTimer(g_fZChargeDuration, _Timer__Charging, user);
		}
	}
}

public Action:_Timer__Puking(Handle:timer, any:boomer) {
	g_hTimer__Ability[boomer] = INVALID_HANDLE;
	DebugPrintToAll("[_Timer__Puking] Times up..");
	
	new num_pukes = 0;
	new bool:isPukedOn[MAXPLAYERS+1] = { false, ... };
	
	for (new i=1; i<=MaxClients; i++) {
		if (g_eClientInfo[i][b_isPukedOn] && (g_eClientInfo[i][Puker_Id] == boomer)) {
			// damnit.. i spent 4 days trying to figure out why clean kill wasnt working because of this..
			//g_eClientInfo[i][b_isPukedOn] = false;
			//g_eClientInfo[i][Puker_Id] = -1;
			num_pukes++;
			isPukedOn[i] = true;
		}
	}
	if (num_pukes >= g_eAchievementInfo[Barf_Bagged][Total]) {
		DebugPrintToAll("[_Timer__Puking] 'Barf Bagged' detected.");
		g_eAchievementStatus[boomer][Barf_Bagged][b_IsCompleted] = true;
		if (g_bUseGenericMessage) {
			PrintAwardMsgToAll(Barf_Bagged, boomer);
		} else {
			decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE];
			decl String:c_boomer[MSG_SIZE];
			Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Barf_Bagged][s_Name]);
			Format(c_boomer, MSG_SIZE, "{green}%N{default}", boomer);
			Format(msg1, MSG_SIZE, "%T", "Message_Barf_Bagged_1", boomer, colorized);
			if (!IsFakeClient(boomer))
				CPrintToChat(boomer, "%s %s", TAG_BOOMER, msg1);
			CSkipNextClient(boomer);
			for (new i=1; i<=MaxClients; i++) {
				if (isPukedOn[i]) {
					if (!IsFakeClient(i)) {
						Format(msg1, MSG_SIZE, "%T", "Message_Barf_Bagged_2", i, colorized, c_boomer);
						CPrintToChat(i, "%s %s", TAG_BOOMER, msg1);
					}
					CSkipNextClient(i);
				}
			}
			Format(msg1, MSG_SIZE, "%T", "Message_Barf_Bagged_3", LANG_SERVER, colorized, c_boomer);
			CPrintToChatAll("%s %s", TAG_BOOMER, msg1);
		}
	}
}

public Action:_Timer__Charging(Handle:timer, any:charger) {
	g_hTimer__Ability[charger] = INVALID_HANDLE;
	DebugPrintToAll("[_Timer__Charging] Times up..");
	
	new num_scattered = 0;
	new i;
	new bool:isScattered[MAXPLAYERS+1] = { false, ... };
	
	for (i=1; i<=MaxClients; i++) {
		if (!g_eClientInfo[i][b_isImpacted] || !g_eClientInfo[i][b_isCarried] || !g_eClientInfo[i][b_isPummeled])
			continue;
		if (g_eClientInfo[i][Impactor_Id] == charger) {
			g_eClientInfo[i][b_isImpacted] = false;
			g_eClientInfo[i][Impactor_Id] = -1;
			DebugPrintToAll("[_Timer__Charging] %N has been scattered (impact) by %N.", i, charger);
			num_scattered++;
			isScattered[i] = true;
		} else if (g_eClientInfo[i][Carrier_Id] == charger) {
			g_eClientInfo[i][b_isCarried] = false;
			g_eClientInfo[i][Carrier_Id] = -1;
			DebugPrintToAll("[_Timer__Charging] %N has been scattered (carry) by %N.", i, charger);
			num_scattered++;
			isScattered[i] = true;
		} else if (g_eClientInfo[i][Pummeler_Id] == charger) {
			g_eClientInfo[i][b_isPummeled] = false;
			g_eClientInfo[i][Pummeler_Id] = -1;
			DebugPrintToAll("[_Timer__Charging] %N has been scattered (pummel) by %N.", i, charger);
			num_scattered++;
			isScattered[i] = true;
		}
	}
	
	if (num_scattered >= g_eAchievementInfo[Scattering_Ram][Total]) {
		DebugPrintToAll("[_Timer__Charging] 'Scattering Ram' detected..");
		g_eAchievementStatus[charger][Scattering_Ram][b_IsCompleted] = true;
		if (g_bUseGenericMessage) {
			PrintAwardMsgToAll(Scattering_Ram, charger);
		} else {
			decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE];
			decl String:c_charger[MSG_SIZE];
			Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Scattering_Ram][s_Name]);
			Format(c_charger, MSG_SIZE, "{green}%N{default}", charger);
			if (!IsFakeClient(charger)) {
				Format(msg1, MSG_SIZE, "%T", "Message_Scattering_Ram_1", charger, colorized, num_scattered);
				CPrintToChat(charger, "%s %s", TAG_CHARGER, msg1);
			}
			CSkipNextClient(charger);
			for (i=1; i<=MaxClients; i++) {
				if (isScattered[i]) {
					if (!IsFakeClient(i)) {
						Format(msg1, MSG_SIZE, "%T", "Message_Scattering_Ram_2", i, colorized, c_charger);
						CPrintToChat(i, "%s %s", TAG_CHARGER, msg1);
					}
					CSkipNextClient(i);
				}
			}
			Format(msg1, MSG_SIZE, "%T", "Message_Scattering_Ram_3", LANG_SERVER, colorized, c_charger, num_scattered);
			CPrintToChatAll("%s %s", TAG_CHARGER, msg1);
		}
	}
}

public Action:_Event__Player_Now_It(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[player_now_it] Begin..");
	new it = GetClientOfUserId(GetEventInt(event, "userid"));
	new boomer = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!IsPlayerClient(it) || !IsPlayerClient(boomer))
		return;
	
	new bool:byBoomer = GetEventBool(event, "by_boomer");
	new bool:byExplosion = GetEventBool(event, "exploded");
	new bool:isInfectious = GetEventBool(event, "infected");		// outbreak?
	DebugPrintToAll("[player_now_it] it = %i, boomer = %i, byBoomer = %b, byExplosion = %b, isInfectious = %b", it, boomer, byBoomer, byExplosion, isInfectious);
	if (byBoomer) {
		DebugPrintToAll("[player_now_it] Achievement 'Stomach Upset' failed.");
		for (new i=1; i<=MaxClients; i++) {
			if (IsClientInGame(i)) {
				if (GetClientTeam(i) == TEAM_SURVIVORS)
					PreventAchievement(i, Stomach_Upset);
			}
		}
		if (byExplosion) {
			if (GetClientTeam(it) == TEAM_SURVIVORS) {
				if (g_eClientInfo[boomer][b_isShoved]) {
					DebugPrintToAll("[player_now_it] 'it' is covered in bile and boomer was shoved.. stop potential clean kill.");
					for (new i=1; i<=MaxClients; i++) {
						if (g_hTimer__CleanKill[i][boomer] != INVALID_HANDLE) {
							DebugPrintToAll("[player_now_it] Achievement 'Clean_Kill' failed. Killing timer for '%N'.", i);
							KillTimer(g_hTimer__CleanKill[i][boomer]);
							g_hTimer__CleanKill[i][boomer] = INVALID_HANDLE;
						}
					}
					g_eClientInfo[boomer][b_isShoved] = false;
					g_eClientInfo[boomer][Shoved_Id] = -1;
				}
				g_eClientInfo[it][b_isBiledOn] = true;
				g_eClientInfo[it][Puker_Id] = boomer;
			}
		} else {
			DebugPrintToAll("[player_now_it] 'it' (%N) is a potential 'Barf Bagged' victim & 'Blind Luck' winner.", it);
			g_eClientInfo[it][b_isPukedOn] = true;
			g_eClientInfo[it][Puker_Id] = boomer;
			if ((IsPrevented(Barf_Bagged, boomer) || !IsRepeatable(Barf_Bagged, boomer))
			&& (IsPrevented(Blind_Luck, it) || !IsRepeatable(Blind_Luck, it))) {
				DebugPrintToAll("[player_now_it] Achievement 'Barf Bagged' is prevented from being earned by boomer '%N' & achievement 'Blind Luck' is prevented from being earned by it '%N'. Aborting..", boomer, it);
			} else {
				if (IsPrevented(Blind_Luck, it) || !IsRepeatable(Blind_Luck, it)) {
					DebugPrintToAll("[player_now_it] 'Blind Luck' is prevented from being earned by it '%N'.", it);
				} else {
					DebugPrintToAll("[player_now_it] Begin 'Blind Luck' timer.");
				//	CreateTimer(g_fSurvivorItDuration, _Timer__CheckBlindLuck, boomer, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

public Action:_Event__Player_No_Longer_It(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[player_no_longer_it] Begin..");
	new clean = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsPlayerClient(clean))
		return;
	
	DebugPrintToAll("[player_no_longer_it] squeaky clean client = '%N'.", clean);
	g_eClientInfo[clean][b_isPukedOn] = false;
	g_eClientInfo[clean][b_isBiledOn] = false;
	g_eClientInfo[clean][Puker_Id] = -1;
}

public Action:_Event__Hunter_Headshot(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[hunter_headshot] Begin..");
	if (!g_bEnabled) return;
	
	new survivor = GetClientOfUserId(GetEventInt(event, "userid"));
	new hunter = GetClientOfUserId(GetEventInt(event, "hunteruserid"));
	if (!IsPlayerClient(survivor) || !IsPlayerClient(hunter))
		return;
	
	DebugPrintToAll("[hunter_headshot] Hunter '%N' was headshotted by '%N'.", hunter, survivor);
	new bool:lunging = GetEventBool(event, "islunging");
	if (lunging) {
		DebugPrintToAll("[hunter_headshot] hunter was headshotted while lunging!");
		if (!IsPrevented(Jump_Shot, survivor) && IsRepeatable(Jump_Shot, survivor)) {
			DebugPrintToAll("[hunter_headshot] Achievement 'Jump_Shot' is qualified!");
			if (g_bUseGenericMessage) {
				PrintAwardMsgToAll(Jump_Shot, survivor);
			} else {
				decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE];
				decl String:c_survivor[MSG_SIZE], String:c_hunter[MSG_SIZE];
				Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Jump_Shot][s_Name]);
				Format(c_survivor, MSG_SIZE, "{green}%N{default}", survivor);
				Format(c_hunter, MSG_SIZE, "{green}%N{default}", hunter);
				if (!IsFakeClient(survivor)) {
					Format(msg1, MSG_SIZE, "%T", "Message_Jump_Shot_1", survivor, colorized, c_hunter);
					CPrintToChat(survivor, "%s %s", TAG_HUNTER, msg1);
				}
				CSkipNextClient(survivor);
				if (!IsFakeClient(hunter)) {
					Format(msg1, MSG_SIZE, "%T", "Message_Jump_Shot_2", hunter, colorized, c_survivor);
					CPrintToChat(hunter, "%s %s", TAG_HUNTER, msg1);
				}
				CSkipNextClient(hunter);
				Format(msg1, MSG_SIZE, "%T", "Message_Jump_Shot_3", LANG_SERVER, colorized, c_survivor, c_hunter);
				CPrintToChatAll("%s %s", TAG_HUNTER, msg1);
			}
		}
	}
}

public Action:_Event__Hunter_Punched(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[hunter_punched] Begin..");
	if (!g_bEnabled) return;
	
	new survivor = GetClientOfUserId(GetEventInt(event, "userid"));
	new hunter = GetClientOfUserId(GetEventInt(event, "hunteruserid"));
	if (!IsPlayerClient(survivor) || !IsPlayerClient(hunter))
		return;
	
	// recently noticed mid-air infected getting "stuck".. don't know why yet, but thats not the problem (yet)..
	// this allows actions like the dead_stop hunter punch to be repeated many times
	// added a timer to prevent it from being earned more then 1ce a pounce.
	DebugPrintToAll("[hunter_punched] Hunter '%N' was punched by '%N'.", hunter, survivor);
	new bool:lunging = GetEventBool(event, "islunging");
	if (lunging) {
		DebugPrintToAll("[hunter_punched] hunter was punched while lunging!");
		if (g_hTimer__PunchedOut[hunter] == INVALID_HANDLE) {
			// using an arbitrary time of 3 seconds.. it takes 1 second just to crouch for a re-pounce
			g_hTimer__PunchedOut[hunter] = CreateTimer(3.0, _Timer__PunchedOut, hunter);
			if (!IsPrevented(Dead_Stop, survivor) && IsRepeatable(Dead_Stop, survivor)) {
				DebugPrintToAll("[hunter_punched] Achievement 'Dead_Stop' is qualified!");
				if (g_bUseGenericMessage) {
					PrintAwardMsgToAll(Dead_Stop, survivor);
				} else {
					decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE];
					decl String:c_survivor[MSG_SIZE], String:c_hunter[MSG_SIZE];
					Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Dead_Stop][s_Name]);
					Format(c_survivor, MSG_SIZE, "{green}%N{default}", survivor);
					Format(c_hunter, MSG_SIZE, "{green}%N{default}", hunter);
					if (!IsFakeClient(survivor)) {
						Format(msg1, MSG_SIZE, "%T", "Message_Dead_Stop_1", survivor, colorized, c_hunter);
						CPrintToChat(survivor, "%s %s", TAG_HUNTER, msg1);
					}
					CSkipNextClient(survivor);
					if (!IsFakeClient(hunter)) {
						Format(msg1, MSG_SIZE, "%T", "Message_Dead_Stop_2", hunter, colorized, c_survivor);
						CPrintToChat(hunter, "%s %s", TAG_HUNTER, msg1);
					}
					CSkipNextClient(hunter);
					Format(msg1, MSG_SIZE, "%T", "Message_Dead_Stop_3", LANG_SERVER, colorized, c_survivor, c_hunter);
					CPrintToChatAll("%s %s", TAG_HUNTER, msg1);
				}
			}
		} else {
			DebugPrintToAll("[hunter_punched] Hunter was already punched mid-air..");
		}
	}
}

public Action:_Timer__PunchedOut(Handle:timer, any:hunter) {
	g_hTimer__PunchedOut[hunter] = INVALID_HANDLE;
}

public Action:_Event__Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[tank_spawn] Begin..");
	if (!g_bEnabled) return;
	
	new id = GetEventInt(event, "userid");
	new tank = GetClientOfUserId(id);
	if (!IsPlayerClient(tank))
		return;
	
	new tankid = GetEventInt(event, "tankid");
	DebugPrintToAll("[tank_spawn] id = %i, tank = %i, tankid = %i", id, tank, tankid);
	
	new bool:frustrated = ReplaceTank(id);
	if (!frustrated) {
		DebugPrintToAll("[tank_spawn] new tank, adding to tank_index.");
		Rebuild_TankIndex(id);
	} else {
		DebugPrintToAll("[tank_spawn] tank just replaced a frustrated teammate.");
	}
}

public Action:_Event__Tank_Frustrated(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[tank_frustrated] Begin..");
	if (!g_bEnabled) return;
	
	new tankid = GetEventInt(event, "userid");
	new tank = GetClientOfUserId(tankid);
	if (!IsPlayerClient(tank))
		return;
	
	new tank_index = FindTankIndex(tankid);
	DebugPrintToAll("[tank_frustrated] tank_id = %i, Client(%i) = '%N', tank_index = %i", tankid, tank, tank, tank_index);
	g_eClientInfo[tank][b_isFrustrated] = true;
	g_eClientInfo[tank][Frustrated_index] = tank_index;
	Reset_All4Dead(tank);
}

public Action:_Event__Tank_Killed(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[tank_killed] Begin..");
	if (!g_bEnabled) return;
	
	new tankid = GetEventInt(event, "userid");
	new tank = GetClientOfUserId(tankid);
	if (!IsPlayerClient(tank))
		return;
	
	DebugPrintToAll("[tank_killed] tankid = %i, tank (%i) '%N'.", tankid, tank, tank);
	Reset_All4Dead(tank);
	
	new tank_id = FindTankIndex(tankid);
	if (tank_id == -1) {
		DebugPrintToAll("[tank_killed] Dead tank is not in tank_index?!? Aborting..");
		return;
	}
	
	DebugPrintToAll("[tank_killed] tank_index tank_id = %i", tank_id);
	Rebuild_TankIndex(tankid, false);
	
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!IsPlayerClient(killer))
		return;
	
	new killer_team = GetClientTeam(killer);
	DebugPrintToAll("[tank_killed] killer (%i) '%N'.", killer, killer);
	// Tankbusters..
	if (!g_eTankIndex[tank_id][TankHasHurt]) {
		if (IsPrevented(Tankbusters) || !IsRepeatable(Tankbusters)) {
			DebugPrintToAll("[tank_killed] Achievement 'Tankbusters' is prevented from being earned by anyone. Aborting..");
		} else {
			new bool:isValid = false;
			for (new i=1; i<=MaxClients; i++) {
				if (IsClientInGame(i)) {
					if (GetClientTeam(i) == TEAM_SURVIVORS) {
						if (!IsPrevented(Tankbusters, i) && IsRepeatable(Tankbusters, i)) {
							isValid = true;
							break;
						}
					}
				}
			}
			if (isValid) {
				DebugPrintToAll("[tank_killed] Achievement 'Tankbusters' is a success..");
				if (g_bUseGenericMessage) {
					PrintAwardMsgToAll(Tankbusters, NEG_T_SURVIVORS);
				} else {
					decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE], String:c_tank[MSG_SIZE];
					Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Tankbusters][s_Name]);
					Format(c_tank, MSG_SIZE, "{green}%N{default}", tank);
					for (new i=1; i<=MaxClients; i++) {
						if (IsClientInGame(i)) {
							if (!IsFakeClient(i)) {
								if (GetClientTeam(i) == TEAM_SURVIVORS) {
									g_eAchievementStatus[i][Tankbusters][b_IsCompleted] = true;
									Format(msg1, MSG_SIZE, "%T", "Message_Tankbusters_1", i, colorized, c_tank);
									CPrintToChat(i, "%s %s", TAG_TANK, msg1);
								} else if (GetClientTeam(i) == TEAM_INFECTED) {
									if (i == tank) {
										Format(msg1, MSG_SIZE, "%T", "Message_Tankbusters_2", tank, colorized);
										CPrintToChat(i, "%s %s", TAG_TANK, msg1);
									} else {
										Format(msg1, MSG_SIZE, "%T", "Message_Tankbusters_3", i, colorized, c_tank);
										CPrintToChat(i, "%s %s", TAG_TANK, msg1);
									}
								}
							}
						}
					}
				}
			} else {
				DebugPrintToAll("[tank_killed] Achievement 'Tankbusters' is prevented from being earned by all of the survivors. Aborting..");
			}
			
		}
	}
	// Man Vs Tank..
	new bool:bSolo = GetEventBool(event, "solo");
	if (bSolo && (killer_team == TEAM_SURVIVORS)) {
		DebugPrintToAll("[tank_killed] Tank was soloed by a survivor..");
		if (IsPrevented(Man_Vs_Tank, killer) || !IsRepeatable(Man_Vs_Tank, killer)) {
			DebugPrintToAll("[tank_killed] Achievement 'Man Vs Tank' is prevented from being earned by killer '%N'. Aborting..", killer);
		} else {
			DebugPrintToAll("[tank_killed] Achievement 'Man Vs Tank' is a success..");
			if (g_bUseGenericMessage) {
				PrintAwardMsgToAll(Man_Vs_Tank, killer);
			} else {
				decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE], String:c_tank[MSG_SIZE], String:c_killer[MSG_SIZE];
				Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Man_Vs_Tank][s_Name]);
				Format(c_tank, MSG_SIZE, "{green}%N{default}", tank);
				Format(c_killer, MSG_SIZE, "{green}%N{default}", killer);
				for (new i=1; i<=MaxClients; i++) {
					if (IsClientInGame(i)) {
						if (!IsFakeClient(i)) {
							if (i == killer) {
								Format(msg1, MSG_SIZE, "%T", "Message_Man_Vs_Tank_1", killer, colorized, c_tank);
								CPrintToChat(i, "%s %s", TAG_TANK, msg1);
							} else if (GetClientTeam(i) == TEAM_SURVIVORS) {
								Format(msg1, MSG_SIZE, "%T", "Message_Man_Vs_Tank_3", i, colorized, c_killer, c_tank);
								CPrintToChat(i, "%s %s", TAG_TANK, msg1);
							} else if (i == tank) {
								Format(msg1, MSG_SIZE, "%T", "Message_Man_Vs_Tank_2", tank, colorized, c_killer);
								CPrintToChat(i, "%s %s", TAG_TANK, msg1);
							} else if (GetClientTeam(i) == TEAM_INFECTED) {
								Format(msg1, MSG_SIZE, "%T", "Message_Man_Vs_Tank_4", i, colorized, c_killer, c_tank);
								CPrintToChat(i, "%s %s", TAG_TANK, msg1);
							}
						}
					}
				}
			}
		}
	} else {
		// somehow an infected player killed the tank? - or maybe he killed himself..
		if (bSolo)
			DebugPrintToAll("[tank_killed] Tank soloed by a non-survivor.. team = %i.", killer_team);
	}
	if (g_bIsL4D2) {
		// Tank Burger..
		new bool:bMelee = GetEventBool(event, "melee_only");
		if (bMelee) {
			DebugPrintToAll("[tank_killed] Tank Killed 'melee_only' detected..");
			if (IsPrevented(Tank_Burger) || !IsRepeatable(Tank_Burger)) {
				DebugPrintToAll("[tank_killed] Achievement 'Tank_Burger' is prevented from being earned by anyone. Aborting..");
			} else {
				new bool:isValid = false;
				for (new i=1; i<=MaxClients; i++) {
					if (IsClientInGame(i)) {
						if (GetClientTeam(i) == TEAM_SURVIVORS) {
							if (!IsFakeClient(i)) {
								if (!IsPrevented(Tank_Burger, i) && IsRepeatable(Tank_Burger, i)) {
									isValid = true;
									break;
								}
							}
						}
					}
				}
				if (isValid) {
					DebugPrintToAll("[tank_killed] Achievement 'Tank_Burger' is a success..");
					if (g_bUseGenericMessage) {
						PrintAwardMsgToAll(Tank_Burger, NEG_T_SURVIVORS);
					} else {
						decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE], String:c_tank[MSG_SIZE];
						Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Tank_Burger][s_Name]);
						Format(c_tank, MSG_SIZE, "{green}%N{default}", tank);
						for (new i=1; i<=MaxClients; i++) {
							if (IsClientInGame(i)) {
								if (GetClientTeam(i) == TEAM_SURVIVORS) {
									if (!IsFakeClient(i)) {
										Format(msg1, MSG_SIZE, "%T", "Message_Tank_Burger_1", i, colorized, c_tank);
										CPrintToChat(i, "%s %s", TAG_TANK, msg1);
									} else if (i == tank) {
										Format(msg1, MSG_SIZE, "%T", "Message_Tank_Burger_2", tank, colorized);
										CPrintToChat(i, "%s %s", TAG_TANK, msg1);
									} else if (GetClientTeam(i) == TEAM_INFECTED) {
										Format(msg1, MSG_SIZE, "%T", "Message_Tank_Burger_3", i, colorized, c_tank);
										CPrintToChat(i, "%s %s", TAG_TANK, msg1);
									}
								}
							}
						}
					}
				} else {
					DebugPrintToAll("[tank_killed] Achievement 'Tank Burger' is prevented from being earned by all of the survivors. Aborting..");
				}
			}
		}
		// Kite Like A Man
		new bool:bL4D1 = GetEventBool(event, "l4d1_only");
		if (bL4D1) {
			DebugPrintToAll("Event: Tank Killed 'l4d1_only' detected.."); 
			// This can only be earned in the passing.. and only in coop since versus doesn't spawn the l4d1 chars.
			// Well it seems as though it's possible to have them in versus now as well..
			if (IsPrevented(Kite_Like_A_Man) || !IsRepeatable(Kite_Like_A_Man)) {
				DebugPrintToAll("[tank_killed] Achievement 'Kite_Like_A_Man' is prevented from being earned by anyone. Aborting..");
			} else {
				new bool:isValid = false;
				for (new i=1; i<=MaxClients; i++) {
					if (IsClientInGame(i)) {
						if (GetClientTeam(i) == TEAM_SURVIVORS) {
							if (!IsFakeClient(i)) {
								if (!IsPrevented(Kite_Like_A_Man, i) && IsRepeatable(Kite_Like_A_Man, i)) {
									isValid = true;
									break;
								}
							}
						}
					}
				}
				if (isValid) {
					DebugPrintToAll("[tank_killed] Achievement 'Kite_Like_A_Man' is a success..");
					if (g_bUseGenericMessage) {
						PrintAwardMsgToAll(Tank_Burger, NEG_T_SURVIVORS);
					} else {
						decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE], String:c_tank[MSG_SIZE];
						Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Kite_Like_A_Man][s_Name]);
						Format(c_tank, MSG_SIZE, "{green}%N{default}", tank);
						for (new i=1; i<=MaxClients; i++) {
							if (IsClientInGame(i)) {
								if (!IsFakeClient(i)) {
									if (GetClientTeam(i) == TEAM_SURVIVORS) {
										Format(msg1, MSG_SIZE, "%T", "Message_Kite_Like_A_Man_1", i, colorized, c_tank);
										CPrintToChat(i, "%s %s", TAG_TANK, msg1);
									} else if (i == tank) {
										Format(msg1, MSG_SIZE, "%T", "Message_Kite_Like_A_Man_2", tank, colorized);
										CPrintToChat(i, "%s %s", TAG_TANK, msg1);
									} else if (GetClientTeam(i) == TEAM_INFECTED) {
										Format(msg1, MSG_SIZE, "%T", "Message_Kite_Like_A_Man_3", i, colorized, c_tank);
										CPrintToChat(i, "%s %s", TAG_TANK, msg1);
									}
								}
							}
						}
					}
				} else {
					DebugPrintToAll("[tank_killed] Achievement 'Kite_Like_A_Man' is prevented from being earned by all of the survivors. Aborting..");
				}
			}
		}
	}
}

public Action:_Event__StashWhacker_GameWon(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[stash_whacker_game_won] (SWGW) Begin..");
	if (!g_bEnabled) return;
	
	if (IsPrevented(Stache_Whacker)) {
		DebugPrintToAll("[SWGW] Stache Whacker is prevented from being earned. Aborting..");
	} else {
		new not_completed = 0;
		for (new i=1; i<=MaxClients; i++) {
			if (IsClientInGame(i)) {
				if ((GetClientTeam(i) == TEAM_SURVIVORS) && !IsFakeClient(i)) {
					if (!IsPlayerAlive(i) || IsPlayerIncapacitated(i)) {
						if (!IsRepeatable(Stache_Whacker, i))
							not_completed++;
						continue;
					}
					// give it to all survivors who are 'alive'
					g_eAchievementStatus[i][Stache_Whacker][b_IsCompleted] = true;
				}
			}
		}
		// Can't repeat this, and all the survivors got it already.. so skip it.
		if (!IsRepeatable(Stache_Whacker) && (not_completed == 0)) {
			DebugPrintToAll("[SWGW] Stache Whacker is not repeatable, and all the survivors have earned it already.");
		} else {
			if (g_bUseGenericMessage) {
				PrintAwardMsgToAll(Stache_Whacker, NEG_T_SURVIVORS);
			} else {
				decl String:msg1[MSG_SIZE], String:msg2[MSG_SIZE], String:colorized[MSG_SIZE];
				Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Stache_Whacker][s_Name]);
				for (new i=1; i<=MaxClients; i++) {
					if (IsClientInGame(i)) {
						if (!IsFakeClient(i)) {
							if (GetClientTeam(i) == TEAM_SURVIVORS) {
								Format(msg1, MSG_SIZE, "%T", "Message_Stache_Whacker_1", i, colorized);
								CPrintToChat(i, "%s %s", TAG_AWARD, msg1);
							} else if (GetClientTeam(i) == TEAM_INFECTED) {
								Format(msg2, MSG_SIZE, "%T", "Message_Stache_Whacker_2", i, colorized);
								CPrintToChat(i, "%s %s", TAG_AWARD, msg2);
							}
						}
					}
				}
			}
		}
	}
}

public Action:_Event__Strongman_BellKO(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[strongman_bell_knocked_off] (SmBKO) Begin..");
	if (!g_bEnabled) return;
	
	new strongman = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsPlayerClient(strongman))
		return;
	
	if (IsPrevented(Gong_Show, strongman) && !IsRepeatable(Gong_Show, strongman)) {
		DebugPrintToAll("[SmBKO] strongman '%N', cannot earn Gong Show right now. Aborting..", strongman);
	} else {
		g_eAchievementStatus[strongman][Gong_Show][b_IsCompleted] = true;
		DebugPrintToAll("[SmBKO] strongman = '%N', earns Gong Show.", strongman);
		if (g_bUseGenericMessage) {
			PrintAwardMsgToAll(Gong_Show, strongman);
		} else {
			decl String:msg1[MSG_SIZE], String:msg2[MSG_SIZE], String:msg3[MSG_SIZE];
			decl String:colorized[MSG_SIZE], String:c_strongman[MSG_SIZE];
			Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Gong_Show][s_Name]);
			Format(c_strongman, MSG_SIZE, "{green}%N{default}", strongman);
			for (new i=1; i<=MaxClients; i++) {
				if (IsClientInGame(i)) {
					if (!IsFakeClient(i)) {
						if (i == strongman) {
							Format(msg1, MSG_SIZE, "%T", "Message_Strongman_Bell_1", strongman, colorized);
							CPrintToChat(i, "%s %s", TAG_AWARD, msg1);
						} else if (GetClientTeam(i) == TEAM_SURVIVORS) {
							Format(msg2, MSG_SIZE, "%T", "Message_Strongman_Bell_2", i, colorized, c_strongman);
							CPrintToChat(i, "%s %s", TAG_AWARD, msg2);
						} else if (GetClientTeam(i) == TEAM_INFECTED) {
							Format(msg3, MSG_SIZE, "%T", "Message_Strongman_Bell_3", i, colorized, c_strongman);
							CPrintToChat(i, "%s %s", TAG_AWARD, msg3);
						}
					}
				}
			}
		}
	}
}

public Action:_Event__Charger_Impact(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[charger_impact] Begin..");
	if (!g_bEnabled) return;
	
	new charger = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!IsPlayerClient(charger) || !IsPlayerClient(victim))
		return;
	
	DebugPrintToAll("[charger_impact] charger = '%N', victim = '%N'.", charger, victim);
	if (IsPrevented(Scattering_Ram, charger) || !IsRepeatable(Scattering_Ram, charger))  {
		DebugPrintToAll("[charger_impact] Achievement 'Scattering Ram' is prevented from being earned by charger '%N'. Aborting..", charger);
	} else {
		g_eClientInfo[victim][b_isImpacted] = true;
		g_eClientInfo[victim][Impactor_Id] = charger;
	}
}

public Action:_Event__Charger_Carry_Start(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[charger_carry_start] Begin..");
	if (!g_bEnabled) return;
	
	new charger = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!IsPlayerClient(charger) || !IsPlayerClient(victim))
		return;
	
	new bool:isPrevented[2] = { false, false };
	DebugPrintToAll("[charger_carry_start] charger = '%N', victim = '%N'.", charger, victim);
	if (IsPrevented(Scattering_Ram, charger) || !IsRepeatable(Scattering_Ram, charger)) {
		DebugPrintToAll("[charger_carry_start] Achievement 'Scattering_Ram' is prevented from being earned by charger '%N'.", charger);
		isPrevented[0] = true;
	} else {
		g_eClientInfo[victim][b_isCarried] = true;
		g_eClientInfo[victim][Carrier_Id] = charger;
	}
	if (IsPrevented(Long_Distance_Carrier, charger) || !IsRepeatable(Long_Distance_Carrier, charger)) {
		DebugPrintToAll("[charger_carry_start] Achievement 'Long_Distance_Carrier' is prevented from being earned by charger '%N'.", charger);
		isPrevented[1] = true;
	} else {
		new Float:f_Origin[3];
		GetClientAbsOrigin(charger, f_Origin);
		g_eClientInfo[charger][f_CarryStartX] = f_Origin[0];
		g_eClientInfo[charger][f_CarryStartY] = f_Origin[1];
		g_eClientInfo[charger][f_CarryStartZ] = f_Origin[2];
	}
	if (isPrevented[0] && isPrevented[1]) {
		DebugPrintToAll("[charger_carry_start] charger has nothing to acomplish, aborting..");
		return;
	}
}

public Action:_Event__Charger_Carry_End(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[charger_carry_end] Begin..");
	if (!g_bEnabled) return;
	
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!IsPlayerClient(victim))
		return;
	
	DebugPrintToAll("[charger_carry_end] victim = '%N'.", victim);
	g_eClientInfo[victim][b_isCarried] = false;
	g_eClientInfo[victim][Carrier_Id] = -1;
	
	new charger = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsPlayerClient(charger))
		return;
	
	DebugPrintToAll("[charger_carry_end] charger = '%N'.", charger);
	if (IsPrevented(Long_Distance_Carrier, charger) || !IsRepeatable(Long_Distance_Carrier, charger)) {
		DebugPrintToAll("[charger_carry_end] Achievement 'Long_Distance_Carrier' is prevented from being earned by charger '%N'.", charger);
	} else {
		new Float:f_EndPos[3], Float:f_StartPos[3];
		GetClientAbsOrigin(charger, f_EndPos);
		f_StartPos[0] = g_eClientInfo[charger][f_CarryStartX];
		f_StartPos[1] = g_eClientInfo[charger][f_CarryStartY];
		f_StartPos[2] = g_eClientInfo[charger][f_CarryStartZ];
		new Float:f_Distance = GetVectorDistance(f_StartPos, f_EndPos);
		DebugPrintToAll("[charger_carry_end] Start = [%.2f %.2f %.2f], End = [%.2f %.2f %.2f], Distance = %.2f",
				f_StartPos[0], f_StartPos[1], f_StartPos[2],
				f_EndPos[0], f_EndPos[1], f_EndPos[2], f_Distance);
		// Distance is a Hammer Unit (HU). 1 HU ~= 1 inch. Long Distance Carrier is in feet.. so 12 inches = 1 foot.
		if (f_Distance >= (FloatMul(float(g_eAchievementInfo[Long_Distance_Carrier][Total]), 12.0))) {
			DebugPrintToAll("[charger_carry_end] Achievement 'Long Distance Carrier' qualified.");
			g_eAchievementStatus[charger][Long_Distance_Carrier][b_IsCompleted] = true;
			if (g_bUseGenericMessage) {
				PrintAwardMsgToAll(Long_Distance_Carrier, charger);
			} else {
				decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE];
				decl String:c_charger[MSG_SIZE], String:c_victim[MSG_SIZE];
				Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Long_Distance_Carrier][s_Name]);
				Format(c_charger, MSG_SIZE, "{green}%N{default}", charger);
				Format(c_victim, MSG_SIZE, "{green}%N{default}", victim);
				if (!IsFakeClient(charger)) {
					Format(msg1, MSG_SIZE, "%T", "Message_Long_Distance_Carrier_1", charger, colorized, c_victim);
					CPrintToChat(charger, "%s %s", TAG_CHARGER, msg1);
				}
				CSkipNextClient(charger);
				if (!IsFakeClient(victim)) {
					Format(msg1, MSG_SIZE, "%T", "Message_Long_Distance_Carrier_2", victim, colorized, c_charger);
					CPrintToChat(victim, "%s %s", TAG_CHARGER, msg1);
				}
				CSkipNextClient(victim);
				Format(msg1, MSG_SIZE, "%T", "Message_Long_Distance_Carrier_3", LANG_SERVER, colorized, c_charger, c_victim);
				CPrintToChatAll("%s %s", TAG_CHARGER, msg1);
			}
		} else {
			DebugPrintToAll("[charger_carry_end] Distance to short (%.2f of %i feet) for 'Long Distance Carrier'.", f_Distance, g_eAchievementInfo[Long_Distance_Carrier][Total]);
		}
	}
}

public Action:_Event__Charger_Pummel_Start(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[charger_pummel_start] Begin..");
	if (!g_bEnabled) return;
	
	new charger = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!IsPlayerClient(charger) || !IsPlayerClient(victim))
		return;
	
	DebugPrintToAll("[charger_pummel_start] charger = '%N', victim = '%N'.", charger, victim);
	if (IsPrevented(Meat_Tenderizer, charger) || !IsRepeatable(Meat_Tenderizer, charger)) {
		DebugPrintToAll("[charger_pummel_start] Achievement 'Meat Tenderizer' is prevented from being earned by charger '%N'. Aborting..", charger);
	} else {
		g_eClientInfo[victim][b_isPummeled] = true;
		g_eClientInfo[victim][Pummeler_Id] = charger;
		
		// hmm? possible?
		if (g_hTimer__Pummel[charger] != INVALID_HANDLE) {
			DebugPrintToAll("[charger_pummel_start] charger already has a pummel timer active!?! kill it.");
			KillTimer(g_hTimer__Pummel[charger]);
		}
		new Float:duration = float(g_eAchievementInfo[Meat_Tenderizer][Total]);
		g_hTimer__Pummel[charger] = CreateTimer(duration, _Timer__Pummel, charger);
	}
}

public Action:_Event__Charger_Pummel_End(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[charger_pummel_end] Begin..");
	if (!g_bEnabled) return;
	
	new charger = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsPlayerClient(charger))
		return;
	
	DebugPrintToAll("Event: charger = '%N'.", charger);
	// Kill Meat Tenderizer tracking, since this fired first..
	if (g_hTimer__Pummel[charger] != INVALID_HANDLE) {
		DebugPrintToAll("[charger_pummel_end] Achievement 'Meat Tenderizer' failed.");
		KillTimer(g_hTimer__Pummel[charger]);
		g_hTimer__Pummel[charger] = INVALID_HANDLE;
	}
	
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!IsPlayerClient(victim))
		return;
	
	DebugPrintToAll("[charger_pummel_end] Former victim = '%N'.", victim);
	g_eClientInfo[victim][b_isPummeled] = false;
	g_eClientInfo[victim][Pummeler_Id] = -1;
}

public Action:_Timer__Pummel(Handle:timer, any:charger) {
	g_hTimer__Pummel[charger] = INVALID_HANDLE;
	DebugPrintToAll("[_Timer__Pummel] Times up..");
	
	new victim = 0;
	for (new i=1; i<=MaxClients; i++) {
		if (g_eClientInfo[i][Pummeler_Id] == charger) {
			DebugPrintToAll("[_Timer__Pummel] 'Meat Tenderizer' detected on '%N' by '%N'.", i, charger);
			g_eClientInfo[i][b_isPummeled] = false;
			g_eClientInfo[i][Pummeler_Id] = -1;
			victim = i;
			break;
		}
	}
	if (!victim) {
		DebugPrintToAll("[_Timer__Pummel] No victim found for charger '%N'???", charger);
		return;
	}
	
	g_eAchievementStatus[charger][Meat_Tenderizer][b_IsCompleted] = true;
	if (g_bUseGenericMessage) {
		PrintAwardMsgToAll(Meat_Tenderizer, charger);
	} else {
		decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE];
		decl String:c_charger[MSG_SIZE], String:c_victim[MSG_SIZE];
		Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Meat_Tenderizer][s_Name]);
		Format(c_charger, MSG_SIZE, "{green}%N{default}", charger);
		Format(c_victim, MSG_SIZE, "{green}%N{default}", victim);
		if (!IsFakeClient(charger)) {
			Format(msg1, MSG_SIZE, "%T", "Message_Meat_Tenderizer_1", charger, colorized, c_victim);
			CPrintToChat(charger, "%s %s", TAG_CHARGER, msg1);
		}
		CSkipNextClient(charger);
		if (!IsFakeClient(victim)) {
			Format(msg1, MSG_SIZE, "%T", "Message_Meat_Tenderizer_2", victim, colorized, c_charger);
			CPrintToChat(victim, "%s %s", TAG_CHARGER, msg1);
		}
		CSkipNextClient(victim);
		Format(msg1, MSG_SIZE, "%T", "Message_Meat_Tenderizer_3", LANG_SERVER, colorized, c_charger, c_victim);
		CPrintToChatAll("%s %s", TAG_CHARGER, msg1);
	}
}

public Action:_Event__Charger_Killed(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[charger_killed] Begin..");
	if (!g_bEnabled) return;
	
	new charger = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsPlayerClient(charger))
		return;
	
	DebugPrintToAll("[charger_killed] charger = '%N'.", charger);
	if (g_hTimer__Ability[charger] != INVALID_HANDLE) {
		DebugPrintToAll("[charger_killed] Achievement 'Scattering Ram' failed.");
		KillTimer(g_hTimer__Ability[charger]);
		g_hTimer__Ability[charger] = INVALID_HANDLE;
	}
	if (g_hTimer__Pummel[charger] != INVALID_HANDLE) {
		DebugPrintToAll("[charger_killed] Achievement 'Meat Tenderizer' failed.");
		KillTimer(g_hTimer__Pummel[charger]);
		g_hTimer__Pummel[charger] = INVALID_HANDLE;
	}
	g_eClientInfo[charger][f_CarryStartX] = 0.0;
	g_eClientInfo[charger][f_CarryStartY] = 0.0;
	g_eClientInfo[charger][f_CarryStartZ] = 0.0;
	for (new i=1; i<=MaxClients; i++) {
		if (g_eClientInfo[i][Impactor_Id] == charger) {
			g_eClientInfo[i][Impactor_Id] = -1;
			g_eClientInfo[i][b_isImpacted] = false;
		}
		if (g_eClientInfo[i][Carrier_Id] == charger) {
			g_eClientInfo[i][Carrier_Id] = -1;
			g_eClientInfo[i][b_isCarried] = false;
		}
		if (g_eClientInfo[i][Pummeler_Id] == charger) {
			g_eClientInfo[i][Pummeler_Id] = -1;
			g_eClientInfo[i][b_isPummeled] = false;
		}
	}
	
	new bool:IsCharging = GetEventBool(event, "charging");
	new bool:IsMelee = GetEventBool(event, "melee");
	DebugPrintToAll("[charger_killed] charging = %b, melee = %b.", IsCharging, IsMelee);
	// Level A Charge
	if (IsMelee && IsCharging) {
		new survivor = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (!IsPlayerClient(survivor))
			return;
		
		DebugPrintToAll("[charger_killed] charger killed by '%N'.", survivor);
		if (IsPrevented(Level_A_Charge, survivor) || !IsRepeatable(Level_A_Charge, survivor)) {
			DebugPrintToAll("[charger_killed] Achievement 'Level A Charge' is prevented from being earned by survivor '%N'. Aborting..", survivor);
			return;
		}
		
		decl String:weaponname[MELEE_DESC_SIZE];
		GetClientWeapon(survivor, weaponname, MELEE_DESC_SIZE);
		if (!StrEqual(weaponname, "weapon_melee")) {
			DebugPrintToAll("[charger_killed] Killed by melee attack, yet not by melee weapon! weaponname = '%s'.", weaponname);
			return;
		} else {
			DebugPrintToAll("[charger_killed] Achievement 'Level A Charge' detected. weaponname = '%s'.", weaponname);
			g_eAchievementStatus[survivor][Level_A_Charge][b_IsCompleted] = true;
		}
		
		GetEntPropString(GetPlayerWeaponSlot(survivor, 1), Prop_Data, "m_strMapSetScriptName", weaponname, MELEE_DESC_SIZE);
		new weapon = GetMeleeWeapon(weaponname);
		
		if (g_bUseGenericMessage) {
			PrintAwardMsgToAll(Level_A_Charge, survivor);
		} else {
			decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE];
			decl String:c_charger[MSG_SIZE], String:c_survivor[MSG_SIZE];
			Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Level_A_Charge][s_Name]);
			Format(c_charger, MSG_SIZE, "{green}%N{default}", charger);
			Format(c_survivor, MSG_SIZE, "{green}%N{default}", survivor);
			// g_eMeleeInfo[weapon][s_WeaponDesc] is already colorized and translated.. its a/an {olive}weapon{default}
			if (!IsFakeClient(survivor)) {
				Format(msg1, MSG_SIZE, "%T", "Message_Level_A_Charge_1", survivor, colorized, c_charger, g_eMeleeInfo[weapon][s_WeaponDesc]);
				CPrintToChat(survivor, "%s %s", TAG_CHARGER, msg1);
			}
			CSkipNextClient(survivor);
			if (!IsFakeClient(charger)) {
				Format(msg1, MSG_SIZE, "%T", "Message_Level_A_Charge_2", charger, colorized, c_survivor, g_eMeleeInfo[weapon][s_WeaponDesc]);
				CPrintToChat(charger, "%s %s", TAG_CHARGER, msg1);
			}
			CSkipNextClient(charger);
			Format(msg1, MSG_SIZE, "%T", "Message_Level_A_Charge_3", LANG_SERVER, colorized, c_survivor, c_charger, g_eMeleeInfo[weapon][s_WeaponDesc]);
			CPrintToChatAll("%s %s", TAG_CHARGER, msg1);
		}
	}
}

public Action:_Event__Jockey_Ride(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[jockey_ride] Begin..");
	if (!g_bEnabled) return;
	
	new jockey = GetClientOfUserId(GetEventInt(event, "userid"));
	new mule = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!IsPlayerClient(jockey) || !IsPlayerClient(mule))
		return;
	
	DebugPrintToAll("[jockey_ride] jockey = '%N', mule = '%N'.", jockey, mule);
	g_eClientInfo[jockey][CurMule_Id] = mule;
	if (g_hTimer__JockeyRide[jockey] != INVALID_HANDLE) {
		DebugPrintToAll("[jockey_ride] Jockey has managed to jump twice in less then 2 seconds.. Kill existing timer.");
		KillTimer(g_hTimer__JockeyRide[jockey]);
		g_hTimer__JockeyRide[jockey] = INVALID_HANDLE;
	}
	/*
		Back in the Saddle:
		- A Ride Denied would over-rule Back in the Saddle.
			This means you cannot earn Back in the Saddle unless BOTH rides are >= 2.0 seconds.
		- Also, since some modded servers allow jockeys to dismount, they break the 'rules' of
			how this should work. Don't allow the achievement if both mules are the same person.
	*/
	if (IsPrevented(Back_In_The_Saddle, jockey) || !IsRepeatable(Back_In_The_Saddle, jockey))  {
		DebugPrintToAll("[jockey_ride] Achievement 'Back In The Saddle' is prevented from being earned by jockey '%N'. Aborting..", jockey);
		return;
	}
	if (g_eClientInfo[jockey][PrevMule_Id] != g_eClientInfo[jockey][CurMule_Id]) {
		if (g_eClientInfo[jockey][PrevMule_Id] != -1)
			DebugPrintToAll("[jockey_ride] This mule is not the same as the last one (%N). Begin timer for 'Back in the Saddle'.", g_eClientInfo[jockey][PrevMule_Id]);
		else
			DebugPrintToAll("[jockey_ride] This mule is the first one. Begin timer for 'Back in the Saddle'.");
		new Float:duration = float(g_eAchievementInfo[A_Ride_Denied][Total]);
		g_hTimer__JockeyRide[jockey] = CreateTimer(duration, _Timer__JockeyRide, jockey);
	}
}

public Action:_Event__Jockey_Ride_End(Handle:event, const String:name[], bool:dontBroadcast) {
	DebugPrintToAll("[jockey_ride_end] Begin..");
	new jockey = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsPlayerClient(jockey))
		return;
	
	DebugPrintToAll("[jockey_ride_end] jockey = '%N'.", jockey);
	if (g_hTimer__JockeyRide[jockey] != INVALID_HANDLE) {
		DebugPrintToAll("[jockey_ride_end] 'Back in the Saddle' attempt failed.");
		g_eClientInfo[jockey][CurMule_Id] = -1;
		KillTimer(g_hTimer__JockeyRide[jockey]);
		g_hTimer__JockeyRide[jockey] = INVALID_HANDLE;
	}
	
	new mule = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!IsPlayerClient(mule))
		return;
	
	DebugPrintToAll("[jockey_ride_end] mule = '%N'.", mule);
	new Float:duration = GetEventFloat(event, "ride_length");
	if (duration < float(g_eAchievementInfo[A_Ride_Denied][Total])) {
		new rescuer = GetClientOfUserId(GetEventInt(event, "rescuer"));
		if ((rescuer > 0) && (rescuer <= MaxClients)) {		// saved by a person!?!
			DebugPrintToAll("[jockey_ride_end] Mule rescuer = '%N'.", rescuer);
			if (GetClientTeam(rescuer) == TEAM_SURVIVORS) {	// saved by a teammate (and not eg: a mean tank)
				if (IsPrevented(A_Ride_Denied, rescuer) || !IsRepeatable(A_Ride_Denied, rescuer)) {
					DebugPrintToAll("[jockey_ride_end] Achievement 'A Ride Denied' is prevented from being earned by rescuer '%N'. Aborting..", rescuer);
					return;
				}
				DebugPrintToAll("[jockey_ride_end] Rescuer is a teammate, 'A Ride Denied' qualified.");
				if (g_bUseGenericMessage) {
					PrintAwardMsgToAll(A_Ride_Denied, rescuer);
				} else {
					decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE];
					decl String:c_jockey[MSG_SIZE], String:c_mule[MSG_SIZE], String:c_rescuer[MSG_SIZE];
					Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[A_Ride_Denied][s_Name]);
					Format(c_jockey, MSG_SIZE, "{green}%N{default}", jockey);
					Format(c_mule, MSG_SIZE, "{green}%N{default}", mule);
					Format(c_rescuer, MSG_SIZE, "{green}%N{default}", rescuer);
					if (!IsFakeClient(rescuer)) {
						Format(msg1, MSG_SIZE, "%T", "Message_A_Ride_Denied_1", rescuer, colorized, c_jockey, c_mule);
						CPrintToChat(rescuer, "%s %s", TAG_JOCKEY, msg1);
					}
					CSkipNextClient(rescuer);
					if (!IsFakeClient(mule)) {
						Format(msg1, MSG_SIZE, "%T", "Message_A_Ride_Denied_2", mule, colorized, c_jockey, c_rescuer);
						CPrintToChat(mule, "%s %s", TAG_JOCKEY, msg1);
					}
					CSkipNextClient(mule);
					if (!IsFakeClient(jockey)) {
						Format(msg1, MSG_SIZE, "%T", "Message_A_Ride_Denied_3", jockey, colorized, c_rescuer, c_mule);
						CPrintToChat(jockey, "%s %s", TAG_JOCKEY, msg1);
					}
					CSkipNextClient(jockey);
					Format(msg1, MSG_SIZE, "%T", "Message_A_Ride_Denied_4", LANG_SERVER, colorized, c_rescuer, c_mule, c_jockey);
					CPrintToChatAll("%s %s", TAG_JOCKEY, msg1);
				}
			}
		}
	} else if (duration >= float(g_eAchievementInfo[Qualified_Ride][Total])) {
		// Is this achievement prevented from being won?
		if (IsPrevented(Qualified_Ride, jockey) || !IsRepeatable(Qualified_Ride, jockey)) {
			DebugPrintToAll("[jockey_ride_end] Achievement 'Qualified Ride' is prevented from being earned by jockey '%N'. Aborting..", jockey);
			return;
		}
		DebugPrintToAll("[jockey_ride_end] 'Qualified Ride' QUALIFIED!");
		if (g_bUseGenericMessage) {
			PrintAwardMsgToAll(Qualified_Ride, jockey);
		} else {
			decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE];
			decl String:c_jockey[MSG_SIZE], String:c_mule[MSG_SIZE];
			Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Qualified_Ride][s_Name]);
			Format(c_jockey, MSG_SIZE, "{green}%N{default}", jockey);
			Format(c_mule, MSG_SIZE, "{green}%N{default}", mule);
			if (!IsFakeClient(jockey)) {
				Format(msg1, MSG_SIZE, "%T", "Message_Qualified_Ride_1", jockey, colorized, c_mule);
				CPrintToChat(jockey, "%s %s", TAG_JOCKEY, msg1);
			}
			CSkipNextClient(jockey);
			if (!IsFakeClient(mule)) {
				Format(msg1, MSG_SIZE, "%T", "Message_Qualified_Ride_2", mule, colorized, c_jockey);
				CPrintToChat(mule, "%s %s", TAG_JOCKEY, msg1);
			}
			CSkipNextClient(mule);
			Format(msg1, MSG_SIZE, "%T", "Message_Qualified_Ride_3", LANG_SERVER, colorized, c_jockey, c_mule);
			CPrintToChatAll("%s %s", TAG_JOCKEY, msg1);
		}
	}
}

public Action:_Timer__JockeyRide(Handle:timer, any:jockey) {
	g_hTimer__JockeyRide[jockey] = INVALID_HANDLE;
	DebugPrintToAll("[_Timer__JockeyRide] Times up..");
	
	if (g_eClientInfo[jockey][PrevMule_Id] == -1) {		// No previous mule
		if (g_eClientInfo[jockey][CurMule_Id] == -1) {		// No current mule
			DebugPrintToAll("[_Timer__JockeyRide] No mules.. How did '%N' get here?", jockey);
		} else {											// There is a current mule
			DebugPrintToAll("[_Timer__JockeyRide] First ride of 'Back In The Saddle' qualified. Jockey '%N' First Mule '%N'", jockey, g_eClientInfo[jockey][CurMule_Id]);
			// Part 1 of Back In The Saddle has been qualified..
			g_eClientInfo[jockey][PrevMule_Id] = g_eClientInfo[jockey][CurMule_Id];
			g_eClientInfo[jockey][CurMule_Id] = -1;
		}
	} else {												// There was a previous mule
		if (g_eClientInfo[jockey][CurMule_Id] == -1) {		// No current mule
			DebugPrintToAll("[_Timer__JockeyRide] No current mule.. How did '%N' get here? Nothing to do.", jockey);
		} else {											// There is a current mule
			DebugPrintToAll("[_Timer__JockeyRide] 'Back In The Saddle' requirements met.");
			g_eAchievementStatus[jockey][Back_In_The_Saddle][b_IsCompleted] = true;
			if (g_bUseGenericMessage) {
				PrintAwardMsgToAll(Back_In_The_Saddle, jockey);
			} else {
				decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE];
				decl String:c_jockey[MSG_SIZE];
				Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[Back_In_The_Saddle][s_Name]);
				Format(c_jockey, MSG_SIZE, "{green}%N{default}", jockey);
				if (!IsFakeClient(jockey)) {
					Format(msg1, MSG_SIZE, "%T", "Message_Back_In_The_Saddle_1", jockey, colorized);
					CPrintToChat(jockey, "%s %s", TAG_JOCKEY, msg1);
				}
				CSkipNextClient(jockey);
				if (!IsFakeClient(g_eClientInfo[jockey][CurMule_Id])) {
					Format(msg1, MSG_SIZE, "%T", "Message_Back_In_The_Saddle_2", g_eClientInfo[jockey][CurMule_Id], colorized, c_jockey);
					CPrintToChat(g_eClientInfo[jockey][CurMule_Id], "%s %s", TAG_JOCKEY, msg1);
				}
				CSkipNextClient(g_eClientInfo[jockey][CurMule_Id]);
				if (!IsFakeClient(g_eClientInfo[jockey][PrevMule_Id])) {
					Format(msg1, MSG_SIZE, "%T", "Message_Back_In_The_Saddle_2", g_eClientInfo[jockey][PrevMule_Id], colorized, c_jockey);
					CPrintToChat(g_eClientInfo[jockey][PrevMule_Id], "%s %s", TAG_JOCKEY, msg1);
				}
				CSkipNextClient(g_eClientInfo[jockey][PrevMule_Id]);
				Format(msg1, MSG_SIZE, "%T", "Message_Back_In_The_Saddle_3", LANG_SERVER, colorized, c_jockey);
				CPrintToChatAll("%s %s", TAG_JOCKEY, msg1);
				g_eClientInfo[jockey][PrevMule_Id] = -1;
				g_eClientInfo[jockey][CurMule_Id] = -1;
			}
		}
	}
}

static PrintAwardMsgToAll(g_eAchievements:Achievement, any:winner) {
//	Not filtering winner (let the calling function do that),
//	but it MUST be: NEG_T_INFECTED, NEG_T_SURVIVORS, 0 < winner <= MaxClients
	/*
		Valves achievement message goes something like (in l4d1):
		<Orange>[NAME]<Green> has earned the achievement <Blue><ALLCAPS>[ACHIEVEMENT]
		
		Can't do any of the colors as valve prints them (the blue isnt {blue}, the orange isnt {green} & green isnt {lightgreen}).. so:
		<TAG> {teamcolor:red/blue/lightgreen}[NAME]{default} has earned the achievement {olive}<ALLCAPS>[ACHIEVEMENT]
	*/
	DebugPrintToAll("Begin generic award message for Achievement: %i '%s'.", Achievement, g_eAchievementInfo[Achievement][s_Name]);
	decl String:msg1[MSG_SIZE], String:tmp[MSG_SIZE];
	decl String:colorized[MSG_SIZE], String:c_winner[MSG_SIZE];
	
	Format(tmp, MSG_SIZE, "%T", g_eAchievementInfo[Achievement][s_Name], LANG_SERVER);
	for (new i=0; i<strlen(tmp); i++)
		CharToUpper(tmp[i]);
	Format(colorized, MSG_SIZE, "{olive}%s{default}", tmp);
	
	if (IsPlayerClient(winner)) {		// team awards are -2 and -3, this returns false if < 1
		if (GetClientTeam(winner) == TEAM_SURVIVORS)
			Format(c_winner, MSG_SIZE, "{blue}%N{default}", winner);
		else if (GetClientTeam(winner) == TEAM_INFECTED)
			Format(c_winner, MSG_SIZE, "{red}%N{default}", winner);
		else
			Format(c_winner, MSG_SIZE, "{lightgreen}%N{default}", winner);
		
		Format(msg1, MSG_SIZE, "%T", "Generic Msg Winner", LANG_SERVER, colorized, c_winner);
		CPrintToChatAll("%s %s", TAG_AWARD, msg1);
	} else {		// instead of printing 4 messages.. just do 1 for the whole team
		winner -= (winner * 2);		// eg: team 3 = -3 - (-3 * 2) = -3 - (-6) = -3 + 6 = 3
		if (winner == TEAM_SURVIVORS) {
			Format(c_winner, MSG_SIZE, "%T", "Team_Survivors");
			Format(c_winner, MSG_SIZE, "{blue}%s{default}", c_winner);
		} else if (winner == TEAM_INFECTED) {
			Format(c_winner, MSG_SIZE, "%T", "Team_Infected");
			Format(c_winner, MSG_SIZE, "{red}%s{default}", c_winner);
		} else {		// this should not happen..
			Format(c_winner, MSG_SIZE, "{lightgreen}UNKNOWN{default}");
		}
		
		Format(msg1, MSG_SIZE, "%T", "Generic Msg Winner Plural", LANG_SERVER, colorized, c_winner);
		CPrintToChatAll("%s %s", TAG_AWARD, msg1);
	}
}

static CheckAll4Dead(any:tank) {
	// Check if prevented - may be a repeat, but it also may not..
	if (IsPrevented(All_4_Dead, tank) || !IsRepeatable(All_4_Dead, tank)) {
		DebugPrintToAll("[CheckAll4Dead] Achievement 'All_4_Dead' is prevented from being earned by tank '%N'. Aborting..", tank);
		return;
	}
	new num_killed = 0;
	new num_alive = 0;
	new victim_pool[MAXPLAYERS+1] = { -1, ... };
	for (new i=1; i<=MaxClients; i++) {
		if (IsClientInGame(i)) {
			if (GetClientTeam(i) == TEAM_SURVIVORS) {
				if (IsPlayerAlive(i) && !IsPlayerIncapacitated(i)) {
					num_alive++;
				} else {
					if (g_eClientInfo[i][Killer_Id] == tank)
						victim_pool[num_killed++] = i;
				}
			}
		}
	}
	new num_players = GetTeamClientCount(TEAM_SURVIVORS);
	DebugPrintToAll("[CheckAll4Dead] Total # of Survivors = %i, num_alive = %i, num_killed = %i.", num_players, num_alive, num_killed);
	/*
		All 4 Dead basically means: kill the entire team by yourself.
		
		If this is run on a server with team sizes = X (where X > 4),
		then All 4 Dead really means All X Dead.
		
		Also, if there are less then 4 survivors (eg: last man on earth, or just
		2 humans and bots kicked), you can't qualify for All 4 Dead at all.
	*/
	if (num_killed >=4) {
		if (num_killed == num_players) {
			DebugPrintToAll("[CheckAll4Dead] Achievement 'All 4 Dead' qualified!");
			g_eAchievementStatus[tank][All_4_Dead][b_IsCompleted] = true;
			if (g_bUseGenericMessage) {
				PrintAwardMsgToAll(All_4_Dead, tank);
			} else {
				decl String:msg1[MSG_SIZE], String:colorized[MSG_SIZE], String:c_tank[MSG_SIZE];
				Format(colorized, MSG_SIZE, "{olive}%s{default}", g_eAchievementInfo[All_4_Dead][s_Name]);
				Format(c_tank, MSG_SIZE, "{green}%N{default}", tank);
				for (new i=1; i<=MaxClients; i++) {
					if (IsClientInGame(i)) {
						if (!IsFakeClient(i)) {
							if (i == tank) {
								Format(msg1, MSG_SIZE, "%T", "Message_All_4_Dead_1", tank, colorized);
								CPrintToChat(tank, "%s %s", TAG_TANK, msg1);
							} else if (GetClientTeam(i) == TEAM_INFECTED) {
								Format(msg1, MSG_SIZE, "%T", "Message_All_4_Dead_2", i, colorized, c_tank);
								CPrintToChat(i, "%s %s", TAG_TANK, msg1);
							} else if (GetClientTeam(i) == TEAM_SURVIVORS) {
								Format(msg1, MSG_SIZE, "%T", "Message_All_4_Dead_3", i, colorized, c_tank);
								CPrintToChat(i, "%s %s", TAG_TANK, msg1);
							}
						}
					}
				}
			}
		} else {
			DebugPrintToAll("[CheckAll4Dead] num_killed >= 4, but not entire team. 'All 4 Dead' failed!");
		}
	} else {								// no go
		DebugPrintToAll("[CheckAll4Dead] Not enough kills: %i of %i, to get 'All 4 Dead'", num_killed, num_players);
	}
}

static Reset_All4Dead(tank) {
	g_eAchievementStatus[tank][All_4_Dead][Count] = 0;
	for (new i=1; i<=MaxClients; i++) {
		if (g_eClientInfo[i][Killer_Id] == tank)
			g_eClientInfo[i][Killer_Id] = -1;
	}
}

static FindAchievement(const String:sAchievement[]) {
	FOR_EACH_ACHIEVEMENT(i) {
		if (StrContains(g_eAchievementInfo[i][s_Name], sAchievement, false) != -1)
			return i;
	}
	return -1;
}

static PreventAchievement(client = -1, g_eAchievements:Achievement = UNDEFINED_ALL) {
/*
	List of achievements which can/should be prevented (any others won't matter):
	Safety_First, Stomache_Upset, Untouchables
*/
	new i,j;
	if (client == -1) {								// Prevent for all clients..
		if (Achievement == UNDEFINED_ALL) {		// Prevent everything.
			DebugPrintToAll("Preventing ALL achievements for ALL clients");
			for (j=1; j<=MaxClients; j++) {
				for (i=0; i<sizeof(g_eAchievementInfo[]); i++) {
					g_eAchievementStatus[j][i][b_IsPrevented] = true;
					g_eAchievementStatus[j][i][Count] = 0;
					g_eAchievementStatus[j][i][Target_Id] = -1;
				}
			}
		} else {									// Prevent 1 achievement.
			DebugPrintToAll("Preventing achievement: '%s' for ALL clients", g_eAchievementInfo[Achievement][s_Name]);
			for (i=1; i<=MaxClients; i++) {
				if (!g_eAchievementStatus[i][Achievement][b_IsPrevented]) {
					g_eAchievementStatus[i][Achievement][b_IsPrevented] = true;
					g_eAchievementStatus[i][Achievement][Count] = 0;
					g_eAchievementStatus[i][Achievement][Target_Id] = -1;
				}
			}
		}
	} else {										// Prevent for 1 client..
		if (Achievement == UNDEFINED_ALL) {		// Prevent everything.
			DebugPrintToAll("Preventing ALL achievements for client: '%N'", client);
			for (i=0; i<sizeof(g_eAchievementInfo[]); i++) {
				g_eAchievementStatus[client][i][b_IsPrevented] = true;
				g_eAchievementStatus[client][i][Count] = 0;
				g_eAchievementStatus[client][i][Target_Id] = -1;
			}
		} else if (!g_eAchievementStatus[client][Achievement][b_IsPrevented]) {
			DebugPrintToAll("Preventing Achievement: %s for client: '%N'", g_eAchievementInfo[Achievement][s_Name], client);
			g_eAchievementStatus[client][Achievement][b_IsPrevented] = true;
			g_eAchievementStatus[client][Achievement][Count] = 0;
			g_eAchievementStatus[client][Achievement][Target_Id] = -1;
		}
	}
}
/*
static ResetAchievement(client = -1, g_eAchievements:Achievement = UNDEFINED_ALL) {
	new i, j;
	
	 if (client == -1) {							// Reset for all clients..
		if (Achievement == UNDEFINED_ALL) {		// Reset all achievements.
			for (i=1; i<=MaxClients; i++) {
				for (j=0; j<sizeof(g_eAchievements); j++) {
					g_eAchievementStatus[i][j][b_IsCompleted] = false;
					g_eAchievementStatus[i][j][count] = 0;
					g_eAchievementStatus[i][j][Target_Id] = -1;
				}
			}
		} else {									// Reset just one achievement.
			for (i=1; i<=MaxClients; i++) {
				g_eAchievementStatus[i][Achievement][b_IsCompleted] = false;
				g_eAchievementStatus[i][Achievement][count] = 0;
				g_eAchievementStatus[i][Achievement][Target_Id] = -1;
			}
		}
	} else {										// Reset just 1 client..
		if (Achievement == UNDEFINED_ALL) {		// Reset all achievements.
			for (j=0; j<sizeof(g_eAchievements); j++) {
				g_eAchievementStatus[client][j][b_IsCompleted] = false;
				g_eAchievementStatus[client][j][count] = 0;
				g_eAchievementStatus[client][j][Target_Id] = -1;
			}
		} else {									// Reset just one achievement.
			g_eAchievementStatus[client][Achievement][b_IsCompleted] = false;
			g_eAchievementStatus[client][Achievement][count] = 0;
			g_eAchievementStatus[client][Achievement][Target_Id] = -1;
		}
	}
}
*/
static bool:IsPrevented(g_eAchievements:Achievement, client = -1) {
	// disabled - which means it hasn't been coded yet, or never - which means its turned off
	if ((g_eAchievementInfo[Achievement][ReportFrequency] == REPORT_DISABLED)
			|| (g_eAchievementInfo[Achievement][ReportFrequency] == REPORT_NEVER))
		return true;
	// l4d1 achievement in l4d2..
	if (!g_bUseL4D1inL4D2 && (g_eAchievementInfo[Achievement][L4D1or2] == GAME_L4D12))
		return true;
	// general achievement check, or client check
	if (client != -1) {
		// already prevented
		if (g_eAchievementStatus[client][Achievement][b_IsPrevented])
			return true;
	}
	return false;
}

static bool:IsRepeatable(g_eAchievements:Achievement, client = -1) {
	// general achievement check or client check
	if (client != -1) {			// client check
		// hasnt been completed yet
		if (!g_eAchievementStatus[client][Achievement][b_IsCompleted]) {
			return true;
		} else {
			switch (g_eAchievementInfo[Achievement][ReportFrequency]) {
				case REPORT_DISABLED, REPORT_NEVER:	{	return false;	}
				case REPORT_ALWAYS:					{	return true;	}
			// will be expanding this..
				case REPORT_ONCE, REPORT_ONCE_PER_GAME, REPORT_ONCE_PER_MAP,
				REPORT_ONCE_PER_LIFE:					{	return true;	}
			}
		}
	} else {					// general achievement check
		if (g_eAchievementInfo[Achievement][b_IsRepeatable]) {		// repeatable
			switch (g_eAchievementInfo[Achievement][ReportFrequency]) {
				case REPORT_DISABLED, REPORT_NEVER:	{	return false;	}
				case REPORT_ALWAYS:					{	return true;	}
			// will be expanding this..
				case REPORT_ONCE, REPORT_ONCE_PER_GAME, REPORT_ONCE_PER_MAP,
				REPORT_ONCE_PER_LIFE:					{	return true;	}
			}
		} else {				// not repeatable..
			return true;		// need to check if an achievement is non repeatable and yet earned by anyone
		}
	}
	return false;
}
/*
stock GetZombieClass(client) {
	decl String:clientmodel[96];
	GetClientModel(client, clientmodel, sizeof(clientmodel));
	if (StrContains(clientmodel, "hulk", false) != -1)
		return ZOMBIECLASS_TANK;
	else if (StrContains(clientmodel, "boomer", false) != -1)
		return ZOMBIECLASS_BOOMER;
	else if (StrContains(clientmodel, "hunter", false) != -1)
		return ZOMBIECLASS_HUNTER;
	else if (StrContains(clientmodel, "smoker", false) != -1)
		return ZOMBIECLASS_SMOKER;
	else if (StrContains(clientmodel, "spitter", false) != -1)
		return ZOMBIECLASS_SPITTER;
	else if (StrContains(clientmodel, "charger", false) != -1)
		return ZOMBIECLASS_CHARGER;
	else if (StrContains(clientmodel, "jockey", false) != -1)
		return ZOMBIECLASS_JOCKEY;
	else if (StrContains(clientmodel, "witch", false) != -1)
		return ZOMBIECLASS_WITCH;
	return ZOMBIECLASS_UNKNOWN;
}
*/
stock GetZombieClass2(any:client) {
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}

stock bool:IsValidClient(client, bool:not_fake = false) {
	if (IsPlayerClient(client)) {
		//if (IsValidEntity(client)) {
			if (IsClientInGame(client)) {
				if (not_fake ? !IsFakeClient(client) : true) {
					if (!IsPlayerAlive(client))
						return true;
				}
			}
		//}
	}
	return false;
}

stock bool:IsPlayerClient(client) {
	if (0 < client <= MaxClients)
		return true;
	return false;
}

stock bool:IsPlayerIncapacitated(client) {
	if (IsValidClient(client)) {
		if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
			return true;
	}
	return false;
}

static Rebuild_TankIndex(tankid = ALL_TANKS, bool:add = true) {
/*
	tankid isnt the client id - it is the userid
*/
	static num_tanks = 0;		// this only gets read the first time function is called
	new i, j, k;
	DebugPrintToAll("[Rebuild_TankIndex] Current # of Tanks: %i", num_tanks);
	if (tankid != ALL_TANKS) {
		if (add) {
			new tank = FindTankIndex(tankid);
			if (tank != -1) {		// tank is in the index already, skip everything else.
				DebugPrintToAll("[Rebuild_TankIndex] Tank %i already in tank_index", tankid);
				return;
			} else {
				DebugPrintToAll("[Rebuild_TankIndex] Trying to add Tank %i to tank_index", tankid);
				num_tanks++;
				if (num_tanks > MAXPLAYERS) {
					DebugPrintToAll("[Rebuild_TankIndex] Too many tanks being tracked: %i.", num_tanks);
					num_tanks = MAXPLAYERS;
				}
				DebugPrintToAll("[Rebuild_TankIndex] Adding %i to tank_index at position %i", tankid, num_tanks);
				g_eTankIndex[num_tanks][userid] = tankid;
			}
		} else {
			DebugPrintToAll("[Rebuild_TankIndex] Tank %i is being removed from the tank_index", tankid);
			/*
				Go backwards thru all the tanks that were alive,
				to find which one just died.
				
				Then work forwards and move all the values down,
				finally clearing the values of the (formerly) last index..
			*/
			for (i=num_tanks; i>=1; i--) {
				if (g_eTankIndex[i][userid] != tankid)		// this one didn't die..
					continue;
				
				if (i == num_tanks) {				// last one in the index, easy-peasy..
					DebugPrintToAll("[Rebuild_TankIndex] Last tank in, first tank out..");
					g_eTankIndex[i][userid] = -1;
					break;
				}
				for (j=i; j<=num_tanks; j++) {		// work back up and reset the damages
					k = j + 1;
					if (j == num_tanks)
						g_eTankIndex[j][userid] = -1;
					else
						g_eTankIndex[j][userid] = g_eTankIndex[k][userid];
				}
				DebugPrintToAll("[Rebuild_TankIndex] Found Tank to remove from tank_index at pos: %i of %i tanks.", i, num_tanks);
				break;		// no need to continue - found it
			}
			num_tanks--;
		}
	} else {				// used to flush everything (eg: map start)
		DebugPrintToAll("[Rebuild_TankIndex] Resetting tank_index..");
		num_tanks = 0;
		for (i=1; i<=MAXPLAYERS; i++) {
			g_eTankIndex[i][userid] = -1;
		}
	}
}

static bool:ReplaceTank(tankid) {
	DebugPrintToAll("[ReplaceTank] Checking if tankid %d is replacing a frustrated tank..", tankid);
	for (new i=1; i<=MaxClients; i++) {
		if (g_eClientInfo[i][b_isFrustrated]) {
			DebugPrintToAll("[ReplaceTank] Frustrated tank found (%d at position %d) and replaced in tank_index.", g_eClientInfo[i][Frustrated_index], i);
			g_eClientInfo[i][b_isFrustrated] = false;
			g_eTankIndex[g_eClientInfo[i][Frustrated_index]][userid] = tankid;
			g_eClientInfo[i][Frustrated_index] = -1;
			return true;
		}
	}
	DebugPrintToAll("[ReplaceTank] tankid %d is not in the index.", tankid);
	return false;
}

static FindTankIndex(tankid) {
	for (new i=1; i<=MAXPLAYERS; i++) {
		if (g_eTankIndex[i][userid] == tankid)
			return i;
	}
	return -1;		// return an invalid user id if suspected tankid isn't in index
}

stock GetAnySurvivor() {
	for (new i=1; i<=MaxClients; i++) {
		if (IsClientInGame(i)) {
			if (GetClientTeam(i) == TEAM_SURVIVORS)
				return i;
		}
	}
	return -1;		// return an invalid client id if there are no survivors in game
}

static GetMeleeWeapon(const String:sWeapon[]) {
	for (new i=1; i<=sizeof(g_eMeleeInfo[]); i++) {
		if (StrEqual(sWeapon, g_eMeleeInfo[i][s_WeaponName])) {
			return i;
		}
	}
	return 0;	// 0 = unknown
}
/*
stock bool:CloseTimer(Handle:timer) {
	new bool:closed = CloseHandle(timer);
	timer = INVALID_HANDLE;
	return closed;
}
*/
stock ResetTimer(Handle:timer) {
	if (timer != INVALID_HANDLE) {
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

static _Reset_ClientInfo(client) {
	g_eClientInfo[client][b_isPukedOn] = false;		// boomer
	g_eClientInfo[client][Puker_Id] = -1;
	g_eClientInfo[client][b_isFrustrated] = false;	// tank
	g_eClientInfo[client][Frustrated_index] = -1;
	g_eClientInfo[client][b_isPounced] = false;		// hunter
	g_eClientInfo[client][Pouncer_Id] = -1;
	g_eClientInfo[client][Rider_Id] = -1;				// jockey
	g_eClientInfo[client][PrevMule_Id] = -1;
	g_eClientInfo[client][CurMule_Id] = -1;
	g_eClientInfo[client][b_isImpacted] = false;		// charger
	g_eClientInfo[client][Impactor_Id] = -1;
	g_eClientInfo[client][b_isCarried] = false;
	g_eClientInfo[client][Carrier_Id] = -1;
	g_eClientInfo[client][b_isPummeled] = false;
	g_eClientInfo[client][Pummeler_Id] = -1;
	g_eClientInfo[client][b_isDead] = false;			// any
	g_eClientInfo[client][Killer_Id] = -1;
	DebugPrintToAll("[_Reset_ClientInfo] All info settings have been reset for client %i", client);
}

static _Init() {
	// MaxClients doesn't exist yet..
	for (new i=0; i<=MAXPLAYERS; i++) {
		_Reset_ClientInfo(i);
		for (new j=0; j<=MAXPLAYERS; j++) {
			g_hTimer__CleanKill[i][j] = INVALID_HANDLE;
		}
	}
	// this should initialize the entire index..
	Rebuild_TankIndex(ALL_TANKS, false);
	
	// Melee weapon info..
	if (g_bIsL4D2) {
		Format(g_eMeleeInfo[unknown][s_WeaponName],			MELEE_NAME_SIZE-1,	"unknown");
		Format(g_eMeleeInfo[baseball_bat][s_WeaponName],		MELEE_NAME_SIZE-1,	"baseball_bat");
		Format(g_eMeleeInfo[cricket_bat][s_WeaponName],		MELEE_NAME_SIZE-1,	"cricket_bat");
		Format(g_eMeleeInfo[crowbar][s_WeaponName],			MELEE_NAME_SIZE-1,	"crowbar");
		Format(g_eMeleeInfo[electric_guitar][s_WeaponName],	MELEE_NAME_SIZE-1,	"electric_guitar");
		Format(g_eMeleeInfo[fireaxe][s_WeaponName],			MELEE_NAME_SIZE-1,	"fireaxe");
		Format(g_eMeleeInfo[frying_pan][s_WeaponName],		MELEE_NAME_SIZE-1,	"frying_pan");
		Format(g_eMeleeInfo[katana][s_WeaponName],			MELEE_NAME_SIZE-1,	"katana");
		Format(g_eMeleeInfo[machete][s_WeaponName],			MELEE_NAME_SIZE-1,	"machete");
		Format(g_eMeleeInfo[tonfa][s_WeaponName],				MELEE_NAME_SIZE-1,	"tonfa");
		Format(g_eMeleeInfo[golfclub][s_WeaponName],			MELEE_NAME_SIZE-1,	"golfclub");
		Format(g_eMeleeInfo[knife][s_WeaponName],				MELEE_NAME_SIZE-1,	"knife");
		Format(g_eMeleeInfo[hunting_knife][s_WeaponName],	MELEE_NAME_SIZE-1,	"hunting_knife");
		Format(g_eMeleeInfo[riotshield][s_WeaponName],		MELEE_NAME_SIZE-1,	"riotshield");
		
		Format(g_eMeleeInfo[unknown][s_WeaponDesc],			MELEE_DESC_SIZE-1,	"an {olive}unknown weapon{default}");
		Format(g_eMeleeInfo[baseball_bat][s_WeaponDesc],		MELEE_DESC_SIZE-1,	"a {olive}baseball bat{default}");
		Format(g_eMeleeInfo[cricket_bat][s_WeaponDesc],		MELEE_DESC_SIZE-1,	"a {olive}cricket bat{default}");
		Format(g_eMeleeInfo[crowbar][s_WeaponDesc],			MELEE_DESC_SIZE-1,	"a {olive}crowbar{default}");
		Format(g_eMeleeInfo[electric_guitar][s_WeaponDesc],	MELEE_DESC_SIZE-1,	"an {olive}electric guitar{default}");
		Format(g_eMeleeInfo[fireaxe][s_WeaponDesc],			MELEE_DESC_SIZE-1,	"a {olive}fireaxe{default}");
		Format(g_eMeleeInfo[frying_pan][s_WeaponDesc],		MELEE_DESC_SIZE-1,	"a {olive}frying pan{default}");
		Format(g_eMeleeInfo[katana][s_WeaponDesc],			MELEE_DESC_SIZE-1,	"a {olive}katana{default}");
		Format(g_eMeleeInfo[machete][s_WeaponDesc],			MELEE_DESC_SIZE-1,	"a {olive}machete{default}");
		Format(g_eMeleeInfo[tonfa][s_WeaponDesc],				MELEE_DESC_SIZE-1,	"a {olive}tonfa{default}");
		Format(g_eMeleeInfo[golfclub][s_WeaponDesc],			MELEE_DESC_SIZE-1,	"a {olive}golf club{default}");
		Format(g_eMeleeInfo[knife][s_WeaponDesc],				MELEE_DESC_SIZE-1,"a {olive}knife{default}");
		Format(g_eMeleeInfo[hunting_knife][s_WeaponDesc],	MELEE_DESC_SIZE-1,"a {olive}knife{default}");
		Format(g_eMeleeInfo[riotshield][s_WeaponDesc],		MELEE_DESC_SIZE-1,	"a {olive}riot shield{default}");
		
		g_eMeleeInfo[unknown][flag]			=	0;
		g_eMeleeInfo[baseball_bat][flag]		=	(1 << 0);
		g_eMeleeInfo[cricket_bat][flag]		=	(1 << 1);
		g_eMeleeInfo[crowbar][flag]			=	(1 << 2);
		g_eMeleeInfo[electric_guitar][flag]	=	(1 << 3);
		g_eMeleeInfo[fireaxe][flag]			=	(1 << 4);
		g_eMeleeInfo[frying_pan][flag]			=	(1 << 5);
		g_eMeleeInfo[katana][flag]				=	(1 << 6);
		g_eMeleeInfo[machete][flag]			=	(1 << 7);
		g_eMeleeInfo[tonfa][flag]				=	(1 << 8);
		g_eMeleeInfo[golfclub][flag]			=	(1 << 9);
		g_eMeleeInfo[knife][flag]				=	(1 << 10);
		g_eMeleeInfo[hunting_knife][flag]		=	(1 << 11);
		g_eMeleeInfo[riotshield][flag]			=	(1 << 12);
		// is the baseball bat part of the achievement?
		MELEE_ALL = g_eMeleeInfo[baseball_bat][flag] | g_eMeleeInfo[cricket_bat][flag] | g_eMeleeInfo[crowbar][flag]
					| g_eMeleeInfo[electric_guitar][flag] | g_eMeleeInfo[fireaxe][flag] | g_eMeleeInfo[frying_pan][flag]
					| g_eMeleeInfo[katana][flag] | g_eMeleeInfo[machete][flag] | g_eMeleeInfo[tonfa][flag];
		
		Format(g_eUncommonInfo[Ceda][s_Name],			UCI_NAME_SIZE-1,	"Ceda");
		Format(g_eUncommonInfo[Clown][s_Name],			UCI_NAME_SIZE-1,	"Clown");
		Format(g_eUncommonInfo[Mudman][s_Name],		UCI_NAME_SIZE-1,	"Mudman");
		Format(g_eUncommonInfo[Roadcrew][s_Name],		UCI_NAME_SIZE-1,	"RoadCrew");
		Format(g_eUncommonInfo[Riot][s_Name],			UCI_NAME_SIZE-1,	"Riot Police");
		Format(g_eUncommonInfo[JimmyGibbs][s_Name],	UCI_NAME_SIZE-1,	"Jimmy Gibbs Jr.");
		Format(g_eUncommonInfo[Fallen][s_Name],		UCI_NAME_SIZE-1,	"Fallen Survivor");
		
		g_eUncommonInfo[Ceda][flag]			=	(1 << 0);
		g_eUncommonInfo[Clown][flag]			=	(1 << 1);
		g_eUncommonInfo[Mudman][flag]			=	(1 << 2);
		g_eUncommonInfo[Roadcrew][flag]		=	(1 << 3);
		g_eUncommonInfo[Riot][flag]			=	(1 << 4);
		g_eUncommonInfo[JimmyGibbs][flag]		=	(1 << 5);
		g_eUncommonInfo[Fallen][flag]			=	(1 << 6);
		UCI_ALL = g_eUncommonInfo[Ceda][flag] | g_eUncommonInfo[Clown][flag] | g_eUncommonInfo[Mudman][flag]
					| g_eUncommonInfo[Roadcrew][flag] | g_eUncommonInfo[Riot][flag];
	}
	
	// Campaign data..
	Format(g_eCampaignInfo[Blood_Harvest][s_Name],	CAMP_NAME_SIZE-1,	"Blood Harvest");
	Format(g_eCampaignInfo[Dead_Air][s_Name],			CAMP_NAME_SIZE-1,	"Dead Air");
	Format(g_eCampaignInfo[Death_Toll][s_Name],		CAMP_NAME_SIZE-1,	"Death Toll");
	Format(g_eCampaignInfo[No_Mercy][s_Name],			CAMP_NAME_SIZE-1,	"No Mercy");
	Format(g_eCampaignInfo[Crash_Course][s_Name],		CAMP_NAME_SIZE-1,	"Crash Course");
	
	g_eCampaignInfo[Blood_Harvest][flag]	=	(1 << 0);
	g_eCampaignInfo[Dead_Air][flag]		=	(1 << 1);
	g_eCampaignInfo[Death_Toll][flag]		=	(1 << 2);
	g_eCampaignInfo[No_Mercy][flag]		=	(1 << 3);
	g_eCampaignInfo[Crash_Course][flag]	=	(1 << 4);
	CAMP_WAYTTP_L4D1 = g_eCampaignInfo[Blood_Harvest][flag] | g_eCampaignInfo[Dead_Air][flag] |
					g_eCampaignInfo[Death_Toll][flag] | g_eCampaignInfo[No_Mercy][flag];
	CAMP_ALL_L4D1 = CAMP_WAYTTP_L4D1 | g_eCampaignInfo[Crash_Course][flag];
	Format(g_eCampaignInfo[Dead_Center][s_Name],		CAMP_NAME_SIZE-1,	"Dead Center");
	Format(g_eCampaignInfo[Dark_Carnival][s_Name],	CAMP_NAME_SIZE-1,	"Dark Carnival");
	Format(g_eCampaignInfo[Swamp_Fever][s_Name],		CAMP_NAME_SIZE-1,	"Swamp Fever");
	Format(g_eCampaignInfo[Hard_Rain][s_Name],		CAMP_NAME_SIZE-1,	"Hard Rain");
	Format(g_eCampaignInfo[The_Parish][s_Name],		CAMP_NAME_SIZE-1,	"The Parish");
	Format(g_eCampaignInfo[The_Passing][s_Name],		CAMP_NAME_SIZE-1,	"The Passing");
	
	g_eCampaignInfo[Dead_Center][flag]		=	(1 << 5);
	g_eCampaignInfo[Dark_Carnival][flag]	=	(1 << 6);
	g_eCampaignInfo[Swamp_Fever][flag]		=	(1 << 7);
	g_eCampaignInfo[Hard_Rain][flag]		=	(1 << 8);
	g_eCampaignInfo[The_Parish][flag]		=	(1 << 9);
	g_eCampaignInfo[The_Passing][flag]		=	(1 << 10);
	CAMP_SSTP_L4D2 = g_eCampaignInfo[Dead_Center][flag] | g_eCampaignInfo[Dark_Carnival][flag]
					| g_eCampaignInfo[Swamp_Fever][flag] | g_eCampaignInfo[Hard_Rain][flag] |
					g_eCampaignInfo[The_Parish][flag];
	CAMP_ALL_L4D2 = CAMP_SSTP_L4D2 | g_eCampaignInfo[The_Passing][flag];
	CAMP_ALL = CAMP_ALL_L4D1 | CAMP_ALL_L4D2;
	
	// Achievement data..
	Format(g_eAchievementInfo[A_Ride_Denied][s_Name],		SIZE_NAME-1,	"%T",	"A Ride Denied",		LANG_SERVER);
	Format(g_eAchievementInfo[A_Ride_Denied][s_Desc],		SIZE_NAME-1,	"%T",	"A_Ride_Denied_DESC",	LANG_SERVER);
	g_eAchievementInfo[A_Ride_Denied][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[A_Ride_Denied][b_IsRepeatable]		=	true;
	g_eAchievementInfo[A_Ride_Denied][ReportFrequency]	=	REPORT_ALWAYS;
	g_eAchievementInfo[A_Ride_Denied][Total]				=	2;
	
	Format(g_eAchievementInfo[A_Spittle_Help_From_My_Friends][s_Name],	SIZE_NAME-1,	"%T",	"A Spittle Help From My Friends",		LANG_SERVER);
	Format(g_eAchievementInfo[A_Spittle_Help_From_My_Friends][s_Desc],	SIZE_NAME-1,	"%T",	"A_Spittle_Help_From_My_Friends_DESC",	LANG_SERVER);
	g_eAchievementInfo[A_Spittle_Help_From_My_Friends][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[A_Spittle_Help_From_My_Friends][b_IsRepeatable]	=	true;
	g_eAchievementInfo[A_Spittle_Help_From_My_Friends][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[A_Spittle_Help_From_My_Friends][Total]			=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Acid_Reflex][s_Name],	SIZE_NAME-1,	"%T",	"Acid Reflex",		LANG_SERVER);
	Format(g_eAchievementInfo[Acid_Reflex][s_Desc],	SIZE_NAME-1,	"%T",	"Acid_Reflex_DESC",	LANG_SERVER);
	g_eAchievementInfo[Acid_Reflex][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Acid_Reflex][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Acid_Reflex][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Acid_Reflex][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Akimbo_Assassin][s_Name],		SIZE_NAME-1,	"%T",	"Akimbo Assassin",		LANG_SERVER);
	Format(g_eAchievementInfo[Akimbo_Assassin][s_Desc],		SIZE_NAME-1,	"%T",	"Akimbo_Assassin_DESC",	LANG_SERVER);
	g_eAchievementInfo[Akimbo_Assassin][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Akimbo_Assassin][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Akimbo_Assassin][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Akimbo_Assassin][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[All_4_Dead][s_Name],	SIZE_NAME-1,	"%T",	"All 4 Dead",		LANG_SERVER);
	Format(g_eAchievementInfo[All_4_Dead][s_Desc],	SIZE_NAME-1,	"%T",	"All_4_Dead_DESC",	LANG_SERVER);
	g_eAchievementInfo[All_4_Dead][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[All_4_Dead][b_IsRepeatable]	=	true;
	g_eAchievementInfo[All_4_Dead][ReportFrequency]	=	REPORT_ALWAYS;
	g_eAchievementInfo[All_4_Dead][Total]				=	4;
	
	Format(g_eAchievementInfo[Armory_Of_One][s_Name],		SIZE_NAME-1,	"%T",	"Armory Of One",		LANG_SERVER);
	Format(g_eAchievementInfo[Armory_Of_One][s_Desc],		SIZE_NAME-1,	"%T",	"Armory_Of_One_DESC",	LANG_SERVER);
	g_eAchievementInfo[Armory_Of_One][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Armory_Of_One][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Armory_Of_One][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Armory_Of_One][Total]				=	4;
	
	Format(g_eAchievementInfo[Back_2_Help][s_Name],	SIZE_NAME-1,	"%T",	"Back 2 Help",		LANG_SERVER);
	Format(g_eAchievementInfo[Back_2_Help][s_Desc],	SIZE_NAME-1,	"%T",	"Back_2_Help_DESC",	LANG_SERVER);
	g_eAchievementInfo[Back_2_Help][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Back_2_Help][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Back_2_Help][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Back_2_Help][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Back_In_The_Saddle][s_Name],	SIZE_NAME-1,	"%T",	"Back In The Saddle",		LANG_SERVER);
	Format(g_eAchievementInfo[Back_In_The_Saddle][s_Desc],	SIZE_NAME-1,	"%T",	"Back_In_The_Saddle_DESC",	LANG_SERVER);
	g_eAchievementInfo[Back_In_The_Saddle][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Back_In_The_Saddle][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Back_In_The_Saddle][ReportFrequency]	=	REPORT_ALWAYS;
	g_eAchievementInfo[Back_In_The_Saddle][Total]				=	2;
	
	Format(g_eAchievementInfo[Barf_Bagged][s_Name],	SIZE_NAME-1,	"%T",	"Barf Bagged",		LANG_SERVER);
	Format(g_eAchievementInfo[Barf_Bagged][s_Desc],	SIZE_NAME-1,	"%T",	"Barf_Bagged_DESC",	LANG_SERVER);
	g_eAchievementInfo[Barf_Bagged][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Barf_Bagged][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Barf_Bagged][ReportFrequency]	=	REPORT_ALWAYS;
	g_eAchievementInfo[Barf_Bagged][Total]				=	4;
	
	Format(g_eAchievementInfo[Beat_The_Rush][s_Name],		SIZE_NAME-1,	"%T",	"Beat The Rush",		LANG_SERVER);
	Format(g_eAchievementInfo[Beat_The_Rush][s_Desc],		SIZE_NAME-1,	"%T",	"Beat_The_Rush_DESC",	LANG_SERVER);
	g_eAchievementInfo[Beat_The_Rush][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Beat_The_Rush][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Beat_The_Rush][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Beat_The_Rush][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Big_Drag][s_Name],		SIZE_NAME-1,	"%T",	"Big Drag",			LANG_SERVER);
	Format(g_eAchievementInfo[Big_Drag][s_Desc],		SIZE_NAME-1,	"%T",	"Big_Drag_DESC",	LANG_SERVER);
	g_eAchievementInfo[Big_Drag][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Big_Drag][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Big_Drag][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Big_Drag][Total]				=	100;
	
	Format(g_eAchievementInfo[Blind_Luck][s_Name],	SIZE_NAME-1,	"%T",	"Blind Luck",		LANG_SERVER);
	Format(g_eAchievementInfo[Blind_Luck][s_Desc],	SIZE_NAME-1,	"%T",	"Blind_Luck_DESC",	LANG_SERVER);
	g_eAchievementInfo[Blind_Luck][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Blind_Luck][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Blind_Luck][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Blind_Luck][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Brain_Salad][s_Name],	SIZE_NAME-1,	"%T",	"Brain Salad",		LANG_SERVER);
	Format(g_eAchievementInfo[Brain_Salad][s_Desc],	SIZE_NAME-1,	"%T",	"Brain_Salad_DESC",	LANG_SERVER);
	g_eAchievementInfo[Brain_Salad][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Brain_Salad][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Brain_Salad][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Brain_Salad][Total]				=	100;
	
	Format(g_eAchievementInfo[Bridge_Burner][s_Name],		SIZE_NAME-1,	"%T",	"Bridge Burner",		LANG_SERVER);
	Format(g_eAchievementInfo[Bridge_Burner][s_Desc],		SIZE_NAME-1,	"%T",	"Bridge_Burner_DESC",	LANG_SERVER);
	g_eAchievementInfo[Bridge_Burner][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Bridge_Burner][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Bridge_Burner][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Bridge_Burner][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Bridge_Over_Trebled_Slaughter][s_Name],	SIZE_NAME-1,	"%T",	"Bridge Over Trebled Slaughter",		LANG_SERVER);
	Format(g_eAchievementInfo[Bridge_Over_Trebled_Slaughter][s_Desc],	SIZE_NAME-1,	"%T",	"Bridge_Over_Trebled_Slaughter_DESC",	LANG_SERVER);
	g_eAchievementInfo[Bridge_Over_Trebled_Slaughter][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Bridge_Over_Trebled_Slaughter][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Bridge_Over_Trebled_Slaughter][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Bridge_Over_Trebled_Slaughter][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Bronze_Mettle][s_Name],		SIZE_NAME-1,	"%T",	"Bronze Mettle",		LANG_SERVER);
	Format(g_eAchievementInfo[Bronze_Mettle][s_Desc],		SIZE_NAME-1,	"%T",	"Bronze_Mettle_DESC",	LANG_SERVER);
	g_eAchievementInfo[Bronze_Mettle][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Bronze_Mettle][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Bronze_Mettle][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Bronze_Mettle][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Burn_The_Witch][s_Name],	SIZE_NAME-1,	"%T",	"Burn The Witch",		LANG_SERVER);
	Format(g_eAchievementInfo[Burn_The_Witch][s_Desc],	SIZE_NAME-1,	"%T",	"Burn_The_Witch_DESC",	LANG_SERVER);
	g_eAchievementInfo[Burn_The_Witch][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Burn_The_Witch][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Burn_The_Witch][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Burn_The_Witch][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Burning_Sensation][s_Name],	SIZE_NAME-1,	"%T",	"Burning Sensation",		LANG_SERVER);
	Format(g_eAchievementInfo[Burning_Sensation][s_Desc],	SIZE_NAME-1,	"%T",	"Burning_Sensation_DESC",	LANG_SERVER);
	g_eAchievementInfo[Burning_Sensation][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Burning_Sensation][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Burning_Sensation][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Burning_Sensation][Total]				=	50;
	
	Format(g_eAchievementInfo[Cache_And_Carry][s_Name],		SIZE_NAME-1,	"%T",	"Cache And Carry",		LANG_SERVER);
	Format(g_eAchievementInfo[Cache_And_Carry][s_Desc],		SIZE_NAME-1,	"%T",	"Cache_And_Carry_DESC",	LANG_SERVER);
	g_eAchievementInfo[Cache_And_Carry][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Cache_And_Carry][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Cache_And_Carry][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Cache_And_Carry][Total]				=	15;
	
	Format(g_eAchievementInfo[Cache_Grab][s_Name],	SIZE_NAME-1,	"%T",	"Cache Grab",		LANG_SERVER);
	Format(g_eAchievementInfo[Cache_Grab][s_Desc],	SIZE_NAME-1,	"%T",	"Cache_Grab_DESC",	LANG_SERVER);
	g_eAchievementInfo[Cache_Grab][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Cache_Grab][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Cache_Grab][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Cache_Grab][Total]				=	5;
	
	Format(g_eAchievementInfo[Chain_Of_Command][s_Name],		SIZE_NAME-1,	"%T",	"Chain Of Command",			LANG_SERVER);
	Format(g_eAchievementInfo[Chain_Of_Command][s_Desc],		SIZE_NAME-1,	"%T",	"Chain_Of_Command_DESC",	LANG_SERVER);
	g_eAchievementInfo[Chain_Of_Command][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Chain_Of_Command][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Chain_Of_Command][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Chain_Of_Command][Total]				=	100;
	
	Format(g_eAchievementInfo[Chain_Smoker][s_Name],		SIZE_NAME-1,	"%T",	"Chain Smoker",			LANG_SERVER);
	Format(g_eAchievementInfo[Chain_Smoker][s_Desc],		SIZE_NAME-1,	"%T",	"Chain_Smoker_DESC",	LANG_SERVER);
	g_eAchievementInfo[Chain_Smoker][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Chain_Smoker][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Chain_Smoker][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Chain_Smoker][Total]				=	2;
	
	Format(g_eAchievementInfo[Cl0wned][s_Name],	SIZE_NAME-1,	"%T",	"Cl0wned",		LANG_SERVER);
	Format(g_eAchievementInfo[Cl0wned][s_Desc],	SIZE_NAME-1,	"%T",	"Cl0wned_DESC",	LANG_SERVER);
	g_eAchievementInfo[Cl0wned][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Cl0wned][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Cl0wned][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Cl0wned][Total]				=	10;
	
	Format(g_eAchievementInfo[Clean_Kill][s_Name],	SIZE_NAME-1,	"%T",	"Clean Kill",		LANG_SERVER);
	Format(g_eAchievementInfo[Clean_Kill][s_Desc],	SIZE_NAME-1,	"%T",	"Clean_Kill_DESC",	LANG_SERVER);
	g_eAchievementInfo[Clean_Kill][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Clean_Kill][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Clean_Kill][ReportFrequency]	=	REPORT_ALWAYS;
	g_eAchievementInfo[Clean_Kill][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Club_Dead][s_Name],		SIZE_NAME-1,	"%T",	"Club Dead",		LANG_SERVER);
	Format(g_eAchievementInfo[Club_Dead][s_Desc],		SIZE_NAME-1,	"%T",	"Club_Dead_DESC",	LANG_SERVER);
	g_eAchievementInfo[Club_Dead][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Club_Dead][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Club_Dead][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Club_Dead][Total]				=	MELEE_ALL;
	
	Format(g_eAchievementInfo[Confederacy_Of_Crunches][s_Name],		SIZE_NAME-1,	"%T",	"Confederacy Of Crunches",		LANG_SERVER);
	Format(g_eAchievementInfo[Confederacy_Of_Crunches][s_Desc],		SIZE_NAME-1,	"%T",	"Confederacy_Of_Crunches_DESC",	LANG_SERVER);
	g_eAchievementInfo[Confederacy_Of_Crunches][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Confederacy_Of_Crunches][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Confederacy_Of_Crunches][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Confederacy_Of_Crunches][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Cr0wnd][s_Name],		SIZE_NAME-1,	"%T",	"Cr0wnd",		LANG_SERVER);
	Format(g_eAchievementInfo[Cr0wnd][s_Desc],		SIZE_NAME-1,	"%T",	"Cr0wnd_DESC",	LANG_SERVER);
	g_eAchievementInfo[Cr0wnd][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Cr0wnd][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Cr0wnd][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Cr0wnd][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Crash_proof][s_Name],	SIZE_NAME-1,	"%T",	"Crash-proof",		LANG_SERVER);
	Format(g_eAchievementInfo[Crash_proof][s_Desc],	SIZE_NAME-1,	"%T",	"Crash_proof_DESC",	LANG_SERVER);
	g_eAchievementInfo[Crash_proof][L4D1or2]			=	GAME_L4D1;
	g_eAchievementInfo[Crash_proof][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Crash_proof][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Crash_proof][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Crass_Menagerie][s_Name],		SIZE_NAME-1,	"%T",	"Crass Menagerie",		LANG_SERVER);
	Format(g_eAchievementInfo[Crass_Menagerie][s_Desc],		SIZE_NAME-1,	"%T",	"Crass_Menagerie_DESC",	LANG_SERVER);
	g_eAchievementInfo[Crass_Menagerie][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Crass_Menagerie][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Crass_Menagerie][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Crass_Menagerie][Total]				=	UCI_ALL;
	
	Format(g_eAchievementInfo[Dead_Baron][s_Name],	SIZE_NAME-1,	"%T",	"Dead Baron",		LANG_SERVER);
	Format(g_eAchievementInfo[Dead_Baron][s_Desc],	SIZE_NAME-1,	"%T",	"Dead_Baron_DESC",	LANG_SERVER);
	g_eAchievementInfo[Dead_Baron][L4D1or2]			=	GAME_L4D1;
	g_eAchievementInfo[Dead_Baron][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Dead_Baron][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Dead_Baron][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Dead_Giveaway][s_Name],		SIZE_NAME-1,	"%T",	"Dead Giveaway",		LANG_SERVER);
	Format(g_eAchievementInfo[Dead_Giveaway][s_Desc],		SIZE_NAME-1,	"%T",	"Dead_Giveaway_DESC",	LANG_SERVER);
	g_eAchievementInfo[Dead_Giveaway][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Dead_Giveaway][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Dead_Giveaway][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Dead_Giveaway][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Dead_In_The_Water][s_Name],		SIZE_NAME-1,	"%T",	"Dead In The Water",		LANG_SERVER);
	Format(g_eAchievementInfo[Dead_In_The_Water][s_Desc],		SIZE_NAME-1,	"%T",	"Dead_In_The_Water_DESC",	LANG_SERVER);
	g_eAchievementInfo[Dead_In_The_Water][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Dead_In_The_Water][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Dead_In_The_Water][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Dead_In_The_Water][Total]				=	10;
	
	Format(g_eAchievementInfo[Dead_Stop][s_Name],		SIZE_NAME-1,	"%T",	"Dead Stop",		LANG_SERVER);
	Format(g_eAchievementInfo[Dead_Stop][s_Desc],		SIZE_NAME-1,	"%T",	"Dead_Stop_DESC",	LANG_SERVER);
	g_eAchievementInfo[Dead_Stop][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Dead_Stop][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Dead_Stop][ReportFrequency]	=	REPORT_ALWAYS;
	g_eAchievementInfo[Dead_Stop][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Dead_Wreckening][s_Name],		SIZE_NAME-1,	"%T",	"Dead Wreckening",		LANG_SERVER);
	Format(g_eAchievementInfo[Dead_Wreckening][s_Desc],		SIZE_NAME-1,	"%T",	"Dead_Wreckening_DESC",	LANG_SERVER);
	g_eAchievementInfo[Dead_Wreckening][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Dead_Wreckening][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Dead_Wreckening][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Dead_Wreckening][Total]				=	5000;
	
	Format(g_eAchievementInfo[Dismemberment_Plan][s_Name],	SIZE_NAME-1,	"%T",	"Dismemberment Plan",		LANG_SERVER);
	Format(g_eAchievementInfo[Dismemberment_Plan][s_Desc],	SIZE_NAME-1,	"%T",	"Dismemberment_Plan_DESC",	LANG_SERVER);
	g_eAchievementInfo[Dismemberment_Plan][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Dismemberment_Plan][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Dismemberment_Plan][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Dismemberment_Plan][Total]				=	15;
	
	Format(g_eAchievementInfo[Distinguished_Survivor][s_Name],	SIZE_NAME-1,	"%T",	"Distinguished Survivor",		LANG_SERVER);
	Format(g_eAchievementInfo[Distinguished_Survivor][s_Desc],	SIZE_NAME-1,	"%T",	"Distinguished_Survivor_DESC",	LANG_SERVER);
	g_eAchievementInfo[Distinguished_Survivor][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Distinguished_Survivor][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Distinguished_Survivor][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Distinguished_Survivor][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Do_Not_Disturb][s_Name],	SIZE_NAME-1,	"%T",	"Do Not Disturb",		LANG_SERVER);
	Format(g_eAchievementInfo[Do_Not_Disturb][s_Desc],	SIZE_NAME-1,	"%T",	"Do_Not_Disturb_DESC",	LANG_SERVER);
	g_eAchievementInfo[Do_Not_Disturb][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Do_Not_Disturb][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Do_Not_Disturb][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Do_Not_Disturb][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Double_Jump][s_Name],	SIZE_NAME-1,	"%T",	"Double Jump",		LANG_SERVER);
	Format(g_eAchievementInfo[Double_Jump][s_Desc],	SIZE_NAME-1,	"%T",	"Double_Jump_DESC",	LANG_SERVER);
	g_eAchievementInfo[Double_Jump][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Double_Jump][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Double_Jump][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Double_Jump][Total]				=	2;
	
	Format(g_eAchievementInfo[Drag_And_Drop][s_Name],		SIZE_NAME-1,	"%T",	"Drag And Drop",		LANG_SERVER);
	Format(g_eAchievementInfo[Drag_And_Drop][s_Desc],		SIZE_NAME-1,	"%T",	"Drag_And_Drop_DESC",	LANG_SERVER);
	g_eAchievementInfo[Drag_And_Drop][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Drag_And_Drop][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Drag_And_Drop][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Drag_And_Drop][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Field_Medic][s_Name],		SIZE_NAME-1,	"%T",	"Field Medic",		LANG_SERVER);
	Format(g_eAchievementInfo[Field_Medic][s_Desc],		SIZE_NAME-1,	"%T",	"Field_Medic_DESC",	LANG_SERVER);
	g_eAchievementInfo[Field_Medic][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Field_Medic][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Field_Medic][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Field_Medic][Total]					=	25;
	
	Format(g_eAchievementInfo[Fore][s_Name],		SIZE_NAME-1,	"%T",	"Fore!",		LANG_SERVER);
	Format(g_eAchievementInfo[Fore][s_Desc],		SIZE_NAME-1,	"%T",	"Fore_DESC",	LANG_SERVER);
	g_eAchievementInfo[Fore][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Fore][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Fore][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Fore][Total]				=	18;
	
	Format(g_eAchievementInfo[Fried_Piper][s_Name],		SIZE_NAME-1,	"%T",	"Fried Piper",		LANG_SERVER);
	Format(g_eAchievementInfo[Fried_Piper][s_Desc],		SIZE_NAME-1,	"%T",	"Fried_Piper_DESC",	LANG_SERVER);
	g_eAchievementInfo[Fried_Piper][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Fried_Piper][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Fried_Piper][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Fried_Piper][Total]					=	10;
	
	Format(g_eAchievementInfo[Fuel_Crisis][s_Name],		SIZE_NAME-1,	"%T",	"Fuel Crisis",		LANG_SERVER);
	Format(g_eAchievementInfo[Fuel_Crisis][s_Desc],		SIZE_NAME-1,	"%T",	"Fuel_Crisis_DESC",	LANG_SERVER);
	g_eAchievementInfo[Fuel_Crisis][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Fuel_Crisis][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Fuel_Crisis][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Fuel_Crisis][Total]					=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Gas_Guzzler][s_Name],		SIZE_NAME-1,	"%T",	"Gas Guzzler",		LANG_SERVER);
	Format(g_eAchievementInfo[Gas_Guzzler][s_Desc],		SIZE_NAME-1,	"%T",	"Gas_Guzzler_DESC",	LANG_SERVER);
	g_eAchievementInfo[Gas_Guzzler][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Gas_Guzzler][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Gas_Guzzler][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Gas_Guzzler][Total]					=	100;
	
	Format(g_eAchievementInfo[Gas_Shortage][s_Name],		SIZE_NAME-1,	"%T",	"Gas Shortage",			LANG_SERVER);
	Format(g_eAchievementInfo[Gas_Shortage][s_Desc],		SIZE_NAME-1,	"%T",	"Gas_Shortage_DESC",	LANG_SERVER);
	g_eAchievementInfo[Gas_Shortage][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Gas_Shortage][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Gas_Shortage][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Gas_Shortage][Total]				=	25;
	
	Format(g_eAchievementInfo[Guardin_Gnome][s_Name],		SIZE_NAME-1,	"%T",	"Guardin' Gnome",		LANG_SERVER);
	Format(g_eAchievementInfo[Guardin_Gnome][s_Desc],		SIZE_NAME-1,	"%T",	"Guardin_Gnome_DESC",	LANG_SERVER);
	g_eAchievementInfo[Guardin_Gnome][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Guardin_Gnome][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Guardin_Gnome][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Guardin_Gnome][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Gong_Show][s_Name],		SIZE_NAME-1,	"%T",	"Gong Show",		LANG_SERVER);
	Format(g_eAchievementInfo[Gong_Show][s_Desc],		SIZE_NAME-1,	"%T",	"Gong_Show_DESC",	LANG_SERVER);
	g_eAchievementInfo[Gong_Show][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Gong_Show][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Gong_Show][ReportFrequency]	=	REPORT_ONCE_PER_MAP;
	g_eAchievementInfo[Gong_Show][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Grave_Robber][s_Name],		SIZE_NAME-1,	"%T",	"Grave Robber",			LANG_SERVER);
	Format(g_eAchievementInfo[Grave_Robber][s_Desc],		SIZE_NAME-1,	"%T",	"Grave_Robber_DESC",	LANG_SERVER);
	g_eAchievementInfo[Grave_Robber][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Grave_Robber][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Grave_Robber][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Grave_Robber][Total]				=	10;
	
	Format(g_eAchievementInfo[Great_Expectorations][s_Name],		SIZE_NAME-1,	"%T",	"Great Expectorations",			LANG_SERVER);
	Format(g_eAchievementInfo[Great_Expectorations][s_Desc],		SIZE_NAME-1,	"%T",	"Great_Expectorations_DESC",	LANG_SERVER);
	g_eAchievementInfo[Great_Expectorations][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Great_Expectorations][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Great_Expectorations][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Great_Expectorations][Total]				=	4;
	
	Format(g_eAchievementInfo[Grim_Reaper][s_Name],		SIZE_NAME-1,	"%T",	"Grim Reaper",		LANG_SERVER);
	Format(g_eAchievementInfo[Grim_Reaper][s_Desc],		SIZE_NAME-1,	"%T",	"Grim_Reaper_DESC",	LANG_SERVER);
	g_eAchievementInfo[Grim_Reaper][L4D1or2]				=	GAME_L4D1;
	g_eAchievementInfo[Grim_Reaper][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Grim_Reaper][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Grim_Reaper][Total]					=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Ground_Cover][s_Name],		SIZE_NAME-1,	"%T",	"Ground Cover",			LANG_SERVER);
	Format(g_eAchievementInfo[Ground_Cover][s_Desc],		SIZE_NAME-1,	"%T",	"Ground_Cover_DESC",	LANG_SERVER);
	g_eAchievementInfo[Ground_Cover][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Ground_Cover][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Ground_Cover][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Ground_Cover][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Head_Honcho][s_Name],		SIZE_NAME-1,	"%T",	"Head Honcho",		LANG_SERVER);
	Format(g_eAchievementInfo[Head_Honcho][s_Desc],		SIZE_NAME-1,	"%T",	"Head_Honcho_DESC",	LANG_SERVER);
	g_eAchievementInfo[Head_Honcho][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Head_Honcho][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Head_Honcho][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Head_Honcho][Total]					=	200;
	
	Format(g_eAchievementInfo[Heartwarmer][s_Name],		SIZE_NAME-1,	"%T",	"Heartwarmer",		LANG_SERVER);
	Format(g_eAchievementInfo[Heartwarmer][s_Desc],		SIZE_NAME-1,	"%T",	"Heartwarmer_DESC",	LANG_SERVER);
	g_eAchievementInfo[Heartwarmer][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Heartwarmer][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Heartwarmer][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Heartwarmer][Total]					=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Helping_Hand][s_Name],		SIZE_NAME-1,	"%T",	"Helping Hand",			LANG_SERVER);
	Format(g_eAchievementInfo[Helping_Hand][s_Desc],		SIZE_NAME-1,	"%T",	"Helping_Hand_DESC",	LANG_SERVER);
	g_eAchievementInfo[Helping_Hand][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Helping_Hand][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Helping_Hand][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Helping_Hand][Total]				=	50;
	
	Format(g_eAchievementInfo[Hero_Closet][s_Name],		SIZE_NAME-1,	"%T",	"Hero Closet",		LANG_SERVER);
	Format(g_eAchievementInfo[Hero_Closet][s_Desc],		SIZE_NAME-1,	"%T",	"Hero_Closet_DESC",	LANG_SERVER);
	g_eAchievementInfo[Hero_Closet][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Hero_Closet][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Hero_Closet][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Hero_Closet][Total]					=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Heroic_Survivor][s_Name],		SIZE_NAME-1,	"%T",	"Heroic Survivor",		LANG_SERVER);
	Format(g_eAchievementInfo[Heroic_Survivor][s_Desc],		SIZE_NAME-1,	"%T",	"Heroic_Survivor_DESC",	LANG_SERVER);
	g_eAchievementInfo[Heroic_Survivor][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Heroic_Survivor][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Heroic_Survivor][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Heroic_Survivor][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Hunter_Punter][s_Name],		SIZE_NAME-1,	"%T",	"Hunter Punter",		LANG_SERVER);
	Format(g_eAchievementInfo[Hunter_Punter][s_Desc],		SIZE_NAME-1,	"%T",	"Hunter_Punter_DESC",	LANG_SERVER);
	g_eAchievementInfo[Hunter_Punter][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Hunter_Punter][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Hunter_Punter][ReportFrequency]	=	REPORT_ALWAYS;
	g_eAchievementInfo[Hunter_Punter][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Hunting_Party][s_Name],		SIZE_NAME-1,	"%T",	"Hunting Party",		LANG_SERVER);
	Format(g_eAchievementInfo[Hunting_Party][s_Desc],		SIZE_NAME-1,	"%T",	"Hunting_Party_DESC",	LANG_SERVER);
	g_eAchievementInfo[Hunting_Party][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Hunting_Party][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Hunting_Party][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Hunting_Party][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Jump_Shot][s_Name],		SIZE_NAME-1,	"%T",	"Jump Shot",		LANG_SERVER);
	Format(g_eAchievementInfo[Jump_Shot][s_Desc],		SIZE_NAME-1,	"%T",	"Jump_Shot_DESC",	LANG_SERVER);
	g_eAchievementInfo[Jump_Shot][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Jump_Shot][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Jump_Shot][ReportFrequency]	=	REPORT_ALWAYS;
	g_eAchievementInfo[Jump_Shot][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Jumpin_Jack_Smash][s_Name],		SIZE_NAME-1,	"%T",	"Jumpin' Jack Smash",		LANG_SERVER);
	Format(g_eAchievementInfo[Jumpin_Jack_Smash][s_Desc],		SIZE_NAME-1,	"%T",	"Jumpin_Jack_Smash_DESC",	LANG_SERVER);
	g_eAchievementInfo[Jumpin_Jack_Smash][L4D1or2]			=	GAME_L4D1;
	g_eAchievementInfo[Jumpin_Jack_Smash][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Jumpin_Jack_Smash][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Jumpin_Jack_Smash][Total]				=	25;
	
	Format(g_eAchievementInfo[Kill_Them_Swiftly_To_This_Song][s_Name],		SIZE_NAME-1,	"%T",	"Killing Them Swiftly To This Song",	LANG_SERVER);
	Format(g_eAchievementInfo[Kill_Them_Swiftly_To_This_Song][s_Desc],		SIZE_NAME-1,	"%T",	"Kill_Them_Swiftly_To_This_Song_DESC",	LANG_SERVER);
	g_eAchievementInfo[Kill_Them_Swiftly_To_This_Song][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Kill_Them_Swiftly_To_This_Song][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Kill_Them_Swiftly_To_This_Song][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Kill_Them_Swiftly_To_This_Song][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Kite_Like_A_Man][s_Name],		SIZE_NAME-1,	"%T",	"Kite Like A Man",		LANG_SERVER);
	Format(g_eAchievementInfo[Kite_Like_A_Man][s_Desc],		SIZE_NAME-1,	"%T",	"Kite_Like_A_Man_DESC",	LANG_SERVER);
	g_eAchievementInfo[Kite_Like_A_Man][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Kite_Like_A_Man][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Kite_Like_A_Man][ReportFrequency]		=	REPORT_ONCE_PER_GAME;
	g_eAchievementInfo[Kite_Like_A_Man][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Lamb_2_Slaughter][s_Name],		SIZE_NAME-1,	"%T",	"Lamb 2 Slaughter",			LANG_SERVER);
	Format(g_eAchievementInfo[Lamb_2_Slaughter][s_Desc],		SIZE_NAME-1,	"%T",	"Lamb_2_Slaughter_DESC",	LANG_SERVER);
	g_eAchievementInfo[Lamb_2_Slaughter][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Lamb_2_Slaughter][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Lamb_2_Slaughter][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Lamb_2_Slaughter][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Last_Stand][s_Name],	SIZE_NAME-1,	"%T",	"Last Stand",		LANG_SERVER);
	Format(g_eAchievementInfo[Last_Stand][s_Desc],	SIZE_NAME-1,	"%T",	"Last_Stand_DESC",	LANG_SERVER);
	g_eAchievementInfo[Last_Stand][L4D1or2]			=	GAME_L4D1;
	g_eAchievementInfo[Last_Stand][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Last_Stand][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Last_Stand][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Legendary_Survivor][s_Name],	SIZE_NAME-1,	"%T",	"Legendary Survivor",		LANG_SERVER);
	Format(g_eAchievementInfo[Legendary_Survivor][s_Desc],	SIZE_NAME-1,	"%T",	"Legendary_Survivor_DESC",	LANG_SERVER);
	g_eAchievementInfo[Legendary_Survivor][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Legendary_Survivor][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Legendary_Survivor][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Legendary_Survivor][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Level_A_Charge][s_Name],	SIZE_NAME-1,	"%T",	"Level A Charge",		LANG_SERVER);
	Format(g_eAchievementInfo[Level_A_Charge][s_Desc],	SIZE_NAME-1,	"%T",	"Level_A_Charge_DESC",	LANG_SERVER);
	g_eAchievementInfo[Level_A_Charge][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Level_A_Charge][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Level_A_Charge][ReportFrequency]	=	REPORT_ALWAYS;
	g_eAchievementInfo[Level_A_Charge][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Long_Distance_Carrier][s_Name],	SIZE_NAME-1,	"%T",	"Long Distance Carrier",		LANG_SERVER);
	Format(g_eAchievementInfo[Long_Distance_Carrier][s_Desc],	SIZE_NAME-1,	"%T",	"Long_Distance_Carrier_DESC",	LANG_SERVER);
	g_eAchievementInfo[Long_Distance_Carrier][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Long_Distance_Carrier][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Long_Distance_Carrier][ReportFrequency]	=	REPORT_ALWAYS;
	g_eAchievementInfo[Long_Distance_Carrier][Total]				=	80;
	
	Format(g_eAchievementInfo[Man_Vs_Tank][s_Name],	SIZE_NAME-1,	"%T",	"Man Vs Tank",		LANG_SERVER);
	Format(g_eAchievementInfo[Man_Vs_Tank][s_Desc],	SIZE_NAME-1,	"%T",	"Man_Vs_Tank_DESC",	LANG_SERVER);
	g_eAchievementInfo[Man_Vs_Tank][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Man_Vs_Tank][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Man_Vs_Tank][ReportFrequency]	=	REPORT_ALWAYS;
	g_eAchievementInfo[Man_Vs_Tank][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Meat_Tenderizer][s_Name],		SIZE_NAME-1,	"%T",	"Meat Tenderizer",		LANG_SERVER);
	Format(g_eAchievementInfo[Meat_Tenderizer][s_Desc],		SIZE_NAME-1,	"%T",	"Meat_Tenderizer_DESC",	LANG_SERVER);
	g_eAchievementInfo[Meat_Tenderizer][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Meat_Tenderizer][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Meat_Tenderizer][ReportFrequency]		=	REPORT_ALWAYS;
	g_eAchievementInfo[Meat_Tenderizer][Total]				=	15;
	
	Format(g_eAchievementInfo[Mercy_Killer][s_Name],		SIZE_NAME-1,	"%T",	"Mercy Killer",			LANG_SERVER);
	Format(g_eAchievementInfo[Mercy_Killer][s_Desc],		SIZE_NAME-1,	"%T",	"Mercy_Killer_DESC",	LANG_SERVER);
	g_eAchievementInfo[Mercy_Killer][L4D1or2]				=	GAME_L4D1;
	g_eAchievementInfo[Mercy_Killer][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Mercy_Killer][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Mercy_Killer][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Midnight_Rider][s_Name],	SIZE_NAME-1,	"%T",	"Midnight Rider",		LANG_SERVER);
	Format(g_eAchievementInfo[Midnight_Rider][s_Desc],	SIZE_NAME-1,	"%T",	"Midnight_Rider_DESC",	LANG_SERVER);
	g_eAchievementInfo[Midnight_Rider][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Midnight_Rider][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Midnight_Rider][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Midnight_Rider][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Mutant_Overlord][s_Name],	SIZE_NAME-1,	"%T",	"Mutant Overlord",		LANG_SERVER);
	Format(g_eAchievementInfo[Mutant_Overlord][s_Desc],	SIZE_NAME-1,	"%T",	"Mutant_Overlord_DESC",	LANG_SERVER);
	g_eAchievementInfo[Mutant_Overlord][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Mutant_Overlord][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Mutant_Overlord][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Mutant_Overlord][Total]				=	6;
	
	Format(g_eAchievementInfo[My_Bodyguard][s_Name],		SIZE_NAME-1,	"%T",	"My Bodyguard",			LANG_SERVER);
	Format(g_eAchievementInfo[My_Bodyguard][s_Desc],		SIZE_NAME-1,	"%T",	"My_Bodyguard_DESC",	LANG_SERVER);
	g_eAchievementInfo[My_Bodyguard][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[My_Bodyguard][b_IsRepeatable]		=	true;
	g_eAchievementInfo[My_Bodyguard][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[My_Bodyguard][Total]				=	50;
	
	Format(g_eAchievementInfo[No_one_Left_Behind][s_Name],	SIZE_NAME-1,	"%T",	"No-one Left Behind",		LANG_SERVER);
	Format(g_eAchievementInfo[No_one_Left_Behind][s_Desc],	SIZE_NAME-1,	"%T",	"No_one_Left_Behind_DESC",	LANG_SERVER);
	g_eAchievementInfo[No_one_Left_Behind][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[No_one_Left_Behind][b_IsRepeatable]	=	false;
	g_eAchievementInfo[No_one_Left_Behind][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[No_one_Left_Behind][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[No_Smoking_Section][s_Name],	SIZE_NAME-1,	"%T",	"No Smoking Section",		LANG_SERVER);
	Format(g_eAchievementInfo[No_Smoking_Section][s_Desc],	SIZE_NAME-1,	"%T",	"No_Smoking_Section_DESC",	LANG_SERVER);
	g_eAchievementInfo[No_Smoking_Section][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[No_Smoking_Section][b_IsRepeatable]	=	true;
	g_eAchievementInfo[No_Smoking_Section][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[No_Smoking_Section][Total]				=	10;
	
	Format(g_eAchievementInfo[Nothing_Special][s_Name],		SIZE_NAME-1,	"%T",	"Nothing Special",		LANG_SERVER);
	Format(g_eAchievementInfo[Nothing_Special][s_Desc],		SIZE_NAME-1,	"%T",	"Nothing_Special_DESC",	LANG_SERVER);
	g_eAchievementInfo[Nothing_Special][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Nothing_Special][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Nothing_Special][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Nothing_Special][Total]				=	CAMP_WAYTTP_L4D1;
	
	Format(g_eAchievementInfo[One_Hundred_One_Cremations][s_Name],		SIZE_NAME-1,	"%T",	"101 Cremations",					LANG_SERVER);
	Format(g_eAchievementInfo[One_Hundred_One_Cremations][s_Desc],		SIZE_NAME-1,	"%T",	"One_Hundred_One_Cremations_DESC",	LANG_SERVER);
	g_eAchievementInfo[One_Hundred_One_Cremations][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[One_Hundred_One_Cremations][b_IsRepeatable]		=	true;
	g_eAchievementInfo[One_Hundred_One_Cremations][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[One_Hundred_One_Cremations][Total]				=	101;
	
	Format(g_eAchievementInfo[Outbreak][s_Name],		SIZE_NAME-1,	"%T",	"Outbreak",			LANG_SERVER);
	Format(g_eAchievementInfo[Outbreak][s_Desc],		SIZE_NAME-1,	"%T",	"Outbreak_DESC",	LANG_SERVER);
	g_eAchievementInfo[Outbreak][L4D1or2]				=	GAME_L4D1;
	g_eAchievementInfo[Outbreak][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Outbreak][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Outbreak][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Pharm_assist][s_Name],		SIZE_NAME-1,	"%T",	"Pharm-assist",			LANG_SERVER);
	Format(g_eAchievementInfo[Pharm_assist][s_Desc],		SIZE_NAME-1,	"%T",	"Pharm_assist_DESC",	LANG_SERVER);
	g_eAchievementInfo[Pharm_assist][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Pharm_assist][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Pharm_assist][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Pharm_assist][Total]				=	10;
	
	Format(g_eAchievementInfo[Port_Of_Scavenge][s_Name],		SIZE_NAME-1,	"%T",	"Port Of Scavenge",			LANG_SERVER);
	Format(g_eAchievementInfo[Port_Of_Scavenge][s_Desc],		SIZE_NAME-1,	"%T",	"Port_Of_Scavenge_DESC",	LANG_SERVER);
	g_eAchievementInfo[Port_Of_Scavenge][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Port_Of_Scavenge][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Port_Of_Scavenge][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Port_Of_Scavenge][Total]				=	5;
	
	Format(g_eAchievementInfo[Price_Chopper][s_Name],		SIZE_NAME-1,	"%T",	"Price Chopper",		LANG_SERVER);
	Format(g_eAchievementInfo[Price_Chopper][s_Desc],		SIZE_NAME-1,	"%T",	"Price_Chopper_DESC",	LANG_SERVER);
	g_eAchievementInfo[Price_Chopper][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Price_Chopper][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Price_Chopper][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Price_Chopper][Total]				=	5;
	
	Format(g_eAchievementInfo[Pyrotechnician][s_Name],	SIZE_NAME-1,	"%T",	"Pyrotechnician",		LANG_SERVER);
	Format(g_eAchievementInfo[Pyrotechnician][s_Desc],	SIZE_NAME-1,	"%T",	"Pyrotechnician_DESC",	LANG_SERVER);
	g_eAchievementInfo[Pyrotechnician][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Pyrotechnician][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Pyrotechnician][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Pyrotechnician][Total]				=	20;
	
	Format(g_eAchievementInfo[Qualified_Ride][s_Name],	SIZE_NAME-1,	"%T",	"Qualified Ride",		LANG_SERVER);
	Format(g_eAchievementInfo[Qualified_Ride][s_Desc],	SIZE_NAME-1,	"%T",	"Qualified_Ride_DESC",	LANG_SERVER);
	g_eAchievementInfo[Qualified_Ride][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Qualified_Ride][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Qualified_Ride][ReportFrequency]	=	REPORT_ALWAYS;
	g_eAchievementInfo[Qualified_Ride][Total]				=	8;
	
	Format(g_eAchievementInfo[Quick_Power][s_Name],		SIZE_NAME-1,	"%T",	"Quick Power",		LANG_SERVER);
	Format(g_eAchievementInfo[Quick_Power][s_Desc],		SIZE_NAME-1,	"%T",	"Quick_Power_DESC",	LANG_SERVER);
	g_eAchievementInfo[Quick_Power][L4D1or2]				=	GAME_L4D1;
	g_eAchievementInfo[Quick_Power][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Quick_Power][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Quick_Power][Total]					=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Ragin_Cajun][s_Name],	SIZE_NAME-1,	"%T",	"Ragin' Cajun",		LANG_SERVER);
	Format(g_eAchievementInfo[Ragin_Cajun][s_Desc],	SIZE_NAME-1,	"%T",	"Ragin_Cajun_DESC",	LANG_SERVER);
	g_eAchievementInfo[Ragin_Cajun][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Ragin_Cajun][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Ragin_Cajun][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Ragin_Cajun][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Red_Mist][s_Name],		SIZE_NAME-1,	"%T",	"Red Mist",			LANG_SERVER);
	Format(g_eAchievementInfo[Red_Mist][s_Desc],		SIZE_NAME-1,	"%T",	"Red_Mist_DESC",	LANG_SERVER);
	g_eAchievementInfo[Red_Mist][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Red_Mist][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Red_Mist][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Red_Mist][Total]					=	1000;
	
	Format(g_eAchievementInfo[Robbed_Zombie][s_Name],		SIZE_NAME-1,	"%T",	"Robbed Zombie",		LANG_SERVER);
	Format(g_eAchievementInfo[Robbed_Zombie][s_Desc],		SIZE_NAME-1,	"%T",	"Robbed_Zombie_DESC",	LANG_SERVER);
	g_eAchievementInfo[Robbed_Zombie][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Robbed_Zombie][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Robbed_Zombie][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Robbed_Zombie][Total]				=	10;
	
	Format(g_eAchievementInfo[Rode_Hard_Put_Away_Wet][s_Name],	SIZE_NAME-1,	"%T",	"Rode Hard, Put Away Wet",		LANG_SERVER);
	Format(g_eAchievementInfo[Rode_Hard_Put_Away_Wet][s_Desc],	SIZE_NAME-1,	"%T",	"Rode_Hard_Put_Away_Wet_DESC",	LANG_SERVER);
	g_eAchievementInfo[Rode_Hard_Put_Away_Wet][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Rode_Hard_Put_Away_Wet][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Rode_Hard_Put_Away_Wet][ReportFrequency]	=	REPORT_ALWAYS;
	g_eAchievementInfo[Rode_Hard_Put_Away_Wet][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Safety_First][s_Name],		SIZE_NAME-1,	"%T",	"Safety First",			LANG_SERVER);
	Format(g_eAchievementInfo[Safety_First][s_Desc],		SIZE_NAME-1,	"%T",	"Safety_First_DESC",	LANG_SERVER);
	g_eAchievementInfo[Safety_First][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Safety_First][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Safety_First][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Safety_First][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Scattering_Ram][s_Name],	SIZE_NAME-1,	"%T",	"Scattering Ram",		LANG_SERVER);
	Format(g_eAchievementInfo[Scattering_Ram][s_Desc],	SIZE_NAME-1,	"%T",	"Scattering_Ram_DESC",	LANG_SERVER);
	g_eAchievementInfo[Scattering_Ram][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Scattering_Ram][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Scattering_Ram][ReportFrequency]	=	REPORT_ALWAYS;
	g_eAchievementInfo[Scattering_Ram][Total]				=	4;
	
	Format(g_eAchievementInfo[Scavenger_Hunt][s_Name],	SIZE_NAME-1,	"%T",	"Scavenger Hunt",		LANG_SERVER);
	Format(g_eAchievementInfo[Scavenger_Hunt][s_Desc],	SIZE_NAME-1,	"%T",	"Scavenger_Hunt_DESC",	LANG_SERVER);
	g_eAchievementInfo[Scavenger_Hunt][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Scavenger_Hunt][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Scavenger_Hunt][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Scavenger_Hunt][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Septic_Tank][s_Name],	SIZE_NAME-1,	"%T",	"Septic Tank",		LANG_SERVER);
	Format(g_eAchievementInfo[Septic_Tank][s_Desc],	SIZE_NAME-1,	"%T",	"Septic_Tank_DESC",	LANG_SERVER);
	g_eAchievementInfo[Septic_Tank][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Septic_Tank][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Septic_Tank][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Septic_Tank][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Shock_Jock][s_Name],	SIZE_NAME-1,	"%T",	"Shock Jock",		LANG_SERVER);
	Format(g_eAchievementInfo[Shock_Jock][s_Desc],	SIZE_NAME-1,	"%T",	"Shock_Jock_DESC",	LANG_SERVER);
	g_eAchievementInfo[Shock_Jock][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Shock_Jock][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Shock_Jock][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Shock_Jock][Total]				=	10;
	
	Format(g_eAchievementInfo[Silver_Bullets][s_Name],	SIZE_NAME-1,	"%T",	"Silver Bullets",		LANG_SERVER);
	Format(g_eAchievementInfo[Silver_Bullets][s_Desc],	SIZE_NAME-1,	"%T",	"Silver_Bullets_DESC",	LANG_SERVER);
	g_eAchievementInfo[Silver_Bullets][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Silver_Bullets][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Silver_Bullets][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Silver_Bullets][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Slippery_Pull][s_Name],	SIZE_NAME-1,	"%T",	"Slippery Pull",		LANG_SERVER);
	Format(g_eAchievementInfo[Slippery_Pull][s_Desc],	SIZE_NAME-1,	"%T",	"Slippery_Pull_DESC",	LANG_SERVER);
	g_eAchievementInfo[Slippery_Pull][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Slippery_Pull][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Slippery_Pull][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Slippery_Pull][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Smash_Hit][s_Name],		SIZE_NAME-1,	"%T",	"Smash Hit",		LANG_SERVER);
	Format(g_eAchievementInfo[Smash_Hit][s_Desc],		SIZE_NAME-1,	"%T",	"Smash_Hit_DESC",	LANG_SERVER);
	g_eAchievementInfo[Smash_Hit][L4D1or2]				=	GAME_L4D1;
	g_eAchievementInfo[Smash_Hit][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Smash_Hit][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Smash_Hit][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Sob_Story][s_Name],		SIZE_NAME-1,	"%T",	"Sob Story",		LANG_SERVER);
	Format(g_eAchievementInfo[Sob_Story][s_Desc],		SIZE_NAME-1,	"%T",	"Sob_Story_DESC",	LANG_SERVER);
	g_eAchievementInfo[Sob_Story][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Sob_Story][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Sob_Story][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Sob_Story][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Spinal_Tap][s_Name],	SIZE_NAME-1,	"%T",	"Spinal Tap",		LANG_SERVER);
	Format(g_eAchievementInfo[Spinal_Tap][s_Desc],	SIZE_NAME-1,	"%T",	"Spinal_Tap_DESC",	LANG_SERVER);
	g_eAchievementInfo[Spinal_Tap][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Spinal_Tap][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Spinal_Tap][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Spinal_Tap][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Stache_Whacker][s_Name],	SIZE_NAME-1,	"%T",	"Stache Whacker",		LANG_SERVER);
	Format(g_eAchievementInfo[Stache_Whacker][s_Desc],	SIZE_NAME-1,	"%T",	"Stache_Whacker_DESC",	LANG_SERVER);
	g_eAchievementInfo[Stache_Whacker][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Stache_Whacker][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Stache_Whacker][ReportFrequency]	=	REPORT_ONCE_PER_MAP;
	g_eAchievementInfo[Stache_Whacker][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Stand_Tall][s_Name],	SIZE_NAME-1,	"%T",	"Stand Tall",		LANG_SERVER);
	Format(g_eAchievementInfo[Stand_Tall][s_Desc],	SIZE_NAME-1,	"%T",	"Stand_Tall_DESC",	LANG_SERVER);
	g_eAchievementInfo[Stand_Tall][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Stand_Tall][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Stand_Tall][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Stand_Tall][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Still_Something_To_Prove][s_Name],		SIZE_NAME-1,	"%T",	"Still Something To Prove",			LANG_SERVER);
	Format(g_eAchievementInfo[Still_Something_To_Prove][s_Desc],		SIZE_NAME-1,	"%T",	"Still_Something_To_Prove_DESC",	LANG_SERVER);
	g_eAchievementInfo[Still_Something_To_Prove][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Still_Something_To_Prove][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Still_Something_To_Prove][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Still_Something_To_Prove][Total]				=	CAMP_SSTP_L4D2;
	
	Format(g_eAchievementInfo[Stomach_Upset][s_Name],		SIZE_NAME-1,	"%T",	"Stomach Upset",		LANG_SERVER);
	Format(g_eAchievementInfo[Stomach_Upset][s_Desc],		SIZE_NAME-1,	"%T",	"Stomach_Upset_DESC",	LANG_SERVER);
	g_eAchievementInfo[Stomach_Upset][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Stomach_Upset][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Stomach_Upset][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Stomach_Upset][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Strength_In_Numbers][s_Name],		SIZE_NAME-1,	"%T",	"Strength In Numbers",		LANG_SERVER);
	Format(g_eAchievementInfo[Strength_In_Numbers][s_Desc],		SIZE_NAME-1,	"%T",	"Strength_In_Numbers_DESC",	LANG_SERVER);
	g_eAchievementInfo[Strength_In_Numbers][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Strength_In_Numbers][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Strength_In_Numbers][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Strength_In_Numbers][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Tank_Burger][s_Name],	SIZE_NAME-1,	"%T",	"Tank Burger",		LANG_SERVER);
	Format(g_eAchievementInfo[Tank_Burger][s_Desc],	SIZE_NAME-1,	"%T",	"Tank_Burger_DESC",	LANG_SERVER);
	g_eAchievementInfo[Tank_Burger][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Tank_Burger][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Tank_Burger][ReportFrequency]	=	REPORT_ALWAYS;
	g_eAchievementInfo[Tank_Burger][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Tank_Stumble][s_Name],		SIZE_NAME-1,	"%T",	"Tank Stumble",			LANG_SERVER);
	Format(g_eAchievementInfo[Tank_Stumble][s_Desc],		SIZE_NAME-1,	"%T",	"Tank_Stumble_DESC",	LANG_SERVER);
	g_eAchievementInfo[Tank_Stumble][L4D1or2]				=	GAME_L4D1;
	g_eAchievementInfo[Tank_Stumble][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Tank_Stumble][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Tank_Stumble][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Tankbusters][s_Name],	SIZE_NAME-1,	"%T",	"Tankbusters",		LANG_SERVER);
	Format(g_eAchievementInfo[Tankbusters][s_Desc],	SIZE_NAME-1,	"%T",	"Tankbusters_DESC",	LANG_SERVER);
	g_eAchievementInfo[Tankbusters][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Tankbusters][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Tankbusters][ReportFrequency]	=	REPORT_ALWAYS;
	g_eAchievementInfo[Tankbusters][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[The_Littlest_Genocide][s_Name],	SIZE_NAME-1,	"%T",	"The Littlest Genocide",		LANG_SERVER);
	Format(g_eAchievementInfo[The_Littlest_Genocide][s_Desc],	SIZE_NAME-1,	"%T",	"The_Littlest_Genocide_DESC",	LANG_SERVER);
	g_eAchievementInfo[The_Littlest_Genocide][L4D1or2]			=	GAME_L4D1;
	g_eAchievementInfo[The_Littlest_Genocide][b_IsRepeatable]	=	true;
	g_eAchievementInfo[The_Littlest_Genocide][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[The_Littlest_Genocide][Total]				=	5359;
	
	Format(g_eAchievementInfo[The_Quick_And_The_Dead][s_Name],	SIZE_NAME-1,	"%T",	"The Quick And The Dead",		LANG_SERVER);
	Format(g_eAchievementInfo[The_Quick_And_The_Dead][s_Desc],	SIZE_NAME-1,	"%T",	"The_Quick_And_The_Dead_DESC",	LANG_SERVER);
	g_eAchievementInfo[The_Quick_And_The_Dead][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[The_Quick_And_The_Dead][b_IsRepeatable]	=	true;
	g_eAchievementInfo[The_Quick_And_The_Dead][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[The_Quick_And_The_Dead][Total]				=	10;
	
	Format(g_eAchievementInfo[The_Real_Deal][s_Name],		SIZE_NAME-1,	"%T",	"The Real Deal",		LANG_SERVER);
	Format(g_eAchievementInfo[The_Real_Deal][s_Desc],		SIZE_NAME-1,	"%T",	"The_Real_Deal_DESC",	LANG_SERVER);
	g_eAchievementInfo[The_Real_Deal][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[The_Real_Deal][b_IsRepeatable]		=	false;
	g_eAchievementInfo[The_Real_Deal][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[The_Real_Deal][Total]				=	CAMP_ALL_L4D2;
	
	Format(g_eAchievementInfo[Til_It_Goes_Click][s_Name],	SIZE_NAME-1,	"%T",	"Til It Goes Click",		LANG_SERVER);
	Format(g_eAchievementInfo[Til_It_Goes_Click][s_Desc],	SIZE_NAME-1,	"%T",	"Til_It_Goes_Click_DESC",	LANG_SERVER);
	g_eAchievementInfo[Til_It_Goes_Click][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Til_It_Goes_Click][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Til_It_Goes_Click][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Til_It_Goes_Click][Total]				=	25;
	
	Format(g_eAchievementInfo[Toll_Collector][s_Name],		SIZE_NAME-1,	"%T",	"Toll Collector",		LANG_SERVER);
	Format(g_eAchievementInfo[Toll_Collector][s_Desc],		SIZE_NAME-1,	"%T",	"Toll_Collector_DESC",	LANG_SERVER);
	g_eAchievementInfo[Toll_Collector][L4D1or2]			=	GAME_L4D1;
	g_eAchievementInfo[Toll_Collector][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Toll_Collector][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Toll_Collector][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Tongue_Twister][s_Name],		SIZE_NAME-1,	"%T",	"Tongue Twister",		LANG_SERVER);
	Format(g_eAchievementInfo[Tongue_Twister][s_Desc],		SIZE_NAME-1,	"%T",	"Tongue_Twister_DESC",	LANG_SERVER);
	g_eAchievementInfo[Tongue_Twister][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Tongue_Twister][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Tongue_Twister][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Tongue_Twister][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Torch_Bearer][s_Name],		SIZE_NAME-1,	"%T",	"Torch Bearer",			LANG_SERVER);
	Format(g_eAchievementInfo[Torch_Bearer][s_Desc],		SIZE_NAME-1,	"%T",	"Torch_Bearer_DESC",	LANG_SERVER);
	g_eAchievementInfo[Torch_Bearer][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Torch_Bearer][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Torch_Bearer][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Torch_Bearer][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Towering_Inferno][s_Name],		SIZE_NAME-1,	"%T",	"Towering Inferno",			LANG_SERVER);
	Format(g_eAchievementInfo[Towering_Inferno][s_Desc],		SIZE_NAME-1,	"%T",	"Towering_Inferno_DESC",	LANG_SERVER);
	g_eAchievementInfo[Towering_Inferno][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Towering_Inferno][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Towering_Inferno][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Towering_Inferno][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Truck_Stop][s_Name],	SIZE_NAME-1,	"%T",	"Truck Stop",		LANG_SERVER);
	Format(g_eAchievementInfo[Truck_Stop][s_Desc],	SIZE_NAME-1,	"%T",	"Truck_Stop_DESC",	LANG_SERVER);
	g_eAchievementInfo[Truck_Stop][L4D1or2]			=	GAME_L4D1;
	g_eAchievementInfo[Truck_Stop][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Truck_Stop][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Truck_Stop][Total]				=	4;
	
	Format(g_eAchievementInfo[Twenty_Car_Pile_up][s_Name],	SIZE_NAME-1,	"%T",	"20 Car Pile-up",			LANG_SERVER);
	Format(g_eAchievementInfo[Twenty_Car_Pile_up][s_Desc],	SIZE_NAME-1,	"%T",	"Twenty_Car_Pile_up_DESC",	LANG_SERVER);
	g_eAchievementInfo[Twenty_Car_Pile_up][L4D1or2]			=	GAME_L4D1;
	g_eAchievementInfo[Twenty_Car_Pile_up][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Twenty_Car_Pile_up][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Twenty_Car_Pile_up][Total]				=	20;
	
	Format(g_eAchievementInfo[Unbreakable][s_Name],	SIZE_NAME-1,	"%T",	"Unbreakable",		LANG_SERVER);
	Format(g_eAchievementInfo[Unbreakable][s_Desc],	SIZE_NAME-1,	"%T",	"Unbreakable_DESC",	LANG_SERVER);
	g_eAchievementInfo[Unbreakable][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Unbreakable][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Unbreakable][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Unbreakable][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Untouchables][s_Name],		SIZE_NAME-1,	"%T",	"Untouchables",			LANG_SERVER);
	Format(g_eAchievementInfo[Untouchables][s_Desc],		SIZE_NAME-1,	"%T",	"Untouchables_DESC",	LANG_SERVER);
	g_eAchievementInfo[Untouchables][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Untouchables][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Untouchables][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Untouchables][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Violence_In_Silence][s_Name],		SIZE_NAME-1,	"%T",	"Violence In Silence",		LANG_SERVER);
	Format(g_eAchievementInfo[Violence_In_Silence][s_Desc],		SIZE_NAME-1,	"%T",	"Violence_In_Silence_DESC",	LANG_SERVER);
	g_eAchievementInfo[Violence_In_Silence][L4D1or2]				=	GAME_L4D2;
	g_eAchievementInfo[Violence_In_Silence][b_IsRepeatable]		=	false;
	g_eAchievementInfo[Violence_In_Silence][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Violence_In_Silence][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Violence_Is_Golden][s_Name],	SIZE_NAME-1,	"%T",	"Violence Is Golden",		LANG_SERVER);
	Format(g_eAchievementInfo[Violence_Is_Golden][s_Desc],	SIZE_NAME-1,	"%T",	"Violence_Is_Golden_DESC",	LANG_SERVER);
	g_eAchievementInfo[Violence_Is_Golden][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Violence_Is_Golden][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Violence_Is_Golden][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Violence_Is_Golden][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Weatherman][s_Name],	SIZE_NAME-1,	"%T",	"Weatherman",		LANG_SERVER);
	Format(g_eAchievementInfo[Weatherman][s_Desc],	SIZE_NAME-1,	"%T",	"Weatherman_DESC",	LANG_SERVER);
	g_eAchievementInfo[Weatherman][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Weatherman][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Weatherman][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Weatherman][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Wedding_Crasher][s_Name],	SIZE_NAME-1,	"%T",	"Wedding Crasher",		LANG_SERVER);
	Format(g_eAchievementInfo[Wedding_Crasher][s_Desc],	SIZE_NAME-1,	"%T",	"Wedding_Crasher_DESC",	LANG_SERVER);
	g_eAchievementInfo[Wedding_Crasher][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Wedding_Crasher][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Wedding_Crasher][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Wedding_Crasher][Total]			=	8;
	
	Format(g_eAchievementInfo[What_Are_You_Trying_To_Prove][s_Name],	SIZE_NAME-1,	"%T",	"What Are You Trying To Prove?",		LANG_SERVER);
	Format(g_eAchievementInfo[What_Are_You_Trying_To_Prove][s_Desc],	SIZE_NAME-1,	"%T",	"What_Are_You_Trying_To_Prove_DESC",	LANG_SERVER);
	g_eAchievementInfo[What_Are_You_Trying_To_Prove][L4D1or2]			=	GAME_L4D1;
	g_eAchievementInfo[What_Are_You_Trying_To_Prove][b_IsRepeatable]	=	false;
	g_eAchievementInfo[What_Are_You_Trying_To_Prove][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[What_Are_You_Trying_To_Prove][Total]				=	CAMP_WAYTTP_L4D1;
	
	Format(g_eAchievementInfo[Wing_And_A_Prayer][s_Name],	SIZE_NAME-1,	"%T",	"Wing And A Prayer",		LANG_SERVER);
	Format(g_eAchievementInfo[Wing_And_A_Prayer][s_Desc],	SIZE_NAME-1,	"%T",	"Wing_And_A_Prayer_DESC",	LANG_SERVER);
	g_eAchievementInfo[Wing_And_A_Prayer][L4D1or2]			=	GAME_L4D2;
	g_eAchievementInfo[Wing_And_A_Prayer][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Wing_And_A_Prayer][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Wing_And_A_Prayer][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Wipefest][s_Name],		SIZE_NAME-1,	"%T",	"Wipefest",			LANG_SERVER);
	Format(g_eAchievementInfo[Wipefest][s_Desc],		SIZE_NAME-1,	"%T",	"Wipefest_DESC",	LANG_SERVER);
	g_eAchievementInfo[Wipefest][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Wipefest][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Wipefest][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Wipefest][Total]				=	3;
	
	Format(g_eAchievementInfo[Witch_Hunter][s_Name],		SIZE_NAME-1,	"%T",	"Witch Hunter",			LANG_SERVER);
	Format(g_eAchievementInfo[Witch_Hunter][s_Desc],		SIZE_NAME-1,	"%T",	"Witch_Hunter_DESC",	LANG_SERVER);
	g_eAchievementInfo[Witch_Hunter][L4D1or2]				=	GAME_L4D12;
	g_eAchievementInfo[Witch_Hunter][b_IsRepeatable]		=	true;
	g_eAchievementInfo[Witch_Hunter][ReportFrequency]		=	REPORT_DISABLED;
	g_eAchievementInfo[Witch_Hunter][Total]				=	NO_TOTAL;
	
	Format(g_eAchievementInfo[Zombicidal_Maniac][s_Name],	SIZE_NAME-1,	"%T",	"Zombicidal Maniac",		LANG_SERVER);
	Format(g_eAchievementInfo[Zombicidal_Maniac][s_Desc],	SIZE_NAME-1,	"%T",	"Zombicidal_Maniac_DESC",	LANG_SERVER);
	g_eAchievementInfo[Zombicidal_Maniac][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Zombicidal_Maniac][b_IsRepeatable]	=	false;
	g_eAchievementInfo[Zombicidal_Maniac][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Zombicidal_Maniac][Total]				=	CAMP_ALL;
	
	Format(g_eAchievementInfo[Zombie_Genocidest][s_Name],	SIZE_NAME-1,	"%T",	"Zombie Genocidest",		LANG_SERVER);
	Format(g_eAchievementInfo[Zombie_Genocidest][s_Desc],	SIZE_NAME-1,	"%T",	"Zombie_Genocidest_DESC",	LANG_SERVER);
	g_eAchievementInfo[Zombie_Genocidest][L4D1or2]			=	GAME_L4D12;
	g_eAchievementInfo[Zombie_Genocidest][b_IsRepeatable]	=	true;
	g_eAchievementInfo[Zombie_Genocidest][ReportFrequency]	=	REPORT_DISABLED;
	g_eAchievementInfo[Zombie_Genocidest][Total]				=	53595;
}

static _ModuleEnabled() {
	HookEvent("award_earned",			_Event__Award_Earned,			EventHookMode_Post);
	HookEvent("vote_passed",			_Event__Vote_Passed,			EventHookMode_Post);
	HookEvent("map_transition",		_Event__Map_Transition,		EventHookMode_PostNoCopy);
	HookEvent("player_transitioned",	_Event__Player_Transitioned,	EventHookMode_Post);
	HookEvent("player_first_spawn",	_Event__Player_First_Spawn,	EventHookMode_Post);
	HookEvent("round_start_post_nav",	_Event__Round_Start_Post_Nav,	EventHookMode_PostNoCopy);
	HookEvent("round_start",			_Event__Round_Start,			EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_start",	_Event__Scavenge_Round_Start,	EventHookMode_Post);
	HookEvent("survival_round_start",	_Event__Survival_Round_Start,	EventHookMode_PostNoCopy);
	HookEvent("versus_round_start",	_Event__Versus_Round_Start,	EventHookMode_PostNoCopy);
	HookEvent("round_end",				_Event__Round_End,				EventHookMode_PostNoCopy);
	HookEvent("finale_start",			_Event__Finale_Start,			EventHookMode_PostNoCopy);
	HookEvent("finale_win",			_Event__Finale_Win,			EventHookMode_Post);
	HookEvent("mission_lost",			_Event__Mission_Lost,			EventHookMode_PostNoCopy);
	HookEvent("difficulty_changed",	_Event__Difficulty_Changed,	EventHookMode_Post);
	HookEvent("friendly_fire",			_Event__Friendly_Fire,		EventHookMode_Post);
	HookEvent("player_team",			_Event__Player_Team,			EventHookMode_Post);
	HookEvent("player_bot_replace",	_Event__Player_Bot_Replace,	EventHookMode_Post);
	HookEvent("bot_player_replace",	_Event__Bot_Player_Replace,	EventHookMode_Post);
	HookEvent("player_shoved",			_Event__Player_Shoved,		EventHookMode_Post);
	HookEvent("player_hurt",			_Event__Player_Hurt,			EventHookMode_Post);
	HookEvent("player_incapacitated",	_Event__Player_Incapacitated,	EventHookMode_Post);
	HookEvent("player_death",			_Event__Player_Death,			EventHookMode_Post);
	HookEvent("revive_success",		_Event__Revive_Success,		EventHookMode_Post);
	HookEvent("defibrillator_used",	_Event__Defibrillator_Used,	EventHookMode_Post);
	HookEvent("respawning",			_Event__Respawning,			EventHookMode_Post);
	HookEvent("ability_use",			_Event__Ability_Use,			EventHookMode_Post);
	HookEvent("player_now_it",			_Event__Player_Now_It,		EventHookMode_Post);
	HookEvent("player_no_longer_it",	_Event__Player_No_Longer_It,	EventHookMode_Post);
	HookEvent("hunter_headshot",		_Event__Hunter_Headshot,		EventHookMode_Post);
	HookEvent("hunter_punched",		_Event__Hunter_Punched,		EventHookMode_Post);
	HookEvent("tank_spawn",			_Event__Tank_Spawn,			EventHookMode_Post);
	HookEvent("tank_frustrated",		_Event__Tank_Frustrated,		EventHookMode_Post);
	HookEvent("tank_killed",			_Event__Tank_Killed,			EventHookMode_Post);
	if (g_bIsL4D2) {
		HookEvent("stashwhacker_game_won",			_Event__StashWhacker_GameWon,	EventHookMode_PostNoCopy);
		HookEvent("strongman_bell_knocked_off",	_Event__Strongman_BellKO,		EventHookMode_Post);
		HookEvent("charger_impact",				_Event__Charger_Impact,		EventHookMode_Post);
		HookEvent("charger_carry_start",			_Event__Charger_Carry_Start,	EventHookMode_Post);
		HookEvent("charger_carry_end",				_Event__Charger_Carry_End,	EventHookMode_Post);
		HookEvent("charger_pummel_start",			_Event__Charger_Pummel_Start,	EventHookMode_Post);
		HookEvent("charger_pummel_end",			_Event__Charger_Pummel_End,	EventHookMode_Post);
		HookEvent("charger_killed",				_Event__Charger_Killed,		EventHookMode_Post);
		HookEvent("jockey_ride",					_Event__Jockey_Ride,			EventHookMode_Post);
		HookEvent("jockey_ride_end",				_Event__Jockey_Ride_End,		EventHookMode_Post);
	}
	/*
		Notes:
			entity_shoved will not help with wedding crasher.. doesn't trigger when charging into chairs.
	*/
	DebugPrintToAll("[_ModuleEnabled] All hooks made.");
}

static _ModuleDisabled() {
	UnhookEvent("award_earned",			_Event__Award_Earned,			EventHookMode_Post);
	UnhookEvent("vote_passed",				_Event__Vote_Passed,			EventHookMode_Post);
	UnhookEvent("map_transition",			_Event__Map_Transition,		EventHookMode_PostNoCopy);
	UnhookEvent("player_transitioned",		_Event__Player_Transitioned,	EventHookMode_Post);
	UnhookEvent("player_first_spawn",		_Event__Player_First_Spawn,	EventHookMode_Post);
	UnhookEvent("round_start_post_nav",	_Event__Round_Start_Post_Nav,	EventHookMode_PostNoCopy);
	UnhookEvent("round_start",				_Event__Round_Start,			EventHookMode_PostNoCopy);
	UnhookEvent("scavenge_round_start",	_Event__Scavenge_Round_Start,	EventHookMode_Post);
	UnhookEvent("survival_round_start",	_Event__Survival_Round_Start,	EventHookMode_PostNoCopy);
	UnhookEvent("versus_round_start",		_Event__Versus_Round_Start,	EventHookMode_PostNoCopy);
	UnhookEvent("round_end",				_Event__Round_End,				EventHookMode_PostNoCopy);
	UnhookEvent("finale_start",			_Event__Finale_Start,			EventHookMode_PostNoCopy);
	UnhookEvent("finale_win",				_Event__Finale_Win,			EventHookMode_PostNoCopy);
	UnhookEvent("mission_lost",			_Event__Mission_Lost,			EventHookMode_PostNoCopy);
	UnhookEvent("difficulty_changed",		_Event__Difficulty_Changed,	EventHookMode_Post);
	UnhookEvent("friendly_fire",			_Event__Friendly_Fire,		EventHookMode_Post);
	UnhookEvent("player_team",				_Event__Player_Team,			EventHookMode_Post);
	UnhookEvent("player_bot_replace",		_Event__Player_Bot_Replace,	EventHookMode_Post);
	UnhookEvent("bot_player_replace",		_Event__Bot_Player_Replace,	EventHookMode_Post);
	UnhookEvent("player_shoved",			_Event__Player_Shoved,		EventHookMode_Post);
	UnhookEvent("player_hurt",				_Event__Player_Hurt,			EventHookMode_Post);
	UnhookEvent("player_incapacitated",	_Event__Player_Incapacitated,	EventHookMode_Post);
	UnhookEvent("player_death",			_Event__Player_Death,			EventHookMode_Post);
	UnhookEvent("revive_success",			_Event__Revive_Success,		EventHookMode_Post);
	UnhookEvent("defibrillator_used",		_Event__Defibrillator_Used,	EventHookMode_Post);
	UnhookEvent("respawning",				_Event__Respawning,			EventHookMode_Post);
	UnhookEvent("ability_use",				_Event__Ability_Use,			EventHookMode_Post);
	UnhookEvent("player_now_it",			_Event__Player_Now_It,		EventHookMode_Post);
	UnhookEvent("player_no_longer_it",		_Event__Player_No_Longer_It,	EventHookMode_Post);
	UnhookEvent("hunter_headshot",			_Event__Hunter_Headshot,		EventHookMode_Post);
	UnhookEvent("hunter_punched",			_Event__Hunter_Punched,		EventHookMode_Post);
	UnhookEvent("tank_spawn",				_Event__Tank_Spawn,			EventHookMode_Post);
	UnhookEvent("tank_frustrated",			_Event__Tank_Frustrated,		EventHookMode_Post);
	UnhookEvent("tank_killed",				_Event__Tank_Killed,			EventHookMode_Post);
	if (g_bIsL4D2) {
		UnhookEvent("stashwhacker_game_won",		_Event__StashWhacker_GameWon,		EventHookMode_PostNoCopy);
		UnhookEvent("strongman_bell_knocked_off",	_Event__Strongman_BellKO,			EventHookMode_Post);
		UnhookEvent("charger_impact",				_Event__Charger_Impact,			EventHookMode_Post);
		UnhookEvent("charger_carry_start",			_Event__Charger_Carry_Start,		EventHookMode_Post);
		UnhookEvent("charger_carry_end",			_Event__Charger_Carry_End,		EventHookMode_Post);
		UnhookEvent("charger_pummel_start",		_Event__Charger_Pummel_Start,		EventHookMode_Post);
		UnhookEvent("charger_pummel_end",			_Event__Charger_Pummel_End,		EventHookMode_Post);
		UnhookEvent("charger_killed",				_Event__Charger_Killed,			EventHookMode_Post);
		UnhookEvent("jockey_ride",					_Event__Jockey_Ride,				EventHookMode_Post);
		UnhookEvent("jockey_ride_end",				_Event__Jockey_Ride_End,			EventHookMode_Post);
	}
	DebugPrintToAll("[_ModuleDisabled] All hooks removed.");
}

stock DebugPrintToAll(const String:format[], any:...) {
	if (!g_bLogToChat && !g_bLogToFile)
		return;
	
	decl String:buffer[250];
	VFormat(buffer, sizeof(buffer), format, 2);
	
	if (g_bLogToChat) {
		PrintToChatAll("%s %s", TAG_DEBUG, buffer);
		PrintToConsole(0, "%s %s", TAG_DEBUG, buffer);
	}
	if (g_bLogToFile)
		LogMessage("%s", buffer);
	
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
}
