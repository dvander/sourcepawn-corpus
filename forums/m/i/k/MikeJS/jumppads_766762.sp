#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <dukehacks>
#define PLUGIN_VERSION "1.0"
new Handle:g_hKv = INVALID_HANDLE;
new g_idxPads[32];
new Float:g_vecPads[32][3];
new String:g_sndPads[32][128];
new g_count;
public Plugin:myinfo = 
{
	name = "Jump Pads",
	author = "MikeJS",
	description = "Add jump pads to maps",
	version = PLUGIN_VERSION,
	url = "http://mikejs.byethost18.com/"
}
public OnPluginStart() {
	CreateConVar("sm_jumppads_version", PLUGIN_VERSION, "Jump Pads version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_padsreload", Command_reload, ADMFLAG_KICK, "Reload jump pads.");
	RegAdminCmd("sm_padsremove", Command_remove, ADMFLAG_KICK, "Remove jump pads.");
	HookEvent("teamplay_round_start", Event_round_start);
	HookEvent("teamplay_restart_round", Event_round_start);
}
public OnMapStart() {
	g_count = 0;
}
LoadPads() {
	if(g_hKv!=INVALID_HANDLE) {
		CloseHandle(g_hKv);
	}
	g_hKv = CreateKeyValues("Pads");
	decl String:path[256];
	BuildPath(Path_SM, path, sizeof(path), "configs/pads.cfg");
	if(FileExists(path)) {
		FileToKeyValues(g_hKv, path);
		if(KvGotoFirstSubKey(g_hKv)) {
			decl String:map[64], String:name[64];
			GetCurrentMap(map, sizeof(map));
			do {
				KvGetSectionName(g_hKv, name, sizeof(name));
				if(StrEqual(name, map)) {
					KvGotoFirstSubKey(g_hKv);
					decl String:kvOrigin[24], String:arOrigin[3][8], Float:vecOrigin[3], String:kvAngles[24], String:arAngles[3][8], Float:vecAngles[3], String:kvVelocity[24], String:arVelocity[3][8], String:kvModel[128], String:kvSound[128];
					g_count = 0;
					do {
						KvGetString(g_hKv, "origin",  kvOrigin,  sizeof(kvOrigin));
						ExplodeString(kvOrigin, ",", arOrigin, 3, 8);
						vecOrigin[0] = StringToFloat(arOrigin[0]);
						vecOrigin[1] = StringToFloat(arOrigin[1]);
						vecOrigin[2] = StringToFloat(arOrigin[2]);
						KvGetString(g_hKv, "angles", kvAngles, sizeof(kvAngles));
						ExplodeString(kvAngles, ",", arAngles, 3, 8);
						vecAngles[0] = StringToFloat(arAngles[0]);
						vecAngles[1] = StringToFloat(arAngles[1]);
						vecAngles[2] = StringToFloat(arAngles[2]);
						KvGetString(g_hKv, "velocity", kvVelocity, sizeof(kvVelocity));
						ExplodeString(kvVelocity, ",", arVelocity, 3, 8);
						KvGetString(g_hKv, "model", kvModel, sizeof(kvModel));
						KvGetString(g_hKv, "sound", kvSound, sizeof(kvSound));
						new entity = CreateEntityByName("prop_physics_override");
						if(IsValidEntity(entity)) {
							PrecacheModel(kvModel, true);
							PrecacheSound(kvSound, true);
							SetEntityModel(entity, kvModel);
							SetEntityMoveType(entity, MOVETYPE_NONE);
							SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0);
							SetEntProp(entity, Prop_Data, "m_usSolidFlags", 28);
							SetEntProp(entity, Prop_Data, "m_nSolidType", 6);
							DispatchSpawn(entity);
							AcceptEntityInput(entity, "DisableMotion");
							TeleportEntity(entity, vecOrigin, vecAngles, NULL_VECTOR);
							dhHookEntity(entity, EHK_Touch, TouchHook);
							g_idxPads[g_count] = entity;
							g_vecPads[g_count][0] = StringToFloat(arVelocity[0]);
							g_vecPads[g_count][1] = StringToFloat(arVelocity[1]);
							g_vecPads[g_count][2] = StringToFloat(arVelocity[2]);
							g_sndPads[g_count++] = kvSound;
						}
					} while(KvGotoNextKey(g_hKv));
				}
			} while(KvGotoNextKey(g_hKv));
		}
	} else {
		SetFailState("File Not Found: %s", path);
	}
}
DeletePads() {
	if(g_count>0) {
		for(new i=0;i<g_count;i++) {
			if(IsValidEntity(g_idxPads[i])) {
				RemoveEdict(g_idxPads[i]);
			}
		}
		g_count = 0;
		return true;
	}
	return false;
}
public Action:TouchHook(entity, other) {
	if(other>0 && other<=MaxClients) {
		new Handle:pack;
		CreateDataTimer(0.01, DoJump, pack);
		WritePackCell(pack, entity);
		WritePackCell(pack, other);
	}
	return Plugin_Handled;
}
public Action:DoJump(Handle:timer, Handle:pack) {
	ResetPack(pack);
	new entity = ReadPackCell(pack);
	new pad = -1;
	for(new i=0;i<g_count;i++) {
		if(g_idxPads[i]==entity) {
			pad = i;
			break;
		}
	}
	if(pad!=-1) {
		new client = ReadPackCell(pack);
		decl Float:velocity[3];
		velocity[0] = g_vecPads[pad][0];
		velocity[1] = g_vecPads[pad][1];
		velocity[2] = g_vecPads[pad][2];
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		if(!StrEqual(g_sndPads[pad], "")) {
			EmitSoundToAll(g_sndPads[pad], g_idxPads[pad]);
		}
	}
}
public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast) {
	DeletePads();
	LoadPads();
}
public Action:Command_reload(client, args) {
	DeletePads();
	LoadPads();
	ReplyToCommand(client, "[SM] Reloaded %i jump pad%s.", g_count, g_count!=1?"s":"");
	return Plugin_Handled;
}
public Action:Command_remove(client, args) {
	if(DeletePads()) {
		ReplyToCommand(client, "[SM] Removed jump pads.");
	} else {
		ReplyToCommand(client, "[SM] No jump pads to remove!");
	}
	return Plugin_Handled;
}