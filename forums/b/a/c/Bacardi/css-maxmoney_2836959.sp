




public Plugin myinfo =
{
	name = "[CS:S]MaxMoney",
	author = "Dr!fter, Bacardi",
	description = "Patches max money",
	version = "2.0.0"
}



ConVar mp_maxmoney;
Address adr_addacc;
Address adr_reset;
int offset_cmp_max;
int offset_set_max;

public void OnPluginStart()
{
	GameData gamedata = new GameData("maxmoney.css");
	
	if(gamedata == null)
		SetFailState("Failed to read gamedata file maxmoney.css.txt");


	ConVar mp_startmoney = FindConVar("mp_startmoney");
	
	if(mp_startmoney != null)
	{
		mp_startmoney.SetBounds(ConVarBound_Lower, true, 0.0);
		mp_startmoney.SetBounds(ConVarBound_Upper, true, 65535.0);
	}

	mp_maxmoney = CreateConVar("mp_maxmoney", "65535", "Set maximum money account", _, true, 0.0, true, 65535.0);
	mp_maxmoney.AddChangeHook(convarchanged);


	adr_addacc = gamedata.GetAddress("AddAccount");

	if(adr_addacc == view_as<Address>(0)) SetFailState("Failed to find address AddAccount");

	adr_reset = gamedata.GetAddress("PlayerReset");

	if(adr_reset == view_as<Address>(0)) SetFailState("Failed to find address PlayerReset");

	offset_cmp_max = gamedata.GetOffset("offset_cmp_max");

	if(offset_cmp_max == -1) SetFailState("Failed to get offset offset_cmp_max from gamedata file");

	offset_set_max = gamedata.GetOffset("offset_set_max");

	if(offset_set_max == -1) SetFailState("Failed to get offset offset_set_max from gamedata file");


	//int output = LoadFromAddress(adr_addacc + view_as<Address>(offset_cmp_max), NumberType_Int32);
	//PrintToServer(" %X  cmp output %08X", adr_addacc + view_as<Address>(offset_cmp_max), output);

	StoreToAddress(adr_addacc + view_as<Address>(offset_cmp_max), mp_maxmoney.IntValue, NumberType_Int32);

	//output = LoadFromAddress(adr_addacc + view_as<Address>(offset_set_max), NumberType_Int32);
	//PrintToServer(" %X  set output %08X", adr_addacc + view_as<Address>(offset_set_max), output);

	StoreToAddress(adr_addacc + view_as<Address>(offset_set_max), mp_maxmoney.IntValue, NumberType_Int32);


	//output = LoadFromAddress(adr_reset, NumberType_Int32);
	//PrintToServer(" %X  reset output %08X", adr_reset, output);

	StoreToAddress(adr_reset, -mp_maxmoney.IntValue, NumberType_Int32);
	 
	//PrintToServer("   mp_maxmoney output %08X %i", mp_maxmoney.IntValue, mp_maxmoney.IntValue);

	//RegConsoleCmd("sm_test", test);
}

//public Action test(int client, int args)
//{
//	PrintToServer("m_iAccount %i ", GetEntProp(client, Prop_Send, "m_iAccount"));
//
//	return Plugin_Handled;
//}

public void convarchanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	StoreToAddress(adr_addacc + view_as<Address>(offset_cmp_max), mp_maxmoney.IntValue, NumberType_Int32);
	StoreToAddress(adr_addacc + view_as<Address>(offset_set_max), mp_maxmoney.IntValue, NumberType_Int32);
	StoreToAddress(adr_reset, -mp_maxmoney.IntValue, NumberType_Int32);
}