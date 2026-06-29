#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION 		"1.0.0.0"
#define MAXKEYS 128
#define TEAM_BLUE 3
#define TEAM_RED 2

new bool:g_bCanSpawnCmd[MAXPLAYERS+1] = {true, ...};
new bool:g_bCreatorMode = false;

new g_nextProp = 0;
new g_entProp[MAXKEYS] = {-1, ...};

new Handle:g_hCreateForBoth = INVALID_HANDLE;
new Handle:g_hKv = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[tTF2DM] Createmode",
	author = "Thrawn",
	description = "[tTF2DM] Createmode. Allows placing of spawnpoints.",
	version = PLUGIN_VERSION,
};

public OnPluginStart() {
	g_hCreateForBoth = CreateConVar("sm_tf2dm_createforboth", "1", "Create spawnpoint usable for both teams.", FCVAR_PLUGIN|FCVAR_NOTIFY);

	RegAdminCmd("sm_tf2dm_createspawn", CreateSpawn_Command, ADMFLAG_BAN, "[SM] Usage: sm_tf2dm_createspawn");
	RegAdminCmd("sm_tf2dm_creatermode", ShowSpawns_Command, ADMFLAG_BAN, "[SM] Usage: sm_tf2dm_createspawn");	
}

public Action:ShowSpawns_Command(client, args) {
	if(g_bCreatorMode) {
		ReplyToCommand(client, "[TF2] Creator mode disabled.");
		g_bCreatorMode = false;
		removeAllVS();
	} else {
		ReplyToCommand(client, "[TF2] Creator mode enabled. You can place spawns now using sm_tf2dm_createspawn.");
		
		g_bCreatorMode = true;

		if(g_hKv!=INVALID_HANDLE)
			CloseHandle(g_hKv);

		g_hKv = CreateKeyValues("Spawns");

		decl String:map[64];
		GetCurrentMap(map, sizeof(map));

		decl String:path[256];
		decl String:filepath[256];
		Format(filepath, sizeof(filepath), "configs/tf2dm/%s.cfg", map);
		BuildPath(Path_SM, path, sizeof(path), filepath);
		if(FileExists(path)) {		
			FileToKeyValues(g_hKv, path);

			decl String:sTeam[5], Float:origin[3], Float:angles[3];
			KvGotoFirstSubKey(g_hKv);	

			do {
				KvGetString(g_hKv, "team", sTeam, sizeof(sTeam));
				KvGetVector(g_hKv, "origin", origin);
				KvGetVector(g_hKv, "angles", angles);

				if(strcmp(sTeam,"red") == 0) {
					createVisualSpawn(2,origin,angles);
				}

				if(strcmp(sTeam,"blue") == 0) {
					createVisualSpawn(1,origin,angles);
				}

				if(strcmp(sTeam,"both") == 0) {
					createVisualSpawn(0,origin,angles);
				}


			} while(KvGotoNextKey(g_hKv));			

		} else {
			LogError("File Not Found: %s", path);
		}			
	}
	
	return Plugin_Handled;
}

stock createVisualSpawn(skin,Float:origin[3],Float:angles[3]) {
	if(g_entProp[g_nextProp] != -1)
		removeVisualSpawn(g_nextProp);

	g_entProp[g_nextProp] = CreateEntityByName("prop_dynamic");

	if (IsValidEdict(g_entProp[g_nextProp]))
	{
		new String:tmpNumber[2];    
		IntToString(skin, tmpNumber, 2);
		DispatchKeyValue(g_entProp[g_nextProp], "skin", tmpNumber);
		SetEntityModel(g_entProp[g_nextProp], "models/player/scout.mdl");
		DispatchSpawn(g_entProp[g_nextProp]);

		TeleportEntity(g_entProp[g_nextProp], origin, angles, NULL_VECTOR);
	}
	
	g_nextProp++;
}

stock removeVisualSpawn(id) {
	RemoveEdict(g_entProp[id]);
	g_entProp[id] = -1;
}

stock removeAllVS() {
	for(new i = 0; i < g_nextProp; i++) {
		if(g_entProp[i] != -1)
			removeVisualSpawn(i);
	}
}

public Action:CreateSpawn_Command(client, args) {
	if(g_bCanSpawnCmd[client] && g_bCreatorMode) {	
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);

		new Float:ang[3];
		GetClientEyeAngles(client, ang);		

		decl String:teamname[5];
		if(GetConVarBool(g_hCreateForBoth)) {
			teamname = "both";
		} else {
			if(GetClientTeam(client) == TEAM_BLUE)
				teamname = "blue";
			else
				teamname = "red";
		}
		
		LogMessage("Creating %s random spawn at %f %f %f facing %f %f", teamname, pos[0], pos[1], pos[2], ang[0], ang[1]);
				
		g_hKv = CreateKeyValues("Spawns");
	
		decl String:map[64];
		GetCurrentMap(map, sizeof(map));

		decl String:path[256];
		decl String:filepath[256];
		Format(filepath, sizeof(filepath), "configs/tf2dm/%s.cfg", map);
		BuildPath(Path_SM, path, sizeof(path), filepath);
	
		if(FileExists(path)) {
			FileToKeyValues(g_hKv, path);
		}
		
		new bool:didSth = false;
			
		new iterationsCnt = 0;
		decl String:keyname[6];		
		do {
			IntToString(iterationsCnt, keyname, sizeof(keyname));			
			KvRewind(g_hKv);
			iterationsCnt++;			
		} while (KvJumpToKey(g_hKv, keyname, false) && iterationsCnt < MAXKEYS);
		
		KvRewind(g_hKv);
		
		if(iterationsCnt == MAXKEYS) {
			ReplyToCommand(client, "[TF2] Maximum spawn locations reached. Sorry.");
			return Plugin_Handled;
		}
		
		if(KvJumpToKey(g_hKv, keyname, true)) {					
			LogMessage("Creating: %s", keyname);
			KvSetVector(g_hKv, "origin", pos);
			KvSetVector(g_hKv, "angles", ang);
			KvSetString(g_hKv, "team", teamname);
			didSth = true;
			KvGoBack(g_hKv);				
		}				
		
		if(didSth) {
			KeyValuesToFile(g_hKv, path);						
			createVisualSpawn(0,pos,ang);
		}
		
		g_bCanSpawnCmd[client] = false;
		CreateTimer(2.0, Timer_reenableSpawnCmd, client);
	}
	else {
		ReplyToCommand(client, "[TF2] Creator mode not enabled or too soon to create another spawn.");		
	}
	
	return Plugin_Handled;
}

public Action:Timer_reenableSpawnCmd(Handle:timer, any:client){
	g_bCanSpawnCmd[client] = true;
}

stock Float:calcDistance(Float:x1,Float:x2,Float:y1,Float:y2,Float:z1,Float:z2){ 
	new Float:dx = x1-x2;
	new Float:dy = y1-y2;
	new Float:dz = z1-z2;
	return(SquareRoot(dx*dx + dy*dy + dz*dz));
}