/**
 * vim: set ai et ts=4 sw=4 :
 * File: remote.sp
 * Description: Remote Controlled Sentries
 * Author(s): twistedeuphoria
 * Modified by: -=|JFH|=-Naris (Murray Wilson)
 *              -- Added Native interface
 */

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = {
    name = "Remote Control Sentries",
    author = "twistedeuphoria",
    description = "Remotely control your sentries",
    version = "0.1",
    url = ""
};

new isRemoting[MAXPLAYERS+1];
new sentryWatcher[MAXPLAYERS+1];
new bool:clientEnabled[MAXPLAYERS+1];
new Float:clientSpeed[MAXPLAYERS+1];
new Float:clientJumpSpeed[MAXPLAYERS+1];

new Float:defaultSpeed = 200.0;
new Float:defaultJumpSpeed = 2000.0;

new Handle:remotecvar = INVALID_HANDLE;
new Handle:speedcvar = INVALID_HANDLE;
new Handle:jumpcvar = INVALID_HANDLE;

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
    // Register Natives
    CreateNative("ControlRemote",Native_ControlRemote);
    CreateNative("SetRemoteControl",Native_SetRemoteControl);
    CreateNative("RemoteControl",Native_RemoteControl);

    RegPluginLibrary("remote");
    return true;
}

public OnPluginStart()
{		
    CreateConVar("sm_remote_sentries_version", "0.1", "Remote Control Sentries Version", FCVAR_REPLICATED|FCVAR_NOTIFY);

    remotecvar = CreateConVar("sm_remote_sentries_enable", "1", "Enable or disable remote sentries.");
    speedcvar = CreateConVar("sm_remote_sentries_speed", "200.0", "Speed at which remote sentries move.");
    jumpcvar = CreateConVar("sm_remote_sentries_jump", "2000.0", "Speed at which remote sentries jump.");
    HookConVarChange(remotecvar, RemoteCvarChange);
    HookConVarChange(speedcvar, RemoteCvarChange);
    HookConVarChange(jumpcvar, RemoteCvarChange);

    RegConsoleCmd("sm_remote_on", remoteon, "Start remote controlling your sentry gun.", 0);
    RegConsoleCmd("sm_remote_off", remoteoff, "Stop remote controlling your sentry gun.", 0);
    RegConsoleCmd("sm_remote", remote, "Start/stop remote controlling your sentry gun.", 0);
}

public OnConfigsExecuted()
{
    defaultSpeed = GetConVarFloat(speedcvar);
    defaultJumpSpeed = GetConVarFloat(jumpcvar);
}

public RemoteCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (convar == remotecvar)
    {
        new oldval = StringToInt(oldValue);
        new newval = StringToInt(newValue);

        if( (newval != 0) && (newval != 1) )
        {
            PrintToServer("Value for sm_remote_sentries_enable is invalid %s, switching back to %s.", newValue, oldValue);
            SetConVarInt(remotecvar, oldval);
            return;
        }

        else if( (oldval == 1) && (newval == 0) )
        {
            for(new i=1;i<MaxClients;i++)
                remoteoff(i, 0);
        }
    }
    else if (convar == speedcvar)
        defaultSpeed = StringToFloat(newValue);
    else if (convar == jumpcvar)
        defaultJumpSpeed = StringToFloat(newValue);
}

public OnGameFrame()
{
    decl String:classname[50];

    for (new i=1;i<MaxClients;i++)
    {
        new sentry = isRemoting[i];
        if (sentry && IsClientInGame(i))
        {
            if (!IsValidEntity(sentry))
                remoteoff(i, 0);
            else if (!GetEdictClassname(sentry, classname, sizeof(classname)) ||
                     strcmp(classname, "obj_sentrygun") != 0)
            {
                remoteoff(i, 0);
            }
            else if (GetEntPropEnt(sentry, Prop_Send, "m_hBuilder") != i)
                remoteoff(i, 0);
            else
            {
                new Float:speed = (clientSpeed[i] > 0.0) ? clientSpeed[i] : defaultSpeed;
                new Float:nspeed = speed * -1.0;

                new Float:angles[3];
                GetClientEyeAngles(i, angles);
                angles[0] = 0.0;

                new Float:fwdvec[3];
                new Float:rightvec[3];
                new Float:upvec[3];
                GetAngleVectors(angles, fwdvec, rightvec, upvec);

                new Float:vel[3];
                vel[2] = -50.0;

                new buttons = GetClientButtons(i);
                if (buttons & IN_FORWARD)
                {
                    vel[0] += fwdvec[0] * speed;
                    vel[1] += fwdvec[1] * speed;
                }
                if (buttons & IN_BACK)
                {
                    vel[0] += fwdvec[0] * nspeed;
                    vel[1] += fwdvec[1] * nspeed;
                }
                if (buttons & IN_MOVELEFT)
                {
                    vel[0] += rightvec[0] * nspeed;
                    vel[1] += rightvec[1] * nspeed;
                }
                if (buttons & IN_MOVERIGHT)
                {
                    vel[0] += rightvec[0] * speed;
                    vel[1] += rightvec[1] * speed;
                }

                if (buttons & IN_JUMP)
                {
                    new flags = GetEntityFlags(isRemoting[i]);
                    if (flags & FL_ONGROUND)
                        vel[2] += (clientJumpSpeed[i] > 0.0) ? clientJumpSpeed[i] : defaultJumpSpeed;
                }

                TeleportEntity(isRemoting[i], NULL_VECTOR, angles, vel);

                new Float:sentrypos[3];
                GetEntPropVector(isRemoting[i], Prop_Data, "m_vecOrigin", sentrypos);

                sentrypos[0] += fwdvec[0] * -150.0;
                sentrypos[1] += fwdvec[1] * -150.0;
                sentrypos[2] += upvec[2] * 75.0;

                TeleportEntity(sentryWatcher[i], sentrypos, angles, NULL_VECTOR);
            }
        }
    }
}

public Action:remote(client, args)
{
    if (isRemoting[client] == 0)
        remoteon(client, args);
    else
        remoteoff(client, args);

    return Plugin_Handled;
}

public Action:remoteon(client, args)
{
    if (!clientEnabled[client])
    {
        if (GetConVarInt(remotecvar) != 1)
        {
            PrintToChat(client, "Remote sentries are not enabled.");
            return Plugin_Handled;
        }
        else if (TF2_GetPlayerClass(client) != TFClass_Engineer)
        {
            PrintToChat(client, "You are not an engineer.");
            return Plugin_Handled;
        }
    }

    decl String:classname[50];

    new sentryid = -1;
    new entcount = GetEntityCount();
    for (new i=MaxClients+1;i<entcount;i++)
    {
        if (IsValidEntity(i))
        {
            if (GetEdictClassname(i, classname, sizeof(classname)) &&
                strcmp(classname, "obj_sentrygun") == 0)
            {
                if (GetEntPropEnt(i,  Prop_Send, "m_hBuilder") == client)
                {
                    sentryid = i;
                    break;
                }
            }
        }
    }

    if (sentryid < 0)
        PrintToChat(client, "No sentry gun found!");
    else
    {
        SetEntityMoveType(sentryid, MOVETYPE_STEP);
        SetEntityMoveType(client, MOVETYPE_STEP);
        isRemoting[client] = sentryid;

        new watcher = sentryWatcher[client] = CreateEntityByName("info_observer_point");
        DispatchSpawn(watcher);

        new Float:angles[3];
        GetClientEyeAngles(client, angles);
        angles[0] = 0.0;

        new Float:fwdvec[3];
        new Float:rightvec[3];
        new Float:upvec[3];
        GetAngleVectors(angles, fwdvec, rightvec, upvec);

        new Float:sentrypos[3];
        GetEntPropVector(sentryid, Prop_Data, "m_vecOrigin", sentrypos);
        sentrypos[0] += fwdvec[0] * -150.0;
        sentrypos[1] += fwdvec[1] * -150.0;
        sentrypos[2] += upvec[2] * 75.0;

        TeleportEntity(watcher, sentrypos, angles, NULL_VECTOR);

        SetClientViewEntity(client, watcher);
    }

    return Plugin_Handled;
}

public Action:remoteoff(client, args)
{
    decl String:classname[50];

    new watcher = sentryWatcher[client];
    if (watcher > 0 && IsValidEntity(watcher))
    {
        if (GetEdictClassname(watcher, classname, sizeof(classname)) &&
            strcmp(classname, "info_observer_point") == 0)
        {
            RemoveEdict(watcher);
        }
    }

    if (IsClientInGame(client))
    {
        new sentry = isRemoting[client];
        if (sentry > 0 && IsValidEntity(sentry))
        {
            if (GetEdictClassname(sentry, classname, sizeof(classname)) &&
                strcmp(classname, "obj_sentrygun") == 0)
            {
                if (GetEntPropEnt(sentry,  Prop_Send, "m_hBuilder") == client)
                {
                    new Float:angles[3];
                    GetClientEyeAngles(client, angles);	
                    angles[0] = 0.0;

                    TeleportEntity(sentry, NULL_VECTOR, angles, NULL_VECTOR);
                }
            }
        }

        SetClientViewEntity(client, client);
        SetEntityMoveType(client, MOVETYPE_WALK);
    }

    isRemoting[client] = 0;
    sentryWatcher[client] = 0;
    return Plugin_Handled;
}

public Native_ControlRemote(Handle:plugin,numParams)
{
    SetConVarInt(remotecvar, 0);
}

public Native_SetRemoteControl(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        clientEnabled[client] = (numParams >= 2) ? (GetNativeCell(2)) : 0;
        clientSpeed[client] = (numParams >= 3) ? (Float:GetNativeCell(3)) : -1.0;
        clientJumpSpeed[client] = (numParams >= 4) ? (Float:GetNativeCell(4)) : -1.0;
    }
}

public Native_RemoteControl(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        remote(client, 0);
    }
}


