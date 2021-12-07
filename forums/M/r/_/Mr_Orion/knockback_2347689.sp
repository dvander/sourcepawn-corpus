#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"
#define DMG_GENERIC            0
#define DMG_PREVENT_PHYSICS_FORCE    (1 << 11)

new Handle:fCvar_PushForceUp = INVALID_HANDLE;
  
public Plugin:myinfo =
{
	name = "Push player",
	author = "Orion && bit of code from Chanz's plugin :D",
	description = "Push player",
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
	fCvar_PushForceUp = CreateConVar("knockback_pushforceup", "251.0", "Upward push force."); // Why 251 ? Idk. D:

	RegAdminCmd("sm_knockback", Command_Knockback, ADMFLAG_ROOT, "Direction = 0, forward | 1, left | 2, backward | 3, right");
}

public Action:Command_Knockback(client, args)
{
	new String:arg1[32], String:arg2[32], String:arg3[32], String:arg4[5];
	new damage;
	new Float:knock;
	new dir;
 
	GetCmdArg(1, arg1, sizeof(arg1))
	GetCmdArg(2, arg2, sizeof(arg2))
	GetCmdArg(3, arg3, sizeof(arg3))
	GetCmdArg(4, arg4, sizeof(arg4))

	if (args == 4)
	{
		knock = StringToFloat(arg2);
		damage = StringToInt(arg3); 
		dir = StringToInt(arg4);
	} else {
		ReplyToCommand(client, "[SM] Usage: sm_knockback <target> <power> <damage> <direction>");
		return Plugin_Handled;
	}
	if (knock < 1)
	{
		ReplyToCommand(client, "Knockback power must be higher than 0");
		return Plugin_Handled;
	}
	if (dir < 0 || dir > 3)
	{
		ReplyToCommand(client, "Direction must be between 0 and 3");
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

		PushUp(target_list[i], GetConVarFloat(fCvar_PushForceUp));
		
		if (dir == 0) PushPlayer(target_list[i], clientEyeAngles, knock,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
		if (dir == 1) {
			clientEyeAngles[1] += 90.0;
			PushPlayer(target_list[i], clientEyeAngles, knock,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
		}
		if (dir == 2) {
			clientEyeAngles[1] += 180.0;
			PushPlayer(target_list[i], clientEyeAngles, knock,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
		}
		if (dir == 3) {
			clientEyeAngles[1] -= 90.0;
			PushPlayer(target_list[i], clientEyeAngles, knock,VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
		}
		DealDamage(target_list[i], damage, client, DMG_PREVENT_PHYSICS_FORCE);
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
stock DealDamage(victim, damage, attacker=0, dmg_type=DMG_GENERIC)
{
    if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage>0)
    {
        new String:dmg_str[16];
        IntToString(damage,dmg_str,16);
        new String:dmg_type_str[32];
        IntToString(dmg_type,dmg_type_str,32);
        new pointHurt=CreateEntityByName("point_hurt");
        if(pointHurt)
        {
            DispatchKeyValue(victim,"targetname","war3_hurtme");
            DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
            DispatchKeyValue(pointHurt,"Damage",dmg_str);
            DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
            DispatchSpawn(pointHurt);
            AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
            DispatchKeyValue(pointHurt,"classname","point_hurt");
            DispatchKeyValue(victim,"targetname","war3_donthurtme");
            RemoveEdict(pointHurt);
        }
    }
}