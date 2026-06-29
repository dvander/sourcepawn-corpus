#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.2.3a"
#define DEBUG 0

int tankIndex[MAXPLAYERS+1] = {0, ...};
int tankCount = 0;
Handle h_CheckTankSpawnTimer=INVALID_HANDLE;
float fTankDangerDistance;
ConVar hTankDangerDistance;
static int ZOMBIECLASS_TANK = 8;

public Plugin myinfo =
{
    name = "[L4D] Dynamic Tank Avoidance - Type A",
    author = "Omixsat",
    description = "Survivor bots will avoid any tank within a specified range",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=339308"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	char GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if (!StrEqual(GameName, "left4dead2", false))
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

public void OnPluginStart()
{
	CreateConVar("l4d_dynatankavoid_version", PLUGIN_VERSION, "[L4D] Dynamic Tank Avoidance Version", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD|FCVAR_SPONLY);
	hTankDangerDistance = CreateConVar("l4d_dynatankavoidancerange", "300.0", "The range the survivor bots must keep a distance from any incoming tank", FCVAR_NOTIFY|FCVAR_REPLICATED);
	HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_PostNoCopy);
	HookEvent("tank_killed", Event_TankDeath, EventHookMode_PostNoCopy);	
	HookEvent("player_incapacitated", Event_PlayerIncapped);
	AutoExecConfig(true, "l4d_dynamictankavoidance");
}

public void OnMapStart()
{
	RebuildTankIndex();
}

public void OnMapEnd()
{
	delete h_CheckTankSpawnTimer;
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(tankCount >= 0)
	{
		RebuildTankIndex(); //replaces the manual timer
	}
	if(h_CheckTankSpawnTimer == INVALID_HANDLE)
	{
		#if DEBUG
			PrintToChatAll("TYPE-A: Tank avoidance algorithm has started");
		#endif
		h_CheckTankSpawnTimer = CreateTimer(0.1, BotControlTimer, _, TIMER_REPEAT);
	}
}

void Event_TankDeath(Event event, const char[] name, bool dontBroadcast)	
{
	RebuildTankIndex();
}

Action BotControlTimer(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && !IsIncapacitated(i))
		{	
			int index = 0;
		
			for(int t = 1; t <= tankCount; t++)
			{
				index = tankIndex[t]; //index replaces TheTank
				if (IsClientInGame(index) && IsPlayerAlive(index) && (GetClientTeam(index) == 3))
				{
					fTankDangerDistance = hTankDangerDistance.FloatValue;
					float TankPosition[3];
					GetClientAbsOrigin(index, TankPosition);
					float BotPosition[3];
					GetClientAbsOrigin(i, BotPosition);
					if (GetVectorDistance(BotPosition, TankPosition) < fTankDangerDistance)
					{
						L4D2_RunScript("CommandABot({cmd=2,bot=GetPlayerFromUserID(%i),target=GetPlayerFromUserID(%i)})", GetClientUserId(i), GetClientUserId(index));
						#if DEBUG
							PrintToChatAll("GAME: L4D2 - Survivor Bot ID %i is moving away from Tank ID %i",i,index);
						#endif
					}
				}
			}
		}
	}	  
	return Plugin_Continue;
}

Action Event_PlayerIncapped(Event event, const char[] name, bool dontBroadcast)
{
	int BotIncapped = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsClientInGame(BotIncapped) && IsPlayerAlive(BotIncapped) && GetClientTeam(BotIncapped) == 2 && IsFakeClient(BotIncapped))
	{
		L4D2_RunScript("CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(BotIncapped));
		#if DEBUG
			PrintToChatAll("GAME: L4D2 - Survivor Bot ID %i is now incapacitated. Resetting its AI.",BotIncapped);
		#endif
	}
	
	return Plugin_Continue;
}

//Credits to Timocop for the stock :D
/**
* Runs a single line of vscript code.
* NOTE: Dont use the "script" console command, it starts a new instance and leaks memory. Use this instead!
*
* @param sCode		The code to run.
* @noreturn
*/

stock void L4D2_RunScript(const char[] sCode, any ...)
{
	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) {
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
			SetFailState("Could not create 'logic_script'");
		
		DispatchSpawn(iScriptLogic);
	}
	
	static char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
	
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}

stock bool IsIncapacitated(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0)
		return true;
	return false;
}

stock void RebuildTankIndex()
{
	tankCount = 0;
	for(int i = 1; i < MaxClients; i++)
	{
		if(!IsClientInGame(i)) continue;
		if(GetClientTeam(i) != 3) continue;
		if(!IsPlayerAlive(i)) continue;
		if(!IsPlayerTank(i)) continue;
		
		tankCount++;
		tankIndex[tankCount] = i;
	}
}

stock bool IsPlayerTank(int client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK)
		return true;
	return false;
}