#include <sourcemod>

public OnMapStart()
{
    ServerCommand("bot_add");
    ServerCommand("bot_kick");
}