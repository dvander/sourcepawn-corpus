



#include <dhooks>

Handle test;
Handle test2;

public void OnPluginStart()
{
	GameData temp = new GameData("test.games");

	test = DHookCreateFromConf(temp, "SelectPatient_function");
	test2 = DHookCreateFromConf(temp, "CTFBotMedicHeal::IsStable_function");

	


	if (!DHookEnableDetour(test, false, SelectPatient))
		SetFailState("Failed to detour SelectPatient_function.");

	if (!DHookEnableDetour(test2, false, IsStable))
		SetFailState("Failed to detour CTFBotMedicHeal::IsStable_function.");
	
}



public MRESReturn SelectPatient(DHookReturn hReturn, DHookParam hParams)
{
	if(hParams.IsNull(1) || hParams.IsNull(2))
		return MRES_Ignored;

	int me = hParams.Get(1);
	int current = hParams.Get(2);

	if(!IsFakeClient(current))
	{
		PrintToServer("SelectPatient me %N, current %N", me, current);
		hReturn.Value = INVALID_ENT_REFERENCE;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}






public MRESReturn IsStable(DHookReturn hReturn, DHookParam hParams)
{
	if(hParams.IsNull(1))
		return MRES_Ignored;

	int patient = hParams.Get(1);

	if(!IsFakeClient(patient))
	{
		PrintToServer("IsStable %N", patient);
		hReturn.Value = true;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}







