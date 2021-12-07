#include <sourcemod>

#pragma semicolon 1


new Handle:AdminListEnabled;

public Plugin:myinfo = 
{
	name = "Admin List",
	author = "Fredd",
	description = "prints admins to clients",
	version = "1.1",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("adminlist_version", "1.1", "Admin List Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	AdminListEnabled		= CreateConVar("adminlist_on", "1", "turns on and off admin list, 1=on ,0=off");
	
	RegConsoleCmd("say", SayHook);
	RegConsoleCmd("say_team", SayHook);
}
public Action:SayHook(client, args)
{
	if(GetConVarInt(AdminListEnabled) == 1)
	{   
		new String:text[192];
		GetCmdArgString(text, sizeof(text));
		
		new startidx = 0;
		if (text[0] == '"')
		{
			startidx = 1;
			
			new len = strlen(text);
			if (text[len-1] == '"')
			{
				text[len-1] = '\0';
			}
		}
		
		if(StrEqual(text[startidx], "!admins") || StrEqual(text[startidx], "/admins"))
		{
			decl String:AdminNames[MAXPLAYERS+1][MAX_NAME_LENGTH+1];
			new count = 0;
			for(new i = 1 ; i <= GetMaxClients() ; i++)
			{
				if(IsClientInGame(i))
				{
					new AdminId:AdminID = GetUserAdmin(i);
					if(AdminID != INVALID_ADMIN_ID)
					{
						GetClientName(i, AdminNames[count], sizeof(AdminNames[]));
						count++;
					
					}
				} 
			}
			decl String:buffer[1024];
			ImplodeStrings(AdminNames, count, ",", buffer, sizeof(buffer));
			PrintHintTextToAll("\x04Admins online are: %s", buffer);
		}
	}
	return Plugin_Continue;
}