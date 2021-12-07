#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =  {
	name = "[L4D2] Drop Grenade Launcher On Empty", 
	author = "Shadowysn", 
	description = "Makes the grenade launcher drop upon emptying.", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=258189"
}

#define DEBUG 0

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
	return APLRes_SilentFailure;
}

public void OnPluginStart()
{
	HookEvent("weapon_fire", Weapon_Fire, EventHookMode_Post);
	RegAdminCmd("sm_testremoveclip", Command_Test, ADMFLAG_CHEATS, "Test");
}

public Action Command_Test(client, args)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	SetEntProp(weapon, Prop_Send, "m_iClip1", 1);
	SetEntProp(weapon, Prop_Send, "m_iClip2", 1);
	return Plugin_Handled;
}

public Weapon_Fire(Handle event, const char[] name, bool dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("Weapon fired!");
	#endif
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	char wep_class[PLATFORM_MAX_PATH];
	GetEntityClassname(weapon, wep_class, sizeof(wep_class));
	if (IsSurvivor(client) && IsValidEntity(weapon) && StrEqual(wep_class, "weapon_grenade_launcher"))
	{
		#if DEBUG
		int cl_ammo_arraysize = GetEntPropArraySize(client, Prop_Send, "m_iAmmo");
		for (int i = 0; i <= (cl_ammo_arraysize-1); i++)
		{
			int result = GetEntProp(client, Prop_Send, "m_iAmmo", 2, i);
			if (result > 0)
			PrintToChatAll("ammo %i: %i", i, result);
		}
		#endif
		DataPack pack = new DataPack();
		pack.WriteCell(client);
		pack.WriteCell(weapon);
		RequestFrame(FrameCallback, pack);
	}
}

public void FrameCallback(DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int weapon = pack.ReadCell();
	CloseHandle(pack);
	if (!IsValidEntity(weapon) || !IsValidClient(client))
	{ return; }
	int clip1 = GetEntProp(weapon, Prop_Send, "m_iClip1");
	int ammo_Type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	int clip2 = GetEntProp(client, Prop_Send, "m_iAmmo", 2, ammo_Type);
	#if DEBUG
	PrintToChatAll("Request grenade launcher remove!");
	PrintToChatAll("%i", clip1);
	PrintToChatAll("%i", clip2);
	#endif
	char wep_class[PLATFORM_MAX_PATH];
	GetEntityClassname(weapon, wep_class, sizeof(wep_class));
	if (IsSurvivor(client) && IsValidEntity(weapon) && StrEqual(wep_class, "weapon_grenade_launcher") && (clip1 <= 0 && clip2 <= 0))
	{
		#if DEBUG
		PrintToChatAll("Request grenade launcher remove!");
		#endif
		//RequestFrame(FrameCallback, pack);
		RemoveEntity(weapon);
		int phys = CreateEntityByName("env_shooter");
		DispatchKeyValue(phys, "shootmodel", "models/w_models/weapons/w_grenade_launcher.mdl");
		float cl_pos[3];
		float cl_ang[3];
		GetClientEyePosition(client, cl_pos);
		GetClientEyeAngles(client, cl_ang);
		//cl_pos[2] = cl_pos[2]+50;
		TeleportEntity(phys, cl_pos, cl_ang, NULL_VECTOR);
		DispatchKeyValue(phys, "shootsounds", "-1");
		DispatchKeyValue(phys, "m_iGibs", "1");
		DispatchKeyValueVector(phys, "gibangles", cl_ang);
		DispatchKeyValue(phys, "gibanglevelocity", "20");
		DispatchKeyValue(phys, "m_flVelocity", "5.0");
		DispatchKeyValue(phys, "m_flVariance", "0.5");
		DispatchKeyValue(phys, "simulation", "1");
		DispatchKeyValue(phys, "m_flGibLife", "10");
		DispatchKeyValue(phys, "spawnflags", "4");
		
		DispatchSpawn(phys);
		ActivateEntity(phys);
		
		AcceptEntityInput(phys, "Shoot");
		SetVariantString("OnUser1 !self:Kill::0.1:1");
		AcceptEntityInput(phys, "AddOutput");
		AcceptEntityInput(phys, "FireUser1");
	}
}

stock bool IsSurvivor(client)
{
	if (IsValidClient(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 4))
	{
		return true;
	}
	return false;
}

stock bool IsValidClient(client)
{
	if (client > 0 && client < MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		return true;
	}
	return false;
}