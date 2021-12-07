#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

ConVar mp_halftime;
bool firsthalf = false;
bool swap = false;

public Plugin myinfo =
{
    name = "[CS:S] mp_halftime",
    author = "GabenNewell (Bad Kitty)",
    description = "Determines whether the match switches sides in a halftime event.",
    version = "2.0.0",
    url = "https://forums.alliedmods.net/showthread.php?t=241716"
};

public void OnPluginStart()
{
    mp_halftime = CreateConVar("mp_halftime", "1",
        "Determines whether the match switches sides in a halftime event.",
        FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if ((CS_GetTeamScore(2) + CS_GetTeamScore(3)) == 0)
        firsthalf = true;
    
    if (GetConVarBool(mp_halftime) && swap)
    {
        SwitchSides();
        swap = false;
    }

    return Plugin_Continue;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (GetConVarBool(mp_halftime) && firsthalf)
    {
        int maxrounds = GetConVarInt(FindConVar("mp_maxrounds"));
        int timeleft, timelimit;
        GetMapTimeLeft(timeleft);
        GetMapTimeLimit(timelimit); // Documentation error: Value is in minutes
        
        if ((maxrounds != 0 && (CS_GetTeamScore(2) + CS_GetTeamScore(3)) == (maxrounds / 2))
        || (timelimit != 0 && timeleft <= (timelimit * 60 / 2)))
        {
            swap = true;
            firsthalf = false;
        }
    }
}

void SwitchSides()
{
    int startmoney = GetConVarInt(FindConVar("mp_startmoney"));

    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && GetClientTeam(client) > 1)
        {
            for (int weapon, i = 0; i < 5; i++)
            {
                while ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
                {
                    if (i == 4)
                        CS_DropWeapon(client, weapon, false, true);
                    else
                        RemovePlayerItem(client, weapon);
                }
            }
            
            SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
            SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
            SetEntProp(client, Prop_Send, "m_bHasDefuser", 0);
            SetEntProp(client, Prop_Send, "m_iAccount", startmoney);
            
            CS_SwitchTeam(client, (GetClientTeam(client) == 2) ? 3 : 2);
            CS_RespawnPlayer(client);
        }
    }

    int tmp = CS_GetTeamScore(2);
    CS_SetTeamScore(2, CS_GetTeamScore(3));
    CS_SetTeamScore(3, tmp);

    SetTeamScore(2, CS_GetTeamScore(2));
    SetTeamScore(3, CS_GetTeamScore(3));
}
