#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.5.1"

//#define WEARABLE_NAMES "plugin_burnanim_wearable_%i"
//#define WEARABLE_MOVETO_RAG "plugin_burnanim_ragdoll_%i"
#define DEATHANIM_TARGET "plugin_burnanim_anim_%i"

#define MODEL_SCOUT "models/player/scout.mdl"
#define MODEL_SOLDIER "models/player/soldier.mdl"
#define MODEL_PYRO "models/player/pyro.mdl"
#define MODEL_DEMO "models/player/demo.mdl"
#define MODEL_HEAVY "models/player/heavy.mdl"
#define MODEL_ENGINEER "models/player/engineer.mdl"
#define MODEL_MEDIC "models/player/medic.mdl"
#define MODEL_SNIPER "models/player/sniper.mdl"
#define MODEL_SPY "models/player/spy.mdl"

static Handle burnAnim;
static Handle sillyDeaths;
static Handle cvar_burnAnimChance;

// DEVELOPMENT INFO
// Scout - "primary_death_burning" - 88 frames
// Soldier - "primary_death_burning" - 116 frames
// Pyro - No burning taunt
// Demoman - "PRIMARY_death_burning" - 67 frames
// Heavy - "PRIMARY_death_burning" - 92 frames
// Engineer - "PRIMARY_death_burning" - 103 frames
// Medic - "primary_death_burning" - 100 frames
// Sniper - "primary_death_burning" - 131 frames
// Spy - "primary_death_burning" - 57 frames

static bool isMVM = true;

//These values are used mainly to time when the final ragdoll will be made.
//They can be adjusted to provide a cleaner transition should a better one not be possible.

static const float g_AnimationTimes[][] = {
	{ 0.0 } /* Unknown */,
	{ /* 2:28 */ 3.2 } /* Scout */,
	{ /* 4:11 */ 4.7 } /* Sniper */, 	
	{ /* 3:26 */ 4.2 } /* Soldier */,
	{ /* 2:07 */ 2.5 } /* Demoman */,
	{ /* 3:10 */ 3.6 } /* Medic */, 
	{ /* 3:02 */ 3.5 } /* Heavy */,	
	{ /* 0:00 */ 0.0 } /* Pyro */,
	{ /* 1:27 */ 2.2 } /* Spy */,
	{ /* 3:13 */ 3.8 } /* Engineer */
};

static int g_ClientAnimEntity[MAXPLAYERS+1] = 0;

public Plugin myinfo = 
{
	name = "[TF2] Burning Death Animations",
	author = "404: User Not Found / Rowedahelicon / Shadowysn",
	description = "Adds in the unused burning death animations.",
	version = PLUGIN_VERSION,
	url = "http://www.unfgaming.net / http://www.rowedahelicon.com"
}

public void OnPluginStart()
{	
	CreateConVar("sm_burnanim_version", PLUGIN_VERSION, "[TF2] Burning Death Animations", FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	burnAnim = CreateConVar("sm_burnanim", "1", "Enables the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	sillyDeaths = CreateConVar("sm_sillydeaths", "1", "Enables death anims for the scout and the demo.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvar_burnAnimChance = CreateConVar("sm_burnanim_chance", "1.0", "Chance of animation to play on death (0.0 - 1.0)", FCVAR_NONE);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public void OnMapStart()
{
	PrecacheGeneric("particles/burningplayer.pcf", true); //This may not be needed, but was at the recommendation to code changes seen in CS:GO.
	isMVM = CheckIfMVM();
}

//-----------------------------------------------------------------------------
// Purpose: Hooking player_death event
//-----------------------------------------------------------------------------
void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	float rand = GetRandomFloat(0.0, 1.0);
	
	if (!GetConVarBool(burnAnim) || GetConVarFloat(cvar_burnAnimChance) < rand) return;
	
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	//int customkill = GetEventInt(event, "customkill");
	
	if (!IsValidClient(victim)) return;
	
	char temp_str[32];
	Format(temp_str, sizeof(temp_str), DEATHANIM_TARGET, victim);
	int old_burnanim = FindEntityByTargetname(-1, temp_str);
	if (RealValidEntity(old_burnanim)) AcceptEntityInput(old_burnanim, "Kill");
	
	// Check if victim is a Pyro
	TFClassType victimClass = TF2_GetPlayerClass(victim);
	int team = GetClientTeam(victim);

	if (isMVM)
	{
		if (team == 3) return;
	}
	
	if (victimClass == TFClass_Pyro || !IsValidClient(attacker) || !(GetEntityFlags(victim) & FL_ONGROUND)) return; //Will not fire if the victim is a pyro or died in the sky.
	
	if (GetConVarInt(sillyDeaths) == 0 && (victimClass == TFClass_Scout || victimClass == TFClass_DemoMan)) return;  //For Silly deaths turned off
	
	/*TFClassType attackerClass = TF2_GetPlayerClass(attacker);
	if (attackerClass == TFClass_Pyro)
	{
		switch (customkill)
		{
			case 3, 8, 17, 46, 47, 53: // Burning, Burning Flare, Burning Arrow, Plasma, Plasma Charged, Flare Pellet
			{
				int g_BurnAnim = 0;
				RequestFrame(RemoveBody, victim);
				AttachNewPlayerModel(victim, g_BurnAnim);
				CreateTimer(g_AnimationTimes[TF2_GetPlayerClass(victim)][g_BurnAnim], Timer_EndBurningDeath, victim, TIMER_FLAG_NO_MAPCHANGE);
			}
			default:
			{
			}
		}
	}*/
	if (TF2_IsPlayerInCondition(victim, TFCond_OnFire))
	{
		//int g_BurnAnim = 0;
		RequestFrame(RemoveBody, victim);
		//AttachNewPlayerModel(victim, g_BurnAnim);
		AttachNewPlayerModel(victim);
	}
}

void RemoveBody(int client)
{
	if (!IsValidClient(client)) return;
	
	int BodyRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	
	if (RealValidEntity(BodyRagdoll))
	{
		AcceptEntityInput(BodyRagdoll, "kill");
	}
}


//-----------------------------------------------------------------------------
// Purpose: Create fake player model
//-----------------------------------------------------------------------------
//void AttachNewPlayerModel(int client, int g_BurnAnim)
void AttachNewPlayerModel(int client)
{
	/*TFClassType playerClass = TF2_GetPlayerClass(client);
	if (playerClass == TFClass_Engineer || playerClass == TFClass_DemoMan || playerClass == TFClass_Heavy)
	{
		g_BurnAnim+=1;
	}*/
		
	int model = CreateEntityByName("prop_dynamic_override");
	if (RealValidEntity(model))
	{
		float pos[3], angles[3];
		char clientmodel[256], skin[2];
		
		int team = GetClientTeam(client);
		
		GetClientModel(client, clientmodel, sizeof(clientmodel));
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(model, pos, NULL_VECTOR, NULL_VECTOR);
		GetClientEyeAngles(client, angles);
		angles[0] = 0.0;
		angles[2] = 0.0;
		IntToString(team-2, skin, sizeof(skin));
		
		DispatchKeyValue(model, "skin", skin);
		DispatchKeyValue(model, "model", clientmodel);
		//DispatchKeyValue(model, "DefaultAnim", g_Animations[g_BurnAnim]);
		//DispatchKeyValue(model, "DefaultAnim", "primary_death_burning");
		DispatchKeyValueVector(model, "angles", angles);
		
		char temp_str[128];
		Format(temp_str, sizeof(temp_str), DEATHANIM_TARGET, client);
		DispatchKeyValue(model, "targetname", temp_str);
		
		SetEntProp(model, Prop_Data, "m_iTeamNum", team);
		
		DispatchSpawn(model);
		ActivateEntity(model);
		
		RecreateWearables(client, model);
		
		//SetVariantString(g_Animations[g_BurnAnim]);
		SetVariantString("primary_death_burning");
		AcceptEntityInput(model, "SetAnimation");
		
		//SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
		//AcceptEntityInput(model, "AddOutput");
		
		/*char temp_str[128];
		Format(temp_str, sizeof(temp_str), "OnUser1 !self:KillHierarchy::%f:1", g_AnimationTimes[TF2_GetPlayerClass(client)][0]+0.1); 
		SetVariantString(temp_str);
		AcceptEntityInput(model, "AddOutput");*/
		
		g_ClientAnimEntity[client] = model;
		
		if (TE_SetupTFParticle("burningplayer_corpse", pos, _, _, model, 3, 0, false))
		TE_SendToAll(0.0); //See note at bottom	
		
		float timer_for_removal = (g_AnimationTimes[TF2_GetPlayerClass(client)][0])-0.4;
		
		//Format(temp_str, sizeof(temp_str), "OnUser1 !self:BecomeRagdoll::%f:-1", timer_for_removal);
		Format(temp_str, sizeof(temp_str), "OnUser1 !self:Kill::%f:-1", timer_for_removal+1.0);
		SetVariantString(temp_str);
		AcceptEntityInput(model, "AddOutput");
		
		AcceptEntityInput(model, "FireUser1");
		//Dissolve(model, timer_for_removal);
		
		DataPack pack = CreateDataPack();
		pack.WriteCell(client);
		pack.WriteCell(model);
		CreateTimer(timer_for_removal, SpawnRagdoll, pack);
	}
}

Action SpawnRagdoll(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int model = pack.ReadCell();
	if (pack != null)
	{ CloseHandle(pack); }
	if (!RealValidEntity(model)) return;
	
	int ragdoll = CreateEntityByName("tf_ragdoll");
	if (!RealValidEntity(ragdoll)) return;
	
	float pos[3], ang[3];
	GetEntPropVector(model, Prop_Data, "m_vecOrigin", pos);
	GetEntPropVector(model, Prop_Data, "m_angRotation", ang);
	SetEntPropVector(ragdoll, Prop_Data, "m_vecOrigin", pos);
	SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollOrigin", pos);
	SetEntPropVector(ragdoll, Prop_Data, "m_angRotation", ang);
	
	//char rag_name[64];
	//Format(rag_name, sizeof(rag_name), WEARABLE_MOVETO_RAG, model);
	//DispatchKeyValue(ragdoll, "targetname", rag_name);
	
	TFClassType class = GetClassFromModel(model);
	
	//PrintToServer("class is: %i", class);
	SetEntProp(ragdoll, Prop_Send, "m_iClass", class);
	SetEntProp(ragdoll, Prop_Send, "m_iTeam", GetEntProp(model, Prop_Data, "m_iTeamNum"));
	SetEntProp(ragdoll, Prop_Data, "m_nSkin", GetEntProp(model, Prop_Send, "m_nSkin"));
	SetEntProp(ragdoll, Prop_Data, "m_nBody", GetEntProp(model, Prop_Send, "m_nBody"));
	
	float Vel[3];
	//Vel[0] = -2048.0;
	//Vel[1] = -2048.0;
	Vel[2] = -20480.0;
	
	//SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollVelocity", Vel);
	SetEntPropVector(ragdoll, Prop_Send, "m_vecForce", Vel);
	
	//SetEntPropEnt(ragdoll, Prop_Send, "m_iPlayerIndex", client);
	
	SetEntProp(ragdoll, Prop_Send, "m_bBurning", 1);
	
	SetEntProp(ragdoll, Prop_Send, "m_nForceBone", 0);
	SetEntProp(ragdoll, Prop_Send, "m_bOnGround", 0);
	
	SetEntPropFloat(ragdoll, Prop_Send, "m_flHeadScale", 1.0);
	SetEntPropFloat(ragdoll, Prop_Send, "m_flTorsoScale", 1.0);
	SetEntPropFloat(ragdoll, Prop_Send, "m_flHandScale", 1.0);
	
	DispatchSpawn(ragdoll);
	ActivateEntity(ragdoll);
	
	if (IsValidClient(client))
	{
		int old_rag = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if (RealValidEntity(old_rag))
		{ AcceptEntityInput(old_rag, "Kill"); }
		SetEntPropEnt(client, Prop_Send, "m_hRagdoll", ragdoll);
	}
	//else
	//{
	SetVariantString("OnUser1 !self:Kill::15.0:-1");
	AcceptEntityInput(ragdoll, "AddOutput");
	AcceptEntityInput(ragdoll, "FireUser1");
	//}
	
	SetVariantString("OnUser1 !self:Kill::0.01:-1");
	AcceptEntityInput(model, "AddOutput");
	AcceptEntityInput(model, "FireUser1");
	
	for (int i = -1; i < GetMaxEntities(); i++)
	{
		if (!RealValidEntity(i)) continue;
		
		if (!HasEntProp(i, Prop_Send, "moveparent")) continue;
		int moveparent = GetEntPropEnt(i, Prop_Send, "moveparent");
		if (moveparent != model) continue;
		
		char classname[14];
		GetEntityClassname(i, classname, sizeof(classname));
		if (StrContains(classname, "prop_dynamic", false) < 0) continue;
		
		float pos_i[3];
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", pos_i);
		pos_i[2] = pos_i[2]-5000.0;
		TeleportEntity(i, pos_i, NULL_VECTOR, NULL_VECTOR);
		
		SetVariantString("!activator");
		AcceptEntityInput(i, "SetParent", ragdoll);
	}
}

TFClassType GetClassFromModel(int entity)
{
	char temp_str[PLATFORM_MAX_PATH+1];
	GetEntPropString(entity, Prop_Data, "m_ModelName", temp_str, sizeof(temp_str));
	
	if (StrEqual(temp_str, MODEL_SCOUT, false)) return TFClass_Scout;
	else if (StrEqual(temp_str, MODEL_SNIPER, false)) return TFClass_Sniper;
	else if (StrEqual(temp_str, MODEL_SOLDIER, false)) return TFClass_Soldier;
	else if (StrEqual(temp_str, MODEL_DEMO, false)) return TFClass_DemoMan;
	else if (StrEqual(temp_str, MODEL_MEDIC, false)) return TFClass_Medic;
	else if (StrEqual(temp_str, MODEL_HEAVY, false)) return TFClass_Heavy;
	else if (StrEqual(temp_str, MODEL_PYRO, false)) return TFClass_Pyro;
	else if (StrEqual(temp_str, MODEL_SPY, false)) return TFClass_Spy;
	else if (StrEqual(temp_str, MODEL_ENGINEER, false)) return TFClass_Engineer;
	return TFClass_Unknown;
}

//-----------------------------------------------------------------------------
// Purpose: Valid client check stock
//-----------------------------------------------------------------------------

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

//-----------------------------------------------------------------------------
// Purpose: Check if the mode running is MVM
//-----------------------------------------------------------------------------

bool CheckIfMVM()
{
	int i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
	if (i > MaxClients && RealValidEntity(i)) return true;
	
	return false;
}

//-----------------------------------------------------------------------------
// Purpose: Create the fake wearables for the death animation model
//-----------------------------------------------------------------------------

void RecreateWearables(int client, int entity)
{
	if (!IsValidClient(client) || !RealValidEntity(entity)) return;
	
	SetEntProp(entity, Prop_Send, "m_nSkin", GetEntProp(client, Prop_Send, "m_nSkin"));
	SetEntProp(entity, Prop_Send, "m_nBody", GetEntProp(client, Prop_Send, "m_nBody"));
	
	for (int i = -1; i < GetMaxEntities(); i++)
	{
		if (!RealValidEntity(i)) continue;
		
		if (!HasEntProp(i, Prop_Send, "moveparent")) continue;
		int check_cl = GetEntPropEnt(i, Prop_Send, "moveparent");
		if (check_cl != client) continue;
		
		char classname[32];
		GetEntityClassname(i, classname, sizeof(classname));
		if (StrContains(classname, "tf_wearable", false) < 0) continue;
		
		if (view_as<bool>(GetEntProp(i, Prop_Send, "m_bDisguiseWearable"))) continue;
		
		//PrintToServer("m_clrRender: %i", GetEntProp(i, Prop_Send, "m_clrRender"));
		
		//CreateAndAttachWearable(i, entity, classname);
		CreateAndAttachWearable(i, entity, GetEntProp(i, Prop_Send, "m_nSkin"), GetEntProp(i, Prop_Send, "m_nBody"));
	}
}

void CreateAndAttachWearable(int refer_wear, int new_owner, int skin = -1, int body = -1)
{
	int wear = CreateEntityByName("prop_dynamic_override");
	if (!RealValidEntity(wear)) return;
	
	//char temp_str[32];
	//Format(temp_str, sizeof(temp_str), WEARABLE_NAMES, new_owner);
	//DispatchKeyValue(wear, "targetname", temp_str);
	
	char wear_model[PLATFORM_MAX_PATH+1];
	GetEntPropString(refer_wear, Prop_Data, "m_ModelName", wear_model, sizeof(wear_model));
	
	SetEntityModel(wear, wear_model);
	
	int cl_team = GetEntProp(refer_wear, Prop_Send, "m_iTeamNum");
	if (skin < 0)
	{ SetEntProp(wear, Prop_Data, "m_nSkin", (cl_team == 3) ? 1 : 0); }
	else
	{ SetEntProp(wear, Prop_Data, "m_nSkin", skin); }
	if (body >= 0)
	{ SetEntProp(wear, Prop_Data, "m_nBody", body); }
	
	SetEntProp(wear, Prop_Send, "m_iTeamNum", cl_team);
	
	SetEntPropEnt(wear, Prop_Send, "m_hOwnerEntity", new_owner);
	DispatchKeyValue(wear, "solid", "0");
	//SetEntProp(wear, Prop_Send, "m_CollisionGroup", 1);
	
	float pos[3], ang[3];
	GetEntPropVector(new_owner, Prop_Data, "m_vecOrigin", pos);
	GetEntPropVector(new_owner, Prop_Data, "m_angRotation", ang);
	
	TeleportEntity(wear, pos, ang, NULL_VECTOR);
	
	DispatchSpawn(wear);
	ActivateEntity(wear);
	
	SetVariantString("!activator");
	AcceptEntityInput(wear, "SetParent", new_owner);
	SetVariantString("head");
	AcceptEntityInput(wear, "SetParentAttachment");
	
	SetEntProp(wear, Prop_Send, "m_fEffects", (0x001 + 0x080)); //EF_BONEMERGE + EF_BONEMERGE_FASTCULL
}

//-----------------------------------------------------------------------------
// Purpose: Gives fire particles to anim models
//-----------------------------------------------------------------------------

bool TE_SetupTFParticle(const char[] name,
			float origin[3] = NULL_VECTOR,
			float start[3] = NULL_VECTOR,
			float angles[3] = NULL_VECTOR,
			int entindex = -1,
			int attachtype = -1,
			int attachpoint = -1,
			bool resetParticles = true)
{
	// find string table
	int tblidx = FindStringTable("ParticleEffectNames");
	if (tblidx == INVALID_STRING_TABLE)
	{
		LogError("Could not find string table: ParticleEffectNames");
		return false;
	}
	
	// find particle index
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;
	
	for (int i = 0; i < count; i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if (StrEqual(tmp, name, false))
		{
			stridx = i;
			break;
		}
	}
	if (stridx == INVALID_STRING_INDEX)
	{
		LogError("Could not find particle: %s", name);
		return false;
	}
	
	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", origin[0]);
	TE_WriteFloat("m_vecOrigin[1]", origin[1]);
	TE_WriteFloat("m_vecOrigin[2]", origin[2]);
	TE_WriteFloat("m_vecStart[0]", start[0]);
	TE_WriteFloat("m_vecStart[1]", start[1]);
	TE_WriteFloat("m_vecStart[2]", start[2]);
	TE_WriteVector("m_vecAngles", angles);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	
	if (entindex != -1)
	{
		TE_WriteNum("entindex", entindex);
	}
	if (attachtype != -1)
	{
		TE_WriteNum("m_iAttachType", attachtype);
	}
	if (attachpoint != -1)
	{
		TE_WriteNum("m_iAttachmentPointIndex", 1);
	}
	TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);
	return true;
}

//-----------------------------------------------------------------------------
// Purpose: Dissolve the ragdoll with a delay parameter
//-----------------------------------------------------------------------------

/*void Dissolve(int entity, float delay = 0.0)
{
	if (!RealValidEntity(entity)) return;
	
	int ent = CreateEntityByName("env_entity_dissolver");
	if (RealValidEntity(ent))
	{
		//DispatchKeyValue(ent, "dissolvetype", 0);
		DispatchKeyValue(ent, "target", "!activator");
		
		char temp_str[64];
		
		Format(temp_str, sizeof(temp_str), "OnUser1 !self:Dissolve::%f:-1", delay);
		SetVariantString(temp_str);
		AcceptEntityInput(ent, "AddOutput");
		Format(temp_str, sizeof(temp_str), "OnUser1 !self:Kill::%f:-1", delay);
		SetVariantString(temp_str);
		AcceptEntityInput(ent, "AddOutput");
		
		AcceptEntityInput(ent, "FireUser1", entity);
	}
}*/

int FindEntityByTargetname(int index, const char[] findname)
{
	for (int i = index; i < GetMaxEntities(); i++) {
		if (!RealValidEntity(i)) continue;
		char name[128];
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		if (!StrEqual(name, findname, false)) continue;
		return i;
	}
	return -1;
}

bool RealValidEntity(int entity)
{
	if (entity <= 0 || !IsValidEntity(entity)) return false;
	return true;
}