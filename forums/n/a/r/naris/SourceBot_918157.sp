#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"2.7.1"

//Client Vars:
static Relation[129];
static RelationUp[129];
static Greeted[129];
static ApologyFilter[129];

//Entity Vars:
new g_ExplosionSprite;

//Bot Vars:
static bool:Respawn;
static IsBot;
static BotHolder;
static BotWait;
static WatchingChat;
static HeldBy;
static ChatTimeOut;
static ChatTarget;
static Typing;
static Stopped;
static LastGreet;
static Paused;
static SayPhrase;
static Leaving;
static TurnDir;
static Health;
static Dead;
static Following;
static Learning;
static String:SayMess[255];

//Data Vars:
static String:BotName[32];
static Float:BotSpeed;
static FloatHeight;
static String:BotModel[255];

//Databanks:
static String:DataPath[128];
static String:MemoryPath[128];
static String:ConfigPath[128];
static String:CustomPath[128];

public Plugin:myinfo = 
{
    name = "SourceBot",
    author = "Alm",
    description = "Enables a dynamic bot in your hl2dm server.",
    version = PLUGIN_VERSION,
    url = "http://www.loners-gaming.com/ && http://www.iwuclan.com/"
};

public OnPluginStart()
{
	RegAdminCmd("sb_spawn", MakeClient, ADMFLAG_CHEATS, "Spawns the bot.");
	RegAdminCmd("sb_kill", KillClient, ADMFLAG_CHEATS, "Kills the bot.");
	RegAdminCmd("sb_pause", PauseClient, ADMFLAG_CHEATS, "Pauses the bot.");
	RegAdminCmd("sb_unpause", UnpauseClient, ADMFLAG_CHEATS, "Unpauses the bot.");
	RegAdminCmd("sb_say", SayClient, ADMFLAG_CHEATS, "<Message> Makes the boy say a message.");
	RegAdminCmd("sb_tele", TeleClient, ADMFLAG_CHEATS, "Teleports the bot.");
	RegAdminCmd("sb_learn", LearnClient, ADMFLAG_CHEATS, "<Message> Makes the bot learn a message.");

	RegAdminCmd("sb_speed", SpeedClient, ADMFLAG_ROOT, "<1-5> Sets the bot speed.");
	RegAdminCmd("sb_wipe", WipeClient, ADMFLAG_ROOT, "Wipes the bot memory.");
	RegAdminCmd("sb_rate", RateClient, ADMFLAG_ROOT, "<Slow/Normal/Fast> Sets the bot learning pace.");
	RegAdminCmd("sb_timer", TimeClient, ADMFLAG_ROOT, "<Seconds> Sets the second that the bot waits before talking when it feels lonely.");

	HookEntityOutput("prop_physics", "OnHealthChanged", BotTookDamage);
	HookEntityOutput("prop_physics", "OnPhysGunOnlyPickup", BotPickUp);
	HookEntityOutput("prop_physics", "OnPhysGunDrop", BotDrop);
	RegConsoleCmd("say", HandleSay);
	RegConsoleCmd("sourcebot", InfoDisplay);

	HookEvent("round_start", RoundStart);
	HookEvent("teamplay_round_start", RoundStart);
	HookEvent("teamplay_round_active", RoundStart);
	HookEvent("teamplay_setup_finished", RoundStart);

	HookEvent("round_end", RoundEnd);
	HookEvent("teamplay_round_win", RoundEnd);
	HookEvent("teamplay_round_stalemate", RoundEnd);
	HookEvent("teamplay_win_panel", RoundEnd);
	HookEvent("teamplay_broadcast_audio", RoundEnd);

	CreateConVar("sourcebot_version", PLUGIN_VERSION, "SourceBot version.", FCVAR_PLUGIN|FCVAR_NOTIFY);

	BotSpeed = 0.0;
	Learning = 30;
	BotWait = 60;
	Respawn = false;
}

public Action:RoundStart(Handle:Event, const String:Name[], bool:Broadcast)
{
	if(Respawn && (IsBot == -1 || !IsValidEntity(IsBot)))
	{
#if 1
		MakeClient(0, 0);
#else
		decl Bot;
		Bot = CreateEntityByName("prop_physics_override");

		DispatchKeyValue(Bot, "physdamagescale", "1.0");

		//DispatchKeyValue(Bot, "model", BotModel);
		SetEntityModel(Bot,BotModel);
	
		DispatchSpawn(Bot);

		IsBot = Bot;

		Health = 100;
		Dead = 0;

		CreateTimer(0.1, LifeTick, Bot);
		CreateTimer(1.0, SecondTimer, Bot);

		SpawnBot(Bot);

		Respawn = false;
#endif
	}
}

public Action:RoundEnd(Handle:Event, const String:Name[], bool:Broadcast)
{
	if(IsBot != -1)
	{
		if(IsValidEdict(IsBot) || IsValidEntity(IsBot))
		{
			AcceptEntityInput(IsBot, "kill", -1);
		}

		IsBot = -1;

		HeldBy = -1;

		Dead = 1;
	
		Following = -1;

		Typing = 0;

		Respawn = true;
	}
}

public BotPickUp(const String:output[], Bot, Player, Float:delay)
{
	if(IsBot == -1)
	{
		return;
	}

	if(Bot != IsBot)
	{
		return;
	}

	HeldBy = Player;
}

public BotDrop(const String:output[], Bot, Player, Float:delay)
{
	if(IsBot == -1)
	{
		return;
	}

	if(Bot != IsBot)
	{
		return;
	}

	HeldBy = -1;
}

public Action:TimeClient(Client, Args)
{
	if(Args == 0)
	{
		PrintToConsole(Client, "[SB] The bot is set to wait %d seconds before talking when lonely.", BotWait);
		return Plugin_Handled;
	}

	decl String:Value[32];
	GetCmdArg(1, Value, 32);
	decl Time;
	Time = StringToInt(Value);

	if(Time < 10)
	{
		PrintToConsole(Client, "[SB] Error: Wait time too low.");
		return Plugin_Handled;
	}

	if(Time > 1800)
	{
		PrintToConsole(Client, "[SB] Error: Wait time too high.");
		return Plugin_Handled;
	}

	BotWait = Time;

	PrintToConsole(Client, "[SB] Bot wait time set to %d.", BotWait);
	
	return Plugin_Handled;
}

public Action:LearnClient(Client, Args)
{
	if(Args == 0)
	{
		PrintToConsole(Client, "[SB] Usage: sb_learn <Message>");
		return Plugin_Handled;
	}

	decl String:Message[255];

	GetCmdArgString(Message, 255);
	StripQuotes(Message);
	TrimString(Message);

	LearnPhrase(Message);

	PrintToConsole(Client, "[SB] Sent the message: %s :to the bot memory.", Message);

	return Plugin_Handled;
}

public Action:WipeClient(Client, Args)
{
	decl Handle:Vault;

	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, MemoryPath);

	decl String:Key[32];

	for(new X = 1; X <= 1000; X++)
	{
		IntToString(X, Key, 32);
		KvJumpToKey(Vault, "Phrases", false);
		KvDeleteKey(Vault, Key);
		KvRewind(Vault);
	}

	KvJumpToKey(Vault, "LastPhrase", true);
	KvSetNum(Vault, "Value", 0);
	KvRewind(Vault);

	KeyValuesToFile(Vault, MemoryPath);

	CloseHandle(Vault);

	PrintToConsole(Client, "[SB] Bot memory has been wiped.");

	return Plugin_Handled;
}

public Action:SpeedClient(Client, Args)
{
	if(Args < 1)
	{
		PrintToConsole(Client, "[SB] Current bot speed is %d. (%f)", (RoundFloat(BotSpeed / 75)), BotSpeed);
		return Plugin_Handled;
	}

	decl ChosenSpeed;
	decl String:TempString[32];

	GetCmdArgString(TempString, 32);

	StripQuotes(TempString);
	TrimString(TempString);

	ChosenSpeed = StringToInt(TempString);

	if(ChosenSpeed != 1 && ChosenSpeed != 2 && ChosenSpeed != 3 && ChosenSpeed != 4 && ChosenSpeed != 5)
	{
		PrintToConsole(Client, "[SB] Error: Please only choose a number from 1-5.");
		return Plugin_Handled;
	}

	if(ChosenSpeed == 1)
	{
		BotSpeed = 75.0;
	}
	if(ChosenSpeed == 2)
	{
		BotSpeed = 150.0;
	}
	if(ChosenSpeed == 3)
	{
		BotSpeed = 225.0;
	}
	if(ChosenSpeed == 4)
	{
		BotSpeed = 300.0;
	}
	if(ChosenSpeed == 5)
	{
		BotSpeed = 375.0;
	}

	PrintToConsole(Client, "[SB] Bot speed set to %d. (%f)", ChosenSpeed, BotSpeed);

	return Plugin_Handled;
}

public Action:RateClient(Client, Args)
{
	if(Args < 1)
	{
		decl String:Rate[32];
		
		if(Learning == 10)
		{
			Rate = "Fast";
		}
		if(Learning == 30)
		{
			Rate = "Normal";
		}
		if(Learning == 50)
		{
			Rate = "Slow";
		}

		PrintToConsole(Client, "[SB] Current bot learning rate is %s.", Rate);
		return Plugin_Handled;
	}

	decl String:TempString[32];

	GetCmdArgString(TempString, 32);

	StripQuotes(TempString);
	TrimString(TempString);

	if(!StrEqual(TempString, "fast", false) && !StrEqual(TempString, "normal", false) && !StrEqual(TempString, "slow", false))
	{
		PrintToConsole(Client, "[SB] Error: Please choose a rate. <Slow/Normal/Fast>");
		return Plugin_Handled;
	}

	if(StrEqual(TempString, "slow", false))
	{
		Learning = 50;
	}

	if(StrEqual(TempString, "normal", false))
	{
		Learning = 30;
	}

	if(StrEqual(TempString, "fast", false))
	{
		Learning = 10;
	}

	PrintToConsole(Client, "[SB] Bot learning rate set to %s.", TempString);

	return Plugin_Handled;
}

public Action:InfoDisplay(Client, Args)
{
	if(Client == 0)
	{
		return Plugin_Handled;
	}

	PrintToChat(Client, "[SB] Please press <ESCAPE>");
	
	decl Handle:Panel;

	Panel = CreatePanel();

	DrawPanelItem(Panel, "Bot Help");
	DrawPanelItem(Panel, "Bot Status");
	DrawPanelItem(Panel, "Plugin Info");
 
	SendPanelToClient(Panel, Client, ChooseTopic, 30);

	CloseHandle(Panel);

	return Plugin_Handled;
}

public ChooseTopic(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{
	if(HandleAction == MenuAction_Select)
	{
		if(Parameter == 1)
		{
			PrintToChat(Client, "[SB] A SourceBot is a basic AI which will interact with you.");
			PrintToChat(Client, "[SB] To talk to the bot, type its name first, then wait until it responds.");
			PrintToChat(Client, "[SB] The bot won't respond if it's 'typing', or it's already talking to another player.");
			PrintToChat(Client, "[SB] It also helps if you use good english when speaking to it. Don't use many contractions.");
			return;
		}
		if(Parameter == 2)
		{
			if(IsBot == -1)
			{
				PrintToChat(Client, "[SB] The bot is not playing right now.");
				return;
			}
			if(Paused == 1)
			{
				PrintToChat(Client, "[SB] Bot Name: %s | Bot Status: Paused", BotName);
				return;
			}
			PrintToChat(Client, "[SB] Bot Name: %s | Bot Status: Active", BotName);
			return;
		}
		if(Parameter == 3)
		{
			PrintToChat(Client, "[SB] Plugin Author: Alm | Version: %s", PLUGIN_VERSION);
			return;
		}
	}
	return;
}

public SpawnBot(Client)
{
	decl Float:SpawnOrg[30][3];
	decl String:ClassName[32];

	new  GotSpawn = 0;
	new  MaxEntites = GetMaxEntities();
	for(new x = 0; x <= MaxEntites; x++)
	{
		if(GotSpawn < 30 && IsValidEdict(x) && IsValidEntity(x))
		{
			GetEdictClassname(x, ClassName, 32);
			if(StrContains(ClassName, "info_observer_point", false) != -1 ||
			   StrContains(ClassName, "item_ammopack", false) != -1 ||
			   StrContains(ClassName, "item_healthkit", false) != -1 ||
			   StrContains(ClassName, "item_teamflag", false) != -1 ||
			   StrContains(ClassName, "team_control_point", false) != -1)
			{
				GetEntPropVector(x, Prop_Send, "m_vecOrigin", SpawnOrg[GotSpawn]);
				GotSpawn += 1;
			}
		}
	}

	if(GotSpawn == 0)
	{
		for(new x = 0; x <= MaxEntites; x++)
		{
			if(GotSpawn < 30 && IsValidEdict(x) && IsValidEntity(x))
			{
				GetEdictClassname(x, ClassName, 32);
				if(StrContains(ClassName, "info_player_", false) != -1)
				{
					GetEntPropVector(x, Prop_Send, "m_vecOrigin", SpawnOrg[GotSpawn]);
					GotSpawn += 1;
				}
			}
		}
	}

	if(GotSpawn == 0)
	{
		LogError("[SB] Error: No locations to spawn the bot at.");
		return;
	}

	decl Random;
	Random = GetRandomInt(0, GotSpawn - 1);

	SpawnOrg[Random][2] += 50.0

	TeleportEntity(Client, SpawnOrg[Random], NULL_VECTOR, NULL_VECTOR);

	return;
}

public Action:TeleClient(Client, Args)
{
	if(Client == 0)
	{
		PrintToConsole(Client, "[SB] Error: You must be in-game.");
		return Plugin_Handled;
	}

	if(Dead == 1)
	{
		PrintToConsole(Client, "[SB] Please wait a second for the bot to spawn.");
		return Plugin_Handled;
	}

	if(IsBot == -1)
	{
		PrintToConsole(Client, "[SB] The bot isn't playing.");
		return Plugin_Handled;
	}

	if(Paused == 1)
	{
		PrintToConsole(Client, "[SB] The bot is paused.");
		return Plugin_Handled;
	}

	decl Float:Location[3];
	decl Float:EyeAngles[3];
	decl Float:ClientOrigin[3];

	GetClientAbsOrigin(Client, ClientOrigin);
	GetClientEyeAngles(Client, EyeAngles);

	Location[0] = (ClientOrigin[0] + (50 * Cosine(DegToRad(EyeAngles[1]))));
	Location[1] = (ClientOrigin[1] + (50 * Sine(DegToRad(EyeAngles[1]))));
	Location[2] = (ClientOrigin[2] + 50);

	TeleportEntity(IsBot, Location, NULL_VECTOR, NULL_VECTOR);

	PrintToConsole(Client, "[SB] Teleported the bot.");

	Typing = 1;
	CreateTimer(1.0, TeleportedBot, IsBot);

	return Plugin_Handled;
}

public Action:TeleportedBot(Handle:Timer, any:Client)
{
	RandomChat("Teleported", 5);

	Typing = 0;
}

public OnClientPutInServer(Client)
{
	PrintToChat(Client, "[SB] This server is running a SourceBot.");
	PrintToChat(Client, "[SB] Type !sourcebot for more info.");
	Greeted[Client] = 0;
	ApologyFilter[Client] = 60;
	Relation[Client] = 50;
	RelationUp[Client] = 60;
	LoadRelation(Client);

	if(Relation[Client] < 20)
	{
		Greeted[Client] = 1;
	}
}

public LoadRelation(Client)
{
	decl String:LoadBuffer[32];
	GetClientAuthString(Client, LoadBuffer, 32);

	decl Handle:Vault;

	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, MemoryPath);

	KvJumpToKey(Vault, "Relation", true);

	Relation[Client] = KvGetNum(Vault, LoadBuffer, 50);

	KvRewind(Vault);
	CloseHandle(Vault);

	return;
}

public SaveRelation(Client)
{
	decl String:SaveBuffer[32];
	GetClientAuthString(Client, SaveBuffer, 32);

	decl Handle:Vault;

	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, MemoryPath);

	KvJumpToKey(Vault, "Relation", true);

	KvSetNum(Vault, SaveBuffer, Relation[Client]);

	KvRewind(Vault);

	KeyValuesToFile(Vault, MemoryPath);

	CloseHandle(Vault);

	return;
}

public Action:SayClient(Client, Args)
{
	if(Args == 0)
	{
		PrintToConsole(Client, "[SB] Usage: sb_say <Message>");
		return Plugin_Handled;
	}

	if(IsBot == -1)
	{
		PrintToConsole(Client, "[SB] The bot isn't playing.");
		return Plugin_Handled;
	}

	if(Paused == 1)
	{
		PrintToConsole(Client, "[SB] The bot is paused.");
		return Plugin_Handled;
	}

	decl String:Message[255];
	GetCmdArgString(Message, 255);

	StripQuotes(Message);
	TrimString(Message);

	PrintToChatAll("\x01\x04%s\x01 :  %s", BotName, Message);
	PrintToServer("%s :  %s", BotName, Message);

	return Plugin_Handled;
}

public OnClientDisconnect(Client)
{
	if(Client == WatchingChat)
	{
		WatchingChat = -1;
		ChatTimeOut = 0;
	}

	if(Client == HeldBy)
	{
		HeldBy = -1;
	}

	if(Client == Following)
	{
		Following = -1;
	}
}

public OnMapStart()
{
	WatchingChat = -1;
	ChatTimeOut = 0;
	Typing = 0;
	Stopped = 0;
	HeldBy = -1;
	SayPhrase = BotWait;
	BotHolder = -1;
	Following = -1;
	LastGreet = 0;
	ChatTarget = -1;
	IsBot = -1;
	Paused = 0;
	BotName = "Null";
	Leaving = 0;
	Health = -1;
	Dead = 0;
	Respawn = false;
	SayMess = "null";
	TurnDir = -1;
	for(new x = 1; x < 129; x++)
	{
		Greeted[x] = 0;
		ApologyFilter[x] = 60;
	}
	for(new q = 1; q < 129; q++)
	{
		Relation[q] = 50;
		RelationUp[q] = 60;
	}

	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	PrecacheSound("ambient/explosions/explode_4.wav", false);

	BuildPath(Path_SM, DataPath, 128, "data/sourcebot/bot_responses.txt");
	if(!FileExists(DataPath))
	{
		SetFailState("Missing needed file...");
	}

	BuildPath(Path_SM, MemoryPath, 128, "data/sourcebot/bot_memory.txt");
	if(!FileExists(MemoryPath))
	{
		SetFailState("Missing needed file...");
	}

	BuildPath(Path_SM, ConfigPath, 128, "data/sourcebot/bot_config.txt");
	if(!FileExists(ConfigPath))
	{
		SetFailState("Missing needed file...");
	}

	BuildPath(Path_SM, CustomPath, 128, "data/sourcebot/bot_customresponses.txt");
	if(!FileExists(CustomPath))
	{
		SetFailState("Missing needed file...");
	}

	decl String:Result[5];
	decl Handle:Vault;

	if(BotSpeed < 1)
	{
		Vault = CreateKeyValues("Vault");
		FileToKeyValues(Vault, ConfigPath);

		KvJumpToKey(Vault, "Setup", false);

		KvGetString(Vault, "DefaultSpeed", Result, 5, "$null");

		KvRewind(Vault);
		CloseHandle(Vault);

		if(StrEqual(Result, "$null", false))
		{
			LogError("[SB] Error: No default speed selected.");
		}
		else
		{
			decl ChosenSpeed;
			ChosenSpeed = StringToInt(Result);
			
			if(ChosenSpeed != 1 && ChosenSpeed != 2 && ChosenSpeed != 3 && ChosenSpeed != 4 && ChosenSpeed != 5)
			{
				LogError("[SB] Error: Default speed is set to a number other than 1-5.");
			}
			else
			{
				BotSpeed = (StringToFloat(Result) * 75);
			}
		}
	}

	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, ConfigPath);

	KvJumpToKey(Vault, "Setup", false);

	KvGetString(Vault, "SpawnOnStart", Result, 5, "$null");

	KvRewind(Vault);
	CloseHandle(Vault);

	if(StrEqual(Result, "Yes", false))
	{
		CreateTimer(3.0, StartSpawnBot);
	}
	else
	{
		if(!StrEqual(Result, "No", false))
		{
			LogError("[SB] Error: Please fill out the value of SpawnOnStart, in the bot_config file, as either Yes or No.");
		}
	}

	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, ConfigPath);

	KvJumpToKey(Vault, "Debug", false);

	KvGetString(Vault, "Model", BotModel, 255, "models/combine_scanner.mdl");

	KvRewind(Vault);
	CloseHandle(Vault);

	PrecacheModel(BotModel, true);

	PrintToServer("[SB] Bot model set to %s.", BotModel);

	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, ConfigPath);

	KvJumpToKey(Vault, "Debug", false);

	FloatHeight = KvGetNum(Vault, "FloatHeight", 70);

	KvRewind(Vault);
	CloseHandle(Vault);

	PrintToServer("[SB] Float height set to %d.", FloatHeight);
}

public Action:StartSpawnBot(Handle:Timer)
{
	ServerCommand("sb_spawn");
	return Plugin_Handled;
}

public Action:HandleSay(Client, Args)
{
	decl String:Message[255];
	GetCmdArgString(Message, 255);

	StripQuotes(Message);
	TrimString(Message);

	if(IsBot == -1 || Paused == 1 || Leaving == 1 || Typing == 1)
	{
		return Plugin_Continue;
	}

	if(WatchingChat == Client)
	{
		SayPhrase = BotWait;
		if(IsCustom(Message))
		{
			Typing = 1;
			CreateTimer(2.0, CustomSay, IsBot);
			return Plugin_Continue;
		}
		if(StrEqual(Message, BotName, false))
		{
			Typing = 1;
			CreateTimer(2.0, RespondToName, IsBot);
			return Plugin_Continue;
		}
		if(StrContains(Message, "?", false) != -1)
		{
			if(StrContains(Message, " or ", false) != -1)
			{
				Typing = 1;
				CreateTimer(2.0, AnswerQuestionOr, IsBot);
				return Plugin_Continue;
			}
			if(StrContains(Message, "why", false) != -1)
			{
				Typing = 1;
				CreateTimer(2.0, AnswerQuestionWhy, IsBot);
				return Plugin_Continue;
			}
			if(StrContains(Message, "many", false) != -1)
			{
				Typing = 1;
				CreateTimer(2.0, AnswerQuestionAmount, IsBot);
				return Plugin_Continue;
			}
			if(StrContains(Message, "much", false) != -1)
			{
				if((StrContains(Message, "you", false) != -1 || StrContains(Message, " u ", false) != -1) && (StrContains(Message, "like", false) != -1 || StrContains(Message, "liek", false) != -1) && (StrContains(Message, " me?", false) != -1 || StrContains(Message, " me ", false) != -1))
				{
					Typing = 1;
					CreateTimer(2.0, Relationship, Client);
					return Plugin_Continue;
				}
				Typing = 1;
				CreateTimer(2.0, AnswerQuestionAmount2, IsBot);
				return Plugin_Continue;
			}
			if(StrContains(Message, "long", false) != -1 || StrContains(Message, "big", false) != -1 || StrContains(Message, "small", false) != -1 || StrContains(Message, "large", false) != -1 || StrContains(Message, "tiny", false) != -1)
			{
				if(StrContains(Message, "til", false) != -1)
				{
					Typing = 1;
					CreateTimer(2.0, AnswerQuestionTimeLengthF, IsBot);
					return Plugin_Continue;
				}
				if(StrContains(Message, "ago", false) != -1)
				{
					Typing = 1;
					CreateTimer(2.0, AnswerQuestionTimeLengthP, IsBot);
					return Plugin_Continue;
				}
				Typing = 1;
				CreateTimer(2.0, AnswerQuestionSize, IsBot);
				return Plugin_Continue;
			}
			if(StrContains(Message, "how", false) != -1)
			{
				if(StrContains(Message, "old", false) != -1)
				{
					if(StrContains(Message, "you", false) != -1 || StrContains(Message, " u?", false) != -1 || StrContains(Message, " u ", false) != -1)
					{
						Typing = 1;
						CreateTimer(2.0, AnswerQuestionBotAge, IsBot);
						return Plugin_Continue;
					}
					Typing = 1;
					CreateTimer(2.0, AnswerQuestionGenAge, IsBot);
					return Plugin_Continue;
				}
				if(StrContains(Message, "often", false) != -1)
				{
					Typing = 1;
					CreateTimer(2.0, AnswerQuestionWhenOften, IsBot);
					return Plugin_Continue;
				}
				if((StrContains(Message, "you", false) != -1 || StrContains(Message, " u ", false) != -1) && (StrContains(Message, "like", false) != -1 || StrContains(Message, "liek", false) != -1) && (StrContains(Message, " me?", false) != -1 || StrContains(Message, " me ", false) != -1))
				{
					Typing = 1;
					CreateTimer(2.0, Relationship, Client);
					return Plugin_Continue;
				}
				if(StrContains(Message, "are", false) != -1 || StrContains(Message, " r ", false) != -1)
				{
					if(StrContains(Message, "you", false) != -1 || StrContains(Message, " u?", false) != -1 || StrContains(Message, " u ", false) != -1)
					{
						Typing = 1;
						CreateTimer(2.0, AnswerQuestionBotFeel, IsBot);
						return Plugin_Continue;
					}
				}
				Typing = 1;
				CreateTimer(2.0, AnswerQuestionHow, IsBot);
				return Plugin_Continue;
			}
			if(StrContains(Message, "what", false) != -1 || StrContains(Message, "wtf", false) != -1)
			{
				if((StrContains(Message, "you", false) != -1 || StrContains(Message, " u ", false) != -1) && StrContains(Message, "think", false) != -1 && (StrContains(Message, " me?", false) != -1 || StrContains(Message, " me ", false) != -1))
				{
					Typing = 1;
					CreateTimer(2.0, Relationship, Client);
					return Plugin_Continue;
				}
				
				Typing = 1;
				CreateTimer(2.0, AnswerQuestionWhat, IsBot);
				return Plugin_Continue;
			}
			if(StrContains(Message, "where", false) != -1)
			{
				Typing = 1;
				CreateTimer(2.0, AnswerQuestionWhere, IsBot);
				return Plugin_Continue;
			}
			if(StrContains(Message, "who", false) != -1 || StrContains(Message, "whose", false) != -1)
			{
				Typing = 1;
				CreateTimer(2.0, AnswerQuestionWho, IsBot);
				return Plugin_Continue;
			}
			if(StrContains(Message, "when", false) != -1)
			{
				if(StrContains(Message, "whend", false) != -1 || StrContains(Message, "did", false) != -1 || StrContains(Message, "was", false) != -1)
				{
					Typing = 1;
					CreateTimer(2.0, AnswerQuestionPast, IsBot);
					return Plugin_Continue;
				}
				if(StrContains(Message, "whens", false) != -1 || StrContains(Message, "will", false) != -1 || StrContains(Message, " is ", false) != -1 || StrContains(Message, " are ", false) != -1)
				{
					Typing = 1;
					CreateTimer(2.0, AnswerQuestionFuture, IsBot);
					return Plugin_Continue;
				}
				if(StrContains(Message, " do ", false) != -1)
				{
					Typing = 1;
					CreateTimer(2.0, AnswerQuestionWhenOften, IsBot);
					return Plugin_Continue;
				}
				Typing = 1;
				CreateTimer(2.0, AnswerQuestionWhen, IsBot);
				return Plugin_Continue;
			}
			if(StrContains(Message, "are", false) != -1 || StrContains(Message, "is ", false) != -1)
			{
				Typing = 1;
				CreateTimer(2.0, AnswerQuestionAre, IsBot);
				return Plugin_Continue;
			}
			if(StrContains(Message, "do ", false) != -1 && (StrContains(Message, "you", false) != -1 || StrContains(Message, " u ", false) != -1) && (StrContains(Message, " me?", false) != -1 || StrContains(Message, " me ", false) != -1))
			{
				if(StrContains(Message, "love", false) != -1 || StrContains(Message, "luv", false) != -1 || StrContains(Message, "like", false) != -1 || StrContains(Message, "liek", false) != -1 || StrContains(Message, "hate", false) != -1 || StrContains(Message, "haet", false) != -1)
				{
					Typing = 1;
					CreateTimer(2.0, Relationship, Client);
					return Plugin_Continue;
				}
			}
			Typing = 1;
			CreateTimer(2.0, AnswerQuestionGen, IsBot);
			return Plugin_Continue;
		}
		else
		{
			if(StrContains(Message, "fuck", false) != -1 || StrContains(Message, "shit", false) != -1 || StrContains(Message, "screw", false) != -1 || StrContains(Message, "bitch", false) != -1 || StrContains(Message, "fag", false) != -1 || StrContains(Message, "whore", false) != -1 || StrContains(Message, "ass", false) != -1 || StrContains(Message, "nigg", false) != -1 || StrContains(Message, "suck", false) != -1)
			{
				Typing = 1;
				CreateTimer(2.0, Insulted, Client);
				return Plugin_Continue;
			}
			if(StrEqual(Message, "hi") || StrEqual(Message, "hey") || StrEqual(Message, "yo") || StrEqual(Message, "hello"))
			{
				CreateTimer(2.0, GenGreetChat, IsBot);
				Typing = 1;
				return Plugin_Continue;
			}
			if(StrContains(Message, "bye", false) != -1 || StrContains(Message, "cya", false) != -1 || StrContains(Message, "see ya", false) != -1 || StrContains(Message, "gtg", false) != -1)
			{
				CreateTimer(2.0, LeavingChat, IsBot);
				Typing = 1;
				return Plugin_Continue;
			}
			if(StrEqual(Message, "ty") || StrContains(Message, "thank", false) != -1 || StrContains(Message, "thanx", false) != -1)
			{
				CreateTimer(2.0, ThankChat, IsBot);
				Typing = 1;
				return Plugin_Continue;
			}
			if(StrContains(Message, "sorry", false) != -1 || StrContains(Message, "srry", false) != -1)
			{
				CreateTimer(2.0, ApologyAccept, Client);
				Typing = 1;
				return Plugin_Continue;
			}
			Typing = 1;
			CreateTimer(2.0, AnswerStatement, IsBot);
			return Plugin_Continue;
		}
	}

	if(WatchingChat == -1 && (StrEqual(Message, BotName, false) || (StrContains(Message, BotName, false) != -1 && StrContains(Message, " ", false) == -1)))
	{
		SayPhrase = BotWait;
		if(Relation[Client] < 20 && Client != 0)
		{
			Typing = 1;
			CreateTimer(2.0, NoRespond, IsBot);
			return Plugin_Continue;
		}

		ChatTimeOut = 62;
		WatchingChat = Client;
		Typing = 1;
		CreateTimer(2.0, Respond, IsBot);
		return Plugin_Continue;
	}
	if(WatchingChat == -1 && StrContains(Message, BotName, false) != -1)
	{
		SayPhrase = BotWait;
		if(Relation[Client] < 20 && Client != 0)
		{
			Typing = 1;
			CreateTimer(2.0, NoRespond, IsBot);
			return Plugin_Continue;
		}

		if(StrContains(Message, "fuck", false) != -1 || StrContains(Message, "shit", false) != -1 || StrContains(Message, "screw", false) != -1 || StrContains(Message, "bitch", false) != -1 || StrContains(Message, "fag", false) != -1 || StrContains(Message, "whore", false) != -1 || StrContains(Message, "ass", false) != -1 || StrContains(Message, "nigg", false) != -1 || StrContains(Message, "suck", false) != -1)
		{
			CreateTimer(2.0, Insulted, Client);
			Typing = 1;
			return Plugin_Continue;
		}
		if(StrContains(Message, "hi", false) != -1 || StrContains(Message, "hey", false) != -1 || StrContains(Message, "yo", false) != -1 || StrContains(Message, "hello", false) != -1)
		{
			CreateTimer(2.0, GenGreetChat, IsBot);
			Typing = 1;
			return Plugin_Continue;
		}
		if(StrContains(Message, "bye", false) != -1 || StrContains(Message, "cya", false) != -1 || StrContains(Message, "see ya", false) != -1 || StrContains(Message, "gtg", false) != -1)
		{
			CreateTimer(2.0, LeavingChat, IsBot);
			Typing = 1;
			return Plugin_Continue;
		}
		if((StrContains(Message, "ty ", false) != -1 || StrContains(Message, " ty", false) != -1) || StrContains(Message, "thank", false) != -1 || StrContains(Message, "thanx", false) != -1)
		{
			CreateTimer(2.0, ThankChat, IsBot);
			Typing = 1;
			return Plugin_Continue;
		}
		if(StrContains(Message, "sorry", false) != -1 || StrContains(Message, "srry", false) != -1)
		{
			CreateTimer(2.0, ApologyAccept, Client);
			Typing = 1;
			return Plugin_Continue;
		}
	}

	if(StrContains(Message, BotName, false) == -1 && StrContains(Message, "?", false) == -1 && Message[0] != '/' && !IsPlayerName(Message) && (StrContains(Message, "bye", false) == -1 || StrContains(Message, "cya", false) == -1 || StrContains(Message, "see ya", false) == -1 || StrContains(Message, "gtg", false) == -1))
	{
		decl Prob;
		Prob = GetRandomInt(1, Learning);

		if(Prob == 1)
		{
			LearnPhrase(Message);
		}

		return Plugin_Continue;
	}

	return Plugin_Continue;
}

public Action:CustomSay(Handle:Timer, any:Client)
{
	PrintToChatAll("\x01\x04%s\x01 :  %s", BotName, SayMess);
	PrintToServer("%s :  %s", BotName, SayMess);

	SayMess = "null";

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public IsCustom(const String:Message[255])
{
	decl Handle:Vault;
	Vault = CreateKeyValues("Vault");
	
	decl String:Returned[255];

	FileToKeyValues(Vault, CustomPath);
	KvGetString(Vault, Message, Returned, 255, "null");
	KvRewind(Vault);

	CloseHandle(Vault);

	if(StrEqual(Returned, "null", false))
	{
		return false;
	}
	else
	{
		SayMess = Returned;
	}

	return true;
}

public IsPlayerName(String:Message[255])
{
	decl String:Name[32];

	for(new X = 1; X <= GetMaxClients(); X++)
	{
		if(IsClientConnected(X) && IsClientInGame(X))
		{
			GetClientName(X, Name, 32);

			if(StrEqual(Message, Name, false))
			{
				return true;
			}
		}
	}

	return false;
}

public RandomPhrase()
{
	decl Max;
	Max = GetMaxLearnKeys();

	if(Max == 0)
	{
		return;
	}

	decl String:Message[255];

	decl Random;
	Random = GetRandomInt(1, Max);

	decl String:Key[32];
	IntToString(Random, Key, 32);

	decl Handle:Vault;

	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, MemoryPath);

	KvJumpToKey(Vault, "Phrases", true);

	KvGetString(Vault, Key, Message, 255, "rawr");

	KvRewind(Vault);

	CloseHandle(Vault);

	PrintToChatAll("\x01\x04%s\x01 :  %s", BotName, Message);
	PrintToServer("%s :  %s", BotName, Message);

	return;
}

public PhraseAlreadyIn(String:Phrase[255])
{
	decl String:Key[32];
	decl String:TestPhrase[255];

	decl Handle:TestVault;
	TestVault = CreateKeyValues("Vault");
	FileToKeyValues(TestVault, MemoryPath);

	for(new x = 1; x <= 1000; x++)
	{
		IntToString(x, Key, 32);

		KvJumpToKey(TestVault, "Phrases", true);

		KvGetString(TestVault, Key, TestPhrase, 255, "$null");

		KvRewind(TestVault);

		if(!StrEqual(TestPhrase, "$null"))
		{
			if(StrEqual(Phrase, TestPhrase, false))
			{
				return true;
			}
		}
	}

	CloseHandle(TestVault);

	return false;
}

public LearnPhrase(String:Phrase[255])
{
	if(PhraseAlreadyIn(Phrase))
	{
		return;
	}

	decl Number;
	Number = GetNextLearnKey();

	decl String:Key[32];
	IntToString(Number, Key, 32);

	decl Handle:Vault;

	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, MemoryPath);

	KvJumpToKey(Vault, "Phrases", true);

	KvSetString(Vault, Key, Phrase);

	KvRewind(Vault);

	KvJumpToKey(Vault, "LastPhrase", true);

	KvSetNum(Vault, "Value", Number);

	KvRewind(Vault);

	KeyValuesToFile(Vault, MemoryPath);

	CloseHandle(Vault);

	return;
}

public GetNextLearnKey()
{
	decl Handle:TestVault;
	decl Value;
	TestVault = CreateKeyValues("Vault");
	FileToKeyValues(TestVault, MemoryPath);

	KvJumpToKey(TestVault, "LastPhrase", true);

	Value = KvGetNum(TestVault, "Value", 0);

	KvRewind(TestVault);

	if(Value == 1000)
	{
		Value = 1;
	}
	else
	{
		Value += 1;
	}

	CloseHandle(TestVault);

	return Value;
}

public GetMaxLearnKeys()
{
	decl Handle:TestVault;
	decl String:Tester[255];
	decl String:Key[32];
	decl Count;
	Count = 0;
	TestVault = CreateKeyValues("Vault");
	FileToKeyValues(TestVault, MemoryPath);

	for(new x = 1; x <= 1000; x++)
	{
		IntToString(x, Key, 32);

		KvJumpToKey(TestVault, "Phrases", true);

		KvGetString(TestVault, Key, Tester, 255, "$null");

		KvRewind(TestVault);

		if(!StrEqual(Tester, "$null"))
		{
			Count += 1;
		}
	}

	CloseHandle(TestVault);

	return Count;
}

public GetMaxEntries(String:Category[32], MaxSearch)
{
	decl Handle:TestVault;
	decl String:Tester[255];
	decl String:Key[32];
	decl Count;
	Count = 0;
	TestVault = CreateKeyValues("Vault");
	FileToKeyValues(TestVault, DataPath);

	for(new x = 1; x <= MaxSearch; x++)
	{
		IntToString(x, Key, 32);

		KvJumpToKey(TestVault, Category, false);

		KvGetString(TestVault, Key, Tester, 255, "$null");

		KvRewind(TestVault);

		if(!StrEqual(Tester, "$null"))
		{
			Count += 1;
		}
	}

	CloseHandle(TestVault);

	return Count;
}

public RandomChat(String:Category[32], MaxRandom)
{
	if(Dead == 1)
	{
		return;
	}

	decl Handle:Vault;
	decl String:Message[255];
	decl String:Key[32];
	decl TestNumber;
	decl NewMax;
	NewMax = GetMaxEntries(Category, MaxRandom);

	if(NewMax == 0)
	{
		PrintToChatAll("\x01\x04%s\x01 :  Error in databank..conversational file missing", BotName);
		LogError("%s :  Error in databank..conversational file missing (Category: %s)", BotName, Category);
		return;
	}

	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, DataPath);

	TestNumber = GetRandomInt(1, NewMax);
	IntToString(TestNumber, Key, 32);

	KvJumpToKey(Vault, Category, false);

	KvGetString(Vault, Key, Message, 255, "$null");

	KvRewind(Vault);
	CloseHandle(Vault);

	if(StrEqual(Message, "$null"))
	{
		PrintToChatAll("\x01\x04%s\x01 :  Error in databank..conversational file missing", BotName);
		LogError("%s :  Error in databank..conversational file missing (Category: %s)(Response: %d)", BotName, Category, TestNumber);
		return;
	}

	PrintToChatAll("\x01\x04%s\x01 :  %s", BotName, Message);
	PrintToServer("%s :  %s", BotName, Message);

	return;
}

public Action:NoRespond(Handle:Timer, any:Client)
{
	RandomChat("No_Respond", 10);

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:RespondToName(Handle:Timer, any:Client)
{
	RandomChat("Said_Name", 5);

	ChatTimeOut = 62;
	Typing = 0;
}

public Action:Relationship(Handle:Timer, any:Client)
{
	if(Client != 0)
	{
		decl Amount;
		Amount = Relation[Client];

		if(Amount >= 0 && Amount <= 30)
		{
			PrintToChatAll("\x01\x04%s\x01 :  i hate you!", BotName);
			PrintToServer("%s :  i hate you!", BotName);
		}
		if(Amount > 30 && Amount < 50)
		{
			PrintToChatAll("\x01\x04%s\x01 :  i dont like you", BotName);
			PrintToServer("%s :  i dont like you", BotName);
		}
		if(Amount >= 50 && Amount < 70)
		{
			PrintToChatAll("\x01\x04%s\x01 :  you are ok", BotName);
			PrintToServer("%s :  you are ok", BotName);
		}
		if(Amount >= 70 && Amount < 90)
		{
			PrintToChatAll("\x01\x04%s\x01 :  i like you", BotName);
			PrintToServer("%s :  i like you", BotName);
		}
		if(Amount >= 90 && Amount <= 100)
		{
			PrintToChatAll("\x01\x04%s\x01 :  i really like you!", BotName);
			PrintToServer("%s :  i really like you!", BotName);
		}
	}
	else
	{
		PrintToChatAll("\x01\x04%s\x01 :  i dont even know who you are console!", BotName);
		PrintToServer("%s :  i dont even know who you are console!", BotName);
	}

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:ThankChat(Handle:Timer, any:Client)
{
	RandomChat("Thanking", 10);

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:ApologyAccept(Handle:Timer, any:Client)
{
	RandomChat("Apology_Accept", 5);

	if(Client != 0)
	{
		if(ApologyFilter[Client] == 0)
		{
			if(Relation[Client] < 97)
			{
				Relation[Client] += 3;
			}
			else
			{
				Relation[Client] = 100;
			}
		}
		SaveRelation(Client);
	}

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:LeavingChat(Handle:Timer, any:Client)
{
	RandomChat("Leaving_Server", 10);

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:Insulted(Handle:Timer, any:Client)
{
	RandomChat("Insulted", 10);

	if(Client != 0)
	{
		if(Relation[Client] > 5)
		{
			Relation[Client] -= 5;
		}
		else
		{
			Relation[Client] = 0;
		}
		SaveRelation(Client);
	}

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:Respond(Handle:Timer, any:Client)
{
	RandomChat("Respond_To_Player", 5);
	
	Typing = 0;
}

public Action:AnswerQuestionBotFeel(Handle:Timer, any:Client)
{
	RandomChat("Bot_Feelings", 20);

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionTimeLengthP(Handle:Timer, any:Client)
{
	RandomChat("Time_Length_Past", 10);	

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionTimeLengthF(Handle:Timer, any:Client)
{
	RandomChat("Time_Length_Future", 10);	

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionSize(Handle:Timer, any:Client)
{
	RandomChat("Size", 20);	

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionAmount(Handle:Timer, any:Client)
{
	decl Random;
	Random = GetRandomInt(1, 20);

	if(Random < 15)
	{
		RandomChat("Amount", 14);
	}
	if(Random > 14)
	{
		decl Random2;
		Random2 = GetRandomInt(1,100);
		PrintToChatAll("\x01\x04%s\x01 :  %d, i think", BotName, Random2);
		PrintToServer("%s :  %d, i think", BotName, Random2);
	}
	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionAmount2(Handle:Timer, any:Client)
{
	RandomChat("Amount", 14);
	
	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionHow(Handle:Timer, any:Client)
{
	RandomChat("How", 20);

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionBotAge(Handle:Timer, any:Client)
{
	decl String:TestString[32];
	decl Age;
	decl Handle:Vault;

	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, ConfigPath);

	KvJumpToKey(Vault, "Personal", false);

	KvGetString(Vault, "Age", TestString, 32, "3");

	KvRewind(Vault);
	CloseHandle(Vault);

	Age = StringToInt(TestString);

	if(Age > 1)
	{
		PrintToChatAll("\x01\x04%s\x01 :  I am %d years old.", BotName, Age);
		PrintToServer("%s :  I am %d years old.", BotName, Age);
	}
	if(Age == 1)
	{
		PrintToChatAll("\x01\x04%s\x01 :  I am 1 year old.", BotName);
		PrintToServer("%s :  I am 1 year old.", BotName);
	}
	if(Age < 1)
	{
		PrintToChatAll("\x01\x04%s\x01 :  I do not exist.", BotName);
		PrintToServer("%s :  I do not exist.", BotName);
	}
	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionGenAge(Handle:Timer, any:Client)
{
	decl Random;
	Random = GetRandomInt(4,40);
	PrintToChatAll("\x01\x04%s\x01 :  I think %d years old.", BotName, Random);
	PrintToServer("%s :  I think %d years old.", BotName, Random);
	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionAre(Handle:Timer, any:Client)
{
	RandomChat("Are_You...?", 20);

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionWhat(Handle:Timer, any:Client)
{
	RandomChat("What", 20);

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionWhy(Handle:Timer, any:Client)
{
	RandomChat("Why", 20);

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionWhere(Handle:Timer, any:Client)
{
	RandomChat("Where", 20);

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionWho(Handle:Timer, any:Client)
{
	decl Random;
	Random = GetRandomInt(1, 20);

	if(Random < 6)
	{
		RandomChat("Who", 5);
	}
	if(Random > 5 && Random < 14)
	{
		decl RandCl;
		RandCl = GetRandomClient();

		if(RandCl != -1)
		{
			if(RandCl == WatchingChat)
			{
				PrintToChatAll("\x01\x04%s\x01 :  oh, I think thats you", BotName);
				PrintToServer("%s :  oh, I think thats you", BotName);
			}
			else
			{
				decl String:RandName[32];
				GetClientName(RandCl, RandName, 32);
				PrintToChatAll("\x01\x04%s\x01 :  oh, I think thats %s", BotName, RandName);
				PrintToServer("%s :  oh, I think thats %s", BotName, RandName);
			}
		}
		if(RandCl == -1)
		{
			PrintToChatAll("\x01\x04%s\x01 :  oh, I think thats me", BotName);
			PrintToServer("%s :  oh I think thats me", BotName);
		}
	}
	if(Random > 13)
	{
		decl RandCl;
		RandCl = GetRandomClient();

		if(RandCl != -1)
		{
			if(RandCl == WatchingChat)
			{
				PrintToChatAll("\x01\x04%s\x01 :  isnt that you?", BotName);
				PrintToServer("%s :  isnt that you?", BotName);
			}
			else
			{
				decl String:RandName[32];
				GetClientName(RandCl, RandName, 32);
				PrintToChatAll("\x01\x04%s\x01 :  isnt that %s?", BotName, RandName);
				PrintToServer("%s :  isnt that %s?", BotName, RandName);
			}
		}
		if(RandCl == -1)
		{
			PrintToChatAll("\x01\x04%s\x01 :  isnt that me?", BotName);
			PrintToServer("%s :  isnt that me?", BotName);
		}
	}
	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionGen(Handle:Timer, any:Client)
{
	RandomChat("General_Question", 8);

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionWhen(Handle:Timer, any:Client)
{
	RandomChat("When_General", 20);

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionPast(Handle:Timer, any:Client)
{
	RandomChat("When_Past", 10);

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionFuture(Handle:Timer, any:Client)
{
	RandomChat("When_Future", 10);

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionWhenOften(Handle:Timer, any:Client)
{
	RandomChat("When_Often", 10);
	
	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:AnswerQuestionOr(Handle:Timer, any:Client)
{
	RandomChat("Either_Or", 10);
	
	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public GetRandomClient()
{
	decl AllPlayers;
	decl Round;
	Round = 0;
	AllPlayers = AlivePlayers();

	decl Result;
	Result = -1;

	if(AllPlayers == 0)
	{
		return Result;
	}

	decl Choice[AllPlayers];

	decl MaxPlayers;
	MaxPlayers = GetMaxClients();

	for(new X = 1; X <= MaxPlayers; X++)
	{
		if(IsClientConnected(X) && IsClientInGame(X))
		{
			Choice[Round] = X;
			Round += 1;
		}
	}

	decl MaxSpin;
	MaxSpin = AllPlayers - 1;

	decl Random;
	Random = GetRandomInt(0,MaxSpin);

	Result = Choice[Random];

	return Result;
}

public Action:AnswerStatement(Handle:Timer, any:Client)
{
	RandomChat("Statement_Response", 50);

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:GreetPlayer(Handle:Timer, any:Client)
{
	if(Dead == 1)
	{
		return Plugin_Handled;
	}

	if(ChatTarget == -1)
	{
		Typing = 0;
		return Plugin_Handled;
	}

	decl Random;
	Random = GetRandomInt(1,4);

	decl String:TargetName[32];
	GetClientName(ChatTarget, TargetName, 32);

	decl Ply;

	Ply = ChatTarget;

	ChatTarget = -1;

	if(IsClientConnected(Ply) && IsClientInGame(Ply))
	{

	if(Random == 1)
	{
		PrintToChatAll("\x01\x04%s\x01 :  Hey %s!", BotName, TargetName);
		PrintToServer("%s :  Hey %s!", BotName, TargetName);
	}
	if(Random == 2)
	{
		PrintToChatAll("\x01\x04%s\x01 :  Oh hey %s.", BotName, TargetName);
		PrintToServer("%s :  Oh hey %s.", BotName, TargetName);
	}
	if(Random == 3)
	{
		PrintToChatAll("\x01\x04%s\x01 :  %s, hey!", BotName, TargetName);
		PrintToServer("%s :  %s, hey!", BotName, TargetName);
	}
	if(Random == 4)
	{
		PrintToChatAll("\x01\x04%s\x01 :  Hey, it's %s!", BotName, TargetName);
		PrintToServer("%s :  Hey, it's %s!", BotName, TargetName);
	}
	}

	Ply = -1;

	Typing = 0;
	return Plugin_Handled;
}

public Action:SecondTimer(Handle:Timer, any:Client)
{
	if(IsBot != Client)
	{
		return Plugin_Handled;
	}

	if(Leaving == 1)
	{
		return Plugin_Handled;
	}

	if(Paused == 1)
	{
		CreateTimer(1.0, SecondTimer, Client);
		return Plugin_Handled;
	}

	for(new X = 1; X <= GetMaxClients(); X++)
	{
		if(IsClientConnected(X) && IsClientInGame(X))
		{
			if(ApologyFilter[X] > 0)
			{
				ApologyFilter[X] -= 1;
			}

			if(RelationUp[X] == 0)
			{
				if(Relation[X] < 100)
				{
					Relation[X] += 1;
				}
				RelationUp[X] = 60;
				SaveRelation(X);
			}
			else
			{
				RelationUp[X] -= 1;
			}
		}
	}

	if(SayPhrase > 0)
	{
		SayPhrase -= 1;
	}

	if(SayPhrase == 0)
	{
		if(Typing == 0 && WatchingChat == -1)
		{
			RandomPhrase();
		}

		SayPhrase = BotWait;
	}

	if(LastGreet != 0)
	{
		LastGreet -= 1;
	}

	if(Stopped > 0)
	{
		Stopped -= 1;
	}

	if(ChatTimeOut > 0)
	{
		ChatTimeOut -= 1;

		if(ChatTimeOut == 0)
		{
			if(WatchingChat > 0)
			{
				decl String:Name[32];
				GetClientName(WatchingChat, Name, 32);
				PrintToChatAll("\x01\x04%s\x01 :  %s, please don't call my name if you have nothing to say...", BotName, Name);
				PrintToServer("%s :  %s, please don't call my name if you have nothing to say...", BotName, Name);

				if(WatchingChat != 0)
				{
					if(Relation[WatchingChat] > 3)
					{
						Relation[WatchingChat] -= 3;
					}
					else
					{
						Relation[WatchingChat] = 0;
					}
					
					SaveRelation(WatchingChat);
				}
			}

			WatchingChat = -1;
		}
	}

	CreateTimer(1.0, SecondTimer, Client);
	return Plugin_Handled;
}

public AlivePlayers()
{
	decl Count;
	Count = 0;
	decl MaxPlayers;
	MaxPlayers = GetMaxClients();
	for(new X = 1; X <= MaxPlayers; X++)
	{
		if(IsClientConnected(X) && IsClientInGame(X))
		{
			Count += 1;
		}
	}
	return Count;
}

public Action:LifeTick(Handle:Timer, any:Client)
{
	if(IsBot != Client || !IsValidEntity(Client))
	{
		return Plugin_Handled;
	}

	if(Paused == 1)
	{
		CreateTimer(0.1, LifeTick, Client);
		return Plugin_Handled;
	}

	if(LastGreet == 0 && Typing == 0)
	{
		new Float:ClientVec[3];
		new Float:XVec[3];
		new Float:Dist;
        	GetEntPropVector(Client, Prop_Send, "m_vecOrigin", ClientVec);
		
		decl MaxPlayers;
		MaxPlayers = GetMaxClients();

		for(new X = 1; X <= MaxPlayers; X++)
		{
			if(IsClientConnected(X) && IsClientInGame(X) && IsPlayerAlive(X) && Client != X)
			{
				if(Greeted[X] == 1)
				{
					continue;
				}

				GetClientAbsOrigin(X, XVec);
				Dist = GetVectorDistance(ClientVec, XVec);

				if(Dist < 250)
				{
					Typing = 1;
					LastGreet = 60;
					ChatTarget = X;
					Greeted[X] = 1;
					CreateTimer(2.0, GreetPlayer, Client);
					CreateTimer(0.1, LifeTick, Client);
				}
			}
		}
	}

	if(HeldBy != -1)
	{
		CreateTimer(0.1, LifeTick, Client);
		return Plugin_Handled;
	}

	decl Random;
	Random = GetRandomInt(1,300);

	if(Random == 300)
	{
		Stopped = 1;
	}
	
	if(Random > 0)
	{
		Random = GetRandomInt(1,10);

		decl Float:BotAngle[3];
		GetEntPropVector(Client, Prop_Data, "m_angRotation", BotAngle);

		if(BotAngle[0] != 0.0)
		{
			BotAngle[0] = 0.0;
		}

		if(BotAngle[2] != 0.0)
		{
			BotAngle[2] = 0.0;
		}

		TeleportEntity(Client, NULL_VECTOR, BotAngle, NULL_VECTOR);

		decl Float:EyeAngles[3];
		decl Float:BotOrg[3];
		decl Float:EndPos[3];
		decl Float:Dist;
		decl ShouldPush;
		decl Direction;
		ShouldPush = 1;
		GetEntPropVector(Client, Prop_Data, "m_vecOrigin", BotOrg);
		GetEntPropVector(Client, Prop_Data, "m_angRotation", EyeAngles);
		
		if(Random < 5 && Stopped == 0 && Leaving == 0 && Typing == 0)
		{
			if(TurnDir == -1)
			{
				if(Random == 1 || Random == 2)
				{
					EyeAngles[1] += 18.0;
					Direction = 1;
				}
				if(Random == 3 || Random == 4)
				{	
					EyeAngles[1] -= 18.0;
					Direction = 0;
				}
			}
			else
			{
				if(TurnDir == 0 || TurnDir == 2 || TurnDir == 3)
				{
					EyeAngles[1] += 18.0;
					Direction = 1;
				}
				if(TurnDir == 1 || TurnDir == 4 || TurnDir == 5)
				{
					EyeAngles[1] -= 18.0;
					Direction = 0;
				}
			}

			TeleportEntity(Client, NULL_VECTOR, EyeAngles, NULL_VECTOR);
		}

		new Handle:Trace = TR_TraceRayFilterEx(BotOrg, EyeAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterNone);

		if(TR_DidHit(Trace))
		{
   	 		TR_GetEndPosition(EndPos, Trace);
			Dist = GetVectorDistance(BotOrg, EndPos);
			if(Dist < (BotSpeed * 0.66))
			{
				ShouldPush = 0;
				if(TurnDir == -1)
				{
					TurnDir = GetRandomInt(0,5);
				}
			}
		}

		CloseHandle(Trace);

		decl Float:FloatOrg[3];
		decl Float:TestAngles[3];
		TestAngles[0] = 90.0;
		TestAngles[1] = 0.0;
		TestAngles[2] = 0.0;
		decl Float:EndLoc[3];
		decl Float:Dist2;
		GetEntPropVector(Client, Prop_Send, "m_vecOrigin", FloatOrg);
		decl PushUp;
		PushUp = 0;

		new Handle:Trace2 = TR_TraceRayFilterEx(FloatOrg, TestAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterNone);

		if(TR_DidHit(Trace2))
		{
   	 		TR_GetEndPosition(EndLoc, Trace2);
			Dist2 = GetVectorDistance(FloatOrg, EndLoc);
			if(Dist2 < FloatHeight)
			{
				PushUp = 1;
			}
		}

		CloseHandle(Trace2);

		decl Float:Push[3];
		Push[0] = 0.0;
		Push[1] = 0.0;
		Push[2] = 0.0;
		
		if(ShouldPush == 1)
		{
			if(TurnDir != -1)
			{
				TurnDir = -1;
			}

			if(Stopped == 0 && Leaving == 0 && Typing == 0)
			{
	    			Push[0] = (BotSpeed * Cosine(DegToRad(EyeAngles[1])));
    				Push[1] = (BotSpeed * Sine(DegToRad(EyeAngles[1])));
			}
		}
		else
		{
			if(Direction == 1 && Typing == 0)
			{
				EyeAngles[1] += 7.0;
			}
			if(Direction == 0 && Typing == 0)
			{
				EyeAngles[1] -= 7.0;
			}
			TeleportEntity(Client, NULL_VECTOR, EyeAngles, NULL_VECTOR);
		}

		if(PushUp == 1)
		{
    			Push[2] = 100.0;
		}
		else
		{
			Push[2] = 10.0;
		}

		TeleportEntity(Client, NULL_VECTOR, NULL_VECTOR, Push);

		CreateTimer(0.1, LifeTick, Client);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public bool:TraceEntityFilterNone(entity, contentsMask)
{
	return (entity > 0 && entity != IsBot) || !entity;
}
			
public Action:GenGreetChat(Handle:Timer, any:Client)
{
	if(IsBot != -1)
	{
		RandomChat("Greeting", 10);
	}

	ChatTimeOut = 0;
	WatchingChat = -1;
	Typing = 0;
}

public Action:PauseClient(Client, Args)
{
	if(Dead == 1)
	{
		PrintToConsole(Client, "[SB] Please wait a second for the bot to respawn.");
		return Plugin_Handled;
	}

	if(IsBot == -1)
	{
		PrintToConsole(Client, "[SB] The bot isn't playing.");
		return Plugin_Handled;
	}

	if(Paused == 0)
	{
		Paused = 1;
		PrintToConsole(Client, "[SB] Paused the bot.");
		return Plugin_Handled;
	}
	if(Paused == 1)
	{
		PrintToConsole(Client, "[SB] The bot is already paused.");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:UnpauseClient(Client, Args)
{
	if(IsBot == -1)
	{
		PrintToConsole(Client, "[SB] The bot isn't playing.");
		return Plugin_Handled;
	}

	if(Paused == 0)
	{
		PrintToConsole(Client, "[SB] The bot is not paused.");
		return Plugin_Handled;
	}
	if(Paused == 1)
	{
		Paused = 0;
		PrintToConsole(Client, "[SB] Unpaused the bot.");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:MakeClient(Client, Args)
{
	if(IsBot != -1 && IsValidEntity(IsBot))
	{
		PrintToConsole(Client, "[SB] The bot is already playing.");
		return Plugin_Handled;
	}

	if(BotSpeed < 1)
	{
		PrintToConsole(Client, "[SB] Error: No bot speed is set.");
		return Plugin_Handled;
	}

	decl Bot;

	decl String:Name[32];
	decl Handle:Vault;

	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, ConfigPath);

	KvJumpToKey(Vault, "Personal", false);

	KvGetString(Vault, "Name", Name, 255, "$null");

	KvRewind(Vault);
	CloseHandle(Vault);

	if(StrEqual(Name, "$null"))
	{
		PrintToConsole(Client, "[SB] Error: No name specified in config file.");
		return Plugin_Handled;
	}

	Bot = CreateEntityByName("prop_physics_override");

	DispatchKeyValue(Bot, "physdamagescale", "2.0");

	//DispatchKeyValue(Bot, "model", BotModel);
	SetEntityModel(Bot,BotModel);
	
	DispatchSpawn(Bot);

	SpawnBot(Bot);

	BotName = Name;

	WatchingChat = -1;
	ChatTimeOut = 0;
	Typing = 1;
	Stopped = 0;
	HeldBy = -1;
	SayPhrase = BotWait;
	Following = -1;
	LastGreet = 10;
	ChatTarget = -1;
	IsBot = Bot;
	Paused = 0;
	Leaving  = 0;
	Health = 100;
	Dead = 0;
	//Respawn = false;
	Respawn = true;
	SayMess = "null";
	TurnDir = -1;
	for(new x = 1; x < 129; x++)
	{
		Greeted[x] = 0;
	}
	CreateTimer(3.0, GenGreetChat, Bot);
	CreateTimer(3.1, LifeTick, Bot);
	CreateTimer(4.0, SecondTimer, Bot);

	PrintToConsole(Client, "[SB] Created bot: %s", Name);

	PrintToServer("[SB] Bot has been spawned.");

	if(UsePlayerSlot())
	{
		BotHolder = CreateFakeClient(Name);
		CreateTimer(0.1, TeamSwitch, BotHolder);
	}

	return Plugin_Handled;
}

public UsePlayerSlot()
{
	decl Handle:Vault;

	decl String:Result[5];
	
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, ConfigPath);

	KvJumpToKey(Vault, "Setup", false);

	KvGetString(Vault, "UsePlayerSlot", Result, 5, "$null");

	KvRewind(Vault);
	CloseHandle(Vault);

	if(StrEqual(Result, "Yes", false))
	{
		return true;
	}
	else
	{
		if(!StrEqual(Result, "No", false))
		{
			LogError("[SB] Error: Please fill out the value of UsePlayerSlot, in the bot_config file, as either Yes or No.");
		}
	}

	return false;
}

public Action:TeamSwitch(Handle:Timer, any:Client)
{
	ChangeClientTeam(Client, 1);
}

public BotTookDamage(const String:output[], Bot, Attacker, Float:delay)
{
	if(IsBot != Bot)
	{
		return;
	}

	if(Bot == Attacker)
	{
		return;
	}

	if(Bot == -1 || Bot == 0 || Attacker == -1 || Attacker == 0)
	{
		return;
	}

	if(IsBot == -1 || Paused == 1)
	{
		return;
	}

	if(Attacker > GetMaxClients())
	{
		return;
	}

	if(Health < 11)
	{
		Dead = 1;
		ExplodeBot(Bot, Attacker);
	}
	else
	{
		decl Float:BotOrigin[3];
		GetEntPropVector(Bot, Prop_Send, "m_vecOrigin", BotOrigin);
		Health -= 10;
	}

	return;
}

public ExplodeBot(Bot, Attacker)
{
	decl Float:BotOrigin[3];
	GetEntPropVector(Bot, Prop_Send, "m_vecOrigin", BotOrigin);

	TE_SetupExplosion(BotOrigin, g_ExplosionSprite, 5.0, 1, 0, 600, 5000);
	TE_SendToAll();

	EmitAmbientSound("ambient/explosions/explode_4.wav", BotOrigin, SNDLEVEL_RAIDSIREN);
	
	AcceptEntityInput(Bot, "kill", -1);

	IsBot = -1;

	HeldBy = -1;

	Following = -1;

	Typing = 1;

	if(Relation[Attacker] > 10)
	{
		Relation[Attacker] -= 10;
	}
	else
	{
		Relation[Attacker] = 0;
	}
	SaveRelation(Attacker);

	if(Leaving == 0)
	{
		CreateTimer(2.0, GotKilled, Attacker);
	}
}

public Action:GotKilled(Handle:Timer, any:Client)
{
	decl Random;
	Random = GetRandomInt(1,5);

	decl String:AttackerName[32];
	GetClientName(Client, AttackerName, 32);

	if(Random == 1)
	{
		PrintToChatAll("\x01\x04%s\x01 :  wow wtf %s!", BotName, AttackerName);
		PrintToServer("%s :  wow wtf %s", BotName, AttackerName);
	}
	if(Random == 2)
	{
		PrintToChatAll("\x01\x04%s\x01 :  %s, you have problems!", BotName, AttackerName);
		PrintToServer("%s :  %s, you have problems", BotName, AttackerName);
	}
	if(Random == 3)
	{
		PrintToChatAll("\x01\x04%s\x01 :  omfg, %s you suck", BotName, AttackerName);
		PrintToServer("%s :  omfg %s you suck", BotName, AttackerName);
	}
	if(Random == 4)
	{
		PrintToChatAll("\x01\x04%s\x01 :  ill get you for that %s...", BotName, AttackerName);
		PrintToServer("%s :  ill get you for that %s...", BotName, AttackerName);
	}
	if(Random == 5)
	{
		PrintToChatAll("\x01\x04%s\x01 :  aww, damn it %s", BotName, AttackerName);
		PrintToServer("%s :  aw damn it %s", BotName, AttackerName);
	}

	Typing = 0;

	CreateTimer(1.0, WaitForRespawn, Client);
}

public Action:WaitForRespawn(Handle:Timer, any:Client)
{
	RespawnBot();
}

public RespawnBot()
{
	decl Bot;
	Bot = CreateEntityByName("prop_physics_override");

	DispatchKeyValue(Bot, "physdamagescale", "1.0");

	//DispatchKeyValue(Bot, "model", BotModel);
	SetEntityModel(Bot,BotModel);
	
	DispatchSpawn(Bot);

	IsBot = Bot;

	Health = 100;
	Dead = 0;

	CreateTimer(0.1, LifeTick, Bot);
	CreateTimer(1.0, SecondTimer, Bot);

	SpawnBot(Bot);
}

public Action:KillClient(Client, Args)
{
	if(IsBot == -1)
	{
		PrintToConsole(Client, "[SB] The bot isn't playing.");
		return Plugin_Handled;
	}

	if(Leaving == 1)
	{
		PrintToConsole(Client, "[SB] The bot is already about to leave.");
		return Plugin_Handled;
	}

	Typing = 1;
	Leaving = 1;
	CreateTimer(1.0, LeaveMessage, IsBot);
	return Plugin_Handled;
}

public Action:LeaveMessage(Handle:Timer, any:Client)
{
	decl Random;
	Random  = GetRandomInt(1,3);

	if(Random == 1)
	{
		PrintToChatAll("\x01\x04%s\x01 :  gtg bye", BotName);
		PrintToServer("%s :  gtg bye", BotName);
	}
	if(Random == 2)
	{
		PrintToChatAll("\x01\x04%s\x01 :  gtg, cya!", BotName);
		PrintToServer("%s :  gtg, cya!", BotName);
	}
	if(Random == 3)
	{
		PrintToChatAll("\x01\x04%s\x01 : gtg, bye!", BotName);
		PrintToServer("%s :  gtg, bye!", BotName);
	}

	CreateTimer(5.0, LeaveGame, IsBot);
	return Plugin_Handled;
}

public Action:LeaveGame(Handle:Timer, any:Client)
{
	PrintToChatAll("%s has left the game (Disconnect by user.)", BotName);

	BotName = "Null";
	WatchingChat = -1;
	ChatTimeOut = 0;
	Typing = 0;
	Stopped = 0;
	HeldBy = -1;
	SayPhrase = BotWait;
	Following = -1;
	LastGreet = 0;
	ChatTarget = -1;
	Paused = 0;
	Leaving = 0;
	Health = -1;
	Dead = 0;
	Respawn = false;
	SayMess = "null";
	TurnDir = -1;
	for(new x = 1; x < 129; x++)
	{
		Greeted[x] = 0;
	}

	if(IsValidEdict(IsBot))
	{
		AcceptEntityInput(IsBot, "Kill", -1);
	}

	IsBot = -1;

	PrintToServer("[SB] Bot has been killed.");

	if(BotHolder > 0 && IsClientConnected(BotHolder) && IsClientInGame(BotHolder) && IsFakeClient(BotHolder) && UsePlayerSlot())
	{
		KickClient(BotHolder);
	}

	return Plugin_Handled;
}
