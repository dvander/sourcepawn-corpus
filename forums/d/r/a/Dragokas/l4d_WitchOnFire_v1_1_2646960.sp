#define PLUGIN_VERSION "1.0"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "WitchOnFire",
	author = "Alex Dragokas",
	description = "Witch is appearing in the fire when somebody throw a molotov",
	version = PLUGIN_VERSION,
	url = "https://dragokas.com"
};

/*
	ChangeLog
	
	1.1
	 - Fixed case when event doesn't happen if molotov hits the car (thanks to BHaType) (unfinished)
	
	1.0
	 - Initial release

	 TODOs:
	 
	 - Fix annoing rapidly repeatable scream witch sound that happen sometimes.
	 - Fix OnTouch doesn't trigger when molotov hits the car.
	 
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

int g_iRefClient[MAXPLAYERS+1];

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
	g_ConVarChance = CreateConVar("l4d_witch_on_fire_chance", "10", "Chance the witch is appear in molotov fire (1 to 100), 0 - to disable.", CVAR_FLAGS);
	g_ConVarDelayMin = CreateConVar("l4d_witch_on_fire_mindelay", "1", "Minimum time in sec. after molotov explosion when witches should appear (by default, 0 - 14).", CVAR_FLAGS);
	g_ConVarDelayMax = CreateConVar("l4d_witch_on_fire_maxdelay", "9", "Maximum time in sec. after molotov explosion when witches should appear (by default, 0 - 14).", CVAR_FLAGS);
	g_ConVarWitchCountMin = CreateConVar("l4d_witch_on_fire_count_min", "3", "Minimum number of witches to spawn in the fire", CVAR_FLAGS);
	g_ConVarWitchCountMax = CreateConVar("l4d_witch_on_fire_count_max", "6", "Maximum number of witches to spawn in the fire", CVAR_FLAGS);
	g_ConVarIntervalMin = CreateConVar("l4d_witch_on_fire_mininterval", "0.5", "Minimum time interval beetween each witch spawn (in sec.)", CVAR_FLAGS);
	g_ConVarIntervalMax = CreateConVar("l4d_witch_on_fire_maxinterval", "2.0", "Maximum time interval beetween each witch spawn (in sec.)", CVAR_FLAGS);
	g_ConVarMinSafeDist = CreateConVar("l4d_witch_on_fire_minsafedist", "700.0", "Minimum client distance to molotov explosion point in order to allow witch spawn event to begin", CVAR_FLAGS);
	
	g_ConVarFlameLifeTime = FindConVar("inferno_flame_lifetime");
	
	// FindConVar("inferno_spawn_angle");
	// FindConVar("inferno_max_range");
	// (cone), require math. calculation depending on eye view angle before throwing the molotov (or some another method to get the angle of molotov fly).
	
	AutoExecConfig(true, "l4d_witch_on_fire");
	
	GetCvars();
	HookConVarChange(g_ConVarFlameLifeTime,	ConVarChanged);
	HookConVarChange(g_ConVarDelayMin,		ConVarChanged);
	HookConVarChange(g_ConVarDelayMax,		ConVarChanged);
}

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
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (g_ConVarEnable.BoolValue && (GetRandomInt(1, 100) <= g_ConVarChance.IntValue))
	{
		if(StrEqual(classname, "inferno"))
		{
			RequestFrame(OnNextInfernoFrame, entity);
		}
		
		if(StrEqual(classname, "molotov_projectile"))
		{
			RequestFrame(OnNextMolotovFrame, entity);
		}
	}
}

public void OnEntityDestroyed(int entity)
{
	char sClass[32];
	
	if (IsValidEntity(entity)) {
		GetEntityClassname(entity, sClass, sizeof(sClass));
		//PrintToChatAll("destroyed: %s", sClass);
	}
}

public void OnNextMolotovFrame(int entity)
{
	if (IsValidEntity(entity)) {
		int client = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		g_iRefClient[client] = EntIndexToEntRef(entity);
		PrintToChatAll("Ref for %i is saved: %i, entity: %i", client, g_iRefClient[client], entity);
	}
}

public void OnNextInfernoFrame(int iEntInferno)
{
	if (IsValidEntity(iEntInferno)) {
		int hOwner = GetEntPropEnt(iEntInferno, Prop_Data, "m_hOwnerEntity");
		
		if (hOwner > 0) {
			PrintToChatAll("Inferno owner: %i", hOwner);
		
			float vecMolotovExplode[3], vecClientOrigin[3];
		
			int iEntMolotov = EntRefToEntIndex(g_iRefClient[hOwner]);
			
			PrintToChatAll("Molotov entity: %i, ref: %i", iEntMolotov, g_iRefClient[hOwner]);
			
			GetEntPropVector(iEntMolotov, Prop_Data, "m_vecOrigin", vecMolotovExplode);
			
			if ((0 < hOwner <= MaxClients) && IsClientInGame(hOwner)) {
				
				GetClientAbsOrigin(hOwner, vecClientOrigin);
				
				if (GetVectorDistance(vecClientOrigin, vecMolotovExplode) > g_ConVarMinSafeDist.FloatValue)
				{
					float fDelay = GetRandomFloat(g_ConVarDelayMin.FloatValue, g_ConVarDelayMax.FloatValue);
					
					DataPack hPack = new DataPack();
					hPack.WriteCell(GetRandomInt(g_ConVarWitchCountMin.IntValue, g_ConVarWitchCountMax.IntValue));
					hPack.WriteFloat(fDelay);
					hPack.WriteFloat(vecMolotovExplode[0]);
					hPack.WriteFloat(vecMolotovExplode[1]);
					hPack.WriteFloat(vecMolotovExplode[2]);
					CreateTimer(fDelay, Timer_SpawnWitch, hPack, TIMER_DATA_HNDL_CLOSE | TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

public Action Timer_SpawnWitch(Handle timer, DataPack hPack)
{
	hPack.Reset();
	int iWitches = hPack.ReadCell();
	float fDelay = hPack.ReadFloat();
	float vecPrime[3];
	vecPrime[0] = hPack.ReadFloat();
	vecPrime[1] = hPack.ReadFloat();
	vecPrime[2] = hPack.ReadFloat();
	
	if (fDelay <= g_ConVarFlameLifeTime.FloatValue) {
		SetWitch(vecPrime);
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

void SetWitch(float vecOrigin[3])
{
	int client = GetAnySurvivor();
	if (client != 0) {
		int ent = -1;
		ArrayList aWitch = new ArrayList(ByteCountToCells(4));
		
		while (-1 != (ent = FindEntityByClassname(ent, "witch")))
			aWitch.Push(ent);
		
		ExecuteClientCommand(client, "z_spawn", "witch auto");
		
		while (-1 != (ent = FindEntityByClassname(ent, "witch"))) {
			if (-1 == aWitch.FindValue(ent)) {
				TeleportEntity(ent, vecOrigin, NULL_VECTOR, NULL_VECTOR);
				break;
			}
		}
	}
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
