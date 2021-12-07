#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#define PLUGIN_VERSION "1.0"
#define MAX_LINE_WIDTH 64
new bool:trans[MAXPLAYERS+1];
new bool:trans1[MAXPLAYERS+1];

new Handle:cvar_speed = INVALID_HANDLE;
new Handle:cvar_slow = INVALID_HANDLE;

new Handle:cvar_fastspeed = INVALID_HANDLE;
new Handle:cvar_slowspeed = INVALID_HANDLE;
new Handle:cvar_health = INVALID_HANDLE;
public Plugin:myinfo =
{
name = "L4D tran-am",
author = "hihi1210",
description = "Add speed add hp and slow down",
version = PLUGIN_VERSION,
url = "http://www.msleeper.com/"
};
public OnPluginStart()
{
// Plugin version public Cvar
CreateConVar("sm_transam_version", PLUGIN_VERSION, "L4D Trans-arm Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
cvar_speed = CreateConVar("sm_trans_fast", "10", "speed up time  s", FCVAR_PLUGIN, true, 0.1, true, 100.0);
cvar_slow = CreateConVar("sm_trans_slow", "30", "slow down time s", FCVAR_PLUGIN, true, 0.1, true, 100.0);
cvar_fastspeed = CreateConVar("sm_trans_fastspeed", "3", "speed(trans-arm start)", FCVAR_PLUGIN, true, 0.1, true, 5);
cvar_slowspeed = CreateConVar("sm_trans_slowspeed", "0.3", "speed(trans-arm end)", FCVAR_PLUGIN, true, 0.1, true, 5);
cvar_health = CreateConVar("sm_trans_health", "80", "health after trans-arm", FCVAR_PLUGIN, true, 1, true, 100);
RegConsoleCmd("sm_power", cmd_Trans);
AutoExecConfig(true, "trans-arm");
HookEvent("round_start", event_RoundStart);
}
public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
new maxplayers = GetMaxClients();
for (new i = 1; i <= maxplayers; i++)
{
trans[i] = false;
trans1[i] = false;
}
}
public Action:cmd_Trans(client ,args)
{
if (trans1[client]) return;
if (trans[client])
{
PrintToChat(client,"you have started trans-arm");
return;
}
decl String:clientName[MAX_LINE_WIDTH];
GetClientName(client, clientName, sizeof(clientName));
SetEntityRenderMode(client, RenderMode:3);
SetEntityRenderColor(client, 255, 0, 0, 200);
SetEntProp(client,Prop_Send,"m_iMaxHealth",99999);
SetEntProp(client,Prop_Send,"m_iHealth",99999);
SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(cvar_fastspeed));
trans[client] = true;
ServerCommand("sm_evilbeam \"%N\"",client);
CreateTimer(GetConVarFloat(cvar_speed), slowdown, client);
PrintHintText(client,"\x01Trans-Arm Mode activated. \x03");
PrintToChatAll("\x01\x03[%s] have started Trans-Arm ,speed & HP up\x03",clientName);
trans1[client] = true;
return;
}

public Action:slowdown(Handle:timer, any:client)
{
decl String:clientName[MAX_LINE_WIDTH];
GetClientName(client, clientName, sizeof(clientName));
SetEntityRenderMode(client, RenderMode:3);
SetEntityRenderColor(client, 255, 255, 255, 255);
SetEntProp(client,Prop_Send,"m_iMaxHealth",100);
SetEntProp(client,Prop_Send,"m_iHealth",GetConVarFloat(cvar_health));
ServerCommand("sm_evilbeam \"%N\"",client);
SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(cvar_slowspeed));
PrintToChatAll("\x01 \x03[%s] Trans-arm end, slow down.\x03",clientName);
CreateTimer(GetConVarFloat(cvar_slow), speednormal, client);
}
public Action:speednormal(Handle:timer, any:client)
{
decl String:clientName[MAX_LINE_WIDTH];
GetClientName(client, clientName, sizeof(clientName));
SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
PrintToChatAll("\x01\x03[%s]have been recovered\x03",clientName);
trans[client] = false;
}
