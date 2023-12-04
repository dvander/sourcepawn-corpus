
#include <dhooks>


Handle hListidDetour;
Handle hgetuseridstring;

public void OnPluginStart()
{
	Handle hGameData = LoadGameConfigFile("ListId.test");
	if (!hGameData)
	{
		SetFailState("Failed to load test gamedata.");
		return;
	}


	hListidDetour = DHookCreateFromConf(hGameData, "Listid");
	if (!hListidDetour)
		SetFailState("Failed to setup detour for Listid");

	hgetuseridstring = DHookCreateFromConf(hGameData, "getuseridstring");
	if (!hgetuseridstring)
		SetFailState("Failed to setup detour for getuseridstring");

	delete hGameData;



	if (!DHookEnableDetour(hListidDetour, false, Detour_Listid_Pre))
		SetFailState("Failed to detour Detour_Listid_Pre.");

	if (!DHookEnableDetour(hListidDetour, true, Detour_Listid_Post))
		SetFailState("Failed to detour Detour_Listid_Post.");


	if (!DHookEnableDetour(hgetuseridstring, true, Detour_getuseridstring_Post))
		SetFailState("Failed to detour Detour_getuseridstring_Post.");
}

bool IsListId;

public MRESReturn Detour_Listid_Pre(Address pThis)
{
	IsListId = true;
	//PrintToServer("\nDetour_Listid_Pre %X", pThis);

	return MRES_Ignored;
}

public MRESReturn Detour_Listid_Post(Address pThis)
{
	IsListId = false;
	//PrintToServer("\nDetour_Listid_Post %X", pThis);

	return MRES_Ignored;
}

// Look values from given addresses only when listid command is executed
public MRESReturn Detour_getuseridstring_Post(Address pThis, DHookReturn hReturn, DHookParam hParams)
{
	if(!IsListId || pThis == Address_Null)
		return MRES_Ignored;

	//PrintToServer("\nDetour_getuseridstring_Post %X", pThis);

	char buffer[30];
	hReturn.GetString(buffer, sizeof(buffer));
	PrintToServer("\n - steamid %s", buffer);

	float banEndTime = LoadFromAddress(pThis+view_as<Address>(12), NumberType_Int32);
	banEndTime -= GetEngineTime();

	float banTime = LoadFromAddress(pThis+view_as<Address>(16), NumberType_Int32);

	PrintToServer(" - banTime %f", banTime);
	PrintToServer(" - banEndTime %f", banEndTime);
	PrintToServer(" - index %d", hParams.Get(1));
	
	return MRES_Ignored;
}



