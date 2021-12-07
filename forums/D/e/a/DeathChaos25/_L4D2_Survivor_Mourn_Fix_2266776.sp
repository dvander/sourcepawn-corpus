/* Includes */
#include <sourcemod>
#include <sceneprocessor>
#include <sdktools_functions>
#include <sdkhooks>
#include <l4d_stocks>

#define MAXENTITIES 4096
#define CVAR_SURVIVOR_MAX_INCAP_COUNT "survivor_max_incapacitated_count"
#define PLUGIN_VERSION "1.3"

/* Plugin Information */
public Plugin:myinfo =  {
	name = "[L4D2] Survivor Mourn Fix", 
	author = "DeathChaos25", 
	description = "Fixes the bug where any survivor is unable to mourn a L4D1 survivor on the L4D2 set", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=258189"
}

/* Huge thanks to machine for the original concept! */

/* Globals */

#define MODEL_FRANCIS		"models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS			"models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY			"models/survivors/survivor_teenangst.mdl"
#define MODEL_BILL			"models/survivors/survivor_namvet.mdl"
#define MODEL_NICK			"models/survivors/survivor_gambler.mdl"
#define MODEL_COACH			"models/survivors/survivor_coach.mdl"
#define MODEL_ROCHELLE		"models/survivors/survivor_producer.mdl"
#define MODEL_ELLIS			"models/survivors/survivor_mechanic.mdl"


new Handle:g_Cvar_MaxIncaps;
static bool:g_bIsRagdollFixEnabled, g_bIsOldTalker;

static iDeathBody[MAXPLAYERS + 1] = 0;
static iDeathScene[MAXPLAYERS + 1] = 0;

static MODEL_LOUIS_INDEX;
static MODEL_FRANCIS_INDEX;
static MODEL_BILL_INDEX;
static MODEL_ZOEY_INDEX;

/* Plugin Functions */
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:s_GameFolder[32];
	GetGameFolderName(s_GameFolder, sizeof(s_GameFolder));
	if (!StrEqual(s_GameFolder, "left4dead2", false))
	{
		strcopy(error, err_max, "This plugin is for Left 4 Dead 2 Only!");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateTimer(1.0, TimerUpdate, _, TIMER_REPEAT);
	CreateConVar("l4d2_mourn_fix_version", PLUGIN_VERSION, "Current Version of Survivor Mourn Fix", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	HookEvent("map_transition", Event_maptransition);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	
	g_Cvar_MaxIncaps = FindConVar(CVAR_SURVIVOR_MAX_INCAP_COUNT);
	if (g_Cvar_MaxIncaps == INVALID_HANDLE)
	{
		SetFailState("Unable to find \"%s\" cvar", CVAR_SURVIVOR_MAX_INCAP_COUNT);
	}
	
	new Handle:RagdollFixEnabled = CreateConVar("enable_ragdoll_fix", "0", "Enable Fix for servers with Ragdoll deaths? 0 = Disable Ragdoll Fix, 1 = Enable Ragdoll Fix", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(RagdollFixEnabled, ConVarRagdollFixEnabled);
	g_bIsRagdollFixEnabled = GetConVarBool(RagdollFixEnabled);
	
	new Handle:SurvivorDeathNameSayEnabled = CreateConVar("enable_death_name_say", "1", "Enable fix for L4D1 survivors saying name of L4D1 survivor that died? 0 = Disable (if using Last Stand talker), 1 = Enable (if using old talker mod or modified talker)", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(SurvivorDeathNameSayEnabled, ConVarSurvivorDeathNameSayEnabled);
	g_bIsOldTalker = GetConVarBool(SurvivorDeathNameSayEnabled);
	
	AutoExecConfig(true, "l4d2_survivor_mourn_fix");
	HookEvent("player_hurt", PlayerHurt_Event);
}

public OnMapStart()
{
	CheckModelPreCache(MODEL_NICK);
	CheckModelPreCache(MODEL_ROCHELLE);
	CheckModelPreCache(MODEL_COACH);
	CheckModelPreCache(MODEL_ELLIS);
	CheckModelPreCache(MODEL_BILL);
	CheckModelPreCache(MODEL_ZOEY);
	CheckModelPreCache(MODEL_FRANCIS);
	CheckModelPreCache(MODEL_LOUIS);
	
	MODEL_LOUIS_INDEX = PrecacheModel(MODEL_LOUIS, true);
	MODEL_FRANCIS_INDEX = PrecacheModel(MODEL_FRANCIS, true);
	MODEL_BILL_INDEX = PrecacheModel(MODEL_BILL, true);
	MODEL_ZOEY_INDEX = PrecacheModel(MODEL_ZOEY, true);
}

public Action:TimerUpdate(Handle:timer)
{
	if (!IsServerProcessing())return Plugin_Continue;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i))
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
					if (distance <= 200.0)
					{
						iDeathBody[i] = entity;
						MournSurvivor(i);
						iDeathScene[i] = 1;
					}
				}
			}
			else if (iDeathBody[i] > 0 && iDeathScene[i] == 0)
			{
				new String:classname[128];
				if (IsValidEntity(iDeathBody[i]))
				{
					GetEntityClassname(iDeathBody[i], classname, sizeof(classname));
					GetEntPropVector(iDeathBody[i], Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(Origin, TOrigin);
					if (distance <= 200.0 && StrEqual(classname, "survivor_death_model"))
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
					GetEntPropVector(iDeathBody[i], Prop_Send, "m_vecOrigin", TOrigin);
					new Float:distance = GetVectorDistance(Origin, TOrigin);
					if (distance > 200.0)
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
	return Plugin_Continue;
}

stock MournSurvivor(client)
{
	if (IsClientZoey(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client) && IsPlayerAlive(client))
	{
		new random = GetRandomInt(1, 5);
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/TeenGirl/GriefManager03.vcd");
				case 2:PerformSceneEx(client, "", "scenes/TeenGirl/GriefManager08.vcd");
				case 3:PerformSceneEx(client, "", "scenes/TeenGirl/GriefManager09.vcd");
				case 4:PerformSceneEx(client, "", "scenes/TeenGirl/GriefManager11.vcd");
				case 5:PerformSceneEx(client, "", "scenes/TeenGirl/GriefManager12.vcd");
			}
		}
		else if (index == MODEL_BILL_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/TeenGirl/GriefVet02.vcd");
				case 2:PerformSceneEx(client, "", "scenes/TeenGirl/GriefVet03.vcd");
				case 3:PerformSceneEx(client, "", "scenes/TeenGirl/GriefVet12.vcd");
				case 4:PerformSceneEx(client, "", "scenes/TeenGirl/GriefVet07.vcd");
				case 5:PerformSceneEx(client, "", "scenes/TeenGirl/GriefVet11.vcd");
			}
		}
		else if (index == MODEL_FRANCIS_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/TeenGirl/GriefBiker01.vcd");
				case 2:PerformSceneEx(client, "", "scenes/TeenGirl/GriefBiker02.vcd");
				case 3:PerformSceneEx(client, "", "scenes/TeenGirl/GriefBiker04.vcd");
				case 4:PerformSceneEx(client, "", "scenes/TeenGirl/GriefBiker06.vcd");
				case 5:PerformSceneEx(client, "", "scenes/TeenGirl/GriefBiker07.vcd");
			}
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/TeenGirl/Generic10.vcd");
				case 2:PerformSceneEx(client, "", "scenes/TeenGirl/Generic10.vcd");
				case 3:PerformSceneEx(client, "", "scenes/TeenGirl/Generic10.vcd");
				case 4:PerformSceneEx(client, "", "scenes/TeenGirl/Generic10.vcd");
				case 5:PerformSceneEx(client, "", "scenes/TeenGirl/Generic10.vcd");
			}
		}
	}
	
	else if (IsClientBill(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client) && IsPlayerAlive(client))
	{
		new random = GetRandomInt(1, 5);
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/NamVet/C6DLC3LOUISDIES03.vcd");
				case 2:PerformSceneEx(client, "", "scenes/NamVet/C6DLC3LOUISDIES04.vcd");
				case 3:PerformSceneEx(client, "", "scenes/NamVet/GriefManager01.vcd");
				case 4:PerformSceneEx(client, "", "scenes/NamVet/GriefManager02.vcd");
				case 5:PerformSceneEx(client, "", "scenes/NamVet/GriefManager03.vcd");
			}
		}
		else if (index == MODEL_BILL_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/NamVet/GriefBiker03.vcd");
				case 2:PerformSceneEx(client, "", "scenes/NamVet/GriefManager03.vcd");
				case 3:PerformSceneEx(client, "", "scenes/NamVet/GriefBiker03.vcd");
				case 4:PerformSceneEx(client, "", "scenes/NamVet/GriefManager03.vcd");
				case 5:PerformSceneEx(client, "", "scenes/NamVet/GriefBiker03.vcd");
			}
		}
		else if (index == MODEL_FRANCIS_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/NamVet/C6DLC3FRANCISDIES03.vcd");
				case 2:PerformSceneEx(client, "", "scenes/NamVet/C6DLC3FRANCISDIES04.vcd");
				case 3:PerformSceneEx(client, "", "scenes/NamVet/GriefBiker01.vcd");
				case 4:PerformSceneEx(client, "", "scenes/NamVet/GriefBiker02.vcd");
				case 5:PerformSceneEx(client, "", "scenes/NamVet/GriefBiker03.vcd");
			}
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/NamVet/C6DLC3ZOEYDIES02.vcd");
				case 2:PerformSceneEx(client, "", "scenes/NamVet/C6DLC3ZOEYDIES03.vcd");
				case 3:PerformSceneEx(client, "", "scenes/NamVet/C6DLC3ZOEYDIES06.vcd");
				case 4:PerformSceneEx(client, "", "scenes/NamVet/GriefTeengirl01.vcd");
				case 5:PerformSceneEx(client, "", "scenes/NamVet/GriefTeengirl02.vcd");
			}
		}
	}
	else if (IsClientFrancis(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client) && IsPlayerAlive(client))
	{
		new random = GetRandomInt(1, 5);
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Biker/GriefManager01.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Biker/C6DLC3LOUISDIES02.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Biker/GriefManager03.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Biker/GriefManager04.vcd");
				case 5:PerformSceneEx(client, "", "scenes/Biker/GriefManager05.vcd");
			}
		}
		else if (index == MODEL_BILL_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Biker/C6DLC3BILLDIES01.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Biker/C6DLC3BILLDIES06.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Biker/GriefVet01.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Biker/GriefVet02.vcd");
				case 5:PerformSceneEx(client, "", "scenes/Biker/GriefVet03.vcd");
			}
		}
		else if (index == MODEL_FRANCIS_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Biker/DLC1_C6M3_Loss01.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Biker/DLC1_C6M3_Loss02.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Biker/GriefManager02.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Biker/GriefManager03.vcd");
				case 5:PerformSceneEx(client, "", "scenes/Biker/GriefManager05.vcd");
			}
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Biker/C6DLC3ZOEYDIES01.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Biker/GriefFemaleGeneric03.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Biker/GriefTeengirl01.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Biker/GriefTeengirl02.vcd");
				case 5:PerformSceneEx(client, "", "scenes/Biker/GriefTeengirl02.vcd");
			}
		}
	}
	
	else if (IsClientLouis(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client) && IsPlayerAlive(client))
	{
		new random = GetRandomInt(1, 8);
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES03.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES04.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES03.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES04.vcd");
				case 5:PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES03.vcd");
				case 6:PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES04.vcd");
				case 7:PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES03.vcd");
				case 8:PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES04.vcd");
			}
		}
		else if (index == MODEL_BILL_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Manager/C6DLC3BILLDIES04.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Manager/C6DLC3BILLDIES05.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Manager/GriefVet01.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Manager/GriefVet03.vcd");
				case 5:PerformSceneEx(client, "", "scenes/Manager/GriefVet04.vcd");
				case 6:PerformSceneEx(client, "", "scenes/Manager/GriefVet06.vcd");
				case 7:PerformSceneEx(client, "", "scenes/Manager/GriefVet07.vcd");
				case 8:PerformSceneEx(client, "", "scenes/Manager/GriefVet08.vcd");
			}
		}
		else if (index == MODEL_FRANCIS_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES03.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Manager/C6DLC3FRANCISDIES04.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Manager/GriefBiker01.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Manager/GriefBiker04.vcd");
				case 5:PerformSceneEx(client, "", "scenes/Manager/GriefBiker05.vcd");
				case 6:PerformSceneEx(client, "", "scenes/Manager/GriefBiker07.vcd");
				case 7:PerformSceneEx(client, "", "scenes/Manager/GriefBiker07.vcd");
				case 8:PerformSceneEx(client, "", "scenes/Manager/GriefBiker05.vcd");
			}
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Manager/GriefTeengirl01.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Manager/GriefTeengirl02.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Manager/GriefTeengirl03.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Manager/GriefTeengirl04.vcd");
				case 5:PerformSceneEx(client, "", "scenes/Manager/GriefTeengirl05.vcd");
				case 6:PerformSceneEx(client, "", "scenes/Manager/GriefTeengirl06.vcd");
				case 7:PerformSceneEx(client, "", "scenes/Manager/GriefTeengirl07.vcd");
				case 8:PerformSceneEx(client, "", "scenes/Manager/GriefTeengirl08.vcd");
			}
		}
	}
	else if (IsClientEllis(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client) && IsPlayerAlive(client))
	{
		new random = GetRandomInt(1, 5);
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Mechanic/SurvivorMournNick03.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B100.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B102.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B147.vcd");
				case 5:PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B148.vcd");
			}
		}
		else if (index == MODEL_BILL_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Mechanic/SurvivorMournGamblerC101.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B100.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B102.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B147.vcd");
				case 5:PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B148.vcd");
			}
		}
		else if (index == MODEL_FRANCIS_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Mechanic/DLC1_C6M3_FinaleFinalGas10.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B100.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B102.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B147.vcd");
				case 5:PerformSceneEx(client, "", "scenes/Mechanic/WorldC1M1B148.vcd");
			}
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/mechanic/survivormournproducerc101.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Mechanic/DLC1_C6M3_FinaleFinalGas02.vcd");
				case 3:PerformSceneEx(client, "", "scenes/mechanic/survivormournproducerc102.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Mechanic/DLC1_C6M3_FinaleFinalGas05.vcd");
				case 5:PerformSceneEx(client, "", "scenes/Mechanic/DLC1_C6M3_FinaleFinalGas04.vcd");
			}
		}
	}
	else if (IsClientFrancis(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client) && IsPlayerAlive(client))
	{
		new random = GetRandomInt(1, 5);
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Biker/GriefManager01.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Biker/C6DLC3LOUISDIES02.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Biker/GriefManager03.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Biker/GriefManager04.vcd");
				case 5:PerformSceneEx(client, "", "scenes/Biker/GriefManager05.vcd");
			}
		}
		else if (index == MODEL_BILL_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Biker/C6DLC3BILLDIES01.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Biker/C6DLC3BILLDIES06.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Biker/GriefVet01.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Biker/GriefVet02.vcd");
				case 5:PerformSceneEx(client, "", "scenes/Biker/GriefVet03.vcd");
			}
		}
		else if (index == MODEL_FRANCIS_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Biker/DLC1_C6M3_Loss01.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Biker/DLC1_C6M3_Loss02.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Biker/GriefManager02.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Biker/GriefManager03.vcd");
				case 5:PerformSceneEx(client, "", "scenes/Biker/GriefManager05.vcd");
			}
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Biker/C6DLC3ZOEYDIES01.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Biker/GriefFemaleGeneric03.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Biker/GriefTeengirl01.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Biker/GriefTeengirl02.vcd");
				case 5:PerformSceneEx(client, "", "scenes/Biker/GriefTeengirl02.vcd");
			}
		}
	}
	else if (IsClientCoach(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client) && IsPlayerAlive(client))
	{
		new random = GetRandomInt(1, 4);
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX || index == MODEL_BILL_INDEX || index == MODEL_FRANCIS_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Coach/SurvivorMournMechanicC101.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Coach/WorldC2M112.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Coach/WorldC2M113.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Coach/SurvivorMournMechanicC101.vcd");
			}
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Coach/SurvivorMournProducerC101.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Coach/SurvivorMournProducerC102.vcd");
				case 3:PerformSceneEx(client, "", "scenes/Coach/SurvivorMournRochelle01.vcd");
				case 4:PerformSceneEx(client, "", "scenes/Coach/SurvivorMournRochelle03.vcd");
			}
		}
	}
	else if (IsClientNick(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client) && IsPlayerAlive(client))
	{
		new random = GetRandomInt(1, 2);
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX || index == MODEL_BILL_INDEX || index == MODEL_FRANCIS_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Gambler/SurvivorMournMechanicC102.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Gambler/SurvivorMournMechanicC102.vcd");
			}
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			switch (random)
			{
				case 1:PerformSceneEx(client, "", "scenes/Gambler/SurvivorMournProducerC101.vcd");
				case 2:PerformSceneEx(client, "", "scenes/Gambler/SurvivorMournProducerC102.vcd");
			}
		}
	}
	else if (IsClientRochelle(client) && iDeathBody[client] > 0 && IsValidEntity(iDeathBody[client]) && !IsActorBusy(client) && IsPlayerAlive(client))
	{
		new index = GetEntProp(iDeathBody[client], Prop_Data, "m_nModelIndex");
		if (index == MODEL_LOUIS_INDEX || index == MODEL_BILL_INDEX)
		{
			PerformSceneEx(client, "", "scenes/Producer/SurvivorMournGamblerC101.vcd");
		}
		else if (index == MODEL_ZOEY_INDEX)
		{
			PerformSceneEx(client, "", "scenes/Producer/Generic02.vcd"); EmitSoundToAll("player/survivor/voice/producer/generic02.wav", client, SNDCHAN_VOICE);
		}
		else if (index == MODEL_FRANCIS_INDEX)
		{
			PerformSceneEx(client, "", "scenes/Producer/DLC1_C6M3_FinaleChat10.vcd");
		}
	}
}

public PlayerHurt_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bIsRagdollFixEnabled)
	{
		return 
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if (!IsSurvivor(client))
	{
		return 
	}
	
	new health = GetEventInt(event, "health")
	
	if (health > 0)
	{
		return 
	}
	
	// Check for Witch attack
	new witch = GetEventInt(event, "attackerentid")
	new String:classname[16]
	new bool:isWitchAttack = false
	if (witch > 0 && witch < MAXENTITIES && IsValidEntity(witch))
	{
		GetEdictClassname(witch, classname, sizeof(classname))
		isWitchAttack = StrEqual(classname, "witch") || StrEqual(classname, "witch_bride")
	}
	
	if (!isWitchAttack && !L4D_IsPlayerIncapacitated(client) && L4D_GetPlayerReviveCount(client) < GetConVarInt(g_Cvar_MaxIncaps))
	{
		return 
	}
	
	SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 1)
	
	new weapon = GetPlayerWeaponSlot(client, _:L4DWeaponSlot_Secondary)
	if (weapon > 0 && weapon < MAXENTITIES && IsValidEntity(weapon))
	{
		SDKHooks_DropWeapon(client, weapon) // Drop their secondary weapon since they cannot be defibed
	}
	
	new entity;
	new String:modelname[128];
	GetEntPropString(client, Prop_Data, "m_ModelName", modelname, 128);
	
	entity = CreateEntityByName("survivor_death_model");
	SetEntityModel(entity, modelname);
	
	new Float:g_Origin[3];
	new Float:g_Angle[3];
	
	GetClientAbsOrigin(client, g_Origin);
	GetClientAbsAngles(client, g_Angle);
	
	TeleportEntity(entity, g_Origin, g_Angle, NULL_VECTOR);
	DispatchSpawn(entity);
	SetEntityRenderMode(entity, RENDER_NONE);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bIsOldTalker)
	{
		return 
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid")); // Player that died
	
	if (!IsSurvivor(client))
	{
		return;
	}
	
	//PrintToChatAll("Player %N has died!", client);
	// In here we fix L4D1 survivors not screaming the names of other L4D1 survivors when they die in set 2
	if (IsClientZoey(client)) // Zoey died
	{
		bool ZoeyDied = false;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsSurvivor(i) && IsPlayerAlive(i) && !IsActorBusy(i))
			{
				if (IsClientNick(i) && !ZoeyDied)
				{
					// We introduce a random chance so its not always the first person responding
					int i_rand = GetRandomInt(1, 4);
					if (i_rand == 1)
					{
						PerformSceneEx(i, "", "scenes/gambler/dlc1_c6m3_finalel4d1killing04.vcd", 1.0);
						ZoeyDied = true; // we set flag so only 1 person says it
					}
				}
				else if (IsClientEllis(i) && !ZoeyDied)
				{
					int i_rand = GetRandomInt(1, 4);
					if (i_rand == 1)
					{
						PerformSceneEx(i, "", "scenes/mechanic/dlc1_c6m3_finalel4d1killing11.vcd", 1.0);
						ZoeyDied = true;
					}
				}
				else if (IsClientCoach(i) && !ZoeyDied)
				{
					int i_rand = GetRandomInt(1, 4);
					if (i_rand == 1)
					{
						PerformSceneEx(i, "", "scenes/coach/nameproducerc103.vcd", 1.0);
						ZoeyDied = true;
					}
				}
				// Fix L4D1 survivors not screaming name of other L4D1 survivor that died
				else if (IsClientBill(i) && !ZoeyDied)
				{
					int i_rand = GetRandomInt(1, 4);
					if (i_rand == 1)
					{
						int randscene = GetRandomInt(1, 3);
						switch (randscene)
						{
							case 1:PerformSceneEx(i, "", "scenes/NamVet/C6DLC3ZOEYDIES01.vcd", 1.0);
							case 2:PerformSceneEx(i, "", "scenes/NamVet/C6DLC3ZOEYDIES04.vcd", 1.0);
							case 3:PerformSceneEx(i, "", "scenes/NamVet/NameZoey01.vcd", 1.0);
						}
						ZoeyDied = true;
					}
				}
				else if (IsClientLouis(i) && !ZoeyDied)
				{
					int i_rand = GetRandomInt(1, 4);
					if (i_rand == 1)
					{
						int randscene = GetRandomInt(1, 3);
						switch (randscene)
						{
							case 1:PerformSceneEx(i, "", "scenes/Manager/GriefTeengirl06.vcd", 1.0);
							case 2:PerformSceneEx(i, "", "scenes/Manager/NameZoey01.vcd", 1.0);
							case 3:PerformSceneEx(i, "", "scenes/Manager/NameZoey02.vcd", 1.0);
						}
						ZoeyDied = true;
					}
				}
				else if (IsClientFrancis(i) && !ZoeyDied)
				{
					int i_rand = GetRandomInt(1, 4);
					if (i_rand == 1)
					{
						int randscene = GetRandomInt(1, 4);
						switch (randscene)
						{
							case 1:PerformSceneEx(i, "", "scenes/Biker/C6DLC3ZOEYDIES02.vcd", 1.0);
							case 2:PerformSceneEx(i, "", "scenes/Biker/C6DLC3ZOEYDIES03.vcd", 1.0);
							case 3:PerformSceneEx(i, "", "scenes/Biker/NameZoey01.vcd", 1.0);
							case 4:PerformSceneEx(i, "", "scenes/Biker/NameZoey02.vcd", 1.0);
						}
						ZoeyDied = true;
					}
				}
			}
		}
	}
	else if (IsClientFrancis(client)) // Francis Died
	{
		bool FrancisDied = false;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsSurvivor(i) && IsPlayerAlive(i) && !IsActorBusy(i))
			{
				if (IsClientEllis(i) && !FrancisDied)
				{
					int i_rand = GetRandomInt(1, 3);
					if (i_rand == 1)
					{
						PerformSceneEx(i, "", "scenes/mechanic/dlc1_c6m3_finalel4d1killing13.vcd", 1.0);
						FrancisDied = true;
					}
				}
				else if (IsClientRochelle(i) && !FrancisDied)
				{
					int i_rand = GetRandomInt(1, 3);
					if (i_rand == 1)
					{
						PerformSceneEx(i, "", "scenes/producer/dlc1_c6m3_finalel4d1killing04.vcd", 1.0);
						FrancisDied = true;
					}
				}
				//L4D1
				else if (IsClientBill(i) && !FrancisDied)
				{
					int i_rand = GetRandomInt(1, 3);
					if (i_rand == 1)
					{
						int randscene = GetRandomInt(1, 3);
						switch (randscene)
						{
							case 1:PerformSceneEx(i, "", "scenes/NamVet/C6DLC3FRANCISDIES01.vcd", 1.0);
							case 2:PerformSceneEx(i, "", "scenes/NamVet/NameFrancis01.vcd", 1.0);
							case 3:PerformSceneEx(i, "", "scenes/NamVet/NameFrancis02.vcd", 1.0);
						}
						FrancisDied = true;
					}
				}
				else if (IsClientLouis(i) && !FrancisDied)
				{
					int i_rand = GetRandomInt(1, 3);
					if (i_rand == 1)
					{
						int randscene = GetRandomInt(1, 5);
						switch (randscene)
						{
							case 1:PerformSceneEx(i, "", "scenes/Manager/C6DLC3FRANCISDIES02.vcd", 1.0);
							case 2:PerformSceneEx(i, "", "scenes/Manager/C6DLC3FRANCISDIES05.vcd", 1.0);
							case 3:PerformSceneEx(i, "", "scenes/Manager/GriefBiker01.vcd", 1.0);
							case 4:PerformSceneEx(i, "", "scenes/Manager/GriefBiker07.vcd", 1.0);
							case 5:PerformSceneEx(i, "", "scenes/Manager/NameFrancis02.vcd", 1.0);
						}
						FrancisDied = true;
					}
				}
				else if (IsClientZoey(i) && !FrancisDied)
				{
					int i_rand = GetRandomInt(1, 3);
					if (i_rand == 1)
					{
						int randscene = GetRandomInt(1, 4);
						switch (randscene)
						{
							case 1:PerformSceneEx(i, "", "scenes/TeenGirl/C6DLC3FRANCISDIES01.vcd", 1.0);
							case 2:PerformSceneEx(i, "", "scenes/TeenGirl/C6DLC3FRANCISDIES02.vcd", 1.0);
							case 3:PerformSceneEx(i, "", "scenes/TeenGirl/GriefBiker02.vcd", 1.0);
							case 4:PerformSceneEx(i, "", "scenes/TeenGirl/GriefBiker04.vcd", 1.0);
						}
						FrancisDied = true;
					}
				}
			}
		}
	}
	else if (IsClientLouis(client))
	{
		bool LouisDied = false;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsSurvivor(i) && IsPlayerAlive(i) && !IsActorBusy(i))
			{
				if (IsClientEllis(i) && !LouisDied)
				{
					int i_rand = GetRandomInt(1, 4);
					if (i_rand == 1)
					{
						PerformSceneEx(i, "", "scenes/mechanic/dlc1_c6m3_finalel4d1killing20.vcd", 1.0);
					}
					LouisDied = true;
				}
				//L4D1
				else if (IsClientBill(i) && !LouisDied)
				{
					int i_rand = GetRandomInt(1, 3);
					if (i_rand == 1)
					{
						int randscene = GetRandomInt(1, 2);
						switch (randscene)
						{
							case 1:PerformSceneEx(i, "", "scenes/NamVet/C6DLC3LOUISDIES01.vcd", 1.0);
							case 2:PerformSceneEx(i, "", "scenes/NamVet/NameLouis01.vcd", 1.0);
						}
						LouisDied = true;
					}
				}
				else if (IsClientFrancis(i) && !LouisDied)
				{
					int i_rand = GetRandomInt(1, 3);
					if (i_rand == 1)
					{
						int randscene = GetRandomInt(1, 3);
						switch (randscene)
						{
							case 1:PerformSceneEx(i, "", "scenes/Biker/C6DLC3LOUISDIES06.vcd", 1.0);
							case 2:PerformSceneEx(i, "", "scenes/Biker/NameLouis01.vcd", 1.0);
							case 3:PerformSceneEx(i, "", "scenes/Biker/NameLouis02.vcd", 1.0);
						}
						LouisDied = true;
					}
				}
				else if (IsClientZoey(i) && !LouisDied)
				{
					int i_rand = GetRandomInt(1, 3);
					if (i_rand == 1)
					{
						int randscene = GetRandomInt(1, 3);
						switch (randscene)
						{
							case 1:PerformSceneEx(i, "", "scenes/TeenGirl/C6DLC3LOUISDIES04.vcd", 1.0);
							case 2:PerformSceneEx(i, "", "scenes/TeenGirl/C6DLC3LOUISDIES05.vcd", 1.0);
							case 3:PerformSceneEx(i, "", "scenes/TeenGirl/GriefManager02.vcd", 1.0);
						}
						LouisDied = true;
					}
				}
			}
		}
		
	}
}

stock CheckModelPreCache(const String:Modelfile[])
{
	if (!IsModelPrecached(Modelfile))
	{
		PrecacheModel(Modelfile, true);
		PrintToServer("Precaching Model:%s", Modelfile);
	}
}

/* stock bools to identify which survivors is who */
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
		decl String:model[84];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_NICK, false))
		{
			return true;
		}
		
	}
	return false;
}
stock bool:IsClientRochelle(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[84];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_ROCHELLE, false))
		{
			return true;
		}
		
	}
	return false;
}
stock bool:IsClientCoach(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[42];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_COACH, false))
		{
			return true;
		}
		
	}
	return false;
}
stock bool:IsClientEllis(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[42];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_ELLIS, false))
		{
			return true;
		}
		
	}
	return false;
}
stock bool:IsClientBill(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[42];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_BILL, false))
		{
			return true;
		}
		
	}
	return false;
}
stock bool:IsClientZoey(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[42];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_ZOEY, false))
		{
			return true;
		}
		
	}
	return false;
}
stock bool:IsClientLouis(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[42];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_LOUIS, false))
		{
			return true;
		}
		
	}
	return false;
}
stock bool:IsClientFrancis(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[42];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_FRANCIS, false))
		{
			return true;
		}
		
	}
	return false;
}

public ConVarRagdollFixEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bIsRagdollFixEnabled = GetConVarBool(convar);
}

public ConVarSurvivorDeathNameSayEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bIsOldTalker = GetConVarBool(convar);
}

public Action:Event_maptransition(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 0; i < MAXPLAYERS; i++)
	{
		iDeathBody[i] = 0;
		iDeathScene[i] = 0;
	}
}
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 0; i < MAXPLAYERS; i++)
	{
		iDeathBody[i] = 0;
		iDeathScene[i] = 0;
	}
}
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 0; i < MAXPLAYERS; i++)
	{
		iDeathBody[i] = 0;
		iDeathScene[i] = 0;
	}
}

public OnMapEnd()
{
	for (new i = 0; i < MAXPLAYERS; i++)
	{
		iDeathBody[i] = 0;
		iDeathScene[i] = 0;
	}
}

