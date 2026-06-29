#pragma semicolon 1
#include <sourcemod>
#include <sceneprocessor>
#include <sdktools_functions>
#include <sdkhooks>
#include <l4d_stocks>

#define MAXENTITIES 4096
#define PLUGIN_VERSION "1.2"

public Plugin:myinfo =
{
	name = "Survivor Mourns Fix", 
	author = "DeathChaos25", 
	description = "Fixes Bugs About Missing Survivor Mourns.", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=258189"
};

#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl"
#define MODEL_BILL "models/survivors/survivor_namvet.mdl"
#define MODEL_NICK "models/survivors/survivor_gambler.mdl"
#define MODEL_COACH "models/survivors/survivor_coach.mdl"
#define MODEL_ROCHELLE "models/survivors/survivor_producer.mdl"
#define MODEL_ELLIS "models/survivors/survivor_mechanic.mdl"

new const String:sVoiceLines[7][] = 
{
	"player/survivor/voice/coach/worldc2m112.wav", 
	"player/survivor/voice/coach/worldc2m113.wav", 
	"player/survivor/voice/mechanic/worldc1m1b100.wav", 
	"player/survivor/voice/mechanic/worldc1m1b102.wav", 
	"player/survivor/voice/mechanic/worldc1m1b147.wav", 
	"player/survivor/voice/mechanic/worldc1m1b148.wav", 
	"player/survivor/voice/producer/Generic02.wav"
};

static iDeathBody[MAXPLAYERS+1] = 0;
static iDeathScene[MAXPLAYERS+1] = 0;

static MODEL_LOUIS_INDEX;
static MODEL_FRANCIS_INDEX;
static MODEL_BILL_INDEX;
static MODEL_ZOEY_INDEX;
static MODEL_ROCHELLE_INDEX;
static MODEL_ELLIS_INDEX;

static bool:rUnwantedMourns = false;

public OnPluginStart()
{
	CreateTimer(10.0, TimerUpdate, _, TIMER_REPEAT);
	
	CreateConVar("survivor_mourns_fix_version", PLUGIN_VERSION, "Survivor Mourns Fix Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("map_transition", OnRoundReset);
	HookEvent("round_end", OnRoundReset);
	HookEvent("round_start", OnRoundReset);
	
	HookEvent("round_end", OnMournsRemove);
	HookEvent("mission_lost", OnMournsRemove);
	
	HookEvent("player_death", OnPlayerDeath);
}

public OnMapStart()
{
	MODEL_LOUIS_INDEX = PrecacheModel(MODEL_LOUIS, true);
	MODEL_FRANCIS_INDEX = PrecacheModel(MODEL_FRANCIS, true);
	MODEL_BILL_INDEX = PrecacheModel(MODEL_BILL, true);
	MODEL_ZOEY_INDEX = PrecacheModel(MODEL_ZOEY, true);
	MODEL_ROCHELLE_INDEX = PrecacheModel(MODEL_ROCHELLE, true);
	MODEL_ELLIS_INDEX = PrecacheModel(MODEL_ELLIS, true);
	
	for (new i = 0; i < 7; i++)
	{
		PrefetchSound(sVoiceLines[i]);
		PrecacheSound(sVoiceLines[i], true);
	}
}

public Action:TimerUpdate(Handle:timer)
{
	if (!IsServerProcessing())
	{
		return Plugin_Continue;
	}
	
	if(!rUnwantedMourns)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientLouis(i) || IsClientBill(i) || IsClientFrancis(i) || IsClientZoey(i) || IsClientEllis(i) || IsClientCoach(i) || IsClientRochelle(i) || IsClientNick(i))
			{
				decl Float:Origin[3], Float:TOrigin[3];
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Origin);
				if (iDeathBody[i] == 0 && iDeathScene[i] == 0)
				{
					new entity = -1;
					while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != INVALID_ENT_REFERENCE)
					{
						GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TOrigin);
						new Float:distance = GetVectorDistance(Origin, TOrigin);
						if (distance <= 100.0)
						{
							iDeathBody[i] = entity;
							MournSurvivor(i);
							iDeathScene[i] = 1;
						}
					}
				}
				else if (iDeathBody[i] > 0 && iDeathScene[i] == 0)
				{
					decl String:classname[128];
					if (IsValidEntity(iDeathBody[i]))
					{
						GetEntityClassname(iDeathBody[i], classname, sizeof(classname));
						
						GetEntPropVector(iDeathBody[i], Prop_Send, "m_vecOrigin", TOrigin);
						
						new Float:distance = GetVectorDistance(Origin, TOrigin);
						if (distance <= 100.0 && StrEqual(classname, "survivor_death_model"))
						{
							MournSurvivor(i);
							iDeathScene[i] = 1;
						}
						else
						{
							iDeathBody[i] = 0;
							iDeathScene[i] = 0;
						}
					}
					else
					{
						iDeathBody[i] = 0;
						iDeathScene[i] = 0;
					}
				}
				else if (iDeathBody[i] > 0 && iDeathScene[i] > 0)
				{
					if (IsValidEntity(iDeathBody[i]))
					{
						decl String:dbClass[64];
						GetEntityClassname(iDeathBody[i], dbClass, sizeof(dbClass));
						if (StrEqual(dbClass, "instanced_scripted_scene") || StrEqual(dbClass, "predicted_viewmodel") || StrContains(dbClass, "ability") != -1)
						{
							return Plugin_Continue;
						}
						
						GetEntPropVector(iDeathBody[i], Prop_Send, "m_vecOrigin", TOrigin);
						
						new Float:distance = GetVectorDistance(Origin, TOrigin);
						if (distance > 100.0)
						{
							iDeathBody[i] = 0;
							iDeathScene[i] = 0;
						}
					}
					else
					{
						iDeathBody[i] = 0;
						iDeathScene[i] = 0;
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

stock MournSurvivor(client)
{
	if (IsClientZoey(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client))
	{
		new random = GetRandomInt(1, 5);
		
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/TeenGirl/GriefManager03.vcd");
				case 2: PerformSceneEx(client, "", "scenes/TeenGirl/GriefManager08.vcd");
				case 3: PerformSceneEx(client, "", "scenes/TeenGirl/GriefManager09.vcd");
				case 4: PerformSceneEx(client, "", "scenes/TeenGirl/GriefManager11.vcd");
				case 5: PerformSceneEx(client, "", "scenes/TeenGirl/GriefManager03.vcd");
			}
		}
		else if (index == MODEL_BILL_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/TeenGirl/GriefVet02.vcd");
				case 2: PerformSceneEx(client, "", "scenes/TeenGirl/GriefVet03.vcd");
				case 3: PerformSceneEx(client, "", "scenes/TeenGirl/GriefVet05.vcd");
				case 4: PerformSceneEx(client, "", "scenes/TeenGirl/GriefVet07.vcd");
				case 5: PerformSceneEx(client, "", "scenes/TeenGirl/GriefVet09.vcd");
			}
		}
		else if (index == MODEL_FRANCIS_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/TeenGirl/GriefBiker01.vcd");
				case 2: PerformSceneEx(client, "", "scenes/TeenGirl/GriefBiker02.vcd");
				case 3: PerformSceneEx(client, "", "scenes/TeenGirl/GriefBiker04.vcd");
				case 4: PerformSceneEx(client, "", "scenes/TeenGirl/GriefBiker06.vcd");
				case 5: PerformSceneEx(client, "", "scenes/TeenGirl/GriefBiker07.vcd");
			}
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/TeenGirl/Generic10.vcd");
				case 2: PerformSceneEx(client, "", "scenes/TeenGirl/Generic03.vcd");
				case 3: PerformSceneEx(client, "", "scenes/TeenGirl/GenericResponses35.vcd");
				case 4: PerformSceneEx(client, "", "scenes/TeenGirl/Generic10.vcd");
				case 5: PerformSceneEx(client, "", "scenes/TeenGirl/Generic03.vcd");
			}
		}
		else if (index == MODEL_ELLIS_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/TeenGirl/dlc1_c6m3_l4d1finalecinematic23.vcd");
				case 2: PerformSceneEx(client, "", "scenes/TeenGirl/dlc1_c6m3_l4d1finalecinematic24.vcd");
				case 3: PerformSceneEx(client, "", "scenes/TeenGirl/dlc1_c6m3_l4d1finalecinematic25.vcd");
				case 4: PerformSceneEx(client, "", "scenes/TeenGirl/dlc1_c6m3_l4d1finalecinematic24.vcd");
				case 5: PerformSceneEx(client, "", "scenes/TeenGirl/dlc1_c6m3_l4d1finalecinematic23.vcd");
			}
		}
	}
	else if (IsClientBill(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client))
	{
		new random = GetRandomInt(1, 5);
		
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/NamVet/GriefManager01.vcd");
				case 2: PerformSceneEx(client, "", "scenes/NamVet/GriefManager02.vcd");
				case 3: PerformSceneEx(client, "", "scenes/NamVet/GriefManager03.vcd");
				case 4: PerformSceneEx(client, "", "scenes/NamVet/GriefManager01.vcd");
				case 5: PerformSceneEx(client, "", "scenes/NamVet/GriefManager02.vcd");
			}
		}
		else if (index == MODEL_BILL_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/NamVet/GriefBiker03.vcd");
				case 2: PerformSceneEx(client, "", "scenes/NamVet/GriefManager03.vcd");
				case 3: PerformSceneEx(client, "", "scenes/NamVet/GriefTeengirl03.vcd");
				case 4: PerformSceneEx(client, "", "scenes/NamVet/GriefBiker03.vcd");
				case 5: PerformSceneEx(client, "", "scenes/NamVet/GriefManager03.vcd");
			}
		}
		else if (index == MODEL_FRANCIS_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/NamVet/GriefBiker01.vcd");
				case 2: PerformSceneEx(client, "", "scenes/NamVet/GriefBiker02.vcd");
				case 3: PerformSceneEx(client, "", "scenes/NamVet/GriefBiker03.vcd");
				case 4: PerformSceneEx(client, "", "scenes/NamVet/GriefBiker01.vcd");
				case 5: PerformSceneEx(client, "", "scenes/NamVet/GriefBiker02.vcd");
			}
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/NamVet/GriefTeengirl01.vcd");
				case 2: PerformSceneEx(client, "", "scenes/NamVet/GriefTeengirl02.vcd");
				case 3: PerformSceneEx(client, "", "scenes/NamVet/GriefFemaleGeneric01.vcd");
				case 4: PerformSceneEx(client, "", "scenes/NamVet/GriefFemaleGeneric02.vcd");
				case 5: PerformSceneEx(client, "", "scenes/NamVet/GriefFemaleGeneric03.vcd");
			}
		}
	}
	else if (IsClientFrancis(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client))
	{
		new random = GetRandomInt(1, 5);
		
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/Biker/GriefManager01.vcd");
				case 2: PerformSceneEx(client, "", "scenes/Biker/GriefManager02.vcd");
				case 3: PerformSceneEx(client, "", "scenes/Biker/GriefManager03.vcd");
				case 4: PerformSceneEx(client, "", "scenes/Biker/GriefManager04.vcd");
				case 5: PerformSceneEx(client, "", "scenes/Biker/GriefManager05.vcd");
			}
		}
		else if (index == MODEL_BILL_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/Biker/GriefVet01.vcd");
				case 2: PerformSceneEx(client, "", "scenes/Biker/GriefVet02.vcd");
				case 3: PerformSceneEx(client, "", "scenes/Biker/GriefVet03.vcd");
				case 4: PerformSceneEx(client, "", "scenes/Biker/GriefVet01.vcd");
				case 5: PerformSceneEx(client, "", "scenes/Biker/GriefVet02.vcd");
			}
		}
		else if (index == MODEL_FRANCIS_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/Biker/DLC1_C6M3_Loss01.vcd");
				case 2: PerformSceneEx(client, "", "scenes/Biker/DLC1_C6M3_Loss02.vcd");
				case 3: PerformSceneEx(client, "", "scenes/Biker/GriefManager02.vcd");
				case 4: PerformSceneEx(client, "", "scenes/Biker/GriefManager03.vcd");
				case 5: PerformSceneEx(client, "", "scenes/Biker/GriefManager05.vcd");
			}
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/Biker/GriefTeengirl01.vcd");
				case 2: PerformSceneEx(client, "", "scenes/Biker/GriefTeengirl02.vcd");
				case 3: PerformSceneEx(client, "", "scenes/Biker/GriefFemaleGeneric03.vcd");
				case 4: PerformSceneEx(client, "", "scenes/Biker/GriefTeengirl01.vcd");
				case 5: PerformSceneEx(client, "", "scenes/Biker/GriefTeengirl02.vcd");
			}
		}
		else if (index == MODEL_ROCHELLE_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/Biker/dlc1_c6m3_l4d1finalecinematic08.vcd");
				case 2: PerformSceneEx(client, "", "scenes/Biker/dlc1_c6m3_l4d1finalecinematic16.vcd");
				case 3: PerformSceneEx(client, "", "scenes/Biker/dlc1_c6m3_l4d1finalecinematic17.vcd");
				case 4: PerformSceneEx(client, "", "scenes/Biker/dlc1_c6m3_l4d1finalecinematic16.vcd");
				case 5: PerformSceneEx(client, "", "scenes/Biker/dlc1_c6m3_l4d1finalecinematic08.vcd");
			}
		}
	}
	else if (IsClientLouis(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client))
	{
		new random = GetRandomInt(1, 8);
		
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES03.vcd");
				case 2: PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES04.vcd");
				case 3: PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES03.vcd");
				case 4: PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES04.vcd");
				case 5: PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES03.vcd");
				case 6: PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES04.vcd");
				case 7: PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES03.vcd");
				case 8: PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES04.vcd");
			}
		}
		else if (index == MODEL_BILL_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/Manager/GriefVet01.vcd");
				case 2: PerformSceneEx(client, "", "scenes/Manager/GriefVet03.vcd");
				case 3: PerformSceneEx(client, "", "scenes/Manager/GriefVet04.vcd");
				case 4: PerformSceneEx(client, "", "scenes/Manager/GriefVet06.vcd");
				case 5: PerformSceneEx(client, "", "scenes/Manager/GriefVet07.vcd");
				case 6: PerformSceneEx(client, "", "scenes/Manager/GriefVet08.vcd");
				case 7: PerformSceneEx(client, "", "scenes/Manager/GriefVet01.vcd");
				case 8: PerformSceneEx(client, "", "scenes/Manager/GriefVet03.vcd");
			}
		}
		else if (index == MODEL_FRANCIS_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/Manager/GriefBiker01.vcd");
				case 2: PerformSceneEx(client, "", "scenes/Manager/GriefBiker03.vcd");
				case 3: PerformSceneEx(client, "", "scenes/Manager/GriefBiker04.vcd");
				case 4: PerformSceneEx(client, "", "scenes/Manager/GriefBiker05.vcd");
				case 5: PerformSceneEx(client, "", "scenes/Manager/GriefBiker06.vcd");
				case 6: PerformSceneEx(client, "", "scenes/Manager/GriefBiker07.vcd");
				case 7: PerformSceneEx(client, "", "scenes/Manager/GriefBiker01.vcd");
				case 8: PerformSceneEx(client, "", "scenes/Manager/GriefBiker03.vcd");
			}
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/Manager/GriefTeengirl01.vcd");
				case 2: PerformSceneEx(client, "", "scenes/Manager/GriefTeengirl02.vcd");
				case 3: PerformSceneEx(client, "", "scenes/Manager/GriefTeengirl03.vcd");
				case 4: PerformSceneEx(client, "", "scenes/Manager/GriefTeengirl04.vcd");
				case 5: PerformSceneEx(client, "", "scenes/Manager/GriefTeengirl05.vcd");
				case 6: PerformSceneEx(client, "", "scenes/Manager/GriefTeengirl06.vcd");
				case 7: PerformSceneEx(client, "", "scenes/Manager/GriefTeengirl07.vcd");
				case 8: PerformSceneEx(client, "", "scenes/Manager/GriefTeengirl08.vcd");
			}
		}
	}
	else if (IsClientEllis(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client))
	{
		new random = GetRandomInt(1, 5);
		
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/Mechanic/SurvivorMournNick03.vcd");
				case 2: { PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B100.vcd"); EmitSoundToAll("player/survivor/voice/mechanic/worldc1m1b100.wav", client, SNDCHAN_VOICE); }
				case 3: { PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B102.vcd"); EmitSoundToAll("player/survivor/voice/mechanic/worldc1m1b102.wav", client, SNDCHAN_VOICE); }
				case 4: { PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B147.vcd"); EmitSoundToAll("player/survivor/voice/mechanic/worldc1m1b147.wav", client, SNDCHAN_VOICE); }
				case 5: { PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B148.vcd"); EmitSoundToAll("player/survivor/voice/mechanic/worldc1m1b148.wav", client, SNDCHAN_VOICE); }
			}
		}
		else if (index == MODEL_BILL_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/Mechanic/SurvivorMournGamblerC101.vcd");
				case 2: { PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B100.vcd"); EmitSoundToAll("player/survivor/voice/mechanic/worldc1m1b100.wav", client, SNDCHAN_VOICE); }
				case 3: { PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B102.vcd"); EmitSoundToAll("player/survivor/voice/mechanic/worldc1m1b102.wav", client, SNDCHAN_VOICE); }
				case 4: { PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B147.vcd"); EmitSoundToAll("player/survivor/voice/mechanic/worldc1m1b147.wav", client, SNDCHAN_VOICE); }
				case 5: { PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B148.vcd"); EmitSoundToAll("player/survivor/voice/mechanic/worldc1m1b148.wav", client, SNDCHAN_VOICE); }
			}
		}
		else if (index == MODEL_FRANCIS_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/Mechanic/DLC1_C6M3_FinaleFinalGas10.vcd");
				case 2: { PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B100.vcd"); EmitSoundToAll("player/survivor/voice/mechanic/worldc1m1b100.wav", client, SNDCHAN_VOICE); }
				case 3: { PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B102.vcd"); EmitSoundToAll("player/survivor/voice/mechanic/worldc1m1b102.wav", client, SNDCHAN_VOICE); }
				case 4: { PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B147.vcd"); EmitSoundToAll("player/survivor/voice/mechanic/worldc1m1b147.wav", client, SNDCHAN_VOICE); }
				case 5: { PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B148.vcd"); EmitSoundToAll("player/survivor/voice/mechanic/worldc1m1b148.wav", client, SNDCHAN_VOICE); }
			}
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/mechanic/survivormournproducerc101.vcd");
				case 2: PerformSceneEx(client, "", "scenes/Mechanic/DLC1_C6M3_FinaleFinalGas02.vcd");
				case 3: PerformSceneEx(client, "", "scenes/mechanic/survivormournproducerc102.vcd");
				case 4: PerformSceneEx(client, "", "scenes/Mechanic/DLC1_C6M3_FinaleFinalGas05.vcd");
				case 5: PerformSceneEx(client, "", "scenes/Mechanic/DLC1_C6M3_FinaleFinalGas04.vcd");
			}
		}
	}
	else if (IsClientCoach(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client))
	{
		new random = GetRandomInt(1, 4);
		
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX || index == MODEL_BILL_INDEX || index == MODEL_FRANCIS_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/Coach/SurvivorMournMechanicC101.vcd");
				case 2: { PerformSceneEx(client, "", "scenes/Coach/WorldC2M112.vcd"); EmitSoundToAll("player/survivor/voice/coach/worldc2m112.wav", client, SNDCHAN_VOICE); }
				case 3: { PerformSceneEx(client, "", "scenes/Coach/WorldC2M113.vcd"); EmitSoundToAll("player/survivor/voice/coach/worldc2m113.wav", client, SNDCHAN_VOICE); }
				case 4: PerformSceneEx(client, "", "scenes/Coach/SurvivorMournMechanicC101.vcd");
			}
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/Coach/SurvivorMournProducerC101.vcd");
				case 2: PerformSceneEx(client, "", "scenes/Coach/SurvivorMournProducerC102.vcd");
				case 3: PerformSceneEx(client, "", "scenes/Coach/SurvivorMournRochelle01.vcd");
				case 4: PerformSceneEx(client, "", "scenes/Coach/SurvivorMournRochelle03.vcd");
			}
		}
	}
	else if (IsClientNick(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client))
	{
		new random = GetRandomInt(1, 2);
		
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX || index == MODEL_BILL_INDEX || index == MODEL_FRANCIS_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/Gambler/SurvivorMournMechanicC102.vcd");
				case 2: PerformSceneEx(client, "", "scenes/Gambler/SurvivorMournMechanicC102.vcd");
			}
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			switch (random)
			{
				case 1: PerformSceneEx(client, "", "scenes/Gambler/SurvivorMournProducerC101.vcd");
				case 2: PerformSceneEx(client, "", "scenes/Gambler/SurvivorMournProducerC102.vcd");
			}
		}
	}
	else if (IsClientRochelle(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client))
	{
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX || index == MODEL_BILL_INDEX)
		{
			PerformSceneEx(client, "", "scenes/Producer/SurvivorMournGamblerC101.vcd");
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			PerformSceneEx(client, "", "scenes/Producer/Generic02.vcd");
			EmitSoundToAll("player/survivor/voice/producer/generic02.wav", client, SNDCHAN_VOICE);
		}
		else if (index == MODEL_FRANCIS_INDEX)
		{
			PerformSceneEx(client, "", "scenes/Producer/DLC1_C6M3_FinaleChat10.vcd");
		}
	}
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:model[42];
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientRochelle(client))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", model, sizeof(model));
				if (StrEqual(model, MODEL_FRANCIS, false))
				{
					new i_rand = GetRandomInt(1, 3);
					PerformSceneEx(i, "", "scenes/Biker/dlc1_c6m3_l4d1finalecinematic07.vcd", 1.2);
					if (i_rand > 1)
					{
						break;
					}
				}
			}
		}
	}
	else if (IsClientZoey(client))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", model, sizeof(model));
				if (StrEqual(model, MODEL_NICK, false))
				{
					new i_rand = GetRandomInt(1, 3);
					PerformSceneEx(i, "", "scenes/gambler/dlc1_c6m3_finalel4d1killing04.vcd", 1.2);
					if (i_rand > 1)
					{
						break;
					}
				}
				else if (StrEqual(model, MODEL_COACH, false))
				{
					new i_rand = GetRandomInt(1, 3);
					PerformSceneEx(i, "", "scenes/coach/nameproducerc103.vcd", 1.2);
					if (i_rand > 1)
					{
						break;
					}
				}
				else if (StrEqual(model, MODEL_ELLIS, false))
				{
					new i_rand = GetRandomInt(1, 3);
					PerformSceneEx(i, "", "scenes/mechanic/dlc1_c6m3_finalel4d1killing11.vcd", 1.2);
					if (i_rand > 1)
					{
						break;
					}
				}
			}
		}
	}
	else if (IsClientFrancis(client))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", model, sizeof(model));
				if (StrEqual(model, MODEL_ROCHELLE, false))
				{
					new i_rand = GetRandomInt(1, 3);
					PerformSceneEx(i, "", "scenes/producer/dlc1_c6m3_finalel4d1killing04.vcd", 1.2);
					if (i_rand > 1)
					{
						break;
					}
				}
				else if (StrEqual(model, MODEL_ELLIS, false))
				{
					new i_rand = GetRandomInt(1, 3);
					PerformSceneEx(i, "", "scenes/mechanic/dlc1_c6m3_finalel4d1killing13.vcd", 1.2);
					if (i_rand > 1)
					{
						break;
					}
				}
			}
		}
	}
	else if (IsClientLouis(client))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", model, sizeof(model));
				if (StrEqual(model, MODEL_ELLIS, false))
				{
					new i_rand = GetRandomInt(1, 3);
					PerformSceneEx(i, "", "scenes/mechanic/dlc1_c6m3_finalel4d1killing20.vcd", 1.2);
					if (i_rand > 1)
					{
						break;
					}
				}
			}
		}
	}
}

stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}

stock bool:IsClientNick(client)
{
	if (IsSurvivor(client))
	{
		new cSurvivor = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if (cSurvivor == 0)
		{
			decl String:model[42];
			GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, MODEL_NICK, false))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsClientRochelle(client)
{
	if (IsSurvivor(client))
	{
		new cSurvivor = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if (cSurvivor == 1)
		{
			decl String:model[42];
			GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, MODEL_ROCHELLE, false))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsClientCoach(client)
{
	if (IsSurvivor(client))
	{
		new cSurvivor = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if (cSurvivor == 2)
		{
			decl String:model[42];
			GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, MODEL_COACH, false))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsClientEllis(client)
{
	if (IsSurvivor(client))
	{
		new cSurvivor = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if (cSurvivor == 3)
		{
			decl String:model[42];
			GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, MODEL_ELLIS, false))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsClientBill(client)
{
	if (IsSurvivor(client))
	{
		new cSurvivor = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if (cSurvivor == 4)
		{
			decl String:model[42];
			GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, MODEL_BILL, false))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsClientZoey(client)
{
	if (IsSurvivor(client))
	{
		new cSurvivor = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if (cSurvivor == 0)
		{
			decl String:model[42];
			GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, MODEL_ZOEY, false))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsClientLouis(client)
{
	if (IsSurvivor(client))
	{
		new cSurvivor = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if (cSurvivor == 7)
		{
			decl String:model[42];
			GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, MODEL_LOUIS, false))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsClientFrancis(client)
{
	if (IsSurvivor(client))
	{
		new cSurvivor = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if (cSurvivor == 6)
		{
			decl String:model[42];
			GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, MODEL_FRANCIS, false))
			{
				return true;
			}
		}
	}
	return false;
}

public Action:OnRoundReset(Handle:event, const String:name[], bool:dontBroadcast)
{
	rUnwantedMourns = false;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			iDeathBody[i] = 0;
			iDeathScene[i] = 0;
		}
	}
}

public Action:OnMournsRemove(Handle:event, const String:name[], bool:dontBroadcast)
{
	rUnwantedMourns = true;
}

public OnMapEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			iDeathBody[i] = 0;
			iDeathScene[i] = 0;
		}
	}
}

