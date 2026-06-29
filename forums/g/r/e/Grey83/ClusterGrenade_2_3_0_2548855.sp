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

enum eGrenades {
	AllNades,
	HeGrenade,
	Flashbang,
	Smoke,
	Molotov,
	Decoy
};

bool bEnable,
	bClusterEnable[eGrenades];
int iAmount;
char sType[5];
float fRadius;

bool Allow[MAXPLAYERS+1] = {true, ...};

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
	(CVar = CreateConVar("sm_cluster_type",		"1",	"0 = All, 1 = HE, 2 = Flashbang, 3 = Smoke, 4 = Molotov / Incendiary, 5 = Decoy. Use: e.g. '1523' (HE+Flashbang+Decoy) for multiple types", FCVAR_NOTIFY, true, 0.0, true, 5555.0)).AddChangeHook(CVarChanged_Type);
	CVar.GetString(sType, sizeof(sType));
	(CVar = CreateConVar("sm_cluster_radius",	"7.0",	"Radius in which the cluster spawns around the main grenade.", FCVAR_NOTIFY, true, 1.0)).AddChangeHook(CVarChanged_Radius);
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

stock void UpdateGrenades()
{
	//Reset previous
	for(int i; i < view_as<int>(eGrenades); i++) bClusterEnable[i] = false;
	if(!sType[0]) return;

	int i;
	while(sType[i])
	{
		if('/' < sType[i] < '6') bClusterEnable[sType[i] - '0'] = true;
		i++;
	}
}

public void OnEntityCreated(int ent, const char[] class)
{
	if(!bEnable || StrContains(class, "_projectile") < 0) return;

	if((bClusterEnable[AllNades]	&& class[0] != 't')
	|| (bClusterEnable[HeGrenade]	&& class[0] == 'h')
	|| (bClusterEnable[Flashbang]	&& class[0] == 'f')
	|| (bClusterEnable[Smoke]		&& class[0] == 's')
	|| (bClusterEnable[Molotov]		&& (class[0] == 'i' || class[0] == 'm'))
	|| (bClusterEnable[Decoy])		&& class[0] == 'd')
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
		char class[50];
		GetEdictClassname(ent, class, sizeof(class));
		CreateCluster(client, class);
	}
	CreateTimer(0.1, AllowAgain, client);
}

public Action AllowAgain(Handle timer, any client)
{
	Allow[client] = true;
}

static const float m_vecAngVelocity[] = {4877.4, 0.0, 0.0};

stock void CreateCluster(int client, const char[] class)
{
	static int ent;
	static float angles[3], pos[3], ang[3], vel[3], fPVelocity[3];
	GetClientEyeAngles(client, angles);
	GetClientEyePosition(client, pos);
	for(int i; i < iAmount; i++)
	{
		ang[0] = angles[0] + GetRandomFloat(fRadius * -1.0, fRadius);
		ang[1] = angles[1] + GetRandomFloat(fRadius * -1.0, fRadius);
		GetAngleVectors(ang, vel, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vel, 1250.0);
		ent = CreateEntityByName(class);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fPVelocity);
		AddVectors(vel, fPVelocity, vel);

		SetEntPropVector(ent, Prop_Data, "m_vecAngVelocity", m_vecAngVelocity);
		SetEntPropEnt(ent, Prop_Data, "m_hThrower", client);
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
		SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
		switch(class[0])
		{
			case 's': CreateTimer(1.5, SmokeOn, EntIndexToEntRef(ent));
			case 'h':
			{
				SetEntPropFloat(ent, Prop_Send, "m_DmgRadius", 350.0);
				SetEntPropFloat(ent, Prop_Send, "m_flDamage", 99.0);
			}
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