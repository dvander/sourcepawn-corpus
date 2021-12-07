#define PLUGIN_VERSION "1.4"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D] Witch On Fire",
	author = "Alex Dragokas",
	description = "Witch is appearing in the fire when somebody throw a molotov",
	version = PLUGIN_VERSION,
	url = "https://dragokas.com"
};

/*
	ChangeLog
	
	1.4
	 - Fixed annoing rapidly repeatable scream witch sound that happen sometimes.
	 - Added forcing the witch to attack molotov thrower even if witch was not in fire (e.g. accidentally relocated by game)
	
	1.3
	 - Previous fix is replaced by sound hook variant (thanks to Lux).
	
	1.2 (unfinished)
	 - Previous fix is replaced by OnEntityDestroyed() method (thanks to MasterMind420) (doesn't fit my needs: too late to track "m_hOwnerEntity")
	
	1.1 (unfinished)
	 - Fixed case when event doesn't happen if molotov hits the car:
	 SDKHook OnStartTouch is replaced by simultaneous tracking of both "inferno" and "projectile" entities (thanks to BHaType).
	
	1.0
	 - Initial release.
	 
	 ==============================================================================================================================
	
	 Warning: Alpha-version !
	
	 Description:
	 
	 Everytime when you throw molotov you should be careful, because you can disturb the witch :) if you throw it too far.
	 Safe distance, chance, number of witches and spawn intervals are configurable.
	 
	 Credits:
	 
	 BHaType, MasterMind420, Lux - for different methods of identification of molotov inferno origin vector.
	 SilverShot - for example of "hurt" entity method.
	 
	 TODOs:
	 
	 - Add changing the velocity
	 - Add MORE fire
	 - Fix the witch sometimes lost the target when using point_hurt and client located too far (try delay the hurt).
	 
	 Bugs:
	 - Witch on fire event triggered when somebody break the gas canister (possibly, return to BHaType method, or hook "break" output).
	 - Too low values of "l4d_witch_on_fire_mininterval" can cause client crash (possibly, due to the sounds channel overload).
	 - infinite rapid scream sound of some witches spawned on fire ("fixed")
	 
	 Support:
	 - I don't plan to support this plugin anymore. Maybe, somebody wants to continue it.
	 
	 Compatibility:
	 - L4D1
	 - L4D2 (untested)
	 
*/

ConVar g_ConVarEnable;
ConVar g_ConVarChance;
ConVar g_ConVarDelayMin;
ConVar g_ConVarDelayMax;
ConVar g_ConVarWitchCountMin;
ConVar g_ConVarWitchCountMax;
ConVar g_ConVarIntervalMin;
ConVar g_ConVarIntervalMax;
ConVar g_ConVarMinSafeDist;

ConVar g_ConVarFlameLifeTime;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead && test != Engine_Left4Dead2) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_witch_on_fire_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD);

	g_ConVarEnable = CreateConVar("l4d_witch_on_fire_enabled", "1", "Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS);
	g_ConVarChance = CreateConVar("l4d_witch_on_fire_chance", "20", "Chance the witch is appear in molotov fire (1 to 100), 0 - to disable.", CVAR_FLAGS);
	g_ConVarDelayMin = CreateConVar("l4d_witch_on_fire_mindelay", "3", "Minimum time in sec. after molotov explosion when witches should appear (by default, 0 - 14).", CVAR_FLAGS);
	g_ConVarDelayMax = CreateConVar("l4d_witch_on_fire_maxdelay", "7", "Maximum time in sec. after molotov explosion when witches should appear (by default, 0 - 14).", CVAR_FLAGS);
	g_ConVarWitchCountMin = CreateConVar("l4d_witch_on_fire_count_min", "2", "Minimum number of witches to spawn in the fire", CVAR_FLAGS);
	g_ConVarWitchCountMax = CreateConVar("l4d_witch_on_fire_count_max", "3", "Maximum number of witches to spawn in the fire", CVAR_FLAGS);
	g_ConVarIntervalMin = CreateConVar("l4d_witch_on_fire_mininterval", "0.7", "Minimum time interval beetween each witch spawn (in sec.)", CVAR_FLAGS);
	g_ConVarIntervalMax = CreateConVar("l4d_witch_on_fire_maxinterval", "2.0", "Maximum time interval beetween each witch spawn (in sec.)", CVAR_FLAGS);
	g_ConVarMinSafeDist = CreateConVar("l4d_witch_on_fire_minsafedist", "700.0", "Minimum client distance to molotov explosion point in order to allow witch spawn event to begin", CVAR_FLAGS);
	
	g_ConVarFlameLifeTime = FindConVar("inferno_flame_lifetime");
	
	// FindConVar("inferno_spawn_angle");
	// FindConVar("inferno_max_range");
	// (cone), require math. calculation depending on eye view angle before throwing the molotov (or some another method to get the angle of molotov fly).
	
	AutoExecConfig(true, "l4d_witch_on_fire");
	
	//RegAdminCmd("sm_test", CmdTest, ADMFLAG_ROOT, "");
	
	GetCvars();
	HookConVarChange(g_ConVarEnable,		ConVarChanged);
	HookConVarChange(g_ConVarFlameLifeTime,	ConVarChanged);
	HookConVarChange(g_ConVarDelayMin,		ConVarChanged);
	HookConVarChange(g_ConVarDelayMax,		ConVarChanged);
}

/*
public Action CmdTest(int client, int args)
{
	return Plugin_Handled;
}
*/

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	// max. delay should fit in flame ignite time ( -1.0 to have a time before finishing igniting)
	if (g_ConVarDelayMax.FloatValue > (g_ConVarFlameLifeTime.FloatValue - 1.0)) {
		g_ConVarDelayMax.SetFloat(g_ConVarFlameLifeTime.FloatValue - 1.0);
	}
	if (g_ConVarDelayMin.FloatValue > g_ConVarDelayMax.FloatValue) {
		g_ConVarDelayMin.SetFloat(g_ConVarDelayMax.FloatValue);
	}
	InitHook();
}

void InitHook()
{
	static bool bHooked;
	
	if (g_ConVarEnable.BoolValue) {
		if (!bHooked) {
			AddNormalSoundHook(OnNormalSoundPlay);
			bHooked = true;
		}
	} else {
		if (bHooked) {
			RemoveNormalSoundHook(OnNormalSoundPlay);
			bHooked = false;
		}
	}
}

public Action OnNormalSoundPlay(int clients[MAXPLAYERS], int &numClients,
		char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level,
		int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	static float fScream = 0.0;

	if(entity < 0 || entity > 2048 || !IsValidEntity(entity))
		return Plugin_Continue;
	
	if(StrContains(sample, "molotov_detonate_3.wav", false) != -1)
	{
		if (GetRandomInt(1, 100) <= g_ConVarChance.IntValue)
			OnMolotovDetonate(entity);
	}
	
	// infinite rapid scream sound fix
	if (StrEqual(sample, "npc/witch/voice/attack/Female_DistantScream1.wav", false) ||
		StrEqual(sample, "npc/witch/voice/attack/Female_DistantScream2.wav", false)) {
		
		float fTime = GetEngineTime();
		if (fTime - fScream < 1.0) {
			fScream = fTime;
			return Plugin_Handled;
		}
		fScream = fTime;
	}
	return Plugin_Continue;
}

void OnMolotovDetonate(int iEntMolotov)
{
	int hOwner = GetEntPropEnt(iEntMolotov, Prop_Data, "m_hOwnerEntity");
	
	if (hOwner > 0) {
		float vecMolotovExplode[3], vecClientOrigin[3];
		
		GetEntPropVector(iEntMolotov, Prop_Data, "m_vecOrigin", vecMolotovExplode);
		
		if ((0 < hOwner <= MaxClients) && IsClientInGame(hOwner)) {
			
			GetClientAbsOrigin(hOwner, vecClientOrigin);
			
			if (GetVectorDistance(vecClientOrigin, vecMolotovExplode) > g_ConVarMinSafeDist.FloatValue)
			{
				vecMolotovExplode[0] += GetRandomFloat(0.0, 10.0);
				vecMolotovExplode[1] += GetRandomFloat(0.0, 10.0);
				vecMolotovExplode[2] += 20.0 + GetRandomFloat(0.0, 20.0);
			
				float fDelay = GetRandomFloat(g_ConVarDelayMin.FloatValue, g_ConVarDelayMax.FloatValue);
				
				DataPack hPack = new DataPack();
				hPack.WriteCell(GetRandomInt(g_ConVarWitchCountMin.IntValue, g_ConVarWitchCountMax.IntValue));
				hPack.WriteFloat(fDelay);
				hPack.WriteCell(hOwner);
				hPack.WriteFloat(vecMolotovExplode[0]);
				hPack.WriteFloat(vecMolotovExplode[1]);
				hPack.WriteFloat(vecMolotovExplode[2]);
				CreateTimer(fDelay, Timer_SpawnWitch, hPack, TIMER_DATA_HNDL_CLOSE | TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action Timer_SpawnWitch(Handle timer, DataPack hPack)
{
	hPack.Reset();
	int iWitches = hPack.ReadCell();
	float fDelay = hPack.ReadFloat();
	int iAttacker = hPack.ReadCell();
	float vecPrime[3];
	vecPrime[0] = hPack.ReadFloat();
	vecPrime[1] = hPack.ReadFloat();
	vecPrime[2] = hPack.ReadFloat();
	
	if (fDelay <= g_ConVarFlameLifeTime.FloatValue) {
		SetWitch(vecPrime, iAttacker);
		iWitches--;
		float fInterval = GetRandomFloat(g_ConVarIntervalMin.FloatValue, g_ConVarIntervalMax.FloatValue);
		fDelay += fInterval;
		
		if (iWitches > 0) {
			hPack.Reset();
			hPack.WriteCell(iWitches);
			hPack.WriteFloat(fDelay);
			CreateTimer(fInterval, Timer_SpawnWitch, CloneHandle(hPack), TIMER_DATA_HNDL_CLOSE | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

int SetWitch(float vecOrigin[3], int attacker = -1)
{
	int iEntWitch = -1;
	int client = GetAnySurvivor();
	if (client != 0) {
		int ent = -1;
		ArrayList aWitch = new ArrayList(ByteCountToCells(4));
		
		while (-1 != (ent = FindEntityByClassname(ent, "witch")))
			aWitch.Push(ent);
		
		ExecuteClientCommand(client, "z_spawn", "witch auto");
		
		while (-1 != (ent = FindEntityByClassname(ent, "witch"))) {
			if (-1 == aWitch.FindValue(ent)) {
				iEntWitch = ent;
				TeleportEntity(iEntWitch, vecOrigin, NULL_VECTOR, NULL_VECTOR);
				//PrintToChatAll("teleported");
				if (attacker != -1 && IsClientInGame(attacker)) {
					HurtEntity(iEntWitch, attacker);
				}
				break;
			}
		}
	}
	return iEntWitch;
}

int GetAnySurvivor()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
			return i;
	}
	return 0;
}

void ExecuteClientCommand(int client, char[] command, char[] param)
{	
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, param);
	SetCommandFlags(command, flags);
}

void HurtEntity(int target, int attacker, int damage = 1, int damagetype = 8) // thanks to SilverShot
{
	char sTemp[16];
	int entity = CreateEntityByName("point_hurt");
	Format(sTemp, sizeof(sTemp), "ext%d%d", EntIndexToEntRef(entity), attacker);
	DispatchKeyValue(target, "targetname", sTemp);
	DispatchKeyValue(entity, "DamageTarget", sTemp);
	IntToString(damage, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "Damage", sTemp);
	IntToString(damagetype, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "DamageType", sTemp);
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "Hurt", attacker > 0 ? attacker : -1);
	RemoveEdict(entity);
}