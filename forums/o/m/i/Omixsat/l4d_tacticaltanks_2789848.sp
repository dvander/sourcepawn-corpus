#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "0.8"
#define DEBUG 0


public Plugin myinfo =
{
    name = "[L4D1 & L4D2] Tactical Tanks",
    author = "Omixsat",
    description = "Tank bots will do a variety of attacks",
    version = PLUGIN_VERSION,
    url = "N/A"
}

static int iHaymakerChanceRate,iJumpAttackChanceRate,ZCLASS_TANK,randNum;
ConVar hHaymakerChanceRate,hJumpAttackChanceRate;
static bool isL4D2;

public void OnPluginStart()
{
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if 		(StrEqual(game_name, "left4dead",  false))	isL4D2 = false;	
	else if (StrEqual(game_name, "left4dead2", false))	isL4D2 = true;
	else SetFailState("Plugin supports Left 4 Dead series only.");
	
	if(isL4D2)
		ZCLASS_TANK = 8;
	else if(!isL4D2)
		ZCLASS_TANK = 5;
	CreateConVar("l4d_tacticaltanks_version", PLUGIN_VERSION, "Tactical Tanks Version", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	hHaymakerChanceRate = CreateConVar("l4d_tacticaltanks_haymaker_chance", "25", "Chance for a tank to perform a haymaker attack", FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 100.0);
	hJumpAttackChanceRate = CreateConVar("l4d_tacticaltanks_jumpattack_chance", "15", "Chance for a tank to perform a jump attack", FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 100.0);
	AutoExecConfig(true, "l4d_tacticaltanks");

}

public Action OnPlayerRunCmd(client, &buttons)
{
    if (IsClientInGame(client) && IsPlayerAlive(client) && (GetClientTeam(client) == 3) && IsFakeClient(client) && IsPlayerTank(client))
    {
		if (buttons & IN_ATTACK)
        {
			iHaymakerChanceRate = hHaymakerChanceRate.IntValue;
			iJumpAttackChanceRate = hJumpAttackChanceRate.IntValue;
			FNumRando();
			if(iHaymakerChanceRate > 0 && randNum <= iHaymakerChanceRate && !isTargetIncapped(client))
			{
				//Normal haymaker
				buttons |= IN_ATTACK2;
				#if DEBUG
					PrintToServer("Haymaker!");
				#endif
				return Plugin_Changed;
			}
			FNumRando();
			if(iJumpAttackChanceRate > 0 && randNum <= iJumpAttackChanceRate && !isTargetIncapped(client))
			{
				//Jump attack
				buttons |= IN_JUMP;
				#if DEBUG
					PrintToServer("Tank is jumping");
				#endif
				return Plugin_Changed;
			}
		}
    }
    
    return Plugin_Continue;
}

void FNumRando()
{
	randNum = GetURandomInt() % (100);
}

static bool IsPlayerTank(int client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZCLASS_TANK)
		return true;
	return false;
}

static bool traceFilter(int entity, int mask, any self)
{
	return entity != self;
}


static bool isTargetIncapped(int client)
{
	static bool targetDown = false;
	static float aim_angles[3];
	static float self_pos[3];
	static int hit;
	
	GetClientEyePosition(client, self_pos);
	
	Handle trace = TR_TraceRayFilterEx(self_pos, aim_angles, MASK_VISIBLE, RayType_Infinite, traceFilter, client);
	if (TR_DidHit(trace)) {
		hit = TR_GetEntityIndex(trace);
		if ( hit > 0 && hit <= MaxClients && GetClientTeam(hit) == 2 && IsPlayerAlive(hit) && IsIncapacitated(hit)) {
			targetDown = true;
			#if DEBUG
				PrintToServer("%N is looking at downed target %N(%i)", client, hit, hit);
			#endif
		}
		else if (hit > 0)
		{
			#if DEBUG
				PrintToServer("%N is looking at %N(%i)", client, hit, hit);
			#endif
		}
	}
	delete trace;
	return targetDown;
}

static bool IsIncapacitated(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0)
		return true;
	return false;
}
