#define PLUGIN_VERSION  "1.4"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "c7m3 Sacrifice Finale Remove Ex",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=350954"
};

bool Valid_map;

bool Started;

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

public void OnMapInit(const char[] mapName)
{
    if(strcmp(mapName, "c7m3_port") != 0)
    {
        return;
    }
    Valid_map = true;
    for(int i = 0; i < EntityLump.Length(); i++)
    {
        EntityLumpEntry entry = EntityLump.Get(i);
        int finale_key = entry.FindKey("IsSacrificeFinale");
        if(finale_key != -1)
        {
            entry.Update(finale_key, .value = "0");
            delete entry;
            return;
        }
        delete entry;
    }
}

public void OnMapEnd()
{
    if(!Valid_map)
    {
        return;
    }
    Valid_map = false;
    Started = false;
}

public void OnClientDisconnect_Post(int client)
{
    if(!Valid_map)
    {
        return;
    }
    RequestFrame(frame_check);
}

void frame_check()
{
    if(!Started)
    {
        return;
    }
    bool got = false;
    int count = 0;
    int alright = 0;
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client) && GetClientTeam(client) == 2)
        {
            got = true;
            if(IsPlayerAlive(client))
            {
                count++;
                if(is_player_alright(client))
                {
                    alright++;
                }
            }
        }
    }
    if(!got || (alright > 0 && count > 1))
    {
        return;
    }
    restart_round();
    BfWrite msg = view_as<BfWrite>(StartMessageAll("VGUIMenu", USERMSG_RELIABLE));
    msg.WriteString("info_window");
    msg.WriteByte(1);
    msg.WriteByte(1);
    msg.WriteString("res");
    msg.WriteString("resource/ui/riverfinalefailed.res");
    EndMessage();
}

void rescue_all()
{
    int rescue = -1;
    while((rescue = FindEntityByClassname(rescue, "info_survivor_rescue")) != -1)
    {
        AcceptEntityInput(rescue, "Rescue");
    }
}

void event_finale_start(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_map)
    {
        return;
    }
    rescue_all();
    Started = true;
    RequestFrame(frame_check);
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_map)
    {
        return;
    }
    Started = false;
}

void event_round_end(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_map)
    {
        return;
    }
    Started = false;
}

void event_map_transition(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_map)
    {
        return;
    }
    Started = false;
}

void event_mission_lost(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_map)
    {
        return;
    }
    Started = false;
}

void event_finale_vehicle_leaving(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_map)
    {
        return;
    }
    Started = false;
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_map)
    {
        return;
    }
    RequestFrame(frame_check);
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_map)
    {
        return;
    }
    RequestFrame(frame_check);
}

void event_player_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_map)
    {
        return;
    }
    RequestFrame(frame_check);
}

void event_player_ledge_grab(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_map)
    {
        return;
    }
    RequestFrame(frame_check);
}

void restart_round()
{
	int flag = GetCommandFlags("scenario_end");
	SetCommandFlags("scenario_end", flag & ~(FCVAR_CHEAT | FCVAR_DEVELOPMENTONLY));
	ServerCommand("scenario_end");
	ServerExecute();
	SetCommandFlags("scenario_end", flag);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    HookEvent("round_start", event_round_start);
    HookEvent("round_end", event_round_end);
	HookEvent("map_transition", event_map_transition);
	HookEvent("mission_lost", event_mission_lost);
	HookEvent("finale_vehicle_leaving", event_finale_vehicle_leaving);
    HookEvent("player_death", event_player_death);
    HookEvent("player_team", event_player_team);
	HookEvent("player_incapacitated", event_player_incapacitated);
	HookEvent("player_ledge_grab", event_player_ledge_grab);
    HookEvent("finale_start", event_finale_start);

	CreateConVar("c7m3_sacrifice_finale_remove_ex_version", PLUGIN_VERSION, "version of c7m3 Sacrifice Finale Remove Ex", FCVAR_NOTIFY | FCVAR_DONTRECORD);
}
