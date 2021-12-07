#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <attachables>
#include <tf2_stocks>

#define PLUGIN_NAME		"[TF2] Visible Weapon Natives"
#define PLUGIN_AUTHOR		"FlaminSarge"
#define PLUGIN_VERSION		"1.1"
#define PLUGIN_CONTACT		"http://pulpfortress.com or http://gaming.calculatedchaos.com"
#define PLUGIN_DESCRIPTION	"Adds natives to add models to invisible weapons"

public Plugin:myinfo = {
	name			= PLUGIN_NAME,
	author			= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url				= PLUGIN_CONTACT
};


new g_iPlayerEntities[MAXPLAYERS + 1][6][4];

public OnPluginStart()
{
	CreateConVar("visibleweapons_version", PLUGIN_VERSION, "[TF2] Visible Weapon Natives version", FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	//Translations file...
	LoadTranslations("common.phrases");
	/************************
	 * Event & Entity Hooks *
	 ************************/
	HookEvent("player_death", player_death, EventHookMode_Pre);
	HookEvent("post_inventory_application", locker_reset);
	HookEvent("player_spawn", locker_reset);
	for (new client = 1; client < MAXPLAYERS + 1; client++)
	{
		if (IsValidClient(client)) SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
		for (new slot = 0; slot < 6; slot++)
		{
			for (new i = 0; i < 4; i++)
			{
				if (g_iPlayerEntities[client][slot][i] != -1)
				{
					g_iPlayerEntities[client][slot][i] = -1;
				}
			}
		}
	}
}
public OnMapStart()
{
//	PrecacheModel("models/weapons/w_models/w_stickybomb_defender.mdl", false);

	for (new client = 1; client <= MaxClients; client++)
	{
		for (new slot = 0; slot < 6; slot++)
		{
			for (new i = 0; i < 4; i++)
			{
				if (g_iPlayerEntities[client][slot][i] != -1)
				{
					g_iPlayerEntities[client][slot][i] = -1;
				}
			}
		}
	}
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	RemovePlayerEntities(client);
}

public OnClientDisconnect_Post(client)
{
	RemovePlayerEntities(client);
}
public player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	RemovePlayerEntities(client);
}
public locker_reset(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	RemovePlayerEntities(client);
}

public Action:OnWeaponSwitch(client, weapon)
{
	for (new x = 0; x < 6; x++)
	{
		if (GetPlayerWeaponSlot(client, x) == weapon)
		{
			MakeSlotVisible(client, x);
		}
	}
	return Plugin_Continue;
}
RemovePlayerEntities(client)
{
	for (new slot = 0; slot < 6; slot++)
	{
		RemoveWeaponsForSlot(client, slot);
		/*for (new i = 0; i < 4; i++)
		{
			if (g_iPlayerEntities[client][slot][i] != -1)
			{
				if (IsValidEntity(g_iPlayerEntities[client][slot][i]) && Attachable_IsHooked(g_iPlayerEntities[client][slot][i]))
				{
//					Attachable_UnhookEntity(g_iPlayerEntities[client][slot][i]);
					if (g_iPlayerEntities[client][slot][i] != 0) AcceptEntityInput(g_iPlayerEntities[client][slot][i], "Kill"); // RemoveEdict(g_iPlayerEntities[client][slot][i]);
				}
				g_iPlayerEntities[client][slot][i] = -1;
			}
		}*/
	}
}
RemoveWeaponsForSlot(client, slot)
{
	for (new i = 0; i < 4; i++)
	{
		if (g_iPlayerEntities[client][slot][i] != -1)
		{
			if (IsValidEntity(g_iPlayerEntities[client][slot][i]) /*&& Attachable_IsHooked(g_iPlayerEntities[client][slot][i])*/)
			{
				decl String:classname[64];
				GetEdictClassname(g_iPlayerEntities[client][slot][i], classname, sizeof(classname));
//				Attachable_UnhookEntity(g_iPlayerEntities[client][slot][i]);
				if (StrEqual(classname, "prop_physics", false) /*g_iPlayerEntities[client][slot][i] != 0*/) AcceptEntityInput(g_iPlayerEntities[client][slot][i], "Kill"); // RemoveEdict(g_iPlayerEntities[client][slot][i]);
			}
			g_iPlayerEntities[client][slot][i] = -1;
		}
	}
}
public Action:AddWeaponForSlot(client, slot, const String:modelname[])
{
	decl String:model[128];
	new idx;
	new bool:stockmodel = false;
	if (strlen(modelname) <= 15) 
	{
		idx = StringToInt(modelname);
		strcopy(model, 128, DetermineWepDefIndexModel(idx));
		stockmodel = true;
	}
	else strcopy(model, 128, modelname);
	RemoveWeaponsForSlot(client, slot);
	
	if (!IsValidClient(client)) return;

	if (StrEqual(model, "")) return;
	if (g_iPlayerEntities[client][slot][0] != -1) return;
	
	new bool:bHasModel = true;
	if (StrEqual(model, "")) bHasModel = false;
	
	// This should've already have happened anyway
	g_iPlayerEntities[client][slot][0] = -1;
	g_iPlayerEntities[client][slot][1] = -1;
	g_iPlayerEntities[client][slot][2] = -1;
	g_iPlayerEntities[client][slot][3] = -1;
	if (!IsModelPrecached(model) && (FileExists(model, false) || FileExists(model, true))) PrecacheModel(model);
	if (!StrEqual(model, "") && bHasModel && IsModelPrecached(model))
	{
		new iEntity3 = Attachable_CreateAttachable(client, false);
		if (iEntity3 > 0 && IsValidEntity(iEntity3)) 
		{
			if (stockmodel)
			{
				switch (idx)
				{
					case 41: SetEntData(iEntity3, FindSendPropOffs("CPhysicsProp", "m_nSkin"), 2, 1, true);
					case 239:
					{
						new iTeam = GetClientTeam(client);
						SetEntData(iEntity3, FindSendPropOffs("CPhysicsProp", "m_nSkin"), (iTeam), 1, true);
					}
					default:
					{
						new iTeam = GetClientTeam(client);
						if (idx != 20 && idx != 15 && idx != 265 && idx != 2041) SetEntData(iEntity3, FindSendPropOffs("CPhysicsProp", "m_nSkin"), (iTeam-2), 1, true);
					}
				}
			}
			SetEntityModel(iEntity3, model);
			g_iPlayerEntities[client][slot][0] = iEntity3;
		}
		if (stockmodel)
		{
			switch (idx)
			{
				case 129:
				{
					new iEntity4 = Attachable_CreateAttachable(client, false);
					if (iEntity4 > 0 && IsValidEntity(iEntity4))
					{
						SetEntityModel(iEntity4, "models/weapons/c_models/c_buffpack/c_buffpack.mdl");
						g_iPlayerEntities[client][slot][2] = iEntity4;
					}
				}
				case 226:
				{
					new iEntity4 = Attachable_CreateAttachable(client, false);
					if (iEntity4 > 0 && IsValidEntity(iEntity4))
					{
						SetEntityModel(iEntity4, "models/weapons/c_models/c_battalion_buffpack/c_batt_buffpack.mdl");
						g_iPlayerEntities[client][slot][2] = iEntity4;
					}
				}
				case 40:
				{
					new iEntity4 = Attachable_CreateAttachable(client, false);
					if (iEntity4 > 0 && IsValidEntity(iEntity4))
					{
						new iTeam = GetClientTeam(client);
						SetEntData(iEntity4, FindSendPropOffs("CPhysicsProp", "m_nSkin"), (iTeam-2), 1, true); 
						SetEntityModel(iEntity4, "models/weapons/c_models/c_backburner/c_backburner.mdl");
						g_iPlayerEntities[client][slot][1] = iEntity4;
					}
				}

				case 35:
				{
					new iEntity4 = Attachable_CreateAttachable(client, false);
					if (iEntity4 > 0 && IsValidEntity(iEntity4))
					{
						SetEntityModel(iEntity4, "models/weapons/c_models/c_overhealer/c_overhealer.mdl");
						g_iPlayerEntities[client][slot][1] = iEntity4;
					}
				}
				case 41:
				{
					new iEntity4 = Attachable_CreateAttachable(client, false);
					if (iEntity4 > 0 && IsValidEntity(iEntity4))
					{
						SetEntityModel(iEntity4, "models/weapons/c_models/c_w_ludmila/c_w_ludmila.mdl");
						g_iPlayerEntities[client][slot][1] = iEntity4;
					}
				}
				case 2041:
				{
					new iEntity4 = Attachable_CreateAttachable(client, false);
					if (iEntity4 > 0 && IsValidEntity(iEntity4))
					{
						SetEntityModel(iEntity4, "models/weapons/c_models/c_w_ludmila/c_w_ludmila.mdl");
						g_iPlayerEntities[client][slot][1] = iEntity4;
					}
				}
			}
		}
	}
	slot = GetClientSlot(client);
	MakeSlotVisible(client, slot);

}
/*stock CreateWeaponForOthers(client) {
	new iEntity = -1;
	iEntity = Attachable_CreateAttachable(client);
	return iEntity;
}*/
stock MakeSlotVisible(client, iTargetSlot)
{   
	for (new slot = 0; slot < 6; slot++)
	{
		new iEntity3 = g_iPlayerEntities[client][slot][0];
		new iEntity4 = g_iPlayerEntities[client][slot][1];
		new bool:bHide = false;
		new bool:bHide2 = false;
//		new bool:bHide3 = false;
		if (iTargetSlot != slot) bHide = true;
		//if (TF2_GetPlayerConditionFlags(client) & TF_CONDFLAG_TAUNTING && TauntShouldShowModel(client, iTargetSlot) == false) bHide = true;
		//if (!ShouldPlayerSeeFP(client)) bHide = true;
		
		
		if (TF2_GetPlayerConditionFlags(client) & TF_CONDFLAG_DISGUISED) {
			bHide2 = true;
		}
		if (TF2_GetPlayerConditionFlags(client) & TF_CONDFLAG_DISGUISING) {
			bHide2 = true;
		}
		
		if (bHide2) bHide = true;
/*		bHide3 = bHide;
		if (TF2_GetPlayerConditionFlags(client) & TF_CONDFLAG_CLOAKED) {
			bHide3 = true;
		}*/
		
		if (iEntity3 != -1) HideEntity(iEntity3, bHide);
		if (iEntity4 != -1) HideEntity(iEntity4, bHide);
	}
}
HideEntity(entity, bool:hide)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[64];
		if (!GetEdictClassname(entity, classname, sizeof(classname))) classname = "";
		if (StrEqual(classname, "prop_physics", false))
		{
			if (hide)
			{
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, 0);
			}
			else
			{
				SetEntityRenderMode(entity, RENDER_NORMAL);
				SetEntityRenderColor(entity, 255, 255, 255, 255);
			}
		}
	}
}
String:DetermineWepDefIndexModel(idx)
{
	decl String:modelname[128];
	switch (idx)
	{
		case 0: strcopy(modelname, 128, "models/weapons/w_models/w_bat.mdl");
		case 13: strcopy(modelname, 128, "models/weapons/w_models/w_scattergun.mdl");
		case 45: strcopy(modelname, 128, "models/weapons/c_models/c_double_barrel.mdl");
		case 46: strcopy(modelname, 128, "models/weapons/c_models/c_energy_drink/c_energy_drink.mdl");
		case 44: strcopy(modelname, 128, "models/weapons/c_models/c_wooden_bat/c_wooden_bat.mdl");
		case 23: strcopy(modelname, 128, "models/weapons/w_models/w_pistol.mdl");
		case 163: strcopy(modelname, 128, "models/weapons/c_models/c_energy_drink/c_energy_drink.mdl");
		case 221: strcopy(modelname, 128, "models/weapons/c_models/c_holymackerel.mdl");
		case 222: strcopy(modelname, 128, "models/weapons/c_models/c_madmilk/c_madmilk.mdl");
		case 220: strcopy(modelname, 128, "models/weapons/c_models/c_shortstop/c_shortstop.mdl");
		case 160: strcopy(modelname, 128, "models/weapons/w_models/w_ttg_max_gun.mdl");
		case 294: strcopy(modelname, 128, "models/weapons/w_models/w_ttg_max_gun.mdl");
		case 317: strcopy(modelname, 128, "models/weapons/c_models/c_candy_cane/c_candy_cane.mdl");
		case 325: strcopy(modelname, 128, "models/weapons/c_models/c_boston_basher/c_boston_basher.mdl");

		case 6: strcopy(modelname, 128, "models/weapons/w_models/w_shovel.mdl");
		case 10: strcopy(modelname, 128, "models/weapons/w_models/w_shotgun.mdl");
		case 18: strcopy(modelname, 128, "models/weapons/w_models/w_rocketlauncher.mdl");
		case 127: strcopy(modelname, 128, "models/weapons/c_models/c_directhit/c_directhit.mdl");
		case 128: strcopy(modelname, 128, "models/weapons/c_models/c_pickaxe/c_pickaxe.mdl");
		case 129: strcopy(modelname, 128, "models/weapons/c_models/c_bugle/c_bugle.mdl");
		case 226: strcopy(modelname, 128, "models/weapons/c_models/c_battalion_bugle/c_battalion_bugle.mdl");
		case 228: strcopy(modelname, 128, "models/weapons/c_models/c_blackbox/c_blackbox.mdl");
		case 237: strcopy(modelname, 128, "models/weapons/w_models/w_rocketlauncher.mdl");

		case 2: strcopy(modelname, 128, "models/weapons/w_models/w_fireaxe.mdl");
		case 12: strcopy(modelname, 128, "models/weapons/w_models/w_shotgun.mdl");
		case 21: strcopy(modelname, 128, "models/weapons/w_models/w_flamethrower.mdl");
		case 38: strcopy(modelname, 128, "models/weapons/c_models/c_axtinguisher/c_axtinguisher_pyro.mdl");
		case 39: strcopy(modelname, 128, "models/weapons/c_models/c_flaregun_pyro/c_flaregun_pyro.mdl");
		case 40: strcopy(modelname, 128, "models/weapons/c_models/c_flamethrower/c_flamethrower.mdl");
		case 153: strcopy(modelname, 128, "models/weapons/c_models/c_sledgehammer/c_sledgehammer.mdl");
		case 214: strcopy(modelname, 128, "models/weapons/c_models/c_powerjack/c_powerjack.mdl");
		case 215: strcopy(modelname, 128, "models/weapons/c_models/c_degreaser/c_degreaser.mdl");
		case 326: strcopy(modelname, 128, "models/weapons/c_models/c_back_scratcher/c_back_scratcher.mdl");

		case 1: strcopy(modelname, 128, "models/weapons/w_models/w_bottle.mdl");
		case 19: strcopy(modelname, 128, "models/weapons/c_models/c_grenadelauncher/c_grenadelauncher.mdl");
		case 20: strcopy(modelname, 128, "models/weapons/w_models/w_stickybomb_launcher.mdl");
		case 130: strcopy(modelname, 128, "models/weapons/c_models/c_scottish_resistance.mdl");
		case 132: strcopy(modelname, 128, "models/weapons/c_models/c_claymore/c_claymore.mdl");
		case 265: strcopy(modelname, 128, "models/weapons/w_models/w_stickybomb_launcher.mdl");
		case 172: strcopy(modelname, 128, "models/weapons/c_models/c_battleaxe/c_battleaxe.mdl");
		case 154: strcopy(modelname, 128, "models/weapons/c_models/c_paintrain/c_paintrain.mdl");
		case 307: strcopy(modelname, 128, "models/weapons/c_models/c_caber/c_caber.mdl");
		case 308: strcopy(modelname, 128, "models/weapons/c_models/c_lochnload/c_lochnload.mdl");
		case 327: strcopy(modelname, 128, "models/weapons/c_models/c_claidheamohmor/c_claidheamohmor.mdl");

		case 11: strcopy(modelname, 128, "models/weapons/w_models/w_shotgun.mdl");
		case 15: strcopy(modelname, 128, "models/weapons/w_models/w_minigun.mdl");
		case 41: strcopy(modelname, 128, "models/weapons/w_models/w_minigun.mdl");
		case 42: strcopy(modelname, 128, "models/weapons/c_models/c_sandwich/c_sandwich.mdl");
		case 43: strcopy(modelname, 128, "models/weapons/c_models/c_boxing_gloves/c_boxing_gloves.mdl");
		case 159: strcopy(modelname, 128, "models/weapons/c_models/c_chocolate/c_chocolate.mdl");
		case 239: strcopy(modelname, 128, "models/weapons/c_models/c_boxing_gloves/c_boxing_gloves.mdl");
		case 298: strcopy(modelname, 128, "models/weapons/c_models/c_iron_curtain/c_iron_curtain.mdl");
		case 310: strcopy(modelname, 128, "models/weapons/c_models/c_bear_claw/c_bear_claw.mdl");
		case 311: strcopy(modelname, 128, "models/weapons/c_models/c_buffalo_steak/c_buffalo_steak.mdl");
		case 312: strcopy(modelname, 128, "models/weapons/c_models/c_gatling_gun/c_gatling_gun.mdl");
		case 331: strcopy(modelname, 128, "models/weapons/c_models/c_fists_of_steel/c_fists_of_steel.mdl");

		case 7: strcopy(modelname, 128, "models/weapons/w_models/w_wrench.mdl");
		case 9: strcopy(modelname, 128, "models/weapons/w_models/w_shotgun.mdl");
		case 22: strcopy(modelname, 128, "models/weapons/w_models/w_pistol.mdl");
		case 140: strcopy(modelname, 128, "models/weapons/c_models/c_wrangler.mdl");
		case 141: strcopy(modelname, 128, "models/weapons/c_models/c_frontierjustice/c_frontierjustice.mdl");
		case 155: strcopy(modelname, 128, "models/weapons/c_models/c_spikewrench/c_spikewrench.mdl");
		case 169: strcopy(modelname, 128, "models/weapons/c_models/c_wrench/c_wrench.mdl");
		case 329: strcopy(modelname, 128, "models/weapons/c_models/c_jag/c_jag.mdl");

		case 8: strcopy(modelname, 128, "models/weapons/w_models/w_bonesaw.mdl");
		case 17: strcopy(modelname, 128, "models/weapons/w_models/w_syringegun.mdl");
		case 29: strcopy(modelname, 128, "models/weapons/w_models/w_medigun.mdl");
		case 35: strcopy(modelname, 128, "models/weapons/c_models/c_medigun/c_medigun.mdl");
		case 36: strcopy(modelname, 128, "models/weapons/c_models/c_leechgun/c_leechgun.mdl");
		case 37: strcopy(modelname, 128, "models/weapons/c_models/c_ubersaw/c_ubersaw.mdl");
		case 173: strcopy(modelname, 128, "models/weapons/c_models/c_uberneedle/c_uberneedle.mdl");
		case 304: strcopy(modelname, 128, "models/weapons/c_models/c_amputator/c_amputator.mdl");
		case 305: strcopy(modelname, 128, "models/weapons/c_models/c_crusaders_crossbow/c_crusaders_crossbow.mdl");

		case 3: strcopy(modelname, 128, "models/weapons/c_models/c_machete/c_machete.mdl");
		case 14: strcopy(modelname, 128, "models/weapons/w_models/w_sniperrifle.mdl");
		case 16: strcopy(modelname, 128, "models/weapons/w_models/w_smg.mdl");
		case 56: strcopy(modelname, 128, "models/weapons/c_models/c_bow/c_bow.mdl");
		case 58: strcopy(modelname, 128, "models/weapons/c_models/urinejar.mdl");
		case 171: strcopy(modelname, 128, "models/weapons/c_models/c_wood_machete/c_wood_machete.mdl");
		case 230: strcopy(modelname, 128, "models/weapons/c_models/c_dartgun.mdl");
		case 232: strcopy(modelname, 128, "models/weapons/c_models/c_croc_knife/c_croc_knife.mdl");

		case 4: strcopy(modelname, 128, "models/weapons/w_models/w_knife.mdl");
		case 24: strcopy(modelname, 128, "models/weapons/w_models/w_revolver.mdl");
		case 61: strcopy(modelname, 128, "models/weapons/c_models/c_ambassador/c_ambassador.mdl");
		case 161: strcopy(modelname, 128, "models/weapons/c_models/c_ttg_sam_gun/c_ttg_sam_gun.mdl");
		case 224: strcopy(modelname, 128, "models/weapons/c_models/c_letranger/c_letranger.mdl");
		case 225: strcopy(modelname, 128, "models/weapons/c_models/c_eternal_reward/c_eternal_reward.mdl");

		case 266: strcopy(modelname, 128, "models/weapons/c_models/c_headtaker/c_headtaker.mdl");
		case 264: strcopy(modelname, 128, "models/weapons/c_models/c_frying_pan/c_frying_pan.mdl");
		case 348: strcopy(modelname, 128, "models/weapons/c_models/c_rift_fire_axe/c_rift_fire_axe.mdl");
		case 349: strcopy(modelname, 128, "models/weapons/c_models/c_rift_fire_mace/c_rift_fire_mace.mdl");
		case 2041: strcopy(modelname, 128, "models/weapons/w_models/w_minigun.mdl");
		default: strcopy(modelname, 128, "");
	}
	return modelname;
}
stock GetClientSlot(client)
{
	// Get all client's weapon indexes.
	new active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	// If client has no deployed weapon, then stop.
	if (active == -1)
	{
		return -1;
	}
	
	for (new x = 0; x < 6; x++)
	{
		if (GetPlayerWeaponSlot(client, x) == active)
		{
			return x;
		}
	}
	
	return -1;
}
stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// Register Native
	CreateNative("VisWep_GiveWeapon", Native_VisWepGive);
	RegPluginLibrary("visweps");
/*	if (late)
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			SDKUnhook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
			OnClientPutInServer(client);
		}
	}*/
	return APLRes_Success;
}
public Native_VisWepGive(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new slot = GetNativeCell(2);
	decl String:model[128];
	GetNativeString(3, model, sizeof(model));
	if (slot < 0 || slot > 5) ThrowNativeError(SP_ERROR_NATIVE, "[SM] Bad slot number %d", slot);
	AddWeaponForSlot(client, slot, model);
}
public OnPluginEnd()
{
	for (new client = 1; client < MaxClients; client++)
	{
		RemovePlayerEntities(client);
	}
}