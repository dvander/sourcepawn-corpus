#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2items>

#define QUALITY_STRANGE 		11

#define VERSION			"0.0.1"

public Plugin:myinfo = {
	name        = "tOnlyStrangePls",
	author      = "Thrawn",
	description = "Blocks all not-strange weapons",
	version     = VERSION,
	url         = "http://forums.alliedmods.net/showthread.php?t=140045"
};

public OnPluginStart() {
	CreateConVar("sm_tonlystrangepls_version", VERSION, "[TF2] tOnlyStrangePls", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public TF2Items_OnGiveNamedItem_Post(client, String:classname[], iItemDefinitionIndex, itemLevel, itemQuality, entityIndex) {
	if(itemQuality != QUALITY_STRANGE) {
		new Handle:hTrie = CreateTrie();
		SetTrieValue(hTrie, "client", client);
		SetTrieValue(hTrie, "entityIndex", entityIndex);

		CreateTimer(0.01, Timer_ReplaceWeapon, hTrie);

		return;
	}
}

public Action:Timer_ReplaceWeapon(Handle:timer, any:hTrie) {
	new entityIndex = -1;
	GetTrieValue(hTrie, "entityIndex", entityIndex);

	new client = -1;
	GetTrieValue(hTrie, "client", client);

	CloseHandle(hTrie);

	if(IsValidEntity(entityIndex)) {
		RemovePlayerItem(client, entityIndex);
		AcceptEntityInput(entityIndex, "Kill");
	}
}