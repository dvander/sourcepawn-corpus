#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


public void OnEntityCreated(int iEntity, const char[] classname) 
{
	if(StrContains(classname, "env_wind") != -1)
	{
		SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
	}
}
	
public Action OnEntitySpawned(int iGrenade)
{
	RequestFrame(Frame_DisableNoSpread, iGrenade);
}

public void Frame_DisableNoSpread(any iGrenade)
{
	if(IsValidEntity(iGrenade))
	{
		AcceptEntityInput(iGrenade, "Kill");
	}
}