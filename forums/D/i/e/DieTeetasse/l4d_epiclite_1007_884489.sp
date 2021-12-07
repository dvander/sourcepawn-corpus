#include <geoip>
#include <sourcemod>
#include <sdktools> 
 
//#############################################
//Global definitions                          #
//#############################################

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define DEBUG_FILE "./addons/sourcemod/logs/epicmodlite_debug.txt"
#define MAX_PLAYERS 1024
#define MAX_LINE_WIDTH 64
#define PLUGIN_TAG "Epic Lite"
#define PLUGIN_VERSION "1.0.0.7"
 
public Plugin:myinfo =
{
	name = "Epicmod Lite",
	author = "Die Teetasse",
	description = "Epicmod lite. Adding statistics, targetsystem and anti cornercamping.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=98757"
};

/* 

FUNCTIONS:
###############################
- Round statistics like killed zombies etc pp
- Personal statistics for infected (dmg and stats [TODO!] in life and dmg in round) and survivors (kills in round)
- Anti corner camping with slap function
- Markersystem to mark as an infected survivors for better coordination (GetClientAimTarget ist really accurate and it is a little complicated to hit somebody in action xD)
- Messages for connection, disconnection and friendly fire

BUGS:
###############################
- i hope not so many :D
- infected player that become a ghost again by pressings e will loose his stats

TODO:
###############################
- Infected Stats
- Boomer damage through common infected

CHANGELOG:
###############################
1.0.0.1 
- Initial Release

1.0.0.2
- Fixed bug, no stats after team change to survivors

1.0.0.3
- Fixed really the bug
- Debug output in file and command epiclite_dump_stats are now optional through global debug variable

1.0.0.4
- List changes via say !epiclite
- Change of welcome message
- Creation of config file
- Stop of recording stats after end round to avoid failure messages
- Infected bots stats record stopped

1.0.0.5
- Fixed bug, that bots stats deletion is not abort
- Fixed bug, where an infected killed an infected leads to an out of bound array failure
- Moved the debug file to the sourcemod logs 
- Debug file default off

1.0.0.6
- Adding Cvar flag FCVAR_DONTRECORD

1.0.0.7
- Adding Cvar flag FCVAR_DONTRECORD only to version cvar
- Adding name for configfile with versionnumber
- Removing Cvar Flag FCVAR_SPONLY
- Print the list of changes in the chat
*/

//#############################################
//Global variables                            #
//#############################################

//+++++ Debugmode +++++
new bool:epiclite_debug = false

//+++++ General statistics +++++
new cinf
new cboomer
new chunter
new csmoker
new ctank
new cwitch
new cwitchdeath
new cmelee
new cmed[3]
new cpills[3]
new cpipe[3]
new cmolow[3]
new cdamage
new cinfdamage
new cincap
new cff
new cslaps
new bool:bmedkit
new bool:bsend

//+++++ Corner Camping (standard values if they are not loaded before (dont know why this should happen, but better is) +++++
new cvarccslap = 10
new bool:bccfirst = false
new bool:bccfound = false
new bool:bccstart = false
new bool:bccstop = false
new Float:cvarccinterval = 5.0
new Float:cvarccradius = 40.0 
new Handle:CvarCC
new Handle:CvarCCInterval
new Handle:CvarCCRadius
new Handle:CvarCCSlap

//+++++ Personal Statistics +++++
/* Damage to
0 = Zoey
1 = Louis
2 = Bill
3 = Fracis */
new infecteddmg[4][4]
new infectedrounddmg[4][4] 
/* Stats
Boomer:
- Puked
- Scratched
- Pushed
- Incap
- Kills
Hunter:
- Lunged
- Scratched
- Pushed
- Incap
- Kills
Smoker:
- Grabbed
- Scratched
- Incap
- Kills
Tank:
- Punched
- Rock hit
- Incap
- Kills
*/
new infectedstats[4][5]
/* Survivor Kills
0 = Common
1 = Boomer
2 = Hunter
3 = Smoker
4 = Tank
5 = Witch */
new survivorstats[4][6]
new bool:broundend
new bool:binfected[4]
new bool:bsurvivor[4]
new String:Infected[4][30]
new String:Survivor[4][30]

//+++++ Marksystem +++++
new Handle:CvarMarkInterval
new Handle:Marked[4]
new String:Marker[4][MAX_NAME_LENGTH]
new String:Modelnames[4][10]

//+++++ Other +++++
new usercount
new Handle:WelcomeTimers[MAX_PLAYERS+1]
new String:WasThere[MAX_PLAYERS+1][30]

//#############################################
//Pluginstart -> HookEvent, Cmds              #
//#############################################

public OnPluginStart()
{
	//+++++ Cvars +++++
	//Versionnumber
	CreateConVar("epiclite_version", PLUGIN_VERSION, "Epiclite version", CVAR_FLAGS|FCVAR_DONTRECORD)
	
	//Corner Camping
	CvarCC = CreateConVar("epiclite_corner_camping", "1", "Checks for Cornercamping and will slap players if continues camping", CVAR_FLAGS)
	CvarCCInterval = CreateConVar("epiclite_corner_camping_check_interval", "5.0", "Cornercamping check interval", CVAR_FLAGS, true, 2.0, true, 30.0)
	CvarCCRadius = CreateConVar("epiclite_corner_camping_radius", "40.0", "Cornercamping check radius from group middle point to players", CVAR_FLAGS, true, 1.0, true, 100.0)
	CvarCCSlap = CreateConVar("epiclite_corner_camping_slap", "10", "Hp loss if cornercamping is detected", CVAR_FLAGS, true, 1.0, true, 50.0)
	CvarMarkInterval = CreateConVar("epiclite_target_interval", "15", "Display interval of marked survivors", CVAR_FLAGS, true, 1.0, true, 30.0)
		
	new String:filename[30]
	Format(filename, 30, "epiclite_config_%s", PLUGIN_VERSION)		
	AutoExecConfig(true, filename)
		
	//+++++ Commands +++++
	RegConsoleCmd("epiclite_list_changes", Command_Description, "Lists all changes of epiclite.")
	RegServerCmd("epiclite_check_corner_camping", Command_CornerCamping, "Force to check if there is cornercamping")
	if (epiclite_debug) RegServerCmd("epiclite_dump_stats", Command_DumpStats, "Dump the stats arrays for survivor and infected")
	
	RegConsoleCmd("say", Command_Say)
	
	//+++++ Hooks +++++
	HookEvent("player_death", Event_player_death)
	HookEvent("witch_spawn", Event_witch_spawn)
	HookEvent("spawner_give_item", Event_spawner_give_item)
	HookEvent("weapon_fire", Event_weapon_fire)
	HookEvent("heal_success", Event_heal_success)
	HookEvent("pills_used", Event_pills_used)
	HookEvent("player_hurt", Event_player_hurt) 
	HookEvent("player_incapacitated", Event_player_incapacitated) 
	HookEvent("friendly_fire", Event_friendly_fire) 
	HookEvent("melee_kill", Event_melee_kill)
	
	HookEvent("player_spawn", Event_spawn)
	HookEvent("player_team", Event_player_team)
	
	HookEvent("round_start", Event_round_start)
	HookEvent("round_end", Event_round_end, EventHookMode_Pre) 
	HookEvent("player_left_start_area", Event_player_left_start_area)
	
	//Targetsystem modelnames
	Modelnames[0] = "Zoey"
	Modelnames[1] = "Louis"
	Modelnames[2] = "Bill"
	Modelnames[3] = "Francis"
	
	usercount = 0
}

//#############################################
//Gameframefunction                           #
//#############################################

public OnGameFrame()
{
    for (new i = 1; i <= MaxClients; i++)
    {
		//Existing?
		if (!IsValidEntity(i)) 
		{
			continue;
		}			

		//Ingame?
		if (!IsClientInGame(i))
		{
			continue;
		}		
		
		//Infected (Markersystem)
		if (GetClientTeam(i) == 3)
		{
			//Alive?
			if (!IsPlayerAlive(i))
			{
				continue;
			}	
			
			//Button? (IN_ZOOM = Middle Mouse Button)
			if (GetClientButtons(i) & IN_ZOOM)
			{
				//Markersystem
				Target_Survivor(i)
				continue;
			}
		}  
	}
}

//#############################################
//Command description                         #
//#############################################

public Action:Command_Say(client, args)
{
	if (args < 1)
	{
		return
	}

	decl String:text[15]
	GetCmdArg(1, text, sizeof(text))
	
	if (StrContains(text, "!epiclite") != -1)
	{
		Description(client)
	}
}

public Action:Command_Description(client, args)
{
	Description(client)
}

Description(client)
{
	PrintToChat(client, "Epiclite adds:")
	PrintToChat(client, "- Round statistics like killed zombies")
	PrintToChat(client, "- Personal statistics for infected (dmg in life and dmg in round) and survivors (kills in round)")
	PrintToChat(client, "- Anti corner camping with slap function")
	PrintToChat(client, "- Markersystem to mark as an infected survivors for better coordination")
	PrintToChat(client, "- Messages for connection, disconnection and friendly fire")
	PrintToChat(client, "Version: %s", PLUGIN_VERSION)
}

//#############################################
//Maptstart                                 #
//#############################################

public OnMapStart()
{
	if (epiclite_debug) LogToFile(DEBUG_FILE, "###### Mapstart ######")

	//Personal statistics initialize
	for (new i = 0; i < 4; i++)
	{
		binfected[i] = false
		bsurvivor[i] = false
		
		Infected[i] = ""
		Survivor[i] = ""
	}
}

//#############################################
//Roundtstart                                 #
//#############################################

public Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (epiclite_debug) LogToFile(DEBUG_FILE, "###### Roundstart ######")

	//Reset all statistics variables
	cinf = 0
	cboomer = 0
	chunter = 0
	csmoker = 0
	ctank = 0
	cwitch = 0
	cwitchdeath = 0
	cmelee = 0
	cmed[0] = 0
	cmed[1] = 0
	cmed[2] = 0
	cpills[0] = 0
	cpills[1] = 0
	cpills[2] = 0
	cpipe[0] = 0
	cpipe[1] = 0
	cpipe[2] = 0
	cmolow[0] = 0
	cmolow[1] = 0
	cmolow[2] = 0
	cdamage = 0
	cinfdamage = 0
	cincap = 0
	cff = 0
	cslaps = 0
	
	//Reset bool variables
	bccfirst = false
	bccfound = false
	bccstart = false
	bccstop = false
	bmedkit = false
	broundend = false
	bsend = false
		
	//Targetsystem initialize
	for (new i = 0; i < 4; i++)
	{
		Marked[i] = INVALID_HANDLE
		Marker[i] = ""
	}
	
	//Count items in 15 seconds (sometimes they are not spawned at this time)
	CreateTimer(15.0, Medkitcount)
}

//#############################################
//Personal statistics                         #
//#############################################

public Event_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new id = GetEventInt(event, "userid")
	new cid = GetClientOfUserId(id)

	if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Spawn...", cid)
	
	//Find space for stats
	CreateStats(cid)
}

public Event_player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
	new id = GetEventInt(event, "userid")
	new cid = GetClientOfUserId(id)
	new oldteam = GetEventInt(event, "oldteam")
	new newteam = GetEventInt(event, "team")
	
	if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Teamchange from %d to %d...", cid, oldteam, newteam)
	
	//If clientid == 0 than there is no need for action
	if (cid == 0)
	{
		return
	}
	
	//Clear infected stats
	if (oldteam == 3)
	{
		ClearStatsInfected(cid)
	}
		
	//Clear survivor stats
	if (oldteam == 2)
	{
		ClearStatsSurvivor(cid)
	}		
	
	//Find new space for stats if you are a survivor, infected get stats when they spawn
	if (newteam == 2) 
	{
		CreateStats(cid, true, newteam)
	}
}

CreateStats(cid, bool:teamchange = false, newteam = -1)
{
	new auswahl = -1
	new i
	new team = GetClientTeam(cid)
	new bool:vorhanden = false
	new String:authstr[30]

	//Bot?
	if (IsFakeClient(cid))
	{
		if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Bot!", cid)
		return
	}
	
	if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Teamnumber by GetClientTeam %d", cid, team)
	if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Teamnumber by parameter %d", cid, newteam)
	
	//Infected
	if (team == 3 && !teamchange)
	{
		//Read auth
		GetClientAuthString(cid, authstr, sizeof(authstr))
	
		//Got already space?
		for (i = 0; i < 4; i++)
		{
			if (StrContains(Infected[i], authstr) != -1)
			{
				auswahl = i
				vorhanden = true
				break
			}
		}
		
		//if so, then reset stats and dmg
		if (vorhanden)
		{
			for (i = 0; i < 5; i++)
			{
				if (i < 4) infecteddmg[auswahl][i] = 0
				infectedstats[auswahl][i] = 0
			}
						
			if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Inf found in %d", cid, auswahl)
						
			//get out
			return
		}
	
		auswahl = -1
		if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Finding new space for Inf...", cid)
	
		//no space, find new one
		for (i = 0; i < 4; i++)
		{
			if (!binfected[i])
			{
				auswahl = i
				break;
			}	
		}
	
		//something wrong... maybe more than 4 player? => get out
		if (auswahl == -1)
		{
			if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: No space for Inf found...", cid)
			return
		}
	
		if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Space %d found...", cid, auswahl)
	
		//reserve space
		binfected[auswahl] = true
		
		//write auth in array
		Infected[auswahl] = authstr
		
		//reset stats
		for (i = 0; i < 5; i++)
		{
			if (i < 4) {
				infecteddmg[auswahl][i] = 0
				infectedrounddmg[auswahl][i] = 0
			}
			
			infectedstats[auswahl][i] = 0
		}		
		
		//get out
		return
	}
	
	//Survivor
	if ((team == 2 && !teamchange) || (teamchange && newteam == 2))
	{
		///read auth
		GetClientAuthString(cid, authstr, sizeof(authstr))
	
		//Got already space?
		for (i = 0; i < 4; i++)
		{
			if (StrContains(Survivor[i], authstr) != -1)
			{
				auswahl = i
				vorhanden = true
				break
			}
		}
		
		//if so, do nothing (maybe coop respawn)
		if (vorhanden)
		{
			if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Survivor found in %d", cid, auswahl)
						
			//get out
			return
		}
	
		auswahl = -1
		if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Finding new space for survivor...", cid)
	
		//find new space
		for (i = 0; i < 4; i++)
		{
			if (!bsurvivor[i])
			{
				auswahl = i
				break;
			}	
		}
	
		//something wrong again?
		if (auswahl == -1)
		{
			if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: No space for survivor...", cid)
			return
		}
	
		if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Space %d found...", cid, auswahl)
	
		//reserve space
		bsurvivor[auswahl] = true
		
		//save auth in array
		Survivor[auswahl] = authstr
		
		//reset stats
		for (i = 0; i < 6; i++)
		{
			survivorstats[auswahl][i] = 0
		}		
		
		//get out
		return
	}	
}

ClearStatsSurvivor(client)
{
	//Bot?
	if (IsFakeClient(client))
	{
		return
	}

	new String:authstr[30]
	GetClientAuthString(client, authstr, sizeof(authstr))
	
	//search client
	for (new i = 0; i < 4; i++)
	{
		if (StrContains(Survivor[i], authstr) != -1)
		{
			//delete him from array (stats will be resettet on spawn of new one)
			if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Delete survivor stats in array %d...", client, i)
			bsurvivor[i] = false
			Survivor[i] = ""
			break
		}
	}
}

ClearStatsInfected(client)
{
	//Bot?
	if (IsFakeClient(client))
	{
		return
	}

	new String:authstr[30]
	GetClientAuthString(client, authstr, sizeof(authstr))
	
	//search him
	for (new i = 0; i < 4; i++)
	{
		if (StrContains(Infected[i], authstr) != -1)
		{
			//delete his stats
			if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Delete infected stats in array %d...", client, i)
			binfected[i] = false
			Infected[i] = ""
			break
		}
	}
}

public Action:Command_DumpStats(args)
{
	new i
	
	if (!epiclite_debug)
	{
		return
	}
	
	LogToFile(DEBUG_FILE, "################")
	LogToFile(DEBUG_FILE, "Stats-Arrays:")
	
	//Dump infected stats
	LogToFile(DEBUG_FILE, "Infected:")
	for (i = 0; i < 4; i++)
	{
		LogToFile(DEBUG_FILE, "%s - %s:", (binfected[i]) ? "true" : "false", Infected[i])
		LogToFile(DEBUG_FILE, "Dmg: %d %d %d %d", infecteddmg[i][0], infecteddmg[i][1], infecteddmg[i][2], infecteddmg[i][3])
		LogToFile(DEBUG_FILE, "Round Dmg: %d %d %d %d", infectedrounddmg[i][0], infectedrounddmg[i][1], infectedrounddmg[i][2], infectedrounddmg[i][3])
		LogToFile(DEBUG_FILE, "Stats: %d %d %d %d %d", infectedstats[i][0], infectedstats[i][1], infectedstats[i][2], infectedstats[i][3], infectedstats[i][4])
	}
	
	//and survivor stats
	LogToFile(DEBUG_FILE, "Survivor Stats:")
	for (i = 0; i < 4; i++)
	{
		LogToFile(DEBUG_FILE, "%s - %s:", (bsurvivor[i]) ? "true" : "false", Survivor[i])
		LogToFile(DEBUG_FILE, "Stats: %d %d %d %d %d %d", survivorstats[i][0], survivorstats[i][1], survivorstats[i][2], survivorstats[i][3], survivorstats[i][4], survivorstats[i][5])
	}
	
	LogToFile(DEBUG_FILE, "################")
}

public Event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new dmg = GetEventInt(event, "dmg_health")
	new id = GetEventInt(event, "userid")
	new cid = GetClientOfUserId(id)
	
	//2 = Survivor	
	if (GetClientTeam(cid) == 2)
	{
		//dmg to round statistic
		cdamage += dmg
		
		//roundend?
		if (broundend)
		{
			return
		}
		
		//dmg to infected player
		new inf_id = GetEventInt(event, "attacker")
		
		//common or world == 0
		if (inf_id != 0)
		{
			new inf_cid = GetClientOfUserId(inf_id)
			//Infected?
			if (GetClientTeam(inf_cid) == 3)
			{
				//Bot?
				if (!IsFakeClient(inf_cid))
				{
					//get the survivormodel of the victim for arrayindex
					new String:model[200]
					new modelnr
		
					GetClientModel(cid, model, sizeof(model))
					if(StrContains(model, "teenangst", false) != -1)
					{
						modelnr	= 0
					}		
					else if(StrContains(model, "manager", false) != -1)
					{
						modelnr	= 1
					}	
					else if(StrContains(model, "namvet", false) != -1)
					{
						modelnr	= 2
					}		
					else if(StrContains(model, "biker", false) != -1)
					{
						modelnr	= 3
					}	
			
					//get auth
					new String:inf_auth[30]
					GetClientAuthString(inf_cid, inf_auth, sizeof(inf_auth))
						
					//find auth in array
					for (new i = 0; i < 4; i++)
					{
						//comapre
						if (StrContains(Infected[i], inf_auth) != -1)
						{
							//add dmg to infected stats
							infecteddmg[i][modelnr] += dmg
							infectedrounddmg[i][modelnr] += dmg
							if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Infected in array %d adding %d Dmg...", inf_cid, i, dmg)
							break
						}
					}
				}
			}
		}
	}
	
	//Infected
	if (GetClientTeam(cid) == 3)
	{
		//Dmg to round stats
		cinfdamage += dmg
	}
}

public Event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attackerid = GetEventInt(event, "attacker")
	new attackercid
	new survivor_arrayid = -1
	new i
	
	//roundend? (y => attackerid = 0, so no stats)
	if (broundend)
	{
		attackerid = 0
	}
	
	//Attacker is world or common?
	if (attackerid == 0)
	{
		//if attackercid == -1 => no kill will saved
		attackercid = -1
	}
	else
	{
		attackercid = GetClientOfUserId(attackerid)
		
		//Survivor?
		if (GetClientTeam(attackercid) == 2)
		{
			//Bot?
			if (!IsFakeClient(attackercid))
			{
				//read auth
				new String:survivor_auth[30]
				GetClientAuthString(attackercid, survivor_auth, sizeof(survivor_auth))
			
				//search auth
				for (i = 0; i < 4; i++)
				{
					//compare like always
					if (StrContains(Survivor[i], survivor_auth) != -1)
					{
						survivor_arrayid = i
						break
					}	
				}
			
				//something wrong?
				if (survivor_arrayid == -1)
				{
					if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Survivor not found...", attackercid)
					attackercid = -1
				}	
				else
				{
					if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Survivor found in %d...", attackercid, survivor_arrayid)
				}
			}
			else
			{
				attackercid = -1
			}
		}
	}
	
	/* Survivor Kills
	0 = Common
	1 = Boomer
	2 = Hunter
	3 = Smoker
	4 = Tank
	5 = Witch */
	
	new String:vic[9]
	GetEventString(event, "victimname", vic, 9)
	
	//Common?
	if (StrContains(vic, "Infected") != -1)
	{
		cinf++
		if (attackercid != -1 && survivor_arrayid != -1)
		{
			//Save kill
			survivorstats[survivor_arrayid][0]++
		}
	}
	//Hunter?
	else if (StrContains(vic, "Hunter") != -1)
	{
		chunter++
		if (attackercid != -1 && survivor_arrayid != -1)
		{
			survivorstats[survivor_arrayid][2]++
		}
	}
	//Boomer?
	else if (StrContains(vic, "Boomer") != -1)
	{
		cboomer++
		if (attackercid != -1 && survivor_arrayid != -1)
		{
			survivorstats[survivor_arrayid][1]++
		}
	}
	//Smoker?
	else if (StrContains(vic, "Smoker") != -1)
	{
		csmoker++
		if (attackercid != -1 && survivor_arrayid != -1)
		{
			survivorstats[survivor_arrayid][3]++
		}
	}
	//Tank?
	else if (StrContains(vic, "Tank") != -1)
	{
		ctank++
		if (attackercid != -1 && survivor_arrayid != -1)
		{
			survivorstats[survivor_arrayid][4]++
		}
	}
	//Witch?
	else if (StrContains(vic, "Witch") != -1)
	{
		cwitchdeath++
		if (attackercid != -1 && survivor_arrayid != -1)
		{
			survivorstats[survivor_arrayid][5]++
		}
	}
		
	//if victim was infected show his stats
	new id = GetEventInt(event, "userid")
		
	//Common? World?
	if (id == 0)
	{
		return
	}
	
	new cid = GetClientOfUserId(id)
	
	//Infected?
	if (GetClientTeam(cid) == 3)
	{
		new arrayid = -1
		
		//auth
		new String:inf_auth[30]
		GetClientAuthString(cid, inf_auth, sizeof(inf_auth))
			
		//search auth
		for (i = 0; i < 4; i++)
		{
			if (StrContains(Infected[i], inf_auth) != -1)
			{
				arrayid = i
				break
			}
		}
		
		if (arrayid == -1)
		{
			if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Infected not found...", cid)
			return
		}
		
		if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Infected found in %d...", cid, arrayid)
		
		//create panel
		new Handle:InfPanel = CreatePanel();
	
		//draw text
		SetPanelTitle(InfPanel, "Infected Stats:")
		DrawPanelText(InfPanel, "----------------------------")
		
		/* 0 = Zoey
		1 = Louis
		2 = Bill
		3 = Fracis */
		
		new String:text[50]
		
		for (i = 0; i < 4; i++)
		{
			Format(text, sizeof(text), "Damage to %s: %3.d", Modelnames[i], infecteddmg[arrayid][i])
			DrawPanelText(InfPanel, text)
		}
		
		//send panel
		SendPanelToClient(InfPanel, cid, PanelHandlerInf, 10)
		
		CloseHandle(InfPanel)
	}
}

public PanelHandlerInf(Handle:menu, MenuAction:action, param1, param2)
{
	//nothing to do
}

//#############################################
//Statistic                                   #
//#############################################

public Action:Medkitcount(Handle:timer)
{
	//Medcount already done?
	if (bmedkit) return
		
	new String:Classname[30]	
	new entcount = GetEntityCount()
	
	for (new i = 1; i < entcount; i++)
	{
		//Valid entity?
		if (!IsValidEntity(i))
		{
			continue;
		}
		
		GetEdictClassname(i, Classname, 30);
		
		//Count items
		if (StrContains(Classname, "weapon_molotov") != -1)
		{
			cmolow[0]++
		}
		else if (StrContains(Classname, "weapon_pipe_bomb") != -1)
		{
			cpipe[0]++
		}	
		else if (StrContains(Classname, "weapon_pain_pills") != -1)
		{	
			cpills[0]++
		}
		else if (StrContains(Classname, "weapon_first_aid_kit") != -1)
		{
			cmed[0]++
		}		
	}
	
	//Count items done!
	bmedkit = true
}

public Event_witch_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	cwitch++
}

public Event_melee_kill(Handle:event, const String:name[], bool:dontBroadcast)
{
	cmelee++
}

public Event_spawner_give_item(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:item[30]
	GetEventString(event, "item", item, 30)
	
	//increase round item took stats
	if (StrContains(item, "weapon_molotov") != -1)
	{
		cmolow[1]++
	}
	else if (StrContains(item, "weapon_pipe_bomb") != -1)
	{
		cpipe[1]++
	}
	else if (StrContains(item, "weapon_pain_pills") != -1)
	{
		cpills[1]++
	}
	else if (StrContains(item, "weapon_first_aid_kit") != -1)
	{
		cmed[1]++
	}
}

public Event_weapon_fire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:weapon[10]
	GetEventString(event, "weapon", weapon, 10)
	
	//increase round item used stats
	if (StrContains(weapon, "molotov") != -1)
	{
		cmolow[2]++
	}
	else if (StrContains(weapon, "pipe_bomb") != -1)
	{
		cpipe[2]++
	}
}

public Event_heal_success(Handle:event, const String:name[], bool:dontBroadcast)
{
	//increase round item used stats
	cmed[2]++
}

public Event_pills_used(Handle:event, const String:name[], bool:dontBroadcast)
{
	//increase round item used stats
	cpills[2]++
}

public Event_player_incapacitated(Handle:event, const String:name[], bool:dontBroadcast)
{
	//stats
	cincap++		
}

//#############################################
//Friendlyfire display                        #
//#############################################

public Event_friendly_fire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new auserid, vuserid, att, vic
	new String:attacker[MAX_NAME_LENGTH], String:victim[MAX_NAME_LENGTH]
	
	//get ids
	auserid = GetEventInt(event, "attacker")
	vuserid = GetEventInt(event, "victim")
	
	//get userids
	att = GetClientOfUserId(auserid)
	vic = GetClientOfUserId(vuserid)
	
	//get names
	GetClientName(att, attacker, sizeof(attacker)) 
	GetClientName(vic, victim, sizeof(victim)) 
	
	//send messages to voctim and attacker
	PrintToChat(att, "[%s] You attacked %s!", PLUGIN_TAG, victim)
	PrintToChat(vic, "[%s] You have been attacked by %s!", PLUGIN_TAG, attacker)
	
	cff++
}

//#############################################
//Targetsystem                                #
//#############################################

public Action:Target_Survivor(client)
{
	//Exist entity?
	if (!IsValidEntity(client)) 
	{
		return
	}	
	
	//Not world?
	if (client == 0)
	{
		return
	}
	
	//Check if client is infected and alive
	if (GetClientTeam(client) != 3 || !IsPlayerAlive(client)) 
	{
		return
	}
	
	//Looking on somebody?
	new targetid = GetClientAimTarget(client, true)
	
	//if not get out
	if (targetid == -1)
	{
		return
	}
	
	//Looking at a survivor?
	if (GetClientTeam(targetid) != 2) 
	{
		return
	}
	
	//Looking up Model of User (Easier to recognize in the panel than the playername)
	new String:model[200]
	new markedindex
	
	GetClientModel(targetid, model, sizeof(model))
	if(StrContains(model, "teenangst", false) != -1)
	{
		markedindex	= 0
	}
	else if(StrContains(model, "manager", false) != -1)
	{
		markedindex	= 1
	}
	else if(StrContains(model, "namvet", false) != -1)
	{
		markedindex	= 2
	}	
	else if(StrContains(model, "biker", false) != -1)
	{
		markedindex	= 3
	}	
	
	//Looking up name of marker
	new String:markername[MAX_NAME_LENGTH]
	GetClientName(client, markername, sizeof(markername))
	
	//Marker got already one?
	new alreadyone = -1
	
	for (new i = 0; i < 4; i++)
	{
		if (StrContains(markername, Marker[i], false) != -1 && Marked[i] != INVALID_HANDLE)
		{
			alreadyone = i
		}
	}
	
	//Deleting old marker
	if (alreadyone != -1)
	{
		//Kill Timer
		KillTimer(Marked[alreadyone])
		
		Marker[alreadyone] = ""
		Marked[alreadyone] = INVALID_HANDLE
	}	
	
	//Storing markername
	Marker[markedindex] = markername
		
	//Create timer
	Marked[markedindex] = CreateTimer(float(GetConVarInt(CvarMarkInterval)), Timer_KillMarker, markedindex)
		
	//Send panel
	MarkerPanel()
}

public Action:Timer_KillMarker(Handle:timer, any:index)
{
	//Killing marker
	Marker[index] = ""
	Marked[index] = INVALID_HANDLE
	
	//Send panel
	MarkerPanel()
}

public MarkerPanel()
{
	//Checking if there is a marker
	new bool:anybody = false
		
	for (new i = 0; i < 4; i++)
	{
		if (Marked[i] != INVALID_HANDLE)
		{
			anybody = true
			break
		}
	}
	
	if (!anybody)
	{
		return
	}
			
	//Creating panel
	new Handle:MarkPanel = CreatePanel();
	
	//Drawing text
	SetPanelTitle(MarkPanel, "Marked Survivors:")
	DrawPanelText(MarkPanel, "---------------------")
	
	new String:text[50]
	
	//Go through markers and draw
	for (new i = 0; i < 4; i++)
	{
		if (Marked[i] == INVALID_HANDLE)
		{
			continue
		}
		
		Format(text, sizeof(text), "%s (from %s)", Modelnames[i], Marker[i])
		DrawPanelText(MarkPanel, text)
	}
	
	//Searching infected and sending panel
	for (new i = 1; i <= MaxClients; i++) 
	{
		//Existing?
		if (!IsValidEntity(i)) 
		{
			continue;
		}			

		//Ingame?
		if (!IsClientInGame(i))
		{
			continue;
		}		
		
		//Infected?
		if (GetClientTeam(i) != 3)
		{
			continue
		}
		
		//Bot?
		if (IsFakeClient(i))
		{
			continue;
		}
		
		//Sending panel
		SendPanelToClient(MarkPanel, i, PanelHandlerMark, GetConVarInt(CvarMarkInterval))
	}
	
	CloseHandle(MarkPanel)
}	

public PanelHandlerMark(Handle:menu, MenuAction:action, param1, param2)
{
	//nothing in here
}

//#############################################
//CornerCamping                               #
//#############################################

public Event_player_left_start_area(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Is activated?
	if (bccstart)
	{
		return
	}
	
	CreateTimer(cvarccinterval, Timer_CornerCamping)
	bccstart = true
}	
	
public Action:Command_CornerCamping(args)
{
	CornerCamping()
}

public Action:Timer_CornerCamping(Handle:timer)
{
	CornerCamping()
}

CornerCamping()
{
	//Is activated and not after map end?
	if (!GetConVarBool(CvarCC) || bccstop) {
		return
	}
	
	//Get vars
	cvarccradius = GetConVarFloat(CvarCCRadius)
	cvarccinterval = GetConVarFloat(CvarCCInterval)
	cvarccslap = GetConVarInt(CvarCCSlap)
	
	//initialize variables
	new camper = 0, campers[4], clienthealth, count = 0, cvec = 0, i, ids[4], incap, relation[6][2], stats[4]
	new Float:vec[4][3], Float:diffvec[6], Float:diffzvec[6], Float:zvec[4]
	
	for (i = 0; i < 4; i++)
	{
		campers[i] = -1
		ids[i] = -1
	}
	
	//loop through clients
	for (i = 1; i <= MaxClients; i++) 
	{
		if (!IsValidEntity(i)) 
		{
			continue;
		}	
		
		//Bot?
		if (IsFakeClient(i))
		{
			continue;
		}
		
		//Alive and survivor?
		if (GetClientTeam(i) == 2 && IsPlayerAlive(i)) 
		{
			//Incap? (Incaps will not counted)
			incap = GetEntProp(i, Prop_Send, "m_isIncapacitated")
			if (incap == 1)
			{
				continue;
			}
			
			//Get position
			GetClientAbsOrigin(i, vec[cvec])
			//seperate the z-coordinate (height)
			zvec[cvec] = vec[cvec][2]
			vec[cvec][2] = 0.0

			ids[cvec] = i
			cvec++
		}
	}
	
	//survivors < 3 => reset found variables and do nothing
	if (cvec < 3) 
	{				
			bccfirst = false	
			bccfound = false
			CreateTimer(cvarccinterval, Timer_CornerCamping)
			return
	}
	
	//3 survivors => get distances between them
	if (cvec == 3)
	{
		//xy-distance (plane)
		diffvec[0] = GetVectorDistance(vec[0], vec[1])
		diffvec[1] = GetVectorDistance(vec[0], vec[2])
		diffvec[2] = GetVectorDistance(vec[1], vec[2])
		
		//z-distance (height)
		diffzvec[0] = FloatAbs(zvec[0]-zvec[1])
		diffzvec[1] = FloatAbs(zvec[0]-zvec[2])
		diffzvec[2] = FloatAbs(zvec[1]-zvec[2])
		
		//all 3 survivors have to stay together in plane and in height
		if (FloatCompare(diffvec[0], cvarccradius) < 1 && FloatCompare(diffvec[1], cvarccradius) < 1 && FloatCompare(diffvec[2], cvarccradius) < 1 && FloatCompare(diffzvec[0], 100.0) < 1 && FloatCompare(diffzvec[1], 100.0) < 1 && FloatCompare(diffzvec[2], 100.0) < 1)
		{
			camper = 3
			for (i = 0; i < cvec; i++) 
			{
				campers[i] = ids[i]
			}
		}
	}
	else
	{
		//xy-distances between everybody to anybody
		diffvec[0] = GetVectorDistance(vec[0], vec[1])
		diffvec[1] = GetVectorDistance(vec[0], vec[2])
		diffvec[2] = GetVectorDistance(vec[0], vec[3])
		diffvec[3] = GetVectorDistance(vec[1], vec[2])			
		diffvec[4] = GetVectorDistance(vec[1], vec[3])
		diffvec[5] = GetVectorDistance(vec[2], vec[3])
	
		//z-distances between everybody to anybody
		diffzvec[0] = FloatAbs(zvec[0]-zvec[1])
		diffzvec[1] = FloatAbs(zvec[0]-zvec[2])
		diffzvec[2] = FloatAbs(zvec[0]-zvec[3])		
		diffzvec[3] = FloatAbs(zvec[1]-zvec[2])
		diffzvec[4] = FloatAbs(zvec[1]-zvec[3])
		diffzvec[5] = FloatAbs(zvec[2]-zvec[3])
		
		//realtions of the distances
		relation[0] = {0, 1}
		relation[1] = {0, 2}
		relation[2] = {0, 3}
		relation[3] = {1, 2}
		relation[4] = {1, 3}
		relation[5] = {2, 3}
		
		//reset stats
		for (i = 0; i < 4; i++)
		{
			stats[i] = 0
		}
		
		//count distances nearer than the radius
		for (i = 0; i < 6; i++)
		{			
			if (FloatCompare(diffvec[i], cvarccradius) < 1 && FloatCompare(diffzvec[i], 100.0) < 1)
			{
				count++
			}
		}
		
		//count = 6 => everybody ist near to anybody => all campers
		if (count == 6)
		{
			camper = 4	
			for (i = 0; i < 4; i++) 
			{
				campers[i] = ids[i]
			}			
		}
		// 2 < count < 6 => have to look, who stands near to which other player(s)
		else if (count > 2)
		{
			for (i = 0; i < 6; i++)
			{
				if (FloatCompare(diffvec[i], cvarccradius) < 1 && FloatCompare(diffzvec[i], 100.0) < 1)
				{
					stats[relation[i][0]]++
					stats[relation[i][1]]++
				}
			}			
			
			for (i = 0; i < 4; i++)
			{
				if (stats[i] > 1)
				{
					campers[camper] = ids[i]
					camper++
				}
			}
		}
		// 3 > count => there can not be 3 campers!
	}	
	
	if (camper > 2) 
	{
		//3. check => SLAP! + warning for another slap in 5 seconds
		if (bccfound == true) {
			PrintToChatAll("[%s] Slapping Campers %d hp!", PLUGIN_TAG, cvarccslap)
			for (i = 0; i < camper; i++) 
			{
				//got the camper less health than the slap?
				clienthealth = GetClientHealth(campers[i])
				//if so, he is lucky
				if (clienthealth <= cvarccslap) {
					PrintToChat(campers[i], "[%s] Lucky bastard, got less health than the slap!", PLUGIN_TAG)
					
					continue
				}
				
				//else SLAP!
				PrintToChat(campers[i], "[%s] Slapped for Cornercamping!", PLUGIN_TAG)
				SetEntityHealth(campers[i], (clienthealth - cvarccslap))
					
				PrintHintText(campers[i], "[%s] Move or another slap in 5 seconds!", PLUGIN_TAG)
			}
			PrintToChatAll("[%s] Move or another slap in 5 seconds!", PLUGIN_TAG)
			
			//stats
			cslaps++
				
			//timer for antother check
			CreateTimer(5.0, Timer_CornerCamping)
			return 
		}
		//2. check => warning + check in 5 seconds
		else if (bccfirst == true) {
			PrintToChatAll("[%s] Cornercamping detected! Move or %.d hp slap in 5 seconds!", PLUGIN_TAG, cvarccslap)
			
			for (i = 0; i < camper; i++) 
			{
				PrintHintText(campers[i], "[%s] Cornercamping detected! Move or %.d hp slap in 5 seconds!", PLUGIN_TAG, cvarccslap)
			}
			
			//confirmed suspicion
			bccfound = true
			
			CreateTimer(5.0, Timer_CornerCamping)
			return 
		}
		//1. check => maybe there is something, check in 3 seconds again to confirm the suspicion
		else {
			bccfirst = true
				
			CreateTimer(3.0, Timer_CornerCamping)
			return 
		}
	}
	
	//no or less than 3 campers? reset bool variables and create normal timer
	bccfirst = false	
	bccfound = false
	CreateTimer(cvarccinterval, Timer_CornerCamping)
}

//#############################################
//Statsdisplay                                #
//#############################################

public Action:Event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Show stats
	Show_Stats()
	
	//Stopping corner camping
	bccstop = true
	
	//Stopping stats record
	broundend = true
		
	//Personal statistics reset
	if (epiclite_debug) LogToFile(DEBUG_FILE, "###### End Round (delete stats) ######")
	
	for (new i = 0; i < 4; i++)
	{
		binfected[i] = false
		bsurvivor[i] = false
		
		Infected[i] = ""
		Survivor[i] = ""
	}
		
	return Plugin_Continue
}

public Show_Stats()
{
	//Already showed?
	if (bsend == true)
	{
		return
	}
	
	decl String:text[1000]
	new Handle:StatsPanel
	
	//Loop through clients
	for (new i = 1; i <= MaxClients; i++)
	{
		//Ingame?
		if (!IsClientInGame(i))
		{
			continue;
		}

		//Bot?
		if (IsFakeClient(i))
		{
			continue;
		}
		
		//Create panel
		StatsPanel = CreatePanel();
		SetPanelTitle(StatsPanel, "Round Statistics:")
		DrawPanelText(StatsPanel, "---------------------")
		
		Format(text, sizeof(text), "Damage to Sp.Inf.: %d", cinfdamage)
		DrawPanelText(StatsPanel, text)
	
		Format(text, sizeof(text), "Damage to Survivor: %d", cdamage)
		DrawPanelText(StatsPanel, text)
		
		Format(text, sizeof(text), "Incaps: %d", cincap)
		DrawPanelText(StatsPanel, text)
		
		Format(text, sizeof(text), "Friendly Fire: %d", cff)
		DrawPanelText(StatsPanel, text)
	
		//if corner camping show slap stats
		if (GetConVarBool(CvarCC))
		{
			Format(text, sizeof(text), "Camping Slaps: %d", cslaps)
			DrawPanelText(StatsPanel, text)		
		}	
			
		Format(text, sizeof(text), "Melee Kills: %d", cmelee)
		DrawPanelText(StatsPanel, text)	
		
		DrawPanelText(StatsPanel, "-----")
		DrawPanelText(StatsPanel, "spawned / took / used")
		
		Format(text, sizeof(text), "Molotov: %d/%d/%d", cmolow[0], cmolow[1], cmolow[2])
		DrawPanelText(StatsPanel, text)
		
		Format(text, sizeof(text), "Pipebomp: %d/%d/%d", cpipe[0], cpipe[1], cpipe[2])
		DrawPanelText(StatsPanel, text)
		
		Format(text, sizeof(text), "Pills: %d/%d/%d", cpills[0], cpills[1], cpills[2])
		DrawPanelText(StatsPanel, text)
		
		Format(text, sizeof(text), "Medkit: %d/%d/%d", cmed[0], cmed[1], cmed[2])
		DrawPanelText(StatsPanel, text)	
		
		DrawPanelText(StatsPanel, "-----")
		
		//Survivor with personal stats
		if (GetClientTeam(i) == 2)
		{
			//find arraynumber
			new survivor_arrayid = -1
			new String:survivor_auth[30]
			GetClientAuthString(i, survivor_auth, sizeof(survivor_auth))
			
			//search auth
			for (new j = 0; j < 4; j++)
			{
				if (StrContains(Survivor[j], survivor_auth) != -1)
				{
					survivor_arrayid = j
					break
				}	
			}
		
			//not found? Oo => normal display
			if (survivor_arrayid == -1)
			{
				if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Survivor not found... normal display", i)
				
				Format(text, sizeof(text), "Common: %d", cinf)
				DrawPanelText(StatsPanel, text)
				
				Format(text, sizeof(text), "Boomer: %d", cboomer)
				DrawPanelText(StatsPanel, text)
				
				Format(text, sizeof(text), "Hunter: %d", chunter)
				DrawPanelText(StatsPanel, text)
				
				Format(text, sizeof(text), "Smoker: %d", csmoker)
				DrawPanelText(StatsPanel, text)
			
				Format(text, sizeof(text), "Tank: %d", ctank)
				DrawPanelText(StatsPanel, text)
				
				Format(text, sizeof(text), "Witch: %d (spawned: %d)", cwitchdeath, cwitch)
				DrawPanelText(StatsPanel, text)			
			}
			//show personal kill stats
			else
			{
				DrawPanelText(StatsPanel, "personal kills in []")
			
				Format(text, sizeof(text), "Common: %d [%d]", cinf, survivorstats[survivor_arrayid][0])
				DrawPanelText(StatsPanel, text)
				
				Format(text, sizeof(text), "Boomer: %d [%d]", cboomer, survivorstats[survivor_arrayid][1])
				DrawPanelText(StatsPanel, text)
				
				Format(text, sizeof(text), "Hunter: %d [%d]", chunter, survivorstats[survivor_arrayid][2])
				DrawPanelText(StatsPanel, text)
				
				Format(text, sizeof(text), "Smoker: %d [%d]", csmoker, survivorstats[survivor_arrayid][3])
				DrawPanelText(StatsPanel, text)
			
				Format(text, sizeof(text), "Tank: %d [%d]", ctank, survivorstats[survivor_arrayid][4])
				DrawPanelText(StatsPanel, text)
				
				Format(text, sizeof(text), "Witch: %d [%d] (spawned: %d)", cwitchdeath, survivorstats[survivor_arrayid][5], cwitch)
				DrawPanelText(StatsPanel, text)
			}
		}
		
		//Infected with personal round stats
		if (GetClientTeam(i) == 3)
		{
			//find arraynumber
			new infected_arrayid = -1
			new String:infected_auth[30]
			GetClientAuthString(i, infected_auth, sizeof(infected_auth))
			
			//search auth like always
			for (new j = 0; j < 4; j++)
			{
				if (StrContains(Infected[j], infected_auth) != -1)
				{
					infected_arrayid = j
					break
				}	
			}
		
			Format(text, sizeof(text), "Common: %d", cinf)
			DrawPanelText(StatsPanel, text)
			
			Format(text, sizeof(text), "Boomer: %d", cboomer)
			DrawPanelText(StatsPanel, text)
			
			Format(text, sizeof(text), "Hunter: %d", chunter)
			DrawPanelText(StatsPanel, text)
			
			Format(text, sizeof(text), "Smoker: %d", csmoker)
			DrawPanelText(StatsPanel, text)
		
			Format(text, sizeof(text), "Tank: %d", ctank)
			DrawPanelText(StatsPanel, text)
			
			Format(text, sizeof(text), "Witch: %d (spawned: %d)", cwitchdeath, cwitch)
			DrawPanelText(StatsPanel, text)		

			//not found? show no more
			if (infected_arrayid == -1)
			{
				if (epiclite_debug) LogToFile(DEBUG_FILE, "Player %d: Infected not found... normal display", i)		
			}
			//show dmg of the complete round
			else
			{
				DrawPanelText(StatsPanel, "-----")
				
				for (new j = 0; j < 4; j++)
				{
					Format(text, sizeof(text), "Damage to %s: %3.d", Modelnames[j], infectedrounddmg[infected_arrayid][j])
					DrawPanelText(StatsPanel, text)
				}
			}
		}
		
		//send panel
		SendPanelToClient(StatsPanel, i, PanelHandlerStats, 12)
	}

	//Send the panel
	bsend = true
	
	CloseHandle(StatsPanel)
}

public PanelHandlerStats(Handle:menu, MenuAction:action, param1, param2)
{
	//nothing
}

//#############################################
//Servermessage after connecting              #
//#############################################

public OnClientConnected(client)
{
	new String:name[MAX_NAME_LENGTH], String:country[45], String:ip[16], String:code[4]
	new bool:tmp
	
	//Get name and country
	GetClientName(client, name, sizeof(name)) 
	GetClientIP(client, ip, 16, true)
	tmp = GeoipCountry(ip, country, 45)
	GeoipCode3(ip, code)
	
	if (tmp)
	{
		PrintToChatAll("[%s] %s connected from %s", PLUGIN_TAG, name, country)
	}
	else 
	{
		PrintToChatAll("[%s] %s connected from an unknown country", PLUGIN_TAG, name)
	}
}

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client))
	{
		new String:auth[30]
		GetClientAuthString(client, auth, sizeof(auth))
	
		//if client already connected sometime => no welcome message
		for (new i = 0; i < usercount; i++) {
			if (StrContains(auth, WasThere[i]) != -1) {
				return
			}
		}
		
		//Create welcome message timer
		WelcomeTimers[client] = CreateTimer(5.0, WelcomePlayer, client)
	}
}
 
public OnClientDisconnect(client)
{
	//Kill welcome message timer
	if (WelcomeTimers[client] != INVALID_HANDLE)
	{
		KillTimer(WelcomeTimers[client])
		WelcomeTimers[client] = INVALID_HANDLE
	}
	
	//Bot?
	if (!IsFakeClient(client)) 
	{
		//Disconnect message
		new String:name[MAX_NAME_LENGTH]
		GetClientName(client, name, sizeof(name))
		PrintToChatAll("[%s] %s disconnected", PLUGIN_TAG, name)
		
		//No? Therefor he has to got stats!
		//Clear infected stats
		if (GetClientTeam(client) == 3)
		{
			ClearStatsInfected(client)
		}
		
		//Clear survivor stats
		if (GetClientTeam(client) == 2)
		{
			ClearStatsSurvivor(client)
		}		
	}
}
 
public Action:WelcomePlayer(Handle:timer, any:client)
{
	new String:name[MAX_NAME_LENGTH]
	//Get name
	GetClientName(client, name, sizeof(name))
	//Get auth for recoginition, that he already was on this server 
	GetClientAuthString(client, WasThere[usercount], 30)
	usercount++
	
	PrintToChat(client, "[%s] Welcome to this epiclite server, %s!", PLUGIN_TAG, name)
	PrintToChat(client, "[%s] Say !epiclite to see the changes!", PLUGIN_TAG)
	
	WelcomeTimers[client] = INVALID_HANDLE
}

/*
Credits:
	- Cellwick, mesaya, daoka, Nos/Ghostbuster
	- sourcemod.net
	- wiki.alliedmods.net
	- and many others for ideas
*/