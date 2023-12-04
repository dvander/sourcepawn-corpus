#define PLUGIN_VERSION  "2.8"
#define PLUGIN_NAME     "Thirdstrike Tip"
#define PLUGIN_PREFIX	"thirdstrike_tip"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=342360"
};

ConVar C_model;
char O_model[PLATFORM_MAX_PATH];
ConVar C_pos;
float O_pos[3];
ConVar C_ang;
float O_ang[3];
ConVar C_scale;
float O_scale;
ConVar C_bone;
char O_bone[PLATFORM_MAX_PATH];
ConVar C_render_fx;
RenderFx O_render_fx;
ConVar C_pulse_duration;
float O_pulse_duration;
ConVar C_pulse_interval;
float O_pulse_interval;

float Next_change_time = -1.0;
bool Show;
bool Should_change;

int Tip[MAXPLAYERS+1] = {-1, ...};
int Wall[MAXPLAYERS+1] = {-1, ...};

bool is_survivor_on_thirdstrike(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike");
}

Action set_transmit(int entity, int client)
{
    if(!Show)
    {
        return Plugin_Handled;
    }
    int ref = EntIndexToEntRef(entity);
    if(ref == Tip[client])
    {
        return Plugin_Handled;
    }
    if(!IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_iObserverMode") == 4)
    {
		int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		if(target != client && target > 0 && target <= MaxClients && ref == Tip[target])
		{
			return Plugin_Handled;
		}
    }
    return Plugin_Continue;
}

void set_tip(int client)
{
    if(Tip[client] == -1)
    {
        int entity = CreateEntityByName("prop_dynamic_override");
        if(entity == -1)
        {
            return;
        }
        int target = CreateEntityByName("info_target");
        if(target == -1)
        {
            RemoveEntity(entity);
            return;
        }
        DispatchSpawn(target);
        if(!IsModelPrecached(O_model))
        {
            PrecacheModel(O_model, true);
        }
        SetEntityModel(entity, O_model);
        DispatchSpawn(entity);
        SetEntPropFloat(entity, Prop_Send, "m_flModelScale", O_scale);
        SetVariantString("!activator");
        AcceptEntityInput(entity, "SetParent", target);
        TeleportEntity(target, O_pos);
        SetVariantString("!activator");
        AcceptEntityInput(target, "SetParent", client);
        SetVariantString(O_bone);
        AcceptEntityInput(target, "SetParentAttachment");
        TeleportEntity(target, O_pos);
        AcceptEntityInput(entity, "DisableShadow");
        AcceptEntityInput(entity, "DisableCollision");
        SetEntProp(entity, Prop_Send, "m_noGhostCollision", 1);
        SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0x0004);
        SetEntPropVector(entity, Prop_Send, "m_vecMins", view_as<float>({0.0, 0.0, 0.0}));
        SetEntPropVector(entity, Prop_Send, "m_vecMaxs", view_as<float>({0.0, 0.0, 0.0}));
        TeleportEntity(target, O_pos, O_ang);
        SetEntProp(entity, Prop_Data, "m_iEFlags", 0);
        SetEntityRenderFx(entity, O_render_fx);
        Tip[client] = EntIndexToEntRef(entity);
        Wall[client] = EntIndexToEntRef(target);
        SDKHook(entity, SDKHook_SetTransmit, set_transmit);
    }
}

void remove_ref(int& ref)
{
    int entity = EntRefToEntIndex(ref);
    if(entity != -1)
    {
        RemoveEntity(entity);
    }
    ref = -1;
}

void reset_tip(int client)
{
    if(Tip[client] != -1)
    {
        remove_ref(Tip[client]);
        remove_ref(Wall[client]);
    }
}

public void OnGameFrame()
{
    if(Should_change && GetEngineTime() >= Next_change_time)
    {
        if(Show)
        {
            Show = false;
            Next_change_time = GetEngineTime() + O_pulse_interval;
        }
        else
        {
            Show = true;
            Next_change_time = GetEngineTime() + O_pulse_duration;
        }
    }
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if(GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_on_thirdstrike(client))
    {
        set_tip(client);
    }
    else
    {
        reset_tip(client);
    }
}

public void OnClientDisconnect_Post(int client)
{
    reset_tip(client);
}

void reset_all()
{
    for(int client = 1; client <= MAXPLAYERS; client++)
    {
        reset_tip(client);
    }
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    reset_all();
}

void get_cvars()
{
    C_model.GetString(O_model, sizeof(O_model));
    char cvar_pos[48];
    char get_pos[3][16];
    char cvar_ang[48];
    char get_ang[3][16];
    C_pos.GetString(cvar_pos, sizeof(cvar_pos));
    C_ang.GetString(cvar_ang, sizeof(cvar_ang));
    ExplodeString(cvar_pos, " ", get_pos, 3, 16);
    ExplodeString(cvar_ang, " ", get_ang, 3, 16);
    for(int i = 0; i < 3; i++)
    {
        O_pos[i] = StringToFloat(get_pos[i]);
        O_ang[i] = StringToFloat(get_ang[i]);
    }
    O_scale = C_scale.FloatValue;
    C_bone.GetString(O_bone, sizeof(O_bone));
    O_render_fx = view_as<RenderFx>(C_render_fx.IntValue);
    O_pulse_duration = C_pulse_duration.FloatValue;
    O_pulse_interval = C_pulse_interval.FloatValue;

    Should_change = O_pulse_duration > 0.0 && O_pulse_interval > 0.0;
    Show = true;
    Next_change_time = -1.0;

    reset_all();
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_cvars();
}

public void OnConfigsExecuted()
{
	get_cvars();
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

    C_model = CreateConVar(PLUGIN_PREFIX ... "_model", "models/props_interiors/medicalcabinet02.mdl", "model of the tip");
    C_model.AddChangeHook(convar_changed);
    C_pos = CreateConVar(PLUGIN_PREFIX ... "_pos", "1.0 0.0 -13.0", "position of the tip, split up with space");
    C_pos.AddChangeHook(convar_changed);
    C_ang = CreateConVar(PLUGIN_PREFIX ... "_ang", "0.0 0.0 0.0", "angle of the tip, split up with space");
    C_ang.AddChangeHook(convar_changed);
    C_scale = CreateConVar(PLUGIN_PREFIX ... "_scale", "0.25", "scale of the tip");
    C_scale.AddChangeHook(convar_changed);
    C_bone = CreateConVar(PLUGIN_PREFIX ... "_bone", "eyes", "bone of the tip");
    C_bone.AddChangeHook(convar_changed);
    C_render_fx = CreateConVar(PLUGIN_PREFIX ... "_render_fx", "0", "render fx of the tip");
    C_render_fx.AddChangeHook(convar_changed);
    C_pulse_duration = CreateConVar(PLUGIN_PREFIX ... "_pulse_duration", "0.2", "duration of pulse to show the tip, 0.0 or lower = disable");
    C_pulse_duration.AddChangeHook(convar_changed);
    C_pulse_interval = CreateConVar(PLUGIN_PREFIX ... "_pulse_interval", "0.2", "interval of pulse to show the tip, 0.0 or lower = disable");
    C_pulse_interval.AddChangeHook(convar_changed);
    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, PLUGIN_PREFIX);
}

public void OnPluginEnd()
{
    reset_all();
}    