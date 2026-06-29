#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	RegConsoleCmd("particle", Command_Particle);
}

public Action:Command_Particle(client, args)
{
	new String:text[128];
	GetCmdArgString(text, sizeof(text));
	
	AttachParticle(client, text, 5.0);

	return Plugin_Handled;
}

stock AttachParticle(ent, String:particleType[], Float:time)
{
    new particle = CreateEntityByName("info_particle_system");

	decl String:tName[32];

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
        new String:classname[64];
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