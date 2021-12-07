#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma tabsize 0
/////////////////////////////////////////////////////////////////////
bool Bekleme[MAXPLAYERS + 1];
/////////////////////////////////////////////////////////////////////
int Etiket_Kapali[MAXPLAYERS + 1];
Handle h_Etiket_Kapali;
/////////////////////////////////////////////////////////////////////
ConVar Yetkili_Herkes, Bekleme_Suresi, Etiket_Kapali_Olan, Etiket_Ses;
/////////////////////////////////////////////////////////////////////
public OnMapStart()
{
	//****************************************//	
	PrecacheSound("ui/beepclear.wav");
	//****************************************//	
}
/////////////////////////////////////////////////////////////////////
public OnPluginStart()
{
	//****************************************//
	RegConsoleCmd("sm_tagging", Oyuncu_Etiketleme);
	RegConsoleCmd("sm_tagg", Etiket_Kapat_Ac);	
	//****************************************//
	Yetkili_Herkes = CreateConVar("etiket_yetkili", "1", "Can the admins also tag the players who have closed the tagging? 1 = Yes || 0 = No");
	Bekleme_Suresi = CreateConVar("etiket_suresi", "10", "How many seconds can a tag be used again after a player has been tagged?");
	Etiket_Kapali_Olan = CreateConVar("etiket_kapali", "0", "Can the players who have turned off tagging use tagging? 1 = Yes || 0 = No");	
	Etiket_Ses = CreateConVar("etiket_ses", "1", "Play a sound when a player is tagged? 1 = Evet || 0 = Hayır");	
	
	AutoExecConfig(true, "Etiket", "Plugincim_com");
	//****************************************//	
	h_Etiket_Kapali = RegClientCookie("Etiket", "Etiket", CookieAccess_Protected);

	for (new i = 1; i <= MaxClients; i++) 
		if(i && IsClientInGame(i) && !IsFakeClient(i))
			if (AreClientCookiesCached(i))
				OnClientCookiesCached(i);
	//****************************************//			
}
/////////////////////////////////////////////////////////////////////
public OnPluginEnd()
{
	//****************************************//			
	for (new i = 1; i <= MaxClients; i++) 
		if(i && IsClientInGame(i) && !IsFakeClient(i))
			if (IsClientInGame(i))
				OnClientDisconnect(i);
	//****************************************//					
}
/////////////////////////////////////////////////////////////////////
public OnClientCookiesCached(client)
{
	//****************************************//					
	char s_Etiket_Kapali[12];
	GetClientCookie(client, h_Etiket_Kapali, s_Etiket_Kapali, 12);
	//****************************************//						
	Etiket_Kapali[client] = StringToInt(s_Etiket_Kapali);
	//****************************************//						
}
/////////////////////////////////////////////////////////////////////
public OnClientDisconnect(client)
{
	//****************************************//		
	if(AreClientCookiesCached(client))
	{
		//****************************************//				
		char s_Etiket_Kapali[12];
		Format(s_Etiket_Kapali, 12, "%d", Etiket_Kapali[client]);
		//****************************************//				
		SetClientCookie(client, h_Etiket_Kapali, s_Etiket_Kapali);
		//****************************************//				
	}
	//****************************************//		
}
/////////////////////////////////////////////////////////////////////
public Action Oyuncu_Etiketleme(client, args)
{
	//****************************************//	
	if(Bekleme[client])
		PrintToChat(client, " \x0bYou must wait \x01to use tagging \x0fagain.");
	else
	{
		//****************************************//		
		if(Etiket_Kapali[client] && !GetConVarInt(Etiket_Kapali_Olan))
			PrintToChat(client, " \x0bYou can't use \x10this command because have \x0fdisabled tagging.");
		else
		{
			//****************************************//			
			new Handle:menu = CreateMenu(Oyuncu_Etiketleme_, MENU_ACTIONS_DEFAULT), String:info[10], String:display[MAX_NAME_LENGTH], userid;
		    SetMenuTitle(menu,"! Select the Player You Want To Tag !\n "); 
			AddMenuItem(menu, "Yenile", "! CLICK TO RENEW THE MENU !\n ");
			//****************************************//	
			for (new i = 0; i <= MaxClients; i++)
				if(i && IsClientInGame(i) && !IsFakeClient(i) && i != client)
				{
					//****************************************//
					if(!Etiket_Kapali[i] || (GetConVarInt(Yetkili_Herkes) && (GetUserFlagBits(client) & ADMFLAG_ROOT || GetUserFlagBits(client) & ADMFLAG_GENERIC)))
					{
						//****************************************//		
						userid = GetClientUserId(i);
						Format(info, sizeof(info), "%i", userid);
						Format(display, sizeof(display), "%N", i);
						Format(display, sizeof(display), "%s", display);
						AddMenuItem(menu, info, display);				
						//****************************************//				
					}
					//****************************************//	
				}
			//****************************************//		
			DisplayMenu(menu, client, 30);			
			//****************************************//	
		}
		//****************************************//	
	}
	//****************************************//
	return Plugin_Handled;
	//****************************************//
}
/////////////////////////////////////////////////////////////////////
public Action Etiket_Kapat_Ac(client, args)
{
	//****************************************//	
	if(Etiket_Kapali[client])
	{
		PrintToChat(client, " \x0bTagging is, \x04enabled.");		
		Etiket_Kapali[client] = 0;
	}
	else
	{
		PrintToChat(client, " \x0bTagging is, \x0fdisabled.");		
		Etiket_Kapali[client] = 1;
	}	
	//****************************************//
}
///////////////////////////////////////////////////////////////////////////////////////
public Oyuncu_Etiketleme_(Handle:menu, MenuAction:action, client, itemNum)
{
	//****************************************//	
	if ( action == MenuAction_Select )  
    {
 		//****************************************//	
		if(Etiket_Kapali[client] && !GetConVarInt(Etiket_Kapali_Olan))
			PrintToChat(client, " \x0bYou can't use \x10this command because have \x0fdisabled tagging.");
		else
		{
			//****************************************//						
      		char info[32];  
	        GetMenuItem(menu, itemNum, info, sizeof(info));     
			//****************************************//	        
	        if (StrEqual(info, "Yenile", true))
				FakeClientCommand(client, "sm_etiketle");
			else
			{
				//****************************************//
			    int Hedef = GetClientOfUserId(StringToInt(info));
				
				if(Hedef)
				{
					//****************************************//
					if(!Etiket_Kapali[Hedef] || (GetConVarInt(Yetkili_Herkes) && (GetUserFlagBits(client) & ADMFLAG_ROOT || GetUserFlagBits(client) & ADMFLAG_GENERIC)))
					{
						//****************************************//
						for (new i = 0; i <= MaxClients; i++)
							if(i && IsClientInGame(i) && !IsFakeClient(i))
							{	
								//****************************************//							
								if(Hedef == i)
									PrintToChat(i, " \x02%N \x0bhas tagged you.", client);
								else
									PrintToChat(i, " \x02%N \x01has tagged \x0e%N", client, Hedef);
								//****************************************//															
							}								
						//****************************************//
						if(GetConVarInt(Etiket_Ses))
						{
							EmitSoundToClient(Hedef, "ui/beepclear.wav");
							EmitSoundToClient(client, "ui/beepclear.wav");						
						}
						//****************************************//					
						CreateTimer(GetConVarFloat(Bekleme_Suresi), Bekleme_Kapat, client, TIMER_FLAG_NO_MAPCHANGE);			
						Bekleme[client] = true;					
						//****************************************//
					}
					else
						PrintToChat(client, " \x0bTarget \x01person \x0has \x0fturned off tagging.");
					//****************************************//
				}			
				//****************************************//			
			}	
			//****************************************//						
		}
		//****************************************//					
	}
	//****************************************//	
}
///////////////////////////////////////////////////////////////////////////////////////
public Action Bekleme_Kapat(Handle timer, any:client)
{
	//****************************************//	
	Bekleme[client] = false;
	//****************************************//		
}
///////////////////////////////////////////////////////////////////////////////////////
public OnClientPostAdminCheck(client)
{
	//****************************************//	
	if(client && IsClientInGame(client) && !IsFakeClient(client))	
	{
		//****************************************//	
		Bekleme[client] = false;
		Etiket_Kapali[client] = 0;
		//****************************************//			
		if (AreClientCookiesCached(client))
		{
			//****************************************//					
			char s_Etiket_Kapali[12];
			GetClientCookie(client, h_Etiket_Kapali, s_Etiket_Kapali, 12);
			//****************************************//						
			Etiket_Kapali[client] = StringToInt(s_Etiket_Kapali);
			//****************************************//		
		}		
		//****************************************//						
	}
	//****************************************//		
}
///////////////////////////////////////////////////////////////////////////////////////