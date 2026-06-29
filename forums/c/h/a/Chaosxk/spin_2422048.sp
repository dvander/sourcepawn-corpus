/*
1.1
- Fixed plugin crashing on cs:go servers
- To be more universal, color chat removed and morecolor.inc no longer needed
- Fixed sm_spin_enabled not properly disabling plugin
- When spinning ends, rotation angles are reset back to 0.0 instead of incremented angles
*/
#pragma semicolon 1
#include <sdktools>
#pragma newdecls required
#include <sourcemod>

#define PLUGIN_VERSION "1.1"
#define SPRITE 	"materials/sprites/dot.vmt"
#define DEFAULT "{default}"
#define YELLOW 	"{yellow}"

ConVar ConVars[2] = {null, ...};
int gEnabled = 0;
float gSpeed = 0.0;

enum DataNum
{
	gEntity = 0,
	gCount,
	gAxis,
	gStop
};

int gDataArray[MAXPLAYERS + 1][DataNum];

public Plugin myinfo = 
{
	name = "[ANY] Spin my screen",
	author = "Tak (Chaosxk)",
	description = "Makes the players' screen spin.",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	CreateConVar("sm_spin_version", "1.0", PLUGIN_VERSION, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	ConVars[0] = CreateConVar("sm_spin_enabled", "1", "Enables/Disables this plugin.");
	ConVars[1] = CreateConVar("sm_spin_speed", "36", "How fast to spin the player's screen?");
	
	RegAdminCmd("sm_spin", Command_Spin, ADMFLAG_GENERIC, "Spin a players' screen.");
	RegAdminCmd("sm_stopspinning", Command_Stop, ADMFLAG_GENERIC, "Stop spinning player.");
	
	for(int i = 0; i < 2; i++)
		ConVars[i].AddChangeHook(OnConvarChanged);
	
	AutoExecConfig(true, "spin");  
}

public void OnConfigsExecuted()
{
	gEnabled = !!GetConVarInt(ConVars[0]);
	gSpeed = GetConVarFloat(ConVars[1]);
}

public void OnMapStart()
{
	PrecacheGeneric(SPRITE, true);
}

public void OnConvarChanged(Handle convar, char[] oldValue, char[] newValue) 
{
	if (StrEqual(oldValue, newValue, true))
		return;
		
	float iNewValue = StringToFloat(newValue);
	
	if(convar == ConVars[0])
		gEnabled = !!RoundFloat(iNewValue);
	else if(convar == ConVars[1])
		gSpeed = iNewValue;
}

public void OnClientPostAdminCheck(int client)
{
	gDataArray[client][gEntity] = 0;
	gDataArray[client][gCount] = 0;
	gDataArray[client][gAxis] = 0;
	gDataArray[client][gStop] = 0;
}

public Action Command_Spin(int client, int args)
{
	if(!gEnabled)
	{
		ReplyToCommand(client, "[SM] This plugin is disabled.");
		return Plugin_Handled;
	}
	
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_spin <client> <rotations> <optional: x,y,z>.");
		return Plugin_Handled;
	}
	
	char arg1[64], arg2[4], arg3[4];

	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int count = StringToInt(arg2);
	
	if(!count)
	{
		ReplyToCommand(client, "[SM] Usage: sm_spin <client> <rotations> <optional: x,y,z>.");
		return Plugin_Handled;
	}
	
	int axis = 0;
	if(GetCmdArg(3, arg3, sizeof(arg3)) > 0)
	{
		switch(arg3[0])
		{
			case 'x':
				axis = 0;
			case 'y':
				axis = 1;
			case 'z':
				axis = 2;
			default:
				axis = 2;
		}
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
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
		ReplyToCommand(client, "[SM] Can not find client.");
		return Plugin_Handled;
	}

	for(int i = 0; i < target_count; i++)
	{
		if(1 <= target_list[i] <= MaxClients && IsClientInGame(target_list[i]))
		{
			float ipos[3];
			GetClientEyePosition(target_list[i], ipos);
			
			int entity = CreateViewEntity(target_list[i], ipos);
			gDataArray[target_list[i]][gEntity] = EntIndexToEntRef(entity);
			gDataArray[target_list[i]][gCount] = count;
			gDataArray[target_list[i]][gAxis] = axis;
			gDataArray[target_list[i]][gStop] = 1;
			
			CreateTimer(0.1, Function_Timer, GetClientUserId(target_list[i]), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	if (tn_is_ml)
		ShowActivity2(client, "[SM] ", "%N has spun %t screen %d times.", client, target_name, count);
	else
		ShowActivity2(client, "[SM] ", "%N has spun %s screen %d times.", client, target_name, count);
	return Plugin_Handled;
}

public Action Command_Stop(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_stopspinning <client>.");
		return Plugin_Handled;
	}
	
	char arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
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
		ReplyToCommand(client, "[SM] Can not find client.");
		return Plugin_Handled;
	}

	for(int i = 0; i < target_count; i++)
	{
		if(1 <= target_list[i] <= MaxClients && IsClientInGame(target_list[i]))
		{
			gDataArray[target_list[i]][gStop] = 0;
		}
	}
	
	if (tn_is_ml)
		ShowActivity2(client, "[SM] ", "%N has stopped spinning %t.", client, target_name);
	else
		ShowActivity2(client, "[SM] ", "%N has stopped spinning %s.", client, target_name);
	return Plugin_Handled;
}

public Action Function_Timer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsClientInGame(client))
		return Plugin_Stop;
		
	int entity = EntRefToEntIndex(gDataArray[client][gEntity]);
	if(!IsValidEntity(entity))
	{
		gDataArray[client][gStop] = 0;
		SetClientViewEntity(client, client);
		return Plugin_Stop;
	}
	
	if(!gDataArray[client][gStop])
	{
		SetClientViewEntity(client, client);
		AcceptEntityInput(entity, "kill");
		return Plugin_Stop;
	}
	
	float angle[3];
	GetEntPropVector(entity, Prop_Send, "m_angRotation", angle);
	
	int count = gDataArray[client][gCount];
	int axis = gDataArray[client][gAxis];
	if(angle[axis]/360.0 >= count)
	{
		angle[axis] = 0.0;
		TeleportEntity(entity, NULL_VECTOR, angle, NULL_VECTOR);
		gDataArray[client][gStop] = 0;
		SetClientViewEntity(client, client);
		AcceptEntityInput(entity, "kill");
		return Plugin_Stop;
	}
	
	angle[axis] += gSpeed;
	TeleportEntity(entity, NULL_VECTOR, angle, NULL_VECTOR);
	
	return Plugin_Continue;
}

int CreateViewEntity(int client, float pos[3])
{
	int entity;
	if((entity = CreateEntityByName("env_sprite")) != -1)
	{
		DispatchKeyValue(entity, "model", SPRITE);
		DispatchKeyValue(entity, "renderamt", "0");
		DispatchKeyValue(entity, "rendercolor", "0 0 0");
		DispatchSpawn(entity);
		
		float angle[3];
		GetClientEyeAngles(client, angle);
		
		TeleportEntity(entity, pos, angle, NULL_VECTOR);
		TeleportEntity(client, NULL_VECTOR, angle, NULL_VECTOR);
		
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client, entity, 0);
		SetClientViewEntity(client, entity);
		return entity;
	}
	return -1;
}