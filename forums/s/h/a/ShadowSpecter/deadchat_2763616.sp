#include <sourcemod> 

#pragma semicolon 1 
#pragma newdecls required 

public Plugin myinfo =  {
    name = "DeadChat",
    author = "ShadowSpecter",
    description = "Chat to dead players",
    version = "1.0",
    url = ""
};

public void OnPluginStart()
{
    AddCommandListener(OnSay, "say");
    AddCommandListener(OnSay, "say_team");
}

public Action OnSay(int client, const char[] command, int args)
{
    if (!IsPlayerAlive(client))
    {
        char text[4096];
        GetCmdArgString(text, sizeof(text));
        StripQuotes(text);
        if (text[0] != '/')
        {
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsValidClient(i) && !IsPlayerAlive(i))
                {
                    PrintToChat(i, "\x07*DEAD* \x10%N \x0E: %s", client, text);
                }
            }
        }
        return Plugin_Handled;
    }
    return Plugin_Handled;
}

stock bool IsValidClient(int client)
{
    if (client <= 0)
        return false;
    if (client > MaxClients)
        return false;
    if (!IsClientConnected(client))
        return false;
    return IsClientInGame(client);
} 