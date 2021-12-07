#include <sourcemod>    
#include <sdktools>
#include <cstrike>

public Plugin:myinfo =
{
    name = "TeamPlay Bombsite Limiter",
    author = "Tomasz 'anacron' Motylinski",
    description = "?",
    version = "1.1.2",
    url = "http://anacron.pl/"
}
public OnPluginStart()
{
    HookEvent("round_freeze_end",Event_FreezeEnd,EventHookMode_Post);
}
public Action:Event_FreezeEnd (Handle:event,const String:name[],bool:dontBroadcast)
{
	new EIBA = -1;
	new EIBB = -1;
	new EIBC = -1;
	new Float:VBCPA[3]; 
	new Float:VBCPB[3]; 
	new Float:VBCPC[3]; 
	new EI = -1;  
	EI = FindEntityByClassname(EI,"cs_player_manager");
	if(IsValidEntity(EI)) 
	{ 
		GetEntPropVector(EI,Prop_Send,"m_bombsiteCenterA",VBCPA); 
		GetEntPropVector(EI,Prop_Send,"m_bombsiteCenterB",VBCPB);
		GetEntPropVector(EI,Prop_Send,"m_bombsiteCenterB",VBCPC); 
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
		else if (IsVecBetween(VBCPC,VBMin,VBMax)) 
		{ 
			EIBC = EI; 
		} 
		EI = FindEntityByClassname(EI,"func_bomb_target");
	}
    if(IsValidEntity(EIBA))
	{
		AcceptEntityInput(EIBA,"Enable");
	}
    if(IsValidEntity(EIBB))
	{
		AcceptEntityInput(EIBB,"Enable");
	}
    if(IsValidEntity(EIBC))
	{
		AcceptEntityInput(EIBC,"Enable");
	}
	if(IsValidEntity(EIBA) && IsValidEntity(EIBB) && IsValidEntity(EIBC))
	{
		new CTPlayers = GetTeamClientCount(CS_TEAM_CT);
		new TTPlayers = GetTeamClientCount(CS_TEAM_T);
		if((CTPlayers < 6 && CTPlayers + 3 < TTPlayers))
		{
			new BS = GetRandomInt(1,3)
			if(BS == 1)
			{
				AcceptEntityInput(EIBA,"Enable");
				AcceptEntityInput(EIBB,"Disable");
				AcceptEntityInput(EIBC,"Disable");
				PrintToChatAll ("[SM] Only Bombsite A is enabled.");
				PrintHintTextToAll("Only Bombsite A is enabled!");
			}
			else if(BS == 2)
			{
				AcceptEntityInput(EIBA,"Disable");
				AcceptEntityInput(EIBB,"Enable");
				AcceptEntityInput(EIBC,"Disable");
				PrintToChatAll ("[SM] Only Bombsite B is enabled.");
				PrintHintTextToAll("Only Bombsite B is enabled!");
			}
			else if(BS == 3)
			{
				AcceptEntityInput(EIBA,"Disable");
				AcceptEntityInput(EIBB,"Disable");
				AcceptEntityInput(EIBC,"Enable");
				PrintToChatAll ("[SM] Only Bombsite C is enabled.");
				PrintHintTextToAll("Only Bombsite C is enabled!");
			}
		}
	}
	else if(IsValidEntity(EIBA) && IsValidEntity(EIBB))
    {
		new CTPlayers = GetTeamClientCount(CS_TEAM_CT);
		new TTPlayers = GetTeamClientCount(CS_TEAM_T);
		if((CTPlayers < 4 && CTPlayers + 2 < TTPlayers))
		{
			if(GetRandomInt(1,2) == 1)
			{
				AcceptEntityInput(EIBA,"Disable");
				AcceptEntityInput(EIBB,"Enable");
				PrintToChatAll ("[SM] Only Bombsite B is enabled.");
				PrintHintTextToAll("Only Bombsite B is enabled!");
			}
			else
			{
				AcceptEntityInput(EIBB,"Disable");
				AcceptEntityInput(EIBA,"Enable");
				PrintToChatAll ("[SM] Only Bombsite A is enabled.");
				PrintHintTextToAll("Only Bombsite A is enabled!");
			}
		}
	}
}
stock bool:IsVecBetween(const Float:vecVector[3],const Float:vecMin[3],const Float:vecMax[3]) 
{ 
    return ( (vecMin[0] <= vecVector[0] <= vecMax[0]) && 
             (vecMin[1] <= vecVector[1] <= vecMax[1]) && 
             (vecMin[2] <= vecVector[2] <= vecMax[2])    ); 
}
