#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.3"
#pragma semicolon 1

new bool:CSS = false;
new bool:CSGO = false;

new Handle:hImposter;
new bool:ImposterEnabled;

public Plugin:myinfo =
{
	name = "[CSGO/CSS] AbNeR Imposter",
	author = "Meng & AbNeR_CSS",
	description = "Rob the skin of another player killing him at knife",
	version = PLUGIN_VERSION,
	url = "www.tecnohardclan.com"
};


public OnPluginStart()
{
	CreateConVar("abner_imposter_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	hImposter = CreateConVar("sm_imposter", "1", "Enable/Disable the imposter.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	ImposterEnabled = GetConVarBool(hImposter);
	
	decl String:theFolder[40];
	GetGameFolderName(theFolder, sizeof(theFolder));
	
	if(StrEqual(theFolder, "cstrike"))
	{
		CSS = true;
	}
	else if(StrEqual(theFolder, "csgo"))
	{
		CSGO = true;
	}
	
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Pre);
	HookConVarChange(hImposter, ImposterChange);
	
}

public ImposterChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	ImposterEnabled = GetConVarBool(hImposter);
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		
	decl String:sWeapon[32];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
	
	if (!ImposterEnabled || StrContains(sWeapon, "knife", false) == -1)
	{
		return;
	}
	
	if ((attacker == 0) || (GetClientTeam(attacker) == GetClientTeam(victim)) || (!IsPlayerAlive(attacker)))
	{
		return;
	}
	
	new String:attackername[MAX_NAME_LENGTH];
	new String:victimname[MAX_NAME_LENGTH];
	
	GetClientName(attacker, attackername, sizeof(attackername));
	GetClientName(victim, victimname, sizeof(victimname));
	
	decl String:sVictimModel[64];
	GetClientModel(victim, sVictimModel, sizeof(sVictimModel));
	SetEntityModel(attacker, sVictimModel);
	
	if (CSGO)
	{
		PrintToChatAll("\x01*\x05%s \x01killed \x06%s\x01 with knife and turned an impostor", attackername, victimname);
	}
	else if (CSS)
	{
		PrintToChatAll("\x01\x03%s \x01killed \x05%s\x01 with knife and turned an impostor", attackername, victimname);
	}
	
	if (GetEntProp(attacker, Prop_Send,"m_bHasDefuser") == 1)
	{
		SetEntProp(attacker, Prop_Send, "m_bHasDefuser", 0);
		CreateTimer(0.5, SetDefuser, any:attacker);
	}
	
}

public Action:SetDefuser(Handle:timer, any:attacker)
{
		if(IsClientInGame(attacker) && GetClientTeam(attacker) != 1 && IsPlayerAlive(attacker))
		{
			SetEntProp(attacker, Prop_Send, "m_bHasDefuser", 1);
		}
}









