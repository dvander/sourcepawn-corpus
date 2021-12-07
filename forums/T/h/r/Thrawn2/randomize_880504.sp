#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"
#define SLOTONEWEAPONSMAX 9
#define SLOTTWOWEAPONSMAX 9
#define SLOTTHREEWEAPONSMAX 9

new classHealth[10] = {0, 125, 125, 200, 175, 150, 300, 175, 125, 125};

new Handle:GameConf;
new Handle:hGiveNamedItem;
new Handle:hWeaponEquip;
new Handle:hKV = INVALID_HANDLE;
new Handle:hKVb = INVALID_HANDLE;

new Handle:g_hCvarEnable;
new Handle:g_hCvarSlotA;
new Handle:g_hCvarSlotB;
new Handle:g_hCvarSlotC;
new Handle:g_hCvarRemoveRefills;
new Handle:g_hCvarAllowClassChoose;

// Functions
public Plugin:myinfo =
{
    name = "TF2 Random",
    author = "Thrawn",
    description = "Spawns players as random classes with random weapons",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
    g_hCvarEnable = CreateConVar("sm_randomizer_enable", "1", "Enable/Disable spawning as random class with random weapons", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarRemoveRefills = CreateConVar("sm_randomizer_remove_lockers", "1", "Automatically removes lockers at round start.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarSlotA = CreateConVar("sm_randomizer_give_slot_one", "1", "Should players have slot 1 weapons?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarSlotB = CreateConVar("sm_randomizer_give_slot_two", "1", "Should players have slot 2 weapons?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarSlotC = CreateConVar("sm_randomizer_give_slot_three", "1", "Should players have slot 3 weapons?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarAllowClassChoose = CreateConVar("sm_randomizer_allow_class_selection", "0", "Allow players to selected their class.", FCVAR_PLUGIN, true, 0.0, true, 1.0);

    HookConVarChange(g_hCvarEnable, Cvar_enabled);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("teamplay_round_start", hook_Start, EventHookMode_Post);

    GameConf = LoadGameConfigFile("givenameditem.games");

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(GameConf, SDKConf_Virtual, "GiveNamedItem");
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
    hGiveNamedItem = EndPrepSDKCall();

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(GameConf, SDKConf_Virtual, "WeaponEquip");
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    hWeaponEquip = EndPrepSDKCall();

    hKV = CreateKeyValues("TF2WeaponData");
    hKVb = CreateKeyValues("TF2WeaponSlots");

    new String:file[128];
    BuildPath(Path_SM, file, sizeof(file), "data/tf2weapondata.txt");
    FileToKeyValues(hKV, file);

    new String:fileb[128];
    BuildPath(Path_SM, fileb, sizeof(fileb), "data/tf2weaponslots.txt");
    FileToKeyValues(hKVb, fileb);

    AutoExecConfig(true, "plugin.randomize");
}

public Action:hook_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
    checkConvarStatus();
}

public Cvar_enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
    checkConvarStatus();
}

stock checkConvarStatus()
{
    if(GetConVarBool(g_hCvarEnable) && GetConVarBool(g_hCvarRemoveRefills))
    {
        RemoveEnts(true);
    }
    else
        RemoveEnts(false);
}

stock RemoveEnts(bool:disable)
{
    new iCurrentEnt = -1;
    while ((iCurrentEnt = FindEntityByClassname(iCurrentEnt, "func_regenerate")) != -1)
    {
        if(disable)
            AcceptEntityInput(iCurrentEnt, "Disable");
        else
            AcceptEntityInput(iCurrentEnt, "Enable");
    }
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GetConVarBool(g_hCvarEnable))
    {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));

        if(IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
        {
            CreateTimer(0.2, Timer_RandomWeapons, GetEventInt(event, "userid"));
        }
    }
}

public Action:Timer_RandomWeapons(Handle:timer, any:userid)
{
    new String:weapon[64];
    new String:tStr[2];
    new client = GetClientOfUserId(userid);

    if (!GetConVarBool(g_hCvarAllowClassChoose))
    {
        new TFClassType:class = TFClass_Unknown;
        new tInt = GetRandomInt(1, 9);
        class = TFClassType:tInt;
        TF2_SetPlayerClass(client, class, false, false);

        SetEntityHealth(client, classHealth[tInt]);
        SetClassSpeed(client, class);
    }

    if (client && IsPlayerAlive(client))
    {
        for (new i = 0; i <= 5; i++)
        {
            TF2_RemoveWeaponSlot(client, i);
        }

        if (GetConVarBool(g_hCvarSlotA))
        {
            KvJumpToKey(hKVb, "Slot1");
            IntToString(GetRandomInt(1,SLOTONEWEAPONSMAX),tStr,sizeof(tStr));
            KvGetString(hKVb,tStr,weapon,sizeof(weapon),"");
            GiveWeapon(client, weapon);
            KvRewind(hKVb);
        }

        if (GetConVarBool(g_hCvarSlotB))
        {
            KvJumpToKey(hKVb, "Slot2");
            IntToString(GetRandomInt(1,SLOTTWOWEAPONSMAX),tStr,sizeof(tStr));
            KvGetString(hKVb,tStr,weapon,sizeof(weapon),"");
            GiveWeapon(client, weapon);
            KvRewind(hKVb);
        }

        if (GetConVarBool(g_hCvarSlotC))
        {
            KvJumpToKey(hKVb, "Slot3");
            IntToString(GetRandomInt(1,SLOTTHREEWEAPONSMAX),tStr,sizeof(tStr));
            KvGetString(hKVb,tStr,weapon,sizeof(weapon),"");
            GiveWeapon(client, weapon);
            KvRewind(hKVb);
        }

        new weaponId = GetPlayerWeaponSlot(client, 0);
        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponId);
    }
}

SetClassSpeed(client, TFClassType:class)
{
    switch (class)
    {
        case TFClass_Scout:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 400.0);
        case TFClass_Sniper:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
        case TFClass_Soldier:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 240.0);
        case TFClass_DemoMan:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 280.0);
        case TFClass_Medic:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 320.0);
        case TFClass_Heavy:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 230.0);
        case TFClass_Pyro:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
        case TFClass_Spy:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
        case TFClass_Engineer:
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
    }
}

GiveWeapon(client,const String:weaponName[64])
{
    if (!KvJumpToKey(hKV, weaponName))
    {
        ReplyToCommand(client, "[SM] Invalid weapon name.");
        return;
    }

    new weaponSlot = KvGetNum(hKV, "slot");
    new weaponClip = KvGetNum(hKV, "clip");
    new weaponMax = KvGetNum(hKV, "max");

    KvRewind(hKV);

    TF2_RemoveWeaponSlot(client, weaponSlot - 1);

    new weaponEntity = SDKCall(hGiveNamedItem, client, weaponName, 0, 0);
    SDKCall(hWeaponEquip, client, weaponEntity);

    if (weaponMax != -1)
    {
        SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + weaponSlot * 4, weaponMax);
        SetEntData(GetPlayerWeaponSlot(client, weaponSlot - 1), FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), weaponClip);
    }

    return;
}