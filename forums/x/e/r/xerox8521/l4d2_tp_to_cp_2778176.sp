#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.0.0"

GameData g_pGameConfig = null;

TopMenu hAdminMenu = null;

public Plugin myinfo =
{
	name = "[L4D2] Checkpoint Teleport",
	author = "XeroX",
	description = "Allows admins to teleport survivors to the checkpoint",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=337558"
}

public void OnPluginStart()
{
    g_pGameConfig = new GameData("l4d2_tp_to_cp");
    if(g_pGameConfig == null)
    {
        SetFailState("GameData file is missing or cannot be read!");
        return;
    }
    
    RegAdminCmd("sm_tptocp", Command_TPTOCP, ADMFLAG_CHEATS, "Teleports all survivors to the checkpoint");
    RegAdminCmd("sm_tptofinale", Command_TPTOFINALE, ADMFLAG_CHEATS, "Teleports all survivors to the finale");

    TopMenu topmenu;
    if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
    {
        OnAdminMenuReady(topmenu);
    }
}

public void OnLibraryRemoved(const char[] szName)
{
    if(StrEqual(szName, "adminmenu", false))
    {
        hAdminMenu = null;
    }
}

public void OnAdminMenuReady(Handle aTopmenu)
{
    TopMenu topmenu = TopMenu.FromHandle(aTopmenu);

    if(topmenu == hAdminMenu)
        return;
    
    hAdminMenu = topmenu;

    TopMenuObject server_commands = hAdminMenu.FindCategory(ADMINMENU_SERVERCOMMANDS);
    if(server_commands != INVALID_TOPMENUOBJECT)
    {
        hAdminMenu.AddItem("sm_tp_to_cp", AdminMenu_TpToCp, server_commands, "sm_tptocp", ADMFLAG_CHEATS);
        hAdminMenu.AddItem("sm_tp_to_finale", AdminMenu_TpToFinale, server_commands, "sm_tptofinale", ADMFLAG_CHEATS);
    }
}

public void AdminMenu_TpToCp(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    if(action == TopMenuAction_DisplayOption)
    {
        Format(buffer, maxlength, "TP Survivors to Checkpoint");
    }
    else if(action == TopMenuAction_SelectOption)
    {
        TeleportSurvivorsToCP(param);
    }
}

public void AdminMenu_TpToFinale(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    if(action == TopMenuAction_DisplayOption)
    {
        Format(buffer, maxlength, "TP Survivors to Finale");
    }
    else if(action == TopMenuAction_SelectOption)
    {
        TeleportSurvivorsToFinale(param);
    }
}


void TeleportSurvivorsToCP(int client)
{
    static Handle hSDKCall = null;
    if(hSDKCall == null)
    {
        StartPrepSDKCall(SDKCall_Static);
        PrepSDKCall_SetFromConf(g_pGameConfig, SDKConf_Signature, "WarpToCheckpoint");
        hSDKCall = EndPrepSDKCall();
    }
    if(hSDKCall != null)
    {
        SDKCall(hSDKCall);
    }
    PrintToChat(client, "Teleporting Survivors to Checkpoint");
    LogAction(client, -1, "\"%L\" teleported all survivors to the checkpoint", client);
}

void TeleportSurvivorsToFinale(int client)
{
    static Handle hSDKCall = null;
    if(hSDKCall == null)
    {
        StartPrepSDKCall(SDKCall_Static);
        PrepSDKCall_SetFromConf(g_pGameConfig, SDKConf_Signature, "WarpToFinale");
        hSDKCall = EndPrepSDKCall();
    }
    if(hSDKCall != null)
    {
        SDKCall(hSDKCall);
    }
    PrintToChat(client, "Teleporting Survivors to Finale");
    LogAction(client, -1, "\"%L\" teleported all survivors to the finale", client);
}

public Action Command_TPTOFINALE(int client, int args)
{
    
    TeleportSurvivorsToFinale(client);
    return Plugin_Handled;
}

public Action Command_TPTOCP(int client, int args)
{
    TeleportSurvivorsToCP(client);
    return Plugin_Handled;
}

