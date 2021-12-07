#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <clientprefs>

#pragma semicolon 1

#define NO_ATTACH 0
#define ATTACH_NORMAL 1
#define ATTACH_HEAD 2

new bool:g_Sparkled[MAXPLAYERS+1];
new particle;

#define PLUGIN_VERSION      "1.01"

public Plugin:myinfo =
{
    name        = "[TF2] Sparkles",
    author      = "Master Xykon",
    description = "Adds Community Sparkle trails",
    version     = PLUGIN_VERSION
};

public OnPluginStart()
{
    CreateConVar("sm_sparkletrail_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    RegConsoleCmd("sm_sparkle_head", SparkleHead, "Become Sparkly");
    RegConsoleCmd("sm_sparkle_feet", SparkleNormal, "Become Sparkly");
    
    RegConsoleCmd("sm_sparkle_off", SparkleOff, "Remove Sparkly");
}

public OnClientDisconnect(client)
{
    if(g_Sparkled[client] == true)
    {    
        DeleteParticle(client, particle);
        g_Sparkled[client] = false;
    }
}

public Action:SparkleNormal(client, args)
{
    if(g_Sparkled[client] == true)
    {
        PrintToChat(client, "[SM] Sorry, you've already been Sparkled!");
        return Plugin_Handled;
    }
    else
    {
        CreateParticle("community_sparkle", 300.0, client, ATTACH_NORMAL);
		PrintToChat(client, "[Sparkles] You've been Self-Made'd!");
        g_Sparkled[client] = true;
        return Plugin_Handled;
    }
}

public Action:SparkleHead(client, args)
{
    if(g_Sparkled[client] == true)
    {
        PrintToChat(client, "[Sparkles] Sorry, you've already been Self-Made!");
        return Plugin_Handled;
    }
    else
    {
        CreateParticle("community_sparkle", 300.0, client, ATTACH_HEAD);
        PrintToChat(client, "[Sparkles] You've been Self-Made'd!");
        g_Sparkled[client] = true;
        return Plugin_Handled;
    }
}

public Action:SparkleOff(client, args)
{
    if (g_Sparkled[client] == true)
    {
        DeleteParticle(client, particle);
        PrintToChat(client, "[Sparkles]  Your Self-Made wore off!");
        g_Sparkled[client] = false;
    }
    else
    {
        PrintToChat(client, "[Sparkles]  Sorry, you're not Self-Made'd!");
    }
    return Plugin_Handled;
}

stock Handle:CreateParticle(String:type[], Float:time, entity, attach=NO_ATTACH, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0)
{
    particle = CreateEntityByName("info_particle_system");
    
    if (IsValidEdict(particle))
    {
        decl Float:pos[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
        pos[0] += xOffs;
        pos[1] += yOffs;
        pos[2] += zOffs;
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", type);

        if (attach != NO_ATTACH)
        {
            SetVariantString("!activator");
            AcceptEntityInput(particle, "SetParent", entity, particle, 0);
        
            if (attach == ATTACH_HEAD)
            {
                SetVariantString("head");
                AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
            }
        }
        DispatchKeyValue(particle, "targetname", "present");
        DispatchSpawn(particle);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "Start");
    }
    else
    {
        LogError("(CreateParticle): Could not create info_particle_system");
    }
    
    return INVALID_HANDLE;
}

public Action:DeleteParticle(client, any)
{
    if (IsValidEdict(particle))
    {
        new String:classname[64];
        GetEdictClassname(particle, classname, sizeof(classname));
        
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(particle);
        }
    }
}