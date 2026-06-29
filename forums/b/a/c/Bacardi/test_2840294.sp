


#define ITEM_FLAG_SELECTONEMPTY		(1<<0)
#define ITEM_FLAG_NOAUTORELOAD		(1<<1)
#define ITEM_FLAG_NOAUTOSWITCHEMPTY	(1<<2)
#define ITEM_FLAG_LIMITINWORLD		(1<<3)
#define ITEM_FLAG_EXHAUSTIBLE			(1<<4)
#define ITEM_FLAG_DOHITLOCATIONDMG	(1<<5)
#define ITEM_FLAG_NOAMMOPICKUPS		(1<<6)
#define ITEM_FLAG_NOITEMPICKUP		(1<<7)


#include <sdktools>
#include <cstrike>

/*
// <cstrike> already done this
char weapons[][] =
{
	"WEAPON_NONE", "WEAPON_P228", "WEAPON_GLOCK", "WEAPON_SCOUT", "WEAPON_HEGRENADE", "WEAPON_XM1014", "WEAPON_C4", "WEAPON_MAC10", "WEAPON_AUG", "WEAPON_SMOKEGRENADE",
	"WEAPON_ELITE", "WEAPON_FIVESEVEN", "WEAPON_UMP45", "WEAPON_SG550", "WEAPON_GALIL", "WEAPON_FAMAS", "WEAPON_USP", "WEAPON_AWP", "WEAPON_MP5NAVY", "WEAPON_M249", "WEAPON_M3",
	"WEAPON_M4A1", "WEAPON_TMP", "WEAPON_G3SG1", "WEAPON_FLASHBANG", "WEAPON_DEAGLE", "WEAPON_SG552", "WEAPON_AK47", "WEAPON_KNIFE", "WEAPON_P90", "WEAPON_SHIELDGUN", "WEAPON_KEVLAR",
	"WEAPON_ASSAULTSUIT", "WEAPON_NVG", "WEAPON_MAX"
}
*/

Handle GetWeaponInfo;
Address off_iFlags;
Address off_iWeight;
Address off_bAutoSwitchTo;
Address off_bAutoSwitchFrom;
Address off_iMaxClip1;
Address off_m_flMaxSpeed;
Address off_m_iDefaultPrice;
//Address off_m_iWeaponPrice;
Address off_m_flArmorRatio;
Address off_m_iPenetration;
Address off_m_iDamage;
Address off_m_flRange;


public void OnPluginStart()
{
	RegConsoleCmd("sm_test", test);

	//// works
	//StartPrepSDKCall(SDKCall_Raw);
	//PrepSDKCall_SetAddress(0x6ABA95C0); // server.dll+E95C0
	//PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	//weaponflags = EndPrepSDKCall(); // SDKCall(weaponflags, weapon_entity_address);


	GameData gamedata = new GameData("test/FileWeaponInfo_t");
	off_iFlags = view_as<Address>(gamedata.GetOffset("iFlags"));
	off_bAutoSwitchTo = view_as<Address>(gamedata.GetOffset("bAutoSwitchTo"));
	off_bAutoSwitchFrom = view_as<Address>(gamedata.GetOffset("bAutoSwitchFrom"));
	off_iWeight = view_as<Address>(gamedata.GetOffset("iWeight"));
	off_iMaxClip1 = view_as<Address>(gamedata.GetOffset("iMaxClip1"));
	off_m_flMaxSpeed = view_as<Address>(gamedata.GetOffset("m_flMaxSpeed"));
	off_m_iDefaultPrice = view_as<Address>(gamedata.GetOffset("m_iDefaultPrice"));
	//off_m_iWeaponPrice = view_as<Address>(gamedata.GetOffset("m_iWeaponPrice"));
	off_m_flArmorRatio = view_as<Address>(gamedata.GetOffset("m_flArmorRatio"));
	off_m_iPenetration = view_as<Address>(gamedata.GetOffset("m_iPenetration"));
	off_m_iDamage = view_as<Address>(gamedata.GetOffset("m_iDamage"));
	off_m_flRange = view_as<Address>(gamedata.GetOffset("m_flRange"));

	StartPrepSDKCall(SDKCall_Server);
	//char sign[] = "\x55\x8B\xEC\x8B\x4D\x08\x56\x85\xC9\x74\x2A\x83\xF9\x1F";
	//PrepSDKCall_SetSignature(SDKLibrary_Server, sign, strlen(sign)); // server.dll+E95C0
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "GetWeaponInfo");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	GetWeaponInfo = EndPrepSDKCall();


}

public Action test(int client, int args)
{

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	char classname[35];
	GetEntityClassname(weapon, classname, sizeof(classname));

	CSWeaponID weaponid = CS_AliasToWeaponID(classname);

	//for(int x = 0; x < sizeof(weapons); x++)
	//{
	//	if(StrEqual(classname, weapons[x], false))
	//	{
	//		weaponid = x;
	//		break;
	//	}
	//}

	Address address = GetEntityAddress(weapon);

	Address weapoinfo = SDKCall(GetWeaponInfo, weaponid);
	int iFlags = LoadFromAddress(weapoinfo+off_iFlags, NumberType_Int16);
	int bAutoSwitchTo = LoadFromAddress(weapoinfo+off_bAutoSwitchTo, NumberType_Int8);
	int bAutoSwitchFrom = LoadFromAddress(weapoinfo+off_bAutoSwitchFrom, NumberType_Int8);
	int iWeight = LoadFromAddress(weapoinfo+off_iWeight, NumberType_Int8);
	int iMaxClip1 = LoadFromAddress(weapoinfo+off_iMaxClip1, NumberType_Int8);
	float m_flMaxSpeed = LoadFromAddress(weapoinfo+off_m_flMaxSpeed, NumberType_Int32);
	int m_iDefaultPrice = LoadFromAddress(weapoinfo+off_m_iDefaultPrice, NumberType_Int16);
	//int m_iWeaponPrice = LoadFromAddress(weapoinfo+off_m_iWeaponPrice, NumberType_Int16);
	float m_flArmorRatio = LoadFromAddress(weapoinfo+off_m_flArmorRatio, NumberType_Int32);
	int m_iPenetration = LoadFromAddress(weapoinfo+off_m_iPenetration, NumberType_Int8);
	int m_iDamage = LoadFromAddress(weapoinfo+off_m_iDamage, NumberType_Int8);
	float m_flRange = LoadFromAddress(weapoinfo+off_m_flRange, NumberType_Int32);

	PrintToServer("GetWeaponID %i entity %i address %X = GetWeaponInfo %X", weaponid, weapon,  address, weapoinfo);
	PrintToServer("iFlags %i", iFlags);
	PrintToServer("bAutoSwitchTo %i", bAutoSwitchTo);
	PrintToServer("bAutoSwitchFrom %i", bAutoSwitchFrom);
	PrintToServer("iWeight %i", iWeight);
	PrintToServer("iMaxClip1 %i", iMaxClip1);
	PrintToServer("m_flMaxSpeed %f", m_flMaxSpeed);
	PrintToServer("m_iDefaultPrice %i", m_iDefaultPrice);
	//PrintToServer("m_iWeaponPrice %i", m_iWeaponPrice);
	PrintToServer("m_flArmorRatio %f", m_flArmorRatio);
	PrintToServer("m_iPenetration %i", m_iPenetration);
	PrintToServer("m_iDamage %i", m_iDamage);
	PrintToServer("m_flRange %f", m_flRange);
	PrintToServer("\n");


	// Modify weapon data

	iFlags |= ITEM_FLAG_NOAUTORELOAD;
	iFlags |= ITEM_FLAG_NOAUTOSWITCHEMPTY;
	StoreToAddress(weapoinfo+off_iFlags, iFlags, NumberType_Int16);

	StoreToAddress(weapoinfo+off_bAutoSwitchTo, 0, NumberType_Int8);
	StoreToAddress(weapoinfo+off_bAutoSwitchFrom, 0, NumberType_Int8);
	StoreToAddress(weapoinfo+off_iWeight, 0, NumberType_Int8);



	StoreToAddress(weapoinfo+off_m_iPenetration, 10, NumberType_Int8);
	StoreToAddress(weapoinfo+off_m_iDamage, 200, NumberType_Int8);
	StoreToAddress(weapoinfo+off_m_flRange, 8192.0, NumberType_Int32);
	StoreToAddress(weapoinfo+off_m_flArmorRatio, 0.1, NumberType_Int32);



	return Plugin_Handled;
}

