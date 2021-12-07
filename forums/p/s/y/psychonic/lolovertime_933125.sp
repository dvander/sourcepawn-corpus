#include <sourcemod>
#include <sdktools>

#define VERSION "1.1"

new bool:g_istf2;

new bool:g_spamming;
new g_otdo;
new g_otcount;
new Handle:g_ottimer;
new Handle:g_cvarInterval;

new String:g_otsounds[][] = {
	"overtime/overtime1.mp3",
	"overtime/overtime2.mp3",
	"overtime/overtime3.mp3",
	"overtime/overtime4.mp3"
};

public Plugin:myinfo = {
	name = "LOL Overtime",
	author = "psychonic",
	description = "Manual overtime spam command",
	version = VERSION,
	url = "http://www.nicholashastings.com"
};

public OnPluginStart()
{
	RegAdminCmd("overtime", callback, ADMFLAG_CUSTOM6, "Spam overtime on command - overtime <count>");
	RegAdminCmd("overtimekill", otkill, ADMFLAG_CUSTOM6, "Kills current overtime spam");
	g_cvarInterval = CreateConVar("lolovertime_interval", "1.4", "Sets the number of seconds between overtime spam events", 0, true, 0.1, true, 600.0);
	CreateConVar("lolovertime_version", VERSION, "LOL Overtime version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	decl String: game_folder[64];
	GetGameFolderName(game_folder, 64);
	if (strncmp(game_folder, "tf", 2, false) == 0)
	{
		g_istf2 = true;
	}
}

public OnMapStart()
{
	g_spamming = false;
	
	if (!g_istf2)
	{
		for (new i = 0; i < 4; i++)
		{
			decl String:fullPath[PLATFORM_MAX_PATH];
			Format(fullPath, sizeof(fullPath), "sound/%s", g_otsounds[i]);
			AddFileToDownloadsTable(fullPath);
			PrecacheSound(g_otsounds[i], true);
		}
	}
}

public Action:callback(client, args)
{
	new ot;
		
	if (g_spamming)
	{
		ReplyToCommand(client, "Manual overtime spam is already occuring. Please wait %d more overtimes and try again.", (g_otcount-g_otdo));
		return Plugin_Handled;
	}
	
	if (GetCmdArgs() < 1)
	{
		ot = 1;
	}
	else
	{
		decl String:arg1[10];
		GetCmdArg(1, arg1, sizeof(arg1));
	
		if (arg1[0] == 0)
		{
			ot = 1;
		}
		else
		{
			ot = StringToInt(arg1);
		}
	}
	
	if (ot != 0)
	{
		if (ot < 0) ot = ot*-1;
		if (ot > 99)
		{
			ReplyToCommand(client, "Limiting overtime spam to 99 times");
			ot = 99;
		}
		g_otdo=ot;
		g_otcount = 0;
		g_spamming=true;
		doOvertime();
		g_ottimer = CreateTimer(GetConVarFloat(Handle:g_cvarInterval), overtime, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		ReplyToCommand(client, "Overtime spam of 0 times? WTF? Nothing to do. Also, you suck.");
	}

	
	return Plugin_Handled;
}

public Action:otkill(client, args)
{
	g_spamming = false;
	if (g_ottimer != INVALID_HANDLE)
	{
		CloseHandle(g_ottimer);
	}
	else
	{
		ReplyToCommand(client, "No overtime spam is occuring");
	}

	return Plugin_Handled;
}

public Action:overtime(Handle:timer)
{
	g_otcount++;
	if (g_otcount == g_otdo)
	{
		g_spamming = false;
		return Plugin_Stop;
	}
	doOvertime();
	
	return Plugin_Continue;
}

doOvertime()
{
	if (g_istf2)
	{
		new Handle:event = CreateEvent("overtime_nag");
		if (event != INVALID_HANDLE)
			FireEvent(event);
	}
	else
	{
		EmitSoundToAll(g_otsounds[GetRandomInt(0,3)]);
	}
}