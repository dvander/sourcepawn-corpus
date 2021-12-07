#define PLUGIN_VERSION "1.0beta"

#include <sourcemod>
#include <sdktools>
#include <colors>
#pragma semicolon 1

/*=====================
        $ Tag $
=======================*/
#define FC  	  "{blue}[{green}Black4Jack{blue}]{default}"

/*=====================
        $ Sound $
=======================*/
#define BlackJack "ambient/materials/ripped_screen01.wav"
#define NotNow "ambient/water/distant_drip2.wav"
#define Win "level/gnomeftw.wav"
#define Push "level/loud/bell_break.wav"
#define Lose "music/bacteria/hunterbacteria.wav"

/*=====================
	   $ ConVar $
=======================*/
new		Handle:MsgTimer[MAXPLAYERS + 1], Handle:g_BJbet, Handle:g_HpLimit;
new		playercard[MAXPLAYERS + 1],  dealer[MAXPLAYERS + 1], card, card2, PlayerHp, Value, Hp, HpLimit;
new		bool:pass[MAXPLAYERS + 1], bool:passblock[MAXPLAYERS + 1],  bool:dilerpass[MAXPLAYERS + 1],  bool:hpblock[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "[L4D2] Black4Jack",
	author = "raziEiL [disawar1]",
	description = "",
	version = PLUGIN_VERSION,
	url = "www.27days-support.at.ua"
}

/*=====================
	$ PLUGIN START! $
=======================*/
public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("plugin supports Left 4 Dead 2 only.");
	}
	
	g_BJbet=CreateConVar("black_jack_bet", "20", "Player's bet in HP", FCVAR_PLUGIN);
	g_HpLimit=CreateConVar("black_jack_health", "100", "Player's max HP", FCVAR_PLUGIN);
	AutoExecConfig(true, "l4d2_Black4Jack");
	
	HookConVarChange(g_BJbet, OnCVarChange);
	HookConVarChange(g_HpLimit, OnCVarChange);
	
	RegConsoleCmd("bj", CmdBlakJack, "Play Blackjack");
	RegConsoleCmd("21", CmdBlakJack, "Play Blackjack");
	RegConsoleCmd("pass", CmdPass, "Blackjack Pass");
}

public OnMapStart()
{
	PrecacheSound(BlackJack, true);
	PrecacheSound(NotNow, true);
	PrecacheSound(Win, true);
	PrecacheSound(Push, true);
	PrecacheSound(Lose, true);
}

public OnClientPostAdminCheck(client)
{
	new clientID = GetClientUserId(client);
	CreateTimer(12.0, Welcome, clientID);
}

public Action:Welcome(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);
	if (client && IsClientInGame(client))
		CPrintToChat(client, "%s You can win a prize! bet - {blue}%dhp{default}. Type {olive}!bj{default} in chat.", FC, Value);
}
/*=====================
		$ Cmd $
=======================*/
public Action:CmdBlakJack(client, agrs)
{	
	if (pass[client] == true || GetClientTeam(client) != 2)
	{
		CPrintToChat(client, "%s {blue}%N{default} not NoW!", FC, client);
		EmitSoundToClient(client, NotNow);
		return Plugin_Handled;
	}
	
	PlayerHp=GetClientHealth(client);
	Hp=PlayerHp-Value;
	
	if (PlayerHp > Value && hpblock[client] == false)
	{
		SetEntProp(client, Prop_Send, "m_iHealth", Hp);
		hpblock[client]=true;
	}
	if (PlayerHp <= Value && hpblock[client] == false) 
	{
		CPrintToChat(client, "%s {blue}%N{default} try again later!", FC, client); 
		return Plugin_Handled;
	}
	if (dealer[client] >= 17)
	{
		CPrintToChat(client, "%s Dealer - Pass!", FC, dealer[client]);
		dilerpass[client]=true;
	}
	else
	{
		card2=GetRandomInt(1, 11);
		dealer[client]+=card2;
	}
	
	card=GetRandomInt(1, 11);
	playercard[client]+=card;
	EmitSoundToClient(client, BlackJack);
	PlayerIdle(client);
	//CPrintToChat(client, "[debug] %d-%d", playercard[client], dealer[client]);
	PlayingField(client);
	return Plugin_Handled;
}

public Action:CmdPass(client, agrs)
{
	if (pass[client] == true || GetClientTeam(client) != 2)
	{
		CPrintToChat(client, "%s {blue}%N{default} not NoW!", FC, client);
		EmitSoundToClient(client, NotNow);
		return Plugin_Handled;
	}
	
	
	if (playercard[client] >= 17 && dealer[client] <= 21 && playercard[client] <= 20 && dilerpass[client]==false)
	{
		pass[client]=true;
		passblock[client]=true;
		PlayerIdle(client);
		
		for (dealer[client]; dealer[client] < playercard[client]; dealer[client]++)
		{
			card2=GetRandomInt(1, 11);
			dealer[client]+=card2;	
		}
		CPrintToChat(client, "%s {blue}%N{default} - Pass!", FC, client);
		PlayingField(client);
	}
	else if (playercard[client] >= 17 && dealer[client] <= 21 && playercard[client] <= 21)
	{
		pass[client]=true;
		passblock[client]=true;
		PlayerIdle(client);
		CPrintToChat(client, "%s {blue}%N{default} - Pass!", FC, client);
		PlayingField(client);
	}
	else if (playercard[client] > dealer[client] && dilerpass[client]==true)
	{
		pass[client]=true;
		PlayerIdle(client);
		CPrintToChat(client, "%s {blue}%N{default} - Pass!", FC, client);
		//CPrintToChatAll( "%s %d:%d - {blue}%N{default} is {green}WIN!", FC, playercard[client], dealer[client], client);
		EmitSoundToClient(client, Win);
		GetBackMyHp(client);
		GameisOver();
	}
	else 
	{
		CPrintToChat(client, "%s {blue}%N{default} not NoW!", FC, client); 
		EmitSoundToClient(client, NotNow);
	}
	return Plugin_Handled;
}

/*=====================
		$ Other $
=======================*/
public PlayerIdle(client)
{
	KillMsgTimer();// Player back, kill timer.
	new clientID=GetClientUserId(client);
	MsgTimer[client]=CreateTimer(60.0, CancelJack, clientID);// Player Idle, game is over!
}

public KillMsgTimer()
{	
	for(new i = 0; i < MAXPLAYERS; i ++)
	{
		if (MsgTimer[i] != INVALID_HANDLE)
		{
			CloseHandle(MsgTimer[i]);
			MsgTimer[i] = INVALID_HANDLE;
		}
	}
}

public Action:CancelJack(Handle:timer, any:client)
{
	client=GetClientOfUserId(client);
	if (client && IsClientInGame(client))
	for(new i = 0; i < MAXPLAYERS; i ++)
	{
		if (playercard[i] > 1)
		{
			CPrintToChat(client, "%s {blue}%N{default} game was cancelled.", FC, client);
			GameisOver();
		}
	}
	MsgTimer[client] = INVALID_HANDLE;
}

public GameisOver()
{
	for(new i = 0; i < MAXPLAYERS; i ++)
	{
		playercard[i]=0;
		dealer[i]=0;
		pass[i]=false;
		passblock[i]=false;
		dilerpass[i]=false;
		hpblock[i]=false;
	}
}

/*=====================
	$ Conditions $
=======================*/
public PlayingField(client)
{
	if (playercard[client] >= 17 && dealer[client] <= 21 && playercard[client] <= 21 && passblock[client]==true)
	{
		if (playercard[client] == dealer[client])
		{
			//CPrintToChat(client, "%s %d:%d - Push! lol", FC, playercard[client], dealer[client]);
			EmitSoundToClient(client, Push);
			GetBackMyHp(client);
			GameisOver();
		}
		else if (playercard[client] < dealer[client])
		{
			CPrintToChatAll( "%s %d:%d - {blue}%N{default} is {olive}LOSE {default}:P", FC, playercard[client],dealer[client], client);
			EmitSoundToClient(client, Lose);
			GameisOver();
		}
		else if (playercard[client] > dealer[client])
		{
			//CPrintToChatAll( "%s %d:%d - {blue}%N{default} is {green}WIN!", FC, playercard[client], dealer[client], client);
			EmitSoundToClient(client, Win);
			GetBackMyHp(client);
			GameisOver();
		}
	}
	else if (playercard[client] >= 17 && dealer[client] <= 21 && playercard[client] <= 20 && passblock[client]==false)
	{
		CPrintToChat(client, "%s %d:%d - take more? ;) !pass or !bj", FC, playercard[client], dealer[client]);
	}
	else if (playercard[client] > 21 || dealer[client] > 21)
	{
		if (playercard[client] > 21)
		{
			CPrintToChatAll( "%s %d Bust! - {blue}%N{default} is {olive}LOSE {default}:P", FC, playercard[client], client);
			EmitSoundToClient(client, Lose);
			GameisOver();
		}
		else
		{
			//CPrintToChatAll( "%s %d:%d - {blue}%N{default} is {green}WIN!", FC, playercard[client], dealer[client], client);
			EmitSoundToClient(client, Win);
			GetBackMyHp(client);
			GameisOver();
		}
	}
	else if (playercard[client] <= 21)
	{
		if (playercard[client] <= 16 && dealer[client] <= 21)
		{
			CPrintToChat(client, "%s %d - You, %d - Dealer.", FC, playercard[client], dealer[client]);
		}
		else if (playercard[client] == dealer[client] && playercard[client] == 21)
		{
			//CPrintToChat(client, "%s %d:%d - Push! lol", FC, playercard[client], dealer[client]);
			EmitSoundToClient(client, Push);
			GetBackMyHp(client);
			GameisOver();
		}
		else if (playercard[client] == 21 && dealer[client]!=21)
		{
			//CPrintToChatAll( "%s %d:%d - WoW {blue}%N{default} a {green}CHAMPION!", FC, playercard[client], dealer[client], client);
			EmitSoundToClient(client, Win);
			GetBackMyHp(client);
			GameisOver();
		} 
	}
}

public GetBackMyHp(client)
{
	PlayerHp=GetClientHealth(client);
	
	if (playercard[client] == 21 && playercard[client]!= dealer[client])
	{
		new CanGiveHp=HpLimit-Value*3;
		Hp=PlayerHp+Value*3;
		
		if (PlayerHp <= CanGiveHp)
		{
			SetEntProp(client, Prop_Send, "m_iHealth", Hp);
			CPrintToChatAll( "%s %d:%d - WoW {blue}%N{default} a {green}CHAMPION! +%dhp", FC, playercard[client], dealer[client], client, Value*3);
		}
		else 
		{
			SetEntProp(client, Prop_Send, "m_iHealth", HpLimit);
			CPrintToChatAll( "%s %d:%d - WoW {blue}%N{default} a {green}CHAMPION! +%dhp", FC, playercard[client], dealer[client], client, HpLimit-PlayerHp);
		}
	}
	if (playercard[client] == dealer[client])
	{
		new CanGiveHp=HpLimit-Value;
		Hp=PlayerHp+Value;
		
		if (PlayerHp <= CanGiveHp)
		{
			SetEntProp(client, Prop_Send, "m_iHealth", Hp);
			CPrintToChat(client, "%s %d:%d - Push! lol {green}+%dhp", FC, playercard[client], dealer[client], Value);
		}
		else 
		{
			SetEntProp(client, Prop_Send, "m_iHealth", HpLimit);
			CPrintToChat(client, "%s %d:%d - Push! lol {green}+%dhp", FC, playercard[client], dealer[client], HpLimit-PlayerHp);
		}
	}
	else if (playercard[client] != 21)
	{
		new CanGiveHp=HpLimit-Value*2;
		Hp=PlayerHp+Value*2;

		
		if (PlayerHp <= CanGiveHp)
		{
			SetEntProp(client, Prop_Send, "m_iHealth", Hp);
			CPrintToChatAll( "%s %d:%d - {blue}%N{default} is {green}WIN! +%dhp", FC, playercard[client], dealer[client], client, Value*2);
		}
		else  
		{
			SetEntProp(client, Prop_Send, "m_iHealth", HpLimit); 
			CPrintToChatAll( "%s %d:%d - {blue}%N{default} is {green}WIN! +%dhp", FC, playercard[client], dealer[client], client, HpLimit-PlayerHp);
		}
	}
}




/*=====================
		$ Cvar $
=======================*/
public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}

public OnConfigsExecuted()
{
	GetCVars();
}

public GetCVars()
{
	Value=GetConVarInt(g_BJbet);
	HpLimit=GetConVarInt(g_HpLimit);
}