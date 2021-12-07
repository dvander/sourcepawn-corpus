#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

bool bChill[2], bTongueOwned[MAXPLAYERS+1];
static BlockSwitchWeapon[MAXPLAYERS + 1] = 0;
static TakingDamage[MAXPLAYERS + 1] = 0;
int chosenThrower, chosenTarget, shootOrder[MAXPLAYERS+1], failedTimes[MAXPLAYERS+1],
	lastChosen[3];

float throwerPos[3], targetPos[3];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char sGame[16];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead", false))
	{
		strcopy(error, err_max, "[GTB] Plugin Supports L4D Only!");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D] Grenade Throwing Bots",
	author = "cravenge, Edison1318, Windy Wind, Lux",
	description = "Allows Bots To Throw Grenades Themselves.",
	version = "1.7",
	url = ""
};

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public Action OnWeaponSwitch(client, weapon)
{
    if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        if (BlockSwitchWeapon[client] == 1)
        {
			if(IsHoldingGrenade(client))
			{
				return Plugin_Handled;
			}
        }
    }
    return Plugin_Continue;
}

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
	HookEvent("tongue_grab", OnTongueGrab);
	HookEvent("tongue_release", OnTongueRelease);
	
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("create_panic_event", OnCreatePanicEvent);
	RegConsoleCmd("sm_releasepipebomb", ThrowPipebomb);
	CreateTimer(1.0, CheckForDanger, _, TIMER_REPEAT);
}

public Action ThrowPipebomb(int client, int args)
{
	new i = GetRandomPipebombPlayer(2);
	if(!i)
	{
		return Plugin_Handled;
	}
	CreateTimer(0.0, ThrowGrenade, i);
	CreateTimer(GetRandomFloat(0.8, 3.0), DelayThrow, i);
	return Plugin_Handled;
}

public Action ThrowGrenade(Handle timer, any client)
{
	if (shootOrder[client] == 1)
	{
		return Plugin_Stop;
	}
	
	ChangeToGrenade(client, _, true);
	BlockSwitchWeapon[client] = 1;
	shootOrder[client] = 1;
	return Plugin_Stop;
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	chosenThrower = 0;
	chosenTarget = 0;
	
	bChill[0] = false;
	bChill[1] = false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			shootOrder[i] = 0;
			failedTimes[i] = 0;
			TakingDamage[i] = 0;
			BlockSwitchWeapon[i] = 0;
			bTongueOwned[i] = false;
		}
	}
	
	for (int i = 0; i < 3; i++)
	{
		lastChosen[i] = 0;
		
		throwerPos[i] = 0.0;
		targetPos[i] = 0.0;
	}
	
	return Plugin_Continue;
}

public Action CheckForDanger(Handle timer)
{
	if (!IsServerProcessing() || bChill[0])
	{
		return Plugin_Continue;
	}
	
	if (chosenThrower == 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsSurvivorBot(i) && IsInShape(i) && i != lastChosen[0])
			{
				chosenThrower = i;
				lastChosen[0] = i;
				
				break;
			}
		}
	}
	else
	{
		if (!IsClientInGame(chosenThrower) || GetClientTeam(chosenThrower) != 2 || !IsPlayerAlive(chosenThrower))
		{
			failedTimes[chosenThrower] = 0;
			chosenThrower = 0;
			
			bChill[0] = true;
			CreateTimer(7.5, FireAgain);
			
			return Plugin_Continue;
		}
		
		if (chosenTarget == 0)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 5 && !GetEntProp(i, Prop_Send, "m_isGhost", 1))
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", targetPos);
					chosenTarget = i;
					
					break;
				}
			}
		}
		else
		{
			if (!IsClientInGame(chosenTarget) || GetClientTeam(chosenTarget) != 3 || !IsPlayerAlive(chosenTarget) || GetEntProp(chosenTarget, Prop_Send, "m_zombieClass") != 5)
			{
				chosenTarget = 0;
				failedTimes[chosenThrower] = 0;
				
				return Plugin_Continue;
			}
			
			if (CanBeSeen(chosenThrower, chosenTarget, 750.0))
			{
				ChangeToGrenade(chosenThrower, true);
				bChill[0] = true;
				CreateTimer(15.0, FireAgain);
				
				failedTimes[chosenThrower] = 0;
				
				float fEyePos[3], fTargetTrajectory[3], fEyeAngles[3];
				
				GetClientEyePosition(chosenThrower, fEyePos);
				MakeVectorFromPoints(fEyePos, targetPos, fTargetTrajectory);
				GetVectorAngles(fTargetTrajectory, fEyeAngles);
				
				fEyeAngles[2] -= 7.5;
				TeleportEntity(chosenThrower, NULL_VECTOR, fEyeAngles, NULL_VECTOR);
				
				shootOrder[chosenThrower] = 1;
				BlockSwitchWeapon[chosenThrower] = 1;
				
				CreateTimer(2.0, DelayThrow, chosenThrower);
				CreateTimer(3.0, ChooseAnother);
			}
			else
			{
				if (failedTimes[chosenThrower] >= 10)
				{
					failedTimes[chosenThrower] = 0;
					
					chosenThrower = 0;
					chosenTarget = 0;
				}
				else
				{
					failedTimes[chosenThrower] += 1;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action FireAgain(Handle timer)
{
	if (!bChill[0])
	{
		return Plugin_Stop;
	}
	
	bChill[0] = false;
	return Plugin_Stop;
}

public Action ChooseAnother(Handle timer)
{
	if (chosenThrower == 0 && chosenTarget == 0)
	{
		return Plugin_Stop;
	}
	
	chosenThrower = 0;
	chosenTarget = 0;
	
	return Plugin_Stop;
}

public Action DelayThrow(Handle timer, any client)
{
	if (shootOrder[client] == 0)
	{
		return Plugin_Stop;
	}
	
	shootOrder[client] = 0;
	CreateTimer(GetRandomFloat(0.2, 1.5), SwitchEnabled, client);
	return Plugin_Stop;
}

public Action ReadyThrow(Handle timer, any client)
{
	if (shootOrder[client] == 1)
	{
		return Plugin_Stop;
	}
	BlockSwitchWeapon[client] = 1;
	ChangeToGrenade(client, _, true);
	shootOrder[client] = 1;
	CreateTimer(GetRandomFloat(2.0, 4.0), DelayThrow, client);
	return Plugin_Stop;
}

public Action SwitchEnabled(Handle timer, any client)
{
	BlockSwitchWeapon[client] = 0;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && IsSurvivorBot(client))
	{
		int throwables = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (throwables != -1 && IsValidEntity(throwables))
		{
			char activeEnt[32];
			GetEntityClassname(throwables, activeEnt, sizeof(activeEnt));
			if (throwables == GetPlayerWeaponSlot(client, 2) && (StrEqual(activeEnt, "weapon_molotov") || StrEqual(activeEnt, "weapon_pipe_bomb")))
			{
				if (TakingDamage[client] == 1)
				{
					return Plugin_Continue;
				}
				else if (shootOrder[client] == 1)
				{
					buttons |= IN_ATTACK;
				}
				else
				{
					buttons &= ~IN_ATTACK;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action OnTongueGrab(Event event, const char[] name, bool dontBroadcast)
{
	int grabbed = GetClientOfUserId(event.GetInt("victim"));
	if (grabbed <= 0 || grabbed > MaxClients || !IsClientInGame(grabbed) || GetClientTeam(grabbed) != 2 || !IsSurvivorBot(grabbed))
	{
		return Plugin_Continue;
	}
	
	if (!bTongueOwned[grabbed])
	{
		bTongueOwned[grabbed] = true;
	}
	return Plugin_Continue;
}

public Action OnTongueRelease(Event event, const char[] name, bool dontBroadcast)
{
	int released = GetClientOfUserId(event.GetInt("victim"));
	if (released <= 0 || released > MaxClients || !IsClientInGame(released) || GetClientTeam(released) != 2 || !IsSurvivorBot(released))
	{
		return Plugin_Continue;
	}
	
	if (bTongueOwned[released])
	{
		bTongueOwned[released] = false;
	}
	return Plugin_Continue;
}

public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int damaged = GetClientOfUserId(event.GetInt("userid"));
	if (damaged <= 0 || damaged > MaxClients || !IsClientInGame(damaged) || GetClientTeam(damaged) != 2 || !IsSurvivorBot(damaged) || !IsInShape(damaged) || damaged == chosenThrower || damaged == lastChosen[1])
	{
		return Plugin_Continue;
	}
	
	if (BlockSwitchWeapon[damaged] == 1)
	{
		TakingDamage[damaged] = 1;
		BlockSwitchWeapon[damaged] = 0;
		CreateTimer(1.0, ResetDamagedBehavior, damaged);
	}
	
	if (bChill[1])
	{
		return Plugin_Continue;
	}
	
	int dangerousEnt = 0;
	
	float fDangerPos[3];
	GetEntPropVector(damaged, Prop_Send, "m_vecOrigin", fDangerPos);
	
	for (int damager = 1; damager < 2049; damager++)
	{
		if (!IsCommonInfected(damager) && !IsSpecialInfected(damager))
		{
			continue;
		}
		
		float fDamagerPos[3];
		GetEntPropVector(damager, Prop_Send, "m_vecOrigin", fDamagerPos);
		
		if (GetVectorDistance(fDangerPos, fDamagerPos) > 150.0)
		{
			continue;
		}
		
		dangerousEnt += 1;
	}
	if (dangerousEnt >= 15 && ChangeToGrenade(damaged, true))
	{
		bChill[1] = true;
		CreateTimer(5.0, ApplyCooldown);
		
		lastChosen[1] = damaged;
		
		float fLookAngles[3];
		GetClientEyeAngles(damaged, fLookAngles);
		fLookAngles[2] += 90.0;
		
		shootOrder[damaged] = 1;
		CreateTimer(2.0, DelayThrow, damaged);
	}
	
	return Plugin_Continue;
}

public Action ResetDamagedBehavior(Handle timer, any damaged)
{
	TakingDamage[damaged] = 0;
}

public Action ApplyCooldown(Handle timer)
{
	if (!bChill[1])
	{
		return Plugin_Stop;
	}
	
	bChill[1] = false;
	return Plugin_Stop;
}

public Action OnCreatePanicEvent(Event event, const char[] name, bool dontBroadcast)
{
	float fMobPos[3];
	
	for (int i = 1; i < 2049; i++)
	{
		if (!IsCommonInfected(i))
		{
			continue;
		}
		
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", fMobPos);
		break;
	}
	
	if (fMobPos[0] != 0.0 || fMobPos[1] != 0.0 || fMobPos[2] != 0.0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsSurvivorBot(i) && IsInShape(i) && i != chosenThrower && i != lastChosen[2])
			{
				if (!ChangeToGrenade(i, _, true))
				{
					continue;
				}
				
				lastChosen[2] = i;
				
				float fEyePos[3], fTargetTrajectory[3], fEyeAngles[3];
				
				GetClientEyePosition(lastChosen[2], fEyePos);
				MakeVectorFromPoints(fEyePos, fMobPos, fTargetTrajectory);
				GetVectorAngles(fTargetTrajectory, fEyeAngles);
				
				fEyeAngles[2] += 5.0;
				TeleportEntity(lastChosen[2], NULL_VECTOR, fEyeAngles, NULL_VECTOR);
				
				CreateTimer(GetRandomFloat(4.0, 6.0), ReadyThrow, lastChosen[2]);
				
				break;
			}
		}
	}
	
	return Plugin_Continue;
}

stock bool:IsHoldingGrenade(client)
{
	int throwables = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (throwables != -1 && IsValidEntity(throwables))
	{
		if (throwables == GetPlayerWeaponSlot(client, 2))
		{
			return true;
		}
	}
	return false;
}

bool CanBeSeen(int client, int other, float distance = 0.0)
{
	float fPos[2][3];
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos[0]);
	fPos[0][2] += 50.0;
	
	GetClientEyePosition(other, fPos[1]);
	
	if (distance == 0.0 || GetVectorDistance(fPos[0], fPos[1], false) < distance)
	{
		Handle trace = TR_TraceRayFilterEx(fPos[0], fPos[1], MASK_SOLID_BRUSHONLY, RayType_EndPoint, EntityChecker);
		if (TR_DidHit(trace))
		{
			delete trace;
			return false;
		}
		
		delete trace;
		return true;
	}
	
	return false;
}

public bool EntityChecker(int entity, int contentsMask, any data)
{
	return (entity == data);
}

bool ChangeToGrenade(int client, bool incFire = false, bool incPipe = false)
{
	int grenadeSlot = GetPlayerWeaponSlot(client, 2);
	if (grenadeSlot != -1 && IsValidEntity(grenadeSlot) && IsValidEdict(grenadeSlot))
	{
		char sGrenade[32];
		GetEdictClassname(grenadeSlot, sGrenade, sizeof(sGrenade));
		if (StrEqual(sGrenade, "weapon_molotov") && incFire)
		{
			FakeClientCommand(client, "use weapon_molotov");
			return true;
		}
		else if (StrEqual(sGrenade, "weapon_pipe_bomb") && incPipe)
		{
			FakeClientCommand(client, "use weapon_pipe_bomb");
			return true;
		}
	}
	
	return false;
}

bool IsInShape(int client)
{
	return (!GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) && !bTongueOwned[client] && GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") <= 0) ? true : false;
}

stock bool IsCommonInfected(int entity)
{
	if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
	{
		char entType[64];
		GetEdictClassname(entity, entType, sizeof(entType));
		return StrEqual(entType, "infected");
	}
	return false;
}

stock bool IsSpecialInfected(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_zombieClass") < 4);
}

stock GetRandomPipebombPlayer(team)
{
	new iClients[MaxClients+1];
	new iNumClients;
	for(new i = 1 ; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			new holding = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			if (IsValidEntity(holding))
			{
				char activeEnt[32];
				GetEntityClassname(holding, activeEnt, sizeof(activeEnt));
				if(IsClientInGame(i) && IsSurvivorBot(i) && holding != GetPlayerWeaponSlot(i, 2) && GetClientTeam(i) == team)
				{
					new String:grenade[32];
					if (IsValidEdict(GetPlayerWeaponSlot(i, 2)))
					{
						GetEdictClassname(GetPlayerWeaponSlot(i, 2), grenade, sizeof(grenade));
						if (StrEqual(grenade, "weapon_pipe_bomb"))
						{
							iClients[iNumClients++] = i;
						}
					}
				}
			}
		}
	}
	return (iNumClients == 0) ? -1 : iClients[GetRandomInt(0, iNumClients-1)];
}

bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}

bool IsSurvivorBot(int client)
{
	if (client > 0 && IsClientInGame(client) && IsFakeClient(client) && !IsClientInKickQueue(client))
	{
		return true;
	}
	return false;
}
