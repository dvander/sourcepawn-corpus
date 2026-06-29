#define PLUGIN_NAME "[TF2] Serverside Ragdolls"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Use commands to force server ragdolls for players."
#define PLUGIN_VERSION "1.0.1"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=337392"
#define PLUGIN_NAME_SHORT "Serverside Ragdolls"
#define PLUGIN_NAME_TECH "tf_server_ragdoll"

#include <sourcemod>
#include <sdktools>
//#include <sdkhooks>
#include <adminmenu>
#include <tf2_stocks>

#pragma newdecls required
#pragma semicolon 1

#define AUTOEXEC_CFG "ImportantRagdoll"

#define DEBUG 0
//#define wear_name "plugin_RagLooseWear"
//#define wear_name_charnum 19
#define rag_name "plugin_svRagdoll"
#define rag_name_charnum 16

#define CMD_INVALID_CL "[SM] Invalid client!"
#define CMD_DEAD_CL "[SM] Client is not a living player!"

#define CVAR_BF_FORCE_RED (1 << 0)
#define CVAR_BF_FORCE_BLU (1 << 1)

int doServerRagdoll[MAXPLAYERS+1] = {0};
bool g_infiniteRagdoll[MAXPLAYERS+1] = {false};
//bool g_hasRecentRagdoll[MAXPLAYERS+1] = {false};
int g_Ragdoll[MAXPLAYERS+1] = {0};

TopMenu hTopMenu;

ConVar cvar_Collision, cvar_ForceEnable;
int g_iCollision, g_iForceEnable;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	if (ev == Engine_TF2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Team Fortress 2.");
	return APLRes_SilentFailure;
}

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		version_cvar.SetString(PLUGIN_VERSION);
	
	Format(cmd_str, sizeof(cmd_str), "%s_collision", PLUGIN_NAME_TECH);
	cvar_Collision = CreateConVar(cmd_str, "1", "Which collision to use for server ragdolls.\n0 = None. (Collide with everything)\n1 = Debris. (Don't collide with players or everything else, like projectiles)\n2 = Pushaway. (collide with everything except players)", FCVAR_NONE, true, 0.0, true, 2.0);
	cvar_Collision.AddChangeHook(CC_IR_Collision);
	
	Format(cmd_str, sizeof(cmd_str), "%s_force", PLUGIN_NAME_TECH);
	cvar_ForceEnable = CreateConVar(cmd_str, "0", "Force ragdolls to automatically be server sided on the specified teams. (THESE ARE BITFLAGS, COMBINE THEM)\n1 = RED\n2 = BLU", FCVAR_NONE, true, 0.0, true, 3.0);
	cvar_ForceEnable.AddChangeHook(CC_IR_ForceEnable);
	
	AutoExecConfig(true, AUTOEXEC_CFG);
	SetCvarValues();
	
	RegAdminCmd("sm_svrag", ForceServerRagdoll_Cmd, ADMFLAG_CHEATS, 
	"sm_svrag <client> - Manually force server ragdoll on a specified player.");
	
	HookEvent("player_death", player_death, EventHookMode_Post);
	
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
	
	LoadTranslations("common.phrases");
	
	#if DEBUG
	RegAdminCmd("sm_ir_ping", Ping_CMD, ADMFLAG_CHEATS, "Ping");
	#endif
}

void CC_IR_Collision(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_iCollision =		convar.IntValue;	}
void CC_IR_ForceEnable(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_iForceEnable =	convar.IntValue;	}
void SetCvarValues()
{
	CC_IR_Collision(cvar_Collision, "", "");
	CC_IR_ForceEnable(cvar_ForceEnable, "", "");
}

public void OnPluginEnd()
{
	for (int client = 1; client <= MAXPLAYERS; client++)
	{
		RemoveSVRagdoll(client);
	}
}

public void OnClientDisconnect(int client)
{
	doServerRagdoll[client] = 0;
	g_infiniteRagdoll[client] = false;
	//g_hasRecentRagdoll[client] = false;
	RemoveSVRagdoll(client);
}

void RemoveSVRagdoll(int client)
{
	if (RealValidEntity(g_Ragdoll[client]))
	{
		AcceptEntityInput(g_Ragdoll[client], "Kill");
		g_Ragdoll[client] = 0;
	}
}

bool shouldRemoveRag = false;

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!shouldRemoveRag || classname[0] != 't') return;
	
	if (strcmp(classname, "tf_ragdoll", false) == 0)
	{
		AcceptEntityInput(entity, "Kill");
	}
}

public void OnEntityDestroyed(int entity)
{
	static char nameChk[rag_name_charnum+1];
	GetEntityClassname(entity, nameChk, sizeof(nameChk));
	if (nameChk[0] != 'p' || strncmp(nameChk, "prop_ragdoll", 12, false) != 0) return;
	GetEntPropString(entity, Prop_Data, "m_iName", nameChk, sizeof(nameChk));
	if (strcmp(nameChk, rag_name, false) != 0) return;
	
	int moveChild = GetEntPropEnt(entity, Prop_Data, "m_hMoveChild");
	if (!RealValidEntity(moveChild)) return;
	
	for (int i = 0; i >= 6; i++)
	{
		#if DEBUG
		PrintToServer("foundEnt: %i", moveChild);
		#endif
		int movePeer = GetEntPropEnt(moveChild, Prop_Data, "m_hMovePeer");
		if (!RealValidEntity(movePeer))
		{ i = 6; continue; }
		else
		{
			int oldChild = moveChild;
			moveChild = movePeer;
			AcceptEntityInput(oldChild, "Kill");
		}
	}
}

/*public void OnEntityCreated(int entity, const char[] classname)
{
	if (!RealValidEntity(entity)) return;
	if (strcmp(classname, "tf_ragdoll", false) != 0) return;
	
	RequestFrame(RequestFrame_OnEntityCreated, entity);
}
void RequestFrame_OnEntityCreated(int entity)
{
	if (!RealValidEntity(entity)) return;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_iPlayerIndex");
	if (!IsValidClient(owner) || !g_hasRecentRagdoll[owner]) return;
	g_hasRecentRagdoll[owner] = false;
	
	AcceptEntityInput(entity, "Kill");
}*/

#if DEBUG
Action Ping_CMD(int client, int args)
{
	if (!IsValidClient(client)) return Plugin_Handled;
	
	for (int i = -1; i < GetMaxEntities(); i++)
	{
		if (!RealValidEntity(i)) continue;
		
		static char classname[12];
		GetEntityClassname(i, classname, sizeof(classname));
		if (strcmp(classname, "tf_wearable", false) != 0) continue;
		
		PrintToServer("Found %s. ID = %i", classname, i);
		
		PrintToServer("moveparent: %i", GetEntPropEnt(i, Prop_Send, "moveparent"));
		PrintToServer("m_CollisionGroup: %i", GetEntProp(i, Prop_Send, "m_CollisionGroup"));
		static char temp_str[PLATFORM_MAX_PATH+1];
		GetEntPropString(i, Prop_Data, "m_ModelName", temp_str, sizeof(temp_str));
		PrintToServer("m_ModelName: %s", temp_str);
	}
	
	/*bool isDisguiseWep = true;
	int active_wep = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
	if (!RealValidEntity(active_wep))
	{ active_wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"); isDisguiseWep = false; }
	if (!RealValidEntity(active_wep)) return Plugin_Handled;
	
	if (!isDisguiseWep) PrintToServer("No disguise wep! Using active wep.");
	
	PrintToServer("m_iItemDefinitionIndex: %i", GetEntProp(active_wep, Prop_Send, "m_iItemDefinitionIndex"));
	PrintToServer("m_iEntityLevel: %i", GetEntProp(active_wep, Prop_Send, "m_iEntityLevel"));
	PrintToServer("m_iItemIDHigh: %i", GetEntProp(active_wep, Prop_Send, "m_iItemIDHigh"));
	PrintToServer("m_iItemIDLow: %i", GetEntProp(active_wep, Prop_Send, "m_iItemIDLow"));
	PrintToServer("m_iAccountID: %i", GetEntProp(active_wep, Prop_Send, "m_iAccountID"));
	PrintToServer("m_iEntityQuality: %i", GetEntProp(active_wep, Prop_Send, "m_iEntityQuality"));
	PrintToServer("m_bOnlyIterateItemViewAttributes: %i", GetEntProp(active_wep, Prop_Send, "m_bOnlyIterateItemViewAttributes"));
	PrintToServer("m_iTeamNumber: %i", GetEntProp(active_wep, Prop_Send, "m_iTeamNumber"));
	PrintToServer("m_iTeamNum: %i", GetEntProp(active_wep, Prop_Send, "m_iTeamNum"));
	PrintToServer("m_iState: %i", GetEntProp(active_wep, Prop_Send, "m_iState"));
	PrintToServer("m_CollisionGroup: %i", GetEntProp(active_wep, Prop_Send, "m_CollisionGroup"));
	PrintToServer("m_bInitialized: %i", GetEntProp(active_wep, Prop_Send, "m_bInitialized"));
	PrintToServer("moveparent: %i", GetEntPropEnt(active_wep, Prop_Send, "moveparent"));
	PrintToServer("m_hMoveParent: %i", GetEntPropEnt(active_wep, Prop_Data, "m_hMoveParent"));
	PrintToServer("movetype: %i", GetEntProp(active_wep, Prop_Send, "movetype"));
	PrintToServer("movecollide: %i", GetEntProp(active_wep, Prop_Send, "movecollide"));
	PrintToServer("m_hOwner: %i", GetEntPropEnt(active_wep, Prop_Send, "m_hOwner"));
	PrintToServer("m_hOwnerEntity: %i", GetEntPropEnt(active_wep, Prop_Send, "m_hOwnerEntity"));
	PrintToServer("m_fEffects: %i", GetEntProp(active_wep, Prop_Send, "m_fEffects"));*/
	
	return Plugin_Handled;
}
#endif

void RecreateWearables(int client, int entity)
{
	if (!IsValidClient(client) || !RealValidEntity(entity)) return;
	
	SetEntProp(entity, Prop_Send, "m_nSkin", GetEntProp(client, Prop_Send, "m_nSkin"));
	SetEntProp(entity, Prop_Send, "m_nBody", GetEntProp(client, Prop_Send, "m_nBody"));
	
	for (int i = -1; i < GetMaxEntities(); i++)
	{
		if (!RealValidEntity(i)) continue;
		
		static char classname[12];
		GetEntityClassname(i, classname, sizeof(classname));
		if (strcmp(classname, "tf_wearable", false) != 0) continue;
		
		int check_cl = GetEntPropEnt(i, Prop_Send, "moveparent");
		if (check_cl != client) continue;
		
		//CreateAndAttachWearable(i, entity, classname);
		CreateAndAttachWearable(i, entity, GetEntProp(i, Prop_Send, "m_nSkin"), GetEntProp(i, Prop_Send, "m_nBody"));
	}
}

/*void CreateAndAttachWearable(int refer_wear, int new_owner, const char[] classname)
{
	int wear = CreateEntityByName(classname);
	if (!RealValidEntity(wear)) return;
	
	static char wear_model[PLATFORM_MAX_PATH+1];
	GetEntPropString(refer_wear, Prop_Data, "m_ModelName", wear_model, sizeof(wear_model));
	
	SetEntityModel(wear, wear_model);
	
	int cl_team = GetEntProp(refer_wear, Prop_Send, "m_iTeamNumber");
	SetEntProp(wear, Prop_Data, "m_nSkin", (cl_team == 3) ? 1 : 0);
	
	SetEntProp(wear, Prop_Send, "m_iItemDefinitionIndex", GetEntProp(refer_wear, Prop_Send, "m_iItemDefinitionIndex"));
	SetEntProp(wear, Prop_Send, "m_iEntityLevel", GetEntProp(refer_wear, Prop_Send, "m_iEntityLevel"));
	SetEntProp(wear, Prop_Send, "m_iEntityQuality", GetEntProp(refer_wear, Prop_Send, "m_iEntityQuality"));
	
	SetEntProp(wear, Prop_Send, "m_iTeamNum", cl_team);
	SetEntProp(wear, Prop_Send, "m_iTeamNumber", cl_team);
	SetEntProp(wear, Prop_Send, "m_bInitialized", 1);
	
	SetEntPropEnt(wear, Prop_Send, "m_hOwnerEntity", new_owner);
	SetEntProp(wear, Prop_Send, "m_CollisionGroup", 11);
	
	float pos[3], ang[3];
	GetEntPropVector(new_owner, Prop_Data, "m_vecOrigin", pos);
	GetEntPropVector(new_owner, Prop_Data, "m_angRotation", ang);
	
	TeleportEntity(wear, pos, ang, NULL_VECTOR);
	
	DispatchSpawn(wear);
	ActivateEntity(wear);
	
	SetEntProp(wear, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	SetVariantString("!activator");
	AcceptEntityInput(wear, "SetParent", new_owner);
	
	SetEntProp(wear, Prop_Send, "m_fEffects", (0x001 + 0x080)); //EF_BONEMERGE + EF_BONEMERGE_FASTCULL
}*/

void CreateAndAttachWearable(int refer_wear, int new_owner, int skin = -1, int body = -1)
{
	static char wear_model[PLATFORM_MAX_PATH+1];
	GetEntPropString(refer_wear, Prop_Data, "m_ModelName", wear_model, sizeof(wear_model));
	#if DEBUG
	PrintToServer("MODEL: %s", wear_model);
	#endif
	if (wear_model[0] == '\0') return;
	
	int wear = CreateEntityByName("prop_dynamic_override");
	if (!RealValidEntity(wear)) return;
	
	//CreateTimer(0.1, CheckWearable, EntIndexToEntRef(wear), TIMER_FLAG_NO_MAPCHANGE);
	
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
	ang[2] = 0.0;
	
	//TeleportEntity(wear, pos, ang, NULL_VECTOR);
	DispatchKeyValueVector(wear, "origin", pos); DispatchKeyValueVector(wear, "angles", ang);
	
	//DispatchKeyValue(wear, "targetname", wear_name);
	
	DispatchSpawn(wear);
	ActivateEntity(wear);
	
	SetVariantString("!activator");
	AcceptEntityInput(wear, "SetParent", new_owner);
	SetVariantString("head");
	AcceptEntityInput(wear, "SetParentAttachment");
	
	SetEntProp(wear, Prop_Send, "m_fEffects", (0x001 + 0x080)); //EF_BONEMERGE + EF_BONEMERGE_FASTCULL
}

/*Action CheckWearable(Handle timer, int wear)
{
	wear = EntRefToEntIndex(wear);
	if (!RealValidEntity(wear)) return;
	
	if (!RealValidEntity(GetEntPropEnt(wear, Prop_Send, "moveparent")))
	{
		AcceptEntityInput(wear, "Kill");
		PrintToServer("IMPORTANTRAGDOLL: Found an invalid fake wearable! Removing it.");
	}
}*/

void player_death(Event event, const char[] name, bool dontBroadcast) 
{
	int userid = event.GetInt("userid", 0);
	int client = GetClientOfUserId(userid);

	if (!IsValidClient(client)) 
	{
		#if DEBUG
		PrintToServer("SERVERRAG: !IsValidClient");
		#endif
		return;
	}
	
	/*int death_flags = event.GetInt("death_flags", 0);
	if (death_flags & TF_DEATHFLAG_DEADRINGER)
	{
		#if DEBUG
		PrintToServer("SERVERRAG: Flags");
		#endif
		return;
	}*/
	#if DEBUG
	if (TF2_IsPlayerInCondition(client, TFCond_OnFire))
	{ PrintToServer("SERVERRAG: Was Burning"); }
	#endif
	if (doServerRagdoll[client] <= 0 && !g_infiniteRagdoll[client])
	{
		TFTeam team = TF2_GetClientTeam(client);
		if (
		(team == TFTeam_Red && !(g_iForceEnable & CVAR_BF_FORCE_RED)) || 
		(team == TFTeam_Blue && !(g_iForceEnable & CVAR_BF_FORCE_BLU))
		)
		{
			#if DEBUG
			PrintToServer("SERVERRAG: !doServerRagdoll");
			#endif
			return;
		}
	}
	
	if (!g_infiniteRagdoll[client]) doServerRagdoll[client] = doServerRagdoll[client] - 1;
	
	#if DEBUG
	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	PrintToServer("SERVERRAG: Ragdoll is, at frame of death: %i", ragdoll);
	#endif
	
	shouldRemoveRag = true;
	RequestFrame(setRemoveRag);
	
	//RequestFrame(RemoveNewRagdoll, userid);
	
	//DoBodyAction(client, GetClientOfUserId(event.GetInt("attacker", 0)));
	//RequestFrame(DoBodyAction, client);
	DoBodyAction(client);
	//int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	//if (RealValidEntity(ragdoll))
	//{ SDKHook(GetEntPropEnt(client, Prop_Send, "m_hRagdoll"), SDKHook_Spawn, DoBodyAction); }
}

void setRemoveRag()
{
	shouldRemoveRag = false;
}

/*void RemoveNewRagdoll(int client)
{
	client = GetClientOfUserId(client);
	
	if (!IsValidClient(client)) return;
	
	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	#if DEBUG
	PrintToServer("SERVERRAG: Potential ragdoll spawn detected, index is %i", ragdoll);
	#endif
	if (!RealValidEntity(ragdoll)) return;
	static char classname[32];
	GetEntityClassname(ragdoll, classname, sizeof(classname));
	if (strcmp(classname, "tf_ragdoll", false) != 0) return;
	
	AcceptEntityInput(ragdoll, "Kill");
}*/

//Action DoBodyAction(ragdoll)
void DoBodyAction(int client)
{
	if (!IsValidClient(client)) return;
	
	/*int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (!RealValidEntity(ragdoll)) return;
	if (!HasEntProp(ragdoll, Prop_Send, "m_bGib")) return;
	
	bool isGibbed = view_as<bool>(GetEntProp(ragdoll, Prop_Send, "m_bGib"));
	if (isGibbed) return;*/
	
	float pos[3], ang[3], vec[3];
	GetClientAbsOrigin(client, pos);
	GetClientAbsAngles(client, ang);
	
	static char clientModel[PLATFORM_MAX_PATH+1];
	GetClientModel(client, clientModel, sizeof(clientModel));
	
	int rag = CreateEntityByName("prop_ragdoll");
	if (!RealValidEntity(rag))
	{ return; }
	RemoveSVRagdoll(client);
	g_Ragdoll[client] = rag;
	//g_hasRecentRagdoll[client] = true;
	
	int force_Bone = GetEntProp(client, Prop_Send, "m_nForceBone");
	
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);
	float temp_force[3];
	GetEntPropVector(client, Prop_Send, "m_vecForce", temp_force);
	float multiplyBy = 50.0;
	vec[0] *= multiplyBy; vec[1] *= multiplyBy; vec[2] *= multiplyBy;
	temp_force[0] *= multiplyBy; temp_force[1] *= multiplyBy; temp_force[2] *= multiplyBy;
	//vec[0] += temp_force[0]; vec[1] += temp_force[1]; vec[2] += temp_force[2];
	//GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]", vec[0]);
	//GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]", vec[1]);
	//GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]", vec[2]);
	//AcceptEntityInput(ragdoll, "Kill");
	
	SetEntityModel(rag, clientModel);
	
	//IntToString(4 & 8192, value, sizeof(value));
	//DispatchKeyValue(rag, "spawnflags", value);
	
	DispatchKeyValueVector(rag, "origin", pos);
	DispatchKeyValueVector(rag, "angles", ang);
	
	SetEntProp(rag, Prop_Send, "m_nForceBone", force_Bone);
	SetEntPropVector(rag, Prop_Send, "m_vecForce", temp_force);
	
	DispatchKeyValue(rag, "targetname", rag_name);
	
	DispatchSpawn(rag);
	ActivateEntity(rag);
	
	if (!IsPlayerAlive(client))
	{
		//SetVariantString("!activator");
		//AcceptEntityInput(client, "SetParent", rag);
		//CreateTimer(2.0, timerView, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		SetEntPropEnt(client, Prop_Send, "m_hRagdoll", rag);
	}
	
	switch (g_iCollision)
	{
		case 0: SetEntProp(rag, Prop_Send, "m_CollisionGroup", 0); // COLLISION_GROUP_NONE
		case 1: SetEntProp(rag, Prop_Send, "m_CollisionGroup", 2); // COLLISION_GROUP_DEBRIS_TRIGGER
		case 2: SetEntProp(rag, Prop_Send, "m_CollisionGroup", 17); // COLLISION_GROUP_PUSHAWAY
	}
	TeleportEntity(rag, NULL_VECTOR, NULL_VECTOR, vec);
	
	RecreateWearables(client, rag);
	
	bool isBurning = TF2_IsPlayerInCondition(client, TFCond_OnFire);
	if (isBurning)
	{
		/*char temp_str[24];
		strcopy(temp_str, sizeof(temp_str), "burningplayer_red");
		strcopy(temp_str, sizeof(temp_str), "burningplayer_blue");
		strcopy(temp_str, sizeof(temp_str), "burningplayer_corpse");*/
		if (TE_SetupTFParticle("burningplayer_corpse", pos, NULL_VECTOR, NULL_VECTOR, rag, 3, 0, false))
		{ TE_SendToAll(0.0); }
		//if (TE_SetupTFParticle(temp_str, pos, NULL_VECTOR, NULL_VECTOR, rag, 3, 0, false))
		//{ TE_SendToAll(0.0); }
	}
	
	/*SetVariantString("OnUser1 !self:Kill::15.0:1");
	AcceptEntityInput(rag, "AddOutput");
	AcceptEntityInput(rag, "FireUser1");*/
}

/*Action timerView(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if (!IsValidClient(client)) return Plugin_Continue;
	AcceptEntityInput(client, "ClearParent");
	return Plugin_Continue;
}*/

/*void RequestFrame_RemoveRag(int client)
{
	if (!IsValidClient(client)) return;
	
	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (!RealValidEntity(ragdoll))
	{ return; }
	
	AcceptEntityInput(ragdoll, "Kill");
}

void DoBodyAction(int client, int attacker = -1)
{
	if (!IsValidClient(client)) return;
	
	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (!RealValidEntity(ragdoll))
	{ return; }
	if (GetEntProp(ragdoll, Prop_Send, "m_bGib"))
	{ return; }
	
	float pos[3];
	float ang[3];
	GetClientAbsOrigin(client, pos);
	GetClientAbsAngles(client, ang);
	
	int rag_ent = CreateEntityByName("generic_actor");
	if (!RealValidEntity(rag_ent)) return;
	RequestFrame(RequestFrame_RemoveRag, client);
	
	char clientModel[64];
	GetClientModel(client, clientModel, sizeof(clientModel));
	DispatchKeyValue(rag_ent, "model", clientModel);
	TeleportEntity(rag_ent, pos, ang, NULL_VECTOR);
	
	char value[32];
	IntToString(GetEntProp(client, Prop_Send, "m_nSkin"), value, sizeof(value));
	DispatchKeyValue(rag_ent, "skin", value);
	
	IntToString(GetEntProp(client, Prop_Send, "m_nBody"), value, sizeof(value));
	DispatchKeyValue(rag_ent, "body", value);
	
	IntToString(4 & 16 & 128 & 512 & 4096 & 8192, value, sizeof(value));
	DispatchKeyValue(rag_ent, "spawnflags", value);
	
	DispatchKeyValue(rag_ent, "health", "1");
	DispatchKeyValue(rag_ent, "max_health", "100");
	
	DispatchSpawn(rag_ent);
	ActivateEntity(rag_ent);
	
	SetEntProp(rag_ent, Prop_Data, "m_bImportanRagdoll", 1);
	
	//float temp_vec[3];
	//GetEntPropVector(client, Prop_Send, "m_vecForce", temp_vec);
	//SetEntPropVector(rag_ent, Prop_Send, "m_vecForce", temp_vec);
	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	
	float velfloat[3];
	GetEntPropVector(client, Prop_Send, "m_vecForce", velfloat);
	
	velfloat[0] += velocity[0];
	velfloat[1] += velocity[1];
	velfloat[2] += velocity[2];
	velfloat[0] *= 60.0;
	velfloat[1] *= 60.0;
	velfloat[2] *= 60.0;
	
	SetEntPropVector(rag_ent, Prop_Send, "m_vecForce", velfloat);
	
	SetEntProp(rag_ent, Prop_Send, "m_nForceBone", GetEntProp(client, Prop_Send, "m_nForceBone"));
	SetEntProp(rag_ent, Prop_Send, "m_nSequence", GetEntProp(client, Prop_Send, "m_nSequence"));
	SetEntProp(rag_ent, Prop_Send, "m_flAnimTime", GetEntProp(client, Prop_Send, "m_flAnimTime"));
	SetEntProp(rag_ent, Prop_Send, "m_flSimulationTime", GetEntProp(client, Prop_Send, "m_flSimulationTime"));
	
	// Taken from the Survivor Legs plugin by Lux https://forums.alliedmods.net/showthread.php?t=299560
	int i;
	for (i = 1; i < 23; i++)
	{
		SetEntPropFloat(rag_ent, Prop_Send, "m_flPoseParameter", GetEntPropFloat(client, Prop_Send, "m_flPoseParameter", i), i); //credit to death chaos for animating legs
	}
	
	DoDamage(rag_ent, attacker, 100.0);
}*/

Action ForceServerRagdoll_Cmd(int client, int args)
{
	if (!IsValidClient(client))
	{ return Plugin_Handled; }
	
	if (args < 1 || args > 2)
	{
		ReplyToCommand(client, "[SM] sm_svrag <client> <num>");
		return Plugin_Handled;
	}
	
	static char arg[128];
	static char arg2[4];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	bool isInfinite = false;
	int arg2_num = StringToInt(arg2, sizeof(arg2));
	if (arg2[0] == '\0')
	{ arg2_num = 1; }
	
	if (strncmp(arg2, "inf", 3, false) == 0)
	{
		isInfinite = true;
	}
	
	int target_list[MAXPLAYERS];
	int target_count = Cmd_GetTargets(client, arg, target_list, COMMAND_FILTER_CONNECTED);
	
	for (int i=0; i < target_count; i++)
	{
		int target = target_list[i];
		
		Cmd_ForceServerRagdoll(target, client, arg2_num, isInfinite);
	}
	
	return Plugin_Handled;
}

void Cmd_ForceServerRagdoll(int target, int client, int count = 1, bool isInfinite = false)
{
	if (!Cmd_CheckClient(target, client, false)) return;
	/*if (doServerRagdoll[target] > 0)
	{
		PrintToChat(client, "[SM] Already forced server ragdoll on %N.", target); return;
	}*/

	if (g_infiniteRagdoll[client] && !isInfinite)
	{
		PrintToChat(client, "[SM] Already forced infinite server ragdolls on %N.", target); return;
	}

	TFTeam team = TF2_GetClientTeam(target);
	if ((g_iForceEnable & CVAR_BF_FORCE_RED && team == TFTeam_Red) || (g_iForceEnable & CVAR_BF_FORCE_BLU && team == TFTeam_Blue))
	{
		PrintToChat(client, "[SM] tf_server_ragdoll_force is already active on %N's team!", target); return;
	}
	
	ForceServerRagdoll(target, count, isInfinite);

	static char temp_str[16];
	switch (isInfinite)
	{
		case false:
		{
			if (doServerRagdoll[target] > 1)
			{
				strcopy(temp_str, sizeof(temp_str), "lives");
			}
			else
			{
				strcopy(temp_str, sizeof(temp_str), "life");
			}
			
			if (count > 0)
			{ PrintToChat(client, "[SM] Successfully forced server ragdoll on %N for %i %s.", target, doServerRagdoll[target], temp_str); }
			else
			{ PrintToChat(client, "[SM] Server ragdolls are forced on %N for %i %s.", target, doServerRagdoll[target], temp_str); }
		}
		case true:
		{
			switch (!g_infiniteRagdoll[target])
			{
				case true:
				{
					strcopy(temp_str, sizeof(temp_str), "OFF");
				}
				case false:
				{
					strcopy(temp_str, sizeof(temp_str), "ON");
				}
			}
			
			PrintToChat(client, "[SM] Server ragdolls on %N have been toggled %s.", target, temp_str);
		}
	}
	if (!IsPlayerAlive(target))
	{
		PrintToChat(client, "[SM] %N seems to be dead right now. Still forcing server ragdoll on next life.", target);
	}
}

void ForceServerRagdoll(int client, int count = 1, bool isInfinite = false)
{
	if (!IsValidClient(client))
		return;
	
	switch (isInfinite)
	{
		case true:
		{
			switch (g_infiniteRagdoll[client])
			{
				case true: g_infiniteRagdoll[client] = false;
				case false: g_infiniteRagdoll[client] = true;
			}
		}
		case false:
		{
			if (doServerRagdoll[client] < 0) doServerRagdoll[client] = 0;
			doServerRagdoll[client] = doServerRagdoll[client] + count;
		}
	}
}

public void AdminMenu_ForceServerRag(TopMenu topmenu, 
					  TopMenuAction action,
					  TopMenuObject object_id,
					  int param,
					  char[] buffer,
					  int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Force server rag", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		ForceServerRagMenu(param);
	}
}

void ForceServerRagMenu(int client)
{
	Menu menu = new Menu(MenuHandler_ForceServerRag);
	
	static char title[24];
	Format(title, sizeof(title), "Force server rag:", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	AddTargetsToMenu(menu, client, true, false);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_ForceServerRag(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu)
		{
			hTopMenu.Display(client, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		static char info[32];
		
		menu.GetItem(param2, info, sizeof(info));
		int userid = StringToInt(info);
		int target = GetClientOfUserId(userid);
		
		Cmd_ForceServerRagdoll(target, client);
		
		if (IsValidClient(client))
		{
			ForceServerRagMenu(client);
		}
	}
	return 0;
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	if (topmenu == hTopMenu)
	{
		return;
	}
	
	hTopMenu = topmenu;
	
	TopMenuObject player_commands = hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		hTopMenu.AddItem("sm_msvrag", AdminMenu_ForceServerRag, player_commands, "A menu to force server ragdoll on a player.", ADMFLAG_CHEATS);
	}
}

//bool Cmd_CheckClient(int client, int sender = -1, bool must_be_alive = false, int team = -1, bool print = true)
bool Cmd_CheckClient(int client, int sender = -1, bool must_be_alive = false, bool print = true)
{
	if (!IsValidClient(client))
	{ if (print && IsValidClient(sender)) PrintToChat(sender, CMD_INVALID_CL); return false; }
	
	if (must_be_alive && (!IsPlayerAlive(client) || IsClientObserver(client)))
	{ if (print && IsValidClient(sender)) PrintToChat(sender, CMD_DEAD_CL); return false; }
	
	/*switch (team)
	{
		if (team > 0)
		{
			if (!IsSurvivor(client))
			{ if (print && IsValidClient(sender)) PrintToChat(sender, CMD_NOT_SURVIVOR_CL); return false; }
		}
		else if (team == 0)
		{
			if (!IsInfected(client))
			{ if (print && IsValidClient(sender)) PrintToChat(sender, CMD_NOT_INFECTED_CL); return false; }
		}
	}*/
	
	return true;
}

int Cmd_GetTargets(int client, const char[] arg, int[] target_list, int filter = COMMAND_FILTER_ALIVE)
{
	static char target_name[MAX_TARGET_LENGTH]; target_name[0] = '\0';
	int target_count;
	bool tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			filter,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{ ReplyToTargetError(client, target_count); return -1; }
	return target_count;
}

/*void DoDamage(int client, int sender, int damage, int damageType = 0)
{
	//float tpos[3], spos[3];
	//GetClientAbsOrigin(client, tpos);
	float spos[3];
	if (IsValidClient(sender))
	{ GetClientAbsOrigin(sender, spos); }
	
	char temp_str[32];
	
	int iDmgEntity = CreateEntityByName("point_hurt");
	if (IsValidClient(sender) && client != sender)
	{ TeleportEntity(iDmgEntity, spos, NULL_VECTOR, NULL_VECTOR); }
	//else
	//{ TeleportEntity(iDmgEntity, tpos, NULL_VECTOR, NULL_VECTOR); }
	
	DispatchKeyValue(iDmgEntity, "DamageTarget", "!activator");
	
	IntToString(damage, temp_str, sizeof(temp_str));
	DispatchKeyValue(iDmgEntity, "Damage", temp_str);
	IntToString(damageType, temp_str, sizeof(temp_str));
	DispatchKeyValue(iDmgEntity, "DamageType", temp_str);
	
	DispatchSpawn(iDmgEntity);
	ActivateEntity(iDmgEntity);
	AcceptEntityInput(iDmgEntity, "Hurt", client);
	AcceptEntityInput(iDmgEntity, "Kill");
}*/

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

bool RealValidEntity(int entity)
{
	if (entity <= 0 || !IsValidEntity(entity)) return false;
	return true;
}

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
	static char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;
	
	for (int i = 0; i < count; i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if (strcmp(tmp, name, false) == 0)
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