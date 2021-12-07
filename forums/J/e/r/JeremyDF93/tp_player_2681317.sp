#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public void OnPluginStart() {
  LoadTranslations("common.phrases");

  RegConsoleCmd("sm_tp2", ConCmd_Teleport);
}

public Action ConCmd_Teleport(int client, int args) {
  if (IsValidClient(client)) {
    Menu_DisplayTeleport(client);
  }

  return Plugin_Handled;
}

void Menu_DisplayTeleport(int client) {
  Menu menu = new Menu(Menu_HandleTeleport);
  menu.SetTitle("選擇傳送玩家");

  int clients = AddTeamToMenu(menu, client);
  if (clients == 0) {
    PrintToChat(client, "%t", "No matching clients");
    delete menu;
    return;
  }

  menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_HandleTeleport(Menu menu, MenuAction action, int client, int item) {
  if (action == MenuAction_Select) {
    char info[32];
    menu.GetItem(item, info, sizeof(info));
    int target = GetClientOfUserId(StringToInt(info));

    if (!IsValidClient(target)) {
      PrintToChat(client, "%t", "Player no longer available");
    } else {
      Menu_DisplayConfirm(target, client);
    }
  }
}

void Menu_DisplayConfirm(int client, int origin) {
  Menu menu = new Menu(Menu_HandleConfirm);
  menu.SetTitle("是否接受玩家的傳送");

  char origin_id[12];
  IntToString(GetClientUserId(origin), origin_id, sizeof(origin_id));
  menu.AddItem(origin_id, "Yes");
  menu.AddItem(origin_id, "No");

  menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_HandleConfirm(Menu menu, MenuAction action, int client, int item) {
  if (action == MenuAction_Select) {
    char origin_id[32];
    menu.GetItem(item, origin_id, sizeof(origin_id));
    int origin = GetClientOfUserId(StringToInt(origin_id));

    if (!IsValidClient(origin)) return;
    if (!IsValidClient(client)) return;

    if (item == 0) { // 0 = Yes, 1 = No
      float origin_pos[3], client_pos[3];
      GetClientAbsOrigin(origin, origin_pos);
      client_pos[0] = origin_pos[0];
      client_pos[1] = origin_pos[1];
      client_pos[2] = (origin_pos[2] + 73);

      TeleportEntity(client, client_pos, NULL_VECTOR, NULL_VECTOR);
      PrintToChat(origin, "玩家 %N 傳送成功", client);
    } else {
      PrintToChat(origin ,"玩家 %N 拒絕你的傳送要求", client);
    }
  }
}

stock bool IsValidClient(int client) {
  if (client <= 0 || client > MaxClients) return false;
  if (!IsClientInGame(client)) return false;

  return true;
}

stock int AddTeamToMenu(Menu menu, int client) {
  int num_clients;
  char user_id[12], name[MAX_NAME_LENGTH];

  for (int i = 1; i <= MaxClients; i++) {
    if (i == client) continue;
    if (!IsValidClient(i)) continue;
    if (!IsPlayerAlive(i)) continue;
    if (IsFakeClient(i)) continue;
    if (GetClientTeam(i) != GetClientTeam(client)) continue;

    IntToString(GetClientUserId(i), user_id, sizeof(user_id));
    GetClientName(i, name, sizeof(name));
    menu.AddItem(user_id, name);

    num_clients++;
  }

  return num_clients;
}
