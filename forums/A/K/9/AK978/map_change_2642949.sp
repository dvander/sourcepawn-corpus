#include <sourcemod>

new String:mCurrent[64];


public OnPluginStart()
{
	HookEvent("finale_win", change_map);
}

public OnMapStart()
{
	GetCurrentMap(mCurrent, sizeof(mCurrent));
}

public Action:change_map(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, TimerChDelayCOOP);
}

public Action:TimerChDelayCOOP(Handle:timer)
{	
	if (StrEqual(mCurrent, "c1m4_atrium", false))
	{
		ServerCommand("changelevel c2m1_highway");
	}	
	else if (StrEqual(mCurrent, "c2m5_concert", false))
	{
		ServerCommand("changelevel c3m1_plankcountry");
	}
	else if (StrEqual(mCurrent, "c3m4_plantation", false))
	{
		ServerCommand("changelevel c4m1_milltown_a");
	}
	else if (StrEqual(mCurrent, "c4m5_milltown_escape", false))
	{
		ServerCommand("changelevel c5m1_waterfront");
	}
	else if (StrEqual(mCurrent, "c5m5_bridge", false))
	{
		ServerCommand("changelevel c6m1_riverbank");
	}
	else if (StrEqual(mCurrent, "c6m3_port", false))
	{
		ServerCommand("changelevel c7m1_docks");
	}
	else if (StrEqual(mCurrent, "c7m3_port", false))
	{
		ServerCommand("changelevel c8m1_apartment");
	}
	else if (StrEqual(mCurrent, "c8m5_rooftop", false))
	{
		ServerCommand("changelevel c9m1_alleys");
	}
	else if (StrEqual(mCurrent, "c9m2_lots", false))
	{
		ServerCommand("changelevel c10m1_caves");
	}
	else if (StrEqual(mCurrent, "c10m5_houseboat", false))
	{
		ServerCommand("changelevel c11m1_greenhouse");
	}
	else if (StrEqual(mCurrent, "c11m5_runway", false))
	{
		ServerCommand("changelevel c12m1_hilltop");
	}
	else if (StrEqual(mCurrent, "c12m5_cornfield", false))
	{
		ServerCommand("changelevel c13m1_alpinecreek");
	}
	else if (StrEqual(mCurrent, "c13m4_cutthroatcreek", false))
	{
		ServerCommand("changelevel c1m1_hotel");
	}
}