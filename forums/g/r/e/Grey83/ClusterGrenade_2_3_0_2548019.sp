#pragma semicolon 1
#pragma newdecls required

#include <sdktools_engine>
#include <sdktools_entinput>
#include <sdktools_functions>
#include <sdkhooks>

#define DEBUG

static const char	PLUGIN_NAME[]		= "Cluster Grenade",
					PLUGIN_VERSION[]	= "2.3.0",
					PLUGIN_AUTHOR[]		= "Simon, Deathknife (rewritten by Grey83)";

bool bEnable;
int iAmount;
char sType[6];
float fRadius;

bool Allow[MAXPLAYERS+1] = {true, ...};

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
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= "Throw multiple grenades at once in a cluster.",
	version		= PLUGIN_VERSION,
	url			= "yash1441@yahoo.com"
};

public void OnPluginStart()
{
	CreateConVar("sm_cluster_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);

	ConVar CVar;
	(CVar = CreateConVar("sm_cluster_enable",	"1",	"Cluster Grenade enable? 0 = disable, 1 = enable", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(CVarChanged_Enable);
	bEnable = CVar.BoolValue;
	(CVar = CreateConVar("sm_cluster_amount",	"3",	"Number of grenades in the cluster.", FCVAR_NOTIFY, true, 1.0, true, 20.0)).AddChangeHook(CVarChanged_Number);
	iAmount = CVar.IntValue;
	(CVar = CreateConVar("sm_cluster_type",		"1",	"0 = All, 1 = HE, 2 = Flashbang, 3 = Smoke, 4 = Molotov / Incendiary, 5 = Decoy. Use: e.g. '125' (HE+Flashbang+Decoy) for multiple types", FCVAR_NOTIFY)).AddChangeHook(CVarChanged_Type);
	CVar.GetString(sType, sizeof(sType));
	(CVar = CreateConVar("sm_cluster_radius",	"7.0",	"Radius in which the cluster spawns around the main grenade.", FCVAR_NOTIFY, true)).AddChangeHook(CVarChanged_Radius);
	fRadius = CVar.FloatValue;

	UpdateGrenades();
}

public void CVarChanged_Enable(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bEnable = CVar.BoolValue;
}

public void CVarChanged_Number(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	iAmount = CVar.BoolValue;
}

public void CVarChanged_Radius(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	fRadius = CVar.FloatValue;
}

public void CVarChanged_Type(ConVar CVar, char[] oldvalue, char[] newvalue)
{
	CVar.GetString(sType, sizeof(sType));
	UpdateGrenades();
}

public void UpdateGrenades()
{
	//Reset previous
	for(int i; i < view_as<int>(eGrenades); i++) EnableNadeCluster[i] = false;
	if(!sType[0]) return;

	int i;
	while(sType[i])
	{
		if(29 < sType[i] < 36) EnableNadeCluster[sType[i] - 30] = true;
		i++;
	}
}

public void OnEntityCreated(int ent, const char[] classname)
{
	if(bEnable || StrContains(classname, "_projectile") < 5) return;

	if(EnableNadeCluster[AllNades]
	|| (!StrContains(classname, "hegrenade") && EnableNadeCluster[HeGrenade])
	|| (!StrContains(classname, "flashbang") && EnableNadeCluster[Flashbang])
	|| (!StrContains(classname, "smoke") && EnableNadeCluster[Smoke])
	|| ((!StrContains(classname, "molotov") || !StrContains(classname, "incgrenade")) && EnableNadeCluster[Molotov])
	|| (!StrContains(classname, "decoy") && EnableNadeCluster[Decoy]))
		SDKHook(ent, SDKHook_SpawnPost, OnEntitySpawned);
}

public void OnEntitySpawned(int ent)
{
	if(!bEnable) return;

	static int client;
	client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if(IsValidClient(client) && Allow[client])
	{
		Allow[client] = false;
		char classname[50];
		GetEdictClassname(ent, classname, sizeof(classname));
		CreateCluster(client, classname);
	}
	CreateTimer(0.1, AllowAgain, client);
}

public Action AllowAgain(Handle timer, any client)
{
	Allow[client] = true;
}

static const float m_vecAngVelocity[] = {4877.4, 0.0, 0.0};

public void CreateCluster(int client, const char[] classname)
{
	static float angles[3], pos[3];
	GetClientEyeAngles(client, angles);
	GetClientEyePosition(client, pos);
	for(int i; i < iAmount; i++)
	{
		static int ent;
		static float ang[3], vel[3], fPVelocity[3];
		ang[0] = angles[0] + GetRandomFloat(fRadius * -1.0, fRadius);
		ang[1] = angles[1] + GetRandomFloat(fRadius * -1.0, fRadius);
		GetAngleVectors(ang, vel, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vel, 1250.0);
		ent = CreateEntityByName(classname);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fPVelocity);
		AddVectors(vel, fPVelocity, vel);

		SetEntPropVector(ent, Prop_Data, "m_vecAngVelocity", m_vecAngVelocity);
		SetEntPropEnt(ent, Prop_Data, "m_hThrower", client);
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
		SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
		if(!StrContains(classname, "smoke"))
			CreateTimer(1.5, SmokeOn, EntIndexToEntRef(ent));
		else if(!StrContains(classname, "hegrenade"))
		{
			SetEntPropFloat(ent, Prop_Send, "m_DmgRadius", 350.0);
			SetEntPropFloat(ent, Prop_Send, "m_flDamage", 99.0);
		}
		AcceptEntityInput(ent, "InitializeSpawnFromWorld");
		AcceptEntityInput(ent, "FireUser1", ent);
		if(DispatchSpawn(ent))
		{
			for(int j; j < 3; j++) if(FloatAbs(ang[j]) > 360) ang[j] = FloatFraction(ang[j]) + RoundToZero(ang[j]) % 360;
			TeleportEntity(ent, pos, ang, vel);
		}
	}
}

public Action SmokeOn(Handle timer, int ref)
{
	if((ref = EntRefToEntIndex(ref)) != INVALID_ENT_REFERENCE)
	{
		SetEntProp(ref, Prop_Send, "m_bDidSmokeEffect", true);
		CreateTimer(18.0, SmokeOff, EntIndexToEntRef(ref));
	}
}

public Action SmokeOff(Handle timer, int ref)
{
	if((ref = EntRefToEntIndex(ref)) != INVALID_ENT_REFERENCE) AcceptEntityInput(ref, "Kill");
}

stock bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}