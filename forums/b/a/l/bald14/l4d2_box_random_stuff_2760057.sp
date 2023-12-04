#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required
bool isMapRunning = false;

#define MODEL_PILLS "models/w_models/weapons/w_eq_painpills.mdl"
#define MODEL_ADRENALINE "models/w_models/weapons/w_eq_adrenaline.mdl"
#define MODEL_FIRST_AID_KIT "models/w_models/weapons/w_eq_Medkit.mdl"
#define MODEL_BOX "models/props_junk/wood_crate001a.mdl"
#define MODEL_BOX2 "models/props_junk/wood_crate002a.mdl"
#define MODEL_MOLOTOV "models/w_models/weapons/w_eq_molotov.mdl"
#define MODEL_PIPE_BOMB "models/w_models/weapons/w_eq_pipebomb.mdl"
#define MODEL_VOMITJAR "models/w_models/weapons/w_eq_bile_flask.mdl"
#define MODEL_DEFIB "models/w_models/weapons/w_eq_defibrillator.mdl"
#define MODEL_EXP "models/w_models/weapons/w_eq_explosive_ammopack.mdl"
#define MODEL_INC "models/w_models/weapons/w_eq_incendiary_ammopack.mdl"
 
char Electables[][] = 
{	 
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_vomitjar",
	"weapon_defibrillator", 
	"weapon_pain_pills",
	"weapon_adrenaline",
	"weapon_first_aid_kit",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_box", box_spawn, ADMFLAG_ROOT);
	RegAdminCmd("sm_box1", box_spawn2, ADMFLAG_ROOT);
	RegAdminCmd("sm_hop", box_spawn, ADMFLAG_ROOT);
	RegAdminCmd("sm_hop1", box_spawn2, ADMFLAG_ROOT);
}
 
public void OnMapStart()
{
	PrecacheModel("models/props_junk/wood_crate001a.mdl", true);
	PrecacheModel("models/props_junk/wood_crate002a.mdl", true);
	isMapRunning = true;
}

public void OnMapEnd()
{
	isMapRunning = false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (isMapRunning && IsServerProcessing())
	{
		return;
	}
	if (IsValidEdict(entity))
	{
		SDKHook(entity, SDKHook_SpawnPost, SpawnPost);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (isMapRunning && IsServerProcessing())
	{
		return;
	}
	if (!IsValidEntity(entity))
	{
		return;
	}
}

public void SpawnPost(int entity)
{
	RequestFrame(nextFrame, EntIndexToEntRef(entity));
}

public void nextFrame(int entity)
{
	if((entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE)
	{
		SDKHook(entity, SDKHook_SpawnPost, SpawnPost);
		
		char model[128];
		GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrContains(model, "wood_crate001a.mdl")!= -1 || StrContains(model, "wood_crate002a.mdl")!= -1)
		{
			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	char model[128];
	int random;
 
	float ent_pos[3];
	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", ent_pos);
	
	GetEntPropString(victim, Prop_Data, "m_ModelName", model, sizeof(model));
	if(!IsValidEntity(victim))	return Plugin_Continue;
	if (StrContains(model, "wood_crate001a.mdl")!= -1 || StrContains(model, "wood_crate002a.mdl")!= -1)
	{
		SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamage);
		random = GetRandomInt(0, sizeof(Electables));
		switch(random) 
		{
			case 1: 
			{
				int molotov = CreateEntityByName("weapon_molotov");
				DispatchSpawn(molotov);
				SetEntityModel(molotov, MODEL_MOLOTOV);
				TeleportEntity(molotov, ent_pos, NULL_VECTOR, NULL_VECTOR);				
				AcceptEntityInput(victim, "break");
			}
			case 2: 
			{
				int pipe = CreateEntityByName("weapon_pipe_bomb");
				DispatchSpawn(pipe);
				SetEntityModel(pipe, MODEL_PIPE_BOMB);
				TeleportEntity(pipe, ent_pos, NULL_VECTOR, NULL_VECTOR);				
				AcceptEntityInput(victim, "break");
			}
			case 3: 
			{
				int vomitjar = CreateEntityByName("weapon_vomitjar");
				DispatchSpawn(vomitjar);
				SetEntityModel(vomitjar, MODEL_VOMITJAR);
				TeleportEntity(vomitjar, ent_pos, NULL_VECTOR, NULL_VECTOR);				
				AcceptEntityInput(victim, "break");
			}
			case 4: 
			{
				int defib = CreateEntityByName("weapon_defibrillator");
				DispatchSpawn(defib);
				SetEntityModel(defib, MODEL_DEFIB);
				TeleportEntity(defib, ent_pos, NULL_VECTOR, NULL_VECTOR);				
				AcceptEntityInput(victim, "break");
			}
			case 5: 
			{
				int pain_pills = CreateEntityByName("weapon_pain_pills");
				DispatchSpawn(pain_pills);
				SetEntityModel(pain_pills, MODEL_PILLS);
				TeleportEntity(pain_pills, ent_pos, NULL_VECTOR, NULL_VECTOR);				
				AcceptEntityInput(victim, "break");
			}
			case 6: 
			{	
				int adrenaline = CreateEntityByName("weapon_adrenaline");
				DispatchSpawn(adrenaline);
				SetEntityModel(adrenaline, MODEL_ADRENALINE);
				TeleportEntity(adrenaline, ent_pos, NULL_VECTOR, NULL_VECTOR);
				AcceptEntityInput(victim, "break");
			}
			case 7:
			{			
				int kit = CreateEntityByName("weapon_first_aid_kit");
				DispatchSpawn(kit);
				SetEntityModel(kit, MODEL_FIRST_AID_KIT);
				TeleportEntity(kit, ent_pos, NULL_VECTOR, NULL_VECTOR);							
				AcceptEntityInput(victim, "break");
			}			
			case 8: 
			{
				int pack_exp = CreateEntityByName("weapon_upgradepack_explosive");
				if(IsValidEntity(pack_exp))
				{
					DispatchSpawn(pack_exp);
					SetEntityModel(pack_exp, MODEL_EXP);
					TeleportEntity(pack_exp, ent_pos, NULL_VECTOR, NULL_VECTOR);					
					AcceptEntityInput(victim, "break");
				}
			}
			case 9: 
			{
				int pack_inc = CreateEntityByName("weapon_upgradepack_incendiary");
				if(IsValidEntity(pack_inc))
				{
					DispatchSpawn(pack_inc);
					SetEntityModel(pack_inc, MODEL_INC);
					TeleportEntity(pack_inc, ent_pos, NULL_VECTOR, NULL_VECTOR);					
					AcceptEntityInput(victim, "break");
				}
			}
		}
	}
	return Plugin_Continue;
}
 
public Action box_spawn(int client, int args)
{
	float Look[3];
	GetLookPos(client, Look);
	Look[2] += 20;
	int karobka = CreateEntityByName("prop_physics");
	if (karobka > MaxClients)
	{
		DispatchKeyValueVector(karobka, "origin", Look);
		SetEntityModel(karobka, MODEL_BOX);
		DispatchSpawn(karobka);
		SDKHook(karobka, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}
 
public Action box_spawn2(int client, int args)
{
	float Look[3];
	GetLookPos(client, Look);
	Look[2] += 20;
	int karobka = CreateEntityByName("prop_physics");
	if (karobka > MaxClients)
	{
		DispatchKeyValueVector(karobka, "origin", Look);
		SetEntityModel(karobka, MODEL_BOX2);
		DispatchSpawn(karobka);
		SDKHook(karobka, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}
 
stock float GetLookPos(int client, float v[3])
{
     float EyePosition[3], EyeAngles[3];
     Handle h_trace;
     GetClientEyePosition(client, EyePosition);
     GetClientEyeAngles(client, EyeAngles);
     h_trace = TR_TraceRayFilterEx(EyePosition, EyeAngles, MASK_SOLID, RayType_Infinite, GetLookPos_Filter, client);
     TR_GetEndPosition(v, h_trace);
     CloseHandle(h_trace);
}
 
public bool GetLookPos_Filter(int ent, int mask, any client)
{
      return client != ent;
}  