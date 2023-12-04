#define PLUGIN_NAME "[TF2] Old Weapon Drop System"
#define PLUGIN_AUTHOR "Lucas 'puntero' Maza, Shadowysn"
#define PLUGIN_DESC "Brings back picking up metal from dropped weapons!"
#define PLUGIN_VERSION "1.3"
#define PLUGIN_URL "https://forums.alliedmods.net/showpost.php?p=2757348&postcount=7"
#define PLUGIN_NAME_SHORT "Old Weapon Drop System"
#define PLUGIN_NAME_TECH "owds"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
//#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

#define AUTOEXEC_CFG "oldweaponsystem"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

static ConVar CV_Enabled;
static ConVar CV_UseAmmoPacks;
static ConVar CV_Advert;
bool g_bCV_Enabled, g_bCV_UseAmmoPacks;
int g_iCV_Advert;

#define BITFLAG_ADVERT_MAPSTART 1
#define BITFLAG_ADVERT_ENABLE 2

static int g_iDroppedWeapon[MAXPLAYERS+1] = {0};

public void OnPluginStart()
{
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	Format(cmd_str, sizeof(cmd_str), "%s_enabled", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "Enable the %s plugin.", PLUGIN_NAME_SHORT);
	CV_Enabled = CreateConVar(cmd_str, "1", desc_str, FCVAR_NONE, true, 0.0, true, 1.0);
	
	Format(cmd_str, sizeof(cmd_str), "%s_drop_ammo_packs", PLUGIN_NAME_TECH);
	CV_UseAmmoPacks = CreateConVar(cmd_str, "0", "Drop ammo packs alongside the weapon?", FCVAR_NONE, true, 0.0, true, 1.0);
	
	Format(cmd_str, sizeof(cmd_str), "%s_adverts", PLUGIN_NAME_TECH);
	CV_Advert = CreateConVar(cmd_str, "0", "Advertise the plugin. 1 = (Advert on map start.) 2 = (Advert when enabling/disabling the plugin) Numbers are combinable.", FCVAR_NONE, true, 0.0, true, 3.0);
	
	CV_Enabled.AddChangeHook(ConVarChanged_Cvars);
	CV_UseAmmoPacks.AddChangeHook(ConVarChanged_Cvars);
	CV_Advert.AddChangeHook(ConVarChanged_Cvars);
	
	AutoExecConfig(true, AUTOEXEC_CFG);
	SetCvars();
}

public void OnMapStart()
{
	if (g_bCV_Enabled && (g_iCV_Advert & BITFLAG_ADVERT_MAPSTART))
		CreateTimer(30.0, DoAdvert);
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	SetCvars();
	if (convar == CV_Enabled && (g_iCV_Advert & BITFLAG_ADVERT_ENABLE))
	{
		if (g_bCV_Enabled)
		{ PrintToChatAll("\x03[\x05OWDS\x03]\x01 Old Weapon Drop System \x04enabled."); }
		else
		{ PrintToChatAll("\x03[\x05OWDS\x03]\x01 Old Weapon Drop System \x04disabled."); }
	}
}
void SetCvars()
{
	g_bCV_Enabled = CV_Enabled.BoolValue;
	g_bCV_UseAmmoPacks = CV_UseAmmoPacks.BoolValue;
	g_iCV_Advert = CV_Advert.IntValue;
}

Action DoAdvert(Handle timer)
{
	PrintToChatAll("\x03[\x05OWDS\x03]\x01 This server is running the Old Weapon Drop System.");
	PrintToChatAll("\x04Version: \x03%s\x01. Made by \x04puntero\x01 and edited by \x04Shadowysn\x01.", PLUGIN_VERSION);
	
	CloseHandle(timer);
	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!g_bCV_Enabled || classname[0] != 't') return;
	
	if (strcmp(classname, "tf_dropped_weapon", false) == 0)
		SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawn);
	else if (strcmp(classname, "tf_ammo_pack", false) == 0 && !g_bCV_UseAmmoPacks)
		SDKHook(entity, SDKHook_SpawnPost, OnAmmoPackSpawn);
}

public void OnEntityDestroyed(int entity)
{
	if (!g_bCV_Enabled) return;
	
	static char classname[18];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (classname[0] != 't' || strcmp(classname, "tf_dropped_weapon", false) != 0) return;
	
	int parent = GetEntPropEnt(entity, Prop_Send, "moveparent");
	if (!RealValidEntity(parent)) return;
	
	GetEntityClassname(parent, classname, sizeof(classname));
	if (classname[0] != 't' || strcmp(classname, "tf_ammo_pack", false) != 0) return;
	
	AcceptEntityInput(parent, "Kill");
}

public void OnAmmoPackSpawn(int entity)
{
	static char modelName[23]; // This 23 limit is so we get results of models/buildables/gibs when this is a building gib
	GetEntPropString(entity, Prop_Data, "m_ModelName", modelName, sizeof(modelName));
	if (strcmp(modelName, "models/buildables/gibs", false) == 0) return;
	
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	
	if (client >= 1)
		AcceptEntityInput(entity, "Kill");
}

public void OnEntitySpawn(int entity)
{
	float vector[3], angles[3], velocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vector);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", angles);
	GetEntPropVector(entity, Prop_Data, "m_vecVelocity", velocity);
		
	int modelIndx = GetEntProp(entity, Prop_Data, "m_nModelIndex");
	
	char model[PLATFORM_MAX_PATH];
	//int modelidx = GetEntProp(entity, Prop_Send, "m_iWorldModelIndex");
	ModelIndexToString(modelIndx, model, sizeof(model));
	
	int box = CreateAmmoBox(model, vector, angles, velocity);
	
	SetEntProp(entity, Prop_Data, "m_MoveType", 0);
	SetEntProp(entity, Prop_Send, "movetype", 0);
	SetEntProp(entity, Prop_Send, "m_bInitialized", 0); // This prevents people from picking up the dropped weapon
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", box);
	SetEntProp(entity, Prop_Send, "m_hOwnerEntity", -1);
	
	SetEntProp(entity, Prop_Data, "m_CollisionGroup", 1); // COLLISION_GROUP_DEBRIS
	//SetEntProp(entity, Prop_Send, "m_fEffects", 1|512); // EF_BONEMERGE|EF_PARENT_ANIMATES
	SetEntProp(entity, Prop_Send, "m_fEffects", 1|128); // EF_BONEMERGE|EF_BONEMERGE_FASTCULL
}

void ModelIndexToString(int index, char[] model, int size)
{
	int table = FindStringTable("modelprecache");
	ReadStringTable(table, index, model, size);
}

int CreateAmmoBox(const char[] model, const float position[3], const float angles[3], const float velocity[3], int owner = -1)
{
	int entity = CreateEntityByName("tf_ammo_pack");
	
	SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", owner);
	
	DispatchKeyValue(entity, "rendermode", "10"); // This hides the ammo pack wep because
	AcceptEntityInput(entity, "DisableShadow"); // tf_dropped_weapon will be the visuals of it
	
	SetEntityModel(entity, model);
	
	DispatchSpawn(entity);
	
	// Give Metal ammo from the box. Credits to Pelipoika: https://github.com/Pelipoika/TF2_NextBot/blob/master/tfpets.sp#L1558-L1559
	// TF_AMMO_METAL is index 3
	// CTFAmmoPack stores its ammo values in m_iAmmo, which is an array with ammo values for each weapon type.
	int Offset = ((3 * 4) + (FindDataMapInfo(entity, "m_vOriginalSpawnAngles") + 20));
	SetEntData(entity, Offset, 100, _, true);
	
	ActivateEntity(entity);
	SetEntProp(entity, Prop_Data, "m_CollisionGroup", 11); // COLLISION_GROUP_WEAPON
	
	TeleportEntity(entity, position, angles, velocity);
	
	return entity;
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && 
	!GetEntProp(client, Prop_Send, "m_bIsCoaching")) // TF2
	{
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}

bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }