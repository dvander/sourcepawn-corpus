#include <sourcemod>

new Handle:cvarAnnounce = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "L4D Away",
	author = "Ivailosp",
	description = "L4D Away",
	version = "0.0.2",
	url = "N/A"
};

public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if (!StrEqual(ModName, "left4dead", false))
	{
		SetFailState("Use this Left 4 Dead only.");
	}
	RegConsoleCmd("sm_away", Away);
	cvarAnnounce = CreateConVar("sm_away_announce","1");
	AutoExecConfig(true, "sm_away");
}

public Action:Away(client, args){
	if(client){
		new Handle:human_zombies = FindConVar("director_no_human_zombies");
		if(human_zombies != INVALID_HANDLE){
			if(GetConVarInt(human_zombies) == 0)
			{			
				if(GetClientTeam(client) == 2)
				{
					ServerCommand("director_no_human_zombies 1");
					FakeClientCommand(client, "go_away_from_keyboard");
					CreateTimer(0.05, TimerAway, client);
				}
				else
				{
					PrintToChat(client, "\x04[SM]\x03 Only survivors can use !away command.");
				}
			}
			else
			{
				FakeClientCommand(client, "go_away_from_keyboard");
			}
			CloseHandle(human_zombies);
		}
	}
}

public Action:TimerAway(Handle:timer, any:client)
{
	ServerCommand("director_no_human_zombies 0");
}

public OnClientPutInServer(client)
{
	if (client)
	{
		if (GetConVarBool(cvarAnnounce))
			CreateTimer(30.0, TimerAnnounce, client);
	}
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		PrintToChat(client, "\x04[SM]\x03 Type !away if you need to go AFK.");
	}
}