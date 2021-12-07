/**
* L4D1/2 Force Mission Changer
* For Sourcemod 1.3.4 & 1.4.0
* THX! DDR Khat
*
* Version 1.5.0
*
* -Added Mutation "Survival VS"
*
* Version 1.4.7
*
* -Added Mutation "Headshot"
* -Fixed Mutation "Room For One" with seperate .txt file
*
* Version 1.4.6
*
* -Added Mutation "Room For One"
* -Added Mutation "Chainsaw Massacre"
* -The .txt files are now read 10 seconds after mapchange to prevent a disconnection issue
*
* Version 1.4.5
*
* -Changed gamemode detection for .txt files to prevent plugin shutdown
* -Changed coopgame .txt to "sm_l4dco_mapchanger.txt" again
*
* Version 1.4.4
*
* -Changed all Coop gamemodes to use only one .txt file (sm_l4dcoop_mapchanger.txt)
* -Changed all Versus gamemdoes to use only one .txt file (sm_l4dvs_mapchanger.txt)
*
* Version 1.4.3
*
* -Added New Mutation Game Mode "The Last Gnome On Earth"
* -Added Team Versus
* -Added Coop realism
*
* Version 1.4.2: 
* -Added new Mutation - Bleed Out (L4D2)
* -Added new mutation - Realism Versus (L4D2)
* 
* Version 1.4.1: Ready for L4D2
* Fix mission announce bug
*/

#pragma semicolon 1
#include <sourcemod>
#define Version "1.5.0"

new Handle:cvarAnnounce = INVALID_HANDLE;
new Handle:Allowed = INVALID_HANDLE;
new Handle:AllowedDie = INVALID_HANDLE;
new Handle:DebugEvent = INVALID_HANDLE;
new Handle:DefM;
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
new String:next_mission_force[64] = "none";
new String:force_mission_name[64];
new RoundEndCounter = 0;
new RoundEndBlock = 0;

new IsRoundStarted = false;
new repeats;
new round_end_repeats;

public Plugin:myinfo = 
{
	name = "[L4D1/2] Force Mission Changer",
	author = "Dionys",
	description = "Force change to next mission when current mission end.",
	version = Version,
	url = "skiner@inbox.ru"
};

public OnPluginStart()
{
	hKVSettings=CreateKeyValues("ForceMissionChangerSettings");

        HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_win", Event_FinalWin);
	HookEvent("mission_lost", Event_FinalLost);
	
	CreateConVar("sm_l4d_fmc_version", Version, "Version of L4D1/2 Force Mission Changer plugin.", FCVAR_NOTIFY);
	DebugEvent = CreateConVar("sm_l4d_fmc_dbug", "0", "on-off Write event to log file.");
	Allowed = CreateConVar("sm_l4d_fmc", "1", "Enables Force changelevel when mission end.");
	AllowedDie = CreateConVar("sm_l4d_fmc_ifdie", "1", "Enables Force changelevel when all player die on final map in coop gamemodes (coop, realism, last gnome on earth, bleed out, chainsaw massacre, room for one, headshot)");
        DefM = CreateConVar("sm_l4d_fmc_def", "l4d_vs_hospital01_apartment", "Mission for change by default.");
	CheckRoundCounter = CreateConVar("sm_l4d_fmc_crec", "4", "Quantity of events RoundEnd before force of changelevel in versus gamemodes: 4 for l4d <> 1.0.1.2");
	
        ChDelayVS = CreateConVar("sm_l4d_fmc_chdelayvs", "0.0", "Delay before versus/teamversus/realism versus/survival vs mission change (float in sec).");
	ChDelayCOOP = CreateConVar("sm_l4d_fmc_chdelaycoop", "0.0", "Delay before coop/realism/last gnome on earth/chainsaw massacre/bleed out/room for one/headshot mission change (float in sec).");

	TimerRoundEndBlockVS = CreateConVar("sm_l4d_fmc_re_timer_block", "0.5", "Time in which current event round_end is not considered (float in sec).");
	cvarAnnounce = CreateConVar("sm_l4d_fmc_announce", "1", "Enables next mission to advertise to players.");

        // Execute the config file
	AutoExecConfig(true, "sm_l4dvs_mapchanger");	

	CurrentGameMode = FindConVar("mp_gamemode");
	HookConVarChange(CurrentGameMode, OnCVGameModeChange);

	logfile = OpenFile("/addons/sourcemod/logs/fmc_event.log", "w");
}

public OnMapStart()
{
	RoundEndCounter = 0;
	RoundEndBlock = 0;

	if (GetConVarInt(DebugEvent) == 1)	
		WriteFileLine(logfile, "***New map start***");

        CreateTimer(10.0, CheckGameMode, TIMER_FLAG_NO_MAPCHANGE);

        if (l4d_gamemode() == 12)
        {
	     repeats = 3;
        }

        round_end_repeats = 0;
}

public OnMapEnd()
{
	if (GetConVarInt(DebugEvent) == 1)
	{
		FlushFile(logfile);
		WriteFileLine(logfile, "***Map end***");
	}
}

public Action:CheckGameMode(Handle:timer)
{
        decl String:gamemode[64];
        GetConVarString(FindConVar("mp_gamemode"), gamemode, 64);

        if (StrEqual(gamemode, "versus") || StrEqual(gamemode, "mutation12") || StrEqual(gamemode, "teamversus"))
        {
  	     BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4dvs_mapchanger.txt");
	     if(!FileToKeyValues(hKVSettings, FMC_FileSettings))
		     SetFailState("Force Mission Changer settings not found!");
        }

        if (StrEqual(gamemode, "coop") || StrEqual(gamemode, "realism") || StrEqual(gamemode, "mutation3") || StrEqual(gamemode, "mutation9") || StrEqual(gamemode, "mutation7") || StrEqual(gamemode, "mutation2"))
        {
             BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4dco_mapchanger.txt");
	     if(!FileToKeyValues(hKVSettings, FMC_FileSettings))
		     SetFailState("Force Mission Changer settings not found!");
        }

        if (StrEqual(gamemode, "mutation10"))
        {
  	     BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4drfo_mapchanger.txt");
	     if(!FileToKeyValues(hKVSettings, FMC_FileSettings))
		     SetFailState("Force Mission Changer settings not found!");
        }
 
        if (StrEqual(gamemode, "mutation15"))
        {
  	     BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4dsv_mapchanger.txt");
	     if(!FileToKeyValues(hKVSettings, FMC_FileSettings))
		     SetFailState("Force Mission Changer settings not found!");
        }

        if(GetConVarInt(Allowed) == 1)
        {
		 next_mission_force = "none";
		 GetCurrentMap(current_map, 64);
		 GetConVarString(DefM, next_mission_def, 64);

		 KvRewind(hKVSettings);
		 if(KvJumpToKey(hKVSettings, current_map))
	         {	
                         KvGetString(hKVSettings, "next mission map", next_mission_force, 64, next_mission_def);
                         KvGetString(hKVSettings, "next mission name", force_mission_name, 64, "none");
                 }
		 if (StrEqual(next_mission_force, "none") != true)
		 {
			 if (!IsMapValid(next_mission_force))
				 next_mission_force = next_mission_def;

                         if (StrEqual(force_mission_name, "none") != true)
				 announce_map = force_mission_name;
			 else
				 announce_map = next_mission_force;
		 }

		 KvRewind(hKVSettings);
        }
}  

public OnClientPutInServer(client)
{
	// Make the announcement in 20 seconds unless announcements are turned off
	if(client && !IsFakeClient(client) && GetConVarBool(cvarAnnounce))
		CreateTimer(20.0, TimerAnnounce, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	IsRoundStarted = true;

        if (round_end_repeats > 2)
	{	

	}
}

stock IsMapSurvivalVS()
{
	if (StrEqual(current_map, "c1m4_atrium", false)
	|| StrEqual(current_map, "c2m1_highway", false)
        || StrEqual(current_map, "c2m4_barns", false)
        || StrEqual(current_map, "c2m5_concert", false)
        || StrEqual(current_map, "c3m1_plankcountry", false)
	|| StrEqual(current_map, "c3m4_plankcountry", false)
	|| StrEqual(current_map, "c4m1_milltown_a", false)
        || StrEqual(current_map, "c4m2_sugarmill_a", false)
        || StrEqual(current_map, "c5m2_park", false)
        || StrEqual(current_map, "c5m5_bridge", false)
        || StrEqual(current_map, "c6m1_riverbank", false)
        || StrEqual(current_map, "c6m2_bedlam", false)
        || StrEqual(current_map, "c6m3_port", false))
	{
		return true;
	}
	return false;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (RoundEndBlock == 0)
	{
		RoundEndCounter += 1;
		RoundEndBlock = 1;
		CreateTimer(GetConVarFloat(TimerRoundEndBlockVS), TimerRoundEndBlock, TIMER_FLAG_NO_MAPCHANGE);
	} 

	if (GetConVarInt(DebugEvent) == 1)
	{
		PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: \"%s\" NUM: \"%d\" ", l4d_gamemode(), name, RoundEndCounter);
		decl String:mBuffer[128];
		Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: \"%s\" NUM: \"%d\" ", l4d_gamemode(), current_map, name, RoundEndCounter);
		WriteFileLine(logfile, mBuffer);
	}
	
	if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 2 && StrEqual(next_mission_force, "none") != true && GetConVarInt(CheckRoundCounter) != 0 && RoundEndCounter >= GetConVarInt(CheckRoundCounter))
	{
		if (GetConVarInt(DebugEvent) == 1)
		{
			PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: START FMC TIMER ", l4d_gamemode());
			decl String:mBuffer[128];
			Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: START FMC TIMER ", l4d_gamemode(), current_map);
			WriteFileLine(logfile, mBuffer);
		}

		CreateTimer(GetConVarFloat(ChDelayVS), TimerChDelayVS, TIMER_FLAG_NO_MAPCHANGE);
		RoundEndCounter = 0;
	}

        // for realism vs
        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 3 && StrEqual(next_mission_force, "none") != true && GetConVarInt(CheckRoundCounter) != 0 && RoundEndCounter >= GetConVarInt(CheckRoundCounter))
	{
		if (GetConVarInt(DebugEvent) == 1)
		{
			PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: START FMC TIMER ", l4d_gamemode());
			decl String:mBuffer[128];
			Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: START FMC TIMER ", l4d_gamemode(), current_map);
			WriteFileLine(logfile, mBuffer);
		}

		CreateTimer(GetConVarFloat(ChDelayVS), TimerChDelayVS, TIMER_FLAG_NO_MAPCHANGE);
		RoundEndCounter = 0;
	}
 
        // for team vs
        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 6 && StrEqual(next_mission_force, "none") != true && GetConVarInt(CheckRoundCounter) != 0 && RoundEndCounter >= GetConVarInt(CheckRoundCounter))
	{
		if (GetConVarInt(DebugEvent) == 1)
		{
			PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: START FMC TIMER ", l4d_gamemode());
			decl String:mBuffer[128];
			Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: START FMC TIMER ", l4d_gamemode(), current_map);
			WriteFileLine(logfile, mBuffer);
		}

		CreateTimer(GetConVarFloat(ChDelayVS), TimerChDelayVS, TIMER_FLAG_NO_MAPCHANGE);
		RoundEndCounter = 0;
	}

        if (!IsRoundStarted)
	{
		return;
	}


        if (l4d_gamemode() == 12 && StrEqual(next_mission_force, "none") != true)
	{
             if (IsMapSurvivalVS())
	     {
		  round_end_repeats++;
	
		  repeats--;
		  if (repeats < 1)
		  {
			 CreateTimer(8.0, TimerChDelayVS);
		  } 
	     }
	
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
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP, TIMER_FLAG_NO_MAPCHANGE);

        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 5 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP, TIMER_FLAG_NO_MAPCHANGE);

        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 7 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP, TIMER_FLAG_NO_MAPCHANGE);
  
        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 8 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP, TIMER_FLAG_NO_MAPCHANGE);
 
        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 9 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP, TIMER_FLAG_NO_MAPCHANGE);

        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 10 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP, TIMER_FLAG_NO_MAPCHANGE);
 
        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 11 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP, TIMER_FLAG_NO_MAPCHANGE);
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
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP, TIMER_FLAG_NO_MAPCHANGE);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && l4d_gamemode() == 5 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP, TIMER_FLAG_NO_MAPCHANGE);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && l4d_gamemode() == 7 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP, TIMER_FLAG_NO_MAPCHANGE);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && l4d_gamemode() == 8 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP, TIMER_FLAG_NO_MAPCHANGE);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && l4d_gamemode() == 9 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP, TIMER_FLAG_NO_MAPCHANGE);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && l4d_gamemode() == 10 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP, TIMER_FLAG_NO_MAPCHANGE);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && l4d_gamemode() == 11 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP, TIMER_FLAG_NO_MAPCHANGE);
}

public OnCVGameModeChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	//If game mode actually changed
	if (strcmp(oldValue, newValue) != 0 && (l4d_gamemode() == 1 || l4d_gamemode() == 2 || l4d_gamemode() == 3 || l4d_gamemode() == 4 || l4d_gamemode() == 5 || l4d_gamemode() == 6 || l4d_gamemode() == 7 || l4d_gamemode() == 8 || l4d_gamemode() == 9 || l4d_gamemode() == 10 || l4d_gamemode() == 11  || l4d_gamemode() == 12))
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
        else if (strcmp(gmode, "mutation15", false) == 0)
	{
		return 12;
	} 
	else
	{
		return false;
	}
}

