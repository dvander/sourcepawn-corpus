#include <sourcemod>  
#include <multicolors>  
#include <basecomm>  

ConVar g_Enable, g_EnableMsg, g_Punishment, g_PunishmentEnable, g_PunishmentBanTime;
char lasttext[MAXPLAYERS + 1][MAX_MESSAGE_LENGTH]; 

public Plugin myinfo =  
{ 
    name = "Simple Anti Spam",  
    author = "Vortéx!",  
    version = "2.0",  
    url = "sourceturk.net" 
} 

public void OnPluginStart() 
{
	g_Enable = CreateConVar("sm_sas_enable", "1", "Simple Anti Spam Plugin Enable/Disable? 1 = Enable - 0 = Disable");	
	g_EnableMsg = CreateConVar("sm_sas_message_enable", "1", "Simple Anti Spam Plugin Chat Warning Messages Enable/Disable? 1 = Enable - 0 = Disable");	
	g_PunishmentEnable = CreateConVar("sm_sas_punishment_enable", "1", "If player write same thing, give punishment. Enable/Disable? 1 = Enable - 0 = Disable");	
	g_Punishment = CreateConVar("sm_sas_punishment_type", "1", "If punishment feature enable -> 1 = KICK - 2 = BAN - 3 = GAG");	
	g_PunishmentBanTime = CreateConVar("sm_sas_punishment_ban_time", "15", "If punishment feature enable and punishment type ban -> Ban time. Default = 15 minute.");	
	AddCommandListener(Command_Say, "say"); 
	AddCommandListener(Command_Say, "say_team"); 
	AddCommandListener(Command_Say, "say2"); 
} 

public void OnClientDisconnect(int client) 
{ 
    lasttext[client] = NULL_STRING; 
} 

public Action Command_Say(int client, const char[] command, int argc) 
{
	if(GetConVarBool(g_Enable))
	{	
	    if (client > 0 && IsClientInGame(client) && !BaseComm_IsClientGagged(client)) 
	    { 
	        char text[192]; 
	        GetCmdArgString(text, sizeof(text)); 
	         
	        if(StrEqual(text, lasttext[client], false)) 
	        {
				if(GetConVarBool(g_PunishmentEnable))
				{
					if(GetConVarInt(g_Punishment) == 1)
					{
						KickClient(client, "You have been kicked for spam.");
					}
					else if(GetConVarInt(g_Punishment) == 2)
					{
						BanClient(client, GetConVarInt(g_PunishmentBanTime), BANFLAG_AUTO, "Spamming", "You have been banned for spam.");
					}
					else if(GetConVarInt(g_Punishment) == 3)
					{
						BaseComm_SetClientGag(client, true);
					}
				}
					
				if(GetConVarBool(g_EnableMsg))
				{
			    	CPrintToChat(client, "{lime}* * * {blue}SPAM IS NOT ALLOWED! {lime}* * *"); 
				}
			}
			
		lasttext[client] = text;
		return Plugin_Handled;     
		}
	}	
	
	CreateTimer(5.0, EmptyLastText, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE); 
	return Plugin_Continue; 
}  

public Action EmptyLastText(Handle timer, any userid) 
{ 
    int client = GetClientOfUserId(userid); 
    if(client > 0 && IsClientInGame(client)) 
    { 
        lasttext[client] = NULL_STRING; 
    } 
}  