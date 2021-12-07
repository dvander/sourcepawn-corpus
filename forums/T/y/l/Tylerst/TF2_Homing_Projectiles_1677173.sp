#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "TF2 Homing Projectiles",
	author = "Tylerst",
	description = "Set a target(s) projectiles to home in on the nearest target",
	version = PLUGIN_VERSION,
	url = "none"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

new bool:g_HomingEnabled[MAXPLAYERS+1] = false;

public OnPluginStart()
{	
	LoadTranslations("common.phrases");
	CreateConVar("sm_homingprojectiles_version", PLUGIN_VERSION, "Set a target(s) projectiles to home in on the nearest target", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_homproj", Command_Name, ADMFLAG_SLAY, "Set target(s) projectiles to homing, Usage: sm_homproj \"target\" \"1/0\"");	
	LoadTranslations("common.phrases");
}

public OnClientPutInServer(client) g_HomingEnabled[client] = false;
public OnClientDisconnect_Post(client) g_HomingEnabled[client] = false;

public Action:Command_Name(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_homproj \"target\" \"1/0\"");
		return Plugin_Handled;
	}

	new String:target[MAX_TARGET_LENGTH], String:strSwitch[2], Switch, String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, strSwitch, sizeof(strSwitch));
	Switch = StringToInt(strSwitch);
	
	if ((target_count = ProcessTargetString(
			target,
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

	if(Switch)
	{
		for(new i = 0; i < target_count; i++)
		{
			g_HomingEnabled[target_list[i]] = true;
		}
		ShowActivity2(client, "[SM] ","Enabled Homing Projectiles for %s", target_name);
	}
	else 
	{
		for(new i = 0; i < target_count; i++)
		{
			g_HomingEnabled[target_list[i]] = false;
		}
		ShowActivity2(client, "[SM] ","Disabled Homing Projectiles for %s", target_name);
	}
	return Plugin_Handled;
}





public OnGameFrame()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(g_HomingEnabled[i])
		{
			SetHomingProjectile(i, "tf_projectile_arrow");
			SetHomingProjectile(i, "tf_projectile_energy_ball");
			SetHomingProjectile(i, "tf_projectile_flare");
			SetHomingProjectile(i, "tf_projectile_healing_bolt");
			SetHomingProjectile(i, "tf_projectile_rocket");
			SetHomingProjectile(i, "tf_projectile_sentryrocket");
			SetHomingProjectile(i, "tf_projectile_syringe");
		}
	}
}

SetHomingProjectile(client, const String:classname[])
{
	new entity = -1; 
	while((entity = FindEntityByClassname(entity, classname))!=INVALID_ENT_REFERENCE)
	{
		new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(!IsValidEntity(owner)) continue;
		if(StrEqual(classname, "tf_projectile_sentryrocket", false)) owner = GetEntPropEnt(owner, Prop_Send, "m_hBuilder");		
		new Target = GetClosestTarget(entity, owner);
		if(!Target) continue;
		if(owner == client)
		{
			new Float:ProjLocation[3], Float:ProjVector[3], Float:ProjSpeed, Float:ProjAngle[3], Float:TargetLocation[3], Float:AimVector[3];			
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", ProjLocation);
			GetClientAbsOrigin(Target, TargetLocation);
			TargetLocation[2] += 40.0;
			MakeVectorFromPoints(ProjLocation, TargetLocation , AimVector);
			GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);					
			ProjSpeed = GetVectorLength(ProjVector);					
			AddVectors(ProjVector, AimVector, ProjVector);	
			NormalizeVector(ProjVector, ProjVector);
			GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
			GetVectorAngles(ProjVector, ProjAngle);
			SetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);					
			ScaleVector(ProjVector, ProjSpeed);
			SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);
		}
	}	
}

GetClosestTarget(entity, owner)
{
	new Float:TargetDistance = 0.0;
	new ClosestTarget = 0;
	for(new i = 1; i <= MaxClients; i++) 
	{
		if(!IsClientConnected(i) || !IsPlayerAlive(i) || i == owner || (GetClientTeam(owner) == GetClientTeam(i))) continue;
		new Float:EntityLocation[3], Float:TargetLocation[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", EntityLocation);
		GetClientAbsOrigin(i, TargetLocation);
		
		new Float:distance = GetVectorDistance(EntityLocation, TargetLocation);
		if(TargetDistance)
		{
			if(distance < TargetDistance) 
			{
				ClosestTarget = i;
				TargetDistance = distance;			
			}
		}
		else
		{
			ClosestTarget = i;
			TargetDistance = distance;
		}
	}
	return ClosestTarget;
}
