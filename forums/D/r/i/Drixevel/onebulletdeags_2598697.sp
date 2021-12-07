//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines

//Sourcemod Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

//Globals

public Plugin myinfo =
{
	name = "One Bullet Deags",
	author = "Keith Warren (Shaders Allen)",
	description = "Automatically sets deagles to have 1 bullet.",
	version = "1.0.0",
	url = "https://github.com/ShadersAllen"
};

public void OnPluginStart()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "weapon_deagle")) != -1)
	{
		RequestFrame(Frame_Delay, EntIndexToEntRef(entity));
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "weapon_deagle"))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
	}
}

public void OnSpawnPost(int entity)
{
	RequestFrame(Frame_Delay, EntIndexToEntRef(entity));
}

public void Frame_Delay(any data)
{
	int entity = EntRefToEntIndex(data);

	if (IsValidEntity(entity))
	{
		SetEntProp(entity, Prop_Data, "m_iClip1", 1);
		SetEntProp(entity, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
	}
}