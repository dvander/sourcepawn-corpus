#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PL_VERSION "1.0"

public Plugin:myinfo = {
	name        = "Anti Class-Leader",
	author      = "[PWH]BonzaiRob",
	description = "Prevents specified class from staying top of leaderboard per team.",
	version     = PL_VERSION,
	url         = "http://www.pwh-clan.co.uk/"
}

// Heavily based on Tsunami's Class Restriction. Go get it, it's great!
// Previously Anti Sniper-Leader, hence default 8.

new g_iClass[MAXPLAYERS + 1];
new g_iClients;
new Handle:g_hEnabled;
new Handle:g_hImmunity;
new Handle:g_hClass;


new String:g_sSounds[10][32] = {"", "vo/scout_no03.wav",   "vo/sniper_no04.wav", "vo/soldier_no01.wav",
																		"vo/demoman_no03.wav", "vo/medic_no02.wav",  "vo/heavy_no02.wav",
																		"vo/pyro_no01.wav",    "vo/spy_no02.wav",    "vo/engineer_no03.wav"};

public OnPluginStart() {
	CreateConVar("sm_anticlassleader_version", PL_VERSION, "Restrict specified class from being point leaders.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hEnabled       = CreateConVar("sm_anticlassleader_enabled",       "1",  "Enable/disable class-swapping leaders.");
	g_hImmunity      = CreateConVar("sm_anticlassleader_immunity",      "0",  "Enable/disable admin immunity for class-swapping leaders.");
	g_hClass      = CreateConVar("sm_anticlassleader_class",      "8",  "Class to disable, 1 to 9.");
	
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
		
		
		new String:classname[32] = "-noclass-";
		switch (getClassNo(GetConVarInt(g_hClass))){
			case 1:
				classname = "Scout";
			case 2:
				classname = "Soldier";
			case 3:
				classname = "Pyro";
			case 4:
				classname = "Demoman";
			case 5:
				classname = "Heavy";
			case 6:
				classname = "Engineer";
			case 7:
				classname = "Medic";
			case 8:
				classname = "Sniper";
			case 9:
				classname = "Spy";
		}
		
		ShowVGUIPanel(iClient, iTeam == 3 ? "class_blue" : "class_red");
		TF2_SetPlayerClass(iClient, TFClassType:g_iClass[iClient]);
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
		ShowVGUIPanel(iClient, iTeam == 3 ? "class_blue" : "class_red");
		PickClass(iClient);
	}
}

public getClassNo(classno){
	new realclassno = 0;
	switch (classno){
		case 1:
			realclassno = 1;
		case 2:
			realclassno = 3;
		case 3:
			realclassno = 7;
		case 4:
			realclassno = 4;
		case 5:
			realclassno = 6;
		case 6:
			realclassno = 9;
		case 7:
			realclassno = 5;
		case 8:
			realclassno = 2;
		case 9:
			realclassno = 8;
	}
	return realclassno;
}
			

bool:IsWin(iTeam, iClient) {
	if (GetConVarBool(g_hEnabled) && iTeam > 1) {
		if (_:TF2_GetPlayerClass(iClient) == getClassNo(GetConVarInt(g_hClass)) ) {
			//Apparently, correct order is:
			//1Scout, 2Sniper, 3Soldier, 4Heavy, 
			//5Medic, 6Demo, 7Pyro, 8Spy, 9Engy

			new String:classname[32] = "-noclass-";
			switch (GetConVarInt(g_hClass)){
				case 1:
					classname = "Scout";
				case 2:
					classname = "Soldier";
				case 3:
					classname = "Pyro";
				case 4:
					classname = "Demoman";
				case 5:
					classname = "Heavy";
				case 6:
					classname = "Engineer";
				case 7:
					classname = "Medic";
				case 8:
					classname = "Sniper";
				case 9:
					classname = "Spy";
			}
			
			
			new fail = 0;
			for (new i = 1; i <= g_iClients; i++) {
				if (TF2_GetPlayerResourceData(iClient, TFResource_TotalScore) <= TF2_GetPlayerResourceData(i, TFResource_TotalScore)
				&& GetClientTeam(i) == iTeam
				&& iClient != i) {
					++fail;
				}
			}
			if (fail == 0){
				EmitSoundToClient(iClient, g_sSounds[getClassNo(GetConVarInt(g_hClass))]);
				PrintCenterText(iClient, "You're top of the points board, you can't be %s.", classname);
				LogAction(0, iClient, "Player %i tried to be %s", iClient, classname);
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