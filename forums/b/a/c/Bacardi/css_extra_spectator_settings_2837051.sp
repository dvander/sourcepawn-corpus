

public Plugin myinfo =
{
	name = "[CS:S] Extra spectator settings",
	author = "Bacardi",
	description = "Extra spectator settings",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

#include <clientprefs>


char OBSMODE[][] = {
	"OBS_MODE_NONE",	// not in spectator mode
	"OBS_MODE_DEATHCAM",	// special mode for death cam animation
	"OBS_MODE_FREEZECAM",	// zooms to a target, and freeze-frames on them
	"OBS_MODE_FIXED",		// view from a fixed camera position
	"OBS_MODE_IN_EYE",	// follow a player in first person view
	"OBS_MODE_CHASE",		// follow a player in third person view
	"OBS_MODE_POI",		// PASSTIME point of interest - game objective, big fight, anything interesting; added in the middle of the enum due to tons of hard-coded "<ROAMING" enum compares
	"OBS_MODE_ROAMING"	// free roaming
};

enum {
	OBS_MODE_NONE = 0,
	OBS_MODE_DEATHCAM,
	OBS_MODE_FREEZECAM,
	OBS_MODE_FIXED,
	OBS_MODE_IN_EYE,
	OBS_MODE_CHASE,
	OBS_MODE_POI,
	OBS_MODE_ROAMING,
	NUM_OBSERVER_MODES
};


int		cookie_cl_spec_mode[MAXPLAYERS+1];
int		cookie_skip_POI_mode[MAXPLAYERS+1]; // don't get confuse about variable name, it handles all mode, not only POI
Cookie cl_spec_mode;
Cookie skip_POI_mode;

public void OnPluginStart()
{
	cl_spec_mode = new Cookie("cl_spec_mode", "Use specific observer mode when enter in server or default", CookieAccess_Public);
	skip_POI_mode = new Cookie("skip_POI_mode", "While cycling different spectating modes, skip 'POI'", CookieAccess_Public);
	SetCookieMenuItem(settings, cl_spec_mode, "spectator settings"); // use this one to create one menu option into !settings

	AddCommandListener(listen, "spec_mode");

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i) || !AreClientCookiesCached(i)) continue;

		OnClientCookiesCached(i);
	}
}


// This callback can appear before or after OnClientPutInServer()
public void OnClientCookiesCached(int client)
{
	if(!IsFakeClient(client) && !IsClientInKickQueue(client))
	{
		cookie_cl_spec_mode[client] = cl_spec_mode.GetInt(client, OBS_MODE_NONE);
		cookie_skip_POI_mode[client] = skip_POI_mode.GetInt(client, OBS_MODE_NONE);

		if(cookie_cl_spec_mode[client] != OBS_MODE_NONE)
			ClientCommand(client, "cl_spec_mode %i", cookie_cl_spec_mode[client]);
	}
}


public void settings(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch(action)
	{
		case CookieMenuAction_SelectOption:
		{
			ShowMenuOptionSpecMode(client);
		}
	}
}

void ShowMenuOptionSpecMode(int client)
{
	Menu menuhandler = new Menu(option_spec_mode, MENU_ACTIONS_DEFAULT|MenuAction_DisplayItem);

	menuhandler.SetTitle("spectator settings");
	menuhandler.AddItem("cl_spec_mode", "Enter in server, using mode = 'cl_spec_mode'\n \n ");
	menuhandler.AddItem("skip_POI_mode", "	-	");
	menuhandler.AddItem("skip_POI_mode", "	-	");
	menuhandler.AddItem("skip_POI_mode", "	-	");
	menuhandler.AddItem("skip_POI_mode", "	-	");
	menuhandler.Display(client, 60);
}

public int option_spec_mode(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_Exit) // player select 'exit' button
				ShowCookieMenu(param1);
		}
		case MenuAction_DisplayItem: // menu creating items
		{
			if(param2 == 0) // cl_spec_mode
			{
				char buffer[65];
				int index = cookie_cl_spec_mode[param1];

				if(index >= OBS_MODE_IN_EYE)
				{
					Format(buffer, sizeof(buffer), "Enter in server, using mode = '%s'\n \n ", OBSMODE[index][9]);

					return RedrawMenuItem(buffer);
				}
			}
			else if(param2 != 0) // skip_POI_mode
			{
				int index = param2 + 3;	// ...funny stuff. I'm lazy. Start from OBS_MODE_IN_EYE

				char buffer[65];
				Format(buffer, sizeof(buffer), "While cycle modes, skip '%s' = %s",
				OBSMODE[index][9],
				cookie_skip_POI_mode[param1] & (1 << index) ? "Yes":"No");

				return RedrawMenuItem(buffer);
			}
		}
		case MenuAction_Select: // player select item
		{
			if(param2 == 0) // cl_spec_mode
			{
				cookie_cl_spec_mode[param1]++;
				cookie_cl_spec_mode[param1] = cookie_cl_spec_mode[param1] % NUM_OBSERVER_MODES;

				if(cookie_cl_spec_mode[param1] != 0 && cookie_cl_spec_mode[param1] < OBS_MODE_IN_EYE)
					cookie_cl_spec_mode[param1] = OBS_MODE_IN_EYE;

				cl_spec_mode.SetInt(param1, cookie_cl_spec_mode[param1]);
			}
			else if(param2 != 0) // skip_POI_mode
			{
				int index = param2 + 3;

				cookie_skip_POI_mode[param1] = cookie_skip_POI_mode[param1] ^ 1 << index;
				skip_POI_mode.SetInt(param1, cookie_skip_POI_mode[param1]);
			}

			ShowMenuOptionSpecMode(param1);
		}
	}

	return 0;
}

// accept spec_mode command without arguments
public Action listen(int client, const char[] command, int argc)
{
	if(argc > 0 || client == 0 || !IsClientInGame(client) || IsFakeClient(client) || IsClientInKickQueue(client))
		return Plugin_Continue;


	// There is some modes skipped, but not all
	if(cookie_skip_POI_mode[client] && !(cookie_skip_POI_mode[client] >> 4 == 0xF))
	{
		RequestFrame(frame, client);
		return Plugin_Handled; // block original command
	}

	return Plugin_Continue;
}

public void frame(int client)
{
	int oldobservermode = GetEntProp(client, Prop_Send, "m_iObserverMode");
	int observermode = oldobservermode;

	for(int x = 0; x < NUM_OBSERVER_MODES; x++)
	{
		observermode++;
		observermode = observermode % NUM_OBSERVER_MODES;

		if(observermode < OBS_MODE_IN_EYE)
			observermode = OBS_MODE_IN_EYE;


		if(cookie_skip_POI_mode[client] & 1 << observermode) // skip mode
		{
			continue;
		}

		break;
	}

	if(observermode != oldobservermode) // we got another mode
		FakeClientCommandEx(client, "spec_mode %i", observermode);
}