/*
*															
*					L4D Rage Meter						
*					 by Darkness							
*															
*  	Description: Counts	quitters as anyone who leaves a match			
* 	in progress and does not rejoin before the round ends. You
* 	are allowed to quit between rounds.	
* 	That is all...except for a kick counter					
* 
*/

/*	Versioning
* 
* 	9/02/09
* 	v1.0.0j
* 	1. Fixed Precache check by just removing it...if you notice a problem let me know
* 	-- Fixes all sounds other than rage quit not working
* 	2. Fix CloseHandle errors due to not checking the status of the handle properly
* 	3. Changed default kick sound to Zoey's "What a dick"
* 	-- I_Am_Scum helps to test and requested it
* 
* 	9/02/09
* 	v1.0.0i Changes
*	1. Added sound ConVars and the ability to play sounds on new players, rejoins, kicks, and quits	
* 	2. Fixed IsClientTimingOut erroring on IsClientInGame
* 	3. Added option to count quits inbetween rounds as part of the last round(not perfect and disabled by default)
* 	4. Added rpm calculation timer - by default runs every minute
* 
*	8/28/09 
*   v1.0.0h Changes:
* 	1. Protect round start and end so they can only process once
* 	2. Added IsClientTimingOut to non-quits
* 	3. Fixed Float comparison in RpmCalc
* 	4. Normalized cache value names
* 	5. Lots of debugging possible
* 	6. Resets galore for round and map functions
* 	7. Shortcircuit on campaign change vote
* 
* 	8/25/09 
*   v1.0.0g Changes:
*  	1. Added Rage Per Minute value (Round specific)
* 	2. Added proper shortCircuit for finale and between rounds
* 	3. Quitting after the win or loss in finale should not count
* 	4. Added and made default steamid option incase of name change reconnects to game the count(may be important later;D)
* 	5. Replaced LogAction with LogMessage
* 	6. Shortcircuit on return to lobby vote
* 
* 
*	8/21/09 
*   v1.0.0f Changes:
* 	1. Fixed native vote kicks counting against quits
* 	2. Changed from ShowActivity2 to PrintToChatAll
*   -- complaints from text being large and ugly
* 	3. Try to fit text output on one line if possible
*   4. Changed plugin name to RageMeter due to people wondering what RageCampaign means...lol
* 	--thanks to I_Am_Scum for the suggested name
* 	5. Added public Cvar "l4d_ragemeter_version"
* 	6. Shortened all Cvar names
*
* 
* 	8/20/09
*	v1.0.0e Changes:
* 	1. Added AutoExecConfig 
* 	-- thanks olj
* 	2. Hooking convar changes now 
* 	--hopefully includes values loaded by AutoExecConfig
* 	3. Added variable CVAR_FLAGS to ConVar's
* 	4. Actually updated Plugin Version this time around
* 
*	8/18/09 
* 	v1.0.0d Changes:
* 	1. Change name from "L4D Rage Counter" to "L4D Rage Campaign" 
* 	--Arrived late to the party and can't expect people to give up first submit first served
* 
* 	7/6/09
*	v1.0.0c Changes: 
* 	1. Clean up constants, variable names, and added debug
* 	
* 	2/24/09
*  	v1.0.0b Changes:
* 	1. Added Rage Statistics that are kept between rounds
*      (Last Round, Best Round, etc.)
* 	2. Added sm_rage(!rage) command to view statistics
* 	
* 	2/21/09
* 	v1.0.0a Changes:
*   1. First Release
* 
*/
#pragma semicolon 1

#define MAX_CLIENT_NAMES 64
#define MAX_TEXT_SIZE 4096
#define PANEL_STRING_SIZE 64
#define AUTH_MAX_LENGTH MAX_NAME_LENGTH
#define REMEMBER_COUNT 32
#define RAGE_STAT_VISIBLE_TIMEOUT 10
#define PLUGIN_VERSION "1.0.0j"
#define VOTE_DETAILS_LENGTH 64
#define CVAR_FLAGS 0
#define RPM_PRECISION 6
#define SOUND_PATH_LIMIT 256
#define RAGESOUNDFLAG 1
#define KICKSOUNDFLAG 2
#define REJOINSOUNDFLAG 4
#define FRESHSOUNDFLAG 8

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "L4D RageMeter",
	author = "Darkness",
	description = "Counts quitters without prejudice or excuses",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

new Handle:ragemeter_version = INVALID_HANDLE;
new Handle:RAGE_DEBUG = INVALID_HANDLE;
new Handle:silentRage = INVALID_HANDLE;
new Handle:rageLog = INVALID_HANDLE;
new Handle:rageKicked = INVALID_HANDLE;
new Handle:freshMeat = INVALID_HANDLE;
new Handle:connectAdvertise = INVALID_HANDLE;
new Handle:rpmMeter = INVALID_HANDLE;
new Handle:authType = INVALID_HANDLE;
new Handle:playSounds = INVALID_HANDLE;
new Handle:freshSound = INVALID_HANDLE;
new Handle:rejoinSound = INVALID_HANDLE;
new Handle:rageSound = INVALID_HANDLE;
new Handle:kickSound = INVALID_HANDLE;
new Handle:resetType = INVALID_HANDLE;
new Handle:rpmCalcTime = INVALID_HANDLE;
new Handle:rpmTimer = INVALID_HANDLE;

new rage_debug_cache, rage_silent_cache, rage_log_cache, rage_kicked_cache;
new rage_fresh_cache,vote_kick_passed,rage_ad_cache, finale_start_cache;
new roundCount, campaignCount, bufferCount, kickedClients, checkCampReset;
new lastRound, bestRound, shortCircuit, rage_rpm_cache, rage_auth_cache;
new rpmTime[2], auth_protect_cache, round_protect_cache, ignoreEvents;
new play_sounds_cache, reset_type_cache, newClientCount, lastClientCount, clientsBack;

new String:fresh_sound_cache[SOUND_PATH_LIMIT];
new String:rejoin_sound_cache[SOUND_PATH_LIMIT];
new String:rage_sound_cache[SOUND_PATH_LIMIT];
new String:kick_sound_cache[SOUND_PATH_LIMIT];

new Float:rpm;
new Float:rpm_calc_time_cache;

new String:auth[MAX_NAME_LENGTH];
new String:playerName[MAX_NAME_LENGTH];
new String:vote_kick_player[MAX_NAME_LENGTH];
new String:fullText[MAX_TEXT_SIZE];
new String:clientAuths[MAX_CLIENT_NAMES][MAX_NAME_LENGTH];
new String:rpmText[RPM_PRECISION];


/*=====================================================================================
* 	OnPluginStart
* 
* 	Setup the plugin, create ConVar's, hook all events and changes, first initialization
=====================================================================================*/
public OnPluginStart()
{
	
	
	//Register our display of stats
	RegConsoleCmd("sm_rage", SayRage);
	
	//CVars
	ragemeter_version = CreateConVar("l4d_ragemeter_version", PLUGIN_VERSION, "RageMeter version",FCVAR_NOTIFY|FCVAR_PLUGIN);
	RAGE_DEBUG = CreateConVar("l4d_ragemeter_debug", "0", "Debug logging",CVAR_FLAGS, true, 0.0, true, 1.0);
	silentRage = CreateConVar("l4d_ragemeter_silent", "1", "Determines whether or not to send general count notices to all players",CVAR_FLAGS, true, 0.0, true, 1.0);
	rageLog = CreateConVar("l4d_ragemeter_log", "0", "Determines whether or not to send general count notices to SM logs",CVAR_FLAGS, true, 0.0, true, 1.0);
	rageKicked = CreateConVar("l4d_ragemeter_kicked", "1", "Determines whether or not to notify on kicked clients ",CVAR_FLAGS, true, 0.0, true, 1.0);
	freshMeat = CreateConVar("l4d_ragemeter_freshmeat", "0", "Determines whether or not to notify on new clients",CVAR_FLAGS, true, 0.0, true, 1.0);
	connectAdvertise = CreateConVar("l4d_ragemeter_connect_ad", "1", "Determines whether or not to inform clients of plugin on putinserver event(only works when l4d_ragemeter_silent=1)",CVAR_FLAGS, true, 0.0, true, 1.0);
	rpmMeter = CreateConVar("l4d_ragemeter_rpm", "1", "Determines whether or not to display rages per minute",CVAR_FLAGS, true, 0.0, true, 1.0);
	authType = CreateConVar("l4d_ragemeter_auth_type", "1", "Count based on Names(0) or SteamID's(1)",CVAR_FLAGS, true, 0.0, true, 1.0);
	resetType = CreateConVar("l4d_ragemeter_reset_type", "0", "Reset on Round End(0) or Round Start(1)",CVAR_FLAGS, true, 0.0, true, 1.0);
	rpmCalcTime = CreateConVar("l4d_ragemeter_rpm_calc_time", "60.0", "How often to recalculate the rpm value when no one has quit",CVAR_FLAGS, true, 60.0, true, 600.0);
	//Sounds
	playSounds = CreateConVar("l4d_ragemeter_play_sounds", "15", "Play notification sounds: add each together to get the combination you want: 0=Off,1=Rage,2=Kick,4=Rejoin,8=FreshMeat",CVAR_FLAGS);
	freshSound = CreateConVar("l4d_ragemeter_fresh_sound", "UI/helpful_event_1.wav", "Plays to everyone when new players join",CVAR_FLAGS);
	rejoinSound = CreateConVar("l4d_ragemeter_rejoin_sound", "UI/holdout_medal.wav", "Plays to everyone when a player rejoins",CVAR_FLAGS);
	rageSound = CreateConVar("l4d_ragemeter_rage_sound", "UI/critical_event_1.wav", "Plays to everyone when players quit",CVAR_FLAGS);
	kickSound = CreateConVar("l4d_ragemeter_kick_sound", "player/survivor/voice/TeenGirl/WorldAirport05NPC07.wav", "Plays to everyone when players are kicked",CVAR_FLAGS);
	
	//Hook All ConVar Changes
	HookConVarChange(ragemeter_version,RageVersionStatic); //Don't change the version outside of code
	HookConVarChange(RAGE_DEBUG, DebugChanged); //May regret this later
	HookConVarChange(silentRage, SilentChanged);
	HookConVarChange(rageLog, LogChanged);
	HookConVarChange(rageKicked, KickChanged);
	HookConVarChange(freshMeat, FreshMeatChanged);
	HookConVarChange(connectAdvertise, ConnectAdvertiseChanged);
	HookConVarChange(rpmMeter, RpmMeterChanged);
	HookConVarChange(authType, AuthTypeChanged); //Should never be changed without restarting plugin
	HookConVarChange(resetType, ResetTypeChanged);
	HookConVarChange(rpmCalcTime, RPMCalcTimeChanged);
	
	HookConVarChange(playSounds, PlaySoundsChanged);
	HookConVarChange(freshSound, FreshSoundChanged);
	HookConVarChange(rejoinSound, RejoinSoundChanged);
	HookConVarChange(rageSound, RageSoundChanged);
	HookConVarChange(kickSound, KickSoundChanged);
	
	
	//Default Cache Values --Important! Need to initialize for default values --do not change defaults and not change these
	rage_debug_cache = 0;
	rage_silent_cache = 1;
	rage_kicked_cache = 1;
	rage_log_cache = 0;
	rage_fresh_cache = 0;
	rage_ad_cache = 1;
	rage_rpm_cache = 1;
	rage_auth_cache = 1;
	reset_type_cache = 0;
	rpm_calc_time_cache = 60.0;
	
	round_protect_cache = 0;
	auth_protect_cache = 0;
	
	play_sounds_cache = 15;
	strcopy(fresh_sound_cache,SOUND_PATH_LIMIT,"UI/helpful_event_1.wav");
	strcopy(rejoin_sound_cache,SOUND_PATH_LIMIT,"UI/holdout_medal.wav");
	strcopy(rage_sound_cache,SOUND_PATH_LIMIT,"UI/critical_event_1.wav");
	strcopy(kick_sound_cache,SOUND_PATH_LIMIT,"player/survivor/voice/TeenGirl/WorldAirport05NPC07.wav");
	
	
	//Hook round start and end as reference points
	HookEvent("round_start", RoundStartCheck);
	HookEvent("round_end", RoundEndCheck);
	HookEvent("finale_start", FinaleStartCheck);
	HookEvent("finale_win", FinaleWinCheck);
	HookEvent("mission_lost", MissionLostCheck);
	//Hook vote_passed so we can properly count kicks and check for other votes
	HookEvent("vote_passed", VotePassed, EventHookMode_Pre);
	
	
	
	//Write the config if not already done --Important to be after ConVar hooks and default cache values
	AutoExecConfig(true,"l4d_ragemeter");
	
	//Initialize some variables
	roundCount = 0;
	campaignCount = 0;
	bufferCount = 0;
	lastRound = 0;
	bestRound = 0;
	rpm=0.000;
	rpmText="0.000";
	
	
	//Used to see whether or not the players went back to lobby or left before a campaign was completed.
	checkCampReset = 1;
}

public OnPluginEnd()
{
	//Just Incase
	if((reset_type_cache==1) && (rpmTimer !=INVALID_HANDLE)) CloseHandle(rpmTimer);
}

/*=====================================================================================
* 	OnMapStart - OnMapEnd
* 
* 	Initialize our variables at the beginning and end of campaigns
=====================================================================================*/
public OnMapStart()
{	
	CallCacheSounds();
	if (campaignCount > 0)
	{
		//This should be 0 unless the last map didn't end.
		if(!(checkCampReset==0)) 
		{	
			campaignCount=0;
			kickedClients=0;
		}
	}
	//Kick off the round 
	checkCampReset = 1;
	
}
public OnMapEnd()
{
	//Tells the plugin that we actually made it to map end (important!)
	checkCampReset = 0;
}



/*=====================================================================================
* 	OnClientConnected
* 
* 	In name mode, this is where we check the list for the name when client connects
=====================================================================================*/
public OnClientConnected(client)
{
	if(rage_auth_cache==0)
	{	
		if(!IsFakeClient(client))
		{	
			ignoreEvents = false;
			if(IsClientInGame(client)) ignoreEvents = ignoreEvents || IsClientTimingOut(client);
		}
		else { ignoreEvents = true;}
		//Gets rid of bot events and timeouts
		if(!ignoreEvents && shortCircuit!=1)
		{
			//Get the client's name
			GetClientName(client, playerName, sizeof(playerName));
			//May change this method if someone says its takes too much cpu
			ImplodeStrings(clientAuths,MAX_CLIENT_NAMES,",",fullText,MAX_TEXT_SIZE);
			
			//Find their name in the players cache
			if ((StrContains(fullText, playerName, false)) >= 0)
			{
				if(roundCount > 0) roundCount--;
				if(campaignCount > 0) campaignCount--;
				if (ReplaceString(fullText, MAX_TEXT_SIZE, playerName, "") > 0)
				{
					ExplodeString(fullText, ",", clientAuths, MAX_CLIENT_NAMES, MAX_NAME_LENGTH);
					if(rage_silent_cache==0) PrintToChatAll("\x03Rage\x05Meter: \x01Player %s rejoined. \x03%d\x01 quit this round... \x03%d\x01 in this campaign.", playerName, roundCount, campaignCount);
					if(rage_log_cache==1) LogMessage("RageMeter: Player %s rejoined. %d quit this round. %d in this campaign.", playerName, roundCount, campaignCount);
					if(play_sounds_cache & REJOINSOUNDFLAG) EmitSoundToAll(rejoin_sound_cache);
				}
			}
			else
			{
				if((rage_silent_cache==0) && (rage_fresh_cache==1)) PrintToChatAll("\x03Rage\x05Meter: \x01Fresh meat... \x03%d\x01 quit this round... \x03%d\x01 in this campaign.", roundCount, campaignCount);
				if(rage_log_cache==1) LogMessage("RageMeter: Fresh meat... %d quit this round. %d in this campaign.", roundCount, campaignCount);
				if(play_sounds_cache & FRESHSOUNDFLAG) EmitSoundToAll(fresh_sound_cache);
			}
			
			if(rage_debug_cache==1)
			{
				LogMessage("RageMeter(onClientConnected): Name->%s", playerName);
				LogMessage("RageMeter(onClientConnected): RoundCount->%d", roundCount);
				LogMessage("RageMeter(onClientConnected): ShortCircuit->%d", shortCircuit);
				LogMessage("RageMeter(onClientConnected): PlayerListText->%s", fullText);
				LogMessage("RageMeter(onClientConnected): PlayerListItem->%s", clientAuths[bufferCount]);
			}
			//Rpm Calculations
			if(rage_rpm_cache==1) RpmCalc();
		}
	}
}

/*=====================================================================================
* 	OnClientAuthorized
* 
* 	In ID mode, this is where we check the list for the steamid when client connects
=====================================================================================*/
public OnClientAuthorized(client)
{
	if(rage_auth_cache==1)
	{	
		if(!IsFakeClient(client))
		{	
			ignoreEvents = false;
			if(IsClientInGame(client)) ignoreEvents = ignoreEvents || IsClientTimingOut(client);
		}
		else { ignoreEvents = true;}
		//Gets rid of bot events and timeouts
		if(!ignoreEvents && shortCircuit!=1)
		{
			//Get the client's name for rejoin message
			GetClientName(client, playerName, sizeof(playerName));
			//Get the client's steamid
			GetClientAuthString(client, auth, sizeof(auth));
			//May change this method if someone says its takes too much cpu
			ImplodeStrings(clientAuths,MAX_CLIENT_NAMES,",",fullText,MAX_TEXT_SIZE);
			
			//Find their SteamID in the players cache
			if ((StrContains(fullText, auth, false)) >= 0)
			{
				if(roundCount > 0) roundCount--;
				if(campaignCount > 0) campaignCount--;
				if (ReplaceString(fullText, MAX_TEXT_SIZE, auth, "") > 0)
				{
					ExplodeString(fullText, ",", clientAuths, MAX_CLIENT_NAMES, AUTH_MAX_LENGTH);
					if(rage_silent_cache==0) PrintToChatAll("\x03Rage\x05Meter: \x01Player %s rejoined. \x03%d\x01 quit this round... \x03%d\x01 in this campaign.", playerName, roundCount, campaignCount);
					if(rage_log_cache==1) LogMessage("RageMeter: Player %s rejoined. %d quit this round. %d in this campaign.", playerName, roundCount, campaignCount);
					if(play_sounds_cache & REJOINSOUNDFLAG) EmitSoundToAll(rejoin_sound_cache);
				}
			}
			else
			{
				if((rage_silent_cache==0) && (rage_fresh_cache==1)) PrintToChatAll("\x03Rage\x05Meter: \x01Fresh meat... \x03%d\x01 quit this round... \x03%d\x01 in this campaign.", roundCount, campaignCount);
				if(rage_log_cache==1) LogMessage("RageMeter: Fresh meat... %d quit this round. %d in this campaign.", roundCount, campaignCount);
				if(play_sounds_cache & FRESHSOUNDFLAG) EmitSoundToAll(fresh_sound_cache);
			}
			
			if(rage_debug_cache==1)
			{
				LogMessage("RageMeter(onClientAuthorized): Name->%s", playerName);
				LogMessage("RageMeter(onClientAuthorized): SteamID->%s", auth);
				LogMessage("RageMeter(onClientAuthorized): RoundCount->%d", roundCount);
				LogMessage("RageMeter(onClientAuthorized): ShortCircuit->%d", shortCircuit);
				LogMessage("RageMeter(onClientAuthorized): PlayerListText->%s", fullText);
				LogMessage("RageMeter(onClientAuthorized): PlayerListItem->%s", clientAuths[bufferCount]);
			}
			
			//Rpm Calculations
			if(rage_rpm_cache==1) RpmCalc();
		}
	}
}
/*=====================================================================================
* 	OnClientDisconnect
* 
* 	Increment stats
=====================================================================================*/
public OnClientDisconnect(client)
{
	if(rage_auth_cache==0)
	{
		if(!IsFakeClient(client))
		{	
			ignoreEvents = false;
			if(IsClientInGame(client)) ignoreEvents = ignoreEvents || IsClientTimingOut(client);
		}
		else { ignoreEvents = true;}
		//Gets rid of bot events and timeouts
		if(!ignoreEvents)
		{
			playerName = "";
			//Get the client's name
			GetClientName(client, playerName, sizeof(playerName));
			//Determine if a vote has occurred and the player was kicked
			if(!(IsClientInKickQueue(client)) && (strcmp(vote_kick_player, playerName, true)== -1))
			{
				if(shortCircuit!=1)
				{
					//Always increment both counts when we get here
					roundCount++;
					campaignCount++;
					//May change this method if someone says its takes too much cpu
					ImplodeStrings(clientAuths,MAX_CLIENT_NAMES,",",fullText,MAX_TEXT_SIZE);
					//Check if name is missing from the player list
					if ((StrContains(fullText, playerName, false)) < 0)
					{
						if (bufferCount + 1 < MAX_CLIENT_NAMES)
						{
							bufferCount++;
						}
						else
						{
							bufferCount = 0;
						}
						strcopy(clientAuths[bufferCount],sizeof(playerName),playerName);
					}
					
					if(rage_silent_cache==0) PrintToChatAll("\x03Rage\x05Meter: \x03%d\x01 quit this round... \x03%d\x01 in this campaign.", roundCount, campaignCount);
					if(rage_log_cache==1) LogMessage("RageMeter(onClientDisconnect): %d quit this round. %d in this campaign.", roundCount, campaignCount);
					if(play_sounds_cache & RAGESOUNDFLAG) EmitSoundToAll(rage_sound_cache);
					if(rage_debug_cache==1)
					{
						
						LogMessage("RageMeter(onClientDisconnect): Name->%s", playerName);
						LogMessage("RageMeter(onClientDisconnect): RoundCount->%d", roundCount);
						LogMessage("RageMeter(onClientDisconnect): ShortCircuit->%d", shortCircuit);
						LogMessage("RageMeter(onClientDisconnect): PlayerListText->%s", fullText);
						LogMessage("RageMeter(onClientDisconnect): PlayerListItem->%s", clientAuths[bufferCount]);
					}
					//Rpm Calculations
					if(rage_rpm_cache==1) RpmCalc();
				}
			} 
			else
			{
				if (vote_kick_passed==1)
				{
					vote_kick_passed = 0;
					vote_kick_player = "";
				}
				kickedClients++;
				if((rage_kicked_cache==0) && (rage_silent_cache==0)) PrintToChatAll("\x03Rage\x05Meter: \x03%d\x01 players kicked in this campaign.", kickedClients);
				if(rage_log_cache==1) LogMessage("RageMeter: %d players have been kicked during this campaign.",kickedClients);
				if(play_sounds_cache & KICKSOUNDFLAG) EmitSoundToAll(kick_sound_cache);
			}
		}
	}
	else if(rage_auth_cache==1)
	{
		if(!IsFakeClient(client))
		{	
			ignoreEvents = false;
			if(IsClientInGame(client)) ignoreEvents = ignoreEvents || IsClientTimingOut(client);
		}
		else { ignoreEvents = true;}
		//Gets rid of bot events and timeouts
		if(!ignoreEvents)
		{
			playerName = "";
			//Get the client's name
			GetClientName(client, playerName, sizeof(playerName));
			if(!(IsClientInKickQueue(client)) && (strcmp(vote_kick_player, playerName, true)== -1))
			{
				if (shortCircuit!=1)
				{
					auth = "";
					GetClientAuthString(client,auth,sizeof(auth));
					//Always increment both counts when we get here
					roundCount++;
					campaignCount++;
					//May change this method if someone says its takes too much cpu
					ImplodeStrings(clientAuths,MAX_CLIENT_NAMES,",",fullText,MAX_TEXT_SIZE);
					//Check if name is missing from the player list
					if ((StrContains(fullText, auth, false)) < 0)
					{
						if (bufferCount + 1 < MAX_CLIENT_NAMES)
						{
							bufferCount++;
						}
						else
						{
							bufferCount = 0;
						}
						strcopy(clientAuths[bufferCount],sizeof(auth),auth);
					}
					
					if(rage_silent_cache==0) PrintToChatAll("\x03Rage\x05Meter: \x03%d\x01 quit this round... \x03%d\x01 in this campaign.", roundCount, campaignCount);
					if(rage_log_cache==1) LogMessage("RageMeter(onClientDisconnect): %d quit this round. %d in this campaign.", roundCount, campaignCount);
					if(play_sounds_cache & RAGESOUNDFLAG) EmitSoundToAll(rage_sound_cache);
					if(rage_debug_cache==1)
					{
						LogMessage("RageMeter(onClientDisconnect): Name->%s", playerName);
						LogMessage("RageMeter(onClientDisconnect): SteamID->%s", auth);
						LogMessage("RageMeter(onClientDisconnect): RoundCount->%d", roundCount);
						LogMessage("RageMeter(onClientDisconnect): ShortCircuit->%d", shortCircuit);
						LogMessage("RageMeter(onClientDisconnect): PlayerListText->%s", fullText);
						LogMessage("RageMeter(onClientDisconnect): PlayerListItem->%s", clientAuths[bufferCount]);
					}
					//Rpm Calculations
					if(rage_rpm_cache==1) RpmCalc();
				}
			} 
			else
			{
				if (vote_kick_passed==1)
				{
					vote_kick_passed = 0;
					vote_kick_player = "";
				}
				kickedClients++;
				if((rage_kicked_cache==0) && (rage_silent_cache==0)) PrintToChatAll("\x03Rage\x05Meter: \x03%d\x01 players kicked in this campaign.", kickedClients);
				if(rage_log_cache==1) LogMessage("RageMeter: %d players have been kicked during this campaign.",kickedClients);
				if(play_sounds_cache & KICKSOUNDFLAG) EmitSoundToAll(kick_sound_cache);
			}
		}
	}
}

/*=====================================================================================
* 	OnClientPutinServer
* 
* 	Display instructions if necessary
=====================================================================================*/
public OnClientPutInServer(client)
{
	//Only advertise if we are running silent and ad is turned on
	if ((rage_silent_cache==1) && (rage_ad_cache==1))
	{
		PrintToChat(client,"\x03Rage\x05Meter: \x01Type !rage or /rage in chat to view rage quit stats.");
	}	
	
	//Bad Hackjob starting here
	if((reset_type_cache==1) && (GetClientCount(false) == newClientCount) && (roundCount < 1))
	{
		if ((clientsBack < newClientCount))
		{
			clientsBack = clientsBack + 1;
		}
		else if(clientsBack == newClientCount)
		{
			CalculateStats();
			ResetAuths();
			newClientCount = 0;
		}
	}//Otherwise we have failed and shouldn't risk screwing up the campaign total
	//May just do without last and best rounds when in the non-standard reset type
}


/*=====================================================================================
* 	SayRage
* 	
* 	Output stats when client types !rage or /rage
=====================================================================================*/
public Action:SayRage(client, args)
{
	
	new Handle:panel = CreatePanel();
	new String:textHold[PANEL_STRING_SIZE];
	
	//Heading
	SetPanelTitle(panel, "Rage Quit Statistics");
	DrawPanelText(panel, " ");
	//Current RPM for this round
	if(rage_rpm_cache==1)
	{
		Format(textHold, PANEL_STRING_SIZE, "Current RPM:	%s", rpmText);
		DrawPanelText(panel, textHold);
	}
	//Current count for this round
	Format(textHold, PANEL_STRING_SIZE, "Current Round:	%d", roundCount);
	DrawPanelText(panel, textHold);
	//Last round
	Format(textHold, PANEL_STRING_SIZE, "Last Round:	%d", lastRound);
	DrawPanelText(panel, textHold);
	// Best
	Format(textHold, PANEL_STRING_SIZE, "Best Round:	%d", bestRound);
	DrawPanelText(panel, textHold);
	// Kicked
	Format(textHold, PANEL_STRING_SIZE, "Kick Count:	%d", kickedClients);
	DrawPanelText(panel, textHold);
	// Total
	Format(textHold, PANEL_STRING_SIZE, "Total: %d", campaignCount);
	DrawPanelText(panel, textHold);
	//Close
	Format(textHold, PANEL_STRING_SIZE, "Close");
	DrawPanelItem(panel, textHold);
	
	//Display
	SendPanelToClient(panel, client, RagePanelHandler, RAGE_STAT_VISIBLE_TIMEOUT);
	//Free
	CloseHandle(panel);
	
	
	//Logging
	if(rage_log_cache==1) {
		LogMessage("Current RPM:	%s", rpmText);
		LogMessage("Current Round:	%d", roundCount);
		LogMessage("Last Round:	%d", lastRound);
		LogMessage("Best Round:	%d", bestRound);
		LogMessage("Kick Count:	%d", kickedClients);
		LogMessage("Total: %d", campaignCount);
	}
	
	return Plugin_Handled;
}


public RagePanelHandler(Handle:menu, MenuAction:action, param1, param2) { return; }


/*=====================================================================================
* 	RpmTimerSprung - Just a wrapper
=====================================================================================*/
public Action:RpmTimerSprung(Handle:timer)
{
	RpmCalc();
	if((shortCircuit==1) &&(reset_type_cache==1) && (rpmTimer !=INVALID_HANDLE)) CloseHandle(timer);
	if(rage_debug_cache==1) LogMessage("RageMeter(RpmTimerSprung): Timer Running");
	return Plugin_Continue;
}

/*=====================================================================================
* 	RoundStartCheck - RoundEndCheck
* 
* 	Let the counting begin and end...at end do stats rollup
=====================================================================================*/
public Action:RoundStartCheck(Handle:event, const String:name[], bool:dontBroadcast)
{
	GetTime(rpmTime); //Start the clock for latest Round Start
	if(round_protect_cache==0)
	{
		//Start Counting 
		shortCircuit=0;
		
		//RPM Calc Timer
		if(rage_rpm_cache==1) rpmTimer = CreateTimer(rpm_calc_time_cache,RpmTimerSprung,_,TIMER_REPEAT);
		if(reset_type_cache==0)
		{
			//Reset RPM
			rpm=0.000;
			rpmText="0.000";
			//Reset roundCount and start using new player count
			roundCount = 0;
			bufferCount = 0;
		}
		else if(reset_type_cache==1)
		{
			//Only to Rectify the last/best round stats
			newClientCount = GetClientCount(false);
			//Reset RPM
			rpm=0.000;
			rpmText="0.000";
			
		}
		if(rage_debug_cache==1)
		{	
			LogMessage("RageMeter(RoundStartCheck): lastRound->%d", lastRound);
			LogMessage("RageMeter(RoundStartCheck): bestRound->%d", bestRound);
			LogMessage("RageMeter(RoundStartCheck): campaignCount->%d", campaignCount);
		}
		//Tell RoundEndCheck to process Only Once
		round_protect_cache = 1;
	}
	return Plugin_Continue;
}

public Action:RoundEndCheck(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(round_protect_cache == 1)
	{
		if((reset_type_cache==1) && (rpmTimer !=INVALID_HANDLE)) CloseHandle(rpmTimer);
		if(reset_type_cache==0)
		{
			//Stop Counting so we can get an accurate reference point.
			shortCircuit=1;
			CalculateStats();
		}
		else if(reset_type_cache==1)
		{
			//Only to Rectify the last/best round stats
			lastClientCount = GetClientCount(false);
			clientsBack = 0;
		}
		if(rage_silent_cache==0) PrintToChatAll("\x03Rage\x05Meter: \x03%d\x01 quit this round... \x03%d\x01 in this campaign.", roundCount, campaignCount);
		if(rage_silent_cache==0) PrintToChatAll("\x03Rage\x05Meter: \x03%d\x01 kicked in this campaign.", kickedClients);
		if(rage_debug_cache==1)
		{	
			LogMessage("RageMeter(RoundEndCheck): lastRound->%d", lastRound);
			LogMessage("RageMeter(RoundEndCheck): bestRound->%d", bestRound);
			LogMessage("RageMeter(RoundEndCheck): campaignCount->%d", campaignCount);
		}
		
		//Process Only Once
		round_protect_cache = 0;
	}
	return Plugin_Continue;
}

/*=====================================================================================
* 	VotePassed
* 	
* 	Detect a kick vote before the client is kicked so we can increment the correct stat
=====================================================================================*/
public Action:VotePassed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:voteDetails[VOTE_DETAILS_LENGTH];
	GetEventString(event,"details", voteDetails, VOTE_DETAILS_LENGTH);
	//Vote Kick
	if((StrContains(voteDetails, "#L4D_vote_passed_kick_player", false)) > -1) {
		vote_kick_passed = 1;
		GetEventString(event,"param1", vote_kick_player, MAX_NAME_LENGTH);
		if (rage_debug_cache==1) LogMessage("RageMeter(VotePassed): KickVote - Yes");
	}
	//Return to Lobby
	if((StrContains(voteDetails, "#L4D_vote_passed_return_to_lobby", false)) > -1) {
		shortCircuit = 1;
		if (rage_debug_cache==1) LogMessage("RageMeter(VotePassed): Return to Lobby - Yes");
	}
	//Change Campaign
	if((StrContains(voteDetails, "#L4D_vote_passed_mission_change", false)) > -1) {
		shortCircuit = 1;
		if (rage_debug_cache==1) LogMessage("RageMeter(VotePassed): Change Campaign - Yes");
	}
	
	if (rage_debug_cache==1) {
		LogMessage("RageMeter(VotePassed): VoteDetails->%s", voteDetails);
		GetEventString(event,"param1", voteDetails, VOTE_DETAILS_LENGTH);
		LogMessage("RageMeter(VotePassed): VoteParam->%s", voteDetails);
	}
	
}

/*=====================================================================================
* 	FinaleStartCheck - FinaleWinCheck - MissionLostCheck
* 
* 	Determine whether or not to stop counting based on the status of the finale
=====================================================================================*/
public Action:FinaleStartCheck(Handle:event, const String:name[], bool:dontBroadcast)
{
	finale_start_cache = 1;
	//Start Counting if not already doing so
	shortCircuit = 0;
	if (rage_debug_cache==1) LogMessage("RageMeter(FinaleStartCheck): finale_start_cache->%d", finale_start_cache);
	
}

public Action:FinaleWinCheck(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (finale_start_cache == 1)
	{
		shortCircuit = 1;
		if (rage_debug_cache==1) LogMessage("RageMeter(FinaleWinCheck): shortCircuit->%d", shortCircuit);
	}
	
}

public Action:MissionLostCheck(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (finale_start_cache == 1)
	{
		shortCircuit = 1;
		if (rage_debug_cache==1) LogMessage("RageMeter(MissionLostCheck): shortCircuit->%d", shortCircuit);
	}
	
}

/*=====================================================================================
* 	RpmCalc
* 
* 	Calculate the current Rages Per Minute based on the time played this round
=====================================================================================*/
public RpmCalc()
{
	new currTime[2], playTime = 0, count;
	count = roundCount;//seems silly to pass a global variable
	GetTime(currTime);
	
	if((currTime[0] - rpmTime[0])/60 > 0)
	{
		playTime = (currTime[0] - rpmTime[0])/60;
		
		if(FloatCompare(FloatDiv(float(count),float(playTime)),0.000) == 1){
			rpm = FloatDiv(float(count),float(playTime));
		}
		else
		{
			rpm = 0.000;
		}
		FloatToString(rpm,rpmText,RPM_PRECISION);
		if(rage_debug_cache==1)
		{
			LogMessage("RageMeter(RageCalc): currTime[0]->%d", currTime[0]);
			LogMessage("RageMeter(RageCalc): rpmTime[0]->%d", rpmTime[0]);
			LogMessage("RageMeter(RageCalc): roundCount->%d", count);
			LogMessage("RageMeter(RageCalc): playTime->%d", playTime);
			LogMessage("RageMeter(RageCalc): rpm->%s", rpmText);
		}
	}
}


/*=====================================================================================
* 	Calculate Stats
* 
* 	Calculate the last and best rounds
=====================================================================================*/
public CalculateStats()
{
	//Initialize the client name list on every round end if required
	if(reset_type_cache==0)
	{
		ResetAuths();
		//Do some simple Stats now since this is our reference point
		if(roundCount > bestRound) bestRound = roundCount;
		if(roundCount > 0) lastRound = roundCount;	
	}
	else if(reset_type_cache==1)
	{
		new count=0;
		if(lastClientCount - newClientCount > 0) count = lastClientCount - newClientCount;
		//Do some simple Stats now since this is our reference point
		if((roundCount + count) > bestRound) bestRound = roundCount + count;
		if((roundCount + count) > 0) lastRound = roundCount + count;
	}
}
/*=====================================================================================
* 	Reset Authorizations
=====================================================================================*/
public ResetAuths()
{
	new i;
	for(i=0;i<MAX_CLIENT_NAMES;i++) clientAuths[i] = "";
}
/*=====================================================================================
* 	PreCache Sounds
=====================================================================================*/
public CallCacheSounds()
{
	PrecacheSound(rage_sound_cache, true); 
	PrecacheSound(rejoin_sound_cache, true);
	PrecacheSound(fresh_sound_cache, true);
	PrecacheSound(kick_sound_cache, true);
}
/*=====================================================================================
* 	ConVar Functions
* 
=====================================================================================*/

public RageVersionStatic(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(convar, PLUGIN_VERSION);
}

public DebugChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	rage_debug_cache = StringToInt(newValue);
}

public SilentChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	rage_silent_cache = StringToInt(newValue);
}

public LogChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	rage_log_cache = StringToInt(newValue);
}

public KickChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	rage_kicked_cache = StringToInt(newValue);
}

public FreshMeatChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	rage_fresh_cache = StringToInt(newValue);
}

public ConnectAdvertiseChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	rage_ad_cache = StringToInt(newValue);
}

public RpmMeterChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	rage_rpm_cache = StringToInt(newValue);
}

public AuthTypeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(auth_protect_cache!=1)
	{
		SetConVarString(convar,newValue);
		rage_auth_cache = StringToInt(newValue);
		auth_protect_cache = 1;	
	}	
}

public ResetTypeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	reset_type_cache = StringToInt(newValue);
}

public RPMCalcTimeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	rpm_calc_time_cache = StringToFloat(newValue);
}
/*=====================================================================================
* 	Sound Related
=====================================================================================*/

public PlaySoundsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	play_sounds_cache = StringToInt(newValue);
}

public FreshSoundChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(fresh_sound_cache,SOUND_PATH_LIMIT,newValue);
}

public RejoinSoundChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(rejoin_sound_cache,SOUND_PATH_LIMIT,newValue);
}

public RageSoundChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(rage_sound_cache,SOUND_PATH_LIMIT,newValue);
}

public KickSoundChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(kick_sound_cache,SOUND_PATH_LIMIT,newValue);
}