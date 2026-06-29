#pragma semicolon 1

#include <sourcemod>
#include <socket>

#define PLUGIN_VERSION "0.9.0"

public Plugin:myinfo = {
  name = "Steam Group Admins (HTTP Prefetch)",
  author = "Mister_Magotchi",
  description = "Reads all players from Steam Community group XML member lists (via HTTP) and adds them to the admin cache.",
  version = PLUGIN_VERSION,
  url = "http://forums.alliedmods.net/showthread.php?t=145767"
};

public OnPluginStart() {
  CreateConVar(
    "sm_stream_group_admins_http_version",
    PLUGIN_VERSION,
    "Steam Group Admins (HTTP Prefetch) Version",
    FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD
  );
}

public OnRebuildAdminCache(AdminCachePart:part) {
  if (AdminCachePart:part == AdminCache_Groups || AdminCachePart:part == AdminCache_Admins) {
    decl String:steam_group_id[10];
    decl String:admin_group_name[128];
    new Handle:kv = CreateKeyValues("steam_groups");
    decl String:config_path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, config_path, sizeof(config_path), "configs/steam-group-admins-http.txt");
    FileToKeyValues(kv, config_path);
    if (KvGotoFirstSubKey(kv)) {
      do {
        KvGetSectionName(kv, steam_group_id, sizeof(steam_group_id));
        KvGetString(kv, "admin_group_name", admin_group_name, sizeof(admin_group_name));
        new GroupId:admin_group_id;
        if (AdminCachePart:part == AdminCache_Groups) {
          decl String:flags[32];
          KvGetString(kv, "flags", flags, sizeof(flags));
          new immunity;
          immunity = KvGetNum(kv, "immunity");
          if ((admin_group_id = FindAdmGroup(admin_group_name)) == INVALID_GROUP_ID) {
            admin_group_id = CreateAdmGroup(admin_group_name);
          }
          new flags_count = strlen(flags);
          for (new i = 0; i < flags_count; i++) {
            decl AdminFlag:flag;
            if (!FindFlagByChar(flags[i], flag)) {
              continue;
            }
            SetAdmGroupAddFlag(admin_group_id, flag, true);
          }
          if (immunity) {
            SetAdmGroupImmunityLevel(admin_group_id, immunity);
          }
        }
        else if (AdminCachePart:part == AdminCache_Admins) {
          admin_group_id = FindAdmGroup(admin_group_name);
          new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
          new Handle:group_id_pack = CreateDataPack();
          WritePackCell(group_id_pack, StringToInt(steam_group_id));
          WritePackCell(group_id_pack, _:admin_group_id);
          SocketSetArg(socket, group_id_pack);
          SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "steamcommunity.com", 80);
        }
      } while (KvGotoNextKey(kv));
    }
    CloseHandle(kv);
  }
}

public OnSocketConnected(Handle:socket, any:group_id_pack) { 
  decl String:request[108];
  ResetPack(group_id_pack);
  new steam_group_id = ReadPackCell(group_id_pack);
  Format(request, sizeof(request), "GET /gid/10358279%i/memberslistxml/?xml=1 HTTP/1.1\r\nHost: steamcommunity.com\r\nConnection: close\r\n\r\n", steam_group_id + 1429521408);
  SocketSend(socket, request);
}

public OnSocketReceive(Handle:socket, String:data[], const dataSize, any:group_id_pack) {
  ResetPack(group_id_pack);
  new admin_group_id = ReadPackCell(group_id_pack);
  admin_group_id = ReadPackCell(group_id_pack);
  new id_start = StrContains(data, "<steamID64>") + 11;
  decl steam_id_64[10];
  decl String:temp_digit[2];
  new subtract[] = {7, 9, 6, 0, 2, 6, 5, 7, 2, 8};
  new carry = 0;
  decl String:steam_id_string[19];
  new steam_id;
  new auth_part;
  while (IsCharNumeric(data[id_start])) {
    for (new c = 9; c >= 0; c--) {
      strcopy(temp_digit, sizeof(temp_digit), data[id_start + c + 7]);
      steam_id_64[c] = StringToInt(temp_digit);
      if (steam_id_64[c] < subtract[c] + carry) {
        steam_id_64[c] = steam_id_64[c] - subtract[c] - carry + 10;
        carry = 1;
      }
      else {
        steam_id_64[c] = steam_id_64[c] - subtract[c] - carry;
        carry = 0;
      }
    }
    Format(steam_id_string, sizeof(
      steam_id_string),
      "%i%i%i%i%i%i%i%i%i%i",
      steam_id_64[0],
      steam_id_64[1],
      steam_id_64[2],
      steam_id_64[3],
      steam_id_64[4],
      steam_id_64[5],
      steam_id_64[6],
      steam_id_64[7],
      steam_id_64[8],
      steam_id_64[9]
    );
    steam_id = StringToInt(steam_id_string);
    auth_part = steam_id % 2;
    if (auth_part) {
      steam_id -= 1;
    }
    steam_id = steam_id / 2;
    Format(steam_id_string, sizeof(steam_id_string), "STEAM_0:%i:%i", auth_part, steam_id);
    new AdminId:admin;
    if ((admin = FindAdminByIdentity("steam", steam_id_string)) == INVALID_ADMIN_ID) {
      admin = CreateAdmin(steam_id_string);
      BindAdminIdentity(admin, "steam", steam_id_string);
    }
    AdminInheritGroup(admin, GroupId:admin_group_id);
    id_start += 42;
  }
}

public OnSocketDisconnected(Handle:socket, any:group_id_pack) {
  CloseHandle(socket);
  CloseHandle(group_id_pack);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:group_id_pack) {
  ResetPack(group_id_pack);
  new steam_group_id = ReadPackCell(group_id_pack);
  LogError("Socket error for group %i", steam_group_id);
  CloseHandle(socket);
  CloseHandle(group_id_pack);
}