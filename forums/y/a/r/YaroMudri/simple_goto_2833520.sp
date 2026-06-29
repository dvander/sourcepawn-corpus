#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = {
    name = "Goto Command",
    author = "Your Name",
    description = "Allows players to teleport to other players using the !goto command.",
    version = PLUGIN_VERSION,
    url = "https://example.com"
};

// ConVars
ConVar g_cvFreeForAll;
ConVar g_cvAdminOnly;
ConVar g_cvOnlyTeam;

// Plugin initialization
public void OnPluginStart() {
    // Create ConVars with admin-only flags
    g_cvFreeForAll = CreateConVar("sm_goto_free_for_all", "0", "Enable (1) or disable (0) access to the !goto command for all players. Default: 0", FCVAR_PROTECTED | FCVAR_GAMEDLL, true, 0.0, true, 1.0);
    g_cvAdminOnly = CreateConVar("sm_goto_admin_only", "0", "Restrict !goto command to admins only (1) or allow all players (0). Default: 0", FCVAR_PROTECTED | FCVAR_GAMEDLL, true, 0.0, true, 1.0);
    g_cvOnlyTeam = CreateConVar("sm_goto_only_team", "1", "Show only teammates (1) or all players (0) in the !goto menu. Default: 1", FCVAR_PROTECTED | FCVAR_GAMEDLL, true, 0.0, true, 1.0);

    // Register the chat command
    RegConsoleCmd("sm_goto", Command_Goto, "Teleport to another player.");

    // Load translations (optional)
    LoadTranslations("common.phrases");
}

// Command handler for !goto
public Action Command_Goto(int client, int args) {
    // Check if the command is enabled for all players or admins only
    if (g_cvAdminOnly.BoolValue && !CheckCommandAccess(client, "sm_goto_admin_only", ADMFLAG_GENERIC)) {
        ReplyToCommand(client, "[SM] You do not have access to this command.");
        return Plugin_Handled;
    }

    if (!g_cvFreeForAll.BoolValue && !CheckCommandAccess(client, "sm_goto_free_for_all", ADMFLAG_GENERIC)) {
        ReplyToCommand(client, "[SM] This command is disabled for players.");
        return Plugin_Handled;
    }

    // Display the player menu
    ShowPlayerMenu(client);
    return Plugin_Handled;
}

// Show a menu of players to teleport to
void ShowPlayerMenu(int client) {
    Menu menu = new Menu(MenuHandler_SelectPlayer);
    menu.SetTitle("Select a player to teleport to:");

    char playerName[MAX_NAME_LENGTH];
    char playerInfo[12];
    int team = GetClientTeam(client);
    bool onlyTeam = g_cvOnlyTeam.BoolValue;

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && IsPlayerAlive(i) && i != client) {
            if (onlyTeam && GetClientTeam(i) != team) {
                continue; // Skip players not on the same team
            }

            GetClientName(i, playerName, sizeof(playerName));
            IntToString(i, playerInfo, sizeof(playerInfo));
            menu.AddItem(playerInfo, playerName);
        }
    }

    if (menu.ItemCount == 0) {
        menu.AddItem("", "No players available.", ITEMDRAW_DISABLED);
    }

    menu.Display(client, MENU_TIME_FOREVER);
}

// Menu handler for selecting a player
public int MenuHandler_SelectPlayer(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[12];
        menu.GetItem(param2, info, sizeof(info));
        int target = StringToInt(info);

        if (IsClientInGame(target) && IsPlayerAlive(target)) {
            TeleportToPlayer(client, target);
            PrintToChat(client, "[SM] You have been teleported to %N.", target);
        } else {
            PrintToChat(client, "[SM] The selected player is no longer available.");
        }
    } else if (action == MenuAction_End) {
        delete menu;
    }

    return 0; // Return 0 to indicate the menu action was handled
}

// Teleport the client to the target player
void TeleportToPlayer(int client, int target) {
    float targetPos[3];
    GetClientAbsOrigin(target, targetPos);

    // Adjust Z position to avoid clipping into the ground
    targetPos[2] += 10.0;

    TeleportEntity(client, targetPos, NULL_VECTOR, NULL_VECTOR);
}