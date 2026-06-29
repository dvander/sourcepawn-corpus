#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "2.1.0"

new Handle:v_SmokeColor = INVALID_HANDLE;
new Handle:v_SmokeTime = INVALID_HANDLE;
new Handle:v_SmokeTransparency = INVALID_HANDLE;
new Handle:v_SmokeDensity = INVALID_HANDLE;
new Handle:v_SmokesPerPlayer = INVALID_HANDLE;
new Handle:v_SmokeColorHandler = INVALID_HANDLE;
new Handle:v_SmokeColorTeam2 = INVALID_HANDLE;
new Handle:v_SmokeColorTeam3 = INVALID_HANDLE;
new Handle:v_SpammyText = INVALID_HANDLE;


new g_SmokeCarry[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "Smoke Bomb",
    author = "DarthNinja",
    description = "Vanish like a ninja!",
    version = PLUGIN_VERSION,
    url = "DarthNinja.com"
}

public OnPluginStart()
{
		//RegAdminCmd("sm_smokebomb", CMDSmoke, ADMFLAG_GENERIC);
		RegAdminCmd("sm_givesmoke", GiveSmoke, ADMFLAG_GENERIC);
		RegConsoleCmd("sm_smokebomb", CMDSmoke, "Use a smoke bomb!  Vanish like a ninja!");
		
		CreateConVar("sm_smokebomb_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		//Smoke colorz | TF2 TeamIDs: red=2 blue=3  | CSS TeamIDs: t=2 ct=3
		v_SmokeColorHandler = CreateConVar("sm_smokecolorhandler", "1", "1 = Default color, 2 = Team colors, 3 = random colors", 0, true, 0.0, true, 3.0);
		v_SmokeColor = CreateConVar("sm_smokecolor", "255 255 255", "<Red> <Green> <Blue> (0-255)");
		v_SmokeColorTeam2 = CreateConVar("sm_smokecolor_team2", "255 0 0", "<Red> <Green> <Blue> (0-255)");
		v_SmokeColorTeam3 = CreateConVar("sm_smokecolor_team3", "0 0 255", "<Red> <Green> <Blue> (0-255)");
		//Other stuffz
		v_SmokeTime = CreateConVar("sm_smoketime", "8", "How long the smoke lasts (in seconds)");
		v_SmokeTransparency = CreateConVar("sm_smoketrans", "255", "Smoke Transparency (0-255)");
		v_SmokeDensity = CreateConVar("sm_smokedensity", "30", "How thick the smoke is");
		v_SmokesPerPlayer = CreateConVar("sm_smokecarry", "3", "How many smokebombs players can carry");
		v_SpammyText = CreateConVar("sm_smoke_helptext_handler", "0", "Sets what text to print", 0, true, 0.0, true, 3.0);
		
		//e-z fix!
		decl String:game[32];
		GetGameFolderName(game, sizeof(game));
		if(StrEqual(game, "tf"))
		{
			HookEvent("post_inventory_application", EventInventoryApplication,  EventHookMode_Post);
		}
		else if(!StrEqual(game, "tf"))
		{
			HookEvent("player_spawn", EventInventoryApplication,  EventHookMode_Post);
		}
		
		LoadTranslations("common.phrases");
}

public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new DefaultSmokes = GetConVarInt(v_SmokesPerPlayer);
	if (DefaultSmokes > g_SmokeCarry[client])
	{
		g_SmokeCarry[client] = DefaultSmokes;
	}
	if (DefaultSmokes > 0 && GetConVarInt(v_SpammyText) == 0)
	{
		PrintToChat(client,"[SmokeBomb] you now have %i SmokeBombs! Type !smokebomb to use one!", g_SmokeCarry[client])
	}
}

public Action:GiveSmoke(client,args)
{	
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: sm_givesmoke <client> <quantity>");
		return Plugin_Handled;
	}
	
	//Create strings
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	//Get target arg
	GetCmdArg(1, buffer, sizeof(buffer));
	
	//Process
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	decl String:StrQuantity[32];
	GetCmdArg(2, StrQuantity, sizeof(StrQuantity));
	new BombQuantity = StringToInt(StrQuantity)
	
	for (new i = 0; i < target_count; i ++)
	{	
		g_SmokeCarry[target_list[i]] = BombQuantity;
		ReplyToCommand(client,"[SmokeBomb] You gave %N %i SmokeBombs!", target_list[i], BombQuantity)
		PrintToChat(target_list[i],"[SmokeBomb] An Admin has given you %i SmokeBombs! Type !smokebomb to use one!", BombQuantity)
	}
	
	return Plugin_Handled;
}

public Action:CMDSmoke(client,args)
{	
	if (IsPlayerAlive(client))
	{
		if (g_SmokeCarry[client] > 0)
		{
			CreateSmoke(client);
			g_SmokeCarry[client] = g_SmokeCarry[client] - 1;
			if (GetConVarInt(v_SpammyText) < 2)
			{
				PrintToChat(client,"[SmokeBomb] You have used a smoke bomb and have %i left!", g_SmokeCarry[client])
			}
		}
		else
		{
			if (GetConVarInt(v_SpammyText) < 3)
			{
				PrintToChat(client,"[SmokeBomb] You are out of SmokeBombs: Go to a resupply to get more!")
			}
		}
	}
	return Plugin_Handled;
}

CreateSmoke(target)
{
	if(target>0 && IsValidEdict(target) && IsClientInGame(target) && IsPlayerAlive(target))
	{
		//new PTSteam=CreateEntityByName("env_steam");
		new SmokeEnt = CreateEntityByName("env_smokestack");
		
		new Float:location[3]
		GetClientAbsOrigin(target, location)
	
		new String:originData[64];
		Format(originData, sizeof(originData), "%f %f %f", location[0], location[1], location[2]);
		
		//Setup smoke color now 300% more complex!
		//new String:SmokeColor[128]
		//GetConVarString(v_SmokeColor, SmokeColor, sizeof(SmokeColor))
		//---------------------------- Begin --------------------------------------
		new ColorPickr = GetConVarInt(v_SmokeColorHandler);
		new String:SmokeColor[128]
		
		if (ColorPickr == 1)
		{
			GetConVarString(v_SmokeColor, SmokeColor, sizeof(SmokeColor))
			//Yay! That was easy!
		}
		else if (ColorPickr == 2)
		{
			//get client team and choose color: red=2 blue=3
			new teamid = GetClientTeam(target)
			if (teamid == 2)
			{
				GetConVarString(v_SmokeColorTeam2, SmokeColor, sizeof(SmokeColor))
			}
			else
			{
				GetConVarString(v_SmokeColorTeam3, SmokeColor, sizeof(SmokeColor))
			}
			//Yay! copypasta from my bubble shield!
		}
		else if (ColorPickr == 3)
		{
			new red = GetRandomInt(1, 255);
			new green = GetRandomInt(1, 255);
			new blue = GetRandomInt(1, 255);
			Format(SmokeColor, sizeof(SmokeColor), "%i %i %i", red, green, blue);
			//Yay! copypasta from strontiumdog's gas plugin! :P
		}
		
		//----------------------------- End ---------------------------------------
		
		//Setup smoke time
		new Float:delay = GetConVarFloat(v_SmokeTime);
		
		//Setup smoke transparency
		new String:SmokeTransparency[32]
		GetConVarString(v_SmokeTransparency, SmokeTransparency, sizeof(SmokeTransparency))
		
		//Setup smoke density
		new String:SmokeDensity[32]
		GetConVarString(v_SmokeDensity, SmokeDensity, sizeof(SmokeDensity))
		
		if(SmokeEnt)
		{
			// Create the Smoke
			new String:SName[128];
			Format(SName, sizeof(SName), "Smoke%i", target);
			DispatchKeyValue(SmokeEnt,"targetname", SName);
			DispatchKeyValue(SmokeEnt,"Origin", originData);
			DispatchKeyValue(SmokeEnt,"BaseSpread", "100");
			DispatchKeyValue(SmokeEnt,"SpreadSpeed", "70");
			DispatchKeyValue(SmokeEnt,"Speed", "80");
			DispatchKeyValue(SmokeEnt,"StartSize", "200");
			DispatchKeyValue(SmokeEnt,"EndSize", "2");
			DispatchKeyValue(SmokeEnt,"Rate", SmokeDensity);
			DispatchKeyValue(SmokeEnt,"JetLength", "400");
			DispatchKeyValue(SmokeEnt,"Twist", "20"); 
			DispatchKeyValue(SmokeEnt,"RenderColor", SmokeColor); //red green blue
			DispatchKeyValue(SmokeEnt,"RenderAmt", SmokeTransparency);
			DispatchKeyValue(SmokeEnt,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
			
			DispatchSpawn(SmokeEnt);
			AcceptEntityInput(SmokeEnt, "TurnOn");
			
			//Start timer to stop smoke
			//new Float:delay = 5.0;
			new Handle:pack
			CreateDataTimer(delay, Timer_KillSmoke, pack)
			WritePackCell(pack, SmokeEnt);
			
			//Start timer to remove smoke
			new Float:longerdelay = 5.0 + delay;
			new Handle:pack2
			CreateDataTimer(longerdelay, Timer_StopSmoke, pack2)
			WritePackCell(pack2, SmokeEnt);
		}
	}
}

public Action:Timer_KillSmoke(Handle:timer, Handle:pack)
{	
	ResetPack(pack)
	new SmokeEnt = ReadPackCell(pack)
	
	StopSmokeEnt(SmokeEnt);
}

StopSmokeEnt(target)
{

	if (IsValidEntity(target))
	{
		AcceptEntityInput(target, "TurnOff");
	}
}

public Action:Timer_StopSmoke(Handle:timer, Handle:pack)
{	
	ResetPack(pack)
	new SmokeEnt = ReadPackCell(pack)
	
	RemoveSmokeEnt(SmokeEnt);
}

RemoveSmokeEnt(target)
{
	if (IsValidEntity(target))
	{
		AcceptEntityInput(target, "Kill");
	}
}