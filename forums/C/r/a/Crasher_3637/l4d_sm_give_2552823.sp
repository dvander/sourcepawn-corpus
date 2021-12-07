#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define TEAM_SURVIVOR 2

new String:g_items[][] =
{
	"autoshotgun",
	"hunting_rifle", 
	"pistol",
	"pumpshotgun",
	"rifle",
	"smg",
	"first_aid_kit",
	"pain_pills",
	"pipe_bomb",
	"molotov"
};

new Handle:g_Cvar_AdminsImmune = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[L4D] sm_give",
	author = "Psykotik",
	description = "Give yourself items/weapons at round start.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("l4d_sm_give_version", PLUGIN_VERSION, "[L4D] sm_give", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_Cvar_AdminsImmune = CreateConVar("l4d_sm_give_adminsallowed", "1", "0 = Off | 1 = On -- Admins allowed to use command any time?");
	RegAdminCmd("sm_give", Cmd_SM_Give, ADMFLAG_ROOT, "sm_give [item_name] [item_name]");
	AutoExecConfig(true, "l4d_sm_give");
}	

public Action:Cmd_SM_Give(client, argCount)
{	
	if (!IsValidSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	if (L4D_HasAnySurvivorLeftSafeArea())
	{
		if (!IsAdmin(client) || IsAdmin(client) && !GetConVarBool(g_Cvar_AdminsImmune))
		{
			ReplyToCommand(client, "Command is only usable at round start (in saferoom).");
			return Plugin_Handled;
		}
	}
	
	if (argCount < 1)
	{
		DisplayGiveMenu(client);
		return Plugin_Handled;
	}

	new bool:found = false;
	new i;
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	for (new argnum = 1; argnum <= argCount; argnum++)
	{	
		decl String:arg[64], String:item[64];
		GetCmdArg(argnum, arg, sizeof(arg));
		if (found != false) found = false;
		if (StrEqual(arg, "m16", false))
		{
			strcopy(item, sizeof(item), "rifle");
			found = true;
		}

		if (StrEqual(arg, "snipe", false))
		{
			strcopy(item, sizeof(item), "hunting_rifle");
			found = true;
		}

		if (StrEqual(arg, "dual", false))
		{
			strcopy(item, sizeof(item), "pistol");
			found = true;
		}

		if (StrEqual(arg, "medkit", false))
		{
			strcopy(item, sizeof(item), "first_aid_kit");
			found = true;
		}

		if (!found)
		{
			for (i = 0; i < sizeof(g_items); i++)
			{ 
				if (StrContains(g_items[i], arg, false) != -1)
				{
					strcopy(item, sizeof(item), g_items[i]);
					found = true;
					break;
				}	 
			}
		}

		if (!found)
		{
			strcopy(item, sizeof(item), arg);		
		}	 
		FakeClientCommand(client, "give %s", item);
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	return Plugin_Handled;		
}

DisplayGiveMenu(client, time=MENU_TIME_FOREVER) 
{ 
	new Handle:menu = CreateMenu(GiveMenuHandler); 
	SetMenuTitle(menu, "Give Menu");
	AddMenuItem(menu, "1", "Items"); 
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, time);
}

DisplayItemsMenu(client, time=MENU_TIME_FOREVER) 
{ 
	new Handle:menu = CreateMenu(ItemsMenuHandler); 
	SetMenuTitle(menu, "Choose an item:");
	for (new i = 0; i < sizeof(g_items); i++)
	{ 
		AddMenuItem(menu, "", g_items[i]);
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, time);
}

public ItemsMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if (action == MenuAction_Select)
	{ 
		decl String:weapon[64];
		Format(weapon, sizeof(weapon), "weapon_%s", g_items[itemNum]);
		new entity = GivePlayerItem(client, weapon);
		if (entity != -1)
		{
			EquipPlayerWeapon(client, entity);
		}
		DisplayGiveMenu(client, 60);
	}

	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public GiveMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{ 
	if (action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0: DisplayItemsMenu(client);
		}
	}

	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
		
bool:IsAdmin(client)
{
	new AdminId:admin = GetUserAdmin(client);
	if (admin == INVALID_ADMIN_ID)
		return false;
	return true;
}

bool:IsValidSurvivor(client)
{
	if (client && IsClientInGame(client))
	{
		if (GetClientTeam(client) == TEAM_SURVIVOR)
		{
			if (IsPlayerAlive(client))
			{
				return true;
			}
		}
	}
	return false;			 
}

bool:L4D_HasAnySurvivorLeftSafeArea()
{
    new entity = FindEntityByClassname(-1, "terror_player_manager");
    if (entity == -1)
    {
            return false;
    }
    return bool:GetEntProp(entity, Prop_Send, "m_hasAnySurvivorLeftSafeArea", 1);
}