#include <sdktools>
#include <sdkhooks>

public void OnEntityCreated(int iEntity, const char[] szClassName)
{
	if(StrContains(szClassName, "chicken", false) == -1) {
		return;
	}
	
	SDKHook(iEntity, SDKHook_Spawn, Hook_ChickenSpawned);
}

public Action Hook_ChickenSpawned(int iChicken) {
	if(IsValidEntity(iChicken)) {
		AcceptEntityInput(iChicken, "Kill");
	}
	
	return Plugin_Stop;
}