/*
Version 1.1:
Fixed a possable handle leak with timers
Fixed thirdpersonshoulder with not showing models of others regarding my transmithook
MasterMind improved thirdpersonshould THIRDPERSON FIX Marker for his work
1.1.1
Fixed stack errors from sev

1.2
added 3 cvars
lmc_ai_model_chance
lmc_ai_model_teams
lmc_allow_tank_model_use

Plugin will now work with CSM or plugins that change the survivor model
fixed some stack errors with mastermind's thirdpersonshoulder checking
Tuned the SetTransmit code with TimoCop :D
Fixed Invis model exploit and fixed malformed model issue with csm
Fixed revive finish showing 2 models
you can now toggle random models for AI
Few tweaks for perf

Added 9 new common infected models
Added Infected pilot in the random common infected pool
Making a total of 33 common infected models

Added Chopper pilot model which replace the Pilot menu entry to Chopper pilot yay we have another human model.

Another bug that i can't fix is Invis models regarding tabbing in and out of the game that sometimes makes you invis this is a clientside issue
*/
//Credit timocop for helpy :D
/*
	Check out http://downloadtzz.spdns.de
	There are a few cool programs and a sourcepawn editor called basicpawe
*/
	


#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1


#define ENABLE_AUTOEXEC true
#define MAX_FRAMECHECK 20

#define PLUGIN_VERSION "1.2"

#define ZOMBIECLASS_SMOKER		1
#define ZOMBIECLASS_BOOMER		2
#define ZOMBIECLASS_HUNTER		3
#define ZOMBIECLASS_TANK		5

#define Witch_Normal			"models/infected/witch.mdl"

#define Infected_TankNorm		"models/infected/hulk.mdl"
#define Infected_TankSac		"models/infected/hulk_dlc3.mdl"
#define Infected_Boomer			"models/infected/boomer.mdl"
#define Infected_Hunter			"models/infected/hunter.mdl"
#define Infected_Smoker			"models/infected/smoker.mdl"

#define MODEL_BILL				"models/survivors/survivor_namvet.mdl"
#define MODEL_ZOEY				"models/survivors/survivor_teenangst.mdl"
#define MODEL_FRANCIS			"models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS				"models/survivors/survivor_manager.mdl"

#define Infected_Common1		"models/infected/common_female_nurse01.mdl"
#define Infected_Common2		"models/infected/common_female_rural01.mdl"
#define Infected_Common3		"models/infected/common_female01.mdl"
#define Infected_Common4		"models/infected/common_male_baggagehandler_01.mdl"
#define Infected_Common5		"models/infected/common_male_pilot.mdl"
#define Infected_Common6		"models/infected/common_male_rural01.mdl"
#define Infected_Common7		"models/infected/common_male_suit.mdl"
#define Infected_Common8		"models/infected/common_male01.mdl"
#define Infected_Common9		"models/infected/common_military_male01.mdl"
#define Infected_Common10		"models/infected/common_patient_male01.mdl"
#define Infected_Common11		"models/infected/common_police_male01.mdl"
#define Infected_Common12		"models/infected/common_surgeon_male01.mdl"
#define Infected_Common13		"models/infected/common_tsaagent_male01.mdl"
#define Infected_Common14		"models/infected/common_worker_male01.mdl"

/*THIRDPERSON FIX*/
static bool:AfkFix[MAXPLAYERS+1];
static bool:DeathFix[MAXPLAYERS+1];
static bool:RescueFix[MAXPLAYERS+1];
static bool:RoundStart[MAXPLAYERS+1];

static iHiddenOwner[2048+1] = {0, ...};
static iHiddenIndex[MAXPLAYERS+1] = {0, ...};
static bool:bThirdPerson[MAXPLAYERS+1] = {false, ...};
static iSavedModel[MAXPLAYERS+1] = {0, ...};
static iModelIndex[MAXPLAYERS+1] = {0, ...};

static Handle:hCvar_AdminOnlyModel = INVALID_HANDLE;
static bool:g_bAdminOnly = false;

static Handle:hCvar_AllowTank = INVALID_HANDLE;
static Handle:hCvar_AllowHunter = INVALID_HANDLE;
static Handle:hCvar_AllowSmoker = INVALID_HANDLE;
static Handle:hCvar_AllowBoomer = INVALID_HANDLE;
static Handle:hCvar_AllowSurvivors = INVALID_HANDLE;
static Handle:hCvar_AiChance = INVALID_HANDLE;
static Handle:hCvar_Aiteams = INVALID_HANDLE;
static Handle:hCvar_TankModel = INVALID_HANDLE;
static bool:g_bAllowTank = false;
static bool:g_bAllowHunter = false;
static bool:g_bAllowSmoker = false;
static bool:g_bAllowBoomer = false;
static bool:g_bAllowSurvivors = false;
static bool:g_bTankModel = false;
static g_iAiChance = 50;
static g_iAiteams = 2;

static Handle:hCvar_TPcheck = INVALID_HANDLE;
static Handle:hTimer_TPcheck = INVALID_HANDLE;
static Handle:hCvar_TPcheckFrequency = INVALID_HANDLE;
static Float:g_fTPcheckFrequency = 0.25;
static bool:g_bTPcheck = false;

static Handle:hCvar_AnnounceDelay = INVALID_HANDLE;
static Handle:hCvar_AnnounceMode = INVALID_HANDLE;
static Float:g_fAnnounceDelay = 7.0;
static g_iAnnounceMode = 3;

public Plugin:myinfo =
{
    name = "Left 4 Dead Model Changer",
    author = "Ludastar (Armonic)",
    description = "Left 4 Dead Model Changer for Survivors and Infected",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2449184#post2449184"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_lmc", ShowMenu, "Brings up a menu to select a client's model");
	
	CreateConVar("l4dmodelchanger_version", PLUGIN_VERSION, "Left 4 Dead Model Changer", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	hCvar_TPcheck = CreateConVar("lmc_tpcheck", "1", "Enable ThirdPersonShoulder checks, this is not perfect so there can be bugs its only basic support", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvar_TPcheckFrequency = CreateConVar("lmc_tpcheckfrequency", "0.25", "Frequency of checks for ThirdPersonShoulder cvar on clients, value will change on next map", FCVAR_PLUGIN, true, 0.1, true, 10.0);
	hCvar_AdminOnlyModel = CreateConVar("lmc_adminonly", "0", "Allow admins to only change models? (1 = true)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvar_AllowTank = CreateConVar("lmc_allowtank", "1", "Allow Tanks to have custom model? (1 = true)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvar_AllowHunter = CreateConVar("lmc_allowhunter", "1", "Allow Hunters to have custom model? (1 = true)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvar_AllowSmoker = CreateConVar("lmc_allowsmoker", "1", "Allow Smoker to have custom model? (1 = true)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvar_AllowBoomer = CreateConVar("lmc_allowboomer", "1", "Allow Boomer to have custom model? (1 = true)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvar_AllowSurvivors = CreateConVar("lmc_allowSurvivors", "1", "Allow Survivors to have custom model? (1 = true)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvar_AnnounceDelay = CreateConVar("lmc_announcedelay", "7.0", "Delay On which a message is displayed for !lmc command", FCVAR_PLUGIN, true, 1.0, true, 360.0);
	hCvar_AnnounceMode = CreateConVar("lmc_announcemode", "0", "Display Mode for !lmc command (0 = off, 1 = Print to chat, 2 = Center text, 3 = Director Hint)", FCVAR_PLUGIN, true, 0.0, true, 4.0);
	hCvar_AiChance = CreateConVar("lmc_ai_model_chance", "0", "(0 = disable custom models)chance on which the AI will get a custom model", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	hCvar_Aiteams = CreateConVar("lmc_ai_model_teams", "3", "Teams you wish to have custom models for AI (1 = Survivors only 2 = Infected Only 3 = Both teams)", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	hCvar_TankModel = CreateConVar("lmc_allow_tank_model_use", "1", "The tank model is big and don't look good on other models so i made it optional(1 = true)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	HookConVarChange(hCvar_TPcheck, eConvarChanged);
	HookConVarChange(hCvar_TPcheckFrequency, eConvarChanged);
	HookConVarChange(hCvar_AdminOnlyModel, eConvarChanged);
	HookConVarChange(hCvar_AllowTank, eConvarChanged);
	HookConVarChange(hCvar_AllowHunter, eConvarChanged);
	HookConVarChange(hCvar_AllowSmoker, eConvarChanged);
	HookConVarChange(hCvar_AllowBoomer, eConvarChanged);
	HookConVarChange(hCvar_AllowSurvivors, eConvarChanged);
	HookConVarChange(hCvar_AnnounceDelay, eConvarChanged);
	HookConVarChange(hCvar_AnnounceMode, eConvarChanged);
	HookConVarChange(hCvar_AiChance, eConvarChanged);
	HookConVarChange(hCvar_Aiteams, eConvarChanged);
	HookConVarChange(hCvar_TankModel, eConvarChanged);
	CvarsChanged();
	
	HookEvent("player_bot_replace", player_bot_replace); /*THIRDPERSON FIX*/
	HookEvent("survivor_rescued", survivor_rescued); /*THIRDPERSON FIX*/
	
	HookEvent("player_death", ePlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", ePlayerSpawn);
	HookEvent("player_team", eTeamChange);
	HookEvent("player_incapacitated", eSetColour);
	HookEvent("revive_end", eSetColour);
	HookEvent("round_end", eRoundEnd);
	HookEvent("round_start", eRoundStart);
	
	#if ENABLE_AUTOEXEC
	AutoExecConfig(true, "L4D2ModelChanger1.2");
	#endif
}

public OnMapStart()
{
	PrecacheModel(Witch_Normal, true);
	PrecacheModel(Infected_TankNorm, true);
	PrecacheModel(Infected_TankSac, true);
	PrecacheModel(Infected_Boomer, true);
	PrecacheModel(Infected_Hunter, true);
	PrecacheModel(Infected_Smoker, true);
	PrecacheModel(Infected_Common1, true);
	PrecacheModel(Infected_Common2, true);
	PrecacheModel(Infected_Common3, true);
	PrecacheModel(Infected_Common4, true);
	PrecacheModel(Infected_Common5, true);
	PrecacheModel(Infected_Common6, true);
	PrecacheModel(Infected_Common7, true);
	PrecacheModel(Infected_Common8, true);
	PrecacheModel(Infected_Common9, true);
	PrecacheModel(Infected_Common10, true);
	PrecacheModel(Infected_Common11, true);
	PrecacheModel(Infected_Common12, true);
	PrecacheModel(Infected_Common13, true);
	PrecacheModel(Infected_Common14, true);

	PrecacheModel(MODEL_BILL, true);
	PrecacheModel(MODEL_ZOEY, true);
	PrecacheModel(MODEL_FRANCIS, true);
	PrecacheModel(MODEL_LOUIS, true);
	PrecacheSound("ui/menu_countdown.wav", true);
	CvarsChanged();
	
	/*THIRDPERSON FIX*/
	for(new i = 1; i <= MaxClients; i++)
	{
		iModelIndex[i] = -1;
		AfkFix[i] = false;
		RescueFix[i] = false;
		RoundStart[i] = true;
	}
}

public eConvarChanged(Handle:hCvar, const String:sOldVal[], const String:sNewVal[])
{
	CvarsChanged();
}

CvarsChanged()
{
	g_bTPcheck = GetConVarInt(hCvar_TPcheck) > 0;
	g_fTPcheckFrequency = GetConVarFloat(hCvar_TPcheckFrequency);
	g_bAdminOnly = GetConVarInt(hCvar_AdminOnlyModel) > 0;
	g_bAllowTank = GetConVarInt(hCvar_AllowTank) > 0;
	g_bAllowHunter = GetConVarInt(hCvar_AllowHunter) > 0;
	g_bAllowSmoker = GetConVarInt(hCvar_AllowSmoker) > 0;
	g_bAllowBoomer = GetConVarInt(hCvar_AllowBoomer) > 0;
	g_bAllowSurvivors = GetConVarInt(hCvar_AllowSurvivors) > 0;
	g_iAiChance = GetConVarInt(hCvar_AiChance);
	g_iAiteams = GetConVarInt(hCvar_Aiteams);
	g_bTankModel = GetConVarInt(hCvar_TankModel) > 0;
	g_fAnnounceDelay = GetConVarFloat(hCvar_AnnounceDelay);
	g_iAnnounceMode = GetConVarInt(hCvar_AnnounceMode);
}

public eRoundStart(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	decl String:sGameMode[12];
	GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
	
	for(new i = 1;i <= MaxClients; i++)
		bThirdPerson[i] = false;
		
	if(!StrEqual(sGameMode, "versus", false))
	{
		if(g_bTPcheck)
			if(hTimer_TPcheck == INVALID_HANDLE)
				hTimer_TPcheck = CreateTimer(g_fTPcheckFrequency, ThirdPersonCheck, INVALID_HANDLE, TIMER_REPEAT);
	}
	else
	{
		if(hTimer_TPcheck != INVALID_HANDLE)
		{
			KillTimer(hTimer_TPcheck);
			hTimer_TPcheck = INVALID_HANDLE;
		}
	}
}
public eRoundEnd(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		bThirdPerson[i] = false;
		static iEntity;
		iEntity = iHiddenIndex[i];
		
		if(iEntity < 0 || iEntity > 2048+1 || !IsValidEntRef(iEntity))
		{
			iHiddenIndex[i] = -1;
			continue;
		}
		
		SetEntityRenderFx(i, RENDERFX_HOLOGRAM);
		SetEntityRenderColor(i, 0, 0, 0, 0);
		iHiddenIndex[i] = -1;
	}
	
	if(hTimer_TPcheck != INVALID_HANDLE)
	{
		KillTimer(hTimer_TPcheck);
		hTimer_TPcheck = INVALID_HANDLE;
	}
}
//heil timocop he done this before me
BeWitched(iClient, const String:sModel[])  
{  
	if(!IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
	
	new iEntity = iHiddenIndex[iClient];
	if(IsValidEntRef(iEntity))
	{
		AcceptEntityInput(iEntity, "kill");
	}
	
	iEntity = CreateEntityByName("prop_dynamic_ornament");
	if(iEntity < 0)
		return;
	
	DispatchKeyValue(iEntity, "model", sModel);
	
	DispatchSpawn(iEntity);
	ActivateEntity(iEntity);
	 
	SetVariantString("!activator");
	AcceptEntityInput(iEntity, "SetParent", iClient);
	 
	SetVariantString("!activator");
	AcceptEntityInput(iEntity, "SetAttached", iClient);
	AcceptEntityInput(iEntity, "TurnOn");
	
	if(!IsFakeClient(iClient))
		SDKHook(iEntity, SDKHook_SetTransmit, HideModel);
	
	iHiddenIndex[iClient] = EntIndexToEntRef(iEntity);
	iHiddenOwner[iEntity] = GetClientUserId(iClient);
}

public Action:HideModel(iEntity, iClient)
{
    if(!IsValidEntRef(iHiddenIndex[iClient]))
        return Plugin_Continue;
   
    static iOwner;
    iOwner = GetClientOfUserId(iHiddenOwner[iEntity]);
   
    if(iOwner < 1 || !IsClientInGame(iOwner))
        return Plugin_Continue;
   
    switch(GetClientTeam(iOwner)) {
        case 2: {
            if(iOwner != iClient)
                return Plugin_Continue;
           
            if(!IsSurvivorThirdPerson(iClient))
                return Plugin_Handled;
        }
        case 3: {
            static bool:bIsGhost;
            bIsGhost = GetEntProp(iOwner, Prop_Send, "m_isGhost", 1) > 0;
           
            if(iOwner != iClient) {
                //Hide model for everyone else when is ghost mode exapt me
                if(bIsGhost)
                    return Plugin_Handled;
            }
            else {
                // Hide my model when not in thirdperson
                if(bIsGhost)
                {
                    SetEntityRenderFx(iOwner, RENDERFX_HOLOGRAM);
                    SetEntityRenderColor(iOwner, 0, 0, 0, 0);
                }
                if(!IsInfectedThirdPerson(iOwner))
                return Plugin_Handled;
            }
        }
    }
   
    return Plugin_Continue;
}

public ePlayerDeath(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
		return;
	
	DeathFix[iClient] = true; /*THIRDPERSON FIX*/
	
	new iEntity = iHiddenIndex[iClient];
	
	if(!IsValidEntRef(iEntity))
		return;
	
	AcceptEntityInput(iEntity, "kill");
	iHiddenIndex[iClient] = -1;
}

public ePlayerSpawn(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
	
	new iEntity = iHiddenIndex[iClient];
	
	if(IsValidEntRef(iEntity))
	{
		AcceptEntityInput(iEntity, "kill");
		iHiddenIndex[iClient] = -1;
	}
	
	if(GetClientTeam(iClient) == 3)
	{
		switch(GetEntProp(iClient, Prop_Send, "m_zombieClass"))
		{
			case ZOMBIECLASS_SMOKER:
			{
				if(!g_bAllowSmoker)
					return;
			}
			case ZOMBIECLASS_BOOMER:
			{
				if(!g_bAllowBoomer)
					return;
			}
			case ZOMBIECLASS_HUNTER:
			{
				if(!g_bAllowHunter)
					return;
			}
			case 4: return;
			case ZOMBIECLASS_TANK:
			{
				if(!g_bAllowTank)
					return;
			}
		}
	}
	
	if(!IsFakeClient(iClient))
	{
		if(iSavedModel[iClient] == 0)
			return;
	
		ModelIndex(iClient, iSavedModel[iClient]);
		return;
	}
	
	if(GetRandomInt(1, 100) > g_iAiChance)
		return;
		
	switch(g_iAiteams)
	{
		case 1:
		{
			if(GetClientTeam(iClient) != 2)
				return;
		}
		case 2:
		{
			if(GetClientTeam(iClient) != 3)
				return;
		}
	}
	ModelIndex(iClient, GetRandomInt(2, 25));
}

public eSetColour(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
		return;
	
	new iEntity = iHiddenIndex[iClient];
	
	if(!IsValidEntRef(iEntity))
		return;
	
	SetEntityRenderFx(iClient, RENDERFX_HOLOGRAM);
	SetEntityRenderColor(iClient, 0, 0, 0, 0);
}

public eTeamChange(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
		return;
		
	new iEntity = iHiddenIndex[iClient];
	
	if(!IsValidEntRef(iEntity))
		return;
	
	AcceptEntityInput(iEntity, "kill");
	iHiddenIndex[iClient] = -1;
}

static bool:IsValidEntRef(iEntRef)
{
    static iEntity;
    iEntity = EntRefToEntIndex(iEntRef);
    return (iEntRef && iEntity != INVALID_ENT_REFERENCE && IsValidEntity(iEntity));
}

static bool:IsSurvivorThirdPerson(iClient) 
{
	if(bThirdPerson[iClient])
		return true;
	//if(GetEntPropFloat(iClient, Prop_Send, "m_TimeForceExternalView") > GetGameTime())
	//	return true; 
	//if(GetEntPropEnt(iClient, Prop_Send, "m_pummelAttacker") > 0)
	//	return true;
	//if(GetEntPropEnt(iClient, Prop_Send, "m_carryAttacker") > 0)
	//	return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	//if(GetEntPropEnt(iClient, Prop_Send, "m_jockeyAttacker") > 0)
	//	return true; 
	if(GetEntProp(iClient, Prop_Send, "m_isHangingFromLedge") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_reviveTarget") > 0)
		return true;  
	//if(GetEntPropFloat(iClient, Prop_Send, "m_staggerTimer", 1) > -1.0)
	//	return true; 
	/*switch(GetEntProp(iClient, Prop_Send, "m_iCurrentUseAction"))
	{
		case 1:
		{
			static iTarget;
			iTarget = GetEntPropEnt(iClient, Prop_Send, "m_useActionTarget");
			
			if(iTarget == GetEntPropEnt(iClient, Prop_Send, "m_useActionOwner"))
				return true;
			else if(iTarget != iClient)
				return true;
		}
		case 4, 5:
			return true;
	}*/
	
	static String:sModel[31];
	GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	
	switch(sModel[29])
	{
		case 'v'://bill
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 528, 759, 763, 764, 529, 530, 531, 532, 533, 534, 753:
					return true;
			}
		}
		case 'n'://zoey
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 537, 819, 823, 824, 538, 539, 540, 541, 542, 543, 813:
					return true;
			}
		}
		case 'e'://francis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 531, 762, 766, 767, 532, 533, 534, 535, 536, 537, 756:
					return true;
			}
		}
		case 'a'://louis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 528, 759, 763, 764, 529, 530, 531, 532, 533, 534, 753:
					return true;
			}
		}
	}
	
	return false;
}
static bool:IsInfectedThirdPerson(iClient) 
{
	if(bThirdPerson[iClient])
		return true;
	//if(GetEntPropFloat(iClient, Prop_Send, "m_TimeForceExternalView") > GetGameTime())
	//	return true; 
	//if(GetEntPropFloat(iClient, Prop_Send, "m_staggerTimer", 1) > -1.0)
	//	return true; 
	
	switch(GetEntProp(iClient, Prop_Send, "m_zombieClass"))
	{
		case 1://smoker
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 30, 31, 32, 36, 37, 38, 39: 
					return true;
			}
		}
		case 2://boomer
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 30, 31, 32, 33: 
					return true;
			}
		}
		case 3://hunter
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 38, 39, 40, 41, 42, 43, 45, 46, 47, 48, 49: 
					return true;
			}
		}
		case 5://tank
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 28, 29, 30, 31, 49, 50, 51, 73, 74, 75, 76 ,77: 
					return true;
			}
		}
	}
	
	return false;
}

public Action:ThirdPersonCheck(Handle:hTimer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		QueryClientConVar(i, "c_thirdpersonshoulder", QueryClientConVarCallback);
	}
}

public QueryClientConVarCallback(QueryCookie:cookie, iClient, ConVarQueryResult:result, const String:sCvarName[], const String:bCvarValue[])
{
/*THIRDPERSON FIX*/
	if (result != ConVarQuery_Okay) { bThirdPerson[iClient] = false; }
	else { bThirdPerson[iClient] = true; }

	if (!StrEqual(bCvarValue, "false") && !StrEqual(bCvarValue, "0")) //THIRDPERSONSHOULDER
	{
		if(RoundStart[iClient])
		{
			RoundStart[iClient] = false;
			bThirdPerson[iClient] = false;
		}
		else if(AfkFix[iClient]){ bThirdPerson[iClient] = false; }
		else if(DeathFix[iClient]) { bThirdPerson[iClient] = false; }
		else if(RescueFix[iClient]) { bThirdPerson[iClient] = false; }
		else { bThirdPerson[iClient] = true; }
	}
	else //FIRSTPERSON
	{
		if(RoundStart[iClient])
		{
			RoundStart[iClient] = false;
			bThirdPerson[iClient] = false;
		}
		AfkFix[iClient] = false;
		DeathFix[iClient] = false;
		RescueFix[iClient] = false;
		bThirdPerson[iClient] = false;
	}
/*THIRDPERSON FIX*/
}

public OnClientDisconnect(iClient)
{
	bThirdPerson[iClient] = false;
		
	new iEntity = iHiddenIndex[iClient];
	
	iHiddenIndex[iClient] = -1;
	iSavedModel[iClient] = 0;
	
	if(!IsValidEntRef(iEntity))
		return;
		
	AcceptEntityInput(iEntity, "kill");
	
}

/*borrowed some code from csm*/
public Action:ShowMenu(iClient, iArgs) 
{
	if(iClient == 0) 
	{
		ReplyToCommand(iClient, "[LMC] Menu is in-game only.");
		return Plugin_Continue;
	}
	if(!IsPlayerAlive(iClient)) 
	{
		ReplyToCommand(iClient, "\x04[LMC] \x03You must be alive to Change Model");
		return Plugin_Continue;
	}
	if(GetUserFlagBits(iClient) == 0 && g_bAdminOnly)
	{
		ReplyToCommand(iClient, "\x04[LMC] \x03Model Changer is only available to admins.");
		return Plugin_Continue;
	}
	
	new Handle:hMenu = CreateMenu(CharMenu);
	SetMenuTitle(hMenu, "Choose a Model");
	 
	AddMenuItem(hMenu, "1", "Normal Models");
	AddMenuItem(hMenu, "2", "Witch");
	AddMenuItem(hMenu, "3", "Tank");    
	AddMenuItem(hMenu, "4", "Tank DLC");
	AddMenuItem(hMenu, "5", "Boomer");
	AddMenuItem(hMenu, "6", "Hunter");
	AddMenuItem(hMenu, "7", "Smoker");
	AddMenuItem(hMenu, "8", "Random Common");
	AddMenuItem(hMenu, "9", "Bill");
	AddMenuItem(hMenu, "10", "Zoey");
	AddMenuItem(hMenu, "11", "Francis");
	AddMenuItem(hMenu, "12", "Louis");
	
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, iClient, 15);
	
	return Plugin_Continue;
}

public CharMenu(Handle:hMenu, MenuAction:action, param1, param2) 
{
	switch(action) 
	{
		case MenuAction_Select: 
		{
			decl String:sItem[4]; 
			GetMenuItem(hMenu, param2, sItem, sizeof(sItem));
			ModelIndex(param1, StringToInt(sItem));
			ShowMenu(param1, 0);
		}
		case MenuAction_Cancel:
		{
		    
		}
		case MenuAction_End: 
		{
			CloseHandle(hMenu);
		}
	}
}

static ModelIndex(iClient, iCaseNum)
{
	switch(GetClientTeam(iClient))
	{
		case 3:
		{
			switch(GetEntProp(iClient, Prop_Send, "m_zombieClass"))
			{
				case ZOMBIECLASS_SMOKER:
				{
					if(!g_bAllowSmoker)
					{
						if(!IsFakeClient(iClient))
							PrintToChat(iClient, "\x04[LMC] \x03Server Has Disabled Models for \x04Smoker");
						iSavedModel[iClient] = iCaseNum;
						return;
					}
				}
				case ZOMBIECLASS_BOOMER:
				{
					if(!g_bAllowBoomer)
					{
						if(!IsFakeClient(iClient))
							PrintToChat(iClient, "\x04[LMC] \x03Server Has Disabled Models for \x04Boomer");
						iSavedModel[iClient] = iCaseNum;
						return;
					}
				}
				case ZOMBIECLASS_HUNTER:
				{
					if(!g_bAllowHunter)
					{
						if(!IsFakeClient(iClient))
							PrintToChat(iClient, "\x04[LMC] \x03Server Has Disabled Models for \x04Hunter");
						iSavedModel[iClient] = iCaseNum;
						return;
					}
				}
				case ZOMBIECLASS_TANK:
				{
					if(!g_bAllowTank)
					{
						if(!IsFakeClient(iClient))
							PrintToChat(iClient, "\x04[LMC] \x03Server Has Disabled Models for \x04Tank");
						iSavedModel[iClient] = iCaseNum;
						return;
					}
				}
			}
		}
		case 2:
		{
			if(!g_bAllowSurvivors)
			{
				if(!IsFakeClient(iClient))
					PrintToChat(iClient, "\x04[LMC] \x03Server Has Disabled Models for \x04Survivors");
				iSavedModel[iClient] = iCaseNum;
				return;
			}
		}
	}
	switch(iCaseNum)
	{
		case 1: {
			SetEntityRenderColor(iClient, 255, 255, 255, 255);
			iSavedModel[iClient] = iCaseNum;
			
			if(!IsFakeClient(iClient))
				PrintToChat(iClient, "\x04[LMC] \x03Models will be default");
			
			new iEntity = iHiddenIndex[iClient];
			if(IsValidEntRef(iEntity))
			{
				AcceptEntityInput(iEntity, "kill");
				iHiddenIndex[iClient] = -1;
			}
			return;
		}
		case 2: {
			BeWitched(iClient, Witch_Normal); 
			if(!IsFakeClient(iClient))
				PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Witch");
		}
		case 3: {
			if(!g_bTankModel)
			{
				if(!IsFakeClient(iClient))
					PrintToChat(iClient, "\x04[LMC] \x03Tank Models are Disabled");
				return;
			}	
			BeWitched(iClient, Infected_TankNorm);
			if(!IsFakeClient(iClient))
				PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Tank");
		}
		case 4: {
			if(!g_bTankModel)
			{
				if(!IsFakeClient(iClient))
					PrintToChat(iClient, "\x04[LMC] \x03Tank Models are Disabled");
				return;
			}
			BeWitched(iClient, Infected_TankSac);
			if(!IsFakeClient(iClient))
				PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Tank DLC");
		}
		case 5: {
			BeWitched(iClient, Infected_Boomer);
			if(!IsFakeClient(iClient))
				PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Boomer");
		}
		case 6: {
			BeWitched(iClient, Infected_Hunter);
			if(!IsFakeClient(iClient))
				PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Hunter");
		}
		case 7: {
			BeWitched(iClient, Infected_Smoker);
			if(!IsFakeClient(iClient))
				PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Smoker");
		}
		case 8:
		{
			switch(GetRandomInt(1, 14))
			{
				case 1: BeWitched(iClient, Infected_Common1);
				case 2: BeWitched(iClient, Infected_Common2);
				case 3: BeWitched(iClient, Infected_Common3);
				case 4: BeWitched(iClient, Infected_Common4);
				case 5: BeWitched(iClient, Infected_Common5);
				case 6: BeWitched(iClient, Infected_Common6);
				case 7: BeWitched(iClient, Infected_Common7);
				case 8: BeWitched(iClient, Infected_Common8);
				case 9: BeWitched(iClient, Infected_Common9);
				case 10: BeWitched(iClient, Infected_Common10);
				case 11: BeWitched(iClient, Infected_Common11);
				case 12: BeWitched(iClient, Infected_Common12);
				case 13: BeWitched(iClient, Infected_Common13);
				case 14: BeWitched(iClient, Infected_Common14);
			}
			if(!IsFakeClient(iClient))
				PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Common Infected");
		}
		case 9: {
			BeWitched(iClient, MODEL_BILL);
			if(!IsFakeClient(iClient))
				PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Bill");
		}
		case 10: {
			BeWitched(iClient, MODEL_ZOEY);
			if(!IsFakeClient(iClient))
				PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Zoey");
		}
		case 11: {
			BeWitched(iClient, MODEL_FRANCIS);
			if(!IsFakeClient(iClient))
				PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Francis");
		}
		case 12: {
			BeWitched(iClient, MODEL_LOUIS);
			if(!IsFakeClient(iClient))
				PrintToChat(iClient, "\x04[LMC] \x03Model is \x04Louis");
		}
	}
	iSavedModel[iClient] = iCaseNum;
}

public OnClientPostAdminCheck(iClient)
{  
	if(IsFakeClient(iClient))
		return;
	
	if(g_iAnnounceMode != 0)
		CreateTimer(g_fAnnounceDelay, iClientInfo, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);   
}
 
public Action:iClientInfo(Handle:hTimer, any:iUserID)
{  
	new iClient = GetClientOfUserId(iUserID);
	
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
		return Plugin_Stop;
	
	switch(g_iAnnounceMode)
	{
		case 1:
		{
			PrintToChat(iClient, "\x04[LMC] \x03To Change Model use chat Command \x04!lmc\x03");
			EmitSoundToClient(iClient, "ui/menu_countdown.wav");
		}
		case 2: PrintHintText(iClient, "[LMC] To Change Model use chat Command !lmc");
		case 3:
		{
			new iEntity = CreateEntityByName("env_instructor_hint");
			
			decl String:sValues[64];
			sValues[0] = '\0';
			
			FormatEx(sValues, sizeof(sValues), "hint%d", iClient);
			DispatchKeyValue(iClient, "targetname", sValues);
			DispatchKeyValue(iEntity, "hint_target", sValues);
			
			Format(sValues, sizeof(sValues), "10");
			DispatchKeyValue(iEntity, "hint_timeout", sValues);
			DispatchKeyValue(iEntity, "hint_range", "0.1");
			DispatchKeyValue(iEntity, "hint_icon_onscreen", "icon_tip");
			DispatchKeyValue(iEntity, "hint_caption", "[LMC] To Change Model use chat Command !lmc");
			Format(sValues, sizeof(sValues), "%i %i %i", GetRandomInt(1, 255), GetRandomInt(100, 255), GetRandomInt(1, 255));
			DispatchKeyValue(iEntity, "hint_color", sValues);
			DispatchSpawn(iEntity);
			AcceptEntityInput(iEntity, "ShowHint");
			
			Format(sValues, sizeof(sValues), "OnUser1 !self:Kill::6:1");
			SetVariantString(sValues);
			AcceptEntityInput(iEntity, "AddOutput");
			AcceptEntityInput(iEntity, "FireUser1");
		}           
	}
	return Plugin_Stop;
}

/*THIRDPERSON FIX*/
public Action:survivor_rescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "victim"));
	RescueFix[iClient] = true;
}

public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	AfkFix[iClient] = true;
}
/*THIRDPERSON FIX*/

//malformed model fix for the real model changing and messing up stuff like invis explot with the menu
public OnGameFrame()
{
	static iFrameskip = 0;
	static iFrameskipColour = 0;
	iFrameskip = (iFrameskip + 1) % MAX_FRAMECHECK;
	
	if(iFrameskip != 0 || !IsServerProcessing())
		return;
	
	iFrameskipColour = (iFrameskipColour + 1) % 480;
	
	for(new i = 1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(!IsFakeClient(i) && iFrameskipColour != 0 && !IsValidEntRef(iHiddenIndex[i]))
		{
			static iColours[4];
			Entity_GetRenderColor(i, iColours);
			if(iColours[0] != 255 || iColours[1] != 255 || iColours[2] != 255 || iColours[3] != 0)
			{
				SetEntityRenderColor(i, 255, 255, 255, 255);
				continue;
			}
		}
		else if(iFrameskipColour != 0 && IsValidEntRef(iHiddenIndex[i]))
		{
			static iColours[4];
			Entity_GetRenderColor(i, iColours);
			if(iColours[0] != 0 || iColours[1] != 0 || iColours[2] != 0 || iColours[3] != 0)
				SetEntityRenderColor(i, 0, 0, 0, 0);
		}
		
		if(GetClientTeam(i) != 2)
			continue;
		
		if(iModelIndex[i] == GetEntProp(i, Prop_Data, "m_nModelIndex", 2))
			continue;
			
		iModelIndex[i] = GetEntProp(i, Prop_Data, "m_nModelIndex", 2);
		
		ModelIndex(i, iSavedModel[i]);
	}
}

static Entity_GetRenderColor(entity, color[4])
{
	static bool:gotconfig = false;
	static String:prop[32];

	if (!gotconfig) {
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_clrRender", prop, sizeof(prop));
		CloseHandle(gc);

		if (!exists) {
			strcopy(prop, sizeof(prop), "m_clrRender");
		}
		
		gotconfig = true;
	}

	new offset = GetEntSendPropOffs(entity, prop);

	if (offset <= 0) {
		ThrowError("SetEntityRenderColor not supported by this mod");
	}

	for (new i=0; i < 4; i++) {
		color[i] = GetEntData(entity, offset + i + 1, 1);
	}
}