#include <sourcemod>
#include <sdktools>
new String:Version[] = "1.3";
new String:NotSet[] = "-1 -1 -1";
new String:Red[] = "255 0 0";
new String:Green[] = "0 255 0";
new String:Blue[] = "0 0 255";
new String:Black[] = "0 0 0";
new Handle:Tank = INVALID_HANDLE;
new Handle:Witch = INVALID_HANDLE;
new Handle:Hunter = INVALID_HANDLE;
new Handle:Smoker = INVALID_HANDLE;
new Handle:Boomer = INVALID_HANDLE;
new Handle:Zoey = INVALID_HANDLE;
new Handle:Louis = INVALID_HANDLE;
new Handle:Bill = INVALID_HANDLE;
new Handle:Francis = INVALID_HANDLE;
new Handle:Render = INVALID_HANDLE;
new Handle:Allowed = INVALID_HANDLE;
new MaxPlayers = 0;

public Plugin:myinfo = 
{
	name = "L4D Painter",
	author = "NBK - Sammy-ROCK!",
	description = "Sets a different color to the game players",
	version = Version,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if(!StrEqual(ModName,"left4dead",false))
		SetFailState("This plugin is for left4dead only.");
	HookEvent("player_class", Event_Player_Class); //Player changed his class. Such as became tank.
	HookEvent("player_spawn", Event_Player_Spawn); //Player spawned
	HookEvent("tank_spawn", Event_Tank_Spawn); //Event of tank coming
	HookEvent("witch_spawn", Event_Witch_Spawn); //Event of witch coming
	Tank = CreateConVar("sm_l4d_painter_tank", Green,"RGB Value for tank. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Witch = CreateConVar("sm_l4d_painter_witch", Blue,"RGB Value for witch. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Hunter = CreateConVar("sm_l4d_painter_hunter", Red,"RGB Value for hunter. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Smoker = CreateConVar("sm_l4d_painter_smoker", Blue,"RGB Value for smoker. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Boomer = CreateConVar("sm_l4d_painter_boomer", Green,"RGB Value for boomer. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Zoey = CreateConVar("sm_l4d_painter_zoey", Red,"RGB Value for zoey. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Louis = CreateConVar("sm_l4d_painter_louis", Black,"RGB Value for louis. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Bill = CreateConVar("sm_l4d_painter_bill", Blue,"RGB Value for bill. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Francis = CreateConVar("sm_l4d_painter_francis", Green,"RGB Value for francis. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Render = CreateConVar("sm_l4d_painter_render_mode","3","Render mode of colored peoples.", 0, true, 0.0, true, 10.0);
	Allowed = CreateConVar("sm_l4d_painter_enabled","1","Enables painting zombies.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	RegAdminCmd("sm_paint", Command_Paint, ADMFLAG_GENERIC, "Paints your target with the given RGB."); //Fun paint brusher
	AutoExecConfig(true, "l4dpainter"); //Saves last used settings so you don't have to set it everytime
	LoadTranslations("common.phrases");
	CreateConVar("sm_l4d_painter_version", Version, "Version of Tank Colorer plugin.", FCVAR_NOTIFY);
}//We can't paint common infecteds because they have no event announcing

public OnMapStart()
{
	MaxPlayers = GetMaxClients();
	for(new client=1; client<=MaxPlayers; client++)
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

public Action:Event_Witch_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Allowed))
	{
		new WitchId = GetEventInt(event, "witchid");
		if(WitchId)
		{
			decl String:Color[50];
			GetConVarString(Witch, Color, sizeof(Color));
			if(!StrEqual(Color, NotSet, false)) //Check if there's a color set
			{
				SetEntityRenderMode(WitchId, RenderMode:GetConVarInt(Render));
				DispatchKeyValue(WitchId, "rendercolor", Color);
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
		if(StrContains(Model, "Hunter", false) > -1) //In order or probability so in most of cases it will save CPU
			GetConVarString(Hunter, Color, sizeof(Color));
		else if(StrContains(Model, "Boomer", false) > -1)//Since boomer and smokers are limited
			GetConVarString(Boomer, Color, sizeof(Color));
		else if(StrContains(Model, "Smoker", false) > -1)
			GetConVarString(Smoker, Color, sizeof(Color));
		else if(StrContains(Model, "teenangst", false) > -1)//Since you'll spawn only once as survivor
			GetConVarString(Zoey, Color, sizeof(Color));
		else if(StrContains(Model, "manager", false) > -1)
			GetConVarString(Louis, Color, sizeof(Color));
		else if(StrContains(Model, "namvet", false) > -1)
			GetConVarString(Bill, Color, sizeof(Color));
		else if(StrContains(Model, "biker", false) > -1)
			GetConVarString(Francis, Color, sizeof(Color));
		else if(StrContains(Model, "Hulk", false) > -1)
			GetConVarString(Tank, Color, sizeof(Color));
		else
		{
			LogMessage("Unknown Model: %s", Model); //Logs the Model for future improvements
			return;//Why not witch? Simple: Players can't become the witch.
		}
		if(!StrEqual(Color, NotSet, false)) //Check if there's a color set
		{
			SetEntityRenderMode(client, RenderMode:GetConVarInt(Render));
			DispatchKeyValue(client, "rendercolor", Color);
		}
	}
}