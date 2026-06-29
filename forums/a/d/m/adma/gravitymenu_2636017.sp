#include <sourcemod>

ConVar g_veryLowGravity,
g_lowGravity, 
g_normalGravity, 
g_highGravity, 
g_veryHighGravity;

public Plugin myinfo = {
  name = "Gravity Menu",
  author = "adma",
  description = "",
  version = "1.0",
  url = ""
};

public void OnPluginStart() {
  RegConsoleCmd("sm_gm", sm_gm, "Open gravity menu");
  g_veryLowGravity = CreateConVar("gm_verylow", "0.2", "", _, true, 0.0);
  g_lowGravity = CreateConVar("gm_low", "0.5", "", _, true, 0.0);
  g_normalGravity = CreateConVar("gm_normal", "1.0", "", _, true, 0.0);
  g_highGravity = CreateConVar("gm_high", "2.0", "", _, true, 0.0);
  g_veryHighGravity = CreateConVar("gm_veryhigh", "5.0", "", _, true, 0.0);
}

public Action sm_gm(int client, int args) {
  if (client <= 0 || !IsClientInGame(client)) return Plugin_Handled;
  Menu menu = new Menu(GMHandler, MENU_ACTIONS_ALL);
  menu.SetTitle("Gravity Menu");
  menu.AddItem("1", "Very Low");
  menu.AddItem("2", "Low");
  menu.AddItem("3", "Normal");
  menu.AddItem("4", "High");
  menu.AddItem("5", "Very High");
  menu.Display(client, MENU_TIME_FOREVER);
  return Plugin_Handled;
}

public int GMHandler(Menu menu, MenuAction action, int param1, int param2) {
  switch (action) {
    case MenuAction_End: delete menu;
    case MenuAction_Select: {
      char info[2]; menu.GetItem(param2, info, sizeof(info));
      int selection = StringToInt(info);
      switch (selection) {
        case 1: SetEntityGravity(param1, g_veryLowGravity.FloatValue);
        case 2: SetEntityGravity(param1, g_lowGravity.FloatValue);
        case 3: SetEntityGravity(param1, g_normalGravity.FloatValue);
        case 4: SetEntityGravity(param1, g_highGravity.FloatValue);
        case 5: SetEntityGravity(param1, g_veryHighGravity.FloatValue);
      }
    }
  }

  return 0;
}

