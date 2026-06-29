#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Colored AdminChat",
	author = "SAMURAI",
	description = "",
	version = "0.1",
	url = ""
}

new g_iMaxClients;

public OnPluginStart()
{
	RegConsoleCmd("say",fnHookSay);
	RegConsoleCmd("say_team",fnHookSayTeam);
	
}

public OnMapStart() { g_iMaxClients = GetMaxClients(); }


public Action:fnHookSay(id,args)
{
	decl String:SayText[192];
	GetCmdArgString(SayText,sizeof(SayText));
	
	StripQuotes(SayText);
	
	if(SayText[0] == '@' || SayText[0] == '/' || SayText[0] == '!' || !SayText[0])
		return Plugin_Continue;
	
	if(! (  1 <= id <= g_iMaxClients ) )
		return Plugin_Changed;
	
	if(!IsClientConnected(id) && !IsClientInGame(id))
		return Plugin_Continue;
	
	if(GetUserAdmin(id) == INVALID_ADMIN_ID || !(GetUserFlagBits(id) & ADMFLAG_GENERIC))
		return Plugin_Continue;
	
	new String:name[64];
	GetClientName(id,name,sizeof(name));
	
	new String:chatText[192];
	
	if(IsPlayerAlive(id))
		Format(chatText,sizeof(chatText),"\x01\x03(ADMIN) \x04%s : \x03%s",name,SayText);
	
	else
		Format(chatText,sizeof(chatText),"\x01\x03*DEAD* (ADMIN) \x04%s : \x03%s",name,SayText);
		
	PrintToChatAll(chatText);
	
	return Plugin_Handled;
}

public Action:fnHookSayTeam(id,args)
{
	decl String:SayText[192];
	GetCmdArgString(SayText,sizeof(SayText));
	
	StripQuotes(SayText);
	
	if(! (  1 <= id <= g_iMaxClients ) )
		return Plugin_Changed;
	
	if(!IsClientConnected(id) && !IsClientInGame(id))
		return Plugin_Continue;
	
	if(SayText[0] == '@' || SayText[0] == '/' || SayText[0] == '!' || !SayText[0])
		return Plugin_Continue;
	
	if(GetUserAdmin(id) == INVALID_ADMIN_ID || !(GetUserFlagBits(id) & ADMFLAG_GENERIC))
		return Plugin_Continue;
	
	new String:name[64];
	GetClientName(id,name,sizeof(name));
	
	new String:chatText[192];
	
	if(IsPlayerAlive(id))
		Format(chatText,sizeof(chatText),"\x01\x03(ADMIN) \x04%s : \x03%s",name,SayText);
	
	else
		Format(chatText,sizeof(chatText),"\x01\x03*DEAD* (ADMIN) \x04%s : \x03%s",name,SayText);
		
	for(new i = 1 ; i <= g_iMaxClients ; i++)
	{
		if(IsClientInGame(i) )
		{
			PrintToChat(i,chatText);
		}
	}
	
	return Plugin_Handled;
}


