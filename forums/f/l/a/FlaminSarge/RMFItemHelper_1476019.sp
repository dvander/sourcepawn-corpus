/////////////////////////////////////////////////////////////////////
//
// TF2用関数群
//
/////////////////////////////////////////////////////////////////////
#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>

#define PL_NAME "[RMF] Item Helper"
#define PL_DESC			"Required natives for RMF Item stuff"
#define PL_VERSION		"1.0"

/////////////////////////////////////////////////////////////////////
//
// MOD情報
//
/////////////////////////////////////////////////////////////////////
public Plugin:myinfo = 
{
	name		= PL_NAME,
	author		= "FlaminSarge",
	description	= PL_DESC,
	version		= PL_VERSION,
	url			= "http://forums.alliedmods.net/"
}

/////////////////////////////////////////////////////////////////////
//
// 定数
//
/////////////////////////////////////////////////////////////////////
//#define TF2_ITEM_NUM 140       //アイテム数


// アイテムのタイプ
enum TFItemType
{
	TYPE_UNKOWN		= 0,
	TYPE_WEAPON		= 1,
	TYPE_WEAR		= 2
};

// アイテムのスロット
enum TFItemSlot
{
	SLOT_PRIMARY	= 0,
	SLOT_SECONDARY	= 1,
	SLOT_MELEE		= 2,
	SLOT_PDA_1		= 3,
	SLOT_PDA_2		= 4,
	SLOT_BUILDING	= 5,
	SLOT_HEAD		= 6,
	SLOT_MISC		= 7,
	SLOT_UNKOWN		= 9
};

// アイテムのクオリティ
enum TFItemQuality
{
	QUALITY_NORMAL		= 0,
	QUALITY_COMMON		= 1,
	QUALITY_RARE		= 2,
	QUALITY_UNIQUE		= 3,
	QUALITY_COMMUNITY		= 7,
	QUALITY_DEVELOPER		= 8,
	QUALITY_SELFMADE		= 9,
	QUALITY_CUSTOMIZED	= 10
};

// 武器アイテム
enum TFItems
{
	ITEM_WEAPON_BAT					= 0,
	ITEM_WEAPON_BOTTLE				= 1,
	ITEM_WEAPON_FIREAXE				= 2,
	ITEM_WEAPON_KUKRI				= 3,
	ITEM_WEAPON_KNIFE				= 4,
	ITEM_WEAPON_FISTS				= 5,
	ITEM_WEAPON_SHOVEL				= 6,
	ITEM_WEAPON_WRENCH				= 7,
	ITEM_WEAPON_BONESAW				= 8,
	ITEM_WEAPON_SHOTGUN_ENG			= 9,
	ITEM_WEAPON_SHOTGUN_SOLDIER		= 10,
	ITEM_WEAPON_SHOTGUN_HWG			= 11,
	ITEM_WEAPON_SHOTGUN_PYRO		= 12,
	ITEM_WEAPON_SCATTERGUN			= 13,
	ITEM_WEAPON_SNIPERRIFLE			= 14,
	ITEM_WEAPON_MINIGUN				= 15,
	ITEM_WEAPON_SMG					= 16,
	ITEM_WEAPON_SYRINGEGUN			= 17,
	ITEM_WEAPON_ROCKETLAUNCHER		= 18,
	ITEM_WEAPON_GRENADELAUNCHER		= 19,
	ITEM_WEAPON_STICKYBOMBLAUNCHER	= 20,
	ITEM_WEAPON_FLAMETHROWER		= 21,
	ITEM_WEAPON_PISTOL_ENG			= 22,
	ITEM_WEAPON_PISTOL_SCOUT		= 23,
	ITEM_WEAPON_REVOLVER			= 24,
	ITEM_WEAPON_PDA_BUILD			= 25,
	ITEM_WEAPON_PDA_DESTROY			= 26,
	ITEM_WEAPON_PDA_DISGUISE		= 27,
	ITEM_WEAPON_TOOLBOX				= 28,
	ITEM_WEAPON_MEDIGUN				= 29,
	ITEM_WEAPON_WATCH_INVIS			= 30,
	ITEM_WEAPON_FLAREGUN			= 31,
	ITEM_WEAPON_BONESAW_LV1			= 32,
	ITEM_WEAPON_SYRINGEGUN_LV1		= 33,
	ITEM_WEAPON_MEDIGUN_LV1			= 34,
	ITEM_WEAPON_KRITZKRIEG			= 35,
	ITEM_WEAPON_BLUTSAUGER			= 36,
	ITEM_WEAPON_UBERSAW				= 37,
	ITEM_WEAPON_AXTINGUISHER		= 38,
	ITEM_WEAPON_FLAREGUN_HALF		= 39,
	ITEM_WEAPON_BACKBURNER			= 40,
	ITEM_WEAPON_NATASCHA			= 41,
	ITEM_WEAPON_SANDVICH			= 42,
	ITEM_WEAPON_KGB					= 43,
	ITEM_WEAPON_SANDMAN				= 44,
	ITEM_WEAPON_FAN					= 45,
	ITEM_WEAPON_BONKDRINK			= 46,
	ITEM_WEAR_DEMO_AFRO				= 47,
	ITEM_WEAR_ENG_LIGHT				= 48,
	ITEM_WEAR_HEAVY_FOOTBALL		= 49,
	ITEM_WEAR_MEDIC_PICKELHAUBE		= 50,
	ITEM_WEAR_PYRO_BEANIE			= 51,
	ITEM_WEAR_SCOUT_BATTER			= 52,
	ITEM_WEAR_SNIPER_TROPHY			= 53,
	ITEM_WEAR_SOLDIER_STASH			= 54,
	ITEM_WEAR_SPY_FEDORA			= 55,
	ITEM_WEAPON_HUNTSMAN			= 56,
	ITEM_WEAR_RAZORBACK				= 57,
	ITEM_WEAPON_JARATE				= 58,
	ITEM_WEAPON_WATCH_DEADRINGER	= 59,
	ITEM_WEAPON_WATCH_CAD			= 60,
	ITEM_WEAPON_AMBASSADOR			= 61,
	ITEM_WEAR_ENG_TENGALLON			= 94,
	ITEM_WEAR_ENG_CAP				= 95,
	ITEM_WEAR_HEAVY_USHANKA			= 96,
	ITEM_WEAR_HEAVY_STOCKING		= 97,
	ITEM_WEAR_SOLDIER_POT			= 98,
	ITEM_WEAR_SOLDIER_TYRANT		= 99,
	ITEM_WEAR_DEMO_GLENGARRY		= 100,
	ITEM_WEAR_MEDIC_TYROLEAN		= 101,
	ITEM_WEAR_PYRO_CHIKEN			= 102,
	ITEM_WEAR_SPY_CAMERA			= 103,
	ITEM_WEAR_MEDIC_MIRROR			= 104,
	ITEM_WEAR_PYRO_FIREMAN			= 105,
	ITEM_WEAR_SCOUT_BONK			= 106,
	ITEM_WEAR_SCOUT_BAKER			= 107,
	ITEM_WEAR_SPY_BILLYCOCK			= 108,
	ITEM_WEAR_SNIPER_PANAMA			= 109,
	ITEM_WEAR_SNIPER_BAND			= 110,
	ITEM_WEAR_SCOUT_HATLESS			= 111,
	ITEM_WEAR_HALLOWEEN_HAT			= 115,
	ITEM_WEAR_DOMINATION_HAT		= 116,
	ITEM_WEAR_SNIPER_HATLESS		= 117,
	ITEM_WEAR_ENG_HATLESS			= 118,
	ITEM_WEAR_DEMO_TOPHAT			= 120,
	ITEM_WEAR_SOLDIER_MEDAL			= 121,
	ITEM_CHEAT_DETECTED_MINOR		= 122,
	ITEM_CHEAT_DETECTED_MAJOR		= 123,
	ITEM_CHEAT_DETECTED_HONESTY		= 124,
	ITEM_WARE_HONEST_HALO			= 125,
	ITEM_WARE_BILL_HAT				= 126,
	ITEM_WEAPON_DIRECTHIT			= 127,
	ITEM_WEAPON_PICKAXE				= 128,
	ITEM_WEAPON_BATTLE_BANNER		= 129,
	ITEM_WEAPON_SCOTTISH_RESISTANCE	= 130,
	ITEM_WEAPON_CHARGIN_TARGE		= 131,
	ITEM_WEAPON_EYELANDER			= 132,
	ITEM_WEAPON_GUNBOATS			= 133,
	ITEM_WEAR_CONTEST_FIRST_PLACE	= 134,
	ITEM_WEAR_TOWERING_PILLAR		= 135,
	ITEM_WEAR_CONTEST_SECOND_PLACE	= 136,
	ITEM_WEAR_NOBLE_AMASSMENT		= 137,
	ITEM_WEAR_CONTEST_THIRD_PLACE	= 138,
	ITEM_WEAR_MODEST_PILE			= 139,
	ITEM_WEAPON_SYDNEYSLEEPER		= 230
};

/////////////////////////////////////////////////////////////////////
//
// グローバル変数
//
/////////////////////////////////////////////////////////////////////
new Handle:g_GameConf			= INVALID_HANDLE;		// ゲームコンフィグ
//new Handle:g_hGiveNamedItem	= INVALID_HANDLE;		// 指定アイテム取得関数
//new Handle:g_hWeaponEquip		= INVALID_HANDLE;		// 武器装備関数
new Handle:g_hEquipWearable		= INVALID_HANDLE;		// ウェア装備
new Handle:g_hRemoveWearable	= INVALID_HANDLE;		// ウェア削除
new Handle:g_hGetMaxHealth		= INVALID_HANDLE;


// アイテムデータ
new Handle:g_ItemData = INVALID_HANDLE;
public OnPluginStart()
{
	CreateConVar("sm_rmf_tf_itemhelper", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	InitGameConf();
}
public OnPluginEnd()
{
	FinalItemData();
}
/////////////////////////////////////////////////////////////////////
//
// ゲームコンフィグ初期化
//
/////////////////////////////////////////////////////////////////////
stock InitGameConf()
{
	// ゲームコンフィグ読み込み
	g_GameConf = LoadGameConfigFile("rmf.games");

	// 指定アイテム取得関数
//	StartPrepSDKCall(SDKCall_Player);
//	PrepSDKCall_SetFromConf(g_GameConf, SDKConf_Virtual, "GiveNamedItem");
//	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
//	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
//	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
//	g_hGiveNamedItem = EndPrepSDKCall();

	// 武器装備関数
/*	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_GameConf, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWeaponEquip = EndPrepSDKCall();*/

	// ウェア装備関数
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_GameConf, SDKConf_Virtual, "EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hEquipWearable = EndPrepSDKCall();

	// ウェア削除関数
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_GameConf, SDKConf_Virtual, "RemoveWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hRemoveWearable = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_GameConf, SDKConf_Virtual, "CTFPlayer_GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hGetMaxHealth = EndPrepSDKCall();

	// アイテムデータ初期化
	InitItemData();
}
public OnMapStart() InitItemData();

/////////////////////////////////////////////////////////////////////
//
// アイテムデータ初期化
//
/////////////////////////////////////////////////////////////////////
stock InitItemData()
{
	// とりあえずTrie作成
		// なんか入っていたら一旦削除
	if( g_ItemData != INVALID_HANDLE )
	{
		ClearTrie(g_ItemData);
	}
	else
	{
		// まだ作成されていなければ作成
		g_ItemData = CreateTrie();
	}
	
	
/*	// アイテムインデックス
	SetTrieValue( g_ItemData[0],	"ItemDefinitionIndex",		0	 );
	SetTrieValue( g_ItemData[1],	"ItemDefinitionIndex",		1	 );
	SetTrieValue( g_ItemData[2],	"ItemDefinitionIndex",		2	 );
	SetTrieValue( g_ItemData[3],	"ItemDefinitionIndex",		3	 );
	SetTrieValue( g_ItemData[4],	"ItemDefinitionIndex",		4	 );
	SetTrieValue( g_ItemData[5],	"ItemDefinitionIndex",		5	 );
	SetTrieValue( g_ItemData[6],	"ItemDefinitionIndex",		6	 );
	SetTrieValue( g_ItemData[7],	"ItemDefinitionIndex",		7	 );
	SetTrieValue( g_ItemData[8],	"ItemDefinitionIndex",		8	 );
	SetTrieValue( g_ItemData[9],	"ItemDefinitionIndex",		9	 );
	SetTrieValue( g_ItemData[10],	"ItemDefinitionIndex",		10	 );
	SetTrieValue( g_ItemData[11],	"ItemDefinitionIndex",		11	 );
	SetTrieValue( g_ItemData[12],	"ItemDefinitionIndex",		12	 );
	SetTrieValue( g_ItemData[13],	"ItemDefinitionIndex",		13	 );
	SetTrieValue( g_ItemData[14],	"ItemDefinitionIndex",		14	 );
	SetTrieValue( g_ItemData[15],	"ItemDefinitionIndex",		15	 );
	SetTrieValue( g_ItemData[16],	"ItemDefinitionIndex",		16	 );
	SetTrieValue( g_ItemData[17],	"ItemDefinitionIndex",		17	 );
	SetTrieValue( g_ItemData[18],	"ItemDefinitionIndex",		18	 );
	SetTrieValue( g_ItemData[19],	"ItemDefinitionIndex",		19	 );
	SetTrieValue( g_ItemData[20],	"ItemDefinitionIndex",		20	 );
	SetTrieValue( g_ItemData[21],	"ItemDefinitionIndex",		21	 );
	SetTrieValue( g_ItemData[22],	"ItemDefinitionIndex",		22	 );
	SetTrieValue( g_ItemData[23],	"ItemDefinitionIndex",		23	 );
	SetTrieValue( g_ItemData[24],	"ItemDefinitionIndex",		24	 );
	SetTrieValue( g_ItemData[25],	"ItemDefinitionIndex",		25	 );
	SetTrieValue( g_ItemData[26],	"ItemDefinitionIndex",		26	 );
	SetTrieValue( g_ItemData[27],	"ItemDefinitionIndex",		27	 );
	SetTrieValue( g_ItemData[28],	"ItemDefinitionIndex",		28	 );
	SetTrieValue( g_ItemData[29],	"ItemDefinitionIndex",		29	 );
	SetTrieValue( g_ItemData[30],	"ItemDefinitionIndex",		30	 );
	SetTrieValue( g_ItemData[31],	"ItemDefinitionIndex",		31	 );
	SetTrieValue( g_ItemData[32],	"ItemDefinitionIndex",		32	 );
	SetTrieValue( g_ItemData[33],	"ItemDefinitionIndex",		33	 );
	SetTrieValue( g_ItemData[34],	"ItemDefinitionIndex",		34	 );
	SetTrieValue( g_ItemData[35],	"ItemDefinitionIndex",		35	 );
	SetTrieValue( g_ItemData[36],	"ItemDefinitionIndex",		36	 );
	SetTrieValue( g_ItemData[37],	"ItemDefinitionIndex",		37	 );
	SetTrieValue( g_ItemData[38],	"ItemDefinitionIndex",		38	 );
	SetTrieValue( g_ItemData[39],	"ItemDefinitionIndex",		39	 );
	SetTrieValue( g_ItemData[40],	"ItemDefinitionIndex",		40	 );
	SetTrieValue( g_ItemData[41],	"ItemDefinitionIndex",		41	 );
	SetTrieValue( g_ItemData[42],	"ItemDefinitionIndex",		42	 );
	SetTrieValue( g_ItemData[43],	"ItemDefinitionIndex",		43	 );
	SetTrieValue( g_ItemData[44],	"ItemDefinitionIndex",		44	 );
	SetTrieValue( g_ItemData[45],	"ItemDefinitionIndex",		45	 );
	SetTrieValue( g_ItemData[46],	"ItemDefinitionIndex",		46	 );
	SetTrieValue( g_ItemData[47],	"ItemDefinitionIndex",		47	 );
	SetTrieValue( g_ItemData[48],	"ItemDefinitionIndex",		48	 );
	SetTrieValue( g_ItemData[49],	"ItemDefinitionIndex",		49	 );
	SetTrieValue( g_ItemData[50],	"ItemDefinitionIndex",		50	 );
	SetTrieValue( g_ItemData[51],	"ItemDefinitionIndex",		51	 );
	SetTrieValue( g_ItemData[52],	"ItemDefinitionIndex",		52	 );
	SetTrieValue( g_ItemData[53],	"ItemDefinitionIndex",		53	 );
	SetTrieValue( g_ItemData[54],	"ItemDefinitionIndex",		54	 );
	SetTrieValue( g_ItemData[55],	"ItemDefinitionIndex",		55	 );
	SetTrieValue( g_ItemData[56],	"ItemDefinitionIndex",		56	 );
	SetTrieValue( g_ItemData[57],	"ItemDefinitionIndex",		57	 );
	SetTrieValue( g_ItemData[58],	"ItemDefinitionIndex",		58	 );
	SetTrieValue( g_ItemData[59],	"ItemDefinitionIndex",		59	 );
	SetTrieValue( g_ItemData[60],	"ItemDefinitionIndex",		60	 );
	SetTrieValue( g_ItemData[61],	"ItemDefinitionIndex",		61	 );
	SetTrieValue( g_ItemData[94],	"ItemDefinitionIndex",		94	 );
	SetTrieValue( g_ItemData[95],	"ItemDefinitionIndex",		95	 );
	SetTrieValue( g_ItemData[96],	"ItemDefinitionIndex",		96	 );
	SetTrieValue( g_ItemData[97],	"ItemDefinitionIndex",		97	 );
	SetTrieValue( g_ItemData[98],	"ItemDefinitionIndex",		98	 );
	SetTrieValue( g_ItemData[99],	"ItemDefinitionIndex",		99	 );
	SetTrieValue( g_ItemData[100],	"ItemDefinitionIndex",		100	 );
	SetTrieValue( g_ItemData[101],	"ItemDefinitionIndex",		101	 );
	SetTrieValue( g_ItemData[102],	"ItemDefinitionIndex",		102	 );
	SetTrieValue( g_ItemData[103],	"ItemDefinitionIndex",		103	 );
	SetTrieValue( g_ItemData[104],	"ItemDefinitionIndex",		104	 );
	SetTrieValue( g_ItemData[105],	"ItemDefinitionIndex",		105	 );
	SetTrieValue( g_ItemData[106],	"ItemDefinitionIndex",		106	 );
	SetTrieValue( g_ItemData[107],	"ItemDefinitionIndex",		107	 );
	SetTrieValue( g_ItemData[108],	"ItemDefinitionIndex",		108	 );
	SetTrieValue( g_ItemData[109],	"ItemDefinitionIndex",		109	 );
	SetTrieValue( g_ItemData[110],	"ItemDefinitionIndex",		110	 );
	SetTrieValue( g_ItemData[111],	"ItemDefinitionIndex",		111	 );
	SetTrieValue( g_ItemData[115],	"ItemDefinitionIndex",		115	 );
	SetTrieValue( g_ItemData[116],	"ItemDefinitionIndex",		116	 );
	SetTrieValue( g_ItemData[117],	"ItemDefinitionIndex",		117	 );
	SetTrieValue( g_ItemData[118],	"ItemDefinitionIndex",		118	 );
	SetTrieValue( g_ItemData[120],	"ItemDefinitionIndex",		120	 );
	SetTrieValue( g_ItemData[121],	"ItemDefinitionIndex",		121	 );
	SetTrieValue( g_ItemData[122],	"ItemDefinitionIndex",		122	 );
	SetTrieValue( g_ItemData[123],	"ItemDefinitionIndex",		123	 );
	SetTrieValue( g_ItemData[124],	"ItemDefinitionIndex",		124	 );
	SetTrieValue( g_ItemData[125],	"ItemDefinitionIndex",		125	 );
	SetTrieValue( g_ItemData[126],	"ItemDefinitionIndex",		126	 );
	SetTrieValue( g_ItemData[127],	"ItemDefinitionIndex",		127	 );
	SetTrieValue( g_ItemData[128],	"ItemDefinitionIndex",		128	 );
	SetTrieValue( g_ItemData[129],	"ItemDefinitionIndex",		129	 );
	SetTrieValue( g_ItemData[130],	"ItemDefinitionIndex",		130	 );
	SetTrieValue( g_ItemData[131],	"ItemDefinitionIndex",		131	 );
	SetTrieValue( g_ItemData[132],	"ItemDefinitionIndex",		132	 );
	SetTrieValue( g_ItemData[133],	"ItemDefinitionIndex",		133	 );
	SetTrieValue( g_ItemData[134],	"ItemDefinitionIndex",		134	 );
	SetTrieValue( g_ItemData[135],	"ItemDefinitionIndex",		135	 );
	SetTrieValue( g_ItemData[136],	"ItemDefinitionIndex",		136	 );
	SetTrieValue( g_ItemData[137],	"ItemDefinitionIndex",		137	 );
	SetTrieValue( g_ItemData[138],	"ItemDefinitionIndex",		138	 );
	SetTrieValue( g_ItemData[139],	"ItemDefinitionIndex",		139	 );*/
	
	// アイテムスロット
	SetTrieValue( g_ItemData,	"0_ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData,	"1_ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData,	"2_ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData,	"3_ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData,	"4_ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData,	"5_ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData,	"6_ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData,	"7_ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData,	"8_ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData,	"9_ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData,	"10_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"11_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"12_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"13_ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData,	"14_ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData,	"15_ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData,	"16_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"17_ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData,	"18_ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData,	"19_ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData,	"20_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"21_ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData,	"22_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"23_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"24_ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData,	"25_ItemSlot",		_:SLOT_PDA_1		);
	SetTrieValue( g_ItemData,	"26_ItemSlot",		_:SLOT_PDA_2		);
	SetTrieValue( g_ItemData,	"27_ItemSlot",		_:SLOT_PDA_1		);
	SetTrieValue( g_ItemData,	"28_ItemSlot",		_:SLOT_BUILDING		);
	SetTrieValue( g_ItemData,	"29_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"30_ItemSlot",		_:SLOT_PDA_2		);
	SetTrieValue( g_ItemData,	"31_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"32_ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData,	"33_ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData,	"34_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"35_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"36_ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData,	"37_ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData,	"38_ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData,	"39_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"40_ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData,	"41_ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData,	"42_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"43_ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData,	"44_ItemSlot",		_:SLOT_MELEE		);
	SetTrieValue( g_ItemData,	"45_ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData,	"46_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"47_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"48_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"49_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"50_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"51_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"52_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"53_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"54_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"55_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"56_ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData,	"57_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"58_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"59_ItemSlot",		_:SLOT_PDA_2		);
	SetTrieValue( g_ItemData,	"60_ItemSlot",		_:SLOT_PDA_2		);
	SetTrieValue( g_ItemData,	"61_ItemSlot",		_:SLOT_PRIMARY		);
	SetTrieValue( g_ItemData,	"94_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"95_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"96_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"97_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"98_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"99_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"100_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"101_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"102_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"103_ItemSlot",		_:SLOT_MISC			);
	SetTrieValue( g_ItemData,	"104_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"105_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"106_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"107_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"108_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"109_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"110_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"111_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"115_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"116_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"117_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"118_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"120_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"121_ItemSlot",		_:SLOT_MISC			);
	SetTrieValue( g_ItemData,	"122_ItemSlot",		_:SLOT_MISC			);
	SetTrieValue( g_ItemData,	"123_ItemSlot",		_:SLOT_MISC			);
	SetTrieValue( g_ItemData,	"124_ItemSlot",		_:SLOT_MISC			);
	SetTrieValue( g_ItemData,	"125_ItemSlot",		_:SLOT_HEAD			);	
	SetTrieValue( g_ItemData,	"126_ItemSlot",		_:SLOT_HEAD			);	
	SetTrieValue( g_ItemData,	"127_ItemSlot",		_:SLOT_PRIMARY		);	
	SetTrieValue( g_ItemData,	"128_ItemSlot",		_:SLOT_MELEE		);	
	SetTrieValue( g_ItemData,	"129_ItemSlot",		_:SLOT_SECONDARY	);
	SetTrieValue( g_ItemData,	"130_ItemSlot",		_:SLOT_PRIMARY		);	
	SetTrieValue( g_ItemData,	"131_ItemSlot",		_:SLOT_PRIMARY		);	
	SetTrieValue( g_ItemData,	"132_ItemSlot",		_:SLOT_MELEE		);	
	SetTrieValue( g_ItemData,	"133_ItemSlot",		_:SLOT_SECONDARY	);	
	SetTrieValue( g_ItemData,	"134_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"135_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"136_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"137_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"138_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"139_ItemSlot",		_:SLOT_HEAD			);
	SetTrieValue( g_ItemData,	"230_ItemSlot",		_:SLOT_PRIMARY		);
	
	// アイテムタイプ
	SetTrieValue( g_ItemData,	"0_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"1_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"2_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"3_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"4_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"5_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"6_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"7_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"8_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"9_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"10_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"11_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"12_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"13_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"14_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"15_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"16_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"17_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"18_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"19_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"20_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"21_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"22_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"23_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"24_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"25_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"26_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"27_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"28_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"29_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"30_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"31_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"32_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"33_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"34_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"35_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"36_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"37_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"38_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"39_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"40_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"41_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"42_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"43_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"44_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"45_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"46_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"47_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"48_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"49_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"50_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"51_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"52_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"53_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"54_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"55_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"56_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"57_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"58_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"59_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"60_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"61_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"94_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"95_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"96_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"97_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"98_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"99_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"100_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"101_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"102_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"103_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"104_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"105_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"106_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"107_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"108_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"109_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"110_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"111_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"115_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"116_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"117_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"118_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"120_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"121_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"122_ItemType",		_:TYPE_UNKOWN	);
	SetTrieValue( g_ItemData,	"123_ItemType",		_:TYPE_UNKOWN	);
	SetTrieValue( g_ItemData,	"124_ItemType",		_:TYPE_UNKOWN	);
	SetTrieValue( g_ItemData,	"125_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"126_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"127_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"128_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"129_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"130_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"131_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"132_ItemType",		_:TYPE_WEAPON	);
	SetTrieValue( g_ItemData,	"133_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"134_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"135_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"136_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"137_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"138_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"139_ItemType",		_:TYPE_WEAR		);
	SetTrieValue( g_ItemData,	"230_ItemType",		_:TYPE_WEAPON	);
	
	// アイテム名
	SetTrieString( g_ItemData,	"0_ItemName",		"#TF_Weapon_Bat"								);
	SetTrieString( g_ItemData,	"1_ItemName",		"#TF_Weapon_Bottle"								);
	SetTrieString( g_ItemData,	"2_ItemName",		"#TF_Weapon_FireAxe"							);
	SetTrieString( g_ItemData,	"3_ItemName",		"#TF_Weapon_Club"								);
	SetTrieString( g_ItemData,	"4_ItemName",		"#TF_Weapon_Knife"								);
	SetTrieString( g_ItemData,	"5_ItemName",		"#TF_Weapon_Fists"								);
	SetTrieString( g_ItemData,	"6_ItemName",		"#TF_Weapon_Shovel"								);
	SetTrieString( g_ItemData,	"7_ItemName",		"#TF_Weapon_Wrench"								);
	SetTrieString( g_ItemData,	"8_ItemName",		"#TF_Weapon_Bonesaw"							);
	SetTrieString( g_ItemData,	"9_ItemName",		"#TF_Weapon_Shotgun"							);
	SetTrieString( g_ItemData,	"10_ItemName",		"#TF_Weapon_Shotgun"							);
	SetTrieString( g_ItemData,	"11_ItemName",		"#TF_Weapon_Shotgun"							);
	SetTrieString( g_ItemData,	"12_ItemName",		"#TF_Weapon_Shotgun"							);
	SetTrieString( g_ItemData,	"13_ItemName",		"#TF_Weapon_Scattergun"							);
	SetTrieString( g_ItemData,	"14_ItemName",		"#TF_Weapon_SniperRifle"						);
	SetTrieString( g_ItemData,	"15_ItemName",		"#TF_Weapon_Minigun"							);
	SetTrieString( g_ItemData,	"16_ItemName",		"#TF_Weapon_SMG"								);
	SetTrieString( g_ItemData,	"17_ItemName",		"#TF_Weapon_SyringeGun"							);
	SetTrieString( g_ItemData,	"18_ItemName",		"#TF_Weapon_RocketLauncher"						);
	SetTrieString( g_ItemData,	"19_ItemName",		"#TF_Weapon_GrenadeLauncher"					);
	SetTrieString( g_ItemData,	"20_ItemName",		"#TF_Weapon_PipebombLauncher"					);
	SetTrieString( g_ItemData,	"21_ItemName",		"#TF_Weapon_FlameThrower"						);
	SetTrieString( g_ItemData,	"22_ItemName",		"#TF_Weapon_Pistol"								);
	SetTrieString( g_ItemData,	"23_ItemName",		"#TF_Weapon_Pistol"								);
	SetTrieString( g_ItemData,	"24_ItemName",		"#TF_Weapon_Revolver"							);
	SetTrieString( g_ItemData,	"25_ItemName",		"#TF_Weapon_PDA_Engineer"						);
	SetTrieString( g_ItemData,	"26_ItemName",		"#TF_Weapon_PDA_Engineer"						);
	SetTrieString( g_ItemData,	"27_ItemName",		"#TF_Weapon_PDA_Engineer"						);
	SetTrieString( g_ItemData,	"28_ItemName",		"#TF_Weapon_PDA_Engineer"						);
	SetTrieString( g_ItemData,	"29_ItemName",		"#TF_Weapon_Medigun"							);
	SetTrieString( g_ItemData,	"30_ItemName",		"#TF_Weapon_Watch"								);
	SetTrieString( g_ItemData,	"31_ItemName",		"#TF_Weapon_Flaregun"							);
	SetTrieString( g_ItemData,	"32_ItemName",		"#TF_Weapon_Bonesaw"							);
	SetTrieString( g_ItemData,	"33_ItemName",		"#TF_Weapon_SyringeGun"							);
	SetTrieString( g_ItemData,	"34_ItemName",		"#TF_Weapon_Medigun"							);
	SetTrieString( g_ItemData,	"35_ItemName",		"#TF_Unique_Achievement_Medigun1"				);
	SetTrieString( g_ItemData,	"36_ItemName",		"#TF_Unique_Achievement_Syringegun1"			);
	SetTrieString( g_ItemData,	"37_ItemName",		"#TF_Unique_Achievement_Bonesaw1"				);
	SetTrieString( g_ItemData,	"38_ItemName",		"#TF_Unique_Achievement_FireAxe1"				);
	SetTrieString( g_ItemData,	"39_ItemName",		"#TF_Unique_Achievement_Flaregun"				);
	SetTrieString( g_ItemData,	"40_ItemName",		"#TF_Unique_Achievement_Flamethrower"			);
	SetTrieString( g_ItemData,	"41_ItemName",		"#TF_Unique_Achievement_Minigun"				);
	SetTrieString( g_ItemData,	"42_ItemName",		"#TF_Unique_Achievement_LunchBox"				);
	SetTrieString( g_ItemData,	"43_ItemName",		"#TF_Unique_Achievement_Fists"					);
	SetTrieString( g_ItemData,	"44_ItemName",		"#TF_Unique_Achievement_Bat"					);
	SetTrieString( g_ItemData,	"45_ItemName",		"#TF_Unique_Achievement_Scattergun_Double"		);
	SetTrieString( g_ItemData,	"46_ItemName",		"#TF_Unique_Achievement_EnergyDrink"			);
	SetTrieString( g_ItemData,	"47_ItemName",		"#TF_Demo_Hat_1"								);
	SetTrieString( g_ItemData,	"48_ItemName",		"#TF_Engineer_Hat_1"							);
	SetTrieString( g_ItemData,	"49_ItemName",		"#TF_Heavy_Hat_1"								);
	SetTrieString( g_ItemData,	"50_ItemName",		"#TF_Medic_Hat_1"								);
	SetTrieString( g_ItemData,	"51_ItemName",		"#TF_Pyro_Hat_1"								);
	SetTrieString( g_ItemData,	"52_ItemName",		"#TF_Scout_Hat_1"								);
	SetTrieString( g_ItemData,	"53_ItemName",		"#TF_Sniper_Hat_1"								);
	SetTrieString( g_ItemData,	"54_ItemName",		"#TF_Soldier_Hat_1"								);
	SetTrieString( g_ItemData,	"55_ItemName",		"#TF_Spy_Hat_1"									);
	SetTrieString( g_ItemData,	"56_ItemName",		"#TF_Unique_Achievement_CompoundBow"			);
	SetTrieString( g_ItemData,	"57_ItemName",		"#TF_Unique_Backstab_Shield"					);
	SetTrieString( g_ItemData,	"58_ItemName",		"#TF_Unique_Achievement_Jar"					);
	SetTrieString( g_ItemData,	"59_ItemName",		"#TF_Unique_Achievement_FeignWatch"				);
	SetTrieString( g_ItemData,	"60_ItemName",		"#TF_Unique_Achievement_CloakWatch"				);
	SetTrieString( g_ItemData,	"61_ItemName",		"#TF_Unique_Achievement_Revolver"				);
	SetTrieString( g_ItemData,	"94_ItemName",		"#TF_Engineer_Cowboy_Hat"						);
	SetTrieString( g_ItemData,	"95_ItemName",		"#TF_Engineer_Train_Hat"						);
	SetTrieString( g_ItemData,	"96_ItemName",		"#TF_Heavy_Ushanka_Hat"							);
	SetTrieString( g_ItemData,	"97_ItemName",		"#TF_Heavy_Stocking_cap"						);
	SetTrieString( g_ItemData,	"98_ItemName",		"#TF_Soldier_Pot_Hat"							);
	SetTrieString( g_ItemData,	"99_ItemName",		"#TF_Soldier_Viking_Hat"						);
	SetTrieString( g_ItemData,	"100_ItemName",		"#TF_Demo_Scott_Hat"							);
	SetTrieString( g_ItemData,	"101_ItemName",		"#TF_Medic_Tyrolean_Hat"						);
	SetTrieString( g_ItemData,	"102_ItemName",		"#TF_Pyro_Chicken_Hat"							);
	SetTrieString( g_ItemData,	"103_ItemName",		"#TF_Spy_Camera_Beard"							);
	SetTrieString( g_ItemData,	"104_ItemName",		"#TF_Medic_Mirror_Hat"							);
	SetTrieString( g_ItemData,	"105_ItemName",		"#TF_Pyro_Fireman_Helmet"						);
	SetTrieString( g_ItemData,	"106_ItemName",		"#TF_Scout_Bonk_Helmet"							);
	SetTrieString( g_ItemData,	"107_ItemName",		"#TF_Scout_Newsboy_Cap"							);
	SetTrieString( g_ItemData,	"108_ItemName",		"#TF_Spy_Derby_Hat"								);
	SetTrieString( g_ItemData,	"109_ItemName",		"#TF_Sniper_Straw_Hat"							);
	SetTrieString( g_ItemData,	"110_ItemName",		"#TF_Sniper_Jarate_Headband"					);
	SetTrieString( g_ItemData,	"111_ItemName",		"#TF_Hatless_Scout"								);
	SetTrieString( g_ItemData,	"115_ItemName",		"#TF_Halloween_Hat"								);
	SetTrieString( g_ItemData,	"116_ItemName",		"#TF_Wearable_Hat"								);
	SetTrieString( g_ItemData,	"117_ItemName",		"#TF_Hatless_Sniper"							);
	SetTrieString( g_ItemData,	"118_ItemName",		"#TF_Hatless_Engineer"							);
	SetTrieString( g_ItemData,	"120_ItemName",		"#TF_Demo_Top_Hat"								);
	SetTrieString( g_ItemData,	"121_ItemName",		"#TF_Soldier_Medal_Web_Sleuth"					);
	SetTrieString( g_ItemData,	"122_ItemName",		"#TF_CheatDetectedMinor"						);
	SetTrieString( g_ItemData,	"123_ItemName",		"#TF_CheatDetectedMajor"						);
	SetTrieString( g_ItemData,	"124_ItemName",		"#TF_HonestyReward"								);
	SetTrieString( g_ItemData,	"125_ItemName",		"#TF_Wearable_HonestyHalo"						);
	SetTrieString( g_ItemData,	"126_ItemName",		"#TF_Wearable_L4DHat"							);
	SetTrieString( g_ItemData,	"127_ItemName",		"#TF_Unique_Achievement_RocketLauncher"			);
	SetTrieString( g_ItemData,	"128_ItemName",		"#TF_Unique_Achievement_Pickaxe"				);
	SetTrieString( g_ItemData,	"129_ItemName",		"#TF_Unique_Achievement_SoldierBuff"			);
	SetTrieString( g_ItemData,	"130_ItemName",		"#TF_Unique_Achievement_StickyLauncher"			);
	SetTrieString( g_ItemData,	"131_ItemName",		"#TF_Unique_Achievement_Shield"					);
	SetTrieString( g_ItemData,	"132_ItemName",		"#TF_Unique_Achievement_Sword"					);
	SetTrieString( g_ItemData,	"133_ItemName",		"#TF_Unique_Blast_Boots"						);
	SetTrieString( g_ItemData,	"134_ItemName",		"#TF_PropagandaContest_FirstPlace"				);
	SetTrieString( g_ItemData,	"135_ItemName",		"#TF_ToweringPillar_Hat"						);
	SetTrieString( g_ItemData,	"136_ItemName",		"#TF_PropagandaContest_SecondPlace"				);
	SetTrieString( g_ItemData,	"137_ItemName",		"#TF_NobleAmassment_Hat"						);
	SetTrieString( g_ItemData,	"138_ItemName",		"#TF_PropagandaContest_ThirdPlace"				);
	SetTrieString( g_ItemData,	"139_ItemName",		"#TF_ModestPile_Hat"							);
	SetTrieString( g_ItemData,	"230_ItemName",		"#TF_SydneySleeper"								);

	// アイテム管理名
	SetTrieString( g_ItemData,	"0_ItemEdictName",		"tf_weapon_bat"						);
	SetTrieString( g_ItemData,	"1_ItemEdictName",		"tf_weapon_bottle"					);
	SetTrieString( g_ItemData,	"2_ItemEdictName",		"tf_weapon_fireaxe"					);
	SetTrieString( g_ItemData,	"3_ItemEdictName",		"tf_weapon_club"					);
	SetTrieString( g_ItemData,	"4_ItemEdictName",		"tf_weapon_knife"					);
	SetTrieString( g_ItemData,	"5_ItemEdictName",		"tf_weapon_fists"					);
	SetTrieString( g_ItemData,	"6_ItemEdictName",		"tf_weapon_shovel"					);
	SetTrieString( g_ItemData,	"7_ItemEdictName",		"tf_weapon_wrench"					);
	SetTrieString( g_ItemData,	"8_ItemEdictName",		"tf_weapon_bonesaw"					);
	SetTrieString( g_ItemData,	"9_ItemEdictName",		"tf_weapon_shotgun_primary"			);
	SetTrieString( g_ItemData,	"10_ItemEdictName",		"tf_weapon_shotgun_soldier"			);
	SetTrieString( g_ItemData,	"11_ItemEdictName",		"tf_weapon_shotgun_hwg"				);
	SetTrieString( g_ItemData,	"12_ItemEdictName",		"tf_weapon_shotgun_pyro"			);
	SetTrieString( g_ItemData,	"13_ItemEdictName",		"tf_weapon_scattergun"				);
	SetTrieString( g_ItemData,	"14_ItemEdictName",		"tf_weapon_sniperrifle"				);
	SetTrieString( g_ItemData,	"15_ItemEdictName",		"tf_weapon_minigun"					);
	SetTrieString( g_ItemData,	"16_ItemEdictName",		"tf_weapon_smg"						);
	SetTrieString( g_ItemData,	"17_ItemEdictName",		"tf_weapon_syringegun_medic"		);
	SetTrieString( g_ItemData,	"18_ItemEdictName",		"tf_weapon_rocketlauncher"			);
	SetTrieString( g_ItemData,	"19_ItemEdictName",		"tf_weapon_grenadelauncher"			);
	SetTrieString( g_ItemData,	"20_ItemEdictName",		"tf_weapon_pipebomblauncher"		);
	SetTrieString( g_ItemData,	"21_ItemEdictName",		"tf_weapon_flamethrower"			);
	SetTrieString( g_ItemData,	"22_ItemEdictName",		"tf_weapon_pistol"					);
	SetTrieString( g_ItemData,	"23_ItemEdictName",		"tf_weapon_pistol_scout"			);
	SetTrieString( g_ItemData,	"24_ItemEdictName",		"tf_weapon_revolver"				);
	SetTrieString( g_ItemData,	"25_ItemEdictName",		"tf_weapon_pda_engineer_build"		);
	SetTrieString( g_ItemData,	"26_ItemEdictName",		"tf_weapon_pda_engineer_destroy"	);
	SetTrieString( g_ItemData,	"27_ItemEdictName",		"tf_weapon_pda_spy"					);
	SetTrieString( g_ItemData,	"28_ItemEdictName",		"tf_weapon_builder"					);
	SetTrieString( g_ItemData,	"29_ItemEdictName",		"tf_weapon_medigun"					);
	SetTrieString( g_ItemData,	"30_ItemEdictName",		"tf_weapon_invis"					);
	SetTrieString( g_ItemData,	"31_ItemEdictName",		"tf_weapon_flaregun"				);
	SetTrieString( g_ItemData,	"32_ItemEdictName",		"tf_weapon_bonesaw"					);
	SetTrieString( g_ItemData,	"33_ItemEdictName",		"tf_weapon_syringegun_medic"		);
	SetTrieString( g_ItemData,	"34_ItemEdictName",		"tf_weapon_medigun"					);
	SetTrieString( g_ItemData,	"35_ItemEdictName",		"tf_weapon_medigun"					);
	SetTrieString( g_ItemData,	"36_ItemEdictName",		"tf_weapon_syringegun_medic"		);
	SetTrieString( g_ItemData,	"37_ItemEdictName",		"tf_weapon_bonesaw"					);
	SetTrieString( g_ItemData,	"38_ItemEdictName",		"tf_weapon_fireaxe"					);
	SetTrieString( g_ItemData,	"39_ItemEdictName",		"tf_weapon_flaregun"				);
	SetTrieString( g_ItemData,	"40_ItemEdictName",		"tf_weapon_flamethrower"			);
	SetTrieString( g_ItemData,	"41_ItemEdictName",		"tf_weapon_minigun"					);
	SetTrieString( g_ItemData,	"42_ItemEdictName",		"tf_weapon_lunchbox"				);
	SetTrieString( g_ItemData,	"43_ItemEdictName",		"tf_weapon_fists"					);
	SetTrieString( g_ItemData,	"44_ItemEdictName",		"tf_weapon_bat_wood"				);
	SetTrieString( g_ItemData,	"45_ItemEdictName",		"tf_weapon_scattergun"				);
	SetTrieString( g_ItemData,	"46_ItemEdictName",		"tf_weapon_lunchbox_drink"			);
	SetTrieString( g_ItemData,	"47_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"48_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"49_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"50_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"51_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"52_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"53_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"54_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"55_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"56_ItemEdictName",		"tf_weapon_compound_bow"			);
	SetTrieString( g_ItemData,	"57_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"58_ItemEdictName",		"tf_weapon_jar"						);
	SetTrieString( g_ItemData,	"59_ItemEdictName",		"tf_weapon_invis"					);
	SetTrieString( g_ItemData,	"60_ItemEdictName",		"tf_weapon_invis"					);
	SetTrieString( g_ItemData,	"61_ItemEdictName",		"tf_weapon_revolver"				);
	SetTrieString( g_ItemData,	"94_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"95_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"96_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"97_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"98_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"99_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"100_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"101_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"102_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"103_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"104_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"105_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"106_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"107_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"108_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"109_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"110_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"111_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"115_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"116_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"117_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"118_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"120_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"121_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"122_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"123_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"124_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"125_ItemEdictName",		"tf_wearable"					);	
	SetTrieString( g_ItemData,	"126_ItemEdictName",		"tf_wearable"					);	
	SetTrieString( g_ItemData,	"127_ItemEdictName",		"tf_weapon_rocketlauncher_directhit");
	SetTrieString( g_ItemData,	"128_ItemEdictName",		"tf_weapon_shovel"					);
	SetTrieString( g_ItemData,	"129_ItemEdictName",		"tf_weapon_buff_item"				);
	SetTrieString( g_ItemData,	"130_ItemEdictName",		"tf_weapon_pipebomblauncher"		);
	SetTrieString( g_ItemData,	"131_ItemEdictName",		"tf_wearable_demoshield"		);
	SetTrieString( g_ItemData,	"132_ItemEdictName",		"tf_weapon_sword"					);
	SetTrieString( g_ItemData,	"133_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"134_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"135_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"136_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"137_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"138_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"139_ItemEdictName",		"tf_wearable"					);
	SetTrieString( g_ItemData,	"230_ItemEdictName",		"tf_weapon_sniperrifle"				);

	// アイテムモデル
	SetTrieValue( g_ItemData,	"0_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_bat.mdl", true )	);
	SetTrieValue( g_ItemData,	"1_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_bottle.mdl", true )	);
	SetTrieValue( g_ItemData,	"2_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_fireaxe.mdl", true )	);
	SetTrieValue( g_ItemData,	"3_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_machete.mdl", true )	);
	SetTrieValue( g_ItemData,	"4_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_knife.mdl", true )	);
	SetTrieValue( g_ItemData,	"5_ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData,	"6_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_shovel.mdl", true )	);
	SetTrieValue( g_ItemData,	"7_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_wrench.mdl", true )	);
	SetTrieValue( g_ItemData,	"8_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_bonesaw.mdl", true )	);
	SetTrieValue( g_ItemData,	"9_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_shotgun.mdl", true )	);
	SetTrieValue( g_ItemData,	"10_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_shotgun.mdl", true )	);
	SetTrieValue( g_ItemData,	"11_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_shotgun.mdl", true )	);
	SetTrieValue( g_ItemData,	"12_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_shotgun.mdl", true )	);
	SetTrieValue( g_ItemData,	"13_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_scattergun.mdl", true )	);
	SetTrieValue( g_ItemData,	"14_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_sniperrifle.mdl", true )	);
	SetTrieValue( g_ItemData,	"15_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_minigun.mdl", true )	);
	SetTrieValue( g_ItemData,	"16_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_smg.mdl", true )	);
	SetTrieValue( g_ItemData,	"17_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_syringegun.mdl", true )	);
	SetTrieValue( g_ItemData,	"18_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_rocketlauncher.mdl", true )	);
	SetTrieValue( g_ItemData,	"19_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_grenadelauncher.mdl", true )	);
	SetTrieValue( g_ItemData,	"20_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_stickybomb_launcher.mdl", true )	);
	SetTrieValue( g_ItemData,	"21_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_flamethrower.mdl", true )	);
	SetTrieValue( g_ItemData,	"22_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_pistol.mdl", true )	);
	SetTrieValue( g_ItemData,	"23_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_pistol.mdl", true )	);
	SetTrieValue( g_ItemData,	"24_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_revolver.mdl", true )	);
	SetTrieValue( g_ItemData,	"25_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_builder.mdl", true )	);
	SetTrieValue( g_ItemData,	"26_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_builder.mdl", true )	);
	SetTrieValue( g_ItemData,	"27_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_cigarette_case.mdl", true )	);
	SetTrieValue( g_ItemData,	"28_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_builder.mdl", true )	);
	SetTrieValue( g_ItemData,	"29_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_medigun.mdl", true )	);
	SetTrieValue( g_ItemData,	"30_ItemModelIndex",		PrecacheModel( "models/weapons/v_models/v_watch_spy.mdl", true )	);
	SetTrieValue( g_ItemData,	"31_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_pistol.mdl", true )	);
	SetTrieValue( g_ItemData,	"32_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_bonesaw.mdl", true )	);
	SetTrieValue( g_ItemData,	"33_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_syringegun.mdl", true )	);
	SetTrieValue( g_ItemData,	"34_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_medigun.mdl", true )	);
	SetTrieValue( g_ItemData,	"35_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_medigun/c_medigun.mdl", true )	);
	SetTrieValue( g_ItemData,	"36_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_leechgun/c_leechgun.mdl", true )	);
	SetTrieValue( g_ItemData,	"37_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_ubersaw/c_ubersaw.mdl", true )	);
	SetTrieValue( g_ItemData,	"38_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_axtinguisher/c_axtinguisher_pyro.mdl", true )	);
	SetTrieValue( g_ItemData,	"39_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_flaregun_pyro/c_flaregun_pyro.mdl", true )	);
	SetTrieValue( g_ItemData,	"40_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_flamethrower/c_flamethrower.mdl", true )	);
	SetTrieValue( g_ItemData,	"41_ItemModelIndex",		PrecacheModel( "models/weapons/w_models/w_minigun.mdl", true )	);
	SetTrieValue( g_ItemData,	"42_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_sandwich/c_sandwich.mdl", true )	);
	SetTrieValue( g_ItemData,	"43_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_boxing_gloves/c_boxing_gloves.mdl", true )	);
	SetTrieValue( g_ItemData,	"44_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_wooden_bat/c_wooden_bat.mdl", true )	);
	SetTrieValue( g_ItemData,	"45_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_double_barrel.mdl", true )	);
	SetTrieValue( g_ItemData,	"46_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_energy_drink/c_energy_drink.mdl", true )	);
//	SetTrieValue( g_ItemData,	"47_ItemModelIndex",		PrecacheModel( "models/player/items/demo/demo_afro.mdl", true )	);
//	SetTrieValue( g_ItemData,	"48_ItemModelIndex",		PrecacheModel( "models/player/items/engineer/mining_hat.mdl", true )	);
//	SetTrieValue( g_ItemData,	"49_ItemModelIndex",		PrecacheModel( "models/player/items/heavy/football_helmet.mdl", true )	);
//	SetTrieValue( g_ItemData,	"50_ItemModelIndex",		PrecacheModel( "models/player/items/medic/medic_helmet.mdl", true )	);
//	SetTrieValue( g_ItemData,	"51_ItemModelIndex",		PrecacheModel( "models/player/items/pyro/pyro_hat.mdl", true )	);
//	SetTrieValue( g_ItemData,	"52_ItemModelIndex",		PrecacheModel( "models/player/items/scout/batter_helmet.mdl", true )	);
//	SetTrieValue( g_ItemData,	"53_ItemModelIndex",		PrecacheModel( "models/player/items/sniper/tooth_hat.mdl", true )	);
//	SetTrieValue( g_ItemData,	"54_ItemModelIndex",		PrecacheModel( "models/player/items/soldier/soldier_hat.mdl", true )	);
//	SetTrieValue( g_ItemData,	"55_ItemModelIndex",		PrecacheModel( "models/player/items/spy/spy_hat.mdl", true )	);
	SetTrieValue( g_ItemData,	"56_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_bow/c_bow.mdl", true )	);
	SetTrieValue( g_ItemData,	"57_ItemModelIndex",		PrecacheModel( "models/player/items/sniper/knife_shield.mdl", true )	);
	SetTrieValue( g_ItemData,	"58_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/urinejar.mdl", true )	);
	SetTrieValue( g_ItemData,	"59_ItemModelIndex",		PrecacheModel( "models/weapons/v_models/v_watch_pocket_spy.mdl", true )	);
	SetTrieValue( g_ItemData,	"60_ItemModelIndex",		PrecacheModel( "models/weapons/v_models/v_watch_leather_spy.mdl", true )	);
	SetTrieValue( g_ItemData,	"61_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_ambassador/c_ambassador.mdl", true )	);
//	SetTrieValue( g_ItemData,	"94_ItemModelIndex",		PrecacheModel( "models/player/items/engineer/engineer_cowboy_hat.mdl", true )	);
//	SetTrieValue( g_ItemData,	"95_ItemModelIndex",		PrecacheModel( "models/player/items/engineer/engineer_train_hat.mdl", true )	);
//	SetTrieValue( g_ItemData,	"96_ItemModelIndex",		PrecacheModel( "models/player/items/heavy/heavy_ushanka.mdl", true )	);
//	SetTrieValue( g_ItemData,	"97_ItemModelIndex",		PrecacheModel( "models/player/items/heavy/heavy_stocking_cap.mdl", true )	);
//	SetTrieValue( g_ItemData,	"98_ItemModelIndex",		PrecacheModel( "models/player/items/soldier/soldier_pot.mdl", true )	);
//	SetTrieValue( g_ItemData,	"99_ItemModelIndex",		PrecacheModel( "models/player/items/soldier/soldier_viking.mdl", true )	);
//	SetTrieValue( g_ItemData,	"100_ItemModelIndex",		PrecacheModel( "models/player/items/demo/demo_scott.mdl", true )	);
//	SetTrieValue( g_ItemData,	"101_ItemModelIndex",		PrecacheModel( "models/player/items/medic/medic_tyrolean.mdl", true )	);
//	SetTrieValue( g_ItemData,	"102_ItemModelIndex",		PrecacheModel( "models/player/items/pyro/pyro_chicken.mdl", true )	);
//	SetTrieValue( g_ItemData,	"103_ItemModelIndex",		PrecacheModel( "models/player/items/spy/spy_camera_beard.mdl", true )	);
//	SetTrieValue( g_ItemData,	"104_ItemModelIndex",		PrecacheModel( "models/player/items/medic/medic_mirror.mdl", true )	);
//	SetTrieValue( g_ItemData,	"105_ItemModelIndex",		PrecacheModel( "models/player/items/pyro/fireman_helmet.mdl", true )	);
//	SetTrieValue( g_ItemData,	"106_ItemModelIndex",		PrecacheModel( "models/player/items/scout/bonk_helmet.mdl", true )	);
//	SetTrieValue( g_ItemData,	"107_ItemModelIndex",		PrecacheModel( "models/player/items/scout/newsboy_cap.mdl", true )	);
//	SetTrieValue( g_ItemData,	"108_ItemModelIndex",		PrecacheModel( "models/player/items/spy/derby_hat.mdl", true )	);
//	SetTrieValue( g_ItemData,	"109_ItemModelIndex",		PrecacheModel( "models/player/items/sniper/straw_hat.mdl", true )	);
//	SetTrieValue( g_ItemData,	"110_ItemModelIndex",		PrecacheModel( "models/player/items/sniper/jarate_headband.mdl", true )	);
	SetTrieValue( g_ItemData,	"111_ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData,	"115_ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData,	"116_ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData,	"117_ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData,	"118_ItemModelIndex",		-1 );
//	SetTrieValue( g_ItemData,	"120_ItemModelIndex",		PrecacheModel( "models/player/items/demo/top_hat.mdl", true )	);
	SetTrieValue( g_ItemData,	"121_ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData,	"122_ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData,	"123_ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData,	"124_ItemModelIndex",		-1 );
//	SetTrieValue( g_ItemData,	"125_ItemModelIndex",		PrecacheModel( "models/player/items/all_class/all_halo.mdl", true )	);
	SetTrieValue( g_ItemData,	"126_ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData,	"127_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_directhit/c_directhit.mdl", true )	);
	SetTrieValue( g_ItemData,	"128_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_pickaxe/c_pickaxe.mdl", true )	);
	SetTrieValue( g_ItemData,	"129_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_bugle/c_bugle.mdl", true )	);
	SetTrieValue( g_ItemData,	"130_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_stickybomb_launcher.mdl", true )	);
	SetTrieValue( g_ItemData,	"131_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_targe/c_targe.mdl", true )	);
	SetTrieValue( g_ItemData,	"132_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_claymore/c_claymore.mdl", true )	);
	SetTrieValue( g_ItemData,	"133_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_rocketboots_soldier.mdl", true )	);
	SetTrieValue( g_ItemData,	"134_ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData,	"135_ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData,	"136_ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData,	"137_ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData,	"138_ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData,	"139_ItemModelIndex",		-1 );
	SetTrieValue( g_ItemData,	"230_ItemModelIndex",		PrecacheModel( "models/weapons/c_models/c_dartgun.mdl", true));
	
	// アイテム最小レベル
	SetTrieValue( g_ItemData,	"0_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"1_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"2_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"3_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"4_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"5_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"6_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"7_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"8_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"9_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"10_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"11_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"12_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"13_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"14_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"15_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"16_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"17_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"18_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"19_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"20_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"21_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"22_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"23_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"24_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"25_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"26_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"27_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"28_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"29_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"30_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"31_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"32_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"33_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"34_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"35_ItemMinLevel",		8	);
	SetTrieValue( g_ItemData,	"36_ItemMinLevel",		5	);
	SetTrieValue( g_ItemData,	"37_ItemMinLevel",		10	);
	SetTrieValue( g_ItemData,	"38_ItemMinLevel",		10	);
	SetTrieValue( g_ItemData,	"39_ItemMinLevel",		10	);
	SetTrieValue( g_ItemData,	"40_ItemMinLevel",		10	);
	SetTrieValue( g_ItemData,	"41_ItemMinLevel",		5	);
	SetTrieValue( g_ItemData,	"42_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"43_ItemMinLevel",		7	);
	SetTrieValue( g_ItemData,	"44_ItemMinLevel",		15	);
	SetTrieValue( g_ItemData,	"45_ItemMinLevel",		10	);
	SetTrieValue( g_ItemData,	"46_ItemMinLevel",		5	);
	SetTrieValue( g_ItemData,	"47_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"48_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"49_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"50_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"51_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"52_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"53_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"54_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"55_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"56_ItemMinLevel",		10	);
	SetTrieValue( g_ItemData,	"57_ItemMinLevel",		10	);
	SetTrieValue( g_ItemData,	"58_ItemMinLevel",		5	);
	SetTrieValue( g_ItemData,	"59_ItemMinLevel",		5	);
	SetTrieValue( g_ItemData,	"60_ItemMinLevel",		5	);
	SetTrieValue( g_ItemData,	"61_ItemMinLevel",		5	);
	SetTrieValue( g_ItemData,	"94_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"95_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"96_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"97_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"98_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"99_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"100_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"101_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"102_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"103_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"104_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"105_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"106_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"107_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"108_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"109_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"110_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"111_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"115_ItemMinLevel",		10	);
	SetTrieValue( g_ItemData,	"116_ItemMinLevel",		10	);
	SetTrieValue( g_ItemData,	"117_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"118_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"120_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"121_ItemMinLevel",		100	);
	SetTrieValue( g_ItemData,	"122_ItemMinLevel",		100	);
	SetTrieValue( g_ItemData,	"123_ItemMinLevel",		100	);
	SetTrieValue( g_ItemData,	"124_ItemMinLevel",		100	);
	SetTrieValue( g_ItemData,	"125_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"126_ItemMinLevel",		10	);
	SetTrieValue( g_ItemData,	"127_ItemMinLevel",		1	);
	SetTrieValue( g_ItemData,	"128_ItemMinLevel",		10	);
	SetTrieValue( g_ItemData,	"129_ItemMinLevel",		5	);
	SetTrieValue( g_ItemData,	"130_ItemMinLevel",		5	);
	SetTrieValue( g_ItemData,	"131_ItemMinLevel",		10	);
	SetTrieValue( g_ItemData,	"132_ItemMinLevel",		5	);
	SetTrieValue( g_ItemData,	"133_ItemMinLevel",		10	);
	SetTrieValue( g_ItemData,	"134_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"135_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"136_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"137_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"138_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"139_ItemMinLevel",		0	);
	SetTrieValue( g_ItemData,	"230_ItemMinLevel",		1	);

	// アイテム最大レベル
	SetTrieValue( g_ItemData,	"0_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"1_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"2_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"3_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"4_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"5_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"6_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"7_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"8_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"9_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"10_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"11_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"12_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"13_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"14_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"15_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"16_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"17_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"18_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"19_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"20_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"21_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"22_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"23_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"24_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"25_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"26_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"27_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"28_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"29_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"30_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"31_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"32_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"33_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"34_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"35_ItemMaxLevel",		8	);
	SetTrieValue( g_ItemData,	"36_ItemMaxLevel",		5	);
	SetTrieValue( g_ItemData,	"37_ItemMaxLevel",		10	);
	SetTrieValue( g_ItemData,	"38_ItemMaxLevel",		10	);
	SetTrieValue( g_ItemData,	"39_ItemMaxLevel",		10	);
	SetTrieValue( g_ItemData,	"40_ItemMaxLevel",		10	);
	SetTrieValue( g_ItemData,	"41_ItemMaxLevel",		5	);
	SetTrieValue( g_ItemData,	"42_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"43_ItemMaxLevel",		7	);
	SetTrieValue( g_ItemData,	"44_ItemMaxLevel",		15	);
	SetTrieValue( g_ItemData,	"45_ItemMaxLevel",		10	);
	SetTrieValue( g_ItemData,	"46_ItemMaxLevel",		5	);
	SetTrieValue( g_ItemData,	"47_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"48_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"49_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"50_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"51_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"52_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"53_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"54_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"55_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"56_ItemMaxLevel",		10	);
	SetTrieValue( g_ItemData,	"57_ItemMaxLevel",		10	);
	SetTrieValue( g_ItemData,	"58_ItemMaxLevel",		5	);
	SetTrieValue( g_ItemData,	"59_ItemMaxLevel",		5	);
	SetTrieValue( g_ItemData,	"60_ItemMaxLevel",		5	);
	SetTrieValue( g_ItemData,	"61_ItemMaxLevel",		5	);
	SetTrieValue( g_ItemData,	"94_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"95_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"96_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"97_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"98_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"99_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"100_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"101_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"102_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"103_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"104_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"105_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"106_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"107_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"108_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"109_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"110_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"111_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"115_ItemMaxLevel",		10	);
	SetTrieValue( g_ItemData,	"116_ItemMaxLevel",		10	);
	SetTrieValue( g_ItemData,	"117_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"118_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"120_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"121_ItemMaxLevel",		100	);
	SetTrieValue( g_ItemData,	"122_ItemMaxLevel",		100	);
	SetTrieValue( g_ItemData,	"123_ItemMaxLevel",		100	);
	SetTrieValue( g_ItemData,	"124_ItemMaxLevel",		100	);
	SetTrieValue( g_ItemData,	"125_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"126_ItemMaxLevel",		10	);
	SetTrieValue( g_ItemData,	"127_ItemMaxLevel",		1	);
	SetTrieValue( g_ItemData,	"128_ItemMaxLevel",		10	);
	SetTrieValue( g_ItemData,	"129_ItemMaxLevel",		5	);
	SetTrieValue( g_ItemData,	"130_ItemMaxLevel",		5	);
	SetTrieValue( g_ItemData,	"131_ItemMaxLevel",		10	);
	SetTrieValue( g_ItemData,	"132_ItemMaxLevel",		5	);
	SetTrieValue( g_ItemData,	"133_ItemMaxLevel",		10	);
	SetTrieValue( g_ItemData,	"134_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"135_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"136_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"137_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"138_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"139_ItemMaxLevel",		0	);
	SetTrieValue( g_ItemData,	"230_ItemMaxLevel",		1	);

	// アイテムクオリティ
	SetTrieValue( g_ItemData,	"0_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"1_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"2_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"3_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"4_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"5_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"6_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"7_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"8_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"9_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"10_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"11_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"12_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"13_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"14_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"15_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"16_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"17_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"18_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"19_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"20_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"21_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"22_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"23_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"24_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"25_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"26_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"27_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"28_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"29_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"30_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"31_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"32_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"33_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"34_ItemQuality",		QUALITY_NORMAL );
	SetTrieValue( g_ItemData,	"35_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"36_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"37_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"38_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"39_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"40_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"41_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"42_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"43_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"44_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"45_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"46_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"47_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"48_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"49_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"50_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"51_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"52_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"53_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"54_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"55_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"56_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"57_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"58_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"59_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"60_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"61_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"94_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"95_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"96_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"97_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"98_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"99_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"100_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"101_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"102_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"103_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"104_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"105_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"106_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"107_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"108_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"109_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"110_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"111_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"115_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"116_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"117_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"118_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"120_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"121_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"122_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"123_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"124_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"125_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"126_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"127_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"128_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"129_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"130_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"131_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"132_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"133_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"135_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"136_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"137_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"138_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"139_ItemQuality",		QUALITY_UNIQUE );
	SetTrieValue( g_ItemData,	"230_ItemQuality",		QUALITY_UNIQUE );

	//// モデル読み込み
	//for( new i = 0; i < TF2_ITEM_NUM; i++)
	//{
	//	// アイテムデータが設定されている
	//	if( GetTrieSize(g_ItemData[i]) > 0 )
	//	{
	//		// モデル名を取得
	//		new String:modelName[64];
	//		GetTrieString( g_ItemData[i], "ItemModelIndex", modelName, sizeof(modelName));
	//		if( !StrEqual( modelName, "" ) )
	//		{
	//			PrecacheModel( modelName, true );
	//		}
	//	}
	//}
		
}


/////////////////////////////////////////////////////////////////////
//
// ゲームコンフィグ後処理
//
/////////////////////////////////////////////////////////////////////
stock FinalItemData()
{
	if( g_ItemData != INVALID_HANDLE )
	{
		CloseHandle( g_ItemData);
	}
}


/////////////////////////////////////////////////////////////////////
//
// アイテム配布
//
/////////////////////////////////////////////////////////////////////
stock bool:TF2_GiveItem( any:client, TFItems:itemIndex )
{
	// クライアント
	if( client > 0 && client <= MaxClients)
	{
		// ゲームに入ってる
		if( IsClientInGame( client ) && IsPlayerAlive(client) )
		{
			decl String:formatBuffer[32];
			new ItemSlot;
			Format(formatBuffer, 32, "%d_ItemSlot", itemIndex);
			if (GetTrieValue(g_ItemData, formatBuffer, ItemSlot))
			{
//				decl String:formatBuffer[32];
				// アイテムインデックス取得
				new ItemDefinitionIndex = _:itemIndex;
				// スロット取得

				// 管理名を取得
				new String:edictName[64];
				Format(formatBuffer, 32, "%d_ItemEdictName", itemIndex);
				GetTrieString( g_ItemData, formatBuffer, edictName, sizeof(edictName));
				// モデルインデックスを取得
				new ItemModelIndex;
				Format(formatBuffer, 32, "%d_ItemModelIndex", itemIndex);
				GetTrieValue( g_ItemData, formatBuffer, ItemModelIndex );
				// アイテムタイプ取得
				new ItemType;
				Format(formatBuffer, 32, "%d_ItemType", itemIndex);
				GetTrieValue( g_ItemData, formatBuffer, ItemType );
				// アイテム最小レベル取得
				new ItemMinLevel;
				Format(formatBuffer, 32, "%d_ItemMinLevel", itemIndex);
				GetTrieValue( g_ItemData, formatBuffer, ItemMinLevel );
				// アイテム最大レベル取得
				new ItemMaxLevel;
				Format(formatBuffer, 32, "%d_ItemMaxLevel", itemIndex);
				GetTrieValue( g_ItemData, formatBuffer, ItemMaxLevel );
				// アイテムクオリティ取得
				new ItemQuality;
				Format(formatBuffer, 32, "%d_ItemQuality", itemIndex);
				GetTrieValue( g_ItemData, formatBuffer, ItemQuality );
				
				
				// 入れるスロットを削除
				if( ItemSlot < _:SLOT_BUILDING )
				{
					new weaponIndex = GetPlayerWeaponSlot( client, ItemSlot );
					if( weaponIndex != -1 )
					{
						//RemovePlayerItem( client, weaponIndex );
						//RemoveEdict( weaponIndex );
						TF2_RemoveWeaponSlot( client, ItemSlot );
					}	
					
				}
				// ウェア検索
				new ent = -1;
				while ((ent = FindEntityByClassname2(ent, "tf_wearable")) != -1)
				{
					// clientのウェア
					new iOwner = GetEntPropEnt( ent, Prop_Send, "m_hOwnerEntity")
					if(iOwner == client)
					{
						// スロットが同じなら削除
						if( TF2_GetItemSlot( ent ) == TFItemSlot:ItemSlot )
						{
							// 削除
							SDKCall( g_hRemoveWearable, client, ent );
						}
					}
				}				
				
				// アイテム取得＆装備
				//new giveItem = SDKCall( g_hGiveNamedItem, client, edictName, 0 );
				
				new giveItem = GivePlayerItem(client, edictName);

				// 生成できた？
				if( IsValidEdict(giveItem) )//giveItem != -1 )
				{
					
					// 武器
					if( ItemType == _:TYPE_WEAPON )
					{
						SetEntProp(giveItem, Prop_Send, "m_bInitialized", 			1 );
						SetEntProp(giveItem, Prop_Send, "m_nSkin",					( GetClientTeam( client ) - 2 ) );
						SetEntProp(giveItem, Prop_Send, "m_iItemDefinitionIndex",	ItemDefinitionIndex );
						SetEntProp(giveItem, Prop_Send, "m_iEntityLevel",			GetRandomInt(ItemMinLevel, ItemMaxLevel) );
						SetEntProp(giveItem, Prop_Send, "m_iEntityQuality",			ItemQuality );
						if( ItemModelIndex != -1 )
						{
							SetEntProp(giveItem, Prop_Send, "m_iWorldModelIndex",			ItemModelIndex );
						}
						DispatchSpawn(giveItem);
						// 出来たら装備
						EquipPlayerWeapon(client, giveItem);

						return true;
					}
					// ウェア
					else if( ItemType == _:TYPE_WEAR )
					{
						SetEntProp(giveItem, Prop_Send, "m_bInitialized", 			1 );
						SetEntProp(giveItem, Prop_Send, "m_nSkin",					( GetClientTeam( client ) - 2 ) );
						SetEntProp(giveItem, Prop_Send, "m_iItemDefinitionIndex",	ItemDefinitionIndex );
						SetEntProp(giveItem, Prop_Send, "m_iEntityLevel",			GetRandomInt(ItemMinLevel, ItemMaxLevel) );
						SetEntProp(giveItem, Prop_Send, "m_iEntityQuality",			ItemQuality );
						DispatchSpawn(giveItem);
						// 出来たら装備
						SDKCall( g_hEquipWearable, client, giveItem );
						if( ItemModelIndex != -1 )
						{
							SetEntProp(giveItem, Prop_Send, "m_nModelIndex",			ItemModelIndex );
						}
						return true;
						
					}
					
					// アイテム番号設定
					//SetEntProp( giveItem, Prop_Send, "m_iItemDefinitionIndex", itemIndex );
					
				}
			}
		}
	}

	return false;
}





/////////////////////////////////////////////////////////////////////
//
// アイテム設定インデックス取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetItemDefIndex( entIndex )
{
	if( entIndex != -1 )
	{
		decl String:classname[32];
		if (GetEdictClassname(entIndex, classname, sizeof(classname)) && (StrContains(classname, "weapon", false) != -1 || StrContains(classname, "wearable", false) != -1))
			return GetEntProp( entIndex, Prop_Send, "m_iItemDefinitionIndex" );
		else return -1;
	}
	return -1;
}

/////////////////////////////////////////////////////////////////////
//
// アイテムクオリティ取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetItemQuality( entIndex )
{
	if( entIndex != -1 )
	{
		return GetEntProp( entIndex, Prop_Send, "m_iEntityQuality" );
	}
	return -1;
}


/////////////////////////////////////////////////////////////////////
//
// アイテムスロット取得
//
/////////////////////////////////////////////////////////////////////
stock TFItemSlot:TF2_GetItemSlot( entIndex )
{
	new itemIndex = TF2_GetItemDefIndex( entIndex );
	if( itemIndex != -1)
	{
		decl String:formatBuffer[32];
		new TFItemSlot:ItemSlot;
		Format(formatBuffer, 32, "%d_ItemSlot", itemIndex);
		GetTrieValue( g_ItemData, formatBuffer,  ItemSlot);
		return ItemSlot;
	}
	return SLOT_UNKOWN;
}

/////////////////////////////////////////////////////////////////////
//
// アイテム名取得
//
/////////////////////////////////////////////////////////////////////
stock TF2_GetItemName(entIndex, String:name[], maxlength)
{
	new itemIndex = TF2_GetItemDefIndex( entIndex );
	if( itemIndex != -1)
	{
		decl String:formatBuffer[32];
		Format(formatBuffer, 32, "%d_ItemName", itemIndex);
		GetTrieString( g_ItemData, formatBuffer, name, maxlength);
	}
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// Register Native
	CreateNative("RMF_GetItemName", RMF_TF2_GetItemName);
	CreateNative("RMF_GetItemSlot", RMF_TF2_GetItemSlot);
	CreateNative("RMF_GetItemQuality", RMF_TF2_GetItemQuality);
	CreateNative("RMF_GetItemDefIndex", RMF_TF2_GetItemDefIndex);
	CreateNative("RMF_GiveItem", RMF_TF2_GiveItem);
	CreateNative("RMF_GetMaxHealth", RMF_TF2_GetMaxHealth);
	RegPluginLibrary("rmf_items");
/*	if (late)
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			SDKUnhook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
			OnClientPutInServer(client);
		}
	}*/
	return APLRes_Success;
}
public RMF_TF2_GetItemName(Handle:plugin, numParams)
{
	decl String:name[64];
	new entIndex = GetNativeCell(1);
	new maxlength = GetNativeCell(3);
	TF2_GetItemName(entIndex, name, maxlength);
	if (SetNativeString(2, name, maxlength) != SP_ERROR_NONE) ThrowNativeError(SP_ERROR_NATIVE, "[RMF] Something failed in getting name of entity %d", entIndex);
}
public RMF_TF2_GetItemSlot(Handle:plugin, numParams)
{
	new entIndex = GetNativeCell(1);
	return _:TF2_GetItemSlot(entIndex);
}
public RMF_TF2_GetItemQuality(Handle:plugin, numParams)
{
	new entIndex = GetNativeCell(1);
	return TF2_GetItemQuality(entIndex);
}
public RMF_TF2_GetItemDefIndex(Handle:plugin, numParams)
{
	new entIndex = GetNativeCell(1);
	return TF2_GetItemDefIndex(entIndex);
}
public RMF_TF2_GiveItem(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new TFItems:itemIndex = TFItems:GetNativeCell(2);
	return TF2_GiveItem(client, itemIndex);
}
public RMF_TF2_GetMaxHealth(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return SDKCall(g_hGetMaxHealth, client);
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}