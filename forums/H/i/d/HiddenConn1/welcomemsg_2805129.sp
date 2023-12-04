#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "Player Welcome Message",
	author = "NSanityHD (Kyle F)",
	description = "Automatically welcomes players upon joining the server.",
	version = "1.0",
}

public OnPluginStart()
{
	// Welcome messages
const char[][] welcomeMessages =
{
    "[SERVER] Welcome to our server!",
    "Welcome! If you have any issues, contact a server administrator.",
    "Welcome #3",
    "Welcome #4",
    "Welcome #5"
};

// Called when a player connects to the server
public Action OnClientConnected(int client)
{
    // Random welcome message
    int randomIndex = RandomInt(0, sizeof(welcomeMessages) / sizeof(welcomeMessages[0]) - 1);
    const char[] message = welcomeMessages[randomIndex];

    // Display the welcome message to the connecting player
    ShowMessage(client, message);

    return Plugin_Continue;
}

// Plugin initialization
public void PluginInit()
{
    // Hook the client connection event
    HookEvent("player_connect", OnClientConnected);
}

// Plugin shutdown
public void PluginExit()
{
    // Unhook the client connection event
    UnhookEvent("player_connect", OnClientConnected);
}

// Plugin start point
public void OnPluginStart()
{
    // Initialize the plugin
    PluginInit();
}

// Plugin end point
public void OnPluginEnd()
{
    // Clean up the plugin
    PluginExit();
}

}