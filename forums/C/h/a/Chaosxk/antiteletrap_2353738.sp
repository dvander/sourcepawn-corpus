#pragma 	semicolon 1
#include 	<sdktools>
#include 	<sdkhooks>
#pragma 	newdecls required
#define 	PLUGIN_VERSION    "1.0.5"
ConVar		set_height;
ConVar		enable_height;

public Plugin myinfo =  {
	name = "Tele-Trap Prevention", 
	author = "Boonie", 
	description = "Prevent stacking teleporters & placing teleporters under low brushes to create traps", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=271569"
};

public void OnPluginStart() {
	CreateConVar("anti_teletrap_version", PLUGIN_VERSION, "Plugin Version", FCVAR_DONTRECORD | FCVAR_CHEAT | FCVAR_NOTIFY);
	set_height = CreateConVar("anti_teletrap_height", "96", "Minimum build height (Default 95)", FCVAR_PLUGIN);
	enable_height = CreateConVar("anti_teletrap_height_enabled", "1", "Enabled?", FCVAR_PLUGIN);
	HookEvent("player_builtobject", Event_Build);
	HookEvent("player_carryobject", Event_Carry);
}

public void Event_Build(Handle hEvent, const char[] strEventName, bool bDontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (client >= 1 && client <= MaxClients && IsClientInGame(client)) {
		char classname[32];
		int entity = GetEventInt(hEvent, "index");
		GetEdictClassname(entity, classname, sizeof(classname));
		if (entity > MaxClients) {
			if (StrEqual(classname, "obj_teleporter")) {
				int cEntity = CreateEntityByName("func_nobuild");
				if (IsValidEntity(cEntity)) {
					DispatchKeyValue(cEntity, "AllowTeleporters", "0");
					DispatchKeyValue(cEntity, "AllowDispenser", "1");
					DispatchKeyValue(cEntity, "AllowSentry", "1");
					DispatchSpawn(cEntity);
					ActivateEntity(cEntity);
					SetVariantString("!activator");
					AcceptEntityInput(cEntity, "SetParent", entity);
					SetVariantString("build_point_0");
					AcceptEntityInput(cEntity, "SetParentAttachment");
					SetEntPropVector(cEntity, Prop_Send, "m_vecMins", view_as<float>( { -50.0, -50.0, 0.0 } ));
					SetEntPropVector(cEntity, Prop_Send, "m_vecMaxs", view_as<float>( { 50.0, 50.0, 40.0 } ));
					SetEntProp(cEntity, Prop_Send, "m_nSolidType", 2);
				}
			}
		}
	}
}

public void Event_Carry(Handle hEvent, const char[] strEventName, bool bDontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (client >= 1 && client <= MaxClients && IsClientInGame(client)) {
		char classname[32], childclass[32];
		int entity = GetEventInt(hEvent, "index");
		GetEdictClassname(entity, classname, sizeof(classname));
		if (entity > MaxClients) {
			if (StrEqual(classname, "obj_teleporter")) {
				if (IsValidEntity(entity)) {
					int childEntity = GetEntPropEnt(entity, Prop_Data, "m_hMoveChild");
					GetEdictClassname(childEntity, childclass, sizeof(childclass));
					if (StrEqual(childclass, "func_nobuild")) {
						AcceptEntityInput(childEntity, "Kill");
					}
					if (enable_height.BoolValue) {
						RequestFrame(ChangeVec, EntIndexToEntRef(entity));
					}
				}
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname) {
	if (enable_height.BoolValue) {
		if (StrEqual(classname, "obj_teleporter")) {
			RequestFrame(ChangeVec, EntIndexToEntRef(entity));
		}
	}
}

public void ChangeVec(any ref) {
	int entity = EntRefToEntIndex(ref);
	if(!IsValidEntity(entity)) return;
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if(client >= 1 && IsClientInGame(client)) {
		float vecMaxs[3];
		vecMaxs[0] = 28.0;
		vecMaxs[1] = 28.0;
		vecMaxs[2] = float(set_height.IntValue);
		SetEntPropVector(entity, Prop_Send, "m_vecMins", view_as<float>( { -28.0, -28.0, 0.0 } ));
		SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecMaxs);
	}
}