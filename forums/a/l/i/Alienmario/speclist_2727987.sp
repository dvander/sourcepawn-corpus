#pragma semicolon 1

#include <sourcemod>

char szSpecString[512];

public Plugin myinfo = 
{
    name = "BM Spectator list", 
    author = "Alienmario", 
    description = "A plugin for showing spectators", 
    version = "1.0.0", 
    url = ""
};

public void OnPluginStart()
{
}

void BuildSpecList()
{
	szSpecString = "Spectators:";
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 1)
		{
			Format(szSpecString, sizeof(szSpecString), "%s\n%N", szSpecString, i);
		}
	}
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	static int oldButtons[MAXPLAYERS+1];
	
	if(!IsFakeClient(client))
	{
		if(buttons & IN_SCORE && !(oldButtons[client] & IN_SCORE))
		{
			BuildSpecList();
			Client_PrintKeyHintText(client, szSpecString);
		}
		else if (!(buttons & IN_SCORE) && oldButtons[client] & IN_SCORE)
		{
			Client_PrintKeyHintText(client, " ");
		}
		oldButtons[client] = buttons;
	}
}

// Function copied from smlib
/**
 * Prints white text to the right-center side of the screen
 * for one client. Does not work in all games.
 * Line Breaks can be done with "\n".
 *
 * @param client		Client Index.
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @return				True on success, false if this usermessage doesn't exist.
 */
stock bool Client_PrintKeyHintText(int client, const char[] format, any ...)
{
	Handle userMessage = StartMessageOne("KeyHintText", client);

	if (userMessage == INVALID_HANDLE) {
		return false;
	}

	char buffer[254];

	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);

	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available
		&& GetUserMessageType() == UM_Protobuf) {

		PbAddString(userMessage, "hints", buffer);
	}
	else {
		BfWriteByte(userMessage, 1);
		BfWriteString(userMessage, buffer);
	}

	EndMessage();

	return true;
}