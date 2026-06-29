


Handle timer_activate[MAXPLAYERS+1];
ArrayList codes;

public void OnPluginStart()
{

	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/codes.txt");

	// file not exist
	if(!FileExists(buffer)) SetFailState("Plugin could not find ...%s", buffer);

	File txt = OpenFile(buffer, "r");

	// error to open txt file
	if(txt == null) SetFailState("Plugin couldn't open file %s", buffer);

	buffer[0] = '\x0';

	// admin group is missing
	if(FindAdmGroup("codes") == INVALID_GROUP_ID) SetFailState("Plugin couldn't find Admin Group called: codes");






	codes = new ArrayList(ByteCountToCells(128));
	
	int newline = -1;

	while(!txt.EndOfFile())
	{
		if(!txt.ReadLine(buffer, sizeof(buffer)))
			break;

		newline = FindCharInString(buffer, '\n', true);

		if(newline != -1)
		{
			buffer[newline] = '\x0';
		}

		if(strlen(buffer) < 2) continue;

		codes.PushString(buffer);
		PrintToServer(" code: \"%s\" added in memory", buffer);
		
	}

	RegConsoleCmd("sm_activate", activate);
}


public Action activate(int client, int args)
{

	if(client == 0)
	{
		ReplyToCommand(client, "[SM] Command is for players, to activate code");
		return Plugin_Handled;
	}

	if(!IsClientInGame(client) || IsFakeClient(client))
	{
		return Plugin_Handled;
	}


	if(GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		ReplyToCommand(client, "[SM] You have already some SM admin priviledge.");
		return Plugin_Handled;
	}


	PrintToChat(client, " \x0E[SM] Enter code in chat, you have 15 seconds to complete:");

	if(timer_activate[client] != null)
		delete timer_activate[client];

	timer_activate[client] = CreateTimer(15.0, delay, client);

	return Plugin_Handled;
}

public Action delay(Handle timer, any data)
{
	timer_activate[data] = null;
	return Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{

	if(timer_activate[client] == null)
		return Plugin_Continue;

	delete timer_activate[client];

	int index = codes.FindString(sArgs);

	if(index != -1)
	{
		AdminId id = CreateAdmin("admin_codes");
		SetUserAdmin(client, id, true);

		GroupId gid = FindAdmGroup("codes");

		if(gid != INVALID_GROUP_ID && AdminInheritGroup(id, gid))
		{
			PrintToChat(client, " \x0E[SM] Code found: \"%s\"\n You have added in admin group \"codes\"", sArgs);

			//codes.Erase(index);	// uncomment this line if you want remove code after activation
		}
	}

	return Plugin_Handled;

}











