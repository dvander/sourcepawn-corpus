#pragma semicolon 1   // preprocessor?  whatever, no idea what it does. but im leaving it
#include <sourcemod>  //  bleh. i figure i need this.
#include <sdktools>   // not even sure i need this, but im leaving it

#define PLUGIN_VERSION "0.1"
#define PLUGIN_NAME "Tank the Vote"

new Handle:onlylosingteam = INVALID_HANDLE;  // just calling the global variables used for the cfg file import
new Handle:notifyeveryoneoftank = INVALID_HANDLE;
new Handle:tankonfinale = INVALID_HANDLE;
new Handle:allowdirectortanks = INVALID_HANDLE;
new Handle:tankonlywithbigwin = INVALID_HANDLE;
new Handle:g_hCvarRestartGame  = INVALID_HANDLE; // has to do with hooking the restart event

public Plugin:myinfo = 
{
	name = "Tank the Vote",  // just a name
	author = "xyster", // aka steve seguin
	description = "In Versus, infected can vote when the tank comes.",
	version = PLUGIN_VERSION,  //  whatever; variable called earlier
	url = "l4d2clan.hostoi.com"  // my clan site
};

public OnPluginStart()      //  The pimp function, cause it calls all the hookers
{

	CreateConVar("l4d2_tankthevote_version", PLUGIN_VERSION, " Version of L4D2 Tank the Vote on this server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD); // add version info to cfg file

	onlylosingteam = CreateConVar("l4d2_tankthevote_losingteam", "1", " Does only the losing team get the tank? ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	notifyeveryoneoftank = CreateConVar("l4d2_tankthevote_notifyeveryone", "1", " When a voted-on tank is called, do the survivors get notified? ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	tankonfinale = CreateConVar("l4d2_tankthevote_tankonfinale", "0", " Can a tank call be voted on during the finale? ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	allowdirectortanks = CreateConVar("l4d2_tankthevote_allowdirectortanks", "1", " Allow the director to spawn tanks at non-finale moments ? ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	tankonlywithbigwin = CreateConVar("l4d2_tankthevote_tankonlywithbigwin", "1", " Only let the losing team get a tank if they are losing by a lot? ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d2_tankthevote"); // load the config file i guess

	HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Pre);  // alert me -before- a tank spawns
	HookEvent("player_say", Event_PlayerSay);  // catch anything any player says
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);   // I have no idea why postnocopy is used here, but whatever
	HookEvent("finale_start", FinaleBegins);  //  make sure no tanks spawn after the finale event has started

	g_hCvarRestartGame = FindConVar("mp_restartgame");                  // my best guess at avoiding a problem if the game restarts and losing team = 1.  good chance this does not work fully
    	HookConVarChange(g_hCvarRestartGame, CvarChange_RestartGame);     // ugh.  needs work im sure.
}

new calledalready=0;  // Just setting the global flag variable, to make sure its a global variable.
new havetheyleftyet = 0;  // have the surivors left the safe room yet
new team2points = 0;  // survivors score
new team3points = 0 ; // infected score
new pointsdif = 0 ; // difference in team's scores at start of each round
new roundcounter = 0; // keep track of what round it is

public OnMapStart ()   // safe room event
{ 
    havetheyleftyet=1;  // survivors have left the starting room
    team2points = GetTeamScore(2); // capture their previous round(s) score ; used to see who is winning
    team3points = GetTeamScore(3); // capture their previous round(s) score ; ditto
    pointsdif = team2points - team3points ; // winning team should make this negative
    if (team2points == 0 && team3points == 0)
		{
		   roundcounter = 1  ; // Game just started as both teams have 0 score to start
		}
} 

public CvarChange_RestartGame(Handle:convar, const String:oldValue[], const String:newValue[])  //  mp_restart, if used, tries to adjust the roundcounter appropriately.  Dunno what else to hook in case though.
{
	if (roundcounter == 2  || roundcounter == 4  || roundcounter == 6 || roundcounter == 8 || roundcounter == 10  )  
		{      
			roundcounter = roundcounter - 2;  //resets counter if round restarts  .. no idea if this works right
		}
	if (roundcounter == 1  || roundcounter == 3  || roundcounter == 5 || roundcounter == 7 || roundcounter == 9  )  
		{      
			roundcounter = roundcounter - 1;  //resets counter if round restarts  .. no idea if this works right
		}
}  

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)   // EVENT: The round has started
{
	
	roundcounter++;  // keeps track of the round
	havetheyleftyet = 0;

	if (GetConVarFloat(onlylosingteam) == 1)
		{
			if (roundcounter == 3 || roundcounter == 5 || roundcounter == 7 || roundcounter == 9)
				{
				calledalready = 0;
				if (GetConVarFloat(tankonlywithbigwin) == 1 && pointsdif >= 200)
					{
					PrintToChatTeam(3, "Your team is really losing. Say call tank to get a tank this round.");
					}
				if (GetConVarFloat(tankonlywithbigwin) == 1 && pointsdif < 200)
					{
					PrintToChatTeam(3, "You're not losing enough to really need a tank this round.");                             
					}
				if  (GetConVarFloat(tankonlywithbigwin) == 0)
					{
					PrintToChatTeam(3, "Your team is losing. Say call tank to get a tank this round.");
					}
				}	
			if (roundcounter == 4  || roundcounter == 6 || roundcounter == 8 || roundcounter == 10  )
				{
				calledalready = 3;
				PrintToChatTeam(3, "Your team is winning, so you do not get to call a tank this round.");       
				}  
			if (roundcounter == 0  || roundcounter == 1 || roundcounter == 2 )
				{
				calledalready = 5;
				PrintToChatTeam(3, "Tank calls are not available on first level.");       
				}  
		}

if (GetConVarFloat(onlylosingteam) == 0)  // both teams get to call tanks each round
		{
			PrintToChatTeam(3, "Hint: Use the call tank command to summon one tank this round.");
   			calledalready=0;  // Reset flag.  Allows the newly spawned infected team to call a tank.
		}
	
}

public Action:FinaleBegins(Handle:event, const String:name[], bool:dontBroadcast)   // EVENT: Finale has begun
{
if (GetConVarFloat(tankonfinale) == 0)  // check cfg file to see if finale tank calls are allowed
	{
	calledalready=2;  // Disable tank calling on finale.
	}
}

public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)  // determines what happens after the vote finishes
{
	if (action == MenuAction_End)   // vote has ended with no result i guess, so close the vote menu down
	{
		/* This is called after VoteEnd */
		CloseHandle(menu);                     // close the menu
	} else if (action == MenuAction_VoteEnd) {  //  The was a voting result! yaay...
		/* 0=yes, 1=no */
		if (param1 == 0)   //  If vote passed...
		{
			if (calledalready == 0)  // just in case finale is started also
			{ 
				calledalready=4; // prevent another vote from starting (4 is the same as 1, but with a double meaning)
			}
                 
			if (GetConVarFloat(notifyeveryoneoftank) == 1)  // check config file
			{
				PrintToChatTeam(2,"Tank has been called! ring ring motherfuckers...");       // Alert survivors the called tank is coming
			}
			PrintToChatTeam(3, "Tank has been called!");       // Alert only infected team the called tank is coming
			new flags = GetCommandFlags("z_spawn");             
			SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
			FakeClientCommand(1, "z_spawn tank auto");     //  sends the spawning command from client 1
			SetCommandFlags("z_spawn", flags);             // tank should be spawning now i guess
		}
		if (param1 != 0)   //  If vote failed...
		{
			PrintToChatTeam(3, "Tank call not passed.");       // only infected team are alerted
		}
	}
}

DoVoteMenu()                  // Vote has been called and is allowed
{
	if (IsVoteInProgress())                // stop vote if there is already a vote going
	{
		return;
	}
	new Clients[MaxClients], iCount;       // figure out how many people there are
	new Handle:menu = CreateMenu(Handle_VoteMenu);   // make a menu to vote with
	SetMenuTitle(menu, "Vote: Call the tank?");     // set its title
	AddMenuItem(menu, "yes", "Yes");                 // option 1
	AddMenuItem(menu, "no", "No");                 // option 2
	SetMenuExitButton(menu, false);               //  disable the exit menu option
	for ( new i = 1; i <= MaxClients; i++)             //  cycle thru each player
    		{
        		if (IsClientInGame(i) && GetClientTeam(i) == 3)    // make an array of only infected players
        		{
            		Clients[iCount++] = i; 
        		}
    		}
    	VoteMenu(menu, Clients, iCount, 15);      // display the vote menu to only the infected players for 15 seconds; 
}


public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)      // redundant at the moment; can be used to stop uncalled tanks from spawning, eventually
{     // not yet called=1, called already=2, finale cant call=3, your team is winning=4, tank is being called =4 , tank is on first level=5
	if(calledalready == 0 || calledalready == 1 || calledalready == 3 || calledalready == 5 ) //  tank that is being spawned was not called by any player -- director called it.
	{
		if (GetConVarFloat(allowdirectortanks) == 1)
			{
			return Plugin_Continue;
			}	   // allow tank to spawn
		if (GetConVarFloat(allowdirectortanks) == 0)
			{
			return Plugin_Handled;
			}		  // stop tank from spawning
	}
	if (calledalready == 4)   // tank has been voted for and the voted tank is now spawning , allow it
	{
	    calledalready = 1;  // tank now has been used and any other tanks spawned are called by the director
	    return Plugin_Continue;
	}
	return Plugin_Continue;  // if on the finale, tanks can spawn, if director or last minute vote spawns one
}

public Action:Event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)       // catches everything every player says
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));       // find out who said what
	new iCurrentTeam = GetClientTeam( client );        // what team were they on?

	new String:text[200];
	GetEventString(event, "text", text, 200);
	
	decl String:player_authid[32];
	GetClientAuthString(client, player_authid, sizeof(player_authid));

	if (strcmp(text, "call tank", false) == 0 && calledalready == 0 && iCurrentTeam == 3 )      // if vote called, tank is allowed, and infected, start vote.
	{
		if (havetheyleftyet == 1)
		{
			if (GetConVarFloat(tankonlywithbigwin) == 1 && pointsdif >= 200)
				{
				DoVoteMenu();
				}
			if (GetConVarFloat(tankonlywithbigwin) == 1 && pointsdif < 200)
				{
				PrintToChat(client, "You're not losing enough to really need a tank this round.");                             
				}
			if  (GetConVarFloat(tankonlywithbigwin) == 0)
				{
				DoVoteMenu();
				}
		}
		if (havetheyleftyet == 0)
		{
			PrintToChat(client, "Can't call tank until the survivors have left the safe room.");    // alert player to the rules
		}
	}
	if (strcmp(text, "call tank", false) == 0 && calledalready == 1 && iCurrentTeam == 3)    // tank has been called
	{
		PrintToChat(client, "Tank has already been called.");                             // alert player they are dumb
	}
	if (strcmp(text, "call tank", false) == 0 && calledalready == 4 && iCurrentTeam == 3)    // tank has been called, (just in case two tanks spawn at same time)
	{
		PrintToChat(client, "Tank has already been called.");                             // alert player they are dumb
	}
	if (strcmp(text, "call tank", false) == 0 && calledalready == 2 && iCurrentTeam == 3)      // finale has started, cant call tank
	{
		PrintToChat(client, "Tank can't be called on the Finale.");                        // alert player they are annoying
	}
	if (strcmp(text, "call tank", false) == 0 && iCurrentTeam != 3)                            // not infected, so cant call a tank
	{
		PrintToChat(client, "Only infected players can use that command.");                // player is really stupid and annoying, so i tell em
	}
	if (strcmp(text, "call tank", false) == 0  && calledalready == 5 && iCurrentTeam == 3)                            // not infected, so cant call a tank
	{
		PrintToChatTeam(3, "Tank calls are not available on first level.");  
	}
	if (strcmp(text, "call tank", false) == 0  && calledalready == 3 && iCurrentTeam == 3)                            // not infected, so cant call a tank
	{
		PrintToChatTeam(3, "Your team is winning, so you do not get a tank this round.");  
	}
	if (strcmp(text, "debug", false) == 0 )          // used for debugging reasons
	{	
		if (roundcounter == -1){PrintToChatAll ("-1");}
		if (roundcounter == 0){PrintToChatAll ("0");}
      	if (roundcounter == 1){PrintToChatAll ("1");}
		if (roundcounter == 2){PrintToChatAll ("2");}
	if (roundcounter == 3){PrintToChatAll ("3");}
		if (roundcounter == 4){PrintToChatAll ("4");}
		if (roundcounter == 5){PrintToChatAll ("5");}
	if (roundcounter == 6){PrintToChatAll ("6");}
		if (roundcounter == 7){PrintToChatAll ("7");}
		if (roundcounter == 8){PrintToChatAll ("8");}
		if (roundcounter == 9){PrintToChatAll ("9");}
	}
}

PrintToChatTeam(team, const String:message[])             // a function used for chating to just one team, and not both; 3=infected, 2=surv, 1=spec, >4=classes
{ 
    for (new i = 1; i <= MaxClients; i++) 
    { 
        if (GetClientTeam(i) == team) 
        { 
            PrintToChat(i, message); 
        } 
    } 
}  
