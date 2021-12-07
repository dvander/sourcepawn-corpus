#pragma semicolon 1
#include <sourcemod>
new Handle:hC;

public OnPluginStart()
{
	hC = CreateConVar("sv_hudhint_sound", "1", "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(hC, "0");
}
