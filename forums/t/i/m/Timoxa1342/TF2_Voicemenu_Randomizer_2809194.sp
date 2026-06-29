#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = {
    name = "Bots Voice Randomizer",
    author = "Timoxa1342",
    description = "Bots use random voice commands based on their health.",
};

public OnClientPutInServer(client)
{
    CreateTimer(8.0, HealthVoiceTimer, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    return;
}

public Action:HealthVoiceTimer(Handle:timer, client)
{
    if (IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client))
    {
        float health = GetHealth(client);
        float max_health = GetMaxHealth(client);

        bool shouldSpeak = GetRandomInt(0, 3) == 1;

        if (!shouldSpeak) return Plugin_Continue;

        int randomVoiceCmd;

        int randomVoiceMenuCmd;

        if (health <= 0.3 * max_health)
        {
            randomVoiceCmd = GetRandomInt(0, 0);
            FakeClientCommand(client, "voicemenu 2 %d", randomVoiceCmd);
        }
        else if (health <= 0.7 * max_health)
        {
            randomVoiceCmd = GetRandomInt(0, 3);
            FakeClientCommand(client, "voicemenu 0 %d", randomVoiceCmd);
        }
        else
        {
            bool selectVoiceMenu2 = GetRandomInt(0, 1) == 1;

            if (selectVoiceMenu2)
            {
                randomVoiceCmd = GetRandomInt(1, 7);
                FakeClientCommand(client, "voicemenu 2 %d", randomVoiceCmd);
            }
            else
            {
                randomVoiceCmd = GetRandomInt(0, 7);
                randomVoiceMenuCmd = GetRandomInt(0, 1);
                FakeClientCommand(client, "voicemenu %d %d", randomVoiceMenuCmd, randomVoiceCmd);
            }
        }
    }
}

stock GetHealth(client)
{
    return GetEntProp(client, Prop_Send, "m_iHealth");
}

bool IsValidClient(client)
{
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
        return false;

    return true;
}

stock GetMaxHealth(client)
{
    int class = TF2_GetPlayerClass(client);
    int max_health = 0;

    switch (class)
    {
        case TFClass_Scout: max_health = 125;
        case TFClass_Soldier: max_health = 200;
        case TFClass_Pyro: max_health = 175;
        case TFClass_DemoMan: max_health = 175;
        case TFClass_Heavy: max_health = 300;
        case TFClass_Engineer: max_health = 125;
        case TFClass_Medic: max_health = 150;
        case TFClass_Sniper: max_health = 125;
        case TFClass_Spy: max_health = 125;
    }

    return max_health;
}
