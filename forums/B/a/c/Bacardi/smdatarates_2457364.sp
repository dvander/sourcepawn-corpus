

char cvars[][] = {
	"sv_maxrate",
	"sv_minrate",
	"sv_maxupdaterate",
	"sv_minupdaterate",
	"sv_maxcmdrate",
	"sv_mincmdrate",
	"sv_client_cmdrate_difference",
	"net_splitpacket_maxrate",
	"sv_competitive_minspec",
	"sv_client_min_interp_ratio",
	"sv_client_max_interp_ratio"
};

public Plugin myinfo = 
{
	name = "SM Data Rate",
	author = "Bacardi",
	description = "Administration Menu",
	version = "0.2",
	url = ""
};



StringMap server_rates;

bool server_cvar_changed;

public void OnPluginStart()
{

	RegConsoleCmd("sm_dataratehelp", sm_dataratehelp, "Display SM Rates Help menu");
	RegConsoleCmd("sm_datarate", sm_datarate, "Display your current data rates in menu");
	RegConsoleCmd("sm_datarates", sm_datarates, "Display all players current data rates in your console");
	RegConsoleCmd("sm_serverdatarates", sm_serverdatarates, "Display server data rate settings in menu");


	server_rates = new StringMap();

	ConVar cvar;

	for(int x = 0; x < sizeof(cvars); x++)
	{
		cvar = FindConVar(cvars[x]);
		if(cvar == null) continue;

		cvar.AddChangeHook(ChangeHook);
		server_rates.SetValue(cvars[x], cvar.IntValue, true);
	}
}

public OnConfigsExecuted()
{
	server_cvar_changed = false;
}

public void ChangeHook(ConVar convar, const char[] oldValue, const char[] newValue)
{
	server_cvar_changed = true;
	char name[MAX_NAME_LENGTH];
	convar.GetName(name, sizeof(name));

	server_rates.SetValue(name, convar.IntValue, true);
}


public Action sm_dataratehelp(int client, int args)
{
	if(client == 0) return Plugin_Handled;

	Panel panel = CreatePanel();
	panel.SetTitle("SM Data Rate Help");

	panel.DrawItem("exit\n");
	panel.DrawItem("!datarate - Show your data rates");
	panel.DrawItem("!datarates - Show all players data rates in your console");
	panel.DrawItem("!serverdatarates - Show server data rate settings");
	panel.Send(client, panelhandler_help, 0);
	delete panel;


	return Plugin_Handled;
}

public int panelhandler_help(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
	{
		delete menu;
	}
	else if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 1:
			{
			}
			case 2:
			{
				FakeClientCommandEx(param1, "say !datarate");
			}
			case 3:
			{
				FakeClientCommandEx(param1, "say !datarates");
				PrintToChat(param1, "[SM] Players data rates printed in your console...");
			}
			case 4:
			{
				FakeClientCommandEx(param1, "say !serverdatarates");
			}
		}
	}
}


public Action sm_datarate(int client, int args)
{
	if(client == 0) return Plugin_Handled;

	char buffer[256];

	Panel panel = CreatePanel();
	panel.SetTitle("SM Data Rates - Your current rates");

	Format(buffer, sizeof(buffer), "exit \n \n");
	panel.DrawItem(buffer);
	Format(buffer, sizeof(buffer), "rate  %i", GetClientDataRate(client));
	panel.DrawText(buffer);
	Format(buffer, sizeof(buffer), " \nupdate %0.0f     in: %0.2fKB/s", GetClientAvgPackets(client, NetFlow_Outgoing), GetClientAvgData(client, NetFlow_Outgoing)/1000.0);
	panel.DrawText(buffer);
	Format(buffer, sizeof(buffer), "loss: %0.0f%%  choke: %0.0f%% ping: %0.0fms", GetClientAvgLoss(client, NetFlow_Outgoing)*100.0, GetClientAvgChoke(client, NetFlow_Outgoing)*100.0, GetClientAvgLatency(client, NetFlow_Outgoing)*1000.0);
	panel.DrawText(buffer);
	
	Format(buffer, sizeof(buffer), " \ncmd %0.0f     out: %0.2fKB/s", GetClientAvgPackets(client, NetFlow_Incoming), GetClientAvgData(client, NetFlow_Incoming)/1000.0);
	panel.DrawText(buffer);
	Format(buffer, sizeof(buffer), "loss: %0.0f%%  choke: %0.0f%% ping: %0.0fms", GetClientAvgLoss(client, NetFlow_Incoming)*100.0, GetClientAvgChoke(client, NetFlow_Incoming)*100.0, GetClientAvgLatency(client, NetFlow_Incoming)*1000.0);
	panel.DrawText(buffer);
	
	
	


	panel.Send(client, panelhandler, 0);
	delete panel;


	return Plugin_Handled;
}

public Action sm_datarates(int client, int args)
{
	if(client == 0) return Plugin_Handled;

	PrintToConsole(client, "\n\n");

	char buffer[1024];
	Format(buffer, sizeof(buffer), "%20s %10s %6s %6s %10s %10s %13s %s", "  name", "  rate", "update", "cmd", "in: KB/s", "out: KB/s", "in: ping ms", "out: ping ms");
	PrintToConsole(client, buffer);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i)) continue;

		Format(buffer, 20, "%N", i);

		Format(buffer, sizeof(buffer), "%20s %-10i %-6.0f %-6.0f %-10.2f %-10.2f %-13.0f %0.0f", buffer, GetClientDataRate(i), GetClientAvgPackets(i, NetFlow_Outgoing), GetClientAvgPackets(i, NetFlow_Incoming), GetClientAvgData(i, NetFlow_Outgoing)/1000.0, GetClientAvgData(i, NetFlow_Incoming)/1000.0, GetClientAvgLatency(i, NetFlow_Outgoing)*1000.0, GetClientAvgLatency(i, NetFlow_Incoming)*1000.0);
		PrintToConsole(client, buffer);
	}

	return Plugin_Handled;
}



public Action sm_serverdatarates(int client, int args)
{
	if(client == 0) return Plugin_Handled;

	char buffer[256];
	int value;

	for(int x = 0; x < sizeof(cvars); x++)
	{
		if(server_rates.GetValue(cvars[x], value)) Format(buffer, sizeof(buffer), "%s%s %i \n", buffer, cvars[x], value);
	}

	Format(buffer, sizeof(buffer), "\n \n \n \n \n \n \n%s", buffer);

	Panel panel = CreatePanel();
	panel.SetTitle(buffer);

	panel.DrawItem("exit");
	panel.Send(client, panelhandler, 0);

	delete panel;

	if(server_cvar_changed) PrintToChat(client, "*Server rate settings have changed, players need reconnect to server to accept new rate restricts");

	return Plugin_Handled;
}



public int panelhandler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End) delete menu;
}

/*
"sv_maxrate" = "0"
 replicated
 - Max bandwidth rate allowed on server, 0 == unlimited
"sv_minrate" = "3500"
 replicated
 - Min bandwidth rate allowed on server, 0 == unlimited
"sv_maxupdaterate" = "66"
 replicated
 - Maximum updates per second that the server will allow
"sv_minupdaterate" = "10"
 replicated
 - Minimum updates per second that the server will allow
"sv_mincmdrate" = "10"
 replicated
 - This sets the minimum value for cl_cmdrate. 0 == unlimited.
"sv_maxcmdrate" = "66"
 replicated
 - (If sv_mincmdrate is > 0), this sets the maximum value for cl_cmdrate.
"sv_client_cmdrate_difference" = "20"
 replicated
 - cl_cmdrate is moved to within sv_client_cmdrate_difference units of cl_update
rate before it is clamped between sv_mincmdrate and sv_maxcmdrate.

"net_splitpacket_maxrate" = "80000" min. 1000.000000 max. 1048576.000000
 - Max bytes per second when queueing splitpacket chunks
 
 "sv_competitive_minspec" = "0"
 game notify replicated
 - Enable to force certain client convars to minimum/maximum values to help prev
ent competitive advantages:
        r_drawdetailprops = 1
        r_staticprop_lod = minimum -1 maximum 3
        fps_max minimum 59 (0 works too)
        cl_detailfade minimum 400
        cl_detaildist minimum 1200
        cl_interp_ratio = minimum 1 maximum 2
        cl_interp = minimum 0 maximum 0.031
		
"sv_client_min_interp_ratio" = "1"
 replicated
 - This can be used to limit the value of cl_interp_ratio for connected clients
(only while they are connected).
              -1 = let clients set cl_interp_ratio to anything
 any other value = set minimum value for cl_interp_ratio
"sv_client_max_interp_ratio" = "5"
 replicated
 - This can be used to limit the value of cl_interp_ratio for connected clients
(only while they are connected). If sv_client_min_interp_ratio is -1, then this
cvar has no effect.
*/

