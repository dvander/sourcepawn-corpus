#pragma semicolon 1

#include <sdktools>
#include <sourcemod> 
#include <sdkhooks>

#define PLUGIN_VERSION "1.1 - HL2DM"

new Handle:g_Enabled;
new Handle:g_Dmg;
new Handle:g_Radius;

new Float:g_pos[3];
new g_Arrows[MAXPLAYERS+1];


public Plugin:myinfo = 
{
	name = "[HL2DM] Explosive Arrows",
	author = "Tak (Chaosxk)",
	description = "Are your arrows too weak? Buff them up!",
	version = PLUGIN_VERSION,
	url = "http://www.alliedmods.net"
}

public OnPluginStart()
{
	CreateConVar("arrows_version", "Version of this plugin", PLUGIN_VERSION, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Enabled = CreateConVar("sm_arrows_enabled", "1", "Enables/Disables explosive arrows.");
	g_Dmg = CreateConVar("sm_arrows_damage", "50", "How much damage should the arrows do?");
	g_Radius = CreateConVar("sm_arrows_radius", "200", "What should the radius of damage be?");
	
	RegAdminCmd("sm_arrowsme", Command_ArrowsMe, ADMFLAG_GENERIC, "Turn on explosive arrows for yourself.");
	RegAdminCmd("sm_arrows", Command_Arrows, ADMFLAG_GENERIC, "Usage: sm_arrows <client> <On: 1 ; Off = 0>.");
	
	LoadTranslations("common.phrases");
	AutoExecConfig(true, "arrows");
}

public Action:Command_ArrowsMe(client, args)
{
	if(!g_Enabled || !IsValidClient(client)) return Plugin_Continue;
	
	if (g_Arrows[client] == 0)
	{
		g_Arrows[client] = 1;
		ReplyToCommand(client, "[SM] You have enabled explosive arrows.");
	}
	else
	{
		g_Arrows[client] = 0;
		ReplyToCommand(client, "[SM] You have disabled explosive arrows.");
	}
	return Plugin_Handled;
}

public Action:Command_Arrows(client, args)
{
	if(!g_Enabled || !IsValidClient(client)) return Plugin_Continue;
	
	decl String:arg1[65], String:arg2[65];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new button = StringToInt(arg2);
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	if(args < 2)
	{
		ReplyToCommand(client, "Usage: sm_arrows <client> <On: 1 ; Off = 0>");
		return Plugin_Handled;
	}
	
	if(args == 2)
	{
		for(new i = 0; i < target_count; i++)
		{
			if(IsValidClient(target_list[i]))
			{
				new target = target_list[i];
				if(button == 1)
				{
					g_Arrows[target] = 1;
					ShowActivity2(client, "[SM] ", "%N has given %s explosive arrows.", client, target_name);
				}
				if(button == 0)
				{
					g_Arrows[target] = 0;
					ShowActivity2(client, "[SM] ", "%N has removed %s explosive arrows.", client, target_name);
				}
			}
		}
	}
	return Plugin_Handled;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname,"crossbow_bolt"))
	{
		SDKHook(entity, SDKHook_StartTouch, OnEntityTouch);
	}
}

public Action:OnEntityTouch(entity, other)
{
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", g_pos);
	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if(g_Arrows[client] == 1)
	{	
		new explode = CreateEntityByName("env_explosion");
		
		if (IsValidEdict(explode))
		{	
			DispatchKeyValue(explode, "targetname", "explode");
			
			SetEntPropEnt(explode, Prop_Data, "m_hOwnerEntity", client);
			SetEntProp(explode, Prop_Data, "m_iMagnitude", GetConVarInt(g_Dmg));
			SetEntProp(explode, Prop_Data, "m_iRadiusOverride", GetConVarInt(g_Radius));
			
			DispatchKeyValue(explode, "spawnflags", "2");
			DispatchKeyValue(explode, "rendermode", "5");
			DispatchKeyValue(explode, "fireballsprite", "sprites/zerogxplode.spr");
			
			DispatchSpawn(explode);
			
			TeleportEntity(explode, g_pos, NULL_VECTOR, NULL_VECTOR);
			ActivateEntity(explode);
			
			CreateTimer(0.1, Timer_Explode, explode);
			CreateTimer(0.2, Explosion_Kill, explode);
		}
	}
	return Plugin_Handled;
}

public Action:Explosion_Kill(Handle:timer, any:explode)
{
	AcceptEntityInput(explode, "kill");
	return Plugin_Handled;
}

public Action:Timer_Explode(Handle:timer, any:explode)
{
	AcceptEntityInput(explode, "Explode");
	return Plugin_Continue;
}

stock bool:IsValidClient(i, bool:replay = true)
{
	if(i <= 0 || i > MaxClients || !IsClientInGame(i) || GetEntProp(i, Prop_Send, "m_bIsCoaching")) return false;
	if(replay && (IsClientSourceTV(i) || IsClientReplay(i))) return false;
	return true;
}