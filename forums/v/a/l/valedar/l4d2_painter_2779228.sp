#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"3.0"
#define ADVERT		"\x02 This server runs \x05 l4d2 painter! enjoy your \x03 colormized character!"


new String:Version[] = "1.3";
new String:NotSet[] = "-1 -1 -1";
new String:Red[] = "255 0 0";
new String:Green[] = "0 255 0";
new String:Blue[] = "0 0 255";
new String:Black[] = "0 0 0";
new String:LightGreen[] = "0 100 0";
new Handle:Tank = INVALID_HANDLE;
new Handle:FemaleBoomer = INVALID_HANDLE;
new Handle:Spitter = INVALID_HANDLE;
new Handle:Jockey = INVALID_HANDLE;
new Handle:Witch = INVALID_HANDLE;
new Handle:Smoker = INVALID_HANDLE;
new Handle:Boomer = INVALID_HANDLE;
new Handle:Ellis = INVALID_HANDLE;
new Handle:Coach = INVALID_HANDLE;
new Handle:Rachelle = INVALID_HANDLE;
new Handle:Nick = INVALID_HANDLE;
new Handle:Render = INVALID_HANDLE;
new Handle:Allowed = INVALID_HANDLE;
new MaxPlayers = 0;
new Handle:Zoey = INVALID_HANDLE;
new Handle:Francis = INVALID_HANDLE;
new Handle:Louis = INVALID_HANDLE;
new Handle:Bill = INVALID_HANDLE;
new Handle:Timer = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "L4D2 Painter",
	author = "gamemann",
	description = "Sets a different color to the game players",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/",
};

public OnPluginStart()
{
	//Requires l4d2
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))

	//witch spawn
	HookEvent("witch_spawn", WitchSpawn);

	//drag_begin 
	HookEvent("drag_begin", DragBegin);

	//player class
	HookEvent("player_class", Event_Player_Class); //Player changed his class. Such as became tank.
	
	//player spawn
	HookEvent("player_spawn", Event_Player_Spawn); //Player spawned

	//tank spawn
	HookEvent("tank_spawn", Event_Tank_Spawn); //Event of tank coming

	//ADVERTISEMENT TIMER!
	Timer = CreateConVar("sm_l4d_painter_advert_timer", "3.0", "the time ingame before the avertisement is announced!", FCVAR_NOTIFY, true, 0.0, true, 60.0);

	//bill
	Bill = CreateConVar("sm_l4d_painter_bill", Blue, "RBG value for bill. Usage \"R G B\" or \"-1 -1 -1\" to do nothin", FCVAR_NOTIFY);

	//louis
	Louis = CreateConVar("sm_l4d_painter_louis", Red, "RGB vlaue for louis. Usage \"R G B\" or \"- 1- 1 -1\" to do nothing.", FCVAR_NOTIFY);

	//zoey
	Zoey = CreateConVar("sm_l4d_painter_zoey", Blue, "RBG value for zoey. Usage \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);

	//fransis
	Francis = CreateConVar("sm_l4d_painter_francis", Green, "RBG value for francis. Useage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);

	//tank
	Tank = CreateConVar("sm_l4d_painter_tank", Green,"RGB Value for tank. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);

	//female boomer
	FemaleBoomer = CreateConVar("sm_l4d_female_boomer", Blue, "RBG Value for female boomer. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing", FCVAR_NOTIFY);

	//smoker
	Smoker = CreateConVar("sm_l4d_painter_smoker", Blue,"RGB Value for smoker. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);

	//boomer
	Boomer = CreateConVar("sm_l4d_painter_boomer", LightGreen,"RGB Value for boomer. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);

	//ellis
	Ellis = CreateConVar("sm_l4d_painter_ellis", Red,"RGB Value for ellis. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);

	//coach
	Coach = CreateConVar("sm_l4d_painter_coach", Black,"RGB Value for coach. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);

	//rachelle
	Rachelle = CreateConVar("sm_l4d_painter_rachelle", Blue,"RGB Value for bill. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);

	//nick
	Nick = CreateConVar("sm_l4d_painter_nick", Green,"RGB Value for nick. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);

	//spitter
	Spitter = CreateConVar("sm_l4d_painter_spitter", Green,"RBG Value for spitter. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);

	//jockey
	Jockey = CreateConVar("sm_l4d_paint_jockey", Red,"RBG Value for jockey. Usage: \"R B G\" or \"-1 -1 -1\" for nothing", FCVAR_NOTIFY);

	//witch
	Witch = CreateConVar("sm_l4d_paint_witch", Black,"RBG Value for witch. Usage: \"R B G\" or \"-1 -1 -1\" for nothing", FCVAR_NOTIFY);

	//render mode
	Render = CreateConVar("sm_l4d_painter_render_mode","0","Render mode of colored peoples.", 0, true, 0.0, true, 10.0);

	//allow the plugin to be enabled	
	Allowed = CreateConVar("sm_l4d_painter_enabled","1","Enables painting zombies.", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	//reg command
	RegAdminCmd("sm_paint", Command_Paint, ADMFLAG_GENERIC, "Paints your target with the given RGB."); //Fun paint brusher
	
	//executs the config
	AutoExecConfig(true, "l4d2painter"); //Saves last used settings so you don't have to set it everytime

	//load the translations phrases!
	LoadTranslations("common.phrases");

	//convar to the plugin to get approved on alliedmodders
	CreateConVar("sm_l4d_painter_version", Version, "Version of Tank Colorer plugin.", FCVAR_NOTIFY);

	//now for the timer!
	CreateTimer(GetConVarFloat(Timer), Advert);
} 
//We can't paint common infecteds because they have no event announcing

//advertisement timer
public Action:Advert(Handle:timer)
{
	PrintToChatAll(ADVERT);
}

public OnMapStart()
{
	MaxPlayers = MaxClients;
	for(new client = 1; client <= MaxPlayers; client++)
	{
		Paint(client);
	}
}

public DragBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Allowed))
	{
		new smokerid = GetEventInt(event, "userid");
		if (smokerid)
		{
			decl String:Color[50];
			GetConVarString(Smoker, Color, sizeof(Color))
			if(!StrEqual(Color, NotSet, false))
			{
				SetEntityRenderMode(smokerid, RenderMode:GetConVarInt(Render));
				DispatchKeyValue(smokerid, "rendercolor", Color);
			}
		}
	}
	for (new client = 1; client <= MaxClients; client++)
	if (IsClientInGame(client))
	{
		Paint(client);
	}
}

public WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Allowed))
	{
		new Witchid = GetEventInt(event, "userid");
		if(Witchid)
		{
			decl String:Color[50];
			GetConVarString(Witch, Color, sizeof(Color));
			if(!StrEqual(Color, NotSet, false)) //check if a color is set yippe lol
			{
				SetEntityRenderMode(Witchid, RenderMode:GetConVarInt(Render));
				DispatchKeyValue(Witchid, "rendercolor", Color);
			}
		}
	}
	for (new client = 1; client <= MaxClients; client++)
	if (IsClientInGame(client))
	{
		Paint(client);
	}
}
public Action:Event_Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Allowed))
	{
		new TankId = GetEventInt(event, "tankid"); //Why not userid? Because it's the player not the tanker. If we use userid the player will stay colored when tanker die
		if(TankId)
		{
			decl String:Color[50];
			GetConVarString(Tank, Color, sizeof(Color));
			if(!StrEqual(Color, NotSet, false)) //Check if there's a color set
			{
				SetEntityRenderMode(TankId, RenderMode:GetConVarInt(Render));
				DispatchKeyValue(TankId, "rendercolor", Color);
			}
		}
	}
}

public Action:Event_Player_Class(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Allowed))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		Paint(client);
	}
}


//now to make it so everytime someone dies or round ends it will paint them again!

public OnMapEnd()
{
	for(new client=1; client <= MaxClients; client++)
	if(IsClientInGame(client))
	{
		Paint(client);
		PrintToConsole(client, "1..2..3..4..5..6..7..8..9..10......... Map End Check Complete");
	}
	else if(!IsClientInGame(client)) return;
}

public Action:Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Allowed))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		Paint(client);
	}
}

public Action:Command_Paint(client, args)
{
	if(args > 1) //Guarantees that will match any of the usage options
	{
		decl String:arg[MAX_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));
		new target = FindTarget(client, arg);
		if(target > 0) //Check for errors
		{
			decl String:Color[50];
			if(args >= 4)
			{
				GetCmdArg(2, arg, sizeof(arg));
				Format(Color, sizeof(Color), "%s", arg);//Starts the color string
				GetCmdArg(3, arg, sizeof(arg));
				Format(Color, sizeof(Color), "%s %s", Color, arg);//Adds colors to color string
				GetCmdArg(4, arg, sizeof(arg));
				Format(Color, sizeof(Color), "%s %s", Color, arg);
			}
			else if(args >= 2)
				GetCmdArg(2, Color, sizeof(Color));
			DispatchKeyValue(target, "rendercolor", Color);
			ReplyToCommand(client, "You've painted %N with the color \"%s\".", target, Color);
		}
	}
	else
		ReplyToCommand(client, "Usage: sm_paint target \"R G B\" or sm_paint target R G B");
}

stock Paint(client)
{
	if(IsClientInGame(client))
	{
		decl String:Model[150], String:Color[50];
		GetClientModel(client, Model, sizeof(Model));
		if(StrContains(Model, "boomer", false) > -1)//Since boomer and smokers are limited
			GetConVarString(Boomer, Color, sizeof(Color));
		else if(StrContains(Model, "smoker", false) > -1)
			GetConVarString(Smoker, Color, sizeof(Color));
		else if(StrContains(Model, "mechanic", false) > -1)//Since you'll spawn only once as survivor
			GetConVarString(Ellis, Color, sizeof(Color));
		else if(StrContains(Model, "coach", false) > -1)
			GetConVarString(Coach, Color, sizeof(Color));
		else if(StrContains(Model, "producer", false) > -1)
			GetConVarString(Rachelle, Color, sizeof(Color));
		else if(StrContains(Model, "gambler", false) > -1)
			GetConVarString(Nick, Color, sizeof(Color));
		else if(StrContains(Model, "hulk", false) > -1)
			GetConVarString(Tank, Color, sizeof(Color));
		else if(StrContains(Model, "spitter", false) > -1)
			GetConVarString(Spitter, Color, sizeof(Color));
		else if(StrContains(Model, "jockey", false) > -1)
			GetConVarString(Jockey, Color, sizeof(Color));
		else if(StrContains(Model, "witch", false) > -1)
			GetConVarString(Witch, Color, sizeof(Color));
		else if(StrContains(Model, "boomette", false) > -1)
			GetConVarString(FemaleBoomer, Color, sizeof(Color));
		else if(StrContains(Model, "biker", false) > -1)
			GetConVarString(Francis, Color, sizeof(Color));
		else if(StrContains(Model, "teenangst", false) > -1)
			GetConVarString(Zoey, Color, sizeof(Color));
		else if(StrContains(Model, "manager", false) > -1)
			GetConVarString(Louis, Color, sizeof(Color));
		else if(StrContains(Model, "namvet", false) > -1)
			GetConVarString(Bill, Color, sizeof(Color));
		else
		{
			LogMessage("Unknown Model: %s is invalid", Model); //Logs the Model for future improvements
			return;//The witch can be colored now!
		}
		if(!StrEqual(Color, NotSet, false)) //Check if there's a color set
		{
			SetEntityRenderMode(client, RenderMode:GetConVarInt(Render));
			DispatchKeyValue(client, "rendercolor", Color);
		}
		if(!IsClientInGame(client)) return;
	}
}
