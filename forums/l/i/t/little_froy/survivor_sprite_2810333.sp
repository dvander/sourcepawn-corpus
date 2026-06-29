#define PLUGIN_VERSION  "1.17"
#define PLUGIN_NAME     "Survivor Sprite"
#define PLUGIN_PREFIX	"survivor_sprite"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
forward void Attachments_OnModelChanged(int client);

#define ENABLE_NORMAL       (1 << 0)
#define ENABLE_THIRDSTRIKE  (1 << 1)

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2810333"
};

ConVar C_enable;
int O_enable;

ConVar C_normal_model;
char O_normal_model[PLATFORM_MAX_PATH];
ConVar C_normal_pos;
float O_normal_pos[3];
ConVar C_normal_scale;
char O_normal_scale[PLATFORM_MAX_PATH];
ConVar C_normal_bone;
char O_normal_bone[PLATFORM_MAX_PATH];
ConVar C_normal_through_things;
bool O_normal_through_things;
ConVar C_normal_pulse_duration;
float O_normal_pulse_duration;
ConVar C_normal_pulse_interval;
float O_normal_pulse_interval;
ConVar C_normal_color;
int O_normal_color[3];

ConVar C_thirdstrike_model;
char O_thirdstrike_model[PLATFORM_MAX_PATH];
ConVar C_thirdstrike_pos;
float O_thirdstrike_pos[3];
ConVar C_thirdstrike_scale;
char O_thirdstrike_scale[PLATFORM_MAX_PATH];
ConVar C_thirdstrike_bone;
char O_thirdstrike_bone[PLATFORM_MAX_PATH];
ConVar C_thirdstrike_through_things;
bool O_thirdstrike_through_things;
ConVar C_thirdstrike_pulse_duration;
float O_thirdstrike_pulse_duration;
ConVar C_thirdstrike_pulse_interval;
float O_thirdstrike_pulse_interval;
ConVar C_thirdstrike_color;
int O_thirdstrike_color[3];

Handle H_change_normal;
Handle H_change_thirdstrike;
bool Show_normal = true;
bool Show_thirdstrike = true;
bool Set_bone_normal;
bool Set_bone_thirdstrike;

bool Late_load;
bool Map_started;

ArrayList Filter_entities;

int Sprite_normal[MAXPLAYERS+1] = {-1, ...};
int Sprite_thirdstrike[MAXPLAYERS+1] = {-1, ...};

public void OnMapStart()
{
    reset_all();
    Map_started = true;
    precache_models();
}

public void OnMapEnd()
{
    reset_all();
    Map_started = false;
    Filter_entities.Clear();
}

public void Attachments_OnModelChanged(int client)
{
    reset_player(client);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if(entity < 0)
    {
        return;
    }
    if(strcmp(classname, "infected") == 0 || strcmp(classname, "witch") == 0 || strcmp(classname, "tank_rock") == 0)
    {
        Filter_entities.Push(EntIndexToEntRef(entity));
    }
}

public void OnEntityDestroyed(int entity)
{
    if(entity < 0)
    {
        return;
    }
    int index = Filter_entities.FindValue(EntIndexToEntRef(entity));
    if(index != -1)
    {
        Filter_entities.Erase(index);
    }
}

void precache_models()
{
    if(!IsModelPrecached(O_normal_model))
    {
        PrecacheModel(O_normal_model, true);
    }
    if(!IsModelPrecached(O_thirdstrike_model))
    {
        PrecacheModel(O_thirdstrike_model, true);
    }
}

bool is_survivor_on_thirdstrike(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike");
}

bool is_visible_to(int client, int target)
{
	float self_pos[3];
    float target_pos[3];
    GetClientEyePosition(client, self_pos);
    GetClientEyePosition(target, target_pos);
	Handle trace = TR_TraceRayFilterEx(self_pos, target_pos, CONTENTS_SOLID, RayType_EndPoint, trace_entity_filter, target);
    bool result = !TR_DidHit(trace) || TR_GetEntityIndex(trace) == target;
	delete trace;
	return result;
}

bool trace_entity_filter(int entity, int contentsMask, any data)
{
    if(entity == data)
    {
        return true;
    }
    if(entity > 0 && entity <= MaxClients)
    {
        return false;
    }
    return Filter_entities.FindValue(EntIndexToEntRef(entity)) == -1;
}

Action set_transmit_normal(int entity, int client)
{
    if(!Show_normal)
    {
        return Plugin_Handled;
    }
    if(GameRules_GetProp("m_bInIntro"))
    {
        return Plugin_Handled;
    }
    if(GetEntPropEnt(client, Prop_Send, "m_hViewEntity") != -1)
    {
        return Plugin_Handled;
    }
    int ref = EntIndexToEntRef(entity);
    int owner = -1;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(Sprite_normal[i] == ref)
        {
            owner = i;
            break;
        }
    }
    if(owner == -1)
    {
        return Plugin_Handled;
    }
    if(owner == client)
    {
        return Plugin_Handled;
    }
    if(!IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_iObserverMode") == 4 && GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") == owner)
    {
        return Plugin_Handled;
    }
    if(!O_normal_through_things && !is_visible_to(client, owner))
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

Action set_transmit_thirdstrike(int entity, int client)
{
    if(!Show_thirdstrike)
    {
        return Plugin_Handled;
    }
    if(GameRules_GetProp("m_bInIntro"))
    {
        return Plugin_Handled;
    }
    if(GetEntPropEnt(client, Prop_Send, "m_hViewEntity") != -1)
    {
        return Plugin_Handled;
    }
    int ref = EntIndexToEntRef(entity);
    int owner = -1;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(Sprite_thirdstrike[i] == ref)
        {
            owner = i;
            break;
        }
    }
    if(owner == -1)
    {
        return Plugin_Handled;
    }
    if(owner == client)
    {
        return Plugin_Handled;
    }
    if(!IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_iObserverMode") == 4 && GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") == owner)
    {
        return Plugin_Handled;
    }
    if(!O_thirdstrike_through_things && !is_visible_to(client, owner))
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

void set_sprite_normal(int client)
{
    if(Sprite_normal[client] == -1)
    {
        int entity = CreateEntityByName("env_sprite");
        if(entity == -1)
        {
            return;
        }
        DispatchKeyValue(entity, "model", O_normal_model);
        DispatchKeyValue(entity, "GlowProxySize", "0.0");
        DispatchKeyValue(entity, "scale", O_normal_scale);
        DispatchSpawn(entity);
        SetVariantString("!activator");
        AcceptEntityInput(entity, "SetParent", client);
        if(Set_bone_normal)
        {
            SetVariantString(O_normal_bone);
            AcceptEntityInput(entity, "SetParentAttachment");
        }
        TeleportEntity(entity, O_normal_pos, view_as<float>({0.0, 0.0, 0.0}));
        SetEntProp(entity, Prop_Data, "m_iEFlags", 0);
        SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
        SetEntityRenderColor(entity, O_normal_color[0], O_normal_color[1], O_normal_color[2], 255);
        Sprite_normal[client] = EntIndexToEntRef(entity);
        SDKHook(entity, SDKHook_SetTransmit, set_transmit_normal);
    }
}

void set_sprite_thirdstrike(int client)
{
    if(Sprite_thirdstrike[client] == -1)
    {
        int entity = CreateEntityByName("env_sprite");
        if(entity == -1)
        {
            return;
        }
        DispatchKeyValue(entity, "model", O_thirdstrike_model);
        DispatchKeyValue(entity, "GlowProxySize", "0.0");
        DispatchKeyValue(entity, "scale", O_thirdstrike_scale);
        DispatchSpawn(entity);
        SetVariantString("!activator");
        AcceptEntityInput(entity, "SetParent", client);
        if(Set_bone_thirdstrike)
        {
            SetVariantString(O_thirdstrike_bone);
            AcceptEntityInput(entity, "SetParentAttachment");
        }
        TeleportEntity(entity, O_thirdstrike_pos, view_as<float>({0.0, 0.0, 0.0}));
        SetEntProp(entity, Prop_Data, "m_iEFlags", 0);
        SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
        SetEntityRenderColor(entity, O_thirdstrike_color[0], O_thirdstrike_color[1], O_thirdstrike_color[2], 255);
        Sprite_thirdstrike[client] = EntIndexToEntRef(entity);
        SDKHook(entity, SDKHook_SetTransmit, set_transmit_thirdstrike);
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

void reset_sprite_normal(int client)
{
    if(Sprite_normal[client] != -1)
    {
        remove_ref(Sprite_normal[client]);
    }
}

void reset_sprite_thirdstrike(int client)
{
    if(Sprite_thirdstrike[client] != -1)
    {
        remove_ref(Sprite_thirdstrike[client]);
    }
}

void reset_player(int client)
{
    reset_sprite_normal(client);
    reset_sprite_thirdstrike(client);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if(GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        if(is_survivor_on_thirdstrike(client))
        {
            if(O_enable & ENABLE_THIRDSTRIKE)
            {
                reset_sprite_normal(client);
                set_sprite_thirdstrike(client);
            }
            else
            {
                reset_player(client);
            }
        }
        else
        {
            if(O_enable & ENABLE_NORMAL)
            {
                reset_sprite_thirdstrike(client);
                set_sprite_normal(client);
            }
            else
            {
                reset_player(client);
            }
        }
    }
    else
    {
        reset_player(client);
    }
}

public void OnClientDisconnect_Post(int client)
{
    reset_player(client);
}

void reset_all()
{
    for(int client = 1; client <= MAXPLAYERS; client++)
    {
        reset_player(client);
    }
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    reset_all();
}

void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0)
	{
		reset_player(client);
	}
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0)
	{
		reset_player(client);
	}
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0)
	{
		reset_player(client);
	}
}

Action timer_change_normal(Handle timer)
{
    if(Show_normal)
    {
        Show_normal = false;
        H_change_normal = CreateTimer(O_normal_pulse_interval, timer_change_normal);
    }
    else
    {
        Show_normal = true;
        H_change_normal = CreateTimer(O_normal_pulse_duration, timer_change_normal);
    }
    return Plugin_Stop;
}

Action timer_change_thirdstrike(Handle timer)
{
    if(Show_thirdstrike)
    {
        Show_thirdstrike = false;
        H_change_thirdstrike = CreateTimer(O_thirdstrike_pulse_interval, timer_change_thirdstrike);
    }
    else
    {
        Show_thirdstrike = true;
        H_change_thirdstrike = CreateTimer(O_thirdstrike_pulse_duration, timer_change_thirdstrike);
    }
    return Plugin_Stop;
}

void get_cvars()
{
    O_enable = C_enable.IntValue;
    char cvar_pos[48];
    char get_pos[3][16];
    char cvar_colors[13];
    char colors_get[3][4];
    C_thirdstrike_model.GetString(O_thirdstrike_model, sizeof(O_thirdstrike_model));
    C_thirdstrike_pos.GetString(cvar_pos, sizeof(cvar_pos));
    ExplodeString(cvar_pos, " ", get_pos, 3, 16);
    for(int i = 0; i < 3; i++)
    {
        O_thirdstrike_pos[i] = StringToFloat(get_pos[i]);
    }
    C_thirdstrike_scale.GetString(O_thirdstrike_scale, sizeof(O_thirdstrike_scale));
    C_thirdstrike_bone.GetString(O_thirdstrike_bone, sizeof(O_thirdstrike_bone));
    O_thirdstrike_through_things = C_thirdstrike_through_things.BoolValue;
    O_thirdstrike_pulse_duration = C_thirdstrike_pulse_duration.FloatValue;
    O_thirdstrike_pulse_interval = C_thirdstrike_pulse_interval.FloatValue;
    C_thirdstrike_color.GetString(cvar_colors, sizeof(cvar_colors));
    ExplodeString(cvar_colors, " ", colors_get, 3, 4);
    for(int i = 0; i < 3; i++)
    {
        O_thirdstrike_color[i] = StringToInt(colors_get[i]);
        if(O_thirdstrike_color[i] > 255)
        {
            O_thirdstrike_color[i] = 255;
        }
        else if(O_thirdstrike_color[i] < 0)
        {
            O_thirdstrike_color[i] = 0;
        }
    }
    C_normal_model.GetString(O_normal_model, sizeof(O_normal_model));
    C_normal_pos.GetString(cvar_pos, sizeof(cvar_pos));
    ExplodeString(cvar_pos, " ", get_pos, 3, 16);
    for(int i = 0; i < 3; i++)
    {
        O_normal_pos[i] = StringToFloat(get_pos[i]);
    }
    C_normal_scale.GetString(O_normal_scale, sizeof(O_normal_scale));
    C_normal_bone.GetString(O_normal_bone, sizeof(O_normal_bone));
    O_normal_through_things = C_normal_through_things.BoolValue;
    O_normal_pulse_duration = C_normal_pulse_duration.FloatValue;
    O_normal_pulse_interval = C_normal_pulse_interval.FloatValue;
    C_normal_color.GetString(cvar_colors, sizeof(cvar_colors));
    ExplodeString(cvar_colors, " ", colors_get, 3, 4);
    for(int i = 0; i < 3; i++)
    {
        O_normal_color[i] = StringToInt(colors_get[i]);
        if(O_normal_color[i] > 255)
        {
            O_normal_color[i] = 255;
        }
        else if(O_normal_color[i] < 0)
        {
            O_normal_color[i] = 0;
        }
    }

    if(Map_started)
    {
        precache_models();
    }

    Set_bone_normal = strlen(O_normal_bone) > 0;
    Set_bone_thirdstrike = strlen(O_thirdstrike_bone) > 0;
    delete H_change_normal;
    delete H_change_thirdstrike;
    Show_normal = true;
    Show_thirdstrike = true;
    if(O_enable & ENABLE_NORMAL && O_normal_pulse_duration >= 0.1 && O_normal_pulse_interval >= 0.1)
    {
        H_change_normal = CreateTimer(O_normal_pulse_duration, timer_change_normal);
    }
    if(O_enable & ENABLE_THIRDSTRIKE && O_thirdstrike_pulse_duration >= 0.1 && O_thirdstrike_pulse_interval >= 0.1)
    {
        H_change_thirdstrike = CreateTimer(O_thirdstrike_pulse_duration, timer_change_thirdstrike);
    }
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_cvars();

    reset_all();
}

public void OnConfigsExecuted()
{
	get_cvars();

    reset_all();
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
    Filter_entities = new ArrayList();

    HookEvent("round_start", event_round_start);
    HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_team", event_player_team);
    HookEvent("player_death", event_player_death);

    C_enable = CreateConVar(PLUGIN_PREFIX ... "_enable", "3", "1 = enable normal sprite, 2 = enable thirdstrike sprite. add numbers together", _, true, 0.0, true, 3.0);
    C_enable.AddChangeHook(convar_changed);

    C_normal_model = CreateConVar(PLUGIN_PREFIX ... "_normal_model", "materials/vgui/icon_arrow_down.vmt", "model of normal sprite");
    C_normal_model.AddChangeHook(convar_changed);
    C_normal_pos = CreateConVar(PLUGIN_PREFIX ... "_normal_pos", "0.0 0.0 0.0", "position of normal sprite, split up with space");
    C_normal_pos.AddChangeHook(convar_changed);
    C_normal_scale = CreateConVar(PLUGIN_PREFIX ... "_normal_scale", "0.4", "scale of normal sprite");
    C_normal_scale.AddChangeHook(convar_changed);
    C_normal_bone = CreateConVar(PLUGIN_PREFIX ... "_normal_bone", "spine", "bone of normal sprite. leave empty to disable");
    C_normal_bone.AddChangeHook(convar_changed);
    C_normal_through_things = CreateConVar(PLUGIN_PREFIX ... "_normal_through_things", "0", "1 = enable, 0 = disable. can normal sprite be seen through things solid?");
    C_normal_through_things.AddChangeHook(convar_changed);
    C_normal_pulse_duration = CreateConVar(PLUGIN_PREFIX ... "_normal_pulse_duration", "0.3", "duration of pulse to show normal sprite. lower than 0.1 = disable");
    C_normal_pulse_duration.AddChangeHook(convar_changed);
    C_normal_pulse_interval = CreateConVar(PLUGIN_PREFIX ... "_normal_pulse_interval", "0.3", "interval of pulse to show normal sprite. lower than 0.1 = disable");
    C_normal_pulse_interval.AddChangeHook(convar_changed);
    C_normal_color = CreateConVar(PLUGIN_PREFIX ... "_normal_color", "255 255 255", "render color of normal sprite, split up with space");
    C_normal_color.AddChangeHook(convar_changed);

    C_thirdstrike_model = CreateConVar(PLUGIN_PREFIX ... "_thirdstrike_model", "materials/vgui/hud/icon_medkit.vmt", "model of thirdstrike sprite");
    C_thirdstrike_model.AddChangeHook(convar_changed);
    C_thirdstrike_pos = CreateConVar(PLUGIN_PREFIX ... "_thirdstrike_pos", "0.0 0.0 0.0", "position of thirdstrike sprite, split up with space");
    C_thirdstrike_pos.AddChangeHook(convar_changed);
    C_thirdstrike_scale = CreateConVar(PLUGIN_PREFIX ... "_thirdstrike_scale", "0.1", "scale of thirdstrike sprite");
    C_thirdstrike_scale.AddChangeHook(convar_changed);
    C_thirdstrike_bone = CreateConVar(PLUGIN_PREFIX ... "_thirdstrike_bone", "spine", "bone of thirdstrike sprite. leave empty to disable");
    C_thirdstrike_bone.AddChangeHook(convar_changed);
    C_thirdstrike_through_things = CreateConVar(PLUGIN_PREFIX ... "_thirdstrike_through_things", "0", "1 = enable, 0 = disable. can thirdstrike sprite be seen through things solid?");
    C_thirdstrike_through_things.AddChangeHook(convar_changed);
    C_thirdstrike_pulse_duration = CreateConVar(PLUGIN_PREFIX ... "_thirdstrike_pulse_duration", "0.3", "duration of pulse to show thirdstrike sprite. lower than 0.1 = disable");
    C_thirdstrike_pulse_duration.AddChangeHook(convar_changed);
    C_thirdstrike_pulse_interval = CreateConVar(PLUGIN_PREFIX ... "_thirdstrike_pulse_interval", "0.3", "interval of pulse to show thirdstrike sprite. lower than 0.1 = disable");
    C_thirdstrike_pulse_interval.AddChangeHook(convar_changed);
    C_thirdstrike_color = CreateConVar(PLUGIN_PREFIX ... "_thirdstrike_color", "255 255 255", "render color of thirdstrike sprite, split up with space");
    C_thirdstrike_color.AddChangeHook(convar_changed);
    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, PLUGIN_PREFIX);
    get_cvars();

    if(Late_load)
    {
        int entity = -1;
        while((entity = FindEntityByClassname(entity, "infected")) != -1)
        {
            Filter_entities.Push(EntIndexToEntRef(entity));
        }
        while((entity = FindEntityByClassname(entity, "witch")) != -1)
        {
            Filter_entities.Push(EntIndexToEntRef(entity));
        }
        while((entity = FindEntityByClassname(entity, "tank_rock")) != -1)
        {
            Filter_entities.Push(EntIndexToEntRef(entity));
        }
    }
}

public void OnPluginEnd()
{
    reset_all();
}