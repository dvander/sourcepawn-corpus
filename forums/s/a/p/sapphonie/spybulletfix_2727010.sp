#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
    name             =  "Spy Disguise Blockbullet Fix",
    author           =  "steph&nie",
    description      =  "Fix Spy Disguise weapons blocking bullets / hitscan - originally seen here: https://youtu.be/bDlgOUOJqWk . Thanks shounic!",
    version          =  "0.0.2",
    url              =  "https://sappho.io"
}

// hook all entity spawns
public void OnEntityCreated(int entity, const char[] classname)
{
    // wait a frame so ownerid is valid
    RequestFrame(waitFrame, entity);
}

// ^
void waitFrame(int entity)
{
    // make sure actual entity itself is still valid
    if (IsValidEntity(entity))
    {
        // grab classname from entity
        char classname[128];
        GetEntityClassname(entity, classname, sizeof(classname));
        // check if entity is a tf_weapon
        if (StrContains(classname, "tf_weapon_", false) != -1)
        {
            // grab the weapon's owner entity's id
            int ownerid = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
            // if it's -1, it's almost certainly a spy ghost weapon
            if (ownerid == -1)
            {
                // yeet it.
                TeleportEntity(entity, view_as<float>({0.0, 0.0, -5000.0}), NULL_VECTOR, NULL_VECTOR);
            }
        }
    }
}
