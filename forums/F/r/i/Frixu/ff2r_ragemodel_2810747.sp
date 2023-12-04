/*
	"rage_model"	// Ability name can use suffixes
	{
		"slot"								"0"														// Ability slot
		"duration"							"10.0"													// Ability duration
		"ragemodel"							"models\freak_fortress_2\testboss\test_ragemodel.mdl"	// Rage model path
		"use class anims on ragemodel"		"true"													// Should we use class animations on ragemodel?
		"defaultmodel"						"models\freak_fortress_2\testboss\test_model_02.mdl"	// Default model path									(Uses default boss model if Left Blank)
		"use class anims on defaultmodel"	"true"													// Should we use class animations on defaultmodel?		(Uses default boss class animations if left blank)
		
		"plugin_name"	"ff2r_ragemodel"
	}
	
	// Unlimited argument count, if ability activated more than argument count; keeps the last model
	"phase_model"	// Ability name can use suffixes
	{
		"slot"							"-1"																// Ability slot
		"phase1 model"					"models\freak_fortress_2\testboss\test_angrymodel_01.mdl"			// Phase one model path
		"use class anims on phase1"		"true"																// Should we use class animations on phase1?
		"phase2 model"					"models\freak_fortress_2\testboss\test_angrymodel_01.mdl"			// Phase two model path
		"use class anims on phase2"		"true"																// Should we use class animations on phase2?
		"phase3 model"					"models\freak_fortress_2\testboss\test_superangrymodel_01.mdl"		// Phase three model path
		"use class anims on phase3"		"true"																// Should we use class animations on phase3?
		"phase4 model"					"models\freak_fortress_2\testboss\test_superangrymodel_02.mdl"		// Phase four model path
		"use class anims on phase4"		"true"																// Should we use class animations on phase4?
		"phaseX model"					""																				
		"use class anims on phaseX"		""
		
		"plugin_name"	"ff2r_ragemodel"
	}
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cfgmap>
#include <ff2r>
#include <tf2_stocks>
#include <tf2items>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME 	"Freak Fortress 2 Rewrite: Rage Model"
#define PLUGIN_AUTHOR 	"J0BL3SS"
#define PLUGIN_DESC 	"Subplugin to change boss's model"

#define MAJOR_REVISION 	"1"
#define MINOR_REVISION 	"0"
#define STABLE_REVISION "0"
#define PLUGIN_VERSION 	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PLUGIN_URL ""

#define MAXTF2PLAYERS	36

int ModelCount[MAXTF2PLAYERS] = { 0, 0, 0, ...};
Handle ModelTimer[MAXTF2PLAYERS];

public Plugin myinfo = 
{
	name 		= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESC,
	version 	= PLUGIN_VERSION,
	url			= PLUGIN_URL,
};

public void OnPluginEnd()
{
	for(int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
	{
		ModelTimer[clientIdx] = null;
		ModelCount[clientIdx] = 0;
	}
}

public void OnPluginStart()
{	
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{	
	int clientIdx = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(clientIdx))
		return;
	
	FF2R_OnBossRemoved(clientIdx);
}

public void FF2R_OnBossRemoved(int clientIdx)
{
	ModelCount[clientIdx] = 0;
	ModelTimer[clientIdx] = null;
}

public void FF2R_OnAbility(int clientIdx, const char[] ability, AbilityData cfg)
{
	if(!cfg.IsMyPlugin())	// Incase of duplicated ability names
		return;
	
	if(!cfg.GetBool("enabled", true))	// hidden/internal bool for abilities
		return;
	
	if(!StrContains(ability, "rage_model", false))
	{
		Rage_ChangeModel(clientIdx, ability, cfg);
	}
	if(!StrContains(ability, "phase_model", false))
	{
		Rage_PhaseModel(clientIdx, ability, cfg);
	}
}

public void Rage_PhaseModel(int clientIdx, const char[] ability, AbilityData cfg)
{
	ModelCount[clientIdx]++;
	char buffer[256], model[PLATFORM_MAX_PATH];
	
	Format(buffer, sizeof(buffer), "phase%i model", ModelCount[clientIdx]);
	
	if(cfg.GetString(buffer, model, sizeof(model)))
	{
		Format(buffer, sizeof(buffer), "use class anims on phase%i", ModelCount[clientIdx]);
		ApplyModel(clientIdx, model, cfg.GetBool(buffer, true));
	}
}

public void Rage_ChangeModel(int clientIdx, const char[] ability, AbilityData cfg)
{
	char buffer[256];
	if(cfg.GetString("ragemodel", buffer, sizeof(buffer)))
	{
		ApplyModel(clientIdx, buffer, cfg.GetBool("use class anims on ragemodel", true));
		
		DataPack pack;
		ModelTimer[clientIdx] = CreateDataTimer(cfg.GetFloat("duration"), Timer_ChangeModel, pack);
		pack.WriteCell(GetClientUserId(clientIdx));
		pack.WriteString(ability);
	}
}

public Action Timer_ChangeModel(Handle timer, DataPack pack)
{
	pack.Reset();
	int clientIdx = GetClientOfUserId(pack.ReadCell());

	if(!clientIdx)
		return Plugin_Handled;
	
	char buffer[256];
	pack.ReadString(buffer, sizeof(buffer));
	
	BossData boss = FF2R_GetBossData(clientIdx);
	if(!boss)
		return Plugin_Handled;
		
	AbilityData ability = boss.GetAbility(buffer);
	if(!ability.IsMyPlugin())
		return Plugin_Handled;
	
	if(ability.GetString("defaultmodel", buffer, sizeof(buffer)))
	{
		ApplyModel(clientIdx, buffer, ability.GetBool("use class anims on defaultmodel"));
	}
	else
	{
		if(boss.GetString("model", buffer, sizeof(buffer)))
		{
			ApplyModel(clientIdx, buffer, true);	
		}
		else
		{
			boss.GetString("class", buffer, sizeof(buffer));
			Format(buffer, sizeof(buffer), "models/player/%s.mdl", buffer);
			ApplyModel(clientIdx, buffer, true);
		}
	}
	
	ModelTimer[clientIdx] = null;
	return Plugin_Continue;
}

public void ApplyModel(int clientIdx, const char[] model, bool useClassAnims)
{
	SetVariantString(model);
	AcceptEntityInput(clientIdx, "SetCustomModel");
	
	if(useClassAnims)
		SetEntProp(clientIdx, Prop_Send, "m_bUseClassAnimations", 1);
}

stock bool IsValidClient(int clientIdx, bool replaycheck=true)
{
	if(clientIdx <= 0 || clientIdx > MaxClients)
		return false;

	if(!IsClientInGame(clientIdx) || !IsClientConnected(clientIdx))
		return false;

	if(GetEntProp(clientIdx, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck && (IsClientSourceTV(clientIdx) || IsClientReplay(clientIdx)))
		return false;

	return true;
}