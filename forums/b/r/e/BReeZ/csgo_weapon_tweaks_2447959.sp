#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "CSGO Weapon Tweaks",
	author = "Keith Warren (Drixevel)",
	description = "Allows to tweak certain weapons while in use.",
	version = "1.0.3",
	url = "http://www.drixevel.com/"
};

ConVar g_cvNoSpread, g_cvRecoil;
bool replicated_spread[MAXPLAYERS + 1], replicated_recoil[MAXPLAYERS + 1];
bool lateload;

ArrayList hNoSpread;
ArrayList hNoRecoil;
ArrayList hDropshot;
StringMap hDamage;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    lateload = late;
}

public void OnPluginStart()
{
	g_cvNoSpread = FindConVar("weapon_accuracy_nospread");
	g_cvNoSpread.SetBool(false);
	g_cvRecoil = FindConVar("weapon_recoil_scale");
	
	HookEvent("weapon_fire", OnWeaponFire, EventHookMode_Pre);
	
	hNoSpread = new ArrayList(ByteCountToCells(64));
	hNoRecoil = new ArrayList(ByteCountToCells(64));
	hDropshot = new ArrayList(ByteCountToCells(64));
	hDamage = new StringMap();
	g_cvNoSpread.Flags &= ~FCVAR_REPLICATED;
    
	if(lateload)
        for (int i = 1; i <= MaxClients; i++)
			OnClientPostAdminCheck(i);
}

public void OnPluginEnd()
{
    g_cvNoSpread.Flags |= FCVAR_REPLICATED;
}

public void OnConfigsExecuted()
{
	ParseWeaponsConfig("configs/csgo_weapon_tweaks.cfg");
}

public void OnClientPostAdminCheck(int client)
{
    if(IsValidClient(client, false))
    {
        SDKHook(client, SDKHook_WeaponSwitchPost, WeaponSwitchPost);
        SDKHook(client, SDKHook_PreThink, PreThink);
        SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
        replicated_spread[client] = replicated_recoil[client] = false;
        g_cvNoSpread.ReplicateToClient(client, "0");
        g_cvRecoil.ReplicateToClient(client, "2.0");
    }
}

public void ParseWeaponsConfig(const char[] config)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), config);
	KeyValues kv = new KeyValues("csgo_weapon_tweaks");

	if (!kv.ImportFromFile(sPath) || !kv.GotoFirstSubKey())
	{
		LogError("Error loading weapon spread configurations.");
		return;
	}

	hNoSpread.Clear();
	hNoRecoil.Clear();
	hDropshot.Clear();
	hDamage.Clear();

	do 
	{
		char sEntity[64];
		kv.GetSectionName(sEntity, sizeof(sEntity));

		if (kv.GetNum("nospread") == 1)
		{
			hNoSpread.PushString(sEntity);
		}

		if (kv.GetNum("norecoil") == 1)
		{
			hNoRecoil.PushString(sEntity);
		}

		if (kv.GetNum("dropdown") == 1)
		{
			hDropshot.PushString(sEntity);
		}

		float fDamage = kv.GetFloat("damage");

		if (fDamage > 0.0)
		{
			hDamage.SetValue(sEntity, fDamage);
		}

	} while (kv.GotoNextKey());

	delete kv;
	LogMessage("Successfully parsed weapon spread configurations.");
}

public Action OnWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidClient(client, true))
		return;

	char sWeapon[32];
	event.GetString("weapon", sWeapon, sizeof(sWeapon));

	if (replicated_spread[client])
	{
		g_cvNoSpread.SetBool(true);
		RequestFrame(Frame_DisableNoSpread);
	}
}

public void Frame_DisableNoSpread()
{
	g_cvNoSpread.SetBool(false);
}

public void WeaponSwitchPost(int client, int weapon)
{
	if (!IsValidClient(client, true) || !IsValidEntity(weapon))
		return;
		
	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	
	if (hNoRecoil.FindString(sWeapon) != -1)
	{
		if (!replicated_recoil[client])
		{
			DataPack pack;
			CreateDataTimer(1.0, DisableRecoil, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(GetClientUserId(client));
			pack.WriteCell(true);
    	}
	}
	else
	{
    	if (replicated_recoil[client])
		{
			DataPack pack;
			CreateDataTimer(1.0, DisableRecoil, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(GetClientUserId(client));
			pack.WriteCell(false);
    	}
	}
	
	if (hNoSpread.FindString(sWeapon) != -1)
	{
		if (!replicated_spread[client])
		{
			g_cvNoSpread.ReplicateToClient(client, "1");
			replicated_spread[client] = true;
		}
	}
	else
	{
		if (replicated_spread[client])
		{
			g_cvNoSpread.ReplicateToClient(client, "0");
			replicated_spread[client] = false;
		}
	}
}

public Action DisableRecoil(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	
	if (!IsValidClient(client, true))
		return;
	
	bool norecoil = pack.ReadCell();
	
	if (norecoil)
	{
		g_cvRecoil.ReplicateToClient(client, "0.0");
	}
	else
	{
		g_cvRecoil.ReplicateToClient(client, "2.0");
	}
}

public void PreThink(int client)
{
	if (!IsValidClient(client, true))
		return;
		
	char sWeapon[32];
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (!IsValidEntity(weapon))
		return;
		
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
		
	if ((hDropshot.FindString(sWeapon) != -1) && (hNoSpread.FindString(sWeapon) == -1))
    {
    	bool dropshot = (GetEntProp(client, Prop_Send, "m_bIsScoped") && GetClientVelocity(client) < 50.0);
        g_cvNoSpread.BoolValue = dropshot;

        if (dropshot != replicated_spread[client])
        {
            g_cvNoSpread.ReplicateToClient(client, dropshot ? "1" : "0");
            replicated_spread[client] = dropshot;
        }
    }
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (!IsValidClient(attacker, true))
		return Plugin_Continue;
		
	char sWeapon[32];
	int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	
	if (!IsValidEntity(weapon))
		return Plugin_Continue;
		
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	
	float fDamage;
	if (hDamage.GetValue(sWeapon, fDamage))
	{
		damage += fDamage;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock float GetClientVelocity(int client)
{
	float vel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
	vel[2] = 0.0;
	return GetVectorLength(vel);
}

stock bool IsValidClient(int client, bool alive)
{
	if ((0 < client <= MaxClients) && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && !IsClientSourceTV(client))
	{
		return (alive ? IsPlayerAlive(client) : true);
	}
	return false;
}