/*
 * THANKS:
 	- Headline - https://forums.alliedmods.net/member.php?u=258953
	- SHUFEN.jp - https://forums.alliedmods.net/member.php?u=250145
	- andi67 - https://forums.alliedmods.net/member.php?u=26100
*/

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

Handle armsHandle;
Handle modelHandle;

public Plugin myinfo =
{
	name = "Arms Fix",
	author = "NomisCZ (-N-) | Kyle",
	description = "Arms fix",
	version = "1.6",
	url = "https://github.com/NomisCZ/Arms-Fix"
}

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnConfigsExecuted()
{
	PrecacheModel("models/player/custom_player/legacy/tm_phoenix.mdl");
	PrecacheModel("models/player/custom_player/legacy/tm_anarchist.mdl");
	PrecacheModel("models/player/custom_player/legacy/ctm_sas.mdl");
	PrecacheModel("models/player/custom_player/legacy/ctm_gign.mdl");

	PrecacheModel("models/weapons/t_arms.mdl");
	PrecacheModel("models/weapons/ct_arms.mdl");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	RegPluginLibrary("CSGO_ArmsFix");

	armsHandle = CreateGlobalForward("ArmsFix_OnArmsSafe", ET_Ignore, Param_Cell);
	modelHandle = CreateGlobalForward("ArmsFix_OnModelSafe", ET_Ignore, Param_Cell);
	CreateNative("ArmsFix_SetDefaults", Native_SetDefault);
	CreateNative("ArmsFix_HasDefaultArms", Native_HasDefaultArms);

	return APLRes_Success;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("userid"));

	if(IsFakeClient(client))
		return;

	SetDefault(client);
	FixOvercap(client);
	CallForwards(client);
}

public void CallForwards(int client)
{
	CallArmsForward(client);
	CreateTimer(0.1, Timer_CallModelForward, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CallModelForward(Handle timer, int client)
{
	CallModelForward(GetClientOfUserId(client));
}

public void CallModelForward(int client)
{
	Call_StartForward(modelHandle);
	Call_PushCell(client);
	Call_Finish();
}

public void CallArmsForward(int client)
{
	Call_StartForward(armsHandle);
	Call_PushCell(client);
	Call_Finish();
}

public int Native_SetDefault(Handle plugin, int numParams)
{
    SetDefault(GetNativeCell(1));
}

public int Native_HasDefaultArms(Handle plugin, int numParams)
{
    return view_as<bool>(hasDefaultArms(GetNativeCell(1)));
}

void SetDefault(int client)
{
	if(!IsValidClient(client))
		return;

	char sModel[128];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModel, 128);

	if(GetClientTeam(client) == 2) 
	{
		SetEntityModel(client, (StrContains(sModel, "tm_phoenix") == -1) ? "models/player/custom_player/legacy/tm_phoenix.mdl" : "models/player/custom_player/legacy/tm_anarchist.mdl");
		SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/t_arms.mdl");
	} 
	else
	{
		SetEntityModel(client, (StrContains(sModel, "ctm_sas") == -1) ? "models/player/custom_player/legacy/ctm_sas.mdl" : "models/player/custom_player/legacy/ctm_gign.mdl");				
		SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/ct_arms.mdl");
	}
}

void FixOvercap(int client)
{
	int decoy = GivePlayerItem(client, "weapon_decoy");
	if(decoy != -1) RequestFrame(Frame_RemoveDecoy, EntIndexToEntRef(decoy));
}

void Frame_RemoveDecoy(int iRef)
{
	int decoy = EntRefToEntIndex(iRef);

	if(!IsValidEdict(decoy))
		return;

	int owner = GetEntPropEnt(decoy, Prop_Send, "m_hOwnerEntity");

	if(IsValidClient(owner))
		RemovePlayerItem(owner, decoy);

	AcceptEntityInput(decoy, "Kill");
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client));
}

bool hasDefaultArms(int client) {

	char clientModel[256];
	GetEntPropString(client, Prop_Send, "m_szArmsModel", clientModel, sizeof(clientModel));

	return (StrEqual(clientModel, "models/weapons/ct_arms.mdl") || StrEqual(clientModel, "models/weapons/t_arms.mdl") || StrEqual(clientModel, ""));
}