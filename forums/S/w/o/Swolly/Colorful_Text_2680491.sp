#include <sourcemod>
#include <sdktools>
#include <store>

#pragma tabsize 0
//////////////////////////////////////////////////////////////////////////////////////
ConVar Kredi_Miktari;
ConVar Isim_Rengi;
ConVar Yazi_Rengi;
ConVar Ses;
///////////////////////////////////////////////////////////////////////////////////////	
public OnMapStart()
{
	//***********************************************//	
	PrecacheSound("ui/beepclear.wav");
	//***********************************************//	
}
///////////////////////////////////////////////////////////////////////////////////////	
public OnPluginStart()
{
	//***********************************************//
	RegConsoleCmd("sm_colorfultext", Colorful_Text, "Colorful writing using market credits");
	//***********************************************//  
	Kredi_Miktari = CreateConVar("colored_text_price", "100", "How much credits can using for colorful text set the value to 0 to disable the command");
	Isim_Rengi = CreateConVar("colorful_text_name_color", "blue", "Name color? ( red - blue - green - white - pink )");
	Yazi_Rengi = CreateConVar("colorful_text_write_color", "red", "Write color? ( red - blue - green - white - pink )");
	Ses = CreateConVar("colorful_text_sound", "1", "Sound Enable or Disable? ( 1 - 0 )");
	
	AutoExecConfig(true, "Colorful_Text", "Plugincim_com");
	//***********************************************//  	
}
//////////////////////////////////////////////////////////////////////////////////////
public Action:Colorful_Text(client, args)
{
	//***********************************************//
	if(GetConVarInt(Kredi_Miktari) <= 0)
		PrintToChat(client, " \x10This command \x02disabled.");
	else
	{
		//***********************************************//		
		if(args >= 1)
		{
			//***********************************************//				
			if(Store_GetClientCredits(client) >= GetConVarInt(Kredi_Miktari))
			{
				//***********************************************//	
				Store_SetClientCredits(client, Store_GetClientCredits(client) - GetConVarInt(Kredi_Miktari));
				//***********************************************//	
				char Mesaj[256], s_Isim_Rengi[32], s_Yazi_Rengi[32];
				GetConVarString(Isim_Rengi, s_Isim_Rengi, 32);
				GetConVarString(Yazi_Rengi, s_Yazi_Rengi, 32);				
				//***********************************************//	
				if(StrEqual(s_Isim_Rengi, "red"))
					Format(s_Isim_Rengi, 32, "\x02");
				else
				if(StrEqual(s_Isim_Rengi, "blue"))
					Format(s_Isim_Rengi, 32, "\x0b");
				else
				if(StrEqual(s_Isim_Rengi, "green"))
					Format(s_Isim_Rengi, 32, "\x04");
				else
				if(StrEqual(s_Isim_Rengi, "white"))
					Format(s_Isim_Rengi, 32, "\x01");
				else
				if(StrEqual(s_Isim_Rengi, "pink"))
					Format(s_Isim_Rengi, 32, "\x0e");
				//***********************************************//	
				if(StrEqual(s_Yazi_Rengi, "red"))
					Format(s_Yazi_Rengi, 32, "\x02");
				else
				if(StrEqual(s_Yazi_Rengi, "blue"))
					Format(s_Yazi_Rengi, 32, "\x0b");
				else
				if(StrEqual(s_Yazi_Rengi, "green"))
					Format(s_Yazi_Rengi, 32, "\x04");
				else
				if(StrEqual(s_Yazi_Rengi, "white"))
					Format(s_Yazi_Rengi, 32, "\x01");
				else
				if(StrEqual(s_Yazi_Rengi, "pink"))
					Format(s_Yazi_Rengi, 32, "\x0e");
				//***********************************************//	
				GetCmdArgString(Mesaj, 256);
				PrintToChatAll(" %s%N : %s%s", s_Isim_Rengi, client, s_Yazi_Rengi, Mesaj);
				//***********************************************//				
				if(GetConVarInt(Ses) == 1)
					EmitSoundToAll("ui/beepclear.wav");
				//***********************************************//				
			}
			else
				PrintToChat(client, " \x10You must have \x0e%d \x0fcredits to write in color.", GetConVarInt(Kredi_Miktari));
			//***********************************************//	
		}
		else
			PrintToChat(client, " \x10Use: \x0e!colorful Message");
		//***********************************************//			
	}
	//***********************************************//	 
}
//////////////////////////////////////////////////////////////////////////////////////
public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
	//***********************************************//	 	
	if(StrContains(sArgs, "!colorfultext", false) == 0)
		return Plugin_Handled;
	//***********************************************//	 
	return Plugin_Continue;
	//***********************************************//	 
}
//////////////////////////////////////////////////////////////////////////////////////