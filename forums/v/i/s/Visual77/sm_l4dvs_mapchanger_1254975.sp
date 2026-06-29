/**
* L4D Force Mission Changer
* For Sourcemod 1.3x and 1.4.0
* THX! DDR Khat
*
*
* Version 1.5.4                 Gone back to the old methods used in version 1.3.4 and 1.4.5
*                               as latest update broke my method. Things should now be working again.                               
*
* Version 1.5.3                 Fixed plugin incompability, removed Survival VS support
*                               and added support for the new mutation "Healthpackalypse"
*
* Version 1.5.2                 Survival VS + Hard Eight Support. 
*
* Version 1.5.1                 Rewrote and cleaned up some code that wasn't needed.
*                               This might have fixed the kick bug on map change.
*
* Version 1.5.0                 Added mutation Four Swordsmen of the Apocalypse, minor changes to
*                               gamemode detection
*
* Version 1.4.7	                Added mutation Headshot and Room For one with a seperate .txt file
*
* Version 1.4.6		        Added mutation Room For One & Chainsaw Massacre. 
*				
* Version 1.4.5	                Changed gamemode detection for .txt files.										
*												
* Version 1.4.4	                Changed all coop gamemodes to sm_l4dco_mapchanger.txt
*                               and all versus gamemodes to sm_l4dvs_mapchanger.txt										
*											
* Version 1.4.3			Added mutation Last Gnome On Earth and support for
*                               realism coop and team versus	
*
* Version 1.4.2		        Added mutation Bleed Out and Realism VS
*						
* Version 1.4.1		        Fixed for L4D2. Coding based on old stable version 1.3.2 and 1.3.4
* 
* Version 1.3.4	                Bugs fixes, causes only 1 round in final	        
*/

#pragma semicolon 1
#include <sourcemod>

#define Version "1.5.4"
#define MAX_ARRAY_LINE 50
#define MAX_MAPNAME_LEN 64
#define MAX_CREC_LEN 2
#define MAX_REBFl_LEN 8

new Handle:cvarAnnounce = INVALID_HANDLE;
new Handle:Allowed = INVALID_HANDLE;
new Handle:AllowedDie = INVALID_HANDLE;
new Handle:DebugEvent = INVALID_HANDLE;
new Handle:CheckRoundCounter;
new Handle:ChDelayVS;
new Handle:ChDelayCOOP;
new Handle:TimerRoundEndBlockVS;

new Handle:hKVSettings = INVALID_HANDLE;

new Handle:CurrentGameMode = INVALID_HANDLE;

new Handle:logfile;

new String:FMC_FileSettings[128];
new String:current_map[64];
new String:announce_map[64];
new String:next_mission_def[64];
new String:next_mission_force[64];
new String:force_mission_name[64];
new RoundEndCounter = 0;
new RoundEndCounterValue = 0;
new RoundEndBlock = 0;
new Float:RoundEndBlockValue = 0.0;

new String:MapNameArrayLine[MAX_ARRAY_LINE][MAX_MAPNAME_LEN];
new String:CrecNumArrayLine[MAX_ARRAY_LINE][MAX_CREC_LEN];
new String:reBlkFlArrayLine[MAX_ARRAY_LINE][MAX_REBFl_LEN];
new g_ArrayCount = 0;

public Plugin:myinfo = 
{
	name = "[L4D/2] Force Mission Changer",
	author = "Dionys",
	description = "Force change to next mission when current mission end.",
	version = Version,
	url = "skiner@inbox.ru"
};

public OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_win", Event_FinalWin);
	HookEvent("mission_lost", Event_FinalLost);
	
	CreateConVar("sm_l4d_fmc_version", Version, "Version of L4D Force Mission Changer plugin.", FCVAR_NOTIFY);
	DebugEvent = CreateConVar("sm_l4d_fmc_dbug", "0", "on-off Write event to log file.");
	Allowed = CreateConVar("sm_l4d_fmc", "1", "Enables Force changelevel when mission end.");
	AllowedDie = CreateConVar("sm_l4d_fmc_ifdie", "1", "Enables Force changelevel when all player die on final map in coop gamemodes (coop, realism, last gnome on earth, bleed out, chainsaw massacre, room for one, headshot, four swordsmen, hard eight)");
	CheckRoundCounter = CreateConVar("sm_l4d_fmc_crec", "4", "Quantity of events RoundEnd before force of changelevel in versus: 4 for l4d <> 1.0.1.2");
	ChDelayVS = CreateConVar("sm_l4d_fmc_chdelayvs", "0.0", "Delay before versus/teamversus/realism versus/healthpackalypse mission change (float in sec).");
	ChDelayCOOP = CreateConVar("sm_l4d_fmc_chdelaycoop", "0.0", "Delay before coop/realism/last gnome on earth/chainsaw massacre/bleed out/room for one/headshot/four swordsmen/hard eight change (float in sec).");
	TimerRoundEndBlockVS = CreateConVar("sm_l4d_fmc_re_timer_block", "0.5", "Time in which current event round_end is not considered (float in sec).");
	cvarAnnounce = CreateConVar("sm_l4d_fmc_announce", "1", "Enables next mission to advertise to players.");
	
	//For custom crec
	RegServerCmd("sm_l4d_fmc_crec_add", Command_CrecAdd, "Add custom value sm_l4d_fmc_crec and sm_l4d_fmc_re_timer_block for the specified map. Max 50.");
	RegServerCmd("sm_l4d_fmc_crec_clear", Command_CrecClear, "Clear all custom value sm_l4d_fmc_crec and sm_l4d_fmc_re_timer_block.");
	RegServerCmd("sm_l4d_fmc_crec_list", Command_CrecList, "Show all custom value sm_l4d_fmc_crec and sm_l4d_fmc_re_timer_block.");

	// Execute the config file
	AutoExecConfig(true, "sm_l4dvs_mapchanger");

	CurrentGameMode = FindConVar("mp_gamemode");
	HookConVarChange(CurrentGameMode,OnCVGameModeChange);

	logfile = OpenFile("/addons/sourcemod/logs/fmc_event.log", "w");
}

public OnMapStart()
{
	RoundEndCounter = 0;
	RoundEndBlock = 0;

	if (GetConVarInt(DebugEvent) == 1)	
		WriteFileLine(logfile, "***New map start***");

        CreateTimer(5.0, CheckGameMode, TIMER_FLAG_NO_MAPCHANGE);

	if (GetConVarInt(DebugEvent) == 1)
	{
		PrintToChatAll("\x04[FMC DEBUG]\x03 MapStart: RECV: \"%d\" REBV: \"%d\"", RoundEndCounterValue, RoundEndBlockValue);
		decl String:mBuffer[128];
		Format(mBuffer, sizeof(mBuffer), "MapStart: RECV: \"%d\" REBV: \"%d\"", RoundEndCounterValue, RoundEndBlockValue);
		WriteFileLine(logfile, mBuffer);
	}

}

public Action:CheckGameMode(Handle:timer)
{
        decl String:gamemode[64];
        GetConVarString(FindConVar("mp_gamemode"), gamemode, 64);

        if (StrEqual(gamemode, "versus") || StrEqual(gamemode, "mutation12") || StrEqual(gamemode, "teamversus") || StrEqual(gamemode, "mutation11"))
        {
             hKVSettings=CreateKeyValues("ForceMissionChangerSettings");
  	     BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4dvs_mapchanger.txt");
	     if(!FileToKeyValues(hKVSettings, FMC_FileSettings))
		     SetFailState("sm_l4dvs_mapchanger.txt not found!");
        }

        if (StrEqual(gamemode, "coop") || StrEqual(gamemode, "realism") || StrEqual(gamemode, "mutation3") || StrEqual(gamemode, "mutation9") || StrEqual(gamemode, "mutation7") || StrEqual(gamemode, "mutation2") || StrEqual(gamemode, "mutation5") || StrEqual(gamemode, "mutation4"))
        {
             hKVSettings=CreateKeyValues("ForceMissionChangerSettings");
             BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4dco_mapchanger.txt");
	     if(!FileToKeyValues(hKVSettings, FMC_FileSettings))
		     SetFailState("sm_l4dco_mapchanger.txt not found!");
        }

        if (StrEqual(gamemode, "mutation10"))
        {
             hKVSettings=CreateKeyValues("ForceMissionChangerSettings");
  	     BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4drfo_mapchanger.txt");
	     if(!FileToKeyValues(hKVSettings, FMC_FileSettings))
		     SetFailState("sm_l4drfo_mapchanger.txt not found!");
        }
         
        if(GetConVarInt(Allowed) == 1)
	{
		next_mission_force = "none";
		GetCurrentMap(current_map, 64);

		KvRewind(hKVSettings);
		if(KvJumpToKey(hKVSettings, current_map))
		{
			KvGetString(hKVSettings, "next mission map", next_mission_force, 64, next_mission_def);
			KvGetString(hKVSettings, "next mission name", force_mission_name, 64, "none");
		}
		KvRewind(hKVSettings);
		
		if (StrEqual(next_mission_force, "none") != true)
		{
			if (!IsMapValid(next_mission_force))
				next_mission_force = next_mission_def;
				
			if (StrEqual(force_mission_name, "none") != true)
				announce_map = force_mission_name;
			else
				announce_map = next_mission_force;
				
			RoundEndCounterValue = 0;
			RoundEndBlockValue = 0.0;
			for (new i = 0; i < g_ArrayCount; i++)
			{
				if (StrEqual(next_mission_force, MapNameArrayLine[i]) == true)
				{
					RoundEndCounterValue = StringToInt(CrecNumArrayLine[g_ArrayCount]);
					RoundEndBlockValue = StringToFloat(reBlkFlArrayLine[g_ArrayCount]);
					break;
				}
			}
			if (RoundEndCounterValue == 0)
				RoundEndCounterValue = GetConVarInt(CheckRoundCounter);
			if (RoundEndBlockValue == 0.0)
				RoundEndBlockValue = GetConVarFloat(ChDelayVS);
		}
	}
}  

public OnMapEnd()
{
	if (GetConVarInt(DebugEvent) == 1)
	{
		PrintToChatAll("\x04[FMC DEBUG]\x03 MapEnd");
		FlushFile(logfile);
		WriteFileLine(logfile, "***Map end***");
	}
}

public OnClientPutInServer(client)
{
	// Make the announcement in 20 seconds unless announcements are turned off
	if(client && !IsFakeClient(client) && GetConVarBool(cvarAnnounce))
		CreateTimer(20.0, TimerAnnounce, client);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (RoundEndBlock == 0)
	{
		RoundEndCounter += 1;
		RoundEndBlock = 1;
		CreateTimer(GetConVarFloat(TimerRoundEndBlockVS), TimerRoundEndBlock);
	}

	if (GetConVarInt(DebugEvent) == 1)
	{
		new winnerteam = GetEventInt(event, "winner");

		PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: \"%s\" NUM: \"%d\" TWIN: \"%d\"", l4d_gamemode(), name, RoundEndCounter, winnerteam);
		decl String:mBuffer[128];
		Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: \"%s\" NUM: \"%d\" TWIN: \"%d\"", l4d_gamemode(), current_map, name, RoundEndCounter, winnerteam);
		WriteFileLine(logfile, mBuffer);
	}
	
	if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 2 && StrEqual(next_mission_force, "none") != true && GetConVarInt(CheckRoundCounter) != 0 && RoundEndCounter >= RoundEndCounterValue)
	{
		if (GetConVarInt(DebugEvent) == 1)
		{
			PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: START FMC TIMER ", l4d_gamemode());
			decl String:mBuffer[128];
			Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: START FMC TIMER ", l4d_gamemode(), current_map);
			WriteFileLine(logfile, mBuffer);
		}

		CreateTimer(RoundEndBlockValue, TimerChDelayVS);
		RoundEndCounter = 0;
	}

        // Realism VS
	if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 3 && StrEqual(next_mission_force, "none") != true && GetConVarInt(CheckRoundCounter) != 0 && RoundEndCounter >= RoundEndCounterValue)
	{
		if (GetConVarInt(DebugEvent) == 1)
		{
			PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: START FMC TIMER ", l4d_gamemode());
			decl String:mBuffer[128];
			Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: START FMC TIMER ", l4d_gamemode(), current_map);
			WriteFileLine(logfile, mBuffer);
		}

		CreateTimer(RoundEndBlockValue, TimerChDelayVS);
		RoundEndCounter = 0;
	}

        // Team VS
        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 6 && StrEqual(next_mission_force, "none") != true && GetConVarInt(CheckRoundCounter) != 0 && RoundEndCounter >= GetConVarInt(CheckRoundCounter))
	{
		if (GetConVarInt(DebugEvent) == 1)
		{
			PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: START FMC TIMER ", l4d_gamemode());
			decl String:mBuffer[128];
			Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: START FMC TIMER ", l4d_gamemode(), current_map);
			WriteFileLine(logfile, mBuffer);
		}

		CreateTimer(RoundEndBlockValue, TimerChDelayVS);
		RoundEndCounter = 0;
	}

        // Healthpackalypse
        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 14 && StrEqual(next_mission_force, "none") != true && GetConVarInt(CheckRoundCounter) != 0 && RoundEndCounter >= GetConVarInt(CheckRoundCounter))
	{
		if (GetConVarInt(DebugEvent) == 1)
		{
			PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: START FMC TIMER ", l4d_gamemode());
			decl String:mBuffer[128];
			Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: START FMC TIMER ", l4d_gamemode(), current_map);
			WriteFileLine(logfile, mBuffer);
		}

		CreateTimer(RoundEndBlockValue, TimerChDelayVS);
		RoundEndCounter = 0;
	}
}

public Action:Event_FinalWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(DebugEvent) == 1)
	{
		PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: \"%s\" ", l4d_gamemode(), name);
		decl String:mBuffer[128];
		Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: \"%s\" ", l4d_gamemode(), current_map, name);
		WriteFileLine(logfile, mBuffer);
	}

	if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 5 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 7 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);
  
        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 8 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 8 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);
 
        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 9 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 9 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 10 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 11 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 12 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 13 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);
}


public Action:Event_FinalLost(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(DebugEvent) == 1)
	{
		PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: \"%s\" ", l4d_gamemode(), name);
		decl String:mBuffer[128];
		Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: \"%s\" ", l4d_gamemode(), current_map, name);
		WriteFileLine(logfile, mBuffer);
	}

	if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && l4d_gamemode() == 1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && l4d_gamemode() == 5 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && l4d_gamemode() == 7 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && l4d_gamemode() == 8 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);
 
        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && l4d_gamemode() == 9 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);
 
        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && l4d_gamemode() == 10 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);
 
        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && l4d_gamemode() == 11 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && l4d_gamemode() == 12 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && l4d_gamemode() == 13 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);
}

public OnCVGameModeChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	//If game mode actually changed
	if (strcmp(oldValue, newValue) != 0 && (l4d_gamemode() == 1 || l4d_gamemode() == 2 || l4d_gamemode() == 3 || l4d_gamemode() == 4 || l4d_gamemode() == 5 || l4d_gamemode() == 6 || l4d_gamemode() == 7 || l4d_gamemode() == 8 || l4d_gamemode() == 9 || l4d_gamemode() == 10 || l4d_gamemode() == 11 || l4d_gamemode() == 12 || l4d_gamemode() == 13 || l4d_gamemode() == 14))
	{
		HookEvent("round_end", Event_RoundEnd);
		HookEvent("finale_win", Event_FinalWin);
		HookEvent("mission_lost", Event_FinalLost);
	}
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if (StrEqual(next_mission_force, "none") != true)
		{
			PrintToChat(client, "\x04[FMC]\x03 The finale has begun. Finish them all!");
			PrintToChat(client, "\x04[FMC]\x03 Next mission: \x04%s.", announce_map);
		}
	}
}

public Action:TimerRoundEndBlock(Handle:timer)
{
	RoundEndBlock = 0;
}

public Action:TimerChDelayVS(Handle:timer)
{
	if (GetConVarInt(DebugEvent) == 1)
	{
		PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: changemission to \"%s\" ", l4d_gamemode(), next_mission_force);
		decl String:mBuffer[128];
		Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: changemission to \"%s\" ", l4d_gamemode(), current_map, next_mission_force);
		WriteFileLine(logfile, mBuffer);
	}

	ServerCommand("changelevel %s", next_mission_force);
}

public Action:TimerChDelayCOOP(Handle:timer)
{
	ServerCommand("changelevel %s", next_mission_force);
}

l4d_gamemode()
{
	new String:gmode[32];
	GetConVarString(FindConVar("mp_gamemode"), gmode, sizeof(gmode));

	if (strcmp(gmode, "coop") == 0)
	{
		return 1;
	}
	else if (strcmp(gmode, "versus", false) == 0)
	{
		return 2;
	}
	else if (strcmp(gmode, "mutation12", false) == 0)
	{
		return 3;
	}
        else if (strcmp(gmode, "survival", false) == 0)
	{
		return 4;
	}
        else if (strcmp(gmode, "mutation3", false) == 0)
	{
		return 5;
	}
        else if (strcmp(gmode, "teamversus", false) == 0)
	{
		return 6;
	}
        else if (strcmp(gmode, "realism", false) == 0)
	{
		return 7;
	}
        else if (strcmp(gmode, "mutation9", false) == 0)
	{
		return 8;
	} 
        else if (strcmp(gmode, "mutation7", false) == 0)
	{
		return 9;
	} 
        else if (strcmp(gmode, "mutation10", false) == 0)
	{
		return 10;
	} 
        else if (strcmp(gmode, "mutation2", false) == 0)
	{
		return 11;
	} 
        else if (strcmp(gmode, "mutation5", false) == 0)
	{
		return 12;
	} 
        else if (strcmp(gmode, "mutation4", false) == 0)
	{
		return 13;
	} 
        else if (strcmp(gmode, "mutation11", false) == 0)
	{
		return 14;
	} 
	else
	{
		return false;
	}
}

public Action:Command_CrecClear(args)
{
	g_ArrayCount = 0;
	PrintToServer("[FMC] Custom value sm_l4d_fmc_crec now is clear.");
}

public Action:Command_CrecAdd(args)
{
	if (g_ArrayCount == MAX_ARRAY_LINE)
	{
		PrintToServer("[FMC] Max number of array line for sm_l4d_fmc_crec_add reached.");
		return;
	}

	decl String:cmdarg1[MAX_MAPNAME_LEN];
	GetCmdArg(1, cmdarg1, sizeof(cmdarg1));
	decl String:cmdarg2[MAX_CREC_LEN];
	GetCmdArg(2, cmdarg2, sizeof(cmdarg2));
	decl String:cmdarg3[MAX_REBFl_LEN];
	GetCmdArg(3, cmdarg3, sizeof(cmdarg3));

	// Check for doubles
	new bool:isDouble = false;
	for (new i = 0; i < g_ArrayCount; i++)
	{
		if (StrEqual(cmdarg1, MapNameArrayLine[i]) == true)
		{
			isDouble = true;
			break;
		}
	}


	if (IsMapValid(cmdarg1) && StringToInt(cmdarg2) != 0 && StringToFloat(cmdarg3) != 0.0)
	{
		if (!isDouble)
		{
			strcopy(MapNameArrayLine[g_ArrayCount], MAX_MAPNAME_LEN, cmdarg1);
			strcopy(CrecNumArrayLine[g_ArrayCount], MAX_CREC_LEN, cmdarg2);
			strcopy(reBlkFlArrayLine[g_ArrayCount], MAX_REBFl_LEN, cmdarg3);
			g_ArrayCount++;
		}
	}
	else
		PrintToServer("[FMC] Error command. Use: sm_l4d_fmc_crec_add <existing custom map> <custom sm_l4d_fmc_crec integer value (max 99)> <custom sm_l4d_fmc_re_timer_block float value>.");
}

public Action:Command_CrecList(args)
{
	PrintToServer("[FMC] Custom value sm_l4d_fmc_crec and sm_l4d_fmc_re_timer_block list:");
	for (new i = 0; i < g_ArrayCount; i++)
	{
		PrintToServer("[%d] %s - %s - %s", i, MapNameArrayLine[i], CrecNumArrayLine[i], reBlkFlArrayLine[i]);
	}
	PrintToServer("[FMC] Custom value sm_l4d_fmc_crec and sm_l4d_fmc_re_timer_block list end.");
}
