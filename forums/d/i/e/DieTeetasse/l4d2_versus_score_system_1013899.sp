#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define PLUGIN_VERSION "1.7"
#define PLUGIN_TAG "[L4D1Score]"

#define DEBUG_ENABLE 1
#define DEBUG_LOGFILE "l4d1_score_debug.txt"

#define MAP_MULTIPLIER_SOURCE "../../cfg/sourcemod/l4d2_versus_score_system_map_multiplier.txt"
/*
Game: Left 4 Dead 2
Plugin: L4D1 Versus Score
Description: This plugin edits the survivor bonus and calculates it after the formula of Left 4 Dead 1. Medkits, pills and shots are important again!
Creator: Die Teetasse

###########

Cvars:
l4d2_l4d1vs_version "1.7" 							//Version number
l4d2_l4d1vs_enable "1" 								//Enabling/disabling score system
l4d2_l4d1vs_score_multiplier "2.0" 					//Multiplier for survival bonus score
l4d2_l4d1vs_defib_multiplier "0.5"					//Multiplier for the restored health of a defib unit (0 for disabling)
l4d2_l4d1vs_map_multiplier_enable "1" 				//Enable/disable map multiplier on score
l4d2_l4d1vs_checkpoint_health_remover_enable "1"	//Enable/disable removing of health items in the checkpoint room
l4d2_l4d1vs_welcome_msg_enable "1"					//Enable/disable welcome message while joining

###########

Todo:
- medkit position system for custom maps

###########

Known Bugs:
- Second team score will show the new bonus score and not the calculated one for the first team
- NO support for custom maps (will fix this later)

###########

History:
v1.7:
- added map multiplier configuration over data file (custom map +)
- fixed bug, where non health items were removed

v1.6:
- fixed bug, where plugin was not loaded on versusmode
- fixed themphealth calculation bug
- changed final recognition

v1.5:
- fixed bug, where on second half the health items were not removed

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

###########

Additional Info:
- distance score on 4 map campagne: 500, 600, 700, 800
- on 5 map campagne: 400 - 800

*/

//plugin info
//#######################
public Plugin:myinfo =
{
	name = "L4D1 Versus Score",
	author = "Die Teetasse",
	description = "L4D1 Versus Score in L4D2",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1013899"
};

//global variables
//#######################
new g_default_score;
new g_player_count;
//if there will be more than 16 survivors, you have to change it here ;)
new g_player_scores[16];
new g_team_score;

new bool:gb_enabled = false;
new bool:gb_med_try = false;
new bool:gb_score_output;

new Handle:cvar_defib;
new Handle:cvar_enable; 
new Handle:cvar_health_remover_enable;
new Handle:cvar_map_multiplier_enable;
new Handle:cvar_multiplier; 
new Handle:cvar_survival_bonus; 
new Handle:cvar_welcome_msg_enable;

new String:mapmultiplier_path[256];
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

	PrepareMapMultiplier();
	
	//convars
	//#######################
	//version
	CreateConVar("l4d2_l4d1vs_version", PLUGIN_VERSION, "L4D1 Versus Score - version", CVAR_FLAGS|FCVAR_DONTRECORD);
	
	//enable/disable
	cvar_enable = CreateConVar("l4d2_l4d1vs_enable", "1", "L4D1 Versus Score - enable/disable", CVAR_FLAGS);
	HookConVarChange(cvar_enable, Hook_Enable);

	//multiplier of team score
	cvar_multiplier = CreateConVar("l4d2_l4d1vs_score_multiplier", "2.0", "L4D1 Versus Score - team score multiplier", CVAR_FLAGS, true, 1.0, true, 5.0);
	
	//defibrillator hp multiplier (like medkits)
	cvar_defib = CreateConVar("l4d2_l4d1vs_defib_multiplier", "0.5", "L4D1 Versus Score - defib health multiplier (like medkits 0.8 -> 80% of hp will be recovered)", CVAR_FLAGS, true, 0.0, true, 0.8);

	//map multiplier enable/disable
	cvar_map_multiplier_enable = CreateConVar("l4d2_l4d1vs_map_multiplier_enable", "1", "L4D1 Versus Score - map multiplier enable/disable", CVAR_FLAGS);
	
	//checkpoint health items remover enable/disable
	cvar_health_remover_enable = CreateConVar("l4d2_l4d1vs_checkpoint_health_remover_enable", "1", "L4D1 Versus Score - checkpoint health items remover enable/disable", CVAR_FLAGS);
	
	//welcome message enable/disable
	cvar_welcome_msg_enable = CreateConVar("l4d2_l4d1vs_welcome_msg_enable", "1", "L4D1 Versus Score - welcome message (while joining) enable/disable", CVAR_FLAGS);
	
	//get survival bonus cvar
	cvar_survival_bonus = FindConVar("vs_survival_bonus");
	
	//save default value
	g_default_score = GetConVarInt(cvar_survival_bonus);
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
Restore default values
#######################
*/
public OnPluginEnd()
{
	//reset to default values
	setscore(g_default_score);
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
		setscore(g_default_score);
		//to prevent unhooking without a hook
		if (gb_enabled) UnhookEvents();
	}
	//save reset value on enabling
	else
	{
		g_default_score = GetConVarInt(cvar_survival_bonus);
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

	LogToFile(DEBUG_LOGFILE, "Mapstart -> %s", mapname);	
#endif
	
	//get gamemode
	new String:mode[20];
	new Handle:gamemode = FindConVar("mp_gamemode");
	GetConVarString(gamemode, mode, sizeof(mode));

#if DEBUG_ENABLE	
	LogToFile(DEBUG_LOGFILE, "--------------> Gamemode: %s", mode);
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
	LogToFile(DEBUG_LOGFILE, "--------------> Hook...");
#endif
	
	HookEvent("round_start", Event_round_start, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_round_end);
	HookEvent("door_close", Event_door_close);
	HookEvent("finale_vehicle_leaving", Event_finale_vehicle_leaving);
	HookEvent("player_left_start_area", Event_player_left_start_area);
		
	gb_enabled = true;
	
	//fix for start round missing
	gb_score_output = false;
	gb_med_try = false;
}

/*
Unhook Events
#######################
*/
UnhookEvents()
{
#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "--------------> UNhook...");
#endif

	UnhookEvent("round_start", Event_round_start);
	UnhookEvent("round_end", Event_round_end);
	UnhookEvent("door_close", Event_door_close);
	UnhookEvent("finale_vehicle_leaving", Event_finale_vehicle_leaving);	
	UnhookEvent("player_left_start_area", Event_player_left_start_area);
	
	gb_enabled = false;
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
		PrintToChat(client, "%s Welcome to this server, %N!", PLUGIN_TAG, client);
		PrintToChat(client, "%s L4D1 Score System is enabled!", PLUGIN_TAG);
		PrintToChat(client, "%s Medkits, pills and shots are important again!", PLUGIN_TAG);
		//PrintToChat(client, "%s The score multiplier is %.1f!", PLUGIN_TAG, GetConVarFloat(cvar_multiplier));
		
		return Plugin_Stop;
	}
	
	//disconnected? stop!
	if (!IsClientConnected(client)) return Plugin_Stop;
	
	return Plugin_Continue;
}

/*
set score output to false and start timer for health items
#######################
*/
public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	gb_score_output = false;
	gb_med_try = false;
	
#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "!!roundstart!!");
#endif
}


/*
try once to delete meds (important if roundstart was before mapstart and the plugin was not enabled)
#######################
*/
public Action:Event_player_left_start_area(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (gb_med_try) return;
	
	deletemeds();
	gb_med_try = true;
}
	
/*
calculate score and override variable on saferoom door closing
#######################
*/
public Action:Event_door_close(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Saferoom?
	if (GetEventBool(event, "checkpoint")) endround();
}

/*
calculate score and override variable on rescue vehicle leaving
#######################
*/
public Action:Event_finale_vehicle_leaving(Handle:event, const String:name[], bool:dontBroadcast)
{
	endround();
}

/*
show score in chat
#######################
*/
public Action:Event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Is thera any output?
	if (!gb_score_output) return Plugin_Continue;

	//Format player score
	new String:tempstring[150];
	decl String:tempstringadd[10];
	new String:plusstring[4] = " + ";
		
	StrCat(tempstring, sizeof(tempstring), PLUGIN_TAG);	
	tempstringadd = " ";
	StrCat(tempstring, sizeof(tempstring), tempstringadd);
		
	//First player without +
	Format(tempstringadd, sizeof(tempstringadd), "%d", g_player_scores[0]);
	StrCat(tempstring, sizeof(tempstring), tempstringadd);	
		
	for (new i = 1; i < g_player_count; i++)	
	{
		//+
		StrCat(tempstring, sizeof(tempstring), plusstring);
		//score
		Format(tempstringadd, sizeof(tempstringadd), "%d", g_player_scores[i]);
		StrCat(tempstring, sizeof(tempstring), tempstringadd);	
	}
	
	new Float:mapmulti;
	new Float:multi = GetConVarFloat(cvar_multiplier);
	new score = RoundFloat(float(RoundFloat(float(g_team_score)/float(g_player_count)))*multi);
	
	//map multiplier if enabled
	if (GetConVarBool(cvar_map_multiplier_enable))
	{
		mapmulti = getmapmultiplier();
		score = RoundFloat(float(score)*mapmulti);
		PrintToChatAll("%s Score = (Playerscores / Survivors) * Multiplier * Map", PLUGIN_TAG);
	}
	else PrintToChatAll("%s Score = (Playerscores / Survivors) * Multiplier", PLUGIN_TAG);
	
	PrintToChatAll("%s ####################", PLUGIN_TAG);
	PrintToChatAll("%s Playerscores:", PLUGIN_TAG);
	PrintToChatAll(tempstring);
	
	if (GetConVarBool(cvar_map_multiplier_enable)) PrintToChatAll("%s (%d / %d) * %.2f * %.2f", PLUGIN_TAG, g_team_score, g_player_count, multi, mapmulti);
	else PrintToChatAll("%s (%d / %d) * %.2f", PLUGIN_TAG, g_team_score, g_player_count, multi);

	PrintToChatAll("%s = %d per survivor", PLUGIN_TAG, score);	
	
	//Block another round end output
	gb_score_output = false;
	
	return Plugin_Continue;
}

/*
save and set team score
#######################
*/
endround()
{
	new score = getscore();
	setscore(score);
}

/*
calculate score and return it
#######################
*/
getscore()
{
	new Float:fhealth;
	new Float:ftemphealth;
	new Float:temphealth;
	new health;
	new maxplayers = MaxClients;
	new score_team = 0;
	new survivors = 0;
	new tempent;
	new String:tempname[50];

	//get defi mutliplier
	new Float:defib_multi = GetConVarFloat(cvar_defib);
	
	//search survivors
	for (new i = 1; i < maxplayers; i++)
	{
		//Ingame, survivor and alive?
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsPlayerIncap(i))
		{
			//Health
			health = GetEntProp(i, Prop_Send, "m_iHealth");
			
			//Temphealth (m_healthBuffer stores not the actual value)
			temphealth = RoundToCeil(GetEntPropFloat(i, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(i, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1.0;
			if (FloatCompare(temphealth, 0.0) == -1) temphealth = 0.0;

			//inventory
			tempent = GetPlayerWeaponSlot(i, 3);
			if (tempent > -1)
			{
				GetEdictClassname(tempent, tempname, sizeof(tempname));
				if (StrContains(tempname, "weapon_first_aid_kit") > -1)
				{
					fhealth = ((100 - health) * 0.8) + health;
					ftemphealth = 0.0;
				}
				//multiplier must be greater than 0
				if (StrContains(tempname, "weapon_defibrillator") > -1 && defib_multi > 0.0)
				{
					fhealth = ((100 - health) * defib_multi) + health;
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
						ftemphealth = temphealth + 50.0;
					}		
					if (StrContains(tempname, "weapon_adrenaline") > -1)
					{
						ftemphealth = temphealth + 25.0;
					}		
				}
				else ftemphealth = temphealth;
			}

			if (fhealth + ftemphealth > 100.0) ftemphealth = 100.0 - fhealth;

			g_player_scores[survivors] = RoundToFloor(fhealth/2) + RoundToFloor(ftemphealth/4);
			score_team += g_player_scores[survivors];			

			survivors++;
		}
	}

	//divide through survivor count 
	new iscore = RoundFloat(float(score_team)/float(survivors));

	//get multiplier
	new Float:multi = GetConVarFloat(cvar_multiplier);
	iscore = RoundFloat(float(iscore) * multi);
	
	//map multiplier if enabled
	if (GetConVarBool(cvar_map_multiplier_enable))
	{
		//get map multiplier and change score
		iscore = RoundFloat(float(iscore) * getmapmultiplier());
	}
	
	//save the score and survivorcount for output
	g_team_score = score_team;
	g_player_count = survivors;
	gb_score_output = true;
	
	return iscore;
}

/*
return map multiplier by mapname (~> custom map problem!)
#######################
*/
Float:getmapmultiplier()
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
override survival bonus variable
#######################
*/
setscore(score)
{
	SetConVarInt(cvar_survival_bonus, score);
}

/*
check if a survivor is incapped and return bool value
#######################
*/
IsPlayerIncap(client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

deletemeds()
{
	//enabled?
	if (!GetConVarBool(cvar_health_remover_enable)) return;
	
#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "DELETE");
#endif
	
	//get mapname
	new String:mapname[10];
	GetCurrentMap(mapname, sizeof(mapname));

	new campaign = StringToInt(mapname[1]);
	new map = StringToInt(mapname[3]);

#if DEBUG_ENABLE	
	LogToFile(DEBUG_LOGFILE, "Map: %d , Campaign: %d", map, campaign);
#endif
	
	//not final?
	if (IsFinal() == 1) return;

#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "Not final...");
#endif
	
	new Float:medkitpos[3];
	
	//look after medkitpos
	if (campaign == 1) 
	{
		if (map == 1)
		{
			medkitpos[0] = 2024.609497;
			medkitpos[1] = 4304.031250;
			medkitpos[2] = 1258.224731;
		}
		else if (map == 2)
		{
			medkitpos[0] = -7691.826660;
			medkitpos[1] = -4755.883301;
			medkitpos[2] = 481.251282;
		}
		else if (map == 3)
		{
			medkitpos[0] = -2203.739746;
			medkitpos[1] = -4693.715332;
			medkitpos[2] = 633.226318;
		}
	}
	else if (campaign == 2) 
	{
		if (map == 1)
		{
			medkitpos[0] = -808.031250;
			medkitpos[1] = -2485.320557;
			medkitpos[2] = -986.767700;
		}
		else if (map == 2)
		{
			medkitpos[0] = -4823.700195;
			medkitpos[1] = -5399.781250;
			medkitpos[2] = 33.232277;
		}
		else if (map == 3)
		{
			medkitpos[0] = -5456.233398;
			medkitpos[1] = 1938.839478;
			medkitpos[2] = 66.031250;
		}
		else if (map == 4)
		{
			medkitpos[0] = -663.120239;
			medkitpos[1] = 2212.477051;
			medkitpos[2] = -158.998734;
		}
	}
	else if (campaign == 3) 
	{
		if (map == 1)
		{
			medkitpos[0] = -2695.298828;
			medkitpos[1] = 552.915649;
			medkitpos[2] = 118.031250;
		}
		else if (map == 2)
		{
			medkitpos[0] = 7609.270508;
			medkitpos[1] = -1056.734619;
			medkitpos[2] = 233.226273;
		}
		else if (map == 3)
		{
			medkitpos[0] = 5087.140137;
			medkitpos[1] = -3690.015137;
			medkitpos[2] = 445.435242;
		}
	}
	else if (campaign == 4) 
	{
		if (map == 1)
		{
			medkitpos[0] = 4112.984375;
			medkitpos[1] = -1512.750610;
			medkitpos[2] = 309.473663;
		}
		else if (map == 2)
		{
			medkitpos[0] = -1807.257568;
			medkitpos[1] = -13777.250977;
			medkitpos[2] = 192.281250;
		}
		else if (map == 3)
		{
			medkitpos[0] = 3863.968750;
			medkitpos[1] = -1643.946045;
			medkitpos[2] = 309.473663;
		}
		else if (map == 4)
		{
			medkitpos[0] = -3382.549072;
			medkitpos[1] = 7791.185059;
			medkitpos[2] = 182.031250;
		}
	}
	else if (campaign == 5) 
	{
		if (map == 1)
		{
			medkitpos[0] = -4335.901367;
			medkitpos[1] = -1132.048462;
			medkitpos[2] = -281.968750;
		}
		else if (map == 2)
		{
			medkitpos[0] = -9825.106445;
			medkitpos[1] = -8167.708496;
			medkitpos[2] = -158.767731;
		}
		else if (map == 3)
		{
			medkitpos[0] = 7471.475098;
			medkitpos[1] = -9677.308594;
			medkitpos[2] = 201.226273;
		}
		else if (map == 4)
		{
			medkitpos[0] = 1588.210449;
			medkitpos[1] = -3547.540527;
			medkitpos[2] = 353.220627;
		}
	}	

#if DEBUG_ENABLE	
	LogToFile(DEBUG_LOGFILE, "Medkitpos (%f %f %f)", medkitpos[0], medkitpos[1], medkitpos[2]);
#endif
	
	//custom map?
	if (medkitpos[0] == 0.0 && medkitpos[1] == 0.0 && medkitpos[2] == 0.0)
	{
		//at the moment return
#if DEBUG_ENABLE
		LogToFile(DEBUG_LOGFILE, "custom map => return");
#endif
		return;
	}
	
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

				/* near medkitpos?
				250 exceptions:
					pills hard rain 3
					pills hard rain 4
					shot parish 4
				
				300 exceptions:
					none?
				*/
				if (GetVectorDistance(medkitpos, entpos) < 300.0) 
				{
#if DEBUG_ENABLE
					LogToFile(DEBUG_LOGFILE, "%s - in range (%f %f %f)", entname, entpos[0], entpos[1], entpos[2]);
#endif
					killentity(i);
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
killentity(entity)
{
#if DEBUG_ENABLE
	LogToFile(DEBUG_LOGFILE, "kill %d...", entity);
#endif
	AcceptEntityInput(entity, "kill");
}

/*
check if final by triiger_final entity
#######################
*/
IsFinal()
{
	new entitycount = GetEntityCount();
	new String:entname[50];

	//loop through entities
	for (new i = 1; i < entitycount; i++)
	{
		if (!IsValidEntity(i)) continue;
		
		GetEdictClassname(i, entname, sizeof(entname));
		if (StrContains(entname, "trigger_finale") > -1) return 1;
	}

	return 0;	
}