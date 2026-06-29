public OnPluginStart()
 	{      
		RegConsoleCmd("sm plugins", SayCallback);
 	}
public Action:SayCallback(client, args) 
	{
          	return Plugin_Handled; 
	}