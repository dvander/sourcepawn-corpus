#include <sourcemod>
#include <sdktools>
#include "left4downtown.inc"

#pragma semicolon 1

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define PLUGIN_VERSION "2.3"
#define PLUGIN_TAG "[L4D1Score]"

#define DEBUG_ENABLE 0
#define DEBUG_LOGFILE "l4d1_down_debug.txt"

#define GAMEDATA_SOURCE "l4d2_versus_score_system_gamedata"
#define MAP_MULTIPLIER_SOURCE "../../cfg/sourcemod/l4d2_versus_score_system_map_multiplier.txt"

#define OFFSET_CAMPAIGN_SCORE 1
#define OFFSET_ROUND_SCORE 3
#define OFFSET_INFECTED_ROUND_SCORE 5
#define OFFSET_SURVIVOR_DISTANCE 21
#define OFFSET_SURVIVOR_DEATH_DISTANCE 29
#define OFFSET_SURVIVOR_COUNT 39
#define OFFSET_ACTUAL_TEAM 62
#define OFFSET_MAX_DISTANCE 64

#define SURVIVOR_INCAP_HEALTH 30.0

#define TEAM_A 0
#define TEAM_B 1

/*
Game: Left 4 Dead 2
Plugin: L4D1 Versus Score
Description: This plugin edits the survivor bonus and calculates it after the formula of Left 4 Dead 1. Medkits, pills and shots are important again!
Creator: Die Teetasse

###########

Dependencies:
- Sourcemod 1.4 development
- Left 4 Downtown v0.4.6 (https://forums.alliedmods.net/showthread.php?t=91132)
- cfg/sourcemod/l4d2_versus_score_system_map_multiplier.txt file
- addons/sourcemod/gamedata/l4d2_versus_score_system_gamedata.txt

###########

Installation:
- install Left 4 Downtown v0.4.6
- copy l4d2_versus_score_system_map_multiplier.txt to cfg/sourcemod
- copy l4d2_versus_score_system_complete.smx to addons/sourcemod/plugins
- copy l4d2_versus_score_system_gamedata.txt to addons/sourcemod/gamedata

###########

Cvars:
l4d2_l4d1vs_version "2.3" 							//Version number
l4d2_l4d1vs_enable "1" 								//Enabling/disabling score system
l4d2_l4d1vs_defib_multiplier "0.5"					//Multiplier for the restored health of a defib unit (0 for disabling)
l4d2_l4d1vs_map_multiplier_enable "1" 				//Enable/disable map multiplier on score
l4d2_l4d1vs_checkpoint_health_remover_enable "1"	//Enable/disable removing of health items in the checkpoint room
l4d2_l4d1vs_score_display "2"						//Score display mode (0 = chat, 1 = motd, 2 = both)
l4d2_l4d1vs_welcome_msg_enable "1"					//Enable/disable welcome message while joining

###########

Todo:
- tie breaker -> infected damage decides (?)

###########

Known Bugs / Incompatibilites:
- NO support for 8+ clients server

###########

History:
v2.3:
- use of an own gamedata file (thx AtomicStryker)
- hide scoreboard at round end
- added cvar to change score display mode
- added score output for first round team on second half
- dynamic roundscore array 
	--> support for 5+ maps campaigns
- simplified score output and motd
--> need Sourcemod 1.4 dev!

v2.2:
- fixed passing update break
- simplified some functions
- deleted old code
- support for custom maps added
- incapped survivor will be counted with 30 temphhp and their items (except for final)

v2.1:
- added another function and renamend an old one (GetSurvivorDistance and GetSurvivorDistancePoints)
- fixed bug, that distance points instead of the distance in percentage would be displayed
- fixed incompatibility for L4D2 Team Manager (thx AtomicStryker)

v2.0:
- changed complete system to implement an 100% score system via downtowns extension
	--> more than 8 people server are not supported anymore!
- deleted cvars: l4d2_l4d1vs_score_multiplier, l4d2_l4d1vs_map_multiplier_enable
- added chat command: !score for displaying round and campaign scores
- fixed bug, where every chatinput was blocked
- fixed bug, where on second half the health items were not removed
- fixed bug, where plugin was not loaded on versusmode
- fixed themphealth calculation bug
- changed final recognition (custon map +)
- added map multiplier configuration over data file (custom map +)
- fixed bug, where non health items were removed
- fixed bug, where first team didnt get a score
- added motd output to overlay 'real' score

v1.4:
- added gamecheck
- renamed file

v1.3:
- added cvar: l4d2_l4d1vs_checkpoint_health_remover_enable
- added values for each checkpoint room to get the distance (need a system for custom maps)
- fixed activiation in other gamemodes
- fixed error try to unhook without any hook
- fixed no medkit deletion if gamemode was before other than versus

v1.2:
- added cvar: l4d2_l4d1vs_welcome_msg_enable
- fixed StrContains use

- first attemp of adding an search system to find a (4) medkit staple in the checkpoint room

v1.1:
- fixed error in log, that client is not ingame on welcome message
- added cvar: l4d2_l4d1vs_defib_multiplier
	the defib units acts in the score system like a medkit and will restore a percentage of the static health of an surivor
	if you dont like this idea you can set the multiplier to 0 and the defib unit will no longer have an effect on the score
- added cvar: l4d2_l4d1vs_map_multiplier_enable
	to avoid that the health is getting less important on later maps the score will be multiplied with a map multiplier like in l4d1
- added a return value to round_end
- fixed pills temphealth
	
v1.0:
- deleted cvar: l4d2_l4d1vs_debug
- deleted debug outputs
- deleted cvar l4d2_l4d1vs_tiebreak and l4d2_l4d1vs_tiebreak_score (was too confusing and would only apply and some rare cases)
- deleted tiebreak code
- added score output
- added instant plugin enable/disable with unhookevent
- fixed that the welcome message will only be displayed if the plugin is enabled

- the plugin is now restricted to 16 survivors (to change that change g_player_scores[16] and new String:tempstring[150] to higher values)

v0.5:
- added message for clients on connection

v0.4:
- added cvar: l4d2_l4d1vs_debug for debug outputs
- added cvar: l4d2_l4d1vs_tiebreak for enabling/disabling tiebreak on health
- changed cvar: l4d2_l4d1vs_tiebreak_score for setting bonus score on health tiebreak
- deleted command score_t
- deleted dublicate code and added new function

v0.3:
- fixed score for survivors with med and pills (completly no temphealth for survivors with med)
- deleted old code
- added cvar: multiplier for survival bonus score 
- added cvar: tiebreak score 
- tiebreak score will be 0 if both teams gets same bonus score

v0.2:
- deleted all code for survivor detection in saferoom (the score will be set every time the door will closed)
- fixed bug, where after disabling the plugin the score was still changed
- reset score is now the one before enabling the plugin
- added cvar: enable/disable convar
- added event finale_vehicle_leaving for final score (dont know yet if it works)

v0.1:
- initial
*/

/*
Plugin info
#######################
*/
public Plugin:myinfo =
{
	name = "L4D1 Versus Score",
	author = "Die Teetasse",
	description = "L4D1 Versus Score in L4D2",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1013899"
};

/*
Global variables
#######################
*/
new g_campaign_scores[2];
new g_map_counter;
new Handle:g_round_scores = INVALID_HANDLE;
new Float:g_round_data[2][4]; //AvgDistance, Health, Survivors, MapMultiplier

new bool:gb_enabled = false;
new bool:gb_med_try = false;
new bool:gb_set_score = false;

new Handle:cvar_defib = INVALID_HANDLE;
new Handle:cvar_enable = INVALID_HANDLE; 
new Handle:cvar_health_remover_enable = INVALID_HANDLE;
new Handle:cvar_scoredisplay = INVALID_HANDLE;
new Handle:cvar_welcome_msg_enable = INVALID_HANDLE;

new Address:sdk_director = Address:0;
new Handle:sdk_getscore = INVALID_HANDLE;
new Handle:sdk_hidescore = INVALID_HANDLE;

new String:mapmultiplier_path[PLATFORM_MAX_PATH];

/*
Fix for L4D2 Team Manager (thx AtomicStryker)
#######################
*/
public OnPluginLoaded()
{
	if (FindConVar("l4d2_team_manager_ver") != INVALID_HANDLE) // L4D2 Team Manager was loaded before this
	{
         ServerCommand("sm plugins unload l4d2scores");
         CreateTimer(0.3, ReloadL4D2Scores);
	}  
}

public Action:ReloadL4D2Scores(Handle:timer)
{
     ServerCommand("sm plugins load l4d2scores");
}  

/*
Create, hook convars and save default values
#######################
*/
public OnPluginStart()
{
	//gamecheck
	decl String:game[12];
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead2") == -1) SetFailState("L4D1 Versus will only work with Left 4 Dead 2!");
	
	//check and prepare dependencies
	PrepareSDK();
	PrepareMapMultiplier();
	
	//convars
	//#######################
	//version
	CreateConVar("l4d2_l4d1vs_version", PLUGIN_VERSION, "L4D1 Versus Score - version", CVAR_FLAGS|FCVAR_DONTRECORD);
	
	//enable/disable
	cvar_enable = CreateConVar("l4d2_l4d1vs_enable", "1", "L4D1 Versus Score - enable/disable", CVAR_FLAGS);
	HookConVarChange(cvar_enable, Hook_Enable);
	
	//defibrillator hp multiplier (like medkits)
	cvar_defib = CreateConVar("l4d2_l4d1vs_defib_multiplier", "0.5", "L4D1 Versus Score - defib health multiplier (like medkits 0.8 -> 80% of hp will be recovered)", CVAR_FLAGS, true, 0.0, true, 0.8);
	
	//checkpoint health items remover enable/disable
	cvar_health_remover_enable = CreateConVar("l4d2_l4d1vs_checkpoint_health_remover_enable", "1", "L4D1 Versus Score - checkpoint health items remover enable/disable", CVAR_FLAGS);
	
	//score display modes
	cvar_scoredisplay = CreateConVar("l4d2_l4d1vs_score_display", "2", "L4D1 Versus Score - display mode of scores at round end (0 = chat, 1 = motd, 2 = both)", CVAR_FLAGS);
	
	//welcome message enable/disable
	cvar_welcome_msg_enable = CreateConVar("l4d2_l4d1vs_welcome_msg_enable", "1", "L4D1 Versus Score - welcome message (while joining) enable/disable", CVAR_FLAGS);
	
	//regconsolecommands
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("teamsay", Command_Say);
	
	//create array
	g_round_scores = CreateArray(2);
}

/*
Prepare SDK calls
#######################
*/
PrepareSDK()
{
	//load game config
	new Handle:game_config = LoadGameConfigFile(GAMEDATA_SOURCE);
	if(game_config == INVALID_HANDLE)
	{
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, "#### Could not load %s ####", GAMEDATA_SOURCE);
#endif
		SetFailState("Fail to load %s", GAMEDATA_SOURCE);
	}
	
	//get director pointer
	sdk_director = GameConfGetAddress(game_config, "CDirector");
#if DEBUG_ENABLE	
	LogToFile(DEBUG_LOGFILE, "PTR to Director loaded at 0x%x", sdk_director);
#endif
	if(sdk_director == Address_Null)
	{
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, "#### CDirector failure ####");
#endif
		SetFailState("Fail to init the director pointer!");
	}
#if DEBUG_ENABLE
	else
	{
		LogToFile(DEBUG_LOGFILE, "#### CDirector ok ####");
	}
#endif
	
	//load getscore
	StartPrepSDKCall(SDKCall_GameRules);
	
	if(PrepSDKCall_SetFromConf(game_config, SDKConf_Signature, "GetTeamScore"))
	{
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		sdk_getscore = EndPrepSDKCall();
		
		if(sdk_getscore == INVALID_HANDLE)
		{
#if DEBUG_ENABLE
			LogToFile(DEBUG_LOGFILE, "#### GetTeamScore failure ####");
#endif
			SetFailState("Fail to init GetTeamScore!");
		}
#if DEBUG_ENABLE
		else
		{
			LogToFile(DEBUG_LOGFILE, "#### GetTeamScore ok ####");
		}
#endif
	}
	else
	{
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, "#### GetTeamScore not found ####");
#endif
		SetFailState("Fail to init GetTeamScore!");
	}
	
	//load hidscoreboard
	StartPrepSDKCall(SDKCall_Raw);
	
	if(PrepSDKCall_SetFromConf(game_config, SDKConf_Signature, "HideScoreboard"))
	{
		sdk_hidescore = EndPrepSDKCall();
	
		if (sdk_hidescore == INVALID_HANDLE)
		{
#if DEBUG_ENABLE
			LogToFile(DEBUG_LOGFILE, "#### HideScoreboard failure ####");
#endif
			SetFailState("Fail to init HideScoreboard!");
		}
#if DEBUG_ENABLE
		else
		{
			LogToFile(DEBUG_LOGFILE, "#### HideScoreboard ok ####");
		}
#endif
	}
	else
	{
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, "#### HideScoreboard not found ####");
#endif
		SetFailState("Fail to init HideScoreboard!");
	}
	
	CloseHandle(game_config);
}

/*
Build path to map multipliere file and check existence
#######################
*/
PrepareMapMultiplier()
{	
	BuildPath(Path_SM, mapmultiplier_path, sizeof(mapmultiplier_path), MAP_MULTIPLIER_SOURCE);

	//check file
	if (!FileExists(mapmultiplier_path))
	{
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, "Fail to load %s", mapmultiplier_path);
#endif
		SetFailState("Fail to load %s", mapmultiplier_path);
	}
}


/*
On l4d2_l4d1vs_enable change save oder restore values and hook/unhook events
#######################
*/
public Hook_Enable(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	//reset to default value on disabling
	if (StringToInt(newVal) == 0)
	{
		//to prevent unhooking without a hook
		if (gb_enabled) UnhookEvents();
	}
	//save reset value on enabling
	else
	{
		HookEvents();
	}
}

/*
Mapstart
#######################
*/
public OnMapStart()
{

#if DEBUG_ENABLE
	new String:mapname[50];
	GetCurrentMap(mapname, sizeof(mapname));

	LogToFile(DEBUG_LOGFILE, "###################");
	LogToFile(DEBUG_LOGFILE, "Mapstart: %s", mapname);	
#endif
	
	//get gamemode
	new String:mode[20];
	new Handle:gamemode = FindConVar("mp_gamemode");
	GetConVarString(gamemode, mode, sizeof(mode));

#if DEBUG_ENABLE	
	LogToFile(DEBUG_LOGFILE, "Gamemode: %s", mode);
#endif
	
	//versus and enabled?
	if (StrContains(mode, "versus") > -1 && GetConVarBool(cvar_enable)) HookEvents();
	else if (gb_enabled) UnhookEvents();
}

/*
Hook Events if versus and enabled
#######################
*/
HookEvents()
{
#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "---> Hook...");
#endif
	
	HookEvent("round_start", Event_round_start, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", Event_player_left_start_area);
		
	gb_enabled = true;
	
	//fix for start round missing
	gb_set_score = true;
	gb_med_try = false;
	
	//clear round data
	for (new i = 0; i < 4; i++) g_round_data[0][i] = g_round_data[1][i] = 0.0;
	
#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "!!roundstart (HOOK)!!");
#endif
	
}

/*
Unhook Events
#######################
*/
UnhookEvents()
{
#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "---> UNhook...");
#endif

	UnhookEvent("round_start", Event_round_start);
	UnhookEvent("player_left_start_area", Event_player_left_start_area);
	
	gb_enabled = false;
}

/*
set score calculation to true and start timer for health items
#######################
*/
public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{	
	gb_set_score = true;
	gb_med_try = false;

#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "!!roundstart!!");
#endif
}

/*
delete meds
#######################
*/
public Action:Event_player_left_start_area(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (gb_med_try) return;
	
	DeleteMeds();
	gb_med_try = true;
}

/*
Left 4 Downtown: Will be fired on campaign socre set
#######################
*/
public Action:L4D_OnSetCampaignScores(&scoreA, &scoreB)
{
	//enabled?
	if (!gb_enabled) return Plugin_Continue;

#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "SCORES SET (%d, %d)", scoreA, scoreB);
#endif
	
	//just copy the calculated score to the references on second attemp
	if (!gb_set_score)
	{
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, "2nd attemp!");
#endif
		//change references
		scoreA = g_campaign_scores[0];
		scoreB = g_campaign_scores[1];	
		
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, "SCORES CHANGED TO (%d, %d)", scoreA, scoreB);
#endif		
		return Plugin_Continue;
	}
	
	gb_set_score = false;
	
	//get team
	new team = GetTeam();
	
	//get score
	new score = GetScore(team);
	
	//save scores
	g_campaign_scores[team] += score;
	
	new tempscorearray[2];
	//first half push array
	if (GetHalf() == 1)
	{
		//g_round_scores[team][g_map_counter] = score;
		tempscorearray[team] = score;
		tempscorearray[otherteam(team)] = -1;	
	
		PushArrayArray(g_round_scores, tempscorearray);
	}
	//second half set array
	else
	{
		new firsthalfarray[2];
		GetArrayArray(g_round_scores, g_map_counter, firsthalfarray);
		
		tempscorearray[team] = score;
		tempscorearray[otherteam(team)] = firsthalfarray[otherteam(team)];

		SetArrayArray(g_round_scores, g_map_counter, tempscorearray);
	}
	
	//change references
	scoreA = g_campaign_scores[0];
	scoreB = g_campaign_scores[1];		
	
	//hide scoreboard
	HideScoreBoard();
	
	//print scores
	PrintScores();
	
	//increment map counter if second half
	if (GetHalf() == 2) g_map_counter++;

#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "SCORES CHANGED TO (%d, %d)", scoreA, scoreB);
	LogToFile(DEBUG_LOGFILE, "Mapcounter: %d", g_map_counter);
	LogToFile(DEBUG_LOGFILE, "Team: %d", team);
	LogToFile(DEBUG_LOGFILE, "Campaign Score: %d", g_campaign_scores[team]);	
	for (new i = 0; i < GetArraySize(g_round_scores); i++)
	{
		new roundarray[2];
		GetArrayArray(g_round_scores, i, roundarray);
		LogToFile(DEBUG_LOGFILE, "Round Scores: %d", roundarray[team]);
	}
#endif
	
	return Plugin_Continue;
}	

/*
Left 4 Downtown: Will be fired on score reset
#######################
*/
public Action:L4D_OnClearTeamScores(bool:newCampaign)
{
#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "SCORES CLEARED");
#endif

	//new campaign, reset score etc
	if (newCampaign)
	{
		g_map_counter = 0;
		
		for (new i = 0; i < 2; i++) g_campaign_scores[i] = 0;		
		ClearArray(g_round_scores);
		
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, "New Campaign => scores reset!");
#endif
	}
	
	return Plugin_Continue;
}

/*
#######################
SDK Calls
#######################

GETSCORE:

	1 0 round score team a
	2 0 round score team b
	
	1 1 campaign score team a
	2 1 campaign score team b
	
	3 1 round score team a (but will not be reset)
	4 1 round score team b 
	
	5 1 infected score team a
	6 1 infected score team b
	
	21 1 survivor distance team a player a		not %, points!
	22 1 survivor distance team a player b
	23 1 survivor distance team a player c
	24 1 survivor distance team a player d

	25 1 survivor distance team b player a
	26 1 survivor distance team b player b
	27 1 survivor distance team b player c
	28 1 survivor distance team b player d
	
	29 1 survivor death distance team a player a	not %, points!	
	30 1 survivor death distance team a player b	-1 => not set yet
	31 1 survivor death distance team a player c
	32 1 survivor death distance team a player d
	
	33 1 survivor death distance team b player a
	34 1 survivor death distance team b player b
	35 1 survivor death distance team b player c
	36 1 survivor death distance team b player d 
	
	37 1 distance score team a
	38 1 distance score team b
	
	39 1 survivors in safe room team a 				(survivor multiplier) update on roundend, before 0
	40 1 survivors in safe room team b
	
	62 1 indicator of half and actual team (first = 0/1, second = 256/257)
	
	64 1 max distance points of map (before passing 65)
*/

/*
return survivor distance points
#######################
*/
GetSurvivorDistancePoints(team, player)
{
	if (team != TEAM_A && team != TEAM_B)
	{
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, ">>> Wrong team paramter of GetSurvivorDistancePoints");
#endif
		return -1;
	}

	if (player < 0 || player > 3)
	{
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, ">>> Wrong player paramter of GetSurvivorDistancePoints");
#endif
		return -1;
	}
	
	return SDKCall(sdk_getscore, (OFFSET_SURVIVOR_DISTANCE + (team * 4) + player), 1);
}

/*
return survivor distance in percentage
#######################
*/
Float:GetSurvivorDistance(team, player)
{
	if (team != TEAM_A && team != TEAM_B)
	{
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, ">>> Wrong team paramter of GetSurvivorDistance");
#endif
		return -1.0;
	}

	if (player < 0 || player > 3)
	{
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, ">>> Wrong player paramter of GetSurvivorDistance");
#endif
		return -1.0;
	}
	
	//(Points / (MaxPoints / 4)) * 100
	return (float(GetSurvivorDistancePoints(team, player)) / (float(GetMaxDistance()) / 4.0)) * 100.0;
}

/*
return survivor count
#######################
*/
#if DEBUG_ENABLE
GetSurvivorCount(team)
{
	if (team != TEAM_A && team != TEAM_B)
	{
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, ">>> Wrong team paramter of GetSurvivorCount");
#endif
		return -1;
	}
		
	return SDKCall(sdk_getscore, (OFFSET_SURVIVOR_COUNT + team), 1);
}
#endif

/*
return actual team
#######################
*/
GetTeam()
{
	return (SDKCall(sdk_getscore, OFFSET_ACTUAL_TEAM, 1) % 256);
}

/*
return half
#######################
*/
GetHalf()
{
	if (SDKCall(sdk_getscore, OFFSET_ACTUAL_TEAM, 1) > 128) return 2;
	else return 1;
}

/*
return max distance points
#######################
*/
GetMaxDistance()
{
	return SDKCall(sdk_getscore, OFFSET_MAX_DISTANCE, 1);
}

/*
hide score board
#######################
*/
HideScoreBoard()
{
	SDKCall(sdk_hidescore, sdk_director);
}

/*
calculate score and return it
#######################
*/
GetScore(team)
{
	new Float:fhealth;
	new Float:fmap_multiplier = 1.0;
	new Float:ftemphealth;
	new Float:fsurvivor_distance = 0.0;
	new health;
	new i;
	new maxplayers = MaxClients;
	new score = 0;
	new score_team = 0;
	new survivors = 0;
	new survivors_incapped = 0;
	new tempent;
	new String:tempname[50];
	
	//get defi mutliplier
	new Float:defib_multi = GetConVarFloat(cvar_defib);
	
	//search survivors
	for (i = 1; i < maxplayers; i++)
	{
		//Ingame, survivor and alive?
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			//incapped and final?
			if (IsPlayerIncap(i))
			{
				if (IsFinal()) continue;
				
				health = 0;
				ftemphealth = SURVIVOR_INCAP_HEALTH;
				
				survivors_incapped++;
			}
			else
			{
				//Health
				health = GetEntProp(i, Prop_Send, "m_iHealth");
			
				//Temphealth (m_healthBuffer stores not the actual value)
				ftemphealth = RoundToCeil(GetEntPropFloat(i, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(i, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1.0;
				if (FloatCompare(ftemphealth, 0.0) == -1) ftemphealth = 0.0;
				
				survivors++;
			}

			//inventory
			tempent = GetPlayerWeaponSlot(i, 3);
			if (tempent > -1)
			{
				GetEdictClassname(tempent, tempname, sizeof(tempname));
				if (StrContains(tempname, "weapon_first_aid_kit") > -1)
				{
					fhealth = ((100.0 - float(health)) * 0.8) + float(health);
					ftemphealth = 0.0;
				}
				//multiplier must be greater than 0
				if (StrContains(tempname, "weapon_defibrillator") > -1 && defib_multi > 0.0)
				{
					fhealth = ((100.0 - float(health)) * defib_multi) + float(health);
					ftemphealth = 0.0;
				}							
			}
			else 
			{
				fhealth = float(health);
				
				tempent = GetPlayerWeaponSlot(i, 4);
				if (tempent > -1)
				{
					GetEdictClassname(tempent, tempname, sizeof(tempname));		
					if (StrContains(tempname, "weapon_pain_pills") > -1)
					{
						ftemphealth += 50.0;
					}		
					if (StrContains(tempname, "weapon_adrenaline") > -1)
					{
						ftemphealth += 25.0;
					}		
				}
			}

			if (ftemphealth > 100.0) ftemphealth = 100.0;
			if (fhealth + ftemphealth > 100.0) ftemphealth = 100.0 - fhealth;

			score_team += RoundToFloor(fhealth/2) + RoundToFloor(ftemphealth/4);			
		}
	}

	//update survivors
	if (survivors > 0) survivors += survivors_incapped;
	
#if DEBUG_ENABLE
	//debug check
	new survivors_director = GetSurvivorCount(team);
	if (survivors != survivors_director)
	{
		LogToFile(DEBUG_LOGFILE, ">>> Counted survivors (%d) not match director survivor (%d)!", survivors, survivors_director);
	}
#endif
	
	//sum distances
	for (i = 0; i < 4; i++) fsurvivor_distance += GetSurvivorDistance(team, i);
	//and divide through survivors
	fsurvivor_distance /= 4.0;

	//map multiplier
	fmap_multiplier = GetMapMultiplier();
	
#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "SCORE DATA:");
	LogToFile(DEBUG_LOGFILE, "%0.1f, %d, %d, %0.1f", fsurvivor_distance, score_team, survivors, fmap_multiplier);
#endif
	
	//survived or not?
	if (survivors == 0) score = RoundFloat(fsurvivor_distance * fmap_multiplier);
	else score = RoundFloat((fsurvivor_distance + float(score_team)) * survivors * fmap_multiplier);

#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "=> %d", score);
#endif
	
	//save data in array
	g_round_data[team][0] = fsurvivor_distance;
	g_round_data[team][1] = float(score_team);
	g_round_data[team][2] = float(survivors);
	g_round_data[team][3] = fmap_multiplier;
	
	return score;
}

/*
print scores main function
#######################
*/
PrintScores()
{
	//get displaymode
	new displaymode = GetConVarInt(cvar_scoredisplay);
	
	if (displaymode != 1) ChatScores();
	if (displaymode > 0) MOTDScores();
}

/*
print score to everyone
#######################
*/
ChatScores()
{
	new team = GetTeam();
	new other_team = otherteam(team);
	
	if (GetHalf() == 2)
	{
		other_team = GetTeam();
		team = otherteam(team);
	}
	
	new roundscores[2];
	GetArrayArray(g_round_scores, g_map_counter, roundscores);

	PrintToChatAll("%s Round Scores:", PLUGIN_TAG);
	
	if (RoundFloat(g_round_data[team][2]) == 0)
	{
		PrintToChatAll("%s (AvgDistance) * MapMultiplier", PLUGIN_TAG);	
		PrintToChatAll("%s Team1: (%0.1f) * %0.1f = %d", PLUGIN_TAG, g_round_data[team][0], g_round_data[team][3], roundscores[team]);
	}
	else
	{
		PrintToChatAll("%s (AvgDistance + Health) * Survivors * MapMultiplier", PLUGIN_TAG);	
		PrintToChatAll("%s Team1: (%0.1f + %d) * %d * %0.1f = %d", PLUGIN_TAG, g_round_data[team][0], RoundFloat(g_round_data[team][1]), RoundFloat(g_round_data[team][2]), g_round_data[team][3], roundscores[team]);	
	}
	
	if (GetHalf() == 2)
	{
		if (RoundFloat(g_round_data[other_team][2]) == 0)
		{
			if (RoundFloat(g_round_data[team][2]) > 0) PrintToChatAll("%s (AvgDistance) * MapMultiplier", PLUGIN_TAG);	
			PrintToChatAll("%s Team2: (%0.1f) * %0.1f = %d", PLUGIN_TAG, g_round_data[other_team][0], g_round_data[other_team][3], roundscores[other_team]);
		}
		else
		{
			if (RoundFloat(g_round_data[team][2]) == 0) PrintToChatAll("%s (AvgDistance + Health) * Survivors * MapMultiplier", PLUGIN_TAG);	
			PrintToChatAll("%s Team2: (%0.1f + %d) * %d * %0.1f = %d", PLUGIN_TAG, g_round_data[other_team][0], RoundFloat(g_round_data[other_team][1]), RoundFloat(g_round_data[other_team][2]), g_round_data[other_team][3], roundscores[other_team]);	
		}		
	}
	
	PrintToChatAll("%s Campaign Scores:", PLUGIN_TAG);
	PrintToChatAll("%s Team1: %d", PLUGIN_TAG, g_campaign_scores[team]);
	PrintToChatAll("%s Team2: %d", PLUGIN_TAG, g_campaign_scores[other_team]);
}

/*
modt output - round score for everybody 
#######################
*/
MOTDScores()
{
	new rounddistance;
	new team = GetTeam();
	new other_team = otherteam(team);
	new Float:distance;
	
	new roundscores[2];
	GetArrayArray(g_round_scores, g_map_counter, roundscores);
	
	new String:text[215] = "";
	new String:addtext[100] = "Distances:\n";
	new String:addint[10];
	
	new Handle:MOTDMessage = StartMessageAll("VGUIMenu");
	if(MOTDMessage == INVALID_HANDLE)
	{
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, "MOTDMessage invalid handle!");
#endif
		return;
	}
	
	for (new i = 0; i < 4; i++)
	{
		distance = GetSurvivorDistance(team, i);
		rounddistance = RoundToNearest(distance / 10.0);

		Format(addint, sizeof(addint), "%3.1f\t", distance);
		StrCat(addtext, sizeof(addtext), addint);	
		
		for (new j = 0; j < rounddistance; j++) StrCat(addtext, sizeof(addtext), "#");
		StrCat(addtext, sizeof(addtext), "\n");
	}
	StrCat(text, sizeof(text), addtext);
	StrCat(text, sizeof(text), "\nRound:\n");
	
	if (GetHalf() == 2)
	{
		other_team = GetTeam();
		team = otherteam(team);
	}
	
	if (RoundFloat(g_round_data[team][2]) == 0) Format(addtext, sizeof(addtext), "Team1: (%0.1f) * %0.1f = %d\n", g_round_data[team][0], g_round_data[team][3], roundscores[team]);
	else Format(addtext, sizeof(addtext), "Team1: (%0.1f + %d) * %d * %0.1f = %d\n", g_round_data[team][0], RoundFloat(g_round_data[team][1]), RoundFloat(g_round_data[team][2]), g_round_data[team][3], roundscores[team]);	
	StrCat(text, sizeof(text), addtext);
	
	if (GetHalf() == 2)
	{
		if (RoundFloat(g_round_data[other_team][2]) == 0) Format(addtext, sizeof(addtext), "Team2: (%0.1f) * %0.1f = %d\n", g_round_data[other_team][0], g_round_data[other_team][3], roundscores[other_team]);
		else Format(addtext, sizeof(addtext), "Team2: (%0.1f + %d) * %d * %0.1f = %d\n", g_round_data[other_team][0], RoundFloat(g_round_data[other_team][1]), RoundFloat(g_round_data[other_team][2]), g_round_data[other_team][3], roundscores[other_team]);
		StrCat(text, sizeof(text), addtext);
	}
		
	StrCat(text, sizeof(text), "\nCampaign:\n");
	
	Format(addtext, sizeof(addtext), "Team1: %d\n", g_campaign_scores[team]);
	StrCat(text, sizeof(text), addtext);
	Format(addtext, sizeof(addtext), "Team2: %d\n", g_campaign_scores[other_team]);
	StrCat(text, sizeof(text), addtext);
	
	BfWriteString(MOTDMessage, "info");
	BfWriteByte(MOTDMessage, 1);
	BfWriteByte(MOTDMessage, 3);

	BfWriteString(MOTDMessage, "title");
	BfWriteString(MOTDMessage, "Scores overview:");
	BfWriteString(MOTDMessage, "type");
	BfWriteString(MOTDMessage, "0");
	BfWriteString(MOTDMessage, "msg");
	BfWriteString(MOTDMessage, text);
	EndMessage();	
	
	//timer to deactivate motd
	CreateTimer(12.0, Timer_MOTD_Disable);
}

/*
will disable motd after x seconds
#######################
*/
public Action:Timer_MOTD_Disable(Handle:timer)
{
	new Handle:MOTDMessage = StartMessageAll("VGUIMenu");
	if(MOTDMessage == INVALID_HANDLE) return Plugin_Continue;
	
	BfWriteString(MOTDMessage, "info");
	BfWriteByte(MOTDMessage, 0);
	EndMessage();
	
	return Plugin_Continue;
}

/*
return map multiplier by cfg defintion
#######################
*/
Float:GetMapMultiplier()
{
	new Float:multiplier;
	new String:mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));

	//create structure
	new Handle:mapmultiplier_data = CreateKeyValues("map_multipliers");
	
	//load file
	if (!FileToKeyValues(mapmultiplier_data, mapmultiplier_path))
	{
		PrintToChatAll("%s Can not load map multiplier file! Assume 1.0", PLUGIN_TAG);
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, "Can not load map multiplier file! Assume 1.0");
#endif
		return 1.0;
	}
	
	multiplier = KvGetFloat(mapmultiplier_data, mapname, -1.0);
	
	//check value
	if (multiplier == -1.0) 
	{
		PrintToChatAll("%s Can not load data from file! Assume 1.0", PLUGIN_TAG);
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, "Can not load data (%s) from file! Assume 1.0", mapname);
#endif
		return 1.0;		
	}
	
	//return value
	return multiplier;
}

/*
check if a survivor is incapped and return bool value
#######################
*/
IsPlayerIncap(client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

/*
delete health items system
#######################
*/
DeleteMeds()
{
	//enabled?
	if (!GetConVarBool(cvar_health_remover_enable)) return;
	
#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "DELETE");
	
	//get mapname
	new String:mapname[10];
	GetCurrentMap(mapname, sizeof(mapname));	
	
	LogToFile(DEBUG_LOGFILE, "Campaign: %d, Map: %d", StringToInt(mapname[1]), StringToInt(mapname[3]));
#endif
		
	//final?
	if (IsFinal()) return;
	
#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "Not final...");
#endif
	
	new Float:medkitpos[3];
	
	//look after medkitpos
	if (!GetSafeRoomPosition(medkitpos))
	{
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, "No saferoom found!");
#endif	
		return;
	}

#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "saferoom: %f %f %f", medkitpos[0], medkitpos[1], medkitpos[2]);
#endif	
	
	new entitycount = GetEntityCount();
	new Float:entpos[3];
	new String:entname[50];
	
	//loop through ents
	for (new i = 1; i < entitycount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, entname, sizeof(entname));
			
			//med or something like this?
			if (StrContains(entname, "weapon_first_aid_kit") > -1 ||
				StrContains(entname, "weapon_defibrillator") > -1 ||
				StrContains(entname, "weapon_pain_pills") > -1 ||				
				StrContains(entname, "weapon_adrenaline") > -1)
			{
				//get position	
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);

				if (GetVectorDistance(medkitpos, entpos) < 400.0) 
				{
#if DEBUG_ENABLE
					LogToFile(DEBUG_LOGFILE, "%s - in range (%f %f %f)", entname, entpos[0], entpos[1], entpos[2]);
#endif
					KillEntity(i);
				}
			}
		}
	}
	
#if DEBUG_ENABLE	
	LogToFile(DEBUG_LOGFILE, "done...");
#endif
}			

/*
send kill input to entity
#######################
*/
KillEntity(entity)
{
#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "kill %d...", entity);
#endif
	AcceptEntityInput(entity, "kill");
}

/*
check if final by trigger_final entity
#######################
*/
bool:IsFinal()
{
	if (FindEntityByClassname(-1, "trigger_finale") > -1) return true;
	return false;	
}

/*
return position of saferoom (thx AtomicStryker)
#######################
*/
bool:GetSafeRoomPosition(Float:position[3])
{
	if (IsFinal()) return false;

	new saferoom = FindEntityByClassname(-1, "info_changelevel");
	if (saferoom < 0) return false;

	decl Float:mins[3], Float:maxs[3];
	GetEntPropVector(saferoom, Prop_Send, "m_vecOrigin", position);
	GetEntPropVector(saferoom, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(saferoom, Prop_Send, "m_vecMaxs", maxs);
		
	for (new i = 0; i < sizeof(mins); i++) position[i] += (mins[i] + maxs[i]) * 0.5;

	return true;
}

/*
Starts welcome message timer
#######################
*/
public OnClientPutInServer(client)
{
	if (GetConVarBool(cvar_welcome_msg_enable) && gb_enabled) CreateTimer(5.0, WelcomePlayer, client, TIMER_REPEAT);
}

/*
Show welcome message
#######################
*/
public Action:WelcomePlayer(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		PrintToChat(client, "%s L4D1 Score System is enabled!", PLUGIN_TAG);
		PrintToChat(client, "%s Medkits, pills and shots are important again!", PLUGIN_TAG);
		PrintToChat(client, "%s Type !score to see the round and campaign scores!", PLUGIN_TAG);
		
		PrintHintText(client, "L4D1 Score System is enabled!\nMedkits, pills and shots are important again!\nType !score to see the round and campaign scores!");
		
		return Plugin_Stop;
	}
	
	//disconnected? stop!
	if (!IsClientConnected(client)) return Plugin_Stop;
	
	return Plugin_Continue;
}

/*
Check if client wants score output
#######################
*/
public Action:Command_Say(client, args)
{
	if (args < 1)
	{
		return Plugin_Continue;
	}

	decl String:text[15];
	GetCmdArg(1, text, sizeof(text));
	
	//only if at the beginning
	if (StrContains(text, "!score") == 0)
	{
		PrintScoresToClient(client);
		//no need to show this chatcommand for everybody
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/*
Print score array to client as panel
#######################
*/
PrintScoresToClient(client)
{	
	//first map and first half?
	if (g_map_counter == 0 && GetHalf() == 1)
	{
		PrintToChat(client, "%s No scores available!", PLUGIN_TAG);
		return;
	}
	
	//get clients side
	new clientside = GetClientTeam(client);
	
	//get actual survivor team
	new actualteam = GetTeam();
	
	//get clients team
	new clientteam;
	new enemyteam;
	
	if (clientside == 2)
	{
		clientteam = actualteam;
		enemyteam = otherteam(actualteam);
	}
	else 
	{
		clientteam = otherteam(actualteam);
		enemyteam = actualteam;
	}
	
	//creating panel
	new Handle:ScorePanel = CreatePanel();
	
	//drawing Text
	SetPanelTitle(ScorePanel, "Scores (yours / enemies):");
	DrawPanelText(ScorePanel, "############################");

	new String:text[50];
	
	//drawing roundscores
	for (new i = 0; i < GetArraySize(g_round_scores); i++)
	{
		new roundarray[2];
		GetArrayArray(g_round_scores, i, roundarray);
		
		Format(text, sizeof(text), "Map %d: %d / %d", (i + 1), roundarray[clientteam], roundarray[enemyteam]);
		DrawPanelText(ScorePanel, text);
	}	
		
	//drawing campaignscores
	DrawPanelText(ScorePanel, "----------------------------");
	Format(text, sizeof(text), "Campaign: %d / %d", g_campaign_scores[clientteam], g_campaign_scores[enemyteam]);
	DrawPanelText(ScorePanel, text);
		
	//send panel
	SendPanelToClient(ScorePanel, client, ScorePanelHandler, 10);
	CloseHandle(ScorePanel);
}

/*
Panel handler
#######################
*/
public ScorePanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	//nothing to do
}

/*
Return other team number
#######################
*/
otherteam(team)
{
	if (team == 0) return 1;
	else return 0;
}
