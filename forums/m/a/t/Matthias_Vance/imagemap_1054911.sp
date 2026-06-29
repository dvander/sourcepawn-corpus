#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

#define MAXCLIENTS (MAXPLAYERS + 1)

#define SPRAY_ACTION_TYPE_NONE -1
#define SPRAY_ACTION_TYPE_URL 0
#define SPRAY_ACTION_TYPE_CMD 1

public Plugin:myinfo = {
	name = "ImageMap",
	author = "Matthias Vance",
	description = "Interactive player/map decals!",
	version = PLUGIN_VERSION,
	url = "http://www.matthiasvance.com/"
};

new Float:lastHintMessage[MAXCLIENTS];
new Float:sprayOrigin[MAXCLIENTS][3];
new Handle:kv;

public OnPluginStart() {

	CreateConVar("imagemap_version", PLUGIN_VERSION, "Interactive player/map decals!", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	SetConVarString(FindConVar("imagemap_version"), PLUGIN_VERSION);

	new String:kvPath[] = "cfg/sourcemod/imagemap.cfg";
	if(!FileExists(kvPath)) SetFailState("Could not find KV file. (%s)", kvPath);
	kv = CreateKeyValues("ImageMap");
	if(!FileToKeyValues(kv, kvPath)) SetFailState("Could not read KV file.");

	AddTempEntHook("Player Decal", te_Spray);
	RegConsoleCmd("voicemenu", cmd_VoiceMenu);

	CreateTimer(1.0, timer_CheckClientSprayTargets, _, TIMER_REPEAT);

	RegConsoleCmd("spray_check", cmd_SprayCheck);
}

public OnPluginEnd() {
	if(kv != INVALID_HANDLE) CloseHandle(kv);
}

public Action:timer_CheckClientSprayTargets(Handle:timer) {
	new Float:clientTime;
	for(new client = 1; client <= MaxClients; client++) {
		if(!IsClientInGame(client)) continue;
		clientTime = GetClientTime(client);
		if((clientTime - lastHintMessage[client] > 12.0) && checkClientSprayHover(client)) {
			lastHintMessage[client] = GetClientTime(client);
			PrintHintText(client, "This is an interactive spray!\nPress E (call medic) or T (spray) on the interactive part.");
		}
	}
	return Plugin_Continue;
}

stock bool:checkClientSprayHover(client) {
	new Float:clientAim[3];
	if(!GetClientAim(client, clientAim)) return false;
	new Float:clientOrigin[3];
	GetClientAbsOrigin(client, clientOrigin);

	new Float:clientDistance;
	new Float:aimDistance;
	new bool:isAimClientSpray = false;
	new sprayClient;
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i)) continue;
		clientDistance = GetVectorDistance(clientOrigin, sprayOrigin[i]);
		if(clientDistance >= 200.0) continue;
		aimDistance = GetVectorDistance(clientAim, sprayOrigin[i]);
		if(aimDistance >= 100.0) continue;
		isAimClientSpray = true;
		sprayClient = i;
		break;
	}
	if(!isAimClientSpray) return false;

	decl String:sprayFile[16];
	if(!GetPlayerDecalFile(sprayClient, sprayFile, sizeof(sprayFile))) return false;

	decl String:temp[64];
	KvRewind(kv);
	do {
		KvGetString(kv, "Type", temp, sizeof(temp));
		if(!StrEqual(temp, "player")) continue;

		KvGetString(kv, "Decal", temp, sizeof(temp));
		if(!StrEqual(temp, sprayFile)) continue;

		return true;

	} while(KvGotoNextKey(kv));

	return true;
}

stock bool:checkClientSprayAction(client, type, String:action[PLATFORM_MAX_PATH]) {

	new Float:clientAim[3];
	if(!GetClientAim(client, clientAim)) return false;
	new Float:clientOrigin[3];
	GetClientAbsOrigin(client, clientOrigin);

	new Float:clientDistance;
	new Float:aimDistance;
	new bool:isAimClientSpray = false;
	new sprayClient;
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i)) continue;
		clientDistance = GetVectorDistance(clientOrigin, sprayOrigin[i]);
		if(clientDistance >= 200.0) continue;
		aimDistance = GetVectorDistance(clientAim, sprayOrigin[i]);
		if(aimDistance >= 100.0) continue;
		isAimClientSpray = true;
		sprayClient = i;
		break;
	}
	if(!isAimClientSpray) return false;

	decl String:sprayFile[16];
	if(!GetPlayerDecalFile(sprayClient, sprayFile, sizeof(sprayFile))) return false;

	decl String:temp[64];
	KvRewind(kv);
	do {
		KvGetString(kv, "Type", temp, sizeof(temp));
		if(!StrEqual(temp, "player")) continue;

		KvGetString(kv, "Decal", temp, sizeof(temp));
		if(!StrEqual(temp, sprayFile)) continue;

		KvGotoFirstSubKey(kv);

		new Float:vecPoint1[3];
		KvGetVector(kv, "Point1", vecPoint1);
		new Float:vecPoint2[3];
		KvGetVector(kv, "Point2", vecPoint2);

		if(!(vecPoint1[0] < (clientAim[0] - sprayOrigin[sprayClient][0]) < vecPoint2[0])) continue;
		if(!(vecPoint2[2] < (clientAim[2] - sprayOrigin[sprayClient][2]) < vecPoint1[2])) continue;

		KvGetString(kv, "ActionType", temp, sizeof(temp));
		if(StrEqual(temp, "url")) {
			type = SPRAY_ACTION_TYPE_URL;
		} else if(StrEqual(temp, "cmd")) {
			type = SPRAY_ACTION_TYPE_CMD;
		} else {
			type = SPRAY_ACTION_TYPE_NONE;
		}

		KvGetString(kv, "Action", action, sizeof(action));

		return true;

	} while(KvGotoNextKey(kv));

	return false;
}

stock executeSprayAction(client, type, const String:action[]) {
	switch(type) {
		case SPRAY_ACTION_TYPE_URL: {
			ShowMOTDPanel(client, "", action, MOTDPANEL_TYPE_URL);
		}
		case SPRAY_ACTION_TYPE_CMD: {
		}
	}
}

public Action:cmd_VoiceMenu(client, argCount) {
	decl String:arg[1];
	GetCmdArg(1, arg, sizeof(arg));
	if(StringToInt(arg) != 0) return Plugin_Continue;
	GetCmdArg(2, arg, sizeof(arg));
	if(StringToInt(arg) != 0) return Plugin_Continue;

	new type;
	decl String:action[PLATFORM_MAX_PATH];
	if(checkClientSprayAction(client, type, action)) {
		executeSprayAction(client, type, action);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:cmd_SprayCheck(client, argCount) {

	new Float:clientAim[3];
	if(!GetClientAim(client, clientAim)) return Plugin_Handled;
	new Float:clientOrigin[3];
	GetClientAbsOrigin(client, clientOrigin);

	new Float:aimDistance;
	new Float:clientDistance;
	decl String:sprayFile[16];
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i)) continue;
		clientDistance = GetVectorDistance(clientOrigin, sprayOrigin[i]);
		if(clientDistance >= 200.0) continue;
		aimDistance = GetVectorDistance(clientAim, sprayOrigin[i]);
		if(aimDistance >= 100.0) continue;
		if(!GetPlayerDecalFile(i, sprayFile, sizeof(sprayFile))) {
			PrintToChat(client, "[ImageMap] Could not find decal for client %d", i);
			continue;
		}

		/*
		PrintToChatAll("Aim => %f, %f, %f", clientAim[0], clientAim[1], clientAim[2]);
		PrintToChatAll("Decal => %f, %f, %f", sprayOrigin[sprayClient][0], sprayOrigin[sprayClient][1], sprayOrigin[sprayClient][2]);
		PrintToChatAll("Diff => %f, %f, %f", (clientAim[0] - sprayOrigin[sprayClient][0]), (clientAim[1] - sprayOrigin[sprayClient][1]), (clientAim[2] - sprayOrigin[sprayClient][2]));
		*/

		PrintToChatAll("PlayerDecal => %s", sprayFile);
		//PrintToChatAll("Distance => %f", clientDistance);
		PrintToChatAll("Point => %f, %f, %f", (clientAim[0] - sprayOrigin[i][0]), (clientAim[1] - sprayOrigin[i][1]), (clientAim[2] - sprayOrigin[i][2]));

		break;

	}

	return Plugin_Handled;
}

public Action:te_Spray(const String:teName[], const clients[], numClients, Float:delay) {
	new client = TE_ReadNum("m_nPlayer");

	new type;
	decl String:action[PLATFORM_MAX_PATH];
	if(checkClientSprayAction(client, type, action)) {
		executeSprayAction(client, type, action);
		return Plugin_Handled;
	}

	TE_ReadVector("m_vecOrigin", sprayOrigin[client]);
	return Plugin_Continue;
}

stock bool:GetClientAim(client, Float:targetOrigin[3]) {
	new Float:clientEyeOrigin[3]; GetClientEyePosition(client, clientEyeOrigin);
	new Float:clientEyeAngles[3]; GetClientEyeAngles(client, clientEyeAngles);
	new Handle:trace = TR_TraceRayFilterEx(clientEyeOrigin, clientEyeAngles, MASK_SHOT, RayType_Infinite, FilterPlayers);
	if(TR_DidHit(trace)) {
		TR_GetEndPosition(targetOrigin, trace);
		CloseHandle(trace);
		return true;
	}

	CloseHandle(trace);
	return false;
}

public bool:FilterPlayers(entity, contentsMask) {
 	return (entity > MaxClients);
}