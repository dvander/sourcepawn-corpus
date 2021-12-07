#include <sourcemod>
#include <chat-processor>

public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
	if (StrContains(flagstring, "team", false) != -1)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && CheckCommandAccess(i, "admin", ADMFLAG_GENERIC, true))
			{
				if (FindValueInArray(recipients, GetClientUserId(i)) == -1)
					PushArrayCell(recipients, GetClientUserId(i));
		    }
	    }
	}
}

public bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}