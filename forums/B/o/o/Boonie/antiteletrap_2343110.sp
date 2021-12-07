#include 	<sdktools>
#pragma 	semicolon 1
#pragma 	newdecls required
#define 	PLUGIN_VERSION "1.0.7"

bool Validated; //Check if the client and entity have already been validated

public Plugin myinfo =  {
	name = "Tele-Trap Prevention", 
	author = "Boonie", 
	description = "Prevent stacking teleporters & placing teleporters under low brushes to create traps", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=271569"
};

public void OnPluginStart() {
	CreateConVar("anti_teletrap_version", PLUGIN_VERSION, "Plugin Version", FCVAR_DONTRECORD | FCVAR_CHEAT | FCVAR_NOTIFY);
	HookEvent("player_builtobject", Event_Build);
	HookEvent("player_carryobject", Event_Carry);
}

public void Event_Build(Handle event, const char[] eventName, bool dontBroadcast) {
	int buildingID = GetEventInt(event, "index");
	int clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
	
	char buildingClassname[32];
	GetEntityClassname(buildingID, buildingClassname, sizeof(buildingClassname));
	
	if (!IsValidEntity(buildingID))return;
	if (!IsValidClient(clientIndex))return;
	
	if (StrEqual(buildingClassname, "obj_teleporter")) {
		int noBuild = CreateEntityByName("func_nobuild");
		DispatchKeyValue(noBuild, "AllowTeleporters", "0");
		DispatchKeyValue(noBuild, "AllowDispenser", "1");
		DispatchKeyValue(noBuild, "AllowSentry", "1");
		DispatchSpawn(noBuild);
		ActivateEntity(noBuild);
		
		//Parent func_nobuild to teleporter
		SetVariantString("!activator");
		AcceptEntityInput(noBuild, "SetParent", buildingID);
		SetVariantString("build_point_0");
		AcceptEntityInput(noBuild, "SetParentAttachment");
		
		//Double the value since you can build 1/2 into func_nobuild
		SetEntPropVector(noBuild, Prop_Send, "m_vecMins", view_as<float>( { -48.0, -48.0, 0.0 } ));
		SetEntPropVector(noBuild, Prop_Send, "m_vecMaxs", view_as<float>( { 48.0, 48.0, 40.0 } ));
		SetEntProp(noBuild, Prop_Send, "m_nSolidType", 2);
	}
}

public void Event_Carry(Handle event, const char[] eventName, bool dontBroadcast) {
	int buildingID = GetEventInt(event, "index");
	int clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
	int childEntity = GetEntPropEnt(buildingID, Prop_Data, "m_hMoveChild");
	
	char buildingClassname[32], childClass[32];
	GetEntityClassname(buildingID, buildingClassname, sizeof(buildingClassname));
	GetEntityClassname(childEntity, childClass, sizeof(childClass));
	
	if (!IsValidEntity(buildingID))return;
	if (!IsValidClient(clientIndex))return;
	
	if (StrEqual(buildingClassname, "obj_teleporter")) {
		if (StrEqual(childClass, "func_nobuild")) {
			//Teleporter gets hidden once it has been picked up, yet the func_nobuild remains, kill it
			AcceptEntityInput(childEntity, "Kill");
		}
		Validated = true;
		RequestFrame(resizeBBox, EntIndexToEntRef(buildingID));
	}
}

public void OnEntityCreated(int entity, const char[] className) {
	if (StrEqual(className, "obj_teleporter")) {
		Validated = false;
		RequestFrame(resizeBBox, EntIndexToEntRef(entity));
	}
}

public void resizeBBox(any ref) {
	int entity = EntRefToEntIndex(ref);
	
	if (!Validated) {
		if (!IsValidEntity(entity))return;
		if (!IsValidClient(GetEntPropEnt(entity, Prop_Send, "m_hBuilder")))return;
	}
	SetEntPropVector(entity, Prop_Send, "m_vecMins", view_as<float>( { -28.0, -28.0, 0.0 } ));
	SetEntPropVector(entity, Prop_Send, "m_vecMaxs", view_as<float>( { 28.0, 28.0, 95.9687385 } )); //As close to the ceiling within reason
}

public bool IsValidClient(int client) {
	if (!(client >= 1))
		return false;
	if (!(client <= MaxClients))
		return false;
	if (!IsClientInGame(client))
		return false;
	return true;
}
