//////////////////////////////////////////
// Automatic Campaign Switcher for L4D2 //
// Version 1.2.2                        //
// Compiled May 21, 2011                //
// Programmed by Chris Pringle          //
//////////////////////////////////////////

/*==================================================================================================

	This plugin was written in response to the server kicking everyone if the vote is not passed
	at the end of the campaign. It will automatically switch to the appropriate map at all the
	points a vote would be automatically called, by the game, to go to the lobby or play again.
	ACS also includes a voting system in which people can vote for their favorite campaign/map
	on a finale or scavenge map.  The winning campaign/map will become the next map the server
	loads.

	Supported Game Modes in Left 4 Dead 2
	
		Coop
		Realism
		Versus
		Team Versus
		Scavenge
		Team Scavenge
		Mutation 1-20
		Community 1-5

	Change Log
		
		v1.2.2 (May 21, 2011)	- Added message for new vote winner when a player disconnects
								- Fixed the sound to play to all the players in the game
								- Added a max amount of coop finale map failures cvar
								- Changed the wait time for voting ad from round_start to the 
								  player_left_start_area event 
								- Added the voting sound when the vote menu pops up
		
		v1.2.1 (May 18, 2011)	- Fixed mutation 15 (Versus Survival)
		
		v1.2.0 (May 16, 2011)	- Changed some of the text to be more clear
								- Added timed notifications for the next map
								- Added a cvar for how to advertise the next map
								- Added a cvar for the next map advertisement interval
								- Added a sound to help notify players of a new vote winner
								- Added a cvar to enable/disable sound notification
								- Added a custom wait time for coop game modes
								
		v1.1.0 (May 12, 2011)	- Added a voting system
								- Added error checks if map is not found when switching
								- Added a cvar for enabling/disabling voting system
								- Added a cvar for how to advertise the voting system
								- Added a cvar for time to wait for voting advertisement
								- Added all current Mutation and Community game modes
								
		v1.0.0 (May 5, 2011)	- Initial Release

===================================================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"v1.2.2"

//Define the wait time after round before changing to the next map in each game mode
#define WAIT_TIME_BEFORE_SWITCH_COOP			7.0
#define WAIT_TIME_BEFORE_SWITCH_VERSUS			6.0
#define WAIT_TIME_BEFORE_SWITCH_SCAVENGE		11.0

//Define Game Modes
#define GAMEMODE_UNKNOWN	-1
#define GAMEMODE_COOP 		0
#define GAMEMODE_VERSUS 	1
#define GAMEMODE_SCAVENGE 	2
#define GAMEMODE_SURVIVAL 	3

#define DISPLAY_MODE_DISABLED	0
#define DISPLAY_MODE_HINT		1
#define DISPLAY_MODE_CHAT		2
#define DISPLAY_MODE_MENU		3

#define SOUND_NEW_VOTE_START	"ui/Beep_SynthTone01.wav"
#define SOUND_NEW_VOTE_WINNER	"ui/alert_clink.wav"


//Global Variables

new g_iGameMode;					//Integer to store the gamemode
new g_iRoundEndCounter;				//Round end event counter for versus
new g_iCoopFinaleFailureCount;		//Number of times the Survivors have lost the current finale
new g_iMaxCoopFinaleFailures = 5;	//Amount of times Survivors can fail before ACS switches in coop
new bool:g_bFinaleWon;				//Indicates whether a finale has be beaten or not

//Voting Variables
new bool:g_bVotingEnabled = true;							//Tells if the voting system is on
new g_iVotingAdDisplayMode = DISPLAY_MODE_HINT;				//The way to advertise the voting system
new Float:g_fVotingAdDelayTime = 1.0;						//Time to wait before showing advertising
new bool:g_bVoteWinnerSoundEnabled = true;					//Sound plays when vote winner changes
new g_iNextMapAdDisplayMode = DISPLAY_MODE_HINT;			//The way to advertise the next map
new Float:g_fNextMapAdInterval = 600.0;						//Interval for ACS next map advertisement
new bool:g_bClientShownVoteAd[MAXPLAYERS + 1];				//If the client has seen the ad already
new bool:g_bClientVoted[MAXPLAYERS + 1];					//If the client has voted on a map
new g_iClientVote[MAXPLAYERS + 1];							//The value of the clients vote
new g_iWinningMapIndex;										//Winning map/campaign's index
new g_iWinningMapVotes;										//Winning map/campaign's number of votes
new Handle:g_hMenu_Vote[MAXPLAYERS + 1]	= INVALID_HANDLE;	//Handle for each players vote menu
new Handle:g_hMenu_VoteCampaign	= INVALID_HANDLE;

//Console Variables (CVars)
new Handle:g_hCVar_VotingEnabled			= INVALID_HANDLE;
new Handle:g_hCVar_VoteWinnerSoundEnabled	= INVALID_HANDLE;
new Handle:g_hCVar_VotingAdMode				= INVALID_HANDLE;
new Handle:g_hCVar_VotingAdDelayTime		= INVALID_HANDLE;
new Handle:g_hCVar_NextMapAdMode			= INVALID_HANDLE;
new Handle:g_hCVar_NextMapAdInterval		= INVALID_HANDLE;
new Handle:g_hCVar_MaxFinaleFailures		= INVALID_HANDLE;
new Handle:g_hCVar_ChMapAnnounceMode		= INVALID_HANDLE;
new Handle:g_hCVar_ChMapBroadcastInterval	= INVALID_HANDLE;


new Handle:g_hTimer_Broadcast;

/*======================================================================================
##################            A C S   M A P   S T R I N G S            #################
========================================================================================
###                                                                                  ###
###      ***  EDIT THESE STRINGS TO CHANGE THE MAP ROTATIONS TO YOUR LIKING  ***     ###
###                                                                                  ###
========================================================================================
###                                                                                  ###
###       Note: The order these strings are stored is important, so make             ###
###             sure these match up or it will not work properly.                    ###
###                                                                                  ###
###       Notice, all of the strings corresponding with [1] in the array match.      ###
###                                                                                  ###
======================================================================================*/
#define LEN_MAPFILE 32
#define LEN_MAPNAME 64
#define LEN_MAX_PATH 260
#define LEN_CFG_LINE 128
#define LEN_CFG_SEGMENT 64

new Handle:g_hStrCampaignFirstMap = INVALID_HANDLE;
new Handle:g_hStrCampaignLastMap = INVALID_HANDLE;
new Handle:g_hStrCampaignName = INVALID_HANDLE;
new numberOfCyclingCampaignMap;
new Handle:g_hStrScavengeMap = INVALID_HANDLE;
new Handle:g_hStrScavengeName = INVALID_HANDLE;
new numberOfCyclingScavengeMap;

new String:campaignListFile[LEN_MAX_PATH];

SetupMapStrings()
{	
	decl String:buffer[LEN_CFG_LINE], String:buffer_split[3][LEN_CFG_SEGMENT];
	new Handle:h_maplist = INVALID_HANDLE;	

	g_hStrCampaignFirstMap = CreateArray(LEN_MAPFILE);
	g_hStrCampaignLastMap = CreateArray(LEN_MAPFILE);
	g_hStrCampaignName = CreateArray(LEN_MAPNAME);
	g_hStrScavengeMap = CreateArray(LEN_MAPFILE);
	g_hStrScavengeName = CreateArray(LEN_MAPNAME);

	//The following three variables are for all game modes except Scavenge.
	if(!FileExists(campaignListFile)) {
		LogError("[Map Vote] Votelist \"%s\" not found, use default list instead.", campaignListFile);
		addCampaignMap("c8m1_apartment", "c8m5_rooftop", "No Mercy");
		addCampaignMap("c1m1_hotel", "c1m4_atrium", "Dead Center");
		addCampaignMap("c7m1_docks", "c7m3_port", "The Sacrifice");
		addCampaignMap("c6m1_riverbank", "c6m3_port", "The Passing");
		addCampaignMap("c2m1_highway", "c2m5_concert", "Dark Carnival");
		addCampaignMap("c3m1_plankcountry", "c3m4_plantation", "Swamp Fever");
		addCampaignMap("c4m1_milltown_a", "c4m5_milltown_escape", "Hard Rain");
		addCampaignMap("c5m1_waterfront", "c5m5_bridge", "The Parish");
		addCampaignMap("c13m1_alpinecreek", "c13m4_cutthroatcreek", "Cold Stream");
		numberOfCyclingCampaignMap = getNumberOfCampaign();
	} else {
		h_maplist = OpenFile(campaignListFile, "r");

		ReadFileLine(h_maplist, buffer, sizeof(buffer));
		while(!IsEndOfFile(h_maplist) && ReadFileLine(h_maplist, buffer, sizeof(buffer))) {
			ReplaceString(buffer, sizeof(buffer), "\n", "");
			TrimString(buffer);
			if (StrContains(buffer, "//") == 0) {
				if (StrContains(buffer, "// 3-rd maps(Do not delete/modify this line!)") == 0) {
					numberOfCyclingCampaignMap = getNumberOfCampaign();
				}

				// Ignore comments
			} else {
				ExplodeString(buffer, ",", buffer_split, LEN_CFG_LINE, LEN_CFG_SEGMENT);
				TrimString(buffer_split[0]);
				TrimString(buffer_split[1]);
				TrimString(buffer_split[2]);
				addCampaignMap(buffer_split[0], buffer_split[1], buffer_split[2]);
				if(!IsMapValid(buffer_split[0])) {
					LogError("[Map Vote] Invalid map name \"%s\" in votelist \"%s\".", buffer_split[0], campaignListFile);
				}
			}
		}
		CloseHandle(h_maplist);
	}

	PrintToServer("MapList=%s", campaignListFile);	
	PrintToServer("Num of Campaign=%d, %d", numberOfCyclingCampaignMap, getNumberOfCampaign());
	for (int i=0; i<getNumberOfCampaign(); i++) {
		char mapName[LEN_MAPNAME];
		getCampaignName(i, mapName);
		PrintToServer("%d=%s", i, mapName);
	}

	//The following string variables are only for Scavenge
	addScavengeMap("c8m1_apartment", "Apartments");
	addScavengeMap("c8m5_rooftop", "Rooftop");
	addScavengeMap("c1m4_atrium", "Mall Atrium");
	addScavengeMap("c7m1_docks", "Brick Factory");
	addScavengeMap("c7m2_barge", "Barge");
	addScavengeMap("c6m1_riverbank", "Riverbank");
	addScavengeMap("c6m2_bedlam", "Underground");
	addScavengeMap("c6m3_port", "Port");
	addScavengeMap("c2m1_highway", "Motel");
	addScavengeMap("c3m1_plankcountry", "Plank Country");
	addScavengeMap("c4m1_milltown_a", "Milltown");
	addScavengeMap("c4m2_sugarmill_a", "Sugar Mill");
	addScavengeMap("c5m2_park", "Park");
	numberOfCyclingScavengeMap = getNumberOfScavengeMap();
}



addCampaignMap(char[] firstMap, char[] lastMap, char[] name){
	PushArrayString(g_hStrCampaignFirstMap, firstMap);
	PushArrayString(g_hStrCampaignLastMap, lastMap);
	PushArrayString(g_hStrCampaignName, name);
}

String:getCampaignFirstMap(index) {
	decl String:mapFileName[LEN_MAPFILE];
	GetArrayString(g_hStrCampaignFirstMap, index, mapFileName, LEN_MAPFILE);
	return mapFileName;
}

String:getCampaignLastMap(index) {
	decl String:mapFileName[LEN_MAPFILE];
	GetArrayString(g_hStrCampaignLastMap, index, mapFileName, LEN_MAPFILE);
	return mapFileName;
}

int getCampaignName(int index, char[] mapName) {
	return GetArrayString(g_hStrCampaignName, index, mapName, LEN_MAPNAME);
}

int getNumberOfCampaign() {
	return GetArraySize(g_hStrCampaignFirstMap);
}

addScavengeMap(char[] map, char[] name) {
	PushArrayString(g_hStrScavengeMap, map);
	PushArrayString(g_hStrScavengeName, name);
}

String:getScavengeMap(index) {
	decl String:mapFileName[LEN_MAPFILE];
	GetArrayString(g_hStrScavengeMap, index, mapFileName, LEN_MAPFILE);
	return mapFileName;
}

String:getScavengeName(index) {
	decl String:mapName[LEN_MAPNAME];
	GetArrayString(g_hStrScavengeName, index, mapName, LEN_MAPNAME);
	return mapName;
}

int getNumberOfScavengeMap() {
	return GetArraySize(g_hStrScavengeMap);
}
/*======================================================================================
#####################             P L U G I N   I N F O             ####################
======================================================================================*/

public Plugin:myinfo = 
{
	name = "Automatic Campaign Switcher (ACS)",
	author = "Chris Pringle & Rikka0w0",
	description = "Automatically switches to the next campaign when the previous campaign is over",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=156392"
}

/*======================================================================================
#################             O N   P L U G I N   S T A R T            #################
======================================================================================*/

public OnPluginStart()
{
	LoadTranslations("acs.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("basevotes.phrases");

	decl String: game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Use this in Left 4 Dead or Left 4 Dead 2 only.");
	}

	BuildPath(Path_SM, campaignListFile, sizeof(campaignListFile), "configs/maplist.txt");
	//Get the strings for all of the maps that are in rotation
	SetupMapStrings();
	BuildVoteCampaignMenu();
	
	//Create custom console variables
	CreateConVar("acs_version", PLUGIN_VERSION, "Version of Automatic Campaign Switcher (ACS) on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCVar_VotingEnabled = CreateConVar("acs_voting_system_enabled", "1", "Enables players to vote for the next map or campaign [0 = DISABLED, 1 = ENABLED]", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCVar_VoteWinnerSoundEnabled = CreateConVar("acs_voting_sound_enabled", "1", "Determines if a sound plays when a new map is winning the vote [0 = DISABLED, 1 = ENABLED]", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCVar_VotingAdMode = CreateConVar("acs_voting_ad_mode", "3", "Sets how to advertise voting at the start of the map [0 = DISABLED, 1 = HINT TEXT, 2 = CHAT TEXT, 3 = OPEN VOTE MENU]\n * Note: This is only displayed once during a finale or scavenge map *", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	g_hCVar_VotingAdDelayTime = CreateConVar("acs_voting_ad_delay_time", "10.0", "Time, in seconds, to wait after survivors leave the start area to advertise voting as defined in acs_voting_ad_mode\n * Note: If the server is up, changing this in the .cfg file takes two map changes before the change takes place *", FCVAR_PLUGIN, true, 0.1, false);
	g_hCVar_NextMapAdMode = CreateConVar("acs_next_map_ad_mode", "2", "Sets how the next campaign/map is advertised during a finale or scavenge map [0 = DISABLED, 1 = HINT TEXT, 2 = CHAT TEXT]", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_hCVar_NextMapAdInterval = CreateConVar("acs_next_map_ad_interval", "60.0", "The time, in seconds, between advertisements for the next campaign/map on finales and scavenge maps", FCVAR_PLUGIN, true, 60.0, false);
	g_hCVar_MaxFinaleFailures = CreateConVar("acs_max_coop_finale_failures", "0", "The amount of times the survivors can fail a finale in Coop before it switches to the next campaign [0 = INFINITE FAILURES]", FCVAR_PLUGIN, true, 0.0, false);
	g_hCVar_ChMapAnnounceMode = CreateConVar("avs_chmap_announce_mode", "3", "Controls how mapvote announcement is displayed. 0 - disabled, 1 - chat, 2 - hint text, 3 - both");
	g_hCVar_ChMapBroadcastInterval =  CreateConVar("acs_chmap_broadcast_interval", "180.0", "Controls how frequent the hint if change map vote is displayed, in second.");	

	//Hook console variable changes
	HookConVarChange(g_hCVar_VotingEnabled, CVarChange_Voting);
	HookConVarChange(g_hCVar_VoteWinnerSoundEnabled, CVarChange_NewVoteWinnerSound);
	HookConVarChange(g_hCVar_VotingAdMode, CVarChange_VotingAdMode);
	HookConVarChange(g_hCVar_VotingAdDelayTime, CVarChange_VotingAdDelayTime);
	HookConVarChange(g_hCVar_NextMapAdMode, CVarChange_NewMapAdMode);
	HookConVarChange(g_hCVar_NextMapAdInterval, CVarChange_NewMapAdInterval);
	HookConVarChange(g_hCVar_MaxFinaleFailures, CVarChange_MaxFinaleFailures);
	HookConVarChange(g_hCVar_ChMapAnnounceMode, CVarChange_ChMapBroadcast);
	HookConVarChange(g_hCVar_ChMapBroadcastInterval, CVarChange_ChMapBroadcast);
		
	//Hook the game events
	//HookEvent("round_start", Event_RoundStart);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_win", Event_FinaleWin);
	HookEvent("scavenge_match_finished", Event_ScavengeMapFinished);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	
	//Register custom console commands
	RegConsoleCmd("mapvote", MapVote);
	RegConsoleCmd("mapvotes", DisplayCurrentVotes);
	RegConsoleCmd("sm_chmap", Command_ChangeMapVote);
	RegConsoleCmd("sm_changemapvote", Command_ChangeMapVote);
	RegConsoleCmd("sm_acs_maps", Command_MapList);
}

public OnConfigsExecuted() {
	MakeChMapBroadcastTimer();
}

MakeChMapBroadcastTimer() {
	if (g_hTimer_Broadcast != null) {
		KillTimer(g_hTimer_Broadcast);
		g_hTimer_Broadcast = null;
	}

	if(GetConVarInt(g_hCVar_ChMapAnnounceMode) != 0)
		g_hTimer_Broadcast = CreateTimer(GetConVarFloat(g_hCVar_ChMapBroadcastInterval), Timer_WelcomeMessage, INVALID_HANDLE, TIMER_REPEAT);
}

public Action:Timer_WelcomeMessage(Handle:timer, any:param) {
	PrintToChatAll("\x03[ACS]\x01 %t: \x04!chmap\x01 %t.", "Announce", "Announce2");
}

/*======================================================================================
##########           C V A R   C A L L B A C K   F U N C T I O N S           ###########
======================================================================================*/
public CVarChange_ChMapBroadcast(Handle:hCVar, const String:strOldValue[], const String:strNewValue[]) {
	MakeChMapBroadcastTimer();
}

//Callback function for the cvar for voting system
public CVarChange_Voting(Handle:hCVar, const String:strOldValue[], const String:strNewValue[])
{
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false) == true)
		return;
	
	//If the value was changed, then set it and display a message to the server and players
	if (StringToInt(strNewValue) == 1)
	{
		g_bVotingEnabled = true;
		PrintToServer("[ACS] ConVar changed: Voting System ENABLED");
		PrintToChatAll("[ACS] ConVar changed: Voting System ENABLED");
	}
	else
	{
		g_bVotingEnabled = false;
		PrintToServer("[ACS] ConVar changed: Voting System DISABLED");
		PrintToChatAll("[ACS] ConVar changed: Voting System DISABLED");
	}
}

//Callback function for enabling or disabling the new vote winner sound
public CVarChange_NewVoteWinnerSound(Handle:hCVar, const String:strOldValue[], const String:strNewValue[])
{
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false) == true)
		return;
	
	//If the value was changed, then set it and display a message to the server and players
	if (StringToInt(strNewValue) == 1)
	{
		g_bVoteWinnerSoundEnabled = true;
		PrintToServer("[ACS] ConVar changed: New vote winner sound ENABLED");
		PrintToChatAll("[ACS] ConVar changed: New vote winner sound ENABLED");
	}
	else
	{
		g_bVoteWinnerSoundEnabled = false;
		PrintToServer("[ACS] ConVar changed: New vote winner sound DISABLED");
		PrintToChatAll("[ACS] ConVar changed: New vote winner sound DISABLED");
	}
}

//Callback function for how the voting system is advertised to the players at the beginning of the round
public CVarChange_VotingAdMode(Handle:hCVar, const String:strOldValue[], const String:strNewValue[])
{
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false) == true)
		return;
	
	//If the value was changed, then set it and display a message to the server and players
	switch(StringToInt(strNewValue))
	{
		case 0:
		{
			g_iVotingAdDisplayMode = DISPLAY_MODE_DISABLED;
			PrintToServer("[ACS] ConVar changed: Voting display mode: DISABLED");
			PrintToChatAll("[ACS] ConVar changed: Voting display mode: DISABLED");
		}
		case 1:
		{
			g_iVotingAdDisplayMode = DISPLAY_MODE_HINT;
			PrintToServer("[ACS] ConVar changed: Voting display mode: HINT TEXT");
			PrintToChatAll("[ACS] ConVar changed: Voting display mode: HINT TEXT");
		}
		case 2:
		{
			g_iVotingAdDisplayMode = DISPLAY_MODE_CHAT;
			PrintToServer("[ACS] ConVar changed: Voting display mode: CHAT TEXT");
			PrintToChatAll("[ACS] ConVar changed: Voting display mode: CHAT TEXT");
		}
		case 3:
		{
			g_iVotingAdDisplayMode = DISPLAY_MODE_MENU;
			PrintToServer("[ACS] ConVar changed: Voting display mode: OPEN VOTE MENU");
			PrintToChatAll("[ACS] ConVar changed: Voting display mode: OPEN VOTE MENU");
		}
	}
}

//Callback function for the cvar for voting display delay time
public CVarChange_VotingAdDelayTime(Handle:hCVar, const String:strOldValue[], const String:strNewValue[])
{
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false) == true)
		return;
	
	//Get the new value
	new Float:fDelayTime = StringToFloat(strNewValue);
	
	//If the value was changed, then set it and display a message to the server and players
	if (fDelayTime > 0.1)
	{
		g_fVotingAdDelayTime = fDelayTime;
		PrintToServer("[ACS] ConVar changed: Voting advertisement delay time changed to %f", fDelayTime);
		PrintToChatAll("[ACS] ConVar changed: Voting advertisement delay time changed to %f", fDelayTime);
	}
	else
	{
		g_fVotingAdDelayTime = 0.1;
		PrintToServer("[ACS] ConVar changed: Voting advertisement delay time changed to 0.1");
		PrintToChatAll("[ACS] ConVar changed: Voting advertisement delay time changed to 0.1");
	}
}

//Callback function for how ACS and the next map is advertised to the players during a finale
public CVarChange_NewMapAdMode(Handle:hCVar, const String:strOldValue[], const String:strNewValue[])
{
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false) == true)
		return;
	
	//If the value was changed, then set it and display a message to the server and players
	switch(StringToInt(strNewValue))
	{
		case 0:
		{
			g_iNextMapAdDisplayMode = DISPLAY_MODE_DISABLED;
			PrintToServer("[ACS] ConVar changed: Next map advertisement display mode: DISABLED");
			PrintToChatAll("[ACS] ConVar changed: Next map advertisement display mode: DISABLED");
		}
		case 1:
		{
			g_iNextMapAdDisplayMode = DISPLAY_MODE_HINT;
			PrintToServer("[ACS] ConVar changed: Next map advertisement display mode: HINT TEXT");
			PrintToChatAll("[ACS] ConVar changed: Next map advertisement display mode: HINT TEXT");
		}
		case 2:
		{
			g_iNextMapAdDisplayMode = DISPLAY_MODE_CHAT;
			PrintToServer("[ACS] ConVar changed: Next map advertisement display mode: CHAT TEXT");
			PrintToChatAll("[ACS] ConVar changed: Next map advertisement display mode: CHAT TEXT");
		}
	}
}

//Callback function for the interval that controls the timer that advertises ACS and the next map
public CVarChange_NewMapAdInterval(Handle:hCVar, const String:strOldValue[], const String:strNewValue[])
{
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false) == true)
		return;
	
	//Get the new value
	new Float:fDelayTime = StringToFloat(strNewValue);
	
	//If the value was changed, then set it and display a message to the server and players
	if (fDelayTime > 60.0)
	{
		g_fNextMapAdInterval = fDelayTime;
		PrintToServer("[ACS] ConVar changed: Next map advertisement interval changed to %f", fDelayTime);
		PrintToChatAll("[ACS] ConVar changed: Next map advertisement interval changed to %f", fDelayTime);
	}
	else
	{
		g_fNextMapAdInterval = 60.0;
		PrintToServer("[ACS] ConVar changed: Next map advertisement interval changed to 60.0");
		PrintToChatAll("[ACS] ConVar changed: Next map advertisement interval changed to 60.0");
	}
}

//Callback function for the amount of times the survivors can fail a coop finale map before ACS switches
public CVarChange_MaxFinaleFailures(Handle:hCVar, const String:strOldValue[], const String:strNewValue[])
{
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue, false) == true)
		return;
	
	//Get the new value
	new iMaxFailures = StringToInt(strNewValue);
	
	//If the value was changed, then set it and display a message to the server and players
	if (iMaxFailures > 0)
	{
		g_iMaxCoopFinaleFailures = iMaxFailures;
		PrintToServer("[ACS] ConVar changed: Max Coop finale failures changed to %f", iMaxFailures);
		PrintToChatAll("[ACS] ConVar changed: Max Coop finale failures changed to %f", iMaxFailures);
	}
	else
	{
		g_iMaxCoopFinaleFailures = 0;
		PrintToServer("[ACS] ConVar changed: Max Coop finale failures changed to 0");
		PrintToChatAll("[ACS] ConVar changed: Max Coop finale failures changed to 0");
	}
}
/*======================================================================================
#################                     E V E N T S                      #################
======================================================================================*/

public OnMapStart()
{
	//Execute config file
	decl String:strFileName[64];
	Format(strFileName, sizeof(strFileName), "Automatic_Campaign_Switcher_%s", PLUGIN_VERSION);
	AutoExecConfig(true, strFileName);
	
	//Set all the menu handles to invalid
	CleanUpMenuHandles();
	
	//Set the game mode
	FindGameMode();
	
	//Precache sounds
	PrecacheSound(SOUND_NEW_VOTE_START);
	PrecacheSound(SOUND_NEW_VOTE_WINNER);
	
	
	//Display advertising for the next campaign or map
	if(g_iNextMapAdDisplayMode != DISPLAY_MODE_DISABLED)
		CreateTimer(g_fNextMapAdInterval, Timer_AdvertiseNextMap, _, TIMER_FLAG_NO_MAPCHANGE);
	
	g_iRoundEndCounter = 0;			//Reset the round end counter on every map start
	g_iCoopFinaleFailureCount = 0;	//Reset the amount of Survivor failures
	g_bFinaleWon = false;			//Reset the finale won variable
	ResetAllVotes();				//Reset every player's vote
}

//Event fired when the Survivors leave the start area
public Action:Event_PlayerLeftStartArea(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{		
	if(g_bVotingEnabled == true && OnFinaleOrScavengeMap() == true)
		CreateTimer(g_fVotingAdDelayTime, Timer_DisplayVoteAdToAll, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

//Event fired when the Round Ends
public Action:Event_RoundEnd(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	// PrintToChatAll("\x03[ACS]\x04 Event_RoundEnd");
	//Check to see if on a finale map, if so change to the next campaign after two rounds
	if(g_iGameMode == GAMEMODE_VERSUS && OnFinaleOrScavengeMap() == true)
	{
		g_iRoundEndCounter++;
		
		if(g_iRoundEndCounter >= 4)	//This event must be fired on the fourth time Round End occurs.
			CheckMapForChange();	//This is because it fires twice during each round end for
									//some strange reason, and versus has two rounds in it.
	}
	//If in Coop and on a finale, check to see if the surviors have lost the max amount of times
	else if(g_iGameMode == GAMEMODE_COOP && OnFinaleOrScavengeMap() == true &&
			g_iMaxCoopFinaleFailures > 0 && g_bFinaleWon == false &&
			++g_iCoopFinaleFailureCount >= g_iMaxCoopFinaleFailures)
	{
		CheckMapForChange();
	}
	
	return Plugin_Continue;
}

//Event fired when a finale is won
public Action:Event_FinaleWin(Handle:hEvent, const String:strName[], bool:bDontBroadcast) {
	// PrintToChatAll("\x03[ACS]\x04 Event_FinaleWin");
	g_bFinaleWon = true;	//This is used so that the finale does not switch twice if this event
							//happens to land on a max failure count as well as this
	
	//Change to the next campaign
	if(g_iGameMode == GAMEMODE_COOP)
		CheckMapForChange();
	
	return Plugin_Continue;
}

//Event fired when a map is finished for scavenge
public Action:Event_ScavengeMapFinished(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	//Change to the next Scavenge map
	if(g_iGameMode == GAMEMODE_SCAVENGE)
		ChangeScavengeMap();
	
	return Plugin_Continue;
}

//Event fired when a player disconnects from the server
public Action:Event_PlayerDisconnect(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient	< 1)
		return Plugin_Continue;
	
	//Reset the client's votes
	g_bClientVoted[iClient] = false;
	g_iClientVote[iClient] = -1;
	
	//Check to see if there is a new vote winner
	SetTheCurrentVoteWinner();
	
	return Plugin_Continue;
}

/*======================================================================================
#################              F I N D   G A M E   M O D E             #################
======================================================================================*/

//Find the current gamemode and store it into this plugin
FindGameMode()
{
	//Get the gamemode string from the game
	decl String:strGameMode[20];
	GetConVarString(FindConVar("mp_gamemode"), strGameMode, sizeof(strGameMode));
	
	//Set the global gamemode int for this plugin
	if(StrEqual(strGameMode, "coop", false))
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "realism", false))
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode,"versus", false))
		g_iGameMode = GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "teamversus", false))
		g_iGameMode = GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "scavenge", false))
		g_iGameMode = GAMEMODE_SCAVENGE;
	else if(StrEqual(strGameMode, "teamscavenge", false))
		g_iGameMode = GAMEMODE_SCAVENGE;
	else if(StrEqual(strGameMode, "survival", false))
		g_iGameMode = GAMEMODE_SURVIVAL;
	else if(StrEqual(strGameMode, "mutation1", false))		//Last Man On Earth
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation2", false))		//Headshot!
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation3", false))		//Bleed Out
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation4", false))		//Hard Eight
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation5", false))		//Four Swordsmen
		g_iGameMode = GAMEMODE_COOP;
	//else if(StrEqual(strGameMode, "mutation6", false))	//Nothing here
	//	g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation7", false))		//Chainsaw Massacre
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation8", false))		//Ironman
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation9", false))		//Last Gnome On Earth
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation10", false))	//Room For One
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation11", false))	//Healthpackalypse!
		g_iGameMode = GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "mutation12", false))	//Realism Versus
		g_iGameMode = GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "mutation13", false))	//Follow the Liter
		g_iGameMode = GAMEMODE_SCAVENGE;
	else if(StrEqual(strGameMode, "mutation14", false))	//Gib Fest
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation15", false))	//Versus Survival
		g_iGameMode = GAMEMODE_SURVIVAL;
	else if(StrEqual(strGameMode, "mutation16", false))	//Hunting Party
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation17", false))	//Lone Gunman
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation18", false))	//Bleed Out Versus
		g_iGameMode = GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "mutation19", false))	//Taaannnkk!
		g_iGameMode = GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "mutation20", false))	//Healing Gnome
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "community1", false))	//Special Delivery
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "community2", false))	//Flu Season
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "community3", false))	//Riding My Survivor
		g_iGameMode = GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "community4", false))	//Nightmare
		g_iGameMode = GAMEMODE_SURVIVAL;
	else if(StrEqual(strGameMode, "community5", false))	//Death's Door
		g_iGameMode = GAMEMODE_COOP;
	else
		g_iGameMode = GAMEMODE_UNKNOWN;
}

/*======================================================================================
#################             A C S   C H A N G E   M A P              #################
======================================================================================*/

//Check to see if the current map is a finale, and if so, switch to the next campaign
CheckMapForChange()
{
	decl String:strCurrentMap[LEN_MAPFILE];
	GetCurrentMap(strCurrentMap,LEN_MAPFILE);					//Get the current map from the game

	for(new iMapIndex = 0; iMapIndex < getNumberOfCampaign(); iMapIndex++)
	{
		if(StrEqual(strCurrentMap, getCampaignLastMap(iMapIndex), false) == true)
		{
			char mapName[LEN_MAPNAME];
			getCampaignName(iMapIndex, mapName);
			
			PrintToChatAll("\x03[ACS] \x05 %t: \x04%s", "Campaign finished", mapName);
			//Check to see if someone voted for a campaign, if so, then change to the winning campaign
			if(g_bVotingEnabled == true && g_iWinningMapVotes > 0 && g_iWinningMapIndex >= 0)
			{
				if(IsMapValid(getCampaignFirstMap(g_iWinningMapIndex)) == true) {
					getCampaignName(g_iWinningMapIndex, mapName);
					PrintToChatAll("\x03[ACS] \x05%t: \x04%s", "Switching map to the vote winner", mapName);
					
					if(g_iGameMode == GAMEMODE_VERSUS)
						CreateTimer(WAIT_TIME_BEFORE_SWITCH_VERSUS, Timer_ChangeCampaign, g_iWinningMapIndex);
					else if(g_iGameMode == GAMEMODE_COOP)
						CreateTimer(WAIT_TIME_BEFORE_SWITCH_COOP, Timer_ChangeCampaign, g_iWinningMapIndex);
					
					return;
				}
				else
					LogError("Error: %s is an invalid map name, attempting normal map rotation.", getCampaignFirstMap(g_iWinningMapIndex));
			}
			
			//If no map was chosen in the vote, then go with the automatic map rotation
			
			if(iMapIndex >= numberOfCyclingCampaignMap - 1)	//Check to see if it reaches/exceed the end of official map list
				iMapIndex = -1;							//If so, start the array over by setting to -1 + 1 = 0
				
			if(IsMapValid(getCampaignFirstMap(iMapIndex + 1)) == true) {
				getCampaignName(iMapIndex + 1, mapName);
				PrintToChatAll("\x03[ACS] \x05 %t: \x04%s", "Switching campaign to", mapName);
				
				if(g_iGameMode == GAMEMODE_VERSUS)
					CreateTimer(WAIT_TIME_BEFORE_SWITCH_VERSUS, Timer_ChangeCampaign, iMapIndex + 1);
				else if(g_iGameMode == GAMEMODE_COOP)
					CreateTimer(WAIT_TIME_BEFORE_SWITCH_COOP, Timer_ChangeCampaign, iMapIndex + 1);
			}
			else
				LogError("Error: %s is an invalid map name, unable to switch map.", getCampaignFirstMap(iMapIndex + 1));
			
			return;
		}
	}
}

//Change to the next scavenge map
ChangeScavengeMap()
{
	//Check to see if someone voted for a map, if so, then change to the winning map
	if(g_bVotingEnabled == true && g_iWinningMapVotes > 0 && g_iWinningMapIndex >= 0)
	{
		if(IsMapValid(getScavengeMap(g_iWinningMapIndex)) == true) {
			PrintToChatAll("\x03[ACS] \x05%t: \x04%s", "Switching map to the vote winner", getScavengeName(g_iWinningMapIndex));
			
			CreateTimer(WAIT_TIME_BEFORE_SWITCH_SCAVENGE, Timer_ChangeScavengeMap, g_iWinningMapIndex);
			
			return;
		}
		else
			LogError("Error: %s is an invalid map name, attempting normal map rotation.", getScavengeMap(g_iWinningMapIndex));
	}
	
	//If no map was chosen in the vote, then go with the automatic map rotation
	
	decl String:strCurrentMap[LEN_MAPFILE];
	GetCurrentMap(strCurrentMap, LEN_MAPFILE);					//Get the current map from the game
	
	//Go through all maps and to find which map index it is on, and then switch to the next map
	for(new iMapIndex = 0; iMapIndex < getNumberOfScavengeMap(); iMapIndex++)
	{
		if(StrEqual(strCurrentMap, getScavengeMap(iMapIndex), false) == true)
		{
			if(iMapIndex >= numberOfCyclingScavengeMap - 1)//Check to see if its the end of the array
				iMapIndex = -1;							//If so, start the array over by setting to -1 + 1 = 0 
			
			//Make sure the map is valid before changing and displaying the message
			if(IsMapValid(getScavengeMap(iMapIndex + 1)) == true) {
				PrintToChatAll("\x03[ACS] \x05 %t: \x04%s", "Switching campaign to", getScavengeName(iMapIndex + 1));
				
				CreateTimer(WAIT_TIME_BEFORE_SWITCH_SCAVENGE, Timer_ChangeScavengeMap, iMapIndex + 1);
			}
			else
				LogError("Error: %s is an invalid map name, unable to switch map.", getScavengeMap(iMapIndex + 1));
			
			return;
		}
	}
}

//Change campaign to its index
public Action:Timer_ChangeCampaign(Handle:timer, any:iCampaignIndex)
{
	ServerCommand("changelevel %s", getCampaignFirstMap(iCampaignIndex));	//Change the campaign
	
	return Plugin_Stop;
}

//Change scavenge map to its index
public Action:Timer_ChangeScavengeMap(Handle:timer, any:iMapIndex)
{
	ServerCommand("changelevel %s", getScavengeMap(iMapIndex));			//Change the map
	
	return Plugin_Stop;
}

/*======================================================================================
#################            A C S   A D V E R T I S I N G             #################
======================================================================================*/

public Action:Timer_AdvertiseNextMap(Handle:timer, any:iMapIndex)
{
	//If next map advertising is enabled, display the text and start the timer again
	if(g_iNextMapAdDisplayMode != DISPLAY_MODE_DISABLED)
	{
		DisplayNextMapToAll();
		CreateTimer(g_fNextMapAdInterval, Timer_AdvertiseNextMap, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

DisplayNextMapToAll() {
	char mapName[LEN_MAPNAME];
	//If there is a winner to the vote display the winner if not display the next map in rotation
	if(g_iWinningMapIndex >= 0) {
		if(g_iNextMapAdDisplayMode == DISPLAY_MODE_HINT) {		
			//Display the map that is currently winning the vote to all the players using hint text
			if(g_iGameMode == GAMEMODE_SCAVENGE) {
				PrintHintTextToAll("The next map is currently %s", getScavengeName(g_iWinningMapIndex));
			} else {
				getCampaignName(g_iWinningMapIndex, mapName);
				PrintHintTextToAll("The next campaign is currently %s", mapName);
			}
		} else if(g_iNextMapAdDisplayMode == DISPLAY_MODE_CHAT)	{
			//Display the map that is currently winning the vote to all the players using chat text
			if(g_iGameMode == GAMEMODE_SCAVENGE) {
				PrintToChatAll("\x03[ACS] \x05The next map is currently \x04%s", getScavengeName(g_iWinningMapIndex));
			} else {
				getCampaignName(g_iWinningMapIndex, mapName);
				PrintToChatAll("\x03[ACS] \x05The next campaign is currently \x04%s", mapName);
			}
		}
	} else {
		decl String:strCurrentMap[LEN_MAPFILE];
		GetCurrentMap(strCurrentMap, LEN_MAPFILE);					//Get the current map from the game
		
		if(g_iGameMode == GAMEMODE_SCAVENGE)
		{
			//Go through all maps and to find which map index it is on, and then switch to the next map
			for(new iMapIndex = 0; iMapIndex < getNumberOfScavengeMap(); iMapIndex++)
			{
				if(StrEqual(strCurrentMap, getScavengeMap(iMapIndex), false) == true)
				{
					if(iMapIndex == getNumberOfScavengeMap() - 1)	//Check to see if its the end of the array
						iMapIndex = -1;								//If so, start the array over by setting to -1 + 1 = 0
					
					//Display the next map in the rotation in the appropriate way
					if(g_iNextMapAdDisplayMode == DISPLAY_MODE_HINT)
						PrintHintTextToAll("The next map is currently %s", getScavengeName(iMapIndex + 1));
					else if(g_iNextMapAdDisplayMode == DISPLAY_MODE_CHAT)
						PrintToChatAll("\x03[ACS] \x05The next map is currently \x04%s", getScavengeName(iMapIndex + 1));
				}
			}
		}
		else
		{
			//Go through all maps and to find which map index it is on, and then switch to the next map
			for(new iMapIndex = 0; iMapIndex < getNumberOfCampaign(); iMapIndex++)
			{
				if(StrEqual(strCurrentMap, getCampaignLastMap(iMapIndex), false) == true)
				{
					if(iMapIndex == getNumberOfCampaign() - 1)	//Check to see if its the end of the array
						iMapIndex = -1;							//If so, start the array over by setting to -1 + 1 = 0
					
					//Display the next map in the rotation in the appropriate way
					getCampaignName(iMapIndex + 1, mapName);
					if(g_iNextMapAdDisplayMode == DISPLAY_MODE_HINT)
						PrintHintTextToAll("The next campaign is currently %s", mapName);
					else if(g_iNextMapAdDisplayMode == DISPLAY_MODE_CHAT)
						PrintToChatAll("\x03[ACS] \x05The next campaign is currently \x04%s", mapName);
				}
			}
		}
	}
}

/*======================================================================================
#################              V O T I N G   S Y S T E M               #################
======================================================================================*/

/*======================================================================================
################             P L A Y E R   C O M M A N D S              ################
======================================================================================*/

//Command that a player can use to vote/revote for a map/campaign
public Action:MapVote(iClient, args)
{
	if(g_bVotingEnabled == false)
	{
		PrintToChat(iClient, "\x03[ACS] \x05Voting has been disabled on this server.");
		return;
	}
	
	if(OnFinaleOrScavengeMap() == false)
	{
		PrintToChat(iClient, "\x03[ACS] \x05Voting is only enabled on a Scavenge or finale map.");
		return;
	}
	
	//Open the vote menu for the client if they arent using the server console
	if(iClient < 1)
		PrintToServer("You cannot vote for a map from the server console, use the in-game chat");
	else
		VoteMenuDraw(iClient);
}

//Command that a player can use to see the total votes for all maps/campaigns
public Action:DisplayCurrentVotes(iClient, args) {
	char mapName[LEN_MAPNAME];
	if(g_bVotingEnabled == false)
	{
		ReplyToCommand(iClient, "\x03[ACS] \x05Voting has been disabled on this server.");
		return;
	}
	
	if(OnFinaleOrScavengeMap() == false)
	{
		ReplyToCommand(iClient, "\x03[ACS] \x05Voting is only enabled on a Scavenge or finale map.");
		return;
	}
	
	decl iPlayer, iMap, iNumberOfMaps;
	
	//Get the total number of maps for the current game mode
	if(g_iGameMode == GAMEMODE_SCAVENGE)
		iNumberOfMaps = getNumberOfScavengeMap();
	else
		iNumberOfMaps = getNumberOfCampaign();
		
	//Display to the client the current winning map
	if(g_iWinningMapIndex != -1) {
		if(g_iGameMode == GAMEMODE_SCAVENGE) {
			ReplyToCommand(iClient, "\x03[ACS] \x05Currently winning the vote: \x04%s", getScavengeName(g_iWinningMapIndex));
		} else {
			getCampaignName(g_iWinningMapIndex, mapName);
			ReplyToCommand(iClient, "\x03[ACS] \x05Currently winning the vote: \x04%s", mapName);
		}
	}
	else
		ReplyToCommand(iClient, "\x03[ACS] \x05No one has voted yet.");
	
	//Loop through all maps and display the ones that have votes
	new iMapVotes[iNumberOfMaps];
	
	for(iMap = 0; iMap < iNumberOfMaps; iMap++)
	{
		iMapVotes[iMap] = 0;
		
		//Tally votes for the current map
		for(iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			if(g_iClientVote[iPlayer] == iMap)
				iMapVotes[iMap]++;
		
		//Display this particular map and its amount of votes it has to the client
		if(iMapVotes[iMap] > 0)
		{
			if(g_iGameMode == GAMEMODE_SCAVENGE) {
				ReplyToCommand(iClient, "\x04          %s: \x05%d votes", getScavengeName(iMap), iMapVotes[iMap]);
			} else {
				getCampaignName(iMap, mapName);
				ReplyToCommand(iClient, "\x04          %s: \x05%d votes", mapName, iMapVotes[iMap]);
			}
				
		}
	}
}

/*======================================================================================
###############                   V O T E   M E N U                       ##############
======================================================================================*/

//Timer to show the menu to the players if they have not voted yet
public Action:Timer_DisplayVoteAdToAll(Handle:hTimer, any:iData)
{
	if(g_bVotingEnabled == false || OnFinaleOrScavengeMap() == false)
		return Plugin_Stop;
	
	for(new iClient = 1;iClient <= MaxClients; iClient++)
	{
		if(g_bClientShownVoteAd[iClient] == false && g_bClientVoted[iClient] == false && IsClientInGame(iClient) == true && IsFakeClient(iClient) == false)
		{
			switch(g_iVotingAdDisplayMode)
			{
				case DISPLAY_MODE_MENU: VoteMenuDraw(iClient);
				case DISPLAY_MODE_HINT: PrintHintText(iClient, "To vote for the next map, type: !mapvote\nTo see all the votes, type: !mapvotes");
				case DISPLAY_MODE_CHAT: PrintToChat(iClient, "\x03[ACS] \x05To vote for the next map, type: \x04!mapvote\n           \x05To see all the votes, type: \x04!mapvotes");
			}
			
			g_bClientShownVoteAd[iClient] = true;
		}
	}
	
	return Plugin_Stop;
}

//Draw the menu for voting
public Action:VoteMenuDraw(iClient)
{
	if(iClient < 1 || IsClientInGame(iClient) == false || IsFakeClient(iClient) == true)
		return Plugin_Handled;
	
	//Create the menu
	g_hMenu_Vote[iClient] = CreateMenu(VoteMenuHandler);
	
	//Give the player the option of not choosing a map
	AddMenuItem(g_hMenu_Vote[iClient], "option1", "I Don't Care");
	
	//Populate the menu with the maps in rotation for the corresponding game mode
	if(g_iGameMode == GAMEMODE_SCAVENGE)
	{
		SetMenuTitle(g_hMenu_Vote[iClient], "Vote for the next map\n ");

		for(new iCampaign = 0; iCampaign < getNumberOfScavengeMap(); iCampaign++)
			AddMenuItem(g_hMenu_Vote[iClient], getScavengeName(iCampaign), getScavengeName(iCampaign));
	}
	else
	{
		SetMenuTitle(g_hMenu_Vote[iClient], "Vote for the next campaign\n ");

		for(new iCampaign = 0; iCampaign < getNumberOfCampaign(); iCampaign++) {
			char mapName[LEN_MAPNAME];
			getCampaignName(iCampaign, mapName);
			AddMenuItem(g_hMenu_Vote[iClient], mapName, mapName);
		}
	}
	
	//Add an exit button
	SetMenuExitButton(g_hMenu_Vote[iClient], true);
	
	//And finally, show the menu to the client
	DisplayMenu(g_hMenu_Vote[iClient], iClient, MENU_TIME_FOREVER);
	
	//Play a sound to indicate that the user can vote on a map
	EmitSoundToClient(iClient, SOUND_NEW_VOTE_START);
	
	return Plugin_Handled;
}

//Handle the menu selection the client chose for voting
public VoteMenuHandler(Handle:hMenu, MenuAction:maAction, iClient, iItemNum)
{
	if(maAction == MenuAction_Select) 
	{
		g_bClientVoted[iClient] = true;
		
		//Set the players current vote
		if(iItemNum == 0)
			g_iClientVote[iClient] = -1;
		else
			g_iClientVote[iClient] = iItemNum - 1;
			
		//Check to see if theres a new winner to the vote
		SetTheCurrentVoteWinner();
		
		//Display the appropriate message to the voter
		char mapName[LEN_MAPNAME];
		if(iItemNum == 0) {
			PrintHintText(iClient, "You did not vote.\nTo vote, type: !mapvote");
		} else if(g_iGameMode == GAMEMODE_SCAVENGE) {
			PrintHintText(iClient, "You voted for %s.\n- To change your vote, type: !mapvote\n- To see all the votes, type: !mapvotes", getScavengeName(iItemNum - 1));
		} else {
			getCampaignName(iItemNum - 1, mapName);
			PrintHintText(iClient, "You voted for %s.\n- To change your vote, type: !mapvote\n- To see all the votes, type: !mapvotes", mapName);
		}
			
	}
}

//Resets all the menu handles to invalid for every player, until they need it again
CleanUpMenuHandles()
{
	for(new iClient = 0; iClient <= MAXPLAYERS; iClient++)
	{
		if(g_hMenu_Vote[iClient] != INVALID_HANDLE)
		{
			CloseHandle(g_hMenu_Vote[iClient]);
			g_hMenu_Vote[iClient] = INVALID_HANDLE;
		}
	}
}

/*======================================================================================
#########       M I S C E L L A N E O U S   V O T E   F U N C T I O N S        #########
======================================================================================*/

//Resets all the votes for every player
ResetAllVotes()
{
	for(new iClient = 1; iClient <= MaxClients; iClient++)
	{
		g_bClientVoted[iClient] = false;
		g_iClientVote[iClient] = -1;
		
		//Reset so that the player can see the advertisement
		g_bClientShownVoteAd[iClient] = false;
	}
	
	//Reset the winning map to NULL
	g_iWinningMapIndex = -1;
	g_iWinningMapVotes = 0;
}

//Tally up all the votes and set the current winner
SetTheCurrentVoteWinner()
{
	decl iPlayer, iMap, iNumberOfMaps;
	
	//Store the current winnder to see if there is a change
	new iOldWinningMapIndex = g_iWinningMapIndex;
	
	//Get the total number of maps for the current game mode
	if(g_iGameMode == GAMEMODE_SCAVENGE)
		iNumberOfMaps = getNumberOfScavengeMap();
	else
		iNumberOfMaps = getNumberOfCampaign();
	
	//Loop through all maps and get the highest voted map	
	new iMapVotes[iNumberOfMaps], iCurrentlyWinningMapVoteCounts = 0, bool:bSomeoneHasVoted = false;
	
	for(iMap = 0; iMap < iNumberOfMaps; iMap++)
	{
		iMapVotes[iMap] = 0;
		
		//Tally votes for the current map
		for(iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			if(g_iClientVote[iPlayer] == iMap)
				iMapVotes[iMap]++;
		
		//Check if there is at least one vote, if so set the bSomeoneHasVoted to true
		if(bSomeoneHasVoted == false && iMapVotes[iMap] > 0)
			bSomeoneHasVoted = true;
		
		//Check if the current map has more votes than the currently highest voted map
		if(iMapVotes[iMap] > iCurrentlyWinningMapVoteCounts)
		{
			iCurrentlyWinningMapVoteCounts = iMapVotes[iMap];
			
			g_iWinningMapIndex = iMap;
			g_iWinningMapVotes = iMapVotes[iMap];
		}
	}
	
	//If no one has voted, reset the winning map index and votes
	//This is only for if someone votes then their vote is removed
	if(bSomeoneHasVoted == false)
	{
		g_iWinningMapIndex = -1;
		g_iWinningMapVotes = 0;
	}
	
	//If the vote winner has changed then display the new winner to all the players
	if(g_iWinningMapIndex > -1 && iOldWinningMapIndex != g_iWinningMapIndex)
	{
		//Send sound notification to all players
		if(g_bVoteWinnerSoundEnabled == true)
			for(iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
				if(IsClientInGame(iPlayer) == true && IsFakeClient(iPlayer) == false)
					EmitSoundToClient(iPlayer, SOUND_NEW_VOTE_WINNER);
		
		char mapName[LEN_MAPNAME];
		//Show message to all the players of the new vote winner
		if(g_iGameMode == GAMEMODE_SCAVENGE) {
			PrintToChatAll("\x03[ACS] \x04%s \x05is now winning the vote.", getScavengeName(g_iWinningMapIndex));
		} else {
			getCampaignName(g_iWinningMapIndex, mapName);
			PrintToChatAll("\x03[ACS] \x04%s \x05is now winning the vote.", mapName);
		}
	}
}

//Check if the current map is the last in the campaign if not in the Scavenge game mode
bool:OnFinaleOrScavengeMap()
{
	if(g_iGameMode == GAMEMODE_SCAVENGE)
		return true;
	
	if(g_iGameMode == GAMEMODE_SURVIVAL)
		return false;
	
	decl String:strCurrentMap[LEN_MAPFILE];
	GetCurrentMap(strCurrentMap, LEN_MAPFILE);			//Get the current map from the game
	
	//Run through all the maps, if the current map is a last campaign map, return true
	for(new iMapIndex = 0; iMapIndex < getNumberOfCampaign(); iMapIndex++)
		if(StrEqual(strCurrentMap, getCampaignLastMap(iMapIndex), false) == true)
			return true;
	
	return false;
}

/*======================================================================================
##########                                 Map Votes                        ###########
======================================================================================*/
BuildVoteCampaignMenu() {
	//Create the menu
	g_hMenu_VoteCampaign = CreateMenu(VoteCampaignMenuHandler);
	
	//Populate the menu with the maps in rotation for the corresponding game mode
	SetMenuTitle(g_hMenu_VoteCampaign, "%t", "Choose a Map");
	
	char mapName[LEN_MAPNAME];
	for(new iCampaign = 0; iCampaign < getNumberOfCampaign(); iCampaign++) {
		getCampaignName(iCampaign, mapName);
		AddMenuItem(g_hMenu_VoteCampaign, getCampaignFirstMap(iCampaign), mapName);
	}
	
	//Add an exit button
	SetMenuExitButton(g_hMenu_VoteCampaign, true);
}

public Action:Command_ChangeMapVote(iClient, args) {
	if(iClient < 1 || IsClientInGame(iClient) == false || IsFakeClient(iClient) == true)
		return Plugin_Handled;
	
	//And finally, show the menu to the client
	DisplayMenu(g_hMenu_VoteCampaign, iClient, MENU_TIME_FOREVER);
	
	//Play a sound to indicate that the user can vote on a map
	EmitSoundToClient(iClient, SOUND_NEW_VOTE_START);
	
	return Plugin_Handled;	
}

#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"
Menu g_hVoteMenu = null;
public int Handler_VoteCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_End) {
		delete g_hVoteMenu;
	} else if (action == MenuAction_Display) {
		// Localize title
		char title[64];
		menu.GetTitle(title, sizeof(title));
			
	 	char buffer[255];
		Format(buffer, sizeof(buffer), "%T", "Change Map To", param1, title);

		Panel panel = view_as<Panel>(param2);
		panel.SetTitle(buffer);
	} else if (action == MenuAction_DisplayItem) {
		char display[64];
		menu.GetItem(param2, "", 0, _, display, sizeof(display));
	 
	 	if (strcmp(display, "No") == 0 || strcmp(display, "Yes") == 0)
	 	{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%T", display, param1);

			return RedrawMenuItem(buffer);
		}
	} else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes) {
		PrintToChatAll("[SM] %t", "No Votes Cast");
	} else if (action == MenuAction_VoteEnd) {
		char item[64], display[64];
		float percent, limit;
		int votes, totalVotes;

		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
		
		if (strcmp(item, VOTE_NO) == 0 && param1 == 1) {
			votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
		}
		
		percent = float(votes) / float(totalVotes);
		
		ConVar limitConVar = FindConVar("sm_vote_map");
		if (limitConVar == null) {
			limit = 0.6;
		} else {
			limit = limitConVar.FloatValue;
		}
		
		// A multi-argument vote is "always successful", but have to check if its a Yes/No vote.
		if (strcmp(item, VOTE_NO) == 0 && param1 == 1) {
			LogAction(-1, -1, "Vote failed.");
			PrintToChatAll("[SM] %t", "Vote Failed", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		} else {
			PrintToChatAll("[SM] %t", "Vote Successful", RoundToNearest(100.0*percent), totalVotes);
			PrintToChatAll("[SM] %t", "Changing map", item);
			DataPack dp;
			CreateDataTimer(5.0, Timer_ChangeMap, dp);
			dp.WriteString(item);
		}
	}
	
	return 0;
}

InitVote(char[] map, char[] displayName) {
	g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	
	g_hVoteMenu.SetTitle("%s", displayName);
	g_hVoteMenu.AddItem(map, "Yes");
	g_hVoteMenu.AddItem(VOTE_NO, "No");
	g_hVoteMenu.ExitButton = false;
	g_hVoteMenu.DisplayVoteToAll(20);	
}

public Action Timer_ChangeMap(Handle timer, DataPack dp) {
	char mapname[LEN_MAPFILE];
	
	dp.Reset();
	dp.ReadString(mapname, LEN_MAPFILE);
	
	ForceChangeLevel(mapname, "sm_votemap Result");
	
	return Plugin_Stop;
}

public int VoteCampaignMenuHandler(Menu menu, MenuAction action, int client, int iItemNum) {
	// Change the map to the selected item.
	if(action == MenuAction_Select)	{
		// decl String:map[64];
		// decl String:displayName[64];
		// int style;
		// GetMenuItem(hMenu, iItemNum, map, sizeof(map), style, displayName, sizeof(displayName));

		char mapName[LEN_MAPNAME];
		getCampaignName(iItemNum, mapName);
		
		switch (GetConVarInt(g_hCVar_ChMapAnnounceMode)) {
			case 1: 
			{
				PrintToChatAll("\x05[SM] \x04 %t : \x05 %s", "Voting for map", mapName);
			}
			case 2: 
			{
				PrintHintTextToAll("\x05[SM] \x04 %t : \x05 %s", "Voting for map", mapName);
			}
			case 3: 
			{
				PrintToChatAll("\x05[SM] \x04 %t : \x05 %s", "Voting for map", mapName);
				PrintHintTextToAll("\x05[SM] \x04 %t : \x05 %s", "Voting for map", mapName);
			}
			default: 
			{
				// Nothing to display
			}
		}
		
		if (IsVoteInProgress()) {
			ReplyToCommand(client, "[SM] %t", "Vote in Progress");
			return 0;
		} else {
			InitVote(getCampaignFirstMap(iItemNum), mapName);
			// ServerCommand("sm_votemap %s", getCampaignFirstMap(iItemNum));
		}	
	}
	
	return 0;
}

public Action:Command_MapList(iClient, args) {
	char mapName[LEN_MAPNAME];
	for(new iCampaign = 0; iCampaign < getNumberOfCampaign(); iCampaign++) {
		getCampaignName(iCampaign, mapName);
		ReplyToCommand(iClient, "%d.%s -> %s = %s", iCampaign + 1, getCampaignFirstMap(iCampaign), getCampaignLastMap(iCampaign), mapName);
	}

	return Plugin_Handled;	
}