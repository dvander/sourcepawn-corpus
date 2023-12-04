#pragma tabsize 0

#include <sdktools>

int point_tesla_ref = -1;
int env_fade_ref = -1;

bool bIsPluginOn[MAXPLAYERS + 1] = { false, ...};

public void OnPluginStart()
{
	RegAdminCmd("sm_thunder", Cmd_thunder, ADMFLAG_CUSTOM1); 

    HookEvent("round_freeze_end", Event_FreezeEnd);
    HookEvent("player_death", Event_PlayerDeath);
}

public Action Cmd_thunder(int iClient, int iArgs)
{
        switch(bIsPluginOn[iClient])
        {
            case true: { bIsPluginOn[iClient] = false; PrintToChat(iClient, "You have successfully turned it off"); }
            case false: { bIsPluginOn[iClient] = true; PrintToChat(iClient, "You have successfully turned it on"); }
        }
    return Plugin_Handled;
}

public void OnConfigsExecuted()
{
    PrecacheGeneric("sprites/physbeam.vmt");
}

public void Event_FreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
        if(EntRefToEntIndex(point_tesla_ref) == -1)
        {

            int entity = CreateEntityByName("point_tesla");
            
            if(entity == -1)
                return;

            point_tesla_ref = entity;

            if(IsValidEntity(entity) && IsValidEdict(entity))
                point_tesla_ref = EntIndexToEntRef(entity);


            DispatchKeyValue(entity, "beamcount_max", "8");
            DispatchKeyValue(entity, "beamcount_min", "6");
            DispatchKeyValue(entity, "interval_max", "2");
            DispatchKeyValue(entity, "interval_min", "0.5");
            DispatchKeyValue(entity, "lifetime_max", "0.3");
            DispatchKeyValue(entity, "lifetime_min", "0.3");
            DispatchKeyValue(entity, "m_Color", "255 255 255");
            DispatchKeyValue(entity, "m_flRadius", "200");
            DispatchKeyValue(entity, "m_SoundName", "DoSpark");
            DispatchKeyValue(entity, "texture", "sprites/physbeam.vmt");
            DispatchKeyValue(entity, "thick_max", "5");
            DispatchKeyValue(entity, "thick_min", "4");
            DispatchSpawn(entity);
        }

        if(EntRefToEntIndex(env_fade_ref) == -1)
        {

            int entity = CreateEntityByName("env_fade");
            
            if(entity == -1)
                return;

            env_fade_ref  = entity;

            if(IsValidEntity(entity) && IsValidEdict(entity))
                env_fade_ref  = EntIndexToEntRef(entity);


            DispatchKeyValue(entity, "duration", "0");
            DispatchKeyValue(entity, "renderamt", "255");
            DispatchKeyValue(entity, "rendercolor", "29 211 222");
            DispatchKeyValue(entity, "ReverseFadeDuration", "0");
            DispatchKeyValue(entity, "spawnflags", "0");
            DispatchSpawn(entity);


        }
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int iClient = GetClientOfUserId(GetEventInt(event, "userid"));

    if (bIsPluginOn[iClient] && GetUserFlagBits(iClient) == ADMFLAG_CUSTOM1)
    {
        if(!event.GetBool("headshot"))
            return;

        int victim = GetClientOfUserId(event.GetInt("userid"));

        float pos[3];
        GetClientEyePosition(victim, pos);

        TeleportEntity(point_tesla_ref, pos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(point_tesla_ref, "DoSpark");

        int attacker = GetClientOfUserId(event.GetInt("attacker"));

        if(attacker == 0 || !IsClientInGame(attacker) || IsFakeClient(attacker))
            return;

        AcceptEntityInput(env_fade_ref, "Fade", attacker);
    }
}
