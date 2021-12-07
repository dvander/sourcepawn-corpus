	
	#pragma semicolon 1
	#include <sourcemod>
	
	#define PLUGIN_VERSION		"r4"
	
	#define MAX_AUTHID_LENGTH	20
	#define MAX_TEXT_LENGTH	191
		
	#define SPEC 1
	
	new Handle:g_hCvarShowMode;
	new g_ShowMode;
	
	public Plugin:myinfo =
	{
		name = "Say SteamID",
		author = "lok1 (New/Fixed plugin), fezh (Original plugin)",
		description = "This plugin provides your steam id to everyone when you write something in chat",
		version = PLUGIN_VERSION,
		url = "http://forums.alliedmods.net/"
	}
	
	public OnPluginStart()
	{
		AddCommandListener(HookSayCommand, "say");
		AddCommandListener(HookSayTeamCommand, "say_team");
		
		g_hCvarShowMode = CreateConVar("say_steamid_show_mode","2","Who will be able to see the steam ids? 0= Only admins 1= Admins + Spectators 2= Everyone.",_,true,0.0,true,2.0);
		
		AutoExecConfig(true,"say_steamid");
		
		HookConVarChange(g_hCvarShowMode,OnConVarChanged);
		
		CreateConVar("say_steamid_version", PLUGIN_VERSION, "Say SteamID version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
		
		
	}
	
	public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
		
		g_ShowMode = GetConVarInt(g_hCvarShowMode);
		
	}
	
	public OnConfigsExecuted(){
	
		g_ShowMode = GetConVarInt(g_hCvarShowMode);
	
	}
	
	public Action:HookSayCommand(Client, const String:command[], argc)
	{
		if(Client == 0 ||  IsChatTrigger())
			return Plugin_Continue;
		
		new String:szName[MAX_NAME_LENGTH];
		GetClientName(Client, szName, sizeof(szName));
		new String:szAuth[MAX_AUTHID_LENGTH];
		GetClientAuthString(Client, szAuth, sizeof(szAuth));
		new String:szText[MAX_TEXT_LENGTH];
		new String:szTextOriginal[MAX_TEXT_LENGTH];
		GetCmdArgString(szText, MAX_TEXT_LENGTH-1);
		StripQuotes(szText);
		Format(szText, MAX_TEXT_LENGTH-1, "\x01%s \x03%s \x04(%s)\x01: %s", IsPlayerAlive(Client) ? "" : "*DEAD*", szName, szAuth, szText);
		GetCmdArgString(szTextOriginal, MAX_TEXT_LENGTH-1);
		StripQuotes(szTextOriginal);
		Format(szTextOriginal, MAX_TEXT_LENGTH-1, "\x01%s \x03%s \x01: %s", IsPlayerAlive(Client) ? "" : "*DEAD*", szName, szTextOriginal);
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i)){
				
				if(IsPlayerAlive(Client) || !IsPlayerAlive(i))
					if(!CanSeeSteamId(i))
						PrintToChatColor(i, Client, szTextOriginal);
					else			
						PrintToChatColor(i, Client, szText);
						
			}
			//break;
		}
		return Plugin_Handled;
	}
	
	public Action:HookSayTeamCommand(Client, const String:command[], argc)
	{
		if(Client == 0  || IsChatTrigger())
			return Plugin_Continue;
		
		new String:szName[MAX_NAME_LENGTH];
		GetClientName(Client, szName, sizeof(szName));
		new String:szAuth[MAX_AUTHID_LENGTH];
		GetClientAuthString(Client, szAuth, sizeof(szAuth));
		new String:szText[MAX_TEXT_LENGTH];
		new String:szTextOriginal[MAX_TEXT_LENGTH];
		GetCmdArgString(szText, MAX_TEXT_LENGTH-1);
		StripQuotes(szText);
		Format(szText, MAX_TEXT_LENGTH-1, "\x01%s (TEAM) \x03%s \x04(%s)\x01: %s", IsPlayerAlive(Client) ? "" : "*DEAD*", szName, szAuth, szText);
		GetCmdArgString(szTextOriginal, MAX_TEXT_LENGTH-1);
		Format(szTextOriginal, MAX_TEXT_LENGTH-1, "\x01%s (TEAM) \x03%s \x01: %s", IsPlayerAlive(Client) ? "" : "*DEAD*", szName, szTextOriginal);
		for (new i = 1; i <= MaxClients; i++)
		{
			
			if(IsClientInGame(i)){
				if((IsPlayerAlive(Client) || !IsPlayerAlive(i)) && (GetClientTeam(Client) == GetClientTeam(i)))
					if(!CanSeeSteamId(i))
						PrintToChatColor(i, Client, szTextOriginal);
					else			
						PrintToChatColor(i, Client, szText);
				
			}
			//break;
			
		}
		return Plugin_Handled;
	}
	
	stock PrintToChatColor(client_index, author_index, const String:message[])
	{ 
		new Handle:buffer = StartMessageOne("SayText2", client_index);
		if (buffer != INVALID_HANDLE)
		{ 
			BfWriteByte(buffer, author_index); 
			BfWriteByte(buffer, true); 
			BfWriteString(buffer, message); 
			EndMessage(); 
		} 
	}
	
	
	stock bool:IsClientAdmin(client)
	{
  
		new flags = GetUserFlagBits(client);
		if (flags & ADMFLAG_GENERIC || flags & ADMFLAG_ROOT)
		{
			return true;
		}
		
		return false;
	}
	
	stock bool:CanSeeSteamId(client){
		//LogError("%N %d %d %d",client,IsClientAdmin(client) ,(g_ShowMode == 1 && GetClientTeam(client) == SPEC), g_ShowMode == 2);
		if(IsClientAdmin(client) || (g_ShowMode == 1 && GetClientTeam(client) == SPEC) || g_ShowMode == 2)
			return true;
		
		return false;
		
	}