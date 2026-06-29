#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#pragma tabsize 0
//////////////////////////////////////////////////////////////////////////////////////
bool Round_Basladi;
char sSilah[32];
//////////////////////////////////////////////////////////////////////////////////////
ConVar c_Sure;
//////////////////////////////////////////////////////////////////////////////////////
public Plugin myinfo = {
	name = "Aim HS Round",
	author = "Swolly",
	description = "Aim map for hs round.",
	url = "www.plugincim.com"
};
///////////////////////////////////////////////////////////////////////////////////////
public OnMapStart()
{
	//*************************************//					
	char Harita_Ismi[32];
	GetCurrentMap(Harita_Ismi, 32);
	//*************************************//					
	if((StrContains(Harita_Ismi, "aim_", false) == 0))
		CreateTimer(GetConVarFloat(c_Sure) * 60, Oylama, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	else
		SetFailState("[HS Round  ||  www.plugincim.com] This plugin only works on aim maps.");
	//*************************************//				
}
///////////////////////////////////////////////////////////////////////////////////////	
public OnPluginStart()
{
	//**************************************************//	
	RegAdminCmd("sm_hsround", Hs_Round, ADMFLAG_GENERIC);
	
    HookEvent("round_start", El_Basi);  
    HookEvent("round_end", El_Sonu);      
	//**************************************************//	
	c_Sure = CreateConVar("hs_round_time", "10", "How many minutes apart should voting take place?");
	
	AutoExecConfig(true, "Aim_HS_Round", "Plugincim_com");
	//**************************************************//	
}
//////////////////////////////////////////////////////////////////////////////////////
public Action Hs_Round(int client, int args)
{
	//*************************************// 
	PrintToChatAll("[SM] \x0b%N \x01started the HS Round voting.", client);
	CreateTimer(0.1, Oylama, _, TIMER_FLAG_NO_MAPCHANGE);	
	//*************************************// 
}
//////////////////////////////////////////////////////////////////////////////////////
public El_Basi(Handle event, const char[] name, bool dontBroadcast)
{
	//*************************************// 
	if(!StrEqual(sSilah, ""))	
	{
		//*************************************//    	
		PrintToChatAll("[SM] \x0bHS Round \x0fbegun!");
		Silahlari_Sil();
		//*************************************//    										
	    for (new i = 1; i <= MaxClients; i++) 
			if(IsValidClient(i))
				GivePlayerItem(i, sSilah);
		//*************************************// 
		Round_Basladi = true;
		//*************************************//    		
	}
	//*************************************//    				
}
//////////////////////////////////////////////////////////////////////////////////////
public El_Sonu(Handle event, const char[] name, bool dontBroadcast)
{
	//*************************************// 
	if(Round_Basladi)
	{
		//*************************************// 
		Round_Basladi = false;
		sSilah = "";
		//*************************************//    			
	}
	//*************************************//    				
}
//////////////////////////////////////////////////////////////////////////////////////
public Action Oylama(Handle Timer)
{
	//**************************************************//				
	Menu menu = new Menu(Oylama_);
	menu.SetTitle("HS Round Hangi sSilah İle Yapılsın?\n ");
	menu.AddItem("", "AK47");		
	menu.AddItem("", "M4A4");				
	menu.AddItem("", "USP-S");				
	menu.AddItem("", "GLOCK18");
	menu.AddItem("", "DEAGLE");		
	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
	//**************************************************//												
}
//////////////////////////////////////////////////////////////////////////////////////
public int Oylama_(Menu menu, MenuAction action, int param1,int param2)
{
	//*************************************//    			
	if (action == MenuAction_End)
		delete menu;
	//*************************************//    			
	if(action == MenuAction_Select)
	{
		int votes, totalVotes;
		char item[64], display[64];
		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
	}
	if (action == MenuAction_VoteEnd) 
	{
		//*************************************//    			
		if (param1 == 0)
		{
			//*************************************//    	
			PrintToChatAll("[SM] \x0bThe other round will be HeadShot AK47.");
			sSilah = "weapon_ak47";
			//*************************************//    			
		}	
		else
		if (param1 == 1)
		{
			//*************************************//    	
			PrintToChatAll("[SM] \x0bThe other round will be HeadShot M4A4.");
			sSilah = "weapon_m4a1";
			//*************************************//    			
		}	
		else
		if (param1 == 2)
		{
			//*************************************//    	
			PrintToChatAll("[SM] \x0bThe other round will be HeadShot USP-S.");
			sSilah = "weapon_usp_silencer";
			//*************************************//    			
		}	
		else
		if (param1 == 3)
		{
			//*************************************//    	
			PrintToChatAll("[SM] \x0bThe other round will be HeadShot GLOCK18.");
			sSilah = "weapon_glock";
			//*************************************//    			
		}	
		else
		if (param1 == 4)
		{
			//*************************************//    	
			PrintToChatAll("[SM] \x0bThe other round will be HeadShot DEAGLE.");
			sSilah = "weapon_deagle";
			//*************************************//    			
		}	
		//*************************************//    			
	}
	//*************************************//    			
}
/////////////////////////////////////////////////////////////////////////////
public Action Hasar_Aldiginda(victim, &attacker, &inflictor, &Float:damage, &damagetype) 
{ 
	//*************************************//    			
	if(Round_Basladi)
	{
		//*************************************//    				
		if(!(damagetype & CS_DMG_HEADSHOT))
		{
			damage = 0.0; 
			return Plugin_Changed; 	
		}
		//*************************************//    				
	}
	//*************************************//    		
	return Plugin_Continue;
	//*************************************//    			
}  
//////////////////////////////////////////////////////////////////////////////////////
Silahlari_Sil()
{
	//*************************************//    			
	int maxent = GetMaxEntities(); 
	char weapon[64];
	
	for (int i=MaxClients;i<maxent;i++)
	{
		if( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if(!(StrContains(weapon, "weapon_")) && (StrContains(weapon, "weapon_knife") != 0) &&  (StrContains(weapon, "weapon_bayonet") != 0))
				RemoveEdict(i);
		}
	}
	//*************************************//    			
}
//////////////////////////////////////////////////////////////////////////////////////
public OnClientPostAdminCheck(int client)
{
	//*************************************//    
	if(IsValidClient(client))
		SDKHook(client, SDKHook_OnTakeDamage, Hasar_Aldiginda);		
	//*************************************//    
}
//////////////////////////////////////////////////////////////////////////////////////
bool IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
} 
//////////////////////////////////////////////////////////////////////////////////////