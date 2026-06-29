public OnPluginStart()
{
	HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);
}

public Action:TextMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if(reliable)
	{
		new String:buffer[20];
		BfReadString(bf, buffer, sizeof(buffer));
		if(StrContains(buffer, "\x03[SM] Console:") == 0)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}