#pragma semicolon 1

#include <rtd2>

public Plugin myinfo = {

	name = "RTD2 External Perk Test",
	author = "Phil25",
	description = "A tutorial plugin for applying perks via external plugins"

};

public void OnPluginStart(){
	
	//Check if registering is available in case this plugin was late-loaded and RTD had been active
	if(RTD2_IsRegOpen()){
	
		PrintToServer("Perk registering is open.");
		RegisterPerks();
	
	}else
		PrintToServer("Perk registering is closed.");

}

//RTD has loaded the core perks and fires this forward before processing sm_rtd2_disabled ConVar
public int RTD2_OnRegOpen(){

	//RTD is ready to handle external perk registration
	PrintToServer("Perk registration is now open, register your perks while you can!");

	//We should ALWAYS register perks each time this forward is fired.
	RegisterPerks();

}

void RegisterPerks(){
	
	int iId = RTD2_RegisterPerk("testperk", "Test Perk", 1, "items/bomb_warning.wav", 0, "0", "0", "this|is|a|test|perk|lets|see|how|it|works", RTD2Manager_Perk);
	PrintToServer("Registered perk to ID: %d", iId);
	
	//-----------
	
	iId = RTD2_RegisterPerk(
		"testperkinst",				//Perk token
		"Test Perk Instant",		//Perk name
		0,							//0 - bad, 1 - good
		"items/bomb_warning.wav",	//Perk sound
		-1,							//-1 - instant, 0 - convar default time, 0< custom perk time
		"1, 5, 7, 8, 9",			//Perk player class limit
		"rocketl",					//Perk player's weapons' class limit
		"what|are|the|odds",		//Perk tags
		RTD2Manager_Perk			//Perk callback function
	);
	PrintToServer("Registered perk to ID: %d", iId);
	
	//-----------

	iId = RTD2_RegisterPerk(
		"testperkcusttime",			//Perk token
		"Test Perk Custom Time",	//Perk name
		0,							//0 - bad, 1 - good
		"items/bomb_warning.wav",	//Perk sound
		20,							//-1 - instant, 0 - convar default time, 0< custom perk time
		"1, 2, 3, 4, 5, 6",			//Perk player class limit
		"rocketl, wood",			//Perk player's weapons' class limit
		"but|holy|shit|it|works",	//Perk tags
		RTD2Manager_Perk			//Perk callback function
	);
	PrintToServer("Registered perk to ID: %d", iId);
	
	//-----------

	iId = RTD2_RegisterPerk(
		"testperkdiffcallback",		//Perk token
		"Test Perk Diff Callback",	//Perk name
		0,							//0 - bad, 1 - good
		"items/bomb_warning.wav",	//Perk sound
		20,							//-1 - instant, 0 - convar default time, 0< custom perk time
		"1, 2, 3, 4, 5, 6, 7, 8",	//Perk player class limit
		"rocketl, sniper_rifle",	//Perk player's weapons' class limit
		"ehh|meh|heh|wut|lel|hah",	//Perk tags
		RTD2Manager_Perk2			//Perk callback function
	);
	PrintToServer("Registered perk to ID: %d", iId);
	
	//-----------
	//Lastly, let's override a core perk.

	iId = RTD2_RegisterPerk(
		"luckysandvich",
		"Lucky Sandvich 2",
		1,
		"vo/heavy_sandwichtaunt17.mp3",
		-1,
		"0",
		"0",
		"luckysandvich|lucky|sandvich|sandwich|health|instant|notimer|good",
		RTD2Manager_NewLuckySandvich
	);
	PrintToServer("Overriden Lucky Sandvich (ID:%d)", iId);

}

public int RTD2Manager_Perk(int client, int iPerkId, bool bEnable){

	if(bEnable)
		PrintToChatAll("Enabling perk (%d) on %N.", iPerkId, client);
	
	else
		PrintToChatAll("Disabling perk (%d) on %N.", iPerkId, client);

}

public int RTD2Manager_Perk2(int client, int iPerkId, bool bEnable){

	PrintToChatAll("This callback is different! Why? I dunno.");

	if(bEnable)
		PrintToChatAll("Enabling perk (%d) on %N.", iPerkId, client);
	
	else
		PrintToChatAll("Disabling perk (%d) on %N.", iPerkId, client);

}

public int RTD2Manager_NewLuckySandvich(int client, int iPerkId, bool bEnable){

	PrintToChatAll("New Lucky Sandvich set on %N", client);

}