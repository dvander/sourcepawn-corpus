#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PL_VERSION "0.5"

public Plugin:myinfo = {
	name        = "Anti Sniper-Leader",
	author      = "[PWH]BonzaiRob",
	description = "Prevents snipers from staying top of leaderboard per team.",
	version     = PL_VERSION,
	url         = "http://www.pwh-clan.co.uk/"
}

// Heavily based on Tsunami's Class Restriction. Go get it, it's great!

new g_iClass[MAXPLAYERS + 1];
new g_iClients;
new Handle:g_hEnabled;
new Handle:g_hImmunity;
new String:g_sSounds[5][32] = {"", "vo/sniper_no01.wav", "vo/sniper_no02.wav", "vo/sniper_no03.wav", "vo/sniper_no04.wav"};

public OnPluginStart() {
	CreateConVar("sm_antisniperleader_version", PL_VERSION, "Restrict Snipers from being point leaders.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hEnabled       = CreateConVar("sm_antisniperleader_enabled",       "1",  "Enable/disable class-swapping winning Snipers.");

	g_hImmunity      = CreateConVar("sm_antisniperleader_immunity",      "0",  "Enable/disable admin immunity for class-swapping winning Snipers.");
	
	HookEvent("player_changeclass", Event_ChangeClass);
	HookEvent("player_spawn",       Event_PlayerSpawn);
	HookEvent("player_team",        Event_ChangeTeam);
}

public OnMapStart() {
	decl i, String:sSound[40];
	for (i = 1; i < sizeof(g_sSounds); i++) {
		Format(sSound, sizeof(sSound), "sound/%s", g_sSounds[i]);
		PrecacheSound(g_sSounds[i]);
		AddFileToDownloadsTable(sSound);
	}
	
	g_iClients       = GetMaxClients();
}

public OnClientPutInServer(client) {
	g_iClass[client] = 0;
}

public Event_ChangeClass(Handle:event, const String:name[], bool:dontBroadcast) {
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	new iTeam = GetClientTeam(iClient);
	
	if (IsWin(iTeam, iClient) && !IsImmune(iClient)) {
		ShowVGUIPanel(iClient, iTeam == 3 ? "class_blue" : "class_red");
		EmitSoundToClient(iClient, g_sSounds[GetRandomInt(1, 4)]);
		TF2_SetPlayerClass(iClient, TFClassType:g_iClass[iClient]);
		PrintCenterText(iClient, "You're top of the points board, you can't be Sniper.");
		LogAction(0, iClient, "Player %s tried to be sniper", iClient);
	}
}

public Event_ChangeTeam(Handle:event,  const String:name[], bool:dontBroadcast) {
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	new iTeam = GetEventInt(event, "team");
	
	if (IsWin(iTeam, iClient) && !IsImmune(iClient)) {
		ShowVGUIPanel(iClient, iTeam == 3 ? "class_blue" : "class_red");
		PickClass(iClient);
	}
	
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new iClient = GetClientOfUserId(GetEventInt(event, "userid")), iTeam = GetClientTeam(iClient);
	g_iClass[iClient] = _:TF2_GetPlayerClass(iClient);
	if (IsWin(iTeam, iClient) && !IsImmune(iClient)) {
		new String:txteam[] = "   A";
		if (iTeam == 3){
			txteam = "blue";
		} else if (iTeam == 4){
			txteam = " red";
		}
		
		//ServerCommand("@%s Sniper slot just became available.", txteam);
		ShowVGUIPanel(iClient, iTeam == 3 ? "class_blue" : "class_red");
		PickClass(iClient);
	}
}

bool:IsWin(iTeam, iClient) {
	//new bool:told = false;
	if (GetConVarBool(g_hEnabled) && iTeam > 1) {
	//change the below line to change the class; in this example i chose heavy which is '4'.
	//this is just a quick-fix example, though; untested, and some other variables such as the sound
	//need to be changed for it to fully work I think.
		if (_:TF2_GetPlayerClass(iClient) == 4) {
			//Apparently, correct order is:
			//1Scout, 2Sniper, 3Soldier, 4Heavy, 
			//5Medic, 6Demo, 7Pyro, 8Spy, 9Engy
			new fail = 0;
			for (new i = 1; i <= g_iClients; i++) {
				if (TF2_GetPlayerResourceData(iClient, TFResource_TotalScore) <= TF2_GetPlayerResourceData(i, TFResource_TotalScore)
				&& GetClientTeam(i) == iTeam
				&& iClient != i) {
					++fail;
				}
			}
			if (fail == 0){
				EmitSoundToClient(iClient, g_sSounds[GetRandomInt(1, 4)]);
				//ShowActivity2(iClient, "[ASL] ", "You're top of the points board, you can't be sniper.");
				PrintCenterText(iClient, "You're top of the points board, you can't be Sniper.");
				LogAction(0, iClient, "Player %s tried to be sniper", iClient);
				/*if (told == false){
					new String:txteam[] = "   A";
					if (iTeam == 3){
						txteam = "blue";
					} else if (iTeam == 4){
						txteam = " red";
					}
					ServerCommand("say_team %s Sniper slot just became available.", txteam);
					told = true;
				}*/
				
				
				return true;
			}
		}
	}
	return false;
}

bool:IsImmune(iClient) {
	return GetConVarBool(g_hImmunity) && GetUserFlagBits(iClient) & (ADMFLAG_GENERIC|ADMFLAG_ROOT);
}

PickClass(iClient) {
	new i = GetRandomInt(1, 9), iClass = i, iTeam = GetClientTeam(iClient);
	for (;;) {
		if (IsWin(iTeam, iClient))  {
			TF2_SetPlayerClass(iClient, TFClassType:i);
			TF2_RespawnPlayer(iClient);
			g_iClass[iClient] = i;
			break;
		} else if (++i >= 9)    {
			i = 1;
		} else if (i == iClass) {
			break;
		}
	}
}