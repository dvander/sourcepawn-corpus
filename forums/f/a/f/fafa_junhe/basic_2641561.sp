#include <sourcemod>
#include <clientprefs>
#include <morecolors>
#include <sdktools_functions>
#include <sdktools>
#include <cstrike>
Handle g_htpswitch;
Handle g_htpa;
Handle g_htpahere;
EngineVersion g_EngineVersion;
public Plugin myinfo =
{
	name = "Basic Plugin",
	author = "fafa_junhe",
	description = "Basic Command",
	version = "1.0",
	url = "http://www.jymc.top"
};
public void OnPluginStart()
{
	LoadTranslations("core.phrases");
	LoadTranslations("basic.phrases");
	g_EngineVersion = GetEngineVersion();
	g_htpswitch = RegClientCookie("basic_tpswitch", "tpswitch", CookieAccess_Protected);
	g_htpa = RegClientCookie("basic_tpa", "tp", CookieAccess_Protected);
	g_htpahere = RegClientCookie("basic_tpahere", "tp", CookieAccess_Protected);
	RegAdminCmd("sm_tp",Command_teleport,ADMFLAG_BAN,"强制tp玩家");
	RegAdminCmd("sm_teleport",Command_teleport,ADMFLAG_BAN,"强制tp玩家");
	RegAdminCmd("sm_tphere",Command_teleporthere,ADMFLAG_BAN,"强制tp玩家");
	RegConsoleCmd("sm_tpahere",Command_teleportahere,"强制tp玩家");
	RegConsoleCmd("sm_tpa",Command_teleporta,"tp需要同意");
	RegConsoleCmd("sm_tpyes",Command_teleportyes,"tp同意");
	RegConsoleCmd("sm_tpaccept",Command_teleportyes,"tp同意");
	RegConsoleCmd("sm_tpdeny",Command_teleportno,"tp不同意");
	RegConsoleCmd("sm_tpnoforever",Command_teleportforeverno,"tp永远不同意");
	RegConsoleCmd("sm_tpno",Command_teleportno,"tp不同意");
	RegConsoleCmd("sm_spawn",Command_spawn,"返回出生点");
	RegConsoleCmd("sm_gospawn",Command_spawn,"返回出生点");
}
public Action Command_teleport (int client, int args)
{
char arg[32];
GetCmdArg(1,arg,sizeof(arg));
if (strcmp (arg,"") == 0)
{
show_Panel(client,5,1);
return Plugin_Handled;
}
int target = FindTarget(client,arg,true);
if(target == -1)
{
CPrintToChat(client,"%T","notonline",client,"prefix");
return Plugin_Handled;
}
tp2(client,target,1,true);
return Plugin_Handled;
}
public Action Command_teleporthere (int client, int args)
{
char arg[32];
GetCmdArg(1,arg,sizeof(arg));
if (strcmp (arg,"") == 0)
{
show_Panel(client,6,1);
return Plugin_Handled;
}
int target = FindTarget(client,arg,true);
if(target == -1)
{
CPrintToChat(client,"%T","notonline",client,"prefix");
return Plugin_Handled;
}
tp2(client,target,2,true);
return Plugin_Handled;
}
public Action Command_teleporta (int client, int args)
{
char arg[32];
GetCmdArg(1,arg,sizeof(arg));
if (strcmp (arg,"") == 0)
{
show_Panel(client,1,1);
return Plugin_Handled;
}
int target = FindTarget(client,arg,true);
if(target == -1)
{
CPrintToChat(client,"%T","notonline",client,"prefix");
return Plugin_Handled;
}
tp(client,target,1);
return Plugin_Handled;
}
public Action Command_teleportahere (int client, int args)
{
char arg[32];
GetCmdArg(1,arg,sizeof(arg));
if (strcmp (arg,"") == 0)
{
show_Panel(client,2,1);
return Plugin_Handled;
}
int target = FindTarget(client,arg,true);
if(target == -1)
{
CPrintToChat(client,"%T","notonline",client,"prefix");
return Plugin_Handled;
}
tp(client,target,2);
return Plugin_Handled;
}
public Action Command_teleportno (int client, int args)
{
int i = 0;
bool a = false;
while (i != (MaxClients))
{
char buffer3[3];
char buffer4[3];
char buffer5[32];
i++;
GetClientCookie(i,g_htpa,buffer3,sizeof(buffer3));
GetClientCookie(i,g_htpahere,buffer4,sizeof(buffer4));
if(StringToInt(buffer3,10) == client)
{
SetClientCookie(i,g_htpa,"0");
Format(buffer5,sizeof(buffer5),"%N",i)
CPrintToChat(client,"%T","refuse1",client,buffer5,"prefix");
Format(buffer5,sizeof(buffer5),"%N",client)
CPrintToChat(i,"%T","refuse2",i,buffer5,"prefix");
a = true;
}
if(StringToInt(buffer4,10) == client)
{
SetClientCookie(i,g_htpahere,"0");
Format(buffer5,sizeof(buffer5),"%N",i)
CPrintToChat(client,"%T","refuse1",client,buffer5,"prefix");
Format(buffer5,sizeof(buffer5),"%N",client)
CPrintToChat(i,"%T","refuse2",i,buffer5,"prefix");
a = true;
}
}
if(a != true)
{
CPrintToChat(client,"%T","nobody",client,"prefix");
return Plugin_Handled;
}
return Plugin_Handled;
}
public Action Command_teleportyes (int client, int args)
{
int i = 0;
bool a = false;
while (i != (MaxClients))
{
char buffer3[3];
char buffer4[3];
i++;
GetClientCookie(i,g_htpa,buffer3,sizeof(buffer3));
GetClientCookie(i,g_htpahere,buffer4,sizeof(buffer4));
if(StringToInt(buffer3,10) == client)
{
tp2(i,client,1,false)
a = true;
}
if(StringToInt(buffer4,10) == client)
{
tp2(client,i,2,false)
a = true;
}
}
if(a != true)
{
CPrintToChat(client,"%T","nobody",client,"prefix");
return Plugin_Handled;
}
return Plugin_Handled;
}
public Action Command_teleportforeverno (int client, int args)
{
char buffer[32];
GetClientCookie(client,g_htpswitch,buffer,sizeof(buffer))
if(strcmp(buffer,"0") == 0 )
{
SetClientCookie(client,g_htpswitch,"1");
CPrintToChat(client,"%T","switch1",client,"prefix");
return Plugin_Handled;
}
if(strcmp(buffer,"0") != 0 )
{
SetClientCookie(client,g_htpswitch,"0");
CPrintToChat(client,"%T","switch2",client,"prefix");
return Plugin_Handled;
}
return Plugin_Handled;
}
public Action Command_spawn (int client, int args)
{
if(g_EngineVersion == Engine_TF2)
{
//TF2_RespawnPlayer(client);
CPrintToChat(client,"Wrong Game");//如果使用其他游戏请注释掉这行并移除上行的注释
}
else
{
CS_RespawnPlayer(client);
}
CPrintToChat(client,"%T","spawn",client,"prefix");
return Plugin_Handled;
}
public int MenuHandler3(Menu menu3, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu3.GetItem(param2, info, sizeof(info));
		PrintToServer("1");
		if(strcmp(info,"yes") == 0)
		{
		FakeClientCommand(param1,"say !tpyes");
		}
		else
		{
		FakeClientCommand(param1,"say !tpno");
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu3;
	}
}
public int MenuHandler4(Menu menu4, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu4.GetItem(param2, info, sizeof(info));
		PrintToServer("2");
		if(strcmp(info,"yes") == 0)
		{
		FakeClientCommand(param1,"say !tpyes");
		}
		else
		{
		FakeClientCommand(param1,"say !tpno");
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu4;
	}
}
public int MenuHandler2(Menu menu2, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu2.GetItem(param2, info, sizeof(info));
		tp(param1,StringToInt(info),2);
	}
	else if (action == MenuAction_End)
	{
		delete menu2;
	}
}
public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		tp(param1,StringToInt(info),1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}
public int MenuHandler5(Menu menu5, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu5.GetItem(param2, info, sizeof(info));
		tp2(param1,StringToInt(info),1,true);
	}
	else if (action == MenuAction_End)
	{
		delete menu5;
	}
}
public int MenuHandler6(Menu menu6, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu6.GetItem(param2, info, sizeof(info));
		tp2(param1,StringToInt(info),2,true);
	}
	else if (action == MenuAction_End)
	{
		delete menu6;
	}
}
void show_Panel(int client,int action,int target)
{
if(action == 1)
{
	Menu menu = new Menu(MenuHandler1);
	SetMenuTitle(menu,"%t","choice1");
	int i = 0;
	char buffer[32];
	char buffer2[32];
	while(i != MaxClients)
	{
	i++;
	if (IsClientInGame(i))
	{
	Format(buffer,sizeof(buffer),"%N",i);
	IntToString(i,buffer2,sizeof(buffer2));
	AddMenuItem(menu,buffer2,buffer);
	}
	continue;
}
	SetMenuExitButton(menu,true);
	DisplayMenu(menu,client,20);
}
if(action == 2)
{
	Menu menu2 = new Menu(MenuHandler2);
	SetMenuTitle(menu2,"%t","choice2");
	int i = 0;
	char buffer[32];
	char buffer2[32];
	while(i != MaxClients)
	{
	i++;
	if (IsClientInGame(i))
	{
	Format(buffer,sizeof(buffer),"%N",i);
	IntToString(i,buffer2,sizeof(buffer2));
	AddMenuItem(menu2,buffer2,buffer);
	}
	continue;
}
	SetMenuExitButton(menu2,true);
	DisplayMenu(menu2,client,20);
}
if(action == 3)
{
if(IsFakeClient(target))
{
	FakeClientCommand(target,"say !tpyes");
}
char buffer[32];
Menu menu3 = new Menu(MenuHandler3);
Format(buffer,sizeof(buffer),"%N",client);
SetMenuTitle(menu3,"%T","choice3",target,buffer,"prefix");
Format(buffer,sizeof(buffer),"%T","yes",target);
AddMenuItem(menu3,"yes",buffer);
Format(buffer,sizeof(buffer),"%T","no",target);
AddMenuItem(menu3,"no",buffer);
SetMenuExitButton(menu3,true);
DisplayMenu(menu3,target,20);
}
if(action == 4)
{
if(IsFakeClient(target))
{
	FakeClientCommand(target,"say !tpyes");
}
char buffer[32];
Menu menu4 = new Menu(MenuHandler4);
Format(buffer,sizeof(buffer),"%N",client);
SetMenuTitle(menu4,"%T","choice3",target,buffer,"prefix");
Format(buffer,sizeof(buffer),"%T","yes",target);
AddMenuItem(menu4,"yes",buffer);
Format(buffer,sizeof(buffer),"%T","no",target);
AddMenuItem(menu4,"no",buffer);
SetMenuExitButton(menu4,true);
DisplayMenu(menu4,target,20);
}
if(action == 5)
{
	char buffer[32];
	Menu menu5 = new Menu(MenuHandler5);
	Format(buffer,sizeof(buffer),"%N",client)
	SetMenuTitle(menu5,"%T","choice1",client,"prefix");
	int i = 0;
	char buffer2[32];
	while(i != MaxClients)
	{
	i++;
	if (IsClientInGame(i))
	{
	Format(buffer,sizeof(buffer),"%N",i);
	IntToString(i,buffer2,sizeof(buffer2));
	AddMenuItem(menu5,buffer2,buffer);
	}
	continue;
}
	SetMenuExitButton(menu5,true);
	DisplayMenu(menu5,client,20);
}
if(action == 6)
{
	char buffer[32];
	Menu menu6 = new Menu(MenuHandler4);
	Format(buffer,sizeof(buffer),"%N",client)
	SetMenuTitle(menu6,"%T","choice2",client,"prefix");
	int i = 0;
	char buffer2[32];
	while(i != MaxClients)
	{
	i++;
	if (IsClientInGame(i))
	{
	Format(buffer,sizeof(buffer),"%N",i);
	IntToString(i,buffer2,sizeof(buffer2));
	AddMenuItem(menu6,buffer2,buffer);
	}
	continue;
}
	SetMenuExitButton(menu6,true);
	DisplayMenu(menu6,client,20);
}
}
void tp (int client,int target,int action)
{
char buffer[32];
GetClientCookie(target,g_htpswitch,buffer,sizeof(buffer));
if(strcmp(buffer,"0") == 0)
{
CPrintToChat(client,"%T","info6",client,"prefix");
}
else
{
if(action == 1)
{
IntToString(target,buffer,10);
SetClientCookie(client, g_htpa,buffer);
Format(buffer,sizeof(buffer),"%N",client)
CPrintToChat(target,"%T","info1",target,buffer,"prefix");
CPrintToChat(target,"%T","info2",target,"prefix",buffer);
CPrintToChat(target,"%T","info3",target,"prefix",buffer);
CPrintToChat(target,"%T","info4",target,"prefix",buffer);
show_Panel(client,3,target);
}
if(action == 2)
{
IntToString(target,buffer,10);
SetClientCookie(client, g_htpahere,buffer);
CPrintToChat(target,"%T","info5",target,buffer,"prefix");
CPrintToChat(target,"%T","info2",target,"prefix",buffer);
CPrintToChat(target,"%T","info3",target,"prefix",buffer);
CPrintToChat(target,"%T","info4",target,"prefix",buffer);
show_Panel(client,4,target);
}
}
}
void tp2 (int client,int target,int action,bool forced)
{
if(action == 1)
{
float vec[3];
GetClientAbsOrigin(target, vec);
vec[2] = vec[2] + 200.0;
TeleportEntity(client,vec,NULL_VECTOR,NULL_VECTOR);
char buffer[32];
Format(buffer,sizeof(buffer),"%N",client)
char buffer2[32];
Format(buffer2,sizeof(buffer2),"%N",target)
CPrintToChat(target,"%T","teleport1",target,buffer,"prefix");
CPrintToChat(client,"%T","teleport2",client,buffer2,"prefix");
if(forced == false)
{
SetClientCookie(target,g_htpa,"0");
}
}
if(action == 2)
{
float vec[3];
GetClientAbsOrigin(target, vec);
vec[2] = vec[2] + 100.0;
TeleportEntity(client,vec,NULL_VECTOR,NULL_VECTOR);
char buffer[32];
Format(buffer,sizeof(buffer),"%N",client)
char buffer2[32];
Format(buffer2,sizeof(buffer2),"%N",target)
CPrintToChat(target,"%T","teleport1",target,buffer,"prefix");
CPrintToChat(client,"%T","teleport2",client,buffer2,"prefix");
if(forced == false)
{
SetClientCookie(target,g_htpahere,"0");
}
}
}