#include <sourcemod>

public OnPluginStart()
{
	new iFlags = GetCommandFlags("listdeaths");
	if(iFlags & FCVAR_GAMEDLL)
	{
		iFlags &= ~FCVAR_GAMEDLL;
		SetCommandFlags("listdeaths", iFlags);
	}
}
