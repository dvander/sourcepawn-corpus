#include <cstrike>

new Handle:g_hTimers[MAXPLAYERS+1];

public OnPluginStart()
{
    //HookUserMessage(GetUserMessageId("VGUIMenu"), VGUIMenu, true);
    HookEventEx("player_connect_full", player_activate);
    AddCommandListener(joingame, "joingame");
}

public Action:joingame(client, const String:command[], argc)
{
    //PrintToServer("%s", command);
    if(g_hTimers[client] != INVALID_HANDLE)
    {
        KillTimer(g_hTimers[client]);
        g_hTimers[client] = INVALID_HANDLE;
    }
}

public player_activate(Handle:event, const String:name[], bool:dontBroadcast)
{
    //PrintToServer("player_activate = %s", name);
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    g_hTimers[client] = CreateTimer(0.1, clearmotd, client, TIMER_REPEAT);
}

public Action:clearmotd(Handle:timer, any:client)
{
    //PrintToServer("clearmotd %i", client);

    if(client == 0 || !IsClientInGame(client) || IsFakeClient(client))
    {
        g_hTimers[client] = INVALID_HANDLE;
        return Plugin_Stop;
    }

    new Handle:pb = StartMessageOne("VGUIMenu", client);
    PbSetString(pb, "name", "info");
    PbSetBool(pb, "show", false);

    new Handle:subkey;

    subkey = PbAddMessage(pb, "subkeys");
    PbSetString(subkey, "name", "title");
    PbSetString(subkey, "str", "");

    subkey = PbAddMessage(pb, "subkeys");
    PbSetString(subkey, "name", "type");
    PbSetString(subkey, "str", "0");

    subkey = PbAddMessage(pb, "subkeys");
    PbSetString(subkey, "name", "msg");
    PbSetString(subkey, "str", "");

    subkey = PbAddMessage(pb, "subkeys");
    PbSetString(subkey, "name", "cmd");
    PbSetString(subkey, "str", "1");
    EndMessage();

    return Plugin_Continue;

}