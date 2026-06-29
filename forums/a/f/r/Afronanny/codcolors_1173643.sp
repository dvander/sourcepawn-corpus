#include <sourcemod>
#define MSG_LENGTH		256
#define PLUGIN_VERSION	"1.0.5"
new Handle:g_hCvarEnabled;

public Plugin:myinfo = 
{
	name = "Name Color Codes",
	author = "Afronanny",
	description = "Adds COD-style color-coding to names in chat",
	version = PLUGIN_VERSION,
	url = "http://jewgle.org"
}



public OnPluginStart()
{
	g_hCvarEnabled = CreateConVar("sm_codnamecolor_enabled", "1", "Enable the plugin", FCVAR_PLUGIN);
	CreateConVar("sm_codnamecolor_version", PLUGIN_VERSION, "Version of COD-Style color-codes", FCVAR_NOTIFY|FCVAR_PLUGIN);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);
}

public Action:Command_Say(client, args)
{
	if (GetConVarBool(g_hCvarEnabled))
	{
		if (client != 0)
		{
			decl String:msg[MSG_LENGTH];
			decl String:buffer[MSG_LENGTH + MAX_NAME_LENGTH];
			decl String:name[MAX_NAME_LENGTH];
			
			GetCmdArgString(msg, sizeof(msg));
			StripQuotes(msg);
			
			
			GetClientName(client, name, sizeof(name));
			
			ReplaceString(name, sizeof(name), "^0", "\x01");
			ReplaceString(name, sizeof(name), "^1", "\x01");
			ReplaceString(name, sizeof(name), "^2", "\x02");
			ReplaceString(name, sizeof(name), "^3", "\x03");
			ReplaceString(name, sizeof(name), "^4", "\x04");
			ReplaceString(name, sizeof(name), "^5", "\x05");
			ReplaceString(name, sizeof(name), "^6", "\x06");
			ReplaceString(name, sizeof(name), "^7", "\x01");
			ReplaceString(name, sizeof(name), "^8", "\x03");
			ReplaceString(name, sizeof(name), "^9", "\x04");
			
			new AdminId:id = GetUserAdmin(client);
			if (id == INVALID_ADMIN_ID)
				ReplaceString(name, sizeof(name), "[admin]", "", false);
			
			Format(buffer, sizeof(buffer), "\x03%s \x03: \x01%s", name, msg);
			
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i))
					SayText2(i, client, buffer);
			}
			
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}
public Action:Command_SayTeam(client, args)
{
	if (GetConVarBool(g_hCvarEnabled))
	{
		if (client != 0)
		{
		decl String:msg[MSG_LENGTH];
		
		GetCmdArgString(msg, sizeof(msg));
		StripQuotes(msg);
		
		decl String:buffer[MSG_LENGTH + MAX_NAME_LENGTH];
		decl String:name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		
		ReplaceString(name, sizeof(name), "^0", "\x01");
		ReplaceString(name, sizeof(name), "^1", "\x01");
		ReplaceString(name, sizeof(name), "^2", "\x02");
		ReplaceString(name, sizeof(name), "^3", "\x03");
		ReplaceString(name, sizeof(name), "^4", "\x04");
		ReplaceString(name, sizeof(name), "^5", "\x05");
		ReplaceString(name, sizeof(name), "^6", "\x06");
		ReplaceString(name, sizeof(name), "^7", "\x01");
		ReplaceString(name, sizeof(name), "^8", "\x03");
		ReplaceString(name, sizeof(name), "^9", "\x04");
		
		new AdminId:id = GetUserAdmin(client);
		if (id == INVALID_ADMIN_ID)
			ReplaceString(name, sizeof(name), "[admin]", "", false);
		
		Format(buffer, sizeof(buffer), "(TEAM)\x03 %s \x03: \x01%s", name, msg);
		new team = GetClientTeam(client);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == team)
				SayText2(i, client, buffer);
		}
		return Plugin_Stop;
	}
	} 
	return Plugin_Continue;
}

stock SayText2(client, author, const String:message[])
{
	new Handle:hBuffer = StartMessageOne("SayText2", client);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, true);
	BfWriteString(hBuffer, message);
	EndMessage();
}

