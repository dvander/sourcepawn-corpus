#include <sdktools>

/* "de_cpl_mill" (CRC "b569b34a12ae350069a40f4df0db06a9") */


public Plugin:myinfo =
{
	name = "[Cs:s] de_cpl_mill (Easter egg notify)",
	author = "Bacardi",
	description = "Notify all players in chat when someone found one of easter egg triggers",
	version = "1.0"
}

new g_lastbutton = -1;

// [0] = buttons
// [1] = oranges
// [2] = secret spots
new eggs[3];

new bool:g_hooked = false;
new bool:easteregg_activated = false;

public OnConfigsExecuted()
{
	decl String:map[60];
	GetCurrentMap(map, sizeof(map));

	if(!g_hooked && StrEqual(map, "de_cpl_mill", false))
	{
		g_hooked = true;
		HookEntityOutput("func_button", "OnPressed", egg);
		HookEntityOutput("prop_physics", "OnBreak", egg);
		HookEntityOutput("trigger_multiple", "OnTrigger", egg);
		HookEntityOutput("math_counter", "OnHitMax", egg);
		HookEvent("round_end", round_end, EventHookMode_PostNoCopy);
		HookEvent("round_start", round_end, EventHookMode_PostNoCopy);
		LogMessage("Plugin loaded");

		new Handle:temp = INVALID_HANDLE;
		round_end(temp, "round_start", false);
	}
	else if(g_hooked && !StrEqual(map, "de_cpl_mill", false))
	{
		g_hooked = false;
		UnhookEntityOutput("func_button", "OnPressed", egg);
		UnhookEntityOutput("prop_physics", "OnBreak", egg);
		UnhookEntityOutput("trigger_multiple", "OnTrigger", egg);
		UnhookEntityOutput("math_counter", "OnHitMax", egg);
		UnhookEvent("round_end", round_end, EventHookMode_PostNoCopy);
		UnhookEvent("round_start", round_end, EventHookMode_PostNoCopy);
		LogMessage("Plugin unloaded");
	}
}

public round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(StrEqual(name, "round_start"))
	{
		easteregg_activated = false;
		eggs[0] = 0;
		eggs[1] = 0;
		eggs[2] = 0;

		decl Float:orig[3];
		g_lastbutton = -1;
		while((g_lastbutton = FindEntityByClassname(g_lastbutton, "func_button")) != -1)
		{
			GetEntPropVector(g_lastbutton, Prop_Send, "m_vecOrigin", orig);
			if(orig[0] == -1156&& orig[1] == 1352)
			{
				break;
			}
		}
	}
	else
	{
		easteregg_activated = true;
	}
}


public egg(const String:output[], caller, activator, Float:delay)
{

	if(easteregg_activated)
	{
		return;
	}

	// math_counter
	if(StrEqual(output, "OnHitMax"))
	{
		easteregg_activated = true;
		return;
	}
/*
CTSpawn			func_button (549)		"-518", "3788", "111"
CTSpawn			func_button (548)		"-518", "3596", "111"
CTSpawn			func_button (559)		"518", "3787", "113"
CTSpawn			func_button (556)		"518", "3595", "113"
BackHall			func_button (550)		"1052", "3110", "127"
BombsiteA		func_button (507)		"-1188", "2006", "81"
TSpawn			func_button (571)		"-164", "-218", "82"
TSpawn			func_button (546)		"284", "-122", "63"
TSpawn			func_button (547)		"544", "-122", "63"
TSpawn			func_button (124)		"477", "-518", "53"
TSpawn			func_button (503)		"1286", "-359", "49"
Basement			func_button (126)		"537", "378", "-80"
Basement			func_button (128)		"-198", "616", "-78"
Basement			func_button (122)		"250", "1094", "-64"
Middle			func_button (120)		"-134", "1286", "-64"
Gate				func_button (551)		"378", "1752", "47"
Sewers			func_button (514)		"408", "2950", "-82"
Sewers			func_button (516)		"616", "2554", "-82"
Sewers			func_button (510)		"-664", "2202", "-82"
Sewers			func_button (512)		"-800", "2566", "-82"
Sewers			func_button (552)		"-890", "1638", "-210"
Sewers			func_button (554)		"-1285", "1434", "-210"
StorageRoom		func_button (505)		"-967", "123", "-62"

// FINAL BUTTON to open door
StorageRoom		func_button (495)		"-1156", "1352", "-67"
*/
	decl String:msg[200];

	if(StrEqual(output, "OnPressed"))
	{

		if(g_lastbutton == caller)
		{
			if(activator != -1)
			{
				SetVariantString("OnUser1 !self:PressOut::1.0:-1");
				AcceptEntityInput(caller, "AddOutput");
				AcceptEntityInput(caller, "FireUser1");
				PrintToChat(activator, "\x01(\x05easter egg\x01) Overall \x04%i/34\x01 easter eggs found", eggs[0]+eggs[1]+eggs[2]);

				for (new i = 1; i <= MaxClients; i++)
				{
					if (!IsClientInGame(i) || IsFakeClient(i))
					{
						continue;
					}
					//FormatActivitySource(client, i, msg, sizeof(msg));
					SendDialogToOne(i, "Easter eggs performed %i/34", eggs[0]+eggs[1]+eggs[2]);
				}
			}
			return;
		}

		eggs[0]++;
		//PrintToServer(output);
		GetEntPropString(activator, Prop_Send, "m_szLastPlaceName", msg, sizeof(msg));
		Format(msg, sizeof(msg), "\x01(\x05easter egg\x01) \x03%N\x01 @ \x04%s\x01: found button %i/23", activator, msg, eggs[0]);

		new Handle:hBf = StartMessageAll("SayText2");
		if (hBf != INVALID_HANDLE)
		{
			BfWriteByte(hBf, activator);
			BfWriteByte(hBf, 0);
			BfWriteString(hBf, msg);
			EndMessage();
		}

		return;
	}

/*
Courtyard		prop_physics (133)		"1232", "2144", "240"
Courtyard		prop_physics (134)		"1270", "2307", "238"
Courtyard		prop_physics (135)		"1180", "2312", "284"
Courtyard		prop_physics (132)		"1119", "2714", "237"
Courtyard		prop_physics (130)		"969", "2752", "243"
Courtyard		prop_physics (131)		"1140", "2804", "298"
*/

	else if(StrEqual(output, "OnBreak"))
	{
		eggs[1]++;
		//PrintToServer(output);
		if(activator > MaxClients)
		{
			activator = GetEntPropEnt(activator, Prop_Send, "m_hOwnerEntity");
		}

		if(activator > 0)
		{
			GetEntPropString(activator, Prop_Send, "m_szLastPlaceName", msg, sizeof(msg));
			Format(msg, sizeof(msg), "\x01(\x05easter egg\x01) \x03%N\x01 @ \x04%s\x01: found orange %i/6", activator, msg, eggs[1]);

			new Handle:hBf = StartMessageAll("SayText2");
			if (hBf != INVALID_HANDLE)
			{
				BfWriteByte(hBf, activator);
				BfWriteByte(hBf, 0);
				BfWriteString(hBf, msg);
				EndMessage();
			}
		}
		else
		{
			PrintToChatAll("\x01(\x05easter egg\x01) @ \x04Courtyard\x01: found orange %i/6", eggs[1]);
		}

		return;
	}

/*
Gate			trigger_multiple (537)	"416", "1696", "34"
House		trigger_multiple (534)	"888", "2496", "256"
Stairwell		trigger_multiple (533)	"2548", "2404", "188"
Stairwell		trigger_multiple (573)	"2544", "2776", "-112"
StorageRoom	trigger_multiple (535)	"-960", "448", "34"
*/
	else
	{
		eggs[2]++;
		GetEntPropString(activator, Prop_Send, "m_szLastPlaceName", msg, sizeof(msg));
		Format(msg, sizeof(msg), "\x01(\x05easter egg\x01) \x03%N\x01 @ \x04%s\x01: found secret spot %i/5", activator, msg, eggs[2]);

		new Handle:hBf = StartMessageAll("SayText2");
		if (hBf != INVALID_HANDLE)
		{
			BfWriteByte(hBf, activator);
			BfWriteByte(hBf, 0);
			BfWriteString(hBf, msg);
			EndMessage();
		}
	}
}

// Snip from SM basechat.sp
SendDialogToOne(client, String:text[], any:...)
{
	new String:message[100];
	VFormat(message, sizeof(message), text, 3);
	
	new Handle:kv = CreateKeyValues("Stuff", "title", message);
	KvSetColor(kv, "color", 255, 255, 0, 255);
	KvSetNum(kv, "level", 1);
	KvSetNum(kv, "time", 1);
	
	CreateDialog(client, kv, DialogType_Msg);
	
	CloseHandle(kv);	
}