#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.51"

#define BOTH_TEAMS 1
#define RED_TEAM 2
#define BLU_TEAM 3

bool g_bMVM;
bool g_bCVEnabled;
bool g_bCVMVMSupported;
bool g_bCVRandomizeDelay;
int g_iCVTeam;
float g_fCVDelay;
Handle g_hWearableEquip;
Handle g_hTouched[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Give Bots Cosmetics",
	author = "luki1412",
	description = "Gives TF2 bots cosmetics",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=43109"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		FormatEx(error, err_max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVar hCVVersion = CreateConVar("sm_gbc_version", PLUGIN_VERSION, "Give Bots Cosmetics version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	ConVar hCVEnabled = CreateConVar("sm_gbc_enabled", "1", "Enables/disables this plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	ConVar hCVDelay = CreateConVar("sm_gbc_delay", "0.5", "Delay for giving cosmetics to bots", FCVAR_NONE, true, 0.1, true, 30.0);
	ConVar hCVRandomizeDelay = CreateConVar("sm_gbc_randomizedelay", "1", "Whether to randomize delay value by taking sm_gbc_delay as the upper bound and 0.1 as the lower bound. sm_gbc_delay must be bigger than 0.1", FCVAR_NONE, true, 0.0, true, 1.0);
	ConVar hCVTeam = CreateConVar("sm_gbc_team", "1", "Team to give cosmetics to: 1-both, 2-red, 3-blu", FCVAR_NONE, true, 1.0, true, 3.0);
	ConVar hCVMVMSupported = CreateConVar("sm_gbc_mvm", "0", "Enables/disables giving bots cosmetics when MVM mode is enabled", FCVAR_NONE, true, 0.0, true, 1.0);

	OnEnabledChanged(hCVEnabled, "", "");
	HookConVarChange(hCVEnabled, OnEnabledChanged);
	OnMVMSupportedChanged(hCVMVMSupported, "", "");
	HookConVarChange(hCVMVMSupported, OnMVMSupportedChanged);
	OnRandomizeDelayChanged(hCVRandomizeDelay, "", "");
	HookConVarChange(hCVRandomizeDelay, OnRandomizeDelayChanged);
	OnDelayChanged(hCVDelay, "", "");
	HookConVarChange(hCVDelay, OnDelayChanged);
	OnTeamChanged(hCVTeam, "", "");
	HookConVarChange(hCVTeam, OnTeamChanged);
	SetConVarString(hCVVersion, PLUGIN_VERSION);
	AutoExecConfig(true, "Give_Bots_Cosmetics");
	GameData hGameConfig = LoadGameConfigFile("give.bots.stuff");

	if (!hGameConfig)
	{
		SetFailState("Failed to find give.bots.stuff.txt gamedata! Can't continue.");
	}

	StartPrepSDKCall(SDKCall_Player);

	if (!PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Virtual, "EquipWearable"))
	{
		SetFailState("Failed to prepare the SDKCall for giving cosmetics. Try updating gamedata or restarting your server.");
	}

	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWearableEquip = EndPrepSDKCall();

	if (!g_hWearableEquip)
	{
		SetFailState("Failed to prepare the SDKCall for giving cosmetics. Try updating gamedata or restarting your server.");
	}

	delete hGameConfig;
	delete hCVVersion;
	delete hCVRandomizeDelay;
	delete hCVTeam;
	delete hCVMVMSupported;
	delete hCVEnabled;
	delete hCVDelay;
}

public void OnEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(convar))
	{
		g_bCVEnabled = true;
		HookEvent("post_inventory_application", player_inv);
	}
	else
	{
		g_bCVEnabled = false;
		UnhookEvent("post_inventory_application", player_inv);

		for (int i = 0; i < (MAXPLAYERS+1); i++)
		{
			delete g_hTouched[i];
		}
	}
}

public void OnMVMSupportedChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bCVMVMSupported = GetConVarBool(convar);
}

public void OnRandomizeDelayChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bCVRandomizeDelay = GetConVarBool(convar);
}

public void OnDelayChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_fCVDelay = GetConVarFloat(convar);
}

public void OnTeamChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iCVTeam = GetConVarInt(convar);
}

public void OnMapStart()
{
	g_bMVM = GameRules_GetProp("m_bPlayingMannVsMachine") ? true : false;

	for (int i = 0; i < (MAXPLAYERS+1); i++)
	{
		delete g_hTouched[i];
	}
}

public void OnClientDisconnect(int client)
{
	delete g_hTouched[client];
}

public void player_inv(Handle event, const char[] name, bool dontBroadcast)
{
	if (!g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported))
	{
		return;
	}

	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	delete g_hTouched[client];

	if (!IsPlayerHere(client) || !IsPlayerAllowed(client))
	{
		return;
	}

	float cvdelay = g_fCVDelay;

	if (g_bCVRandomizeDelay && (cvdelay > 0.1))
	{
		cvdelay = GetRandomUFloat(0.1, cvdelay);
	}

	g_hTouched[client] = CreateTimer(cvdelay, Timer_GiveCosmetic, userd, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_GiveCosmetic(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	g_hTouched[client] = null;

	if (!g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported) || !IsPlayerHere(client) || !IsPlayerAllowed(client))
	{
		return Plugin_Stop;
	}

	TFClassType class = TF2_GetPlayerClass(client);
	bool faceCovered = GetRandomUInt(0,1) ? SelectAllClassHat(client) : SelectClassHat(client, class);

	if (!faceCovered)
	{
		GetRandomUInt(0,1) ? SelectAllClassFacialCosmetic(client) : SelectClassFacialCosmetic(client, class);

		if (GetRandomUInt(0,1))
		{
			GetRandomUInt(0,1) ? SelectAllClassTorsoCosmetic(client) : SelectClassTorsoCosmetic(client, class);
		}
		else
		{
			GetRandomUInt(0,1) ? SelectAllClassLegsCosmetic(client) : SelectClassLegsCosmetic(client, class);
		}
	}
	else
	{
		GetRandomUInt(0,1) ? SelectAllClassTorsoCosmetic(client) : SelectClassTorsoCosmetic(client, class);
		GetRandomUInt(0,1) ? SelectAllClassLegsCosmetic(client) : SelectClassLegsCosmetic(client, class);
	}

	return Plugin_Continue;
}

bool SelectAllClassHat(int client)
{
	bool face = false;
	int rnd = GetRandomUInt(0,45);

	switch (rnd)
	{
		case 1:
		{
			CreateCosmetic(client, 940, 6, 10); //Ghostly Gibus
		}
		case 2:
		{
			CreateCosmetic(client, 668, 6); //The Full Head of Steam
		}
		case 3:
		{
			CreateCosmetic(client, 774, 6); //The Gentle Munitionne of Leisure
		}
		case 4:
		{
			CreateCosmetic(client, 941, 6, 31); //The Skull Island Topper
		}
		case 5:
		{
			CreateCosmetic(client, 30357, 6); //Dark Falkirk Helm
		}
		case 6:
		{
			CreateCosmetic(client, 538, 6); //Killer Exclusive
		}
		case 7:
		{
			CreateCosmetic(client, 139, 6); //Modest Pile of Hat
		}
		case 8:
		{
			CreateCosmetic(client, 137, 6); //Noble Amassment of Hats
		}
		case 9:
		{
			CreateCosmetic(client, 135, 6); //Towering Pillar of Hats
		}
		case 10:
		{
			CreateCosmetic(client, 30119, 6); //The Federal Casemaker
		}
		case 11:
		{
			CreateCosmetic(client, 252, 6); //Dr's Dapper Topper
		}
		case 12:
		{
			CreateCosmetic(client, 341, 6); //A Rather Festive Tree
		}
		case 13:
		{
			CreateCosmetic(client, 523, 6, 10); //The Sarif Cap
		}
		case 14:
		{
			CreateCosmetic(client, 614, 6); //The Hot Dogger
		}
		case 15:
		{
			CreateCosmetic(client, 611, 6); //The Salty Dog
		}
		case 16:
		{
			CreateCosmetic(client, 671, 6); //The Brown Bomber
		}
		case 17:
		{
			CreateCosmetic(client, 817, 6); //The Human Cannonball
		}
		case 18:
		{
			CreateCosmetic(client, 993, 6); //Antlers
		}
		case 19:
		{
			CreateCosmetic(client, 984, 6); //Tough Stuff Muffs
		}
		case 20:
		{
			CreateCosmetic(client, 1014, 6); //The Brutal Bouffant
		}
		case 21:
		{
			CreateCosmetic(client, 30066, 6); //The Brotherhood of Arms
		}
		case 22:
		{
			CreateCosmetic(client, 30067, 6); //The Well-Rounded Rifleman
		}
		case 23:
		{
			CreateCosmetic(client, 30175, 6); //The Cotton Head
		}
		case 24:
		{
			CreateCosmetic(client, 30177, 6); //Hong Kong Cone
		}
		case 25:
		{
			CreateCosmetic(client, 30313, 6); //The Kiss King
		}
		case 26:
		{
			CreateCosmetic(client, 30307, 6); //Neckwear Headwear
		}
		case 27:
		{
			CreateCosmetic(client, 30329, 6); //The Polar Pullover
		}
		case 28:
		{
			CreateCosmetic(client, 30362, 6); //The Law
		}
		case 29:
		{
			CreateCosmetic(client, 30567, 6); //The Crown of the Old Kingdom
		}
		case 30:
		{
			CreateCosmetic(client, 1164, 6, 50); //Civilian Grade JACK Hat
		}
		case 31:
		{
			CreateCosmetic(client, 920, 6); //The Crone's Dome
		}
		case 32:
		{
			CreateCosmetic(client, 30425, 6); //Tipped Lid
		}
		case 33:
		{
			CreateCosmetic(client, 30413, 6); //The Merc's Mohawk
		}
		case 34:
		{
			CreateCosmetic(client, 921, 6); //The Executioner
			face = true;
		}
		case 35:
		{
			CreateCosmetic(client, 30422, 6); //Vive La France
			face = true;
		}
		case 36:
		{
			CreateCosmetic(client, 291, 6); //Horrific Headsplitter
		}
		case 37:
		{
			CreateCosmetic(client, 345, 6, 10); //MNC hat
		}
		case 38:
		{
			CreateCosmetic(client, 785, 6, 10); //Robot Chicken Hat
		}
		case 39:
		{
			CreateCosmetic(client, 702, 6); //Warsworn Helmet
			face = true;
		}
		case 40:
		{
			CreateCosmetic(client, 634, 6); //Point and Shoot
		}
		case 41:
		{
			CreateCosmetic(client, 942, 6); //Cockfighter
		}
		case 42:
		{
			CreateCosmetic(client, 944, 6); //That 70s Chapeau
			face = true;
		}
		case 43:
		{
			CreateCosmetic(client, 30065, 6); //Hardy Laurel
		}
		case 44:
		{
			CreateCosmetic(client, 30571, 6); //Brimstone
		}
		case 45:
		{
			CreateCosmetic(client, 30473, 6); //MK 50
		}
	}

	return face;
}

bool SelectClassHat(int client, TFClassType class)
{
	bool face = false;
	int rnd = 0;

	switch (class)
	{
		case TFClass_Scout:
		{
			rnd = GetRandomUInt(0,23);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 111, 6); // Baseball Bill's Sports Shine
				}
				case 2:
				{
					CreateCosmetic(client, 106, 6); // Bonk Helm
				}
				case 3:
				{
					CreateCosmetic(client, 107, 6); // Ye Olde Baker Boy
				}
				case 4:
				{
					CreateCosmetic(client, 150, 6); // Scout Beanie
				}
				case 5:
				{
					CreateCosmetic(client, 174, 6); // Whoopee Cap
				}
				case 6:
				{
					CreateCosmetic(client, 249, 6); // Bombing Run
				}
				case 7:
				{
					CreateCosmetic(client, 219, 6); // Milkman
				}
				case 8:
				{
					CreateCosmetic(client, 324, 6); // Flipped Trilby
				}
				case 9:
				{
					CreateCosmetic(client, 346, 6, 10, 10); // MNC Mascot Hat
				}
				case 10:
				{
					CreateCosmetic(client, 453, 6); // Hero's Tail
				}
				case 11:
				{
					CreateCosmetic(client, 539, 6, 10, 10); // El Jefe
				}
				case 12:
				{
					CreateCosmetic(client, 617, 6, 10, 10); // Backwards Ballcap
				}
				case 13:
				{
					CreateCosmetic(client, 633, 6, 10, 10); // Hermes
				}
				case 14:
				{
					CreateCosmetic(client, 652, 6); // Big Elfin Deal
				}
				case 15:
				{
					CreateCosmetic(client, 760, 6); // Front Runner
				}
				case 16:
				{
					CreateCosmetic(client, 765, 6); // Cross-Comm Express
				}
				case 17:
				{
					CreateCosmetic(client, 780, 6); // Fed-Fightin' Fedora
				}
				case 18:
				{
					CreateCosmetic(client, 853, 6); // Crafty Hair
				}
				case 19:
				{
					CreateCosmetic(client, 858, 6); // Hanger-On Hood
					face = true;
				}
				case 20:
				{
					CreateCosmetic(client, 1012, 6); // Wilson Weave
				}
				case 21:
				{
					CreateCosmetic(client, 1040, 6); // Bacteria Blocker
				}
				case 22:
				{
					CreateCosmetic(client, 30059, 6); // Beastly Bonnet
				}
				case 23:
				{
					CreateCosmetic(client, 30078, 6); // Greased Lightning
				}
			}
		}
		case TFClass_Sniper:
		{
			rnd = GetRandomUInt(0,23);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 110, 6); // Master's Yellow Belt
				}
				case 2:
				{
					CreateCosmetic(client, 109, 6); // Professional's Panama
				}
				case 3:
				{
					CreateCosmetic(client, 117, 6); // Ritzy Rick's Hair Fixative
				}
				case 4:
				{
					CreateCosmetic(client, 158, 6); // Sniper Pith Helmet
				}
				case 5:
				{
					CreateCosmetic(client, 181, 6); // Sniper Fishing Hat
				}
				case 6:
				{
					CreateCosmetic(client, 229, 6); // Ol' Snaggletooth
				}
				case 7:
				{
					CreateCosmetic(client, 314, 6); // Larrikin Robin
				}
				case 8:
				{
					CreateCosmetic(client, 344, 6); // Crocleather Slouch
				}
				case 9:
				{
					CreateCosmetic(client, 400, 6); // Desert Marauder
				}
				case 10:
				{
					CreateCosmetic(client, 518, 6, 10, 10); // Anger
					face = true;
				}
				case 11:
				{
					CreateCosmetic(client, 631, 6, 10, 10); // Hat With No Name
				}
				case 12:
				{
					CreateCosmetic(client, 626, 6, 10, 10); // Swagman's Swatter
				}
				case 13:
				{
					CreateCosmetic(client, 600, 6, 10, 10); // Your Worst Nightmare
				}
				case 14:
				{
					CreateCosmetic(client, 720, 6); // Bushman's Boonie
				}
				case 15:
				{
					CreateCosmetic(client, 759, 6); // Fruit Shoot
				}
				case 16:
				{
					CreateCosmetic(client, 783, 6); // HazMat Headcase
					face = true;
				}
				case 17:
				{
					CreateCosmetic(client, 779, 6); // Liquidator's Lid
				}
				case 18:
				{
					CreateCosmetic(client, 819, 6); // Lone Star
				}
				case 19:
				{
					CreateCosmetic(client, 877, 6); // Stovepipe Sniper Shako
				}
				case 20:
				{
					CreateCosmetic(client, 981, 6); // Cold Killer
				}
				case 21:
				{
					CreateCosmetic(client, 1022, 6); // Sydney Straw Boat
				}
				case 22:
				{
					CreateCosmetic(client, 30135, 6); // Wet Works
				}
				case 23:
				{
					CreateCosmetic(client, 30173, 6); // Brim-Full Of Bullets
				}
			}
		}
		case TFClass_Soldier:
		{
			rnd = GetRandomUInt(0,36);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 98, 6); // Stainless Pot
				}
				case 2:
				{
					CreateCosmetic(client, 99, 6); // Tyrant's Helm
				}
				case 3:
				{
					CreateCosmetic(client, 152, 6); // Soldier Samurai Hat
				}
				case 4:
				{
					CreateCosmetic(client, 183, 6); // Soldier Drill Hat
				}
				case 5:
				{
					CreateCosmetic(client, 250, 6); // Chieftain's Challenge
				}
				case 6:
				{
					CreateCosmetic(client, 227, 6); // Grenadier's Softcap
				}
				case 7:
				{
					CreateCosmetic(client, 251, 6); // Stout Shako
				}
				case 8:
				{
					CreateCosmetic(client, 340, 6); // Defiant Spartan
					face = true;
				}
				case 9:
				{
					CreateCosmetic(client, 339, 6); // Exquisite Rack
				}
				case 10:
				{
					CreateCosmetic(client, 391, 6); // Honcho's Headgear
					face = true;
				}
				case 11:
				{
					CreateCosmetic(client, 434, 6); // Bucket Hat
					face = true;
				}
				case 12:
				{
					CreateCosmetic(client, 395, 6); // Furious Fukaamigasa
				}
				case 13:
				{
					CreateCosmetic(client, 378, 6); // Team Captain
				}
				case 14:
				{
					CreateCosmetic(client, 445, 6); // Armored Authority
				}
				case 15:
				{
					CreateCosmetic(client, 417, 6); // Jumper's Jeepcap
				}
				case 16:
				{
					CreateCosmetic(client, 439, 6); // Lord Cockswain's Pith Helmet
				}
				case 17:
				{
					CreateCosmetic(client, 516, 6, 10, 10); // Stahlhelm
				}
				case 18:
				{
					CreateCosmetic(client, 631, 6, 10, 10); // Hat With No Name
				}
				case 19:
				{
					CreateCosmetic(client, 575, 6, 13, 13); // Infernal Impaler
				}
				case 20:
				{
					CreateCosmetic(client, 701, 6); // Lucky Shot
				}
				case 21:
				{
					CreateCosmetic(client, 719, 6); // Battle Bob
				}
				case 22:
				{
					CreateCosmetic(client, 721, 6); // Conquistador
				}
				case 23:
				{
					CreateCosmetic(client, 764, 6); // Cross-Comm Crash Helmet
				}
				case 24:
				{
					CreateCosmetic(client, 732, 6); // Helmet Without a Home
				}
				case 25:
				{
					CreateCosmetic(client, 853, 6); // Crafty Hair
				}
				case 26:
				{
					CreateCosmetic(client, 829, 6); // War Pig
				}
				case 27:
				{
					CreateCosmetic(client, 945, 6); // Chief Constable
				}
				case 28:
				{
					CreateCosmetic(client, 980, 6); // Soldier's Slope Scopers
				}
				case 29:
				{
					CreateCosmetic(client, 360, 6); // Hero's Hachimaki
					face = true;
				}
				case 30:
				{
					CreateCosmetic(client, 1021, 6); // Doe-Boy
				}
				case 31:
				{
					CreateCosmetic(client, 30071, 6); // Cloud Crasher
				}
				case 32:
				{
					CreateCosmetic(client, 30069, 6); // Powdered Practitioner
				}
				case 33:
				{
					CreateCosmetic(client, 30116, 6); // Caribbean Conqueror
					face = true;
				}
				case 34:
				{
					CreateCosmetic(client, 30120, 6); // Rebel Rouser
				}
				case 35:
				{
					CreateCosmetic(client, 30114, 6); // Valley Forge
				}
				case 36:
				{
					CreateCosmetic(client, 30118, 6); // Whirly Warrior
				}
			}
		}
		case TFClass_DemoMan:
		{
			rnd = GetRandomUInt(0,29);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 100, 6); // Glengarry Bonnet
				}
				case 2:
				{
					CreateCosmetic(client, 120, 6); // Scotsman's Stove Pipe
				}
				case 3:
				{
					CreateCosmetic(client, 146, 6); // Demoman Hallmark
				}
				case 4:
				{
					CreateCosmetic(client, 179, 6); // Demoman Tricorne
				}
				case 5:
				{
					CreateCosmetic(client, 259, 6); // Carouser's Capotain
				}
				case 6:
				{
					CreateCosmetic(client, 216, 6); // Rimmed Raincatcher
				}
				case 7:
				{
					CreateCosmetic(client, 255, 6); // Sober Stuntman
				}
				case 8:
				{
					CreateCosmetic(client, 342, 6); // Prince Tavish's Crown
				}
				case 9:
				{
					CreateCosmetic(client, 306, 6); // Scotch Bonnet
				}
				case 10:
				{
					CreateCosmetic(client, 359, 6); // Demo Kabuto
				}
				case 11:
				{
					CreateCosmetic(client, 388, 6); // Private Eye
				}
				case 12:
				{
					CreateCosmetic(client, 390, 6); // Reggaelator
				}
				case 13:
				{
					CreateCosmetic(client, 465, 6); // Conjurer's Cowl
				}
				case 14:
				{
					CreateCosmetic(client, 403, 6); // Sultan's Ceremonial
				}
				case 15:
				{
					CreateCosmetic(client, 480, 6); // Tam O' Shanter
				}
				case 16:
				{
					CreateCosmetic(client, 514, 6, 10, 10); // Mask of the Shaman
					face = true;
				}
				case 17:
				{
					CreateCosmetic(client, 607, 6, 10, 10); // Buccaneer's Bicorne
				}
				case 18:
				{
					CreateCosmetic(client, 631, 6, 10, 10); // Hat With No Name
				}
				case 19:
				{
					CreateCosmetic(client, 604, 6, 10, 10); // Tavish DeGroot Experience
				}
				case 20:
				{
					CreateCosmetic(client, 703, 6); // Bolgan
					face = true;
				}
				case 21:
				{
					CreateCosmetic(client, 876, 6); // K-9 Mane
				}
				case 22:
				{
					CreateCosmetic(client, 289, 6, 31, 31); // Voodoo JuJu
				}
				case 23:
				{
					CreateCosmetic(client, 1012, 6); // Wilson Weave
				}
				case 24:
				{
					CreateCosmetic(client, 30064, 6); // Tartan Shade
				}
				case 25:
				{
					CreateCosmetic(client, 30105, 6); // Black Watch
				}
				case 26:
				{
					CreateCosmetic(client, 30082, 6); // Glasgow Great Helm
					face = true;
				}
				case 27:
				{
					CreateCosmetic(client, 30112, 6); // Stormin' Norman
				}
				case 28:
				{
					CreateCosmetic(client, 30106, 6); // Tartan Spartan
				}
				case 29:
				{
					CreateCosmetic(client, 30180, 6); // Pirate Bandana
				}
			}
		}
		case TFClass_Medic:
		{
			rnd = GetRandomUInt(0,27);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 104, 6); // Otolaryngologist's Mirror
				}
				case 2:
				{
					CreateCosmetic(client, 101, 6); // Vintage Tyrolean
				}
				case 3:
				{
					CreateCosmetic(client, 184, 6); // Medic Gatsby
				}
				case 4:
				{
					CreateCosmetic(client, 303, 6); // Berliner's Bucket Helm
					face = true;
				}
				case 5:
				{
					CreateCosmetic(client, 177, 6); // Medic Goggles
				}
				case 6:
				{
					CreateCosmetic(client, 323, 6); // German Gonzila
				}
				case 7:
				{
					CreateCosmetic(client, 363, 6); // Medic Geisha Hair
				}
				case 8:
				{
					CreateCosmetic(client, 383, 6); // Grimm Hatte
				}
				case 9:
				{
					CreateCosmetic(client, 381, 6); // Medic's Mountain Cap
				}
				case 10:
				{
					CreateCosmetic(client, 388, 6); // Private Eye
				}
				case 11:
				{
					CreateCosmetic(client, 398, 6); // Doctor's Sack
				}
				case 12:
				{
					CreateCosmetic(client, 378, 6); // Team Captain
				}
				case 13:
				{
					CreateCosmetic(client, 467, 6); // Planeswalker Helm
					face = true;
				}
				case 14:
				{
					CreateCosmetic(client, 616, 6, 10, 10); // Surgeon's Stahlhelm
				}
				case 15:
				{
					CreateCosmetic(client, 778, 6); // Gentleman's Ushanka
				}
				case 16:
				{
					CreateCosmetic(client, 853, 6); // Crafty Hair
				}
				case 17:
				{
					CreateCosmetic(client, 867, 6); // Combat Medic's Crusher Cap
				}
				case 18:
				{
					CreateCosmetic(client, 1012, 6); // Wilson Weave
				}
				case 19:
				{
					CreateCosmetic(client, 1039, 6); // Weather Master
				}
				case 20:
				{
					CreateCosmetic(client, 30069, 6); // Powdered Practitioner
				}
				case 21:
				{
					CreateCosmetic(client, 30136, 6); // Baron von Havenaplane
				}
				case 22:
				{
					CreateCosmetic(client, 30127, 6); // Das Gutenkutteharen
				}
				case 23:
				{
					CreateCosmetic(client, 30095, 6); // Das Hazmattenhatten
					face = true;
				}
				case 24:
				{
					CreateCosmetic(client, 30121, 6); // Das Maddendoktor
				}
				case 25:
				{
					CreateCosmetic(client, 30109, 6); // Das Naggenvatcher
				}
				case 26:
				{
					CreateCosmetic(client, 30097, 6); // Das Ubersternmann
				}
				case 27:
				{
					CreateCosmetic(client, 30187, 6); // Slick Cut
				}
			}
		}
		case TFClass_Heavy:
		{
			rnd = GetRandomUInt(0,35);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 96, 6); // Officer's Ushanka
				}
				case 2:
				{
					CreateCosmetic(client, 97, 6); // Tough Guy's Toque
				}
				case 3:
				{
					CreateCosmetic(client, 145, 6); // Heavy Hair
					face = true;
				}
				case 4:
				{
					CreateCosmetic(client, 185, 6); // Heavy Do-rag
				}
				case 5:
				{
					CreateCosmetic(client, 254, 6); // Hard Counter
				}
				case 6:
				{
					CreateCosmetic(client, 246, 6); // Pugilist's Protector
				}
				case 7:
				{
					CreateCosmetic(client, 290, 6, 31, 31); // Cadaver's Cranium
				}
				case 8:
				{
					CreateCosmetic(client, 309, 6); // Big Chief
				}
				case 9:
				{
					CreateCosmetic(client, 330, 6); // Coupe D'isaster
				}
				case 10:
				{
					CreateCosmetic(client, 313, 6); // Magnificent Mongolian
				}
				case 11:
				{
					CreateCosmetic(client, 358, 6); // Heavy Topknot
				}
				case 12:
				{
					CreateCosmetic(client, 380, 6); // Large Luchadore
					face = true;
				}
				case 13:
				{
					CreateCosmetic(client, 378, 6); // Team Captain
				}
				case 14:
				{
					CreateCosmetic(client, 427, 6); // Capone's Capper
				}
				case 15:
				{
					CreateCosmetic(client, 485, 6); // Big Steel Jaw of Summer Fun
				}
				case 16:
				{
					CreateCosmetic(client, 478, 6); // Copper's Hard Top
				}
				case 17:
				{
					CreateCosmetic(client, 515, 6, 10, 10); // Pilotka
				}
				case 18:
				{
					CreateCosmetic(client, 517, 6, 10, 10); // Dragonborn Helmet
					face = true;
				}
				case 19:
				{
					CreateCosmetic(client, 613, 6, 10, 10); // Gym Rat
				}
				case 20:
				{
					CreateCosmetic(client, 601, 6, 10, 10); // One-Man Army
				}
				case 21:
				{
					CreateCosmetic(client, 603, 6, 10, 10); // Outdoorsman
				}
				case 22:
				{
					CreateCosmetic(client, 585, 6, 10, 10); // Cold War Luchador
					face = true;
				}
				case 23:
				{
					CreateCosmetic(client, 635, 6, 10, 10); // War Head
				}
				case 24:
				{
					CreateCosmetic(client, 853, 6); // Crafty Hair
				}
				case 25:
				{
					CreateCosmetic(client, 821, 6); // Soviet Gentleman
				}
				case 26:
				{
					CreateCosmetic(client, 866, 6); // Heavy Artillery Officer's Cap
				}
				case 27:
				{
					CreateCosmetic(client, 876, 6); // K-9 Mane
				}
				case 28:
				{
					CreateCosmetic(client, 952, 6); // Brock's Locks
				}
				case 29:
				{
					CreateCosmetic(client, 989, 6); // Carl
					face = true;
				}
				case 30:
				{
					CreateCosmetic(client, 985, 6); // Heavy's Hockey Hair
				}
				case 31:
				{
					CreateCosmetic(client, 1018, 6); // Pounding Father
				}
				case 32:
				{
					CreateCosmetic(client, 1012, 6); // Wilson Weave
				}
				case 33:
				{
					CreateCosmetic(client, 30122, 6); // Bear Necessities
				}
				case 34:
				{
					CreateCosmetic(client, 30094, 6); // Katyusha
				}
				case 35:
				{
					CreateCosmetic(client, 30081, 6); // Tsarboosh
				}
			}
		}
		case TFClass_Pyro:
		{
			rnd = GetRandomUInt(0,37);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 105, 6); // Brigade Helm
				}
				case 2:
				{
					CreateCosmetic(client, 102, 6); // Respectless Rubber Glove
				}
				case 3:
				{
					CreateCosmetic(client, 151, 6); // Pyro Brain Sucker
				}
				case 4:
				{
					CreateCosmetic(client, 182, 6); // Pyro Helm
				}
				case 5:
				{
					CreateCosmetic(client, 213, 6); // Attendant
				}
				case 6:
				{
					CreateCosmetic(client, 253, 6); // Handyman's Handle
				}
				case 7:
				{
					CreateCosmetic(client, 248, 6); // Napper's Respite
				}
				case 8:
				{
					CreateCosmetic(client, 247, 6); // Old Guadalajara
				}
				case 9:
				{
					CreateCosmetic(client, 321, 6); // Madame Dixie
				}
				case 10:
				{
					CreateCosmetic(client, 318, 6); // Prancer's Pride
				}
				case 11:
				{
					CreateCosmetic(client, 435, 6); // Traffic Cone
				}
				case 12:
				{
					CreateCosmetic(client, 394, 6); // Connoisseur's Cap
				}
				case 13:
				{
					CreateCosmetic(client, 377, 6); // Hottie's Hoodie
				}
				case 14:
				{
					CreateCosmetic(client, 481, 6); // Stately Steel Toe
				}
				case 15:
				{
					CreateCosmetic(client, 615, 6, 10, 10); // Birdcage
				}
				case 16:
				{
					CreateCosmetic(client, 627, 6, 10, 10); // Flamboyant Flamenco
				}
				case 17:
				{
					CreateCosmetic(client, 612, 6, 20, 20); // Little Buddy
				}
				case 18:
				{
					CreateCosmetic(client, 597, 6); // Bubble Pipe
				}
				case 19:
				{
					CreateCosmetic(client, 644, 6); // Head Warmer
				}
				case 20:
				{
					CreateCosmetic(client, 571, 6, 13, 13); // Apparition's Aspect
					face = true;
				}
				case 21:
				{
					CreateCosmetic(client, 570, 6, 13, 13); // Last Breath
					face = true;
				}
				case 22:
				{
					CreateCosmetic(client, 753, 6); // Waxy Wayfinder
				}
				case 23:
				{
					CreateCosmetic(client, 783, 6); // HazMat Headcase
					face = true;
				}
				case 24:
				{
					CreateCosmetic(client, 854, 6); // Area 451
					face = true;
				}
				case 25:
				{
					CreateCosmetic(client, 937, 6); // Wraith Wrap
				}
				case 26:
				{
					CreateCosmetic(client, 949, 6); // DethKapp
				}
				case 27:
				{
					CreateCosmetic(client, 950, 6); // Nose Candy
					face = true;
				}
				case 28:
				{
					CreateCosmetic(client, 976, 6); // Winter Wonderland Wrap
					face = true;
				}
				case 29:
				{
					CreateCosmetic(client, 1020, 6); // Person in the Iron Mask
					face = true;
				}
				case 30:
				{
					CreateCosmetic(client, 1038, 6); // Breather Bag
					face = true;
				}
				case 31:
				{
					CreateCosmetic(client, 30063, 6); // Centurion
				}
				case 32:
				{
					CreateCosmetic(client, 30075, 6); // Mair Mask
					face = true;
				}
				case 33:
				{
					CreateCosmetic(client, 30091, 6); // Burning Bandana
				}
				case 34:
				{
					CreateCosmetic(client, 30093, 6); // Hive Minder
				}
				case 35:
				{
					CreateCosmetic(client, 30139, 6); // Pampered Pyro
				}
				case 36:
				{
					CreateCosmetic(client, 30163, 6); // Air Raider
					face = true;
				}
				case 37:
				{
					CreateCosmetic(client, 30162, 6); // Bone Dome
				}
			}
		}
		case TFClass_Spy:
		{
			rnd = GetRandomUInt(0,20);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 108, 6); // Backbiter's Billycock
				}
				case 2:
				{
					CreateCosmetic(client, 147, 6); // Spy Noble Hair
				}
				case 3:
				{
					CreateCosmetic(client, 180, 6); // Spy Beret
				}
				case 4:
				{
					CreateCosmetic(client, 223, 6); // Familiar Fez
					face = true;
				}
				case 5:
				{
					CreateCosmetic(client, 319, 6); // Détective Noir
				}
				case 6:
				{
					CreateCosmetic(client, 397, 6); // Charmer's Chapeau
				}
				case 7:
				{
					CreateCosmetic(client, 388, 6); // Private Eye
				}
				case 8:
				{
					CreateCosmetic(client, 437, 6); // Janissary Hat
				}
				case 9:
				{
					CreateCosmetic(client, 459, 6); // Cosa Nostra Cap
				}
				case 10:
				{
					CreateCosmetic(client, 521, 6, 10, 10); // Belltower Spec Ops
				}
				case 11:
				{
					CreateCosmetic(client, 602, 6, 10, 10); // Counterfeit Billycock
				}
				case 12:
				{
					CreateCosmetic(client, 622, 6, 10, 10); // L'Inspecteur
				}
				case 13:
				{
					CreateCosmetic(client, 637, 6, 10, 10); // Dashin' Hashshashin
				}
				case 14:
				{
					CreateCosmetic(client, 825, 6); // Hat of Cards
				}
				case 15:
				{
					CreateCosmetic(client, 872, 6); // Lacking Moral Fiber Mask
					face = true;
				}
				case 16:
				{
					CreateCosmetic(client, 30072, 6); // Pom-Pommed Provocateur
				}
				case 17:
				{
					CreateCosmetic(client, 30069, 6); // Powdered Practitioner
				}
				case 18:
				{
					CreateCosmetic(client, 30128, 6); // Belgian Detective
					face = true;
				}
				case 19:
				{
					CreateCosmetic(client, 30123, 6); // Harmburg
				}
				case 20:
				{
					CreateCosmetic(client, 30182, 6); // L'homme Burglerre
				}
			}
		}
		case TFClass_Engineer:
		{
			rnd = GetRandomUInt(0,22);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 95, 6); // Engineer's Cap
				}
				case 2:
				{
					CreateCosmetic(client, 118, 6); // Texas Slim's Dome Shine
				}
				case 3:
				{
					CreateCosmetic(client, 94, 6); // Texas Ten Gallon
				}
				case 4:
				{
					CreateCosmetic(client, 148, 6); // Engineer Welding Mask
				}
				case 5:
				{
					CreateCosmetic(client, 178, 6); // Engineer Earmuffs
				}
				case 6:
				{
					CreateCosmetic(client, 322, 6); // Buckaroo's Hat
				}
				case 7:
				{
					CreateCosmetic(client, 338, 6); // Industrial Festivizer
				}
				case 8:
				{
					CreateCosmetic(client, 382, 6); // Big Country
				}
				case 9:
				{
					CreateCosmetic(client, 384, 6); // Professor's Peculiarity
					face = true;
				}
				case 10:
				{
					CreateCosmetic(client, 436, 6); // Polish War Babushka
				}
				case 11:
				{
					CreateCosmetic(client, 399, 6); // Ol' Geezer
				}
				case 12:
				{
					CreateCosmetic(client, 379, 6); // Western Wear
				}
				case 13:
				{
					CreateCosmetic(client, 631, 6, 10, 10); // Hat With No Name
				}
				case 14:
				{
					CreateCosmetic(client, 605, 6, 10, 10); // Pencil Pusher
				}
				case 15:
				{
					CreateCosmetic(client, 628, 6, 10, 10); // Virtual Reality Headset
				}
				case 16:
				{
					CreateCosmetic(client, 590); // Brainiac Hairpiece
				}
				case 17:
				{
					CreateCosmetic(client, 853, 6); // Crafty Hair
				}
				case 18:
				{
					CreateCosmetic(client, 988, 6); // Barnstormer
					face = true;
				}
				case 19:
				{
					CreateCosmetic(client, 1012, 6); // Wilson Weave
				}
				case 20:
				{
					CreateCosmetic(client, 1010, 6); // Last Straw
				}
				case 21:
				{
					CreateCosmetic(client, 1017, 6); // Vox Diabolus
				}
				case 22:
				{
					CreateCosmetic(client, 30099, 6); // Pardner's Pompadour
					face = true;
				}
			}
		}
	}

	return face;
}

void SelectAllClassFacialCosmetic(int client)
{
	int rnd = GetRandomUInt(0,10);

	switch (rnd)
	{
		case 1:
		{
			CreateCosmetic(client, 30569, 6); //The Tomb Readers
		}
		case 2:
		{
			CreateCosmetic(client, 744, 6); //Pyrovision Goggles
		}
		case 3:
		{
			CreateCosmetic(client, 522, 6); //The Deus Specs
		}
		case 4:
		{
			CreateCosmetic(client, 816, 6); //The Marxman
		}
		case 5:
		{
			CreateCosmetic(client, 30104, 6); //Graybanns
		}
		case 6:
		{
			CreateCosmetic(client, 30306, 6); //The Dictator
		}
		case 7:
		{
			CreateCosmetic(client, 30352, 6); //The Mustachioed Mann
		}
		case 8:
		{
			CreateCosmetic(client, 30414, 6); //The Eye-Catcher
		}
		case 9:
		{
			CreateCosmetic(client, 30140, 6); //The Virtual Viewfinder
		}
		case 10:
		{
			CreateCosmetic(client, 30397, 6); //The Bruiser's Bandanna
		}
	}
}

void SelectClassFacialCosmetic(int client, TFClassType class)
{
	int rnd = 0;

	switch (class)
	{
		case TFClass_Scout:
		{
			rnd = GetRandomUInt(0,5);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 460, 6); // Scout MtG Hat
				}
				case 2:
				{
					CreateCosmetic(client, 451, 6); // Bonk Boy
				}
				case 3:
				{
					CreateCosmetic(client, 630, 6); // Stereoscopic Shades
				}
				case 4:
				{
					CreateCosmetic(client, 986, 6); // Mutton Mann
				}
				case 5:
				{
					CreateCosmetic(client, 30085, 6); // Macho Mann
				}
			}
		}
		case TFClass_Sniper:
		{
			rnd = GetRandomUInt(0,5);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 393, 6); // Villain's Veil
				}
				case 2:
				{
					CreateCosmetic(client, 647, 6, 15, 15); // All-Father
				}
				case 3:
				{
					CreateCosmetic(client, 766, 6); // Doublecross-Comm
				}
				case 4:
				{
					CreateCosmetic(client, 986, 6); // Mutton Mann
				}
				case 5:
				{
					CreateCosmetic(client, 30085, 6); // Macho Mann
				}
			}
		}
		case TFClass_Soldier:
		{
			rnd = GetRandomUInt(0,7);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 440, 6); // Lord Cockswain's Novelty Mutton Chops and Pipe
				}
				case 2:
				{
					CreateCosmetic(client, 647, 6, 15, 15); // All-Father
				}
				case 3:
				{
					CreateCosmetic(client, 875, 6); // Menpo
				}
				case 4:
				{
					CreateCosmetic(client, 986, 6); // Mutton Mann
				}
				case 5:
				{
					CreateCosmetic(client, 30085, 6); // Macho Mann
				}
				case 6:
				{
					CreateCosmetic(client, 30165, 6); // Cuban Bristle Crisis
				}
				case 7:
				{
					CreateCosmetic(client, 30164, 6); // Viking Braider
				}
			}
		}
		case TFClass_DemoMan:
		{
			rnd = GetRandomUInt(0,7);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 647, 6, 15, 15); // All-Father
				}
				case 2:
				{
					CreateCosmetic(client, 709, 6); // Snapped Pupil
				}
				case 3:
				{
					CreateCosmetic(client, 830, 6); // Bearded Bombardier
				}
				case 4:
				{
					CreateCosmetic(client, 875, 6); // Menpo
				}
				case 5:
				{
					CreateCosmetic(client, 986, 6); // Mutton Mann
				}
				case 6:
				{
					CreateCosmetic(client, 1019, 6); // Blind Justice
				}
				case 7:
				{
					CreateCosmetic(client, 30085, 6); // Macho Mann
				}
			}
		}
		case TFClass_Medic:
		{
			rnd = GetRandomUInt(0,8);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 315, 6); // Blighted Beak
				}
				case 2:
				{
					CreateCosmetic(client, 144, 6); // Medic Mask
				}
				case 3:
				{
					CreateCosmetic(client, 647, 6, 15, 15); // All-Father
				}
				case 4:
				{
					CreateCosmetic(client, 657, 6); // Nine-Pipe Problem
				}
				case 5:
				{
					CreateCosmetic(client, 826, 6); // Medi-Mask
				}
				case 6:
				{
					CreateCosmetic(client, 986, 6); // Mutton Mann
				}
				case 7:
				{
					CreateCosmetic(client, 30085, 6); // Macho Mann
				}
				case 8:
				{
					CreateCosmetic(client, 30186, 6); // A Brush with Death
				}
			}
		}
		case TFClass_Heavy:
		{
			rnd = GetRandomUInt(0,7);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 479, 6); // Security Shades
				}
				case 2:
				{
					CreateCosmetic(client, 647, 6, 15, 15); // All-Father
				}
				case 3:
				{
					CreateCosmetic(client, 986, 6); // Mutton Mann
				}
				case 4:
				{
					CreateCosmetic(client, 30141, 6); // Gabe Glasses
				}
				case 5:
				{
					CreateCosmetic(client, 30085, 6); // Macho Mann
				}
				case 6:
				{
					CreateCosmetic(client, 30165, 6); // Cuban Bristle Crisis
				}
				case 7:
				{
					CreateCosmetic(client, 30164, 6); // Viking Braider
				}
			}
		}
		case TFClass_Pyro:
		{
			rnd = GetRandomUInt(0,5);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 316, 6); // Pyromancer's Mask
				}
				case 2:
				{
					CreateCosmetic(client, 175, 6); // Pyro Monocle
				}
				case 3:
				{
					CreateCosmetic(client, 387, 6); // Sight for Sore Eyes
				}
				case 4:
				{
					CreateCosmetic(client, 30176, 6); // Pop-Eyes
				}
				case 5:
				{
					CreateCosmetic(client, 30168, 6); // Special Eyes
				}
			}
		}
		case TFClass_Spy:
		{
			rnd = GetRandomUInt(0,8);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 103, 6); // Camera Beard
				}
				case 2:
				{
					CreateCosmetic(client, 462, 6); // Made Man
				}
				case 3:
				{
					CreateCosmetic(client, 629, 6); // Spectre's Spectacles
				}
				case 4:
				{
					CreateCosmetic(client, 337, 6); // Le Party Phantom
				}
				case 5:
				{
					CreateCosmetic(client, 361, 6); // Spy Oni Mask
				}
				case 6:
				{
					CreateCosmetic(client, 766, 6); // Doublecross-Comm
				}
				case 7:
				{
					CreateCosmetic(client, 919, 6); // Scarecrow
				}
				case 8:
				{
					CreateCosmetic(client, 30085, 6); // Macho Mann
				}
			}
		}
		case TFClass_Engineer:
		{
			rnd = GetRandomUInt(0,10);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 389, 6); // Googly Gazer
				}
				case 2:
				{
					CreateCosmetic(client, 647, 6, 15, 15); // All-Father
				}
				case 3:
				{
					CreateCosmetic(client, 591, 6, 20, 20); // Brainiac Goggles
				}
				case 4:
				{
					CreateCosmetic(client, 986, 6); // Mutton Mann
				}
				case 5:
				{
					CreateCosmetic(client, 1009, 6); // Grizzled Growth
				}
				case 6:
				{
					CreateCosmetic(client, 30085, 6); // Macho Mann
				}
				case 7:
				{
					CreateCosmetic(client, 30165, 6); // Cuban Bristle Crisis
				}
				case 8:
				{
					CreateCosmetic(client, 30164, 6); // Viking Braider
				}
				case 9:
				{
					CreateCosmetic(client, 30168, 6); // Special Eyes
				}
				case 10:
				{
					CreateCosmetic(client, 30172, 6); // Gold Digger
				}
			}
		}
	}
}

void SelectAllClassTorsoCosmetic(int client)
{
	int rnd = GetRandomUInt(0,21);

	switch (rnd)
	{
		case 1:
		{
			CreateCosmetic(client, 868, 6, 20); //Heroic Companion Badge
		}
		case 2:
		{
			CreateCosmetic(client, 583, 6, 20); //Bombinomicon
		}
		case 3:
		{
			CreateCosmetic(client, 586, 6); //Mark of the Saint
		}
		case 4:
		{
			CreateCosmetic(client, 625, 6, 20); //Clan Pride
		}
		case 5:
		{
			CreateCosmetic(client, 619, 6, 20); //Flair!
		}
		case 6:
		{
			CreateCosmetic(client, 1096, 6); //The Baronial Badge
		}
		case 7:
		{
			CreateCosmetic(client, 623, 6, 20); //Photo Badge
		}
		case 8:
		{
			CreateCosmetic(client, 738, 6); //Pet Balloonicorn
		}
		case 9:
		{
			CreateCosmetic(client, 955, 6); //The Tuxxy
		}
		case 10:
		{
			CreateCosmetic(client, 995, 6, 20); //Pet Reindoonicorn
		}
		case 11:
		{
			CreateCosmetic(client, 987, 6); //The Merc's Muffler
		}
		case 12:
		{
			CreateCosmetic(client, 855, 6); //Vigilant Pin
		}
		case 13:
		{
			CreateCosmetic(client, 818, 6); //Awesomenauts Badge
		}
		case 14:
		{
			CreateCosmetic(client, 767, 6); //Atomic Accolade
		}
		case 15:
		{
			CreateCosmetic(client, 718, 6); //Merc Medal
		}
		case 16:
		{
			CreateCosmetic(client, 30309, 6); //Dead of Night
		}
		case 17:
		{
			CreateCosmetic(client, 1024, 6); //Crofts Crest
		}
		case 18:
		{
			CreateCosmetic(client, 992, 6); //Smissmas Wreath
		}
		case 19:
		{
			CreateCosmetic(client, 956, 6); //Faerie Solitaire Pin
		}
		case 20:
		{
			CreateCosmetic(client, 943, 6); //Hitt Mann Badge
		}
		case 21:
		{
			CreateCosmetic(client, 873, 6, 20); //Whale Bone Charm
		}
	}
}

void SelectClassTorsoCosmetic(int client, TFClassType class)
{
	int rnd = 0;

	switch (class)
	{
		case TFClass_Scout:
		{
			rnd = GetRandomUInt(0,19);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 454, 6, 20, 20); // Sign of the Wolf's School
				}
				case 2:
				{
					CreateCosmetic(client, 707, 6); // Boston Boom-Bringer
				}
				case 3:
				{
					CreateCosmetic(client, 722, 6); // Fast Learner
				}
				case 4:
				{
					CreateCosmetic(client, 781, 6); // Dillinger's Duffel
				}
				case 5:
				{
					CreateCosmetic(client, 815, 6); // Champ Stamp
				}
				case 6:
				{
					CreateCosmetic(client, 814, 6); // Triad Trinket
				}
				case 7:
				{
					CreateCosmetic(client, 827, 6); // Track Terrorizer
				}
				case 8:
				{
					CreateCosmetic(client, 925, 6); // Spooky Sleeves
				}
				case 9:
				{
					CreateCosmetic(client, 983, 6); // Digit Divulger
				}
				case 10:
				{
					CreateCosmetic(client, 859, 6); // Flight of the Monarch
				}
				case 11:
				{
					CreateCosmetic(client, 1026, 6); // Tomb Wrapper
				}
				case 12:
				{
					CreateCosmetic(client, 30076, 6); // The Bigg Mann on Campus
				}
				case 13:
				{
					CreateCosmetic(client, 30083, 6); // Caffeine Cooler
				}
				case 14:
				{
					CreateCosmetic(client, 30077, 6); // Cool Cat Cardigan
				}
				case 15:
				{
					CreateCosmetic(client, 30134, 6); // Delinquent's Down Vest
				}
				case 16:
				{
					CreateCosmetic(client, 30084, 6); // Half-Pipe Hurdler
				}
				case 17:
				{
					CreateCosmetic(client, 30185, 6); // Flapjack
				}
				case 18:
				{
					CreateCosmetic(client, 30189, 6); // Frenchman's Formals
				}
				case 19:
				{
					CreateCosmetic(client, 30178, 6); // Weight Room Warmer
				}
			}
		}
		case TFClass_Sniper:
		{
			rnd = GetRandomUInt(0,11);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 618, 6, 20, 20); // The Crocodile Smile
				}
				case 2:
				{
					CreateCosmetic(client, 645, 6, 15, 15); // Outback Intellectual
				}
				case 3:
				{
					CreateCosmetic(client, 815, 6); // Champ Stamp
				}
				case 4:
				{
					CreateCosmetic(client, 814, 6); // Triad Trinket
				}
				case 5:
				{
					CreateCosmetic(client, 925, 6); // Spooky Sleeves
				}
				case 6:
				{
					CreateCosmetic(client, 917, 6); // Sir Hootsalot
				}
				case 7:
				{
					CreateCosmetic(client, 1023, 6); // Steel Songbird
				}
				case 8:
				{
					CreateCosmetic(client, 30103, 6); // Falconer
				}
				case 9:
				{
					CreateCosmetic(client, 30100, 6); // Birdman of Australiacatraz
				}
				case 10:
				{
					CreateCosmetic(client, 30101, 6); // Cobber Chameleon
				}
				case 11:
				{
					CreateCosmetic(client, 30170, 6); // Chronomancer
				}
			}
		}
		case TFClass_Soldier:
		{
			rnd = GetRandomUInt(0,13);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 446, 6); // Fancy Dress Uniform
				}
				case 2:
				{
					CreateCosmetic(client, 650, 6); // Kringle Collection
				}
				case 3:
				{
					CreateCosmetic(client, 641, 6, 20, 20); // Ornament Armament
				}
				case 4:
				{
					CreateCosmetic(client, 768, 6); // Professor's Pineapple
				}
				case 5:
				{
					CreateCosmetic(client, 731, 6); // Captain's Cocktails
				}
				case 6:
				{
					CreateCosmetic(client, 922, 6); // Bonedolier
				}
				case 7:
				{
					CreateCosmetic(client, 936, 6); // Exorcizor
				}
				case 8:
				{
					CreateCosmetic(client, 948, 6); // Deadliest Duckling
				}
				case 9:
				{
					CreateCosmetic(client, 30131, 6); // Brawling Buccaneer
				}
				case 10:
				{
					CreateCosmetic(client, 30115, 6); // Compatriot
				}
				case 11:
				{
					CreateCosmetic(client, 30142, 6); // Founding Father
				}
				case 12:
				{
					CreateCosmetic(client, 30129, 6); // Hornblower
				}
				case 13:
				{
					CreateCosmetic(client, 30126, 6); // Shogun's Shoulder Guard
				}
			}
		}
		case TFClass_DemoMan:
		{
			rnd = GetRandomUInt(0,15);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 610, 6, 20, 20); // A Whiff of the Old Brimstone
				}
				case 2:
				{
					CreateCosmetic(client, 641, 6, 20, 20); // Ornament Armament
				}
				case 3:
				{
					CreateCosmetic(client, 768, 6); // Professor's Pineapple
				}
				case 4:
				{
					CreateCosmetic(client, 771, 6); // Liquor Locker
				}
				case 5:
				{
					CreateCosmetic(client, 776, 6); // Bird-Man of Aberdeen
				}
				case 6:
				{
					CreateCosmetic(client, 874, 6); // King of Scotland Cape
				}
				case 7:
				{
					CreateCosmetic(client, 922, 6); // Bonedolier
				}
				case 8:
				{
					CreateCosmetic(client, 925, 6); // Spooky Sleeves
				}
				case 9:
				{
					CreateCosmetic(client, 948, 6); // Deadliest Duckling
				}
				case 10:
				{
					CreateCosmetic(client, 30073, 6); // Dark Age Defender
				}
				case 11:
				{
					CreateCosmetic(client, 30107, 6); // Gaelic Golf Bag
				}
				case 12:
				{
					CreateCosmetic(client, 30124, 6); // Gaelic Garb
				}
				case 13:
				{
					CreateCosmetic(client, 30110, 6); // Whiskey Bib
				}
				case 14:
				{
					CreateCosmetic(client, 30179, 6); // Hurt Locher
				}
				case 15:
				{
					CreateCosmetic(client, 30178, 6); // Weight Room Warmer
				}
			}
		}
		case TFClass_Medic:
		{
			rnd = GetRandomUInt(0,13);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 620, 6, 20, 20); // Couvre Corner
				}
				case 2:
				{
					CreateCosmetic(client, 621, 6, 20, 20); // Surgeon's Stethoscope
				}
				case 3:
				{
					CreateCosmetic(client, 639, 6, 15, 15); // Dr. Whoa
				}
				case 4:
				{
					CreateCosmetic(client, 754, 6); // Scrap Pack
				}
				case 5:
				{
					CreateCosmetic(client, 769, 6); // Quadwrangler
				}
				case 6:
				{
					CreateCosmetic(client, 878, 6); // Foppish Physician
				}
				case 7:
				{
					CreateCosmetic(client, 936, 6); // Exorcizor
				}
				case 8:
				{
					CreateCosmetic(client, 978, 6); // Der Wintermantel
				}
				case 9:
				{
					CreateCosmetic(client, 982, 6); // Doc's Holiday
				}
				case 10:
				{
					CreateCosmetic(client, 30098, 6); // Das Metalmeatencasen
				}
				case 11:
				{
					CreateCosmetic(client, 30137, 6); // Das Fantzipantzen
				}
				case 12:
				{
					CreateCosmetic(client, 30171, 6); // Medical Mystery
				}
				case 13:
				{
					CreateCosmetic(client, 30190, 6); // Ward
				}
			}
		}
		case TFClass_Heavy:
		{
			rnd = GetRandomUInt(0,13);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 524, 6, 10, 10); // The Purity Fist
				}
				case 2:
				{
					CreateCosmetic(client, 757, 6); // Toss-Proof Towel
				}
				case 3:
				{
					CreateCosmetic(client, 777, 6); // Apparatchik's Apparel
				}
				case 4:
				{
					CreateCosmetic(client, 815, 6); // Champ Stamp
				}
				case 5:
				{
					CreateCosmetic(client, 814, 6); // Triad Trinket
				}
				case 6:
				{
					CreateCosmetic(client, 925, 6); // Spooky Sleeves
				}
				case 7:
				{
					CreateCosmetic(client, 946, 6); // Siberian Sophisticate
				}
				case 8:
				{
					CreateCosmetic(client, 991, 6); // Hunger Force
				}
				case 9:
				{
					CreateCosmetic(client, 30074, 6); // Tyurtlenek
				}
				case 10:
				{
					CreateCosmetic(client, 30138, 6); // Bolshevik Biker
				}
				case 11:
				{
					CreateCosmetic(client, 30108, 6); // Borscht Belt
				}
				case 12:
				{
					CreateCosmetic(client, 30079, 6); // Red Army Robin
				}
				case 13:
				{
					CreateCosmetic(client, 30178, 6); // Weight Room Warmer
				}
			}
		}
		case TFClass_Pyro:
		{
			rnd = GetRandomUInt(0,20);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 632, 6, 15, 15); // Cremator's Conscience
				}
				case 2:
				{
					CreateCosmetic(client, 641, 6, 20, 20); // Ornament Armament
				}
				case 3:
				{
					CreateCosmetic(client, 651, 6); // Jingle Belt
				}
				case 4:
				{
					CreateCosmetic(client, 596, 6, 15, 15); // Moonman Backpack
				}
				case 5:
				{
					CreateCosmetic(client, 754, 6); // Scrap Pack
				}
				case 6:
				{
					CreateCosmetic(client, 768, 6); // Professor's Pineapple
				}
				case 7:
				{
					CreateCosmetic(client, 746, 6); // Burning Bongos
				}
				case 8:
				{
					CreateCosmetic(client, 745, 6); // Infernal Orchestrina
				}
				case 9:
				{
					CreateCosmetic(client, 820, 6); // Russian Rocketeer
				}
				case 10:
				{
					CreateCosmetic(client, 856, 6); // Pyrotechnic Tote
				}
				case 11:
				{
					CreateCosmetic(client, 922, 6); // Bonedolier
				}
				case 12:
				{
					CreateCosmetic(client, 936, 6); // Exorcizor
				}
				case 13:
				{
					CreateCosmetic(client, 938, 6); // Coffin Kit
				}
				case 14:
				{
					CreateCosmetic(client, 948, 6); // Deadliest Duckling
				}
				case 15:
				{
					CreateCosmetic(client, 951, 6); // Rail Spikes
				}
				case 16:
				{
					CreateCosmetic(client, 30062, 6); // Steel Sixpack
				}
				case 17:
				{
					CreateCosmetic(client, 30090, 6); // Backpack Broiler
				}
				case 18:
				{
					CreateCosmetic(client, 30089, 6); // El Muchacho
				}
				case 19:
				{
					CreateCosmetic(client, 30092, 6); // Soot Suit
				}
				case 20:
				{
					CreateCosmetic(client, 30169, 6); // Trickster's Turnout Gear
				}
			}
		}
		case TFClass_Spy:
		{
			rnd = GetRandomUInt(0,11);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 483, 6, 15, 15); // Rogue's Col Roule
				}
				case 2:
				{
					CreateCosmetic(client, 639, 6, 15, 15); // Dr. Whoa
				}
				case 3:
				{
					CreateCosmetic(client, 782, 6); // Business Casual
				}
				case 4:
				{
					CreateCosmetic(client, 814, 6); // Triad Trinket
				}
				case 5:
				{
					CreateCosmetic(client, 879, 6); // Distinguished Rogue
				}
				case 6:
				{
					CreateCosmetic(client, 936, 6); // Exorcizor
				}
				case 7:
				{
					CreateCosmetic(client, 977, 6); // Cut Throat Concierge
				}
				case 8:
				{
					CreateCosmetic(client, 30132, 6); // Blood Banker
				}
				case 9:
				{
					CreateCosmetic(client, 30133, 6); // After Dark
				}
				case 10:
				{
					CreateCosmetic(client, 30189, 6); // Frenchman's Formals
				}
				case 11:
				{
					CreateCosmetic(client, 30183, 6); // Escapist
				}
			}
		}
		case TFClass_Engineer:
		{
			rnd = GetRandomUInt(0,6);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 519, 6, 10, 10); // Pip-Boy
				}
				case 2:
				{
					CreateCosmetic(client, 784, 6); // Idea Tube
				}
				case 3:
				{
					CreateCosmetic(client, 815, 6); // Champ Stamp
				}
				case 4:
				{
					CreateCosmetic(client, 814, 6); // Triad Trinket
				}
				case 5:
				{
					CreateCosmetic(client, 925, 6); // Spooky Sleeves
				}
				case 6:
				{
					CreateCosmetic(client, 30086, 6); // Trash Toter
				}
			}
		}
	}
}

void SelectAllClassLegsCosmetic(int client)
{
	int rnd = GetRandomUInt(0,4);

	switch (rnd)
	{
		case 1:
		{
			CreateCosmetic(client, 1025, 6); //The Fortune Hunter
		}
		case 2:
		{
			CreateCosmetic(client, 30607, 6); //The Pocket Raiders
		}
		case 3:
		{
			CreateCosmetic(client, 30068, 6); //The Breakneck Baggies
		}
		case 4:
		{
			CreateCosmetic(client, 869, 6); //The Rump-o-Lantern
		}
	}
}

void SelectClassLegsCosmetic(int client, TFClassType class)
{
	int rnd = 0;

	switch (class)
	{
		case TFClass_Scout:
		{
			rnd = GetRandomUInt(0,7);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 653, 6, 10, 10); // Bootie Time
				}
				case 2:
				{
					CreateCosmetic(client, 734, 6, 10, 10); // Teufort Tooth Kicker
				}
				case 3:
				{
					CreateCosmetic(client, 924, 6); // Spooky Shoes
				}
				case 4:
				{
					CreateCosmetic(client, 857, 6); // Flunkyware
				}
				case 5:
				{
					CreateCosmetic(client, 1016, 6); // Buck Turner All-Stars
				}
				case 6:
				{
					CreateCosmetic(client, 30060, 6); // Cheet Sheet
				}
				case 7:
				{
					CreateCosmetic(client, 30167, 6); // Beep Boy
				}
			}
		}
		case TFClass_Sniper:
		{
			rnd = GetRandomUInt(0,5);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 646, 6, 15, 15); // Itsy Bitsy Spyer
				}
				case 2:
				{
					CreateCosmetic(client, 734, 6, 10, 10); // Teufort Tooth Kicker
				}
				case 3:
				{
					CreateCosmetic(client, 824, 6); // Koala Compact
				}
				case 4:
				{
					CreateCosmetic(client, 948, 6); // Deadliest Duckling
				}
				case 5:
				{
					CreateCosmetic(client, 30181, 6); // Li'l Snaggletooth
				}
			}
		}
		case TFClass_Soldier:
		{
			rnd = GetRandomUInt(0,4);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 392, 6, 15, 15); // Pocket Medic
				}
				case 2:
				{
					CreateCosmetic(client, 734, 6, 10, 10); // Teufort Tooth Kicker
				}
				case 3:
				{
					CreateCosmetic(client, 30117, 6); // Colonial Clogs
				}
				case 4:
				{
					CreateCosmetic(client, 30130, 6); // Lieutenant Bites
				}
			}
		}
		case TFClass_DemoMan:
		{
			rnd = GetRandomUInt(0,5);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 708, 6); // Aladdin's Private Reserve
				}
				case 2:
				{
					CreateCosmetic(client, 734, 6, 10, 10); // Teufort Tooth Kicker
				}
				case 3:
				{
					CreateCosmetic(client, 979, 6); // Cool Breeze
				}
				case 4:
				{
					CreateCosmetic(client, 1016, 6); // Buck Turner All-Stars
				}
				case 5:
				{
					CreateCosmetic(client, 30061, 6); // Tartantaloons
				}
			}
		}
		case TFClass_Medic:
		{
			rnd = GetRandomUInt(0,2);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 770, 6); // Surgeon's Side Satchel
				}
				case 2:
				{
					CreateCosmetic(client, 30096, 6); // Das Feelinbeterbager
				}
			}
		}
		case TFClass_Heavy:
		{
			rnd = GetRandomUInt(0,4);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 392, 6, 15, 15); // Pocket Medic
				}
				case 2:
				{
					CreateCosmetic(client, 643, 6, 15, 15); // Sandvich Safe
				}
				case 3:
				{
					CreateCosmetic(client, 990, 6); // Aqua Flops
				}
				case 4:
				{
					CreateCosmetic(client, 30080, 6); // Heavy-Weight Champ
				}
			}
		}
		case TFClass_Pyro:
		{
			rnd = GetRandomUInt(0,1);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 30167, 6); // Beep Boy
				}
			}
		}
		case TFClass_Spy:
		{
			rnd = GetRandomUInt(0,2);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 763, 6); // Sneaky Spats of Sneaking
				}
				case 2:
				{
					CreateCosmetic(client, 30125, 6); // Rogue's Brogues
				}
			}
		}
		case TFClass_Engineer:
		{
			rnd = GetRandomUInt(0,13);

			switch (rnd)
			{
				case 1:
				{
					CreateCosmetic(client, 520, 6, 10, 10); // Wingstick
				}
				case 2:
				{
					CreateCosmetic(client, 755, 6); // Texas Half-Pants
				}
				case 3:
				{
					CreateCosmetic(client, 606, 6, 15, 15); // Builder's Blueprints
				}
				case 4:
				{
					CreateCosmetic(client, 484, 6, 15, 15); // Prairie Heel Biters
				}
				case 5:
				{
					CreateCosmetic(client, 386, 6); // Teddy Roosebelt
				}
				case 6:
				{
					CreateCosmetic(client, 646, 6, 15, 15); // Itsy Bitsy Spyer
				}
				case 7:
				{
					CreateCosmetic(client, 670, 6); // Stocking Stuffer
				}
				case 8:
				{
					CreateCosmetic(client, 734, 6, 10, 10); // Teufort Tooth Kicker
				}
				case 9:
				{
					CreateCosmetic(client, 823, 6); // Pocket Purrer
				}
				case 10:
				{
					CreateCosmetic(client, 948, 6); // Deadliest Duckling
				}
				case 11:
				{
					CreateCosmetic(client, 1008, 6); // Prize Plushy
				}
				case 12:
				{
					CreateCosmetic(client, 30070, 6); // Pocket Pyro
				}
				case 13:
				{
					CreateCosmetic(client, 30113, 6); // Flared Frontiersman
				}
				case 14:
				{
					CreateCosmetic(client, 30167, 6); // Beep Boy
				}
			}
		}
	}
}

bool CreateCosmetic(int client, int itemindex, int quality = 6, int minlevel = 1, int maxlevel = 100)
{
	int hat = CreateEntityByName("tf_wearable");

	if (!IsValidEntity(hat))
	{
		LogError("Failed to create a valid entity with class name [tf_wearable]! Skipping.");
		return false;
	}

	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntData(hat, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(hat, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomUInt(minlevel,maxlevel));

	if (!DispatchSpawn(hat))
	{
		LogError("The created cosmetic entity [Class name: tf_wearable, Item index: %i, Index: %i], failed to spawn! Skipping.", itemindex, hat);
		RemoveEntity(hat);
		return false;
	}

	SDKCall(g_hWearableEquip, client, hat);
	return true;
}

bool IsPlayerHere(int client)
{
	return (client && IsClientInGame(client) && IsFakeClient(client) && !IsClientReplay(client) && !IsClientSourceTV(client));
}

bool IsPlayerAllowed(int client)
{
	return ((g_iCVTeam == BOTH_TEAMS) || (GetClientTeam(client) == g_iCVTeam) ? true : false);
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}

float GetRandomUFloat(float min, float max)
{
	return ((GetURandomFloat() * (max - min + 0.01)) + min);
}