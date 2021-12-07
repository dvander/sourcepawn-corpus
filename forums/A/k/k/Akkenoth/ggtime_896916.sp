#include <sourcemod>

#define GGT_V "1.2.1"

new Handle:starttime,
	Handle:stoptime,
	Handle:altmap,
	Handle:ggcommand,
	Handle:mapcycle;
new timestart,
	timestop;
new bool:altmapcycle,
	bool:altmapexist;

public Plugin:myinfo = 
{
	name = "GunGame Time",
	author = "Akkenoth",
	description = "Enables alternative mapcycle, config and gungame in defined time",
	version = GGT_V,
	url = "http://stormtroopers.ugu.pl"
}

public OnPluginStart()
{
	CreateConVar("ggtime_version", GGT_V, "Version of GunGame Time plugin", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	altmap=CreateConVar("ggtime_altmapcycle", "1", "Use alternative mapcycle (ggmapcycle.txt) or not", FCVAR_PLUGIN, true, 0, true, 1);
	starttime=CreateConVar("ggtime_starttime", "22", "Hour to start GunGame", FCVAR_PLUGIN, true, 0, true, 24);
	stoptime=CreateConVar("ggtime_stoptime", "8", "Hour to stop GunGame", FCVAR_PLUGIN, true, 0, true, 24);
	ggcommand=CreateConVar("ggtime_command", "gg_enable", "Command that enables GunGame", FCVAR_PLUGIN);
	AutoExecConfig(true, "ggtime_config", "sourcemod");
	mapcycle=FindConVar("mapcyclefile");
	timestart = GetConVarInt(starttime);
	timestop = GetConVarInt(stoptime);
	altmapcycle = GetConVarBool(altmap);
	altmapexist = FileExists("ggmapcycle.txt", false);
}

public OnMapStart()
{	
	new String:hour[4], minute[4];
	FormatTime(String:hour,4,"%H",GetTime());
	FormatTime(String:minute, 4, "%M", GetTime());
	new inthour = StringToInt(hour);
	new intmin = StringToInt(String:minute);
	intmin=60-intmin;
	
	if(timestart<timestop && inthour>=timestart && inthour<timestop) //If GunGame runs in the daytime
	{
		GunGame();
	}
	else if(timestart>timestop && inthour>=timestart || inthour<timestop) //If GunGame runs in the nighttime (like default)
	{
		GunGame();
	}
	else if((inthour+1)==timestart || (inthour-23)==timestart)
	{
		if(intmin<=GetConVarInt(FindConVar("mp_timelimit")) && altmapcycle)
		{
			SetConVarString(mapcycle, "ggmapcycle.txt", false, false); //Enable alternative mapcycle, so next map will be from gungame mapcycle
		}
	}
	else if(altmapcycle)
	{
		SetConVarString(mapcycle, "mapcycle.txt", false, false); //Disable alternative mapcycle
	}
}
GunGame()
{
	new String:command[32];
	GetConVarString(ggcommand, command, 32);
	if(altmapcycle)
	{
		if(altmapexist)
		{
			SetConVarString(mapcycle, "ggmapcycle.txt", false, false); //Enable alternative mapcycle
		}
		else
		{
			PrintToServer("The alternative mapcycle file does not exist!");
		}
	}
	if(LoadGameConfigFile("../../../cfg/sourcemod/ggtime_exec")!=INVALID_HANDLE)
	{
		ServerCommand("exec sourcemod/ggtime_exec.cfg");
	}
	ServerCommand(command);
}