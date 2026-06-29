#include <sourcemod>

#define maxVote 3

int voteTimes;

public Plugin:myinfo = {
	name = "Client Initialized Voting - Alltalk", 
	author = "LazyLizard", 
	description = "!alltalk", 
	version = "1.8", 
	
}

public OnMapStart()
{
	voteTimes = 0;
	
}

public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		
		CloseHandle(menu);
	} else if (action == MenuAction_VoteEnd) {
		
		if (param1 == 0)
		{
			
			PrintToChatAll("Общий чат включен!");
			voteTimes = voteTimes + 1;
			ServerCommand("sv_alltalk 1");
		}
		else
		{
			PrintToChatAll("Общий чат выключен!");
			voteTimes = voteTimes + 1;
			ServerCommand("sv_alltalk 0");
		}
	}
}




public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	
	if (client && StrEqual(sArgs, "!alltalk\0", false))
	{
		
		if (voteTimes >= maxVote)
		{
			PrintToChat(client, "\x04Голосование за общий чат уже проводилось.");
			return;
		}
		
		if (!IsNewVoteAllowed())
		{
			PrintToChat(client, "\x04Пока нельзя запустить голосование.");
			return;
		}
		
		
		
		ShowActivity2(client, "[SM] ", "Initiated Vote alltalk");
		LogAction(client, -1, "\"%L\" used vote-alltalk", client);
		new Handle:menu = CreateMenu(Handle_VoteMenu);
		SetMenuTitle(menu, "Включить общий чат, чтобы все слышали мои шутки?");
		AddMenuItem(menu, "notsure1", "Да");
		AddMenuItem(menu, "notsure2", "Нет");
		SetMenuExitButton(menu, false);
		VoteMenuToAll(menu, 18);
		
		return;
		
		
	}
}
