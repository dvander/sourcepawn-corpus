#pragma semicolon 1
#include <sourcemod>    
#include <sdktools>
#include <cstrike>

#define	STANDARDMAPSMAX	12

new String:BSAL[1];
new EIBA = -1;
new EIBB = -1;
new Handle:Timer = INVALID_HANDLE;
new String:StandardMaps[STANDARDMAPSMAX][2][11] =
{	
	{
		"de_aztec","B"
	},
	{
		"de_cbble","A"
	},
	{
		"de_chateau","A"
	},
	{
		"de_dust","A"
	},
	{
		"de_dust2","A"
	},
	{
		"de_inferno","B"
	},
	{
		"de_nuke","B"
	},
	{
		"de_piranesi","A"
	},
	{
		"de_port","A"
	},
	{
		"de_prodigy","B"
	},
	{
		"de_tides","A"
	},
	{
		"de_train","A"
	}
};

public Plugin:myinfo =
{
    name = "Bombsite Limiter",
    author = "Tomasz 'anacron' Motylinski",
    description = "Limiting Bomsites when due to low CT players.",
    version = "1.2.3",
    url = "http://anacron.pl/"
}
public OnPluginStart()
{
	HookEvent("round_freeze_end",Event_RoundFreezeEnd,EventHookMode_Post); 
	HookEvent("bomb_planted",Event_RoundEnd,EventHookMode_Post); 
	HookEvent("round_end",Event_RoundEnd,EventHookMode_Post); 
	CreateConVar("sm_bslimiter","1.2.3","Version Information",FCVAR_REPLICATED|FCVAR_NOTIFY);
}
stock bool:IsVecBetween(const Float:vecVector[3],const Float:vecMin[3],const Float:vecMax[3]) 
{ 
    return ( (vecMin[0] <= vecVector[0] <= vecMax[0]) && 
             (vecMin[1] <= vecVector[1] <= vecMax[1]) && 
             (vecMin[2] <= vecVector[2] <= vecMax[2])    ); 
}
public Message()
{
	PrintToChatAll("[BS Limiter] Due to the low number of CT's in this round. CT's must defend only bomsite %s.",BSAL);
	PrintHintTextToAll("Only Bombsite %s is enabled in this round!",BSAL);
}
public Action:RepeatMessage(Handle:timer)
{
	Message();
}
public Action:Event_RoundFreezeEnd (Handle:event,const String:name[],bool:dontBroadcast)
{
	if(IsValidEntity(EIBA)) 
	{
		EIBA = -1;
	}
	if(IsValidEntity(EIBB)) 
	{
		EIBB = -1;
	}
	if(Timer != INVALID_HANDLE)
	{
		CloseHandle(Timer);
		Timer = INVALID_HANDLE;
	}

	new Float:VBCPA[3]; 
	new Float:VBCPB[3]; 
	new EI = -1;
	
	EI = FindEntityByClassname(EI,"cs_player_manager");
	
	if(IsValidEntity(EI)) 
	{ 
		GetEntPropVector(EI,Prop_Send,"m_bombsiteCenterA",VBCPA); 
		GetEntPropVector(EI,Prop_Send,"m_bombsiteCenterB",VBCPB); 
	} 
	
	EI = -1; 
	EI = FindEntityByClassname(EI,"func_bomb_target");
	
	while(IsValidEntity(EI)) 
	{ 
		new Float:VBMin[3]; 
		new Float:VBMax[3]; 
		 
		GetEntPropVector(EI,Prop_Send,"m_vecMins",VBMin); 
		GetEntPropVector(EI,Prop_Send,"m_vecMaxs",VBMax); 
		 
		if (IsVecBetween(VBCPA,VBMin,VBMax)) 
		{ 
			EIBA = EI; 
		} 
		else if (IsVecBetween(VBCPB,VBMin,VBMax)) 
		{ 
			EIBB = EI; 
		} 
		EI = FindEntityByClassname(EI,"func_bomb_target");
	}
    
	if(IsValidEntity(EIBA) && IsValidEntity(EIBB))
    {
		new CTPlayers = GetTeamClientCount(CS_TEAM_CT);
		new TTPlayers = GetTeamClientCount(CS_TEAM_T);

		if(((CTPlayers > TTPlayers) && (TTPlayers == 1 || CTPlayers > 3)) || CTPlayers > 4)
		{
			AcceptEntityInput(EIBB,"Enable");
			AcceptEntityInput(EIBA,"Enable");
			BSAL = "";
			PrintHintTextToAll("All Bombsites are enabled in this round!");
			PrintCenterTextAll("All Bombsites are enabled in this round!");
		}
		else
		{
			if(GetRandomInt(1,2) == 1)
			{
				AcceptEntityInput(EIBA,"Disable");
				AcceptEntityInput(EIBB,"Enable");
				BSAL = "B";
			}
			else
			{
				AcceptEntityInput(EIBB,"Disable");
				AcceptEntityInput(EIBA,"Enable");
				BSAL = "A";
			}
			decl String:CurrentMap[256];
			GetCurrentMap(CurrentMap,sizeof(CurrentMap));
			for(new i=0; i<STANDARDMAPSMAX; i++)
			{
				if(StrEqual(CurrentMap,StandardMaps[i][0],false)) 
				{
					if(StrEqual(StandardMaps[i][1],"B",false))
					{
						AcceptEntityInput(EIBA,"Disable");
						AcceptEntityInput(EIBB,"Enable");
						BSAL = "B";
					}
					else
					{
						AcceptEntityInput(EIBB,"Disable");
						AcceptEntityInput(EIBA,"Enable");
						BSAL = "A";
					}
				}
			}
			if(GetClientCount(true) > 1)
			{
				Message();
				Timer = CreateTimer(15.0,RepeatMessage, _,TIMER_REPEAT); 
			}
		}
	}
}
public Action:Event_RoundEnd (Handle:event,const String:name[],bool:dontBroadcast)
{
	if(Timer != INVALID_HANDLE)
	{
		CloseHandle(Timer);
		Timer = INVALID_HANDLE;
	}
	if(IsValidEntity(EIBA)) 
	{
		AcceptEntityInput(EIBA,"Enable");
		EIBA = -1;
	}
	if(IsValidEntity(EIBB)) 
	{
		AcceptEntityInput(EIBB,"Enable");
		EIBB = -1;
	}
}

