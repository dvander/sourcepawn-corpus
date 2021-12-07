#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME "Speed Meter"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_DESCRIPTION "Show current player speed in HUD"
#define PLUGIN_AUTHOR "Petit Renard"
#define PLUGIN_URL "http://css.cooldev.net/"

new Handle:g_enable = INVALID_HANDLE;
new Handle:g_unit = INVALID_HANDLE;
new Float:lastPosition[MAXPLAYERS + 1][3];
new g_MaxClients;
new Handle:g_timer = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart ()
{
	LoadTranslations ("speedmeter.phrases");
	
	g_enable = CreateConVar ("speedmeter_enable", "1", "Enable SpeedMeter ? (1 = yes, 0 = no)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_unit = CreateConVar ("speedmeter_unit", "0", "Unit of length (0 = kilometres, 1 = miles)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	CreateConVar ("speedmeter_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	CreateConVar ("speedmeter_credit", PLUGIN_URL, PLUGIN_NAME, FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	
	HookEvent ("round_start", Event_RoundStart);
	HookEvent ("round_end", Event_RoundEnd);
}

public OnMapStart ()
{
	g_MaxClients = GetMaxClients();
}

public Action:Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsPluginEnable ())
	{
		if (g_timer != INVALID_HANDLE)
		{
			KillTimer (g_timer);
			g_timer = INVALID_HANDLE;
		}
		g_timer = CreateTimer (0.5, Timer_Speed);
	}
	return Plugin_Continue;
}

public Action:Event_RoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_timer != INVALID_HANDLE)
	{
		KillTimer (g_timer);
		g_timer = INVALID_HANDLE;
	}
}

public Action:Timer_Speed (Handle:timer, any:nothing)
{
	for (new i=1; i<=g_MaxClients; i++)
	{
		speedMeter (i);
	}
	g_timer = CreateTimer (0.5, Timer_Speed);
}

stock speedMeter (client)
{
	if (client && IsClientConnected (client) && IsClientInGame (client) && IsPlayerAlive (client))
	{
		new Float:newPosition[3], Float:distance, Float:speed, String:message[128], unit;
		
		// calc speed in kilometer
		GetClientAbsOrigin (client, newPosition);
		distance = GetVectorDistance (lastPosition[client], newPosition);
		speed = distance / 20 * 2;
		lastPosition[client] = newPosition;
		
		unit = GetConVarInt (g_unit);
		switch (unit)
		{
			case 0:
			{
				message = "Current speed in kilometers";
			}
			case 1:
			{
				// convert kilometer for miles
				speed = speed / 1.609347;
				message = "Current speed in miles";
			}
		}
		
		PrintHintText (client, "%t", message, RoundToNearest (speed));
	}
}

stock Bool:IsPluginEnable ()
{
	return Bool:GetConVarBool (g_enable);
}