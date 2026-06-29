#include <sourcemod>

new Handle:g_Menu;

public OnPluginStart()
{
	g_Menu = CreateMenu(Select_Menu);
	SetMenuTitle(g_Menu,"Music Kit:\n \n");
	AddMenuItem(g_Menu, "sm_music 1",	"Стандартная");
	AddMenuItem(g_Menu, "sm_music 3",	"Crimsion Assault");
	AddMenuItem(g_Menu, "sm_music 4",	"Noisia | Sharpened");
	AddMenuItem(g_Menu, "sm_music 5",	"Robert | Insurgency");
	AddMenuItem(g_Menu, "sm_music 6",	"Sean Murray | A*D*B");
	AddMenuItem(g_Menu, "sm_music 7",	"Feed Me | High Noon");
	AddMenuItem(g_Menu, "sm_music 8",	"Dren | Death's Head Demolition");
	AddMenuItem(g_Menu, "sm_music 9",	"Austin | Desert Fire");
	AddMenuItem(g_Menu, "sm_music 10",	"Sasha | LNDE");
	AddMenuItem(g_Menu, "sm_music 11",	"Skog | Metal");
	AddMenuItem(g_Menu, "sm_music 12",  "Midnight Riders | All I Want For Christmas");
	AddMenuItem(g_Menu, "sm_music 13",  "Matt Lange | IsoRhythm");
	AddMenuItem(g_Menu, "sm_music 14",  "Mateo Messina | For No Mankind");
	AddMenuItem(g_Menu, "sm_music 15",  "Hotline Miami | Various Artists");
	AddMenuItem(g_Menu, "sm_music 16",  "Total Domination | Daniel Sadowski");
	AddMenuItem(g_Menu, "sm_music 17",  "Damjan Mravunac | The Talos Principle");
	RegConsoleCmd("sm_musicmenu", test);
	RegConsoleCmd("sm_mm", test);
}

public Action:test(client, args)
{

	if (0 < client <= MaxClients)
	{
		DisplayMenu(g_Menu, client, 0);
		ClientCommand(client, "playgamesound sound/buttons/button3.wav");
	}
	return Plugin_Handled;
}

public Select_Menu(Handle:menu, MenuAction:action, client, item) 
{ 

	if (action != MenuAction_Select)
		return;

	decl String:cmd[50];
	if (!GetMenuItem(menu, item, cmd, 50))
		return;
	FakeClientCommand(client, cmd);
}