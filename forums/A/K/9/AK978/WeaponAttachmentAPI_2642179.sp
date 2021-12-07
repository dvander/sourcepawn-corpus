#include <sdktools>
#pragma semicolon 1

int plyAttachmentEnts[MAXPLAYERS+1] = {-1,...};
int plyAttachmentEntP[MAXPLAYERS+1] = {-1,...};
int plyLastWeapon[MAXPLAYERS+1] = {-1,...};
char plyLastAttachment[MAXPLAYERS+1][32];
float emptyVector[3];
EngineVersion EVGame;
char gameAttachPoint[32];

#define EF_BONEMERGE                (1 << 0)
#define EF_NOSHADOW                 (1 << 4)
#define EF_NORECEIVESHADOW          (1 << 6)
#define EF_PARENT_ANIMATES          (1 << 9)
#define PLUGIN_VERSION              "1.1.1"
public Plugin myinfo = {
	name = "Weapon Attachment API",
	author = "Mitchell",
	description = "Natives for weapon attachments.",
	version = PLUGIN_VERSION,
	url = "http://mtch.tech"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("WA_GetAttachmentPos", Native_GetAttachmentPos);
	RegPluginLibrary("WeaponAttachmentAPI");
	return APLRes_Success;
}

public OnPluginStart() {
	CreateConVar("sm_weapon_attachment_api_version", PLUGIN_VERSION, "Weapon Attachment API Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	EVGame = GetEngineVersion();
	GetGameAttachPoint();
//	HookEvent("player_death", Event_Death);
}
public void OnMapStart() {
	PrecacheModel("models/error.mdl", true);
}

public OnPluginEnd() {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			RemoveAttachEnt(i);
		}
	}
}

public GetGameAttachPoint() {
	switch(EVGame) {
		case Engine_CSS: gameAttachPoint = "muzzle_flash";
		case Engine_TF2, Engine_DODS: gameAttachPoint = "weapon_bone";
		case Engine_HL2DM: gameAttachPoint = "chest";
	}
}

public Native_GetAttachmentPos(Handle plugin, args) {
	int client = GetNativeCell(1);
	bool result = false;
	if(NativeCheck_IsClientValid(client) && IsPlayerAlive(client)) {
		char attachment[32];
		GetNativeString(2, attachment, 32);
		float pos[3];
		result = GetAttachmentPosition(client, attachment, pos);
		SetNativeArray(3, pos, 3);
	}
	return result;
}

/*
//Do we even really need to remove the entity on death?
public Action Event_Death(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client)) 
	{
		RemoveAttachEnt(client);
	}
}
*/

public bool GetAttachmentPosition(client, char[] attachment, float epos[3]) {
	if(StrEqual(attachment, "")) {
		return false;
	}
	int aent = GetAttachmentEnt(client);
	if(aent == INVALID_ENT_REFERENCE) {
		aent = EntIndexToEntRef(CreateAttachmentEnt(client));
		if(!IsValidEntity(aent)) {
			return false;
		}
		plyAttachmentEnts[client] = aent;
	}
	int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if(plyLastWeapon[client] != weapon || !StrEqual(attachment, plyLastAttachment[client], false)) {
		//The position is different, need to relocate the entity.
		plyLastWeapon[client] = weapon;
		strcopy(plyLastAttachment[client], 32, attachment);
		AcceptEntityInput(aent, "ClearParent");
		if(EVGame == Engine_CSGO) {
			weapon = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
		} else {
			//Games other than CSGO, what a hassle.
			char modelName[PLATFORM_MAX_PATH];
			//Setting the model's index will not update attachment names..
			findModelString(GetEntProp(weapon, Prop_Send, "m_iWorldModelIndex"), modelName, sizeof(modelName));
			int pent = GetAttachmentProp(client);
			if(pent == INVALID_ENT_REFERENCE) {
				pent = CreateAttachmentProp(client);
				if(!IsValidEntity(aent)) {
					return false;
				}
			}
			AcceptEntityInput(pent, "ClearParent");
			SetEntityModel(pent, modelName);
			setParent(pent, client, gameAttachPoint);
			weapon = pent;
		}
		setParent(aent, weapon, attachment);
		TeleportEntity(aent, emptyVector, NULL_VECTOR, NULL_VECTOR);
	}
	GetEntPropVector(aent, Prop_Data, "m_vecAbsOrigin", epos);
	return true;
}

public GetAttachmentEnt(int client) {
	if(IsValidEntity(plyAttachmentEnts[client])) {
		return plyAttachmentEnts[client];
	}
	return INVALID_ENT_REFERENCE;
}

public GetAttachmentProp(int client) {
	if(IsValidEntity(plyAttachmentEntP[client])) {
		return plyAttachmentEntP[client];
	}
	return INVALID_ENT_REFERENCE;
}

public CreateAttachmentEnt(int client) {
	RemoveAttachEnt(client);
	int aent = CreateEntityByName("info_target");
	DispatchSpawn(aent);
	plyLastWeapon[client] = INVALID_ENT_REFERENCE;
	plyLastAttachment[client] = "";
	if(EVGame != Engine_CSGO) {
		int pent = EntIndexToEntRef(CreateAttachmentProp(client));
		if(!IsValidEntity(pent)) {
			return false;
		}
		plyAttachmentEntP[client] = pent;
	}
	return aent;
}

public CreateAttachmentProp(int client) {
	RemoveAttachProp(client);
	int pent = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(pent, "model", "models/error.mdl");
	DispatchKeyValue(pent, "disablereceiveshadows", "1");
	DispatchKeyValue(pent, "disableshadows", "1");
	DispatchKeyValue(pent, "solid", "0");
	DispatchKeyValue(pent, "spawnflags", "256");
	DispatchSpawn(pent);
	SetEntProp(pent, Prop_Send, "m_fEffects", 32|EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW|EF_PARENT_ANIMATES);
	return pent;
}

public RemoveAttachEnt(int client) {
	if(IsValidEntity(plyAttachmentEnts[client])) {
		AcceptEntityInput(plyAttachmentEnts[client], "Kill");
	}
	RemoveAttachProp(client);
	plyAttachmentEnts[client] = INVALID_ENT_REFERENCE;
	plyLastWeapon[client] = INVALID_ENT_REFERENCE;
	plyLastAttachment[client] = "";
}

public RemoveAttachProp(int client) {
	if(IsValidEntity(plyAttachmentEntP[client])) {
		AcceptEntityInput(plyAttachmentEntP[client], "Kill");
	}
	plyAttachmentEntP[client] = INVALID_ENT_REFERENCE;
}

public NativeCheck_IsClientValid(int client) {
	if (client <= 0 || client > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %i is invalid", client);
	}
	if (!IsClientInGame(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %i is not in game", client);
	}
	return true;
}

public setParent(int child, int parent, char[] attachment) {
	SetVariantString("!activator");
	AcceptEntityInput(child, "SetParent", parent, child, 0);
	if(!StrEqual(attachment, "")) {
		SetVariantString(attachment);
		AcceptEntityInput(child, "SetParentAttachment", child, child, 0);
	}
}

public int findModelString(int modelIndex, char[] modelString, int string_size) {
	static int stringTable = INVALID_STRING_TABLE;
	if (stringTable == INVALID_STRING_TABLE) {
		stringTable = FindStringTable("modelprecache");
	}
	return ReadStringTable(stringTable, modelIndex, modelString, string_size);
}