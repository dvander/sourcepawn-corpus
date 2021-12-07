/**
* L4D Force Mission Changer
* For Sourcemod 1.3.0 & 1.4.0
* THX! DDR Khat
*
* Version 1.4.3
*
* -Added New Mutation Game Mode "The Last Gnome On Earth"
* -Added Team Versus
* -Added Coop realism
*
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
#define Version "1.4.3"

new Handle:cvarAnnounce = INVALID_HANDLE;
new Handle:Allowed = INVALID_HANDLE;
new Handle:AllowedDie = INVALID_HANDLE;
new Handle:AllowedDieBleedOut = INVALID_HANDLE;
new Handle:AllowedDieRealism = INVALID_HANDLE;
new Handle:AllowedDieLastGnome = INVALID_HANDLE;
new Handle:DebugEvent = INVALID_HANDLE;
new Handle:DefM;
new Handle:CheckRoundCounter;
new Handle:ChDelayVS;
new Handle:ChDelayRSVS;
new Handle:ChDelayCOOP;
new Handle:ChDelayLastGnomeOnEarth;
new Handle:ChDelayBleedOut;
new Handle:ChDelayCoopRealism;
new Handle:TimerRoundEndBlockVS;
new Handle:TimerRoundEndBlockRSVS;

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

	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_win", Event_FinalWin);
	HookEvent("mission_lost", Event_FinalLost);
	
	CreateConVar("sm_l4d_fmc_version", Version, "Version of L4D1/2 Force Mission Changer plugin.", FCVAR_NOTIFY);
	DebugEvent = CreateConVar("sm_l4d_fmc_dbug", "0", "on-off Write event to log file.");
	Allowed = CreateConVar("sm_l4d_fmc", "1", "Enables Force changelevel when mission end.");
	AllowedDie = CreateConVar("sm_l4d_fmc_ifdie", "1", "Enables Force changelevel when all player die on final map in coop gamemode.");
        AllowedDieBleedOut = CreateConVar("sm_l4d_fmc_ifdie_realism", "1", "Enables Force changelevel when all player die on final map in coop realism.");
        AllowedDieRealism = CreateConVar("sm_l4d_fmc_ifdie_bleedout", "1", "Enables Force changelevel when all player die on final map in Bleed Out gamemode.");
        AllowedDieLastGnome = CreateConVar("sm_l4d_fmc_ifdie_lastgnome", "1", "Enables Force changelevel when all player die on final map in Last Gnome On Earth gamemode.");		
        DefM = CreateConVar("sm_l4d_fmc_def", "l4d_vs_hospital01_apartment", "Mission for change by default.");
	CheckRoundCounter = CreateConVar("sm_l4d_fmc_crec", "4", "Quantity of events RoundEnd before force of changelevel in versus: 4 for l4d <> 1.0.1.2");
	
        ChDelayVS = CreateConVar("sm_l4d_fmc_chdelayvs", "0.0", "Delay before versus/teamversus mission change (float in sec).");
        ChDelayRSVS = CreateConVar("sm_l4d_fmc_chdelayrsvs", "0.0", "Delay before realism versus mission change (float in sec).");
	ChDelayCOOP = CreateConVar("sm_l4d_fmc_chdelaycoop", "0.0", "Delay before coop/coop realism mission change (float in sec).");
        ChDelayLastGnomeOnEarth = CreateConVar("sm_l4d_fmc_chdelaylast_gnome_on_earth", "0.0", "Delay before last gnome on earth mission change (float in sec).");
        ChDelayBleedOut = CreateConVar("sm_l4d_fmc_chdelaybleedout", "0.0", "Delay before bleed out mission change (float in sec).");
        ChDelayCoopRealism = CreateConVar("sm_l4d_fmc_chcooprealism", "0.0", "Delay before coop realism mission change (float in sec).");

	TimerRoundEndBlockVS = CreateConVar("sm_l4d_fmc_re_timer_block", "0.5", "Time in which current event round_end is not considered (float in sec).");
        TimerRoundEndBlockRSVS = CreateConVar("sm_l4d_fmc_re_timer_block_rsvs", "0.5", "Time in which current event round_end is not considered (float in sec).");
	cvarAnnounce = CreateConVar("sm_l4d_fmc_announce", "1", "Enables next mission to advertise to players.");

	CurrentGameMode = FindConVar("mp_gamemode");
	HookConVarChange(CurrentGameMode, OnCVGameModeChange);

	logfile = OpenFile("/addons/sourcemod/logs/fmc_event.log", "w");
}

public OnMapStart()
{
        // Execute the config file
	AutoExecConfig(true, "sm_l4d_mapchanger");

	RoundEndCounter = 0;
	RoundEndBlock = 0;

	if (GetConVarInt(DebugEvent) == 1)	
		WriteFileLine(logfile, "***New map start***");

	if(GetConVarInt(Allowed) == 1)
	{
		PluginInitialization();
        }
}

public OnMapEnd()
{
	if (GetConVarInt(DebugEvent) == 1)
	{
		FlushFile(logfile);
		WriteFileLine(logfile, "***Map end***");
	}
}

public OnClientPutInServer(client)
{
	// Make the announcement in 25 seconds unless announcements are turned off
	if(client && !IsFakeClient(client) && GetConVarBool(cvarAnnounce))
		CreateTimer(25.0, TimerAnnounce, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (RoundEndBlock == 0)
	{
		RoundEndCounter += 1;
		RoundEndBlock = 1;
		CreateTimer(GetConVarFloat(TimerRoundEndBlockVS), TimerRoundEndBlock, TIMER_FLAG_NO_MAPCHANGE);
	}

        if (RoundEndBlock == 0)
	{
		RoundEndCounter += 1;
		RoundEndBlock = 1;
		CreateTimer(GetConVarFloat(TimerRoundEndBlockRSVS), TimerRoundEndBlock, TIMER_FLAG_NO_MAPCHANGE);
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

		CreateTimer(GetConVarFloat(ChDelayRSVS), TimerChDelayRSVS, TIMER_FLAG_NO_MAPCHANGE);
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
		CreateTimer(GetConVarFloat(ChDelayBleedOut), TimerChDelayBleedOut, TIMER_FLAG_NO_MAPCHANGE);

        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 7 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCoopRealism), TimerChDelayCoopRealism, TIMER_FLAG_NO_MAPCHANGE);
  
        if(GetConVarInt(Allowed) == 1 && l4d_gamemode() == 8 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayLastGnomeOnEarth), TimerChDelayLastGnome, TIMER_FLAG_NO_MAPCHANGE);
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

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDieBleedOut) && l4d_gamemode() == 5 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayBleedOut), TimerChDelayBleedOut, TIMER_FLAG_NO_MAPCHANGE);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDieRealism) && l4d_gamemode() == 7 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCoopRealism), TimerChDelayCoopRealism, TIMER_FLAG_NO_MAPCHANGE);

        if(GetConVarInt(Allowed) == 1 && GetConVarInt(AllowedDieLastGnome) && l4d_gamemode() == 8 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayLastGnomeOnEarth), TimerChDelayLastGnome, TIMER_FLAG_NO_MAPCHANGE);
}

public OnCVGameModeChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	//If game mode actually changed
	if (strcmp(oldValue, newValue) != 0)
	{
		new GameMode = l4d_gamemode();
		if (GameMode == 1 || GameMode == 2 || GameMode == 3 || GameMode == 4 || GameMode == 5 || GameMode == 6 || GameMode == 7 || GameMode == 8)
		{
			HookEvent("round_end", Event_RoundEnd);
			HookEvent("finale_win", Event_FinalWin);
			HookEvent("mission_lost", Event_FinalLost);
		}
        }   

        if(GetConVarInt(Allowed) == 1)
		PluginInitialization();    
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

public Action:TimerChDelayRSVS(Handle:timer)
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

public Action:TimerChDelayBleedOut(Handle:timer)
{
	ServerCommand("changelevel %s", next_mission_force);
}

public Action:TimerChDelayScavenge(Handle:timer)
{
	ServerCommand("changelevel %s", next_mission_force);
}

public Action:TimerChDelayLastGnome(Handle:timer)
{
        ServerCommand("changelevel %s", next_mission_force);
}

public Action:TimerChDelayCoopRealism(Handle:timer)
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
	else
	{
		return false;
	}
}

ClearKV(Handle:kvhandle)
{
	KvRewind(kvhandle);
	if (KvGotoFirstSubKey(kvhandle))
	{
		do
		{
			KvDeleteThis(kvhandle);
			KvRewind(kvhandle);
		}
		while (KvGotoFirstSubKey(kvhandle));
		KvRewind(kvhandle);
	}
}

PluginInitialization()
{
	ClearKV(hKVSettings);
	new GameMode = l4d_gamemode();
	if (GameMode == 1)
	{
		BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4dco_mapchanger.txt");
		PrintToServer("[FMC] Discovered Coop gamemode. Link to sm_l4dco_mapchanger.");
	}
	else if (GameMode == 2)
	{
		BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4dvs_mapchanger.txt");
		PrintToServer("[FMC] Discovered Versus gamemode. Link to sm_l4dvs_mapchanger.");
	}
        else if (GameMode == 3)
	{
		BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4dvs_mapchanger.txt");
		PrintToServer("[FMC] Discovered Versus Realism gamemode. Link to sm_l4dvs_mapchanger.");
	}
	else if (GameMode == 4)
	{
		SetConVarInt(Allowed, 0);
		PrintToServer("[FMC] Discovered Survival gamemode. Plugin stop activity. Wait for coop or versus.");
		return;
	}
        else if (GameMode == 5)
	{
		BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4dbleedout_mapchanger.txt");
		PrintToServer("[FMC] Discovered Bleed Out gamemode. Link to sm_l4dbleedout_mapchanger.");
	}
        else if (GameMode == 6)
	{
		BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4dvs_mapchanger.txt");
		PrintToServer("[FMC] Discovered Team Versus gamemode. Link to sm_l4dvs_mapchanger.");
	}
        else if (GameMode == 7)
	{
		BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4dco_mapchanger.txt");
		PrintToServer("[FMC] Discovered Coop Realism gamemode. Link to sm_l4dco_mapchanger.");
	}
        else if (GameMode == 8)
	{
		BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4dlastgnome_mapchanger.txt");
		PrintToServer("[FMC] Discovered Last Gnome On Earth gamemode. Link to sm_l4dlastgnome_mapchanger.");
	}

        if(!FileToKeyValues(hKVSettings, FMC_FileSettings))
		SetFailState("Force Mission Changer settings not found! Shutdown.");

        next_mission_force = "none";
	GetCurrentMap(current_map, 64);
	GetConVarString(DefM, next_mission_def, 64);

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
        }
}
