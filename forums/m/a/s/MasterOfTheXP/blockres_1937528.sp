new bool:UsedCommand[MAXPLAYERS + 1];

public OnPluginStart()
{
    AddCommandListener(Listener_res, "sm_res");
    AddCommandListener(Listener_res, "sm_resurrect");
    
    HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Post);
}

public OnClientDisconnect(client)
    UsedCommand[client] = true; // Prevent rejoin->respawn

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i = 1; i <= MaxClients; i++)
        UsedCommand[i] = false;
}

// Option 1
public Action:Listener_res(client, const String:command[], args)
{
    if (!client) return Plugin_Continue;
    if (IsPlayerAlive(client)) return Plugin_Continue;
    if (2 > GetClientTeam(client)) return Plugin_Continue;
    if (UsedCommand[client])
    {
        ReplyToCommand(client, "You can only use this command once per round.");
        return Plugin_Handled;
    }
    UsedCommand = true;
    return Plugin_Continue;
}

// Option 2
/*public Action:OnClientCommand(client, args)
{
    if (!client) return Plugin_Continue;
    if (IsPlayerAlive(client)) return Plugin_Continue;
    if (2 > GetClientTeam(client)) return Plugin_Continue;
    new String:arg0[13];
    GetCmdArg(0, arg0, sizeof(arg0));
    if (!StrEqual(arg0, "sm_res") &&
    !StrEqual(arg0, "sm_resurrect")) return Plugin_Continue;
    if (UsedCommand[client])
    {
        ReplyToCommand(client, "You can only use this command once per round.");
        return Plugin_Handled;
    }
    UsedCommand = true;
    return Plugin_Continue;
}*/  