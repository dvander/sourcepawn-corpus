
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

new Handle:CheckingTimer[MAXPLAYERS+1];
new Handle:h_Distance;
new Handle:h_HeightVector;
new Handle:h_SideVectors;
new Float:HeightVector;
new Float:SideVectors;
new Float:MinDistance;

public Plugin:myinfo = 
{
	name = "Flying Survivors Pushing",
	author = "Olj",
	description = "Survivors flying after tank punch can push other survivors",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	CreateConVar("l4d_fsp_version", PLUGIN_VERSION, " Version of Flying survivors push on this server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("player_hurt", TankPunch, EventHookMode_Post);
	h_Distance = CreateConVar("l4d_survivorspushing_distance", "130.0", "Collision radius", CVAR_FLAGS);
	h_HeightVector = CreateConVar("l4d_survivorspushing_heightvector", "200.0", "Height vector", CVAR_FLAGS);
	h_SideVectors = CreateConVar("l4d_survivorspushing_sidevectorsmultiplier", "2.0", "Movement vectors multiplier (x,y vectors multiplier)", CVAR_FLAGS);
	MinDistance = GetConVarFloat(h_Distance);
	SideVectors = GetConVarFloat(h_SideVectors);
	HeightVector = GetConVarFloat(h_HeightVector);
	HookConVarChange(h_Distance, MinDistanceChanged);
	HookConVarChange(h_HeightVector, HeightVectorChanged);
	HookConVarChange(h_SideVectors, SideVectorsChanged);
	AutoExecConfig(true, "l4d_survivorspushing");
}

public MinDistanceChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	MinDistance = GetConVarFloat(h_Distance);
}

public HeightVectorChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	HeightVector = GetConVarFloat(h_HeightVector);
}	

public SideVectorsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SideVectors = GetConVarFloat(h_SideVectors);
}	

public Action:TankPunch(Handle:event, String:event_name[], bool:dontBroadcast)
{
	//new TankID = GetClientOfUserId(GetEventInt(event, "attacker"));
	new VictimID = GetClientOfUserId(GetEventInt(event, "userid"));	
	new String:Weapon[256];	 
	GetEventString(event, "weapon", Weapon, 256);
	if ((StrEqual(Weapon, "tank_claw"))&&(!IsIncapped(VictimID))&&(IsValidClient(VictimID)))
		{
			CreateTimer(0.1, CreatingTimer, any:VictimID, TIMER_FLAG_NO_MAPCHANGE);
		}
}

public Action:CreatingTimer(Handle:timer, any:VictimID)
{
	CheckingTimer[VictimID] = CreateTimer(0.07, CheckingFunction,any:VictimID,TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	CreateTimer(2.5, KillTimerFunction, any:VictimID);
}

public Action:CheckingFunction(Handle:timer, any:VictimID)
{
	if (!IsValidClient(VictimID))
		{
			PrintToChatAll("KilledTimer for %i due to invalid client (line 50)", VictimID);
			if (CheckingTimer[VictimID] != INVALID_HANDLE)
				{
					KillTimer(CheckingTimer[VictimID]);
					CheckingTimer[VictimID] = INVALID_HANDLE;
					return Plugin_Stop;
				}
			return Plugin_Stop;
		}
	
	new Float:Victim_Vector[3];
	new Float:VictimOrigin[3];
	if (IsValidClient(VictimID)) GetClientAbsOrigin(VictimID,VictimOrigin);
	if (IsValidClient(VictimID)) GetEntPropVector(VictimID, Prop_Data, "m_vecVelocity", Victim_Vector);
	//PrintToChatAll("VictimVector[2] = %f", Victim_Vector[2]);
	new Float:I_Vector[3];
	if ((!IsValidClient(VictimID))||(Victim_Vector[2]==0))
		{
			if (CheckingTimer[VictimID] != INVALID_HANDLE)
				{
					//PrintToChatAll("KilledTimer for %i due to invalid client (line 67)", VictimID);
					KillTimer(CheckingTimer[VictimID]);
					CheckingTimer[VictimID] = INVALID_HANDLE;
					return Plugin_Stop;
				}
		}
	for (new i = 1; i <=MaxClients; i++)
		{
			if ((IsValidClient(i))&&(!IsIncapped(i)))
				{
					GetClientAbsOrigin(i, I_Vector);
					new Float:distance = GetVectorDistance(I_Vector, VictimOrigin);
					if (distance < MinDistance)
						{                            
							decl Float:NearSurvivorVector[3];
							GetEntPropVector(i, Prop_Data, "m_vecVelocity", NearSurvivorVector);
							//PrintToChatAll("Near survivors Velocity = %f", NearSurvivorVector[2]);
							if (NearSurvivorVector[2] != 0) return Plugin_Continue;
							NearSurvivorVector[0] *= SideVectors;
							NearSurvivorVector[1] *= SideVectors;
							NearSurvivorVector[2] = HeightVector;
							TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, NearSurvivorVector);
							return Plugin_Continue;	
						}
				}
		}  
	return Plugin_Continue;
}

public Action:KillTimerFunction(Handle:timer, any:VictimID)
{
	if (CheckingTimer[VictimID] != INVALID_HANDLE)
				{
					//PrintToChatAll("KilledTimer for %i due to invalid client (line 102)", VictimID);
					KillTimer(CheckingTimer[VictimID]);
					CheckingTimer[VictimID] = INVALID_HANDLE;
					return Plugin_Handled;
				}
	return Plugin_Continue;
}

bool:IsIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated")!=0)
		return true;
	return false;
}

public IsValidClient (client)
{
	if (client == 0)
		return false;
	if (!IsClientConnected(client))
		return false;
	if (!IsClientInGame(client))
		return false;
	if (!IsPlayerAlive(client))
		return false;
	if (GetClientTeam(client)!=2)
		return false;
	return true;
}