#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_NAME_SHORT "Spawn Client Ragdoll"
#define PLUGIN_NAME "[ANY] Spawn Client Ragdoll"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Spawn client-sided ragdolls that are sent to all clients."
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL ""

#define cmd_1 "sm_spawnrag"
char cmd_1_desc[128];

ConVar version_cvar = null;

static int g_isGame = 0;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() == Engine_TF2)
	{ g_isGame = 1; }
	else if(GetEngineVersion() == Engine_Left4Dead)
	{ g_isGame = 2; }
	else if(GetEngineVersion() == Engine_Left4Dead2)
	{ g_isGame = 3; }
	return APLRes_Success;
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
	char temp_str[128];
	Format(temp_str, sizeof(temp_str), "%s plugin version", PLUGIN_NAME_SHORT);
	version_cvar = CreateConVar("sm_spawn_client_rag_version", PLUGIN_VERSION, temp_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	Format(cmd_1_desc, sizeof(cmd_1_desc), "%s <model> <mode: 0=origin, 1=cursor> <animation> <delay> - spawn a clientside ragdoll", cmd_1);
	RegAdminCmd(cmd_1, Command_SpawnRagdoll, ADMFLAG_CHEATS, cmd_1_desc);
}

public Action Command_SpawnRagdoll(int client, any args)
{
	if (args < 1 || args > 4)
	{
		ReplyToCommand(client, "[SM] Usage: %s", cmd_1_desc);
		return Plugin_Handled;
	}
	
	char model[PLATFORM_MAX_PATH];
	char mode[2];
	char anim[128];
	char delay[24];
	GetCmdArg(1, model, sizeof(model));
	GetCmdArg(2, mode, sizeof(mode));
	GetCmdArg(3, anim, sizeof(anim));
	GetCmdArg(4, delay, sizeof(delay));
	
	int mode_int = StringToInt(mode);
	float delay_float = StringToFloat(delay);
	if (delay_float > 10.0) delay_float = 10.0;
	
	if (!IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] Invalid client! Unable to get position and angles!");
		return Plugin_Handled;
	}
	
	float pos[3];
	float ang[3];
	GetClientAbsOrigin(client, pos);
	GetClientAbsAngles(client, ang);
	if (mode_int >= 1)
	{
		GetClientEyePosition(client, pos);
		GetClientEyeAngles(client, ang);
		TR_TraceRayFilter(pos, ang, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, client);
		if(TR_DidHit(null))
		{
			TR_GetEndPosition(pos);
		}
		else
		{
			PrintToChat(client, "[SM] Vector out of world geometry. Teleporting on origin instead");
		}
	}
	SpawnRagdoll(client, model, pos, ang[1], anim, delay_float);
	return Plugin_Handled;
}

void SpawnRagdoll(int client, const char[] const_model, float pos[3], float yaw = 0.0, const char[] anim = "", float delay = 0.0)
{
	char model[PLATFORM_MAX_PATH];
	strcopy(model, sizeof(model), const_model);
	
	int hasText1 = StrContains(model, "models/", false);
	int hasText2 = StrContains(model, ".mdl", false);
	
	if (hasText1 <= -1 || hasText1 > 8)
	{ Format(model, sizeof(model), "models/%s", model); }
	if (hasText2 <= -1)
	{ Format(model, sizeof(model), "%s.mdl", model); }
	//PrintToChat(client, model);
	
	if (!IsModelPrecached(model))
	{
		if (PrecacheModel(model) <= 1)
		{ PrintToChat(client, "[SM] Invalid model!"); return; }
	}
	
	float new_ang[3]; new_ang[0] = 0.0; new_ang[1] = yaw; new_ang[2] = 0.0;
	
	/*char entity_str[128] = "prop_dynamic_override";
	if ((g_isGame == 2 || g_isGame == 3) && StrContains(model, "survivors", false) > -1)
	{ strcopy(entity_str, sizeof(entity_str), "commentary_dummy"); }
	PrintToChat(client, "%s", entity_str);*/
	
	int temp_prop_l4d = -1;
	int temp_prop = CreateEntityByName("prop_dynamic_override");
	if (!IsValidEntity(temp_prop)) return;
	
	//if ((g_isGame == 2 || g_isGame == 3) && StrContains(model, "survivors", false) > -1 && delay > 0.0)
	//{ temp_prop_l4d = CreateEntityByName("commentary_dummy"); }
	
	SetEntityModel(temp_prop, model);
	char new_mdl[PLATFORM_MAX_PATH];
	GetEntPropString(temp_prop, Prop_Data, "m_ModelName", new_mdl, sizeof(new_mdl));
	if (StrEqual(new_mdl, "", false) || StrEqual(new_mdl, "error.mdl", false))
	{ AcceptEntityInput(temp_prop, "Kill"); if (IsValidEntity(temp_prop_l4d)) AcceptEntityInput(temp_prop_l4d, "Kill"); return; }
	
	DispatchKeyValue(temp_prop, "solid", "0");
	
	SetEdictFlags(temp_prop, FL_EDICT_ALWAYS); // For some reason, commentary_dummy becomes absolutely invisible if this is set on it.
	
	DispatchSpawn(temp_prop);
	ActivateEntity(temp_prop);
	/*if (IsValidEntity(temp_prop_l4d))
	{
		DispatchSpawn(temp_prop_l4d);
		ActivateEntity(temp_prop_l4d);
	}*/
	
	if (!StrEqual(anim, "", false))
	{
		SetVariantString(anim);
		AcceptEntityInput(temp_prop, "SetAnimation");
	}
	
	TeleportEntity(temp_prop, pos, new_ang, NULL_VECTOR);
	//if (IsValidEntity(temp_prop_l4d)) TeleportEntity(temp_prop_l4d, pos, new_ang, NULL_VECTOR);
	
	char temp_str[128];
	
	Format(temp_str, sizeof(temp_str), "OnUser1 !self:BecomeRagdoll::%f:1", delay);
	SetVariantString(temp_str);
	AcceptEntityInput(temp_prop, "AddOutput");
	/*if (IsValidEntity(temp_prop_l4d))
	{
		SetVariantString(temp_str);
		AcceptEntityInput(temp_prop, "AddOutput");
		Format(temp_str, sizeof(temp_str), "OnUser1 !self:Kill::%f:1", delay);
		SetVariantString(temp_str);
		AcceptEntityInput(temp_prop_l4d, "AddOutput");
	}*/
	
	Format(temp_str, sizeof(temp_str), "OnUser1 !self:Kill::%f:1", delay+1.0);
	SetVariantString(temp_str);
	AcceptEntityInput(temp_prop, "AddOutput");
	
	AcceptEntityInput(temp_prop, "FireUser1");
	if (IsValidEntity(temp_prop_l4d)) AcceptEntityInput(temp_prop_l4d, "FireUser1");
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	if(entity == data) // Check if the TraceRay hit the itself.
	{
		return false; // Don't let the entity be hit
	}
	return true; // It didn't hit itself
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (!IsValidEntity(client)) return false;
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (g_isGame == 1)
	{ if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false; }
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}