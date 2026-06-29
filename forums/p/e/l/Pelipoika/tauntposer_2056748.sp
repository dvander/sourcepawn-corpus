#pragma semicolon 1
#include <tf2>
#include <tf2_stocks>
#include <sourcemod>
#include <tf2attributes>
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name        =    "TauntPoser",
	author        =    "Pelipoika",
	description    =    "Pose Yourself via Menu",
	version        =    PLUGIN_VERSION,
	url            =    "http://www.sourcemod.net"
};

new Handle:g_hPoseMenu = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("sm_poser", OnPoserCmd, ADMFLAG_CUSTOM6, "Taunt Poser Menu.");
	RegAdminCmd("sm_pose", OnPoserCmd, ADMFLAG_CUSTOM6, "Taunt Poser Menu.");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "[TF2] This plugin only works in TF2 (Duh)");
		return APLRes_Failure;
	}
	return APLRes_Success;
}


public OnConfigsExecuted()
{
	g_hPoseMenu = CreateMenu(MenuMainHandler);
	SetMenuTitle(g_hPoseMenu, "Taunt Poser Menu");
	AddMenuItem(g_hPoseMenu, "1", "Taunt speed -1x");
	AddMenuItem(g_hPoseMenu, "2", "Taunt speed 0x");
	AddMenuItem(g_hPoseMenu, "3", "Taunt speed 0.1x");
	AddMenuItem(g_hPoseMenu, "4", "Taunt speed 0.25x");
	AddMenuItem(g_hPoseMenu, "5", "Taunt speed 0.5x");
	AddMenuItem(g_hPoseMenu, "6", "Taunt speed 1x");
	AddMenuItem(g_hPoseMenu, "7", "Untaunt");
}

public Action:OnPoserCmd(client, args)
{
	if(!CheckCommandAccess(client, "sm_poser_access", ADMFLAG_CUSTOM6))
	{
		ReplyToCommand(client, "[SM] You don't have acces to this command.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		ReplyToCommand(client, "Cannot use command from RCON.");
		return Plugin_Handled;
	}
	DisplayMenuSafely(g_hPoseMenu, client);
	return Plugin_Handled;
}

public MenuMainHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		switch (param2)
		{
			case 0:
            {
				/*if(TF2_IsPlayerInCondition(param1, TFCond_Taunting))
				{
					DisplayMenu(menu, param1, MENU_TIME_FOREVER);
					TF2Attrib_SetByName(param1, "gesture speed increase", -1.0);
				}
				else
				{
					DisplayMenu(menu, param1, MENU_TIME_FOREVER);
					PrintToChat(param1, "\x04 You cannot set taunt speed to -1 unless you are taunting.");
				}*/
				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
				TF2Attrib_SetByName(param1, "gesture speed increase", -1.0);
            }
            case 1:
            {
				/*if(TF2_IsPlayerInCondition(param1, TFCond_Taunting))
				{
					DisplayMenu(menu, param1, MENU_TIME_FOREVER);
					TF2Attrib_SetByName(param1, "gesture speed increase", 0.0);
				}
				else
				{
					DisplayMenu(menu, param1, MENU_TIME_FOREVER);
					PrintToChat(param1, "\x04 You cannot set taunt speed to 0 unless you are taunting.");
				}*/
				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
				TF2Attrib_SetByName(param1, "gesture speed increase", 0.0);
            }
            case 2:
            {
				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
				TF2Attrib_SetByName(param1, "gesture speed increase", 0.1);
			}
            case 3:
            {
				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
				TF2Attrib_SetByName(param1, "gesture speed increase", 0.25);
            }
            case 4:
            {
				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
				TF2Attrib_SetByName(param1, "gesture speed increase", 0.5);
            }
            case 5:
            {
				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
				TF2Attrib_SetByName(param1, "gesture speed increase", 1.0);
            }
			case 6:
			{
				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
				TF2_RemoveCondition(param1, TFCond_Taunting);
				PrintToChat(param1, "Made you stop Taunting");
			}
		}
	}
}

stock DisplayMenuSafely(Handle:menu, client)
{
    if (client != 0)
    {
        if (menu == INVALID_HANDLE)
        {
            PrintToConsole(client, "ERROR: Unable to open Poser Menu.");
        }
        else
        {
            DisplayMenu(menu, client, MENU_TIME_FOREVER);
        }
    }
}

public OnMapEnd()
{
    if (g_hPoseMenu != INVALID_HANDLE)
    {
        CloseHandle(g_hPoseMenu);
        g_hPoseMenu = INVALID_HANDLE;
    }
}  