

#define PLAYERS 32

#pragma semicolon 1
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <sdktools>
#include <adminmenu>
#define PLUGIN_VERSION "1.274"
#define CVAR_FLAGS FCVAR_PLUGIN
#define SURVIVORTEAM 2

public Plugin:myinfo = 
{
    name = "[L4D] Points and Gift System",
    author = "(-DR-)GrammerNatzi",
    description = "This plug-in allows clients to gain points through various accomplishments and use them to buy items and health/ammo refills. It also allows admins to gift the same things to players and grant them god mode. Both use menus, no less.",
    version = PLUGIN_VERSION,
    url = ""
}

/*Some Important Variables*/
new currenttarget;
new godon[21];
new points[21];
new pointskillcount[21];
new pointsteam[21];
new numtanks;
new numwitches;
new tankonfire[27];
new istank[27];
new buyitem[25];
new canspawn;
new burntimeleft[26];
new sburntimeleft[26];
new hasincendiary[26];
new hassuperburn[26];
new pointsremindtimer;
new pointsremindnumtimer;
new pointstimer;
new bool:pointson;

/*Convar Variables*/
new Handle:pointsoncvar;
new Handle:pointsinfected;
new Handle:pointsspecial;
new Handle:pointsheal;
new Handle:pointsrevive;
new Handle:pointsrescue;
new Handle:pointsonversus;
new Handle:pointsadvertising;
new Handle:pointsnumreminder;
new Handle:pointswitchinsta;
new Handle:pointswitch;
new Handle:pointstankburn;
new Handle:pointstankkill;
new Handle:pointshurt;
//new pointsvson;
new Handle:pointsminigun;
new Handle:pointsheadshot;
new Handle:pointsinfectednum;
new Handle:pointsgrab;
new Handle:pointspounce;
new Handle:pointsincapacitate;
new Handle:pointsboom;
new Handle:pointsvomit;
new Handle:pointshurtcount[20];
new Handle:pointsadvertisingticks;
new Handle:pointsremindticks;
new Handle:pointsreset;
new Handle:pointsresetround;
new Handle:ticksprevious;

/*Item-Related Convars*/
new Handle:tanklimit;
new Handle:witchlimit;
new Handle:pointsburntime;
new Handle:pointssuperburntime;

/*Price Convars*/
new Handle:shotpoints;
new Handle:smgpoints;
new Handle:riflepoints;
new Handle:autopoints;
new Handle:huntingpoints;
new Handle:pipepoints;
new Handle:molopoints;
new Handle:pillspoints;
new Handle:medpoints;
new Handle:pistolpoints;
new Handle:refillpoints;
new Handle:healpoints;


/*Infected Price Convars*/
new Handle:suicidepoints;
new Handle:ihealpoints;
new Handle:boomerpoints;
new Handle:hunterpoints;
new Handle:smokerpoints;
new Handle:tankpoints;
new Handle:wwitchpoints;
new Handle:panicpoints;
new Handle:mobpoints;


/*Special Price Convars*/
new Handle:burnpoints;
new Handle:superburnpoints;


public OnPluginStart()
{
    
	/*Commands*/
	RegAdminCmd("refill", Refill, ADMFLAG_KICK);
	RegAdminCmd("heal", Heal, ADMFLAG_KICK);
	RegConsoleCmd("debugteamid",TeamID);
	RegConsoleCmd("$", ShowPoints);
	RegConsoleCmd("#",RepeatBuy);
	RegAdminCmd("fakegod",FakeGod, ADMFLAG_KICK);
	RegConsoleCmd("itempointshelp", PointsHelp);
	RegConsoleCmd("b", PointsChooseMenu);
	RegConsoleCmd("bs", PointsSpecialMenu);
	RegConsoleCmd("b1", PointsMenu);
	RegConsoleCmd("b2", PointsMenu2);
	RegConsoleCmd("b3", PointsMenu3);
	RegConsoleCmd("pointsconfirm", PointsConfirm);
	RegAdminCmd("sm_clientsetpoints",Command_SetPoints,ADMFLAG_KICK,"sm_clientsetpoints <#userid|name> [number of points]");
	RegAdminCmd("sm_clientgive", Command_ClientCmd, ADMFLAG_KICK, "sm_clientgive <#userid|name> [item number] Numbers: 0 - Shotgun, 1 - SMG, 2 - Rifle, 3 - Hunting Rifle, 4 - Auto-shotty, 5 - Pipe Bomb, 6 - Molotov, 7 - Pistol, 8 - Pills, 9 - Medkit, 10 - Ammo, 11 - Health");
    RegAdminCmd("sm_clientgivemenu", GiveItemMenu, ADMFLAG_KICK, "Blah");
	RegAdminCmd("sm_clientgivepoints",Command_GivePoints,ADMFLAG_KICK,"sm_clientgivepoints <#userid|name> [number of points]");
	//this signals that the plugin is on on this server
    CreateConVar("points_gift_on", PLUGIN_VERSION, "Points_Gift_On", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	/* Values for Convars*/
	pointsoncvar = CreateConVar("points_on","1","Point system on or off?",CVAR_FLAGS, true, 0.0);
	pointsinfected = CreateConVar("points_amount_infected","2","How many points for killing a certain number of infected.",CVAR_FLAGS, true, 0.0);
	pointsspecial = CreateConVar("points_amount_specialinfected","1","How many points for killing a special infected.",CVAR_FLAGS, true, 0.0);
	pointsheal = CreateConVar("points_amount_heal","5","How many points for healing someone.",CVAR_FLAGS, true, 0.0);
	pointsrevive = CreateConVar("points_amount_revive","3","How many points for reviving someone.",CVAR_FLAGS, true, 0.0);
	pointsrescue = CreateConVar("points_amount_rescue","2","How many points for rescuing someone from a closet.",CVAR_FLAGS, true, 0.0);
	//pointsonversus = CreateConVar("points_on_versus","0","Point system on or off in versus mode? (DOES NOT WORK YET)",CVAR_FLAGS, true, 0.0);
	pointsadvertising = CreateConVar("points_advertising","0","Do we want the plugin to advertise itself? 1 for short version, 2 for long, 0 for none.",CVAR_FLAGS, true, 0.0);
	pointsnumreminder = CreateConVar("points_advertising_remind","0","Reminds the players how to get their number keys to properly work. 1 for yes, 0 for no.",CVAR_FLAGS,true,0.0);
	pointswitch = CreateConVar("points_amount_witch","5","How many points you get for killing a witch.",CVAR_FLAGS,true,0.0);
	pointswitchinsta = CreateConVar("points_amount_witch_instakill","3","How many extra points you get for killing a witch in one shot.",CVAR_FLAGS,true,0.0);
	pointstankburn = CreateConVar("points_amount_tank_burn","2","How many points you get for burning a tank.",CVAR_FLAGS,true,0.0);
	pointstankkill = CreateConVar("points_amount_tank","2","How many additional points you get for killing a tank.",CVAR_FLAGS,true,0.0);
	pointshurt = CreateConVar("points_amount_infected_hurt","2","How many points infected get for hurting survivors a number of times.",CVAR_FLAGS,true,0.0);
	pointsinfectednum = CreateConVar("points_amount_infectednum","25","How many killed infected does it take to earn points? Headshot and minigun kills can be used to rank up extra kills.",CVAR_FLAGS,true,0.0);
	pointsheadshot = CreateConVar("points_amount_extra_headshotkills","1","How many extra kills are survivors awarded for scoring headshots? 0 = None.",CVAR_FLAGS,true, 0.0);
	pointsminigun = CreateConVar("points_amount_extra_minigunkills","1","How many extra kills are survivors awarded for scoring minigun kills? 0 = None.",CVAR_FLAGS,true, 0.0);
	pointsincapacitate = CreateConVar("points_amount_infected_incapacitation","5","How many points you get for incapacitating a survivor",CVAR_FLAGS,true,0.0);
	//pointsvson = CreateConVar("points_on_infected","1","Do infected in versus get points or not?",CVAR_FLAGS,true,0.0);
	pointsgrab = CreateConVar("points_amount_infected_pull","1","How many points you get [as a smoker] when you pull a survivor.",CVAR_FLAGS,true,0.0);
	pointspounce = CreateConVar("points_amount_infected_pounce","1","How many points you get [as a hunter] when you pounce a survivor.",CVAR_FLAGS,true,0.0);
	pointsvomit = CreateConVar("points_amount_infected_vomit","1","How many points you get [as a boomer] when you vomit/explode on a survivor.",CVAR_FLAGS,true,0.0);
	pointsadvertisingticks = CreateConVar("points_advertising_ticks","80","How many seconds before the optional advertisement is displayed again.",CVAR_FLAGS,true,0.0);
	pointsremindticks = CreateConVar("points_advertising_remind_ticks","60","How many seconds before the optional gamepad reminder is displayed again.",CVAR_FLAGS,true,0.0);
	//pointsreset = CreateConVar("points_reset","0","Reset points on map load?",CVAR_FLAGS, true, 0.0);
	pointsresetround = CreateConVar("points_reset_round","0","Reset points on round change? (Recommended to make a cfg to turn on in coop and turn off in versus).",CVAR_FLAGS, true, 0.0);
	
	/*Price Convars*/
	shotpoints = CreateConVar("points_price_shotgun","5","How many points a shotgun costs.",CVAR_FLAGS, true, -1.0);
	smgpoints = CreateConVar("points_price_smg","5","How many points a sub-machine gun costs.",CVAR_FLAGS, true, -1.0);
	riflepoints = CreateConVar("points_price_rifle","10","How many points a rifle costs.",CVAR_FLAGS, true, -1.0);
	huntingpoints = CreateConVar("points_price_huntingrifle","15","How many points a hunting rifle costs.",CVAR_FLAGS, true, -1.0);
	autopoints = CreateConVar("points_price_autoshotgun","15","How many points an auto-shotgun costs.",CVAR_FLAGS, true, -1.0);
	pipepoints = CreateConVar("points_price_pipebomb","3","How many points a pipe-bomb costs.",CVAR_FLAGS, true, -1.0);
	molopoints = CreateConVar("points_price_molotov","4","How many points a molotov costs.",CVAR_FLAGS, true, -1.0);
	pistolpoints = CreateConVar("points_price_pistol","5","How many points an extra pistol costs.",CVAR_FLAGS, true, -1.0);
	pillspoints = CreateConVar("points_price_painpills","5","How many points a bottle of pills costs.",CVAR_FLAGS, true, -1.0);
	medpoints = CreateConVar("points_price_medkit","10","How many points a medkit costs.",CVAR_FLAGS, true, -1.0);
	refillpoints = CreateConVar("points_price_refill","5","How many points an ammo refill costs.",CVAR_FLAGS, true, -1.0);
	healpoints = CreateConVar("points_price_heal","10","How many points a heal costs.",CVAR_FLAGS, true, -1.0);
	
	/*Infected Price Convars*/
	suicidepoints = CreateConVar("points_price_infected_suicide","4","How many points it takes to end it all.",CVAR_FLAGS, true, -1.0);
	ihealpoints = CreateConVar("points_price_infected_heal","5","How many points a heal costs (for infected).",CVAR_FLAGS, true, -1.0);
	boomerpoints = CreateConVar("points_price_infected_boomer","10","How many points a boomer costs.",CVAR_FLAGS, true, -1.0);
	hunterpoints = CreateConVar("points_price_infected_hunter","5","How many points a hunter costs.",CVAR_FLAGS, true, -1.0);
	smokerpoints = CreateConVar("points_price_infected_smoker","7","How many points a smoker costs.",CVAR_FLAGS, true, -1.0);
	tankpoints = CreateConVar("points_price_infected_tank","35","How many points a tank costs.",CVAR_FLAGS, true, -1.0);
	wwitchpoints = CreateConVar("points_price_infected_witch","25","How many points a witch costs.",CVAR_FLAGS, true, -1.0);
	mobpoints = CreateConVar("points_price_infected_mob","18","How many points a mini-event/mob costs.",CVAR_FLAGS, true, -1.0);
	panicpoints = CreateConVar("points_price_infected_mob_mega","23","How many points a mega mob costs.",CVAR_FLAGS, true, -1.0);
	
	/*Special Price Convars*/
	burnpoints = CreateConVar("points_price_special_burn","10","How many points does incendiary ammo cost?",CVAR_FLAGS,true,-1.0);
	superburnpoints = CreateConVar("points_price_special_burn_super","20","How many points does super incendiary ammo (burn special infected) cost?",CVAR_FLAGS,true,-1.0);
	
	/*Item-Related Convars*/
	tanklimit = CreateConVar("points_limit_tanks","1","How many tanks can be spawned in a round.",CVAR_FLAGS,true,0.0);
	witchlimit = CreateConVar("points_limit_witches","2","How many witches can be spawned in a round.",CVAR_FLAGS,true,0.0);
	pointsburntime = CreateConVar("points_special_burn_time","30","How many seconds does a survivor get incendiary ammo for in seconds?",CVAR_FLAGS,true,0.0);
	pointssuperburntime = CreateConVar("points_special_burn_super_time","30","How many seconds does a survivor get super incendiary ammo for in seconds?",CVAR_FLAGS,true,0.0);
	
	/*Bug Prevention*/
	pointsremindtimer = 1;
	pointsremindnumtimer = 1;
	
	
	/*Event Hooks*/
	HookEvent("player_death", InfectedKill);
	HookEvent("round_end", RoundEnd, EventHookMode_Pre);
	//HookEvent("game_newmap", MapLoad);
	//HookEvent("rescue_door_open", RescuePoints);
	HookEvent("heal_success", HealPoints);
	//HookEvent("entity_shoved", MeleeShove);
	HookEvent("revive_success", RevivePoints);
	HookEvent("infected_death", KillPoints);
	HookEvent("infected_hurt", IncendiaryBurn);
	HookEvent("player_team", ResetPoints);
	HookEvent("witch_killed", WitchPoints);
	HookEvent("zombie_ignited", TankBurnPoints);
	HookEvent("tank_killed", TankKill);
	HookEvent("player_hurt",HurtPoints);
	HookEvent("player_incapacitated",IncapacitatePoints);
	HookEvent("tongue_grab",GrabPoints);
	HookEvent("lunge_pounce",PouncePoints);
	HookEvent("player_now_it",VomitPoints);
	//HookEvent("tank_spawn",TankCheck);
	//CreateTimer(80.0, PointsReminder, _, TIMER_REPEAT);
	//CreateTimer(60.0,PointsNumReminder, _,TIMER_REPEAT);
	CreateTimer(1.0,TimerUpdate, _, TIMER_REPEAT);

	/* Config Creation*/
	AutoExecConfig(true,"L4DPoints");
	
	return Plugin_Handled;
}

/*public Action:PointsReminder(Handle:timer)
{
	new advertising = GetConVarInt(pointsadvertising);
	if(pointson)
	{
		if(advertising == 2)
		{
			PrintToChatAll("\x04[$]\x03 You can get item points in this server to buy items. Type !usepoints to use them.");
		}
		else if(advertising == 1)
		{
			PrintToChatAll("\x04[$]\x03 Type !usepoints to use your item points.");
		}
	}
}

public Action:PointsNumReminder(Handle:timer)
{
	new advertising = GetConVarInt(pointsnumreminder);
	if(pointson)
	{
		if(advertising >= 1)
		{
			PrintToChatAll("\x04[$]\x03 If you are having trouble pressing numbers 6, 7, 8, 9, and 0 in the points menu, try enabling and disabling gamepad.");
		}
	}
}*/

public Action:IncendiaryBurn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetEventInt(event, "entityid");
	if (hasincendiary[client] == 1 || hassuperburn[client] == 1)
	{
		decl String:class[20];
		GetEntityNetClass(target, class, 20);
		new compare;
		compare = strcmp(class, "Witch");
		if(compare == 0)
		{
			return Plugin_Continue;
		}
		else
		{
			IgniteEntity(target,999.0,false);
		}
	}
}

/*public Action:MeleeShove(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetEventInt(event, "userid");
	if (hasmelee[client] == 1)
	{
		decl String:class[20];
		GetEntityNetClass(target, class, 20);
		new compare;
		compare = strcmp(class, "Witch");
		if(compare == 0)
		{
			return Plugin_Continue;
		}
		else
		{
			SetEntityHealth(GetClienttarget,0);
		}
	}
}*/

public Action:TimerUpdate(Handle:timer)
{
	new advertising;
	pointson = GetConVarBool(pointsoncvar);
	pointstimer += 1;
	if(pointson)
	{
		if (pointstimer >= GetConVarInt(pointsadvertisingticks) * pointsremindtimer)
		{
			advertising = GetConVarInt(pointsadvertising);
			pointsremindtimer += 1;
			if(advertising == 2)
			{
				PrintToChatAll("\x04[$]\x03 You can get item points in this server to buy things. Type !usepoints to use them.");
			}
			else if(advertising == 1)
			{
				PrintToChatAll("\x04[$]\x03 Type !usepoints to use your item points.");
			}
		}
		if (pointstimer >= GetConVarInt(pointsremindticks) * pointsremindnumtimer)
		{
			advertising = GetConVarInt(pointsnumreminder);
			pointsremindnumtimer += 1;
			if(advertising >= 1)
			{
				PrintToChatAll("\x04[$]\x03 If you are having trouble pressing numbers 6, 7, 8, 9, and 0 in the points menu, try enabling and disabling gamepad.");
			}
		}
		for (new i;i <= 25;i++)
		{
			if (hasincendiary[i] >= 1)
			{
				if(burntimeleft[i] < 0)
				{
					hasincendiary[i] = 0;
					if(burntimeleft[i] == -1)
					{
						PrintHintText(i,"\x04[$]\x03 所有普通燃燒彈已耗盡!");
					}
				}
				else
				{
					PrintHintText(i,"\x04[$]\x03 你有 %d 秒使用普通燃燒彈的時限.",burntimeleft[i]);
					burntimeleft[i] -= 1;
				}
			}
			if (hassuperburn[i] >= 1)
			{
				if(sburntimeleft[i] < 0)
				{
					hassuperburn[i] = 0;
					if(sburntimeleft[i] == -1)
					{
						PrintHintText(i,"\x04[$]\x03 所有特殊燃燒彈已耗盡!");
					}
				}
				else
				{
					PrintHintText(i,"你有 %d 秒使用特殊燃燒彈的時限.",sburntimeleft[i]);
					sburntimeleft[i] -= 1;
				}
			}
		}
	}
}

public Action:PointsHelp(client,args)
{
	if(pointson)
	{
		PrintToChat(client, "\x04[$]\x03 Item points can be earned by performing acts of teamwork. Type !usepoints to spend them, and !points to find out how many you have.");
	}
}

public Action:ShowPoints(client,args)
{
	if(pointson)
	{
		ShowPointsFunc(client);
	}
	return Plugin_Handled;
}

public Action:TeamID(client,args)
{
	if(pointson)
	{
		TeamIDFunc(client);
	}
	return Plugin_Handled;
}

public Action:TeamIDFunc(client)
{
	PrintToChat(client, "\x04[$]\x03 You are on team %d.",pointsteam[client]);
	
	return Plugin_Handled;
}

public Action:ShowPointsFunc(client)
{
	PrintToChat(client, "\x04[$]\x03 你現在持有 $%d.",points[client]);
	
	return Plugin_Handled;
}

/*public Action:TankCheck(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	istank[client] = 1;
}*/

public Action:InfectedKill(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker > 0 && attacker < PLAYERS)
	{
		if (client > 0 && client < 20)
		{
			if(pointson)
			{
				points[attacker] += GetConVarInt(pointsspecial);
				PrintToChat(attacker, "\x04[$]\x03 殺死特殊感染者令你賺到$%d, 現有$%d.",GetConVarInt(pointsspecial),points[attacker]);
			}
		}
	}
	
}

public Action:RoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	numtanks = 0;
	numwitches = 0;
	if (GetConVarBool(pointsresetround))
	{
		for (new i;i <= 20;i++)
		{
			points[i] = 0;
		}
	}
}

/*public Action:MapLoad(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (GetConVarBool(pointsreset))
	{
		for (new i;i < 20;i++)
		{
			points[i] = 0;
		}
	}
}*/

public Action:IncapacitatePoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker > 0 && attacker < PLAYERS)
	{
		if (pointsteam[attacker] != SURVIVORTEAM)
		{
			if (client > 0 && client < 20)
			{
				if(pointson)
				{
					PrintToChat(attacker, "\x04[$]\x03 Incapacitated Survivor: %d Point(s)",GetConVarInt(pointsincapacitate));
					points[attacker] += GetConVarInt(pointsincapacitate);
				}
			}
		}
	}
}

public Action:GrabPoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && client < PLAYERS)
	{
		if (pointsteam[client] != SURVIVORTEAM)
		{
			if(pointson)
			{
				PrintToChat(client, "\x04[$]\x03 Pulled Survivor: %d Point(s)",GetConVarInt(pointsgrab));
				points[client] += GetConVarInt(pointsgrab);
			}
		}
	}
	
}

public Action:PouncePoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && client < PLAYERS)
	{
		if (pointsteam[client] != SURVIVORTEAM)
		{
			if(pointson)
			{
				PrintToChat(client, "\x04[$]\x03 Pounced Survivor: %d Point(s)",GetConVarInt(pointspounce));
				points[client] += GetConVarInt(pointspounce);
			}
		}
	}
	
}

public Action:VomitPoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (client > 0 && client < PLAYERS)
	{
		if (pointsteam[client] != SURVIVORTEAM)
		{
			if(pointson)
			{
				PrintToChat(client, "\x04[$]\x03 'Tagged' Survivor: %d Point(s)",GetConVarInt(pointsvomit));
				points[client] += GetConVarInt(pointsvomit);
			}
		}
	}
	
}

public Action:HurtPoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker > 0 && attacker < PLAYERS)
	{
		if (attacker > 0 && attacker < 20)
		{
			if (pointsteam[attacker] != SURVIVORTEAM)
			{
				if (pointsteam[client] == SURVIVORTEAM)
				{
					if(pointson)
					{
						pointshurtcount[attacker] += 1;
						if(pointshurtcount[attacker] >= 5)
						{
							PrintToChat(attacker, "\x04[$]\x03 Hurt Survivors Five Times: %d Point(s)",GetConVarInt(pointshurt));
							points[attacker] += GetConVarInt(pointshurt);
							pointshurtcount[attacker] -= 5;
						}
					}
				}
			}
			else if (pointsteam[client] == 3)
			{
				if(hassuperburn[attacker] == 1)
				{
					IgniteEntity(client,999.0,false);
				}
			}
		}
	}
	
}

public Action:TankKill(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker > 0 && attacker < PLAYERS)
	{
		if(pointson)
		{
			points[attacker] += GetConVarInt(pointstankkill);
			PrintToChat(attacker, "\x04[$]\x03 殺死Tank令你賺到$%d, 現有$%d.",GetConVarInt(pointstankkill),points[attacker]);
			for (new i = 0;i <= 27;i++)
			{
				tankonfire[i] = 0;
			}
		}
	}
	
}

public Action:WitchPoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new instakill = GetEventBool(event, "oneshot");
	if (client > 0 && client < 20)
	{
		if(pointson)
		{
			points[client] += GetConVarInt(pointswitch);
			PrintToChat(client, "\x04[$]\x03 殺死Witch令你賺到$%d, 現有$%d.",GetConVarInt(pointswitch),points[client]);
			if (instakill)
			{
				points[client] += GetConVarInt(pointswitchinsta);
				PrintToChat(client, "\x04[$]\x03 另外你秒殺Witch更可額外得到$%d, 現有$%d.",GetConVarInt(pointswitchinsta),points[client]);
			}
		}
	}
}

public Action:TankBurnPoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	decl String:victim[64];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "victimname", victim, sizeof(victim));
	new target = GetEventInt(event,"clientid");
	if (client > 0 && client < 20)
	{
		if (StrEqual(victim,"Tank",false))
		{
			if(tankonfire[client] != 1)
			{
				if(pointson)
				{
					points[client] += GetConVarInt(pointstankburn);	
					PrintToChat(client, "\x04[$]\x03 燒著Tank令你賺到$%d, 現有$%d.",GetConVarInt(pointstankburn),points[client]);
					tankonfire[client] = 1;
				}
			}
		}
	}
}

/*public Action:RescuePoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && client < PLAYERS)
	{
		if(pointson)
		{
			points[client] += pointsrescue;
			PrintToChat(client, "\x04[$]\x03 You saved [a] member(s) of your team. You have earned five points.");
		}
	}
}*/

public Action:ResetPoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new disconnect = GetEventBool(event, "disconnect");
	new teamid = GetEventInt(event,"team");
	if (disconnect)
	{
		points[client] = 0;
	}
	pointsteam[client] = teamid;
}

public Action:HealPoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new target = GetClientOfUserId(GetEventInt(event, "subject"));
	if (client > 0 && client < PLAYERS)
	{
		if (client != target)
		{
			if(pointson)
			{
				if(pointson)
				{
					points[client] += GetConVarInt(pointsheal);
					PrintToChat(client, "\x04[$]\x03 醫治你的朋友令你賺到$%d, 現有$%d.", GetConVarInt(pointsheal),points[client]);
				}
			}
		}
	}
}

public Action:KillPoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new headshot = GetEventBool(event, "headshot");
	new minigun = GetEventBool(event, "minigun");
	if (client > 0 && client < PLAYERS)
	{
		if (client > 0 && client < PLAYERS)
		{
			pointskillcount[client] += 1;
			if (headshot)
			{
				pointskillcount[client] += GetConVarInt(pointsheadshot);
			}
			if (minigun)
			{
				pointskillcount[client] += GetConVarInt(pointsminigun);
			}
			if (pointskillcount[client] >= GetConVarInt(pointsinfectednum))
			{
				if(pointson)
				{
					points[client] += GetConVarInt(pointsinfected);
					PrintToChat(client, "\x04[$]\x03 你純熟嘅殺屍技巧令你賺到$%d, 現有$%d.",GetConVarInt(pointsinfected),points[client]);
				}
				pointskillcount[client] -= GetConVarInt(pointsinfectednum);
			}
		}
	}
}

public Action:RevivePoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new target = GetClientOfUserId(GetEventInt(event, "subject"));
	if (client > 0 && client < PLAYERS)
	{
		if (client != target)
		{
			if(pointson)
			{
				points[client] += GetConVarInt(pointsrevive);
				PrintToChat(client, "\x04[$]\x03 救活你的朋友令你賺到$%d, 現有$%d.",GetConVarInt(pointsrevive),points[client]);
			}
		}
	}
}

public Action:Command_GivePoints(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04[$]\x03 Usage: sm_clientgivepoints <#userid|name> [number of points]");
		return Plugin_Handled;
	}

	decl String:arg[MAX_NAME_LENGTH], String:arg2[4];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	new targetclient;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			points[targetclient] += StringToInt(arg2);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_SetPoints(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04[$]\x03 Usage: sm_clientsetpoints <#userid|name> [number of points]");
		return Plugin_Handled;
	}

	decl String:arg[MAX_NAME_LENGTH], String:arg2[4];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	new targetclient;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			points[targetclient] = StringToInt(arg2);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_ClientCmd(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04[$]\x03 Usage: sm_clientgive <#userid|name> [item number] Numbers: 0 - Shotgun, 1 - SMG, 2 - Rifle, 3 - Hunting Rifle, 4 - Auto-shotty, 5 - Pipe Bomb, 6 - Molotov, 7 - Pistol, 8 - Pills, 9 - Medkit, 10 - Ammo, 11 - Health");
		return Plugin_Handled;
	}

	decl String:arg[MAX_NAME_LENGTH], String:arg2[4];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	new flags4;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			flags4 = GetCommandFlags("give");
			SetCommandFlags("give", flags4 & ~FCVAR_CHEAT);
			switch (StringToInt(arg2))
			{
				case 0: //shotgun
				{
					//Give the player a shotgun
					FakeClientCommand(target_list[i], "give pumpshotgun");
				}
				case 1: //smg
				{
					//Give the player an smg
					FakeClientCommand(target_list[i], "give smg");
				}
				case 2: //rifle
				{
					//Give the player a rifle
					FakeClientCommand(target_list[i], "give rifle");
				}
				case 3: //hunting rifle
				{
					//Give the player a hunting rifle
					FakeClientCommand(target_list[i], "give hunting_rifle");
				}
				case 4: //auto shotgun
				{
					//Give the player a autoshotgun
					FakeClientCommand(target_list[i], "give autoshotgun");
				}
				case 5: //pipe_bomb
				{
					//Give the player a pipe_bomb
					FakeClientCommand(target_list[i], "give pipe_bomb");
				}
				case 6: //hunting molotov
				{
					//Give the player a molotov
					FakeClientCommand(target_list[i], "give molotov");
				}
				case 7: //pistol
				{
					//Give the player a pistol
					FakeClientCommand(target_list[i], "give pistol");
				}
				case 8: //pills
				{
					//Give the player pain pills
					FakeClientCommand(target_list[i], "give pain_pills");
				}
				case 9: //medkit
				{
					//Give the player a first aid kit
					FakeClientCommand(target_list[i], "give first_aid_kit");
				}
				case 10: //refill
				{
					//Refill ammo
					FakeClientCommand(target_list[i], "give ammo");
				}
				case 11: //heal
				{
					//Heal player
					FakeClientCommand(target_list[i], "give health");
				}	
			}
			SetCommandFlags("give", flags4|FCVAR_CHEAT);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

DisplayGiveItemMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_GiveItem);
	
	decl String:title[100];
	Format(title, sizeof(title), "Item Choose Page", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddMenuItem(menu, "0", "Shotgun");
    AddMenuItem(menu, "1", "SMG");
    AddMenuItem(menu, "2", "Rifle");
    AddMenuItem(menu, "3", "Hunting Rifle");
    AddMenuItem(menu, "4", "Auto Shotgun");
    AddMenuItem(menu, "5", "Pipe Bomb");
	AddMenuItem(menu, "6", "Next Page");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_GiveItem(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		
		new flags6 = GetCommandFlags("give");
		SetCommandFlags("give", flags6 & ~FCVAR_CHEAT);
		switch (param2)
        {
            case 0: //shotgun
            {
                //Give the player a shotgun
                FakeClientCommand(currenttarget, "give pumpshotgun");
				DisplayGiveItemMenu(param1);
            }
            case 1: //smg
            {
                //Give the player a smg
                FakeClientCommand(currenttarget, "give smg");
				DisplayGiveItemMenu(param1);
            }
            case 2: //rifle
            {
                //Give the player a rifle
                FakeClientCommand(currenttarget, "give rifle");
				DisplayGiveItemMenu(param1);
            }
			case 3: //hunting rifle
            {
                //Give the player a hunting rifle
                FakeClientCommand(currenttarget, "give hunting_rifle");
				DisplayGiveItemMenu(param1);
            }
			case 4: //auto shotgun
            {
                //Give the player a autoshotgun
                FakeClientCommand(currenttarget, "give autoshotgun");
				DisplayGiveItemMenu(param1);
            }
			case 5: //pipe_bomb
            {
                //Give the player a pipe_bomb
                FakeClientCommand(currenttarget, "give pipe_bomb");
				DisplayGiveItemMenu(param1);
            }
			case 6: //Next Page
			{
				//Go to next page.
				DisplayGiveItemMenu2(param1);
			}
        }
		SetCommandFlags("give", flags6|FCVAR_CHEAT);
	}
	else if (action == MenuAction_Cancel)
	{
		DisplayGiveTargetMenu(param1);
	}
}

DisplayGiveItemMenu2(client)
{
	new Handle:menu = CreateMenu(MenuHandler_GiveItem2);
	
	decl String:title[100];
	Format(title, sizeof(title), "Item Choose Page 2", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddMenuItem(menu, "0", "Molotov");
    AddMenuItem(menu, "1", "Extra Pistol");
    AddMenuItem(menu, "2", "Pain Pills");
    AddMenuItem(menu, "3", "Medkit");
    AddMenuItem(menu, "4", "Refill");
    AddMenuItem(menu, "5", "Heal");
	AddMenuItem(menu, "6", "God");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_GiveItem2(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		
		new flags5 = GetCommandFlags("give");
		SetCommandFlags("give", flags5 & ~FCVAR_CHEAT);
		switch (param2)
        {
            case 0: //molotov
            {
                //Give the player a molotov
                FakeClientCommand(currenttarget, "give molotov");
            }
            case 1: //pistol
            {
                //Give the player a pistol
                FakeClientCommand(currenttarget, "give pistol");
            }
            case 2: //pills
            {
                //Give the player pills
                FakeClientCommand(currenttarget, "give pain_pills");
            }
			case 3: //medkit
            {
                //Give the player a medkit
                FakeClientCommand(currenttarget, "give first_aid_kit");
            }
			case 4: //refill
            {
                //Give the player an ammo refill
                FakeClientCommand(currenttarget, "give ammo");
            }
			case 5: //heal
            {
                //Heal the player
                FakeClientCommand(currenttarget, "give health");
            }
			case 6: //godmode
			{
				if (godon[currenttarget] <= 0)
				{
					godon[currenttarget] = 1;
					SetEntProp(currenttarget, Prop_Data, "m_takedamage", 0, 1);
				}
				else
				{
					godon[currenttarget] = 0;
					SetEntProp(currenttarget, Prop_Data, "m_takedamage", 2, 1);  
				}
			}
        }
		SetCommandFlags("give", flags5|FCVAR_CHEAT);
		DisplayGiveItemMenu2(param1);
	}
	else if (action == MenuAction_Cancel)
	{
		DisplayGiveItemMenu(param1);
	}
}

DisplayGiveTargetMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Give);
	
	decl String:title[100];
	Format(title, sizeof(title), "Choose player to give item to.", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Give(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "\x04[$]\x03 %s", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "\x04[$]\x03 %s", "Unable to target");
		}
		else if (!IsPlayerAlive(target))
		{
			ReplyToCommand(param1, "\x04[$]\x03 %s", "Player has since died");
		}	
		else
		{
			decl String:name[32];
			GetClientName(target, name, sizeof(name));
			currenttarget = target;
			DisplayGiveItemMenu(param1);
		}
	}
}

public Action:GiveItemMenu(client,args)
{
    DisplayGiveTargetMenu(client);
    
    return Plugin_Handled;
}

public Action:PointsChooseMenu(client,args)
{
	if(pointson)
	{
		PointsChooseMenuFunc(client);
	}
    
    return Plugin_Handled;
}

public Action:PointsMenu(client,args)
{
	if(pointson)
	{
		if(pointsteam[client] != SURVIVORTEAM)
		{
			InfectedPointsMenuFunc(client);
		}
		else
		{
			PointsMenuFunc(client);
		}
	}
    
    return Plugin_Handled;
}

public Action:PointsSpecialMenu(client,args)
{
	if(pointson)
	{
		if(pointsteam[client] != SURVIVORTEAM)
		{
			PrintToChat(client,"特殊感染者未有特殊裝備!");
		}
		else
		{
			PointsSpecialMenuFunc(client);
		}
	}
    
    return Plugin_Handled;
}

public Action:PointsMenu2(client,args)
{
	if(pointson)
	{
		if(pointsteam[client] != SURVIVORTEAM)
		{
			InfectedPointsMenu2Func(client);
		}
		else
		{
			PointsMenu2Func(client);
		}
	}
    
    return Plugin_Handled;
}

public Action:PointsMenu3(client,args)
{
	if(pointson)
	{
		if(pointsteam[client] != SURVIVORTEAM)
		{
			InfectedPointsMenu3Func(client);
		}
		else
		{
			PointsMenu3Func(client);
		}
	}
    
    return Plugin_Handled;
}

public Action:PointsConfirm(client,args)
{
	if(pointson)
	{
		PointsConfirmFunc(client);
	}
    
    return Plugin_Handled;
}

public Action:PointsMenuFunc(clientId) {
    new Handle:menu = CreateMenu(PointsMenuHandler);
    SetMenuTitle(menu, "持有金錢: %d", points[clientId]);
    AddMenuItem(menu, "option1", "步槍");
    AddMenuItem(menu, "option2", "狩獵步槍");
    AddMenuItem(menu, "option3", "自動散彈槍");
	AddMenuItem(menu, "option4", "手槍");
	AddMenuItem(menu, "option5", "下一頁");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
    return Plugin_Handled;
}

public Action:PointsMenu2Func(clientId) {
    new Handle:menu = CreateMenu(PointsMenuHandler2);
    SetMenuTitle(menu, "持有金錢: %d", points[clientId]);
	AddMenuItem(menu, "option1", "上一頁");
    AddMenuItem(menu, "option2", "散彈槍");
    AddMenuItem(menu, "option3", "衝鋒槍");
	AddMenuItem(menu, "option4", "彈藥");
    AddMenuItem(menu, "option5", "裝備選單");
    DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
    return Plugin_Handled;
}

public Action:PointsMenu3Func(clientId) {
    new Handle:menu = CreateMenu(PointsMenuHandler3);
    SetMenuTitle(menu, "持有金錢: %d", points[clientId]);
    AddMenuItem(menu, "option1", "土製鐵管炸彈");
	AddMenuItem(menu, "option2", "汽油彈");
	AddMenuItem(menu, "option3", "止痛藥");
	AddMenuItem(menu, "option4", "醫療包");
	AddMenuItem(menu, "option5", "完全回復");
    DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
    return Plugin_Handled;
}

public Action:PointsChooseMenuFunc(clientId) {
    new Handle:menu = CreateMenu(PointsChooseMenuHandler);
    SetMenuTitle(menu, "持有金錢: %d", points[clientId]);
    AddMenuItem(menu, "option1", "第一頁 (b1)");
    AddMenuItem(menu, "option2", "第二頁 (b2)");
    AddMenuItem(menu, "option3", "第三頁 (b3)");
    AddMenuItem(menu, "option4", "特殊升級 (bs)");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
    return Plugin_Handled;
}

public Action:PointsSpecialMenuFunc(clientId) {
    new Handle:menu = CreateMenu(PointsSpecialMenuHandler);
    SetMenuTitle(menu, "持有金錢: %d", points[clientId]);
    AddMenuItem(menu, "option1", "普通燃燒彈");
	AddMenuItem(menu, "option2", "特殊燃燒彈");
	AddMenuItem(menu, "option3", "將會有更多升級供購買!");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
    return Plugin_Handled;
}

public Action:PointsConfirmFunc(clientId) 
{
	new cost;
	switch (buyitem[clientId])
	{
		case 0: //shotgun
		{
			cost = GetConVarInt(shotpoints);
		}
		case 1: //smg
        {
			cost = GetConVarInt(smgpoints);
        }
		case 2: //rifle
        {
            cost = GetConVarInt(riflepoints);
        }
		case 3: //hunting rifle
		{
			cost = GetConVarInt(huntingpoints);
		}
		case 4: //auto shotgun
		{
			cost = GetConVarInt(autopoints);
		}
		case 5: //pipe bomb
		{
			cost = GetConVarInt(pipepoints);
		}
		case 6: //molotov
		{
			cost = GetConVarInt(molopoints);
		}
		case 7: //extra pistol
		{
			cost = GetConVarInt(pistolpoints);
		}
		case 8: //pills
		{
			cost = GetConVarInt(pillspoints);
		}
		case 9: //medkit
		{
			cost = GetConVarInt(medpoints);
		}
		case 10: //refill
		{
			cost = GetConVarInt(refillpoints);
		}
		case 11: //heal
		{
			cost = GetConVarInt(healpoints);
		}
		case 12: //suicide
		{
			cost = GetConVarInt(suicidepoints);
		}
		case 13: //iheal
		{
			cost = GetConVarInt(ihealpoints);
		}
		case 14: //boomer
		{
			cost = GetConVarInt(boomerpoints);
		}
		case 15: //hunter
		{
			cost = GetConVarInt(hunterpoints);
		}
		case 16: //smoker
		{
			cost = GetConVarInt(smokerpoints);
		}
		case 17: //tank
		{
			cost = GetConVarInt(tankpoints);
		}
		case 18: //witch
		{
			cost = GetConVarInt(wwitchpoints);
		}
		case 19: //mob
		{
			cost = GetConVarInt(mobpoints);
		}
		case 20: //panic
		{
			cost = GetConVarInt(panicpoints);
		}
		case 21: //incendiary
		{
			cost = GetConVarInt(burnpoints);
		}
		case 22: //super melee
		{
			cost = GetConVarInt(superburnpoints);
		}
	}
    new Handle:menu = CreateMenu(PointsConfirmHandler);
    SetMenuTitle(menu, "持有金錢: $%d, 收費: $%d", points[clientId], cost);
    AddMenuItem(menu, "option1", "確定");
    AddMenuItem(menu, "option2", "離開");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
    return Plugin_Handled;
}

public Action:InfectedPointsMenuFunc(clientId) {
    new Handle:menu = CreateMenu(InfectedPointsMenuHandler);
    SetMenuTitle(menu, "持有金錢: %d", points[clientId]);
    AddMenuItem(menu, "option1", "召喚 Tank");
    AddMenuItem(menu, "option2", "召喚 Witch");
    AddMenuItem(menu, "option3", "敵人來襲");
    AddMenuItem(menu, "option4", "大型敵襲");
	AddMenuItem(menu, "option5", "下一頁");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
    return Plugin_Handled;
}

public Action:InfectedPointsMenu2Func(clientId) {
    new Handle:menu = CreateMenu(InfectedPointsMenu2Handler);
    SetMenuTitle(menu, "持有金錢: %d", points[clientId]);
	AddMenuItem(menu, "option1", "上一頁");
    AddMenuItem(menu, "option2", "召喚 Boomer");
    AddMenuItem(menu, "option3", "召喚 Hunter");
    AddMenuItem(menu, "option4", "召喚 Smoker");
	AddMenuItem(menu, "option5", "下一頁");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
    return Plugin_Handled;
}

public Action:InfectedPointsMenu3Func(clientId) {
    new Handle:menu = CreateMenu(InfectedPointsMenu3Handler);
    SetMenuTitle(menu, "持有金錢: %d", points[clientId]);
	AddMenuItem(menu, "option1", "上一頁");
    AddMenuItem(menu, "option2", "自殺");
    AddMenuItem(menu, "option3", "回全回復");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
    return Plugin_Handled;
}

public Action:Refill(client,args)
{
	RefillFunc(client);
	
	return Plugin_Handled;
}

public Action:RefillFunc(clientId)
{
	new flags3 = GetCommandFlags("give");
	SetCommandFlags("give", flags3 & ~FCVAR_CHEAT);
	
	//Give player ammo
	FakeClientCommand(clientId, "give ammo");
	
	SetCommandFlags("give", flags3|FCVAR_CHEAT);
	
	return Plugin_Handled;
}

public Action:Heal(client,args)
{
	HealFunc(client);
	
	return Plugin_Handled;
}

public Action:HealFunc(clientId)
{
	new flags2 = GetCommandFlags("give");
	SetCommandFlags("give", flags2 & ~FCVAR_CHEAT);
	
	//Give player health
	FakeClientCommand(clientId, "give health");
	
	SetCommandFlags("give", flags2|FCVAR_CHEAT);
	
	return Plugin_Handled;
}

public Action:FakeGod(client,args)
{
	FakeGodFunc(client);
	
	return Plugin_Handled;
}

public Action:FakeGodFunc(client)
{
	if (godon[client] <= 0)
	{
		godon[client] = 1;
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	}
	else
	{
		godon[client] = 0;
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);  
	}
	
	return Plugin_Handled;
}

public Action:RepeatBuy(client, args)
{
    new giveflags = GetCommandFlags("give");
	new killflags = GetCommandFlags("kill");
	new spawnflags = GetCommandFlags("z_spawn");
	new panicflags = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("give", giveflags & ~FCVAR_CHEAT);
	SetCommandFlags("kill", killflags & ~FCVAR_CHEAT);
	SetCommandFlags("z_spawn", spawnflags & ~FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", panicflags & ~FCVAR_CHEAT);
	switch(buyitem[client])
	{
		case 0: //shotgun
		{
			if (points[client] >= GetConVarInt(shotpoints))
			{
				//Give the player a shotgun
				FakeClientCommand(client, "give pumpshotgun");
				points[client] -= GetConVarInt(shotpoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 1: //smg
		{
			if (points[client] >= GetConVarInt(smgpoints))
			{
				//Give the player an SMG
				FakeClientCommand(client, "give smg");
				points[client] -= GetConVarInt(smgpoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 2: //rifle
		{
			if (points[client] >= GetConVarInt(riflepoints))
			{
				//Give the player a rifle
				FakeClientCommand(client, "give rifle");
				points[client] -= GetConVarInt(riflepoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 3: //hunting rifle
		{
			if (points[client] >= GetConVarInt(huntingpoints))
			{
				//Give the player a hunting rifle
				FakeClientCommand(client, "give hunting_rifle");
				points[client] -= GetConVarInt(huntingpoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 4: //auto shotgun
		{
			if (points[client] >= GetConVarInt(autopoints))
			{
				//Give the player an auto shotgun
				FakeClientCommand(client, "give autoshotgun");
				points[client] -= GetConVarInt(autopoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 5: //pipe bomb
		{
			if (points[client] >= GetConVarInt(pipepoints))
			{
				//Give the player a pipebomb
				FakeClientCommand(client, "give pipe_bomb");
				points[client] -= GetConVarInt(pipepoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 6: //molotov
		{
			if (points[client] >= GetConVarInt(molopoints))
			{
				//Give the player a molotov
				FakeClientCommand(client, "give molotov");
				points[client] -= GetConVarInt(molopoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 7: //pistol
		{
			if (points[client] >= GetConVarInt(pistolpoints))
			{
				//Give the player a pistol
				FakeClientCommand(client, "give pistol");
				points[client] -= GetConVarInt(pistolpoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 8: //pills
		{
		   if (points[client] >= GetConVarInt(pillspoints))
			{
				//Give the player pain pills
				FakeClientCommand(client, "give pain_pills");
				points[client] -= GetConVarInt(pillspoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 9: //medkit
		{
			if (points[client] >= GetConVarInt(medpoints))
			{
				//Give the player a medkit
				FakeClientCommand(client, "give first_aid_kit");
				points[client] -= GetConVarInt(medpoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 10: //refill
		{
			if (points[client] >= GetConVarInt(refillpoints))
			{
				//Refill ammo
				FakeClientCommand(client, "give ammo");
				points[client] -= GetConVarInt(refillpoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 11: //heal
		{
			if (points[client] >= GetConVarInt(healpoints))
			{
				//Heal player
				FakeClientCommand(client, "give health");
				points[client] -= GetConVarInt(healpoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 12: //suicide
		{
			if (points[client] >= GetConVarInt(suicidepoints))
			{
				//Kill yourself (for boomers)
				FakeClientCommand(client, "kill");
				points[client] -= GetConVarInt(suicidepoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 13: //heal
		{
			if (points[client] >= GetConVarInt(ihealpoints))
			{
				//Give the player health
				FakeClientCommand(client, "give health");
				points[client] -= GetConVarInt(ihealpoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 14: //boomer
		{
			if (points[client] >= GetConVarInt(boomerpoints))
			{
				//Make the player a boomer
				FakeClientCommand(client, "z_spawn boomer auto");
				points[client] -= GetConVarInt(boomerpoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 15: //hunter
		{
			if (points[client] >= GetConVarInt(hunterpoints))
			{
				//Make the player a hunter
				FakeClientCommand(client, "z_spawn hunter auto");
				points[client] -= GetConVarInt(hunterpoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 16: //smoker
		{
			if (points[client] >= GetConVarInt(smokerpoints))
			{
				//Make the player a smoker
				FakeClientCommand(client, "z_spawn smoker auto");
				points[client] -= GetConVarInt(smokerpoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 17: //tank
		{
			if (points[client] >= GetConVarInt(tankpoints))
			{
				numtanks += 1;
				if (numtanks < GetConVarInt(tanklimit) + 1)
				{
					//Make the player a tank
					FakeClientCommand(client, "z_spawn tank auto");
					points[client] -= GetConVarInt(tankpoints);
				}
				else
				{
					PrintToChat(client,"\x04[$]\x03 Tank limit for the round has been reached!");
				}
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 18: //spawn witch
		{
			if (points[client] >= GetConVarInt(wwitchpoints))
			{
				numwitches += 1;
				if (numwitches < GetConVarInt(witchlimit) + 1)
				{
					//Spawn a witch
					FakeClientCommand(client, "z_spawn witch auto");
					points[client] -= GetConVarInt(wwitchpoints);
				}
				else
				{
					PrintToChat(client,"\x04[$]\x03 Witch limit for the round has been reached!");
				}
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 19: //spawn mob
		{
			if (points[client] >= GetConVarInt(mobpoints))
			{
				//Spawn a mob
				FakeClientCommand(client, "z_spawn mob");
				points[client] -= GetConVarInt(mobpoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 20: //create panic event
		{
			if (points[client] >= GetConVarInt(panicpoints))
			{
				//Spawn a mob
				FakeClientCommand(client, "director_force_panic_event");
				points[client] -= GetConVarInt(panicpoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 21: //incendiary
		{
			if (points[client] >= GetConVarInt(burnpoints))
			{
				//Give Incendiary Ammo
				hasincendiary[client] = 1;
				burntimeleft[client] = GetConVarInt(pointsburntime);
				points[client] -= GetConVarInt(burnpoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
		case 22: //super incendiary
		{
			if (points[client] >= GetConVarInt(superburnpoints))
			{
				//Give Super Incendiary
				hassuperburn[client] = 1;
				hasincendiary[client] = 1;
				sburntimeleft[client] = GetConVarInt(pointssuperburntime);
				points[client] -= GetConVarInt(superburnpoints);
			}
			else
			{
				PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
			}
		}
    }

    SetCommandFlags("give", giveflags|FCVAR_CHEAT);
	SetCommandFlags("kill", killflags|FCVAR_CHEAT);
	SetCommandFlags("z_spawn", spawnflags|FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", panicflags|FCVAR_CHEAT);
	PrintToChat(client, "\x04[$]\x03 你現在持有 $%d.",points[client]);
	
	return Plugin_Handled;
}

public PointsConfirmHandler(Handle:menu, MenuAction:action, client, itemNum)
{
    new flags = GetCommandFlags("give");
	new flags2 = GetCommandFlags("kill");
	new flags3 = GetCommandFlags("z_spawn");
	new flags4 = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	SetCommandFlags("kill", flags2 & ~FCVAR_CHEAT);
	SetCommandFlags("z_spawn", flags3 & ~FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flags4 & ~FCVAR_CHEAT);
    
    if ( action == MenuAction_Select ) {
        
        if(itemNum == 0)
		{
			switch(buyitem[client])
			{
				case 0: //shotgun
				{
					if (points[client] >= GetConVarInt(shotpoints))
					{
						//Give the player a shotgun
						FakeClientCommand(client, "give pumpshotgun");
						points[client] -= GetConVarInt(shotpoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 1: //smg
				{
					if (points[client] >= GetConVarInt(smgpoints))
					{
						//Give the player an SMG
						FakeClientCommand(client, "give smg");
						points[client] -= GetConVarInt(smgpoints);
					}
					else
					{
					PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 2: //rifle
				{
					if (points[client] >= GetConVarInt(riflepoints))
					{
						//Give the player a rifle
						FakeClientCommand(client, "give rifle");
						points[client] -= GetConVarInt(riflepoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 3: //hunting rifle
				{
					if (points[client] >= GetConVarInt(huntingpoints))
					{
						//Give the player a hunting rifle
						FakeClientCommand(client, "give hunting_rifle");
						points[client] -= GetConVarInt(huntingpoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 4: //auto shotgun
				{
					if (points[client] >= GetConVarInt(autopoints))
					{
						//Give the player an auto shotgun
						FakeClientCommand(client, "give autoshotgun");
						points[client] -= GetConVarInt(autopoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 5: //pipe bomb
				{
					if (points[client] >= GetConVarInt(pipepoints))
					{
						//Give the player a pipebomb
						FakeClientCommand(client, "give pipe_bomb");
						points[client] -= GetConVarInt(pipepoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 6: //molotov
				{
					if (points[client] >= GetConVarInt(molopoints))
					{
						//Give the player a molotov
						FakeClientCommand(client, "give molotov");
						points[client] -= GetConVarInt(molopoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 7: //pistol
				{
					if (points[client] >= GetConVarInt(pistolpoints))
					{
						//Give the player a pistol
						FakeClientCommand(client, "give pistol");
						points[client] -= GetConVarInt(pistolpoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 8: //pills
				{
				   if (points[client] >= GetConVarInt(pillspoints))
					{
						//Give the player pain pills
						FakeClientCommand(client, "give pain_pills");
						points[client] -= GetConVarInt(pillspoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 9: //medkit
				{
					if (points[client] >= GetConVarInt(medpoints))
					{
						//Give the player a medkit
						FakeClientCommand(client, "give first_aid_kit");
						points[client] -= GetConVarInt(medpoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 10: //refill
				{
					if (points[client] >= GetConVarInt(refillpoints))
					{
						//Refill ammo
						FakeClientCommand(client, "give ammo");
						points[client] -= GetConVarInt(refillpoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 11: //heal
				{
					if (points[client] >= GetConVarInt(healpoints))
					{
						//Heal player
						FakeClientCommand(client, "give health");
						points[client] -= GetConVarInt(healpoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 12: //suicide
				{
					if (points[client] >= GetConVarInt(suicidepoints))
					{
						//Kill yourself (for boomers)
						FakeClientCommand(client, "kill");
						points[client] -= GetConVarInt(suicidepoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 13: //heal
				{
					if (points[client] >= GetConVarInt(ihealpoints))
					{
						//Give the player health
						FakeClientCommand(client, "give health");
						points[client] -= GetConVarInt(ihealpoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 14: //boomer
				{
					if (points[client] >= GetConVarInt(boomerpoints))
					{
						//Make the player a boomer
						FakeClientCommand(client, "z_spawn boomer auto");
						points[client] -= GetConVarInt(boomerpoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 15: //hunter
				{
					if (points[client] >= GetConVarInt(hunterpoints))
					{
						//Make the player a hunter
						FakeClientCommand(client, "z_spawn hunter auto");
						points[client] -= GetConVarInt(hunterpoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 16: //smoker
				{
					if (points[client] >= GetConVarInt(smokerpoints))
					{
						//Make the player a smoker
						FakeClientCommand(client, "z_spawn smoker auto");
						points[client] -= GetConVarInt(smokerpoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 17: //tank
				{
					if (points[client] >= GetConVarInt(tankpoints))
					{
						numtanks += 1;
						if (numtanks < GetConVarInt(tanklimit) + 1)
						{
							//Make the player a tank
							FakeClientCommand(client, "z_spawn tank auto");
							points[client] -= GetConVarInt(tankpoints);
						}
						else
						{
							PrintToChat(client,"\x04[$]\x03 Tank limit for the round has been reached!");
						}
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 18: //spawn witch
				{
					if (points[client] >= GetConVarInt(wwitchpoints))
					{
						numwitches += 1;
						if (numwitches < GetConVarInt(witchlimit) + 1)
						{
							//Spawn a witch
							FakeClientCommand(client, "z_spawn witch auto");
							points[client] -= GetConVarInt(wwitchpoints);
						}
						else
						{
							PrintToChat(client,"\x04[$]\x03 無法召喚Witch! 超過召喚次數上限");
						}
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 19: //spawn mob
				{
					if (points[client] >= GetConVarInt(mobpoints))
					{
						//Spawn a mob
						FakeClientCommand(client, "z_spawn mob");
						points[client] -= GetConVarInt(mobpoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 20: //spawn mega mob
				{
					if (points[client] >= GetConVarInt(panicpoints))
					{
						//Spawn a mob
						FakeClientCommand(client, "z_spawn mob;z_spawn mob;z_spawn mob;z_spawn mob;z_spawn mob");
						points[client] -= GetConVarInt(panicpoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 21: //incendiary
				{
					if (points[client] >= GetConVarInt(burnpoints))
					{
						//Give Incendiary Ammo
						hasincendiary[client] = 1;
						burntimeleft[client] = GetConVarInt(pointsburntime);
						points[client] -= GetConVarInt(burnpoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
				case 22: //super incendiary
				{
					if (points[client] >= GetConVarInt(superburnpoints))
					{
						//Give Super Incendiary
						hassuperburn[client] = 1;
						sburntimeleft[client] = GetConVarInt(pointssuperburntime);
						points[client] -= GetConVarInt(superburnpoints);
					}
					else
					{
						PrintToChat(client,"\x04[$]\x03 現金不足! 無法購買!");
					}
				}
			}
		}
    }

    SetCommandFlags("give", flags|FCVAR_CHEAT);
	SetCommandFlags("kill", flags2|FCVAR_CHEAT);
	SetCommandFlags("z_spawn", flags3|FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flags4|FCVAR_CHEAT);
	PrintToChat(client, "\x04[$]\x03 你現在持有 $%d.",points[client]);
}

public PointsMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
    
    if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
            case 0: //rifle
            {
				if (GetConVarInt(riflepoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 2;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 1: //hunting rifle
            {
				if (GetConVarInt(huntingpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 3;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 2: //auto shotgun
            {
				if (GetConVarInt(autopoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 4;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 3: //pistol
            {
				if (GetConVarInt(pistolpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 7;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 4: //more
			{
				//Go to menu 2
				FakeClientCommand(client, "b2");
			}
        }
    }
}

public PointsMenuHandler2(Handle:menu, MenuAction:action, client, itemNum)
{
    
    if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
			case 0: //back
            {
                //Go back
                FakeClientCommand(client, "b1");
            }
			case 1: //shotgun
            {
				if (GetConVarInt(shotpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					//Give the player a shotgun
					buyitem[client] = 0;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
            case 2: //smg
            {
				if (GetConVarInt(smgpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 1;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 3: //refill
			{
				if (GetConVarInt(refillpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 10;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
			case 4: //more
			{
				//Go to menu 3
				FakeClientCommand(client, "b3");
			}
		}
    }
}

public PointsMenuHandler3(Handle:menu, MenuAction:action, client, itemNum)
{
    
    if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
			case 0: //pipe_bomb
            {
				if (GetConVarInt(pipepoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 5;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 1: //molotov
            {
				if (GetConVarInt(molopoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 6;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
            case 2: //pills
            {
				if (GetConVarInt(pillspoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 8;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
            case 3: //medkit
            {
				if (GetConVarInt(medpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 9;
					FakeClientCommand(client, "pointsconfirm");
				}
            }

			case 4: //heal
			{
				if (GetConVarInt(healpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 11;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
        }
    }
}

public InfectedPointsMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
    if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
			case 0: //tank
            {
				if (GetConVarInt(tankpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 17;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
            case 1: //witch
            {
				if (GetConVarInt(wwitchpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 18;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
            case 2: //mob
            {
				if (GetConVarInt(mobpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 19;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
            case 3: //mega mob
            {
				if (GetConVarInt(panicpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 20;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 4: //next page
			{
				FakeClientCommand(client,"b2");
			}
        }
    }
}

public InfectedPointsMenu2Handler(Handle:menu, MenuAction:action, client, itemNum)
{
    if ( action == MenuAction_Select ) 
	{
        
        switch (itemNum)
        {
			case 0: //back page
			{
				FakeClientCommand(client,"b1");
			}
		    case 1: //boomer
            {
				if (GetConVarInt(boomerpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 14;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 2: //hunter
            {
				if (GetConVarInt(hunterpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 15;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 3: //smoker
            {
				if (GetConVarInt(smokerpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 16;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 4: //next page
			{
				FakeClientCommand(client,"b3");
			}
        }
	}
	else if (action == MenuAction_Cancel)
	{
		FakeClientCommand(client,"pointsmenu");
	}
}

public InfectedPointsMenu3Handler(Handle:menu, MenuAction:action, client, itemNum)
{
    if ( action == MenuAction_Select ) 
	{
        
        switch (itemNum)
        {
			case 0: //back page
			{
				FakeClientCommand(client,"b2");
			}
			case 1: //suicide
            {
				if (GetConVarInt(suicidepoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 12;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
            case 2: //heal
            {
				if (GetConVarInt(ihealpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 13;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
        }
	}
	else if (action == MenuAction_Cancel)
	{
		FakeClientCommand(client,"pointsmenu");
	}
}

public PointsSpecialMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
    if ( action == MenuAction_Select ) 
	{
        
        switch (itemNum)
        {
            case 0: //incendiary
            {
				if (GetConVarInt(burnpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 21;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
			case 1: //super incendiary
			{
				if (GetConVarInt(superburnpoints) < 0)
				{
					PrintToChat(client,"\x04[$]\x03 伺服器禁售.");
				}
				else
				{
					buyitem[client] = 22;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
        }
	}
}

public PointsChooseMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
    if ( action == MenuAction_Select ) 
	{
        
        switch (itemNum)
        {
            case 0: //normal
            {
				FakeClientCommand(client,"b1");
			}
            case 1: //normal
            {
				FakeClientCommand(client,"b2");
			}
            case 2: //normal
            {
				FakeClientCommand(client,"b3");
			}
			case 3: //special
            {
				FakeClientCommand(client,"bs");
			}
        }
	}
}