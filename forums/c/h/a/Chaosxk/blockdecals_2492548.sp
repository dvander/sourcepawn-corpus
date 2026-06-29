#include <sdktools>

public void OnPluginStart()
{
	AddTempEntHook("Shotgun Shot", Hook_BlockTE);
	AddTempEntHook("Blood Sprite", Hook_BlockTE);
}

public Action Hook_BlockTE(const char[] te_name, const int[] Players, int numClients, float delay)
{
	return Plugin_Stop;
}