#include <sourcemod>



public Plugin myinfo =
{
	name = "block_spectator_say",
	author = "91346706501435897134",
	description = "mutes spectators",
	version = "1.0",
}



public Action OnClientSayCommand(int client, const char[] commnad, const char[] args)
{
	if (client != 0 && IsClientObserver(client))
	{
		PrintToChat(client, ">> cannot talk in spectators!");



		return Plugin_Handled;
	}


	return Plugin_Continue;
}