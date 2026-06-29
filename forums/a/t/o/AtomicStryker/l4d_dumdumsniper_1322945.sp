#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.2"
#define PLUGIN_NAME "L4D Dum Dum Sniper"


new Handle:DumDumForce = INVALID_HANDLE;


public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = " AtomicStryker ",
	description = " Dum Dum Effect for Sniper only ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=98354"
}

public OnPluginStart()
{
	HookEvent("infected_hurt", AnInfectedGotHurt);
	HookEvent("player_hurt", APlayerGotHurt);

	CreateConVar("l4d_dumdumsniper_version", PLUGIN_VERSION, " The version of L4D DumDum Sniper running ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	DumDumForce = CreateConVar("l4d_dumdumsniper_dumdumforce", "75.0", " How powerful the DumDum Kickback is. (default 75.0) ", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d_dumdumsniper");
}

public Action:APlayerGotHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!client
	|| !IsClientInGame(client)
	|| GetClientTeam(client) != 2) return;
	
	new InfClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!InfClient
	|| !IsClientInGame(InfClient)
	|| GetClientTeam(InfClient) != 3) return;
	
	decl String:gun[32];
	GetClientWeapon(client, gun, sizeof(gun));
	if (strcmp(gun, "weapon_hunting_rifle", false) != 0
	&& StrContains(gun, "weapon_sniper", false) == -1) return; // for snipers only.
	
	decl Float:FiringAngles[3];
	decl Float:PushforceAngles[3];
	new Float:force = GetConVarFloat(DumDumForce);
	
	GetClientEyeAngles(client, FiringAngles);
	
	PushforceAngles[0] = FloatMul(Cosine(DegToRad(FiringAngles[1])), force);
	PushforceAngles[1] = FloatMul(Sine(DegToRad(FiringAngles[1])), force);
	PushforceAngles[2] = FloatMul(Sine(DegToRad(FiringAngles[0])), force);
	
	decl Float:current[3];
	GetEntPropVector(InfClient, Prop_Data, "m_vecVelocity", current);
	
	decl Float:resulting[3];
	resulting[0] = FloatAdd(current[0], PushforceAngles[0]);
	resulting[1] = FloatAdd(current[1], PushforceAngles[1]);
	resulting[2] = FloatAdd(current[2], PushforceAngles[2]);
	
	TeleportEntity(InfClient, NULL_VECTOR, NULL_VECTOR, resulting);
}

public Action:AnInfectedGotHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!client
	|| !IsClientInGame(client)
	|| GetClientTeam(client) != 2) return;
	
	new infectedentity = GetEventInt(event, "entityid");
	if (!IsValidEdict(infectedentity)) return;
	
	decl String:gun[32];
	GetClientWeapon(client, gun, sizeof(gun));
	if (strcmp(gun, "weapon_hunting_rifle", false) != 0) return; // for sniper only.
	
	decl Float:FiringAngles[3];
	decl Float:PushforceAngles[3];
	new Float:force = GetConVarFloat(DumDumForce);
	
	GetClientEyeAngles(client, FiringAngles);
	
	PushforceAngles[0] = FloatMul(Cosine(DegToRad(FiringAngles[1])), force);
	PushforceAngles[1] = FloatMul(Sine(DegToRad(FiringAngles[1])), force);
	PushforceAngles[2] = FloatMul(Sine(DegToRad(FiringAngles[0])), force);
	
	decl Float:current[3];
	GetEntPropVector(infectedentity, Prop_Data, "m_vecVelocity", current);
	
	decl Float:resulting[3];
	resulting[0] = FloatAdd(current[0], PushforceAngles[0])		
	resulting[1] = FloatAdd(current[1], PushforceAngles[1])
	resulting[2] = FloatAdd(current[2], PushforceAngles[2])
	
	TeleportEntity(infectedentity, NULL_VECTOR, NULL_VECTOR, resulting);
}