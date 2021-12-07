#include <sourcemod> 
#include <sceneprocessor>
#include <sdktools>
#define PLUGIN_VERSION		"1.0"

public Plugin:myinfo = 
{
	name = "[L4D2] Survivor Carried By Charger Vocalization Restore", 
	author = "DeathChaos", 
	description = "Implements unused reactions lines for Ellis & Rochelle when they are being carried by a charger", 
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=260753"
}

#define MAX_ELLISRESPONSE  5
#define MAX_ROCHELLERESPONSE  2

new const String:sEllisResponse[MAX_ELLISRESPONSE + 1][] = 
{
	"player/survivor/voice/mechanic/chargerrunningwithplayer01.wav",
	"player/survivor/voice/mechanic/chargerrunningwithplayer02.wav", 
	"player/survivor/voice/mechanic/chargerrunningwithplayer03.wav", 
	"player/survivor/voice/mechanic/chargerrunningwithplayer04.wav", 
	"player/survivor/voice/mechanic/chargerrunningwithplayer05.wav", 
	"player/survivor/voice/mechanic/chargerrunningwithplayer06.wav"
};

new const String:sEllisScenes[MAX_ELLISRESPONSE + 1][] = 
{
	"scenes/mechanic/chargerrunningwithplayer01.vcd",
	"scenes/mechanic/chargerrunningwithplayer02.vcd", 
	"scenes/mechanic/chargerrunningwithplayer03.vcd", 
	"scenes/mechanic/chargerrunningwithplayer04.vcd", 
	"scenes/mechanic/chargerrunningwithplayer05.vcd", 
	"scenes/mechanic/chargerrunningwithplayer06.vcd"
};

new const String:sRochelleResponse[MAX_ROCHELLERESPONSE + 1][] = 
{
	"player/survivor/voice/producer/chargerrunningwithplayer01.wav",
	"player/survivor/voice/producer/chargerrunningwithplayer02.wav",	
	"player/survivor/voice/producer/chargerrunningwithplayer03.wav"
};

new const String:sRochelleScenes[MAX_ROCHELLERESPONSE + 1][] = 
{
	"scenes/producer/chargerrunningwithplayer01.vcd",
	"scenes/producer/chargerrunningwithplayer02.vcd", 
	"scenes/producer/chargerrunningwithplayer03.vcd"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_chargercarried", ChargerCarried, ADMFLAG_ROOT);
	HookEvent("charger_carry_start", Event_SurvivorCharged);
}

public Action:ChargerCarried(client, args)
{
	new String:clientModel[42];
	GetClientModel(client, clientModel, sizeof(clientModel));
	if (StrEqual(clientModel, "models/survivors/survivor_mechanic.mdl"))
	{
		new i = GetRandomInt(0, MAX_ELLISRESPONSE);
		PerformSceneEx(client, "", sEllisScenes[i], 0.0, _, SCENE_INITIATOR_WORLD);
		EmitSoundToAll(sEllisResponse[i], client, SNDCHAN_VOICE);
	}
	else if (StrEqual(clientModel, "models/survivors/survivor_producer.mdl"))
	{
		new i = GetRandomInt(0, MAX_ROCHELLERESPONSE); //Third voice file seems to be broken ingame
		PerformSceneEx(client, "", sRochelleScenes[i], 0.0, _, SCENE_INITIATOR_WORLD);
		EmitSoundToAll(sRochelleResponse[i], client, SNDCHAN_VOICE);
	}
	return Plugin_Handled;
}

public Event_SurvivorCharged(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (!IsSurvivor(client))
	{
		return;
	}
	if (IsActorBusy(client))
	{
		return;
	}
	
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, GetClientUserId(client));
	CreateTimer(0.25, VoiceDelayTimer, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
}

public Action:VoiceDelayTimer(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = GetClientOfUserId(ReadPackCell(pack));
	if (client == 0)
	{
		return Plugin_Stop;
	}
	
	new String:clientModel[42];
	GetClientModel(client, clientModel, sizeof(clientModel));
	
	if (StrEqual(clientModel, "models/survivors/survivor_mechanic.mdl"))
	{
		new i = GetRandomInt(0, MAX_ELLISRESPONSE);
		PerformSceneEx(client, "", sEllisScenes[i], 0.0, _, SCENE_INITIATOR_WORLD);
		EmitSoundToAll(sEllisResponse[i], client, SNDCHAN_VOICE);
	}
	else if (StrEqual(clientModel, "models/survivors/survivor_producer.mdl"))
	{
		new i = GetRandomInt(0, MAX_ROCHELLERESPONSE); //Third voice file seems to be broken ingame
		PerformSceneEx(client, "", sRochelleScenes[i], 0.0, _, SCENE_INITIATOR_WORLD);
		EmitSoundToAll(sRochelleResponse[i], client, SNDCHAN_VOICE);
	}
	
	return Plugin_Stop;
}

stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}

public OnMapStart()
{
	for (new i = 0; i <= MAX_ELLISRESPONSE; i++)
	{
		PrefetchSound(sEllisResponse[i]);
		PrecacheSound(sEllisResponse[i], true);
	}
	for (new i = 0; i <= MAX_ROCHELLERESPONSE; i++)
	{
		PrefetchSound(sRochelleResponse[i]);
		PrecacheSound(sRochelleResponse[i], true);
	}
} 