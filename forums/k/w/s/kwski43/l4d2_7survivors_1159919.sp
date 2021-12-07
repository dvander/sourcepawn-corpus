#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "3.0"

#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl"
#define MODEL_NICK "models/survivors/survivor_gambler.mdl"
#define MODEL_COACH "models/survivors/survivor_coach.mdl"
#define MODEL_ROCHELLE "models/survivors/survivor_producer.mdl"
#define MODEL_ELLIS "models/survivors/survivor_mechanic.mdl"

new Handle:cvarPluginVersion;

public Plugin:myinfo = 
{
	name = "L4D2 7 Sruvivors",
	author = "kwski43 aka Jacklul",
	description = "Allows to set 7 survivors without cloned models.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	decl String:s_Game[12];
	
	GetGameFolderName(s_Game, sizeof(s_Game));
	if (!StrEqual(s_Game, "left4dead2"))
		SetFailState("Seven Survivors supports Left 4 Dead 2 only!");
	
	cvarPluginVersion = CreateConVar("l4d2_7survivors_version", PLUGIN_VERSION, "Seven Survivors Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		
	HookEvent("round_start", RoundStart, EventHookMode_Post);
	SetConVarString(cvarPluginVersion, PLUGIN_VERSION);
}

public OnMapStart()
{
	PrecacheModel(MODEL_FRANCIS, true);
	PrecacheModel(MODEL_LOUIS, true);
	PrecacheModel(MODEL_ZOEY, true);
	PrecacheModel(MODEL_NICK, true);
	PrecacheModel(MODEL_COACH, true);
	PrecacheModel(MODEL_ROCHELLE, true);
	PrecacheModel(MODEL_ELLIS, true);
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new model=0;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
		model=model+1;
		if(model==1)
		{
			SetEntityModel(client, MODEL_COACH);
		}
		else if(model==2)
		{
			SetEntityModel(client, MODEL_ELLIS);
		}		
		else if(model==3)
		{
			SetEntityModel(client, MODEL_NICK);
		}
		else if(model==4)
		{
			SetEntityModel(client, MODEL_ROCHELLE);
		}
		else if(model==5)
		{
			SetEntityModel(client, MODEL_ZOEY);
		}
		else if(model==6)
		{
			SetEntityModel(client, MODEL_FRANCIS);
		}
		else if(model==7)
		{		
			SetEntityModel(client, MODEL_LOUIS);
		}
		}		
	}
}