#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_DEBUG                    					"0" // Debug to console, 1 = on, 0 = off
#define PLUGIN_CONVAR_DEBUG             					"sm_genericmenu_debug" // ConVar name for debugging
//#define CONFIG_PATH_CREATE		    					"configs/menu_items.cfg"	// Place where automaticly config file gets created if not exists, combined into MENU_CONFIG_TITLE_FILE
//#define CONFIG_PATH_READ									"addons/sourcemod/configs/menu_items.cfg"	// File thats being read, combined into MENU_CONFIG_TITLE_FILE
#define MENU_OPEN_COMMAND									"sm_menu"	// Command to open the menu, keep in quote
#define MENU_OPEN_TITLE										"Menu Title"	// Title inside the menu shown in game
#define MENU_CONFIG_TITLE_FILE        						"menu_items.cfg" // File name inside addons/sourcemod/configs
#define MENU_CONFIG_TITLE_INTERNAL							"MenuItems"		// Title inside the config file at top
#define MENU_CONFIG_RELOAD_COMMAND							"sm_reloadmenu"	// Command to reload the config, not the plugin
#define MENU_CONFIG_RELOAD_OUTPUT							"sm_chat GenericMenu.smx has been reloaded."	// Command executed after reloading the config
#define MENU_DISABLED_OUTPUT           						"[SM] Menu is not available at the moment." // Output when menu is disabled
#define MENU_CONVAR_ONOFF               				    "sm_genericmenu_enabled" // ConVar name for enabling/disabling the menu
#define MENU_CONVAR_DESCRIPTION         				    "Enable or disable the menu" // ConVar description
#define MENU_ENABLED_DEFAULT            				    "1" // Menu enabled (1) or disabled (0), anything other than 1 is disabled
#define MENU_CONVAR_ADMIN_REQUIRE_ONOFF 					"sm_genericmenu_admin_require" // ConVar name for enabling/disabling admin only access
#define MENU_CONVAR_ADMIN_REQUIRE_DEFAULT				    "1" // Avabile to all (0) or admin only (1)
#define MENU_CONVAR_ADMIN_REQUIRE_LEVEL 					ADMFLAG_ROOT // Admin flag required to use the menu if MENU_ADMIN_REQUIRE == 1, no quotes ("")


public Plugin myinfo =
{
	name = "[TF2] Generic Menu",
	author = "well",
	description = "Creates a menu for easy command access",
	version = "1.8",
	//url = ""
};

char g_itemNames[MAXPLAYERS + 1][1000][64]; 
Handle g_hConVarDebug;
Handle g_hKvMenuItems;
Handle g_hConVarMenuEnabled;
Handle g_hConVarMenuAccess;

public void OnPluginStart()	// Autoexec go brrr
{
    g_hConVarMenuEnabled = CreateConVar(MENU_CONVAR_ONOFF, MENU_ENABLED_DEFAULT, MENU_CONVAR_DESCRIPTION , FCVAR_NONE, true, 0.0, true, 1.0);
    g_hConVarDebug = CreateConVar(PLUGIN_CONVAR_DEBUG, PLUGIN_DEBUG, "Enable or Disable Debug output to console", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hConVarMenuAccess = CreateConVar(MENU_CONVAR_ADMIN_REQUIRE_ONOFF, MENU_CONVAR_ADMIN_REQUIRE_DEFAULT, "Enable or Disable Admin only access, Enabled by default", FCVAR_NONE, true, 0.0, true, 1.0);
    RegConsoleCmd(MENU_OPEN_COMMAND, MenuCommand); // Open menu all avabile
    RegAdminCmd(MENU_CONFIG_RELOAD_COMMAND, ReloadCommand, ADMFLAG_ROOT);	// Config reload command
    CreateDefaultMenuConfig(); // Create the config file if it doesn't exist
    LoadMenuItems();    //Load menu items from config

    if (GetConVarInt(g_hConVarDebug) == 1) // Debug to console
    {
        PrintToServer("[SM] GenericMenu.smx OnPluginStart check");
    }
}

public Action MenuCommand(int client, int args)	// IF cvar = 1, work. Else = no work
{
    if (GetConVarInt(g_hConVarMenuAccess) == 1) // If admin only, do below
    {
        if (GetUserFlagBits(client) & MENU_CONVAR_ADMIN_REQUIRE_LEVEL) // Check adminflag with said flag, ROOT might not if flag =/= ROOT
        {
            if (client == 0)
            {
                PrintToServer("[SM] This command is only available to in-game players.");
            }
            else
            {
                if (GetConVarInt(g_hConVarMenuEnabled) == 1)    // IF 1, do below
                {
                    ShowMenu(client);
                    if (GetConVarInt(g_hConVarDebug) == 1) // Debug to console
                    {
                        PrintToServer("[SM] GenericMenu.smx MenuCommand == 1 check");
                    }
                }
                else        //If other than 1, do below
                {
                    PrintToChat(client, MENU_DISABLED_OUTPUT);   // Reply to client privately
                    if (GetConVarInt(g_hConVarDebug) == 1) // Debug to console
                    {
                        PrintToServer("[SM] GenericMenu.smx MenuCommand =/= 1 check");
                    }
                }
            }   
        }
        else
        {
            PrintToChat(client, "[SM] You do not have access to this command."); // Reply to client privately
        }
    }
    else    // If not admin only, do below
    {
        if (client == 0)
        {
            PrintToServer("[SM] This command is only available to in-game players.");
        }
        else
        {
            if (GetConVarInt(g_hConVarMenuEnabled) == 1)    // IF 1, do below
            {
                ShowMenu(client);
                if (GetConVarInt(g_hConVarDebug) == 1) // Debug to console
                {
                    PrintToServer("[SM] GenericMenu.smx MenuCommand == 1 check");
                }
            }
            else        //If other than 1, do below
            {
                PrintToChat(client, MENU_DISABLED_OUTPUT);   // Reply to client privately
                if (GetConVarInt(g_hConVarDebug) == 1) // Debug to console
                {
                    PrintToServer("[SM] GenericMenu.smx MenuCommand =/= 1 check");
                }
            }
        }        
    }
    return Plugin_Handled;
}



public Action ReloadCommand(int client, int args)	//Reload command funciton
{
	LoadMenuItems();	//Reloads the config
    ServerCommand(MENU_CONFIG_RELOAD_OUTPUT);	//Output after reloading
    if (GetConVarInt(g_hConVarDebug) == 1) // Debug to console
    {
        PrintToServer("[SM] GenericMenu.smx ReloadCommand check");
    }
	return Plugin_Handled;	// Removes Unkown command output
}

public void ShowMenu(int client)	//Shows menu
{
    Handle hMenu = CreateMenu(MenuHandler);
    SetMenuTitle(hMenu, MENU_OPEN_TITLE);	// Title shown ingame menu
    if (g_hKvMenuItems != INVALID_HANDLE)
    {
        KvRewind(g_hKvMenuItems);
        char itemName[64];
        char itemCommand[128];
        KvGotoFirstSubKey(g_hKvMenuItems); 
        int i = 0;
        do
        {
            KvGetString(g_hKvMenuItems, "name", itemName, sizeof(itemName));			// Config read name, put name in menu
            KvGetString(g_hKvMenuItems, "command", itemCommand, sizeof(itemCommand));	// Config read command, put command in the menu under said name
            AddMenuItem(hMenu, itemCommand, itemName);
            strcopy(g_itemNames[client][i], sizeof(g_itemNames[][]), itemName); // Save item name, for feedback to admin
            i++;
        } while (KvGotoNextKey(g_hKvMenuItems, false)); 
        if (GetConVarInt(g_hConVarDebug) == 1) // Debug to console
        {
            PrintToServer("[SM] GenericMenu.smx ShowMenu check");
        }
    }
    else
    {
        PrintToServer("[SM] GenericMenu.smx ShowMenu error");	//Error to console
    }

    DisplayMenu(hMenu, client, 0);
}

public void MenuHandler(Handle menu, MenuAction action, int param1, int param2)	// Stuff that happens when you use a menu item
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char itemCommand[128];
            GetMenuItem(menu, param2, itemCommand, sizeof(itemCommand));
            char command[256];
            char itemName[64];
            strcopy(itemName, sizeof(itemName), g_itemNames[param1][param2]); // Function to replace 1st %s with command, 2nd %s with the menu item name
            Format(command, sizeof(command), "[SM]User %%n has redeemed %s with %s", itemName, itemCommand); 
            ReplaceVariables(itemCommand, sizeof(itemCommand), param1);
            ReplaceVariables(command, sizeof(command), param1);
            ServerCommand("%s", itemCommand);
            PrintToServer("%s", command);
        
            if (GetConVarInt(g_hConVarDebug) == 1) // Debug to console
            {
                PrintToServer("[SM] GenericMenu.smx MenuAction_Select check");
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);	// Slot10 to close the menu
            if (GetConVarInt(g_hConVarDebug) == 1) // Debug to console
            {
                PrintToServer("[SM] GenericMenu.smx MenuAction_End check");
            }
        }
    }
}

public void LoadMenuItems()
{
    g_hKvMenuItems = CreateKeyValues(MENU_CONFIG_TITLE_INTERNAL);
    char pathsmconfigs[] = "configs/";
    char configPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, configPath, sizeof(configPath), "%s%s", pathsmconfigs, MENU_CONFIG_TITLE_FILE);

    if (GetConVarInt(g_hConVarDebug) == 1) // Debug to console
    {
        PrintToServer("[SM] Attempting to load file from path: %s", configPath);
    }

    if (FileToKeyValues(g_hKvMenuItems, configPath))	//Config file to read from. If change, change 
    {
        if (GetConVarInt(g_hConVarDebug) == 1) // Debug to console
        {
            PrintToServer("[SM] GenericMenu.smx LoadMenuItems check");
        }
    }
    else
    {
        if (GetConVarInt(g_hConVarDebug) == 1)
        {
            PrintToServer("[SM] GenericMenu.smx LoadMenuItems error");
        }
        CloseHandle(g_hKvMenuItems); 
        g_hKvMenuItems = INVALID_HANDLE;
    }
}

//Replace %u and %n with UserID and Username respectively in the config file
public void ReplaceVariables(char[] output, int maxlength, int client)
{
    char sBuffer[32];
    char clientName[64];

    // Replace %u with user ID
    IntToString(GetClientUserId(client), sBuffer, sizeof(sBuffer));
    ReplaceString(output, maxlength, "%u", sBuffer, true);

    // Replace %n with client name
    GetClientName(client, clientName, sizeof(clientName));
    ReplaceString(output, maxlength, "%n", clientName, true);
    if (GetConVarInt(g_hConVarDebug) == 1)    // Debug to console
    {
        PrintToServer("[SM] GenericMenu.smx ReplaceVariables check");
    }
}

//Automatic creation of config file in /tf/addons/sourcemod/configs if dont already have
//Self sufficent debug
public void CreateDefaultMenuConfig()
{
    char configPath[PLATFORM_MAX_PATH];
    char pathsmconfigs[] = "configs/";
    BuildPath(Path_SM, configPath, sizeof(configPath), "%s%s", pathsmconfigs, MENU_CONFIG_TITLE_FILE); // Path to create file in addons/sourcemod/

    if (!FileExists(configPath)) 
    {
        Handle hFile = OpenFile(configPath, "w");
        if (hFile != INVALID_HANDLE)
        {
            WriteFileLine(hFile, "\"%s\"", MENU_CONFIG_TITLE_INTERNAL);
            WriteFileLine(hFile, "{");
            WriteFileLine(hFile, "\t\"1\"");
            WriteFileLine(hFile, "\t{");
            WriteFileLine(hFile, "\t\t\"name\"\t\t\"Test ConsoleAdminSay Username UserID\"");
            WriteFileLine(hFile, "\t\t\"command\"\t\"sm_say Userid of %%n is #%%u\"");
            WriteFileLine(hFile, "\t}");
            WriteFileLine(hFile, "\t\"2\"");
            WriteFileLine(hFile, "\t{");
            WriteFileLine(hFile, "\t\t\"name\"\t\t\"This is the visible menu name\"");
            WriteFileLine(hFile, "\t\t\"command\"\t\"sm_say This is the command executed\"");
            WriteFileLine(hFile, "\t}");
            WriteFileLine(hFile, "}");

            CloseHandle(hFile);
            PrintToServer("[SM] Default config file created."); // Debug to console
        }
        else
        {
            PrintToServer("[SM] Failed to create the config file."); // Debug to console
        }
    }
}
