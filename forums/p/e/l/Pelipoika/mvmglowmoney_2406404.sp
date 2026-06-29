#include <sdkhooks>
#include <tf2_stocks>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[TF2] Glowing MvM money",
	author = "Pelipoika",
	description = "Makes money glow through walls in mvm",
	version = "1.0",
	url = "http://www.sourcemod.net/plugins.php?author=Pelipoika&search=1"
};

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "item_currencypack_custom"))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnMoneySpawn);
	}
}

public Action OnMoneySpawn(int entity)
{
	if(GetEntProp(entity, Prop_Send, "m_bDistributed") == 0)
	{
		char strModel[PLATFORM_MAX_PATH];
		GetEntPropString(entity, Prop_Data, "m_ModelName", strModel, PLATFORM_MAX_PATH);
		if(!StrEqual(strModel, ""))
		{
			int ent = CreateEntityByName("tf_taunt_prop");
			DispatchKeyValue(ent, "targetname", "MoneyESP");
			DispatchSpawn(ent);
			
			SetEntityModel(ent, strModel);
			
			SetEntPropEnt(ent, Prop_Data, "m_hEffectEntity", entity);
			SetEntProp(ent, Prop_Send, "m_bGlowEnabled", 1);
			
			int iFlags = GetEntityFlags(entity);
			int iEffects = GetEntProp(ent, Prop_Send, "m_fEffects");
			SetEntProp(ent, Prop_Send, "m_fEffects", iEffects|1|16|8);
			SetEntityFlags(entity, iFlags | FL_EDICT_ALWAYS);
			
			SetVariantString("!activator");
			AcceptEntityInput(ent, "SetParent", entity);
			
			SDKHook(ent, SDKHook_SetTransmit, Hook_MoneyTransmit);
		}
	}
}

public Action Hook_MoneyTransmit(int ent, int other)
{
	if(other > 0 && other <= MaxClients && IsClientInGame(other))
	{
		int iMoney = GetEntPropEnt(ent, Prop_Data, "m_hEffectEntity");
		if(IsValidEntity(iMoney))
		{
			int iclrRender = GetEntProp(iMoney, Prop_Send, "m_clrRender");
			if(iclrRender == -1)
			{
				return Plugin_Continue;
			}
		}
	}

	return Plugin_Handled;
}