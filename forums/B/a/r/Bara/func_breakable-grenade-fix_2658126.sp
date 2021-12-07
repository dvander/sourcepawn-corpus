#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int g_iEntity[2048] = { -1, ... };

public Plugin myinfo =
{
    name = "Fix infinite grenade touch/landing sounds",
    author = "Bara",
    description = "",
    version = "1.0.0",
    url = "github.com/Bara"
};

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity > 0 && IsValidEntity(entity))
    {
        g_iEntity[entity] = -1;
        
        char sClass[32]
        GetEntityClassname(entity, sClass, sizeof(sClass));

        if (StrEqual(sClass, "decoy_projectile", false) || StrEqual(sClass, "smokegrenade_projectile"))
        {   
            SDKHook(entity, SDKHook_StartTouch, StartTouch);
            SDKHook(entity, SDKHook_EndTouch, EndTouch);
        }
    }
}

public Action StartTouch(int entity, int other)
{
    if (IsValidEntity(other))
    {
        char sClass[32];
        GetEntityClassname(other, sClass, sizeof(sClass));
        
        if (StrContains(sClass, "func_breakable", false) != -1)
        {
            g_iEntity[entity] = EntIndexToEntRef(other);

            int iHealth = GetEntProp(other, Prop_Data, "m_iHealth");

            if (iHealth == 0)
            {
                CreateTimer(0.5, Timer_CheckSmoke, EntIndexToEntRef(entity));
            }
        }
    }
}

public Action EndTouch(int entity, int other)
{
    if (IsValidEntity(other))
    {
        if (other == EntRefToEntIndex(g_iEntity[entity]))
        {
            g_iEntity[entity] = -1;
        }
    }
}

public Action Timer_CheckSmoke(Handle timer, int ref)
{
    int entity = EntRefToEntIndex(ref);

    if (IsValidEntity(entity))
    {
        int other = EntRefToEntIndex(g_iEntity[entity])

        if (IsValidEntity(other))
        {
            char sClass[32];
            GetEntityClassname(other, sClass, sizeof(sClass));
            
            if (StrContains(sClass, "func_breakable", false) != -1)
            {
                g_iEntity[entity] = -1;

                AcceptEntityInput(entity, "Kill");
            }
        }
    }

    return Plugin_Stop;
}
