/*

  (©)= = = = = = = = = = = = =(©)
  ||                           ||
  ||          S K Y            ||
  ||                           ||
  ||                           ||
  ||           ...             ||
  ||                           ||
  ||    Copyright ©  t*Q       ||
  ||  All rights reserved :D   ||
  ||           ...             ||
  ||  web site: www.hlmod.ru   ||
  ||                           ||
  (©)= = = = = = = = = = = = =(©)


*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <topmenus>
#define VERSION  "2.0"
#undef REQUIRE_PLUGIN
#include <adminmenu>

new	Handle:g_hTopMenu = INVALID_HANDLE;
new	Handle:g_CvarSky = INVALID_HANDLE;
new String:g_MenuItemName[64];
new String:g_MapName[64];
new String:StdSky[64];
new bool:g_Changed = false;
new seconds = 5;

public Plugin:myinfo = 
{
	name = "[skY]",
	author = "tale*Quale",
	description = "Change Skybox Textures on Maps",
	version = VERSION,
	url = "www.hlmod.ru"
};

public OnPluginStart()
{
  LoadTranslations("skY.phrases");
  CreateConVar("sky_version", VERSION, "[skY] Версия | [skY] Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);
  RegAdminCmd("sky", MenuMain, ADMFLAG_CONVARS, "[skY] Главное Меню | [skY]Main Menu");
  g_CvarSky = FindConVar("sv_skyname");
  GetConVarString(g_CvarSky, StdSky, sizeof(StdSky));
  
  PrintToServer("[skY] Loaded!");
}

public OnMapStart()
{
  GetCurrentMap(g_MapName, 64);
  PrecacheSound("ambient/misc/brass_bell_d.wav", true);
  GetConVarString(g_CvarSky, StdSky, sizeof(StdSky));

  new String:PathToRead[256];
  Format(PathToRead, sizeof(PathToRead), "cfg/sourcemod/skY.cfg");
  new Handle:SkyfileRead = OpenFile(PathToRead, "rt");

  decl String:buffer[512];
  decl String:AddSkyBoxes[PLATFORM_MAX_PATH];

  while(ReadFileLine(SkyfileRead, buffer, sizeof(buffer)))
  {
    TrimString(buffer);

    if((StrContains(buffer, "//") == -1) && (!StrEqual(buffer, "")))
    {
      Format(AddSkyBoxes, sizeof(AddSkyBoxes), "materials/skybox/%s", buffer);
      if(FileExists(AddSkyBoxes))
      {
        PrecacheModel(buffer, true);
        AddFileToDownloadsTable(AddSkyBoxes);
        PrintToServer("[skY] Adding textures to downloads! : %s", AddSkyBoxes);
      }
    }
  }

  if (g_Changed == true)
  {
    SetConVarString(g_CvarSky, g_MenuItemName);
  }
  else
  {
    SetConVarString(g_CvarSky, StdSky);
  }
}

public OnConfigsExecuted()
{
  new String:PathSet[256];
  Format(PathSet, sizeof(PathSet), "cfg/sourcemod/skY.cfg");
  if(!FileExists(PathSet))
  {
    PrintToServer("[skY] SkyBoxes List file does not exist [%s] autocreated...", PathSet);
    skYList(1, 1);
  }
  else if(FileExists(PathSet))
  {
    PrintToServer("[skY] SkyBoxes List file exist! [%s] reading...", PathSet);
  }
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == g_hTopMenu)
	{
		return;
	}
	g_hTopMenu = topmenu;
	new TopMenuObject:server_commands = FindTopMenuCategory (g_hTopMenu, ADMINMENU_SERVERCOMMANDS);
	AddToTopMenu(g_hTopMenu, "skY", TopMenuObject_Item, ItemSkY, server_commands, "sky", ADMFLAG_CONFIG);
}

public ItemSkY(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "TopMenuItem", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		MenuMain(param, 1);
	}
}

public Action:MenuMain(client, args) 
{
  decl String:buffer[512];
  new String:Curr[64];
  GetConVarString(g_CvarSky, Curr, 64);
  new Handle:menu = CreateMenu(MenuMainHandler);
  Format(buffer, sizeof(buffer), "[skY] %T", "MenuTitle", client, Curr);
  SetMenuTitle(menu, buffer);
  Format(buffer, sizeof(buffer), "%T", "CstrikeItem", client);
  AddMenuItem(menu, "", buffer);
  Format(buffer, sizeof(buffer), "%T", "Hl2Item", client);
  AddMenuItem(menu, "", buffer);
  Format(buffer, sizeof(buffer), "%T [%s]", "SetStdSkyItem", client, g_MapName);
  AddMenuItem(menu, "", buffer);
  SetMenuExitBackButton(menu, true);
  DisplayMenu(menu, client, MENU_TIME_FOREVER);

  return Plugin_Handled;
}

public MenuMainHandler(Handle:menu, MenuAction:action, param1, param2)
{
  if (action == MenuAction_Select)
  {
    switch(param2)
    {
      case 0:
      {
        LoadCstrikeSkyBoxesMenu(param1, 1);
      }
      case 1:
      {
        LoadHl2SkyBoxesMenu(param1, 1);
      }
      case 2:
      {
        g_Changed = false;
        PrintToChatAll("\x03[\x01SkY\x03] \x01%t [\x03%s\x01]", "ChosenSkyStd", g_MapName);
        CreateTimer(1.0, ReloadMapTimer, _, TIMER_REPEAT);
      }
    }
  }
  if (action == MenuAction_Cancel)
  {
    if (param2 == MenuCancel_ExitBack)
    {
      RedisplayAdminMenu(g_hTopMenu, param1);
    }
  }
  else if(action == MenuAction_End)
  CloseHandle(menu);
}

public Action:LoadCstrikeSkyBoxesMenu(client, args)
{
  decl String:TitleCstrike[64];
  new Handle:menu = CreateMenu(LoadCstrikeSkyBoxesMenuHandler);
  Format(TitleCstrike, sizeof(TitleCstrike), "[skY] %T", "MenuTitleCstrike", client);
  SetMenuTitle(menu, TitleCstrike);

  new Handle:SkyBoxesDir = OpenDirectory("../cstrike/materials/skybox/");
  new String:SkyName[64];
  new FileType:type;
  new Len;

  while(ReadDirEntry(SkyBoxesDir, SkyName, sizeof(SkyName), type))
  {
    if(type == FileType_File)
    {
      if(StrContains(SkyName, ".ztmp", false) == strlen(SkyName) - 5 || StrContains(SkyName, ".vtf", false) == strlen(SkyName) - 4)
      continue;

      Len = strlen(SkyName) - 4;
      if(StrContains(SkyName, ".vmt", false) == Len)
      {
        Len = Len - 2;
        if(StrContains(SkyName, "bk", false) == Len ||
           StrContains(SkyName, "dn", false) == Len ||
           StrContains(SkyName, "lf", false) == Len ||
           StrContains(SkyName, "ft", false) == Len ||
           StrContains(SkyName, "rt", false) == Len)
        continue;
        strcopy(SkyName, Len + 1, SkyName);
      }
      AddMenuItem(menu, SkyName, SkyName);
    }
  }
  SetMenuExitBackButton(menu, true);
  DisplayMenu(menu, client, MENU_TIME_FOREVER);
  CloseHandle(SkyBoxesDir);
  return Plugin_Handled;
}

public LoadCstrikeSkyBoxesMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
  if (action == MenuAction_Select)
  {
    GetMenuItem(menu, param2, g_MenuItemName, sizeof(g_MenuItemName));
    SetConVarString(g_CvarSky, g_MenuItemName);
    g_Changed = true;
    PrintToChatAll("\x03[\x01SkY\x03] \x01%t : \x03%s", "ChosenSky", g_MenuItemName);
    CreateTimer(1.0, ReloadMapTimer, _, TIMER_REPEAT);
  }
  if (action == MenuAction_Cancel)
  {
    if (param2 == MenuCancel_ExitBack)
    {
    MenuMain(param1, 0);
    }
  }

  else if(action == MenuAction_End)
  CloseHandle(menu);
}

public Action:LoadHl2SkyBoxesMenu(client, args)
{
  decl String:TitleHl2[64];
  new Handle:menu = CreateMenu(LoadHl2SkyBoxesMenuHandler);
  Format(TitleHl2, sizeof(TitleHl2), "[skY] %T", "MenuTitleHl2", client);
  SetMenuTitle(menu, TitleHl2);

  new Handle:SkyBoxesDir = OpenDirectory("../hl2/materials/skybox/");
  new String:SkyName[64];
  new FileType:type;
  new Len;

  while(ReadDirEntry(SkyBoxesDir, SkyName, sizeof(SkyName), type))
  {
    if(type == FileType_File)
    {
      //На всякий
      if(StrContains(SkyName, ".ztmp", false) == strlen(SkyName) - 5 || StrContains(SkyName, ".vtf", false) == strlen(SkyName) - 4)
      continue;

      Len = strlen(SkyName) - 4;
      if(StrContains(SkyName, ".vmt", false) == Len)
      {
        Len = Len - 2;
        if(StrContains(SkyName, "bk", false) == Len ||
           StrContains(SkyName, "dn", false) == Len ||
           StrContains(SkyName, "lf", false) == Len ||
           StrContains(SkyName, "ft", false) == Len ||
           StrContains(SkyName, "rt", false) == Len)
        continue;
        strcopy(SkyName, Len + 1, SkyName);
      }
      AddMenuItem(menu, SkyName, SkyName);
    }
  }
  SetMenuExitBackButton(menu, true);
  DisplayMenu(menu, client, MENU_TIME_FOREVER);
  CloseHandle(SkyBoxesDir);
  return Plugin_Handled;
}

public LoadHl2SkyBoxesMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
  if (action == MenuAction_Select)
  {
    GetMenuItem(menu, param2, g_MenuItemName, sizeof(g_MenuItemName));
    SetConVarString(g_CvarSky, g_MenuItemName);
    g_Changed = true;
    PrintToChatAll("\x03[\x01SkY\x03] \x01%t : \x03%s", "ChosenSky", g_MenuItemName);
    CreateTimer(1.0, ReloadMapTimer, _, TIMER_REPEAT);
  }
  if (action == MenuAction_Cancel)
  {
    if (param2 == MenuCancel_ExitBack)
    {
      MenuMain(param1, 0);
    }
  }

  else if(action == MenuAction_End)
  CloseHandle(menu);
}


public Action:ReloadMapTimer(Handle:timer)
{
  seconds--;
  PrintHintTextToAll("[skY] %t: %d", "Reload", seconds);
  EmitSoundToAll("ambient/misc/brass_bell_d.wav", SND_CHANGEVOL, 10);
  if(seconds == 0)
  {
    ForceChangeLevel(g_MapName, "[skY]...");
    seconds = 6;
    return Plugin_Stop;
  }
  return Plugin_Continue;
}

//Если skY.cfg файла нет он автоматически запишется в (...cfg/sourcemod/) после старта сервера
//IF skY.cfg file does not exist him autocreated in (...cfg/sourcemod/) on start server

public Action:skYList(client, args)
{
  new String:Path[256];
  Format(Path, sizeof(Path), "cfg/sourcemod/skY.cfg");
  new Handle:Skyfile = OpenFile(Path, "wt");

  WriteFileLine(Skyfile, "//-------------------------------\n//\n// SkyBox текстуры\n// (SkyBox Textures)\n//");
  WriteFileLine(Skyfile, "// Сдесь можно добавить свои SkyBox текстуры для закачки клиентам! всего их 12 в каждом Скайбоксе\n// (Here you can add you own SkyBox's textures which clients could download! it's a 12 files in each skybox)\n//");
  WriteFileLine(Skyfile, "// 6 это текстуры в формате *.vtf и 6 файлы описывающие их хорактеристики в формате *.vmt!\n// (6 - *.vtf  files and 6 - *.vmt files!)\n//");
  WriteFileLine(Skyfile, "// Много хороших Skybox'ов можно скачать по адресу www.fpsbanana.com!\n// (Many good textures you can download from www.fpsbanana.com)\n//");
  WriteFileLine(Skyfile, "// Добавлять текстуры нужно в папку cstrike/materials/skybox/...\n// (Just drop new textures to cstrike/materials/skybox/...)\n//");
  WriteFileLine(Skyfile, "// Не нужно забывать что текстуры скайбоксов в названии содержат ключевые буквы которые отвечают за их расположение:\n// (Tags, postfix in texture names of skybox):\n//\n// \"up\" - верхняя текстура (top texture)\n// \"dn\" - нижняя текстура (bottom texture)\n// \"lf\" - текстура с лева (left texture)\n// \"rt\" - текстура с права (right texture)\n// \"ft\" - фронтальная текстура (front texture)\n// \"bk\" - задняя текстура (back texture)\n//");
  WriteFileLine(Skyfile, "// Чтобы установить на сервере ваш добавленный skybox, нужно вызвать меню коммандой \"sky\" выбрать пункт \"Скайбоксы из папки cstrike\" найти его там и выбрать!\n// (To install on server your added skybox, it is necessary to cause the menu an command \"sky\" choose the item \"cstrike folder\" find his there and choose!)\n//\n//");
  WriteFileLine(Skyfile, "// Пример как прописывать добавленные текстуры в этом файле:\n//\n// ИмяСкайбоксаbk.vmt\n// ИмяСкайбоксаbk.vtf\n// ИмяСкайбоксаdn.vmt\n// ИмяСкайбоксаdn.vtf\n// ИмяСкайбоксаft.vmt\n// ИмяСкайбоксаft.vtf\n// ИмяСкайбоксаlf.vmt\n// ИмяСкайбоксаlf.vtf\n// ИмяСкайбоксаrt.vmt\n// ИмяСкайбоксаrt.vtf\n// ИмяСкайбоксаup.vmt\n// ИмяСкайбоксаup.vtf\n//\n//");
  WriteFileLine(Skyfile, "// (Example what write in this file):\n//\n// Skyboxnamebk.vmt\n// Skyboxnamebk.vtf\n// Skyboxnamedn.vmt\n// Skyboxnamedn.vtf\n// Skyboxnameft.vmt\n// Skyboxnameft.vtf\n// Skyboxnamelf.vmt\n// Skyboxnamelf.vtf\n// Skyboxnamert.vmt\n// Skyboxnamert.vtf\n// Skyboxnameup.vmt\n// Skyboxnameup.vtf\n//\n//-----------------------------\n");
  CloseHandle(Skyfile);
}
