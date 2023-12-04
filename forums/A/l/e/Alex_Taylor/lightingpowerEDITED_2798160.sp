
/*
Server event "player_death", Tick 11930:
- "userid" = "4"
- "attacker" = "2"
- "assister" = "0"
- "assistedflash" = "0"
- "weapon" = "usp_silencer"
- "weapon_itemid" = "0"
- "weapon_fauxitemid" = "17293822569102704701"
- "weapon_originalowner_xuid" = "76561197988592905"
- "headshot" = "1"
- "dominated" = "0"
- "revenge" = "0"
- "wipe" = "0"
- "penetrated" = "0"
- "noreplay" = "1"
- "noscope" = "0"
- "thrusmoke" = "0"
- "attackerblind" = "0"
- "distance" = "10.64"
*/

#include <sdktools>

int point_tesla_ref = -1;
int env_fade_ref = -1;

bool bIsPluginOn = false;

public void OnPluginStart()
{
	RegAdminCmd("sm_thunder", Cmd_thunder, ADMFLAG_SLAY); 

    HookEvent("round_freeze_end", Event_FreezeEnd);
    HookEvent("player_death", Event_PlayerDeath);
}

public Action Cmd_thunder(int iClient, int iArgs)
{
    switch(bIsPluginOn)
    {
        case true: { bIsPluginOn = false; PrintToChat(iClient, "You have successfully turned it off"); }
        case false: { bIsPluginOn = true; PrintToChat(iClient, "You have successfully turned it on"); }
    }
    return Plugin_Handled;
}

public void OnConfigsExecuted()
{
    PrecacheGeneric("sprites/physbeam.vmt");
}

public void Event_FreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (bIsPluginOn)
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
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (bIsPluginOn)
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

/*
entity
{
    "id" "1251"
    "classname" "env_fade"
    "duration" "0"
    "renderamt" "255"
    "rendercolor" "29 211 222"
    "ReverseFadeDuration" "0"
    "spawnflags" "0"
    "targetname" "fade"
    "origin" "496 720 96"
    editor
    {
        "color" "220 30 220"
        "visgroupshown" "1"
        "visgroupautoshown" "1"
        "logicalpos" "[0 0]"
    }
}

entity
{
    "id" "1240"
    "classname" "point_tesla"
    "beamcount_max" "8"
    "beamcount_min" "6"
    "interval_max" "2"
    "interval_min" "0.5"
    "lifetime_max" "0.3"
    "lifetime_min" "0.3"
    "m_Color" "255 255 255"
    "m_flRadius" "200"
    "m_SoundName" "DoSpark"
    "targetname" "tesla"
    "texture" "sprites/physbeam.vmt"
    "thick_max" "5"
    "thick_min" "4"
    "origin" "464 720 64"
    editor
    {
        "color" "220 30 220"
        "visgroupshown" "1"
        "visgroupautoshown" "1"
        "logicalpos" "[0 0]"
    }
*/ 