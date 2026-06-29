#include <sourcemod>

public Plugin myinfo = {
  name = "Random Starting Map",
  author = "Codefined / Popey",
  description = "Random Starting Map",
  version = "1.0.0",
  url = "https://femto.pw"
};

ArrayList maps;
int serial = -1;

public OnPluginStart() {
  maps = new ArrayList(512, 0);
  ChangeToRandomMap();
}

public void ChangeToRandomMap() {
  if (ReadMapList(maps, serial) == null || serial == -1 || maps == INVALID_HANDLE) {
    LogMessage("Random Map failed to load a map list. Serial: %i", serial);
    return;
  }

  char map[256];
  int random = GetRandomInt(0, maps.Length - 1);

  maps.GetString(random, map, sizeof(map));

  LogMessage("Changed map to %s", map);
  ServerCommand("sm_map %s", map);
}