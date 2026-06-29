#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.6"
#define STARTSHOOTING 1
#define STOPSHOOTING 0

#define COMMANDABOT_MOVE "CommandABot({cmd=1,pos=Vector(%f,%f,%f),bot=GetPlayerFromUserID(%i)})"
#define COMMANDABOT_REACT_TO_OTHER "CommandABot({cmd=%i,bot=GetPlayerFromUserID(%i),target=GetPlayerFromUserID(%i)})"
#define COMMANDABOT_RESET "CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})"

static int shoot[MAXPLAYERS + 1] = 0;

static Handle MedsArray = null;

public Plugin myinfo = 
{
	name = "[L4D2] Defib using bots", 
	author = "DeathChaos25", 
	description = "Allows bots to use Defibrillators in L4D2", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=261566"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
	return APLRes_SilentFailure;
}

public void OnPluginStart()
{
	CreateConVar("sm_defib_bots_version", PLUGIN_VERSION, "Defib Bots Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	CreateTimer(1.0, BotsDefib, _, TIMER_REPEAT);
	CreateTimer(1.0, CheckForPickUps, _, TIMER_REPEAT);
	
	HookEvent("defibrillator_used_fail", Event_DefibFailed);
	HookEvent("defibrillator_interrupted", Event_DefibFailed);
	HookEvent("defibrillator_used", Event_DefibUsed);
	
	RegAdminCmd("sm_resetbots", ResetSurvivorAI, ADMFLAG_ROOT, "Completely Resets Survivor AI");
	RegAdminCmd("sm_regroup", RegroupBots, ADMFLAG_ROOT, "Commands Survivor Bots to move to your location");
	RegAdminCmd("sm_attack", AttackSI, ADMFLAG_ROOT, "Orders Survivor Bots to Attack the SI you are aiming at");
	RegAdminCmd("sm_retreat", RunAway, ADMFLAG_ROOT, "Orders Survivor Bots to retreat from the SI you are aiming at");
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!RealValidEntity(entity) || classname[0] != 'w' || classname[1] != 'e' || classname[2] != 'a')
	{
		return;
	}
	
	CreateTimer(2.0, CheckEntityForGrab, entity);
}

// checking for Defibs for the defib pickup
public void OnEntityDestroyed(int entity)
{
	if (!RealValidEntity(entity)) return;
	
	if (MedsArray == null) return;
	
	for (int i = 0; i <= GetArraySize(MedsArray) - 1; i++)
	{
		if (entity == GetArrayCell(MedsArray, i))
		{
			RemoveFromArray(MedsArray, i);
		}
	}
}

// Timer based functions
Action CheckForPickUps(Handle timer)
{
	// trying to account for late loading and unexpected
	// or unreported weapons (stripper created weapons dont seem to fire OnEntityCreated)
	if (!IsServerProcessing()) return;
	
	for (int entity = 0; entity < GetMaxEntities(); entity++)
	{
		if (!RealValidEntity(entity)) continue;
		
		char classname[128];
		GetEntityClassname(entity, classname, sizeof(classname));
		if (!StrEqual(classname, "weapon_defibrillator", false)
			 && !StrEqual(classname, "weapon_defibrillator_spawn", false)
			 && !StrEqual(classname, "weapon_first_aid_kit", false)
			 && !StrEqual(classname, "weapon_first_aid_kit_spawn", false)) continue;
		
		if (!IsDefibOwned(entity))
		{
			for (int i = 0; i <= GetArraySize(MedsArray) - 1; i++)
			{
				if (entity == GetArrayCell(MedsArray, i))
				{ return; }
				else if (!IsValidEntity(entity))
				{ RemoveFromArray(MedsArray, entity); }
			}
			PushArrayCell(MedsArray, entity);
		}
		else
		{
			for (int i = 0; i <= GetArraySize(MedsArray) - 1; i++)
			{
				if (entity == GetArrayCell(MedsArray, i))
				{ RemoveFromArray(MedsArray, i); }
			}
		}
	}
}

Action CheckEntityForGrab(Handle timer, int entity)
{
	if (!RealValidEntity(entity) || MedsArray == null) return;
	
	char classname[128];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (!StrEqual(classname, "weapon_defibrillator", false)
		 && !StrEqual(classname, "weapon_defibrillator_spawn", false)
		 && !StrEqual(classname, "weapon_first_aid_kit", false)
		 && !StrEqual(classname, "weapon_first_aid_kit_spawn", false)) return;
	
	if (!IsDefibOwned(entity))
	{
		for (int i = 0; i <= GetArraySize(MedsArray) - 1; i++)
		{
			if (entity == GetArrayCell(MedsArray, i))
			{
				return;
			}
		}
		PushArrayCell(MedsArray, entity);
	}
}

Action BotsDefib(Handle timer)
{
	if (!IsServerProcessing()) return Plugin_Continue;
	
	float Origin[3], TOrigin[3];
	int i = -1;
	while ((i = FindEntityByClassname(i, "survivor_death_model")) != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", Origin);
		
		for (int j = 1; j <= MaxClients; j++)
		{
			if (!IsSurvivor(j) || !IsFakeClient(j) || !IsPlayerAlive(j) || IsIncapacitated(j) || IsPlayerHeld(j) || IsAssistNeeded() || !ClientHasFewThreats(j)) continue;
			
			GetEntPropVector(j, Prop_Send, "m_vecOrigin", TOrigin);
			float distance = GetVectorDistance(TOrigin, Origin);
			char defib[32];
			if (IsValidEdict(GetPlayerWeaponSlot(j, 3)))
			{
				GetEdictClassname(GetPlayerWeaponSlot(j, 3), defib, sizeof(defib));
				if (distance > 100 && distance < 800)
				{
					if (StrEqual(defib, "weapon_defibrillator"))
					{
						//ScriptCommand(j, "script", "CommandABot({cmd=1,pos=Vector(%f,%f,%f),bot=GetPlayerFromUserID(%i)})", Origin[0], Origin[1], Origin[2], GetClientUserId(j));
						Logic_RunScript(COMMANDABOT_MOVE, Origin[0], Origin[1], Origin[2], GetClientUserId(j));
						break;
					}
				}
				else if (distance < 100)
				{
					if (StrEqual(defib, "weapon_defibrillator") && ChangePlayerWeaponSlot(j, 3))
					{
						float EyePos[3], AimOnDeadSurvivor[3], AimAngles[3];
						GetClientEyePosition(j, EyePos);
						MakeVectorFromPoints(EyePos, Origin, AimOnDeadSurvivor);
						GetVectorAngles(AimOnDeadSurvivor, AimAngles);
						TeleportEntity(j, NULL_VECTOR, AimAngles, NULL_VECTOR);
						
						CreateTimer(0.2, AllowDefib, GetClientUserId(j), TIMER_FLAG_NO_MAPCHANGE);
						break;
					}
				}
			}
		}
		break;
	}
	return Plugin_Continue;
}

// Bot AI Manipulations Functions
Action RegroupBots(int client, int args)
{
	float Origin[3];
	GetClientAbsOrigin(client, Origin);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i) && !IsIncapacitated(i) && !IsAssistNeeded() && ClientHasFewThreats(i))
		{
			//ScriptCommand(i, "script", "CommandABot({cmd=1,pos=Vector(%f,%f,%f),bot=GetPlayerFromUserID(%i)})", Origin[0], Origin[1], Origin[2], GetClientUserId(i));
			Logic_RunScript(COMMANDABOT_MOVE, Origin[0], Origin[1], Origin[2], GetClientUserId(i));
		}
	}
}

Action AttackSI(int client, int args)
{
	if (!IsSurvivor(client)) return;
	
	int target = GetClientAimTarget(client);
	if (!IsInfected(target)) return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i) && !IsIncapacitated(i) && !IsAssistNeeded())
		{
			//ScriptCommand(i, "script", "CommandABot({cmd=0,bot=GetPlayerFromUserID(%i),target=GetPlayerFromUserID(%i)})", GetClientUserId(i), GetClientUserId(target));
			Logic_RunScript(COMMANDABOT_REACT_TO_OTHER, 0, GetClientUserId(i), GetClientUserId(target));
		}
	}
}

Action RunAway(int client, int args)
{
	if (!IsSurvivor(client)) return;
	
	int target = GetClientAimTarget(client);
	if (!IsInfected(target)) return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i) && !IsIncapacitated(i) && !IsAssistNeeded())
		{
			//ScriptCommand(i, "script", "CommandABot({cmd=2,bot=GetPlayerFromUserID(%i),target=GetPlayerFromUserID(%i)})", GetClientUserId(i), GetClientUserId(target));
			Logic_RunScript(COMMANDABOT_REACT_TO_OTHER, 2, GetClientUserId(i), GetClientUserId(target));
		}
	}
}

// This only fires if we have Left4Downtown2!
public Action L4D2_OnFindScavengeItem(int client, int &item)
{
	if (item) return Plugin_Continue;
	
	float Origin[3], TOrigin[3];
	if (MedsArray != null)
	{
		int iWeapon = GetPlayerWeaponSlot(client, 3);
		if (iWeapon > MaxClients)
		{
			char weapon[32];
			if (IsValidEdict(GetEdictClassname(GetPlayerWeaponSlot(client, 3), weapon, sizeof(weapon))))
			{
				if (StrEqual(weapon, "weapon_defibrillator") || StrEqual(weapon, "weapon_first_aid_kit"))
				{
					return Plugin_Continue;
				}
			}
		}
		for (int i = 0; i <= GetArraySize(MedsArray) - 1; i++)
		{
			if (!IsValidEntity(GetArrayCell(MedsArray, i)))
			{
				return Plugin_Continue;
			}
			
			char waClass[64];
			GetEntityClassname(GetArrayCell(MedsArray, i), waClass, sizeof(waClass));
			if (StrEqual(waClass, "predicted_viewmodel") || StrContains(waClass, "scene") != -1 || StrContains(waClass, "ability") != -1)
			{
				return Plugin_Continue;
			}
			
			GetEntPropVector(GetArrayCell(MedsArray, i), Prop_Send, "m_vecOrigin", Origin);
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
			float distance = GetVectorDistance(TOrigin, Origin);
			if (distance < 300)
			{
				item = GetArrayCell(MedsArray, i);
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

// Functions to allow the Bot to use Defibs
Action AllowDefib(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	shoot[client] = STARTSHOOTING;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsSurvivor(client) && IsPlayerAlive(client) && IsFakeClient(client))
	{
		int defib = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(defib))
		{
			char classname[128];
			GetEntityClassname(defib, classname, sizeof(classname));
			if (defib == GetPlayerWeaponSlot(client, 3) && StrEqual(classname, "weapon_defibrillator"))
			{
				if (shoot[client] == STARTSHOOTING)
				{
					buttons |= IN_ATTACK;
				}
				else if (shoot[client] == STOPSHOOTING)
				{
					buttons &= ~IN_ATTACK;
				}
			}
		}
	}
	return Plugin_Continue;
}

// Event Hooks so we can reset bots and prevent them from being stuck in the trying to defib state
void Event_DefibUsed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsSurvivor(client) && IsFakeClient(client))
	{
		shoot[client] = STOPSHOOTING;
		CreateTimer(0.4, ResetBotAI, GetClientUserId(client));
	}
}

void Event_DefibFailed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsSurvivor(client) && IsFakeClient(client))
	{
		shoot[client] = STOPSHOOTING;
		CreateTimer(6.0, ResetBotAI, GetClientUserId(client));
	}
}

Action ResetSurvivorAI(int client, int args)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i) && !IsIncapacitated(i) && !IsAssistNeeded() && ClientHasFewThreats(i))
		{
			//ScriptCommand(i, "script", "CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(i));
			Logic_RunScript(COMMANDABOT_RESET, GetClientUserId(i));
		}
	}
}

Action ResetBotAI(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsSurvivor(client) && IsFakeClient(client))
	{
		shoot[client] = STOPSHOOTING;
		//ScriptCommand(client, "script", "CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(client));
		Logic_RunScript(COMMANDABOT_RESET, GetClientUserId(client));
	}
}

// Stock functions, bools, etc
bool IsIncapacitated(int client, int hanging = 2)
{
	bool isIncap = view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
	bool isHanging = view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge"));
	
	switch (hanging)
	{
		// if hanging is 2, don't care about hanging
		case 2:
		{
			if (isIncap) return true;
		}
		// if 1, check for hanging too
		case 1:
		{
			if (isIncap && isHanging) return true;
		}
		// otherwise, must just be incapped to return true
		case 0:
		{
			if (isIncap && !isHanging) return true;
		}
	}
	return false;
}

bool ChangePlayerWeaponSlot(int client, int weaponslot)
{
	int iWeapon = GetPlayerWeaponSlot(client, weaponslot);
	if (iWeapon > MaxClients)
	{
		char weapon[32];
		if (IsValidEdict(GetEdictClassname(GetPlayerWeaponSlot(client, 3), weapon, sizeof(weapon))))
		{
			if (StrEqual(weapon, "weapon_defibrillator"))
			{
				FakeClientCommand(client, "use weapon_defibrillator");
				return true;
			}
		}
	}
	return false;
}

bool IsPlayerHeld(int client)
{
	int jockey = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	int charger = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	int hunter = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	int smoker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (RealValidEntity(jockey) || RealValidEntity(charger) || RealValidEntity(hunter) || RealValidEntity(smoker))
	{
		return true;
	}
	return false;
}

bool IsAssistNeeded()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i) && (IsIncapacitated(i) || IsPlayerHeld(i)))
		{
			return true;
		}
	}
	return false;
}

bool IsDefibOwned(int defib)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i) && GetPlayerWeaponSlot(i, 3) == defib)
		{
			return true;
		}
	}
	return false;
}

bool ClientHasFewThreats(int client)
{
	if (IsSurvivor(client))
	{
		int threats = GetEntProp(client, Prop_Send, "m_hasVisibleThreats");
		if (threats <= 0)
		{
			return true;
		}
	}
	return false;
}

#define PLUGIN_SCRIPTLOGIC "plugin_scripting_logic_entity"

void Logic_RunScript(const char[] sCode, any ...) 
{
	int iScriptLogic = FindEntityByTargetname(-1, PLUGIN_SCRIPTLOGIC);
	if (!iScriptLogic || !IsValidEntity(iScriptLogic))
	{
		iScriptLogic = CreateEntityByName("logic_script");
		DispatchKeyValue(iScriptLogic, "targetname", PLUGIN_SCRIPTLOGIC);
		DispatchSpawn(iScriptLogic);
	}
	
	char sBuffer[512]; 
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2); 
	
	SetVariantString(sBuffer); 
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}

int FindEntityByTargetname(int index, const char[] findname)
{
	for (int i = index; i < GetMaxEntities(); i++) {
		if (!IsValidEntity(i)) continue;
		char name[128];
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		if (!StrEqual(name, findname, false)) continue;
		return i;
	}
	return -1;
}

/*void ScriptCommand(int client, const char[] command, const char[] arguments, any ...)
{
	char vscript[PLATFORM_MAX_PATH];
	VFormat(vscript, sizeof(vscript), arguments, 4);
	
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags^FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, vscript);
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}*/

bool IsSurvivor(int client)
{
	if (!IsValidClient(client)) return false;
	//if (GetClientTeam(client) != 2 && GetClientTeam(client) != 4) return false;
	if (GetClientTeam(client) != 2) return false;
	return true;
}

bool IsInfected(int client)
{
	if (!IsValidClient(client)) return false;
	if (GetClientTeam(client) != 2 && GetClientTeam(client) != 4) return false;
	return true;
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

bool RealValidEntity(int entity)
{
	if (entity <= 0 || !IsValidEntity(entity)) return false;
	return true;
}

public void OnMapStart()
{
	MedsArray = CreateArray();
}

public void OnMapEnd()
{
	CloseHandle(MedsArray);
	MedsArray = null;
}