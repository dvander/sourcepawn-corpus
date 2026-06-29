#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

new bool:PP_bol = false;
new String:sParticles[64];
new iHolyness = 1;

public Plugin:myinfo = {
	name = "Freak Fortress 2: Projectile Particles (1.2)",
	author = "Otokiru",
};

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", event_round_start);
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	if (!strcmp(ability_name,"projectile_particles"))
		PP(index,ability_name);
	return Plugin_Continue;
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	PP_bol = false;
	return Plugin_Continue;
}

PP(index,const String:ability_name[])
{
	FF2_GetAbilityArgumentString(index,this_plugin_name,ability_name, 1, sParticles, 64);
	iHolyness=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);

	if(!StrEqual(sParticles,""))
		PP_bol = true;
}

public OnEntityCreated(entity, const String:classname[])
{
	if(PP_bol){
		if(StrEqual(classname, "tf_projectile_arrow") ||
		StrEqual(classname, "tf_projectile_ball_ornament") ||
		StrEqual(classname, "tf_projectile_energy_ball") ||
		StrEqual(classname, "tf_projectile_energy_ring") ||
		StrEqual(classname, "tf_projectile_flare") ||
		StrEqual(classname, "tf_projectile_healing_bolt") ||
		StrEqual(classname, "tf_projectile_jar") ||
		StrEqual(classname, "tf_projectile_jar_milk") ||
		StrEqual(classname, "tf_projectile_pipe") ||
		StrEqual(classname, "tf_projectile_pipe_remote") ||
		StrEqual(classname, "tf_projectile_rocket") ||
		StrEqual(classname, "tf_projectile_sentryrocket") ||
		StrEqual(classname, "tf_projectile_stun_ball") ||
		StrEqual(classname, "tf_projectile_syringe"))
		{
			SDKHook(entity, SDKHook_Spawn, Arrow);
		}
	}
}

public Arrow(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	
	if(client < 1)
	{
		return;
	}
	if(FF2_GetBossIndex(client) != -1)
		if(IsClientInGame(client) && IsPlayerAlive(client))
			HolyArrow(entity);

	SDKUnhook(entity, SDKHook_Spawn, Arrow);
}

HolyArrow(entity)
{
	for(new i=1; i <= iHolyness; i++)
	{
		CreateParticle(entity, sParticles, true);
	}
}

stock CreateParticle(iEntity, String:strParticle[], bool:bAttach = false, String:strAttachmentPoint[]="", Float:fOffset[3]={0.0, 0.0, 0.0})
{
    new iParticle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(iParticle))
    {
        decl Float:fPosition[3];
        decl Float:fAngles[3];
        decl Float:fForward[3];
        decl Float:fRight[3];
        decl Float:fUp[3];
        
        // Retrieve entity's position and angles
        //GetClientAbsOrigin(iClient, fPosition);
        //GetClientAbsAngles(iClient, fAngles);
        GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPosition)
		
        // Determine vectors and apply offset
        GetAngleVectors(fAngles, fForward, fRight, fUp);
        fPosition[0] += fRight[0]*fOffset[0] + fForward[0]*fOffset[1] + fUp[0]*fOffset[2];
        fPosition[1] += fRight[1]*fOffset[0] + fForward[1]*fOffset[1] + fUp[1]*fOffset[2];
        fPosition[2] += fRight[2]*fOffset[0] + fForward[2]*fOffset[1] + fUp[2]*fOffset[2];
        
        // Teleport and attach to client
        //TeleportEntity(iParticle, fPosition, fAngles, NULL_VECTOR);
        TeleportEntity(iParticle, fPosition, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(iParticle, "effect_name", strParticle);

        if (bAttach == true)
        {
            SetVariantString("!activator");
            AcceptEntityInput(iParticle, "SetParent", iEntity, iParticle, 0);            
            
            if (StrEqual(strAttachmentPoint, "") == false)
            {
                SetVariantString(strAttachmentPoint);
                AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle, iParticle, 0);                
            }
        }

        // Spawn and start
        DispatchSpawn(iParticle);
        ActivateEntity(iParticle);
        AcceptEntityInput(iParticle, "Start");
    }

    return iParticle;
}