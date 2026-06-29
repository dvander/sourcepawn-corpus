#include <sdktools>
#include <sdkhooks>

public void OnEntityCreated(int iEntity, const char[] szClassName)
{
	if(StrContains(szClassName, "chicken", false) == -1) {
		return;
	}
	
	SDKHook(iEntity, SDKHook_SpawnPost, Hook_ChickenSpawned);
}

public void Hook_ChickenSpawned(int iChicken)
{
	if(!IsValidEntity(iChicken)) {
		return;
	}
	
	AcceptEntityInput(iChicken, "Kill");
}