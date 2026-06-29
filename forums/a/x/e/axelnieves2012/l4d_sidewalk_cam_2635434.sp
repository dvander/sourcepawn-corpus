#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

#define DIRECTION_LEFT			-1
#define DIRECTION_RIGHT			1

#define KEY_PRESSED				1
#define KEY_RELEASED			-1

new Handle:l4d_sidewalk_angle = INVALID_HANDLE;
new Handle:l4d_sidewalk_enable = INVALID_HANDLE;
new Handle:l4d_sidewalk_smoothness = INVALID_HANDLE;
new Handle:l4d_sidewalk_ads_timer = INVALID_HANDLE;
new g_KeyStatus[MAXPLAYERS+1]; //1: starting rolling(keypress), -1:finishing rolling(key released.), 0: normal view
new g_Direction[MAXPLAYERS+1];
new g_Enabled[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Side-walk camera rotation",
	author = "Axel Juan Nieves",
	description = "Simulates Black Mesa Source's side walk camera rotation.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=313698"
};

public OnPluginStart()
{
	l4d_sidewalk_enable = CreateConVar("l4d_sidewalk_enable", "1", "Enable/Disable this plugin", 0);
	l4d_sidewalk_angle = CreateConVar("l4d_sidewalk_angle", "3.0", "Max rotation angle", 0);
	l4d_sidewalk_smoothness = CreateConVar("l4d_sidewalk_smoothness", "1.0", "Smooth effect. Higher=smoother Lower(1.0)=instant rotation. ", 0);
	l4d_sidewalk_ads_timer = CreateConVar("l4d_sidewalk_ads_timer", "40.0", "Show plugin ads each x seconds. 0=Disable ads", 0);
	CreateConVar("l4d_sidewalk_camera_version", PLUGIN_VERSION, "Side-walk camera version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("cl_sidewalk_center", user_reset, "Resets camera. Use in case of bug.");
	RegConsoleCmd("cl_sidewalk_reset", user_reset, "Alias of cl_sidewalk_center.");
	RegConsoleCmd("sm_sidewalk", user_toggle, "Toggle sidewalk camera rotation.");
	
	decl String:GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if ( StrContains(GameName, "left4dead", false)==0 )
	{
		HookEvent("player_incapacitated", reset_angle_event);
		HookEvent("lunge_pounce", reset_angle_event);
		HookEvent("pounce_stopped", reset_angle_event);
		HookEvent("tongue_grab", reset_angle_event);
		HookEvent("tongue_release", reset_angle_event);
		HookEvent("player_ledge_grab", reset_angle_event);
		HookEvent("round_start", reset_angle_event);
		HookEvent("player_death", reset_angle_event);
		HookEvent("player_bot_replace", reset_angle_event);
		HookEvent("player_afk", reset_angle_event);
	}
	if ( StrEqual(GameName, "left4dead2", false) )
	{
		HookEvent("jockey_ride", reset_angle_event);
		HookEvent("jockey_ride_end", reset_angle_event);
		HookEvent("charger_pummel_start", reset_angle_event);
		HookEvent("charger_pummel_end", reset_angle_event);
	}
	AutoExecConfig(true, "l4d_sidewalk_cam");
}
public OnMapStart()
{
	new Float:timer = GetConVarFloat(l4d_sidewalk_ads_timer);
	if (timer>0.0)
		CreateTimer(timer, sidewalk_ads, _, TIMER_REPEAT);
}

public OnClientPutInServer(client)
{
	g_Enabled[client] = 1;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsValidClientAlive(client)) return;
	if (IsFakeClient(client)) return;
	if ( GetConVarInt(l4d_sidewalk_enable)==0 ) return;
	
	if (buttons & IN_MOVELEFT)
	{
		g_KeyStatus[client] = KEY_PRESSED;
		g_Direction[client] = DIRECTION_LEFT;
	}
	else if (buttons & IN_MOVERIGHT)
	{
		g_KeyStatus[client] = KEY_PRESSED;
		g_Direction[client] = DIRECTION_RIGHT;
	}
}

public OnGameFrame()
{
	if ( GetConVarInt(l4d_sidewalk_enable)==0 ) return;
	new Float: equation, Float:smooth, Float:angle;
	//new Float:time = GetGameTime();
	//if ( time - g_fLastTime < 0.1 ) return;
	
  	for(new client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClientAlive(client)) continue;
		if (IsFakeClient(client)) continue;
		if (g_Enabled[client]==0) continue;
		
		//get pressed/released buttons...
		new buttons = GetClientButtons(client);
		
		//-moveleft...
		if ( g_Direction[client]==DIRECTION_LEFT && (buttons&IN_MOVELEFT)==0 )
		{
			g_KeyStatus[client] = KEY_RELEASED;
		}
		
		//-moveright...
		else if ( g_Direction[client]==DIRECTION_RIGHT && (buttons&IN_MOVERIGHT)==0 )
		{
			g_KeyStatus[client] = KEY_RELEASED;
		}
		
		//if camera is centered and nothing pressed, noop.
		if ( g_Direction[client]==0 && g_KeyStatus[client]==0 )
			continue;
		
		smooth = GetConVarFloat(l4d_sidewalk_smoothness);
		angle = GetConVarFloat(l4d_sidewalk_angle);
		if (smooth<1.1) smooth = 1.1;
		
		//roll camera according to key is pressed or released:
		float angs[3];
		GetClientEyeAngles(client, angs);
		
		equation = (GetConVarFloat(l4d_sidewalk_angle)/smooth)*(g_Direction[client])*g_KeyStatus[client];
		angs[2] += equation;
		
		//prevent exceeding max angle defined in cvar...
		if ( g_KeyStatus[client] == KEY_PRESSED )
		{
			if ( g_Direction[client] == DIRECTION_RIGHT )
			{
				if ( angs[2] > angle )
					angs[2] = angle;
			}
			if ( g_Direction[client] == DIRECTION_LEFT )
			{
				if ( FloatAbs(angs[2]) > angle )
					angs[2] = angle*(-1);
			}
			
			//This prevents mouse move bug, while moving...
			if ( FloatAbs(angs[2]) != angle )
				TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
		}
		
		//this make camera go centered automatically when no sidewalk is pressed...
		else if ( g_KeyStatus[client] == KEY_RELEASED )
		{
			if ( g_Direction[client] == DIRECTION_RIGHT )
			{
				if ( angs[2]+equation < 0.0)
				{
					reset_angle(client);
					continue;
				}
			}
			else if ( g_Direction[client] == DIRECTION_LEFT )
			{
				if ( angs[2]+equation > 0.0)
				{
					reset_angle(client);
					continue;
				}
			}
			
			//This prevents mouse move bug, while stopping moving...
			if ( angs[2] != 0.0 )
				TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
		}
	}
	//g_fLastTime = time;
}

reset_angle(client)
{
	if (client <= 0) return;
	if (!IsClientConnected(client)) return;
	if (!IsClientInGame(client)) return;
	if ( GetConVarInt(l4d_sidewalk_enable)==0 ) return;
	
	float angs[3];
	GetClientEyeAngles(client, angs);
	angs[2] = 0.0;
	g_Direction[client] = 0;
	g_KeyStatus[client] = 0;
	TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
}

public Action:reset_angle_event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	reset_angle(client);
}

public Action:user_reset(client, args)
{
	reset_angle(client);
}

public Action:user_toggle(client, args)
{
	if (g_Enabled[client]==0)
	{
		PrintToChat(client, "[Sidewalk]: Rotation enabled!");
		g_Enabled[client] = 1;
	}
	else 
	{
		PrintToChat(client, "[Sidewalk]: Rotation disabled!");
		g_Enabled[client] = 0;
	}
}

public Action:sidewalk_ads(Handle:timer)
{
	PrintToChatAll("[Sidewalk] Type !sidewalk to enable/disable camera rotation.");
}

public IsValidClientAlive(client)
{
	if (client <= 0)
		return false;
	if (!IsClientConnected(client))
		return false;
	if (!IsClientInGame(client))
		return false;
	if (!IsPlayerAlive(client))
		return false;
	
	return true;
}