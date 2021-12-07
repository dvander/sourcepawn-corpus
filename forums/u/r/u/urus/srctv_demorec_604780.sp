#pragma semicolon 1
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "0.4"

new Handle:hTopMenu = INVALID_HANDLE;
new Handle:g_hTimer = INVALID_HANDLE;
new Handle:g_Cvar_Sourcetv = INVALID_HANDLE;
new Handle:g_Cvar_RecTime = INVALID_HANDLE;
new Handle:g_Cvar_SbStatus = INVALID_HANDLE;
new Handle:g_Cvar_SbStatusTime = INVALID_HANDLE;
new Handle:g_Cvar_AdmDisconnect = INVALID_HANDLE;
new Handle:g_Cvar_Folder = INVALID_HANDLE;
new Handle:g_Cvar_Log = INVALID_HANDLE;
new Handle:g_hSrvip = INVALID_HANDLE;
new Handle:g_hSrvport = INVALID_HANDLE;

new String:g_recstarter[24];
new String:g_startername[48];
new String:g_map[48];
new String:g_date[24];
new String:logRec[PLATFORM_MAX_PATH];
new String:g_RecTime[14][5];

new g_nSecondsPassed;
new g_timeelapsed;
new g_recordtime;
new g_maxitems;
new g_CmdStatus;
new g_CmdStatusTime;

new bool:g_demoen = false;


public Plugin:myinfo = 
{
	name = "SourceTV demorecord",
	author = "O!KAK",
	description = "Admin tool for SourceTV demo recording",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
        LoadTranslations("plugin.demorecord");
	RegAdminCmd("demorec", DemorecordMenu, ADMFLAG_CUSTOM1, "Display menu for record demos");
	RegAdminCmd("demorecon", DemoreconConsole, ADMFLAG_CUSTOM1, "Console command for record demos");
	RegAdminCmd("demorecoff", DemorecoffConsole, ADMFLAG_CUSTOM1, "Console command for stop recording demos");
        RegAdminCmd("demostatus", DemoCheckStatusConsole, ADMFLAG_CUSTOM1, "Console command for check record status");
	RegAdminCmd("demodump", DemoCallDumpToSourcetv, ADMFLAG_CUSTOM1, "Console command for call sb_status/status command");

	CreateConVar("demorec_version", PLUGIN_VERSION, _, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Cvar_RecTime = CreateConVar("demorec_times", "0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60", "Comma delimited! Time in minutes for record time menu. Max 14 items!");
	g_Cvar_SbStatus = CreateConVar("demorec_status", "0", "This option determines if sb_status or status command can be executed while recording a demo (0 - disable; 1 - sb_status; 2 - status)", _, true, 0.0, true, 2.0);
	g_Cvar_SbStatusTime = CreateConVar("demorec_status_time", "0", "Time in seconds (after record start) when sb_status/status will be executed (0 - disable)", _, true, 0.0);
	g_Cvar_AdmDisconnect = CreateConVar("demorec_onadmin_leave", "1", "Should demo record autostop when admin disconnect from server", _, true, 0.0, true, 1.0);
	g_Cvar_Folder = CreateConVar("demorec_folder", "", "Directory where server store demos. If this cvar empty, demos will store in root directory (cstrike, dod, tf, etc.)");
	g_Cvar_Log = CreateConVar("demorec_log", "1", "Enable/disable logging to a file demorec.log", _, true, 0.0, true, 1.0);

	g_hSrvip = FindConVar("ip");
        g_hSrvport = FindConVar("hostport");
	g_Cvar_Sourcetv = FindConVar("tv_enable");

	BuildPath(Path_SM, logRec, PLATFORM_MAX_PATH, "logs/demorec.log");

	AutoExecConfig(true, "plugin_demorec");
}

public OnConfigsExecuted()
{
	g_CmdStatus = GetConVarInt(g_Cvar_SbStatus);
        g_CmdStatusTime = GetConVarInt(g_Cvar_SbStatusTime);
	
	new String:CvarHolder[96];
	GetConVarString (g_Cvar_RecTime, CvarHolder, sizeof (CvarHolder));
        g_maxitems = ExplodeString(CvarHolder, ",", g_RecTime, 14, 5);

	g_nSecondsPassed = 0;
        g_demoen = false;
        g_recordtime = 0;
        g_timeelapsed = 0;
	g_hTimer = INVALID_HANDLE;
}

public OnMapEnd()
{
	if(g_demoen && GetConVarBool(g_Cvar_Log)) 
        {
               LogToFileEx(logRec, "Demo record autostop on mapchange");
	       LogToFileEx(logRec, "-----------------------------------");
        } 
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	hTopMenu = topmenu;

	new TopMenuObject:server_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);

	if (server_commands != INVALID_TOPMENUOBJECT)
	{
	       AddToTopMenu(hTopMenu,
			"demorec",
			TopMenuObject_Item,
			DemorecItem,
			server_commands,
			"demorec",
			ADMFLAG_CUSTOM1);

	}
}

public DemorecItem(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "DemoMenuTitle", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DemorecMenu(param, false);
	}
}

public Action:DemoRecTimer(Handle:timer)
{
        g_nSecondsPassed++;
               
        g_timeelapsed = g_recordtime - g_nSecondsPassed;

	if(g_CmdStatus > 0 && g_CmdStatusTime > 0)
	{
	        if(g_nSecondsPassed == g_CmdStatusTime)
                {
                       CallStatus(INVALID_HANDLE);
		}
	}

        if(g_nSecondsPassed >= g_recordtime)
        {
		StopRecord(-1);
        }
}

public Action:CallStatus(Handle:timer)
{
        switch(g_CmdStatus)
	{
                case 1:
		       ServerCommand("sb_status");
		case 2:
                {
		       for(new i = 1; i <= MaxClients; i++)
                       {
		             if(IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i))
		             {
                                     if(GetClientTeam(i) == 1) {
                                            DumpStatusToSourcetv(i);
				     }
	                     }
		       }
		}
	}
}				 

DemorecMenu(client, bool:callcmd)
{
        decl String:buffer[100];
	new Handle:menu = CreateMenu(DemorecHandler);
	Format(buffer, sizeof(buffer), "%T", "DemoMenuTitle", client);
	SetMenuTitle(menu, buffer);

        if (!g_demoen) {
	        Format(buffer, sizeof(buffer), "%T", "StartRecord", client);
	        AddMenuItem(menu, "menu item", buffer);
	        Format(buffer, sizeof(buffer), "%T", "StopRecord", client);
		AddMenuItem(menu, "menu item", buffer, ITEMDRAW_DISABLED);
                Format(buffer, sizeof(buffer), "%T", "CheckStatus", client);
	        AddMenuItem(menu, "menu item", buffer, ITEMDRAW_DISABLED);
	} else {
	        decl String:checkstarter[24];
	        GetClientAuthString(client, checkstarter, sizeof(checkstarter));
		
		Format(buffer, sizeof(buffer), "%T", "StartRecord", client);
	        AddMenuItem(menu, "menu item", buffer, ITEMDRAW_DISABLED);
                if(StrEqual(checkstarter, g_recstarter)) {
	               Format(buffer, sizeof(buffer), "%T", "StopRecord", client);
	               AddMenuItem(menu, "menu item", buffer);
		} else {
                        Format(buffer, sizeof(buffer), "%T", "StopRecord", client);
	                AddMenuItem(menu, "menu item", buffer, ITEMDRAW_DISABLED);
		}
                Format(buffer, sizeof(buffer), "%T", "CheckStatus", client);
	        AddMenuItem(menu, "menu item", buffer);
	}

	if(!callcmd)
	        SetMenuExitBackButton(menu, true);

	DisplayMenu(menu, client, 15);
}

public DemorecHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
	        switch(param2)
		{
			case 0:
                                DemorecTimeMenu(param1);
			case 1:
                                StopRecord(param1);
			case 2:
			        CheckStatus(param1);
		}
	} else if(action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
}

DemorecTimeMenu(client)
{	
	new Handle:menu = CreateMenu(DemorecTimeHandler);
	
	decl String:buffer[100];
	Format(buffer, sizeof(buffer), "%T", "RecordTime", client);
	SetMenuTitle(menu, buffer);

	for(new i = 0; i < g_maxitems; i++)
	{
		TrimString(g_RecTime[i]);
		if(g_RecTime[i][0] != '\0')
		{
		       Format(buffer, sizeof(buffer), "%T", "Minutes", client, g_RecTime[i]);
		       AddMenuItem(menu, g_RecTime[i], buffer);
		}
	}
	
	DisplayMenu(menu, client, 15);
}

public DemorecTimeHandler(Handle:menu, MenuAction:action, param1, param2)
{
        if (action == MenuAction_Select)
	{
		decl String:time[16];
		
		GetMenuItem(menu, param2, time, sizeof(time));
		g_recordtime = StringToInt(time) * 60;
		StartDemo(param1);
	} else if(action == MenuAction_End)	{
		CloseHandle(menu);
	}
}

CheckStatus(client)
{
	decl String:infoMessage[192], String:szHintMessage[192];
	Format(infoMessage, sizeof(infoMessage), "%T", "RecStarter", client, g_startername);

	if(g_recordtime != 0) 
	{
                new mins, secs;
		if (g_timeelapsed > 0)
	        {
		       mins = g_timeelapsed / 60;
		       secs = g_timeelapsed % 60;		
	        }

                decl String:parsedMessage[192], String:demoMessage[192];
	        Format(parsedMessage, sizeof(parsedMessage), "%T", "RemainTime", client, mins, secs);
                Format(demoMessage, sizeof(demoMessage), "%T", "DemoTimeName", client, g_recordtime / 60);
	        Format(szHintMessage, sizeof(szHintMessage), "%s\n%s\n%s", demoMessage, parsedMessage, infoMessage);
	} 
	else 
	{
	        decl String:parsedMessage[192], String:demoMessage[192];
		Format(parsedMessage, sizeof(parsedMessage), "%T", "RemainTime2", client);
		Format(demoMessage, sizeof(demoMessage), "%T", "DemoTimeName2", client);
	        Format(szHintMessage, sizeof(szHintMessage), "%s\n%s\n%s", demoMessage, parsedMessage, infoMessage);
	}
		
	new Handle:HintMessage = StartMessageOne("HintText", client);
	BfWriteByte(HintMessage, -1);
	BfWriteString(HintMessage, szHintMessage);
	EndMessage();
}

StartDemo(client)
{
       if(!GetConVarInt(g_Cvar_Sourcetv))
       {
                if(client != 0)
		      PrintToChat(client, "\x04[AdminDemo] %t", "TvNotEnabled");
		else
                      PrintToConsole(client, "[AdminDemo] %t", "TvNotEnabled");

		return;
       }

       FormatTime(g_date, sizeof(g_date), "%d-%m-%Y_%H-%M");
       GetCurrentMap(g_map, sizeof(g_map));

       decl String:folder[32];
       GetConVarString(g_Cvar_Folder, folder, sizeof(folder));
		
       ServerCommand("tv_stoprecord");
       if(folder[0] != '\0')
                ServerCommand("tv_record %s/%s-%s.dem", folder, g_date, g_map);
       else
                ServerCommand("tv_record %s-%s.dem", g_date, g_map);

       g_demoen = true;

       if(client != 0)
       {
                GetClientAuthString(client, g_recstarter, sizeof(g_recstarter));
                GetClientName(client, g_startername, sizeof(g_startername));
		PrintToChat(client, "\x04[AdminDemo] %t", "DemoStarted", g_date, g_map);
		if(GetConVarBool(g_Cvar_Log))
		       LogToFileEx(logRec, "Admin <%s> <%s> start record a demo %s-%s (%i minutes)", g_startername, g_recstarter, g_date, g_map, g_recordtime / 60);

       } else {
                Format(g_recstarter, sizeof(g_recstarter), "CONSOLE");
		Format(g_startername, sizeof(g_startername), "CONSOLE");
		PrintToConsole(client, "[AdminDemo] %t", "DemoStarted", g_date, g_map);
		if(GetConVarBool(g_Cvar_Log))
		       LogToFileEx(logRec, "Admin (CONSOLE) start record a demo %s-%s (%i minutes)", g_date, g_map, g_recordtime / 60);
       
       }

       if (g_hTimer != INVALID_HANDLE)
       {
	        KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
       }
       
       if(g_recordtime != 0)
       {
                g_hTimer = CreateTimer(1.0, DemoRecTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
       }
       else
       {         
                if(g_CmdStatus > 0 && g_CmdStatusTime > 0)
		       CreateTimer(float(g_CmdStatusTime), CallStatus);
       }
}

StopRecord(client, bool:disconnect = false)
{
       if(g_recordtime != 0) 
       {
              KillTimer(g_hTimer);
              g_hTimer = INVALID_HANDLE;
       }

       ServerCommand("tv_stoprecord");
       g_nSecondsPassed = 0;
       g_demoen = false;
       g_recordtime = 0;
       g_timeelapsed = 0;
	
       for(new i = 1; i <= MaxClients; i++)
       {
              if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
	      { 
		     if(GetUserAdmin(i) != INVALID_ADMIN_ID)
	             {
			    if(client != 0)
			          PrintToChat(i, "\x04[AdminDemo] %t", "DemoStopped", g_date, g_map);
		            else
			          PrintToChat(i, "\x04[AdminDemo] %t", "ConDemoStopped", g_date, g_map);
		     }
	      }
       }

       if(StrEqual(g_startername, "CONSOLE"))
              PrintToServer("[AdminDemo] %t", "DemoStopped", g_date, g_map);

       if(!GetConVarBool(g_Cvar_Log))
              return;
       
       if(client != -1)
       {
              if(!disconnect)
	             LogToFileEx(logRec, "Admin \"%L\" stopped record a demo", client);
              else
	             LogToFileEx(logRec, "Demo record autostop - admin leave server (\"%L\")", client);

       } 
       else 
              LogToFileEx(logRec, "Demo record autostop on time elapsed");

       LogToFileEx(logRec, "-----------------------------------");
}

public OnClientDisconnect(client)
{
       if(g_demoen && GetConVarBool(g_Cvar_AdmDisconnect))
       {
               decl String:checkplayer[24];
               GetClientAuthString(client, checkplayer, sizeof(checkplayer));

	       if(StrEqual(checkplayer, g_recstarter))
               {
                      StopRecord(client, true);
               }
       }
}

public Action:DemoreconConsole(client, args)
{
       if (args < 1)
       {
	       PrintToConsole(client, "Usage: demorecon <time_in_minutes>");
	       return Plugin_Handled;
       }

       if(!g_demoen) {
              new String:argcon[10];
              GetCmdArg(1, argcon, sizeof(argcon));
              g_recordtime = StringToInt(argcon) * 60;
              StartDemo(client);
       } else {
              PrintToConsole(client, "[AdminDemo] %t", "DemoAlready", g_startername);     
       }

       return Plugin_Handled;
}

public Action:DemorecoffConsole(client, args)
{
       if(!g_demoen) 
       {
              PrintToConsole(client, "[AdminDemo] %t", "DemoAbsent");
	      return Plugin_Handled;              
       } 
      
       if(client != 0)
       {
	      new String:checkstarter[24];
              GetClientAuthString(client, checkstarter, sizeof(checkstarter));

	      if(StrEqual(checkstarter, g_recstarter)) 
	      {
	              StopRecord(client);
	      } 
	      else 
	      {
	              PrintToConsole(client, "[AdminDemo] %t", "DemoBusy");
	      }
       }
       else
       {
	      StopRecord(client);
       }

       return Plugin_Handled;
}

public Action:DemorecordMenu(client, args)
{
       if(!client) 
       {
              PrintToConsole(client, "[AdminDemo] This command for ingame use only!");
	      return Plugin_Handled;              
       }
       
       DemorecMenu(client, true);
       return Plugin_Handled;
}

public Action:DemoCheckStatusConsole(client, args)
{
       if(!g_demoen) 
       {
              PrintToConsole(client, "[AdminDemo] %t", "DemoAbsent");
	      return Plugin_Handled;              
       } 
       
       if(g_recordtime != 0) 
       {
	      new mins, secs;
              if (g_timeelapsed > 0)
              {
                    mins = g_timeelapsed / 60;
	            secs = g_timeelapsed % 60;		
              }
	      
	      PrintToConsole(client, "[AdminDemo] %t", "DemoTimeName", g_recordtime / 60);
	      PrintToConsole(client, "[AdminDemo] %t", "RemainTime", mins, secs);
       } else {      
	      PrintToConsole(client, "[AdminDemo] %t", "DemoTimeName2");
	      PrintToConsole(client, "[AdminDemo] %t", "RemainTime2");
       }

       PrintToConsole(client, "[AdminDemo] %t", "RecStarter", g_startername);
       
       return Plugin_Handled;
}

public Action:DemoCallDumpToSourcetv(client, args)
{
       if(!g_demoen) 
       {
              PrintToConsole(client, "[AdminDemo] %t", "DemoAbsent");
	      return Plugin_Handled;              
       }

       if(g_CmdStatus == 0)
       {
              PrintToConsole(client, "[AdminDemo] %t", "CommandDisabled");
	      return Plugin_Handled;
       }

       CallStatus(INVALID_HANDLE);
       PrintToConsole(client, "[AdminDemo] %t", "InfoSend");

       return Plugin_Handled;
}

DumpStatusToSourcetv(client)
{
       decl String:srvip[16], String:srvport[8], String:auth[24], String:name[32], String:hostname[96], String:date[24];
                 
       GetConVarString(g_hSrvip, srvip, sizeof(srvip));
       GetConVarString(g_hSrvport, srvport, sizeof(srvport));
       GetClientName(0, hostname, sizeof(hostname));
       FormatTime(date, sizeof(date), "%d %b %Y  %H:%M");

       
       PrintToChat(client, "--------------------------------------------------");
       PrintToChat(client, "hostname : %s", hostname);
       PrintToChat(client, "ip/port  : %s:%s", srvip, srvport);
       PrintToChat(client, "date/time: %s", date);
       PrintToChat(client, "map      : %s", g_map);
       PrintToChat(client, "players  : %i (%i max)", GetClientCount(), MaxClients);
       PrintToChat(client, "--------------------------------------------------");
       PrintToChat(client, "SteamID               | IP address      | Name");
       PrintToChat(client, "--------------------------------------------------");
       
       for(new i = 1; i <= MaxClients; i++)
       {
	      if(IsClientConnected(i) && IsClientInGame(i))
	      {
		     GetClientAuthString(i, auth, sizeof(auth));
		     GetClientName(i, name, sizeof(name));
		     GetClientIP(i, srvip, sizeof(srvip));
		     PrintToChat(client, "%21s | %15s | %s", auth, srvip, name);
	      }
       }

       PrintToChat(client, "--------------------------------------------------");
}
