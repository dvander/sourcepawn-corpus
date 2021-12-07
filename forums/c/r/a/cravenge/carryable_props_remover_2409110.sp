#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new Handle:hCPRGasCans;
new Handle:hCPROxygenTanks;
new Handle:hCPRFireCrackers;
new Handle:hCPRPropaneTanks;

new bool:bRemovePropaneTanks;
new bool:bRemoveFireCrackers;
new bool:bRemoveGasCans;
new bool:bRemoveOxygenTanks;

public Plugin:myinfo =
{
	name = "[L4D2] Carryable Props Remover",
	author = "cravenge",
	description = "Removes Carryable Props Like Gas Cans, Propane Tanks, Oxygen Tanks, and Fire Crackers.",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	CreateConVar("carryable_props_remover_version", PLUGIN_VERSION, "Carryable Props Remover Version", FCVAR_NOTIFY|FCVAR_REPLICATED);
	hCPRGasCans = CreateConVar("carryable_gascans_remover", "0", "Enable/Disable Removal Of Carryable Gas Cans", FCVAR_NOTIFY);
	hCPRPropaneTanks = CreateConVar("carryable_propanetanks_remover", "1", "Enable/Disable Removal Of Carryable Propane Tanks", FCVAR_NOTIFY);
	hCPROxygenTanks = CreateConVar("carryable_oxygentanks_remover", "1", "Enable/Disable Removal Of Carryable Oxygen Tanks", FCVAR_NOTIFY);
	hCPRFireCrackers = CreateConVar("carryable_fireworks_remover", "0", "Enable/Disable Removal Of Carryable Fire Crackers", FCVAR_NOTIFY);
	
	bRemoveGasCans = GetConVarBool(hCPRGasCans);
	bRemovePropaneTanks = GetConVarBool(hCPRPropaneTanks);
	bRemoveOxygenTanks = GetConVarBool(hCPROxygenTanks);
	bRemoveFireCrackers = GetConVarBool(hCPRFireCrackers);
	
	HookEvent("round_start", OnRoundStart);
	
    HookConVarChange(hCPRGasCans, OnBooleansChange);
    HookConVarChange(hCPRPropaneTanks, OnBooleansChange);
    HookConVarChange(hCPROxygenTanks, OnBooleansChange);
    HookConVarChange(hCPRFireCrackers, OnBooleansChange);
}

public OnBooleansChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	bRemoveGasCans = GetConVarBool(hCPRGasCans);
	bRemovePropaneTanks = GetConVarBool(hCPRPropaneTanks);
	bRemoveOxygenTanks = GetConVarBool(hCPROxygenTanks);
	bRemoveFireCrackers = GetConVarBool(hCPRFireCrackers);
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	CreateTimer(1.0, StartRemovingCP);
}

public Action:StartRemovingCP(Handle:timer) 
{
	new cpEntity = FindEntityByClassname(cpEntity, "prop_physics");
	if (cpEntity == -1 || !IsValidEntity(cpEntity) || !IsValidEdict(cpEntity))
	{
		return Plugin_Stop;
	}
	
	if(AreCarryable(cpEntity))
	{
		AcceptEntityInput(cpEntity, "Kill");
	}
	
	return Plugin_Stop;
}

AreCarryable(prop)
{
	decl String:pModel[128];
	GetEntPropString(prop, Prop_Data, "m_ModelName", pModel, sizeof(pModel));
	if (bRemoveGasCans && StrEqual(pModel, "models/props_junk/gascan001a.mdl", false))
	{
		return true;
	}
	
	if (bRemovePropaneTanks && StrEqual(pModel, "models/props_junk/propanecanister001a.mdl", false))
	{
		return true;
	}
	
	if (bRemoveOxygenTanks && StrEqual(pModel, "models/props_equipment/oxygentank01.mdl", false))
	{
		return true;
	}
	
	if (bRemoveFireCrackers && StrEqual(pModel, "models/props_junk/explosive_box001.mdl", false))
	{
		return true;
	}
	
    return false;
}

