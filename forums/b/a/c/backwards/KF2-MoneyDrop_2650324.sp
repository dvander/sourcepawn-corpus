#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin:myinfo =
{
	name = "Kf2-MoneyDrop",
	author = "backwards",
	description = "Allows players to transfer money to teammates by dropping it on the ground (press +use).",
	version = SOURCEMOD_VERSION,
	url = "http://www.steamcommunity.com/id/mypassword"
}

#define MAX_CASH_ALLOWED_DROPPED 100

new TeamCashDropped[MAX_CASH_ALLOWED_DROPPED][2];
new TeamCashDroppedTotal[2] = {0, ...};

new bool:InUse[MAXPLAYERS+1] = {false, ...};
new Float:fBombPos[3];

public OnPluginStart()
{
	ClearAllMoneySlots();
	
	//RegConsoleCmd("sm_drop", CMD_DropMoney);
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("dz_item_interaction", OnItemInteraction);
	HookEvent("bomb_planted", Event_BombPlanted, EventHookMode_PostNoCopy);
}

bool IsValidClient(int client)
{
    if (!(1 <= client <= MaxClients) || !IsClientConnected(client) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client))
        return false;
		
    return true;
}

public Action:OnRoundStart(Handle: event, const String: name[], bool: dontBroadcast)
{
	fBombPos = {999999.00, 999999.00, 999999.00};
	ClearAllMoneySlots();
}

public Action:OnItemInteraction(Handle: event, const String: name[], bool: dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(player))
		return;
	
	new item_cash = GetEventInt(event, "subject");
	new String:Type[128];
	
	GetEventString(event, "type", Type, sizeof(Type));
	
	if(StrEqual(Type, "item_cash"))
		FindAndRemoveFromMoneySlot(item_cash);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{    
    if (IsPlayerAlive(client))
	{
		if(buttons & IN_USE && !InUse[client])
		{
			InUse[client] = true;
			CMD_DropMoney(client, 0);
		}
		else if (!(buttons & IN_USE) && InUse[client])
		{
			InUse[client] = false;
		}
	}
}

void ClearAllMoneySlots()
{
	for(int c = 0;c<2;c++)
		for(int i = 0;i<MAX_CASH_ALLOWED_DROPPED;i++)
			TeamCashDropped[i][c] = -1;
}

void FindAndRemoveFromMoneySlot(entity)
{
	for(int i = 0;i<MAX_CASH_ALLOWED_DROPPED;i++)
	{
		if(TeamCashDropped[i][0] == entity)
		{
			TeamCashDropped[i][0] = -1;
			TeamCashDroppedTotal[0]--;
			return;
		}
	}
	
	for(int i = 0;i<MAX_CASH_ALLOWED_DROPPED;i++)
	{
		if(TeamCashDropped[i][1] == entity)
		{
			TeamCashDropped[i][1] = -1;
			TeamCashDroppedTotal[1]--;
			return;
		}
	}
}

void FindAndInsertIntoMoneySlot(entity, team)
{
	for(int i = 0;i<MAX_CASH_ALLOWED_DROPPED;i++)
	{
		if(TeamCashDropped[i][team] == -1)
		{
			TeamCashDropped[i][team] = entity;
			return;
		}
	}
}

public Event_BombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	BombPlanted();
}

void BombPlanted()
{
    new bomb = FindEntityByClassname(-1, "planted_c4");
    if (bomb != -1)
    {
        GetEntPropVector(bomb, Prop_Send, "m_vecOrigin", fBombPos);
        fBombPos[2] += 5.0;
    }
}

bool IsTryingToDefuseBomb(client)
{
	if(GetClientTeam(client) == CS_TEAM_T)
		return false;
	
	float fPos[3];
	GetClientEyePosition(client, fPos);
	
	if(GetVectorDistance(fPos, fBombPos) < 125.0)
		return true;
		
	return false;
}

bool IsOpeningDoorOrPickingUpGun(client)
{
	float fEyeAngles[3], fPos[3];
	GetClientEyeAngles(client, fEyeAngles); 
	GetClientEyePosition(client, fPos); 

	float fForwards[3], fLookAtPos[3];
	GetAngleVectors(fEyeAngles, fForwards, NULL_VECTOR, NULL_VECTOR);
	
	for(int i = 0;i < 3; i++)
		fLookAtPos[i] = fPos[i] + (fForwards[i] * 200.0);
	
	TR_TraceRayFilter(fPos, fLookAtPos, MASK_SHOT, RayType_EndPoint, TraceRayDontHitSelf, client); 
	
	new hitobject = TR_GetEntityIndex(INVALID_HANDLE);
	if(IsValidEdict(hitobject) && IsValidEntity(hitobject))
	{
		decl String:className[128];
		GetEntityClassname(hitobject, className, sizeof(className));
	
		if(StrEqual(className, "prop_door_rotating") || StrContains(className, "weapon_", false) != -1)
			return true;
	}
	return false;
}

public Action: CMD_DropMoney(client, args)
{
	if(!IsClientInGame(client))
		return Plugin_Handled;

	if(!IsPlayerAlive(client))
		return Plugin_Handled;
	
	new account = GetEntProp(client, Prop_Send, "m_iAccount");
	if(account <= 0)
		return Plugin_Handled;
	
	new Team = GetClientTeam(client);
	if(Team != CS_TEAM_CT && Team != CS_TEAM_T)
		return Plugin_Handled;
		
	new TeamIndex = Team - 2;
	
	if(TeamCashDroppedTotal[TeamIndex] >= 100)
	{
		PrintToChat(client, "Sorry, your team already has $%i on the ground!", 100*100);
		return Plugin_Handled;
	}
	
	if(IsTryingToDefuseBomb(client))
		return Plugin_Handled;
		
	if(IsOpeningDoorOrPickingUpGun(client))
		return Plugin_Handled;
	
	new Float:eye_pos[3], Float:eye_angles[3];
	
	GetClientEyePosition(client, eye_pos);
	GetClientEyeAngles(client, eye_angles);
	
	new Handle:trace = TR_TraceRayFilterEx(eye_pos, eye_angles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	if(!TR_DidHit(trace))
		return Plugin_Handled;
	
	new entity = CreateEntityByName("item_cash");
	if(!IsValidEntity(entity))
		return Plugin_Handled;

	DispatchKeyValue(entity, "spawnflags", "4358");
	DispatchSpawn(entity);
	
	FindAndInsertIntoMoneySlot(entity, TeamIndex);
		
	SetEntProp(client, Prop_Send, "m_iAccount", account - 50);
	
	new Float: end_pos[3];
	TR_GetEndPosition(end_pos, trace);
	
	SubtractVectors(end_pos, eye_pos, end_pos);
	NormalizeVector(end_pos, end_pos);
	ScaleVector(end_pos, 300.0);
	
	new Float: velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	AddVectors(end_pos, velocity, velocity);
	velocity[2] = velocity[2] + 100.0;
	
	eye_pos[2] = eye_pos[2] - 6.0;
	eye_angles[0] = eye_angles[2] = 0.0;
	eye_angles[1] = eye_angles[1] + 90.0;
	
	TeleportEntity(entity, eye_pos, eye_angles, velocity);
	
	TeamCashDroppedTotal[TeamIndex]++;
	
	return Plugin_Handled;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
    return (entity != data);
}