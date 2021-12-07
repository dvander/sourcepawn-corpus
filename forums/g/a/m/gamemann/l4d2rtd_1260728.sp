#include <sourcemod>
#include <sdktools>

//this is rp
//random picks:
/*
- player death
- health
- weapons packs
- horde
- new bot to help you
- etc
*/
//convars
new Handle:PlayerDeathE = INVALID_HANDLE;
new Handle:HealthE = INVALID_HANDLE;
new Handle:HordeE = INVALID_HANDLE;
new Handle:NewBotE = INVALID_HANDLE;
new Handle:AdvertE = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "rp_mod",
	author = "gamemann",
	description = "A rtd mod for l4d2",
	version = "1.0",
	url = "games223.com"
};

public OnPluginStart()
{
	//convars
	PlayerDeathE = CreateConVar("player_death_choice", "1", "enable player death in random pick");
	HealthE = CreateConVar("health_choice", "1", "Enable health random pick");
	HordeE = CreateConVar("horde_choice", "1", "Enable horde random pick");
	NewBotE = CreateConVar("new_bot_choice", "1", "enable random pick");
	AdvertE = CreateConVar("advert_enable", "1", "enable advertisement or not");
	//console cmds
	RegConsoleCmd("sm_rp", CmdPick);
	//advert event
	HookEvent("round_start", RoundStart);
	AutoExecConfig(true, "l4d2_rp");
}

//cmd rp
public Action:CmdPick(client, args)
{
	//now for the random choice
	new RandomPick = GetRandomInt(1,5);
	//now for the choices
	if (RandomPick == 1)
	{
		if(HealthE)
		{
			FakeClientCommand(client, "give health");
		}
		else
		{
			PrintToChat(client, "\x04 you get nothing since this choice is unabled!");
		}
	}
	if (RandomPick == 2)
	{
		if(NewBotE)
		{
			if (GetClientTeam(client) == 3)
			{
				new bot = CreateFakeClient("infected bot");
				ChangeClientTeam(bot, 3);
				DispatchSpawn(bot);
				DispatchKeyValue(bot,"classname","InfectedBot");
				CreateTimer(1.0,InfectedKicker,bot);
			}
			if (GetClientTeam(client)==2)
			{
				new bot = CreateFakeClient("infected bot");
				ChangeClientTeam(bot, 3);
				DispatchSpawn(bot);
				DispatchKeyValue(bot,"classname","InfectedBot");
				CreateTimer(1.0, SurvivorKicker,bot);
			}
			else
			{
				PrintToChat(client, "\x04 you get nothing since this choice is unabled!");
			}
		}
		if (RandomPick == 3)
		{
			if(PlayerDeathE)
			{
				FakeClientCommand(client, "kill");
			}
			else
			{
				PrintToChat(client, "\x04 you get nothing since this choice is unabled!");
			}
		}
		if (RandomPick == 4)
		{
			if(HordeE)
			{
				FakeClientCommand(client, "director_force_panic_event");
			}
			else
			{
				PrintToChat(client, "you get nothing since this choice is unabled!");
			}
		}
		if (RandomPick == 5)
		{
			PrintToChat(client, "hahaha you get nothing!");
		}
	}
	return Plugin_Handled;
}

//ADVERT
public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(AdvertE)
	{
		for (new i = 1; i <= GetMaxClients(); i++)
		if (IsClientInGame(i))
		{
			PrintToChat(i, "\x05 this server is running \x04 rp_mod so type in the chat !rp and you get a random thing!");
		}
	}
}


public Action:SurvivorKicker(Handle:timer, any:value)
{
	KickClient(value, "survivor bot");
	return Plugin_Handled;
}

public Action:InfectedKicker(Handle:timer, any:value)
{
	KickClient(value, "infected bot");
	return Plugin_Handled;
}


	


