#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Simon -edit by Deathknife"
#define PLUGIN_VERSION "2.2"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

bool Allow[MAXPLAYERS+1] = {true, ...};
ConVar ClusterEnable;
ConVar ClusterNumber;
ConVar ClusterType;
ConVar ClusterRadius;

enum eGrenades {
	AllNades,
	HeGrenade,
	Flashbang,
	Smoke,
	Molotov,
	Decoy
};
bool EnableNadeCluster[eGrenades];

public Plugin myinfo = 
{
	name = "Cluster Grenade",
	author = PLUGIN_AUTHOR,
	description = "Throw multiple grenades at once in a cluster.",
	version = PLUGIN_VERSION,
	url = "yash1441@yahoo.com"
};

public void OnPluginStart()
{
	CreateConVar("sm_cluster_version", PLUGIN_VERSION, "Cluster Grenade Version", FCVAR_DONTRECORD | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_SPONLY);
	ClusterEnable = CreateConVar("sm_cluster_enable", "1", "Cluster Grenade enable? 0 = disable, 1 = enable", 0, true, 0.0, true, 1.0);
	ClusterNumber = CreateConVar("sm_cluster_amount", "3", "Number of grenades in the cluster.", 0, true, 0.0, false);
	ClusterType = CreateConVar("sm_cluster_type", "1", "0 = All, 1 = HE, 2 = Flashbang, 3 = Smoke, 4 = Molotov / Incendiary, 5 = Decoy. Separate by comma for multiple", 0, true, 0.0, true, 5.0);
	ClusterRadius = CreateConVar("sm_cluster_radius", "7.0", "Radius in which the cluster spawns around the main grenade.", 0, true, 0.0, false);
	
	HookConVarChange(ClusterType, OnClusterTypeChange);
	UpdateGrenades();
}

public void OnClusterTypeChange(ConVar cvar, char[] oldvalue, char[] newvalue) 
{
	UpdateGrenades();
}
	
public void UpdateGrenades() 
{
	char buffer[view_as<int>(eGrenades)*8+view_as<int>(eGrenades)];
	char grenades[eGrenades][8];
	
	GetConVarString(ClusterType, buffer, sizeof(buffer));
	int amountOfStrings = ExplodeString(buffer, ",", grenades, eGrenades, sizeof(grenades[]));
	
	//Reset previous
	for(int i = 0; i < view_as<int>(eGrenades); i++) 
	{
		EnableNadeCluster[i] = false;
	}
	
	for(int i = 0; i < amountOfStrings; i++) 
	{
		int nade = StringToInt(grenades[i]);
		EnableNadeCluster[nade] = true;
	}
}

public void OnEntityCreated(int iEntity, const char[] classname) 
{
	if (StrContains(classname, "_projectile") != -1 && GetConVarBool(ClusterEnable))
	{
		if(EnableNadeCluster[AllNades])
		{
			SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
		}
		else if(StrContains(classname, "hegrenade") != -1 && EnableNadeCluster[HeGrenade])
		{
			SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
		}
		else if(StrContains(classname, "flashbang") != -1 && EnableNadeCluster[Flashbang])
		{
			SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
		}
		else if(StrContains(classname, "smoke") != -1 && EnableNadeCluster[Smoke])
		{
			SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
		}
		else if((StrContains(classname, "molotov") != -1 || StrContains(classname, "incgrenade") != -1) && EnableNadeCluster[Molotov])
		{
			SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
		}
		else if(StrContains(classname, "decoy") != -1 && EnableNadeCluster[Decoy])
		{
			SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
		}
	}
}

public Action OnEntitySpawned(int iGrenade)
{
	int client = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
	if (IsValidClient(client) && Allow[client] && GetConVarBool(ClusterEnable))
	{
		Allow[client] = false;
		char classname[50];
		GetEdictClassname(iGrenade, classname, sizeof(classname));
		CreateCluster(client, GetConVarInt(ClusterNumber), classname);
	}
	CreateTimer(0.1, AllowAgain, client);
}

public Action AllowAgain(Handle timer, any data)
{
	Allow[data] = true;
}

public void CreateCluster(int client, const int number, const char[] classname)
{
	float angles[3];
	float[][] ang = new float[number][3];
	float pos[3];
	float vel[3];
	GetClientEyeAngles(client, angles);
	GetClientEyePosition(client, pos);
	int[] GEntities = new int[number];
	float g_fSpin[3] =  { 4877.4, 0.0, 0.0 };
	float fPVelocity[3];
	for (int i = 0; i < number; i++)
	{
		ang[i][0] = angles[0] + GetRandomFloat(GetConVarFloat(ClusterRadius) * -1.0, GetConVarFloat(ClusterRadius)); 
		ang[i][1] = angles[1] + GetRandomFloat(GetConVarFloat(ClusterRadius) * -1.0, GetConVarFloat(ClusterRadius));
		float temp_ang[3];
		temp_ang[0] = ang[i][0];
		temp_ang[1] = ang[i][1];
		temp_ang[2] = ang[i][2];
		GetAngleVectors(temp_ang, vel, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vel, 1250.0);
		GEntities[i] = CreateEntityByName(classname);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fPVelocity);
		AddVectors(vel, fPVelocity, vel);
		
		SetEntPropVector(GEntities[i], Prop_Data, "m_vecAngVelocity", g_fSpin);
		SetEntPropEnt(GEntities[i], Prop_Data, "m_hThrower", client);
		SetEntPropEnt(GEntities[i], Prop_Data, "m_hOwnerEntity", client);
		SetEntProp(GEntities[i], Prop_Send, "m_iTeamNum", GetClientTeam(client));
		if(StrContains(classname, "smoke") != -1)
		{
			CreateTimer(1.5, SmokeOn, GEntities[i]);
		}
		if(StrContains(classname, "hegrenade") != -1)
		{
			SetEntPropFloat(GEntities[i], Prop_Send, "m_DmgRadius", 350.0);
			SetEntPropFloat(GEntities[i], Prop_Send, "m_flDamage", 99.0);
		}
		AcceptEntityInput(GEntities[i], "InitializeSpawnFromWorld");
		AcceptEntityInput(GEntities[i], "FireUser1", GEntities[i]);
		if (DispatchSpawn(GEntities[i]))
		{
			TeleportEntity(GEntities[i], pos, temp_ang, vel);
		}
	}
}

public Action SmokeOn(Handle timer, int ent)
{
	SetEntProp(ent, Prop_Send, "m_bDidSmokeEffect", true);
	CreateTimer(18.0, SmokeOff, ent);
}

public Action SmokeOff(Handle timer, int ent)
{
	RemoveEdict(ent);
}

stock bool IsValidClient(int client)
{
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	return IsClientInGame(client);
}