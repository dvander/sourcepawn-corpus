#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

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
			HookEvent("player_hurt", Events);
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
			UnhookEvent("player_hurt", Events);
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

public void OnClientPutInServer(int client)
{
	if(plugin.bHooked && client > 0)
	{
		SDKHook(client, SDKHook_WeaponDropPost, WeaponsOnDropPost);
	}
}

Action WeaponsOnDropPost(int client, int weapon)
{
	if(plugin.bHooked && IsValidSurv(client) && plugin.bGivenGun[client])
	{
		if(IsValidEntity(weapon) && IsValidEdict(weapon))
		{
			float origin[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
			origin[2] += 20;
			char cWeaponDrop[32];
			GetEdictClassname(weapon, cWeaponDrop, sizeof(cWeaponDrop));
			if(StrEqual(cWeaponDrop, "weapon_molotov", false))
			{
				RemoveEdict(weapon);
				L4D_MolotovPrj(client, origin, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
			}
			else if(StrEqual(cWeaponDrop, "weapon_pipe_bomb", false))
			{
				RemoveEdict(weapon);
				L4D_PipeBombPrj(client, origin, NULL_VECTOR, true, NULL_VECTOR, NULL_VECTOR);
			}
			else if(StrEqual(cWeaponDrop, "weapon_vomitjar", false))
			{
				RemoveEdict(weapon);
				L4D2_VomitJarPrj(client, origin, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
	return Plugin_Continue;
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
	if (strcmp(name, "round_start") == 0 || strcmp(name, "mission_lost") == 0 || strcmp(name, "round_end") == 0 || strcmp(name, "map_transition") == 0)
	{
        for (int i = 1; i <= MaxClients; i++) 
        {
            if (IsClientInGame(i)) 
            {
                plugin.bGivenGun[i] = false;
            }
        }
	}
	else if(strcmp(name, "player_hurt") == 0)
	{
		if (L4D2_IsTankInPlay())
		{
			int client = GetClientOfUserId(event.GetInt("userid"));
			int attacker = GetClientOfUserId(event.GetInt("attacker"));
			if (IsValidSurv(client) && IsValidTank(attacker))
			{
				if (!L4D_IsPlayerIncapacitated(client))
				{
					DropWep(client);
				}
			}
		}
	}
	else if(strcmp(name, "player_incapacitated_start") == 0)
	{
		if (L4D2_IsTankInPlay())
		{
			int client = GetClientOfUserId(event.GetInt("userid"));
			int attacker = GetClientOfUserId(event.GetInt("attacker"));
			if(IsValidSurv(client) && IsValidTank(attacker))
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
		if (IsValidSurv(client) && plugin.bGivenGun[client])
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

stock void DropWep(int client)
{
	int iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(iActiveWeapon != -1 && IsValidEntity(iActiveWeapon) && IsValidEdict(iActiveWeapon))
	{
		char cWeapon[32];
		GetEdictClassname(iActiveWeapon, cWeapon, sizeof(cWeapon));
		if(!StrEqual(cWeapon, "weapon_pistol", false))
		{
			SDKHooks_DropWeapon(client, iActiveWeapon, NULL_VECTOR, NULL_VECTOR);
			if(plugin.bGivePistol && GetPlayerWeaponSlot(client, L4DWeaponSlot_Secondary) == -1)
			{
				GivePlayerItem(client, "weapon_pistol");
			}
			plugin.bGivenGun[client] = true;
		}
	}
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client);
}

stock bool IsValidSurv(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == L4D_TEAM_SURVIVOR;
}

stock bool IsValidTank(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == L4D_TEAM_INFECTED && GetEntProp(client, Prop_Send, "m_zombieClass") == L4D2_ZOMBIE_CLASS_TANK;
}
