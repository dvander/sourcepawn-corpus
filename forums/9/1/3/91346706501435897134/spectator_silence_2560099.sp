#include <sourcemod>
#include <basecomm>



public Plugin myinfo =
{
	name = "spectator_silence",
	author = "91346706501435897134",
	description = "silences spectators",
	version = "1.0",
}



public void OnPluginStart()
{
	HookEvent("player_team", event_player_change_team);
}



public void event_player_change_team(Event event, const char[] name, bool dontBroadcast)
{
	int team_id = event.GetInt("team");
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (team_id == 1)
	{
		PrintToChat(client, ">> you are silenced while being in spectator.");
		BaseComm_SetClientMute(client, true);
	}
	else
	{

		BaseComm_SetClientMute(client, false);
	}
}



public Action OnClientSayCommand(int client, const char[] command, const char[] args)
{
	if (client != 0 && IsClientObserver(client))
	{
		PrintToChat(client, ">> cannot talk in spectators!");



		return Plugin_Handled;
	}



	return Plugin_Continue;
}