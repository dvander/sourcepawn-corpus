#include <tf2attributes>

new Float:DSPID[MAXPLAYERS+1] = 0.0

public Plugin:myinfo = 
{
	name = "[TF2] DSP Effects",
	author = "A.I, Hurp Durp",
	description = "Allows you to apply a DSP Effect to your class's voice",
	version ="1.1",
	url = "www.lemonparty.org"
}

public OnPluginStart()
{
	RegAdminCmd("sm_dsp", DSPFX, ADMFLAG_RESERVATION)
	RegAdminCmd("sm_voicefx", DSPFX, ADMFLAG_RESERVATION)

	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post)
	HookEvent("post_inventory_application", OnPostInventoryApplication);
}

public OnClientDisconnect(client)
{
	if(DSPID[client] > 0.0)
	{
		DSPID[client] = 0.0
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(DSPID[client] > 0.0)
	{
		TF2Attrib_SetByName(client, "SET BONUS: special dsp", DSPID[client]);
	}
}

public Action:DSPFX(client, args)
{
	new Handle:ws = CreateMenu(DSPFXCALLBACK);
	SetMenuTitle(ws, "Choose Your DSP Effect");

	AddMenuItem(ws, "0", "No Effect");
	AddMenuItem(ws, "X", "----------", ITEMDRAW_DISABLED);
	AddMenuItem(ws, "2", "Reverb #1");
	AddMenuItem(ws, "3", "Reverb #2");
	AddMenuItem(ws, "4", "Reverb #3");
	AddMenuItem(ws, "5", "Short Reverb");
	AddMenuItem(ws, "11", "Metal Reverb");
	AddMenuItem(ws, "111", "Reverb + Delay");
	AddMenuItem(ws, "20", "Delay #1");
	AddMenuItem(ws, "21", "Delay #2");
	AddMenuItem(ws, "22", "Long Delay");
	AddMenuItem(ws, "23", "Robodelay");
	AddMenuItem(ws, "24", "Distant Delay #1");
	AddMenuItem(ws, "25", "Distant Delay #2");
	AddMenuItem(ws, "130", "Cavernous Delay");
	AddMenuItem(ws, "47", "Repeater");
	AddMenuItem(ws, "44", "+10% Pitch");
	AddMenuItem(ws, "45", "-10% Pitch");
	AddMenuItem(ws, "30", "Highpass");
	AddMenuItem(ws, "126", "Bandpass");
	AddMenuItem(ws, "55", "Speaker");
	AddMenuItem(ws, "38", "Distorted Speaker");
	AddMenuItem(ws, "56", "Echo Speaker");
	AddMenuItem(ws, "112", "Chorus");
	AddMenuItem(ws, "116", "Chorusverb");
	AddMenuItem(ws, "33", "Explosion Ring");
	AddMenuItem(ws, "37", "Shock Muffle");
	AddMenuItem(ws, "134", "The Brundle Bundle");
	AddMenuItem(ws, "135", "Evil");

	DisplayMenu(ws, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public DSPFXCALLBACK(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_End) CloseHandle(menu);

	if(action == MenuAction_Select)
	{
		decl String:info[12];
		GetMenuItem(menu, param2, info, sizeof(info));

		new Float:weapon_glow = StringToFloat(info);
		DSPID[client] = weapon_glow
		if(weapon_glow == 0.0)
		{
			TF2Attrib_RemoveByName(client, "SET BONUS: special dsp")
		}
		else
		{
			TF2Attrib_SetByName(client, "SET BONUS: special dsp", weapon_glow);
		}
	}
}

public OnPostInventoryApplication(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	TF2Attrib_SetByName(client, "SET BONUS: special dsp", DSPID[client]);
}