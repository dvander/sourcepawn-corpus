// Advanced AdminMenu v1.0.0 by [FG] Silent

// Cvars
new Handle:cvar_gravity = INVALID_HANDLE;
new Handle:cvar_alltalk = INVALID_HANDLE;
new Handle:cvar_criticals = INVALID_HANDLE;
new Handle:cvar_friendlyfire = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2]CvarMenu",
	author = "[FG] Silent",
	description = "All of clients can be targetted at once with this plugin",
	version = "1.0.0",
	url = "www.finalgaming.co.uk",
}

public OnPluginStart()
{
	RegAdminCmd("sm_menu", Display_Menu, ADMFLAG_KICK, "admin cmd for menu");

	cvar_gravity = FindConVar("sv_gravity");
	cvar_alltalk = FindConVar("sv_alltalk");
	cvar_criticals = FindConVar("tf_weapon_criticals");
	cvar_friendlyfire = FindConVar("mp_friendlyfire");
}

public Action:Display_Menu(client, args)
{
	new Handle:menu = CreateMenu(MenuHandle);
	SetMenuTitle(menu, "Cvar Menu:");

	new gravity = GetConVarInt(cvar_gravity)
	if(gravity == 800)
	{
		AddMenuItem(menu, "gravityoff", "Gravity: OFF");
	}
	else
	{
		AddMenuItem(menu, "gravityon", "Gravity: ON");
	}

	new alltalk = GetConVarInt(cvar_alltalk);
	if(alltalk == 0)
	{
		AddMenuItem(menu, "alltalkoff", "Alltalk: OFF");
	}
	else
	{
		AddMenuItem(menu, "alltalkon", "Alltalk: ON");
	}

	new criticals = GetConVarInt(cvar_criticals);
	if(criticals == 0)
	{
		AddMenuItem(menu, "criticalsoff", "Criticals: OFF");
	}
	else
	{
		AddMenuItem(menu,	"criticalson", "Criticals: ON");
	}

	new friendlyfire = GetConVarInt(cvar_friendlyfire);
	if(friendlyfire == 0)
	{
		AddMenuItem(menu, "friendlyfireoff", "Friendlyfire: OFF");
	}
	else
	{
		AddMenuItem(menu, "friendlyfireon", "Friendlyfire: ON");
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public MenuHandle(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new client = param1;
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}

	if(param2 == 0)
	{
		PerformGravity();
	}
	else if(param2 == 1)
	{
		PerformAlltalk();
	}
	else if(param2 == 2)
	{
		PerformCriticals();
	}
	else if(param2 == 3)
	{
		PerformFriendlyfire();
	}
}

public PerformGravity()
{
	new gravity = GetConVarInt(cvar_gravity)

	if(gravity == 800)
	{
		SetConVarInt(cvar_gravity, 550);
	}
	else
	{
		SetConVarInt(cvar_gravity, 800);
	}
}

public PerformAlltalk()
{
	new alltalk = GetConVarInt(cvar_alltalk)

	if(alltalk == 0)
	{
		SetConVarInt(cvar_alltalk, 1);
	}
	else
	{
		SetConVarInt(cvar_alltalk, 0);
	}
}

public PerformCriticals()
{
	new criticals = GetConVarInt(cvar_criticals);

	if(criticals == 0)
	{
		SetConVarInt(cvar_criticals, 1);
	}
	else
	{
		SetConVarInt(cvar_criticals, 0);
	}
}

public PerformFriendlyfire()
{
	new friendlyfire = GetConVarInt(cvar_friendlyfire);

	if(friendlyfire == 0)
	{
		SetConVarInt(cvar_friendlyfire, 1);
	}
	else
	{
		SetConVarInt(cvar_friendlyfire, 0);
	}
}
