#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "0.99"
#define STRING_LENGTH_NAME		32

//core
new Handle:as_horde;
new Handle:as_horde_info;
new Handle:as_drone_randoms;
new Handle:as_horde_mode;
new Handle:as_horde_static;


//horde 
new Handle:horde_interval_min;
new Handle:horde_interval_max;
new Handle:peak_min_time;
new Handle:peak_max_time;

new Handle:horde_min_dro;
new Handle:horde_max_dro;
new Handle:horde_min_drj;
new Handle:horde_max_drj;
new Handle:horde_min_dru;
new Handle:horde_max_dru;
new Handle:horde_min_par;
new Handle:horde_max_par;
new Handle:horde_min_buz;
new Handle:horde_max_buz;
new Handle:horde_min_ran;
new Handle:horde_max_ran;
new Handle:horde_min_har;
new Handle:horde_max_har;
new Handle:horde_min_boo;
new Handle:horde_max_boo;
new Handle:horde_min_mor;
new Handle:horde_max_mor;
new Handle:horde_min_sha;
new Handle:horde_max_sha;
new Handle:horde_min_shb;
new Handle:horde_max_shb;
new Handle:horde_min_que;
new Handle:horde_max_que;
new Handle:horde_min_bha;
new Handle:horde_max_bha;
new Handle:horde_min_bsb;
new Handle:horde_max_bsb;
new Handle:horde_min_bdr;
new Handle:horde_max_bdr;

//drone
new Handle:drone_health_max;
new Handle:drone_yaw_speed_attackprep_max;
new Handle:drone_yaw_speed_attacking_max;
new Handle:drone_yaw_speed_max;
new Handle:drone_yaw_speed_min;
new Handle:drone_yaw_speed_attacking_min;
new Handle:drone_yaw_speed_attackprep_min;
new Handle:drone_health_min;


static Handle:as_horde_aliens		= INVALID_HANDLE;

///part of http://forums.alliedmods.net/showthread.php?t=109623 and big thnx to AtomicStryker
enum aliens
{
	drone,
	drone_jumper,
	drone_uber,
	parasite,
	buzzer,
	ranger,
	shaman,
	harvester,
	boomer,
	mortar,
	shieldbug,
	queen, 
	beta_harvester,
	beta_shieldbug,
	beta_drone,
	xenomite
}

enum alienInfo
{
	String:aname[STRING_LENGTH_NAME],
	String:bname[STRING_LENGTH_NAME],
	flag,
	max,
	min
}
static alienData[aliens][alienInfo];
static InitDataArray()
{
	Format(alienData[drone][aname], 		STRING_LENGTH_NAME-1, 		"asw_drone");
	Format(alienData[drone_jumper][aname],	STRING_LENGTH_NAME-1, 		"asw_drone_jumper");
	Format(alienData[drone_uber][aname], 	STRING_LENGTH_NAME-1, 		"asw_drone_uber");
	Format(alienData[parasite][aname],		STRING_LENGTH_NAME-1, 		"asw_parasite");
	Format(alienData[buzzer][aname], 		STRING_LENGTH_NAME-1, 		"asw_buzzer");
	Format(alienData[ranger][aname], 		STRING_LENGTH_NAME-1, 		"asw_ranger");
	Format(alienData[shaman][aname],		STRING_LENGTH_NAME-1, 		"asw_shaman");
	Format(alienData[harvester][aname], 	STRING_LENGTH_NAME-1, 		"asw_harvester");
	Format(alienData[boomer][aname],		STRING_LENGTH_NAME-1, 		"asw_boomer");
	Format(alienData[mortar][aname], 		STRING_LENGTH_NAME-1, 		"asw_mortarbug");
	Format(alienData[shieldbug][aname],		STRING_LENGTH_NAME-1, 		"asw_shieldbug");
	Format(alienData[queen][aname], 		STRING_LENGTH_NAME-1, 		"asw_queen");
	Format(alienData[beta_harvester][aname],STRING_LENGTH_NAME-1, 		"asw_harvester");
	Format(alienData[beta_shieldbug][aname],STRING_LENGTH_NAME-1, 		"asw_shieldbug");
	Format(alienData[beta_drone][aname], 	STRING_LENGTH_NAME-1, 		"asw_drone");
	Format(alienData[xenomite][aname], 		STRING_LENGTH_NAME-1, 		"asw_parasite_defanged'"); 
	//Format(alienData[grub][aname], 			STRING_LENGTH_NAME-1, 		"asw_grub");
	//Format(alienData[zombie][aname], 			STRING_LENGTH_NAME-1, 		"asw_zombie"); asw_zombie.cpp
	
	Format(alienData[drone][bname], 		STRING_LENGTH_NAME-1, 		"Drones");
	Format(alienData[drone_jumper][bname],	STRING_LENGTH_NAME-1, 		"Drone Jumpers");
	Format(alienData[drone_uber][bname], 	STRING_LENGTH_NAME-1, 		"Uber Drones");
	Format(alienData[parasite][bname],		STRING_LENGTH_NAME-1, 		"Parasites");
	Format(alienData[buzzer][bname], 		STRING_LENGTH_NAME-1, 		"Buzzers");
	Format(alienData[ranger][bname], 		STRING_LENGTH_NAME-1, 		"Rangers");
	Format(alienData[shaman][bname],		STRING_LENGTH_NAME-1, 		"Shamans");
	Format(alienData[harvester][bname], 	STRING_LENGTH_NAME-1, 		"Harvesters");
	Format(alienData[boomer][bname],		STRING_LENGTH_NAME-1, 		"Boomers");
	Format(alienData[mortar][bname], 		STRING_LENGTH_NAME-1, 		"Mortarbugs");
	Format(alienData[shieldbug][bname],		STRING_LENGTH_NAME-1, 		"Shieldbugs");
	Format(alienData[queen][bname], 		STRING_LENGTH_NAME-1, 		"Queen");
	Format(alienData[beta_harvester][bname],STRING_LENGTH_NAME-1, 		"Harvesters (Betastyle)");
	Format(alienData[beta_shieldbug][bname],STRING_LENGTH_NAME-1, 		"Shieldbugs (Betastyle)");
	Format(alienData[beta_drone][bname], 	STRING_LENGTH_NAME-1, 		"Drones (Betastyle)");
	Format(alienData[xenomite][bname], 		STRING_LENGTH_NAME-1, 		"Harvester Spawns"); 
	
	alienData[drone][flag]			= 1;				//	0
	alienData[drone_jumper][flag]	= 2;				//	1
	alienData[drone_uber][flag]		= 4;				//	2
	alienData[parasite][flag]		= 8;				//	3
	alienData[buzzer][flag]			= 16;				//	4
	alienData[ranger][flag]			= 32;				//	5
	alienData[shaman][flag]			= 64;				//	6
	alienData[harvester][flag]		= 128;				//	7
	alienData[boomer][flag]			= 256;				//	8
	alienData[mortar][flag]			= 512;				//	9
	alienData[shieldbug][flag]		= 1024;				//	10
	alienData[queen][flag]			= 2048;				//	11
	alienData[beta_harvester][flag]	= 4096;				//	12
	alienData[beta_shieldbug][flag]	= 8192;				//	13
	alienData[beta_drone][flag]		= 16384;			//	14
	alienData[xenomite][flag]		= 32768;			//	15
	//alienData[grub][flag]			= 65536;

}

public Plugin:myinfo = 
{
	name = "[AS] HoRde MoDe",
	author = "dYZER",
	description = "Controlls Horde and Drones",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=133905"
}

public OnPluginStart()
{
	CreateConVar("as_horde_mode_version", PLUGIN_VERSION, "Version of Horde Mode", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	//Hord Mod
	as_horde = CreateConVar("as_horde", "1", "Horde Mode ON/OFF (1/0)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	as_horde_info = CreateConVar("as_horde_info", "1", "enable disable Hord Mod Infotext (1/0)", FCVAR_PLUGIN);
	
	horde_interval_min = CreateConVar("as_horde_interval_min", "10", "horde_interval_min (def 70)", FCVAR_PLUGIN);
	horde_interval_max = CreateConVar("as_horde_interval_max", "30", "horde_interval_max (def 150)", FCVAR_PLUGIN);
	peak_min_time = CreateConVar("as_peak_min_time", "1", "director_peak_min_time (def 1)", FCVAR_PLUGIN);
	peak_max_time = CreateConVar("as_peak_max_time", "2", "director_peak_max_time (def 3)", FCVAR_PLUGIN);

	as_horde_mode = CreateConVar("as_horde_mode", "2", " /0=default /1=Static /2=binary settings /3=aliens horde_size_max settings", FCVAR_PLUGIN);

	as_horde_aliens = CreateConVar("as_horde_aliens", "5162", "binary flags of allowed aliens in random order ,example /4096[beta_harvester] + 32[ranger] + 8[parasite] + 2[drone_jumper] + 1024[shieldbug] / 4096+32+8+2+1024=5162", FCVAR_PLUGIN);
	as_horde_static = CreateConVar("as_horde_static", "8", "binary flag of alien ,1=drone,2=drone_jumper,4=drone_uber,8=parasite,16=buzzer,32=ranger,64=shaman,128=harvester,256=boomer,512=mortar,1024=shieldbug,2048=queen,4096=Beta-harvester,8192=Beta-shieldbug,16384=beta Drones", FCVAR_PLUGIN);
	
	//min/max
	horde_min_dro = CreateConVar("as_horde_min_dro", "8", "drone horde_size_min", FCVAR_PLUGIN);
	horde_max_dro = CreateConVar("as_horde_max_dro", "18", "drone horde_size_max", FCVAR_PLUGIN);
	horde_min_drj = CreateConVar("as_horde_min_drj", "8", "drone_jumper horde_size_min", FCVAR_PLUGIN);
	horde_max_drj = CreateConVar("as_horde_max_drj", "14", "drone_jumper horde_size_max", FCVAR_PLUGIN);
	horde_min_dru = CreateConVar("as_horde_min_dru", "2", "drone_uber horde_size_min", FCVAR_PLUGIN);
	horde_max_dru = CreateConVar("as_horde_max_dru", "4", "drone_uber horde_size_max", FCVAR_PLUGIN);
	horde_min_par = CreateConVar("as_horde_min_par", "4", "parasite horde_size_min", FCVAR_PLUGIN);
	horde_max_par = CreateConVar("as_horde_max_par", "10", "parasite horde_size_max", FCVAR_PLUGIN);
	horde_min_buz = CreateConVar("as_horde_min_buz", "5", "buzzer horde_size_min", FCVAR_PLUGIN);
	horde_max_buz = CreateConVar("as_horde_max_buz", "12", "buzzer horde_size_max", FCVAR_PLUGIN);
	horde_min_ran = CreateConVar("as_horde_min_ran", "3", "ranger horde_size_min", FCVAR_PLUGIN);
	horde_max_ran = CreateConVar("as_horde_max_ran", "6", "ranger horde_size_max", FCVAR_PLUGIN);
	horde_min_har = CreateConVar("as_horde_min_har", "3", "harvester horde_size_min", FCVAR_PLUGIN);
	horde_max_har = CreateConVar("as_horde_max_har", "5", "harvester horde_size_max", FCVAR_PLUGIN);
	horde_min_boo = CreateConVar("as_horde_min_boo", "2", "boomer horde_size_min", FCVAR_PLUGIN);
	horde_max_boo = CreateConVar("as_horde_max_boo", "4", "boomer horde_size_max", FCVAR_PLUGIN);
	horde_min_mor = CreateConVar("as_horde_min_mor", "1", "mortar horde_size_min", FCVAR_PLUGIN);
	horde_max_mor = CreateConVar("as_horde_max_mor", "3", "mortar horde_size_max", FCVAR_PLUGIN);	
	horde_min_sha = CreateConVar("as_horde_min_sha", "3", "shaman horde_size_min", FCVAR_PLUGIN);
	horde_max_sha = CreateConVar("as_horde_max_sha", "5", "shaman horde_size_max", FCVAR_PLUGIN);
	horde_min_shb = CreateConVar("as_horde_min_shb", "2", "shieldbug horde_size_min", FCVAR_PLUGIN);
	horde_max_shb = CreateConVar("as_horde_max_shb", "4", "shieldbug horde_size_max", FCVAR_PLUGIN);
	horde_min_que = CreateConVar("as_horde_min_que", "1", "queen horde_size_min", FCVAR_PLUGIN);
	horde_max_que = CreateConVar("as_horde_max_que", "1", "queen horde_size_max", FCVAR_PLUGIN);
	horde_min_bha = CreateConVar("as_horde_min_bha", "3", "beta_harvester horde_size_min", FCVAR_PLUGIN);
	horde_max_bha = CreateConVar("as_horde_max_bha", "5", "beta_harvester horde_size_max", FCVAR_PLUGIN);
	horde_min_bsb = CreateConVar("as_horde_min_bsb", "2", "beta_shieldbug horde_size_min", FCVAR_PLUGIN);
	horde_max_bsb = CreateConVar("as_horde_max_bsb", "4", "beta_shieldbug horde_size_max", FCVAR_PLUGIN);	
	horde_min_bdr = CreateConVar("as_horde_min_bdr", "10", "beta_shieldbug horde_size_min", FCVAR_PLUGIN);
	horde_max_bdr = CreateConVar("as_horde_max_bdr", "18", "beta_shieldbug horde_size_max", FCVAR_PLUGIN);	
	
	//randoms Drone
	as_drone_randoms = CreateConVar("as_drone_randoms", "1", "Random Drones ON/OFF (1/0)", FCVAR_PLUGIN);
	drone_health_min = CreateConVar("as_drone_health_min", "20", "min drone hp (def 40)", FCVAR_PLUGIN);	
	drone_health_max = CreateConVar("as_drone_health_max", "120", "max drone hp (def 40)", FCVAR_PLUGIN);	
	drone_yaw_speed_min = CreateConVar("as_drone_yaw_speed_min", "20", "min drone speed (def 32.0)", FCVAR_PLUGIN);	
	drone_yaw_speed_max = CreateConVar("as_drone_yaw_speed_max", "75", "max drone speed (def 32.0)", FCVAR_PLUGIN);	
	drone_yaw_speed_attacking_min = CreateConVar("as_drone_yaw_speed_attacking_min", "4", "drone speed_attacking_min (def 8.0)", FCVAR_PLUGIN);	
	drone_yaw_speed_attacking_max = CreateConVar("as_drone_yaw_speed_attacking_max", "12", "drone speed_attacking_max (def 8.0)", FCVAR_PLUGIN);	
	drone_yaw_speed_attackprep_min = CreateConVar("as_drone_yaw_speed_attackprep_min", "40", "drone speed_attackprep_min (def 64.0)", FCVAR_PLUGIN);	
	drone_yaw_speed_attackprep_max = CreateConVar("as_drone_yaw_speed_attackprep_max", "100", "drone speed_attackprep_max (def 64.0)", FCVAR_PLUGIN);	


	InitDataArray();
	setminmax();
	//4vote didnt working
	//RegConsoleCmd("say", Command_Say);

	//omg timer, cant get any event atm / andbygameframe2high
	CreateTimer(10.0, rando, -1, TIMER_REPEAT);

	AutoExecConfig(true, "as_horde99");
	HookConVarChange(as_horde, ConVarChange);
	HookConVarChange(as_horde_info, ConVarChange);
	HookConVarChange(as_horde_mode, ConVarChange);
	HookConVarChange(as_drone_randoms, ConVarChange);
	HookConVarChange(as_horde_aliens, ConVarChange);
	HookConVarChange(as_horde_static, ConVarChange);

}

/*// vote and a event not supported 
//(--- Missing Vgui material vgui/plugin/message_waiting)
// not worx, atm :( 



public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "asw_drone"))
	{
		PrintToChatAll("asw_drone");
		//randomit();
	}
	PrintToServer("%s",classname);
}

//NO VOTE MENU worx 
//(--- Missing Vgui material vgui/plugin/message_waiting)

public Action:Command_Say(client, args)
{
	if(!client) return Plugin_Continue;
	decl String:text[192];
	if(!GetCmdArgString(text, sizeof(text))) return Plugin_Continue;
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
		}
	if(strcmp(text[startidx], "!hord", false) == 0) hordevote();
	return Plugin_Continue;
}

hordevote()
{
//old
	new Handle:hordev = CreateMenu(Handle_hordev);
	SetMenuTitle(hordev, "Horde Vote");
	AddMenuItem(hordev, "0", "Random");
	AddMenuItem(hordev, "1", "Drone");
	AddMenuItem(hordev, "3", "Parasite");
	AddMenuItem(hordev, "4", "Buzzer");
	AddMenuItem(hordev, "5", "Ranger");
	AddMenuItem(hordev, "6", "Harvester");
	AddMenuItem(hordev, "7", "Boomer");
	AddMenuItem(hordev, "8", "Mortar");
	AddMenuItem(hordev, "9", "Shieldbug");
	AddMenuItem(hordev, "10", "Drone Uber");
	AddMenuItem(hordev, "11", "Drone Jumper");
	AddMenuItem(hordev, "12", "Queen");
	SetMenuExitButton(hordev, false);
	VoteMenuToAll(hordev, 20);
}
public Handle_hordev(Handle:hordev, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(hordev);
	} else if (action == MenuAction_VoteEnd) {

			if (param1 == 0)
			{
			SetConVarInt(as_horde_random, 1, false, false);
			}
			if (param1 > 1)
			{
			SetConVarString(FindConVar("asw_horde_class"), alienData[param1][aname]);
			SetConVarInt(as_horde_random, 0, false, false);
			PrintToChatAll("[HoRde MoDe] %s Hords",alienData[param1][aname]);
			}
	} else if (action == MenuAction_Cancel) {
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
}

*/
public OnMapStart()
{
	setminmax();
	if (GetConVarInt(as_horde_info) == 1) 
	{
		if (GetConVarInt(as_horde)) omgall();
		if (GetConVarInt(as_drone_randoms) == 1) PrintToChatAll("[HoRde MoDe] Random Drones");
		//if (GetConVarInt(as_drone_randoms) == 0) PrintToChatAll("[HoRde MoDe] Normal Drones");
	}
}

public OnClientPutInServer(client)
{
	if ((IsClientConnected(client)) && (GetConVarInt(as_horde_info) == 1))
	{
		CreateTimer(15.0, announce, client);
	}
}

public Action:announce(Handle:timer,  any:client) 
{ 
	if (GetConVarInt(as_horde_info) == 1) 
	{
		if (GetConVarInt(as_horde))
		{
			if (GetConVarInt(as_horde_mode) >= 2) PrintToChat(client,"[HoRde MoDe] Random Hords");
			if (GetConVarInt(as_horde_mode) == 1) 
			{
				new i;
				new as_horde_stati = GetConVarInt(as_horde_static);
				for (i=0; i<=sizeof(alienData)-1; i++) 
				{ 
					if (as_horde_stati == alienData[i][flag])
					{ 
						PrintToChat(client,"[HoRde MoDe] %s Hords",alienData[i][bname]); 
					}
				}
			}
			if (GetConVarInt(as_horde_mode) == 0)
			{
				PrintToChat(client,"[HoRde MoDe] %s Hords",alienData[0][bname]);  
			}
		}
		if (GetConVarInt(as_drone_randoms) == 1) PrintToChat(client,"[HoRde MoDe] Random Drones");
		//if (GetConVarInt(as_drone_randoms) == 0) PrintToChat(client,"[HoRde MoDe] Normal Drones");
	}

}
public ConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FindConVar("as_horde"), GetConVarInt(as_horde));
	SetConVarInt(FindConVar("as_horde_info"), GetConVarInt(as_horde_info));
	SetConVarInt(FindConVar("as_drone_randoms"), GetConVarInt(as_drone_randoms));
	SetConVarInt(FindConVar("as_horde_aliens"), GetConVarInt(as_horde_aliens));
	SetConVarInt(FindConVar("as_horde_static"), GetConVarInt(as_horde_static));
	SetConVarInt(FindConVar("as_horde_mode"), GetConVarInt(as_horde_mode));
	setminmax();
	
	if (GetConVarInt(as_horde_info) == 1) 
	{
		if (GetConVarInt(as_horde))
		{
			omgall();
		}
		if (cvar == as_drone_randoms) 
		{
			if (GetConVarInt(as_drone_randoms) == 1) PrintToChatAll("[HoRde MoDe] Random Drones");
			if (GetConVarInt(as_drone_randoms) == 0) PrintToChatAll("[HoRde MoDe] Normal Drones");
		} 
	}
}
omgall()
{
	new i;
	new as_horde_stati = GetConVarInt(as_horde_static);
	
	if (GetConVarInt(as_horde_mode) >= 2) PrintToChatAll("[HoRde MoDe] Random Hords");
	if (GetConVarInt(as_horde_mode) == 1)
	{
		for (i=0; i<=sizeof(alienData)-1; i++) 
		{ 
			if (as_horde_stati == alienData[i][flag])
			{ 
				PrintToChatAll("[HoRde MoDe] %s Hords",alienData[i][bname]); 
			}
		}
	}
	if (GetConVarInt(as_horde_mode) == 0)
	{
		PrintToChatAll("[HoRde MoDe] %s Hords",alienData[0][bname]); 
	}
}
public Action:rando(Handle:timer) {	randomit(); }

randomit()
{
	if (GetConVarInt(as_drone_randoms) == 1) 
	{
		setdrones();
	}
	if (GetConVarInt(as_drone_randoms) == 0) 
	{
		resetdrone();
	}
	if (GetConVarInt(as_horde) == 1) 
	{
	
		//convar hook/reset by timer10sec,omg gimmi events
		//setminmax(); //disabled here
		//set hords
		sethord();
	}
	if (GetConVarInt(as_horde) == 0) resethord();
}

GetAllowedAlienInf(style)
{
	new as_horde_alist = GetConVarInt(as_horde_aliens);
	new as_horde_stati = GetConVarInt(as_horde_static);
	new number = 0;
	
	if (style == 1)
	{
		for (new i=0; i<=sizeof(alienData)-1; i++)
		{
			if (as_horde_stati == alienData[i][flag])
			{
				//overwrite fix, if max horde_size 0, and style=1(static)
				if (alienData[i][max] == 0)	{ alienData[i][max] = 1; }

				number = i;	
			}
		}
	}
	
	if (style == 2)
	{
		do
		{
			number = GetRandomInt(0, sizeof(alienData)-1);		
		}
		while (!(as_horde_alist & alienData[number][flag]) || (alienData[number][max]==0));

	}
	
	if (style == 3)
	{
		do
		{
			number = GetRandomInt(0, sizeof(alienData)-1);		
		}
		while ((alienData[number][max]==0));

	}
	
	return number;
}

sethord()
{
	//hord settings
	if (GetConVarInt(FindConVar("asw_horde_override")) != 1) { SetConVarInt(FindConVar("asw_horde_override"), 1); }
	if (GetConVarInt(FindConVar("asw_shieldbug_force_defend")) != 1) { SetConVarInt(FindConVar("asw_shieldbug_force_defend"), 1); }
	SetConVarInt(FindConVar("asw_horde_interval_min"), GetConVarInt(horde_interval_min));
	SetConVarInt(FindConVar("asw_horde_interval_max"), GetConVarInt(horde_interval_max));
	
	SetConVarInt(FindConVar("asw_director_peak_min_time"), GetConVarInt(peak_min_time));
	SetConVarInt(FindConVar("asw_director_peak_max_time"), GetConVarInt(peak_max_time));

	
	//									CASW_Director m_bHordeInProgress	
	//event Will be spawning a horde in 29.862221 seconds			CASW_Director flDuration
	//event Created horde of size 11								CASW_Spawn_Manager::Update m_iHordeToSpawn
	//event Horde finishes spawning									CASW_Director::OnHordeFinishedSpawning(){sethord();}

	new style = GetConVarInt(as_horde_mode);
	new currentclass = GetAllowedAlienInf(style);
	
	if (style >= 1)
	{
		//this is part of the style-changer (10secs intervall) to betaskins , need realy a spawn hord events to set this better ...
		//event on hord spawning interval , set xxx-style, on finish create hord and finish spawning,change back xxx-style...
		if (currentclass == 12) { SetConVarInt(FindConVar("asw_harvester_new"), 0); } 
		if (currentclass != 12) { SetConVarInt(FindConVar("asw_harvester_new"), 1); }
		if (currentclass == 13) { SetConVarInt(FindConVar("asw_old_shieldbug"), 1); } 
		if (currentclass != 13) { SetConVarInt(FindConVar("asw_old_shieldbug"), 0); }
		if (currentclass == 14) { SetConVarInt(FindConVar("asw_new_drone"), 0); } 
		if (currentclass != 14) { SetConVarInt(FindConVar("asw_new_drone"), 1); }

		
		//set horde_class now
		SetConVarString(FindConVar("asw_horde_class"), alienData[currentclass][aname]);
		SetConVarInt(FindConVar("asw_horde_size_max"), alienData[currentclass][max]);
		SetConVarInt(FindConVar("asw_horde_size_min"), alienData[currentclass][min]);
		
	}
	if (style == 0) 
	{ 
		//set all 2 defaul, without the interval
		ResetConVar(FindConVar("asw_horde_class"), true, true);
		ResetConVar(FindConVar("asw_horde_size_min"), true, true);
		ResetConVar(FindConVar("asw_horde_size_max"), true, true);
	}
}

resethord()
{
	ResetConVar(FindConVar("asw_horde_override"), true, true);
	ResetConVar(FindConVar("asw_horde_size_min"), true, true);
	ResetConVar(FindConVar("asw_horde_size_max"), true, true);
	ResetConVar(FindConVar("asw_horde_interval_min"), true, true);
	ResetConVar(FindConVar("asw_horde_interval_max"), true, true);
	ResetConVar(FindConVar("asw_horde_class"), true, true);
}


setminmax()
{
//max
	alienData[drone][max]			= GetConVarInt(horde_max_dro);
	alienData[drone_jumper][max]	= GetConVarInt(horde_max_drj);
	alienData[drone_uber][max]		= GetConVarInt(horde_max_dru);
	alienData[parasite][max]		= GetConVarInt(horde_max_par);
	alienData[buzzer][max]			= GetConVarInt(horde_max_buz);
	alienData[ranger][max]			= GetConVarInt(horde_max_ran);
	alienData[shaman][max]			= GetConVarInt(horde_max_sha);
	alienData[harvester][max]		= GetConVarInt(horde_max_har);
	alienData[boomer][max]			= GetConVarInt(horde_max_boo);
	alienData[mortar][max]			= GetConVarInt(horde_max_mor);
	alienData[shieldbug][max]		= GetConVarInt(horde_max_shb);
	alienData[queen][max]			= GetConVarInt(horde_max_que);
	alienData[beta_harvester][max]	= GetConVarInt(horde_max_bha);
	alienData[beta_shieldbug][max]	= GetConVarInt(horde_max_bsb);
	alienData[beta_drone][max]		= GetConVarInt(horde_max_bdr);
//min	
	alienData[drone][min]			= GetConVarInt(horde_min_dro);
	alienData[drone_jumper][min]	= GetConVarInt(horde_min_drj);
	alienData[drone_uber][min]		= GetConVarInt(horde_min_dru);
	alienData[parasite][min]		= GetConVarInt(horde_min_par);
	alienData[buzzer][min]			= GetConVarInt(horde_min_buz);
	alienData[ranger][min]			= GetConVarInt(horde_min_ran);
	alienData[shaman][min]			= GetConVarInt(horde_min_sha);
	alienData[harvester][min]		= GetConVarInt(horde_min_har);
	alienData[boomer][min]			= GetConVarInt(horde_min_boo);
	alienData[mortar][min]			= GetConVarInt(horde_min_mor);
	alienData[shieldbug][min]		= GetConVarInt(horde_min_shb);
	alienData[queen][min]			= GetConVarInt(horde_min_que);
	alienData[beta_harvester][min]	= GetConVarInt(horde_min_bha);
	alienData[beta_shieldbug][min]	= GetConVarInt(horde_min_bsb);
	alienData[beta_drone][min]		= GetConVarInt(horde_min_bdr);
}
setdrones()
{
	if (GetConVarInt(FindConVar("asw_drone_override_move")) != 1) { SetConVarInt(FindConVar("asw_drone_override_move"), 1); }
	if (GetConVarInt(FindConVar("asw_wanderer_override")) != 1) { SetConVarInt(FindConVar("asw_wanderer_override"), 1); }
	if (GetConVarInt(FindConVar("asw_drone_zig_zagging")) != 1) { SetConVarInt(FindConVar("asw_drone_zig_zagging"), 1); }
	
	new RandomHealth = GetRandomInt(GetConVarInt(drone_health_min),GetConVarInt(drone_health_max));
	new RandomSpeed = GetRandomInt(GetConVarInt(drone_yaw_speed_min),GetConVarInt(drone_yaw_speed_max));
	new attackspeed = GetRandomInt(GetConVarInt(drone_yaw_speed_attacking_min),GetConVarInt(drone_yaw_speed_attacking_max));
	new attackka = GetRandomInt(GetConVarInt(drone_yaw_speed_attackprep_min),GetConVarInt(drone_yaw_speed_attackprep_max));
		
	SetConVarInt(FindConVar("asw_drone_health"), RandomHealth);
	SetConVarInt(FindConVar("asw_drone_yaw_speed"), RandomSpeed);
	SetConVarInt(FindConVar("asw_drone_yaw_speed_attacking"), attackspeed);
	SetConVarInt(FindConVar("asw_drone_yaw_speed_attackprep"), attackka);
	
}
resetdrone()
{
	ResetConVar(FindConVar("asw_drone_health"), true, true);
	ResetConVar(FindConVar("asw_drone_yaw_speed"), true, true);
	ResetConVar(FindConVar("asw_drone_yaw_speed_attacking"), true, true);
	ResetConVar(FindConVar("asw_drone_yaw_speed_attackprep"), true, true);
	ResetConVar(FindConVar("asw_drone_override_move"), true, true);
	ResetConVar(FindConVar("asw_wanderer_override"), true, true);
	ResetConVar(FindConVar("asw_drone_zig_zagging"), true, true);
}