#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Plug-in reloader",
	author = "JakeSmokie",
	description = "Reloads plugins every map change",
	version = "1.0",
	url = "http://ezplay.pro/"
};

public void OnPluginStart()
{
	
}

public void OnPluginEnd()
{
	
}

public void OnMapEnd()
{
	char sPluginName[64];
	
	char sPath[512];
	BuildPath(Path_SM, sPath, 511, "configs/plugins_reload.txt");
		
	File f = OpenFile(sPath, "rt");
	
	if (!f)
		return;
	
	while (!f.EndOfFile())
	{
		if (!f.ReadLine(sPluginName, 63))
			break;
			
		ReplaceString(sPluginName, 63, "\n", "");
		
		ServerCommand("sm plugins reload %s", sPluginName);
		LogMessage("Reloaded %s", sPluginName);
	}
	
	f.Close();
}