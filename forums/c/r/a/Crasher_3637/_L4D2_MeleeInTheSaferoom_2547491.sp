#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "2.0.7modded"

new Handle:g_hEnabled;
new Handle:g_hWeaponRandom;
new Handle:g_hWeaponRandomAmount;
new Handle:g_hWeaponBaseballbat;
new Handle:g_hWeaponCricketbat;
new Handle:g_hWeaponCrowbar;
new Handle:g_hWeaponElectricguitar;
new Handle:g_hWeaponFireaxe;
new Handle:g_hWeaponFryingpan;
new Handle:g_hWeaponGolfclub;
new Handle:g_hWeaponKatana;
new Handle:g_hWeaponMachete;
new Handle:g_hWeaponTonfa;
new Handle:g_hWeapon2handedconcrete;
new Handle:g_hWeaponAetherpickaxe;
new Handle:g_hWeaponAethersword;
new Handle:g_hWeaponArm;
new Handle:g_hWeaponBrokenbottle;
new Handle:g_hWeaponFoamfinger;
new Handle:g_hWeaponLegbone;
new Handle:g_hWeaponBamboo;
new Handle:g_hWeaponBarnacle;
new Handle:g_hWeaponBigoronsword;
new Handle:g_hWeaponBnc;
new Handle:g_hWeaponBottle;
new Handle:g_hWeaponBow;
new Handle:g_hWeaponNail;
new Handle:g_hWeaponSledge;
new Handle:g_hWeaponTorch;
new Handle:g_hWeaponChains;
new Handle:g_hWeaponChair;
new Handle:g_hWeaponChair2;
new Handle:g_hWeaponCombatknife;
new Handle:g_hWeaponComputerkeyboard;
new Handle:g_hWeaponConcrete1;
new Handle:g_hWeaponConcrete2;
new Handle:g_hWeaponCustomammopack;
new Handle:g_hWeaponDaxe;
new Handle:g_hWeaponDekustick;
new Handle:g_hWeaponDhoe;
new Handle:g_hWeaponDoc1;
new Handle:g_hWeaponDshovel;
new Handle:g_hWeaponDsword;
new Handle:g_hWeaponDustpan;
new Handle:g_hWeaponElectricguitar2;
new Handle:g_hWeaponElectricguitar3;
new Handle:g_hWeaponElectricguitar4;
new Handle:g_hWeaponEnchsword;
new Handle:g_hWeaponFishingrod;
new Handle:g_hWeaponFlamethrower;
new Handle:g_hWeaponFoot;
new Handle:g_hWeaponFubar;
new Handle:g_hWeaponGaxe;
new Handle:g_hWeaponGhoe;
new Handle:g_hWeaponGloves;
new Handle:g_hWeaponGman;
new Handle:g_hWeaponGpickaxe;
new Handle:g_hWeaponGshovel;
new Handle:g_hWeaponGuandao;
new Handle:g_hWeaponGuitar;
new Handle:g_hWeaponHammer;
new Handle:g_hWeaponHelmsanduril;
new Handle:g_hWeaponHelmshatchet;
new Handle:g_hWeaponHelmsorcrist;
new Handle:g_hWeaponHelmssting;
new Handle:g_hWeaponHelmsswordshield;
new Handle:g_hWeaponHylianshield;
new Handle:g_hWeaponIaxe;
new Handle:g_hWeaponIhoe;
new Handle:g_hWeaponIpickaxe;
new Handle:g_hWeaponIsword;
new Handle:g_hWeaponKatana2;
new Handle:g_hWeaponKitchenknife;
new Handle:g_hWeaponLamp;
new Handle:g_hWeaponLegosword;
new Handle:g_hWeaponLightsaber;
new Handle:g_hWeaponLobo;
new Handle:g_hWeaponLongsword;
new Handle:g_hWeaponM72law;
new Handle:g_hWeaponMace;
new Handle:g_hWeaponMace2;
new Handle:g_hWeaponMastersword;
new Handle:g_hWeaponMirrorshield;
new Handle:g_hWeaponMop;
new Handle:g_hWeaponMop2;
new Handle:g_hWeaponMuffler;
new Handle:g_hWeaponNailbat;
new Handle:g_hWeaponPickaxe;
new Handle:g_hWeaponPipehammer;
new Handle:g_hWeaponPot;
new Handle:g_hWeaponRiotshield;
new Handle:g_hWeaponRockaxe;
new Handle:g_hWeaponScup;
new Handle:g_hWeaponSh2wood;
new Handle:g_hWeaponShoe;
new Handle:g_hWeaponSlasher;
new Handle:g_hWeaponSpickaxe;
new Handle:g_hWeaponSshovel;
new Handle:g_hWeaponSsword;
new Handle:g_hWeaponSyringegun;
new Handle:g_hWeaponThrower;
new Handle:g_hWeaponTireiron;
new Handle:g_hWeaponTonfariot;
new Handle:g_hWeaponTrashbin;
new Handle:g_hWeaponVampiresword;
new Handle:g_hWeaponWand;
new Handle:g_hWeaponWaterpipe;
new Handle:g_hWeaponWaxe;
new Handle:g_hWeaponWeaponchalice;
new Handle:g_hWeaponWeaponmorgenstern;
new Handle:g_hWeaponWeaponshadowhand;
new Handle:g_hWeaponWeaponsof;
new Handle:g_hWeaponWoodbat;
new Handle:g_hWeaponWpickaxe;
new Handle:g_hWeaponWrench;
new Handle:g_hWeaponWshovel;
new Handle:g_hWeaponWsword;
new Handle:g_hWeaponWulinmiji;

new bool:g_bSpawnedMelee;

new g_iMeleeClassCount = 0;
new g_iMeleeRandomSpawn[20];
new g_iRound = 2;

new String:g_sMeleeClass[16][32];

public Plugin:myinfo =
{
	name = "Melee In The Saferoom Modded",
	author = "Original script by N3wton and modified by Psykotik",
	description = "Spawns a selection of melee weapons in the saferoom, at the start of each round.",
	version = VERSION
};

public OnPluginStart()
{
	decl String:GameName[12];
	GetGameFolderName(GameName, sizeof(GameName));
	if( !StrEqual(GameName, "left4dead2") )
		SetFailState( "Melee In The Saferoom is only supported on left 4 dead 2." );
		
	CreateConVar( "l4d2_MITSR_Version",		VERSION, "The version of Melee In The Saferoom", FCVAR_PLUGIN ); 
	g_hEnabled				    = CreateConVar( "l4d2_MITSR_Enabled",		"1", "Should the plugin be enabled", FCVAR_PLUGIN ); 
	g_hWeaponRandom			    = CreateConVar( "l4d2_MITSR_Random",		"1", "Spawn Random Weapons (1) or custom list (0)", FCVAR_PLUGIN ); 
	g_hWeaponRandomAmount	    = CreateConVar( "l4d2_MITSR_Amount",		"8", "Number of weapons to spawn if l4d2_MITSR_Random is 1", FCVAR_PLUGIN ); 
	g_hWeaponBaseballbat	    = CreateConVar( "l4d2_MITSR_Baseballbat",		"1", "Number of baseball bats to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponCricketbat	        = CreateConVar( "l4d2_MITSR_Cricketbat",		"1", "Number of cricket bats to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponCrowbar	        = CreateConVar( "l4d2_MITSR_Crowbar",		"1", "Number of crowbars to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponElectricguitar	    = CreateConVar( "l4d2_MITSR_Electricguitar",		"1", "Number of electric guitars to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponFireaxe	        = CreateConVar( "l4d2_MITSR_Fireaxe",		"1", "Number of fire axes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponFryingpan	        = CreateConVar( "l4d2_MITSR_Fryingpan",		"1", "Number of frying pans to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponGolfclub	        = CreateConVar( "l4d2_MITSR_Golfclub",		"1", "Number of golf clubs to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponKatana	            = CreateConVar( "l4d2_MITSR_Katana",		"1", "Number of katanas to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponMachete	        = CreateConVar( "l4d2_MITSR_Machete",		"1", "Number of machetes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponTonfa	            = CreateConVar( "l4d2_MITSR_Tonfa",		"1", "Number of nightsticks to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeapon2handedconcrete	= CreateConVar( "l4d2_MITSR_2handedconcrete",		"1", "Number of large concrete sticks to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponAetherpickaxe		= CreateConVar( "l4d2_MITSR_Aetherpickaxe",		"1", "Number of aether pickaxes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponAethersword		= CreateConVar( "l4d2_MITSR_Aethersword",		"1", "Number of aether swords to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponArm			    = CreateConVar( "l4d2_MITSR_Arm",		"1", "Number of arms to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponBrokenbottle		= CreateConVar( "l4d2_MITSR_Brokenbottle",		"1", "Number of brown broken bottles to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponFoamfinger			= CreateConVar( "l4d2_MITSR_Foamfinger",		"1", "Number of foam fingers to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponLegbone			= CreateConVar( "l4d2_MITSR_Legbone",		"1", "Number of leg bones to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponBamboo			    = CreateConVar( "l4d2_MITSR_Bamboo",		"1", "Number of bamboo sticks to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponBarnacle			= CreateConVar( "l4d2_MITSR_Barnacle",		"1", "Number of barnacle guns to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponBigoronsword		= CreateConVar( "l4d2_MITSR_Bigoronsword",		"1", "Number of biggoron swords to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponBnc			    = CreateConVar( "l4d2_MITSR_Bnc",		"1", "Number of flails to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponBottle			    = CreateConVar( "l4d2_MITSR_Bottle",		"1", "Number of green broken bottles to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponBow			    = CreateConVar( "l4d2_MITSR_Bow",		"1", "Number of recurve bows to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponNail			    = CreateConVar( "l4d2_MITSR_Nail",		"1", "Number of pain trains to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponSledge			    = CreateConVar( "l4d2_MITSR_Sledge",		"1", "Number of homewreckers to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponTorch			    = CreateConVar( "l4d2_MITSR_Torch",		"1", "Number of skull torches to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponChains			    = CreateConVar( "l4d2_MITSR_Chains",		"1", "Number of chains to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponChair			    = CreateConVar( "l4d2_MITSR_Chair",		"1", "Number of classroom chairs to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponChair2			    = CreateConVar( "l4d2_MITSR_Chair2",		"1", "Number of wooden chairs to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponCombatknife		= CreateConVar( "l4d2_MITSR_CombatKnife",		"1", "Number of combat knives to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponComputerkeyboard	= CreateConVar( "l4d2_MITSR_ComputerKeyboard",		"1", "Number of computer keyboards to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponConcrete1			= CreateConVar( "l4d2_MITSR_Concrete1",		"1", "Number of medium concrete sticks to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponConcrete2			= CreateConVar( "l4d2_MITSR_Concrete2",		"1", "Number of small concrete sticks to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponCustomammopack		= CreateConVar( "l4d2_MITSR_Customammopack",		"1", "Number of deployable ammo packs to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponDaxe			    = CreateConVar( "l4d2_MITSR_Daxe",		"1", "Number of battleaxes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponDekustick			= CreateConVar( "l4d2_MITSR_Dekustick",		"1", "Number of deku sticks to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponDhoe			    = CreateConVar( "l4d2_MITSR_Dhoe",		"1", "Number of diamond hoes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponDoc1			    = CreateConVar( "l4d2_MITSR_Doc1",		"1", "Number of kink maps to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponDshovel			= CreateConVar( "l4d2_MITSR_Dshovel",		"1", "Number of diamond shovels to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponDsword			    = CreateConVar( "l4d2_MITSR_Dsword",		"1", "Number of diamond swords to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponDustpan			= CreateConVar( "l4d2_MITSR_Dustpan",		"1", "Number of dustpans and brushes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponElectricguitar2	= CreateConVar( "l4d2_MITSR_Electricguitar2",		"1", "Number of black guitars to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponElectricguitar3	= CreateConVar( "l4d2_MITSR_Electricguitar3",		"1", "Number of orange guitars to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponElectricguitar4	= CreateConVar( "l4d2_MITSR_Electricguitar4",		"1", "Number of grey guitars to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponEnchsword			= CreateConVar( "l4d2_MITSR_Enchsword",		"1", "Number of enchanted swords to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponFishingrod			= CreateConVar( "l4d2_MITSR_Fishingrod",		"1", "Number of fishing rods to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponFlamethrower		= CreateConVar( "l4d2_MITSR_Flamethrower",		"1", "Number of makeshift flamethrowers to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponFoot			    = CreateConVar( "l4d2_MITSR_Foot",		"1", "Number of feet to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponFubar			    = CreateConVar( "l4d2_MITSR_Fubar",		"1", "Number of fubars to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponGaxe			    = CreateConVar( "l4d2_MITSR_Gaxe",		"1", "Number of golden axes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponGhoe			    = CreateConVar( "l4d2_MITSR_Ghoe",		"1", "Number of golden hoes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponGloves			    = CreateConVar( "l4d2_MITSR_Gloves",		"1", "Number of boxing gloves to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponGman			    = CreateConVar( "l4d2_MITSR_Gman",		"1", "Number of garbage sets to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponGpickaxe			= CreateConVar( "l4d2_MITSR_Gpickaxe",		"1", "Number of golden pickaxes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponGshovel			= CreateConVar( "l4d2_MITSR_Gshovel",		"1", "Number of golden shovels to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponGuandao			= CreateConVar( "l4d2_MITSR_Guandao",		"1", "Number of guandaos to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponGuitar			    = CreateConVar( "l4d2_MITSR_Guitar",		"1", "Number of black electric guitars to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponHammer			    = CreateConVar( "l4d2_MITSR_Hammer",		"1", "Number of mega hammers to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponHelmsanduril		= CreateConVar( "l4d2_MITSR_Helmsanduril",		"1", "Number of andurils to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponHelmshatchet		= CreateConVar( "l4d2_MITSR_Helmshatchet",		"1", "Number of hatchets to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponHelmsorcrist		= CreateConVar( "l4d2_MITSR_Helmsorcrist",		"1", "Number of orcrists to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponHelmssting			= CreateConVar( "l4d2_MITSR_Helmssting",		"1", "Number of stings to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponHelmsswordshield	= CreateConVar( "l4d2_MITSR_Helmsswordshield",		"1", "Number of warrior sets to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponHylianshield		= CreateConVar( "l4d2_MITSR_Hylianshield",		"1", "Number of hylian shields to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponIaxe			    = CreateConVar( "l4d2_MITSR_Iaxe",		"1", "Number of iron axes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponIhoe			    = CreateConVar( "l4d2_MITSR_Ihoe",		"1", "Number of iron hoes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponIpickaxe			= CreateConVar( "l4d2_MITSR_Ipickaxe",		"1", "Number of iron pickaxes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponIsword			    = CreateConVar( "l4d2_MITSR_Isword",		"1", "Number of iron swords to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponKatana2			= CreateConVar( "l4d2_MITSR_Katana2",		"1", "Number of skyrim katanas to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponKitchenknife		= CreateConVar( "l4d2_MITSR_Kitchenknife",		"1", "Number of kitchen knives to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponLamp			    = CreateConVar( "l4d2_MITSR_Lamp",		"1", "Number of lamps to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponLegosword			= CreateConVar( "l4d2_MITSR_Legosword",		"1", "Number of lego swords to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponLightsaber			= CreateConVar( "l4d2_MITSR_Lightsaber",		"1", "Number of lightsabers to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponLobo			    = CreateConVar( "l4d2_MITSR_Lobo",		"1", "Number of palm daggers to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponLongsword			= CreateConVar( "l4d2_MITSR_Longsword",		"1", "Number of swords and shields to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponM72law			    = CreateConVar( "l4d2_MITSR_M72law",		"1", "Number of m72 laws to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponMace			    = CreateConVar( "l4d2_MITSR_Mace",		"1", "Number of maces to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponMace2			    = CreateConVar( "l4d2_MITSR_Mace2",		"1", "Number of improved maces to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponMastersword		= CreateConVar( "l4d2_MITSR_Mastersword",		"1", "Number of master swords to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponMirrorshield		= CreateConVar( "l4d2_MITSR_Mirrorshield",		"1", "Number of mirror shields to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponMop			    = CreateConVar( "l4d2_MITSR_Mop",		"1", "Number of light blue mops to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponMop2			    = CreateConVar( "l4d2_MITSR_Mop2",		"1", "Number of pink mops to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponMuffler			= CreateConVar( "l4d2_MITSR_Muffler",		"1", "Number of mufflers to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponNailbat			= CreateConVar( "l4d2_MITSR_Nailbat",		"1", "Number of nail bats to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponPickaxe			= CreateConVar( "l4d2_MITSR_Pickaxe",		"1", "Number of pickaxes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponPipehammer			= CreateConVar( "l4d2_MITSR_Pipehammer",		"1", "Number of pipe hammers to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponPot			    = CreateConVar( "l4d2_MITSR_Pot",		"1", "Number of sauce pots to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponRiotshield			= CreateConVar( "l4d2_MITSR_Riotshield",		"1", "Number of riotshields to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponRockaxe			= CreateConVar( "l4d2_MITSR_Rockaxe",		"1", "Number of rockaxes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponScup			    = CreateConVar( "l4d2_MITSR_Scup",		"1", "Number of pink mugs to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponSh2wood			= CreateConVar( "l4d2_MITSR_Sh2wood",		"1", "Number of nail sticks to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponShoe			    = CreateConVar( "l4d2_MITSR_Shoe",		"1", "Number of silver hoes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponSlasher			= CreateConVar( "l4d2_MITSR_Slasher",		"1", "Number of slasher blades to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponSpickaxe			= CreateConVar( "l4d2_MITSR_Spickaxe",		"1", "Number of silver pickaxes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponSshovel			= CreateConVar( "l4d2_MITSR_Sshovel",		"1", "Number of silver shovels to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponSsword			    = CreateConVar( "l4d2_MITSR_Ssword",		"1", "Number of silver swords to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponSyringegun			= CreateConVar( "l4d2_MITSR_Syringegun",		"1", "Number of syringe guns to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponThrower			= CreateConVar( "l4d2_MITSR_Thrower",		"1", "Number of improved makeshift flamethrowers to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponTireiron			= CreateConVar( "l4d2_MITSR_Tireiron",		"1", "Number of tire irons to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponTonfariot			= CreateConVar( "l4d2_MITSR_Tonfariot",		"1", "Number of tonfas and riotshields to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponTrashbin			= CreateConVar( "l4d2_MITSR_Trashbin",		"1", "Number of trash cans to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponVampiresword		= CreateConVar( "l4d2_MITSR_Vampiresword",		"1", "Number of vampire swords to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponWand			    = CreateConVar( "l4d2_MITSR_Wand",		"1", "Number of magic wands to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponWaterpipe			= CreateConVar( "l4d2_MITSR_Waterpipe",		"1", "Number of water pipes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponWaxe			    = CreateConVar( "l4d2_MITSR_Waxe",		"1", "Number of wooden axes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponWeaponchalice		= CreateConVar( "l4d2_MITSR_Weaponchalice",		"1", "Number of chalices to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponWeaponmorgenstern	= CreateConVar( "l4d2_MITSR_Weaponmorgenstern",		"1", "Number of flail maces to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponWeaponshadowhand	= CreateConVar( "l4d2_MITSR_Weaponshadowhand",		"1", "Number of shadow claws to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponWeaponsof			= CreateConVar( "l4d2_MITSR_Weaponsof",		"1", "Number of molten swords to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponWoodbat			= CreateConVar( "l4d2_MITSR_Woodbat",		"1", "Number of wooden bats to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponWpickaxe			= CreateConVar( "l4d2_MITSR_Wpickaxe",		"1", "Number of wooden pickaxes to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponWrench			    = CreateConVar( "l4d2_MITSR_Wrench",		"1", "Number of wrenches to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponWshovel			= CreateConVar( "l4d2_MITSR_Wshovel",		"1", "Number of wooden shovels to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponWsword			    = CreateConVar( "l4d2_MITSR_Wsword",		"1", "Number of wooden swords to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	g_hWeaponWulinmiji			= CreateConVar( "l4d2_MITSR_Wulinmiji",		"1", "Number of wulinmijis to spawn (l4d2_MITSR_Random must be 0)", FCVAR_PLUGIN );
	AutoExecConfig( true, "[L4D2]MeleeInTheSaferoom" );
	
	HookEvent( "round_start", Event_RoundStart );
	
	RegAdminCmd( "sm_melee", Command_SMMelee, ADMFLAG_KICK, "Lists all melee weapons spawnable in current campaign" );
}

public Action:Command_SMMelee(client, args)
{
	for( new i = 0; i < g_iMeleeClassCount; i++ )
	{
		PrintToChat( client, "%d : %s", i, g_sMeleeClass[i] );
	}
}

public OnMapStart()
{
	PrecacheModel( "models/weapons/melee/v_bat.mdl", true );
	PrecacheModel( "models/weapons/melee/v_cricket_bat.mdl", true );
	PrecacheModel( "models/weapons/melee/v_crowbar.mdl", true );
	PrecacheModel( "models/weapons/melee/v_electric_guitar.mdl", true );
	PrecacheModel( "models/weapons/melee/v_fireaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_frying_pan.mdl", true );
	PrecacheModel( "models/weapons/melee/v_golfclub.mdl", true );
	PrecacheModel( "models/weapons/melee/v_katana.mdl", true );
	PrecacheModel( "models/weapons/melee/v_machete.mdl", true );
	PrecacheModel( "models/weapons/melee/v_tonfa.mdl", true );
	PrecacheModel( "models/weapons/melee/v_two_handed_concrete.mdl", true );
	PrecacheModel( "models/weapons/melee/v_aetherpickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_aethersword.mdl", true );
	PrecacheModel( "models/weapons/melee/v_arm.mdl", true );
	PrecacheModel( "models/bunny/weapons/melee/v_b_brokenbottle.mdl", true );
	PrecacheModel( "models/bunny/weapons/melee/v_b_foamfinger.mdl", true );
	PrecacheModel( "models/bunny/weapons/melee/v_b_legbone.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_bamboo.mdl", true );
	PrecacheModel( "models/weapons/melee/v_barnacle.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/v_biggoron.mdl", true );
	PrecacheModel( "models/weapons/melee/v_bnc.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_bottle.mdl", true );
	PrecacheModel( "models/weapons/melee/v_bow.mdl", true );
	PrecacheModel( "models/weapons/melee/v_paintrain.mdl", true );
	PrecacheModel( "models/weapons/melee/v_sledgehammer.mdl", true );
	PrecacheModel( "models/weapons/melee/v_btorch.mdl", true);
	PrecacheModel( "models/byblo/weapons/melee/v_chains.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_chair.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_chair2.mdl", true );
	PrecacheModel( "models/v_models/v_knife_t.mdl", true );
	PrecacheModel( "models/weapons/melee/v_pckeyboard.mdl", true );
	PrecacheModel( "models/weapons/melee/v_concretev1.mdl", true );
	PrecacheModel( "models/weapons/melee/v_concretev2.mdl", true );
	PrecacheModel( "models/weapons/melee/v_ammo_pack.mdl", true );
	PrecacheModel( "models/weapons/melee/v_daxe.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/v_dekustick.mdl", true );
	PrecacheModel( "models/weapons/melee/v_dhoe.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_doc1.mdl", true );
	PrecacheModel( "models/weapons/melee/v_dshovel.mdl", true );
	PrecacheModel( "models/weapons/melee/v_dsword.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_dustpan.mdl", true );
	PrecacheModel( "models/weapons/melee/v_electric_guitar2.mdl", true );
	PrecacheModel( "models/weapons/melee/v_electric_guitar3.mdl", true );
	PrecacheModel( "models/weapons/melee/v_electric_guitar4.mdl", true );
	PrecacheModel( "models/weapons/melee/v_enchsword.mdl", true );
	PrecacheModel( "models/weapons/melee/v_rod.mdl", true );
	PrecacheModel( "models/weapons/melee/v_flamethrower.mdl", true );
	PrecacheModel( "models/weapons/melee/v_foot.mdl", true );
	PrecacheModel( "models/weapons/melee/v_fubar.mdl", true );
	PrecacheModel( "models/weapons/melee/v_gaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_ghoe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_gloves_box.mdl", true );
	PrecacheModel( "models/weapons/melee/v_gman.mdl", true );
	PrecacheModel( "models/weapons/melee/v_gpickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_gshovel.mdl", true );
	PrecacheModel( "models/weapons/melee/v_guandao.mdl", true );
	PrecacheModel( "models/weapons/melee/v_electric_guitrb.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/v_megahammer.mdl", true );
	PrecacheModel( "models/weapons/melee/v_greenhood_anduril.mdl", true );
	PrecacheModel( "models/weapons/melee/v_greenhood_hatchet.mdl", true );
	PrecacheModel( "models/weapons/melee/v_greenhood_orcrist.mdl", true );
	PrecacheModel( "models/weapons/melee/v_greenhood_sting.mdl", true );
	PrecacheModel( "models/weapons/melee/v_splinkswashere.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/v_shield.mdl", true );
	PrecacheModel( "models/weapons/melee/v_iaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_ihoe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_ipickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_isword.mdl", true );
	PrecacheModel( "models/weapons/melee/v_katano.mdl", true );
	PrecacheModel( "models/weapons/melee/v_kitchen.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_lamp.mdl", true );
	PrecacheModel( "models/weapons/melee/v_greenhood_lego.mdl", true );
	PrecacheModel( "models/weapons/v_lightsaber.mdl", true );
	PrecacheModel( "models/weapons/melee/v_lobo.mdl", true );
	PrecacheModel( "models/weapons/melee/v_longsword.mdl", true );
	PrecacheModel( "models/weapons/melee/v_m72law.mdl", true );
	PrecacheModel( "models/weapons/melee/v_mace.mdl", true );
	PrecacheModel( "models/weapons/melee/v_mace2.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/v_msword.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/v_mirrorshield.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_mop.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_mop2.mdl", true );
	PrecacheModel( "models/weapons/melee/v_muffler.mdl", true );
	PrecacheModel( "models/weapons/melee/v_nailbat.mdl", true );
	PrecacheModel( "models/weapons/melee/v_pickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_pipehammer.mdl", true );
	PrecacheModel( "models/weapons/melee/v_sauced_pot.mdl", true );
	PrecacheModel( "models/weapons/melee/v_riotshield.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/v_rockaxe.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/v_scup.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_sh2wood.mdl", true );
	PrecacheModel( "models/weapons/melee/v_shoe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_slasher.mdl", true );
	PrecacheModel( "models/weapons/melee/v_spickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_sshovel.mdl", true );
	PrecacheModel( "models/weapons/melee/v_ssword.mdl", true );
	PrecacheModel( "models/weapons/melee/v_syringe_gun.mdl", true );
	PrecacheModel( "models/weapons/melee/v_thrower.mdl", true );
	PrecacheModel( "models/weapons/melee/v_tireiron.mdl", true );
	PrecacheModel( "models/weapons/melee/v_tonfa_riot.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_trashbin.mdl", true );
	PrecacheModel( "models/weapons/melee/v_vampiresword.mdl", true );
	PrecacheModel( "models/weapons/melee/v_wand.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/v_waterpipe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_waxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_chalice.mdl", true );
	PrecacheModel( "models/weapons/melee/v_morgenstern.mdl", true );
	PrecacheModel( "models/weapons/melee/v_shadowhand.mdl", true );
	PrecacheModel( "models/weapons/melee/v_sof.mdl", true );
	PrecacheModel( "models/weapons/melee/v_btc.mdl", true );
	PrecacheModel( "models/weapons/melee/v_wpickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_wrench.mdl", true );
	PrecacheModel( "models/weapons/melee/v_wshovel.mdl", true );
	PrecacheModel( "models/weapons/melee/v_wsword.mdl", true );
	PrecacheModel( "models/weapons/melee/v_wulinmiji.mdl", true );
	
	PrecacheModel( "models/weapons/melee/w_bat.mdl", true );
	PrecacheModel( "models/weapons/melee/w_cricket_bat.mdl", true );
	PrecacheModel( "models/weapons/melee/w_crowbar.mdl", true );
	PrecacheModel( "models/weapons/melee/w_electric_guitar.mdl", true );
	PrecacheModel( "models/weapons/melee/w_fireaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_frying_pan.mdl", true );
	PrecacheModel( "models/weapons/melee/w_golfclub.mdl", true );
	PrecacheModel( "models/weapons/melee/w_katana.mdl", true );
	PrecacheModel( "models/weapons/melee/w_machete.mdl", true );
	PrecacheModel( "models/weapons/melee/w_tonfa.mdl", true );
	PrecacheModel( "models/weapons/melee/w_two_handed_concrete.mdl", true );
	PrecacheModel( "models/weapons/melee/w_aetherpickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_aethersword.mdl", true );
	PrecacheModel( "models/weapons/melee/w_arm.mdl", true );
	PrecacheModel( "models/bunny/weapons/melee/w_b_brokenbottle.mdl", true );
	PrecacheModel( "models/bunny/weapons/melee/w_b_foamfinger.mdl", true );
	PrecacheModel( "models/bunny/weapons/melee/w_b_legbone.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_bamboo.mdl", true );
	PrecacheModel( "models/weapons/melee/w_barnacle.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/w_biggoron.mdl", true );
	PrecacheModel( "models/weapons/melee/w_bnc.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_bottle.mdl", true );
	PrecacheModel( "models/weapons/melee/w_bow.mdl", true );
	PrecacheModel( "models/weapons/melee/w_paintrain.mdl", true );
	PrecacheModel( "models/weapons/melee/w_sledgehammer.mdl", true );
	PrecacheModel( "models/weapons/melee/w_btorch.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_chains.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_chair.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_chair2.mdl", true );
	PrecacheModel( "models/w_models/weapons/w_knife_t.mdl", true );
	PrecacheModel( "models/weapons/melee/w_pckeyboard.mdl", true );
	PrecacheModel( "models/weapons/melee/w_concretev1.mdl", true );
	PrecacheModel( "models/weapons/melee/w_concretev2.mdl", true );
	PrecacheModel( "models/weapons/melee/w_ammo_pack.mdl", true );
	PrecacheModel( "models/weapons/melee/w_daxe.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/w_dekustick.mdl", true );
	PrecacheModel( "models/weapons/melee/w_dhoe.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_doc1.mdl", true );
	PrecacheModel( "models/weapons/melee/w_dshovel.mdl", true );
	PrecacheModel( "models/weapons/melee/w_dsword.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_dustpan.mdl", true );
	PrecacheModel( "models/weapons/melee/w_electric_guitar2.mdl", true );
	PrecacheModel( "models/weapons/melee/w_electric_guitar3.mdl", true );
	PrecacheModel( "models/weapons/melee/w_electric_guitar4.mdl", true );
	PrecacheModel( "models/weapons/melee/w_enchsword.mdl", true );
	PrecacheModel( "models/weapons/melee/w_rod.mdl", true );
	PrecacheModel( "models/weapons/melee/w_flamethrower.mdl", true );
	PrecacheModel( "models/weapons/melee/w_foot.mdl", true );
	PrecacheModel( "models/weapons/melee/w_fubar.mdl", true );
	PrecacheModel( "models/weapons/melee/w_gaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_ghoe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_gloves_box.mdl", true );
	PrecacheModel( "models/weapons/melee/w_gman.mdl", true );
	PrecacheModel( "models/weapons/melee/w_gpickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_gshovel.mdl", true );
	PrecacheModel( "models/weapons/melee/w_guandao.mdl", true );
	PrecacheModel( "models/weapons/melee/w_electric_guitrb.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/w_megahammer.mdl", true );
	PrecacheModel( "models/weapons/melee/w_greenhood_anduril.mdl", true );
	PrecacheModel( "models/weapons/melee/w_greenhood_hatchet.mdl", true );
	PrecacheModel( "models/weapons/melee/w_greenhood_orcrist.mdl", true );
	PrecacheModel( "models/weapons/melee/w_greenhood_sting.mdl", true );
	PrecacheModel( "models/weapons/melee/w_splinkswashereaswell.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/w_shield.mdl", true );
	PrecacheModel( "models/weapons/melee/w_iaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_ihoe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_ipickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_isword.mdl", true );
	PrecacheModel( "models/weapons/melee/w_katano.mdl", true );
	PrecacheModel( "models/weapons/melee/w_kitchen.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_lamp.mdl", true );
	PrecacheModel( "models/weapons/melee/w_greenhood_lego.mdl", true );
	PrecacheModel( "models/weapons/w_lightsaber.mdl", true );
	PrecacheModel( "models/weapons/melee/w_lobo.mdl", true );
	PrecacheModel( "models/weapons/melee/w_longsword.mdl", true );
	PrecacheModel( "models/weapons/melee/w_m72law.mdl", true );
	PrecacheModel( "models/weapons/melee/w_mace.mdl", true );
	PrecacheModel( "models/weapons/melee/w_mace2.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/w_msword.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/w_mirrorshield.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_mop.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_mop2.mdl", true );
	PrecacheModel( "models/weapons/melee/w_muffler.mdl", true );
	PrecacheModel( "models/weapons/melee/w_nailbat.mdl", true );
	PrecacheModel( "models/weapons/melee/w_pickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_pipehammer.mdl", true );
	PrecacheModel( "models/weapons/melee/w_sauced_pot.mdl", true );
	PrecacheModel( "models/weapons/melee/w_riotshield.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/w_rockaxe.mdl", true );
	PrecacheModel( "models/zelda/weapons/melee/w_scup.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_sh2wood.mdl", true );
	PrecacheModel( "models/weapons/melee/w_shoe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_slasher.mdl", true );
	PrecacheModel( "models/weapons/melee/w_spickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_sshovel.mdl", true );
	PrecacheModel( "models/weapons/melee/w_ssword.mdl", true );
	PrecacheModel( "models/weapons/melee/w_syringe_gun.mdl", true );
	PrecacheModel( "models/weapons/melee/w_thrower.mdl", true );
	PrecacheModel( "models/weapons/melee/w_tireiron.mdl", true );
	PrecacheModel( "models/weapons/melee/w_tonfa_riot.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_trashbin.mdl", true );
	PrecacheModel( "models/weapons/melee/w_vampiresword.mdl", true );
	PrecacheModel( "models/weapons/melee/w_wand.mdl", true );
	PrecacheModel( "models/byblo/weapons/melee/w_waterpipe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_waxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_chalice.mdl", true );
	PrecacheModel( "models/weapons/melee/w_morgenstern.mdl", true );
	PrecacheModel( "models/weapons/melee/w_shadowhand.mdl", true );
	PrecacheModel( "models/weapons/melee/w_sof.mdl", true );
	PrecacheModel( "models/weapons/melee/w_btc.mdl", true );
	PrecacheModel( "models/weapons/melee/w_wpickaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_wrench.mdl", true );
	PrecacheModel( "models/weapons/melee/w_wshovel.mdl", true );
	PrecacheModel( "models/weapons/melee/w_wsword.mdl", true );
	PrecacheModel( "models/weapons/melee/w_wulinmiji.mdl", true );
	
	PrecacheGeneric( "scripts/melee/baseball_bat.txt", true );
	PrecacheGeneric( "scripts/melee/cricket_bat.txt", true );
	PrecacheGeneric( "scripts/melee/crowbar.txt", true );
	PrecacheGeneric( "scripts/melee/electric_guitar.txt", true );
	PrecacheGeneric( "scripts/melee/fireaxe.txt", true );
	PrecacheGeneric( "scripts/melee/frying_pan.txt", true );
	PrecacheGeneric( "scripts/melee/golfclub.txt", true );
	PrecacheGeneric( "scripts/melee/katana.txt", true );
	PrecacheGeneric( "scripts/melee/machete.txt", true );
	PrecacheGeneric( "scripts/melee/tonfa.txt", true );
	PrecacheGeneric( "scripts/melee/2_handed_concrete.txt", true );
	PrecacheGeneric( "scripts/melee/aetherpickaxe.txt", true );
	PrecacheGeneric( "scripts/melee/aethersword.txt", true );
	PrecacheGeneric( "scripts/melee/arm.txt", true );
	PrecacheGeneric( "scripts/melee/b_brokenbottle.txt", true );
	PrecacheGeneric( "scripts/melee/b_foamfinger.txt", true );
	PrecacheGeneric( "scripts/melee/b_legbone.txt", true );
	PrecacheGeneric( "scripts/melee/bamboo.txt", true );
	PrecacheGeneric( "scripts/melee/barnacle.txt", true );
	PrecacheGeneric( "scripts/melee/bigoronsword.txt", true );
	PrecacheGeneric( "scripts/melee/bnc.txt", true );
	PrecacheGeneric( "scripts/melee/bottle.txt", true );
	PrecacheGeneric( "scripts/melee/bow.txt", true );
	PrecacheGeneric( "scripts/melee/bt_nail.txt", true );
	PrecacheGeneric( "scripts/melee/bt_sledge.txt", true );
	PrecacheGeneric( "scripts/melee/btorch.txt", true );
	PrecacheGeneric( "scripts/melee/chains.txt", true );
	PrecacheGeneric( "scripts/melee/chair.txt", true );
	PrecacheGeneric( "scripts/melee/chair2.txt", true );
	PrecacheGeneric( "scripts/melee/combat_knife.txt", true );
	PrecacheGeneric( "scripts/melee/computer_keyboard.txt", true );
	PrecacheGeneric( "scripts/melee/concrete1.txt", true );
	PrecacheGeneric( "scripts/melee/concrete2.txt", true );
	PrecacheGeneric( "scripts/melee/custom_ammo_pack.txt", true );
	PrecacheGeneric( "scripts/melee/daxe.txt", true );
	PrecacheGeneric( "scripts/melee/dekustick.txt", true );
	PrecacheGeneric( "scripts/melee/dhoe.txt", true );
	PrecacheGeneric( "scripts/melee/doc1.txt", true );
	PrecacheGeneric( "scripts/melee/dshovel.txt", true );
	PrecacheGeneric( "scripts/melee/dsword.txt", true );
	PrecacheGeneric( "scripts/melee/dustpan.txt", true );
	PrecacheGeneric( "scripts/melee/electric_guitar2.txt", true );
	PrecacheGeneric( "scripts/melee/electric_guitar3.txt", true );
	PrecacheGeneric( "scripts/melee/electric_guitar4.txt", true );
	PrecacheGeneric( "scripts/melee/enchsword.txt", true );
	PrecacheGeneric( "scripts/melee/fishingrod.txt", true );
	PrecacheGeneric( "scripts/melee/flamethrower.txt", true );
	PrecacheGeneric( "scripts/melee/foot.txt", true );
	PrecacheGeneric( "scripts/melee/fubar.txt", true );
	PrecacheGeneric( "scripts/melee/gaxe.txt", true );
	PrecacheGeneric( "scripts/melee/ghoe.txt", true );
	PrecacheGeneric( "scripts/melee/gloves.txt", true );
	PrecacheGeneric( "scripts/melee/gman.txt", true );
	PrecacheGeneric( "scripts/melee/gpickaxe.txt", true );
	PrecacheGeneric( "scripts/melee/gshovel.txt", true );
	PrecacheGeneric( "scripts/melee/guandao.txt", true );
	PrecacheGeneric( "scripts/melee/guitar.txt", true );
	PrecacheGeneric( "scripts/melee/hammer.txt", true );
	PrecacheGeneric( "scripts/melee/helms_anduril.txt", true );
	PrecacheGeneric( "scripts/melee/helms_hatchet.txt", true );
	PrecacheGeneric( "scripts/melee/helms_orcrist.txt", true );
	PrecacheGeneric( "scripts/melee/helms_sting.txt", true );
	PrecacheGeneric( "scripts/melee/helms_sword_and_shield.txt", true );
	PrecacheGeneric( "scripts/melee/hylianshield.txt", true );
	PrecacheGeneric( "scripts/melee/iaxe.txt", true );
	PrecacheGeneric( "scripts/melee/ihoe.txt", true );
	PrecacheGeneric( "scripts/melee/ipickaxe.txt", true );
	PrecacheGeneric( "scripts/melee/isword.txt", true );
	PrecacheGeneric( "scripts/melee/katana2.txt", true );
	PrecacheGeneric( "scripts/melee/kitchen_knife.txt", true );
	PrecacheGeneric( "scripts/melee/lamp.txt", true );
	PrecacheGeneric( "scripts/melee/legosword.txt", true );
	PrecacheGeneric( "scripts/melee/lightsaber.txt", true );
	PrecacheGeneric( "scripts/melee/lobo.txt", true );
	PrecacheGeneric( "scripts/melee/longsword.txt", true );
	PrecacheGeneric( "scripts/melee/m72law.txt", true );
	PrecacheGeneric( "scripts/melee/mace.txt", true );
	PrecacheGeneric( "scripts/melee/mace2.txt", true );
	PrecacheGeneric( "scripts/melee/mastersword.txt", true );
	PrecacheGeneric( "scripts/melee/mirrorshield.txt", true );
	PrecacheGeneric( "scripts/melee/mop.txt", true );
	PrecacheGeneric( "scripts/melee/mop2.txt", true );
	PrecacheGeneric( "scripts/melee/muffler.txt", true );
	PrecacheGeneric( "scripts/melee/nailbat.txt", true );
	PrecacheGeneric( "scripts/melee/pickaxe.txt", true );
	PrecacheGeneric( "scripts/melee/pipehammer.txt", true );
	PrecacheGeneric( "scripts/melee/pot.txt", true );
	PrecacheGeneric( "scripts/melee/riotshield.txt", true );
	PrecacheGeneric( "scripts/melee/rockaxe.txt", true );
	PrecacheGeneric( "scripts/melee/scup.txt", true );
	PrecacheGeneric( "scripts/melee/sh2wood.txt", true );
	PrecacheGeneric( "scripts/melee/shoe.txt", true );
	PrecacheGeneric( "scripts/melee/slasher.txt", true );
	PrecacheGeneric( "scripts/melee/spickaxe.txt", true );
	PrecacheGeneric( "scripts/melee/sshovel.txt", true );
	PrecacheGeneric( "scripts/melee/ssword.txt", true );
	PrecacheGeneric( "scripts/melee/syringe_gun.txt", true );
	PrecacheGeneric( "scripts/melee/thrower.txt", true );
	PrecacheGeneric( "scripts/melee/tireiron.txt", true );
	PrecacheGeneric( "scripts/melee/tonfa_riot.txt", true );
	PrecacheGeneric( "scripts/melee/trashbin.txt", true );
	PrecacheGeneric( "scripts/melee/vampiresword.txt", true );
	PrecacheGeneric( "scripts/melee/wand.txt", true );
	PrecacheGeneric( "scripts/melee/waterpipe.txt", true );
	PrecacheGeneric( "scripts/melee/waxe.txt", true );
	PrecacheGeneric( "scripts/melee/weapon_chalice.txt", true );
	PrecacheGeneric( "scripts/melee/weapon_morgenstern.txt", true );
	PrecacheGeneric( "scripts/melee/weapon_shadowhand.txt", true );
	PrecacheGeneric( "scripts/melee/weapon_sof.txt", true );
	PrecacheGeneric( "scripts/melee/woodbat.txt", true );
	PrecacheGeneric( "scripts/melee/wpickaxe.txt", true );
	PrecacheGeneric( "scripts/melee/wrench.txt", true );
	PrecacheGeneric( "scripts/melee/wshovel.txt", true );
	PrecacheGeneric( "scripts/melee/wsword.txt", true );
	PrecacheGeneric( "scripts/melee/wulinmiji.txt", true );
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( !GetConVarBool( g_hEnabled ) ) return Plugin_Continue;
	
	g_bSpawnedMelee = false;
	
	if( g_iRound == 2 && IsVersus() ) g_iRound = 1; else g_iRound = 2;
	
	GetMeleeClasses();
	
	CreateTimer( 1.0, Timer_SpawnMelee );
	
	return Plugin_Continue;
}

public Action:Timer_SpawnMelee( Handle:timer )
{
	new client = GetInGameClient();

	if( client != 0 && !g_bSpawnedMelee )
	{
		decl Float:SpawnPosition[3], Float:SpawnAngle[3];
		GetClientAbsOrigin( client, SpawnPosition );
		SpawnPosition[2] += 20; SpawnAngle[0] = 90.0;
		
		if( GetConVarBool( g_hWeaponRandom ) )
		{
			new i = 0;
			while( i < GetConVarInt( g_hWeaponRandomAmount ) )
			{
				new RandomMelee = GetRandomInt( 0, g_iMeleeClassCount-1 );
				if( IsVersus() && g_iRound == 2 ) RandomMelee = g_iMeleeRandomSpawn[i]; 
				SpawnMelee( g_sMeleeClass[RandomMelee], SpawnPosition, SpawnAngle );
				if( IsVersus() && g_iRound == 1 ) g_iMeleeRandomSpawn[i] = RandomMelee;
				i++;
			}
			g_bSpawnedMelee = true;
		}
		else
		{
			SpawnCustomList( SpawnPosition, SpawnAngle );
			g_bSpawnedMelee = true;
		}
	}
	else
	{
		if( !g_bSpawnedMelee ) CreateTimer( 1.0, Timer_SpawnMelee );
	}
}

stock SpawnCustomList( Float:Position[3], Float:Angle[3] )
{
	decl String:ScriptName[32];
	
	//Spawn Baseball bats
	if( GetConVarInt( g_hWeaponBaseballbat ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponBaseballbat ); i++ )
		{
			GetScriptName( "baseball_bat", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Cricket bats
	if( GetConVarInt( g_hWeaponCricketbat ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponCricketbat ); i++ )
		{
			GetScriptName( "cricket_bat", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Crowbars
	if( GetConVarInt( g_hWeaponCrowbar ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponCrowbar ); i++ )
		{
			GetScriptName( "crowbar", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Electric guitars
	if( GetConVarInt( g_hWeaponElectricguitar ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponElectricguitar ); i++ )
		{
			GetScriptName( "electric_guitar", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Fire axes
	if( GetConVarInt( g_hWeaponFireaxe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponFireaxe ); i++ )
		{
			GetScriptName( "fireaxe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Frying pans
	if( GetConVarInt( g_hWeaponFryingpan ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponFryingpan ); i++ )
		{
			GetScriptName( "frying_pan", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Golf clubs
	if( GetConVarInt( g_hWeaponGolfclub ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponGolfclub ); i++ )
		{
			GetScriptName( "golfclub", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Katanas
	if( GetConVarInt( g_hWeaponKatana ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponKatana ); i++ )
		{
			GetScriptName( "katana", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Machetes
	if( GetConVarInt( g_hWeaponMachete ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponMachete ); i++ )
		{
			GetScriptName( "machete", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Nightsticks
	if( GetConVarInt( g_hWeaponTonfa ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponTonfa ); i++ )
		{
			GetScriptName( "tonfa", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}

	//Spawn Large concrete sticks
	if( GetConVarInt( g_hWeapon2handedconcrete ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeapon2handedconcrete ); i++ )
		{
			GetScriptName( "2_handed_concrete", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Aether pickaxes
	if( GetConVarInt( g_hWeaponAetherpickaxe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponAetherpickaxe ); i++ )
		{
			GetScriptName( "aetherpickaxe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Aether swords
	if( GetConVarInt( g_hWeaponAethersword ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponAethersword ); i++ )
		{
			GetScriptName( "aethersword", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Arms
	if( GetConVarInt( g_hWeaponArm ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponArm ); i++ )
		{
			GetScriptName( "arm", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Brown broken bottles
	if( GetConVarInt( g_hWeaponBrokenbottle ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponBrokenbottle ); i++ )
		{
			GetScriptName( "b_brokenbottle", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Foam fingers
	if( GetConVarInt( g_hWeaponFoamfinger ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponFoamfinger ); i++ )
		{
			GetScriptName( "b_foamfinger", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Leg bones
	if( GetConVarInt( g_hWeaponLegbone ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponLegbone ); i++ )
		{
			GetScriptName( "b_legbone", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Bamboo sticks
	if( GetConVarInt( g_hWeaponBamboo ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponBamboo ); i++ )
		{
			GetScriptName( "bamboo", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Barnacle guns
	if( GetConVarInt( g_hWeaponBarnacle ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponBarnacle ); i++ )
		{
			GetScriptName( "barnacle", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Biggoron swords
	if( GetConVarInt( g_hWeaponBigoronsword ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponBigoronsword ); i++ )
		{
			GetScriptName( "bigoronsword", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Flails
	if( GetConVarInt( g_hWeaponBnc ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponBnc ); i++ )
		{
			GetScriptName( "bnc", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Green broken bottles
	if( GetConVarInt( g_hWeaponBottle ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponBottle ); i++ )
		{
			GetScriptName( "bottle", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Recurve bows
	if( GetConVarInt( g_hWeaponBow ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponBow ); i++ )
		{
			GetScriptName( "bow", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Pain trains
	if( GetConVarInt( g_hWeaponNail ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponNail ); i++ )
		{
			GetScriptName( "bt_nail", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Homewreckers
	if( GetConVarInt( g_hWeaponSledge ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponSledge ); i++ )
		{
			GetScriptName( "bt_sledge", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Skull torches
	if( GetConVarInt( g_hWeaponTorch ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponTorch ); i++ )
		{
			GetScriptName( "btorch", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Chains
	if( GetConVarInt( g_hWeaponChains ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponChains ); i++ )
		{
			GetScriptName( "chains", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Classroom chairs
	if( GetConVarInt( g_hWeaponChair ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponChair ); i++ )
		{
			GetScriptName( "chair", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Wooden chairs
	if( GetConVarInt( g_hWeaponChair2 ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponChair2 ); i++ )
		{
			GetScriptName( "chair2", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Combat knives
	if( GetConVarInt( g_hWeaponCombatknife ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponCombatknife ); i++ )
		{
			GetScriptName( "combat_knife", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Computer keyboards
	if( GetConVarInt( g_hWeaponComputerkeyboard ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponComputerkeyboard ); i++ )
		{
			GetScriptName( "computer_keyboard", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Medium concrete sticks
	if( GetConVarInt( g_hWeaponConcrete1 ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponConcrete1 ); i++ )
		{
			GetScriptName( "concrete1", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Small concrete sticks
	if( GetConVarInt( g_hWeaponConcrete2 ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponConcrete2 ); i++ )
		{
			GetScriptName( "concrete2", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Deployable ammo packs
	if( GetConVarInt( g_hWeaponCustomammopack ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponCustomammopack ); i++ )
		{
			GetScriptName( "custom_ammo_pack", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Battleaxes
	if( GetConVarInt( g_hWeaponDaxe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponDaxe ); i++ )
		{
			GetScriptName( "daxe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Deku sticks
	if( GetConVarInt( g_hWeaponDekustick ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponDekustick ); i++ )
		{
			GetScriptName( "dekustick", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Diamond hoes
	if( GetConVarInt( g_hWeaponDhoe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponDhoe ); i++ )
		{
			GetScriptName( "dhoe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Kink maps
	if( GetConVarInt( g_hWeaponDoc1 ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponDoc1 ); i++ )
		{
			GetScriptName( "doc1", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Diamond shovels
	if( GetConVarInt( g_hWeaponDshovel ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponDshovel ); i++ )
		{
			GetScriptName( "dshovel", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Diamond swords
	if( GetConVarInt( g_hWeaponDsword ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponDsword ); i++ )
		{
			GetScriptName( "dsword", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Dustpans and brushes
	if( GetConVarInt( g_hWeaponDustpan ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponDustpan ); i++ )
		{
			GetScriptName( "dustpan", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Black guitars
	if( GetConVarInt( g_hWeaponElectricguitar2 ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponElectricguitar2 ); i++ )
		{
			GetScriptName( "electric_guitar2", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Orange guitars
	if( GetConVarInt( g_hWeaponElectricguitar3 ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponElectricguitar3 ); i++ )
		{
			GetScriptName( "electric_guitar3", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Grey guitars
	if( GetConVarInt( g_hWeaponElectricguitar4 ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponElectricguitar4 ); i++ )
		{
			GetScriptName( "electric_guitar4", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Enchanted swords
	if( GetConVarInt( g_hWeaponEnchsword ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponEnchsword ); i++ )
		{
			GetScriptName( "enchsword", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Fishing rods
	if( GetConVarInt( g_hWeaponFishingrod ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponFishingrod ); i++ )
		{
			GetScriptName( "fishingrod", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Makeshift flamethrowers
	if( GetConVarInt( g_hWeaponFlamethrower ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponFlamethrower ); i++ )
		{
			GetScriptName( "flamethrower", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Feet
	if( GetConVarInt( g_hWeaponFoot ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponFoot ); i++ )
		{
			GetScriptName( "foot", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Fubars
	if( GetConVarInt( g_hWeaponFubar ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponFubar ); i++ )
		{
			GetScriptName( "fubar", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Golden axes
	if( GetConVarInt( g_hWeaponGaxe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponGaxe ); i++ )
		{
			GetScriptName( "gaxe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Golden hoes
	if( GetConVarInt( g_hWeaponGhoe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponGhoe ); i++ )
		{
			GetScriptName( "ghoe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Boxing gloves
	if( GetConVarInt( g_hWeaponGloves ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponGloves ); i++ )
		{
			GetScriptName( "gloves", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Garbage sets
	if( GetConVarInt( g_hWeaponGman ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponGman ); i++ )
		{
			GetScriptName( "gman", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Golden pickaxes
	if( GetConVarInt( g_hWeaponGpickaxe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponGpickaxe ); i++ )
		{
			GetScriptName( "gpickaxe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Golden shovels
	if( GetConVarInt( g_hWeaponGshovel ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponGshovel ); i++ )
		{
			GetScriptName( "gshovel", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Guandaos
	if( GetConVarInt( g_hWeaponGuandao ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponGuandao ); i++ )
		{
			GetScriptName( "guandao", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Black electric guitars
	if( GetConVarInt( g_hWeaponGuitar ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponGuitar ); i++ )
		{
			GetScriptName( "guitar", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Mega hammers
	if( GetConVarInt( g_hWeaponHammer ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponHammer ); i++ )
		{
			GetScriptName( "hammer", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Andurils
	if( GetConVarInt( g_hWeaponHelmsanduril ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponHelmsanduril ); i++ )
		{
			GetScriptName( "helms_anduril", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Hatchets
	if( GetConVarInt( g_hWeaponHelmshatchet ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponHelmshatchet ); i++ )
		{
			GetScriptName( "helms_hatchet", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Orcrists
	if( GetConVarInt( g_hWeaponHelmsorcrist ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponHelmsorcrist ); i++ )
		{
			GetScriptName( "helms_orcrist", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Stings
	if( GetConVarInt( g_hWeaponHelmssting ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponHelmssting ); i++ )
		{
			GetScriptName( "helms_sting", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Warrior sets
	if( GetConVarInt( g_hWeaponHelmsswordshield ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponHelmsswordshield ); i++ )
		{
			GetScriptName( "helms_sword_and_shield", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Hylian shields
	if( GetConVarInt( g_hWeaponHylianshield ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponHylianshield ); i++ )
		{
			GetScriptName( "hylianshield", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Iron axes
	if( GetConVarInt( g_hWeaponIaxe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponIaxe ); i++ )
		{
			GetScriptName( "iaxe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Iron hoes
	if( GetConVarInt( g_hWeaponIhoe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponIhoe ); i++ )
		{
			GetScriptName( "ihoe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Iron pickaxes
	if( GetConVarInt( g_hWeaponIpickaxe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponIpickaxe ); i++ )
		{
			GetScriptName( "ipickaxe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Iron swords
	if( GetConVarInt( g_hWeaponIsword ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponIsword ); i++ )
		{
			GetScriptName( "isword", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Skyrim katanas
	if( GetConVarInt( g_hWeaponKatana2 ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponKatana2 ); i++ )
		{
			GetScriptName( "katana2", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Kitchen knives
	if( GetConVarInt( g_hWeaponKitchenknife ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponKitchenknife ); i++ )
		{
			GetScriptName( "kitchen_knife", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Lamps
	if( GetConVarInt( g_hWeaponLamp ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponLamp ); i++ )
		{
			GetScriptName( "lamp", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Lego swords
	if( GetConVarInt( g_hWeaponLegosword ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponLegosword ); i++ )
		{
			GetScriptName( "legosword", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Lightsabers
	if( GetConVarInt( g_hWeaponLightsaber ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponLightsaber ); i++ )
		{
			GetScriptName( "lightsaber", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Palm daggers
	if( GetConVarInt( g_hWeaponLobo ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponLobo ); i++ )
		{
			GetScriptName( "lobo", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Swords and shields
	if( GetConVarInt( g_hWeaponLongsword ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponLongsword ); i++ )
		{
			GetScriptName( "longsword", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn M72 LAWs
	if( GetConVarInt( g_hWeaponM72law ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponM72law ); i++ )
		{
			GetScriptName( "m72law", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Maces
	if( GetConVarInt( g_hWeaponMace ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponMace ); i++ )
		{
			GetScriptName( "mace", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Improved Maces
	if( GetConVarInt( g_hWeaponMace2 ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponMace2 ); i++ )
		{
			GetScriptName( "mace2", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Master swords
	if( GetConVarInt( g_hWeaponMastersword ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponMastersword ); i++ )
		{
			GetScriptName( "mastersword", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Mirror shields
	if( GetConVarInt( g_hWeaponMirrorshield ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponMirrorshield ); i++ )
		{
			GetScriptName( "mirrorshield", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Light blue mops
	if( GetConVarInt( g_hWeaponMop ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponMop ); i++ )
		{
			GetScriptName( "mop", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Pink mops
	if( GetConVarInt( g_hWeaponMop2 ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponMop2 ); i++ )
		{
			GetScriptName( "mop2", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Mufflers
	if( GetConVarInt( g_hWeaponMuffler ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponMuffler ); i++ )
		{
			GetScriptName( "muffler", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Nail bats
	if( GetConVarInt( g_hWeaponNailbat ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponNailbat ); i++ )
		{
			GetScriptName( "nailbat", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Pickaxes
	if( GetConVarInt( g_hWeaponPickaxe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponPickaxe ); i++ )
		{
			GetScriptName( "pickaxe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Pipe hammers
	if( GetConVarInt( g_hWeaponPipehammer ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponPipehammer ); i++ )
		{
			GetScriptName( "pipehammer", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Sauce pots
	if( GetConVarInt( g_hWeaponPot ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponPot ); i++ )
		{
			GetScriptName( "pot", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Riotshields
	if( GetConVarInt( g_hWeaponRiotshield ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponRiotshield ); i++ )
		{
			GetScriptName( "riotshield", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Rockaxes
	if( GetConVarInt( g_hWeaponRockaxe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponRockaxe ); i++ )
		{
			GetScriptName( "rockaxe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Pink mugs
	if( GetConVarInt( g_hWeaponScup ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponScup ); i++ )
		{
			GetScriptName( "scup", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Nail sticks
	if( GetConVarInt( g_hWeaponSh2wood ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponSh2wood ); i++ )
		{
			GetScriptName( "sh2wood", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Silver hoes
	if( GetConVarInt( g_hWeaponShoe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponShoe ); i++ )
		{
			GetScriptName( "shoe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Slasher blades
	if( GetConVarInt( g_hWeaponSlasher ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponSlasher ); i++ )
		{
			GetScriptName( "slasher", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Silver pickaxes
	if( GetConVarInt( g_hWeaponSpickaxe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponSpickaxe ); i++ )
		{
			GetScriptName( "spickaxe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Silver shovels
	if( GetConVarInt( g_hWeaponSshovel ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponSshovel ); i++ )
		{
			GetScriptName( "sshovel", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Silver swords
	if( GetConVarInt( g_hWeaponSsword ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponSsword ); i++ )
		{
			GetScriptName( "ssword", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Syringe guns
	if( GetConVarInt( g_hWeaponSyringegun ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponSyringegun ); i++ )
		{
			GetScriptName( "syringe_gun", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Improved makeshift flamethrowers
	if( GetConVarInt( g_hWeaponThrower ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponThrower ); i++ )
		{
			GetScriptName( "thrower", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Tire irons
	if( GetConVarInt( g_hWeaponTireiron ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponTireiron ); i++ )
		{
			GetScriptName( "tireiron", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Nightsticks and riotshields
	if( GetConVarInt( g_hWeaponTonfariot ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponTonfariot ); i++ )
		{
			GetScriptName( "tonfa_riot", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Trash cans
	if( GetConVarInt( g_hWeaponTrashbin ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponTrashbin ); i++ )
		{
			GetScriptName( "trashbin", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Vampire swords
	if( GetConVarInt( g_hWeaponVampiresword ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponVampiresword ); i++ )
		{
			GetScriptName( "vampiresword", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Magic wands
	if( GetConVarInt( g_hWeaponWand ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponWand ); i++ )
		{
			GetScriptName( "wand", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Water pipes
	if( GetConVarInt( g_hWeaponWaterpipe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponWaterpipe ); i++ )
		{
			GetScriptName( "waterpipe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Wooden axes
	if( GetConVarInt( g_hWeaponWaxe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponWaxe ); i++ )
		{
			GetScriptName( "waxe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Chalices
	if( GetConVarInt( g_hWeaponWeaponchalice ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponWeaponchalice ); i++ )
		{
			GetScriptName( "weapon_chalice", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Flail maces
	if( GetConVarInt( g_hWeaponWeaponmorgenstern ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponWeaponmorgenstern ); i++ )
		{
			GetScriptName( "weapon_morgenstern", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Shadow claws
	if( GetConVarInt( g_hWeaponWeaponshadowhand ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponWeaponshadowhand ); i++ )
		{
			GetScriptName( "weapon_shadowhand", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Molten swords
	if( GetConVarInt( g_hWeaponWeaponsof ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponWeaponsof ); i++ )
		{
			GetScriptName( "weapon_sof", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Wooden bats
	if( GetConVarInt( g_hWeaponWoodbat ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponWoodbat ); i++ )
		{
			GetScriptName( "woodbat", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Wooden pickaxes
	if( GetConVarInt( g_hWeaponWpickaxe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponWpickaxe ); i++ )
		{
			GetScriptName( "wpickaxe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Wrenches
	if( GetConVarInt( g_hWeaponWrench ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponWrench ); i++ )
		{
			GetScriptName( "wrench", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Wooden shovels
	if( GetConVarInt( g_hWeaponWshovel ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponWshovel ); i++ )
		{
			GetScriptName( "wshovel", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Wooden swords
	if( GetConVarInt( g_hWeaponWsword ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponWsword ); i++ )
		{
			GetScriptName( "wsword", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
    
	//Spawn Wulinmijis
	if( GetConVarInt( g_hWeaponWulinmiji ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponWulinmiji ); i++ )
		{
			GetScriptName( "wulinmiji", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
}

stock SpawnMelee( const String:Class[32], Float:Position[3], Float:Angle[3] )
{
	decl Float:SpawnPosition[3], Float:SpawnAngle[3];
	SpawnPosition = Position;
	SpawnAngle = Angle;
	
	SpawnPosition[0] += ( -10 + GetRandomInt( 0, 20 ) );
	SpawnPosition[1] += ( -10 + GetRandomInt( 0, 20 ) );
	SpawnPosition[2] += GetRandomInt( 0, 10 );
	SpawnAngle[1] = GetRandomFloat( 0.0, 360.0 );

	new MeleeSpawn = CreateEntityByName( "weapon_melee" );
	DispatchKeyValue( MeleeSpawn, "melee_script_name", Class );
	DispatchSpawn( MeleeSpawn );
	TeleportEntity(MeleeSpawn, SpawnPosition, SpawnAngle, NULL_VECTOR );
}

stock GetMeleeClasses()
{
	new MeleeStringTable = FindStringTable( "MeleeWeapons" );
	g_iMeleeClassCount = GetStringTableNumStrings( MeleeStringTable );
	
	for( new i = 0; i < g_iMeleeClassCount; i++ )
	{
		ReadStringTable( MeleeStringTable, i, g_sMeleeClass[i], 32 );
	}	
}

stock GetScriptName( const String:Class[32], String:ScriptName[32] )
{
	for( new i = 0; i < g_iMeleeClassCount; i++ )
	{
		if( StrContains( g_sMeleeClass[i], Class, false ) == 0 )
		{
			Format( ScriptName, 32, "%s", g_sMeleeClass[i] );
			return;
		}
	}
	Format( ScriptName, 32, "%s", g_sMeleeClass[0] );	
}

stock GetInGameClient()
{
	for( new x = 1; x <= GetClientCount( true ); x++ )
	{
		if( IsClientInGame( x ) && GetClientTeam( x ) == 2 )
		{
			return x;
		}
	}
	return 0;
}

stock bool:IsVersus()
{
	new String:GameMode[32];
	GetConVarString( FindConVar( "mp_gamemode" ), GameMode, 32 );
	if( StrContains( GameMode, "versus", false ) != -1 ) return true;
	return false;
}