#include <sourcemod>

public OnPluginStart()
{
	RegConsoleCmd("sm_google", Command_Google);
}

public Action:Command_Google(client, args)
{
	new String:strSearch[128];
	
	GetCmdArgString(strSearch, sizeof(strSearch));
	
	Format(strSearch, sizeof(strSearch), "https://www.google.com/search?q=%s", strSearch);
	ShowMOTDPanel(client, "Google", strSearch, MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}