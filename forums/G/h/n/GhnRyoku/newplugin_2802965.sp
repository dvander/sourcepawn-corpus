#include <sourcemod>

public void OnPluginStart()
{
    // Register the command to reward players
    RegConsoleCmd("reward", Cmd_Reward);
    
    // Create a timer to reward players every minute
    CreateTimer(60.0, Timer_Reward, _, TIMER_REPEAT);
}

public Action Cmd_Reward(int client, const char[] args)
{
    // Get the client's SteamID
    new steamid[20];
    GetClientAuthId(client, steamid, sizeof(steamid));
    
    // Reward the client with 100 points
    RewardPlayer(steamid, 100);
    
    return Plugin_Handled;
}

public Action Timer_Reward(Handle timer)
{
    // Loop through all connected clients
    for (int i = 1; i <= MaxClients; i++)
    {
        // Check if the client is connected
        if (IsClientInGame(i))
        {
            // Get the client's SteamID
            new steamid[20];
            GetClientAuthId(i, steamid, sizeof(steamid));
            
            // Reward the client with 10 points
            RewardPlayer(steamid, 10);
        }
    }
    
    return Plugin_Continue;
}

public void RewardPlayer(const char[] steamid, int points)
{
    // Open a connection to the MySQL database
    new database = SQL_Connect("localhost", "username", "password", "database");
    
    // Check if the connection was successful
    if (SQL_IsError(database))
    {
        LogError("Failed to connect to database: %s", SQL_GetLastError());
        return;
    }
    
    // Create the query string
    new query[256];
    Format(query, sizeof(query), "INSERT INTO rewards (steamid, points) VALUES ('%s', %d)", steamid, points);
    
    // Execute the query
    new result = SQL_Query(database, query);
    
    // Check if the query was successful
    if (SQL_IsError(result))
    {
        LogError("Failed to execute query: %s", SQL_GetLastError());
    }
    
    // Free the query result
    SQL_FreeResult(result);
    
    // Close the database connection
    SQL_Disconnect(database);
}
