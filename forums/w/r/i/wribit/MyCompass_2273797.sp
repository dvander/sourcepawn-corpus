#pragma semicolon 1
#pragma unused cvarVersion

#include <sourcemod>
#include <clientprefs>
#include <sdkhooks>
#include <sdktools>


#define PLUGIN_VERSION "2"
#define PLUGIN_DESCRIPTION "Puts a compass in the game, in center text, in hint text or in left panel"
// UPDATE INFO 
// 0.0.2:: ADDED COMPASS TO SPECTATORS
// 1.3 :: DID SOME FANCY FOOTWORK, MAKING SURE THE OBSERVED CLIENT IS VALID
// 1.4 :: TIMER SET TO 1.8 SECS TO ALLOW OTHER PLUGINS TO PRINT TO SCREEN 
// 2   :: SET THE TIMER TO 1 SO THERE'S NO DELAY, AND ADDED A CHOICE TO SHOW BEARING

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarPosition = INVALID_HANDLE; //where to put the compass
new Handle:cvarBearing = INVALID_HANDLE; //whether or not to show the bearing
new bool:enable_compass = true;
new compass_position = 1;
new bool:compass_bearing = true;

public Plugin:myinfo = {
	name= "MyCompass",
	author  = "wribit",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = ""
};


public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_comp_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_comp_enabled", "1", "sets whether compass is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarPosition = CreateConVar("sm_comp_pos", "1", "Sets the position of the compass on screen. 1=center text, 2=panel left, 3=hint text bottom", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarBearing = CreateConVar("sm_comp_bearing", "1", "Sets whether or not to show bearing. 1=show, 0=don't show", FCVAR_NOTIFY | FCVAR_PLUGIN);

	HookConVarChange(cvarEnabled, OnCVarChange);
	HookConVarChange(cvarPosition, OnCVarChange);
	
	AutoExecConfig(true, "plugin.MyCompass");
	
	CreateTimer(1.0, RefreshCompass, _, TIMER_REPEAT);
}

public Action:RefreshCompass(Handle:timer)
{
	if (!enable_compass)
	{
		KillTimer(timer);
		return;
	}
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if(Client_IsValid(client,true))
		{
			if(Client_IsIngame(client) && IsClientObserver(client) && GetClientHealth(client) == 0)
			{
				new ObsTarget = Client_GetObserverTarget(client);
				if(Client_IsValid(ObsTarget,true) && Client_IsIngame(ObsTarget))
				{
					Check_Compass(client, ObsTarget);
				}
				else
				{
					Check_Compass(client, 0);
				}	
			}
			else if(Client_IsIngame(client))
			{
				Check_Compass(client, 0);
			}
		}
	}
}

public Action:Check_Compass(client, target)
{
	if (!enable_compass)
	{
		return;
	}

	if(compass_position == 1)
	{
		//COMPASS IN CENTER TEXT
		PrintCenterText(client, getDisplayString(client, target));
	}
	else if(compass_position == 2)
	{
		//COMPASS IN LEFT PANEL -- WARNING, KEYS: 1, 2, 3, 4 WEAPON SELECT DON'T WORK WHILE PANEL IS SHOWING!
		new Handle:CompassPanel = CreatePanel(INVALID_HANDLE);
		
		DrawPanelText(CompassPanel, getDisplayString(client, target));
		SendPanelToClient(CompassPanel, client, NullMenuHandler, 1);
		CloseHandle(CompassPanel);
	}
	else if(compass_position == 3)
	{
		//COMPASS IN HINT TEXT - BOTTOM CENTER OF SCREEN
		PrintHintText(client, getDisplayString(client, target));
	}
}

public OnConfigsExecuted()
{
	GetCVars();
}

String:getDisplayString(client, target)
{
	//calculations by JBallou
	decl Float:angle[3];
	decl Float:bearing;
	new String:sDisplay[512];
	
	if(!target) //client is not an observer
	{
		GetClientEyeAngles(client, angle);
		if ((angle[1] < -158)  || (angle[1] > 158)) {
			sDisplay[0] = 'W';
		} else if (angle[1] < -113) {
			sDisplay[0] = 'S';
			sDisplay[1] = 'W';
		} else if (angle[1] < -68) {
			sDisplay[0] = 'S';
		} else if (angle[1] < -22) {
			sDisplay[0] = 'S';
			sDisplay[1] = 'E';
		} else if (angle[1] < 22) {
			sDisplay[0] = 'E';
		} else if (angle[1] < 67) {
			sDisplay[0] = 'N';
			sDisplay[1] = 'E';
		} else if (angle[1] < 112) {
			sDisplay[0] = 'N';
		} else {
			sDisplay[0] = 'N';
			sDisplay[1] = 'W';
		}
		
		if(compass_bearing)
		{
			bearing = Get_Bearing(angle[1]);
			//add line break
			Format(sDisplay,sizeof(sDisplay),"%s\n",sDisplay);
			//print bearing
			Format(sDisplay,sizeof(sDisplay),"%s%0.1f\xc2\xb0",sDisplay,bearing);
		}
	}
	else //client is an observer
	{
		GetClientEyeAngles(target, angle);
		if ((angle[1] < -158)  || (angle[1] > 158)) {
			sDisplay[0] = 'W';
		} else if (angle[1] < -113) {
			sDisplay[0] = 'S';
			sDisplay[1] = 'W';
		} else if (angle[1] < -68) {
			sDisplay[0] = 'S';
		} else if (angle[1] < -22) {
			sDisplay[0] = 'S';
			sDisplay[1] = 'E';
		} else if (angle[1] < 22) {
			sDisplay[0] = 'E';
		} else if (angle[1] < 67) {
			sDisplay[0] = 'N';
			sDisplay[1] = 'E';
		} else if (angle[1] < 112) {
			sDisplay[0] = 'N';
		} else {
			sDisplay[0] = 'N';
			sDisplay[1] = 'W';
		}
		
		if(compass_bearing)
		{
			bearing = Get_Bearing(angle[1]);
			//add line break
			Format(sDisplay,sizeof(sDisplay),"%s\n",sDisplay);
			//print bearing
			Format(sDisplay,sizeof(sDisplay),"%s%0.1f\xc2\xb0",sDisplay,bearing);
		}
	}
	return sDisplay;
}

Float:Get_Bearing(Float:angle)
{
	decl Float:bearing;
	//calculations by JBallou
	if (angle >= 90.0) { // W to N
		bearing = 270.0 + (180.0 - angle);
	} else if (angle) { //W to N
		bearing = 90.0 - angle;
	} else if (angle >= -90) {
		bearing = 90.0 + (0.0 - angle);
	} else {
		bearing = 180.0 - (angle + 90.0);
	}
	
	return bearing;
}

static Client_IsValid(client, bool:checkConnected)
{
	if (client > 4096) {
		client = EntRefToEntIndex(client);
	}

	if (client < 1 || client > MaxClients) {
		return false;
	}

	if (checkConnected && !IsClientConnected(client)) {
		return false;
	}
	
	return true;
}

static Client_IsIngame(client)
{
	if (!Client_IsValid(client, false)) 
	{
		return false;
	}

	return IsClientInGame(client);
}

static Client_GetObserverTarget(client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}

static GetCVars()
{
	enable_compass = GetConVarBool(cvarEnabled);
	compass_position = GetConVarInt(cvarPosition);
	compass_bearing = GetConVarBool(cvarBearing);
}

public NullMenuHandler(Handle:menu, MenuAction:action, param1, param2) 
{
}
