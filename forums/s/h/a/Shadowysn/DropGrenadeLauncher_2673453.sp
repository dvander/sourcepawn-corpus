#define PLUGIN_NAME "[L4D2] Drop Empty Grenade Launcher"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Makes the grenade launcher drop upon emptying."
#define PLUGIN_VERSION "1.0.2"
#define PLUGIN_URL "https://forums.alliedmods.net/showpost.php?p=2673453&postcount=7"
#define PLUGIN_NAME_SHORT "Drop Empty Grenade Launcher"
#define PLUGIN_NAME_TECH "gl_drop_empty"

#include <sourcemod>
#include <sdktools>

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

#define DEBUG 0

public void OnPluginStart()
{
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	HookEvent("weapon_fire", Weapon_Fire, EventHookMode_Post);
	#if DEBUG
	RegAdminCmd("sm_testremoveclip", Command_Test, ADMFLAG_CHEATS, "Test");
	#endif
}

#if DEBUG
Action Command_Test(client, args)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	SetEntProp(weapon, Prop_Send, "m_iClip1", 1);
	SetEntProp(weapon, Prop_Send, "m_iClip2", 1);
	return Plugin_Handled;
}
#endif

void Weapon_Fire(Event event, const char[] name, bool dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("Weapon fired!");
	#endif
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (!IsValidClient(client) || !IsSurvivor(client) || !RealValidEntity(weapon)) return;
	static char classname[24];
	GetEntityClassname(weapon, classname, sizeof(classname));
	if (strcmp(classname, "weapon_grenade_launcher", false) != 0) return;
	
	#if DEBUG
	int cl_ammo_arraysize = GetEntPropArraySize(client, Prop_Send, "m_iAmmo");
	for (int i = 0; i <= (cl_ammo_arraysize-1); i++)
	{
		int result = GetEntProp(client, Prop_Send, "m_iAmmo", _, i);
		if (result > 0)
		PrintToChatAll("ammo %i: %i", i, result);
	}
	#endif
	
	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.WriteCell(weapon);
	RequestFrame(FrameCallback, pack);
}

void FrameCallback(DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int weapon = pack.ReadCell();
	if (pack != null) CloseHandle(pack);
	
	if (!IsValidClient(client) || !IsSurvivor(client) || !RealValidEntity(weapon)) return;
	
	int clip1 = GetEntProp(weapon, Prop_Send, "m_iClip1");
	int clip2 = GetEntProp(client, Prop_Send, "m_iAmmo", _, GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"));
	
	#if DEBUG
	PrintToChatAll("Request grenade launcher remove!");
	PrintToChatAll("%i", clip1);
	PrintToChatAll("%i", clip2);
	#endif
	
	if (clip1 > 0 || clip2 > 0) return;
	
	static char classname[24];
	GetEntityClassname(weapon, classname, sizeof(classname));
	if (strcmp(classname, "weapon_grenade_launcher", false) != 0) return;
	
	#if DEBUG
	PrintToChatAll("Request grenade launcher remove!");
	#endif
	//RequestFrame(FrameCallback, pack);
	
	AcceptEntityInput(weapon, "Kill");
	
	int phys = CreateEntityByName("env_shooter");
	DispatchKeyValue(phys, "shootmodel", "models/w_models/weapons/w_grenade_launcher.mdl");
	
	float cl_pos[3], cl_ang[3];
	GetClientEyePosition(client, cl_pos);
	GetClientEyeAngles(client, cl_ang);
	
	//cl_pos[2] = cl_pos[2]+50;
	TeleportEntity(phys, cl_pos, cl_ang, NULL_VECTOR);
	DispatchKeyValue(phys, "shootsounds", "-1");
	DispatchKeyValue(phys, "m_iGibs", "1");
	DispatchKeyValueVector(phys, "gibangles", cl_ang);
	DispatchKeyValue(phys, "gibanglevelocity", "10");
	DispatchKeyValue(phys, "m_flVelocity", "200.0");
	DispatchKeyValue(phys, "m_flVariance", "0.5");
	DispatchKeyValue(phys, "simulation", "1");
	DispatchKeyValue(phys, "m_flGibLife", "10");
	DispatchKeyValue(phys, "spawnflags", "4");
	
	DispatchSpawn(phys);
	ActivateEntity(phys);
	
	AcceptEntityInput(phys, "Shoot");
	DispatchKeyValue(phys, "OnUser1", "!self,Kill,,0.5,1");
	AcceptEntityInput(phys, "FireUser1");
}

bool IsSurvivor(int client)
{ return (GetClientTeam(client) == 2 || GetClientTeam(client) == 4); }

bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }

bool IsValidClient(int client, bool replaycheck = true, bool isLoop = false)
{
	if ((isLoop || client > 0 && client <= MaxClients) && IsClientInGame(client))
	{
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}