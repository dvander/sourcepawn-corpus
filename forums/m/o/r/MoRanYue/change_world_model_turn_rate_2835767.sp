#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0"

ConVar world_model_turn_rate;

ConVar face_front_time;
ConVar feet_max_yaw_rate;
ConVar feet_yaw_rate;
ConVar feet_yaw_rate_max;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    if (GetEngineVersion() != Engine_Left4Dead2) {
        strcopy(error, err_max, "This plugin only supports Left 4 Dead 2");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public Plugin myinfo = {
    name = "[L4D2] Change world model turn rate",
    author = "Lux, MoRanYue",
    description = "By default restores l4d1 world model turnrate.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2641104"
};

public void OnPluginStart() {
    CreateConVar("cwmtr_version", PLUGIN_VERSION, "Change world model turn rate version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
    world_model_turn_rate = CreateConVar("world_model_turn_rate", "2160", "Speed at which world model turns to match view model pitch angle, default L4D1 speed is 100, default of 2160 closely matches it", _, true, 1.0);
    face_front_time = FindConVar("mp_facefronttime");
    feet_max_yaw_rate = FindConVar("mp_feetmaxyawrate");
    feet_yaw_rate = FindConVar("mp_feetyawrate");
    feet_yaw_rate_max = FindConVar("mp_feetyawrate_max");
    AutoExecConfig(true, "cwmtr");

    world_model_turn_rate.AddChangeHook(OnCvarChange);
    
    SetWorldModelTrunRate();
}

public Action L4D_OnCThrowActivate(int ability) {
    ResetWorldModelTrunRate();
    return Plugin_Continue;

}
public Action L4D_TankRock_OnRelease(int tank, int rock, float vecPos[3], float vecAng[3], float vecVel[3], float vecRot[3]) {
    SetWorldModelTrunRate();
    return Plugin_Continue;
}

public void OnCvarChange(ConVar convar, const char[] oldValue, const char[] newValue) {
    SetWorldModelTrunRate();
}

void SetWorldModelTrunRate() {
    int turn_rate = world_model_turn_rate.IntValue;
    face_front_time.SetInt(-1, true, false);
    feet_max_yaw_rate.SetInt(turn_rate, true, false);
    feet_yaw_rate.SetInt(turn_rate, true, false);
    feet_yaw_rate_max.SetInt(turn_rate, true, false);
}

void ResetWorldModelTrunRate() {
    face_front_time.RestoreDefault(true, false);
    feet_max_yaw_rate.RestoreDefault(true, false);
    feet_yaw_rate.RestoreDefault(true, false);
    feet_yaw_rate_max.RestoreDefault(true, false);
}