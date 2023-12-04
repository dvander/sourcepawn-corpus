
/*
example ...configs/env_wind_settings.txt

"settings"
{
	"first"
	{
		"minwind"        "20"
		"maxwind"        "50"
		"mingust"        "100"
		"maxgust"        "250"
		"mingustdelay"   "10.0"
		"maxgustdelay"   "20.0"
		"gustduration"   "5.0"
		"gustdirchange"  "20"
	}

	"second"
	{
		"minwind"        "100"
		"maxwind"        "150"
		"mingust"        "250"
		"maxgust"        "350"
		"mingustdelay"   "10.0"
		"maxgustdelay"   "20.0"
		"gustduration"   "5.0"
		"gustdirchange"  "20"
	}
}


*/

public Plugin myinfo =
{
	name = "env_wind manipulator",
	author = "Bacardi",
	description = "Change env_wind settings during game",
	version = "21.12.2021",
	url = "https://forums.alliedmods.net/index.php"
};


#include <sdktools>


enum struct env_wind
{
	int minwind;
	int maxwind;
	int mingust;
	int maxgust;
	float mingustdelay;
	float maxgustdelay;
	float gustduration;
	int gustdirchange;
	
	void def()
	{
		this.minwind = 20;
		this.maxwind = 50;
		this.mingust = 100;
		this.maxgust = 250;
		this.mingustdelay = 10.0;
		this.maxgustdelay = 20.0;
		this.gustduration = 5.0;
		this.gustdirchange = 20;
	}
	void stop()
	{
		this.minwind = 0;
		this.maxwind = 0;
		this.mingust = 0;
		this.maxgust = 0;
		this.mingustdelay = 10.0;
		this.maxgustdelay = 20.0;
		this.gustduration = 5.0;
		this.gustdirchange = 20;
	}
}

env_wind windsettings;

KeyValues kv;

public void OnPluginStart()
{

	char kvfile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, kvfile, sizeof(kvfile), "configs/env_wind_settings.txt");

	kv = CreateKeyValues("settings");
	
	if(!kv.ImportFromFile(kvfile))
	{
		PrintToServer("%s", kvfile);
		delete kv;
	}

	RegServerCmd("sm_env_wind", cmd_env_wind);
}

public void OnConfigsExecuted()
{
	int wind = FindEntityByClassname(-1, "env_wind");
	
	if(wind == -1)
	{
		wind = CreateEntityByName("env_wind");

		if(wind == -1)
		{
			SetFailState("Can not create entity called env_wind");
		}

		DispatchKeyValue(wind, "minwind", "0");
		DispatchKeyValue(wind, "maxwind", "0");
		DispatchKeyValue(wind, "mingust", "0");
		DispatchKeyValue(wind, "maxgust", "0");
		DispatchKeyValue(wind, "mingustdelay", "10.0");
		DispatchKeyValue(wind, "maxgustdelay", "20.0");
		DispatchKeyValue(wind, "gustduration", "5.0");
		DispatchKeyValue(wind, "gustdirchange", "20");

		//CreateTimer(60.0, delay, EntIndexToEntRef(wind), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action delay(Handle timer, any data)
{
	int wind = EntRefToEntIndex(data);
	
	if(wind != -1)
	{
		AcceptEntityInput(wind, "Kill");
	}
}


public Action cmd_env_wind(int args)
{
	if(args < 1)
	{
		return Plugin_Handled;
	}

	char buffer[100];
	GetCmdArgString(buffer, sizeof(buffer));

	if(StrEqual(buffer, "default", false))
	{
		windsettings.def();
		PrintToServer("[SM] env_wind set to default");
		PrintToChatAll("[SM] env_wind set to default");
	}
	else if(StrEqual(buffer, "stop", false))
	{
		windsettings.stop();
		PrintToServer("[SM] env_wind set to stop");
		PrintToChatAll("[SM] env_wind set to stop");
	}
	else
	{
		if(kv == null) return Plugin_Handled;

		kv.Rewind();


		if(!kv.JumpToKey(buffer)) return Plugin_Handled;
		
		windsettings.minwind = kv.GetNum("minwind", 20);
		windsettings.maxwind = kv.GetNum("maxwind", 50);
		windsettings.mingust = kv.GetNum("mingust", 100);
		windsettings.maxgust = kv.GetNum("maxgust", 250);
		windsettings.mingustdelay = kv.GetFloat("mingustdelay", 10.0);
		windsettings.maxgustdelay = kv.GetFloat("maxgustdelay", 20.0);
		windsettings.gustduration = kv.GetFloat("gustduration", 5.0);
		windsettings.gustdirchange = kv.GetNum("gustdirchange", 20);

		PrintToServer("[SM] env_wind set to %s", buffer);
		PrintToChatAll("[SM] env_wind set to %s", buffer);
	}


	int wind = FindEntityByClassname(-1, "env_wind");

	if(wind != -1)
	{
		//SetEntProp(wind, Prop_Send, "m_iWindSeed", 1000);
		SetEntProp(wind, Prop_Send, "m_iMinWind", windsettings.minwind);					// minwind 20
		SetEntProp(wind, Prop_Send, "m_iMaxWind", windsettings.maxwind);					// maxwind 50

		//SetEntProp(wind, Prop_Send, "m_iInitialWindDir", 0);

		//SetEntPropFloat(wind, Prop_Send, "m_flInitialWindSpeed", 100.0);
		//SetEntPropFloat(wind, Prop_Send, "m_flStartTime", 0.0);


		SetEntProp(wind, Prop_Send, "m_iMinGust", windsettings.mingust);					// mingust 100
		SetEntProp(wind, Prop_Send, "m_iMaxGust", windsettings.maxgust);					// maxgust 250
		SetEntPropFloat(wind, Prop_Send, "m_flMinGustDelay", windsettings.mingustdelay);	// mingustdelay 10.0
		SetEntPropFloat(wind, Prop_Send, "m_flMaxGustDelay", windsettings.maxgustdelay);	// maxgustdelay 20.0 // zero -> crash
		SetEntPropFloat(wind, Prop_Send, "m_flGustDuration", windsettings.gustduration);	// gustduration 5.0
		SetEntProp(wind, Prop_Send, "m_iGustDirChange", windsettings.gustdirchange);		// gustdirchange 20
	}

	return Plugin_Handled;
}


