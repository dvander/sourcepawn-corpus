#pragma semicolon 1
#include <sourcemod> 
#include <sceneprocessor>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

public Plugin myinfo = 
{
	name = "[L4D2] Carried Survivor Vocalization Restore", 
	author = "DeathChaos", 
	description = "Restores Some Vocalizations For Some Survivors Carried By Chargers.", 
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=260753"
};

#define MAX_ELLISRESPONSE 6
#define MAX_ROCHELLERESPONSE 2

char sEllisResponse[MAX_ELLISRESPONSE][] = 
{
	"player/survivor/voice/mechanic/chargerrunningwithplayer01.wav", 
	"player/survivor/voice/mechanic/chargerrunningwithplayer02.wav", 
	"player/survivor/voice/mechanic/chargerrunningwithplayer03.wav", 
	"player/survivor/voice/mechanic/chargerrunningwithplayer04.wav", 
	"player/survivor/voice/mechanic/chargerrunningwithplayer05.wav", 
	"player/survivor/voice/mechanic/chargerrunningwithplayer06.wav"
};

char sRochelleResponse[MAX_ROCHELLERESPONSE][] = 
{
	"player/survivor/voice/producer/chargerrunningwithplayer03.wav", 
	"player/survivor/voice/producer/chargerrunningwithplayer02.wav"
};

char sEllisScenes[MAX_ELLISRESPONSE][] = 
{
	"scenes/mechanic/chargerrunningwithplayer01.vcd", 
	"scenes/mechanic/chargerrunningwithplayer02.vcd", 
	"scenes/mechanic/chargerrunningwithplayer03.vcd", 
	"scenes/mechanic/chargerrunningwithplayer04.vcd", 
	"scenes/mechanic/chargerrunningwithplayer05.vcd", 
	"scenes/mechanic/chargerrunningwithplayer06.vcd"
};

char sRochelleScenes[MAX_ROCHELLERESPONSE][] = 
{
	"scenes/producer/chargerrunningwithplayer03.vcd", 
	"scenes/producer/chargerrunningwithplayer02.vcd"
};

public void OnPluginStart()
{
	HookEvent("charger_carry_start", OnSurvivorCharged);
}

public void OnMapStart()
{
	for (int i = 0; i < MAX_ELLISRESPONSE; i++)
	{
		PrefetchSound(sEllisResponse[i]);
		PrecacheSound(sEllisResponse[i], true);
	}
	
	for (int i = 0; i < MAX_ROCHELLERESPONSE; i++)
	{
		PrefetchSound(sRochelleResponse[i]);
		PrecacheSound(sRochelleResponse[i], true);
	}
}

public Action OnSurvivorCharged(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (!IsSurvivor(client) || IsActorBusy(client))
	{
		return;
	}
	
	DataPack pack = CreateDataPack();
	pack.WriteCell(GetClientUserId(client));
	CreateTimer(0.25, VoiceDelayTimer, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
}

public Action VoiceDelayTimer(Handle timer, Handle pack)
{
	ResetPack(pack);
	
	int client = GetClientOfUserId(ReadPackCell(pack));
	if (!IsSurvivor(client) || IsActorBusy(client))
	{
		return Plugin_Stop;
	}
	
	char clientModel[42];
	GetClientModel(client, clientModel, sizeof(clientModel));
	if (StrEqual(clientModel, "models/survivors/survivor_mechanic.mdl"))
	{
		int i = GetRandomInt(0, MAX_ELLISRESPONSE - 1);
		PerformSceneEx(client, "", sEllisScenes[i], 0.0, _, SCENE_INITIATOR_WORLD);
		EmitSoundToAll(sEllisResponse[i], client, SNDCHAN_VOICE);
	}
	else if (StrEqual(clientModel, "models/survivors/survivor_producer.mdl"))
	{
		int i = GetRandomInt(0, MAX_ROCHELLERESPONSE - 1);
		PerformSceneEx(client, "", sRochelleScenes[i], 0.0, _, SCENE_INITIATOR_WORLD);
		EmitSoundToAll(sRochelleResponse[i], client, SNDCHAN_VOICE);
	}
	
	return Plugin_Stop;
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

