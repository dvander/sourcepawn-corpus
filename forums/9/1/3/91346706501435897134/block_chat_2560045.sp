#include <sourcemod>



public Plugin myinfo =
{
	name = "block chat",
	author = "91346706501435897134",
	description = "blocks chat",
	version = "1.0",
}



public Action OnClientSayCommand(int client, const char[] commnad, const char[] args)
{
	if (client != 0)
	{
		PrintToChat(client, ">> Chat is disabled!");



		return Plugin_Handled;
	}



	return Plugin_Continue;
}