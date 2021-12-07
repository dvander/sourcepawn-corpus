/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: tf2teleporter.sp
 * Description: Decrease teleporter time in TF2
 * Author(s): Nican132
 */

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "3.0"

public Plugin:myinfo = 
{
    name = "Teleport Tools",
    author = "Nican132",
    description = "Decrease teleporter time in TF2",
    version = PL_VERSION,
    url = "http://sourcemod.net/"
};       

new maxents;
new maxplayers;

new TeleporterList[ MAXPLAYERS ][ 2 ];

new bool:NativeControl = false;
new Float:TeleporterTime[ MAXPLAYERS ] = { 0.0, ...};

#define LIST_OBJECT 0
#define LIST_TEAM 1

#define ENABLEDTELE 0
#define TELEBLUETIME 1
#define TELEREDTIME 2
#define TELETIME 3

new Handle:g_cvars[4];
new Handle:teletimer = INVALID_HANDLE;

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
    // Register Natives
    CreateNative("ControlTeleporter",Native_ControlTeleporter);
    CreateNative("SetTeleporter",Native_SetTeleporter);
    RegPluginLibrary("tf2teleporter");
    return true;
}


public OnPluginStart()
{
    CreateConVar("sm_tf_teletools", PL_VERSION, "Teleport Tools", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    g_cvars[ENABLEDTELE] = CreateConVar("sm_tele_on","1","Enable/Disable teleport manager");
    g_cvars[TELEBLUETIME] = CreateConVar("sm_teleblue_time","0.6","Amount of time for blue tele to recharg, 0.0=disable");
    g_cvars[TELEREDTIME] = CreateConVar("sm_telered_time","0.6","Amount of time for red tele to recharg, 0.0=disable");
    g_cvars[TELETIME] = CreateConVar("sm_tele_time","0.0","Amount of time for the recharge timer tick, 0.0=auto");

    HookEvent("player_builtobject", Event_player_builtobject);
}

public OnConfigsExecuted()
{
    Createtimers(0.0);

    HookConVarChange(g_cvars[ENABLEDTELE],  TF2ConfigsChanged );
    HookConVarChange(g_cvars[TELEBLUETIME], TF2ConfigsChanged ); 
    HookConVarChange(g_cvars[TELEREDTIME],  TF2ConfigsChanged );
    HookConVarChange(g_cvars[TELETIME],  TF2ConfigsChanged );
}

public TF2ConfigsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    Createtimers(0.0);
}

stock Createtimers(Float:time)
{
    if(teletimer != INVALID_HANDLE)
    {
        KillTimer( teletimer );
        teletimer = INVALID_HANDLE;
    }

    if (time > 0.0)
        CreateTeleTimer( time ); 
    else if(GetConVarBool( g_cvars[ENABLEDTELE] ))
    {
        time = GetConVarFloat( g_cvars[TELETIME] );
        if (time > 0.0)
            CreateTeleTimer( time ); 
        else
        {
            new Float:bluetime = GetConVarFloat( g_cvars[TELEBLUETIME] );
            new Float:redtime  = GetConVarFloat( g_cvars[TELEREDTIME] );
            if (bluetime > 0.0 && redtime >= bluetime)
                CreateTeleTimer( bluetime );    
            else if (redtime > 0.0)
                CreateTeleTimer( redtime ); 
            else
                LogError("tf2_teletools have been disabled, sm_tele_on is set, but no sm_tele*_time values are");
        }
    }
}

stock CreateTeleTimer( Float:time )
{
    teletimer = CreateTimer( time, CheckAllTeles, 0, TIMER_REPEAT);
}

public Action:CheckAllTeles(Handle:timer, any:useless)
{
    new i;
    new Float:bluetime = GetConVarFloat( g_cvars[TELEBLUETIME] );
    new Float:redtime  = GetConVarFloat( g_cvars[TELEREDTIME] );

    decl String:classname[19];
    new Float:oldtime, Float:newtime, Float:time;

    for(i = 1; i< maxplayers; i++)
    {
        new entity = TeleporterList[i][LIST_OBJECT];
        if(entity == 0)
            continue;
        else if(!IsValidEntity(entity))
        {
            TeleporterList[i][LIST_OBJECT] = 0;
            continue;
        }
        else
        {
            GetEntityNetClass(entity, classname, sizeof(classname));
            if(!StrEqual(classname, "CObjectTeleporter"))
            {
                TeleporterList[i][LIST_OBJECT] = 0;
                continue;
            }
            else if( GetEntProp(entity, Prop_Send, "m_iObjectType") != 1 )
            {
                TeleporterList[i][LIST_OBJECT] = 0;
                continue;
            }
            else if ( GetEntPropEnt(entity, Prop_Send, "m_hBuilder") != i )
            {
                TeleporterList[i][LIST_OBJECT] = 0;
                continue;
            }
        }

        if (NativeControl)
            time = TeleporterTime[i];
        else if( TeleporterList[i][LIST_TEAM] == 3)
            time = bluetime;
        else if( TeleporterList[i][LIST_TEAM] == 2)
            time = redtime;
        else // Unknown Team!
            time = 0.0;

        if (time <= 0.0)
            continue;

        oldtime = GetEntPropFloat(entity, Prop_Send, "m_flRechargeTime");
        if( float(RoundFloat(oldtime)) == oldtime)
            continue;

        newtime = oldtime - 10.5 + time;

        SetEntPropFloat(entity, Prop_Send, "m_flRechargeTime", float(RoundFloat(newtime)));
    } 
}

public Action:Event_player_builtobject(Handle:event, const String:name[], bool:dontBroadcast)
{
    //new id = GetEventInt(event, "object");
    //Does not work, object return what type of structure it is
    //0=dispenser
    //1=teleporter entrance
    //2=teleporter exit
    //3=sentry

    if ( GetEventInt(event, "object") != 1)
        return Plugin_Continue;

    new i, owner;
    decl String:classname[19];
    for(i =  maxplayers + 1; i <= maxents; i++)
    {
        if(IsValidEntity(i))
        {
            GetEntityNetClass(i, classname, sizeof(classname));
            if(StrEqual(classname, "CObjectTeleporter"))
            {
                if( GetEntProp(i, Prop_Send, "m_iObjectType") == 1 )
                {
                    owner = GetEntPropEnt(i, Prop_Send, "m_hBuilder");
                    TeleporterList[owner][ LIST_TEAM ] = GetEntProp(i, Prop_Send, "m_iTeamNum");
                    TeleporterList[owner][ LIST_OBJECT ] = i;	
                }	
            }
        }
    } 

    return Plugin_Continue;
}

public OnMapStart()
{
    maxplayers = GetMaxClients();
    maxents = GetMaxEntities();
}

public Native_ControlTeleporter(Handle:plugin,numParams)
{
    if (numParams == 0)
        NativeControl = true;
    else if(numParams >= 1)
    {
        NativeControl = GetNativeCell(1);
        if (numParams >= 2)
            Createtimers(Float:GetNativeCell(1));
    }
}

public Native_SetTeleporter(Handle:plugin,numParams)
{
    if (numParams >= 1 && numParams <= 2)
    {
        new client = GetNativeCell(1);
        TeleporterTime[client] = (numParams >= 2) ? (Float:GetNativeCell(2)) : 0.0;
    }
}
