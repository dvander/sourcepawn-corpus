/* Plugin Version History
* 1.0 - Public release
* 1.1 - renamed cvar descriptions
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define MODEL_V_FIREAXE "models/weapons/melee/v_fireaxe.mdl"
#define MODEL_V_FRYING_PAN "models/weapons/melee/v_frying_pan.mdl"
#define MODEL_V_MACHETE "models/weapons/melee/v_machete.mdl"
#define MODEL_V_BASEBALL_BAT "models/weapons/melee/v_bat.mdl"
#define MODEL_V_CROWBAR "models/weapons/melee/v_crowbar.mdl"
#define MODEL_V_CRICKET_BAT "models/weapons/melee/v_cricket_bat.mdl"
#define MODEL_V_TONFA "models/weapons/melee/v_tonfa.mdl"
#define MODEL_V_KATANA "models/weapons/melee/v_katana.mdl"
#define MODEL_V_ELECTRIC_GUITAR "models/weapons/melee/v_electric_guitar.mdl"
#define MODEL_V_GOLFCLUB "models/weapons/melee/v_golfclub.mdl"

#define PLUGIN_VERSION "1.1"
#define ADVERT "\x04[\x03Caught Item Drop\x04] \x03You will drop current held item when caught by special infected\x04!"

public Plugin:myinfo =
{
	name = "L4D2 Caught Item Drop",
	author = "kwski43 aka Jacklul",
	description = "Survivors drop their current held item when caught by special infected.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1252856"
}

//Main functionality cvars
new Handle:cvarAdvertDelay;
new Handle:cvarShowInfo;

new Handle:cvarDropOnHunter;
new Handle:cvarDropOnSmoker;
new Handle:cvarDropOnCharger;
new Handle:cvarDropOnJockey;

public OnPluginStart()
{
	CreateConVar("l4d2_ciw_version", PLUGIN_VERSION, "Caught Item Drop Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	LoadTranslations("l4d2_caughtitemdrop.phrases");
	
	decl String:s_Game[12];
	GetGameFolderName(s_Game, sizeof(s_Game));
	if (StrEqual(s_Game, "left4dead")) {
		LogMessage("Detected Left4Dead!");
		//Main Cvars
		cvarAdvertDelay = CreateConVar("l4d_ciw_adsdelay", "15.0", "Advertisements after round start delay? 0-disable",FCVAR_PLUGIN, true, 0.0, true, 120.0);
		cvarShowInfo = CreateConVar("l4d_ciw_showinfo", "1", "Show info to players that they dropped item? 0-disabled, 1-chat, 2-hint",FCVAR_PLUGIN, true, 0.0, true, 1.0);
		cvarDropOnHunter = CreateConVar("l4d_ciw_droponhunter", "1", "Drop Item when pounced?",FCVAR_PLUGIN, true, 0.0, true, 1.0);
		cvarDropOnSmoker = CreateConVar("l4d_ciw_droponsmoker", "1", "Drop Item when dragged?",FCVAR_PLUGIN, true, 0.0, true, 1.0);
		
		AutoExecConfig(true, "l4d_caughtitemdrop");
		
		HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
		//Some infected attacks events
		HookEvent("tongue_grab", EventTongueGrab, EventHookMode_Post);
		HookEvent("lunge_pounce", EventPlayerPounced, EventHookMode_Post);
		
	}
	else if (StrEqual(s_Game, "left4dead2")) {
		LogMessage("Detected Left4Dead2!");
		//Main cvars
		cvarAdvertDelay = CreateConVar("l4d2_ciw_adsdelay", "15.0", "Advertisements after round start delay? 0-disable",FCVAR_PLUGIN, true, 0.0, true, 120.0);
		cvarShowInfo = CreateConVar("l4d2_ciw_showinfo", "1", "Show info to players that they dropped item? 0-disabled, 1-chat, 2-hint",FCVAR_PLUGIN, true, 0.0, true, 1.0);
		cvarDropOnHunter = CreateConVar("l4d2_ciw_droponhunter", "1", "Drop Item when pounced?",FCVAR_PLUGIN, true, 0.0, true, 1.0);
		cvarDropOnSmoker = CreateConVar("l4d2_ciw_droponsmoker", "1", "Drop Item when dragged?",FCVAR_PLUGIN, true, 0.0, true, 1.0);
		cvarDropOnCharger = CreateConVar("l4d2_ciw_droponcharger", "1", "Drop Item when pummelled?",FCVAR_PLUGIN, true, 0.0, true, 1.0);
		cvarDropOnJockey = CreateConVar("l4d2_ciw_droponjockey", "1", "Drop Item when jockeyed?",FCVAR_PLUGIN, true, 0.0, true, 1.0);
		
		AutoExecConfig(true, "l4d2_caughtitemdrop");
		
		HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
		//Some infected attacks events
		HookEvent("tongue_grab", EventTongueGrab, EventHookMode_Post);
		HookEvent("lunge_pounce", EventPlayerPounced, EventHookMode_Post);
		HookEvent("charger_pummel_start", EventPlayerPummeled, EventHookMode_Post);
		HookEvent("jockey_ride", EventPlayerJockeyed, EventHookMode_Post);
		
	}
	else
	{
		SetFailState("This plugin works only with Left 4 Dead and Left 4 Dead 2!");
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{ 	
	if(GetConVarInt(cvarAdvertDelay) != 0)
	{
		CreateTimer(GetConVarFloat(cvarAdvertDelay), Advert);
	}
}

public Action:Advert(Handle:timer)
{
	PrintToChatAll(ADVERT);
}

public EventTongueGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarDropOnSmoker))
	{
		new client = GetClientOfUserId(GetEventInt(event, "victim"));
		DropItem(client);
	}
}

public EventPlayerPounced(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarDropOnHunter))
	{
		new client = GetClientOfUserId(GetEventInt(event, "victim"));
		DropItem(client);
	}
}

public EventPlayerPummeled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarDropOnCharger))
	{
		new client = GetClientOfUserId(GetEventInt(event, "victim"));
		DropItem(client);
	}
}

public EventPlayerJockeyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarDropOnJockey))
	{
		new client = GetClientOfUserId(GetEventInt(event, "victim"));
		DropItem(client);
	}
}

//The following code is from l4d2_drop, http://forums.alliedmods.net/showthread.php?p=1136497
public Action:DropItem(client)
{
	if (client == 0 || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return Plugin_Handled;

	new String:weapon[32];
	GetClientWeapon(client, weapon, 32);

	if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_hunting_rifle") || StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5") || StrEqual(weapon, "weapon_shotgun_spas") || StrEqual(weapon, "weapon_shotgun_chrome") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47") || StrEqual(weapon, "weapon_grenade_launcher") || StrEqual(weapon, "weapon_rifle_m60"))
		DropSlot(client, 0);
	else if (StrEqual(weapon, "weapon_pipe_bomb") || StrEqual(weapon, "weapon_molotov") || StrEqual(weapon, "weapon_vomitjar"))
		DropSlot(client, 2);
	else if (StrEqual(weapon, "weapon_first_aid_kit") || StrEqual(weapon, "weapon_defibrillator") || StrEqual(weapon, "weapon_upgradepack_explosive") || StrEqual(weapon, "weapon_upgradepack_incendiary"))
		DropSlot(client, 3);
	else if (StrEqual(weapon, "weapon_pain_pills") || StrEqual(weapon, "weapon_adrenaline"))
		DropSlot(client, 4);

	if (GetConVarInt(cvarShowInfo)==1)
	{
		PrintToChat(client, "%t", "dropped");
	}
	else	if (GetConVarInt(cvarShowInfo)==2)
	{
		PrintHintText(client, "%t", "dropped");
	}

	return Plugin_Handled;
}

public DropSlot(client, slot)
{
	if (GetPlayerWeaponSlot(client, slot) > 0)
	{
		new String:weapon[32];
		new ammo;
		new clip;
		new upgrade;
		new upammo;
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(GetPlayerWeaponSlot(client, slot), weapon, 32);

		if (slot == 0)
		{
			clip = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1");
			upgrade = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_upgradeBitVec");
			upammo = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
			if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
			{
				ammo = GetEntData(client, ammoOffset+(12));
				SetEntData(client, ammoOffset+(12), 0);
			}
			else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
			{
				ammo = GetEntData(client, ammoOffset+(20));
				SetEntData(client, ammoOffset+(20), 0);
			}
			else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
			{
				ammo = GetEntData(client, ammoOffset+(28));
				SetEntData(client, ammoOffset+(28), 0);
			}
			else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
			{
				ammo = GetEntData(client, ammoOffset+(32));
				SetEntData(client, ammoOffset+(32), 0);
			}
			else if (StrEqual(weapon, "weapon_hunting_rifle"))
			{
				ammo = GetEntData(client, ammoOffset+(36));
				SetEntData(client, ammoOffset+(36), 0);
			}
			else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
			{
				ammo = GetEntData(client, ammoOffset+(40));
				SetEntData(client, ammoOffset+(40), 0);
			}
			else if (StrEqual(weapon, "weapon_grenade_launcher"))
			{
				ammo = GetEntData(client, ammoOffset+(68));
				SetEntData(client, ammoOffset+(68), 0);
			}
		}
		new index = CreateEntityByName(weapon);
		new Float:origin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		origin[2]+=20;
		TeleportEntity(index, origin, NULL_VECTOR, NULL_VECTOR);

		if (slot == 1)
		{
			if (StrEqual(weapon, "weapon_melee"))
			{
				new String:item[150];
				GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_ModelName", item, sizeof(item));
				//PrintToChat(client, "%s", item);
				if (StrEqual(item, MODEL_V_FIREAXE))
				{
					DispatchKeyValue(index, "model", MODEL_V_FIREAXE);
					DispatchKeyValue(index, "melee_script_name", "fireaxe")
;
				}
				else if (StrEqual(item, MODEL_V_FRYING_PAN))
				{
					DispatchKeyValue(index, "model", MODEL_V_FRYING_PAN);
					DispatchKeyValue(index, "melee_script_name", "frying_pan")
;
				}
				else if (StrEqual(item, MODEL_V_MACHETE))
				{
					DispatchKeyValue(index, "model", MODEL_V_MACHETE);
					DispatchKeyValue(index, "melee_script_name", "machete")
;
				}
				else if (StrEqual(item, MODEL_V_BASEBALL_BAT))
				{
					DispatchKeyValue(index, "model", MODEL_V_BASEBALL_BAT);
					DispatchKeyValue(index, "melee_script_name", "baseball_bat")
;
				}
				else if (StrEqual(item, MODEL_V_CROWBAR))
				{
					DispatchKeyValue(index, "model", MODEL_V_CROWBAR);
					DispatchKeyValue(index, "melee_script_name", "crowbar")
;
				}
				else if (StrEqual(item, MODEL_V_CRICKET_BAT))
				{
					DispatchKeyValue(index, "model", MODEL_V_CRICKET_BAT);
					DispatchKeyValue(index, "melee_script_name", "cricket_bat")
;
				}
				else if (StrEqual(item, MODEL_V_TONFA))
				{
					DispatchKeyValue(index, "model", MODEL_V_TONFA);
					DispatchKeyValue(index, "melee_script_name", "tonfa")
;
				}
				else if (StrEqual(item, MODEL_V_KATANA))
				{
					DispatchKeyValue(index, "model", MODEL_V_KATANA);
					DispatchKeyValue(index, "melee_script_name", "katana")
;
				}
				else if (StrEqual(item, MODEL_V_ELECTRIC_GUITAR))
				{
					DispatchKeyValue(index, "model", MODEL_V_ELECTRIC_GUITAR);
					DispatchKeyValue(index, "melee_script_name", "electric_guitar")
;
				}
				else if (StrEqual(item, MODEL_V_GOLFCLUB))
				{
					DispatchKeyValue(index, "model", MODEL_V_GOLFCLUB);
					DispatchKeyValue(index, "melee_script_name", "golfclub")
;
				}
			}
			else if (StrEqual(weapon, "weapon_chainsaw"))
			{
				clip = GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iClip1");
			}
			else if (StrEqual(weapon, "weapon_pistol") && (GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_isDualWielding") > 0))
			{
				new indexC = CreateEntityByName(weapon);
				TeleportEntity(indexC, origin, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(indexC);
				ActivateEntity(indexC);
			}
		}

		DispatchSpawn(index);
		ActivateEntity(index);
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, slot));

		if (slot == 0)
		{
			SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
			SetEntProp(index, Prop_Send, "m_iClip1", clip);
			SetEntProp(index, Prop_Send, "m_upgradeBitVec", upgrade);
			SetEntProp(index, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", upammo);
		}

		if (slot == 1)
		{
			if (StrEqual(weapon, "weapon_chainsaw"))
			{
				SetEntProp(index, Prop_Send, "m_iClip1", clip);
			}
		}
	}
}