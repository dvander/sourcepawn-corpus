#include <sourcemod>
#include <colors>

//IsPlayerAlive(client) GetClientTeam(client) GivePlayerItem(client, "weapon_knife")
//IsClientInGame(client)

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
    name = "Admin Check",
    author = "xbatista",
    description = "Shows admins online",
    version = PLUGIN_VERSION,
    url = "www.laikiux.lt"
};

public OnPluginStart()
{
	CreateConVar("some_command", PLUGIN_VERSION, "Shows admins online", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegConsoleCmd("say", Say_SendToAll);
}
public Action:Say_SendToAll(client, args)
{
	decl String:Text[192];
	decl String:szArg1[16]
	GetCmdArgString(Text, sizeof(Text));

	StripQuotes(Text)

	BreakString(Text, szArg1, sizeof(szArg1))

	new String:AdminNames[MAXPLAYERS+1][MAX_NAME_LENGTH]
	new String:Message[256]

	new X, Len
	new Count = 0

	if( StrEqual(szArg1, "!uzai") || StrEqual(szArg1, "uzai") || StrEqual(szArg1, "!admins") || StrEqual(szArg1, "admins") )
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if ( IsClientInGame(i) )
			{
				if(GetUserAdmin(i) != INVALID_ADMIN_ID)
				{
					GetClientName(i, AdminNames[Count], sizeof(AdminNames[]));

					Count++
				}
			}	
		}

		Len = Format(Message, sizeof(Message), "Admins Online: " )

		if(Count > 0)
		{
			for(X = 0 ; X < Count ; X++)
			{
				Len += Format(Message[Len], sizeof(Message) - Len, "{green}%s%s ", AdminNames[X], X < (Count - 1) ? ", ":"")
			}

			CPrintToChat(client, Message)
		}
		else 
		{
			Len += Format(Message[Len], sizeof(Message) - Len, "{red}No Admins Online.")
			CPrintToChat(client, Message)
		}

		return Plugin_Handled
	}

	return Plugin_Continue
}