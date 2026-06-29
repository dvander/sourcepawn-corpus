#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "R3TROATTACK"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
    name = "jailmates",
    author = PLUGIN_AUTHOR,
    description = "",
    version = PLUGIN_VERSION,
    url = "https://insanitygaming.net/forums"
};

bool g_bFirstSpawn[MAXPLAYERS + 1];
int g_iBuddy[MAXPLAYERS + 1] = {-1, ...};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] err, int len)
{
    RegPluginLibrary("jailmates");
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_buddy", Command_Buddy);
    RegConsoleCmd("sm_unbuddy", Command_UnBuddy);
    LoadTranslations("common.phrases");

    HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for(int i = 1; i <= MaxClients; i++)
        g_bFirstSpawn[i] = true;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(!IsValidClient(client))
        return;
    CreateTimer(0.5, Timer_Delay, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Delay(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if(!IsValidClient(client))
        return;

    if(!g_bFirstSpawn[client])
        return;
    g_bFirstSpawn[client] = false;
    if(g_iBuddy[client] != -1)
    {
        if(GetClientTeam(client) == 3)
        {
            ClearBuddy(client);
            return;
        }
        if(GetClientTeam(g_iBuddy[client]) == 3)
        {
            ClearBuddy(client);
            return;
        }
        PrintToChat(client, " \x10[JailBuddies] \x01Teleporting %N to you", g_iBuddy[client]);
        float pos[3];
        GetClientAbsOrigin(client, pos);
        TeleportEntity(g_iBuddy[client], pos, NULL_VECTOR, NULL_VECTOR);
    }
}

public void OnClientPostAdminCheck(int client)
{
    g_iBuddy[client] = -1;
    g_bFirstSpawn[client] = false;
}

public void OnClientDisconnect(int client)
{
    ClearBuddy(client);
}

public Action Command_UnBuddy(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;
    
    if(g_iBuddy[client] == -1)
        return Plugin_Handled;
    
    PrintToChat(client, " \x10[JailBuddies] \x01You no longer have a cell buddy!");
    ClearBuddy(client);
    return Plugin_Handled;
}

public Action Command_Buddy(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;
    
    if(GetClientTeam(client) == 3)
    {
        ReplyToCommand(client, " \x10[JailBuddies] \x01You guards cannot use this command");
        return Plugin_Handled;
    }
    
    if(args < 1)
    {
        ReplyToCommand(client, "[SM] sm_buddy <name>");
        return Plugin_Handled;
    }

    char arg[MAX_TARGET_LENGTH];
    GetCmdArg(1, arg, sizeof(arg));
    int target = FindTarget(client, arg, true, false);
    if(target == -1 || !IsValidClient(target))
        return Plugin_Handled;
    
    if(GetClientTeam(target) == 3)
    {
        ReplyToCommand(client, " \x10[JailBuddies] \x01You cannot be buddies with a guard");
        return Plugin_Handled;
    }
    
    PrintToChat(client, " \x10[JailBuddies] \x01Asking %N to be your cell buddy.", target);
    AskToBuddy(client, target);
    return Plugin_Handled;
}

void AskToBuddy(int asker, int client)
{
    Menu menu = new Menu(MenuHandled_BuddyMenu);
    char info[16];
    Format(info, sizeof(info), "%d",GetClientUserId(asker));
    menu.SetTitle("Do you want to become jail buddies with %N", asker);
    menu.AddItem(info, "Yes");
    menu.AddItem(info, "No");

    menu.ExitBackButton = false;
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandled_BuddyMenu(Menu menu, MenuAction action, int client, int choice)
{
    if(action == MenuAction_Select)
    {
        char info[16];
        menu.GetItem(choice, info, sizeof(info));
        int asker = GetClientOfUserId(StringToInt(info));
        if(!IsValidClient(asker))
            return;
        if(choice == 0)
        {
            ClearBuddy(asker);
            ClearBuddy(client);
            g_iBuddy[client] = asker;
            g_iBuddy[asker] = client;
            PrintToChat(client, " \x10[JailBuddies] \x01You and \x04%N\x01 have become cell buddies!", asker);
            PrintToChat(asker, " \x10[JailBuddies] \x01You and \x04%N\x01 have become cell buddies!", client);
        }
        else
        {
            PrintToChat(asker, " \x10[JailBuddies] \x01%N has declined your buddie request!", client);
        }
    }
    else if(action == MenuAction_End)
        delete menu;
}

void ClearBuddy(int client)
{
    if(g_iBuddy[client] == -1)
        return;
    g_iBuddy[g_iBuddy[client]] = -1;
    g_iBuddy[client] = -1;
}

stock bool IsValidClient(int client)
{
	return (
		0 < client <= MaxClients && IsValidEntity(client) && IsClientInGame(client) && 
		IsClientConnected(client) && !IsClientSourceTV(client)
	);
}
