#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME			    "clown_world"
#define PLUGIN_VERSION 			"1.02"
#define CONFIG_FILENAME         PLUGIN_NAME
#define DEBUG 0

#define MAXENTITIES        2048

#define STATE_UNCHECKED 0 // entity not checked for m_clrRender
#define STATE_VALID 1 // entity has m_clrRender
#define STATE_INVALID 2 // entity does not have m_clrRender

int state[MAXENTITIES+1]; // ignore entities without m_clrRender entprop
ArrayList g_IgnoreClasses; // all infected models

public Plugin myinfo =
{
	name = "[ANY] Clown World",
	author = "gvazdas",
	description = "Randomize color of all entities.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=352413, https://knockout.chat/user/3022"
}

Handle timer_caramel;
ConVar g_hCvarEnable, g_hCvarPlayers, g_hCvarRound, g_hCvarCaramel;
bool plugin_started = false;

Action request_reset(int client, int args)
{
    char command[PLATFORM_MAX_PATH];
    Format(command, sizeof(command), "exec sourcemod/%s", CONFIG_FILENAME);
    ServerCommand(command);
    return Plugin_Stop;
}

public void OnPluginStart()
{
    AutoExecConfig(true, CONFIG_FILENAME);
    RegAdminCmd("clown_world_resetcvars", request_reset, ADMFLAG_ROOT, "Reload default cfg. Admins only.");
    RegAdminCmd("clown_world_randomize", randomize_all, ADMFLAG_ROOT,"Randomize color of all entities.");
    RegAdminCmd("clown_world_target", color_target, ADMFLAG_ROOT,"Set R G B A (0-255; -1 for random) of target entity. No arguments to randomize values.");
    
    g_hCvarEnable = CreateConVar("clown_world_enable", "1", "Enable clown world. Randomize colors every new map.",FCVAR_PROTECTED , true, 0.0, true, 1.0);
    g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarCaramel = CreateConVar("clown_world_caramel", "0", "Randomize colors every 0.36363636363 seconds.",FCVAR_PROTECTED , true, 0.0, true, 1.0);
    g_hCvarCaramel.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarPlayers = CreateConVar("clown_world_players", "0", "Allow player colors to be randomized.",FCVAR_PROTECTED , true, 0.0, true, 1.0);
    g_hCvarRound = CreateConVar("clown_world_round", "1", "Randomize colors every round.",FCVAR_PROTECTED , true, 0.0, true, 1.0);
    
    HookEvent("round_start",evtRoundStart,EventHookMode_PostNoCopy);
    
    delete g_IgnoreClasses;
	g_IgnoreClasses = new ArrayList(ByteCountToCells(64));
    plugin_started = true;
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (strcmp(oldValue,newValue,false)==0) return;
    randomize_all(0,0);
}

void evtRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_hCvarEnable.BoolValue || !g_hCvarRound.BoolValue) return;
	randomize_all(0,0);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (IsValidEdict(entity)) state[entity] = STATE_UNCHECKED;
    if (!g_hCvarEnable.BoolValue) return;
    set_color(entity);
}

public void OnMapStart()
{
    timer_caramel = null;
    if (!g_hCvarEnable.BoolValue) return;
    randomize_all(0,0);
}

Action randomize_all(int client, int args)
{
    if (!plugin_started) return Plugin_Stop;
    int entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
    {
        set_color(entity);
    }
    if (!g_hCvarCaramel.BoolValue || !g_hCvarEnable.BoolValue) timer_caramel = null;
    if (g_hCvarEnable.BoolValue && g_hCvarCaramel.BoolValue && timer_caramel==null)
        timer_caramel = CreateTimer(0.36363636363,Timer_Randomize,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Continue;
}

Action Timer_Randomize(Handle timer)
{
    if (!g_hCvarEnable.BoolValue || !g_hCvarCaramel.BoolValue || timer_caramel==null)
    {
        timer_caramel = null;
        return Plugin_Stop;
    }
    randomize_all(0,0);
    return Plugin_Continue;
}

Action color_target(int client, int args)
{
   if (client<=0) return Plugin_Stop;
   int target = GetClientAimTarget(client,false);
   if (target==-1) return Plugin_Stop;
   int r = -1;
   int g = -1;
   int b = -1;
   int a = 255;
   if (args>0)
   {
       r = Clamp(GetCmdArgInt(1),255); 
       if (args>1)
       {
           g = Clamp(GetCmdArgInt(2),255);  
           if (args>2)
           {
               b = Clamp(GetCmdArgInt(3),255);  
               if (args>3) a = Clamp(GetCmdArgInt(4),255);  
           }
       }
   }
   set_color(target,client,r,g,b,a);
   return Plugin_Continue;
}

// client specifies who is calling the function, >0 for admins. Allows admins to change colors of target even if main cvar is OFF.
void set_color(int entity, int client = -1, int r = -1, int g = -1, int b = -1, int a = 255)
{
    if (entity==-1) return;
    bool networked = IsValidEdict(entity);
    if (networked && state[entity]>=STATE_INVALID) return;
    if (entity>0 && entity<=MaxClients && client<0 && !g_hCvarPlayers.BoolValue) return;
    if ( !networked || (networked && state[entity]<=STATE_UNCHECKED) )
    {
        static char class[64];
        GetEntityClassname(entity, class, sizeof(class));
        if (g_IgnoreClasses.FindString(class)>=0)
        {
            if (networked) state[entity] = STATE_INVALID;
            return;
        }
        if (!HasEntProp(entity,Prop_Send,"m_clrRender")) // this is slow
        {
            #if DEBUG
            LogMessage("entity %d %s m_clrRender not found", entity, class);
            #endif
            g_IgnoreClasses.PushString(class);
            if (networked) state[entity] = STATE_INVALID;
            return;
        }
        else if (networked) state[entity] = STATE_VALID;
    }
    if (g_hCvarEnable.BoolValue || client>0)
    {
        if (r<0) r = GetRandomInt(0,255);
        if (g<0) g = GetRandomInt(0,255);
        if (b<0) b = GetRandomInt(0,255);
        if (a<0) a = GetRandomInt(0,255);
    }
    else
    {
        r = 255; g = 255; b = 255; a = 255;
    }
    SetEntityRenderColor(entity,r,g,b,a);
}

stock int Clamp(int value, int max)
{
    if (value > max) return max;
    return value;
}