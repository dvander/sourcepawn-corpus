/*
*
*
*	TF2 Skills Player Rank with Speed Run Timer
*
*	by Lt Llama & Remade for TF2 by Cranck
*
*
*	Thanks to:
*	- Lt. Llama
*	- MikeJS
*	- P3tsin
*	- Everyone else that helped make this..
*
*  WHAT IS THIS?
*  ====================
*	The TF2 skills community has never had an ingame ranking system, like other mods
*	where you can count how many frags you got by using what. Skillsrank solves
*	this by using a difficulty setting for each map. This is added to a map cfg which
*	is read by this plugin, When a player finish a map with a difficulty setting he 
*	triggers a goal model and data is saved to two SQL tables.
*	
*	If the map config has coords for the start model it spawns it and you have a
*	speedrun timer.
*
*	Skillsrank is designed so you can only finish and collect points ONE time during
*	the current loaded map. This is to not get a skewed collection of points because
*	someone continuosly collects points on an easy map.
*
*  WHAT IS CALCULATED?
*  ===================
*	- How many maps you finished and compared to others
*	- Which class you finished with
*	- How many points you have collected and compared to others
*	- First and last time you finished a map on the server
*	- Your best speedrun on the current map
*	- The all time high speed run on the current map
*	- The average difficulty of finished map (UBER factor)
*	- The top 5 players in 3 cathegories 1. Ubers, 2. Finished maps, 3. Collected
*	  points.
*
*  WHAT IS AN UBER?
*  ================
*	UBER is someone who have finished at least the amount of maps defined by: 
*	#define uberCount 10. When someone finished in this case 10 maps the plugin
*	divclientes <sum of collected points>/<number of finished maps>. It then compares
*	these players average difficulty and sort it. The top 5 gets into the /top 5 list. 
*	This is to encourage playing harder maps. If you play easier maps your average
*	drops.
*
* 	CONTENT OF SQL TABLES
*	=====================
*		Table skillranks (1 row for each player)
*		================
*		- steam client
*		- nickname
*		- number of times finished the map
*		- total collected points
*		- average of all points collected
*		Table skillmaps (1 row each time someone finish a map)
*		================
*		- steam client
*		- nickname
*		- map name
*		- player class (all Tf2 classes)
*		-.date
*		- time
*		- difficulty
*		- speedrun time
*
* 	MAP CONFIGS
*	===========
*	Map configs goes in tf/cfg/mapscfg/
* 	Map configs is added by admins with ADMINFLG_GENERIC access.
*	Use sr_adminmenu to add or manipulate current map config data.
*
*  THIS PLUGIN NEEDS AN SQL DATABASE TO WORK
*  =========================================
*	If you don't have SQL forget this. If you have it then see to that you have set
*	$moddir/addons/sourcemod/configs/databases.cfg
*
*  INSTALLATION
*  ============
*	_ Create the folder tf/cfg/mapscfg and put all cfg files there
*
*
*
*  SETTINGS YOU MAY CHANGE
*  =======================
*  	Change to whatever you like under "// Customizable globals" below and recompile.
*
*  FUTURE PLANS FOR THIS PLUGIN
*  ============================
*	- Leet custom stuff attached to top5 players on 4 cathegories: Ubers, High rankers,
*	  most finished maps and speed runners (on current map)
*	- Allow players to keep speed running the current map and update db. Now only the first
*	  run i saved.
*	- Ability to say YES or NO to if you want the ranks to be saved on the current map.
*	  If NO you can speed run but it wont be saved.
*
*  USER COMMANDS
*  =============
*  	- say '/difficulty' to show difficulty (number between 1-100)
*  	- say '/top5' to show top 5 players in 3 cathegories (finished times, total points, average difficulty)
*  	- say '/mapStats' to show your stats on the current map.
*  	- say '/stats' to see your overall stats.
*  	- 'sr_stoptimer' = Client command to stop speed run timer
*  	- 'sr_adminmenu' = Admin tool to add coords and difficulty
*
*/


#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <dukehacks>

// Customizable globals
#define RECORD_SOUND "misc/happy_birthday.wav" 		// The sound played when the all time speedrun record is broken
#define FINISH_SOUND "misc/achievement_earned.wav" 		// The sound played when map is finished
#define START_MODEL "models/props_combine/combine_mine01.mdl" 	// The model used as trigger for the timer
#define GOAL_MODEL "models/props_combine/combine_mine01.mdl" 	// The model used to trigger when map is finished
#define uberCount 10 				// How many times you have to finish maps until average difficulty starts to count (so noone can come and finish 1 map and become an uber)
#define maxUserclient 64 				// Set a max of client's in the array (max amount of players who can finish during map period)
#define maxPlayersInDB 2000 			// When you have more than 400 unique visitors in your maps table.you need to increase this or delete posts in the 
// db. But be aware of stack error. You see how many players there are in the db by saying
// /skillme.
#define maxFinishedMaps 164			// This is used when selecting all lines in the maps table which
// match the current map loaded and a certain player. Maybe noone
// will finish same map 64 times or more, but in case increse.
//#define keysTimerMenu (1<<0)|(1<<1) 		// Shown when a speedrunner stops the clock
#define SCOUT 1
#define SNIPER 2
#define SOLDIER 3
#define DEMO 4
#define MEDIC 5
#define HEAVY 6
#define PYRO 7
#define SPY 8
#define ENGIE 9
#define CLS_MAX 10

#define PLUGIN_VERSION "0.9.0"

// Non Customizable globals
public Plugin:myinfo = 
{
	name = "Skillsrank",
	author = "Lt Llama & CrancK",
	description = "speedrun tool",
	version = PLUGIN_VERSION,
	url = ""
};

// Debug messages
new debugSkills;

// The entity names for the goal and the start
#define GOAL_NAME "goal"
#define START_NAME "start"

new String:finishContainer[maxUserclient][33];
new bool:hasTimer[33];
new bool:hasFinished[33];
new String:tName[256];
new curclient;

new totalFinnish;
new bestFinishedTotal;
new bestRankTotal;
new playersUberPosition;
new rankIncr1;
new rankIncr2;
new topFinish;
new topRank;
new startTime[33];
new stopTime[33];
new models[2];
//new clockmodel;
new menunumber = 1;
//new allowteams[30];
new bool:dontspam[33];
new Handle:timeTimer[33];

// Database globals
new Handle:dbcSkills;
new Handle:resultRanks;
new Handle:resultMaps;

// cvars
new Handle:y_goal = INVALID_HANDLE;
new Handle:x_goal = INVALID_HANDLE;
new Handle:z_goal = INVALID_HANDLE;
new Handle:y_start = INVALID_HANDLE;
new Handle:x_start = INVALID_HANDLE;
new Handle:z_start = INVALID_HANDLE;
new Handle:sv_diff = INVALID_HANDLE;
//new Handle:sv_gteam = INVALID_HANDLE;
new Handle:gEnabled = INVALID_HANDLE;
new Handle:gHostname = INVALID_HANDLE;

public OnPluginStart() 
{
	CreateConVar("sr_version", PLUGIN_VERSION, "skillsrank plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sv_diff = CreateConVar("sr_difficulty","0", "difficulty", FCVAR_PLUGIN|FCVAR_NOTIFY) ;
	//sv_gteam = CreateConVar("sv_goalteams","bryg", "team");
	gEnabled = CreateConVar("sr_enable", "1", "enables/disables the speedrunning, stats are still available", FCVAR_PLUGIN|FCVAR_NOTIFY);
	x_goal = CreateConVar("sr_xgoal","0.0", "x coordinate for goal", FCVAR_PLUGIN) ;
	y_goal = CreateConVar("sr_ygoal","0.0", "y coordinate for goal", FCVAR_PLUGIN) ;
	z_goal = CreateConVar("sr_zgoal","0.0", "z coordinate for goal", FCVAR_PLUGIN) ;
	x_start = CreateConVar("sr_xstart","0.0", "x coordinate for start", FCVAR_PLUGIN) ;
	y_start = CreateConVar("sr_ystart","0.0", "y coordinate for start", FCVAR_PLUGIN) ;
	z_start = CreateConVar("sr_zstart","0.0", "z coordinate for start", FCVAR_PLUGIN) ;

	HookEvent("teamplay_round_start", Event_round_start);
	RegConsoleCmd("sr_showdifficulty", Command_mapDifficulty, "- shows the difficulty of the map");
	RegConsoleCmd("sr_showStats", Command_showStats, "- shows the rank for the current player") ;
	RegConsoleCmd("sr_showMapStats", Command_showMapStats, "- shows the rank for the current player") ;
	RegConsoleCmd("sr_showTopFive", Command_showTopFive, "- shows the stats for the top 5 players") ;
	RegConsoleCmd("sr_stopTimer", Command_showTimerMenu, "- Stops the speed run timer");
	//RegConsoleCmd("sr_skillsmenu", adminmenu, "shows admin menu");
	RegAdminCmd("sr_adminmenu", adminmenu, ADMFLAG_GENERIC);
	
	RegConsoleCmd("say", Command_Say);
	
	
	gHostname = FindConVar("hostname");
	models[0] = -10;
	models[1] = -10;
	
	
	// Debug messages
	// Set this to 1 in plugin_init to get debug messages in the log files
	debugSkills = 0;
	PrintToServer("ConVars and Commands created succesfully");
	// Connect to dabatase and init tables
	
	sql_init_db();
	
	// If everything is ok with the db try and spawn the start and goal model
	//spawnStartModel();
	//spawnGoalModel();
	
	//return Plugin_Continue;
}

// Clear the tasks and cvars attached to client's
public OnClientDisconnect(client) 
{
	hasTimer[client] = false;
	hasFinished[client] = false;
}

// Reset the cvars before map change
public OnPluginEnd() 
{
	SetConVarInt(sv_diff, 0);
	SetConVarFloat(x_goal, 0.0);
	SetConVarFloat(y_goal, 0.0);
	SetConVarFloat(z_goal, 0.0);
	SetConVarFloat(x_start, 0.0);
	SetConVarFloat(y_start, 0.0);
	SetConVarFloat(z_start, 0.0);
	//CloseHandle(dbcSkills);
}

// Precache resources
public OnMapStart() 
{
	//PrecacheSound("misc/achievement_earned.wav");
	//AddFileToDownloadsTable("sound/misc/achievement_earned.wav");

	PrecacheModel(GOAL_MODEL, true) ;
	PrecacheModel(START_MODEL, true) ;
	PrecacheSound(FINISH_SOUND, true) ;
	PrecacheSound(RECORD_SOUND, true) ;
	
	if(GetConVarFloat(x_goal) != 0.0 || GetConVarFloat(y_goal) != 0.0 || GetConVarFloat(z_goal) != 0.0 || GetConVarFloat(x_start) != 0.0 || GetConVarFloat(y_start) != 0.0 || GetConVarFloat(z_start) != 0.0 || GetConVarInt(sv_diff) != 0)
	{
		PrintToServer("resetting difficulty and locations");
		SetConVarInt(sv_diff, 0);
		SetConVarFloat(x_goal, 0.0);
		SetConVarFloat(y_goal, 0.0);
		SetConVarFloat(z_goal, 0.0);
		SetConVarFloat(x_start, 0.0);
		SetConVarFloat(y_start, 0.0);
		SetConVarFloat(z_start, 0.0);
	}
	plugin_cfg();
	//clockmodel = PrecacheModel(CLOCK_SPRITE, true);
} 

// Exec sql.cfg //
public plugin_cfg()
{
	//new String:mapname[64]; GetCurrentMap(mapname, 63);
	//new String:rpath2[PLATFORM_MAX_PATH];
	//BuildPath(Path_SM,rpath2,PLATFORM_MAX_PATH,"/configs/maps/%s.cfg", mapname);
	//ServerCommand("exec %s", rpath2);
	new String:mapname[64]; GetCurrentMap(mapname, 63);
	ServerCommand("exec mapscfg/%s.cfg", mapname);  
}

// Connect to the database and create tables if they dont exist
sql_init_db() 
{
	// Connect to db
	PrintToServer("trying to connect to database");
	new String:error[255];
	dbcSkills = SQL_DefConnect(error, sizeof(error));
	decl String:query[512];
	 
	if (dbcSkills == INVALID_HANDLE)
	{
		PrintToServer("Could not connect to skillrank: %s", error);
	} 
	else 
	{
		// Create table skillrank if it dont exist
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `skillrank` ( `steamclient` VARCHAR(32) NOT NULL,`nickNames` VARCHAR(32) NOT NULL, `nFinnished` INT NOT NULL, `rankTotal` INT NOT NULL, `primaryRank` INT NOT NULL, PRIMARY KEY(`steamclient`))");
		if (!SQL_Query(dbcSkills, query))
		{
			SQL_GetError(dbcSkills, error, sizeof(error));
			PrintToServer("Failed to query (error: %s)", error);
		}
		
	}
	CloseHandle(dbcSkills)
	
	// Create table skillmaps if it dont exist
	dbcSkills = SQL_DefConnect(error, sizeof(error));
	if (dbcSkills == INVALID_HANDLE)
	{
		PrintToServer("Could not connect to skillmaps: %s,", error);
	} 
	else 
	{
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `skillmaps` ( `client` int(11) NOT NULL auto_increment, `steamclient` VARCHAR(32) NOT NULL,`nickNames` VARCHAR(32) NOT NULL, `mapName` VARCHAR(32) NOT NULL, `playerClass` INT NOT NULL, `curDate` VARCHAR(10) NOT NULL, `curTime` VARCHAR(8) NOT NULL, `difficulty` INT NOT NULL, `runTime` INT NOT NULL, PRIMARY KEY(`client`))");
		if (!SQL_Query(dbcSkills, query))
		{
			SQL_GetError(dbcSkills, error, sizeof(error));
			PrintToServer("Failed to query (error: %s)", error);
		}
		
	}
	CloseHandle(dbcSkills);
	//return Plugin_Continue;
}

// Check if its the first time before a map change a player connects
// and if the player has already triggered the goal.
public OnClientPostAdminCheck(client) 
{
	new String:authclient[64]; GetClientAuthString(client, authclient, 63);
	// Loop through the array of client's
	new reconnected = 0;
	// Check if a player who finished is coming back
	for (new loopclient = 1; loopclient <= curclient; loopclient++)
	{
		if (StrContains(finishContainer[loopclient],authclient, false) != -1) 
		{
			CreateTimer(5.0, msgToReconnectTimer, client);
			reconnected = 1;
			hasFinished[client] = true;
			if (debugSkills) { PrintToServer("[AMXX: skillrank DEBUG] Player returned auth = %s finishcontainer = %s client = %i  loopclient = % i curclient = %i",authclient,finishContainer[loopclient],client,loopclient,curclient); }
		}
	}
	if (reconnected == 0) {	CreateTimer(5.0, msgToNewPlayerTimer, client); }
	//return Plugin_Continue;
}

public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if(GetConVarInt(gEnabled)==1)
	{
		CreateTimer(0.01, spawnModels);
	}
}

public Action:spawnModels(Handle:timer)
{
	spawnStartModel();
	spawnGoalModel();
}


// Show the current maps difficulty if the client types /difficulty 
public Action:Command_mapDifficulty (client, args) 
{ 
	new sv_difficulty = GetConVarInt(sv_diff);
	if (sv_difficulty > 0)
	{
		PrintToChat(client, "Map difficulty = %i of 100",sv_difficulty );
	}
	else
	{
		PrintToChat(client, "The current map has no difficulty setting");
	}
	return Plugin_Handled ;
} 

public Action:spawnModelTimer(Handle:timer, any:number)
{
	spawnStartModel();
	spawnGoalModel();
}

// Spawn the start model
public Action:spawnStartModel() 
{	
	// Shut down if its not a dedicated server
	if (!IsDedicatedServer()) 
	{
		PrintToServer("[AMXX: skillrank] Connect without being a dedicated server");
		PrintToServer("[AMXX: SKILLSRANK]: The skillsrank is turned off. Not a dedicated server!");
		return Plugin_Handled;
	}
	// Check if all the cvars for difficulty setting and coords for start and
	// end model exists.

	if(GetConVarInt(sv_diff) > 0 && GetConVarFloat(x_goal) != 0.0 && GetConVarFloat(y_goal) != 0.0 && GetConVarFloat(z_goal) != 0.0 && GetConVarFloat(x_start) != 0.0 && GetConVarFloat(y_start) != 0.0 && GetConVarFloat(z_start) != 0.0)
	{
		PrintToServer("cvars and info found");
		// Create the the start entity and spawn it
		new start = CreateEntityByName("prop_physics_override");
		if(IsValidEntity(start))
		{
			new Float:origin[3];
			SetEntityModel(start, START_MODEL);
			SetEntityMoveType(start, MOVETYPE_NONE);
			SetEntProp(start, Prop_Data, "m_CollisionGroup", 0);
			SetEntProp(start, Prop_Data, "m_usSolidFlags", 28);
			SetEntProp(start, Prop_Data, "m_nSolidType", 6);
			DispatchSpawn(start);
			dhHookEntity(start, EHK_Touch, start_touch);
			Format(tName, sizeof(tName), "start", start);
			DispatchKeyValue(start, "targetname", tName);
			AcceptEntityInput(start, "DisableDamageForces");
			origin[0] = GetConVarFloat(x_start);
			origin[1] = GetConVarFloat(y_start);
			origin[2] = GetConVarFloat(z_start);
			TeleportEntity(start, origin, NULL_VECTOR, NULL_VECTOR);
			models[0] = start;
			PrintToServer("start created");
		}
	}
	else
	{
		noRankInfo();
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


// Spawn the goal model 
public Action:spawnGoalModel() 
{
	// Check if the map cfg cvars exist, else print a message saying rank info is
	// missing.
	if (GetConVarInt(sv_diff) > 0)
	{
		PrintToServer("difficulty found");
		if(GetConVarFloat(x_goal) != 0.0 && GetConVarFloat(y_goal) != 0.0 && GetConVarFloat(z_goal) != 0.0)
		{
			PrintToServer("cvars found");
			// Create the the start entity and spawn it
			new goal = CreateEntityByName("prop_physics_override");
			if(IsValidEntity(goal))
			{
				new Float:origin[3];
				SetEntityModel(goal, GOAL_MODEL);
				SetEntityMoveType(goal, MOVETYPE_NONE);
				SetEntProp(goal, Prop_Data, "m_CollisionGroup", 0);
				SetEntProp(goal, Prop_Data, "m_usSolidFlags", 28);
				SetEntProp(goal, Prop_Data, "m_nSolidType", 6);
				DispatchSpawn(goal);
				dhHookEntity(goal, EHK_Touch, goal_touch);
				Format(tName, sizeof(tName), "goal", goal);
				DispatchKeyValue(goal, "targetname", tName);
				AcceptEntityInput(goal, "DisableDamageForces");
				origin[0] = GetConVarFloat(x_goal) ;
				origin[1] = GetConVarFloat(y_goal) ;
				origin[2] = GetConVarFloat(z_goal);
				TeleportEntity(goal, origin, NULL_VECTOR, NULL_VECTOR);
				models[1] = goal;
				PrintToServer("goal created");
			}
		}
		else
		{
			noRankInfo();
			return Plugin_Handled;
		}
	}
	else
	{
		noRankInfo();
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// Show a hud message if there is no cfg or wrong Format in it
public Action:noRankInfo() 
{
	PrintToChatAll("This map has no rank info added.");
}

public Action:DoJump(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new start = ReadPackCell(pack);
	new Float:origin[3];
	GetClientAbsOrigin(client, origin);
	origin[0] += 40.0;
	TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
	SetEntPropEnt(start, Prop_Data, "m_hOwnerEntity", start);
}

public Action:DoJump2(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new goal = ReadPackCell(pack);
	new Float:origin[3];
	GetClientAbsOrigin(client, origin);
	origin[0] += 40.0;
	TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
	SetEntPropEnt(goal, Prop_Data, "m_hOwnerEntity", goal);
}

// Events triggered when start model is touched
public Action:start_touch(start,client) 
{
	//PrintToServer("%d touched start", client);
	if (client>0 && client<=GetMaxClients())
	{
		// Since we don't remove the entity in its own hook,
		// we must use a work around so TouchHook doesn't get
		// called again.  The server binary does not consider
		// entites touching if one entity "owns" the other.
		// This workaround allows us to delay the deletion
		// of the entity without TouchHook getting called
		// again.
		SetEntPropEnt(start, Prop_Data, "m_hOwnerEntity", client);
		new Handle:pack;
		CreateDataTimer(0.01, DoJump, pack);
		WritePackCell(pack, client);
		WritePackCell(pack, start);
		if(dontspam[client] == true) { return Plugin_Handled; }
		new String:name[32]; GetClientName(client, name, 31);
		
		// If someone touch the timer check if he has the timer running.
		// If not set the time and save his/hers start timer.
		/*new allowteam[5];
		GetConVarString(sv_gteam, allowteam, 4);
		new team = GetClientTeam(client);
		if(team == 1 && StrContains(allowteam, "b", false) == -1)
		{
			shownot(client);
		}
		else if(team == 2 && StrContains(allowteam, "r", false) == -1)
		{
			shownot(client);
		}
		else
		{*/
		if(!hasTimer[client])
		{
			new String:text[255];
			Format(text, 254, "You have started the speedrun timer \nRun for the ball at end \nGO GO GO !!! \n \n(type sr_stoptimer in console to start over) \n \n(Only first run is saved in db)");
			PrintToChat(client, text);
			//PrintToChat(client, "You have started the speedrun timer %s");
			PrintToChat(client, "one... two... three... go!!!");
			hasTimer[client] = true;
			startTime[client] = int:RoundFloat(GetGameTime());
			timeTimer[client] = CreateTimer(1.0, showtimer, client, TIMER_REPEAT);
			PrintToServer("timer added");
		}
		//}
	}
	return Plugin_Continue;
}



// Events triggered when goal model is touched
public Action:goal_touch(goal,client) 
{
	//PrintToServer("%d touched goal", client);
	if (client>0 && client<=GetMaxClients())
	{
		if(timeTimer[client] != INVALID_HANDLE)
		{ KillTimer(timeTimer[client]); timeTimer[client] = INVALID_HANDLE; }
		// Since we don't remove the entity in its own hook,
		// we must use a work around so TouchHook doesn't get
		// called again.  The server binary does not consider
		// entites touching if one entity "owns" the other.
		// This workaround allows us to delay the deletion
		// of the entity without TouchHook getting called
		// again.
		SetEntPropEnt(goal, Prop_Data, "m_hOwnerEntity", client);
		new Handle:pack;
		CreateDataTimer(0.01, DoJump2, pack);
		WritePackCell(pack, client);
		WritePackCell(pack, goal);
		if(dontspam[client] == true) { return Plugin_Handled; }
		/*new allowteam[5]
		GetConVarString(sv_gteam, allowteam, 4);
		new team = GetClientTeam(client);
		
		if(team == 1 && StrContains(allowteam, "b", false) == -1)
		{
			shownot(client);
		}
		else if(team == 2 && StrContains(allowteam, "r", false) == -1)
		{
			shownot(client);
		}
		else
		{*/
		// set up vars for goal_touch function
		new String:authclient[32]; GetClientAuthString(client, authclient, 31);
			
		// Loop through the array of people who previously finished the map
		for(new loopFinnished = 0; loopFinnished < maxUserclient; loopFinnished++)
		{
			if(StrContains(finishContainer[loopFinnished], authclient) != -1)
			{
				new String:name[32]; GetClientName(client, name, 31);
				// Check if the player has touched the timer
				if(hasTimer[client])
				{
					new String:mapname[64] ; GetCurrentMap(mapname,63);
					stopTime[client] = int:RoundFloat(GetGameTime());
					new finishTime = stopTime[client] - startTime[client];
					new nHours = (finishTime / 3600) % 24; 
					new nMinutes = (finishTime / 60) % 60 ;
					new nSeconds = finishTime % 60  ;
					//ShowHudText(client, 0, "%s\n\nfinished %s in\n%i hours, %i minutes, %i seconds.\nOnly first run is saved in db ;)", name, mapname, nHours, nMinutes, nSeconds);
					PrintToChat(client, "Sorry %s. No more points but your time was %i hours, %i minutes, %i seconds.",name,nHours,nMinutes,nSeconds);
					Command_showTimerMenu(client, 0); // Display menu 
					hasTimer[client] = false;
				}
			}
		}
		// Save the steam client's of those who finished and give them a treat :)
		if(!hasFinished[client])
		{
			if(curclient == maxUserclient)
			{
				new String:name[32]; GetClientName(client, name, 31);
				PrintToChat(client, "Sorry %s! Your ranks and time cant be saved. There are to many saved ranks atm",name);
				hasFinished[client] = true;
			}
			else
			{
				new sv_difficulty = GetConVarInt(sv_diff);
				new String:name[32]; GetClientName(client, name, 31);
				new String:mapname[64]; GetCurrentMap(mapname, 63);
				PrintToChat(client, "Good Job %s. You have finished %s and gained %i rank points.",name,mapname,sv_difficulty);
				hasFinished[client] = true;
				curclient++;
				finishContainer[curclient] = authclient;
				// Check if the player has touched the timer
				// OneEyed showed the way of get_systime :)
				if(hasTimer[client])
				{
					stopTime[client] = int:RoundFloat(GetGameTime());
					new finishTime = stopTime[client] - startTime[client];
					new nHours = (finishTime / 3600) % 24;
					new nMinutes = (finishTime / 60) % 60;
					new nSeconds = finishTime % 60;
					// Check if the player broke the all time speed run record
					// Check if anyone broke the speed run record or if it is the first time.
					new String:error[255];
					dbcSkills = SQL_DefConnect(error, sizeof(error));
					decl String:query[512];
					if (dbcSkills == INVALID_HANDLE)
					{
						PrintToServer("Could not connect to skillrank: %s", error);
					} 
					else 
					{
						Format(query, sizeof(query), "SELECT nickNames,curDate,runTime FROM skillmaps where mapName='%s' AND runTime>'%i' ORDER BY runTime DESC",mapname,0);
						resultMaps = SQL_Query(dbcSkills, query);
						if (resultMaps == INVALID_HANDLE)
						{
							//new String:error[255];
							SQL_GetError(dbcSkills, error, sizeof(error));
							PrintToServer("[AMXX: skillrank] Couldnt search for all time speed run record in table skillmaps. Plugin cancelled.", error);
							CloseHandle(resultMaps);
						} 
						else if (!SQL_FetchRow(resultMaps))
						{
							//ClientCommand(0,"play %s",RECORD_SOUND);
							EmitSoundToClient(client, RECORD_SOUND, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
							
							new String:tempString[256];
							new Handle:pack2[4];
							CreateDataTimer(0.9, textTimer, pack2[0]); 
							WritePackCell(pack2[0], client);
							Format(tempString, 255, "%s\nBROKE THE SPEED RUN RECORD\nfor %s", name, mapname);
							WritePackString(pack2[0], tempString);
							
							CreateDataTimer(1.9, textTimer, pack2[1]); 
							WritePackCell(pack2[1], client);
							Format(tempString, 255, "in\n%i hours, %i minutes, %i seconds\nand gained\n%i points", nHours,nMinutes,nSeconds, sv_difficulty);
							WritePackString(pack2[1], tempString)
							
							CreateDataTimer(2.9, textTimer, pack2[2]); 
							WritePackCell(pack2[2], client);
							Format(tempString, 255, "say /top5 for ranks\nsay /mapstats for personal map stats");
							WritePackString(pack2[2], tempString)
							
							CreateDataTimer(3.9, textTimer, pack2[3]); 
							WritePackCell(pack2[3], client);
							Format(tempString, 255, "say /top5 for ranks\nsay /mapstats for personal map stats\nsay /skillme for all your stats");
							WritePackString(pack2[3], tempString)
							
							//ShowHudText(client, 0,"%s\n\nBROKE THE SPEED RUN RECORD\n\n\nfor %s\nin\n%i hours, %i minutes, %i seconds\nand gained\n%i points\n\nsay /top5 for ranks\nsay /mapstats for personal map stats\nsay /skillme for all your stats",name,mapname,nHours,nMinutes,nSeconds,sv_difficulty);
							CloseHandle(resultMaps);
						}
						else 
						{
							new allTimeRecord;
							while (resultMaps != INVALID_HANDLE && SQL_FetchRow(resultMaps)) 
							{
								allTimeRecord = SQL_FetchInt(resultMaps, 2); //"runTime"
								if (finishTime > allTimeRecord) { break; }
							}
							if (finishTime < RoundFloat(Float:allTimeRecord)) 
							{
								//ClientCommand(0,"play %s",RECORD_SOUND)
								EmitSoundToClient(client, RECORD_SOUND, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								
								
								new String:tempString[256];
								new Handle:pack3[4];
								CreateDataTimer(0.9, textTimer, pack3[0]); 
								WritePackCell(pack3[0], client);
								Format(tempString, 255, "%s\nBROKE THE SPEED RUN RECORD\nfor %s", name, mapname);
								WritePackString(pack3[0], tempString);
								
								CreateDataTimer(1.9, textTimer, pack3[1]); 
								WritePackCell(pack3[1], client);
								Format(tempString, 255, "in\n%i hours, %i minutes, %i seconds\nand gained\n%i points", nHours,nMinutes,nSeconds, sv_difficulty);
								WritePackString(pack3[1], tempString)
								
								CreateDataTimer(2.9, textTimer, pack3[2]); 
								WritePackCell(pack3[2], client);
								Format(tempString, 255, "say /top5 for ranks\nsay /mapstats for personal map stats");
								WritePackString(pack3[2], tempString)
								
								CreateDataTimer(3.9, textTimer, pack3[3]); 
								WritePackCell(pack3[3], client);
								Format(tempString, 255, "say /top5 for ranks\nsay /mapstats for personal map stats\nsay /skillme for all your stats");
								WritePackString(pack3[3], tempString)
								
								//ShowHudText(client, 0,"%s\n\nBROKE THE SPEED RUN RECORD\n\n\nfor %s\nin\n%i hours, %i minutes, %i seconds\nand gained\n%i points\n\nsay /top5 for ranks\nsay /mapstats for personal map stats\nsay /skillme for all your stats",name,mapname,nHours,nMinutes,nSeconds,sv_difficulty);
							} 
							else 
							{
								
								
								new String:tempString[256];
								new Handle:pack4[3];
								CreateDataTimer(0.9, textTimer, pack4[0]); 
								WritePackCell(pack4[0], client);
								Format(tempString, 255, "%s\n\nfinished %s in\n%i hours, %i minutes, %i seconds\nand gained\n%i points", name, mapname, nHours,nMinutes,nSeconds, sv_difficulty);
								WritePackString(pack4[0], tempString)
								
								CreateDataTimer(1.9, textTimer, pack4[1]); 
								WritePackCell(pack4[1], client);
								Format(tempString, 255, "say /top5 for ranks\nsay /mapstats for personal map stats");
								WritePackString(pack4[1], tempString)
								
								CreateDataTimer(2.9, textTimer, pack4[2]); 
								WritePackCell(pack4[2], client);
								Format(tempString, 255, "say /top5 for ranks\nsay /mapstats for personal map stats\nsay /skillme for all your stats");
								WritePackString(pack4[2], tempString)
								
								//ShowHudText(client, 0,"%s\n\nfinished %s in\n%i hours, %i minutes, %i seconds\nand gained\n%i points\n\nsay /top5 for ranks\nsay /mapstats for personal map stats\nsay /skillme for all your stats",name,mapname,nHours,nMinutes,nSeconds,sv_difficulty);
								EmitSoundToAll(FINISH_SOUND, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
								//ClientCommand(0,"spk %s",FINISH_SOUND);
							}
							CloseHandle(resultMaps);
						}
						Command_showTimerMenu(client, 0);
						//show_menu(client, keysTimerMenu, "Want to be teleported back to start?\n\n1: Yes\n2: No\n\n", -1, "timerMenu") // Display menu
						sql_insert_ranks(client);
						sql_insert_maps(client,finishTime);
						hasTimer[client] = false;
					}
				} 
				else 
				{
					//ClientCommand(0,"spk %s",FINISH_SOUND)
					EmitSoundToAll(FINISH_SOUND, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
					
					
					new String:tempString[256];
					new Handle:pack5[3];
					CreateDataTimer(0.9, textTimer, pack5[0]); 
					WritePackCell(pack5[0], client);
					Format(tempString, 255, "%s\n\nfinished %s and gained\n%i points", name, mapname, sv_difficulty);
					WritePackString(pack5[0], tempString)
					
					CreateDataTimer(1.9, textTimer, pack5[1]); 
					WritePackCell(pack5[1], client);
					Format(tempString, 255, "say /top5 for ranks\nsay /mapstats for personal map stats");
					WritePackString(pack5[1], tempString)
					
					CreateDataTimer(2.9, textTimer, pack5[2]); 
					WritePackCell(pack5[2], client);
					Format(tempString, 255, "say /top5 for ranks\nsay /mapstats for personal map stats\nsay /skillme for all your stats");
					WritePackString(pack5[2], tempString)
					
					//ShowHudText(client, 0,"%s\n\nfinished %s and gained %i points\n\nsay /top5 for ranks\nsay /mapstats for personal map stats\nsay /skillme for all your stats",name,mapname,sv_difficulty);
					sql_insert_ranks(client);
					new finishTime = 0;
					sql_insert_maps(client,finishTime);
					if (debugSkills) { PrintToServer("[AMXX: skillrank DEBUG] Finished without touching timer Nickname = %s finishtime = %i sv_difficulty = %i",name,finishTime,sv_difficulty); }
				}
				totalFinnish++;
			}
		}
		//}
	}
	return Plugin_Continue;
}

public Action:msgToNewPlayerTimer(Handle:timer, any:client)
{
	msgToNewPlayer(client);
}

public Action:textTimer(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new String:tempString[256];
	ReadPackString(pack, tempString, 255);
	PrintToChat(client, tempString);
	return Plugin_Handled;
}


public Action:msgToNewPlayer (client) 
{
	new String:name[32]; GetClientName(client, name, 31);
	new sv_difficulty = GetConVarInt(sv_diff);
	new String:mapname[64]; GetCurrentMap(mapname, 63);
	//decl String:query[512];
	if(sv_difficulty > 0)
	{
		if(GetConVarFloat(x_goal) != 0.0 && GetConVarFloat(y_goal) != 0.0 && GetConVarFloat(z_goal) != 0.0)
		{
			new String:hostname[64]; GetConVarString(gHostname, hostname, 63);
			// Query for alltime speedrun record on current map
			new String:error[255];
			dbcSkills = SQL_DefConnect(error, sizeof(error));
			decl String:query[512];
	 
			if (dbcSkills == INVALID_HANDLE)
			{
				PrintToServer("Could not connect to skillrank: %s", error);
			} 
			else 
			{
				Format(query, sizeof(query), "SELECT nickNames,curDate,runTime FROM skillmaps where mapName='%s' AND runTime>'%i' ORDER BY runTime ASC LIMIT 1",mapname,0);
				resultMaps = SQL_Query(dbcSkills,query);
				if(resultMaps == INVALID_HANDLE)
				{
					PrintToServer("[AMXX: skillrank] Couldnt search for all time speed run record in table skillmaps. Plugin cancelled.");
					CloseHandle(resultMaps);
					return Plugin_Handled;
				}
				else if (!SQL_FetchRow(resultMaps))
				{
				
					new String:tempString[256];
					new Handle:pack[3];
					CreateDataTimer(0.9, textTimer, pack[0]); 
					WritePackCell(pack[0], client);
					Format(tempString, 255, "Welcome to %s %s.\nRank points if you finish = %i.", name, mapname, sv_difficulty);
					WritePackString(pack[0], tempString)
					
					CreateDataTimer(1.9, textTimer, pack[1]); 
					WritePackCell(pack[1], client);
					Format(tempString, 255, "Speedrun record: No record set yet");
					WritePackString(pack[1], tempString)
					
					CreateDataTimer(2.9, textTimer, pack[2]); 
					WritePackCell(pack[2], client);
					Format(tempString, 255, "COMMANDS: Say /top5 /skillme /mapstats or /difficulty");
					WritePackString(pack[2], tempString)
				}
				else
				{
					//SQL_FetchRow(resultMaps);
					new allTimeRecord;
					new String:recordHolder[32];
					new String:recordDate[32];
					allTimeRecord = SQL_FetchInt(resultMaps, 2); //"runtime"
					SQL_FetchString(resultMaps, 0, recordHolder,31); //"nicknames"
					SQL_FetchString(resultMaps, 1, recordDate,31); //"curdate"
					new finishTime = allTimeRecord;
					new nHours = int:((finishTime / 3600) % 24);
					new nMinutes = int:((finishTime / 60) % 60);
					new nSeconds = int:(finishTime % 60);
					//set_hudmessage( 200, 100, 0, -1.0, 35.0, 0, 6.0, 20.0, 0.3, 0.3, 4 )
					
			
					new String:tempString[256];
					new Handle:pack[3];
					CreateDataTimer(0.9, textTimer, pack[0]); 
					WritePackCell(pack[0], client);
					Format(tempString, 255, "Welcome to %s %s.\nRank points if you finish = %i.", name, mapname, sv_difficulty);
					WritePackString(pack[0], tempString)
					
					CreateDataTimer(1.9, textTimer, pack[1]); 
					WritePackCell(pack[1], client);
					Format(tempString, 255, "Speedrun record on %s\nSet by %s %s:\n%i hours, %i minutes, %i seconds", mapname,recordHolder,recordDate,nHours,nMinutes,nSeconds);
					WritePackString(pack[1], tempString)
					
					CreateDataTimer(2.9, textTimer, pack[2]); 
					WritePackCell(pack[2], client);
					Format(tempString, 255, "COMMANDS: Say /top5 /skillme /mapstats or /difficulty");
					WritePackString(pack[2], tempString)
				}
				CloseHandle(resultMaps);
			}
			CloseHandle(dbcSkills);
		}
	}
	return Plugin_Continue;
}

public Action:msgToReconnectTimer(Handle:timer, any:client)
{
	msgToReconnect(client);
}

msgToReconnect (client) {
	new String:name[32]; GetClientName(client, name, 31);
	if(GetConVarInt(sv_diff) > 0)
	{
		if(GetConVarFloat(x_goal) != 0.0 && GetConVarFloat(y_goal) != 0.0 && GetConVarFloat(z_goal) != 0.0)
		{
			PrintToChat(client, "Welcome back %s! Wait to map change before getting new points. You can still speed run.",name);
		}
	}
}

/*
msgToToManyclient (client) 
{

	new String:name[32]; GetClientName(client, name, 31);
	new sv_difficulty = GetConVarInt(sv_diff);
	if(sv_difficulty > 0)
	{ 
		if(GetConVarFloat(x_goal) != 0.0 && GetConVarFloat(y_goal) != 0.0 && GetConVarFloat(z_goal) != 0.0)
		{
			new String:hostname[64];
			GetConVarString(gHostname, hostname, 63);
			PrintToChat(client, "Welcome to %s %s. Currently your ranks can't be saved. Map difficulty is %i of 100.",hostname,name,sv_difficulty);
		}
	}
}
*/


// Insert into table skillrank
public Action:sql_insert_ranks(client) 
{
	//if(dbcSkills == INVALID_HANDLE) { return Plugin_Continue; }
	new sv_difficulty = GetConVarInt(sv_diff);
	new String:authclient[32]; GetClientAuthString(client, authclient, 31);
	new String:name[32]; GetClientName(client, name, 31);
	//Update user info when a map is finished
	new String:error[255];
	dbcSkills = SQL_DefConnect(error, sizeof(error));
	decl String:query[512];
	 
	if (dbcSkills == INVALID_HANDLE)
	{
		PrintToServer("Could not connect to skillrank: %s", error);
	} 
	else 
	{
		Format(query, sizeof(query), "SELECT * FROM skillrank where steamclient ='%s'",authclient);
		resultRanks = SQL_Query(dbcSkills, query);
		if(resultRanks == INVALID_HANDLE)
		{
			PrintToServer("[AMXX: skillrank] Couldnt do the search in the database");
			return Plugin_Handled;
		}
		else if (!SQL_FetchRow(resultRanks))
		{
			Format(query, sizeof(query), "INSERT INTO skillrank (steamclient, nickNames, nFinnished, rankTotal, primaryRank) values ('%s','%s',%i,%i,%i)",authclient,name,1,sv_difficulty,sv_difficulty);
			resultRanks = SQL_Query(dbcSkills, query);
			CloseHandle(resultRanks);
		}
		else
		{
			Format(query, sizeof(query), "UPDATE skillrank SET nickNames='%s',nFinnished=nFinnished+1,rankTotal=rankTotal+%i,primaryRank=((rankTotal+%i)/(nFinnished+1)) WHERE steamclient='%s'",name,sv_difficulty,sv_difficulty,authclient);
			resultRanks = SQL_Query(dbcSkills, query);
			CloseHandle(resultRanks);
		}
	}
	CloseHandle(dbcSkills);
	return Plugin_Continue;
}

// Insert into table skillmaps
// The 'runTime' column is a place holder for speed run times in future version. 0 is added until this is done.
public Action:sql_insert_maps(client,finishTime) 
{
	//if(dbcSkills == INVALID_HANDLE) { return Plugin_Continue; }
	new sv_difficulty = GetConVarInt(sv_diff);
	//new stamp[2]; GetTime(stamp);
	new String:curTime[10]; FormatTime(curTime, 9, "%H:%M:%S");
	new String:curDate[32]; FormatTime(curDate, 31, "%d,%m,%y");
	new String:authclient[32]; GetClientAuthString(client, authclient, 31);
	new String:name[32]; GetClientName(client, name, 31);
	new String:mapname[64]; GetCurrentMap(mapname, 63);
	new class = int:TF2_GetPlayerClass(client);
	if(class == 1) { class = 0; }
	//Insert finished maps and who finished them in table skillmaps
	new String:error[255];
	dbcSkills = SQL_DefConnect(error, sizeof(error));
	decl String:query[512];
	 
	if (dbcSkills == INVALID_HANDLE)
	{
		PrintToServer("Could not connect to skillrank: %s", error);
	} 
	else 
	{
		Format(query, sizeof(query), "INSERT INTO skillmaps (steamclient, nickNames, mapName, playerClass, curDate,curTime,difficulty, runTime) values ('%s','%s','%s',%i,'%s','%s',%i,%i)",authclient,name,mapname,class,curDate,curTime,sv_difficulty,finishTime);
		resultMaps = SQL_Query(dbcSkills, query);
		if(resultMaps == INVALID_HANDLE)
		{
			PrintToServer("[AMXX: skillrank] Couldnt insert to table skillmaps")
			//CloseHandle(resultMaps);
			return Plugin_Handled;
		}
		CloseHandle(resultMaps);
		if(debugSkills) { PrintToServer("[AMXX: skillrank DEBUG] Inserted into maps table: '%s','%s','%s',%i,'%s','%s',%i,%i",authclient,name,mapname,class,curDate,curTime,sv_difficulty,finishTime); }
	}
	CloseHandle(dbcSkills);
	return Plugin_Continue;
}


// Pick the top five players of number of finished maps, total ranks and best average rank
// and show an MOTD to the player.
public Action:Command_showTopFive(client, args) 
{
	new ln = 0, qryFinnished[32], qryPrimaryRank;
	new String:motd[2048], qryRankTotal, String:qryNickname[32];
	new String:title[32];
	new String:hostname[64];
	GetConVarString(gHostname, hostname, 63);
	Format(title, 31, "TOP 5 LIST @ %s", hostname);
	// Search for top 5 player with best average difficulty
	new String:error[255];
	dbcSkills = SQL_DefConnect(error, sizeof(error));
	decl String:query[512];
	 
	if (dbcSkills == INVALID_HANDLE)
	{
		PrintToServer("Could not connect to skillrank: %s", error);
	} 
	else 
	{
		Format(query, sizeof(query), "SELECT nickNames, primaryRank,nFinnished FROM `skillrank` WHERE nFinnished>=%i ORDER BY primaryRank DESC LIMIT 5",uberCount);
		resultRanks = SQL_Query(dbcSkills, query);
		if(resultRanks == INVALID_HANDLE)
		{
			PrintToServer("[AMXX: skillrank] Couldnt search for nickNames, primaryRank,nFinnished in table skillranks. Plugin cancelled.");
			return Plugin_Handled;
		}
		else if(!SQL_FetchRow(resultRanks))
		{
			PrintToChat(client, "Noone have finished %i maps yet. Do it an be the first UBER :)",uberCount);
			ln += Format(motd[ln], 2047-ln,"\n<<<================= [ UBERS ] =================>>>\n");
			ln += Format(motd[ln], 2047-ln,"Sorry we have no ubers yet. Finish more maps\n\n");
		}
		else
		{
			new incrUberCount = 0;
			new incrPosition = 0;
			//Loop through the result set
			ln += Format(motd[ln], 2047-ln,"\n<<<================= [ UBERS ] =================>>>\n");
			qryFinnished[incrUberCount] = SQL_FetchInt(resultRanks, 2); //"nFinnished"
			if (qryFinnished[incrUberCount] >= uberCount) 
			{
				SQL_FetchString(resultRanks, 0, qryNickname, 31); //nicknames
				qryPrimaryRank = SQL_FetchInt(resultRanks, 1); //"primaryRank"
				ln += Format(motd[ln], 2047-ln,"%i. %s = %i\n",++incrPosition,qryNickname, qryPrimaryRank);
			}
			while (resultRanks && SQL_FetchRow(resultRanks)) 
			{
				qryFinnished[incrUberCount] = SQL_FetchInt(resultRanks, 2); //"nFinnished"
				if (qryFinnished[incrUberCount] >= uberCount) 
				{
					SQL_FetchString(resultRanks, 0, qryNickname, 31); //nicknames
					qryPrimaryRank = SQL_FetchInt(resultRanks, 1); //"primaryRank"
					ln += Format(motd[ln], 2047-ln,"%i. %s = %i\n",++incrPosition,qryNickname, qryPrimaryRank);
				}
				if (!SQL_FetchRow(resultRanks)) { continue; }
				qryFinnished[incrUberCount] = SQL_FetchInt(resultRanks, 2) ; //"nFinnished"
				if (qryFinnished[incrUberCount] >= uberCount) 
				{
					SQL_FetchString(resultRanks, 0, qryNickname, 31) ; //"nicknames" 
					qryPrimaryRank = SQL_FetchInt(resultRanks, 1); //"primaryRank"
					ln += Format(motd[ln], 2047-ln,"%i. %s = %i\n",++incrPosition,qryNickname, qryPrimaryRank);
				}
				if (!SQL_FetchRow(resultRanks)) { continue; }
				qryFinnished[incrUberCount] = SQL_FetchInt(resultRanks, 2) ;
				if (qryFinnished[incrUberCount] >= uberCount) 
				{
					SQL_FetchString(resultRanks, 0, qryNickname, 31) ;
					qryPrimaryRank = SQL_FetchInt(resultRanks, 1);
					ln += Format(motd[ln], 2047-ln,"%i. %s = %i\n",++incrPosition,qryNickname, qryPrimaryRank);
				}
				if (!SQL_FetchRow(resultRanks)) { continue; }
				qryFinnished[incrUberCount] = SQL_FetchInt(resultRanks, 2) ;
				if (qryFinnished[incrUberCount] >= uberCount) 
				{
					SQL_FetchString(resultRanks, 0, qryNickname, 31) ;
					qryPrimaryRank = SQL_FetchInt(resultRanks, 1);
					ln += Format(motd[ln], 2047-ln,"%i. %s = %i\n",++incrPosition,qryNickname, qryPrimaryRank);
				}
				if (!SQL_FetchRow(resultRanks)) { continue; }
				qryFinnished[incrUberCount] = SQL_FetchInt(resultRanks, 2) ;
				if (qryFinnished[incrUberCount] >= uberCount) 
				{
					SQL_FetchString(resultRanks, 0, qryNickname, 31) ;
					qryPrimaryRank = SQL_FetchInt(resultRanks, 1);
					ln += Format(motd[ln], 2047-ln,"%i. %s = %i\n",++incrPosition,qryNickname, qryPrimaryRank);
				}
			}
			CloseHandle(resultRanks);
		}
		Format(query, sizeof(query),"SELECT nickNames, primaryRank FROM `skillrank` ORDER BY `primaryRank` DESC LIMIT 5");
		resultRanks = SQL_Query(dbcSkills, query);
		if (resultRanks == INVALID_HANDLE) 
		{
			PrintToServer("[AMXX: skillrank] Couldnt search for nickNames, primaryRank in table skillranks. Plugin cancelled.");
			return Plugin_Handled;
		} 
		else if (!SQL_FetchRow(resultRanks)) 
		{
			PrintToChat(client, "Nothing added to the database yet. Finish 1 time and you will be first :)");
		} 
		else 
		{
			// Search for top 5 players with highest ranks
			Format(query, sizeof(query),"SELECT nickNames, rankTotal FROM `skillrank` ORDER BY `rankTotal` DESC LIMIT 5");
			resultRanks = SQL_Query(dbcSkills, query);
			if (resultRanks == INVALID_HANDLE ) 
			{
				PrintToServer("[AMXX: skillrank] Couldnt search for rankTotal in table skillranks. Plugin cancelled.");
				return Plugin_Handled;
			}
			//Loop through the result set
			ln += Format(motd[ln], 2047-ln,"\n<<<=============== [ HIGH RANKERS ] =============>>>");
			while (resultRanks && SQL_FetchRow(resultRanks)) 
			{ 
				SQL_FetchString(resultRanks, 0, qryNickname, 31) ;
				qryRankTotal = SQL_FetchInt(resultRanks, 1);
				ln += Format(motd[ln], 2047-ln,"\n1. %s = %i",qryNickname, qryRankTotal);

				if (!SQL_FetchRow(resultRanks)) { continue; }
				SQL_FetchString(resultRanks, 0, qryNickname, 31) ;
				qryRankTotal = SQL_FetchInt(resultRanks, 1);
				ln += Format(motd[ln], 2047-ln,"\n2. %s = %i",qryNickname, qryRankTotal);

				if (!SQL_FetchRow(resultRanks)) { continue; }
				SQL_FetchString(resultRanks, 0, qryNickname, 31) ;
				qryRankTotal = SQL_FetchInt(resultRanks, 1);
				ln += Format(motd[ln], 2047-ln,"\n3. %s = %i",qryNickname, qryRankTotal);

				if (!SQL_FetchRow(resultRanks)) { continue; }
				SQL_FetchString(resultRanks, 0, qryNickname, 31) ;
				qryRankTotal = SQL_FetchInt(resultRanks, 1);
				ln += Format(motd[ln], 2047-ln,"\n4. %s = %i",qryNickname, qryRankTotal);

				if (!SQL_FetchRow(resultRanks)) { continue; }
				SQL_FetchString(resultRanks, 0, qryNickname, 31) ;
				qryRankTotal = SQL_FetchInt(resultRanks, 1);
				ln += Format(motd[ln], 2047-ln,"\n5. %s = %i\n",qryNickname, qryRankTotal);
			}
			CloseHandle(resultRanks)
			
			// Search for top 5 players who finished most times
			Format(query, sizeof(query),"SELECT nickNames, nFinnished FROM `skillrank` ORDER BY `nFinnished` DESC LIMIT 5");
			resultRanks = SQL_Query(dbcSkills, query);
			if (resultRanks == INVALID_HANDLE ) 
			{
				PrintToServer("[AMXX: skillrank] Couldnt search for nFinnished in table skillranks. Plugin cancelled.");
				return Plugin_Handled;
			}
			//Loop through the result set
			new qryFinnished2;
			ln += Format(motd[ln], 2047-ln,"\n<<<=========== [ MOST FINISHED MAPS ] ===========>>>");
			while (resultRanks && SQL_FetchRow(resultRanks)) 
			{ 
				SQL_FetchString(resultRanks, 0, qryNickname, 31) ;
				qryFinnished2 = SQL_FetchInt(resultRanks, 1);
				ln += Format(motd[ln], 2047-ln,"\n1. %s = %i",qryNickname, qryFinnished2);

				if (!SQL_FetchRow(resultRanks)) { continue; }
				SQL_FetchString(resultRanks, 0, qryNickname, 31) ;
				qryFinnished2 = SQL_FetchInt(resultRanks, 1);
				ln += Format(motd[ln], 2047-ln,"\n2. %s = %i",qryNickname, qryFinnished2);

				if (!SQL_FetchRow(resultRanks)) { continue; }
				SQL_FetchString(resultRanks, 0, qryNickname, 31) ;
				qryFinnished2 = SQL_FetchInt(resultRanks, 1);
				ln += Format(motd[ln], 2047-ln,"\n3. %s = %i",qryNickname, qryFinnished2);

				if (!SQL_FetchRow(resultRanks)) { continue; }
				SQL_FetchString(resultRanks, 0, qryNickname, 31) ;
				qryFinnished2 = SQL_FetchInt(resultRanks, 1);
				ln += Format(motd[ln], 2047-ln,"\n4. %s = %i",qryNickname, qryFinnished2);

				if (!SQL_FetchRow(resultRanks)) { continue; }
				SQL_FetchString(resultRanks, 0, qryNickname, 31) ;
				qryFinnished2 = SQL_FetchInt(resultRanks, 1);
				ln += Format(motd[ln], 2047-ln,"\n5. %s = %i",qryNickname, qryFinnished2);
			}
			CloseHandle(resultRanks);
			SetLongMOTD("tMOTD", motd);
			new Handle:pack;
			CreateDataTimer(1.0, timerMOTD, pack);
			WritePackCell(pack, client);
			WritePackString(pack, title);
			WritePackString(pack, "tMOTD");
			//ShowMOTDPanel(client, title, motd, MOTDPANEL_TYPE_TEXT);
		}
	}
	CloseHandle(dbcSkills);
	return Plugin_Handled;
}


public Action:Command_showMapStats(client, args) 
{
	new String:name[32] ; GetClientName(client,name,31);
	new String:mapname[64] ; GetCurrentMap(mapname,63);
	new String:authclient[32] ; GetClientAuthString(client,authclient,31);
	new String:mapStatsTitle[32];
	new sv_difficulty = GetConVarInt(sv_diff);
	Format(mapStatsTitle,31,"Map stats: %s",name);
	new String:mapStatsMotd[2048],len=0, foundFirstDate=0, totalFinnished=0,rankSum=0;
	new scoutSum=0, sniperSum=0,soldierSum=0,demomanSum=0,medicSum=0,hwguySum=0,pyroSum=0,spySum=0,engineerSum=0,civilianSum=0;
	
	// Query for player info on this map and show him speedrun record
	new String:qryDate[maxFinishedMaps];
	new String:error[255];
	dbcSkills = SQL_DefConnect(error, sizeof(error));
	decl String:query[512];
	 
	if (dbcSkills == INVALID_HANDLE)
	{
		PrintToServer("Could not connect to skillrank: %s", error);
	} 
	else 
	{
		Format(query, sizeof(query), "SELECT curDate FROM skillmaps where steamclient='%s' AND mapName='%s' ORDER BY curDate ASC",authclient,mapname);
		resultMaps = SQL_Query(dbcSkills, query);
		len += Format(mapStatsMotd[len], 2047-len,"\nMap: %s || ",mapname);
		if (resultMaps == INVALID_HANDLE ) 
		{
			PrintToServer("[AMXX: skillrank] Couldnt search for authclient in table skillmaps. Plugin cancelled.");
			return Plugin_Handled;
		} 
		else if (!SQL_FetchRow(resultMaps)) 
		{
			if (sv_difficulty != 0) { len += Format(mapStatsMotd[len], 2047-len,"Difficulty: %i\n\n",sv_difficulty); }
			len += Format(mapStatsMotd[len], 2047-len,"First time finished: NEVER\n");
			CloseHandle(resultMaps);
			
			// Query for alltime speedrun record on current map
			Format(query, sizeof(query), "SELECT nickNames,curDate,runTime FROM skillmaps where mapName='%s' AND runTime>'%i' ORDER BY runTime ASC LIMIT 1",mapname,0);
			resultMaps = SQL_Query(dbcSkills, query);
			if (resultMaps == INVALID_HANDLE ) 
			{
				PrintToServer("[AMXX: skillrank] Couldnt search for all time speed run record in table skillmaps. Plugin cancelled.");
				return Plugin_Handled;
			} 
			else if (!SQL_FetchRow(resultMaps)) 
			{
				len += Format(mapStatsMotd[len], 2047-len,"\nSpeedrun record: No record set yet\n");
			} 
			else 
			{
				new allTimeRecord, String:recordHolder[32], String:recordDate[32];
				//SQL_FetchRow(resultMaps);
				allTimeRecord = SQL_FetchInt(resultMaps, 2);
				SQL_FetchString(resultMaps, 0, recordHolder,31);
				SQL_FetchString(resultMaps, 1, recordDate,31);
				new finishTime = allTimeRecord;
				new nHours = int:((finishTime / 3600) % 24);
				new nMinutes = int:((finishTime / 60) % 60) ;
				new nSeconds = int:(finishTime % 60);
				len += Format(mapStatsMotd[len], 2047-len,"\nSpeedrun record: Set by %s %s: %i hours, %i minutes, %i seconds\n",recordHolder,recordDate,nHours,nMinutes,nSeconds);
			}
			CloseHandle(resultMaps);
		} 
		else 
		{
			//uncertain
			if (foundFirstDate == 0) 
			{
				SQL_FetchString(resultMaps, 0, qryDate, maxFinishedMaps-1);
				len += Format(mapStatsMotd[len], 2047-len,"Difficulty: %i\n\n",sv_difficulty);
				len += Format(mapStatsMotd[len], 2047-len,"First time finished: %s\n",qryDate);
				foundFirstDate = 1;
			}
			totalFinnished++;
			//uncertain
			while (resultMaps && SQL_FetchRow(resultMaps)) //
			{
				if (foundFirstDate == 0) 
				{
					SQL_FetchString(resultMaps, 0, qryDate, maxFinishedMaps-1);
					len += Format(mapStatsMotd[len], 2047-len,"Difficulty: %i\n\n",sv_difficulty);
					len += Format(mapStatsMotd[len], 2047-len,"First time finished: %s\n",qryDate);
					foundFirstDate = 1;
				}
				totalFinnished++;
			}
			
			len += Format(mapStatsMotd[len], 2047-len,"Finished number of times: %i\n",totalFinnished);
			rankSum = sv_difficulty * totalFinnished;
			len += Format(mapStatsMotd[len], 2047-len,"Total collected points on %s: %i\n",mapname,rankSum);
			CloseHandle(resultMaps);
			
			// Query for personal speedrun record
			Format(query, sizeof(query), "SELECT runTime FROM skillmaps where steamclient='%s' AND mapName='%s' AND runTime>'%i' ORDER BY runTime ASC LIMIT 1",authclient,mapname,0);
			resultMaps = SQL_Query(dbcSkills, query);
			if (resultMaps == INVALID_HANDLE ) 
			{
				PrintToServer("[AMXX: skillrank] Couldnt search for personal speed run record in table skillmaps. Plugin cancelled.");
				return Plugin_Handled;
			} 
			else if (!SQL_FetchRow(resultMaps)) 
			{
				len += Format(mapStatsMotd[len], 2047-len,"Your best speedrun: You have done no speedrun on this map yet\n");
			} 
			else 
			{
				new personalRecord;
				//SQL_FetchRow(resultMaps);
				personalRecord = SQL_FetchInt(resultMaps, 0);
				new finishTime = personalRecord;
				new nHours = int:((finishTime / 3600) % 24);
				new nMinutes = int:((finishTime / 60) % 60 );
				new nSeconds = int:(finishTime % 60);
				len += Format(mapStatsMotd[len], 2047-len,"Your best speedrun: %i hours, %i minutes, %i seconds\n",nHours,nMinutes,nSeconds);
			}
			CloseHandle(resultMaps);
			
			// Query for alltime speedrun record on current map
			Format(query, sizeof(query), "SELECT nickNames,curDate,runTime FROM skillmaps where mapName='%s' AND runTime>'%i' ORDER BY runTime ASC LIMIT 1",mapname,0);
			resultMaps = SQL_Query(dbcSkills, query);
			if (resultMaps == INVALID_HANDLE ) 
			{
				PrintToServer("[AMXX: skillrank] Couldnt search for all time speed run record in table skillmaps. Plugin cancelled.");
				return Plugin_Handled;
			} 
			else if (!SQL_FetchRow(resultMaps)) 
			{
				len += Format(mapStatsMotd[len], 2047-len,"\nSpeedrun record: No record set yet\n");
			} 
			else 
			{
				new allTimeRecord, String:recordHolder[32], String:recordDate[32];
				//SQL_FetchRow(resultMaps);
				allTimeRecord = SQL_FetchInt(resultMaps, 2);
				SQL_FetchString(resultMaps, 0, recordHolder,31);
				SQL_FetchString(resultMaps, 1, recordDate,31);
				new finishTime = allTimeRecord;
				new nHours = int:((finishTime / 3600) % 24);
				new nMinutes = int:((finishTime / 60) % 60 );
				new nSeconds = int:(finishTime % 60);
				len += Format(mapStatsMotd[len], 2047-len,"\nSpeedrun record: Set by %s %s: %i hours, %i minutes, %i seconds\n",recordHolder,recordDate,nHours,nMinutes,nSeconds);
			}
			CloseHandle(resultMaps);
			
			// Query for number of times finished of each class
			len += Format(mapStatsMotd[len], 2047-len,"\nFinished with class: \n");
			Format(query, sizeof(query), "SELECT playerClass FROM skillmaps where steamclient='%s' AND mapName='%s' ORDER BY curDate ASC",authclient,mapname);
			resultMaps = SQL_Query(dbcSkills, query);
			if (resultMaps == INVALID_HANDLE )
			{
				PrintToServer("[AMXX: skillrank] Couldnt search for player class in table  skillmaps. Plugin cancelled.");
				return Plugin_Handled;
			} 
			else 
			{
				new qryClass[maxFinishedMaps];
				new incrQryClass = 0;
				while (resultMaps && SQL_FetchRow(resultMaps)) //
				{
					qryClass[incrQryClass] = SQL_FetchInt(resultMaps, 0);
					if (qryClass[incrQryClass] == 0)
						++scoutSum;
					else if (qryClass[incrQryClass] == 2)
						++sniperSum;
					else if (qryClass[incrQryClass] == 3)
						++soldierSum;
					else if (qryClass[incrQryClass] == 4)
						++demomanSum;
					else if (qryClass[incrQryClass] == 5)
						++medicSum;
					else if (qryClass[incrQryClass] == 6)
						++hwguySum;
					else if (qryClass[incrQryClass] == 7)
						++pyroSum;
					else if (qryClass[incrQryClass] == 8)
						++spySum;
					else if (qryClass[incrQryClass] == 9)
						++engineerSum;
					else
						++civilianSum;
					++incrQryClass;
				}
			}
			len += Format(mapStatsMotd[len], 2047-len,"Scout: %i\n",scoutSum);
			len += Format(mapStatsMotd[len], 2047-len,"Sniper: %i\n",sniperSum);
			len += Format(mapStatsMotd[len], 2047-len,"Soldier: %i\n",soldierSum);
			len += Format(mapStatsMotd[len], 2047-len,"Demoman: %i\n",demomanSum);
			len += Format(mapStatsMotd[len], 2047-len,"Medic: %i\n",medicSum);
			len += Format(mapStatsMotd[len], 2047-len,"Hwguy: %i\n",hwguySum);
			len += Format(mapStatsMotd[len], 2047-len,"Pyro: %i\n",pyroSum);
			len += Format(mapStatsMotd[len], 2047-len,"Spy: %i\n",spySum);
			len += Format(mapStatsMotd[len], 2047-len,"Engineer: %i\n",engineerSum);
			len += Format(mapStatsMotd[len], 2047-len,"Civilian: %i\n",civilianSum);
			CloseHandle(resultMaps);
		}
		SetLongMOTD("mapMOTD", mapStatsMotd);
		new Handle:pack;
		CreateDataTimer(1.0, timerMOTD, pack);
		WritePackCell(pack, client);
		WritePackString(pack, mapStatsTitle);
		WritePackString(pack, "mapMOTD");
		PrintToServer("%s", mapStatsMotd); //Print the value to the HLDS console
		//ShowMOTDPanel(client, mapStatsTitle, mapStatsMotd, MOTDPANEL_TYPE_TEXT);
	}
	CloseHandle(dbcSkills);
	return Plugin_Handled;
}


public Action:Command_showStats(client, args) 
{	
	new String:name[32] ; GetClientName(client,name,31);
	new String:authclient[32] ; GetClientAuthString(client,authclient,31);
	new String:statsMotd[2048],len1=0, String:statsTitle[32];
	
	Format(statsTitle,31,"Personal stats for %s",name);
	
	// Query for the first and last time the player finished a map
	new String:error[255];
	dbcSkills = SQL_DefConnect(error, sizeof(error));
	decl String:query[512];
	 
	if (dbcSkills == INVALID_HANDLE)
	{
		PrintToServer("Could not connect to skillrank: %s", error);
	} 
	else 
	{
		Format(query, sizeof(query), "SELECT curDate FROM `skillmaps` WHERE steamclient='%s' ORDER BY curDate ASC",authclient);
		resultMaps = SQL_Query(dbcSkills, query);
		new String:qryFirstDate[maxFinishedMaps];
		if (resultMaps == INVALID_HANDLE ) 
		{
			PrintToServer("[AMXX: skillrank] Couldnt search for date. Plugin cancelled.");
			return Plugin_Handled;
		} 
		else if (!SQL_FetchRow(resultMaps)) 
		{
			len1 += Format(statsMotd[len1], 2047-len1,"Sorry %s, you have to finish at least one map to see your stats.\n",name);
			SetLongMOTD("statsMOTD", statsMotd);
			new Handle:pack;
			CreateDataTimer(1.0, timerMOTD, pack);
			WritePackCell(pack, client);
			WritePackString(pack, statsTitle);
			WritePackString(pack, "statsMOTD");
			//ShowMOTDPanel(client, statsTitle, statsMotd, MOTDPANEL_TYPE_TEXT);
			CloseHandle(resultMaps);
			return Plugin_Handled;
		} 
		else 
		{
			//SQL_FetchRow(resultMaps);
			SQL_FetchString(resultMaps, 0, qryFirstDate, maxFinishedMaps-1);
			new nRows = SQL_GetRowCount(resultMaps);
			new incrRows = 1;
			len1 += Format(statsMotd[len1], 2047-len1,"First time you finished a map: %s\n",qryFirstDate);
			while (incrRows < nRows) 
			{
				SQL_FetchRow(resultMaps);
				incrRows++;
			}
			SQL_FetchString(resultMaps, 0, qryFirstDate, maxFinishedMaps-1);
			len1 += Format(statsMotd[len1], 2047-len1,"Last time you finished a map: %s\n\n\n",qryFirstDate);
			CloseHandle(resultMaps);
		}
		
		// Query current players uber factor
		Format(query, sizeof(query), "SELECT steamclient,nFinnished FROM `skillrank` where nFinnished>=%i AND steamclient ='%s'",uberCount,authclient);
		resultRanks = SQL_Query(dbcSkills, query);
		if (resultRanks == INVALID_HANDLE ) 
		{
			PrintToServer("[AMXX: skillrank] Couldnt search for rankTotal in table skillranks. Plugin cancelled.");
			return Plugin_Handled;
		}
		else if (!SQL_FetchRow(resultRanks)) 
		{
			len1 += Format(statsMotd[len1], 2047-len1,"<<<=========== [ UBER FACTOR ] ===========>>>\n");
			len1 += Format(statsMotd[len1], 2047-len1,"You have to finish at least %i maps to have a chance to be an uber.\n\n",uberCount);
			CloseHandle(resultRanks);
		} 
		else 
		{
			new incrUberCount = 0, incrUberPerson = 0, String:qryUber[maxFinishedMaps];
			new qryRankPrimaryRank;
			
			playersUberPosition = 0;
			Format(query, sizeof(query), "SELECT steamclient, primaryRank,nFinnished FROM `skillrank` WHERE nFinnished>=%i ORDER BY primaryRank DESC",uberCount);
			resultRanks = SQL_Query(dbcSkills, query);
			while (resultRanks && SQL_FetchRow(resultRanks))  //
			{
				SQL_FetchString(resultRanks, 0, qryUber[incrUberCount],maxFinishedMaps-1);
				if (incrUberPerson == 0) 
				{
					if (StrContains(qryUber[incrUberCount],authclient) != -1) 
					{
						incrUberPerson = 1;
						qryRankPrimaryRank = SQL_FetchInt(resultRanks, 1);
					}
					playersUberPosition++;
					incrUberCount++;
				}
			}
			new nUbers = SQL_GetRowCount(resultRanks);
			CloseHandle(resultRanks);
			len1 += Format(statsMotd[len1], 2047-len1,"<<<=========== [ UBER FACTOR ] ===========>>>\n");
			len1 += Format(statsMotd[len1], 2047-len1,"Your average difficulty of finished maps = %i\n",qryRankPrimaryRank);
			len1 += Format(statsMotd[len1], 2047-len1,"Your on place [%i] of [%i] ubers.\nHarder maps = more uber :)\n\n\n",playersUberPosition,nUbers);
		}
		
		// Query current players rank in number of finished maps
		Format(query, sizeof(query), "SELECT steamclient,nFinnished FROM `skillrank` ORDER BY nFinnished DESC");
		resultRanks = SQL_Query(dbcSkills, query);
		new String:qryRankFinnish1[maxPlayersInDB];
		if (resultRanks == INVALID_HANDLE ) 
		{
			PrintToServer("[AMXX: skillrank] Couldnt do rank search for players rank in number of finished maps. Plugin cancelled.");
			return Plugin_Handled;
		} 
		else if (!SQL_FetchRow(resultRanks) ) 
		{
			len1 += Format(statsMotd[len1], 2047-len1,"Sorry %s, you have to finish at least one map to see your stats.\n",name);
			SetLongMOTD("statsMOTD", statsMotd);
			new Handle:pack;
			CreateDataTimer(1.0, timerMOTD, pack);
			WritePackCell(pack, client);
			WritePackString(pack, statsTitle);
			WritePackString(pack, "statsMOTD");
			//ShowMOTDPanel(client, statsTitle, statsMotd, MOTDPANEL_TYPE_TEXT);
			CloseHandle(resultRanks);
			return Plugin_Handled;
		} 
		else 
		{
			new numFinishTotal=0, foundPlayerFinish=0;
			bestFinishedTotal=0, rankIncr1=0;
			//uncertain
			if (numFinishTotal != 1) 
			{
				topFinish = SQL_FetchInt(resultRanks,1);
				numFinishTotal=1;
			}
			SQL_FetchString(resultRanks, 0, qryRankFinnish1[rankIncr1], maxPlayersInDB-1);
			if (foundPlayerFinish != 1) 
			{
				if (StrContains(qryRankFinnish1[rankIncr1],authclient) != -1)
					foundPlayerFinish = 1;
				rankIncr1++;
			}
			//uncertain
			while (resultRanks && SQL_FetchRow(resultRanks)) //
			{
				if (numFinishTotal != 1) 
				{
					topFinish = SQL_FetchInt(resultRanks,1);
					numFinishTotal=1;
				}
				SQL_FetchString(resultRanks, 0, qryRankFinnish1[rankIncr1], maxPlayersInDB-1);
				if (foundPlayerFinish != 1) 
				{
					if (StrContains(qryRankFinnish1[rankIncr1],authclient) != -1)
						foundPlayerFinish = 1;
					rankIncr1++;
				}
			}
			bestFinishedTotal = SQL_GetRowCount(resultRanks);
			CloseHandle(resultRanks);
		}
		
		// Query current players rank in points collected
		Format(query, sizeof(query), "SELECT steamclient,rankTotal FROM `skillrank` ORDER BY rankTotal DESC");
		resultRanks = SQL_Query(dbcSkills, query);
		new String:qryRankTotal1[maxPlayersInDB];
		if (resultRanks == INVALID_HANDLE ) 
		{
			PrintToServer("[AMXX: skillrank] Couldnt do rank search for players rank in collected points. Plugin cancelled.");
			return Plugin_Handled;
		} 
		else if (!SQL_FetchRow(resultRanks) ) 
		{
			len1 += Format(statsMotd[len1], 2047-len1,"Sorry %s, you have to finish at least one map to see your stats.\n",name);
			SetLongMOTD("statsMOTD", statsMotd);
			new Handle:pack;
			CreateDataTimer(1.0, timerMOTD, pack);
			WritePackCell(pack, client);
			WritePackString(pack, statsTitle);
			WritePackString(pack, "statsMOTD");
			//ShowMOTDPanel(client, statsTitle, statsMotd, MOTDPANEL_TYPE_TEXT);
			CloseHandle(resultRanks);
			return Plugin_Handled;
		} 
		else 
		{
			new foundPlayerRank=0, numRankTotal=0;
			rankIncr2=0;
			//uncertain
			if (numRankTotal != 1) 
			{
				topRank = SQL_FetchInt(resultRanks, 1);
				numRankTotal=1;
			}
			SQL_FetchString(resultRanks, 0, qryRankTotal1[rankIncr2], maxPlayersInDB-1);
			if (foundPlayerRank != 1) 
			{
				if (StrContains(qryRankTotal1[rankIncr2],authclient) != -1)
					foundPlayerRank = 1;
				rankIncr2++;
			}
			//uncertain
			while (resultRanks && SQL_FetchRow(resultRanks)) //
			{
				if (numRankTotal != 1) 
				{
					topRank = SQL_FetchInt(resultRanks, 1);
					numRankTotal=1;
				}
				SQL_FetchString(resultRanks, 0, qryRankTotal1[rankIncr2], maxPlayersInDB-1);
				if (foundPlayerRank != 1) 
				{
					if (StrContains(qryRankTotal1[rankIncr2],authclient) != -1)
						foundPlayerRank = 1;
					rankIncr2++;
				}
			}
			bestRankTotal = SQL_GetRowCount(resultRanks);
			CloseHandle(resultRanks);
		}
		
		
		// Query for the players number of times finished maps, total points and average difficulty of finished maps
		new qryRankFinnished, qryRankTotal;
		Format(query, sizeof(query), "SELECT nFinnished,rankTotal,primaryRank FROM  `skillrank` WHERE steamclient='%s'",authclient);
		resultRanks = SQL_Query(dbcSkills, query);
		if (resultRanks == INVALID_HANDLE ) 
		{
			PrintToServer("[AMXX: skillrank] Couldnt do the rank search. Plugin cancelled.");
			return Plugin_Handled;
		} 
		else if (!SQL_FetchRow(resultRanks)) 
		{
			len1 += Format(statsMotd[len1], 2047-len1,"Sorry %s, you have to finish at least one map to see your stats.\n",name);
			SetLongMOTD("statsMOTD", statsMotd);
			new Handle:pack;
			CreateDataTimer(1.0, timerMOTD, pack);
			WritePackCell(pack, client);
			WritePackString(pack, statsTitle);
			WritePackString(pack, "statsMOTD");
			//ShowMOTDPanel(client, statsTitle, statsMotd, MOTDPANEL_TYPE_TEXT);
			CloseHandle(resultRanks);
			return Plugin_Handled;
		} 
		else 
		{
			//SQL_FetchRow(resultRanks);
			qryRankFinnished = SQL_FetchInt(resultRanks, 0);
			qryRankTotal = SQL_FetchInt(resultRanks, 1);
			len1 += Format(statsMotd[len1], 2047-len1,"<<<=========== [ FINISHED MAPS ] ===========>>>\n");
			len1 += Format(statsMotd[len1], 2047-len1,"You have finished %i maps\n",qryRankFinnished);
			len1 += Format(statsMotd[len1], 2047-len1,"Your on place [%i] of [%i]. (%i finished maps is highest)\n\n\n",rankIncr1,bestFinishedTotal,topFinish);
			len1 += Format(statsMotd[len1], 2047-len1,"<<<=========== [ RANK POINTS ] ===========>>>\n");
			len1 += Format(statsMotd[len1], 2047-len1,"You have collected %i points\n",qryRankTotal);
			len1 += Format(statsMotd[len1], 2047-len1,"Your on place [%i] of [%i]. (%i collected points is highest)\n\n",rankIncr2,bestRankTotal,topRank);
			SetLongMOTD("statsMOTD", statsMotd);
			new Handle:pack;
			CreateDataTimer(1.0, timerMOTD, pack);
			WritePackCell(pack, client);
			WritePackString(pack, statsTitle);
			WritePackString(pack, "statsMOTD");
			//ShowMOTDPanel(client, statsTitle, statsMotd,  MOTDPANEL_TYPE_TEXT);
			CloseHandle(resultRanks);
		}
	}
	CloseHandle(dbcSkills);
	return Plugin_Handled;
}

public Action:Command_Say(client, args)
{
	new String:text[192];
	GetCmdArgString(text, sizeof(text));
 
	new startidx = 0;
	if (text[0] == '"')
	{
		startidx = 1;
		/* Strip the ending quote, if there is one */
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0';
		}
	}
	
	if (StrEqual(text[startidx], "/difficulty"))
	{
		Command_mapDifficulty(client, args);
		/* Block the client's messsage from broadcasting */
		return Plugin_Handled;
	}
	else if (StrEqual(text[startidx], "/top5"))
	{
		Command_showTopFive(client, args);
		return Plugin_Handled;
	}
	else if (StrEqual(text[startidx], "/showStats"))
	{
		Command_showStats(client, args);
		return Plugin_Handled;
	}
	else if (StrEqual(text[startidx], "/showMapStats"))
	{
		Command_showMapStats(client, args);
		return Plugin_Handled;
	}
	else if (StrEqual(text[startidx], "/stopTimer"))
	{
		Command_showTimerMenu(client, args);
		return Plugin_Handled;
	}
 
	/* Let say continue normally */
	return Plugin_Continue;
}

public Action:timerMOTD(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new String:title[32]; ReadPackString(pack, title, 31);
	new String:panel[32]; ReadPackString(pack, panel, 31);
	ShowLongMOTD(client, title, panel);
}

// Starts the timer when speed running
/*public starttimer(client)
{
	if(IsClientConnected(client)) // if connected
	{
		if(IsPlayerAlive(client)) // if alive
		{
			showspr(client); // show clock above head
		}
	}
}*/

public skillsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		// called when menu choices have been done for adding and manipulating map configs
		switch (param2)
		{
			case 1: // key 1
			{
				new Float:origin[3];
				GetClientAbsOrigin(param1,origin);
				SetConVarFloat(x_start,origin[0]);
				SetConVarFloat(y_start,origin[1]);
				SetConVarFloat(z_start,origin[2]);
				PrintToChat(param1,"Start added");
				skillsmenu(param1, 0);
			}
			case 2: // key 2
			{
				new Float:origin[3];
				GetClientAbsOrigin(param1,origin);
				SetConVarFloat(x_goal,origin[0]);
				SetConVarFloat(y_goal,origin[1]);			
				SetConVarFloat(z_goal,origin[2]);
				PrintToChat(param1,"End added");
				skillsmenu(param1, 0);
			}
			case 3:  // key 0
			{
				diffimenu(param1, 0);
			}
		}
		PrintToConsole(param1, "You selected item: %d", param2);
		PrintToServer("Client %d selected item: %d from skillsmenu", param1, param2);
	} 
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
}


// Admin menu for adding and manipulating map configs
public Action:skillsmenu(client, args)
{
	new Handle:skillsMenu = CreatePanel();
	SetPanelTitle(skillsMenu, "Pick a task");
	DrawPanelItem(skillsMenu, "Add start model");
	DrawPanelItem(skillsMenu, "Add end model");
	DrawPanelItem(skillsMenu, "Goto difficulty menu");
	DrawPanelItem(skillsMenu, "Cancel");
	SendPanelToClient(skillsMenu, client, skillsMenuHandler, 20);
	CloseHandle(skillsMenu);
 
	return Plugin_Handled;
}
	
public modelMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	// Executed when choices done in the model menu
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1: // key 1
			{
				if(models[0] == -10)
				{
					spawnStartModel();
				}
				modelmenu(param1, 0);
			}
			case 2: // key 2
			{
				if(models[0] != -10)
				{
					RemoveEdict(models[0]);
					models[0] = -10;
				}
				modelmenu(param1, 0);
			}
			case 3: // key 3
			{
				if(models[1] == -10)
				{
					spawnGoalModel();
				}
				modelmenu(param1, 0);
			}
			case 4: // key 4
			{
				if(models[1] != -10)
				{
					RemoveEdict(models[1]);
					models[1] = -10;
				}
				modelmenu(param1, 0);
			}
			case 5: // key 5
			{
				if(models[0] != -10)
				{
					new Float:origin[3];
					GetClientAbsOrigin(param1,origin);
					SetConVarFloat(x_start,origin[0]);
					SetConVarFloat(y_start,origin[1]);
					SetConVarFloat(z_start,origin[2]);
					TeleportEntity(models[0], origin, NULL_VECTOR, NULL_VECTOR);

					origin[0] = origin[0] - 40.0;
					origin[2] = origin[2] + 20.0;
					TeleportEntity(param1,origin, NULL_VECTOR, NULL_VECTOR);
					PrintToChat(param1,"Moving you so you dont touch the start.");
					deletefile();
					modelmenu(param1, 0);
				}
			}
			case 6:
			{
				if(models[1] != -10)
				{
					new Float:origin[3];
					GetClientAbsOrigin(param1,origin);
					SetConVarFloat(x_goal,origin[0]);
					SetConVarFloat(y_goal,origin[1]);
					SetConVarFloat(z_goal,origin[2]);
					TeleportEntity(models[1], origin, NULL_VECTOR, NULL_VECTOR);

					origin[0] = origin[0] - 40.0;
					origin[2] = origin[2] + 20.0;
					TeleportEntity(param1,origin, NULL_VECTOR, NULL_VECTOR);
					PrintToChat(param1,"Moving you so you dont touch the end.");	
					 
					deletefile();
					modelmenu(param1, 0);
				}
			}
			case 7:
			{
				adminmenu(param1, 0);
			}
		}
		PrintToConsole(param1, "You selected item: %d", param2);
		PrintToServer("Client %d selected item: %d from modelmenu", param1, param2);
	} 
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
}

// Menu for adding or deletin start and goal models.
public Action:modelmenu(client, args)
{ // modelmenu
	new Handle:modelMenu = CreatePanel();
	SetPanelTitle(modelMenu, "Pick a task");
	DrawPanelItem(modelMenu, "Spawn start model");
	DrawPanelItem(modelMenu, "Remove start model");
	DrawPanelItem(modelMenu, "Spawn goal model");
	DrawPanelItem(modelMenu, "Remove goal model");
	DrawPanelItem(modelMenu, "Move start model to my location");
	DrawPanelItem(modelMenu, "Move goal model to my location");
	DrawPanelItem(modelMenu, "Goto Admin menu");
	DrawPanelItem(modelMenu, "Cancel");
	SendPanelToClient(modelMenu, client, modelMenuHandler, 20);
	CloseHandle(modelMenu);
 
	return Plugin_Handled;
}

public adminMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{	
	if (action == MenuAction_Select)
	{
		// Executed when choices done in the adminmenu
		switch (param2)
		{
			case 1: // key 1
			{
				modelmenu(param1, 0); // show other menu
			}
			case 2: // key 2
			{
				diffimenu(param1, 0); // show other menu
			}
			case 3: // key 3
			{
				skillsmenu(param1, 0); // show other menu
			}
		}
		PrintToConsole(param1, "You selected item: %d", param2);
		PrintToServer("Client %d selected item: %d from admin panel", param1, param2);
	} 
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
}

// Menu for admin to move/remove/spawn start & goal/set difficulty and teams allowed to finish & make map config
public Action:adminmenu(client,args)
{ 
	new Handle:adminMenu = CreatePanel();
	SetPanelTitle(adminMenu, "Pick a task");
	DrawPanelItem(adminMenu, "Move/Remove/Spawn start and goal");
	DrawPanelItem(adminMenu, "Set difficulty & goalteams");
	DrawPanelItem(adminMenu, "Make mapconfig");
	DrawPanelItem(adminMenu, "Cancel");
	SendPanelToClient(adminMenu, client, adminMenuHandler, 20);
	CloseHandle(adminMenu);
	return Plugin_Handled;
}
	
public diffiMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{	
	if (action == MenuAction_Select)
	{
		// Menu to select difficulty when admin is adding map config
		switch (param2) 
		{  
			case 1:  
			{ 
				menunumber = menunumber + 10; 
				if(menunumber > 100) menunumber = 100; 
				diffimenu(param1, 0);
			} 
			case 2:  
			{ 
				menunumber = menunumber + 5; 
				if(menunumber > 100) menunumber = 100; 
				diffimenu(param1, 0); 
			} 
			case 3:  
			{ 
				menunumber = menunumber + 1; 
				if(menunumber > 100) menunumber = 100; 
				diffimenu(param1, 0); 
			} 
			case 4:  
			{ 
				menunumber = menunumber - 10; 
				if(menunumber < 1) menunumber = 1;
				diffimenu(param1, 0);
			} 
			case 5:  
			{ 
				menunumber = menunumber - 5;
				if(menunumber < 1) menunumber = 1;
				diffimenu(param1, 0);
			} 
			case 6:  
			{ 
				menunumber = menunumber - 1;
				if(menunumber < 1) menunumber = 1;
				diffimenu(param1, 0);
			} 
			case 7:  
			{ 
				SetConVarInt(sv_diff,menunumber); 
				new String:name[32] ;
				GetClientName(param1,name,32) ;
				PrintToChatAll("Admin: %s has set the difficulty to %d",name,menunumber);
				//allowteams = "";
				//blockteammenu(client);
			} 
		} 
		PrintToConsole(param1, "You selected item: %d", param2);
		PrintToServer("Client %d selected item: %d from diffipanel", param1, param2);
	} 
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
}

// Menu options to select difficulty when admin is adding map config
public Action:diffimenu(client, args) 
{ 
	new Handle:diffiMenu = CreatePanel();
	new String:difficulty[32];
	Format(difficulty, 31, "Difficulty now is: %d", GetConVarInt(sv_diff));
	SetPanelTitle(diffiMenu, "Please select a difficulty");
	DrawPanelText(diffiMenu, difficulty);
	DrawPanelItem(diffiMenu, "10 up");
	DrawPanelItem(diffiMenu, "5 up");
	DrawPanelItem(diffiMenu, "1 up");
	DrawPanelItem(diffiMenu, "10 down");
	DrawPanelItem(diffiMenu, "5 down");
	DrawPanelItem(diffiMenu, "1 down");
	DrawPanelItem(diffiMenu, "Done");
	SendPanelToClient(diffiMenu, client, diffiMenuHandler, 20);
	CloseHandle(diffiMenu); 
	return Plugin_Continue;
} 	
	
	
public timerMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{	
	if (action == MenuAction_Select)
	{ 
		switch(param2)
		{
			case 1:
			{
				new Float:origin[3];
				origin[0] = Float:(GetConVarFloat(x_start) - 40);
				origin[1] = Float:GetConVarFloat(y_start);
				origin[2] = Float:(GetConVarFloat(z_start) + 20);
				TeleportEntity(param1, origin, NULL_VECTOR, NULL_VECTOR);
			}
		}
		PrintToChat(param1, "Your timer has stopped. Touch the timer again to do another try.");
		hasTimer[param1] = false;
	
		PrintToConsole(param1, "You selected item: %d", param2);
		PrintToServer("Client %d selected item: %d from timerPanel", param1, param2);
	} 
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
}


// Menu when someone stops timer
public Action:Command_showTimerMenu(client, args) 
{ 
	if(hasTimer[client])
	{
		new Handle:timerMenu = CreatePanel();
		SetPanelTitle(timerMenu, "Timer stopped! Teleport to start?");
		DrawPanelItem(timerMenu, "Yes");
		DrawPanelItem(timerMenu, "No");
	 
		SendPanelToClient(timerMenu, client, timerMenuHandler, 20);
	 
		CloseHandle(timerMenu);
		dontspam[client] = true;
		canshow(client);
	}
	else 
	{
		PrintToChat(client,"You cant use sr_stoptimer if you havent started timer silly ;)");
	}
	return Plugin_Handled;
}

// Show on screen timer
public Action:showtimer(Handle:timer, any:client)
{
	if(hasTimer[client] == false || !IsClientConnected(client)) return Plugin_Handled;
	if(!IsPlayerAlive(client))
	{
		hasTimer[client] = false;
		return Plugin_Handled;
	}
	new now; 
	now = int:(RoundFloat(GetGameTime()) - startTime[client]);
	new hour = (now / 3600) % 24;
	new minute = (now / 60) % 60;
	new second = now % 60;
	ShowHudText(client, 0,"Your time: %d:%d:%d",hour,minute,second);
	return Plugin_Continue;
}


//thx to p3tsin for showing how to make long MOTD's
ShowLongMOTD(client,const String:title[],const String:panel[]) 
{
    new Handle:kv = CreateKeyValues("data");

    KvSetString(kv,"title",title);
    KvSetString(kv,"type","1");
    KvSetString(kv,"msg",panel);
    ShowVGUIPanel(client,"info",kv);
    CloseHandle(kv);
}

bool:SetLongMOTD(const String:panel[],const String:text[]) 
{
    new table = FindStringTable("InfoPanel");

    if(table != INVALID_STRING_TABLE) 
	{
        new len = strlen(text);
        new str = FindStringIndex(table,panel);
        new bool:locked = LockStringTables(false);

        if(str == INVALID_STRING_INDEX || str == 65535) //for some reason it keeps returning 65535
		{   
            AddToStringTable(table,panel,text,len);
        }
        else
		{
            SetStringTableData(table,str,text,len);
        }

        LockStringTables(locked);
        return true;
    }

    return false;
}

// old map config deleted when admin is adding map config
deletefile()
{
	
	new String:mapname[32];
	GetCurrentMap(mapname,31);
	new String:rpath[PLATFORM_MAX_PATH];
	Format(rpath,PLATFORM_MAX_PATH,"cfg/mapscfg/%s.cfg",mapname);
	if (FileExists(rpath))
	{
		DeleteFile(rpath);
	}
	PrintToServer("deleted %s.cfg", mapname);
	setfile();
}

// New map config is written when admin is adding map config
setfile()
{
	new String:mapname[32];
	GetCurrentMap(mapname,31);
	PrintToServer("creating %s.cfg", mapname);
	new String:rpath[PLATFORM_MAX_PATH];
	Format(rpath,PLATFORM_MAX_PATH,"cfg/mapscfg/%s.cfg",mapname);
	new Handle:fileHandle2=OpenFile(rpath,"w");
	CloseHandle(fileHandle2); 
	
	new String:mapfilestart[76];
	new String:x_cstart[32];
	new String:y_cstart[32];
	new String:z_cstart[32];
	new String:x_cgoal[32];
	new String:y_cgoal[32];
	new String:z_cgoal[32];
	//new String:sv_cgoalteams[32];
	new String:sv_cdifficulty[32];
	new String:mapfileend[76];
	//GetConVarString(sv_gteam,sv_cgoalteams,31);
	Format(mapfilestart , 75, "//START OF SKILLSRANK MAPFILE OF MAP %s", mapname);
	Format(x_cstart,31,"sr_xstart %f",GetConVarFloat(x_start));
	Format(y_cstart,31,"sr_ystart %f",GetConVarFloat(y_start));
	Format(z_cstart,31,"sr_zstart %f",GetConVarFloat(z_start));
	Format(x_cgoal,31,"sr_xgoal %f",GetConVarFloat(x_goal));
	Format(y_cgoal,31,"sr_ygoal %f",GetConVarFloat(y_goal));
	Format(z_cgoal,31,"sr_zgoal %f",GetConVarFloat(z_goal));
	//Format(sv_cgoalteams,31,"sv_goalteams %s",sv_cgoalteams);
	Format(sv_cdifficulty,31,"sr_difficulty %d",GetConVarInt(sv_diff));
	Format(mapfileend,75,"// END OF SKILLSRANK MAPFILE OF MAP %s",mapname);
	new String:rpath2[PLATFORM_MAX_PATH];
	Format(rpath2,PLATFORM_MAX_PATH,"cfg/mapscfg/%s.cfg",mapname);
	new Handle:fileHandle=OpenFile(rpath2,"a"); // Opens addons/sourcemod/blank.txt to append text to it
	WriteFileLine(fileHandle,mapfilestart);
	WriteFileLine(fileHandle,x_cstart);
	WriteFileLine(fileHandle,y_cstart);
	WriteFileLine(fileHandle,z_cstart);
	WriteFileLine(fileHandle,x_cgoal);
	WriteFileLine(fileHandle,y_cgoal);
	WriteFileLine(fileHandle,z_cgoal);
	//WriteFileLine(fileHandle,sv_cgoalteams);
	WriteFileLine(fileHandle,sv_cdifficulty);
	WriteFileLine(fileHandle,mapfileend);
	
	CloseHandle(fileHandle);
	deletemodels();
	CreateTimer(1.0, spawnModelTimer, 0);

	
}

// Old start and end entities deleted when admin has added new map config
deletemodels()
{
	if(models[0] != -10){ RemoveEdict(models[0]); }
	if(models[1] != -10){ RemoveEdict(models[1]); }
	models[0] = -10;
	models[1] = -10;
}

// Allow user to touch end 
canshow(client) {
	dontspam[client] = false;
}
