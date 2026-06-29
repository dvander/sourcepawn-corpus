#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

new BossTeam=_:TFTeam_Blue;

public Plugin:myinfo = {
    name = "Freak Fortress 2: Completely Stripped Version of Darth's Ability Pack Fix",
    author = "Darthmule, edit by Deathreus",
    version = "1.2",
};

#define MAX_PLAYERS 33

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
    decl Float:distance;
    decl i;
    
    GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
    for(i=1; i<=MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam && !TF2_IsPlayerInCondition(i,TFCond_Ubercharged))
        {
            GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
            distance = GetVectorDistance( pos, pos2 );
            if (distance < Range && GetClientTeam(i)!=BossTeam)
			{
                SetVariantInt(0);
                AcceptEntityInput(i, "SetForcedTauntCam");
                
                switch(cEffect)
                {
                    case 0:
                        TF2_IgnitePlayer(i, Boss);
                    case 1: 
                        TF2_MakeBleed(i, Boss, fDuration);
                    case 2:
                        TF2_AddCondition(i, TFCond_RestrictToMelee, fDuration);
                    case 3:
                        TF2_AddCondition(i, TFCond_MarkedForDeath, fDuration);
                    case 4:
                        TF2_AddCondition(i, TFCond_Milked, fDuration);
                    case 5:
                        TF2_AddCondition(i, TFCond_Jarated, fDuration);
					case 6:
						TF2_StunPlayer(i, fDuration, 0.0, TF_STUNFLAG_BONKSTUCK, Boss);
					case 7:
						TF2_AddCondition(Boss, TFCond_DefenseBuffed, fDuration);
					case 8:
						TF2_AddCondition(Boss, TFCond_SpeedBuffAlly, fDuration);
						
                }
            }
        }    
    }
}