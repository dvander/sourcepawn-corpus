#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>

public Plugin myinfo = 
{
	name = "[L4D2] Infected Attack Suppression Patch",
	author = "BHaType"
};
	
public void OnPluginStart()
{
	GameData data = new GameData("l4d2_infected_attack_suppresion_patch");
	
	MemoryPatch patch = MemoryPatch.CreateFromConf(data, "CBaseAbility::SetSupressionTimer");
	patch.Enable();
	
	delete data;
}