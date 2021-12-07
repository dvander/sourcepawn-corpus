#include <sourcemod>


public OnPluginStart()
{
	new Handle:hBonus = FindConVar("mp_bonusroundtime");
	
	SetConVarBounds(hBonus, ConVarBound_Lower, false);
	SetConVarBounds(hBonus, ConVarBound_Upper, false);
	
	CloseHandle(hBonus);
}
