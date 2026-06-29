#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

public Plugin myinfo =
{
	name = "MvM Vaccinator Fix",
	author = "Flowaria",
	description = "Fix the nesty Vaccinator hose bug",
	version = "1.0",
	url = "http://steamcommunity.com/id/flowaria/"
};

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "tf_wearable", false))
	{
		SDKHook(entity, SDKHook_SpawnPost, CheckVaccinatorBackpack);
	}
}

public CheckVaccinatorBackpack(int entity)
{
	if(!IsValidEdict(entity))
		return;
	
	if(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == 65535)
	{
		//Hide : Alternative to 'Disable' Input because it's breaks red med's hose bone
		//Also, without hiding, it will cause hose's flicker appearence
		SetEntProp(entity, Prop_Send, "m_fEffects", 32 );
		CreateTimer(0.0, VaccTimer, entity); //tf_wearable entity need check delay until Client equip it
	}
	SDKUnhook(entity, SDKHook_SpawnPost, CheckVaccinatorBackpack);
}

public Action VaccTimer(Handle timer, any entity)
{
	if(!IsValidEdict(entity))
		return;

	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(1 <= client <= MaxClients)
	{
		if(GetClientTeam(client) == _:TFTeam_Blue && TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			char model[128];
			GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
			if(StrEqual(model, "models/weapons/c_models/c_medigun_defense/c_medigun_defensepack.mdl", false))
			{
				RemoveEdict(entity);
			}
		}
		else
		{
			SetEntProp(entity, Prop_Send, "m_fEffects", 1); //Unhide
		}
	}
}