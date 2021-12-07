#pragma semicolon 1

#include <sourcemod>
#include <keyvalues>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CONFIG_FILE "configs/driver_name_display.cfg"

new String:CraneRelationsFile[PLATFORM_MAX_PATH];
new Handle:CraneRelationsList;
new String:currentMap[64];
new SettingExists = false;

new bool:lookingAt[MAXPLAYERS+1] = { false, ... };

public Plugin:myinfo = 
{
	name = "vehicle driver name display",
	author = "Berni",
	description = "Shows the name of the driver when looking at the vehicle",
	version = PLUGIN_VERSION,
	url = "http://manni.ice-gfx.com/forum"
};

public OnPluginStart() {
	BuildPath(Path_SM, CraneRelationsFile, sizeof(CraneRelationsFile), CONFIG_FILE);

	RegConsoleCmd("sm_cranes", Cranes);
	
	CreateTimer(0.6, Timer, 0, TIMER_REPEAT);
}

public OnMapStart() {
	Load_Settings();
}

public Action:Timer(Handle:timer, any:value) {
	new String:entName[32];
	new aimTarget;
	
	new maxplayers = GetMaxClients();
	for (new i=1; i<maxplayers; ++i) {
		if(IsClientInGame(i)) {   
			aimTarget = GetClientAimTarget(i, false);
			
			if (aimTarget > 0) {
				GetEntityNetClass(aimTarget, entName, sizeof(entName));
					
				new offset_player = FindSendPropOffs(entName, "m_hPlayer");

				if (offset_player != -1) {
					new driver = GetEntDataEnt(aimTarget, offset_player);
					
					if (driver == i) {
						continue;
					}
				
					if (driver > 0) {
						PrintCenterText(i, "Driver: %N", driver);
					}
					else {
						PrintCenterText(i, "Driver: empty");
					}
					
					lookingAt[i] = true;
					continue;
				}
			}
			
			if (lookingAt[i]) {
				PrintCenterText(i, "");
				lookingAt[i] = false;
			}
		}
	}
}

public Action:Cranes(client, args) {
	new String:entName[32], String:outputMsg[256];
	strcopy(outputMsg, sizeof(outputMsg), "");
	new num_cranes = 0;
	new num_drived_cranes = 0;
	new countMsg = 1;
	new String:output_closest[128];
	strcopy(output_closest, sizeof(output_closest), "");
	new Float:closestDistance = 0.0;

    	for (new i=0; i<=GetMaxEntities(); i++) {
       	if(IsValidEntity(i) && GetEntityNetClass(i, entName, sizeof(entName))) {
			if (StrEqual(entName, "CPropCrane")) {
				new offset_player = FindSendPropOffs("CPropCrane", "m_hPlayer");
				new crandriver = GetEntDataEnt(i, offset_player);

				new String:playerName[64];
				new String:craneName[64];
				new String:output[128];

				if (crandriver > 0) {
					GetClientName(crandriver, playerName, sizeof(playerName));
				}
				else {
					strcopy(playerName, sizeof(playerName), "No Driver");
				}
	
				if (!GetNameOfCrane(i, craneName, 64)) {
					strcopy(craneName, sizeof(craneName), "Crane");
				}

				if (GetUserAdmin(client) != INVALID_ADMIN_ID) {
					Format(output, sizeof(output), "\x01%s \x04\x01(#%d)\x01: \x04%s", craneName, i, playerName);
				}
				else {
					Format(output, sizeof(output), "\x01%s\x01: \x04%s", craneName, playerName);
				}

				PrintToChat(client, output);
				countMsg++;

				new Float:clientPos[3];
				new Float:cranePos[3];

				new offset_craneVec = FindSendPropOffs("CPropCrane", "m_vecOrigin");
				GetClientAbsOrigin(client, clientPos);
				GetEntDataVector(i, offset_craneVec, cranePos);
				new Float:distance = GetVectorDistance(clientPos, cranePos);

				if (closestDistance == 0 || distance < closestDistance) {
					Format(output_closest, sizeof(output_closest), ", closest crane: %s", output);
					closestDistance = distance;
				}

				if (crandriver > 0) {
					num_drived_cranes++;
				}
				num_cranes++;
			}
					
		}
	
	}

	if (!StrEqual(outputMsg, "")) {
		PrintToChat(client, outputMsg);
	}

	PrintToChat(client, "\x04Total: \x04%d\x01 cranes, \x04%d \x01cranes with drivers in it%s", num_cranes, num_drived_cranes, output_closest);
	
	return Plugin_Handled;
}


public GetNameOfCrane(index, String:buf[], size) {
	if (SettingExists) {
		new String:entID[8];

		IntToString(index, entID, sizeof(entID));
		KvGetString(CraneRelationsList, entID, buf, size, "");

		if (StrEqual(buf, "")) {
			return false;
		}
	}
	else {
		return false;
	}
	
	return true;
}

public Load_Settings() {
	if(!FileExists(CraneRelationsFile)) {
		LogMessage("%s not parsed...file doesnt exist!", CraneRelationsFile);
		SettingExists= false;
	}
	else {
		GetCurrentMap(currentMap, sizeof(currentMap));
		PrintToServer("Map: %s", currentMap);

		CraneRelationsList = CreateKeyValues("cranelist");
		FileToKeyValues(CraneRelationsList, CraneRelationsFile);

		if (!KvJumpToKey(CraneRelationsList, currentMap)) {
			LogMessage("No matching setting in %s for this map (%s) !", CONFIG_FILE, currentMap);
			SettingExists= false;
		}
		else {
			SettingExists=true;
		}
	}

	return SettingExists;
}
