#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public void OnPluginStart() {
	RegConsoleCmd("sm_vip", Command_Vip, "Displays a vip menu");
}

public Action Command_Vip(int client, int args) {
	Menu menu = new Menu(Menu_Callback);
	menu.SetTitle("VIP Menu :)");
	menu.AddItem("option1", "Gravity");
	menu.AddItem("option2", "AutoBhop");
	menu.ExitButton = true;
	menu.Display(client, 30);
	return Plugin_Handled;
}

public int Menu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action) {

		case MenuAction_Select:
		{
			char item[32];
			menu.GetItem(param2, item, sizeof(item));

			if (StrEqual(item, "Gravity")) {
				stock void SetEntityGravity(int entity, float 2.0)
			}
			else if (StrEqual(item, "AutoBhop")) {
				// do other stuff
			}
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}
}
