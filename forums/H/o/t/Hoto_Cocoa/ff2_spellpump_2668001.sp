#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#undef REQUIRE_PLUGIN
#tryinclude <ff2_dynamic_defaults>
#define REQUIRE_PLUGIN

public Plugin myinfo = {
	name	= "Freak Fortress 2: SpellPumpkin",
	author	= "Hoto Cocoa, Orginal code by Deathrus",
	version = "1.0"
};


int BossTeam = view_as<int>(TFTeam_Blue);


/* Ability_Management_System */
bool Pump_TriggerAMS[MAXPLAYERS+1];

public void OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_Post);
	
	if(FF2_GetRoundState()==1)	// Late-load
	{
		HookAbilities();
	}
}

public void Event_RoundStart(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	BossTeam = FF2_GetBossTeam();
	
	int iBoss;
	for(int iIndex = 0; (iBoss=GetClientOfUserId(FF2_GetBossUserId(iIndex)))>0; iIndex++)
	{
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_pump"))
		{
			Pump_TriggerAMS[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_pump", 1) == 1; // If true, this will trigger AMS_InitSubability.
			if(Pump_TriggerAMS[iBoss])
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_pump", "PUMP"); // Important function to tell AMS that this subplugin supports it
			}
		}
		
	}
}

public void Event_RoundEnd(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		Pump_TriggerAMS[iClient] = false;
		
	}
}

public void HookAbilities()
{
	for(int iClient=1; iClient <= MaxClients; iClient++)
	{
		if(!IsValidClient(iClient))
			return;
		
		Pump_TriggerAMS[iClient] = false;
		
		int iIndex = FF2_GetBossIndex(iClient);
		if(iIndex>=0)
		{
			if(FF2_HasAbility(iIndex, this_plugin_name, "rage_pump"))
			{
				Pump_TriggerAMS[iClient] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_pump", 1) == 1; // If true, this will trigger AMS_InitSubability.
				if(Pump_TriggerAMS[iClient])
				{
					AMS_InitSubability(iIndex, iClient, this_plugin_name, "rage_pump", "PUMP"); // Important function to tell AMS that this subplugin supports it
				}
			}
		
		}
	}
}

public void FF2_OnAbility2(int iBoss, const char[] pluginName, const char[] abilityName, int iStatus)
{
	int iClient = GetClientOfUserId(FF2_GetBossUserId(iBoss));
	if (!strcmp(abilityName, "rage_pump"))
		Rage_Pump(iClient);
}


public bool PUMP_CanInvoke(int iClient)
{
	return true;
}

void Rage_Pump(int iClient)
{
	if(Pump_TriggerAMS[iClient]) // Prevent normal 100% RAGE activation if using AMS
		return;
	
	PUMP_Invoke(iClient);
}

public void PUMP_Invoke(int iClient)
{
	ShootProjectile(iClient, "tf_projectile_spellpumpkin");
}

int ShootProjectile(int iClient, char strEntname[48] = "")
{
	float flAng[3]; // original
	float flPos[3]; // original
	GetClientEyeAngles(iClient, flAng);
	GetClientEyePosition(iClient, flPos);
	
	int iTeam = GetClientTeam(iClient);
	int iSpell = CreateEntityByName(strEntname);
	
	if(!IsValidEntity(iSpell))
		return -1;
	
	float flVel1[3];
	float flVel2[3];
	
	GetAngleVectors(flAng, flVel2, NULL_VECTOR, NULL_VECTOR);
	
	flVel1[0] = flVel2[0]*1100.0; //Speed of a tf2 rocket.
	flVel1[1] = flVel2[1]*1100.0;
	flVel1[2] = flVel2[2]*1100.0;
	
	SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", iClient);
	SetEntProp(iSpell, Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
	SetEntProp(iSpell, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iSpell, Prop_Send, "m_nSkin", (iTeam-2));
	
	TeleportEntity(iSpell, flPos, flAng, NULL_VECTOR);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0); 
	
	DispatchSpawn(iSpell);
	TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, flVel1);
	
	return iSpell;
}



stock bool IsValidClient(int iClient, bool bAlive = false, bool bTeam = false)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;

	if(IsClientSourceTV(iClient) || IsClientReplay(iClient))
		return false;
	
	if(bAlive && !IsPlayerAlive(iClient))
		return false;
	
	if(bTeam && GetClientTeam(iClient) != BossTeam)
		return false;

	return true;
}

// call AMS from epic scout's subplugin via reflection:
stock Handle FindPlugin(char[] plugin_name)
{
	char buffer[256];
	char path[PLATFORM_MAX_PATH];
	Handle iter = GetPluginIterator();
	Handle pl = INVALID_HANDLE;
	
	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		Format(path, sizeof(path), "%s.ff2", plugin_name);
		GetPluginFilename(pl, buffer, sizeof(buffer));
		if (StrContains(buffer, path, false) >= 0)
			break;
		else
			pl = INVALID_HANDLE;
	}
	
	delete iter;

	return pl;
}

// this will tell AMS that the abilities listed on PrepareAbilities() supports AMS
stock void AMS_InitSubability(int iBoss, int iClient, const char[] plugin_name, const char[] ability_name, const char[] prefix)
{
	Handle plugin = FindPlugin("ff2_sarysapub3");
	if (plugin != INVALID_HANDLE)
	{
		Function func = GetFunctionByName(plugin, "AMS_InitSubability");
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(plugin, func);
			Call_PushCell(iBoss);
			Call_PushCell(iClient);
			Call_PushString(plugin_name);
			Call_PushString(ability_name);
			Call_PushString(prefix);
			Call_Finish();
		}
		else
			LogError("ERROR: Unable to initialize ff2_sarysapub3:AMS_InitSubability()");
	}
	else
		LogError("ERROR: Unable to initialize ff2_sarysapub3:AMS_InitSubability(). Make sure this plugin exists!");

}