#include <sourcemod>

#pragma tabsize 0
//////////////////////////////////////////////////////////////////////////////////////
bool Kapatti[MAXPLAYERS + 1];
//////////////////////////////////////////////////////////////////////////////////////
ConVar Mesaj_Turu;
ConVar Eklenti_Tagi;
//////////////////////////////////////////////////////////////////////////////////////
public Plugin:myinfo = {
	name = "Buy Item Notification",
	author = "Swolly",
	description = "When the player buyed item, they show the other team friends what they have received as a message.",
	url = "www.plugincim.com"
};
///////////////////////////////////////////////////////////////////////////////////////
public OnPluginStart() 
{ 
	//******************************************//	
	RegConsoleCmd("sm_bin", Kapat_Ac);
	//******************************************//		
	HookEvent("item_purchase", Esya_Alindiginda);
	//******************************************//  
	Mesaj_Turu = CreateConVar("bin_type", "3", "0 = disable || 1 = only console || 2 = only chat || 3 = chat + console");
	Eklenti_Tagi = CreateConVar("bin_prefix", "SM", "Plugin chat message prefix.");	
	AutoExecConfig(true, "Buy_Item_Notification", "sourcemod");
	//******************************************//  
}
//////////////////////////////////////////////////////////////////////////////////////
public Action:Kapat_Ac(client, args)
{
	//******************************************//    	
	char EklentiTagi[32];
	GetConVarString(Eklenti_Tagi, EklentiTagi, 32);				
	//******************************************//    		
	if(Kapatti[client])
	{
		//******************************************//    			
		PrintToChat(client, " \x02[%s] \x0bBin \x04enabled!", EklentiTagi);				
		Kapatti[client] = false;
		//******************************************//    			
	}	
	else
	{
		//******************************************//    					
		PrintToChat(client, " \x02[%s] \x0bBin \x01disabled!", EklentiTagi);		
		Kapatti[client] = true;
		//******************************************//    				
	}		
	//******************************************//    	
	return Plugin_Handled;
	//******************************************//    		
}
//////////////////////////////////////////////////////////////////////////////////////
public Esya_Alindiginda(Handle:event, const String:name[], bool:dontBroadcast)
{
	//******************************************//    	
	if(GetConVarInt(Mesaj_Turu) != 0)
	{
		//******************************************//    			
		new client = GetClientOfUserId(GetEventInt(event, "userid"));		
		//******************************************//    					
		char Silah_Ismi[32], EklentiTagi[32];
		GetConVarString(Eklenti_Tagi, EklentiTagi, 32);				
		//******************************************//    							
		GetEventString(event, "weapon", Silah_Ismi, 32);		
		ReplaceString(Silah_Ismi, 32, "weapon_", "");
		//******************************************//    	
		if(GetConVarInt(Mesaj_Turu) == 1)
		{
			//******************************************//    				
			for (new i = 1; i <= MaxClients; i++) 
				if(IsValidClient(i) && GetClientTeam(i) == GetClientTeam(client) && !Kapatti[i])
					PrintToConsole(i, "%N player has bought %s (!bin)", client, Silah_Ismi);
			//******************************************//    									
		}
		else
		if(GetConVarInt(Mesaj_Turu) == 2)
		{
			//******************************************//    							
			for (new i = 1; i <= MaxClients; i++) 
				if(IsValidClient(i) && GetClientTeam(i) == GetClientTeam(client) && !Kapatti[i])
					PrintToChat(i, " \x02[%s] \x0b%N \x01player has bought \x04%s (!bin)", EklentiTagi, client, Silah_Ismi);
			//******************************************//    									
		}
		else
		if(GetConVarInt(Mesaj_Turu) == 3)
		{
			//******************************************//    							
			for (new i = 1; i <= MaxClients; i++) 
				if(IsValidClient(i) && GetClientTeam(i) == GetClientTeam(client) && !Kapatti[i])
				{
					PrintToConsole(i, "%N player has bought %s (!bin)", client, Silah_Ismi);
					PrintToChat(i, " \x02[%s] \x0b%N \x01player has bought \x04%s (!bin)", EklentiTagi, client, Silah_Ismi);
				}
			//******************************************//    								
		}
		//******************************************//    
	}
	//******************************************//    		    	
}
//////////////////////////////////////////////////////////////////////////////////////
bool:IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}  
//////////////////////////////////////////////////////////////////////////////////////
public OnClientPostAdminCheck(client)
	Kapatti[client] = false;
//////////////////////////////////////////////////////////////////////////////////////