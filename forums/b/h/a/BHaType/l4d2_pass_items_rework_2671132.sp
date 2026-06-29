#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define MAXSLOTS 6

Handle g_hThrow;
float g_flTime[MAXPLAYERS + 1], g_flVelocity;
ConVar cAllowedSlots, cThrowVelocity;
bool g_iRestricted[MAXSLOTS];

public Plugin myinfo =
{
	name = "[L4D2] Throw Items Rework",
	author = "BHaType",
	description = "Changes the system of giving away items teammates",
	version = "0.0",
	url = "SDKCall"
}

public void OnPluginStart()
{
	Handle hData = LoadGameConfigFile("l4d2_items_pass_rework");
	
	cAllowedSlots = CreateConVar("sm_throw_restricted_slots", "5|0", "Which slots doesnt allow to throw", FCVAR_NONE);
	cThrowVelocity = CreateConVar("sm_throw_velocity", "250.0", "Throw velocity", FCVAR_NONE);
	
	Address hAddress = GameConfGetAddress(hData, "CTerrorPlayer::GiveActiveWeapon");
	
	StoreToAddress(hAddress + view_as<Address>(GameConfGetOffset(hData, "Patch1")), 0x90, NumberType_Int8);
	StoreToAddress(hAddress + view_as<Address>(GameConfGetOffset(hData, "Patch2")), 0x90, NumberType_Int8);
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "CTerrorPlayer::ThrowWeapon");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hThrow = EndPrepSDKCall();
	
	GetAllowedSlots();
	g_flVelocity = cThrowVelocity.FloatValue;
	
	cThrowVelocity.AddChangeHook(OnConVarChanged);
	cAllowedSlots.AddChangeHook(OnConVarChanged);
	
	delete hData;
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
		g_flTime[i] = 0.0;
}

public void OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetAllowedSlots();
	g_flVelocity = cThrowVelocity.FloatValue;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (GetClientTeam(client) != 2 || !(buttons & IN_ATTACK2))
		return;
	
	if (GetGameTime() - g_flTime[client] < 0.225)
		return;
		
	g_flTime[client] = GetGameTime();
		
	int iTarget = GetClientAimTarget(client);
	
	if (iTarget <= 0 || iTarget > MaxClients || GetClientTeam(iTarget) != 2)
		return;
		
	int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (iWeapon <= MaxClients)
		return;
	
	if (g_iRestricted[iSlotWeapon(client, iWeapon)])
		return;
	
	SDKCall(g_hThrow, client, iWeapon, iTarget, g_flVelocity, 0, 0);

	CreateTrigger(EntRefToEntIndex(iWeapon), client);
}

int CreateTrigger (int iWeapon, int client)
{
	int entity = CreateEntityByName("trigger_multiple");
	
	if (entity == -1)
	{
		LogError("Invalid trigger");
		return -1;
	}
	
	char szName[16];
	IntToString(GetClientUserId(client), szName, sizeof szName); 
	
	DispatchKeyValue(entity, "spawnflags", "1");
	DispatchKeyValue(entity, "wait", "0");
	DispatchKeyValue(entity, "targetname", szName);
	
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", iWeapon);
	
	DispatchSpawn(entity);
	ActivateEntity(entity);
	
	SetEntPropVector(entity, Prop_Send, "m_vecMins", view_as<float>({-5.0, -5.0, -5.0}));
	SetEntPropVector(entity, Prop_Send, "m_vecMaxs", view_as<float>({5.0, 5.0, 5.0}));
	
	SetEntProp(entity, Prop_Send, "m_nSolidType", 2);
	HookSingleEntityOutput(entity, "OnStartTouch", OnTouch);
	
	SetEntProp(entity, Prop_Data, "m_iHammerID", EntIndexToEntRef(iWeapon));
	TeleportEntity(entity, view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR, NULL_VECTOR);
	return -1;
}

public void OnTouch(const char[] output, int entity, int client, float delay)
{
	char szName[16];
	GetEntPropString(entity, Prop_Data, "m_iName", szName, sizeof szName);
	
	if (client == GetClientOfUserId(StringToInt(szName)) || GetClientTeam(client) != 2)
		return;
	
	int iWeapon = EntRefToEntIndex(GetEntProp(entity, Prop_Data, "m_iHammerID"));
	
	if (IsValidEntity(iWeapon))
		AcceptEntityInput(iWeapon, "Use", client);
	
	if (IsValidEntity(entity))
		AcceptEntityInput(entity, "kill");
}

int iSlotWeapon(int client, int entity)
{
	for (int i; i <= 5; i++)
		if (GetPlayerWeaponSlot(client, i) == entity)
			return i;
	return 0;
}

void GetAllowedSlots()
{
	char szString[16], szExploded[MAXSLOTS][4];
	
	
	cAllowedSlots.GetString(szString, sizeof szString);
	
	if (szString[0] == '\0')
		return;
	
	int iNum = ExplodeString(szString, "|", szExploded, sizeof szExploded, sizeof szExploded[]);
	
	if (iNum > 0)
	{
		for (int i; i <= iNum - 1; i++)
			g_iRestricted[StringToInt(szExploded[i])] = true;
	}
	else
	{
		g_iRestricted[StringToInt(szString)] = true;
	}
}