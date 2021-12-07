#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>

#define PLUGIN_VERSION  "2.0"
#define DMG_GENERIC			0
#define DMG_CRUSH			(1 << 0)
#define DMG_BULLET			(1 << 1)
#define DMG_SLASH			(1 << 2)
#define DMG_BURN			(1 << 3)
#define DMG_VEHICLE			(1 << 4)
#define DMG_FALL			(1 << 5)
#define DMG_BLAST			(1 << 6)
#define DMG_CLUB			(1 << 7)
#define DMG_SHOCK			(1 << 8)
#define DMG_SONIC			(1 << 9)
#define DMG_ENERGYBEAM			(1 << 10)
#define DMG_PREVENT_PHYSICS_FORCE	(1 << 11)
#define DMG_NEVERGIB			(1 << 12)
#define DMG_ALWAYSGIB			(1 << 13)
#define DMG_DROWN			(1 << 14)
#define DMG_TIMEBASED			(DMG_PARALYZE | DMG_NERVEGAS | DMG_POISON | DMG_RADIATION | DMG_DROWNRECOVER | DMG_ACID | DMG_SLOWBURN)
#define DMG_PARALYZE			(1 << 15)
#define DMG_NERVEGAS			(1 << 16)
#define DMG_POISON			(1 << 17)
#define DMG_RADIATION			(1 << 18)
#define DMG_DROWNRECOVER		(1 << 19)
#define DMG_ACID			(1 << 20)
#define DMG_SLOWBURN			(1 << 21)
#define DMG_REMOVENORAGDOLL		(1 << 22)
#define DMG_PHYSGUN			(1 << 23)
#define DMG_PLASMA			(1 << 24)
#define DMG_AIRBOAT			(1 << 25)
#define DMG_DISSOLVE			(1 << 26)
#define DMG_BLAST_SURFACE		(1 << 27)
#define DMG_DIRECT			(1 << 28)
#define DMG_BUCKSHOT			(1 << 29)


new bool:sd;

new Handle:plugin_enable = INVALID_HANDLE;
new Handle:brokenbottle = INVALID_HANDLE;
new Handle:hurtme = INVALID_HANDLE;
new Handle:cvheal = INVALID_HANDLE;
new Handle:cooldown = INVALID_HANDLE;
new Handle:cooldowntime[MAXPLAYERS+1] = INVALID_HANDLE;
new bool:drinking[MAXPLAYERS+1] = false;
new Float:orig[MAXPLAYERS+1][3];

new enablehook = 0;
new healhook = 0;
new Float:cooldownhook = 0.0;
new broken = 0;
new hurthook = 0;

public Plugin:myinfo = 
{
    name = "Drunken Heal",
    author = "Fire - Dragonshadow",
    description = "Demoman Bottle Taunt Now Heals",
    version = PLUGIN_VERSION,
    url = "www.snigsclan.com"
}

public OnPluginStart()
{
    
    CreateConVar("sm_drunkenheal_version", PLUGIN_VERSION, "Drunken Heal Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    cvheal = CreateConVar("sm_drunkenheal_amount", "15", "Amount Healed By Bottle (Default 15)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, false, 0.0);
    cooldown = CreateConVar("sm_drunkenheal_cooldown", "10.0", "Heal Cooldown Time [In Seconds] | 0 = Disabled (Default 10)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, false);
    plugin_enable = CreateConVar("sm_drunkenheal_enable", "1", "Enable/Disable Drunken Heal", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
    brokenbottle = CreateConVar("sm_drunkenheal_broken", "1", "If set, broken bottle's only heal (or hurt) for half", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
    hurtme = CreateConVar("sm_drunkenheal_hurt", "0", "If set, bottle hurts instead of heals", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
//    RegConsoleCmd("sm_bottleme", BottleMe);

    HookEvent("teamplay_round_stalemate", Event_SuddenDeathStart);
    HookEvent("teamplay_round_start", Event_SuddenDeathEnd);
    HookEvent("teamplay_round_win", Event_SuddenDeathEnd);
    
    HookConVarChange(cvheal, OnCvarChanged);
    HookConVarChange(plugin_enable, OnCvarChanged);
    HookConVarChange(cooldown, OnCvarChanged);
    HookConVarChange(brokenbottle, OnCvarChanged);
    HookConVarChange(hurtme, OnCvarChanged);
}

public OnConfigsExecuted() 
{
    enablehook = GetConVarInt(plugin_enable);
    cooldownhook = GetConVarFloat(cooldown);
    healhook = GetConVarInt(cvheal);
    broken = GetConVarInt(brokenbottle);
    hurthook = GetConVarInt(hurtme);
} 

public OnCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
    enablehook = GetConVarInt(plugin_enable);
    cooldownhook = GetConVarFloat(cooldown);
    healhook = GetConVarInt(cvheal);
    broken = GetConVarInt(brokenbottle);
    hurthook = GetConVarInt(hurtme);
} 

public OnEventShutdown()
{
    UnhookEvent("teamplay_round_stalemate", Event_SuddenDeathStart);
    UnhookEvent("teamplay_round_start", Event_SuddenDeathEnd);
    UnhookEvent("teamplay_round_win", Event_SuddenDeathEnd);
}

public OnMapStart()
{
    sd = false;
    for (new i = 1; i < MaxClients; i++)
    {
        cooldowntime[i] = INVALID_HANDLE;
    }
}

public Action:OnClientCommand(client, args)
{	
    if (enablehook)
    {
        new String:cmd0[91];
        GetCmdArg(0, cmd0, sizeof(cmd0));
        if (StrEqual(cmd0, "taunt"))
        {
            if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
            {
                new wpn = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"); 
                new String:weapon[34];
                GetEdictClassname(wpn, weapon, sizeof(weapon));
                if ((strcmp(weapon, "tf_weapon_bottle", false)) == 0)
                {
                    if (sd != true)
                    { 
                        if (cooldowntime[client] == INVALID_HANDLE)
                        {
                            if (!drinking[client])
                            {
                                if(cooldownhook>0)
                                {
                                    cooldowntime[client] = CreateTimer(cooldownhook, cooldowntimer, client);
                                }
                                drinking[client] = true;
                                
                                new num = (client) | (wpn << 16);
                                GetClientAbsOrigin(client, orig[client]);
                                CreateTimer(2.2, startdrinkin, num);
                                CreateTimer(4.5, donedrinkin, client);
                            }
                        }
                    }
                    else
                    {
                        PrintHintText(client, "Drunken Heal Disabled In Sudden Death!");
                    }
                    
                }
            }
        }
    }
    return Plugin_Continue;
}

public Action:cooldowntimer(Handle:timer, any:client)
{
    if (IsValidEntity(client))
    {
        if (IsClientInGame(client) && IsPlayerAlive(client)) 
        {
            PrintHintText(client, "Your Bottle Is Full Again");
        }
    }
    cooldowntime[client] = INVALID_HANDLE;
    return Plugin_Continue;
}

public Action:donedrinkin(Handle:timer, any:client)
{
    {
        drinking[client] = false;
    }
    return Plugin_Continue;
}

public Action:startdrinkin(Handle:timer, any:num)
{
    new client = num & 0xFFFF, enti = (num >> 16) & 0xFFFF;
    if (IsValidEntity(client))
    {
        if (IsClientInGame(client) && IsPlayerAlive(client))
        {
            new Float:norigin[3];
            GetClientAbsOrigin(client, norigin);
            if(ArrayEqual(orig[client],norigin, 3))
            {
                new hp = healhook;
                if(broken)
                {
                    if(GetEntProp(enti, Prop_Send, "m_bBroken") == 1)
                    {
                        hp = RoundFloat(healhook * 0.5);
                    }
                }

                if(hurthook)
                {
                    DealDamage(client,hp,client,DMG_DROWN,"tf_weapon_bottle");
                }
                else
                {
                    new health = GetClientHealth(client);
                    if (health + hp >= 175)
                    {
                        SetEntityHealth(client, 175);
                    }
                    else
                    {
                        SetEntityHealth(client, health + hp);
                    }
                }
                /*
                else if (health + hp < health)
                {
                    DealDamage(client,hp,client,DMG_DROWN,"tf_weapon_bottle");
                }
                */
            }
        }
    }
    return Plugin_Continue;
}

public Action:BottleMe(client, args)
{
    DealDamage(client,1000,client,DMG_GENERIC,"tf_weapon_bottle");
}

public Event_SuddenDeathStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    sd = true;
}

public Event_SuddenDeathEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    sd = false;
}

stock ArrayEqual(any:one[], any:two[], length) 
{
    for (new i=0; i<length; i++) 
    { 
        if (one[i] != two[i])
        {
            return false; 
        }
        return true;
    }
    return false;
}

stock DealDamage(victim,damage,attacker=0,dmg_type=DMG_GENERIC,String:weapon[]="")
{
    if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage>0)
    {
        new String:dmg_str[16];
        IntToString(damage,dmg_str,16);
        new String:dmg_type_str[32];
        IntToString(dmg_type,dmg_type_str,32);
        new pointHurt=CreateEntityByName("point_hurt");
        if(pointHurt)
        {
            DispatchKeyValue(victim,"targetname","war3_hurtme");
            DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
            DispatchKeyValue(pointHurt,"Damage",dmg_str);
            DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
            if(!StrEqual(weapon,""))
            {
                DispatchKeyValue(pointHurt,"classname",weapon);
            }
            DispatchSpawn(pointHurt);
            AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
            DispatchKeyValue(pointHurt,"classname","point_hurt");
            DispatchKeyValue(victim,"targetname","war3_donthurtme");
            RemoveEdict(pointHurt);
        }
    }
}