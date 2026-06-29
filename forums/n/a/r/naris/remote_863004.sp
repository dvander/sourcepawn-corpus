/**
 * vim: set ai et ts=4 sw=4 :
 * File: remote.sp
 * Description: Remote Controlled Sentries
 * Author(s): twistedeuphoria
 * Modified by: -=|JFH|=-Naris (Murray Wilson)
 *              -- Added Native interface
 *              -- Added build support
 *              -- Merged build limit
 */

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

//#include <remote>
// These define the permissions
#define HAS_REMOTE 		            (1 << 0)
#define CAN_STEAL		            (1 << 1)
#define CAN_BUILD     		        (1 << 2)

// Build Limit defines
#define TF_OBJECT_DISPENSER	0
#define TF_OBJECT_TELE_ENTR	1
#define TF_OBJECT_TELE_EXIT	2
#define TF_OBJECT_SENTRY	3

#define TF_TEAM_BLU			3
#define TF_TEAM_RED			2

//#include <tf2_objects>
/**
 * Description: Functions to return infomation about TF2 objects.
 */
enum objects { dispenser, teleporter_entry, teleporter_exit, sentrygun, sapper, teleporter, unknown };

stock String:TF2_ObjectNames[objects][] = { "Dispenser", "Teleporter Entrance", "Teleporter Exit",
                                            "Sentry Gun", "Sapper", "Teleporter", "" };

stock objects:GetObjectTypeFromEdictClass(const String:class[])
{
    if (StrEqual(class, "obj_sentrygun", false))
        return sentrygun;
    else if (StrEqual(class, "obj_dispenser", false))
        return dispenser;
    else if (StrEqual(class, "obj_teleporter_entrance", false))
        return teleporter_entry;
    else if (StrEqual(class, "obj_teleporter_exit", false))
        return teleporter_exit;
    else if (StrEqual(class, "obj_sapper", false))
        return sapper;
    else
        return unknown;
}

stock objects:GetObjectType(entity)
{
    decl String:class[32];
    if (GetEdictClassname(entity,class,sizeof(class)))
        return GetObjectTypeFromEdictClass(class);
    else
        return unknown;
}
/**
 * End of tf2_objects
 */


public Plugin:myinfo = {
    name = "Remote Control Sentries",
    author = "twistedeuphoria",
    description = "Remotely control your sentries",
    version = "0.1",
    url = ""
};

new isRemoting[MAXPLAYERS+1];
new objects:remoteType[MAXPLAYERS+1];
new watcherEntity[MAXPLAYERS+1];
new clientPermissions[MAXPLAYERS+1] = { -1, ... };
new Float:clientSpeed[MAXPLAYERS+1];
new Float:clientJumpSpeed[MAXPLAYERS+1];

new Float:fallSpeed = -500.0;
new Float:levelFactor = 0.50;
new Float:defaultSpeed = 300.0;
new Float:defaultJumpSpeed = 2000.0;

// build limits
new Handle:gTimer;       
new g_iMaxEntities = 2048;
new bool:g_bNativeControl = false;
new Handle:g_hLimits[4][4];
new g_iAllowed[MAXPLAYERS+1][4]; // how many buildings each player is allowed

new bool:g_bBuildHooked = false;
new bool:gControlObjectHooked = false;

// forwards
new Handle:g_fwdOnBuild = INVALID_HANDLE;
new Handle:fwdOnControlObject = INVALID_HANDLE;

// convars
new Handle:cvarRemote = INVALID_HANDLE;
new Handle:cvarSteal = INVALID_HANDLE;
new Handle:cvarBuild = INVALID_HANDLE;
new Handle:cvarFactor = INVALID_HANDLE;
new Handle:cvarSpeed = INVALID_HANDLE;
new Handle:cvarJump = INVALID_HANDLE;
new Handle:cvarFall = INVALID_HANDLE;

new Handle:g_hBuildEnabled = INVALID_HANDLE;
new Handle:g_hBuildImmunity = INVALID_HANDLE;

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
    // Register Natives
    CreateNative("ControlRemote",Native_ControlRemote);
    CreateNative("SetRemoteControl",Native_SetRemoteControl);
    CreateNative("RemoteControlObject",Native_ControlObject);
    CreateNative("HookControlObject",Native_HookControlObject);

    // Build Limit Natives
    CreateNative("BuildSentry",Native_BuildSentry);
    CreateNative("BuildDispenser",Native_BuildDispenser);
    CreateNative("BuildBuildTeleporterEntry",N_BuildBuildTeleporterEntry);
    CreateNative("BuildBuildTeleporterExit",N_BuildBuildTeleporterExit);

    // Build Limit Natives
    CreateNative("ControlBuild",Native_ControlBuild);
    CreateNative("ResetBuild",Native_ResetBuild);
    CreateNative("CheckBuild",Native_CheckBuild);
    CreateNative("GiveBuild",Native_GiveBuild);
    CreateNative("HookBuild",Native_HookBuild);

    // Register Forwards
    fwdOnControlObject=CreateForward(ET_Hook,Param_Cell,Param_Cell,Param_Cell);

    // Build Limit Forwards
    g_fwdOnBuild=CreateForward(ET_Hook,Param_Cell,Param_Cell,Param_Cell);

    RegPluginLibrary("remote");
    return true;
}

public OnPluginStart()
{		
    CreateConVar("sm_remote_sentries_version", "0.1", "Remote Control Sentries Version", FCVAR_REPLICATED|FCVAR_NOTIFY);

    cvarRemote = CreateConVar("sm_remote_enable", "1", "Enable or disable remote control.");
    cvarSteal = CreateConVar("sm_remote_steal", "0", "Set true to allow stealing other people's buildings.");
    cvarBuild = CreateConVar("sm_remote_build", "0", "Set true to spawn desired building if it doesn't exist.");
    cvarFactor = CreateConVar("sm_remote_factor", "0.50", "Factor multiplied by (4 - sentry level) then multiplied by speed.");
    cvarSpeed = CreateConVar("sm_remote_speed", "300.0", "Speed at which remote objects move.");
    cvarJump = CreateConVar("sm_remote_jump", "2000.0", "Speed at which remote objects jump.");
    cvarFall = CreateConVar("sm_remote_fall", "500.0", "Speed at which remote objects fall.");

    HookConVarChange(cvarRemote, RemoteCvarChange);
    HookConVarChange(cvarSteal, RemoteCvarChange);
    HookConVarChange(cvarBuild, RemoteCvarChange);
    HookConVarChange(cvarFactor, RemoteCvarChange);
    HookConVarChange(cvarSpeed, RemoteCvarChange);
    HookConVarChange(cvarJump, RemoteCvarChange);

    RegConsoleCmd("sm_remote_on", remoteon, "Start remote controlling your buildings(sentry gun).", 0);
    RegConsoleCmd("sm_remote_off", remoteoff, "Stop remote controlling your buildings.", 0);
    RegConsoleCmd("sm_remote", remote, "Start/stop remote controlling your buildings(sentry gun).", 0);

    RegConsoleCmd("sm_sentry", remote, "Start/stop remote controlling your sentry gun.");
    RegConsoleCmd("sm_enter", remote, "Start/stop remote controlling your teleport entrance.");
    RegConsoleCmd("sm_exit", remote, "Start/stop remote controlling your teleport exit.");
    RegConsoleCmd("sm_disp", remote, "Start/stop remote controlling your dispenser.");

    RegAdminCmd("sm_remote_god", remotegod, ADMFLAG_ROOT, "Gives Sentry godmode (experimental).");

    // Build Limits
    g_hBuildEnabled  = CreateConVar("sm_buildlimit_enabled",               "1", "Enable/disable restricting buildings in TF2.");
    g_hBuildImmunity = CreateConVar("sm_buildlimit_immunity",              "0", "Enable/disable admin immunity for restricting buildings in TF2.");

    g_hLimits[2][0] = CreateConVar("sm_buildlimit_red_dispensers",         "1", "Limit for Red dispensers in TF2.");
    g_hLimits[2][1] = CreateConVar("sm_buildlimit_red_teleport_entrances", "1", "Limit for Red teleport entrances in TF2.");
    g_hLimits[2][2] = CreateConVar("sm_buildlimit_red_teleport_exits",     "1", "Limit for Red teleport exits in TF2.");
    g_hLimits[2][3] = CreateConVar("sm_buildlimit_red_sentries",           "1", "Limit for Red sentries in TF2.");
    g_hLimits[3][0] = CreateConVar("sm_buildlimit_blu_dispensers",         "1", "Limit for Blu dispensers in TF2.");
    g_hLimits[3][1] = CreateConVar("sm_buildlimit_blu_teleport_entrances", "1", "Limit for Blu teleport entrances in TF2.");
    g_hLimits[3][2] = CreateConVar("sm_buildlimit_blu_teleport_exits",     "1", "Limit for Blu teleport exits in TF2.");
    g_hLimits[3][3] = CreateConVar("sm_buildlimit_blu_sentries",           "1", "Limit for Blu sentries in TF2.");

    RegConsoleCmd("build", Command_Build, "Restrict buildings in TF2.");
}

public OnConfigsExecuted()
{
    levelFactor = GetConVarFloat(cvarFactor);
    defaultSpeed = GetConVarFloat(cvarSpeed);
    defaultJumpSpeed = GetConVarFloat(cvarJump);

    fallSpeed = GetConVarFloat(cvarFall);
    if (fallSpeed > 0)
        fallSpeed *= -1.0;
}

public OnMapStart()
{
    // start timer
    gTimer = CreateTimer(0.1, UpdateObjects, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

    g_iMaxEntities  = GetMaxEntities();
}

public OnMapEnd()
{
    CloseHandle(gTimer);
}

public RemoteCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (convar == cvarRemote)
    {
        new oldval = StringToInt(oldValue);
        new newval = StringToInt(newValue);
        if (newval != 0 && newval != 1)
        {
            PrintToServer("Value for sm_remote_enable is invalid %s, switching back to %s.", newValue, oldValue);
            SetConVarInt(cvarRemote, oldval);
            return;
        }
        else if (oldval == 1 && newval == 0)
        {
            for(new i=1;i<MaxClients;i++)
                remoteoff(i, 0);
        }
    }
    else if (convar == cvarSteal)
    {
        new oldval = StringToInt(oldValue);
        new newval = StringToInt(newValue);
        if (newval != 0 && newval != 1)
        {
            PrintToServer("Value for sm_remote_steal is invalid %s, switching back to %s.", newValue, oldValue);
            SetConVarInt(cvarSteal, oldval);
            return;
        }
    }
    else if (convar == cvarBuild)
    {
        new oldval = StringToInt(oldValue);
        new newval = StringToInt(newValue);
        if (newval != 0 && newval != 1)
        {
            PrintToServer("Value for sm_remote_build is invalid %s, switching back to %s.", newValue, oldValue);
            SetConVarInt(cvarBuild, oldval);
            return;
        }
    }
    else if (convar == cvarSpeed)
        defaultSpeed = StringToFloat(newValue);
    else if (convar == cvarJump)
        defaultJumpSpeed = StringToFloat(newValue);
    else if (convar == cvarFall)
    {
        fallSpeed = StringToFloat(newValue);
        if (fallSpeed > 0)
            fallSpeed *= -1.0;
    }
    else if (convar == cvarFactor)
        levelFactor = StringToFloat(newValue);
}

public Action:UpdateObjects(Handle:timer)
{
    decl String:classname[50];

    for (new i=1;i<MaxClients;i++)
    {
        new object = isRemoting[i];
        if (object && IsClientInGame(i))
        {
            if (!IsValidEntity(object))
                remoteoff(i, 0);
            else if (!GetEdictClassname(object, classname, sizeof(classname)) ||
                     GetObjectTypeFromEdictClass(classname) != remoteType[i])
            {
                remoteoff(i, 0);
            }
            else if (GetEntPropEnt(object, Prop_Send, "m_hBuilder") != i)
                remoteoff(i, 0);
            else
            {
                new Float:speed = (clientSpeed[i] > 0.0) ? clientSpeed[i] : defaultSpeed;
                new level = GetEntProp(object, Prop_Send, "m_iUpgradeLevel");
                if (level > 0)
                    speed *= levelFactor * float(4-level);

                new Float:nspeed = speed * -1.0;

                new Float:angles[3];
                GetClientEyeAngles(i, angles);
                angles[0] = 0.0;

                new Float:fwdvec[3];
                new Float:rightvec[3];
                new Float:upvec[3];
                GetAngleVectors(angles, fwdvec, rightvec, upvec);

                new Float:vel[3];
                vel[2] = fallSpeed;

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

                /*
                new Float:objectpos[3];
                GetEntPropVector(isRemoting[i], Prop_Data, "m_vecOrigin", objectpos);

                objectpos[0] += fwdvec[0] * -150.0;
                objectpos[1] += fwdvec[1] * -150.0;
                objectpos[2] += upvec[2] * 75.0;

                TeleportEntity(watcherEntity[i], objectpos, angles, NULL_VECTOR);
                */
            }
        }
    }
    return Plugin_Continue;
}

public Action:remote(client, args)
{
    if (isRemoting[client] != 0)
        remoteoff(client, args);
    else
    {
        decl String:arg[64];
        GetCmdArg(0, arg, sizeof(arg));

        new objects:type = unknown;
        if (StrEqual(arg, "sm_sentry"))
            type = sentrygun;
        else if (StrEqual(arg, "sm_disp"))
            type = dispenser;
        else if (StrEqual(arg, "sm_enter"))
            type = teleporter_entry;
        else if (StrEqual(arg, "sm_exit"))
            type = teleporter_exit;
        else if (GetCmdArgs() >= 1)
        {
            GetCmdArg(1, arg, sizeof(arg));
            new value = StringToInt(arg);
            if (value >= 1)
                type = objects:(value-1);
            else
            {
                if (StrEqual(arg, "sentry"))
                    type = sentrygun;
                else if (StrEqual(arg, "disp"))
                    type = dispenser;
                else if (StrEqual(arg, "enter"))
                    type = teleporter_entry;
                else if (StrEqual(arg, "exit"))
                    type = teleporter_exit;
            }
        }
        remoteControl(client, type);
    }

    return Plugin_Handled;
}

public Action:remoteon(client, args)
{
    remoteControl(client, unknown);
    return Plugin_Handled;
}

remoteControl(client, objects:type)
{
    new permissions = clientPermissions[client];
    if (permissions < 0)
    {
        if (!GetConVarBool(cvarRemote))
        {
            PrintToChat(client, "Remoting is not enabled.");
            return;
        }
        else if (TF2_GetPlayerClass(client) != TFClass_Engineer)
        {
            PrintToChat(client, "You are not an engineer.");
            return;
        }
        else
        {
            if (GetConVarBool(cvarSteal))
                permissions |= CAN_STEAL;

            if (GetConVarBool(cvarBuild))
                permissions |= CAN_BUILD;
        }
    }
    else if (permissions == 0)
    {
        PrintToChat(client, "You are not authorized to use remote controls.");
        return;
    }

    if (type == unknown)
    {
        new target = GetClientAimTarget(client);
        if (target > 0) 
        {
            type = GetObjectType(target);
            if (type != unknown)
            {
                if ((permissions & CAN_STEAL) ||
                    GetEntPropEnt(target,  Prop_Send, "m_hBuilder") == client)
                {
                    control(client, target, type);
                }
                else
                {
                    PrintToChat(client, "You don't own that!");
                }
                return;
            }
        }

        new Handle:menu=CreateMenu(ObjectSelected);
        SetMenuTitle(menu,"Remote Control which Building:");

        new count = AddBuildingsToMenu(client, menu, false, target);
        if (count == 1)
            control(client, target, GetObjectType(target));
        else if (count > 0)
            DisplayMenu(menu,client,MENU_TIME_FOREVER);
        else
        {
            CancelMenu(menu);
            if (permissions & CAN_BUILD)
            {
                menu=CreateMenu(BuildSelected);
                SetMenuTitle(menu,"Build & Remote Control:");

                new counts[5];
                CountBuildings(client, counts);

                AddMenuItem(menu,"0","Dispenser", (counts[0] > g_iAllowed[client][0]) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
                AddMenuItem(menu,"1","Teleporter Entry", (counts[1] > g_iAllowed[client][1]) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
                AddMenuItem(menu,"2","Teleporter Exit", (counts[2] > g_iAllowed[client][2]) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
                AddMenuItem(menu,"3","Level 1 Sentry Gun", (counts[3] > g_iAllowed[client][3]) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
                AddMenuItem(menu,"4","Level 2 Sentry Gun", (counts[3] > g_iAllowed[client][3]) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
                AddMenuItem(menu,"5","Level 3 Sentry Gun", (counts[3] > g_iAllowed[client][3]) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
                DisplayMenu(menu,client,MENU_TIME_FOREVER);
            }
            else
                PrintToChat(client, "You have nothing to remote control!");
        }
    }
    else
    {
        decl String:classname[50];

        new objectid = -1;
        for (new i=MaxClients+1;i<g_iMaxEntities;i++)
        {
            if (IsValidEntity(i))
            {
                if (GetEdictClassname(i, classname, sizeof(classname)) &&
                    GetObjectTypeFromEdictClass(classname) == type)
                {
                    if (GetEntPropEnt(i,  Prop_Send, "m_hBuilder") == client)
                    {
                        objectid = i;
                        break;
                    }
                }
            }
        }

        if (objectid <= 0 && (permissions & CAN_BUILD))
        {
            if (TF2_GetPlayerClass(client) == TFClass_Engineer)
                ClientCommand(client, "build %d", type);
            else
            {
                new Float:pos[3];
                GetClientAbsOrigin(client, pos);

                new Float:angles[3];
                GetClientAbsAngles(client, angles);

                switch (type)
                {
                    case dispenser:         objectid = BuildDispenser(client, pos, angles);
                    case teleporter_entry:  objectid = BuildTeleporterEntry(client, pos, angles);
                    case teleporter_exit:   objectid = BuildTeleporterExit(client, pos, angles);
                    case sentrygun:         objectid = BuildSentry(client, pos, angles);
                }

                // Move player up ontop of new object
                new Float:size[3];
                GetEntPropVector(objectid, Prop_Send, "m_vecBuildMaxs", size);

                pos[2] += size[2] * 1.1;
                TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
            }
        }

        if (objectid > 0)
            control(client, objectid, type);
        else
            PrintToChat(client, "%s not found!", TF2_ObjectNames[type]);
    }
}

public BuildSelected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        decl String:SelectionInfo[11];
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));

        new item = StringToInt(SelectionInfo);
        if (item == 4)
            DestroyBuilding(client);
        else if (TF2_GetPlayerClass(client) == TFClass_Engineer)
            ClientCommand(client, "build %d", item);
        else
        {
            new Float:pos[3];
            GetClientAbsOrigin(client, pos);

            new Float:angles[3];
            GetClientAbsAngles(client, angles);

            new objectid = -1;
            switch (selection)
            {
                case 0: objectid = BuildDispenser(client, pos, angles);
                case 1: objectid = BuildTeleporterEntry(client, pos, angles);
                case 2: objectid = BuildTeleporterExit(client, pos, angles);
                case 3: objectid = BuildSentry(client, pos, angles, 1);
                case 4:
                {
                    objectid = BuildSentry(client, pos, angles, 2);
                    selection = _:sentrygun;
                }
                case 5:
                {
                    objectid = BuildSentry(client, pos, angles, 3);
                    selection = _:sentrygun;
                }
            }

            if (objectid > 0)
            {
                // Move player up ontop of new object
                new Float:size[3];
                GetEntPropVector(objectid, Prop_Send, "m_vecBuildMaxs", size);

                pos[2] += size[2] * 1.1;
                TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);

                control(client, objectid, objects:selection);
            }
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public ObjectSelected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        decl String:SelectionInfo[11];
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));
        new objectid = StringToInt(SelectionInfo);
        control(client, objectid, GetObjectType(objectid));
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

control(client, objectid, objects:type)
{
    new Action:res = Plugin_Continue;
    if (gControlObjectHooked)
    {
        Call_StartForward(fwdOnControlObject);
        Call_PushCell(client);
        Call_PushCell(client); // builder);
        Call_PushCell(objectid);
        Call_Finish(res);
    }

    if (res == Plugin_Continue)
    {
        SetEntityMoveType(objectid, MOVETYPE_STEP);
        SetEntityMoveType(client, MOVETYPE_STEP);
        isRemoting[client] = objectid;
        remoteType[client] = type;

        new watcher = watcherEntity[client] = CreateEntityByName("info_observer_point");
        DispatchSpawn(watcher);

        new Float:angles[3];
        GetClientEyeAngles(client, angles);
        angles[0] = 0.0;

        new Float:fwdvec[3];
        new Float:rightvec[3];
        new Float:upvec[3];
        GetAngleVectors(angles, fwdvec, rightvec, upvec);

        new Float:pos[3];
        GetEntPropVector(objectid, Prop_Data, "m_vecOrigin", pos);
        pos[0] += fwdvec[0] * -150.0;
        pos[1] += fwdvec[1] * -150.0;
        pos[2] += upvec[2] * 75.0;

        TeleportEntity(watcher, pos, angles, NULL_VECTOR);

        SetClientViewEntity(client, watcher);

        // Set the watcher's parent to the object.
        new String:strTargetName[64]
        IntToString(objectid, strTargetName, 64)
    
        DispatchKeyValue(objectid, "targetname", strTargetName)
        
        SetVariantString(strTargetName)
        AcceptEntityInput(watcher, "SetParent", -1, -1, 0)
    }
}

public Action:remoteoff(client, args)
{
    decl String:classname[50];

    new watcher = watcherEntity[client];
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
                GetObjectTypeFromEdictClass(classname) == remoteType[client])
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
    watcherEntity[client] = 0;
    return Plugin_Handled;
}

public Action:remotegod(client, args)
{
    new building = isRemoting[client];
    if (building < 0)
    {
        PrintToChat(client, "Not controlling a building!");
    }
    else
    {
        if (GetEntProp(building, Prop_Data, "m_takedamage", 1)) // mortal
        {
            SetEntProp(building, Prop_Data, "m_takedamage", 0, 1);
            PrintToChat(client,"\x01\x04Building god mode on");
        }
        else // godmode
        {
            SetEntProp(building, Prop_Data, "m_takedamage", 1, 1);
            PrintToChat(client,"\x01\x04Building god mode off");
        }
    }
}

/**
 * Description: Build Restrictions for TF2
 * Author(s): Tsunami
 */

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
    for (new i=0; i < sizeof(g_iAllowed[]); i++)
        g_iAllowed[client][i] = 1;

    return true;
}

public OnClientDisconnect(client)
{
    for (new i=0; i < sizeof(g_iAllowed[]); i++)
        g_iAllowed[client][i] = 1;
}

public Action:Command_Build(client, args)
{
    new Action:iResult = Plugin_Continue;

    if (g_bNativeControl || !client || 
        (GetConVarBool(g_hBuildEnabled) &&
         (!(GetConVarBool(g_hBuildImmunity) &&
           (GetUserFlagBits(client) & ADMFLAG_GENERIC|ADMFLAG_ROOT)))))
    {
        decl String:sObject[2];
        GetCmdArg(1, sObject, sizeof(sObject));

        new iObject = StringToInt(sObject);
        new iTeam   = GetClientTeam(client);
        if (iObject < TF_OBJECT_DISPENSER || iObject > TF_OBJECT_SENTRY || iTeam < TF_TEAM_RED)
            return Plugin_Continue;

        new iCount;
        if (!CheckBuild(client, iObject, iCount))
            return Plugin_Handled;

        if (g_bNativeControl && g_bBuildHooked)
        {
            Call_StartForward(g_fwdOnBuild);
            Call_PushCell(client);
            Call_PushCell(iObject);
            Call_PushCell(iCount);
            Call_Finish(iResult);
        }
    }

    return iResult;
}

bool:CheckBuild(client, iObject, &iCount)
{
    if (iObject >= 4) // Don't check sappers or invalid objects
    {
        iCount = -1;
        return true;
    }
    else
    {
        new iLimit = g_bNativeControl ? g_iAllowed[client][iObject]
                                      : GetConVarInt(g_hLimits[GetClientTeam(client)][iObject]);
        if (iLimit == 0)
        {
            iCount = -1;
            return false;
        }
        else if (iLimit > 0)
        {
            iCount = 0;
            decl String:sClassName[32];
            for (new i = MaxClients + 1; i < g_iMaxEntities; i++)
            {
                if (IsValidEntity(i))
                {
                    GetEntityNetClass(i, sClassName, sizeof(sClassName));

                    if (0        == strncmp(sClassName, "CObject", 7)            &&
                        iObject  == GetEntProp(i,    Prop_Send, "m_iObjectType") &&
                        client   == GetEntPropEnt(i, Prop_Send, "m_hBuilder")    &&
                        ++iCount >= iLimit)
                    {
                        return false;
                    }
                }
            }
        }
        else
            iCount = -1;
    }
    return true;
}

/**
 * Description: Native Interface
 */

public Native_ControlRemote(Handle:plugin,numParams)
{
    SetConVarInt(cvarRemote, 0);
}

public Native_SetRemoteControl(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        clientPermissions[client] = (numParams >= 2) ? (GetNativeCell(2)) : -1;
        clientSpeed[client] = (numParams >= 3) ? (Float:GetNativeCell(3)) : -1.0;
        clientJumpSpeed[client] = (numParams >= 4) ? (Float:GetNativeCell(4)) : -1.0;
    }
}

public Native_ControlObject(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        remote(client, 0);
    }
}

public Native_HookControlObject(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        AddToForward(fwdOnControlObject, plugin, Function:GetNativeCell(1));
        gControlObjectHooked = true;
    }
}

/**
 * Description: Native Interface for Build
 */

public Native_BuildSentry(Handle:plugin,numParams)
{
    new Float:fOrigin[3], Float:fAngle[3];
    GetNativeArray(2, fOrigin, sizeof(fOrigin));
    GetNativeArray(3, fAngle, sizeof(fAngle));
    return BuildSentry(GetNativeCell(1), fOrigin, fAngle, GetNativeCell(4),
                       GetNativeCell(5), GetNativeCell(6), GetNativeCell(7),
                       GetNativeCell(8), GetNativeCell(9));
}

public Native_BuildDispenser(Handle:plugin,numParams)
{
    new Float:fOrigin[3], Float:fAngle[3];
    GetNativeArray(2, fOrigin, sizeof(fOrigin));
    GetNativeArray(3, fAngle, sizeof(fAngle));
    return BuildDispenser(GetNativeCell(1), fOrigin, fAngle, GetNativeCell(4),
                          GetNativeCell(5), GetNativeCell(6), GetNativeCell(7));
}

public N_BuildBuildTeleporterEntry(Handle:plugin,numParams)
{
    new Float:fOrigin[3], Float:fAngle[3];
    GetNativeArray(2, fOrigin, sizeof(fOrigin));
    GetNativeArray(3, fAngle, sizeof(fAngle));
    return BuildTeleporterEntry(GetNativeCell(1), fOrigin, fAngle, GetNativeCell(4),
                                GetNativeCell(5), GetNativeCell(6));
}

public N_BuildBuildTeleporterExit(Handle:plugin,numParams)
{
    new Float:fOrigin[3], Float:fAngle[3];
    GetNativeArray(2, fOrigin, sizeof(fOrigin));
    GetNativeArray(3, fAngle, sizeof(fAngle));
    return BuildTeleporterExit(GetNativeCell(1), fOrigin, fAngle, GetNativeCell(4),
                               GetNativeCell(5), GetNativeCell(6));
}

/**
 * Description: Native Interface for Build Limit
 */

public Native_ControlBuild(Handle:plugin,numParams)
{
    if (numParams == 0)
        g_bNativeControl = true;
    else if (numParams == 1)
        g_bNativeControl = GetNativeCell(1);
}

public Native_GiveBuild(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        g_iAllowed[client][3] = (numParams >= 2) ? GetNativeCell(2) : 1; // sentry
        g_iAllowed[client][0] = (numParams >= 3) ? GetNativeCell(3) : 1; // dispenser
        g_iAllowed[client][1] = (numParams >= 4) ? GetNativeCell(4) : 1; // teleporter_entry
        g_iAllowed[client][2] = (numParams >= 5) ? GetNativeCell(5) : 1; // teleporter_exit
    }
}

public Native_ResetBuild(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        for (new i=0; i < sizeof(g_iAllowed[]); i++)
            g_iAllowed[client][i] = 1;
    }
}

public Native_CheckBuild(Handle:plugin,numParams)
{
    if (numParams >= 2)
    {
        new iCount;
        new bool:result = CheckBuild(GetNativeCell(1), GetNativeCell(2), iCount);

        if (numParams >= 3)
            SetNativeCellRef(3, iCount);

        return result;
    }
    else
        return false;
}

public Native_HookBuild(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        AddToForward(g_fwdOnBuild, plugin, Function:GetNativeCell(1));
        g_bBuildHooked = true;
    }
}

//#include <tf2_build>
/**
 * Description: Functions to spawn buildings.
 */
 
stock BuildSentry(iBuilder, Float:fOrigin[3], Float:fAngle[3], iLevel=1,
                  bool:iDisabled=false, iHealth=-1, iMaxHealth=-1,
                  iShells=-1, iRockets=-1)
{
    decl String:sModel[64];

    new Float:fBuildMaxs[3] = { 24.0, 24.0, 66.0 };
    //new Float:fMdlWidth[3] = { 1.0, 0.5, 0.0 };

    new iTeam = GetClientTeam(iBuilder);

    if (iLevel < 0)
        iLevel = 0;
    else if (iLevel > 5)
        iLevel = 5;

    switch (iLevel)
    {
        case 0:
        {
            sModel = "models/buildables/sentry1.mdl";
            iRockets = 0;
            iShells = 0;
            iLevel = 1;

            if (iMaxHealth < 0)
                iMaxHealth = 150;

            if (iHealth < 0 || iHealth > iMaxHealth)
                iHealth = iMaxHealth;
        }
        case 1:
        {
            sModel = "models/buildables/sentry1.mdl";
            iRockets = 0;

            if (iShells < 0)
                iShells = 100;

            if (iMaxHealth < 0)
                iMaxHealth = 150;

            if (iHealth < 0 || iHealth > iMaxHealth)
                iHealth = iMaxHealth;
        }
        case 2:
        {
            sModel = "models/buildables/sentry2.mdl";
            iRockets = 0;

            if (iShells < 0)
                iShells = 120;

            if (iMaxHealth < 0)
                iMaxHealth = 180;

            if (iHealth < 0 || iHealth > iMaxHealth)
                iHealth = iMaxHealth;
        }
        case 3:
        {
            sModel = "models/buildables/sentry3.mdl";
            if (iShells < 0)
                iShells = 144;

            if (iRockets < 0)
                iRockets = 20;

            if (iMaxHealth < 0)
                iMaxHealth = 216;

            if (iHealth < 0 || iHealth > iMaxHealth)
                iHealth = iMaxHealth;
        }
        case 4:
        {
            sModel = "models/buildables/sentry3.mdl";
            iLevel = 3;
            if (iShells < 0)
                iShells = 288;

            if (iRockets < 0)
                iRockets = 40;

            if (iMaxHealth < 0)
                iMaxHealth = 450;

            if (iHealth < 0 || iHealth > iMaxHealth)
                iHealth = iMaxHealth;
        }
        case 5:
        {
            sModel = "models/buildables/sentry3.mdl";
            iLevel = 3;
            if (iShells < 0)
                iShells = 511;

            if (iRockets < 0)
                iRockets = 63;

            if (iMaxHealth < 0)
                iMaxHealth = 600;

            if (iHealth < 0 || iHealth > iMaxHealth)
                iHealth = iMaxHealth;
        }
    }

    new iSentry = CreateEntityByName("obj_sentrygun");

    DispatchSpawn(iSentry);

    TeleportEntity(iSentry, fOrigin, fAngle, NULL_VECTOR);

    SetEntityModel(iSentry,sModel);

    SetEntProp(iSentry, Prop_Send, "m_nNewSequenceParity", 		        4, 4);
    SetEntProp(iSentry, Prop_Send, "m_nResetEventsParity", 		        4, 4);
    SetEntProp(iSentry, Prop_Send, "m_iAmmoShells" , 				    iShells, 4);
    SetEntProp(iSentry, Prop_Send, "m_iMaxHealth", 				        iMaxHealth, 4);
    SetEntProp(iSentry, Prop_Send, "m_iHealth", 					    iHealth, 4);
    SetEntProp(iSentry, Prop_Send, "m_bBuilding", 				        0, 2);
    SetEntProp(iSentry, Prop_Send, "m_bPlacing", 					    0, 2);
    SetEntProp(iSentry, Prop_Send, "m_bDisabled", 				        iDisabled, 2);
    SetEntProp(iSentry, Prop_Send, "m_iObjectType", 				    _:sentrygun, 1);
    SetEntProp(iSentry, Prop_Send, "m_iState", 					        1, 1);
    SetEntProp(iSentry, Prop_Send, "m_iUpgradeMetal", 			        0, 2);
    SetEntProp(iSentry, Prop_Send, "m_bHasSapper", 				        0, 2);
    SetEntProp(iSentry, Prop_Send, "m_nSkin", 					        (iTeam-2), 1);
    SetEntProp(iSentry, Prop_Send, "m_bServerOverridePlacement", 	    1, 1);
    SetEntProp(iSentry, Prop_Send, "m_iUpgradeLevel", 			        iLevel, 4);
    SetEntProp(iSentry, Prop_Send, "m_iAmmoRockets", 				    iRockets, 4);

    SetEntPropEnt(iSentry, Prop_Send, "m_nSequence",                    0);
    SetEntPropEnt(iSentry, Prop_Send, "m_hBuilder", 	                iBuilder);

    SetEntPropFloat(iSentry, Prop_Send, "m_flCycle", 					0.0);
    SetEntPropFloat(iSentry, Prop_Send, "m_flPlaybackRate", 			1.0);
    SetEntPropFloat(iSentry, Prop_Send, "m_flPercentageConstructed", 	1.0);
    SetEntPropFloat(iSentry, Prop_Send, "m_flModelWidthScale", 	        1.0);

    SetEntPropVector(iSentry, Prop_Send, "m_vecOrigin", 			    fOrigin);
    SetEntPropVector(iSentry, Prop_Send, "m_angRotation", 		        fAngle);
    SetEntPropVector(iSentry, Prop_Send, "m_vecBuildMaxs", 		        fBuildMaxs);
    //SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_flModelWidthScale"),	fMdlWidth, true);

    SetVariantInt(iTeam);
    AcceptEntityInput(iSentry, "TeamNum", -1, -1, 0);

    SetVariantInt(iTeam);
    AcceptEntityInput(iSentry, "SetTeam", -1, -1, 0); 

    new Handle:event = CreateEvent("player_builtobject");
    if (event != INVALID_HANDLE)
    {
        SetEventInt(event, "userid", GetClientUserId(iBuilder));
        SetEventInt(event, "object", _:sentrygun);
        SetEventBool(event, "sourcemod", true);
        FireEvent(event);
    }
    return iSentry;
}

stock BuildDispenser(iBuilder, Float:fOrigin[3], Float:fAngle[3],
                     bool:iDisabled=false, iHealth=-1, iMaxHealth=-1,
                     iMetal=-1)
{
    new Float:fBuildMaxs[3] = { 24.0, 24.0, 66.0 };

    new iTeam = GetClientTeam(iBuilder);

    if (iMaxHealth < 0)
        iMaxHealth = 150;

    if (iHealth < 0 || iHealth > iMaxHealth)
        iHealth = iMaxHealth;

    if (iMetal < 0)
        iMetal = 1000;

    new iDispenser = CreateEntityByName("obj_dispenser");

    DispatchSpawn(iDispenser);

    TeleportEntity(iDispenser, fOrigin, fAngle, NULL_VECTOR);

    SetEntityModel(iDispenser,"models/buildables/dispenser_light.mdl");

    SetEntProp(iDispenser, Prop_Send, "m_nNewSequenceParity", 		        4, 4);
    SetEntProp(iDispenser, Prop_Send, "m_nResetEventsParity", 		        4, 4);
    SetEntProp(iDispenser, Prop_Send, "m_iMaxHealth", 				        iMaxHealth, 4);
    SetEntProp(iDispenser, Prop_Send, "m_iHealth", 				            iHealth, 4);
    SetEntProp(iDispenser, Prop_Send, "m_iAmmoMetal", 				        iMetal, 4);
    SetEntProp(iDispenser, Prop_Send, "m_bBuilding", 				        0, 2);
    SetEntProp(iDispenser, Prop_Send, "m_bPlacing", 				        0, 2);
    SetEntProp(iDispenser, Prop_Send, "m_bDisabled", 				        iDisabled, 2);
    SetEntProp(iDispenser, Prop_Send, "m_iObjectType", 			            _:dispenser, 1);
    SetEntProp(iDispenser, Prop_Send, "m_bHasSapper", 				        0, 2);
    SetEntProp(iDispenser, Prop_Send, "m_nSkin", 					        (iTeam-2), 1);
    SetEntProp(iDispenser, Prop_Send, "m_bServerOverridePlacement",         1, 1);

    SetEntPropEnt(iDispenser, Prop_Send, "m_nSequence",                     0);
    SetEntPropEnt(iDispenser, Prop_Send, "m_hBuilder",                      iBuilder);

    SetEntPropFloat(iDispenser, Prop_Send, "m_flCycle", 					0.0);
    SetEntPropFloat(iDispenser, Prop_Send, "m_flPlaybackRate", 			    1.0);
    SetEntPropFloat(iDispenser, Prop_Send, "m_flPercentageConstructed", 	1.0);
    SetEntPropFloat(iDispenser, Prop_Send, "m_flModelWidthScale", 	        1.0);

    SetEntPropVector(iDispenser, Prop_Send, "m_vecOrigin", 		            fOrigin);
    SetEntPropVector(iDispenser, Prop_Send, "m_angRotation", 		        fAngle);
    SetEntPropVector(iDispenser, Prop_Send, "m_vecBuildMaxs",		        fBuildMaxs);

    SetVariantInt(iTeam);
    AcceptEntityInput(iDispenser, "TeamNum", -1, -1, 0);

    SetVariantInt(iTeam);
    AcceptEntityInput(iDispenser, "SetTeam", -1, -1, 0);

    if (!iDisabled)
        AcceptEntityInput(iDispenser, "TurnOn");

    new Handle:event = CreateEvent("player_builtobject");
    if (event != INVALID_HANDLE)
    {
        SetEventInt(event, "userid", GetClientUserId(iBuilder));
        SetEventInt(event, "object", _:dispenser);
        SetEventBool(event, "sourcemod", true);
        FireEvent(event);
    }
    return iDispenser;
}

stock BuildTeleporterEntry(iBuilder, Float:fOrigin[3], Float:fAngle[3],
                           bool:iDisabled=false, iHealth=-1, iMaxHealth=-1)
{
    new Float:fBuildMaxs[3] = { 28.0, 28.0, 66.0 };
    //new Float:fMdlWidth[3] = { 1.0, 0.5, 0.0 };

    new iTeam = GetClientTeam(iBuilder);

    if (iMaxHealth < 0)
        iMaxHealth = 150;

    if (iHealth < 0 || iHealth > iMaxHealth)
        iHealth = iMaxHealth;

    new iTeleporter = CreateEntityByName("obj_teleporter_entrance");

    DispatchSpawn(iTeleporter);

    TeleportEntity(iTeleporter, fOrigin, fAngle, NULL_VECTOR);

    SetEntityModel(iTeleporter,"models/buildables/teleporter_light.mdl");

    SetEntProp(iTeleporter, Prop_Send, "m_nNewSequenceParity", 		        4, 4);
    SetEntProp(iTeleporter, Prop_Send, "m_nResetEventsParity", 		        4, 4);
    SetEntProp(iTeleporter, Prop_Send, "m_iMaxHealth", 				        iMaxHealth, 4);
    SetEntProp(iTeleporter, Prop_Send, "m_iHealth", 					    iHealth, 4);
    SetEntProp(iTeleporter, Prop_Send, "m_bBuilding", 				        0, 2);
    SetEntProp(iTeleporter, Prop_Send, "m_bPlacing", 					    0, 2);
    SetEntProp(iTeleporter, Prop_Send, "m_bDisabled", 				        iDisabled, 2);
    SetEntProp(iTeleporter, Prop_Send, "m_iObjectType", 				    _:teleporter_entry, 1);
    SetEntProp(iTeleporter, Prop_Send, "m_bHasSapper", 				        0, 2);
    SetEntProp(iTeleporter, Prop_Send, "m_nSkin", 					        (iTeam-2), 1);
    SetEntProp(iTeleporter, Prop_Send, "m_bServerOverridePlacement", 	    1, 1);
    SetEntProp(iTeleporter, Prop_Send, "m_iState", 	                        1, 1);

    SetEntPropEnt(iTeleporter, Prop_Send, "m_nSequence",                    0);
    SetEntPropEnt(iTeleporter, Prop_Send, "m_hBuilder", 	                iBuilder);

    SetEntPropFloat(iTeleporter, Prop_Send, "m_flCycle", 					0.0);
    SetEntPropFloat(iTeleporter, Prop_Send, "m_flPlaybackRate", 			1.0);
    SetEntPropFloat(iTeleporter, Prop_Send, "m_flPercentageConstructed", 	1.0);
    SetEntPropFloat(iTeleporter, Prop_Send, "m_flModelWidthScale", 	        1.0);

    SetEntPropVector(iTeleporter, Prop_Send, "m_vecOrigin", 			    fOrigin);
    SetEntPropVector(iTeleporter, Prop_Send, "m_angRotation", 		        fAngle);
    SetEntPropVector(iTeleporter, Prop_Send, "m_vecBuildMaxs", 		        fBuildMaxs);

    SetVariantInt(iTeam);
    AcceptEntityInput(iTeleporter, "TeamNum", -1, -1, 0);

    SetVariantInt(iTeam);
    AcceptEntityInput(iTeleporter, "SetTeam", -1, -1, 0); 

    if (!iDisabled)
        AcceptEntityInput(iTeleporter, "TurnOn");

    new Handle:event = CreateEvent("player_builtobject");
    if (event != INVALID_HANDLE)
    {
        SetEventInt(event, "userid", GetClientUserId(iBuilder));
        SetEventInt(event, "object", _:teleporter_entry);
        SetEventBool(event, "sourcemod", true);
        FireEvent(event);
    }
    return iTeleporter;
}

stock BuildTeleporterExit(iBuilder, Float:fOrigin[3], Float:fAngle[3],
                          bool:iDisabled=false, iHealth=-1, iMaxHealth=-1)
{
    new Float:fBuildMaxs[3] = { 28.0, 28.0, 66.0 };

    new iTeam = GetClientTeam(iBuilder);

    if (iMaxHealth < 0)
        iMaxHealth = 150;

    if (iHealth < 0 || iHealth > iMaxHealth)
        iHealth = iMaxHealth;

    new iTeleporter = CreateEntityByName("obj_teleporter_exit");

    DispatchSpawn(iTeleporter);

    TeleportEntity(iTeleporter, fOrigin, fAngle, NULL_VECTOR);

    SetEntityModel(iTeleporter,"models/buildables/teleporter_light.mdl");

    SetEntProp(iTeleporter, Prop_Send, "m_nNewSequenceParity", 		        4, 4 );
    SetEntProp(iTeleporter, Prop_Send, "m_nResetEventsParity", 		        4, 4 );
    SetEntProp(iTeleporter, Prop_Send, "m_iMaxHealth", 				        iMaxHealth, 4);
    SetEntProp(iTeleporter, Prop_Send, "m_iHealth", 				        iHealth, 4);
    SetEntProp(iTeleporter, Prop_Send, "m_bBuilding", 				        0, 2);
    SetEntProp(iTeleporter, Prop_Send, "m_bPlacing", 				        0, 2);
    SetEntProp(iTeleporter, Prop_Send, "m_bDisabled", 				        iDisabled, 2);
    SetEntProp(iTeleporter, Prop_Send, "m_iObjectType", 			        _:teleporter_exit, 1);
    SetEntProp(iTeleporter, Prop_Send, "m_bHasSapper", 				        0, 2);
    SetEntProp(iTeleporter, Prop_Send, "m_nSkin", 					        (iTeam-2), 1);
    SetEntProp(iTeleporter, Prop_Send, "m_bServerOverridePlacement", 	    1, 1);
    SetEntProp(iTeleporter, Prop_Send, "m_iState", 	                        1, 1);

    SetEntPropEnt(iTeleporter, Prop_Send, "m_nSequence",                    0);
    SetEntPropEnt(iTeleporter, Prop_Send, "m_hBuilder", 	                iBuilder);

    SetEntPropFloat(iTeleporter, Prop_Send, "m_flCycle", 					0.0);
    SetEntPropFloat(iTeleporter, Prop_Send, "m_flPlaybackRate", 			1.0);
    SetEntPropFloat(iTeleporter, Prop_Send, "m_flPercentageConstructed", 	1.0);
    SetEntPropFloat(iTeleporter, Prop_Send, "m_flModelWidthScale", 	        1.0);

    SetEntPropVector(iTeleporter, Prop_Send, "m_vecOrigin", 			    fOrigin);
    SetEntPropVector(iTeleporter, Prop_Send, "m_angRotation", 		        fAngle);
    SetEntPropVector(iTeleporter, Prop_Send, "m_vecBuildMaxs", 		        fBuildMaxs);

    SetVariantInt(iTeam);
    AcceptEntityInput(iTeleporter, "TeamNum", -1, -1, 0);

    SetVariantInt(iTeam);
    AcceptEntityInput(iTeleporter, "SetTeam", -1, -1, 0); 

    if (!iDisabled)
        AcceptEntityInput(iTeleporter, "TurnOn");

    new Handle:event = CreateEvent("player_builtobject");
    if (event != INVALID_HANDLE)
    {
        SetEventInt(event, "userid", GetClientUserId(iBuilder));
        SetEventInt(event, "object", _:teleporter_exit);
        SetEventBool(event, "sourcemod", true);
        FireEvent(event);
    }
    return iTeleporter;
}

stock CountBuildings(client, counts[5])
{
    decl String:className[32];
    counts[0] = counts[1] = counts[2] = counts[3] = counts[4] = 0;
    for (new i = MaxClients + 1; i < g_iMaxEntities; i++)
    {
        if (IsValidEntity(i))
        {
            GetEdictClassname(i, className, sizeof(className));

            if (strncmp(className, "CObject", 7) == 0 &&
                GetEntPropEnt(i, Prop_Send, "m_hBuilder") == client)
            {
                new object = GetEntProp(i, Prop_Send, "m_iObjectType");
                counts[object]++;
            }
        }
    }
}

stock AddBuildingsToMenu(client, Handle:menu, bool:all=false, &target=0)
{
    decl String:class[32], String:buf[11], String:item[64];

    new count=0;
    for (new i = MaxClients + 1; i <= g_iMaxEntities; i++)
    {
        if (IsValidEntity(i))
        {
            GetEdictClassname(i, class, sizeof(class));
            new objects:type=GetObjectTypeFromEdictClass(class);
            if (type != unknown)
            {
                if (GetEntPropEnt(i, Prop_Send, "m_hBuilder") == client &&
                    (all || (GetEntPropFloat(i, Prop_Send, "m_flPercentageConstructed") >= 1.0 &&
                             !GetEntProp(i, Prop_Send, "m_bDisabled"))))
                {
                    count++;
                    target=i;
                    IntToString(i, buf, sizeof(buf));
                    Format(item,sizeof(item),"%s (%d)", TF2_ObjectNames[type], i);
                    AddMenuItem(menu,buf,item);
                }
            }
        }
    }
    return count;
}

stock DestroyAllBuildings(client)
{
    decl String:class[32];

    new count=0;
    for (new i = MaxClients + 1; i <= g_iMaxEntities; i++)
    {
        if (IsValidEntity(i))
        {
            GetEdictClassname(i, class, sizeof(class));
            new objects:type=GetObjectTypeFromEdictClass(class);
            if (type != unknown)
            {
                if (GetEntPropEnt(i, Prop_Send, "m_hBuilder") == client)
                {
                    count++;
                    AcceptEntityInput(i, "Kill");
                }
            }
        }
    }
    return count;
}

stock bool:DestroyBuilding(client)
{
    new Handle:menu=CreateMenu(Destroy_Selected);
    SetMenuTitle(menu,"Destroy which Structure:");

    new count = AddBuildingsToMenu(client, menu);
    if (count > 0)
    {
        DisplayMenu(menu,client,MENU_TIME_FOREVER);
        return true;
    }
    else
    {
        CancelMenu(menu);
        return false;
    }
}

public Destroy_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        decl String:SelectionInfo[11];
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));

        new object = StringToInt(SelectionInfo);
        if (IsValidEntity(object))
        {
            decl String:class[32];
            GetEdictClassname(object, class, sizeof(class));
            new objects:type=GetObjectTypeFromEdictClass(class);
            if (type != unknown)
                AcceptEntityInput(object, "Kill");
        }
    }
}
/**
 * End of tf2_build
 */


/**
 * End of remote.sp
 */
