#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>

Handle  g_hFriendlyFire;
bool g_bFriendlyFireEnable;
bool g_bInTaunt[MAXPLAYERS+1];

public void OnEntityCreated(int ent, const char[] ClassName) 
{
	if(!StrEqual(ClassName, "instanced_scripted_scene", false))
		return;

	SDKHook(ent, SDKHook_SpawnPost, Hook_SpawnTaunt);
}

public void OnClientPostAdminCheck(int client)
{
	g_bInTaunt[client] = false;
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if(condition == TFCond_Taunting)
		g_bInTaunt[client] = false;
}

public void OnPluginStart()
{
	g_hFriendlyFire = CreateConVar("sm_nk_friendlyfire_damage", "1", "Neck crack damage for teammates", _, true, 0.0, true, 1.0);
	g_bFriendlyFireEnable = GetConVarBool(g_hFriendlyFire);
	HookConVarChange(g_hFriendlyFire, OnFriendlyFireUpdated);
}

public void OnFriendlyFireUpdated(ConVar hCvar, const char[] szOldValue, const char[] szNewValue) 
{
	g_bFriendlyFireEnable = GetConVarBool(g_hFriendlyFire);
}

public void Hook_SpawnTaunt(int ent)
{
	char SceneFile[PLATFORM_MAX_PATH];
	GetEntPropString(ent, Prop_Data, "m_iszSceneFile", SceneFile, sizeof(SceneFile));

	if(!StrEqual(SceneFile, "scenes/workshop/player/soldier/low/taunt_neck_snap_initiator.vcd"))
		return;

	int owner = GetEntPropEnt(ent, Prop_Data, "m_hOwner");

	if(!IsClientValid(owner))
		return;
	
	int partner = GetEntPropEnt(owner, Prop_Send, "m_hHighFivePartner");

	if(!IsClientValid(partner))
		return;

	g_bInTaunt[owner] = true;
	g_bInTaunt[partner] = true;

	DataPack Pack;
	CreateDataTimer(2.9, Timer_Crack, Pack, TIMER_FLAG_NO_MAPCHANGE);
	Pack.WriteCell(GetClientUserId(owner));
	Pack.WriteCell(GetClientUserId(partner));
}

public Action Timer_Crack(Handle timer, Handle PackPack)
{
	DataPack Pack = view_as<DataPack>(PackPack);
	Pack.Reset();
	int owner = GetClientOfUserId(ReadPackCell(Pack));
	int partner = GetClientOfUserId(ReadPackCell(Pack));

	if(!IsClientValid(owner) || !IsClientValid(owner))
		return Plugin_Stop;

	if(!IsPlayerAlive(owner) || !IsPlayerAlive(owner))
		return Plugin_Stop;

	if(TF2_GetClientTeam(owner) == TF2_GetClientTeam(partner) && !g_bFriendlyFireEnable)
		return Plugin_Stop;

	int weapon = GetPlayerWeaponSlot(owner, 2);

	if(weapon != -1)
		SetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon", weapon); 

	if(g_bInTaunt[owner] && g_bInTaunt[partner])
		SDKHooks_TakeDamage(partner, owner, owner, 850.0, 128, weapon);

	return Plugin_Continue;
}

stock bool IsClientValid(int client)
{
	if (0 < client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}

//Lengz37: scenes/workshop/player/pyro/low/taunt_neck_snap.vcd
//Mr_panica : scenes/workshop/player/soldier/low/taunt_neck_snap_initiator.vcd
