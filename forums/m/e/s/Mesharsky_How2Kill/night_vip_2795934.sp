/**
 * The file is a part of Night-VIP.
 *
 * Copyright (C) Mesharsky
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include <sourcemod>
#include <multicolors>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "0.2"

bool g_FreeVip[MAXPLAYERS + 1];
bool g_PlayerNotify;

char g_ChatTag[64];

int g_StartingHour;
int g_EndingHour;
int g_Flag;

float g_NotificationTime;

public Plugin myinfo =
{
    name = "Night VIP",
    author = "Mesharsky",
    description = "Give free VIP flag on specific times",
    version = PLUGIN_VERSION,
    url = "https://github.com/Mesharsky/Night-VIP"
};

public void OnPluginStart()
{
    LoadTranslations("night_vip.phrases.txt");

    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
}

public void OnMapStart()
{
    LoadConfig();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("NV_IsNight", Native_IsNight);
    CreateNative("NV_ClientHasFreeVIP", Native_ClientHasFreeVIP);
    RegPluginLibrary("night_vip");

    return APLRes_Success;
}

public void OnClientPostAdminCheck(int client)
{
    if (IsNight())
    {
        AddFlagsToClient(client, g_Flag);
        g_FreeVip[client] = true;

        if (g_PlayerNotify && !IsFakeClient(client))
            CreateTimer(g_NotificationTime, Timer_PlayerNotify, client);
    }
}

public Action Timer_PlayerNotify(Handle tmr, int client)
{
    if (!IsClientInGame(client))
        return Plugin_Handled;

    CPrintToChat(client, "%s %t", g_ChatTag, "Player Notify");

    return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
    g_FreeVip[client] = false;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (!IsNight())
        return;  

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!g_FreeVip[client] && IsClientInGame(client) && !IsFakeClient(client))
    {
        AddFlagsToClient(client, g_Flag);
        g_FreeVip[client] = true;

        CPrintToChat(client, "%s %t", g_ChatTag, "Player Notify");
    }
}

void LoadConfig()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/night_vip.cfg");

    KeyValues kv = new KeyValues("Night VIP - Configuration");

    if (!kv.ImportFromFile(path))
        SetFailState("Cannot find config file: %s", path);

    if (!kv.JumpToKey("Settings"))
        SetFailState("Missing \"Settings\" section in config file");

    kv.GetString("chat_tag", g_ChatTag, sizeof(g_ChatTag));

    g_StartingHour = kv.GetNum("starting_hour");
    g_EndingHour = kv.GetNum("ending_hour");

    char buffer[32];
    kv.GetString("flag", buffer, sizeof(buffer));

    g_Flag = ReadFlagString(buffer);

    g_PlayerNotify = view_as<bool>(kv.GetNum("player_notify"));
    g_NotificationTime = kv.GetFloat("player_notify_time");

    delete kv;
}

void AddFlagsToClient(int client, int adminFlags)
{
    SetUserFlagBits(client, adminFlags | GetUserFlagBits(client));
}

bool IsNight()
{
    // Clamp the starting and ending hours to the valid range (0 to 23)
    g_StartingHour = clamp(g_StartingHour, 0, 23);
    g_EndingHour = clamp(g_EndingHour, 0, 23);

    if (g_StartingHour == g_EndingHour)
    {
        // The starting and ending hours are the same, return true all the time
        return true;
    }

    char buffer[4];
    FormatTime(buffer, sizeof(buffer), "%H", GetTime());

    int hour = StringToInt(buffer);

    if (g_StartingHour < g_EndingHour)
    {
        // The night time range is within a single day
        if (hour >= g_StartingHour && hour <= g_EndingHour)
            return true;
    }
    else if (g_StartingHour > g_EndingHour)
    {
        // The night time range spans across midnight
        if (hour >= g_StartingHour || hour <= g_EndingHour)
            return true;
    }

    return false;
}

int clamp(int value, int min, int max)
{
    if (value < min)
        return min;
    else if (value > max)
        return max;
    else
        return value;
}

public any Native_IsNight(Handle plugin, int numParams)
{
    return IsNight();
}

public any Native_ClientHasFreeVIP(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if (client < 0 || client >= MaxClients)
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %i", client);

    return g_FreeVip[client];    
}