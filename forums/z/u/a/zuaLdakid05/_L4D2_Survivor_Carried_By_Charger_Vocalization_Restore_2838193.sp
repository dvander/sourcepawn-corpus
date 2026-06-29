#include <sourcemod>
#include "sceneprocessor"
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
    name = "[L4D2] Survivor Carried By Charger Vocalization Restore",
    author = "DeathChaos",
    description = "Implements unused reaction lines for Ellis & Rochelle when they are being carried by a charger",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=260753"
};

#define MAX_ELLISRESPONSE        5
#define MAX_ROCHELLERESPONSE     1

static const char sEllisResponse[][] = 
{
    "player/survivor/voice/mechanic/chargerrunningwithplayer01.wav",
    "player/survivor/voice/mechanic/chargerrunningwithplayer02.wav",
    "player/survivor/voice/mechanic/chargerrunningwithplayer03.wav",
    "player/survivor/voice/mechanic/chargerrunningwithplayer04.wav",
    "player/survivor/voice/mechanic/chargerrunningwithplayer05.wav",
    "player/survivor/voice/mechanic/chargerrunningwithplayer06.wav"
};

static const char sRochelleResponse[][] = 
{
    "player/survivor/voice/producer/chargerrunningwithplayer03.wav",
    "player/survivor/voice/producer/chargerrunningwithplayer02.wav"
    // "player/survivor/voice/producer/chargerrunningwithplayer01.wav" // Broken in game
};

static const char sEllisScenes[][] = 
{
    "scenes/mechanic/chargerrunningwithplayer01.vcd",
    "scenes/mechanic/chargerrunningwithplayer02.vcd",
    "scenes/mechanic/chargerrunningwithplayer03.vcd",
    "scenes/mechanic/chargerrunningwithplayer04.vcd",
    "scenes/mechanic/chargerrunningwithplayer05.vcd",
    "scenes/mechanic/chargerrunningwithplayer06.vcd"
};

static const char sRochelleScenes[][] = 
{
    "scenes/producer/chargerrunningwithplayer03.vcd",
    "scenes/producer/chargerrunningwithplayer02.vcd"
    // "scenes/producer/chargerrunningwithplayer01.vcd" // Broken in game
};

public void OnPluginStart()
{
    HookEvent("charger_carry_start", Event_SurvivorCharged);
}

public void Event_SurvivorCharged(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("victim"));

    if (GetClientTeam(client) != 2 || IsActorBusy(client))
    {
        return;
    }

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    CreateTimer(0.25, VoiceDelayTimer, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
}

public Action VoiceDelayTimer(Handle timer, DataPack pack)
{
    pack.Reset();
    int client = GetClientOfUserId(pack.ReadCell());

    if (client == 0)
    {
        return Plugin_Stop;
    }

    char clientModel[64];
    GetClientModel(client, clientModel, sizeof(clientModel));

    if (StrEqual(clientModel, "models/survivors/survivor_mechanic.mdl"))
    {
        int i = GetRandomInt(0, MAX_ELLISRESPONSE);
        PerformSceneEx(client, "", sEllisScenes[i], 0.0, _, SCENE_INITIATOR_WORLD);
        EmitSoundToAll(sEllisResponse[i], client, SNDCHAN_VOICE);
    }
    else if (StrEqual(clientModel, "models/survivors/survivor_producer.mdl"))
    {
        int i = GetRandomInt(0, MAX_ROCHELLERESPONSE);
        PerformSceneEx(client, "", sRochelleScenes[i], 0.0, _, SCENE_INITIATOR_WORLD);
        EmitSoundToAll(sRochelleResponse[i], client, SNDCHAN_VOICE);
    }

    return Plugin_Stop;
}

public void OnMapStart()
{
	PrecacheSound("player/survivor/voice/mechanic/chargerrunningwithplayer01.wav", true);
    PrecacheSound("player/survivor/voice/mechanic/chargerrunningwithplayer02.wav", true);
    PrecacheSound("player/survivor/voice/mechanic/chargerrunningwithplayer03.wav", true);
    PrecacheSound("player/survivor/voice/mechanic/chargerrunningwithplayer04.wav", true);
    PrecacheSound("player/survivor/voice/mechanic/chargerrunningwithplayer05.wav", true);
    PrecacheSound("player/survivor/voice/mechanic/chargerrunningwithplayer06.wav", true);
	PrecacheSound("player/survivor/voice/producer/chargerrunningwithplayer03.wav", true);
    PrecacheSound("player/survivor/voice/producer/chargerrunningwithplayer02.wav", true);
    //PrecacheSound("player/survivor/voice/producer/chargerrunningwithplayer01.wav", true); // Broken in game
}