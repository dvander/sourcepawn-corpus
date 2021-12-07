

#include <sourcemod>
#include <sdktools>

#define L4D_TEAM_INFECTED 3
#define L4D_TEAM_SURVIVOR 2

#define PLUGIN_VERSION "1.2"

public Plugin:myinfo =
{
	name = "survivor & infected bot adder[gamemann]",
	author = "gamemann",
	description = "adds l4d2 infected bots",
	version = PLUGIN_VERSION,
	url = "sourcemod.net"
};

new Handle:AllowJoinCmd = INVALID_HANDLE;
new Handle:AllowAutoPicking = INVALID_HANDLE;
new Handle:AllowBotKicking = INVALID_HANDLE;
new Handle:AllowBotAdding = INVALID_HANDLE;
new Handle:Advertisement = INVALID_HANDLE;
new Handle:AllowClientPicking = INVALID_HANDLE;
new bool:InfectedSpawned = false;
new bool:SurvivorSpawned = false;

public OnPluginStart()
{
	//console cmds
	RegAdminCmd("sm_addbot", CmdAddBot, ADMFLAG_ROOT);
	RegAdminCmd("sm_addib", CmdInfectedBot, ADMFLAG_ROOT);

	//convars
	AllowJoinCmd = CreateConVar("l4d2_allow_join_cmds", "0", "if 1 it will allow everyone to type in the chatbox !join !joingame !jointeam 2 !jointeam 1 !jointeam 3 !joinsurvivor !joininfected !joinspectator");
	AllowAutoPicking = CreateConVar("l4d2_allow_auto_picking", "0", "if 1 when a player is in spectator mode it will make them join survivor mode automanicly, warning: This may interfierr with allow bot picking convar thats why i set it to 0!");
	Advertisement = CreateConVar("l4d2_allow_anvertisement", "1", "disablke or enable anvertisements for this plugin");
	AllowBotKicking = CreateConVar("l4d2_allow_bot_kicking", "0", "If 1 it will make it so when a client disconnects it will delete tht bot. Really works good with allow_bot_adding convar. USAGE: 1 = active , 0 = disabled");
	AllowBotAdding = CreateConVar("l4d2_allow_bot_adding", "0", "if 1 it will make it so when a client enters the game a bot will be created");
	AllowClientPicking = CreateConVar("l4d2_allow_bot_picking", "1", "if 1 it will make it so if a client is a specator they can say in the console !add and it will make a bot and they join it. USAGE: 1 = active , 0 = disabled");
		
	//checkers
	InfectedSpawned = false;
	SurvivorSpawned = false;

	//config
	AutoExecConfig(true, "l4d2_survivor_infected_adder");
}

public Action:CmdAddBot(client, args)
{
	new Handle:menu = CreateMenu(addbotmenu);
	SetMenuTitle(menu, "l4d2 clientaddbots menu");
	AddMenuItem(menu, "option0", "add survivor bot");
	AddMenuItem(menu, "option1", "add infected bot");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	//return;
}

public addbotmenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0: //adding a survivor bot
			{
				new survivorbot = CreateFakeClient("survivor bot");
				ChangeClientTeam(survivorbot, L4D_TEAM_SURVIVOR);
				DispatchKeyValue(survivorbot,"classname","SurvivorBot");
				DispatchSpawn(survivorbot);
				//now to make a timer to kick the client
				CreateTimer(1.0, SurvivorKicker,survivorbot);
				SurvivorSpawned = true;
				if (SurvivorSpawned == false)
				{
					LogError("survivor bot not spawned");
				}
			}
			
			case 1: // infected bot
			{
				new infectedbot = CreateFakeClient("infected bot");
				ChangeClientTeam(infectedbot, L4D_TEAM_INFECTED);
				//now to dispatch the spawn so it doesnt disapear in mid air!
				DispatchSpawn(infectedbot);
				DispatchKeyValue(infectedbot,"classname","InfectedBot");
				//now a timer to kick the infected bot
				CreateTimer(1.0, InfectedKicker,infectedbot);
				InfectedSpawned = true;
				if (InfectedSpawned == false)
				{
					LogError("infected bot not spawned");
				}
				if (infectedbot == ChangeClientTeam(infectedbot, L4D_TEAM_SURVIVOR))
				{
					LogError("infected bot changed to survivor bot");
					PrintToServer("infected bot changed to survivor bot");
				}
			}
		}
	}
}
//now for the infected bot spawn function

public Action:CmdInfectedBot(client, args)
{
	new bot = CreateFakeClient("infected bot");
	ChangeClientTeam(bot, L4D_TEAM_INFECTED);
	DispatchSpawn(bot);
	DispatchKeyValue(bot,"classname","InfectedBot");
	InfectedSpawned = true;
	CreateTimer(1.0, InfectedKicker,bot);
	return Plugin_Handled;
}



//now for timers!
/* timers settings and what they do */
/*
	KickFakeClient();
public Action:SurvivorKicker(Handle:timer, any:client)
{
	KickFakeClient();
}
*/

public Action:SurvivorKicker(Handle:timer, any:value)
{
	KickClient(value,"survivor bot");
	return Plugin_Continue;
}

public Action:InfectedKicker(Handle:timer, any:value)
{
	KickClient(value,"infected bot");
	return Plugin_Handled;
}


/* solution */
public OnMapEnd()
{
	CreateTimer(10.0, EndTimer);
}

public Action:EndTimer(Handle:timer)
{
	//nothing
}

//now for the other convars stuff!

public OnClientConnected(client)
{
	if (GetConVarInt(AllowJoinCmd))
	{
		//survivor commands
		RegConsoleCmd("sm_join", JoinSurvivor);
		RegConsoleCmd("sm_joingame", JoinSurvivor);
		RegConsoleCmd("sm_jointeam 2", JoinSurvivor);
		RegConsoleCmd("sm_joinsurvivor", JoinSurvivor);
		//infected commands
		RegConsoleCmd("sm_joininfected", JoinInfected);
		RegConsoleCmd("sm_jointeam 3", JoinInfected);
		//spectator
		RegConsoleCmd("sm_joinspectator", JoinSpectator);
		RegConsoleCmd("sm_jointeam 1", JoinSpectator);
	}
	else
	{
		return 0;
	}
		
	if (GetConVarInt(AllowAutoPicking))
	{
		if (GetClientTeam(client) == 1)
		{
			FakeClientCommand(client, "jointeam 2");
		}
	}
	else
	{
		return 0;
	}
	if (GetConVarInt(AllowBotAdding))
	{
		new bot = CreateFakeClient("bot1");
		ChangeClientTeam(bot, L4D_TEAM_SURVIVOR);
		DispatchSpawn(bot);
		DispatchKeyValue(bot,"classname","SurvivorBot");
		SurvivorSpawned = true;
		CreateTimer(1.0, SK);
	}
	else
	{
		return 0;
	}
	if (GetConVarInt(AllowClientPicking))
	{
		if (GetClientTeam(client) == 1)
		{
			RegConsoleCmd("sm_add", CmdAdd);
			RegConsoleCmd("sm_joinbot", CmdJoin);
			PrintToChat(client, "\x03 your a spectator so you can tpye in the chatbox !add to add a bot and !joinbot to join the bot!");
		}
	}
	else
	{
		return 0;
	}
	if (GetConVarInt(Advertisement))
	{
		PrintToChat(client, "\x03 this server uses survivor&infected adding bots by gamemann");
	}
	else
	{
		return 0;
	}
	return 1;
}

public Action:SK(Handle:timer, any:value)
{
	KickClient(value, "bot1");
	return Plugin_Handled;
}

public Action:CmdAdd(client, args)
{
	new bot = CreateFakeClient("bot2");
	ChangeClientTeam(bot, L4D_TEAM_SURVIVOR);
	DispatchSpawn(bot);
	DispatchKeyValue(bot,"classname","SurvivorBot");
	SurvivorSpawned = true;
	CreateTimer(1.0, SK2);
	return Plugin_Handled;
}

public Action:CmdJoin(client, args)
{
	FakeClientCommand(client, "jointeam 2");
	return Plugin_Handled;
}

public Action:SK2(Handle:timer, any:value)
{
	KickClient(value, "bot2");
	return Plugin_Handled;
}

public OnClientDisconnect(client)
{
	if (GetConVarInt(AllowBotKicking))
	{
		KickClient(client, "bot");
	}
	else
	{
		return 0;
	}
	return 1;
}


//join commands
public Action:JoinSurvivor(client, args)
{
	FakeClientCommand(client, "jointeam 2");
	return Plugin_Handled;
}

public Action:JoinInfected(client, args)
{
	FakeClientCommand(client, "jointeam 3");
	return Plugin_Handled;
}

public Action:JoinSpectator(client, args)
{
	FakeClientCommand(client, "jointeam 1");
	return Plugin_Handled;
}





				
