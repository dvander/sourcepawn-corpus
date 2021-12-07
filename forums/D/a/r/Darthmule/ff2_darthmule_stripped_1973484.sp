#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo = {
    name = "Freak Fortress 2: Completely Stripped Version of Darth's Ability Pack Fix",
    author = "Darthmule",
    version = "1.0",
};
    
public OnPluginStart2()
{
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
    if (!strcmp(ability_name, "rage_condition"))
        Rage_Condition(ability_name, index);
}

Rage_Condition(const String:ability_name[], index)
{
    new Boss        =   GetClientOfUserId(FF2_GetBossUserId(index));
    new cEffect     =   FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);        // Effect (cases)
    new Float:fDuration   =   FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 2);        // Duration (if valid)
    new Float:Range =   FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 3);   // Range
    
    decl Float:pos[3];
    decl Float:pos2[3];
    
    GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
    for(new Victim=1; Victim<=MaxClients; Victim++)
    {
        if(IsClientInGame(Victim) && IsPlayerAlive(Victim) && GetClientTeam(Victim)!=BossTeam)
        {
            GetEntPropVector(Victim, Prop_Send, "m_vecOrigin", pos2);
            if ((GetVectorDistance(pos, pos2)<Range)) {
            
                SetVariantInt(0);
                AcceptEntityInput(Victim++, "SetForcedTauntCam");
                
                switch(cEffect)
                {
                    case 0:
                        TF2_IgnitePlayer(Boss, Victim);
                    case 1: 
                        TF2_MakeBleed(Victim, Boss, fDuration);
                    case 2:
                        TF2_AddCondition(Victim, TFCond_RestrictToMelee, fDuration);
                    case 3:
                        TF2_AddCondition(Victim, TFCond_MarkedForDeath, fDuration);
                    case 4:
                        TF2_AddCondition(Victim, TFCond_Milked, fDuration);
                    case 5:
                        TF2_AddCondition(Victim, TFCond_Jarated, fDuration);
                }
            }
        }    
    }
}