//                          =======================================================================
//	                    |     Plugin By Tair Azoulay                                          |
//                          |                                                                     |
//                          |     Profile : http://steamcommunity.com/profiles/76561198013150925/ |                                         |
//                          |                                                                     |
//	                    |     Name : SteamID Player                                           |
//                          |                                                                     |
//	                    |     Version : 1.0                                                   |
//                          |                                                                     |
//	                    |     Description : Check SteamID of player.                          |     
//                          =======================================================================
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <adminmenu>


public Plugin:myinfo = 
{
	name = "SteamID Player",
	author = "Tair",
	description = "Check SteamID of player.",
	version = "1.0",
	url = "Www.sourcemod.net"
}

public OnPluginStart() 
{
        RegConsoleCmd("sm_steamid", Command_SteamID);
}


public Action:Command_SteamID(client, args)
{
        new Handle:menu = CreateMenu(MenuHandler1, MENU_ACTIONS_ALL);
        SetMenuTitle(menu,"Choose Player :");
        AddTargetsToMenu2(menu, 0 , COMMAND_FILTER_NO_BOTS);
        DisplayMenu(menu, client, 20);
    return Plugin_Continue;
}

public MenuHandler1(Handle:menu, MenuAction:action, client, itemNum)
{

    if ( action == MenuAction_Select ) 
    {
        new String:info[32];
        decl String:Name[32];    
        GetMenuItem(menu, itemNum, info, sizeof(info));     
        new iInfo = StringToInt(info);
        new iUserid = GetClientOfUserId(iInfo);
        GetClientName(iUserid, Name, sizeof(Name));    

 	new String:ID1[50];
	GetClientAuthString(iUserid, ID1, 50);
        PrintToChatAll(" \x04[SM]\x01 %s SteamID : %s",Name ,ID1);
        }    
    }



 