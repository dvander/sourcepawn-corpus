/*
 *  vim: set ai et ts=4 sw=4 :
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

#define PL_VERSION "1.5"

#define SOUND_A "weapons/medigun_no_target.wav"
#define SOUND_B "items/spawn_item.wav"
#define SOUND_C "ui/hint.wav"

#define MEDKIT_LARGE_MODEL              "models/items/medkit_large.mdl"
#define MEDKIT_MEDIUM_MODEL             "models/items/medkit_medium.mdl"
#define MEDKIT_SMALL_MODEL              "models/items/medkit_small.mdl"

#define BIRTHDAY_MEDKIT_LARGE_MODEL     "models/items/medkit_large_bday.mdl"
#define BIRTHDAY_MEDKIT_MEDIUM_MODEL    "models/items/medkit_medium_bday.mdl"
#define BIRTHDAY_MEDKIT_SMALL_MODEL     "models/items/medkit_small.mdl_bday"

#define HALLOWEEN_MEDKIT_LARGE_MODEL    "models/props_halloween/halloween_medkit_large.mdl"
#define HALLOWEEN_MEDKIT_MEDIUM_MODEL   "models/props_halloween/halloween_medkit_medium.mdl"
#define HALLOWEEN_MEDKIT_SMALL_MODEL    "models/props_halloween/halloween_medkit_small.mdl"

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
new TFHoliday:g_Holiday;

new g_MedkitSmallModel = 0;
new g_MedkitMediumModel = 0;
new g_MedkitLargeModel = 0;
new g_BirthdayMedkitSmallModel = 0;
new g_BirthdayMedkitMediumModel = 0;
new g_BirthdayMedkitLargeModel = 0;
new g_HalloweenMedkitSmallModel = 0;
new g_HalloweenMedkitMediumModel = 0;
new g_HalloweenMedkitLargeModel = 0;

new Handle:g_IsMedipacksOn = INVALID_HANDLE;
new Handle:g_Advertise = INVALID_HANDLE;
new Handle:g_DefUberCharge = INVALID_HANDLE;
new Handle:g_MedipacksSmall = INVALID_HANDLE;
new Handle:g_MedipacksMedium = INVALID_HANDLE;
new Handle:g_MedipacksFull = INVALID_HANDLE;
new Handle:g_MedipacksDeploy = INVALID_HANDLE;
new Handle:g_MedipacksKeep = INVALID_HANDLE;
new Handle:g_MedipacksTeam = INVALID_HANDLE;
new Handle:g_MedipacksLimit = INVALID_HANDLE;
new Handle:g_MedipacksTime = INVALID_HANDLE;
new Handle:g_MedipacksRef = INVALID_HANDLE;

/**
 * Description: Stocks to return information about TF2 UberCharge.
 */
#tryinclude <tf2_uber>
#if !defined _tf2_uber_included
    stock Float:TF2_ExGetUberLevel(client)
    {
        if (TF2_GetPlayerClass(client) == TFClass_Medic)
        {
            new index = GetPlayerWeaponSlot(client, 1);
            if (index > 0)
            {
                decl String:classname[50];
                if (GetEdictClassname(index, classname, sizeof(classname)) &&
                    StrEqual(classname, "tf_weapon_medigun"))
                {
                    return GetEntPropFloat(index, Prop_Send, "m_flChargeLevel");
                }
            }
        }
        return 0.0;
    }

    stock bool:TF2_ExSetUberLevel(client, Float:uberlevel)
    {
        if (TF2_GetPlayerClass(client) == TFClass_Medic)
        {
            new index = GetPlayerWeaponSlot(client, 1);
            if (index > 0)
            {
                decl String:classname[50];
                if (GetEdictClassname(index, classname, sizeof(classname)) &&
                    StrEqual(classname, "tf_weapon_medigun"))
                {
                    SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel);
                    return true;
                }
            }
        }
        return false;
    }

    stock TF2_ExIsUberCharge(client)
    {
        if (TF2_GetPlayerClass(client) == TFClass_Medic)
        {
            new index = GetPlayerWeaponSlot(client, 1);
            if (index > 0)
            {
                decl String:classname[50];
                if (GetEdictClassname(index, classname, sizeof(classname)) &&
                    StrEqual(classname, "tf_weapon_medigun"))
                {
                    return GetEntProp(index, Prop_Send, "m_bChargeRelease", 1);
                }
            }
        }
        return 0;
    }
#endif

/**
 * Description: Stocks to return information about weapons.
 */
#tryinclude <weapons>
#if !defined _weapons_included
    stock GetCurrentWeaponClass(client, String:name[], maxlength)
    {
        new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        if (index > 0 && IsValidEntity(index))
            GetEntityNetClass(index, name, maxlength);
        else
            name[0] = '\0';
    }
#endif

#tryinclude <entlimit>
#if !defined _entlimit_included
    stock IsEntLimitReached(warn=20,critical=16,client=0,const String:message[]="")
    {
        new max = GetMaxEntities();
        new count = GetEntityCount();
        new remaining = max - count;
        if (remaining <= warn)
        {
            if (count <= critical)
            {
                PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
                LogError("Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);

                if (client > 0)
                {
                    PrintToConsole(client, "Entity limit is nearly reached: %d/%d (%d):%s",
                                   count, max, remaining, message);
                }
            }
            else
            {
                PrintToServer("Caution: Entity count is getting high!");
                LogMessage("Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);

                if (client > 0)
                {
                    PrintToConsole(client, "Entity count is getting high: %d/%d (%d):%s",
                                   count, max, remaining, message);
                }
            }
            return count;
        }
        else
            return 0;
    }
#endif

/**
 * Description: Manage precaching resources.
 */
#tryinclude "ResourceManager"
#if !defined _ResourceManager_included
    #define AUTO_DOWNLOAD   -1
	#define DONT_DOWNLOAD    0
	#define DOWNLOAD         1
	#define ALWAYS_DOWNLOAD  2

	enum State { Unknown=0, Defined, Download, Force, Precached };

	// Trie to hold precache status of sounds
	new Handle:g_soundTrie = INVALID_HANDLE;

	stock bool:PrepareSound(const String:sound[], bool:force=false, bool:preload=false)
	{
        #pragma unused force
        new State:value = Unknown;
        if (!GetTrieValue(g_soundTrie, sound, value) || value < Precached)
        {
            PrecacheSound(sound, preload);
            SetTrieValue(g_soundTrie, sound, Precached);
        }
        return true;
    }

	stock SetupSound(const String:sound[], bool:force=false, download=AUTO_DOWNLOAD,
	                 bool:precache=false, bool:preload=false)
	{
        new State:value = Unknown;
        new bool:update = !GetTrieValue(g_soundTrie, sound, value);
        if (update || value < Defined)
        {
            value  = Defined;
            update = true;
        }

        if (download && value < Download)
        {
            decl String:file[PLATFORM_MAX_PATH+1];
            Format(file, sizeof(file), "sound/%s", sound);

            if (FileExists(file))
            {
                if (download < 0)
                {
                    if (!strncmp(file, "ambient", 7) ||
                        !strncmp(file, "beams", 5) ||
                        !strncmp(file, "buttons", 7) ||
                        !strncmp(file, "coach", 5) ||
                        !strncmp(file, "combined", 8) ||
                        !strncmp(file, "commentary", 10) ||
                        !strncmp(file, "common", 6) ||
                        !strncmp(file, "doors", 5) ||
                        !strncmp(file, "friends", 7) ||
                        !strncmp(file, "hl1", 3) ||
                        !strncmp(file, "items", 5) ||
                        !strncmp(file, "midi", 4) ||
                        !strncmp(file, "misc", 4) ||
                        !strncmp(file, "music", 5) ||
                        !strncmp(file, "npc", 3) ||
                        !strncmp(file, "physics", 7) ||
                        !strncmp(file, "pl_hoodoo", 9) ||
                        !strncmp(file, "plats", 5) ||
                        !strncmp(file, "player", 6) ||
                        !strncmp(file, "resource", 8) ||
                        !strncmp(file, "replay", 6) ||
                        !strncmp(file, "test", 4) ||
                        !strncmp(file, "ui", 2) ||
                        !strncmp(file, "vehicles", 8) ||
                        !strncmp(file, "vo", 2) ||
                        !strncmp(file, "weapons", 7))
                    {
                        // If the sound starts with one of those directories
                        // assume it came with the game and doesn't need to
                        // be downloaded.
                        download = 0;
                    }
                    else
                        download = 1;
                }

                if (download > 0)
                {
                    AddFileToDownloadsTable(file);

                    update = true;
                    value  = Download;
                }
            }
        }

        if (precache && value < Precached)
        {
            PrecacheSound(sound, preload);
            value  = Precached;
            update = true;
        }
        else if (force && value < Force)
        {
            value  = Force;
            update = true;
        }

        if (update)
            SetTrieValue(g_soundTrie, sound, value);
    }

    stock SetupModel(const String:model[], &index=0, bool:download=false,
                     bool:precache=false, bool:preload=false)
    {
        if (download && FileExists(model))
            AddFileToDownloadsTable(model);

        if (precache)
            index = PrecacheModel(model,preload);
        else
            index = 0;
    }

    stock PrepareModel(const String:model[], &index=0, bool:preload=true)
    {
        if (index <= 0)
            index = PrecacheModel(model,preload);

        return index;
    }
#endif

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("ControlMedipacks", Native_ControlMedipacks);
    CreateNative("SetMedipack", Native_SetMedipack);
    CreateNative("DropMedipack", Native_DropMedipack);
    RegPluginLibrary("medipacks");
    return APLRes_Success;
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("medipacks.phrases");

    HookConVarChange(CreateConVar("sm_tf_medipacks", PL_VERSION, "Medipacks", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY), ConVarChange_Version);
    g_IsMedipacksOn = CreateConVar("sm_medipacks","3","Enable/Disable medipacks (0=disabled|1=on death|2=on command|3=on death and command)", _, true, 0.0, true, 3.0);
    g_Advertise = CreateConVar("sm_medipacks_advertise","1","Enable/Disable Advertisements");
    g_DefUberCharge = CreateConVar("sm_medipacks_ubercharge","25","Give medics a default UberCharge on spawn", _, true, 0.0, true, 100.0);
    g_MedipacksSmall = CreateConVar("sm_medipacks_small","10","UberCharge required for small Medipacks", _, true, 0.0, true, 100.0);
    g_MedipacksMedium = CreateConVar("sm_medipacks_medium","25","UberCharge required for medium Medipacks", _, true, 0.0, true, 100.0);
    g_MedipacksFull = CreateConVar("sm_medipacks_full","50","UberCharge required for full Medipacks", _, true, 0.0, true, 100.0);
    g_MedipacksDeploy = CreateConVar("sm_medipacks_deploy","80","Max UberCharge to deploy Medipacks with medigun", _, true, 0.0, true, 100.0);
    g_MedipacksKeep = CreateConVar("sm_medipacks_keep","60","Time to keep Medipacks on map. (0=off|>0=seconds)", _, true, 0.0, true, 600.0);
    g_MedipacksTeam = CreateConVar("sm_medipacks_team","3","Team to drop Medipacks for. (0=any team|1=own team|2=opposing team|3=own on command, any on death)", _, true, 0.0, true, 3.0);
    g_MedipacksLimit = CreateConVar("sm_medipacks_limit","100","Maximum number of extra Medipacks on map at a time. (0=unlimited)", _, true, 0.0, true, 512.0);

    new maxents = GetMaxEntities();
    g_MedipacksTime = CreateArray(_, maxents);
    g_MedipacksRef = CreateArray(_, maxents);

    HookConVarChange(g_IsMedipacksOn, ConVarChange_IsMedipacksOn);
    HookConVarChange(g_Advertise, ConVarChange_Advertise);
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
    RegAdminCmd("sm_spawnmedipack", Command_Spawn, ADMFLAG_CHEATS);
    RegAdminCmd("sm_halloweenhealth", Command_Spawn, ADMFLAG_CHEATS);
    RegAdminCmd("sm_birthdayhealth", Command_Spawn, ADMFLAG_CHEATS);
    RegAdminCmd("sm_christmashealth", Command_Spawn, ADMFLAG_CHEATS);

    CreateTimer(1.0, Timer_Caching, _, TIMER_REPEAT);

    AutoExecConfig(true);
}

public Action:TF2_OnIsHolidayActive(TFHoliday:holiday, &bool:result)
{
    // Stash the holiday flag
    g_Holiday = holiday;
    return Plugin_Continue;
}

public OnMapStart()
{
    SetupModel(MEDKIT_SMALL_MODEL,  g_MedkitSmallModel);
    SetupModel(MEDKIT_MEDIUM_MODEL, g_MedkitMediumModel);
    SetupModel(MEDKIT_LARGE_MODEL,  g_MedkitLargeModel);

    SetupModel(BIRTHDAY_MEDKIT_SMALL_MODEL,  g_BirthdayMedkitSmallModel);
    SetupModel(BIRTHDAY_MEDKIT_MEDIUM_MODEL, g_BirthdayMedkitMediumModel);
    SetupModel(BIRTHDAY_MEDKIT_LARGE_MODEL,  g_BirthdayMedkitLargeModel);

    SetupModel(HALLOWEEN_MEDKIT_SMALL_MODEL,  g_HalloweenMedkitSmallModel);
    SetupModel(HALLOWEEN_MEDKIT_MEDIUM_MODEL, g_HalloweenMedkitMediumModel);
    SetupModel(HALLOWEEN_MEDKIT_LARGE_MODEL,  g_HalloweenMedkitLargeModel);

    SetupSound(SOUND_A, true, DONT_DOWNLOAD, false, false);
    SetupSound(SOUND_B, true, DONT_DOWNLOAD, false, false);
    SetupSound(SOUND_C, true, DONT_DOWNLOAD, true,  true);

    new maxents = GetMaxEntities();
    ClearArray(g_MedipacksRef);
    ClearArray(g_MedipacksTime);
    ResizeArray(g_MedipacksRef, maxents);
    ResizeArray(g_MedipacksTime, maxents);
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

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (buttons & IN_ATTACK2 && !g_MedicButtonDown[client])
    {
        if (!g_NativeControl && GetConVarInt(g_IsMedipacksOn) < 2)
            return Plugin_Continue;
        else if (g_NativeControl && g_NativeMedipacks[client] < 2)
            return Plugin_Continue;
        else if (TF2_GetPlayerClass(client) == TFClass_Medic)
        {
            if (TF2_ExIsUberCharge(client) == 0.0)
            {
                new String:classname[64];
                GetCurrentWeaponClass(client, classname, sizeof(classname));
                if (StrEqual(classname, "CWeaponMedigun") &&
                    g_MedicUberCharge[client] < GetConVarInt(g_MedipacksDeploy))
                {
                    new weaponent = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
                    if (weaponent > 0 && GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex") != 35) // Kritzkrieg
                        TF_DropMedipack(client, true, g_Holiday);
                }
                else if (StrEqual(classname, "CTFSyringeGun"))
                {
                    TF_DropMedipack(client, true, g_Holiday);
                }

                g_MedicButtonDown[client] = true;
                CreateTimer(0.5, Timer_ButtonUp, client);
            }
        }
    }
    return Plugin_Continue;
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

public ConVarChange_Advertise(Handle:convar, const String:oldValue[], const String:newValue[])
{
    SetConVarInt(convar, StringToInt(newValue));
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
    GetCurrentWeaponClass(client, classname, 64);
    if(!StrEqual(classname, "CWeaponMedigun"))
        return Plugin_Handled;

    TF_DropMedipack(client, true, g_Holiday);

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

    TF2_ExSetUberLevel(target, charge*0.01);

    ReplyToCommand(client, "[SM] %t", "Changed UberCharge", name, charge);
    return Plugin_Handled;
}

public Action:Command_Spawn(client,args)
{
    decl String:command[64];
    GetCmdArg(0, command, sizeof(command));

    if (args != 1)
    {
        ReplyToCommand(client, "Usage: %s <full / medium / small>", command);
        return Plugin_Handled;
    }
    else if (client < 1)
    {
        ReplyToCommand(client, "This command must be used ingame");
        return Plugin_Handled;
    }

    new TFHoliday:holiday;
    if (StrEqual(command, "sm_halloweenhealth"))
        holiday = TFHoliday_Halloween;
    else if (StrEqual(command, "sm_birthdayhealth"))        
        holiday = TFHoliday_Birthday;
    else if (StrEqual(command, "sm_christmashealth"))        
        holiday = TFHoliday_Christmas;
    else        
        holiday = g_Holiday;

    decl String:buffer[128];
    GetCmdArg(1, buffer, sizeof(buffer));

    if (StrEqual(buffer, "full", false))
    {
        ShowActivity2(client, "\x04[Medipacks\x04]\x01 ","spawned a \x04Full\x01 health kit!", client);
        LogAction(client, -1, "[Medipacks] %L spawned a Full health kit.", client);
        TF_SpawnMedipack(client, "item_healthkit_full", true, holiday);
        return Plugin_Handled;
    }
    else if (StrEqual(buffer, "medium", false))
    {
        ShowActivity2(client, "\x04[Medipacks\x04]\x01 ","spawned a \x04Medium\x01 health kit!", client);
        LogAction(client, -1, "[Medipacks] %L spawned a Medium health kit.", client);
        TF_SpawnMedipack(client, "item_healthkit_medium", true, holiday);
        return Plugin_Handled;
    }
    else if (StrEqual(buffer, "small", false))
    {
        ShowActivity2(client, "\x04[Medipacks\x04]\x01 ","spawned a \x04Small\x01 health kit!", client);
        LogAction(client, -1, "[Medipacks] %L spawned a Small health kit.", client);
        TF_SpawnMedipack(client, "item_healthkit_small", true, holiday);
        return Plugin_Handled;
    }

    ReplyToCommand(client, "Usage: %s <full / medium / small>", command);
    return Plugin_Handled;
}

public Action:Timer_Advert(Handle:timer, any:client)
{
    if (IsClientConnected(client) && IsClientInGame(client))
    {
        if (GetConVarInt(g_Advertise) == 1)
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
}

public Action:Timer_Caching(Handle:timer)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && TF2_GetPlayerClass(i) == TFClass_Medic)
        {
            g_MedicUberCharge[i] = RoundFloat(TF2_ExGetUberLevel(i)*100.0);
            GetClientAbsOrigin(i, g_MedicPosition[i]);
        }
    }

    new MedipacksKeep = GetConVarInt(g_MedipacksKeep);
    new MedipacksLimit = GetConVarInt(g_MedipacksLimit);
    if (MedipacksKeep > 0 || MedipacksLimit > 0)
    {
        new maxents = GetMaxEntities();
        new mintime = GetTime() - MedipacksKeep;
        for (new c = MaxClients; c < maxents; c++)
        {
            new time = GetArrayCell(g_MedipacksTime, c);
            if (time > 0)
            {
                new bool:valid = (EntRefToEntIndex(GetArrayCell(g_MedipacksRef, c)) == c &&
                                 IsValidEdict(c));
                if (valid)
                {
                    if (MedipacksKeep > 0 && time < mintime)
                    {
                        EmitSoundToAll(SOUND_C, c, _, _, _, 0.75);
                        AcceptEntityInput(c, "kill");
                        valid = false;
                    }
                }

                if (!valid)
                {
                    g_MedipacksCount--;
                    SetArrayCell(g_MedipacksRef, c, INVALID_ENT_REFERENCE);
                    SetArrayCell(g_MedipacksTime, c, 0.0);
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
        TF2_ExSetUberLevel(client, DefUberCharge*0.01);
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
    // Skip feigned deaths.
    if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
        return;

    // Skip fishy deaths.
    if (GetEventInt(event, "weaponid") == TF_WEAPON_BAT_FISH &&
        GetEventInt(event, "customkill") != TF_CUSTOM_FISH_KILL)
    {
        return;
    }

    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientInGame(client))
        return;

    new MedipacksOn = g_NativeControl ? g_NativeMedipacks[client] : GetConVarInt(g_IsMedipacksOn);
    if (MedipacksOn < 1 || MedipacksOn == 2)
        return;

    new TFClassType:class = TF2_GetPlayerClass(client);
    if (class != TFClass_Medic)
        return;

    TF_DropMedipack(client, false, g_Holiday);
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
        new maxents = GetMaxEntities();
        for (new c = MaxClients; c < maxents; c++)
        {
            new time = GetArrayCell(g_MedipacksTime, c);
            if (time > 0)
            {
                SetArrayCell(g_MedipacksRef, c, INVALID_ENT_REFERENCE);
                SetArrayCell(g_MedipacksTime, c, 0.0);
                g_MedipacksCount--;
            }
        }
    }
}

public Action:Entity_OnPlayerTouch(const String:output[], caller, activator, Float:delay)
{
    if (activator > 0 && caller > 0)
    {
        new time = GetArrayCell(g_MedipacksTime, caller);
        if (time > 0)
        {
            SetArrayCell(g_MedipacksRef, caller, INVALID_ENT_REFERENCE);
            SetArrayCell(g_MedipacksTime, caller, 0.0);
            g_MedipacksCount--;
        }
    }
}

public bool:MedipackTraceFilter(ent, contentMask)
{
    return (ent != g_FilteredEntity);
}

stock TF_SpawnMedipack(client, String:name[], bool:cmd, TFHoliday:holiday)
{
    new Float:PlayerPosition[3];
    if (cmd)
        GetClientAbsOrigin(client, PlayerPosition);
    else
        PlayerPosition = g_MedicPosition[client];

    if (PlayerPosition[0] != 0.0 && PlayerPosition[1] != 0.0 && PlayerPosition[2] != 0.0 &&
        !IsEntLimitReached(.client=client,.message="Unable to spawn medipack"))
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
        if (Medipack > 0 && IsValidEntity(Medipack))
        {
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

                if (holiday == TFHoliday_Halloween || holiday == TFHoliday_FullMoon ||
                    holiday == TFHoliday_HalloweenOrFullMoon)
                {
                    if (StrContains(name, "small") >= 0)
                    {
                        PrepareModel(HALLOWEEN_MEDKIT_SMALL_MODEL, g_HalloweenMedkitSmallModel);
                        SetEntityModel(Medipack, HALLOWEEN_MEDKIT_SMALL_MODEL);
                    }
                    else if (StrContains(name, "medium") >= 0)
                    {
                        PrepareModel(HALLOWEEN_MEDKIT_MEDIUM_MODEL, g_HalloweenMedkitMediumModel);
                        SetEntityModel(Medipack, HALLOWEEN_MEDKIT_MEDIUM_MODEL);
                    }
                    else
                    {
                        PrepareModel(HALLOWEEN_MEDKIT_LARGE_MODEL, g_HalloweenMedkitLargeModel);
                        SetEntityModel(Medipack, HALLOWEEN_MEDKIT_LARGE_MODEL);
                    }
                }
                else if (holiday == TFHoliday_Birthday)
                {
                    if (StrContains(name, "small") >= 0)
                    {
                        PrepareModel(BIRTHDAY_MEDKIT_SMALL_MODEL, g_BirthdayMedkitSmallModel);
                        SetEntityModel(Medipack, BIRTHDAY_MEDKIT_SMALL_MODEL);
                    }
                    else if (StrContains(name, "medium") >= 0)
                    {
                        PrepareModel(BIRTHDAY_MEDKIT_MEDIUM_MODEL, g_BirthdayMedkitMediumModel);
                        SetEntityModel(Medipack, BIRTHDAY_MEDKIT_MEDIUM_MODEL);
                    }
                    else
                    {
                        PrepareModel(BIRTHDAY_MEDKIT_LARGE_MODEL, g_BirthdayMedkitLargeModel);
                        SetEntityModel(Medipack, BIRTHDAY_MEDKIT_LARGE_MODEL);
                    }
                }
                else
                {
                    if (StrContains(name, "small") >= 0)
                        PrepareModel(MEDKIT_SMALL_MODEL,  g_MedkitSmallModel);
                    else if (StrContains(name, "medium") >= 0)
                        PrepareModel(MEDKIT_MEDIUM_MODEL, g_MedkitMediumModel);
                    else
                        PrepareModel(MEDKIT_LARGE_MODEL,  g_MedkitLargeModel);
                }

                SetArrayCell(g_MedipacksTime, Medipack, GetTime());
                SetArrayCell(g_MedipacksRef, Medipack, EntIndexToEntRef(Medipack));
                g_MedipacksCount++;

                if (PrepareSound(SOUND_B))
                    EmitSoundToAll(SOUND_B, Medipack, _, _, _, 0.75);
            }
        }
    }
}

stock bool:TF_DropMedipack(client, bool:cmd, TFHoliday:holiday)
{
    new charge;
    if (cmd)
        charge = RoundFloat(TF2_ExGetUberLevel(client)*100.0);
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
        if (cmd) TF2_ExSetUberLevel(client, (charge-MedipacksFull)*0.01);
        TF_SpawnMedipack(client, "item_healthkit_full", cmd, holiday);
        return true;
    }
    else if (charge >= MedipacksMedium && MedipacksMedium != 0)
    {
        if (cmd) TF2_ExSetUberLevel(client, (charge-MedipacksMedium)*0.01);
        TF_SpawnMedipack(client, "item_healthkit_medium", cmd, holiday);
        return true;
    }
    else if (charge >= MedipacksSmall && MedipacksSmall != 0)
    {
        if (cmd) TF2_ExSetUberLevel(client, (charge-MedipacksSmall)*0.01);
        TF_SpawnMedipack(client, "item_healthkit_small", cmd, holiday);
        return true;
    }
    else if (cmd && PrepareSound(SOUND_A))
    {
        EmitSoundToClient(client, SOUND_A, _, _, _, _, 0.75);
    }
    return false;
}

public Native_ControlMedipacks(Handle:plugin, numParams)
{
    g_NativeControl = GetNativeCell(1);
}

public Native_SetMedipack(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    g_NativeMedipacks[client] = GetNativeCell(2);
    g_NativeUberCharge[client] = GetNativeCell(3);
}

public Native_DropMedipack(Handle:plugin, numParams)
{
    new client         = GetNativeCell(1);
    new charge         = GetNativeCell(2);
    new TFHoliday:type = TFHoliday:GetNativeCell(3);

    if (charge >= 0)
    {
        g_MedicUberCharge[client] = charge;
        return TF_DropMedipack(client, false, type);
    }
    else
        return TF_DropMedipack(client, true, type);
}
