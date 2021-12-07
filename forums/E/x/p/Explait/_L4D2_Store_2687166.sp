





/*


___.           ___________              .__         .__  __   
\_ |__ ___.__. \_   _____/__  _________ |  | _____  |__|/  |_ 
 | __ <   |  |  |    __)_\  \/  /\____ \|  | \__  \ |  \   __\
 | \_\ \___  |  |        \>    < |  |_> >  |__/ __ \|  ||  |  
 |___  / ____| /_______  /__/\_ \|   __/|____(____  /__||__|  
     \/\/              \/      \/|__|             \/          


___.           ___________              .__         .__  __   
\_ |__ ___.__. \_   _____/__  _________ |  | _____  |__|/  |_ 
 | __ <   |  |  |    __)_\  \/  /\____ \|  | \__  \ |  \   __\
 | \_\ \___  |  |        \>    < |  |_> >  |__/ __ \|  ||  |  
 |___  / ____| /_______  /__/\_ \|   __/|____(____  /__||__|  
     \/\/              \/      \/|__|             \/          



___.           ___________              .__         .__  __   
\_ |__ ___.__. \_   _____/__  _________ |  | _____  |__|/  |_ 
 | __ <   |  |  |    __)_\  \/  /\____ \|  | \__  \ |  \   __\
 | \_\ \___  |  |        \>    < |  |_> >  |__/ __ \|  ||  |  
 |___  / ____| /_______  /__/\_ \|   __/|____(____  /__||__|  
     \/\/              \/      \/|__|             \/          



___.           ___________              .__         .__  __   
\_ |__ ___.__. \_   _____/__  _________ |  | _____  |__|/  |_ 
 | __ <   |  |  |    __)_\  \/  /\____ \|  | \__  \ |  \   __\
 | \_\ \___  |  |        \>    < |  |_> >  |__/ __ \|  ||  |  
 |___  / ____| /_______  /__/\_ \|   __/|____(____  /__||__|  
     \/\/              \/      \/|__|             \/          
*/





#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "Shop",
	author = "Explait",
	description = "Shop",
	version = "1.0",
	url = ""
}
new g_iCredits[MAXPLAYERS + 1]; // create a variable with client money
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY
/*///////////////////////////////////////////////////////////////
   ___ ___  _ __   __   ____ _ _ __ ___ 
  / __/ _ \| '_ \  \ \ / / _` | '__/ __|
 | (_| (_) | | | |  \ V / (_| | |  \__ \
  \___\___/|_| |_|   \_/ \__,_|_|  |___/
*/////////////////////////////////////////////////////////////////
new Handle:g_BoomerKilled = INVALID_HANDLE;                     //
new Handle:g_ChargerKilled = INVALID_HANDLE;                    //
new Handle:g_SmokerKilled = INVALID_HANDLE;                     //
new Handle:g_HunterKilled = INVALID_HANDLE;                     //
new Handle:g_JockeyKilled = INVALID_HANDLE;                     //
new Handle:g_SpitterKilled = INVALID_HANDLE;                    //
new Handle:g_TankKilled = INVALID_HANDLE;                       //
new Handle:g_WitchKilled = INVALID_HANDLE;                      //
new Handle:g_ZombieKilled = INVALID_HANDLE;                     //
//////////////////////////////////////////////////////////////////
public OnPluginStart()
{
	RegConsoleCmd("sm_shop", HinT);//shop command
	RegConsoleCmd("sm_pay", Pay);//pay command
	HookEvent("witch_killed", witch_killed);
	HookEvent("infected_death", infected_death);
	HookEvent("player_death", player_death);
	RegAdminCmd("sm_givemoney", GiveMoney, ADMFLAG_SLAY);
	HookEvent("tank_killed", tank_killed);
	//*****************//
	//  S E T T I N G S //
	//****************//
	g_BoomerKilled = CreateConVar("sm_boomkilled", "25", "Giving money for killing a boomer");
	g_ChargerKilled = CreateConVar("sm_chargerkilled", "50", "Giving money for killing a charger");
	g_SmokerKilled = CreateConVar("sm_smokerkilled", "45", "Giving money for killing a smoker");
	g_HunterKilled = CreateConVar("sm_hunterkilled", "45", "Giving money for killing a hunter");
	g_JockeyKilled = CreateConVar("sm_jockeykilled", "55", "Giving money for killing a jockey");
	g_SpitterKilled = CreateConVar("sm_spitterkilled", "50", "Giving money for killing a spitter");
	g_TankKilled = CreateConVar("sm_tankkilled", "500", "Giving money for killing a tank");
	g_WitchKilled = CreateConVar("sm_witchkilled", "250", "Giving money for killing a witch");
	g_ZombieKilled = CreateConVar("sm_zombiekilled", "2", "Giving money for killing a zombie");
}
/*///////////////////////////////////////////////////////////////
                       _       
                      | |      
   _____   _____ _ __ | |_ ___ 
  / _ \ \ / / _ \ '_ \| __/ __|
 |  __/\ V /  __/ | | | |_\__ \
  \___| \_/ \___|_| |_|\__|___/
*/////////////////////////////////////////////////////////////////
public Action GiveMoney(int client, int args) {
	char arg1[32], arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	int target = FindTarget(client, arg1);
	int money = 0;
	money = StringToInt(arg2);
	if (args != 2) {
		PrintToChat(client, "[shop] Usage: !givemoney <player> <money>");
	}
	g_iCredits[target] += money;
	char name[MAX_NAME_LENGTH];
	GetClientName(target, name, sizeof(name));
	PrintToChat(client, "[shop] You gave out %i to a %s", money, name);

}

public witch_killed(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new WitchKilled = GetConVarInt(g_WitchKilled);
	g_iCredits[client] += WitchKilled;
	PrintToChat(client, "[shop] You got %i for killing witch", WitchKilled);
}
public player_death(Handle:event, const String:name[], bool:dontBroadcast) {
	new BoomerKilled = GetConVarInt(g_BoomerKilled);// creating a con vars
	new ChargerKilled = GetConVarInt(g_ChargerKilled);
	new SmokerKilled = GetConVarInt(g_SmokerKilled);
	new HunterKilled = GetConVarInt(g_HunterKilled);
	new JockeyKilled = GetConVarInt(g_JockeyKilled);
	new SpitterKilled = GetConVarInt(g_SpitterKilled);
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl String:victimname[32];
	GetEventString(event, "victimname", victimname, sizeof(victimname));
	if (attacker != client) {
		if (strcmp(victimname, "boomer", false) == 0)// if killed a boomer add 50 credits
		{
			PrintToChat(attacker, "[shop] You got %i credits for killing the boomer", BoomerKilled);
			g_iCredits[attacker] += BoomerKilled;
		}
		if (strcmp(victimname, "smoker", false) == 0)
		{
			PrintToChat(attacker, "[shop] You got %i credits for killing the smoker", SmokerKilled);
			g_iCredits[attacker] += SmokerKilled;
		}
		if (strcmp(victimname, "charger", false) == 0)
		{
			PrintToChat(attacker, "[shop] You got %i credits for killing the charger", ChargerKilled);
			g_iCredits[attacker] += ChargerKilled;
		}
		if (strcmp(victimname, "hunter", false) == 0)
		{
			PrintToChat(attacker, "[shop] You got %i credits for killing the hunter", HunterKilled);
			g_iCredits[attacker] += HunterKilled;
		}
		if (strcmp(victimname, "jockey", false) == 0)
		{
			PrintToChat(attacker, "[shop] You got %i credits for killing the jockey", JockeyKilled);
			g_iCredits[attacker] += JockeyKilled;
		}
		if (strcmp(victimname, "spitter", false) == 0)
		{
			PrintToChat(attacker, "[shop] You got %i credits for killing the spitter", SpitterKilled);
			g_iCredits[attacker] += SpitterKilled;
		}
	}
}
public infected_death(Handle:event, const String:name[], bool:dontBroadcast) {
	new ZombieKilled = GetConVarInt(g_ZombieKilled);
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	g_iCredits[attacker] += ZombieKilled;
	PrintToChat(attacker, "[shop] You got %i credits for killing a zombie", ZombieKilled);
}

public tank_killed(Handle:event, const String:name[], bool:dontBroadcast) {
	new TankKilled = GetConVarInt(g_TankKilled);
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	PrintToChat(client, "[shop] You got %i credits for killing tank", TankKilled);
}

//////////////////////////////////////////////////////////////////



/*///////////////////////////////////////////////////////////////
   _____ _______ ____  _____  ______ 
  / ____|__   __/ __ \|  __ \|  ____|
 | (___    | | | |  | | |__) | |__   
  \___ \   | | | |  | |  _  /|  __|  
  ____) |  | | | |__| | | \ \| |____ 
 |_____/   |_|  \____/|_|  \_\______|
*/////////////////////////////////////////////////////////////////                                
                                     

public Action:HinT(client, args)
{

	new Handle:menu = CreateMenu(MeleeMenuHandler);
	SetMenuTitle(menu, "Your money is %d", g_iCredits[client]);

	AddMenuItem(menu, "option1", "Weapons");
	AddMenuItem(menu, "option2", "Melee");
	AddMenuItem(menu, "option3", "Other");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	SetMenuExitButton(menu, true);

	return Plugin_Handled;
}

public int MeleeMenuHandler(Handle:trollmenu, MenuAction:action, param1, param2)
{

	switch (action)
	{
		case MenuAction_Select:
		{
			new String:item[64];
			GetMenuItem(trollmenu, param2, item, sizeof(item))

			if (StrEqual(item, "option1"))
			{
				new Handle:menu = CreateMenu(Weapon_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
				SetMenuTitle(menu, "Weapons (Your credits: %i)", g_iCredits[param1]);

				AddMenuItem(menu, "option1", "Magnum Pistol - 75 credits");
				AddMenuItem(menu, "option2", "Automatic Shotgun - 200 credits");
				AddMenuItem(menu, "option3", "Sniper Rifle - 200 credits");
				AddMenuItem(menu, "option4", "SPAS Shotgun - 200 credits");
				AddMenuItem(menu, "option5", "Pump Shotgun - 150 credits");
				AddMenuItem(menu, "option6", "Chrome Shotgun - 130 credits");
				AddMenuItem(menu, "option7", "SMG - 125 credits");
				AddMenuItem(menu, "option8", "SMG (Silenced) - 130 credits");
				AddMenuItem(menu, "option9", "AK-47 - 250 credits");
				AddMenuItem(menu, "option10", "M16 - 255 credits");
				AddMenuItem(menu, "option11", "M60 - 500 credits");
				AddMenuItem(menu, "option12", "Hunting Rifle - 150 credits");
				AddMenuItem(menu, "option13", "Combat Rifle - 150 credits");
				AddMenuItem(menu, "option14", "Grenade Launcher - 250 credits");
				SetMenuExitButton(menu, true);

				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
			}
			if (StrEqual(item, "option2"))
			{
				new Handle:menu = CreateMenu(Melee_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
				SetMenuTitle(menu, "Melee (Your credits: %i)", g_iCredits[param1]);
				AddMenuItem(menu, "option1", "Chainsaw - 150 credits");
				AddMenuItem(menu, "option2", "Katana - 150 credits");
				AddMenuItem(menu, "option3", "Machete - 150 credits");
				AddMenuItem(menu, "option4", "Nightstick - 150 credits");
				AddMenuItem(menu, "option5", "Guitar - 150 credits");
				SetMenuExitButton(menu, true);

				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
			}
			if (StrEqual(item, "option3"))
			{
				new Handle:menu = CreateMenu(Other_Menu_Handle, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
				SetMenuTitle(menu, "Other (Your credits: %i)", g_iCredits[param1]);
				AddMenuItem(menu, "option1", "Defibrilator - 100");
				AddMenuItem(menu, "option2", "Aid Kit - 50 credits");
				AddMenuItem(menu, "option3", "Adrenaline - 30 credits");
				AddMenuItem(menu, "option4", "Pain Pills - 25 credits");
				AddMenuItem(menu, "option5", "Refill Health - 300 credits");
				AddMenuItem(menu, "option6", "Ammunition - 100 credits");
				AddMenuItem(menu, "option7", "Pipe Bomb - 45 credits");
				AddMenuItem(menu, "option8", "Molotov - 55 credits");
				AddMenuItem(menu, "option9", "Boomer Bile - 60 credits");
				SetMenuExitButton(menu, true);

				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
			}
		}

	}
}
//////////////////////////////////////////////////////////////////




public Action:Pay(client, args) {
	char arg1[32], arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	int paymoney = 0;
	paymoney = StringToInt(arg2);
	int target = FindTarget(client, arg1);
	if (target == -1) {
		return Plugin_Handled;
	}
	if (args != 2) {
		ReplyToCommand(client, "[shop] usage: !pay <name> <money>");
	}
	g_iCredits[target] += paymoney;
	g_iCredits[client] -= paymoney;
	PrintToChat(target, "[shop] %s gave you %i credits", client, paymoney);
	PrintToChat(client, "[shop] thanks for pay!: %i credits", paymoney)
	return Plugin_Handled;
}

/*/////////////////////////////////////////////////////////////////
  _____ _______ ______ __  __  _____ 
 |_   _|__   __|  ____|  \/  |/ ____|
   | |    | |  | |__  | \  / | (___  
   | |    | |  |  __| | |\/| |\___ \ 
  _| |_   | |  | |____| |  | |____) |
 |_____|  |_|  |______|_|  |_|_____/ 
                                     
                                     
*//////////////////////////////////////////////////////////////////



public Weapon_Menu_Handle(Menu menu, MenuAction action, int client, int Position)
{
	new flagszspawn = GetCommandFlags("give");
	SetCommandFlags("give", flagszspawn & ~FCVAR_CHEAT);
	char Item[32];
	menu.GetItem(Position, Item, sizeof(Item));
	menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	if (action == MenuAction_Select) {
		if (StrEqual(Item, "option1"))
		{
			if (g_iCredits[client] >= 75) {
				FakeClientCommand(client, "give pistol_magnum");
				g_iCredits[client] -= 75;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 75", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option2"))
		{
			if (g_iCredits[client] >= 200) {
				FakeClientCommand(client, "give autoshotgun");
				g_iCredits[client] -= 200;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 200", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option3"))
		{
			if (g_iCredits[client] >= 200) {
				FakeClientCommand(client, "give sniper_military");
				g_iCredits[client] -= 200;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 200", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option4"))
		{
			if (g_iCredits[client] >= 200) {
				FakeClientCommand(client, "give shotgun_spas");
				g_iCredits[client] -= 200;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 200", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option5"))
		{
			if (g_iCredits[client] >= 150) {
				FakeClientCommand(client, "give pumpshotgun");
				g_iCredits[client] -= 150;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 150", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option6"))
		{
			if (g_iCredits[client] >= 130) {
				FakeClientCommand(client, "give shotgun_chrome");
				g_iCredits[client] -= 130;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 130", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option7"))
		{
			if (g_iCredits[client] >= 125) {
				FakeClientCommand(client, "give smg");
				g_iCredits[client] -= 125;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 125", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option8"))
		{
			if (g_iCredits[client] >= 130) {
				FakeClientCommand(client, "give smg_silenced");
				g_iCredits[client] -= 130;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 130", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option9"))
		{
			if (g_iCredits[client] >= 250) {
				FakeClientCommand(client, "give rifle_ak47");
				g_iCredits[client] -= 250;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 250", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option10"))
		{
			if (g_iCredits[client] >= 255) {
				FakeClientCommand(client, "give rifle");
				g_iCredits[client] -= 255;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 255", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option11"))
		{
			if (g_iCredits[client] >= 500) {
				FakeClientCommand(client, "give rifle_m60");
				g_iCredits[client] -= 500;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 500", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option12"))
		{
			if (g_iCredits[client] >= 150) {
				FakeClientCommand(client, "give hunting_rifle");
				g_iCredits[client] -= 150;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 150", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option13"))
		{
			if (g_iCredits[client] >= 150) {
				FakeClientCommand(client, "give rifle_desert");
				g_iCredits[client] -= 150;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 150", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option14"))
		{
			if (g_iCredits[client] >= 250) {
				FakeClientCommand(client, "give weapon_grenade_launcher");
				g_iCredits[client] -= 250;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 250", g_iCredits[client]);
			}
		}
	}
	SetCommandFlags("give", flagszspawn | FCVAR_CHEAT);
}





public Melee_Menu_Handle(Menu menu, MenuAction action, int client, int Position)
{
	new flagszspawn = GetCommandFlags("give");
	SetCommandFlags("give", flagszspawn & ~FCVAR_CHEAT);
	char Item[32];
	menu.GetItem(Position, Item, sizeof(Item));
	menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	if (action == MenuAction_Select) {
		if (StrEqual(Item, "option1"))
		{
			if (g_iCredits[client] >= 150) {
				FakeClientCommand(client, "give chainsaw");
				g_iCredits[client] -= 150;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 150", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option2"))
		{
			if (g_iCredits[client] >= 150) {
				FakeClientCommand(client, "give katana");
				g_iCredits[client] -= 150;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 150", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option3"))
		{
			if (g_iCredits[client] >= 150) {
				FakeClientCommand(client, "give machete");
				g_iCredits[client] -= 150;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 150", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option4"))
		{
			if (g_iCredits[client] >= 150) {
				FakeClientCommand(client, "give tonfa");
				g_iCredits[client] -= 150;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 150", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option5"))
		{
			if (g_iCredits[client] >= 150) {
				FakeClientCommand(client, "give electric_guitar");
				g_iCredits[client] -= 150;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 150", g_iCredits[client]);
			}
		}
	}
	SetCommandFlags("give", flagszspawn | FCVAR_CHEAT);
}








public Other_Menu_Handle(Menu menu, MenuAction action, int client, int Position)
{
	new flagszspawn = GetCommandFlags("give");
	SetCommandFlags("give", flagszspawn & ~FCVAR_CHEAT);

	char Item[32];
	menu.GetItem(Position, Item, sizeof(Item));
	menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	if (action == MenuAction_Select) {
		if (StrEqual(Item, "option1"))
		{
			if (g_iCredits[client] >= 100) {
				FakeClientCommand(client, "give defibrillator");
				g_iCredits[client] -= 100;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 100", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option2"))
		{
			if (g_iCredits[client] >= 50) {
				FakeClientCommand(client, "give first_aid_kit");
				g_iCredits[client] -= 50;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 50", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option3"))
		{
			if (g_iCredits[client] >= 30) {
				FakeClientCommand(client, "give adrenaline");
				g_iCredits[client] -= 30;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 30", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option3"))
		{
			if (g_iCredits[client] >= 30) {
				FakeClientCommand(client, "give adrenaline");
				g_iCredits[client] -= 30;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 30", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option4"))
		{
			if (g_iCredits[client] >= 25) {
				FakeClientCommand(client, "give pain_pills");
				g_iCredits[client] -= 25;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 25", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option5"))
		{
			if (g_iCredits[client] >= 300) {
				FakeClientCommand(client, "give health");
				g_iCredits[client] -= 300;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 300", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option6"))
		{
			if (g_iCredits[client] >= 100) {
				FakeClientCommand(client, "give ammo");
				g_iCredits[client] -= 100;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 100", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option7"))
		{
			if (g_iCredits[client] >= 45) {
				FakeClientCommand(client, "give pipe_bomb");
				g_iCredits[client] -= 45;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 45", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option8"))
		{
			if (g_iCredits[client] >= 55) {
				FakeClientCommand(client, "give molotov");
				g_iCredits[client] -= 55;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 55", g_iCredits[client]);
			}
		}
		if (StrEqual(Item, "option9"))
		{
			if (g_iCredits[client] >= 60) {
				FakeClientCommand(client, "give vomitjar");
				g_iCredits[client] -= 60;
			}
			else {
				PrintToChat(client, "[shop] Your credits: %i (Not have enough credit! Need 60", g_iCredits[client]);
			}
		}
	}
	SetCommandFlags("give", flagszspawn | FCVAR_CHEAT);
}
//////////////////////////////////////////////////////////////////




