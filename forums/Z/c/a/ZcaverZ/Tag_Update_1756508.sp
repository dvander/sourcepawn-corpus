#include <sourcemod>

new bool:ClientUseTag[MAXPLAYERS+1] = {false,...};

public Plugin:myinfo =
{
	name = "Custom Admin Prefixes",
	author = "Marcus",
	description = "A plugin that addes special prefixes to your name if you are admin.",
	version = "1.0.0",
	url = "http://snbx.info"
};
enum AdminLevel{
	AL_None=0,
	AL_Root,
	AL_LeadAdmin,
	AL_Admin
};
public OnClientPostAdminCheck(client)
{
	new AdminId:id = GetUserAdmin(client);
	if (id != INVALID_ADMIN_ID)
	{
		ClientUseTag[client] = true;
	}
} 
public OnPluginStart()
{
	RegAdminCmd("sm_admintag", Command_ATag, ADMFLAG_GENERIC);
	AddCommandListener(HookPlayerChat, "say");
}
public Action:Command_ATag(client, args)
{
	if (!ClientUseTag[client])
	{
		PrintToChat2(client, "\x070069DC[Notice]\x01 You have now enabled your admin tag.");
		ClientUseTag[client] = true;
	}
	else if (ClientUseTag[client])
	{
		PrintToChat2(client, "\x070069DC[Notice]\x01 You have now disabled your admin tag.");
		ClientUseTag[client] = false;
	}
}
public AdminLevel:GetAdmin(client)
{
	if(IsValidClient(client))
	{
		if(!GetUserFlagBits(client))
			return AL_None;
		else if(GetUserFlagBits(client)&ADMFLAG_ROOT > 0)
			return AL_Root;
		else if(GetUserFlagBits(client)&ADMFLAG_RCON > 0)
			return AL_LeadAdmin;
		else if(GetUserFlagBits(client)&ADMFLAG_GENERIC > 0)
			return AL_Admin;
		else
			return AL_None;
	}
	return AL_None;
}
stock bool:IsValidClient( client ) 
{
    if((1<=client<= MaxClients ) && IsClientInGame(client)) 
        return true; 
     
    return false; 
}
public Action:HookPlayerChat(client, const String:command[], args)
{
	if (IsClientInGame(client) && ClientUseTag[client])
	{
		decl String:szText[256], String:szAuthId[32];
		szText[0] = '\0';
		GetCmdArg(1, szText, sizeof(szText));
		GetClientAuthString(client, szAuthId, 32);

		if (szText[0] != '/' && szText[0] != '!')
		{
			if (GetAdmin(client) == AL_Root)
			{
				PrintToChatAll2("\x07DC6900[Owner]\x01 %N: \x070069DC%s\x01",client, szText);
			}
			if (GetAdmin(client) == AL_LeadAdmin)
			{
				PrintToChatAll2("\x07DC6900[Lead Admin]\x01 %N: \x070069DC%s\x01",client, szText);
			}
			if (GetAdmin(client) == AL_Admin)
			{
				PrintToChatAll2("\x07DC6900[Admin]\x01 %N: \x070069DC%s\x01",client, szText);
			}
			if (GetAdmin(client) == AL_None)
			{
				return Plugin_Handled;
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public PrintToChat2(client, const String:format[], any:...)
{
	decl String:buffer[256];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	
	new Handle:bf = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	BfWriteByte(bf, -1);
	BfWriteByte(bf, true);
	BfWriteString(bf, buffer);
	EndMessage();
}
public PrintToChatAll2(const String:format[], any:...)
{
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), format, 2);
	
	new Handle:bf = StartMessageAll("SayText2", USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	BfWriteByte(bf, -1);
	BfWriteByte(bf, true);
	BfWriteString(bf, buffer);
	EndMessage();
}