public OnPluginStart()
{
	RegConsoleCmd("status", Block)
	RegConsoleCmd("ping", Block)
}

public Action:Block(client, args)
{
	return Plugin_Handled;
}