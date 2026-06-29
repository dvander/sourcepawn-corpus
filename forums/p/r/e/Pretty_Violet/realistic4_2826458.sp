#include <sourcemod>
#include <sdktools>
#include <tf2>

public Plugin:myinfo = 
{
    name = "TF2 Third Person on Spawn",
    author = "YourName",
    description = "Automatically switches to third-person view on spawn for TF2 players, except when sniping.",
    version = "1.0",
    url = ""
};

public OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_changeclass", Event_PlayerChangeClass);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (IsClientInGame(client))
    {
        SetThirdPerson(client, true); // Включаем третий вид при спавне
    }
    return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (IsClientInGame(client))
    {
        SetThirdPerson(client, true); // Включаем третий вид при смерти
    }
    return Plugin_Continue;
}

public Action:Event_PlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (IsClientInGame(client))
    {
        SetThirdPerson(client, true); // Включаем третий вид при смене класса
    }
    return Plugin_Continue;
}

public Action:Event_PlayerRunCmd(Handle:event, const String:name[], bool:dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (IsClientInGame(client) && IsPlayerAlive(client))
    {
        // Проверяем, является ли игрок снайпером
        int playerClass = GetEntProp(client, Prop_Data, "m_iClass"); // Получаем класс игрока

        if (playerClass == 3) // 3 = класс снайпера
        {
            // Получаем состояние кнопок
            int buttons = GetClientButtons(client);

            // Проверяем, вошел ли снайпер в режим прицеливания
            if (buttons & IN_ATTACK2) // Если нажата кнопка прицеливания
            {
                SetThirdPerson(client, false); // Отключаем третий вид
                return Plugin_Continue;
            }
        }

        SetThirdPerson(client, true); // Включаем третий вид в противном случае
    }
    return Plugin_Continue;
}

void SetThirdPerson(int client, bool enable)
{
    if (enable)
    {
        SetEntProp(client, Prop_Data, "m_iObserverMode", 4); // 4 = третье лицо
    }
    else
    {
        SetEntProp(client, Prop_Data, "m_iObserverMode", 0); // 0 = первое лицо
    }
}