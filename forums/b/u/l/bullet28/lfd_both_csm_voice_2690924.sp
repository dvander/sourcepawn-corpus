#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma newdecls required

public Plugin myinfo =
{
	name = "Wrong Voice Owner Fix",
	author = "bullet28",
	description = "When two or more same characters in the game only 1 become source of voices from all same characters",
	version = "1",
	url = ""
}

bool bSkipNextEntity;

public void OnEntityCreated(int entity, const char[] classname) {
	if (!bSkipNextEntity && StrEqual(classname, "instanced_scripted_scene")) {
		SDKHook(entity, SDKHook_SpawnPost, OnPostSceneSpawn);
	}
}

public void OnPostSceneSpawn(int entity) {
	if (!isValidEntity(entity)) return;

	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwner");
	if (!isPlayerAliveSurvivor(owner)) return;

	int ownerCharacterId = GetEntProp(owner, Prop_Send, "m_survivorCharacter");

	bool bFoundSameCharacter;
	for (int i = 1; i <= MaxClients; i++) {
		if (i == owner) continue;
		if (!isPlayerAliveSurvivor(i)) continue;
		int iCharacterId = GetEntProp(i, Prop_Send, "m_survivorCharacter");
		if (iCharacterId == ownerCharacterId) {
			bFoundSameCharacter = true;
			break;
		}
	}

	if (!bFoundSameCharacter) {
		return;
	}

	float pitch = GetEntPropFloat(entity, Prop_Data, "m_fPitch");
	float preDelay = GetEntPropFloat(entity, Prop_Data, "m_flPreDelay");
	
	char sceneFile[128];
	GetEntPropString(entity, Prop_Data, "m_iszSceneFile", sceneFile, sizeof sceneFile);
	//PrintToChatAll("OnPostSceneSpawn:: %N | %s | %0.2f | Delay: %f", owner, sceneFile, pitch, preDelay);

	AcceptEntityInput(entity, "Cancel");
	AcceptEntityInput(entity, "Kill");

	/* Re-creating a scene */
	int prevSurvivorCharacter[MAXPLAYERS+1];
	for (int i = 1; i <= MaxClients; i++) {
		if (i != owner && isPlayerAliveSurvivor(i)) {
			int characterId = GetEntProp(i, Prop_Send, "m_survivorCharacter");
			if (characterId == ownerCharacterId) {
				prevSurvivorCharacter[i] = characterId +1;
				int placeholderCharacterId = characterId == 0 ? 1 : 0;
				SetEntProp(i, Prop_Send, "m_survivorCharacter", placeholderCharacterId);
			}
		}
	}

	bSkipNextEntity = true;

	int scene = CreateEntityByName("instanced_scripted_scene");
	if (scene >= 0) {
		DispatchKeyValue(scene, "SceneFile", sceneFile);
		SetEntPropEnt(scene, Prop_Data, "m_hOwner", owner);
		SetEntPropFloat(scene, Prop_Data, "m_flPreDelay", preDelay);
		SetEntPropFloat(scene, Prop_Data, "m_fPitch", pitch);
		DispatchSpawn(scene);
		ActivateEntity(scene);
		AcceptEntityInput(scene, "Start", owner, owner);
	}

	bSkipNextEntity = false;

	for (int i = 1; i <= MaxClients; i++) {
		if (prevSurvivorCharacter[i] != 0) {
			SetEntProp(i, Prop_Send, "m_survivorCharacter", prevSurvivorCharacter[i] -1);
		}
	}
}

bool isValidEntity(int entity) {
	return entity > 0 && entity <= 2048 && IsValidEdict(entity) && IsValidEntity(entity);
}

bool isPlayerAliveSurvivor(int client) {
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}
