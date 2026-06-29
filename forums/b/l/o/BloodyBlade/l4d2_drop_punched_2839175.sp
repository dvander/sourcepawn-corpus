#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY
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
#define MODEL_V_PITCHFORK "models/weapons/melee/v_pitchfork.mdl"
#define MODEL_V_SHOVEL "models/weapons/melee/v_shovel.mdl"

public Plugin myinfo =
{
	name = "[L4D2] Drop weapon when punched",
	author = "cheewongken",
	description = "Survivors will drop their weapon when they get punched by a tank.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if(engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead2\" game.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

PluginData plugin;

enum struct PluginCvars
{
	ConVar c_dwp_enabled;
	ConVar c_dwp_drop_incapped;
	ConVar c_dwp_drop_melee;
	ConVar c_dwp_give_pistol;
	ConVar c_dwp_drop_chainsaw;

	void Init()
	{
		CreateConVar("l4d2_dwp_version", PLUGIN_VERSION, "Version of [L4D2] Drop weapon when punched", CVAR_FLAGS|FCVAR_DONTRECORD);
		this.c_dwp_enabled = CreateConVar("l4d2_dwp_enabled", "1", "Is plugin enabled? 1=Yes, 0=No", CVAR_FLAGS);
		this.c_dwp_drop_incapped = CreateConVar("l4d2_dwp_drop_when_incapped", "0", "Will you drop weapon if you get incapped? 1=Yes, 0=No", CVAR_FLAGS);
		this.c_dwp_drop_melee = CreateConVar("l4d2_dwp_drop_melee", "1", "Will you drop melee weapon if you get hit? 1=Yes, 0=No", CVAR_FLAGS);
		this.c_dwp_give_pistol = CreateConVar("l4d2_dwp_give_pistol", "1", "Will you get a pistol if you drop your melee weapon? 1=Yes, 0=No", CVAR_FLAGS);
		this.c_dwp_drop_chainsaw = CreateConVar("l4d2_dwp_drop_chainsaw", "1", "Will you drop chainsaw if you get hit? 1=Yes, 0=No", CVAR_FLAGS);

		AutoExecConfig(true, "l4d2_drop_when_punched");
		
		this.c_dwp_enabled.AddChangeHook(OnConVarPluginOnChange);
		this.c_dwp_drop_incapped.AddChangeHook(ConVarChanged_Cvars);
		this.c_dwp_drop_melee.AddChangeHook(ConVarChanged_Cvars);
		this.c_dwp_give_pistol.AddChangeHook(ConVarChanged_Cvars);
		this.c_dwp_drop_chainsaw.AddChangeHook(ConVarChanged_Cvars);
	}
}

enum struct PluginData
{
	PluginCvars cvars;
	bool bHooked;
	bool bPluginOn;
	bool bDropIncapped;
	bool bDropMelee;
	bool bGivePistol;
	bool bDropChainsaw;
	bool bGivenGun[MAXPLAYERS + 1];
	int iTanksInGame;

	void Init()
	{
		this.cvars.Init();
	}

	void GetCvarValues()
	{
		this.bDropIncapped = this.cvars.c_dwp_drop_incapped.BoolValue;
		this.bDropMelee = this.cvars.c_dwp_drop_melee.BoolValue;
		this.bGivePistol = this.cvars.c_dwp_give_pistol.BoolValue;
		this.bDropChainsaw = this.cvars.c_dwp_drop_chainsaw.BoolValue;
	}

	void IsAllowed()
	{
		this.bPluginOn = this.cvars.c_dwp_enabled.BoolValue;
		if(!this.bHooked && this.bPluginOn)
		{
			this.bHooked = true;
			HookEvent("round_start", Events, EventHookMode_Pre);
			HookEvent("mission_lost", Events, EventHookMode_Pre);
			HookEvent("round_end", Events, EventHookMode_Pre);
			HookEvent("map_transition", Events, EventHookMode_Pre);
			HookEvent("tank_spawn", Events);
			HookEvent("player_hurt", Events);
			HookEvent("player_death", Events);
			HookEvent("player_incapacitated_start", Events);
			HookEvent("item_pickup", Events);
		}
		else if(this.bHooked && !this.bPluginOn)
		{
			this.bHooked = false;
			UnhookEvent("round_start", Events, EventHookMode_Pre);
			UnhookEvent("mission_lost", Events, EventHookMode_Pre);
			UnhookEvent("round_end", Events, EventHookMode_Pre);
			UnhookEvent("map_transition", Events, EventHookMode_Pre);
			UnhookEvent("tank_spawn", Events);
			UnhookEvent("player_hurt", Events);
			UnhookEvent("player_death", Events);
			UnhookEvent("player_incapacitated_start", Events);
			UnhookEvent("item_pickup", Events);
		}
	}
}

public void OnPluginStart()
{	
	plugin.Init();
}

public void OnConfigsExecuted()
{
	plugin.IsAllowed();
	plugin.GetCvarValues();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.IsAllowed();
}

void ConVarChanged_Cvars(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.GetCvarValues();
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
	if (strcmp(name, "round_start") == 0 || strcmp(name, "mission_lost") == 0 || strcmp(name, "round_end") == 0 || strcmp(name, "map_transition") == 0)
	{
		plugin.iTanksInGame = 0;
	}
	else if(strcmp(name, "tank_spawn") == 0)
	{
		plugin.iTanksInGame++;
	}
	else if(strcmp(name, "player_hurt") == 0)
	{
		if (plugin.iTanksInGame != 0)
		{
			int client = GetClientOfUserId(event.GetInt("userid"));
			int attacker = GetClientOfUserId(event.GetInt("attacker"));
			if (IsValidSurv(client) && IsValidTank(attacker))
			{
				if (!IsPlayerIncapped(client))
				{
					DropWep(client);
				}
			}
		}
	}
	else if(strcmp(name, "player_death") == 0)
	{
		int iTank = 0;
		iTank = GetClientOfUserId(event.GetInt("userid"));
		if(iTank == 0)
		{
			iTank = event.GetInt("entityid");
		}

		if(iTank > 0)
		{
			plugin.iTanksInGame--;
			if (plugin.iTanksInGame == 0)
			{
				int client = Misc_GetAnyClient();
				if (client > 0)
				{
					for (int i = 1; i <= MaxClients; i++) 
					{
						if (IsValidSurv(i))
						{
							plugin.bGivenGun[i] = false;
						}
					}
				}
			}
		}
	}
	else if(strcmp(name, "player_incapacitated_start") == 0)
	{
		if (plugin.iTanksInGame != 0)
		{
			int client = GetClientOfUserId(event.GetInt("userid"));
			int attacker = GetClientOfUserId(event.GetInt("attacker"));
			if(IsValidTank(attacker))
			{
				if (plugin.bDropIncapped)
				{
					DropWep(client);
				}
			}
		}
	}
	else if(strcmp(name, "item_pickup") == 0)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (plugin.bGivenGun[client])
		{
			char weapon[32];
			GetClientWeapon(client, weapon, 32);
			if (StrEqual(weapon, "weapon_melee") || StrEqual(weapon, "weapon_chainsaw") || StrEqual(weapon, "weapon_pistol_magnum"))
			{
				int ent22 = -1;
				int prev22 = 0;
				while ((ent22 = FindEntityByClassname(ent22, "weapon_pistol")) != -1)
				{
					if (prev22) RemoveEdict(prev22);
					prev22 = ent22;
				}
				if (prev22) RemoveEdict(prev22);
				plugin.bGivenGun[client] = false;
			}	
		}
	}
	return Plugin_Continue;
}

//The following code is from l4d2_drop, http://forums.alliedmods.net/showthread.php?p=1136497
stock void DropWep(int client)
{
	if (IsValidSurv(client))
	{
		char weapon[32];
		GetClientWeapon(client, weapon, 32);
		if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_hunting_rifle") || StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5") || StrEqual(weapon, "weapon_shotgun_spas") || StrEqual(weapon, "weapon_shotgun_chrome") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47") || StrEqual(weapon, "weapon_grenade_launcher") || StrEqual(weapon, "weapon_rifle_m60"))
		{
			DropSlot(client, 0);
		}
		else if (!IsPlayerIncapped(client))
		{
			if (plugin.bDropMelee)
			{
				if (StrEqual(weapon, "weapon_melee"))
				{
					DropSlot(client, 1);
					if (plugin.bGivePistol)
					{
						GivePlayerItem(client, "weapon_pistol");
						plugin.bGivenGun[client] = true;
					}
				}
			}
			if (plugin.bDropChainsaw)
			{
				if (StrEqual(weapon, "weapon_chainsaw"))
				{
					DropSlot(client, 1);
					if (plugin.bGivePistol)
					{
						GivePlayerItem(client, "weapon_pistol");
						plugin.bGivenGun[client] = true;
					}
				}
			}
		}
	}
}

stock void DropSlot(int client, int slot)
{
	if (GetPlayerWeaponSlot(client, slot) > 0)
	{
		char weapon[32];
		int ammo = 0;
		int clip = 0;
		int upgrade = 0;
		int upammo = 0;
		int ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(GetPlayerWeaponSlot(client, slot), weapon, 32);

		if (slot == 0)
		{
			clip = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1");
			upgrade = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_upgradeBitVec");
			upammo = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
			if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
			{
				ammo = GetEntData(client, ammoOffset + (12));
				SetEntData(client, ammoOffset + (12), 0);
			}
			else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
			{
				ammo = GetEntData(client, ammoOffset + (20));
				SetEntData(client, ammoOffset + (20), 0);
			}
			else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
			{
				ammo = GetEntData(client, ammoOffset + (28));
				SetEntData(client, ammoOffset + (28), 0);
			}
			else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
			{
				ammo = GetEntData(client, ammoOffset + (32));
				SetEntData(client, ammoOffset + (32), 0);
			}
			else if (StrEqual(weapon, "weapon_hunting_rifle"))
			{
				ammo = GetEntData(client, ammoOffset + (36));
				SetEntData(client, ammoOffset + (36), 0);
			}
			else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
			{
				ammo = GetEntData(client, ammoOffset + (40));
				SetEntData(client, ammoOffset + (40), 0);
			}
			else if (StrEqual(weapon, "weapon_grenade_launcher"))
			{
				ammo = GetEntData(client, ammoOffset + (68));
				SetEntData(client, ammoOffset + (68), 0);
			}
		}
		int index = CreateEntityByName(weapon);
		float origin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		origin[2] += 20;
		TeleportEntity(index, origin, NULL_VECTOR, NULL_VECTOR);

		if (slot == 1)
		{
			if (StrEqual(weapon, "weapon_melee"))
			{
				char item[150];
				GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_ModelName", item, sizeof(item));
				//PrintToChat(client, "%s", item);
				if (StrEqual(item, MODEL_V_FIREAXE))
				{
					DispatchKeyValue(index, "model", MODEL_V_FIREAXE);
					DispatchKeyValue(index, "melee_script_name", "fireaxe");
				}
				else if (StrEqual(item, MODEL_V_FRYING_PAN))
				{
					DispatchKeyValue(index, "model", MODEL_V_FRYING_PAN);
					DispatchKeyValue(index, "melee_script_name", "frying_pan");
				}
				else if (StrEqual(item, MODEL_V_MACHETE))
				{
					DispatchKeyValue(index, "model", MODEL_V_MACHETE);
					DispatchKeyValue(index, "melee_script_name", "machete");
				}
				else if (StrEqual(item, MODEL_V_BASEBALL_BAT))
				{
					DispatchKeyValue(index, "model", MODEL_V_BASEBALL_BAT);
					DispatchKeyValue(index, "melee_script_name", "baseball_bat");
				}
				else if (StrEqual(item, MODEL_V_CROWBAR))
				{
					DispatchKeyValue(index, "model", MODEL_V_CROWBAR);
					DispatchKeyValue(index, "melee_script_name", "crowbar");
				}
				else if (StrEqual(item, MODEL_V_CRICKET_BAT))
				{
					DispatchKeyValue(index, "model", MODEL_V_CRICKET_BAT);
					DispatchKeyValue(index, "melee_script_name", "cricket_bat");
				}
				else if (StrEqual(item, MODEL_V_TONFA))
				{
					DispatchKeyValue(index, "model", MODEL_V_TONFA);
					DispatchKeyValue(index, "melee_script_name", "tonfa");
				}
				else if (StrEqual(item, MODEL_V_KATANA))
				{
					DispatchKeyValue(index, "model", MODEL_V_KATANA);
					DispatchKeyValue(index, "melee_script_name", "katana");
				}
				else if (StrEqual(item, MODEL_V_ELECTRIC_GUITAR))
				{
					DispatchKeyValue(index, "model", MODEL_V_ELECTRIC_GUITAR);
					DispatchKeyValue(index, "melee_script_name", "electric_guitar");
				}
				else if (StrEqual(item, MODEL_V_GOLFCLUB))
				{
					DispatchKeyValue(index, "model", MODEL_V_GOLFCLUB);
					DispatchKeyValue(index, "melee_script_name", "golfclub");
				}
				else if (StrEqual(item, MODEL_V_PITCHFORK))
				{
					DispatchKeyValue(index, "model", MODEL_V_PITCHFORK);
					DispatchKeyValue(index, "melee_script_name", "pitchfork");
				}
				else if (StrEqual(item, MODEL_V_SHOVEL))
				{
					DispatchKeyValue(index, "model", MODEL_V_SHOVEL);
					DispatchKeyValue(index, "melee_script_name", "shovel");
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

stock int Misc_GetAnyClient()
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i)) 
		{
			return i;
		}
	}
	return 0;
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client);
}

stock bool IsValidSurv(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 2;
}

stock bool IsValidTank(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8;
}

stock bool IsPlayerIncapped(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}
