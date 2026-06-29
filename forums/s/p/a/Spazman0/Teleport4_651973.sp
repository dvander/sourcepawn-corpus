#include <sourcemod>
#include <sdktools>

 public Plugin:myinfo = 
{
name = "Point-Tele",
author = "Spazman0",
description = "Teleport a user to the cursor.",
version = SOURCEMOD_VERSION,
url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegAdminCmd("sm_tele", Command_tele, ADMFLAG_SLAY)
	LoadTranslations("common.phrases");
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
	{
		return entity > GetMaxClients() || !entity;
	} 

public ShowParticle(Float:possie[3], String:particlename[], Float:time)
{
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, possie, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", particlename);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, particle);
    }
    else
    {
        LogError("ShowParticle: could not create info_particle_system");
    }    
}

AttachParticle(ent, String:particleType[], Float:time)
{
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        new Float:pos[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
        DispatchKeyValue(particle, "targetname", "tf2particle");
        DispatchKeyValue(particle, "parentname", tName);
        DispatchKeyValue(particle, "effect_name", particleType);
        DispatchSpawn(particle);
        SetVariantString(tName);
        AcceptEntityInput(particle, "SetParent", particle, particle, 0);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, particle);
    }
    else
    {
        LogError("AttachParticle: could not create info_particle_system");
    }
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classname[32];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(particle);
        }
        else
        {
            LogError("DeleteParticles: not removing entity - not a particle '%s'", classname);
        }
    }
}

public Action:Command_tele(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_tele <#userid|name>");
		return Plugin_Handled;
	}
	new Float:vAngles[3], Float:vOrigin[3], Float:pos[3];
    
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new String:arg1[32]
	
	GetCmdArg(1, arg1, sizeof(arg1))
	
	
	
	
	new target = FindTarget(client, arg1)
	if(target == -1)
	{
		return Plugin_Handled;
	}
		
    
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
    
	if(TR_DidHit(trace))
	{
   	 	
   	 
   	 	TR_GetEndPosition(pos, trace);
   	 	
   		//Distance = (GetVectorDistance(vOrigin, pos)- 35.0); //-35 to get them out of a wall.
   	 	pos[2] += 10.0;	
    	//TeleportEntity( target, pos, NULL_VECTOR, NULL_VECTOR )	 

	}
	CloseHandle(trace);
	
		 
	new String:name[MAX_NAME_LENGTH]
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml, Float:partpos[3];
	
	GetClientName(target, name, sizeof(name))
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			name,
			sizeof(name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		GetClientEyePosition(target_list[i], partpos)
		partpos[2]-=20.0
		ShowParticle(partpos, "pyro_blast", 1)
		ShowParticle(partpos, "pyro_blast_lines", 1)
		ShowParticle(partpos, "pyro_blast_warp", 1)
		ShowParticle(partpos, "pyro_blast_flash", 1)
		ShowParticle(partpos, "burninggibs", 1)
		TeleportEntity(target_list[i], pos, NULL_VECTOR, NULL_VECTOR)
		pos[2]+=40.0
		ShowParticle(pos, "pyro_blast", 1)
		ShowParticle(pos, "pyro_blast_lines", 1)
		ShowParticle(pos, "pyro_blast_warp", 1)
		ShowParticle(pos, "pyro_blast_flash", 1)
		ShowParticle(pos, "burninggibs", 1)
		
	}


	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%s", "was Teleported!", name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%s", "was Teleported!", "_s", name);
	}
	
	
	
	
	LogAction(client, target, "\"%N\" teleported \"%N\"" , client, target)
	
	ReplyToCommand(client, "You Teleported %s.", name)
	
	return Plugin_Handled;
	
}

