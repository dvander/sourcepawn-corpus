#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <clientprefs>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required

Handle g_hCookie;
ConVar g_cvarMaxClassBan;

int ChosedTarget[64];
int bitClassBanned[64];

int ClassBits[9] = 
{
	(1 << 0), //1
	(1 << 1), //2
	(1 << 2), //4
	(1 << 3), //8
	(1 << 4), //16
	(1 << 5), //32
	(1 << 6), //64
	(1 << 7), //128
	(1 << 8)  //256
}

char ClassNames[9][64] = 
{
	"scout",
	"soldier",
	"pyro",
	"demoman",
	"heavy",
	"engineer",
	"medic",
	"sniper",
	"spy"
}

char ClassSounds[10][64] =
{
	"",
	"vo/scout_no03.wav",
	"vo/sniper_no04.wav",
	"vo/soldier_no01.wav",
	"vo/demoman_no03.wav",
	"vo/medic_no03.wav",
	"vo/heavy_no02.wav",
	"vo/pyro_no01.wav",
	"vo/spy_no02.wav",
	"vo/engineer_no03.wav"
}

int EventToBit[10] = 
{
	0,
	1,
	128,
	2,
	8,
	64,
	16,
	4,
	256,
	32
}

public Plugin myinfo =
{
	name = "ClassBan Plugin",
	author = "Facksy",
	description = "Ban players from using some classes",
	version = "1",
	url = "http://steamcommunity.com/id/iamfacksy"
};

public void OnPluginStart()
{
	g_cvarMaxClassBan = CreateConVar("sm_maxclassban", "4", "Max classban per player");
	g_hCookie = RegClientCookie("sm_clientclassban", "", CookieAccess_Private);
	RegAdminCmd("sm_classban", sm_classban, ADMFLAG_SLAY);
	RegAdminCmd("sm_banclass", sm_classban, ADMFLAG_SLAY);
	HookEvent("player_changeclass", Event_PlayerClass);
	LoadTranslations("common.phrases");
}

public void OnMapStart()
{
	for(int i = 1; i <= 9; i++) PrecacheSound(ClassSounds[i]);
}

public void Event_PlayerClass(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid")), iClass = GetEventInt(event, "class"), iTeam = GetClientTeam(client);
	
	if(EventToBit[iClass] & bitClassBanned[client])
	{
		ShowVGUIPanel(client, iTeam == 3 ? "class_blue" : "class_red");			//Thanks DJ Tsunami
		EmitSoundToClient(client, ClassSounds[iClass]);
		TF2_SetPlayerClass(client, TFClass_Unknown);
	}
}

public void OnClientPutInServer(int client)
{
	char cookie[64];
	GetClientCookie(client, g_hCookie, cookie, 64);
	bitClassBanned[client] = StringToInt(cookie);
}

public Action sm_classban(int client, int args)
{
	ChosedTarget[client] = -1;
	if(args == 0)
	{
		if(client == 0)
		{
			PrintToServer("[SM] Command can be used only in game without args");
			return Plugin_Handled;
		}
		
		DisplayAllTargetMenu(client);
	}
	if(args == 1)
	{
		char arg1[64];
		GetCmdArg(1, arg1, 64);
		int target = FindTarget(client, arg1);
		if(target != -1)
		{
			ChosedTarget[client] = target;
			DisplayChosedTargetMenu(client, 0);
		}
	}
	if(args == 2)
	{
		char arg1[64];
		char arg2[64];
		GetCmdArg(1, arg1, 64);
		GetCmdArg(2, arg2, 64);
		int target = FindTarget(client, arg1);
		if(target != -1)
		{
			for(int i = 0; i <= 8; i++)
			{
				if(StrEqual(arg2, ClassNames[i], false))
				{
					AttemptClassBan(client, target, i);
					return Plugin_Handled;
				}
			}
			PrintToChatAll("[SM] Not valid classname");
		}
	}
	return Plugin_Handled;
}

void DisplayAllTargetMenu(int client)
{
	Menu menu = CreateMenu(Menu_Handler);
	menu.SetTitle("All Online Players");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i)) continue;
		char name[64], id[64];
		GetClientName(i, name, 64);
		int userid = GetClientUserId(i);
		Format(name, 64, "%s(%i)", name, userid);
		Format(id, 64, "%i", userid);
		menu.AddItem(id, name);
	}
	menu.Display(client, 0);
}

int Menu_Handler(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_End)
	{
		delete menu;
	}
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param2, info, sizeof(info));
		int target = GetClientOfUserId(StringToInt(info));
		if(!IsValidClient(target))
		{
			if(IsValidClient(client)) PrintToChat(client, "[SM] Target is no more valid");
			return -1;
		}
		ChosedTarget[client] = target;
		DisplayChosedTargetMenu(client, 0);
	}
	return 1;
}

void DisplayChosedTargetMenu(int client, int page)
{
	Menu menu = CreateMenu(Menu_Handler2);
	char item[64];
	Format(item, 64, "All Banned Class for %N", ChosedTarget[client])
	menu.SetTitle(item);
	Format(item, 64, "[%s]Banned from: Scout", HasBit(ChosedTarget[client], 1) ? "X" : "")
	menu.AddItem("1", item);
	Format(item, 64, "[%s]Banned from: Soldier", HasBit(ChosedTarget[client], 2) ? "X" : "")
	menu.AddItem("2", item);
	Format(item, 64, "[%s]Banned from: Pyro", HasBit(ChosedTarget[client], 4) ? "X" : "")
	menu.AddItem("4", item);
	Format(item, 64, "[%s]Banned from: Demoman", HasBit(ChosedTarget[client], 8) ? "X" : "")
	menu.AddItem("8", item);
	Format(item, 64, "[%s]Banned from: Heavy", HasBit(ChosedTarget[client], 16) ? "X" : "")
	menu.AddItem("16", item);
	Format(item, 64, "[%s]Banned from: Engineer", HasBit(ChosedTarget[client], 32) ? "X" : "")
	menu.AddItem("32", item);
	Format(item, 64, "[%s]Banned from: Medic", HasBit(ChosedTarget[client], 64) ? "X" : "")
	menu.AddItem("64", item);
	Format(item, 64, "[%s]Banned from: Sniper", HasBit(ChosedTarget[client], 128) ? "X" : "")
	menu.AddItem("128", item);
	Format(item, 64, "[%s]Banned from: Spy", HasBit(ChosedTarget[client], 256) ? "X" : "")
	menu.AddItem("256", item);
	menu.DisplayAt(client, page, 0);
}

int Menu_Handler2(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_End)
	{
		delete menu;
	}
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param2, info, sizeof(info));
		if(!IsValidClient(ChosedTarget[client]))
		{
			if(IsValidClient(client)) PrintToChat(client, "[SM] Target no longer valid");
			CloseHandle(menu);
			return -1;
		}
		if(HasBit(ChosedTarget[client], StringToInt(info)))
		{
			bitClassBanned[ChosedTarget[client]] &= ~StringToInt(info);
			Format(info, 64, "%i", bitClassBanned[ChosedTarget[client]]);
			SetClientCookie(client, g_hCookie, info);
		}
		else
		{
			if(CanBeClassBanned(ChosedTarget[client])) 
			{
				bitClassBanned[ChosedTarget[client]] |= StringToInt(info);
				Format(info, 64, "%i", bitClassBanned[ChosedTarget[client]]);
				SetClientCookie(client, g_hCookie, info);
			}
			else if(IsValidClient(client)) PrintToChat(client, "[SM] This player is enoughly classbanned");
		}
		if(param2 >= 7) DisplayChosedTargetMenu(client, 7);
		else DisplayChosedTargetMenu(client, 0);
	}
	return 1;
}

void AttemptClassBan(int client, int target, int i)
{
	if(bitClassBanned[target] & ClassBits[i])
	{
		if(client == 0) PrintToServer("[SM] Player is already banned from this class, \"sm_classban\" to manage this player");
		else if(IsValidClient(client)) PrintToChat(client, "[SM] Player is already banned from this class, \"sm_classban\" to manage this player");
		return;
	}
	if(!CanBeClassBanned(target))
	{
		if(client == 0) PrintToServer("[SM] This player is enoughly classbanned");
		else if(IsValidClient(client)) PrintToChat(client, "[SM] This player is enoughly classbanned");
		return;
	}
	bitClassBanned[target] |= ClassBits[i];
	char info[64];
	Format(info, 64, "%i", bitClassBanned[ChosedTarget[client]]);
	SetClientCookie(client, g_hCookie, info);
	if(client == 0) PrintToServer("[SM] Successfully banned %N from the %s class", target, ClassNames[i]);
	else if(IsValidClient(client)) PrintToChat(client, "[SM] Successfully banned %N from the %s class", target, ClassNames[i]);
	return;
}

bool HasBit(int client, int bit)
{
	if(bitClassBanned[client] & bit) return true;
	return false;
}

bool CanBeClassBanned(int client)
{
	int total = 0;
	char binaryString[64];
	Format(binaryString, 64, "%b", bitClassBanned[client]);
	int len = strlen(binaryString);
	for(int i = 0; i < len; i++ )
	{
		if(binaryString[i] == '1')
		{
			total++;
		}
	}
	if(total >= g_cvarMaxClassBan.IntValue) return false;
	return true;
}

public void OnClientDisconnect(int client)
{
	ChosedTarget[client] = -1;
	bitClassBanned[client] = 0;
}

bool IsValidClient(int client)
{ 
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || IsFakeClient(client) || !IsClientInGame(client))
	{
		return false; 
	}
	return true; 
}
