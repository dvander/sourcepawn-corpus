public OnMapStart()
{
	UnlockConsoleCommandAndConvar("c_thirdpersonshoulderoffset");
	UnlockConsoleCommandAndConvar("c_thirdpersonshoulderaimdist");
	UnlockConsoleCommandAndConvar("c_thirdpersonshoulderheight");
	UnlockConsoleCommandAndConvar("c_thirdpersonshoulder");
}

UnlockConsoleCommandAndConvar(const String:command[])
{
	new flags = GetCommandFlags(command);
	if (flags != INVALID_FCVAR_FLAGS)
	{
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	}
	
	new Handle:cvar = FindConVar(command);
	if (cvar != INVALID_HANDLE)
	{
		flags = GetConVarFlags(cvar);
		SetConVarFlags(cvar, flags & ~FCVAR_CHEAT);
	}
}