#include <sourcemod>
#include <sdktools>

#define ZOMBIECLASS_TANK 8

new Handle:StopTime[MAXPLAYERS+1] = {	INVALID_HANDLE, ...};
new Handle:g_enable = INVALID_HANDLE;
new Handle:chance = INVALID_HANDLE;
new Handle:jump_time = INVALID_HANDLE;

new g_iVelocity	= -1;

public Plugin:myinfo = {
	name = "[L4D2]Tank Jump",
	author = "AK978",
	version = "1.2"
}

public OnPluginStart(){
	g_enable = CreateConVar("l4d2_tankjump_enable", "1", " 0:關閉  , 1: 啟動");
	chance = CreateConVar("l4d2_tankjump_chance", "30.0", "Tank Jump Chance");
	jump_time = CreateConVar("l4d2_tankjump_time", "1.0", "Tank Jump Time");
	
	HookEvent("tank_spawn", Event_Tank_Spawn);
	
	if((g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]")) == -1)
		LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");
}

public Action:Event_Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast){
	if(GetConVarBool(g_enable)){	
		new Client = GetClientOfUserId(GetEventInt(event, "userid"));
		SetEntityGravity(Client, 2.0);
		
		if (IsFakeClient(Client)){
			new Float:p=GetConVarFloat(chance);
			new Float:r=GetRandomFloat(0.0, 100.0);
			if(r<p){		
				StopTime[Client] = CreateTimer(GetConVarFloat(jump_time), JumpingTimer, GetClientUserId(Client), TIMER_REPEAT);
			}
		}
	}
}
	
public Action:JumpingTimer(Handle:timer, any:Client){
	Client = GetClientOfUserId(Client);
	
	if(IsTank(Client) && IsPlayerAlive(Client)){
		AddVelocity(Client, 300.0);
	}
	else{
		if (StopTime[Client] != null){
			KillTimer(StopTime[Client]);
			StopTime[Client] = null;
		}
	}
}

public AddVelocity(Client, Float:zSpeed){
	if(g_iVelocity == -1) return;
	
	new Float:vecVelocity[3];
	GetEntDataVector(Client, g_iVelocity, vecVelocity);
	vecVelocity[2] = zSpeed;
	
	TeleportEntity(Client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

stock bool:IsTank(Client){
	if (Client > 0 && Client <= MaxClients && IsClientInGame(Client) && GetClientTeam(Client) == 3){
		if(GetEntProp(Client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK)
			return true;
		return false;
	}
	return false;
}