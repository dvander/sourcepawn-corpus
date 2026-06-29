#include <sourcemod>
#include <sdktools>

#pragma tabsize 0
//////////////////////////////////////////////////////////////////////////////////////
bool Oylama_Var;
//////////////////////////////////////////////////////////////////////////////////////
public Plugin myinfo = {
	name = "Vote Sound",
	author = "Swolly",
	description = "Vote Sound",
	url = "www.plugincim.com"
};
//////////////////////////////////////////////////////////////////////////////////////
public OnMapStart()
{
	//***********************************************************//					
	AddFileToDownloadsTable("sound/Plugincim_com/Oylama.wav");
	PrecacheSound("Plugincim_com/Oylama.wav");		
	
	PrecacheSound("ui/beep07.wav");				
	//***********************************************************//	
	CreateTimer(0.3, Oylama_Kontrol, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);		
	//***********************************************************//				
}
//////////////////////////////////////////////////////////////////////////////////////
public Action Oylama_Kontrol(Handle Timer)
{	
	//*************************//
	if (!Oylama_Var && IsVoteInProgress())
	{
		//*************************//    	   					
		EmitSoundToAll("Plugincim_com/Oylama.wav", _, _, 25, _, _, _, _, _, _, _, _);	
		Oylama_Var = true;	
		//*************************// 
		CreateTimer(0.1, Oylama_Kontrol2, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);		
		//*************************// 
	}
	//*************************//    
}
//////////////////////////////////////////////////////////////////////////////////////
public Action Oylama_Kontrol2(Handle Timer)
{	
	//*************************//
	if (Oylama_Var && !IsVoteInProgress())
	{
		//*************************//    	   	
		for (new i = 1; i <= MaxClients; i++) 
			if(IsValidClient(i))		
				StopSound(i, SNDCHAN_AUTO, "Plugincim_com/Oylama.wav");	
				
		Oylama_Var = false;	
		//*************************// 
		return Plugin_Stop;
		//*************************// 
	}
	//*************************//    
	return Plugin_Continue;	
	//*************************// 	
}
//////////////////////////////////////////////////////////////////////////////////////
bool IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
} 
//////////////////////////////////////////////////////////////////////////////////////