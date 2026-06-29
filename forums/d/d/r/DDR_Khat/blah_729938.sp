/**
* L4D Force Mission Changer
* For Sourcemod 1.2.0
*/

#pragma semicolon 1
#include <sourcemod>
#define Version "1.0"
#define MAX_FILE_LEN 128

new Handle:cvarAnnounce = INVALID_HANDLE;
new Handle:Allowed = INVALID_HANDLE;
new Handle:DefM;
new Handle:hKVSettings = INVALID_HANDLE;
new String:FMC_FileSettings[MAX_FILE_LEN];
new RoundEndCounter = 0;
new String:current_map[64];
new String:next_mission_def[64];
new String:next_mission_force[64] = "none";

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

	if(!StrEqual(ModName, "left4dead", false)) SetFailState("Use this Left 4 Dead only.");

	hKVSettings=CreateKeyValues("ForceMissionChangerSettings");
  	BuildPath(Path_SM, FMC_FileSettings, MAX_FILE_LEN, "data/sm_l4dvs_mapchanger.txt");
	if(!FileToKeyValues(hKVSettings, FMC_FileSettings)) SetFailState("Force Mission Changer settings not found!");

	HookEvent("round_end", Event_RoundEnd);

	CreateConVar("sm_l4d_fmc_version", Version, "Version of L4D Force Mission Changer plugin.", FCVAR_NOTIFY);
	Allowed = CreateConVar("sm_l4d_fmc", "1", "Enables Force changelevel when mission end.");
	DefM = CreateConVar("sm_l4d_fmc_def", "l4d_vs_hospital01_apartment", "Mission for change by default.");
	cvarAnnounce = CreateConVar("sm_l4d_fmc_announce", "1", "Enables next mission to advertise to players.");

	// Execute the config file
	AutoExecConfig(true, "sm_l4dvs_mapchanger");
}

public OnMapStart()
{
	RoundEndCounter = 0;
	next_mission_force = "none";

	if(GetConVarInt(Allowed))
	{
		GetCurrentMap(current_map, 64);
		GetConVarString(DefM, next_mission_def, 64);

		KvRewind(hKVSettings);
		if(KvJumpToKey(hKVSettings, current_map)) KvGetString(hKVSettings, "next mission map", next_mission_force, 64, next_mission_def);

		if (StrEqual(next_mission_force, "none") != true&&!IsMapValid(next_mission_force)) next_mission_force = next_mission_def;
	}
}

public OnClientPutInServer(client)
{
	if(client && !IsFakeClient(client)&&GetConVarBool(cvarAnnounce)) CreateTimer(20.0, TimerAnnounce, client);

}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Allowed)&&StrEqual(next_mission_force, "none") != true)
	{
		RoundEndCounter += 1;

		if (RoundEndCounter == 4)
		{
			for (new player=1; player<=GetMaxClients(); player++)
			{
				if (IsClientInGame(player) && IsFakeClient(player))
				{
						ServerCommand("kick %s", player);
				}
			}
			ServerCommand("changelevel %s", next_mission_force);
		}
	}
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if (StrEqual(next_mission_force, "none") != true)
		{
			PrintToChat(client, "\x04[SM]\x03 Next mission map - \x04%s.", next_mission_force);
		}
		else
		{
			PrintToChat(client, "\x04[SM]\x03 Next mission map not selected.");
		}
	}
}
