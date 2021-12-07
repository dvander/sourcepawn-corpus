#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new bool:exists[3];
#define PIPBOYVM "models/weapons/c_models/c_bet_pb/c_bet_pb.mdl"
#define QUADWRANGLERVM "models/weapons/c_models/c_qc_glove/c_qc_glove_v1.mdl"
#define ROBRO "models/player/items/all_class/pet_robro.mdl"
#define BALLOONICORN "models/player/items/all_class/pet_balloonicorn.mdl"
#define PURITYFIST "models/weapons/c_models/c_dex_sarifarm/c_dex_sarifarm_v1.mdl"
//PURITYFIST DOES NOT WORK, JUST SO YA KNOW
#define EF_BONEMERGE			(1 << 0)
#define EF_BONEMERGE_FASTCULL	(1 << 7)

#define PIPBOY_ON (1 << 0)
#define QCGLOVE_ON (1 << 1)
#define ROBRO_ON (1 << 2)
#define BALLOON_ON (1 << 3)

public Plugin:myinfo = {
	name = "[TF2] Extra Viewmodel Fixes",
	author = "FlaminSarge",
	description = "Adds viewmodels for certain cosmetic items",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

new Handle:g_hSdkEquipWearable;
new Handle:disabler;
public OnPluginStart()
{
	CreateConVar("tf_vmfix_version", PLUGIN_VERSION, "[TF2] Extra Viewmodel Fixes version", FCVAR_PLUGIN|FCVAR_NOTIFY);
	disabler = CreateConVar("tf_vmfix_enable", "15", "Add up the viewmodels you want enabled: 1-Pipboy, 2-Quadwrangler, 3-Robro, 4-Balloonicorn", FCVAR_PLUGIN, true, 0.0, true, 15.0);
/*	if (!FileExists(PIPBOYVM, true))
	{
		SetFailState("[TF2] Pip-Boy VM failed to find the viewmodel file! (%s)", PIPBOYVM);
		return;
	}
	if (!FileExists(QUADWRANGLERVM, true))
	{
		SetFailState("[TF2] Pip-Boy VM failed to find the viewmodel file! (%s)", QUADWRANGLERVM);
		return;
	}*/
//	if (!FileExists(PURITYFIST, true))
//	{
//		SetFailState("[TF2] Pip-Boy VM failed to find the viewmodel file! (%s)", PURITYFIST);
//		return;
//	}
	HookEvent("post_inventory_application", Event_PostInventoryApplication);
}
public OnMapStart()
{
	exists[0] = FileExists(PIPBOYVM, true);
	decl String:model[PLATFORM_MAX_PATH];
	new size = sizeof(model);
	if (exists[0])
	{
		strcopy(model, sizeof(model), PIPBOYVM);
		PrecacheModel(model, true);
		AddFileToDownloadsTable(model);
		ReplaceStringEx(model, size, ".mdl", ".vvd");
		AddFileToDownloadsTable(model);
		ReplaceStringEx(model, size, ".vvd", ".phy");
		AddFileToDownloadsTable(model);
		ReplaceStringEx(model, size, ".phy", ".sw.vtx");
		AddFileToDownloadsTable(model);
		ReplaceStringEx(model, size, ".sw.vtx", ".dx80.vtx");
		AddFileToDownloadsTable(model);
		ReplaceStringEx(model, size, ".dx80.vtx", ".dx90.vtx");
		AddFileToDownloadsTable(model);
	}
	exists[1] = FileExists(QUADWRANGLERVM, true);
	if (exists[1])
	{
		strcopy(model, sizeof(model), QUADWRANGLERVM);
		PrecacheModel(model, true);
		AddFileToDownloadsTable(model);
		ReplaceStringEx(model, size, ".mdl", ".vvd");
		AddFileToDownloadsTable(model);
		ReplaceStringEx(model, size, ".vvd", ".sw.vtx");
		AddFileToDownloadsTable(model);
		ReplaceStringEx(model, size, ".sw.vtx", ".dx80.vtx");
		AddFileToDownloadsTable(model);
		ReplaceStringEx(model, size, ".dx80.vtx", ".dx90.vtx");
		AddFileToDownloadsTable(model);
	}
	// strcopy(model, sizeof(model), PURITYFIST);
	// PrecacheModel(model, true);
	// AddFileToDownloadsTable(model);
	// ReplaceStringEx(model, size, ".mdl", ".vvd");
	// AddFileToDownloadsTable(model);
	// ReplaceStringEx(model, size, ".vvd", ".sw.vtx");
	// AddFileToDownloadsTable(model);
	// ReplaceStringEx(model, size, ".sw.vtx", ".dx80.vtx");
	// AddFileToDownloadsTable(model);
	// ReplaceStringEx(model, size, ".dx80.vtx", ".dx90.vtx");
	// AddFileToDownloadsTable(model);
}
public Action:Event_PostInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if (client <= 0 || client > MaxClients || !IsClientInGame(client)) return;
	if (!IsPlayerAlive(client)) return;
	new i = -1;
	new bool:found[5];
	new cvarsetting = GetConVarInt(disabler);
	while ((i = FindEntityByClassname(i, "tf_wearable")) != -1)
	{
		if (i > MaxClients && IsValidEntity(i) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable"))
		{
			new idx = GetEntProp(i, Prop_Send, "m_iItemDefinitionIndex");
			switch (idx)
			{
				case 519:
				{
					if (!found[0]) { if (exists[0] && (cvarsetting & PIPBOY_ON)) { CreateVM(client, PIPBOYVM); } }
					found[0] = true;
				}
				case 769:
				{
					if (!found[1]) { if (exists[1] && (cvarsetting & QCGLOVE_ON)) { CreateVM(client, QUADWRANGLERVM); } }
					found[1] = true;
				}
				case 733:
				{
					if (!found[2]) if (cvarsetting & ROBRO_ON) CreateVM(client, ROBRO);
					found[2] = true;
				}
				case 738:
				{
					if (!found[3]) if (cvarsetting & BALLOON_ON) CreateVM(client, BALLOONICORN);
					found[3] = true;
				}
				// case 524:
				// {
					// if (!found[4]) CreateVM(client, PURITYFIST);
					// found[4] = true;
				// }
			}
		}
	}
//	CreateTimer(0.0, Timer_CheckClient, userid, TIMER_FLAG_NO_MAPCHANGE);
}
/*public Action:Timer_CheckClient(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client <= 0 || client > MaxClients || !IsClientInGame(client)) return;
	if (!IsPlayerAlive(client)) return;
	new i = -1;
	while ((i = FindEntityByClassname(i, "tf_wearable")) != -1)
	{
		if (i > MaxClients && IsValidEntity(i) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && GetEntProp(i, Prop_Send, "m_iItemDefinitionIndex") == 519)
		{
			CreatePipBoyVM(client);
			break;
		}
	}
}*/
stock CreateVM(client, String:model[])
{
	new ent = CreateEntityByName("tf_wearable_vm");
	if (!IsValidEntity(ent)) return -1;
	SetEntProp(ent, Prop_Send, "m_nModelIndex", PrecacheModel(model));
	SetEntProp(ent, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL);
	SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
	SetEntProp(ent, Prop_Send, "m_usSolidFlags", 4);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 11);
	DispatchSpawn(ent);
	SetVariantString("!activator");
	ActivateEntity(ent);
	TF2_EquipWearable(client, ent);
	return ent;
}

stock TF2_EquipWearable(client, entity)
{
	if (g_hSdkEquipWearable == INVALID_HANDLE)
	{
		new Handle:hGameConf = LoadGameConfigFile("tf2items.randomizer");
		if (hGameConf == INVALID_HANDLE)
		{
			SetFailState("Couldn't load SDK functions. Could not locate tf2items.randomizer.txt in the gamedata folder.");
			return;
		}
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFPlayer::EquipWearable");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSdkEquipWearable = EndPrepSDKCall();
		if (g_hSdkEquipWearable == INVALID_HANDLE)
		{
			SetFailState("Could not initialize call for CTFPlayer::EquipWearable");
			CloseHandle(hGameConf);
			return;
		}
	}
	if (g_hSdkEquipWearable != INVALID_HANDLE) SDKCall(g_hSdkEquipWearable, client, entity);
}