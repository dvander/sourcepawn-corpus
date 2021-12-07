#include <sourcemod>
#include <colorvariables>

new Handle:SelectedKnife;

Menu g_KnifeMenu = null;
Menu g_SkinMenu = null;

public Plugin:myinfo = {
	name = "Fake cases",
	author = "tommie113",
	description = "Fakes an item found in a case",
	version = "1.0",
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_fakecase", FakeCaseCMD, ADMFLAG_GENERIC);
	
	SelectedKnife = CreateArray(32);
	
	for(new i = 0; i < MAXPLAYERS; i++)
	{
		PushArrayString(SelectedKnife, "null");
	}
}

public void OnMapStart()
{
	g_KnifeMenu = BuildKnifeMenu();
	g_SkinMenu = BuildSkinMenu();
}

public void OnMapEnd()
{
	if(g_KnifeMenu != INVALID_HANDLE)
	{
		delete(g_KnifeMenu);
		g_KnifeMenu = null;
	}
	
	if(g_SkinMenu != INVALID_HANDLE)
	{
		delete(g_SkinMenu);
		g_SkinMenu = null;
	}
}

public Action FakeCaseCMD(client, int args)
{
	g_KnifeMenu.Display(client, MENU_TIME_FOREVER);
}

Menu BuildKnifeMenu()
{
	Menu menu = new Menu(Menu_Knife);
	menu.AddItem("★ Butterfly Knife | ", "★ Butterfly Knife | ");
	menu.AddItem("★ Shadow Daggers | ", "★ Shadow Daggers | ");
	menu.AddItem("★ Karambit | ", "★ Karambit | ");
	menu.AddItem("★ Falchion knife | ", "★ Falchion knife | ");
	menu.AddItem("★ M9 Bayonet | ", "★ M9 Bayonet | ");
	menu.AddItem("★ Bayonet | ", "★ Bayonet | ");
	menu.AddItem("★ Flip knife | ", "★ Flip knife | ");
	menu.AddItem("★ Gut knife | ", "★ Gut knife | ");
	menu.AddItem("★ Huntsman knife | ", "★ Huntsman knife | ");
	menu.SetTitle("Select knife:");
	return menu;
}

public int Menu_Knife(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char knife_id[32];
		menu.GetItem(param2, knife_id, sizeof(knife_id));
		
		SetArrayString(SelectedKnife, param1, knife_id);

		g_SkinMenu.Display(param1, MENU_TIME_FOREVER);
	}
}

Menu BuildSkinMenu()
{
	Menu menu = new Menu(Menu_Skin);
	menu.AddItem("Blue Steel", "Blue Steel");
	menu.AddItem("Boreal Forest", "Boreal Forest");
	menu.AddItem("Case Hardened", "Case Hardened");
	menu.AddItem("Damascus Steel", "Damascus Steel");
	menu.AddItem("Doppler", "Doppler");
	menu.AddItem("Fade", "Fade");
	menu.AddItem("Forest DDPAT", "Forest DDPAT");
	menu.AddItem("Marble Fade", "Marble Fade");
	menu.AddItem("Safari Mesh", "Safari Mesh");
	menu.AddItem("Scorched", "Scorched");
	menu.SetTitle("Select knife skin:");
	return menu;
}

public int Menu_Skin(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char skin_id[32];
		menu.GetItem(param2, skin_id, sizeof(skin_id));
		
		char knife[32];
		GetArrayString(SelectedKnife, param1, knife, sizeof(knife));
		
		char name[32];
		GetClientName(param1, name, sizeof(name));

		CPrintToChatAll("{player %d}%s{default} has opened a container and found: {red}%s%s", param1, name, knife, skin_id);
		SetArrayString(SelectedKnife, param1, "null");	
	}
}