#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.1"

//Bools
new bool:g_bEnabled = false;

//Handles
new Handle:g_hdifficulty = INVALID_HANDLE;
new Handle:g_hGameMode = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[L4D2] Director Settings Loader",
	author = "honorcode23",
	description = "Will execute director settings, according to the server needs and difficulty",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1238667"
}

public OnPluginStart()
{
	//Left 4 dead 2 only
	decl String:game[256];
	GetGameFolderName(game, sizeof(game));
	if (!StrEqual(game, "left4dead2", false))
	{
		SetFailState("Director Loader supports Left 4 dead 2 only!");
	}
	
	//Commands
	RegAdminCmd("sm_reload_ds", Cmd_ReloadSettings, ADMFLAG_SLAY, "Forces the director to reload settings, based on difficulty");
	
	//CVARS
	CreateConVar("l4d2_director_settings_loader_version", PLUGIN_VERSION, "Version of Director Settings Loader Plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	//Get difficulty string
	g_hdifficulty = FindConVar("z_difficulty");
	HookConVarChange(g_hdifficulty, Evt_DifficultyChanged);
	
	//Game mode
	g_hGameMode = FindConVar("mp_gamemode");
	
	decl String:gamemode[56];
	GetConVarString(g_hGameMode, gamemode, sizeof(gamemode));
	if(StrEqual(gamemode, "coop") || StrEqual(gamemode, "realism"))
	{
		g_bEnabled = true;
		PrintToServer("[Director Settings] Gamemode is Coop or Realism, begin custom settings");
	}
	else
	{
		g_bEnabled = false;
		SetFailState("Director Loader supports Coop and Realism game mode only!");
		PrintToServer("[Director Settings] Gamemode is not Coop or Realism, disabling to avoid gameplay interference");
	}
}

public OnMapStart()
{
	if(g_bEnabled)
	{
		BeginControlSettings()
	}
}

BeginControlSettings()
{
	CreateTimer(15.0, timerCheckDifficulty, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	decl String:difficulty[256];
	g_hdifficulty = FindConVar("z_difficulty");
	GetConVarString(g_hdifficulty, difficulty, sizeof(difficulty));
	if(StrEqual(difficulty, "Easy"))
	{
		new flags = GetCommandFlags("script_execute");
		SetCommandFlags("script_execute", flags & ~FCVAR_CHEAT);
		CreateTimer(0.1, timerNormalFlags, flags, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("script_execute Director_Easy_Settings");
	}
	else if(StrEqual(difficulty, "Normal"))
	{
		new flags = GetCommandFlags("script_execute");
		SetCommandFlags("script_execute", flags & ~FCVAR_CHEAT);
		CreateTimer(0.1, timerNormalFlags, flags, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("script_execute Director_Normal_Settings");
	}
	else if(StrEqual(difficulty, "Hard"))
	{
		new flags = GetCommandFlags("script_execute");
		SetCommandFlags("script_execute", flags & ~FCVAR_CHEAT);
		CreateTimer(0.1, timerNormalFlags, flags, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("script_execute Director_Advanced_Settings");
	}
	else if(StrEqual(difficulty, "Impossible"))
	{
		new flags = GetCommandFlags("script_execute");
		SetCommandFlags("script_execute", flags & ~FCVAR_CHEAT);
		CreateTimer(0.1, timerNormalFlags, flags, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("script_execute Director_Expert_Settings");
	}
}

public Action:timerNormalFlags(Handle:timer, any:flags)
{
	SetCommandFlags("script_execute", flags);
}

public Action:timerCheckDifficulty(Handle:timer)
{
	decl String:difficulty[256];
	g_hdifficulty = FindConVar("z_difficulty");
	GetConVarString(g_hdifficulty, difficulty, sizeof(difficulty));
	
	if(StrEqual(difficulty, "Easy"))
	{
		new flags = GetCommandFlags("script_execute");
		SetCommandFlags("script_execute", flags & ~FCVAR_CHEAT);
		CreateTimer(0.1, timerNormalFlags, flags, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("script_execute Director_Easy_Settings");
	}
	else if(StrEqual(difficulty, "Normal"))
	{
		new flags = GetCommandFlags("script_execute");
		SetCommandFlags("script_execute", flags & ~FCVAR_CHEAT);
		CreateTimer(0.1, timerNormalFlags, flags, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("script_execute Director_Normal_Settings");
	}
	else if(StrEqual(difficulty, "Hard"))
	{
		new flags = GetCommandFlags("script_execute");
		SetCommandFlags("script_execute", flags & ~FCVAR_CHEAT);
		CreateTimer(0.1, timerNormalFlags, flags, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("script_execute Director_Advanced_Settings");
	}
	else if(StrEqual(difficulty, "Impossible"))
	{
		new flags = GetCommandFlags("script_execute");
		SetCommandFlags("script_execute", flags & ~FCVAR_CHEAT);
		CreateTimer(0.1, timerNormalFlags, flags, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("script_execute Director_Expert_Settings");
	}
	return Plugin_Continue
}

public Action:Cmd_ReloadSettings(client, args)
{
	decl String:difficulty[256];
	g_hdifficulty = FindConVar("z_difficulty");
	GetConVarString(g_hdifficulty, difficulty, sizeof(difficulty));
	
	if(StrEqual(difficulty, "Easy"))
	{
		new flags = GetCommandFlags("script_execute");
		SetCommandFlags("script_execute", flags & ~FCVAR_CHEAT);
		CreateTimer(0.1, timerNormalFlags, flags, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("script_execute Director_Easy_Settings");
	}
	else if(StrEqual(difficulty, "Normal"))
	{
		new flags = GetCommandFlags("script_execute");
		SetCommandFlags("script_execute", flags & ~FCVAR_CHEAT);
		CreateTimer(0.1, timerNormalFlags, flags, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("script_execute Director_Normal_Settings");
	}
	else if(StrEqual(difficulty, "Hard"))
	{
		new flags = GetCommandFlags("script_execute");
		SetCommandFlags("script_execute", flags & ~FCVAR_CHEAT);
		CreateTimer(0.1, timerNormalFlags, flags, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("script_execute Director_Advanced_Settings");
	}
	else if(StrEqual(difficulty, "Impossible"))
	{
		new flags = GetCommandFlags("script_execute");
		SetCommandFlags("script_execute", flags & ~FCVAR_CHEAT);
		CreateTimer(0.1, timerNormalFlags, flags, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("script_execute Director_Expert_Settings");
	}
	PrintToChat(client, "Director settings have been reloaded succesfully!");
}

public Evt_DifficultyChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StrEqual(newValue, "Easy"))
	{
		new flags = GetCommandFlags("script_execute");
		SetCommandFlags("script_execute", flags & ~FCVAR_CHEAT);
		CreateTimer(0.1, timerNormalFlags, flags, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("script_execute Director_Easy_Settings");
	}
	else if(StrEqual(newValue, "Normal"))
	{
		new flags = GetCommandFlags("script_execute");
		SetCommandFlags("script_execute", flags & ~FCVAR_CHEAT);
		CreateTimer(0.1, timerNormalFlags, flags, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("script_execute Director_Normal_Settings");
	}
	else if(StrEqual(newValue, "Hard"))
	{
		new flags = GetCommandFlags("script_execute");
		SetCommandFlags("script_execute", flags & ~FCVAR_CHEAT);
		CreateTimer(0.1, timerNormalFlags, flags, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("script_execute Director_Advanced_Settings");
	}
	else if(StrEqual(newValue, "Impossible"))
	{
		new flags = GetCommandFlags("script_execute");
		SetCommandFlags("script_execute", flags & ~FCVAR_CHEAT);
		CreateTimer(0.1, timerNormalFlags, flags, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("script_execute Director_Expert_Settings");
	}
}