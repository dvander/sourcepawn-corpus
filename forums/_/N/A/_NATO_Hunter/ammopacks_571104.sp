/*
 *
 *  TF2 Ammopacks - SourceMod Plugin
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
#define SOUND_A "weapons/smg_clip_out.wav"
#define SOUND_B "items/spawn_item.wav"
#define SOUND_C "ui/hint.wav"

public Plugin:myinfo = 
{
    name = "TF2 Ammopacks",
    author = "Hunter",
    description = "Allows engineers to drop ammopacks on death or with secondary Wrench fire.",
    version = PL_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=65355"
}

new bool:g_NativeControl = false;
new bool:g_EngiButtonDown[MAXPLAYERS+1];
new Float:g_EngiPosition[MAXPLAYERS+1][3];
new g_NativeAmmopacks[MAXPLAYERS+1];
new g_EngiMetal[MAXPLAYERS+1];
new g_AmmopacksCount = 0;
new g_FilteredEntity = -1;
new Handle:g_IsAmmopacksOn = INVALID_HANDLE;
new Handle:g_AmmopacksSmall = INVALID_HANDLE;
new Handle:g_AmmopacksMedium = INVALID_HANDLE;
new Handle:g_AmmopacksFull = INVALID_HANDLE;
new Handle:g_AmmopacksKeep = INVALID_HANDLE;
new Handle:g_AmmopacksTeam = INVALID_HANDLE;
new Handle:g_AmmopacksLimit = INVALID_HANDLE;
new Handle:g_AmmopacksTime = INVALID_HANDLE;

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("ControlAmmopacks", Native_ControlAmmopacks);
    CreateNative("SetAmmopack", Native_SetAmmopack);
    RegPluginLibrary("ammopacks");

    return true;
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("ammopacks.phrases");

    HookConVarChange(CreateConVar("sm_tf_ammopacks", PL_VERSION, "Ammopacks", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY), ConVarChange_Version);
    g_IsAmmopacksOn = CreateConVar("sm_ammopacks","3","Enable/Disable ammopacks (0 = disabled | 1 = on death | 2 = on command | 3 = on death and command)", _, true, 0.0, true, 3.0);
    g_AmmopacksSmall = CreateConVar("sm_ammopacks_small","50","Metal required for small Ammopacks", _, true, 0.0, true, 200.0);
    g_AmmopacksMedium = CreateConVar("sm_ammopacks_medium","100","Metal required for medium Ammopacks", _, true, 0.0, true, 200.0);
    g_AmmopacksFull = CreateConVar("sm_ammopacks_full","200","Metal required for full Ammopacks", _, true, 0.0, true, 200.0);
    g_AmmopacksKeep = CreateConVar("sm_ammopacks_keep","60","Time to keep Ammopacks on map. (0 = off | >0 = seconds)", _, true, 0.0, true, 600.0);
    g_AmmopacksTeam = CreateConVar("sm_ammopacks_team","3","Team to drop Ammopacks for. (0 = any team | 1 = own team | 2 = opposing team | 3 = own on command, any on death)", _, true, 0.0, true, 3.0);
    g_AmmopacksLimit = CreateConVar("sm_ammopacks_limit","100","Maximum number of extra Ammopacks on map at a time. (0 = unlimited)", _, true, 0.0, true, 512.0);
    g_AmmopacksTime = CreateArray(_, GetMaxEntities());

    HookConVarChange(g_IsAmmopacksOn, ConVarChange_IsAmmopacksOn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_team", Event_PlayerTeam);
    HookEvent("teamplay_round_start", Event_TeamplayRoundStart);
    HookEntityOutput("item_ammopack_full", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);
    HookEntityOutput("item_ammopack_medium", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);
    HookEntityOutput("item_ammopack_small", "OnPlayerTouch", EntityOutput:Entity_OnPlayerTouch);
    RegConsoleCmd("sm_ammopack", Command_Ammopack);
    RegAdminCmd("sm_metal", Command_MetalAmount, ADMFLAG_CHEATS);

    CreateTimer(1.0, Timer_Caching, _, TIMER_REPEAT);

    AutoExecConfig(true);
}

public OnMapStart()
{
    PrecacheModel("models/items/ammopack_large.mdl", true);
    PrecacheModel("models/items/ammopack_medium.mdl", true);
    PrecacheModel("models/items/ammopack_small.mdl", true);

    PrecacheSound(SOUND_A, true);
    PrecacheSound(SOUND_B, true);
    PrecacheSound(SOUND_C, true);

    ClearArray(g_AmmopacksTime);
    ResizeArray(g_AmmopacksTime, GetMaxEntities());
    g_AmmopacksCount = 0;

    AutoExecConfig(true);
}

public OnClientDisconnect(client)
{
    g_EngiButtonDown[client] = false;
    g_EngiMetal[client] = 0;
    g_EngiPosition[client] = NULL_VECTOR;
}

public OnClientPutInServer(client)
{
    if(!g_NativeControl && GetConVarBool(g_IsAmmopacksOn))
        CreateTimer(45.0, Timer_Advert, client);
}

public OnGameFrame()
{
    new AmmopacksOn = GetConVarInt(g_IsAmmopacksOn);
    if (AmmopacksOn < 2 && !g_NativeControl)
        return;

    for (new i = 1; i <= MaxClients; i++)
    {
        if (g_NativeControl && g_NativeAmmopacks[i] < 2)
            continue;

        if (!g_EngiButtonDown[i] && IsClientInGame(i) && TF2_GetPlayerClass(i) == TFClass_Engineer)
        {
            if (GetClientButtons(i) & IN_ATTACK2)
            {
                g_EngiButtonDown[i] = true;
                CreateTimer(0.5, Timer_ButtonUp, i);
                new String:classname[64];
                TF_GetCurrentWeaponClass(i, classname, 64);
                if(StrEqual(classname, "CTFWrench"))
                    TF_DropAmmopack(i, true);
            }
        }
    }
}

public ConVarChange_Version(Handle:convar, const String:oldValue[], const String:newValue[])
{
    SetConVarString(convar, PL_VERSION);
}

public ConVarChange_IsAmmopacksOn(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (StringToInt(newValue) > 0)
        PrintToChatAll("[SM] %t", "Enabled Ammopacks");
    else
        PrintToChatAll("[SM] %t", "Disabled Ammopacks");
}

public Action:Command_Ammopack(client, args)
{
    new AmmopacksOn = g_NativeControl ? g_NativeAmmopacks[client]
                                      : GetConVarInt(g_IsAmmopacksOn);
    if (AmmopacksOn < 2)
        return Plugin_Handled;

    new TFClassType:class = TF2_GetPlayerClass(client);
    if (class != TFClass_Engineer)
        return Plugin_Handled;

    new String:classname[64];
    TF_GetCurrentWeaponClass(client, classname, 64);
    if(!StrEqual(classname, "CWrench"))
        return Plugin_Handled;

    TF_DropAmmopack(client, true);

    return Plugin_Handled;
}

public Action:Command_MetalAmount(client, args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] %t", "Metal Usage");
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
    if (class != TFClass_Engineer)
    {
        ReplyToCommand(client, "[SM] %t", "Not a Engineer", name);
        return Plugin_Handled;
    }

    new charge = 100;
    if (args > 1)
    {
        GetCmdArg(2, arg2, sizeof(arg2));
        charge = StringToInt(arg2);
        if (charge < 0 || charge > 200)
        {
            ReplyToCommand(client, "[SM] %t", "Invalid Amount");
            return Plugin_Handled;
        }
    }

    TF_SetMetalAmount(target, charge);

    ReplyToCommand(client, "[SM] %t", "Changed Metal", name, charge);
    return Plugin_Handled;
}

public Action:Timer_Advert(Handle:timer, any:client)
{
    if (IsClientConnected(client) && IsClientInGame(client))
    {
        new AmmopacksOn = GetConVarInt(g_IsAmmopacksOn);
        switch (AmmopacksOn)
        {
            case 1:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnDeath Ammopacks");
            case 2:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnCommand Ammopacks");
            case 3:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnDeathAndCommand Ammopacks");
        }
    }
}

public Action:Timer_Caching(Handle:timer)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && TF2_GetPlayerClass(i) == TFClass_Engineer)
        {
            g_EngiMetal[i] = TF_GetMetalAmount(i);
            GetClientAbsOrigin(i, g_EngiPosition[i]);
        }
    }

    new AmmopacksKeep = GetConVarInt(g_AmmopacksKeep);
    if (AmmopacksKeep > 0)
    {
        new mintime = GetTime() - AmmopacksKeep;
        for (new c = MaxClients; c < GetMaxEntities(); c++)
        {
            new time = GetArrayCell(g_AmmopacksTime, c);
            if (time > 0 && time < mintime)
            {
                SetArrayCell(g_AmmopacksTime, c, 0);
                if (IsValidEdict(c))
                {
                    new String:classname[64];
                    GetEdictClassname(c, classname, 64);
                    if (!strncmp(classname, "item_ammopack", 13))
                    {
                        EmitSoundToAll(SOUND_C, c, _, _, _, 0.75);
                        RemoveEdict(c);
                        g_AmmopacksCount--;
                    }
                }
            }
        }
    }
}

public Action:Timer_ButtonUp(Handle:timer, any:client)
{
    g_EngiButtonDown[client] = false;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientInGame(client))
        return;

    new AmmopacksOn = g_NativeControl ? g_NativeAmmopacks[client] : GetConVarInt(g_IsAmmopacksOn);
    if (AmmopacksOn < 1 || AmmopacksOn == 2)
        return;

    new TFClassType:class = TF2_GetPlayerClass(client);	
    if (class != TFClass_Engineer)
        return;

    TF_DropAmmopack(client, false);
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

    g_EngiButtonDown[client] = false;
    g_EngiMetal[client] = 0;
    g_EngiPosition[client] = NULL_VECTOR;
}

public Action:Event_TeamplayRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    new full_reset = GetEventInt(event, "full_reset");
    if (full_reset)
    {
        for (new c = MaxClients; c < GetMaxEntities(); c++)
        {
            new time = GetArrayCell(g_AmmopacksTime, c);
            if (time > 0)
            {
                SetArrayCell(g_AmmopacksTime, c, 0);
                g_AmmopacksCount--;
            }
        }
    }
}

public Action:Entity_OnPlayerTouch(const String:output[], caller, activator, Float:delay)
{
    new time = GetArrayCell(g_AmmopacksTime, caller);
    if (time > 0 && activator > 0)
    {
        SetArrayCell(g_AmmopacksTime, caller, 0);
        g_AmmopacksCount--;
    }
}

public bool:AmmopackTraceFilter(ent, contentMask)
{
    return (ent != g_FilteredEntity);
}

stock TF_SpawnAmmopack(client, String:name[], bool:cmd)
{
    new Float:PlayerPosition[3];
    if (cmd)
        GetClientAbsOrigin(client, PlayerPosition);
    else
        PlayerPosition = g_EngiPosition[client];

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

            new Handle:TraceEx = TR_TraceRayFilterEx(PlayerPosition, PlayerPosAway, MASK_SOLID, RayType_EndPoint, AmmopackTraceFilter);
            TR_GetEndPosition(PlayerPosition, TraceEx);
            CloseHandle(TraceEx);
        }

        new Float:Direction[3];
        Direction[0] = PlayerPosition[0];
        Direction[1] = PlayerPosition[1];
        Direction[2] = PlayerPosition[2]-1024;
        new Handle:Trace = TR_TraceRayFilterEx(PlayerPosition, Direction, MASK_SOLID, RayType_EndPoint, AmmopackTraceFilter);

        new Float:AmmoPos[3];
        TR_GetEndPosition(AmmoPos, Trace);
        CloseHandle(Trace);
        AmmoPos[2] += 4;

        new Ammopack = CreateEntityByName(name);
        DispatchKeyValue(Ammopack, "OnPlayerTouch", "!self,Kill,,0,-1");
        if (DispatchSpawn(Ammopack))
        {
            new team = 0;
            new AmmopacksTeam = GetConVarInt(g_AmmopacksTeam);
            if (AmmopacksTeam == 2)
                team = ((GetClientTeam(client)-1) % 2) + 2;
            else if (AmmopacksTeam == 1 || (AmmopacksTeam == 3 && cmd))
                team = GetClientTeam(client);

            SetEntProp(Ammopack, Prop_Send, "m_iTeamNum", team, 4);
            TeleportEntity(Ammopack, AmmoPos, NULL_VECTOR, NULL_VECTOR);
            EmitSoundToAll(SOUND_B, Ammopack, _, _, _, 0.75);
            SetArrayCell(g_AmmopacksTime, Ammopack, GetTime());
            g_AmmopacksCount++;
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

stock TF_GetMetalAmount(client)
{
    return GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 4);
}

stock TF_SetMetalAmount(client, metal)
{
    g_EngiMetal[client] = metal;
    SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), metal, 4, true);
}

stock TF_GetCurrentWeaponClass(client, String:name[], maxlength)
{
    new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (index > 0 && IsValidEntity(index))
        GetEntityNetClass(index, name, maxlength);
    else
        name[0] = '\0';
}

stock bool:TF_DropAmmopack(client, bool:cmd)
{
    new metal;
    if (cmd)
        metal = TF_GetMetalAmount(client);
    else
        metal = g_EngiMetal[client];

    new AmmopacksLimit = GetConVarInt(g_AmmopacksLimit);
    if (AmmopacksLimit > 0 && g_AmmopacksCount >= AmmopacksLimit)
        metal = 0;

    new AmmopacksSmall = GetConVarInt(g_AmmopacksSmall);
    new AmmopacksMedium = GetConVarInt(g_AmmopacksMedium);
    new AmmopacksFull = GetConVarInt(g_AmmopacksFull);
    if (metal >= AmmopacksFull && AmmopacksFull != 0)
    {
        if (cmd) TF_SetMetalAmount(client, (metal-AmmopacksFull));
        TF_SpawnAmmopack(client, "item_ammopack_full", cmd);
        return true;
    }
    else if (metal >= AmmopacksMedium && AmmopacksMedium != 0)
    {
        if (cmd) TF_SetMetalAmount(client, (metal-AmmopacksMedium));
        TF_SpawnAmmopack(client, "item_ammopack_medium", cmd);
        return true;
    }
    else if (metal >= AmmopacksSmall && AmmopacksSmall != 0)
    {
        if (cmd) TF_SetMetalAmount(client, (metal-AmmopacksSmall));
        TF_SpawnAmmopack(client, "item_ammopack_small", cmd);
        return true;
    }
    if (cmd)
    {
        EmitSoundToClient(client, SOUND_A, _, _, _, _, 0.75);
    }
    return false;
}

public Native_ControlAmmopacks(Handle:plugin, numParams)
{
    if (numParams == 0)
        g_NativeControl = true;
    else if(numParams == 1)
        g_NativeControl = GetNativeCell(1);
}

public Native_SetAmmopack(Handle:plugin, numParams)
{
    if(numParams >= 1 && numParams <= 2)
    {
        new client = GetNativeCell(1);
        g_NativeAmmopacks[client] = (numParams >= 2) ? GetNativeCell(2) : 3;
    }
}
