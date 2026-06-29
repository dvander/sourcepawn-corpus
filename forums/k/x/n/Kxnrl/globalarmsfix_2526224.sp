#include <sdktools>

#pragma newdecls required

public Plugin myinfo =
{
	name		= "Global Arms Fix",
	author		= "Kyle",
	description	= "",
	version		= "1.0",
	url			= "https://forums.alliedmods.net/showthread.php?t=276677&page=119"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

public void OnConfigsExecuted()  
{
	PrecacheModel("models/player/custom_player/legacy/tm_anarchist.mdl");
	PrecacheModel("models/player/custom_player/legacy/tm_pirate.mdl");
	PrecacheModel("models/player/custom_player/legacy/ctm_gign.mdl");
	PrecacheModel("models/player/custom_player/legacy/ctm_fbi.mdl");

	PrecacheModel("models/weapons/t_arms.mdl");
	PrecacheModel("models/weapons/ct_arms.mdl");
}

public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast) 
{ 
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// Set default
	SetDefaultSkin(client);

	// Fix spawn without any weapon.
	RequestFrame(Frame_SpawnPost, client);
}

void Frame_SpawnPost(int client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	// Check Weapon.
	if(HasClientWeapon(client))
		return;

	float fDelay = 0.2;
	Handle cvar = FindConVar("sm_store_playerskin_delay");
	if(cvar != INVALID_HANDLE)
		fDelay = GetConVarFloat(cvar)+0.2;
	
	int decoy = GivePlayerItem(client, "weapon_decoy");
	if(decoy != -1)
		CreateTimer(fDelay, Timer_DecoyDelay, EntIndexToEntRef(decoy));
}

public Action Timer_DecoyDelay(Handle timer, int iRef)
{ 
	int decoy = EntRefToEntIndex(iRef);

	if(!IsValidEdict(decoy))
		return Plugin_Stop;

	int owner = GetEntPropEnt(decoy, Prop_Send, "m_hOwnerEntity");

	if(owner > 0 && owner <= MaxClients && IsClientInGame(owner) && IsPlayerAlive(owner))
		RemovePlayerItem(owner, decoy);

	AcceptEntityInput(decoy, "Kill");

	return Plugin_Stop;
}

void SetDefaultSkin(int client)
{
	char m_szModel[128];
	GetEntPropString(client, Prop_Data, "m_ModelName", m_szModel, 128);

	if(GetClientTeam(client) == 2)
	{
		SetEntityModel(client, (StrContains(m_szModel, "tm_anarchist") != -1 || StrContains(m_szModel, "tm_phoenix") != -1) ? "models/player/custom_player/legacy/tm_pirate.mdl" : "models/player/custom_player/legacy/tm_anarchist.mdl");
		SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/t_arms.mdl");
	}
	else
	{
		SetEntityModel(client, (StrContains(m_szModel, "ctm_fbi") != -1 || StrContains(m_szModel, "ctm_sas") != -1 || StrContains(m_szModel, "ctm_swat") != -1) ? "models/player/custom_player/legacy/ctm_gign.mdl" : "models/player/custom_player/legacy/ctm_fbi.mdl");
		SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/ct_arms.mdl");
	}
}

bool HasClientWeapon(int client)
{
	int weapon;
	for(int slot = 0; slot <= 4; ++slot)
	{
		weapon = GetPlayerWeaponSlot(client, slot);
		if(IsValidEdict(weapon))
			return true;
	}

	return false;
}