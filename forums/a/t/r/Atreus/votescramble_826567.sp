/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

/*

Versions:
	 
	1.2 - May 12, 2009 (By Atreus and Robo_Leader)
		+ Added ability to have sounds play when you scramble!
	
	1.1 - January 11, 2009
		? Fixed bug where config file would not be loaded on server startup.
		? Players are no longer moved to spectator first.
		+ Added convar to choose trigger words. Done to avoid conflicts with other plugins.
		+ Added HUN translation (thanks to KhyrOO).
		+ Added POL translation (thanks to Zuko).
		+ Added event handling for changes in convar values.
		+ Performance of scramble is logged (as in, amount of players swapped).
		+ Added a new (better) algorithm for scrambling

	1.0 - initial release

*/

#include <sourcemod>
#include <tf2>
#include <sdktools>

#pragma dynamic 131072

#define PLUGIN_VERSION "1.2"
//#define ISDEBUGSCRAMBLE 1
#define TEAM_RED 3				// team variables.
#define TEAM_BLUE 2
#define TEAM_SPEC 1
#define TEAM_ARRAY_SIZE 4
#define FAILSAFE_DEPTH 5000
#define TRANSLATION_FILE "votescramble.phrases.txt"
#define ADMIN_RIGHTS ADMFLAG_KICK
#define CLIENTNAME_LENGTH 64
#define SCRAMBLE_WORD_LENGTH 32
#define SCRAMBLE_MAX_WORD_COUNT 10
#define SCRAMBLE_STRAT2_MINCHANGE 0.40
#define SCRAMBLE_STRAT2_MAXCHANGE 0.80

new Handle:listfile = INVALID_HANDLE;
new Handle:soundfiles = INVALID_HANDLE;
new Handle:g_varMinNeeded;								// Min percentage needed for vote to activate
new Handle:g_varMinTimePassed;							// Minimum time which should have passed before the vote can be activated
new Handle:g_varMinTimeLeft;							// Minimum time left on the map. If less is remaining, the vote cannot start
new Handle:g_varMinPlayers;								// Minimum amount of players to be available before the scramble can operate
new Handle:g_varScrambleDelay;							// Scramble delay
new Handle:g_varTriggerWords;							// Trigger words
new Handle:g_varStrategy;								// Scramble strategy (algorithm)

new Handle:g_scrambleRetryTimer;						// Retry timer for scramble
new Handle:g_scrambleTimer;								// Timer for scramble
new Handle:g_scrambleWords;								// Array of scramble words.

new bool:g_clientWantsScramble[MAXPLAYERS + 1];			// Array of flags indicating which clients want a scramble

new g_voterCount;										// Amount of people allowed to cast a vote (excludes fake clients)
new g_scrambleVotes;									// Amount of people who voted to scramble.
new g_scrambleStartTime;								// Time at which scramble will be available
new g_scrambleWordCount;								// Amount of scramble words. Cached for performance.

new String:soundlistfile[PLATFORM_MAX_PATH] = "";

new t;

enum ScrambleResult
{
	SCRAMBLE_ALREADYINPROGRESS,
	SCRAMBLE_TOOFEWPLAYERS,
	SCRAMBLE_COMPLETE
}

public Plugin:myinfo = 
{
	name = "TF2 Advanced Vote Scramble (With Sounds)",
	author = "Brainstorm",
	description = "Allows for players to vote for scrambling the teams. uses a custom scrambling algorithm. Now with Scramble Sounds!",
	version = PLUGIN_VERSION,
	url = "http://www.teamfortress.be"
}

public OnPluginStart()
{
	LoadTranslations(TRANSLATION_FILE);
	
	// init all of the vars
	CreateConVar("sm_scramble_version", PLUGIN_VERSION, "Version number of advanced vote scramble.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_varMinNeeded = CreateConVar("sm_scramble_percent", "0.65", "sm_scramble_percent - Minimum percent of people who should have voted before scramble will take effect.", 0, true, 0.0, true, 1.0);
	g_varMinTimePassed = CreateConVar("sm_scramble_timepassed", "180", "sm_scramble_timepassed - Minimum time which should have passed before the vote can be activated.", 0, true, 0.0, false, 0.0);
	g_varMinTimeLeft = CreateConVar("sm_scramble_timeleft", "0", "sm_scramble_timeleft - Minimum time left on the map. If less is remaining, the vote cannot start.", 0, true, 0.0, false, 0.0);
	g_varMinPlayers = CreateConVar("sm_scramble_minplayers", "3", "sm_scramble_minplayers - Minimum amount of players to be playing before the scramble can be selected.", 0, true, 3.0, false, 0.0);
	g_varScrambleDelay = CreateConVar("sm_scramble_delay", "5", "sm_scramble_delay - After a scramble has been initiated, this amount of seconds must pass before the scramble is executed.", 0, true, 0.0, true, 60.0);
	g_varTriggerWords = CreateConVar("sm_scramble_words", "!teamscramble, !scramble, scramble", "sm_scramble_words - Comma separated list of words that will allow users to vote for activating the scramble.");
	g_varStrategy = CreateConVar("sm_scramble_strategy", "2", "sm_scramble_strategy - algorithm used for scramble (1 = random shuffle, 2 = random shuffle with minimum change)", 0, true, 1.0);
	
	// hook convars changes for certain vars 
	HookConVarChange(g_varTriggerWords, ConvarChangeTriggerWords);
	HookConVarChange(g_varMinTimePassed, ConvarChangeTimePassed);
	HookConVarChange(g_varMinNeeded, ConvarChangeSuccessPercent);

	// admin commands
	RegAdminCmd("sm_scramblenow", Command_Scramble, ADMIN_RIGHTS, "sm_scramblenow - Scramble the teams.");
	RegAdminCmd("sm_scramblereset", Command_ScrambleReset, ADMIN_RIGHTS, "sm_scramblereset - Reset the scramble vote. Aborts a scramble if it's in progress and resets all player votes..");
	
	// register events
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	g_scrambleStartTime = GetTime();
	g_scrambleWords = CreateArray(SCRAMBLE_WORD_LENGTH);
	g_scrambleWordCount = 0;
	
	// load variables
	AutoExecConfig(true, "plugin.votescramble");

	soundfiles = CreateArray(PLATFORM_MAX_PATH+1);
}

public OnMapStart()
{
	ClearArray(soundfiles);
	t=1;
	CreateTimer(0.2, Load_Sounds);
	// reset vote & nominate vars
	g_voterCount = 0;
	g_scrambleVotes = 0;
	for (new i=1; i <= GetMaxClients(); i++)
	{
		g_clientWantsScramble[i] = false;
		
		if (IsClientInGame(i) && !IsFake(i))
		{
			g_voterCount++;
		}
	}
}

public PlaySound()
{
	new soundnumber = GetRandomInt(0,GetArraySize(soundfiles)-1); //number of sound in sound's array
	decl String:filetoplay[PLATFORM_MAX_PATH+1]; // path to choosen sound
	GetArrayString(soundfiles, soundnumber, filetoplay, sizeof(filetoplay)) //get path to choosen sound
	decl String:buffer[PLATFORM_MAX_PATH+1]; //command to client
	Format(buffer, sizeof(buffer), "play %s", (filetoplay), SNDLEVEL_GUNFIRE); //compile command
	for(new i = 1; i <= GetMaxClients(); i++) 
	if(IsClientConnected(i) && !IsFakeClient(i) && IsClientInGame(i)) //for all real and in-game clients
	{
		ClientCommand((i), buffer); //send command to client
	}
	t=1;
	CreateTimer(5.0, Load_Sounds);
}

public OnMapEnd()
{
	ClearArray(soundfiles);
}

public Action:Load_Sounds(Handle:timer)
{
	// precache sounds, loop through sounds
	BuildPath(Path_SM,soundlistfile,sizeof(soundlistfile),"configs/votescramblesounds.cfg");
	if(!FileExists(soundlistfile)) {
		SetFailState("scramblescriptsound.cfg not parsed...file doesnt exist!");
	}else{
		if (listfile != INVALID_HANDLE){
			CloseHandle(listfile);
		}
		listfile = CreateKeyValues("soundlist");
		FileToKeyValues(listfile,soundlistfile);
		KvRewind(listfile);
		if (KvGotoFirstSubKey(listfile)){
			do{
				decl String:filelocation[PLATFORM_MAX_PATH+1];
				decl String:dl[PLATFORM_MAX_PATH+1];
				decl String:file[8];
				t = KvGetNum(listfile, "count", 1);
				new download = KvGetNum(listfile, "download", 1);
				for (new i = 0; i <= t; i++){
					if (i){
						Format(file, sizeof(file), "file%d", i);
					}else{
						strcopy(file, sizeof(file), "file");
					}
					filelocation[0] = '\0';
					KvGetString(listfile, file, filelocation, sizeof(filelocation), "");
					if (filelocation[0] != '\0'){
						Format(dl, sizeof(dl), "sound/%s", filelocation);
						PrecacheSound(filelocation, true);
						PushArrayString(soundfiles, filelocation);
						if(download && FileExists(dl)){
							AddFileToDownloadsTable(dl);
						}
					}
				}
			} while (KvGotoNextKey(listfile));
		}
		else{
			SetFailState("scramblescriptsound.cfg not parsed...No subkeys found!");
		}
	}
	return Plugin_Handled;
}

public OnConfigsExecuted()
{
	UpdateScrambleStartTime();
	UpdateScrambleWords();
}

public ConvarChangeTriggerWords(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UpdateScrambleWords();
}

public ConvarChangeTimePassed(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UpdateScrambleStartTime();
}

public ConvarChangeSuccessPercent(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	StartScrambleIfNeeded();
}

UpdateScrambleWords()
{
	ClearArray(g_scrambleWords);
	g_scrambleWordCount = 0;
	
	decl String:allWords[SCRAMBLE_MAX_WORD_COUNT * SCRAMBLE_WORD_LENGTH];
	GetConVarString(g_varTriggerWords, allWords, sizeof(allWords));
	
	decl String:splitted[SCRAMBLE_MAX_WORD_COUNT][SCRAMBLE_WORD_LENGTH];
	new count = ExplodeString(allWords, ",", splitted, SCRAMBLE_MAX_WORD_COUNT, SCRAMBLE_WORD_LENGTH);
	if (count <= 0)
	{
		PushArrayString(g_scrambleWords, "!teamscramble");
		g_scrambleWordCount++;
		LogError("The sm_scramble_words variable is not set or set to an incorrect value. Defaulting to the !teamscramble command.");
		return;
	}
	
	for (new i=0; i < count; i++)
	{
		TrimString(splitted[i]);
		PushArrayString(g_scrambleWords, splitted[i]);
		g_scrambleWordCount++;
	}
}

UpdateScrambleStartTime()
{
	// set scramble start time
	g_scrambleStartTime = GetTime() + GetConVarInt(g_varMinTimePassed);
	
	// compensate for late-loading the plugin
	new timeLeft, timeLimit;
	GetMapTimeLeft(timeLeft);
	GetMapTimeLimit(timeLimit);
	if (timeLeft >= 0 && timeLimit > 0)
	{
		g_scrambleStartTime -= ((timeLimit * 60) - timeLeft);
	}
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	if (!IsFake(client))
	{
		g_voterCount++;
		g_clientWantsScramble[client] = false;
	}
	return true;
}

public OnClientDisconnect(client)
{
	if (!IsFake(client))
	{
		if (g_clientWantsScramble[client])
		{
			g_scrambleVotes--;
		}
		g_voterCount--;
		g_clientWantsScramble[client] = false;
		
		StartScrambleIfNeeded();
	}
}

public Action:Command_Say(client, args)
{
	if (client <= 0 || !IsClientInGame(client))
	{
		return Plugin_Continue;
	}

	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	// compensate for quotation marks
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	// loop through word list to see if any of them matches the say text
	new bool:isTriggerWord = false;
	decl String:triggerWord[SCRAMBLE_WORD_LENGTH];
	for (new i=0; !isTriggerWord && i < g_scrambleWordCount; i++)
	{
		GetArrayString(g_scrambleWords, i, triggerWord, SCRAMBLE_WORD_LENGTH);
		isTriggerWord = (strcmp(triggerWord, text[startidx], false) == 0);
		PrintToServer("Compared %s to %s to result %d", triggerWord, text[startidx], isTriggerWord);
	}
	
	// if player want to trigger scramble, handle it
	if (isTriggerWord)
	{
		new timeLeft;
		GetMapTimeLeft(timeLeft);
		new minTimeLeft = GetConVarInt(g_varMinTimeLeft);
		new minPlayersForStart = GetConVarInt(g_varMinPlayers);
		new minPlayers = RoundToCeil(GetConVarFloat(g_varMinNeeded) * float(g_voterCount));
		
		if (g_clientWantsScramble[client])
		{
			PrintToChat(client, "%T", "Already Voted", client, 0x04, minPlayers, g_scrambleVotes);
			return Plugin_Handled;
		}
		else if (GetTime() < g_scrambleStartTime)
		{
			PrintToChat(client, "%T", "Not Yet Available", client, 0x04, GetConVarInt(g_varMinTimePassed), (g_scrambleStartTime - GetTime()));
			return Plugin_Handled;
		}
		else if (timeLeft < minTimeLeft && minTimeLeft > 0)
		{
			PrintToChat(client, "%T", "Not Available Anymore", client, 0x04);
			return Plugin_Handled;
		}
		else if ((GetTeamClientCount(TEAM_BLUE) + GetTeamClientCount(TEAM_RED)) < minPlayersForStart)
		{
			PrintToChat(client, "%T", "Not Enough Players", client, 0x04, minPlayersForStart);
			return Plugin_Handled;
		}
		else
		{
			g_scrambleVotes++;
			g_clientWantsScramble[client] = true;
			decl String:name[64];
			GetClientName(client, name, sizeof(name));
			PrintToChat(client, "%T", "Your Vote Recorded", client, 0x04, minPlayers, g_scrambleVotes);
			PrintToChatAll("%T", "Vote Cast", LANG_SERVER, 0x04, name, g_scrambleVotes, minPlayers);
			StartScrambleIfNeeded();
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

// starts scramble if enough players voted for it. If the admin requested
// param is set, then the scramble will occur even if there are too few players.
StartScrambleIfNeeded(bool:isAdminRequested=false, adminClient=0)
{
	new bool:isInProgress = (g_scrambleRetryTimer != INVALID_HANDLE) || (g_scrambleTimer != INVALID_HANDLE);
	if (isInProgress)
	{
		if (isAdminRequested)
		{
			ReplyToCommand(adminClient, "%t", "Start Failed In Progress");
		}
		else
		{
			if (g_scrambleRetryTimer == INVALID_HANDLE)
			{
				g_scrambleRetryTimer = CreateTimer(2.0, Timer_StartScramble);
			}
		}
		return;
	}
	
	new Float:percentVoted = 0.0;
	if (g_scrambleVotes > 0)
	{
		percentVoted = float(g_scrambleVotes) / float(g_voterCount);
	}
	if (percentVoted < GetConVarFloat(g_varMinNeeded))
	{
		if (!isAdminRequested)
		{
			return;
		}
	}
	
	if (isAdminRequested)
	{
		ReplyToCommand(adminClient, "%t", "Admin Start Scramble");
	}
	
	// execute scramble
	ExecuteTimedScramble();
	
}

public Action:Timer_StartScramble(Handle:timer)
{
	g_scrambleRetryTimer = INVALID_HANDLE;
	StartScrambleIfNeeded();
	return Plugin_Stop;
}

public Action:Command_Scramble(client, args)
{
	LogAdminAction(client, "%s is forcing a scramble.");
	StartScrambleIfNeeded(true, client);
	return Plugin_Handled;
}

public Action:Command_ScrambleReset(client, args)
{
	ResetScrambleState();
	AbortCurrentScramble();
	ReplyToCommand(client, "%T", "Scramble Reset", client);
	LogAdminAction(client, "%s has reset the vote.");
	return Plugin_Handled;
}

LogAdminAction(client, const String:format[])
{
	decl String:adminName[CLIENTNAME_LENGTH];
	if (client <= 0)
	{
		strcopy(adminName, sizeof(adminName), "Console");
	}
	else
	{
		GetClientName(client, adminName, sizeof(adminName));
	}
	LogMessage(format, adminName);
}

ResetScrambleState()
{
	g_scrambleVotes = 0;
	for (new i=1; i <= GetMaxClients(); i++)
	{
		g_clientWantsScramble[i] = false;
	}
}

AbortCurrentScramble()
{
	if (g_scrambleTimer != INVALID_HANDLE)
	{
		KillTimer(g_scrambleTimer);
		g_scrambleTimer = INVALID_HANDLE;
	}
}

ExecuteTimedScramble()
{
	AbortCurrentScramble();
	new scrambleDelay = GetConVarInt(g_varScrambleDelay);
	new Float:delay = 0.0 + scrambleDelay;		// dirty way of converting to float here.
	g_scrambleTimer = CreateTimer(delay, Timer_Scramble);
	if (scrambleDelay > 0)
	{
		PrintCenterTextAll("%T", "Scramble Start (center)", LANG_SERVER, scrambleDelay);
		PrintToChatAll("%T", "Scramble Start (chat)", LANG_SERVER, 0x04, scrambleDelay);
	}
	else
	{
		PrintCenterTextAll("%T", "Scramble Start Now", LANG_SERVER);
	}
}

public Action:Timer_Scramble(Handle:timer)
{
	g_scrambleTimer = INVALID_HANDLE;
	new ScrambleResult:result = ExecuteScramble();
	
	switch (result)
	{
		case SCRAMBLE_COMPLETE:
		{
			PrintToChatAll("%T", "Scramble Result Success", LANG_SERVER, 0x04);
		}
		case SCRAMBLE_TOOFEWPLAYERS:
		{
			PrintToChatAll("%T", "Scramble Result Playercount", LANG_SERVER, 0x04);
		}
		case SCRAMBLE_ALREADYINPROGRESS:
		{
			// do nothing
		}
	}
}

ScrambleResult:ExecuteScramble()
{
	// ignore if a scramble is in progress
	if (g_scrambleTimer != INVALID_HANDLE)
	{
		return SCRAMBLE_ALREADYINPROGRESS;
	}
	
	PlaySound();
	
	// count the players on red and blue and team sizes
	new clientCount = GetMaxClients();
	new redCount = GetTeamClientCount(TEAM_RED);
	new bluCount = GetTeamClientCount(TEAM_BLUE);
	
	// subtract bots from both red and blu
	for (new i=1; i <= clientCount; i++)
	{
		if (IsClientConnected(i) && IsFake(i) && IsClientInGame(i))
		{
			new team = GetClientTeam(i);
			switch (team)
			{
				case TEAM_BLUE:
					bluCount--;
				case TEAM_RED:
					redCount--;
			}
		}
	}
	
	new totalPlayers = redCount + bluCount;			// total amount of active players
	new targetSize = totalPlayers / 2;				// how large should each team be
	new bool:isUneven = ((totalPlayers % 2) != 0);	// whether teams will be uneven
	
	new minPlayersForStart = GetConVarInt(g_varMinPlayers);
	if (totalPlayers < minPlayersForStart)
	{
		ResetScrambleState();
		return SCRAMBLE_TOOFEWPLAYERS;
	}
	
	// decide on the strategy
	new strategy = GetConVarInt(g_varStrategy);
	if (strategy == 1)
	{
		
		return Scramble_Strategy1(clientCount, targetSize, isUneven);
	}
	else
	{
		
		return Scramble_Strategy2(clientCount, redCount, bluCount, targetSize, isUneven);
	}
	
}

ScrambleResult:Scramble_Strategy1(clientCount, targetSize, bool:isUneven)
{	
	// determine current team for everyone
	new playersTeam[clientCount + 1];
	new playersInitialTeam[clientCount + 1];
	DetermineCurrentTeams(clientCount, playersInitialTeam, playersTeam, TEAM_BLUE);

	// determine amount of players on red (half of the available players + one more)
	new clientPickCount = targetSize;
	if (isUneven)
	{
		if (GetRandomInt(0, 1) == 1)
		{
			clientPickCount += 1;
		}
	}

	// determine which players will switch to red
	/* This is just a simple solution: randomly pick players until we've found enough red players
	 * This code uses a failsafe counter to prevent possible bugs from hanging the server. Although
	 * testing filtered out all known bugs, it doen't mean there aren't any... */
	new failsafe = 0;
	for (new i=0; i < clientPickCount; i++)
	{
		new index = 0;
		do
		{
			index = GetRandomInt(1, clientCount);
			failsafe++;
		}
		while ((playersTeam[index] != TEAM_BLUE) && failsafe < FAILSAFE_DEPTH);
			
		if (failsafe < FAILSAFE_DEPTH)
		{
			playersTeam[index] = TEAM_RED;
		}
	}
	
	if (failsafe >= FAILSAFE_DEPTH)
	{
		LogMessage("Failsafe activated! This might indicate a bug or other problems");
	}

	// reset state
	ResetScrambleState();
	
	// scramble
	PerformTeamSwaps(clientCount, playersInitialTeam, playersTeam);
	
	return SCRAMBLE_COMPLETE;
}

ScrambleResult:Scramble_Strategy2(clientCount, redCount, bluCount, targetSize, bool:isUneven)
{
	// put amounts into array for easier manipulation
	new teamSize[TEAM_ARRAY_SIZE];
	for (new i=0; i < TEAM_ARRAY_SIZE; i++)
	{
		teamSize[i] = 0;
	}
	teamSize[TEAM_BLUE] = bluCount;
	teamSize[TEAM_RED] = redCount;
	
	// determine current team for everyone. Set new team to spec
	new playersTeam[clientCount + 1];
	new playersInitialTeam[clientCount + 1];
	DetermineCurrentTeams(clientCount, playersInitialTeam, playersTeam, 0);
	
	// if there's an uneven amount of players, pick one person to be kept out of the algorithm. This
	// players will be put on a random team afterwards.
	new extraPlayerIndex = -1;
	if (isUneven)
	{
		do
		{
			extraPlayerIndex = GetRandomInt(1, clientCount);
		}
		while (playersInitialTeam[extraPlayerIndex] == 0);
			
		// decrement team size and act as if this player is not ingame
		teamSize[playersInitialTeam[extraPlayerIndex]]--;
		playersTeam[extraPlayerIndex] = 0;
		playersInitialTeam[extraPlayerIndex] = 0;
	}
	
	new changeCount = 0;			// this var will count the amount of changes in player teams
	
	// balance teams by putting players from the largest team to the smallest team
	if (FloatAbs(1.0 * (teamSize[TEAM_BLUE] - teamSize[TEAM_RED])) > 1)
	{
		new largerTeam, smallerTeam;
		if (bluCount > redCount)
		{
			largerTeam = TEAM_BLUE;
			smallerTeam = TEAM_RED;
		}
		else
		{
			largerTeam = TEAM_RED;
			smallerTeam = TEAM_BLUE;
		}
		
		do
		{
			// find a player that can be balanced from larger to smaller
			// player must be on the largest team and not yet have another team assigned.
			new playerIndex;
			do
			{
				playerIndex = GetRandomInt(1, clientCount);
			}
			while (playersInitialTeam[playerIndex] != largerTeam || playersTeam[playerIndex] != 0);
				
			playersTeam[playerIndex] = smallerTeam;
			changeCount++;
			teamSize[largerTeam]--;
			teamSize[smallerTeam]++;
		}
		while (FloatAbs(1.0 * (teamSize[TEAM_BLUE] - teamSize[TEAM_RED])) > 1);
	}
	
	// at this point, teams should be equal in size. A certain amount of changes has been made (zero or more).
	// Calculate how many changes we are allowed to make. This is randomly based on the min & max constraints.
	new Float:changePercent = GetRandomFloat(SCRAMBLE_STRAT2_MINCHANGE, SCRAMBLE_STRAT2_MAXCHANGE);
	new changeCountTarget = RoundToFloor(changePercent * targetSize);						// desired amount of changes
	new changeCountMin = RoundToFloor(SCRAMBLE_STRAT2_MINCHANGE * targetSize);			// minimum amount of changes
	new changeCountMax = RoundToFloor(SCRAMBLE_STRAT2_MAXCHANGE * targetSize);			// maximum amount of changes
	
	//PrintToServer("DBG: pc %f  target %d min %d max %d  change %d", changePercent, changeCountTarget, changeCountMin, changeCountMax, changeCount);
	
	// for safety, clip the min/max values to acceptable values
	if (changeCountMin < 0)
	{
		changeCountMin = 0;
	}
	if (changeCountMax > targetSize)
	{
		changeCountMax = targetSize;
	}
	
	// if min is 0 and there's room for at least 1 change, then add 1 to min
	if (changeCountMin == 0 && changeCountMax > changeCountMin)
	{
		changeCountMin++;
	}
	
	// clip target count to min and max
	if (changeCountTarget < changeCountMin)
	{
		changeCountTarget = changeCountMin;
	}
	if (changeCountTarget > changeCountMax)
	{
		changeCountTarget = changeCountMax;
	}
	
	// count amount of players available for team swap on each team
	new teamSizeAvailable[TEAM_ARRAY_SIZE];
	for (new i=0; i < TEAM_ARRAY_SIZE; i++)
	{
		teamSizeAvailable[i] = 0;
	}
	for (new i=0; i < clientCount; i++)
	{
		if (playersInitialTeam[i] > 0 && playersTeam[i] == 0)
		{
			teamSizeAvailable[playersInitialTeam[i]]++;
		}
	}
	
	// swap players until the target count has been reached or there are no players left to swap
	while (changeCount < changeCountTarget && teamSizeAvailable[TEAM_BLUE] > 0 && teamSizeAvailable[TEAM_RED] > 0)
	{
		// pick a player on each opposing team and swap them
		new index1, index2;
		do
		{
			index1 = GetRandomInt(1, clientCount);
		}
		while (playersTeam[index1] != 0 || playersInitialTeam[index1] != TEAM_RED);
		do
		{
			index2 = GetRandomInt(1, clientCount);
		}
		while (playersTeam[index2] != 0 || playersInitialTeam[index2] != TEAM_BLUE);
		
		// swap them
		playersTeam[index2] = TEAM_RED;
		playersTeam[index1] = TEAM_BLUE;
		changeCount++;
		teamSizeAvailable[TEAM_BLUE]--;
		teamSizeAvailable[TEAM_RED]--;
	}
	
	// handle the extra player, if it's available
	if (extraPlayerIndex > 0)
	{
		playersInitialTeam[extraPlayerIndex] = GetClientTeam(extraPlayerIndex);
		new inSecondTeam = GetRandomInt(0, 1);
		if (inSecondTeam == 0)
		{
			playersTeam[extraPlayerIndex] = TEAM_BLUE;
		}
		else
		{
			playersTeam[extraPlayerIndex] = TEAM_RED;
		}
	}
	
	//set teams for players that did not change
	for (new i=1; i <= clientCount; i++)
	{
		if (playersTeam[i] == 0 && playersInitialTeam[i] > 0)
		{
			playersTeam[i] = playersInitialTeam[i];
		}	
	}
	
	// reset state
	ResetScrambleState();
	
	// scramble
	PerformTeamSwaps(clientCount, playersInitialTeam, playersTeam);
	
	return SCRAMBLE_COMPLETE;
}

DetermineCurrentTeams(clientCount, playersInitialTeam[], playersTeam[], defaultNewTeam = 0)
{
	playersTeam[0] = 0;
	playersInitialTeam[0] = 0;
	for (new i=1; i <= clientCount; i++)
	{
		new currentTeam = 0;
		if (IsClientConnected(i) && !IsFake(i) && IsClientInGame(i))
		{
			currentTeam = GetClientTeam(i);
		}
		
		if (currentTeam == TEAM_BLUE || currentTeam == TEAM_RED)
		{
			playersInitialTeam[i] = currentTeam;
			playersTeam[i] = defaultNewTeam;
		}
		else
		{
			playersTeam[i] = 0;
			playersInitialTeam[i] = 0;
		}
	}
}

PerformTeamSwaps(clientCount, playersInitialTeam[], playersTeam[])
{
	new changeCount = 0;
	new changeMax = 0;
	
	for (new i=1; i <= clientCount; i++)
	{
		if (playersTeam[i] > 0)
		{
			// change teams only if needed.
			if (playersTeam[i] != playersInitialTeam[i])
			{
				// change team & respawn
				ChangeClientTeam(i, playersTeam[i]);
				changeCount++;
			}
			else		// change to spec and respawn
			{
				//ChangeClientTeam(i, TEAM_SPEC);				
			}
			TF2_RespawnPlayer(i);
			changeMax++;
		}
	}
	
	LogMessage("%d of %d players were forced to changed teams.", changeCount, changeMax);
}

bool:IsFake(client)
{
#if defined ISDEBUGSCRAMBLE
	return false;
#else
	return IsFakeClient(client);
#endif
}