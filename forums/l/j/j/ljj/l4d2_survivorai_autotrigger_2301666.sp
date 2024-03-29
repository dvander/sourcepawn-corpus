/**
 * Time: 2015/05/27
 * Version: 1.1
 * - Support all game mode.
 * - Remake some auto trigger. Now it's auto trigger is simpler than before.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.3"

new bool:MapTrigger;
new bool:MapTriggerTwo;
//new bool:MapTriggerThree;
//new bool:MapTriggerFourth;
new bool:WarpTrigger;
//new bool:WarpTriggerTwo;
new TriggeringBot;

new bool:GameRunning;

new bool:FinaleHasStarted;

public Plugin:myinfo =
{
	name = "L4D2 Survivor AI Auto Trigger",
	author = "ljj",
	description = "The plugin will help bots trigger the switch what they can not trigger themselves.",
	version = PLUGIN_VERSION,
	url = "NONE"
};

public OnPluginStart()
{
	CreateConVar("l4d2_survivoraitriggerfix_version", PLUGIN_VERSION, " Version of L4D2 Survivor AI Auto Trigger on this server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	CreateTimer(3.0, CheckAroundTriggers, 0, TIMER_REPEAT);
	
	HookEvent("finale_start", FinaleBegins);
	HookEvent("round_end", GameEnds);
	HookEvent("map_transition", GameEnds);
	HookEvent("mission_lost", GameEnds);
	HookEvent("finale_win", GameEnds);
}

public OnMapStart()
{
	MapTrigger = false;
	MapTriggerTwo = false;
	//MapTriggerThree = false;
	//MapTriggerFourth = false;
	WarpTrigger = false;
	FinaleHasStarted = false;
}

public OnMapEnd()
{
	MapTrigger = false;
	MapTriggerTwo = false;
	//MapTriggerThree = false;
	//MapTriggerFourth = false;
	WarpTrigger = false;
}

public OnClientConnected(client)
{
	if (IsFakeClient(client)) return;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				GameRunning = true;
				return;
			}
		}
	}
	GameRunning = false;
}

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client))
	{
		GameRunning = true;
	}
}

public OnClientDisconnect_Post(client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				GameRunning = true;
				return;
			}
		}
	}
	GameRunning = false;
}

public Action:GameEnds(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(7.0, DelayedBoolReset, 0);
	FinaleHasStarted = false;
}

public Action:FinaleBegins(Handle:event, const String:name[], bool:dontBroadcast)
{
	FinaleHasStarted = true;
}

public Action:DelayedBoolReset(Handle:Timer)
{
	MapTrigger = false; // to circumvent bugs with slow-ass l4d engine.
	MapTriggerTwo = false;
	//MapTriggerThree = false;
	//MapTriggerFourth = false;
	WarpTrigger = false;
}

public Action:CheckAroundTriggers(Handle:timer)
{
	if (!GameRunning) return Plugin_Continue;
		
	if (!AllBotTeam()) return Plugin_Continue;

	decl String:mapname[256];
	GetCurrentMap(mapname, sizeof(mapname));
	
	// Dead Center 1 is fine in Coop

	if (StrContains(mapname, "c1m2_streets", false) != -1)
	{
		// Dead Center 02
		// pos -6698.6 -962.6 448.4
		
		decl Float:pos1[3];
		pos1[0] = -6698.6;
		pos1[1] = -962.6;
		pos1[2] = 448.4;
		
		if (CheckforBots(pos1, 400.0) && !WarpTrigger)
		{
			//PrintToChatAll("\x04[AutoTrigger] \x01Bot found stuck near supermarket, initiating in 10 seconds.");
			//PrintToChatAll("\x04[AutoTrigger] \x01Crescendo will end 60 seconds after that.");
			PrintToChatAll("\x04[AutoTrigger] \x01Start c1m2 trigger.");

			// position cola: -7377.6 -1372.1 427.2
			new Handle:posonedata = CreateDataPack();
			WritePackFloat(posonedata, -7377.6);
			WritePackFloat(posonedata, -1372.1);
			WritePackFloat(posonedata, 427.2);
			CreateTimer(10.0, WarpAllBots, posonedata);
			CreateTimer(10.0, CallSuperMarket);
			
			// position give cola: -5375.4 -2016.0 678.0
			new Handle:postwodata = CreateDataPack();
			WritePackFloat(postwodata, -5375.4);
			WritePackFloat(postwodata, -2016.0);
			WritePackFloat(postwodata, 678.0);
			CreateTimer(65.0, WarpAllBots, postwodata);
			CreateTimer(70.0, CallTankerBoom);
			
			WarpTrigger = true;
		}
	}
	
	if (StrContains(mapname, "c1m3_mall", false) != -1)
	{
		// Dead Center 03 - emergency door or windows
		// name door_hallway_lower4a, class prop_door_rotating, Input "Open"
		// they do the rest veeery slowly, but by themselves
		
		new door = FindEntityByName("door_hallway_lower4a", -1);
		
		decl Float:pos1[3];
		if (door > 0)
		{
			GetEntityAbsOrigin(door, pos1);
			if (CheckforBots(pos1, 200.0) && !MapTrigger)
			{
				//PrintToChatAll("\x04[AutoTrigger] \x01Bot found close to the Emergency Door, open sesame...");
				//PrintToChatAll("\x04[AutoTrigger] \x01Warping them all ahead in 30 seconds.");
				PrintToChatAll("\x04[AutoTrigger] \x01Start c1m3 trigger.");

				AcceptEntityInput(door, "Open");

				new Handle:posxdata = CreateDataPack();
				WritePackFloat(posxdata, 1207.4);
				WritePackFloat(posxdata, -3180.1);
				WritePackFloat(posxdata, 598.0);
				CreateTimer(30.0, WarpAllBots, posxdata);
				MapTrigger = true;
			}
		}
		
		new glass = FindEntityByName("breakble_glass_minifinale", -1); //Valve typing error, lol
		if (glass > 0)
		{
			GetEntityAbsOrigin(glass, pos1);
			if (CheckforBots(pos1, 200.0) && !MapTrigger)
			{
				//PrintToChatAll("\x04[AutoTrigger] \x01Bot found close to the Alarmed Windows, open sesame...");
				//PrintToChatAll("\x04[AutoTrigger] \x01Warping them all ahead in 30 seconds.");
				PrintToChatAll("\x04[AutoTrigger] \x01Start c1m3 trigger.");

				new Handle:posxdata = CreateDataPack();
				WritePackFloat(posxdata, 1207.4);
				WritePackFloat(posxdata, -3180.1);
				WritePackFloat(posxdata, 598.0);
				CreateTimer(30.0, WarpAllBots, posxdata);
				MapTrigger = true;
			}
		}
	}
	
	// Dead Center 4 - use ScavengeBots plugin
	if (StrContains(mapname, "c1m4_atrium", false) != -1)
	{
		//new button = FindEntityByName("button_elev_3rdfloor", -1);
		
		decl Float:pos1[3];
		pos1[0] = -4037.9;
		pos1[1] = -3411.3;
		pos1[2] = 598.0;
		//GetEntityAbsOrigin(button, pos1);
			
		if (CheckforBots(pos1, 200.0) && !MapTrigger)
		{
			//PrintToChatAll("\x04[AutoTrigger] \x01TEST01.");
			CreateTimer(5.0, BotsUnstick);
			MapTrigger = true;
		}
		
		decl Float:pos2[3];
		pos2[0] = -4033.6;
		pos2[1] = -3415.1;
		pos2[2] = 66.0;
		
		if (CheckforBots(pos2, 200.0) && !MapTriggerTwo)
		{
			//PrintToChatAll("\x04[AutoTrigger] \x01TEST02.");
			CreateTimer(10.0, BotsStick);
			MapTriggerTwo = true;
		}
	}
	// Dark Carnival 1 is fine in Coop
	
	// Dark Carnival 2 is fine in Coop
	
	if (StrContains(mapname, "c2m3_coaster", false) != -1)
	{
		// Dark Carnival 03 - coaster buttons
		
		// Go: name minifinale_button, class func_button, Input "Press"
		// they do the rest veeery slowly, but by themselves
		
		new button = FindEntityByName("minifinale_button", -1);
		
		if (!IsValidEntity(button))
		{
			MapTrigger = true;
		}
		else
		{
			decl Float:pos1[3];
			GetEntityAbsOrigin(button, pos1);
			
			if (CheckforBots(pos1, 250.0) && !MapTrigger)
			{
				PrintToChatAll("\x04[AutoTrigger] \x01Start c2m3 trigger.");
				AcceptEntityInput(button, "Press");
				MapTrigger = true;

				//CreateTimer(250.0, C2M3WarpAllBotToThere, 0);
			}
		}
	
		// c2m3 - after shut off the rollercoaster, warp them to the special spot
		decl Float:posx[3];
		posx[0] = -4029.9;
		posx[1] = 1428.9;
		posx[2] = 222.0;
		// confusion spot -4029.9 1428.9 222.0, teleport them off
		// to: -4315.1 2311.4 313.2
		if (CheckforBots(posx, 200.0) && !WarpTrigger)
		{
			PrintToChatAll("\x04[AutoTrigger] \x01Start c2m3 special trigger.");
			
			new Handle:posdata = CreateDataPack();
			WritePackFloat(posdata, -4315.1);
			WritePackFloat(posdata, 2311.4);
			WritePackFloat(posdata, 313.2);
			CreateTimer(50.0, WarpAllBots, posdata);
			WarpTrigger = true;
		}

	}
	
	// Dark Carnival 4 is fine in Coop
	
	if (StrContains(mapname, "c2m5_concert", false) != -1)
	{
		if (MapTrigger) return Plugin_Continue;
		// map is Dark Carnival 5

		decl Float:pos1[3];
		pos1[0] = -3406.7;
		pos1[1] = 3003.2;
		pos1[2] = -193.9;
		
		if (CheckforBots(pos1, 200.0) && !MapTrigger)
		{
			PrintToChatAll("\x04[AutoTrigger] \x01Start c2m5 trigger.");
			//AcceptEntityInput(lightsbutton, "Press");
			UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "stage_lights_button", "Use");
			MapTrigger = true;
		}
	}
	
	if (StrContains(mapname, "c3m1_plankcountry", false) != -1)
	{
		// Swamp Fever 01 - classic crescendo
		// they freakin KILL THEMSELVES by teleporting into the river, yay
		// name: ferry_button, func_button
		
		new button = FindEntityByName("ferry_button", -1);
		
		if (!IsValidEntity(button) && !MapTrigger)
		{
			SetConVarInt(FindConVar("sb_unstick"), 0);
			MapTrigger = true;

			PrintToChatAll("\x04[AutoTrigger] \x01Start c3m1 special trigger.");
			// position: -5470.1 6092.6 90.2
			new Handle:posdata = CreateDataPack();
			WritePackFloat(posdata, -5470.1);
			WritePackFloat(posdata, 6092.6);
			WritePackFloat(posdata, 90.2);
			CreateTimer(75.0, WarpAllBots, posdata, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(150.0, BotsUnstick);
		}
		/*
		decl Float:posx[3];
		posx[0] = -4340.6;
		posx[1] = 6068.1;
		posx[2] = 60.2;
		// confusion spot -4340.6 6068.1 60.2
		if (CheckforBots(posx, 100.0) && !MapTriggerTwo)
		{
			SetConVarInt(FindConVar("sb_unstick"), 1);
			MapTriggerTwo = true;
		}
		*/
	}
	
	// Swamp Fever 2 is fine in Coop

	// Swamp Fever 3 is fine in Coop
	
	if (StrContains(mapname, "c3m4_plantation", false) != -1)
	{
		// map is Swamp Fever 4
		
		// getpos 1667.1 -114.4 286.0
		decl Float:pos1[3];
		pos1[0] = 1667.1;
		pos1[1] = -114.4;
		pos1[2] = 286.0;

		//new button = FindEntityByName("escape_gate_button", -1);
		
		// finale balcony coordinates - getpos 1524.9 1937.5 188.1	
		if (CheckforBots(pos1, 300.0) && !MapTrigger)
		{
			PrintToChatAll("\x04[AutoTrigger] \x01Start c3m4 trigger.");
			UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "escape_gate_button", "Press");
			//AcceptEntityInput(button, "Press");
			MapTrigger = true;

			CreateTimer(30.0, C3M4FinaleStart);
		}
	}
	
	//Hard Rain 1 - is fine in Coop
	
	if (StrContains(mapname, "c4m2_sugarmill_a", false) != -1)
	{
		// Hard Rain 02  -1413.3 -9390.2 671.1
		decl Float:pos1[3];
		pos1[0] = -1413.3;
		pos1[1] = -9390.2;
		pos1[2] = 671.1;
		// confusion spot -1413.3 -9390.2 671.1
		if (CheckforBots(pos1, 200.0) && !MapTrigger)
		{
			PrintToChatAll("\x04[AutoTrigger] \x01Start c4m2 special trigger.");
			SetConVarInt(FindConVar("sb_unstick"), 0);
			MapTrigger = true;
		}

		decl Float:pos2[3];
		pos2[0] = -1370.9;
		pos2[1] = -9549.0;
		pos2[2] = 190.2;
		// confusion spot -1370.9 -9549.0 190.2
		if (CheckforBots(pos2, 200.0) && !MapTriggerTwo)
		{
			SetConVarInt(FindConVar("sb_unstick"), 1);
			CreateTimer(1.0, C4M2BotsActions);
			CreateTimer(11.0, ResumeBotsActions);
			MapTriggerTwo = true;
		}
	}
	
	//Hard Rain 3 - is fine in Coop
	
	//Hard Rain 4 - is fine in Coop
	
	//Hard Rain 5 - is fine in Coop, astonishingly
	
	//The Parish 1 - is fine in Coop
	
	if (StrContains(mapname, "c5m2_park", false) != -1)
	{
		// c5m2_park - name finale_cleanse_entrance_door class prop_door_rotating "close"
		// huddle -9654.8 -5962.8 -166.8 -9645.740234 -5970.330566 -151.945755;
		// name finale_cleanse_exit_door, class prop_door_rotating "open" - a few secs later
		
		// -9614.2 -5981.5 -151.9;
		// ready into the trailer
		decl Float:pos1[3];
		pos1[0] = -9614.2;
		pos1[1] = -5981.5;
		pos1[2] = -151.9;
		
		if (CheckforBots(pos1, 100.0) && !MapTrigger)
		{
			PrintToChatAll("\x04[AutoTrigger] \x01Start c5m2 trigger.");
			/*
			new Handle:posdata = CreateDataPack();
			WritePackFloat(posdata, pos1[0]);
			WritePackFloat(posdata, pos1[1]);
			WritePackFloat(posdata, pos1[2]);
			CreateTimer(0.5, WarpAllBots, posdata);
			*/
			CreateTimer(10.0, RunBusStationEvent);
			MapTrigger = true;
		}
	}
	
	//The Parish 3 - is fine in Coop
	
	if (StrContains(mapname, "c5m4_quarter", false) != -1)
	{
		//c5m4_quarter - huddle after crescendo -1487.0 684.0 109.0
		// teleport to -2179.3,389.3,302.0;
		// -2019.551636 494.859070 302.031250;
		// 70sec
		
		new button = FindEntityByName("tractor_button", -1);
		
		//decl Float:pos1[3];
		//pos1[0] = -1487.0;
		//pos1[1] = 684.0;
		//pos1[2] = 109.0;
		
		if (!IsValidEntity(button) && !MapTrigger)
		{
			PrintToChatAll("\x04[AutoTrigger] \x01Start c5m4 special trigger.");
			//CreateTimer(100.0, C5M4BotsActions);
			MapTrigger = true;
			
			new Handle:posdata = CreateDataPack();
			WritePackFloat(posdata, -1864.4);
			WritePackFloat(posdata, 474.3);
			WritePackFloat(posdata, 302.0);
			CreateTimer(100.0, WarpAllBots, posdata);
		}
		/*
		decl Float:pos1[3];
		pos1[0] = -2179.3;
		pos1[1] = 389.3;
		pos1[2] = 302.0;
		if (CheckforBots(pos1, 100.0) && !MapTriggerTwo)
		{
			PrintToChatAll("\x04[AutoTrigger] \x015���ָ���");
			CreateTimer(5.0, ResumeBotsActions);
			MapTriggerTwo = true;
		}
		*/
	}

	if (StrContains(mapname, "c5m5_bridge", false) != -1)
	{
		// c5m5_bridge   pos -11591.227539 6172.690430 518.031250;
		// name radio_fake_button, class func_button "Press"
		// a little later standard finale call
		
		new button = FindEntityByName("radio_fake_button", -1);
		
		if (!IsValidEntity(button) && !MapTrigger)
		{
			MapTrigger = true;
			CreateTimer(13.0, C5M5FinaleStart);
		}
		else
		{
			decl Float:pos1[3];
			GetEntityAbsOrigin(button, pos1);
			
			if (CheckforBots(pos1, 200.0) && !MapTrigger)
			{
				//PrintToChatAll("\x04[AutoTrigger] \x01C5M5FinaleTrigger.");
				UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "radio_fake_button", "Use");
				//AcceptEntityInput(button, "Press");
				
				CreateTimer(13.0, C5M5FinaleStart);
				MapTrigger = true;
			}
		}
	}

	//The Passing 01 - is fine in Coop

	if (StrContains(mapname, "c6m2_bedlam", false) != -1)
	{
		// The Passing 02
		decl Float:posx[3];
		posx[0] = 439.9;
		posx[1] = 1689.4;
		posx[2] = -125.1;
		// confusion spot 439.9 1689.4 -125.1, teleport them off
		// to: 36.9 1888.7 -1.9;
		if (CheckforBots(posx, 200.0) && !WarpTrigger)
		{
			PrintToChatAll("\x04[AutoTrigger] \x01Start c6m2 trigger.");

			new Handle:posdata = CreateDataPack();
			WritePackFloat(posdata, 36.9);
			WritePackFloat(posdata, 1888.7);
			WritePackFloat(posdata, -1.9);
			CreateTimer(10.0, WarpAllBots, posdata);

			WarpTrigger = true;
		}
	}

	//The Passing 03 - use ScavengeBots plugin

	if (StrContains(mapname, "c7m1_docks", false) != -1)
	{
		// The Sacrifice 01
		
		new button = FindEntityByName("tankdoorin_button", -1);
		
		if (!IsValidEntity(button))
		{
			MapTrigger = true;
		}
		else
		{
			decl Float:pos1[3];
			GetEntityAbsOrigin(button, pos1);
			
			if (CheckforBots(pos1, 150.0) && !MapTrigger)
			{
				PrintToChatAll("\x04[AutoTrigger] \x01Start c7m1 trigger1.");
				AcceptEntityInput(button, "Press");
				if (!IsCoop())
				CreateTimer(5.0, TankDoor01COOP, 0);
				else if (!IsVersus())
				CreateTimer(5.0, TankDoor01VERSUS, 0);

				MapTrigger = true;
			}
		}

		if (!IsValidEntity(FindEntityByName("tankdoorout_button", -1)))
		{
			MapTriggerTwo = true;
		}
		else
		{
			decl Float:pos2[3];
			GetEntityAbsOrigin(FindEntityByName("tankdoorout_button", -1), pos2);
			
			if (CheckforBots(pos2, 100.0) && !MapTriggerTwo)
			{
				PrintToChatAll("\x04[AutoTrigger] \x01Start c7m1 trigger1-1.");
				AcceptEntityInput(FindEntityByName("tankdoorout_button", -1), "Press");
				CreateTimer(5.0, TankDoor02, 0);
				MapTriggerTwo = true;
			}
		}
	}

	if (StrContains(mapname, "c7m2_barge", false) != -1)
	{
		// The Sacrifice 02
		decl Float:posx[3];
		posx[0] = -4355.0;
		posx[1] = -62.0;
		posx[2] = 62.0;
		// confusion spot -4355.0 -62.0 62.0, teleport them off
		// to: -5408.7 858.6 696.4
		if (CheckforBots(posx, 200.0) && !WarpTrigger)
		{
			PrintToChatAll("\x04[AutoTrigger] \x01Strat c13m2 trigger.\x01");
			
			new Handle:posdata = CreateDataPack();
			WritePackFloat(posdata, -5408.7);
			WritePackFloat(posdata, 858.6);
			WritePackFloat(posdata, 696.4);
			CreateTimer(10.0, WarpAllBots, posdata);
			WarpTrigger = true;
		}
	}
	/**
	 * ==========================================================================
	 * 				Warning!!!
	 * This trigger has a bug, it will make the survivor bots lose game!
	 * I don't know how to fix it.
	 * ==========================================================================
	if (StrContains(mapname, "c7m3_port", false) != -1)
	{
		// The Sacrifice 03

		if (!IsValidEntity(FindEntityByName("finale_start_button", -1)) && !MapTrigger)
		{
			MapTrigger = true;
		}
		else
		{
			decl Float:pos1[3];
			GetEntityAbsOrigin(FindEntityByName("finale_start_button", -1), pos1);
			
			if (CheckforBots(pos1, 300.0) && !MapTrigger)
			{
				PrintToChatAll("\x04[AutoTrigger] \x01Bot found close to the first generator button, pressing...");
				AcceptEntityInput(FindEntityByName("finale_start_button", -1), "Press");
				CreateTimer(5.0, C7M3GeneratorStart);
				MapTrigger = true;

				CreateTimer(20.0, C7M3WarpBotsToGenerator1);
			}
		}

		if (!IsValidEntity(FindEntityByName("finale_start_button1", -1)) && MapTrigger && !MapTriggerTwo)
		{
			MapTriggerTwo = true;
		}
		else
		{
			decl Float:pos1[3];
			GetEntityAbsOrigin(FindEntityByName("finale_start_button1", -1), pos1);
			
			if (CheckforBots(pos1, 300.0) && !MapTriggerTwo)
			{
				PrintToChatAll("\x04[AutoTrigger] \x01Bot found close to the second generator button, pressing...");
				AcceptEntityInput(FindEntityByName("finale_start_button1", -1), "Press");
				CreateTimer(5.0, C7M3GeneratorStart1);
				MapTriggerTwo = true;

				CreateTimer(20.0, C7M3WarpBotsToGenerator2);
			}
		}
		
		if (!IsValidEntity(FindEntityByName("finale_start_button2", -1)) && MapTrigger && MapTriggerTwo && !MapTriggerThree)
		{
			MapTriggerThree = true;
		}
		else
		{
			decl Float:pos1[3];
			GetEntityAbsOrigin(FindEntityByName("finale_start_button2", -1), pos1);
			
			if (CheckforBots(pos1, 300.0) && !MapTriggerThree)
			{
				PrintToChatAll("\x04[AutoTrigger] \x01Bot found close to the third generator button, pressing...");
				AcceptEntityInput(FindEntityByName("finale_start_button2", -1), "Press");
				CreateTimer(5.0, C7M3GeneratorStart2);
				MapTriggerThree = true;
			}
		}

		decl Float:pos1[3];
		pos1[0] = -0.8;
		pos1[1] = -1360.1;
		pos1[2] = 56.5;

		if (CheckforBots(pos1, 100.0) && !MapTriggerFourth)
		{
			PrintToChatAll("\x04[AutoTrigger] \x01Bot found at a stuck spot, warping them all ahead in 10 seconds");
		
			new Handle:posdata = CreateDataPack();
			WritePackFloat(posdata, -123.2);
			WritePackFloat(posdata, -1747.9);
			WritePackFloat(posdata, 314.0);
			CreateTimer(10.0, WarpAllBots, posdata);
			CreateTimer(12.0, C7M3BridgeStartButton, 0);

			MapTriggerFourth = true;

			CreateTimer(30.0, C7M3GeneratorFinaleButtonStart, 0);
		}
	}
	*/
	if (StrContains(mapname, "c9m2_lots", false) != -1)
	{
		// Crash Course 02
		
		// Go: name finaleswitch_initial, class func_button_timed, Input "Press"
		// they do the rest veeery slowly, but by themselves
		
		new button = FindEntityByName("finaleswitch_initial", -1);
		
		if (!IsValidEntity(button))
		{
			MapTrigger = true;
		}
		else
		{
			decl Float:pos1[3];
			GetEntityAbsOrigin(button, pos1);
			
			if (CheckforBots(pos1, 500.0) && !MapTrigger)
			{
				PrintToChatAll("\x04[AutoTrigger] \x01Strat c9m2 trigger1.");
				AcceptEntityInput(button, "Press");
				CreateTimer(5.0, GeneratorStart, 0);
				MapTrigger = true;

				// Crash Cause 02 - Generator Second Start
				CreateTimer(205.0, GeneratorStartTwoReady, 0);
				CreateTimer(210.0, GeneratorStartTwo, 0);
			}

		}
	}

	if (StrContains(mapname, "c10m4_mainstreet", false) != -1)
	{
		// map is Death Toll 4

		new button = FindEntityByName("button", -1);

		decl Float:pos1[3];
		GetEntityAbsOrigin(button, pos1);

		if (CheckforBots(pos1, 200.0) && !MapTrigger)
		{
			PrintToChatAll("\x04[AutoTrigger] \x01Strat c10m4 trigger.");
			UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "button", "Use");
			MapTrigger = true;
		}
	}

	if (StrContains(mapname, "c10m5_houseboat", false) != -1)
	{
		// map is Death Toll 5
		// 3884.3 -4144.5 -89.9
		//new button = FindEntityByName("radio_button", -1);

		decl Float:pos1[3];
		pos1[0] = 3884.3;
		pos1[1] = -4144.5;
		pos1[2] = -89.9;
		//GetEntityAbsOrigin(button, pos1);

		if (CheckforBots(pos1, 100.0) && !MapTrigger)
		{
			PrintToChatAll("\x04[AutoTrigger] \x01Strat c10m5 trigger.");
			UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "radio_button", "Use");
			//UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "orator_boat_radio", "Kill");

			MapTrigger = true;

			CreateTimer(20.0, C10M5FinaleStart, 0);
		}
	}

	if (StrContains(mapname, "c11m3_garage", false) != -1)
	{
		// map is Dead Air 3.

		new gascans = FindEntityByName("barricade_gas_can", -1);
		
		if (gascans == -1) // has it been destroyed already? continue without doing anything.
		{
			MapTrigger = true;
			return Plugin_Continue;
		}
			
		decl Float:pos1[3];
		GetEntityAbsOrigin(gascans, pos1);
	
		if (CheckforBots(pos1, 900.0) && !MapTrigger)
		{
			PrintToChatAll("\x04[AutoTrigger] \x01Strat c11m3 trigger.");
			AcceptEntityInput(gascans, "Ignite");
			MapTrigger = true;
		}
	}

	if (StrContains(mapname, "c11m5_runway", false) != -1)
	{
		// map is Dead Air 5
		// pos -5033.4 9164.0 -129.9
		
		new button = FindEntityByName("radio_fake_button", -1);

		if (!IsValidEntity(button) && !MapTrigger)
		{
			//PrintToChatAll("\x04[AutoTrigger] \x01Strat c11m5 trigger.");
			CreateTimer(20.0, C11M5FinaleStart, 0);
			MapTrigger = true;
		}
	}

	if (StrContains(mapname, "c12m2_traintunnel", false) != -1)
	{
		// map is BH2
		//decl Float:posdoor[3], Float:postriggerer[3], Float:anglestriggerer[3];
		decl Float:posdoor[3];
		
		posdoor[0] = -8605.0;
		posdoor[1] = -7530.0;
		posdoor[2] = -21.0;
		/*
		postriggerer[0] = -8600.0;
		postriggerer[1] = -7504.0;
		postriggerer[2] = -60.0;
		
		anglestriggerer[0] = 8.0;
		anglestriggerer[1] = -90.0;
		anglestriggerer[2] = 0.0;
		*/
		if (CheckforBots(posdoor, 300.0) && !MapTrigger)
		{
			PrintToChatAll("\x04[AutoTrigger] \x01Strat c12m2 trigger.");
			MapTrigger = true;
			
			//TeleportEntity(TriggeringBot, postriggerer, anglestriggerer, NULL_VECTOR); // move bot infront of the door, facing it
			
			UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "emergency_door", "open");
		}
	}
	
	if (StrContains(mapname, "c13m1_alpinecreek", false) != -1)
	{
		// Cold Stream 01
		
		decl Float:posx[3];
		posx[0] = 1068.9;
		posx[1] = 251.4;
		posx[2] = 766.0;

		if (CheckforBots(posx, 100.0) && !MapTrigger)
		{
			PrintToChatAll("\x04[AutoTrigger] \x01Strat c13m1 trigger.");
			AcceptEntityInput(FindEntityByName("bunker_button", -1), "Press");
			MapTrigger = true;
		}
	}
	
	if (StrContains(mapname, "c13m2_southpinestream", false) != -1)
	{
		// Cold Stream 02
		
		decl Float:posx[3];
		posx[0] = 119.1;
		posx[1] = 5574.1;
		posx[2] = 334.0;

		if (CheckforBots(posx, 400.0) && !MapTrigger)
		{
			PrintToChatAll("\x04[AutoTrigger] \x01Strat c13m2 trigger.");
			
			CreateTimer(1.0, BotsStopMove);
			CreateTimer(5.0, C13M2Trigger);
			CreateTimer(11.0, BotsStartMove);
			MapTrigger = true;
		}
	}

	if (StrContains(mapname, "c13m4_cutthroatcreek", false) != -1)
	{
		// Cold Stream 04
		// getpos -4127.968750 -7866.249023 433.031250;
		decl Float:posx[3];
		posx[0] = -4127.9;
		posx[1] = -7866.2;
		posx[2] = 433.0;

		if (CheckforBots(posx, 100.0))
		{
			new button = FindEntityByClassname(-1, "startbldg_door_button");
			
			if (!IsValidEntity(button) && MapTrigger==false)
			{
				MapTrigger = true;
				CreateTimer(1.0, BotsStick, 0);
				CreateTimer(20.0, FinaleStart, 0);
				CreateTimer(23.0, BotsUnstick, 0);
				return Plugin_Continue;
			}
		}
	}

	return Plugin_Continue;
}

public Action:WarpAllBots(Handle:Timer, Handle:posdata)
{
	ResetPack(posdata);
	decl Float:position[3];
	position[0] = ReadPackFloat(posdata);
	position[1] = ReadPackFloat(posdata);
	position[2] = ReadPackFloat(posdata);
	CloseHandle(posdata);
	
	PrintToChatAll("\x04[AutoTrigger] \x01Warping Bots now.");
	
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (IsPlayerAlive(target) && GetClientTeam(target) == 2 && IsFakeClient(target)) // make sure target is a Survivor Bot
			{
				TeleportEntity(target, position, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}

public Action:BotsStopMove(Handle:Timer)
{
	// Dead Center 02 - Go In The Market
	SetConVarInt(FindConVar("sb_move"), 0);
}

public Action:BotsStartMove(Handle:Timer)
{
	// Dead Center 02 - Out Off The Market
	SetConVarInt(FindConVar("sb_move"), 1);
}

public Action:BotsStick(Handle:Timer)
{
	// Cold Stream 04 - Finale Started
	SetConVarInt(FindConVar("sb_unstick"), 0);
}

public Action:BotsUnstick(Handle:Timer)
{
	// Cold Stream 04 - Finale Started
	SetConVarInt(FindConVar("sb_unstick"), 1);
}

public Action:BotsOffFire(Handle:Timer)
{
	// Cold Stream 04 - Finale Started
	SetConVarInt(FindConVar("sb_open_fire"), 0);
}

public Action:BotsOpenFire(Handle:Timer)
{
	// Cold Stream 04 - Finale Started
	SetConVarInt(FindConVar("sb_open_fire"), 1);
}

public Action:CallSuperMarket(Handle:Timer)
{
	// name store_doors, class prop_door_rotating - input "Open"
	AcceptEntityInput(FindEntityByName("store_doors", -1), "Open");
}

public Action:CallTankerBoom(Handle:Timer)
{
	// ent_fire tanker_destroy_relay trigger
	UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "tanker_destroy_relay", "trigger");
}

public Action:C4M2BotsActions(Handle:Timer)
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (IsPlayerAlive(target) && GetClientTeam(target) == 2 && IsFakeClient(target)) // make sure target is a Survivor Bot
			{
				AutoCommand(target, "script", "CommandABot({cmd=1,pos=Vector(-1125.9,-10181.1,179.6),bot=GetPlayerFromUserID(%i)})", GetClientUserId(target));
			}
		}
	}
}

public Action:C5M4BotsActions(Handle:Timer)
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (IsPlayerAlive(target) && GetClientTeam(target) == 2 && IsFakeClient(target)) // make sure target is a Survivor Bot
			{
				AutoCommand(target, "script", "CommandABot({cmd=1,pos=Vector(-2179.3,389.3,302.0),bot=GetPlayerFromUserID(%i)})", GetClientUserId(target));
			}
		}
	}
}

public Action:C6M2BotsActions(Handle:Timer)
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (IsPlayerAlive(target) && GetClientTeam(target) == 2 && IsFakeClient(target)) // make sure target is a Survivor Bot
			{
				AutoCommand(target, "script", "CommandABot({cmd=1,pos=Vector(36.9,1888.7,-1.9),bot=GetPlayerFromUserID(%i)})", GetClientUserId(target));
			}
		}
	}
}

public Action:ResumeBotsActions(Handle:Timer)
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (IsPlayerAlive(target) && GetClientTeam(target) == 2 && IsFakeClient(target)) // make sure target is a Survivor Bot
			{
				AutoCommand(target, "script", "CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(target));
			}
		}
	}
}

public Action:RunBusStationEvent(Handle:Timer)
{
	AcceptEntityInput(FindEntityByName("finale_cleanse_entrance_door", -1), "Close");
	//PrintToChatAll("\x04[AutoTrigger] \x01Start c5m2 trigger1.");
	CreateTimer(5.0, RunBusStationEvent2);
}

public Action:RunBusStationEvent2(Handle:Timer)
{
	AcceptEntityInput(FindEntityByName("finale_cleanse_exit_door", -1), "Open");
	//PrintToChatAll("\x04[AutoTrigger] \x01Start c5m2 trigger1-1.");
}
/*
public Action:C2M3WarpAllBotToThere(Handle:Timer)
{
	// c2m3 - after shut off the rollercoaster, warp them to the special spot
	decl Float:posx[3];
	posx[0] = -4029.9;
	posx[1] = 1428.9;
	posx[2] = 222.0;
	// confusion spot -4029.9 1428.9 222.0, teleport them off
	// to: -4315.1 2311.4 313.2
	if (CheckforBots(posx, 300.0) && !WarpTrigger)
	{
		PrintToChatAll("\x04[AutoTrigger] \x01Bot found at a stuck spot, warping them all ahead in 50 seconds");
		
		new Handle:posdata = CreateDataPack();
		WritePackFloat(posdata, -4315.1);
		WritePackFloat(posdata, 2311.4);
		WritePackFloat(posdata, 313.2);
		CreateTimer(50.0, WarpAllBots, posdata);
		WarpTrigger = true;
	}
}
*/
public Action:C3M4FinaleStart(Handle:Timer)
{
	PrintToChatAll("\x04[AutoTrigger] \x01Start c3m4 finale trigger.");
	UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "escape_gate_triggerfinale", "Use");
}

public Action:C5M5FinaleStart(Handle:Timer)
{
	PrintToChatAll("\x04[AutoTrigger] \x01Start c5m5 finale trigger.");
	UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "finale", "Use");
}

public Action:C10M5FinaleStart(Handle:Timer)
{
	// c10m5 - finale start
	if (MapTrigger && !MapTriggerTwo)
	{
		PrintToChatAll("\x04[AutoTrigger] \x01Start c10m5 finale trigger.");
		UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "radio", "Use");
		MapTriggerTwo = true;
	}
}

public Action:C11M5FinaleStart(Handle:Timer)
{
	// c11m5 - finale start
	if (MapTrigger && !MapTriggerTwo)
	{
		PrintToChatAll("\x04[AutoTrigger] \x01Start c11m5 finale trigger.");
		UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "radio", "Use");
		MapTriggerTwo = true;
	}
}

public Action:GeneratorStart(Handle:Timer)
{
	// Crash Cause 02 - Generator Start
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "finaleswitch_initial", "Kill", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "finale_lever", "Enable", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "radio_game_event_pre", "Kill", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "radio_game_event", "GenerateGameEvent", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "sound_generator_start", "StopSound", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator_start_particles", "Start", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator_light_switchable", "TurnOn", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator_lights", "LightOn", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "sound_generator_run", "PlaySound", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "lift_switch_spark", "SparkOnce", "", "1");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "lift_lever", "SetDefaultAnimation", "IDLE_DOWN", "0.1");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "lift_lever", "SetAnimation", "DOWN", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "lift_spark02", "SparkOnce", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "lift_spark01", "SparkOnce", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "radio_game_event", "Kill", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "survivalmode_exempt", "Trigger", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator_break_timer", "Enable", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "finale_lever", "ForceFinaleStart", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator_hint", "EndHint", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "survival_start_relay", "Trigger", "", "0");
}

public Action:GeneratorStartTwoReady(Handle:Timer)
{
	// Crash Cause 02 - Generator Second Start
	PrintToChatAll("\x04[AutoTrigger] \x01Start c9m2 trigger1-1.");
	AcceptEntityInput(FindEntityByName("generator_switch", -1), "Press");
}

public Action:GeneratorStartTwo(Handle:Timer)
{
	// Crash Cause 02 - Generator Second Start
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator_switch", "Kill", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "finale_lever", "Enable", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "sound_generator_start", "StopSound", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator_start_particles", "Start", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator_light_switchable", "TurnOn", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator_lights", "LightOn", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "sound_generator_run", "PlaySound", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "lift_switch_spark", "SparkOnce", "", "1");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "lift_lever", "SetDefaultAnimation", "IDLE_DOWN", "0.1");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "lift_lever", "SetAnimation", "DOWN", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "lift_spark02", "SparkOnce", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "lift_spark01", "SparkOnce", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "survivalmode_exempt", "Trigger", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "finale_lever", "ForceFinaleStart", "", "5");
}

public Action:TankDoor01COOP(Handle:Timer)
{
	// The Sacrifice 01 - Tank Door - In
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tankdoorin_button", "UnLock", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "coop_tank", "Trigger", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tankdoorin", "Open", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tankdoorin_button", "Kill", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tank_sound_timer", "Disable", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "panic_event_relay", "Trigger", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "doorsound", "PlaySound", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tank_fog", "Enable", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tank_fog", "Disable", "", "5+0.5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "big_splash", "Stop", "", "5+2");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "big_splash", "Start", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "radio_game_event", "Kill", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tank_door_clip", "Kill", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "director", "EnableTankFrustration", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "battlefield_cleared", "UnblockNav", "", "5+60");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tank_car_camera_clip", "Kill", "", "5");
}

public Action:TankDoor01VERSUS(Handle:Timer)
{
	// The Sacrifice 01 - Tank Door - In
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tankdoorin_button", "UnLock", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "versus_tank", "Trigger", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tankdoorin", "Open", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tankdoorin_button", "Kill", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tank_sound_timer", "Disable", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "panic_event_relay", "Trigger", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "doorsound", "PlaySound", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tank_fog", "Enable", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tank_fog", "Disable", "", "5+0.5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "big_splash", "Stop", "", "5+2");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "big_splash", "Start", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "radio_game_event", "Kill", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tank_door_clip", "Kill", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "director", "EnableTankFrustration", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "battlefield_cleared", "UnblockNav", "", "5+60");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tank_car_camera_clip", "Kill", "", "5");
}

public Action:TankDoor02(Handle:Timer)
{
	// The Sacrifice 01 - Tank Door - Out
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tankdoorout_button", "UnLock", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tankdoorout", "Open", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "tankdoorout_button", "Kill", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "battlefield_cleared", "UnblockNav", "", "0");
}

public Action:C7M3GeneratorStart(Handle:Timer)
{
	// The Sacrifice 03 - Generator Start
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "finale_start_button", "Kill", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "sound_generator_start", "StopSound", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "sound_generator_run", "PlaySound", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator_start_particles", "Start", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator_model2", "StopGlowing", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "radio_game_event_pre", "Kill", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "mob_spawner_finale", "Enable", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator2_tankmessage_templated", "Kill", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "relay_advance_finale_state", "Trigger", "", "2");
	//UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "", "", "", "0");
}

public Action:C7M3GeneratorStart1(Handle:Timer)
{
	// The Sacrifice 03 - Generator1 Start
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "finale_start_button1", "Kill", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "sound_generator_start1", "StopSound", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "sound_generator_run1", "PlaySound", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator_start_particles1", "Start", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator_model1", "StopGlowing", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "mob_spawner_finale", "Enable", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "relay_advance_finale_state", "Trigger", "", "2");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "radio_game_event_pre1", "Kill", "", "0");
}

public Action:C7M3GeneratorStart2(Handle:Timer)
{
	// The Sacrifice 03 - Generator2 Start
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "finale_start_button2", "Kill", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "sound_generator_start2", "StopSound", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "sound_generator_run2", "PlaySound", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator_start_particles2", "Start", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator_model3", "StopGlowing", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "mob_spawner_finale", "Enable", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator3_tankmessage_templated", "Kill", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "relay_advance_finale_state", "Trigger", "", "2");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "radio_game_event_pre2", "Kill", "", "0");
}

public Action:C7M3WarpBotsToGenerator1(Handle:Timer)
{
	// The Sacrifice 03 - Warp Bots to Generator1
	// c7m3 - after they start the first generator, warp them to the special spot,
	// there has an another generator
	// teleport them off to -1224.8 814.7 222.0
	PrintToChatAll("\x04[AutoTrigger] \x01Start c7m3 trigger1-1.");
	new Handle:posdata = CreateDataPack();
	WritePackFloat(posdata, -1224.8);
	WritePackFloat(posdata, 814.7);
	WritePackFloat(posdata, 222.0);
	CreateTimer(10.0, WarpAllBots, posdata);
}

public Action:C7M3WarpBotsToGenerator2(Handle:Timer)
{
	// The Sacrifice 03 - Warp Bots to Generator2
	// c7m3 - after they start the second generator, warp them to the special spot,
	// there has the last generator
	// teleport them off to 1781.9 678.1 -33.9
	PrintToChatAll("\x04[AutoTrigger] \x01Start c7m3 trigger2-1.");
	new Handle:posdata = CreateDataPack();
	WritePackFloat(posdata, 1781.9);
	WritePackFloat(posdata, 678.1);
	WritePackFloat(posdata, -33.9);
	CreateTimer(10.0, WarpAllBots, posdata);
}

public Action:C7M3BridgeStartButton(Handle:Timer)
{
	// The Sacrifice 03 - C7M3 Bridge Start Button
	PrintToChatAll("\x04[AutoTrigger] \x01Start c7m3 trigger3.");
	UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "bridge_start_button", "Use");
}

public Action:C7M3GeneratorFinaleButtonStart(Handle:Timer)
{
	// The Sacrifice 03 - Generator final button start
	PrintToChatAll("\x04[AutoTrigger] \x01Start c7m3 finale trigger.");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "generator_final_button_relay", "Trigger", "", "0");
}

public Action:C13M2Trigger(Handle:Timer)
{
	//PrintToChatAll("\x04[AutoTrigger] \x01Start c13m2 trigger.");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_barrels", "StopGlowing", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_barrels", "Kill", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_button", "Kill", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_explosion", "Explode", "", "3");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_fire", "Start", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_fire", "Stop", "", "10");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_fire_sound", "PlaySound", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_fire_sound", "StopSound", "", "11");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_shake", "StartShake", "", "2");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_shake", "StopShake", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_murette", "Break", "", "3");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_impact", "Explode", "", "3");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_explosion_sound", "PlaySound", "", "3");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "barrier", "EnableMotion", "", "2.5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_smoke", "Start", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_smoke", "Stop", "", "10");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_dummy", "Kill", "", "0");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "director", "BeginScript", "event_alarme", "3.2");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_new_particle", "Start", "", "3");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_new_particle1", "Start", "", "3.2");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_new_particle1", "Stop", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_new_particle", "Stop", "", "5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "ceda_truck_alarm", "PlaySound", "", "3.5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_nav_blocker", "UnblockNav", "", "3");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "scene_relay", "Trigger", "", "4.5");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_barrels_hurt_trigger", "Enable", "", "3");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "bridge_barrels_hurt_trigger", "Disable", "", "10");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "barrier", "DisableMotion", "", "8");
	UnflagAndExecuteCommandTwo(TriggeringBot, "ent_fire", "template_onslaught_hint", "ForceSpawn", "", "4");
}

public Action:FinaleStart(Handle:Timer)
{
	if (FinaleHasStarted) return Plugin_Continue;
	
	if (!TriggeringBot) TriggeringBot = GetAnyValidClient();
	else if (!IsClientInGame(TriggeringBot)) TriggeringBot = GetAnyValidClient();
	
	if (!TriggeringBot) return Plugin_Continue;
	UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "trigger_finale", "");
	PrintToChatAll("\x04[AutoTrigger] \x01Start finale trigger.");
	return Plugin_Continue;
}

// this bool return true if a Bot was found in a radius around the given position, and sets TriggeringBot to it.
bool:CheckforBots(Float:position[3], Float:distancesetting)
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (GetClientHealth(target)>1 && GetClientTeam(target) == 2 && IsFakeClient(target)) // make sure target is a Survivor Bot
			{
				if (IsPlayerIncapped(target)) // incapped doesnt count
					return false;
				
				decl Float:targetPos[3];
				GetClientAbsOrigin(target, targetPos);
				new Float:distance = GetVectorDistance(targetPos, position); // check Survivor Bot Distance from checking point
				
				if (distance < distancesetting)
				{
					TriggeringBot = target;
					return true;
				}
				else
				{
					continue;
				}
			}
		}
	}
	return false;
}

stock FindEntityByName(String:name[], any:startcount)
{
	decl String:classname[128];
	new maxentities = GetMaxEntities();
	
	for (new i = startcount; i <= maxentities; i++)
	{
		if (!IsValidEntity(i)) continue; // exclude invalid entities.
		
		GetEdictClassname(i, classname, 128);
		
		if (FindDataMapOffs(i, "m_iName") == -1) continue;
		
		decl String:iname[128];
		GetEntPropString(i, Prop_Data, "m_iName", iname, sizeof(iname));
		if (strcmp(name,iname,false) == 0) return i;
	}
	return -1;
}

stock UnflagAndExecuteCommand(client, String:command[], String:parameter1[]="", String:parameter2[]="")
{
	if (!client || !IsClientInGame(client)) client = GetAnyValidClient();
	if (!client || !IsClientInGame(client)) return;
	
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, parameter1, parameter2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

stock UnflagAndExecuteCommandTwo(client, String:command[], String:parameter1[]="", String:parameter2[]="", String:parameter3[]="", String:parameter4[]="")
{
	if (!client || !IsClientInGame(client)) client = GetAnyValidClient();
	if (!client || !IsClientInGame(client)) return;
	
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s %s %s", command, parameter1, parameter2, parameter3, parameter4);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

//entity abs origin code from here
//http://forums.alliedmods.net/showpost.php?s=e5dce96f11b8e938274902a8ad8e75e9&p=885168&postcount=3
stock GetEntityAbsOrigin(entity,Float:origin[3])
{
	if (entity > 0 && IsValidEntity(entity))
	{
		decl Float:mins[3], Float:maxs[3];
		GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
		GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
		GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
		
		origin[0] += (mins[0] + maxs[0]) * 0.5;
		origin[1] += (mins[1] + maxs[1]) * 0.5;
		origin[2] += (mins[2] + maxs[2]) * 0.5;
	}
}

stock bool:IsVersus()
{
	decl String:gamemode[56];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	if (StrContains(gamemode, "versus", false) > -1)
		return true;
	return false;
}

stock bool:IsCoop()
{
	decl String:gamemode[56];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	if (StrContains(gamemode, "coop", false) > -1)
		return true;
	return false;
}

stock bool:AllBotTeam()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientHealth(client)>=1 && GetClientTeam(client) == 2)
		{
			if (!IsFakeClient(client)) return false;
		}
	}
	return true;
}

stock bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated"))
		return true;
	return false;
}

stock GetAnyValidClient()
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target)) return target;
	}
	return -1;
}

stock AutoCommand(client, const String:command[], const String:arguments[], any:...)
{
	new String:vscript[PLATFORM_MAX_PATH];
	VFormat(vscript, sizeof(vscript), arguments, 4);	

	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags ^ FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, vscript);
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}
