#include <sourcemod>
#include <clientprefs>

new Float:MapStart;

public Plugin:myinfo = 
{
	name 		= "Map Time",
	author 		= "EGood",
	description = "Shows how long current map is running",
	version 	= "1.0.0",
	url 		= ""
}

public OnPluginStart()
{
	CreateConVar("sm_maptime_enable", "1", "Enables the plugin.", FCVAR_PLUGIN);
	AutoExecConfig(true, "sm_maptime");
	RegAdminCmd( "sm_maptime", Command_MapTime, ADMFLAG_CHAT );
}

public OnMapStart()
{
	MapStart = GetEngineTime();
}

public Action:Command_MapTime( client, args )
{

	new Enable = GetConVarInt( FindConVar( "sm_maptime_enable" ) );
	
	if (! Enable)
	{
		ReplyToCommand( client, "\x03Map Time Disable !!" );
		return Plugin_Handled;
	}

	if ( args > 0 )
	{
		ReplyToCommand(client, "\x03[SM] \x04Usage: sm_maptime");
		return Plugin_Handled;
	}
	
	//-----------------------------------------
	// Calculate the Map Time!
	//-----------------------------------------
	
	new Float:TheTime 	= GetEngineTime();
	new MapTime 		= RoundToZero( TheTime - MapStart );
	
	new DaysPassed		= MapTime / 60 / 60 / 24;
	new HoursPassed		= MapTime / 60 / 60;
	new MinutesPassed	= MapTime / 60;
	new SecondsPassed	= MapTime % 60;
	
	PrintToChat( client, "\x03Map-Time Is :\x04\n%d days\n%d hours\n%d minutes\n%d seconds", DaysPassed, HoursPassed, MinutesPassed, SecondsPassed );	
	
	return Plugin_Handled;
}