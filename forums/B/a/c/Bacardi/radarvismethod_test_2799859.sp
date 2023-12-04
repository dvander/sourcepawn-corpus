





public void OnPluginStart()
{
	ConVar radarvismethod = FindConVar("radarvismethod");
	
	if(radarvismethod != null)
	{
		radarvismethod.SetBounds(ConVarBound_Lower, true, -1.0);
	}
	else
	{
		SetFailState("Plugin fail to find cvar called \"radarvismethod\"");
	}
}