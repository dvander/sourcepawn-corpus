#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "0.3.04"
/// V 0.3.04
///		*Change sb_status when a new player connects to OnClientPostAdminCheck instead of OnClientAuthorized.
///			When OnClientAuthorized was used sb_status would be called too soon, so the new player would'nt show up in status :/
///		*Changed the OnMapEnd, so it's checks if a demo is recording before stoping an printing in log.

/// V 0.3.03
///		+Added OnMapEnd to kill the timer on mapchange.
///		+Added sb_status when a new player connects
///		*Changed log path..
///		*Fixed demo filename (Now YEAR-MONTH-DAY_HOUR-MINUTE-MAPANAME.dem, Before YEAR-MONTH-DAY_MINUTE-MINUTE-MAPNAME.dem)

new bool:g_demoen = false;
new g_nSecondsPassed = 0;
new timeelapsed;
new recordtime;
// Added after 0.3.02
//new pName;
//new sid;
//
new Handle:g_hTimer = INVALID_HANDLE;
new Handle:g_Cvar_Sourcetv = INVALID_HANDLE;

new String:g_recstarter[20];
new String:g_startername[64];
new String:map[64];
new String:date[32];
new String:logRec[PLATFORM_MAX_PATH];

new Handle:hTopMenu = INVALID_HANDLE;


public Plugin:myinfo = 
{
	name = "SrcTV demorecord with sb_status",
	author = "O!KAK modified by PhyRo",
	description = "Admin tool for SourceTV demo recording with sb_status",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
        LoadTranslations("plugin.demorecord");
	RegAdminCmd("demorecon", DemoreconConsole, ADMFLAG_CUSTOM1, "Console command for record demos");
	RegAdminCmd("demorecoff", DemorecoffConsole, ADMFLAG_CUSTOM1, "Console command for stop recording demos");
	///RegAdminCmd("demorec", DemoreStatusConsole, ADMFLAG_CUSTOM1, "Console command to check status of recording demos");     /// Use this to check status from console

	CreateConVar("demorec_version", PLUGIN_VERSION, _, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_Cvar_Sourcetv = FindConVar("tv_enable");
	
	BuildPath(Path_SM, logRec, PLATFORM_MAX_PATH, "logs/demorec.log");
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
		DemorecMenu(param);
	}
}

public Action:DemoRecTimer(Handle:timer)
{
        g_nSecondsPassed++;
               
        timeelapsed = (recordtime - g_nSecondsPassed);
    	
	if (g_nSecondsPassed == 3) 
		{ 
			ServerCommand("sb_status");
			/// LogToFileEx(logRec, "ServerCommand sb_status");  // Not needed now .. was only for debug..
		}

        if (g_nSecondsPassed >= recordtime - 1)
        {
		 ServerCommand("tv_stoprecord");
		 g_nSecondsPassed = 0;
		 recordtime = 0;
	         g_demoen = false;
		 g_hTimer = INVALID_HANDLE;

		 LogToFileEx(logRec, "Demo record stopped on time elapsed");
		 LogToFileEx(logRec, "-----------------------------------");

                 new iMaxClients = GetMaxClients();

	         for (new i = 1; i <= iMaxClients; i++)
                 {
	                 if (IsClientInGame(i))
		         { 
		                 if (GetUserFlagBits(i) & ADMFLAG_GENERIC)
			         {
			                  PrintToChat(i, "\x04[AdminDemo] %t", "DemoStopped", date, map);
		                 }
		         }
                 }
		 return Plugin_Stop;
        }
	return Plugin_Continue;
}
	                 
public Action:DemorecMenu(client)
{
        decl String:buffer[100];
	new String:checkstarter[20];
	GetClientAuthString(client, checkstarter, sizeof(checkstarter));
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
	        Format(buffer, sizeof(buffer), "%T", "StartRecord", client);
	        AddMenuItem(menu, "menu item", buffer, ITEMDRAW_DISABLED);
                if (StrEqual(checkstarter, g_recstarter)) {
	               Format(buffer, sizeof(buffer), "%T", "StopRecord", client);
	               AddMenuItem(menu, "menu item", buffer);
		} else {
                        Format(buffer, sizeof(buffer), "%T", "StopRecord", client);
	                AddMenuItem(menu, "menu item", buffer, ITEMDRAW_DISABLED);
		}
                Format(buffer, sizeof(buffer), "%T", "CheckStatus", client);
	        AddMenuItem(menu, "menu item", buffer);
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 15);

	return Plugin_Handled;
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
                                Stoprecord(param1);
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
	
	Format(buffer, sizeof(buffer), "5 %T", "Minutes", client);
	AddMenuItem(menu, "5", buffer);
	Format(buffer, sizeof(buffer), "10 %T", "Minutes", client);
	AddMenuItem(menu, "10", buffer);
	Format(buffer, sizeof(buffer), "15 %T", "Minutes", client);
	AddMenuItem(menu, "15", buffer);
	Format(buffer, sizeof(buffer), "20 %T", "Minutes", client);
	AddMenuItem(menu, "20", buffer);
	Format(buffer, sizeof(buffer), "25 %T", "Minutes", client);
	AddMenuItem(menu, "25",buffer);
	Format(buffer, sizeof(buffer), "30 %T", "Minutes", client);
	AddMenuItem(menu, "30", buffer);
	Format(buffer, sizeof(buffer), "40 %T", "Minutes", client);
	AddMenuItem(menu, "40", buffer);
	
	DisplayMenu(menu, client, 15);
}

public DemorecTimeHandler(Handle:menu, MenuAction:action, param1, param2)
{
        if (action == MenuAction_Select)
	{
		decl String:time[16];
		
		GetMenuItem(menu, param2, time, sizeof(time));
		recordtime = StringToInt(time) * 60;
		Startdemo(param1);
	} else if(action == MenuAction_End)	{
		CloseHandle(menu);
	}
}

public Action:CheckStatus(client)
{

        new mins, secs;
		
	if (timeelapsed > 0)
	{
		mins = timeelapsed / 60;
		secs = timeelapsed % 60;		
	}
        
	decl String:infoMessage[192], String:szHintMessage[192];
	Format(infoMessage, sizeof(infoMessage), "%T", "RecStarter", client, g_startername);

	if(recordtime != 0) {
                decl String:parsedMessage[192], String:demoMessage[192];
	        Format(parsedMessage, sizeof(parsedMessage), "%T", "RemainTime", client, mins, secs);
                Format(demoMessage, sizeof(demoMessage), "%T", "DemoTimeName", client, recordtime / 60);
	        Format(szHintMessage, sizeof(szHintMessage), "%s\n%s\n%s", demoMessage, infoMessage, parsedMessage);
	} else {
	        decl String:demoMessage[192];
		Format(demoMessage, sizeof(demoMessage), "%T", "DemoTimeName2", client);
	        Format(szHintMessage, sizeof(szHintMessage), "%s\n%s", demoMessage, infoMessage);
		PrintToChat(client, "\x04[AdminDemo] %t", "YouMustStop");
	}
		
	new Handle:HintMessage = StartMessageOne("HintText", client);
	BfWriteByte(HintMessage, -1);
	BfWriteString(HintMessage, szHintMessage);
	EndMessage();
}

public Action:Startdemo(client)
{
       if (!GetConVarInt(g_Cvar_Sourcetv))
       {
                PrintToChat(client, "\x04[AdminDemo] %t", "TvNotEnabled");
		return Plugin_Handled;
       }

       FormatTime(date, sizeof(date), "%Y-%m-%d_%H-%M");
       GetCurrentMap(map, sizeof(map));
		
       ServerCommand("tv_stoprecord");
       ServerCommand("tv_record %s-%s", date, map);
       g_demoen = true;

       if(client != 0)
       {
                GetClientAuthString(client, g_recstarter, sizeof(g_recstarter));
                GetClientName(client, g_startername, sizeof(g_startername));
		PrintToChat(client, "\x04[AdminDemo] %t", "DemoStarted", date, map);
		LogToFileEx(logRec, "Admin <%s> <%s> start record a demo %s-%s (%i minutes)", g_startername, g_recstarter, date, map, recordtime / 60);
       } else {
                LogToFileEx(logRec, "Admin (console) start record a demo %s-%s (%i minutes)", date, map, recordtime / 60);
       }

       if (g_hTimer != INVALID_HANDLE)
       {
	        KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
       }
       
       if(recordtime != 0) {
                g_hTimer = CreateTimer(1.0, DemoRecTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
       }

       return Plugin_Continue;
}

public Action:Stoprecord(client)
{
       if(recordtime != 0) {
                KillTimer (g_hTimer);
                g_hTimer = INVALID_HANDLE;
       }

       ServerCommand("tv_stoprecord");
       g_nSecondsPassed = 0;
       g_demoen = false;
       recordtime = 0;
       timeelapsed = 0;

       new iMaxClients = GetMaxClients();

       decl String:admin[32];
       GetClientName(client, admin, sizeof(admin));       
	
       for (new i = 1; i <= iMaxClients; i++)
       {
                if (IsClientInGame(i))
	        { 
		         if (GetUserFlagBits(i) & ADMFLAG_GENERIC)
			 {
			          PrintToChat(i, "\x04[AdminDemo] %t", "DemoStopper", admin);
		         }
		}
       }

       LogToFileEx(logRec, "Admin \"%L\" stopped record a demo", client);
       LogToFileEx(logRec, "-----------------------------------");

       return Plugin_Continue;
}

public OnClientDisconnect(client)
{
       decl String:g_checkplayer[20];
       GetClientAuthString(client, g_checkplayer, 20);

       if (g_demoen)
       {
                if(StrEqual(g_checkplayer, g_recstarter))
                {
                         if(recordtime != 0) {
			         KillTimer (g_hTimer);
		                 g_hTimer = INVALID_HANDLE;
		         }
		         
		         ServerCommand("tv_stoprecord");
			 g_demoen = false;
                         g_nSecondsPassed = 0;
			 recordtime = 0;
			 timeelapsed = 0;
			 LogToFileEx(logRec, "Stop recording demo on ClientDiscconnect");
		         LogToFileEx(logRec, "-----------------------------------");
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
              recordtime = StringToInt(argcon) * 60;
              Startdemo(client);
       } else {
              PrintToConsole(client, "[AdminDemo] %t", "DemoAlready", g_startername);
	      return Plugin_Handled;
       }

       return Plugin_Continue;
}

public Action:DemorecoffConsole(client, args)
{
       if(!g_demoen) 
       {
              PrintToConsole(client, "[AdminDemo] %t", "DemoAbsent");
	      return Plugin_Handled;              
       } 
       else 
       {
              if(client != 0)
              {
	              new String:checkstarter[20];
                      GetClientAuthString(client, checkstarter, sizeof(checkstarter));

		      if (StrEqual(checkstarter, g_recstarter)) 
	              {
	                      Stoprecord(client);
	              } 
	              else 
	              {
	                      PrintToConsole(client, "[AdminDemo] %t", "DemoBusy");
		              return Plugin_Handled;
	              }
              }
	      else
	      {
	             Stoprecord(client);
	      }
       }

       return Plugin_Continue;
}


//// Added after 0.3.02

public OnMapEnd() {
	// Delete that annoying timer that keeps bugging the plugin ..
	// Also make a log entry that demo has stopped recording due to end of map
	// Copy and paste FTW :D
       if(g_demoen) 	{
	
	       if(recordtime != 0) 	{
                KillTimer (g_hTimer);
                g_hTimer = INVALID_HANDLE;
								}
		LogToFileEx(logRec, "Demo stopped recording due to mapchange.");

       ServerCommand("tv_stoprecord");
       g_nSecondsPassed = 0;
       g_demoen = false;
       recordtime = 0;
       timeelapsed = 0;
						}
	
}

public OnClientPostAdminCheck(client) {
	// When a new player has connected and is authed, send sb_status to console again
	//
	if(g_demoen) 	{
	decl String:sid[20];
	decl String:pName[32];
	GetClientName(client,pName,sizeof(pName));
	GetClientAuthString(client,sid,sizeof(sid));
	if (!StrEqual(sid,"BOT")) 	{
	ServerCommand("sb_status");
		LogToFileEx(logRec, "New player connected %s %s, sb_status sent again.", sid,pName);
							}
					}
}
