#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.01"
#define SM "\x04[SM]\x01"

public Plugin:myinfo =
{
    name = "Noblock Trigger",
    author = "Heartless",
    description = "Allows players to enable noblock on everyone in the server for x seconds",
    version = PLUGIN_VERSION,
    url = "http://www.badnetwork.net/"
};

new g_CollisionOffset;
new TimerActive;
new Handle:sm_noblock_time = INVALID_HANDLE;
new Handle:sm_block_time = INVALID_HANDLE;
new g_iLastTime[MAXPLAYERS + 1];
new spam;

public OnPluginStart()
{
    RegConsoleCmd("sm_noblock", Command_NoBlock);
    g_CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
    sm_noblock_time = CreateConVar("sm_noblock_time", "10", "Sets the noblock timer value");
    sm_block_time = CreateConVar("sm_block_time", "5", "Sets the spam block timer value");
    AutoExecConfig(true, "sm_noblock");
}

public Action:Command_NoBlock(client, args)
{
    if (IsClientInGame(client) && IsPlayerAlive(client) && TimerActive == 0 && spam == 0)
    {
        if(GetTime() < g_iLastTime[client]) return Plugin_Handled; // i put it here so u still can have auto noblock
        
	new Float:Time;
        Time = GetConVarFloat(sm_noblock_time);
        PrintToChatAll("%s Noblock enabled for %f seconds", SM, Time);    
        TimerActive = 1;
	spam = 1;
        CreateTimer(Time, Timer_UnBlockPlayer, client);
                
        // enable noblock on every client in the server
        for (new i = 1; i <= MaxClients; i++)
        {    
            if (IsClientInGame(i) && IsPlayerAlive(i))
            {
                EnableNoBlock(i);
            }
        }
    }
    else if (TimerActive == 1)
    {
        PrintToChat(client, "%s Command is already in use", SM);
    }
    else if (spam == 1)
    {
	new Float:spam2;
	spam2 = GetConVarFloat(sm_block_time);
	PrintToChat(client, "%s Please wait %f seconds", SM, spam2);
    }
    else
    {
        PrintToChat(client, "%s You must be alive to use this command", SM);
    }
        
    return Plugin_Handled;
    
}

public Action:Timer_UnBlockPlayer(Handle:timer, any:client)
{
    TimerActive = 0;
    PrintToChatAll("%s Noblock disabled", SM);
    
    // enable block on every client in the server
    for (new i = 1; i <= MaxClients; i++)
    {    
        if (IsClientInGame(i) && IsPlayerAlive(i))
        {
            EnableBlock(i);
        }
	new Float:spam2;
	spam2 = GetConVarFloat(sm_block_time);
	CreateTimer(spam2, spamblock, client);
    }
    
    return Plugin_Continue;
    
}

public Action:spamblock(Handle:timer, any:client)
{
    spam = 0;
    return Plugin_Continue;
    
}

EnableBlock(client)
{
    // CAN NOT PASS THRU ie: Players can jump on each other
    SetEntData(client, g_CollisionOffset, 5, 4, true);
    
}

EnableNoBlock(client)
{
    // Noblock active ie: Players can walk thru each other
    SetEntData(client, g_CollisionOffset, 2, 4, true);
    g_iLastTime[client] = GetTime() + 10;
    
}