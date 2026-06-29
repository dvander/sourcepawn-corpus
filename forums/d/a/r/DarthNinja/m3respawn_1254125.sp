#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <colors>
#include <sdktools_functions>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hAdminMenu = INVALID_HANDLE;

// new Handle:g_Target[MAXPLAYERS+1];

#define PLUGIN_VERSION "1.0.102"


public Plugin:myinfo = {
    name = "M3Respawn - Respawn a dead player reloaded",
    author = "M3Studios, Inc.",
    description = "Let's admins respawn any dead player.",
    version = "1.1.0",
    url = "http://www.m3studiosinc.com/"
}

public OnPluginStart() {
    RegAdminCmd("sm_respawn", CmdRespawn, ADMFLAG_KICK, "sm_respawn <#userid|name>");
    
    new Handle:topmenu;
    if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
    {
        OnAdminMenuReady(topmenu);
    }
}

public Action:CmdRespawn(client, args) {
    decl String:target[65];
    decl String:target_name[MAX_TARGET_LENGTH];
    decl target_list[MAXPLAYERS];
    decl target_count;
    decl bool:tn_is_ml;
    
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_respawn <#userid|name>");
        return Plugin_Handled;
    }
    
    GetCmdArg(1, target, sizeof(target));
    
    if((target_count = ProcessTargetString(
            target,
            client,
            target_list,
            MAXPLAYERS,
            0,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }
        
    for (new i = 0; i < target_count; i++)
    {
        if (IsClientInGame(target_list[i]) && IsPlayerAlive(target_list[i]))
        {
            doRespawn(client, target_list[i]);
        }
    }
    return Plugin_Handled;
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "adminmenu")) 
    {
        hAdminMenu = INVALID_HANDLE;
    }
}

public OnAdminMenuReady(Handle:topmenu)
{
    if (topmenu == hAdminMenu)
    {
        return;
    }
    
    hAdminMenu = topmenu;

    new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);

    if (player_commands != INVALID_TOPMENUOBJECT)
    {
        AddToTopMenu(hAdminMenu,
            "sm_respawn",
            TopMenuObject_Item,
            AdminMenu_Respawn, 
            player_commands,
            "sm_respawn",
            ADMFLAG_KICK);
    }
}

public AdminMenu_Respawn( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
    if (action == TopMenuAction_DisplayOption)
    {
        Format(buffer, maxlength, "Respawn Dead Players");
    }
    else if( action == TopMenuAction_SelectOption)
    {
        DisplayPlayerMenu(param);
    }
}

DisplayPlayerMenu(client)
{
    new Handle:menu = CreateMenu(MenuHandler_Players);
    
    decl String:title[100];
    Format(title, sizeof(title), "Choose Player to Respawn:");
    SetMenuTitle(menu, title);
    SetMenuExitBackButton(menu, true);
    
    AddTargetsToMenu2(menu, client, COMMAND_FILTER_DEAD|CS_TEAM_CT);
    AddTargetsToMenu2(menu, client, COMMAND_FILTER_DEAD|CS_TEAM_T);
    if(GetMenuItemCount(menu) == 0)        
    {
        AddMenuItem(menu,"refresh","Refresh",ITEMDRAW_DEFAULT);
        AddMenuItem(menu,"no_client","No aviable client",ITEMDRAW_DISABLED);
    }
    
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Players(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
        {
            DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
        }
    }
    else if (action == MenuAction_Select)
    {
        decl String:info[32];
        new userid, target;
        
        GetMenuItem(menu, param2, info, sizeof(info));
        if(!StrEqual(info,"no_client",true) && !StrEqual(info,"refresh",true))
        {
            userid = StringToInt(info);

            if ((target = GetClientOfUserId(userid)) == 0)
            {
                CPrintToChat(param1, "{olive}[SM] {red}%s", "Player no longer available");
            }
            else if (!CanUserTarget(param1, target))
            {
                CPrintToChat(param1, "{olive}[SM] {red}%s", "Unable to target");
            }
            else
            {    
                decl String:targetname[60];
                GetClientName(target,targetname,sizeof(targetname));
                doRespawn(param1, target);
                CPrintToChatEx(param1,target,"{olive}[M3Respawn] {green}You have Respawned {teamcolor}%s",targetname); 
            }
            
            /* Re-draw the menu if they're still valid */
            if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
            {
                DisplayPlayerMenu(param1);
            }
        }
        else
        {
			if(StrEqual(info,"refresh",true) && IsClientInGame(param1) && !IsClientInKickQueue(param1))        DisplayPlayerMenu(param1);
        }
    }
}

public doRespawn(client, target) {
    new String:adminName[MAX_NAME_LENGTH];
    GetClientName(client, adminName, sizeof(adminName));
        
    CPrintToChatEx(target,client,"{green}(ADMIN) {teamcolor}%s {olive}has given you another chance",adminName);
    
    CS_RespawnPlayer(target);
}