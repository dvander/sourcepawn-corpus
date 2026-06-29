// INCLUDES & DEFINES //

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define VERSION "1.3"

new Handle:g_CvarDescMode = INVALID_HANDLE;
new Handle:g_CvarShowOnConnect = INVALID_HANDLE;
new Item = 0;

// PLUGIN INFO //

public Plugin:myinfo = 
{
    name = "Simple Help Menu",
    author = "PHHAAKE",
    description = "Help",
    version = VERSION,
    url = ""
};


// ESSENTIAL FUNCTIONS //


public OnPluginStart()
{
     // Register Client / Admins Commands
    RegConsoleCmd("sm_helps", HelpsMenu_Func);
    RegAdminCmd("sm_showhelps", ShowHelps, ADMFLAG_GENERIC);
    
    g_CvarDescMode = CreateConVar("sm_helps_descmode", "0", "Set to 0 if you want Help to be show on a menu ,and 1 if you want it to show on chat .");
    
}

// CMD HANDLERs //

public Action:HelpsMenu_Func(client, args)
{
     // Function To Create the menu and send it to client
    CreateHelpsMenu(client, 0);
    PrintToChat(client, "\x04[Helps] \x03You Have \x01succefully openned \x03Helps Menu!");
    return Plugin_Handled;
}

public Action:ShowHelps(client, args)
{
     // Send admins a list of players to send the Helps menu
    new Handle:PlayersMenu = CreateMenu(ShowHelpsHandler);
    SetMenuTitle(PlayersMenu, "Send Helps To Player");
    SetMenuExitButton(PlayersMenu, true);
    AddTargetsToMenu2(PlayersMenu, client, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);
    DisplayMenu(PlayersMenu, client, 15);
    return Plugin_Handled;
}


// MENUs / MENUs HANDLERs

public Action:CreateHelpsMenu(client, item)
{
    new Handle:HelpsMenu = CreateMenu(HelpsMenuHandler);
    SetMenuTitle(HelpsMenu, "Help Menu");
    
    new Handle:kv = CreateKeyValues("Helps");
    FileToKeyValues(kv, "addons/sourcemod/configs/helps.cfg");
    
	  if (!KvGotoFirstSubKey(kv))
	  {
		    return Plugin_Continue;
	  }
	  
	  decl String:HelpNumber[64];
	  decl String:HelpName[255];
	  
	  do
	  {
    	  KvGetSectionName(kv, HelpNumber, sizeof(HelpNumber));    
        KvGetString(kv, "help", HelpName, sizeof(HelpName));
         // Add Each Help to the menu 
        AddMenuItem(HelpsMenu, HelpNumber, HelpName);    
    } while (KvGotoNextKey(kv));
    CloseHandle(kv);  
     // Send Menu to client
    DisplayMenuAtItem(HelpsMenu, client, item, 15);
    
    return Plugin_Handled;  
}

public HandlerBackToMenu(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        CreateHelpsMenu(param1, Item);
    }
    else if (action == MenuAction_Cancel)
	  {
		    PrintToServer("", param1, param2);
	  }

    else if (action == MenuAction_End)
	  {
		    CloseHandle(menu);
	  }
}


public HelpsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {             
        new Handle:kv = CreateKeyValues("Helps");   
        FileToKeyValues(kv, "addons/sourcemod/configs/helps.cfg");
        
        if (!KvGotoFirstSubKey(kv))
	      {
		        return Plugin_Handled;
	      }
        
        decl String:buffer[255];
        decl String:choice[255];
        GetMenuItem(menu, param2, choice, sizeof(choice));     
        
        do
        {   
            KvGetSectionName(kv, buffer, sizeof(buffer));
            if (StrEqual(buffer, choice))
            {
                decl String:HelpName[255];
                decl String:HelpDescription[255];
                KvGetString(kv, "help", HelpName, sizeof(HelpName));
                KvGetString(kv, "info", HelpDescription, sizeof(HelpDescription));

                if (GetConVarInt(g_CvarDescMode))
                {
                    PrintToChat(param1, "\x04[Helps] \x03%s : \x01%s", HelpName, HelpDescription);
                    Item = GetMenuSelectionPosition();
                    CreateHelpsMenu(param1, Item);
                }
                else
                {
                    decl String:Help[255];
                    decl String:Desc[255];
                    Format(Help, sizeof(Help), "%s", HelpName);
                    Format(Desc, sizeof(Desc), "%s", HelpDescription); 
                    Item = GetMenuSelectionPosition();               
                    new Handle:DescriptionPanel = CreatePanel(); 
                    SetPanelTitle(DescriptionPanel, Help);
                    DrawPanelText(DescriptionPanel, " ");
                    DrawPanelText(DescriptionPanel, Desc);
                    DrawPanelText(DescriptionPanel, " ");
                    DrawPanelItem(DescriptionPanel, "Back");                   
                    SendPanelToClient(DescriptionPanel, param1, HandlerBackToMenu, 15);                
                }


            }
        } while (KvGotoNextKey(kv));
        CloseHandle(kv);           
    }
    else if (action == MenuAction_Cancel)
	  {
		    PrintToServer("", param1, param2);
	  }

    else if (action == MenuAction_End)
	  {
		    CloseHandle(menu);
	  }

    return Plugin_Handled; 
}

public ShowHelpsHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:UserId[64];
        GetMenuItem(menu, param2, UserId, sizeof(UserId));
        new i_UserId = StringToInt(UserId);
        new client = GetClientOfUserId(i_UserId);
        CreateHelpsMenu(client, 1);
    }

    else if (action == MenuAction_Cancel)
	  {
		    PrintToServer("", param1, param2);
	  }

    else if (action == MenuAction_End)
	  {
		    CloseHandle(menu);
	  }

    return Plugin_Handled; 
    
}