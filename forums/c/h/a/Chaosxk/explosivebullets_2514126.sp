/*	
[CSGO] Explosive Bullets
Current Version: 2.2

Version Log:
2.2 - 
- Fixed memory leak in kv config
- Fixed logic giving explosive bullets on non warm-up rounds?
- Cleaned up some code and syntax
2.1 -
- Updated/Fixed flag/commands not properly giving explosive bullets to guns
- Added convar sm_eb_warmup which will enable explosive bullets on all weapons during warmup round
- Added convar sm_eb_roundend which will enable explosive bullets on all weapons during the round end bonus time
- Added command sm_ebme/sm_explosivebulletsme which will enable explosive bullets on yourself only

2.0 - Rewritten code
- No longer creates an explosion with env_explosion entity (FPS heavy), now creates a custom made explosion (Less FPS intensive)
- Explosion is now created with temp entities/sounds and plugin does all calculation of damage (See new video)
- Explosion now does less damage the further you are away the impact
- The new explosion effect will not hurt FPS as much as env_explosion entity did
- You can now enable/disable and set damage/radius for each specific weapon from the new configuration file at sourcemod/configs/explosivebullets_guns.cfg
- Removed the convars sm_eb_damage and sm_eb_radius
- Shotguns no longer plays extra sounds from the explosion per bullet (There will still be multiple explosion from shotguns, but not multiple sounds)
- sm_eb and sm_explosivebullets can turn on explosive bullets for ALL weapons reguardless if that weapon is disabled in the configs
*/ 
#pragma semicolon 1

#define PLUGIN_VERSION "2.2"
#define CS_SLOT_PRIMARY 0
#define CS_SLOT_SECONDARY 1
#define DISTORTION "explosion_child_distort01b"
#define FLASH "explosion_child_core04b"
#define SMOKE "impact_dirt_child_smoke_puff"
#define DIRT "impact_dirt_child_clumps"
//#define SOUND "weapons/sensorgrenade/sensor_explode.wav"
#define SOUND "weapons/revolver/revolver-1_01.wav"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

ConVar g_cEnabled, g_cWarmUp, g_cRoundEnd;
bool g_bOverride[MAXPLAYERS + 1];
bool g_bExplode[MAXPLAYERS + 1];
float g_fDamage[MAXPLAYERS + 1];
float g_fRadius[MAXPLAYERS + 1];
bool g_bAccess[MAXPLAYERS + 1];

ArrayList g_hArray;
bool g_bRoundEnabled;

public Plugin myinfo = 
{
	name = "[CS:GO] Explosive Bullets",
	author = "Tak (Chaosxk)",
	description = "Your bullets will explode on impact.",
	version = PLUGIN_VERSION,
	url = "https://github.com/xcalvinsz/explosivebullets"
};

public void OnPluginStart()
{
	CreateConVar("sm_eb_version", PLUGIN_VERSION, "Version for explosive bullets.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_cEnabled = CreateConVar("sm_eb_enabled", "1", "Enables/Disables this plugin.");
	g_cWarmUp = CreateConVar("sm_eb_warmup", "1", "If set to 1, explosive bullets will be enabled for everyone during warmup round otherwise 0 to turn off.");
	g_cRoundEnd = CreateConVar("sm_eb_roundend", "1", "If set to 1, explosive bullets will be enabled for everyone when round ends and is waiting for the next round restart otherwise 0 to turn off.");
	
	RegAdminCmd("sm_eb", Command_Explode, ADMFLAG_GENERIC, "Enables explosive bullets on players.");
	RegAdminCmd("sm_explosivebullets", Command_Explode, ADMFLAG_GENERIC, "Enables explosive bullets on players.");
	RegAdminCmd("sm_ebme", Command_ExplodeMe, ADMFLAG_GENERIC, "Enables explosive bullets on yourself.");
	RegAdminCmd("sm_explosivebulletsme", Command_ExplodeMe, ADMFLAG_GENERIC, "Enables explosive bullets on yourself.");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	//Hook bullet impact to create the explosion effect, each bullet counts...even shotguns
	HookEvent("bullet_impact", Event_BulletImpact);
	//Hook another bullet event but does not calculate the extra bullets from shotguns, this is used so EmitAmbientSound doesn't get played more than once
	AddTempEntHook("Shotgun Shot", Hook_BulletShot);
	
	g_hArray = new ArrayList();
	AutoExecConfig(true, "explosivebullets");
}

public void OnMapStart()
{
	PrecacheEffect("ParticleEffect");
	PrecacheParticleEffect(DISTORTION);
	PrecacheParticleEffect(FLASH);
	PrecacheParticleEffect(SMOKE);
	PrecacheParticleEffect(DIRT);
	PrecacheSound(SOUND);
	
	g_bRoundEnabled = false;
}

public void OnConfigsExecuted()
{
	SetupKVFiles();
	
	//Handles loading cache data when plugins get reloaded mid-game
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
			
		OnClientPostAdminCheck(i);
		
		if (!IsPlayerAlive(i))
			continue;
			
		int weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
		Hook_WeaponSwitch(i, weapon);
	}
}

public void OnClientPostAdminCheck(int client)
{
	g_bOverride[client] = false;
	SDKHook(client, SDKHook_WeaponCanSwitchTo, Hook_WeaponSwitch);
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	if (part == AdminCache_Admins)
	{
		RequestFrame(Frame_AdminCache, 0);
	}
}

public void Frame_AdminCache(any data)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
			
		char weaponname[32];
		GetClientWeapon(i, weaponname, sizeof(weaponname));
		UpdateClientCache(i, weaponname);
	}
}

public Action Command_Explode(int client, int args)
{
	if (!g_cEnabled.BoolValue)
	{
		ReplyToCommand(client, "[SM] This plugin is disabled.");
		return Plugin_Handled;
	}
	
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_eb <client> <1:ON | 0:OFF>");
		return Plugin_Handled;
	}
	
	char arg1[64], arg2[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	bool button = !!StringToInt(arg2);
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToCommand(client, "[SM] Can not find client.");
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		if(1 <= target_list[i] <= MaxClients && IsClientInGame(target_list[i]))
		{
			g_bOverride[target_list[i]] = button;
		}
	}
	
	if (tn_is_ml)
		ShowActivity2(client, "[SM] ", "%N has %s %t explosive bullets.", client, button ? "given" : "removed", target_name);
	else
		ShowActivity2(client, "[SM] ", "%N has %s %s explosive bullets.", client, button ? "given" : "removed", target_name);
		
	return Plugin_Handled;
}

public Action Command_ExplodeMe(int client, int args)
{
	if (!g_cEnabled.BoolValue)
	{
		ReplyToCommand(client, "[SM] This plugin is disabled.");
		return Plugin_Handled;
	}
	
	g_bOverride[client] = !g_bOverride[client];
	ReplyToCommand(client, "[SM] You have %s explosive bullets.", g_bOverride[client] ? "enabled" : "disabled");
	return Plugin_Handled;
}

public void Hook_WeaponSwitch(int client, int weapon)
{
	if (weapon == -1)
		return;
		
	char weaponname[32];
	GetEntityClassname(weapon, weaponname, sizeof(weaponname));
	UpdateClientCache(client, weaponname);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundEnabled = false;
	
	if (!g_cEnabled.BoolValue)
		return Plugin_Continue;
	
	if (GameRules_GetProp("m_bWarmupPeriod") && g_cWarmUp.BoolValue)
	{
		g_bRoundEnabled = true;
	}
	
	return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cEnabled.BoolValue)
		return Plugin_Continue;
		
	if (g_cRoundEnd.BoolValue)
	{	
		g_bRoundEnabled = true;
	}
	
	return Plugin_Continue;
}

public Action Event_BulletImpact(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cEnabled.BoolValue)
		return Plugin_Continue;
		
	int client = GetClientOfUserId(event.GetInt("userid"));
		
	if (!g_bRoundEnabled && !g_bOverride[client] && !(g_bExplode[client] && g_bAccess[client]))
		return Plugin_Continue;
		
	float pos[3];
	pos[0] = event.GetFloat("x");
	pos[1] = event.GetFloat("y");
	pos[2] = event.GetFloat("z");
	
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	CS_CreateExplosion(client, weapon, g_fDamage[client], g_fRadius[client], pos);
	return Plugin_Continue;
}

public Action Hook_BulletShot(const char[] te_name, const int[] Players, int numClients, float delay)
{
	if (!g_cEnabled.BoolValue)
		return Plugin_Continue;
		
	int client = TE_ReadNum("m_iPlayer") + 1;
	
	if (!g_bRoundEnabled && !g_bOverride[client] && !(g_bExplode[client] && g_bAccess[client]))
		return Plugin_Continue;
		
	float pos[3], angles[3];
	TE_ReadVector("m_vecOrigin", pos);
	angles[0] = TE_ReadFloat("m_vecAngles[0]");
	angles[1] = TE_ReadFloat("m_vecAngles[1]");
	angles[2] = 0.0;
    
	float endpos[3];
	Handle trace = TR_TraceRayFilterEx(pos, angles, MASK_SHOT, RayType_Infinite, TR_DontHitSelf, client);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(endpos, trace);
	}
	delete trace;
	//Play the explosion sound
	EmitAmbientSound(SOUND, endpos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, SNDPITCH_HIGH);
	return Plugin_Continue;
}

public bool TR_DontHitSelf(int entity, int mask, any data)
{
	if (entity == data) 
		return false;
	return true;
}

void UpdateClientCache(int client, const char[] weaponname)
{
	for (int i = 0; i < g_hArray.Length; i++)
	{
		char buffer[32];
		DataPack pack = g_hArray.Get(i);
		pack.Reset();
		pack.ReadString(buffer, sizeof(buffer));
		
		if (!strcmp(buffer, weaponname))
		{
			//Update current cache values
			g_bExplode[client] = pack.ReadCell();
			g_fDamage[client] = pack.ReadFloat();
			g_fRadius[client] = pack.ReadFloat();
			g_bAccess[client] = CheckCommandAccess(client, "", (1 << pack.ReadCell()), true);
			break;
		}
	}
}

void CS_CreateExplosion(int attacker, int weapon, float damage, float radius, float pos[3])
{
	//Create temp entity particle explosion effects
	TE_DispatchEffect(DISTORTION, pos);
	TE_DispatchEffect(FLASH, pos);
	TE_DispatchEffect(SMOKE, pos);
	TE_DispatchEffect(DIRT, pos);
	
	//Hurt the players in the area of explosion
	for (int victim = 1; victim <= MaxClients; victim++)
	{
		if (!IsClientInGame(victim) || !IsPlayerAlive(victim))
			continue;
		
		float victim_pos[3];
		GetClientAbsOrigin(victim, victim_pos);
		
		float distance = GetVectorDistance(pos, victim_pos);
		
		if (distance <= radius)
		{
			//Calculate damage based of distance
			float result = Sine(((radius - distance) / radius) * (3.14159 / 2)) * damage;
			SDKHooks_TakeDamage(victim, attacker, attacker, result, DMG_BLAST, weapon, NULL_VECTOR, pos);
		}
	}
}

void TE_DispatchEffect(const char[] particle, float pos[3])
{
	TE_Start("EffectDispatch");
	TE_WriteFloatArray("m_vOrigin.x", pos, 3);
	TE_WriteFloatArray("m_vStart.x", pos, 3);
	TE_WriteNum("m_nHitBox", GetParticleEffectIndex(particle));
	TE_WriteNum("m_iEffectName", GetEffectIndex("ParticleEffect"));
	TE_SendToAll();
}

void PrecacheParticleEffect(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
		table = FindStringTable("ParticleEffectNames");
		
	bool save = LockStringTables(false);
	AddToStringTable(table, sEffectName);
	LockStringTables(save);
}

int GetParticleEffectIndex(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;

	if (table == INVALID_STRING_TABLE)
		table = FindStringTable("ParticleEffectNames");

	int iIndex = FindStringIndex(table, sEffectName);

	if (iIndex != INVALID_STRING_INDEX)
		return iIndex;

	return 0;
}

void PrecacheEffect(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
		table = FindStringTable("EffectDispatch");
		
	bool save = LockStringTables(false);
	AddToStringTable(table, sEffectName);
	LockStringTables(save);
}

int GetEffectIndex(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;

	if (table == INVALID_STRING_TABLE)
		table = FindStringTable("EffectDispatch");

	int iIndex = FindStringIndex(table, sEffectName);

	if (iIndex != INVALID_STRING_INDEX)
		return iIndex;

	return 0;
}

void SetupKVFiles()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/explosivebullets_guns.cfg");
	
	if (!FileExists(sPath))
		SetFailState("Can not find map filepath %s", sPath);
		
	KeyValues kv = new KeyValues("Explosive Bullets");
	kv.ImportFromFile(sPath);

	if (!kv.GotoFirstSubKey())
		SetFailState("Can not read file: %s", sPath);
	
	//Clear array of old data when map changes
	g_hArray.Clear();
	
	do
	{
		char weaponname[32], flagstring[2];
		int enable;
		float damage, radius;
		
		kv.GetSectionName(weaponname, sizeof(weaponname));
		enable = kv.GetNum("Enable", 0);
		damage = kv.GetFloat("Damage", 0.0);
		radius = kv.GetFloat("Radius", 0.0);
		kv.GetString("Flag", flagstring, sizeof(flagstring), "");
		
		int buffer = flagstring[0];
		AdminFlag flag;
		FindFlagByChar(buffer, flag);
		
		//Cache values
		DataPack pack = new DataPack();
		pack.WriteString(weaponname);
		pack.WriteCell(enable);
		pack.WriteFloat(damage);
		pack.WriteFloat(radius);
		pack.WriteCell(view_as<int>(flag));
		g_hArray.Push(pack);
		
	} while (kv.GotoNextKey());
	
	delete kv;
}