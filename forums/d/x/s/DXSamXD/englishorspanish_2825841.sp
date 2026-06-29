#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
    name = "English or Spanish",
    author = "DXSamXD",
    description = "Freezes survivor players for a few seconds as the song plays. This plugin is best used for interactive streams. (English or Spanish?)",
    version = "1.0",
    url = ""
};

bool g_bFreezeActive = false;
Handle g_hFreezeTimer = INVALID_HANDLE;

public void OnPluginStart()
{
    RegAdminCmd("sm_eos", Command_FreezeAll, ADMFLAG_GENERIC, "ENGLISH OR SPANISH?");

    // Add the custom sound file to the download table
    AddFileToDownloadsTable("sound/custom/eos.mp3");

    // Precache the sound file
    PrecacheSound("custom/eos.mp3", true);
}

public void OnMapStart()
{
    // Add the custom sound file to the download table
    AddFileToDownloadsTable("sound/custom/eos.mp3");
    
    // Precache the sound file again to ensure it's available
    PrecacheSound("custom/eos.mp3", true);
}

public Action Command_FreezeAll(int client, int args)
{
    // Activate freeze effect
    g_bFreezeActive = true;

    // Schedule the chat conversation to start after 0.1 second
    CreateTimer(0.1, Timer_StartConversation);

    // Freeze players at the 4-second mark
    CreateTimer(4.16, Timer_FreezePlayers);

    // Create a timer to unfreeze players after 12.76 seconds
    CreateTimer(12.76, Timer_UnfreezeAll);

    // Play the custom sound for all clients
    PlaySoundForAll("custom/eos.mp3");

    return Plugin_Handled;
}

void PlaySoundForAll(const char[] soundFile)
{
    // Ensure the sound file is precached
    PrecacheSound(soundFile, true);

    // Emit the sound for all valid clients
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            // Play the sound to the client
            EmitSoundToClient(i, soundFile);
        }
    }
}

public Action Timer_StartConversation(Handle timer)
{
    // Send the chat messages with fixed delays
    CreateTimer(0.0, Timer_PrintMessage1); // "Excuse me, English or Spanish?"
    CreateTimer(2.2, Timer_PrintMessage2); // "English"
    CreateTimer(3.0, Timer_PrintMessage3); // "Whoever moves first is gay"

    return Plugin_Handled;
}

public Action Timer_PrintMessage1(Handle timer)
{
    PrintToChatAll("Excuse me, English or Spanish?");
    return Plugin_Handled;
}

public Action Timer_PrintMessage2(Handle timer)
{
    PrintToChatAll("English");
    return Plugin_Handled;
}

public Action Timer_PrintMessage3(Handle timer)
{
    PrintToChatAll("Whoever moves first is gay");
    return Plugin_Handled;
}

public Action Timer_FreezePlayers(Handle timer)
{
    // Freeze players
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && CheckPlayerAlive(i) && IsPlayerSurvivor(i))
        {
            FreezePlayer(i, true);
        }
    }
    
    // Continue applying freeze periodically to handle idle bypass
    if (g_bFreezeActive)
    {
        g_hFreezeTimer = CreateTimer(0.067, Timer_FreezePlayers); // Reapply freeze every 0.067 seconds
    }

    return Plugin_Handled;
}

public Action Timer_UnfreezeAll(Handle timer)
{
    // Unfreeze all players
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && CheckPlayerAlive(i) && IsPlayerSurvivor(i))
        {
            FreezePlayer(i, false);
        }
    }

    // Deactivate freeze effect
    g_bFreezeActive = false;

    // Close the freeze timer handle
    if (g_hFreezeTimer != INVALID_HANDLE)
    {
        CloseHandle(g_hFreezeTimer);
        g_hFreezeTimer = INVALID_HANDLE;
    }

    return Plugin_Handled;
}

bool IsPlayerSurvivor(int client)
{
    int team = GetClientTeam(client);
    return team == 2; // Team 2 is Survivors
}

bool CheckPlayerAlive(int client)
{
    return (GetClientHealth(client) > 0);
}

void FreezePlayer(int client, bool freeze)
{
    if (freeze)
    {
        SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags") | FL_FROZEN); // Stops player actions
        SetEntProp(client, Prop_Data, "m_nButtons", 0); // Disable all player input
    }
    else
    {
        SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags") & ~FL_FROZEN); // Restores player actions
        SetEntProp(client, Prop_Data, "m_nButtons", -1); // Enable all player input
    }
}

public void OnClientPutInServer(int client)
{
    // Ensure the player is frozen if they join during an active freeze period
    if (g_bFreezeActive && IsPlayerSurvivor(client) && CheckPlayerAlive(client))
    {
        FreezePlayer(client, true);
    }
}

public void OnClientDisconnect(int client)
{
    // Ensure the player is unfrozen if they disconnect during an active freeze period
    if (g_bFreezeActive && IsPlayerSurvivor(client) && CheckPlayerAlive(client))
    {
        FreezePlayer(client, false);
    }
}