#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma newdecls required

#define PLUGIN_VERSION "1.1"

public Plugin myinfo = 
{
    name        =   "[ANY] Fling Players",
    author      =   "TOB",
    description =   "Lets admins fling players around.",
    version     =   PLUGIN_VERSION,
    url         =   "https://forums.alliedmods.net/showthread.php?p=2841025#post2841025"
}

#define MIN_FORCE -1000
#define MAX_FORCE 1000

TopMenu g_hAdminMenu;
Menu g_hForceSelect;
ConVar g_cvSnd, g_cvDownloadSnd;
int g_myForce[MAXPLAYERS + 1];
char g_flingSnd[PLATFORM_MAX_PATH];

public void OnPluginStart()
{
    CreateConVar("sm_fling_version", PLUGIN_VERSION, "", FCVAR_SPONLY|FCVAR_DONTRECORD);
    LoadTranslations("common.phrases");
    LoadTranslations("fling.phrases");

    g_hForceSelect = new Menu(MenuHandler_ForceSelect, MenuAction_Display|MenuAction_DisplayItem);
    g_hForceSelect.ExitBackButton = true;
    g_hForceSelect.AddItem("300", "Weak");
    g_hForceSelect.AddItem("450", "Medium");
    g_hForceSelect.AddItem("600", "Strong");
    g_hForceSelect.AddItem("900", "Tank");
    g_hForceSelect.AddItem("-300", "Weak magnet");
    g_hForceSelect.AddItem("-450", "Medium magnet");
    g_hForceSelect.AddItem("-600", "Strong magnet");
    g_hForceSelect.AddItem("-900", "Tank magnet");

    TopMenu topmenu;
    if (LibraryExists("adminmenu") && (topmenu = GetAdminTopMenu()) != null)
    {
        OnAdminMenuReady(topmenu);
    }

    RegAdminCmd("sm_fling", Command_Fling, ADMFLAG_SLAY, "Fling your target around."
    ...                                                  "\n <#userid|target> - The target to fling."
    ...                                                  "\n <#force> - The force to be applied.");

    g_cvSnd = CreateConVar("sm_fling_sound", "misc/banana_slip.wav", "The sound to play when a client is flung.", FCVAR_SPONLY|FCVAR_DONTRECORD);
    g_cvDownloadSnd = CreateConVar("sm_fling_download_sound", "0", "Should the fling sound be downloaded to clients?", FCVAR_SPONLY|FCVAR_DONTRECORD);
}

public void OnAdminMenuReady(Handle aTopMenu)
{
    TopMenu adminmenu = TopMenu.FromHandle(aTopMenu);
    if (adminmenu == g_hAdminMenu)
    {
        return;
    }
    g_hAdminMenu = adminmenu;

    TopMenuObject player_commands = g_hAdminMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);
    if (player_commands != INVALID_TOPMENUOBJECT)
    {
        g_hAdminMenu.AddItem("Fling player", TopMenuHandler_FlingPlayer, player_commands, "sm_fling", ADMFLAG_SLAY);
    }
}

public void OnConfigsExecuted()
{
    g_cvSnd.GetString(g_flingSnd, sizeof(g_flingSnd));
    if (g_cvDownloadSnd.BoolValue)
    {
        AddFileToDownloadsTable(g_flingSnd);
    }
    PrecacheSound(g_flingSnd);
}

int MenuHandler_ForceSelect(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_Display:
        {
            char display[64];
            Format(display, sizeof(display), "%T:", "Fling force", param1);

            Panel panel = view_as<Panel>(param2);
            panel.SetTitle(display);
        }

        case MenuAction_DisplayItem:
        {
            char info[5], display[64];
            menu.GetItem(param2, info, sizeof(info), _, display, sizeof(display));
            Format(display, sizeof(display), "%T (%s)", display, param1, info);

            return RedrawMenuItem(display);
        }

        case MenuAction_Select:
        {
            char info[5];
            menu.GetItem(param2, info, sizeof(info));

            g_myForce[param1] = StringToInt(info);
            if (!DisplayTargetSelect(param1))
            {
                ReplyToTargetError(param1, COMMAND_TARGET_NONE);
            }
        }

        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                g_hAdminMenu.Display(param1, TopMenuPosition_LastCategory);
            }
        }
    }

    return 0;
}

void TopMenuHandler_FlingPlayer(TopMenu topmenu, 
TopMenuAction action, 
TopMenuObject object_id,
int param, 
char[] buffer,
int maxLength)
{
    switch(action)
    {
        case TopMenuAction_DisplayOption:
        Format(buffer, maxLength, "%T", "Fling player", param);

        case TopMenuAction_SelectOption:
        {
            g_hForceSelect.Display(param, MENU_TIME_FOREVER);
        }
    }
}

Action Command_Fling(int client, int numArgs)
{
    if (numArgs >= 1)
    {
        char targetStr[32];
        GetCmdArg(1, targetStr, sizeof(targetStr));

        int targetList[MAXPLAYERS];
        char targetName[64];
        bool tn_is_ml;
        int targetCount;
        if ((targetCount = ProcessTargetString(targetStr,
        client,
        targetList,
        sizeof(targetList),
        COMMAND_FILTER_ALIVE,
        targetName,
        sizeof(targetName),
        tn_is_ml)) <= 0)
        {
            ReplyToTargetError(client, targetCount);
            return Plugin_Handled;
        }

        int force = ClampInt(GetCmdArgInt(2), MIN_FORCE, MAX_FORCE);
        if (force == 0)
        {
            force = 300;
        }

        for (int i = 0; i < targetCount; i++)
        {
            PerformFling(client, targetList[i], force);
        }

        if (tn_is_ml)
        {
            ShowActivity2(client, "[SM] ", "%t", "Flung player", targetName);
        }
        else 
        {
            ShowActivity2(client, "[SM] ", "%t", "Flung player", "_s", targetName);
        }
    }
    else if (client > 0)
    {
        g_hForceSelect.Display(client, MENU_TIME_FOREVER);
    }
    else 
    {
        PrintToServer("[SM] Usage: sm_fling <#userid|target> <#force>");
    }

    return Plugin_Handled;
}

bool DisplayTargetSelect(int client)
{
    Menu menu = new Menu(MenuHandler_TargetSelect, MenuAction_Display);
    if (AddTargetsToMenu(menu, client, true, true) == 0)
    {
        delete menu;
        return false;
    }
    menu.ExitBackButton = true;
    menu.Display(client, 60);
    return true;
}

int MenuHandler_TargetSelect(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_Display:
        {
            char title[64];
            Format(title, sizeof(title), "%T", "Fling player: force", param1, g_myForce[param1]);

            Panel panel = view_as<Panel>(param2);
            panel.SetTitle(title);
        }

        case MenuAction_Select:
        {
            char info[4];
            menu.GetItem(param2, info, sizeof(info));

            int target = GetClientOfUserId(StringToInt(info));
            if (target == 0)
            {
                PrintToChat(param1, "[SM] %t", "Player no longer available");
            }
            else if (!IsPlayerAlive(target))
            {
                PrintToChat(param1, "[SM] %t", "Player has since died");
            }
            else 
            {
                PerformFling(param1, target, g_myForce[param1]);

                char targetName[64];
                GetClientName(target, targetName, sizeof(targetName));
                ShowActivity2(param1, "[SM] ", "%t", "Flung player", "_s", targetName);
            }
        }

        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack || param2 == MenuCancel_Timeout)
            {
                g_hForceSelect.Display(param1, MENU_TIME_FOREVER);
            }
        }

        case MenuAction_End:
        delete menu;
    }

    return 0;
}

void PerformFling(int admin, int target, int force)
{
    float ang[3], fwd[3];
    GetClientAbsAngles(target, ang);
    GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(fwd, -float(force));
    fwd[2] = FloatAbs(float(force));

    TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, fwd);
    EmitSoundToAll(g_flingSnd, target, SNDCHAN_STATIC);
    LogAction(admin, target, "\"%L\" flung \"%L\" (force: \"%d\").", admin, target, force);
}

int ClampInt(int value, int min, int max)
{
    if (value < min)
    {
        return min;
    }
    else if (value > max)
    {
        return max;
    }
    return value;
}