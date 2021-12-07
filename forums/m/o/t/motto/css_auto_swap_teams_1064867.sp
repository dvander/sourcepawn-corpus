#include <sourcemod>
#include <sdktools>
#include <cstrike>
public Plugin:myinfo = 
{
	name = "CSS Auto Swap Teams",
	author = "Tomasz 'anacron' Motylinski",
	description = "Auto Swap Teams with reset cash and weapons and auto join",
	version = "2.3.20",
	url = "http://anacron.pl"
}
new String:Model_CT[3][ ] = {"models/player/ct_gign.mdl", "models/player/ct_gsg9.mdl", "models/player/ct_sas.mdl"};
new String:Model_T[3][ ] = {"models/player/t_guerilla.mdl", "models/player/t_leet.mdl", "models/player/t_phoenix.mdl"};
new Handle:GameVar_mp_maxrounds;
new Handle:GameVar_mp_startmoney;
new SwapAferRound;
new CTscore;
new Tscore;
new bool:SwapNow = false;
public OnPluginStart()
{
	PrecacheSound("ambient/misc/brass_bell_C.wav",true);
	for(new i = 0; i < 3; i++)
	{
		PrecacheModel(Model_CT[i],true);
		PrecacheModel(Model_T[i],true);
	}
	HookEvent("player_spawn", Event_Player_Spawn,EventHookMode_Post);
	HookEvent("round_freeze_end",Event_round_freeze_end,EventHookMode_Post);
	HookEvent("round_start",Event_round_start,EventHookMode_Post);
	HookEvent("round_end",Event_round_end,EventHookMode_Post);
	HookEvent("player_death",Event_player_death);
	GameVar_mp_maxrounds = FindConVar("mp_maxrounds");	
	GameVar_mp_startmoney = FindConVar("mp_startmoney");
	SwapAferRound = RoundFloat(GetConVarInt(GameVar_mp_maxrounds) / 2.0);
	CreateConVar("sm_astversion","2.3.20","Version Information",FCVAR_REPLICATED|FCVAR_NOTIFY);
}
public OnMapStart()
{
	SwapAferRound = RoundFloat(GetConVarInt(GameVar_mp_maxrounds) / 2.0);
	PrecacheSound("ambient/misc/brass_bell_C.wav",true);
	for(new i = 0; i < 3; i++)
	{
		PrecacheModel(Model_CT[i],true);
		PrecacheModel(Model_T[i],true);
	}
}

public Event_Player_Spawn(Handle:event,const String:name[],bool:dontBroadcast)
{    
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (GetClientTeam(client) == CS_TEAM_CT)
	{
		SetEntityModel(client,Model_CT[GetRandomInt(0,2)]);
	}
	else if (GetClientTeam(client) == CS_TEAM_T)
	{
		SetEntityModel(client,Model_T[GetRandomInt(0,2)]);
	}
}
public Action:Event_round_freeze_end(Handle:event,const String:name[],bool:dontBroadcast)
{
	CTscore = GetTeamScore(CS_TEAM_CT);
	Tscore = GetTeamScore(CS_TEAM_T);
	new SumScore = CTscore + Tscore;
	if(SumScore == SwapAferRound-1) 
	{
		SwapNow = true;
		PrintToChatAll("[SM] Teams will be swap after this round.");
	}
}
public Action:Event_round_end(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(SwapNow)	
	{
		CTscore = GetTeamScore(CS_TEAM_CT);
		Tscore = GetTeamScore(CS_TEAM_T);		
		SetTeamScore(CS_TEAM_CT,Tscore);
		SetTeamScore(CS_TEAM_T,CTscore);
		PrintToChatAll("[SM] Teams Scores swaped.");	
		for(new client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client))
			{
				new Team = GetClientTeam(client);
				if(Team == CS_TEAM_CT)
				{
					CS_SwitchTeam(client,CS_TEAM_T);
				}
				else if(Team == CS_TEAM_T)
				{
					CS_SwitchTeam(client,CS_TEAM_CT);
				}
			}
		}
		EmitSoundToAll("ambient/misc/brass_bell_C.wav");
		PrintToChatAll("[SM] Teams swaped.");	
	}
}
public Event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client) && GetEntProp(client,Prop_Send,"m_iAccount") < GetConVarInt(GameVar_mp_startmoney)) 
	{
		SetEntProp(client,Prop_Send,"m_iAccount",GetConVarInt(GameVar_mp_startmoney),2);
	}
}
public Action:Event_round_start(Handle:event,const String:name[],bool:dontBroadcast)
{
	new index;
	if(SwapNow)
	{
		if(IsValidEntity(FindEntityByClassname(index,"func_buyzone")))
		{
			for(new client = 1; client <= MaxClients; client++)
			{
				if(IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client)) 
				{
					new Team = GetClientTeam(client);
					SetEntProp(client,Prop_Send,"m_iAccount",GetConVarInt(GameVar_mp_startmoney),2);
					SetEntProp(client,Prop_Send,"m_ArmorValue",0,1);
					SetEntProp(client,Prop_Send,"m_bHasHelmet",0,1);
					SetEntProp(client,Prop_Send,"m_bHasDefuser",0,1);
					SetEntProp(client,Prop_Send,"m_bHasNightVision",0,1);
					new weapon_entity;
					for(new j = 0; j < 4; j++)
					{
						weapon_entity = GetPlayerWeaponSlot(client,j);
						if(IsValidEntity(weapon_entity) && j != 2) 
						{
							RemovePlayerItem(client,weapon_entity);
							if(j == 3)
							{
								weapon_entity = GetPlayerWeaponSlot(client,j);
								while(IsValidEntity(weapon_entity))
								{
									RemovePlayerItem(client,weapon_entity);
									weapon_entity = GetPlayerWeaponSlot(client,j);
								}
							}
						}
					}
					if(Team == CS_TEAM_CT)
					{
						SetEntProp(client,Prop_Send,"m_bHasDefuser",1,1);
						GivePlayerItem(client,"weapon_usp");
					}
					else if(Team == CS_TEAM_T)
					{
						GivePlayerItem(client,"weapon_glock");
					}
				}
				
			}
		}
		SwapNow = false;
	}
	else
	{
		for(new client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client) && (GetClientTeam(client) == CS_TEAM_CT))
			{
				SetEntProp(client,Prop_Send,"m_bHasDefuser",1,1);
			}
		}
	}
}
