#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
#define MAX_WEAPONS_PER_CLASS 32
#define REGEN_DELAY 0.1

enum WearableType
{
    Wearable_None,
    Wearable_DemoShield,
    Wearable_SoldierSecondary,
    Wearable_SniperSecondary,
    Wearable_Razorback,
    Wearable_DemoBoots,
    Wearable_Regular
};

public Plugin myinfo = 
{
    name = "TF2 Auto Item Giver",
    author = "",
    description = "Automatically gives weapons and wearables to players on spawn or regeneration",
    version = PLUGIN_VERSION,
    url = ""
}

// Weapon variables
int g_iAutoGiveWeapon[MAXPLAYERS + 1];

// Wearable variables
Handle g_hWearableEquip;
ArrayList g_hAutoWearables[MAXPLAYERS+1];

public void OnPluginStart()
{
    // Weapon commands
    RegAdminCmd("sm_givewep", Command_GiveWeapon, ADMFLAG_GENERIC, "Give weapon to player: sm_givewep <@red/@blue/@all/@me/@aim/@bots/name> <ID>");
    RegAdminCmd("sm_auto_givewep", Command_AutoGiveWeapon, ADMFLAG_GENERIC, "Automatically give weapon to player on spawn/regenerate: sm_auto_givewep <@red/@blue/@all/@me/@aim/name> <ID>");
    RegAdminCmd("sm_stop_auto_give", Command_StopAutoGiveWeapon, ADMFLAG_GENERIC, "Stop auto-giving weapon to player: sm_stop_auto_givewea <@red/@blue/@all/@me/@aim/name>");
    
    // Wearable commands
    RegAdminCmd("sm_givewea", Command_GiveWearable, ADMFLAG_GENERIC, "Give wearable to player: sm_givewea <@red/@blue/@all/@me/@aim/name> <ID>");
    RegAdminCmd("sm_auto_givewea", Command_AutoGiveWearable, ADMFLAG_GENERIC, "Auto give wearable to player: sm_auto_givewea <@red/@blue/@all/@me/@aim/name> <ID>");
    RegAdminCmd("sm_stop_auto_givewea", Command_RemoveAutoGiveWearable, ADMFLAG_GENERIC, "Remove auto give wearable: sm_remove_auto_givewea <@red/@blue/@all/@me/@aim/name>");
    
    HookEvent("player_spawn", Event_PlayerSpawn);
    
    // Initialize wearable arrays
    for (int i = 0; i <= MAXPLAYERS; i++)
    {
        g_hAutoWearables[i] = new ArrayList();
        g_iAutoGiveWeapon[i] = -1;
    }
    
    // Set up wearable SDKCall
    GameData hTF2 = LoadGameConfigFile("sm-tf2.games");
    if (!hTF2)
        SetFailState("Could not load sm-tf2.games gamedata");

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetVirtual(hTF2.GetOffset("RemoveWearable") - 1);
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    g_hWearableEquip = EndPrepSDKCall();

    if (!g_hWearableEquip)
        SetFailState("Failed to create call: CBasePlayer::EquipWearable");

    delete hTF2;
    
    // Hook regenerators
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "func_regenerate")) != -1)
    {
        SDKHook(entity, SDKHook_StartTouch, OnRegenerateStartTouch);
    }
}

public void OnMapStart()
{
    // Re-hook regenerators
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "func_regenerate")) != -1)
    {
        SDKHook(entity, SDKHook_StartTouch, OnRegenerateStartTouch);
    }
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "func_regenerate"))
    {
        SDKHook(entity, SDKHook_StartTouch, OnRegenerateStartTouch);
    }
}

public void OnClientDisconnect(int client)
{
    delete g_hAutoWearables[client];
    g_hAutoWearables[client] = new ArrayList();
    g_iAutoGiveWeapon[client] = -1;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client && IsClientInGame(client))
    {
        CreateTimer(0.1, Timer_GiveAutoItems, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
    return Plugin_Continue;
}

public Action OnRegenerateStartTouch(int entity, int client)
{
    if (1 <= client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
    {
        DataPack pack = new DataPack();
        pack.WriteCell(GetClientUserId(client));
        CreateTimer(REGEN_DELAY, Timer_RegenGiveItems, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
    }
    return Plugin_Continue;
}

public Action Timer_RegenGiveItems(Handle timer, DataPack pack)
{
    pack.Reset();
    int client = GetClientOfUserId(pack.ReadCell());
    
    if (client && IsClientInGame(client) && IsPlayerAlive(client))
    {
        GiveAutoItems(client);
    }
    return Plugin_Stop;
}

public Action Timer_GiveAutoItems(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client && IsClientInGame(client) && IsPlayerAlive(client))
    {
        GiveAutoItems(client);
    }
    return Plugin_Stop;
}

void GiveAutoItems(int client)
{
    // Give auto weapons
    int weaponID = g_iAutoGiveWeapon[client];
    if (weaponID != -1)
    {
        GiveWeapon(client, weaponID);
    }
    
    // Give auto wearables
    int count = g_hAutoWearables[client].Length;
    if (count > 0)
    {
        for (int i = 0; i < count; i++)
        {
            int itemID = g_hAutoWearables[client].Get(i);
            GiveWearable(client, itemID);
        }
    }
}

// ============================================
// WEAPON COMMANDS AND FUNCTIONS
// ============================================

public Action Command_AutoGiveWeapon(int client, int args)
{
    if (args < 2)
    {
        ReplyToCommand(client, "[SM] Usage: sm_auto_givewep <@red/@blue/@all/@me/@aim/name> <ID>");
        return Plugin_Handled;
    }

    char arg1[64], arg2[64];
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));
    int weaponID = StringToInt(arg2);
    if (weaponID < 0)
    {
        ReplyToCommand(client, "[SM] Invalid weapon ID");
        return Plugin_Handled;
    }

    int targets[MAXPLAYERS];
    char target_name[MAX_TARGET_LENGTH];
    bool tn_is_ml;
    int targetCount = ProcessTargetString(
        arg1,
        client,
        targets,
        MAXPLAYERS,
        COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_IMMUNITY,
        target_name,
        sizeof(target_name),
        tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToCommand(client, "[SM] No matching players found");
        return Plugin_Handled;
    }

    for (int i = 0; i < targetCount; i++)
    {
        int target = targets[i];
        if (IsClientInGame(target))
        {
            g_iAutoGiveWeapon[target] = weaponID;
            char name[MAX_NAME_LENGTH];
            GetClientName(target, name, sizeof(name));
            ReplyToCommand(client, "[SM] Will auto-give weapon %d to %s on spawn/regenerate", weaponID, name);
            
            if (IsPlayerAlive(target))
            {
                GiveWeapon(target, weaponID);
            }
        }
    }

    return Plugin_Handled;
}

public Action Command_StopAutoGiveWeapon(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_stop_auto_givewea <@red/@blue/@all/@me/@aim/name>");
        return Plugin_Handled;
    }

    char arg1[64];
    GetCmdArg(1, arg1, sizeof(arg1));

    int targets[MAXPLAYERS];
    char target_name[MAX_TARGET_LENGTH];
    bool tn_is_ml;
    int targetCount = ProcessTargetString(
        arg1,
        client,
        targets,
        MAXPLAYERS,
        COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_IMMUNITY,
        target_name,
        sizeof(target_name),
        tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToCommand(client, "[SM] No matching players found");
        return Plugin_Handled;
    }

    for (int i = 0; i < targetCount; i++)
    {
        int target = targets[i];
        if (IsClientInGame(target))
        {
            g_iAutoGiveWeapon[target] = -1;
            char name[MAX_NAME_LENGTH];
            GetClientName(target, name, sizeof(name));
            ReplyToCommand(client, "[SM] Stopped auto-giving weapons to %s", name);
        }
    }
    return Plugin_Handled;
}

public Action Command_GiveWeapon(int client, int args)
{
    if (args < 2)
    {
        ReplyToCommand(client, "[SM] Usage: sm_givewep <@red/@blue/@all/@me/@aim/@bots/name> <ID>");
        return Plugin_Handled;
    }

    char arg1[64], arg2[64];
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));
    int weaponID = StringToInt(arg2);
    if (weaponID < 0)
    {
        ReplyToCommand(client, "[SM] Invalid weapon ID");
        return Plugin_Handled;
    }

    int targets[MAXPLAYERS];
    char target_name[MAX_TARGET_LENGTH];
    bool tn_is_ml;
    int targetCount;

    if (StrEqual(arg1, "@red"))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) == TFTeam_Red)
            {
                targets[targetCount++] = i;
            }
        }
    }
    else if (StrEqual(arg1, "@blue"))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) == TFTeam_Blue)
            {
                targets[targetCount++] = i;
            }
        }
    }
    else if (StrEqual(arg1, "@all"))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i))
            {
                targets[targetCount++] = i;
            }
        }
    }
    else if (StrEqual(arg1, "@me"))
    {
        if (IsClientInGame(client) && IsPlayerAlive(client))
        {
            targets[targetCount++] = client;
        }
    }
    else if (StrEqual(arg1, "@aim"))
    {
        int target = GetClientAimTarget(client, true);
        if (target != -1 && IsClientInGame(target) && IsPlayerAlive(target))
        {
            targets[targetCount++] = target;
        }
    }
    else if (StrEqual(arg1, "@bots"))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i) && IsFakeClient(i))
            {
                targets[targetCount++] = i;
            }
        }
    }
    else
    {
        targetCount = ProcessTargetString(
            arg1,
            client,
            targets,
            MAXPLAYERS,
            COMMAND_FILTER_ALIVE,
            target_name,
            sizeof(target_name),
            tn_is_ml);
    }

    if (targetCount <= 0)
    {
        ReplyToCommand(client, "[SM] No matching players found");
        return Plugin_Handled;
    }

    for (int i = 0; i < targetCount; i++)
    {
        int target = targets[i];
        if (GiveWeapon(target, weaponID))
        {
            char name[MAX_NAME_LENGTH];
            GetClientName(target, name, sizeof(name));
            ReplyToCommand(client, "[SM] Gave weapon %d to %s", weaponID, name);
        }
    }
    return Plugin_Handled;
}

bool GiveWeapon(int client, int itemIndex)
{
    char classname[64];
    int slot = 0;
    bool isSaxxy = (itemIndex == 423 || itemIndex == 474 || itemIndex == 264  || itemIndex == 423  || itemIndex == 474 || itemIndex == 880 || itemIndex == 939 || itemIndex == 954 || itemIndex == 1013 || itemIndex == 1071 || itemIndex == 1123 || itemIndex == 1127 || itemIndex == 30758);
    
    if (itemIndex == 1101)
    {
        classname = "tf_weapon_parachute";
        switch(TF2_GetPlayerClass(client))
        {
            case TFClass_Soldier:
                slot = -1;
            case TFClass_DemoMan:
                slot = -1;
            case TFClass_Scout:
                slot = -1;
            case TFClass_Pyro:
                slot = -1;
            case TFClass_Sniper:
                slot = -1;
            case TFClass_Medic:
                slot = -1;
            case TFClass_Heavy:
                slot = -1;
            case TFClass_Spy:
                slot = -1;
            case TFClass_Engineer:
                slot = -1;
            default:
                return false;
        }
    }

    if (itemIndex == 199 || itemIndex == 1141 || itemIndex == 1153 || itemIndex == 15003 || itemIndex == 15016 || itemIndex == 15044 || itemIndex == 15047 || itemIndex == 15085 || itemIndex == 15109 || itemIndex == 15132 || itemIndex == 15133 || itemIndex == 15152)
    {
        switch(TF2_GetPlayerClass(client))
        {
            case TFClass_Engineer:
            {
                classname = "tf_weapon_shotgun_primary";
                slot = 0; 
            }
            case TFClass_Soldier, TFClass_Pyro, TFClass_Heavy:
            {
                classname = "tf_weapon_shotgun_soldier";
                slot = 1; 
            }
            default:
            {
                return false;
            }
        }
    }

    if (itemIndex == 1152)
    {
        classname = "tf_weapon_grapplinghook";
        switch(TF2_GetPlayerClass(client))
        {
            case TFClass_Soldier:
                slot = 6;
            case TFClass_DemoMan:
                slot = 6;
            case TFClass_Scout:
                slot = 6;
            case TFClass_Pyro:
                slot = 6;
            case TFClass_Sniper:
                slot = 6;
            case TFClass_Medic:
                slot = 6;
            case TFClass_Heavy:
                slot = 6;
            case TFClass_Spy:
                slot = 6;
            case TFClass_Engineer:
                slot = 6;
            default:
                return false;
        }
    }
    
    if (isSaxxy)
    {
        switch(TF2_GetPlayerClass(client))
        {
            case TFClass_Scout: classname = "tf_weapon_bat";
            case TFClass_Soldier: classname = "tf_weapon_shovel";
            case TFClass_Pyro: classname = "tf_weapon_club";
            case TFClass_DemoMan: classname = "tf_weapon_bottle";
            case TFClass_Heavy: classname = "tf_weapon_club";
            case TFClass_Engineer: classname = "tf_weapon_wrench";
            case TFClass_Medic: classname = "tf_weapon_bonesaw";
            case TFClass_Sniper: classname = "tf_weapon_club";
            case TFClass_Spy: classname = "tf_weapon_knife";
        }
        slot = 2;
    }
    else if (itemIndex == 13 || itemIndex == 200 || itemIndex == 45 || itemIndex == 669 || itemIndex == 799 || itemIndex == 808 || itemIndex == 888 || itemIndex == 897 || itemIndex == 906 || itemIndex == 915 || itemIndex == 964 || itemIndex == 973 || itemIndex == 1078 || itemIndex == 1103 || itemIndex == 15002 || itemIndex == 15015 || itemIndex == 15021 || itemIndex == 15029 || itemIndex == 15036 || itemIndex == 15053 || itemIndex == 15065 || itemIndex == 15069 || itemIndex == 15106 || itemIndex == 15107 || itemIndex == 15108 ||  itemIndex == 15131 || itemIndex == 15133 || itemIndex == 15151 || itemIndex == 15157)
    {
        classname = "tf_weapon_scattergun";
        slot = 0;
    }
    else if (itemIndex == 220)
    {
        classname = "tf_weapon_handgun_scout_primary";
        slot = 0;
    }
    else if (itemIndex == 448)
    {
        classname = "tf_weapon_soda_popper";
        slot = 0;
    }
    else if (itemIndex == 772)
    {
        classname = "tf_weapon_pep_brawler_blaster";
        slot = 0;
    }
    else if ( itemIndex == 22 || itemIndex == 23 || itemIndex == 209 || itemIndex == 160 || itemIndex == 294 || itemIndex == 15013 || itemIndex == 15018 || itemIndex == 15035 || itemIndex == 15041 || itemIndex == 15046 || itemIndex == 15056 || itemIndex == 15060 || itemIndex == 15061 || itemIndex == 15100 || itemIndex == 15101 || itemIndex == 15102 || itemIndex == 15126 || itemIndex == 15148 || itemIndex == 30666)
    {
        classname = "tf_weapon_pistol";
        slot = 1;
    }
    else if (itemIndex == 46 || itemIndex == 163 || itemIndex == 1145)
    {
        classname = "tf_weapon_lunchbox_drink";
        slot = 1;
    }
    else if (itemIndex == 449 || itemIndex == 773)
    {
        classname = "tf_weapon_handgun_scout_secondary";
        slot = 1;
    }
    else if (itemIndex == 222 || itemIndex == 1121)
    {
        classname = "tf_weapon_jar_milk";
        slot = 1;
    }
    else if (itemIndex == 812 || itemIndex == 833)
    {
        classname = "tf_weapon_cleaver";
        slot = 1;
    }
    else if (itemIndex == 0 || itemIndex == 190 || itemIndex == 317 || itemIndex == 325 || itemIndex == 349 || itemIndex == 355 || itemIndex == 450 || itemIndex == 452 || itemIndex == 660 || itemIndex == 30667)
    {
        classname = "tf_weapon_bat";
        slot = 2;
    }
    else if (itemIndex == 44)
    {
        classname = "tf_weapon_bat_wood";
        slot = 2;
    }
    else if (itemIndex == 221 || itemIndex == 572  || itemIndex == 999)
    {
        classname = "tf_weapon_bat_fish";
        slot = 2;
    }
    else if (itemIndex == 648)
    {
        classname = "tf_weapon_bat_giftwrap";
        slot = 2;
    }
    else if (itemIndex == 18 || itemIndex == 205 || itemIndex == 228 || itemIndex == 237 || itemIndex == 414 || itemIndex == 513 || itemIndex == 658 || itemIndex == 730 || itemIndex == 800 || itemIndex == 809 || itemIndex == 889 || itemIndex == 898 || itemIndex == 907 || itemIndex == 916 || itemIndex == 965 || itemIndex == 974 || itemIndex == 1085 || itemIndex == 15006 || itemIndex == 15014 || itemIndex == 15028 || itemIndex == 15043 || itemIndex == 15052 || itemIndex == 15057 || itemIndex == 15081 || itemIndex == 15104 || itemIndex == 15105 || itemIndex == 15129 || itemIndex == 15130 || itemIndex == 15150) 
    {
        classname = "tf_weapon_rocketlauncher";
        slot = 0;
    }
    else if (itemIndex == 127)
    {
        classname = "tf_weapon_rocketlauncher_directhit";
        slot = 0;
    }
    else if (itemIndex == 441)
    {
        classname = "tf_weapon_particle_cannon";
        slot = 0;
    }
    else if (itemIndex == 1104)
    {
        classname = "tf_weapon_rocketlauncher_airstrike";
        slot = 0;
    }
    else if (itemIndex == 10 || itemIndex == 415) 
    {
        classname = "tf_weapon_shotgun_soldier";
        slot = 1;
    }
    else if (itemIndex == 442) 
    {
        classname = "tf_weapon_raygun";
        slot = 1;
    }
    else if (itemIndex == 129 || itemIndex == 226  || itemIndex == 354  || itemIndex == 1001)
    {
        classname = "tf_weapon_buff_item";
        slot = 1;
    }
    else if (itemIndex == 6 || itemIndex == 196 || itemIndex == 128 || itemIndex == 154 || itemIndex == 264 || itemIndex == 416 || itemIndex == 447 || itemIndex == 775) 
    {
        classname = "tf_weapon_shovel";
        slot = 2;
    }
    else if (itemIndex == 357) 
    {
        classname = "tf_weapon_katana";
        slot = 2;
    }
    else if (itemIndex == 21 || itemIndex == 208 || itemIndex == 40 || itemIndex == 215 || itemIndex == 594 || itemIndex == 659 || itemIndex == 741 || itemIndex == 798 || itemIndex == 807 || itemIndex == 887 || itemIndex == 896 || itemIndex == 905 || itemIndex == 914 || itemIndex == 963 || itemIndex == 972 || itemIndex == 1146 || itemIndex == 15005 || itemIndex == 15017 || itemIndex == 15030 || itemIndex == 15034 || itemIndex == 15049 || itemIndex == 15054 || itemIndex == 15066 || itemIndex == 15067 || itemIndex == 15068 || itemIndex == 15089 || itemIndex == 15090 || itemIndex == 15115 || itemIndex == 15141 || itemIndex == 30474)
    {
        classname = "tf_weapon_flamethrower";
        slot = 0;
    }
    else if (itemIndex == 1178) 
    {
        classname = "tf_weapon_rocketlauncher_fireball";
        slot = 0;
    }
    else if (itemIndex == 12) 
    {
        classname = "tf_weapon_shotgun_pyro";
        slot = 1;
    }
    else if (itemIndex == 39 || itemIndex == 351 || itemIndex == 740 || itemIndex == 1081) 
    {
        classname = "tf_weapon_flaregun";
        slot = 1;
    }
    else if (itemIndex == 595) 
    {
        classname = "tf_weapon_flaregun_revenge";
        slot = 1;
    }
    else if (itemIndex == 1179) 
    {
        classname = "tf_weapon_rocketpack";
        slot = 1;
    }
    else if (itemIndex == 1180) 
    {
        classname = "tf_weapon_jar_gas";
        slot = 1;
    }
    else if (itemIndex == 2 || itemIndex == 192 || itemIndex == 38 || itemIndex == 153 || itemIndex == 214 || itemIndex == 326 || itemIndex == 348 || itemIndex == 457 || itemIndex == 466 || itemIndex == 593 || itemIndex == 739 || itemIndex == 1000)
    {
        classname = "tf_weapon_fireaxe";
        slot = 2;
    }
    else if (itemIndex == 813 || itemIndex == 834)
    {
        classname = "tf_weapon_breakable_sign";
        slot = 2;
    }
    else if (itemIndex == 1181)
    {
        classname = "tf_weapon_slap";
        slot = 2;
    }
    else if (itemIndex == 19 || itemIndex == 206 || itemIndex == 308 || itemIndex == 1007 || itemIndex == 1151 || itemIndex == 15077 || itemIndex == 15079 || itemIndex == 15091 || itemIndex == 15092 || itemIndex == 15116 || itemIndex == 15117 || itemIndex == 15142 || itemIndex == 15158)
    {
        classname = "tf_weapon_grenadelauncher";
        slot = 0;
    }
    else if (itemIndex == 996)
    {
        classname = "tf_weapon_cannon";
        slot = 0;
    }
    else if (itemIndex == 996)
    {
        classname = "tf_weapon_cannon";
        slot = 0;
    }
    else if (itemIndex == 20 || itemIndex == 207 || itemIndex == 130 || itemIndex == 265 || itemIndex == 661 || itemIndex == 797 || itemIndex == 806 || itemIndex == 886 || itemIndex == 895 || itemIndex == 904 || itemIndex == 913 || itemIndex == 962 || itemIndex == 971 || itemIndex == 1150 || itemIndex == 15009 || itemIndex == 15012 || itemIndex == 15024 || itemIndex == 15038 || itemIndex == 15045 || itemIndex == 15048 || itemIndex == 15082 || itemIndex == 15083 || itemIndex == 15084 || itemIndex == 15113 || itemIndex == 15137 || itemIndex == 15138 || itemIndex == 15155)
    {
        classname = "tf_weapon_pipebomblauncher";
        slot = 1;
    }
    else if (itemIndex == 1 || itemIndex == 191 || itemIndex == 609)
    {
        classname = "tf_weapon_bottle";
        slot = 2;
    }
    else if (itemIndex == 132 || itemIndex == 172 || itemIndex == 266 || itemIndex == 327 || itemIndex == 404 || itemIndex == 482 || itemIndex == 1082)
    {
        classname = "tf_weapon_sword";
        slot = 2;
    }
    else if (itemIndex == 307)
    {
        classname = "tf_weapon_stickbomb";
        slot = 2;
    }
    else if (itemIndex == 15 || itemIndex == 202 || itemIndex == 41 || itemIndex == 298 || itemIndex == 312 || itemIndex == 424 || itemIndex == 654 || itemIndex == 793 || itemIndex == 802 || itemIndex == 811 || itemIndex == 832 || itemIndex == 850 || itemIndex == 882 || itemIndex == 891 || itemIndex == 900 || itemIndex == 909 || itemIndex == 958 || itemIndex == 967 || itemIndex == 15004 || itemIndex == 15020 || itemIndex == 15026 || itemIndex == 15031 || itemIndex == 15040 || itemIndex == 15055 || itemIndex == 15086 || itemIndex == 15087 || itemIndex == 15088 || itemIndex == 15098 || itemIndex == 15099 || itemIndex == 15123 || itemIndex == 15124 || itemIndex == 15125 || itemIndex == 15147)
    {
        classname = "tf_weapon_minigun";
        slot = 0;
    }
    else if (itemIndex == 11 || itemIndex == 425)
    {
        classname = "tf_weapon_shotgun_hwg";
        slot = 1;
    }
    else if (itemIndex == 42 || itemIndex == 159 || itemIndex == 311 || itemIndex == 433 || itemIndex == 863 || itemIndex == 1002 || itemIndex == 1190)
    {
        classname = "tf_weapon_lunchbox";
        slot = 1;
    }
    else if (itemIndex == 5 || itemIndex == 195 || itemIndex == 43 || itemIndex == 239 || itemIndex == 310 || itemIndex == 331 || itemIndex == 426 || itemIndex == 587 || itemIndex == 656 || itemIndex == 1084 || itemIndex == 1100 || itemIndex == 1184)
    {
        classname = "tf_weapon_fists";
        slot = 2;
    }
    else if (itemIndex == 9 || itemIndex == 527)
    {
        classname = "tf_weapon_shotgun_primary";
        slot = 0;
    }
    else if (itemIndex == 141 || itemIndex == 1004)
    {
        classname = "tf_weapon_sentry_revenge";
        slot = 0;
    }
    else if (itemIndex == 588)
    {
        classname = "tf_weapon_drg_pomson";
        slot = 0;
    }
    else if (itemIndex == 997)
    {
        classname = "tf_weapon_shotgun_building_rescue";
        slot = 0;
    }
    else if (itemIndex == 140 || itemIndex == 1086 || itemIndex == 30668)
    {
        classname = "tf_weapon_laser_pointer";
        slot = 1;
    }
    else if (itemIndex == 528	)
    {
        classname = "tf_weapon_mechanical_arm";
        slot = 1;
    }
    else if (itemIndex == 7 || itemIndex == 197 || itemIndex == 155 || itemIndex == 169 || itemIndex == 329 || itemIndex == 589 || itemIndex == 662 || itemIndex == 795 || itemIndex == 804 || itemIndex == 884 || itemIndex == 893 || itemIndex == 902 || itemIndex == 911 || itemIndex == 960 || itemIndex == 969 || itemIndex == 15073 || itemIndex == 15074 || itemIndex == 15075 || itemIndex == 15139 || itemIndex == 15140 || itemIndex == 15114 || itemIndex == 15156)
    {
        classname = "tf_weapon_wrench";
        slot = 2;
    }
    else if (itemIndex == 142)
    {
        classname = "tf_weapon_robot_arm";
        slot = 3;
    }
    else if (itemIndex == 17 || itemIndex == 204 || itemIndex == 36 || itemIndex == 412)
    {
        classname = "tf_weapon_syringegun_medic";
        slot = 0;
    }
    else if (itemIndex == 305 || itemIndex == 1079)
    {
        classname = "tf_weapon_crossbow";
        slot = 0;
    }
    else if (itemIndex == 29 || itemIndex == 211 || itemIndex == 35 || itemIndex == 411 || itemIndex == 663 || itemIndex == 796 || itemIndex == 805 || itemIndex == 885 || itemIndex == 894 || itemIndex == 903 || itemIndex == 912 || itemIndex == 961 || itemIndex == 970 || itemIndex == 998 || itemIndex == 15008 || itemIndex == 15010 || itemIndex == 15025 || itemIndex == 15039 || itemIndex == 15050 || itemIndex == 15078 || itemIndex == 15097 || itemIndex == 15121 || itemIndex == 15122 || itemIndex == 15145 || itemIndex == 15146)
    {
        classname = "tf_weapon_medigun";
        slot = 1;
    }
    else if (itemIndex == 8 || itemIndex == 198 || itemIndex == 37 || itemIndex == 173 || itemIndex == 304 || itemIndex == 413 || itemIndex == 1003 || itemIndex == 1143)
    {
        classname = "tf_weapon_bonesaw";
        slot = 2;
    }
    else if (itemIndex == 14 || itemIndex == 201 || itemIndex == 230 || itemIndex == 526 || itemIndex == 664 || itemIndex == 752 || itemIndex == 792 || itemIndex == 801 || itemIndex == 851 || itemIndex == 881 || itemIndex == 890 || itemIndex == 899 || itemIndex == 908 || itemIndex == 957 || itemIndex == 966 || itemIndex == 15000 || itemIndex == 15007 || itemIndex == 15019 || itemIndex == 15023 || itemIndex == 15033 || itemIndex == 15059 || itemIndex == 15070 || itemIndex == 15071 || itemIndex == 15072 || itemIndex == 15111 || itemIndex == 15112 || itemIndex == 15135 || itemIndex == 15136 || itemIndex == 15154 || itemIndex == 30665)
    {
        classname = "tf_weapon_sniperrifle";
        slot = 0;
    }
    else if (itemIndex == 56 || itemIndex == 1005 || itemIndex == 1092)
    {
        classname = "tf_weapon_compound_bow";
        slot = 0;
    }
    else if (itemIndex == 402)
    {
        classname = "tf_weapon_sniperrifle_decap";
        slot = 0;
    }
    else if (itemIndex == 1098)
    {
        classname = "tf_weapon_sniperrifle_classic";
        slot = 0;
    }
    else if (itemIndex == 16 || itemIndex == 203 || itemIndex == 1149 || itemIndex == 15001 || itemIndex == 15022 || itemIndex == 15032 || itemIndex == 15037 || itemIndex == 15058 || itemIndex == 15076 || itemIndex == 15110 || itemIndex == 15134 || itemIndex == 15153)
    {
        classname = "tf_weapon_smg";
        slot = 1;
    }
    else if (itemIndex == 58 || itemIndex == 1083 || itemIndex == 1105)
    {
        classname = "tf_weapon_jar";
        slot = 1;
    }
    else if (itemIndex == 751)
    {
        classname = "tf_weapon_charged_smg";
        slot = 1;
    }
    else if (itemIndex == 3 || itemIndex == 193 || itemIndex == 171 || itemIndex == 232 || itemIndex == 401)
    {
        classname = "tf_weapon_club";
        slot = 2;
    }
    else if (itemIndex == 24 || itemIndex == 210 || itemIndex == 61 || itemIndex == 161 || itemIndex == 224 || itemIndex == 460 || itemIndex == 525 || itemIndex == 1006 || itemIndex == 1142 || itemIndex == 15011 || itemIndex == 15027 || itemIndex == 15042 || itemIndex == 15051 || itemIndex == 15062 || itemIndex == 15063 || itemIndex == 15064 || itemIndex == 15103 || itemIndex == 15128 || itemIndex == 15127 || itemIndex == 15149)
    {
        classname = "tf_weapon_revolver";
        slot = 0;
    }
    else if (itemIndex == 735 || itemIndex == 736 || itemIndex == 810 || itemIndex == 831 || itemIndex == 933 || itemIndex == 1080 || itemIndex == 1102)
    {
        classname = "tf_weapon_sapper";
        slot = 1;
    }
    else if (itemIndex == 4 || itemIndex == 194 || itemIndex == 225 || itemIndex == 356 || itemIndex == 461 || itemIndex == 574 || itemIndex == 638 || itemIndex == 649 || itemIndex == 665 || itemIndex == 727 || itemIndex == 794 || itemIndex == 803 || itemIndex == 883 || itemIndex == 892 || itemIndex == 901 || itemIndex == 910 || itemIndex == 959 || itemIndex == 968 || itemIndex == 15094 || itemIndex == 15095 || itemIndex == 15096 || itemIndex == 15118 || itemIndex == 15119 || itemIndex == 15143 || itemIndex == 15144)
    {
        classname = "tf_weapon_knife";
        slot = 2;
    }
    else if (itemIndex == 27)
    {
        classname = "tf_weapon_pda_spy";
        slot = 3;
    }
    else if (itemIndex == 30 || itemIndex == 212 || itemIndex == 59 || itemIndex == 60 || itemIndex == 297 || itemIndex == 947)
    {
        classname = "tf_weapon_invis";
        slot = 4;
    }

    int weapon = CreateEntityByName(classname);
    if (!IsValidEntity(weapon))
    {
        return false;
    }

    SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", itemIndex);
    SetEntProp(weapon, Prop_Send, "m_bInitialized", 1);
    
    if (isSaxxy)
    {
        SetEntProp(weapon, Prop_Send, "m_iEntityQuality", 6);
        SetEntProp(weapon, Prop_Send, "m_iEntityLevel", 100);
        SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
    }
    else
    {
        SetEntProp(weapon, Prop_Send, "m_iEntityQuality", 0);
        SetEntProp(weapon, Prop_Send, "m_iEntityLevel", 0);
    }
    int oldWeapon = GetPlayerWeaponSlot(client, slot);
    if (oldWeapon != -1)
    {
        RemovePlayerItem(client, oldWeapon);
        AcceptEntityInput(oldWeapon, "Kill");
    }
    DispatchSpawn(weapon);
    EquipPlayerWeapon(client, weapon);
    
    if (isSaxxy)
    {
        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
        CreateTimer(0.1, Timer_ForceWeaponSwitch, GetClientUserId(client));
    }
    return true;
}

public Action Timer_ForceWeaponSwitch(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client && IsClientInGame(client))
    {
        int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        if (weapon != -1)
        {
            SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + 0.1);
            SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.1);
        }
    }
    return Plugin_Stop;
}

// ============================================
// WEARABLE COMMANDS AND FUNCTIONS
// ============================================

public Action Command_GiveWearable(int client, int args)
{
    if (args < 2)
    {
        ReplyToCommand(client, "[SM] Usage: sm_givewea <@red/@blue/@all/@me/@aim/name> <ID>");
        return Plugin_Handled;
    }

    char arg1[64], arg2[64];
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));

    int weaponID = StringToInt(arg2);
    if (weaponID <= 0)
    {
        ReplyToCommand(client, "[SM] Invalid weapon ID");
        return Plugin_Handled;
    }

    int targets[MAXPLAYERS];
    char target_name[MAX_TARGET_LENGTH];
    bool tn_is_ml;
    int targetCount;

    if (StrEqual(arg1, "@red"))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) == TFTeam_Red)
            {
                targets[targetCount++] = i;
            }
        }
    }
    else if (StrEqual(arg1, "@blue"))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) == TFTeam_Blue)
            {
                targets[targetCount++] = i;
            }
        }
    }
    else if (StrEqual(arg1, "@all"))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i))
            {
                targets[targetCount++] = i;
            }
        }
    }
    else if (StrEqual(arg1, "@me"))
    {
        if (IsClientInGame(client) && IsPlayerAlive(client))
        {
            targets[targetCount++] = client;
        }
    }
    else if (StrEqual(arg1, "@aim"))
    {
        int target = GetClientAimTarget(client, true);
        if (target != -1 && IsClientInGame(target) && IsPlayerAlive(target))
        {
            targets[targetCount++] = target;
        }
    }
    else
    {
        targetCount = ProcessTargetString(
            arg1,
            client,
            targets,
            MAXPLAYERS,
            COMMAND_FILTER_ALIVE,
            target_name,
            sizeof(target_name),
            tn_is_ml);
    }

    if (targetCount <= 0)
    {
        ReplyToCommand(client, "[SM] No matching players found");
        return Plugin_Handled;
    }

    for (int i = 0; i < targetCount; i++)
    {
        int target = targets[i];
        if (GiveWearable(target, weaponID))
        {
            char name[MAX_NAME_LENGTH];
            GetClientName(target, name, sizeof(name));
            ReplyToCommand(client, "[SM] Gave wearable %d to %s", weaponID, name);
        }
    }

    return Plugin_Handled;
}

public Action Command_AutoGiveWearable(int client, int args)
{
    if (args < 2)
    {
        ReplyToCommand(client, "[SM] Usage: sm_auto_givewea <@red/@blue/@all/@me/@aim/name> <ID>");
        return Plugin_Handled;
    }

    char arg1[64], arg2[64];
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));

    int weaponID = StringToInt(arg2);
    if (weaponID <= 0)
    {
        ReplyToCommand(client, "[SM] Invalid weapon ID");
        return Plugin_Handled;
    }

    int targets[MAXPLAYERS];
    char target_name[MAX_TARGET_LENGTH];
    bool tn_is_ml;
    int targetCount;

    if (StrEqual(arg1, "@red"))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && TF2_GetClientTeam(i) == TFTeam_Red)
            {
                targets[targetCount++] = i;
            }
        }
    }
    else if (StrEqual(arg1, "@blue"))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && TF2_GetClientTeam(i) == TFTeam_Blue)
            {
                targets[targetCount++] = i;
            }
        }
    }
    else if (StrEqual(arg1, "@all"))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                targets[targetCount++] = i;
            }
        }
    }
    else if (StrEqual(arg1, "@me"))
    {
        if (IsClientInGame(client))
        {
            targets[targetCount++] = client;
        }
    }
    else if (StrEqual(arg1, "@aim"))
    {
        int target = GetClientAimTarget(client, true);
        if (target != -1 && IsClientInGame(target))
        {
            targets[targetCount++] = target;
        }
    }
    else
    {
        targetCount = ProcessTargetString(
            arg1,
            client,
            targets,
            MAXPLAYERS,
            COMMAND_FILTER_NO_IMMUNITY,
            target_name,
            sizeof(target_name),
            tn_is_ml);
    }

    if (targetCount <= 0)
    {
        ReplyToCommand(client, "[SM] No matching players found");
        return Plugin_Handled;
    }

    for (int i = 0; i < targetCount; i++)
    {
        int target = targets[i];
        if (g_hAutoWearables[target].FindValue(weaponID) == -1)
        {
            g_hAutoWearables[target].Push(weaponID);
            char name[MAX_NAME_LENGTH];
            GetClientName(target, name, sizeof(name));
            ReplyToCommand(client, "[SM] Enabled auto-give wearable %d for %s", weaponID, name);
            
            if (IsPlayerAlive(target))
            {
                GiveWearable(target, weaponID);
            }
        }
    }

    return Plugin_Handled;
}

public Action Command_RemoveAutoGiveWearable(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_remove_auto_givewea <@red/@blue/@all/@me/@aim/name>");
        return Plugin_Handled;
    }

    char arg1[64];
    GetCmdArg(1, arg1, sizeof(arg1));

    int targets[MAXPLAYERS];
    char target_name[MAX_TARGET_LENGTH];
    bool tn_is_ml;
    int targetCount;

    if (StrEqual(arg1, "@red"))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && TF2_GetClientTeam(i) == TFTeam_Red)
            {
                targets[targetCount++] = i;
            }
        }
    }
    else if (StrEqual(arg1, "@blue"))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && TF2_GetClientTeam(i) == TFTeam_Blue)
            {
                targets[targetCount++] = i;
            }
        }
    }
    else if (StrEqual(arg1, "@all"))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                targets[targetCount++] = i;
            }
        }
    }
    else if (StrEqual(arg1, "@me"))
    {
        if (IsClientInGame(client))
        {
            targets[targetCount++] = client;
        }
    }
    else if (StrEqual(arg1, "@aim"))
    {
        int target = GetClientAimTarget(client, true);
        if (target != -1 && IsClientInGame(target))
        {
            targets[targetCount++] = target;
        }
    }
    else
    {
        targetCount = ProcessTargetString(
            arg1,
            client,
            targets,
            MAXPLAYERS,
            COMMAND_FILTER_NO_IMMUNITY,
            target_name,
            sizeof(target_name),
            tn_is_ml);
    }

    if (targetCount <= 0)
    {
        ReplyToCommand(client, "[SM] No matching players found");
        return Plugin_Handled;
    }

    for (int i = 0; i < targetCount; i++)
    {
        int target = targets[i];
        g_hAutoWearables[target].Clear();
        char name[MAX_NAME_LENGTH];
        GetClientName(target, name, sizeof(name));
        ReplyToCommand(client, "[SM] Disabled auto-give wearables for %s", name);
    }

    return Plugin_Handled;
}

WearableType GetWearableType(int itemIndex)
{
    switch(itemIndex)
    {
        case 131, 406, 1099, 1144:			// Shields (Demoman)
            return Wearable_DemoShield;
        case 133, 444:						// Gunboats + The Mantreads (Soldier)
            return Wearable_SoldierSecondary;
        case 57:							// Razorback (Sniper)
            return Wearable_Razorback;
        case 231, 642:						// Darwin's Danger Shield, Cozy Camper (Sniper)
            return Wearable_SniperSecondary;
        case 405, 608:						// Ali Baba's Wee Booties, The Bootlegger (Demoman)
            return Wearable_DemoBoots;
        default:
            return Wearable_Regular;
    }
}

void RemoveConflictingItems(int client, WearableType type)
{
    int slot = -1;
    char classname[64];
    
    switch(type)
    {
        case Wearable_DemoShield:
        {
            slot = 1;
            classname = "tf_wearable_demoshield";
        }
        case Wearable_SoldierSecondary:
        {
            slot = 1;
            classname = "tf_wearable";
        }
        case Wearable_SniperSecondary, Wearable_Razorback:
        {
            slot = 1;
            classname = "tf_wearable";
            
            int razorback = -1;
            while ((razorback = FindEntityByClassname(razorback, "tf_wearable_razorback")) != -1)
            {
                if (GetEntPropEnt(razorback, Prop_Send, "m_hOwnerEntity") == client)
                {
                    SDKCall(g_hWearableEquip, client, razorback);
                    AcceptEntityInput(razorback, "Kill");
                }
            }
        }
        case Wearable_DemoBoots:
        {
            slot = 0;
            classname = "tf_wearable";
        }
        default:
        {
            return;
        }
    }
    
    if (slot != -1)
    {
        int weapon = GetPlayerWeaponSlot(client, slot);
        if (weapon != -1)
        {
            TF2_RemoveWeaponSlot(client, slot);
        }
    }
    
    int wearable = -1;
    while ((wearable = FindEntityByClassname(wearable, classname)) != -1)
    {
        if (GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity") == client)
        {
            SDKCall(g_hWearableEquip, client, wearable);
            AcceptEntityInput(wearable, "Kill");
        }
    }
}

bool GiveWearable(int client, int itemIndex)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return false;

    WearableType type = GetWearableType(itemIndex);
    char classname[64];
    
    switch(type)
    {
        case Wearable_DemoShield:
        {
            if (TF2_GetPlayerClass(client) != TFClass_DemoMan)
            {
                PrintToChat(client, "[SM] You must be a Demoman to use shields!");
                return false;
            }
            classname = "tf_wearable_demoshield";
            RemoveConflictingItems(client, type);
        }
        case Wearable_SoldierSecondary:
        {
            if (TF2_GetPlayerClass(client) != TFClass_Soldier)
            {
                PrintToChat(client, "[SM] You must be a Soldier to use this wearable!");
                return false;
            }
            classname = "tf_wearable";
            RemoveConflictingItems(client, type);
        }
        case Wearable_Razorback:
        {
            if (TF2_GetPlayerClass(client) != TFClass_Sniper)
            {
                PrintToChat(client, "[SM] You must be a Sniper to use the Razorback!");
                return false;
            }
            classname = "tf_wearable_razorback";
            RemoveConflictingItems(client, type);
        }
        case Wearable_SniperSecondary:
        {
            if (TF2_GetPlayerClass(client) != TFClass_Sniper)
            {
                PrintToChat(client, "[SM] You must be a Sniper to use this wearable!");
                return false;
            }
            classname = "tf_wearable";
            RemoveConflictingItems(client, type);
        }
        case Wearable_DemoBoots:
        {
            if (TF2_GetPlayerClass(client) != TFClass_DemoMan)
            {
                PrintToChat(client, "[SM] You must be a Demoman to use these boots!");
                return false;
            }
            classname = "tf_wearable";
            RemoveConflictingItems(client, type);
        }
        default:
        {
            classname = "tf_wearable";
        }
    }

    int wearable = CreateEntityByName(classname);
    if (!IsValidEntity(wearable))
    {
        return false;
    }

    char entclass[64];
    GetEntityNetClass(wearable, entclass, sizeof(entclass));
    SetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex", itemIndex);
    SetEntProp(wearable, Prop_Send, "m_bInitialized", 1);
    SetEntData(wearable, FindSendPropInfo(entclass, "m_iEntityQuality"), 6);
    SetEntProp(wearable, Prop_Send, "m_iEntityLevel", 1);
    DispatchSpawn(wearable);
    SDKCall(g_hWearableEquip, client, wearable);
    
    return true;
}