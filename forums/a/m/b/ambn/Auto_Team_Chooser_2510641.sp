#include <sourcemod>
public Plugin myinfo =  {

	name = "[ANY] Auto Team Changer",
	author = "noBrain",
	description = "This plugin will handle player joins",
	version = "1.1",

};
ConVar a_jAutoJoin = null;
ConVar a_jCheckDelay = null;
Handle TimerHandle[MAXPLAYERS+1] = INVALID_HANDLE;
int TeamNumber[MAXPLAYERS+1];
public void OnPluginStart()
{
	a_jAutoJoin = CreateConVar("sm_auto_join", "1", "If enabled, then server will check for conneced players and move their teamsl");
	a_jCheckDelay = CreateConVar("sm_check_time", "10.0", "Used when auto join is enabled and will check after this period of time");
}
public void OnClientPostAdminCheck(int client)
{
	//Check if the auto join function is allowed to be run.
	if(GetConVarBool(a_jAutoJoin))
	{
		//Set client pre-defined team number to 4
		TeamNumber[client] = 0;
		//Timer to check if player has chosen team or not and keep checking.
		TimerHandle[client] = CreateTimer(GetConVarFloat(a_jCheckDelay), Timer_Check, client, TIMER_REPEAT);
	}
}
public Action Timer_Check(Handle timer, any userid)
{
	//prevent possible timer issue
	int client = GetClientOfUserId(userid);
	//Check for user TeamID but first if the user is actully in game or not
	if(IsClientInGame(client) && IsClientConnected(client))
	{
		//Get Client Team
		int CurrentTeamNumber = GetClientTeam(client);
		if(CurrentTeamNumber == TeamNumber[client])
		{
			//Get Players Team Count
			int CT = GetPlayerTeamCount(3);
			int TE = GetPlayerTeamCount(2);
			if(CT > TE)
			{
				ChangeClientTeam(client, 2);
				PrintToChat(client, "[SM] You have been moved to Terror Side!");
			}
			else if(CT < TE)
			{
				ChangeClientTeam(client, 3);
				PrintToChat(client, "[SM] You have been moved to CT Side!");
			}
			else if(CT == TE)
			{
				//If CT = T then choose a random team number
				int RandomTeam = GetRandomInt(2, 3);
				ChangeClientTeam(client, RandomTeam);
			}
		}
		//Kill handle if client is found and is job is done;
		KillTimer(TimerHandle[client]);
	}
	//If user has disconnected after join immediately then no more checks is required
	else if(!IsClientConnected(client))
	{
		KillTimer(TimerHandle[client])
	}
	//else the check will keep repeating until some results comes out!
}
//This will get player's count of a team
stock int GetPlayerTeamCount(int team)
{
	int MTeamNum = 0;
	for(int user = 1; user <=MaxClients; user++)
	{
		if(IsClientConnected(user))
		{
			if(GetClientTeam(user) == team)
			{
				MTeamNum++;
			}
		}
	}
	return MTeamNum;
}