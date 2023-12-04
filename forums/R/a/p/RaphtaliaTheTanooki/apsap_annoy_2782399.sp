#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.3"

public Plugin myinfo = 
{
	name = "[TF2] Ap-Sap Exploit Recover",
	author = "Peanut",
	description = "Makes Ap-Sap speak crap again",
	version = PLUGIN_VERSION,
	url = "https://discord.gg/7sRn8Bt"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion g_engineversion = GetEngineVersion();
	if (g_engineversion != Engine_TF2)
	{
		SetFailState("This plugin was made for use with Team Fortress 2 only.");
	}
} 

public void OnPluginStart()
{
	AddCommandListener(CommandListener_Build, "build");
}

public void OnMapStart()
{
	PrecacheScriptSound("PSap.HackedLoud");
}


Action CommandListener_Build(int client, const char[] command, int argc) 
{
	//PrintToChatAll("Listener do build sendo chamado");
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEntity(weapon)) {
		int defindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if(defindex == 933) {
		 	EmitGameSoundToAll("PSap.HackedLoud", client);	
		 	}
	}
	return Plugin_Continue;
}