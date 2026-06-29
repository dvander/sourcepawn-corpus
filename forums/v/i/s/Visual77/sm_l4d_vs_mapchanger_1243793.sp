/**
* L4D Force Mission Changer
* For Sourcemod 1.3.0 and 1.4.0
* THX! DDR Khat
*
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
*/

#pragma semicolon 1
#include <sourcemod>
#define Version "1.5.2"

new Handle:cvarAnnounce = INVALID_HANDLE;
new Handle:Allowed = INVALID_HANDLE;
new Handle:AllowedDie = INVALID_HANDLE;
new Handle:DebugEvent = INVALID_HANDLE;
new Handle:CheckRoundCounter;
new Handle:CheckRoundCounterSurvVS;
new Handle:ChDelayVS;
new Handle:ChDelaySurvVS;
new Handle:ChDelayCOOP;
new Handle:TimerRoundEndBlockVS;

new Handle:hKVSettings = INVALID_HANDLE;
new Handle:logfile;
new String:gmode[64] = "";
new String:FMC_FileSettings[128];
new String:current_map[64];
new String:announce_map[64];
new String:next_mission_def[64];
new String:next_mission_force[64] = "none";
new String:force_mission_name[64];
new RoundEndCounter = 0;
new RoundEndBlock = 0;

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

        //gmode = FindConVar("mp_gamemode");
	
	CreateConVar("sm_l4d_fmc_version", Version, "Version of L4D1/2 Force Mission Changer plugin.", FCVAR_NOTIFY);
	DebugEvent = CreateConVar("sm_l4d_fmc_dbug", "0", "on-off Write event to log file.");
	Allowed = CreateConVar("sm_l4d_fmc", "1", "Enables Force changelevel when mission end.");
	AllowedDie = CreateConVar("sm_l4d_fmc_ifdie", "1", "Enables Force changelevel when all player die on final map in coop gamemodes (coop, realism, last gnome on earth, bleed out, chainsaw massacre, room for one, headshot, four swordsmen)");
	CheckRoundCounter = CreateConVar("sm_l4d_fmc_crec", "4", "Quantity of events RoundEnd before force of changelevel in versus gamemodes: 4");
        CheckRoundCounterSurvVS = CreateConVar("sm_l4d_fmc_crec_survivalvs", "4", "Quantity of events RoundEnd before force of changelevel in survival versus: 3");	
        ChDelayVS = CreateConVar("sm_l4d_fmc_chdelayvs", "0.0", "Delay before versus/teamversus/realism versus mission change (float in sec).");
        ChDelaySurvVS = CreateConVar("sm_l4d_fmc_chdelaysurvvs", "0.0", "Delay before survial versus change (float in sec).");
	ChDelayCOOP = CreateConVar("sm_l4d_fmc_chdelaycoop", "0.0", "Delay before coop/realism/last gnome on earth/chainsaw massacre/bleed out/room for one/headshot/four swordsmen change (float in sec).");

        TimerRoundEndBlockVS = CreateConVar("sm_l4d_fmc_re_timer_block", "0.5", "Time in which current event round_end is not considered (float in sec).");
	cvarAnnounce = CreateConVar("sm_l4d_fmc_announce", "1", "Enables next mission to advertise to players.");

        // Used for Survival VS and all other game modes to prevent issues.
        SetConVarInt(FindConVar("mp_roundlimit"), 5);

        // Execute the config file
	AutoExecConfig(true, "sm_l4dvs_mapchanger");
	
	logfile = OpenFile("/addons/sourcemod/logs/fmc_event.log", "w");
}

public OnMapStart()
{
	RoundEndCounter = 0;
	RoundEndBlock = 0;

	if (GetConVarInt(DebugEvent) == 1)	
		WriteFileLine(logfile, "***New map start***");
             
        CreateTimer(5.0, CheckGameMode);
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

public Action:CheckGameMode(Handle:timer)
{
        decl String:gamemode[64];
        GetConVarString(FindConVar("mp_gamemode"), gamemode, 64);

        if (StrEqual(gamemode, "versus") || StrEqual(gamemode, "mutation12") || StrEqual(gamemode, "teamversus"))
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
  
        if (StrEqual(gamemode, "mutation15"))
        {
             hKVSettings=CreateKeyValues("ForceMissionChangerSettings");
  	     BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4dsv_mapchanger.txt");
	     if(!FileToKeyValues(hKVSettings, FMC_FileSettings))
		     SetFailState("sm_l4dsv_mapchanger.txt not found!");
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
		CreateTimer(20.0, TimerAnnounce, client);
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
		PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: \"%s\" NUM: \"%d\" ", gmode, name, RoundEndCounter);
		decl String:mBuffer[128];
		Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: \"%s\" NUM: \"%d\" ", gmode, current_map, name, RoundEndCounter);
		WriteFileLine(logfile, mBuffer);
	}
	
	if(GetConVarInt(Allowed) == 1 && StrContains(gmode, "versus", false) != -1 && StrEqual(next_mission_force, "none") != true && GetConVarInt(CheckRoundCounter) != 0 && RoundEndCounter >= GetConVarInt(CheckRoundCounter))
	{
		if (GetConVarInt(DebugEvent) == 1)
		{
			PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: START FMC TIMER ", gmode);
			decl String:mBuffer[128];
			Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: START FMC TIMER ", gmode, current_map);
			WriteFileLine(logfile, mBuffer);
		}

		CreateTimer(GetConVarFloat(ChDelayVS), TimerChDelayVS);
		RoundEndCounter = 0;
	}

        // for realism vs
        if(GetConVarInt(Allowed) == 1 && StrContains(gmode, "mutation12", false) != -1 && StrEqual(next_mission_force, "none") != true && GetConVarInt(CheckRoundCounter) != 0 && RoundEndCounter >= GetConVarInt(CheckRoundCounter))
	{
		if (GetConVarInt(DebugEvent) == 1)
		{
			PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: START FMC TIMER ", gmode);
			decl String:mBuffer[128];
			Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: START FMC TIMER ", gmode, current_map);
			WriteFileLine(logfile, mBuffer);
		}

		CreateTimer(GetConVarFloat(ChDelayVS), TimerChDelayVS);
		RoundEndCounter = 0;
	}
 
        // for team vs
        if(GetConVarInt(Allowed) == 1 && StrContains(gmode, "teamversus", false) != -1 && StrEqual(next_mission_force, "none") != true && GetConVarInt(CheckRoundCounter) != 0 && RoundEndCounter >= GetConVarInt(CheckRoundCounter))
	{
		if (GetConVarInt(DebugEvent) == 1)
		{
			PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: START FMC TIMER ", gmode);
			decl String:mBuffer[128];
			Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: START FMC TIMER ", gmode, current_map);
			WriteFileLine(logfile, mBuffer);
		}

		CreateTimer(GetConVarFloat(ChDelayVS), TimerChDelayVS);
		RoundEndCounter = 0;
	}

        // for team vs
        if(GetConVarInt(Allowed) == 1 && StrContains(gmode, "teamversus", false) != -1 && StrEqual(next_mission_force, "none") != true && GetConVarInt(CheckRoundCounter) != 0 && RoundEndCounter >= GetConVarInt(CheckRoundCounter))
	{
		if (GetConVarInt(DebugEvent) == 1)
		{
			PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: START FMC TIMER ", gmode);
			decl String:mBuffer[128];
			Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: START FMC TIMER ", gmode, current_map);
			WriteFileLine(logfile, mBuffer);
		}

		CreateTimer(GetConVarFloat(ChDelayVS), TimerChDelayVS);
		RoundEndCounter = 0;
	}
 
        // for survival vs
        if(GetConVarInt(Allowed) == 1 && StrContains(gmode, "mutation15", false) != -1 && StrEqual(next_mission_force, "none") != true && GetConVarInt(CheckRoundCounterSurvVS) != 0 && RoundEndCounter >= GetConVarInt(CheckRoundCounterSurvVS))
	{
		if (GetConVarInt(DebugEvent) == 1)
		{
			PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: START FMC TIMER ", gmode);
			decl String:mBuffer[128];
			Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: START FMC TIMER ", gmode, current_map);
			WriteFileLine(logfile, mBuffer);
		}

		CreateTimer(GetConVarFloat(ChDelaySurvVS), TimerChDelaySurvVS);
		RoundEndCounter = 0;
	}
}

public Action:Event_FinalWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(DebugEvent) == 1)
	{
		PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: \"%s\" ", gmode, name);
		decl String:mBuffer[128];
		Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: \"%s\" ", gmode, current_map, name);
		WriteFileLine(logfile, mBuffer);
	}

	if(GetConVarInt(Allowed) == 1 && StrContains(gmode, "coop", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && StrContains(gmode, "mutation3", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && StrContains(gmode, "realism", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);
  
        if(GetConVarInt(Allowed) == 1 && StrContains(gmode, "mutation9", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);
 
        if(GetConVarInt(Allowed) == 1 && StrContains(gmode, "mutation7", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && StrContains(gmode, "mutation10", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);
 
        if(GetConVarInt(Allowed) == 1 && StrContains(gmode, "mutation2", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && StrContains(gmode, "mutation5", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && StrContains(gmode, "mutation4", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);
}

public Action:Event_FinalLost(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(DebugEvent) == 1)
	{
		PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: \"%s\" ", gmode, name);
		decl String:mBuffer[128];
		Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: \"%s\" ", gmode, current_map, name);
		WriteFileLine(logfile, mBuffer);
	}

	if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && StrContains(gmode, "coop", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && StrContains(gmode, "mutation3", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && StrContains(gmode, "realism", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && StrContains(gmode, "mutation9", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && StrContains(gmode, "mutation7", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && StrContains(gmode, "mutation10", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && StrContains(gmode, "mutation2", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && StrContains(gmode, "mutation5", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDie) && StrContains(gmode, "mutation4", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);
}

public Action:TimerRoundEndBlock(Handle:timer)
{
	RoundEndBlock = 0;
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

public Action:TimerChDelayVS(Handle:timer)
{
	if (GetConVarInt(DebugEvent) == 1)
	{
		PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: changemission to \"%s\" ", gmode, next_mission_force);
		decl String:mBuffer[128];
		Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: changemission to \"%s\" ", gmode, current_map, next_mission_force);
		WriteFileLine(logfile, mBuffer);
	}

	ServerCommand("changelevel %s", next_mission_force);
}

public Action:TimerChDelaySurvVS(Handle:timer)
{
	if (GetConVarInt(DebugEvent) == 1)
	{
		PrintToChatAll("\x04[FMC DEBUG]\x03 MODE: \"%d\" EVENT: changemission to \"%s\" ", gmode, next_mission_force);
		decl String:mBuffer[128];
		Format(mBuffer, sizeof(mBuffer), "MODE: \"%d\" MAP: \"%s\" EVENT: changemission to \"%s\" ", gmode, current_map, next_mission_force);
		WriteFileLine(logfile, mBuffer);
	}

	ServerCommand("changelevel %s", next_mission_force);
}

public Action:TimerChDelayCOOP(Handle:timer)
{
	ServerCommand("changelevel %s", next_mission_force);
}
