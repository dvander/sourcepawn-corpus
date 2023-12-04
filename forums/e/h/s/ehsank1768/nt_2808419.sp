#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

new BeamSprite, g_beamsprite, g_halosprite;
new Handle:GTrailsEnabled;

new Float:FireColorCT[] = {0, 0, 255, 225}; // Blue color for CT team
new Float:FireColorT[] = {255, 0, 0, 225}; // Red color for T team

new Float:FireColor[4];

public Plugin:myinfo = 
{
    name = "Grenade Trails",
    author = "Fredd",
    description = "Adds a trail to grenades.",
    version = "1.1",
    url = "www.sourcemod.net"
}

public OnMapStart()
{
    BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
    g_beamsprite = PrecacheModel("materials/sprites/lgtning.vmt");
    g_halosprite = PrecacheModel("materials/sprites/halo01.vmt");
}

public OnPluginStart()
{
    CreateConVar("gt_version", "1.1", "Grenade Trails Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    GTrailsEnabled = CreateConVar("gt_enables", "1", "Enables/Disables Grenade Trails");

    HookEvent("hegrenade_detonate", OnHeDetonate);
}

public OnHeDetonate(Handle:event, const String:name[], bool:dontBroadcast) 
{
    new Float:origin[3];
    origin[0] = GetEventFloat(event, "x");
    origin[1] = GetEventFloat(event, "y");
    origin[2] = GetEventFloat(event, "z");

    int thrower = GetEventInt(event, "userid");
    int client = GetClientOfUserId(thrower);
    int team = GetClientTeam(client);
    new Float:FireColor[4];
    if (team == 3)
    {
        FireColor = FireColorCT;
    }
    else if (team == 2)
    {
        FireColor = FireColorT;
    }

    TE_SetupBeamRingPoint(origin, 10.0, 400.0, g_beamsprite, g_halosprite, 1, 1, 0.2, 100.0, 1.0, FireColor, 0, 0);
    TE_SendToAll();
}

public OnEntityCreated(Entity, const String:Classname[])
{
    if (GetConVarInt(GTrailsEnabled) != 1)
        return;

    if (strcmp(Classname, "hegrenade_projectile") == 0)
    {
        int thrower = GetEntPropEnt(Entity, Prop_Send, "m_hThrower");
        int client = GetClientOfUserId(thrower);
        if (client == -1)
            return;

        int team = GetClientTeam(client);
        new Float:FireColor[4];
        if (team == 3)
        {
            FireColor = FireColorCT;
        }
        else if (team == 2)
        {
            FireColor = FireColorT;
        }

        new Float:origin[3];
        GetEntPropVector(Entity, Prop_Send, "m_vecOrigin", origin);

        TE_SetupBeamRingPoint(origin, 10.0, 400.0, BeamSprite, BeamSprite, 1, 1, 0.2, 100.0, 1.0, FireColor, 0, 0);
        TE_SendToAll();
    }
}