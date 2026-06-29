#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.0"
#define PRECIPITATION_TYPE_SNOW 3

public Plugin myinfo = 
{
    name = "Snowfall: Source",
    author = "YOUR NAME",
    description = "Creates Snowfall on all maps",
    version = PLUGIN_VERSION,
    url = "YOUR SITE"
};

ConVar g_cvSnowfallEnabled;
int g_iSnowEntity = -1;

public void OnPluginStart()
{
    CreateConVar("snowfall_version", PLUGIN_VERSION, "Snowfall version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
    g_cvSnowfallEnabled = CreateConVar("sm_snow_enabled", "0", "Enable or Disable Snowfall on the map (1 = Enable, 0 = Disable)", FCVAR_NONE, true, 0.0, true, 1.0);
    RegAdminCmd("sm_snow", Command_Snow, ADMFLAG_GENERIC, "Enable or Disable Snowfall on the map: sm_snow <1/0>");
    HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public Action Command_Snow(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_snow <1/0> - 1 to Enable, 0 to Disable Snowfall.");
        return Plugin_Handled;
    }

    char arg[4];
    GetCmdArg(1, arg, sizeof(arg));
    int value = StringToInt(arg);

    if (value != 0 && value != 1)
    {
        ReplyToCommand(client, "[SM] Invalid value. Use 1 to Enable or 0 to Disable Snowfall.");
        return Plugin_Handled;
    }

    g_cvSnowfallEnabled.SetInt(value, true, true);

    if (value == 1)
    {
        CreateSnowfall();
        ReplyToCommand(client, "[SM] Snowfall Enabled.");
    }
    else
    {
        RemoveSnowfall();
        ReplyToCommand(client, "[SM] Snowfall Disabled.");
    }

    return Plugin_Handled;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvSnowfallEnabled.BoolValue)
    {
        CreateSnowfall();
    }
}

void CreateSnowfall()
{
    if (g_iSnowEntity != -1 && IsValidEntity(g_iSnowEntity))
    {
        return; // Snowfall already exists
    }

    g_iSnowEntity = CreateEntityByName("func_precipitation");
    if (IsValidEntity(g_iSnowEntity))
    {
        char mapName[128];
        GetCurrentMap(mapName, sizeof(mapName));
        Format(mapName, sizeof(mapName), "maps/%s.bsp", mapName);

        DispatchKeyValue(g_iSnowEntity, "model", mapName);
        DispatchKeyValue(g_iSnowEntity, "preciptype", "3"); // 3 = Snow

        float worldMins[3], worldMaxs[3];
        GetEntPropVector(0, Prop_Data, "m_WorldMins", worldMins);
        GetEntPropVector(0, Prop_Data, "m_WorldMaxs", worldMaxs);

        float origin[3];
        origin[0] = (worldMins[0] + worldMaxs[0]) / 2.0;
        origin[1] = (worldMins[1] + worldMaxs[1]) / 2.0;
        origin[2] = (worldMins[2] + worldMaxs[2]) / 2.0;

        DispatchKeyValueVector(g_iSnowEntity, "origin", origin);
        DispatchSpawn(g_iSnowEntity);

        SetEntPropVector(g_iSnowEntity, Prop_Data, "m_Collision.m_vecMins", worldMins);
        SetEntPropVector(g_iSnowEntity, Prop_Data, "m_Collision.m_vecMaxs", worldMaxs);
    }
}

void RemoveSnowfall()
{
    if (g_iSnowEntity != -1 && IsValidEntity(g_iSnowEntity))
    {
        AcceptEntityInput(g_iSnowEntity, "Kill");
        g_iSnowEntity = -1;
    }
}