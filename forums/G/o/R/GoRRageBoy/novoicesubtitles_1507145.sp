#include <sourcemod>

#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "No Voice Subtitles",
	author = "GoRRageBoy",
	description = "Removes all in-chat messages when using Voice commands.",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	HookUserMessage(GetUserMessageId("VoiceSubtitle"), VoiceHook, true); 
}

public Action:VoiceHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new clientid = BfReadByte(bf);
	new voicemenu1 = BfReadByte(bf);
	new voicemenu2 = BfReadByte(bf);
	
	if (IsPlayerAlive(clientid) && IsClientInGame(clientid))
	{	
		if (voicemenu1 == 0)
		{
			switch (voicemenu2)
			{
				case 0:
				{
					return Plugin_Handled;
				}
				case 1:
				{
					return Plugin_Handled;
				}
				case 2:
				{
					return Plugin_Handled;
				}
				case 3:
				{
					return Plugin_Handled;
				}
				case 4:
				{
					return Plugin_Handled;
				}
				case 5:
				{
					return Plugin_Handled;
				}
				case 6:
				{
					return Plugin_Handled;
				}
				case 7:
				{
					return Plugin_Handled;
				}
			}
		}
		if (voicemenu1 == 1)
		{
			switch (voicemenu2)
			{
				case 0:
				{
					return Plugin_Handled;
				}
				case 1:
				{
					return Plugin_Handled;
				}
				case 2:
				{
					return Plugin_Handled;
				}
				case 6:
				{
					return Plugin_Handled;
				}
			}
		}
		if((voicemenu1 == 2) && (voicemenu2 == 0))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}