#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.0"

ConVar g_cvNotify;

public Plugin myinfo = 
{
    name = "[Any] Teleport Bring/Goto Commands",
    author = "Unreal1",
    description = "Teleportation bring/goto commands with menu and collision support",
    version = PLUGIN_VERSION,
    url = "http://davidivashenko.com"
};

public void OnPluginStart()
{
    LoadTranslations("common.phrases");

    CreateConVar("sm_teleportbringgoto_version", PLUGIN_VERSION, "SM Teleport Bring/Goto", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_cvNotify = CreateConVar("sm_teleport_notify", "1", "Notification mode (0: Disabled, 1: Private, 2: Public)", _, true, 0.0, true, 2.0);
    
    RegAdminCmd("sm_goto", Command_Goto, ADMFLAG_SLAY, "Teleport to a player");
    RegAdminCmd("sm_bring", Command_Bring, ADMFLAG_SLAY, "Bring a player to you");
    RegAdminCmd("sm_teleport", Command_TeleportMenu, ADMFLAG_SLAY, "Teleport menu");
}

public Action Command_Goto(int client, int args)
{
    if (!ValidateCommand(client, args, false)) return Plugin_Handled;
    
    char targetName[MAX_TARGET_LENGTH];
    int target = FindTarget(client, targetName, sizeof(targetName), COMMAND_FILTER_ALIVE);
    if (target == -1) return Plugin_Handled;
    
    PerformTeleport(client, target);
    NotifyTeleport(client, target, false);
    return Plugin_Handled;
}

public Action Command_Bring(int client, int args)
{
    if (!ValidateCommand(client, args, true)) return Plugin_Handled;
    
    char pattern[64];
    GetCmdArg(1, pattern, sizeof(pattern));
    
    int targets[MAXPLAYERS];
    int targetCount = ProcessTargets(client, pattern, targets, sizeof(targets));
    if (targetCount == 0) return Plugin_Handled;
    
    for (int i = 0; i < targetCount; i++)
    {
        PerformTeleport(targets[i], client);
        NotifyTeleport(client, targets[i], true);
    }
    return Plugin_Handled;
}

void PerformTeleport(int subject, int destination)
{
    float pos[3];
    if (subject == destination) return;
    
    if (destination == 0) // Bring to looking position
    {
        GetCollisionPoint(subject, pos);
    }
    else // Goto player position
    {
        GetClientAbsOrigin(destination, pos);
    }
    
    TeleportEntity(subject, pos, NULL_VECTOR, NULL_VECTOR);
    AdjustCollision(subject, pos);
}

void AdjustCollision(int client, const float pos[3])
{
    TR_TraceHullFilter(pos, pos, view_as<float>({-16.0, -16.0, 0.0}), view_as<float>({16.0, 16.0, 72.0}), 
        MASK_PLAYERSOLID, TraceEntityFilterPlayer, client);
    
    if (TR_DidHit())
    {
        SetEntProp(client, Prop_Send, "m_bDucked", 1);
        SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);
    }
}

public bool TraceEntityFilterPlayer(int entity, int mask, any data)
{
    return entity != data;
}

void GetCollisionPoint(int client, float pos[3])
{
    float eyePos[3], eyeAng[3];
    GetClientEyePosition(client, eyePos);
    GetClientEyeAngles(client, eyeAng);
    
    Handle trace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SOLID, RayType_Infinite, TraceFilterPlayers);
    if (TR_DidHit(trace))
    {
        TR_GetEndPosition(pos, trace);
        pos[2] += 2.0; // Prevent getting stuck in ground
    }
    delete trace;
}

public bool TraceFilterPlayers(int entity, int mask)
{
    return entity > MaxClients;
}

void NotifyTeleport(int admin, int target, bool bring)
{
    char adminName[MAX_NAME_LENGTH], targetName[MAX_NAME_LENGTH];
    GetClientName(admin, adminName, sizeof(adminName));
    GetClientName(target, targetName, sizeof(targetName));
    
    switch (g_cvNotify.IntValue)
    {
        case 1:
        {
            PrintToChat(admin, "[SM] %s %s to you", bring ? "Brought" : "Teleported", targetName);
            PrintToChat(target, "[SM] You were %s by %s", bring ? "brought" : "teleported to", adminName);
        }
        case 2:
        {
            PrintToChatAll("[SM] %s %s %s %s", adminName, bring ? "brought" : "teleported to", bring ? targetName : adminName, bring ? "to them" : "");
        }
    }
}

public Action Command_TeleportMenu(int client, int args)
{
    if (!client) return Plugin_Handled;
    
    Menu menu = new Menu(MenuHandler_Main);
    menu.SetTitle("Teleport Menu");
    menu.AddItem("bring", "Bring Player");
    menu.AddItem("goto", "Go To Player");
    menu.Display(client, 20);
    return Plugin_Handled;
}

public int MenuHandler_Main(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char info[16];
        menu.GetItem(param, info, sizeof(info));
        ShowPlayerMenu(client, StrEqual(info, "bring"));
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

void ShowPlayerMenu(int client, bool bring)
{
    Menu menu = new Menu(bring ? MenuHandler_Bring : MenuHandler_Goto);
    menu.SetTitle(bring ? "Select Player to Bring" : "Select Player to Teleport To");
    
    char userid[12], name[MAX_NAME_LENGTH], display[MAX_NAME_LENGTH + 16];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && (bring || IsPlayerAlive(i)))
        {
            IntToString(GetClientUserId(i), userid, sizeof(userid));
            GetClientName(i, name, sizeof(name));
            Format(display, sizeof(display), "%s%s", name, IsPlayerAlive(i) ? "" : " (DEAD)");
            menu.AddItem(userid, display);
        }
    }
    
    menu.ExitBackButton = true;
    menu.Display(client, 20);
}

public int MenuHandler_Bring(Menu menu, MenuAction action, int client, int param)
{
    return HandlePlayerMenu(menu, action, client, param, true);
}

public int MenuHandler_Goto(Menu menu, MenuAction action, int client, int param)
{
    return HandlePlayerMenu(menu, action, client, param, false);
}

int HandlePlayerMenu(Menu menu, MenuAction action, int client, int param, bool bring)
{
    if (action == MenuAction_Select)
    {
        char userid[12];
        menu.GetItem(param, userid, sizeof(userid));
        int target = GetClientOfUserId(StringToInt(userid));
        
        if (IsValidTarget(client, target, bring))
        {
            if (bring) PerformTeleport(target, 0);
            else PerformTeleport(client, target);
            NotifyTeleport(client, target, bring);
        }
        ShowPlayerMenu(client, bring);
    }
    else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
    {
        Command_TeleportMenu(client, 0);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

bool ValidateCommand(int client, int args, bool requireAlive)
{
    if (!client)
    {
        ReplyToCommand(client, "[SM] This command can only be used in-game");
        return false;
    }
    
    if (requireAlive && !IsPlayerAlive(client))
    {
        ReplyToCommand(client, "[SM] You must be alive to use this command");
        return false;
    }
    
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: %s <target>", requireAlive ? "sm_bring" : "sm_goto");
        return false;
    }
    return true;
}

int ProcessTargets(int client, const char[] pattern, int[] targets, int maxTargets)
{
    char targetName[MAX_TARGET_LENGTH];
    bool tnIsML;
    
    int targetCount = ProcessTargetString(
        pattern,
        client,
        targets,
        maxTargets,
        COMMAND_FILTER_ALIVE,
        targetName,
        sizeof(targetName),
        tnIsML);
    
    if (targetCount <= 0)
    {
        ReplyToCommand(client, "[SM] No matching player found");
    }
    return targetCount;
}

bool IsValidTarget(int client, int target, bool bring)
{
    if (!target || !IsClientInGame(target))
    {
        ReplyToCommand(client, "[SM] Player no longer available");
        return false;
    }
    
    if (bring && !IsPlayerAlive(target))
    {
        ReplyToCommand(client, "[SM] Target must be alive");
        return false;
    }
    
    if (target == client)
    {
        ReplyToCommand(client, "[SM] You cannot target yourself");
        return false;
    }
    return true;
}