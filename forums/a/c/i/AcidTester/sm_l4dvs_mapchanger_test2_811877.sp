/**
* L4D Force Mission Changer
* For Sourcemod 1.2.0
*/

#pragma semicolon 1
#include <sourcemod>
#define Version "1.2"

new Handle:cvarAnnounce = INVALID_HANDLE;
new Handle:Allowed = INVALID_HANDLE;
new Handle:AllowedDie = INVALID_HANDLE;
new Handle:DefM;
new Handle:CheckRoundCounter;
new String:gmode[64] = "";
new Handle:ChDelayVS;
new Handle:ChDelayCOOP;
new Handle:hKVSettings = INVALID_HANDLE;
new String:FMC_FileSettings[128];
new String:current_map[64];
new String:next_mission_def[64];
new String:next_mission_force[64] = "none";
new RoundEndCounter = 0;

public Plugin:myinfo = 
{
	name = "L4D Force Mission Changer",
	author = "Dionys",
	description = "Force change to next mission when current mission end.",
	version = Version,
	url = "skiner@inbox.ru"
};

public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));

	if(!StrEqual(ModName, "left4dead", false))
		SetFailState("Use this Left 4 Dead only.");

	hKVSettings=CreateKeyValues("ForceMissionChangerSettings");
  	BuildPath(Path_SM, FMC_FileSettings, 128, "data/sm_l4dvs_mapchanger.txt");
	if(!FileToKeyValues(hKVSettings, FMC_FileSettings))
		SetFailState("Force Mission Changer settings not found!");

	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_win", Event_FinalWin);
	HookEvent("mission_lost", Event_FinalLost);

	CreateConVar("sm_l4d_fmc_version", Version, "Version of L4D Force Mission Changer plugin.", FCVAR_NOTIFY);
	//gmode = FindConVar("mp_gamemode");
	Allowed = CreateConVar("sm_l4d_fmc", "1", "Enables Force changelevel when mission end.");
	AllowedDie = CreateConVar("sm_l4d_fmc_ifdie", "1", "Enables Force changelevel when all player die on final map in coop gamemode.");
	DefM = CreateConVar("sm_l4d_fmc_def", "l4d_vs_hospital01_apartment", "Mission for change by default.");
	CheckRoundCounter = CreateConVar("sm_l4d_fmc_crec", "4", "Quantity of events RoundEnd before force of changelevel: 4 - versus.");
	ChDelayVS = CreateConVar("sm_l4d_fmc_chdelayvs", "0.0", "Delay before versus mission change in sec.");
	ChDelayCOOP = CreateConVar("sm_l4d_fmc_chdelaycoop", "0.0", "Delay before coop mission change in sec.");
	cvarAnnounce = CreateConVar("sm_l4d_fmc_announce", "1", "Enables next mission to advertise to players.");

	// Execute the config file
	AutoExecConfig(true, "sm_l4dvs_mapchanger");
}

public OnMapStart()
{
	RoundEndCounter = 0;

	if(GetConVarInt(Allowed))
	{
		GetConVarString(FindConVar("mp_gamemode"), gmode, 64);
		next_mission_force = "none";
		GetCurrentMap(current_map, 64);
		GetConVarString(DefM, next_mission_def, 64);

		KvRewind(hKVSettings);
		if(KvJumpToKey(hKVSettings, current_map))
			KvGetString(hKVSettings, "next mission map", next_mission_force, 64, next_mission_def);

		if (StrEqual(next_mission_force, "none") != true)
		{
			if (!IsMapValid(next_mission_force))
				next_mission_force = next_mission_def;
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
	if(GetConVarInt(Allowed) && StrContains(gmode, "versus", false) != -1 && StrContains(current_map, "05", false) != -1)
	{
		RoundEndCounter += 1;

		if (RoundEndCounter == GetConVarInt(CheckRoundCounter))
			CreateTimer(GetConVarFloat(ChDelayVS), TimerChDelayVS);
	}
}
/*--------------------------------------
public OnMapEnd()
{
	//GetCurrentMap(current_map, sizeof(current_map));
	if(GetConVarInt(Allowed) && GetConVarInt(CurrentGameMode) == 0 && StrContains(current_map, "05", false) != -1)
		//CreateTimer(GetConVarFloat(ChDelayVS), TimerChDelayVS);
		CreateTimer(10.0, TimerChDelayVS);
		//ServerCommand("changelevel %s", next_mission_force);
}
------------------------------------------*/
public Action:Event_FinalWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Allowed) && StrContains(gmode, "coop", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);
}

public Action:Event_FinalLost(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Allowed) && GetConVarInt(AllowedDie) && StrContains(gmode, "coop", false) != -1 && StrEqual(next_mission_force, "none") != true)
		CreateTimer(GetConVarFloat(ChDelayCOOP), TimerChDelayCOOP);
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if (StrEqual(next_mission_force, "none") != true)
			PrintToChat(client, "\x04[SM]\x03 Next mission map - \x04%s.", next_mission_force);
		else
			PrintToChat(client, "\x04[SM]\x03 Next mission map not selected.");
	}
}

public Action:TimerChDelayVS(Handle:timer)
{
	ServerCommand("changelevel %s", next_mission_force);
}

public Action:TimerChDelayCOOP(Handle:timer)
{
	ServerCommand("changelevel %s", next_mission_force);
}
