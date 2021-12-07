#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_NAME "Vocalize[L4D]"

#include <sourcemod>
#include <sdktools>
public Plugin:myinfo = 
{
    name = PLUGIN_NAME,
    author = "HateMeh",
    description = "Shows a menu with vocalize commands",
    version = PLUGIN_VERSION,
    url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("sm_vocalize_general", general);
	RegConsoleCmd("sm_vocalize_zoey", zoey);
	RegConsoleCmd("sm_vocalize_bill", bill);
	RegConsoleCmd("sm_vocalize_francis", francis);
	RegConsoleCmd("sm_vocalize_louis", louis);
	RegConsoleCmd("sm_vocalize", test);
}
//general vocalize
public MenuHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(param1, "vocalize %s", info);
	}
	/* If the menu has ended, destroy it 
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	*/
}
 
public Action:general(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler1);
	SetMenuTitle(menu, "Vocalize");
	AddMenuItem(menu, "Playerdeath", "Playerdeath");
	AddMenuItem(menu, "EatPills", "EatPills");
	AddMenuItem(menu, "elevator_conversation", "elevator_conversation")
	AddMenuItem(menu, "EmphaticArriveRun", "EmphaticArriveRun")
	AddMenuItem(menu, "PlayerAlertGiveItem", "PlayerAlertGiveItem")
	AddMenuItem(menu, "PlayerChoke", "PlayerChoke")
	AddMenuItem(menu, "PlayerFollowMe", "PlayerFollowMe")
	AddMenuItem(menu, "PlayerFriendlyFire", "PlayerFriendlyFire")
	AddMenuItem(menu, "PlayerHealing", "PlayerHealing")
	AddMenuItem(menu, "PlayerHealingOther", "PlayerHealingOther")
	AddMenuItem(menu, "PlayerIncapacitated", "PlayerIncapacitated")
	AddMenuItem(menu, "PlayerIncoming", "PlayerIncoming")
	AddMenuItem(menu, "PlayerKillThatLight", "PlayerKillThatLight")
	AddMenuItem(menu, "PlayerLedgeHangEnd", "PlayerLedgeHangEnd")
	AddMenuItem(menu, "PlayerLedgeHangMiddle", "PlayerLedgeHangMiddle")
	AddMenuItem(menu, "PlayerLedgeHangStart", "PlayerLedgeHangStart")
	AddMenuItem(menu, "PlayerLedgeSave", "PlayerLedgeSave")
	AddMenuItem(menu, "PlayerLedgeSaveCritical", "PlayerLedgeSaveCritical")
	AddMenuItem(menu, "PlayerLookOut", "PlayerLookOut")
	AddMenuItem(menu, "PlayerNegative", "PlayerNegative")
	AddMenuItem(menu, "PlayerNiceShot", "PlayerNiceShot")
	AddMenuItem(menu, "PlayerReviveFriend", "PlayerReviveFriend")
	AddMenuItem(menu, "PlayerSpotAmmo", "PlayerSpotAmmo")
	AddMenuItem(menu, "PlayerSpotFirstAid", "PlayerSpotFirstAid")
	AddMenuItem(menu, "PlayerSpotGrenade", "PlayerSpotGrenade")
	AddMenuItem(menu, "PlayerSpotPills", "PlayerSpotPills")
	AddMenuItem(menu, "PlayerStayTogether", "PlayerStayTogether")
	AddMenuItem(menu, "PlayerTaunt", "PlayerTaunt")
	AddMenuItem(menu, "PlayerVomitInFace", "PlayerVomitInFace")
	AddMenuItem(menu, "PlayerWarnBoomer", "PlayerWarnBoomer")
	AddMenuItem(menu, "PlayerWarnHunter", "PlayerWarnHunter")
	AddMenuItem(menu, "PlayerWarnSmoker", "PlayerWarnSmoker")
	AddMenuItem(menu, "PlayerWarnWitch", "PlayerWarnWitch")
	AddMenuItem(menu, "PlayerWatchOutBehind", "PlayerWatchOutBehind")
	AddMenuItem(menu, "PlayerYouAreWelcome", "PlayerYouAreWelcome")
	AddMenuItem(menu, "ResponseSoftDispleasureSwear", "ResponseSoftDispleasureSwear")
	AddMenuItem(menu, "ReviveMeInterrupted", "ReviveMeInterrupted")
	AddMenuItem(menu, "ScenarioJoin", "ScenarioJoin")
	AddMenuItem(menu, "YouWelcome", "YouWelcome")
	AddMenuItem(menu, "ReviveMeInterrupted", "ReviveMeInterrupted")
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
 
	return Plugin_Handled;
}


//Choose menu
public MenuHandler2(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(param1, "sm_vocalize_%s", info);
	}
	/* If the menu has ended, destroy it 
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	*/
}
public Action:test(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler2);
	SetMenuTitle(menu, "Vocalize");
	AddMenuItem(menu, "general", "general");
	AddMenuItem(menu, "louis", "Louis");
	AddMenuItem(menu, "zoey", "Zoey");
	AddMenuItem(menu, "bill", "Bill");
	AddMenuItem(menu, "francis", "Francis");
		SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
 
	return Plugin_Handled;
}

//louis
public MenuHandler3(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(param1, "vocalize %s", info);
	}
	/* If the menu has ended, destroy it 
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	*/
}
public Action:louis(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler3);
	SetMenuTitle(menu, "Vocalize");
	AddMenuItem(menu, "Airport04_05a", "Airport04_05a");
	AddMenuItem(menu, "Airport04_08b", "Airport04_08b");
	AddMenuItem(menu, "smalltown02_path08a", "smalltown02_path08a");
	AddMenuItem(menu, "Smalltown04_path07A", "Smalltown04_path07A");
	AddMenuItem(menu, "smalltown02_path01b", "smalltown02_path01b");
	AddMenuItem(menu, "Farm01_path03a", "Farm01_path03a");
	AddMenuItem(menu, "Farm03_path01a", "Farm03_path01a");
	AddMenuItem(menu, "IntroFarm4", "IntroFarm4");
	AddMenuItem(menu, "IntroHospital", "IntroHospital");
	AddMenuItem(menu, "hospital02_path03a1", "hospital02_path03a1");
	AddMenuItem(menu, "hospital03_path03a1", "hospital03_path03a1");
	AddMenuItem(menu, "hospital04_path02a", "hospital04_path02a");
	AddMenuItem(menu, "hospital04_path04a", "hospital04_path04a");
	AddMenuItem(menu, "hospital05_path01b", "hospital05_path01b");
	AddMenuItem(menu, "RiversideIsDead", "RiversideIsDead");
	AddMenuItem(menu, "RiversideIsDeadB", "RiversideIsDeadB");
	AddMenuItem(menu, "ampiresBeata", "VampiresBeata");
	AddMenuItem(menu, "TakeShotgunGroovyLouis", "TakeShotgunGroovyLouis");
	AddMenuItem(menu, "TrainUnhookedManager", "TrainUnhookedManager");
	AddMenuItem(menu, "PlaneCrashResponse", "PlaneCrashResponse");
	AddMenuItem(menu, "PlayerTransition", "PlayerTransition");
	AddMenuItem(menu, "ResponseSoftDispleasureSwear", "ResponseSoftDispleasureSwear");
	AddMenuItem(menu, "ConceptBlock015", "ConceptBlock015");
	AddMenuItem(menu, "ConceptBlock017", "ConceptBlock017");
	AddMenuItem(menu, "ConceptBlock019", "ConceptBlock019");
	AddMenuItem(menu, "ConceptBlock050", "ConceptBlock050");
	AddMenuItem(menu, "ConceptBlock581", "ConceptBlock581");
	AddMenuItem(menu, "ConceptBlock594", "ConceptBlock594");
	AddMenuItem(menu, "ConceptBlock610", "ConceptBlock610");
	AddMenuItem(menu, "ConceptBlock619", "ConceptBlock619");
	AddMenuItem(menu, "ConceptBlock628", "ConceptBlock628");
	AddMenuItem(menu, "ConceptBlock645", "ConceptBlock645");
	AddMenuItem(menu, "ConceptBlock650", "ConceptBlock650");
	AddMenuItem(menu, "ConceptBlock652", "ConceptBlock652");
	AddMenuItem(menu, "ConceptBlock656", "ConceptBlock656");
	AddMenuItem(menu, "ConceptBlock658", "ConceptBlock658");
	AddMenuItem(menu, "ConceptBlock659", "ConceptBlock659");
	AddMenuItem(menu, "ConceptBlock660", "ConceptBlock660");
	AddMenuItem(menu, "ConceptBlock669", "ConceptBlock669");
	AddMenuItem(menu, "ConceptBlock702", "ConceptBlock702");
	AddMenuItem(menu, "ConceptBlock705", "ConceptBlock705");
		SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
 
	return Plugin_Handled;
}

//francis


public MenuHandler4(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(param1, "vocalize %s", info);
	}
	/* If the menu has ended, destroy it 
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	*/
}
public Action:francis(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler4);
	SetMenuTitle(menu, "Vocalize");
	AddMenuItem(menu, "irport04_08a", "Airport04_08a");
	AddMenuItem(menu, "Airport04_08b", "Airport04_08b");
	AddMenuItem(menu, "Farm05_path09c", "Farm05_path09c");
	AddMenuItem(menu, "airport04_vana", "airport04_vana");
	AddMenuItem(menu, "IntroHospital02", "IntroHospital02");
	AddMenuItem(menu, "Smalltown05_path03a", "Smalltown05_path03a");
	AddMenuItem(menu, "Smalltown02_path01a", "Smalltown02_path01a");
	AddMenuItem(menu, "Smalltown04_path05a", "Smalltown04_path05a");
	AddMenuItem(menu, "RiversideIsDeadSpecialA", "RiversideIsDeadSpecialA");
	AddMenuItem(menu, "IntroAirport01bc", "IntroAirport01bc");
	AddMenuItem(menu, "AynRandResponse", "AynRandResponse");
	AddMenuItem(menu, "ConceptBlock009", "ConceptBlock009");
	AddMenuItem(menu, "ConceptBlock023", "ConceptBlock023");
	AddMenuItem(menu, "ConceptBlock040", "ConceptBlock040");
	AddMenuItem(menu, "ConceptBlock044", "ConceptBlock044");
	AddMenuItem(menu, "ConceptBlock049", "ConceptBlock049");
	AddMenuItem(menu, "ConceptBlock517", "ConceptBlock517");
	AddMenuItem(menu, "ConceptBlock527", "ConceptBlock527");
	AddMenuItem(menu, "ConceptBlock537", "ConceptBlock537");
	AddMenuItem(menu, "ConceptBlock558", "ConceptBlock558");
	AddMenuItem(menu, "ConceptBlock596", "ConceptBlock596");
	AddMenuItem(menu, "ConceptBlock607", "ConceptBlock607");
	AddMenuItem(menu, "ConceptBlock627", "ConceptBlock627");
	AddMenuItem(menu, "ConceptBlock629", "ConceptBlock629");
	AddMenuItem(menu, "ConceptBlock632", "ConceptBlock632");
	AddMenuItem(menu, "ConceptBlock633", "ConceptBlock633");
	AddMenuItem(menu, "ConceptBlock635", "ConceptBlock635");
	AddMenuItem(menu, "ConceptBlock637", "ConceptBlock637");
	AddMenuItem(menu, "ConceptBlock697", "ConceptBlock697");
	AddMenuItem(menu, "ConceptBlock709", "ConceptBlock709");
	AddMenuItem(menu, "ConceptBlock710", "ConceptBlock710");
	AddMenuItem(menu, "ConceptBlock712", "ConceptBlock712");
	AddMenuItem(menu, "ConceptBlock721", "ConceptBlock721");
	
		SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
 
	return Plugin_Handled;
}

//zoey

public MenuHandler5(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(param1, "vocalize %s", info);
	}
	/* If the menu has ended, destroy it 
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	*/
}
public Action:zoey(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler5);
	SetMenuTitle(menu, "Vocalize");
	AddMenuItem(menu, "Airport04_08c", "Airport04_08c");
	AddMenuItem(menu, "BounceReaction", "BounceReaction");
	AddMenuItem(menu, "IntroFarm4", "IntroFarm4");
	AddMenuItem(menu, "IntroSmallTown2", "IntroSmallTown2");
	AddMenuItem(menu, "TakeShotgunZoey", "TakeShotgunZoey");
	AddMenuItem(menu, "ConceptBlock032", "ConceptBlock032");
	AddMenuItem(menu, "ConceptBlock035", "ConceptBlock035");
	AddMenuItem(menu, "ConceptBlock037", "ConceptBlock037");
	AddMenuItem(menu, "ConceptBlock620", "ConceptBlock620");
	AddMenuItem(menu, "ConceptBlock642", "ConceptBlock642");
	AddMenuItem(menu, "ConceptBlock647", "ConceptBlock647");
	AddMenuItem(menu, "ConceptBlock649", "ConceptBlock649");
	AddMenuItem(menu, "vConceptBlock654", "ConceptBlock654");
	AddMenuItem(menu, "ConceptBlock657", "ConceptBlock657");
	AddMenuItem(menu, "ConceptBlock661", "ConceptBlock661");
		SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
 
	return Plugin_Handled;
}


//bill


public MenuHandler6(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(param1, "vocalize %s", info);
	}
	/* If the menu has ended, destroy it 
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	*/
}
public Action:bill(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler6);
	SetMenuTitle(menu, "Vocalize");
	AddMenuItem(menu, "Airport04_08a", "Airport04_08a");
	AddMenuItem(menu, "Airport04_08c", "Airport04_08c");
	AddMenuItem(menu, "DontBeAnAss", "DontBeAnAss");
	AddMenuItem(menu, "Farm02_path01a", "Farm02_path01a");
	AddMenuItem(menu, "Farm05_path07b", "Farm05_path07b");
	AddMenuItem(menu, "Farm05_path09c", "Farm05_path09c");
	AddMenuItem(menu, "FarmvampiresB", "FarmvampiresB");
	AddMenuItem(menu, "Hospital02_path03b1", "Hospital02_path03b1");
	AddMenuItem(menu, "Hospital02_path03c1", "Hospital02_path03c1");
	AddMenuItem(menu, "Hospital04_path01a", "Hospital04_path01a");
	AddMenuItem(menu, "IntroFarm3", "IntroFarm3");
	AddMenuItem(menu, "IntroFarm4", "IntroFarm4");
	AddMenuItem(menu, "IntroHospital", "IntroHospital");
	AddMenuItem(menu, "IntroHospital03", "IntroHospital03");
	AddMenuItem(menu, "ConceptBlock608", "ConceptBlock608");
	AddMenuItem(menu, "ConceptBlock639", "ConceptBlock639");
	AddMenuItem(menu, "ConceptBlock051", "ConceptBlock051");
	AddMenuItem(menu, "ConceptBlock515", "ConceptBlock515");
	AddMenuItem(menu, "ConceptBlock536", "ConceptBlock536");
	AddMenuItem(menu, "ConceptBlock556", "ConceptBlock556");
	AddMenuItem(menu, "ConceptBlock611", "ConceptBlock611");
	AddMenuItem(menu, "ConceptBlock663", "ConceptBlock663");
	AddMenuItem(menu, "ConceptBlock696", "ConceptBlock696");
	AddMenuItem(menu, "ConceptBlock712", "ConceptBlock712");
	AddMenuItem(menu, "ConceptBlock715", "ConceptBlock715");
		SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
 
	return Plugin_Handled;
}




