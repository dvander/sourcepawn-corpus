#define PLUGIN_VERSION	"1.3"

#define DEBUG 0

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "c7m3 Finale Stuck Fix",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351981"
};

bool Valid_Map;
int Tank_count;
int Tank_max;
Handle H_next_stage;

ConVar C_delay;
float O_delay;

public void OnMapInit(const char[] mapName)
{
    if(strcmp(mapName, "c7m3_port") == 0)
    {
        Valid_Map = true;
    }
}

public void OnMapEnd()
{
    if(!Valid_Map)
    {
        return;
    }
    Valid_Map = false;
    reset_all();
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if(!Valid_Map)
    {
        return;
    }
    if(entity < 1)
    {
        return;
    }
    if(strcmp(classname, "func_button_timed") == 0)
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost_func_button_timed);
    }
}

void OnSpawnPost_func_button_timed(int entity)
{
    char name[64];
    GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
    if(strncmp(name, "finale_start_button", 19) == 0)
    {
        HookSingleEntityOutput(entity, "OnTimeUp", OnTimeUp);
    }
}

void OnTimeUp(const char[] output, int caller, int activator, float delay)
{
    #if DEBUG
    PrintToChatAll("%f按钮按下，创建计时器等待", GetGameTime());
    #endif
    Tank_max++;
    delete H_next_stage;
    H_next_stage = CreateTimer(O_delay, timer_next);
}

void reset_all()
{
    Tank_count = 0;
    Tank_max = 0;
    delete H_next_stage;
}

void timer_next(Handle timer)
{
    H_next_stage = null;
    for(int stage = L4D2_GetCurrentFinaleStage(); !(stage == FINALE_HORDE_ESCAPE || stage == FINALE_CUSTOM_TANK); stage = L4D2_GetCurrentFinaleStage())
    {
        L4D2_ForceNextStage();
    }
    #if DEBUG
    PrintToChatAll("%f强制跳关", GetGameTime());
    #endif
}

void event_tank_killed(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_Map)
    {
        return;
    }
    if(Tank_max < 1)
    {
        return;
    }
    delete H_next_stage;
    if(Tank_count < Tank_max)
    {
        #if DEBUG
        PrintToChatAll("%f坦克死亡，创建计时器等待", GetGameTime());
        #endif
        H_next_stage = CreateTimer(O_delay, timer_next);
    }
}

void event_tank_spawn(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_Map)
    {
        return;
    }
    if(Tank_max < 1)
    {
        return;
    }
    Tank_count++;
    if(Tank_count >= 3 && Tank_max >= 3)
    {
        Tank_max = -1;
    }
    #if DEBUG
    PrintToChatAll("%f坦克出生，停止计时器", GetGameTime());
    #endif
    delete H_next_stage;
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_Map)
    {
        return;
    }
    reset_all();
}

void get_all_cvars()
{
    O_delay = C_delay.FloatValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_delay)
    {
        O_delay = C_delay.FloatValue;
    }
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
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
    HookEvent("tank_killed", event_tank_killed);
    HookEvent("tank_spawn", event_tank_spawn);
    HookEvent("round_start", event_round_start);

    C_delay = CreateConVar("c7m3_finale_stuck_fix_delay", "10.0", "delay to force next finale stage", _, true, 0.1);
    C_delay.AddChangeHook(convar_changed);
    CreateConVar("c7m3_finale_stuck_fix_version", PLUGIN_VERSION, "version of c7m3 Finale Stuck Fix", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	//AutoExecConfig(true, "c7m3_finale_stuck_fix");
	get_all_cvars();
}
