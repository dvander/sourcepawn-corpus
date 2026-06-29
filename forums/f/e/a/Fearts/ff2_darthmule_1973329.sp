#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define MB 3
#define ME 2048

new Float:BossCharge[MAXPLAYERS+1][8];

public Plugin:myinfo = {
    name = "Freak Fortress 2: Darthmule's Abilities",
    author = "Darthmule",
};

new BossTeam=_:TFTeam_Blue;

public OnPluginStart2()
{
    HookEvent("teamplay_round_start", event_round_start);
    HookEvent("player_death", event_player_death);
    LoadTranslations("freak_fortress_2.phrases");
}

public Native_GetBossCharge(Handle:plugin,numParams)
{
    new index = GetNativeCell(1);
    new slot = GetNativeCell(2);
    return _:BossCharge[index][slot];
}

public Native_SetBossCharge(Handle:plugin,numParams)
{
    new index = GetNativeCell(1);
    new slot = GetNativeCell(2);
    BossCharge[index][slot] = Float:GetNativeCell(3);
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
    CreateTimer(0.3,Timer_GetBossTeam);
    return Plugin_Continue;
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
    new index=FF2_GetBossIndex(GetClientOfUserId(GetEventInt(event, "attacker")));
    if (index!=-1 && FF2_HasAbility(index,this_plugin_name,"special_killgivesrage"))
    {
        if (BossCharge[index][0] < 100)
            BossCharge[index][0] += 2.5;
    }
    
    if (index!=-1 && FF2_HasAbility(index,this_plugin_name,"special_killgivesrage2"))
    {
        if (BossCharge[index][0] < 100)
            BossCharge[index][0] += 5.0;
    }
        
    return Plugin_Continue;
}

public Action:Timer_GetBossTeam(Handle:hTimer)
{
    BossTeam=FF2_GetBossTeam();
    return Plugin_Continue;
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
    if (!strcmp(ability_name,"rage_sethp"))    
        Rage_DeductHealth(ability_name,index);   
    else if (!strcmp(ability_name,"rage_ignite"))    
        Rage_IgnitePlayers(ability_name,index);
    else if (!strcmp(ability_name,"rage_bleed"))    
        Rage_BleedPlayers(ability_name,index);
    else if (!strcmp(ability_name,"rage_mark"))    
        Rage_MarkPlayers(ability_name,index);
}        

Rage_DeductHealth(const String:ability_name[],index)
{
    decl Float:pos[3];
    decl Float:pos2[3];
    decl i;
    new value1=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);                  // Are Übercharged players affected? (Default = true unless 0 is specifically defined)
    new Float:value2=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 2, 35.0);   // Define new health of the victim(s) (Default = 35 health)
    new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
    GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
    new Float:ragedist=FF2_GetRageDist(index,this_plugin_name,ability_name);
    for(i=1;i<=MaxClients;i++)
        if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
        {
            GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
            if(value1==0)
            {
                if (!TF2_IsPlayerInCondition(i,TFCond_Ubercharged) && (GetVectorDistance(pos,pos2)<ragedist))
                    SetEntProp(i, Prop_Data, "m_iHealth", value2);
            }
            else
            {
                if ((GetVectorDistance(pos,pos2)<ragedist))
                    SetEntProp(i, Prop_Data, "m_iHealth", value2);
            }
        }
}

Rage_IgnitePlayers(const String:ability_name[],index)
{
    decl Float:pos[3];
    decl Float:pos2[3];
    decl i;
    new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
    new value1=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);                  // Are Übercharged players affected? (Default = true unless 0 is specifically defined)
    GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
    new Float:ragedist=FF2_GetRageDist(index,this_plugin_name,ability_name);
    for(i=1;i<=MaxClients;i++)
        if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
        {
            GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
            if(value1==0)
            {
                if (!TF2_IsPlayerInCondition(i,TFCond_Ubercharged) && (GetVectorDistance(pos,pos2)<ragedist))
                    TF2_IgnitePlayer(i, Boss);
            }
            else
            {
                if ((GetVectorDistance(pos,pos2)<ragedist))
                    TF2_IgnitePlayer(i, Boss);
            }
        }
}

Rage_MarkPlayers(const String:ability_name[],index)
{
    decl Float:pos[3];
    decl Float:pos2[3];
    decl i;
    new value1=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);                  // Are Übercharged players affected? (Default = true unless 0 is specifically defined)
    new Float:value2=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 2, 12.0); // Duration of the condition (Default = 12 seconds)
    decl String:s[64];
    FloatToString(value2,s,64);
    new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
    GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
    new Float:ragedist=FF2_GetRageDist(index,this_plugin_name,ability_name);
    for(i=1;i<=MaxClients;i++)
        if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
        {
            GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
            if(value1==0)
            {
                if (!TF2_IsPlayerInCondition(i,TFCond_Ubercharged) && (GetVectorDistance(pos,pos2)<ragedist))
                    TF2_AddCondition(i, TFCond_MarkedForDeath, value2);
            }
            else
            {
                if ((GetVectorDistance(pos,pos2)<ragedist))
                    TF2_AddCondition(i, TFCond_MarkedForDeath, value2);
            }
        }
}

Rage_BleedPlayers(const String:ability_name[],index)
{
    decl Float:pos[3];
    decl Float:pos2[3];
    decl i;
    new value1=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);                  // Are Übercharged players affected? (Default = true unless 0 is specifically defined)
    new Float:value2=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 2, 12.0); // Duration of the condition (Default = 12 seconds)
    decl String:s[64];
    FloatToString(value2,s,64);
    new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
    GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
    new Float:ragedist=FF2_GetRageDist(index,this_plugin_name,ability_name);
    for(i=1;i<=MaxClients;i++)
        if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
        {
            GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
            if(value1==0)
            {
                if (!TF2_IsPlayerInCondition(i,TFCond_Ubercharged) && (GetVectorDistance(pos,pos2)<ragedist))
                    TF2_AddCondition(i, TFCond_Bleeding, value2);
            }
            else
            {
                if ((GetVectorDistance(pos,pos2)<ragedist))
                    TF2_AddCondition(i, TFCond_Bleeding, value2);
            }
        }
}