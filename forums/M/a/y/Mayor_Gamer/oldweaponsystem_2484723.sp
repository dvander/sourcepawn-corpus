#pragma semicolon 1

#define PLUGIN_AUTHOR "Lucas 'aIM' Maza"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <morecolors>

public Plugin myinfo = 
{
	name = "[TF2] Old Weapon Drop System",
	author = PLUGIN_AUTHOR,
	description = "Brings back picking up metal from dropped weapons!",
	version = PLUGIN_VERSION,
	url = ""
};

ConVar CV_UseAmmoPacks;
ConVar CV_Enabled;
ConVar CV_Version;
ConVar CV_Advert;

public void OnPluginStart()
{
	CV_Version = CreateConVar("owds_version", PLUGIN_VERSION, "Plugin's version. Don't touch!", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	
	CV_Enabled = CreateConVar("owds_enabled", "1", "Wether the plugin is enabled or not.", _, true, 0.0, true, 1.0);
	CV_UseAmmoPacks = CreateConVar("owds_drop_ammo_packs", "0", "Wether to drop actual ammo packs alongside the weapon or not to.", _, true, 0.0, true, 1.0);
	CV_Advert = CreateConVar("owds_adverts", "1", "Wether to show when the plugin is enabled or disabled.", _, true, 0.0, true, 1.0);
	
	HookConVarChange(CV_Enabled, OnChangeEnabledState);
}

public void OnMapStart()
{
	if (GetConVarBool(CV_Enabled))
		CreateTimer(30.0, DoAdvert);
	
	SetConVarFloat(CV_Version, StringToFloat(PLUGIN_VERSION));
}

public void OnChangeEnabledState (ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(CV_Advert))
	{
		if (GetConVarBool(convar))
		{
			CPrintToChatAll("Old Weapon Drop System {green}enabled...");
		}
		else
		{
			CPrintToChatAll("Old Weapon Drop System {red}disabled...");
		}
	}
}

public Action DoAdvert (Handle timer, Handle hndl)
{
	CPrintToChatAll("This server is running the {skyblue}Old Weapon Drop System.");
	CPrintToChatAll("Version: {steelblue}%s. {default}Made by {gold}aIM.", PLUGIN_VERSION);
	
	CloseHandle(timer);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (GetConVarBool(CV_Enabled))
	{
		if (StrContains(classname, "tf_dropped_weapon", false) != -1)
		{
			SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawn);
		}
		else if (StrContains(classname, "tf_ammo_pack", false) != -1 && !GetConVarBool(CV_UseAmmoPacks))
		{
			SDKHook(entity, SDKHook_SpawnPost, OnAmmoPackSpawn);
		}
	}
}

public void OnAmmoPackSpawn (int entity)
{
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		
	if (client >= 1)
		AcceptEntityInput(entity, "Kill");
}

public void OnEntitySpawn (int entity)
{
	float vector[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vector);
		
	int modelIndx = GetEntProp(entity, Prop_Data, "m_nModelIndex");
	
	char model[PLATFORM_MAX_PATH];
	//int modelidx = GetEntProp(entity, Prop_Send, "m_iWorldModelIndex");
	ModelIndexToString(modelIndx, model, sizeof(model));
		
	AcceptEntityInput(entity, "Kill");
	
	CreateAmmoBox(model, vector);
}


void ModelIndexToString(int index, char[] model, int size)
{
	int table = FindStringTable("modelprecache");
	ReadStringTable(table, index, model, size);
}

void CreateAmmoBox (const char[] model, float position[3])
{
	int entity = CreateEntityByName("tf_ammo_pack");
	
	SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", -1);
	
	SetEntityModel(entity, model);
	
	DispatchSpawn(entity);
	
	TeleportEntity(entity, position, NULL_VECTOR, NULL_VECTOR);
}
