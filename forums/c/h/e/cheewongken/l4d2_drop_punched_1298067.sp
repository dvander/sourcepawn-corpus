#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS									FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_REPLICATED
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

public Plugin:myinfo =
{
	name = "[L4D2] Drop weapon when punched",
	author = "cheewongken",
	description = "Survivors will drop their weapon when they get punched by a tank.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new TanksInGame;
new GivenGun[MAXPLAYERS+1];
new Handle:c_dwp_enabled = INVALID_HANDLE;
new Handle:c_dwp_drop_incapped = INVALID_HANDLE;
new Handle:c_dwp_drop_melee = INVALID_HANDLE;
new Handle:c_dwp_give_pistol = INVALID_HANDLE;
new Handle:c_dwp_drop_chainsaw = INVALID_HANDLE;

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{		
		SetFailState("[SM] Plugin supports Left 4 Dead 2 only.");
	}
	
	CreateConVar("l4d2_dwp_version", PLUGIN_VERSION, "Version of [L4D2] Drop weapon when punched", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("round_start", RoundR, EventHookMode_Pre);
	HookEvent("round_end", RoundR, EventHookMode_Pre);
	HookEvent("tank_spawn", TankSpawned);
	HookEvent("player_hurt", PlayerHit);
	HookEvent("tank_killed", TankKilled);
	HookEvent("player_incapacitated_start", PlayerIncapped);
	HookEvent("item_pickup", Event_Pickup);
	
	c_dwp_enabled = CreateConVar("l4d2_dwp_enabled", "1", "Is plugin enabled? 1=Yes, 0=No", CVAR_FLAGS);
	c_dwp_drop_incapped = CreateConVar("l4d2_dwp_drop_when_incapped", "0", "Will you drop weapon if you get incapped? 1=Yes, 0=No", CVAR_FLAGS);
	c_dwp_drop_melee = CreateConVar("l4d2_dwp_drop_melee", "1", "Will you drop melee weapon if you get hit? 1=Yes, 0=No", CVAR_FLAGS);
	c_dwp_give_pistol = CreateConVar("l4d2_dwp_give_pistol", "1", "Will you get a pistol if you drop your melee weapon? 1=Yes, 0=No", CVAR_FLAGS);
	c_dwp_drop_chainsaw = CreateConVar("l4d2_dwp_drop_chainsaw", "1", "Will you drop chainsaw if you get hit? 1=Yes, 0=No", CVAR_FLAGS);
	AutoExecConfig(true, "l4d2_drop_when_punched");
}

public Action:RoundR(Handle:event, String:event_name[], bool:dontBroadcast)
{
	TanksInGame = 0;
}

public Action:TankSpawned(Handle:event, String:event_name[], bool:dontBroadcast)
{
	TanksInGame++;
}

public Action:TankKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
	TanksInGame--;
	if (TanksInGame == 0)
	{
		new client = Misc_GetAnyClient();
		if (client > 0)
		{
			for (new i = 1; i <= MaxClients; i++) 
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2)
				{
					GivenGun[i] = 0;
				}
			}
		}
	}
}

Misc_GetAnyClient()
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i)) 
		{
			return i;
		}
	}
	return 0;
}

public Action:PlayerHit(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (TanksInGame != 0)
	{
		if (GetConVarBool(c_dwp_enabled))
		{
			new client = GetClientOfUserId(GetEventInt(event,"userid"));
			new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
			if (IsValidClient(attacker) && GetClientTeam(client) == 2 && IsPlayerTank(attacker))
			{
				if (!(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)))
				{
					DropWep(client);
				}
			}
		}
	}
}

public Action:PlayerIncapped(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (TanksInGame != 0)
	{
		if (GetConVarBool(c_dwp_enabled))
		{
			new client = GetClientOfUserId(GetEventInt(event,"userid"));
			new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
			if(IsValidClient(attacker) && GetClientTeam(client) == 2 && IsPlayerTank(attacker))
			{
				if (GetConVarBool(c_dwp_drop_incapped))	DropWep(client);
			}
		}
	}
}

public Action:Event_Pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GivenGun[client] == 1)
	{
		new String:weapon[32];
		GetClientWeapon(client, weapon, 32);
		
		if (StrEqual(weapon, "weapon_melee") || StrEqual(weapon, "weapon_chainsaw") || StrEqual(weapon, "weapon_pistol_magnum"))
		{
			new ent22 = -1;
			new prev22 = 0;
			while ((ent22 = FindEntityByClassname(ent22, "weapon_pistol")) != -1)
			{
				if (prev22) RemoveEdict(prev22);
				prev22 = ent22;
			}
			if (prev22) RemoveEdict(prev22);
			GivenGun[client] = 0;
		}	
	}
}

public Action:GivePistol(client)
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give pistol");
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	GivenGun[client] = 1;
}

//The following code is from l4d2_drop, http://forums.alliedmods.net/showthread.php?p=1136497
public Action:DropWep(client)
{
	if (client == 0 || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return Plugin_Handled;

	new String:weapon[32];
	GetClientWeapon(client, weapon, 32);

	if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_hunting_rifle") || StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5") || StrEqual(weapon, "weapon_shotgun_spas") || StrEqual(weapon, "weapon_shotgun_chrome") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47") || StrEqual(weapon, "weapon_grenade_launcher") || StrEqual(weapon, "weapon_rifle_m60"))
		DropSlot(client, 0);
	else if (!(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)))
	{
		if (GetConVarBool(c_dwp_drop_melee))
		{
			if (StrEqual(weapon, "weapon_melee"))
			{
				DropSlot(client, 1);
				if (GetConVarBool(c_dwp_give_pistol))
					GivePistol(client);
			}
		}
		if (GetConVarBool(c_dwp_drop_chainsaw))
		{
			if (StrEqual(weapon, "weapon_chainsaw"))
			{
				DropSlot(client, 1);
				if (GetConVarBool(c_dwp_give_pistol))
					GivePistol(client);
			}
		}
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

public IsValidClient(i) // code from Mortiegama
{
	if (i == 0)
		return false;

	if (!IsClientConnected(i))
		return false;
	
	if (!IsClientInGame(i))
		return false;
	
	if (!IsPlayerAlive(i))
		return false;

	if (!IsValidEntity(i))
		return false;

	return true;
}

stock bool:IsPlayerTank(i) // code from Mecha the Slag
{
    new String:model[128]; 
    GetClientModel(i, model, sizeof(model));
    if (StrContains(model, "hulk", false) <= 0)  return false;
    return true;
}