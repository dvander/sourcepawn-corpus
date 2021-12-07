#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Press Button",
	author = "",
	description = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_button", Command_button, "Press Button");
}

public Action Command_button(int client, int args)
{
	new i = -1;
	while ((i = FindEntityByClassname(i, "func_button")) != -1)
	{
		decl String:strName[50];
		GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName));
		
		if(strcmp(strName, "button_1") == 0)
		{
			AcceptEntityInput(i, "Use");
		}
	}
}