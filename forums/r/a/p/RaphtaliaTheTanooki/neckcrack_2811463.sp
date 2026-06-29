#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>

Handle g_hFriendlyFire;
Handle g_bTauntKill;
bool g_bFriendlyFireEnable;
bool g_bTauntKillEnabled;

public void OnEntityCreated(int ent, const char[] sClassName) {

	if(!StrEqual(sClassName, "instanced_scripted_scene", false))
		return;
	SDKHook(ent, SDKHook_SpawnPost, Hook_SpawnTaunt);
}

public void OnPluginStart()
{
	g_hFriendlyFire = CreateConVar("sm_nk_friendlyfire_bypass", "1", "Bypass friendlyfire check for allies (kills them even if friendlyfire = 0", _, true, 0.0, true, 1.0);
	g_bTauntKill = CreateConVar("sm_nk_tauntkill", "1", "Enables taunt killing with the taunt", _, true, 0.0, true, 1.0);
	g_bFriendlyFireEnable = GetConVarBool(g_hFriendlyFire);
	
	HookConVarChange(g_hFriendlyFire, OnFriendlyFireUpdated);
	HookConVarChange(g_bTauntKill, OnTauntKillUpdated);
}

public void OnFriendlyFireUpdated(ConVar hCvar, const char[] szOldValue, const char[] szNewValue) 
{
	g_bFriendlyFireEnable = GetConVarBool(g_hFriendlyFire);
}

public void OnTauntKillUpdated(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	g_bTauntKillEnabled = GetConVarBool(g_bTauntKill)
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
	
	g_bTauntKillEnabled = GetConVarBool(g_bTauntKill);
	if(!g_bTauntKillEnabled)	{
		//PrintToChatAll("[DEBUG]: TauntKillEnabled é false");
		return Plugin_Stop;
		}

	if(!IsClientValid(owner) || !IsClientValid(partner))	{
		//PrintToChatAll("[DEBUG]: owner e partner não são válidos");
		return Plugin_Stop;
	}

	if(!IsPlayerAlive(owner) || !IsPlayerAlive(partner))	{
		//PrintToChatAll("[DEBUG]: owner ou partner não está vivo");
		return Plugin_Stop;
		}

	/*if(TF2_GetClientTeam(owner) == TF2_GetClientTeam(partner)) pretty useless now
		return Plugin_Stop;*/

	int weapon = GetPlayerWeaponSlot(owner, 2);
	//PrintToChatAll("[DEBUG]: Arma tem ID: %d", weapon);
	
	int owner_team = GetEntProp(owner, Prop_Send, "m_iTeamNum");
	int partner_team = GetEntProp(partner, Prop_Send, "m_iTeamNum");

	if(weapon != -1)
		SetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon", weapon); 

	//int OwnerIndex = GetEntProp(owner, Prop_Send, "m_nSequence"); this is inconsistent, makes taunt work only sometimes
	//int OwnerIndex = 150;
	//PrintToChatAll("[DEBUG]: SequenceID do Owner: %d", OwnerIndex); 
	if(TF2_IsPlayerInCondition(partner, TFCond_Taunting) && g_bFriendlyFireEnable && owner_team == partner_team)	{ 
		// checks for friendlyfire before assuming it's an enemy player
		int temp_team = OpposideTeam(owner_team);
		SetEntProp(owner, Prop_Send, "m_iTeamNum", temp_team);
		//PrintToChatAll("[DEBUG]: Aplicando dano a aliado");
		SetEntProp(owner, Prop_Send, "m_iTeamNum", owner_team);
		L_ApplyDamage(owner, partner, weapon);
		
		return Plugin_Handled;
	}
	if (TF2_IsPlayerInCondition(partner, TFCond_Taunting)) {
		//PrintToChatAll("[DEBUG]: Aplicando dano a inimigo");
		L_ApplyDamage(owner, partner, weapon);
		return Plugin_Handled;
	}
	return Plugin_Stop;
}

void L_ApplyDamage(int client, int partner, int weapon)	{
	//PrintToChatAll("[DEBUG]: L_ApplyDamage executou");
	SDKHooks_TakeDamage(partner, client, client, 999.0, 128, weapon, _, _, false);
}

bool IsClientValid(int client)
{
	if (0 < client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}

int OpposideTeam(int client)
{
	int time_inicial = GetEntProp(client, Prop_Send, "m_iTeamNum");
	int time_novo;

	if(time_inicial == 3)
	{
		time_novo = 2;
	}
	if(time_inicial == 2)
	{
		time_novo = 3;
	}
	return time_novo;
}

//Lengz37: scenes/workshop/player/pyro/low/taunt_neck_snap.vcd
//Mr_panica : scenes/workshop/player/soldier/low/taunt_neck_snap_initiator.vcd
