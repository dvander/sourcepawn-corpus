#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

new const String:PLUGIN_VERSION[] = "1.2";

new Handle:hcv_Type = INVALID_HANDLE;
new Handle:hcv_TypeBySelf = INVALID_HANDLE;
public Plugin:myinfo = 
{
	name = "Ping Position",
	author = "Eyal282",
	description = "Allows you to ping your crosshair",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("sm_pingpos", Command_PingPos);
	
	hcv_Type = CreateConVar("pingpos_type", "0", "Type of ping to create by the command", _, true, 0.0, true, 14.0);
	hcv_TypeBySelf = CreateConVar("pingpos_typebyself", "1", "If 1, you can write sm_pingpos <type> to set the type of ping yourself");
	
	AddCommandListener(Listener_PlayerPing, "player_ping");
}

public Action:Listener_PlayerPing(client, const String:command[], args)
{
	if(PingCrosshair(client, command, false))
		return Plugin_Stop;
		
	return Plugin_Continue;
}

public Action:Command_PingPos(client, args)
{
	new String:Arg[65];
	GetCmdArg(1, Arg, sizeof(Arg));
	PingCrosshair(client, Arg);
	
	return Plugin_Handled;
}

stock bool:PingCrosshair(client, const String:Arg[], bool:replytocommand=true)
{
	if(client == 0)
		return false;
		
	new Team = GetClientTeam(client);
	
	if(Team != CS_TEAM_CT && Team != CS_TEAM_T)
	{
		if(replytocommand)
			ReplyToCommand(client, "Your team is invalid.");
			
		else
			PrintToChat(client, "Your team is invalid.");
		return false;
	}
	
	new Type = GetConVarInt(hcv_Type);
	
	if(GetConVarBool(hcv_TypeBySelf))
	{
		new Float:fMax, Float:fMin;
		GetConVarBounds(hcv_Type, ConVarBound_Upper, fMax);
		GetConVarBounds(hcv_Type, ConVarBound_Lower, fMin);
		
		Type = StringToInt(Arg);
		
		if(Type > RoundFloat(fMax) || Type < RoundFloat(fMin))
			Type = GetConVarInt(hcv_Type);
	}
	else
		Type = GetConVarInt(hcv_Type);

	new Float:Origin[3], Float:Angles[3];
	GetClientEyePosition(client, Origin);
	GetClientEyeAngles(client, Angles);
	
	TR_TraceRayFilter(Origin, Angles, MASK_SHOT, RayType_Infinite, TraceRayDontHitPlayers);
	
	if(!TR_DidHit(INVALID_HANDLE))
	{
		if(replytocommand)
			ReplyToCommand(client, "Could not find a position in your aim");
			
		else
			PrintToChat(client, "Could not find a position in your aim");
			
		return false;
	}
	
	
	new ent = CreateEntityByName("info_player_ping");
	
	DispatchSpawn(ent);
	
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(ent, Prop_Send, "m_hPlayer", client);
	SetEntPropEnt(client, Prop_Send, "m_hPlayerPing", ent);

	SetEntProp(ent, Prop_Send, "m_iTeamNum", Team);
	
	TR_GetEndPosition(Origin, INVALID_HANDLE);
	
	TeleportEntity(ent, Origin, NULL_VECTOR, NULL_VECTOR);
	
	SetEntProp(ent, Prop_Send, "m_iType", Type);
	if(replytocommand)
		ReplyToCommand(client, "Successfully pinged at your crosshair");
			
	else
		PrintToChat(client, "Successfully pinged at your crosshair");
	
	return true;
}


public bool:TraceRayDontHitPlayers(entityhit, mask) 
{
    return (entityhit>MaxClients || entityhit == 0);
}