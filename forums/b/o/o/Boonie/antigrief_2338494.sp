#include	<sourcemod>
#include	<sdktools>
#include	<sdkhooks>
#pragma		semicolon 1
#pragma 	newdecls required
#define 	PLUGIN_VERSION 	"2.0.0"

public Plugin myinfo =  {
	name = "Anti-Griefing Zones", 
	author = "Boonie", 
	description = "Fixes griefing zones on maps", 
	version = PLUGIN_VERSION, 
	url = "http://alliedmods.net"
};

/*-------------- Model for Bounding Box --------------*/
char model[PLATFORM_MAX_PATH] = "models\empty.mdl";
bool roundRunning = true;

public void OnPluginStart() {
	CreateConVar("antigrief_version", PLUGIN_VERSION, "Plugin Version", FCVAR_DONTRECORD|FCVAR_CHEAT|FCVAR_NOTIFY);	
	HookEvent("teamplay_round_start", Round_Start);
	HookEvent("teamplay_round_win", Round_End);
	HookEvent("teamplay_round_stalemate", Round_End);
}

public void OnMapStart() {
	PrecacheModel(model);
}

public Action Round_Start(Handle event, const char[] name, bool dontBroadcast) {
	roundRunning = true;
	char mapname[64], place[28] = "Placing Anti-Griefing Zones";
	GetCurrentMap(mapname, sizeof(mapname));
	if (StrEqual(mapname, "pl_upward")) {
		LogMessage(place);
		Zone(view_as<float>( { 1976.0, -1160.0, 72.0 } ), view_as<float>( { -40.0, -40.0, -72.0 } ), view_as<float>( { 40.0, 40.0, 72.0 } ), "PBZ:0:0:0:0"); // First Point Tunnel
	}
	else if (StrEqual(mapname, "pl_goldrush")) {
		LogMessage(place);
		Zone(view_as<float>( { -2424.0, 1311.0, -12.0 } ), view_as<float>( { -16.0, -87.0, -68.0 } ), view_as<float>( { 16.0, 87.0, 68.0 } ), "PBZ:0:0:1:1"); // First Section Blue Spawn Under Railtrack
		Zone(view_as<float>( { -7896.0, 412.0, 512.0 } ), view_as<float>( { -16.0, -48.0, -48.0 } ), view_as<float>( { 16.0, 48.0, 48.0 } ), "PCZ:0:0:0:0"); // Second Section Red Spawn In Pipe at Top of Map
		Zone(view_as<float>( { -5448.0, 810.0, 188.0 } ), view_as<float>( { -56.0, -26.0, -52.0 } ), view_as<float>( { 56.0, 26.0, 52.0 } ), "PBZ:0:0:1:1"); // Third Section Second Point Next to Stairs
		Zone(view_as<float>( { -4528.0, -968.0, -48.0 } ), view_as<float>( { -64.0, -184.0, -80.0 } ), view_as<float>( { 64.0, 184.0, 80.0 } ), "PBZ:0:0:0:0"); // Third Section Red Basement
	}
	else if (StrEqual(mapname, "pl_borneo")) {
		LogMessage(place);
		Zone(view_as<float>( { 864.0, -2576.0, 368.0 } ), view_as<float>( { -48.0, -48.0, -32.0 } ), view_as<float>( { 48.0, 48.0, 32.0 } ), "PBZ:0:0:0:0"); // Second Point Balcony
	}
	else if (StrEqual(mapname, "pl_badwater")) {
		LogMessage(place);
		Zone(view_as<float>( { -680.0, 864.0, 144.0 } ), view_as<float>( { -32.0, -216.0, -16.0 } ), view_as<float>( { 32.0, 216.0, 16.0 } ), "PBZ:0:0:0:0"); // Map Room Window
		Edit("nBuild:logic_relay:window_block_relay"); // Set Map Room NoBuild Kill
	}
	else if (StrEqual(mapname, "pl_hoodoo_final")) {
		LogMessage(place);
		Zone(view_as<float>( { -176.0, -1604.0, 176.0 } ), view_as<float>( { -64.0, -68.0, -48.0 } ), view_as<float>( { 64.0, 68.0, 48.0 } ), "PBZ:0:0:1:1"); // Second Section Second Point Under Railtrack
		Zone(view_as<float>( { 264.0, -1672.0, 176.0 } ), view_as<float>( { -56.0, -24.0, -48.0 } ), view_as<float>( { 56.0, 24.0, 48.0 } ), "PBZ:0:0:1:1"); // Second Section Second Point Under Railtrack
		Zone(view_as<float>( { -4160.0, -952.0, 136.0 } ), view_as<float>( { -304.0, -392.0, -136.0 } ), view_as<float>( { 304.0, 392.0, 136.0 } ), "PKZ:3:1:1:1"); // Third Section Blue Spawn
		Zone(view_as<float>( { -4416.0, -440.0, 240.0 } ), view_as<float>( { -192.0, -120.0, -176.0 } ), view_as<float>( { 192.0, 120.0, 176.0 } ), "PKZ:3:1:1:1"); // Third Section Blue Spawn Right Door
		Edit("Kill:func_nobuild:PKZ"); // Hook Kill Zone
	}
	else if (StrEqual(mapname, "pl_frontier_final")) {
		LogMessage(place);
		Zone(view_as<float>( { 1696.0, -2816.0, 8.0 } ), view_as<float>( { -64.0, -48.0, -56.0 } ), view_as<float>( { 64.0, 48.0, 56.0 } ), "PBZ:0:0:1:1"); // Blue Spawn Under Ramp to Spawn
		Zone(view_as<float>( { 3968.0, -1724.0, -72.0 } ), view_as<float>( { -32.0, -16.0, -56.0 } ), view_as<float>( { 32.0, 16.0, 56.0 } ), "PBZ:0:0:1:1"); // Red Spawn Barrel in Hut
		Zone(view_as<float>( { 4468.0, -608.0, -128.0 } ), view_as<float>( { -12.0, -92.0, -64.0 } ), view_as<float>( { 12.0, 92.0, 64.0 } ), "PBZ:0:1:1:0"); // Second Point Red/Blue Spawn Door
		Zone(view_as<float>( { -2164.0, 1008.0, 914.0 } ), view_as<float>( { -60.0, -192.0, -66.0 } ), view_as<float>( { 60.0, 192.0, 66.0 } ), "PBZ:0:0:0:0"); // Red Spawn Last Point Respawn Room
		Zone(view_as<float>( { -3776.0, 1392.0, -800.0 } ), view_as<float>( { -720.0, -720.0, -64.0 } ), view_as<float>( { 720.0, 720.0, 64.0 } ), "PBZ:0:0:0:0"); // Pit Last Point
	}
	else if (StrEqual(mapname, "plr_pipeline")) {
		LogMessage(place);
		Zone(view_as<float>( { -2200.0, 6688.0, 228.0 } ), view_as<float>( { -32.0, -160.0, -100.0 } ), view_as<float>( { 32.0, 160.0, 100.0 } ), "PBZ:0:0:0:0"); // Third Section Red Spawn
		Zone(view_as<float>( { 2200.0, 6688.0, 228.0 } ), view_as<float>( { -32.0, -160.0, -100.0 } ), view_as<float>( { 32.0, 160.0, 100.0 } ), "PBZ:0:0:0:0"); // Third Section Blue Spawn
	}
	else if (StrEqual(mapname, "plr_nightfall_final")) {
		LogMessage(place);
		Zone(view_as<float>( { -1992.0, 12096.0, 64.0 } ), view_as<float>( { -12.0, -96.0, -64.0 } ), view_as<float>( { 12.0, 96.0, 64.0 } ), "PBZ:0:0:0:0"); // Third Section Blue Spawn
		Zone(view_as<float>( { 1992.0, 12096.0, 64.0 } ), view_as<float>( { -12.0, -96.0, -64.0 } ), view_as<float>( { 12.0, 96.0, 64.0 } ), "PBZ:0:0:0:0"); // Third Section Red Spawn
	}
	else if (StrEqual(mapname, "cp_egypt_final")) {
		LogMessage(place);
		Zone(view_as<float>( { -4260.0, -1148.0, -356.0 } ), view_as<float>( { -60.0, -36.0, -60.0 } ), view_as<float>( { 60.0, 36.0, 60.0 } ), "PBZ:0:0:1:1"); // First Section Second Point Behind Left Torch
		Zone(view_as<float>( { -4260.0, -900.0, -356.0 } ), view_as<float>( { -60.0, -36.0, -60.0 } ), view_as<float>( { 60.0, 36.0, 60.0 } ), "PBZ:0:0:1:1"); // First Section Second Point Behind Right Torch
		Zone(view_as<float>( { -928.0, 1280.0, -60.0 } ), view_as<float>( { -224.0, -96.0, -100.0 } ), view_as<float>( { 224.0, 96.0, 100.0 } ), "PBZ:0:0:1:1"); // Second Section Inside Blue Spawn Room
		Zone(view_as<float>( { 64.0, 5232.0, 320.0 } ), view_as<float>( { -56.0, -56.0, -64.0 } ), view_as<float>( { 56.0, 56.0, 64.0 } ), "PBZ:0:0:0:0"); // Third Section First Point Between Pillers
		Zone(view_as<float>( { 1712.0, 7312.0, 1092.0 } ), view_as<float>( { -16.0, -40.0, -68.0 } ), view_as<float>( { 16.0, 40.0, 68.0 } ), "PBZ:0:0:0:0"); // Third Section Inside Red Spawn
	}
	else if (StrEqual(mapname, "cp_badlands")) {
		LogMessage(place);
		Zone(view_as<float>( { 768.0, 4848.0, 280.0 } ), view_as<float>( { -384.0, -16.0, -88.0 } ), view_as<float>( { 384.0, 16.0, 88.0 } ), "PBZ:0:0:0:0"); // Last Point Red Spawn Room
		Zone(view_as<float>( { 208.0, 2644.0, 200.0 } ), view_as<float>( { -144.0, -412.0, -8.0 } ), view_as<float>( { 144.0, 412.0, 8.0 } ), "PBZ:0:0:0:0"); // Second Point Red Spawn Room
	}
	else if (StrEqual(mapname, "cp_dustbowl")) {
		LogMessage(place);
		Zone(view_as<float>( { 984.0, -440.0, 72.0 } ), view_as<float>( { -40.0, -40.0, -72.0 } ), view_as<float>( { 40.0, 40.0, 72.0 } ), "PBZ:0:0:1:1"); // Third Section Last Point Left Stairs
		Edit("Coll:func_door:red_hq_door3"); // Add Collision - Third Section Red Spawn Shortcut Door
	}
	else if (StrEqual(mapname, "cp_manor_event")) {
		LogMessage(place);
		Zone(view_as<float>( { 1284.0, 1168.0, -832.0 } ), view_as<float>( { -30.0, -136.0, -64.0 } ), view_as<float>( { 30.0, 136.0, 64.0 } ), "PBZ:0:0:0:0"); // Red Spawn Door to Machine
	}
	else if (StrEqual(mapname, "cp_gravelpit")) {
		LogMessage(place);
		Zone(view_as<float>( { 432.0, 3656.0, -424.0 } ), view_as<float>( { -656.0, -760.0, -105.0 } ), view_as<float>( { 656.0, 760.0, 105.0 } ), "PKZ:3:1:1:1"); // Blue Spawn
		Edit("Kill:func_nobuild:PKZ"); // Hook Kill Zone
	}
	else if (StrEqual(mapname, "cp_steel")) {
		LogMessage(place);
		Zone(view_as<float>( { 424.0, -3064.0, -480.0 } ), view_as<float>( { -536.0, -328.0, -96.0 } ), view_as<float>( { 536.0, 328.0, 96.0 } ), "PKZ:3:1:1:1"); // Blue Spawn Center + Right
		Zone(view_as<float>( { -364.0, -3252.0, -480.0 } ), view_as<float>( { -252.0, -140.0, -96.0 } ), view_as<float>( { 252.0, 140.0, 96.0 } ), "PKZ:3:1:1:1"); // Blue Spawn Left Door
		Zone(view_as<float>( { -48.0, -2392.0, -376.0 } ), view_as<float>( { -64.0, -344.0, -128.0 } ), view_as<float>( { 64.0, 344.0, 128.0 } ), "PKZ:3:1:1:1"); // Blue Spawn Left Hallway
		Edit("Coll:func_door:point_a_door1"); // Add Collision - Point A Left Shortcut Door
		Edit("Coll:func_door:point_a_door2"); // Add Collision - Point A Right Shortcut Door
		Edit("Kill:func_nobuild:PKZ"); // Hook Kill Zone
	}
	else if (StrEqual(mapname, "cp_yukon_final")) {
		LogMessage(place);
		Zone(view_as<float>( { 128.0, 1472.0, 600.0 } ), view_as<float>( { -48.0, -12.0, -48.0 } ), view_as<float>( { 48.0, 12.0, 48.0 } ), "PCZ:0:0:0:0"); // Blue Second Point Above Shortcut
	}
	else if (StrEqual(mapname, "cp_fastlane")) {
		LogMessage(place);
		Zone(view_as<float>( { 644.0, -900.0, -84.0 } ), view_as<float>( { -68.0, -68.0, -60.0 } ), view_as<float>( { 68.0, 68.0, 60.0 } ), "PBZ:0:0:1:1"); // Red Spawn Second Point Under Stairs
		Zone(view_as<float>( { -644.0, -1924.0, -84.0 } ), view_as<float>( { -68.0, -68.0, -60.0 } ), view_as<float>( { 68.0, 68.0, 60.0 } ), "PBZ:0:0:1:1"); // Blue Spawn Second Point Under Stairs
	}
}

public Action Round_End(Handle event, const char[] name, bool dontBroadcast) {
	roundRunning = false;
}

public void Zone(float position[3], float minbounds[3], float maxbounds[3], char[] parameters) {
	char param[5][4];
	ExplodeString(parameters, ":", param, sizeof(param), sizeof(param[]));
	int zone = CreateEntityByName((StrEqual(param[0], "PCZ")) ? "func_brush" : "func_nobuild");
	if (zone != -1) {
		DispatchKeyValueVector(zone, "origin", position);
		if (StrEqual(param[0], "PCZ")) {
			DispatchKeyValue(zone, "Solidity", "2");
			DispatchKeyValue(zone, "spawnflags", "2");
		} else {
			DispatchKeyValue(zone, "targetname", param[0]);
			DispatchKeyValue(zone, "TeamNum", param[1]);
			DispatchKeyValue(zone, "AllowTeleporters", param[2]);
			DispatchKeyValue(zone, "AllowDispenser", param[3]);
			DispatchKeyValue(zone, "AllowSentry", param[4]);
		}
		DispatchKeyValue(zone, "StartDisabled", "0");
		DispatchSpawn(zone);
		ActivateEntity(zone);
		SetEntityModel(zone, model);
		SetEntPropVector(zone, Prop_Send, "m_vecMins", minbounds);
		SetEntPropVector(zone, Prop_Send, "m_vecMaxs", maxbounds);
		SetEntProp(zone, Prop_Send, "m_nSolidType", 2);
		SetEntProp(zone, Prop_Send, "m_fEffects", GetEntProp(zone, Prop_Send, "m_fEffects") | 32);
	}
}

public void Edit(char[] parameters) {
	int entity = -1;
	char ent[128], param[3][20];
	ExplodeString(parameters, ":", param, sizeof(param), sizeof(param[]));
	while ((entity = FindEntityByClassname(entity, param[1])) != -1) {
		if (IsValidEntity(entity)) {
			GetEntPropString(entity, Prop_Data, "m_iName", ent, sizeof(ent));
			if (StrEqual(ent, param[2])) {
				if (StrEqual(param[0], "Coll")) {
					SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
				}
				if (StrEqual(param[0], "Kill")) {
					SDKHook(entity, SDKHook_TouchPost, OnTouchKillZone);
					SDKHook(entity, SDKHook_StartTouchPost, OnTouchKillZone);
				}
				if (StrEqual(param[0], "nBuild")) {
					SetVariantString("OnTrigger PBZ,Kill");
					AcceptEntityInput(entity, "AddOutput");
				}
			}
		}
	}
}

public void OnTouchKillZone(int entity, int other) {
	if (other < 1 || other > MaxClients || !IsPlayerAlive(other) || !roundRunning) {
		return;
	}
	if (GetEntProp(entity, Prop_Send, "m_iTeamNum") != GetClientTeam(other) && !CheckCommandAccess(other, "antigrief_spawn_access", ADMFLAG_GENERIC)) {
		ForcePlayerSuicide(other);
	}
} 