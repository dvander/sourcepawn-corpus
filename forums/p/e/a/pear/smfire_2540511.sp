#define PLUGIN_VERSION "2.4"
#pragma semicolon 1
#pragma newdecls required
#pragma dynamic 131072

#include <sourcemod>
#include <tf2_stocks>

#define MAX_BUTTONS 25
#define IN_ALT1	(1 << 14)
#define IN_ALT2	(1 << 15)
#define IN_SPEED (1 << 17)
#define IN_WALK	(1 << 18)	
#define DATA_DIR "data/smfire"
#define SAVES_DIR "data/smfire/saves"
#define PROPS_DIR "data/smfire/props"

int lastbuttons[MAXPLAYERS + 1];
int iCounter;
int iCopy[MAXPLAYERS + 1];
int iEntity[MAXPLAYERS + 1];
float fHeadScale[MAXPLAYERS + 1];
float fTorsoScale[MAXPLAYERS + 1];
float fHandScale[MAXPLAYERS + 1];
bool bThirdperson[MAXPLAYERS + 1];
int iTrail[MAXPLAYERS + 1];
int iVoicePitch[MAXPLAYERS + 1];
bool bShift[MAXPLAYERS + 1];
int iShiftMode[MAXPLAYERS + 1];
int iShift[MAXPLAYERS + 1];
int iWeapon[MAXPLAYERS + 1];
int iMove[MAXPLAYERS + 1];
int iMoveTarget[MAXPLAYERS + 1];
bool bMove[MAXPLAYERS + 1];
bool bChoose[MAXPLAYERS + 1];
int iChoose[MAXPLAYERS + 1];
int iChooseTarget[MAXPLAYERS + 1];
bool bWarp[MAXPLAYERS + 1];
int iWarp[MAXPLAYERS + 1];
int iWarpMode[MAXPLAYERS + 1];
float fWarpAmount[MAXPLAYERS + 1];
Handle hChoose[MAXPLAYERS + 1];
Handle aSelect[MAXPLAYERS + 1];
bool bSelect[MAXPLAYERS + 1];
Handle hEquipWearableSDK;
Handle hItemSchemaSDK;
Handle hGetAttribSDK;
Handle hRuntimeAttribSDK;
Handle hRemoveAttribSDK;
Handle hDestroyAttribSDK;
Handle hGetAttribIdSDK;
Handle hItemDefSDK;
int iBeam;

public Plugin myinfo =  {
	name = "SMFire", 
	author = "pear", 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart() {
	char mod[32]; GetGameFolderName(mod, sizeof(mod));
	if (!StrEqual(mod, "tf")) {
		SetFailState("Plugin only works with Team Fortress 2!");
	}
	LoadTranslations("common.phrases");
	LoadSDKHandles("smfire");
	RegAdminCmd("sm_fire", sm_fire, ADMFLAG_BAN, "[SM] Usage: sm_fire <target> <action> <value>");
	HookEvent("player_spawn", event_playerspawn, EventHookMode_Post);
	HookEvent("player_death", event_playerdeath, EventHookMode_Post);
	HookEvent("teamplay_round_start", event_roundstart, EventHookMode_Post);
	AddNormalSoundHook(hook_sound);
	for (int i = 1; i <= MaxClients; i++) {
		fHeadScale[i] = 1.0;
		fTorsoScale[i] = 1.0;
		fHandScale[i] = 1.0;
		bThirdperson[i] = false;
		iTrail[i] = -1;
		iVoicePitch[i] = 100;
	}
	iBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

public void OnPluginEnd() {
	UnhookEvent("player_spawn", event_playerspawn, EventHookMode_Post);
	RemoveNormalSoundHook(hook_sound);
	for (int e = 1; e <= GetMaxEntities(); e++) {
		if (IsValidEntity(e)) {
			char tname[128]; GetEntPropString(e, Prop_Data, "m_iName", tname, sizeof(tname));
			if (StrContains(tname, "enttemp") == 0) {
				if (e != -1) {
					RemoveEdict(e);
				}
			}
		}
	}
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidEntity(iChoose[i]) && iChoose[i] != 0) {
			RemoveEdict(iChoose[i]);
		}
		StopActiveActions(i);
		if (aSelect[i] != INVALID_HANDLE) {
			while (GetArraySize(aSelect[i]) != 0) {
				for (int a; a < GetArraySize(aSelect[i]); a++) {
					RemoveFromArray(aSelect[i], a);
				}
			}
			ClearArray(aSelect[i]);
		}
		if (iTrail[i] != -1) {
			if (IsValidEntity(iTrail[i]))RemoveEdict(iTrail[i]);
			iTrail[i] = -1;
		}
	}
}

public void OnGameFrame() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i)) {
			if (fHeadScale[i] != 1.0) {
				SetEntPropFloat(i, Prop_Send, "m_flHeadScale", fHeadScale[i]);
			}
			if (fTorsoScale[i] != 1.0) {
				SetEntPropFloat(i, Prop_Send, "m_flTorsoScale", fTorsoScale[i]);
			}
			if (fHandScale[i] != 1.0) {
				SetEntPropFloat(i, Prop_Send, "m_flHandScale", fHandScale[i]);
			}
		}
		if (IsClientInGame(i) && aSelect[i] != INVALID_HANDLE) {
			for (int j; j < GetArraySize(aSelect[i]); j++) {
				DrawBoundingBox(i, GetArrayCell(aSelect[i], j), 0.1, { 0, 0, 255, 255 } );
			}
		}
	}
}

public void OnClientDisconnect(int client) {
	lastbuttons[client] = 0;
	StopActiveActions(client);
	if (aSelect[client] != INVALID_HANDLE) {
		while (GetArraySize(aSelect[client]) != 0) {
			for (int i; i < GetArraySize(aSelect[client]); i++) {
				RemoveFromArray(aSelect[client], i);
			}
		}
		ClearArray(aSelect[client]);
	}
	if (iTrail[client] != -1) {
		if (IsValidEntity(iTrail[client]))RemoveEdict(iTrail[client]);
		iTrail[client] = -1;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon) {
	for (int i = 0; i < MAX_BUTTONS; i++) {
		int button = (1 << i);
		if ((buttons & button)) {
			if (!(lastbuttons[client] & button)) {
				if (button == IN_WALK && bMove[client] == true && iMoveTarget[client] > 0 && IsValidEntity(iMoveTarget[client])) {
					float entorg[3]; GetEntPropVector(iMoveTarget[client], Prop_Data, "m_vecOrigin", entorg);
					float entang[3]; GetEntPropVector(iMoveTarget[client], Prop_Data, "m_angRotation", entang);
					TeleportEntity(iMove[client], entorg, entang, NULL_VECTOR);
					DeleteTempEnts(client);
					CreateTempEnts(client, iMove[client]);
				}
				if (button == IN_SPEED && bMove[client] == true && iMoveTarget[client] > 0 && IsValidEntity(iMoveTarget[client])) {
					float entorg[3]; GetEntPropVector(iMoveTarget[client], Prop_Data, "m_vecOrigin", entorg);
					float entang[3]; GetEntPropVector(iMoveTarget[client], Prop_Data, "m_angRotation", entang);
					char model[256]; GetEntPropString(iMove[client], Prop_Data, "m_ModelName", model, sizeof(model));
					char name[256]; GetEntPropString(iMove[client], Prop_Data, "m_iName", name, sizeof(name));
					PrecacheModel(model);
					int prop = CreateEntityByName("prop_dynamic");
					DispatchKeyValue(prop, "model", model);
					DispatchKeyValue(prop, "targetname", name);
					DispatchKeyValue(prop, "solid", "6");
					DispatchSpawn(prop);
					TeleportEntity(prop, entorg, entang, NULL_VECTOR);
					int red, green, blue, alpha;
					GetEntityRenderColor(iMove[client], red, green, blue, alpha);
					SetEntityRenderColor(prop, red, green, blue, alpha);
					SetEntityRenderMode(prop, GetEntityRenderMode(iMove[client]));
					SetEntityRenderFx(prop, GetEntityRenderFx(iMove[client]));
					iMove[client] = prop;
					DeleteTempEnts(client);
					CreateTempEnts(client, iMove[client]);
				}
				if (button == IN_SPEED && bShift[client] == true && iShift[client] != 0 && IsValidEntity(iShift[client])) {
					char model[256]; GetEntPropString(iShift[client], Prop_Data, "m_ModelName", model, sizeof(model));
					char name[256]; GetEntPropString(iShift[client], Prop_Data, "m_iName", name, sizeof(name));
					float entorg[3]; GetEntPropVector(iShift[client], Prop_Data, "m_vecOrigin", entorg);
					float entang[3]; GetEntPropVector(iShift[client], Prop_Data, "m_angRotation", entang);
					PrecacheModel(model);
					int prop = CreateEntityByName("prop_dynamic");
					DispatchKeyValue(prop, "model", model);
					DispatchKeyValue(prop, "targetname", name);
					DispatchKeyValue(prop, "solid", "6");
					DispatchSpawn(prop);
					TeleportEntity(prop, entorg, entang, NULL_VECTOR);
					int red, green, blue, alpha;
					GetEntityRenderColor(iShift[client], red, green, blue, alpha);
					SetEntityRenderColor(prop, red, green, blue, alpha);
					SetEntityRenderMode(prop, GetEntityRenderMode(iShift[client]));
					SetEntityRenderFx(prop, GetEntityRenderFx(iShift[client]));
				}
				if (button == IN_WALK && bChoose[client] == true && hChoose[client] != INVALID_HANDLE) {
					char line[512];
					if (IsEndOfFile(hChoose[client])) {
						FileSeek(hChoose[client], 0, SEEK_SET);
					}
					ReadFileLine(hChoose[client], line, sizeof(line));
					TrimString(line);
					PrecacheModel(line);
					char auth[256]; GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
					char buffer[128]; FormatEx(buffer, sizeof(buffer), "enttemp_%s", auth);
					float playerang[3]; GetClientEyeAngles(client, playerang);
					float playerorg[3]; GetClientEyePosition(client, playerorg);
					Handle trace = TR_TraceRayFilterEx(playerorg, playerang, MASK_SHOT, RayType_Infinite, filter_multiple, client);
					int prop = CreateEntityByName("prop_dynamic");
					DispatchKeyValue(prop, "model", line);
					DispatchKeyValue(prop, "targetname", buffer);
					DispatchKeyValue(prop, "solid", "4");
					DispatchSpawn(prop);
					SetEntityRenderColor(prop, 255, 255, 255, 140);
					SetEntityRenderMode(prop, RENDER_TRANSALPHAADD);
					if (iChoose[client] > 0) {
						float entorg[3]; GetEntPropVector(iChoose[client], Prop_Data, "m_vecOrigin", entorg);
						RemoveEdict(iChoose[client]);
						TeleportEntity(prop, entorg, NULL_VECTOR, NULL_VECTOR);
					}
					else {
						float endpos[3]; TR_GetEndPosition(endpos, trace);
						TeleportEntity(prop, endpos, NULL_VECTOR, NULL_VECTOR);
					}
					CloseHandle(trace);
					iChoose[client] = prop;
				}
				if (button == IN_SPEED && bChoose[client] == true && iChoose[client] != 0 && IsValidEntity(iChoose[client])) {
					char model[256]; GetEntPropString(iChoose[client], Prop_Data, "m_ModelName", model, sizeof(model));
					char auth[256]; GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
					char name[128]; FormatEx(name, sizeof(name), "entprop_%s", auth);
					float entorg[3]; GetEntPropVector(iChoose[client], Prop_Data, "m_vecOrigin", entorg);
					float entang[3]; GetEntPropVector(iChoose[client], Prop_Data, "m_angRotation", entang);
					PrecacheModel(model);
					int prop = CreateEntityByName("prop_dynamic");
					DispatchKeyValue(prop, "model", model);
					DispatchKeyValue(prop, "targetname", name);
					DispatchKeyValue(prop, "solid", "6");
					DispatchSpawn(prop);
					TeleportEntity(prop, entorg, entang, NULL_VECTOR);
					SetEntityRenderColor(prop, 255, 255, 255, 255);
					SetEntityRenderMode(prop, GetEntityRenderMode(iChoose[client]));
					SetEntityRenderFx(prop, GetEntityRenderFx(iChoose[client]));
					iChooseTarget[client] = prop;
					ReplyToCommand(client, "[SM] Spawned %i > %s", prop, model);
				}
				if (button == IN_SPEED && bSelect[client] == true) {
					int entity = GetAimEntity(client);
					if (IsValidEntity(entity) && entity > 0) {
						char ename[256]; GetEntityClassname(entity, ename, sizeof(ename));
						if (StrEqual(ename, "prop_dynamic")) {
							int index = -1;
							for (int a; a < GetArraySize(aSelect[client]); a++) {
								if (entity == GetArrayCell(aSelect[client], a)) {
									index = a;
								}
							}
							if (index != -1) {
								ReplyToCommand(client, "[SM] Deselected %i", GetArrayCell(aSelect[client], index));
								RemoveFromArray(aSelect[client], index);
							}
							else {
								ReplyToCommand(client, "[SM] Selected %i", entity);
								PushArrayCell(aSelect[client], entity);
							}
						}
						else {
							ReplyToCommand(client, "[SM] Target must be a prop!");
						}
					}
					else {
						ReplyToCommand(client, "[SM] Invalid entity!");
					}
				}
				if (button == IN_SPEED && bWarp[client] == true) {
					if (iWarpMode[client] == 0) {
						iWarpMode[client] = 1;
						ReplyToCommand(client, "[SM] Changed WarpMode to Angles");
					}
					else {
						iWarpMode[client] = 0;
						ReplyToCommand(client, "[SM] Changed WarpMode to Origin");
					}
				}
				if (bWarp[client] == true) {
					float vec[3];
					if (iWarpMode[client] == 0)GetEntPropVector(iWarp[client], Prop_Data, "m_vecAbsOrigin", vec);
					else GetEntPropVector(iWarp[client], Prop_Data, "m_angAbsRotation", vec);
					float amount = fWarpAmount[client];
					switch (button) {
						case IN_FORWARD: { vec[0] += amount; }
						case IN_BACK: { vec[0] -= amount; }
						case IN_MOVELEFT: { vec[1] += amount; }
						case IN_MOVERIGHT: { vec[1] -= amount; }
						case IN_JUMP: { vec[2] += amount; }
						case IN_DUCK: { vec[2] -= amount; }
					}
					if (iWarpMode[client] == 0)TeleportEntity(iWarp[client], vec, NULL_VECTOR, NULL_VECTOR);
					else TeleportEntity(iWarp[client], NULL_VECTOR, vec, NULL_VECTOR);
				}
			}
		}
	}
	lastbuttons[client] = buttons;
	if (bMove[client] == true) {
		if (IsPlayerAlive(client)) {
			int aim = GetAimEntity(client);
			if (aim > 0) {
				char tname[128]; GetEntPropString(aim, Prop_Data, "m_iName", tname, sizeof(tname));
				char auth[256]; GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
				char buffer[128]; FormatEx(buffer, sizeof(buffer), "enttemp_%s", auth);
				if (StrContains(tname, buffer) == 0) {
					if (iMoveTarget[client] != aim) {
						if (IsValidEntity(iMoveTarget[client])) {
							SetEntityRenderColor(iMoveTarget[client], 255, 255, 255, 0);
						}
						iMoveTarget[client] = aim;
						SetEntityRenderColor(iMoveTarget[client], 255, 255, 255, 128);
					}
				}
			}
		}
		else {
			DeleteTempEnts(client);
			bMove[client] = false;
			ReplyToCommand(client, "[SM] Stopped moving!");
		}
	}
	if (bShift[client] == true && iShift[client] != 0 && IsValidEntity(iShift[client])) {
		if (IsPlayerAlive(client)) {
			float playerang[3]; GetClientEyeAngles(client, playerang);
			float playerorg[3]; GetClientEyePosition(client, playerorg);
			float entorg[3]; GetEntPropVector(iShift[client], Prop_Data, "m_vecOrigin", entorg);
			float entang[3]; GetEntPropVector(iShift[client], Prop_Data, "m_angRotation", entang);
			Handle trace = TR_TraceRayFilterEx(playerorg, playerang, MASK_SHOT, RayType_Infinite, filter_multiple, client);
			float endpos[3]; TR_GetEndPosition(endpos, trace);
			if (iShiftMode[client] != 0) {
				entang[1] = playerang[1] + iShiftMode[client];
			}
			TeleportEntity(iShift[client], endpos, entang, NULL_VECTOR);
			CloseHandle(trace);
		}
		else {
			bShift[client] = false;
			iShift[client] = 0;
			iShiftMode[client] = 0;
			ReplyToCommand(client, "[SM] Stopped shifting.");
		}
	}
	if (bChoose[client] == true && iChoose[client] != 0 && IsValidEntity(iChoose[client])) {
		if (IsPlayerAlive(client)) {
			float playerang[3]; GetClientEyeAngles(client, playerang);
			float playerorg[3]; GetClientEyePosition(client, playerorg);
			float entorg[3]; GetEntPropVector(iChoose[client], Prop_Data, "m_vecOrigin", entorg);
			float entang[3]; GetEntPropVector(iChoose[client], Prop_Data, "m_angRotation", entang);
			Handle trace = TR_TraceRayFilterEx(playerorg, playerang, MASK_SHOT, RayType_Infinite, filter_multiple, client);
			float endpos[3]; TR_GetEndPosition(endpos, trace);
			entang[1] = playerang[1];
			TeleportEntity(iChoose[client], endpos, entang, NULL_VECTOR);
			CloseHandle(trace);
		}
		else {
			bChoose[client] = false;
			if (IsValidEntity(iChoose[client]) && iChoose[client] != 0) {
				RemoveEdict(iChoose[client]);
			}
			iChoose[client] = 0;
			iChooseTarget[client] = 0;
			CloseHandle(hChoose[client]);
			ReplyToCommand(client, "[SM] Stopped choosing!");
		}
	}
}

public Action event_playerspawn(Handle event, char[] name, bool dontbroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (bThirdperson[client] == true) {
		CreateTimer(0.1, spawn_thirdperson, client);
	}
	if (iTrail[client] != -1) {
		DispatchKeyValue(iTrail[client], "renderamt", "255");
	}
}

public Action event_playerdeath(Handle event, char[] name, bool dontbroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	StopActiveActions(client);
	if (iTrail[client] != -1) {
		DispatchKeyValue(iTrail[client], "renderamt", "0");
	}
}

public Action event_roundstart(Handle event, char[] name, bool dontbroadcast) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsClientConnected(i)) {
			StopActiveActions(i);
			if (aSelect[i] != INVALID_HANDLE) {
				while (GetArraySize(aSelect[i]) != 0) {
					for (int a; a < GetArraySize(aSelect[i]); a++) {
						RemoveFromArray(aSelect[i], a);
					}
				}
				ClearArray(aSelect[i]);
			}
		}
	}
}

public Action spawn_thirdperson(Handle timer, any client) {
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");
}

public Action hook_sound(int clients[64], int &numclients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags) {
	if (channel == SNDCHAN_VOICE && entity >= 1 && entity <= MaxClients) {
		if (iVoicePitch[entity] != 100) {
			pitch = iVoicePitch[entity];
			flags |= SND_CHANGEPITCH;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public bool filter_player(int entity, int mask, any data) {
	if (entity == data) {
		return false;
	}
	else {
		return true;
	}
}

public bool filter_multiple(int entity, int mask, any data) {
	if (entity == data || entity == iShift[data] || entity == iChoose[data] || entity == iChooseTarget[data]) {
		return false;
	}
	else {
		return true;
	}
}

stock int GetAimEntity(int client) {
	float org[3]; GetClientEyePosition(client, org);
	float ang[3]; GetClientEyeAngles(client, ang);
	Handle trace = TR_TraceRayFilterEx(org, ang, MASK_SHOT, RayType_Infinite, filter_player, client);
	int ent = TR_GetEntityIndex(trace);
	CloseHandle(trace);
	return ent;
}

stock int CreatePropRelative(int entity, float offset[3], char[] name) {
	float org[3]; GetEntPropVector(entity, Prop_Data, "m_vecOrigin", org);
	float ang[3]; GetEntPropVector(entity, Prop_Data, "m_angRotation", ang);
	char model[256]; GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	PrecacheModel(model);
	org[0] += offset[0];
	org[1] += offset[1];
	org[2] += offset[2];
	int prop = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(prop, "model", model);
	DispatchKeyValue(prop, "targetname", name);
	DispatchKeyValue(prop, "solid", "4");
	DispatchSpawn(prop);
	TeleportEntity(prop, org, ang, NULL_VECTOR);
	SetEntityRenderColor(prop, 255, 255, 255, 0);
	SetEntityRenderMode(prop, RENDER_TRANSALPHAADD);
	return prop;
}

stock void CreateTempEnts(int client, int entity) {
	float vector1[3]; GetEntPropVector(entity, Prop_Data, "m_vecMins", vector1);
	float vector2[3]; GetEntPropVector(entity, Prop_Data, "m_vecMaxs", vector2);
	float vector3[3];
	
	if (vector1[0] < 0) { vector1[0] /= (-1); }
	if (vector1[1] < 0) { vector1[1] /= (-1); }
	if (vector1[2] < 0) { vector1[2] /= (-1); }
	
	char auth[256]; GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
	char buffer[128]; FormatEx(buffer, sizeof(buffer), "enttemp_%s", auth);
	vector3[0] = vector1[0] + vector2[0];
	CreatePropRelative(entity, vector3, buffer);
	vector3[0] = (vector1[0] + vector2[0]) / (-1);
	CreatePropRelative(entity, vector3, buffer);
	vector3[0] = 0.0;
	vector3[1] = vector1[1] + vector2[1];
	CreatePropRelative(entity, vector3, buffer);
	vector3[1] = (vector1[1] + vector2[1]) / (-1);
	CreatePropRelative(entity, vector3, buffer);
	vector3[1] = 0.0;
	vector3[2] = vector1[2] + vector2[2];
	CreatePropRelative(entity, vector3, buffer);
	vector3[2] = (vector1[2] + vector2[2]) / (-1);
	CreatePropRelative(entity, vector3, buffer);
}

stock void DeleteTempEnts(int client) {
	for (int e = 1; e <= GetMaxEntities(); e++) {
		if (IsValidEntity(e)) {
			char tname[128]; GetEntPropString(e, Prop_Data, "m_iName", tname, sizeof(tname));
			char auth[256]; GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
			char buffer[128]; FormatEx(buffer, sizeof(buffer), "enttemp_%s", auth);
			if (StrContains(tname, buffer) == 0) {
				if (e != -1) {
					RemoveEdict(e);
				}
			}
		}
	}
}

stock void StopActiveActions(int client) {
	if (bShift[client] == true) {
		bShift[client] = false;
		iShift[client] = 0;
		iShiftMode[client] = 0;
		ReplyToCommand(client, "[SM] Stopped shifting.");
	}
	if (bMove[client] == true) {
		DeleteTempEnts(client);
		bMove[client] = false;
		ReplyToCommand(client, "[SM] Stopped moving!");
	}
	if (bChoose[client] == true) {
		bChoose[client] = false;
		if (IsValidEntity(iChoose[client]) && iChoose[client] != 0) {
			RemoveEdict(iChoose[client]);
		}
		iChoose[client] = 0;
		iChooseTarget[client] = 0;
		CloseHandle(hChoose[client]);
		ReplyToCommand(client, "[SM] Stopped choosing!");
	}
	if (bSelect[client] == true) {
		bSelect[client] = false;
		ReplyToCommand(client, "[SM] Stopped selecting!");
	}
	if (bWarp[client] == true) {
		SetEntityMoveType(client, MOVETYPE_WALK);
		bWarp[client] = false;
		iWarp[client] = 0;
		fWarpAmount[client] = 0.0;
		iWarpMode[client] = 0;
		ReplyToCommand(client, "[SM] Stopped warping!");
	}
}

public Action sm_fire(int client, int args) {
	if (client == 0) { return Plugin_Handled; }
	char arg1[256]; GetCmdArg(1, arg1, sizeof(arg1));
	char arg2[256]; GetCmdArg(2, arg2, sizeof(arg2));
	char arg3[256]; GetCmdArgString(arg3, sizeof(arg3));
	if (StrEqual(arg1, "reload")) {
		ServerCommand("sm plugins reload smfire");
	}
	else if (args < 2) {
		ReplyToCommand(client, "[SM] Usage: sm_fire <target> <action> <value>");
	}
	else {
		int len1 = strlen(arg1); int len2 = strlen(arg2);
		int len3 = len1 + len2;
		strcopy(arg3, sizeof(arg3), arg3[len3 + 2]);
		ent_fire(client, arg1, arg2, arg3);
	}
	return Plugin_Handled;
}

public void ent_fire(int client, char[] target, char[] action, char[] value) {
	int num;
	if (StrEqual(target, "!self", false)) {
		int itarget = client;
		ent_action(client, itarget, action, value, false);
	}
	else if (StrEqual(target, "!wep", false)) {
		int itarget = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		ent_action(client, itarget, action, value, false);
	}
	else if (StrEqual(target, "!picker", false)) {
		int itarget = GetClientAimTarget(client, false);
		ent_action(client, itarget, action, value, false);
	}
	else if (StrEqual(target, "!all", false)) {
		if (StrEqual(action, "data", false)) {
			for (int e = 1; e <= GetMaxEntities(); e++) {
				if (IsValidEntity(e)) {
					if (e != -1) {
						int itarget = e;
						ent_action(client, itarget, action, value, true);
						num++;
					}
				}
			}
		}
		else {
			for (int i = 1; i <= MaxClients; i++) {
				if (IsClientInGame(i) && IsClientConnected(i)) {
					int itarget = i;
					ent_action(client, itarget, action, value, true);
				}
			}
		}
	}
	else if (StrEqual(target, "!blue", false)) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && IsClientConnected(i)) {
				int team = GetClientTeam(i);
				if (team == 3) {
					int itarget = i;
					ent_action(client, itarget, action, value, true);
					num++;
				}
			}
		}
	}
	else if (StrEqual(target, "!red", false)) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && IsClientConnected(i)) {
				int team = GetClientTeam(i);
				if (team == 2) {
					int itarget = i;
					ent_action(client, itarget, action, value, true);
					num++;
				}
			}
		}
	}
	else if (StrEqual(target, "!bots", false)) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i)) {
				int itarget = i;
				ent_action(client, itarget, action, value, true);
				num++;
			}
		}
	}
	else if (StrEqual(target, "!select", false)) {
		if (StrEqual(action, "data")) {
			if (aSelect[client] != INVALID_HANDLE) {
				for (int i; i < GetArraySize(aSelect[client]); i++) {
					if (IsValidEntity(GetArrayCell(aSelect[client], i)) && GetArrayCell(aSelect[client], i) > 0) {
						PrintToConsole(client, "%i. > %i", i, GetArrayCell(aSelect[client], i));
						num++;
					}
				}
			}
			if (num == 0) {
				ReplyToCommand(client, "[SM] No props selected!");
			}
		}
		else if (StrEqual(action, "clear")) {
			if (aSelect[client] != INVALID_HANDLE) {
				while (GetArraySize(aSelect[client]) != 0) {
					for (int i; i < GetArraySize(aSelect[client]); i++) {
						RemoveFromArray(aSelect[client], i);
						num++;
					}
				}
				ClearArray(aSelect[client]);
			}
			if (num > 0) {
				ReplyToCommand(client, "[SM] Selection cleared!");
			}
			else {
				ReplyToCommand(client, "[SM] No props selected!");
			}
		}
		else {
			if (aSelect[client] != INVALID_HANDLE) {
				if (GetArraySize(aSelect[client]) == 0) {
					ReplyToCommand(client, "[SM] No props selected!");
				}
				else {
					for (int i; i < GetArraySize(aSelect[client]); i++) {
						if (IsValidEntity(GetArrayCell(aSelect[client], i)) && GetArrayCell(aSelect[client], i) > 0) {
							int itarget = GetArrayCell(aSelect[client], i);
							ent_action(client, itarget, action, value, true);
							num++;
						}
					}
					if (num == 0) {
						ReplyToCommand(client, "[SM] No props selected!");
					}
				}
			}
			else {
				ReplyToCommand(client, "[SM] No props selected!");
			}
		}
	}
	else if (StrEqual(target, "!aim", false)) {
		float playerang[3]; GetClientEyeAngles(client, playerang);
		float playerorg[3]; GetClientEyePosition(client, playerorg);
		Handle trace = TR_TraceRayFilterEx(playerorg, playerang, MASK_SHOT, RayType_Infinite, filter_player, client);
		if (TR_DidHit(trace)) {
			float endpos[3]; TR_GetEndPosition(endpos, trace);
			int entity = TR_GetEntityIndex(trace);
			ent_trace(client, playerorg, playerang, endpos, entity, action, value);
		}
	}
	else if (StrEqual(target, "!file", false)) {
		ent_file(client, action, value);
	}
	else if (StrContains(target, "@", false) == 0) {
		strcopy(target, 64, target[1]);
		int itarget = FindTarget(client, target, false, false);
		if (itarget != -1) {
			ent_action(client, itarget, action, value, false);
		}
	}
	else if (StrContains(target, "*", false) == 0) {
		strcopy(target, 64, target[1]);
		int itarget = StringToInt(target);
		ent_action(client, itarget, action, value, false);
	}
	else if (StrContains(target, "#", false) == 0) {
		strcopy(target, 64, target[1]);
		for (int e = 1; e <= GetMaxEntities(); e++) {
			if (IsValidEntity(e)) {
				char tname[128]; GetEntPropString(e, Prop_Data, "m_iName", tname, sizeof(tname));
				if (StrEqual(target, tname)) {
					if (e != -1) {
						int itarget = e;
						ent_action(client, itarget, action, value, true);
						num++;
					}
				}
			}
		}
	}
	else {
		for (int e = 1; e <= GetMaxEntities(); e++) {
			if (IsValidEntity(e)) {
				char ename[128]; GetEntityClassname(e, ename, sizeof(ename));
				if (StrEqual(target, ename)) {
					if (e != -1) {
						int itarget = e;
						ent_action(client, itarget, action, value, true);
						num++;
					}
				}
			}
		}
	}
	
	if (StrEqual(action, "data", false) && num >= 1) {
		ReplyToCommand(client, "[SM] %i entities printed to console!", num);
	}
	iCounter = 0;
}

public void ent_action(int client, int itarget, char[] action, char[] value, bool multiple) {
	StopActiveActions(client);
	iCounter++;
	if (itarget <= 0 || !IsValidEntity(itarget)) {
		if (iCounter == 1)
			ReplyToCommand(client, "[SM] Invalid target!");
	}
	else if (StrEqual(action, "data", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		char tname[128]; GetEntPropString(itarget, Prop_Data, "m_iName", tname, sizeof(tname));
		char model[512]; GetEntPropString(itarget, Prop_Data, "m_ModelName", model, sizeof(model));
		char parent[256]; GetEntPropString(itarget, Prop_Data, "m_iParent", parent, sizeof(parent));
		float entang[3]; GetEntPropVector(itarget, Prop_Data, "m_angRotation", entang);
		float entorg[3]; GetEntPropVector(itarget, Prop_Data, "m_vecOrigin", entorg);
		float entvec[3]; GetEntPropVector(itarget, Prop_Data, "m_vecVelocity", entvec);
		if (StrEqual(tname, "")) { strcopy(tname, sizeof(tname), "N/A"); }
		if (StrEqual(model, "")) { strcopy(model, sizeof(model), "N/A"); }
		if (StrEqual(parent, "")) { strcopy(parent, sizeof(parent), "N/A"); }
		if (multiple == false) {
			ReplyToCommand(client, "\x03%i > Classname: %s - Name: %s", itarget, ename, tname);
			if (StrEqual(value, "full", false)) {
				ReplyToCommand(client, "Model: %s", model);
				ReplyToCommand(client, "Parent: %s", model);
				ReplyToCommand(client, "Origin: %.0f %.0f %.0f", entorg[0], entorg[1], entorg[2]);
				ReplyToCommand(client, "Angles: %.0f %.0f %.0f", entang[0], entang[1], entang[2]);
				ReplyToCommand(client, "Velocity: %.0f %.0f %.0f", entvec[0], entvec[1], entvec[2]);
			}
		}
		else if (StrEqual(value, "full", false)) {
			PrintToConsole(client, "%i > Classname: %s - Name: %s - Model: %s", itarget, ename, tname, model);
		}
		else {
			PrintToConsole(client, "%i > Classname: %s - Name: %s", itarget, ename, tname);
		}
	}
	else if (StrEqual(action, "removeslot", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] removeslot <value>");
			}
			else if (StrEqual(value, "all")) {
				TF2_RemoveAllWeapons(itarget);
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Removed all slots from target");
			}
			else {
				int ivalue = StringToInt(value);
				TF2_RemoveWeaponSlot(itarget, ivalue);
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Removed slot %i from target", ivalue);
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "stun", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] stun <duration>");
			}
			else {
				float fvalue = StringToFloat(value);
				TF2_StunPlayer(itarget, fvalue, 0.0, TF_STUNFLAGS_BIGBONK, 0);
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Stunned target for %.0f seconds", fvalue);
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "scare", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] scare <duration>");
			}
			else {
				float fvalue = StringToFloat(value);
				TF2_StunPlayer(itarget, fvalue, 0.0, TF_STUNFLAGS_GHOSTSCARE, 0);
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Scared target for %.0f seconds", fvalue);
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "trail", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] trail <R+G+B/off>");
			}
			else if (StrEqual(value, "off")) {
				if (iTrail[itarget] != -1) {
					if (IsValidEntity(iTrail[itarget]))RemoveEdict(iTrail[itarget]);
					iTrail[itarget] = -1;
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Disabled trail for target");
				}
				else {
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] No trail found for target!");
				}
			}
			else {
				char num[32][3]; ExplodeString(value, "+", num, 3, sizeof(num));
				int red = StringToInt(num[0]);
				int green = StringToInt(num[1]);
				int blue = StringToInt(num[2]);
				char color[128]; Format(color, sizeof(color), "%i %i %i", red, green, blue);
				if (iTrail[itarget] != -1) {
					DispatchKeyValue(iTrail[itarget], "rendercolor", color);
				}
				else {
					char tname[64]; Format(tname, sizeof(tname), "player_%i", itarget);
					int ent = CreateEntityByName("env_spritetrail");
					DispatchKeyValue(ent, "renderamt", "255");
					DispatchKeyValue(ent, "rendermode", "1");
					DispatchKeyValue(ent, "spritename", "materials/sprites/spotlight.vmt");
					DispatchKeyValue(ent, "lifetime", "3.0");
					DispatchKeyValue(ent, "startwidth", "8.0");
					DispatchKeyValue(ent, "endwidth", "0.1");
					DispatchKeyValue(ent, "rendercolor", color);
					DispatchSpawn(ent);
					float targetorg[3]; GetClientAbsOrigin(itarget, targetorg);
					targetorg[2] += 10.0;
					TeleportEntity(ent, targetorg, NULL_VECTOR, NULL_VECTOR);
					DispatchKeyValue(itarget, "targetname", tname);
					SetVariantString(tname);
					AcceptEntityInput(ent, "SetParent", -1, -1);
					iTrail[itarget] = ent;
				}
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Set trail for target to %s", value);
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "setname", false)) {
		if (StrEqual(value, "")) {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] setname <name>");
		}
		else {
			char newvalue[128]; Format(newvalue, sizeof(newvalue), "targetname %s", value);
			SetVariantString(newvalue);
			AcceptEntityInput(itarget, "addoutput");
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Set name to %s of target", value);
		}
	}
	else if (StrEqual(action, "kill", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			ForcePlayerSuicide(itarget);
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Killed target");
		}
		else {
			if (aSelect[client] != INVALID_HANDLE) {
				for (int i; i < GetArraySize(aSelect[client]); i++) {
					if (itarget == GetArraySize(aSelect[client])) {
						RemoveFromArray(aSelect[client], i);
						i = 0;
					}
				}
			}
			RemoveEdict(itarget);
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Removed target");
		}
	}
	else if (StrEqual(action, "regen", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			TF2_RegeneratePlayer(itarget);
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Regenerated target");
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "health", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] health <amount>");
			}
			else {
				int health = StringToInt(value);
				SetEntProp(itarget, Prop_Data, "m_iHealth", health);
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Added %i health to target target", health);
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "respawn", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			TF2_RespawnPlayer(itarget);
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Respawned target");
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "addorg", false)) {
		if (StrEqual(value, "")) {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] addorg <x> <y> <z>");
		}
		else {
			float entorg[3]; GetEntPropVector(itarget, Prop_Data, "m_vecOrigin", entorg);
			char num[32][6]; ExplodeString(value, " ", num, 6, sizeof(num));
			entorg[0] += StringToFloat(num[0]);
			entorg[1] += StringToFloat(num[1]);
			entorg[2] += StringToFloat(num[2]);
			TeleportEntity(itarget, entorg, NULL_VECTOR, NULL_VECTOR);
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Added origin to target");
		}
	}
	else if (StrEqual(action, "addang", false)) {
		if (StrEqual(value, "")) {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] addang <pitch> <yaw> <roll>");
		}
		else {
			float entang[3]; GetEntPropVector(itarget, Prop_Data, "m_angRotation", entang);
			char num[32][6]; ExplodeString(value, " ", num, 6, sizeof(num));
			entang[0] += StringToFloat(num[0]);
			entang[1] += StringToFloat(num[1]);
			entang[2] += StringToFloat(num[2]);
			TeleportEntity(itarget, NULL_VECTOR, entang, NULL_VECTOR);
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Added angles to target");
		}
	}
	else if (StrEqual(action, "addvel", false)) {
		if (StrEqual(value, "")) {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] addvel <x> <y> <z>");
		}
		else {
			float entvel[3]; GetEntPropVector(itarget, Prop_Data, "m_vecVelocity", entvel);
			char num[32][6]; ExplodeString(value, " ", num, 6, sizeof(num));
			entvel[0] += StringToFloat(num[0]);
			entvel[1] += StringToFloat(num[1]);
			entvel[2] += StringToFloat(num[2]);
			TeleportEntity(itarget, NULL_VECTOR, NULL_VECTOR, entvel);
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Added velocity to target");
		}
	}
	else if (StrEqual(action, "setorg", false)) {
		if (StrEqual(value, "")) {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] setorg <x> <y> <z>");
		}
		else {
			float entorg[3]; char num[32][6];
			ExplodeString(value, " ", num, 6, sizeof(num));
			entorg[0] = StringToFloat(num[0]);
			entorg[1] = StringToFloat(num[1]);
			entorg[2] = StringToFloat(num[2]);
			TeleportEntity(itarget, entorg, NULL_VECTOR, NULL_VECTOR);
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Set origin of target");
		}
	}
	else if (StrEqual(action, "setang", false)) {
		if (StrEqual(value, "")) {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] setang <pitch> <yaw> <roll>");
		}
		else {
			float entang[3]; char num[32][6];
			ExplodeString(value, " ", num, 6, sizeof(num));
			entang[0] = StringToFloat(num[0]);
			entang[1] = StringToFloat(num[1]);
			entang[2] = StringToFloat(num[2]);
			TeleportEntity(itarget, NULL_VECTOR, entang, NULL_VECTOR);
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Set angles of target");
		}
	}
	else if (StrEqual(action, "setvel", false)) {
		if (StrEqual(value, "")) {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] setvel <x> <y> <z>");
		}
		else {
			float entvel[3]; char num[32][6];
			ExplodeString(value, " ", num, 6, sizeof(num));
			entvel[0] = StringToFloat(num[0]);
			entvel[1] = StringToFloat(num[1]);
			entvel[2] = StringToFloat(num[2]);
			TeleportEntity(itarget, NULL_VECTOR, NULL_VECTOR, entvel);
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Set velocity of target");
		}
	}
	else if (StrEqual(action, "copy", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "prop_dynamic") || StrEqual(ename, "prop_physics") || StrEqual(ename, "prop_static")) {
			if (StrEqual(value, "")) {
				ReplyToCommand(client, "[SM] copy <x> <y> <z> <pitch> <yaw> <roll>");
			}
			else {
				char model[512]; GetEntPropString(itarget, Prop_Data, "m_ModelName", model, sizeof(model));
				char tname[128]; GetEntPropString(itarget, Prop_Data, "m_iName", tname, sizeof(tname));
				float entang[3]; GetEntPropVector(itarget, Prop_Data, "m_angRotation", entang);
				float entorg[3]; GetEntPropVector(itarget, Prop_Data, "m_vecOrigin", entorg);
				int ent = CreateEntityByName("prop_dynamic");
				DispatchKeyValue(ent, "targetname", tname);
				DispatchKeyValue(ent, "model", model);
				DispatchKeyValue(ent, "solid", "6");
				DispatchKeyValue(ent, "physdamagescale", "0.0");
				DispatchSpawn(ent);
				ActivateEntity(ent);
				char num[32][12]; ExplodeString(value, " ", num, 12, sizeof(num));
				entorg[0] += StringToFloat(num[0]);
				entorg[1] += StringToFloat(num[1]);
				entorg[2] += StringToFloat(num[2]);
				entang[0] += StringToFloat(num[3]);
				entang[1] += StringToFloat(num[4]);
				entang[2] += StringToFloat(num[5]);
				TeleportEntity(ent, entorg, entang, NULL_VECTOR);
				int red, green, blue, alpha;
				GetEntityRenderColor(itarget, red, green, blue, alpha);
				SetEntityRenderColor(ent, red, green, blue, alpha);
				SetEntityRenderMode(ent, GetEntityRenderMode(itarget));
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Copied prop to location");
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a prop!");
		}
	}
	else if (StrEqual(action, "class", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			TFClassType class;
			if (StrEqual(value, "scout", false)) { class = TFClass_Scout; }
			else if (StrEqual(value, "soldier", false)) { class = TFClass_Soldier; }
			else if (StrEqual(value, "pyro", false)) { class = TFClass_Pyro; }
			else if (StrEqual(value, "demoman", false)) { class = TFClass_DemoMan; }
			else if (StrEqual(value, "heavy", false)) { class = TFClass_Heavy; }
			else if (StrEqual(value, "engineer", false)) { class = TFClass_Engineer; }
			else if (StrEqual(value, "medic", false)) { class = TFClass_Medic; }
			else if (StrEqual(value, "sniper", false)) { class = TFClass_Sniper; }
			else if (StrEqual(value, "spy", false)) { class = TFClass_Spy; }
			if (class == TFClass_Unknown) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Invalid class!");
			}
			else {
				TF2_SetPlayerClass(itarget, class);
				SetEntityHealth(itarget, 25);
				TF2_RegeneratePlayer(itarget);
				int weapon = GetPlayerWeaponSlot(itarget, TFWeaponSlot_Primary);
				if (IsValidEntity(weapon)) {
					SetEntPropEnt(itarget, Prop_Send, "m_hActiveWeapon", weapon);
				}
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Set class to %s for target", value);
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "setheadscale", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] setheadscale <value>");
			}
			else {
				fHeadScale[itarget] = StringToFloat(value);
				SetEntPropFloat(itarget, Prop_Send, "m_flHeadScale", fHeadScale[itarget]);
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Set headscale to %.0f for target", StringToFloat(value));
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "settorsoscale", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] settorsoscale <value>");
			}
			else {
				fTorsoScale[itarget] = StringToFloat(value);
				SetEntPropFloat(itarget, Prop_Send, "m_flTorsoScale", fTorsoScale[itarget]);
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Set torsoscale to %.0f for target", StringToFloat(value));
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "sethandscale", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] sethandscale <value>");
			}
			else {
				fHandScale[itarget] = StringToFloat(value);
				SetEntPropFloat(itarget, Prop_Send, "m_flHandScale", fHandScale[itarget]);
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Set handscale to %.0f for target", StringToFloat(value));
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "resetscale", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			fHeadScale[itarget] = 1.0;
			fTorsoScale[itarget] = 1.0;
			fHandScale[itarget] = 1.0;
			SetVariantString("1.0");
			AcceptEntityInput(itarget, "setmodelscale");
			SetEntPropFloat(itarget, Prop_Send, "m_flHeadScale", 1.0);
			SetEntPropFloat(itarget, Prop_Send, "m_flTorsoScale", 1.0);
			SetEntPropFloat(itarget, Prop_Send, "m_flHandScale", 1.0);
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Reset scales for target");
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "fp", false) || StrEqual(action, "firstperson", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			SetVariantInt(0);
			AcceptEntityInput(itarget, "SetForcedTauntCam");
			bThirdperson[itarget] = false;
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Set firstperson for target");
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "tp", false) || StrEqual(action, "thirdperson", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			SetVariantInt(1);
			AcceptEntityInput(itarget, "SetForcedTauntCam");
			bThirdperson[itarget] = true;
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Set thirdperson for target");
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "teleport", false)) {
		if (StrEqual(value, "!picker", false)) {
			int newtarget = GetClientAimTarget(client, false);
			float entorg[3]; GetEntPropVector(newtarget, Prop_Data, "m_vecAbsOrigin", entorg);
			TeleportEntity(itarget, entorg, NULL_VECTOR, NULL_VECTOR);
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Teleported target to !picker");
		}
		else if (StrEqual(value, "!self", false)) {
			int newtarget = client;
			float entorg[3]; GetEntPropVector(newtarget, Prop_Data, "m_vecAbsOrigin", entorg);
			TeleportEntity(itarget, entorg, NULL_VECTOR, NULL_VECTOR);
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Teleported target to !self");
		}
		else if (StrContains(value, "@", false) == 0) {
			char tvalue[256];
			strcopy(tvalue, 64, value[1]);
			int newtarget = FindTarget(client, tvalue, false, false);
			if (newtarget != -1) {
				float entorg[3]; GetEntPropVector(newtarget, Prop_Data, "m_vecAbsOrigin", entorg);
				TeleportEntity(itarget, entorg, NULL_VECTOR, NULL_VECTOR);
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Teleported target to %N", newtarget);
			}
		}
		else if (StrContains(value, "*", false) == 0) {
			char tvalue[256];
			strcopy(tvalue, 64, value[1]);
			int newtarget = StringToInt(tvalue);
			float entorg[3]; GetEntPropVector(newtarget, Prop_Data, "m_vecAbsOrigin", entorg);
			TeleportEntity(itarget, entorg, NULL_VECTOR, NULL_VECTOR);
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Teleported target to %i", newtarget);
		}
		else if (StrEqual(value, "")) {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] teleport <target>");
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target invalid!");
		}
	}
	else if (StrEqual(action, "addcond", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] addcond <condition>");
			}
			else {
				int condition = StringToInt(value);
				TF2_AddCondition(itarget, view_as<TFCond>(condition));
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Added condition %i to target", StringToInt(value));
			}
			
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "removecond", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] removecond <condition>");
			}
			else {
				int condition = StringToInt(value);
				TF2_RemoveCondition(itarget, view_as<TFCond>(condition));
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Removed condition %i for target", StringToInt(value));
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "pitch", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				iVoicePitch[itarget] = 100;
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Reset pitch for target");
			}
			else {
				iVoicePitch[itarget] = StringToInt(value);
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Set pitch to %i", StringToInt(value));
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "killstreak", false) || StrEqual(action, "ks", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] killstreak <amount/reset>");
			}
			else if (StrEqual(value, "reset")) {
				SetEntProp(client, Prop_Send, "m_nStreaks", 0, _, 0);
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Reset killstreak for target");
			}
			else {
				SetEntProp(client, Prop_Send, "m_nStreaks", StringToInt(value), _, 0);
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Set killstreak to %i", StringToInt(value));
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "sheen", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player") || StrContains(ename, "tf_weapon") >= 0) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] sheen <sheen index/reset> <effect index>");
			}
			else {
				char part[32][6]; ExplodeString(value, " ", part, 6, sizeof(part));
				int weapon = itarget;
				if (StrEqual(ename, "player"))weapon = GetEntPropEnt(itarget, Prop_Data, "m_hActiveWeapon");
				if (StrEqual(part[0], "reset")) {
					SetAttrib(weapon, 2025, 0.0);
					SetAttrib(weapon, 2014, 0.0);
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Reset sheen of weapon");
				}
				else {
					int sheen = StringToInt(part[0]);
					int effect = StringToInt(part[1]);
					if (sheen < 0 || effect < 0) {
						if (iCounter == 1)
							ReplyToCommand(client, "[SM] Negative values not permitted");
					}
					else {
						char sheens[][] =  {
							"", 
							"Team Shine", 
							"Deadly Daffodil", 
							"Manndarin", 
							"Mean Green", 
							"Agonizing Emerald", 
							"Villainous Violet", 
							"Hot Rod"
						};
						char effects[][] =  {
							"", 
							"Fire Horns", 
							"Cerebral Discharge", 
							"Tornado", 
							"Flames", 
							"Singularity", 
							"Incinerator", 
							"Hypno-Beam"
						};
						SetAttrib(weapon, 2025, 3.0);
						SetAttrib(weapon, 2014, StringToFloat(part[0]));
						SetAttrib(weapon, 2013, 2001.0 + StringToFloat(part[1]));
						if (iCounter == 1)
							ReplyToCommand(client, "[SM] Set sheen to '%s' and effect to '%s'", sheens[sheen], effects[effect]);
					}
				}
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player or weapon!");
		}
	}
	else if (StrEqual(action, "index", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player") || StrContains(ename, "tf_weapon") >= 0) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] index <item index>");
			}
			else {
				int weapon = itarget;
				if (StrEqual(ename, "player"))weapon = GetEntPropEnt(itarget, Prop_Data, "m_hActiveWeapon");
				SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", StringToInt(value));
				ReplyToCommand(client, "[SM] Set active weapon's index to \"%s\"", value);
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player or weapon!");
		}
	}
	else if (StrEqual(action, "color", false)) {
		if (StrEqual(value, "")) {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] color <R+G+B+A/reset>");
		}
		else {
			char num[32][6]; ExplodeString(value, "+", num, 6, sizeof(num));
			int red = StringToInt(num[0]);
			int green = StringToInt(num[1]);
			int blue = StringToInt(num[2]);
			int alpha = StringToInt(num[3]);
			if (StrEqual(num[0], "")) { red = 255; }
			if (StrEqual(num[1], "")) { green = 255; }
			if (StrEqual(num[2], "")) { blue = 255; }
			if (StrEqual(num[3], "")) { alpha = 255; }
			if (StrEqual(value, "reset")) {
				red = 255;
				green = 255;
				blue = 255;
				alpha = 255;
			}
			SetEntityRenderColor(itarget, red, green, blue, alpha);
			SetEntityRenderMode(itarget, RENDER_TRANSALPHAADD);
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Color set to %i+%i+%i+%i for target", red, green, blue, alpha);
		}
	}
	else if (StrEqual(action, "setclip", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player") || StrContains(ename, "tf_weapon") >= 0) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] setclip <value>");
			}
			else {
				int weapon = itarget;
				if (StrEqual(ename, "player"))weapon = GetEntPropEnt(itarget, Prop_Data, "m_hActiveWeapon");
				SetEntProp(weapon, Prop_Data, "m_iClip1", StringToInt(value));
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Set clipsize of weapon to %i", StringToInt(value));
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player or weapon!");
		}
	}
	else if (StrEqual(action, "firerate", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player") || StrContains(ename, "tf_weapon") >= 0) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] firerate <rate>");
			}
			else {
				float rate = StringToFloat(value);
				int weapon = itarget;
				if (StrEqual(ename, "player"))weapon = GetEntPropEnt(itarget, Prop_Data, "m_hActiveWeapon");
				SetAttrib(weapon, 6, rate);
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Set firerate of weapon to %.2f", StringToFloat(value));
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player or weapon!");
		}
	}
	else if (StrEqual(action, "noclip", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				MoveType movetype = GetEntityMoveType(itarget);
				if (movetype != MOVETYPE_NOCLIP) {
					SetEntityMoveType(itarget, MOVETYPE_NOCLIP);
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Turned noclip on for target");
				}
				else {
					SetEntityMoveType(itarget, MOVETYPE_WALK);
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Turned noclip off for target");
				}
			}
			else {
				if (StrEqual(value, "on")) {
					SetEntityMoveType(itarget, MOVETYPE_NOCLIP);
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Turned noclip on for target");
				}
				else if (StrEqual(value, "off")) {
					SetEntityMoveType(itarget, MOVETYPE_WALK);
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Turned noclip off for target");
				}
				else {
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] noclip <on/off>");
				}
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "freeze", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				MoveType movetype = GetEntityMoveType(itarget);
				if (movetype != MOVETYPE_NONE) {
					SetEntityMoveType(itarget, MOVETYPE_NONE);
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Froze target");
				}
				else {
					SetEntityMoveType(itarget, MOVETYPE_WALK);
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Unfroze target");
				}
			}
			else {
				if (StrEqual(value, "on")) {
					SetEntityMoveType(itarget, MOVETYPE_NONE);
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Froze target");
				}
				else if (StrEqual(value, "off")) {
					SetEntityMoveType(itarget, MOVETYPE_WALK);
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Unfroze target");
				}
				else {
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] freeze <on/off>");
				}
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "play", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				iVoicePitch[itarget] = 100;
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] play <soundpath>");
			}
			else {
				if (PrecacheSound(value)) {
					EmitSoundToClient(itarget, value);
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Played %s to target", StringToInt(value));
				}
				else {
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Invalid soundpath!");
				}
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "wear", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] wear <index>");
			}
			else {
				int entity = CreateEntityByName("tf_wearable");
				if (entity != -1) {
					SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", StringToInt(value));
					SetEntProp(entity, Prop_Send, "m_iEntityQuality", 6);
					SetEntProp(entity, Prop_Send, "m_iEntityLevel", 10);
					SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", itarget);
					SetEntPropEnt(entity, Prop_Send, "moveparent", itarget);
					SetEntProp(entity, Prop_Send, "m_bInitialized", 1);
					DispatchSpawn(entity);
					SDKCall(hEquipWearableSDK, itarget, entity);
					SetEntityRenderMode(entity, RENDER_NORMAL);
					SetEntityRenderColor(entity, 255, 255, 255, 255);
				}
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "clearprops", false)) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			int num;
			if (StrEqual(value, "all")) {
				if (iCounter == 1) {
					for (int e = 1; e <= GetMaxEntities(); e++) {
						if (IsValidEntity(e)) {
							char tname[128]; GetEntPropString(e, Prop_Data, "m_iName", tname, sizeof(tname));
							if (StrContains(tname, "entprop_") == 0) {
								if (e != -1) {
									RemoveEdict(e);
									num++;
								}
							}
						}
					}
					if (num > 0) {
						ReplyToCommand(client, "[SM] %i props cleared", num);
					}
					else {
						ReplyToCommand(client, "[SM] No user props found");
					}
				}
			}
			else {
				for (int e = 1; e <= GetMaxEntities(); e++) {
					if (IsValidEntity(e)) {
						char tname[128]; GetEntPropString(e, Prop_Data, "m_iName", tname, sizeof(tname));
						char auth[256]; GetClientAuthId(itarget, AuthId_SteamID64, auth, sizeof(auth));
						char buffer[128]; FormatEx(buffer, sizeof(buffer), "entprop_%s", auth);
						if (StrContains(tname, buffer) == 0) {
							if (e != -1) {
								RemoveEdict(e);
								num++;
							}
						}
					}
				}
				if (num > 0) {
					ReplyToCommand(client, "[SM] %i props cleared from %N", num, itarget);
				}
				else {
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] No props found for target");
				}
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else if (StrEqual(action, "mod", false)) {
		if (StrEqual(value, "")) {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] mod <attrib index/list/reset> <value/reset>");
		}
		else {
			char part[32][6]; ExplodeString(value, " ", part, 6, sizeof(part));
			if (StrEqual(part[0], "reset")) {
				ResetAttribs(itarget);
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] Reset all attributes of target");
			}
			else if (StrEqual(part[0], "list")) {
				char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
				if (StrEqual(ename, "tf_wearable") || StrContains(ename, "tf_weapon") >= 0) {
					int index = GetEntProp(itarget, Prop_Send, "m_iItemDefinitionIndex");
					int indexes[16];
					int values[16];
					int num = ListAttribs(index, indexes, values);
					if (num != -1) {
						for (int i = 0; i < num; i++) {
							PrintToConsole(client, "Attrib: %i, Value: %.2f", indexes[i], values[i]);
						}
						ReplyToCommand(client, "[SM] Printed %i attributes of [%i] to console!", num, index);
					}
					else {
						if (iCounter == 1)
							ReplyToCommand(client, "[SM] No attributes for that target!");
					}
				}
				else {
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Target must be a weapon or wearable!");
				}
			}
			else {
				int index = StringToInt(part[0]);
				if (StrEqual(part[1], "reset")) {
					RemoveAttrib(itarget, index);
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Removed attribute %i from target", index);
				}
				else if (StrEqual(part[1], "")) {
					float val = GetAttrib(itarget, index);
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] mod %s has value: %.2f", part[0], val);
					else if (iCounter >= 2) {
						PrintToConsole(client, "[%i] mod %s value: %.2f", itarget, part[0], val);
					}
				}
				else {
					float val = StringToFloat(part[1]);
					SetAttrib(itarget, index, val);
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Set attribute %i to %.2f for target", index, val);
				}
			}
		}
	}
	else if (StrContains(action, "m_", false) == 0) {
		PropFieldType type;
		int info = FindDataMapInfo(itarget, action, type);
		if (info != -1) {
			if (StrEqual(value, "")) {
				char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
				if (type == PropField_Integer) {
					int data = GetEntProp(itarget, Prop_Data, action);
					if (StrEqual(ename, "player")) {
						ReplyToCommand(client, "[%N] \x03%i", itarget, data);
					}
					else {
						ReplyToCommand(client, "[%i] \x03%i", itarget, data);
					}
				}
				else if (type == PropField_Float) {
					float data = GetEntPropFloat(itarget, Prop_Data, action);
					if (StrEqual(ename, "player")) {
						ReplyToCommand(client, "[%N] \x03%.2f", itarget, data);
					}
					else {
						ReplyToCommand(client, "[%i] \x03%.2f", itarget, data);
					}
				}
				else if (type == PropField_String || type == PropField_String_T) {
					char buffer[256];
					GetEntPropString(itarget, Prop_Data, action, buffer, sizeof(buffer));
					if (StrEqual(ename, "player")) {
						ReplyToCommand(client, "[%N] \x03%s", itarget, buffer);
					}
					else {
						ReplyToCommand(client, "[%i] \x03%s", itarget, buffer);
					}
				}
				else if (type == PropField_Vector) {
					float vector[3];
					GetEntPropVector(itarget, Prop_Data, action, vector);
					if (StrEqual(ename, "player")) {
						ReplyToCommand(client, "[%N] \x03%.0f %.0f %.0f", itarget, vector[0], vector[1], vector[2]);
					}
					else {
						ReplyToCommand(client, "[%i] \x03%.0f %.0f %.0f", itarget, vector[0], vector[1], vector[2]);
					}
				}
				else if (type == PropField_Entity) {
					int data = GetEntPropEnt(itarget, Prop_Data, action);
					if (StrEqual(ename, "player")) {
						ReplyToCommand(client, "[%N] \x03%i", itarget, data);
					}
					else {
						ReplyToCommand(client, "[%i] \x03%i", itarget, data);
					}
				}
				else {
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Type not supported!");
				}
			}
			else {
				if (type == PropField_Integer) {
					SetEntProp(itarget, Prop_Data, action, StringToInt(value));
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Set %s to %s", action, value);
				}
				else if (type == PropField_Float) {
					SetEntPropFloat(itarget, Prop_Data, action, StringToFloat(value));
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Set %s to %s", action, value);
				}
				else if (type == PropField_String || type == PropField_String_T) {
					SetEntPropString(itarget, Prop_Data, action, value);
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Set %s to %s", action, value);
				}
				else if (type == PropField_Vector) {
					float vector[3]; char num[64][6];
					ExplodeString(value, " ", num, 3, sizeof(num), false);
					vector[0] = StringToFloat(num[0]);
					vector[1] = StringToFloat(num[1]);
					vector[2] = StringToFloat(num[2]);
					SetEntPropVector(itarget, Prop_Data, action, vector);
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Set %s to %.0f %.0f %.0f", action, vector[0], vector[1], vector[2]);
				}
				else if (type == PropField_Entity) {
					if (IsValidEntity(StringToInt(value))) {
						SetEntPropEnt(itarget, Prop_Data, action, StringToInt(value));
						if (iCounter == 1)
							ReplyToCommand(client, "[SM] Set %s to %s", action, value);
					}
					else {
						if (iCounter == 1)
							ReplyToCommand(client, "[SM] Invalid entity!", action, value);
					}
					
				}
				else {
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Type not supported!");
				}
			}
		}
		else {
			char netname[256]; GetEntityNetClass(itarget, netname, sizeof(netname));
			info = FindSendPropInfo(netname, action, type);
			if (info != -1) {
				if (StrEqual(value, "")) {
					char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
					if (type == PropField_Integer) {
						int data = GetEntProp(itarget, Prop_Send, action);
						if (StrEqual(ename, "player")) {
							ReplyToCommand(client, "[%N] \x03%i", itarget, data);
						}
						else {
							ReplyToCommand(client, "[%i] \x03%i", itarget, data);
						}
					}
					else if (type == PropField_Float) {
						float data = GetEntPropFloat(itarget, Prop_Send, action);
						if (StrEqual(ename, "player")) {
							ReplyToCommand(client, "[%N] \x03%.2f", itarget, data);
						}
						else {
							ReplyToCommand(client, "[%i] \x03%.2f", itarget, data);
						}
					}
					else if (type == PropField_String || type == PropField_String_T) {
						char buffer[256];
						GetEntPropString(itarget, Prop_Send, action, buffer, sizeof(buffer));
						if (StrEqual(ename, "player")) {
							ReplyToCommand(client, "[%N] \x03%s", itarget, buffer);
						}
						else {
							ReplyToCommand(client, "[%i] \x03%s", itarget, buffer);
						}
					}
					else if (type == PropField_Vector) {
						float vector[3];
						GetEntPropVector(itarget, Prop_Send, action, vector);
						if (StrEqual(ename, "player")) {
							ReplyToCommand(client, "[%N] \x03%.0f %.0f %.0f", itarget, vector[0], vector[1], vector[2]);
						}
						else {
							ReplyToCommand(client, "[%i] \x03%.0f %.0f %.0f", itarget, vector[0], vector[1], vector[2]);
						}
					}
					else if (type == PropField_Entity) {
						int data = GetEntPropEnt(itarget, Prop_Send, action);
						if (StrEqual(ename, "player")) {
							ReplyToCommand(client, "[%N] \x03%i", itarget, data);
						}
						else {
							ReplyToCommand(client, "[%i] \x03%i", itarget, data);
						}
					}
					else {
						if (iCounter == 1)
							ReplyToCommand(client, "[SM] Type not supported!");
					}
				}
				else {
					if (type == PropField_Integer) {
						SetEntProp(itarget, Prop_Send, action, StringToInt(value));
						if (iCounter == 1)
							ReplyToCommand(client, "[SM] Set %s to %s", action, value);
					}
					else if (type == PropField_Float) {
						SetEntPropFloat(itarget, Prop_Send, action, StringToFloat(value));
						if (iCounter == 1)
							ReplyToCommand(client, "[SM] Set %s to %s", action, value);
					}
					else if (type == PropField_String || type == PropField_String_T) {
						SetEntPropString(itarget, Prop_Send, action, value);
						if (iCounter == 1)
							ReplyToCommand(client, "[SM] Set %s to %s", action, value);
					}
					else if (type == PropField_Vector) {
						float vector[3]; char num[64][6];
						ExplodeString(value, " ", num, 3, sizeof(num), false);
						vector[0] = StringToFloat(num[0]);
						vector[1] = StringToFloat(num[1]);
						vector[2] = StringToFloat(num[2]);
						SetEntPropVector(itarget, Prop_Send, action, vector);
						if (iCounter == 1)
							ReplyToCommand(client, "[SM] Set %s to %.0f %.0f %.0f", action, vector[0], vector[1], vector[2]);
					}
					else if (type == PropField_Entity) {
						if (IsValidEntity(StringToInt(value))) {
							SetEntPropEnt(itarget, Prop_Send, action, StringToInt(value));
							if (iCounter == 1)
								ReplyToCommand(client, "[SM] Set %s to %s", action, value);
						}
						else {
							if (iCounter == 1)
								ReplyToCommand(client, "[SM] Invalid entity!", action, value);
						}
						
					}
					else {
						if (iCounter == 1)
							ReplyToCommand(client, "[SM] Type not supported!");
					}
				}
			}
			else {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] %s not a datamap for target!", action);
			}
		}
	}
	else if (StrContains(action, "tf_weapon", false) == 0) {
		char ename[256]; GetEntityClassname(itarget, ename, sizeof(ename));
		if (StrEqual(ename, "player")) {
			if (StrEqual(value, "")) {
				if (iCounter == 1)
					ReplyToCommand(client, "[SM] tf_weapon_* <index>");
			}
			else {
				int ent = CreateEntityByName(action);
				if (ent != -1 && IsValidEntity(ent)) {
					if (iWeapon[itarget] != 0) {
						if (IsValidEdict(iWeapon[itarget])) {
							RemoveEdict(iWeapon[itarget]);
						}
						iWeapon[itarget] = 0;
					}
					SetEntProp(ent, Prop_Send, "m_bDisguiseWeapon", 1);
					SetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex", StringToInt(value));
					SetEntProp(ent, Prop_Send, "m_iEntityQuality", 6);
					SetEntProp(ent, Prop_Send, "m_iEntityLevel", 10);
					SetEntPropEnt(ent, Prop_Send, "m_hOwner", itarget);
					SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", itarget);
					SetEntPropEnt(ent, Prop_Send, "moveparent", itarget);
					SetEntProp(ent, Prop_Send, "m_bInitialized", 1);
					DispatchSpawn(ent);
					EquipPlayerWeapon(itarget, ent);
					SetEntPropEnt(itarget, Prop_Data, "m_hActiveWeapon", ent);
					iWeapon[itarget] = ent;
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Gave weapon %s with index %s", action, value);
				}
				else {
					if (iCounter == 1)
						ReplyToCommand(client, "[SM] Invalid weapon!");
				}
			}
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Target must be a player!");
		}
	}
	else {
		SetVariantString(value);
		bool success = AcceptEntityInput(itarget, action);
		if (StrEqual(action, "setcustommodel", false)) {
			SetEntProp(itarget, Prop_Send, "m_bCustomModelRotates", 1);
			SetEntProp(itarget, Prop_Send, "m_bUseClassAnimations", TF2_GetPlayerClass(itarget));
		}
		if (success == true) {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Triggered \"%s\" with value \"%s\"", action, value);
		}
		else {
			if (iCounter == 1)
				ReplyToCommand(client, "[SM] Invalid action!");
		}
	}
}

public void ent_trace(int client, float startpos[3], float startang[3], float endpos[3], int entity, char[] action, char[] value) {
	if (StrEqual(action, "data", false)) {
		ReplyToCommand(client, "StartPos: %.0f %.0f %.0f", startpos[0], startpos[1], startpos[2]);
		ReplyToCommand(client, "StartAng: %.0f %.0f %.0f", startang[0], startang[1], startang[2]);
		ReplyToCommand(client, "EndPos: %.0f %.0f %.0f", endpos[0], endpos[1], endpos[2]);
		ReplyToCommand(client, "Hit: %i", entity);
	}
	else if (StrEqual(action, "prop", false)) {
		if (StrEqual(value, "")) {
			ReplyToCommand(client, "[SM] prop <modelpath>");
		}
		else {
			char auth[256]; GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
			char targetname[256]; FormatEx(targetname, sizeof(targetname), "entprop_%s", auth);
			PrecacheModel(value);
			int prop = CreateEntityByName("prop_dynamic");
			DispatchKeyValue(prop, "physdamagescale", "0.0");
			DispatchKeyValue(prop, "Solid", "6");
			DispatchKeyValue(prop, "model", value);
			DispatchKeyValue(prop, "targetname", targetname);
			DispatchSpawn(prop);
			ActivateEntity(prop);
			float propang[3];
			propang[1] = 180 + startang[1];
			TeleportEntity(prop, endpos, propang, NULL_VECTOR);
			SetEntityRenderMode(prop, RENDER_TRANSALPHAADD);
			ReplyToCommand(client, "[SM] Spawned %i > %s", prop, value);
		}
	}
	else if (StrEqual(action, "create", false)) {
		if (StrEqual(value, "")) {
			ReplyToCommand(client, "[SM] create <entity>");
		}
		else {
			if (StrEqual(value, "0") || StrEqual(value, "-1")) {
				ReplyToCommand(client, "[SM] Cannot create that entity!");
			}
			else if (iEntity[client] == 0) {
				iEntity[client] = CreateEntityByName(value);
				if (IsValidEntity(iEntity[client])) {
					ReplyToCommand(client, "[SM] Entity %i > %s created.", iEntity[client], value);
				}
				else {
					ReplyToCommand(client, "[SM] Invalid entity!");
					iEntity[client] = 0;
				}
			}
			else {
				ReplyToCommand(client, "[SM] Please delete or spawn your previous entity first. (%i)", iEntity[client]);
			}
		}
	}
	else if (StrEqual(action, "delete", false)) {
		if (iEntity[client] != 0) {
			char ename[128]; GetEntityClassname(iEntity[client], ename, sizeof(ename));
			ReplyToCommand(client, "[SM] Entity %i > %s deleted", iEntity[client], ename);
			RemoveEdict(iEntity[client]);
			iEntity[client] = 0;
		}
		else {
			ReplyToCommand(client, "[SM] No entity created yet.", iEntity[client]);
		}
	}
	else if (StrEqual(action, "value", false)) {
		if (StrEqual(value, "")) {
			ReplyToCommand(client, "[SM] value <key> <value>");
		}
		else {
			if (iEntity[client] != 0) {
				char ename[128]; GetEntityClassname(iEntity[client], ename, sizeof(ename));
				char part[256][8]; ExplodeString(value, " ", part, 2, sizeof(part), true);
				if (StrEqual(part[0], "model", false) || StrEqual(part[0], "parent", false)) {
					PrecacheModel(part[1]);
				}
				DispatchKeyValue(iEntity[client], part[0], part[1]);
				ReplyToCommand(client, "[SM] Key:\"%s\" Value:\"%s\"", part[0], part[1]);
				ReplyToCommand(client, "added to entity %i > %s", iEntity[client], ename);
			}
			else {
				ReplyToCommand(client, "[SM] No entity created yet.", iEntity[client]);
			}
		}
	}
	else if (StrEqual(action, "spawn", false)) {
		if (StrEqual(value, "")) {
			if (iEntity[client] != 0) {
				char ename[128]; GetEntityClassname(iEntity[client], ename, sizeof(ename));
				ReplyToCommand(client, "[SM] Entity %i > %s spawned.", iEntity[client], ename);
				DispatchSpawn(iEntity[client]);
				ActivateEntity(iEntity[client]);
				float propang[3];
				propang[1] = 180 + startang[1];
				TeleportEntity(iEntity[client], endpos, propang, NULL_VECTOR);
				iEntity[client] = 0;
			}
			else {
				ReplyToCommand(client, "[SM] No entity created yet.", iEntity[client]);
			}
		} else {
			int ent = CreateEntityByName(value);
			if (ent != -1) {
				DispatchSpawn(ent);
				ActivateEntity(ent);
				float propang[3];
				propang[1] = 180 + startang[1];
				TeleportEntity(ent, endpos, propang, NULL_VECTOR);
				ReplyToCommand(client, "[SM] Entity %i > %s spawned.", ent, value);
			}
			else {
				ReplyToCommand(client, "[SM] Classname \"%s\" is invalid!", value);
			}
		}
	}
	else if (StrEqual(action, "copy", false)) {
		char ename[256]; GetEntityClassname(entity, ename, sizeof(ename));
		if (StrEqual(ename, "prop_dynamic")) {
			iCopy[client] = entity;
			ReplyToCommand(client, "[SM] %i > %s copied.", iCopy[client], ename);
		}
		else {
			ReplyToCommand(client, "[SM] Target must be a prop!");
		}
	}
	else if (StrEqual(action, "paste", false)) {
		if (iCopy[client] != 0 && IsValidEntity(iCopy[client])) {
			char model[512]; GetEntPropString(iCopy[client], Prop_Data, "m_ModelName", model, sizeof(model));
			char tname[128]; GetEntPropString(iCopy[client], Prop_Data, "m_iName", tname, sizeof(tname));
			float entang[3]; GetEntPropVector(iCopy[client], Prop_Data, "m_angRotation", entang);
			float entorg[3]; GetEntPropVector(iCopy[client], Prop_Data, "m_vecOrigin", entorg);
			PrecacheModel(model);
			int prop = CreateEntityByName("prop_dynamic");
			DispatchKeyValue(prop, "targetname", tname);
			DispatchKeyValue(prop, "physdamagescale", "0.0");
			DispatchKeyValue(prop, "solid", "6");
			DispatchKeyValue(prop, "model", model);
			DispatchSpawn(prop);
			ActivateEntity(prop);
			TeleportEntity(prop, endpos, entang, NULL_VECTOR);
			int red, green, blue, alpha;
			GetEntityRenderColor(iCopy[client], red, green, blue, alpha);
			SetEntityRenderColor(prop, red, green, blue, alpha);
			SetEntityRenderMode(prop, GetEntityRenderMode(iCopy[client]));
			SetEntityRenderFx(prop, GetEntityRenderFx(iCopy[client]));
			ReplyToCommand(client, "[SM] Pasted prop");
		}
		else {
			ReplyToCommand(client, "[SM] No entity copied yet!");
		}
	}
	else if (StrEqual(action, "shift", false)) {
		if (bShift[client] == false) {
			if (IsValidEntity(entity) && entity > 0) {
				StopActiveActions(client);
				bShift[client] = true;
				iShift[client] = entity;
				iShiftMode[client] = StringToInt(value);
				ReplyToCommand(client, "[SM] Started shifting %i", iShift[client]);
				ReplyToCommand(client, "[SM] Copy: +speed");
			}
			else {
				ReplyToCommand(client, "[SM] Invalid entity!");
			}
		}
		else {
			bShift[client] = false;
			iShift[client] = 0;
			iShiftMode[client] = 0;
			ReplyToCommand(client, "[SM] Stopped shifting.");
		}
	}
	else if (StrEqual(action, "warp", false)) {
		if (bWarp[client] == false) {
			if (IsValidEntity(entity) && entity > 0) {
				StopActiveActions(client);
				bWarp[client] = true;
				iWarp[client] = entity;
				SetEntityMoveType(client, MOVETYPE_NONE);
				fWarpAmount[client] = StringToFloat(value);
				ReplyToCommand(client, "[SM] Started warping %i with %.2f", iWarp[client], fWarpAmount[client]);
				ReplyToCommand(client, "[SM] Warp: W/A/S/D/JUMP/DUCK | Swap Mode: +speed");
			}
			else {
				ReplyToCommand(client, "[SM] Invalid entity!");
			}
		}
		else {
			SetEntityMoveType(client, MOVETYPE_WALK);
			bWarp[client] = false;
			iWarp[client] = 0;
			fWarpAmount[client] = 0.0;
			ReplyToCommand(client, "[SM] Stopped warping.");
		}
	}
	else if (StrEqual(action, "move", false)) {
		if (bMove[client] == false) {
			StopActiveActions(client);
			iMove[client] = GetAimEntity(client);
			char ename[256]; GetEntityClassname(entity, ename, sizeof(ename));
			if (iMove[client] > 0) {
				if (StrEqual(ename, "prop_dynamic")) {
					CreateTempEnts(client, iMove[client]);
					bMove[client] = true;
					ReplyToCommand(client, "[SM] Started moving %i", iMove[client]);
					ReplyToCommand(client, "[SM] Move: +walk | Copy: +speed");
				}
				else {
					ReplyToCommand(client, "[SM] Target must be a prop!");
				}
			}
			else {
				ReplyToCommand(client, "[SM] Invalid entity!");
			}
		}
		else {
			DeleteTempEnts(client);
			bMove[client] = false;
			ReplyToCommand(client, "[SM] Stopped moving!");
		}
	}
	else if (StrEqual(action, "choose", false)) {
		if (bChoose[client] == false) {
			if (!StrEqual(value, "")) {
				StopActiveActions(client);
				char dir[256]; BuildPath(Path_SM, dir, sizeof(dir), DATA_DIR);
				if (!DirExists(dir)) {
					CreateDirectory(dir, 0);
				}
				BuildPath(Path_SM, dir, sizeof(dir), PROPS_DIR);
				if (!DirExists(dir)) {
					CreateDirectory(dir, 0);
				}
				char filename[256]; FormatEx(filename, sizeof(filename), "%s/%s.cfg", PROPS_DIR, value);
				char filepath[256]; BuildPath(Path_SM, filepath, sizeof(filepath), filename);
				if (FileExists(filepath)) {
					hChoose[client] = OpenFile(filepath, "r");
					bChoose[client] = true;
					ReplyToCommand(client, "[SM] Choosing props from %s", filename);
					ReplyToCommand(client, "[SM] Cyle: +walk | Place: +speed");
				}
				else {
					ReplyToCommand(client, "[SM] %s doesn't exist!", filename);
				}
			}
			else {
				ReplyToCommand(client, "[SM] choose <filename>");
			}
		}
		else {
			bChoose[client] = false;
			if (IsValidEntity(iChoose[client]) && iChoose[client] != 0) {
				RemoveEdict(iChoose[client]);
			}
			iChoose[client] = 0;
			iChooseTarget[client] = 0;
			CloseHandle(hChoose[client]);
			ReplyToCommand(client, "[SM] Stopped choosing!");
		}
	}
	else if (StrEqual(action, "decal", false)) {
		if (!StrEqual(value, "")) {
			int index = PrecacheDecal(value, true);
			TE_Start("World Decal");
			TE_WriteVector("m_vecOrigin", endpos);
			TE_WriteNum("m_nIndex", index);
			TE_SendToAll();
			ReplyToCommand(client, "[SM] Placed decal '%s' at crosshair", value);
		}
		else {
			ReplyToCommand(client, "[SM] decal <material path>");
		}
	}
	else if (StrEqual(action, "drop", false)) {
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		char model[256]; ReadStringTable(FindStringTable("modelprecache"), GetEntProp(weapon, Prop_Send, "m_iWorldModelIndex"), model, sizeof(model));
		if (!IsModelPrecached(model))PrecacheModel(model);
		int ent = CreateEntityByName("tf_dropped_weapon");
		if (ent != -1) {
			SetEntityModel(ent, model);
			SetEntProp(ent, Prop_Send, "m_bInitialized", 1);
			SetEntProp(ent, Prop_Send, "m_bOnlyIterateItemViewAttributes", GetEntProp(weapon, Prop_Send, "m_bOnlyIterateItemViewAttributes"));
			SetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
			SetEntProp(ent, Prop_Send, "m_iEntityLevel", GetEntProp(weapon, Prop_Send, "m_iEntityLevel"));
			SetEntProp(ent, Prop_Send, "m_iItemIDHigh", GetEntProp(weapon, Prop_Send, "m_iItemIDHigh"));
			SetEntProp(ent, Prop_Send, "m_iItemIDLow", GetEntProp(weapon, Prop_Send, "m_iItemIDLow"));
			SetEntProp(ent, Prop_Send, "m_iAccountID", GetEntProp(weapon, Prop_Send, "m_iAccountID"));
			SetEntProp(ent, Prop_Send, "m_iEntityQuality", GetEntProp(weapon, Prop_Send, "m_iEntityQuality"));
			SetEntProp(ent, Prop_Send, "m_iTeamNumber", GetEntProp(weapon, Prop_Send, "m_iTeamNumber"));
			if (HasEntProp(weapon, Prop_Send, "m_flChargeLevel")) {
				SetEntPropFloat(ent, Prop_Send, "m_flChargeLevel", GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel"));
			}
			ActivateEntity(ent);
			DispatchSpawn(ent);
			TeleportEntity(ent, endpos, NULL_VECTOR, NULL_VECTOR);
			ReplyToCommand(client, "Dropped weapon at crosshair.");
		}
	}
	else if (StrEqual(action, "select", false) || StrEqual(action, "deselect", false)) {
		if (!StrEqual(value, "")) {
			if (aSelect[client] == INVALID_HANDLE) {
				aSelect[client] = CreateArray();
			}
			if (StrEqual(value, "0")) {
				if (IsValidEntity(entity) && entity > 0) {
					char ename[256]; GetEntityClassname(entity, ename, sizeof(ename));
					if (StrEqual(ename, "prop_dynamic")) {
						int index = -1;
						for (int a; a < GetArraySize(aSelect[client]); a++) {
							if (entity == GetArrayCell(aSelect[client], a)) {
								index = a;
							}
						}
						if (index != -1) {
							ReplyToCommand(client, "[SM] Deselected %i", GetArrayCell(aSelect[client], index));
							RemoveFromArray(aSelect[client], index);
						}
						else {
							ReplyToCommand(client, "[SM] Selected %i", entity);
							PushArrayCell(aSelect[client], entity);
						}
					}
					else {
						ReplyToCommand(client, "[SM] Target must be a prop!");
					}
				}
				else {
					ReplyToCommand(client, "[SM] Invalid entity!");
				}
			}
			else {
				float range = StringToFloat(value);
				if (range > 0) {
					float clientorg[3]; GetClientAbsOrigin(client, clientorg);
					int num;
					for (int e = 1; e <= GetMaxEntities(); e++) {
						if (IsValidEntity(e) && e != client) {
							char ename[128]; GetEntityClassname(e, ename, sizeof(ename));
							if (StrEqual(ename, "prop_dynamic", false)) {
								float entorg[3]; GetEntPropVector(e, Prop_Data, "m_vecOrigin", entorg);
								float distance = GetVectorDistance(clientorg, entorg);
								if (distance < range) {
									int index = -1;
									for (int a; a < GetArraySize(aSelect[client]); a++) {
										if (e == GetArrayCell(aSelect[client], a)) {
											index = a;
										}
									}
									if (index != -1) {
										if (StrEqual(action, "deselect", false)) {
											PrintToConsole(client, "[SM] Deselected %i", GetArrayCell(aSelect[client], index));
											RemoveFromArray(aSelect[client], index);
										}
									}
									else {
										if (StrEqual(action, "select", false)) {
											PrintToConsole(client, "[SM] Selected %i", e);
											PushArrayCell(aSelect[client], e);
										}
									}
									num++;
								}
							}
						}
					}
					if (num > 0) {
						if (StrEqual(action, "select", false)) {
							ReplyToCommand(client, "%i props selected.", num);
						}
						else {
							ReplyToCommand(client, "%i props deselected.", num);
						}
					}
					else {
						ReplyToCommand(client, "No props in range!");
					}
				}
				else {
					ReplyToCommand(client, "[SM] Invalid range!");
				}
			}
		}
		else if (bSelect[client] == false) {
			if (aSelect[client] == INVALID_HANDLE) {
				aSelect[client] = CreateArray();
			}
			StopActiveActions(client);
			bSelect[client] = true;
			ReplyToCommand(client, "[SM] Started selecting.");
			ReplyToCommand(client, "[SM] Select/Deselect: +speed");
		}
		else {
			bSelect[client] = false;
			ReplyToCommand(client, "[SM] Stopped selecting!");
		}
	}
}

public void ent_file(int client, char[] action, char[] value) {
	if (StrEqual(action, "create", false)) {
		if (StrEqual(value, "")) {
			ReplyToCommand(client, "[SM] create <filename>");
		}
		else {
			char dir[256]; BuildPath(Path_SM, dir, sizeof(dir), DATA_DIR);
			if (!DirExists(dir)) {
				CreateDirectory(dir, 0);
			}
			char buffer[256]; FormatEx(buffer, sizeof(buffer), "%s/%s.cfg", DATA_DIR, value);
			char filepath[256]; BuildPath(Path_SM, filepath, sizeof(filepath), buffer);
			if (!FileExists(filepath)) {
				Handle filehandle = OpenFile(filepath, "w");
				if (filehandle == null) {
					ReplyToCommand(client, "[SM] Error creating file!");
				}
				else {
					ReplyToCommand(client, "[SM] Created %s!", buffer);
				}
				CloseHandle(filehandle);
			}
			else {
				ReplyToCommand(client, "[SM] File %s already exists!", buffer);
			}
		}
	}
	else if (StrEqual(action, "delete", false)) {
		if (StrEqual(value, "")) {
			ReplyToCommand(client, "[SM] delete <filename>");
		}
		else {
			char buffer[256]; FormatEx(buffer, sizeof(buffer), "%s/%s.cfg", DATA_DIR, value);
			char filepath[256]; BuildPath(Path_SM, filepath, sizeof(filepath), buffer);
			if (FileExists(filepath)) {
				bool deleted = DeleteFile(filepath);
				if (deleted == true) {
					ReplyToCommand(client, "[SM] Deleted %s!", buffer);
				}
				else {
					ReplyToCommand(client, "[SM] Error deleting file!");
				}
			}
			else {
				ReplyToCommand(client, "[SM] File %s doesn't exist!", buffer);
			}
		}
	}
	else if (StrEqual(action, "print", false)) {
		if (StrEqual(value, "")) {
			ReplyToCommand(client, "[SM] print <filename>");
		}
		else {
			char buffer[256]; FormatEx(buffer, sizeof(buffer), "%s/%s.cfg", DATA_DIR, value);
			char filepath[256]; BuildPath(Path_SM, filepath, sizeof(filepath), buffer);
			if (FileExists(filepath)) {
				int num;
				char line[512];
				Handle filehandle = OpenFile(filepath, "r");
				while (!IsEndOfFile(filehandle) && ReadFileLine(filehandle, line, sizeof(line))) {
					num++;
					TrimString(line);
					PrintToConsole(client, "|%i| %s", num, line);
				}
				if (num == 0) {
					ReplyToCommand(client, "[SM] File %s is empty", buffer);
				}
				else {
					ReplyToCommand(client, "[SM] Printed %i lines from %s", num, buffer);
				}
			}
			else {
				ReplyToCommand(client, "[SM] File %s doesn't exist!", buffer);
			}
		}
	}
	else if (StrEqual(action, "write", false)) {
		char part[1024][6]; ExplodeString(value, " ", part, 2, sizeof(part), true);
		if (StrEqual(part[1], "")) {
			ReplyToCommand(client, "[SM] write <filename> <value>");
		}
		else {
			char buffer[256]; FormatEx(buffer, sizeof(buffer), "%s/%s.cfg", DATA_DIR, part[0]);
			char filepath[256]; BuildPath(Path_SM, filepath, sizeof(filepath), buffer);
			if (FileExists(filepath)) {
				Handle filehandle = OpenFile(filepath, "a");
				bool written = WriteFileLine(filehandle, part[1]);
				if (written == false) {
					ReplyToCommand(client, "[SM] Error writing to file!");
				}
				else {
					ReplyToCommand(client, "[SM] Line written.");
				}
				CloseHandle(filehandle);
			}
			else {
				ReplyToCommand(client, "[SM] File %s doesn't exist!", buffer);
			}
		}
	}
	else if (StrEqual(action, "saveprops", false)) {
		if (StrEqual(value, "")) {
			ReplyToCommand(client, "[SM] saveprops <filename>");
		}
		else {
			char dir[256]; BuildPath(Path_SM, dir, sizeof(dir), DATA_DIR);
			if (!DirExists(dir)) {
				CreateDirectory(dir, 0);
			}
			BuildPath(Path_SM, dir, sizeof(dir), SAVES_DIR);
			if (!DirExists(dir)) {
				CreateDirectory(dir, 0);
			}
			char filename[256]; FormatEx(filename, sizeof(filename), "%s/%s.cfg", SAVES_DIR, value);
			char filepath[256]; BuildPath(Path_SM, filepath, sizeof(filepath), filename);
			int check;
			if (aSelect[client] != INVALID_HANDLE) {
				if (GetArraySize(aSelect[client]) == 0) {
					ReplyToCommand(client, "[SM] No props selected!");
				}
				else {
					for (int i; i < GetArraySize(aSelect[client]); i++) {
						if (IsValidEntity(GetArrayCell(aSelect[client], i)) && GetArrayCell(aSelect[client], i) > 0) {
							check++;
						}
					}
				}
			}
			int num;
			if (check > 0) {
				Handle filehandle = OpenFile(filepath, "w");
				for (int i; i < GetArraySize(aSelect[client]); i++) {
					if (IsValidEntity(GetArrayCell(aSelect[client], i)) && GetArrayCell(aSelect[client], i) > 0) {
						int e = GetArrayCell(aSelect[client], i);
						char ename[128]; GetEntityClassname(e, ename, sizeof(ename));
						if (e != -1 && StrEqual(ename, "prop_dynamic")) {
							char tname[128]; GetEntPropString(e, Prop_Data, "m_iName", tname, sizeof(tname));
							char model[512]; GetEntPropString(e, Prop_Data, "m_ModelName", model, sizeof(model));
							int parent = GetEntPropEnt(e, Prop_Data, "m_hParent");
							int solid = GetEntProp(e, Prop_Data, "m_nSolidType");
							float scale = GetEntPropFloat(e, Prop_Data, "m_flModelScale");
							float entorg[3]; GetEntPropVector(e, Prop_Data, "m_vecOrigin", entorg);
							float entang[3]; GetEntPropVector(e, Prop_Data, "m_angRotation", entang);
							int red, green, blue, alpha;
							GetEntityRenderColor(e, red, green, blue, alpha);
							char mapname[256]; GetCurrentMap(mapname, sizeof(mapname));
							char string[512];
							Format(string, sizeof(string), "%s|%s|%i|%i|%f|%f|%f|%f|%f|%f|%f|%i|%i|%i|%i|%s", 
								mapname, model, parent, solid, scale, entorg[0], entorg[1], entorg[2], entang[0], entang[1], entang[2], red, green, blue, alpha, tname);
							WriteFileLine(filehandle, "%s", string);
							num++;
						}
					}
				}
				ReplyToCommand(client, "[SM] %i props saved into %s", num, filename);
				CloseHandle(filehandle);
			}
			else {
				ReplyToCommand(client, "[SM] No props selected for saving.");
			}
		}
	}
	else if (StrEqual(action, "loadprops", false)) {
		if (StrEqual(value, "")) {
			ReplyToCommand(client, "[SM] loadprops <filename>");
		}
		else {
			char dir[256]; BuildPath(Path_SM, dir, sizeof(dir), DATA_DIR);
			if (!DirExists(dir)) {
				CreateDirectory(dir, 0);
			}
			BuildPath(Path_SM, dir, sizeof(dir), SAVES_DIR);
			if (!DirExists(dir)) {
				CreateDirectory(dir, 0);
			}
			char buffer[256]; FormatEx(buffer, sizeof(buffer), "%s/%s.cfg", SAVES_DIR, value);
			char filepath[256]; BuildPath(Path_SM, filepath, sizeof(filepath), buffer);
			if (!FileExists(filepath)) {
				ReplyToCommand(client, "[SM] File %s doesn't exist!", buffer);
			}
			else {
				int num;
				char line[512], realmap[256];
				Handle filehandle = OpenFile(filepath, "r");
				while (!IsEndOfFile(filehandle) && ReadFileLine(filehandle, line, sizeof(line))) {
					char part[512][128];
					ExplodeString(line, "|", part, 16, sizeof(part));
					char mapname[256]; GetCurrentMap(mapname, sizeof(mapname));
					if (StrEqual(part[0], mapname)) {
						char auth[256]; GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
						char tname[128]; FormatEx(tname, sizeof(tname), "entprop_%s", auth);
						PrecacheModel(part[1]);
						int prop = CreateEntityByName("prop_dynamic");
						DispatchKeyValue(prop, "model", part[1]);
						DispatchKeyValue(prop, "targetname", tname);
						DispatchKeyValue(prop, "solid", part[3]);
						DispatchKeyValue(prop, "modelscale", part[4]);
						DispatchSpawn(prop);
						SetEntPropEnt(prop, Prop_Data, "m_hParent", StringToInt(part[2]));
						float entorg[3]; entorg[0] = StringToFloat(part[5]); entorg[1] = StringToFloat(part[6]); entorg[2] = StringToFloat(part[7]);
						float entang[3]; entang[0] = StringToFloat(part[8]); entang[1] = StringToFloat(part[9]); entang[2] = StringToFloat(part[10]);
						TeleportEntity(prop, entorg, entang, NULL_VECTOR);
						SetEntityRenderColor(prop, StringToInt(part[11]), StringToInt(part[12]), StringToInt(part[13]), StringToInt(part[14]));
						SetEntityRenderMode(prop, RENDER_TRANSALPHAADD);
					}
					else {
						strcopy(realmap, sizeof(realmap), part[0]);
					}
					num++;
				}
				if (num == 0) {
					ReplyToCommand(client, "[SM] File %s is empty", buffer);
				}
				else if (!StrEqual(realmap, "")) {
					ReplyToCommand(client, "[SM] Wrong map! These were saved on %s.", realmap);
				}
				else {
					ReplyToCommand(client, "[SM] Spawned %i saved props from %s", num, buffer);
				}
				CloseHandle(filehandle);
			}
		}
	}
}

stock void LoadSDKHandles(char[] config) {
	Handle cfg = LoadGameConfigFile(config);
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(cfg, SDKConf_Virtual, "CTFPlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	hEquipWearableSDK = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(cfg, SDKConf_Signature, "GEconItemSchema");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	hItemSchemaSDK = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(cfg, SDKConf_Signature, "CEconItemSchema::GetAttributeDefinition");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	hGetAttribSDK = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(cfg, SDKConf_Signature, "CAttributeList::SetRuntimeAttributeValue");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	hRuntimeAttribSDK = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(cfg, SDKConf_Signature, "CAttributeList::RemoveAttribute");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	hRemoveAttribSDK = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(cfg, SDKConf_Signature, "CAttributeList::DestroyAllAttributes");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	hDestroyAttribSDK = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(cfg, SDKConf_Signature, "CAttributeList::GetAttributeByID");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	hGetAttribIdSDK = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(cfg, SDKConf_Signature, "CEconItemSchema::GetItemDefinition");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	hItemDefSDK = EndPrepSDKCall();
}

stock bool SetAttrib(int entity, int index, float value) {
	if (!IsValidEntity(entity))return false;
	int offs = GetEntSendPropOffs(entity, "m_AttributeList", true);
	if (offs <= 0)return false;
	Address pEntity = GetEntityAddress(entity);
	if (pEntity == Address_Null)return false;
	Address pSchema = SDKCall(hItemSchemaSDK);
	if (pSchema == Address_Null)return false;
	Address pAttribDef = SDKCall(hGetAttribSDK, pSchema, index);
	static Address Address_MinimumValid = view_as<Address>(0x10000);
	if (pAttribDef == Address_Null)return false;
	int res;
	if (view_as<int>(pAttribDef) == view_as<int>(Address_MinimumValid))res = 0;
	if ((view_as<int>(pAttribDef) >>> 31) == (view_as<int>(Address_MinimumValid) >>> 31)) {
		res = ((view_as<int>(pAttribDef) & 0x7FFFFFFF) > (view_as<int>(Address_MinimumValid) & 0x7FFFFFFF)) ? 1 : -1;
	}
	res = ((view_as<int>(pAttribDef) >>> 31) > (view_as<int>(Address_MinimumValid) >>> 31)) ? 1 : -1;
	if (res >= 0)return false;
	SDKCall(hRuntimeAttribSDK, pEntity + view_as<Address>(offs), pAttribDef, value);
	return true;
}

stock bool RemoveAttrib(int entity, int index) {
	if (!IsValidEntity(entity))return false;
	int offs = GetEntSendPropOffs(entity, "m_AttributeList", true);
	if (offs <= 0)return false;
	Address pEntity = GetEntityAddress(entity);
	if (pEntity == Address_Null)return false;
	Address pSchema = SDKCall(hItemSchemaSDK);
	if (pSchema == Address_Null)return false;
	Address pAttribDef = SDKCall(hGetAttribSDK, pSchema, index);
	static Address Address_MinimumValid = view_as<Address>(0x10000);
	if (pAttribDef == Address_Null)return false;
	int res;
	if (view_as<int>(pAttribDef) == view_as<int>(Address_MinimumValid))res = 0;
	if ((view_as<int>(pAttribDef) >>> 31) == (view_as<int>(Address_MinimumValid) >>> 31)) {
		res = ((view_as<int>(pAttribDef) & 0x7FFFFFFF) > (view_as<int>(Address_MinimumValid) & 0x7FFFFFFF)) ? 1 : -1;
	}
	res = ((view_as<int>(pAttribDef) >>> 31) > (view_as<int>(Address_MinimumValid) >>> 31)) ? 1 : -1;
	if (res >= 0)return false;
	SDKCall(hRemoveAttribSDK, pEntity + view_as<Address>(offs), pAttribDef);
	return true;
}

stock bool ResetAttribs(int entity) {
	if (!IsValidEntity(entity))return false;
	int offs = GetEntSendPropOffs(entity, "m_AttributeList", true);
	if (offs <= 0)return false;
	Address pEntity = GetEntityAddress(entity);
	if (pEntity == Address_Null)return false;
	SDKCall(hDestroyAttribSDK, pEntity + view_as<Address>(offs)); //disregard the return (Valve does!)
	return true;
}

stock float GetAttrib(int entity, int index) {
	if (!IsValidEntity(entity))return 0.0;
	int offs = GetEntSendPropOffs(entity, "m_AttributeList", true);
	if (offs <= 0)return 0.0;
	Address pEntity = GetEntityAddress(entity);
	if (pEntity == Address_Null)return 0.0;
	Address pAttribDef = view_as<Address>(SDKCall(hGetAttribIdSDK, pEntity + view_as<Address>(offs), index));
	static Address Address_MinimumValid = view_as<Address>(0x10000);
	if (pAttribDef == Address_Null)return 0.0;
	int res;
	if (view_as<int>(pAttribDef) == view_as<int>(Address_MinimumValid))res = 0;
	if ((view_as<int>(pAttribDef) >>> 31) == (view_as<int>(Address_MinimumValid) >>> 31)) {
		res = ((view_as<int>(pAttribDef) & 0x7FFFFFFF) > (view_as<int>(Address_MinimumValid) & 0x7FFFFFFF)) ? 1 : -1;
	}
	res = ((view_as<int>(pAttribDef) >>> 31) > (view_as<int>(Address_MinimumValid) >>> 31)) ? 1 : -1;
	if (res >= 0)return 0.0;
	return view_as<float>(LoadFromAddress(pAttribDef + view_as<Address>(8), NumberType_Int32));
}

stock int ListAttribs(int iItemDefIndex, int iAttribIndices[16], int iAttribValues[16]) {
	Address pSchema = SDKCall(hItemSchemaSDK);
	if (pSchema == Address_Null)return -1;
	Address pItemDef = SDKCall(hItemDefSDK, pSchema, iItemDefIndex);
	static Address Address_MinimumValid = view_as<Address>(0x10000);
	if (pItemDef == Address_Null)return -1;
	int res;
	if (view_as<int>(pItemDef) == view_as<int>(Address_MinimumValid))res = 0;
	if ((view_as<int>(pItemDef) >>> 31) == (view_as<int>(Address_MinimumValid) >>> 31)) {
		res = ((view_as<int>(pItemDef) & 0x7FFFFFFF) > (view_as<int>(Address_MinimumValid) & 0x7FFFFFFF)) ? 1 : -1;
	}
	res = ((view_as<int>(pItemDef) >>> 31) > (view_as<int>(Address_MinimumValid) >>> 31)) ? 1 : -1;
	if (res >= 0)return -1;
	int iCount = GetStaticAttribs(pItemDef, iAttribIndices, iAttribValues);
	return iCount;
}

stock int GetStaticAttribs(Address pItemDef, int iAttribIndices[16], int iAttribValues[16]) {
	static Address Address_MinimumValid = view_as<Address>(0x10000);
	if (pItemDef == Address_Null)return 0;
	int res;
	if (view_as<int>(pItemDef) == view_as<int>(Address_MinimumValid))res = 0;
	if ((view_as<int>(pItemDef) >>> 31) == (view_as<int>(Address_MinimumValid) >>> 31)) {
		res = ((view_as<int>(pItemDef) & 0x7FFFFFFF) > (view_as<int>(Address_MinimumValid) & 0x7FFFFFFF)) ? 1 : -1;
	}
	res = ((view_as<int>(pItemDef) >>> 31) > (view_as<int>(Address_MinimumValid) >>> 31)) ? 1 : -1;
	if (res >= 0)return 0;
	int iNumAttribs = LoadFromAddress(pItemDef + view_as<Address>(0x28), NumberType_Int32);
	Address pAttribList = view_as<Address>(LoadFromAddress(pItemDef + view_as<Address>(0x1C), NumberType_Int32));
	for (int i = 0; i < iNumAttribs && i < 16; i++) {
		iAttribIndices[i] = LoadFromAddress(pAttribList + view_as<Address>(i * 8), NumberType_Int16);
		iAttribValues[i] = LoadFromAddress(pAttribList + view_as<Address>(i * 8 + 4), NumberType_Int32);
	}
	return iNumAttribs;
}

stock void RotateVectorAroundPoint(float vector[3], float origin[3], float angles[3]) {
	SubtractVectors(vector, origin, vector);
	float pitch = DegToRad(angles[0]);
	float yaw = DegToRad(angles[1]);
	float roll = DegToRad(angles[2]);
	float cosa = Cosine(yaw);
	float sina = Sine(yaw);
	float cosb = Cosine(pitch);
	float sinb = Sine(pitch);
	float cosc = Cosine(roll);
	float sinc = Sine(roll);
	float Axx = cosa * cosb;
	float Axy = cosa * sinb * sinc - sina * cosc;
	float Axz = cosa * sinb * cosc + sina * sinc;
	float Ayx = sina * cosb;
	float Ayy = sina * sinb * sinc + cosa * cosc;
	float Ayz = sina * sinb * cosc - cosa * sinc;
	float Azx = -sinb;
	float Azy = cosb * sinc;
	float Azz = cosb * cosc;
	float px = vector[0];
	float py = vector[1];
	float pz = vector[2];
	vector[0] = Axx * px + Axy * py + Axz * pz;
	vector[1] = Ayx * px + Ayy * py + Ayz * pz;
	vector[2] = Azx * px + Azy * py + Azz * pz;
	AddVectors(vector, origin, vector);
}

public void DrawBoundingBox(int client, int target, float size, int color[4]) {
	if (target < 1 || !IsValidEntity(target))return;
	float mins[3]; GetEntPropVector(target, Prop_Data, "m_vecMins", mins);
	float maxs[3]; GetEntPropVector(target, Prop_Data, "m_vecMaxs", maxs);
	float org[3]; GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", org);
	float ang[3]; GetEntPropVector(target, Prop_Data, "m_angAbsRotation", ang);
	
	//TLB = Top Left Back
	//BRF = Bottom Right Front
	float TLB[3]; TLB[0] = org[0] + maxs[0]; TLB[1] = org[1] + maxs[1]; TLB[2] = org[2] + maxs[2]; RotateVectorAroundPoint(TLB, org, ang);
	float TLF[3]; TLF[0] = org[0] + mins[0]; TLF[1] = org[1] + maxs[1]; TLF[2] = org[2] + maxs[2]; RotateVectorAroundPoint(TLF, org, ang);
	float TRB[3]; TRB[0] = org[0] + maxs[0]; TRB[1] = org[1] + mins[1]; TRB[2] = org[2] + maxs[2]; RotateVectorAroundPoint(TRB, org, ang);
	float BLB[3]; BLB[0] = org[0] + maxs[0]; BLB[1] = org[1] + maxs[1]; BLB[2] = org[2] + mins[2]; RotateVectorAroundPoint(BLB, org, ang);
	float BRF[3]; BRF[0] = org[0] + mins[0]; BRF[1] = org[1] + mins[1]; BRF[2] = org[2] + mins[2]; RotateVectorAroundPoint(BRF, org, ang);
	float BRB[3]; BRB[0] = org[0] + maxs[0]; BRB[1] = org[1] + mins[1]; BRB[2] = org[2] + mins[2]; RotateVectorAroundPoint(BRB, org, ang);
	float BLF[3]; BLF[0] = org[0] + mins[0]; BLF[1] = org[1] + maxs[1]; BLF[2] = org[2] + mins[2]; RotateVectorAroundPoint(BLF, org, ang);
	float TRF[3]; TRF[0] = org[0] + mins[0]; TRF[1] = org[1] + mins[1]; TRF[2] = org[2] + maxs[2]; RotateVectorAroundPoint(TRF, org, ang);
	
	TE_SetupBeamPoints(TLB, TRB, iBeam, 0, 0, 0, 0.1, size, size, 10, 0.0, color, 0); TE_SendToClient(client);
	TE_SetupBeamPoints(TRB, TRF, iBeam, 0, 0, 0, 0.1, size, size, 10, 0.0, color, 0); TE_SendToClient(client);
	TE_SetupBeamPoints(TRF, TLF, iBeam, 0, 0, 0, 0.1, size, size, 10, 0.0, color, 0); TE_SendToClient(client);
	TE_SetupBeamPoints(TLF, TLB, iBeam, 0, 0, 0, 0.1, size, size, 10, 0.0, color, 0); TE_SendToClient(client);
	
	TE_SetupBeamPoints(BLB, BRB, iBeam, 0, 0, 0, 0.1, size, size, 10, 0.0, color, 0); TE_SendToClient(client);
	TE_SetupBeamPoints(BRB, BRF, iBeam, 0, 0, 0, 0.1, size, size, 10, 0.0, color, 0); TE_SendToClient(client);
	TE_SetupBeamPoints(BRF, BLF, iBeam, 0, 0, 0, 0.1, size, size, 10, 0.0, color, 0); TE_SendToClient(client);
	TE_SetupBeamPoints(BLF, BLB, iBeam, 0, 0, 0, 0.1, size, size, 10, 0.0, color, 0); TE_SendToClient(client);
	
	TE_SetupBeamPoints(TLB, BLB, iBeam, 0, 0, 0, 0.1, size, size, 10, 0.0, color, 0); TE_SendToClient(client);
	TE_SetupBeamPoints(TRB, BRB, iBeam, 0, 0, 0, 0.1, size, size, 10, 0.0, color, 0); TE_SendToClient(client);
	TE_SetupBeamPoints(TRF, BRF, iBeam, 0, 0, 0, 0.1, size, size, 10, 0.0, color, 0); TE_SendToClient(client);
	TE_SetupBeamPoints(TLF, BLF, iBeam, 0, 0, 0, 0.1, size, size, 10, 0.0, color, 0); TE_SendToClient(client);
} 