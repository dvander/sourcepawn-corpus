#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include "vocalizefatigue"

public Plugin:myinfo =
{
	name = "[L4D2] Model Based Vocalizations Part 2",
	author = "DeathChaos, cravenge",
	description = "Continuation Of First Part Plugin.",
	version = "1.5",
	url = ""
};

static const String:g_sCoach[][] =
{
	"BoomerReaction01", "BoomerReaction02", "BoomerReaction03", "BoomerReaction04", "BoomerReaction05", "BoomerReaction06", "BoomerReaction07", "BoomerReaction08",
	"ScreamWhilePounced01", "ScreamWhilePounced02", "ScreamWhilePounced02A", "ScreamWhilePounced03", "ScreamWhilePounced04", "ScreamWhilePounced05",
	"GrabbedByJockey01", "GrabbedByJockey02", "GrabbedByJockey03", "GrabbedByJockey04", "GrabbedByJockey05", "GrabbedByJockey06", "GrabbedByJockey07", "GrabbedByJockey08", "GrabbedByJockey09",
	"GrabbedByCharger01", "GrabbedByCharger02", "GrabbedByCharger03", "GrabbedByCharger04", "GrabbedByCharger05", "GrabbedByCharger06", "GrabbedByCharger07", "GrabbedByCharger08", "GrabbedByCharger09",
	"DLC_M6001", "DLC_M6002", "DLC_M6003", "DLC_M6004", "DLC_M6005", "DLC_M6006", "DLC_M6007", "DLC_M6008",
	"TakeGrenadeLauncher01", "TakeGrenadeLauncher02", "TakeGrenadeLauncher03", "TakeGrenadeLauncher04", "TakeGrenadeLauncher05",
	"TakeAssaultRifle01", "TakeAssaultRifle02", "TakeAssaultRifle03", "TakeAssaultRifle04", "TakeAssaultRifle05",
	"TakeAutoShotgun01", "TakeAutoShotgun02", "TakeAutoShotgun03",
	"TakeSniper01", "TakeSniper02", "TakeSniper03",
	"TakeSubMachineGun01", "TakeSubMachineGun02", "TakeSubMachineGun03",
	"TakeShotgun01", "TakeShotgun02", "TakeShotgun03",
	"TakePistol01", "TakePistol02", "TakePistol03",
	"Choke01", "Choke02", "Choke03", "Choke04", "Choke05", "Choke06", "Choke07", "Choke08", "Choke09", "Choke10", "Choke11", "Choke12", "Choke13"
};

static const String:g_sNick[][] =
{
	"BoomerReaction01", "BoomerReaction02", "BoomerReaction03", "BoomerReaction04",
	"ScreamWhilePounced01", "ScreamWhilePounced01A", "ScreamWhilePounced02", "ScreamWhilePounced02A", "ScreamWhilePounced03", "ScreamWhilePounced03A", "ScreamWhilePounced04", "ScreamWhilePounced04A", "ScreamWhilePounced04B", "ScreamWhilePounced05", "ScreamWhilePounced05A", "ScreamWhilePounced06",
	"GrabbedByJockey01", "GrabbedByJockey02", "GrabbedByJockey03", "GrabbedByJockey04", "GrabbedByJockey05", "GrabbedByJockey06",
	"GrabbedByCharger01", "GrabbedByCharger02", "GrabbedByCharger03", "GrabbedByCharger04", "GrabbedByCharger05", "GrabbedByCharger06", "GrabbedByCharger07", "GrabbedByCharger08",
	"DLC_M6001", "DLC_M6002", "DLC_M6003", "DLC_M6004", "DLC_M6005", "DLC_M6006",
	"GrenadeLauncher02", "GrenadeLauncher03", "GrenadeLauncher04",
	"TakeAssaultRifle01", "TakeAssaultRifle02", "TakeAssaultRifle03", "TakeAssaultRifle04", "TakeAssaultRifle05",
	"TakeAutoShotgun01", "TakeAutoShotgun02", "TakeAutoShotgun03", "TakeAutoShotgun04",
	"TakeSniper01", "TakeSniper02", "TakeSniper03", "TakeSniper04",
	"TakeSubMachineGun01", "TakeSubMachineGun02",
	"TakeShotgun01", "TakeShotgun02", "TakeShotgun03",
	"TakePistol01", "TakePistol02", "TakePistol03",
	"Choke01", "Choke02", "Choke03", "Choke04", "Choke05", "Choke06", "Choke07"
};

static const String:g_sEllis[][] =
{
	"BoomerReaction01", "BoomerReaction02", "BoomerReaction03", "BoomerReaction04", "BoomerReaction05", "BoomerReaction06",
	"ScreamWhilePounced01", "ScreamWhilePounced01A", "ScreamWhilePounced01B", "ScreamWhilePounced02", "ScreamWhilePounced03", "ScreamWhilePounced03A", "ScreamWhilePounced04", "ScreamWhilePounced04A", "ScreamWhilePounced05", "ScreamWhilePounced05B", "ScreamWhilePounced05C", "ScreamWhilePounced06", "ScreamWhilePounced06A", "ScreamWhilePounced06B", "ScreamWhilePounced07", "ScreamWhilePounced07A", "ScreamWhilePounced07B", "ScreamWhilePounced07C", "ScreamWhilePounced07D",
	"GrabbedByJockey01", "GrabbedByJockey02", "GrabbedByJockey03", "GrabbedByJockey04", "GrabbedByJockey05", "GrabbedByJockey06", "GrabbedByJockey07",
	"GrabbedByCharger01", "GrabbedByCharger02", "GrabbedByCharger03", "GrabbedByCharger04", "GrabbedByCharger05", "GrabbedByCharger06", "GrabbedByCharger07", "GrabbedByCharger08", "GrabbedByCharger09",
	"DLC_M6001", "DLC_M6002", "DLC_M6003", "DLC_M6004", "DLC_M6005", "DLC_M6006", "DLC_M6007", "DLC_M6008", "DLC_M6009", "DLC_M6010", "DLC_M6011", "DLC_M6012", "DLC_M6013",
	"GrenadeLauncher03", "GrenadeLauncher04", "GrenadeLauncher05",
	"TakeAssaultRifle01", "TakeAssaultRifle02", "TakeAssaultRifle03", "TakeAssaultRifle04", "TakeAssaultRifle05",
	"TakeAutoShotgun01", "TakeAutoShotgun02", "TakeAutoShotgun03",
	"TakeSniper01", "TakeSniper02", "TakeSniper03",
	"TakeSubMachineGun01", "TakeSubMachineGun02", "TakeSubMachineGun03", "TakeSubMachineGun04",
	"TakeShotgun01", "TakeShotgun02", "TakeShotgun03",
	"TakePistol01", "TakePistol02", "TakePistol03", "TakePistol04", "TakePistol05",
	"Choke01", "Choke02", "Choke03", "Choke04", "Choke05", "Choke06", "Choke07"
};

static const String:g_sRochelle[][] =
{
	"BoomerReaction01", "BoomerReaction02", "BoomerReaction03", "BoomerReaction04", "BoomerReaction05",
	"ScreamWhilePounced01", "ScreamWhilePounced01A", "ScreamWhilePounced02", "ScreamWhilePounced02A", "ScreamWhilePounced02B", "ScreamWhilePounced03", "ScreamWhilePounced03A", "ScreamWhilePounced03B", "ScreamWhilePounced03C", "ScreamWhilePounced04", "ScreamWhilePounced04A", "ScreamWhilePounced04B", "ScreamWhilePounced05", "ScreamWhilePounced05A",
	"GrabbedByJockey01", "GrabbedByJockey02", "GrabbedByJockey03", "GrabbedByJockey04", "GrabbedByJockey05", "GrabbedByJockey06", "GrabbedByJockey07", "GrabbedByJockey08",
	"GrabbedByCharger01", "GrabbedByCharger02", "GrabbedByCharger03", "GrabbedByCharger04", "GrabbedByCharger05", "GrabbedByCharger06", "GrabbedByCharger07", "GrabbedByCharger08", "GrabbedByCharger09",
	"DLC_M6001", "DLC_M6002", "DLC_M6003", "DLC_M6004", "DLC_M6005", "DLC_M6006", "DLC_M6007", "DLC_M6008", "DLC_M6009", "DLC_M6010",
	"GrenadeLauncher03", "GrenadeLauncher04", "GrenadeLauncher05", "GrenadeLauncher06",
	"TakeAssaultRifle01", "TakeAssaultRifle02", "TakeAssaultRifle03",
	"TakeAutoShotgun01", "TakeAutoShotgun02", "TakeAutoShotgun03",
	"TakeSniper01", "TakeSniper02",
	"TakeSubMachineGun01", "TakeSubMachineGun02",
	"TakeShotgun01", "TakeShotgun02", "TakeShotgun03",
	"TakePistol01", "TakePistol02", "TakePistol03", "TakePistol04",
	"Choke01", "Choke02", "Choke03", "Choke04", "Choke05", "Choke06"
};

static const String:g_sBill[][] =
{
	"ReactionBoomerVomit01", "ReactionBoomerVomit02", "ReactionDisgusted01", "ReactionDisgusted02", "ReactionDisgusted03", "ReactionDisgusted04", "ReactionDisgusted05", "ReactionDisgusted06", "ReactionDisgusted07", "ReactionDisgusted08",
	"ScreamWhilePounced01", "ScreamWhilePounced02", "ScreamWhilePounced03",
	"TankPound01", "TankPound02", "TankPound03",
	"TakeAssaultRifle01", "TakeAssaultRifle02", "TakeAssaultRifle03", "TakeAssaultRifle04", "TakeAssaultRifle05",
	"TakeAutoShotgun01", "TakeAutoShotgun02", "TakeAutoShotgun03", "TakeAutoShotgun04", "TakeAutoShotgun05",
	"TakeSniper01", "TakeSniper02", "Blank",
	"TakeSubMachineGun01", "TakeSubMachineGun02", "TakeSubMachineGun03",
	"TakeShotgun01", "TakeShotgun02", "TakeShotgun03",
	"TakePistol01", "TakePistol02", "TakePistol03", "TakePistol04",
	"Choke01", "Choke02", "Choke03", "Choke04", "Choke05", "Choke06", "Choke07", "Choke08", "Choke09", "Choke10", "Choke11", "Choke12"
};

static const String:g_sFrancis[][] =
{
	"ReactionBoomerVomit01", "ReactionBoomerVomit02", "ReactionBoomerVomit03", "ReactionBoomerVomit04", "ReactionBoomerVomit05", "ReactionDisgusted01", "ReactionDisgusted02", "ReactionDisgusted03", "ReactionDisgusted04", "ReactionDisgusted05", "ReactionDisgusted06", "ReactionDisgusted07", "ReactionDisgusted08", "ReactionDisgusted09", "ReactionDisgusted10",
	"ScreamWhilePounced01", "ScreamWhilePounced02", "ScreamWhilePounced03", "ScreamWhilePounced04",
	"TankPound01", "TankPound02", "TankPound03", "TankPound04",
	"TakeAssaultRifle01", "TakeAssaultRifle02", "TakeAssaultRifle03", "TakeAssaultRifle04", "TakeAssaultRifle05", "TakeAssaultRifle06", "TakeAssaultRifle07", "TakeAssaultRifle08",
	"TakeAutoShotgun01", "TakeAutoShotgun02", "TakeAutoShotgun03", "TakeAutoShotgun04", "TakeAutoShotgun05", "TakeAutoShotgun06", "TakeAutoShotgun07", "TakeAutoShotgun08",
	"TakeSniper01", "TakeSniper02", "Blank",
	"TakeSubMachineGun01", "TakeSubMachineGun02", "TakeSubMachineGun03",
	"TakeShotgun01", "TakeShotgun02", "TakeShotgun03", "TakeShotgun04",
	"TakePistol01", "TakePistol02", "TakePistol03", "TakePistol04",
	"Choke01", "Choke02", "Choke03", "Choke04", "Choke05", "Choke06", "Choke07", "Choke08", "Choke09"
};

static const String:g_sLouis[][] =
{
	"ReactionBoomerVomit01", "ReactionBoomerVomit02", "ReactionBoomerVomit03", "ReactionBoomerVomit04", "ReactionDisgusted01", "ReactionDisgusted02", "ReactionDisgusted03", "ReactionDisgusted04",
	"ScreamWhilePounced01", "ScreamWhilePounced02", "ScreamWhilePounced03",
	"TankPound01", "TankPound02", "TankPound03", "TankPound04", "TankPound05",
	"TakeAssaultRifle01", "TakeAssaultRifle02", "TakeAssaultRifle03", "TakeAssaultRifle04", "TakeAssaultRifle05",
	"TakeAutoShotgun01", "TakeAutoShotgun02", "TakeAutoShotgun03", "TakeAutoShotgun04", "TakeAutoShotgun05",
	"TakeSniper01", "TakeSniper02", "Blank",
	"TakeSubMachineGun01", "TakeSubMachineGun02", "TakeSubMachineGun03",
	"TakeShotgun01",
	"TakePistol01", "TakePistol02",
	"Choke01", "Choke02", "Choke03", "Choke04", "Choke05", "Choke06", "Choke07", "Choke08"
};

static const String:g_sZoey[][] =
{
	"ReactionBoomerVomit01", "ReactionBoomerVomit02", "ReactionBoomerVomit03", "ReactionDisgusted02", "ReactionDisgusted04", "ReactionDisgusted05", "ReactionDisgusted06", "ReactionDisgusted07", "ReactionDisgusted09", "ReactionDisgusted10", "ReactionDisgusted12", "ReactionDisgusted13",
	"ScreamWhilePounced01", "ScreamWhilePounced02", "ScreamWhilePounced03", "ScreamWhilePounced04", "ScreamWhilePounced06",
	"TankPound01", "TankPound02", "TankPound03", "TankPound04", "TankPound05",
	"TakeAssaultRifle01", "TakeAssaultRifle02", "TakeAssaultRifle03", "TakeAssaultRifle04", "TakeAssaultRifle05", "TakeAssaultRifle06", "TakeAssaultRifle07", "TakeAssaultRifle08",
	"TakeAutoShotgun01", "TakeAutoShotgun02", "TakeAutoShotgun03", "TakeAutoShotgun04", "TakeAutoShotgun05", "TakeAutoShotgun06",
	"TakeSniper01", "TakeSniper02", "TakeSniper04", "Blank",
	"TakeSubMachineGun01", "TakeSubMachineGun03", "TakeSubMachineGun04", "TakeSubMachineGun05",
	"TakeShotgun01", "TakeShotgun02", "TakeShotgun03", "TakeShotgun04", "TakeShotgun05",
	"TakePistol01", "TakePistol02", "TakePistol03", "TakePistol04", "TakePistol07", "TakePistol08",
	"Choke01", "Choke02", "Choke03", "Choke04"
};

static Float:initialPosition[32][3];

static bool:IsPlayerPounced[MAXPLAYERS+1] = false;
static bool:IsPlayerRidden[MAXPLAYERS+1] = false;
static bool:IsPlayerPummeled[MAXPLAYERS+1] = false;
static bool:IsPlayerChoked[MAXPLAYERS+1] = false;

public OnPluginStart()
{
	HookEvent("round_start", OnVocalizationsReset);
	HookEvent("round_end", OnVocalizationsReset);
	HookEvent("mission_lost", OnVocalizationsReset);
	HookEvent("map_transition", OnVocalizationsReset);
	HookEvent("player_spawn", OnVocalizationsReset);
	HookEvent("player_transitioned", OnVocalizationsReset);
	HookEvent("defibrillator_used", OnDefibrillatorUsed);
	HookEvent("player_now_it", OnPlayerNowIt);
	HookEvent("ability_use", OnAbilityUse);
	HookEvent("lunge_pounce", OnLungePounce);
	HookEvent("pounce_end", OnHunterEventsEnd);
	HookEvent("pounce_stopped", OnHunterEventsEnd);
	HookEvent("jockey_ride", OnJockeyRide);
	HookEvent("jockey_ride_end", OnJockeyRideEnd);
	HookEvent("charger_pummel_start", OnChargerPummelStart);
	HookEvent("charger_pummel_end", OnChargerPummelEnd);
	HookEvent("choke_start", OnChokeStart);
	HookEvent("choke_end", OnSmokerEventsEnd);
	HookEvent("choke_stopped", OnSmokerEventsEnd);
	HookEvent("player_use", OnPlayerUse);
}

public OnMapStart()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			IsPlayerPounced[i] = false;
			IsPlayerRidden[i] = false;
			IsPlayerPummeled[i] = false;
			IsPlayerChoked[i] = false;
		}
	}
}

public OnMapEnd()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			IsPlayerPounced[i] = false;
			IsPlayerRidden[i] = false;
			IsPlayerPummeled[i] = false;
			IsPlayerChoked[i] = false;
		}
	}
}

public Action:OnVocalizationsReset(Handle:event, const String:name[], bool:dontBroadcast)
{
	new vocalizer = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidSurvivor(vocalizer))
	{
		IsPlayerPounced[vocalizer] = false;
		IsPlayerRidden[vocalizer] = false;
		IsPlayerPummeled[vocalizer] = false;
		IsPlayerChoked[vocalizer] = false;
	}
}

public Action:L4D_OnClientVocalize(client, const String:vocalize[]) 
{
	if(!IsValidSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(client, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	if (StrEqual(vocalize, "playerboomerreaction") || StrEqual(vocalize, "playerreactionboomervomit") || StrEqual(vocalize, "playerreactiondisgusted"))
	{
		switch (i_Type)
		{
			case 1: { i_Min = 0; i_Max = 7; }
			case 2: { i_Min = 0; i_Max = 3; }
			case 3: { i_Min = 0; i_Max = 5; }
			case 4: { i_Min = 0; i_Max = 4; }
			case 5: { i_Min = 0; i_Max = 9; }
			case 6: { i_Min = 0; i_Max = 14; }
			case 7: { i_Min = 0; i_Max = 7; }
			case 8: { i_Min = 0; i_Max = 11; }
		}
	}
	else if (StrEqual(vocalize, "playerscreamwhilepounced"))
	{
		switch (i_Type)
		{
			case 1: { i_Min = 8; i_Max = 13; }
			case 2: { i_Min = 4; i_Max = 15; }
			case 3: { i_Min = 6; i_Max = 24; }
			case 4: { i_Min = 5; i_Max = 18; }
			case 5: { i_Min = 10; i_Max = 12; }
			case 6: { i_Min = 15; i_Max = 18; }
			case 7: { i_Min = 8; i_Max = 10; }
			case 8: { i_Min = 12; i_Max = 16; }
		}
	}
	else if (StrEqual(vocalize, "playergrabbedbyjockey"))
	{
		switch (i_Type)
		{
			case 1: { i_Min = 14; i_Max = 22; }
			case 2: { i_Min = 16; i_Max = 21; }
			case 3: { i_Min = 25; i_Max = 31; }
			case 4: { i_Min = 19; i_Max = 26; }
			case 5: { i_Min = 10; i_Max = 12; }
			case 6: { i_Min = 15; i_Max = 18; }
			case 7: { i_Min = 8; i_Max = 10; }
			case 8: { i_Min = 12; i_Max = 16; }
		}
	}
	else if (StrEqual(vocalize, "playergrabbedbycharger"))
	{
		switch (i_Type)
		{
			case 1: { i_Min = 23; i_Max = 31; }
			case 2: { i_Min = 22; i_Max = 29; }
			case 3: { i_Min = 32; i_Max = 40; }
			case 4: { i_Min = 27; i_Max = 35; }
			case 5: { i_Min = 13; i_Max = 15; }
			case 6: { i_Min = 19; i_Max = 22; }
			case 7: { i_Min = 11; i_Max = 15; }
			case 8: { i_Min = 17; i_Max = 21; }
		}
	}
	else if (StrEqual(vocalize, "playertakem60"))
	{
		switch (i_Type)
		{
			case 1: { i_Min = 32; i_Max = 39; }
			case 2: { i_Min = 30; i_Max = 35; }
			case 3: { i_Min = 41; i_Max = 53; }
			case 4: { i_Min = 36; i_Max = 45; }
			case 5: { i_Min = 16; i_Max = 20; }
			case 6: { i_Min = 23; i_Max = 30; }
			case 7: { i_Min = 16; i_Max = 20; }
			case 8: { i_Min = 22; i_Max = 29; }
		}
	}
	else if (StrEqual(vocalize, "playertakegrenadelauncher"))
	{
		switch (i_Type)
		{
			case 1: { i_Min = 40; i_Max = 44; }
			case 2: { i_Min = 36; i_Max = 38; }
			case 3: { i_Min = 54; i_Max = 56; }
			case 4: { i_Min = 46; i_Max = 49; }
			case 5: { i_Min = 28; i_Max = 28; }
			case 6: { i_Min = 41; i_Max = 41; }
			case 7: { i_Min = 28; i_Max = 28; }
			case 8: { i_Min = 39; i_Max = 39; }
		}
	}
	else if (StrEqual(vocalize, "playertakeassaultrifle"))
	{
		switch (i_Type)
		{
			case 1: { i_Min = 45; i_Max = 49; }
			case 2: { i_Min = 39; i_Max = 43; }
			case 3: { i_Min = 57; i_Max = 61; }
			case 4: { i_Min = 50; i_Max = 52; }
			case 5: { i_Min = 16; i_Max = 20; }
			case 6: { i_Min = 23; i_Max = 30; }
			case 7: { i_Min = 16; i_Max = 20; }
			case 8: { i_Min = 22; i_Max = 29; }
		}
	}
	else if (StrEqual(vocalize, "playertakeautoshotgun"))
	{
		switch (i_Type)
		{
			case 1: { i_Min = 50; i_Max = 52; }
			case 2: { i_Min = 44; i_Max = 47; }
			case 3: { i_Min = 62; i_Max = 64; }
			case 4: { i_Min = 53; i_Max = 55; }
			case 5: { i_Min = 21; i_Max = 25; }
			case 6: { i_Min = 31; i_Max = 38; }
			case 7: { i_Min = 21; i_Max = 25; }
			case 8: { i_Min = 30; i_Max = 35; }
		}
	}
	else if (StrEqual(vocalize, "playertakesniper"))
	{
		switch (i_Type)
		{
			case 1: { i_Min = 53; i_Max = 55; }
			case 2: { i_Min = 48; i_Max = 51; }
			case 3: { i_Min = 65; i_Max = 67; }
			case 4: { i_Min = 56; i_Max = 57; }
			case 5: { i_Min = 26; i_Max = 27; }
			case 6: { i_Min = 39; i_Max = 40; }
			case 7: { i_Min = 26; i_Max = 27; }
			case 8: { i_Min = 36; i_Max = 38; }
		}
	}
	else if (StrEqual(vocalize, "playertakesubmachinegun"))
	{
		switch (i_Type)
		{
			case 1: { i_Min = 56; i_Max = 58; }
			case 2: { i_Min = 52; i_Max = 53; }
			case 3: { i_Min = 68; i_Max = 71; }
			case 4: { i_Min = 58; i_Max = 59; }
			case 5: { i_Min = 29; i_Max = 31; }
			case 6: { i_Min = 42; i_Max = 44; }
			case 7: { i_Min = 29; i_Max = 31; }
			case 8: { i_Min = 40; i_Max = 43; }
		}
	}
	else if (StrEqual(vocalize, "playertakeshotgun"))
	{
		switch (i_Type)
		{
			case 1: { i_Min = 59; i_Max = 61; }
			case 2: { i_Min = 54; i_Max = 56; }
			case 3: { i_Min = 72; i_Max = 74; }
			case 4: { i_Min = 60; i_Max = 62; }
			case 5: { i_Min = 32; i_Max = 34; }
			case 6: { i_Min = 45; i_Max = 48; }
			case 7: { i_Min = 32; i_Max = 32; }
			case 8: { i_Min = 44; i_Max = 48; }
		}
	}
	else if (StrEqual(vocalize, "playertakepistol"))
	{
		switch (i_Type)
		{
			case 1: { i_Min = 62; i_Max = 64; }
			case 2: { i_Min = 57; i_Max = 59; }
			case 3: { i_Min = 75; i_Max = 79; }
			case 4: { i_Min = 63; i_Max = 66; }
			case 5: { i_Min = 35; i_Max = 38; }
			case 6: { i_Min = 49; i_Max = 52; }
			case 7: { i_Min = 33; i_Max = 34; }
			case 8: { i_Min = 49; i_Max = 54; }
		}
	}
	else if (StrEqual(vocalize, "playerchoke"))
	{
		switch (i_Type)
		{
			case 1: { i_Min = 65; i_Max = 77; }
			case 2: { i_Min = 60; i_Max = 66; }
			case 3: { i_Min = 80; i_Max = 86; }
			case 4: { i_Min = 67; i_Max = 72; }
			case 5: { i_Min = 39; i_Max = 50; }
			case 6: { i_Min = 53; i_Max = 61; }
			case 7: { i_Min = 35; i_Max = 42; }
			case 8: { i_Min = 55; i_Max = 58; }
		}
	}
	else
	{
		return Plugin_Continue;
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_sCoach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_sNick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_sEllis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_sRochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_sBill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_sFrancis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_sLouis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_sZoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(client, s_Scene);
		L4D_MakeClientVocalizeEx(client, CustomVoc[75]);
	}
	
	return Plugin_Handled;
}

VocalizeScene(client, String:scenefile[90])
{
	new tempent = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(tempent, "SceneFile", scenefile);
	DispatchSpawn(tempent);
	SetEntPropEnt(tempent, Prop_Data, "m_hOwner", client);
	ActivateEntity(tempent);
	AcceptEntityInput(tempent, "Start", client, client);
}

public Action:OnDefibrillatorUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new revived = GetClientOfUserId(GetEventInt(event, "subject"));
	if(!IsValidSurvivor(revived))
	{
		return;
	}
	
	IsPlayerPounced[revived] = false;
	IsPlayerRidden[revived] = false;
	IsPlayerPummeled[revived] = false;
	IsPlayerChoked[revived] = false;
}

public Action:OnPlayerNowIt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new blinded = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidSurvivor(blinded))
	{
		return Plugin_Handled;
	}
	
	CreateTimer(0.1, BoomerReactionDelay, blinded);
	
	return Plugin_Continue;
}

public Action:BoomerReactionDelay(Handle:timer, any:blinded)
{
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(blinded, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	switch (i_Type)
	{
		case 1: { i_Min = 0; i_Max = 7; }
		case 2: { i_Min = 0; i_Max = 3; }
		case 3: { i_Min = 0; i_Max = 5; }
		case 4: { i_Min = 0; i_Max = 4; }
		case 5: { i_Min = 0; i_Max = 9; }
		case 6: { i_Min = 0; i_Max = 14; }
		case 7: { i_Min = 0; i_Max = 7; }
		case 8: { i_Min = 0; i_Max = 11; }
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_sCoach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_sNick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_sEllis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_sRochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_sBill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_sFrancis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_sLouis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_sZoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(blinded, s_Scene);
		L4D_MakeClientVocalizeEx(blinded, CustomVoc[75]);
	}
	
	return Plugin_Stop;
}

public Action:OnAbilityUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new hunter = GetClientOfUserId(GetEventInt(event, "userid"));
	if (hunter == 0)
	{
		return;
	}
	GetClientAbsOrigin(hunter, initialPosition[hunter]);
}

public Action:OnLungePounce(Handle:event, const String:name[], bool:dontBroadcast)
{
	new pouncer = GetClientOfUserId(GetEventInt(event, "userid"));
	new pounced = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if(!IsValidSurvivor(pounced) || !IsValidInfected(pouncer))
	{
		return Plugin_Handled;
	}
	
	new Float:pouncePosition[3];
	GetClientAbsOrigin(pouncer, pouncePosition);
	new pouncedist = RoundToNearest(GetVectorDistance(initialPosition[pouncer], pouncePosition));
	
	if(pouncedist >= 1750)
	{
		return Plugin_Handled;
	}
	
	IsPlayerPounced[pounced] = true;
	
	CreateTimer(2.0, ScreamWhilePouncedDelay, pounced, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action:ScreamWhilePouncedDelay(Handle:timer, any:pounced)
{
	if(!IsValidEntity(pounced) || !IsPlayerPounced[pounced])
	{
		return Plugin_Stop;
	}
	
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(pounced, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	switch (i_Type)
	{
		case 1: { i_Min = 8; i_Max = 13; }
		case 2: { i_Min = 4; i_Max = 15; }
		case 3: { i_Min = 6; i_Max = 24; }
		case 4: { i_Min = 5; i_Max = 18; }
		case 5: { i_Min = 10; i_Max = 12; }
		case 6: { i_Min = 15; i_Max = 18; }
		case 7: { i_Min = 8; i_Max = 10; }
		case 8: { i_Min = 12; i_Max = 16; }
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_sCoach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_sNick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_sEllis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_sRochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_sBill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_sFrancis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_sLouis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_sZoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(pounced, s_Scene);
		L4D_MakeClientVocalizeEx(pounced, CustomVoc[75]);
	}
	
	return Plugin_Continue;
}

public Action:OnHunterEventsEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new helped = GetClientOfUserId(GetEventInt(event, "victim"));
	if(!IsValidSurvivor(helped))
	{
		return;
	}
	
	IsPlayerPounced[helped] = false;
}

public Action:OnJockeyRide(Handle:event, const String:name[], bool:dontBroadcast)
{
	new rider = GetClientOfUserId(GetEventInt(event, "userid"));
	new ridden = GetClientOfUserId(GetEventInt(event, "victim"));
	if(!IsValidSurvivor(ridden) || !IsValidInfected(rider))
	{
		return Plugin_Handled;
	}
	
	IsPlayerRidden[ridden] = true;
	
	CreateTimer(2.0, GrabbedByJockeyDelay, ridden, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action:GrabbedByJockeyDelay(Handle:timer, any:ridden)
{
	if(!IsPlayerRidden[ridden])
	{
		return Plugin_Stop;
	}
	
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(ridden, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	switch (i_Type)
	{
		case 1: { i_Min = 14; i_Max = 22; }
		case 2: { i_Min = 16; i_Max = 21; }
		case 3: { i_Min = 25; i_Max = 31; }
		case 4: { i_Min = 19; i_Max = 26; }
		case 5: { i_Min = 10; i_Max = 12; }
		case 6: { i_Min = 15; i_Max = 18; }
		case 7: { i_Min = 8; i_Max = 10; }
		case 8: { i_Min = 12; i_Max = 16; }
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_sCoach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_sNick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_sEllis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_sRochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_sBill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_sFrancis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_sLouis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_sZoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(ridden, s_Scene);
		L4D_MakeClientVocalizeEx(ridden, CustomVoc[75]);
	}
	
	return Plugin_Continue;
}

public Action:OnJockeyRideEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ally = GetClientOfUserId(GetEventInt(event, "victim"));
	if(!IsValidSurvivor(ally))
	{
		return;
	}
	
	IsPlayerRidden[ally] = false;
}

public Action:OnChargerPummelStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new pummeler = GetClientOfUserId(GetEventInt(event, "userid"));
	new pummeled = GetClientOfUserId(GetEventInt(event, "victim"));
	if(!IsValidInfected(pummeler) || !IsValidSurvivor(pummeled))
	{
		return Plugin_Handled;
	}
	
	IsPlayerPummeled[pummeled] = true;
	
	CreateTimer(3.0, GrabbedByChargerDelay, pummeled, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action:GrabbedByChargerDelay(Handle:timer, any:pummeled)
{
	if(!IsPlayerPummeled[pummeled])
	{
		return Plugin_Stop;
	}
	
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(pummeled, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	switch (i_Type)
	{
		case 1: { i_Min = 23; i_Max = 31; }
		case 2: { i_Min = 22; i_Max = 29; }
		case 3: { i_Min = 32; i_Max = 40; }
		case 4: { i_Min = 27; i_Max = 35; }
		case 5: { i_Min = 13; i_Max = 15; }
		case 6: { i_Min = 19; i_Max = 22; }
		case 7: { i_Min = 11; i_Max = 15; }
		case 8: { i_Min = 17; i_Max = 21; }
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_sCoach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_sNick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_sEllis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_sRochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_sBill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_sFrancis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_sLouis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_sZoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(pummeled, s_Scene);
		L4D_MakeClientVocalizeEx(pummeled, CustomVoc[75]);
	}
	
	return Plugin_Continue;
}

public Action:OnChargerPummelEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new charged = GetClientOfUserId(GetEventInt(event, "victim"));
	if(!IsValidSurvivor(charged))
	{
		return;
	}
	
	IsPlayerPummeled[charged] = false;
}

public Action:OnChokeStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new choked = GetClientOfUserId(GetEventInt(event, "victim"));
	if(!IsValidSurvivor(choked))
	{
		return Plugin_Handled;
	}
	
	IsPlayerChoked[choked] = true;
	
	CreateTimer(1.5, ChokeDelay, choked, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action:ChokeDelay(Handle:timer, any:choked)
{
	if(!IsPlayerChoked[choked])
	{
		return Plugin_Stop;
	}
	
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(choked, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	switch (i_Type)
	{
		case 1: { i_Min = 65; i_Max = 77; }
		case 2: { i_Min = 60; i_Max = 66; }
		case 3: { i_Min = 80; i_Max = 86; }
		case 4: { i_Min = 67; i_Max = 72; }
		case 5: { i_Min = 39; i_Max = 50; }
		case 6: { i_Min = 53; i_Max = 61; }
		case 7: { i_Min = 35; i_Max = 42; }
		case 8: { i_Min = 55; i_Max = 58; }
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_sCoach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_sNick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_sEllis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_sRochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_sBill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_sFrancis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_sLouis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_sZoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(choked, s_Scene);
		L4D_MakeClientVocalizeEx(choked, CustomVoc[75]);
	}
	
	return Plugin_Continue;
}

public Action:OnSmokerEventsEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new dragged = GetClientOfUserId(GetEventInt(event, "victim"));
	if(!IsValidSurvivor(dragged))
	{
		return;
	}
	
	IsPlayerChoked[dragged] = false;
}

public Action:OnPlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new user = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidSurvivor(user))
	{
		return Plugin_Handled;
	}
	
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(user, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	new gWeapon = GetEventInt(event, "targetid");
	if (gWeapon <= 0 || !IsValidEntity(gWeapon))
	{
		return Plugin_Handled;
	}
	
	decl String:cbEquipped[64];
	GetEdictClassname(gWeapon, cbEquipped, sizeof(cbEquipped));
	if (strncmp(cbEquipped, "weapon", 6) == 0)
	{
		if (StrEqual(cbEquipped, "weapon_rifle", false) || StrEqual(cbEquipped, "weapon_rifle_ak47", false) || StrEqual(cbEquipped, "weapon_rifle_desert", false) || StrEqual(cbEquipped, "weapon_rifle_sg552", false))
		{
			switch (i_Type)
			{
				case 1: { i_Min = 45; i_Max = 49; }
				case 2: { i_Min = 39; i_Max = 43; }
				case 3: { i_Min = 57; i_Max = 61; }
				case 4: { i_Min = 50; i_Max = 52; }
				case 5: { i_Min = 16; i_Max = 20; }
				case 6: { i_Min = 23; i_Max = 30; }
				case 7: { i_Min = 16; i_Max = 20; }
				case 8: { i_Min = 22; i_Max = 29; }
			}
		}
		else if (StrEqual(cbEquipped, "weapon_smg", false) || StrEqual(cbEquipped, "weapon_smg_silenced", false) || StrEqual(cbEquipped, "weapon_smg_mp5", false))
		{
			switch (i_Type)
			{
				case 1: { i_Min = 56; i_Max = 58; }
				case 2: { i_Min = 52; i_Max = 53; }
				case 3: { i_Min = 68; i_Max = 71; }
				case 4: { i_Min = 58; i_Max = 59; }
				case 5: { i_Min = 29; i_Max = 31; }
				case 6: { i_Min = 42; i_Max = 44; }
				case 7: { i_Min = 29; i_Max = 31; }
				case 8: { i_Min = 40; i_Max = 43; }
			}
		}		
		else if (StrEqual(cbEquipped, "weapon_pumpshotgun", false) || StrEqual(cbEquipped, "weapon_shotgun_chrome", false))
		{
			switch (i_Type)
			{
				case 1: { i_Min = 59; i_Max = 61; }
				case 2: { i_Min = 54; i_Max = 56; }
				case 3: { i_Min = 72; i_Max = 74; }
				case 4: { i_Min = 60; i_Max = 62; }
				case 5: { i_Min = 32; i_Max = 34; }
				case 6: { i_Min = 45; i_Max = 48; }
				case 7: { i_Min = 32; i_Max = 32; }
				case 8: { i_Min = 44; i_Max = 48; }
			}
		}
		else if (StrEqual(cbEquipped, "weapon_autoshotgun", false) || StrEqual(cbEquipped, "weapon_shotgun_spas", false))
		{
			switch (i_Type)
			{
				case 1: { i_Min = 50; i_Max = 52; }
				case 2: { i_Min = 44; i_Max = 47; }
				case 3: { i_Min = 62; i_Max = 64; }
				case 4: { i_Min = 53; i_Max = 55; }
				case 5: { i_Min = 21; i_Max = 25; }
				case 6: { i_Min = 31; i_Max = 38; }
				case 7: { i_Min = 21; i_Max = 25; }
				case 8: { i_Min = 30; i_Max = 35; }
			}
		}
		else if (StrEqual(cbEquipped, "weapon_hunting_rifle", false) || StrEqual(cbEquipped, "weapon_sniper_military", false) || StrEqual(cbEquipped, "weapon_sniper_awp", false) || StrEqual(cbEquipped, "weapon_sniper_scout", false))
		{
			switch (i_Type)
			{
				case 1: { i_Min = 53; i_Max = 55; }
				case 2: { i_Min = 48; i_Max = 51; }
				case 3: { i_Min = 65; i_Max = 67; }
				case 4: { i_Min = 56; i_Max = 57; }
				case 5: { i_Min = 26; i_Max = 27; }
				case 6: { i_Min = 39; i_Max = 40; }
				case 7: { i_Min = 26; i_Max = 27; }
				case 8: { i_Min = 36; i_Max = 38; }
			}
		}
		else if (StrEqual(cbEquipped, "weapon_grenade_launcher", false))
		{
			switch (i_Type)
			{
				case 1: { i_Min = 40; i_Max = 44; }
				case 2: { i_Min = 36; i_Max = 38; }
				case 3: { i_Min = 54; i_Max = 56; }
				case 4: { i_Min = 46; i_Max = 49; }
				case 5: { i_Min = 28; i_Max = 28; }
				case 6: { i_Min = 41; i_Max = 41; }
				case 7: { i_Min = 28; i_Max = 28; }
				case 8: { i_Min = 39; i_Max = 39; }
			}
		}
		else if (StrEqual(cbEquipped, "weapon_rifle_m60", false))
		{
			switch (i_Type)
			{
				case 1: { i_Min = 32; i_Max = 39; }
				case 2: { i_Min = 30; i_Max = 35; }
				case 3: { i_Min = 41; i_Max = 53; }
				case 4: { i_Min = 36; i_Max = 45; }
				case 5: { i_Min = 16; i_Max = 20; }
				case 6: { i_Min = 23; i_Max = 30; }
				case 7: { i_Min = 16; i_Max = 20; }
				case 8: { i_Min = 22; i_Max = 29; }
			}
		}
		else if (StrEqual(cbEquipped, "weapon_pistol", false))
		{
			if(GetEntProp(GetPlayerWeaponSlot(user, 1), Prop_Send, "m_hasDualWeapons") == 1)
			{
				return Plugin_Handled;
			}
			else
			{
				switch (i_Type)
				{
					case 1: { i_Min = 62; i_Max = 64; }
					case 2: { i_Min = 57; i_Max = 59; }
					case 3: { i_Min = 75; i_Max = 79; }
					case 4: { i_Min = 63; i_Max = 66; }
					case 5: { i_Min = 35; i_Max = 38; }
					case 6: { i_Min = 49; i_Max = 52; }
					case 7: { i_Min = 33; i_Max = 34; }
					case 8: { i_Min = 49; i_Max = 54; }
				}
			}
		}
		else
		{
			return Plugin_Handled;
		}
		
		i_Rand = GetRandomInt(i_Min, i_Max);
		decl String:s_Temp[40];
		
		switch (i_Type)
		{
			case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_sCoach[i_Rand]);
			case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_sNick[i_Rand]);
			case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_sEllis[i_Rand]);
			case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_sRochelle[i_Rand]);
			case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_sBill[i_Rand]);
			case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_sFrancis[i_Rand]);
			case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_sLouis[i_Rand]);
			case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_sZoey[i_Rand]);
		}
		{
			decl String:CustomVoc[75];
			decl String:s_Scene[90];
			Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
			CustomVoc[75] = VocalizeScene(user, s_Scene);
			L4D_MakeClientVocalizeEx(user, CustomVoc[75]);
		}
	}
	else
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public IsValidSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

public IsValidInfected(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}

