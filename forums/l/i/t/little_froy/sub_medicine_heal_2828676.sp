#define PLUGIN_VERSION	"1.3"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
native int Heartbeat_GetRevives(int client); 
native void Heartbeat_SetRevives(int client, int reviveCount, bool reviveLogic = true);

#define SOUND_HEARTBEAT	"player/heartbeatloop.wav"

public Plugin myinfo =
{
	name = "Sub Medicine Heal",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=349321"
};

GlobalForward Forward_OnReducedByPills;
GlobalForward Forward_OnReducedByAdrenaline;

bool Lib_l4d_heartbeat;

ConVar C_revive_count_reduce_pills;
int O_revive_count_reduce_pills;
ConVar C_revive_count_reduce_adrenaline;
int O_revive_count_reduce_adrenaline;
ConVar C_min_revive_count_pills;
ConVar C_min_revive_count_adrenaline;
int O_min_revive_count_pills;
int O_min_revive_count_adrenaline;

public void OnLibraryAdded(const char[] name)
{
	if(strcmp(name, "l4d_heartbeat") == 0)
    {
        Lib_l4d_heartbeat = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
	if(strcmp(name, "l4d_heartbeat") == 0)
    {
        Lib_l4d_heartbeat = false;
    }
}

public void OnMapStart()
{
    PrecacheSound(SOUND_HEARTBEAT, true);
}

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool is_player_on_thirdstrike(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike");
}

void reduce_revive_count(int userid, int reduce, int min, GlobalForward handle)
{
    int client = GetClientOfUserId(userid);
    if(client > 0 && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_player_alright(client))
    {
        int revived = 0;
        if(Lib_l4d_heartbeat)
        {
            revived = Heartbeat_GetRevives(client);
        }
        else
        {
            revived = GetEntProp(client, Prop_Send, "m_currentReviveCount");
        }
        int updated = revived - reduce;
        if(updated < min)
        {
            updated = min;
        }
        if(updated >= revived)
        {
            return;
        }
        if(Lib_l4d_heartbeat)
        {
            Heartbeat_SetRevives(client, updated, false);
        }
        else
        {
            SetEntProp(client, Prop_Send, "m_currentReviveCount", updated);
        }
        bool thirdstrike = is_player_on_thirdstrike(client);
        if(thirdstrike)
        {
            SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
            StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
        }
        Call_StartForward(handle);
        Call_PushCell(client);
        Call_PushCell(revived);
        Call_PushCell(updated);
        Call_PushCell(revived - updated);
        Call_PushCell(thirdstrike);
        Call_Finish();
    }
}

void event_pills_used(Event event, const char[] name, bool dontBroadcast)
{
    if(O_revive_count_reduce_pills < 1)
    {
        return;
    }
    reduce_revive_count(event.GetInt("userid"), O_revive_count_reduce_pills, O_min_revive_count_pills, Forward_OnReducedByPills);
}

void event_adrenaline_used(Event event, const char[] name, bool dontBroadcast)
{
    if(O_revive_count_reduce_adrenaline < 1)
    {
        return;
    }
    reduce_revive_count(event.GetInt("userid"), O_revive_count_reduce_adrenaline, O_min_revive_count_adrenaline, Forward_OnReducedByAdrenaline);
}

void get_all_cvars()
{
    O_revive_count_reduce_pills = C_revive_count_reduce_pills.IntValue;
    O_revive_count_reduce_adrenaline = C_revive_count_reduce_adrenaline.IntValue;
    O_min_revive_count_pills = C_min_revive_count_pills.IntValue;
    O_min_revive_count_adrenaline = C_min_revive_count_adrenaline.IntValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_revive_count_reduce_pills)
    {
        O_revive_count_reduce_pills = C_revive_count_reduce_pills.IntValue;
    }
    else if(convar == C_revive_count_reduce_adrenaline)
    {
        O_revive_count_reduce_adrenaline = C_revive_count_reduce_adrenaline.IntValue;
    }
    else if(convar == C_min_revive_count_pills)
    {
        O_min_revive_count_pills = C_min_revive_count_pills.IntValue;
    }
    else if(convar == C_min_revive_count_adrenaline)
    {
        O_min_revive_count_adrenaline = C_min_revive_count_adrenaline.IntValue;
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
	MarkNativeAsOptional("Heartbeat_GetRevives");
	MarkNativeAsOptional("Heartbeat_SetRevives");
	Forward_OnReducedByPills = new GlobalForward("SubMedicineHeal_OnReducedByPills", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
    Forward_OnReducedByAdrenaline = new GlobalForward("SubMedicineHeal_OnReducedByAdrenaline", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	RegPluginLibrary("sub_medicine_heal");
    return APLRes_Success;
}

public void OnPluginStart()
{
    HookEvent("pills_used", event_pills_used);
    HookEvent("adrenaline_used", event_adrenaline_used);

    C_revive_count_reduce_pills = CreateConVar("sub_medicine_heal_revive_count_reduce_pills", "1", "how many revive count will reduce after using pain pills. 0 = disable", _, true, 0.0);
    C_revive_count_reduce_pills.AddChangeHook(convar_changed);
    C_revive_count_reduce_adrenaline = CreateConVar("sub_medicine_heal_revive_count_reduce_adrenaline", "1", "how many revive count will reduce after using adrenaline. 0 = disable", _, true, 0.0);
    C_revive_count_reduce_adrenaline.AddChangeHook(convar_changed);
    C_min_revive_count_pills = CreateConVar("sub_medicine_heal_min_revive_count_pills", "1", "minimum revive count can reduce to after using pain pills", _, true, 0.0);
    C_min_revive_count_pills.AddChangeHook(convar_changed);
    C_min_revive_count_adrenaline = CreateConVar("sub_medicine_heal_min_revive_count_adrenaline", "1", "minimum revive count can reduce to after using adrenaline", _, true, 0.0);
    C_min_revive_count_adrenaline.AddChangeHook(convar_changed);
    CreateConVar("sub_medicine_heal_version", PLUGIN_VERSION, "version of Sub Medicine Heal", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    //AutoExecConfig(true, "sub_medicine_heal");
    get_all_cvars();
}
