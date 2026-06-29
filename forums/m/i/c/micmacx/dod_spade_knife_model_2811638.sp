#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.8"
#define EF_NODRAW 32

// SET THE NUMBER OF WORLDMODELS
new g_iWorldModel1;
new g_iWorldModel2;

new g_iViewModels[MAXPLAYERS + 1][2];
new Handle:g_hCreateViewModel;
new g_iOffset_Effects;
new g_iOffset_ViewModel;
new g_iOffset_ActiveWeapon;
new g_iOffset_Weapon;
new g_iOffset_Sequence;
new g_iOffset_ModelIndex;
new g_iOffset_PlaybackRate;
//new g_weaponHasOwner;
new g_iCustomVM_ModelIndex[2];

//SET THE ORIGINAL MODEL NAMES - SET NUMBER OF MODELS in []
static const String:g_szCustomVM_ClassName[2][] =  { "spade", "amerknife" };

//SET THE REPLACE MODEL NAMES - SET NUMBER OF MODELS in []
static const String:g_szCustomVM_Model[2][] =  { "models/weapons/darky/v_spade2axe.mdl", "models/weapons/darky/v_knife.mdl" };

public Plugin:myinfo =  {
	name = "DoD:S Spade and Knife Models", 
	author = "Darkranger & Andersso, Modif Micmacx", 
	description = "replaces the SPADE and the KNIFE clientside & ingame", 
	version = PLUGIN_VERSION, 
	url = "http://dodsplugins.com"
}

public OnPluginStart()
{
	CreateConVar("dod_spade_knife_model", PLUGIN_VERSION, "DoD:S Spade and Knife Models", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	new Handle:gameConf = LoadGameConfigFile("plugin.viewmodel");
	if (!gameConf)
	{
		SetFailState("Fatal Error: Unable to open game config file: \"plugin.viewmodel\"!");
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Virtual, "CreateViewModel");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	if ((g_hCreateViewModel = EndPrepSDKCall()) == INVALID_HANDLE)
	{
		SetFailState("Fatal Error: Unable to create SDK call \"CreateViewModel\"!");
	}
	
	CloseHandle(gameConf);
	g_iOffset_Effects = GetSendPropOffset("CBaseEntity", "m_fEffects");
	g_iOffset_ViewModel = GetSendPropOffset("CBasePlayer", "m_hViewModel");
	g_iOffset_ActiveWeapon = GetSendPropOffset("CBasePlayer", "m_hActiveWeapon");
	g_iOffset_Weapon = GetSendPropOffset("CDODViewModel", "m_hWeapon");
	g_iOffset_Sequence = GetSendPropOffset("CDODViewModel", "m_nSequence");
	g_iOffset_ModelIndex = GetSendPropOffset("CDODViewModel", "m_nModelIndex");
	g_iOffset_PlaybackRate = GetSendPropOffset("CDODViewModel", "m_flPlaybackRate");
	
	//g_weaponHasOwner = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	HookEvent("player_spawn", Event_PlayerSpawn);
}

GetSendPropOffset(const String:serverClass[], const String:propName[])
{
	new offset = FindSendPropInfo(serverClass, propName);
	if (!offset)
	{
		SetFailState("Fatal Error: Unable to find offset: \"%s::%s\"!", serverClass, propName);
	}
	return offset;
}

public OnMapStart()
{
	AddFileToDownloadsTable("models/weapons/darky/v_spade2axe.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/darky/v_spade2axe.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/darky/v_spade2axe.mdl");
	AddFileToDownloadsTable("models/weapons/darky/v_spade2axe.sw.vtx");
	AddFileToDownloadsTable("models/weapons/darky/v_spade2axe.vvd");
	AddFileToDownloadsTable("models/weapons/darky/w_spade2axe.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/darky/w_spade2axe.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/darky/w_spade2axe.mdl");
	AddFileToDownloadsTable("models/weapons/darky/w_spade2axe.sw.vtx");
	AddFileToDownloadsTable("models/weapons/darky/w_spade2axe.vvd");
	AddFileToDownloadsTable("materials/models/darky/axe/v_models/axe/hacha.vmt");
	AddFileToDownloadsTable("materials/models/darky/axe/v_models/axe/hacha.vtf");
	AddFileToDownloadsTable("materials/models/darky/axe/v_models/axe/hacha_normal.vtf");
	AddFileToDownloadsTable("materials/models/darky/axe/v_models/axe/hacha_ref.vtf");
	AddFileToDownloadsTable("materials/models/darky/axe/w_models/axe/hacha.vmt");
	AddFileToDownloadsTable("models/weapons/darky/v_knife.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/darky/v_knife.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/darky/v_knife.mdl");
	AddFileToDownloadsTable("models/weapons/darky/v_knife.sw.vtx");
	AddFileToDownloadsTable("models/weapons/darky/v_knife.vvd");
	AddFileToDownloadsTable("models/weapons/darky/w_knife.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/darky/w_knife.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/darky/w_knife.mdl");
	AddFileToDownloadsTable("models/weapons/darky/w_knife.sw.vtx");
	AddFileToDownloadsTable("models/weapons/darky/w_knife.vvd");
	AddFileToDownloadsTable("materials/models/darky/knife/bolo.vmt");
	AddFileToDownloadsTable("materials/models/darky/knife/bolo.vtf");
	AddFileToDownloadsTable("materials/models/darky/knife/bolon.vtf");
	
	for (new i = 0; i < 2; i++)
	{
		g_iCustomVM_ModelIndex[i] = PrecacheModel(g_szCustomVM_Model[i], true);
	}
	
	//PRECHACE THE WORLD MODEL
	g_iWorldModel1 = PrecacheModel("models/weapons/darky/w_spade2axe.mdl", true);
	g_iWorldModel2 = PrecacheModel("models/weapons/darky/w_knife.mdl", true);
}

public OnClientPostAdminCheck(client)
{
	g_iViewModels[client][0] = -1;
	g_iViewModels[client][1] = -1;
	SDKHook(client, SDKHook_PostThink, OnClientThinkPost);
}

public OnClientThinkPost(client)
{
	static currentWeapon[MAXPLAYERS + 1];
	new viewModel1 = g_iViewModels[client][0];
	new viewModel2 = g_iViewModels[client][1];
	if (!IsPlayerAlive(client))
	{
		if ((viewModel2 != -1) && (IsValidEntity(viewModel2)))
		{
			// If the player is dead, hide the secondary viewmodel.
			ShowViewModel(viewModel2, false);
			g_iViewModels[client][0] = -1;
			g_iViewModels[client][1] = -1;
			currentWeapon[client] = 0;
		}
		return;
	}
	new activeWeapon = GetEntDataEnt2(client, g_iOffset_ActiveWeapon);
	// Check if the player has switched weapon.
	if ((activeWeapon != currentWeapon[client]) && (IsValidEntity(activeWeapon)))
	{
		// Hide the secondary viewmodel, if necessary.
		if (currentWeapon[client])
		{
			ShowViewModel(viewModel2, false);
		}
		currentWeapon[client] = 0;
		decl String:className[32];
		if (IsValidEntity(activeWeapon))
		{
			GetEdictClassname(activeWeapon, className, sizeof(className));
			if (ReplaceString(className, sizeof(className), "weapon_", NULL_STRING))
			{
				for (new i = 0; i < 2; i++)
				{
					if (StrEqual(className, g_szCustomVM_ClassName[i]))
					{
						// Hide the primary viewmodel.
						ShowViewModel(viewModel1, false);
						// Show the secondary viewmodel.
						ShowViewModel(viewModel2, true);
						SetEntData(viewModel2, g_iOffset_ModelIndex, g_iCustomVM_ModelIndex[i], _, true);
						SetEntData(viewModel2, g_iOffset_Weapon, GetEntData(viewModel1, g_iOffset_Weapon), _, true);
						currentWeapon[client] = activeWeapon;
						break;
					}
				}
			}
		}
	}
	if ((currentWeapon[client]) && IsValidEntity(viewModel2))
	{
		SetEntData(viewModel2, g_iOffset_Sequence, GetEntData(viewModel1, g_iOffset_Sequence), _, true);
		SetEntData(viewModel2, g_iOffset_PlaybackRate, GetEntData(viewModel1, g_iOffset_PlaybackRate), _, true);
	}
}

ShowViewModel(viewModel, bool:show)
{
	new flags = GetEntData(viewModel, g_iOffset_Effects);
	SetEntData(viewModel, g_iOffset_Effects, show ? flags & ~EF_NODRAW : flags | EF_NODRAW, _, true);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBrodcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(client) > 1)
	{
		// Create the second view model.
		SDKCall(g_hCreateViewModel, client, 1);
		g_iViewModels[client][0] = GetViewModel(client, 0);
		g_iViewModels[client][1] = GetViewModel(client, 1);
	}
}

GetViewModel(client, index)
{
	return GetEntDataEnt2(client, g_iOffset_ViewModel + (index * 4));
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &Impulse, Float:fVelocity[3], Float:fAngles[3], &iWeapon)
{
	new iActiveWeapon = GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon");
	if (iActiveWeapon != -1)
	{
		decl String:sWeapon[64];
		GetEdictClassname(iActiveWeapon, sWeapon, sizeof(sWeapon));
		if (StrEqual(sWeapon, "weapon_spade"))
		{
			SetEntProp(iActiveWeapon, Prop_Send, "m_iWorldModelIndex", g_iWorldModel1);
		}
		if (StrEqual(sWeapon, "weapon_amerknife"))
		{
			SetEntProp(iActiveWeapon, Prop_Send, "m_iWorldModelIndex", g_iWorldModel2);
		}
	}
}

/*
public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

public Action:OnWeaponDrop(client, weapon)
{
    if (weapon && IsValidEdict(weapon) && IsValidEntity(weapon))
            CreateTimer(0.01, deleteWeapon, weapon);

    return Plugin_Continue;
}

public Action:deleteWeapon(Handle:timer, any:weapon)
{
	new maxent = GetMaxEntities(), String:name[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, name, sizeof(name));
			if ( ( StrContains(name, "weapon_") != -1 || StrContains(name, "item_") != -1 ) && GetEntDataEnt2(i, g_weaponHasOwner) == -1 )
					RemoveEdict(i);
		}
	}
}
*/