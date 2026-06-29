#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY
#define MODEL_AMMO1 "models/props_unique/spawn_apartment/coffeeammo.mdl"
#define MODEL_AMMO2 "models/props/terror/ammo_stack.mdl"
#define MODEL_AMMO3 "models/props/de_prodigy/ammo_can_02.mdl"

ConVar hCvarLimit, hCvarChance;
bool bLimit = false;
int iChance = 0, iAlreadyUsed[MAXPLAYERS + 1] = {0, ...};

public Plugin myinfo =
{
	name = "[L4D2] Laser Box Replace With Ammo Piles",
	author = "BloodyBlade",
	description = "Replace all laser boxes with ammo piles",
	version = PLUGIN_VERSION,
	url = "https://bloodsiworld.ru"
};

public void OnPluginStart()
{	
	CreateConVar("l4d2_laser_box_replace_with_ammo_piles_version", PLUGIN_VERSION, "[L4D2] Laser Box Replace With Ammo Piles plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hCvarLimit = CreateConVar("l4d2_laser_box_replace_with_ammo_piles_limited", "1", "Limited ammo piles use(1 = limited, 0 = unlimited)", CVAR_FLAGS, true, 0.0, true, 1.0);
	hCvarChance = CreateConVar("l4d2_laser_box_replace_with_ammo_piles_chance", "100", "Laser sights replace chance", CVAR_FLAGS, true, 0.0, true, 100.0);
	AutoExecConfig(true, "l4d2_laser_box_replace_with_ammo_piles");
	bLimit = hCvarLimit.BoolValue;
	iChance = hCvarLimit.IntValue;
	hCvarLimit.AddChangeHook(OnConVarChange);
	hCvarChance.AddChangeHook(OnConVarChange);
}

void OnConVarChange(ConVar convar, char[] oldValue, char[] newValue)
{
	bLimit = hCvarLimit.BoolValue;
	iChance = hCvarLimit.IntValue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(entity > 0 && entity < 2048 && StrContains(classname, "upgrade_laser_sight") != -1)
	{
		if(GetRandomInt(1, 100) > iChance) return;
		int ammoStack = CreateEntityByName("weapon_ammo_spawn");
		if (ammoStack <= 0) return;
		float origin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		RemoveEntity(entity);
		int IRandom = GetRandomInt(1, 3);
		if(IRandom == 1)
		{
			SetEntityModel(ammoStack, MODEL_AMMO1);
		}
		else if(IRandom == 2)
		{
			SetEntityModel(ammoStack, MODEL_AMMO2);
		}
		else if(IRandom == 3)
		{
			SetEntityModel(ammoStack, MODEL_AMMO3);
		}

		SetEntProp(ammoStack, Prop_Send, "m_CollisionGroup", 1, 1);

		if(bLimit)
		{
			SDKHook(ammoStack, SDKHook_UsePost, OnUsePost);
		}
	}
}

void OnUsePost(int entity, int activator, int caller, UseType type, float value)
{
    if (iAlreadyUsed[caller] > 0)
    {
        return;
    }

    iAlreadyUsed[caller]++;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(iAlreadyUsed[i] >= TotalSurvivors())
        {
            iAlreadyUsed[i] = 0;
            RemoveEntity(entity);
        }
    }
}

int TotalSurvivors()
{
	int TotalSurv = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			TotalSurv++;
		}
	}
	return TotalSurv;
}
