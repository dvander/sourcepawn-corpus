#pragma semicolon 1

#include <tf2_stocks>
#include <tf2items>
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>
#include <tf2attributes>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

//0
int Ent_Index0;
char Ent_ParticleName0[256];
char Ent_AttachPoint0[256];

//1
int Ent_Index1;
char Ent_ParticleName1[256];
char Ent_AttachPoint1[256];

//2
int Ent_Index2;
char Ent_ParticleName2[256];
char Ent_AttachPoint2[256];

//3
int Ent_Index3;
char Ent_ParticleName3[256];
char Ent_AttachPoint3[256];

//4
int Ent_Index4;
char Ent_ParticleName4[256];
char Ent_AttachPoint4[256];

//5
int Ent_Index5;
char Ent_ParticleName5[256];
char Ent_AttachPoint5[256];

//6
int Ent_Index6;
char Ent_ParticleName6[256];
char Ent_AttachPoint6[256];

//7
int Ent_Index7;
char Ent_ParticleName7[256];
char Ent_AttachPoint7[256];

//8
int Ent_Index8;
char Ent_ParticleName8[256];
char Ent_AttachPoint8[256];

//9
int Ent_Index9;
char Ent_ParticleName9[256];
char Ent_AttachPoint9[256];

//10
int Ent_Index10;
char Ent_ParticleName10[256];
char Ent_AttachPoint10[256];

//11
int Ent_Index11;
char Ent_ParticleName11[256];
char Ent_AttachPoint11[256];


public Plugin myinfo = 
{
	name = "Freak Fortress 2: Particle Effects",
	author = "J0BL3SS",
	description = "Special particle effects on boss model",
	version = "1.0.0",
};

public void OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("teamplay_round_active", Event_RoundStart); // for non-arena maps
	
	HookEvent("arena_win_panel", Event_RoundEnd);
	HookEvent("teamplay_round_win", Event_RoundEnd); // for non-arena maps
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int bossClientIdx; bossClientIdx <= MaxClients; bossClientIdx++)
	{
		int bossIdx = FF2_GetBossIndex(bossClientIdx); // Well this seems to be the solution to make it multi-boss friendly
		if(bossIdx >= 0)
		{
			char AbilityName[96];
			for(int Num = 0; Num <= 11; Num++)
			{
				Format(AbilityName, sizeof(AbilityName), "special_particle_%i", Num);
				if(FF2_HasAbility(bossIdx, this_plugin_name, AbilityName))
				{
					switch(Num)
					{
						case 0:
						{
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 1, Ent_ParticleName0, sizeof(Ent_ParticleName0));
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 2, Ent_AttachPoint0, sizeof(Ent_AttachPoint0));
							Ent_Index0 = CreateParticle(Ent_ParticleName0, Ent_AttachPoint0, bossClientIdx);
						}
						case 1:
						{
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 1, Ent_ParticleName1, sizeof(Ent_ParticleName1));
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 2, Ent_AttachPoint1, sizeof(Ent_AttachPoint1));
							Ent_Index1 = CreateParticle(Ent_ParticleName1, Ent_AttachPoint1, bossClientIdx);
						}
						case 2:
						{
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 1, Ent_ParticleName2, sizeof(Ent_ParticleName2));
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 2, Ent_AttachPoint2, sizeof(Ent_AttachPoint2));
							Ent_Index2 = CreateParticle(Ent_ParticleName2, Ent_AttachPoint2, bossClientIdx);
						}
						case 3:
						{
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 1, Ent_ParticleName3, sizeof(Ent_ParticleName3));
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 2, Ent_AttachPoint3, sizeof(Ent_AttachPoint3));
							Ent_Index3 = CreateParticle(Ent_ParticleName3, Ent_AttachPoint3, bossClientIdx);
						}
						case 4:
						{
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 1, Ent_ParticleName4, sizeof(Ent_ParticleName4));
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 2, Ent_AttachPoint4, sizeof(Ent_AttachPoint4));
							Ent_Index4 = CreateParticle(Ent_ParticleName4, Ent_AttachPoint4, bossClientIdx);
						}
						case 5:
						{
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 1, Ent_ParticleName5, sizeof(Ent_ParticleName5));
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 2, Ent_AttachPoint5, sizeof(Ent_AttachPoint5));
							Ent_Index5 = CreateParticle(Ent_ParticleName5, Ent_AttachPoint5, bossClientIdx);							
						}
						case 6:
						{
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 1, Ent_ParticleName6, sizeof(Ent_ParticleName6));
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 2, Ent_AttachPoint6, sizeof(Ent_AttachPoint6));
							Ent_Index6 = CreateParticle(Ent_ParticleName6, Ent_AttachPoint6, bossClientIdx);	
						}
						case 7:
						{
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 1, Ent_ParticleName7, sizeof(Ent_ParticleName7));
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 2, Ent_AttachPoint7, sizeof(Ent_AttachPoint7));
							Ent_Index7 = CreateParticle(Ent_ParticleName7, Ent_AttachPoint7, bossClientIdx);
						}
						case 8:
						{
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 1, Ent_ParticleName8, sizeof(Ent_ParticleName8));
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 2, Ent_AttachPoint8, sizeof(Ent_AttachPoint8));
							Ent_Index8 = CreateParticle(Ent_ParticleName8, Ent_AttachPoint8, bossClientIdx);
						}
						case 9:
						{
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 1, Ent_ParticleName9, sizeof(Ent_ParticleName9));
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 2, Ent_AttachPoint9, sizeof(Ent_AttachPoint9));
							Ent_Index9 = CreateParticle(Ent_ParticleName9, Ent_AttachPoint9, bossClientIdx);
						}
						case 10:
						{
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 1, Ent_ParticleName10, sizeof(Ent_ParticleName10));
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 2, Ent_AttachPoint10, sizeof(Ent_AttachPoint10));
							Ent_Index10 = CreateParticle(Ent_ParticleName10, Ent_AttachPoint10, bossClientIdx);
						}
						case 11:
						{
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 1, Ent_ParticleName11, sizeof(Ent_ParticleName11));
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AbilityName, 2, Ent_AttachPoint11, sizeof(Ent_AttachPoint11));
							Ent_Index11 = CreateParticle(Ent_ParticleName11, Ent_AttachPoint11, bossClientIdx);
						}
						
					}
				}	
			}
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int bossClientIdx; bossClientIdx <= MaxClients; bossClientIdx++)
	{
		int bossIdx = FF2_GetBossIndex(bossClientIdx); // Well this seems to be the solution to make it multi-boss friendly
		if(bossIdx >= 0)
		{
			char AbilityName[96];
			for(int Num = 0; Num <= 11; Num++)
			{
				Format(AbilityName, sizeof(AbilityName), "special_particle_%i", Num);
				if(FF2_HasAbility(bossIdx, this_plugin_name, AbilityName))
				{
					switch(Num)
					{
						case 0:AcceptEntityInput(Ent_Index0, "kill");
						case 1:AcceptEntityInput(Ent_Index1, "kill");
						case 2:AcceptEntityInput(Ent_Index2, "kill");
						case 3:AcceptEntityInput(Ent_Index3, "kill");
						case 4:AcceptEntityInput(Ent_Index4, "kill");
						case 5:AcceptEntityInput(Ent_Index5, "kill");
						case 6:AcceptEntityInput(Ent_Index6, "kill");
						case 7:AcceptEntityInput(Ent_Index7, "kill");
						case 8:AcceptEntityInput(Ent_Index8, "kill");
						case 9:AcceptEntityInput(Ent_Index9, "kill");
						case 10:AcceptEntityInput(Ent_Index10, "kill");
						case 11:AcceptEntityInput(Ent_Index11, "kill");
					}
				}	
			}
		}
	}
}

stock int CreateParticle(const char[] particle, const char[] attachpoint, int client)
{
    float pos[3];
    
    GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
    
    int entity = CreateEntityByName("info_particle_system");
    TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
    DispatchKeyValue(entity, "effect_name", particle);
    
    SetVariantString("!activator");
    AcceptEntityInput(entity, "SetParent", client, entity, 0);
    
    SetVariantString(attachpoint);
    AcceptEntityInput(entity, "SetParentAttachment", entity, entity, 0);
    
    char t_Name[128];
    Format(t_Name, sizeof(t_Name), "target%i", client);
    
    DispatchKeyValue(entity, "targetname", t_Name);
    
    DispatchSpawn(entity);
    ActivateEntity(entity);
    AcceptEntityInput(entity, "start");
    return entity;
}

public Action FF2_OnAbility2(int bossClientIdx, const char[] plugin_name, const char[] ability_name, int status)
{
	return Plugin_Continue;
}


