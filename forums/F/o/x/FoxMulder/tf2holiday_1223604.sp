#include <sourcemod>
#include <tf2>

#define PLUGIN_VERSION "0.91"

new Handle:c_Holiday	= INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[TF2] Holiday",
	author = "Fox",
	description = "Set the games holiday",
	version = "1.0",
	url = "www.rtdgaming.com"
}

public OnPluginStart()
{
	CreateConVar("sm_tf2holiday_version", PLUGIN_VERSION, "[TF2] Holiday", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	c_Holiday = CreateConVar("sm_tf2holiday",		"2",	"<0/1/2/3> 0=Disabled/1=None/2=Halloween/3=Birthday");
}

public Action:TF2_OnGetHoliday(&TFHoliday:holiday)
{
	//TFHoliday_None = 1,
	//TFHoliday_Halloween = 2,
	//TFHoliday_Birthday = 3
	new settingsHoliday = GetConVarInt(c_Holiday);
	
	switch(settingsHoliday)
	{
		case 1:
		{
			holiday = TFHoliday_None;
			return Plugin_Changed;
		}
		case 2:
		{
			holiday = TFHoliday_Halloween;
			return Plugin_Changed;
		}
		case 3:
		{
			holiday = TFHoliday_Birthday;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}