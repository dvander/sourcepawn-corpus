#include <sourcemod>
#include <clientprefs>
#include <menus>
#include <clients>  // For IsFakeClient

#define MAX_PLAYERS 64

// Global variables
bool g_bGnomGiven[MAX_PLAYERS + 1];

public void OnPluginStart()
{
    RegConsoleCmd("sm_prikol", Command_Prikol); // Register !prikol command
    // Timer to check the gnome limit at the start of every round
    CreateTimer(1.0, Timer_CheckRoundLimit, null, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

// Call the !prikol command
public Action Command_Prikol(int client, int args)
{
    if (!IsClientInGame(client))
        return Plugin_Stop;

    // Get the list of players
    int players[MAX_PLAYERS];
    int count = 0;
    for (int i = 1; i <= MAX_PLAYERS; i++)
    {
        if (IsClientInGame(i))
        {
            players[count] = i;
            count++;
        }
    }

    // Open the player menu
    OpenPlayerMenu(client, players, count);

    return Plugin_Continue;
}

// Create the menu and add players to it
public void OpenPlayerMenu(int client, int players[MAX_PLAYERS], int count)
{
    // Create the menu
    Menu menu = CreateMenu(MenuHandler);

    // Add each player to the menu
    for (int i = 0; i < count; i++)
    {
        char playerName[64];
        GetClientName(players[i], playerName, sizeof(playerName));

        // Check if the player is a bot and show as bot in the menu
        if (IsFakeClient(players[i]))
        {
            Format(playerName, sizeof(playerName), "%s (Bot)", playerName);
        }

        // Add menu item
        AddMenuItem(menu, IntToString(players[i]), playerName);
    }

    SetMenuTitle(menu, "Player List");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

// Give the selected player a gnome
public int MenuHandler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char itemData[16];
        GetMenuItem(menu, item, itemData, sizeof(itemData));
        int selectedPlayer = StringToInt(itemData);

        // Give gnome to the selected player
        if (IsClientInGame(selectedPlayer) && !g_bGnomGiven[selectedPlayer])
        {
            GiveGnome(selectedPlayer);
        }
    }

    return 0;
}

// Give the player a gnome
public void GiveGnome(int client)
{
    // Process for giving a gnome to the player
    // For example, giving a specific item or status called "gnome"
    PrintToChatAll("Player %N received the gnome!", client);

    // Mark the player as having received a gnome
    g_bGnomGiven[client] = true;
}

// Check the round limit, ensure only one gnome is given per round
public void Timer_CheckRoundLimit(Handle timer)
{
    // Check the gnome status for each player
    for (int i = 1; i <= MAX_PLAYERS; i++)
    {
        if (IsClientInGame(i))
        {
            // Reset the gnome status for each player at the start of the round
            g_bGnomGiven[i] = false;
        }
    }
}
