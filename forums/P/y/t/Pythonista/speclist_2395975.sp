#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Xpktro"
#define PLUGIN_VERSION "0.1"

#include <sourcemod>
#include <tf2>
#include <smlib>

int client_list[MAXPLAYERS];

public Plugin myinfo = 
{
    name = "[TF2] Spectator List", 
    author = PLUGIN_AUTHOR, 
    description = "A plugin show a simple ingame spectator list.", 
    version = PLUGIN_VERSION, 
    url = ""
};

public void OnPluginStart()
{
    PrintToServer("Using spectator list plugin version %s by %s.", PLUGIN_VERSION, PLUGIN_AUTHOR);
    AddMultiTargetFilter("@spec", ProcessSpecs, "Spectators", false);
    RegConsoleCmd("sl", CmdHandler);
    AddCommandListener(PlayerJoiningTeam, "jointeam");
    LoadTranslations("common.phrases");
    CreateTimer(5.0, DrawTimer, _, TIMER_REPEAT);
}

public bool ProcessSpecs(const char[] pattern, Handle clients)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && TFTeam:GetClientTeam(i) == TFTeam_Spectator && !IsClientSourceTV(i) && !IsClientReplay(i))
            PushArrayCell(clients, i);
    }
    return true;
}

public Action PlayerJoiningTeam(int client, const char[] command, int args)
{
    if (IsClientInGame(client) && args >= 1)
    {
        DrawList();
    }
    return Plugin_Continue;
}

public Action CmdHandler(int client, int args)
{
    if (client_list[client] == 0)
    {
        client_list[client] = 1;
    }
    else
    {
        client_list[client] = 0;
    }
    DrawList();
}

void DrawList()
{
    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;
    
    target_count = ProcessTargetString("@spec", 0, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, MAX_TARGET_LENGTH, tn_is_ml);
    
    if (target_count < 0)
    {
        target_count = 0;
    }
    
    char player_list[MAXPLAYERS * MAX_NAME_LENGTH + 12 + MAXPLAYERS + (MAXPLAYERS * 4)];
    Format(player_list, sizeof(player_list), "Spectators: %i\n", target_count);
    
    int counter = 1;
    
    for (int i = 0; i <= target_count; i++)
    {
        if (target_list[i] != 0)
        {
            char client_name[MAX_NAME_LENGTH];
            
            char index_str[3];
            IntToString(counter, index_str, 3);
            
            GetClientName(target_list[i], client_name, MAX_NAME_LENGTH);
            StrCat(player_list, sizeof(player_list), index_str);
            StrCat(player_list, sizeof(player_list), ". ");
            StrCat(player_list, sizeof(player_list), client_name);
            StrCat(player_list, sizeof(player_list), "\n");
            counter++;
        }
    }
    
    for (int client = 0; client < MaxClients; client++)
    {
        if (client_list[client] == 1 && IsClientInGame(client))
        {
            Client_PrintKeyHintText(client, "%s", player_list);
        }
        else if (client != 0 && IsClientInGame(client))
        {
            Client_PrintKeyHintText(client, "");
        }
        
    }
} 

public Action DrawTimer(Handle timer)
{
    DrawList();
    return Plugin_Continue;
}