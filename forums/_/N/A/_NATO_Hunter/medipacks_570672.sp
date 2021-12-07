/*
 *
 *  TF2 Medipacks - SourceMod Plugin
 *  Copyright (C) 2009  Marc Hörsken
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 * 
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PL_VERSION "1.2.4"
#define SOUND_A "weapons/medigun_no_target.wav"
#define SOUND_B "items/spawn_item.wav"
#define SOUND_C "ui/hint.wav"

public Plugin:myinfo = 
{
    name = "TF2 Medipacks",
    author = "Hunter",
    description = "Allows medics to drop medipacks on death or with secondary Medigun fire.",
    version = PL_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=65315"
}

new bool:g_NativeControl = false;
new bool:g_MedicButtonDown[MAXPLAYERS+1];
new Float:g_MedicPosition[MAXPLAYERS+1][3];
new g_NativeMedipacks[MAXPLAYERS+1];
new g_NativeUberCharge[MAXPLAYERS+1];
new g_MedicUberCharge[MAXPLAYERS+1];
new g_MedipacksCount = 0;
new g_FilteredEntity = -1;
new Handle:g_IsMedipacksOn = INVALID_HANDLE;
new Handle:g_DefUberCharge = INVALID_HANDLE;
new Handle:g_MedipacksSmall = INVALID_HANDLE;
new Handle:g_MedipacksMedium = INVALID_HANDLE;
new Handle:g_MedipacksFull = INVALID_HANDLE;
new Handle:g_MedipacksKeep = INVALID_HANDLE;
new Handle:g_MedipacksTeam = INVALID_HANDLE;
new Handle:g_MedipacksLimit = INVALID_HANDLE;
new Handle:g_MedipacksTime = INVALID_HANDLE;

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("ControlMedipacks", Native_ControlMedipacks);
    CreateNative("SetMedipack", Native_SetMedipack);
    RegPluginLibrary("medipacks");

    return true;
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("medipacks.phrases");

    HookConVarChange(CreateConVar("sm_tf_medipacks", PL_VERSION, "Medipacks", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY), ConVarChange_Version);
    g_IsMedipacksOn = CreateConVar("sm_medipacks","3","Enable/Disable medipacks (0 = disabled | 1 = on death | 2 = on command | 3 = on death and command)", _, true, 0.0, true, 3.0);
    g_DefUberCharge = CreateConVar("sm_medipacks_ubercharge","25","Give medics a default UberCharge on spawn", _, true, 0.0, true, 100.0);
    g_MedipacksSmall = CreateConVar("sm_medipacks_small","10","UberCharge required for small Medipacks", _, true, 0.0, true, 100.0);
    g_MedipacksMedium = CreateConVar("sm_medipacks_medium","25","UberCharge required for medium Medipacks", _, true, 0.0, true, 100.0);
    g_MedipacksFull = CreateConVar("sm_medipacks_full","50","UberCharge required for full Medipacks", _, true, 0.0, true, 100.0);
    g_MedipacksKeep = CreateConVar("sm_medipacks_keep","60","Time to keep Medipacks on map. (0 = off | >0 = seconds)", _, true, 0.0, true, 600.0);
    g_MedipacksTeam = CreateConVar("sm_medipacks_team","3","Team to drop Medipacks for. (0 = any team | 1 = own team | 2 = opposing team | 3 = own on command, any on death)", _, true, 0.0, true, 3.0);
    g_MedipacksLimit = CreateConVar("sm_medipacks_limit","100","Maximum number of extra Medipacks on map at a time. (0 = unlimited)", _, true, 0.0, true, 512.0);
    g_MedipacksTime = CreateArray(_, GetMaxEntities());

    HookConVarChange(g_IsMedipacksOn, ConVarChange_IsMedipacksOn);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_changeclass", Event_PlayerClass);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_team", Event_PlayerTeam);
    HookEvent("teamplay_round_start", Event_TeamplayRoundStart);
    HookEntityOutput("item_healthkit_full", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);
    HookEntityOutput("item_healthkit_medium", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);
    HookEntityOutput("item_healthkit_small", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);
    RegConsoleCmd("sm_medipack", Command_Medipack);
    RegAdminCmd("sm_ubercharge", Command_UberCharge, ADMFLAG_CHEATS);

    CreateTimer(1.0, Timer_Caching, _, TIMER_REPEAT);

    AutoExecConfig(true);
}

public OnMapStart()
{
    PrecacheModel("models/items/medkit_large.mdl", true);
    PrecacheModel("models/items/medkit_medium.mdl", true);
    PrecacheModel("models/items/medkit_small.mdl", true);

    PrecacheSound(SOUND_A, true);
    PrecacheSound(SOUND_B, true);
    PrecacheSound(SOUND_C, true);

    ClearArray(g_MedipacksTime);
    ResizeArray(g_MedipacksTime, GetMaxEntities());
    g_MedipacksCount = 0;

    AutoExecConfig(true);
}

public OnClientDisconnect(client)
{
    g_MedicButtonDown[client] = false;
    g_MedicUberCharge[client] = 0;
    g_MedicPosition[client] = NULL_VECTOR;
}

public OnClientPutInServer(client)
{
    if(!g_NativeControl && GetConVarBool(g_IsMedipacksOn))
        CreateTimer(45.0, Timer_Advert, client);
}

public OnGameFrame()
{
    new MedipacksOn = GetConVarInt(g_IsMedipacksOn);
    if (MedipacksOn < 2 && !g_NativeControl)
        return;

    for (new i = 1; i <= MaxClients; i++)
    {
        if (g_NativeControl && g_NativeMedipacks[i] < 2)
            continue;

        if (!g_MedicButtonDown[i] && IsClientInGame(i) && TF2_GetPlayerClass(i) == TFClass_Medic)
        {
            if (GetClientButtons(i) & IN_ATTACK2)
            {
                g_MedicButtonDown[i] = true;
                CreateTimer(0.5, Timer_ButtonUp, i);
                new String:classname[64];
                TF_GetCurrentWeaponClass(i, classname, 64);
                if (StrEqual(classname, "CWeaponMedigun") && g_MedicUberCharge[i] < 100 && TF_IsUberCharge(i) == 0)
                    TF_DropMedipack(i, true);
            }
        }
    }
}

public ConVarChange_Version(Handle:convar, const String:oldValue[], const String:newValue[])
{
    SetConVarString(convar, PL_VERSION);
}

public ConVarChange_IsMedipacksOn(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (StringToInt(newValue) > 0)
        PrintToChatAll("[SM] %t", "Enabled Medipacks");
    else
        PrintToChatAll("[SM] %t", "Disabled Medipacks");
}

public Action:Command_Medipack(client, args)
{
    new MedipacksOn = g_NativeControl ? g_NativeMedipacks[client]
                                      : GetConVarInt(g_IsMedipacksOn);
    if (MedipacksOn < 2)
        return Plugin_Handled;

    new TFClassType:class = TF2_GetPlayerClass(client);
    if (class != TFClass_Medic)
        return Plugin_Handled;

    new String:classname[64];
    TF_GetCurrentWeaponClass(client, classname, 64);
    if(!StrEqual(classname, "CWeaponMedigun"))
        return Plugin_Handled;

    TF_DropMedipack(client, true);

    return Plugin_Handled;
}

public Action:Command_UberCharge(client, args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] %t", "UberCharge Usage");
        return Plugin_Handled;
    }

    new String:arg1[32], String:arg2[32];
    GetCmdArg(1, arg1, sizeof(arg1));

    new target = FindTarget(client, arg1);
    if (target == -1)
    {
        return Plugin_Handled;
    }

    new String:name[MAX_NAME_LENGTH];
    GetClientName(target, name, sizeof(name));

    new bool:alive = IsPlayerAlive(target);
    if (!alive)
    {
        ReplyToCommand(client, "[SM] %t", "Cannot be performed on dead", name);
        return Plugin_Handled;
    }

    new TFClassType:class = TF2_GetPlayerClass(target);
    if (class != TFClass_Medic)
    {
        ReplyToCommand(client, "[SM] %t", "Not a Medic", name);
        return Plugin_Handled;
    }

    new charge = 100;
    if (args > 1)
    {
        GetCmdArg(2, arg2, sizeof(arg2));
        charge = StringToInt(arg2);
        if (charge < 0 || charge > 100)
        {
            ReplyToCommand(client, "[SM] %t", "Invalid Amount");
            return Plugin_Handled;
        }
    }

    TF_SetUberLevel(target, charge);

    ReplyToCommand(client, "[SM] %t", "Changed UberCharge", name, charge);
    return Plugin_Handled;
}

public Action:Timer_Advert(Handle:timer, any:client)
{
    if (IsClientConnected(client) && IsClientInGame(client))
    {
        new MedipacksOn = GetConVarInt(g_IsMedipacksOn);
        switch (MedipacksOn)
        {
            case 1:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnDeath Medipacks");
            case 2:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnCommand Medipacks");
            case 3:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnDeathAndCommand Medipacks");
        }
    }
}

public Action:Timer_Caching(Handle:timer)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && TF2_GetPlayerClass(i) == TFClass_Medic)
        {
            g_MedicUberCharge[i] = TF_GetUberLevel(i);
            GetClientAbsOrigin(i, g_MedicPosition[i]);
        }
    }

    new MedipacksKeep = GetConVarInt(g_MedipacksKeep);
    if (MedipacksKeep > 0)
    {
        new mintime = GetTime() - MedipacksKeep;
        for (new c = MaxClients; c < GetMaxEntities(); c++)
        {
            new time = GetArrayCell(g_MedipacksTime, c);
            if (time > 0 && time < mintime)
            {
                SetArrayCell(g_MedipacksTime, c, 0);
                if (IsValidEdict(c))
                {
                    new String:classname[64];
                    GetEdictClassname(c, classname, 64);
                    if (!strncmp(classname, "item_healthkit", 14))
                    {
                        EmitSoundToAll(SOUND_C, c, _, _, _, 0.75);
                        RemoveEdict(c);
                        g_MedipacksCount--;
                    }
                }
            }
        }
    }
}

public Action:Timer_ButtonUp(Handle:timer, any:client)
{
    g_MedicButtonDown[client] = false;
}

public Action:Timer_PlayerDefDelay(Handle:timer, any:client)
{
    if (!IsClientInGame(client))
        return;

    new TFClassType:class = TF2_GetPlayerClass(client);
    if (class != TFClass_Medic)
        return;

    new DefUberCharge = g_NativeControl ? g_NativeUberCharge[client] : GetConVarInt(g_DefUberCharge);
    if (DefUberCharge)
        TF_SetUberLevel(client, DefUberCharge);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new TFClassType:class = TF2_GetPlayerClass(client);
    if (class != TFClass_Medic)
        return;

    CreateTimer(0.25, Timer_PlayerDefDelay, client);
}

public Action:Event_PlayerClass(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new any:class = GetEventInt(event, "class");
    if (class != TFClass_Medic)
        return;

    CreateTimer(0.25, Timer_PlayerDefDelay, client);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientInGame(client))
        return;

    new MedipacksOn = g_NativeControl ? g_NativeMedipacks[client] : GetConVarInt(g_IsMedipacksOn);
    if (MedipacksOn < 1 || MedipacksOn == 2)
        return;

    new TFClassType:class = TF2_GetPlayerClass(client);
    if (class != TFClass_Medic)
        return;

    TF_DropMedipack(client, false);
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    new disconnect = GetEventInt(event, "disconnect");
    if (disconnect)
        return;

    new team = GetEventInt(event, "team");
    if (team > 1)
        return;

    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientInGame(client))
        return;

    g_MedicButtonDown[client] = false;
    g_MedicUberCharge[client] = 0;
    g_MedicPosition[client] = NULL_VECTOR;
}

public Action:Event_TeamplayRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    new full_reset = GetEventInt(event, "full_reset");
    if (full_reset)
    {
        for (new c = MaxClients; c < GetMaxEntities(); c++)
        {
            new time = GetArrayCell(g_MedipacksTime, c);
            if (time > 0)
            {
                SetArrayCell(g_MedipacksTime, c, 0);
                g_MedipacksCount--;
            }
        }
    }
}

public Action:Entity_OnPlayerTouch(const String:output[], caller, activator, Float:delay)
{
    new time = GetArrayCell(g_MedipacksTime, caller);
    if (time > 0 && activator > 0)
    {
        SetArrayCell(g_MedipacksTime, caller, 0);
        g_MedipacksCount--;
    }
}

public bool:MedipackTraceFilter(ent, contentMask)
{
    return (ent != g_FilteredEntity);
}

stock TF_SpawnMedipack(client, String:name[], bool:cmd)
{
    new Float:PlayerPosition[3];
    if (cmd)
        GetClientAbsOrigin(client, PlayerPosition);
    else
        PlayerPosition = g_MedicPosition[client];

    if (PlayerPosition[0] != 0.0 && PlayerPosition[1] != 0.0 && PlayerPosition[2] != 0.0 && IsEntLimitReached() == false)
    {
        PlayerPosition[2] += 4;
        g_FilteredEntity = client;
        if (cmd)
        {
            new Float:PlayerPosEx[3], Float:PlayerAngle[3], Float:PlayerPosAway[3];
            GetClientEyeAngles(client, PlayerAngle);
            PlayerPosEx[0] = Cosine((PlayerAngle[1]/180)*FLOAT_PI);
            PlayerPosEx[1] = Sine((PlayerAngle[1]/180)*FLOAT_PI);
            PlayerPosEx[2] = 0.0;
            ScaleVector(PlayerPosEx, 75.0);
            AddVectors(PlayerPosition, PlayerPosEx, PlayerPosAway);

            new Handle:TraceEx = TR_TraceRayFilterEx(PlayerPosition, PlayerPosAway, MASK_SOLID, RayType_EndPoint, MedipackTraceFilter);
            TR_GetEndPosition(PlayerPosition, TraceEx);
            CloseHandle(TraceEx);
        }

        new Float:Direction[3];
        Direction[0] = PlayerPosition[0];
        Direction[1] = PlayerPosition[1];
        Direction[2] = PlayerPosition[2]-1024;
        new Handle:Trace = TR_TraceRayFilterEx(PlayerPosition, Direction, MASK_SOLID, RayType_EndPoint, MedipackTraceFilter);

        new Float:MediPos[3];
        TR_GetEndPosition(MediPos, Trace);
        CloseHandle(Trace);
        MediPos[2] += 4;

        new Medipack = CreateEntityByName(name);
        DispatchKeyValue(Medipack, "OnPlayerTouch", "!self,Kill,,0,-1");
        if (DispatchSpawn(Medipack))
        {
            new team = 0;
            new MedipacksTeam = GetConVarInt(g_MedipacksTeam);
            if (MedipacksTeam == 2)
                team = ((GetClientTeam(client)-1) % 2) + 2;
            else if (MedipacksTeam == 1 || (MedipacksTeam == 3 && cmd))
                team = GetClientTeam(client);

            SetEntProp(Medipack, Prop_Send, "m_iTeamNum", team, 4);
            TeleportEntity(Medipack, MediPos, NULL_VECTOR, NULL_VECTOR);
            EmitSoundToAll(SOUND_B, Medipack, _, _, _, 0.75);
            SetArrayCell(g_MedipacksTime, Medipack, GetTime());
            g_MedipacksCount++;
        }
    }
}

stock bool:IsEntLimitReached()
{
    if (GetEntityCount() >= (GetMaxEntities()-16))
    {
        PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
        LogError("Entity limit is nearly reached: %d/%d", GetEntityCount(), GetMaxEntities());
        return true;
    }
    else
        return false;
}

stock TF_IsUberCharge(client)
{
    new index = GetPlayerWeaponSlot(client, 1);
    if (index > 0)
        return GetEntProp(index, Prop_Send, "m_bChargeRelease", 1);
    else
        return 0;
}

stock TF_GetUberLevel(client)
{
    new index = GetPlayerWeaponSlot(client, 1);
    if (index > 0)
        return RoundFloat(GetEntPropFloat(index, Prop_Send, "m_flChargeLevel")*100);
    else
        return 0;
}

stock TF_SetUberLevel(client, uberlevel)
{
    new index = GetPlayerWeaponSlot(client, 1);
    if (index > 0)
    {
        g_MedicUberCharge[client] = uberlevel;
        SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
    }
}

stock TF_GetCurrentWeaponClass(client, String:name[], maxlength)
{
    new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (index > 0 && IsValidEntity(index))
        GetEntityNetClass(index, name, maxlength);
    else
        name[0] = '\0';
}

stock bool:TF_DropMedipack(client, bool:cmd)
{
    new charge;
    if (cmd)
        charge = TF_GetUberLevel(client);
    else
        charge = g_MedicUberCharge[client];

    new MedipacksLimit = GetConVarInt(g_MedipacksLimit);
    if (MedipacksLimit > 0 && g_MedipacksCount >= MedipacksLimit)
        charge = 0;

    new MedipacksSmall = GetConVarInt(g_MedipacksSmall);
    new MedipacksMedium = GetConVarInt(g_MedipacksMedium);
    new MedipacksFull = GetConVarInt(g_MedipacksFull);
    if (charge >= MedipacksFull && MedipacksFull != 0)
    {
        if (cmd) TF_SetUberLevel(client, (charge-MedipacksFull));
        TF_SpawnMedipack(client, "item_healthkit_full", cmd);
        return true;
    }
    else if (charge >= MedipacksMedium && MedipacksMedium != 0)
    {
        if (cmd) TF_SetUberLevel(client, (charge-MedipacksMedium));
        TF_SpawnMedipack(client, "item_healthkit_medium", cmd);
        return true;
    }
    else if (charge >= MedipacksSmall && MedipacksSmall != 0)
    {
        if (cmd) TF_SetUberLevel(client, (charge-MedipacksSmall));
        TF_SpawnMedipack(client, "item_healthkit_small", cmd);
        return true;
    }
    if (cmd)
    {
        EmitSoundToClient(client, SOUND_A, _, _, _, _, 0.75);
    }
    return false;
}

public Native_ControlMedipacks(Handle:plugin, numParams)
{
    if (numParams == 0)
        g_NativeControl = true;
    else if(numParams == 1)
        g_NativeControl = GetNativeCell(1);
}

public Native_SetMedipack(Handle:plugin, numParams)
{
    if (numParams >= 1 && numParams <= 3)
    {
        new client = GetNativeCell(1);
        g_NativeMedipacks[client] = (numParams >= 2) ? GetNativeCell(2) : 3;
        g_NativeUberCharge[client] = (numParams >= 3) ? GetNativeCell(3) : 0;
    }
}
