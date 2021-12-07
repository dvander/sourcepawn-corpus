#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"
#define DMG_GENERIC            0
#define DMG_PREVENT_PHYSICS_FORCE    (1 << 11)

  
public Plugin:myinfo =
{
	name = "Player Push",
	author = "YoNer, Code from Orion's knockback plugin",
	description = "Push player in any of six directions",
	version = PLUGIN_VERSION,
}

enum VelocityOverride {
	
	VelocityOvr_None = 0,
	VelocityOvr_Velocity,
	VelocityOvr_OnlyWhenNegative,
	VelocityOvr_InvertReuseVelocity
};

public OnPluginStart()
{

	RegAdminCmd("sm_ppush", Command_PlayerPush, ADMFLAG_ROOT, "Direction = 'front' 'back' 'left' 'right' 'up' 'down'")
}

public Action:Command_PlayerPush(client, args)
{
	new String:arg1[32], String:arg2[32], String:arg3[12];
	new Float:knock;
	new String:dir[12];
 
	GetCmdArg(1, arg1, sizeof(arg1))
	GetCmdArg(2, arg2, sizeof(arg2))
	GetCmdArg(3, arg3, sizeof(arg3))

	if (args == 3)
	{
		knock = StringToFloat(arg2);
		dir=arg3
	} else {
		ReplyToCommand(client, "[SM] Usage: sm_ppush <target> <power> <direction>");
		return Plugin_Handled;
	}
	if (knock < 1)
	{
		ReplyToCommand(client, "Knockback power must be higher than 0");
		return Plugin_Handled;
	}
	if (!StrEqual(dir, "up",false) && !StrEqual(dir, "down",false) && !StrEqual(dir, "left",false) && !StrEqual(dir, "right",false) && !StrEqual(dir, "front",false) && !StrEqual(dir, "back",false))
	{
		ReplyToCommand(client, "Direction must be 'front','back','left','right','up' or 'down' ");
		return Plugin_Handled;
	}

	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		decl Float:clientEyeAngles[3];
		GetClientEyeAngles(target_list[i], clientEyeAngles);
		clientEyeAngles[0] = 0.0;

	
		
		if (StrEqual(dir, "front",false)) {
			PushUp(target_list[i], 251.0);
			PushPlayer(target_list[i], clientEyeAngles, knock,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
		}
		if (StrEqual(dir, "left",false)) {
			PushUp(target_list[i], 251.0);
			clientEyeAngles[1] += 90.0;
			PushPlayer(target_list[i], clientEyeAngles, knock,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
		}
		if (StrEqual(dir, "back",false)) {
			PushUp(target_list[i], 251.0);
			clientEyeAngles[1] += 180.0;
			PushPlayer(target_list[i], clientEyeAngles, knock,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
		}
		if (StrEqual(dir, "right",false)) {
			PushUp(target_list[i], 251.0);
			clientEyeAngles[1] -= 90.0;
			PushPlayer(target_list[i], clientEyeAngles, knock,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
		}
		if (StrEqual(dir, "up",false)) {
			PushUp(target_list[i], knock)
		}
		if (StrEqual(dir, "down",false)) {
			PushUp(target_list[i], 0-knock)
		}
		
	}
 
	return Plugin_Handled;
}
stock PushPlayer(client, Float:clientEyeAngle[3], Float:power, VelocityOverride:override[3]=VelocityOvr_None) //Chanz :D
{
	decl	Float:forwardVector[3],
	Float:newVel[3];
	
	GetAngleVectors(clientEyeAngle, forwardVector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(forwardVector, forwardVector);
	ScaleVector(forwardVector, power);
	
	Entity_GetAbsVelocity(client,newVel);
	
	for(new i=0;i<3;i++){
		switch(override[i]){
			case VelocityOvr_Velocity:{
				newVel[i] = 0.0;
			}
			case VelocityOvr_OnlyWhenNegative:{				
				if(newVel[i] < 0.0){
					newVel[i] = 0.0;
				}
			}
			case VelocityOvr_InvertReuseVelocity:{				
				if(newVel[i] < 0.0){
					newVel[i] *= -1.0;
				}
			}
		}
		
		newVel[i] += forwardVector[i];
	}
	
	Entity_SetAbsVelocity(client,newVel);
}
PushUp(client,Float:power){
	
	PushPlayer(client,Float:{-90.0,0.0,0.0},power,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
}
stock Entity_GetAbsVelocity(entity, Float:vec[3])
{
    GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vec);
}
stock Entity_SetAbsVelocity(entity, const Float:vec[3])
{
    TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vec);
}
