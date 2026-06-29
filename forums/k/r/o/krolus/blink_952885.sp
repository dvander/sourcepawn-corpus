/*
It is ripped sm_tele from funcommandsX
*/

#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>

//Definitions:
#define	CLIENTWIDTH	35.0
#define	CLIENTHEIGHT 90.0
#define PL_VERSION "0.1"

new Float:g_pos[3];

//Information:
public Plugin:myinfo =
{
	name = "Blink",
	author = "kroleg",
	description = "Self teport",
	version = PL_VERSION,
	url = "http://tf2.kz"
}

//Initation:
public OnPluginStart()
{
	RegAdminCmd("blink", Command_Blink, ADMFLAG_CUSTOM1, "Teleports you to where you are aiming!");
}

public Action:Command_Blink(client, args){
	if( !client ){
		ReplyToCommand(client, "[SM] Cannot teleport from rcon");
		return Plugin_Handled;	
	}
		
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite,TraceEntityFilterPlayer);
    	
	if(TR_DidHit(trace)){   	 
   	 	TR_GetEndPosition(vStart, trace);
		//GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
		CloseHandle(trace);
		TeleportEntity(client, g_pos, NULL_VECTOR, NULL_VECTOR);
	}
	else {
		PrintToChat(client, "\x05[SM]\x01 %s", "Can't blink there");
		CloseHandle(trace);
		return Plugin_Handled;
	}
	
	
	//return true;

	//PerformTeleport(client,client_list[i],g_pos);
	decl Float:partpos[3];

	GetClientEyePosition(client, partpos);
	partpos[2]-=20.0;	
	
	TeleportEffects(partpos);
	
	//TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	g_pos[2]+=40.0;
	
	TeleportEffects(g_pos);

	
	return Plugin_Handled;	
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
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
    }
}

TeleportEffects(Float:pos[3])
{
	//if(g_GameType == GAME_TF2)
	{
		ShowParticle(pos, "pyro_blast", 1.0);
		ShowParticle(pos, "pyro_blast_lines", 1.0);
		ShowParticle(pos, "pyro_blast_warp", 1.0);
		ShowParticle(pos, "pyro_blast_flash", 1.0);
		ShowParticle(pos, "burninggibs", 0.5);
	}
}

ShowParticle(Float:possie[3], String:particlename[], Float:time)
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