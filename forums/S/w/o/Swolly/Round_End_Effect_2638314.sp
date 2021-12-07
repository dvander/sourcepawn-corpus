#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma tabsize 0
//////////////////////////////////////////////////////////////////////////////////////
int Renk_Sirasi;
Handle h_timer = null;
//////////////////////////////////////////////////////////////////////////////////////
public Plugin:myinfo = {
	name = "El Sonu Efekti",
	author = "Swolly",
	description = "El Sonu Efekti",
	url = "www.plugincim.com"
};
///////////////////////////////////////////////////////////////////////////////////////
public OnPluginStart()
{
	//*********************************//	
    HookEvent("round_end", El_Sonu);     		
    HookEvent("round_start", El_Basi);   
	//*********************************//
}
//////////////////////////////////////////////////////////////////////////////////////
public El_Sonu(Handle:event, const String:name[], bool:dontBroadcast)
{
	//*********************************//
	Renk_Sirasi = 1;
	//*********************************//  
	h_timer = CreateTimer(0.3, Renk_Degistir, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	Ekrani_Salla();	
	//*********************************//  	
}
//////////////////////////////////////////////////////////////////////////////////////
public El_Basi(Handle:event, const String:name[], bool:dontBroadcast)
{
	//*********************************//
	if (h_timer != null) 
	{
		CloseHandle(h_timer);
	  	h_timer = null;
	}  
	//*********************************//  	
}
//////////////////////////////////////////////////////////////////////////////////////
public Action:Renk_Degistir(Handle:Timer)
{
	//*********************************//  			
	for (new i = 1; i <= MaxClients; i++) 
		if(!IsFakeClient(i) && IsValidClient(i))
		{
			if(Renk_Sirasi == 1)
			{
				Ekran_Renk_Olustur(i, 255, 0, 0, 160);				
			}
			else
			if(Renk_Sirasi == 2)
			{
				Ekran_Renk_Olustur(i, 0, 255, 0, 160);				
			}
			else
			if(Renk_Sirasi == 3)
			{
				Ekran_Renk_Olustur(i, 0, 0, 255, 160);				
			}
			else
			if(Renk_Sirasi == 4)
			{
				Ekran_Renk_Olustur(i, 102, 0, 255, 160);				
			}
			else
			if(Renk_Sirasi == 5)
			{
				Ekran_Renk_Olustur(i, 204, 204, 0, 160);				
			}
			else
			if(Renk_Sirasi == 6)
			{
				Ekran_Renk_Olustur(i, 255, 0, 102, 160);				
			}
			else
			if(Renk_Sirasi == 7)
			{
				Ekran_Renk_Olustur(i, 255, 102, 0, 160);				
			}
			else
			if(Renk_Sirasi == 8)
			{
				Renk_Sirasi = 1;
				Ekran_Renk_Olustur(i, 255, 0, 0, 160);				
			}
		}
	//*********************************//  		
	Renk_Sirasi++;
	//*********************************//  			
}
//////////////////////////////////////////////////////////////////////////////////////
Ekran_Renk_Olustur(client, Renk1, Renk2, Renk3, Renk4)
{
	//*********************************//  		
    int clients[2]; 
    clients[0] = client; 
 	//*********************************//  		   
    int Sure = 200,
    	holdtime = 40,
    	flags = (0x0001 | 0x0010);
	//*********************************//  	 
	int Renk[4];
	Renk[0] = Renk1;
	Renk[1] = Renk2;
	Renk[2] = Renk3;
	Renk[3] = Renk4;
	//*********************************//  	     
    Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1); 
 	//*********************************//  	   
    if (GetUserMessageType() == UM_Protobuf) 
    { 
        Protobuf pb = UserMessageToProtobuf(message); 
        pb.SetInt("duration", Sure); 
        pb.SetInt("hold_time", holdtime); 
        pb.SetInt("flags", flags); 
        pb.SetColor("clr", Renk); 
    } 
    else
    { 
        BfWriteShort(message, Sure); 
        BfWriteShort(message, holdtime); 
        BfWriteShort(message, flags); 
        BfWriteByte(message, Renk[0]); 
        BfWriteByte(message, Renk[1]); 
        BfWriteByte(message, Renk[2]); 
        BfWriteByte(message, Renk[3]); 
    } 
  	//*********************************//  	  
    EndMessage(); 
 	//*********************************//  	   
}
//////////////////////////////////////////////////////////////////////////////////////
Ekrani_Salla()
{
 	//*********************************//	
	Handle message = StartMessageAll("Shake");
 	//*********************************//		
	if (GetUserMessageType() == UM_Protobuf) 
	{
		PbSetInt(message, "command", 0);
		PbSetFloat(message, "local_amplitude", 30.0);
		PbSetFloat(message, "frequency", 15.0);
		PbSetFloat(message, "duration", GetConVarFloat(FindConVar("mp_round_restart_delay")));
	} 
	else 
	{
		BfWriteByte(message, 0);
		BfWriteFloat(message, 30.0);
		BfWriteFloat(message, 15.0);
		BfWriteFloat(message, GetConVarFloat(FindConVar("mp_round_restart_delay")));
	}
 	//*********************************//		
	EndMessage();	
 	//*********************************//  	   	
}
//////////////////////////////////////////////////////////////////////////////////////
bool:IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}  
//////////////////////////////////////////////////////////////////////////////////////