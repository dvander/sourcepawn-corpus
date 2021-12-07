#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <cstrike>

#pragma semicolon 1
#pragma tabsize 0
#pragma newdecls required

public Plugin myinfo = 
{
    name = "CMDWeapons",
    author = "Kashinoda",
    version = "1.0.0",
    description = "Set spawn guns using !wp <gun>",
    url = "https://github.com/kashinoda/",
};

// Weapon Array: [0] Weapon Name, [1] Formatted name, [2] Lookup name, [3] Include Hemlet

char sWeapons[][][] = 
{
    { "weapon_ak47", "AK-47", "ak", "1" },
    { "weapon_aug", "AUG", "aug", "1" },
    { "weapon_awp", "AWP", "awp", "1" },
    { "weapon_bizon", "PP-Bizon", "bizon", "1" },
    { "weapon_cz75a", "CZ-75 Auto", "cz", "1" },
    { "weapon_deagle", "Desert Eagle", "deag", "1" },
    { "weapon_elite", "Dual Berettas", "dualies", "1" },
    { "weapon_famas", "FAMAS", "famas", "1" },
    { "weapon_fiveseven", "Five-SeveN", "57", "1" },
    { "weapon_galilar", "Galil AR", "galil", "1" },
    { "weapon_glock", "Glock-18", "glock", "0" },
    { "weapon_hkp2000", "P2000", "p2000", "0" },
    { "weapon_m249", "M249", "m249", "1" },
    { "weapon_m4a1", "M4A4", "m4", "1" },
    { "weapon_m4a1_silencer", "M4A1-S", "m4s", "1" },
    { "weapon_mac10", "MAC-10", "mac10", "1" },
    { "weapon_mag7", "MAG-7", "mag7", "1" },
    { "weapon_mp7", "MP7", "mp7", "1" },
    { "weapon_mp9", "MP9", "mp9", "1" },
    { "weapon_negev", "Negev", "negev", "1" },
    { "weapon_nova", "Nova", "nova", "1" },
    { "weapon_p250", "P250", "p250", "1" },
    { "weapon_p90", "P90", "p90", "1" },
    { "weapon_sawedoff", "Sawed-Off", "shorty", "1" },
    { "weapon_sg556", "SG 553", "sg", "1" },
    { "weapon_ssg08", "SSG 08", "scout", "1" },
    { "weapon_tec9", "Tec-9", "tec9", "1" },
    { "weapon_ump45", "UMP-45", "ump", "1" },
    { "weapon_usp_silencer", "USP-S", "usp", "0" },
    { "weapon_xm1014", "XM1014", "xm", "1" },
    { "weapon_revolver", "R8 Revolver", "r8", "1" },
    { "weapon_mp5sd", "MP5", "mp5", "1" },
    { "", "Knife", "knife", "0" },
  /*  { "weapon_taser", "Zeus", "zeus", "1" },*/
};

// Item Array: [0] Item Name, [1] Formatted name, [2] Lookup name, [3] Grenade Offset or item type, [4] CT KeyValue Label, [5] T KeyValue Label

char sItems[][][] = 
{
    { "weapon_snowball", "SNOWBALLS", "snowball","25", "CT_Snowball", "T_Snowball" },
    { "weapon_hegrenade", "GRENADES", "grenade", "14", "CT_Grenade", "T_Grenade" },
    { "weapon_smokegrenade", "SMOKES", "smoke", "16", "CT_Smoke", "T_Smoke" },
    { "weapon_flashbang", "FLASHBANGS", "flash", "15", "CT_Flash", "T_Flash" },
    { "weapon_tagrenade", "TAG GRENADS", "tag", "22", "CT_Tag", "T_Tag" },
    { "weapon_decoy", "DECOYS", "decoy", "18", "CT_Decoy", "T_Decoy" },
    { "weapon_breachcharge", "BREACH CHARGES", "charge", "no_offset", "CT_Breach", "T_Breach" },
    { "weapon_bumpmine", "BUMP MINES", "mine", "no_offset", "CT_Mine", "T_Mine" },
    { "weapon_healthshot", "HEALTH SHOTS", "hp", "21", "CT_HP", "T_HP" },
    { "weapon_shield", "SHIELD", "shield", "single_item", "CT_Shield", "T_Shield" },
    { "item_defuser", "DEFUSER", "defuser", "defuser_item", "CT_Defuse", "T_Defuse" },
    { "weapon_incgrenade", "MOLOTOVS", "ct_molly", "17", "CT_IncGrenade", "T_IncGrenade" },
    { "weapon_molotov", "MOLOTOVS", "molly", "17", "CT_Molly", "T_Molly" },
};

#define MAX_BUFFER 3000

#define BOTH "\x01[\x08 BOTH TEAMS \x01] \x10~"
#define CT "\x01[\x0B COUNTER-TERRORISTS \x01] \x10~"
#define TRST "\x01[\x0F TERRORISTS \x01] \x10~"
#define WEPLIST "\x01 [\x08awp, scout, ak, m4, m4s, sg, aug, deag, usp, glock, galil, famas, mac10, mp9, mp7, ump, bizon, p90, mp5, m249, mag7, negev, nova, shorty, xm, 57, dualies, p250, tec9, cz, r8, p2000\x01]"
#define ITEMLIST "\x01 [\x08grenade, smoke, flash, decoy, charge, mine, tag, snowball, shield, defuser\x01]"

int iSelectionActive_CT;
int iSelectedWeapon_CT;
int iSelectionType_CT;
int iOneTapEnabled_CT;
int iOneTapTimerEnabled_CT;
int iItemAmountArray_CT[sizeof(sItems)][999];
int iItemSelectionActive_CT;
int iHealthValue_CT = 100;

int iSelectionActive_T;
int iSelectedWeapon_T;
int iSelectionType_T;
int iOneTapEnabled_T;
int iOneTapTimerEnabled_T;
int iItemAmountArray_T[sizeof(sItems)][999];
int iItemSelectionActive_T;
int iHealthValue_T = 100;

/* int iWeaponSelection[MAXPLAYERS][sizeof(sWeapons)]; */
int iWeaponSelectionActive[MAXPLAYERS][2];

char sCustomSetting[MAX_BUFFER];
static char KVPath[64];
static char KVPath2[64];

public void OnPluginStart()
{
    BuildPath(Path_SM, KVPath, sizeof(KVPath), "data/save_slots.txt");
    BuildPath(Path_SM, KVPath2, sizeof(KVPath2), "data/custom_rcon_settings.txt");

    RegAdminCmd("wp", CMD_WP, ADMFLAG_GENERIC, "");
    RegAdminCmd("clear", CMD_WPClear, ADMFLAG_GENERIC, "");
    RegAdminCmd("onetap", CMD_OTap, ADMFLAG_GENERIC, "");
    RegAdminCmd("item", CMD_Nades, ADMFLAG_GENERIC, "");
    RegAdminCmd("rr", CMD_RR, ADMFLAG_GENERIC, "");
    RegAdminCmd("hp", CMD_HP, ADMFLAG_GENERIC, "");
    RegAdminCmd("flip", CMD_FLIP, ADMFLAG_GENERIC, "");

    HookEvent("round_start", EquipPlayerItems);
    HookEvent("round_start", EquipPlayers);
    HookEvent("round_start", HookAdditionalModes);
   /* HookEvent("player_spawn", EquipClient); */

    RegAdminCmd("save", CMD_S, ADMFLAG_GENERIC, "");
    RegAdminCmd("load", CMD_L, ADMFLAG_GENERIC, "");
    RegAdminCmd("delete", CMD_D, ADMFLAG_GENERIC, "");
    RegAdminCmd("update", CMD_U, ADMFLAG_GENERIC, "");

    RegAdminCmd("rcon_save", CMD_RSAVE, ADMFLAG_GENERIC, "");
    RegAdminCmd("rcon_load", CMD_RLOAD, ADMFLAG_GENERIC, "");
    RegAdminCmd("rcon_update", CMD_RUPDATE, ADMFLAG_GENERIC, "");
    RegAdminCmd("rcon_del", CMD_RDEL, ADMFLAG_GENERIC, "");

    /*RegAdminCmd("gun", CMD_GUN, ADMFLAG_GENERIC); */
}

//////////////////////////////// FLIP TEAM CONFIG COMMAND //////////////////////////////// 

public Action CMD_FLIP(int client, int args)
{
    int iSelectionActive_CT_FLIP = iSelectionActive_CT;
    int iSelectedWeapon_CT_FLIP = iSelectedWeapon_CT;
    int iSelectionType_CT_FLIP = iSelectionType_CT;
    int iOneTapEnabled_CT_FLIP = iOneTapEnabled_CT;
    int iItemSelectionActive_CT_FLIP = iItemSelectionActive_CT;
    int iHealthValue_CT_FLIP = iHealthValue_CT;
    int iItemAmountArray_CT_FLIP[sizeof(sItems)][999];
    int iItemCount = sizeof(sItems);
    for (int iItemLookup = 0; iItemLookup < iItemCount; iItemLookup++)
    {
        iItemAmountArray_CT_FLIP[iItemLookup][1] = iItemAmountArray_CT[iItemLookup][1];

    }

    iSelectionActive_CT = iSelectionActive_T;
    iSelectedWeapon_CT = iSelectedWeapon_T;
    iSelectionType_CT = iSelectionType_T;
    iOneTapEnabled_CT = iOneTapEnabled_T;
    iItemSelectionActive_CT = iItemSelectionActive_T;
    iHealthValue_CT = iHealthValue_T;
    for (int iItemLookup = 0; iItemLookup < iItemCount; iItemLookup++)
    {
        iItemAmountArray_CT[iItemLookup][1] = iItemAmountArray_T[iItemLookup][1];
    }

    iSelectionActive_T = iSelectionActive_CT_FLIP;
    iSelectedWeapon_T = iSelectedWeapon_CT_FLIP;
    iSelectionType_T = iSelectionType_CT_FLIP;
    iOneTapEnabled_T = iOneTapEnabled_CT_FLIP;
    iItemSelectionActive_T = iItemSelectionActive_CT_FLIP;
    iHealthValue_T = iHealthValue_CT_FLIP;
    for (int iItemLookup = 0; iItemLookup < iItemCount; iItemLookup++)
    {
        iItemAmountArray_T[iItemLookup][1] = iItemAmountArray_CT_FLIP[iItemLookup][1];
    }

    PrintToChatAll(" \x10~ \x01[\x09 SETTINGS \x01] \x10~ \x01[\x04 FLIPPED TEAM CONFIG \x01] \x10~");
}

/*
//////////////////////////////// GUN COMMAND (CLIENT OVERRIDE) //////////////////////////////// 

public Action CMD_GUN(int client, int args)
{
    if(args < 1)
    {
       PrintToChatAll(" Usage: \x05!gun <weapon> %s",WEPLIST);     
    }
    else
    {
        char sCmd[20];
        GetCmdArg(1, sCmd, sizeof(sCmd));
        int iValidSelection;
        int iWeaponCount = sizeof(sWeapons);

        for (int iWeaponLookup = 0; iWeaponLookup < iWeaponCount; iWeaponLookup++)
        {
            if (StrEqual(sWeapons[iWeaponLookup][2], sCmd))
            {
                iWeaponSelection[client][1] = iWeaponLookup;
                iWeaponSelectionActive[client][1] = 1;
                iValidSelection = 1;
            }
        }
        if (iValidSelection == 0)
        {
            PrintToChatAll(" \x0FERROR \x01 Can't find \x09 %s",sCmd);
            PrintToChatAll(" \x05!gun <weapon> %s",WEPLIST);
        }
    }
}

public void EquipClient(Event event, const char[] name, bool dontBroadcast)
{
    int iClient = GetClientOfUserId(event.GetInt("userid"));
    if (iWeaponSelectionActive[iClient][1] == 1)
    {
        CreateTimer(0.1, EquipClientTimer, iClient, TIMER_FLAG_NO_MAPCHANGE);
    }   
}

public Action EquipClientTimer(Handle timer, any client)
{
    int iClientWeapon = iWeaponSelection[client][1];
    for (int iSlot = 0; iSlot < 2; iSlot++)
    {
        int iEntity;
        while ((iEntity = GetPlayerWeaponSlot(client, iSlot)) != -1)
        {
            RemovePlayerItem(client, iEntity);
            AcceptEntityInput(iEntity, "Kill");
        }
    }

    SetEntProp(client, Prop_Data, "m_ArmorValue", 100, 1);
    GivePlayerItem(client, sWeapons[iClientWeapon][0], 0);

    switch(StringToInt(sWeapons[iClientWeapon][3]))
    {
        case 0: SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
        case 1: SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
    }  
}
*/
//////////////////////////////// RESTART ROUND //////////////////////////////// 

public Action CMD_RR(int client, int args)
{
    CS_TerminateRound(0.5, CSRoundEnd_Draw);
    PrintToChatAll("  \x01[\x05ENDING ROUND \x0BDRAW\x01] \x10~");
}


//////////////////////////////// HEALTH COMMAND //////////////////////////////// 

public Action CMD_HP(int client, int args)
{
    if(args < 1)
    {
       PrintToChatAll(" Usage: \x05!hp <health> <all|ct|t>");     
    }
    else
    { 
        int iAmount;
        int iValidSelection;
 
        char sCmd[20];
        GetCmdArg(1, sCmd, sizeof(sCmd));
        char sCmd2[10];
        GetCmdArg(2, sCmd2,sizeof(sCmd2));

        iAmount = StringToInt(sCmd);

        if (StrEqual("", sCmd2))
        {
            sCmd2 = "all";
        }

        if (StrEqual("all", sCmd2))
        {
            iHealthValue_CT = iAmount;
            iHealthValue_T = iAmount;
            iValidSelection = 1;
            PrintToChatAll(" \x10~ \x01[\x09 MODE \x01] \x10~ \x01[\x01 %i \x04 HEALTH \x01] \x10~ %s", iAmount, BOTH);
        }
        if (StrEqual("ct", sCmd2))
        {
            iHealthValue_CT = iAmount;
            iValidSelection = 1;
            PrintToChatAll(" \x10~ \x01[\x09 MODE \x01] \x10~ \x01[\x01 %i \x04 HEALTH \x01] \x10~ %s", iAmount, CT);
        }
        if (StrEqual("t", sCmd2))
        {
            iHealthValue_T = iAmount;
            iValidSelection = 1;
            PrintToChatAll(" \x10~ \x01[\x09 MODE \x01] \x10~ \x01[\x01 %i \x04 HEALTH \x01] \x10~ %s", iAmount, TRST);
        }
    

        if (iValidSelection == 0)
        {
            PrintToChatAll(" \x0FERROR");
            PrintToChatAll(" \x05!hp <health> <all|ct|t>");
        }
    }
}

//////////////////////////////// ONE TAP COMMAND //////////////////////////////// 

public Action CMD_OTap(int client, int args)
{
    if(args < 1)
    {
       PrintToChatAll(" Usage: \x05!onetap <on|off> <ct|t|all>");     
    }
    else
    {
        char sCmd[20];
        GetCmdArg(1, sCmd, sizeof(sCmd));

        char sCmd2[20];
        GetCmdArg(2, sCmd2, sizeof(sCmd2));

        if (StrEqual("", sCmd2))
        {
            sCmd2 = "all";
        }

        int iValidSelection;
        if (StrEqual("on", sCmd))
        {

            if (StrEqual("all", sCmd2))
            {
                if (iSelectionActive_CT == 0)
                {
                    iSelectionActive_CT = 1;
                    DisablePlacedWeap();
                    iSelectedWeapon_CT = 0;
                    iSelectionType_CT = 1;
                }
                if (iSelectionActive_T == 0)
                {
                    iSelectionActive_T = 1;
                    DisablePlacedWeap();
                    iSelectedWeapon_T = 0;
                    iSelectionType_T = 1;
                }
                iOneTapEnabled_CT = 1;
                iOneTapEnabled_T = 1;
                iValidSelection = 1;
                PrintToChatAll(" \x10~ \x01[\x09 MODE \x01] \x10~ \x01[\x04 ONE TAP \x01] \x10~  \x01[\x05 ENABLED \x01] \x10~ %s",BOTH);
            }
            if (StrEqual("ct", sCmd2))
            {
                if (iSelectionActive_CT == 0)
                {
                    iSelectionActive_CT = 1;
                    DisablePlacedWeap();
                    iSelectedWeapon_CT = 0;
                    iSelectionType_CT = 1;
                }
                iOneTapEnabled_CT = 1;
                iValidSelection = 1;
                PrintToChatAll(" \x10~ \x01[\x09 MODE \x01] \x10~ \x01[\x04 ONE TAP \x01] \x10~  \x01[\x05 ENABLED \x01] \x10~ %s",CT);
            }
            if (StrEqual("t", sCmd2))
            {
                if (iSelectionActive_T == 0)
                {
                    iSelectionActive_T = 1;
                    DisablePlacedWeap();
                    iSelectedWeapon_T = 0;
                    iSelectionType_T = 1;
                }
                iOneTapEnabled_T = 1;
                iValidSelection = 1;
                PrintToChatAll(" \x10~ \x01[\x09 MODE \x01] \x10~ \x01[\x04 ONE TAP \x01] \x10~  \x01[\x05 ENABLED \x01] \x10~ %s",TRST);
            }
        }

        if (StrEqual("off", sCmd))
        {
            if (StrEqual("all", sCmd2))
            {
                iOneTapEnabled_CT = 0;
                iOneTapEnabled_T = 0;
                iValidSelection = 1;
                PrintToChatAll(" \x10~ \x01[\x09 MODE \x01] \x10~ \x01[\x04 ONE TAP \x01] \x10~  \x01[\x03 DISABLED \x01] \x10~ %s",BOTH);
            }
            if (StrEqual("ct", sCmd2))
            {
                iOneTapEnabled_CT = 0;
                iValidSelection = 1;
                PrintToChatAll(" \x10~ \x01[\x09 MODE \x01] \x10~ \x01[\x04 ONE TAP \x01] \x10~  \x01[\x03 DISABLED \x01] \x10~ %s",CT);
            }
            if (StrEqual("t", sCmd2))
            {
                iOneTapEnabled_T = 0;
                iValidSelection = 1;
                PrintToChatAll(" \x10~ \x01[\x09 MODE \x01] \x10~ \x01[\x04 ONE TAP \x01] \x10~  \x01[\x03 DISABLED \x01] \x10~ %s",TRST);
            }
        }

        if (iValidSelection == 0)
        {
            PrintToChatAll(" \x0FERROR");
            PrintToChatAll(" \x05!onetap <on|off> <ct|t|all>");
        }
    }

}

//////////////////////////////// REMOVE PLACED WEAPONS //////////////////////////////// 

public Action DisablePlacedWeap()
{
    ServerCommand("mp_weapons_allow_map_placed 0");
}

//////////////////////////////// CLEAR VALUES COMMAND AND HOOK //////////////////////////////// 

public Action CMD_WPClear(int client, int args)
{
    PrintToChatAll(" \x10~ \x01[\x04 SETTINGS CLEARED \x01] \x10~ ");
    ClearSettings();
}

public void OnMapStart()
{
    ClearSettings();
}

public Action ClearSettings()
{
    ServerCommand("mp_weapons_allow_map_placed 1");
    iSelectionActive_CT = 0;
    iItemSelectionActive_CT = 0;
    iSelectionActive_T = 0;
    iItemSelectionActive_T = 0;
    iOneTapEnabled_CT = 0;
    iOneTapEnabled_T = 0;
    iSelectedWeapon_CT = 0;
    iSelectedWeapon_T = 0;
    iSelectionType_CT = 0;
    iSelectionType_T = 0;
    iHealthValue_CT = 100;
    iHealthValue_T = 100;
    int iItemCount = sizeof(sItems);
    for (int iItemLookup = 0; iItemLookup < iItemCount; iItemLookup++)
    {
        iItemAmountArray_CT[iItemLookup][1] = 0;

    }
    for (int iItemLookup = 0; iItemLookup < iItemCount; iItemLookup++)
    {
        iItemAmountArray_T[iItemLookup][1] = 0;
    }
}

//////////////////////////////// EQUIP WEAPONS COMMAND //////////////////////////////// 

public Action CMD_WP(int client, int args)
{
    char sCmd[20];
    GetCmdArg(1, sCmd, sizeof(sCmd));

    char sCmd2[20];
    GetCmdArg(2, sCmd2, sizeof(sCmd2));

    if (StrEqual("", sCmd2))
    {
        sCmd2 = "all";
    }

    int iWeaponCount = sizeof(sWeapons);
    int iValidSelection;

    if (StrEqual("randomeach",sCmd))
    {
        if (StrEqual("all", sCmd2))
        {
            iSelectionType_CT = 2;
            iSelectionActive_CT = 1;
            DisablePlacedWeap();
            iSelectionType_T = 2;
            iSelectionActive_T = 1;
            PrintToChatAll(" \x10~ \x01[\x09 WEAPON \x01] \x10~ \x01[\x04 RANDOM GUN EACH \x01] \x10~ %s", BOTH);
        }
        if (StrEqual("ct", sCmd2))
        {
            iSelectionType_CT = 2;
            iSelectionActive_CT = 1;
            DisablePlacedWeap();
            PrintToChatAll(" \x10~ \x01[\x09 WEAPON \x01] \x10~ \x01[\x04 RANDOM GUN EACH \x01] \x10~ %s", CT);
        }
        if (StrEqual("t", sCmd2))
        {
            iSelectionType_T = 2;
            iSelectionActive_T = 1;
            DisablePlacedWeap();
            PrintToChatAll(" \x10~ \x01[\x09 WEAPON \x01] \x10~ \x01[\x04 RANDOM GUN EACH \x01] \x10~ %s", TRST);
        }
    }

    else
    {
        if (StrEqual("randomall",sCmd))
        {
            if (StrEqual("all", sCmd2))
            {
                iSelectionType_CT = 3;
                iSelectionActive_CT = 1;
                iSelectionType_T = 3;
                iSelectionActive_T = 1;
                DisablePlacedWeap();
                PrintToChatAll(" \x10~ \x01[\x09 WEAPON \x01] \x10~ \x01[\x04 RANDOM GUN ALL \x01] \x10~ %s",BOTH);
            }
            if (StrEqual("ct", sCmd2))
            {
                iSelectionType_CT = 3;
                iSelectionActive_CT = 1;
                DisablePlacedWeap();
                PrintToChatAll(" \x10~ \x01[\x09 WEAPON \x01] \x10~ \x01[\x04 RANDOM GUN ALL \x01] \x10~ %s",CT);
            }
            if (StrEqual("t", sCmd2))
            {
                iSelectionType_T = 3;
                iSelectionActive_T = 1;
                DisablePlacedWeap();
                PrintToChatAll(" \x10~ \x01[\x09 WEAPON \x01] \x10~ \x01[\x04 RANDOM GUN ALL \x01] \x10~ %s",TRST);
            }
        }

        else
        {
        // Iterate through the array and see if any weapons match the command argument

            for (int iWeaponLookup = 0; iWeaponLookup < iWeaponCount; iWeaponLookup++)
            {
                if (StrEqual(sWeapons[iWeaponLookup][2], sCmd))
                {
                    if (StrEqual("all", sCmd2))
                    {
                    PrintToChatAll(" \x10~ \x01[\x09 WEAPON \x01] \x10~ \x01[\x04 %s \x01] \x10~ %s", sWeapons[iWeaponLookup][1], BOTH);
                    iSelectedWeapon_CT = iWeaponLookup;
                    iSelectionType_CT = 1;
                    iSelectionActive_CT = 1;
                    DisablePlacedWeap();
                    iValidSelection = 1;
                    iSelectedWeapon_T = iWeaponLookup;
                    iSelectionType_T = 1;
                    iSelectionActive_T = 1;
                    iValidSelection = 1;
                    }
                    if (StrEqual("ct", sCmd2))
                    {
                    PrintToChatAll(" \x10~ \x01[\x09 WEAPON \x01] \x10~ \x01[\x04 %s \x01] \x10~ %s", sWeapons[iWeaponLookup][1], CT);
                    iSelectedWeapon_CT = iWeaponLookup;
                    iSelectionType_CT = 1;
                    iSelectionActive_CT = 1;
                    DisablePlacedWeap();
                    iValidSelection = 1;
                    }
                    if (StrEqual("t", sCmd2))
                    {
                    PrintToChatAll(" \x10~ \x01[\x09 WEAPON \x01] \x10~ \x01[\x04 %s \x01] \x10~ %s", sWeapons[iWeaponLookup][1], TRST);
                    iSelectedWeapon_T = iWeaponLookup;
                    iSelectionType_T = 1;
                    iSelectionActive_T = 1;
                    DisablePlacedWeap();
                    iValidSelection = 1;
                    }
                }
            }

            if (iValidSelection == 0)
            {
                PrintToChatAll(" \x0FERROR \x01 Can't find \x09 %s",sCmd);
                PrintToChatAll(" \x05!wp <weapon> <all/ct/t> %s",WEPLIST);
         
            }
       // iValidSelection = 0;
        }
    }
}

//////////////////////////////// HOOK WEAPON EQUIP //////////////////////////////// 

public void EquipPlayers(Event event, const char[] name, bool dontBroadcast)
{
    int iRandom = GetRandomInt(0,sizeof(sWeapons) - 1);
    
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        // Counter Terrorists
        if (IsClientConnected(iClient) && IsClientInGame(iClient) && GetClientTeam(iClient) == CS_TEAM_CT && iSelectionActive_CT == 1)
        {
            if (iWeaponSelectionActive[iClient][1] == 0)
            {
                SetEntProp(iClient, Prop_Data, "m_ArmorValue", 100, 1);
                int iClientWeapon;

                for (int iSlot = 0; iSlot < 2; iSlot++)
                {
                    int iEntity;
                    while ((iEntity = GetPlayerWeaponSlot(iClient, iSlot)) != -1)
                    {
                        RemovePlayerItem(iClient, iEntity);
                        AcceptEntityInput(iEntity, "Kill");
                    }
                }

                switch (iSelectionType_CT)
                {
                    case 1: iClientWeapon = iSelectedWeapon_CT; 
                    case 2: iClientWeapon = GetRandomInt(0,sizeof(sWeapons) - 1);
                    case 3: iClientWeapon = iRandom;
                }

                switch(iOneTapEnabled_CT)
                {
                    case 0: GivePlayerItem(iClient, sWeapons[iClientWeapon][0], 0);
                    case 1: Client_GiveWeaponAndAmmo(iClient, sWeapons[iClientWeapon][0], _, 0, _, 1);
                }   

                switch(StringToInt(sWeapons[iClientWeapon][3]))
                {
                    case 0: SetEntProp(iClient, Prop_Send, "m_bHasHelmet", 0);
                    case 1: SetEntProp(iClient, Prop_Send, "m_bHasHelmet", 1);
                }               
            }

        }
        // Terrorists
        else
        {            
            if (IsClientConnected(iClient) && IsClientInGame(iClient) && GetClientTeam(iClient) == CS_TEAM_T && iSelectionActive_T == 1)
            {
                if (iWeaponSelectionActive[iClient][1] == 0)
                {
                    SetEntProp(iClient, Prop_Data, "m_ArmorValue", 100, 1);
                    int iClientWeapon;

                    for (int iSlot = 0; iSlot < 2; iSlot++)
                    {
                        int iEntity;
                        while ((iEntity = GetPlayerWeaponSlot(iClient, iSlot)) != -1)
                        {
                            RemovePlayerItem(iClient, iEntity);
                            AcceptEntityInput(iEntity, "Kill");
                        }
                    }
                    switch (iSelectionType_T)
                    {
                        case 1: iClientWeapon = iSelectedWeapon_T; 
                        case 2: iClientWeapon = GetRandomInt(0,sizeof(sWeapons) - 1);
                        case 3: iClientWeapon = iRandom;
                    }

                    switch(iOneTapEnabled_T)
                    {
                        case 0: GivePlayerItem(iClient, sWeapons[iClientWeapon][0], 0);
                        case 1: Client_GiveWeaponAndAmmo(iClient, sWeapons[iClientWeapon][0], _, 0, _, 1);
                    }   

                    switch(StringToInt(sWeapons[iClientWeapon][3]))
                    {
                        case 0: SetEntProp(iClient, Prop_Send, "m_bHasHelmet", 0);
                        case 1: SetEntProp(iClient, Prop_Send, "m_bHasHelmet", 1);
                    }                    
                }

            }
        }
    }    
}

//////////////////////////////// HOOK ADDITIONAL MODES //////////////////////////////// 

public void HookAdditionalModes(Event event, const char[] name, bool dontBroadcast)
{
    iOneTapTimerEnabled_T = 0;
    iOneTapTimerEnabled_CT = 0;
  
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        // Counter Terrorists
        if (IsClientConnected(iClient) && IsClientInGame(iClient) && GetClientTeam(iClient) == CS_TEAM_CT)
        {
            if (iOneTapEnabled_CT == 1)
            {
                iOneTapTimerEnabled_CT = 1;
                CreateTimer(0.5, OneTapMode_CT, iClient, TIMER_REPEAT);
            }

            SetEntProp(iClient, Prop_Data, "m_iHealth", iHealthValue_CT);
        }
        else
        {
            // Terrorists
            if (IsClientConnected(iClient) && IsClientInGame(iClient) && GetClientTeam(iClient) == CS_TEAM_T)
            {
                if (iOneTapEnabled_T == 1)
                {
                    iOneTapTimerEnabled_T = 1;
                    CreateTimer(0.5, OneTapMode_T, iClient, TIMER_REPEAT);
                }

                SetEntProp(iClient, Prop_Data, "m_iHealth", iHealthValue_T);
            }
        }
    }
}

public Action OneTapMode_CT(Handle timer, any client)
{   
    if (iOneTapTimerEnabled_CT == 0)
    {    
        return Plugin_Stop;
    } 

    for (int iSlot = 0; iSlot < 2; iSlot++)
    {
        int iEntity;
        if ((iEntity = GetPlayerWeaponSlot(client, iSlot)) != -1)
        {
            int clip1 = GetEntProp(iEntity, Prop_Send, "m_iClip1");
            if (clip1 == 0) 
            {
                char sWeapon[64];
                GetEntityClassname(iEntity, sWeapon, sizeof(sWeapon)); 
                Client_SetWeaponPlayerAmmo(client, sWeapon, 1);
            }
        }
    }
    return Plugin_Continue;
}

public Action OneTapMode_T(Handle timer, any client)
{   
    if (iOneTapTimerEnabled_T == 0)
    {    
        return Plugin_Stop;
    } 

    for (int iSlot = 0; iSlot < 2; iSlot++)
    {
        int iEntity;
        if ((iEntity = GetPlayerWeaponSlot(client, iSlot)) != -1)
        {
            int clip1 = GetEntProp(iEntity, Prop_Send, "m_iClip1");
            if (clip1 == 0) 
            {
                char sWeapon[64];
                GetEntityClassname(iEntity, sWeapon, sizeof(sWeapon)); 
                Client_SetWeaponPlayerAmmo(client, sWeapon, 1);
            }
        }
    }
    return Plugin_Continue;
}

//////////////////////////////// EQUIP ITEMS COMMAND //////////////////////////////// 

public Action CMD_Nades(int client, int args)
{
    if(args < 1)
    {
       PrintToChatAll(" Usage: \x05!item <item> <amount> <all|ct|t> %s",ITEMLIST);     
    }
    else
    { 
        int iAmount;
        int iValidItemSelection;
        ServerCommand("ammo_grenade_limit_breachcharge 30; ammo_grenade_limit_bumpmine 30; ammo_grenade_limit_default 30; ammo_grenade_limit_flashbang 30; ammo_grenade_limit_snowballs 30; ammo_grenade_limit_total 180; ammo_item_limit_healthshot 30");     
        char sCmd[20];
        GetCmdArg(1, sCmd, sizeof(sCmd));
        char sCmd2[10];
        GetCmdArg(2, sCmd2,sizeof(sCmd2));
        char sCmd3[10];
        GetCmdArg(3, sCmd3,sizeof(sCmd3));

        if (StrEqual("", sCmd3))
        {
            sCmd3 = "all";
        }

        if (StrEqual("", sCmd2))
        {
            iAmount = 1;
        }
        else
        {
            iAmount = StringToInt(sCmd2);
        }

        if (iAmount > 30)
        {
            iAmount = 30;
        }
        int iItemCount = sizeof(sItems);
        for (int iItemLookup = 0; iItemLookup < iItemCount; iItemLookup++)
        {
            if (StrEqual(sItems[iItemLookup][2], sCmd))
            {
                if (StrEqual("all", sCmd3))
                {
                    iItemAmountArray_CT[iItemLookup][1] = iAmount;
                    iItemSelectionActive_CT = 1;
                    iItemAmountArray_T[iItemLookup][1] = iAmount;
                    iItemSelectionActive_T = 1;
                    iValidItemSelection = 1;
                    PrintToChatAll(" \x10~ \x01[\x09 ITEM \x01] \x10~ \x01[\x01 %i \x04 %s \x01] \x10~ %s", iAmount, sItems[iItemLookup][1], BOTH);
                }
                if (StrEqual("ct", sCmd3))
                {
                    iItemAmountArray_CT[iItemLookup][1] = iAmount;
                    iItemSelectionActive_CT = 1;
                    iValidItemSelection = 1;
                    PrintToChatAll(" \x10~ \x01[\x09 ITEM \x01] \x10~ \x01[\x01 %i \x04 %s \x01] \x10~ %s", iAmount, sItems[iItemLookup][1], CT);
                }
                if (StrEqual("t", sCmd3))
                {
                    iItemAmountArray_T[iItemLookup][1] = iAmount;
                    iItemSelectionActive_T = 1;
                    iValidItemSelection = 1;
                    PrintToChatAll(" \x10~ \x01[\x09 ITEM \x01] \x10~ \x01[\x01 %i \x04 %s \x01] \x10~ %s", iAmount, sItems[iItemLookup][1], TRST);
                }
            }
        }

        if (iValidItemSelection == 0)
        {
            PrintToChatAll(" \x0FERROR \x01 Can't find \x09 %s",sCmd);
            PrintToChatAll(" \x05!item <item> <amount> <all|ct|t> %s",ITEMLIST);
        }
        iValidItemSelection = 0;
    }
}

//////////////////////////////// HOOK ITEM EQUIP //////////////////////////////// 

public void EquipPlayerItems(Event event, const char[] name, bool dontBroadcast)
{
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsClientConnected(iClient) && IsClientInGame(iClient) && GetClientTeam(iClient) == CS_TEAM_CT && iItemSelectionActive_CT == 1)
        {
            int iItemCount = sizeof(sItems);
            SetEntProp(iClient, Prop_Send, "m_bHasDefuser", 0);
            for (int iItemLookup = 0; iItemLookup < iItemCount; iItemLookup++)
            {
                Client_RemoveWeapon(iClient, sItems[iItemLookup][0]);
                if (iItemAmountArray_CT[iItemLookup][1] == 0 )
                {
                    // Do Noithing
                }
                else
                {
                    if (StrEqual("no_offset",sItems[iItemLookup][3]))
                    {
                        Client_GiveWeaponAndAmmo(iClient, sItems[iItemLookup][0], _, 0, _, iItemAmountArray_CT[iItemLookup][1]);
                    }
                    else
                    {
                        if (StrEqual("single_item",sItems[iItemLookup][3]))
                        {
                            GivePlayerItem(iClient, sItems[iItemLookup][0], 0);                   
                        } 
                        else
                        {
                            if (StrEqual("defuser_item",sItems[iItemLookup][3]))
                            {
                                SetEntProp(iClient, Prop_Send, "m_bHasDefuser", 1);
                            }
                            else
                            {
                                GivePlayerItem(iClient, sItems[iItemLookup][0], 0);
                                SetEntProp(iClient, Prop_Send, "m_iAmmo", iItemAmountArray_CT[iItemLookup][1], _, StringToInt(sItems[iItemLookup][3]));                                  
                            }                      
                        }                       
                    }                 
                }
            }
        }
        else
        {
            if (IsClientConnected(iClient) && IsClientInGame(iClient) && GetClientTeam(iClient) == CS_TEAM_T && iItemSelectionActive_T == 1)
            {
                int iItemCount = sizeof(sItems);
                SetEntProp(iClient, Prop_Send, "m_bHasDefuser", 0);
                for (int iItemLookup = 0; iItemLookup < iItemCount; iItemLookup++)
                {
                    Client_RemoveWeapon(iClient, sItems[iItemLookup][0]);
                    if (iItemAmountArray_T[iItemLookup][1] == 0 )
                    {
                        // Do Noithing
                    }
                    else
                    {
                        if (StrEqual("no_offset",sItems[iItemLookup][3]))
                        {
                            Client_GiveWeaponAndAmmo(iClient, sItems[iItemLookup][0], _, 0, _, iItemAmountArray_T[iItemLookup][1]);
                        }
                        else
                        {
                            if (StrEqual("single_item",sItems[iItemLookup][3]))
                            {
                                GivePlayerItem(iClient, sItems[iItemLookup][0], 0);                   
                            } 
                            else
                            {
                                if (StrEqual("defuser_item",sItems[iItemLookup][3]))
                                {
                                    SetEntProp(iClient, Prop_Send, "m_bHasDefuser", 1);
                                }
                                else
                                {
                                    GivePlayerItem(iClient, sItems[iItemLookup][0], 0);
                                    SetEntProp(iClient, Prop_Send, "m_iAmmo", iItemAmountArray_T[iItemLookup][1], _, StringToInt(sItems[iItemLookup][3]));                                  
                                }                      
                            }                       
                        }                 
                    }
                }
            }
        }
    }
}

//////////////////////////////// RCON SETTINGS KEY VALUES SAVE & LOAD //////////////////////////////// 

public Action CMD_RSAVE(int client, int args)
{
    if(args < 2)
    {
        PrintToChatAll(" Example: \x10!rcon_save \x09mysave \x08\"sv_cheats 1; sv_enablebunnyhopping 1\"");       
    }
    else
    { 
        char sCmd[20];
        GetCmdArg(1, sCmd, sizeof(sCmd));

        char sCmd2[MAX_BUFFER];
        GetCmdArg(2, sCmd2, sizeof(sCmd2));
        sCustomSetting = sCmd2;

        Handle DB = CreateKeyValues("Setting");
        FileToKeyValues(DB, KVPath2);
        if (KvJumpToKey(DB, sCmd))
        {  
            PrintToChatAll(" \x0FERROR \x01 Save slot \x09%s \x01 already exists, please use \x05!rcon_update \x01or \x05!rcon_del",sCmd);           
        }
        else
        {
            SaveRconSettings(sCmd);
        }
        CloseHandle(DB);
    }
}

public Action CMD_RUPDATE(int client, int args)
{
    if(args < 2)
    {
        PrintToChatAll(" Example: \x10!rcon_update \x09mysave \x08\"sv_cheats 1; sv_enablebunnyhopping 1\"");       
    }
    else
    { 
        char sCmd[20];
        GetCmdArg(1, sCmd, sizeof(sCmd));

        char sCmd2[MAX_BUFFER];
        GetCmdArg(2, sCmd2, sizeof(sCmd2));
        sCustomSetting = sCmd2;

        Handle DB = CreateKeyValues("Setting");
        FileToKeyValues(DB, KVPath2);
        if (KvJumpToKey(DB, sCmd))
        {  
            SaveRconSettings(sCmd);
        }
        else
        {
            PrintToChatAll(" \x0FERROR \x01 Save slot \x09%s \x01 doesn't exist, please use \x05!rcon_save \x01to create it",sCmd);
        }
        CloseHandle(DB);
    }
}

public Action CMD_RDEL(int client, int args)
{
    if(args < 1)
    {
       PrintToChatAll(" Usage: \x05!rcon_del <save_name>");     
    }
    else
    {
        char sCmd[20];
        GetCmdArg(1, sCmd, sizeof(sCmd));

        Handle DB = CreateKeyValues("Setting");
        FileToKeyValues(DB, KVPath2);

        if (KvJumpToKey(DB, sCmd))
        {   
            KvDeleteThis(DB);
            KvRewind(DB);
            KeyValuesToFile(DB, KVPath2);           
            PrintToChatAll(" \x10~ \x01[\x09 CUSTOM SETTINGS \x01] \x10~ \x01[\x04 %s \x01] \x10~  \x01[\x0F DELETED \x01] \x10~",sCmd);   
        }
        else
        {
            PrintToChatAll(" \x0FERROR \x01 Can't find saved slot \x09%s",sCmd);
        }
        CloseHandle(DB); 
    }
}

public Action CMD_RLOAD(int client, int args)
{
    if(args < 1)
    {
       PrintToChatAll(" Usage: \x05!rcon_load <save_name>");     
    }
    else
    {
        char sCmd[20];
        GetCmdArg(1, sCmd, sizeof(sCmd));

        Handle DB = CreateKeyValues("Setting");
        FileToKeyValues(DB, KVPath2);

        if (KvJumpToKey(DB, sCmd))
        {   
            KvGetString(DB,"sCustomSetting", sCustomSetting, MAX_BUFFER);
            KvRewind(DB);

            ServerCommand("%s",sCustomSetting); 
            PrintToChatAll(" \x08%s",sCustomSetting);
            PrintToChatAll(" \x10~ \x01[\x09 CUSTOM SETTINGS \x01] \x10~ \x01[\x04 %s \x01] \x10~  \x01[\x05 LOADED \x01] \x10~",sCmd);
            sCustomSetting = "";        
        }
        else
        {
            PrintToChatAll(" \x0FERROR \x01 Can't find saved slot \x09%s",sCmd); 
        }
        CloseHandle(DB);
    }
}

public Action SaveRconSettings(char[] save)
{   

    Handle DB = CreateKeyValues("Setting");   
    FileToKeyValues(DB, KVPath2);

    KvJumpToKey(DB, save, true);   
    KvSetString(DB,"sCustomSetting", sCustomSetting);

    KvRewind(DB);
    KeyValuesToFile(DB, KVPath2);
    CloseHandle(DB);

    PrintToChatAll(" \x08%s",sCustomSetting);
    sCustomSetting = "";
    PrintToChatAll(" \x10~ \x01[\x09 CUSTOM SETTINGS \x01] \x10~ \x01[\x04 %s \x01] \x10~  \x01[\x05 SAVED \x01] \x10~",save);
}

//////////////////////////////// KEY VALUES SAVE & LOAD //////////////////////////////// 

public Action CMD_S(int client, int args)
{
    if(args < 1)
    {
        PrintToChatAll(" Usage: \x05!save <save_name>");     
    }
    else
    { 
        char sCmd[20];
        GetCmdArg(1, sCmd, sizeof(sCmd));
        Handle DB = CreateKeyValues("Setting");
        FileToKeyValues(DB, KVPath);
        if (KvJumpToKey(DB, sCmd))
        {  
            PrintToChatAll(" \x0FERROR \x01 Save slot \x09%s \x01 already exists, please use \x05!update \x01or \x05!delete",sCmd);           
        }
        else
        {  
            SaveSettings(sCmd);
        }
        CloseHandle(DB);
    }
}

public Action CMD_U(int client, int args)
{
    if(args < 1)
    {
        PrintToChatAll(" Usage: \x05!update <existing_save_name>");     
    }
    else
    { 
        char sCmd[20];
        GetCmdArg(1, sCmd, sizeof(sCmd));

        Handle DB = CreateKeyValues("Setting");
        FileToKeyValues(DB, KVPath);
        if (KvJumpToKey(DB, sCmd))
        {  
            SaveSettings(sCmd);                 
        }
        else
        {
            PrintToChatAll(" \x0FERROR \x01 Save slot \x09%s \x01 doesn't exist, please use \x05!save \x01to create it",sCmd); 
        }
        CloseHandle(DB);
    }
}

public Action CMD_D(int client, int args)
{
    if(args < 1)
    {
       PrintToChatAll(" Usage: \x05!delete <save_name>");     
    }
    else
    {
        char sCmd[20];
        GetCmdArg(1, sCmd, sizeof(sCmd));

        Handle DB = CreateKeyValues("Setting");
        FileToKeyValues(DB, KVPath);

        if (KvJumpToKey(DB, sCmd))
        {   
            KvDeleteThis(DB);
            KvRewind(DB);
            KeyValuesToFile(DB, KVPath);           
            PrintToChatAll(" \x10~ \x01[\x09 SETTINGS \x01] \x10~ \x01[\x04 %s \x01] \x10~  \x01[\x0F DELETED \x01] \x10~",sCmd);   
        }
        else
        {
            PrintToChatAll(" \x0FERROR \x01 Can't find saved slot \x09%s",sCmd);
        }
        CloseHandle(DB); 
    }
}

public Action CMD_L(int client, int args)
{
    if(args < 1)
    {
       PrintToChatAll(" Usage: \x05!load <save_name>");     
    }
    else
    {
        char sCmd[20];
        GetCmdArg(1, sCmd, sizeof(sCmd));

        int iItemCount = sizeof(sItems);
        Handle DB = CreateKeyValues("Setting");
        FileToKeyValues(DB, KVPath);

        if (KvJumpToKey(DB, sCmd))
        {
            iSelectionActive_CT = KvGetNum(DB,"iSelectionActive_CT");
            iSelectedWeapon_CT = KvGetNum(DB,"iSelectedWeapon_CT");
            iSelectionType_CT = KvGetNum(DB,"iSelectionType_CT");
            iOneTapEnabled_CT = KvGetNum(DB,"iOneTapEnabled_CT");
            iItemSelectionActive_CT = KvGetNum(DB,"iItemSelectionActive_CT");
            iHealthValue_CT = KvGetNum(DB,"iHealthValue_CT");
            iSelectionActive_T = KvGetNum(DB,"iSelectionActive_T");
            iSelectedWeapon_T = KvGetNum(DB,"iSelectedWeapon_T");
            iSelectionType_T = KvGetNum(DB,"iSelectionType_T");
            iOneTapEnabled_T = KvGetNum(DB,"iOneTapEnabled_T");
            iItemSelectionActive_T = KvGetNum(DB,"iItemSelectionActive_T");
            iHealthValue_T = KvGetNum(DB,"iHealthValue_T");
            for (int iItemLookup = 0; iItemLookup < iItemCount; iItemLookup++)
            {
                iItemAmountArray_CT[iItemLookup][1] = KvGetNum(DB,sItems[iItemLookup][4]);
            }
            for (int iItemLookup = 0; iItemLookup < iItemCount; iItemLookup++)
            {
                iItemAmountArray_T[iItemLookup][1] = KvGetNum(DB,sItems[iItemLookup][5]);
            }
            PrintToChatAll(" \x10~ \x01[\x09 SETTINGS \x01] \x10~ \x01[\x04 %s \x01] \x10~  \x01[\x05 LOADED \x01] \x10~",sCmd);
            KvRewind(DB);        
        }
        else
        {
            PrintToChatAll(" \x0FERROR \x01 Can't find saved slot \x09%s",sCmd); 
        }
        CloseHandle(DB);
    }
}

public Action SaveSettings(char[] save)
{   
    int iItemCount = sizeof(sItems);

    Handle DB = CreateKeyValues("Setting");   
    FileToKeyValues(DB, KVPath);

    KvJumpToKey(DB, save, true);   
    KvSetNum(DB,"iSelectionActive_CT", iSelectionActive_CT);
    KvSetNum(DB,"iSelectedWeapon_CT", iSelectedWeapon_CT);
    KvSetNum(DB,"iSelectionType_CT", iSelectionType_CT);
    KvSetNum(DB,"iOneTapEnabled_CT", iOneTapEnabled_CT);
    KvSetNum(DB,"iItemSelectionActive_CT", iItemSelectionActive_CT);
    KvSetNum(DB,"iHealthValue_CT", iHealthValue_CT);
    KvSetNum(DB,"iSelectionActive_T", iSelectionActive_T);
    KvSetNum(DB,"iSelectedWeapon_T", iSelectedWeapon_T);
    KvSetNum(DB,"iSelectionType_T", iSelectionType_T);
    KvSetNum(DB,"iOneTapEnabled_T", iOneTapEnabled_T);
    KvSetNum(DB,"iItemSelectionActive_T", iItemSelectionActive_T);
    KvSetNum(DB,"iHealthValue_T", iHealthValue_T);
    for (int iItemLookup = 0; iItemLookup < iItemCount; iItemLookup++)
    {
        KvSetNum(DB,sItems[iItemLookup][4], iItemAmountArray_CT[iItemLookup][1]);
    }
    for (int iItemLookup = 0; iItemLookup < iItemCount; iItemLookup++)
    {
        KvSetNum(DB,sItems[iItemLookup][5], iItemAmountArray_T[iItemLookup][1]);
    }

    KvRewind(DB);
    KeyValuesToFile(DB, KVPath);
    CloseHandle(DB);

    PrintToChatAll(" \x10~ \x01[\x09 SETTINGS \x01] \x10~ \x01[\x04 %s \x01] \x10~  \x01[\x05 SAVED \x01] \x10~",save);
}