#include <sourcemod>
#include <sdktools>

/*
some things may not color!
*/


/*
Version History:

version 1.0:
- release

version 1.1:
- added spitter, jockey, and charger
- fixed the plugin

version 1.2:
- added more colors (light blue, and light green)
- made a witch color
*/



//colors
new String:Version[] = "1.3";
new String:NotSet[] = "-1 -1 -1";
new String:Red[] = "255 0 0";
new String:Green[] = "0 255 0";
new String:Blue[] = "0 0 255";
new String:Black[] = "0 0 0";
new String:LightGreen[] = "0 100 0";

//guns
new Handle:Pistol = INVALID_HANDLE;
new Handle:Magnum = INVALID_HANDLE;
new Handle:Rifle_Desert = INVALID_HANDLE;
new Handle:Rifle_Ak47 = INVALID_HANDLE;
new Handle:PumpShotGun = INVALID_HANDLE;
new Handle:Hunting_Rifle = INVALID_HANDLE;
new Handle:Sniper_Military = INVALID_HANDLE;
new Handle:SMG = INVALID_HANDLE;
new Handle:SMG_Silenced = INVALID_HANDLE;
new Handle:Shotgun_Spas = INVALID_HANDLE;
new Handle:Rifle = INVALID_HANDLE;
new Handle:ShotGun_Chrome = INVALID_HANDLE;
new Handle:Auto_Shotgun = INVALID_HANDLE;

//items
new Handle:PainPills = INVALID_HANDLE;
new Handle:PipeBomb = INVALID_HANDLE;
new Handle:Molotov = INVALID_HANDLE;
new Handle:FirstAidKit = INVALID_HANDLE;
new Handle:VomitJar = INVALID_HANDLE;



//infected
new Handle:Tank = INVALID_HANDLE;
new Handle:FemaleBoomer = INVALID_HANDLE;
new Handle:Spitter = INVALID_HANDLE;
new Handle:Jockey = INVALID_HANDLE;
new Handle:Charger = INVALID_HANDLE;
new Handle:Witch = INVALID_HANDLE;
new Handle:Hunter = INVALID_HANDLE;
new Handle:Smoker = INVALID_HANDLE;
new Handle:Boomer = INVALID_HANDLE;
new Handle:Ellis = INVALID_HANDLE;
new Handle:Coach = INVALID_HANDLE;
new Handle:Rachelle = INVALID_HANDLE;
new Handle:Nick = INVALID_HANDLE;
new Handle:Render = INVALID_HANDLE;
new Handle:Allowed = INVALID_HANDLE;
new MaxPlayers = 0;

public Plugin:myinfo = 
{
	name = "L4D2 Painter",
	author = "gamemann",
	description = "Sets a different color to the game players",
	version = "1",
	url = "http://www.sourcemod.net/",
};

public OnPluginStart()
{
	//Requires l4d2
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	HookEvent("witch_spawn", WitchSpawn);
	HookEvent("drag_begin", DragBegin);
	HookEvent("lunge_pounce", HunterPaint);
	HookEvent("charger_charge_start", ChargerPaint);
	HookEvent("charger_killed", ChargerKilled);
	HookEvent("player_class", Event_Player_Class); //Player changed his class. Such as became tank.
	HookEvent("player_spawn", Event_Player_Spawn); //Player spawned
	HookEvent("tank_spawn", Event_Tank_Spawn); //Event of tank coming

	//item convars
	PainPills = CreateConVar("sm_l4d_paint_painpills", Blue, "the color of pain pills", FCVAR_NOTIFY);
	PipeBomb = CreateConVar("sm_l4d_paint_pipebomb", Red, "color of pipebomb");
	FirstAidKit = CreateConVar("sm_l4d_paint_firstaidkit", Green, "color of first aid kit");
	Molotov = CreateConVar("sm_l4d_paint_molotov", Black, "color of molotov");

	//gun convars
	Pistol = CreateConVar("sm_l4d_paint_pistol", NotSet, "the color of a pistol");
	Magnum = CreateConVar("sm_l4d_paint_magnum", NotSet, "the magnum color");
	Rifle_Desert = CreateConVar("sm_l4d_paint_rifle_desert", NotSet, "the color of the rifle desert");
	Rifle_Ak47 = CreateConVar("sm_l4d_paint_rifle_ak47", NotSet, "the color of the rifle ak47");
	PumpShotGun = CreateConVar("sm_l4d_paint_pump_shotgun", NotSet, "the color of the pump shotgun");
	Hunting_Rifle = CreateConVar("sm_l4d_paint_hunting_rifle", NotSet, "the color of the hunting rifle");
	Sniper_Military = CreateConVar("sm_l4d_paint_sniper_military", NotSet, "the color of the sniper military");
	SMG = CreateConVar("sm_l4d_paint_smg", NotSet, "the color of the smg");
	SMG_Silenced = CreateConVar("sm_l4d_paint_smg_silenced", NotSet, "the color of the smg silenced");
	Shotgun_Spas = CreateConVar("sm_l4d_paint_shotgun_spas", NotSet, "the color of the shotgun spas");
	Rifle = CreateConVar("sm_l4d_paint_rifle", NotSet, "the color of the rifle");
	ShotGun_Chrome = CreateConVar("sm_l4d_paint_shotgun_chrome", NotSet, "the color of the shotgun chrome");
	Auto_Shotgun = CreateConVar("sm_l4d_paint_auto_shotgun", Blue, "the color of the auto shotgun");

	//infected convars
	Tank = CreateConVar("sm_l4d_painter_tank", Green,"RGB Value for tank. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	FemaleBoomer = CreateConVar("sm_l4d_female_boomer", Blue, "RBG Value for female boomer. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing", FCVAR_NOTIFY);
	Hunter = CreateConVar("sm_l4d_painter_hunter", Red,"RGB Value for hunter. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Smoker = CreateConVar("sm_l4d_painter_smoker", Blue,"RGB Value for smoker. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Boomer = CreateConVar("sm_l4d_painter_boomer", LightGreen,"RGB Value for boomer. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Ellis = CreateConVar("sm_l4d_painter_ellis", Red,"RGB Value for ellis. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Coach = CreateConVar("sm_l4d_painter_coach", Black,"RGB Value for coach. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Rachelle = CreateConVar("sm_l4d_painter_rachelle", Blue,"RGB Value for bill. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Nick = CreateConVar("sm_l4d_painter_nick", Green,"RGB Value for nick. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Spitter = CreateConVar("sm_l4d_painter_spitter", Green,"RBG Value for spitter. Usage: \"R G B\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Jockey = CreateConVar("sm_l4d_paint_jockey", Red,"RBG Value for jockey. Usage: \"R B G\" or \"-1 -1 -1\" for nothing", FCVAR_NOTIFY);
	Witch = CreateConVar("sm_l4d_paint_witch", Black,"RBG Value for witch. Usage: \"R B G\" or \"-1 -1 -1\" for nothing", FCVAR_NOTIFY);
	Charger = CreateConVar("sm_l4d_paint_charger", Blue,"RBG Value for charger. Usage: \"R B G\" or \"-1 -1 -1\" to do nothing.", FCVAR_NOTIFY);
	Render = CreateConVar("sm_l4d_painter_render_mode","0","Render mode of colored peoples.", 0, true, 0.0, true, 10.0);
	Allowed = CreateConVar("sm_l4d_painter_enabled","1","Enables painting zombies.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	RegAdminCmd("sm_paint", Command_Paint, ADMFLAG_GENERIC, "Paints your target with the given RGB."); //Fun paint brusher
	AutoExecConfig(true, "l4d2painter"); //Saves last used settings so you don't have to set it everytime
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
	for (new client = 1; client <= GetMaxClients(); client++)
	if (IsClientInGame(client))
	{
		Paint(client);
	}
}

public HunterPaint(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Allowed))
	{
		new hunterid = GetEventInt(event, "userid");
		if (hunterid)
		{
			decl String:Color[50];
			GetConVarString(Hunter, Color, sizeof(Color))
			if(!StrEqual(Color, NotSet, false))
			{
				SetEntityRenderMode(hunterid, RenderMode:GetConVarInt(Render));
				DispatchKeyValue(hunterid, "rendercolor", Color);
			}
		}
	}
	for (new client = 1; client <= GetMaxClients(); client++)
	if (IsClientInGame(client))
	{
		Paint(client);
	}
}

public ChargerPaint(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Allowed))
	{
		new chargerid = GetEventInt(event, "userid");
		if (chargerid)
		{
			decl String:Color[50];
			GetConVarString(Charger, Color, sizeof(Color))
			if(!StrEqual(Color, NotSet, false))
			{
				SetEntityRenderMode(chargerid, RenderMode:GetConVarInt(Render));
				DispatchKeyValue(chargerid, "rendercolor", Color);
			}
		}
	}
	for (new client = 1; client <= GetMaxClients(); client++)
	if (IsClientInGame(client))
	{
		Paint(client);
	}
}

public ChargerKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Allowed))
	{
		new chargerid = GetEventInt(event, "userid");
		if (chargerid)
		{
			decl String:Color[50];
			GetConVarString(Charger, Color, sizeof(Color))
			if(!StrEqual(Color, NotSet, false))
			{
				SetEntityRenderMode(chargerid, RenderMode:GetConVarInt(Render));
				DispatchKeyValue(chargerid, "rendercolor", Color);
			}
		}
	}
	for (new client = 1; client <= GetMaxClients(); client++)
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
	for (new client = 1; client <= GetMaxClients(); client++)
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
	CreateTimer(10.0, MapEndCheck);
}

public Action:MapEndCheck(Handle:timer, any:client)
{
	Paint(client);
	return Plugin_Handled;
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
		else if(StrContains(Model, "boomer", false) > -1)//Since boomer and smokers are limited
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
		else if(StrContains(Model, "charger", false) > -1)
			GetConVarString(Charger, Color, sizeof(Color));
		else if(StrContains(Model, "witch", false) > -1)
			GetConVarString(Witch, Color, sizeof(Color));
		else if(StrContains(Model, "boomette", false) > -1)
			GetConVarString(FemaleBoomer, Color, sizeof(Color));
		//now for the guns
		else if(StrContains(Model, "v_autoshot_m4super", false) > -1)
			GetConVarString(Auto_Shotgun, Color, sizeof(Color));
		else if(StrContains(Model, "shotgun_spas", false) > -1)
			GetConVarString(Shotgun_Spas, Color, sizeof(Color));
		else if(StrContains(Model, "v_desert_eagle", false) > -1)
			GetConVarString(Magnum, Color, sizeof(Color));
		
		//now for items
		else if(StrContains(Model, "painpills", false) > -1)
			GetConVarString(PainPills, Color, sizeof(Color));
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
	}
}