#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.1"

public Plugin:myinfo =
{
	name = "Following C4",
	author = "Mitch",
	description = "Makes the C4 Follow the planter, and if he dies then follows another unfortunate soul.",
	version = PLUGIN_VERSION,
	url = "http://snbx.info/"
};

new C4Hostage;
new FollowingPlayer;

public OnPluginStart()
{
	CreateConVar("sm_followingc4_version", PLUGIN_VERSION, "C4Model Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);	
	HookEvent("player_death", PlayerDeathEvent);
	HookEvent("bomb_planted", BomPlanted_Event);
}
public OnPluginEnd()
{
	if(IsHostage(C4Hostage))
	{
		AcceptEntityInput(C4Hostage, "Kill");
	}
}
public OnClientDisconnect(client)
{
	if( client == FollowingPlayer )
		FindNewPlayer();
}
public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( GetClientOfUserId(GetEventInt(event, "userid")) == FollowingPlayer )
		FindNewPlayer();
}
FindNewPlayer()
{
	if(!IsHostage(C4Hostage))
		return;
	new Float:orig[3];
	GetEntPropVector(C4Hostage, Prop_Send, "m_vecOrigin", orig);
	
	decl Float:client_pos[3];
	new Float:distance = 0.0;
	new closestEdict = INVALID_ENT_REFERENCE;
	new Float:edict_distance = 0.0;

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", client_pos);
			edict_distance = GetVectorDistance(orig, client_pos);
			if (edict_distance < distance || distance == 0.0)
			{
				distance = edict_distance;
				closestEdict = i;
			}
		}
	}
	FollowingPlayer = closestEdict;
	if(FollowingPlayer > 0 && IsClientInGame(FollowingPlayer) && IsPlayerAlive(FollowingPlayer))
		if(IsHostage(C4Hostage))
			SetEntPropEnt(C4Hostage, Prop_Send, "m_leader", FollowingPlayer);
	return;
}
public OnMapStart()
{
	CreateTimer(5.0, Timer_OwnerRepeat, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public Action:Timer_OwnerRepeat(Handle:timer)
{
	if(FollowingPlayer > 0 && IsClientInGame(FollowingPlayer) && IsPlayerAlive(FollowingPlayer))
	{
		if(IsHostage(C4Hostage))
		{
			SetEntPropEnt(C4Hostage, Prop_Send, "m_leader", FollowingPlayer);
		}
	}
}
public Action:BomPlanted_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new c4 = -1;
	c4 = FindEntityByClassname(c4, "planted_c4");
	if(c4 != -1)
	{
		C4Hostage = CreateEntityByName("hostage_entity");
		if(C4Hostage != -1)
		{
			FollowingPlayer = GetClientOfUserId(GetEventInt(event, "userid"));
			decl Float:pos[3], Float:angles[3];
			GetEntPropVector(FollowingPlayer, Prop_Data, "m_vecOrigin", pos);
			GetEntPropVector(FollowingPlayer, Prop_Data, "m_angRotation", angles);
			decl String:c4Model[128];
			GetEntPropString(c4, Prop_Data, "m_ModelName", c4Model,sizeof(c4Model));
			DispatchKeyValue(C4Hostage, "model", c4Model);
			DispatchKeyValue(C4Hostage, "skin", "1");
			DispatchKeyValue(C4Hostage, "solid", "0");
			DispatchKeyValue(C4Hostage, "disableshadows", "1");
			SetEntityModel(C4Hostage, c4Model);
			DispatchSpawn(C4Hostage);
			SetEntProp(C4Hostage, Prop_Data, "m_takedamage", 0);
			SetEntityRenderColor(C4Hostage, 255, 255, 255, 0);
			SetEntityRenderMode(C4Hostage, RENDER_TRANSALPHA);
			TeleportEntity(C4Hostage, pos, angles, NULL_VECTOR);
			SetEntProp(C4Hostage, Prop_Data, "m_CollisionGroup", 1);
			SetEntProp(C4Hostage, Prop_Send, "m_isRescued", true);
			SetVariantString("!activator");
			AcceptEntityInput(c4, "SetParent", C4Hostage, c4, 0);
		}
	}
	return Plugin_Continue;
}
bool:IsHostage(Ent)
{
	if(Ent != -1)
	{
		if(IsValidEdict(Ent) && IsValidEntity(Ent) && IsEntNetworkable(Ent))
		{
			decl String:ClassName[255];
			GetEdictClassname(Ent, ClassName, 255);
			return StrEqual(ClassName, "hostage_entity");
		}
	}
	return false;
}