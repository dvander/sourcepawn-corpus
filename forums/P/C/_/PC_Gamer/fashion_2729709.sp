#include <sourcemod>
#include <tf2_stocks>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1"

Handle g_hEquipWearable;
Handle g_hFashionItems[5] = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "Fashion",
	author = "PC Gamer",
	description = "fashion - Choose a wearable outfit",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public void OnPluginStart() 
{
	RegConsoleCmd("sm_fashion", fashion_Mode);

	GameData hTF2 = new GameData("sm-tf2.games"); // sourcemod's tf2 gamdata

	if (!hTF2)
		SetFailState("This plugin is designed for a TF2 dedicated server only.");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(hTF2.GetOffset("RemoveWearable") - 1);    // EquipWearable offset is always behind RemoveWearable, subtract its value by 1
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hEquipWearable = EndPrepSDKCall();

	if (!g_hEquipWearable)
		SetFailState("Failed to create call: CBasePlayer::EquipWearable");

	delete hTF2;  

	g_hFashionItems[0] = RegClientCookie("fashion_item1", "", CookieAccess_Private);
	g_hFashionItems[1] = RegClientCookie("fashion_item2", "", CookieAccess_Private);	
	g_hFashionItems[2] = RegClientCookie("fashion_item3", "", CookieAccess_Private);
	g_hFashionItems[3] = RegClientCookie("fashion_item4", "", CookieAccess_Private);
	g_hFashionItems[4] = RegClientCookie("fashion_item5", "", CookieAccess_Private);

	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);	
	HookEvent("player_changeclass", EventChangeClass, EventHookMode_Post);	
}

public Action fashion_Mode(int client, int args)
{
	Menu_fashion(client);
	return Plugin_Handled;
}

public Action Menu_fashion(int client)
{
	Handle menu = CreateMenu(FMenu, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	SetMenuTitle(menu, "Fashion Menu");

	AddMenuItem(menu, "99999", "Remove Items");

	if (TF2_GetPlayerClass(client) == TFClass_Heavy)
	{	
		AddMenuItem(menu, "70008", "Heavy - FrakenHeavy");
		AddMenuItem(menu, "70009", "Heavy - Grand Duchess");
		AddMenuItem(menu, "70010", "Heavy - Minsk Beast");
		AddMenuItem(menu, "70011", "Heavy - Yeti");
		AddMenuItem(menu, "70034", "Heavy - Beach Bum");
		AddMenuItem(menu, "70072", "Heavy - Chicken Kiev");
		AddMenuItem(menu, "70078", "Heavy - Tsar Platinum");
		AddMenuItem(menu, "70096", "Heavy - Mediterranean Mercenary");
		AddMenuItem(menu, "70106", "Heavy - Convict Hat");
		AddMenuItem(menu, "70118", "Heavy - Pajamas");		
	}
	if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{	
		AddMenuItem(menu, "70012", "Demoman - Highland Hound");	
		AddMenuItem(menu, "70030", "Demoman - South of the Border");
		AddMenuItem(menu, "70031", "Demoman - Cursed Captain");
		AddMenuItem(menu, "70032", "Demoman - Count Tavish");
		AddMenuItem(menu, "70033", "Demoman - Forgotten King");
		AddMenuItem(menu, "70076", "Demoman - Antarctic Eyewear");	
		AddMenuItem(menu, "70077", "Demoman - Frag Proof Fragger");	
		AddMenuItem(menu, "70095", "Demoman - Backbreaker");
		AddMenuItem(menu, "70113", "Demoman - Samurai");
	}
	if (TF2_GetPlayerClass(client) == TFClass_Soldier)
	{	
		AddMenuItem(menu, "70013", "Soldier - Tin Soldier");		
		AddMenuItem(menu, "70014", "Soldier - Federal Express");
		AddMenuItem(menu, "70035", "Soldier - Colonial");
		AddMenuItem(menu, "70036", "Soldier - Lone Warrior");	
		AddMenuItem(menu, "70068", "Soldier - Knight");	
		AddMenuItem(menu, "70069", "Soldier - Battle Bird");
		AddMenuItem(menu, "70070", "Soldier - Skullcap");
		AddMenuItem(menu, "70074", "Soldier - High Sky Fly Guy");
		AddMenuItem(menu, "70092", "Soldier - Dancing Doe");
		AddMenuItem(menu, "70093", "Soldier - Peacebreaker");
		AddMenuItem(menu, "70101", "Soldier - El Zapateador");
		AddMenuItem(menu, "70102", "Soldier - Racc Mann	");	
	}
	if (TF2_GetPlayerClass(client) == TFClass_Scout)
	{	
		AddMenuItem(menu, "70015", "Scout - Wicked Good Ninja");
		AddMenuItem(menu, "70016", "Scout - Deep Fried Dummy");	
		AddMenuItem(menu, "70017", "Scout - Isolationist");
		AddMenuItem(menu, "70018", "Scout - Rooftop Rebel");
		AddMenuItem(menu, "70019", "Scout - Curse-a-Nature");
		AddMenuItem(menu, "70020", "Scout - Boston Bulldog");
		AddMenuItem(menu, "70021", "Scout - Super Sidekick");
		AddMenuItem(menu, "70022", "Scout - Super Speedster");
		AddMenuItem(menu, "70073", "Scout - Beach Bum");
		AddMenuItem(menu, "70076", "Scout - Antarctic Eyewear");
		AddMenuItem(menu, "70081", "Scout - Punks Pomp");
		AddMenuItem(menu, "70086", "Scout - Athenian Attire");
		AddMenuItem(menu, "70090", "Scout - Bottlecap");
		AddMenuItem(menu, "70091", "Scout - Speedy Scoundrel");
		AddMenuItem(menu, "70100", "Scout - Remorseless Raptor");
		AddMenuItem(menu, "70117", "Scout - California Cap");		
	}
	if (TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		AddMenuItem(menu, "70023", "Pyro - Dr Grordborts Moonman");
		AddMenuItem(menu, "70024", "Pyro - Sons of Arsonry");	
		AddMenuItem(menu, "70025", "Pyro - Ronin Roaster");
		AddMenuItem(menu, "70026", "Pyro - Fast Food Firestarter");	
		AddMenuItem(menu, "70027", "Pyro - Infernal Imp");
		AddMenuItem(menu, "70028", "Pyro - Burny the Pyrosaur");
		AddMenuItem(menu, "70029", "Pyro - Murky Lurker");
		AddMenuItem(menu, "70037", "Pyro - Hovering Hotshot");
		AddMenuItem(menu, "70038", "Pyro - Centurion");
		AddMenuItem(menu, "70071", "Pyro - Sight for Sore Eyes");
		AddMenuItem(menu, "70079", "Pyro - Burning Question and Hot Case");
		AddMenuItem(menu, "70084", "Pyro - Brigade Helm and Tricksters Turnout Gear");
		AddMenuItem(menu, "70094", "Pyro - Melted Mop");
		AddMenuItem(menu, "70103", "Pyro - Pyro Shark");
		AddMenuItem(menu, "70114", "Pyro - Pyro Shark 2");
		AddMenuItem(menu, "70104", "Pyro - Candy Cranium");
		AddMenuItem(menu, "70105", "Pyro - Pyrolantern");
	}
	if (TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		AddMenuItem(menu, "70039", "Sniper - Camouflage");
		AddMenuItem(menu, "70040", "Sniper - Marsupial Man");
		AddMenuItem(menu, "70041", "Sniper - Mangaroo");
		AddMenuItem(menu, "70042", "Sniper - Sir Shootsalot");	
		AddMenuItem(menu, "70043", "Sniper - Camper Van Helsing");
		AddMenuItem(menu, "70044", "Sniper - Corona Australis");
		AddMenuItem(menu, "70045", "Sniper - Archer");
		AddMenuItem(menu, "70076", "Sniper - Antarctic Eyewear");
		AddMenuItem(menu, "70087", "Sniper - Crocodile Mun-Dee");
		AddMenuItem(menu, "70089", "Sniper - Ol Snaggletooth");
		AddMenuItem(menu, "70097", "Sniper - Bare Necessities");
		AddMenuItem(menu, "70110", "Sniper - Elizabeth the Third");	
	}
	if (TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		AddMenuItem(menu, "70046", "Spy - Gravelpit Emperor");	
		AddMenuItem(menu, "70047", "Spy - Invisible Rogue");
		AddMenuItem(menu, "70048", "Spy - Automatic Pilot");
		AddMenuItem(menu, "70049", "Spy - Aloha Apparel");
		AddMenuItem(menu, "70050", "Spy - Big Topper");
		AddMenuItem(menu, "70051", "Spy - Ethereal Hood");
		AddMenuItem(menu, "70052", "Spy - Fowl Cowl");
		AddMenuItem(menu, "70080", "Spy - Assassins Attire and Aristotle");
		AddMenuItem(menu, "70088", "Spy - Murderers Motiff");
		AddMenuItem(menu, "70098", "Spy - Shutterbug");
		AddMenuItem(menu, "70111", "Spy - Avian Amante");
		AddMenuItem(menu, "70112", "Spy - Voodoo Vizier");
		AddMenuItem(menu, "70116", "Spy - Crabe de Chapeau");		
	}
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{		
		AddMenuItem(menu, "70053", "Medic - Dr Gogglestache");	
		AddMenuItem(menu, "70054", "Medic - Private Eye");
		AddMenuItem(menu, "70055", "Medic - Coldfront Commander");
		AddMenuItem(menu, "70056", "Medic - Burly Beast");	
		AddMenuItem(menu, "70057", "Medic - Templars Spirit");
		AddMenuItem(menu, "70058", "Medic - Teutonkahmun");	
		AddMenuItem(menu, "70059", "Medic - Hundkopf");	
		AddMenuItem(menu, "70060", "Medic - Transylvanian Toupe");
		AddMenuItem(menu, "70061", "Medic - Holiday Medic");
		AddMenuItem(menu, "70083", "Medic - Scourge of the Sky");
		AddMenuItem(menu, "70109", "Medic - Madmanns Muzzle");
		AddMenuItem(menu, "70119", "Medic - Elf Care Provider");			
	}
	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		AddMenuItem(menu, "70062", "Engineer - Buzz Killer");
		AddMenuItem(menu, "70063", "Engineer - Braniac");
		AddMenuItem(menu, "70064", "Engineer - Texas");
		AddMenuItem(menu, "70065", "Engineer - Beep Man");	
		AddMenuItem(menu, "70066", "Engineer - Aloha Apparel");	
		AddMenuItem(menu, "70067", "Engineer - Frizz");
		AddMenuItem(menu, "70076", "Engineer - Antarctic Eyewear");	
		AddMenuItem(menu, "70082", "Engineer - Cold Case");
		AddMenuItem(menu, "70107", "Engineer - El Mostacho");
		AddMenuItem(menu, "70108", "Engineer - Eingineer");
	}

	AddMenuItem(menu, "70120", "Covid Mask");	
	AddMenuItem(menu, "70001", "Batman");
	AddMenuItem(menu, "70002", "Saxton Outfit");
	AddMenuItem(menu, "125", "Cheater's Lament");
	AddMenuItem(menu, "126", "Bill's Hat");
	AddMenuItem(menu, "70005", "Pyrovision Goggles");
	AddMenuItem(menu, "162", "Max's Severed Head");
	AddMenuItem(menu, "30643", "Banana Head");	
	AddMenuItem(menu, "30669", "Phononaut and Space Hamster Hammy");
	AddMenuItem(menu, "70075", "Tundra Top and Robin Walkers");
	AddMenuItem(menu, "70085", "Heart of Gold/Gifting Hat/Robin Walkers");	
	AddMenuItem(menu, "70099", "Bat Hat/Binoculus/Pocket Halloween Boss");
	AddMenuItem(menu, "70115", "Breadcrab and Loaf Loafers");	
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int FMenu(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			//param1 is client, param2 is item

			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));

			if (StrEqual(item, "99999"))
			{
				TF2_RemoveCosmetics(param1);

				SetClientCookie(param1, g_hFashionItems[0], "-1");		
				SetClientCookie(param1, g_hFashionItems[1], "-1");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");
				
				PrintToChat(param1,"Wearable Items Removed");
			}
			else if (StrEqual(item, "70001"))
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30720, 10, 6); //Arkham Cowl
				CreateHat(param1, 30722, 10, 6); //Batters Bracers
				CreateHat(param1, 30738, 10, 6); //Bat Belt
				CreateHat(param1, 30727, 10, 6); //Caped Crusader					

				SetClientCookie(param1, g_hFashionItems[0], "30720");
				SetClientCookie(param1, g_hFashionItems[1], "30722");
				SetClientCookie(param1, g_hFashionItems[2], "30738");
				SetClientCookie(param1, g_hFashionItems[3], "30727");
				SetClientCookie(param1, g_hFashionItems[4], "-1");				
			}
			else if (StrEqual(item, "70002")) 
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 1185, 10, 6); //Saxton
				CreateHat(param1, 30878, 10, 6); //Quizzical Quetzal
				CreateHat(param1, 30880, 10, 6); //Pocket Saxton

				SetClientCookie(param1, g_hFashionItems[0], "1185");
				SetClientCookie(param1, g_hFashionItems[1], "30878");
				SetClientCookie(param1, g_hFashionItems[2], "30880");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");				
			}
			else if (StrEqual(item, "125"))
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 125, 10, 6); //Cheater's Lament
				
				SetClientCookie(param1, g_hFashionItems[0], "125");
				SetClientCookie(param1, g_hFashionItems[1], "-1");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");				
			}
			else if (StrEqual(item, "126"))
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 126, 10, 6); //Bill's Hat
				
				SetClientCookie(param1, g_hFashionItems[0], "126");
				SetClientCookie(param1, g_hFashionItems[1], "-1");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");				
			}
			else if (StrEqual(item, "70005"))
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 743, 10, 6); //Pyrovision Goggles
				SetClientCookie(param1, g_hFashionItems[0], "743");
			}
			else if (StrEqual(item, "162"))
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 162, 10, 6); //Max's Severed Head

				SetClientCookie(param1, g_hFashionItems[0], "162");
				SetClientCookie(param1, g_hFashionItems[1], "-1");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "30643"))
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30643, 10, 6); //Potassium Bonnet

				SetClientCookie(param1, g_hFashionItems[0], "30643");
				SetClientCookie(param1, g_hFashionItems[1], "-1");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}			
			else if (StrEqual(item, "30669"))
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30669, 10, 6); //Space Hamster Hammy
				CreateHat(param1, 30647, 10, 6); //Phononaut

				SetClientCookie(param1, g_hFashionItems[0], "30669");
				SetClientCookie(param1, g_hFashionItems[1], "30647");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70008")) //FrankenHeavy
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 561, 10, 6); //Can Opener
				CreateHat(param1, 562, 10, 6); //Soviet Stitchup
				CreateHat(param1, 563, 10, 6); //Steel Toed Stompers

				SetClientCookie(param1, g_hFashionItems[0], "561");
				SetClientCookie(param1, g_hFashionItems[1], "562");
				SetClientCookie(param1, g_hFashionItems[2], "563");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70009")) //Grand Duchess
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 930, 10, 6); //Grand Duchess Tiara
				CreateHat(param1, 931, 10, 6); //Grand Duchess Fairy Wings
				CreateHat(param1, 932, 10, 6); //Grand Duchess Tutu	
				
				SetClientCookie(param1, g_hFashionItems[0], "930");
				SetClientCookie(param1, g_hFashionItems[1], "931");
				SetClientCookie(param1, g_hFashionItems[2], "932");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70010")) //Minsk Beast
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30533, 10, 6); //Minsk Beef
				CreateHat(param1, 30532, 10, 6); //Bull Locks
				CreateHat(param1, 30531, 10, 6); //Bone Cut Belt
				
				SetClientCookie(param1, g_hFashionItems[0], "30533");
				SetClientCookie(param1, g_hFashionItems[1], "30532");
				SetClientCookie(param1, g_hFashionItems[2], "30531");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70011")) //Yeti
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 1187, 10, 6); //Yeti Head
				CreateHat(param1, 1189, 10, 6); //Yeti Arms
				CreateHat(param1, 1188, 10, 6); //Yeti Legs
				
				SetClientCookie(param1, g_hFashionItems[0], "1187");
				SetClientCookie(param1, g_hFashionItems[1], "1189");
				SetClientCookie(param1, g_hFashionItems[2], "1188");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70012")) //Highland Hound	
			{
				TF2_RemoveCosmetics(param1);	
				CreateHat(param1, 543, 10, 6); //Hair of the Dog
				CreateHat(param1, 544, 10, 6); //Scottish Snarl
				CreateHat(param1, 545, 10, 6); //Pickled Paws
				
				SetClientCookie(param1, g_hFashionItems[0], "543");
				SetClientCookie(param1, g_hFashionItems[1], "544");
				SetClientCookie(param1, g_hFashionItems[2], "545");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70013")) //Tin Soldier	
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 555, 10, 6); //Idiot Box
				CreateHat(param1, 556, 10, 6); //Steel Pipes
				CreateHat(param1, 557, 10, 6); //Shoestring Budget
				
				SetClientCookie(param1, g_hFashionItems[0], "555");
				SetClientCookie(param1, g_hFashionItems[1], "556");
				SetClientCookie(param1, g_hFashionItems[2], "557");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70014")) //Federal Express
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30390, 10, 6); //Spook Specs
				CreateHat(param1, 30388, 10, 6); //Classified Coif
				CreateHat(param1, 30392, 10, 6); //Man in Slacks
				
				SetClientCookie(param1, g_hFashionItems[0], "30390");
				SetClientCookie(param1, g_hFashionItems[1], "30388");
				SetClientCookie(param1, g_hFashionItems[2], "30392");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70015")) //Ninja Pack
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30394, 10, 6); //Frickin Sweet Ninja Hood
				CreateHat(param1, 30395, 10, 6); //Southie Shinobi
				CreateHat(param1, 30396, 10, 6); //Red Socks
				
				SetClientCookie(param1, g_hFashionItems[0], "30394");
				SetClientCookie(param1, g_hFashionItems[1], "30395");
				SetClientCookie(param1, g_hFashionItems[2], "30396");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70016")) //Deep Fried Dummy
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30491, 10, 6); //Nugget Noggin
				CreateHat(param1, 30492, 10, 6); //Fowl Fists
				CreateHat(param1, 30493, 10, 6); //Talon Trotters

				SetClientCookie(param1, g_hFashionItems[0], "30491");
				SetClientCookie(param1, g_hFashionItems[1], "30492");
				SetClientCookie(param1, g_hFashionItems[2], "30493");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70017")) //Isolationist
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30471, 10, 6); //Alien Cranium
				CreateHat(param1, 30470, 10, 6); //Biomech Backpack
				CreateHat(param1, 30472, 10, 6); //Xeno Suit
				
				SetClientCookie(param1, g_hFashionItems[0], "30471");
				SetClientCookie(param1, g_hFashionItems[1], "30470");
				SetClientCookie(param1, g_hFashionItems[2], "30472");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70018")) //Rooftop Rebel
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30494, 10, 6); //Head Hunter
				CreateHat(param1, 30495, 10, 6); //Claws and Infect
				CreateHat(param1, 30496, 10, 6); //Crazy Legs
				
				SetClientCookie(param1, g_hFashionItems[0], "30494");
				SetClientCookie(param1, g_hFashionItems[1], "30495");
				SetClientCookie(param1, g_hFashionItems[2], "30496");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70019")) //Curse a Nature
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 546, 10, 6); //Wrap Battler
				CreateHat(param1, 547, 10, 6); //Bankh
				CreateHat(param1, 548, 10, 6); //Futankamun	

				SetClientCookie(param1, g_hFashionItems[0], "546");
				SetClientCookie(param1, g_hFashionItems[1], "547");
				SetClientCookie(param1, g_hFashionItems[2], "548");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70020")) //Boston Bulldog
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30207, 10, 6); //Hounds Hood
				CreateHat(param1, 30077, 10, 6); //Cool Cat Cardigan				
				CreateHat(param1, 30208, 10, 6); //Terrier Trousers

				SetClientCookie(param1, g_hFashionItems[0], "30207");
				SetClientCookie(param1, g_hFashionItems[1], "30077");
				SetClientCookie(param1, g_hFashionItems[2], "30208");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70021")) //Super Sidekick
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30735, 10, 6); //Sidekicks Side Slick
				CreateHat(param1, 30736, 10, 6); //Bat Backup
				CreateHat(param1, 30737, 10, 6); //Crook Combatant
				
				SetClientCookie(param1, g_hFashionItems[0], "30735");
				SetClientCookie(param1, g_hFashionItems[1], "30736");
				SetClientCookie(param1, g_hFashionItems[2], "30737");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70022")) //Super Speedster
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30867, 10, 6); //Lightning Lid
				CreateHat(param1, 30875, 10, 6); //Speedsters Spandex
				CreateHat(param1, 857, 10, 6); //Flunkyware	

				SetClientCookie(param1, g_hFashionItems[0], "30867");
				SetClientCookie(param1, g_hFashionItems[1], "30875");
				SetClientCookie(param1, g_hFashionItems[2], "857");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70023")) //Dr Grordborts Moonman
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 597, 10, 6); //Bubble Pipe
				CreateHat(param1, 596, 10, 6); //Moonman Backpack
				CreateHat(param1, 30236, 10, 6); //Pin Pals	
				
				SetClientCookie(param1, g_hFashionItems[0], "597");
				SetClientCookie(param1, g_hFashionItems[1], "596");
				SetClientCookie(param1, g_hFashionItems[2], "30236");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70024")) //Sons of Arsonry
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30399, 10, 6); //Smoking Skid Lid
				CreateHat(param1, 30400, 10, 6); //Lunatics Leathers
				CreateHat(param1, 30398, 10, 6); //Gas Guzzler
				
				SetClientCookie(param1, g_hFashionItems[0], "30399");
				SetClientCookie(param1, g_hFashionItems[1], "30400");
				SetClientCookie(param1, g_hFashionItems[2], "30398");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70025")) //Ronin Roaster
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30418, 10, 6); //Combustible Kabuto
				CreateHat(param1, 30391, 10, 6); //Sengoku Scorcher
				
				SetClientCookie(param1, g_hFashionItems[0], "30418");
				SetClientCookie(param1, g_hFashionItems[1], "30391");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70026")) //Fast Food Firestarter
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30416, 10, 6); //Employee of the Mmmph
				CreateHat(param1, 30417, 10, 6); //Frymaster
				CreateHat(param1, 1024, 10, 6); //Crofts Crest
				
				SetClientCookie(param1, g_hFashionItems[0], "30416");
				SetClientCookie(param1, g_hFashionItems[1], "30417");
				SetClientCookie(param1, g_hFashionItems[2], "1024");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70027")) //Infernal Imp
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 549, 10, 6); //Blazing Bull
				CreateHat(param1, 550, 10, 6); //Fallen Angel
				CreateHat(param1, 551, 10, 6); //Tail from the Crypt

				SetClientCookie(param1, g_hFashionItems[0], "549");
				SetClientCookie(param1, g_hFashionItems[1], "550");
				SetClientCookie(param1, g_hFashionItems[2], "551");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70028")) //Burny the Pyrosaur
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30203, 10, 6); //Burnys Boney Bonnet
				CreateHat(param1, 30225, 10, 6); //Cauterizers Caudal Appendage
				CreateHat(param1, 30259, 10, 6); //Monsters Stompers
				
				SetClientCookie(param1, g_hFashionItems[0], "30203");
				SetClientCookie(param1, g_hFashionItems[1], "30225");
				SetClientCookie(param1, g_hFashionItems[2], "30259");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70029")) //Murky Lurker
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30273, 10, 6); //Vicious Visage
				CreateHat(param1, 30303, 10, 6); //Abhorrent Appendages
				CreateHat(param1, 1011, 10, 6); //Tux

				SetClientCookie(param1, g_hFashionItems[0], "30273");
				SetClientCookie(param1, g_hFashionItems[1], "30303");
				SetClientCookie(param1, g_hFashionItems[2], "1011");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70030")) //South of the Border
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30429, 10, 6); //Allbrero
				CreateHat(param1, 30430, 10, 6); //Seeing Double
				CreateHat(param1, 30431, 10, 6); //Six Pack Abs
				
				SetClientCookie(param1, g_hFashionItems[0], "30429");
				SetClientCookie(param1, g_hFashionItems[1], "30430");
				SetClientCookie(param1, g_hFashionItems[2], "30431");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70031")) //Cursed Captain
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30193, 10, 6); //Capn Calamari
				CreateHat(param1, 30219, 10, 6); //Squids Lid

				SetClientCookie(param1, g_hFashionItems[0], "30193");
				SetClientCookie(param1, g_hFashionItems[1], "30219");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70032")) //Count Tavish
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30241, 10, 6); //Transylvania Top
				CreateHat(param1, 30249, 10, 6); //Lordly Lapels
				CreateHat(param1, 922, 10, 6); //Bonedolier

				SetClientCookie(param1, g_hFashionItems[0], "30241");
				SetClientCookie(param1, g_hFashionItems[1], "30249");
				SetClientCookie(param1, g_hFashionItems[2], "922");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70033")) //Forgotten King
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30516, 10, 6); //Forgotten Kings Restless Head
				CreateHat(param1, 30517, 10, 6); //Forgotten Kings Pauldrons
				CreateHat(param1, 874, 10, 6); //King of Scotland Cape
				
				SetClientCookie(param1, g_hFashionItems[0], "30516");
				SetClientCookie(param1, g_hFashionItems[1], "30517");
				SetClientCookie(param1, g_hFashionItems[2], "874");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70034")) //Beach Bum
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 145, 10, 6); //Hound Dog
				CreateHat(param1, 30803, 10, 6); //Heavy Tourism
				CreateHat(param1, 990, 10, 6); //Aqua Flops
				CreateHat(param1, 143, 10, 6); //Earbuds

				SetClientCookie(param1, g_hFashionItems[0], "145");
				SetClientCookie(param1, g_hFashionItems[1], "30803");
				SetClientCookie(param1, g_hFashionItems[2], "990");
				SetClientCookie(param1, g_hFashionItems[3], "143");	
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70035")) //Colonial
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30114, 10, 6); //Valley Forge
				CreateHat(param1, 30142, 10, 6); //Founding Father
				CreateHat(param1, 30117, 10, 6); //Colonial Clogs

				SetClientCookie(param1, g_hFashionItems[0], "30114");
				SetClientCookie(param1, g_hFashionItems[1], "30142");
				SetClientCookie(param1, g_hFashionItems[2], "30117");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70036")) //Lone Warrior
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30477, 10, 6); //Lone Survivor
				CreateHat(param1, 631, 10, 6); //Hat with No Name
				CreateHat(param1, 30392, 10, 6); //Man in Slacks
				
				SetClientCookie(param1, g_hFashionItems[0], "30477");
				SetClientCookie(param1, g_hFashionItems[1], "631");
				SetClientCookie(param1, g_hFashionItems[2], "30392");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70037")) //Hovering Hotshot
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30662, 10, 6); //Head Full of Hot Air
				CreateHat(param1, 30664, 10, 6); //Space Diver
				CreateHat(param1, 30795, 10, 6); //Hovering Hotshot
				
				SetClientCookie(param1, g_hFashionItems[0], "30662");
				SetClientCookie(param1, g_hFashionItems[1], "30664");
				SetClientCookie(param1, g_hFashionItems[2], "30795");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70038")) //Centurion
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30063, 10, 6); //Centurion
				CreateHat(param1, 30062, 10, 6); //Steel Sixpack
				CreateHat(param1, 856, 10, 6); //Pyrotechnic Tote

				SetClientCookie(param1, g_hFashionItems[0], "30063");
				SetClientCookie(param1, g_hFashionItems[1], "30062");
				SetClientCookie(param1, g_hFashionItems[2], "856");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70039")) //Camouflage
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 720, 10, 6); //Bushmans Boonie
				CreateHat(param1, 30892, 10, 6); //Conspicuous Camouflage
				CreateHat(param1, 30891, 10, 6); //Cammy Jammies

				SetClientCookie(param1, g_hFashionItems[0], "720");
				SetClientCookie(param1, g_hFashionItems[1], "30892");
				SetClientCookie(param1, g_hFashionItems[2], "30891");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70040")) //Marsupial Man
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30501, 10, 6); //Marsupial Man
				CreateHat(param1, 30513, 10, 11); //Mr Mundees Wild Ride
				CreateHat(param1, 30478, 10, 6); //Poachers Safari Jacket
				
				SetClientCookie(param1, g_hFashionItems[0], "30501");
				SetClientCookie(param1, g_hFashionItems[1], "30513");
				SetClientCookie(param1, g_hFashionItems[2], "30478");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70041")) //Manngaroo
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30504, 10, 6); //Marsupial Muzzle
				CreateHat(param1, 30502, 10, 11); //Kanga Kickers
				CreateHat(param1, 30503, 10, 6); //Roo Rippers

				SetClientCookie(param1, g_hFashionItems[0], "30504");
				SetClientCookie(param1, g_hFashionItems[1], "30502");
				SetClientCookie(param1, g_hFashionItems[2], "30503");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70042")) //Sir Shootsalot
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30284, 10, 6); //Sir Shootsalot
				CreateHat(param1, 917, 10, 11); //Sir Hootsalot
				CreateHat(param1, 30600, 10, 6); //Wally Pocket
				
				SetClientCookie(param1, g_hFashionItems[0], "30284");
				SetClientCookie(param1, g_hFashionItems[1], "917");
				SetClientCookie(param1, g_hFashionItems[2], "30600");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70043")) //Camper Van Helsing
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 564, 10, 6); //Holy Hunter
				CreateHat(param1, 565, 10, 11); //Silver Bullets
				CreateHat(param1, 566, 10, 6); //Garlic Flank Stake
				
				SetClientCookie(param1, g_hFashionItems[0], "564");
				SetClientCookie(param1, g_hFashionItems[1], "565");
				SetClientCookie(param1, g_hFashionItems[2], "566");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70044")) //Corona Australis
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30648, 10, 6); //Corona Australis
				CreateHat(param1, 30649, 10, 11); //Final Frontiersman
				CreateHat(param1, 30650, 10, 6); //Starduster
				CreateHat(param1, 30629, 10, 6); //Support Spurs

				SetClientCookie(param1, g_hFashionItems[0], "30648");
				SetClientCookie(param1, g_hFashionItems[1], "30649");
				SetClientCookie(param1, g_hFashionItems[2], "30650");
				SetClientCookie(param1, g_hFashionItems[3], "30629");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70045")) //Archer
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30874, 10, 6); //Archers Sterling
				CreateHat(param1, 30857, 10, 11); //Guilden Guardian
				CreateHat(param1, 30789, 10, 6); //Scoped Spartan

				SetClientCookie(param1, g_hFashionItems[0], "30874");
				SetClientCookie(param1, g_hFashionItems[1], "30857");
				SetClientCookie(param1, g_hFashionItems[2], "30789");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70046")) //Gravelpit Emperor
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30261, 10, 6); //Candymans Cap
				CreateHat(param1, 30260, 10, 11); //Bountiful Bow
				CreateHat(param1, 30301, 10, 6); //Bozos Brogues

				SetClientCookie(param1, g_hFashionItems[0], "30261");
				SetClientCookie(param1, g_hFashionItems[1], "30260");
				SetClientCookie(param1, g_hFashionItems[2], "30301");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70047")) //Invisible Rogue
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 558, 10, 6); //Under Cover
				CreateHat(param1, 559, 10, 11); //Griffins Gog
				CreateHat(param1, 560, 10, 6); //Intangible Ascot

				SetClientCookie(param1, g_hFashionItems[0], "558");
				SetClientCookie(param1, g_hFashionItems[1], "559");
				SetClientCookie(param1, g_hFashionItems[2], "560");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70048")) //Automatic Pilot
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30404, 10, 6); //Aviator Assassin
				CreateHat(param1, 30405, 10, 11); //Sky Captain
				CreateHat(param1, 30606, 10, 6); //Pocket Momma	

				SetClientCookie(param1, g_hFashionItems[0], "30404");
				SetClientCookie(param1, g_hFashionItems[1], "30405");
				SetClientCookie(param1, g_hFashionItems[2], "30606");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70049")) //Aloha Apparel
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30085, 10, 6); //Macho Mann
				CreateHat(param1, 30884, 10, 11); //Aloha Apparel
				CreateHat(param1, 30467, 10, 6); //Spycrab	
				
				SetClientCookie(param1, g_hFashionItems[0], "30085");
				SetClientCookie(param1, g_hFashionItems[1], "30884");
				SetClientCookie(param1, g_hFashionItems[2], "30467");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70050")) //Big Topper
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30798, 10, 6); //Big Topper
				CreateHat(param1, 30797, 10, 11); //Showstopper
				CreateHat(param1, 30606, 10, 6); //Pocket Momma
				
				SetClientCookie(param1, g_hFashionItems[0], "30798");
				SetClientCookie(param1, g_hFashionItems[1], "30797");
				SetClientCookie(param1, g_hFashionItems[2], "30606");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70051")) //Ethreal Hood
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30195, 10, 6); //Ethereal Hood
				CreateHat(param1, 483, 10, 11); //Rogues Col Roule
				CreateHat(param1, 30125, 10, 6); //Rogues Brogues
				
				SetClientCookie(param1, g_hFashionItems[0], "30195");
				SetClientCookie(param1, g_hFashionItems[1], "483");
				SetClientCookie(param1, g_hFashionItems[2], "30125");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70052")) //Fowl Cowl
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30182, 10, 6); //Le Homme Burglerre
				CreateHat(param1, 30283, 10, 11); //Foul Cowl
				CreateHat(param1, 30728, 10, 6); //Buttler

				SetClientCookie(param1, g_hFashionItems[0], "30182");
				SetClientCookie(param1, g_hFashionItems[1], "30283");
				SetClientCookie(param1, g_hFashionItems[2], "30728");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70053")) //Dr Gogglestache
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 552, 10, 6); //Einstein
				CreateHat(param1, 553, 10, 6); //Dr Gogglestache
				CreateHat(param1, 554, 10, 6); //Emerald Jarate

				SetClientCookie(param1, g_hFashionItems[0], "552");
				SetClientCookie(param1, g_hFashionItems[1], "553");
				SetClientCookie(param1, g_hFashionItems[2], "554");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70054")) //Private Eye
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 388, 10, 6); //Private Eye
				CreateHat(param1, 657, 10, 11); //Nine Pipe Problem
				CreateHat(param1, 30096, 10, 6); //Das Feelinbeterbager

				SetClientCookie(param1, g_hFashionItems[0], "388");
				SetClientCookie(param1, g_hFashionItems[1], "657");
				SetClientCookie(param1, g_hFashionItems[2], "30096");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70055")) //Coldfront Commander
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30939, 10, 6); //Coldfront Commander
				CreateHat(param1, 30940, 10, 11); //Coldfront Carapace
				CreateHat(param1, 30929, 10, 6); //Pocket Yeti
				
				SetClientCookie(param1, g_hFashionItems[0], "30939");
				SetClientCookie(param1, g_hFashionItems[1], "30940");
				SetClientCookie(param1, g_hFashionItems[2], "30929");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70056")) //Burly Beast
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30862, 10, 6); //Field Practice
				CreateHat(param1, 30817, 10, 11); //Burly Beast
				CreateHat(param1, 30773, 10, 6); //Surgical Survivalist
				
				SetClientCookie(param1, g_hFashionItems[0], "30862");
				SetClientCookie(param1, g_hFashionItems[1], "30817");
				SetClientCookie(param1, g_hFashionItems[2], "30773");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70057")) //Templars Spirit
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30514, 10, 6); //Templars Spirit
				CreateHat(param1, 30515, 10, 11); //Wings of Purity
				CreateHat(param1, 30483, 10, 6); //Pocket Heavy
				
				SetClientCookie(param1, g_hFashionItems[0], "30514");
				SetClientCookie(param1, g_hFashionItems[1], "30515");
				SetClientCookie(param1, g_hFashionItems[2], "30483");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70058")) //Teutonkahmun
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30293, 10, 6); //Teutonkahmun
				CreateHat(param1, 30299, 10, 11); //Ramses Regalia
				CreateHat(param1, 30279, 10, 11); //Archimedes the Undying

				SetClientCookie(param1, g_hFashionItems[0], "30293");
				SetClientCookie(param1, g_hFashionItems[1], "30299");
				SetClientCookie(param1, g_hFashionItems[2], "30279");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70059")) //Hundkopf
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30487, 10, 6); //Hundkopf
				CreateHat(param1, 30486, 10, 11); //Herzensbrecher
				CreateHat(param1, 30488, 10, 6); //Kriegsmaschine 9000
				
				SetClientCookie(param1, g_hFashionItems[0], "30487");
				SetClientCookie(param1, g_hFashionItems[1], "30486");
				SetClientCookie(param1, g_hFashionItems[2], "30488");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70060")) //Transylvanian Toupe
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30489, 10, 6); //Transylvanian Toupe
				CreateHat(param1, 30490, 10, 11); //Vampiric Vesture
				CreateHat(param1, 30198, 10, 6); //Pocket Horsemann
				
				SetClientCookie(param1, g_hFashionItems[0], "30489");
				SetClientCookie(param1, g_hFashionItems[1], "30490");
				SetClientCookie(param1, g_hFashionItems[2], "30198");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70061")) //Holiday Medic
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 666, 10, 6); //BMOC
				CreateHat(param1, 30972, 10, 11); //Pocket Santa
				CreateHat(param1, 30825, 10, 6); //Santarchimedes
				CreateHat(param1, 30750, 10, 6); //Medical Monarch
				CreateHat(param1, 30186, 10, 6); //Brush with Death	

				SetClientCookie(param1, g_hFashionItems[0], "666");
				SetClientCookie(param1, g_hFashionItems[1], "30972");
				SetClientCookie(param1, g_hFashionItems[2], "30825");
				SetClientCookie(param1, g_hFashionItems[3], "30750");
				SetClientCookie(param1, g_hFashionItems[4], "30186");				
			}
			else if (StrEqual(item, "70062")) //Buzz Killer
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 567, 10, 6); //Buzz Killer
				CreateHat(param1, 568, 10, 6); //Frontier Flyboy
				CreateHat(param1, 569, 10, 6); //Legend of Bugfoot

				SetClientCookie(param1, g_hFashionItems[0], "567");
				SetClientCookie(param1, g_hFashionItems[1], "568");
				SetClientCookie(param1, g_hFashionItems[2], "569");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70063")) //Braniac
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 591, 10, 6); //Braniac Goggles
				CreateHat(param1, 590, 10, 6); //Brainiac Hairpiece				
				CreateHat(param1, 519, 10, 6); //Pip Boy

				SetClientCookie(param1, g_hFashionItems[0], "591");
				SetClientCookie(param1, g_hFashionItems[1], "590");
				SetClientCookie(param1, g_hFashionItems[2], "519");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70064")) //Texas
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 94, 10, 6); //Texas Ten Gallon
				CreateHat(param1, 30785, 10, 6); //Dad Duds		
				CreateHat(param1, 30172, 10, 6); //Gold Digger

				SetClientCookie(param1, g_hFashionItems[0], "94");
				SetClientCookie(param1, g_hFashionItems[1], "30785");
				SetClientCookie(param1, g_hFashionItems[2], "30172");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70065")) //Beep Man
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30509, 10, 6); //Beep Man
				CreateHat(param1, 30337, 10, 6); //Trenchers Tunic				
				CreateHat(param1, 30167, 10, 6); //Beep Boy	

				SetClientCookie(param1, g_hFashionItems[0], "30509");
				SetClientCookie(param1, g_hFashionItems[1], "30337");
				SetClientCookie(param1, g_hFashionItems[2], "30167");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70066")) //Aloha Apparel
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30406, 10, 6); //Peaceniks Ponytail
				CreateHat(param1, 30884, 10, 6); //Aloha Apparel
				CreateHat(param1, 30409, 10, 6); //Lonesome Loafers	

				SetClientCookie(param1, g_hFashionItems[0], "30406");
				SetClientCookie(param1, g_hFashionItems[1], "30884");
				SetClientCookie(param1, g_hFashionItems[2], "30409");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70067")) //Frizz
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30871, 10, 6); //Flash of Inspiration
				CreateHat(param1, 30402, 10, 6); //Tools of the Trade			
				CreateHat(param1, 30403, 10, 6); //Joe on the Go

				SetClientCookie(param1, g_hFashionItems[0], "30871");
				SetClientCookie(param1, g_hFashionItems[1], "30402");
				SetClientCookie(param1, g_hFashionItems[2], "30403");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70068")) //Knight
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30969, 10, 6); //Brass Bucket
				CreateHat(param1, 30131, 10, 6); //Brawling Buccaneer
				CreateHat(param1, 30727, 10, 6); //Caped Crusader

				SetClientCookie(param1, g_hFashionItems[0], "30969");
				SetClientCookie(param1, g_hFashionItems[1], "30131");
				SetClientCookie(param1, g_hFashionItems[2], "30727");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70069")) //Battle Bird
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30524, 10, 6); //Battle Bird
				CreateHat(param1, 30727, 10, 6); //Caped Crusader
				CreateHat(param1, 30728, 10, 6); //Buttler

				SetClientCookie(param1, g_hFashionItems[0], "30524");
				SetClientCookie(param1, g_hFashionItems[1], "30727");
				SetClientCookie(param1, g_hFashionItems[2], "30728");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70070")) //Skullcap
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30578, 10, 6); //Skullcap
				CreateHat(param1, 30339, 10, 6); //Killers Kit
				CreateHat(param1, 30236, 10, 6); //Pin Pals	

				SetClientCookie(param1, g_hFashionItems[0], "30578");
				SetClientCookie(param1, g_hFashionItems[1], "30339");
				SetClientCookie(param1, g_hFashionItems[2], "30236");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70071")) //Sight for Sore Eyes
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 387, 10, 6); //Sight for Sore Eyes
				CreateHat(param1, 30936, 10, 6); //Burning Beanie
				CreateHat(param1, 30581, 10, 6); //Pyromancers Raiments
				CreateHat(param1, 30795, 10, 6); //Hovering Hotshot	
				
				SetClientCookie(param1, g_hFashionItems[0], "387");
				SetClientCookie(param1, g_hFashionItems[1], "30936");
				SetClientCookie(param1, g_hFashionItems[2], "30581");
				SetClientCookie(param1, g_hFashionItems[3], "30795");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70072")) //Chicken Kiev
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30238, 10, 6); //Chicken Kiev
				CreateHat(param1, 30913, 10, 6); //Siberian Tigerstripe
				CreateHat(param1, 30079, 10, 6); //Red Army Robin

				SetClientCookie(param1, g_hFashionItems[0], "30238");
				SetClientCookie(param1, g_hFashionItems[1], "30913");
				SetClientCookie(param1, g_hFashionItems[2], "30079");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}	
			else if (StrEqual(item, "70073")) //Scout Beach Bum
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 617, 10, 6); //Backwards Ball Cap
				CreateHat(param1, 30884, 10, 6); //Aloha Apparel
				CreateHat(param1, 630, 10, 6); //Stereoscopic Shades
				CreateHat(param1, 30754, 10, 6); //Hot Heels

				SetClientCookie(param1, g_hFashionItems[0], "617");
				SetClientCookie(param1, g_hFashionItems[1], "30884");
				SetClientCookie(param1, g_hFashionItems[2], "630");
				SetClientCookie(param1, g_hFashionItems[3], "30754");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70074")) //High Sky Fly Guy
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30984, 10, 6); //High Sky Fly Guy
				CreateHat(param1, 30985, 10, 6); //Private Maggot Muncher
				CreateHat(param1, 30983, 10, 6); //Veterans Attire

				SetClientCookie(param1, g_hFashionItems[0], "30984");
				SetClientCookie(param1, g_hFashionItems[1], "30985");
				SetClientCookie(param1, g_hFashionItems[2], "30983");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70075")) //Tundra Top
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30976, 10, 6); //Tundra Top
				CreateHat(param1, 30975, 10, 6); //Robin Walkers

				SetClientCookie(param1, g_hFashionItems[0], "30976");
				SetClientCookie(param1, g_hFashionItems[1], "30975");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70076")) //Antarctic Eyewear
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30977, 10, 6); //Antarctic Eyewear
				CreateHat(param1, 30975, 10, 6); //Robin Walkers

				SetClientCookie(param1, g_hFashionItems[0], "30977");
				SetClientCookie(param1, g_hFashionItems[1], "30975");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70077")) //Frag Proof Fragger
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30979, 10, 6); //Frag Proof Fragger
				CreateHat(param1, 30945, 10, 6); //Blast Blocker
				CreateHat(param1, 30742, 10, 6); //Shin Shredders

				SetClientCookie(param1, g_hFashionItems[0], "30979");
				SetClientCookie(param1, g_hFashionItems[1], "30945");
				SetClientCookie(param1, g_hFashionItems[2], "30742");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70078")) //Tsar Platinum
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30980, 10, 6); //Tsar Platinum
				CreateHat(param1, 30981, 10, 6); //Starboard Crusader

				SetClientCookie(param1, g_hFashionItems[0], "30980");
				SetClientCookie(param1, g_hFashionItems[1], "30981");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70079")) //Burning Question and Hot Case
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30987, 10, 6); //Burning Question
				CreateHat(param1, 30986, 10, 6); //Hot Case	

				SetClientCookie(param1, g_hFashionItems[0], "30987");
				SetClientCookie(param1, g_hFashionItems[1], "30986");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70080")) //Assassins Attire and Aristotle
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30989, 10, 6); //Assassins Attire
				CreateHat(param1, 30988, 10, 6); //Aristotle
				
				SetClientCookie(param1, g_hFashionItems[0], "30989");
				SetClientCookie(param1, g_hFashionItems[1], "30988");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70081")) //Punks Pomp
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30993, 10, 6); //Punks Pomp
				CreateHat(param1, 30990, 10, 6); //Wipe Out Wraps
				CreateHat(param1, 30991, 10, 6); //Blizzard Britches
				
				SetClientCookie(param1, g_hFashionItems[0], "30993");
				SetClientCookie(param1, g_hFashionItems[1], "30990");
				SetClientCookie(param1, g_hFashionItems[2], "30991");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70082")) //Cold Case
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30992, 10, 6); //Cold Case
				CreateHat(param1, 30846, 10, 6); //Plumbers Cap	
				CreateHat(param1, 30884, 10, 6); //Aloha Apparel

				SetClientCookie(param1, g_hFashionItems[0], "30992");
				SetClientCookie(param1, g_hFashionItems[1], "30846");
				SetClientCookie(param1, g_hFashionItems[2], "30884");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70083")) //Scourge of the Sky
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 30982, 10, 6); //Scourge of the Sky

				SetClientCookie(param1, g_hFashionItems[0], "30982");
				SetClientCookie(param1, g_hFashionItems[1], "-1");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70084")) //Burning Question and Tricksters Turnout Gear
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 105, 10, 6); //Brigade Helment
				CreateHat(param1, 30169, 10, 6); //Tricksters Turnout Gear

				SetClientCookie(param1, g_hFashionItems[0], "105");
				SetClientCookie(param1, g_hFashionItems[1], "30169");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70085")) //Heart of Gold
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 8367, 10, 6); //Heart of Gold
				CreateHat(param1, 712, 10, 6); //Gifting Man from Gifting Land	
				CreateHat(param1, 30975, 10, 6); //Robin Walkers
				
				SetClientCookie(param1, g_hFashionItems[0], "8367");
				SetClientCookie(param1, g_hFashionItems[1], "712");
				SetClientCookie(param1, g_hFashionItems[2], "30975");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70086")) //Athenian Attire
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31000, 10, 6); //Hephaistos Handcraft
				CreateHat(param1, 31001, 10, 6); //Athenian Attire
				CreateHat(param1, 30999, 10, 6); //Olympic Leapers

				SetClientCookie(param1, g_hFashionItems[0], "31000");
				SetClientCookie(param1, g_hFashionItems[1], "31001");
				SetClientCookie(param1, g_hFashionItems[2], "30999");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70087")) //Crocodile Mun-Dee
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31009, 10, 6); //Crocodile Mun-Dee
				CreateHat(param1, 31005, 10, 6); //Scopers Scales
				
				SetClientCookie(param1, g_hFashionItems[0], "31009");
				SetClientCookie(param1, g_hFashionItems[1], "31005");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70088")) //Murderers Motiff
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31016, 10, 6); //Murderers Motiff
				CreateHat(param1, 31014, 10, 6); //Dressperado
				CreateHat(param1, 31015, 10, 6); //Bandits Boots

				SetClientCookie(param1, g_hFashionItems[0], "31016");
				SetClientCookie(param1, g_hFashionItems[1], "31014");
				SetClientCookie(param1, g_hFashionItems[2], "31015");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70089")) //Ol Snaggletooth
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 229, 10, 6); //Ol Snaggletooth

				SetClientCookie(param1, g_hFashionItems[0], "229");
				SetClientCookie(param1, g_hFashionItems[1], "-1");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70090")) //Bottle Cap
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31042, 10, 6); //Bottle Cap
				CreateHat(param1, 30185, 10, 6); //Flapjack
				CreateHat(param1, 30751, 10, 6); //Bonk Batters Backup

				SetClientCookie(param1, g_hFashionItems[0], "31042");
				SetClientCookie(param1, g_hFashionItems[1], "30185");
				SetClientCookie(param1, g_hFashionItems[2], "30751");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70091")) //Speedy Scoundrel
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31056, 10, 6); //Speedy Scoundrel
				CreateHat(param1, 31043, 10, 6); //Pompous Privateer
				CreateHat(param1, 30719, 10, 6); //Baaarrgh-n-Britches

				SetClientCookie(param1, g_hFashionItems[0], "31056");
				SetClientCookie(param1, g_hFashionItems[1], "31043");
				SetClientCookie(param1, g_hFashionItems[2], "30719");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70092")) //Dancing Doe
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31045, 10, 6); //Dancing Doe
				CreateHat(param1, 30236, 10, 6); //Pin Pals	

				SetClientCookie(param1, g_hFashionItems[0], "31045");
				SetClientCookie(param1, g_hFashionItems[1], "30236");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70093")) //Peacebreaker
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31044, 10, 6); //Peacebreaker
				CreateHat(param1, 30983, 10, 6); //Veterans Attire
				CreateHat(param1, 30339, 10, 6); //Killers Kit

				SetClientCookie(param1, g_hFashionItems[0], "31044");
				SetClientCookie(param1, g_hFashionItems[1], "30983");
				SetClientCookie(param1, g_hFashionItems[2], "30339");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70094")) //Melted Mop
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31041, 10, 6); //Melted Mop
				CreateHat(param1, 31051, 10, 6); //Wanderers Wear
				CreateHat(param1, 31050, 10, 6); //Spawn Camper
				CreateHat(param1, 31047, 10, 6); //Fiery Phoenix

				SetClientCookie(param1, g_hFashionItems[0], "31041");
				SetClientCookie(param1, g_hFashionItems[1], "31051");
				SetClientCookie(param1, g_hFashionItems[2], "31050");
				SetClientCookie(param1, g_hFashionItems[3], "31047");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70095")) //Backbreaker
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31040, 10, 6); //Unforgiven Glory
				CreateHat(param1, 31038, 10, 6); //Backbreaker Skullcracker
				CreateHat(param1, 31039, 10, 6); //Backbreakers Guards
				CreateHat(param1, 31037, 10, 6); //Dynamite Abs	

				SetClientCookie(param1, g_hFashionItems[0], "31040");
				SetClientCookie(param1, g_hFashionItems[1], "31038");
				SetClientCookie(param1, g_hFashionItems[2], "31039");
				SetClientCookie(param1, g_hFashionItems[3], "31037");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70096")) //Mediterranean Mercenary
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31052, 10, 6); //Mediterranean Mercenary
				CreateHat(param1, 31053, 10, 6); //Kapitans Kaftan
				
				SetClientCookie(param1, g_hFashionItems[0], "31052");
				SetClientCookie(param1, g_hFashionItems[1], "31053");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70097")) //Bare Necessities
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31054, 10, 6); //Bare Necessities
				CreateHat(param1, 31055, 10, 6); //Wagga Wagga Wear
				CreateHat(param1, 30891, 10, 6); //Cammy Jammies

				SetClientCookie(param1, g_hFashionItems[0], "31054");
				SetClientCookie(param1, g_hFashionItems[1], "31055");
				SetClientCookie(param1, g_hFashionItems[2], "30891");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70098")) //Shutterbug
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31048, 10, 6); //Shutterbug
				CreateHat(param1, 31036, 10, 6); //Stapler Specs

				SetClientCookie(param1, g_hFashionItems[0], "31048");
				SetClientCookie(param1, g_hFashionItems[1], "31036");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70099")) //Bat Hat and Binoculus
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31058, 10, 6); //Bat Hat
				CreateHat(param1, 31060, 10, 6); //Binoculus
				CreateHat(param1, 31061, 10, 6); //Pocket Halloween Boss

				SetClientCookie(param1, g_hFashionItems[0], "31058");
				SetClientCookie(param1, g_hFashionItems[1], "31060");
				SetClientCookie(param1, g_hFashionItems[2], "31061");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70100")) //Remorseless Raptor
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31082, 10, 6); //Remorseless Raptor
				CreateHat(param1, 31083, 10, 6); //Wild Whip
				CreateHat(param1, 30888, 10, 6); //Jungle Jersey

				SetClientCookie(param1, g_hFashionItems[0], "31082");
				SetClientCookie(param1, g_hFashionItems[1], "31083");
				SetClientCookie(param1, g_hFashionItems[2], "30888");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70101")) //El Zapateador
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31069, 10, 6); //El Zapateador
				CreateHat(param1, 31070, 10, 6); //Party Poncho
				CreateHat(param1, 30558, 10, 6); //Coldfront Curbstompers

				SetClientCookie(param1, g_hFashionItems[0], "31069");
				SetClientCookie(param1, g_hFashionItems[1], "31070");
				SetClientCookie(param1, g_hFashionItems[2], "30558");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70102")) //Racc Mann
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31071, 10, 6); //Racc Mann
				CreateHat(param1, 30983, 10, 6); //Veterans Attire
				CreateHat(param1, 30339, 10, 6); //Killers Kit

				SetClientCookie(param1, g_hFashionItems[0], "31071");
				SetClientCookie(param1, g_hFashionItems[1], "30983");
				SetClientCookie(param1, g_hFashionItems[2], "30339");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70103")) //Pyro Shark
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31068, 10, 6); //Pyroshark
				CreateHat(param1, 30584, 10, 6); //charred chainmail - armoured appendages
				CreateHat(param1, 31050, 10, 6); //Spawn Camper

				SetClientCookie(param1, g_hFashionItems[0], "31068");
				SetClientCookie(param1, g_hFashionItems[1], "30584");
				SetClientCookie(param1, g_hFashionItems[2], "31050");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70104")) //Candy Cranium
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31067, 10, 6); //Candy Cranium
				CreateHat(param1, 31051, 10, 6); //Wanderers Wear
				CreateHat(param1, 31050, 10, 6); //Spawn Camper

				SetClientCookie(param1, g_hFashionItems[0], "31067");
				SetClientCookie(param1, g_hFashionItems[1], "31051");
				SetClientCookie(param1, g_hFashionItems[2], "31050");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70105")) //Pyrolantern
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31076, 10, 6); //Pyrolantern
				CreateHat(param1, 30400, 10, 6); //Lunatics Leathers
				CreateHat(param1, 30398, 10, 6); //Gas Guzzler

				SetClientCookie(param1, g_hFashionItems[0], "31076");
				SetClientCookie(param1, g_hFashionItems[1], "30400");
				SetClientCookie(param1, g_hFashionItems[2], "30398");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70106")) //Convict Hat
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31080, 10, 6); //Convict Hat
				CreateHat(param1, 31079, 10, 6); //Soviet Strongmann
				CreateHat(param1, 30343, 10, 6); //Gone Commando

				SetClientCookie(param1, g_hFashionItems[0], "31080");
				SetClientCookie(param1, g_hFashionItems[1], "31079");
				SetClientCookie(param1, g_hFashionItems[2], "30343");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70107")) //El Mostacho
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31074, 10, 6); //El Mostacho
				CreateHat(param1, 30804, 10, 6); //El Paso Poncho
				CreateHat(param1, 30629, 10, 6); //Support Spurs
				SetClientCookie(param1, g_hFashionItems[0], "31074");
				SetClientCookie(param1, g_hFashionItems[1], "30804");
				SetClientCookie(param1, g_hFashionItems[2], "30629");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70108")) //Eingineer
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31075, 10, 6); //Eingineer
				CreateHat(param1, 30337, 10, 6); //Trenchers Tunic
				CreateHat(param1, 31013, 10, 6); //Mini Engy

				SetClientCookie(param1, g_hFashionItems[0], "31075");
				SetClientCookie(param1, g_hFashionItems[1], "30337");
				SetClientCookie(param1, g_hFashionItems[2], "31013");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70109")) //Madmanns Muzzle
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31077, 10, 6); //Madmanns Muzzle
				CreateHat(param1, 31078, 10, 6); //Derangement Garment
				
				SetClientCookie(param1, g_hFashionItems[0], "31077");
				SetClientCookie(param1, g_hFashionItems[1], "31078");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70110")) //Elizabeth the Third
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31084, 10, 6); //Elizabeth the Third
				CreateHat(param1, 30978, 10, 6); //Head Hedge
				CreateHat(param1, 30424, 10, 6); //Triggermans Tacticals

				SetClientCookie(param1, g_hFashionItems[0], "31084");
				SetClientCookie(param1, g_hFashionItems[1], "30978");
				SetClientCookie(param1, g_hFashionItems[2], "30424");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70111")) //Avian Amante
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 1073, 10, 6); //Avian Amante
				CreateHat(param1, 30125, 10, 6); //Rogues Brogues
				
				SetClientCookie(param1, g_hFashionItems[0], "1073");
				SetClientCookie(param1, g_hFashionItems[1], "30125");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70112")) //Voodoo Vizier
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31072, 10, 6); //Voodoo Vizier
				CreateHat(param1, 30476, 10, 6); //Lady Killer
				CreateHat(param1, 30125, 10, 6); //Rogues Brogues

				SetClientCookie(param1, g_hFashionItems[0], "31072");
				SetClientCookie(param1, g_hFashionItems[1], "30476");
				SetClientCookie(param1, g_hFashionItems[2], "30125");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70113")) //Samurai
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 359, 10, 6); //Samur Eye
				CreateHat(param1, 875, 10, 6); //Menpo		
				CreateHat(param1, 30348, 10, 6); //Bushi Dou
				CreateHat(param1, 30366, 10, 6); //Sangu Sleeves
				CreateHat(param1, 30742, 10, 6); //Shin Shredders
				
				SetClientCookie(param1, g_hFashionItems[0], "359");
				SetClientCookie(param1, g_hFashionItems[1], "875");
				SetClientCookie(param1, g_hFashionItems[2], "30348");
				SetClientCookie(param1, g_hFashionItems[3], "30366");
				SetClientCookie(param1, g_hFashionItems[4], "30742");				
			}
			else if (StrEqual(item, "70114")) //Pyro Shark
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31068, 10, 6); //Pyro Shark
				CreateHat(param1, 30176, 10, 6); //Pop Eyes			
				CreateHat(param1, 30305, 10, 6); //Sub Zero Suit
				
				SetClientCookie(param1, g_hFashionItems[0], "31068");
				SetClientCookie(param1, g_hFashionItems[1], "30176");
				SetClientCookie(param1, g_hFashionItems[2], "30305");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70115")) //Breadcrab
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31105, 10, 6); //Pyro Shark
				CreateHat(param1, 31104, 10, 6); //Pop Eyes			
				
				SetClientCookie(param1, g_hFashionItems[0], "31105");
				SetClientCookie(param1, g_hFashionItems[1], "31104");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70116")) //Spy Crabe de Caapeau
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31109, 10, 6); //Crabe de Caapeau
				CreateHat(param1, 31124, 10, 6); //Smoking Jacket	
				CreateHat(param1, 31110, 10, 6); //Birds Eye Viewer
				
				SetClientCookie(param1, g_hFashionItems[0], "31109");
				SetClientCookie(param1, g_hFashionItems[1], "31124");
				SetClientCookie(param1, g_hFashionItems[2], "31110");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70117")) //Scout Tourist
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31116, 10, 6); //Soda Specs
				CreateHat(param1, 31117, 10, 6); //California Cap
				CreateHat(param1, 31118, 10, 6); //Poolside Polo	
				CreateHat(param1, 31119, 10, 6); //Tools of the Tourist
				
				SetClientCookie(param1, g_hFashionItems[0], "31116");
				SetClientCookie(param1, g_hFashionItems[1], "31117");
				SetClientCookie(param1, g_hFashionItems[2], "31118");
				SetClientCookie(param1, g_hFashionItems[3], "31119");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70118")) //Heavy Pajamas
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31178, 10, 6); //SandManns Brush
				CreateHat(param1, 31179, 10, 6); //BedBug Protection
				CreateHat(param1, 31180, 10, 6); //Bear Walker	
				
				SetClientCookie(param1, g_hFashionItems[0], "31178");
				SetClientCookie(param1, g_hFashionItems[1], "31179");
				SetClientCookie(param1, g_hFashionItems[2], "31180");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70119")) //Medic NightWard
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31176, 10, 6); //Elf Care Provider
				CreateHat(param1, 31177, 10, 6); //NightWard
				CreateHat(param1, 31163, 10, 6); //Particulate Protector				
				CreateHat(param1, 31078, 10, 6); //Derangement Garment	
				
				SetClientCookie(param1, g_hFashionItems[0], "31176");
				SetClientCookie(param1, g_hFashionItems[1], "31177");
				SetClientCookie(param1, g_hFashionItems[1], "31163");				
				SetClientCookie(param1, g_hFashionItems[2], "31078");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}
			else if (StrEqual(item, "70120")) //Particulate Protector
			{
				TF2_RemoveCosmetics(param1);
				CreateHat(param1, 31163, 10, 6); //Particulate Protector
				
				SetClientCookie(param1, g_hFashionItems[0], "31163");
				SetClientCookie(param1, g_hFashionItems[1], "-1");
				SetClientCookie(param1, g_hFashionItems[2], "-1");
				SetClientCookie(param1, g_hFashionItems[3], "-1");
				SetClientCookie(param1, g_hFashionItems[4], "-1");					
			}			
		}
	case MenuAction_End:
		{
			//param1 is MenuEnd reason, if canceled param2 is MenuCancel reason
			CloseHandle(menu);
		}
	}
	return;
}


public Action EventChangeClass(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsFakeClient(client) && IsClientInGame(client))
	{
		SetClientCookie(client, g_hFashionItems[0], "-1");		
		SetClientCookie(client, g_hFashionItems[1], "-1");
		SetClientCookie(client, g_hFashionItems[2], "-1");
		SetClientCookie(client, g_hFashionItems[3], "-1");
		SetClientCookie(client, g_hFashionItems[4], "-1");
	}
}

public Action EventInventoryApplication(Handle event, const char[] name, bool dontBroadcast)
{
	char strItemsindex[5][65];
	int strItem[5];
	strItem[0] = StringToInt(strItemsindex[0]);
	strItem[1] = StringToInt(strItemsindex[1]);
	strItem[2] = StringToInt(strItemsindex[2]);
	strItem[3] = StringToInt(strItemsindex[3]);
	strItem[4] = StringToInt(strItemsindex[4]);

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsFakeClient(client) && IsClientInGame(client))
	{
		GetClientCookie(client, g_hFashionItems[0], strItemsindex[0], 65); //Item 1
		strItem[0] = StringToInt(strItemsindex[0]);		
		if (strItem[0] > 0)
		{
			TF2_RemoveCosmetics(client);
			CreateHat(client, strItem[0], 10, 6);
		}

		GetClientCookie(client, g_hFashionItems[1], strItemsindex[1], 65); //Item 2
		strItem[1] = StringToInt(strItemsindex[1]);		
		if (strItem[1] > 0)
		{
			CreateHat(client, strItem[1], 10, 6);
		}

		GetClientCookie(client, g_hFashionItems[2], strItemsindex[2], 65); //Item 3
		strItem[2] = StringToInt(strItemsindex[2]);		
		if (strItem[2] > 0)
		{
			CreateHat(client, strItem[2], 10, 6);
		}

		GetClientCookie(client, g_hFashionItems[3], strItemsindex[3], 65); //Item 4
		strItem[3] = StringToInt(strItemsindex[3]);		
		if (strItem[3] > 0)
		{
			CreateHat(client, strItem[3], 10, 6);
		}

		GetClientCookie(client, g_hFashionItems[4], strItemsindex[4], 65); //Item 5
		strItem[4] = StringToInt(strItemsindex[4]);		
		if (strItem[4] > 0)
		{
			CreateHat(client, strItem[4], 10, 6);
		}	
	}
}

public void OnClientPostAdminCheck(int client)
{
	SetClientCookie(client, g_hFashionItems[0], "-1");
	SetClientCookie(client, g_hFashionItems[1], "-1");
	SetClientCookie(client, g_hFashionItems[2], "-1");
	SetClientCookie(client, g_hFashionItems[3], "-1");
	SetClientCookie(client, g_hFashionItems[4], "-1");	
}

bool CreateHat(int client, int itemindex, int level, int quality)
{
	int hat = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(hat))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex", itemindex);	 
	SetEntProp(hat, Prop_Send, "m_bInitialized", 1);	
	SetEntProp(hat, Prop_Send, "m_iEntityLevel", level);
	SetEntProp(hat, Prop_Send, "m_iEntityQuality", quality);
	SetEntProp(hat, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	DispatchSpawn(hat);
	SDKCall(g_hEquipWearable, client, hat);
	return true;
} 

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

stock void TF2_RemoveCosmetics(int client)
{
	int edict = MaxClients+1;
	while((edict = FindEntityByClassname(edict, "tf_wearable")) != -1)
	{
		char netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				AcceptEntityInput(edict, "Kill");
			}
		}
	}
}