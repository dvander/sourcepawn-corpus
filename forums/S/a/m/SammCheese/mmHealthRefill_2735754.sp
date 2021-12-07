/*
    "arg1"      "Int for lives" // 1 = 0 revives, 2 = 1 revive, etc.
    "arg2"      "0"             // 0 = No Attacking but Moving, 1 = Complete Freeze including Attacking, 2 and above = No Impairment
    "arg3"      "3.0"           // Time in s after which it starts Refilling Health
    "arg4"      "0"             // Enable Fake End
*/
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <freak_fortress_2>


#pragma newdecls required
#pragma semicolon 1

#define this_plugin_name "mmHealthRefill"

bool 
    isHealing     = false,
    healTriggered = false,
    PlayerDamageHooked[MAXPLAYERS+1];
    
int 
    iVLives,
    iVFreeze,
    iVFakeEnd,
    healTriggers  = 0;

float
    fVRegenDelay,
    fVPlayerPositions[MAXPLAYERS+1][3],
    fVPlayerAngle[MAXPLAYERS+1][3];

public Plugin myinfo =
{
    name        = "Freak Fortress 2: Lifeloss Refill",
    author      = "Samm-Cheese#9500",
    description = "Allows Bosses to Regenerate their Health on LL",
    version     = "1.0.2"
}

public void OnPluginStart()
{
    HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
    HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);

    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsValidClient(client))
        {
            int BossID = FF2_GetBossIndex(client);
            if (BossID>=0 && FF2_HasAbility(BossID, this_plugin_name, "lifeloss_regen"))
            {
                iVLives      = FF2_GetArgI(BossID, this_plugin_name, "lifeloss_regen", "arg1", 1, 2);
                iVFreeze     = FF2_GetArgI(BossID, this_plugin_name, "lifeloss_regen", "arg2", 2, 0);
                fVRegenDelay = FF2_GetArgF(BossID, this_plugin_name, "lifeloss_regen", "arg3", 3, 3.0);
                iVFakeEnd    = FF2_GetArgI(BossID, this_plugin_name, "lifeloss_regen", "arg4", 4, 0);
                PlayerDamageHooked[client] = true;
                SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
            }
        }
    }
}


public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsValidEdict(client) && IsClientInGame(client))
        {
            int BossID = FF2_GetBossIndex(client);
            if(BossID>=0 && FF2_HasAbility(BossID, this_plugin_name, "lifeloss_regen"))
            {
                iVLives      = FF2_GetArgI(BossID, this_plugin_name, "lifeloss_regen", "arg1", 1, 2);
                iVFreeze     = FF2_GetArgI(BossID, this_plugin_name, "lifeloss_regen", "arg2", 2, 0);
                fVRegenDelay = FF2_GetArgF(BossID, this_plugin_name, "lifeloss_regen", "arg3", 3, 3.0);
                iVFakeEnd    = FF2_GetArgI(BossID, this_plugin_name, "lifeloss_regen", "arg4", 4, 0);
                PlayerDamageHooked[client] = true;
                SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
            }
        }
    }
}

public Action OnTakeDamageAlive(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if (!FF2_IsFF2Enabled())
        return Plugin_Continue;

    if (attacker<1 || client==attacker || !IsValidClient(attacker) || !IsValidClient(client))
        return Plugin_Continue;

    if (healTriggered)
        return Plugin_Continue;

    if (iVLives <= 1)
        return Plugin_Continue;

    int idBoss = FF2_GetBossIndex(client);
    int iHp    = FF2_GetBossHealth(idBoss);	// get Hp
    int iHpMax = FF2_GetBossMaxHealth(idBoss);	// max hp, for works with nimber of life
    int iLives = FF2_GetBossLives(idBoss);	// Take number of life
    int iAllHp = iHp;

    if (iLives > 1)
    {
        iAllHp = iHp+(iHpMax*(iLives-1)); // If multiple life and a take a really big damage (can happen with powerfull hit)
    }

    int iAlldamage = RoundFloat(damage);

    if (damagetype & DMG_ACID)
    {
        iAlldamage = RoundFloat(damage*1.5);	// If minicrit
    }
    if (damagetype & DMG_CRIT)
    {
        iAlldamage = RoundFloat(damage*3);	// If crit
    }
    if (iAllHp<=iAlldamage) // If damage can kill the boss
    {
        damage        = 0.0;              // Don't deal damage
        healTriggers  = healTriggers + 1; // Make Sure to Not start Healing at round start
        iVLives       = iVLives - 1;
        healTriggered = true;

        if (iVFakeEnd == 1)
        {
            getPlayerPosition(false);
            EmitGameSoundToAll("Game.YourTeamLost", SOUND_FROM_PLAYER, SND_NOFLAGS, -1, NULL_VECTOR, NULL_VECTOR, true, 7.0);
            CreateTimer(7.0, FakeEnding);
        }

        FF2_SetBossHealth(idBoss, 1);
        TF2_AddCondition(client, TFCond_UberchargedHidden,  TFCondDuration_Infinite);
        TF2_AddCondition(client, TFCond_MegaHeal,  TFCondDuration_Infinite);

        if (iVFreeze == 0)
        {
            TF2Attrib_AddCustomPlayerAttribute(client, "no_attack", 1.0, -1.0);
        }
        else if (iVFreeze == 1)
        {
            TF2_AddCondition(client, TFCond_FreezeInput, TFCondDuration_Infinite);
        }

        CreateTimer(fVRegenDelay, regenHealth, GetClientSerial(client));
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

public Action regenHealth(Handle timer, int serial)
{
    int client = GetClientFromSerial(serial);
    if (IsValidClient(client) && FF2_GetBossIndex(client) != -1)
    {
        isHealing = true;
    }
}

public void OnGameFrame()
{
    for (int client = 1; client <= MAXPLAYERS; client++)
    {
        if (isHealing)
        {
            if (PlayerDamageHooked[client])
            {
                int bossId = FF2_GetBossIndex(client);
                int healing = (FF2_GetBossHealth(bossId) + (7 + Players()));
                FF2_SetBossHealth(bossId, healing);
                FF2_HPBarUpdate();
                if (FF2_GetBossHealth(bossId) >= FF2_GetBossMaxHealth(bossId) && healTriggers != 0)
                {
                    TF2_RemoveCondition(client, TFCond_UberchargedHidden);
                    TF2_RemoveCondition(client, TFCond_MegaHeal);

                    if (iVFakeEnd == 1)
                    {
                        respawnPlayers(true);
                        getPlayerPosition(true);
                    }

                    if (iVFreeze == 0)
                    {
                        TF2Attrib_RemoveCustomPlayerAttribute(client, "no_attack");
                    }
                    else if (iVFreeze == 1)
                    {
                        TF2_RemoveCondition(client, TFCond_FreezeInput);
                    }
                    isHealing     = false;
                    healTriggered = false;
                }
            }
        }
    }
}

public void OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
    for (int client = 1; client <= MAXPLAYERS; client++)
    {
        if (PlayerDamageHooked[client])
        {
            SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
            PlayerDamageHooked[client] = false;
            isHealing       = false;
            healTriggers    = 0;
        }
    }
}


public Action FakeEnding(Handle timer)
{
    respawnPlayers(false);
}

void getPlayerPosition(bool TPback)
{
    if (!TPback)
    {
        for (int client = 1; client <= MAXPLAYERS; client++)
        {
            if (IsValidClient(client) && GetClientTeam(client) == 2)
            {
                GetClientEyePosition(client, fVPlayerPositions[client]);
                GetClientEyeAngles(client, fVPlayerAngle[client]);
            }
        }
    }
    else if (TPback)
    {
        for (int client = 1; client <= MAXPLAYERS; client++)
        {
            if (IsValidClient(client) && GetClientTeam(client) == 2)
            {
                TeleportEntity(client, fVPlayerPositions[client], fVPlayerAngle[client], NULL_VECTOR);
            }
        }
    }
}

void respawnPlayers(bool remove)
{
    if (!remove)
    {
        for (int client = 1; client <= MAXPLAYERS; client++)
        {
            if (IsValidClient(client) && GetClientTeam(client) == 2)
            {
                TF2_RespawnPlayer(client);
                TF2Attrib_AddCustomPlayerAttribute(client, "no_attack", 1.0, -1.0);
                TF2Attrib_AddCustomPlayerAttribute(client, "move speed penalty", 2.0, -1.0);
            }
        }
    }
    else if (remove)
    {
        for (int client = 1; client <= MAXPLAYERS; client++)
        {
            if (IsValidClient(client) && GetClientTeam(client) == 2)
            {
                TF2Attrib_RemoveCustomPlayerAttribute(client, "no_attack");
                TF2Attrib_RemoveCustomPlayerAttribute(client, "move speed penalty");
            }
        }
    }
}

int Players()
{
    int RPlayers = GetTeamClientCount(2);
    return RPlayers;
}

bool IsValidClient(int client, bool replaycheck = true) //checks if client is valid
{
    if (client<=0 || client>MaxClients)
    { 
        return false;
    }

    if (!IsClientInGame(client))
    {
        return false;
    }
    if (GetEntProp(client, Prop_Send, "m_bIsCoaching"))
    {
        return false;
    }
    if (replaycheck)
    { 
        if (IsClientSourceTV(client) || IsClientReplay(client))
        { 
            return true;
        } 
    }
    return true;
}