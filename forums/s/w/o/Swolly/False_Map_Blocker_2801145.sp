#include <sourcemod>
#include <sdktools>

#pragma tabsize 0
//////////////////////////////////////////////////////////////////////////////////////
char Acilacak_Harita[32];
//////////////////////////////////////////////////////////////////////////////////////
public Plugin myinfo = {
	name = "False Map Blocker",
	author = "Swolly",
	description = "False Map Blocker",
	url = "www.plugincim.com"
};
///////////////////////////////////////////////////////////////////////////////////////	
public OnPluginStart()
{
	//*************************************//			
	AddCommandListener(Komut_Kontrol, "sm_map");		
	//*************************************//			
}
//////////////////////////////////////////////////////////////////////////////////////
public Action Komut_Kontrol(int client, const char[] command, int args)
{
 	//***********************************//  
 	if(IsValidClient(client))
    	if (CheckCommandAccess(client, "sm_map", ADMFLAG_CHANGEMAP, false))
			if(args) 	
		 	{
		 	 	//***********************************//		
		 	 	char Harita_Ismi[32], Haritalar[32];
			 	GetCmdArg(1, Harita_Ismi, 32);
			 	//***********************************//
			 	
			 	
			  	//***********************************//	
				int Harita_Sayisi;
				FileType Dosya_Tipi;
			 	//***********************************//
				Handle Konum = OpenDirectory("maps");
				//*********************************************//	
				while (ReadDirEntry(Konum, Haritalar, 256, Dosya_Tipi) && Harita_Sayisi != 2) 
					if (Dosya_Tipi == FileType_File)
						if(ReplaceString(Haritalar, 32, Harita_Ismi, Harita_Ismi))
							if(ReplaceString(Haritalar, 32, ".bsp", ""))											
								Harita_Sayisi++;
			 	//***********************************//						
				CloseHandle(Konum);									
			 	//***********************************//
			 	
			 	
			 	
			 	//***********************************//		 	
			 	if(Harita_Sayisi > 1)
			 	{
			 		//***********************************// 		
			 		PrintToChat(client, "[SM] \x01Select the map you want to open from the menu.");
			 		//***********************************// 
					Handle menuhandle = CreateMenu(Harita_Menu);
					SetMenuTitle(menuhandle, "           ! HARİTALAR !\n----------------------------------\n ");
			  		//***********************************//					
					Konum = OpenDirectory("maps");
				
					while (ReadDirEntry(Konum, Haritalar, 256, Dosya_Tipi)) 
						if (Dosya_Tipi == FileType_File)
							if(ReplaceString(Haritalar, 32, Harita_Ismi, Harita_Ismi))
								if(ReplaceString(Haritalar, 32, ".bsp", ""))						
									AddMenuItem(menuhandle, Haritalar, Haritalar);
			  		//***********************************//								
					SetMenuPagination(menuhandle, 7);
					SetMenuExitButton(menuhandle, true);
					DisplayMenu(menuhandle, client, 250);						
			  		//***********************************//		
			 		return Plugin_Stop;
			 		//***********************************//		
				}
			 	//***********************************//			
			}
	//***********************************//
	return Plugin_Continue;
	//***********************************//	
}
//////////////////////////////////////////////////////////////////////////////////////
public Harita_Menu(Handle menuhandle, MenuAction:action, client, Position)
{	
	//*****************************************//				
	if(action == MenuAction_Select)
	{
		//*****************************************//					
		GetMenuItem(menuhandle, Position, Acilacak_Harita, 32);
		//*****************************************//	
 		PrintToChatAll("[SM] \x01The %s map is opened by \x0b%N.", Acilacak_Harita, client);		
 		CreateTimer(15.0, Haritayi_Ac, _, TIMER_FLAG_NO_MAPCHANGE);
		//*****************************************//	 	
		SetCvar("mp_respawn_on_death_ct", 0);
		SetCvar("mp_respawn_on_death_t", 0);
		SetCvar("mp_timelimit", 0);
		SetCvar("mp_maxrounds", 0);		
		//*****************************************//	 			
	    for (new i = 1; i <= MaxClients; i++) 
			if(IsValidClient(i) && IsPlayerAlive(i))	
				ForcePlayerSuicide(i);
		//*****************************************//			
	} 
	else 
	if(action == MenuAction_End)
		CloseHandle(menuhandle);
	//*****************************************//				
}
//////////////////////////////////////////////////////////////////////////////////////
public Action Haritayi_Ac(Handle Timer)
{
	ServerCommand("sm_map %s", Acilacak_Harita);
}
//////////////////////////////////////////////////////////////////////////////////////
stock SetCvar(char cvarName[64], int value)
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
stock bool IsValidClient(client, bool nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
        return false; 

    return IsClientInGame(client); 
} 
//////////////////////////////////////////////////////////////////////////////////////