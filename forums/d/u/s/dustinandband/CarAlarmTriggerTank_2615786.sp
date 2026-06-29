#pragma semicolon 1
#include <sdktools>
#pragma newdecls required

static bool bL4D2;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion EngineVer = GetEngineVersion();
	if(EngineVer == Engine_Left4Dead2)
		bL4D2 = true;
	else if(EngineVer == Engine_Left4Dead)
		bL4D2 = false;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1/2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}


public Plugin myinfo =
{
	name = "CarAlarmTriggerTank",
	author = "Lux",
	description = "",
	version = "1.0",
	url = "https://forums.alliedmods.net/member.php?u=257841"
};

public void OnPluginStart()
{
	HookEntityOutput("prop_car_alarm", "OnCarAlarmStart", OnCarAlarmStart);
}

public void OnCarAlarmStart(const char[] Output, int Caller, int Activator, float Delay)
{
	if (!IsValidEntity(Caller) || TankCounter() > 0)
		return;
	
	SpawnTank();
}

void SpawnTank()
{
	int iClient = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			iClient = i;
			break;
		}
	}
	
	if(iClient < 1)
		return;
	
	if(bL4D2)
		Client_ExecuteCheat(iClient, "z_spawn_old", "tank auto");
	else
		Client_ExecuteCheat(iClient, "z_spawn", "tank auto");
	
}

void Client_ExecuteCheat(int iClient, const char[] sCmd, const char[] sArgs)
{
	int flags = GetCommandFlags(sCmd);
	SetCommandFlags(sCmd, flags & ~FCVAR_CHEAT);
	FakeClientCommand(iClient, "%s %s", sCmd, sArgs);
	SetCommandFlags(sCmd, flags | FCVAR_CHEAT);
}

public int TankCounter()
{
	int iTankCount;
	
	int iTankClass = 8; // L4D2 tank class
	if(!bL4D2)
		iTankClass = 5; // L4D1 tank class
	
	for (int i = 1; i <=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
		{
			if (GetEntProp(i, Prop_Send, "m_zombieClass") == iTankClass)
			{
				iTankCount++;
			}
		}
	}
	return iTankCount;
}