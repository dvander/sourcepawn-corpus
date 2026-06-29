#include <sourcemod>

public void OnPluginStart()
{
    HookEvent("create_panic_event", Event_Panic);
}

void Event_Panic(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client && IsClientInGame(client))
    {
        PrintToChatAll( "\x03[Panic Event]\x01 %N started the panic event!", client);
    }
    else
    {
        PrintToChatAll( "\x03[Panic Event]\x01 Panic event has been started!");
    }
}

