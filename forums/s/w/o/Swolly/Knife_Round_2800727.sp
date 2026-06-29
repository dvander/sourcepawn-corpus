#include <sourcemod>
#include <sdktools>

#pragma tabsize 0
///////////////////////////////////////////////////////////////////////////////////////
int Kazanan_Takim;
bool Knife_Round = true;
//////////////////////////////////////////////////////////////////////////////////////
public Plugin myinfo = {
	name = "Knife Round",
	author = "Swolly",
	description = "Knife Round",
	url = "www.plugincim.com"
};
///////////////////////////////////////////////////////////////////////////////////////
public OnMapStart()
{
	//*************************************//					
	char Harita_Ismi[32], Eklenti_Ismi[32];
	GetCurrentMap(Harita_Ismi, 32);
	GetPluginFilename(INVALID_HANDLE, Eklenti_Ismi, 32);
	//*************************************//					
	if((StrContains(Harita_Ismi, "de_", false) == 0) || (StrContains(Harita_Ismi, "cs_", false) == 0))
	{
		SetCvar("mp_give_player_c4", 0);					
		SetCvar("mp_roundtime", 1);		
	
		Knife_Round = true;	
	}			
	else
		SetFailState("This plugin for only pro map.");
	//*************************************//		

}
///////////////////////////////////////////////////////////////////////////////////////	
public OnPluginStart()
{
	//*******************************************//
    HookEvent("round_start", El_Basi, EventHookMode_PostNoCopy); 
    HookEvent("round_end", El_Sonu, EventHookMode_PostNoCopy);     
    HookEvent("player_spawn", Oyuncu_Dogdugunda, EventHookMode_PostNoCopy);         
	//*******************************************//    
}
//////////////////////////////////////////////////////////////////////////////////////
public El_Basi(Handle event, const char[] name, bool dontBroadcast)
{
	//*******************************************//	
	if(Knife_Round && GameRules_GetProp("m_bWarmupPeriod") == 0)
	{
		//*******************************************//	
		PrintHintTextToAll("The Knife Round has begun. The winners determine your team!");
		PrintToChatAll("The Knife Round has begun. The winners determine your team!");		
		//*******************************************//	
	    for (new i = 1; i <= MaxClients; i++) 
			if(i && IsClientInGame(i) && !IsFakeClient(i))
				Ayarla(i);
		//*******************************************//				
	}
	//*******************************************//	
}
//////////////////////////////////////////////////////////////////////////////////////
public Oyuncu_Dogdugunda(Handle event, const char[] name, bool dontBroadcast)
{
	//*******************************************//	
	if(Knife_Round && GameRules_GetProp("m_bWarmupPeriod") == 0)
	{
		//*******************************************//	
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		//*******************************************//	
		if(IsValidClient(client))		
			Ayarla(client);
		//*******************************************//				
	}
	//*******************************************//	
}
//////////////////////////////////////////////////////////////////////////////////////
public El_Sonu(Handle event, const char[] name, bool dontBroadcast)
{
	//*******************************************//	
	if(Knife_Round && GameRules_GetProp("m_bWarmupPeriod") == 0)
	{
		//*******************************************//
		Kazanan_Takim = GetEventInt(event, "winner");
		//*******************************************//		
		
		
		
		
		//*******************************************//		
		if(Kazanan_Takim > 1)
		{
			//*******************************************//		
			PrintHintTextToAll("The winners choose the team!");
			PrintToChatAll("The winners choose the team!");		
			//*******************************************//				
			Menu menu = CreateMenu(Oylama);
			SetMenuTitle(menu, "! CHOOSE THE TEAM YOU WANT TO START !\n---------------------------------------------------------------\n ");	
			//*******************************************//		
			AddMenuItem(menu, "3", "CT");		
			AddMenuItem(menu, "2", "T\n \n---------------------------------------------------------------");	
			SetMenuExitButton(menu, false);
			//*******************************************//	
			int Oyuncular[MAXPLAYERS+1], Sira;
			
		    for (new i = 1; i <= MaxClients; i++) 
				if(IsValidClient(i)&& GetClientTeam(i) == Kazanan_Takim)
				{
					Oyuncular[Sira] = i;
					Sira++;
				}
			//*******************************************//				
			VoteMenu(menu, Oyuncular, MAXPLAYERS+1, 5, 0);
			//*******************************************//		
		}
		//*******************************************//		
		
		
		
		
		//*******************************************//				
		SetCvar("mp_give_player_c4", 1);							
		SetCvar("mp_roundtime", 2);					
		//*******************************************//		
		Knife_Round = false;
		//*******************************************//		
	}
	//*******************************************//	
}
//////////////////////////////////////////////////////////////////////////////////////
public Oylama(Menu:menu, MenuAction:action, param1, param2)
{
	//*********************************//					
	if (action == MenuAction_VoteEnd)
	{
		//*********************************//
		SetCvar("mp_restartgame", 3);					
		//*********************************//
		int votes, totalVotes;
		char result[32];
        GetMenuItem(menu, param1, result, sizeof(result));     
		GetMenuVoteInfo(param2, votes, totalVotes);
		//*********************************//				
		int Takim = StringToInt(result, 10);
		
		if(Takim == 2)
			PrintToChatAll("The winning team chose to play on the T team.");
		else
			PrintToChatAll("The winning team chose to play on the CT team.");
		//*********************************//							
		if(Takim != Kazanan_Takim)
		{
			//*********************************//					
		    for (new i = 1; i <= MaxClients; i++) 
				if(IsValidClient(i)&& GetClientTeam(i) != 1)		
					if(GetClientTeam(i) == Takim)
					{
						if(Takim == 2)
							ChangeClientTeam(i, 3);
						else
							ChangeClientTeam(i, 2);
					}
					else
						ChangeClientTeam(i, Takim);
			//*********************************//
		}
		//*********************************//		
	}
	//*********************************//						
}
////////////////////////////////////////////////////////////////////////////////
Ayarla(client)
{
	//*******************************************//		
	if(IsValidClient(client))
	{
		//*******************************************//				
		for(int j = 0; j < 5; j++)
		{
			int weapon = GetPlayerWeaponSlot(client, j);
			if(weapon != -1)
			{
				RemovePlayerItem(client, weapon);
				RemoveEdict(weapon);						
			}
		}
		//*******************************************//		
	    SetEntProp(client, Prop_Send, "m_iAccount", 0);	
		GivePlayerItem(client, "weapon_knife");
		//*******************************************//		
	}
	//*******************************************//		
}
//////////////////////////////////////////////////////////////////////////////////////
SetCvar(char cvarName[64], int value)
{
	Handle IntCvar = FindConVar(cvarName);
	if (IntCvar == null) return;

	int flags = GetConVarFlags(IntCvar);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(IntCvar, flags);

	SetConVarInt(IntCvar, value);

	flags |= FCVAR_NOTIFY;
	SetConVarFlags(IntCvar, flags);
}
//////////////////////////////////////////////////////////////////////////////////////
bool IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
} 
//////////////////////////////////////////////////////////////////////////////////////