//Ultimate Killer 1.0 by [GR]Nick

//INCLUDE TO RUN PLUGIN
#include <sourcemod>
#include <sdktools>

//NEW INFORMATION
//SOUNDS
#define KILL_EXPLODE1 "ambient/explosions/explode_8.wav"
#define KILL_EXPLODE2 "ambient/explosions/explode_7.wav"
#define KILL_EXPLODE3 "ambient/explosions/explode_5.wav"
#define KILL_EXPLODE4 "ambient/explosions/explode_2.wav"
#define KILL_EXPLODE5 "ambient/explosions/explode_1.wav"

//MATERIALS
new kill_Smoke;
new kill_LaserMaterial;

//TOGGLE
new Handle:kill_Toggle = INVALID_HANDLE;

//LASER
new Handle:kill_LaserToggle = INVALID_HANDLE;
new Handle:kill_LaserWidth = INVALID_HANDLE;
new Handle:kill_LaserNoise = INVALID_HANDLE;
new Handle:kill_LaserRed = INVALID_HANDLE;
new Handle:kill_LaserGreen = INVALID_HANDLE;
new Handle:kill_LaserBlue = INVALID_HANDLE;

//SPARKS
new Handle:kill_SparkToggle = INVALID_HANDLE;
new Handle:kill_SparkSize = INVALID_HANDLE;

//SMOKE
new Handle:kill_SmokeToggle = INVALID_HANDLE;
new Handle:kill_SmokeSize = INVALID_HANDLE;
new Handle:kill_SmokeRadius = INVALID_HANDLE;
new Handle:kill_SmokeMagnitude = INVALID_HANDLE;

//EXPLODE SOUND
new Handle:kill_ExplodeSound = INVALID_HANDLE;

//------------------------------------------------------------------------------------------------
//PLUGIN INFORMATION
//------------------------------------------------------------------------------------------------

public Plugin:myinfo =
{
	name = "Ultimate Killer",
	author = "[GR]Nick_6893{A}",
	description = "Ultimate way to kill a person.",
	version = "1.0",
	url = "www.sourcemod.net"
}

//------------------------------------------------------------------------------------------------
//COMMANDS AND CONVARS
//------------------------------------------------------------------------------------------------

public OnPluginStart()
{
	//COMMANDS
	RegAdminCmd("sm_killcfg", Command_KillCFG, ADMFLAG_BAN, "Reload the config file for killer plugin.");
	RegAdminCmd("sm_kill", Command_Kill, ADMFLAG_SLAY, "Kills a person.");
	RegAdminCmd("sm_killmenu", Command_KillMenu, ADMFLAG_BAN, "Shows a menu of the settings used.");

	//CONVARS
	kill_Toggle = CreateConVar("sm_killplugin", "1", "[KILLER] Activate plugin. 0 = off, 1 = on", FCVAR_PLUGIN);
	kill_LaserToggle = CreateConVar("sm_kill_laser", "1", "[KILLER] Turn on/off the laser part. 0 = off, 1 = on", FCVAR_PLUGIN);
	kill_LaserWidth = CreateConVar("sm_kill_laser_width", "5", "[KILLER] Sets width of the laser.", FCVAR_PLUGIN);
	kill_LaserNoise = CreateConVar("sm_kill_laser_noise", "5", "[KILLER] Sets noise of the laser.", FCVAR_PLUGIN);
	kill_LaserRed = CreateConVar("sm_kill_laserred", "255", "[KILLER] Sets how much red in a laser. 0 - 255", FCVAR_PLUGIN);
	kill_LaserGreen = CreateConVar("sm_kill_lasergreen", "0", "[KILLER] Sets how much green in a laser. 0 - 255", FCVAR_PLUGIN);
	kill_LaserBlue = CreateConVar("sm_kill_laserblue", "0", "[KILLER] Sets how much blue in a laser. 0 - 255", FCVAR_PLUGIN);
	kill_SparkToggle = CreateConVar("sm_kill_spark", "1", "[KILLER] Turn on/off the spark part. 0 = off, 1 = on", FCVAR_PLUGIN);
	kill_SparkSize = CreateConVar("sm_kill_spark_size", "5", "[KILLER] Sets how big the sparks will be.", FCVAR_PLUGIN);
	kill_SmokeToggle = CreateConVar("sm_kill_smoke", "1", "[KILLER] Turn on/off the smoke part. 0 = off, 1 = on", FCVAR_PLUGIN);
	kill_SmokeSize = CreateConVar("sm_kill_smoke_size", "10", "[KILLER] Sets how big the smoke will be.", FCVAR_PLUGIN);
	kill_SmokeRadius = CreateConVar("sm_kill_smoke_radius", "100", "[KILLER] Sets how big the smoke radius will be.", FCVAR_PLUGIN);
	kill_SmokeMagnitude = CreateConVar("sm_kill_smoke_magnitude", "5000", "[KILLER] Sets how big the smoke radius will be.", FCVAR_PLUGIN);
	kill_ExplodeSound = CreateConVar("sm_kill_sound", "1", "[KILLER] Sound to be used when person is exploded. 1 - 5 sound types.", FCVAR_PLUGIN);
	
	AutoExecConfig(true, "KillerConfig");
}

//------------------------------------------------------------------------------------------------
//FORCE THE CONFIG TO RELOAD. (USED IF IT DIDN"T LOAD RIGHT OR GO BACK TO YOUR ORIGINAL SETTINGS. MAY NOT WORK. IDK)
//------------------------------------------------------------------------------------------------

public Action:Command_KillCFG(Client, Arguments)
{
	PrintToConsole(Client, "[SM] Executing KillerConfig...");
	PrintToConsole(Client, "[SM] KillerConfig executed sucessfully.");
	ServerCommand("sm plugins reload Killer");
	return Plugin_Handled;
}

//------------------------------------------------------------------------------------------------
//PRECACHE SOUNDS AND MATERIALS
//------------------------------------------------------------------------------------------------

public OnMapStart()
{
	//SOUNDS
	PrecacheSound(KILL_EXPLODE1, true);
	PrecacheSound(KILL_EXPLODE2, true);
	PrecacheSound(KILL_EXPLODE3, true);
	PrecacheSound(KILL_EXPLODE4, true);
	PrecacheSound(KILL_EXPLODE5, true);

	//MATERIALS
	kill_Smoke = PrecacheModel("effects/redflare.vmt");
	kill_LaserMaterial = PrecacheModel("materials/sprites/laserbeam.vmt");
}

//------------------------------------------------------------------------------------------------
//FINDING PERSON AND STARTING EFFECTS - START OF PLUGIN
//------------------------------------------------------------------------------------------------

public Action:Command_Kill(Client, Arguments)
{
	//CHECKING IF PLUGIN IS ACTIVATED
	new Activated = GetConVarInt(kill_Toggle);
	if (Activated > 0)
	{
		//FINDING TARGET - PERSON
		if(Arguments < 1)
		{
			PrintToConsole(Client, "[SM] Usage: sm_kill <Name>");
			return Plugin_Handled;
		}
		new String:Player_Name[32], Max, Target = -1;
		GetCmdArg(1, Player_Name, sizeof(Player_Name));
		Max = GetMaxClients();
		for(new i=1; i <= Max; i++)
		{
			if(!IsClientConnected(i))
				continue;
			new String:Other[32];
			GetClientName(i, Other, sizeof(Other));
			if(StrContains(Other, Player_Name, false) != -1)
				Target = i;
		}
		if(Target == -1)
		{
			PrintToConsole(Client, "[SM] Could not kill client %s.", Player_Name);
			return Plugin_Handled;
		}

		//FREEZE PLAYER
		SetEntityMoveType(Target, MOVETYPE_NONE);
		SetEntityMoveType(Client, MOVETYPE_NONE);

		//LASER
		new LaserToggle = GetConVarInt(kill_LaserToggle);
		if (LaserToggle > 0)
		{
			new String:Execute[32];
			GetClientName(Target, Execute, 32);
			SetHudTextParams(0.05, 0.015, 2.5, 255, 0, 0, 255, 0, 2.5, 0.1, 0.2);
			ShowHudText(Client, -1, "Executing %s Immediately.", Execute);

			decl Float:Start[3];
			GetClientAbsOrigin(Client, Start);

			decl Float:End[3];
			GetClientAbsOrigin(Target, End);

			new Renderred = GetConVarInt(kill_LaserRed);
			new Rendergreen = GetConVarInt(kill_LaserGreen);
			new Renderblue = GetConVarInt(kill_LaserBlue);
			new BeamColor[4];
			BeamColor[0] = GetConVarInt(kill_LaserRed);
			BeamColor[1] = GetConVarInt(kill_LaserGreen);
			BeamColor[2] = GetConVarInt(kill_LaserBlue);
			BeamColor[3] = 255
			new Width = GetConVarInt(kill_LaserWidth);
			new Noise = GetConVarInt(kill_LaserNoise);
			SetEntityRenderColor(Target, Renderred, Rendergreen, Renderblue, 150);
			SetEntityHealth(Target, 100);
			TE_SetupBeamPoints(Start, End, kill_LaserMaterial, 0, 0, 50, 3.3, float(Width), float(Width), 0, float(Noise), BeamColor, 0);
			TE_SendToAll(0.1);
		}

		//TIMERS FOR SPECIAL EFFECTS IF MODE IS ON 1
		new SparkToggle = GetConVarInt(kill_SparkToggle);
		if (SparkToggle > 0)
		{
			CreateTimer(0.1, Spark, Target);
		}

		new SmokeToggle = GetConVarInt(kill_SmokeToggle);
		if (SmokeToggle > 0)
		{
			CreateTimer(3.5, Smoke, Target);
		}
		//MAKING SURE PLAYER IS DEFINITELY FROZEN!!
		SetEntityMoveType(Target, MOVETYPE_NONE);
		SetEntityMoveType(Client, MOVETYPE_NONE);
		CreateTimer(3.4, Unfreeze, Client);
		CreateTimer(3.5, Goodby, Target);
		return Plugin_Handled;
	}
	if (Activated < 1)
	{
		PrintToChat(Client, "[SM] Owner has not activated the plugin.");
	}
	return Plugin_Handled;
}

//------------------------------------------------------------------------------------------------
//SPARK EFFECT
//------------------------------------------------------------------------------------------------

public Action:Spark(Handle:Timer, any:Target)
{
	//SPARKS
	new SparkSize = GetConVarInt(kill_SparkSize);
	decl Float:Origin1[3];
	GetClientAbsOrigin(Target, Origin1);
	TE_SetupSparks(Origin1, NULL_VECTOR, SparkSize, SparkSize);
	TE_SendToAll(0.1);
	TE_SetupSparks(Origin1, NULL_VECTOR, SparkSize, SparkSize);
	TE_SendToAll(0.5);
	TE_SetupSparks(Origin1, NULL_VECTOR, SparkSize, SparkSize);
	TE_SendToAll(1.0);
	TE_SetupSparks(Origin1, NULL_VECTOR, SparkSize, SparkSize);
	TE_SendToAll(1.5);
	TE_SetupSparks(Origin1, NULL_VECTOR, SparkSize, SparkSize);
	TE_SendToAll(2.0);
	TE_SetupSparks(Origin1, NULL_VECTOR, SparkSize, SparkSize);
	TE_SendToAll(2.25);
	SetEntityHealth(Target, 25);
	return Plugin_Handled;
}

//------------------------------------------------------------------------------------------------
//SMOKE EFFECT
//------------------------------------------------------------------------------------------------

public Action:Smoke(Handle:Timer, any:Target)
{
	//SMOKE EFFECT
	new SmokeSize = GetConVarInt(kill_SmokeSize);
	new SmokeRadius = GetConVarInt(kill_SmokeRadius);
	new SmokeMagnitude = GetConVarInt(kill_SmokeMagnitude);
	decl Float:Origin2[3];
	GetClientAbsOrigin(Target, Origin2);
	TE_SetupExplosion(Origin2, kill_Smoke, float(SmokeSize), 1, 0, SmokeRadius, SmokeMagnitude);
	TE_SendToAll();
	return Plugin_Handled;
}

//------------------------------------------------------------------------------------------------
//UNFREEZING ADMIN
//------------------------------------------------------------------------------------------------

public Action:Unfreeze(Handle:Timer, any:Client)
{
	SetEntityMoveType(Client, MOVETYPE_WALK);
}

//------------------------------------------------------------------------------------------------
//SLAYNG AND MESSAGE WITH SOUND - END OF PLUGIN
//------------------------------------------------------------------------------------------------

public Action:Goodby(Handle:Timer, any:Target)
{
	//SOUND
	decl Float:Origin3[3];
	GetClientAbsOrigin(Target, Origin3);
	new ExplodeSound = GetConVarInt(kill_ExplodeSound);
	if (ExplodeSound > 0)
	{
		EmitAmbientSound(KILL_EXPLODE1, Origin3, Target, SNDLEVEL_RAIDSIREN);
	}
	if (ExplodeSound > 1)
	{
		EmitAmbientSound(KILL_EXPLODE2, Origin3, Target, SNDLEVEL_RAIDSIREN);
	}
	if (ExplodeSound > 2)
	{
		EmitAmbientSound(KILL_EXPLODE3, Origin3, Target, SNDLEVEL_RAIDSIREN);
	}
	if (ExplodeSound > 3)
	{
		EmitAmbientSound(KILL_EXPLODE4, Origin3, Target, SNDLEVEL_RAIDSIREN);
	}
	if (ExplodeSound > 4)
	{
		EmitAmbientSound(KILL_EXPLODE5, Origin3, Target, SNDLEVEL_RAIDSIREN);
	}

	//NAME AND FORCE KILL	
	new String:Killname[32];
	GetClientName(Target, Killname, 32);
	PrintToChatAll("[SM] Killed %s.", Killname);
	SetEntityRenderColor(Target, 255, 255, 255, 150);
	ForcePlayerSuicide(Target);
	return Plugin_Handled;
}

//------------------------------------------------------------------------------------------------
//KILL MENU - CUSTOMIZE CONVARS WITH A MENU INSTEAD OF TYPING!
//------------------------------------------------------------------------------------------------

public Action:Command_KillMenu(Client, Arguments)
{
	//PRINTING TO ADMIN
	PrintToChat(Client, "[SM] Press <Escape> to access the kill menu.");
	
	//DRAWING MENU
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Killer Plugin v1.0 Settings:", false);
	DrawPanelItem(Panel, "Laser");
	DrawPanelItem(Panel, "Sparks");
	DrawPanelItem(Panel, "Smoke");
	DrawPanelItem(Panel, "Sounds");
	DrawPanelItem(Panel, "Toggle");
	SendPanelToClient(Panel, Client, MainMenu, 30);
	CloseHandle(Panel);
}

public MainMenu(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	if (Click == MenuAction_Select)
	{
		//Clicked Button:
		if(Parameter2 == 1)
		{
			LaserSettings(Parameter1);
		}
		if(Parameter2 == 2)
		{
			SparkSettings(Parameter1);
		}
		if(Parameter2 == 3)
		{
			SmokeSettings(Parameter1);
		}
		if(Parameter2 == 4)
		{
			SoundSettings(Parameter1);
		}
		if(Parameter2 == 5)
		{
			Toggle(Parameter1);
		}
	}
}

//------------------------------------------------------------------------------------------------
//KILL MENU - LASER MENU SECTION
//------------------------------------------------------------------------------------------------

public LaserSettings(Client)
{
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Laser Settings:", false);
	DrawPanelItem(Panel, "Colors");
	DrawPanelItem(Panel, "Width");
	DrawPanelItem(Panel, "Noise");
	SendPanelToClient(Panel, Client, LaserSet, 30);
	CloseHandle(Panel);
}

public LaserSet(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	if (Click == MenuAction_Select)
	{
		if(Parameter2 == 1)
		{
			LaserColors(Parameter1);
		}
		if(Parameter2 == 2)
		{
			LaserWidth(Parameter1);
		}
		if(Parameter2 == 3)
		{
			LaserNoise(Parameter1);
		}
	}
}

public LaserColors(Client)
{
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Laser Color:", false);
	DrawPanelItem(Panel, "Red");
	DrawPanelItem(Panel, "Yellow");
	DrawPanelItem(Panel, "Green");
	DrawPanelItem(Panel, "Blue");
	DrawPanelItem(Panel, "Orange");
	DrawPanelItem(Panel, "Purple");
	SendPanelToClient(Panel, Client, LaserColorSet, 30);
	CloseHandle(Panel);
}

public LaserColorSet(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	if (Click == MenuAction_Select)
	{
		if(Parameter2 == 1)
		{
			ServerCommand("sm_kill_laserred 255");
			ServerCommand("sm_kill_lasergreen 0");
			ServerCommand("sm_kill_laserblue 0");
		}
		if(Parameter2 == 2)
		{
			ServerCommand("sm_kill_laserred 255");
			ServerCommand("sm_kill_lasergreen 255");
			ServerCommand("sm_kill_laserblue 0");
		}
		if(Parameter2 == 3)
		{
			ServerCommand("sm_kill_laserred 0");
			ServerCommand("sm_kill_lasergreen 255");
			ServerCommand("sm_kill_laserblue 0");
		}
		if(Parameter2 == 4)
		{
			ServerCommand("sm_kill_laserred 0");
			ServerCommand("sm_kill_lasergreen 0");
			ServerCommand("sm_kill_laserblue 255");
		}
		if(Parameter2 == 5)
		{
			ServerCommand("sm_kill_laserred 255");
			ServerCommand("sm_kill_lasergreen 165");
			ServerCommand("sm_kill_laserblue 0");
		}
		if(Parameter2 == 6)
		{
			ServerCommand("sm_kill_laserred 160");
			ServerCommand("sm_kill_lasergreen 32");
			ServerCommand("sm_kill_laserblue 240");
		}
	}
}

public LaserWidth(Client)
{
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Laser Width:", false);
	DrawPanelItem(Panel, "Width 1");
	DrawPanelItem(Panel, "Width 2");
	DrawPanelItem(Panel, "Width 3");
	DrawPanelItem(Panel, "Width 4");
	DrawPanelItem(Panel, "Width 5");
	DrawPanelItem(Panel, "Width 8");
	SendPanelToClient(Panel, Client, LaserWidthSet, 30);
	CloseHandle(Panel);
}

public LaserWidthSet(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	if (Click == MenuAction_Select)
	{
		if(Parameter2 == 1)
		{
			ServerCommand("sm_kill_laser_width 1");
		}
		if(Parameter2 == 2)
		{
			ServerCommand("sm_kill_laser_width 2");
		}
		if(Parameter2 == 3)
		{
			ServerCommand("sm_kill_laser_width 3");
		}
		if(Parameter2 == 4)
		{
			ServerCommand("sm_kill_laser_width 4");
		}
		if(Parameter2 == 5)
		{
			ServerCommand("sm_kill_laser_width 5");
		}
		if(Parameter2 == 6)
		{
			ServerCommand("sm_kill_laser_width 8");
		}
	}
}

public LaserNoise(Client)
{
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Laser Noise:", false);
	DrawPanelItem(Panel, "Noise 1");
	DrawPanelItem(Panel, "Noise 2");
	DrawPanelItem(Panel, "Noise 3");
	DrawPanelItem(Panel, "Noise 4");
	DrawPanelItem(Panel, "Noise 5");
	DrawPanelItem(Panel, "Noise 10");
	SendPanelToClient(Panel, Client, LaserNoiseSet, 30);
	CloseHandle(Panel);
}

public LaserNoiseSet(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	if (Click == MenuAction_Select)
	{
		if(Parameter2 == 1)
		{
			ServerCommand("sm_kill_laser_noise 1");
		}
		if(Parameter2 == 2)
		{
			ServerCommand("sm_kill_laser_noise 2");
		}
		if(Parameter2 == 3)
		{
			ServerCommand("sm_kill_laser_noise 3");
		}
		if(Parameter2 == 4)
		{
			ServerCommand("sm_kill_laser_noise 4");
		}
		if(Parameter2 == 5)
		{
			ServerCommand("sm_kill_laser_noise 5");
		}
		if(Parameter2 == 6)
		{
			ServerCommand("sm_kill_laser_noise 10");
		}
	}
}

//------------------------------------------------------------------------------------------------
//KILL MENU - SPARKS MENU SECTION
//------------------------------------------------------------------------------------------------

public SparkSettings(Client)
{
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Spark Settings:", false);
	DrawPanelItem(Panel, "Size");
	SendPanelToClient(Panel, Client, SparkSet, 30);
	CloseHandle(Panel);
}

public SparkSet(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	if(Parameter2 == 1)
	{
		SparkSizeSet(Parameter1);
	}
}

public SparkSizeSet(Client)
{
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Spark Size:", false);
	DrawPanelItem(Panel, "Size 1");
	DrawPanelItem(Panel, "Size 2");
	DrawPanelItem(Panel, "Size 3");
	DrawPanelItem(Panel, "Size 4");
	DrawPanelItem(Panel, "Size 5");
	DrawPanelItem(Panel, "Size 8");
	SendPanelToClient(Panel, Client, SparkSize2, 30);
	CloseHandle(Panel);
}

public SparkSize2(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	if (Click == MenuAction_Select)
	{
		if(Parameter2 == 1)
		{
			ServerCommand("sm_kill_spark_size 1");
		}
		if(Parameter2 == 2)
		{
			ServerCommand("sm_kill_spark_size 2");
		}
		if(Parameter2 == 3)
		{
			ServerCommand("sm_kill_spark_size 3");
		}
		if(Parameter2 == 4)
		{
			ServerCommand("sm_kill_spark_size 4");
		}
		if(Parameter2 == 5)
		{
			ServerCommand("sm_kill_spark_size 5");
		}
		if(Parameter2 == 6)
		{
			ServerCommand("sm_kill_spark_size 8");
		}
	}
}

//------------------------------------------------------------------------------------------------
//KILL MENU - SMOKE MENU SECTION
//------------------------------------------------------------------------------------------------

public SmokeSettings(Client)
{
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Smoke Settings:", false);
	DrawPanelItem(Panel, "Size");
	DrawPanelItem(Panel, "Radius");
	DrawPanelItem(Panel, "Magnitude");
	SendPanelToClient(Panel, Client, SmokeSet, 30);
	CloseHandle(Panel);
}

public SmokeSet(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	if (Click == MenuAction_Select)
	{
		if(Parameter2 == 1)
		{
			SmokeSize2(Parameter1);
		}
		if(Parameter2 == 2)
		{
			SmokeRadius2(Parameter1);
		}
		if(Parameter2 == 3)
		{
			SmokeMagnitude2(Parameter1);
		}
	}
}

public SmokeSize2(Client)
{
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Smoke Size:", false);
	DrawPanelItem(Panel, "Size 5");
	DrawPanelItem(Panel, "Size 10");
	DrawPanelItem(Panel, "Size 15");
	DrawPanelItem(Panel, "Size 20");
	SendPanelToClient(Panel, Client, SmokeSizeSet, 30);
	CloseHandle(Panel);
}

public SmokeSizeSet(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	if (Click == MenuAction_Select)
	{
		if(Parameter2 == 1)
		{
			ServerCommand("sm_kill_smoke_size 5");
		}
		if(Parameter2 == 2)
		{
			ServerCommand("sm_kill_smoke_size 10");
		}
		if(Parameter2 == 3)
		{
			ServerCommand("sm_kill_smoke_size 15");
		}
		if(Parameter2 == 4)
		{
			ServerCommand("sm_kill_smoke_size 20");
		}
	}
}

public SmokeRadius2(Client)
{
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Smoke Radius:", false);
	DrawPanelItem(Panel, "Radius 50");
	DrawPanelItem(Panel, "Radius 75");
	DrawPanelItem(Panel, "Radius 100");
	DrawPanelItem(Panel, "Radius 150");
	SendPanelToClient(Panel, Client, SmokeRadiusSet, 30);
	CloseHandle(Panel);
}

public SmokeRadiusSet(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	if (Click == MenuAction_Select)
	{
		if(Parameter2 == 1)
		{
			ServerCommand("sm_kill_smoke_radius 50");
		}
		if(Parameter2 == 2)
		{
			ServerCommand("sm_kill_smoke_radius 75");
		}
		if(Parameter2 == 3)
		{
			ServerCommand("sm_kill_smoke_radius 100");
		}
		if(Parameter2 == 4)
		{
			ServerCommand("sm_kill_smoke_radius 150");
		}
	}
}

public SmokeMagnitude2(Client)
{
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Smoke Magnitude:", false);
	DrawPanelItem(Panel, "Radius 500");
	DrawPanelItem(Panel, "Radius 1000");
	DrawPanelItem(Panel, "Radius 1500");
	DrawPanelItem(Panel, "Radius 2000");
	DrawPanelItem(Panel, "Radius 3000");
	DrawPanelItem(Panel, "Radius 5000");
	SendPanelToClient(Panel, Client, SmokeMagnitudeSet, 30);
	CloseHandle(Panel);
}

public SmokeMagnitudeSet(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	if (Click == MenuAction_Select)
	{
		if(Parameter2 == 1)
		{
			ServerCommand("sm_kill_smoke_magnitude 500");
		}
		if(Parameter2 == 2)
		{
			ServerCommand("sm_kill_smoke_magnitude 1000");
		}
		if(Parameter2 == 3)
		{
			ServerCommand("sm_kill_smoke_magnitude 1500");
		}
		if(Parameter2 == 4)
		{
			ServerCommand("sm_kill_smoke_magnitude 2000");
		}
		if(Parameter2 == 5)
		{
			ServerCommand("sm_kill_smoke_magnitude 3000");
		}
		if(Parameter2 == 6)
		{
			ServerCommand("sm_kill_smoke_magnitude 5000");
		}
	}
}

//------------------------------------------------------------------------------------------------
//KILL MENU - SOUND MENU SECTION
//------------------------------------------------------------------------------------------------

public SoundSettings(Client)
{
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Sound Type Use:", false);
	DrawPanelItem(Panel, "Sound 1");
	DrawPanelItem(Panel, "Sound 2");
	DrawPanelItem(Panel, "Sound 3");
	DrawPanelItem(Panel, "Sound 4");
	DrawPanelItem(Panel, "Sound 5");
	SendPanelToClient(Panel, Client, SoundTypeSet, 30);
	CloseHandle(Panel);
}

public SoundTypeSet(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	if (Click == MenuAction_Select)
	{
		if(Parameter2 == 1)
		{
			ServerCommand("sm_kill_sound 1");
		}
		if(Parameter2 == 2)
		{
			ServerCommand("sm_kill_sound 2");
		}
		if(Parameter2 == 3)
		{
			ServerCommand("sm_kill_sound 3");
		}
		if(Parameter2 == 4)
		{
			ServerCommand("sm_kill_sound 4");
		}
		if(Parameter2 == 5)
		{
			ServerCommand("sm_kill_sound 5");
		}
	}
}


//------------------------------------------------------------------------------------------------
//KILL MENU - TOGGLE MENU SECTION
//------------------------------------------------------------------------------------------------

public Toggle(Client)
{
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Toggle Effects:", false);
	DrawPanelItem(Panel, "Laser");
	DrawPanelItem(Panel, "Spark");
	DrawPanelItem(Panel, "Smoke");
	SendPanelToClient(Panel, Client, Toggleset, 30);
	CloseHandle(Panel);
}


public Toggleset(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	if (Click == MenuAction_Select)
	{
		if(Parameter2 == 1)
		{
			LaserTog(Parameter1);
		}
		if(Parameter2 == 2)
		{
			SparkTog(Parameter1);
		}
		if(Parameter2 == 3)
		{
			SmokeTog(Parameter1);
		}
	}
}

public LaserTog(Client)
{
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Laser Toggle:", false);
	DrawPanelItem(Panel, "Turnon");
	DrawPanelItem(Panel, "Turnoff");
	SendPanelToClient(Panel, Client, ToggleLaserset, 30);
	CloseHandle(Panel);
}

public ToggleLaserset(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	if (Click == MenuAction_Select)
	{
		if(Parameter2 == 1)
		{
			ServerCommand("sm_kill_laser 1");
		}
		if(Parameter2 == 2)
		{
			ServerCommand("sm_kill_laser 0");
		}
	}
}

public SparkTog(Client)
{
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Spark Toggle:", false);
	DrawPanelItem(Panel, "Turnon");
	DrawPanelItem(Panel, "Turnoff");
	SendPanelToClient(Panel, Client, ToggleSparkset, 30);
	CloseHandle(Panel);
}

public ToggleSparkset(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	if (Click == MenuAction_Select)
	{
		if(Parameter2 == 1)
		{
			ServerCommand("sm_kill_spark 1");
		}
		if(Parameter2 == 2)
		{
			ServerCommand("sm_kill_spark 0");
		}
	}
}
public SmokeTog(Client)
{
	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Smoke Toggle:", false);
	DrawPanelItem(Panel, "Turnon");
	DrawPanelItem(Panel, "Turnoff");
	SendPanelToClient(Panel, Client, ToggleSmokeset, 30);
	CloseHandle(Panel);
}

public ToggleSmokeset(Handle:Menu, MenuAction:Click, Parameter1, Parameter2)
{
	if (Click == MenuAction_Select)
	{
		if(Parameter2 == 1)
		{
			ServerCommand("sm_kill_smoke 1");
		}
		if(Parameter2 == 2)
		{
			ServerCommand("sm_kill_smoke 0");
		}
	}
}