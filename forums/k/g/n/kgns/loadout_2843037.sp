#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <PTaH>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
#define NUM_GROUPS     6

// CS:GO team indices
#define TEAM_ANY 0
#define TEAM_CT  3
#define TEAM_T   2

public Plugin myinfo = {
    name        = "Loadout Manager",
    author      = "kgns",
    description = "Per-player weapon loadout preferences via PTaH",
    version     = PLUGIN_VERSION,
    url         = "https://www.oyunhost.net"
};

// -------------------------------------------------------------------------
// Weapon group data
//
// Groups with identical weapon pairs across teams (deagle/revolver,
// mp7/mp5sd) are merged into a single TEAM_ANY group.
//
//  0  CT   P2000 / USP-S
//  1  CT   Five-SeveN / CZ75-Auto
//  2  ANY  Desert Eagle / R8 Revolver
//  3  CT   M4A4 / M4A1-S
//  4  ANY  MP7 / MP5-SD
//  5  T    Tec-9 / CZ75-Auto
//  6  T    Sawed-Off / XM1014
// -------------------------------------------------------------------------

static const int g_GroupTeam[NUM_GROUPS] = {
    TEAM_CT,   // 0
    TEAM_CT,   // 1
    TEAM_ANY,  // 2
    TEAM_CT,   // 3
    TEAM_ANY,  // 4
    TEAM_T     // 5
};

static const char g_Weapon0Class[NUM_GROUPS][32] = {
    "weapon_hkp2000",
    "weapon_fiveseven",
    "weapon_deagle",
    "weapon_m4a1",
    "weapon_mp7",
    "weapon_tec9"
};

static const char g_Weapon1Class[NUM_GROUPS][32] = {
    "weapon_usp_silencer",
    "weapon_cz75a",
    "weapon_revolver",
    "weapon_m4a1_silencer",
    "weapon_mp5sd",
    "weapon_cz75a"
};

static const char g_Weapon0Name[NUM_GROUPS][24] = {
    "P2000",
    "Five-SeveN",
    "Desert Eagle",
    "M4A4",
    "MP7",
    "Tec-9"
};

static const char g_Weapon1Name[NUM_GROUPS][24] = {
    "USP-S",
    "CZ75-Auto",
    "R8 Revolver",
    "M4A1-S",
    "MP5-SD",
    "CZ75-Auto"
};

static const char g_GroupLabel[NUM_GROUPS][40] = {
    "P2000 / USP-S",
    "Five-SeveN / CZ75-Auto",
    "Desert Eagle / R8 Revolver",
    "M4A4 / M4A1-S",
    "MP7 / MP5-SD",
    "Tec-9 / CZ75-Auto"
};

// -------------------------------------------------------------------------
// Globals
// -------------------------------------------------------------------------

Handle g_hCookie[NUM_GROUPS];

// Preferred weapon classname per client per group (empty = no preference)
char g_Pref[MAXPLAYERS + 1][NUM_GROUPS][32];

// Which group the sub-menu is currently showing
int g_MenuGroup[MAXPLAYERS + 1];

// -------------------------------------------------------------------------
// Plugin lifecycle
// -------------------------------------------------------------------------

public void OnPluginStart()
{
    RegConsoleCmd("sm_loadout", Cmd_Loadout, "Open weapon loadout menu");
    RegConsoleCmd("sm_lo", Cmd_Loadout, "Open weapon loadout menu");

    g_hCookie[0] = RegClientCookie("loadout_p2000_usps", "P2000/USP-S",       CookieAccess_Private);
    g_hCookie[1] = RegClientCookie("loadout_57_cz",      "Five-SeveN/CZ75",   CookieAccess_Private);
    g_hCookie[2] = RegClientCookie("loadout_deagle_r8",  "Deagle/R8",         CookieAccess_Private);
    g_hCookie[3] = RegClientCookie("loadout_m4a4_m4a1s", "M4A4/M4A1-S",       CookieAccess_Private);
    g_hCookie[4] = RegClientCookie("loadout_mp7_mp5",    "MP7/MP5-SD",        CookieAccess_Private);
    g_hCookie[5] = RegClientCookie("loadout_tec9_cz",    "Tec-9/CZ75",        CookieAccess_Private);

    PTaH(PTaH_GiveNamedItemPre, Hook, OnGiveNamedItemPre);

    // Late-load support
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i))
            LoadPrefs(i);
}

public void OnPluginEnd()
{
    PTaH(PTaH_GiveNamedItemPre, UnHook, OnGiveNamedItemPre);
}

// -------------------------------------------------------------------------
// Client events
// -------------------------------------------------------------------------

public void OnClientCookiesCached(int client)
{
    LoadPrefs(client);
}

public void OnClientDisconnect(int client)
{
    for (int g = 0; g < NUM_GROUPS; g++)
        g_Pref[client][g][0] = '\0';
}

void LoadPrefs(int client)
{
    for (int g = 0; g < NUM_GROUPS; g++)
        GetClientCookie(client, g_hCookie[g], g_Pref[client][g], sizeof(g_Pref[][]));
}

void SavePref(int client, int group)
{
    SetClientCookie(client, g_hCookie[group], g_Pref[client][group]);
}

// -------------------------------------------------------------------------
// PTaH hook — runs before the engine creates a weapon entity
// -------------------------------------------------------------------------

public Action OnGiveNamedItemPre(int iClient, char sClassname[64], CEconItemView &pItemView, bool &bIgnoredView, bool &bOriginNULL, float vecOrigin[3])
{
    if (iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
        return Plugin_Continue;

    int team = GetClientTeam(iClient);

    for (int g = 0; g < NUM_GROUPS; g++)
    {
        // Skip groups that don't apply to this player's team
        if (g_GroupTeam[g] != TEAM_ANY && g_GroupTeam[g] != team)
            continue;

        // Does the weapon being given belong to this group?
        if (!StrEqual(sClassname, g_Weapon0Class[g]) && !StrEqual(sClassname, g_Weapon1Class[g]))
            continue;

        // No preference set — leave as-is
        if (g_Pref[iClient][g][0] == '\0')
            return Plugin_Continue;

        // Already the preferred weapon — nothing to do
        if (StrEqual(sClassname, g_Pref[iClient][g]))
            return Plugin_Continue;

        // Replace with the player's preferred weapon
        strcopy(sClassname, 64, g_Pref[iClient][g]);
        bIgnoredView = true;
        return Plugin_Changed;
    }

    return Plugin_Continue;
}

// -------------------------------------------------------------------------
// Command
// -------------------------------------------------------------------------

public Action Cmd_Loadout(int client, int args)
{
    if (!client)
    {
        ReplyToCommand(client, "[Loadout] Players only.");
        return Plugin_Handled;
    }
    ShowMainMenu(client);
    return Plugin_Handled;
}

// -------------------------------------------------------------------------
// Main menu — lists every group with the current selection
// -------------------------------------------------------------------------

void ShowMainMenu(int client)
{
    Menu menu = new Menu(MainMenuHandler);
    menu.SetTitle("Weapon Loadout");

    for (int g = 0; g < NUM_GROUPS; g++)
    {
        char label[64], key[4];
        IntToString(g, key, sizeof(key));

        if (g_Pref[client][g][0] != '\0')
        {
            char prefName[24];
            GetPrefName(g, g_Pref[client][g], prefName, sizeof(prefName));
            Format(label, sizeof(label), "%s  [%s]", g_GroupLabel[g], prefName);
        }
        else
        {
            strcopy(label, sizeof(label), g_GroupLabel[g]);
        }

        menu.AddItem(key, label);
    }

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MainMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char key[4];
            menu.GetItem(param2, key, sizeof(key));
            g_MenuGroup[client] = StringToInt(key);
            ShowGroupMenu(client, g_MenuGroup[client]);
        }
        case MenuAction_End: delete menu;
    }
    return 0;
}

// -------------------------------------------------------------------------
// Group sub-menu — pick one of the two weapons
// -------------------------------------------------------------------------

void ShowGroupMenu(int client, int group)
{
    Menu menu = new Menu(GroupMenuHandler);

    char title[64];
    Format(title, sizeof(title), "%s\nPick your preferred weapon:", g_GroupLabel[group]);
    menu.SetTitle(title);

    char label0[40], label1[40];

    if (StrEqual(g_Pref[client][group], g_Weapon0Class[group]))
        Format(label0, sizeof(label0), "%s  [selected]", g_Weapon0Name[group]);
    else
        strcopy(label0, sizeof(label0), g_Weapon0Name[group]);

    if (StrEqual(g_Pref[client][group], g_Weapon1Class[group]))
        Format(label1, sizeof(label1), "%s  [selected]", g_Weapon1Name[group]);
    else
        strcopy(label1, sizeof(label1), g_Weapon1Name[group]);

    menu.AddItem("0", label0);
    menu.AddItem("1", label1);

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int GroupMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char key[4];
            menu.GetItem(param2, key, sizeof(key));
            int group  = g_MenuGroup[client];
            int choice = StringToInt(key);

            if (choice == 0)
            {
                strcopy(g_Pref[client][group], sizeof(g_Pref[][]), g_Weapon0Class[group]);
                PrintToChat(client, " \x04[Loadout]\x01 %s set to \x04%s\x01.", g_GroupLabel[group], g_Weapon0Name[group]);
            }
            else
            {
                strcopy(g_Pref[client][group], sizeof(g_Pref[][]), g_Weapon1Class[group]);
                PrintToChat(client, " \x04[Loadout]\x01 %s set to \x04%s\x01.", g_GroupLabel[group], g_Weapon1Name[group]);
            }

            SavePref(client, group);
            ShowMainMenu(client);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
                ShowMainMenu(client);
        }
        case MenuAction_End: delete menu;
    }
    return 0;
}

// -------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------

void GetPrefName(int group, const char[] classname, char[] out, int len)
{
    if (StrEqual(classname, g_Weapon0Class[group]))
        strcopy(out, len, g_Weapon0Name[group]);
    else if (StrEqual(classname, g_Weapon1Class[group]))
        strcopy(out, len, g_Weapon1Name[group]);
    else
        strcopy(out, len, classname);
}
