#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.6"

bool g_bRTouched[MAXPLAYERS+1] = false;
bool g_bMedieval;
ConVar g_hRHEnabled;
Handle g_hEquipWearable;

bool g_bIsBling[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Bling",
	author = "PC Gamer, with code by luki1412 and manicogaming, edited by That Annoying Guide",
	description = "Gives Players random cosmetics and random weapons",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public void OnPluginStart() 
{
	RegAdminCmd("sm_startbling", Command_StartBling, ADMFLAG_SLAY, "Bling Target");
	RegAdminCmd("sm_stopbling", Command_StopBling, ADMFLAG_SLAY, "Stop Bling Target");
	RegConsoleCmd("sm_bling", Command_Bling);
	RegConsoleCmd("sm_nobling", Command_NoBling);	
	
	g_hRHEnabled = CreateConVar("sm_bling_enabled", "1", "Enables/disables this plugin", FCVAR_NONE, true, 0.0, true, 1.0);

	HookEvent("player_spawn", player_spawned);
	HookEvent("post_inventory_application", player_inv);
	HookConVarChange(g_hRHEnabled, OnEnabledChanged);

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
	
}

public void OnEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(g_hRHEnabled))
	{
		HookEvent("post_inventory_application", player_inv);
	}
	else
	{
		UnhookEvent("post_inventory_application", player_inv);
	}
}

public void OnClientDisconnect(int client)
{
	if(g_bIsBling[client])
	{
		g_bIsBling[client] = false;
	}
}

public void OnMapStart()
{
	if (GameRules_GetProp("m_bPlayingMedieval"))
	{
		g_bMedieval = true;
	}	
}

public Action Command_StartBling(int client, int args) 
{
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		makerandom(target_list[i]);
		PrintToChat(target_list[i], "Bling is Enabled!");
		//PrintToChat(target_list[i], "You will have a random class whenever you spawn,");
		PrintToChat(target_list[i], "You will have random weapons and cosmetics,");	
		PrintToChat(target_list[i], "Touch a locker to change your weapons and cosmetics");
		PrintToChat(target_list[i], "To enable or disable Bling type: !bling");	
		ReplyToCommand(client, "Bling Enabled for %N", target_list[i]);
	}
	return Plugin_Handled;
}

public Action Command_StopBling(int client, int args) 
{
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		g_bIsBling[target_list[i]] = false;
		PrintToChat(target_list[i], "Bling is now Disabled.");		
		ReplyToCommand(client, "Bling Disabled for %N", target_list[i]);		
	}
	return Plugin_Handled;
}

public Action Command_Bling(int client, int args) 
{
	if(g_bIsBling[client])
	{
		g_bIsBling[client] = false;
		PrintToChat(client, "[SM] Bling mode is now disabled");
	}
	else
	{
		makerandom(client);
		PrintToChat(client, "Bling is enabled!");
		//PrintToChat(client, "You will have a random class whenever you spawn.");
		PrintToChat(client, "You will have random weapons and cosmetics.");	
		PrintToChat(client, "Touch a locker to change your weapons and cosmetics.");
		PrintToChat(client, "To enable or disable Bling mode type: !bling.");
	}
	
	return Plugin_Handled;
}

public Action Command_NoBling(int client, int args) 
{
	g_bIsBling[client] = false;
	PrintToChat(client, "Bling is Disabled!");
	
	return Plugin_Handled;
}

public void makerandom(int client)
{
	if (!GetConVarInt(g_hRHEnabled))
	{
		return;
	}

	if (IsPlayerHere(client))
	{
		//int ID = GetRandomUInt(1,9);
		//TF2_SetPlayerClass(client, view_as<TFClassType>(ID), true, true);

		if (!g_bRTouched[client])
		{
			TF2_RegeneratePlayer(client);
			g_bRTouched[client] = true;
		}

		RemoveWeaponWearables(client);
		TF2_RemoveAllWearables(client);	

		int userd = GetClientUserId(client);
		g_bIsBling[client] = true;	
		CreateTimer(0.5, Timer_GiveHat, userd);
		CreateTimer(1.0, Timer_GiveWeapons, userd);
	}
}

public Action player_spawned(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidEntity(client) && g_bIsBling[client] == true)
	{
		if(IsClientInGame(client))
		{
			makerandom(client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void player_inv(Handle event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarInt(g_hRHEnabled))
	{
		return;
	}

	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);

	if (g_bIsBling[client] == true && IsPlayerHere(client) && !g_bRTouched[client] && client > 0)
	{
		g_bRTouched[client] = true;

		TF2_RemoveAllWearables(client);
		
		CreateTimer(0.5, Timer_GiveHat, userd);
		CreateTimer(1.0, Timer_GiveWeapons, userd);
	}
}

public Action Timer_GiveHat(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	g_bRTouched[client] = false;
	if (!GetConVarInt(g_hRHEnabled))
	{
		return;
	}
	
	if (IsPlayerHere(client))
	{
		int rnd4 = GetRandomInt(1,20);
		if (rnd4 == 1)
		{
			TF2_RemoveAllWearables(client);
			GiveHat2(client);
			return;
		}
		
		TF2_RemoveAllWearables(client);	
		if (TF2_GetPlayerClass(client) == TFClass_Scout)
		{
			int rnd3 = GetRandomInt(1,37);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 451, 10, 6, 1); //Bonk Boy
					CreateHat(client, 30751, 10, 6, 0); //Bonk Batters Backup
					CreateHat(client, 30754, 10, 6, 0); //Hot Heels					
				}
			case 2:
				{
					CreateHat(client, 546, 10, 6, 1); //Wrap Battler
					CreateHat(client, 547, 10, 6, 0); //Bankh
					CreateHat(client, 548, 10, 6, 0); //Futankamun					
				}
			case 3:
				{
					CreateHat(client, 652, 10, 6, 1); //Big Elfin Deal
					CreateHat(client, 653, 10, 6, 0); //Bootie Time					
					CreateHat(client, 1075, 10, 6, 0); //Sack Full of Smissmas
				}
			case 4:
				{
					CreateHat(client, 780, 10, 6, 1); //Fed Fightin Fedora
					CreateHat(client, 30376, 10, 6, 0); //Ticket Boy				
					CreateHat(client, 781, 10, 6, 0); //Dillingers Duffel
				}
			case 5:
				{
					CreateHat(client, 30207, 10, 6, 1); //Hounds Hood
					CreateHat(client, 30077, 10, 6, 0); //Cool Cat Cardigan				
					CreateHat(client, 30208, 10, 6, 0); //Terrier Trousers
				}
			case 6:
				{
					CreateHat(client, 30428, 10, 6, 1); //Pomade Prince
					CreateHat(client, 30426, 10, 6, 0); //Paisley Pro
					CreateHat(client, 30427, 10, 6, 0); //Argyle Ace					
				}
			case 7:
				{
					CreateHat(client, 30394, 10, 6, 1); //Frickin Sweet Ninja Hood
					CreateHat(client, 30395, 10, 6, 0); //Southie Shinobi
					CreateHat(client, 30396, 10, 6, 0); //Red Socks	
				}
			case 8:
				{
					CreateHat(client, 30471, 10, 6, 1); //Alien Cranium
					CreateHat(client, 30470, 10, 6, 0); //Biomech Backpack
					CreateHat(client, 30472, 10, 6, 0); //Xeno Suit	
				}
			case 9:
				{
					CreateHat(client, 30491, 10, 6, 1); //Nugget Noggin
					CreateHat(client, 30492, 10, 6, 0); //Fowl Fists
					CreateHat(client, 30493, 10, 6, 0); //Talon Trotters	
				}
			case 10:
				{
					CreateHat(client, 30494, 10, 6, 1); //Head Hunter
					CreateHat(client, 30495, 10, 6, 0); //Claws and Infect
					CreateHat(client, 30496, 10, 6, 0); //Crazy Legs	
				}
			case 11:
				{
					CreateHat(client, 30735, 10, 6, 1); //Sidekicks Side Slick
					CreateHat(client, 30736, 10, 6, 0); //Bat Backup
					CreateHat(client, 30737, 10, 6, 0); //Crook Combatant	
				}
			case 12:
				{
					CreateHat(client, 30867, 10, 6, 1); //Lightning Lid
					CreateHat(client, 30875, 10, 6, 0); //Speedsters Spandex
					CreateHat(client, 857, 10, 6, 0); //Flunkyware	
				}
			case 13:
				{
					CreateHat(client, 30636, 10, 6, 1); //Fortunate Son
					CreateHat(client, 30637, 10, 6, 0); //Flak Jack
					CreateHat(client, 30889, 10, 6, 0); //Transparent Trousers	
				}
			case 14:
				{
					CreateHat(client, 30769, 10, 6, 1); //Heralds Helm
					CreateHat(client, 30770, 10, 6, 0); //Courtly Cuirass
					CreateHat(client, 30771, 10, 6, 0); //Squires Sabatons	
				}
			case 15:
				{
					CreateHat(client, 30059, 10, 6, 1); //Beastly Bonnet
					CreateHat(client, 30134, 10, 6, 0); //Delinquent Down Vest					
					CreateHat(client, 30060, 10, 6, 0); //Cheet Sheet				
				}
			case 16:
				{
					CreateHat(client, 1012, 10, 6, 1); //Wilson Weave
					CreateHat(client, 30873, 10, 6, 0); //Airborne Attire				
					CreateHat(client, 30824, 10, 6, 0); //Electric Twanger				
				}
			case 17:
				{
					CreateHat(client, 30573, 10, 6, 1); //Mountebanks Masque
					CreateHat(client, 30574, 10, 6, 0); //Courtiers Collar				
					CreateHat(client, 30575, 10, 6, 0); //Harlequins Hooves
				}
			case 18:
				{
					CreateHat(client, 853, 10, 6, 1); //Crafty Hair
					CreateHat(client, 30884, 10, 6, 0); //Aloha Apparel					
					CreateHat(client, 490, 10, 6, 0); //Flip Flops
				}
			case 19:
				{
					CreateHat(client, 30686, 10, 6, 1); //Death Racer Helmet
					CreateHat(client, 30685, 10, 6, 0); //Thrilling Tracksuit				
					CreateHat(client, 30890, 10, 6, 0); //Forest Footwear
				}
			case 20:
				{
					CreateHat(client, 30718, 10, 6, 1); //Baargh n Bicorne
					CreateHat(client, 30185, 10, 6, 0); //Flapjack				
					CreateHat(client, 30719, 10, 6, 0); //Baargh n Britches
				}
			case 21:
				{
					CreateHat(client, 788, 10, 6, 1); //Void Monk Hair
					CreateHat(client, 30084, 10, 6, 0); //Half Pipe Hurdler			
					CreateHat(client, 30320, 10, 6, 0); //Chucklenuts
				}
			case 22:
				{
					CreateHat(client, 756, 10, 6, 1); //Bolt Action Blitzer					
					CreateHat(client, 30076, 10, 6, 0); //Big Man on Campus
					CreateHat(client, 540, 10, 6, 0); //Ball Kicking Boots					
				}
			case 23:
				{
					CreateHat(client, 126, 10, 6, 1); //Bills Hat
					CreateHat(client, 30889, 10, 6, 0); //Transparent Trousers
					CreateHat(client, 30561, 10, 6, 0); //Botenkhamuns				
				}
			case 24:
				{
					CreateHat(client, 765, 10, 6, 1); //Cross Com Express
					CreateHat(client, 30888, 10, 6, 0); //Jungle Jersey
					CreateHat(client, 30540, 10, 6, 0); //Brooklyn Booties
				}
			case 25:
				{
					CreateHat(client, 30469, 10, 6, 1); //Horace
					CreateHat(client, 30077, 10, 6, 0); //Cool Cat Cardigan
					CreateHat(client, 30849, 10, 6, 0); //Pocket Pauling
				}
			case 26:
				{
					CreateHat(client, 30720, 10, 6, 1); //Arkham Cowl
					CreateHat(client, 30722, 10, 6, 0); //Batters Bracers
					CreateHat(client, 30754, 10, 6, 0); //Hot Heels
				}
			case 27:
				{
					CreateHat(client, 453, 10, 6, 1); //Heros Tail
					CreateHat(client, 468, 10, 6, 0); //Planeswalker Goggles
					CreateHat(client, 454, 10, 6, 0); //Sign of the Wolfs School					
				}
			case 28:
				{
					CreateHat(client, 30078, 10, 6, 1); //Greased Lightning
					CreateHat(client, 30189, 10, 6, 0); //FrenchMans Formals
					CreateHat(client, 30540, 10, 6, 0); //Brooklyn Booties				
				}
			case 29:
				{
					CreateHat(client, 30735, 10, 6, 1); //Sidekicks Side Slick
					CreateHat(client, 30736, 10, 6, 0); //Bat Backup
					CreateHat(client, 30737, 10, 6, 0); //Crook Combatant	
				}
			case 30:
				{
					CreateHat(client, 31000, 10, 6, 1); //Hephaistos Handcraft
					CreateHat(client, 31001, 10, 6, 0); //Athenian Attire
					CreateHat(client, 30999, 10, 6, 0); //Olympic Leapers	
				}
			case 31:
				{
					CreateHat(client, 31022, 10, 6, 1); //Juveniles Jumper
					CreateHat(client, 31023, 10, 6, 0); //Millennial Mercenary
					CreateHat(client, 31021, 10, 6, 0); //Catchers Companion	
				}

			case 32:
				{
					CreateHat(client, 30993, 10, 6, 1); //Punks Pomp
					CreateHat(client, 30990, 10, 6, 0); //Wipe Out Wraps
					CreateHat(client, 30991, 10, 6, 0); //Blizzard Britches	
				}
			case 33:
				{
					CreateHat(client, 30977, 10, 6, 1); //Antarctic Eyewear
					CreateHat(client, 30990, 10, 6, 0); //Wipe Out Wraps
					CreateHat(client, 30991, 10, 6, 0); //Blizzard Britches	
				}
			case 34:
				{
					CreateHat(client, 31042, 10, 6, 1); //Bottle Cap
					CreateHat(client, 30185, 10, 6, 0); //Flapjack
					CreateHat(client, 30751, 10, 6, 0); //Bonk Batters Backup	
				}
			case 35:
				{
					CreateHat(client, 31056, 10, 6, 1); //Speedy Scoundrel
					CreateHat(client, 31043, 10, 6, 0); //Pompous Privateer
					CreateHat(client, 30719, 10, 6, 0); //Baaarrgh-n-Britches	
				}
			case 36:
				{
					CreateHat(client, 31082, 10, 6, 1); //Remorseless Raptor
					CreateHat(client, 31083, 10, 6, 0); //Wild Whip
					CreateHat(client, 30888, 10, 6, 0); //Jungle Jersey	
				}
			case 37:
				{
					CreateHat(client, 31116, 10, 6, 1); //Soda Specs
					CreateHat(client, 31117, 10, 6, 0); //California Cap			
					CreateHat(client, 31118, 10, 6, 0); //Poolside Polo
					CreateHat(client, 31119, 10, 6, 0); //Tools of the Tourist				
				}				
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Soldier)
		{
			int rnd3 = GetRandomInt(1,41);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 30720, 10, 6, 1); //Arkham Cowl
					CreateHat(client, 30722, 10, 6, 0); //Batters Bracers
					CreateHat(client, 30738, 10, 6, 0); //Bat Belt
				}
			case 2:
				{
					CreateHat(client, 852, 10, 6, 1); //Soldiers Stogie
					CreateHat(client, 54, 10, 6, 0); //Soldiers Stash
					CreateHat(client, 446, 10, 6, 0); //Fancy Dress Uniform
				}
			case 3:
				{
					CreateHat(client, 980, 10, 6, 1); //Soldiers Slope Scopers
					CreateHat(client, 30542, 10, 6, 0); //Coldsnap Coat
					CreateHat(client, 30392, 10, 6, 0); //Man in Slacks
				}
			case 4:
				{
					CreateHat(client, 30114, 10, 6, 1); //Valley Forge
					CreateHat(client, 30142, 10, 6, 0); //Founding Father
					CreateHat(client, 30117, 10, 6, 0); //Colonial Clogs
				}
			case 5:
				{
					CreateHat(client, 829, 10, 6, 1); //War Pig
					CreateHat(client, 30331, 10, 6, 0); //Antarctic Parka
					CreateHat(client, 30554, 10, 6, 0); //Mistaken Movember
				}
			case 6:
				{
					CreateHat(client, 99, 10, 6, 1); //Tyrants Helm
					CreateHat(client, 30129, 10, 6, 0); //Hornblower
					CreateHat(client, 30335, 10, 6, 0); //Marshals Mutton Chops
				}
			case 7:
				{
					CreateHat(client, 152, 10, 6, 1); //Killers Kabuto
					CreateHat(client, 875, 10, 6, 0); //Menpo
					CreateHat(client, 30126, 10, 6, 0); //Shoguns Shoulder Guard
				}
			case 8:
				{
					CreateHat(client, 30085, 10, 6, 1); //Macho Mann
					CreateHat(client, 183, 10, 6, 0); //Sergeants Drill Hat
					CreateHat(client, 446, 10, 6, 0); //Fancy Dress Uniform
				}
			case 9:
				{
					CreateHat(client, 445, 10, 6, 1); //Armored Authority
					CreateHat(client, 624, 10, 6, 0); //Clan Pride
					CreateHat(client, 440, 10, 6, 0); //Novelty Mutton Chops
				}
			case 10:
				{
					CreateHat(client, 30477, 10, 6, 1); //Lone Survivor
					CreateHat(client, 631, 10, 6, 0); //Hat with No Name
					CreateHat(client, 30392, 10, 6, 0); //Man in Slacks
				}
			case 11:
				{
					CreateHat(client, 1021, 10, 6, 1); //Doe Boy
					CreateHat(client, 30554, 10, 6, 0); //Mistaken Movember
					CreateHat(client, 30388, 10, 6, 0); //Classified Coif
				}
			case 12:
				{
					CreateHat(client, 875, 10, 6, 1); //Menpo
					CreateHat(client, 30571, 10, 6, 0); //Brimstone
					CreateHat(client, 575, 10, 6, 0); //Infernal Impaler
				}
			case 13:
				{
					CreateHat(client, 30118, 10, 6, 1); //Whirly Warrior
					CreateHat(client, 30601, 10, 6, 0); //Cold Snap Coat
					CreateHat(client, 30558, 10, 6, 0); //Coldfront Curbstompers
				}
			case 14:
				{
					CreateHat(client, 30338, 10, 6, 1); //Ground Control
					CreateHat(client, 852, 10, 6, 0); //Soldiers Stogie
					CreateHat(client, 446, 10, 6, 0); //Fancy Dress Uniform
				}
			case 15:
				{
					CreateHat(client, 516, 10, 6, 1); //Stahlhelm
					CreateHat(client, 30165, 10, 6, 0); //Cuban Bristle Crisis
					CreateHat(client, 852, 10, 6, 0); //Soldiers Stogie
				}
			case 16:
				{
					CreateHat(client, 30115, 10, 6, 1); //Compatriot
					CreateHat(client, 30314, 10, 6, 0); //Slo Poke
					CreateHat(client, 30130, 10, 6, 0); //Lieutenant Bites
				}
			case 17:
				{
					CreateHat(client, 555, 10, 6, 1); //Idiot Box
					CreateHat(client, 556, 10, 6, 0); //Steel Pipes
					CreateHat(client, 557, 10, 6, 0); //Shoestring Budget
				}
			case 18:
				{
					CreateHat(client, 30264, 10, 6, 1); //Hardium Helm
					CreateHat(client, 30265, 10, 6, 0); //Jupiter Jumpers
					CreateHat(client, 30266, 10, 6, 0); //Space Bracers
				}
			case 19:
				{
					CreateHat(client, 30228, 10, 6, 1); //Hidden Dragon
					CreateHat(client, 30227, 10, 6, 0); //Faux Manchu
					CreateHat(client, 30281, 10, 6, 0); //Shaolin Sash
				}
			case 20:
				{
					CreateHat(client, 30390, 10, 6, 1); //Spook Specs
					CreateHat(client, 30388, 10, 6, 0); //Classified Coif
					CreateHat(client, 30392, 10, 6, 0); //Man in Slacks
				}
			case 21:
				{
					CreateHat(client, 30521, 10, 6, 1); //Hellhunters Headpiece
					CreateHat(client, 30522, 10, 6, 0); //Supernatural Stalker
					CreateHat(client, 30520, 10, 6, 0); //Ghoul Gibbin Gear
				}
			case 22:
				{
					CreateHat(client, 30885, 10, 6, 1); //Nuke
					CreateHat(client, 30853, 10, 6, 0); //Flakcatcher
					CreateHat(client, 734, 10, 6, 0); //Teufort Tooth Kicker
				}
			case 23:
				{
					CreateHat(client, 719, 10, 6, 1); //Battle Bob
					CreateHat(client, 30886, 10, 6, 0); //Bananades
					CreateHat(client, 8367, 10, 6, 0); //Heart of Gold
				}
			case 24:
				{
					CreateHat(client, 30578, 10, 6, 1); //Skullcap
					CreateHat(client, 30339, 10, 6, 0); //Killers Kit
					CreateHat(client, 30236, 10, 6, 0); //Pin Pals					
				}
			case 25:
				{
					CreateHat(client, 30524, 10, 6, 1); //Battle Bird
					CreateHat(client, 30727, 10, 6, 0); //Caped Crusader
					CreateHat(client, 30728, 10, 6, 0); //Buttler					
				}
			case 26:
				{
					CreateHat(client, 1067, 10, 6, 1); //Grand Master
					CreateHat(client, 299, 10, 6, 0); //Companion Cube Pin	
					CreateHat(client, 948, 10, 6, 0); //Deadliest Duckling					
				}
			case 27:
				{
					CreateHat(client, 30239, 10, 6, 1); //Freedom Feathers
					CreateHat(client, 30115, 10, 6, 0); //Compatriot
					CreateHat(client, 30898, 10, 6, 0); //Sharp Chest Pain				
				}
			case 28:
				{
					CreateHat(client, 30969, 10, 6, 1); //Brass Bucket
					CreateHat(client, 30131, 10, 6, 0); //Brawling Buccaneer
					CreateHat(client, 30727, 10, 6, 0); //Caped Crusader				
				}
			case 29:
				{
					CreateHat(client, 555, 10, 6, 1); //Idiot Box
					CreateHat(client, 556, 10, 6, 0); //Steel Pipes
					CreateHat(client, 557, 10, 6, 0); //Shoestring Budget
				}
			case 30:
				{
					CreateHat(client, 31024, 10, 6, 1); //Crack Pot
					CreateHat(client, 30983, 10, 6, 0); //Veterans Attire
					CreateHat(client, 30339, 10, 6, 0); //Killers Kit
				}
			case 31:
				{
					CreateHat(client, 31025, 10, 6, 1); //Climbing Commander
					CreateHat(client, 30331, 10, 6, 0); //Antarctic Parka
					CreateHat(client, 30339, 10, 6, 0); //Killers Kit	
				}
			case 32:
				{
					CreateHat(client, 30984, 10, 6, 1); //High Sky Fly Guy
					CreateHat(client, 30985, 10, 6, 0); //Private Maggot Muncher
					CreateHat(client, 30983, 10, 6, 0); //Veterans Attire
				}
			case 33:
				{
					CreateHat(client, 30885, 10, 6, 1); //Nuke
					CreateHat(client, 30558, 10, 6, 0); //Coldfront Curbstompers
					CreateHat(client, 30853, 10, 6, 0); //Flakcatcher
				}
			case 34:
				{
					CreateHat(client, 30899, 10, 6, 1); //Crit Cloak
					CreateHat(client, 30131, 10, 6, 0); //Brawling Buccaneer
				}
			case 35:
				{
					CreateHat(client, 30118, 10, 6, 1); //Whirly Warrior
					CreateHat(client, 30985, 10, 6, 0); //Private Maggot Muncher
					CreateHat(client, 30983, 10, 6, 0); //Veterans Attire
					CreateHat(client, 30339, 10, 6, 0); //Killers Kit					
				}
			case 36:
				{
					CreateHat(client, 31045, 10, 6, 1); //Dancing Doe
					CreateHat(client, 30236, 10, 6, 0); //Pin Pals
				}
			case 37:
				{
					CreateHat(client, 31044, 10, 6, 1); //Peacebreaker
					CreateHat(client, 30983, 10, 6, 0); //Veterans Attire
					CreateHat(client, 30339, 10, 6, 0); //Killers Kit					
				}
			case 38:
				{
					CreateHat(client, 31069, 10, 6, 1); //El Zapateador
					CreateHat(client, 31070, 10, 6, 0); //Party Poncho
					CreateHat(client, 30558, 10, 6, 0); //Coldfront Curbstompers					
				}
			case 39:
				{
					CreateHat(client, 31071, 10, 6, 1); //Racc Mann
					CreateHat(client, 30983, 10, 6, 0); //Veterans Attire
					CreateHat(client, 30339, 10, 6, 0); //Killers Kit				
				}
			case 40:
				{
					CreateHat(client, 941, 10, 6, 1); //Skull Island Topper
					CreateHat(client, 30522, 10, 6, 0); //Supernatural Stalker			
					CreateHat(client, 30727, 10, 6, 0); //Caped Crusader
				}
			case 41:
				{
					CreateHat(client, 30969, 10, 6, 1); //Brass Bucket
					CreateHat(client, 30129, 10, 6, 0); //Hornblower		
					CreateHat(client, 556, 10, 6, 0); //Steel Pipes
				}				
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Pyro)
		{
			int rnd3 = GetRandomInt(1,42);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 549, 10, 6, 1); //Blazing Bull
					CreateHat(client, 550, 10, 6, 0); //Fallen Angel
					CreateHat(client, 551, 10, 6, 0); //Tail from the Crypt	
				}
			case 2:
				{
					CreateHat(client, 597, 10, 6, 1); //Bubble Pipe
					CreateHat(client, 596, 10, 6, 0); //Moonman Backpack
					CreateHat(client, 30236, 10, 6, 0); //Pin Pals	
				}
			case 3:
				{
					CreateHat(client, 30203, 10, 6, 1); //Burnys Boney Bonnet
					CreateHat(client, 30225, 10, 6, 0); //Cauterizers Caudal Appendage
					CreateHat(client, 30259, 10, 6, 0); //Monsters Stompers
				}
			case 4:
				{
					CreateHat(client, 30204, 10, 6, 1); //Crispy Golden Locks
					CreateHat(client, 30205, 10, 6, 0); //Scorched Skirt
					CreateHat(client, 632, 10, 6, 0); //Cremators Conscience
				}
			case 5:
				{
					CreateHat(client, 30273, 10, 6, 1); //Vicious Visage
					CreateHat(client, 30303, 10, 6, 0); //Abhorrent Appendages
					CreateHat(client, 1011, 10, 6, 0); //Tux
				}
			case 6:
				{
					CreateHat(client, 30416, 10, 6, 1); //Employee of the Mmmph
					CreateHat(client, 30417, 10, 6, 0); //Frymaster
					CreateHat(client, 1024, 10, 6, 0); //Crofts Crest
				}
			case 7:
				{
					CreateHat(client, 30399, 10, 6, 1); //Smoking Skid Lid
					CreateHat(client, 30400, 10, 6, 0); //Lunatics Leathers
					CreateHat(client, 30398, 10, 6, 0); //Gas Guzzler
				}
			case 8:
				{
					CreateHat(client, 30473, 10, 6, 1); //MK 50
					CreateHat(client, 30526, 10, 6, 0); //Arsonist Apparatus
					CreateHat(client, 30527, 10, 6, 0); //Moccasin Machinery
				}
			case 9:
				{
					CreateHat(client, 248, 10, 6, 1); //Nappers Respite
					CreateHat(client, 30826, 10, 6, 0); //Sweet Smissmas Sweater
					CreateHat(client, 856, 10, 6, 0); //Pyrothectic Tote
				}
			case 10:
				{
					CreateHat(client, 30567, 10, 6, 1); //Crown of the Old Kingdom
					CreateHat(client, 316, 10, 6, 0); //Pyromancers Mask
					CreateHat(client, 30583, 10, 6, 0); //Torchers Tabard
				}
			case 11:
				{
					CreateHat(client, 30684, 10, 6, 1); //Neptunes Nightmare
					CreateHat(client, 30584, 10, 6, 0); //Charred Chainmail
					CreateHat(client, 30089, 10, 6, 0); //El Muchacho
				}
			case 12:
				{
					CreateHat(client, 783, 10, 6, 1); //Hazmat Headcase
					CreateHat(client, 30580, 10, 6, 0); //Pyromancers Hood
					CreateHat(client, 30664, 10, 6, 0); //Space Diver
				}
			case 13:
				{
					CreateHat(client, 627, 10, 6, 1); //Flamboyant Flamenco
					CreateHat(client, 570, 10, 6, 0); //Last Breath
					CreateHat(client, 30089, 10, 6, 0); //El Muchacho
				}
			case 14:
				{
					CreateHat(client, 30391, 10, 6, 1); //Sengoku Scorcher
					CreateHat(client, 30177, 10, 6, 0); //Hong Kong Cone
					CreateHat(client, 571, 10, 6, 0); //Apparitions Aspect
				}
			case 15:
				{
					CreateHat(client, 105, 10, 6, 1); //Brigade Helm
					CreateHat(client, 30169, 10, 6, 0); //Tricksters Turnout Gear
					CreateHat(client, 30900, 10, 6, 0); //Firemans Essentials
				}
			case 16:
				{
					CreateHat(client, 30357, 10, 6, 1); //Dark Falkirk Helm
					CreateHat(client, 30062, 10, 6, 0); //Steel Sixpack
					CreateHat(client, 30584, 10, 6, 0); //Charred Chainmail
				}
			case 17:
				{
					CreateHat(client, 213, 10, 6, 1); //Attendant
					CreateHat(client, 335, 10, 6, 0); //Fosters Facade
					CreateHat(client, 30400, 10, 6, 0); //Lunatics Leathers
				}
			case 18:
				{
					CreateHat(client, 30063, 10, 6, 1); //Centurion
					CreateHat(client, 30062, 10, 6, 0); //Steel Sixpack
					CreateHat(client, 856, 10, 6, 0); //Pyrotechnic Tote
				}
			case 19:
				{
					CreateHat(client, 30192, 10, 6, 1); //Hard Headed Hardware
					CreateHat(client, 30216, 10, 6, 0); //External Organ
					CreateHat(client, 855, 10, 6, 0); //Vigilant Pin
				}
			case 20:
				{
					CreateHat(client, 30662, 10, 6, 1); //Head Full of Hot Air
					CreateHat(client, 30664, 10, 6, 0); //Space Diver
					CreateHat(client, 30795, 10, 6, 0); //Hovering Hotshot
				}
			case 21:
				{
					CreateHat(client, 976, 10, 6, 1); //Winter Wonderland Wrap
					CreateHat(client, 30826, 10, 6, 0); //Sweet Smissmas Sweater
					CreateHat(client, 1072, 10, 6, 0); //Portable Smissmas Spirit Dispenser
				}
			case 22:
				{
					CreateHat(client, 247, 10, 6, 1); //Old Guadalajara
				}
			case 23:
				{
					CreateHat(client, 394, 10, 6, 1); //Connoisseurs Cap
				}
			case 24:
				{
					CreateHat(client, 377, 10, 6, 1); //Hotties Hoodie
				}
			case 25:
				{
					CreateHat(client, 644, 10, 6, 1); //Head Warmer
					CreateHat(client, 30305, 10, 6, 0); //Sub Zero Suit					
				}
			case 26:
				{
					CreateHat(client, 30304, 10, 6, 1); //Blizzard Breather
					CreateHat(client, 30305, 10, 6, 1); //Sub Zero Suit	
					CreateHat(client, 30308, 10, 6, 0); //Trail Blazer
				}
			case 27:
				{
					CreateHat(client, 744, 10, 6, 1); //Pyrovision Goggles
					CreateHat(client, 733, 10, 6, 0); //Pet Robro
					CreateHat(client, 745, 10, 6, 0); //Infernal Orchestrina
				}
			case 28:
				{
					CreateHat(client, 30418, 10, 6, 1); //Combustible Kabuto
					CreateHat(client, 30391, 10, 6, 0); //Sengoku Scorcher
				}
			case 29:
				{
					CreateHat(client, 30528, 10, 6, 1); //Lollichop Licker
					CreateHat(client, 30544, 10, 6, 0); //North Polar Fleece
				}
			case 30:
				{
					CreateHat(client, 30987, 10, 6, 1); //Burning Question
					CreateHat(client, 30986, 10, 6, 0); //Hot Case	
				}
			case 31:
				{
					CreateHat(client, 30937, 10, 6, 1); //Cats Pajamas
					CreateHat(client, 30706, 10, 6, 0); //catastrophic companions
					CreateHat(client, 30905, 10, 6, 0); //Hot Huaraches
				}
			case 32:
				{
					CreateHat(client, 31041, 10, 6, 1); //Melted Mop
					CreateHat(client, 31051, 10, 6, 0); //Wanderers Wear
					CreateHat(client, 31050, 10, 6, 0); //Spawn Camper
					CreateHat(client, 31047, 10, 6, 0); //Fiery Phoenix					
				}
			case 33:
				{
					CreateHat(client, 31058, 10, 6, 1); //Bat Hat
					CreateHat(client, 31060, 10, 6, 0); //Binoculus
					CreateHat(client, 31061, 10, 6, 0); //Pocket Halloween Boss
				}
			case 34:
				{
					CreateHat(client, 31066, 10, 6, 1); //Skullbrero
					CreateHat(client, 31065, 10, 6, 0); //Head of the Dead
					CreateHat(client, 30716, 10, 6, 0); //Crusaders Getup
				}
			case 35:
				{
					CreateHat(client, 31068, 10, 6, 1); //Pyroshark
					CreateHat(client, 30584, 10, 6, 0); //charred chainmail - armoured appendages
					CreateHat(client, 31050, 10, 6, 0); //Spawn Camper					
				}
			case 36:
				{
					CreateHat(client, 31067, 10, 6, 1); //Candy Cranium
					CreateHat(client, 31051, 10, 6, 0); //Wanderers Wear
					CreateHat(client, 31050, 10, 6, 0); //Spawn Camper					
				}
			case 37:
				{
					CreateHat(client, 31076, 10, 6, 1); //Pyrolantern
					CreateHat(client, 30400, 10, 6, 0); //Lunatics Leathers
					CreateHat(client, 30398, 10, 6, 0); //Gas Guzzler
				}
			case 38:
				{
					CreateHat(client, 291, 10, 6, 1); //Horrific Headsplitter
					CreateHat(client, 31060, 10, 6, 0); //Binoculus			
					CreateHat(client, 30367, 10, 6, 0); //Cute Suit
				}
			case 39:
				{
					CreateHat(client, 1014, 10, 6, 1); //Brutal Bouffant			
					CreateHat(client, 30062, 10, 6, 0); //Steel Sixpack
				}
			case 40:
				{
					CreateHat(client, 31068, 10, 6, 1); //Pyro Shark
					CreateHat(client, 30176, 10, 6, 0); //Pop Eyes			
					CreateHat(client, 30305, 10, 6, 0); //Sub Zero Suit
				}
			case 41:
				{
					CreateHat(client, 31065, 10, 6, 1); //Head of the Dead
					CreateHat(client, 31060, 10, 6, 0); //Binoculus		
					CreateHat(client, 30986, 10, 6, 0); //Hot Case
				}
			case 42:
				{
					CreateHat(client, 1014, 10, 6, 1); //Brutal Bouffant
					CreateHat(client, 31060, 10, 6, 0); //Binoculus		
					CreateHat(client, 30391, 10, 6, 0); //Sengoku Scorcher
				}				
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
		{
			int rnd3 = GetRandomInt(1,35);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 607, 10, 6, 1); //Buccaneers Bicorne
					CreateHat(client, 610, 10, 6, 0); //Whiff of the Old Brimstone
					CreateHat(client, 608, 10, 6, 0); //Bootlegger
				}
			case 2:
				{
					CreateHat(client, 543, 10, 6, 1); //Hair of the Dog
					CreateHat(client, 544, 10, 6, 0); //Scottish Snarl
					CreateHat(client, 545, 10, 6, 0); //Pickled Paws
				}
			case 3:
				{
					CreateHat(client, 30241, 10, 6, 1); //Transylvania Top
					CreateHat(client, 30249, 10, 6, 0); //Lordly Lapels
					CreateHat(client, 922, 10, 6, 0); //Bonedolier
				}
			case 4:
				{
					CreateHat(client, 30516, 10, 6, 1); //Forgotten Kings Restless Head
					CreateHat(client, 30517, 10, 6, 0); //Forgotten Kings Pauldrons
					CreateHat(client, 874, 10, 6, 0); //King of Scotland Cape
				}
			case 5:
				{
					CreateHat(client, 30429, 10, 6, 1); //Allbrero
					CreateHat(client, 30430, 10, 6, 0); //Seeing Double
					CreateHat(client, 30431, 10, 6, 0); //Six Pack Abs
				}
			case 6:
				{
					CreateHat(client, 306, 10, 6, 1); //Scotch Bonnet
					CreateHat(client, 30363, 10, 6, 0); //Juggernaut Jacket
					CreateHat(client, 30179, 10, 6, 0); //Hurt Locher
				}
			case 7:
				{
					CreateHat(client, 30480, 10, 6, 1); //Mann of the Seven Seas
					CreateHat(client, 610, 10, 6, 0); //A Whiff of the Old Brimstone
					CreateHat(client, 607, 10, 6, 0); //Buccaneers Bicorne
				}
			case 8:
				{
					CreateHat(client, 30779, 10, 6, 1); //Dayjogger
					CreateHat(client, 30363, 10, 6, 0); //Juggernaut Jacket
					CreateHat(client, 30550, 10, 6, 0); //Snow Sleeves
				}
			case 9:
				{
					CreateHat(client, 403, 10, 6, 1); //Sultans Ceremonial
					CreateHat(client, 1019, 10, 6, 0); //Blind Justice
					CreateHat(client, 30124, 10, 6, 0); //Gaelic Garb
				}
			case 10:
				{
					CreateHat(client, 359, 10, 6, 1); //Samur Eye
					CreateHat(client, 30742, 10, 6, 0); //Sin Shredders
					CreateHat(client, 30348, 10, 6, 0); //Bushi Dou
				}
			case 11:
				{
					CreateHat(client, 342, 10, 6, 1); //Prince Tavishs Crown
					CreateHat(client, 830, 10, 6, 0); //Bearded Bombardier
					CreateHat(client, 874, 10, 6, 0); //King of Scotland Cape
				}
			case 12:
				{
					CreateHat(client, 30604, 10, 6, 1); //Scot Bonnet
					CreateHat(client, 948, 10, 6, 0); //deadliest duckling
					CreateHat(client, 30587, 10, 6, 0); //Storm Stompers
				}
			case 13:
				{
					CreateHat(client, 30421, 10, 6, 1); //Frontier Djustice
					CreateHat(client, 30788, 10, 6, 0); //Demos Dustcatcher
					CreateHat(client, 734, 10, 6, 0); //Teufort Tooth Kicker
				}
			case 14:
				{
					CreateHat(client, 30357, 10, 6, 1); //Dark Falkirk Helm
					CreateHat(client, 30073, 10, 6, 0); //Dark Age Defender
					CreateHat(client, 30358, 10, 6, 0); //Sole Saviors
				}
			case 15:
				{
					CreateHat(client, 47, 10, 6, 1); //Demomans Fro
					CreateHat(client, 295, 10, 6, 0); //Dangeresque Too
					CreateHat(client, 1016, 10, 6, 0); //Buck Turner All Stars
				}
			case 16:
				{
					CreateHat(client, 30106, 10, 6, 1); //Tartan Spartan
					CreateHat(client, 30073, 10, 6, 0); //Dark Age Defender
					CreateHat(client, 30358, 10, 6, 0); //Sole Saviors
				}
			case 17:
				{
					CreateHat(client, 30628, 10, 6, 1); //Outta Sight
					CreateHat(client, 30541, 10, 6, 0); //Double Dynamite
					CreateHat(client, 30555, 10, 6, 0); //Double Dog Dare Demo Pants
				}
			case 18:
				{
					CreateHat(client, 30064, 10, 6, 1); //Tartan Shade
					CreateHat(client, 30061, 10, 6, 0); //Tartantaloons
					CreateHat(client, 30550, 10, 6, 0); //Snow Sleeves
				}
			case 19:
				{
					CreateHat(client, 126, 10, 6, 1); //Bills Hat
					CreateHat(client, 143, 10, 6, 0); //Earbuds
					CreateHat(client, 619, 10, 6, 0); //Flair
				}
			case 20:
				{
					CreateHat(client, 30954, 10, 6, 1); //Hungover Hero
					CreateHat(client, 30973, 10, 6, 0); //Melody of Misery					
					CreateHat(client, 30945, 10, 6, 0); //Blast Blocker
				}
			case 21:
				{
					CreateHat(client, 30830, 10, 6, 1); //Bomber Knight
					CreateHat(client, 30793, 10, 6, 0); //Aerobatics Demonstrator				
					CreateHat(client, 1016, 10, 6, 0); //Buck Turner All Stars
				}
			case 22:
				{
					CreateHat(client, 30830, 10, 6, 1); //Bomber Knight
					CreateHat(client, 30793, 10, 6, 0); //Aerobatics Demonstrator				
					CreateHat(client, 1016, 10, 6, 0); //Buck Turner All Stars
				}
			case 23:
				{
					CreateHat(client, 30954, 10, 6, 1); //Hungover Hero
					CreateHat(client, 874, 10, 6, 0); //King of Scotland Cape
					CreateHat(client, 30061, 10, 6, 0); //tartantaloons
				}
			case 24:
				{
					CreateHat(client, 30421, 10, 6, 1); //Frontier Djustice
					CreateHat(client, 30541, 10, 6, 0); //Double Dynamite
					CreateHat(client, 734, 10, 6, 0); //Teufort Tooth Kicker
				}
			case 25:
				{
					CreateHat(client, 30519, 10, 6, 1); //Explosive Mind/Mannhattan Project
					CreateHat(client, 30945, 10, 6, 0); //Blast Blocker
					CreateHat(client, 30358, 10, 6, 0); //Sole Saviors
				}
			case 26:
				{
					CreateHat(client, 543, 10, 6, 1); //Hair of the Dog
					CreateHat(client, 544, 10, 6, 0); //Scottish Snarl
					CreateHat(client, 545, 10, 6, 0); //Pickled Paws
				}
			case 27:
				{
					CreateHat(client, 543, 10, 6, 1); //Hair of the Dog
					CreateHat(client, 544, 10, 6, 0); //Scottish Snarl
					CreateHat(client, 545, 10, 6, 0); //Pickled Paws
				}
			case 28:
				{
					CreateHat(client, 543, 10, 6, 1); //Hair of the Dog
					CreateHat(client, 544, 10, 6, 0); //Scottish Snarl
					CreateHat(client, 545, 10, 6, 0); //Pickled Paws
				}
			case 29:
				{
					CreateHat(client, 543, 10, 6, 1); //Hair of the Dog
					CreateHat(client, 544, 10, 6, 0); //Scottish Snarl
					CreateHat(client, 545, 10, 6, 0); //Pickled Paws
				}				
			case 30:
				{
					CreateHat(client, 31017, 10, 6, 1); //Gaelic Glutton
					CreateHat(client, 30555, 10, 6, 0); //Double Dog Dare Pants
					CreateHat(client, 30333, 10, 6, 0); //Highland High Heels
				}
			case 31:
				{
					CreateHat(client, 30723, 10, 6, 1); //Hood of Sorrows
					CreateHat(client, 30973, 10, 6, 0); //Melody of Mystery
					CreateHat(client, 30555, 10, 6, 0); //Double Dog Dare Demo Pants
				}
			case 32:
				{
					CreateHat(client, 31040, 10, 6, 1); //Unforgiven Glory
					CreateHat(client, 31038, 10, 6, 0); //Backbreaker Skullcracker
					CreateHat(client, 31039, 10, 6, 0); //Backbreakers Guards
					CreateHat(client, 31037, 10, 6, 0); //Dynamite Abs
				}
			case 33:
				{
					CreateHat(client, 390, 10, 6, 1); //Reggaelator
					CreateHat(client, 30085, 10, 6, 0); //Macho Mann			
					CreateHat(client, 31037, 10, 6, 0); //Dynamite Abs
				}
			case 34:
				{
					CreateHat(client, 1014, 10, 6, 1); //Brutal Bouffant
					CreateHat(client, 647, 10, 6, 0); //All Father			
					CreateHat(client, 31024, 10, 6, 0); //Gaelic Garb
				}
			case 35:
				{
					CreateHat(client, 359, 10, 6, 1); //Samur Eye
					CreateHat(client, 875, 10, 6, 0); //Menpo		
					CreateHat(client, 30348, 10, 6, 0); //Bushi Dou
					CreateHat(client, 30366, 10, 6, 0); //Sangu Sleeves
					CreateHat(client, 30742, 10, 6, 0); //Shin Shredders					
				}				
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Heavy)
		{
			int rnd3 = GetRandomInt(1,44);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 561, 10, 6, 1); //Can Opener
					CreateHat(client, 562, 10, 6, 0); //Soviet Stitchup
					CreateHat(client, 563, 10, 6, 0); //Steel Toed Stompers				
				}
			case 2:
				{
					CreateHat(client, 930, 10, 6, 1); //Grand Duchess Tiara
					CreateHat(client, 931, 10, 6, 0); //Grand Duchess Fairy Wings
					CreateHat(client, 932, 10, 6, 0); //Grand Duchess Tutu	
				}
			case 3:
				{
					CreateHat(client, 30533, 10, 6, 1); //Minsk Beef
					CreateHat(client, 30532, 10, 6, 0); //Bull Locks
					CreateHat(client, 30531, 10, 6, 0); //Bone Cut Belt
				}
			case 4:
				{
					CreateHat(client, 1187, 10, 6, 1); //Yeti Head
					CreateHat(client, 1189, 10, 6, 0); //Yeti Arms
					CreateHat(client, 1188, 10, 6, 0); //Yeti Legs
				}
			case 5:
				{
					CreateHat(client, 30959, 10, 6, 1); //Sinners Shade
					CreateHat(client, 30960, 10, 6, 0); //Wild West Whiskers
					CreateHat(client, 777, 10, 6, 0); //Apparatchiks Apparel
				}
			case 6:
				{
					CreateHat(client, 601, 10, 6, 1); //One Man Army
					CreateHat(client, 30138, 10, 6, 0); //Bolshevik Biker
					CreateHat(client, 30343, 10, 6, 0); //Gone Commando
				}
			case 7:
				{
					CreateHat(client, 30912, 10, 6, 1); //Commando Elite
					CreateHat(client, 30913, 10, 6, 0); //Siberian Tigerstripe
					CreateHat(client, 30372, 10, 6, 0); //Combat Slacks
				}
			case 8:
				{
					CreateHat(client, 30885, 10, 6, 1); //Nuke
					CreateHat(client, 30913, 10, 6, 0); //Siberian Tigerstripe
					CreateHat(client, 30372, 10, 6, 0); //Combat Slacks
				}
			case 9:
				{
					CreateHat(client, 1087, 10, 6, 1); //Der Maschinensoldaten Helm
					CreateHat(client, 1088, 10, 6, 0); //Die Regime Panzerung
					CreateHat(client, 30372, 10, 6, 0); //Combat Slacks
				}
			case 10:
				{
					CreateHat(client, 1087, 10, 6, 1); //Soviet Gentleman
					CreateHat(client, 30913, 10, 6, 0); //Siberian Tigerstripe
					CreateHat(client, 30563, 10, 6, 0); //Jungle Booty
				}
			case 11:
				{
					CreateHat(client, 601, 10, 6, 1); //One Man Army
					CreateHat(client, 30165, 10, 6, 0); //Cuban Bristle Crisis
					CreateHat(client, 30414, 10, 6, 0); //Eye Catcher
				}
			case 12:
				{
					CreateHat(client, 30344, 10, 6, 1); //Bullet Buzz
					CreateHat(client, 30342, 10, 6, 0); //Heavy Lifter
					CreateHat(client, 30104, 10, 6, 0); //Greybanns
				}
			case 13:
				{
					CreateHat(client, 330, 10, 6, 1); //Coupe Disaster
					CreateHat(client, 946, 10, 6, 0); //Siberian Sophisticate
					CreateHat(client, 30319, 10, 6, 0); //Mann of the House
				}
			case 14:
				{
					CreateHat(client, 145, 10, 6, 1); //Hound Dog
					CreateHat(client, 30803, 10, 6, 0); //Heavy Tourism
					CreateHat(client, 990, 10, 6, 0); //Aqua Flops
				}
			case 15:
				{
					CreateHat(client, 30589, 10, 6, 1); //Old Man Frost
					CreateHat(client, 30747, 10, 6, 0); //Gift Bringer
					CreateHat(client, 30972, 10, 6, 0); //Pocket Santa
				}
			case 16:
				{
					CreateHat(client, 1187, 10, 6, 1); //Yeti Head
					CreateHat(client, 1189, 10, 6, 0); //Yeti Arms
					CreateHat(client, 1188, 10, 6, 0); //Yeti Legs
				}
			case 17:
				{
					CreateHat(client, 30914, 10, 6, 1); //Aztec Aggressor
					CreateHat(client, 30910, 10, 6, 0); //Heavy Harness
					CreateHat(client, 30563, 10, 6, 0); //Jungle Booty
				}
			case 18:
				{
					CreateHat(client, 30887, 10, 6, 1); //War Eagle
					CreateHat(client, 30910, 10, 6, 0); //Heavy Harness
					CreateHat(client, 30563, 10, 6, 0); //Jungle Booty
				}
			case 19:
				{
					CreateHat(client, 30866, 10, 6, 1); //WarHood
					CreateHat(client, 30873, 10, 6, 0); //Airborne Attire
					CreateHat(client, 1097, 10, 6, 0); //Little Bear
				}
			case 20:
				{
					CreateHat(client, 30644, 10, 6, 1); //White Russian
					CreateHat(client, 30645, 10, 6, 0); //El Duderino
					CreateHat(client, 30633, 10, 6, 0); //Commisars Coat
				}
			case 21:
				{
					CreateHat(client, 30653, 10, 6, 1); //Sucker Slug
					CreateHat(client, 30557, 10, 6, 0); //Hunter Heavy
					CreateHat(client, 30079, 10, 6, 0); //Red Army Robin			
				}
			case 22:
				{
					CreateHat(client, 30588, 10, 6, 1); //Siberian Face Hugger (heavy_parka)
					CreateHat(client, 30550, 10, 6, 0); //Snow Sleeves
					CreateHat(client, 30929, 10, 6, 0); //Pocket Yeti				
				}
			case 23:
				{
					CreateHat(client, 30815, 10, 6, 1); //Mad Mask
					CreateHat(client, 30557, 10, 6, 0); //Hunter Heavy (EOTL Sheavyshirt)
					CreateHat(client, 30354, 10, 6, 0); //Rat Stompers				
				}
			case 24:
				{
					CreateHat(client, 30960, 10, 6, 1); //Wild West Whiskers
					CreateHat(client, 30633, 10, 6, 0); //Commissars Coat
					CreateHat(client, 392, 10, 6, 0); //Pocket Medic
				}
			case 25:
				{
					CreateHat(client, 478, 10, 6, 1); //Coppers Hard Top
					CreateHat(client, 479, 10, 6, 0); //Security Shades
					CreateHat(client, 30319, 10, 6, 0); //Mann of the House
				}
			case 26:
				{
					CreateHat(client, 743, 10, 6, 1); //Pyrovision Goggles
					CreateHat(client, 1012, 10, 6, 0); //Wilson Weave
					CreateHat(client, 30563, 10, 6, 0); //Jungle Booty
				}
			case 27:
				{
					CreateHat(client, 30589, 10, 6, 1); //Old Man Frost
					CreateHat(client, 30747, 10, 6, 0); //Gift Bringer
					CreateHat(client, 30972, 10, 6, 0); //Pocket Santa
				}
			case 28:
				{
					CreateHat(client, 30122, 10, 6, 1); //Bear Necessities
					CreateHat(client, 30138, 10, 6, 0); //Bolshevik Biker
					CreateHat(client, 30319, 10, 6, 0); //Mann of the House
				}
			case 29:
				{
					CreateHat(client, 603, 10, 6, 1); //Outdoorsman
					CreateHat(client, 777, 10, 6, 0); //Apparatchiks Apparel
					CreateHat(client, 392, 10, 6, 0); //Pocket Medic
				}
			case 30:
				{
					CreateHat(client, 31029, 10, 6, 1); //Cool Capuchon
					CreateHat(client, 31030, 10, 6, 0); //Paka Parka
				}
			case 31:
				{
					CreateHat(client, 30959, 10, 6, 1); //Sinners Shade
					CreateHat(client, 30960, 10, 6, 0); //Wild West Whiskers
					CreateHat(client, 777, 10, 6, 0); //Apparatchiks Apparel
				}
			case 32:
				{
					CreateHat(client, 821, 10, 6, 1); //Soviet Gentleman
					CreateHat(client, 777, 10, 6, 0); //Apparatchiks Apparel
				}
			case 33:
				{
					CreateHat(client, 30980, 10, 6, 1); //Tsar Platinum
					CreateHat(client, 30981, 10, 6, 0); //Starboard Crusader	
				}
			case 34:
				{
					CreateHat(client, 30964, 10, 6, 1); //Polar Bear
					CreateHat(client, 30980, 10, 6, 0); //Tsar Platinum
				}
			case 35:
				{
					CreateHat(client, 1187, 10, 6, 1); //Kathman Hairdo
					CreateHat(client, 1189, 10, 6, 0); //Himalayan Hair Shirt
					CreateHat(client, 1188, 10, 6, 0); //Abominable Snow Pants				
				}
			case 36:
				{
					CreateHat(client, 30885, 10, 6, 1); //Nuke
					CreateHat(client, 30342, 10, 6, 0); //Heavy Lifter
					CreateHat(client, 30343, 10, 6, 0); //Gone Commando			
				}
			case 37:
				{
					CreateHat(client, 30866, 10, 6, 1); //Warhood
					CreateHat(client, 30873, 10, 6, 0); //Airborne Attire
					CreateHat(client, 30343, 10, 6, 0); //Gone Commando			
				}
			case 38:
				{
					CreateHat(client, 30644, 10, 6, 1); //White Russian
					CreateHat(client, 30803, 10, 6, 0); //Heavy Tourism
					CreateHat(client, 30343, 10, 6, 0); //Jungle Booty			
				}
			case 39:
				{
					CreateHat(client, 31052, 10, 6, 1); //Mediterranean Mercenary
					CreateHat(client, 31053, 10, 6, 0); //Kapitans Kaftan
				}
			case 40:
				{
					CreateHat(client, 31080, 10, 6, 1); //Convict Hat
					CreateHat(client, 31079, 10, 6, 0); //Soviet Strongmann
					CreateHat(client, 30343, 10, 6, 0); //Gone Commando
				}
			case 41:
				{
					CreateHat(client, 185, 10, 6, 1); //Heavy Duty
					CreateHat(client, 30342, 10, 6, 0); //Heavy Lifter			
					CreateHat(client, 30368, 10, 6, 0); //War Goggles
				}
			case 42:
				{
					CreateHat(client, 97, 10, 6, 1); //Tough Guys Toque
					CreateHat(client, 987, 10, 6, 0); //Mercs Muffler			
					CreateHat(client, 30079, 10, 6, 0); //Red Army Robin
				}
			case 43:
				{
					CreateHat(client, 96, 10, 6, 1); //Officers Ushanka
					CreateHat(client, 30306, 10, 6, 0); //Dictator			
					CreateHat(client, 30633, 10, 6, 0); //Comissars Coat
				}
			case 44:
				{
					CreateHat(client, 31178, 10, 6, 1); //SandManns Brush
					CreateHat(client, 31179, 10, 6, 0); //BedBug Protection
					CreateHat(client, 31180, 10, 6, 0); //Bear Walker
				}				
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			int rnd3 = GetRandomInt(1,36);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 567, 10, 6, 1); //Buzz Killer
					CreateHat(client, 568, 10, 6, 0); //Frontier Flyboy
					CreateHat(client, 569, 10, 6, 0); //Legend of Bugfoot
				}
			case 2:
				{
					CreateHat(client, 591, 10, 6, 1); //Braniac Goggles
					CreateHat(client, 590, 10, 6, 0); //Brainiac Hairpiece				
					CreateHat(client, 519, 10, 6, 0); //Pip Boy
				}
			case 3:
				{
					CreateHat(client, 30407, 10, 6, 1); //Level Three Chin
					CreateHat(client, 30408, 10, 6, 0); //Eggheads Overalls			
					CreateHat(client, 30409, 10, 6, 0); //Lonesome Loafers
				}
			case 4:
				{
					CreateHat(client, 30871, 10, 6, 1); //Flash of Inspiration
					CreateHat(client, 30402, 10, 6, 0); //Tools of the Trade			
					CreateHat(client, 30403, 10, 6, 0); //Joe on the Go
				}
			case 5:
				{
					CreateHat(client, 94, 10, 6, 1); //Texas Ten Gallon
					CreateHat(client, 30785, 10, 6, 0); //Dad Duds		
					CreateHat(client, 30172, 10, 6, 0); //Gold Digger
				}
			case 6:
				{
					CreateHat(client, 988, 10, 6, 1); //Barnstormer
					CreateHat(client, 30330, 10, 6, 0); //Dogfighter			
					CreateHat(client, 30347, 10, 6, 0); //Scotch Saver
				}
			case 7:
				{
					CreateHat(client, 94, 10, 6, 1); //Texas Ten Gallon
					CreateHat(client, 30085, 10, 6, 0); //Macho Mann	
					CreateHat(client, 986, 10, 6, 0); //Mutton Mann
				}
			case 8:
				{
					CreateHat(client, 126, 10, 6, 1); //Bills Hat
					CreateHat(client, 30605, 10, 6, 0); //Thermal Insulation Layer	
					CreateHat(client, 30172, 10, 6, 0); //Gold Digger
				}
			case 9:
				{
					CreateHat(client, 30085, 10, 6, 1); //Macho Mann
					CreateHat(client, 30805, 10, 6, 0); //Wide Brimmed Bandito		
					CreateHat(client, 30804, 10, 6, 0); //El Paso Poncho
				}
			case 10:
				{
					CreateHat(client, 486, 10, 6, 1); //Summer Shades
					CreateHat(client, 30634, 10, 6, 0); //Sheriffs Stetson	
					CreateHat(client, 30397, 10, 6, 0); //Bruisers Bandanna
				}
			case 11:
				{
					CreateHat(client, 30362, 10, 6, 1); ///The Law
					CreateHat(client, 486, 10, 6, 0); //Summer Shades
					CreateHat(client, 30681, 10, 6, 0); //El Patron
				}
			case 12:
				{
					CreateHat(client, 30509, 10, 6, 1); //Beep Man
					CreateHat(client, 30337, 10, 6, 0); //Trenchers Tunic				
					CreateHat(client, 30167, 10, 6, 0); //Beep Boy
				}
			case 13:
				{
					CreateHat(client, 30341, 10, 6, 1); //Ein
					CreateHat(client, 30330, 10, 6, 0); //Dogfighter
					CreateHat(client, 30347, 10, 6, 0); //Scotch Saver
				}
			case 14:
				{
					CreateHat(client, 30336, 10, 6, 1); //Trenchers Topper
					CreateHat(client, 30337, 10, 6, 0); //Trenchers Tunic
					CreateHat(client, 30070, 10, 6, 0); //Pocket Pyro					
				}
			case 15:
				{
					CreateHat(client, 492, 10, 6, 1); //Summer Hat
					CreateHat(client, 486, 10, 6, 0); //Summer Shades
					CreateHat(client, 30172, 10, 6, 0); //Gold Digger
				}
			case 16:
				{
					CreateHat(client, 30407, 10, 6, 1); //Level Three Chin
					CreateHat(client, 30362, 10, 6, 0); //Law
					CreateHat(client, 296, 10, 6, 0); //License to Maim
				}
			case 17:
				{
					CreateHat(client, 611, 10, 6, 1); //Salty Dog
					CreateHat(client, 30785, 10, 6, 0); //Dad Duds
					CreateHat(client, 30347, 10, 6, 0); //Scotch Saver
				}
			case 18:
				{
					CreateHat(client, 30367, 10, 6, 1); //Cute Suit
					CreateHat(client, 30168, 10, 6, 0); //Special Eyes
					CreateHat(client, 30066, 10, 6, 0); //Brotherhood of Arms
				}
			case 19:
				{
					CreateHat(client, 30846, 10, 6, 1); //Plumbers Cap
					CreateHat(client, 30590, 10, 6, 0); //Holstered Heaters
					CreateHat(client, 823, 10, 6, 0); //Pocket Purrer
				}
			case 20:
				{
					CreateHat(client, 30406, 10, 6, 1); //Peaceniks Ponytail
					CreateHat(client, 30884, 10, 6, 0); //Aloha Apparel
					CreateHat(client, 30409, 10, 6, 0); //Lonesome Loafers
				}
			case 21:
				{
					CreateHat(client, 30681, 10, 6, 1); //El Patron
					CreateHat(client, 30785, 10, 6, 0); //Dad Duds
					CreateHat(client, 823, 10, 6, 0); //Pocket Purrer
				}
			case 22:
				{
					CreateHat(client, 338, 10, 6, 1); //Industrial Festivizer
					CreateHat(client, 30322, 10, 6, 0); //Face Full of Festive
					CreateHat(client, 30821, 10, 6, 0); //Packable Provisions
				}
			case 23:
				{
					CreateHat(client, 533, 10, 6, 1); //Clockwerks Helm
					CreateHat(client, 606, 10, 6, 0); //Builders Blueprints
					CreateHat(client, 519, 10, 6, 0); //Pip Boy
				}
			case 24:
				{
					CreateHat(client, 30099, 10, 6, 1); //Pardners Pompadour
					CreateHat(client, 30113, 10, 6, 0); //Flared Frontiersman
					CreateHat(client, 30087, 10, 6, 0); //Dry Gulch Gulp
				}
			case 25:
				{
					CreateHat(client, 30322, 10, 6, 1); //Face Full of Festive
					CreateHat(client, 743, 10, 6, 0); //Pyrovision Goggles
					CreateHat(client, 30330, 10, 6, 0); //Dogfighter
				}
			case 26:
				{
					CreateHat(client, 988, 10, 6, 1); //Barnstormer
					CreateHat(client, 986, 10, 6, 0); //Mutton Mann
					CreateHat(client, 1008, 10, 6, 0); //Prize Plushy
				}
			case 27:
				{
					CreateHat(client, 30511, 10, 6, 1); //Tiny Texan
					CreateHat(client, 784, 10, 6, 0); //Idea Tube				
					CreateHat(client, 386, 10, 6, 0); //Teddy Roosebelt
				}
			case 28:
				{
					CreateHat(client, 30707, 10, 6, 1); //Deader Alive
					CreateHat(client, 30655, 10, 6, 0); //Rocket Operator
					CreateHat(client, 30654, 10, 6, 0); //Life Support System
				}
			case 29:
				{
					CreateHat(client, 30634, 10, 6, 1); //Sheriffs Stetson
					CreateHat(client, 30635, 10, 6, 0); //Wild West Waistcoat
					CreateHat(client, 30629, 10, 6, 0); //Support Spurs
				}					
			case 30:
				{
					CreateHat(client, 31031, 10, 6, 1); //Wise Whiskers
					CreateHat(client, 31032, 10, 6, 0); //Puggyback
					CreateHat(client, 30409, 10, 6, 0); //Lonesome Loafers
				}
			case 31:
				{
					CreateHat(client, 30871, 10, 6, 1); //Flash of Inspiration
					CreateHat(client, 30992, 10, 6, 0); //Cold Case
					CreateHat(client, 30908, 10, 6, 0); //Conaghers Utility Idol
					CreateHat(client, 30975, 10, 6, 0); //Robin Walkers
				}	
			case 32:
				{
					CreateHat(client, 30977, 10, 6, 1); //Antarctic Eyewear
					CreateHat(client, 30992, 10, 6, 0); //Cold Case
					CreateHat(client, 30909, 10, 6, 0); //Tropical Toad
				}
			case 33:
				{
					CreateHat(client, 30872, 10, 6, 1); //Head Mounted Double Observatory
					CreateHat(client, 30877, 10, 6, 0); //Hunter in Darkness
					CreateHat(client, 30884, 10, 6, 0); //Aloha Apparel
				}
			case 34:
				{
					CreateHat(client, 988, 10, 6, 1); //Barnstormer
					CreateHat(client, 30794, 10, 6, 0); //Final Frontier Freighter
					CreateHat(client, 30884, 10, 6, 0); //Aloha Apparel
					CreateHat(client, 30975, 10, 6, 0); //Robin Walkers					
				}
			case 35:
				{
					CreateHat(client, 31074, 10, 6, 1); //El Mostacho
					CreateHat(client, 30804, 10, 6, 0); //El Paso Poncho
					CreateHat(client, 30629, 10, 6, 0); //Support Spurs					
				}
			case 36:
				{
					CreateHat(client, 31075, 10, 6, 1); //Eingineer
					CreateHat(client, 30337, 10, 6, 0); //Trenchers Tunic					
					CreateHat(client, 31013, 10, 6, 0); //Mini Engy
				}
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			int rnd3 = GetRandomInt(1,38);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 552, 10, 6, 1); //Einstein
					CreateHat(client, 553, 10, 6, 0); //Dr Gogglestache
					CreateHat(client, 554, 10, 6, 0); //Emerald Jarate
				}
			case 2:
				{
					CreateHat(client, 388, 10, 6, 1); //Private Eye
					CreateHat(client, 657, 10, 6, 0); //Nine Pipe Problem
					CreateHat(client, 30096, 10, 6, 0); //Das Feelinbeterbager
				}
			case 3:
				{
					CreateHat(client, 30658, 10, 6, 1); //Universal Translator
					CreateHat(client, 30230, 10, 6, 0); //Surgeons Space Suit
					CreateHat(client, 30229, 10, 6, 0); //Low Grav Loafers
				}
			case 4:
				{
					CreateHat(client, 30293, 10, 6, 1); //Teutonkahmun
					CreateHat(client, 30299, 10, 6, 0); //Ramses Regalia
					CreateHat(client, 30279, 10, 6, 0); //Archimedes the Undying					
				}
			case 5:
				{
					CreateHat(client, 30487, 10, 6, 1); //Hundkopf
					CreateHat(client, 30486, 10, 6, 0); //Herzensbrecher
					CreateHat(client, 30488, 10, 6, 0); //Kriegsmaschine 9000
				}
			case 6:
				{
					CreateHat(client, 30489, 10, 6, 1); //Transylvanian Toupe
					CreateHat(client, 30490, 10, 6, 0); //Vampiric Vesture
					CreateHat(client, 30198, 10, 6, 0); //Pocket Horsemann
				}
			case 7:
				{
					CreateHat(client, 30514, 10, 6, 1); //Templars Spirit
					CreateHat(client, 30515, 10, 6, 0); //Wings of Purity
					CreateHat(client, 30483, 10, 6, 0); //Pocket Heavy
				}
			case 8:
				{
					CreateHat(client, 30939, 10, 6, 1); //Coldfront Commander
					CreateHat(client, 30940, 10, 6, 0); //Coldfront Carapace
					CreateHat(client, 30929, 10, 6, 0); //Pocket Yeti
				}
			case 9:
				{
					CreateHat(client, 30907, 10, 6, 1); //Battle Boonie
					CreateHat(client, 30906, 10, 6, 0); //Vitals Vest
					CreateHat(client, 30483, 10, 6, 0); //Pocket Heavy
				}
			case 10:
				{
					CreateHat(client, 30862, 10, 6, 1); //Field Practice
					CreateHat(client, 30817, 10, 6, 0); //Burly Beast
					CreateHat(client, 30773, 10, 6, 0); //Surgical Survivalist
				}
			case 11:
				{
					CreateHat(client, 30786, 10, 6, 1); //Gauzed Gaze
					CreateHat(client, 30750, 10, 6, 0); //Medical Monarch
					CreateHat(client, 30379, 10, 6, 0); //Gaiter Guards
				}
			case 12:
				{
					CreateHat(client, 30755, 10, 6, 1); //Berlin Brain Bowl
					CreateHat(client, 30756, 10, 6, 0); //Bunnyhoppers Ballistics Vest
					CreateHat(client, 30773, 10, 6, 0); //Surgical Survivalist
				}
			case 13:
				{
					CreateHat(client, 30625, 10, 6, 1); //Physicians Protector
					CreateHat(client, 30626, 10, 6, 0); //Vascular Vestment
					CreateHat(client, 30607, 10, 6, 0); //Pocket Raiders
				}
			case 14:
				{
					CreateHat(client, 30596, 10, 6, 1); //Surgeons Shako
					CreateHat(client, 30490, 10, 6, 0); //Vampiric Vesture
					CreateHat(client, 30483, 10, 6, 0); //Pocket Heavy
				}
			case 15:
				{
					CreateHat(client, 30351, 10, 6, 1); //Teutonic Toque
					CreateHat(client, 30419, 10, 6, 0); //Chronoscarf
					CreateHat(client, 30323, 10, 6, 0); //Ruffled Ruprecht
				}
			case 16:
				{
					CreateHat(client, 30311, 10, 6, 1); //Nunhood
					CreateHat(client, 30356, 10, 6, 0); //Heat of Winter
					CreateHat(client, 30929, 10, 6, 0); //Pocket Yeti
				}
			case 17:
				{
					CreateHat(client, 30351, 10, 6, 1); //Teutonic Toque
					CreateHat(client, 30350, 10, 6, 0); //Dough Puncher
					CreateHat(client, 554, 10, 6, 0); //Emerald Jarate
				}
			case 18:
				{
					CreateHat(client, 30233, 10, 6, 1); //Trepanabotomizer
					CreateHat(client, 30197, 10, 6, 0); //Second Opinion
					CreateHat(client, 30279, 10, 6, 0); //Archimedes the Undying
				}
			case 19:
				{
					CreateHat(client, 30237, 10, 6, 1); //Medimedes
					CreateHat(client, 30171, 10, 6, 0); //Medical Mystery
					CreateHat(client, 828, 10, 6, 0); //Archimedes
				}
			case 20:
				{
					CreateHat(client, 30224, 10, 6, 1); //Alternative Medicine Mann
					CreateHat(client, 30190, 10, 6, 0); //Ward
					CreateHat(client, 30693, 10, 6, 0); //Grim Tweeter
				}
			case 21:
				{
					CreateHat(client, 30121, 10, 6, 1); //Das Maddendoktor
					CreateHat(client, 30098, 10, 6, 0); //Das Metalmeatencasen
					CreateHat(client, 30109, 10, 6, 0); //Das Naggenvatcher
				}
			case 22:
				{
					CreateHat(client, 1039, 10, 6, 1); //Weather Master
					CreateHat(client, 30137, 10, 6, 0); //Das Fantzipantzen
					CreateHat(client, 30096, 10, 6, 0); //Das Feelinbeterbager
				}
			case 23:
				{
					CreateHat(client, 867, 10, 6, 1); //Combat Medics Crusher Cap
					CreateHat(client, 986, 10, 6, 0); //Mutton Mann
					CreateHat(client, 878, 10, 6, 0); //Foppish Physician
				}				
			case 24:
				{
					CreateHat(client, 978, 10, 6, 1); //Der Wintermantel
					CreateHat(client, 30042, 10, 6, 0); //Platinum Pickelhaube
					CreateHat(client, 30050, 10, 6, 0); //Steam Pipe
				}
			case 25:
				{
					CreateHat(client, 616, 10, 6, 1); //Surgeons Stahlhelm
					CreateHat(client, 621, 10, 6, 0); //Surgeons Stethoscope
					CreateHat(client, 144, 10, 6, 0); //Physicians Procedure Mask
				}
			case 26:
				{
					CreateHat(client, 30069, 10, 6, 1); //Powdered Practitioner
					CreateHat(client, 30186, 10, 6, 0); //A Brush with Death
					CreateHat(client, 30361, 10, 6, 0); //Colonels Coat
				}
			case 27:
				{
					CreateHat(client, 30514, 10, 6, 1); //Templars Spirit
					CreateHat(client, 30515, 10, 6, 0); //Wings of Purity
					CreateHat(client, 30483, 10, 6, 0); //Pocket Heavy
				}
			case 28:
				{
					CreateHat(client, 30939, 10, 6, 1); //Coldfront Commander
					CreateHat(client, 30940, 10, 6, 0); //Coldfront Carapace
					CreateHat(client, 30929, 10, 6, 0); //Pocket Yeti
				}
			case 29:
				{
					CreateHat(client, 30487, 10, 6, 1); //Hundkopf
					CreateHat(client, 30486, 10, 6, 0); //Herzensbrecher
					CreateHat(client, 30488, 10, 6, 0); //Kriegsmaschine 9000
				}
			case 30:
				{
					CreateHat(client, 31028, 10, 6, 1); //Snowcapped
					CreateHat(client, 30773, 10, 6, 0); //Surgical Survivalist
					CreateHat(client, 31033, 10, 6, 0); //Harry
				}
			case 31:
				{
					CreateHat(client, 378, 10, 6, 1); //Team Captain
					CreateHat(client, 657, 10, 6, 0); //Nine Pipe Problem
					CreateHat(client, 30982, 10, 6, 0); //Scourge of the Sky
				}
			case 32:
				{
					CreateHat(client, 30907, 10, 6, 1); //Battle Boonie
					CreateHat(client, 30626, 10, 6, 0); //Vascular Vestment
					CreateHat(client, 30813, 10, 6, 0); //Surgeons Sidearms
				}
			case 33:
				{
					CreateHat(client, 31077, 10, 6, 1); //Madmanns Muzzle
					CreateHat(client, 31078, 10, 6, 0); //Derangement Garment
				}
			case 34:
				{
					CreateHat(client, 30127, 10, 6, 1); //Das Gutenkutteharen
					CreateHat(client, 30085, 10, 6, 0); //Macho Mann			
					CreateHat(client, 30817, 10, 6, 0); //Burly Beast
				}
			case 35:
				{
					CreateHat(client, 162, 10, 6, 1); //Maxs Severed Head
					CreateHat(client, 1014, 10, 6, 0); //Brutal Bouffant			
					CreateHat(client, 30817, 10, 6, 0); //Burly Beast
				}
			case 36:
				{
					CreateHat(client, 30755, 10, 6, 1); //Berlin Brain Bowl
					CreateHat(client, 30626, 10, 6, 0); //Vascular Vestment			
					CreateHat(client, 30773, 10, 6, 0); //Surgical Survivalist
				}
			case 37:
				{
					CreateHat(client, 30838, 10, 6, 1); //Head Prize
					CreateHat(client, 30323, 10, 6, 0); //Ruffled Ruprecht			
					CreateHat(client, 30982, 10, 6, 0); //Scourge of the Sky
				}
			case 38:
				{
					CreateHat(client, 31176, 10, 6, 1); //Elf Care Provider
					CreateHat(client, 31177, 10, 6, 0); //NightWard
					CreateHat(client, 31163, 10, 6, 0); //Particulate Protector
					CreateHat(client, 31078, 10, 6, 0); //Derangement Garment	
				}				
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Sniper)
		{
			int rnd3 = GetRandomInt(1,40);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 30504, 10, 6, 1); //Marsupial Muzzle
					CreateHat(client, 30502, 10, 6, 0); //Kanga Kickers
					CreateHat(client, 30503, 10, 6, 0); //Roo Rippers
				}
			case 2:
				{
					CreateHat(client, 564, 10, 6, 1); //Holy Hunter
					CreateHat(client, 565, 10, 6, 0); //Silver Bullets
					CreateHat(client, 566, 10, 6, 0); //Garlic Flank Stake
				}
			case 3:
				{
					CreateHat(client, 30423, 10, 6, 1); //Scopers Smoke
					CreateHat(client, 30424, 10, 6, 0); //Triggermans Tacticals
					CreateHat(client, 30929, 10, 6, 0); //Pocket Yeti
				}
			case 4:
				{
					CreateHat(client, 518, 10, 6, 1); //Anger
					CreateHat(client, 30100, 10, 6, 0); //Birdman of Australiacatraz
					CreateHat(client, 30371, 10, 6, 0); //Archers Groundings
				}
			case 5:
				{
					CreateHat(client, 30066, 10, 6, 1); //Brotherhood of Arms
					CreateHat(client, 393, 10, 6, 0); //Villains Veil
					CreateHat(client, 486, 10, 6, 0); //Summer Shades
				}
			case 6:
				{
					CreateHat(client, 162, 10, 6, 1); //Maxs Severed Head
					CreateHat(client, 30413, 10, 6, 0); //Mercs Mohawk
					CreateHat(client, 30597, 10, 6, 0); //Bushmans Bristles
				}
			case 7:
				{
					CreateHat(client, 30375, 10, 6, 1); //Deep Cover Operator
					CreateHat(client, 30317, 10, 6, 0); //Five Month Shadow
					CreateHat(client, 30649, 10, 6, 0); //Final Frontiersman
				}
			case 8:
				{
					CreateHat(client, 30598, 10, 6, 1); //Professionals Ushanka
					CreateHat(client, 393, 10, 6, 0); //Villains Veil
					CreateHat(client, 30310, 10, 6, 0); //Snow Scoper
				}
			case 9:
				{
					CreateHat(client, 393, 10, 6, 1); //Villains Veil
					CreateHat(client, 30373, 10, 6, 0); //Toowoomba Tunic
					CreateHat(client, 981, 10, 6, 0); //Cold Killer
				}
			case 10:
				{
					CreateHat(client, 400, 10, 6, 1); //Desert Marauder
					CreateHat(client, 393, 10, 6, 0); //Villains Veil
					CreateHat(client, 110, 10, 6, 0); //Master Yellow Belt
				}
			case 11:
				{
					CreateHat(client, 1095, 10, 6, 1); //Dread Hiding Hood
					CreateHat(client, 30424, 10, 6, 0); //Triggermans Tacticals
					CreateHat(client, 30170, 10, 6, 0); //Chronomancer
				}
			case 12:
				{
					CreateHat(client, 30316, 10, 6, 1); //Toy Soldier
					CreateHat(client, 986, 10, 6, 0); //Mutton Mann
					CreateHat(client, 30324, 10, 6, 0); //Golden Garment
				}
			case 13:
				{
					CreateHat(client, 30067, 10, 6, 1); //Well Rounded Rifleman
					CreateHat(client, 30424, 10, 6, 0); //Triggermans Tacticals
					CreateHat(client, 30478, 10, 6, 0); //Poachers Safari Jacket
				}
			case 14:
				{
					CreateHat(client, 783, 10, 6, 1); //Hazmat Headcase
					CreateHat(client, 117, 10, 6, 0); //Ritzy Ricks Hair Fixative
					CreateHat(client, 30649, 10, 6, 0); //Final Fontiersman
				}
			case 15:
				{
					CreateHat(client, 30173, 10, 6, 1); //Brim Full of Bullets
					CreateHat(client, 30317, 10, 6, 0); //Five Month Shadow
					CreateHat(client, 30170, 10, 6, 0); //Chronomancer
				}
			case 16:
				{
					CreateHat(client, 1022, 10, 6, 1); //Sydney Straw Boat
					CreateHat(client, 986, 10, 6, 0); //Mutton Mann
					CreateHat(client, 645, 10, 6, 0); //Outback Intellectual
				}
			case 17:
				{
					CreateHat(client, 261, 10, 6, 1); //Mann Co Cap
					CreateHat(client, 522, 10, 6, 0); //Deus Specs
					CreateHat(client, 30923, 10, 6, 0); //Sledders Sidekick
				}
			case 18:
				{
					CreateHat(client, 314, 10, 6, 1); //Larrikin Robin
					CreateHat(client, 30373, 10, 6, 0); //Toowoomba Tunic
					CreateHat(client, 30789, 10, 6, 0); //Scoped Spartan
				}
			case 19:
				{
					CreateHat(client, 30648, 10, 6, 1); //Corona Australis
					CreateHat(client, 30649, 10, 6, 0); //Final Frontiersman
					CreateHat(client, 30650, 10, 6, 0); //Starduster
				}
			case 20:
				{
					CreateHat(client, 30170, 10, 6, 1); //Chronomancer
					CreateHat(client, 30423, 10, 6, 0); //Scopers Smoke
					CreateHat(client, 30067, 10, 6, 0); //Well Rounded Rifleman
				}
			case 21:
				{
					CreateHat(client, 30317, 10, 6, 1); //Five Month Shadow
					CreateHat(client, 30324, 10, 6, 0); //Golden Garment
					CreateHat(client, 824, 10, 6, 0); //Koala Compact
				}
			case 22:
				{
					CreateHat(client, 30958, 10, 6, 1); //Puffy Polar Cap
					CreateHat(client, 30971, 10, 6, 0); //Down Tundra Coat
					CreateHat(client, 30995, 10, 6, 0); //Handsome Hitman
				}
			case 23:
				{
					CreateHat(client, 30858, 10, 6, 1); //Hawk Eyed Hunter
					CreateHat(client, 30892, 10, 6, 0); //Conspicuous Camoflage
					CreateHat(client, 30891, 10, 6, 0); //Cammy Jammies
				}
			case 24:
				{
					CreateHat(client, 30893, 10, 6, 1); //Classy Capper
					CreateHat(client, 30894, 10, 6, 0); //Most Dangerous Mane
					CreateHat(client, 824, 10, 6, 0); //Koala Compact
				}
			case 25:
				{
					CreateHat(client, 30648, 10, 6, 1); //Corona Australis
					CreateHat(client, 30650, 10, 6, 0); //Starduster
					CreateHat(client, 30629, 10, 6, 0); //Support Spurs
				}
			case 26:
				{
					CreateHat(client, 30874, 10, 6, 1); //Archers Sterling
					CreateHat(client, 30857, 10, 6, 0); //Guilden Guardian
					CreateHat(client, 30789, 10, 6, 0); //Scoped Spartan
				}
			case 27:
				{
					CreateHat(client, 30501, 10, 6, 1); //Marsupial Man
					CreateHat(client, 30513, 10, 6, 0); //Mr Mundees Wild Ride
					CreateHat(client, 30478, 10, 6, 0); //Poachers Safari Jacket
				}
			case 28:
				{
					CreateHat(client, 30958, 10, 6, 1); //Puffy Polar Cap
					CreateHat(client, 30971, 10, 6, 0); //Down Tundra Coat
					CreateHat(client, 30995, 10, 6, 0); //Handsome Hitman
				}
			case 29:
				{
					CreateHat(client, 30858, 10, 6, 1); //Hawk Eyed Hunter
					CreateHat(client, 30892, 10, 6, 0); //Conspicuous Camoflage
					CreateHat(client, 30891, 10, 6, 0); //Cammy Jammies
				}
			case 30:
				{
					CreateHat(client, 31009, 10, 6, 1); //Crocodile Mun-Dee
					CreateHat(client, 31005, 10, 6, 0); //Scopers Scales
				}
			case 31:
				{
					CreateHat(client, 30978, 10, 6, 1); //Head Hedge
					CreateHat(client, 30895, 10, 6, 0); //Riflemans Regalia
					CreateHat(client, 30891, 10, 6, 0); //Cammy Jammies
				}
			case 32:
				{
					CreateHat(client, 30977, 10, 6, 1); //Antarctic Eyewear
					CreateHat(client, 30971, 10, 6, 0); //Down Tundra Coat
					CreateHat(client, 30891, 10, 6, 0); //Cammy Jammies
				}
			case 33:
				{
					CreateHat(client, 720, 10, 6, 1); //Bushmans Boonie
					CreateHat(client, 30895, 10, 6, 0); //Riflemans Regalia
					CreateHat(client, 30891, 10, 6, 0); //Cammy Jammies
				}
			case 34:
				{
					CreateHat(client, 31054, 10, 6, 1); //Bare Necessities
					CreateHat(client, 31055, 10, 6, 0); //Wagga Wagga Wear
					CreateHat(client, 30891, 10, 6, 0); //Cammy Jammies
				}
			case 35:
				{
					CreateHat(client, 31084, 10, 6, 1); //Elizabeth the Third
					CreateHat(client, 30978, 10, 6, 0); //Head Hedge
					CreateHat(client, 30424, 10, 6, 0); //Triggermans Tacticals
				}
			case 36:
				{
					CreateHat(client, 981, 10, 6, 1); //Cold Killer
					CreateHat(client, 393, 10, 6, 0); //Villians Veil		
					CreateHat(client, 30310, 10, 6, 0); //Snow Scoper
				}
			case 37:
				{
					CreateHat(client, 921, 10, 6, 1); //Executioner
					CreateHat(client, 31102, 10, 6, 0); //Mislaid Sweater			
					CreateHat(client, 30891, 10, 6, 0); //Cammy Jammies
				}
			case 38:
				{
					CreateHat(client, 1077, 10, 6, 1); //Randolph the Blood Nosed Caribou
					CreateHat(client, 30971, 10, 6, 0); //Down Tundra Coat			
					CreateHat(client, 30891, 10, 6, 0); //Cammy Jammies
				}
			case 39:
				{
					CreateHat(client, 819, 10, 6, 1); //Lone Star
					CreateHat(client, 30856, 10, 6, 0); //Down Under Duster		
					CreateHat(client, 30629, 10, 6, 0); //Support Spurs
				}
			case 40:
				{
					CreateHat(client, 344, 10, 6, 1); //Crocleather Slouch
					CreateHat(client, 30317, 10, 6, 0); //Five Month Shadow		
					CreateHat(client, 645, 10, 6, 0); //The Outback Intellectual
				}				
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			int rnd3 = GetRandomInt(1,41);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 30261, 10, 6, 1); //Candymans Cap
					CreateHat(client, 30260, 10, 6, 0); //Bountiful Bow
					CreateHat(client, 30301, 10, 6, 0); //Bozos Brogues
				}
			case 2:
				{
					CreateHat(client, 30404, 10, 6, 1); //Aviator Assassin
					CreateHat(client, 30405, 10, 6, 0); //Sky Captain
					CreateHat(client, 30929, 10, 6, 0); //Pocket Yeti
				}
			case 3:
				{
					CreateHat(client, 558, 10, 6, 1); //Under Cover
					CreateHat(client, 559, 10, 6, 0); //Griffins Gog
					CreateHat(client, 560, 10, 6, 0); //Intangible Ascot
				}
			case 4:
				{
					CreateHat(client, 459, 10, 6, 1); //Cosa Nostra Cap
					CreateHat(client, 462, 10, 6, 0); //Made Man
					CreateHat(client, 763, 10, 6, 0); //Sneaky Spats of Sneaking
				}
			case 5:
				{
					CreateHat(client, 180, 10, 6, 1); //Frenchmans Beret
					CreateHat(client, 30183, 10, 6, 0); //Escapist
					CreateHat(client, 30352, 10, 6, 0); //Mustachioed Mann
				}
			case 6:
				{
					CreateHat(client, 361, 10, 6, 1); //Noh Mercy
					CreateHat(client, 30189, 10, 6, 0); //Frenchmans Formals
					CreateHat(client, 397, 10, 6, 0); //Charmers Chapeau
				}
			case 7:
				{
					CreateHat(client, 879, 10, 6, 1); //Distinguished Rogue
					CreateHat(client, 629, 10, 6, 0); //Spectres Spectacles
					CreateHat(client, 147, 10, 6, 0); //Magistrates Mullet
				}
			case 8:
				{
					CreateHat(client, 30602, 10, 6, 1); //Puffy Provocateur
					CreateHat(client, 30603, 10, 6, 0); //Stealthy Scarf
					CreateHat(client, 30072, 10, 6, 0); //Pom Pommed Provocateur
				}
			case 9:
				{
					CreateHat(client, 30177, 10, 6, 1); //Hong Kong Cone
					CreateHat(client, 361, 10, 6, 0); //Noh Mercy
					CreateHat(client, 483, 10, 6, 0); //Rogues Col Roule
				}
			case 10:
				{
					CreateHat(client, 55, 10, 6, 1); //Fancy Fedora
					CreateHat(client, 30476, 10, 6, 0); //Lady Killer
					CreateHat(client, 763, 10, 6, 0); //Sneaky Spats of Sneaking
				}
			case 11:
				{
					CreateHat(client, 30123, 10, 6, 1); //Harmburg
					CreateHat(client, 977, 10, 6, 0); //Cut Throat Concierge
					CreateHat(client, 30569, 10, 6, 0); //Tomb Readers
				}
			case 12:
				{
					CreateHat(client, 397, 10, 6, 1); //Charmers Chapeau
					CreateHat(client, 955, 10, 6, 0); //Tuxxy
					CreateHat(client, 462, 10, 6, 0); //Made Man
				}
			case 13:
				{
					CreateHat(client, 223, 10, 6, 1); //Familiar Fez
					CreateHat(client, 30132, 10, 6, 0); //Blood Banker
					CreateHat(client, 30353, 10, 6, 0); //Backstabbers Bommerslang
				}
			case 14:
				{
					CreateHat(client, 180, 10, 6, 1); //Frenchmans Beret
					CreateHat(client, 30777, 10, 6, 0); //Lurking Legionnaire
					CreateHat(client, 30352, 10, 6, 0); //Mustachioed Mann
				}
			case 15:
				{
					CreateHat(client, 319, 10, 6, 1); //Detective Noir
					CreateHat(client, 30752, 10, 6, 0); //Chicago Overcoat
					CreateHat(client, 30352, 10, 6, 0); //Mustachioed Mann
				}
			case 16:
				{
					CreateHat(client, 287, 10, 6, 1); //Spine Chilling Skull
					CreateHat(client, 361, 10, 6, 0); //Noh Mercy
					CreateHat(client, 30132, 10, 6, 0); //Blood Banker
				}
			case 17:
				{
					CreateHat(client, 538, 10, 6, 1); //Killer Exclusive
					CreateHat(client, 30831, 10, 6, 0); //Readers Choice
					CreateHat(client, 30411, 10, 6, 0); //Au Courant Assassin
				}
			case 18:
				{
					CreateHat(client, 397, 10, 6, 1); //Charmers Chapeau
					CreateHat(client, 337, 10, 6, 0); //Le Party Phantom
					CreateHat(client, 30476, 10, 6, 0); //Laddy Killer
				}
			case 19:
				{
					CreateHat(client, 30549, 10, 6, 1); //Winter Woodsman
					CreateHat(client, 30602, 10, 6, 0); //Puffy Provocateur
					CreateHat(client, 30603, 10, 6, 0); //Stealthy Scarf
				}
			case 20:
				{
					CreateHat(client, 30505, 10, 6, 1); //Shadowmans Shade
					CreateHat(client, 30775, 10, 6, 0); //Dead Head
					CreateHat(client, 879, 10, 6, 0); //Distinguished Rogue
				}
			case 21:
				{
					CreateHat(client, 30505, 10, 6, 1); //Shadowmans Shade
					CreateHat(client, 30104, 10, 6, 0); //graybanns
					CreateHat(client, 30467, 10, 6, 0); //Spycrab
				}
			case 22:
				{
					CreateHat(client, 30827, 10, 6, 1); //Brainwarming Wear
					CreateHat(client, 30467, 10, 6, 0); //Spycrab
					CreateHat(client, 30606, 10, 6, 0); //Pocket Mama
				}
			case 23:
				{
					CreateHat(client, 30753, 10, 6, 1); //A Hat to Kill For
					CreateHat(client, 30651, 10, 6, 0); //Graylien
					CreateHat(client, 30752, 10, 6, 0); //Chicago Overcoat
				}
			case 24:
				{
					CreateHat(client, 521, 10, 6, 1); //Nanobalaclava
					CreateHat(client, 639, 10, 6, 0); //Dr Whoa
					CreateHat(client, 763, 10, 6, 0); //Sneaky Spats of Sneaking
				}
			case 25:
				{
					CreateHat(client, 872, 10, 6, 1); //Lacking Moral Fiber Mask
					CreateHat(client, 879, 10, 6, 0); //Distinguished Rogue
					CreateHat(client, 30467, 10, 6, 0); //Spycrab
				}
			case 26:
				{
					CreateHat(client, 30195, 10, 6, 1); //Ethereal Hood
					CreateHat(client, 483, 10, 6, 0); //Rogues Col Roule
					CreateHat(client, 30125, 10, 6, 0); //Rogues Brogues
				}
			case 27:
				{
					CreateHat(client, 30182, 10, 6, 1); //Le Homme Burglerre
					CreateHat(client, 30283, 10, 6, 0); //Foul Cowl
					CreateHat(client, 30728, 10, 6, 0); //Buttler
				}
			case 28:
				{
					CreateHat(client, 30512, 10, 6, 1); //Face Peeler
					CreateHat(client, 30506, 10, 6, 0); //Nightmare Hunter
					CreateHat(client, 30603, 10, 6, 0); //Stealthy Scarf
				}
			case 29:
				{
					CreateHat(client, 30848, 10, 6, 1); //Upgrade
					CreateHat(client, 30884, 10, 6, 0); //Aloha Apparel
					CreateHat(client, 30467, 10, 6, 0); //Spycrab
				}
			case 30:
				{
					CreateHat(client, 31016, 10, 6, 1); //Murderers Motiff
					CreateHat(client, 31014, 10, 6, 0); //Dressperado
					CreateHat(client, 31015, 10, 6, 0); //Bandits Boots	
				}
			case 31:
				{
					CreateHat(client, 30775, 10, 6, 1); //Dead Head
					CreateHat(client, 30989, 10, 6, 0); //Assassins Attire
					CreateHat(client, 30988, 10, 6, 0); //Aristotle
				}
			case 32:
				{
					CreateHat(client, 30827, 10, 6, 1); //Brain Warming Gear
					CreateHat(client, 30884, 10, 6, 0); //Aloha Apparal
					CreateHat(client, 30467, 10, 6, 0); //Spy Crab
				}
			case 33:
				{
					CreateHat(client, 30507, 10, 6, 1); //Rogues Rabbit
					CreateHat(client, 30884, 10, 6, 0); //Aloha Apparal
					CreateHat(client, 30467, 10, 6, 0); //Spy Crab
				}
			case 34:
				{
					CreateHat(client, 30753, 10, 6, 1); //Hat to Kill For
					CreateHat(client, 30752, 10, 6, 0); //Chicago Overcoat
					CreateHat(client, 30125, 10, 6, 0); //Rogues Brogues
				}
			case 35:
				{
					CreateHat(client, 31048, 10, 6, 1); //Shutterbug
					CreateHat(client, 31036, 10, 6, 0); //Stapler Specs
				}
			case 36:
				{
					CreateHat(client, 31048, 10, 6, 1); //Shutterbug
					CreateHat(client, 30476, 10, 6, 0); //Lady Killer
					CreateHat(client, 30125, 10, 6, 0); //Rogues Brogues
				}
			case 37:
				{
					CreateHat(client, 31073, 10, 6, 1); //Avian Amante
					CreateHat(client, 30125, 10, 6, 0); //Rogues Brogues
				}
			case 38:
				{
					CreateHat(client, 31072, 10, 6, 1); //Voodoo Vizier
					CreateHat(client, 30476, 10, 6, 0); //Lady Killer
					CreateHat(client, 30125, 10, 6, 0); //Rogues Brogues
				}
			case 39:
				{
					CreateHat(client, 30733, 10, 6, 1); //Teufort Knight
					CreateHat(client, 30467, 10, 6, 0); //Spycrab			
					CreateHat(client, 30602, 10, 6, 0); //Puffy Provocateur
				}
			case 40:
				{
					CreateHat(client, 397, 10, 6, 1); //Charmers Chapeau
					CreateHat(client, 30104, 10, 6, 0); //Graybanns			
					CreateHat(client, 879, 10, 6, 0); //Distinguished Rogue
				}
			case 41:
				{
					CreateHat(client, 31109, 10, 6, 1); //Crabe de Chapeau
					CreateHat(client, 31110, 10, 6, 0); //Birds Eye Viewer			
					CreateHat(client, 31124, 10, 6, 0); //Smoking Jacket
				}				
			}
		}		
	}
	return;
}

public Action GiveHat2(int client)
{
	g_bRTouched[client] = false;
	if (!GetConVarInt(g_hRHEnabled))
	{
		return;
	}
	
	if (IsPlayerHere(client))
	{
		int rnd3 = GetRandomInt(1,26);
		switch (rnd3)
		{
			//ALLCLASS
		case 1:
			{
				CreateHat(client, 139, 10, 6, 1); //Modest Pile of Hat
				CreateHat(client, 30104, 10, 6, 0); //Greybanns
				CreateHat(client, 955, 10, 6, 0); //Tuxxy
			}
		case 2:
			{
				CreateHat(client, 30066, 10, 6, 1); //Brotherhood of Arms
				CreateHat(client, 30397, 10, 6, 0); //Bruisers Bandana
				CreateHat(client, 30309, 10, 6, 0); //Dead of Night
			}
		case 3:
			{
				CreateHat(client, 30413, 10, 6, 1); //Mercs Mohawk
				CreateHat(client, 30085, 10, 6, 0); //Macho Mann 
				CreateHat(client, 30309, 10, 6, 0); //Dead of Night summer shades for pyro
			}
		case 4:
			{
				CreateHat(client, 1186, 10, 6, 1); //Monstrous Memento
				CreateHat(client, 743, 10, 6, 0); //Pyrovision Goggles
				CreateHat(client, 30923, 10, 6, 0); //Sledders Sidekick
			}
		case 5:
			{
				CreateHat(client, 30882, 10, 6, 1); //Jungle Wreath
				CreateHat(client, 743, 10, 6, 0); //Pyrovision Goggles
				CreateHat(client, 30881, 10, 6, 0); //Croaking Hazard
			}
		case 6:
			{
				CreateHat(client, 30915, 10, 6, 1); //Pithy Professional
				CreateHat(client, 30878, 10, 6, 0); //Quizzical Quetzal
				CreateHat(client, 30880, 10, 6, 0); //Pocket Saxton
			}
		case 7:
			{
				CreateHat(client, 30329, 10, 6, 1); //Polar Pullover
				CreateHat(client, 1025, 10, 6, 0); //Fortune Hunter
				CreateHat(client, 30551, 10, 6, 0); //Flashdance Footies
			}
		case 8:
			{
				CreateHat(client, 30362, 10, 6, 1); //Law
				CreateHat(client, 30104, 10, 6, 0); //Graybanns
				CreateHat(client, 296, 10, 6, 0); //License to Maim
			}
		case 9:
			{
				CreateHat(client, 30623, 10, 6, 1); //Rotation Sensation
				CreateHat(client, 143, 10, 6, 0); //Earbuds
				CreateHat(client, 30726, 10, 6, 0); //Pocket Villians
			}
		case 10:
			{
				CreateHat(client, 30646, 10, 6, 0); //Captain Space Mann
				CreateHat(client, 30658, 10, 6, 0); //Universal Translator
				CreateHat(client, 733, 10, 6, 0); //Pet Robro
			}
		case 11:
			{
				CreateHat(client, 30066, 10, 6, 1); //Brotherhood of Arms
				CreateHat(client, 30068, 10, 6, 0); //Breakneck Baggies
				CreateHat(client, 30607, 10, 6, 0); //Pocket Raiders
			}
		case 12:
			{
				CreateHat(client, 30740, 10, 6, 1); //Arkham Cowl
				CreateHat(client, 30722, 10, 6, 0); //Batters Bracers
				CreateHat(client, 30738, 10, 6, 0); //Batbelt
			}
		case 13:
			{
				CreateHat(client, 471, 10, 6, 1); //Proof of Purchase
				CreateHat(client, 30309, 10, 6, 0); //Dead of Night
				CreateHat(client, 30551, 10, 6, 0); //Flashdance Footies
			}
		case 14:
			{
				CreateHat(client, 30974, 10, 6, 1); //Caribou Companion
				CreateHat(client, 30972, 10, 6, 0); //Pocket Santa
				CreateHat(client, 30923, 10, 6, 0); //Sledders Sidekick
			}
		case 15:
			{
				CreateHat(client, 1185, 10, 6, 1); //Saxton
				CreateHat(client, 30878, 10, 6, 0); //Quizzical Quetzal
				CreateHat(client, 30880, 10, 6, 0); //Pocket Saxton
			}
		case 16:
			{
				CreateHat(client, 30838, 10, 6, 1); //Head Prize
				CreateHat(client, 30706, 10, 6, 0); //Catastrophic Companions
				CreateHat(client, 30929, 10, 6, 0); //Pocket Yeti
			}
		case 17:
			{
				CreateHat(client, 30829, 10, 6, 1); //Snowmann
				CreateHat(client, 30972, 10, 6, 0); //Pocket Santa
				CreateHat(client, 9229, 10, 6, 0); //Altruists Adornment
			}
		case 18:
			{
				CreateHat(client, 30759, 10, 6, 1); //Prinny Hat
				CreateHat(client, 30706, 10, 6, 0); //Catastrophic Companions
				CreateHat(client, 30757, 10, 6, 0); //Prinny Pouch
			}
		case 19:
			{
				CreateHat(client, 30814, 10, 6, 1); //Lil Bitey
				CreateHat(client, 30706, 10, 6, 0); //Catastrophic Companions
				CreateHat(client, 30929, 10, 6, 0); //Pocket Yeti
			}
		case 20:
			{
				CreateHat(client, 470, 10, 6, 1); //Lo Fi Longwave
				CreateHat(client, 486, 10, 6, 0); //Summer Shades
				CreateHat(client, 30726, 10, 6, 0); //Pocket Villians
			}
		case 21:
			{
				CreateHat(client, 702, 10, 6, 1); //Warsworn Helmet
				CreateHat(client, 30551, 10, 6, 0); //Flashdance Footies
				CreateHat(client, 30198, 10, 6, 0); //Pocket Horsemann
			}
		case 22:
			{
				CreateHat(client, 30542, 10, 6, 1); //Coldsnap Cap
				CreateHat(client, 30551, 10, 6, 0); //Flashdance Footies
				CreateHat(client, 30972, 10, 6, 0); //Pocket Santa
			}
		case 23:
			{
				CreateHat(client, 1186, 10, 6, 1); //Monstrous Memento
				CreateHat(client, 143, 10, 6, 0); //Earbuds
				CreateHat(client, 30929, 10, 6, 0); //Pocket Yeti
			}
		case 24:
			{
				CreateHat(client, 1185, 10, 6, 1); //Saxton
				CreateHat(client, 143, 10, 6, 0); //Earbuds
				CreateHat(client, 30929, 10, 6, 0); //Pocket Yeti
			}
		case 25:
			{
				CreateHat(client, 31058, 10, 6, 1); //Bat Hat
				CreateHat(client, 31060, 10, 6, 0); //Binoculus
				CreateHat(client, 31061, 10, 6, 0); //Pocket Halloween Boss
			}
		case 26:
			{
				CreateHat(client, 31173, 10, 6, 1); //Towering Pile of Presents
				CreateHat(client, 31093, 10, 6, 0); //Glittering Garland
				CreateHat(client, 31167, 10, 6, 0); //Festive Flip Thwomps
			}			
		}
	}
	return;
}

bool CreateHat(int client, int itemindex, int level, int quality, int unusual)
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
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);	

	if (level !=10)
	{
		SetEntProp(hat, Prop_Send, "m_iEntityLevel", level);
	}
	else
	{
		SetEntProp(hat, Prop_Send, "m_iEntityLevel", GetRandomUInt(1,100));
	}

	if (quality == 6)
	{
		if (GetRandomUInt(1,5) == 1)
		{
			SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);	
			TF2Attrib_SetByDefIndex(hat, 214, view_as<float>(GetRandomUInt(0, 9000)));
		}
	}	

	if (unusual == 0)
	{
		TF2Attrib_RemoveByDefIndex(hat, 134);
	}

	if (unusual == 1)
	{
		if (GetRandomInt(1,3) == 1)
		{
			SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);	
			TF2Attrib_SetByDefIndex(hat, 134, GetRandomInt(1,174) + 0.0);
		}
	}

	if (unusual > 1)
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);	
		TF2Attrib_SetByDefIndex(hat, 134, unusual + 0.0);
	}
	
	if(itemindex == 1158 || itemindex == 1173)
	{
		TF2Attrib_SetByDefIndex(hat, 134, GetRandomUInt(1,174) + 0.0);
	}
	
	if (GetRandomUInt(1,3) == 1)
	{
		int rndp = GetRandomUInt(1,29);
		switch(rndp)
		{
		case 1:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 3100495.0);
				TF2Attrib_SetByDefIndex(hat, 261, 3100495.0);
			}
		case 2:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8208497.0);
				TF2Attrib_SetByDefIndex(hat, 261, 8208497.0);
			}
		case 3:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 1315860.0);
				TF2Attrib_SetByDefIndex(hat, 261, 1315860.0);
			}
		case 4:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12377523.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12377523.0);
			}
		case 5:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 2960676.0);
				TF2Attrib_SetByDefIndex(hat, 261, 2960676.0);
			}
		case 6:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8289918.0);
				TF2Attrib_SetByDefIndex(hat, 261, 8289918.0);
			}
		case 7:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15132390.0);
				TF2Attrib_SetByDefIndex(hat, 261, 15132390.0);
			}
		case 8:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15185211.0);
				TF2Attrib_SetByDefIndex(hat, 261, 15185211.0);
			}
		case 9:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 14204632.0);
				TF2Attrib_SetByDefIndex(hat, 261, 14204632.0);
			}
		case 10:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15308410.0);
				TF2Attrib_SetByDefIndex(hat, 261, 15308410.0);
			}
		case 11:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8421376.0);
				TF2Attrib_SetByDefIndex(hat, 261, 8421376.0);
			}
		case 12:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 7511618.0);
				TF2Attrib_SetByDefIndex(hat, 261, 7511618.0);
			}
		case 13:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 13595446.0);
				TF2Attrib_SetByDefIndex(hat, 261, 13595446.0);
			}
		case 14:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 10843461.0);
				TF2Attrib_SetByDefIndex(hat, 261, 10843461.0);
			}
		case 15:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 5322826.0);
				TF2Attrib_SetByDefIndex(hat, 261, 5322826.0);
			}
		case 16:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12955537.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12955537.0);
			}
		case 17:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 16738740.0);
				TF2Attrib_SetByDefIndex(hat, 261, 16738740.0);
			}
		case 18:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 6901050.0);
				TF2Attrib_SetByDefIndex(hat, 261, 6901050.0);
			}
		case 19:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 3329330.0);
				TF2Attrib_SetByDefIndex(hat, 261, 3329330.0);
			}
		case 20:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15787660.0);
				TF2Attrib_SetByDefIndex(hat, 261, 15787660.0);
			}
		case 21:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8154199.0);
				TF2Attrib_SetByDefIndex(hat, 261, 8154199.0);
			}
		case 22:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 4345659.0);
				TF2Attrib_SetByDefIndex(hat, 261, 4345659.0);
			}
		case 23:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 6637376.0);
				TF2Attrib_SetByDefIndex(hat, 261, 2636109.0);
			}
		case 24:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 3874595.0);
				TF2Attrib_SetByDefIndex(hat, 261, 1581885.0);
			}
		case 25:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12807213.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12091445.0);
			}
		case 26:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 4732984.0);
				TF2Attrib_SetByDefIndex(hat, 261, 3686984.0);
			}
		case 27:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12073019.0);
				TF2Attrib_SetByDefIndex(hat, 261, 5801378.0);
			}
		case 28:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8400928.0);
				TF2Attrib_SetByDefIndex(hat, 261, 2452877.0);
			}
		case 29:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 11049612.0);
				TF2Attrib_SetByDefIndex(hat, 261, 8626083.0);
			}
		}
	}

	SetEntProp(hat, Prop_Send, "m_bValidatedAttachedEntity", 1);  

	DispatchSpawn(hat);
	SDKCall(g_hEquipWearable, client, hat);
	return true;
} 

public Action Timer_GiveWeapons(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	
	if (!GetConVarBool(g_hRHEnabled) || !IsPlayerHere(client))
	{
		return;
	}

	g_bRTouched[client] = false;

	TFClassType class = TF2_GetPlayerClass(client);

	switch (class)
	{
	case TFClass_Scout:
		{
			if (!g_bMedieval)
			{
				int rnd = GetRandomUInt(1,36);
				TF2_RemoveWeaponSlot(client, 0);

				switch (rnd)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 45, 6);
					}
				case 2:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 1078, 6);
					}
				case 3:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 45, 9);
					}
				case 4:
					{
						CreateWeapon(client, "tf_weapon_handgun_scout_primary", 220, 6);
					}
				case 5:
					{
						CreateWeapon(client, "tf_weapon_handgun_scout_primary", 220, 16);
					}
				case 6:
					{
						CreateWeapon(client, "tf_weapon_soda_popper", 448, 6);
					}
				case 7:
					{
						CreateWeapon(client, "tf_weapon_soda_popper", 448, 16);
					}
				case 8:
					{
						CreateWeapon(client, "tf_weapon_pep_brawler_blaster", 772, 6);
					}
				case 9:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 1103, 6);
					}
				case 10:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 13, 5);
					}
				case 11:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 669, 6);
					}
				case 12:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 200, 9);
					}
				case 13:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 200, 16);
					}
				case 14:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 200, 11);
					}
				case 15:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 799, 11);
					}
				case 16:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 808, 11);
					}
				case 17:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 888, 11);
					}
				case 18:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 897, 11);
					}
				case 19:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 906, 11);
					}
				case 20:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 915, 11);
					}
				case 21:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 964, 11);
					}
				case 22:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 973, 11);
					}
				case 23:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 15002, 15);
					}
				case 24:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 15015, 15);
					}
				case 25:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 15029, 15);
					}
				case 26:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 15036, 15);
					}
				case 27:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 15053, 15);
					}
				case 28:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 15065, 11);
					}
				case 29:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 15069, 15);
					}
				case 30:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 15106, 15);
					}
				case 31:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 15107, 15);
					}
				case 32:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 15108, 15);
					}
				case 33:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 15131, 15);
					}
				case 34:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 15151, 15);
					}
				case 35:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 15157, 15);
					}
				case 36:
					{
						CreateWeapon(client, "tf_weapon_scattergun", 15021, 15);
					}
				}
				
				int rnd2 = GetRandomUInt(1,28);
				TF2_RemoveWeaponSlot(client, 1);
				
				switch (rnd2)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 773, 6);
					}
				case 2:
					{
						CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 449, 6);
					}
				case 3:
					{
						CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 449, 16);
					}
				case 4:
					{
						CreateWeapon(client, "tf_weapon_cleaver", 812, 6);
					}
				case 5:
					{
						CreateWeapon(client, "tf_weapon_cleaver", 833, 3);
					}
				case 6:
					{
						CreateWeapon(client, "tf_weapon_lunchbox_drink", 46, 6);
					}
				case 7:
					{
						CreateWeapon(client, "tf_weapon_lunchbox_drink", 1145, 6);
					}
				case 8:
					{
						CreateWeapon(client, "tf_weapon_lunchbox_drink", 163, 6);
					}
				case 9:
					{
						CreateWeapon(client, "tf_weapon_jar_milk", 222, 6);
					}
				case 10:
					{
						CreateWeapon(client, "tf_weapon_jar_milk", 1121, 6);
					}
				case 11:
					{
						CreateWeapon(client, "tf_weapon_pistol", 23, 5);
					}
				case 12:
					{
						CreateWeapon(client, "tf_weapon_pistol", 160, 3);
					}
				case 13:
					{
						CreateWeapon(client, "tf_weapon_pistol", 294, 6);
					}
				case 14:
					{
						CreateWeapon(client, "tf_weapon_pistol", 30666, 6);
					}
				case 15:
					{
						CreateWeapon(client, "tf_weapon_pistol", 209, 16);
					}
				case 16:
					{
						CreateWeapon(client, "tf_weapon_pistol", 15013, 15);
					}
				case 17:
					{
						CreateWeapon(client, "tf_weapon_pistol", 15018, 15);
					}
				case 18:
					{
						CreateWeapon(client, "tf_weapon_pistol", 15035, 15);
					}
				case 19:
					{
						CreateWeapon(client, "tf_weapon_pistol", 15041, 15);
					}
				case 20:
					{
						CreateWeapon(client, "tf_weapon_pistol", 15046, 15);
					}
				case 21:
					{
						CreateWeapon(client, "tf_weapon_pistol", 15056, 15);
					}
				case 22:
					{
						CreateWeapon(client, "tf_weapon_pistol", 15060, 15);
					}
				case 23:
					{
						CreateWeapon(client, "tf_weapon_pistol", 15061, 15);
					}
				case 24:
					{
						CreateWeapon(client, "tf_weapon_pistol", 15100, 15);
					}
				case 25:
					{
						CreateWeapon(client, "tf_weapon_pistol", 15101, 15);
					}
				case 26:
					{
						CreateWeapon(client, "tf_weapon_pistol", 15102, 15);
					}
				case 27:
					{
						CreateWeapon(client, "tf_weapon_pistol", 15126, 15);
					}
				case 28:
					{
						CreateWeapon(client, "tf_weapon_pistol", 15148, 15);
					}
				}
			}
			
			int rnd3 = GetRandomUInt(1,26);
			TF2_RemoveWeaponSlot(client, 2);
			
			switch (rnd3)
			{
			case 1:
				{
					CreateWeapon(client, "tf_weapon_bat_wood", 44, 6);
				}
			case 2:
				{
					CreateWeapon(client, "tf_weapon_bat", 325, 6);
				}
			case 3:
				{
					CreateWeapon(client, "tf_weapon_bat", 452, 6);
				}
			case 4:
				{
					CreateWeapon(client, "tf_weapon_bat", 317, 6);
				}
			case 5:
				{
					CreateWeapon(client, "tf_weapon_bat", 349, 6);
				}
			case 6:
				{
					CreateWeapon(client, "tf_weapon_bat", 355, 6);
				}
			case 7:
				{
					CreateWeapon(client, "tf_weapon_bat_giftwrap", 648, 6);
				}
			case 8:
				{
					CreateWeapon(client, "tf_weapon_bat", 450, 6);
				}
			case 9:
				{
					CreateWeapon(client, "tf_weapon_bat_fish", 221, 6);
				}
			case 10:
				{
					CreateWeapon(client, "tf_weapon_bat_fish", 572, 6);
				}
			case 11:
				{
					CreateWeapon(client, "tf_weapon_bat_fish", 999, 6);
				}
			case 12:
				{
					CreateWeapon(client, "tf_weapon_bat_fish", 221, 16);
				}
			case 13:
				{
					CreateWeapon(client, "tf_weapon_bat", 190, 11);
				}
			case 14:
				{
					CreateWeapon(client, "tf_weapon_bat", 264, 6);
				}
			case 15:
				{
					CreateWeapon(client, "tf_weapon_bat", 423, 11);
				}
			case 16:
				{
					CreateWeapon(client, "tf_weapon_bat", 474, 6);
				}
			case 17:
				{
					CreateWeapon(client, "tf_weapon_bat", 880, 6);
				}
			case 18:
				{
					CreateWeapon(client, "tf_weapon_bat", 939, 6);
				}
			case 19:
				{
					CreateWeapon(client, "tf_weapon_bat", 954, 11);
				}
			case 20:
				{
					CreateWeapon(client, "tf_weapon_bat", 1013, 6);
				}
			case 21:
				{
					CreateWeapon(client, "tf_weapon_bat", 1071, 11);
				}
			case 22:
				{
					CreateWeapon(client, "tf_weapon_bat", 1123, 6);
				}
			case 23:
				{
					CreateWeapon(client, "tf_weapon_bat", 1127, 6);
				}
			case 24:
				{
					CreateWeapon(client, "tf_weapon_bat", 30667, 15);
				}
			case 25:
				{
					CreateWeapon(client, "tf_weapon_bat", 30758, 6);
				}
			case 26:
				{
					CreateWeapon(client, "tf_weapon_bat", 660, 6);
				}
			}
		}
		
	case TFClass_Sniper:
		{
			if (!g_bMedieval)
			{
				int rnd = GetRandomUInt(1,7);
				TF2_RemoveWeaponSlot(client, 0);
				
				switch (rnd)
				{
				case 1:
					{
						int rnd5 = GetRandomUInt(1,3);
						switch (rnd5)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_compound_bow", 56, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_compound_bow", 1092, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_compound_bow", 1005, 6);
							}
						}
					}
				case 2:
					{
						CreateWeapon(client, "tf_weapon_sniperrifle", 230, 6);
					}
				case 3:
					{
						int rnd11 = GetRandomUInt(1,2);
						switch (rnd11)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_sniperrifle_decap", 402, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_sniperrifle_decap", 402, 16);
							}
						}
					}
				case 4:
					{
						int rnd6 = GetRandomUInt(1,2);
						switch (rnd6)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_sniperrifle", 526, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_sniperrifle", 30665, 15);
							}
						}
					}
				case 5:
					{
						CreateWeapon(client, "tf_weapon_sniperrifle", 752, 6);
					}
				case 6:
					{
						CreateWeapon(client, "tf_weapon_sniperrifle_classic", 1098, 6);
					}
				case 7:
					{
						int rnd4 = GetRandomUInt(1,7);
						switch (rnd4)
						{     
						case 1:
							{
								CreateWeapon(client, "tf_weapon_sniperrifle", 14, 5);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_sniperrifle", 851, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_sniperrifle", 664, 6);
							}
						case 4:
							{
								int rnd10 = GetRandomUInt(1,8);
								switch (rnd10)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 792, 11);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 801, 11);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 881, 11);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 890, 11);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 899, 11);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 908, 11);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 957, 11);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 966, 11);
									}
								}
							}
						case 5:
							{
								int rnd11 = GetRandomUInt(1,14);
								switch (rnd11)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 15000, 15);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 15007, 15);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 15019, 15);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 15023, 15);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 15033, 15);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 15059, 15);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 15070, 15);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 15071, 15);
									}
								case 9:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 15072, 15);
									}
								case 10:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 15111, 15);
									}
								case 11:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 15112, 15);
									}
								case 12:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 15135, 15);
									}
								case 13:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 15136, 15);
									}
								case 14:
									{
										CreateWeapon(client, "tf_weapon_sniperrifle", 15154, 15);
									}
								}
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_sniperrifle", 201, 11);
							}
						case 7:
							{
								CreateWeapon(client, "tf_weapon_sniperrifle", 201, 9);
							}
						}
					}				
				}
				
				int rnd2 = GetRandomUInt(1,6);
				TF2_RemoveWeaponSlot(client, 1);

				switch (rnd2)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_charged_smg", 751, 6);
					}
				case 2:
					{
						int rnd7 = GetRandomUInt(1,3);
						switch (rnd7)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_jar", 58, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_jar", 1105, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_jar", 1083, 6);
							}
						}
					}
				case 3:
					{
						CreateWeapon(client, "tf_wearable_razorback", 57, 6);
					}
				case 4:
					{
						CreateWeapon(client, "tf_wearable", 231, 6);
					}
				case 5:
					{
						CreateWeapon(client, "tf_wearable", 642, 6);
					}
				case 6:
					{
						int rnd6 = GetRandomUInt(1,6);
						switch (rnd6)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_smg", 16, 5);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_smg", 1149, 6);
							}
						case 3:
							{
								int rnd10 = GetRandomUInt(1,9);
								switch (rnd10)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_smg", 15001, 15);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_smg", 15022, 15);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_smg", 15032, 15);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_smg", 15037, 15);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_smg", 15058, 15);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_smg", 15076, 15);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_smg", 15110, 15);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_smg", 15134, 15);
									}
								case 9:
									{
										CreateWeapon(client, "tf_weapon_smg", 15153, 15);
									}
								}
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_smg", 203, 11);
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_smg", 203, 9);
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_smg", 203, 16);
							}
						}
					}
				}
			}
			
			int rnd3 = GetRandomUInt(1,4);
			TF2_RemoveWeaponSlot(client, 2);

			switch (rnd3)
			{
			case 1:
				{
					CreateWeapon(client, "tf_weapon_club", 171, 6);
				}
			case 2:
				{
					CreateWeapon(client, "tf_weapon_club", 232, 6);
				}
			case 3:
				{
					int rnd6 = GetRandomUInt(1,2);
					switch (rnd6)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_club", 401, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_club", 401, 16);
						}
					}
				}
			case 4:
				{
					int rnd8 = GetRandomUInt(1,13);
					switch (rnd8)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_club", 3, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_club", 264, 6);
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_club", 423, 11);
						}
					case 4:
						{
							CreateWeapon(client, "tf_weapon_club", 474, 6);
						}
					case 5:
						{
							CreateWeapon(client, "tf_weapon_club", 880, 6);
						}
					case 6:
						{
							CreateWeapon(client, "tf_weapon_club", 939, 6);
						}
					case 7:
						{
							CreateWeapon(client, "tf_weapon_club", 954, 11);
						}
					case 8:
						{
							CreateWeapon(client, "tf_weapon_club", 1013, 6);
						}
					case 9:
						{
							CreateWeapon(client, "tf_weapon_club", 1071, 11);
						}
					case 10:
						{
							CreateWeapon(client, "tf_weapon_club", 1123, 6);
						}
					case 11:
						{
							CreateWeapon(client, "tf_weapon_club", 1127, 6);
						}
					case 12:
						{
							CreateWeapon(client, "tf_weapon_club", 30758, 6);
						}
					case 13:
						{
							CreateWeapon(client, "tf_weapon_club", 193, 11);
						}
					}
				}					
			}			
		}
		
	case TFClass_Soldier:
		{
			if (!g_bMedieval)
			{
				int rnd = GetRandomUInt(1,9);
				TF2_RemoveWeaponSlot(client, 0);

				switch (rnd)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_rocketlauncher_directhit", 127, 6);
					}
				case 2:
					{
						int rnd4 = GetRandomUInt(1,4);
						switch (rnd4)
						{     
						case 1:
							{
								CreateWeapon(client, "tf_weapon_rocketlauncher", 228, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_rocketlauncher", 1085, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_rocketlauncher", 228, 9);
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_rocketlauncher", 228, 16);
							}
						}
					}
				case 3:
					{
						CreateWeapon(client, "tf_weapon_rocketlauncher", 414, 6);
					}
				case 4:
					{
						CreateWeapon(client, "tf_weapon_particle_cannon", 441, 6);
					}
				case 5:
					{
						CreateWeapon(client, "tf_weapon_rocketlauncher", 513, 6);
					}
				case 6:
					{
						int rnd4 = GetRandomUInt(1,2);
						switch (rnd4)
						{     
						case 1:
							{
								CreateWeapon(client, "tf_weapon_rocketlauncher_airstrike", 1104, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_rocketlauncher_airstrike", 1104, 16);
							}
						}
					}
				case 7:
					{
						CreateWeapon(client, "tf_weapon_rocketlauncher", 730, 6);
					}
				case 8:
					{
						CreateWeapon(client, "tf_weapon_rocketlauncher", 237, 6);
					}
				case 9:
					{
						int rnd4 = GetRandomUInt(1,6);
						switch (rnd4)
						{     
						case 1:
							{
								CreateWeapon(client, "tf_weapon_rocketlauncher", 18, 5);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_rocketlauncher", 658, 6);
							}
						case 3:
							{
								int rnd11 = GetRandomUInt(1,8);
								switch (rnd11)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 800, 11);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 809, 11);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 889, 11);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 898, 11);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 907, 11);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 916, 11);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 965, 11);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 974, 11);
									}
								}
							}
						case 4:
							{
								int rnd12 = GetRandomUInt(1,12);
								switch (rnd12)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 15006, 15);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 15014, 15);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 15028, 15);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 15043, 15);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 15052, 15);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 15057, 15);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 15081, 15);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 15104, 15);
									}
								case 9:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 15105, 15);
									}
								case 10:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 15129, 15);
									}
								case 11:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 15130, 15);
									}
								case 12:
									{
										CreateWeapon(client, "tf_weapon_rocketlauncher", 15150, 15);
									}
								}
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_rocketlauncher", 205, 9);
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_rocketlauncher", 205, 16);
							}
						}
					}					
				}
				
				int rnd2 = GetRandomUInt(1,10);
				TF2_RemoveWeaponSlot(client, 1);
				
				switch (rnd2)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_raygun", 442, 6);
					}
				case 2:
					{
						int rnd5 = GetRandomUInt(1,2);
						switch (rnd5)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 1153, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 1153, 16);
							}
						}
					}
				case 3:
					{
						int rnd5 = GetRandomUInt(1,2);
						switch (rnd5)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 415, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 415, 16);
							}
						}
					}
				case 4:
					{
						int rnd6 = GetRandomUInt(1,2);
						switch (rnd6)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_buff_item", 129, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_buff_item", 1001, 6);
							}
						}
					}
				case 5:
					{
						CreateWeapon(client, "tf_weapon_buff_item", 226, 6);
					}
				case 6:
					{
						CreateWeapon(client, "tf_weapon_buff_item", 354, 6);
					}
				case 7:
					{
						CreateWeapon(client, "tf_wearable", 133, 6);
					}
				case 8:
					{
						CreateWeapon(client, "tf_wearable", 444, 6);
					}
				case 9:
					{
						CreateWeapon(client, "tf_weapon_parachute", 1101, 6);
					}
				case 10:
					{
						int rnd7 = GetRandomUInt(1,5);
						switch (rnd7)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 10, 5);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 1141, 6);
							}
						case 3:
							{
								int rnd11 = GetRandomUInt(1,9);
								switch (rnd11)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_shotgun_soldier", 15003, 15);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_shotgun_soldier", 15016, 15);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_shotgun_soldier", 15044, 15);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_shotgun_soldier", 15047, 15);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_shotgun_soldier", 15085, 15);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_shotgun_soldier", 15109, 15);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_shotgun_soldier", 15132, 15);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_shotgun_soldier", 15133, 15);
									}
								case 9:
									{
										CreateWeapon(client, "tf_weapon_shotgun_soldier", 15152, 15);
									}
								}
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 199, 11);
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_shotgun_soldier", 199, 16);
							}
						}
					}					
				}
			}
			
			int rnd3 = GetRandomUInt(1,7);
			TF2_RemoveWeaponSlot(client, 2);
			
			switch (rnd3)
			{
			case 1:
				{
					CreateWeapon(client, "tf_weapon_shovel", 128, 6);
				}
			case 2:
				{
					CreateWeapon(client, "tf_weapon_shovel", 154, 6);
				}
			case 3:
				{
					int rnd6 = GetRandomUInt(1,2);
					switch (rnd6)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_shovel", 447, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_shovel", 447, 16);
						}
					}
				}
			case 4:
				{
					CreateWeapon(client, "tf_weapon_shovel", 775, 6);
				}
			case 5:
				{
					CreateWeapon(client, "tf_weapon_katana", 357, 6);
				}
			case 6:
				{
					CreateWeapon(client, "tf_weapon_shovel", 416, 6);
				}
			case 7:
				{
					int rnd5 = GetRandomUInt(1,12);
					switch (rnd5)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_shovel", 264, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_shovel", 423, 11);
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_shovel", 474, 6);
						}
					case 4:
						{
							CreateWeapon(client, "tf_weapon_shovel", 880, 6);
						}
					case 5:
						{
							CreateWeapon(client, "tf_weapon_shovel", 939, 6);
						}
					case 6:
						{
							CreateWeapon(client, "tf_weapon_shovel", 1013, 6);
						}
					case 7:
						{
							CreateWeapon(client, "tf_weapon_shovel", 1071, 11);
						}
					case 8:
						{
							CreateWeapon(client, "tf_weapon_shovel", 1123, 6);
						}
					case 9:
						{
							CreateWeapon(client, "tf_weapon_shovel", 1127, 6);
						}
					case 10:
						{
							CreateWeapon(client, "tf_weapon_shovel", 30758, 6);
						}
					case 11:
						{
							CreateWeapon(client, "tf_weapon_shovel", 954, 11);
						}
					case 12:
						{
							CreateWeapon(client, "tf_weapon_shovel", 196, 11);
						}
					}
				}					
			}
		}
		
	case TFClass_DemoMan:
		{
			if (!g_bMedieval)
			{
				int rnd = GetRandomUInt(1,6); 
				TF2_RemoveWeaponSlot(client, 0);
				
				switch (rnd)
				{
				case 1:
					{
						int rnd8 = GetRandomUInt(1,2);
						switch (rnd8)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_grenadelauncher", 308, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_grenadelauncher", 308, 16);
							}
						}
					}
				case 2:
					{
						int rnd9 = GetRandomUInt(1,2);
						switch (rnd9)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_grenadelauncher", 1151, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_grenadelauncher", 1151, 16);
							}
						}
					}
				case 3:
					{
						int rnd4 = GetRandomUInt(1,2);
						switch (rnd4)
						{
						case 1:
							{
								CreateWeapon(client, "tf_wearable", 405, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_wearable", 608, 6);
							}
						}
					}
				case 4:
					{
						CreateWeapon(client, "tf_weapon_parachute", 1101, 6);
					}
				case 5:
					{
						int rnd9 = GetRandomUInt(1,2);
						switch (rnd9)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_cannon", 996, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_cannon", 996, 16);
							}
						}
					}
				case 6:
					{
						int rnd7 = GetRandomUInt(1,6);
						switch (rnd7)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_grenadelauncher", 19, 5);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_grenadelauncher", 1007, 6);
							}
						case 3:
							{
								int rnd11 = GetRandomUInt(1,8);
								switch (rnd11)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_grenadelauncher", 15077, 15);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_grenadelauncher", 15079, 15);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_grenadelauncher", 15091, 15);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_grenadelauncher", 15092, 15);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_grenadelauncher", 15116, 15);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_grenadelauncher", 15117, 15);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_grenadelauncher", 15142, 15);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_grenadelauncher", 15158, 15);
									}
								}
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_grenadelauncher", 206, 11);
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_grenadelauncher", 206, 9);
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_grenadelauncher", 206, 16);
							}
						}
					}	
				}
				
				int rnd2 = GetRandomUInt(1,7); 
				TF2_RemoveWeaponSlot(client, 1);
				
				switch (rnd2)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_pipebomblauncher", 1150, 6);
					}
				case 2:
					{
						CreateWeapon(client, "tf_weapon_pipebomblauncher", 130, 6);
					}
				case 3:
					{
						CreateWeapon(client, "tf_weapon_pipebomblauncher", 265, 6);
					}
				case 4:
					{
						int rnd4 = GetRandomUInt(1,2);
						switch (rnd4)
						{     
						case 1:
							{
								CreateWeapon(client, "tf_wearable_demoshield", 131, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_wearable_demoshield", 1144, 6);
							}
						}
					}
				case 5:
					{
						CreateWeapon(client, "tf_wearable_demoshield", 406, 6);
					}
				case 6:
					{
						CreateWeapon(client, "tf_wearable_demoshield", 1099, 6);
					}
				case 7:
					{
						int rnd5 = GetRandomUInt(1,8);
						switch (rnd5)
						{     
						case 1:
							{
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 20, 5);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 661, 6);
							}
						case 3:
							{
								int rnd12 = GetRandomUInt(1,8);
								switch (rnd12)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 797, 11);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 806, 11);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 886, 11);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 895, 11);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 904, 11);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 913, 11);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 962, 11);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 971, 11);
									}
								}
							}
						case 4:
							{
								int rnd14 = GetRandomUInt(1,13);
								switch (rnd14)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 15009, 15);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 15012, 15);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 15024, 15);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 15038, 15);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 15045, 15);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 15048, 15);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 15082, 15);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 15083, 15);
									}
								case 9:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 15084, 15);
									}
								case 10:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 15113, 15);
									}
								case 11:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 15137, 15);
									}
								case 12:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 15138, 15);
									}
								case 13:
									{
										CreateWeapon(client, "tf_weapon_pipebomblauncher", 15155, 15);
									}
								}
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 207, 9);
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 207, 16);
							}
						case 7:
							{
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 207, 11);
							}
						case 8:
							{
								CreateWeapon(client, "tf_weapon_pipebomblauncher", 661, 11);
							}
						}
					}					
				}
			}
			
			int rnd3 = GetRandomUInt(1,8);
			TF2_RemoveWeaponSlot(client, 2);
			
			switch (rnd3)
			{
			case 1:
				{
					int rnd5 = GetRandomUInt(1,5);
					switch (rnd5)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_sword", 132, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_sword", 266, 5);
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_sword", 482, 6);
						}
					case 4:
						{
							CreateWeapon(client, "tf_weapon_sword", 1082, 6);
						}
					case 5:
						{
							CreateWeapon(client, "tf_weapon_sword", 132, 9);
						}
					}
				}
			case 2:
				{
					CreateWeapon(client, "tf_weapon_shovel", 154, 6);
				}
			case 3:
				{
					int rnd4 = GetRandomUInt(1,2);
					switch (rnd4)
					{     
					case 1:
						{
							CreateWeapon(client, "tf_weapon_sword", 172, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_sword", 172, 16);
						}
					}
				}
			case 4:
				{
					CreateWeapon(client, "tf_weapon_stickbomb", 307, 6);
				}
			case 5:
				{
					int rnd7 = GetRandomUInt(1,2);
					switch (rnd7)
					{     
					case 1:
						{
							CreateWeapon(client, "tf_weapon_sword", 327, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_sword", 327, 16);
						}
					}
				}
			case 6:
				{
					CreateWeapon(client, "tf_weapon_katana", 357, 6);
				}
			case 7:
				{
					int rnd8 = GetRandomUInt(1,2);
					switch (rnd8)
					{     
					case 1:
						{
							CreateWeapon(client, "tf_weapon_sword", 404, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_sword", 404, 16);
						}
					}
				}
			case 8:
				{
					int rnd6 = GetRandomUInt(1,13);
					switch (rnd6)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_bottle", 191, 11);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_bottle", 264, 6);
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_bottle", 423, 11);
						}
					case 4:
						{
							CreateWeapon(client, "tf_weapon_bottle", 474, 6);
						}
					case 5:
						{
							CreateWeapon(client, "tf_weapon_bottle", 609, 6);
						}
					case 6:
						{
							CreateWeapon(client, "tf_weapon_bottle", 880, 6);
						}
					case 7:
						{
							CreateWeapon(client, "tf_weapon_bottle", 939, 6);
						}
					case 8:
						{
							CreateWeapon(client, "tf_weapon_bottle", 954, 11);
						}
					case 9:
						{
							CreateWeapon(client, "tf_weapon_bottle", 1013, 6);
						}
					case 10:
						{
							CreateWeapon(client, "tf_weapon_bottle", 1071, 11);
						}
					case 11:
						{
							CreateWeapon(client, "tf_weapon_bottle", 1123, 6);
						}
					case 12:
						{
							CreateWeapon(client, "tf_weapon_bottle", 1127, 6);
						}
					case 13:
						{
							CreateWeapon(client, "tf_weapon_bottle", 30758, 6);
						}
					}
				}					
			}				
		}
		
	case TFClass_Medic:
		{
			if (!g_bMedieval)
			{
				int rnd = GetRandomUInt(1,4); 
				TF2_RemoveWeaponSlot(client, 0);
				
				switch (rnd)
				{
				case 1:
					{
						int rnd7 = GetRandomUInt(1,2);
						switch (rnd7)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_syringegun_medic", 36, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_syringegun_medic", 36, 9);
							}
						}
					}
				case 2:
					{
						int rnd6 = GetRandomUInt(1,3);
						switch (rnd6)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_crossbow", 305, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_crossbow", 1079, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_crossbow", 305, 16);
							}
						}
					}
				case 3:
					{
						CreateWeapon(client, "tf_weapon_syringegun_medic", 412, 6);
					}
				case 4:
					{
						CreateWeapon(client, "tf_weapon_syringegun_medic", 204, 11);
					}				
				}
				
				int rnd2 = GetRandomUInt(1,4);
				TF2_RemoveWeaponSlot(client, 1);
				switch (rnd2)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_medigun", 35, 6);
					}
				case 2:
					{
						CreateWeapon(client, "tf_weapon_medigun", 411, 6);
					}
				case 3:
					{
						CreateWeapon(client, "tf_weapon_medigun", 998, 6);
					}
				case 4:
					{
						int rnd4 = GetRandomUInt(1,7);
						switch (rnd4)
						{     
						case 1:
							{
								CreateWeapon(client, "tf_weapon_medigun", 29, 5);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_medigun", 663, 6);
							}
						case 3:
							{
								int rnd13 = GetRandomUInt(1,8);
								switch (rnd13)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_medigun", 796, 11);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_medigun", 805, 11);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_medigun", 885, 11);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_medigun", 894, 11);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_medigun", 903, 11);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_medigun", 912, 11);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_medigun", 961, 11);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_medigun", 970, 11);
									}
								}
							}
						case 4:
							{
								int rnd12 = GetRandomUInt(1,12);
								switch (rnd12)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_medigun", 15008, 15);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_medigun", 15010, 15);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_medigun", 15025, 15);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_medigun", 15039, 15);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_medigun", 15050, 15);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_medigun", 15078, 15);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_medigun", 15097, 15);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_medigun", 15121, 15);
									}
								case 9:
									{
										CreateWeapon(client, "tf_weapon_medigun", 15122, 15);
									}
								case 10:
									{
										CreateWeapon(client, "tf_weapon_medigun", 15123, 15);
									}
								case 11:
									{
										CreateWeapon(client, "tf_weapon_medigun", 15145, 15);
									}
								case 12:
									{
										CreateWeapon(client, "tf_weapon_medigun", 15146, 15);
									}
								}
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_medigun", 211, 11);
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_medigun", 211, 9);
							}
						case 7:
							{
								CreateWeapon(client, "tf_weapon_medigun", 211, 16);
							}
						}
					}				
				}
			}
			int rnd3 = GetRandomUInt(1,5);
			TF2_RemoveWeaponSlot(client, 2);
			
			switch (rnd3)
			{
			case 1:
				{
					int rnd7 = GetRandomUInt(1,3);
					switch (rnd7)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 37, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 1003, 6);
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 37, 16);
						}
					}
				}
			case 2:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 173, 6);
				}
			case 3:
				{
					int rnd8 = GetRandomUInt(1,2);
					switch (rnd8)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 304, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 304, 16);
						}
					}
				}
			case 4:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 413, 6);
				}
			case 5:
				{
					int rnd4 = GetRandomUInt(1,14);
					switch (rnd4)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 8, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 264, 6);
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 423, 11);
						}
					case 4:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 474, 6);
						}
					case 5:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 880, 6);
						}
					case 6:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 939, 6);
						}
					case 7:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 1013, 6);
						}
					case 8:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 1071, 11);
						}
					case 9:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 1123, 6);
						}
					case 10:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 1127, 6);
						}
					case 11:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 30758, 6);
						}
					case 12:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 1143, 11);
						}
					case 13:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 954, 11);
						}
					case 14:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 198, 11);
						}
					}
				}			
			}			
		}
		
	case TFClass_Heavy:
		{
			if (!g_bMedieval)
			{
				int rnd = GetRandomUInt(1,5);
				TF2_RemoveWeaponSlot(client, 0);
				
				switch (rnd)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_minigun", 41, 6);
					}
				case 2:
					{
						int rnd10 = GetRandomUInt(1,2);
						switch (rnd10)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_minigun", 312, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_minigun", 312, 16);
							}
						}
					}
				case 3:
					{
						int rnd9 = GetRandomUInt(1,4);
						switch (rnd9)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_minigun", 424, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_minigun", 424, 5);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_minigun", 424, 9);
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_minigun", 424, 16);
							}
						}
					}
				case 4:
					{
						int rnd8 = GetRandomUInt(1,2);
						switch (rnd8)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_minigun", 811, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_minigun", 811, 15);
							}
						}
					}
				case 5:
					{
						int rnd4 = GetRandomUInt(1,8);
						switch (rnd4)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_minigun", 15, 5);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_minigun", 298, 6);
							}
						case 3:
							{
								int rnd13 = GetRandomUInt(1,8);
								switch (rnd13)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_minigun", 793, 11);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_minigun", 802, 11);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_minigun", 882, 11);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_minigun", 891, 11);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_minigun", 900, 11);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_minigun", 909, 11);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_minigun", 958, 11);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_minigun", 967, 11);
									}
								}
							}
						case 4:
							{
								int rnd12 = GetRandomUInt(1,15);
								switch (rnd12)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_minigun", 15004, 15);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_minigun", 15020, 15);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_minigun", 15026, 15);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_minigun", 15031, 15);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_minigun", 15040, 15);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_minigun", 15055, 15);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_minigun", 15086, 15);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_minigun", 15087, 15);
									}
								case 9:
									{
										CreateWeapon(client, "tf_weapon_minigun", 15088, 15);
									}
								case 10:
									{
										CreateWeapon(client, "tf_weapon_minigun", 15098, 15);
									}
								case 11:
									{
										CreateWeapon(client, "tf_weapon_minigun", 15099, 15);
									}
								case 12:
									{
										CreateWeapon(client, "tf_weapon_minigun", 15123, 15);
									}
								case 13:
									{
										CreateWeapon(client, "tf_weapon_minigun", 15124, 15);
									}
								case 14:
									{
										CreateWeapon(client, "tf_weapon_minigun", 15125, 15);
									}
								case 15:
									{
										CreateWeapon(client, "tf_weapon_minigun", 15147, 15);
									}
								}
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_minigun", 202, 11);
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_minigun", 202, 9);
							}
						case 7:
							{
								CreateWeapon(client, "tf_weapon_minigun", 202, 16);
							}
						case 8:
							{
								CreateWeapon(client, "tf_weapon_minigun", 850, 6);
							}
						}
					}					
				}
				
				int rnd2 = GetRandomUInt(1,7);
				TF2_RemoveWeaponSlot(client, 1);
				
				switch (rnd2)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_shotgun_hwg", 425, 6);
					}
				case 2:
					{
						int rnd5 = GetRandomUInt(1,2);
						switch (rnd5)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_shotgun_hwg", 1153, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_shotgun_hwg", 1153, 16);
							}
						}
					}	
				case 3:
					{
						int rnd7 = GetRandomUInt(1,5);
						switch (rnd7)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_shotgun_hwg", 11, 5);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_shotgun_hwg", 1141, 6);
							}
						case 3:
							{
								int rnd11 = GetRandomUInt(1,9);
								switch (rnd11)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_shotgun_hwg", 15003, 15);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_shotgun_hwg", 15016, 15);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_shotgun_hwg", 15044, 15);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_shotgun_hwg", 15047, 15);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_shotgun_hwg", 15085, 15);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_shotgun_hwg", 15109, 15);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_shotgun_hwg", 15132, 15);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_shotgun_hwg", 15133, 15);
									}
								case 9:
									{
										CreateWeapon(client, "tf_weapon_shotgun_hwg", 15152, 15);
									}
								}
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_shotgun_hwg", 199, 16);
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_shotgun_hwg", 199, 11);
							}
						}
					}
				case 4:
					{
						CreateWeapon(client, "tf_weapon_lunchbox", 311, 6);
					}
				case 5:
					{
						int rnd5 = GetRandomUInt(1,3);
						switch (rnd5)
						{
							case 1:
							{
								CreateWeapon(client, "tf_weapon_lunchbox", 42, 6);
							}
							case 2:
							{
								CreateWeapon(client, "tf_weapon_lunchbox", 863, 6);
							}
							case 3:
							{
								CreateWeapon(client, "tf_weapon_lunchbox", 1002, 6);
							}
						}
					}
				case 6:
					{
						int rnd6 = GetRandomUInt(1,2);
						switch (rnd6)
						{
							case 1:
							{
								CreateWeapon(client, "tf_weapon_lunchbox", 159, 6);
							}
							case 2:
							{
								CreateWeapon(client, "tf_weapon_lunchbox", 433, 6);
							}
						}
					}
				case 7:
					{
						CreateWeapon(client, "tf_weapon_lunchbox", 1190, 6);
					}					
				}
			}
			int rnd3 = GetRandomUInt(1,8);
			TF2_RemoveWeaponSlot(client, 2);
			
			switch (rnd3)
			{
			case 1:
				{
					CreateWeapon(client, "tf_weapon_fists", 43, 6);
				}
			case 2:
				{
					int rnd5 = GetRandomUInt(1,3);
					switch (rnd5)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_fists", 239, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_fists", 1100, 6);
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_fists", 1084, 6);
						}
					}
				}
			case 3:
				{
					CreateWeapon(client, "tf_weapon_fists", 310, 6);
				}
			case 4:
				{
					CreateWeapon(client, "tf_weapon_fists", 331, 6);
				}
			case 5:
				{
					CreateWeapon(client, "tf_weapon_fists", 426, 6);
				}
			case 6:
				{
					CreateWeapon(client, "tf_weapon_fists", 656, 6);
				}
			case 7:
				{
					CreateWeapon(client, "tf_weapon_fists", 1184, 6);
				}
			case 8:
				{
					int rnd6 = GetRandomUInt(1,13);
					switch (rnd6)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_fists", 195, 11);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_fists", 587, 6);
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 264, 6);
						}
					case 4:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 423, 11);
						}
					case 5:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 474, 6);
						}
					case 6:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 880, 6);
						}
					case 7:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 939, 6);
						}
					case 8:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 954, 11);
						}
					case 9:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 1013, 6);
						}
					case 10:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 1071, 11);
						}
					case 11:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 1123, 6);
						}
					case 12:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 1127, 6);
						}
					case 13:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 30758, 6);
						}
					}
				}
			}						
		}
		
	case TFClass_Pyro:
		{
			if (!g_bMedieval)
			{
				int rnd = GetRandomUInt(1,5);
				TF2_RemoveWeaponSlot(client, 0);

				switch (rnd)
				{
				case 1:
					{
						int rnd5 = GetRandomUInt(1,2);
						switch (rnd5)
						{
							case 1:
							{
								CreateWeapon(client, "tf_weapon_flamethrower", 40, 6);
							}
							case 2:
							{
								CreateWeapon(client, "tf_weapon_flamethrower", 1146, 6);
							}
						}
					}
				case 2:
					{
						int rnd9 = GetRandomUInt(1,2);
						switch (rnd9)
						{
							case 1:
							{
								CreateWeapon(client, "tf_weapon_flamethrower", 215, 6);
							}
							case 2:
							{
								CreateWeapon(client, "tf_weapon_flamethrower", 215, 16);
							}
						}
					}
				case 3:
					{
						CreateWeapon(client, "tf_weapon_flamethrower", 594, 6);
					}
				case 4:
					{
						CreateWeapon(client, "tf_weapon_rocketlauncher_fireball", 1178, 6);
					}
				case 5:
					{
						int rnd4 = GetRandomUInt(1,9);
						switch (rnd4)
						{
							case 1:
							{
								CreateWeapon(client, "tf_weapon_flamethrower", 21, 5);
							}
							case 2:
							{
								CreateWeapon(client, "tf_weapon_flamethrower", 741, 6);
							}
							case 3:
							{
								CreateWeapon(client, "tf_weapon_flamethrower", 30474, 6);
							}
							case 4:
							{
								int rnd15 = GetRandomUInt(1,8);
								switch (rnd15)
								{
									case 1:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 798, 11);
									}
									case 2:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 807, 11);
									}
									case 3:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 887, 11);
									}
									case 4:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 896, 11);
									}
									case 5:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 905, 11);
									}
									case 6:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 914, 11);
									}
									case 7:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 963, 11);
									}
									case 8:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 972, 11);
									}
								}
							}
							case 5:
							{
								int rnd12 = GetRandomUInt(1,13);
								switch (rnd12)
								{
									case 1:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 15005, 15);
									}
									case 2:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 15017, 15);
									}
									case 3:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 15030, 15);
									}
									case 4:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 15034, 15);
									}
									case 5:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 15049, 15);
									}
									case 6:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 15054, 15);
									}
									case 7:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 15066, 15);
									}
									case 8:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 15067, 15);
									}
									case 9:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 15068, 15);
									}
									case 10:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 15089, 15);
									}
									case 11:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 15090, 15);
									}
									case 12:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 15115, 15);
									}
									case 13:
									{
										CreateWeapon(client, "tf_weapon_flamethrower", 15141, 15);
									}
								}
							}
							case 6:
							{
								CreateWeapon(client, "tf_weapon_flamethrower", 659, 6);
							}
							case 7:
							{
								CreateWeapon(client, "tf_weapon_flamethrower", 208, 11);
							}
							case 8:
							{
								CreateWeapon(client, "tf_weapon_flamethrower", 208, 9);
							}
							case 9:
							{
								CreateWeapon(client, "tf_weapon_flamethrower", 208, 16);
							}
						}
					}	
				}
				
				int rnd2 = GetRandomUInt(1,9);
				TF2_RemoveWeaponSlot(client, 1);
				
				switch (rnd2)
				{
				case 1:
					{
						int rnd7 = GetRandomUInt(1,2);
						switch (rnd7)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_flaregun", 39, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_flaregun", 1081, 6);
							}
						}
					}
				case 2:
					{
						int rnd8 = GetRandomUInt(1,2);
						switch (rnd8)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_flaregun", 351, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_flaregun", 351, 16);
							}
						}
					}
				case 3:
					{
						CreateWeapon(client, "tf_weapon_flaregun_revenge", 595, 6);
					}
				case 4:
					{
						int rnd7 = GetRandomUInt(1,2);
						switch (rnd7)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_flaregun", 740, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_flaregun", 740, 16);
							}
						}
					}
				case 5:
					{
						int rnd5 = GetRandomUInt(1,2);
						switch (rnd5)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 1153, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 1153, 16);
							}
						}
					}
				case 6:
					{
						int rnd6 = GetRandomUInt(1,2);
						switch (rnd6)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 415, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 415, 16);
							}
						}
					}
				case 7:
					{
						CreateWeapon(client, "tf_weapon_jar_gas", 1180, 6);
					}
				case 8:
					{
						CreateWeapon(client, "tf_weapon_rocketpack", 1179, 6);
					}
				case 9:
					{
						int rnd8 = GetRandomUInt(1,5);
						switch (rnd8)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 12, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 1141, 6);
							}
						case 3:
							{
								int rnd11 = GetRandomUInt(1,9);
								switch (rnd11)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_shotgun_pyro", 15003, 15);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_shotgun_pyro", 15016, 15);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_shotgun_pyro", 15044, 15);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_shotgun_pyro", 15047, 15);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_shotgun_pyro", 15085, 15);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_shotgun_pyro", 15109, 15);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_shotgun_pyro", 15132, 15);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_shotgun_pyro", 15133, 15);
									}
								case 9:
									{
										CreateWeapon(client, "tf_weapon_shotgun_pyro", 15152, 15);
									}
								}
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 199, 16);
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_shotgun_pyro", 199, 11);
							}
						}
					}				
				}
			}
			
			int rnd3 = GetRandomUInt(1,9);
			TF2_RemoveWeaponSlot(client, 2);
			
			switch (rnd3)
			{
			case 1:
				{
					int rnd5 = GetRandomUInt(1,4);
					switch (rnd5)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 38, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 457, 6);
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 1000, 6);
						}
					case 4:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 38, 9);
						}
					}
				}
			case 2:
				{
					int rnd6 = GetRandomUInt(1,2);
					switch (rnd6)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 153, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 466, 6);
						}
					}
				}
			case 3:
				{
					int rnd8 = GetRandomUInt(1,2);
					switch (rnd8)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 326, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 326, 16);
						}
					}
				}
			case 4:
				{
					int rnd9 = GetRandomUInt(1,2);
					switch (rnd9)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 214, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 214, 16);
						}
					}
				}
			case 5:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 348, 6);
				}
			case 6:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 593, 6);
				}
			case 7:
				{
					CreateWeapon(client, "tf_weapon_breakable_sign", 813, 6);
				}
			case 8:
				{
					CreateWeapon(client, "tf_weapon_slap", 1181, 6);
				}
			case 9:
				{
					int rnd7 = GetRandomUInt(1,13);
					switch (rnd7)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 192, 11);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 739, 6);
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 264, 6);
						}
					case 4:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 423, 11);
						}
					case 5:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 474, 6);
						}
					case 6:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 880, 6);
						}
					case 7:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 939, 6);
						}
					case 8:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 954, 11);
						}
					case 9:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 1013, 6);
						}
					case 10:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 1071, 11);
						}
					case 11:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 1123, 6);
						}
					case 12:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 1127, 6);
						}
					case 13:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 30758, 6);
						}
					}
				}				
			}			
		}
	case TFClass_Spy:
		{
			if (!g_bMedieval)
			{
				int rnd = GetRandomUInt(1,5);
				TF2_RemoveWeaponSlot(client, 0);
				
				switch (rnd)
				{
				case 1:
					{
						int rnd5 = GetRandomUInt(1,2);
						switch (rnd5)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_revolver", 61, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_revolver", 1006, 6);
							}
						}
					}
				case 2:
					{
						CreateWeapon(client, "tf_weapon_revolver", 224, 6);
					}
				case 3:
					{
						CreateWeapon(client, "tf_weapon_revolver", 460, 6);
					}
				case 4:
					{
						CreateWeapon(client, "tf_weapon_revolver", 525, 6);
					}
				case 5:
					{
						int rnd23 = GetRandomUInt(1,6);
						switch (rnd23)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_revolver", 24, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_revolver", 161, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_revolver", 1142, 6);
							}
						case 4:
							{
								int rnd12 = GetRandomUInt(1,11);
								switch (rnd12)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_revolver", 15011, 15);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_revolver", 15027, 15);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_revolver", 15042, 15);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_revolver", 15051, 15);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_revolver", 15062, 15);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_revolver", 15063, 15);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_revolver", 15064, 15);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_revolver", 15103, 15);
									}
								case 9:
									{
										CreateWeapon(client, "tf_weapon_revolver", 15128, 15);
									}
								case 10:
									{
										CreateWeapon(client, "tf_weapon_revolver", 15129, 15);
									}
								case 11:
									{
										CreateWeapon(client, "tf_weapon_revolver", 15149, 15);
									}
								}
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_revolver", 210, 11);
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_revolver", 210, 16);
							}
						}
					}					
				}
				
				int rnd2 = GetRandomUInt(1,5);
				TF2_RemoveWeaponSlot(client, 1);
				
				switch (rnd2)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_sapper", 810, 6);
					}
				case 2:
					{
						CreateWeapon(client, "tf_weapon_builder", 736, 11);
					}
				case 3:
					{
						CreateWeapon(client, "tf_weapon_sapper", 933, 6);
					}
				case 4:
					{
						CreateWeapon(client, "tf_weapon_sapper", 1080, 6);
					}
				case 5:
					{
						CreateWeapon(client, "tf_weapon_sapper", 1102, 6);
					}
				}
			}
			
			int rnd3 = GetRandomUInt(1,5);
			TF2_RemoveWeaponSlot(client, 2);
			CreateWeapon(client, "tf_weapon_pda_spy", 27, 6);
			
			switch (rnd3)
			{
			case 1:
				{
					CreateWeapon(client, "tf_weapon_knife", 356, 6);
				}
			case 2:
				{
					CreateWeapon(client, "tf_weapon_knife", 461, 6);
				}
			case 3:
				{
					CreateWeapon(client, "tf_weapon_knife", 649, 6);
				}
			case 4:
				{
					int rnd7 = GetRandomUInt(1,2);
					switch (rnd7)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_knife", 225, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_knife", 574, 6);
						}
					}
				}
			case 5:
				{
					int rnd6 = GetRandomUInt(1,11);
					switch (rnd6)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_knife", 194, 16);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_knife", 423, 11);
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_knife", 638, 6);
						}
					case 4:
						{
							CreateWeapon(client, "tf_weapon_knife", 727, 6);
						}
					case 5:
						{
							CreateWeapon(client, "tf_weapon_knife", 1071, 11);
						}
					case 6:
						{
							CreateWeapon(client, "tf_weapon_knife", 30758, 6);
						}
					case 7:
						{
							CreateWeapon(client, "tf_weapon_knife", 665, 6);
						}
					case 8:
						{
							int rnd11 = GetRandomUInt(1,8);
							switch (rnd11)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_knife", 794, 11);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_knife", 803, 11);
								}
							case 3:
								{
									CreateWeapon(client, "tf_weapon_knife", 883, 11);
								}
							case 4:
								{
									CreateWeapon(client, "tf_weapon_knife", 892, 11);
								}
							case 5:
								{
									CreateWeapon(client, "tf_weapon_knife", 901, 11);
								}
							case 6:
								{
									CreateWeapon(client, "tf_weapon_knife", 910, 11);
								}
							case 7:
								{
									CreateWeapon(client, "tf_weapon_knife", 959, 11);
								}
							case 8:
								{
									CreateWeapon(client, "tf_weapon_knife", 968, 11);
								}
							}
						}
					case 9:
						{
							int rnd12 = GetRandomUInt(1,8);
							switch (rnd12)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_knife", 15062, 15);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_knife", 15094, 15);
								}
							case 3:
								{
									CreateWeapon(client, "tf_weapon_knife", 15095, 15);
								}
							case 4:
								{
									CreateWeapon(client, "tf_weapon_knife", 15096, 15);
								}
							case 5:
								{
									CreateWeapon(client, "tf_weapon_knife", 15118, 15);
								}
							case 6:
								{
									CreateWeapon(client, "tf_weapon_knife", 15119, 15);
								}
							case 7:
								{
									CreateWeapon(client, "tf_weapon_knife", 15143, 15);
								}
							case 8:
								{
									CreateWeapon(client, "tf_weapon_knife", 15144, 15);
								}
							}
						}
					case 10:
						{
							CreateWeapon(client, "tf_weapon_knife", 194, 11);
						}
					case 11:
						{
							CreateWeapon(client, "tf_weapon_knife", 194, 9);
						}
					}
				}					
			}

			int rnd4 = GetRandomUInt(1,5);
			TF2_RemoveWeaponSlot(client, 4);

			switch (rnd4)
			{
			case 1:
				{
					CreateWeapon(client, "tf_weapon_invis", 947, 6);
				}
			case 2:
				{
					CreateWeapon(client, "tf_weapon_invis", 212, 11);
				}
			case 3:
				{
					CreateWeapon(client, "tf_weapon_invis", 60, 6);
				}
			case 4:
				{
					CreateWeapon(client, "tf_weapon_invis", 297, 6);
				}
			case 5:
				{
					CreateWeapon(client, "tf_weapon_invis", 59, 6);
				}
			}
		}
	case TFClass_Engineer:
		{
			if (!g_bMedieval)
			{
				int rnd = GetRandomUInt(1,6);
				TF2_RemoveWeaponSlot(client, 0);
				
				switch (rnd)
				{
				case 1:
					{
						int rnd8 = GetRandomUInt(1,3);
						switch (rnd8)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_sentry_revenge", 141, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_sentry_revenge", 1004, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_sentry_revenge", 141, 9);
							}
						}
					}
				case 2:
					{
						int rnd11 = GetRandomUInt(1,2);
						switch (rnd11)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_shotgun_building_rescue", 997, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_shotgun_building_rescue", 997, 16);
							}
						}
					}
				case 3:
					{
						CreateWeapon(client, "tf_weapon_drg_pomson", 588, 6);
					}
				case 4:
					{
						int rnd5 = GetRandomUInt(1,2);
						switch (rnd5)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_shotgun_primary", 1153, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_shotgun_primary", 1153, 16);
							}
						}
					}	
				case 5:
					{
						CreateWeapon(client, "tf_weapon_shotgun_primary", 527, 6);
					}				
				case 6:
					{
						int rnd7 = GetRandomUInt(1,4);
						switch (rnd7)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_shotgun_primary", 9, 5);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_shotgun_primary", 1141, 6);
							}
						case 3:
							{
								int rnd11 = GetRandomUInt(1,9);
								switch (rnd11)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_shotgun_primary", 15003, 15);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_shotgun_primary", 15016, 15);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_shotgun_primary", 15044, 15);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_shotgun_primary", 15047, 15);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_shotgun_primary", 15085, 15);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_shotgun_primary", 15109, 15);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_shotgun_primary", 15132, 15);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_shotgun_primary", 15133, 15);
									}
								case 9:
									{
										CreateWeapon(client, "tf_weapon_shotgun_primary", 15152, 15);
									}
								}
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_shotgun_primary", 199, 16);
							}
						}
					}					
				}
				
				int rnd2 = GetRandomUInt(1,3);
				TF2_RemoveWeaponSlot(client, 1);
				
				switch (rnd2)
				{
				case 1:
					{
						int rnd5 = GetRandomUInt(1,3);
						switch (rnd5)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_laser_pointer", 140, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_laser_pointer", 30668, 15);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_laser_pointer", 1086, 6);
							}
						}
					}
				case 2:
					{
						CreateWeapon(client, "tf_weapon_mechanical_arm", 528, 6);
					}
				case 3:
					{
						int rnd6 = GetRandomUInt(1,5);
						switch (rnd6)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_pistol", 22, 5);
							}
						case 2:
							{
								int rnd7 = GetRandomUInt(1,2);
								switch (rnd7)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_pistol", 160, 3);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_pistol", 294, 6);
									}
								}
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_pistol", 30666, 15);
							}
						case 4:
							{
								int rnd7 = GetRandomUInt(1,13);
								switch (rnd7)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_pistol", 15013, 15);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_pistol", 15018, 15);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_pistol", 15035, 15);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_pistol", 15041, 15);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_pistol", 15046, 15);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_pistol", 15056, 15);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_pistol", 15060, 15);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_pistol", 15061, 15);
									}
								case 9:
									{
										CreateWeapon(client, "tf_weapon_pistol", 15100, 15);
									}
								case 10:
									{
										CreateWeapon(client, "tf_weapon_pistol", 15101, 15);
									}
								case 11:
									{
										CreateWeapon(client, "tf_weapon_pistol", 15102, 15);
									}
								case 12:
									{
										CreateWeapon(client, "tf_weapon_pistol", 15126, 15);
									}
								case 13:
									{
										CreateWeapon(client, "tf_weapon_pistol", 15148, 15);
									}
								}
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_pistol", 209, 16);
							}
						}
					}					
				}
				int rnd4 = GetRandomUInt(1,4);
				if(rnd4 == 1)
				{
					TF2_RemoveWeaponSlot(client, 3);				
					CreateWeapon(client, "tf_weapon_pda_engineer_build", 737, 11);
				}
				else
				{
					TF2_RemoveWeaponSlot(client, 3);				
					CreateWeapon(client, "tf_weapon_pda_engineer_build", 25, 6);
				}				
				
				TF2_RemoveWeaponSlot(client, 4);
				CreateWeapon(client, "tf_weapon_pda_engineer_destroy", 26, 6);					
			}
			int rnd3 = GetRandomUInt(1,5);
			TF2_RemoveWeaponSlot(client, 2);

			switch (rnd3)
			{
			case 1:
				{
					CreateWeapon(client, "tf_weapon_wrench", 155, 6);
				}
			case 2:
				{
					int rnd6 = GetRandomUInt(1,2);
					switch (rnd6)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_wrench", 329, 6);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_wrench", 329, 16);
						}
					}
				}
			case 3:
				{
					CreateWeapon(client, "tf_weapon_robot_arm", 142, 6);
				}
			case 4:
				{
					int rnd5 = GetRandomUInt(1,11);
					switch (rnd5)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_wrench", 197, 11);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_wrench", 169, 6);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_wrench", 423, 11);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_wrench", 1071, 11);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_wrench", 1123, 6);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_wrench", 30758, 6);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_wrench", 662, 6);
						}
						case 8:
						{
							int rnd12 = GetRandomUInt(1,8);
							switch (rnd12)
							{
								case 1:
								{
									CreateWeapon(client, "tf_weapon_wrench", 795, 11);
								}
								case 2:
								{
									CreateWeapon(client, "tf_weapon_wrench", 804, 11);
								}
								case 3:
								{
									CreateWeapon(client, "tf_weapon_wrench", 884, 11);
								}
								case 4:
								{
									CreateWeapon(client, "tf_weapon_wrench", 893, 11);
								}
								case 5:
								{
									CreateWeapon(client, "tf_weapon_wrench", 902, 11);
								}
								case 6:
								{
									CreateWeapon(client, "tf_weapon_wrench", 911, 11);
								}
								case 7:
								{
									CreateWeapon(client, "tf_weapon_wrench", 960, 11);
								}
								case 8:
								{
									CreateWeapon(client, "tf_weapon_wrench", 969, 11);
								}
							}
						}
						case 9:
						{
							int rnd13 = GetRandomUInt(1,7);
							switch (rnd13)
							{
								case 1:
								{
									CreateWeapon(client, "tf_weapon_wrench", 15073, 15);
								}
								case 2:
								{
									CreateWeapon(client, "tf_weapon_wrench", 15074, 15);
								}
								case 3:
								{
									CreateWeapon(client, "tf_weapon_wrench", 15075, 15);
								}
								case 4:
								{
									CreateWeapon(client, "tf_weapon_wrench", 15139, 15);
								}
								case 5:
								{
									CreateWeapon(client, "tf_weapon_wrench", 15140, 15);
								}
								case 6:
								{
									CreateWeapon(client, "tf_weapon_wrench", 15114, 15);
								}
								case 7:
								{
									CreateWeapon(client, "tf_weapon_wrench", 15156, 15);
								}
							}
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_wrench", 197, 9);
						}
						case 11:
						{
							CreateWeapon(client, "tf_weapon_wrench", 197, 16);
						}
					}
				}
			case 5:
				{
					CreateWeapon(client, "tf_weapon_wrench", 589, 6);
				}					
			}	
		}
	}
	CreateTimer(0.1, TimerHealth, client);
}

bool CreateWeapon(int client, char[] classname, int itemindex, int quality, int level = 0)
{
	int weapon = CreateEntityByName(classname);
	
	if (!IsValidEntity(weapon))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", itemindex);	 
	SetEntProp(weapon, Prop_Send, "m_bInitialized", 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);	
	SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1);  	

	if (level)
	{
		SetEntProp(weapon, Prop_Send, "m_iEntityLevel", level);
	}
	else
	{
		SetEntProp(weapon, Prop_Send, "m_iEntityLevel", GetRandomUInt(1,99));
	}

	switch (itemindex)
	{
	case 25:
		{
			DispatchSpawn(weapon);
			EquipPlayerWeapon(client, weapon); 
			
			if(GetRandomInt(1,3) == 1)
			{
				TF2Attrib_SetByName(weapon, "has pipboy build interface", 1.0);
			}
			
			return true; 			
		}
	case 26, 737:
		{
			DispatchSpawn(weapon);
			EquipPlayerWeapon(client, weapon); 

			return true; 			
		}		
	case 735, 736, 810, 933, 1080, 1102:
		{
			SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
			SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
		}			
	case 998:
		{
			SetEntProp(weapon, Prop_Send, "m_nChargeResistType", GetRandomUInt(0,2));
		}
	case 1071:
		{
			TF2Attrib_SetByName(weapon, "item style override", 0.0);
			TF2Attrib_SetByName(weapon, "loot rarity", 1.0);		
			TF2Attrib_SetByName(weapon, "turn to gold", 1.0);
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);				

			DispatchSpawn(weapon);
			EquipPlayerWeapon(client, weapon); 
			
			return true; 
		}		
	}

	if(quality == 9)
	{
		TF2Attrib_SetByName(weapon, "is australium item", 1.0);
		TF2Attrib_SetByName(weapon, "item style override", 1.0);
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);		
	}

	if(itemindex == 200 || itemindex == 220 || itemindex == 448 || itemindex == 15002 || itemindex == 15015 || itemindex == 15021 || itemindex == 15029 || itemindex == 15036 || itemindex == 15053 || itemindex == 15065 || itemindex == 15069 || itemindex == 15106 || itemindex == 15107 || itemindex == 15108 || itemindex == 15131 || itemindex == 15151 || itemindex == 15157 || itemindex == 449 || itemindex == 15013 || itemindex == 15018 || itemindex == 15035 || itemindex == 15041 || itemindex == 15046 || itemindex == 15056 || itemindex == 15060 || itemindex == 15061 || itemindex == 15100 || itemindex == 15101
			|| itemindex == 15102 || itemindex == 15126 || itemindex == 15148 || itemindex == 44 || itemindex == 221 || itemindex == 205 || itemindex == 228 || itemindex == 1104 || itemindex == 15006 || itemindex == 15014 || itemindex == 15028 || itemindex == 15043 || itemindex == 15052 || itemindex == 15057 || itemindex == 15081 || itemindex == 15104 || itemindex == 15105 || itemindex == 15129 || itemindex == 15130 || itemindex == 15150 || itemindex == 196 || itemindex == 447 || itemindex == 208 || itemindex == 215 || itemindex == 1178 || itemindex == 15005 || itemindex == 15017 || itemindex == 15030 || itemindex == 15034
			|| itemindex == 15049 || itemindex == 15054 || itemindex == 15066 || itemindex == 15067 || itemindex == 15068 || itemindex == 15089 || itemindex == 15090 || itemindex == 15115 || itemindex == 15141 || itemindex == 351 || itemindex == 740 || itemindex == 192 || itemindex == 214 || itemindex == 326 || itemindex == 206 || itemindex == 308 || itemindex == 996 || itemindex == 1151 || itemindex == 15077 || itemindex == 15079 || itemindex == 15091 || itemindex == 15092 || itemindex == 15116 || itemindex == 15117 || itemindex == 15142 || itemindex == 15158 || itemindex == 207 || itemindex == 130 || itemindex == 15009
			|| itemindex == 15012 || itemindex == 15024 || itemindex == 15038 || itemindex == 15045 || itemindex == 15048 || itemindex == 15082 || itemindex == 15083 || itemindex == 15084 || itemindex == 15113 || itemindex == 15137 || itemindex == 15138 || itemindex == 15155 || itemindex == 172 || itemindex == 327 || itemindex == 404 || itemindex == 202 || itemindex == 41 || itemindex == 312 || itemindex == 424 || itemindex == 15004 || itemindex == 15020 || itemindex == 15026 || itemindex == 15031 || itemindex == 15040 || itemindex == 15055 || itemindex == 15086 || itemindex == 15087 || itemindex == 15088 || itemindex == 15098
			|| itemindex == 15099 || itemindex == 15123 || itemindex == 15124 || itemindex == 15125 || itemindex == 15147 || itemindex == 425 || itemindex == 997 || itemindex == 197 || itemindex == 329 || itemindex == 15073 || itemindex == 15074 || itemindex == 15075 || itemindex == 15139 || itemindex == 15140 || itemindex == 15114 || itemindex == 15156 || itemindex == 305 || itemindex == 211 || itemindex == 15008 || itemindex == 15010 || itemindex == 15025 || itemindex == 15039 || itemindex == 15050 || itemindex == 15078 || itemindex == 15097 || itemindex == 15121 || itemindex == 15122 || itemindex == 15123 || itemindex == 15145
			|| itemindex == 15146 || itemindex == 35 || itemindex == 411 || itemindex == 37 || itemindex == 304 || itemindex == 201 || itemindex == 402 || itemindex == 15000 || itemindex == 15007 || itemindex == 15019 || itemindex == 15023 || itemindex == 15033 || itemindex == 15059 || itemindex == 15070 || itemindex == 15071 || itemindex == 15072 || itemindex == 15111 || itemindex == 15112 || itemindex == 15135 || itemindex == 15136 || itemindex == 15154 || itemindex == 203 || itemindex == 15001 || itemindex == 15022 || itemindex == 15032 || itemindex == 15037 || itemindex == 15058 || itemindex == 15076 || itemindex == 15110
			|| itemindex == 15134 || itemindex == 15153 || itemindex == 193 || itemindex == 401 || itemindex == 210 || itemindex == 15011 || itemindex == 15027 || itemindex == 15042 || itemindex == 15051 || itemindex == 15062 || itemindex == 15063 || itemindex == 15064 || itemindex == 15103 || itemindex == 15128 || itemindex == 15129 || itemindex == 15149 || itemindex == 194 || itemindex == 649 || itemindex == 15062 || itemindex == 15094 || itemindex == 15095 || itemindex == 15096 || itemindex == 15118 || itemindex == 15119 || itemindex == 15143 || itemindex == 15144 || itemindex == 209 || itemindex == 15013 || itemindex == 15018
			|| itemindex == 15035 || itemindex == 15041 || itemindex == 15046 || itemindex == 15056 || itemindex == 15060 || itemindex == 15061 || itemindex == 15100 || itemindex == 15101 || itemindex == 15102 || itemindex == 15126 || itemindex == 15148 || itemindex == 415 || itemindex == 15003 || itemindex == 15016 || itemindex == 15044 || itemindex == 15047 || itemindex == 15085 || itemindex == 15109 || itemindex == 15132 || itemindex == 15133 || itemindex == 15152 || itemindex == 1153)
	{
		if(GetRandomUInt(1,35) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2053, 1.0);
		}
	}
	
	if(quality == 11)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);	
		if (GetRandomUInt(1,5) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);
		}
		else if (GetRandomUInt(1,5) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 2.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomUInt(1,7) + 0.0);
		}
		else if (GetRandomUInt(1,5) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 3.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomUInt(1,7) + 0.0);
			TF2Attrib_SetByDefIndex(weapon, 2013, GetRandomUInt(2002,2008) + 0.0);
		}
		TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(GetRandomUInt(0, 9000)));
	}

	if (quality == 15)
	{
		switch(itemindex)
		{
		case 30666, 30667, 30668, 30665:
			{
				TF2Attrib_RemoveByDefIndex(weapon, 725);
			}
		default:
			{
				TF2Attrib_SetByDefIndex(weapon, 725, GetRandomFloat(0.0,1.0));
			}
		}
	}

	if (quality == 16)
	{
		quality = 14;
		int paint = GetRandomUInt(200, 283);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
		{		
			paint = GetRandomUInt(300, 310);
		}
		TF2Attrib_SetByDefIndex(weapon, 834, view_as<float>(paint));

		if (GetRandomUInt(1,8) < 7)
		{
			TF2Attrib_SetByDefIndex(weapon, 725, GetRandomFloat(0.0,1.0));		
		}
		
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 14);	
	}
	
	if (quality >0 && quality < 9)
	{
		int rnd4 = GetRandomUInt(1,4);
		switch (rnd4)
		{
		case 1:
			{
				SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 1);
			}
		case 2:
			{
				SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 3);
			}
		case 3:
			{
				SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 7);
			}
		case 4:
			{
				SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);
				if (GetRandomInt(1,5) == 1)
				{
					TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);
				}
				else if (GetRandomInt(1,5) == 2)
				{
					TF2Attrib_SetByDefIndex(weapon, 2025, 2.0);
					TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
				}
				else if (GetRandomInt(1,5) == 3)
				{
					TF2Attrib_SetByDefIndex(weapon, 2025, 3.0);
					TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
					TF2Attrib_SetByDefIndex(weapon, 2013, GetRandomInt(2002,2008) + 0.0);
				}
				
				TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(GetRandomInt(0, 9000)));
			}
		}
	}
	
	if (itemindex == 405 || itemindex == 608 || itemindex == 1101 || itemindex == 133 || itemindex == 444 || itemindex == 57 || itemindex == 231 || itemindex == 642 || itemindex == 131 || itemindex == 406 || itemindex == 1099 || itemindex == 1144)
	{
		DispatchSpawn(weapon);
		SDKCall(g_hEquipWearable, client, weapon);
		CreateTimer(0.1, TimerHealth, client);
	}
	
	else
	{
		DispatchSpawn(weapon);
		EquipPlayerWeapon(client, weapon); 
	}
	
	if (itemindex == 13
			|| itemindex == 200
			|| itemindex == 23
			|| itemindex == 209
			|| itemindex == 18
			|| itemindex == 205
			|| itemindex == 10
			|| itemindex == 199
			|| itemindex == 21
			|| itemindex == 208
			|| itemindex == 12
			|| itemindex == 19
			|| itemindex == 206
			|| itemindex == 20
			|| itemindex == 207
			|| itemindex == 15
			|| itemindex == 202
			|| itemindex == 11
			|| itemindex == 9
			|| itemindex == 22
			|| itemindex == 29
			|| itemindex == 211
			|| itemindex == 14
			|| itemindex == 201
			|| itemindex == 16
			|| itemindex == 203
			|| itemindex == 24
			|| itemindex == 210)	
	{
		if (GetRandomUInt(1,2) == 1)
		{
			TF2_SwitchtoSlot(client, 0);
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);			
			int iRand = GetRandomInt(1,4);
			if (iRand == 1)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 701.0);	
			}
			else if (iRand == 2)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 702.0);	
			}	
			else if (iRand == 3)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 703.0);	
			}
			else if (iRand == 4)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 704.0);	
			}
		}
		if (GetRandomUInt(1,4) == 1)
		{
			TF2_SwitchtoSlot(client, 1);
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);						
			int iRand2 = GetRandomInt(1,4);
			switch (iRand2)
			{
			case 1:
				{
					TF2Attrib_SetByDefIndex(weapon, 134, 701.0);	
				}
			case 2:
				{
					TF2Attrib_SetByDefIndex(weapon, 134, 702.0);	
				}
			case 3:
				{
					TF2Attrib_SetByDefIndex(weapon, 134, 703.0);	
				}
			case 4:
				{
					TF2Attrib_SetByDefIndex(weapon, 134, 704.0);	
				}				
			}				
		}
		
		int iRand2 = GetRandomUInt(1,2);
		if (iRand2 == 1)
		{			
			int paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
			}
			TF2Attrib_SetByDefIndex(weapon, 834, view_as<float>(paint));
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
		}
		
		DispatchSpawn(weapon);
		EquipPlayerWeapon(client, weapon); 		
		
	}
	TF2_SwitchtoSlot(client, 0);
	return true;
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}

stock void TF2_SwitchtoSlot(int client, int slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		char wepclassname[64];
		int wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, wepclassname, sizeof(wepclassname)))
		{
			FakeClientCommandEx(client, "use %s", wepclassname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

Action TimerHealth(Handle timer, any client)
{
	int hp = GetPlayerMaxHp(client);
	
	if (hp > 0)
	{
		SetEntityHealth(client, hp);
	}
}

int GetPlayerMaxHp(int client)
{
	if (!IsClientConnected(client))
	{
		return -1;
	}

	int entity = GetPlayerResourceEntity();

	if (entity == -1)
	{
		return -1;
	}

	return GetEntProp(entity, Prop_Send, "m_iMaxHealth", _, client);
}

void RemoveWeaponWearables(int client)
{
	int edict = -1;
	while((edict = FindEntityByClassname(edict, "tf_wearable")) != -1)
	{
		char netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			int idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if ((idx == 57 || idx == 133 || idx == 231 || idx == 444 || idx == 642 || idx == 405 || idx == 608) &&
					GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				AcceptEntityInput(edict, "Kill");
			}
		}
	}
	
	while((edict = FindEntityByClassname(edict, "tf_weapon_invis")) != -1)
	{
		if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
		{
			AcceptEntityInput(edict, "Kill");
		}
	}
	
	edict = -1;
	while((edict = FindEntityByClassname(edict, "tf_wearable_demoshield")) != -1)
	{
		if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
		{
			AcceptEntityInput(edict, "Kill");
		}
	}
}

void TF2_RemoveAllWearables(int client)
{
	int i = -1;
	while ((i = FindEntityByClassname(i, "tf_wearable*")) != -1)
	{
		if (client != GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity")) continue;
		AcceptEntityInput(i, "Kill");
	}
}  

bool IsPlayerHere(int client)
{
	return (client && IsClientInGame(client));
}