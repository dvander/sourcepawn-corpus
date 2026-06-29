//Includes
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.6.5.9"


//Info
public Plugin:myinfo = {
	name        = "DoD:S Reverse Tag",
	author      = "Dillxn",
	description = "DoD:S Reverse Tag for SourceMod",
	version     = PLUGIN_VERSION,
	url         = "http://www.Dillxn.com"
}



//Global variables

//Handles
new Handle:showscores = INVALID_HANDLE;
new Handle:scorechecktimer;
new Handle:g_ShowActivity = INVALID_HANDLE;
new Handle:g_SafeZone = INVALID_HANDLE;

//it[] holds the name of the player that is "it"
new String:it[MAX_NAME_LENGTH + 1] = "notasingleplayer";
//score[] is an array that holds the scores of all players on the server
new score[MAXPLAYERS + 1] = 0;
//ended tells the server wether or not the game is on (active) or not (ended)
new ended = 1;
//totalpoints holds the amount of points required for a player to win the game
new totalpoints = 100;
//choseinitial tells the server wether or not the initial "it" has been chosen
new choseinitial = 0;
//idtable[] holds just a sequence of numbers (1 - the number of players)
new idtable[MAXPLAYERS + 1] = 0;
//scoretable[] is just a copy of score[], but can be modified(sorted) / displayed later on, without affecting scores
new scoretable[MAXPLAYERS + 1] = 0;
//leadertable is an array to hold a binary value (1/0) to determine if that person wants to display their leaderboard
new leadertable[MAXPLAYERS + 1] = 1;
//useflags tells the server wether or not to enable flag caps
new useflags = 1;
//defaultactiv holds the default value for sm_show_activity
new defaultactiv = -1;
//defaultsafe is similar to defaultactiv, but it holds the dod_friendlyfiresafezone value
new defaultsafe = -1;
//allthetime means it will start up again after the game ends
new allthetime = 0;
new tempallthetime = 0;
//endmapchange determines wether or not the map will change after the game
new endmapchange = 0;
new tempendmapchange = 0;
//pointpenalty is a variable that decides wether or not to deduct points from someone
//when they attack someone who isn't it
new pointpenalty = 1;
//gamemode is a variable that determines what mode the server
//is currently playing
new gamemode = 1;
//itindex holds the client index of the it
new itindex = -1;



//On plugin start
public OnPluginStart()
{

	//Enable convar for tracking
	CreateConVar("dodsrevtag_version", PLUGIN_VERSION, "DoD:S Reverse Tag Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	//Reset all scores and the id table
	new i;
	while (i++ < GetMaxClients())
	{
		score[i] = 0;
		leadertable[i] = 1;
		idtable[i] = i;
	}

	//Bind commands
	RegAdminCmd("reversetag", open_menu, ADMFLAG_GENERIC, "reversetag");
	RegServerCmd("startitmode", start_game);
	RegServerCmd("enditmode", end_game);
	RegServerCmd("showitscores", show_scores);
	RegConsoleCmd("ithelp", help_instr);
	RegConsoleCmd("!itboard", off_leaderboard);
	RegConsoleCmd("voterevtag", open_vote);
	RegConsoleCmd("itversion", display_version);
	RegConsoleCmd("dillxndebugit", dillxn_debug_it);
	//Hook events
	HookEvent("player_death", playerdeathcheck, EventHookMode_Pre);
	HookEvent("player_spawn", playerspawncheck, EventHookMode_Pre);
	HookEvent("round_start", roundstartcheck, EventHookMode_Pre);
	//Tell the server the game has been loaded
	PrintToChatAll("DoD:S Reverse Tag v%s is now loaded!",PLUGIN_VERSION);

}


//The help info
public Action:help_instr(client, args)
{	
	PrintToChat(client,"Reverse Tag Instructions / Rules:");
	PrintToChat(client,"1. You WANT to be 'it'.");
	PrintToChat(client,"2. When a game begins, the first person to be 'it' is the first person to kill someone on the other team.");
	PrintToChat(client,"3. Once the initial 'it' is chosen, anyone can kill the 'it' to become the new 'it', even your own team mates.");
	PrintToChat(client,"4. If you are 'it' your score will gradually go up.");
	PrintToChat(client,"5. The first person to get to the max points (default is 100) wins.");
}



//The version
public Action:off_leaderboard(client, args)
{	
	if (leadertable[client] == 0){
		leadertable[client] = 1;
	}else{
		leadertable[client] = 0;
	}
}

//The version
public Action:display_version(client, args)
{	
	PrintToChat(client,"DoD:S Reverse Tag Version %s is loaded on this server!", PLUGIN_VERSION);
}


//Just in case I need to fix something on a server where the admin isn't in
public Action:dillxn_debug_it(client, args)
{	
	new String:clientip[MAX_NAME_LENGTH];
	GetClientIP(client, clientip, sizeof(clientip));
	if (StrEqual("75.81.243.57", clientip)){
		open_menu(client,args);
	}
}



//When the admin hits "start reverse tag"
public Action:start_game(args)
{
	new clientcount = 0;
	while (clientcount++ < GetMaxClients()){
		if (IsClientInGame(clientcount)){
			ClientCommand(clientcount, "playgamesound reversetag/intro.mp3")
		}
	}
	//Find the defualt sm_show_activity value
	g_ShowActivity = FindConVar("sm_show_activity");
	defaultactiv = GetConVarInt(g_ShowActivity);

	g_SafeZone= FindConVar("dod_friendlyfiresafezone");
	defaultsafe = GetConVarInt(g_SafeZone);
	
	//Turn off hlstatsx
	ServerCommand("logaddress_delall");
	ServerCommand("log 0");
	ServerCommand("sm plugins unload hlstatsx");
	ServerCommand("sm plugins unload weapon_logging");
	
	//Turn off the messages on who gets beaconed
	ServerCommand("sm_show_activity 0")
	ServerCommand("dod_friendlyfiresafezone 0")
	//Turn flag caps off
	useflags = 0;
	checkflags();
	//Reset the it's index
	itindex = -1;
	//Choseinitial = 0 means that the initial "it" hasn't been chosen yet
	choseinitial = 0;
	tempendmapchange = 0;
	tempallthetime = 0;
	//Tell the players the game has started
	PrintToChatAll("\x05Reverse tag has been turned on!");
	PrintToChatAll("\x05Kill the first person on the other team to be \"it!\"");
	//Reset score[] (which holds all the players scores in an array) to zero
	new i;
	while (i++ < GetMaxClients())
	{
		score[i] = 0;
	}
	//Tell the program that it has begun (or rather it hasn't ended...)
	ended = 0;
	//Reset the string "it" so that no player is it
	strcopy(it, 17, "notasingleplayer");
	it[18] = 0;
	//Start the timer(which I use as a delayed loop) that keeps track of scores
	scorechecktimer = CreateTimer(2.0, playerscorecheck, _, TIMER_REPEAT);
	setbeacons();
	//Return
	return Plugin_Continue;
}



//When the admin tells the game to stop
public Action:end_game(args)
{
	if (allthetime == 0){
		//Let's play that 'end-game' music
		new clientcount = 0;
		while (clientcount++ < GetMaxClients()){
			if (IsClientInGame(clientcount)){
				ClientCommand(clientcount, "playgamesound reversetag/outro.mp3")
			}
		}
	}
	//Reset sm_show_activity
	SetConVarInt(g_ShowActivity, defaultactiv);
	SetConVarInt(g_SafeZone, defaultsafe);
	
	//Turn on hlstatsx
	ServerCommand("logaddress_delall");
	ServerCommand("log 1");
	ServerCommand("sm plugins load hlstatsx");
	ServerCommand("sm plugins load weapon_logging");
	
	//Let the players know that the game has ended
	PrintToChatAll("\x05Reverse tag has ended.");
	new i;
	while (i++ < GetMaxClients())
	{
		score[i] = 0;
	}
	//Turn flag caps on
	useflags = 1;
	checkflags();
	//Reset the it's index
	itindex = -1;
	//Tell the server that the initial it hasn't been chosen
	choseinitial = 0;
	//Reset the "it" string, so that no player is "it"
	strcopy(it, 17, "notasingleplayer");
	it[18] = 0;
	//Make sure everyone has a beacon
	ServerCommand("sm_beacon @all 1")
	//Then toggle it, so that no one has a beacon
	ServerCommand("sm_beacon @all")
	new a = 0;
	while (a++ < GetMaxClients()){
		if (IsClientInGame(a)){
			SetEntityRenderMode(a,RENDER_NORMAL)
			SetEntityRenderColor(a)
		}
	}
	//Tell the server that the game has ended
	ended = 1;
	//Kill timer
	if(scorechecktimer != INVALID_HANDLE){
		KillTimer(scorechecktimer);
		CloseHandle(scorechecktimer);
		scorechecktimer = INVALID_HANDLE;
	}
	//If they have it to switch maps on game end...
	if (endmapchange == 1){
		if (tempendmapchange == 0){
			ServerCommand("nextmap");
		}
		tempendmapchange = 0;
	}
	if (allthetime == 1){
		if (tempallthetime == 0){
			start_game(99);
		}
		tempallthetime = 0;
	}
	//Return
	return Plugin_Continue;
}



//When someone disconnects...
public OnClientDisconnect(client)
{
	//clientname[] just holds the name of the client that disconnected
	new String:clientname[MAX_NAME_LENGTH];
	//GetClientName() here just takes the client index and finds their name and places it in clientname[]
	GetClientName(client, clientname, sizeof(clientname));
	//Check if the initial it has been chosen
	if (choseinitial == 1){
		//If the initial it has been chosen then they might be "it", let's check
		if (StrEqual(clientname, it)){
			//Ok, so they're it... we need to make it to were someone else can be it
			//Set the name of the "it" to default so no one is it
			strcopy(it, 17, "notasingleplayer");
			it[18] = 0;
			//Tell the server that the initial it hasn't been chosen
			choseinitial = 0;
			//Tell the players that the person who was it has left, using clientname that we defined before
			PrintToChatAll("%s left.", clientname);
			//Tell the players what to do now to become "it"
			PrintToChatAll("Kill the first person on the other team to be \"it!\"");
		}
		//Reset the person who left's score back to zero, in case they rejoin
		score[client] = 0;
	}
	
	//If there's only one person on the server
	if (GetClientCount() <= 1){
		PrintToChatAll("The scoreboard has been reset since there's only on person playing.");
		new i;
		while (i++ < GetMaxClients())
		{
			score[i] = 0;
		}
	}

}



//When someone dies...
public playerdeathcheck(Handle:event, const String:name[], bool:dontBroadcast)
{
	//If the game is started
	if (ended == 0) {
		//Get the attacker and victim's client id
		new victim_id = GetEventInt(event, "userid");
		new attacker_id = GetEventInt(event, "attacker");
		//From those id's, determine their client index
		new victim = GetClientOfUserId(victim_id);
		new attacker = GetClientOfUserId(attacker_id);
		
		//Store the name of the victim in victimname[]
		new String:victimname[MAX_NAME_LENGTH];
		GetClientName(victim, victimname, sizeof(victimname));
		//Do the same thing for the name of the attacker in attackername[]
		new String:attackername[MAX_NAME_LENGTH];
		GetClientName(attacker, attackername, sizeof(attackername));
		
		//If the victim is "it"
		if (StrEqual(victimname, it)) {
			//If they like fell down, or got crushed or something by the world
			if (!attacker) {
				//Tell the players that the "it" died
				PrintToChatAll("%s died unexpectedly.", it);
				//Thell the players what they have to do to be "it"
				PrintToChatAll("Kill the first person on the other team to be \"it!\"");
				//Reset the "it"'s name so that no one is "it"
				strcopy(it, 17, "notasingleplayer");
				it[18] = 0;
				//Tell the server that the initial it has not been chosen
				choseinitial = 0;
			//If it wasn't the world, then if might be someone else that killed the "it"
			}else if (attacker != victim){
				new clientcount = 0;
				while (clientcount++ < GetMaxClients()){
					if (IsClientInGame(clientcount)){
						ClientCommand(clientcount, "playgamesound reversetag/newit.mp3")
					}
				}
				//Tell the players that there's a new "it" in town...
				PrintToChatAll("%s is now it!", attackername);
				//Make it[] (the variable that is holding the "it"'s name) equal the attacker's name
				strcopy(it, sizeof(attackername), attackername);
				it[sizeof(attackername) + 1] = 0;
				itindex = attacker;
				
			//Ok, so it's not the world, and it's not another player, it must be they killed themself
			}else{
				//Let all the players see their shame
				PrintToChatAll("%s killed themself.",it);
				//Now let them know what to do to be "it"
				PrintToChatAll("Kill the first person on the other team to be \"it!\"");
				//Make it[] (the variable that is holding the "it"'s name) equal nothing
				strcopy(it, 17, "notasingleplayer");
				it[18] = 0;
				//Tell the server that the initial "it" needs to be chosen
				choseinitial = 0;
			}
		//Ok, so the person who died wasn't "it"
		}else{
			//But maybe the initial it hasn't been chosen!
			if (choseinitial == 0){
				//Ok, so we might've found our initial "it"!
				//Determine the team of the victim and the attacker
				new victimteam = GetClientTeam(victim);
				new attackerteam = GetClientTeam(attacker);
				//So were they on the same team?
				if (victimteam != attackerteam){
					//Nope, they were on different teams so the attacker is now "it"
					//Tell the server that the initial "it" has been chosen
					choseinitial = 1;
					//Tell the players who got to be "it"!
					PrintToChatAll("%s is it!",attackername);
					//Make it[] (the variable that is holding the "it"'s name) equal the attacker's name
					strcopy(it, sizeof(attackername), attackername);
					it[sizeof(attackername) + 1] = 0;
					itindex = attacker;
				}
			//Ok, so there is an "it" on the board, and they just killed someone who isn't "it"
			}else{
				//If the person killing someone isn't "it" (because they have the right to)
				if (!StrEqual(attackername, it)){
					//If the admin has point penalties on
					if (pointpenalty == 1){
						//Take away points from the wrongful attacker
						score[attacker] = score[attacker] - 5;
						if (score[attacker] < 0){
							score[attacker] = 0;
						}
						//Tell the bad attacker that he just got a point deduction
						PrintToChat(attacker,"\x04You just lost points because you killed someone who wasn't it!");
					}
				//If the attacker is it then
				}else{
					//If hard mode is on
					if (gamemode == 2){
						score[attacker] = score[attacker] + 10
					}
				}
			}
			
		}
		setbeacons();
	}
}



//When a player spawns
//We need to check if they are it so we can make sure they have a beacon
public playerspawncheck(Handle:event, const String:name[], bool:dontBroadcast)
{
	setbeacons();
}



//When the round starts (or when a map changes)
public roundstartcheck(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if (ended == 0){
		end_game(1);
	}
	//Reload the plugin for good measure
	ServerCommand("sm plugins reload reversetag")
}



public OnMapStart()
{
	//Downloads
	AddFileToDownloadsTable("sound/reversetag/intro.mp3")
	AddFileToDownloadsTable("sound/reversetag/outro.mp3")
	AddFileToDownloadsTable("sound/reversetag/newit.mp3")
	
	if (ended == 0){
		end_game(1);
	}
	
}



setbeacons()
{
	//If the game is active
	if (ended == 0){
		//Make sure everyone has a beacon
		ServerCommand("sm_beacon @all 1")
		//Then toggle it, so that no one has a beacon
		ServerCommand("sm_beacon @all")
		//Then beacon the "it"
		ServerCommand("sm_beacon %s 1",it)
		//Thus, having only the "it" beaconed
		//Genius, I know ;)
		
		new a = 0;
		while (a++ < GetMaxClients()){
			if (IsClientInGame(a)){
				SetEntityRenderMode(a,RENDER_NORMAL)
				SetEntityRenderColor(a)
			}
		}
		//Start the glowing
		SetEntityRenderMode(itindex,RENDER_TRANSCOLOR)
		SetEntityRenderColor(itindex,0,255,0,255)
	}
}

//This is the timed event (every two or so seconds) that adds to their scores and checks if they won
//I also use this timed event for other things, just because I don't want to make another timed event.
public Action:playerscorecheck(Handle:timer)
{
	if (ended == 0) {
		//Make SURE flag caps are off, because I seem to have a problem with those :P
		useflags = 0;
		checkflags();
		//Make a new string that holds the name of the client
		new String:itname[MAX_NAME_LENGTH];
		//i will just be used as a counter for the loop
		new i;
		i = 0;
		//Go through every client, counting i by one every time
		while (i++ < GetMaxClients())
		{
			if (IsClientInGame(i)){
				//Get the name of the current client (remember i is our counter,
				//so it will start with one and go through the amound of clients)
				GetClientName(i, itname, sizeof(itname));
				//If the current client (using i as the client number) is it
				if (StrEqual(it, itname)){
					//If the current game is normal mode
					if (gamemode == 1){
						//Make sure their score goes up by one, held in their slot in the score[] array
						score[i] = score[i] + 1;
					}
					//If thier score is greater than (or equal to) the total points required
					if (score[i] >= totalpoints)
					{
						//Tell all the players who beat them
						PrintToChatAll("\x04%s won the game!",itname);
						//Print this message on the center screen of every client
						PrintCenterTextAll("%s won the game!",itname);
						//Tell the server that the initial "it" is no longer chosen
						choseinitial = 0;
						//Run the end_game scripts
						end_game(99);
					}
					
				}
				//So now, if it's not ended
				if (ended == 0) {
					//Let them know what their current score is
					PrintHintText(i,"Your score : %d",score[i]);
				}
			}
		}
		if (ended == 0){
		//Ok, let's move on to displaying the leaderboard
		show_scores(99);
		}
	}

	//Return
	return Plugin_Continue;
}

//When the admin types "reversetag" in his / her console
public Action:open_menu(client, args)
{
	//We know that if a user was able to exec this then they are admin
	//So let's make sure they don't see the leaderboard for this instance
	leadertable[client] = 0;
	//Let's create the variables that will hold the amount of points required
	new String:temppoints1[64] = "Increase required points to ";
	new String:temppoints2[64] = "Decrease required points to ";
	new String:tempamount1[64];
	new String:tempamount2[64];
	//This is the menu handle
	new Handle:menu = CreateMenu(MenuHandler1);
	//Set the title of the menu
	SetMenuTitle(menu, "Choose an action:");
	
	//Add the items to the menu
	
	//Item 1
	AddMenuItem(menu, "1", "Load Reverse Tag");
	
	//Item 2
	AddMenuItem(menu, "2", "Unload Reverse Tag");
	
	//Item 3
	AddMenuItem(menu, "3", "Bring  Up A Vote");
	
	//Item 4
	AddMenuItem(menu, "4", "Check for updates!");
	
	//Item 5
	IntToString(totalpoints + 50, tempamount1,32);
	StrCat(temppoints1, sizeof(temppoints1) - 1, tempamount1);
	AddMenuItem(menu, "5", temppoints1);
	
	//Item 6
	IntToString(totalpoints - 50, tempamount2,32);
	StrCat(temppoints2, sizeof(temppoints2) - 1, tempamount2);
	AddMenuItem(menu, "6", temppoints2);
	
	AddMenuItem(menu, "7", "", ITEMDRAW_SPACER);
	
	//Item 8
	if(allthetime == 1){
		AddMenuItem(menu, "8", "Turn Auto-Restart Off");
	}else{
		AddMenuItem(menu, "8", "Turn Auto-Restart On");
	}
	
	//Item 9
	if(pointpenalty == 1){
		AddMenuItem(menu, "9", "Turn Point Penalties Off");
	}else{
		AddMenuItem(menu, "9", "Turn Point Penalties On");
	}
	
	//Item 10
	if(endmapchange == 1){
		AddMenuItem(menu, "10", "Turn Map Switch (At End) Off");
	}else{
		AddMenuItem(menu, "10", "Turn Map Switch (At End) On");
	}
	
	//Item 11
	if(gamemode == 1){
		AddMenuItem(menu, "11", "Normal Mode Is Enabled", ITEMDRAW_DISABLED);
	}else{
		AddMenuItem(menu, "11", "Turn Normal Mode On");
	}
	
	//Item 12
	if(gamemode == 2){
		AddMenuItem(menu, "12", "Hard Mode Is Enabled", ITEMDRAW_DISABLED);
	}else{
		AddMenuItem(menu, "12", "Turn Hard Mode On");
	}
	
	//Item 13
	if(gamemode == 3){
		//AddMenuItem(menu, "13", "Reverse Mode Is Enabled", ITEMDRAW_DISABLED);
	}else{
		//AddMenuItem(menu, "13", "Turn Reverse Mode On");
	}

	//Actually display the menu
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}



//Ok, this is a handle to carry out the functions of the admin menu
public MenuHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	//Ok, they've closed the menu somehow (by hitting some number on their keyboard)
	//Let's make sure they can see the leaderboard again
	leadertable[param1] = 1;

	//If they've selected a menu item
	if (action == MenuAction_Select)
	{
		//If they've selected option 1
		if (param2 == 0)
		{
			if(ended == 1){
				//Run the start_game scripts
				tempendmapchange = 0;
				tempallthetime = 0;
				start_game(99);
			}else{
				PrintToChat(param1,"The game is already started!");
			}
		}	
		//If they've selected option 2
		if (param2 == 1)
		{
			if (ended == 0){
				ended = 1;
				tempendmapchange = 1;
				tempallthetime = 1;
				//Run the end_game scripts
				end_game(99);
			}else{
				PrintToChat(param1,"The game is already ended!");
			}
		}	
		//If they've selected option 3
		if (param2 == 2)
		{
			open_vote(param1,1);
		}	
		//If they've selected option 5
		if (param2 == 4)
		{
			//Add 50 to the total points required to win
			totalpoints += 50;
			//If the game is going on
			if (ended == 0){
				//Display that the score change has taken place
				PrintToChatAll("Total required points to win is now %d",totalpoints);
			}
		}
		//If they've selected option 6	
		if (param2 == 5)
		{
			//Subtract 50 from the total points required to win
			totalpoints -= 50;
			//If the game is going on
			if (ended == 0){
				//Let the players know that the change has happened
				PrintToChatAll("Total required points to win is now %d",totalpoints);
			}
		}
		//If they've selected option 4
		if (param2 == 3)
		{
			//Check the update page
			versioncheck(param1, 99);
		}
		//If they've selected option 8
		if (param2 == 7)
		{
			//Toggle the allthetime var
			if(allthetime == 1){
				allthetime = 0;
			}else{
				allthetime = 1;
			}
		}
		//If they've selected option 9
		if (param2 == 8)
		{
			//Toggle the endmapchange var
			if(pointpenalty == 1){
				pointpenalty = 0;
			}else{
				pointpenalty = 1;
			}
			
		}
		//If they've selected option 10
		if (param2 == 9)
		{
			//Toggle the endmapchange var
			if(endmapchange == 1){
				endmapchange = 0;
			}else{
				endmapchange = 1;
			}
			
		}
		//If they've selected option 11
		if (param2 == 10)
		{
			gamemode = 1;
			PrintToChatAll("\x04Normal Mode Has Been Turned On!");			
		}
		//If they've selected option 12
		if (param2 == 11)
		{
			gamemode = 2;
			PrintToChatAll("\x04Hard Mode Has Been Turned On!");			
		}
		//If they've selected option 13
		if (param2 == 12)
		{
			gamemode = 3;
			PrintToChatAll("\x04Reverse Mode Has Been Turned On!");			
		}

	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}



//When starting a vote
public Action:open_vote(client, args)
{
	//If they're voting...
	if (IsVoteInProgress())
	{
		//Get outta' here!
		return Plugin_Handled;
	}
	//If there's no current game going on (why would you vote to start the game when it's already on?)
	if (ended == 1){
		//This is the menu handle
		new Handle:voting = CreateMenu(votehandler);
		
		//Set the title of the menu
		SetMenuTitle(voting, "Would you like to start reverse tag?");
		
		//Add the items to the menu
		AddMenuItem(voting, "1", "Yes");
		AddMenuItem(voting, "2", "No");
		
		//Actually display the menu
		VoteMenuToAll(voting, 20);
	}
	return Plugin_Handled;
}



//The vote handler
//This determines who voted what
public votehandler(Handle:voting, MenuAction:action, param1, param2)
{
	//If they voted
	if (action == MenuAction_End)
	{
		//Close the voting handle
		CloseHandle(voting);
	} else if (action == MenuAction_VoteEnd) {
		//If they voted to start the game
		if (param1 == 0)
		{
			//Tell 'em what they won!
			PrintToChatAll("The yea's have it!")
			//Start the game
			start_game(99);
		}else{
			PrintToChatAll("The vote failed.")
		}
	}
}



//The score handler
//Not sure why I need this...
public scorehandler(Handle:nothingyo, MenuAction:action, param1, param2)
{
}

//This is called to display the leaderboards
public Action:show_scores(args)
{
	//If the menu exists, then end it!
	if(showscores != INVALID_HANDLE){
		CloseHandle(showscores);
	}
	//The showscores menu handler
	showscores = CreateMenu(scorehandler);
	//curname is used to hold a temporary name in a loop
	new String:curname[MAX_NAME_LENGTH];
	//theirscore holds, well, their score...
	new String:theirscore[34];
	//finishloop is a check to see if the loop has finished
	new finishloop = 0;
	// finishcheck is similar to finishloop, they both are used to sort the 'display' arrays (idtable, scoretable)
	//The reason I use different arrays (ie. scoretable[] instead of score[]) when sorting is so that when I sort
	//them, I don't screw up the scores.
	new finishcheck = 0;
	//thisisit tells the server if the current player is it
	new thisisit = 0;
	//Define loop counter variables
	new z = 0;
	new y = 0;
	new a = 0;
	new d = 0;
	
	//For every client...
	while (z++ < GetMaxClients())
	{
		//Make scoretable[] equal score[]
		scoretable[z] = score[z];
	}
	//I'm cautious about my variables, so I have to make EXTRA sure that z = 0... I'm ocd like that :P
	z = 0;
	//Ok, so for every client...
	while (z++ < GetMaxClients())
	{
		//Reset idtable so that it's like [1,2,3,4,5,6,etc]
		idtable[z] = z;
	}
	//Ok, so while finishloop = 0, which it is by default
	while (finishloop == 0){
		//Make finishcheck = 0
		finishcheck = 0;
		//Make sure I reset y so that it goes through this (y - clientcount) loop everytime in the (finishloop = 0) loop
		y = 0;
		//For every client
		while (y++ < GetMaxClients()) {
			if (IsClientInGame(y)){
				//We have to make sure it's at least at 2, because 1 - 1 = 0 and there is not "0" client index...
				if ( y != 1 ){	
					//If the score of the [y]th person represented in both arrays is greater than
					//the score of the [y - 1]th person represented before them, then...
					if (scoretable[y] > scoretable[y - 1]){
						//Ok, let's set finishcheck to 1 because it had to make an adjustment to the arrays
						finishcheck = 1;
						//Switch the two spots in both arrays
						a = idtable[y - 1];
						idtable[y - 1] = idtable[y];
						idtable[y] = a;
						a = scoretable[y - 1];
						scoretable[y - 1] = scoretable[y];
						scoretable[y] = a;
					}
				}
			}
		}
		//Ok, so we looked at all the clients in the arrays
		//Did we have to make a change to the array?
		if (finishcheck == 0){
			//If we didn't have to make a change, then let's get out of this loop by doing (finishloop = 1)
			//because we know that it's sorted.
			finishloop = 1;
		}
		//If we did have to make a change then we'll stay in the loop, because it still might be out of order
	}
	//Ok, once we've sorted our arrays by score, let's create the leaderboard
	//in the form of a menu
	
	//Let's set the menu title
	SetMenuTitle(showscores, "Leaderboard:");
	//I'm setting z back to zero because I used it in an earlier loop
	z = 0;
	//Ok, so for every client...
	while (z++ < GetMaxClients()) {
		if (IsClientInGame(z)){
			//Store their name into curname[], which will serve as a temp placeholder until the data is displayed
			GetClientName(idtable[z], curname, sizeof(curname));
			//We want to make the person that is it stick out on the leaderboard
			//So if the curname (the name of the person we're dealing with) is equal to the
			//name of the 'it' then (they're 'it')
			thisisit = 0;
			if (StrEqual(curname, it)){
				thisisit = 1;
			}
			//If the length of their name is greater than so many characters (probably in a clan) then...
			if (strlen(curname) >= 16){
				strcopy(curname, 16, curname);
				curname[17] = 0;
			}
			//Now let's begin making the string that will be displayed (ex: "Dillxn - 99", as in Dillxn has a score of 99)
			//I actually do this process, because I couldn't get variables to work in menu items... very nifty.
			StrCat(curname, sizeof(curname) - 1, " - ");
			IntToString(scoretable[z],theirscore,32);
			StrCat(curname, sizeof(curname) - 1, theirscore);
			//Ok, once it's all concatenated we can add the menu item with the new, complete, string!
			if (thisisit == 1){
				//Make the menu item which, because it is a normal style, will be orange (and stick out)
				AddMenuItem(showscores, curname, curname);
			}else{
				//Disable the menu item, which coincidentally also grays it out
				AddMenuItem(showscores, curname, curname, ITEMDRAW_DISABLED);
			}
			//Now, since it is a leaderboard, and since it will continue to pop up every 2 seconds
			//let's just not have an exit button. There's no point.
			SetMenuExitButton(showscores, false);
		}
	}
	//For every client
	d = 0;
	while (d++ < GetMaxClients() + 1){
		//If the admin isn't viewing some command at the moment
		if (leadertable[d] == 1){
			//Display the leaderboard
			DisplayMenu(showscores, d, 20);
		}
	}

	//Return
	return Plugin_Handled;
}

//Let's make sure they're up to date
public versioncheck(client, args)
{
   new String:url[256]
   url = "http://www.Dillxn.com/dods/addons/revtag/version.asp?version="
   StrCat(url, sizeof(url) - 1, PLUGIN_VERSION);
   ShowMOTDPanel(client,"DoD:S Reverse Tag Version Checker", url, MOTDPANEL_TYPE_URL);
}

//Blocking caps
//The following "checkflags" function was taken from:
//DoD:S GunGame 0.4
//By DJ Tsunami
//http://www.tsunami-productions.nl
//Modified by me for the use of this plugin
checkflags() {
	new iCaptureArea = -1;
	while ((iCaptureArea = FindEntityByClassname(iCaptureArea, "dod_capture_area")) != -1) {
		if (useflags == 1){
			AcceptEntityInput(iCaptureArea, "Enable");
		}else{
			AcceptEntityInput(iCaptureArea, "Disable");
		}
	}
}
