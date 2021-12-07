public Plugin:myinfo = 
{
	name = "Command hider",
	author = "Author zipcore Compiled by Playa",
	description = "Hids annoying commands in the chat",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
    AddCommandListener(HideCommands,"say");
    AddCommandListener(HideCommands,"say_team");
}
 
public Action:HideCommands(client, const String:command[], argc)
{
    if(IsChatTrigger())
        return Plugin_Handled;
   
    return Plugin_Continue;
}  