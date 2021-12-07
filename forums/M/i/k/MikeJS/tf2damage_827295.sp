#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
new g_iHealth[MAXPLAYERS+1];
new Handle:g_hForwardHurt = INVALID_HANDLE;
public OnPluginStart() {
	RegPluginLibrary("tf2damage");
	g_hForwardHurt = CreateGlobalForward("TF2_PlayerHurt", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	HookEntityOutput("item_healthkit_small", "OnPlayerTouch", EntityOutput_SaveHealth);
	HookEntityOutput("item_healthkit_medium", "OnPlayerTouch", EntityOutput_SaveHealth);
	HookEntityOutput("item_healthkit_full", "OnPlayerTouch", EntityOutput_SaveHealth);
	HookEntityOutput("prop_dynamic", "OnAnimationBegun", EntityOutput_SaveHealthAll);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_spawn", Event_PlayerSpawn);
}
public OnGameFrame() {
	new cond;
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)>1) {
			cond = GetEntProp(i, Prop_Send, "m_nPlayerCond");
			if(cond&8192 || cond&32768 || TF2_GetPlayerClass(i)==TFClass_Medic)
				g_iHealth[i] = GetClientHealth(i);
		}
	}
}
public EntityOutput_SaveHealth(const String:output[],	caller, activator, Float:delay) {
	g_iHealth[activator] = GetClientHealth(activator);
}
public EntityOutput_SaveHealthAll(const String:output[], caller, activator, Float:delay) {
	for(new i=1;i<=MaxClients;i++)
		if(IsClientInGame(i) && !IsClientObserver(i))
			g_iHealth[i] = GetClientHealth(i);
}
public Action:Event_PlayerHurt(Handle:event,  const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid")), health = GetEventInt(event, "health"), damage = g_iHealth[client]-health;
	decl Action:result;
	Call_StartForward(g_hForwardHurt);
	Call_PushCell(client);
	Call_PushCell(GetClientOfUserId(GetEventInt(event, "attacker")));
	Call_PushCell(damage);
	Call_PushCell(health);
	Call_Finish(_:result);
	if(result==Plugin_Handled) {
		new prevhealth = health+damage;
		SetEntProp(client, Prop_Send, "m_iHealth", prevhealth, 1);
		SetEntProp(client, Prop_Data, "m_iHealth", prevhealth, 1);
	} else {
		g_iHealth[client] = health;
	}
}
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	CreateTimer(0.01, Timer_SaveHealth, GetClientOfUserId(GetEventInt(event, "userid")));
}
public Action:Timer_SaveHealth(Handle:timer, any:client) {
	g_iHealth[client] = GetClientHealth(client);
}