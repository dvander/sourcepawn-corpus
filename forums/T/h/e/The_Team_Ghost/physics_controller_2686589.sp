#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Yimura"
#define PLUGIN_VERSION "1.0.0"

#include <sourcemod>
#include <sdktools>

ConVar
    g_cvGravity,

    g_cvClientGravity,
    g_cvPhysicsGravity,
    g_cvEntityGravity,

    g_cvServerReloadTimer;

int
    g_iInterval = 0,

    g_iPreviousClientGravity = -1,
    g_iPreviousPhysicsGravity = -1,
    g_iPreviousEntityGravity = -1,

    g_iClientGravity = 800,
    g_iPhysicsGravity = 800,
    g_iEntityGravity = 800;

#pragma newdecls required

public Plugin myinfo =
{
	name = "[ANY/?] Gravity Controller",
	author = PLUGIN_AUTHOR,
	description = "A plugin which modifies certain aspects of gravity",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
    RegAdminCmd("sm_physics", Command_Physics, ADMFLAG_ROOT, "Gravity Menu");

    g_cvClientGravity = CreateConVar("sm_physics_clientgravity", "800", "Value for client-side gravity (800 = source engine default), ragdolls are controlled by this.");
    g_cvPhysicsGravity = CreateConVar("sm_physics_physicsgravity", "800", "Value for physics gravity (800 = source engine default), ammo packs are controlled by this.");
    g_cvEntityGravity = CreateConVar("sm_physics_entitygravity", "800", "Value for player gravity (800 = source engine default)");

    g_cvServerReloadTimer = CreateConVar("sm_physics_timer", "10", "Confirm Menu countdown timer before server reloads.");

    g_cvGravity = FindConVar("sv_gravity");

    g_iInterval = g_cvServerReloadTimer.IntValue;

    g_iPreviousClientGravity = g_cvClientGravity.IntValue;
    g_iPreviousPhysicsGravity = g_cvPhysicsGravity.IntValue;
    g_iPreviousEntityGravity = g_cvEntityGravity.IntValue;

    AutoExecConfig(true, "physics_controller");
}

public void OnClientPostAdminCheck(int iClient)
{
    if(IsFakeClient(iClient))
        return ;
    char cClientGrav[8];
    IntToString(g_iClientGravity, cClientGrav, sizeof(cClientGrav));
    g_cvGravity.ReplicateToClient(iClient, cClientGrav);
}

public void OnMapStart()
{
    g_cvGravity.SetInt(g_iEntityGravity, true, true);
}

public void OnMapEnd()
{
    g_cvGravity.SetInt(g_iPhysicsGravity, true, true);
}

Action Command_Physics(int iClient, int iArgs)
{
    if (iArgs >= 4)
    {
        ReplyToCommand(iClient, "Invalid arguments, usage: sm_physics <# number of client gravity> <# number of physics gravity> <# number for entity gravity>");
        return Plugin_Handled;
    }

    g_iPreviousClientGravity = g_iClientGravity;
    g_iPreviousPhysicsGravity = g_iPhysicsGravity;
    g_iPreviousEntityGravity = g_iEntityGravity;

    if (iArgs == 3)
    {
        char
            cClientGrav[8],
            cPhysicsGrav[8],
            cEntityGrav[8];
        GetCmdArg(1, cClientGrav, sizeof(cClientGrav));
        GetCmdArg(2, cPhysicsGrav, sizeof(cPhysicsGrav));
        GetCmdArg(3, cEntityGrav, sizeof(cEntityGrav));

        g_iClientGravity = StringToInt(cClientGrav);
        g_iPhysicsGravity = StringToInt(cPhysicsGrav);
        g_iEntityGravity = StringToInt(cEntityGrav);

        ConfirmMenu(iClient);
        return Plugin_Handled;
    }

    if(iArgs == 2)
    {
        char
            cClientGrav[8],
            cPhysicsGrav[8];
        GetCmdArg(1, cClientGrav, sizeof(cClientGrav));
        GetCmdArg(2, cPhysicsGrav, sizeof(cPhysicsGrav));

        g_iClientGravity = StringToInt(cClientGrav);
        g_iPhysicsGravity = StringToInt(cPhysicsGrav);
        g_iEntityGravity = g_cvEntityGravity.IntValue;

        ConfirmMenu(iClient);
        return Plugin_Handled;
    }

    if(iArgs == 1)
    {
        char
            cClientGrav[8];
        GetCmdArg(1, cClientGrav, sizeof(cClientGrav));

        g_iClientGravity = StringToInt(cClientGrav);
        g_iPhysicsGravity = g_cvPhysicsGravity.IntValue;
        g_iEntityGravity = g_cvEntityGravity.IntValue;

        ConfirmMenu(iClient);
        return Plugin_Handled;
    }

    OpenClientMenu(iClient);
    return Plugin_Handled;
}

void ConfirmMenu(int iClient)
{
    Menu mMenu = new Menu(ConfirmMenuHandler);
    mMenu.SetTitle("Reload server now?");
    mMenu.AddItem("1", "Yes");
    mMenu.AddItem("0", "No");

    mMenu.Display(iClient, 99999);
}

int ConfirmMenuHandler(Menu mMenu, MenuAction action, int iClient, int param2)
{
    if (action == MenuAction_End) delete mMenu;
    if (action == MenuAction_Select)
	{
        int iStyle;
        char cInfo[32], cDisplay[32];
        mMenu.GetItem(param2, cInfo, sizeof(cInfo), iStyle, cDisplay, sizeof(cDisplay));

        if (StringToInt(cInfo) == 1) {
            PrintToChatAll("Server will reload to apply new physics in %i seconds!", g_iInterval);
            CreateTimer(1.0, Timer_CountDown_PhysicsChange, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
        else
            PrintToChat(iClient, "[SM] Physics will update on next mapchange!");
	}
}

void OpenClientMenu(int iClient)
{
    Menu mMenu = new Menu(ClientGravMenuHandler);
    mMenu.SetTitle("Set Client Gravity:");
    mMenu.AddItem("-1200", "-1200");
    mMenu.AddItem("-800", "-800");
    mMenu.AddItem("-200", "-200");
    mMenu.AddItem("0", "0");
    mMenu.AddItem("200", "200");
    mMenu.AddItem("800", "800 (DEFAULT)");
    mMenu.AddItem("1200", "1200");

    mMenu.Display(iClient, 99999);
}

int ClientGravMenuHandler(Menu mMenu, MenuAction action, int iClient, int param2)
{
    if (action == MenuAction_End) {
        g_iClientGravity = g_iPreviousClientGravity;
        delete mMenu;
    }
    if (action == MenuAction_Select)
	{
        int iStyle;
        char cInfo[32], cDisplay[32];
        mMenu.GetItem(param2, cInfo, sizeof(cInfo), iStyle, cDisplay, sizeof(cDisplay));

        g_iPreviousPhysicsGravity = g_iPhysicsGravity;
        g_iPhysicsGravity = StringToInt(cInfo);
        OpenPhysicsMenu(iClient);
	}
}

void OpenPhysicsMenu(int iClient)
{
    Menu mMenu = new Menu(PhysicsGravMenuHandler);
    mMenu.SetTitle("Set Physics Gravity:");
    mMenu.AddItem("-1200", "-1200");
    mMenu.AddItem("-800", "-800");
    mMenu.AddItem("-200", "-200");
    mMenu.AddItem("0", "0");
    mMenu.AddItem("200", "200");
    mMenu.AddItem("800", "800 (DEFAULT)");
    mMenu.AddItem("1200", "1200");

    mMenu.Display(iClient, 99999);
}

int PhysicsGravMenuHandler(Menu mMenu, MenuAction action, int iClient, int param2)
{
    if (action == MenuAction_End) {
        g_iClientGravity = g_iPreviousClientGravity;
        g_iPhysicsGravity = g_iPreviousPhysicsGravity;
        delete mMenu;
    }
    if (action == MenuAction_Select)
	{
        int iStyle;
        char cInfo[32], cDisplay[32];
        mMenu.GetItem(param2, cInfo, sizeof(cInfo), iStyle, cDisplay, sizeof(cDisplay));

        g_iPreviousPhysicsGravity = g_iPhysicsGravity;
        g_iPhysicsGravity = StringToInt(cInfo);
        OpenEntityMenu(iClient);
	}
}

void OpenEntityMenu(int iClient)
{
    Menu mMenu = new Menu(EntityGravMenuHandler);
    mMenu.SetTitle("Set Entity Gravity:");
    mMenu.AddItem("-1200", "-1200");
    mMenu.AddItem("-800", "-800");
    mMenu.AddItem("-200", "-200");
    mMenu.AddItem("0", "0");
    mMenu.AddItem("200", "200");
    mMenu.AddItem("800", "800 (DEFAULT)");
    mMenu.AddItem("1200", "1200");

    mMenu.Display(iClient, 99999);
}

int EntityGravMenuHandler(Menu mMenu, MenuAction action, int iClient, int param2)
{
    if (action == MenuAction_End) {
        g_iClientGravity = g_iPreviousClientGravity;
        g_iPhysicsGravity = g_iPreviousPhysicsGravity;
        g_iEntityGravity = g_iPreviousEntityGravity;
        delete mMenu;
    }
    if (action == MenuAction_Select)
	{
        int iStyle;
        char cInfo[32], cDisplay[32];
        mMenu.GetItem(param2, cInfo, sizeof(cInfo), iStyle, cDisplay, sizeof(cDisplay));

        g_iPreviousEntityGravity = g_iEntityGravity;
        g_iEntityGravity = StringToInt(cInfo);
        ConfirmMenu(iClient);
	}
}

Action Timer_CountDown_PhysicsChange(Handle hTimer)
{
    if (g_iInterval == 0)
    {
        g_iInterval = 10;

        char cMapName[256];
        GetCurrentMap(cMapName, sizeof(cMapName));
        ForceChangeLevel(cMapName, "Reloading server physics");

        KillTimer(hTimer);
        return Plugin_Handled;
    }
    PrintHintTextToAll("Server will reload to apply new physics\nin %i seconds!", g_iInterval);
    g_iInterval--;
    return Plugin_Handled;
}
